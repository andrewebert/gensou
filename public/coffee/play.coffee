# =========================================================================== #
#      HEADER
# =========================================================================== #

# The number of messages that can be displayed in the log
log_display = 4

g = this
util = g.util
g.images = {front: {}, back: {}, icon: {}, type: {}}
g.id = "player1"

# =========================================================================== #
#      HERO SELECTION
# =========================================================================== #

# Choose what set of hero icons are visible - true to show your icons, false to
# show enemy icons
select_icons = (enemy=false) ->
    g.enemy = enemy
    if enemy
        stacks = g.enemy_stacks
        change_state("team_state", "enemy_team")
    else
        stacks = g.my_stacks
        change_state("team_state", "my_team")
    for hero in Object.keys(stacks)
        icon = $(".hero_icon.#{stacks[hero].position}")
        if hero.indexOf("unknown") == -1
            icon.attr("src", g.images.icon[hero].src)
            icon.name("#{hero}")
            icon.addClass("clickable")
        else
            # We don't know who this hero is
            icon.attr("src", g.images.icon["unknown"].src)
            icon.removeClass("clickable")


# Set the active hero - 
# name :: heroID
# enemy is true iff you're setting the enemy active hero
set_active_hero = (name, enemy=false) ->
    if enemy
        zone = $(".enemy.game_area")
        stack = g.enemy_stacks
        angle = "front"
    else
        zone = $(".my.game_area")
        stack = g.my_stacks
        angle = "back"
        g.active_hero = name
        change_state("activity_state", 
            if name is g.active_hero then "active_hero" else "inactive_hero")

    fill_hero_bar(zone, name, stack[name], angle)

# Display the information relating to a hero - image, HP bar, name, types, etc
# zone is a jQuery object that is the outer div of the hero bar
# name :: heroID
# stack is either window.my_stacks[name] or window.enemy_stacks[name]
# angle :: front | back (for the hero picture)
fill_hero_bar = (zone, name, stack, angle="front") ->
    # Show the hero details
    hero = g.heroes[name]

    zone.show()
    zone.find(".hero").attr("src", g.images[angle][name].src)
    zone.find(".hero").name(name)
    zone.find(".name").html("#{hero.name}")
    set_hp(zone.find("span.hp"), stack.hp)
    zone.find("p.hp").html("#{stack.hp}/100")

    # Show the hero types
    zone.find(".type.1").type(hero.types[0])
    if hero.types.length is 1
        zone.find(".type.2").hide()
        zone.find(".type.2").attr("type", "none")
    else
        zone.find(".type.2").show()
        zone.find(".type.2").type(hero.types[1])

# Selects which hero is visible in the details panel. Does not change
# the active hero.
# name :: heroID
select_hero = (name) ->
    # Get the hero data (stored in the attributes of the hero icon)
    hero = g.heroes[name]

    change_state("details_state", "hero_details")
    change_state("activity_state", 
        if name is g.active_hero then "active_hero" else "inactive_hero")

    stack = (if g.enemy then g.enemy_stacks else g.my_stacks)[name]

    # Fill the hero bar
    fill_hero_bar($("#hero_bar"), name, stack)
    
    # Show the item details
    if stack.item?
        item = g.items[stack.item]
        $("#item_data .name").html("<b>Item: </b>#{item.name}")
        effect = interpolate(item.effect, hero, item)
        $("#item_data .text").html(effect)
        details = interpolate(item.details, hero, item)
        write_help_text(details, $("#item_data .effect"))
    else
        $("#item_data .name").html("")


    # Fill in the stats table
    $("#hero_data .stat").removeClass("stat_changed buffed nerfed")
    for stat in ["attack", "defence", "magic_attack", "magic_defence", "speed"]
        data = stack.stats[stat]
        table_cell = $("#details .stats .#{stat}")
        table_cell.html("#{data.total}")
        table_cell.attr("stat", stat)
        if data.base?
            table_cell.addClass("stat_changed")
            if data.total > data.base
                table_cell.addClass("buffed")
            else if data.total < data.base
                table_cell.addClass("nerfed")
    
    # Print the hero ability and help text
    $("#hero_data .effect .text").html("#{hero.ability}")
    # We don't want to show the help text until the user presses the help icon
    write_help_text(hero.details, $("#hero_data .effect"))

    # Fill the spellcard buttons with the appropriate text
    # $(".spellcard").removeClass("critical")
    scs = stack.spellcards
    for i in [0..scs.length-1]
        # 0 is the id of the undefined spellcard
        if scs[i] != 0
            spellcard = g.spellcards[scs[i]]
            #if get_effectiveness(spellcard.type, 
            #        $(".enemy .type.1").type(), $(".enemy .type.2").type()) > 1
            #    $("##{i}").addClass("critical")
            $("##{i}").name(scs[i])
            $("##{i} .sign").html("#{spellcard.sign}")
            $("##{i} .name").html("#{spellcard.name}")
            # $("##{i} .name").setAttackType(spellcard.atype)
            # $("##{i} .type").show()
            # $("##{i} .type").type(spellcard.type)
        else
            # We don't know what this spellcard is, don't show anything
            $("##{i} .sign").html("")
            $("##{i} .name").html("")
            $("##{i} .type").hide()

    # Mark this hero as active
    $(".hero_icon.active").deactivate()
    $(".hero_icon.#{stack.position}").activate()
    
    # Format the buttons
    $(".spellcard").deactivate()
    if name == g.active_hero
        # If we're looking at the active hero, we can use the spellcards
        if g.confirmed_spellcard?
            $("#confirm").activate()
            $("##{g.confirmed_spellcard}").activate()
    else if not enemy
        # If we're not looking at the active hero, we can't use the spellcards,
        # but we can switch hero
        if not confirmed()
            $("#confirm .text").html("Switch to #{hero.shortname}")
        if g.confirmed_hero == name
            $("#confirm").activate()

# =========================================================================== #
#      SPELLCARD SELECTION
# =========================================================================== #

# Selects which spellcard is visible in the details panel. Does not confirm the
# spellcard.
# card :: spellcardID
select_spellcard = (card) ->
    spellcard = g.spellcards[$("##{card}").name()]

    change_state("details_state", "spellcard_details")
    change_state("help_state", "help_not_shown") if spellcard.details?

    activate_spellcard(card)

    $("#spellcard_data .name").html(spellcard.name)

    if spellcard.power?
        $("#spellcard_data .power").show()
        $("#spellcard_data .power").setAttackType(spellcard.atype)
        $("#spellcard_data .power b").html(spellcard.power)
    else
        $("#spellcard_data .power").hide()

    $("#spellcard_data .type").type(spellcard.type)
    if spellcard.atype?
        $("#spellcard_data .typestring").show()
        attack_type_string = {
            "physical": "Physical Attack",
            "magic": "Magic Attack",
            "special": "Attack",
        }[spellcard.atype]
        $("#spellcard_data .typestring").html(
            "#{attack_type_string} &mdash; #{spellcard.type}")
    else 
        $("#spellcard_data .power").hide()
        $("#spellcard_data .typestring").hide()

    effect = interpolate(spellcard.effect, g.heroes[selected_hero()], spellcard)
    $("#spellcard_data .effect .text").html(effect)
    details = interpolate(spellcard.details, g.heroes[selected_hero()], spellcard)
    # We don't want to show the help text until the user presses the help icon
    write_help_text(details, $("#spellcard_data .effect"))

# Sets which spellcard is active without modifying the details panel.
# card :: spellcardID
activate_spellcard = (card) ->
    selected_spellcard()?.deactivate()
    $("##{card}").activate()

    # The spellcard can only be used if it belongs to the active hero
    if selected_hero() is g.active_hero
        $("#confirm .text").html("Use Spellcard") if not confirmed()

# =========================================================================== #
#      CONFIRMATION
# =========================================================================== #

# Triggered when the user presses the confirm button. Sends a message to the
# server telling it that you've chosen a particular action.
confirm = ->
    change_state("confirmed_state", "confirmed")
    $("#confirm").activate()
    # If we're looking at the active hero, we're confirming a spellcard
    if selected_hero() == g.active_hero
        if selected_spellcard()?
            choose(selected_spellcard())
            # Set the text of the confirm button to the spellcard selected
            $("#confirm .text").html(selected_spellcard().find(".name").html())
        else
            alert("ERROR: No selected spellcard")
    # If we're not looking at the active hero, we're confirming a switch
    else
        choose(selected_hero())
        g.confirmed_hero = selected_hero()
        # Set the text of the confirm button to the spellcard selected
        $("#confirm .text").html("Switch to #{g.heroes[selected_hero()].shortname}")


# Cancels the confirmation. Won't work if the server's in the middle of processing
# the action. Can also be called if the server forces a cancel, or once an action
# has been resolved.
cancel_confirm = ->
    change_state("confirmed_state", "not_confirmed")
    $("#confirm").deactivate()
    g.confirmed_spellcard = null
    g.confirmed_hero = null
    # Put the text back to what it should be based on the current selection
    if selected_hero() == g.active_hero
        if selected_spellcard()?
            $("#confirm .text").html(selected_spellcard().find(".name").html())
    else
        $("#confirm .text").html("Switch to #{g.heroes[selected_hero()].shortname}")
    # Return false so that the href doesn't reload the page
    return false

# =========================================================================== #
#      TYPECHART
# =========================================================================== #

# Formats the HTML for the typechart, and creates the g.effectiveness object
# g.effectiveness :: {(type): {(type): (int)}}
create_typechart = ->
    table = $("#typechart table")
    for type in g.types[0]
        $("#typechart tr").append("""
            <td>
                <img src="#{g.images.type[type].src}" type="#{type}">
                </img>
            </td>
            """
        )
    for row in g.types[1..]
        table_row = """
            <tr>
                <td class="attacker">
                    <img src ="#{g.images.type[row[0]].src}" type="#{row[0]}">
                    </img>
                 </td>
            """
        for e, i in row[1..]
            table_row += 
                """<td class="#{{0.5: "resist", 2:"crit", 0:"immune", 1:""}[e]}"></td>"""
        table_row += "</tr>"
        table.append(table_row)

    # This constructs a table of types used by effectiveness/3 - The first index
    # is the attacker and the second index is the defender
    typenames = g.types[0]
    g.effectiveness = Object()
    for row in g.types[1..]
        g.effectiveness[row[0]] = Object()
        for e, j in row[1..]
            g.effectiveness[row[0]][typenames[j]] = e

# =========================================================================== #
#      Logging
# =========================================================================== #

# Writes a message or list of messages to the game log, pausing briefly between
# each message and longer on blank lines
write_log = (parts) ->
    return if parts.length is 0
    delay = if parts[0] is "<br/>" then 2400 else 800
    if $.isArray(parts)
        display_message(parts[0], $("#log"))
        g.setTimeout(write_log, delay, parts[1..])
    else
        display_message(parts, $("#log"))

# Writes a message into a box (log or chat box), then scrolls the box to
# the bottom
display_message = (message, box) ->
    message = """<div class="message">#{message}</div>"""
    $(message).hide()
    box.append(message)
    $(message).slideDown()
    # TODO: Fix
    box.scrollTop(1000000)

# =========================================================================== #
#      Stat change explanations
# =========================================================================== #

# Explains why a hero has a particular set of stats; activated when the user
# clicks a green or red cell in the stat table
display_stat_change = (stat, data) ->
    change_state("stat_help_state", "stat_help_shown")
    stat = stat.replace("_", " ")
    write_help_text(["Base #{stat}: #{data.base}<br/>"].concat(
                     data.buffs).concat(
                     ["Total #{stat}: #{data.total}"])
                     , $("#hero_data .stat_effect"))

# =========================================================================== #
#      State
# =========================================================================== #

# Change the state in a given category of states
# States are implemented as classes of the #container element
# There is at most one state active in each category at a time
states = {
    team_state:         ["my_team", "enemy_team"],
    details_state:      ["hero_details", "spellcard_details", "typechart_details"],
    activity_state:     ["active_hero", "inactive_hero"],
    expand_state:       ["expanded_hero", "expanded_item", "not_expanded"],
    help_state:         ["no_help", "help_not_shown", "help_shown"],
    stat_help_state:    ["stat_help_not_shown", "stat_help_shown"],
    confirmed_state:    ["confirmed", "not_confirmed"],
}

# Changes the state associated with the given category
change_state = (category, state) ->
    $("#container").removeClass(states[category].join(" "))
    $("#container").addClass(state)
    if category is "details_state"
        change_state("expand_state", "not_expanded")
        change_state("help_state", "no_help")
        change_state("stat_help_state", "stat_help_not_shown")
        if state isnt "typechart_details"
            $("#typechart td").removeClass(""""
                highlighted_row
                highlighted_col
                pre_highlighted_row
                pre_highlighted_col
                """)
    if category is "expand_state" and not in_state("no_help")
        change_state("help_state", "help_not_shown")
        change_state("stat_help_state", "stat_help_not_shown")

# Toggles between help being shown and not shown
toggle_state = (category) ->
    if category is "help_state" and not in_state("no_help")
        if in_state("help_not_shown")
            change_state("help_state", "help_shown")
        else
            change_state("help_state", "help_not_shown")
    
    #if states[category].length == 2
        #if in_state(category[0])
            #change_state(category, category[1])
        #else
            #change_state(category, category[0])

# Checks whether we're currently in the given state, returns boolean
in_state = (state) ->
    return $("#container").hasClass(state)

# =========================================================================== #
#      Helper functions
# =========================================================================== #

# Displays the hp of a hp bar
# hp bar :: a jquery reference to a <span>
# hp :: Int (range 0..100)
set_hp = (hp_bar, hp) ->
    hue = hp * 0.86 # 0 is red, 86 is green
    top = util.hsl_to_hexcolor(hue, 212, 151)
    bottom = util.hsl_to_hexcolor(hue, 235, 106)
    hp_bar.css("background-color", top)
    hp_bar.css("background-image", "-webkit-gradient(linear, left top, left bottom, " +
        "color-stop(0, #{top}), color-stop(1, #{bottom}))")
    hp_bar.width(322 * hp / 100)
    
    hp_bar.removeClass("one_hp low full")
    if hp == 1
        hp_bar.addClass("one_hp")
    if hp <= 4
        hp_bar.addClass("low")
    if hp > 99
        hp_bar.addClass("full")

# Replaces all instances of #{hero} with hero and #{this_object} with this_object
# text: String | [String]
# hero: String
# this_object: String
interpolate = (text, hero=null, this_object=null) ->
    return "" unless text?
    if $.isArray(text)
        return (interpolate(t, hero, this_object) for t in text)
    else
        if hero?
            text = text.replace(/#{hero}/g, hero.shortname)
        if this_object?
            text = text.replace(/#{this}/g, this_object.name)
        return text


# Writes the details text for a game object
# details :: [String]
# zone: jquery object representing a .effect zone
write_help_text = (details, zone) ->
    # Get rid of whatever text was here previously
    zone.find(".detail").remove()
    # Create a new %p.detail for each line of help text
    if details
        zone.find(".text").addClass("clickable")
        for detail in details
            zone.append("""<p class="detail">#{detail}</p>""")
    else
        zone.find(".text").removeClass("clickable")

# Highlights a row or column of type chart
# type :: Type
# kind :: row | column
# clear :: Bool
#   if true, clear all row or column highlighting (depending on kind) 
#     before applying the highlighting
#   if false, toggle the highlighting of this row or column
highlight_typechart = (type, kind, clear=true) ->
    change_state("details_state", "typechart_details")
    change_state("help_state", "help_shown")

    if type?
        index = g.types[0].indexOf(type) + 1
        if kind is "row"
          zone = $("#typechart tr:eq(#{index}) td")
          pre_zone = $("#typechart tr:eq(#{index-1}) td")
        else if kind is "col"
          zone = $("#typechart tr td:nth-child(#{index+1})")
          pre_zone = $("#typechart tr td:nth-child(#{index})")
        else
          alert("Invalid call to highlight_typechart!")

        # pre_highlighted is needed because with overlapping borders, the
        # left/top borders of a call are determined by the right/bottom borders
        # of adjacent cells.
        if clear
            $("#typechart td").removeClass("highlighted_#{kind} pre_highlighted_#{kind}")
            zone.addClass("highlighted_#{kind}")
            pre_zone.addClass("pre_highlighted_#{kind}")
        else
            zone.toggleClass("highlighted_#{kind}")
            pre_zone.toggleClass("pre_highlighted_#{kind}")
    else
        alert("Undefined type in highlight_typechart!")


# Returns true iff we're currently in a confirmed state
confirmed = -> return g.confirmed_spellcard? or g.confirmed_hero?

# Gets the effectiveness (int) of the given skill type against the given hero types
# my_type, enemy_type1, enemy_type2 :: Type
get_effectiveness = (my_type, enemy_type1, enemy_type2=null) ->
    e = g.effectiveness[my_type][enemy_type1]
    if enemy_type2?
        e *= g.effectiveness[my_type][enemy_type2]
    return e

# Gets the currently selected hero (i.e. the hero whose details are currently
# being displayed). Not necessarily the active hero. May be an enemy hero.
# return :: HeroID
selected_hero = ->
    $(".hero_icon.active").name()

# Gets the currently selected spellcard (i.e. the spellcard whose details are currently
# being displayed). Not necessarily the active spellcard. May be an enemy spellcard.
# return :: SpellcardID
selected_spellcard = ->
    spellcard = $(".spellcard.active")
    return spellcard if spellcard.length > 0
    return null

# =========================================================================== #
#      WEBSOCKETS INTERFACE
# =========================================================================== #

# An object used to communicate with the server over websockets.
# start: the constructor; establishes a websocket connection
# onmessage: called whenever the server sends us a message
#   message :: JSONString
# send: call in order to send the server a message
#   message :: Object
socket = {
    start: ->
        @ready = false
        @queue = []
        @socket = new WebSocket("ws://localhost:4567/socket")
        @socket.onmessage = (message) =>
            # message.data is the content of the message, not the content of
            # the data field of the event (the rest of message has the
            # metadata)
            events = JSON.parse(message.data)
            events = [events] unless $.isArray(events)
            for event in events
                if event.type is "chat"
                    display_message(event.data, $("#inbox"))
                else if event.type is "ready"
                    # Send our ID to the server, then send any queued up messages.
                    @ready = true
                    @send({type: "id", id: g.id})
                    for m in @queue
                        @send(m)
                else if event.type is "initial_load"
                    # initial_load events are received when we join a game and
                    # tell us what our heroes are and what everything does.
                    initialize_game(event)
                else if event.type is "update"
                    # update messages give us information about what each player
                    # does and its consequences. They are sent over the course
                    # of the game.
                    act(event)
                else
                    # For debugging.
                    alert("Invalid event #{event.type}")

    # If the server isn't ready to receieve messages on the socket,
    # store any messages we receive. They will be sent when the server
    # is ready.
    send: (message) ->
        if @ready
            @socket.send(JSON.stringify(message))
        else
            @queue.push(message)
}

# =========================================================================== #
#      GAME ACTIONS (merge into another file)
# =========================================================================== #

# Acts on a game action message we've received from the server
act = (data) ->
    #if data.phase is "select_starting_hero"
        # write_log("<b>Choose your starting hero</b>")
    if data.my_active_hero?
        set_active_hero(data.my_active_hero, false)
        write_log("You chose #{heroes[data.my_active_hero].name}")
        cancel_confirm()
    if data.enemy_active_hero?
        set_active_hero(data.enemy_active_hero, true)
        write_log("Robert chose #{heroes[data.enemy_active_hero].name}")

# Tell the server which game action you've chosen
choose = (choice) ->
    socket.send({"type": "action", "action": choice})

# =========================================================================== #
#      LOAD DATA
# =========================================================================== #

initialize_game = (data) ->
    # Get the data from the server - this tells you what heroes you've got
    # (data.my_stacks), what they do (data.heroes), what your spellcards do
    # (data.spellcards), what your items do (data.items) and the typechart
    # (data.typechart).
    # Once you've got this, load all the images from the server, format the
    # typechart, then remove the loading screen
    load_data data, ->
        load_types ->
            create_typechart()
            select_icons(false)
            select_hero((hero for hero in Object.keys(g.my_stacks) when g.my_stacks[hero].position is 1)[0])
            # set_active_hero("youmu", false)
            # set_active_hero("mokou", true)
            set_actions()
            # Once we've finished loading everything, display it
            $("#loading").hide()
            $("#container").show()
            # socket.send({type: "action", action: "begin_game"})

# Loads all the images specified in the list into window.images, then calls the callback.
# images ::
#   {
#     kind: (front OR back OR icon OR type)
#     name :: heroID
#     source: (path relative to the public/ directory of the server)
#   }
# window.images ::
#   {
#     front: {heroID: (src)}
#     back: {heroID: (src)}
#     icon: {heroID: (src)}
#     type: {heroID: (src)}
#   }
load_images = (images, callback) ->
    num_loaded = 0
    loaded = ->
        num_loaded += 1
        $("#loading h1").html("Loading... #{Math.floor(100*num_loaded/images.length)}%")
        if num_loaded is images.length
            callback()
    for i in images
        if g.images[i.kind][i.name]?
            loaded
        else
            image = new Image()
            image.src = i.source
            image.onload = loaded
            image.onerror = loaded
            g.images[i.kind][i.name] = image

# Loads any sprites referenced in data, then calls the callback with no arguments
# data ::
#   {
#     my_stacks: {heroID: ..., ...}, 
#     enemy_stacks: {heroID: ..., ...},
#     ...
#   }
load_data = (data, callback) ->
    # Do a deep extend (recursive merge)
    $.extend(true, g, data)
    sprite_names = (Object.keys(d) for d in [data.my_stacks, data.enemy_stacks])
    sprite_names = sprite_names[0].concat(sprite_names[1])
    images = [{kind: "icon", name: "unknown", source: "img/icon/unknown.png"}]
    for name in sprite_names
        if name.indexOf("unknown") < 0
            $.merge(images, ({ 
                kind: kind,
                name: name,
                source: "img/#{kind}/#{name}.png",
            } for kind in ["front", "back", "icon"]))
    load_images(images, callback)

# Loads all the type images, then calls the callback with no arguments
load_types = (callback) ->
    type_names = ["Air", "Divine", "Earth", "Fighting", "Fire", "Ice",
        "Shadow", "Spirit", "Steel", "Water"]
    images = ({
            kind: "type",
            name: name,
            source: "img/types/#{name}.svg",
        } for name in type_names)
    load_images(images, callback)

# =========================================================================== #
#      ACTIONS
# =========================================================================== #

# Defines what happens when you click on things or enter text into forms
set_actions = ->
    # ================= HEROES

    $(".hero_icon").click ->
        # show_hero_details = false, enemy = false
        if $(this).hasClass("clickable")
            select_hero($(this).name())

    $(".my .hero").click ->
        # show_hero_details = true, enemy = false
        select_icons(false)
        select_hero(g.active_hero)

    $(".enemy .hero").click ->
        # show_hero_details = true, enemy = true
        select_icons(true)
        select_hero($(this).name())

    # ================= SPELLCARDS

    $(".spellcard").click ->
        if $(this).hasClass("active") and in_state("spellcard_details")
            select_hero(selected_hero())
        else
            select_spellcard($(this).id())

    # ================= CONFIRMATION

    $("#confirm").click ->
        confirm() unless confirmed()

    $(".cancel").click ->
        cancel_confirm()

    # ================= TYPECHART

    $(".spellcard .type").click ->
        highlight_typechart($(this).type(), "row")
        # This way the spellcard underneath gets selected, but the typechart
        # doesn't get replaced by spellcard data
        activate_spellcard($(this).parent().id())
        return false;

    $("#spellcard_data .type").click ->
        highlight_typechart($(this).type(), "row")

    $("#typechart .attacker img").click ->
        highlight_typechart($(this).type(), "row", clear=false)

    $("#typechart .defender img").click ->
        highlight_typechart($(this).type(), "col", clear=false)

    $(".game_area img.type").click ->
        highlight_typechart($(this).type(), "col", clear=true)
        other_type = $(this).siblings().type()
        if other_type? and other_type != "none"
            highlight_typechart(other_type, "col", clear=false)

    # ================= HELP FUNCTIONS
    $("#hero_bar .expand").click ->
        change_state("help_state", "help_not_shown") if g.heroes[selected_hero()].details?
        change_state("expand_state", "expanded_hero")

    $("#hero_bar .unexpand").click ->
        change_state("expand_state", "not_expanded")

    $("#item_data .name").click ->
        if in_state("expanded_item")
            # Hide the item info
            change_state("expand_state", "not_expanded")
        else
            # Show the item info
            change_state("expand_state", "expanded_item")
            stacks = if g.enemy then g.enemy_stacks else g.my_stacks
            if g.items[stacks[selected_hero()].item].details?
                change_state("help_state", "help_not_shown")

    $(".effect .text").click ->
        toggle_state("help_state", "help_shown")

    $("#hero_zone .hero").click ->
        if in_state("expanded_hero")
            change_state("expand_state", "not_expanded")
        else
            change_state("expand_state", "expanded_hero")
            unless in_state("no_help")
                change_state("help_state", "help_not_shown")
            change_state("stat_help_state", "stat_help_not_shown")

    $(".unhelp").click ->
        change_state("help_state", "help_not_shown")
        if in_state("typechart_details")
            if selected_spellcard()?
                select_spellcard(selected_spellcard().id())
            else
                select_hero(selected_hero())

    $("#hero_data .stat").click ->
        if $(this).hasClass("stat_changed")
            stacks = if g.enemy is false then g.my_stacks else g.enemy_stacks
            display_stat_change($(this).attr("stat"),
                stacks[selected_hero()].stats[$(this).attr("stat")])

    $(".stat_unhelp").click ->
        change_state("stat_help_state", "stat_help_not_shown")

    # ================= CHAT
    $("#chat form").submit ->
        message = $("#chatbox").val()
        socket.send({"type": "chat", "message": message})
        $("#chatbox").val("")
        return false

# =========================================================================== #
#      READY
# =========================================================================== #

$(document).ready ->
    # ================= WINDOW VARIABLES

    #g.active_hero = "youmu"
    g.confirmed_hero = null
    g.confirmed_spellcard = null
    g.enemy = false
    
    # ================= JQUERY FUNCTIONS

    # Extend jquery with some shortcuts for dom manipulation
    util.attribute_function("id")
    util.attribute_function("name")
    $.fn.activate = -> this.addClass("active")
    $.fn.deactivate = -> this.removeClass("active")
    #$.fn.hide = -> this.addClass("hidden")
    #$.fn.unhide = -> this.removeClass("hidden")

    # Sets a type image - both its source and its type attribute
    # val :: Air | Divine | Fire | ...
    $.fn.type = (val) ->
       if val?
           this.attr("src", "#{g.images.type[val].src}")
           this.attr("type", val)
       else
           return this.attr("type")

    # Sets the attack type of an object (none by default)
    # attack_type :: physical | magic | special | none
    $.fn.setAttackType = (attack_type) ->
        this.removeClass("physical magic special none")
        this.addClass(attack_type ? "none")

    # ================= SETUP

    socket.start()

