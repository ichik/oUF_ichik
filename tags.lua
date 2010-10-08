local addon, ns = ...
local cfg = ns.cfg

local SVal = function(val)
if val then
	if (val >= 1e6) then
        return ("%.1fm"):format(val / 1e6)
	elseif (val >= 1e3) then
		return ("%.1fk"):format(val / 1e3)
	else
		return ("%d"):format(val)
	end
end
end

local function utf8sub(string, i, dots)
	if string then
	local bytes = string:len()
	if bytes <= i then
		return string
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = string:byte(pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if len == i then break end
		end
		if len == i and pos <= bytes then
			return string:sub(1, pos - 1)..(dots and '..' or '')
		else
			return string
		end
	end
	end
end

local function hex(r, g, b)
	if r then
		if (type(r) == 'table') then
			if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
		end
		return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
	end
end

pcolors = setmetatable({
	power = setmetatable({
		['MANA']            = { 95/255, 155/255, 255/255 }, 
		['RAGE']            = { 250/255,  75/255,  60/255 }, 
		['FOCUS']           = { 255/255, 209/255,  71/255 },
		['ENERGY']          = { 200/255, 255/255, 200/255 }, 
		['RUNIC_POWER']     = {   0/255, 209/255, 255/255 },
		["AMMOSLOT"]		= { 200/255, 255/255, 200/255 },
		["FUEL"]			= { 250/255,  75/255,  60/255 },
		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},	
		["POWER_TYPE_HEAT"] = {0.55,0.57,0.61},
      	["POWER_TYPE_OOZE"] = {0.76,1,0},
      	["POWER_TYPE_BLOOD_POWER"] = {0.7,0,1},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

-- [[ Tags, credits to Coree ]]
oUF.Tags['ichikdiff']  = function(u) local l = UnitLevel(u); return Hex(GetQuestDifficultyColor((l > 0) and l or 99)) end
oUF.TagEvents['ichikselect'] = oUF.TagEvents['pvp']
oUF.Tags['ichikselect'] = function(u) local c = colors.reaction[UnitReaction(u, "player")] return Hex(c[1],c[2],c[3]) end
oUF.Tags['ichikcolor'] = function(u)
  return   ((UnitIsFriend("player", "target") and UnitPlayerControlled("target")) or not UnitIsConnected(u)) and oUF.Tags['raidcolor'](u) or
      (not UnitIsFriend("player", "target") and UnitPlayerControlled("target")) and oUF.Tags['ichikselect'](u) or 
      oUF.Tags['ichikdiff'](u)
end
oUF.TagEvents['ichikclassi'] = oUF.TagEvents['classification']
oUF.Tags['ichikclassi'] = function(u)
  local c = UnitClassification(u);
  return c == "rare" and "Rare" or c == "rareelite" and "+ Rare" or c == "elite" and "+" or c == "worldboss" and "Boss" or ""
end
oUF.TagEvents['ichikafk'] = "PLAYER_FLAGS_CHANGED"
oUF.Tags['ichikafk'] = function(u) return UnitIsAFK(u) and "<AFK> " or "" end
oUF.TagEvents['ichikhpp'] = oUF.TagEvents['curhp']
oUF.Tags['ichikhpp'] = function(u)
  return  (not UnitIsConnected(u)) and oUF.Tags['offline'](u) or
      UnitIsDead(u) and "Dead" or
      UnitIsGhost(u) and "Ghost" or oUF.Tags['curhp'](u)
end
oUF.TagEvents['ichikhp'] = "UNIT_HEALTH UNIT_MANA UNIT_RAGE UNIT_ENERGY UNIT_RUNIC_POWER UNIT_MAXMANA UNIT_MAXRAGE UNIT_MAXENERGY UNIT_DISPLAYPOWER UNIT_MAXRUNIC_POWER PLAYER_REGEN_ENABLED PLAYER_REGEN_DISABLED"
oUF.Tags['ichikhp'] = function(u)
  local min, max, ma = UnitHealth(u), UnitHealthMax(u), UnitMana("player")
  local combat = UnitAffectingCombat("player")
  return   (not UnitIsConnected(u) and "Offline") or (UnitIsDead(u) and "Dead") or (UnitIsGhost(u) and "Ghost")
      or (u == "target" and targetshort) and ShortHp(min)
      or (u == "target" and not targetshort) and min
      or (u == "player" and (min~=max or ma > 0 or combat == 1)) and min
      or (u == "player" and ma == 0) and "" or ""
end
oUF.TagEvents['ichikhp2'] = oUF.TagEvents['perpp']
oUF.Tags['ichikhp2'] = function(u)
  local min, max = UnitHealth(u), UnitHealthMax(u)
  local d = floor(min/max*100)
  return   (not UnitIsConnected(u) or UnitIsDead(u) or UnitIsGhost(u)) and ""
      or (d < 100 ) and d.."%"
      or ""
end
oUF.TagEvents['ichikpp'] = oUF.TagEvents['curpp']
oUF.Tags['ichikpp'] = function(u)
  local min = UnitMana(u)
  local _, ptype = UnitPowerType(u)
  local color = colors.power[ptype]
  return   (not UnitIsPlayer(u) or not UnitIsConnected(u) or UnitIsDeadOrGhost(u) or min == 0) and "" 
      or format(min .. "|cff%02x%02x%02x .|r", color[1]*255, color[2]*255, color[3]*255)
end

oUF.TagEvents['ichiknamev'] = oUF.TagEvents['name']
oUF.Tags['ichiknamev'] = function(u, r, realUnit)
  return UnitName(realUnit or u or r)
end