local Matrix = require("busted.matrix")

local helpers = require("spec.helpers")

local assert_same_elements = helpers.assert_same_elements
local extract = helpers.extract

describe("busted.matrix", function()
  ---@type busted.matrix
  local m

  before_each(function()
    m = Matrix.new()
  end)

  describe("new()", function()
    it("creates a new matrix", function()
      m = Matrix.new()
      assert.table(m)
    end)
  end)

  describe("add()", function()
    it("adds a new variable", function()
      m:add("foo", { 1, 2 })
      m:add("bar", { 3, 4 })
    end)

    it("errors on duplicate variables", function()
      m:add("foo", { 1, 2 })

      assert.has_error(function()
        m:add("foo", { 3, 4 })
      end)
    end)

    it("errors on bad inputs", function()
      assert.has_error(function() m:add() end)
      assert.has_error(function() m:add(123) end)
      assert.has_error(function() m:add({}) end)
      assert.has_error(function() m:add("yes", 123) end)
      assert.has_error(function() m:add("yes", nil) end)
    end)

    it("errors on empty value tables", function()
      assert.has_error(function() m:add("var", {}) end)
    end)
  end)

  describe("tag()", function()
    it("adds a tag rule", function()
      m:add("foo", { "x", "y" })
      m:tag({ foo = "x" }, "X")
      m:tag({ foo = "y" }, "why")

      assert_same_elements({
        { matrix = { foo = "x" }, tags = { "X" } },
        { matrix = { foo = "y" }, tags = { "why" } },
      }, m:render())
    end)

    it("accepts a table or string for the tag", function()
      m:tag({ x = 1 }, { "tag" })
      m:tag({ y = 1 }, "tag" )
    end)

    it("errors on bad match inputs", function()
      assert.has_error(function() m:tag(nil, "tag") end)
      assert.has_error(function() m:tag("no", "tag") end)
      assert.has_error(function() m:tag(123, "tag") end)
      assert.has_error(function() m:tag({}, "tag") end)
    end)

    it("errors on bad tag inputs", function()
      assert.has_error(function() m:tag({ x = 1 }, 123) end)
      assert.has_error(function() m:tag({ x = 1 }, {}) end)
      assert.has_error(function() m:tag({ x = 1 }, { foo = 1 }) end)
      assert.has_error(function() m:tag({ x = 1 }, { "" }) end)
      assert.has_error(function() m:tag({ x = 1 }, "") end)
      assert.has_error(function() m:tag({ x = 1 }, { [0] = 1 }) end)
      assert.has_error(function() m:tag({ x = 1 }, { "a", "a" }) end)
    end)
  end)

  describe("include()", function()
    it("registers an inclusion", function()
      m:add("foo", { 1, 2 })

      m:include({ foo = 3 })

      assert_same_elements({
        { matrix = { foo = 1 } },
        { matrix = { foo = 2 } },
        { matrix = { foo = 3 } },
      }, m:render(), "expcted `foo = 3` to be added by include()")
    end)

    it("errors on bad inputs", function()
      assert.has_error(function() m:include() end)
      assert.has_error(function() m:include("nope") end)
      assert.has_error(function() m:include({}) end)
    end)
  end)

  describe("exclude()", function()
    it("registers an exclusion", function()
      m:add("foo", { 1, 2 })

      m:exclude({ foo = 1 })

      assert_same_elements({
        { matrix = { foo = 2 } },
      }, m:render(), "expected `foo = 1` to be removed by exclude()")
    end)

    it("errors on bad inputs", function()
      assert.has_error(function() m:exclude() end)
      assert.has_error(function() m:exclude("nope") end)
      assert.has_error(function() m:exclude({}) end)
    end)
  end)

  describe("render()", function()
    it("produces an array with each permutation", function()
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
