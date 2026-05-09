local M = {}

M.Int = { tag = "Int" }
M.Bool = { tag = "Bool" }
M.Unit = { tag = "Unit" }
M.Function = function(params, ret)
  return {
    tag = "Function",
    params = params,
    ret = ret,
  }
end

return M
