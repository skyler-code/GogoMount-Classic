local addonName, addonTable = ...

local tinsert, tremove = tinsert, tremove
local GetRealZoneText, InCombatLockdown, IsFlying, GetZoneText, GetSubZoneText, IsOutdoors, IsFlyableArea, IsFalling, IsSwimming =
	GetRealZoneText, InCombatLockdown, IsFlying, GetZoneText, GetSubZoneText, IsOutdoors, IsFlyableArea, IsFalling, IsSwimming
local IsMounted, CanExitVehicle, GetMinimapZoneText, UnitBuff, GetUnitSpeed, GetNumSkillLines, GetSkillLineInfo, GetSpellBookItemName =
	IsMounted, CanExitVehicle, GetMinimapZoneText, UnitBuff, GetUnitSpeed, GetNumSkillLines, GetSkillLineInfo, GetSpellBookItemName
local C_Map = C_Map

local GoGoMount = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local playerZone, playerSubZone
local _, playerClass = UnitClass("player")


local savedDBDefaults = {
	char = {
		enabled = true,
        autodismount = true,
		genericfastflyer = false,
		DruidClickForm = true,
		DruidFlightForm = true,
		GlobalPrefMount = false,
		FilteredZones = {},
		GlobalPrefMounts = {},
		GlobalIgnoreMounts = {},
	},
}

local GOGO_ERRORS = {
	[SPELL_FAILED_NOT_MOUNTED] = true,
	[SPELL_FAILED_NOT_SHAPESHIFT] = true,
	[ERR_ATTACK_MOUNTED] = true,
}

local GOGO_COMMANDS = {
	["auto"] = function(self)
		self.db.char.autodismount = not self.db.char.autodismount
		self:Msg("auto")
	end,
	["genericfastflyer"] = function(self)
		if not self:CanFly() then
			return
		else
			self.db.char.genericfastflyer = not self.db.char.genericfastflyer
			self:Msg("genericfastflyer")
		end
	end,
	["clear"] = function(self)
		if self.db.char.GlobalPrefMount then
			self.db.char.GlobalPrefMounts = nil
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton1, GoGoButton2}) do
					self:FillButton(button)
				end
			end
		else
			self.db.char.FilteredZones[playerZone] = nil
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton1, GoGoButton2}) do
					self:FillButton(button)
				end
			end
		end
		self:Msg("pref")
	end,
	["druidclickform"] = function(self)
		self.db.char.DruidClickForm = not self.db.char.DruidClickForm
		self:Msg("druidclickform")
	end,
	["druidflightform"] = function(self)
		self.db.char.DruidFlightForm = not self.db.char.DruidFlightForm
		self:Msg("druidflightform")
	end,
	["options"] = function(self)
		InterfaceOptionsFrame_OpenToCategory(addonName)
		InterfaceOptionsFrame_OpenToCategory(addonName)
	end,
}

local GOGO_MESSAGES = {
	["auto"] = function(self)
		if self.db.char.autodismount then
			return "Autodismount active - </gogo auto> to toggle"
		else
			return "Autodismount inactive - </gogo auto> to toggle"
		end
	end,
	["genericfastflyer"] = function(self)
		if not self:CanFly() then
			return
		elseif self.db.char.genericfastflyer then
			return "Considering epic flying mounts 310% - 280% speeds the same for random selection - </gogo genericfastflyer> to toggle"
		else
			return "Considering epic flying mounts 310% - 280% speeds different for random selection - </gogo genericfastflyer> to toggle"
		end
	end,
	["ignore"] = function(self)
		local list = ""
		if self.db.char.GlobalIgnoreMounts then
			list = list .. self:GetIDName(self.db.char.GlobalIgnoreMounts)
			msg = "Global Ignore Mounts: "..list
		else
			msg =  "Global Ignore Mounts: ?".." - </gogo ignore ItemLink> or </gogo ignore SpellName> to add"
		end
		if self.db.char.FilteredZones[playerZone] then
			list = list .. self:GetIDName(self.db.char.FilteredZones[playerZone])
			msg = msg .. "\n" .. playerZone ..": "..list.." - Disable global mount preferences to change."
		end
		return msg
	end,
	["pref"] = function(self)
		local msg = ""
		if not self.db.char.GlobalPrefMount then
			local list = ""
			if self.db.char[playerZone] then
				list = list .. self:GetIDName(self.db.char[playerZone])
				msg = playerZone..": "..list.." - </gogo clear> to clear"
			else
				msg = playerZone..": ?".." - </gogo ItemLink> or </gogo SpellName> to add"
			end
			if self.db.char.GlobalPrefMounts then
				list = list .. self:GetIDName(self.db.char.GlobalPrefMounts)
				msg = msg .. "\nGlobal Preferred Mounts: "..list.." - Enable global mount preferences to change."
			end
			return msg
		else
			local list = ""
			if self.db.char.GlobalPrefMounts then
				list = list .. self:GetIDName(self.db.char.GlobalPrefMounts)
				msg = "Global Preferred Mounts: "..list.." - </gogo clear> to clear"
			else
				msg =  "Global Preferred Mounts: ?".." - </gogo ItemLink> or </gogo SpellName> to add"
			end
			if self.db.char[playerZone] then
				list = list .. self:GetIDName(self.db.char[playerZone])
				msg = msg .. "\n" .. playerZone ..": "..list.." - Disable global mount preferences to change."
			end
			return msg
		end
	end,
	["druidclickform"] = function(self)
		if self.db.char.DruidClickForm then
			return "Single click form changes enabled - </gogo druidclickform> to toggle"
		else
			return "Single click form changes disabled - </gogo druidclickform> to toggle"
		end
	end,
	["druidflightform"] = function(self)
		if self.db.char.DruidFlightForm then
			return "Flight Forms always used over flying mounts - </gogo druidflightform> to toggle"
		else
			return "Flighing mounts selected, flight forms if moving - </gogo druidflightform> to toggle"
		end
	end,
	["optiongui"] = function() return "To open the GUI options window - </gogo options>" end,
}

local function parseForItemId(msg)
	local FItemID = string.gsub(msg,".-\124H([^\124]*)\124h.*", "%1");
	local idtype, itemid = strsplit(":",FItemID);
	return idtype, tonumber(itemid)
end

function GoGoMount:ParseSpellbook()
	self.playerSpellbook = {}
	for i = 1, GetNumSpellTabs() do
		local offset, numSlots = select(3, GetSpellTabInfo(i))
		for j = offset+1, offset+numSlots do
			local spellName, _, spellID = GetSpellBookItemName(j, BOOKTYPE_SPELL)
			self.playerSpellbook[spellID] = spellName
		end
	end
end

function GoGoMount:SpellInBook(spell)
	if type(spell) == "function" then
		self:DebugAddLine("Running spell function")
		return spell()
	end
	if addonTable.Debug then
		self:DebugAddLine("Searching for spell", GetSpellInfo(spell), spell)
	end
	local spellInBook = self.playerSpellbook[spell]
	if spellInBook then
		self:DebugAddLine("Found spell", spellInBook)
		return spellInBook
	end
end

local function IsMoving()
    return GetUnitSpeed("player") ~= 0
end

local function IsOnMapID(mapIds)
	if type(mapIds) ~= "table" then
		mapIds = {mapIds}
	end
	local currentMap = C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player"))
	if currentMap then
		for k, mapID in pairs(mapIds) do
			if currentMap.mapID == mapID or currentMap.parentMapID == mapID then
				return true
			end
		end
	end
end

local function FilterMountsIn(PlayerMounts, FilterID)
	local filteredMounts = {}
	for _, MountID in pairs(PlayerMounts) do
		local mountData = addonTable.MountDB[MountID]
		if mountData and mountData[FilterID] then
			tinsert(filteredMounts, MountID)
		end
	end
	return filteredMounts
end

local function FilterMountsOut(PlayerMounts, FilterID)
	local filteredMounts = {}
	for _, MountID in pairs(PlayerMounts) do
		local mountData = addonTable.MountDB[MountID]
		if mountData and not mountData[FilterID] then
			tinsert(filteredMounts, MountID)
		end
	end
	return filteredMounts
end

function GoGoMount:CreateBindings()
	local buttonInfo = {
		{false,nil}, -- main
		{false,true}, -- no flying
		{true,false} -- passenger mounts
	}
	
	for k,v in ipairs(buttonInfo) do
		local newBinding = CreateFrame("BUTTON", "GoGoButton"..k, UIParent, "SecureActionButtonTemplate")
		newBinding:SetAttribute("type", "macro")
		newBinding:SetScript("PreClick", function(btn)
			self:DebugAddLine("BUTTON: Button "..k.." pressed.")
			addonTable.SelectPassengerMount = v[1]
			addonTable.SkipFlyingMount = v[2]
			self:PreClick(btn)
		end)
	end
end

function GoGoMount:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(addonName.."DB", savedDBDefaults)
	self:RegisterChatCommand("gogo", "OnSlash")

	addonTable.TestVersion = false
	addonTable.Debug = true
	playerZone, playerSubZone = GetRealZoneText(), GetSubZoneText()

	self:CreateBindings()

	self:ParseSpellbook()
	self:SetClassSpell()
	self:SKILL_LINES_CHANGED()

	-- Register our options
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, self:GetOptions())
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

	self:RegisterEvent("VARIABLES_LOADED", "UPDATE_BINDINGS")
	self:RegisterEvent("UPDATE_BINDINGS")
	self:RegisterEvent("TAXIMAP_OPENED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED")
	self:RegisterEvent("SPELLS_CHANGED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("SKILL_LINES_CHANGED")
end

function GoGoMount:PLAYER_REGEN_DISABLED()
	for i, button in ipairs({GoGoButton1, GoGoButton2, GoGoButton3}) do
		self:DebugAddLine("Filling", button:GetName())
		self:FillButton(button, self:SpellInBook(self.classSpell))
	end
end

function GoGoMount:SPELLS_CHANGED()
	self:ParseSpellbook()
end

function GoGoMount:UNIT_SPELLCAST_SUCCEEDED(_, unitId, _, spellId)
	if unitId == 'player' and spellId == 55884 then
		self:DebugAddLine("EVENT: Companion Learned")
		self:BuildMountSpellList()
		self:BuildMountList()
	end
end

function GoGoMount:ZONE_CHANGED()
	playerZone = GetRealZoneText()
	playerSubZone = GetSubZoneText()
end

function GoGoMount:TAXIMAP_OPENED()
	self:Dismount()
end

function GoGoMount:UPDATE_BINDINGS()
	if not InCombatLockdown() then  -- ticket 213
		self:CheckBindings()
	end
end

function GoGoMount:UI_ERROR_MESSAGE(event, errorType, errorMsg)
	if self.db.char.autodismount and GOGO_ERRORS[errorMsg] and not IsFlying() then
		self:Dismount()
	end
end

function GoGoMount:PLAYER_ENTERING_WORLD()
	self:DebugAddLine("EVENT: Player Entering World")
	self:BuildMountSpellList()
	self:BuildMountItemList()
	self:BuildMountList()
end

function GoGoMount:SKILL_LINES_CHANGED()
	self:DebugAddLine("Building player skill table")
	for skillIndex = 1, GetNumSkillLines() do
		local skillName, isHeader, _, skillRank = GetSkillLineInfo(skillIndex)
		if not isHeader and addonTable.PlayerSkills[skillName]  then
			addonTable.PlayerSkills[skillName] = skillRank
		end
	end
end

function GoGoMount:OnSlash(msg)
	if GOGO_COMMANDS[string.lower(msg)] then
		GOGO_COMMANDS[string.lower(msg)](self)
	elseif string.find(msg, "ignore") then
		local idtype, itemid = parseForItemId(msg)
		self:AddIgnoreMount(itemid)
		self:Msg("ignore")
	elseif string.find(msg, "spell:%d+") or string.find(msg, "item:%d+") then
		local idtype, itemid = parseForItemId(msg)
		self:AddPrefMount(itemid)
		self:Msg("pref")
	else
		self:Msg("optiongui")
		self:Msg("auto")
		self:Msg("genericfastflyer")
		self:Msg("updatenotice")
		self:Msg("mountnotice")
		if playerClass == "DRUID" then self:Msg("druidclickform") end
		if playerClass == "DRUID" then self:Msg("druidflightform") end
		self:Msg("pref")
	end
end

function GoGoMount:PreClick(button)
	if addonTable.Debug then
		self:DebugAddLine("Starts")
		self:DebugAddLine("Location = " .. GetRealZoneText() .. " - " .. GetZoneText() .. " - " ..GetSubZoneText() .. " - " .. GetMinimapZoneText())
		self:DebugAddLine("Current unit speed is " .. GetUnitSpeed("player"))
		local level = UnitLevel("player")
		self:DebugAddLine("We are level " .. level)
		self:DebugAddLine("We are a " .. playerClass)
		if self:CanFly() then
			self:DebugAddLine("We can fly here as per self:CanFly()")
		else
			self:DebugAddLine("We can not fly here as per self:CanFly()")
		end
		if IsOutdoors() then
			self:DebugAddLine("We are outdoors as per IsOutdoors()")
		else
			self:DebugAddLine("We are not outdoors as per IsOutdoors()")
		end
		if IsIndoors() then
			self:DebugAddLine("We are indoors as per IsIndoors()")
		else
			self:DebugAddLine("We are not indoors as per IsIndoors()")
		end
		if IsFlyableArea() then
			self:DebugAddLine("We can fly here as per IsFlyableArea()")
		else
			self:DebugAddLine("We can not fly here as per IsFlyableArea()")
		end
		if IsFlying() then
			self:DebugAddLine("We are flying as per IsFlying()")
		else
			self:DebugAddLine("We are not flying as per IsFlying()")
		end
		if IsSwimming() then
			self:DebugAddLine("We are swimming as per IsSwimming()")
		else
			self:DebugAddLine("We are not swimming as per IsSwimming()")
		end
		if IsFalling() then
			self:DebugAddLine("We are falling as per IsFalling()")
		else
			self:DebugAddLine("We are not falling as per IsFalling()")
		end
		if IsMoving() then
			self:DebugAddLine("We are moving as per IsMoving()")
		else
			self:DebugAddLine("We are not moving as per IsMoving()")
		end
		local position = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
		self:DebugAddLine("Player location: X = ".. position.x .. ", Y = " .. position.y)
	end

	if not InCombatLockdown() then
		self:FillButton(button)
	end

	if IsMounted() or CanExitVehicle() then
		self:DebugAddLine("Player is mounted and is being dismounted.")
		self:Dismount()
	elseif playerClass == "DRUID" and self:IsShifted() and not InCombatLockdown() then
		self:DebugAddLine("Player is a druid, is shifted and not in combat.")
		self:Dismount(button)
	elseif playerClass == "SHAMAN" and UnitBuff("player", addonTable.SpellDB.GhostWolf) then
		self:DebugAddLine("Player is a shaman and is in wolf form.")
		self:Dismount()
	elseif not InCombatLockdown() then
		self:DebugAddLine("Player not in combat, button pressed, looking for a mount.")
		self:FillButton(button, self:GetMount())
	end
end

function GoGoMount:GetMount()
	if playerClass == "DRUID" then
		if IsIndoors() then
			if IsSwimming() then
				return self:SpellInBook(addonTable.SpellDB.AquaForm)
			elseif select(5, GetTalentInfo(2, 12)) > 0 then
				return self:SpellInBook(addonTable.SpellDB.CatForm)
			end
			return
		end
		if (IsSwimming() or IsFalling() or IsMoving()) then
			if addonTable.Debug then
				self:DebugAddLine("We are a druid and we're falling, swimming or moving.  Changing shape form.")
			end
			return self:SpellInBook(self.classSpell)
		end
	elseif playerClass == "SHAMAN" and IsMoving() then
		if select(5, GetTalentInfo(2, 3)) == 2 then
			if addonTable.Debug then
				self:DebugAddLine("We are a shaman and we're moving.  Changing shape form.")
			end
			return self:SpellInBook(self.classSpell)
		end
	elseif playerClass == "HUNTER" and IsMoving() then
		if addonTable.Debug then
			self:DebugAddLine("We are a hunter and we're moving.  Checking for aspects.")
		end
		local cheetah = self:SpellInBook(addonTable.SpellDB.AspectCheetah)
		if cheetah then
			return cheetah
		end
	end

	self:DebugAddLine("Passed Druid / Shaman forms - nothing selected.")

	local mounts = {}
	local GoGo_FilteredMounts = {}
	local ridingLevel = addonTable.PlayerSkills[L['Riding']]
	if addonTable.Debug then
		for k,v in pairs(addonTable.PlayerSkills) do
			self:DebugAddLine(k, "=", v)
		end
	end

	if #mounts == 0 then
		if self.db.char.FilteredZones[playerZone] then
			GoGo_FilteredMounts = self.db.char.FilteredZones[playerZone]
		end
	end
	self:DebugAddLine("Checked for zone favorites.")

	if #mounts == 0 and not GoGo_FilteredMounts or #GoGo_FilteredMounts == 0 then
		if self.db.char.GlobalPrefMounts then
			GoGo_FilteredMounts = self.db.char.GlobalPrefMounts
		end
		self:DebugAddLine("Checked for global favorites.")
	end

	if #mounts == 0 and not GoGo_FilteredMounts or #GoGo_FilteredMounts == 0 then
		self:DebugAddLine("Checking for spell and item mounts.")
		-- Not updating bag items on bag changes right now so scan and update list
		self:BuildMountItemList()
		self:BuildMountList()
		GoGo_FilteredMounts = addonTable.MountList
		if not GoGo_FilteredMounts or #GoGo_FilteredMounts == 0 then
			if self.classSpell then
				self:DebugAddLine("No mounts found. Forcing "..playerClass.." shape form.")
				return self:SpellInBook(playerClass)
			else
				self:DebugAddLine("No mounts found.  Giving up the search.")
				return
			end
		end
	end
	
	local GoGo_TempMounts = {}
	local engineeringLevel = addonTable.PlayerSkills[GetSpellInfo(addonTable.SpellDB.Tailoring)]
	if engineeringLevel < 375 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 46)
	end
	if engineeringLevel < 300 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 45)
	end

	local tailoringLevel = addonTable.PlayerSkills[GetSpellInfo(addonTable.SpellDB.Tailoring)]
	if tailoringLevel < 450 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 47)
	end
	if tailoringLevel < 425 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 49)
	end
	if tailoringLevel < 300 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 48)
	end

	if IsSwimming() then
		self:DebugAddLine("Forcing ground mounts because we're swimming.")
		addonTable.SkipFlyingMount = true
	else
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 53)
	end
	
	if playerZone ~= L["Ahn'Qiraj"] then
		self:DebugAddLine("Removing AQ40 mounts since we are not in AQ40.")
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 50)
	end

	if addonTable.SelectPassengerMount then
		self:DebugAddLine("Filtering out all mounts except passenger mounts since passenger mount only was requested.")
		GoGo_FilteredMounts = FilterMountsIn(GoGo_FilteredMounts, 2) or {}
	end

	if #mounts == 0 and IsSwimming() then
		self:DebugAddLine("Looking for water speed increase mounts since we're in water.")
		mounts = FilterMountsIn(GoGo_FilteredMounts, 5) or {}
	end
	
	if #mounts == 0 and self:CanFly() and not addonTable.SkipFlyingMount then
		self:DebugAddLine("Looking for flying mounts since we past flight checks.")
		if ridingLevel < 225 then
			GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 36)
		end
		if ridingLevel < 300 then
			GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 35)
		end

		-- Druid stuff... 
		-- Use flight forms if preferred
		if playerClass == "DRUID" and self.db.char.DruidFlightForm and (self:SpellInBook(addonTable.SpellDB.FastFlightForm) or self:SpellInBook(addonTable.SpellDB.FlightForm)) then
			self:DebugAddLine("Druid with preferred flight forms option enabled.  Using flight form.")
			return self:SpellInBook(self.classSpell)
		end
	
		if #mounts == 0 then
			GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 9)
			mounts = FilterMountsIn(GoGo_TempMounts, 24)
		end
		if self.db.char.genericfastflyer then
			local GoGo_TempMountsA = FilterMountsIn(GoGo_TempMounts, 23)
			if ridingLevel < 300 then
				GoGo_TempMountsA = FilterMountsOut(GoGo_TempMountsA, 29)
			end
			if GoGo_TempMountsA then
				for k, v in ipairs(GoGo_TempMountsA) do
					tinsert(mounts, v)
				end
			end
			local GoGo_TempMountsA = FilterMountsIn(GoGo_TempMounts, 26)
			if GoGo_TempMountsA then
				for k, v in ipairs(GoGo_TempMountsA) do
					tinsert(mounts, v)
				end
			end
		end
		if #mounts == 0 then
			GoGo_TempMountsA = FilterMountsIn(GoGo_TempMounts, 23)
			if ridingLevel < 300 then
				mounts = FilterMountsOut(GoGo_TempMountsA, 29)
			else
				mounts = GoGo_TempMountsA
			end
		end

		-- no epic flyers found - add druid swift flight if available
		if #mounts == 0 and playerClass == "DRUID" and self:SpellInBook(addonTable.SpellDB.FastFlightForm) then
			tinsert(mounts, addonTable.SpellDB.FastFlightForm)
		end

		if #mounts == 0 then
			GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 9)
			mounts = FilterMountsIn(GoGo_TempMounts, 22)
		end

		-- no slow flying mounts found - add druid flight if available
		if #mounts == 0 and playerClass == "DRUID" and self:SpellInBook(addonTable.SpellDB.FlightForm) then
			tinsert(mounts, addonTable.SpellDB.FlightForm)
		end
	end
	
	if #GoGo_FilteredMounts >= 1 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 36)
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 35)
	end

	if #mounts == 0 and #GoGo_FilteredMounts >= 1 then  -- no flying mounts selected yet - try to use loaned mounts
		GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 52) or {}
		if #GoGo_TempMounts >= 1 and IsOnMapID(118, 119, 120) then
			mounts = FilterMountsIn(GoGo_FilteredMounts, 52)
		end
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 52)
	end
	
	-- Set the oculus mounts as the only mounts available if we're in the oculus, not skiping flying and have them in inventory
	if #mounts == 0 and #GoGo_FilteredMounts >= 1 and playerZone == L["The Oculus"] and not addonTable.SkipFlyingMount then
		GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 54) or {}
		if #GoGo_TempMounts >= 1 then
			mounts = GoGo_TempMounts
			if addonTable.Debug then
				self:DebugAddLine("In the Oculus, Oculus only mount found, using.")
			end
		else
			if addonTable.Debug then
				self:DebugAddLine("In the Oculus, no oculus mount found in inventory.")
			end
		end
	else
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 54)
		if addonTable.Debug then
			self:DebugAddLine("Not in Oculus or forced ground mount only.")
		end
	end
	
	-- Select ground mounts
	if #mounts == 0 and self:CanRide() then
		self:DebugAddLine("Looking for ground mounts since we can't fly.")
		if ridingLevel < 75 then
			GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 37)
			GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 38)
		elseif ridingLevel < 150 then
			GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 37)
		end
		GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 21)
		if ridingLevel < 150 then
			GoGo_TempMounts = FilterMountsOut(GoGo_TempMounts, 29)
		end
		if ridingLevel <= 225 and self:CanFly() then
			mounts = FilterMountsOut(GoGo_TempMounts, 3)
		else
			mounts = GoGo_TempMounts
		end
		if #mounts == 0 then
			mounts = FilterMountsIn(GoGo_FilteredMounts, 20)
		end
		if #mounts == 0 then
			mounts = FilterMountsIn(GoGo_FilteredMounts, 25)
		end
	end
	
	if #GoGo_FilteredMounts >= 1 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 37)
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 38)
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 21)
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 20)
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 25)
	end
	
	if #mounts == 0 and playerClass == "SHAMAN" and self:SpellInBook(addonTable.SpellDB.GhostWolf) then
		tinsert(mounts, addonTable.SpellDB.GhostWolf)
	end

	if self.db.char.GlobalIgnoreMounts and #self.db.char.GlobalIgnoreMounts > 0 then
		local filteredMounts = {}
		for k,mountId in pairs(mounts) do
			if not self:GlobalIgnoreMountExists(mountId) then
				tinsert(filteredMounts, mountId)
			end
		end
		mounts = filteredMounts
	end

	if #mounts >= 1 then
		if addonTable.Debug then
			for a = 1, #mounts do
				self:DebugAddLine("Found mount", mounts[a], "- included in random pick.")
			end
		end
		selected = mounts[math.random(#mounts)]
		if type(selected) == "string" then
			self:DebugAddLine("Selected string", selected)
			return selected
		else
			selected = self:GetIDName(selected)
			return selected
		end
	end
end

function GoGoMount:Dismount(button)
	if IsMounted() then
		Dismount()
	elseif CanExitVehicle() then	
		VehicleExit()
	elseif playerClass == "DRUID" then
		local isShifted = self:IsShifted()
		if button and isShifted then
			if self.db.char.DruidClickForm and not IsFlying() then
				self:FillButton(button, self:GetMount())
			else
				self:FillButton(button, isShifted)
			end
		end
	elseif playerClass == "SHAMAN" and UnitBuff("player", self:SpellInBook(addonTable.SpellDB.GhostWolf)) then
		CancelUnitBuff("player", self:SpellInBook(addonTable.SpellDB.GhostWolf))
	end
end

function GoGoMount:BuildMountList()
	addonTable.MountList = {}
	for _, v in pairs(addonTable.MountSpellList or {}) do
		tinsert(addonTable.MountList, v)
	end
	for _, v in pairs(addonTable.MountItemList) do
		tinsert(addonTable.MountList, v)
	end
	return addonTable.MountList
end 

function GoGoMount:BuildMountSpellList()
	addonTable.MountSpellList = {}
	local superFastFound
	for slot = 1, GetNumCompanions("MOUNT") do
		local _, _, SpellID = GetCompanionInfo("MOUNT", slot)
		tinsert(addonTable.MountSpellList, SpellID)
		local mountData = addonTable.MountDB[SpellID]
		if mountData and mountData[24] then
			superFastFound = true
		end
	end
	if superFastFound then
		self:ApplySuperFast()
	end
	self:DebugAddLine("Added", #addonTable.MountSpellList, "mounts to spell list.")
	return addonTable.MountSpellList
end

function GoGoMount:BuildMountItemList()
	addonTable.MountItemList = {}
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemId = GetContainerItemID(bag, slot)
			if addonTable.MountsItems[itemId] then
				tinsert(addonTable.MountItemList, itemId)
			end
		end
	end
	self:DebugAddLine("Added", #addonTable.MountItemList, "mounts to item list.")
	return addonTable.MountItemList
end

function GoGoMount:IsShifted()
	for i = 1, GetNumShapeshiftForms() do
		local _, active, _, spellID = GetShapeshiftFormInfo(i)
		if active then
			local name = GetSpellInfo(spellID)
			self:DebugAddLine("Found", name)
			return name, spellID
		end
	end
	self:DebugAddLine("Not shifted")
end

function GoGoMount:GlobalIgnoreMountExists(spell)
	for k, v in pairs(self.db.char.GlobalIgnoreMounts) do
		if v == spell then
			return true
		end
	end
end

function GoGoMount:GlobalPrefMountExists(spell)
	for k, v in pairs(self.db.char.GlobalPrefMounts) do
		if v == spell then
			return true
		end
	end
end

function GoGoMount:AddPrefMount(spell)
	if addonTable.Debug then 
		self:DebugAddLine("Preference " .. spell)
	end

	if not self.db.char.GlobalPrefMount then
		if not self.db.char.FilteredZones[playerZone] then self.db.char.FilteredZones[playerZone] = {} end
		tinsert(self.db.char.FilteredZones[playerZone], spell)
		if #self.db.char.FilteredZones[playerZone] > 1 then
			local i = 2
			repeat
				if self.db.char.FilteredZones[playerZone][i] == self.db.char.FilteredZones[playerZone][i - 1] then
					tremove(self.db.char.FilteredZones[playerZone], i)
				else
					i = i + 1
				end
			until i > #self.db.char.FilteredZones[playerZone]
		end
	else
		if not self.db.char.GlobalPrefMounts then self.db.char.GlobalPrefMounts = {} end
		if not self:GlobalPrefMountExists(spell) then
			tinsert(self.db.char.GlobalPrefMounts, spell)
			if #self.db.char.GlobalPrefMounts > 1 then
				local i = 2
				repeat
					if self.db.char.GlobalPrefMounts[i] == self.db.char.GlobalPrefMounts[i - 1] then
						tremove(self.db.char.GlobalPrefMounts, i)
					else
						i = i + 1
					end
				until i > #self.db.char.GlobalPrefMounts
			end
		end
	end
end

function GoGoMount:AddIgnoreMount(spell)
		if addonTable.Debug then 
			self:DebugAddLine("Preference " .. spell)
		end
		if not self.db.char.GlobalIgnoreMounts then self.db.char.GlobalIgnoreMounts = {} end
		if not self:GlobalIgnoreMountExists(spell) then
			tinsert(self.db.char.GlobalIgnoreMounts, spell)
			if #self.db.char.GlobalIgnoreMounts > 1 then
				local i = 2
				repeat
					if self.db.char.GlobalIgnoreMounts[i] == self.db.char.GlobalIgnoreMounts[i - 1] then
						tremove(self.db.char.GlobalIgnoreMounts, i)
					else
						i = i + 1
					end
				until i > #self.db.char.GlobalIgnoreMounts
			end
		end
end

function GoGoMount:GetIDName(itemid)
	if type(itemid) == "table" then
		local idTable = {}
		for k,tableItem in pairs(itemid) do
			tinsert(idTable, self:GetIDName(tableItem))
		end
		local idString = table.concat(idTable, ", ")
		if addonTable.Debug then
			self:DebugAddLine("Itemname string is " .. idString)
		end
		return idString
	end
	if addonTable.MountDB[itemid] and addonTable.MountDB[itemid][4] == true then
		self:DebugAddLine("GetItemID for", itemid, GetItemInfo(itemid))
		return GetItemInfo(itemid) or "Unknown Mount"
	else
		self:DebugAddLine("GetSpellID for", itemid, GetSpellInfo(itemid))
		return GetSpellInfo(itemid) or "Unknown Mount"
	end
end

function GoGoMount:FillButton(button, mount)
	if mount then
		if addonTable.Debug then 
			self:DebugAddLine("Casting " .. mount)
		end
		button:SetAttribute("macrotext", "/use "..mount)
	else
		button:SetAttribute("macrotext", nil)
	end
end

function GoGoMount:CheckBindings()
	for binding, button in pairs({GOGOBINDING = GoGoButton1, GOGOBINDING2 = GoGoButton2, GOGOBINDING3 = GoGoButton3}) do
		ClearOverrideBindings(button)
		for _, key in ipairs({GetBindingKey(binding)}) do
			if key then
				SetOverrideBindingClick(button, true, key, button:GetName())
			end
		end
	end
end

function GoGoMount:CanFly()
	local level = UnitLevel("player")
	if (level < 60) then
		if addonTable.Debug then
			self:DebugAddLine("Failed - Player under level 60")
		end
		return false
	end
	
	if IsOnMapID(1945) then -- Outlands
		return true
	end

	if IsOnMapID(113) and self:SpellInBook(addonTable.SpellDB.ColdWeatherFlying) then -- On Northrend and know cold weather
		if IsOnMapID(125) then
			if playerSubZone == L["Krasus' Landing"] then
				if not IsFlyableArea() then
					if addonTable.Debug then
						self:DebugAddLine("Failed - Player in " .. L["Krasus' Landing"] .. " and not in flyable area.")
					end
					return false
				end
			elseif playerSubZone == L["The Violet Citadel"] then
				if not IsOutdoors() then
					if addonTable.Debug then
						self:DebugAddLine("Failed - Player in " .. L["The Violet Citadel"] .. " and not outdoors area.")
					end
					return false
				end
				if not IsFlyableArea() then
					if addonTable.Debug then
						self:DebugAddLine("Failed - Player in " .. L["The Violet Citadel"] .. " and not in flyable area.")
					end
					return false
				end
			elseif playerSubZone == L["The Underbelly"] then
				if not IsFlyableArea() then
					if addonTable.Debug then
						self:DebugAddLine("Failed - Player in " .. L["The Underbelly"] .. " and not in flyable area.")
					end
					return false
				end
			elseif playerSubZone == L["Dalaran"] then
				if not IsFlyableArea() then
					if addonTable.Debug then
						self:DebugAddLine("Failed - Player in " .. L["Dalaran"] .. " and not outdoors area.")
					end
					return false
				end
			else
				if addonTable.Debug then
					self:DebugAddLine("Failed - Player in " .. L["Dalaran"] .. " and not in known flyable subzone.")
				end
				return false
			end
		end

		if GetWintergraspWaitTime and IsOnMapID(123) then
			if GetWintergraspWaitTime() then
				if addonTable.Debug then
					self:DebugAddLine("Player in Wintergrasp and battle ground is not active.")
				end
				-- timer ticking to start wg.. we can mount
			else
				if addonTable.Debug then
					self:DebugAddLine("Failed - Player in Wintergrasp and battle ground is active.")
				end
				-- we should be in battle.. can't mount
				return false
			end
		end
		return true
	end

	if addonTable.Debug then
		self:DebugAddLine("Failed - Player does not meet any flyable conditions.")
	end
	return false  -- we can't fly anywhere else
end

function GoGoMount:CanRide()
	local level = UnitLevel("player")
	if level >= 20 then
		if addonTable.Debug then
			self:DebugAddLine("Passed - Player is over level 20.")
		end
		return true
	end
end

local function MountListHasType(mountList, typeId)
	for k, v in pairs(mountList) do
		local mountData = addonTable.MountDB[v]
		if mountData and mountData[typeId] then
			return true
		end
	end
end

function GoGoMount:ApplySuperFast()  -- checks to see if any existing 310% mounts exist to increase the speed of [6] mounts

	if self.SuperFastFlyingFound then
		return
	end
	self:DebugAddLine("Function executed.")

	self.SuperFastFlyingFound = true
	for k, mountData in pairs(addonTable.MountDB) do
		if mountData[6] then
			mountData[24] = true
			self:DebugAddLine("Mount ID " .. k .. " added as 310% flying.")
		end
	end
end

function GoGoMount:Msg(msg,...)
	if msg then
		if GOGO_MESSAGES[msg] then
			self:Msg(GOGO_MESSAGES[msg](self))
		else
			self:Print(msg, ...)
		end
	end
end

function GoGoMount:SetClassSpell()
	local classSpells = {
		["DRUID"] = function()
			local travelForm = self:SpellInBook(addonTable.SpellDB.TravelForm)
			local aquaForm = self:SpellInBook(addonTable.SpellDB.AquaForm)
			if aquaForm then
				local flightForm = (not addonTable.SkipFlyingMount and self:CanFly()) and (self:SpellInBook(addonTable.SpellDB.FastFlightForm) or self:SpellInBook(addonTable.SpellDB.FlightForm))
				if flightForm then
					return "[swimming] "..aquaForm.."; [combat]"..travelForm.."; "..flightForm
				else
					return "[swimming] "..aquaForm.."; "..travelForm
				end
			end
			return travelForm
		end,
		["SHAMAN"] = function()
			return self:SpellInBook(addonTable.SpellDB.GhostWolf)
		end
	}
	self.classSpell = classSpells[playerClass]
	if self.classSpell then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
	end
end

function GoGoMount:DebugAddLine(...)
	if addonTable.Debug then
		local callingFunc = debugstack(2,1,0)
		local funcMatch = strmatch(callingFunc, ("`(.+)'"))
		self:Msg(funcMatch or "", ...)
	end
end

function GoGoMount:GetOptions()
	-- Build options table
	local options = {
		type = "group",
		name = addonName,
		args = {
			druidClickForm = {
				name = L["Single click to shift from form to travel forms"],
				type = "toggle",
				order = 1,
				width = "full",
				get = function() return self.db.char.DruidClickForm end,
				set = function(info, v) self.db.char.DruidClickForm = v end,
			},
			druidFlightForm = {
				name = L["Always use flight forms instead of when moving only"],
				type = "toggle",
				order = 2,
				width = "full",
				get = function() return self.db.char.DruidFlightForm end,
				set = function(info, v) self.db.char.DruidFlightForm = v end,
			},
			autodismount = {
				name = L["Enable automatic dismount"],
				type = "toggle",
				order = 3,
				width = "full",
				get = function() return self.db.char.autodismount end,
				set = function(info, v) self.db.char.autodismount = v end,
			},
			genericfastflyer = {
				name = L["Consider 310% and 280% mounts the same speed"],
				type = "toggle",
				order = 4,
				width = "full",
				get = function() return self.db.char.genericfastflyer end,
				set = function(info, v) self.db.char.genericfastflyer = v end,
			},
			GlobalPrefMount = {
				name = L["Preferred mount changes apply to global setting"],
				type = "toggle",
				order = 5,
				width = "full",
				get = function() return self.db.char.GlobalPrefMount end,
				set = function(info, v) self.db.char.GlobalPrefMount = v end,
			}
		}
	}
	return options
end