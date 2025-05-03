local _M = {}

local assert = require("luassert")
local util = require("luassert.util")
local deep_copy = util.deepcopy
local deep_compare = util.deepcompare

local exec = require("pl.utils").executeex
local fmt = string.format

_M.fixtures = {
  empty_conf = "spec/fixtures/busted_conf",
  test_spec = "spec/fixtures/test_spec.lua",
}
setmetatable(_M.fixtures, {
  __index = function(_, k) error("missing key: " .. tostring(k)) end,
  __newindex = function() error("spec.helpers.fixtures is readonly") end,
})

local HELPER_SCRIPT = "src/busted/matrix/helper.lua"


---@param exp any[]
---@param got any[]
---@param msg? string
function _M.assert_same_elements(exp, got, msg)
  -- TODO: luassert-ify this

  local missing = {}

  msg = msg or "assert_same_elements()"

  local deep = true
  assert.unique(exp, deep, msg .. ": duplicate expected items")
  assert.unique(got, deep, msg .. ": duplicate received items")

  exp = deep_copy(exp)
  got = deep_copy(got)

  for i = #exp, 1, -1 do
    local lhs_elem = exp[i]
    exp[i] = nil

    local found = false

    for j, rhs_elem in ipairs(got) do
      if deep_compare(lhs_elem, rhs_elem) then
        found = true
        table.remove(got, j)
        break
      end
    end

    if not found then
      table.insert(missing, lhs_elem)
    end
  end

  local extra = got
  assert.same({}, missing, msg .. ": items missing")
  assert.same({}, extra, msg .. ": unexpected items")
end


---@param t table[]
---@param key string
function _M.extract(t, key)
  local new = {}
  for i = 1, #t do
    new[i] = t[i][key]
  end
  return new
end


---@class busted.matrix._test.command.result
---
---@field status integer
---@field stdout string
---@field stderr string


---@param args string[]
---@return busted.matrix._test.command.result
function _M.busted_exec(args)
  -- XXX: this is not adequate quoting, be careful

  local cmd = {
    "busted",
    fmt("--config-file=%q", _M.fixtures.empty_conf),
    fmt("--helper=%q", HELPER_SCRIPT),
  }

  for _, arg in ipairs(args) do
    table.insert(cmd, arg)
  end

  cmd = table.concat(cmd, " ")

  local ok, ec, stdout, stderr = exec(cmd, false)
  local err = fmt("command (%s) failed\nSTDOUT:\n%s\nSTDERR:\n%s\n",
                  cmd, stdout, stderr)

  assert.truthy(ok, err)
  assert.equals(0, ec, err)

  return {
    status = ec,
    stdout = stdout,
    stderr = stderr,
  }
end


---@param str string
---@return string[]
function _M.split_lines(str)
  assert.is_string(str)
  local lines = {}
  local i = 0
  str:gsub("[^\r\n]+", function(line)
    i = i + 1
    lines[i] = line
  end)
  return lines
end


---@param t string[]
---@return string[]
function _M.sort(t)
  table.sort(t)
  return t
end


---@param exp string[]
---@param res busted.matrix._test.command.result
---@param msg? string
function _M.assert_stdout_lines(exp, res, msg)
  if type(exp) == "string" then
    exp = _M.split_lines(exp)
  end

  local lines = _M.split_lines(res.stdout)

  msg = msg or "expected stdout lines"

  _M.assert_same_elements(exp, lines, msg)
end


function _M.print_context(busted)
  local descriptors = {
    "file",
    "suite",
    "MATRIX",
    "before_each",
    "after_each",
    "lazy_setup",
    "lazy_teardown",
    "strict_setup",
    "strict_teardown",
    "describe",
    "it",
    "test",
  }

  local inspect = require("inspect")

  local function eprintf(f, ...)
    io.stderr:write(string.format(f .. "\n", ...))
  end

  local function table_keys(t)
    if not t then return end
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    table.sort(keys)
    return keys
  end

  local function get_children(ctx)
    local children = {}

    for _, desc in ipairs(descriptors) do
      if ctx[desc] and #ctx[desc] > 0 then
        for _, child in ipairs(ctx[desc] or {}) do
          table.insert(children, child)
        end
      end
    end

    return children
  end

  local function serialize(ctx, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    eprintf("%sname         = %s", indent, ctx.name)
    eprintf("%sdescriptor   = %s", indent, ctx.descriptor)
    eprintf("%senv          = %s", indent, inspect(table_keys(ctx.env)))
    eprintf("%sattrs        = %s", indent, inspect(table_keys(ctx.attributes)))
    eprintf("%sMatrix.vars  = %s", indent, inspect(
      ctx.attributes
      and ctx.attributes.matrix
      and ctx.attributes.matrix.obj
      and ctx.attributes.matrix.obj.vars_by_name
      and table_keys(ctx.attributes.matrix.obj.vars_by_name)
    ))
    eprintf("%sMatrix.each  = %s", indent, inspect(
      ctx.attributes
      and ctx.attributes.matrix
      and ctx.attributes.matrix.each
      and table_keys(getmetatable(ctx.attributes.matrix.each).matrix)
    ))

    eprintf("%smatrix.vars  = %s", indent, inspect(
      ctx.env
      and ctx.env.matrix
      and rawget(ctx.env.matrix, "obj")
      and rawget(ctx.env.matrix, "obj").vars_by_name
      and table_keys(rawget(ctx.env.matrix, "obj").vars_by_name)
    ))
    eprintf("%smatrix.each  = %s", indent, inspect(
      ctx.env
      and ctx.env.matrix
      and rawget(ctx.env.matrix, "each")
      and rawget(ctx.env.matrix, "each").matrix
      and table_keys(rawget(ctx.env.matrix, "each").matrix)
    ))

    local children = get_children(ctx)
    if #children > 0 then
      eprintf("%schildren     = {", indent)
      for i, child in ipairs(children) do
        eprintf("%s%02d/%02d", indent, i, #children)
        serialize(child, depth + 2)
        eprintf("")
      end
      eprintf("%s}", indent)
    else
      eprintf("%schildren     = {}", indent)
    end
  end

  local ctx = busted.context.get()
  while busted.context.parent(ctx) do
    ctx = busted.context.parent(ctx)
  end
  serialize(ctx)
end

return _M
