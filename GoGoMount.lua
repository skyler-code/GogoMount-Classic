local addonName, addonTable = ...

local GoGoMount = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local GoGo_Panel = CreateFrame("FRAME")

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
		local GoGoButton = CreateFrame("BUTTON", "GoGoButton"..k, UIParent, "SecureActionButtonTemplate")
		GoGoButton:SetAttribute("type", "macro")
		GoGoButton:SetScript("PreClick", function(btn)
			if addonTable.Debug then GoGo_DebugAddLine("BUTTON: Button "..k.." pressed.") end
			addonTable.SelectPassengerMount = v[1]
			addonTable.SkipFlyingMount = v[2]
			GoGo_PreClick(btn)
		end)
	end
end

---------
function GoGoMount:OnInitialize()
---------
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
end --function

function GoGoMount:VARIABLES_LOADED()
	GoGo_DebugLog = {}
	if not GoGo_Prefs then
		GoGo_Prefs = {}
		GoGo_Settings_Default()
	end --if

	addonTable.TestVersion = false
	addonTable.Debug = false
	_, addonTable.Player.Class = UnitClass("player")
	if (addonTable.Player.Class == "DRUID") then
		addonTable.Druid = {}
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
	elseif (addonTable.Player.Class == "SHAMAN") then
		addonTable.Shaman = {}
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
	end --if
	GOGO_OUTLANDS = GetZoneNames(1945)..addonTable.Localize.Zone.TwistingNether
	GOGO_NORTHREND = GetZoneNames(113)..addonTable.Localize.Zone.TheFrozenSea
	addonTable.Player.Zone = GetRealZoneText()
	if not GoGo_Prefs.version then
		GoGo_Settings_Default()
	elseif GoGo_Prefs.version ~= GetAddOnMetadata("GoGoMount", "Version") then
		GoGo_Settings_SetUpdates()
	end --if
	GoGo_Panel_Options()
	GoGo_Panel_UpdateViews()
end

function GoGoMount:PLAYER_REGEN_DISABLED()
	for i, button in ipairs({GoGoButton, GoGoButton2, GoGoButton3}) do
		if addonTable.Player.Class == "SHAMAN" then
			GoGo_FillButton(button, GoGo_InBook(GOGO_SPELLS["SHAMAN"]))
		elseif addonTable.Player.Class == "DRUID" then
			GoGo_FillButton(button, GoGo_InBook(GOGO_SPELLS["DRUID"]))
		end --if
	end --for
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
	end --if
end

function GoGoMount:UI_ERROR_MESSAGE()
	if GOGO_ERRORS[arg1] and not IsFlying() then
		GoGo_Dismount()
	end --if
end

function GoGoMount:PLAYER_ENTERING_WORLD()
	if addonTable.Debug then
		GoGo_DebugAddLine("EVENT: Player Entering World")
	end --if
	GoGo_BuildMountSpellList()
	GoGo_BuildMountItemList()
	GoGo_BuildMountList()
	GoGo_CheckFor310()
end

function GoGoMount:COMPANION_LEARNED()
	if addonTable.Debug then
		GoGo_DebugAddLine("EVENT: Companion Learned")
	end --if
	GoGo_BuildMountSpellList()
	GoGo_BuildMountList()
	GoGo_CheckFor310()
end

---------
function GoGoMount:OnSlash(msg)
---------
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
		if addonTable.Player.Class == "DRUID" then GoGo_Msg("druidclickform") end --if
		if addonTable.Player.Class == "DRUID" then GoGo_Msg("druidflightform") end --if
		GoGo_Msg("pref")
	end --if
end --function

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
		end --if
		if IsOutdoors() then
			GoGo_DebugAddLine("GoGo_PreClick: We are outdoors as per IsOutdoors()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not outdoors as per IsOutdoors()")
		end --if
		if IsIndoors() then
			GoGo_DebugAddLine("GoGo_PreClick: We are indoors as per IsIndoors()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not indoors as per IsIndoors()")
		end --if
		if IsFlyableArea() then
			GoGo_DebugAddLine("GoGo_PreClick: We can fly here as per IsFlyableArea()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We can not fly here as per IsFlyableArea()")
		end --if
		if IsFlying() then
			GoGo_DebugAddLine("GoGo_PreClick: We are flying as per IsFlying()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not flying as per IsFlying()")
		end --if
		if IsSwimming() then
			GoGo_DebugAddLine("GoGo_PreClick: We are swimming as per IsSwimming()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not swimming as per IsSwimming()")
		end --if
		if IsFalling() then
			GoGo_DebugAddLine("GoGo_PreClick: We are falling as per IsFalling()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not falling as per IsFalling()")
		end --if
		if GoGo_IsMoving() then
			GoGo_DebugAddLine("GoGo_PreClick: We are moving as per GoGo_IsMoving()")
		else
			GoGo_DebugAddLine("GoGo_PreClick: We are not moving as per GoGo_IsMoving()")
		end --if
		local map = C_Map.GetBestMapForUnit("player")
		local position = C_Map.GetPlayerMapPosition(map, "player")
		local posX, posY = position:GetXY()
		GoGo_DebugAddLine("GoGo_PreClick: Player location: X = ".. posX .. ", Y = " .. posY)
	end --if

	if not InCombatLockdown() then
		GoGo_FillButton(button)
	end --if

	if IsMounted() or CanExitVehicle() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_PreClick: Player is mounted and is being dismounted.")
		end --if
		GoGo_Dismount()
	elseif addonTable.Player.Class == "DRUID" and GoGo_IsShifted() and not InCombatLockdown() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_PreClick: Player is a druid, is shifted and not in combat.")
		end --if
		GoGo_Dismount(button)
	elseif addonTable.Player.Class == "SHAMAN" and UnitBuff("player", addonTable.Localize.GhostWolf) then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_PreClick: Player is a shaman and is in wolf form.")
		end --if
		GoGo_Dismount()
	elseif not InCombatLockdown() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_PreClick: Player not in combat, button pressed, looking for a mount.")
		end --if
		GoGo_FillButton(button, GoGo_GetMount())
	end --if
end --function

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
			end --if
			return
		end --if
		if (IsSwimming() or IsFalling() or GoGo_IsMoving()) then
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: We are a druid and we're falling, swimming or moving.  Changing shape form.")
			end --if
			return GoGo_InBook(GOGO_SPELLS["DRUID"])
		end --if
	elseif (addonTable.Player.Class == "SHAMAN") and GoGo_IsMoving() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: We are a shaman and we're moving.  Changing shape form.")
		end --if
		addonTable.Shaman.ImprovedGhostWolf, _ = GoGo_GetTalentInfo(GOGO_TALENT_IMPROVEDGHOSTWOLF)
		if (addonTable.Shaman.ImprovedGhostWolf == 2) then return GoGo_InBook(GOGO_SPELLS["SHAMAN"]) end --if
	elseif (addonTable.Player.Class == "HUNTER") and GoGo_IsMoving() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: We are a hunter and we're moving.  Checking for aspects.")
		end --if
--		if GoGo_InBook(addonTable.Localize.AspectPack) then
--			return GoGo_InBook(addonTable.Localize.AspectPack)
		if GoGo_InBook(addonTable.Localize.AspectCheetah) then
			return GoGo_InBook(addonTable.Localize.AspectCheetah)
		end --if
	end --if

	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_ChooseMount: Passed Druid / Shaman forms - nothing selected.")
	end --if

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
	end --if

	if (table.getn(mounts) == 0) then
		if GoGo_Prefs[addonTable.Player.Zone] then
			GoGo_FilteredMounts = GoGo_Prefs[addonTable.Player.Zone]
			GoGo_DisableUnknownMountNotice = true
		end --if
	end --if
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_ChooseMount: Checked for zone favorites.")
	end --if

	if (table.getn(mounts) == 0) and not GoGo_FilteredMounts or (table.getn(GoGo_FilteredMounts) == 0) then
		if GoGo_Prefs.GlobalPrefMounts then
			GoGo_FilteredMounts = GoGo_Prefs.GlobalPrefMounts
			GoGo_DisableUnknownMountNotice = true
		end --if
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Checked for global favorites.")
		end --if
	end --if

	if (table.getn(mounts) == 0) and not GoGo_FilteredMounts or (table.getn(GoGo_FilteredMounts) == 0) then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Checking for spell and item mounts.")
		end --if
		-- Not updating bag items on bag changes right now so scan and update list
		GoGo_BuildMountItemList()
		GoGo_BuildMountList()
		GoGo_FilteredMounts = addonTable.MountList
		if not GoGo_FilteredMounts or (table.getn(GoGo_FilteredMounts) == 0) then
			if addonTable.Player.Class == "SHAMAN" then
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_ChooseMount: No mounts found. Forcing shaman shape form.")
				end --if
				return GoGo_InBook(GOGO_SPELLS["SHAMAN"])
			elseif addonTable.Player.Class == "DRUID" then
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_ChooseMount: No mounts found. Forcing druid shape form.")
				end --if
				return GoGo_InBook(GOGO_SPELLS["DRUID"])
			else
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_ChooseMount: No mounts found.  Giving up the search.")
				end --if
				return nil
			end --if
		end --if
	end --if
	
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
	end --if
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
	end --if

	if IsSwimming() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Forcing ground mounts because we're swimming.")
		end --if
		addonTable.SkipFlyingMount = true
	else
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 53)
	end --if
	
	if addonTable.Player.Zone ~= addonTable.Localize.Zone.AQ40 then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Removing AQ40 mounts since we are not in AQ40.")
		end --if
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 50)
	end --if

	if addonTable.SelectPassengerMount then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Filtering out all mounts except passenger mounts since passenger mount only was requested.")
		end --if
		GoGo_FilteredMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 2) or {}
	end --if

	if (table.getn(mounts) == 0) and IsSwimming() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Looking for water speed increase mounts since we're in water.")
		end --if
		mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 5) or {}
	end --if
	
	if (table.getn(mounts) == 0) and GoGo_CanFly() and not addonTable.SkipFlyingMount then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Looking for flying mounts since we past flight checks.")
		end --if
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
		end --if

		-- Druid stuff... 
		-- Use flight forms if preferred
		if addonTable.Player.Class == "DRUID" and (GoGo_InBook(addonTable.Localize.FastFlightForm) or GoGo_InBook(addonTable.Localize.FlightForm)) and GoGo_Prefs.DruidFlightForm then
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: Druid with preferred flight forms option enabled.  Using flight form.")
			end --if
			return GoGo_InBook(GOGO_SPELLS["DRUID"])
		end --if
	
		if (table.getn(mounts) == 0) then
			GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 9)
			mounts = GoGo_FilterMountsIn(GoGo_TempMounts, 24)
		end --if
		if GoGo_Prefs.genericfastflyer then
			local GoGo_TempMountsA = GoGo_FilterMountsIn(GoGo_TempMounts, 23)
			if addonTable.RidingLevel <= 299 then
				GoGo_TempMountsA = GoGo_FilterMountsOut(GoGo_TempMountsA, 29)
			end --if
			if GoGo_TempMountsA then
				for counter = 1, table.getn(GoGo_TempMountsA) do
					table.insert(mounts, GoGo_TempMountsA[counter])
				end --for
			end --if
			local GoGo_TempMountsA = GoGo_FilterMountsIn(GoGo_TempMounts, 26)
			if GoGo_TempMountsA then
				for counter = 1, table.getn(GoGo_TempMountsA) do
					table.insert(mounts, GoGo_TempMountsA[counter])
				end --for
			end --if
		end --if
		if (table.getn(mounts) == 0) then
			GoGo_TempMountsA = GoGo_FilterMountsIn(GoGo_TempMounts, 23)
			if addonTable.RidingLevel <= 299 then
				mounts = GoGo_FilterMountsOut(GoGo_TempMountsA, 29)
			else
				mounts = GoGo_TempMountsA
			end --if
		end --if

		-- no epic flyers found - add druid swift flight if available
		if (table.getn(mounts) == 0 and (addonTable.Player.Class == "Druid") and (GoGo_InBook(addonTable.Localize.FastFlightForm))) then
			table.insert(mounts, addonTable.Localize.FastFlightForm)
		end --if

		if (table.getn(mounts) == 0) then
			GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 9)
			mounts = GoGo_FilterMountsIn(GoGo_TempMounts, 22)
		end --if

		-- no slow flying mounts found - add druid flight if available
		if (table.getn(mounts) == 0 and (addonTable.Player.Class == "Druid") and (GoGo_InBook(addonTable.Localize.FlightForm))) then
			table.insert(mounts, addonTable.Localize.FlightForm)
		end --if
	end --if
	
	if (table.getn(GoGo_FilteredMounts) >= 1) then
		--GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 1)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 36)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 35)
	end --if

	if (table.getn(mounts) == 0) and (table.getn(GoGo_FilteredMounts) >= 1) then  -- no flying mounts selected yet - try to use loaned mounts
		GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 52) or {}
		if (table.getn(GoGo_TempMounts) >= 1) and (addonTable.Player.Zone == addonTable.Localize.Zone.SholazarBasin or addonTable.Player.Zone == addonTable.Localize.Zone.TheStormPeaks or addonTable.Player.Zone == GOGO_ZONE_ICECROWN) then
			mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 52)
		end --if
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 52)
	end --if
	
	-- Set the oculus mounts as the only mounts available if we're in the oculus, not skiping flying and have them in inventory
	if (table.getn(mounts) == 0) and (table.getn(GoGo_FilteredMounts) >= 1) and (addonTable.Player.Zone == GOGO_ZONE_THEOCULUS) and not addonTable.SkipFlyingMount then
		GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 54) or {}
		if (table.getn(GoGo_TempMounts) >= 1) then
			mounts = GoGo_TempMounts
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: In the Oculus, Oculus only mount found, using.")
			end --if
		else
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: In the Oculus, no oculus mount found in inventory.")
			end --if
		end --if
	else
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 54)
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Not in Oculus or forced ground mount only.")
		end --if
	end --if
	
	-- Select ground mounts
	if (table.getn(mounts) == 0) and GoGo_CanRide() then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_ChooseMount: Looking for ground mounts since we can't fly.")
		end --if
		if addonTable.RidingLevel <= 74 then
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 37)
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 38)
		elseif addonTable.RidingLevel >= 75 and addonTable.RidingLevel <= 149 then
			GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 37)
		end --if
		GoGo_TempMounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 21)
		if addonTable.RidingLevel <= 149 then
			GoGo_TempMounts = GoGo_FilterMountsOut(GoGo_TempMounts, 29)
		end --if
		if addonTable.RidingLevel <= 225 and GoGo_CanFly() then
			mounts = GoGo_FilterMountsOut(GoGo_TempMounts, 3)
		else
			mounts = GoGo_TempMounts
		end --if
		if (table.getn(mounts) == 0) then
			mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 20)
		end --if
		if (table.getn(mounts) == 0) then
			mounts = GoGo_FilterMountsIn(GoGo_FilteredMounts, 25)
		end --if
	end --if
	
	if table.getn(GoGo_FilteredMounts) >= 1 then
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 37)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 38)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 21)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 20)
		GoGo_FilteredMounts = GoGo_FilterMountsOut(GoGo_FilteredMounts, 25)
	end --if
	
	if (table.getn(mounts) == 0) then
		if (addonTable.Player.Class == "SHAMAN") and (GoGo_InBook(addonTable.Localize.GhostWolf)) then
			table.insert(mounts, addonTable.Localize.GhostWolf)
		end --if
	end --if

	if GoGo_Prefs.GlobalIgnoreMounts and #GoGo_Prefs.GlobalIgnoreMounts > 0 then
		local filteredMounts = {}
		for k,mountId in pairs(mounts) do
			if not GoGo_GlobalIgnoreMountExists(mountId) then
				table.insert(filteredMounts, mountId)
			end
		end
		mounts = filteredMounts
	end

	if (table.getn(mounts) >= 1) then
		if addonTable.Debug then
			for a = 1, table.getn(mounts) do
				GoGo_DebugAddLine("GoGo_ChooseMount: Found mount " .. mounts[a] .. " - included in random pick.")
			end --for
		end --if
		selected = mounts[math.random(table.getn(mounts))]
		if type(selected) == "string" then
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_ChooseMount: Selected string " .. selected)
			end --if
			return selected
		else
			selected = GoGo_GetIDName(selected)
			return selected
		end --if
	end --if
end --function

---------
function GoGo_FilterMountsOut(PlayerMounts, FilterID)
---------
	local GoGo_FilteringMounts = {}
	if table.getn(PlayerMounts) == 0 then
		return GoGo_FilteringMounts
	end --if
	for a = 1, table.getn(PlayerMounts) do
		local MountID = PlayerMounts[a]
		for DBMountID, DBMountData in pairs(addonTable.MountDB) do
			if (DBMountID == MountID) and not DBMountData[FilterID] then
				table.insert(GoGo_FilteringMounts, MountID)
			elseif not addonTable.MountDB[MountID] then
				GoGo_Prefs.UnknownMounts[MountID] = true
				if not GoGo_Prefs.DisableMountNotice and not GoGo_DisableUnknownMountNotice then
					GoGo_DisableUnknownMountNotice = true
					GoGo_Msg("UnknownMount")
				end --if
			end --if
		end --for
	end --for
	return GoGo_FilteringMounts
end --function

---------
function GoGo_FilterMountsIn(PlayerMounts, FilterID)
---------
	local GoGo_FilteringMounts = {}
	if table.getn(PlayerMounts) == 0 then
		return GoGo_FilteringMounts
	end --if
	for a = 1, table.getn(PlayerMounts) do
		local MountID = PlayerMounts[a]
		for DBMountID, DBMountData in pairs(addonTable.MountDB) do
			if (DBMountID == MountID) and DBMountData[FilterID] then
				table.insert(GoGo_FilteringMounts, MountID)
			elseif not addonTable.MountDB[MountID] then
				GoGo_Prefs.UnknownMounts[MountID] = true
				if not GoGo_Prefs.DisableMountNotice and not GoGo_DisableUnknownMountNotice then
					GoGo_DisableUnknownMountNotice = true
					GoGo_Msg("UnknownMount")
				end --if
			end --if
		end --for
	end --for
	return GoGo_FilteringMounts
end --function

---------
function GoGo_Dismount(button)
---------
	if IsMounted() then
		Dismount()
	elseif CanExitVehicle() then	
		VehicleExit()
	elseif addonTable.Player.Class == "DRUID" then
		if GoGo_IsShifted() and button then
			if GoGo_Prefs.DruidClickForm and not IsFlying() then
				GoGo_FillButton(button, GoGo_GetMount())
			else
--				CancelUnitBuff("player", GoGo_IsShifted())  -- protected by blizzard now
				GoGo_FillButton(button, GoGo_IsShifted())
			end --if
		end --if
	elseif addonTable.Player.Class == "SHAMAN" and UnitBuff("player", GoGo_InBook(addonTable.Localize.GhostWolf)) then
		CancelUnitBuff("player", GoGo_InBook(addonTable.Localize.GhostWolf))
	else
		return nil
	end --if
	return true
end --function

---------
function GoGo_InCompanions(item)
---------
	for slot = 1, GetNumCompanions("MOUNT") do
		local _, _, spellID = GetCompanionInfo("MOUNT", slot)
		if spellID and string.find(item, spellID) then
			if addonTable.Debug then 
				GoGo_DebugAddLine("GoGo_InCompanions: Found mount name  " .. GetSpellInfo(spellID) .. " in mount list.")
			end --if
			return GetSpellInfo(spellID)
		end --if
	end --for
end --function

---------
function GoGo_BuildMountList()
---------
	addonTable.MountList = {}
	if (table.getn(addonTable.MountSpellList) > 0) then
		for a=1, table.getn(addonTable.MountSpellList) do
			table.insert(addonTable.MountList, addonTable.MountSpellList[a])
		end --for
	end --if
	
	if (table.getn(addonTable.MountItemList) > 0) then
		for a=1, table.getn(addonTable.MountItemList) do
			table.insert(addonTable.MountList, addonTable.MountItemList[a])
		end --for
	end --if

	return addonTable.MountList
end  --function

---------
function GoGo_BuildMountSpellList()
---------
	addonTable.MountSpellList = {}
	if (GetNumCompanions("MOUNT") >= 1) then
		for slot = 1, GetNumCompanions("MOUNT"),1 do
			local _, _, SpellID = GetCompanionInfo("MOUNT", slot)
			if addonTable.Debug then 
				GoGo_DebugAddLine("GoGo_BuildMountSpellList: Found mount spell ID " .. SpellID .. " at slot " .. slot .. " and added to known mount list.")
			end --if
			table.insert(addonTable.MountSpellList, SpellID)
		end --for
	end --if
	return addonTable.MountSpellList
end  -- function

---------
function GoGo_BuildMountItemList()
---------
	addonTable.MountItemList = {}
	
	for a = 1, table.getn(addonTable.MountsItems) do
		local MountID = addonTable.MountsItems[a]
		if GoGo_InBags(MountID) then
			if addonTable.Debug then 
				GoGo_DebugAddLine("GoGo_BuildMountItemList: Found mount item ID " .. MountID .. " in a bag and added to known mount list.")
			end --if
			table.insert(addonTable.MountItemList, MountID)
		end --if
	end --for
	return addonTable.MountItemList
end --function

---------
function GoGo_InBags(item)
---------
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_InBags: Searching for " .. item)
	end --if

	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local _, itemid, _ = strsplit(":",link,3)
				if tonumber(itemid) == item then
					if addonTable.Debug then 
						GoGo_DebugAddLine("GoGo_InBags: Found item ID " .. item .. " in bag " .. (bag+1) .. ", at slot " .. slot .. " and added to known mount list.")
					end --if
					return GetItemInfo(link)
				end --if
			end --if
		end --for
	end --for
end --function

---------
function GoGo_InBook(spell)
---------
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_InBook: Searching for type " .. type(spell))
	end --if
	if type(spell) == "function" then
		return spell()
	else
		if type(spell) == "string" then
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_InBook: Searching for " .. spell)
			end --if
			local slot = 1
			while GetSpellBookItemName(slot, "spell") do
				local name = GetSpellBookItemName(slot, "spell")
				if name == spell then
					return spell
				end --if
				slot = slot + 1
			end --while
		elseif type(spell) == "number" then
			local spellname = GetSpellInfo(spell)
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_InBook: Searching for spell ID " .. spell)
			end --if
			local slot = 1
			while GetSpellBookItemName(slot, "spell") do
				local name = GetSpellBookItemName(slot, "spell")
				if name == spellname then
					return name
				end --if
				slot = slot + 1
			end --while
			-- blah
		end --if
	end --if
end --function

---------
function GoGo_IsShifted()
---------
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_IsShifted:  GoGo_IsShifted starting")
	end --if
	for i = 1, GetNumShapeshiftForms() do
		local _, active, castable, spellID = GetShapeshiftFormInfo(i)
		if active then
			local name = GetSpellInfo(spellID)
			if addonTable.Debug then
				GoGo_DebugAddLine("GoGo_IsShifted: Found " .. name)
			end --if
			return name
		end
	end --for
end --function

---------
function GoGo_InOutlands()
---------
	if string.find(GOGO_OUTLANDS, addonTable.Player.Zone, 1, true) then
		return true
	end --if
end --function

function GoGo_InNorthrend()
---------
	if string.find(GOGO_NORTHREND, addonTable.Player.Zone, 1, true) then
		return true
	end --if
end --function

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

---------
function GoGo_AddPrefMount(spell)
---------
	if addonTable.Debug then 
		GoGo_DebugAddLine("GoGo_AddPrefMount: Preference " .. spell)
	end --if

	if not GoGo_Prefs.GlobalPrefMount then
		addonTable.Player.Zone = GetRealZoneText()
		if not GoGo_Prefs[addonTable.Player.Zone] then GoGo_Prefs[addonTable.Player.Zone] = {} end
		table.insert(GoGo_Prefs[addonTable.Player.Zone], spell)
		if table.getn(GoGo_Prefs[addonTable.Player.Zone]) > 1 then
			local i = 2
			repeat
				if GoGo_Prefs[addonTable.Player.Zone][i] == GoGo_Prefs[addonTable.Player.Zone][i - 1] then
					table.remove(GoGo_Prefs[addonTable.Player.Zone], i)
				else
					i = i + 1
				end --if
			until i > table.getn(GoGo_Prefs[addonTable.Player.Zone])
		end --if
	else
		if not GoGo_Prefs.GlobalPrefMounts then GoGo_Prefs.GlobalPrefMounts = {} end
		if not GoGo_GlobalPrefMountExists(spell) then
			table.insert(GoGo_Prefs.GlobalPrefMounts, spell)
			if table.getn(GoGo_Prefs.GlobalPrefMounts) > 1 then
				local i = 2
				repeat
					if GoGo_Prefs.GlobalPrefMounts[i] == GoGo_Prefs.GlobalPrefMounts[i - 1] then
						table.remove(GoGo_Prefs.GlobalPrefMounts, i)
					else
						i = i + 1
					end --if
				until i > table.getn(GoGo_Prefs.GlobalPrefMounts)
			end --if
		end
	end --if
end --function

---------
function GoGo_AddIgnoreMount(spell)
	---------
		if addonTable.Debug then 
			GoGo_DebugAddLine("GoGo_AddPrefMount: Preference " .. spell)
		end --if
	
		
		if not GoGo_Prefs.GlobalIgnoreMounts then GoGo_Prefs.GlobalIgnoreMounts = {} end
		if not GoGo_GlobalIgnoreMountExists(spell) then
			table.insert(GoGo_Prefs.GlobalIgnoreMounts, spell)
			if table.getn(GoGo_Prefs.GlobalIgnoreMounts) > 1 then
				local i = 2
				repeat
					if GoGo_Prefs.GlobalIgnoreMounts[i] == GoGo_Prefs.GlobalIgnoreMounts[i - 1] then
						table.remove(GoGo_Prefs.GlobalIgnoreMounts, i)
					else
						i = i + 1
					end --if
				until i > table.getn(GoGo_Prefs.GlobalIgnoreMounts)
			end --if
		end
end --function

---------
function GoGo_GetIDName(itemid)
---------
	local tempname = ""
	local ItemName = ""
	if type(itemid) == "number" then
		local GoGo_TempMount = {}
		table.insert(GoGo_TempMount, itemid)
		if (table.getn(GoGo_FilterMountsIn(GoGo_TempMount, 4)) == 1) then
			return GetItemInfo(itemid) or "Unknown Mount"
		else
			return GetSpellInfo(itemid) or "Unknown Mount"
		end --if
	elseif type(itemid) == "table" then
		for a=1, table.getn(itemid) do
			tempname = itemid[a]
			local GoGo_TempTable = {}
			table.insert(GoGo_TempTable, tempname)
			if (table.getn(GoGo_FilterMountsIn(GoGo_TempTable, 4)) == 1) then
--				tempname = GetItemInfo(tempname)
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_GetIDName: GetItemID for " .. tempname .. GetItemInfo(tempname))
				end --if
				ItemName = ItemName .. (GetItemInfo(tempname) or "Unknown Mount") .. ", "
			else
--				tempname = GetSpellInfo(tempname)
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_GetIDName: GetSpellID for " .. tempname .. GetSpellInfo(tempname))
				end --if
				ItemName = ItemName .. (GetSpellInfo(tempname) or "Unknown Mount") .. ", "
			end --if
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_GetIDName: Itemname string is " .. ItemName)
				end --if
		end --for
		return ItemName
	end --if
end --function

---------
function GoGo_GetTalentInfo(talentname)
---------
	if addonTable.Debug then 
		GoGo_DebugAddLine("GoGo_GetTalentInfo: Searching talent tree for " .. talentname)
	end --if
	local numTabs = GetNumTalentTabs()
	for tab=1, numTabs do
		local numTalents = GetNumTalents(tab)
		for talent=1, numTalents do
			local name, _, _, _, rank, maxrank = GetTalentInfo(tab,talent)
			if (talentname == name) then
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_GetTalentInfo: Found " .. talentname .. " with rank " .. rank)
				end --if
				return rank, maxrank
			end --if
		end --for
	end --for
	return 0,0
end --function

---------
function GoGo_FillButton(button, mount)
---------
	if mount then
		if addonTable.Debug then 
			GoGo_DebugAddLine("GoGo_FillButton: Casting " .. mount)
		end --if
		button:SetAttribute("macrotext", "/use "..mount)
	else
		button:SetAttribute("macrotext", nil)
	end --if
end --function

---------
function GoGo_CheckBindings()
---------
	for binding, button in pairs({GOGOBINDING = GoGoButton1, GOGOBINDING2 = GoGoButton2, GOGOBINDING3 = GoGoButton3}) do
		ClearOverrideBindings(button)
		local key1, key2 = GetBindingKey(binding)
		if key1 then
			SetOverrideBindingClick(button, true, key1, button:GetName())
		end --if
		if key2 then
			SetOverrideBindingClick(button, true, key2, button:GetName())
		end --if
	end --if
end --function

---------
function GoGo_CanFly()
---------
	addonTable.Player.Zone = GetRealZoneText()
	addonTable.Player.SubZone = GetSubZoneText()

	local level = UnitLevel("player")
	if (level < 60) then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_CanFly: Failed - Player under level 60")
		end --if
		return false
	end --if
	
	if GoGo_InOutlands() then
		-- we can fly here
	elseif (GoGo_InNorthrend() and (GoGo_InBook(addonTable.Localize.ColdWeatherFlying))) then
		if addonTable.Player.Zone == addonTable.Localize.Zone.Dalaran then
			if (addonTable.Player.SubZone == GOGO_SZONE_KRASUSLANDING) then
				if not IsFlyableArea() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. GOGO_SZONE_KRASUSLANDING .. " and not in flyable area.")
					end --if
					return false
				end --if
			elseif (addonTable.Player.SubZone == GOGO_SZONE_THEVIOLETCITADEL) then
				if not IsOutdoors() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. GOGO_SZONE_THEVIOLETCITADEL .. " and not outdoors area.")
					end --if
					return false
				end --if
				if not IsFlyableArea() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. GOGO_SZONE_THEVIOLETCITADEL .. " and not in flyable area.")
					end --if
					return false
				end --if
			elseif (addonTable.Player.SubZone == GOGO_SZONE_THEUNDERBELLY) then
				if not IsFlyableArea() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. GOGO_SZONE_THEUNDERBELLY .. " and not in flyable area.")
					end --if
					return false
				end --if
			elseif (addonTable.Player.SubZone == addonTable.Localize.Zone.Dalaran) then
				if not IsFlyableArea() then
					if addonTable.Debug then
						GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. addonTable.Localize.Zone.Dalaran .. " and not outdoors area.")
					end --if
					return false
				end --if
			else
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in " .. addonTable.Localize.Zone.Dalaran .. " and not in known flyable subzone.")
				end --if
				return false
			end --if
		end --if

		if addonTable.Player.Zone == addonTable.Localize.Zone.Wintergrasp then
			if GetWintergraspWaitTime and GetWintergraspWaitTime() then
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_CanFly: Player in Wintergrasp and battle ground is not active.")
				end --if
				-- timer ticking to start wg.. we can mount
			else
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_CanFly: Failed - Player in Wintergrasp and battle ground is active.")
				end --if
				-- we should be in battle.. can't mount
				return false
			end --if
		end --if
	else
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_CanFly: Failed - Player does not meet any flyable conditions.")
		end --if
		return false  -- we can't fly anywhere else
	end --if
	
	return true
end --function

---------
function GoGo_CanRide()
---------
	local level = UnitLevel("player")
	if level >= 20 then
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_CanRide: Passed - Player is over level 20.")
		end --if
		return true
	end --if
end --function

---------
function GoGo_CheckFor310()  -- checks to see if any existing 310% mounts exist to increase the speed of [6] mounts
---------
	local loop
	local MountID
	if addonTable.Debug then
		GoGo_DebugAddLine("GoGo_CheckFor310: Function executed.")
	end --if

	local Find310Mounts = GoGo_FilterMountsIn(addonTable.MountList,24)
	for loop=1, table.getn(Find310Mounts) do
		MountID = Find310Mounts[loop]
		if addonTable.Debug then
			GoGo_DebugAddLine("GoGo_CheckFor310: Mount ID " .. MountID .. " found as 310% flying.")
		end --if
	end --for
	if (table.getn(Find310Mounts) > 0) then
		Find310Mounts = GoGo_FilterMountsIn(addonTable.MountList,6)
		if table.getn(Find310Mounts) then
			for loop=1, table.getn(Find310Mounts) do
				MountID = Find310Mounts[loop]
				addonTable.MountDB[MountID][24] = true
				if addonTable.Debug then
					GoGo_DebugAddLine("GoGo_CheckFor310: Mount ID " .. MountID .. " added as 310% flying.")
				end --if

			end --for
		end --if
	end --if
end --function

function GoGo_IsMoving()
    return GetUnitSpeed("player") ~= 0
end

---------
function GoGo_GetSkillLevel(searchname)
---------
	for skillIndex = 1, GetNumSkillLines() do
		skillName, isHeader, isExpanded, skillRank = GetSkillLineInfo(skillIndex)
		if isHeader == nil then
			if skillName == searchname then
				return skillRank
			end --if
		end --if
	end --for
end --function

---------
function GoGo_Msg(msg)
---------
	if msg then
		if GOGO_MESSAGES[msg] then
			GoGo_Msg(GOGO_MESSAGES[msg]())
		else
			msg = string.gsub(msg, "<", LIGHTYELLOW_FONT_COLOR_CODE)
			msg = string.gsub(msg, ">", "|r")
			DEFAULT_CHAT_FRAME:AddMessage(GREEN_FONT_COLOR_CODE.."GoGo: |r"..msg)
		end --if
	end --if
end --function

---------
function GoGo_Id(itemstring)
---------
	local _, _, itemid = string.find(itemstring,"(item:%d+)")
	if itemid then
		return itemid.." - "..itemstring
	end --if
	local _, _, spellid = string.find(itemstring,"(spell:%d+)")
	if spellid then
		return spellid.." - "..itemstring
	end --if

end --function

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
			end --if
		end --if
		return GoGo_InBook(addonTable.Localize.TravelForm)
	end, --function
	["SHAMAN"] = function()
		return GoGo_InBook(addonTable.Localize.GhostWolf)
	end, --function
}

GOGO_COMMANDS = {
	["auto"] = function()
		GoGo_Prefs.autodismount = not GoGo_Prefs.autodismount
		GoGo_Msg("auto")
		GoGo_Panel_UpdateViews()
	end, --function
	["genericfastflyer"] = function()
		if not GoGo_CanFly() then
			return
		else
			GoGo_Prefs.genericfastflyer = not GoGo_Prefs.genericfastflyer
			GoGo_Msg("genericfastflyer")
			GoGo_Panel_UpdateViews()
		end --if
	end, --function
	["clear"] = function()
		if GoGo_Prefs.GlobalPrefMount then
			GoGo_Prefs.GlobalPrefMounts = nil
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton, GoGoButton2}) do
					GoGo_FillButton(button)
				end --for
			end --if
		else
			GoGo_Prefs[addonTable.Player.Zone] = nil
			if not InCombatLockdown() then
				for i, button in ipairs({GoGoButton, GoGoButton2}) do
					GoGo_FillButton(button)
				end --for
			end --if
		end --if
		GoGo_Msg("pref")
	end, --function
	["mountnotice"] = function()
		GoGo_Prefs.DisableMountNotice = not GoGo_Prefs.DisableMountNotice
		GoGo_Msg("mountnotice")
		GoGo_Panel_UpdateViews()
	end, --function
	["druidclickform"] = function()
		GoGo_Prefs.DruidClickForm = not GoGo_Prefs.DruidClickForm
		GoGo_Msg("druidclickform")
		GoGo_Panel_UpdateViews()
	end, --function
	["druidflightform"] = function()
		GoGo_Prefs.DruidFlightForm = not GoGo_Prefs.DruidFlightForm
		GoGo_Msg("druidflightform")
		GoGo_Panel_UpdateViews()
	end, --function
	["options"] = function()
		InterfaceOptionsFrame_OpenToCategory(GoGo_Panel)
		InterfaceOptionsFrame_OpenToCategory(GoGo_Panel)
	end, --function
}

GOGO_MESSAGES = {
	["auto"] = function()
		if GoGo_Prefs.autodismount then
			return "Autodismount active - </gogo auto> to toggle"
		else
			return "Autodismount inactive - </gogo auto> to toggle"
		end --if
	end, --function
	["genericfastflyer"] = function()
		if not GoGo_CanFly() then
			return
		elseif GoGo_Prefs.genericfastflyer then
			return "Considering epic flying mounts 310% - 280% speeds the same for random selection - </gogo genericfastflyer> to toggle"
		else
			return "Considering epic flying mounts 310% - 280% speeds different for random selection - </gogo genericfastflyer> to toggle"
		end --if
	end, --function
	["ignore"] = function()
		local list = ""
		if GoGo_Prefs.GlobalIgnoreMounts then
			list = list .. GoGo_GetIDName(GoGo_Prefs.GlobalIgnoreMounts)
			msg = "Global Ignore Mounts: "..list
		else
			msg =  "Global Ignore Mounts: ?".." - </gogo ignore ItemLink> or </gogo ignore SpellName> to add"
		end --if
		if GoGo_Prefs[addonTable.Player.Zone] then
			list = list .. GoGo_GetIDName(GoGo_Prefs[addonTable.Player.Zone])
			msg = msg .. "\n" .. addonTable.Player.Zone ..": "..list.." - Disable global mount preferences to change."
		end --if
		return msg
	end, --function
	["pref"] = function()
		local msg = ""
		if not GoGo_Prefs.GlobalPrefMount then
			local list = ""
			if GoGo_Prefs[addonTable.Player.Zone] then
				list = list .. GoGo_GetIDName(GoGo_Prefs[addonTable.Player.Zone])
				msg = addonTable.Player.Zone..": "..list.." - </gogo clear> to clear"
			else
				msg = addonTable.Player.Zone..": ?".." - </gogo ItemLink> or </gogo SpellName> to add"
			end --if
			if GoGo_Prefs.GlobalPrefMounts then
				list = list .. GoGo_GetIDName(GoGo_Prefs.GlobalPrefMounts)
				msg = msg .. "\nGlobal Preferred Mounts: "..list.." - Enable global mount preferences to change."
			end --if
			return msg
		else
			local list = ""
			if GoGo_Prefs.GlobalPrefMounts then
				list = list .. GoGo_GetIDName(GoGo_Prefs.GlobalPrefMounts)
				msg = "Global Preferred Mounts: "..list.." - </gogo clear> to clear"
			else
				msg =  "Global Preferred Mounts: ?".." - </gogo ItemLink> or </gogo SpellName> to add"
			end --if
			if GoGo_Prefs[addonTable.Player.Zone] then
				list = list .. GoGo_GetIDName(GoGo_Prefs[addonTable.Player.Zone])
				msg = msg .. "\n" .. addonTable.Player.Zone ..": "..list.." - Disable global mount preferences to change."
			end --if
			return msg
		end --if
	end, --function
	["mountnotice"] = function()
		if GoGo_Prefs.DisableMountNotice then
			return "Update notices about unknown mounts are disabled - </gogo mountnotice> to toggle"
		else
			return "Update notices about unknown mounts are enabled - </gogo mountnotice> to toggle"
		end --if
	end, --function
	["druidclickform"] = function()
		if GoGo_Prefs.DruidClickForm then
			return "Single click form changes enabled - </gogo druidclickform> to toggle"
		else
			return "Single click form changes disabled - </gogo druidclickform> to toggle"
		end --if
	end, --function
	["druidflightform"] = function()
		if GoGo_Prefs.DruidFlightForm then
			return "Flight Forms always used over flying mounts - </gogo druidflightform> to toggle"
		else
			return "Flighing mounts selected, flight forms if moving - </gogo druidflightform> to toggle"
		end --if
	end, --function
	["UnknownMount"] = function() return GOGO_STRING_UNKNOWNMOUNTFOUND end, --function
	["optiongui"] = function() return "To open the GUI options window - </gogo options>" end, --function
}

---------
function GoGo_DebugAddLine(LogLine)
---------
	if not addonTable.DebugLine then addonTable.DebugLine = 1 end --if
	GoGo_DebugLog[addonTable.DebugLine] = LogLine
	GoGo_Msg(LogLine)
	addonTable.DebugLine = addonTable.DebugLine + 1
	
end --function

function GoGo_Panel:OnLoad()
	self.name = addonName
	self.okay = function (self) GoGo_Panel_Okay(); end;
	self.default = function (self) GoGo_Settings_Default(); GoGo_Panel_UpdateViews(); end;
	InterfaceOptions_AddCategory(self)
	
end

---------
function GoGo_Panel_Options()
---------
	GoGo_Panel_DruidClickForm = CreateFrame("CheckButton", "GoGo_Panel_DruidClickForm", GoGo_Panel, "OptionsCheckButtonTemplate")
	GoGo_Panel_DruidClickForm:SetPoint("TOPLEFT", 16, -16)
	GoGo_Panel_DruidClickFormText:SetText(GOGO_STRING_DRUIDSINGLECLICK)

	GoGo_Panel_DruidFlightForm = CreateFrame("CheckButton", "GoGo_Panel_DruidFlightForm", GoGo_Panel, "OptionsCheckButtonTemplate")
	GoGo_Panel_DruidFlightForm:SetPoint("TOPLEFT", "GoGo_Panel_DruidClickForm", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_DruidFlightFormText:SetText(addonTable.Localize.String.DruidFlightPreference)

	GoGo_Panel_AutoDismount = CreateFrame("CheckButton", "GoGo_Panel_AutoDismount", GoGo_Panel, "OptionsCheckButtonTemplate")
	GoGo_Panel_AutoDismount:SetPoint("TOPLEFT", "GoGo_Panel_DruidFlightForm", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_AutoDismountText:SetText(GOGO_STRING_ENABLEAUTODISMOUNT)

	GoGo_Panel_GenericFastFlyer = CreateFrame("CheckButton", "GoGo_Panel_GenericFastFlyer", GoGo_Panel, "OptionsCheckButtonTemplate")
	GoGo_Panel_GenericFastFlyer:SetPoint("TOPLEFT", "GoGo_Panel_AutoDismount", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_GenericFastFlyerText:SetText(GOGO_STRING_SAMEEPICFLYSPEED)


	GoGo_Panel_GlobalPrefMount = CreateFrame("CheckButton", "GoGo_Panel_GlobalPrefMount", GoGo_Panel, "OptionsCheckButtonTemplate")
	GoGo_Panel_GlobalPrefMount:SetPoint("TOPLEFT", "GoGo_Panel_GenericFastFlyer", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_GlobalPrefMountText:SetText("Preferred mount changes apply to global setting")

	GoGo_Panel_DisableMountNotice = CreateFrame("CheckButton", "GoGo_Panel_DisableMountNotice", GoGo_Panel, "OptionsCheckButtonTemplate")
	GoGo_Panel_DisableMountNotice:SetPoint("TOPLEFT", "GoGo_Panel_GlobalPrefMount", "BOTTOMLEFT", 0, -4)
	GoGo_Panel_DisableMountNoticeText:SetText(GOGO_STRING_DISABLEUNKNOWNMOUNTNOTICES)
end --function

---------
function GoGo_Panel_UpdateViews()
---------
	GoGo_Panel_AutoDismount:SetChecked(GoGo_Prefs.autodismount)
	GoGo_Panel_GenericFastFlyer:SetChecked(GoGo_Prefs.genericfastflyer)
	GoGo_Panel_DisableMountNotice:SetChecked(GoGo_Prefs.DisableMountNotice)
	GoGo_Panel_DruidClickForm:SetChecked(GoGo_Prefs.DruidClickForm)
	GoGo_Panel_DruidFlightForm:SetChecked(GoGo_Prefs.DruidFlightForm)
	GoGo_Panel_GlobalPrefMount:SetChecked(GoGo_Prefs.GlobalPrefMount)
	
	if GoGo_Prefs.autodismount then
		GoGoMount:RegisterEvent("UI_ERROR_MESSAGE")
	else
		GoGoMount:UnregisterEvent("UI_ERROR_MESSAGE")
	end --if
end -- function

---------
function GoGo_Panel_Okay()
---------
	GoGo_Prefs.autodismount = GoGo_Panel_AutoDismount:GetChecked()
	GoGo_Prefs.genericfastflyer = GoGo_Panel_GenericFastFlyer:GetChecked()
	GoGo_Prefs.DisableMountNotice = GoGo_Panel_DisableMountNotice:GetChecked()
	GoGo_Prefs.DruidClickForm = GoGo_Panel_DruidClickForm:GetChecked()
	GoGo_Prefs.DruidFlightForm = GoGo_Panel_DruidFlightForm:GetChecked()
	GoGo_Prefs.GlobalPrefMount = GoGo_Panel_GlobalPrefMount:GetChecked()
end --function

---------
function GoGo_Settings_Default()
---------
	GoGo_Prefs.version = GetAddOnMetadata(addonName, "Version")
	GoGo_Prefs.autodismount = true
	GoGo_Prefs.DisableMountNotice = false
	GoGo_Prefs.genericfastflyer = false
	GoGo_Prefs.DruidClickForm = true
	GoGo_Prefs.DruidFlightForm = true
	GoGo_Prefs.UnknownMounts = {}
	GoGo_Prefs.GlobalPrefMounts = {}
	GoGo_Prefs.GlobalPrefMount = false
end --function

---------
function GoGo_Settings_SetUpdates()
---------
	GoGo_Prefs.version = GetAddOnMetadata(addonName, "Version")
	if not GoGo_Prefs.autodismount then GoGo_Prefs.autodismount = false end
	if not GoGo_Prefs.DisableMountNotice then GoGo_Prefs.DisableMountNotice = false end
	if not GoGo_Prefs.genericfastflyer then GoGo_Prefs.genericfastflyer = false end
	if not GoGo_Prefs.DruidClickForm then GoGo_Prefs.DruidClickForm = false end
	if not GoGo_Prefs.DruidFlightForm then GoGo_Prefs.DruidFlightForm = false end
	if not GoGo_Prefs.GlobalPrefMount then GoGo_Prefs.GlobalPrefMount = false end
	GoGo_Prefs.UnknownMounts = {}
end --function



function GoGoMount:GetOptions()
	-- Build options table --
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
			}
		}
	}

	return options
end