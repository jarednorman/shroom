local Lexer = require("lexer")
local Parser = require("parser")

local function show_ast(node, indent)
  indent = indent or ""
  if type(node) ~= "table" then
    io.write(tostring(node))
    return
  end
  io.write(node.tag or "?")
  for k, v in pairs(node) do
    if k ~= "tag" and k ~= "line" and k ~= "col" then
      io.write("\n", indent, "  ", k, ": ")
      show_ast(v, indent .. "  ")
    end
  end
end

local function show(node)
  show_ast(node)
  io.write("\n")
end

local function run(source)
  print("input: " .. string.format("%q", source))
  local tokens = Lexer.new(source):tokenize()
  local ast = Parser.new(tokens):parse_program()
  show(ast)
end

run("let x = 1")
run("let x = 1 + 2")
run("let x = 1 + 2 + 3")
run("let x = 1 + y")
