local M = {}

M.tags = {
  IntLit = "IntLit",
  BinOp = "BinOp",
  Ident = "Ident",
  LetBinding = "LetBinding",
  Program = "Program",
  Call = "Call",
  ExprStmt = "ExprStmt",
  If = "If",
  Block = "Block",
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

function M.Call(callee, args, line, col)
  return {
    tag = M.tags.Call,
    callee = callee,
    args = args,
    line = line,
    col = col,
  }
end

function M.ExprStmt(expr, line, col)
  return {
    tag = M.tags.ExprStmt,
    expr = expr,
    line = line,
    col = col,
  }
end

function M.If(condition, then_block, else_block, line, col)
  return {
    tag = M.tags.If,
    condition = condition,
    then_block = then_block,
    else_block = else_block,
    line = line,
    col = col,
  }
end

function M.Block(statements, result, line, col)
  return {
    tag = M.tags.Block,
    statements = statements,
    result = result,
    line = line,
    col = col,
  }
end

return M
