local _, class = UnitClass("player")
local texture = [=[Interface\AddOns\oUF_ichik\media\minimalist]=]
local debufftex = [=[Interface\AddOns\oUF_ichik\media\dh]=]
local border = [=[Interface\AddOns\oUF_ichik\media\border]=]
local fontn = "Fonts\\ARIALN.ttf"
local fontb = "Interface\\AddOns\\oUF_ichik\\media\\calibri.ttf"
local backdrop = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
  edgeFile = "", edgeSize = 16,
  insets = {left = -1, right = -1, top = -1, bottom = -1},
}

local width, height = 216, 20
local targetshort = false -- true = short hpvalue for target
local cbar = true -- true = oUF castbar 
local cbarsafe = true -- true = latency zone for the castbar
local partyraid = true -- true = show party in raid
local ppets = true -- true = show party pets
local inCombat = false -- true = show icon when entering combat

--[[ Disabling default buff frames ]]
_G["BuffFrame"]:Hide()
_G["BuffFrame"]:UnregisterAllEvents()
_G["BuffFrame"]:SetScript("OnUpdate", nil)

local colors = setmetatable({
  power = setmetatable({
    ["MANA"] = {0, 144/255, 1},
    ["AMMOSLOT"] = {0.8, 0.6, 0},
    ["FUEL"] = {0, 0.55, 0.5},
    ["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
    ["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
  }, {__index = oUF.colors.power}),
  reaction = setmetatable({  
    [1] = {1, 0, 0},
    [2] = {1, 0, 0},
    [3] = {0.75, 0.27,0},
    [4] = {1.0, 0.96, 0},
    [5] = {0, 1, 0.1},
    [6] = {0, 1, 0.1},
    [7] = {0, 1, 0.1},
    [8] = {0, 1, 0.1},
    }, {__index = oUF.colors.reaction}),
  runes = setmetatable({
    [1] = {0.8, 0, 0},
    [3] = {0, 0.4, 0.7},
    [4] = {0.8, 0.8, 0.8}
  }, {__index = oUF.colors.runes})
}, {__index = oUF.colors})

local function Hex(r, g, b)
  if type(r) == "table" then
    if r.r then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
  end
  return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

-- [[ Tags, credits to Coree ]]
oUF.Tags["[ichikdiff]"]  = function(u) local l = UnitLevel(u); return Hex(GetQuestDifficultyColor((l > 0) and l or 99)) end
oUF.TagEvents["[ichikselect]"] = oUF.TagEvents["[pvp]"]
oUF.Tags["[ichikselect]"] = function(u) local c = colors.reaction[UnitReaction(u, "player")] return Hex(c[1],c[2],c[3]) end
oUF.Tags["[ichikcolor]"] = function(u)
  return   ((UnitIsFriend("player", "target") and UnitPlayerControlled("target")) or not UnitIsConnected(u)) and oUF.Tags["[raidcolor]"](u) or
      (not UnitIsFriend("player", "target") and UnitPlayerControlled("target")) and oUF.Tags["[ichikselect]"](u) or 
      oUF.Tags["[ichikdiff]"](u)
end
oUF.TagEvents["[ichikclassi]"] = oUF.TagEvents["[classification]"]
oUF.Tags["[ichikclassi]"] = function(u)
  local c = UnitClassification(u);
  return c == "rare" and "Rare" or c == "rareelite" and "+ Rare" or c == "elite" and "+" or c == "worldboss" and "Boss" or ""
end
oUF.TagEvents["[ichikafk]"] = "PLAYER_FLAGS_CHANGED"
oUF.Tags["[ichikafk]"] = function(u) return UnitIsAFK(u) and "<AFK> " or "" end
oUF.TagEvents["[ichikhpp]"] = oUF.TagEvents["[curhp]"]
oUF.Tags["[ichikhpp]"] = function(u)
  return  (not UnitIsConnected(u)) and oUF.Tags["[offline]"](u) or
      UnitIsDead(u) and "Dead" or
      UnitIsGhost(u) and "Ghost" or oUF.Tags["[curhp]"](u)
end
oUF.TagEvents["[ichikhp]"] = "UNIT_HEALTH UNIT_MANA UNIT_RAGE UNIT_ENERGY UNIT_RUNIC_POWER UNIT_MAXMANA UNIT_MAXRAGE UNIT_MAXENERGY UNIT_DISPLAYPOWER UNIT_MAXRUNIC_POWER PLAYER_REGEN_ENABLED PLAYER_REGEN_DISABLED"
oUF.Tags["[ichikhp]"] = function(u)
  local min, max, ma = UnitHealth(u), UnitHealthMax(u), UnitMana("player")
  local combat = UnitAffectingCombat("player")
  return   (not UnitIsConnected(u) and "Offline") or (UnitIsDead(u) and "Dead") or (UnitIsGhost(u) and "Ghost")
      or (u == "target" and targetshort) and ShortHp(min)
      or (u == "target" and not targetshort) and min
      or (u == "player" and (min~=max or ma > 0 or combat == 1)) and min
      or (u == "player" and ma == 0) and "" or ""
end
oUF.TagEvents["[ichikhp2]"] = oUF.TagEvents["[perpp]"]
oUF.Tags["[ichikhp2]"] = function(u)
  local min, max = UnitHealth(u), UnitHealthMax(u)
  local d = floor(min/max*100)
  return   (not UnitIsConnected(u) or UnitIsDead(u) or UnitIsGhost(u)) and ""
      or (d < 100 ) and d.."%"
      or ""
end
oUF.TagEvents["[ichikpp]"] = oUF.TagEvents["[curpp]"]
oUF.Tags["[ichikpp]"] = function(u)
  local min = UnitMana(u)
  local _, ptype = UnitPowerType(u)
  local color = colors.power[ptype]
  return   (not UnitIsPlayer(u) or not UnitIsConnected(u) or UnitIsDeadOrGhost(u) or min == 0) and "" 
      or format(min .. "|cff%02x%02x%02x .|r", color[1]*255, color[2]*255, color[3]*255)
end

oUF.TagEvents["[ichiknamev]"] = oUF.TagEvents["[name]"]
oUF.Tags["[ichiknamev]"] = function(u, r, realUnit)
  return UnitName(realUnit or u or r)
end

local function menu(self)
  local unit = string.gsub(self.unit, "(.)", string.upper, 1)
  if(_G[unit.."FrameDropDown"]) then
    ToggleDropDownMenu(1, nil, _G[unit.."FrameDropDown"], "cursor")
  end
end

local function ShortHp(value)
  if(value >= 1e6) then
    return string.format("%.1fm", value / 1e6)
  elseif(value >= 1e4) then
    return string.format("%.1fk", value / 1e3)
  else
    return value
  end
end

local function SetFontString(parent, fontName, fontHeight, fontStyle)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(fontName, fontHeight, fontStyle)
  fs:SetJustifyH("LEFT")
  fs:SetShadowColor(0,0,0)
  fs:SetShadowOffset(1, -1)
  return fs
end

local function updateRIcon(self, event)
  local index = GetRaidTargetIndex(self.unit)
  if(index) then
    self.RIcon:SetText(ICON_LIST[index].."22|t")
  else
    self.RIcon:SetText()
  end
end

local function playerVehicle(self, event, unit)
  if self.unit ~= unit then return end
  if event == "UNIT_ENTERED_VEHICLE" then
    self.Info:Show()
  elseif event == "UNIT_EXITED_VEHICLE" then
    self.Info:Hide()
  end
end

oUF.TagEvents['[druidpower]'] = 'UNIT_MANA UPDATE_SHAPESHIFT_FORM'
oUF.Tags['[druidpower]'] = function(unit)
  local min, max = UnitPower(unit, 0), UnitPowerMax(unit, 0)
  return UnitPowerType(unit) ~= 0 and format('|cff0090ff%d - %d%%|r', min, math.floor(min / max * 100))
end

local function updateDruidPower(self, event, unit)
  if(unit and unit ~= self.unit) then return end
  local bar = self.DruidPower

  local mana = UnitPowerType('player') == 0
  local min, max = UnitPower('player', mana and 3 or 0), UnitPowerMax('player', mana and 3 or 0)

  bar:SetStatusBarColor(unpack(colors.power[mana and 'ENERGY' or 'MANA']))
  bar:SetMinMaxValues(0, max)
  bar:SetValue(min)
  bar:SetAlpha(min ~= max and 1 or 0)
end

local function castbarTime(self, duration)
  if(self.channeling) then
    self.Time:SetFormattedText('%.1f ', duration)
  elseif(self.casting) then
    self.Time:SetFormattedText('%.1f ', self.max - duration)
  end
end

--[[ Castbar styling  !!!!!!!!made by ALZA!!!!!!!!!!!!]]
local FormatCastbarTime = function(self, duration)
	if self.channeling then
		self.Time:SetFormattedText("%.1f ", duration)
	elseif self.casting then
		self.Time:SetFormattedText("%.1f / %.1f", duration, self.max)
	end
end

local sentTime = 0
local lagTime = 0

local UNIT_SPELLCAST_SENT = function (self, event, unit, spell, spellrank)
    if(self.unit~=unit) then return end
    sentTime = GetTime()
end

local PostCastStart = function(self, event, unit, name, rank, text, castid)
    lagTime = GetTime() - sentTime
end

local PostChannelStart = function(self, event, unit, name, rank, text)
    lagTime = GetTime() - sentTime
end

local OnCastbarUpdate = function(self, elapsed)
    if(self.casting) then
        local duration = self.duration + elapsed
        if(duration>=self.max) then
            self.casting = nil
            self:Hide()
            return
        end

        local width = self:GetWidth()
        local safeZonePercent = lagTime / self.max
        if(safeZonePercent>1) then safeZonePercent=1 end
        self.SafeZone:SetWidth(width * safeZonePercent)

        if(self.delay~=0) then
            self.Time:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, self.delay)
        else
            self.Time:SetFormattedText("%.1f / %.1f", duration, self.max)
            self.Lag:SetFormattedText("%d ms", lagTime * 1000)
        end

        self.duration = duration
        self:SetValue(duration)
		
    elseif(self.channeling) then
        local duration = self.duration - elapsed

        if(duration<=0) then
            self.channeling = nil
            self:Hide()
            return
        end

        if(lagTime > 1e5) then
            lagTime = 0
            self.SafeZone:SetWidth(0)
        else
            local width = self:GetWidth()
            local safeZonePercent = lagTime / self.max
            if(safeZonePercent > 1 or safeZonePercent<=0) then safeZonePercent = 1 end
            self.SafeZone:SetWidth(width * safeZonePercent)
        end

        if(self.delay~=0) then
            self.Time:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, self.delay)
        else
            self.Time:SetFormattedText("%.1f / %.1f", duration, self.max)
            self.Lag:SetFormattedText( "%d ms ", lagTime * 1000 )
        end

        self.duration = duration
        self:SetValue(duration)
		
    else
        self.unitName = nil
        self.channeling = nil
        self:SetValue(1)
        self:Hide()
    end
end

------ [Time operations for auras]
local FormatTime = function(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return format("%dd", floor(s/day + 0.5)), s % day
	elseif s >= hour then
		return format("%dh", floor(s/hour + 0.5)), s % hour
	elseif s >= minute then
		if s <= minute * 5 then
			return format('%d:%02d', floor(s/60), s % minute), s - floor(s)
		end
		return format("%dm", floor(s/minute + 0.5)), s % minute
	elseif s >= minute / 12 then
		return floor(s + 0.5), (s * 100 - floor(s * 100))/100
	end
	return format("%.1f", s), (s * 100 - floor(s * 100))/100
end

------ [Create aura timer, credits to Monolit]
local CreateAuraTimer = function(self,elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed >= 0.1 then
		if not self.first then
			self.timeLeft = self.timeLeft - self.elapsed
		else
			self.timeLeft = self.timeLeft - GetTime()
			self.first = false
		end
		if self.timeLeft > 0 then
			local time = FormatTime(self.timeLeft)
			self.time:SetText(time)
			if self.timeLeft < 5 then
				self.time:SetTextColor(1, 0, 0)
			else
				self.time:SetTextColor(0.8, 0.8, 0.8)
			end
			else
				self.time:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
end

local CreateEnchantTimer = function(self, icons)
	for i = 1, 2 do
		local icon = icons[i]
		if icon.expTime then
			icon.timeLeft = icon.expTime - GetTime()
			icon.time:Show()
		else
			icon.time:Hide()
		end
		icon:SetScript("OnUpdate", CreateAuraTimer)
	end
end

local function createAura(self, icon, icons, index, debuff)
	icon.cd.noOCC = true
	icon.cd.noCooldownCount = true
	icons.disableCooldown = true
	
	icon.count:SetFont(fontb, 14, 'THINOUTLINE')
	icon.count:SetPoint("BOTTOMRIGHT", icon, 2, -2)
	icon.count:SetTextColor(0.8, 0.8, 0.8)
	
	icon.time = icon:CreateFontString(nil, 'OVERLAY')
	icon.time:SetFont(fontb, 14, 'THINOUTLINE')
	icon.time:SetPoint('BOTTOM', icon, 'TOP', 0, -8)
	icon.time:SetJustifyH('CENTER')
	icon.time:SetVertexColor(1.0,1.0,1.0)
		
	icons.showDebuffType = true
  
	icon.icon:SetTexCoord(0.03, 0.97, 0.03, 0.97)
	
	icon.overlay:SetTexture(border)
	icon.overlay:SetTexCoord(0.03, 0.97, 0.03, 0.97)
	icon.overlay.Hide = function(self) self:SetVertexColor(0.3, 0.3, 0.3) end
end

local function updateAura(self, icons, unit, icon, index, offset, filter, isDebuff, duration, timeLeft)
	local _, _, _, _, _, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)
	if unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle" then
		if icon.debuff then
				icon.icon:SetDesaturated(false)
			end
	else
		if UnitIsEnemy("player", unit) then
			if icon.debuff then
				icon.icon:SetDesaturated(true)
			end
		end
	end

	if duration and duration > 0 then
		icon.time:Show()
		icon.timeLeft = expirationTime
		icon:SetScript("OnUpdate", CreateAuraTimer)
	else
		icon.time:Hide()
		icon.timeLeft = math.huge
		icon:SetScript('OnUpdate', nil)
	end

	icon.first = true
end

local sort = function(a, b)
       return a.timeLeft > b.timeLeft
end
 
local preAuraSetPosition = function(self, icon, max)
	table.sort(icon, function(a,b) return a.timeLeft > b.timeLeft end)
end

local function styleFunc(self, unit)
  self.colors = colors
  self.menu = menu
  self:RegisterForClicks("AnyUp")
  self:SetAttribute("type2", "menu")
  self:SetScript("OnEnter", UnitFrame_OnEnter)
  self:SetScript("OnLeave", UnitFrame_OnLeave)

  self:SetBackdrop(backdrop)
  self:SetBackdropColor(0, 0, 0, 1)
  self:SetBackdropBorderColor(1, 1, 1, 1)

  self.Health = CreateFrame("StatusBar", nil, self)
  self.Health:SetPoint("TOPRIGHT", self)
  self.Health:SetPoint("TOPLEFT", self)
  self.Health:SetHeight(height - 4)
  self.Health:SetStatusBarTexture(texture)

  self.Health.Text = SetFontString(self.Health, fontn, 14, "THINOUTLINE")
  self.Health.Text:SetPoint("RIGHT", 0, -23)
  self.Health.Text:SetJustifyH("RIGHT")
  self.Health.Text.frequentUpdates = 0.1
  if self:GetParent():GetName():match'oUF_Party' then
    self:Tag(self.Health.Text, "[ichikhpp]")
  elseif (unit == "player" or unit == "target") then
    self:Tag(self.Health.Text, "[ichikhp]")
  end
  
  self.Health.Text2 = SetFontString(self.Health, fontn, (unit == "player" or unit == "target") and 20 or 14, "THINOUTLINE")
  self.Health.Text2.frequentUpdates = 0.1
  if(unit == "player") then
    self.Health.Text2:SetPoint("RIGHT", 40, -1)
  elseif(unit == "target") then
    self.Health.Text2:SetPoint("LEFT", -38, -1)
  elseif(unit == "targettarget" or unit == "pet") then
    self.Health.Text2:SetPoint("RIGHT", 0, -23)
  elseif(unit and unit:match("boss%d")) then
    self.Health.Text2:SetPoint("RIGHT",self.Health, 30, 1)  
  elseif(unit == "focus" or unit == "pet") then
    self.Health.Text2:SetPoint("LEFT",self.Health, -30, -1)
  else
    self.Health.Text2:SetPoint("LEFT",self.Health, -30, 0)
  end
  self:Tag(self.Health.Text2, "[ichikhp2]")

  self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
  self.Health.bg:SetAllPoints(self.Health)
  self.Health.bg:SetTexture(texture)
  self.Health.bg.multiplier = 0.3
  
  self.Health.colorTapping = true
  self.Health.colorDisconnected = true
  self.Health.colorClass = true
  self.Health.colorReaction = true
  
  self.Health.frequentUpdates = true
  self.Health.Smooth = true  

  self.Power = CreateFrame("StatusBar", nil, self)
  self.Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, -1)
  self.Power:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -1)
  self.Power:SetStatusBarTexture(texture)
  self.Power:SetHeight(3)

  self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
  self.Power.bg:SetAllPoints(self.Power)
  self.Power.bg:SetTexture(texture)
  self.Power.bg.multiplier = 0.3
  
  if (unit == "player" or unit == "target") then
    self.Power.Text = SetFontString(self.Health, fontn, 14, "THINOUTLINE")
    self.Power.Text:SetPoint("RIGHT", self.Health.Text, "LEFT")
    self.Power.Text.frequentUpdates = 0.1
    self:Tag(self.Power.Text, "[ichikpp]")
  end
  
  self.Power.colorPower = true
  
  self.Power.frequentUpdates = true
  self.Power.Smooth = true

  local ricon = self.Health:CreateFontString(nil, "OVERLAY")
  ricon:SetPoint("TOP", self, 0, 8)
  ricon:SetJustifyH"LEFT"
  ricon:SetFontObject(GameFontNormalSmall)
  ricon:SetTextColor(1, 1, 1)
  self.RIcon = ricon
  self:RegisterEvent("RAID_TARGET_UPDATE", updateRIcon)
  table.insert(self.__elements, updateRIcon)    

  self.Info = SetFontString(self.Health, fontn, 14, "THINOUTLINE")
  self.Info:SetPoint("LEFT", self.Health, 1, -23)
  if(unit == "player") then
	self.Info:Hide()
	self:RegisterEvent("UNIT_ENTERED_VEHICLE", playerVehicle)
	self:RegisterEvent("UNIT_EXITED_VEHICLE", playerVehicle)		  
  elseif(unit == "targettarget" or unit == "pet") then    
    self.Info:SetPoint("RIGHT", self.Health.Text2, "LEFT")
  elseif(unit == "focus" or unit == "focustarget" or (unit and unit:match("boss%d"))) then    
    self.Info:SetPoint("LEFT", self.Health, 3, 0)
    self.Info:SetPoint("RIGHT", self.Health)
  elseif(self:GetParent():GetName():match'oUF_Party') then
    self.Info:SetPoint("LEFT", self.Health, 0, -23)
    self.Info:SetPoint("RIGHT", self.Health.Text, "LEFT")
  else  
    self.Info:SetPoint("RIGHT", self.Power.Text, "LEFT")
  end
  self:Tag(self.Info, unit == "target" and "[ichikcolor][level][ichikclassi] |cFFFFFFFF[name]|r" or self:GetParent():GetName():match'oUF_Party' and "[ichikafk]|cFFFFFFFF[name]|r" or "|cFFFFFFFF[ichiknamev]|r")
    
  if(cbar == true and (unit == "player" or unit == "target" or unit == "focus" or unit == "pet")) then
    do
      local cb = CreateFrame("StatusBar", nil, self)
      cb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -21)
      cb:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -21)
      if (unit == "focus") then    
        cb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -12)
		cb:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -12)
      end
      cb:SetStatusBarTexture(texture, "OVERLAY")
      cb:SetStatusBarColor(0.2705882352941176, 0.407843137254902, 0.5450980392156862)
      cb:SetBackdrop(backdrop)
      cb:SetBackdropColor(0, 0, 0)
      cb:SetHeight(15)
      cb:SetWidth(300)
      cb:SetMinMaxValues(1, 100)
      cb:SetValue(1)
      cb:Hide()
      self.Castbar = cb  
    
      local cbbg = cb:CreateTexture(nil, "BORDER")
      cbbg:SetAllPoints(cb)
      cbbg:SetTexture(0.3, 0.3, 0.3)
      cb.bg = cbbg    

      local cbtime = SetFontString(cb, fontn, 14, "THINOUTLINE")
      cbtime:SetPoint("RIGHT", cb, -3, 1)
      cbtime:SetJustifyH("RIGHT")
      cb.CustomTimeText = OverrideCastbarTime
      cb.Time = cbtime

      local cbtext = SetFontString(cb, fontn, 14, "THINOUTLINE")
      cbtext:SetPoint("LEFT", cb, 3, 1)
      cbtext:SetPoint("RIGHT", cbtime, "LEFT")
      cb.Text = cbtext
		local cbicon = cb:CreateTexture(nil, 'ARTWORK')
		cbicon:SetHeight(32)
        cbicon:SetWidth(32)
		cbicon:SetTexCoord(0.0, 1.0, 0.0, 1.0)
		if(unit == "player") then
		cbicon:SetPoint("RIGHT", 40, 0)
		else cbicon:SetPoint("LEFT",-40, 0) end
				local ib = cb:CreateTexture(nil, 'OVERLAY')
				ib:SetTexture(border)
				ib:SetAllPoints(cbicon)
				ib:SetTexCoord(0.03, 0.97, 0.03, 0.97)
				ib:SetVertexColor(0.3, 0.3, 0.3)
				ib:SetBlendMode('BLEND')
		cb.Icon = cbicon
				
      if(cbarsafe == true and unit == "player") then
        local cbsafe = cb:CreateTexture(nil,"ARTWORK")
        cbsafe:SetTexture(texture)
        cbsafe:SetVertexColor(.69,.31,.31)
        cbsafe:SetPoint("TOPRIGHT")
        cbsafe:SetPoint("BOTTOMRIGHT")
        cb.SafeZone = cbsafe
		local lag = SetFontString(cb, fontn, 10, "THINOUTLINE")
        lag:SetPoint("BOTTOMRIGHT",cb,0, -12)
        cb.Lag = lag
		self.PostCastStart = PostCastStart
		self.OnCastbarUpdate = OnCastbarUpdate
		self.PostChannelStart = PostChannelStart
		self:RegisterEvent("UNIT_SPELLCAST_SENT", UNIT_SPELLCAST_SENT)
      end    
	end
  end
  if(unit == "player") then
    if(IsAddOnLoaded("oUF_Swing")) then      
      local pcolor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
      self.Swing = CreateFrame("StatusBar", nil, self)
      self.Swing:SetPoint("BOTTOM", self, "TOP", 0, 38)
      self.Swing:SetStatusBarTexture(texture)
      if(pcolor) then
        self.Swing:SetStatusBarColor(pcolor.r, pcolor.g, pcolor.b)
      else
        self.Swing:SetStatusBarColor(0.3, 0.3, .3)
      end      
      self.Swing:SetHeight(4)
      self.Swing:SetWidth(width)
      self.Swing:SetBackdrop(backdrop)
      self.Swing:SetBackdropColor(0, 0, 0)

      self.Swing.Text = self.Swing:CreateFontString(nil, "OVERLAY")
      self.Swing.Text:SetFont(fontn, 10, "THINOUTLINE")
      self.Swing.Text:SetPoint("BOTTOMRIGHT", self.Swing, "TOPRIGHT", 0,1)

      self.Swing.bg = self.Swing:CreateTexture(nil, "BORDER")
      self.Swing.bg:SetAllPoints(self.Swing)
      self.Swing.bg:SetTexture(0.4, 0.4, 0.4)        
    end
	if(IsAddOnLoaded("oUF_PowerSpark")) then
	  self.Spark = self.Power:CreateTexture(nil, "OVERLAY")
	  self.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	  self.Spark:SetVertexColor(1, 1, 1, 1)
	  self.Spark:SetBlendMode("ADD")
	  self.Spark:SetHeight(self.Power:GetHeight()*2)
	  self.Spark:SetWidth(4)
	  self.Spark = spark
	end
    if(class == "DRUID") then
      self.DruidPower = CreateFrame('StatusBar', nil, self)
      self.DruidPower:SetPoint('TOP', self.Health, 'BOTTOM')
      self.DruidPower:SetStatusBarTexture(texture)
      self.DruidPower:SetHeight(1)
      self.DruidPower:SetWidth(width)
      self.DruidPower:SetAlpha(0)

      local value = SetFontString(self.DruidPower, fontn, 14, "THINOUTLINE")
      value:SetPoint("LEFT",self.Health, 0, -23)
      self:Tag(value, '[druidpower]')

      table.insert(self.__elements, updateDruidPower)
      self:RegisterEvent('UNIT_MANA', updateDruidPower)
      self:RegisterEvent('UNIT_ENERGY', updateDruidPower)
      self:RegisterEvent('UPDATE_SHAPESHIFT_FORM', updateDruidPower)
    end
    if(select(2, UnitClass('player')) == 'DEATHKNIGHT') then
      self.Runes = CreateFrame('Frame', nil, self)
      self.Runes:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -1)
      self.Runes:SetHeight(4)
      self.Runes:SetWidth(width)
      self.Runes.anchor = 'TOPLEFT'
      self.Runes.growth = 'RIGHT'
      self.Runes.height = 4
      self.Runes.width = width / 6 - 1
	  self.Runes.spacing = 1

      for index = 1, 6 do
        self.Runes[index] = CreateFrame('StatusBar', nil, self.Runes)
        self.Runes[index]:SetBackdrop(backdrop)
        self.Runes[index]:SetBackdropColor(0, 0, 0)
        self.Runes[index]:SetStatusBarTexture(texture)

        self.Runes[index].bg = self.Runes[index]:CreateTexture(nil, 'BACKGROUND')
        self.Runes[index].bg:SetAllPoints(self.Runes[index])
        self.Runes[index].bg:SetTexture(texture)
		self.Runes[index].bg.multiplier = 0.3
      end
    end   
    if(UnitLevel("player") ~= MAX_PLAYER_LEVEL) then
      self.Resting = self.Health:CreateTexture(nil, "OVERLAY")
      self.Resting:SetHeight(16)
      self.Resting:SetWidth(16)
      self.Resting:SetPoint("TOPRIGHT", 0, 8)
    end  
	if inCombat then
	  self.Combat = self.Health:CreateTexture(nil, "OVERLAY")
      self.Combat:SetPoint("BOTTOMLEFT", self, -2, -8)
      self.Combat:SetHeight(20)
      self.Combat:SetWidth(20)
	end
  end
	if IsAddOnLoaded("oUF_WeaponEnchant") then
			self.Enchant = CreateFrame("Frame", nil, self)
			self.Enchant.size = 32
			self.Enchant:SetHeight(self.Enchant.size * 1)
			self.Enchant:SetWidth(self.Enchant.size * 3)
			self.Enchant:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 59, -141)
			self.Enchant["growth-x"] = "LEFT"
			self.Enchant.spacing = 2
			self.PostCreateEnchantIcon = createAura
			self.PostUpdateEnchantIcons = CreateEnchantTimer
	end
  	if(unit=="player") then
		self.Buffs = CreateFrame("Frame", nil, self) -- buffs
		self.Buffs.size = 32
		self.Buffs:SetHeight(self.Buffs.size * 3)
		self.Buffs:SetWidth(self.Buffs.size * 12)
		self.Buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -5, -35)
		self.Buffs.initialAnchor = "TOPRIGHT"
		self.Buffs["growth-y"] = "DOWN"
		self.Buffs["growth-x"] = "LEFT"
		self.Buffs.spacing = 2
		self.Buffs.num = 40
		self.Buffs.disableCooldown = false
	end
		
 	if (unit == "player" or self:GetParent():GetName():match'oUF_Party') then
    self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
    self.Leader:SetPoint("TOPLEFT", self, 0, 8)
    self.Leader:SetHeight(16)
    self.Leader:SetWidth(16)
    
    self.Threat = self.Health:CreateTexture(nil, "OVERLAY")
    self.Threat:SetHeight(8)
    self.Threat:SetWidth(8)  
	self.Threat:SetTexture([=[Interface\AddOns\oUF_ichik\media\indicator]=])
    self.Threat:SetPoint("TOPRIGHT", self.Health, 0, 0)  
  end
	if (unit == "player" or unit == "target" or unit == "pet" or unit == "targettarget" or self:GetParent():GetName():match'oUF_Party') then
    self.Auras = CreateFrame("Frame", nil, self)
    self.Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -1, 5)
    self.Auras.gap = false
    self.Auras.showDebuffType = true  
    self.Auras.spacing = 1
    self.Auras.initialAnchor = "BOTTOMLEFT"
    self.Auras["growth-y"] = "UP"
    if(unit == "target") then      
      self.CPoints = SetFontString(self.Health, fontn, 16, "THINOUTLINE")
      self.CPoints:SetPoint("RIGHT", self.Health, -2, 0)
      self.CPoints.unit = "player"
      self.Auras:SetHeight(30)
	  self.Auras.numBuffs = 7
	  self.Auras.numDebuffs = 7
      self.Auras:SetWidth(width)
      self.Auras.size = self.Auras:GetHeight()
    elseif(unit == "player") then
		self.Auras.numDebuffs = 7
		self.Auras.numBuffs = 0
		self.Auras:SetHeight(30)
		self.Auras:SetWidth(width)
		self.Auras.size = self.Auras:GetHeight()
		self.PreAuraSetPosition = preAuraSetPosition
    end  
    if(unit == "pet") then
      self.Power.colorPower = true
      self.Power.colorHappiness = true
      self.Power.colorReaction = false
      
      self.Auras:SetHeight(self.Health:GetHeight())
      self.Auras:SetWidth(width - 106)
      self.Auras.size = self.Auras:GetHeight()

      self.CPoints = SetFontString(self.Health, fontn, 14, "THINOUTLINE")
      self.CPoints:SetPoint("LEFT", self.Health, 2, 0)
      self.CPoints.unit = "pet"
    end
    if(unit == "targettarget") then
      self.Auras:SetHeight(30)
      self.Auras:SetWidth(width - 106)
      self.Auras.size = self.Auras:GetHeight()
      self.Auras.num = 5
      self.Auras.numBuffs = 0
      self.Auras.numDebuffs = 2
      self.Auras.initialAnchor = "TOPRIGHT"
      self.Auras["growth-x"] = "LEFT"
    end    
    if (self:GetParent():GetName():match'oUF_Party') then  
      self:SetAttribute('initial-height', height)
      self:SetAttribute('initial-width', width - 86)
      
      self.Health.Text2:Hide()
      self.Auras:SetHeight(30)
      self.Auras:SetWidth(width - 86)
      self.Auras.size = 30
      self.Auras.buffFilter = "HELPFUL|RAID"
      self.Auras.numBuffs = 3
      self.Auras.numDebuffs = 3
      
      self.outsideRangeAlpha = 0.4
      self.inRangeAlpha = 1.0
      self.Range = true  
      if(ppets and self:GetAttribute('unitsuffix') == 'pet') then
        self:SetAttribute('initial-height', height)
        self:SetAttribute('initial-width', width - 126)
        
        self.Health.Text:Hide()
        self.Health.colorReaction = true
        
        self.Power.colorPower = true
        
        self.Info:SetPoint("LEFT", self.Health, 0, -23)
        self.Info:SetPoint("RIGHT", self.Health)
        self.Threat:Hide()
        self.Leader:Hide()
        self.Auras:Hide()
      end
    end
  end
    -- oUF Debuff Highlight support
	if(IsAddOnLoaded("oUF_DebuffHighlight")) then
		local dbh = self.Health:CreateTexture(nil, "OVERLAY")
		dbh:SetAllPoints(self)
		dbh:SetTexture(debufftex)
		dbh:SetVertexColor(0,0,0,0)
		dbh:SetBlendMode("ADD")
		self.DebuffHighlight = dbh
		self.DebuffHighlightAlpha = 1
		self.DebuffHighlightFilter = true
	end
  if(IsAddOnLoaded("oUF_HealComm4")) then
    self.HealCommBar = CreateFrame('StatusBar', nil, self.Health)
	self.HealCommBar:SetHeight(0)
	self.HealCommBar:SetWidth(0)
	self.HealCommBar:SetStatusBarTexture(self.Health:GetStatusBarTexture():GetTexture())
	self.HealCommBar:SetStatusBarColor(0, 1, 0, 0.25)
	self.HealCommBar:SetPoint('LEFT', self.Health, 'LEFT')

	-- optional flag to show overhealing
	self.allowHealCommOverflow = true
  end

  if(not (unit == "target" or self:GetParent():GetName():match'oUF_Party')) then
    self.ignoreHealComm = true
  end  
  self.MoveableFrames = true
  --self.disallowVehicleSwap = true
  
  if(unit=="target") then
	self:RegisterEvent("UNIT_TARGET", function(self, event, unit)
	  if(unit=="target") then
        oUF.units.targettarget:PLAYER_ENTERING_WORLD'OnTargetUpdate'
  	  end
	end)
  end  
  self.PostCreateAuraIcon = createAura
  self.PostUpdateAuraIcon = updateAura
  if(unit == "focustarget") then
    self.Health:SetHeight(13)
    self.Power:Hide()
    
    self:SetAttribute("initial-height", 13)
    self:SetAttribute('initial-width', width - 86)        
  elseif(unit == "focus" or (unit and unit:match("boss%d"))) then      
    self:SetAttribute('initial-height', height)
    self:SetAttribute('initial-width', width - 86)        
  elseif(unit == "pet" or unit == "targettarget") then
    self:SetAttribute('initial-height', height)
    self:SetAttribute('initial-width', width - 106)        
  elseif(unit == "player" or unit == "target") then
    self:SetAttribute('initial-height', height)
    self:SetAttribute('initial-width', width)
  end

  return self
end

oUF:RegisterStyle("ichik", styleFunc)
oUF:SetActiveStyle("ichik")
oUF:Spawn("player", "oUF_ichik_player"):SetPoint("TOP", UIParent, "BOTTOM", -300, 419)
oUF:Spawn("target", "oUF_ichik_target"):SetPoint("TOP", UIParent, "BOTTOM", 0, 300)

 oUF:Spawn("targettarget", "oUF_ichik_targett"):SetPoint("LEFT", "oUF_ichik_target", "RIGHT", 7, 0)
oUF:Spawn("pet", "oUF_ichik_pet"):SetPoint("RIGHT", "oUF_ichik_player", "LEFT", -7, 0)

oUF:Spawn("focus", "oUF_ichik_focus"):SetPoint("RIGHT", UIParent, -55, 0)
oUF:Spawn("focustarget", "oUF_ichik_focust"):SetPoint("TOP", "oUF_ichik_focus", 0, 18)

local boss = {}
for i = 1, MAX_BOSS_FRAMES do
	boss[i] = oUF:Spawn("boss"..i, "oUF_Boss"..i)

	if i == 1 then
		boss[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 15, -215)
	else
		boss[i]:SetPoint("TOP", boss[i-1], "BOTTOM", 0, -5)
	end
end

for i, v in ipairs(boss) do v:Show() end

local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("TOPRIGHT","oUF_ichik_pet", 0, 75)
party:SetManyAttributes("showParty", true, "yOffset", 83, "showPlayer", false)
if ppets then
  party:SetAttribute("template", "oUF_ichikPPets")
end
if IsAddOnLoaded("oUF_MoveableFrames") then
  oUF_MoveableFrames_HEADER("oUF_Party", PartyAnchor, 0, 75)
end

local partyToggle = CreateFrame("Frame")
partyToggle:RegisterEvent("PLAYER_LOGIN")
partyToggle:RegisterEvent("RAID_ROSTER_UPDATE")
partyToggle:RegisterEvent("PARTY_LEADER_CHANGED")
partyToggle:RegisterEvent("PARTY_MEMBER_CHANGED")
partyToggle:SetScript("OnEvent", function(self)
  if(InCombatLockdown()) then
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
  else
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if (partyraid == true and GetNumRaidMembers() <=5 or GetNumRaidMembers() == 0) then
      party:Show()
    else
      party:Hide()
    end
  end
end)
