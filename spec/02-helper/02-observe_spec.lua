assert(matrix == nil)

local helpers = require("spec.helpers")

local busted_exec = helpers.busted_exec
local test_spec = helpers.fixtures.test_spec

describe("integration with busted", function()
  it("works", function()
    local res = busted_exec({
      "--output", "TAP",
      test_spec,
    })

    helpers.assert_stdout_lines({
      "ok 1 - one [bar = a, foo = x] before inner matrix",
      "ok 2 - one [bar = a, foo = x] after inner matrix #yes",
      "ok 3 - one [bar = a, foo = x] after inner matrix #no",
      "ok 4 - one [bar = a, foo = x] nest #yes works (nested)",
      "ok 5 - one [bar = a, foo = x] nest #no works (nested)",
      "ok 6 - one [bar = b, foo = x] before inner matrix",
      "ok 7 - one [bar = b, foo = x] after inner matrix #yes",
      "ok 8 - one [bar = b, foo = x] after inner matrix #no",
      "ok 9 - one [bar = b, foo = x] nest #yes works (nested)",
      "ok 10 - one [bar = b, foo = x] nest #no works (nested)",
      "ok 11 - one [bar = a, foo = y] before inner matrix",
      "ok 12 - one [bar = a, foo = y] after inner matrix #yes",
      "ok 13 - one [bar = a, foo = y] after inner matrix #no",
      "ok 14 - one [bar = a, foo = y] nest #yes works (nested)",
      "ok 15 - one [bar = a, foo = y] nest #no works (nested)",
      "ok 16 - one [bar = b, foo = y] before inner matrix",
      "ok 17 - one [bar = b, foo = y] after inner matrix #yes",
      "ok 18 - one [bar = b, foo = y] after inner matrix #no",
      "ok 19 - one [bar = b, foo = y] nest #yes works (nested)",
      "ok 20 - one [bar = b, foo = y] nest #no works (nested)",
      "ok 21 - two [bar = a, foo = x] works",
      "ok 22 - two [bar = b, foo = x] works",
      "ok 23 - two [bar = a, foo = y] works",
      "ok 24 - two [bar = b, foo = y] works",
      "ok 25 - three [bar = a, foo = x]",
      "ok 26 - three [bar = b, foo = x]",
      "ok 27 - three [bar = a, foo = y]",
      "ok 28 - three [bar = b, foo = y]",
      "1..28",
    }, res)

    assert.equals("", res.stderr)
  end)

  -- `busted --list` is a special case because it installs a handler with higher
  -- priority than our own that skips the `{ "describe", "start" }` event
  it("works with --list", function()
    local res = busted_exec({
      "--output", "TAP",
      test_spec,
      "--list",
    })

    helpers.assert_stdout_lines({
      "spec/fixtures/test_spec.lua:10: one [bar = a, foo = x] before inner matrix",
      "spec/fixtures/test_spec.lua:21: one [bar = a, foo = x] after inner matrix #yes",
      "spec/fixtures/test_spec.lua:21: one [bar = a, foo = x] after inner matrix #no",
      "spec/fixtures/test_spec.lua:36: one [bar = a, foo = x] nest #yes works (nested)",
      "spec/fixtures/test_spec.lua:36: one [bar = a, foo = x] nest #no works (nested)",
      "spec/fixtures/test_spec.lua:10: one [bar = b, foo = x] before inner matrix",
      "spec/fixtures/test_spec.lua:21: one [bar = b, foo = x] after inner matrix #yes",
      "spec/fixtures/test_spec.lua:21: one [bar = b, foo = x] after inner matrix #no",
      "spec/fixtures/test_spec.lua:36: one [bar = b, foo = x] nest #yes works (nested)",
      "spec/fixtures/test_spec.lua:36: one [bar = b, foo = x] nest #no works (nested)",
      "spec/fixtures/test_spec.lua:10: one [bar = a, foo = y] before inner matrix",
      "spec/fixtures/test_spec.lua:21: one [bar = a, foo = y] after inner matrix #yes",
      "spec/fixtures/test_spec.lua:21: one [bar = a, foo = y] after inner matrix #no",
      "spec/fixtures/test_spec.lua:36: one [bar = a, foo = y] nest #yes works (nested)",
      "spec/fixtures/test_spec.lua:36: one [bar = a, foo = y] nest #no works (nested)",
      "spec/fixtures/test_spec.lua:10: one [bar = b, foo = y] before inner matrix",
      "spec/fixtures/test_spec.lua:21: one [bar = b, foo = y] after inner matrix #yes",
      "spec/fixtures/test_spec.lua:21: one [bar = b, foo = y] after inner matrix #no",
      "spec/fixtures/test_spec.lua:36: one [bar = b, foo = y] nest #yes works (nested)",
      "spec/fixtures/test_spec.lua:36: one [bar = b, foo = y] nest #no works (nested)",
      "spec/fixtures/test_spec.lua:53: two [bar = a, foo = x] works",
      "spec/fixtures/test_spec.lua:53: two [bar = b, foo = x] works",
      "spec/fixtures/test_spec.lua:53: two [bar = a, foo = y] works",
      "spec/fixtures/test_spec.lua:53: two [bar = b, foo = y] works",
      "three [bar = a, foo = x]",
      "three [bar = b, foo = x]",
      "three [bar = a, foo = y]",
      "three [bar = b, foo = y]",
    }, res)

    assert.equals("", res.stderr)
  end)

  it("does not expand across files", function()
    local res = busted_exec({
      "--output", "TAP",
      "spec/fixtures/expand_spec.lua",
      "spec/fixtures/no_expand_spec.lua",
    })

    helpers.assert_stdout_lines({
      "ok 1 - expansion [expand = 1] expands the matrix",
      "ok 2 - expansion [expand = 2] expands the matrix",
      "ok 3 - expansion does not expand the matrix",
      "1..3",
    }, res)
  end)
end)
