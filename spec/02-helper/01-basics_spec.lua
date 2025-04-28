local seen = {}

local function assert_matrix(matrix, ctx)
  local msg = "expected matrix object to be populated in " .. ctx
  assert.table(matrix, msg)
  assert.number(matrix.y, msg)

  if matrix.y == 123 then
    assert.equals(3, matrix.c, msg)
  else
    assert.is_nil(matrix.c, msg)
    assert.number(matrix.x, msg)
  end

  local key = string.format("%s x = %q, y = %q",
                            ctx, matrix.x, matrix.y)

  assert.is_nil(seen[key], "duplicate matrix: " .. key)
  seen[key] = true

  assert.has_error(function()
    matrix.x = 7
  end, "attempting to overwrite matrix var")

  assert.has_error(function()
    matrix.new = 123
  end, "attempting to overwrite matrix var")

  assert.error_matches(function()
    print(matrix.not_a_var)
  end, "unknown matrix var: not_a_var")
end


MATRIX {
  vars = {
    x = { 1, 2 },
    y = { 3, 4 },
  },

  include = {
    { y = 123, c = 3 },
  },

  tags = {
    { match = { c = 3 }, tags = "c3" }
  },
}


describe("basic usage", function()
  assert_matrix(matrix, "describe()")

  strict_setup(function()
    assert_matrix(matrix, "strict_setup()")
  end)

  strict_teardown(function()
    assert_matrix(matrix, "strict_teardown()")
  end)

  lazy_setup(function()
    assert_matrix(matrix, "lazy_setup()")
  end)

  lazy_teardown(function()
    assert_matrix(matrix, "lazy_teardown()")
  end)

  before_each(function()
    assert_matrix(matrix, "before_each()")
  end)

  after_each(function()
    assert_matrix(matrix, "after_each()")
  end)

  it("test case", function()
    finally(function()
      assert_matrix(matrix, "finally()")
    end)

    assert_matrix(matrix, "it()")
  end)
end)
