local Tokens = require("tokens")
local Ast = require("ast")

local function make_item(line, col)
  return {
    line = line,
    col = col,
    name = nil,
    type_expr = nil,
    expr = nil
  }
end

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
  [Tokens.types.OR]      = 3,
  [Tokens.types.AND]     = 4,
  [Tokens.types.EQ_EQ]   = 5,
  [Tokens.types.BANG_EQ] = 5,
  [Tokens.types.LT]      = 5,
  [Tokens.types.LT_EQ]   = 5,
  [Tokens.types.GT]      = 5,
  [Tokens.types.GT_EQ]   = 5,
  [Tokens.types.PLUS]    = 10,
  [Tokens.types.MINUS]   = 10,
  [Tokens.types.STAR]    = 20,
  [Tokens.types.SLASH]   = 20,
}

local function precedence_of(token)
  return PRECEDENCE[token.type] or 0
end

function Parser:finish_lambda(lparen, items)
  local params = {}
  for _, item in ipairs(items) do
    if not item.name then
      error(string.format(
        "expected parameter name at line %d, col %d",
        item.line, item.col))
    end
    if not item.type_expr then
      error(string.format(
        "parameter '%s' missing type annotation at line %d, col %d",
        item.name, item.line, item.col))
    end
    table.insert(params, Ast.Param(item.name, item.type_expr, item.line, item.col))
  end

  local ret_type = nil
  if self:check(Tokens.types.COLON) then
    self:advance()
    self:skip_newlines()
    ret_type = self:parse_type_expr()
  end

  self:expect(Tokens.types.FAT_ARROW)
  self:skip_newlines()

  local body = self:parse_expression()

  return Ast.Lambda(params, ret_type, body, lparen.line, lparen.col)
end

function Parser:parse_lambda_or_paren()
  local lparen, items = self:parse_paren_group()

  if self:check(Tokens.types.FAT_ARROW)
    or self:check(Tokens.types.COLON) then
    return self:finish_lambda(lparen, items)
  end

  if #items == 0 then
    error(string.format("empty parentheses at line %d, col %d",
                        lparen.line, lparen.col))
  end

  if #items > 1 then
    error(string.format(
      "unexpected ',' - multiple expressions in parentheses not allowed at line %d, col %d",
      lparen.line, lparen.col))
  end

  local item = items[1]

  if item.type_expr then
    error(string.format(
      "type annotation in expression context at line %d, col %d",
      item.line, item.col))
  end

  return item.expr
end

function Parser:parse_paren_group()
  local lparen = self:expect(Tokens.types.LPAREN)
  self:skip_newlines()

  local items = {}
  if not self:check(Tokens.types.RPAREN) then
    table.insert(items, self:parse_paren_item())

    while self:match(Tokens.types.COMMA) do
      self:skip_newlines()
      table.insert(items, self:parse_paren_item())
    end

    self:skip_newlines()
  end

  self:expect(Tokens.types.RPAREN)
  return lparen, items
end

function Parser:parse_paren_item()
  local first = self:peek()
  local item = make_item(first.line, first.col)

  if first.type == Tokens.types.IDENT
    and self.tokens[self.pos + 1]
    and self.tokens[self.pos + 1].type == Tokens.types.COLON then
    self:advance()
    item.name = first.value
    self:advance()
    self:skip_newlines()

    item.type_expr = self:parse_type_expr()

    return item
  end

  local expr = self:parse_expression()
  item.expr = expr

  if expr.tag == "Ident" then
    item.name = expr.name
  end

  return item
end

function Parser:parse_expression(min_precedence)
  min_precedence = min_precedence or 0

  local left = self:parse_prefix()

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

  if t.type == Tokens.types.TRUE then
    self:advance()
    return Ast.BoolLit(true, t.line, t.col)
  end

  if t.type == Tokens.types.FALSE then
    self:advance()
    return Ast.BoolLit(false, t.line, t.col)
  end

  if t.type == Tokens.types.IDENT then
    self:advance()
    return Ast.Ident(t.value, t.line, t.col)
  end

  if t.type == Tokens.types.LPAREN then
    return self:parse_lambda_or_paren()
  end

  if t.type == Tokens.types.LBRACE then
    return self:parse_block()
  end

  if t.type == Tokens.types.IF then
    return self:parse_if()
  end

  error(string.format("unexpected token %s at line %d, col %d",
                      t.type, t.line, t.col))
end

function Parser:parse_paren_type()
  local lparen = self:expect(Tokens.types.LPAREN)
  self:skip_newlines()

  local types = {}

  if not self:check(Tokens.types.RPAREN) then
    table.insert(types, self:parse_type_expr())

    while self:match(Tokens.types.COMMA) do
      self:skip_newlines()
      table.insert(types, self:parse_type_expr())
    end

    self:skip_newlines()
  end

  self:expect(Tokens.types.RPAREN)

  if self:check(Tokens.types.THIN_ARROW) then
    self:advance()
    self:skip_newlines()
    local ret = self:parse_type_expr()
    return Ast.TypeFunc(types, ret, lparen.line, lparen.col)
  end

  if #types == 0 then
    error(string.format(
      "expected '->' after empty parameter list at line %d, col %d",
      lparen.line, lparen.col))
  end

  if #types > 1 then
    error(string.format(
      "unexpected ',' in type expression at line %d, col %d (did you mean '... -> T'?)",
      lparen.line, lparen.col))
  end

  return types[1]
end

function Parser:parse_type_expr()
  local t = self:peek()

  if t.type == Tokens.types.IDENT then
    self:advance()
    return Ast.TypeIdent(t.value, t.line, t.col)
  end

  if t.type == Tokens.types.LPAREN then
      return self:parse_paren_type()
    end

    error(string.format("expected type expression at line %d, col %d",
                        t.line, t.col))
end

function Parser:parse_if()
  local if_token = self:expect(Tokens.types.IF)

  self:skip_newlines()
  local cond = self:parse_expression()

  self:skip_newlines()
  local then_block = self:parse_block()

  self:skip_newlines()
  local else_block = nil
  if self:check(Tokens.types.ELSE) then
    self:advance()
    self:skip_newlines()
    else_block = self:parse_block()
  end

  return Ast.If(cond, then_block, else_block, if_token.line, if_token.col)
end

function Parser:parse_block()
  local lbrace = self:expect(Tokens.types.LBRACE)
  self:skip_newlines()

  local statements = {}
  local result = nil

  while not self:check(Tokens.types.RBRACE) and not self:check(Tokens.types.EOF) do
    if self:check(Tokens.types.LET) then
      table.insert(statements, self:parse_let())
    else
      local expr = self:parse_expression()
      self:skip_newlines()
      -- If the the expression parsed _is_ the last expression in the block, it
      -- becomes the result of the block.
      if self:check(Tokens.types.RBRACE) then
        result = expr
        break
      else
        table.insert(statements, Ast.ExprStmt(expr, expr.line, expr.col))
      end
      self:skip_newlines()
    end
  end

  self:expect(Tokens.types.RBRACE)
  return Ast.Block(statements, result, lbrace.line, lbrace.col)
end

function Parser:parse_prefix()
  local t = self:peek()

  if t.type == Tokens.types.NOT then
    self:advance()
    local operand = self:parse_prefix()
    return Ast.UnaryOp("not", operand, t.line, t.col)
  end

  return self:parse_postfix()
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
