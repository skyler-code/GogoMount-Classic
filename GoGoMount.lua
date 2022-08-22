local addonName, addonTable = ...

local GoGoMount = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local tinsert, tremove = tinsert, tremove
local C_Map = C_Map

local function GetZoneNames(mapId)
	local zoneStr = ""
	local zones = C_Map.GetMapChildrenInfo(mapId)
	if zones then
		for i, zoneInfo in ipairs(zones) do
			zoneStr = zoneStr .. zoneInfo.name .. ":"
		end
	end
	return zoneStr
end

local function parseForItemId(msg)
	local FItemID = string.gsub(msg,".-\124H([^\124]*)\124h.*", "%1");
	local idtype, itemid = strsplit(":",FItemID);
	return idtype, tonumber(itemid)
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
			if addonTable.Debug then GoGo_DebugAddLine("BUTTON: Button "..k.." pressed.") end
			addonTable.SelectPassengerMount = v[1]
			addonTable.SkipFlyingMount = v[2]
			GoGo_PreClick(btn)
		end)
	end
end

function GoGoMount:OnInitialize()
	self:RegisterChatCommand("gogo", 'OnSlash')

	self:CreateBindings()

	-- Register our options
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, self:GetOptions())
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("UPDATE_BINDINGS")
	self:RegisterEvent("TAXIMAP_OPENED")
	self:RegisterEvent("COMPANION_LEARNED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

function GoGoMount:VARIABLES_LOADED()
	GoGo_DebugLog = {}
	if not GoGo_Prefs then
		GoGo_Prefs = {}
		GoGo_Settings_Default()
	end

	addonTable.TestVersion = false
	addonTable.Debug = false
	_, addonTable.Player.Class = UnitClass("player")
	if (addonTable.Player.Class == "DRUID") then
		addonTable.Druid = {}
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
	elseif (addonTable.Player.Class == "SHAMAN") then
		addonTable.Shaman = {}
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
	end
	GOGO_OUTLANDS = GetZoneNames(1945)..addonTable.Localize.Zone.TwistingNether
	GOGO_NORTHREND = GetZoneNames(113)..addonTable.Localize.Zone.TheFrozenSea
	addonTable.Player.Zone = GetRealZoneText()
end

function GoGoMount:PLAYER_REGEN_DISABLED()
	for i, button in ipairs({GoGoButton1, GoGoButton2, GoGoButton3}) do
		if addonTable.Player.Class == "SHAMAN" then
			GoGo_FillButton(button, GoGo_InBook(GOGO_SPELLS["SHAMAN"]))
		elseif addonTable.Player.Class == "DRUID" then
			GoGo_FillButton(button, GoGo_InBook(GOGO_SPELLS["DRUID"]))
		end
	end
end

function GoGoMount:ZONE_CHANGED_NEW_AREA()
	addonTable.Player.Zone = GetRealZoneText()
end

function GoGoMount:TAXIMAP_OPENED()
	GoGo_Dismount()
end

function GoGoMount:UPDATE_BINDINGS()
	if not InCombatLockdown() then  -- ticket 213
		GoGo_CheckBindings()
	end
end

function GoGoMount:UI_ERROR_MESSAGE()
	if GOGO_ERRORS[arg1] and not IsFlying() then
		GoGo_Dismount()
	end
end

function GoGoMount:PLAYER_ENTERING_WORLD()
	if addonTable.Debug then
		GoGo_DebugAddLine("EVENT: Player Entering World")
	end
	GoGo_BuildMountSpellList()
	GoGo_BuildMountItemList()
	GoGo_BuildMountList()
	GoGo_CheckFor310()
end

function GoGoMount:COMPANION_LEARNED()
	if addonTable.Debug then
		GoGo_DebugAddLine("EVENT: Companion Learned")
	end
	GoGo_BuildMountSpellList()
	GoGo_BuildMountList()
	GoGo_CheckFor310()
end

function GoGoMount:OnSlash(msg)
	if GOGO_COMMANDS[string.lower(msg)] then
		GOGO_COMMANDS[string.lower(msg)]()
	elseif string.find(msg, "ignore") then
		local idtype, itemid = parseForItemId(msg)
		GoGo_AddIgnoreMount(itemid)
		GoGo_Msg("ignore")
	elseif string.find(msg, "spell:%d+") or string.find(msg, "item:%d+") then
		local idtype, itemid = parseForItemId(msg)
		GoGo_AddPrefMount(itemid)
		GoGo_Msg("pref")
	else
		GoGo_Msg("optiongui")
		GoGo_Msg("auto")
		GoGo_Msg("genericfastflyer")
		GoGo_Msg("updatenotice")
		GoGo_Msg("mountnotice")
		if addonTable.Player.Class == "DRUID" then GoGo_Msg("druidclickform") end
		if addonTable.Player.Class == "DRUID" then GoGo_Msg("druidflightform") end
		GoGo_Msg("pref")
	end
end

---------
function GoGo_PreClick(button)
---------
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_PreClick: Starts")
		GoGo_DebugAddLine("GoGo_PreClick: Location = " .. GetRealZoneText() .. " - " .. GetZoneText() .. " - " ..GetSubZoneText() .. " - " .. GetMinimapZoneText())
		GoGo_DebugAddLine("GoGo_PreClick: Current unit speed is " .. GetUnitSpeed("player"))
		local level = UnitLevel("player")
		GoGo_DebugAddLine("GoGo_PreClick: We are level " .. level)
		GoGo_DebugAddLine("GoGo_PreClick: We are a " .. addonTable.Player.Class)
		if GoGo_CanFly() then
			GoGo_DebugAddLine("GoGo_PreClick: We can fly here as per GoGo_CanFly()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We can not fly here as per GoGo_CanFly()")
		end
		if IsOutdoors() then
			GoGo_DebugAddLine("GoGo_PreClick: We are outdoors as per IsOutdoors()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not outdoors as per IsOutdoors()")
		end
		if IsIndoors() then
			GoGo_DebugAddLine("GoGo_PreClick: We are indoors as per IsIndoors()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not indoors as per IsIndoors()")
		end
		if IsFlyableArea() then
			GoGo_DebugAddLine("GoGo_PreClick: We can fly here as per IsFlyableArea()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We can not fly here as per IsFlyableArea()")
		end
		if IsFlying() then
			GoGo_DebugAddLine("GoGo_PreClick: We are flying as per IsFlying()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not flying as per IsFlying()")
		end
		if IsSwimming() then
			GoGo_DebugAddLine("GoGo_PreClick: We are swimming as per IsSwimming()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not swimming as per IsSwimming()")
		end
		if IsFalling() then
			GoGo_DebugAddLine("GoGo_PreClick: We are falling as per IsFalling()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not falling as per IsFalling()")
		end
		if GoGo_IsMoving() then
			GoGo_DebugAddLine("GoGo_PreClick: We are moving as per GoGo_IsMoving()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not moving as per GoGo_IsMoving()")
		end
		local position = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
		GoGo_DebugAddLine("GoGo_PreClick: Player location: X = ".. position.x .. ", Y = " .. position.y)
	end

	if not InCombatLockdown() then
		GoGo_FillButton(button)
	end

	if IsMounted() or CanExitVehicle() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_PreClick: Player is mounted and is being dismounted.")
		end
		GoGo_Dismount()
	elseif addonTable.Player.Class == "DRUID" and GoGo_IsShifted() and not InCombatLockdown() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_PreClick: Player is a druid, is shifted and not in combat.")
		end
		GoGo_Dismount(button)
	elseif addonTable.Player.Class == "SHAMAN" and UnitBuff("player", addonTable.Localize.GhostWolf) then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_PreClick: Player is a shaman and is in wolf form.")
		end
		GoGo_Dismount()
	elseif not InCombatLockdown() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_PreClick: Player not in combat, button pressed, looking for a mount.")
		end
		GoGo_FillButton(button, GoGo_GetMount())
	end
end

function GoGo_GetMount()
	local selectedmount = GoGo_ChooseMount()
	return selectedmount
end

---------
function GoGo_ChooseMount()
---------
	if (addonTable.Player.Class == "DRUID") then
		addonTable.Druid.FeralSwiftness, _ = GoGo_GetTalentInfo(GOGO_TALENT_FERALSWIFTNESS)
		if IsIndoors() then
			if IsSwimming() then
				return GoGo_InBook(addonTable.Localize.AquaForm)
			elseif addonTable.Druid.FeralSwiftness > 0 then
				return GoGo_InBook(addonTable.Localize.CatForm)
			end
			return
		end
		if (IsSwimming() or IsFalling() or GoGo_IsMoving()) then
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: We are a druid and we're falling, swimming or moving.  Changing shape form.")
			end
			return GoGo_InBook(GOGO_SPELLS["DRUID"])
		end
	elseif (addonTable.Player.Class == "SHAMAN") and GoGo_IsMoving() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: We are a shaman and we're moving.  Changing shape form.")
		end
		addonTable.Shaman.ImprovedGhostWolf, _ = GoGo_GetTalentInfo(GOGO_TALENT_IMPROVEDGHOSTWOLF)
		if (addonTable.Shaman.ImprovedGhostWolf == 2) then return GoGo_InBook(GOGO_SPELLS["SHAMAN"]) end
	elseif (addonTable.Player.Class == "HUNTER") and GoGo_IsMoving() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: We are a hunter and we're moving.  Checking for aspects.")
		end
		if GoGo_InBook(addonTable.Localize.AspectCheetah) then
			return GoGo_InBook(addonTable.Localize.AspectCheetah)
		end
	end

	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_ChooseMount: Passed Druid / Shaman forms - nothing selected.")
	end

	local mounts = {}
	local GoGo_FilteredMounts = {}
	addonTable.Player.Zone = GetRealZoneText()
	addonTable.EngineeringLevel = GoGo_GetSkillLevel(GOGO_SKILL_ENGINEERING) or 0
	addonTable.TailoringLevel = GoGo_GetSkillLevel(GOGO_SKILL_TAILORING) or 0
	addonTable.RidingLevel = GoGo_GetSkillLevel(GOGO_SKILL_RIDING) or 0
	
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_ChooseMount: " .. GOGO_SKILL_ENGINEERING .. " = "..addonTable.EngineeringLevel)
		GoGo_DebugAddLine("GoGo_ChooseMount: " .. GOGO_SKILL_TAILORING .. " = "..addonTable.TailoringLevel)
		GoGo_DebugAddLine("GoGo_ChooseMount: " .. GOGO_SKILL_RIDING .. " = "..addonTable.RidingLevel)
	end

	if (#mounts == 0) then
		if GoGo_Prefs[addonTable.Player.Zone] then
			GoGo_FilteredMounts = GoGo_Prefs[addonTable.Player.Zone]
			GoGo_DisableUnknownMountNotice = true
		end
	end
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_ChooseMount: Checked for zone favorites.")
	end

	if (#mounts == 0) and not GoGo_FilteredMounts or (#GoGo_FilteredMounts == 0) then
		if GoGo_Prefs.GlobalPrefMounts then
			GoGo_FilteredMounts = GoGo_Prefs.GlobalPrefMounts
			GoGo_DisableUnknownMountNotice = true
		end
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Checked for global favorites.")
		end
	end

	if (#mounts == 0) and not GoGo_FilteredMounts or (#GoGo_FilteredMounts == 0) then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Checking for spell and item mounts.")
		end
		-- Not updating bag items on bag changes right now so scan and update list
		GoGo_BuildMountItemList()
		GoGo_BuildMountList()
		GoGo_FilteredMounts = addonTable.MountList
		if not GoGo_FilteredMounts or (#GoGo_FilteredMounts == 0) then
			if addonTable.Player.Class == "SHAMAN" then
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_ChooseMount: No mounts found. Forcing shaman shape form.")
				end
				return GoGo_InBook(GOGO_SPELLS["SHAMAN"])
			elseif addonTable.Player.Class == "DRUID" then
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_ChooseMount: No mounts found. Forcing druid shape form.")
				end
				return GoGo_InBook(GOGO_SPELLS["DRUID"])
			else
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_ChooseMount: No mounts found.  Giving up the search.")
				end
				return nil
			end
		end
	end
	
	local GoGo_TempMounts = {}
	if addonTable.EngineeringLevel <= 299 then
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 45)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 46)
	elseif addonTable.EngineeringLevel >= 300 and addonTable.EngineeringLevel <= 374 then
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 46)
	elseif addonTable.EngineeringLevel >= 375 then
		-- filter nothing
	else
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 45)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 46)
	end
	if addonTable.TailoringLevel <= 299 then
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 49)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 48)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 47)
	elseif addonTable.TailoringLevel >= 300 and addonTable.TailoringLevel <= 424 then
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 49)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 47)
	elseif addonTable.TailoringLevel >= 425 and addonTable.TailoringLevel <= 449 then
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 47)
	elseif addonTable.TailoringLevel >= 450 then
		-- filter nothing
	else
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 49)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 48)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 47)
	end

	if IsSwimming() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Forcing ground mounts because we're swimming.")
		end
		addonTable.SkipFlyingMount = true
	else
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 53)
	end
	
	if addonTable.Player.Zone ~= addonTable.Localize.Zone.AQ40 then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Removing AQ40 mounts since we are not in AQ40.")
		end
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 50)
	end

	if addonTable.SelectPassengerMount then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Filtering out all mounts except passenger mounts since passenger mount only was requested.")
		end
		GoGo_FilteredMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 2) or {}
	end

	if (#mounts == 0) and IsSwimming() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Looking for water speed increase mounts since we're in water.")
		end
		mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 5) or {}
	end
	
	if (#mounts == 0) and GoGo_CanFly() and not addonTable.SkipFlyingMount then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Looking for flying mounts since we past flight checks.")
		end
		if addonTable.RidingLevel <= 224 then
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 36)
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 35)
		elseif addonTable.RidingLevel >= 225 and addonTable.RidingLevel <= 299 then
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 35)
		elseif addonTable.RidingLevel >= 300 then
			-- filter nothing
		else
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 36)
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 35)
		end

		-- Druid stuff... 
		-- Use flight forms if preferred
		if addonTable.Player.Class == "DRUID" and (GoGo_InBook(addonTable.Localize.FastFlightForm) or GoGo_InBook(addonTable.Localize.FlightForm)) and GoGo_Prefs.DruidFlightForm then
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: Druid with preferred flight forms option enabled.  Using flight form.")
			end
			return GoGo_InBook(GOGO_SPELLS["DRUID"])
		end
	
		if (#mounts == 0) then
			GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 9)
			mounts = GoGo_FilterMountsIn(GoGo_TempMounts, 24)
		end
		if GoGo_Prefs.genericfastflyer then
			local GoGo_TempMountsA = GoGo_FilterMountsIn(GoGo_TempMounts, 23)
			if addonTable.RidingLevel <= 299 then
				GoGo_TempMountsA = GoGo_FilterMountsOut(GoGo_TempMountsA, 29)
			end
			if GoGo_TempMountsA then
				for k, v in ipairs(GoGo_TempMountsA) do
					tinsert(mounts, v)
				end
			end
			local GoGo_TempMountsA = GoGo_FilterMountsIn(GoGo_TempMounts, 26)
			if GoGo_TempMountsA then
				for k, v in ipairs(GoGo_TempMountsA) do
					tinsert(mounts, v)
				end
			end
		end
		if #mounts == 0 then
			GoGo_TempMountsA = GoGo_FilterMountsIn(GoGo_TempMounts, 23)
			if addonTable.RidingLevel <= 299 then
				mounts = GoGo_FilterMountsOut(GoGo_TempMountsA, 29)
			else
				mounts = GoGo_TempMountsA
			end
		end

		-- no epic flyers found - add druid swift flight if available
		if (#mounts == 0 and (addonTable.Player.Class == "Druid") and (GoGo_InBook(addonTable.Localize.FastFlightForm))) then
			tinsert(mounts, addonTable.Localize.FastFlightForm)
		end

		if #mounts == 0 then
			GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 9)
			mounts = GoGo_FilterMountsIn(GoGo_TempMounts, 22)
		end

		-- no slow flying mounts found - add druid flight if available
		if (#mounts == 0 and (addonTable.Player.Class == "Druid") and (GoGo_InBook(addonTable.Localize.FlightForm))) then
			tinsert(mounts, addonTable.Localize.FlightForm)
		end
	end
	
	if (#GoGo_FilteredMounts >= 1) then
		--GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 1)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 36)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 35)
	end

	if (#mounts == 0) and (#GoGo_FilteredMounts >= 1) then  -- no flying mounts selected yet - try to use loaned mounts
		GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 52) or {}
		if (#GoGo_TempMounts >= 1) and (addonTable.Player.Zone == addonTable.Localize.Zone.SholazarBasin or addonTable.Player.Zone == addonTable.Localize.Zone.TheStormPeaks or addonTable.Player.Zone == GOGO_ZONE_ICECROWN) then
			mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 52)
		end
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 52)
	end
	
	-- Set the oculus mounts as the only mounts available if we're in the oculus, not skiping flying and have them in inventory
	if #mounts == 0 and (#GoGo_FilteredMounts >= 1) and (addonTable.Player.Zone == GOGO_ZONE_THEOCULUS) and not addonTable.SkipFlyingMount then
		GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 54) or {}
		if #GoGo_TempMounts >= 1 then
			mounts = GoGo_TempMounts
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: In the Oculus, Oculus only mount found, using.")
			end
		else
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: In the Oculus, no oculus mount found in inventory.")
			end
		end
	else
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 54)
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Not in Oculus or forced ground mount only.")
		end
	end
	
	-- Select ground mounts
	if #mounts == 0 and GoGo_CanRide() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Looking for ground mounts since we can't fly.")
		end
		if addonTable.RidingLevel <= 74 then
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 37)
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 38)
		elseif addonTable.RidingLevel >= 75 and addonTable.RidingLevel <= 149 then
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 37)
		end
		GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 21)
		if addonTable.RidingLevel <= 149 then
			GoGo_TempMounts = GoGo_FilterMountsOut(GoGo_TempMounts, 29)
		end
		if addonTable.RidingLevel <= 225 and GoGo_CanFly() then
			mounts = GoGo_FilterMountsOut(GoGo_TempMounts, 3)
		else
			mounts = GoGo_TempMounts
		end
		if #mounts == 0 then
			mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 20)
		end
		if #mounts == 0 then
			mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 25)
		end
	end
	
	if #GoGo_FilteredMounts >= 1 then
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 37)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 38)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 21)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 20)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 25)
	end
	
	if #mounts == 0 then
		if (addonTable.Player.Class == "SHAMAN") and (GoGo_InBook(addonTable.Localize.GhostWolf)) then
			tinsert(mounts, addonTable.Localize.GhostWolf)
		end
	end

	if GoGo_Prefs.GlobalIgnoreMounts and #GoGo_Prefs.GlobalIgnoreMounts > 0 then
		local filteredMounts = {}
		for k,mountId in pairs(mounts) do
			if not GoGo_GlobalIgnoreMountExists(mountId) then
				tinsert(filteredMounts, mountId)
			end
		end
		mounts = filteredMounts
	end

	if #mounts >= 1 then
		if addonTable.Debug then
			for a = 1, #mounts do
				GoGo_DebugAddLine("GoGo_ChooseMount: Found mount " .. mounts[a] .. " - included in random pick.")
			end
		end
		selected = mounts[math.random(#mounts)]
		if type(selected) == "string" then
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: Selected string " .. selected)
			end
			return selected
		else
			selected = GoGo_GetIDName(selected)
			return selected
		end
	end
end

function GoGo_FilterMountsOut(PlayerMounts, FilterID)
	local GoGo_FilteringMounts = {}
	for k, MountID in pairs(PlayerMounts) do
		for DBMountID, DBMountData in pairs(addonTable.MountDB) do
			if (DBMountID == MountID) and not DBMountData[FilterID] then
				tinsert(GoGo_FilteringMounts, MountID)
			elseif not addonTable.MountDB[MountID] then
				GoGo_Prefs.UnknownMounts[MountID] = true
				if not GoGo_Prefs.DisableMountNotice and not GoGo_DisableUnknownMountNotice then
					GoGo_DisableUnknownMountNotice = true
					GoGo_Msg("UnknownMount")
				end
			end
		end
	end
	return GoGo_FilteringMounts
end

---------
function GoGo_FilterMountsIn(PlayerMounts, FilterID)
---------
	local GoGo_FilteringMounts = {}
	for k, MountID in pairs(PlayerMounts) do
		for DBMountID, DBMountData in pairs(addonTable.MountDB) do
			if (DBMountID == MountID) and DBMountData[FilterID] then
				tinsert(GoGo_FilteringMounts, MountID)
			elseif not addonTable.MountDB[MountID] then
				GoGo_Prefs.UnknownMounts[MountID] = true
				if not GoGo_Prefs.DisableMountNotice and not GoGo_DisableUnknownMountNotice then
					GoGo_DisableUnknownMountNotice = true
					GoGo_Msg("UnknownMount")
				end
			end
		end
	end
	return GoGo_FilteringMounts
end

function GoGo_Dismount(button)
	if IsMounted() then
		Dismount()
	elseif CanExitVehicle() then	
		VehicleExit()
	elseif addonTable.Player.Class == "DRUID" then
		if GoGo_IsShifted() and button then
			if GoGo_Prefs.DruidClickForm and not IsFlying() then
				GoGo_FillButton(button, GoGo_GetMount())
			else
				GoGo_FillButton(button, GoGo_IsShifted())
			end
		end
	elseif addonTable.Player.Class == "SHAMAN" and UnitBuff("player", GoGo_InBook(addonTable.Localize.GhostWolf)) then
		CancelUnitBuff("player", GoGo_InBook(addonTable.Localize.GhostWolf))
	else
		return nil
	end
	return true
end

function GoGo_BuildMountList()
	addonTable.MountList = {}
	for _, v in pairs(addonTable.MountSpellList) do
		tinsert(addonTable.MountList, v)
	end
	for _, v in pairs(addonTable.MountItemList) do
		tinsert(addonTable.MountList, v)
	end
	return addonTable.MountList
end 

function GoGo_BuildMountSpellList()
	addonTable.MountSpellList = {}
	for slot = 1, GetNumCompanions("MOUNT"),1 do
		local _, _, SpellID = GetCompanionInfo("MOUNT", slot)
		if addonTable.Debug then 
			GoGo_DebugAddLine("GoGo_BuildMountSpellList: Found mount spell ID " .. SpellID .. " at slot " .. slot .. " and added to known mount list.")
		end
		tinsert(addonTable.MountSpellList, SpellID)
	end
	return addonTable.MountSpellList
end

function GoGo_BuildMountItemList()
	addonTable.MountItemList = {}
	for k, MountID in ipairs(addonTable.MountsItems) do
		if GoGo_InBags(MountID) then
			if addonTable.Debug then 
				GoGo_DebugAddLine("GoGo_BuildMountItemList: Found mount item ID " .. MountID .. " in a bag and added to known mount list.")
			end
			tinsert(addonTable.MountItemList, MountID)
		end
	end
	return addonTable.MountItemList
end

function GoGo_InBags(item)
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_InBags: Searching for " .. item)
	end

	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemId = GetContainerItemID(bag, slot)
			if itemId == item then
				if addonTable.Debug then 
					GoGo_DebugAddLine("GoGo_InBags: Found item ID " .. item .. " in bag " .. (bag+1) .. ", at slot " .. slot .. " and added to known mount list.")
				end
				return GetItemInfo(itemId)
			end
		end
	end
end

local function ParseSpellbook(spell)
	local slot = 1
	while GetSpellBookItemName(slot, "spell") do
		local name = GetSpellBookItemName(slot, "spell")
		if name == spell then
			return name
		end
		slot = slot + 1
	end
end

function GoGo_InBook(spell)
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_InBook: Searching for type " .. type(spell))
	end
	if type(spell) == "function" then
		return spell()
	end
	if type(spell) == "number" then
		spell = GetSpellInfo(spell)
	end
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_InBook: Searching for spell " .. spell)
	end
	return ParseSpellbook(spell)
end

function GoGo_IsShifted()
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_IsShifted:  GoGo_IsShifted starting")
	end
	for i = 1, GetNumShapeshiftForms() do
		local _, active, _, spellID = GetShapeshiftFormInfo(i)
		if active then
			local name = GetSpellInfo(spellID)
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_IsShifted: Found " .. name)
			end
			return name
		end
	end
end

function GoGo_InOutlands()
	if string.find(GOGO_OUTLANDS, addonTable.Player.Zone, 1, true) then
		return true
	end
end

function GoGo_InNorthrend()
	if string.find(GOGO_NORTHREND, addonTable.Player.Zone, 1, true) then
		return true
	end
end

function GoGo_GlobalIgnoreMountExists(spell)
	for k, v in pairs(GoGo_Prefs.GlobalIgnoreMounts) do
		if v == spell then
			return true
		end
	end
end

function GoGo_GlobalPrefMountExists(spell)
	for k, v in pairs(GoGo_Prefs.GlobalPrefMounts) do
		if v == spell then
			return true
		end
	end
end

function GoGo_AddPrefMount(spell)
	if addonTable.Debug then 
		GoGo_DebugAddLine("GoGo_AddPrefMount: Preference " .. spell)
	end

	if not GoGo_Prefs.GlobalPrefMount then
		addonTable.Player.Zone = GetRealZoneText()
		if not GoGo_Prefs[addonTable.Player.Zone] then GoGo_Prefs[addonTable.Player.Zone] = {} end
		tinsert(GoGo_Prefs[addonTable.Player.Zone], spell)
		if #GoGo_Prefs[addonTable.Player.Zone] > 1 then
			local i = 2
			repeat
				if GoGo_Prefs[addonTable.Player.Zone][i] == GoGo_Prefs[addonTable.Player.Zone][i - 1] then
					tremove(GoGo_Prefs[addonTable.Player.Zone], i)
				else
					i = i + 1
				end
			until i > #GoGo_Prefs[addonTable.Player.Zone]
		end
	else
		if not GoGo_Prefs.GlobalPrefMounts then GoGo_Prefs.GlobalPrefMounts = {} end
		if not GoGo_GlobalPrefMountExists(spell) then
			tinsert(GoGo_Prefs.GlobalPrefMounts, spell)
			if #GoGo_Prefs.GlobalPrefMounts > 1 then
				local i = 2
				repeat
					if GoGo_Prefs.GlobalPrefMounts[i] == GoGo_Prefs.GlobalPrefMounts[i - 1] then
						tremove(GoGo_Prefs.GlobalPrefMounts, i)
					else
						i = i + 1
					end
				until i > #GoGo_Prefs.GlobalPrefMounts
			end
		end
	end
end

function GoGo_AddIgnoreMount(spell)
		if addonTable.Debug then 
			GoGo_DebugAddLine("GoGo_AddPrefMount: Preference " .. spell)
		end
		if not GoGo_Prefs.GlobalIgnoreMounts then GoGo_Prefs.GlobalIgnoreMounts = {} end
		if not GoGo_GlobalIgnoreMountExists(spell) then
			tinsert(GoGo_Prefs.GlobalIgnoreMounts, spell)
			if #GoGo_Prefs.GlobalIgnoreMounts > 1 then
				local i = 2
				repeat
					if GoGo_Prefs.GlobalIgnoreMounts[i] == GoGo_Prefs.GlobalIgnoreMounts[i - 1] then
						tremove(GoGo_Prefs.GlobalIgnoreMounts, i)
					else
						i = i + 1
					end
				until i > #GoGo_Prefs.GlobalIgnoreMounts
			end
		end
end

function GoGo_GetIDName(itemid)
	local tempname = ""
	local ItemName = ""
	if type(itemid) == "number" then
		local GoGo_TempMount = {}
		tinsert(GoGo_TempMount, itemid)
		if (#GoGo_FilterMountsIn(GoGo_TempMount, 4) == 1) then
			return GetItemInfo(itemid) or "Unknown Mount"
		else
			return GetSpellInfo(itemid) or "Unknown Mount"
		end
	elseif type(itemid) == "table" then
		for a=1, itemid do
			tempname = itemid[a]
			local GoGo_TempTable = {}
			tinsert(GoGo_TempTable, tempname)
			if (#GoGo_FilterMountsIn(GoGo_TempTable, 4) == 1) then
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_GetIDName: GetItemID for " .. tempname .. GetItemInfo(tempname))
				end
				ItemName = ItemName .. (GetItemInfo(tempname) or "Unknown Mount") .. ", "
			else
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_GetIDName: GetSpellID for " .. tempname .. GetSpellInfo(tempname))
				end
				ItemName = ItemName .. (GetSpellInfo(tempname) or "Unknown Mount") .. ", "
			end
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_GetIDName: Itemname string is " .. ItemName)
				end
		end
		return ItemName
	end
end

function GoGo_GetTalentInfo(talentname)
	if addonTable.Debug then 
		GoGo_DebugAddLine("GoGo_GetTalentInfo: Searching talent tree for " .. talentname)
	end
	local numTabs = GetNumTalentTabs()
	for tab=1, numTabs do
		local numTalents = GetNumTalents(tab)
		for talent=1, numTalents do
			local name, _, _, _, rank, maxrank = GetTalentInfo(tab,talent)
			if (talentname == name) then
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_GetTalentInfo: Found " .. talentname .. " with rank " .. rank)
				end
				return rank, maxrank
			end
		end
	end
	return 0,0
end

function GoGo_FillButton(button, mount)
	if mount then
		if addonTable.Debug then 
			GoGo_DebugAddLine("GoGo_FillButton: Casting " .. mount)
		end
		button:SetAttribute("macrotext", "/use "..mount)
	else
		button:SetAttribute("macrotext", nil)
	end
end

function GoGo_CheckBindings()
	for binding, button in pairs({GOGOBINDING = GoGoButton1, GOGOBINDING2 = GoGoButton2, GOGOBINDING3 = GoGoButton3}) do
		ClearOverrideBindings(button)
		local key1, key2 = GetBindingKey(binding)
		if key1 then
			SetOverrideBindingClick(button, true, key1, button:GetName())
		end
		if key2 then
			SetOverrideBindingClick(button, true, key2, button:GetName())
		end
	end
end

function GoGo_CanFly()
	addonTable.Player.Zone = GetRealZoneText()
	addonTable.Player.SubZone = GetSubZoneText()

	local level = UnitLevel("player")
	if (level < 60) then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_CanFly: Failed - Player under level 60")
		end
		return false
	end
	
	if GoGo_InOutlands() then
		-- we can fly here
	elseif (GoGo_InNorthrend() and (GoGo_InBook(addonTable.Localize.ColdWeatherFlying))) then
		if addonTable.Player.Zone == addonTable.Localize.Zone.Dalaran then
			if (addonTable.Player.SubZone == GOGO_SZONE_KRASUSLANDING) then
				if not IsFlyableArea() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. GOGO_SZONE_KRASUSLANDING .. " and not in flyable area.")
					end
					return false
				end
			elseif (addonTable.Player.SubZone == GOGO_SZONE_THEVIOLETCITADEL) then
				if not IsOutdoors() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. GOGO_SZONE_THEVIOLETCITADEL .. " and not outdoors area.")
					end
					return false
				end
				if not IsFlyableArea() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. GOGO_SZONE_THEVIOLETCITADEL .. " and not in flyable area.")
					end
					return false
				end
			elseif (addonTable.Player.SubZone == GOGO_SZONE_THEUNDERBELLY) then
				if not IsFlyableArea() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. GOGO_SZONE_THEUNDERBELLY .. " and not in flyable area.")
					end
					return false
				end
			elseif (addonTable.Player.SubZone == addonTable.Localize.Zone.Dalaran) then
				if not IsFlyableArea() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. addonTable.Localize.Zone.Dalaran .. " and not outdoors area.")
					end
					return false
				end
			else
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. addonTable.Localize.Zone.Dalaran .. " and not in known flyable subzone.")
				end
				return false
			end
		end

		if addonTable.Player.Zone == addonTable.Localize.Zone.Wintergrasp then
			if GetWintergraspWaitTime and GetWintergraspWaitTime() then
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_CanFly: Player in Wintergrasp and battle ground is not active.")
				end
				-- timer ticking to start wg.. we can mount
			else
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in Wintergrasp and battle ground is active.")
				end
				-- we should be in battle.. can't mount
				return false
			end
		end
	else
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_CanFly: Failed - Player does not meet any flyable conditions.")
		end
		return false  -- we can't fly anywhere else
	end
	
	return true
end

function GoGo_CanRide()
	local level = UnitLevel("player")
	if level >= 20 then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_CanRide: Passed - Player is over level 20.")
		end
		return true
	end
end

function GoGo_CheckFor310()  -- checks to see if any existing 310% mounts exist to increase the speed of [6] mounts
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_CheckFor310: Function executed.")
	end

	local Find310Mounts = GoGo_FilterMountsIn(addonTable.MountList,24)
	Find310Mounts = GoGo_FilterMountsIn(addonTable.MountList,6)
	for k, MountID in ipairs(Find310Mounts) do
		addonTable.MountDB[MountID][24] = true
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_CheckFor310: Mount ID " .. MountID .. " added as 310% flying.")
		end
	end
end

function GoGo_IsMoving()
    return GetUnitSpeed("player") ~= 0
end

function GoGo_GetSkillLevel(searchname)
	for skillIndex = 1, GetNumSkillLines() do
		skillName, isHeader, isExpanded, skillRank = GetSkillLineInfo(skillIndex)
		if isHeader == nil then
			if skillName == searchname then
				return skillRank
			end
		end
	end
end

function GoGo_Msg(msg)
	if msg then
		if GOGO_MESSAGES[msg] then
			GoGo_Msg(GOGO_MESSAGES[msg]())
		else
			msg = string.gsub(msg, "<", LIGHTYELLOW_FONT_COLOR_CODE)
			msg = string.gsub(msg, ">", "|r")
			DEFAULT_CHAT_FRAME:AddMessage(GREEN_FONT_COLOR_CODE.."GoGo: |r"..msg)
		end
	end
end

function GoGo_Id(itemstring)
	local _, _, itemid = string.find(itemstring,"(item:%d+)")
	if itemid then
		return itemid.." - "..itemstring
	end
	local _, _, spellid = string.find(itemstring,"(spell:%d+)")
	if spellid then
		return spellid.." - "..itemstring
	end
end

GOGO_ERRORS = {
	[SPELL_FAILED_NOT_MOUNTED] = true,
	[SPELL_FAILED_NOT_SHAPESHIFT] = true,
	[ERR_ATTACK_MOUNTED] = true,
}

GOGO_SPELLS = {
	["DRUID"] = function()
		if GoGo_InBook(addonTable.Localize.AquaForm) then
			if not addonTable.SkipFlyingMount and GoGo_CanFly() and GoGo_InBook(addonTable.Localize.FastFlightForm) then
				return "[swimming] "..GoGo_InBook(addonTable.Localize.AquaForm).."; [combat]"..GoGo_InBook(addonTable.Localize.TravelForm).."; "..GoGo_InBook(addonTable.Localize.FastFlightForm)
			elseif not addonTable.SkipFlyingMount and GoGo_CanFly() and GoGo_InBook(addonTable.Localize.FlightForm) then
				return "[swimming] "..GoGo_InBook(addonTable.Localize.AquaForm).."; [combat]"..GoGo_InBook(addonTable.Localize.TravelForm).."; "..GoGo_InBook(addonTable.Localize.FlightForm)
			else
				return "[swimming] "..GoGo_InBook(addonTable.Localize.AquaForm).."; "..GoGo_InBook(addonTable.Localize.TravelForm)
			end
		end
		return GoGo_InBook(addonTable.Localize.TravelForm)
	end,
	["SHAMAN"] = function()
		return GoGo_InBook(addonTable.Localize.GhostWolf)
	end,
}

GOGO_COMMANDS = {
	["auto"] = function()
		GoGo_Prefs.autodismount = not GoGo_Prefs.autodismount
		GoGo_Msg("auto")
	end,
	["genericfastflyer"] = function()
		if not GoGo_CanFly() then
			return
		else
			GoGo_Prefs.genericfastflyer = not GoGo_Prefs.genericfastflyer
			GoGo_Msg("genericfastflyer")
		end
	end,
	["clear"] = function()
		if GoGo_Prefs.GlobalPrefMount then
			GoGo_Prefs.GlobalPrefMounts = nil
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton, GoGoButton2}) do
					GoGo_FillButton(button)
				end
			end
		else
			GoGo_Prefs[addonTable.Player.Zone] = nil
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton, GoGoButton2}) do
					GoGo_FillButton(button)
				end
			end
		end
		GoGo_Msg("pref")
	end,
	["mountnotice"] = function()
		GoGo_Prefs.DisableMountNotice = not GoGo_Prefs.DisableMountNotice
		GoGo_Msg("mountnotice")
	end,
	["druidclickform"] = function()
		GoGo_Prefs.DruidClickForm = not GoGo_Prefs.DruidClickForm
		GoGo_Msg("druidclickform")
	end,
	["druidflightform"] = function()
		GoGo_Prefs.DruidFlightForm = not GoGo_Prefs.DruidFlightForm
		GoGo_Msg("druidflightform")
	end,
	["options"] = function()
		InterfaceOptionsFrame_OpenToCategory(addonName)
		InterfaceOptionsFrame_OpenToCategory(addonName)
	end,
}

GOGO_MESSAGES = {
	["auto"] = function()
		if GoGo_Prefs.autodismount then
			return "Autodismount active - </gogo auto> to toggle"
		else
			return "Autodismount inactive - </gogo auto> to toggle"
		end
	end,
	["genericfastflyer"] = function()
		if not GoGo_CanFly() then
			return
		elseif GoGo_Prefs.genericfastflyer then
			return "Considering epic flying mounts 310% - 280% speeds the same for random selection - </gogo genericfastflyer> to toggle"
		else
			return "Considering epic flying mounts 310% - 280% speeds different for random selection - </gogo genericfastflyer> to toggle"
		end
	end,
	["ignore"] = function()
		local list = ""
		if GoGo_Prefs.GlobalIgnoreMounts then
			list = list .. GoGo_GetIDName(GoGo_Prefs.GlobalIgnoreMounts)
			msg = "Global Ignore Mounts: "..list
		else
			msg =  "Global Ignore Mounts: ?".." - </gogo ignore ItemLink> or </gogo ignore SpellName> to add"
		end
		if GoGo_Prefs[addonTable.Player.Zone] then
			list = list .. GoGo_GetIDName(GoGo_Prefs[addonTable.Player.Zone])
			msg = msg .. "\n" .. addonTable.Player.Zone ..": "..list.." - Disable global mount preferences to change."
		end
		return msg
	end,
	["pref"] = function()
		local msg = ""
		if not GoGo_Prefs.GlobalPrefMount then
			local list = ""
			if GoGo_Prefs[addonTable.Player.Zone] then
				list = list .. GoGo_GetIDName(GoGo_Prefs[addonTable.Player.Zone])
				msg = addonTable.Player.Zone..": "..list.." - </gogo clear> to clear"
			else
				msg = addonTable.Player.Zone..": ?".." - </gogo ItemLink> or </gogo SpellName> to add"
			end
			if GoGo_Prefs.GlobalPrefMounts then
				list = list .. GoGo_GetIDName(GoGo_Prefs.GlobalPrefMounts)
				msg = msg .. "\nGlobal Preferred Mounts: "..list.." - Enable global mount preferences to change."
			end
			return msg
		else
			local list = ""
			if GoGo_Prefs.GlobalPrefMounts then
				list = list .. GoGo_GetIDName(GoGo_Prefs.GlobalPrefMounts)
				msg = "Global Preferred Mounts: "..list.." - </gogo clear> to clear"
			else
				msg =  "Global Preferred Mounts: ?".." - </gogo ItemLink> or </gogo SpellName> to add"
			end
			if GoGo_Prefs[addonTable.Player.Zone] then
				list = list .. GoGo_GetIDName(GoGo_Prefs[addonTable.Player.Zone])
				msg = msg .. "\n" .. addonTable.Player.Zone ..": "..list.." - Disable global mount preferences to change."
			end
			return msg
		end
	end,
	["mountnotice"] = function()
		if GoGo_Prefs.DisableMountNotice then
			return "Update notices about unknown mounts are disabled - </gogo mountnotice> to toggle"
		else
			return "Update notices about unknown mounts are enabled - </gogo mountnotice> to toggle"
		end
	end,
	["druidclickform"] = function()
		if GoGo_Prefs.DruidClickForm then
			return "Single click form changes enabled - </gogo druidclickform> to toggle"
		else
			return "Single click form changes disabled - </gogo druidclickform> to toggle"
		end
	end,
	["druidflightform"] = function()
		if GoGo_Prefs.DruidFlightForm then
			return "Flight Forms always used over flying mounts - </gogo druidflightform> to toggle"
		else
			return "Flighing mounts selected, flight forms if moving - </gogo druidflightform> to toggle"
		end
	end,
	["UnknownMount"] = function() return GOGO_STRING_UNKNOWNMOUNTFOUND end,
	["optiongui"] = function() return "To open the GUI options window - </gogo options>" end,
}

---------
function GoGo_DebugAddLine(LogLine)
---------
	if not addonTable.DebugLine then addonTable.DebugLine = 1 end
	GoGo_DebugLog[addonTable.DebugLine] = LogLine
	GoGo_Msg(LogLine)
	addonTable.DebugLine = addonTable.DebugLine + 1
	
end

function GoGoMount:GetOptions()
	-- Build options table
	local options = {
		type = "group",
		name = addonName,
		args = {
			druidClickForm = {
				name = GOGO_STRING_DRUIDSINGLECLICK,
				type = "toggle",
				order = 1,
				width = "full",
				get = function() return GoGo_Prefs.DruidClickForm end,
				set = function(info, v) GoGo_Prefs.DruidClickForm = v end,
			},
			druidFlightForm = {
				name = addonTable.Localize.String.DruidFlightPreference,
				type = "toggle",
				order = 2,
				width = "full",
				get = function() return GoGo_Prefs.DruidFlightForm end,
				set = function(info, v) GoGo_Prefs.DruidFlightForm = v end,
			},
			autodismount = {
				name = GOGO_STRING_ENABLEAUTODISMOUNT,
				type = "toggle",
				order = 3,
				width = "full",
				get = function() return GoGo_Prefs.autodismount end,
				set = function(info, v)
					GoGo_Prefs.autodismount = v
					if v then
						self:RegisterEvent("UI_ERROR_MESSAGE")
					else
						self:UnregisterEvent("UI_ERROR_MESSAGE")
					end
				end,
			},
			genericfastflyer = {
				name = GOGO_STRING_SAMEEPICFLYSPEED,
				type = "toggle",
				order = 4,
				width = "full",
				get = function() return GoGo_Prefs.genericfastflyer end,
				set = function(info, v) GoGo_Prefs.genericfastflyer = v end,
			},
			GlobalPrefMount = {
				name = "Preferred mount changes apply to global setting",
				type = "toggle",
				order = 5,
				width = "full",
				get = function() return GoGo_Prefs.GlobalPrefMount end,
				set = function(info, v) GoGo_Prefs.GlobalPrefMount = v end,
			},
			DisableMountNotice = {
				name = GOGO_STRING_DISABLEUNKNOWNMOUNTNOTICES,
				type = "toggle",
				order = 6,
				width = "full",
				get = function() return GoGo_Prefs.DisableMountNotice end,
				set = function(info, v) GoGo_Prefs.DisableMountNotice = v end,
			}
		}
	}
	return options
end