# toml.lua
A [toml](https://toml.io) v1.0.0 decoder/encoder written in pure [lua](https://lua.org)

# Summary
1. [Installation](#installation)
2. [Usage](#usage)
3. [Tests](#tests)
4. [Limitations](#limitations)
5. [Licence](#licence)

# Installation
toml.lua is compatible with:
  - lua 5.x
  - luajit

You can copy the [toml.lua](./toml.lua) file and put it directly in your project or use [lit](https://github.com/luvit/lit) with the following command

```
$ lit install lil-evil/toml
```

No dependencies

# Usage
Simply require it and start using it :
```lua
local toml = require"toml"

local toml_file = [=[
  key = "value"

  [header]
  number = 42
]=]

local parsed, err = toml.parse(toml_file)
```
The parser should not throw any error, and if so, it's a bug

the table `toml` contains constants and function that are usefull for integration:


|     name    |   type   | description                                        |
|-------------|----------|----------------------------------------------------|
| error_code  |   table  | contain all error id that indentify an error       |
|error_message|   table  | contain all error message with error id as key     |
|   encode    | function | encode a lua table to a toml string (COMING SOON) |
|   decode    | function | decode a toml string to lua table                  |
|    parse    | function | same a decode (naming convennience)                |
|   version   |  string  | toml.lua version                                   |

The parsing functions take a single string and return 3 values:
  - `table`|`nil`  : the parsed table or nil in case of error
  - `nil`|`string` : the error message fomatted with line and pos
  - `nil`|`table`  : the error table, with formatted message, error id, line and pos of the error (for advanced use cases, when reporting the error message is not enough)

Data are parsed to their respective data type in lua:
  - **strings**
  - **numbers**
  - **boolean**
  - **table** => contains a metatable: `{__tomltype="table", __jsontype="object", __tomlheader=bool, __tomlinline=bool}`
  - **array** (also table) => contains a metatable: `{__tomltype="array", __jsontype="array", __tomlheader=bool, __tomlinline=bool}`

And dates are supported. any parsed dates are translated to a table with following fields:
  - **__type**: "localtime", "localdate" or "datetime"
  - **timestamp**: the unix timestamp calculated with os.time and converted to milliseconds, and offset applied
  - **offset**: present if the datetime contains an offset at the end, and **already applied to the timestamp**
  - **input**: the date/time given to the parser, undisturbed
  - from metatable (all strings):
    - **year**
    - **month**
    - **day**
    - **hour**
    - **min**
    - **sec**
    - **ms**
  
Example:
```lua
local datetime = {
  __type    = 'datetime', 
  input     = '1998-11-19T13:41:00.255+01:00',
  timestamp = 911482860255,
  offset    = 3600000,

  -- the following are calculated with the __index meta using the timestamp
  year      = "1998",
  month     = "11",
  day       = "19",
  hour      = "14",
  min       = "41",
  sec       = "00",
  ms        = "255",
}
```

# Tests
Toml.lua passes most of [toml-test](https://github.com/toml-lang/toml-test) validations.

For validation, I used modified tests and skipped some other for diverses reasons

You can test the parser localy with [test.lua](./test.lua) which currently require [luvit](https://luvit.io) as a lua runtime, it automatically download toml-test, unpack it and run the test using the specified lua runtime (default luvit)

*In the near futur, test.lua will not require luvit to work, and will emulate toml-test by itself, using any lua runtime*
```
$ luvit test.lua lua-runtime
```
or with the magic of shebangs
```
$ ./test.lua lua-runtime
```

where lua-runtime is a valid command that invoque a lua interpreter (eg lua5.1, luajit, luvit...)

The modified tests with justification are listed [here](./tests/tests/changes)

For skipped tests, it's listed [here](./test.lua?plain=1#L28) and if any of theses tests/features seems really important for you, open an issue and i'll work on it

# Limitations
Skipped and modified tests are not just for fun, there are limitaions for this parser, either by lua itself, or my brain lacking coffe to handle some problems (I guess)

- Numbers above 2^53 loose precision, but the parser does not raise error
- [this pull](https://github.com/toml-lang/toml/pull/859) is not handled currently, and thuse, allow dotted keys to append on header table
- comments are just ignored, no unicode verification is done on them


# Licence
This project is licensed under the MIT License. See the [LICENSE](./LICENCE) file for more information.