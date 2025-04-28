local Matrix = require("busted.matrix")

local util = require("luassert.util")
local deep_copy = util.deepcopy
local deep_compare = util.deepcompare


---@param exp any[]
---@param got any[]
---@param msg? string
local function assert_same_elements(exp, got, msg)
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
---@param k string
local function map_key(t, k)
  local new = {}
  for i = 1, #t do
    new[i] = t[i][k]
  end
  return new
end


describe("busted.matrix", function()
  describe("new()", function()
    it("creates a new matrix", function()
      local m = Matrix.new()
      assert.table(m)
    end)
  end)

  describe("add()", function()
    it("adds a new variable", function()
      local m = Matrix.new()
      m:add("foo", { 1, 2 })
      m:add("bar", { 3, 4 })
    end)

    it("errors on duplicate variables", function()
      local m = Matrix.new()
      m:add("foo", { 1, 2 })

      assert.has_error(function()
        m:add("foo", { 3, 4 })
      end)
    end)
  end)

  describe("tag()", function()
    it("adds a tag rule", function()
      local m = Matrix.new()
      m:add("foo", { "x", "y" })
      m:tag({ foo = "x" }, "X")
      m:tag({ foo = "y" }, "why")

      assert_same_elements({
        { matrix = { foo = "x" }, tags = { "X" } },
        { matrix = { foo = "y" }, tags = { "why" } },
      }, m:render())
    end)
  end)

  describe("include()", function()
    it("registers an inclusion", function()
      local m = Matrix.new()
      m:add("foo", { 1, 2 })

      m:include({ foo = 3 })

      assert_same_elements({
        { matrix = { foo = 1 } },
        { matrix = { foo = 2 } },
        { matrix = { foo = 3 } },
      }, m:render(), "expcted `foo = 3` to be added by include()")
    end)
  end)

  describe("exclude()", function()
    it("registers an exclusion", function()
      local m = Matrix.new()
      m:add("foo", { 1, 2 })

      m:exclude({ foo = 1 })

      assert_same_elements({
        { matrix = { foo = 2 } },
      }, m:render(), "expected `foo = 1` to be removed by exclude()")
    end)
  end)

  describe("render()", function()
    it("produces an array with each permutation", function()
      local m = Matrix.new()
      m:add("foo", { "a", "b" })

      local rendered = m:render()
      assert.table(rendered)
      assert.equals(2, #rendered)

      assert_same_elements({
        { foo = "a" },
        { foo = "b" },
      }, map_key(m:render(), "matrix"))

      -- add another variable and re-render
      m:add("bar", { "x", "y" })

      assert_same_elements({
        { foo = "a", bar = "x" },
        { foo = "a", bar = "y" },
        { foo = "b", bar = "x" },
        { foo = "b", bar = "y" },
      }, map_key(m:render(), "matrix"))
    end)

    -- https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategymatrixinclude
    it("handles inclusions (github example 01)", function()
      local m = Matrix.new()

      m:add("fruit", { "apple", "pear" })
      m:add("animal", { "cat", "dog" })

      assert_same_elements({
        { fruit = "apple", animal = "cat", color = nil, shape = nil },
        { fruit = "apple", animal = "dog", color = nil, shape = nil },
        { fruit = "pear",  animal = "cat", color = nil, shape = nil },
        { fruit = "pear",  animal = "dog", color = nil, shape = nil },
      }, map_key(m:render(), "matrix"), "initial matrix is incorrect")


      -- unconditionally add `color = "green"` to all entries
      m:include({ color = "green" })
      assert_same_elements({
        { fruit = "apple", animal = "cat", color = "green", shape = nil },
        { fruit = "apple", animal = "dog", color = "green", shape = nil },
        { fruit = "pear",  animal = "cat", color = "green", shape = nil },
        { fruit = "pear",  animal = "dog", color = "green", shape = nil },
      }, map_key(m:render(), "matrix"), "expected all items to have color == 'green'")


      -- set `color = "pink"` where `animal == "cat"`
      m:include({ color = "pink", animal = "cat" })
      assert_same_elements({
        { fruit = "apple", animal = "cat", color = "pink",  shape = nil },
        { fruit = "apple", animal = "dog", color = "green", shape = nil },
        { fruit = "pear",  animal = "cat", color = "pink",  shape = nil },
        { fruit = "pear",  animal = "dog", color = "green", shape = nil },
      }, map_key(m:render(), "matrix"), "expected color = 'pink' where animal == 'cat'")


      -- set `shape = "circle"` where `fruit == "apple"`
      m:include({ fruit = "apple", shape = "circle" })
      assert_same_elements({
        { fruit = "apple", animal = "cat", color = "pink",  shape = "circle" },
        { fruit = "apple", animal = "dog", color = "green", shape = "circle" },
        { fruit = "pear",  animal = "cat", color = "pink",  shape = nil },
        { fruit = "pear",  animal = "dog", color = "green", shape = nil },
      }, map_key(m:render(), "matrix"), "expected shape = 'circle' where fruit == 'apple'")

      -- adds new `{ fruit = "banana" }` entry
      m:include({ fruit = "banana" })
      assert_same_elements({
        { fruit = "apple",  animal = "cat", color = "pink",  shape = "circle" },
        { fruit = "apple",  animal = "dog", color = "green", shape = "circle" },
        { fruit = "pear",   animal = "cat", color = "pink",  shape = nil },
        { fruit = "pear",   animal = "dog", color = "green", shape = nil },
        { fruit = "banana", animal = nil,   color = nil,     shape = nil },
      }, map_key(m:render(), "matrix"), "expected new fruit = 'banana' entry")

      -- adds new `{ fruit = "banana", animal = "cat" }` entry
      -- does not affect `{ fruit = "banana" }` because it was not a member of the
      -- original matrix vars
      m:include({ fruit = "banana", animal = "cat" })
      assert_same_elements({
        { fruit = "apple",  animal = "cat", color = "pink",  shape = "circle" },
        { fruit = "apple",  animal = "dog", color = "green", shape = "circle" },
        { fruit = "pear",   animal = "cat", color = "pink",  shape = nil },
        { fruit = "pear",   animal = "dog", color = "green", shape = nil },
        { fruit = "banana", animal = nil,   color = nil,     shape = nil },
        { fruit = "banana", animal = "cat", color = nil,     shape = nil },
      }, map_key(m:render(), "matrix"), "expected new fruit = 'banana', animal = 'cat' entry")
    end)

    -- https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#example-expanding-configurations
    it("handles inclusions (github example 02)", function()
      local m = Matrix.new()
      m:add("os", { "windows-latest", "ubuntu-latest" })
      m:add("node", { 14, 16 })
      m:include({ os = "windows-latest", node = 16, npm = 6 })

      assert_same_elements({
        { os = "windows-latest", node = 14, npm = nil },
        { os = "windows-latest", node = 16, npm = 6   },
        { os = "ubuntu-latest",  node = 14, npm = nil },
        { os = "ubuntu-latest",  node = 16, npm = nil },
      }, map_key(m:render(), "matrix"))
    end)

    -- https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategymatrixexclude
    it("handles exclusions (github example 01)", function()
      local m = Matrix.new()
      m:add("os", { "macos-latest", "windows-latest" })
      m:add("version", { 12, 14, 16 })
      m:add("environment", { "staging", "production" })

      assert_same_elements({
        { os = "macos-latest", version = 12, environment = "staging" },
        { os = "macos-latest", version = 14, environment = "staging" },
        { os = "macos-latest", version = 16, environment = "staging" },
        { os = "macos-latest", version = 12, environment = "production" },
        { os = "macos-latest", version = 14, environment = "production" },
        { os = "macos-latest", version = 16, environment = "production" },

        { os = "windows-latest", version = 12, environment = "staging" },
        { os = "windows-latest", version = 14, environment = "staging" },
        { os = "windows-latest", version = 16, environment = "staging" },
        { os = "windows-latest", version = 12, environment = "production" },
        { os = "windows-latest", version = 14, environment = "production" },
        { os = "windows-latest", version = 16, environment = "production" },
      }, map_key(m:render(), "matrix"))

      m:exclude({ os = "macos-latest",   version = 12, environment = "production" })
      m:exclude({ os = "windows-latest", version = 16, environment = nil })

      assert_same_elements({
        { os = "macos-latest", version = 12, environment = "staging" },
        { os = "macos-latest", version = 14, environment = "staging" },
        { os = "macos-latest", version = 16, environment = "staging" },

      --[[ removed by :exclude()
        { os = "macos-latest", version = 12, environment = "production" },
      ]]--

        { os = "macos-latest", version = 14, environment = "production" },
        { os = "macos-latest", version = 16, environment = "production" },

        { os = "windows-latest", version = 12, environment = "staging" },
        { os = "windows-latest", version = 14, environment = "staging" },

      --[[ removed by :exclude()
        { os = "windows-latest", version = 16, environment = "staging" },
      ]]--

        { os = "windows-latest", version = 12, environment = "production" },
        { os = "windows-latest", version = 14, environment = "production" },

      --[[ removed by :exclude()
        { os = "windows-latest", version = 16, environment = "production" },
      ]]--
      }, map_key(m:render(), "matrix"))
    end)

    it("handles inclusions after expansions", function()
      local m = Matrix.new()
      m:add("foo", { 1, 2 })

      m:exclude({ foo = 1 })

      assert_same_elements({
        { matrix = { foo = 2 } },
      }, m:render(), "expected `foo = 1` to be removed by exclude()")

      m:include({ foo = 1 })

      assert_same_elements({
        { matrix = { foo = 1 } },
        { matrix = { foo = 2 } },
      }, m:render(), "expected `foo = 1` to be re-added by include()")
    end)
  end)
end)
