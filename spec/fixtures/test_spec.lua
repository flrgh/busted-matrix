MATRIX("foo", { "x", "y" })

MATRIX("bar", function()
  add({ "a", "b" })
end)

describe("one", function()
  local parent = matrix

  it("before inner matrix", function()
    assert(matrix.foo == "x" or matrix.foo == "y")
    assert(matrix.bar == "a" or matrix.bar == "b")
  end)

  MATRIX("inner", function()
    add { true, false }
    tag({ inner = true }, "yes")
    tag({ inner = false }, "no")
  end)

  it("after inner matrix", function()
    assert.has_error(function()
      print(matrix.foo)
    end)
    assert.has_error(function()
      print(matrix.bar)
    end)

    assert(parent.foo == "x" or parent.foo == "y")
    assert(parent.bar == "a" or parent.bar == "b")

    assert(matrix.inner == true or matrix.inner == false)
  end)

  describe("nest", function()
    it("works (nested)", function()
      assert.has_error(function()
        print(matrix.foo)
      end)
      assert.has_error(function()
        print(matrix.bar)
      end)

      assert(parent.foo == "x" or parent.foo == "y")
      assert(parent.bar == "a" or parent.bar == "b")

      assert(matrix.inner == true or matrix.inner == false)
    end)
  end)
end)

describe("two", function()
  it("works", function()
    assert(matrix.foo == "x" or matrix.foo == "y")
    assert(matrix.bar == "a" or matrix.bar == "b")
  end)
end)

local three_count = 0

it("three", function()
  three_count = three_count + 1
  assert(three_count < 5)

  assert(matrix.foo == "x" or matrix.foo == "y")
  assert(matrix.bar == "a" or matrix.bar == "b")
end)
