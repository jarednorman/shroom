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
run("let")
run("let x")
run("let x = 1")
run("let x = 1 + 2")
run("letx")        -- should be a single IDENT, not LET + IDENT
run("let1")        -- should be a single IDENT (identifiers can contain digits after first char)
run("foo_bar")     -- underscores work
run("_x")          -- leading underscore works
