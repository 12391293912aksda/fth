-- Store overrides: [instance][property] = { value, scriptable }
local scriptable_overrides = {}

getgenv().isscriptable = function(instance, property_name)
    local ok, result = xpcall(
        instance.GetPropertyChangedSignal,
        function(err) return err end,
        instance,
        property_name
    )
    return ok or not string.find(result, "scriptable", nil, true)
end

getgenv().setscriptable = function(instance, property_name, scriptable)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string",  "arg #2 must be type string")
    assert(type(scriptable) == "boolean",    "arg #3 must be type boolean")

    local previous = getgenv().isscriptable(instance, property_name)

    -- Track overrides per instance
    if not scriptable_overrides[instance] then
        scriptable_overrides[instance] = {}
    end
    scriptable_overrides[instance][property_name] = scriptable

    return previous
end

getgenv().gethiddenproperty = function(instance, property_name)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string", "arg #2 must be type string")

    local was_hidden = not getgenv().isscriptable(instance, property_name)

    if not was_hidden then
        -- Already scriptable, read normally
        return instance[property_name], false
    end

    -- Use getrawmetatable to bypass scriptable restriction
    local mt = getrawmetatable(instance)
    local old_index = mt.__index
    local old_newindex = mt.__newindex
    local result

    -- Temporarily replace __index to intercept property read
    setrawmetatable(instance, {
        __index = function(self, key)
            if key == property_name then
                -- Call original __index which has access to hidden props at identity 6+
                local ok, val = pcall(old_index, self, key)
                if ok then
                    result = val
                end
                return val
            end
            return old_index(self, key)
        end,
        __newindex = old_newindex,
        __metatable = getrawmetatable(instance).__metatable
    })

    local ok, val = pcall(function()
        return old_index(instance, property_name)
    end)

    -- Restore original metatable
    setrawmetatable(instance, mt)

    if ok then
        return val, true
    else
        error(val, 2)
    end
end

getgenv().sethiddenproperty = function(instance, property_name, value)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string", "arg #2 must be type string")

    local was_hidden = not getgenv().isscriptable(instance, property_name)

    local mt = getrawmetatable(instance)
    local old_newindex = mt.__newindex

    local ok, err = pcall(old_newindex, instance, property_name, value)

    if ok then
        return was_hidden
    else
        error(err, 2)
    end
end
