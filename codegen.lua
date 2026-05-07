local emit

local emitters = {
  ["IntLit"] = function(node)
    return tostring(node.value)
  end,
  ["Ident"] = function(node)
    return node.name
  end,
  ["BinOp"] = function(node)
    local left = emit(node.left)
    local right = emit(node.right)
    return "(" .. left .. " " .. node.op .. " " .. right .. ")"
  end,
  ["LetBinding"] = function(node)
    return "local " .. node.name .. " = " .. emit(node.value)
  end,
  ["Program"] = function(node)
    local lines = {}

    for _, statement in ipairs(node.statements) do
      table.insert(lines, emit(statement))
    end

    return table.concat(lines, "\n")
  end,
  ["Call"] = function(node)
    local callee = emit(node.callee)
    local args = {}

    for _, arg in ipairs(node.args) do
      table.insert(args, emit(arg))
    end

    return callee .. "(" .. table.concat(args, ", ") .. ")"
  end,
  ["ExprStmt"] = function(node)
    return emit(node.expr)
  end,
}

emit = function(node)
  local emitter = emitters[node.tag]
  if emitter then
    return emitter(node)
  else
    error("codegen: unhandled node " .. tostring(node.tag))
  end
end

function generate(ast)
  return emit(ast)
end

return generate
