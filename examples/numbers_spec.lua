MATRIX {
  vars = {
    odd = { 1, 7, 13 },
    even = { 4, 42 },
  },

  tags = {
    { match = { odd = 7 }, tags = { "lucky" } },
    { match = { odd = 13 }, tags = { "unlucky" } },
  },

}

local function is_odd(n)
  return n % 2 ~= 0
end

local function is_even(n)
  return n % 2 == 0
end

local sum = 0
setup(function()
  for _, each in ipairs(matrix.all) do
    sum = sum + each.odd + each.even
  end
end)

describe("numbers", function()
  assert.equals(180, sum, "setup() adds everything up")

  it("odds are odd", function()
    assert(is_odd(matrix.odd))
  end)

  it("evens are even", function()
    assert(is_even(matrix.even))
  end)

  it("odd times even is always even", function()
    assert(is_even(matrix.odd * matrix.even))
  end)
end)
