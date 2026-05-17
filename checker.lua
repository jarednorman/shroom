local Types = require("types")
local Env = require("env")

local function type_error(node, msg)
  error(string.format("type error at line %d, col %d: %s",
    node.line or 0, node.col or 0, msg))
end

local function types_equal(t1, t2)
  if t1.tag ~= t2.tag then return false end

  if t1.tag == "Function" then
    if #t1.params ~= #t2.params then return false end

    for i = 1, #t1.params do
      if not types_equal(t1.params[i], t2.params[i]) then return false end
    end

    return types_equal(t1.ret, t2.ret)
  end

  return true
end

local function type_to_string(t)
  if t.tag == "Function" then
    local params = {}

    for _, p in ipairs(t.params) do
      table.insert(params, type_to_string(p))
    end

    return "(" .. table.concat(params, ", ") .. ") -> " .. type_to_string(t.ret)
  end

  return t.tag
end

local function resolve_type(node)
  if node.tag == "TypeIdent" then
    if node.name == "Int" then
      return Types.Int
    elseif node.name == "Bool" then
      return Types.Bool
    elseif node.name == "Unit" then
      return Types.Unit
    else
      type_error(node, "unknown type: " .. node.name)
    end
  elseif node.tag == "TypeFunc" then
    local params = {}

    for _, param in ipairs(node.params) do
      table.insert(params, resolve_type(param))
    end

    local ret = resolve_type(node.ret)
    return Types.Function(params, ret)
  else
    error("resolve_type: unhandled type node " .. tostring(node.tag))
  end
end

-- Type-check a lambda expression without checking its body.
local function check_lambda_signature(node)
  local param_types = {}
  for _, param in ipairs(node.params) do
    if not param.type_expr then
      type_error(param, "parameter '" .. param.name ..
                  "' must have a type annotation")
    end
    table.insert(param_types, resolve_type(param.type_expr))
  end

  if not node.ret_type then
    type_error(node, "function must have a return type annotation")
  end
  local ret_type = resolve_type(node.ret_type)

  return Types.Function(param_types, ret_type)
end

local function check_arith(node, left, right)
  if not types_equal(left, Types.Int) then
    type_error(node, "left operand of " .. node.op ..
      " must be Int, got " .. type_to_string(left))
  end
  if not types_equal(right, Types.Int) then
    type_error(node, "right operand of " .. node.op ..
      " must be Int, got " .. type_to_string(right))
  end
  return Types.Int
end

local function check_int_compare(node, left, right)
  if not types_equal(left, Types.Int) then
    type_error(node, "left operand of " .. node.op ..
      " must be Int, got " .. type_to_string(left))
  end
  if not types_equal(right, Types.Int) then
    type_error(node, "right operand of " .. node.op ..
      " must be Int, got " .. type_to_string(right))
  end
  return Types.Bool
end

local function check_equality(node, left, right)
  if not types_equal(left, right) then
    type_error(node, "operands of " .. node.op ..
      " must have the same type, got " ..
      type_to_string(left) .. " and " .. type_to_string(right))
  end
  return Types.Bool
end

local function check_logical(node, left, right)
  if not types_equal(left, Types.Bool) then
    type_error(node, "left operand of " .. node.op ..
      " must be Bool, got " .. type_to_string(left))
  end
  if not types_equal(right, Types.Bool) then
    type_error(node, "right operand of " .. node.op ..
      " must be Bool, got " .. type_to_string(right))
  end
  return Types.Bool
end

local BINOP_CHECKERS = {
  ["+"] = check_arith,
  ["-"] = check_arith,
  ["*"] = check_arith,
  ["/"] = check_arith,
  ["<"] = check_int_compare,
  ["<="] = check_int_compare,
  [">"] = check_int_compare,
  [">="] = check_int_compare,
  ["=="] = check_equality,
  ["!="] = check_equality,
  ["and"] = check_logical,
  ["or"] = check_logical,
}

local check_expr
local check_stmt

local check_block = function(block, env)
  local child = env:child()
  for _, stmt in ipairs(block.statements) do
    check_stmt(stmt, child)
  end
  if block.result then
    return check_expr(block.result, child)
  else
    return Types.Unit
  end
end

local expr_checkers = {
  ["IntLit"] = function(node, env)
    return Types.Int
  end,

  ["BoolLit"] = function(node, env)
    return Types.Bool
  end,

  ["Ident"] = function(node, env)
    local t = env:lookup(node.name)
    if not t then
      type_error(node, "undefined variable: " .. node.name)
    end
    return t
  end,

  ["BinOp"] = function(node, env)
    local left = check_expr(node.left, env)
    local right = check_expr(node.right, env)
    local checker = BINOP_CHECKERS[node.op]
    if not checker then
      error("checker: unknown binary operator: " .. node.op)
    end
    return checker(node, left, right)
  end,

  ["UnaryOp"] = function(node, env)
    local t = check_expr(node.operand, env)

    if node.op == "not" then
      if not types_equal(t, Types.Bool) then
        type_error(node, "operand of 'not' must be Bool, got " .. type_to_string(t))
      end
      return Types.Bool
    end

    error("checker: unknown unary operator: " .. node.op)
  end,

  ["If"] = function(node, env)
    local cond_t = check_expr(node.condition, env)

    if not types_equal(cond_t, Types.Bool) then
      type_error(node, "if condition must be Bool, got " .. type_to_string(cond_t))
    end

    local then_t = check_block(node.then_block, env)

    if node.else_block then
      local else_t = check_block(node.else_block, env)

      if not types_equal(then_t, else_t) then
        type_error(node, "if branches must have the same type, got " ..
                         type_to_string(then_t) .. " and " .. type_to_string(else_t))
      end

      return then_t
    else
      -- Conditionals with no "else" must have the type Unit, as that's the
      -- type/value of the expression when the condition is false.
      if not types_equal(then_t, Types.Unit) then
        type_error(node, "if without else must produce Unit, got " ..
                         type_to_string(then_t))
      end

      return Types.Unit
    end
  end,

  ["Call"] = function(node, env)
    local callee_t = check_expr(node.callee, env)

    if callee_t.tag ~= "Function" then
      type_error(node, "cannot call a non-function value of type " ..
                  type_to_string(callee_t))
    end

    if #node.args ~= #callee_t.params then
      type_error(node, "expected " .. #callee_t.params ..
                 " argument(s), got " .. #node.args)
    end

    for i, arg in ipairs(node.args) do
      local arg_t = check_expr(arg, env)

      if not types_equal(arg_t, callee_t.params[i]) then
        type_error(node, "argument " .. i .. " expected " ..
                   type_to_string(callee_t.params[i]) ..
                   ", got " .. type_to_string(arg_t))
      end
    end

    return callee_t.ret
  end,

  ["Lambda"] = function(node, env)
    local function_type = check_lambda_signature(node)

    local body_env = env:child()

    for i, param in ipairs(node.params) do
      body_env:define(param.name, function_type.params[i])
    end

    local body_type = check_expr(node.body, body_env)
    if not types_equal(body_type, function_type.ret) then
      type_error(node, "function body has type " ..
                 type_to_string(body_type) ..
                 " but declared return type is " ..
                 type_to_string(function_type.ret))
    end

    return function_type
  end
}

local stmt_checkers = {
  ["LetBinding"] = function(node, env)
    if not node.recursive then
      local t = check_expr(node.value, env)
      env:define(node.name, t)
    elseif node.recursive and node.value.tag == "Lambda" then
      local lambda_type = check_lambda_signature(node.value)

      env:define(node.name, lambda_type)

      check_expr(node.value, env)
    else
      type_error(node, "only functions can be recursive")
    end
  end,

  ["ExprStmt"] = function(node, env)
    check_expr(node.expr, env)
  end,

  ["Program"] = function(node, env)
    for _, s in ipairs(node.statements) do
      check_stmt(s, env)
    end
  end,
}

check_expr = function(node, env)
  local checker = expr_checkers[node.tag]
  if not checker then
    error("No checker for node type: " .. node.tag)
  end
  return checker(node, env)
end

check_stmt = function(node, env)
  local checker = stmt_checkers[node.tag]
  if not checker then
    error("No checker for node type: " .. node.tag)
  end
  return checker(node, env)
end

local check = function(program)
  local env = Env.new(nil)

  env:define("print_int",  Types.Function({Types.Int},  Types.Unit))
  env:define("print_bool", Types.Function({Types.Bool}, Types.Unit))

  check_stmt(program, env)
end

return check
