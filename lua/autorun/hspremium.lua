if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("hspremium/cl_init.lua")
	AddCSLuaFile("hspremium/shared.lua")
	for _, v in pairs(file.Find("hspremium/vgui/*.lua", "LUA")) do
		AddCSLuaFile("hspremium/vgui/" .. v)
		print(v)
	end
	include("hspremium/init.lua")
else
	include("hspremium/cl_init.lua")
end
	