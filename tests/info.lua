local is_jit, jit = pcall(require, "jit")
local is_luvi, luvi = pcall(require, "luvi")
local has_toml, toml = pcall(require, "toml")
local has_json, json = pcall(require, "tests.json")

if not has_toml then
  print("failed: cannot open toml.lua : ", toml)
  os.exit(1)
end

if not has_json then
  print("failed: cannot open json.lua : ", json)
  os.exit(1)
end

arg = arg or args

print("Informations:")
print("\truntime : ", arg[-1] or arg[0] )
print("\tlua :\t", _VERSION)
print("\ttoml.lua : ", toml.version)
print("\tjit :\t", is_jit)
print("\tluvi :\t", is_luvi)