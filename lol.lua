-- setscriptable: returns false if property is ALREADY in target state, true if changed
getgenv().setscriptable = function(instance, property_name, scriptable)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string",  "arg #2 must be type string")
    assert(type(scriptable) == "boolean",    "arg #3 must be type boolean")

    local currently_scriptable = getgenv().isscriptable(instance, property_name)

    -- Already in desired state — return false (nothing changed)
    if currently_scriptable == scriptable then
        return false
    end

    -- Actually toggle scriptability via bridge
    return bridge:send("set_scriptable", instance, property_name, scriptable)
end

-- gethiddenproperty: returns value, was_hidden
getgenv().gethiddenproperty = function(instance, property_name)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string", "arg #2 must be type string")

    local was_hidden = not getgenv().isscriptable(instance, property_name)

    if not was_hidden then
        -- Already scriptable, read directly
        return instance[property_name], false
    end

    -- Temporarily make scriptable to read value
    getgenv().setscriptable(instance, property_name, true)

    local ok, result = pcall(function()
        return instance[property_name]
    end)

    -- Restore hidden state
    getgenv().setscriptable(instance, property_name, false)

    if ok then
        return result, true
    else
        error(result, 2)
    end
end

-- sethiddenproperty: sets value, returns was_hidden
getgenv().sethiddenproperty = function(instance, property_name, value)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string", "arg #2 must be type string")

    local was_hidden = not getgenv().isscriptable(instance, property_name)

    if was_hidden then
        getgenv().setscriptable(instance, property_name, true)
    end

    local ok, err = pcall(function()
        instance[property_name] = value
    end)

    if was_hidden then
        getgenv().setscriptable(instance, property_name, false)
    end

    if ok then
        return was_hidden
    else
        error(err, 2)
    end
end
