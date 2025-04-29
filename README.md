# busted-matrix

[![CI](https://github.com/flrgh/busted-matrix/actions/workflows/test.yml/badge.svg)](https://github.com/flrgh/busted-matrix/actions/workflows/test.yml)

Persue more permutations.

Cover all corners.

Scan every scenario.

Comb each combination.

Demand more dimensions.

**Master the matrix.**


## synopsis

`busted-matrix` helps you write test cases for different permutations of your
inputs.

Example:

<details open>

<summary><a href="/examples/numbers_spec.lua">numbers_spec.lua</a></summary>

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

local function is_odd(n)
  return n % 2 ~= 0
end

local function is_even(n)
  return n % 2 == 0
end

describe("numbers", function()
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
```

</details>

```console
$ busted -o TAP --helper busted.matrix.helper examples/numbers_spec.lua
ok 1 - numbers [even = 4, odd = 1] odds are odd
ok 2 - numbers [even = 4, odd = 1] evens are even
ok 3 - numbers [even = 4, odd = 1] odd times even is always even
ok 4 - numbers #lucky [even = 4] odds are odd
ok 5 - numbers #lucky [even = 4] evens are even
ok 6 - numbers #lucky [even = 4] odd times even is always even
ok 7 - numbers #unlucky [even = 4] odds are odd
ok 8 - numbers #unlucky [even = 4] evens are even
ok 9 - numbers #unlucky [even = 4] odd times even is always even
ok 10 - numbers [even = 42, odd = 1] odds are odd
ok 11 - numbers [even = 42, odd = 1] evens are even
ok 12 - numbers [even = 42, odd = 1] odd times even is always even
ok 13 - numbers #lucky [even = 42] odds are odd
ok 14 - numbers #lucky [even = 42] evens are even
ok 15 - numbers #lucky [even = 42] odd times even is always even
ok 16 - numbers #unlucky [even = 42] odds are odd
ok 17 - numbers #unlucky [even = 42] evens are even
ok 18 - numbers #unlucky [even = 42] odd times even is always even
1..18
```

## the old way

Without `busted-matrix`, permutation testing is ungainly, typically requiring you
to iterate over inputs and create `describe()` and `it()` blocks in the loop
body:

1. Each new variable increases code indentation level
2. Ugly string-munging code is required to create unique test labels

```lua
local odds =  { 1, 7, 13 }
local evens = { 4, 42 }

for _, odd in ipairs(odds) do
  for _, even in pairs(evens) do
    describe("numbers [even = " .. tostring(even)
             .. ", odd = " .. tostring(odd) .. "]", function()

      it("odds are odd", function()
        assert(is_odd(odd))
      end)

      it("evens are even", function()
        assert(is_even(even))
      end)

      it("odd times even is always even", function()
        assert(is_even(odd * even))
      end)
    end)
  end
end
```


# installation

**TODO** (install it by hand for now)

### requirements

`busted-matrix` requires busted >= 2.1.2


# documentation

## using `busted-matrix` in your project

To use `busted-matrix`'s main features, you must tell `busted` to load it as a
helper script. This can be done via the command line:

```console
# hard-coded path
busted --helper path/to/busted/matrix.helper

# require()-like syntax
busted -- helper "busted.matrix.helper"
```

...*or* via your `.busted` config file:

```lua
return {
  _all = {
    helper = "busted.matrix.helper",

    -- alternatively
    helper = "path/to/busted/matrix/helper.lua",
  },
}
```

## the `MATRIX` block

Once you've installed `busted-matrix` and configured `busted` to load it as a
helper, you can start using the `MATRIX` block in your test files.

`MATRIX` is overloaded, so there are several ways to use it depending on what
suits your code. The following examples are equivalent:

```lua
-- all at once
MATRIX {
  vars = {
    x = { 1, 2 },
    y = { 3, 4 },
  },
}

-- add vars individually
MATRIX("x", { 1, 2 })
MATRIX("y", { 3, 4 })

-- run your own code in the MATRIX context
MATRIX(function()
  add("x", { 1, 2 })
  add("y", { 3, 4 })
end)
```

## include

Matricies can be expanded and updated via `include` directives:

```lua
MATRIX(function()
  add("x", { 1, 2 })
  add("y", { 3, 4 })

  -- add a combo with `x = 23`
  include { x = 23 }

  -- add `n = 98` to all combos
  include { n = 98 }

  -- override `n = 99` when `x == 1`
  include { n = 99, x = 1 }

  -- add `z = 12` when `y == 4`
  include { z = 12, y = 4 }
end)

describe("matrix", function()
  describe("(z)", function()
    it("is 12 when y is 4 and nil otherwise", function()
      -- XXX: conditional asserts are often a test code smell. This is a
      -- demonstration of matrix behavior and not a suggestion of how to
      -- write tests

      if matrix.y == 4 then
        assert.equals(12, matrix.z)
      else
        assert.is_nil(matrix.z)
      end
    end)
  end)

  describe("(n)", function()
    it("is 99 when x is 1, nil when x is 23, and 98 otherwise", function()
      if matrix.x == 1 then
        assert.equals(99, matrix.n)
      elseif matrix.x == 23 then
        assert.is_nil(matrix.n)
      else
        assert.equals(98, matrix.n)
      end
    end)
  end)

  describe("x = 23", function()
    it("everything else is nil", function()
      if matrix.x == 23 then
        assert.is_nil(matrix.y)
        assert.is_nil(matrix.n)
        assert.is_nil(matrix.z)
      end
    end)
  end)
end)
```

## exclude

Combinations can be excluded from the matrix via the `exclude` directive. This
pattern is typically used when some combination of input variables is untestable
or fundamentally unreachable in real world code:

```lua
MATRIX {
  vars = {
    meat = { true, false },
    pudding = { true, false },
  },

  exclude = {
    -- How can you have any pudding if you don't eat yer meat?!
    { meat = false, pudding = true },
  },
}
```

## matrix behavior

For the sake of familiarity with existing tooling and workflows, matrix behavior
is modeled after the `matrix` property in Github Actions (`busted-matrix` even
has unit tests for Github's usage examples). See the 
[documentation](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow)
for more.

## tagging

`busted-matrix` can tag test cases based on configurable combination criteria.
This is helpful for applying tags to your tests for filtering:

```lua
MATRIX {
  vars = {
    foo = { true, false },
    bar = { true, false },
  },

  tags = {
    -- we can't test foo in CI yet!
    -- add the `skip_ci` tag so we can skip it for now
    { match = { foo = true  }, tags = { "foo", "skip_ci" } },
  },
}

describe("foo?", function()
  it("test", function()
    -- ...
  end)
end)
```

Tagging has broader effects on the way that `busted-matrix` labels your test
cases. When a tag matches a matrix combination, the fields that it matched on
are consumed and no longer used in the label:

```console
$ busted -o TAP --helper busted.matrix.helper foo_spec.lua
ok 1 - foo? #foo #skip_ci [bar = true] test
ok 2 - foo? #foo #skip_ci [bar = false] test
ok 3 - foo? [bar = true, foo = false] test
ok 4 - foo? [bar = false, foo = false] test
1..4
```

## debugging

`busted-matrix` will print diagnostic info to `stdout` when debugging is
enabled. This can be done a few different ways:

* set `BUSTED_MATRIX_DEBUG=1` in busted's environment
* pass the `--debug` flag  to the helper (`busted -Xhelper --debug ...`)
* run busted in verbose mode (`busted --verbose ...`)

Use `-Xhelper --no-debug` to explicitly disable debug output from
`busted-matrix` (i.e. `busted --verbose -Xhelper --no-debug ...` enables
busted's verbose mode and disables `busted-matrix`'s debug mode)
