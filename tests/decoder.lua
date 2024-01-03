local toml = require"toml"
local json = require"tests.json"


local types = {
  datetime = "datetime",
  localdate = "date",
  localtime = "time"
}

-- https://stackoverflow.com/a/69827191
local function float_to_string(x)
  for precision = 15, 17 do
    -- Use a 2-layer format to try different precisions with %g.
    local s = ('%%.%dg'):format(precision):format(x)
    -- See if s is an exact representation of x.
    if tonumber(s) == x then
      return s
    end
  end
end

local function encode(tbl, root)
  root = root or setmetatable({}, {__jsontype="object"})
  for key, value in pairs(tbl) do
    local t = type(value)

    if t == "table" and not value.__type then -- array or table
      local t = setmetatable({}, getmetatable(value))
      root[key] = encode(value, t)
    elseif t == "table" and value.__type then --time
      root[key] = {
        type = types[value.__type] .. (value.offset and "" or "-local"),
        value = value.input
      }
    elseif t == "boolean" then
      root[key] = {
        type = "bool",
        value = tostring(value)
      }
    elseif t == "string" then
      root[key] = {
        type = "string",
        value = value
      }
    elseif t == "number" then
      local float = math.fmod(value, 1) ~= 0

      local v = tostring(value)
      -- luajit, lua5.1, 5.2, 5.3 and 5.4 need to be tuned by hand (eg -0 parsed as -0 by lua < 5.3 and 0 by lua > 5.2) 
      if not float then
        v = v:gsub("%..+$", "")
        if value == 0 and v:sub(1,1) == "-" then
          v = v:gsub("^%-", "")
        end
      end

      root[key] = {
        type = float and "float" or "integer",
        value = v
      }
      -- float tostring precision loss
      -- value == value ensure that valu is not nan or inf
      if float and value == value and math.abs(value) ~= math.huge then
        root[key].value = float_to_string(value)
      end
    end

  end
  return root
end

io.stdin:flush()
local data = io.stdin:read("*a")


local table, err, t = toml.parse(data)

if err then
  io.stderr:write(err .. "\n")
  os.exit(1)
end

local encoded = json.encode(encode(table))
print(encoded)

os.exit(0)