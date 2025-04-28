local Matrix = require("busted.matrix")

local helpers = require("spec.helpers")

local assert_same_elements = helpers.assert_same_elements
local extract = helpers.extract

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
      }, extract(m:render(), "matrix"))

      -- add another variable and re-render
      m:add("bar", { "x", "y" })

      assert_same_elements({
        { foo = "a", bar = "x" },
        { foo = "a", bar = "y" },
        { foo = "b", bar = "x" },
        { foo = "b", bar = "y" },
      }, extract(m:render(), "matrix"))
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
