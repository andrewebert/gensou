# =========================================================================== #
#      HEADER
# =========================================================================== #
@util = Object()

# Adds a function to the jquery object - attribute_function("foo") lets you
# call $(elem).foo() instead of $(elem).attr("foo") 
# and  $(elem).foo(val) instead of $(elemn).attr("foo", val)
@util.attribute_function = (att) ->
    $.fn[att] = (val) ->
        if val? then this.attr(att, val) else this.attr(att)

# Takes a hsl value with each in the range [0..255]
# Returns a RGB hex-string, e.g. #fe136b
@util.hsl_to_hexcolor = (h, s, l) ->
    # Convert the hsl to rgb (credit to less.js)
    h = (h % 255) / 255;
    s = (s % 255) / 255;
    l = (l % 255) / 255;

    m2 = if l <= 0.5 then l * (s + 1) else l + s - l * s;
    m1 = l * 2 - m2;

    hue = (h) ->
        h = if h < 0 then h + 1 else (if h > 1 then h - 1 else h)
        if (h * 6 < 1)
            return m1 + (m2 - m1) * h * 6
        else if (h * 2 < 1)
            return m2
        else if (h * 3 < 2)
            return m1 + (m2 - m1) * (2/3 - h) * 6
        else
            return m1
    
    r = Math.floor(hue(h + 1/3) * 255)
    g = Math.floor(hue(h)       * 255)
    b = Math.floor(hue(h - 1/3) * 255)

    # Convert the rgb values to 
    return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)
