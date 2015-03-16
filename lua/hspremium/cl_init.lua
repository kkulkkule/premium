Msg("##############################\n")
Msg("## Loading Premium Module   ##\n")
Msg("## shared.lua               ##\n")
include("shared.lua")
Msg("## vgui/hspmainframe.lua    ##\n")
include("vgui/hspmainframe.lua")
Msg("## Complete!                ##\n")
Msg("##############################\n")


HSPremium = HSPremium or {}

-- Chat hook
function HSPremium.ChatHook(pl, text, teamchat, dead)
	if pl ~= LocalPlayer() then
		return
	end
	if !string.Left(text, 1) == "!" then
		return
	end
	text = string.lower(text)
	text = string.sub(text, 2, string.len(text))
	local splited = string.Explode(" ", text)
	local command = splited[1]
	
	if command == "ap" or command == "addpremium" and splited[2] and splited[3] then
		local pin = ""
		local count = table.Count(splited)
		if count > 4 then
			for i = 4, count do
				pin = pin .. splited[i]
			end
		else
			pin = splited[4]
		end
		RunConsoleCommand("hsp_addpremium", "\"" .. splited[2] .. "\"", splited[3], "\"" .. pin .. "\"")
	end
	
	if command == "pr" or command == "premain" then
		if splited[2] then
			RunConsoleCommand("hsp_remain", "\"" .. splited[2] .. "\"")
		else
			RunConsoleCommand("hsp_remain")
		end
	end
	
	if command == "rp" or command == "removepremium" and splited[2] then
		RunConsoleCommand("hsp_removepremium", "\"" .. splited[2] .. "\"")
	end
	
	if command == "ep" or command == "editpremium" and splited[2] and splited[3] then
		RunConsoleCommand("hsp_editpremium", "\"" .. splited[2] .. "\"", splited[3])
	end
	
	if command == "pm" or command == "premiummanagement" then
		RunConsoleCommand("hsp_showmanagewindow")
	end
	
	if command == "cuid" then
		local uid = LocalPlayer():UniqueID()
		local nick = LocalPlayer():Nick()
		chat.AddText(Color(0, 255, 255), "[HSPremium]", Color(255, 255, 255), ": ", Color(255, 255, 0), nick, Color(255, 255, 255), "님의 UID는 ", Color(255, 255, 0), uid, Color(255, 255, 255), "입니다.")
		chat.AddText(Color(255, 0, 255), "Ctrl + V", Color(255, 255, 255), "하여 붙여넣으세요.")
		SetClipboardText(uid)
	end
	
	if command == "reqp" or command == "request" or command == "requestpremium" then
		RunConsoleCommand("hsp_showrequestwindow")
	end
end
hook.Add("OnPlayerChat", "HSPremiumChatHook", HSPremium.ChatHook)

-- Receive broadcasting message
function HSPremium.ReceiveBroadcast(len)
	local nick = net.ReadString()
	local day = net.ReadFloat()
	chat.AddText(Color(0, 255, 255), "[HSPremium]", Color(255, 255, 255), ": ", Color(255, 255, 0), nick, Color(255, 255, 255), "님께서 ", Color(255, 255, 0), tostring(day), Color(255, 255, 255), "일 동안 ", Color(255, 255, 0), "프리미엄 유저", Color(255, 255, 255), "가 되었습니다.")
end
net.Receive("hspremium_broadcast", HSPremium.ReceiveBroadcast)

-- Receive removing message
function HSPremium.ReceiveRemove(len)
	local nick = net.ReadString()
	chat.AddText(Color(255, 255, 0), nick, Color(255, 255, 255), " 님의 프리미엄이 끝났습니다.")
end
net.Receive("hspremium_removed", HSPremium.ReceiveRemove)

-- Receive changed info
function HSPremium.ReceiveChangedInfo(len)
	local nick = net.ReadString()
	local past = net.ReadFloat()
	local time = net.ReadFloat()
	local diff = time / 86400
	
	chat.AddText(Color(255, 255, 0), nick, Color(255, 255, 255), " 님의 프리미엄 기한이 기존 \n",
		Color(0, 255, 255), os.date("%Y-%m-%d %H:%M:%S", past), Color(255, 255, 255), "까지에서 ", 
		Color(0, 255, 255), os.date("%Y-%m-%d %H:%M:%S", past + time), Color(255, 255, 255), "까지로\n",
		Color(255, 255, 0), tostring(diff) .. "일", Color(255, 255, 255), "변했습니다.")
end
net.Receive("hspremium_infochanged", HSPremium.ReceiveChangedInfo)

-- Receive remaining message
function HSPremium.ReceiveRemain(len)
	local ispremium = tobool(net.ReadBit())
	local nick = net.ReadString()
	if !ispremium then
		chat.AddText(Color(255, 255, 0), nick, Color(255, 255, 255), " 님께서는 프리미엄 유저가 아니므로 ", Color(255, 255, 255), "이 명령어를 사용할 수 없습니다.")
		return
	end
	local time = net.ReadFloat()
	local datestr = os.date("%Y-%m-%d %H:%M:%S", time)
	chat.AddText(Color(0, 255, 0), nick, Color(255, 255, 255), "님의 프리미엄 기한은 ", Color(0, 255, 255), datestr, Color(255, 255, 255), "까지입니다.")
	local days = math.ceil((time - os.time()) / 86400)
	chat.AddText(Color(255, 255, 0), days .. "일", Color(255, 255, 255), "남았습니다.")
end
net.Receive("hspremium_remain", HSPremium.ReceiveRemain)

-- Draw premium HUD
function HSPremium.ShowHUD()
	if !HSPremium.IsPremium then
		return
	end
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetAlphaMultiplier(1)
	surface.SetMaterial(Material("hspremium/text"))
	surface.DrawTexturedRect(10, 32, 128, 128)
end
hook.Add("HUDPaint", "HSPremiumShowHUD", HSPremium.ShowHUD)

-- Check premium every 10 seconds
local lastCheck = 0
function HSPremium.CheckPremium()
	if lastCheck + 10 <= CurTime() then
		if LocalPlayer():GetNWBool("hspremium") then
			HSPremium.IsPremium = true
		else
			HSPremium.IsPremium = false
		end
		lastCheck = CurTime()
	end
end
hook.Add("Think", "HSPremiumCheckPremium", HSPremium.CheckPremium)

-- Request server to send premium list
function HSPremium.GetPremiumListFromServer()
	net.Start("hspremium_getlist")
	net.SendToServer()
end

-- When premium list received, allocate it to properties.
HSPremium.PremiumList = {}
function HSPremium.ReceivePremiumListFromServer(len)
	HSPremium.PremiumList = net.ReadTable() or {}
end
net.Receive("hspremium_getlist", HSPremium.ReceivePremiumListFromServer)

-- Premium management window control
HSPremium.WindowShouldShow = true
function HSPremium.ShowManageWindowCommand(pl, cmd, args, full)
	if pl ~= LocalPlayer() then
		return
	end
	if HSPremium.WindowShouldShow then
		HSPremium.GetPremiumListFromServer()
		HSPremium.CreateManageWindow()
		HSPremium.WindowShouldShow = false
	end
end
concommand.Add("hsp_showmanagewindow", HSPremium.ShowManageWindowCommand)

function HSPremium.CloseManageWindowCommand(pl, cmd, args, full)
	if pl ~= LocalPlayer() then
		return
	end
	if !HSPremium.WindowShouldShow then
		HSPremium.CloseManageWindow()
		HSPremium.WindowShouldShow = true
	end
end
concommand.Add("hsp_closemanagewindow", HSPremium.CloseManageWindowCommand)

-- Premium request window control
HSPremium.RequestWindowShouldShow = true
function HSPremium.ShowRequestWindowCommand(pl, cmd, args, full)
	if pl ~= LocalPlayer() then
		return
	end
	if HSPremium.RequestWindowShouldShow then
		HSPremium.CreateRequestWindow()
		HSPremium.RequestWindowShouldShow = false
	end
end
concommand.Add("hsp_showrequestwindow", HSPremium.ShowRequestWindowCommand)

function HSPremium.CloseRequestWindowCommand(pl, cmd, args, full)
	if pl ~= LocalPlayer() then
		return
	end
	if !HSPremium.RequestWindowShouldShow then
		HSPremium.CloseRequestWindow()
		HSPremium.RequestWindowShouldShow = true
	end
end
concommand.Add("hsp_closerequestwindow", HSPremium.CloseRequestWindowCommand)

function HSPremium.CreateManageWindow()
	local frame = vgui.Create("HSP_Mainframe")
	
	frame.AddTBPair = function(self, title, top, enable)
		enable = enable or false
		local label = vgui.Create("DLabel", self)
		label:SetFont("Default")
		label:SetText(title)
		label:SetWide(self:GetContentWide() * 0.2 - 5)
		label:SetContentAlignment(6)
		label:AlignTop(self:MarginTop() + top)
		label:AlignLeft(self.ListBox:GetWide() + self:MarginLeft())
		
		local start = vgui.Create("DTextEntry", self)
		start:SetWide(self:GetContentWide() * 0.3)
		start:AlignRight(5 + self:MarginLeft())
		start:AlignTop(self:MarginTop() + top)
		start:SetEnabled(enable)
		
		return label, start
	end
	
	local listbox = vgui.Create("DListBox", frame)
	local listboxwid = frame:GetContentWide() * 0.5
	listbox:SetSize(listboxwid, frame:GetContentTall())
	listbox:AlignLeft(frame:MarginLeft())
	listbox:AlignTop(frame:MarginTop())
	listbox:SetMultiple(false)
	frame.ListBox = listbox
	
	local label, tb
	label, tb = frame:AddTBPair("START: ", 96)
	frame.TBStart = tb
	label, tb = frame:AddTBPair("END: ", 128, true)
	frame.TBEnd = tb
	label, tb = frame:AddTBPair("PIN: " , 160, true)
	frame.TBPin = tb
	
	local edit = vgui.Create("DButton", frame)
	edit:SetWide(frame:GetContentWide() * 0.4 - frame:MarginLeft() - 10)
	edit:AlignRight(10)
	edit:AlignTop(192 + frame:MarginTop())
	edit:SetText("EDIT")
	edit.DoClick = function(self)
	
	end
	frame.EditBtn = edit
	
	local oldclose = frame.btnClose.DoClick
	frame.btnClose.DoClick = function(self)
		HSPremium.WindowShouldShow = true
		oldclose(self)
	end
	
	local items = {}
	
	timer.Simple(1, function()
		repeat
			for i, v in pairs(HSPremium.PremiumList) do
				local item = {}
				item.start = v.start
				item.endday = v.endday
				item.pin = v.pin
				item.uid = v.uid
				item.nick = v.nick
				item.DoClick = function(self)
					frame.TBStart:SetText(os.date("%Y-%m-%d %H:%M:%S", tonumber(self.start)))
					frame.TBEnd:SetText(os.date("%Y-%m-%d %H:%M:%S", tonumber(self.endday)))
					frame.TBPin:SetText(self.pin)
				end
				table.insert(items, item)
			end
		until #HSPremium.PremiumList >= 1
	
		table.sort(items, function(a, b)
			return tonumber(a.endday) < tonumber(b.endday)
		end)
		
		for _, item in pairs(items) do
			local lst = frame.ListBox:AddItem(string.sub(item.nick, 2, string.len(item.nick)))
			lst.start = item.start
			lst.endday = item.endday
			lst.pin = item.pin
			lst.uid = item.uid
			lst.nick = item.nick
			lst.DoClick = item.DoClick
		end
	end)
	
	-- timer.Simple(1, function()
		-- repeat
			-- for i, v in pairs(HSPremium.PremiumList) do
				-- local item = frame.ListBox:AddItem(string.sub(v.nick, 2, string.len(v.nick)))
				-- item.start = v.start
				-- item.endday = v.endday
				-- item.pin = v.pin
				-- item.uid = v.uid
				-- item.nick = v.nick
				-- item.DoClick = function(self)
					-- frame.TBStart:SetText(os.date("%Y-%m-%d %H:%M:%S", tonumber(self.start)))
					-- frame.TBEnd:SetText(os.date("%Y-%m-%d %H:%M:%S", tonumber(self.endday)))
					-- frame.TBPin:SetText(self.pin)
				-- end
			-- end
		-- until #HSPremium.PremiumList >= 1
	-- end)
	
	frame.EditBtn.DoClick = function(self)
		local item = frame.ListBox:GetSelectedItems()
		if istable(item) then
			item = item[1]
		end
		net.Start("hspremium_updateinfo")
			net.WriteTable({
				uid = item.uid,
				start = item.start,
				endday = frame.TBEnd:GetText(),
				pin = frame.TBPin:GetText(),
				nick = item.nick
			})
		net.SendToServer()
	end
	
	HSPremium.ManageWindow = frame
end

function HSPremium.CloseManageWindow()
	if IsValid(HSPremium.ManageWindow) then
		HSPremium.ManageWindow:Close()
		for i, v in pairs(HSPremium.ManageWindow:GetChildren()) do
			v:Remove()
		end
		HSPremium.ManageWindow:Remove()
	end
end

function HSPremium.CreateRequestWindow()
	local frame = vgui.Create("HSP_Mainframe")
	local tbwidth = 300
	local lbwidth = 50
	
	frame:SetTitle("[KOR]혼살의 프리미엄 신청 모듈")
	frame:SetTall(200)
	frame:SetMinHeight(200)
	
	frame.AddTBPair = function(self, title, top, default)
		local label = vgui.Create("DLabel", frame)
		label:SetText(title)
		label:AlignLeft(frame:GetContentWide() / 2 - tbwidth / 2 - lbwidth / 2)
		label:AlignTop(frame:MarginTop() + top)
		
		local text = vgui.Create("DTextEntry", frame)
		text:AlignLeft(frame:GetContentWide() / 2 - tbwidth / 2)
		text:AlignTop(frame:MarginTop() + top)
		text:SetText(default or "")
		text:SetWide(tbwidth)
		
		return label, text
	end
	
	local label, tb
	label, tb = frame:AddTBPair("UID: ", 32, LocalPlayer():UniqueID())	
	frame.TBUID = tb
	label, tb = frame:AddTBPair("PIN: ", 64)	
	frame.TBPIN = tb
	label, tb = frame:AddTBPair("발행일자: \n(해피머니)", 96)	
	frame.TBDATE = tb
	label:AlignLeft(32)
	label:SizeToContents()
	
	-- local label = vgui.Create("DLabel", frame)
	-- label:SetText("컬쳐랜드: ")
	-- label:AlignTop(96 + frame:MarginTop())
	-- label:AlignLeft(frame:GetContentWide() / 2 - 16 - label:GetWide() / 2)
	
	-- local culture = vgui.Create("DCheckBox", frame)
	-- culture:AlignTop(96 + frame:MarginTop())
	-- culture:AlignLeft(frame:GetContentWide() / 2 + 16)
	-- culture:SetValue(1)
	-- frame.Culture = culture
	
	-- local label = vgui.Create("DLabel", frame)
	-- label:SetText("해피머니: ")
	-- label:AlignTop(128 + frame:MarginTop())
	-- label:AlignLeft(frame:GetContentWide() / 2 - 16 - label:GetWide() / 2)
	
	-- local happy = vgui.Create("DCheckBox", frame)
	-- happy:AlignTop(128 + frame:MarginTop())
	-- happy:AlignLeft(frame:GetContentWide() / 2 + 16)
	-- happy:SetValue(0)
	-- frame.Happy = happy
	
	local button = vgui.Create("DButton", frame)
	button:AlignTop(144 + frame:MarginTop())
	button:SetWide(200)
	button:AlignLeft(frame:GetContentWide() / 2 - button:GetWide() / 2)
	button:SetText("전송")
	button.DoClick = function(self)
		net.Start("hspremium_request")
			net.WriteString(frame.TBUID:GetValue())
			net.WriteString(frame.TBPIN:GetValue())
			net.WriteString(frame.TBDATE:GetValue())
		net.SendToServer()
		HSPremium.RequestWindow:Close()
		HSPremium.RequestWindowShouldShow = true
	end
	local oldclose = frame.btnClose.DoClick
		frame.btnClose.DoClick = function(self)
		HSPremium.RequestWindowShouldShow = true
		oldclose(self)
	end
	HSPremium.RequestWindow = frame
end

function HSPremium.CloseRequestWindow()
	if IsValid(HSPremium.RequestWindow) then
		HSPremium.RequestWindow:Close()
		for i, v in pairs(HSPremium.RequestWindow:GetChildren()) do
			v:Remove()
		end
		HSPremium.RequestWindow:Remove()
	end
end