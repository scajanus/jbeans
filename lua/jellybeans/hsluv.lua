--[[
Lua implementation of HSLuv and HPLuv color spaces
Homepage: http://www.hsluv.org/

Copyright (C) 2019 Alexei Boronine

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
local hsluv = {}

local hexChars = "0123456789abcdef"

local distance_line_from_origin = function(line)
  return math.abs(line.intercept) / math.sqrt((line.slope ^ 2) + 1)
end

local length_of_ray_until_intersect = function(theta, line)
  return line.intercept / (math.sin(theta) - line.slope * math.cos(theta))
end

hsluv.get_bounds = function(l)
  local result = {}
  local sub2
  local sub1 = ((l + 16) ^ 3) / 1560896
  if sub1 > hsluv.epsilon then
    sub2 = sub1
  else
    sub2 = l / hsluv.kappa
  end

  for i = 1, 3 do
    local m1 = hsluv.m[i][1]
    local m2 = hsluv.m[i][2]
    local m3 = hsluv.m[i][3]

    for t = 0, 1 do
      local top1 = (284517 * m1 - 94839 * m3) * sub2
      local top2 = (838422 * m3 + 769860 * m2 + 731718 * m1) * l * sub2 - 769860 * t * l
      local bottom = (632260 * m3 - 126452 * m2) * sub2 + 126452 * t
      table.insert(result, { slope = top1 / bottom, intercept = top2 / bottom })
    end
  end
  return result
end

hsluv.max_safe_chroma_for_l = function(l)
  local bounds = hsluv.get_bounds(l)
  local min = 1.7976931348623157e+308

  for i = 1, 6 do
    local length = distance_line_from_origin(bounds[i])
    if length >= 0 then
      min = math.min(min, length)
    end
  end
  return min
end

hsluv.max_safe_chroma_for_lh = function(l, h)
  local hrad = h / 360 * math.pi * 2
  local bounds = hsluv.get_bounds(l)
  local min = 1.7976931348623157e+308

  for i = 1, 6 do
    local bound = bounds[i]
    local length = length_of_ray_until_intersect(hrad, bound)
    if length >= 0 then
      min = math.min(min, length)
    end
  end
  return min
end

hsluv.dot_product = function(a, b)
  local sum = 0
  for i = 1, 3 do
    sum = sum + a[i] * b[i]
  end
  return sum
end

hsluv.from_linear = function(c)
  if c <= 0.0031308 then
    return 12.92 * c
  else
    return 1.055 * (c ^ 0.416666666666666685) - 0.055
  end
end

hsluv.to_linear = function(c)
  if c > 0.04045 then
    return ((c + 0.055) / 1.055) ^ 2.4
  else
    return c / 12.92
  end
end

hsluv.xyz_to_rgb = function(tuple)
  return {
    hsluv.from_linear(hsluv.dot_product(hsluv.m[1], tuple)),
    hsluv.from_linear(hsluv.dot_product(hsluv.m[2], tuple)),
    hsluv.from_linear(hsluv.dot_product(hsluv.m[3], tuple)),
  }
end

hsluv.rgb_to_xyz = function(tuple)
  local rgbl = { hsluv.to_linear(tuple[1]), hsluv.to_linear(tuple[2]), hsluv.to_linear(tuple[3]) }
  return {
    hsluv.dot_product(hsluv.minv[1], rgbl),
    hsluv.dot_product(hsluv.minv[2], rgbl),
    hsluv.dot_product(hsluv.minv[3], rgbl),
  }
end

hsluv.y_to_l = function(Y)
  if Y <= hsluv.epsilon then
    return Y / hsluv.refY * hsluv.kappa
  else
    return 116 * ((Y / hsluv.refY) ^ 0.333333333333333315) - 16
  end
end

hsluv.l_to_y = function(L)
  if L <= 8 then
    return hsluv.refY * L / hsluv.kappa
  else
    return hsluv.refY * (((L + 16) / 116) ^ 3)
  end
end

hsluv.xyz_to_luv = function(tuple)
  local X = tuple[1]
  local Y = tuple[2]
  local divider = X + 15 * Y + 3 * tuple[3]
  local varU = 4 * X
  local varV = 9 * Y
  if divider ~= 0 then
    varU = varU / divider
    varV = varV / divider
  else
    varU = 0
    varV = 0
  end
  local L = hsluv.y_to_l(Y)
  if L == 0 then
    return { 0, 0, 0 }
  end
  return { L, 13 * L * (varU - hsluv.refU), 13 * L * (varV - hsluv.refV) }
end

hsluv.luv_to_xyz = function(tuple)
  local L = tuple[1]
  local U = tuple[2]
  local V = tuple[3]
  if L == 0 then
    return { 0, 0, 0 }
  end
  local varU = U / (13 * L) + hsluv.refU
  local varV = V / (13 * L) + hsluv.refV
  local Y = hsluv.l_to_y(L)
  local X = 0 - (9 * Y * varU) / (((varU - 4) * varV) - varU * varV)
  return { X, Y, (9 * Y - 15 * varV * Y - varV * X) / (3 * varV) }
end

hsluv.luv_to_lch = function(tuple)
  local L = tuple[1]
  local U = tuple[2]
  local V = tuple[3]
  local C = math.sqrt(U * U + V * V)
  local H
  if C < 0.00000001 then
    H = 0
  else
    H = math.atan2(V, U) * 180.0 / 3.1415926535897932
    if H < 0 then
      H = 360 + H
    end
  end
  return { L, C, H }
end

hsluv.lch_to_luv = function(tuple)
  local L = tuple[1]
  local C = tuple[2]
  local Hrad = tuple[3] / 360.0 * 2 * math.pi
  return { L, math.cos(Hrad) * C, math.sin(Hrad) * C }
end

hsluv.hsluv_to_lch = function(tuple)
  local H = tuple[1]
  local S = tuple[2]
  local L = tuple[3]
  if L > 99.9999999 then
    return { 100, 0, H }
  end
  if L < 0.00000001 then
    return { 0, 0, H }
  end
  return { L, hsluv.max_safe_chroma_for_lh(L, H) / 100 * S, H }
end

hsluv.lch_to_hsluv = function(tuple)
  local L = tuple[1]
  local C = tuple[2]
  local H = tuple[3]
  local max_chroma = hsluv.max_safe_chroma_for_lh(L, H)
  if L > 99.9999999 then
    return { H, 0, 100 }
  end
  if L < 0.00000001 then
    return { H, 0, 0 }
  end

  return { H, C / max_chroma * 100, L }
end

hsluv.hpluv_to_lch = function(tuple)
  local H = tuple[1]
  local S = tuple[2]
  local L = tuple[3]
  if L > 99.9999999 then
    return { 100, 0, H }
  end
  if L < 0.00000001 then
    return { 0, 0, H }
  end
  return { L, hsluv.max_safe_chroma_for_l(L) / 100 * S, H }
end

hsluv.lch_to_hpluv = function(tuple)
  local L = tuple[1]
  local C = tuple[2]
  local H = tuple[3]
  if L > 99.9999999 then
    return { H, 0, 100 }
  end
  if L < 0.00000001 then
    return { H, 0, 0 }
  end
  return { H, C / hsluv.max_safe_chroma_for_l(L) * 100, L }
end

hsluv.rgb_to_hex = function(tuple)
  local h = "#"
  for i = 1, 3 do
    local c = math.floor(tuple[i] * 255 + 0.5)
    local digit2 = math.fmod(c, 16)
    local x = (c - digit2) / 16
    local digit1 = math.floor(x)
    h = h .. string.sub(hexChars, digit1 + 1, digit1 + 1)
    h = h .. string.sub(hexChars, digit2 + 1, digit2 + 1)
  end
  return h
end

hsluv.hex_to_rgb = function(hex)
  hex = string.lower(hex)
  local ret = {}
  for i = 0, 2 do
    local char1 = string.sub(hex, i * 2 + 2, i * 2 + 2)
    local char2 = string.sub(hex, i * 2 + 3, i * 2 + 3)
    local digit1 = string.find(hexChars, char1) - 1
    local digit2 = string.find(hexChars, char2) - 1
    ret[i + 1] = (digit1 * 16 + digit2) / 255.0
  end
  return ret
end

hsluv.lch_to_rgb = function(tuple)
  return hsluv.xyz_to_rgb(hsluv.luv_to_xyz(hsluv.lch_to_luv(tuple)))
end

hsluv.rgb_to_lch = function(tuple)
  return hsluv.luv_to_lch(hsluv.xyz_to_luv(hsluv.rgb_to_xyz(tuple)))
end

hsluv.hsluv_to_rgb = function(tuple)
  return hsluv.lch_to_rgb(hsluv.hsluv_to_lch(tuple))
end

hsluv.rgb_to_hsluv = function(tuple)
  return hsluv.lch_to_hsluv(hsluv.rgb_to_lch(tuple))
end

hsluv.hpluv_to_rgb = function(tuple)
  return hsluv.lch_to_rgb(hsluv.hpluv_to_lch(tuple))
end

hsluv.rgb_to_hpluv = function(tuple)
  return hsluv.lch_to_hpluv(hsluv.rgb_to_lch(tuple))
end

hsluv.hsluv_to_hex = function(tuple)
  return hsluv.rgb_to_hex(hsluv.hsluv_to_rgb(tuple))
end

hsluv.hpluv_to_hex = function(tuple)
  return hsluv.rgb_to_hex(hsluv.hpluv_to_rgb(tuple))
end

hsluv.hex_to_hsluv = function(s)
  return hsluv.rgb_to_hsluv(hsluv.hex_to_rgb(s))
end

hsluv.hex_to_hpluv = function(s)
  return hsluv.rgb_to_hpluv(hsluv.hex_to_rgb(s))
end

hsluv.hex_to_okhsl = function(s)
  return hsluv.srgb_to_okhsl(hsluv.hex_to_rgb(s))
end

hsluv.okhsl_to_hex = function(s)
  return hsluv.rgb_to_hex(hsluv.okhsl_to_srgb(s))
end

hsluv.okhsl_to_srgb = function(tuple)
  local Hrad = tuple[1] / 360.0 * 2 * math.pi
  local s = tuple[2] / 100.0
  local L_r = tuple[3] / 100.0

  if tuple[3] > 99.9999999 then
    return { 1, 1, 1 }
  end
  if tuple[3] < 0.00000001 then
    return { 0, 0, 0 }
  end

  local a_ = math.cos(Hrad)
  local b_ = math.sin(Hrad)
  local L = hsluv.toe_inv(L_r)

  local Cs = hsluv.get_Cs(L, a_, b_)
  local C_0 = Cs[1]
  local C_mid = Cs[2]
  local C_max = Cs[3]

  local C, t, k_0, k_1, k_2

  if s < 0.8 then
    t = 1.25 * s
    k_0 = 0
    k_1 = 0.8 * C_0
    k_2 = (1 - k_1 / C_mid)
  else
    t = 5 * (s - 0.8)
    k_0 = C_mid
    k_1 = 0.2 * C_mid * C_mid * 1.25 * 1.25 / C_0
    k_2 = (1 - k_1 / (C_max - C_mid))
  end

  C = k_0 + t * k_1 / (1 - k_2 * t)

  -- If you would only use one of the Cs:
  -- C = s * C_0
  -- C = s * 1.25 * C_mid
  -- C = s * C_max

  local rgb = hsluv.oklab_to_linear_srgb(L, C * a_, C * b_)

  return {
    hsluv.from_linear(rgb[1]),
    hsluv.from_linear(rgb[2]),
    hsluv.from_linear(rgb[3])
  }
end

hsluv.srgb_to_okhsl = function(tuple)
    if (tuple[1] < 0.00000001 and tuple[2] < 0.00000001 and tuple[3] < 0.00000001) then
        return {0, 0, 0}
    end
    local lab = hsluv.linear_srgb_to_oklab(
        hsluv.to_linear(tuple[1]),
        hsluv.to_linear(tuple[2]),
        hsluv.to_linear(tuple[3])
    )

    local C = math.sqrt(lab[2]^2 + lab[3]^2)
    local a_ = lab[2]/C
    local b_ = lab[3]/C

    local L = lab[1]
    local h = 0
    if (math.abs(lab[2]) > 0.0000001 or math.abs(lab[3]) > 0.0000001) then
      h = 0.5 + 0.5*math.atan2(-lab[3], -lab[2])/math.pi
    end

    local Cs = hsluv.get_Cs(L, a_, b_)
    local C_0 = Cs[1]
    local C_mid = Cs[2]
    local C_max = Cs[3]

    local s

    if C < C_mid then
        local k_0 = 0
        local k_1 = 0.8*C_0
        local k_2 = (1-k_1/C_mid)

        local t = (C - k_0)/(k_1 + k_2*(C - k_0))
        s = t*0.8
    else
        local k_0 = C_mid
        local k_1 = 0.2*C_mid*C_mid*1.25*1.25/C_0
        local k_2 = (1 - (k_1)/(C_max - C_mid))

        local t = (C - k_0)/(k_1 + k_2*(C - k_0))
        s = 0.8 + 0.2*t
    end

    local l = hsluv.toe(L)
    if l > 0.998 then
        h = 0
        s = 0
    end
    return {h*360, s*100, l*100}
end

hsluv.get_Cs = function(L, a_, b_)
  local cusp = hsluv.find_cusp(a_, b_)

  local C_max = hsluv.find_gamut_intersection(a_, b_, L, 1, L, cusp)
  local ST_max = hsluv.get_ST_max(a_, b_, cusp)

  local S_mid = 0.11516993 + 1 / (
  7.44778970 + 4.15901240 * b_ + a_ * (-2.19557347 + 1.75198401 * b_ + a_ * (-2.13704948 - 10.02301043 * b_ + a_ * (-4.24894561 + 5.38770819 * b_ + 4.69891013 * a_)))
)

  local T_mid = 0.11239642 + 1 / (
  1.61320320 - 0.68124379 * b_ + a_ * (0.40370612 + 0.90148123 * b_ + a_ * (-0.27087943 + 0.61223990 * b_ + a_ * (0.00299215 - 0.45399568 * b_ - 0.14661872 * a_)))
)

  local k = C_max / math.min(L * ST_max[1], (1 - L) * ST_max[2])

  local C_a = L * S_mid
  local C_b = (1 - L) * T_mid

  local C_mid = 0.9 * k * math.sqrt(math.sqrt(1 / (1 / (C_a^4) + 1 / (C_b^4))))

  local C_a_0 = L * 0.4
  local C_b_0 = (1 - L) * 0.8

  local C_0 = math.sqrt(1 / (1 / (C_a_0^2) + 1 / (C_b_0^2)))

  return {C_0, C_mid, C_max}
end

hsluv.get_ST_max = function(a, b, cusp)
  if cusp == nil then
    cusp = hsluv.find_cusp(a, b)
  end

  local L = cusp[1]
  local C = cusp[2]

  return {C / L, C / (1 - L)}
end
-- Function to get mid saturation and chroma
hsluv.get_ST_mid = function(a, b)
  local S = 0.11516993 + 1 / (7.44778970 + 4.15901240 * b + a * (-2.19557347 + 1.75198401 * b + a * (-2.13704948 - 10.02301043 * b + a * (-4.24894561 + 5.38770819 * b + 4.69891013 * a))))
  local T = 0.11239642 + 1 / (1.61320320 - 0.68124379 * b + a * (0.40370612 + 0.90148123 * b + a * (-0.27087943 + 0.61223990 * b + a * (0.00299215 - 0.45399568 * b - 0.14661872 * a))))
  return {S, T}
end

hsluv.toe = function(L)
  L_r =  0.5 * (hsluv.K_3 * L - hsluv.K_1 + math.sqrt((hsluv.K_3 * L - hsluv.K_1) * (hsluv.K_3 * L - hsluv.K_1) + 4 * hsluv.K_2 * hsluv.K_3 * L))
  return L_r
end

hsluv.oklab_to_linear_srgb = function(L, a, b)
  local l_ = L + 0.3963377774 * a + 0.2158037573 * b
  local m_ = L - 0.1055613458 * a - 0.0638541728 * b
  local s_ = L - 0.0894841775 * a - 1.2914855480 * b

  local l = l_ * l_ * l_
  local m = m_ * m_ * m_
  local s = s_ * s_ * s_

  return {
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
  }
end

hsluv.linear_srgb_to_oklab = function(r, g, b)
    local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    local l_ = l^(1/3)
    local m_ = m^(1/3)
    local s_ = s^(1/3)

    return {
        0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_,
        1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_,
        0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
    }
end

hsluv.find_cusp = function(a, b)
  -- First, find the maximum saturation (saturation S = C/L)
  local S_cusp = hsluv.compute_max_saturation(a, b)

  -- Convert to linear sRGB to find the first point where at least one of r,g or b >= 1:
  local rgb_at_max = hsluv.oklab_to_linear_srgb(1, S_cusp * a, S_cusp * b)
  local max_rgb = math.max(rgb_at_max[1], rgb_at_max[2], rgb_at_max[3])
  local L_cusp = 1 / max_rgb^(1/3)
  local C_cusp = L_cusp * S_cusp

  return {L_cusp, C_cusp}
end

hsluv.compute_max_saturation = function(a, b)
  -- Max saturation will be when one of r, g, or b goes below zero.
  -- Select different coefficients depending on which component goes below zero first
  local k0, k1, k2, k3, k4, wl, wm, ws

  if -1.88170328 * a - 0.80936493 * b > 1 then
    -- Red component
    k0, k1, k2, k3, k4 = 1.19086277, 1.76576728, 0.59662641, 0.75515197, 0.56771245
    wl, wm, ws = 4.0767416621, -3.3077115913, 0.2309699292
  elseif 1.81444104 * a - 1.19445276 * b > 1 then
    -- Green component
    k0, k1, k2, k3, k4 = 0.73956515, -0.45954404, 0.08285427, 0.12541070, 0.14503204
    wl, wm, ws = -1.2684380046, 2.6097574011, -0.3413193965
  else
    -- Blue component
    k0, k1, k2, k3, k4 = 1.35733652, -0.00915799, -1.15130210, -0.50559606, 0.00692167
    wl, wm, ws = -0.0041960863, -0.7034186147, 1.7076147010
  end

  -- Approximate max saturation using a polynomial
  local S = k0 + k1 * a + k2 * b + k3 * a * a + k4 * a * b

  -- Do one step Halley's method to get closer
  local k_l = 0.3963377774 * a + 0.2158037573 * b
  local k_m = -0.1055613458 * a - 0.0638541728 * b
  local k_s = -0.0894841775 * a - 1.2914855480 * b

  local l_ = 1 + S * k_l
  local m_ = 1 + S * k_m
  local s_ = 1 + S * k_s

  local l = l_ * l_ * l_
  local m = m_ * m_ * m_
  local s = s_ * s_ * s_

  local l_dS = 3 * k_l * l_ * l_
  local m_dS = 3 * k_m * m_ * m_
  local s_dS = 3 * k_s * s_ * s_

  local l_dS2 = 6 * k_l * k_l * l_
  local m_dS2 = 6 * k_m * k_m * m_
  local s_dS2 = 6 * k_s * k_s * s_

  local f  = wl * l     + wm * m     + ws * s
  local f1 = wl * l_dS  + wm * m_dS  + ws * s_dS
  local f2 = wl * l_dS2 + wm * m_dS2 + ws * s_dS2

  S = S - f * f1 / (f1*f1 - 0.5 * f * f2)

  return S
end

hsluv.find_gamut_intersection = function(a, b, L1, C1, L0, cusp)
    if not cusp then
        -- Find the cusp of the gamut triangle
        cusp = hsluv.find_cusp(a, b)
    end

    -- Find the intersection for upper and lower half separately
    local t

    if ((L1 - L0) * cusp[2] - (cusp[1] - L0) * C1) <= 0 then
        -- Lower half
        t = cusp[2] * L0 / (C1 * cusp[1] + cusp[2] * (L0 - L1))
    else
        -- Upper half

        -- First intersect with triangle
        t = cusp[2] * (L0 - 1) / (C1 * (cusp[1] - 1) + cusp[2] * (L0 - L1))

        -- Then one step Halley's method
        local dL = L1 - L0
        local dC = C1

        local k_l =  0.3963377774 * a + 0.2158037573 * b
        local k_m = -0.1055613458 * a - 0.0638541728 * b
        local k_s = -0.0894841775 * a - 1.2914855480 * b

        local l_dt = dL + dC * k_l
        local m_dt = dL + dC * k_m
        local s_dt = dL + dC * k_s

        -- If higher accuracy is required, 2 or 3 iterations of the following block can be used:
        local L = L0 * (1 - t) + t * L1
        local C = t * C1

        local l_ = L + C * k_l
        local m_ = L + C * k_m
        local s_ = L + C * k_s

        local l = l_ * l_ * l_
        local m = m_ * m_ * m_
        local s = s_ * s_ * s_

        local ldt = 3 * l_dt * l_ * l_
        local mdt = 3 * m_dt * m_ * m_
        local sdt = 3 * s_dt * s_ * s_

        local ldt2 = 6 * l_dt * l_dt * l_
        local mdt2 = 6 * m_dt * m_dt * m_
        local sdt2 = 6 * s_dt * s_dt * s_

        local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s - 1
        local r1 = 4.0767416621 * ldt - 3.3077115913 * mdt + 0.2309699292 * sdt
        local r2 = 4.0767416621 * ldt2 - 3.3077115913 * mdt2 + 0.2309699292 * sdt2

        local u_r = r1 / (r1 * r1 - 0.5 * r * r2)
        local t_r = -r * u_r

        local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s - 1
        local g1 = -1.2684380046 * ldt + 2.6097574011 * mdt - 0.3413193965 * sdt
        local g2 = -1.2684380046 * ldt2 + 2.6097574011 * mdt2 - 0.3413193965 * sdt2

        local u_g = g1 / (g1 * g1 - 0.5 * g * g2)
        local t_g = -g * u_g

        b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s - 1
        local b1 = -0.0041960863 * ldt - 0.7034186147 * mdt + 1.7076147010 * sdt
        local b2 = -0.0041960863 * ldt2 - 0.7034186147 * mdt2 + 1.7076147010 * sdt2

        local u_b = b1 / (b1 * b1 - 0.5 * b * b2)
        local t_b = -b * u_b

        t_r = u_r >= 0 and t_r or 10e5
        t_g = u_g >= 0 and t_g or 10e5
        t_b = u_b >= 0 and t_b or 10e5

        t = t + math.min(t_r, math.min(t_g, t_b))
    end

    return t
end

hsluv.toe_inv = function(L_r)
  local L = (L_r * L_r + hsluv.K_1 * L_r) / (hsluv.K_3 * (L_r + hsluv.K_2))
  return L
end

hsluv.K_1 = 0.206
hsluv.K_2 = 0.03
hsluv.K_3 = (1.0 + hsluv.K_1) / (1.0 + hsluv.K_2)

hsluv.m = {
  { 3.240969941904521, -1.537383177570093, -0.498610760293 },
  { -0.96924363628087, 1.87596750150772, 0.041555057407175 },
  { 0.055630079696993, -0.20397695888897, 1.056971514242878 },
}
hsluv.minv = {
  { 0.41239079926595, 0.35758433938387, 0.18048078840183 },
  { 0.21263900587151, 0.71516867876775, 0.072192315360733 },
  { 0.019330818715591, 0.11919477979462, 0.95053215224966 },
}
hsluv.refY = 1.0
hsluv.refU = 0.19783000664283
hsluv.refV = 0.46831999493879
hsluv.kappa = 903.2962962
hsluv.epsilon = 0.0088564516

return hsluv
