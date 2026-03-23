getgenv().getsenv = function(script_instance)
    local env = getfenv(debug.info(2, 'f'))
	return setmetatable({
		script = script_instance,
	}, {
		__index = function(self, index)
			return env[index] or rawget(self, index)
		end,
		__newindex = function(self, index, value)
			xpcall(function()
				env[index] = value
			end, function()
				rawset(self, index, value)
			end)
		end,
	})
end
---

getgenv().getscriptbytecode = function(script)
	assert(typeof(script) == "Instance", "invalid argument #1 to 'getscriptbytecode' (Instance expected, got " .. typeof(script) .. ") ", 2)
	assert(script:IsA("LuaSourceContainer"), "invalid argument #1 to 'getscriptbytecode' (LuaSourceContainer expected, got " .. script.ClassName .. ") ", 2)
	return ""
end
