local M = {}

M.types = {
  -- Literals
  INT = "INT",
  -- FLOAT = "FLOAT",
  -- STRING = "STRING",
  IDENT = "IDENT",
  -- TYPE_VAR = "TYPE_VAR",

  -- Keywords
  LET = "LET",
  -- IF = "IF",
  -- ELSE = "ELSE",
  -- MATCH = "MATCH",
  -- TYPE = "TYPE",
  -- TRUE = "TRUE",
  -- FALSE = "FALSE",
  -- AND = "AND",
  -- OR = "OR",
  -- NOT = "NOT",

  -- Operators
  PLUS = "PLUS",
  MINUS = "MINUS",
  STAR = "STAR",
  SLASH = "SLASH",
  -- PERCENT = "PERCENT",
  -- PLUS_DOT = "PLUS_DOT",
  -- MINUS_DOT = "MINUS_DOT",
  -- STAR_DOT = "STAR_DOT",
  -- SLASH_DOT = "SLASH_DOT",
  -- EQ_EQ = "EQ_EQ",
  -- BANG_EQ = "BANG_EQ",
  -- LT = "LT",
  -- LT_EQ = "LT_EQ",
  -- GT = "GT",
  -- GT_EQ = "GT_EQ",
  EQ = "EQ",
  -- FAT_ARROW = "FAT_ARROW",
  -- THIN_ARROW = "THIN_ARROW",

  -- Delimiters
  -- LPAREN = "LPAREN",
  -- RPAREN = "RPAREN",
  -- LBRACE = "LBRACE",
  -- RBRACE = "RBRACE",
  -- LBRACKET = "LBRACKET",
  -- RBRACKET = "RBRACKET",
  -- COMMA = "COMMA",
  -- COLON = "COLON",
  -- SEMICOLON = "SEMICOLON",

  -- Special
  NEWLINE = "NEWLINE",
  EOF = "EOF"
}

M.operators = {
  [M.types.PLUS] = "+",
  [M.types.MINUS] = "-",
  [M.types.STAR] = "*",
  [M.types.SLASH] = "/",
}

function M.new(type, value, line, col)
  assert(M.types[type], "invalid token type: " .. tostring(type) .. ", value: " .. tostring(value))

  return {
    type = type,
    value = value,
    line = line,
    col = col
  }
end

return M
