local M = {}

M.tags = {
  IntLit = "IntLit",
  BinOp = "BinOp",
  Ident = "Ident",
  LetBinding = "LetBinding",
  Program = "Program",
}

function M.IntLit(value, line, col)
  return {
    tag = M.tags.IntLit,
    value = value,
    line = line,
    col = col,
  }
end

function M.BinOp(op, left, right, line, col)
  return {
    tag = M.tags.BinOp,
    op = op,
    left = left,
    right = right,
    line = line,
    col = col,
  }
end

function M.Ident(name, line, col)
  return {
    tag = M.tags.Ident,
    name = name,
    line = line,
    col = col,
  }
end

function M.LetBinding(name, value, line, col)
  return {
    tag = M.tags.LetBinding,
    name = name,
    value = value,
    line = line,
    col = col,
  }
end

function M.Program(statements, line, col)
  return {
    tag = M.tags.Program,
    statements = statements,
    line = line,
    col = col,
  }
end

return M
