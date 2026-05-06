local Tokens = require("tokens")
local Ast = require("ast")

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
  return setmetatable({ tokens = tokens, pos = 1 }, Parser)
end

function Parser:peek()
  return self.tokens[self.pos]
end

function Parser:advance()
  local t = self.tokens[self.pos]
  self.pos = self.pos + 1
  return t
end

function Parser:check(type)
  return self:peek().type == type
end

function Parser:match(type)
  if self:check(type) then
    return self:advance()
  end
  return nil
end

function Parser:expect(type)
  if self:check(type) then return self:advance() end

  local t = self:peek()
  error(string.format("expected %s but got %s at line %d, col %d",
                        type, t.type, t.line, t.col))
end

function Parser:parse_program()
  local statement = self:parse_statement()
  self:expect(Tokens.types.EOF)
  return statement
end

function Parser:parse_statement()
  if self:check(Tokens.types.LET) then
    return self:parse_let()
  end
  -- Could also be a bare expression, but we'll add that later.
  error("expected a statement")
end

function Parser:parse_let()
  local let_token = self:expect(Tokens.types.LET)
  local name_token = self:expect(Tokens.types.IDENT)

  self:expect(Tokens.types.EQ)

  local value = self:parse_expression()
  return Ast.LetBinding(name_token.value, value, let_token.line, let_token.col)
end

function Parser:parse_expression()
  -- Currently, we only support addition.
  local left = self:parse_primary()

  while self:check(Tokens.types.PLUS) do
    local op_token = self:advance()
    local right = self:parse_primary()
    left = Ast.BinOp("+", left, right, op_token.line, op_token.col)
  end

  return left
end

function Parser:parse_primary()
  local t = self:peek()

  if t.type == Tokens.types.INT then
    self:advance()
    return Ast.IntLit(t.value, t.line, t.col)
  end

  if t.type == Tokens.types.IDENT then
    self:advance()
    return Ast.Ident(t.value, t.line, t.col)
  end

  error(string.format("unexpected token %s at line %d, col %d",
                      t.type, t.line, t.col))
end

return Parser
