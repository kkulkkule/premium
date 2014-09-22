local PANEL = {}

local scrw = ScrW()
local scrh = ScrH()

PANEL._MarginLeft = 10
PANEL._MarginTop = 30

function PANEL:Init()
	self:SetTitle("[KOR]혼살의 프리미엄 제어판")
	self:SetSize(512, 384)
	self:SetPos(scrw / 2 - self:GetWide() / 2, scrh / 2 - self:GetTall() / 2)
	self:SetMinWidth(self:GetWide())
	self:SetMinHeight(self:GetTall())
	self:SetDraggable(false)
	
	-- local listbox = vgui.Create("DListBox", self)
	-- local listboxwid = self:GetContentWide() * 0.5
	-- listbox:SetSize(listboxwid, self:GetContentTall())
	-- listbox:AlignLeft(self:MarginLeft())
	-- listbox:AlignTop(self:MarginTop())
	-- listbox:SetMultiple(false)
	-- self.ListBox = listbox
	
	-- local label, tb
	-- label, tb = self:AddTBPair("START: ", 96)
	-- self.TBStart = tb
	-- label, tb = self:AddTBPair("END: ", 128, true)
	-- self.TBEnd = tb
	-- label, tb = self:AddTBPair("PIN: " , 160, true)
	-- self.TBPin = tb
	
	-- local edit = vgui.Create("DButton", self)
	-- edit:SetWide(self:GetContentWide() * 0.4 - self:MarginLeft() - 10)
	-- edit:AlignRight(10)
	-- edit:AlignTop(192 + self:MarginTop())
	-- edit:SetText("EDIT")
	-- edit.DoClick = function()
	
	-- end
	-- self.EditBtn = edit
	
	self:MakePopup()
end

function PANEL:Paint()
	surface.SetDrawColor(255, 255, 255, 80)
	local wid, hei = self:GetSize()
	draw.RoundedBox(8, 0, 0, wid, hei, Color(255, 255, 255, 80))
	local marginleft = self:MarginLeft()
	local margintop = self:MarginTop()
	draw.RoundedBox(4, marginleft, margintop, wid - marginleft * 2, hei - margintop * 2, Color(80, 80, 80, 80))
end

function PANEL:GetContentWide()
	return self:GetWide() - self:MarginLeft() * 2
end

function PANEL:GetContentTall()
	return self:GetTall() - self:MarginTop() * 2
end

function PANEL:GetContentWidth()
	return self:GetContentWide()
end

function PANEL:GetContentHeight()
	return self:GetContentTall()
end

function PANEL:GetContentAreaSize()
	return self:GetContentWide(), self:GetContentTall()
end

function PANEL:MarginLeft()
	return self._MarginLeft
end

function PANEL:MarginTop()
	return self._MarginTop
end

function PANEL:SetMarginLeft(margin)
	self._MarginLeft = margin
end

function PANEL:SetMarginTop(margin)
	self._MarginTop = margin
end

vgui.Register("HSP_Mainframe", PANEL, "DFrame")