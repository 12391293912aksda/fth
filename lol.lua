
---

getgenv().getscriptbytecode = function(script)
	assert(typeof(script) == "Instance", "invalid argument #1 to 'getscriptbytecode' (Instance expected, got " .. typeof(script) .. ") ", 2)
	assert(script:IsA("LuaSourceContainer"), "invalid argument #1 to 'getscriptbytecode' (LuaSourceContainer expected, got " .. script.ClassName .. ") ", 2)
	return ""
end
