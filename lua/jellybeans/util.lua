local hsluv = require("jellybeans.hsluv")
M = {}

local clamp = function(x, min, max)
    return math.max(min, math.min(x, max) )
end

M.blend = function(col1, col2, ratio)
    col1 = hsluv.hex_to_rgb(col1)
    col2 = hsluv.hex_to_rgb(col2)

    local blendChannel = function(i)
      local ret = (ratio * col2[i] + ((1 - ratio) * col1[i]))
      return clamp(ret, 0, 1)
    end

  return hsluv.rgb_to_hex({blendChannel(1), blendChannel(2), blendChannel(3)})
  end

M.adjust = function(hex, h, s, l)
    local c = hsluv.hex_to_okhsl(hex)
    c[1] = (c[1] + h) % 360
    c[2] = clamp(c[2] + s, 0, 100)
    c[3] = clamp(c[3] + l, 0, 100)
    return hsluv.okhsl_to_hex(c)
end

M.lighten = function(hex, l)
    return M.adjust(hex, 0, 0, l)
end

M.darken = function(hex, l)
    return M.adjust(hex, 0, 0, -l)
end

M.rotate = function(hex, h)
    return M.adjust(hex, h, 0, 0)
end

return M
