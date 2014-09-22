FindMetaTable("Player").SetPremium = function(self, set)
	self:SetNetworkedVar("hspremium", set)
end

FindMetaTable("Player").GetPremium = function(self)
	return self:GetNetworkedVar("hspremium")
end