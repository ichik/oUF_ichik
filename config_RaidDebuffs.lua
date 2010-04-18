--[[================================================
	
	Instructions for Setting up oUF_RaidDebuffs
	
===================================================]]

--[[
	Settings and debuff data
	
	You can put these in your layout file, or keep it saparated
]]


local _, ns = ...
local ORD = ns.oUF_RaidDebuffs or oUF_RaidDebuffs

if not ORD then return end


ORD.ShowDispelableDebuff = true
ORD.FilterDispellableDebuff = true
ORD.MatchBySpellName = false -- false: matching by spellID
ORD.SHAMAN_CAN_DECURSE = true


local debuff_data = {
  69065, -- Impaled (Lord Marrowgar)
  71829, -- Dominate Mind (Lady Deathwhisper)
  72446, 72444, 72293, 72445, 72256, 72255, -- Mark of the Fallen Champion (Deathbringer Saurfang)
  72385, 72442, -- Boiling Blood (Deathbringer Saurfang)
  70867, -- Bite (Blood-Queen Lana'thel)
  70126, -- Frost Beacon (Sindragosa)
  68980, 74325, 74327, 74326, 68980, -- Harvest Soul (Arthas)
}  

ORD:RegisterDebuffs(debuff_data)

--[[
	Extra stuff
	
	Load debuff data depanding on the zone


local debuff_data = {
	['some place'] = {
		123, 12345
	},
	['other place'] = {
		54321, 321
	}
}

local f = CreateFrame'Frame'
f:SetScript('OnEvent', function(self, event, ...)
	self[event](self, event, ...)
end)


f:RegisterEvent('PLAYER_ENTERING_WORLD')
function f:PLAYER_ENTERING_WORLD()
	ORD:ResetDebuffData()
	
	local zone = GetRealZoneText()
	local zone_data = debuff_data[zone]
	if zone_data then
		ORD:RegisterDebuffs(zone_data)
	end
end]]

