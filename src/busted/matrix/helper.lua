do
  -- busted versions before 2.1.2 have `--helper` support, but they do not
  -- check for a function return value from the helper file, so they will
  -- fail in the most confusing way possible

  local ok, busted_core = pcall(require, "busted.core")
  if not ok then
    error("failed loading `busted.core`: " .. tostring(busted_core))
  end

  local version = busted_core().version
  if not version then
    error("failed checking busted version: `busted.core().version` is undefined")
  end

  local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)")
  major = tonumber(major)
  minor = tonumber(minor)
  patch = tonumber(patch)
  if not major or not minor or not patch then
    error("failed checking busted version: could not parse '" .. version .. "'")
  end

  if major < 2
    or (major == 2 and minor < 1)
    or (major == 2 and minor == 1 and patch < 2)
  then
    error("busted.matrix requires busted >= 2.1.2 (installed: " .. version .. ")")
  end
end


return function(busted, _, options)
  local print, printf
  local DEBUG
  do
    local env = os.getenv("BUSTED_MATRIX_DEBUG")
    env = env and env:lower() or ""
    DEBUG = env == "yes"
        or env == "1"
        or env == "on"
        or env == "true"
        or env == "enable"
  end

  -- also enable for `busted --verbose`
  if options.verbose then
    DEBUG = true
  end

  for _, arg in ipairs(options.arguments) do
    if arg == "--debug" then
      DEBUG = true

    -- turn off debugging if previously enabled
    elseif arg == "--no-debug" then
      DEBUG = false
    end
  end

  if DEBUG then
    local _print = _G.print
    local fmt = string.format

    local inspect = require("inspect")

    function print(v, opts)
      local t = type(v)
      if t == "string" or t == "number" or t == "boolean" then
        _print(v)
        return
      end
      _print(inspect(v, opts))
    end

    function printf(f, ...)
      print(fmt(f, ...))
    end
  else
    print = function() end
    printf = print
  end


  ---@generic T: table
  ---@param t T|nil
  ---@return T
  local function copy(t)
    local new = {}
    if t then
      for k, v in pairs(t) do
        new[k] = v
      end
    end
    return new
  end


  local Matrix = require("busted.matrix")

  local block = require("busted.block")(busted)

  local insert = table.insert
  local fmt = string.format

  local function is_callable(obj)
    return type(obj) == "function"
        or (debug.getmetatable(obj) or {}).__call
        and true
  end

  local function default_fn()
    error("unreachable")
  end

  busted.register("MATRIX", {
    envmode = "insulate",
    default_fn = default_fn,
  })

  --- this implements the default behavior for `busted.subscribe({ 'register', descriptor })`
  --- while also adding the `env` table ahead of time for the element
  ---
  --- the attributes table is [shallow] copied, so changes can be made to it as needed
  ---
  ---@param descriptor string
  ---@param name? string
  ---@param fn function
  ---@param trace table
  ---@param attributes? table
  ---@return table
  local function attach(descriptor, name, fn, trace, attributes)
    local ctx = busted.context.get()
    local plugin = {
      descriptor = descriptor,
      attributes = copy(attributes),
      env = {},
      name = name,
      run = fn,
      trace = trace,
      starttick = nil,
      endtick = nil,
      starttime = nil,
      endtime = nil,
      duration = nil,
    }

    busted.context.attach(plugin)

    if not ctx[descriptor] then
      ctx[descriptor] = { plugin }
    else
      ctx[descriptor][#ctx[descriptor]+1] = plugin
    end

    return plugin
  end


  ---@param plugin table
  local function wrap_env(plugin)
    busted.context.push(plugin)
    busted.wrap(plugin.run)
    busted.context.pop()
  end


  busted.subscribe({ "register", "MATRIX" }, function(name, fn, trace, attributes)
    local m = attach("MATRIX", name, fn, trace, attributes)
    local env = m.env

    if is_callable(fn) then
      -- MATRIX {
      --   vars = {
      --     a = { 1, 2 },
      --     b = { 3, 4 },
      --   },
      --   include = {
      --     { a = 1, y = 1 },
      --     { b = 2, y = 1 },
      --   },
      --   tags = {
      --     { match = { a = 1 }, tags = "yes" },
      --     { match = { a = 2 }, tags = { "no", "never" } },
      -- }
      if fn == default_fn then
        m.name = "MATRIX"

        local params = name
        params.vars = params.vars or {}
        params.include = params.include or {}
        params.exclude = params.exclude or {}
        params.tags = params.tags or {}

        m.run = function()
          for k, v in pairs(params.vars) do
            env.matrix:add(k, v)
          end

          for _, inc in ipairs(params.include) do
            env.matrix:include(inc)
          end

          for _, exc in ipairs(params.exclude) do
            env.matrix:exclude(exc)
          end

          for _, tag in ipairs(params.tags) do
            env.matrix:tag(tag.match, tag.tags)
          end
        end

      -- MATRIX(function() ... end)
      else
        m.name = m.name or "MATRIX"

        m.run = function()
          fn(env.matrix)
        end
      end

    elseif type(fn) == "table" then
      -- MATRIX("var", { 1, 2, 3 })
      if name then
        local items = fn
        m.run = function()
          env.matrix:add(name, items)
        end
      else
        error("hopefully unreachable")
      end
    else
      error("hopefully unreachable")
    end

    m.env.add = function(var_name, elems)
      if type(var_name) == "table" and not elems then
        elems = var_name
        var_name = m.name
      end

      if type(var_name) ~= "string" then
        error("cannot call add() from a MATRIX() block with no name")
      end
      env.matrix:add(var_name, elems)
    end

    m.env.include = function(elem)
      if elem[1] then
        for _, ielem in ipairs(elem) do
          env.matrix:include(ielem)
        end
      else
        env.matrix:include(elem)
      end
    end

    m.env.exclude = function(elem)
      if elem[1] then
        for _, ielem in ipairs(elem) do
          env.matrix:exclude(ielem)
        end
      else
        env.matrix:exclude(elem)
      end
    end

    m.env.tag = function(match, tag)
      env.matrix:tag(match, tag)
    end

    wrap_env(m)

    return nil, false
  end, { priority = 1 })


  for _, descriptor in ipairs({ "describe", "it" }) do
    busted.subscribe({ "register", descriptor }, function(name, fn, element, attributes)
      local context = busted.context.get()

      if attributes and attributes.matrix then
        printf("register(%s(%s)) => already expanded", descriptor, name)
        return nil, true
      end

      if not context.MATRIX then
        printf("register(%s(%s)) => no MATRIX() blocks", descriptor, name)
        return nil, true
      end

      local matrix = Matrix.new()

      for _, child in ipairs(context.MATRIX) do
        child.env.matrix = matrix
      end

      local ok = block.execAll("MATRIX", context)
      if not ok then
        busted.fail("matrix expansion failed")
      end

      local rendered = matrix:render({ label = true, protect = true })
      if #rendered == 0 then
        printf("register(%s(%s)) => empty matrix", descriptor, name)
        return nil, true
      end

      for _, elem in ipairs(rendered) do
        local each_name = fmt("%s %s", name, elem.label)

        local plugin = attach(descriptor, each_name, fn, element, attributes)
        plugin.env.matrix = elem.matrix
        plugin.attributes.matrix = elem.matrix
        wrap_env(plugin)
      end

      return nil, false
    end, { priority = 1 })


    -- busted event names are inconsistent
    local start_and_end = descriptor == "it"
                          and "test"
                          or descriptor

    busted.subscribe({ start_and_end, "start" }, function(element, parent)
      local matrix = element.attributes and element.attributes.matrix

      element.env = element.env or {}
      if not matrix then
        element.env.matrix = nil
        return nil, true
      end

      if element.env.matrix then
        assert(element.env.matrix == matrix)
      end

      printf("start(%s(%s)) => found matrix", descriptor, element.name)
      element.env.matrix = matrix

      -- TODO: child/parent matrix chains (configurable?)
      if true and false then
        local parent_matrix = parent.attributes
                          and parent.attributes.matrix

        if parent_matrix then
          printf("start(%s(%s)) => found parent matrix", descriptor, element.name)
          local mt = getmetatable(matrix)
          local new = setmetatable({}, {
            __index = function(_, k)
              if mt.vars[k] then
                return matrix[k]
              end
              return parent_matrix.matrix[k]
            end,
            __newindex = assert(mt.__newindex),
          })
          element.env.matrix = new
        end
      end

      return nil, true
    end, { priority = 1 })


    busted.subscribe({ start_and_end, "end" }, function(element, parent)
      if element.attributes then
        element.attributes.matrix = nil
      end

      if element.env then
        element.env.matrix = nil
      end

      return nil, true
    end, { priority = 1 })
  end

  return true
end
