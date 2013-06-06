package = "registry"
version = "0.1-1"
source = {
  url = "https://github.com/Tieske/registry/archive/version_0.1.tar.gz",
  dir = "registry-version_0.1"
}
description = {
  summary = "Windows registry access",
  detailed = [[
    Pure Lua access to the regsitry.
  ]],
  homepage = "https://github.com/Tieske/registry",
  license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["registry"] = "src/registry.lua",
  },
}
