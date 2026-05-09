local Env = {}
Env.__index = Env

function Env.new(parent)
  return setmetatable({
    bindings = {},
    parent = parent, -- nil for the top-level environment
  }, Env)
end

function Env:lookup(name)
  if self.bindings[name] ~= nil then
    return self.bindings[name]
  end

  if self.parent then
    return self.parent:lookup(name)
  end

  return nil
end

function Env:define(name, type)
  self.bindings[name] = type
end

function Env:child()
  return Env.new(self)
end

return Env
