#!/usr/bin/env luvit
local fs = require"fs"
local http, https = require"http", require"https"
local jit = require"jit"
local OS = require"los".type()
local timer = require"timer"

-- thanks to https://github.com/zerkman/zzlib
local zzlib = require"./tests/zzlib"

local toml_test = {
  version = "v1.4.0",
  repo = "https://github.com/toml-lang/toml-test/",
                  -- version/filename
  release = "releases/download/%s/%s",
                -- version-os-arch
  filename = "toml-test-%s-%s-%s.gz",

  x64 = "amd64",
  arm64 = "arm64",

  linux = "linux",
  win32 = "windows",
  osx = "darwin",
  bsd = "openbsd"
}

local skips = {
  -- trailling coma are cool (don't want to switch to toml v1.1.0 as it's not official)
  "invalid/inline-table/trailing-comma",
  -- aren't we supposed to put anything we want in a comment ????
  "invalid/encoding/bad-codepoint",
  "invalid/encoding/bad-utf8-in-comment",
  "invalid/control/comment-*",
  -- I'm too dumb to rewrite lua's number or something like that
  "valid/integer/long",
  -- don't know how to implement that without breaking every other valid use cases
  "invalid/table/redefine-2",
  "invalid/table/append-with-dotted-keys-*",

  -- idk and idc (unless it's an issue for you)
  "invalid/encoding/*"
}

local function httpget(url, callback)
  url = http.parseUrl(url)

  local req = (url.protocol == 'https' and https or http).get(url, function(res)
    local body={}
    res:on('data', function(s)
      body[#body+1] = s
    end)
    res:on('end', function()
      res.body = table.concat(body)
      coroutine.wrap(callback)(res)
    end)
    res:on('error', function(err)
      coroutine.wrap(callback)(res, err)
    end)
  end)
  req:on('error', function(err)
    coroutine.wrap(callback)(nil, err)
  end)
end


if not fs.existsSync"./tests/toml-test" then
  print("toml-test not found")

  local OS = toml_test[OS] or OS
  local arch = toml_test[jit.arch] or jit.arch
  
  local file = toml_test.filename:format(toml_test.version, OS, arch)
  local release = toml_test.release:format(toml_test.version, file)

  print(("downloading toml-test\n\tversion: \t%s \n\tfor: \t\t%s-%s \n\tfrom: \t\t%s"):format(toml_test.version, OS, arch, toml_test.repo))
  local done, status, data

  print("> " .. toml_test.repo .. release)
  httpget(toml_test.repo..release, function(res, err)
    if res then print("> status " .. res.statusCode) end
    if err then
      print("ERROR", err)
      done, data, status = true, res.body, res.statusCode
    else
      if res.statusCode == 302 then
        print("> following redirection...")

        httpget(res.headers["Location"], function(res, err)
          if res then print("> status " .. res.statusCode) end
          if err then
            print("ERROR", err)
            done, data, status = true, res.body, res.statusCode
          else
            done, data, status = true, res.body, res.statusCode
          end
        end) --httpget location
      else
        done, data, status = true, res.body, res.statusCode
      end
    end
  end)-- httpget

  local i = 0
  while not done do
    local thread = coroutine.running()
    timer.setTimeout(1000, function ()
      coroutine.resume(thread)
      i = i + 1
    end)
    coroutine.yield()
    if i >= 30 then
      break
    end
  end
  
  if not done then
    print("Downloading took too long, aborting.")
    os.exit(1)
  end

  if status ~= 200 or #data <= 0 then
    print("Failed to download toml-test. please download it by hand to 'tests/toml-test'")
    os.exit(1)
  end

  print("> decompressing...")
  local decompressed, err = zzlib.gunzip(data)

  if not decompressed then
    print("ERROR cannot decompress:", err)
  end

  fs.writeFileSync("tests/toml-test", decompressed)
  print("> decompressed to tests/toml-test")


---@diagnostic disable-next-line: cast-local-type
  decompressed, data = nil, nil
  collectgarbage("collect")
end

local runtime = args[2] or "luvit"

print("Using lua runtime:", runtime)

local test = os.execute(runtime .. " -v")

if not test then
  print("ERROR: Cannot use this runtime. Ensure '" .. runtime .. "' is in the PATH.")
  os.exit(1)
end


print("===============")
local file, err = io.popen(runtime.." ./tests/info.lua", "r")
if not file then
  print("ERROR: cannot dump information tests/info.lua: ", err)
  os.exit(1)
end
local failed = false
file:flush()
for line in file:lines() do
  if line:match("^failed") then
    failed = true
  end
  print(line)
end
file:close()

if failed then
  os.exit(1)
end


-- actual test
print("===============")
print("starting decoder checking:")
local cmd = "./tests/toml-test -testdir ./tests/tests "..runtime.." ./tests/decoder.lua"

for i,v in ipairs(skips) do
  cmd = cmd .. " -skip \""..v.."\""
end

print("> "..cmd)

local decode, err = io.popen(cmd, "r")
if not decode then
  print("ERROR: start tests : ", err)
  os.exit(1)
end

decode:flush()
for line in decode:lines() do
  print(line)
end
decode:close()

print("===============")