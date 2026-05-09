local Lexer = require("lexer")
local Parser = require("parser")
local check = require("checker")
local generate = require("codegen")

local PRELUDE = [[
local print_int = print
local print_bool = print
]]

local function compile(source)
  local tokens = Lexer.new(source):tokenize()
  local ast = Parser.new(tokens):parse_program()
  check(ast)
  return PRELUDE .. generate(ast)
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then
    io.stderr:write("shroom: cannot open " .. path .. ": " .. err .. "\n")
    os.exit(1)
  end
  local source = f:read("*a")
  f:close()
  return source
end

local function write_file(path, contents)
  local f, err = io.open(path, "w")
  if not f then
    io.stderr:write("shroom: cannot write " .. path .. ": " .. err .. "\n")
    os.exit(1)
  end
  f:write(contents)
  f:close()
end


local function output_path_for(input_path)
  -- foo.shr  -> foo.shr.lua
  local base, ext = input_path:match("^(.*)%.(.*)$")

  if not base then
    io.stderr:write("shroom: input file must have an extension\n")
    os.exit(1)
  end

  return base .. "." .. ext .. ".lua"
end


local function main()
  if #arg ~= 1 then
    io.stderr:write("usage: lua shroom.lua <file.shr>\n")
    os.exit(1)
  end

  local input_path = arg[1]
  local source = read_file(input_path)
  local lua_source = compile(source)
  local output_path = output_path_for(input_path)
  write_file(output_path, lua_source .. "\n")
  print("compiled " .. input_path .. " -> " .. output_path)
end

main()
