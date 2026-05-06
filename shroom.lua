local Lexer = require("lexer")
local Parser = require("parser")
local generate = require("codegen")

local function compile(source)
  local tokens = Lexer.new(source):tokenize()
  local ast = Parser.new(tokens):parse_program()
  return generate(ast)
end

local function run(source)
  print("input:  " .. source)
  print("output: " .. compile(source))
  print("---")
end

run("let x = 1")
run("let x = 1 + 2")
run("let x = 1 + 2 + 3")
run("let x = 1 + y")
