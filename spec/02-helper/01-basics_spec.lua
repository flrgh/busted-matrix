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
                            ctx, tostring(matrix.x), tostring(matrix.y))

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

local function assert_matrix_all(matrix, ctx)
  local msg = "expected matrix object to be populated in " .. ctx
  assert.table(matrix, msg)
  assert.is_function(matrix.all, msg)

  local block_seen = {}
  local count = 0

  for each in matrix.all() do
    local key = string.format("%s x = %q, y = %q",
                              ctx, tostring(each.x), tostring(each.y))

    assert.is_nil(block_seen[key], "duplicate matrix: " .. key)
    block_seen[key] = true
    count = count + 1
  end

  assert.equals(5, count)
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

lazy_setup(function()
  assert_matrix_all(matrix, "file() -> lazy_setup()")
end)

strict_setup(function()
  assert_matrix_all(matrix, "file() -> strict_setup()")
end)

lazy_teardown(function()
  assert_matrix_all(matrix, "file() -> lazy_teardown()")
end)

strict_teardown(function()
  assert_matrix_all(matrix, "file() -> strict_teardown()")
end)

describe("basic usage", function()
  assert_matrix(matrix, "describe()")

  strict_setup(function()
    assert_matrix(matrix, "describe() -> strict_setup()")
  end)

  strict_teardown(function()
    assert_matrix(matrix, "describe() -> strict_teardown()")
  end)

  lazy_setup(function()
    assert_matrix(matrix, "describe() -> lazy_setup()")
  end)

  lazy_teardown(function()
    assert_matrix(matrix, "describe() -> lazy_teardown()")
  end)

  before_each(function()
    assert_matrix(matrix, "describe() -> before_each()")
  end)

  after_each(function()
    assert_matrix(matrix, "describe() -> after_each()")
  end)

  it("test case", function()
    finally(function()
      assert_matrix(matrix, "describe() -> it() -> finally()")
    end)

    assert_matrix(matrix, "describe() -> it()")
  end)
end)
