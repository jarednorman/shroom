local Tokens = require("tokens")

local Lexer = {}
Lexer.__index = Lexer

function Lexer.new(source)
  return setmetatable({
    source = source,
    pos = 1,
    line = 1,
    col = 1,
  }, Lexer)
end

function Lexer:at_end()
  return self.pos > #self.source
end

function Lexer:peek(offset)
  offset = offset or 0

  return self.source:sub(self.pos + offset, self.pos + offset)
end

function Lexer:advance()
  local c = self:peek()
  self.pos = self.pos + 1
  if c == "\n" then
    self.line = self.line + 1
    self.col = 1
  else
    self.col = self.col + 1
  end
  return c
end

function Lexer:skip_whitespace()
  while not self:at_end() do
    local c = self:peek()

    if c == " " or c == "\t" or c == "\r" then
      self:advance()
    else
      break
    end
  end
end

function Lexer:read_int()
  local start_line, start_col = self.line, self.col
  local digits = {}

  while not self:at_end() and self:peek():match("%d") do
    table.insert(digits, self:advance())
  end

  local value = tonumber(table.concat(digits))
  return Tokens.new(Tokens.types.INT, value, start_line, start_col)
end

local KEYWORDS = {
  ["let"] = Tokens.types.LET,
  ["rec"] = Tokens.types.REC,
  ["if"] = Tokens.types.IF,
  ["else"] = Tokens.types.ELSE,
  ["true"] = Tokens.types.TRUE,
  ["false"] = Tokens.types.FALSE,
  ["not"] = Tokens.types.NOT,
  ["and"] = Tokens.types.AND,
  ["or"] = Tokens.types.OR,
  -- FIXME: Add more keywords.
}

function Lexer:read_ident_or_keyword()
  local start_line, start_col = self.line, self.col
  local chars = {}

  table.insert(chars, self:advance())

  while not self:at_end() and self:peek():match("[%w_]") do
    table.insert(chars, self:advance())
  end

  local text = table.concat(chars)
  local keyword = KEYWORDS[text]

  if keyword then
    return Tokens.new(keyword, nil, start_line, start_col)
  else
    return Tokens.new(Tokens.types.IDENT, text, start_line, start_col)
  end
end

function Lexer:next_token()
  self:skip_whitespace()

  if self:at_end() then
    return Tokens.new(Tokens.types.EOF, nil, self.line, self.col)
  end

  local c = self:peek()

  if c == "\n" then
    local line, col = self.line, self.col
    self:advance()
    return Tokens.new(Tokens.types.NEWLINE, nil, line, col)
  end

  if c:match("%d") then
    return self:read_int()
  end

  if c == "+" then
    self:advance()
    return Tokens.new(Tokens.types.PLUS, nil, self.line, self.col - 1)
  end

  if c == "*" then
    self:advance()
    return Tokens.new(Tokens.types.STAR, nil, self.line, self.col - 1)
  end

  if c == "/" then
    self:advance()
    return Tokens.new(Tokens.types.SLASH, nil, self.line, self.col - 1)
  end

  if c == "=" then
    self:advance()

    if self:peek() == "=" then
      self:advance()
      return Tokens.new(Tokens.types.EQ_EQ, nil, self.line, self.col - 2)
    end

    if self:peek() == ">" then
      self:advance()
      return Tokens.new(Tokens.types.FAT_ARROW, nil, self.line, self.col - 2)
    end

    return Tokens.new(Tokens.types.EQ, nil, self.line, self.col - 1)
  end


  if c == "-" then
    self:advance()

    if self:peek() == ">" then
      self:advance()
      return Tokens.new(Tokens.types.THIN_ARROW, nil, self.line, self.col - 2)
    end

    return Tokens.new(Tokens.types.MINUS, nil, self.line, self.col - 1)
  end

  if c == "!" then
    self:advance()

    if self:peek() == "=" then
      self:advance()
      return Tokens.new(Tokens.types.BANG_EQ, nil, self.line, self.col - 2)
    end

    error(string.format("unexpected character '!' at line %d, col %d",
                        self.line, self.col - 1))
  end

  if c == "<" then
    self:advance()

    if self:peek() == "=" then
      self:advance()
      return Tokens.new(Tokens.types.LT_EQ, nil, self.line, self.col - 2)
    end

    return Tokens.new(Tokens.types.LT, nil, self.line, self.col - 1)
  end

  if c == ">" then
    self:advance()

    if self:peek() == "=" then
      self:advance()
      return Tokens.new(Tokens.types.GT_EQ, nil, self.line, self.col - 2)
    end

    return Tokens.new(Tokens.types.GT, nil, self.line, self.col - 1)
  end

  if c == ":" then
    self:advance()
    return Tokens.new(Tokens.types.COLON, nil, self.line, self.col - 1)
  end

  if c == "(" then
    self:advance()
    return Tokens.new(Tokens.types.LPAREN, nil, self.line, self.col - 1)
  end

  if c == ")" then
    self:advance()
    return Tokens.new(Tokens.types.RPAREN, nil, self.line, self.col - 1)
  end

  if c == "," then
    self:advance()
    return Tokens.new(Tokens.types.COMMA, nil, self.line, self.col - 1)
  end

  if c == "{" then
    self:advance()
    return Tokens.new(Tokens.types.LBRACE, nil, self.line, self.col - 1)
  end

  if c == "}" then
    self:advance()
    return Tokens.new(Tokens.types.RBRACE, nil, self.line, self.col - 1)
  end

  if c:match("[%a_]") then
    return self:read_ident_or_keyword()
  end

  error(string.format("unexpected character '%s' at line %d, col %d",
    c, self.line, self.col))
end

function Lexer:tokenize()
  local tokens = {}
  while true do
    local tok = self:next_token()
    table.insert(tokens, tok)
    if tok.type == Tokens.types.EOF then break end
  end
  return tokens
end

return Lexer
