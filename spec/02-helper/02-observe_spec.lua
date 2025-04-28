local exec = require("pl.utils").executeex

local fmt = string.format

describe("integration with busted", function()
  local busted_conf = "spec/fixtures/busted_conf"
  local helper = "src/busted/matrix/helper.lua"

  ---@param args string[]
  ---@return string stdout
  ---@return string stderr
  local function busted_exec(args)
    -- XXX: this is not adequate quoting, be careful

    local cmd = {
      "busted",
      fmt("--config-file=%q", busted_conf),
      fmt("--helper=%q", helper),
    }

    for _, arg in ipairs(args) do
      table.insert(cmd, arg)
    end

    cmd = table.concat(cmd, " ")

    local ok, ec, stdout, stderr = exec(cmd, false)
    local err = fmt("command (%s) failed\nSTDOUT:\n%s\nSTDERR:\n%s\n",
                    cmd, stdout, stderr)

    assert.truthy(ok, err)
    assert.equals(0, ec, err)

    return stdout, stderr
  end

  lazy_setup(function()
  end)

  lazy_teardown(function()
  end)

  it("works", function()
    local stdout, stderr = busted_exec({
      "--output", "TAP",
--      "-Xhelper", "--no-debug",
      "spec/fixtures/test_spec.lua",
    })

    assert.string(stdout)
    print("STDOUT: " .. stdout .. "\n")

    assert.string(stderr)
    print("STDERR: " .. stderr .. "\n")
  end)
end)
