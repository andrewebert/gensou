module Game
class Interface
    def initialize
        @nextGameInterface = GameInterface.new(self)
        # {socket: ClientInterface}
        @interfaces = {}
    end

    def addPlayer(socket)
        @interfaces[socket] = @nextGameInterface
        if @nextGameInterface.addPlayer(socket)
            # We added the second player to the game; the next player should be
            # added to a new game
            @nextGameInterface = GameInterface.new(self)
        end
    end

    # Called when a message is received from the client
    def message(socket, message)
        if @interfaces.include? socket
            @interfaces[socket].message(socket, message)
        else
            print "Got message from unknown socket #{socket}\n"
        end
    end

    # Send a message to the client
    def send(socket, message)
        socket = socket
        #EM.next_tick do
        socket.send(JSON.dump(message))
        #end
    end
end

class GameInterface
    def initialize(interface)
        # Game::Interface
        @interface = interface
        # [Playersocket]
        @players = []
        @player_objects = []
        # {Playersocket: [DataMessage]}
        @log = {}
        # {Playersocket: GameCallback}
        @callback = {}
        # {Playersocket: GameAction -> bool}
        @legality = {}
    end

    # Returns true iff a new game was started
    def addPlayer(socket)
        @players << socket

        @log[socket] = [{"type" => "ready"}]
        #if @players.length >= 2
            ## Set up the game
            #@players.each do |p|
                #@log[p] << {
                    #"type" => "data",
                    #"phase" => "select_starting_hero",
                #}
                #send_log(p)
                #@callback[p] = nil
                #@legality[p] = nil
            #end
            #return true
        #else
        send_log(socket)
        return false
        #end
    end

    def message(socket, message)
        # If somehow we got a message from the wrong socket, ignore it
        unless @players.include? socket
            return
        end

        case message["type"]

        when "chat"
            send_all({
                "type" => "chat",
                "message" => message["message"]
            })

        when "action"
            sleep(1)
            if @legality[socket].nil? or not @legal[socket].call(message)
                send(socket, {"type" => "illegal"})
            else
                @callback[socket].add_action(socket, message)
            end

        when "id"
            @player_objects << Player.new(socket, message["id"])
            #if @player_objects.length >= 2
                #@game = Game.new(@player_objects)
            #end
        end

            #send_all({
                #"type" => "data",
                #"my_active_hero" => message["action"],
                #"enemy_active_hero" => "mokou",
                #"phase" => "select_action"
            #})
    end

    def request_player_action(sockets, callback, legality_check)
        sockets = [sockets].flatten
        sockets.each do |socket|
            @callback[socket] = GameCallback.new(socket, callback)
            @legal[socket] = legality_check
            send_log(@players[socket])
        end
    end

    def send_log(socket)
        send(socket, @log[socket])
        @log[socket] = []
    end

    def send(socket, message)
        print "Sent message #{message}\n"
        @interface.send(socket, message)
    end
end

# A callback can require the input of one or both players. When all required
# players have selected their action, calls the callback.
# sockets :: [Playersocket]
# callback :: [[Playersocket, GameAction]] -> 
class GameCallback
    def initialize(sockets, callback)
        @actions = []
        @sockets = sockets
        @callback = callback
    end

    def add_action(socket, action)
        if @sockets.include? socket
            @actions << [socket, action]
            @sockets.delete(socket)
        end
        if @sockets.empty?
            callback.call(@actions)
        end
    end
end

class Game
    def initialize(interface, socket, id)
        @interface = interface
        @socket = socket
        @data = load_data(id)
        @interface.send(id, @data)
    end
end

class Player
    def initialize(socket, id)
        print "Initializing new player #{id}\n"
        my_stacks = JSON.parse(File.read("public/json/#{id}.json"))
        # We don't know what any of the enemy heroes are at the start of the game
        enemy_stacks = {}
        heroes = JSON.parse(File.read("public/json/heroes.json"))
        spellcards = JSON.parse(File.read("public/json/spellcards.json"))
        items = JSON.parse(File.read("public/json/items.json"))
        types = JSON.parse(File.read("public/json/types.json"))
        message = [{
            "type" => "initial_load",
            "my_stacks" => my_stacks,
            "enemy_stacks" => enemy_stacks,
            "heroes" => heroes,
            "spellcards" => spellcards,
            "items" => items,
            "types" => types,
        }]
        socket.send(JSON.dump(message))
    end
end




class PlayQueue
end

end # module Game
