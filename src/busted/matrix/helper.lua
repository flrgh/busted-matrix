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

  for _, arg in ipairs(options.arguments) do
    if arg == "--debug" then
      DEBUG = true

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


  local Matrix = require("busted.matrix")

  local block = require("busted.block")(busted)

  local insert = table.insert
  local fmt = string.format

  local function is_callable(obj)
    return type(obj) == "function"
        or (debug.getmetatable(obj) or {}).__call
        and true
  end

  ---@class busted.matrix.registry.node
  ---
  ---@field value busted.matrix.each|nil
  ---@field children { [string]: busted.matrix.registry.node }
  local registry = {
    value = nil,
    children = {},
  }

  ---@param descriptor string
  ---@param name? string
  ---@return string
  local function key_for(descriptor, name)
    if name then
      return fmt("%s(%s)", descriptor, name)
    else
      return descriptor
    end
  end


  ---@param ns busted.matrix.registry.node
  ---@param descriptor string
  ---@param name? string
  ---@param parent? table
  ---@return busted.matrix.each? value
  local function get(ns, descriptor, name, parent)
    local path = { key_for(descriptor, name) }

    while parent and parent.descriptor ~= "suite" do
      insert(path, key_for(parent.descriptor, parent.name))
      parent = busted.context.parent(parent)
    end

    local node = ns
    for i = #path, 1, -1 do
      node = node.children and node.children[path[i]]
      if not node then
        return
      end
    end

    return node.value
  end


  ---@param ns busted.matrix.registry.node
  ---@param descriptor string
  ---@param name? string
  ---@param parent? table
  ---@param value busted.matrix.each
  local function set(ns, descriptor, name, parent, value)
    local path = { key_for(descriptor, name) }

    while parent and parent.descriptor ~= "suite" do
      insert(path, key_for(parent.descriptor, parent.name))
      parent = busted.context.parent(parent)
    end

    local node = ns
    for i = #path, 1, -1 do
      if not node.children then
        node.children = {}
      end

      if not node.children[path[i]] then
        node.children[path[i]] = {}
      end

      node = node.children[path[i]]
    end

    node.value = value
  end


  ---@param ns busted.matrix.registry.node
  ---@param descriptor string
  ---@param name? string
  ---@param parent? table
  local function delete(ns, descriptor, name, parent)
    local path = {}

    while parent and parent.descriptor ~= "suite" do
      insert(path, key_for(parent.descriptor, parent.name))
      parent = busted.context.parent(parent)
    end

    local node = ns
    for i = #path, 1, -1 do
      if not node.children then
        return
      end

      if not node.children[path[i]] then
        return
      end

      node = node.children[path[i]]
    end

    local key = key_for(descriptor, name)
    if node.children then
      node.children[key] = nil
      if next(node.children) == nil then
        node.children = nil
      end
    end
  end


  local function default_fn()
    error("unreachable")
  end

  busted.register("MATRIX", {
    envmode = "insulate",
    default_fn = default_fn,
  })

  busted.subscribe({ "register", "MATRIX" }, function(name, fn, trace, attrs)
    local m = {
      descriptor = "MATRIX",
      attributes = attrs or {},
      env = {},
      name = name or "MATRIX",
      run = fn,
      trace = trace,
      starttick = nil,
      endtick = nil,
      starttime = nil,
      endtime = nil,
      duration = nil,
    }

    busted.context.attach(m)

    local ctx = busted.context.get()
    ctx.MATRIX = ctx.MATRIX or {}
    insert(ctx.MATRIX, m)

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

    m.env.add = function(elems)
      if type(name) ~= "string" then
        error("cannot call add() from a MATRIX() block with no name")
      end
      env.matrix:add(name, elems)
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

    busted.context.push(m)
    busted.wrap(m.run)
    busted.context.pop()

    return nil, false
  end, { priority = 1 })


  for _, descriptor in ipairs({ "describe", "it" }) do
    busted.subscribe({ "register", descriptor }, function(name, fn, element, attrs)
      local context = busted.context.get()

      if get(registry, descriptor, name, context) then
        printf("register(%s(%s)) => already expanded", descriptor, name)
        return nil, true
      end

      if not context.MATRIX then
        printf("register(%s(%s)) => no MATRIX() blocks", descriptor, name)
        return nil, true
      end

      local matrix = Matrix.new()

      for _, elem in ipairs(context.MATRIX) do
        elem.env.matrix = matrix
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
        set(registry, descriptor, each_name, context, elem)
        busted.publish({ "register", descriptor }, each_name, fn, element, attrs)
      end

      return nil, false
    end, { priority = 1 })


    -- busted event names are inconsistent
    local start_and_end = descriptor == "it"
                          and "test"
                          or descriptor

    busted.subscribe({ start_and_end, "start" }, function(element, parent)
      local each = get(registry, descriptor, element.name, parent)

      element.env = element.env or {}
      if each then
        printf("register(%s(%s)) => found matrix", descriptor, element.name)
        element.env.matrix = each.matrix

        -- TODO: child/parent matrix chains (configurable?)
        if false then
          local parent_matrix = get(registry, parent.descriptor, parent.name,
                                    busted.context.parent(parent))

          if parent_matrix then
            printf("register(%s(%s)) => found parent matrix", descriptor, element.name)
            local mt = getmetatable(each.matrix)
            local new = setmetatable({}, {
              __index = function(_, k)
                if mt.vars[k] then
                  return each.matrix[k]
                end
                return parent_matrix.matrix[k]
              end,
              __newindex = assert(mt.__newindex),
            })
            element.env.matrix = new
          end
        end
      else
        element.env.matrix = nil
      end

      return nil, true
    end, { priority = 1 })


    busted.subscribe({ start_and_end, "end" }, function(element, parent)
      delete(registry, descriptor, element.name, parent)

      if element.env then
        element.env.matrix = nil
      end

      return nil, true
    end, { priority = 1 })
  end

  busted.subscribe({ "file", "end" }, function(file)
    delete(registry, "file", file.name, nil)
    return nil, true
  end, { priority = 1 })

  return true
end
