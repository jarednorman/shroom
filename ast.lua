local M = {}

M.tags = {
  IntLit = "IntLit",
  BinOp = "BinOp",
  Ident = "Ident",
  LetBinding = "LetBinding",
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

return M
