local assert = require("luassert")
local util = require("luassert.util")
local say = require("say")

local E_ARGTYPE = "matrix.error.argtype"
say:set(E_ARGTYPE, "bad argument #%s to '%s' (%s expected, got %s)")

local function e_argtype(narg, fn, exp, got)
  return say(E_ARGTYPE, { narg, fn, exp, got })
end

local E_BADARG = "matrix.error.invalid-arg"
say:set(E_BADARG, "bad argument #%s to '%s' (%s)")

local function e_badarg(narg, fn, reason)
  return say(E_BADARG, { narg, fn, reason })
end


local deep_copy = util.deepcopy
local deep_compare = util.deepcompare

local ipairs = ipairs
local pairs = pairs
local insert = table.insert
local concat = table.concat
local fmt = string.format
local type = type


---@type fun(t: table): boolean
local isempty
do
  local ok
  ok, isempty = pcall(require, "table.isempty")
  if not ok then
    ---@param t table
    ---@return boolean
    isempty = function(t)
      return next(t, nil) == nil
    end
  end
end


---@param exp "table"|"string"|"number"|"table"|"boolean"
---@param v any
---@param narg integer
---@param fn string
---@param level? integer
local function check_type(exp, v, narg, fn, level)
  level = (level or 1) + 1

  local got = type(v)
  assert(got == exp,
         say(E_ARGTYPE, { narg, fn, exp, got }),
         level)
end


---@param exp "table"|"string"|"number"|"table"|"boolean"
---@param v any
---@param narg integer
---@param fn string
---@param level? integer
local function check_optional(exp, v, narg, fn, level)
  if v == nil then
    return
  end

  level = (level or 1) + 1

  local got = type(v)
  assert(got == exp,
         say(E_ARGTYPE, { narg, fn, exp .. " or nil", got }),
         level)
end


---@param v any
---@param narg integer
---@param fn string
---@param level? integer
local function check_non_empty_table(v, narg, fn, level)
  level = (level or 1) + 1
  check_type("table", v, narg, fn, level + 1)

  assert(not isempty(v),
         say(E_BADARG, { narg, fn, "empty table" }),
         level)
end


---@param v any
---@param narg integer
---@param fn string
---@param level? integer
local function check_non_empty_string(v, narg, fn, level)
  level = (level or 1) + 1
  check_type("string", v, narg, fn, level + 1)

  assert(v ~= "",
         say(E_BADARG, { narg, fn, "empty string" }),
         level)
end


---@param v any
---@param narg integer
---@param fn string
---@param level? integer
---@return string[]
local function string_list(v, narg, fn, level, optional, unique)
  if optional and v == nil then
    return {}
  end

  level = (level or 1) + 1
  local typ = type(v)

  local list

  if typ == "string" then
    assert(v ~= "", e_badarg(narg, fn, "empty string", level))
    list = { v }

  elseif typ == "table" then
    list = {}
    local seen

    if unique then
      seen = {}
    end

    for i, iv in pairs(v) do
      assert(type(i) == "number",
             e_badarg(narg, fn, "non-integer table key"),
             level)

      local ctx = "table element at #" .. i

      assert(type(iv) == "string",
             e_badarg(narg, fn, "non-string " .. ctx),
             level)

      assert(iv ~= "",
             e_badarg(narg, fn, "empty string " .. ctx),
             level)

      if unique then
        assert(seen[iv] == nil,
               e_badarg(narg, fn, "duplicate value " .. ctx),
               level)

        seen[iv] = true
      end

      insert(list, iv)
    end

    assert(not isempty(list),
           e_badarg(narg, fn, "empty list"),
           level)

  else
    assert(false,
           e_argtype(narg, fn, "string or table of strings", typ),
           level)
  end

  return list
end


---@generic T: table
---@type fun(t: T): T
local shallow_copy
do
  local ok
  ok, shallow_copy = pcall(require, "table.clone")
  if not ok then
    ---@generic T: table
    ---@param t T
    ---@return T
    shallow_copy = function(t)
      local copy = {}
      for k, v in pairs(t) do
        copy[k] = v
      end
      return copy
    end
  end
end


---@generic K
---@generic T : table<K, any>
---@param t T
---@return fun(t: T): K|nil
local function iter_sorted_keys(t)
  local keys = {}
  for k in pairs(t) do
    insert(keys, k)
  end
  table.sort(keys)

  local i = 0
  return function()
    i = i + 1
    return keys[i]
  end
end


---@param t any[]
---@param any[]
local function table_extend(t, extra)
  for _, elem in ipairs(extra) do
    insert(t, elem)
  end
end


---@param t string[]
---@param extra string|string[]
local function add_tags(t, extra)
  if extra == nil then
    return
  end

  local have = {}
  for _, current in ipairs(t) do
    have[current] = true
  end

  if type(extra) == "string" then
    if not have[extra] then
      insert(t, extra)
    end
    return
  end

  assert(type(extra) == "table")
  for _, ext in ipairs(extra) do
    if not have[ext] then
      insert(t, ext)
    end
  end
end


---@param subject table
---@param criteria table
---@return boolean
local function table_match(subject, criteria)
  assert(not isempty(criteria))

  for k, v in pairs(criteria) do
    if not deep_compare(subject[k], v) then
      return false
    end
  end

  return true
end


---@param t table
---@return table
local function unprotect(t)
  check_type("table", t, 1, "Matrix.unprotect")

  local new = {}

  local mt = getmetatable(t)
  local protected = mt and mt.matrix or t

  for k, v in pairs(protected) do
    new[k] = v
  end

  return new
end


---@param matrix table
---@param vars? table
---@return table
local function protect(matrix, vars)
  check_type("table", matrix, 1, "Matrix.protect")
  check_optional("table", vars, 2, "Matrix.protect")

  if not vars then
    local mt = getmetatable(matrix)
    vars = mt and mt.vars
  end

  assert(type(vars) == "table",
         e_badarg(1, "Matrix.protect", "not a matrix element"))

  local protected = setmetatable({}, {
    vars = vars,

    matrix = matrix,

    __index = function(_, k)
      if not vars[k] then
        error("unknown matrix var: " .. tostring(k))
      end
      return matrix[k]
    end,

    __newindex = function()
      error("attempting to overwrite matrix var")
    end,
  })

  return protected
end


--- Test matrix object
---
--- For the sake of familiarity with existing tooling, this object implements
--- the same behaviors as the `matrix` property in Github Actions:
---
--- https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow
---
---@class busted.matrix
---
---@field vars         busted.matrix.var[]
---@field vars_by_name table<string, busted.matrix.var>
---@field seen_vars    table<string, boolean>
---
---@field includes table[]
---@field excludes table[]
---
---@field tags     { match: table, tags: string[] }[]
local Matrix = {}

local matrix_mt = { __index = Matrix }


---@class busted.matrix.var
---
---@field name string
---@field values any[]


---@class busted.matrix.each
---
---@field label string
---@field tags? string[]
---@field matrix table


--- Create a new test matrix
---
---@return busted.matrix
function Matrix.new()
  return setmetatable({
    vars = {},
    vars_by_name = {},
    seen_vars = {},
    includes = {},
    excludes = {},
    tags = {},
    labels = {},
  }, matrix_mt)
end


--- Add a variable and its value permutations to the test matrix
---
---@param name string
---@param values any[]
---@return busted.matrix
function Matrix:add(name, values)
  check_non_empty_string(name, 1, "add")
  assert(self.vars_by_name[name] == nil,
         e_badarg(1, "Matrix.add", "duplicate var"))

  check_non_empty_table(values, 2, "add")

  ---@type busted.matrix.var
  local entry = {
    name = name,
    values = deep_copy(values),
  }

  insert(self.vars, entry)
  self.vars_by_name[name] = entry

  return self
end


--- Add a matrix inclusion
---
---@param inc table
---@return busted.matrix
function Matrix:include(inc)
  check_non_empty_table(inc, 1, "include")
  insert(self.includes, inc)
  return self
end


--- Add an a matrix exclusion
---
---@param exc table
---@return busted.matrix
function Matrix:exclude(exc)
  check_non_empty_table(exc, 1, "exclude")
  insert(self.excludes, exc)
  return self
end


--- Add an a matrix tag rule
---
---@param match table
---@param tag string|string[]
---@return busted.matrix
function Matrix:tag(match, tag)
  check_non_empty_table(match, 1, "tag")

  local tags = string_list(tag, 2, "tag", nil, false, true)

  insert(self.tags, {
    match = match,
    tags = tags,
  })

  return self
end


--- Return a table of all matrix permutations
---
--- This processes all exclusions and inclusions.
---
---@param opts? { label: boolean, protect: boolean }
---@return busted.matrix.each[]
function Matrix:render(opts)
  check_optional("table", opts, 1, "render")
  opts = opts or {}

  ---@type busted.matrix.each[]
  local rendered = {}

  for _, var in ipairs(self.vars) do
    -- first var, populate the matrix
    if #rendered == 0 then
      for _, value in ipairs(var.values) do
        insert(rendered, {
          matrix = {
            [var.name] = deep_copy(value),
          }
        })
      end
    else
      local new = {}
      for _, item in ipairs(rendered) do
        for _, value in ipairs(var.values) do
          item = deep_copy(item)
          item.matrix[var.name] = deep_copy(value)
          insert(new, item)
        end
      end
      rendered = new
    end
  end

  ---@type busted.matrix.each[]
  local not_excluded = {}
  for _, item in ipairs(rendered) do
    local keep = true

    for _, exc in ipairs(self.excludes) do
      if table_match(item.matrix, exc) then
        keep = false
        break
      end
    end

    if keep then
      insert(not_excluded, item)
    end
  end
  rendered = not_excluded

  ---@type busted.matrix.each[]
  local additional = {}

  for _, inc in ipairs(self.includes) do
    local match_on

    for _, var in ipairs(self.vars) do
      if inc[var.name] ~= nil then
        match_on = match_on or {}
        match_on[var.name] = inc[var.name]
      end
    end

    if match_on then
      local matched_any = false

      for _, item in ipairs(rendered) do
        if table_match(item.matrix, match_on) then
          matched_any = true

          local new = deep_copy(item.matrix)

          for k, v in pairs(inc) do
            new[k] = deep_copy(v)
          end

          item.matrix = new
        end
      end

      if not matched_any then
        insert(additional, {
          matrix = deep_copy(inc),
        })
      end

    else
      for _, item in ipairs(rendered) do
        local new = deep_copy(item.matrix)
        for k, v in pairs(inc) do
          new[k] = deep_copy(v)
        end
        item.matrix = new
      end
    end
  end

  table_extend(rendered, additional)

  local all_var_names = {}
  for _, item in ipairs(rendered) do
    for k in pairs(item.matrix) do
      all_var_names[k] = true
    end
  end

  local all_labels = {}

  for _, item in ipairs(rendered) do
    local label_vars = shallow_copy(all_var_names)

    for _, tag in ipairs(self.tags) do
      if table_match(item.matrix, tag.match) then
        item.tags = item.tags or {}
        add_tags(item.tags, tag.tags)

        for k in pairs(tag.match) do
          label_vars[k] = nil
        end
      end
    end

    if opts.label then
      local label

      if item.tags and #item.tags > 0 then
        table.sort(item.tags)
        label = "#" .. concat(item.tags, " #")
      end

      if not isempty(label_vars) then
        local vars = {}
        for var in iter_sorted_keys(label_vars) do
          local value = item.matrix[var]
          if value ~= nil then
            insert(vars, fmt("%s = %s", var, item.matrix[var]))
          end
        end

        vars = fmt("[%s]", concat(vars, ", "))
        if label then
          label = label .. " " .. vars
        else
          label = vars
        end
      end

      assert(label ~= nil)
      assert(all_labels[label] == nil, "duplicate label: " .. label)
      all_labels[label] = true
      item.label = label
    end
  end

  if opts.protect then
    for _, item in ipairs(rendered) do
      item.matrix = protect(item.matrix, all_var_names)
    end
  end

  return rendered
end


---@return busted.matrix
function Matrix:reset()
  self.vars = {}
  self.vars_by_name = {}
  self.seen_vars = {}
  self.includes = {}
  self.excludes = {}
  self.tags = {}
  self.labels = {}

  return self
end


---@return busted.matrix
function Matrix:clone()
  local clone = deep_copy(self)
  setmetatable(clone, matrix_mt)
  return clone
end


return {
  protect = protect,
  unprotect = unprotect,
  new = Matrix.new,
}
