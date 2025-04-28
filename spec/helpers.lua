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


---@param args string[]
---@return string stdout
---@return string stderr
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

  return stdout, stderr
end


return _M
