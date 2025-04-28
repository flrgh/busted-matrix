local Matrix = require("busted.matrix")

local helpers = require("spec.helpers")

local assert_same_elements = helpers.assert_same_elements
local extract = helpers.extract

describe("GitHub Actions Examples", function()
  describe("basic", function()

    -- https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategymatrixinclude
    it("01", function()
      local m = Matrix.new()

      m:add("fruit", { "apple", "pear" })
      m:add("animal", { "cat", "dog" })

      assert_same_elements({
        { fruit = "apple", animal = "cat", color = nil, shape = nil },
        { fruit = "apple", animal = "dog", color = nil, shape = nil },
        { fruit = "pear",  animal = "cat", color = nil, shape = nil },
        { fruit = "pear",  animal = "dog", color = nil, shape = nil },
      }, extract(m:render(), "matrix"), "initial matrix is incorrect")


      -- unconditionally add `color = "green"` to all entries
      m:include({ color = "green" })
      assert_same_elements({
        { fruit = "apple", animal = "cat", color = "green", shape = nil },
        { fruit = "apple", animal = "dog", color = "green", shape = nil },
        { fruit = "pear",  animal = "cat", color = "green", shape = nil },
        { fruit = "pear",  animal = "dog", color = "green", shape = nil },
      }, extract(m:render(), "matrix"), "expected all items to have color == 'green'")


      -- set `color = "pink"` where `animal == "cat"`
      m:include({ color = "pink", animal = "cat" })
      assert_same_elements({
        { fruit = "apple", animal = "cat", color = "pink",  shape = nil },
        { fruit = "apple", animal = "dog", color = "green", shape = nil },
        { fruit = "pear",  animal = "cat", color = "pink",  shape = nil },
        { fruit = "pear",  animal = "dog", color = "green", shape = nil },
      }, extract(m:render(), "matrix"), "expected color = 'pink' where animal == 'cat'")


      -- set `shape = "circle"` where `fruit == "apple"`
      m:include({ fruit = "apple", shape = "circle" })
      assert_same_elements({
        { fruit = "apple", animal = "cat", color = "pink",  shape = "circle" },
        { fruit = "apple", animal = "dog", color = "green", shape = "circle" },
        { fruit = "pear",  animal = "cat", color = "pink",  shape = nil },
        { fruit = "pear",  animal = "dog", color = "green", shape = nil },
      }, extract(m:render(), "matrix"), "expected shape = 'circle' where fruit == 'apple'")

      -- adds new `{ fruit = "banana" }` entry
      m:include({ fruit = "banana" })
      assert_same_elements({
        { fruit = "apple",  animal = "cat", color = "pink",  shape = "circle" },
        { fruit = "apple",  animal = "dog", color = "green", shape = "circle" },
        { fruit = "pear",   animal = "cat", color = "pink",  shape = nil },
        { fruit = "pear",   animal = "dog", color = "green", shape = nil },
        { fruit = "banana", animal = nil,   color = nil,     shape = nil },
      }, extract(m:render(), "matrix"), "expected new fruit = 'banana' entry")

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
      }, extract(m:render(), "matrix"), "expected new fruit = 'banana', animal = 'cat' entry")
    end)
  end)

  describe("include()", function()

    -- https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#example-expanding-configurations
    it("01", function()
      local m = Matrix.new()
      m:add("os", { "windows-latest", "ubuntu-latest" })
      m:add("node", { 14, 16 })
      m:include({ os = "windows-latest", node = 16, npm = 6 })

      assert_same_elements({
        { os = "windows-latest", node = 14, npm = nil },
        { os = "windows-latest", node = 16, npm = 6   },
        { os = "ubuntu-latest",  node = 14, npm = nil },
        { os = "ubuntu-latest",  node = 16, npm = nil },
      }, extract(m:render(), "matrix"))
    end)
  end)

  describe("exclude()", function()

    -- https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategymatrixexclude
    it("01", function()
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
      }, extract(m:render(), "matrix"))

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
      }, extract(m:render(), "matrix"))
    end)
  end)
end)
