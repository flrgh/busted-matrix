package = "busted-matrix"
version = "scm-1"
rockspec_format = "3.0"

source = {
  url = "git+ssh://git@github.com/flrgh/busted-matrix.git"
}

description = {
  summary = "Test matrix support for Busted",
  homepage = "https://github.com/flrgh/busted-matrix",
  license = "MIT",
  maintainer = "Michael Martin <flrgh@protonmail.com>"
}

build = {
  type = "builtin",
  modules = {
    ["busted.matrix"] = "src/busted/matrix.lua",
    ["busted.matrix.helper"] = "src/busted/matrix/helper.lua",
  },
}

supported_platforms = { "linux" }

dependencies = {
  "busted >= 2.1.2",
  "luassert >= 1.9.0",
  "lua_cliargs >= 3.0",
}

test_dependencies = {
  "inspect == 3.1.3",
  "luafilesystem == 1.8.0",
  "busted-htest == 1.0.0",
  "penlight == 1.14.0",
}

test = {
  type = "command",
  command = "busted",
}

-- vim: set ft=lua ts=2 sw=2 sts=2 et :
