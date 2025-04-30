rockspec_format = "3.0"
package = "busted-matrix"
version = "scm-1"
source = {
  url = "git+https://github.com/flrgh/busted-matrix",
}
description = {
  summary = "Test matrix support for Busted",
  homepage = "https://github.com/flrgh/busted-matrix",
  license = "MIT",
  issues_url = "https://github.com/flrgh/busted-matrix/issues",
  maintainer = "Michael Martin <flrgh@protonmail.com>",
}
supported_platforms = {
  "linux",
}
dependencies = {
  "lua >= 5.1",
  "busted >= 2.1.2",
  "luassert >= 1.9.0",
  "lua_cliargs >= 3.0",
  "inspect >= 3.0",
}
build = {
  type = "builtin",
  modules = {
    ["busted.matrix"] = "src/busted/matrix.lua",
    ["busted.matrix.helper"] = "src/busted/matrix/helper.lua",
  }
}
test_dependencies = {
  "busted-htest == 1.0.0",
  "penlight == 1.14.0",
}
test = {
  type = "command",
  command = "busted",
}

-- vim: set ft=lua ts=2 sw=2 sts=2 et :
