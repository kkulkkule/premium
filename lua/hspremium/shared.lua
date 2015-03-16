FindMetaTable("Player").SetPremium = function(self, set)
	self:SetNWBool("hspremium", set)
end

FindMetaTable("Player").GetPremium = function(self)
	return self:GetNWBool("hspremium")
end