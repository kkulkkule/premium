Msg("##############################\n")
Msg("## Loading Premium Module   ##\n")
Msg("## shared.lua               ##\n")
include("shared.lua")
-- Msg("## sv_checkpm.lua           ##\n")
-- include("sv_checkpm.lua")
Msg("## Complete!                ##\n")
Msg("##############################\n")

resource.AddFile("materials/hspremium/text.vmt")
resource.AddFile("materials/hspremium/score_icon.vmt")

util.AddNetworkString("hspremium_broadcast")
util.AddNetworkString("hspremium_removed")
util.AddNetworkString("hspremium_infochanged")
util.AddNetworkString("hspremium_remain")
util.AddNetworkString("hspremium_getlist")
util.AddNetworkString("hspremium_updateinfo")
util.AddNetworkString("hspremium_request")

FindMetaTable("Player").SetPremium = function(self, set)
	self:SetNetworkedVar("hspremium", set)
end

FindMetaTable("Player").GetPremium = function(self)
	return self:GetNetworkedVar("hspremium")
end

HSPremium = HSPremium or {}

-- Process when player initialize spawn
function HSPremium.InitializeSpawn(pl)
	if !IsValid(pl) then
		return
	end
	local uid = pl:UniqueID()
	if HSPremium.Valid(uid) then
		pl:SetPremium(true)
	end
	
	local info = HSPremium.ChangedNickInfo(pl)
	
	if info then
		HSPremium.ChangeInfo(uid, info)
	end
end
hook.Add("PlayerInitialSpawn", "HSPremiumInit", HSPremium.InitializeSpawn)

-- Check player's premium is valid
function HSPremium.Valid(uid)
	if !HSPremium.Exists(uid) then
		return false
	end

	local info = HSPremium.GetKeyValue(uid)
	
	local infovalid = HSPremium.ValidInfo(info)
	
	if !infovalid then
		return false
	end
	
	if tonumber(info.endday) <= tonumber(os.time()) then
		local path = HSPremium.GetPath(uid)
		if !path then
			return
		end
		HSPremium.RemovePremium(uid)
		return false
	end
	
	return infovalid
end

-- Get keys and values
function HSPremium.GetKeyValue(uid)
	return HSPremium.GetKeyValueFromFile(HSPremium.GetPath(uid))
end

-- Get keys and values
function HSPremium.GetKeyValueFromFile(path)
	if !file.Exists(path, "DATA") then
		return false
	end
	local f = file.Open(path, "r", "DATA")
	local value = {}
	local str = nil
	local count = 0
	repeat
		str = f:Read(1)
		if str and string.match(str, "%s") == nil then
			local key = {}
			repeat
				key[count + 1] = (key[count + 1] or "") .. (!string.match(str, "%s") and str or "")
				str = f:Read(1)
			until !str or str == ":"
			str = f:Read(1)
			repeat
				value[key[count + 1]] = (value[key[count + 1]] or "") .. (!string.match(str, "[-:]") and str or "")
				str = f:Read(1)
			until !str or string.match(str, "\n") ~= nil
			count = count + 1
		end
	until str == nil
	f:Close()
	
	return value
end

-- Is premium file exists?
function HSPremium.Exists(uid)
	if !file.Exists(HSPremium.GetPath(uid), "DATA") then
		return false
	end
	return true
end

-- Get premium file path
function HSPremium.GetPath(uid)
	if !HSPremium.IsUID(uid) then
		return false
	end
	return "hspremium/" .. uid .. ".txt"
end

-- Is UID?
function HSPremium.IsUID(str)
	return tonumber(str) and string.len(tostring(str)) >= 6 or false
end

-- Is info table valid?
function HSPremium.ValidInfo(info)
	if !istable(info) then
		return false
	end
	if table.Count(info) < 3 then
		return false
	end
	if !(info.nick and info.start and info.endday) then
		return false
	end
	
	return true
end

-- If nick was changed, return current nick
function HSPremium.ChangedNickInfo(pl)
	if !IsValid(pl) then
		return false
	end
	
	local nick = pl:Nick()
	
	local info = HSPremium.GetKeyValue(pl:UniqueID())
	
	if !HSPremium.ValidInfo(info) then
		return false
	end	
	
	if info.nick ~= nick then
		info.nick = nick
		return info
	end
	
	return false
end

-- Change player's premium info
function HSPremium.ChangeInfo(uid, info)
	if !HSPremium.Valid(uid) or !info then
		return
	end
	
	if !HSPremium.ValidInfo(info) then
		return
	end
	
	local f = file.Open(HSPremium.GetPath(uid), "w", "DATA")
	f:Write(
	"nick: " .. info.nick .. "\n" ..
	"start:" .. info.start .. "\n" ..
	"endday:" .. info.endday .. "\n" ..
	"pin:" .. info.pin or ""
	)
	f:Close()
end

-- Set player premium
function HSPremium.SetPremium(uid, time, pin)
	if HSPremium.Valid(uid) or !time or !pin then
		return false
	end
	
	local pl = player.GetByUniqueID(uid)
	if IsValid(pl) then
		pl:SetPremium(true)
	end
	local nick = IsValid(pl) and pl:Nick() or uid
	local today = os.time()
	if !(nick and today and time and pin) then
		return
	end
	local f = file.Open(HSPremium.GetPath(uid), "w", "DATA")
	f:Write(
		"nick: " .. nick .. "\n" ..
		"start: " .. today .. "\n" ..
		"endday: " .. time + os.time() .. "\n" ..
		"pin: " .. pin
	)
	f:Close()
end

function HSPremium.RemovePremium(uid)
	local path = HSPremium.GetPath(uid)
	if file.Exists(path, "DATA") then
		local nick = HSPremium.GetNickByUID(uid)
		local pl = HSPremium.MatchedNickPlayer(nick)
		if IsValid(pl) then
			pl:SetPremium(false)
		end
		file.Delete(path)
		net.Start("hspremium_removed")
			net.WriteString(nick)
		net.Broadcast()
		MsgC(Color(0, 255, 0), nick .. "[" .. uid .. "] is now removed from premium list.\n")
		ulx.logString(nick .. "[" .. uid .. "] is now removed from premium list.\n")
		return true
	end
	return false
end

-- Get start time
function HSPremium.GetStartTime(uid)
	local value = HSPremium.GetKeyValue(uid)
	if !value then
		return false
	end
	return tonumber(value.start)
end

-- Get end time
function HSPremium.GetEndTime(uid)
	local value = HSPremium.GetKeyValue(uid)
	if !value then
		return false
	end
	return tonumber(value.endday)
end

-- Get nickname
function HSPremium.GetNickByUID(uid)
	local value = HSPremium.GetKeyValue(uid)
	if !value then
		return false
	end
	return value.nick
end

function HSPremium.GetUIDFromNick(str)
	local path = "hspremium/"
	local files = file.Find(path .. "*.txt", "DATA")
	str = string.lower(str)
	for i, f in pairs(files) do
		local value = HSPremium.GetKeyValueFromFile(path .. f)
		if value and string.find(string.lower(value.nick), str) then
			return string.sub(f, 1, string.len(f) - 4)
		end
	end
	return false
end

function HSPremium.FixArg(arg)
	return string.lower(string.Replace(arg, "'", ""))
end

function HSPremium.MatchedNickPlayer(str)
	for _, pl in pairs(player.GetAll()) do
		if string.find(string.lower(pl:Nick()), string.lower(str)) or pl:Nick() == str then
			return pl
		end
	end
	return false
end

-- Processed when superadmin send add premium command
function HSPremium.AddPremiumCommand(pl, cmd, args, full)
	if pl ~= NULL and !pl:IsSuperAdmin() then
		return
	end
	if !args[1] or !args[2] or !tonumber(args[2]) or !args[3] then
		return
	end
	
	args[1] = HSPremium.FixArg(args[1])
	args[3] = HSPremium.FixArg(args[3])
	
	local target = NULL
	local isuid = HSPremium.IsUID(args[1])
	
	if !isuid then
		target = HSPremium.MatchedNickPlayer(args[1])
		if IsValid(target) then
			local uid = target:UniqueID()
			HSPremium.SetPremium(uid, args[2] * 60 * 60 * 24, args[3])
			net.Start("hspremium_broadcast")
				net.WriteString(target:Nick())
				net.WriteFloat(args[2])
			net.Broadcast()
		end
	else
		HSPremium.SetPremium(args[1], args[2] * 60 * 60 * 24, args[3])
		net.Start("hspremium_broadcast")
			net.WriteString(HSPremium.GetNickByUID(args[1]))
			net.WriteFloat(args[2])
		net.Broadcast()
	end
	
	if IsValid(target) then
		MsgC(Color(0, 255, 0), target:Nick() .. "[" .. target:UniqueID() .. "] is now premium.\n")
		ulx.logString(target:Nick() .. "[" .. target:UniqueID() .. "] is now premium.\n")
	else
		MsgC(Color(0, 255, 0), HSPremium.GetNickByUID(args[1]) .. " is now premium.\n")
		ulx.logString(HSPremium.GetNickByUID(args[1]) .. " is now premium.\n")
	end
end
concommand.Add("hsp_addpremium", HSPremium.AddPremiumCommand)

-- Processed when superadmin send add premium command
function HSPremium.RemovePremiumCommand(pl, cmd, args, full)
	if pl ~= NULL and !pl:IsSuperAdmin() then
		return
	end
	if !args[1] then
		return
	end
	
	args[1] = HSPremium.FixArg(args[1])
	
	local target = HSPremium.MatchedNickPlayer(args[1])
	local isuid = HSPremium.IsUID(args[1])
	local uid = ""
	
	if !isuid and IsValid(target) then
		uid = target:UniqueID()
	elseif !isuid and !IsValid(target) then
		uid = HSPremium.GetUIDFromNick(args[1])
	elseif isuid then
		uid = args[1]
	else
		return
	end
	
	if !uid then
		return
	end
	
	HSPremium.RemovePremium(uid)
end
concommand.Add("hsp_removepremium", HSPremium.RemovePremiumCommand)

-- Processed when superadmin send add premium command
function HSPremium.EditPremiumCommand(pl, cmd, args, full)
	if pl ~= NULL and !pl:IsSuperAdmin() then
		return
	end
	if !args[1] or !args[2] or !tonumber(args[2]) then
		return
	end
	
	args[1] = HSPremium.FixArg(args[1])
	
	local target = HSPremium.MatchedNickPlayer(args[1])
	local isuid = HSPremium.IsUID(args[1])
	local uid = ""
	local time = tonumber(args[2]) * 86400
	local past = 0
	
	if !isuid and IsValid(target) then
		uid = target:UniqueID()
	elseif !isuid and !IsValid(target) then
		uid = HSPremium.GetUIDFromNick(args[1])
	elseif isuid then
		uid = args[1]
	else
		return
	end
	
	if !uid then
		return
	end
	
	local info = HSPremium.GetKeyValue(uid)
	
	if !HSPremium.ValidInfo(info) then
		return
	end
	
	past = info.endday
	info.endday = tonumber(info.endday) + time
	if tonumber(info.endday) <= tonumber(info.start) then
		return
	end
	HSPremium.ChangeInfo(uid, info)
	
	net.Start("hspremium_infochanged")
		net.WriteString(HSPremium.GetNickByUID(uid))
		net.WriteFloat(past)
		net.WriteFloat(time)
	net.Broadcast()
	MsgC(Color(0, 255, 0), "Premium info changed on uid '" .. uid .. "': " .. past .. " to " .. time .. ".")
	ulx.logString("Premium info changed on uid '" .. uid .. "': " .. past .. " to " .. time .. ".")
end
concommand.Add("hsp_editpremium", HSPremium.EditPremiumCommand)

-- Processed when player send remain command
function HSPremium.RemainCommand(pl, cmd, args, full)
	if !IsValid(pl) then
		return
	end
	
	if pl == NULL then
		print("Console can't execute this command.")
		return
	end
	
	if !pl:IsAdmin() or (pl:IsAdmin() and !args[1]) then	
		local uid = pl:UniqueID()
		
		local ispremium = HSPremium.Valid(uid)
		
		if !ispremium then
			net.Start("hspremium_remain")
				net.WriteBit(ispremium)
				net.WriteString(pl:Nick())
			net.Send(pl)
			return
		end
		net.Start("hspremium_remain")
			net.WriteBit(ispremium)
			net.WriteString(pl:Nick())
			net.WriteFloat(HSPremium.GetEndTime(uid))
		net.Send(pl)	
	elseif pl:IsAdmin() and args[1] then
		args[1] = HSPremium.FixArg(args[1])
		local ispremium = false
		local uid = ""
		if HSPremium.IsUID(args[1]) then
			ispremium = HSPremium.Valid(args[1])
			uid = args[1]
		else
			uid = HSPremium.GetUIDFromNick(args[1])
			if !uid then
				return
			end
			ispremium = HSPremium.Valid(uid)
		end
		
		if !ispremium then
			net.Start("hspremium_remain")
				net.WriteBit(ispremium)
				net.WriteString("해당 UID를 가진")
			net.Send(pl)
			return
		end
		net.Start("hspremium_remain")
			net.WriteBit(ispremium)
			net.WriteString(HSPremium.GetNickByUID(uid))
			net.WriteFloat(HSPremium.GetEndTime(uid))
		net.Send(pl)
	end
end
concommand.Add("hsp_remain", HSPremium.RemainCommand)

function HSPremium.SendPremiumListToClient(len, pl)
	local lst = {}
	local files = file.Find("hspremium/*.txt", "DATA")
	for i, f in pairs(files) do 
		local uid = string.sub(f, 1, string.len(f) - 4)
		if !HSPremium.IsUID(uid) then
			continue
		end
		
		local info = HSPremium.GetKeyValue(uid)
		
		if !HSPremium.ValidInfo(info) then
			continue
		end
		
		table.insert(lst, {
			uid = uid,
			nick = info.nick or "UNKNOWN",
			start = info.start,
			endday = info.endday,
			pin = info.pin or "0"
		})
	end
	net.Start("hspremium_getlist")
		net.WriteTable(lst)
	net.Send(pl)
end
net.Receive("hspremium_getlist", HSPremium.SendPremiumListToClient)

function HSPremium.ReceiveUpdateInfo(len, pl)
	if pl == NULL or !pl:IsSuperAdmin() then
		return
	end
	local info = net.ReadTable()
	
	if !HSPremium.ValidInfo(info) then
		return
	end
	
	if !HSPremium.IsUID(info.uid) then
		return
	end
	
	local endday = info.endday
	
	local dateData = {
		year = tonumber(string.Left(endday, 4)),
		month = tonumber(string.sub(endday, 6, 7)),
		day = tonumber(string.sub(endday, 9, 10)),
		hour = tonumber(string.sub(endday, 12, 13)),
		min = tonumber(string.sub(endday, 15, 16)),
		sec = tonumber(string.sub(endday, 18, 19))
	}
	endday = os.time(dateData)
	info.endday = endday
	
	local info2 = HSPremium.GetKeyValue(info.uid)
	
	if !HSPremium.ValidInfo(info2) then
		return
	end
	
	local time = info2.endday
	
	HSPremium.ChangeInfo(info.uid, info)
	net.Start("hspremium_infochanged")
		net.WriteString(HSPremium.GetNickByUID(info.uid))
		net.WriteFloat(time)
		net.WriteFloat(info.endday - time)
	net.Broadcast()
end
net.Receive("hspremium_updateinfo", HSPremium.ReceiveUpdateInfo)

-- Process client request
function HSPremium.ProcessRequest(len, pl)
	local uid = pl:UniqueID()
	-- if HSPremium.Valid(uid) then
		-- return
	-- end
	local uid = net.ReadString()
	local pin = net.ReadString()
	local date = net.ReadString()
	file.Write("hspremium_requests/" .. os.date("%Y%m%d%H%M%S", os.time()) .. "_" .. uid .. ".txt", "NICK: " .. (pl:Nick() or "UNKNOWN") .. "\nUID: " .. uid .. "\nPIN: " .. pin .. "\nDATE: " .. date)
end
net.Receive("hspremium_request", HSPremium.ProcessRequest)