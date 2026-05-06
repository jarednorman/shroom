-- shroom.lua
local Lexer = require("lexer")

local function show(tokens)
  for _, t in ipairs(tokens) do
    print(t.type, t.value, "at", t.line .. ":" .. t.col)
  end
end

local function run(source)
  print("input: " .. string.format("%q", source))
  show(Lexer.new(source):tokenize())
  print("---")
end

run("42")
run("  123   456  ")
run("")
run("1\n2")
