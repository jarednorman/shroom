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

function Parser:skip_newlines()
  while self:check(Tokens.types.NEWLINE) do
    self:advance()
  end
end

function Parser:parse_program()
  local statements = {}

  self:skip_newlines() -- Allow leading blank lines.

  while not self:check(Tokens.types.EOF) do
    local statement = self:parse_statement()
    table.insert(statements, statement)

    if self:check(Tokens.types.EOF) then break end

    if not self:check(Tokens.types.NEWLINE) then
      local t = self:peek()
      error(string.format("expected newline or end of file after statement, got %s at line %d, col %d",
                          t.type, t.line, t.col))
    end

    self:skip_newlines()
  end

  return Ast.Program(statements, 1, 1)
end

function Parser:parse_statement()
  if self:check(Tokens.types.LET) then
    return self:parse_let()
  end

  return self:parse_expression_statement()
end

function Parser:parse_let()
  local let_token = self:expect(Tokens.types.LET)
  local name_token = self:expect(Tokens.types.IDENT)

  self:expect(Tokens.types.EQ)
  self:skip_newlines()

  local value = self:parse_expression()

  return Ast.LetBinding(name_token.value, value, let_token.line, let_token.col)
end

function Parser:parse_expression_statement()
  local expression = self:parse_expression()
  return Ast.ExprStmt(expression, expression.line, expression.col)
end

local PRECEDENCE = {
  [Tokens.types.PLUS]  = 10,
  [Tokens.types.MINUS] = 10,
  [Tokens.types.STAR]  = 20,
  [Tokens.types.SLASH] = 20,
}

local function precedence_of(token)
  return PRECEDENCE[token.type] or 0
end

function Parser:parse_expression(min_precedence)
  min_precedence = min_precedence or 0

  local left = self:parse_postfix()

  while true do
    local token = self:peek()
    local precedence = precedence_of(token)

    -- Here, a precedence of zero means this is not an operator that can
    -- continue the expression.
    if precedence < min_precedence or precedence == 0 then break end

    self:advance()

    local right = self:parse_expression(precedence + 1)

    left = Ast.BinOp(Tokens.operators[token.type], left, right, token.line, token.col)
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

function Parser:parse_postfix()
  local expression = self:parse_primary()

  while true do
    if self:check(Tokens.types.LPAREN) then
      expression = self:parse_call(expression)
    else
      break
    end
  end

  return expression
end

function Parser:parse_call(callee)
  local lparen = self:expect(Tokens.types.LPAREN)

  local args = {}

  if not self:check(Tokens.types.RPAREN) then
    table.insert(args, self:parse_expression())

    while self:match(Tokens.types.COMMA) do
      self:skip_newlines()
      table.insert(args, self:parse_expression())
    end
  end
  self:skip_newlines()
  self:expect(Tokens.types.RPAREN)

  return Ast.Call(callee, args, callee.line, callee.col)
end

return Parser
