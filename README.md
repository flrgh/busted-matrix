# busted-matrix

Permit more permutations.

Cover more corners.

Sense more scenarios.

Conquer more combinations.

## synopsis

`busted-matrix` helps you write test cases for different permutations of your
inputs.


```lua
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

describe("numbers", function()
  it("odds are odd", function()
    assert.not_equals(0, matrix.odd % 2)
  end)

  it("evens are even", function()
    assert.equals(0, matrix.even % 2)
  end)

  it("odds never == evens", function()
    assert.not_equal(matrix.even, matrix.odd)
  end)
end)
```

```console
$ busted -o htest --helper busted.matrix.helper numbers_spec.lua
======= Running tests from scanned files.
------- Global test environment setup.
------- Running tests from numbers_spec.lua :
   0.08   OK 14: numbers [even = 4, odd = 1] odds are odd
   0.06   OK 18: numbers [even = 4, odd = 1] evens are even
   0.06   OK 22: numbers [even = 4, odd = 1] odds never == evens
   0.07   OK 14: numbers [even = 42, odd = 1] odds are odd
   0.06   OK 18: numbers [even = 42, odd = 1] evens are even
   0.06   OK 22: numbers [even = 42, odd = 1] odds never == evens
   0.07   OK 14: numbers #lucky [even = 4] odds are odd
   0.08   OK 18: numbers #lucky [even = 4] evens are even
   0.08   OK 22: numbers #lucky [even = 4] odds never == evens
   0.06   OK 14: numbers #lucky [even = 42] odds are odd
   0.05   OK 18: numbers #lucky [even = 42] evens are even
   0.03   OK 22: numbers #lucky [even = 42] odds never == evens
   0.15   OK 14: numbers #unlucky [even = 4] odds are odd
   0.09   OK 18: numbers #unlucky [even = 4] evens are even
   0.11   OK 22: numbers #unlucky [even = 4] odds never == evens
   0.04   OK 14: numbers #unlucky [even = 42] odds are odd
   0.09   OK 18: numbers #unlucky [even = 42] evens are even
   0.09   OK 22: numbers #unlucky [even = 42] odds never == evens
------- 18 tests from numbers_spec.lua (4.76 ms total)

------- Global test environment teardown.
======= 18 tests from 1 test file ran. (4.91 ms total)
PASSED  18 tests.
```
