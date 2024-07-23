local addonName, addonTable = ...

local tinsert, tconc = tinsert, table.concat
local GetRealZoneText, InCombatLockdown, GetZoneText, GetSubZoneText, IsOutdoors, IsFalling, IsSwimming
	= GetRealZoneText, InCombatLockdown, GetZoneText, GetSubZoneText, IsOutdoors, IsFalling, IsSwimming
local IsMounted, CanExitVehicle, GetMinimapZoneText, UnitAura, GetUnitSpeed, GetNumSkillLines, GetSkillLineInfo, GetSpellBookItemName
	= IsMounted, CanExitVehicle, GetMinimapZoneText, UnitAura, GetUnitSpeed, GetNumSkillLines, GetSkillLineInfo, GetSpellBookItemName
local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local C_Map = C_Map

local GoGoMount = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = GoGoMount
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local _, playerClass = UnitClass("player")

local ridingSkills = {}

local savedDBDefaults = {
	char = {
        autoDismount = true,
		debug = false,
		druidClickForm = true,
		enabled = true,
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

local function IsMoving()
    return GetUnitSpeed("player") ~= 0
end

local GOGO_COMMANDS = {
	["auto"] = function(self)
		self:ToggleCharVar('autoDismount')
		self:Msg("auto")
	end,
	["debug"] = function(self)
		self:ToggleCharVar('debug')
		self:Msg("debug")
	end,
	["druidclickform"] = function(self)
		self:ToggleCharVar('druidClickForm')
		self:Msg("druidClickForm")
	end,
	["help"] = function(self)
		self:Msg("auto")
		self:Msg("updatenotice")
		self:Msg("mountnotice")
		if playerClass == "DRUID" then self:Msg("druidClickForm") end
		self:Msg("pref")
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
	["druidClickForm"] = function(self)
		if self.db.char.druidClickForm then
			return "Single click form changes enabled - </gogo druidclickform> to toggle"
		else
			return "Single click form changes disabled - </gogo druidclickform> to toggle"
		end
	end,
	["optiongui"] = function() return "To open the GUI options window - </gogo options>" end,
}

function GoGoMount:ParseSpellbook()
	for _, v in pairs(addonTable.RidingSkills) do
		ridingSkills[v] = IsPlayerSpell(v)
	end
end

function GoGoMount:SpellInBook(spell)
	if type(spell) == "function" then
		self:DebugAddLine("Running spell function")
		return spell()
	end
	local spellInfo = GetSpellInfo(spell)
	self:DebugAddLine("Searching for spell", spellInfo, spell)
	if IsPlayerSpell(spell) then
		self:DebugAddLine("Found spell", spellInfo)
		return spellInfo
	end
end

function GoGoMount:CancelPlayerBuff(spell)
	CancelSpellByName( type(spell) == "number" and GetSpellInfo(spell) or spell)
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
    local newBinding = CreateFrame("BUTTON", "GoGoButton"..index, UIParent, "SecureActionButtonTemplate")
    newBinding:SetAttribute("type", "macro")
    newBinding:SetScript("PreClick", function(btn)
		self:DebugAddLine("BUTTON:", btn:GetName(), "pressed.")
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

	-- Register our options
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, self:GetOptions())
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("SPELLS_CHANGED")
	self:RegisterEvent("TAXIMAP_OPENED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("UPDATE_BINDINGS")
	self:RegisterEvent("VARIABLES_LOADED", "UPDATE_BINDINGS")
end

function GoGoMount:PLAYER_REGEN_DISABLED()
	for k,button in ipairs(self.bindingsTable) do
		self:DebugAddLine("Filling", button:GetName())
		self:FillButton(button, self:SpellInBook(self.classSpell))
	end
end

function GoGoMount:SPELLS_CHANGED(event)
	self:DebugAddLine(event)
	self:ParseSpellbook()
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
	if self.db.char.autoDismount and GOGO_ERRORS[errorMsg] then
		self:Dismount()
	end
end

function GoGoMount:PLAYER_ENTERING_WORLD(event)
	self:DebugAddLine(event)

	self:ParseSpellbook()
	self:SetClassSpell()
end

function GoGoMount:BAG_UPDATE_DELAYED(event)
	if InCombatLockdown() then
		return
	end
	self:DebugAddLine(event)
	self:BuildMountList()
end

function GoGoMount:OnSlash(input)
	local arg1, arg2 = self:GetArgs(input, 2, 1, input)
	if arg1 then
		if GOGO_COMMANDS[arg1:lower()] then
			GOGO_COMMANDS[arg1:lower()](self, arg2)
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
		self:DebugAddLine("We are level " .. UnitLevel("player"))
		self:DebugAddLine("We are a " .. playerClass)
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
	elseif playerClass == "SHAMAN" and C_UnitAuras.GetPlayerAuraBySpellID(addonTable.SpellDB.GhostWolf) then
		self:DebugAddLine("Player is a shaman and is in wolf form.")
		self:Dismount()
	elseif not InCombatLockdown() then
		self:DebugAddLine("Player not in combat, button pressed, looking for a mount.")
		self:FillButton(button, self:GetMount())
	end
end

local function playerHasTalent(talentKey)
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
		elseif (IsSwimming() or IsFalling() or IsMoving()) then
			self:DebugAddLine("We are a druid and we're falling, swimming or moving.  Changing shape form.")
			return self:SpellInBook(self.classSpell)
		end
	elseif playerClass == "SHAMAN" and IsMoving() and playerHasTalent("ImpGhostWolf") then
		self:DebugAddLine("We are a shaman and we're moving.  Changing shape form.")
		return self:SpellInBook(self.classSpell)
	elseif playerClass == "HUNTER" then
		if self.reapplyHawk and C_UnitAuras.GetPlayerAuraBySpellID(addonTable.SpellDB.AspectCheetah) then
			self:DebugAddLine("We are a hunter, we have cheetah and we previously had hawk.  Reapplying hawk.")
			local hawk = self:SpellInBook(self.reapplyHawk)
			self.reapplyHawk = nil
			if hawk then
				return hawk
			end
		elseif IsMoving() then
			self:DebugAddLine("We are a hunter and we're moving.  Checking for aspects.")
			local hawkID = C_UnitAuras.GetPlayerAuraBySpellID(addonTable.SpellDB.AspectHawk)
			if hawkID then
				self:DebugAddLine("We have aspect of the hawk.")
				self.reapplyHawk = hawkID.spellId
			end
			local cheetah = self:SpellInBook(addonTable.SpellDB.AspectCheetah)
			if cheetah then
				return cheetah
			end
		end
	end

	self:DebugAddLine("Passed Druid / Shaman forms - nothing selected.")

	local mounts = {}

	if self:CanRide() then
		if UnitLevel("player") == 60 and #self.EpicMounts > 0 then
			mounts = self.EpicMounts
		else
			mounts = self.RareMounts
		end
	end

	if self.db.char.debug then
		for k,v in pairs(ridingSkills) do
			self:DebugAddLine(GetSpellInfo(k), "=", v)
		end
	end
	local mountCount = #mounts
	if mountCount == 0 then
		if self.classSpell then
			self:DebugAddLine("No mounts found. Forcing "..playerClass.." shape form.")
			return self:SpellInBook(self.classSpell)
		end
		self:DebugAddLine("No mounts found.  Giving up the search.")
		return
	end
	if self.db.char.debug then
		for a = 1, mountCount do
			self:DebugAddLine("Found mount", mounts[a], "- included in random pick.")
		end
	end
	return mountCount > 1 and mounts[math.random(mountCount)] or mounts[1]
end

function GoGoMount:Dismount(button)
	if IsMounted() then
		Dismount()
	elseif CanExitVehicle and CanExitVehicle() then
		VehicleExit()
	elseif playerClass == "DRUID" and button then
		local isShifted = self:IsShifted()
		if isShifted then
			if self.db.char.druidClickForm then
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
	self.EpicMounts, self.RareMounts = {}, {}
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local item = Item:CreateFromBagAndSlot(bag, slot)
			if not item:IsItemEmpty() and addonTable.MountDB[item:GetItemID()]  then
				local slotInfo = ("%s %s"):format(bag, slot)
				if item:GetItemQuality() > Enum.ItemQuality.Rare then
					tinsert(self.EpicMounts, slotInfo)
				else
					tinsert(self.RareMounts, slotInfo)
				end
			end
		end
	end
	self:DebugAddLine("Added", #self.EpicMounts + #self.RareMounts, "mounts to item list.")
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

function GoGoMount:FillButton(button, mount)
	if mount then
		self:DebugAddLine("Casting", mount)
		button:SetAttribute("macrotext", SLASH_USE1.." "..mount)
	else
		button:SetAttribute("macrotext", nil)
	end
end

function GoGoMount:CanRide()
	for k,v in pairs(ridingSkills) do
		if v then
			self:DebugAddLine("Passed - " ..GetSpellInfo(k).." is known.")
			return true
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
			local shiftInfo = {}
			local catForm = self:SpellInBook(addonTable.SpellDB.CatForm)
			local travelForm = self:SpellInBook(addonTable.SpellDB.TravelForm) or (playerHasTalent("FeralSwiftness") and catForm) or nil
			local aquaForm = self:SpellInBook(addonTable.SpellDB.AquaForm)
			if aquaForm then
				tinsert(shiftInfo, "[swimming] "..aquaForm)
			end
			if travelForm then
				tinsert(shiftInfo, travelForm)
			end
			return tconc(shiftInfo, "; ")
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
		local arg1 = ...
		if type(arg1) == 'function' then
			return self:DebugAddLine(arg1())
		end
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
			autoDismount = {
				name = L["Enable automatic dismount"],
				type = "toggle",
				order = getOrderId(),
				width = "full",
				get = function() return self.db.char.autoDismount end,
				set = function(info, v) self.db.char.autoDismount = v end,
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