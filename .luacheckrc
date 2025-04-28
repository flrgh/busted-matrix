std             = "min"
unused_args     = true
redefined       = true
max_line_length = false

globals = {}
not_globals = {}

ignore = {
    "6.", -- ignore whitespace warnings
}

exclude_files = {}

files["spec/**/*_spec.lua"] = {
    std = "min+busted",
    globals = {
      "MATRIX",
      "matrix",
      "add",
      "include",
      "tag",
    },
}
