local texture = [=[Interface\AddOns\oUF_ichik\media\minimalist]=]
local highlight = [=[Interface\AddOns\oUF_ichik\media\white]=]
local border = [=[Interface\AddOns\oUF_ichik\media\border]=]
local fontn = "Fonts\\ARIALN.TTF"
local width, height = 35, 35
local widthm, heightm = 120, 20

local pname, prealm = UnitName("player"), GetRealmName()
local playerClass = select(2, UnitClass("player"))
local dfilter = false     -- true = filtering debuffs on raid and mt/ma. See blacklist
local blacklist = false   -- true = debuffs in filterlist won't displayed // false = only debuffs in filterlist will displayed.
						 -- See i.e. www.wowhead.com for spellIDs	
local debuffTooltip = true -- true = tooltip of debuffs are shown

-- Credits to Caellian (oUF Caellian)
local function utf8sub(string, i, dots)
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
      elseif c >= 194 and c <= 223 then
        pos = pos + 2
      elseif c >= 224 and c <= 239 then
        pos = pos + 3
      elseif c >= 240 and c <= 244 then
        pos = pos + 4
      end
      if len == i then break end
    end

    if len == i and pos <= bytes then
      return string:sub(1, pos - 1)..(dots and "..." or "")
    else
      return string
    end
  end
end	
 
oUF.TagEvents["[ichikname]"] = oUF.TagEvents["[name]"]
oUF.Tags["[ichikname]"]  = function(u, r, realUnit)
  local name = UnitName(realUnit or u or r)
  return utf8sub(name, 5, false)
end

oUF.TagEvents["[ichikstatus]"] = oUF.TagEvents["[curhp]"]
oUF.Tags["[ichikstatus]"] = function(u)
  return   not UnitIsConnected(u) and "Offline" or
      UnitIsDead(u) and "Dead" or 
      UnitIsGhost(u) and "Ghost" or ""
end

oUF.TagEvents["[ichikhpm]"] = oUF.TagEvents["[curhp]"]
oUF.Tags["[ichikhpm]"] = function(u)
  return  UnitIsDeadOrGhost(u) and oUF.Tags["[dead]"](u) or
      (not UnitIsConnected(u)) and oUF.Tags["[offline]"](u) or oUF.Tags["[curhp]"](u)
end	

local function menu(self)
  if(self.unit:match("party")) then
    ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
  else
    FriendsDropDown.unit = self.unit
    FriendsDropDown.id = self.id
    FriendsDropDown.initialize = RaidFrameDropDown_Initialize
    ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
  end
end
	
local colors = setmetatable({
  power = setmetatable({
    ["MANA"] = {0, 144/255, 1},
  }, {__index = oUF.colors.power}),
}, {__index = oUF.colors})
	
-- buff indicators - Credits to roth (oUF D3OrbsRaid) and Astromech (oUF AuraWatch)
local function cR_createAuraWatch(self,unit)
  local auras = CreateFrame("Frame", nil, self)
  auras:SetAllPoints(self.Health)
  --auras:SetFrameStrata("HIGH")
  local spellIDs = { 
    47440, -- Commanding Shout
    47436, -- Battle Shout
    59665, -- Vigilance
  }
    
  auras.presentAlpha = 1
  auras.missingAlpha = 0
  --auras.hideCooldown = true
  --auras.PostCreateIcon = createAuraIcon
  auras.icons = {}
   
  for i, sid in pairs(spellIDs) do
    local icon = CreateFrame("Frame", nil, auras)
    icon.spellID = sid
    local cd = CreateFrame("Cooldown", nil, icon)
    cd:SetAllPoints(icon)
    cd:SetReverse()
    --cd:SetAlpha(0)
    icon.cd = cd
    if i > 4 then
      icon.anyUnit = true
      icon:SetWidth(20)
      icon:SetHeight(20)
      icon:SetPoint("CENTER",0,0)
    else
      icon:SetWidth(7)
      icon:SetHeight(7)
      local tex = icon:CreateTexture(nil, "BACKGROUND")
      tex:SetAllPoints(icon)
      tex:SetTexture([=[Interface\AddOns\oUF_ichik\media\indicator]=])
      if i == 1 then
        icon:SetPoint("BOTTOMLEFT",0,0)
        tex:SetVertexColor(200/255,100/255,200/255)
      elseif i == 2 then
        icon:SetPoint("BOTTOMLEFT",0,0)
        tex:SetVertexColor(200/255,100/255,200/255)
      elseif i == 3 then 
        icon:SetPoint("BOTTOMRIGHT",0,0)
        tex:SetVertexColor(50/255,200/255,50/255)
        --[[local count = icon:CreateFontString(nil, "OVERLAY")
        count:SetFont(NAMEPLATE_FONT,10,"THINOUTLINE")
        count:SetPoint("CENTER", -6, 0)
        --count:SetAlpha(0)
        icon.count = count]]
      elseif i == 4 then
        icon:SetPoint("BOTTOMRIGHT",0,0)
        tex:SetVertexColor(200/255,100/255,0/255)
      end
      icon.icon = tex
    end  
    auras.icons[sid] = icon
  end
  self.AuraWatch = auras
end

local function updateRIcon(self, event)
  local index = GetRaidTargetIndex(self.unit)
  if(index) then
    self.RIcon:SetText(ICON_LIST[index].."22|t")
  else
    self.RIcon:SetText()
  end
end

-- credits to Freebaser (oUF_Freebgrid)
local function updateThreat(self, event, u)
	if (self.unit ~= u) then return end
	local s = UnitThreatSituation(u)
	if s and s > 1 then
		r, g, b = GetThreatStatusColor(s)
		self.TBorder:SetBackdropBorderColor(r, g, b,1)
	else
		self.TBorder:SetBackdropBorderColor(0, 0, 0,0)
	end
end

local function TChange(self)
  if (UnitInRaid"player" == 1 or UnitInParty"player") and UnitName("target") == UnitName(self.unit) then
    self.TBorder:SetBackdropBorderColor(0, 1, 0,1)
    self.Info:SetTextColor(0, 1, 0)
  else
    self.TBorder:SetBackdropBorderColor(0,0,0,0)
    self.Info:SetTextColor(1,1,1)
  end
end

local function OnEnter(self)
  UnitFrame_OnEnter(self)
  self.TBorder:SetBackdropBorderColor(0.8,0.8,0.8,1)
  self.Highlight:Show()
end

local function OnLeave(self)
  UnitFrame_OnLeave(self)
  if (UnitInRaid"player" == 1 or UnitInParty"player") and UnitName("target") == UnitName(self.unit) then
    self.TBorder:SetBackdropBorderColor(0, 1, 0, 1)
  else
    self.TBorder:SetBackdropBorderColor(0,0,0,0)
  end
  self.Highlight:Hide()
end

--[[local filter = {
  [GetSpellInfo(11196)] = true, -- Recently Bandaged
  [GetSpellInfo(6788)] = true, -- Weakened Soul
  [GetSpellInfo(57723)] = true, -- Exhaustion
  [GetSpellInfo(61251)] = true, -- Power of Vesperon
  [GetSpellInfo(61248)] = true, -- Power of Tenebron
  [GetSpellInfo(58105)] = true, -- Power of Shadron
  [GetSpellInfo(55799)] = true, -- Frost Aura (Sapphiron)
  [GetSpellInfo(62692)] = true, -- Aura of Despair (General Vezax)
  [GetSpellInfo(64646)] = true, -- Corrupted Wisdom (General Vezax)
  [GetSpellInfo(63050)] = true, -- Sanity (Yogg Saron)
  [GetSpellInfo(64805)] = true, -- Bested Darnassus
  [GetSpellInfo(64808)] = true, -- Bested Exodar
  [GetSpellInfo(64809)] = true, -- Bested Gnomeregan
  [GetSpellInfo(64810)] = true, -- Bested Ironforge  
  [GetSpellInfo(64811)] = true, -- Bested Orgrimmar
  [GetSpellInfo(64812)] = true, -- Bested Sen'jin 
  [GetSpellInfo(64813)] = true, -- Bested Silvermoon City
  [GetSpellInfo(64814)] = true, -- Bested Stormwind  
  [GetSpellInfo(64815)] = true, -- Bested Thunder Bluff
  [GetSpellInfo(64816)] = true, -- Bested Undercity
  [GetSpellInfo(25771)] = true, -- Forbearance
  [GetSpellInfo(41425)] = true, -- Hypothermia
  [GetSpellInfo(69127)] = true, -- Chill of the Throne
}]]--
local function CustomAuraFilter(icons, unit, icon, name)
  if blacklist then
    if(filter[name]) then return false else return true end
  else
    if(filter[name]) then return true else return false end
  end
end

local function PostCreateAuraIcon(icons, button)
  local pcolor = UnitIsPlayer("player") and RAID_CLASS_COLORS[select(2, UnitClass("player"))]
  icons.showDebuffType = true
  button:EnableMouse(debuffTooltip)  
  button.cd:SetReverse()
  button.icon:SetTexCoord(0.0, 1.0, 0.0, 1.0)
  button.overlay:SetTexture(border)
  button.overlay:SetTexCoord(0.03, 0.97, 0.03, 0.97)
  if (pcolor) then
    button.overlay.Hide = function(self) self:SetVertexColor(pcolor.r, pcolor.g, pcolor.b) end
  else 
    button.overlay.Hide = function(self) self:SetVertexColor(.37, .3, .3) end
  end
  button:SetScript('OnMouseUp', onMouseUp)
end

local function styleFunc(self, unit)
  self.menu = menu
  self.colors = colors
  self:EnableMouse(true)
  self:SetScript("OnEnter", OnEnter)
  self:SetScript("OnLeave", OnLeave)
  self:RegisterForClicks"anyup"
  self:SetAttribute("*type2", "menu")
  self:SetFrameStrata("LOW")

  self:SetBackdrop({bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], insets = {top = -1, left = -1, bottom = -1, right = -1}})
  self:SetBackdropColor(0, 0, 0)
 
  self.TBorder = CreateFrame("Frame", nil, self)
  self.TBorder:SetPoint("TOPLEFT",-2,2)
  self.TBorder:SetPoint("BOTTOMRIGHT",2,-2)
  self.TBorder:SetBackdrop({
    bgFile = [[Interface\ChatFrame\ChatFrameBackground]], tile = true, tileSize = 16,
    edgeFile = [[Interface\ChatFrame\ChatFrameBackground]], edgeSize = 1,
    insets = {top = 1, left = 1, bottom = 1, right = 1},
  })
  self.TBorder:SetBackdropColor(0, 0, 0, 0)
  self.TBorder:SetBackdropBorderColor(0, 0, 0, 0)    
  
  self.Health = CreateFrame("StatusBar", nil, self)
  self.Health:SetFrameStrata("LOW")
  self.Health:SetPoint("TOPRIGHT", self)
  self.Health:SetPoint("TOPLEFT", self)
  self.Health:SetHeight(height - 4)
  self.Health:SetStatusBarTexture(texture)

  self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
  self.Health.bg:SetAllPoints(self.Health)
  self.Health.bg:SetTexture(texture)
  self.Health.bg:SetAlpha(0.3)
  
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
  
  self.Power.colorPower = true
  
  self.Power.frequentUpdates = true
  self.Power.Smooth = true

  self.Status = self.Health:CreateFontString(nil, "OVERLAY")
  self.Status:SetFont(fontn,12,"THINOUTLINE")
  self.Status:SetPoint("BOTTOM", self.Health,0,1)
  self.Status:SetJustifyH("CENTER")
  self:Tag(self.Status, "[ichikstatus]")

  self.Info = self.Health:CreateFontString(nil, "OVERLAY")
  self.Info:SetFont(fontn,12,"THINOUTLINE")
  self.Info:SetPoint("TOP", self)
  self.Info:SetJustifyH("CENTER")
  self:Tag(self.Info, "[ichikname]")  

  self.Highlight = self.Health:CreateTexture(nil, "OVERLAY")
  self.Highlight:SetAllPoints(self)
  self.Highlight:SetTexture(highlight)
  self.Highlight:SetVertexColor(1,1,1,.1)
  self.Highlight:SetBlendMode("ADD")
  self.Highlight:Hide()  

  if(self:GetParent():GetName():match("oUF_MainTank") or self:GetParent():GetName():match("oUF_MainAssist") or (self:GetAttribute('unitsuffix') and (self:GetAttribute('unitsuffix') == 'target'or self:GetAttribute('unitsuffix') == 'targettarget'))) then
    self.Health:SetHeight(heightm - 4)
    
    self.Health.Text = self.Health:CreateFontString(nil, "OVERLAY")
    self.Health.Text:SetFont(fontn, 14, "THINOUTLINE")
    self.Health.Text:SetPoint("RIGHT", -1, 1)
    self.Health.Text:SetShadowColor(0,0,0)
    self.Health.Text:SetShadowOffset(1, -1)
    self.Health.Text:SetJustifyH("RIGHT")	
    self:Tag(self.Health.Text, "[ichikhpm]")
    
    self.Info:SetFont(fontn,14,"THINOUTLINE")
    self.Info:SetPoint("LEFT", self.Health, 2, 0)
    self.Info:SetPoint("RIGHT", self.Health.Text, "LEFT")    
    self.Info:SetJustifyH("LEFT")
    self:Tag(self.Info, "[name]")
    
    self.Status:Hide()
    self.Highlight:SetVertexColor(1,1,1,0)
    self.TBorder:Hide()
    
    self.outsideRangeAlpha = 1.0
    self.inRangeAlpha = 1.0
    self.Range = true  
    
    self:SetAttribute('initial-height', heightm)
    self:SetAttribute('initial-width', widthm)
    if not (self:GetAttribute('unitsuffix') and (self:GetAttribute('unitsuffix') == 'target' or self:GetAttribute('unitsuffix') == 'targettarget')) then
      self.Auras = CreateFrame("Frame", nil, self)
      self.Auras:SetPoint("CENTER", self, "CENTER", 0, 0)
      self.Auras.gap = true
      self.Auras.showDebuffType = true  
      self.Auras.spacing = 2
      self.Auras.initialAnchor = "RIGHT"
      self.Auras["growth-x"] = "LEFT"  
      self.Auras.numBuffs = 1
      self.Auras.buffFilter = "HELPFUL|RAID"
      self.Auras.numDebuffs = 3
      self.Auras:SetHeight(20)
      self.Auras:SetWidth(widthm)
      self.Auras.size = self.Auras:GetHeight()

      self.PostCreateAuraIcon = PostCreateAuraIcon
      self.CustomAuraFilter = CustomAuraFilter
    end    
  else  
    if(IsAddOnLoaded("oUF_AuraWatch")) then
      cR_createAuraWatch(self,unit)
	end  
	if(IsAddOnLoaded("oUF_RaidDebuffs")) then
	  self.RaidDebuffs = CreateFrame('Frame', nil, self)
	  self.RaidDebuffs:SetHeight(25)
	  self.RaidDebuffs:SetWidth(25)
	  self.RaidDebuffs:SetPoint('CENTER', self, "CENTER",0,1)
	  self.RaidDebuffs:SetFrameStrata'HIGH'
	
	  self.RaidDebuffs.icon = self.RaidDebuffs:CreateTexture(nil, 'OVERLAY')
	  self.RaidDebuffs.icon:SetTexCoord(0.0,1.0,0.0,1.0)
	  self.RaidDebuffs.icon:SetAllPoints(self.RaidDebuffs)
	  
	  self.RaidDebuffs.overlay = self.RaidDebuffs:CreateTexture(nil, "OVERLAY")
	  self.RaidDebuffs.overlay:SetAllPoints(self.RaidDebuffs)
	  self.RaidDebuffs.overlay:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	  self.RaidDebuffs.overlay:SetTexture(border)
    else
	  if dfilter then
        self.Debuffs = CreateFrame("Frame", nil, self)
        self.Debuffs:SetPoint("CENTER",self.Health)
        self.Debuffs.showDebuffType = true  
        self.Debuffs.num = 2
        self.Debuffs.initialAnchor = "BOTTOMLEFT"
        self.Debuffs:SetHeight(20)
        self.Debuffs:SetWidth(20)
        self.Debuffs.size = self.Debuffs:GetHeight()  
        self.Debuffs.disableCooldown = 1

	    self.PostCreateAuraIcon = PostCreateAuraIcon
        self.CustomAuraFilter = CustomAuraFilter  	
	  end
    end
    self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
    self.Leader:SetPoint("TOPLEFT", self.Health, 0, 6)
    self.Leader:SetHeight(16)
    self.Leader:SetWidth(16)  

    self.ReadyCheck = self.Health:CreateTexture(nil, "OVERLAY")
    self.ReadyCheck:SetPoint("CENTER", self.Health, 0, 0)
    self.ReadyCheck:SetHeight(20)
    self.ReadyCheck:SetWidth(20)
    
    local ricon = self.Health:CreateFontString(nil, "OVERLAY")
    ricon:SetPoint("TOP", self, 0, 8)
    ricon:SetJustifyH"LEFT"
    ricon:SetFontObject(GameFontNormalSmall)
    ricon:SetTextColor(1, 1, 1)
    self.RIcon = ricon
    self:RegisterEvent("RAID_TARGET_UPDATE", updateRIcon)
    table.insert(self.__elements, updateRIcon)  
    
    self.Threat = self.Health:CreateTexture(nil, "OVERLAY")
    self.Threat:SetHeight(7)
    self.Threat:SetWidth(7)
	self.Threat:SetTexture([=[Interface\AddOns\oUF_ichik\media\indicator]=])
    self.Threat:SetPoint("BOTTOM", self.Health, 0, 0) 
	
    if(IsAddOnLoaded("oUF_HealComm4")) then

	-- optional flag to show overhealing
	  self.allowHealCommOverflow = true
	
	  self.HealCommText = self.Health:CreateFontString(nil, "OVERLAY")
      self.HealCommText:SetFont(fontn,12,"THINOUTLINE")
      self.HealCommText:SetPoint("BOTTOM", self.Health,0,1)
      self.HealCommText:SetJustifyH("CENTER")	

	-- optional routine override to format the text display
	  self.HealCommTextFormat = shortVal
  
      self.disallowVehicleSwap = false 
	
    end	  
    self:RegisterEvent("PLAYER_TARGET_CHANGED", OnLeave)  
    self:RegisterEvent("PLAYER_TARGET_CHANGED", TChange)
	self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", updateThreat)
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", updateThreat)
    
    self:SetAttribute('initial-height', height)
    self:SetAttribute('initial-width', width)    
  end
  
  self.MoveableFrames = true
  
  self.outsideRangeAlpha = 0.4
  self.inRangeAlpha = 1.0
  self.Range = true  
  
  return self
end

oUF:RegisterStyle("ichikR", styleFunc)
oUF:SetActiveStyle("ichikR")


local zone_data = {
  ["Alteractal"] = 8, -- Alterac Valley
  ["Insel der Eroberung"] = 8, -- Isle of Conquest
}

local zoneRaid = CreateFrame'Frame'

function zoneRaid:OnEvent(event, ...)
	local raid_groups
	local zone = GetRealZoneText()
	if zone_data[GetRealZoneText()] then
      for k, v in pairs(zone_data) do
        if k == GetRealZoneText() then
          raid_groups = v
        end
      end
	else
      raid_groups = 5	
    end
   return raid_groups
end

zoneRaid:RegisterEvent("PLAYER_LOGIN")
zoneRaid:RegisterEvent("WORLD_MAP_UPDATE")
zoneRaid:RegisterEvent("MINIMAP_ZONE_CHANGED");
zoneRaid:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneRaid:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
zoneRaid:RegisterEvent("ZONE_CHANGED_INDOORS");
zoneRaid:RegisterEvent("ZONE_CHANGED");
zoneRaid:RegisterEvent("ZONE_CHANGED_NEW_AREA")

zoneRaid:SetScript("OnEvent", zoneRaid.OnEvent)
--ChatFrame1:AddMessage(zoneRaid:OnEvent())

local Raid = {}
local group = 0
for i = 1, zoneRaid:OnEvent() do
  local RaidGroup = oUF:Spawn("header", "oUF_Raid" .. i)
  RaidGroup:SetManyAttributes("groupFilter", tostring(i), "showRaid", true, "yOffset", 3, "point", "BOTTOM", "sortDir", "DESC")
  table.insert(Raid, RaidGroup)
  if i == 1 then
    RaidGroup:SetPoint("BOTTOMLEFT", UIParent, 5, 300) 	
  else
    RaidGroup:SetPoint("TOPLEFT", Raid[i-1], "TOPRIGHT", 3, 0)  
  end    
  group = group + 1
  RaidGroup:Show()
end

local tank = oUF:Spawn("header", "oUF_MainTank")
tank:SetManyAttributes("showRaid", true, "groupFilter", "MAINTANK", "yOffset", 5, "point" , "BOTTOM")
tank:SetPoint("BOTTOMLEFT", UIParent, 5, 510)
tank:SetAttribute("template", "oUF_ichikMt")
tank:Show()

--[[local assist = oUF:Spawn("header", "oUF_MainAssist")
assist:SetManyAttributes("showRaid", true, "groupFilter", "MAINASSIST", "yOffset", 5, "point", "BOTTOM")
assist:SetPoint("TOP", tank, "BOTTOM", 0, -30)
assist:SetAttribute("template", "oUF_ichikMt")
assist:Show()]]

if IsAddOnLoaded("oUF_MoveableFrames") then
  oUF_MoveableFrames_HEADER("oUF_Raid" .. 1, RaidAnchor, 300, -500)
  oUF_MoveableFrames_HEADER("oUF_MainTank", MtAnchor, 200, 761)
  oUF_MoveableFrames_HEADER("oUF_MainAssist", MaAnchor, 200, 686)
end