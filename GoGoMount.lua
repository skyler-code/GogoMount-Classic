local addonName, addonTable = ...

local tinsert, tremove = tinsert, tremove
local GetRealZoneText, InCombatLockdown, IsFlying, GetZoneText, GetSubZoneText, IsOutdoors, BlizzIsFlyableArea, IsFalling, IsSwimming
	= GetRealZoneText, InCombatLockdown, IsFlying, GetZoneText, GetSubZoneText, IsOutdoors, IsFlyableArea, IsFalling, IsSwimming
local IsMounted, CanExitVehicle, GetMinimapZoneText, UnitAura, GetUnitSpeed, GetNumSkillLines, GetSkillLineInfo, GetSpellBookItemName
	= IsMounted, CanExitVehicle, GetMinimapZoneText, UnitAura, GetUnitSpeed, GetNumSkillLines, GetSkillLineInfo, GetSpellBookItemName
local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetContainerItemID = C_Container and C_Container.GetContainerItemID or GetContainerItemID
local C_Map = C_Map

local GoGoMount = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = GoGoMount
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local isVanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local _, playerClass = UnitClass("player")

local playerZone, playerSubZone
local playerSkills = {
	[GetSpellInfo(addonTable.SpellDB.Engineering)] = 0,
	[GetSpellInfo(addonTable.SpellDB.Tailoring)] = 0,
}

local ridingSkills = isVanilla and {
	[L["Riding"]] = 0,
	[GetSpellInfo(addonTable.SpellDB.KodoRiding)] = 0,
	[GetSpellInfo(addonTable.SpellDB.HorseRiding)] = 0,
	[GetSpellInfo(addonTable.SpellDB.UndeadRiding)] = 0,
} or {
	[L["Riding"]] = 0,
}

local savedDBDefaults = {
	char = {
        autoDismount = true,
		autoLance = true,
		debug = false,
		druidClickForm = true,
		druidFlightForm = true,
		enabled = true,
		filteredZones = {},
		genericFastFlyer = false,
		globalIgnoreMounts = {},
		globalPrefMount = false,
		globalPrefMounts = {},
	},
}

local GOGO_ERRORS = {
	[SPELL_FAILED_NOT_MOUNTED] = true,
	[SPELL_FAILED_NOT_SHAPESHIFT] = true,
	[ERR_ATTACK_MOUNTED] = true,
}

local function OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(addonName)
	InterfaceOptionsFrame_OpenToCategory(addonName)
end

local function NotifyOptionChange()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end

local function tableHasAtLeastOneElement(val)
	if val and type(val) == "table" then
		for k,v in pairs(val) do
			return true
		end
	end
end

local function IsMoving()
    return GetUnitSpeed("player") ~= 0
end

local function IsOnMapID(mapIds)
	if type(mapIds) == "number" then
		mapIds = {mapIds}
	end
	local playerMap = C_Map.GetBestMapForUnit("player")
	if playerMap then
		local currentMap = C_Map.GetMapInfo(playerMap)
		if currentMap then
			for k, mapID in pairs(mapIds) do
				if currentMap.mapID == mapID or currentMap.parentMapID == mapID then
					return true
				end
			end
		end
	end
end

local function IsFlyableArea()
	local isFlyable = BlizzIsFlyableArea()
	-- if isFlyable and playerSubZone == C_Map.GetAreaInfo(4560)  then return false end
	return isFlyable
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

local function parseForItemId(msg)
	local FItemID = string.gsub(msg,".-\124H([^\124]*)\124h.*", "%1");
	local idtype, itemid = strsplit(":",FItemID);
	return idtype, tonumber(itemid)
end

local GOGO_COMMANDS = {
	["auto"] = function(self)
		self:ToggleCharVar('autoDismount')
		self:Msg("auto")
	end,
	["clear"] = function(self)
		if self.db.char.globalPrefMount then
			self:SetCharVar('genericFastFlyer', nil)
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton1, GoGoButton2}) do
					self:FillButton(button)
				end
			end
		else
			self.db.char.filteredZones[playerZone] = nil
			NotifyOptionChange()
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton1, GoGoButton2}) do
					self:FillButton(button)
				end
			end
		end
		self:Msg("pref")
	end,
	["debug"] = function(self)
		self:ToggleCharVar('debug')
		self:Msg("debug")
	end,
	["druidclickform"] = function(self)
		self:ToggleCharVar('druidClickForm')
		self:Msg("druidClickForm")
	end,
	["druidflightform"] = function(self)
		self:ToggleCharVar('druidFlightForm')
		self:Msg("druidFlightForm")
	end,
	["help"] = function(self)
		self:Msg("auto")
		self:Msg("genericFastFlyer")
		self:Msg("updatenotice")
		self:Msg("mountnotice")
		if playerClass == "DRUID" then self:Msg("druidClickForm") end
		if playerClass == "DRUID" then self:Msg("druidFlightForm") end
		self:Msg("pref")
	end,
	["ignore"] = function(self, arg1)
		if arg1 then
			if arg1 == "clear" then
				self.db.char.globalIgnoreMounts = {}
			else
				local idtype, itemid = parseForItemId(arg1)
				if itemid then
					self:ToggleIgnoreMount(itemid)
				end
			end
		end
		self:Msg("ignore")
	end,
	["options"] = OpenOptions,
}

local GOGO_MESSAGES = {
	["debug"] = function(self)
		if self.db.char.debug then
			return "Debug active - </gogo debug> to toggle"
		else
			return "Debug inactive - </gogo debug> to toggle"
		end
	end,
	["auto"] = function(self)
		if self.db.char.autoDismount then
			return "Autodismount active - </gogo auto> to toggle"
		else
			return "Autodismount inactive - </gogo auto> to toggle"
		end
	end,
	["genericFastFlyer"] = function(self)
		if not self:CanFly() then
			return
		elseif self.db.char.genericFastFlyer then
			return "Considering epic flying mounts 310% - 280% speeds the same for random selection - </gogo genericFastFlyer> to toggle"
		else
			return "Considering epic flying mounts 310% - 280% speeds different for random selection - </gogo genericFastFlyer> to toggle"
		end
	end,
	["ignore"] = function(self)
		local list = ""
		if tableHasAtLeastOneElement(self.db.char.globalIgnoreMounts) then
			list = list .. self:GetIDName(self.db.char.globalIgnoreMounts)
			msg = "Global Ignore Mounts: "..list
		else
			msg =  "Global Ignore Mounts: ?".." - </gogo ignore ItemLink> or </gogo ignore SpellName> to add"
		end
		if tableHasAtLeastOneElement(self.db.char.filteredZones[playerZone]) then
			list = list .. self:GetIDName(self.db.char.filteredZones[playerZone])
			msg = msg .. "\n" .. playerZone ..": "..list.." - Disable global mount preferences to change."
		end
		return msg
	end,
	["pref"] = function(self)
		local msg = ""
		if not self.db.char.globalPrefMount then
			local list = ""
			if self.db.char[playerZone] then
				list = list .. self:GetIDName(self.db.char[playerZone])
				msg = playerZone..": "..list.." - </gogo clear> to clear"
			else
				msg = playerZone..": ?".." - </gogo ItemLink> or </gogo SpellName> to add"
			end
			if self.db.char.globalPrefMounts then
				list = list .. self:GetIDName(self.db.char.globalPrefMounts)
				msg = msg .. "\nGlobal Preferred Mounts: "..list.." - Enable global mount preferences to change."
			end
			return msg
		else
			local list = ""
			if self.db.char.globalPrefMounts then
				list = list .. self:GetIDName(self.db.char.globalPrefMounts)
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
	["druidClickForm"] = function(self)
		if self.db.char.druidClickForm then
			return "Single click form changes enabled - </gogo druidclickform> to toggle"
		else
			return "Single click form changes disabled - </gogo druidclickform> to toggle"
		end
	end,
	["druidFlightForm"] = function(self)
		if self.db.char.druidFlightForm then
			return "Flight Forms always used over flying mounts - </gogo druidflightform> to toggle"
		else
			return "Flighing mounts selected, flight forms if moving - </gogo druidflightform> to toggle"
		end
	end,
	["optiongui"] = function() return "To open the GUI options window - </gogo options>" end,
}

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
	self:DebugAddLine("Searching for spell", GetSpellInfo(spell), spell)
	local spellInBook = self.playerSpellbook[spell]
	if spellInBook then
		self:DebugAddLine("Found spell", spellInBook)
		return spellInBook
	end
end

function GoGoMount:GetPlayerAura(spell, filter)
	if filter and not filter:upper():find("FUL") then
		filter = filter.."|HELPFUL"
	end
	for i = 1, 255 do
		local name, _, _, _, _, _, _, _, _, spellId = UnitAura("player", i, filter)
		if not name then return end
		if spell == spellId or spell == name then
			return i, UnitAura("player", i, filter)
		end
	end
end

function GoGoMount:CancelPlayerBuff(spell)
	local auraIndex = self:GetPlayerAura(spell)
	if auraIndex then
		CancelUnitBuff("player", auraIndex)
	end
end

function GoGoMount:SetCharVar(varName, value)
	self.db.char[varName] = value
	NotifyOptionChange()
end

function GoGoMount:ToggleCharVar(varName)
	self:SetCharVar(varName, not self.db.char[varName])
end

function GoGoMount:GetBindingFrame(index)
    if not self.bindingsTable then self.bindingsTable = {} end
    if self.bindingsTable[index] then
        return self.bindingsTable[index]
    end
    local newBinding = CreateFrame("BUTTON", self:GetName()..index, UIParent, "SecureActionButtonTemplate")
    newBinding:SetAttribute("type", "macro")
    newBinding:SetScript("PreClick", function(btn)
		self:DebugAddLine("BUTTON:", btn:GetName(), "pressed.")
		local bindingInfo = addonTable.bindings[index]
		self.SelectPassengerMount = bindingInfo.SelectPassengerMount
		self.SkipFlyingMount = bindingInfo.SkipFlyingMount
		self:PreClick(btn)
    end)
    self.bindingsTable[index] = newBinding
    return newBinding
end

function GoGoMount:CheckBindings()
    if InCombatLockdown() then return end
    for k in ipairs(addonTable.bindings) do
        local button = self:GetBindingFrame(k)
		ClearOverrideBindings(button)
		for _, key in ipairs({GetBindingKey(addonName:upper().."BINDING"..k)}) do
			if key then
				SetOverrideBindingClick(button, true, key, button:GetName())
			end
		end
    end
end

function GoGoMount:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(addonName.."DB", savedDBDefaults)
	self:RegisterChatCommand(addonName, "OnSlash")
	self:RegisterChatCommand("gogo", "OnSlash")

	playerZone, playerSubZone = GetRealZoneText(), GetSubZoneText()

	-- Register our options
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, self:GetOptions())
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("SPELLS_CHANGED")
	if not isVanilla then
		self:RegisterEvent("COMPANION_LEARNED")
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:RegisterEvent("UNIT_EXITED_VEHICLE")
	end
	self:RegisterEvent("TAXIMAP_OPENED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("UPDATE_BINDINGS")
	self:RegisterEvent("VARIABLES_LOADED", "UPDATE_BINDINGS")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED")
end

function GoGoMount:PLAYER_REGEN_DISABLED()
	for i, button in ipairs({GoGoButton1, GoGoButton2, GoGoButton3}) do
		self:DebugAddLine("Filling", button:GetName())
		self:FillButton(button, self:SpellInBook(self.classSpell))
	end
end

function GoGoMount:SPELLS_CHANGED(event)
	self:DebugAddLine(event)
	self:ParseSpellbook()
end

function GoGoMount:COMPANION_LEARNED(event)
	self:DebugAddLine(event)
	self:ParseSpellbook()
end

function GoGoMount:UNIT_SPELLCAST_SUCCEEDED(_, unitId, _, spellId)
	if unitId == "player" and spellId == 55884 then
		self:DebugAddLine("EVENT: Companion Learned")
		self:BuildMountSpellList()
		self:BuildMountList()
	end
end

function GoGoMount:ZONE_CHANGED(event)
	self:DebugAddLine(event)
	playerZone = GetRealZoneText()
	playerSubZone = GetSubZoneText()
end

function GoGoMount:TAXIMAP_OPENED(event)
	self:DebugAddLine(event)
	if self.db.char.autoDismount then	
		self:Dismount()
	end
end

function GoGoMount:UPDATE_BINDINGS(event)
	self:DebugAddLine(event)
	self:CheckBindings()
end

function GoGoMount:UI_ERROR_MESSAGE(event, errorType, errorMsg)
	if self.db.char.autoDismount and GOGO_ERRORS[errorMsg] and not IsFlying() then
		self:Dismount()
	end
	if self.db.char.autoLance and errorMsg == SPELL_FAILED_CUSTOM_ERROR_60 then
		self:EquipLance()
	end
end

function GoGoMount:UNIT_EXITED_VEHICLE(event)
	if self.prevItem then
		EquipItemByName(self.prevItem)
		self.prevItem = nil
	end
end

function GoGoMount:PLAYER_ENTERING_WORLD(event)
	self:DebugAddLine(event)
	self:BuildMountSpellList()
	self:BuildMountList()

	self:ParseSpellbook()
	self:SetClassSpell()
end

function GoGoMount:SKILL_LINES_CHANGED(event)
	self:DebugAddLine(event)
	for skillIndex = 1, GetNumSkillLines() do
		local skillName, isHeader, _, skillRank = GetSkillLineInfo(skillIndex)
		if not isHeader then
			if playerSkills[skillName] then
				playerSkills[skillName] = skillRank
			end
			if ridingSkills[skillName] then
				ridingSkills[skillName] = skillRank
			end
		end
	end
end

function GoGoMount:BAG_UPDATE_DELAYED(event)
	self:DebugAddLine(event)
	self:BuildMountItemList()
	self:BuildMountList()
end

local lanceIds = {
	46070, -- Horde Lance
	46069, -- Alliance Lance
	46106, -- Argent Lance
}

function GoGoMount:EquipLance()
	for k,v in ipairs(lanceIds) do
		if GetItemCount(v) > 0 then
			self.prevItem = GetInventoryItemID("player", INVSLOT_MAINHAND)
			EquipItemByName(v)
			break
		end
	end
end

function GoGoMount:OnSlash(input)
	local arg1, arg2 = self:GetArgs(input, 2, 1, input)
	if arg1 then
		if GOGO_COMMANDS[arg1:lower()] then
			GOGO_COMMANDS[arg1:lower()](self, arg2)
		elseif arg1:find("spell:%d+") or arg1:find("item:%d+") then
			local idtype, itemid = parseForItemId(arg1)
			self:AddPrefMount(itemid)
			self:Msg("pref")
		end
	else
		OpenOptions()
	end
end

function GoGoMount:PreClick(button)
	if self.db.char.debug then
		self:DebugAddLine("Starts")
		self:DebugAddLine("Location = " .. GetRealZoneText() .. " - " .. GetZoneText() .. " - " ..GetSubZoneText() .. " - " .. GetMinimapZoneText())
		self:DebugAddLine("Current unit speed is " .. GetUnitSpeed("player"))
		local level = UnitLevel("player")
		self:DebugAddLine("We are level " .. level)
		self:DebugAddLine("We are a " .. playerClass)
		local canFly = self:CanFly()
		if canFly then
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

	if IsMounted() or (CanExitVehicle and CanExitVehicle()) then
		self:DebugAddLine("Player is mounted and is being dismounted.")
		self:Dismount()
	elseif playerClass == "DRUID" and not InCombatLockdown() and self:IsShifted() then
		self:DebugAddLine("Player is a druid, is shifted and not in combat.")
		self:Dismount(button)
	elseif playerClass == "SHAMAN" and self:GetPlayerAura(addonTable.SpellDB.GhostWolf) then
		self:DebugAddLine("Player is a shaman and is in wolf form.")
		self:Dismount()
	elseif not InCombatLockdown() then
		self:DebugAddLine("Player not in combat, button pressed, looking for a mount.")
		self:FillButton(button, self:GetMount())
	end
end

function playerHasTalent(talentKey)
	local talentInfo = addonTable.TalentIndexDB[talentKey]
	if not talentInfo then return false end

	local tier, column, minRank = unpack(talentInfo)
	return select(5, GetTalentInfo(tier, column)) >= minRank
end

function GoGoMount:GetMount()
	if playerClass == "DRUID" then
		if IsIndoors() then
			if IsSwimming() then
				return self:SpellInBook(addonTable.SpellDB.AquaForm)
			elseif playerHasTalent("FeralSwiftness") then
				return self:SpellInBook(addonTable.SpellDB.CatForm)
			end
			return
		end
		if (IsSwimming() or IsFalling() or IsMoving()) then
			self:DebugAddLine("We are a druid and we're falling, swimming or moving.  Changing shape form.")
			return self:SpellInBook(self.classSpell)
		end
	elseif playerClass == "SHAMAN" and IsOutdoors() and IsMoving() and playerHasTalent("ImpGhostWolf") then
		self:DebugAddLine("We are a shaman, we're outdoors, and we're moving.  Changing shape form.")
		return self:SpellInBook(self.classSpell)
	elseif playerClass == "HUNTER" and IsMoving() then
		self:DebugAddLine("We are a hunter and we're moving.  Checking for aspects.")
		local cheetah = self:SpellInBook(addonTable.SpellDB.AspectCheetah)
		if cheetah then
			return cheetah
		end
	end

	self:DebugAddLine("Passed Druid / Shaman forms - nothing selected.")

	local mounts = {}
	local GoGo_FilteredMounts = {}
	local ridingLevel = ridingSkills[L['Riding']]
	if self.db.char.debug then
		for k,v in pairs(playerSkills) do
			self:DebugAddLine(k, "=", v)
		end
		for k,v in pairs(ridingSkills) do
			self:DebugAddLine(k, "=", v)
		end
	end

	if #mounts == 0 then
		if self.db.char.filteredZones[playerZone] then
			GoGo_FilteredMounts = self.db.char.filteredZones[playerZone]
		end
	end
	self:DebugAddLine("Checked for zone favorites.")

	if #mounts == 0 and not GoGo_FilteredMounts or #GoGo_FilteredMounts == 0 then
		if self.db.char.globalPrefMounts then
			GoGo_FilteredMounts = self.db.char.globalPrefMounts
		end
		self:DebugAddLine("Checked for global favorites.")
	end

	if #mounts == 0 and not GoGo_FilteredMounts or #GoGo_FilteredMounts == 0 then
		self:DebugAddLine("Checking for spell and item mounts.")
		GoGo_FilteredMounts = self.MountList
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
	local engineeringLevel = playerSkills[GetSpellInfo(addonTable.SpellDB.Tailoring)]
	if engineeringLevel < 375 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 46)
	end
	if engineeringLevel < 300 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 45)
	end

	local tailoringLevel = playerSkills[GetSpellInfo(addonTable.SpellDB.Tailoring)]
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
		self.SkipFlyingMount = true
	else
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 53)
	end
	
	if playerZone ~= C_Map.GetMapInfo(319).name then
		self:DebugAddLine("Removing AQ40 mounts since we are not in AQ40.")
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 50)
	end

	if self.SelectPassengerMount then
		self:DebugAddLine("Filtering out all mounts except passenger mounts since passenger mount only was requested.")
		GoGo_FilteredMounts = FilterMountsIn(GoGo_FilteredMounts, 2) or {}
	end

	if #mounts == 0 and IsSwimming() then
		self:DebugAddLine("Looking for water speed increase mounts since we're in water.")
		mounts = FilterMountsIn(GoGo_FilteredMounts, 5) or {}
	end

	local canFly = self:CanFly()
	
	if #mounts == 0 and canFly and not self.SkipFlyingMount then
		self:DebugAddLine("Looking for flying mounts since we past flight checks.")
		if ridingLevel < 225 then
			GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 36)
		end
		if ridingLevel < 300 then
			GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 35)
		end

		-- Druid stuff... 
		-- Use flight forms if preferred
		if playerClass == "DRUID" and self.db.char.druidFlightForm and (self:SpellInBook(addonTable.SpellDB.FlightForm) or self:SpellInBook(addonTable.SpellDB.FastFlightForm)) then
			self:DebugAddLine("Druid with preferred flight forms option enabled.  Using flight form.")
			return self:SpellInBook(self.classSpell)
		end
	
		if #mounts == 0 then
			GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 9)
			mounts = FilterMountsIn(GoGo_TempMounts, 24)
		end
		if self.db.char.genericFastFlyer then
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
		if not isVanilla and #mounts == 0 and playerClass == "DRUID" and self:SpellInBook(addonTable.SpellDB.FastFlightForm) then
			tinsert(mounts, addonTable.SpellDB.FastFlightForm)
		end

		if #mounts == 0 then
			GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 9)
			mounts = FilterMountsIn(GoGo_TempMounts, 22)
		end

		-- no slow flying mounts found - add druid flight if available
		if not isVanilla and #mounts == 0 and playerClass == "DRUID" and self:SpellInBook(addonTable.SpellDB.FlightForm) then
			tinsert(mounts, addonTable.SpellDB.FlightForm)
		end
	end
	
	if #GoGo_FilteredMounts >= 1 then
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 36)
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 35)
	end

	if not isVanilla and #mounts == 0 and #GoGo_FilteredMounts >= 1 then  -- no flying mounts selected yet - try to use loaned mounts
		GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 52) or {}
		if #GoGo_TempMounts >= 1 and IsOnMapID({118, 119, 120}) then
			mounts = FilterMountsIn(GoGo_FilteredMounts, 52)
		end
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 52)
	end
	
	-- Set the oculus mounts as the only mounts available if we're in the oculus, not skiping flying and have them in inventory
	if not isVanilla and #mounts == 0 and #GoGo_FilteredMounts >= 1 and playerZone == L["The Oculus"] and not self.SkipFlyingMount then
		GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 54) or {}
		if #GoGo_TempMounts >= 1 then
			mounts = GoGo_TempMounts
			self:DebugAddLine("In the Oculus, Oculus only mount found, using.")
		else
			self:DebugAddLine("In the Oculus, no oculus mount found in inventory.")
		end
	else
		GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 54)
		self:DebugAddLine("Not in Oculus or forced ground mount only.")
	end
	
	-- Select ground mounts
	if #mounts == 0 then
		if self:CanRide() then
			self:DebugAddLine("Looking for ground mounts since we can't fly.")
			local canUseEpic = ridingLevel >= 150 or (isVanilla and UnitLevel("player") == 60)
			if not canUseEpic then
				GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 37)
			end
			GoGo_TempMounts = FilterMountsIn(GoGo_FilteredMounts, 21)
			if not canUseEpic then
				GoGo_TempMounts = FilterMountsOut(GoGo_TempMounts, 29)
			end
			if ridingLevel <= 225 and canFly then
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
		else
			GoGo_FilteredMounts = FilterMountsOut(GoGo_FilteredMounts, 38)
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

	if tableHasAtLeastOneElement(self.db.char.globalIgnoreMounts) then
		local filteredMounts = {}
		for k,mountId in pairs(mounts) do
			if not self.db.char.globalIgnoreMounts[mountId] then
				tinsert(filteredMounts, mountId)
			end
		end
		mounts = filteredMounts
	end

	if #mounts >= 1 then
		if self.db.char.debug then
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
	elseif CanExitVehicle and CanExitVehicle() then	
		VehicleExit()
	elseif playerClass == "DRUID" and button then
		local isShifted = self:IsShifted()
		if isShifted then
			if self.db.char.druidClickForm and not IsFlying() then
				self:FillButton(button, self:GetMount())
			else
				self:FillButton(button, isShifted)
			end
		end
	elseif playerClass == "SHAMAN" and self:SpellInBook(addonTable.SpellDB.GhostWolf) then
		self:CancelPlayerBuff(addonTable.SpellDB.GhostWolf)
	end
end

function GoGoMount:BuildMountList()
	self.MountList = {}
	for _,list in pairs({'Spell', 'Item'}) do
		for _, mountID in pairs(self["Mount"..list.."List"] or {}) do
			tinsert(self.MountList, mountID)
		end
	end
	return self.MountList
end 

function GoGoMount:BuildMountSpellList()
	self.MountSpellList = {}
	local superFastFound
	if not isVanilla then
		for slot = 1, GetNumCompanions("MOUNT") do
			local _, _, SpellID = GetCompanionInfo("MOUNT", slot)
			tinsert(self.MountSpellList, SpellID)
			local mountData = addonTable.MountDB[SpellID]
			if mountData and mountData[24] then
				superFastFound = true
			end
		end
		if superFastFound and not self.SuperFastFlyingFound then
			self:ApplySuperFast()
		end
	end
	self:DebugAddLine("Added", #self.MountSpellList, "mounts to spell list.")
	return self.MountSpellList
end

function GoGoMount:BuildMountItemList()
	self.MountItemList = {}
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemId = GetContainerItemID(bag, slot)
			if addonTable.MountsItems[itemId] then
				tinsert(self.MountItemList, itemId)
			end
		end
	end
	self:DebugAddLine("Added", #self.MountItemList, "mounts to item list.")
	return self.MountItemList
end

function GoGoMount:IsShifted()
	local currentForm = GetShapeshiftForm()
	if currentForm > 0 then
		local _, active, _, spellID = GetShapeshiftFormInfo(currentForm)
		if active then
			local name = GetSpellInfo(spellID)
			self:DebugAddLine("Found", name)
			return name, spellID
		end
	end
	self:DebugAddLine("Not shifted")
end

function GoGoMount:globalPrefMountExists(spell)
	for k, v in pairs(self.db.char.globalPrefMounts) do
		if v == spell then
			return true
		end
	end
end

function GoGoMount:AddPrefMount(spell)
	self:DebugAddLine("Preference " .. spell)

	if not self.db.char.globalPrefMount then
		if not self.db.char.filteredZones[playerZone] then self.db.char.filteredZones[playerZone] = {} end
		tinsert(self.db.char.filteredZones[playerZone], spell)
		if #self.db.char.filteredZones[playerZone] > 1 then
			local i = 2
			repeat
				if self.db.char.filteredZones[playerZone][i] == self.db.char.filteredZones[playerZone][i - 1] then
					tremove(self.db.char.filteredZones[playerZone], i)
				else
					i = i + 1
				end
			until i > #self.db.char.filteredZones[playerZone]
		end
	else
		if not self.db.char.globalPrefMounts then self.db.char.globalPrefMounts = {} end
		if not self:globalPrefMountExists(spell) then
			tinsert(self.db.char.globalPrefMounts, spell)
			if #self.db.char.globalPrefMounts > 1 then
				local i = 2
				repeat
					if self.db.char.globalPrefMounts[i] == self.db.char.globalPrefMounts[i - 1] then
						tremove(self.db.char.globalPrefMounts, i)
					else
						i = i + 1
					end
				until i > #self.db.char.globalPrefMounts
			end
		end
	end
end

function GoGoMount:ToggleIgnoreMount(spell)
	if self.db.char.globalIgnoreMounts[spell] then
		self:DebugAddLine("Preference remove" .. spell)
		self.db.char.globalIgnoreMounts[spell] = nil
	else
		self:DebugAddLine("Preference added" .. spell)
		self.db.char.globalIgnoreMounts[spell] = spell
	end
end

function GoGoMount:GetIDName(itemid)
	if type(itemid) == "table" then
		local idTable = {}
		for k,tableItem in pairs(itemid) do
			local valToUse = tableItem == true and k or tableItem
			tinsert(idTable, self:GetIDName(valToUse))
		end
		local idString = table.concat(idTable, ", ")
		self:DebugAddLine("Itemname string is " .. idString)
		return idString
	end
	if addonTable.MountDB[itemid] and addonTable.MountDB[itemid][4] == true then
		if self.db.char.debug then
			self:DebugAddLine("GetItemInfo for", itemid, GetItemInfo(itemid))
		end
		return GetItemInfo(itemid) or "Unknown Mount"
	else
		if self.db.char.debug then
			self:DebugAddLine("GetSpellInfo for", itemid, GetSpellInfo(itemid))
		end
		return GetSpellInfo(itemid) or "Unknown Mount"
	end
end

function GoGoMount:FillButton(button, mount)
	if mount then
		self:DebugAddLine("Casting " .. mount)
		button:SetAttribute("macrotext", SLASH_USE1.." "..mount)
	else
		button:SetAttribute("macrotext", nil)
	end
end

function GoGoMount:CanFly()
	if isVanilla then
		self:DebugAddLine("Failed - Flying Doesn't Exist In Vanilla")
		return false
	end

	if UnitLevel("player") < 60 then
		self:DebugAddLine("Failed - Player under level 60")
		return false
	end
	
	if IsOnMapID(1945) then -- Outlands
		return true
	end

	if self:SpellInBook(addonTable.SpellDB.ColdWeatherFlying) then -- On Northrend and know cold weather
		if IsOnMapID(113) then
			if IsOnMapID(125) then
				if playerSubZone == C_Map.GetAreaInfo(4564) then
					if not IsFlyableArea() then
						self:DebugAddLine("Failed - Player in " .. playerSubZone .. " and not in flyable area.")
						return false
					end
				elseif playerSubZone == C_Map.GetAreaInfo(4619) then -- The Violet Citadel
					if not IsOutdoors() then
						self:DebugAddLine("Failed - Player in " .. playerSubZone.. " and not outdoors area.")
						return false
					end
					if not IsFlyableArea() then
						self:DebugAddLine("Failed - Player in " .. playerSubZone .. " and not in flyable area.")
						return false
					end
					return false
				elseif playerSubZone == C_Map.GetAreaInfo(4560) then -- The Underbelly
					
					return false
				elseif playerSubZone == C_Map.GetAreaInfo(4395) then
					if not IsFlyableArea() then
						self:DebugAddLine("Failed - Player in " .. playerSubZone .. " and not outdoors area.")
						return false
					end
					return false
				else
					self:DebugAddLine("Failed - Player in " .. playerSubZone .. " and not in known flyable subzone.")
					return false
				end
			end

			if not IsFlyableArea() then
				self:DebugAddLine("Failed - Player in " .. playerSubZone .. " and not outdoors area.")
				return false
			end

			return true
		elseif IsOnMapID(126) then --Underbelly
			if not IsFlyableArea() then
				self:DebugAddLine("Failed - Player in " .. playerSubZone .. " and not outdoors area.")
				return false
			end
			return true
		end
	end

	self:DebugAddLine("Failed - Player does not meet any flyable conditions.")
	return false  -- we can't fly anywhere else
end

function GoGoMount:CanRide()
	for k,v in pairs(ridingSkills) do
		if v > 0 then
			self:DebugAddLine("Passed - Player " ..k.." level is "..v..'.')
			return true
		end
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
			local travelForm = self:SpellInBook(addonTable.SpellDB.TravelForm) or (playerHasTalent("FelineSwiftness") and self:SpellInBook(addonTable.SpellDB.CatForm)) or nil
			local aquaForm = self:SpellInBook(addonTable.SpellDB.AquaForm)
			local catForm = self:SpellInBook(addonTable.SpellDB.CatForm)
			if aquaForm then
				local flightForm = (not self.SkipFlyingMount and self:CanFly()) and (self:SpellInBook(addonTable.SpellDB.FastFlightForm) or self:SpellInBook(addonTable.SpellDB.FlightForm))
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
	if self.db.char.debug then
		local callingFunc = debugstack(2,1,0)
		local funcMatch = strmatch(callingFunc, ("`(.+)'"))
		self:Msg(funcMatch or "", ...)
	end
end

function GoGoMount:GetOptions()
	local orderId = 0
	local function getOrderId()
		orderId = orderId + 1
		return orderId + 1
	end
	-- Build options table
	local options = {
		type = "group",
		name = addonName,
		args = {
			druidClickForm = {
				name = L["Single click to shift from form to travel forms"],
				type = "toggle",
				order = getOrderId(),
				width = "full",
				get = function() return self.db.char.druidClickForm end,
				set = function(info, v) self.db.char.druidClickForm = v end,
			},
			druidFlightForm = {
				name = L["Always use flight forms instead of when moving only"],
				type = "toggle",
				order = getOrderId(),
				hidden = isVanilla,
				width = "full",
				get = function() return self.db.char.druidFlightForm end,
				set = function(info, v) self.db.char.druidFlightForm = v end,
			},
			autoDismount = {
				name = L["Enable automatic dismount"],
				type = "toggle",
				order = getOrderId(),
				width = "full",
				get = function() return self.db.char.autoDismount end,
				set = function(info, v) self.db.char.autoDismount = v end,
			},
			genericFastFlyer = {
				name = L["Consider 310% and 280% mounts the same speed"],
				type = "toggle",
				order = getOrderId(),
				width = "full",
				hidden = isVanilla,
				get = function() return self.db.char.genericFastFlyer end,
				set = function(info, v) self.db.char.genericFastFlyer = v end,
			},
			globalPrefMount = {
				name = L["Preferred mount changes apply to global setting"],
				type = "toggle",
				order = getOrderId(),
				width = "full",
				get = function() return self.db.char.globalPrefMount end,
				set = function(info, v) self.db.char.globalPrefMount = v end,
			},
			autoLance = {
				name = L["Automatically equip lance when trying to mount argent steeds."],
				type = "toggle",
				order = getOrderId(),
				width = "full",
				hidden = isVanilla,
				get = function() return self.db.char.autoLance end,
				set = function(info, v) self.db.char.autoLance = v end,
			},
			debug = {
				name = L["Print Debug messages"],
				type = "toggle",
				order = getOrderId(),
				width = "full",
				get = function() return self.db.char.debug end,
				set = function(info, v) self.db.char.debug = v end,
			}
		}
	}
	return options
end