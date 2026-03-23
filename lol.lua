getgenv().setscriptable = function(instance, property_name, scriptable)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string",  "arg #2 must be type string")
    assert(type(scriptable) == "boolean",    "arg #3 must be type boolean")

    -- Capture the PREVIOUS state before changing anything
    local previous = getgenv().isscriptable(instance, property_name)

    if previous ~= scriptable then
        bridge:send("set_scriptable", instance, property_name, scriptable)
    end

    -- Always return the previous state, NOT whether something changed
    return previous
end

getgenv().gethiddenproperty = function(instance, property_name)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string", "arg #2 must be type string")

    local was_hidden = not getgenv().isscriptable(instance, property_name)

    if was_hidden then
        getgenv().setscriptable(instance, property_name, true)
    end

    local ok, result = pcall(function()
        return instance[property_name]
    end)

    if was_hidden then
        getgenv().setscriptable(instance, property_name, false)
    end

    if ok then
        return result, was_hidden   -- value, wasHidden
    else
        error(result, 2)
    end
end

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
        return was_hidden   -- true if property was hidden before
    else
        error(err, 2)
    end
end
