describe("nested matrices", function()
  MATRIX("outer", function()
    add("outer", { 1, 2 })
  end)

  setup(function()
  end)

  describe("nest", function()
    MATRIX("inner", function()
      add("inner", { 1, 2 })
    end)

    setup(function()
    end)

    it("can access inner properties", function()
      assert(matrix.inner == 1 or matrix.inner == 2)
    end)

    it("cannot access outer properties", function()
      assert.has_error(function()
        print(matrix.outer)
      end)
    end)
  end)

  it("can access outer properties", function()
    assert(matrix.outer == 1 or matrix.outer == 2)
  end)

  it("cannot access inner properties", function()
    assert.has_error(function()
      print(matrix.inner)
    end)
  end)
end)
