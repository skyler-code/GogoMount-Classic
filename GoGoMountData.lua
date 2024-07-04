local addonName, addonTable = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

addonTable.bindings = {
	{ title = L["Mount/Dismount"] }, -- main
}
print("BINDING_HEADER_"..addonName:upper())
_G["BINDING_HEADER_"..addonName:upper()] = addonName
for k, v in ipairs(addonTable.bindings) do
    _G["BINDING_NAME_"..addonName:upper().."BINDING"..k] = v.title
end

addonTable.SpellDB = {
	ColdWeatherFlying = 54197,
	FlightMasterLicense = 90267,
	FastFlightForm = 40120,
	FlightForm = 33943,
	AquaForm = 1066,
	TravelForm = 783,
	CatForm = 768,
	GhostWolf = 2645,
	AspectCheetah = 5118,
	AspectHawk = 13165,
	Engineering = 4036,
	Tailoring = 3908,
	KodoRiding = 18996,
	HorseRiding = 824,
	TigerRiding = 828,
	UndeadRiding = 10906,
	RamRiding = 826,
}


	addonTable.TalentIndexDB = {
		ImpGhostWolf = {2, 2, 2},
		FeralSwiftness = {2, 6, 1}
	}

addonTable.MountDB = {
	[5655]  = true,  -- Chestnut Mare
	[8632]  = true,  -- Spotted Frostsaber
	[211498]  = true,  -- Trainee's Sentinel Nightsaber
	[5873] = true,  -- White Ram

	[15290] = true,  -- Brown Kodo
	[18793] = true,  -- Great White Kodo

	[13331] = true,  -- Red Skeletal Horse
	[18791] = true,  -- Purple Skeletal Warhorse

	-- Below are not used for detection, only used to prevent being reported as unknown mounts
	[783] = {[28] = true, spell = true}, -- GOGO_DRUID_TRAVELFORM
	[2645] = {[28] = true, spell = true}, -- GOGO_SHAMAN_GHOSTWOLF
}