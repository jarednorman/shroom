local emit

-- This is a simple way to generate fresh temporary identifiers for storing the
-- result of expressions.
local fresh_id = 0
local function fresh()
  fresh_id = fresh_id + 1
  return "_tmp" .. fresh_id
end

local function append_all(target, source)
  for _, s in ipairs(source) do table.insert(target, s) end
end

-- Operators that differ from their Lua equivalents.
local LUA_OP = {
  ["!="] = "~=",
}

local emit_expr
local emit_stmt

local function emit_block_into(block, target)
  local lines = {}

  for _, stmt in ipairs(block.statements) do
    table.insert(lines, emit_stmt(stmt))
  end

  if block.result then
    local result_stmts, result_expr = emit_expr(block.result)
    append_all(lines, result_stmts)
    table.insert(lines, target .. " = " .. result_expr)
  end

  return lines
end

local expr_emitters = {
  ["IntLit"] = function(node)
    return {}, tostring(node.value)
  end,

  ["Ident"] = function(node)
    return {}, node.name
  end,

  ["BinOp"] = function(node)
    local op = LUA_OP[node.op] or node.op
    local left_stmts, left_expr = emit_expr(node.left)
    local right_stmts, right_expr = emit_expr(node.right)
    local stmts = {}
    append_all(stmts, left_stmts)
    append_all(stmts, right_stmts)
    return stmts, "(" .. left_expr .. " " .. op .. " " .. right_expr .. ")"
  end,

  ["Call"] = function(node)
    local stmts = {}
    local callee_stmts, callee_expr = emit_expr(node.callee)

    append_all(stmts, callee_stmts)
    local arg_exprs = {}
    for _, arg in ipairs(node.args) do
      local arg_stmts, arg_expr = emit_expr(arg)
      append_all(stmts, arg_stmts)
      table.insert(arg_exprs, arg_expr)
    end

    return stmts, callee_expr .. "(" .. table.concat(arg_exprs, ", ") .. ")"
  end,

  ["If"] = function(node)
    local tmp = fresh()
    local stmts = {}

    table.insert(stmts, "local " .. tmp)

    local cond_stmts, cond_expr = emit_expr(node.condition)
    append_all(stmts, cond_stmts)

    local then_lines = emit_block_into(node.then_block, tmp)
    table.insert(stmts, "if " .. cond_expr .. " then")

    for _, line in ipairs(then_lines) do
      table.insert(stmts, "  " .. line)
    end

    if node.else_block then
      local else_lines = emit_block_into(node.else_block, tmp)
      table.insert(stmts, "else")

      for _, line in ipairs(else_lines) do
        table.insert(stmts, "  " .. line)
      end
    end

    table.insert(stmts, "end")
    return stmts, tmp
  end,

  ["BoolLit"] = function(node)
    return {}, tostring(node.value)
  end,

  ["UnaryOp"] = function(node)
    local stmts, expr = emit_expr(node.operand)
    return stmts, "(" .. node.op .. " " .. expr .. ")"
  end
}

local stmt_emitters = {
  ["LetBinding"] = function(node)
    local stmts, expr = emit_expr(node.value)

    local lines = {}
    append_all(lines, stmts)
    table.insert(lines, "local " .. node.name .. " = " .. expr)
    return table.concat(lines, "\n")
  end,

  ["ExprStmt"] = function(node)
    local stmts, expr = emit_expr(node.expr)
    local lines = {}
    append_all(lines, stmts)
    table.insert(lines, expr)
    return table.concat(lines, "\n")
  end,

  ["Program"] = function(node)
    local lines = {}

    for _, statement in ipairs(node.statements) do
      table.insert(lines, emit_stmt(statement))
    end

    return table.concat(lines, "\n")
  end,
}

emit_expr = function(node)
  local emitter = expr_emitters[node.tag]

  if emitter then
    return emitter(node)
  else
    error("codegen: unhandled expression node " .. tostring(node.tag))
  end
end

emit_stmt = function(node)
  local emitter = stmt_emitters[node.tag]
  if emitter then
    return emitter(node)
  else
    error("codegen: unhandled statement node " .. tostring(node.tag))
  end
end

function generate(ast)
  return emit_stmt(ast)
end

return generate
