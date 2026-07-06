local _hook = hookfunction
local _hookmeta = hookmetamethod
local _oth_hook = oth and oth.hook or nil
local _oth_unhook = oth and oth.unhook or nil

assert(_hook, "Your executor doesn't support hookfunction")
assert(_hookmeta, "Your executor doesn't support hookmetamethod")

local hook_library = {
    hooks = {},
    paused_hooks = {}
}

function hook_library.add_hook(name, original, custom)
    if not original or not custom then
        return nil
    end
    local old = _hook(original, custom)
    hook_library.hooks[name] = {
        original = original,
        old = old,
        custom = custom
    }
    return old
end

function hook_library.add_metamethod_hook(name, table_obj, method, custom)
    if not table_obj or not method or not custom then
        return nil
    end
    local old = _hookmeta(table_obj, method, custom)
    hook_library.hooks[name] = {
        original = table_obj,
        method = method,
        old = old,
        custom = custom,
        is_meta = true
    }
    return old
end

function hook_library.add_oth_hook(name, original, custom)
    if not _oth_hook or not original or not custom then
        return nil
    end
    local old = _oth_hook(original, custom)
    hook_library.hooks[name] = {
        original = original,
        old = old,
        custom = custom,
        is_oth = true
    }
    return old
end

function hook_library.remove_hook(name)
    local entry = hook_library.hooks[name]
    if not entry then
        return false
    end
    if entry.is_oth then
        _oth_unhook(entry.original)
    elseif entry.is_meta then
        _hookmeta(entry.original, entry.method, entry.old)
    else
        _hook(entry.original, entry.old)
    end
    hook_library.hooks[name] = nil
    hook_library.paused_hooks[name] = nil
    return true
end

function hook_library.pause_hook(name)
    local entry = hook_library.hooks[name]
    if not entry or hook_library.paused_hooks[name] then
        return false
    end
    if entry.is_oth then
        _oth_unhook(entry.original)
    elseif entry.is_meta then
        _hookmeta(entry.original, entry.method, entry.old)
    else
        _hook(entry.original, entry.old)
    end
    hook_library.paused_hooks[name] = entry
    hook_library.hooks[name] = nil
    return true
end

function hook_library.resume_hook(name)
    local entry = hook_library.paused_hooks[name]
    if not entry then
        return false
    end
    local old
    if entry.is_oth then
        old = _oth_hook(entry.original, entry.custom)
    elseif entry.is_meta then
        old = _hookmeta(entry.original, entry.method, entry.custom)
    else
        old = _hook(entry.original, entry.custom)
    end
    entry.old = old
    hook_library.hooks[name] = entry
    hook_library.paused_hooks[name] = nil
    return true
end

function hook_library.clear_all()
    for name, _ in pairs(hook_library.hooks) do
        hook_library.remove_hook(name)
    end
    for name, _ in pairs(hook_library.paused_hooks) do
        hook_library.paused_hooks[name] = nil
    end
end

return hook_library

