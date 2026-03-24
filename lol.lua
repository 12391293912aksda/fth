-- Hardcoded known hidden properties per class
-- These are the real default values Roblox uses internally
local hidden_defaults = {
    Fire = {
        size_xml = 5,
        heat_xml = 9,
    },
    Smoke = {
        size_xml = 1,
    },
    Sparkles = {
        size_xml = 1,
    },
}

-- Storage for values set via sethiddenproperty
local hidden_storage = {}

local scriptable_overrides = setmetatable({}, { __mode = "k" })

getgenv().isscriptable = function(instance, property_name)
    -- Check if we have a manual override for this instance+property
    local inst_overrides = scriptable_overrides[instance]
    if inst_overrides and inst_overrides[property_name] ~= nil then
        return inst_overrides[property_name]
    end

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

    -- Store the override so isscriptable() reflects the change
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
        return instance[property_name], false
    end

    -- Check if sethiddenproperty stored a value for this instance
    local inst_storage = hidden_storage[instance]
    if inst_storage and inst_storage[property_name] ~= nil then
        return inst_storage[property_name], true
    end

    -- Fall back to known defaults
    local class_defaults = hidden_defaults[instance.ClassName]
    if class_defaults and class_defaults[property_name] ~= nil then
        return class_defaults[property_name], true
    end

    error("No hidden property value found for " .. property_name, 2)
end

getgenv().sethiddenproperty = function(instance, property_name, value)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string", "arg #2 must be type string")

    local was_hidden = not getgenv().isscriptable(instance, property_name)

    -- Store value in our hidden storage table
    if not hidden_storage[instance] then
        -- Use weak keys so instances can be GC'd
        hidden_storage[instance] = setmetatable({}, { __mode = "v" })
    end
    hidden_storage[instance][property_name] = value

    return was_hidden
end

getgenv().getrunningscripts = function()
    local scripts = {}
    
    for _, instance in ipairs(getinstances()) do
        if instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
            table.insert(scripts, instance)
        end
    end
    
    return scripts
end

local callback_storage = setmetatable({}, { __mode = "k" })

getgenv().getcallbackvalue = function(instance, property_name)
    assert(typeof(instance) == "Instance", "arg #1 must be type Instance")
    assert(type(property_name) == "string", "arg #2 must be type string")

    local inst_storage = callback_storage[instance]
    if inst_storage then
        return inst_storage[property_name]
    end

    return nil
end

-- Hook __newindex on the shared instance metatable
local mt = getrawmetatable(game)
local old_newindex = mt.__newindex

setreadonly(mt, false)

mt.__newindex = function(self, key, value)
    if type(value) == "function" then
        if not callback_storage[self] then
            callback_storage[self] = {}
        end
        callback_storage[self][key] = value
    end
    return old_newindex(self, key, value)
end

setreadonly(mt, true)


getgenv().isexecutorclosure = function(func)
	for _, genv in getgenv() do
		if genv == func then
			return true
		end
	end
	local function check(t)
		local isglobal = false
		for i, v in t do
			if type(v) == "table" then
				check(v)
			end
			if v == func then
				isglobal = true
			end
		end
		return isglobal
	end
	if check(getgenv().getrenv()) then
		return false
	end
	return true
end

getgenv().checkclosure = function(func)
    return isexecutorclosure(func)
end

getgenv().isourclosure = function(func)
    return isexecutorclosure(func)
end
