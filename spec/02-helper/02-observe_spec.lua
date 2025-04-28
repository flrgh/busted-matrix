local helpers = require("spec.helpers")

local busted_exec = helpers.busted_exec
local test_spec = helpers.fixtures.test_spec

describe("integration with busted", function()
  it("works", function()
    local stdout, stderr = busted_exec({
      "--output", "TAP",
      test_spec,
    })

    assert.string(stdout)
    print("STDOUT: " .. stdout .. "\n")

    assert.string(stderr)
    print("STDERR: " .. stderr .. "\n")
  end)

  -- `busted --list` is a special case because it installs a handler with higher
  -- priority than our own that skips the `{ "describe", "start" }` event
  it("works with --list", function()
    local stdout, stderr = busted_exec({
      "--output", "TAP",
      "./spec/02-helper/01-basics_spec.lua",
      "--list",
    })

    assert.string(stdout)
    print("STDOUT: " .. stdout .. "\n")

    assert.string(stderr)
    print("STDERR: " .. stderr .. "\n")
  end)
end)
