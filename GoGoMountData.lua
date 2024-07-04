local addonName, addonTable = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local isVanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

if isVanilla then
	addonTable.bindings = {
		{ title = L["Mount/Dismount"] }, -- main
	}
else
	addonTable.bindings = {
		{ title = L["Mount/Dismount"] }, -- main
		{ title = L["Mount/Dismount (no flying)"], SkipFlyingMount = true }, -- no flying
		{ title = L["Mount/Dismount Passenger Mounts"], SelectPassengerMount = true }, -- passenger mounts
	}
end

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

if isVanilla then

	addonTable.TalentIndexDB = {
		ImpGhostWolf = {2, 2, 2},
		FeralSwiftness = {2, 6, 1}
	}

	addonTable.MountDB = {

		[5655]  = {[14] = true, [20] = true, [38] = true},  -- Chestnut Mare

		
		[8632]  = {[14] = true, [20] = true, [38] = true},  -- Chestnut Mare


		[211498]  = {[1440]=true},  -- Trainee's Sentinel Nightsaber

		[5873] = {[14] = true, [20] = true, [38] = true},  -- White Ram

		[15290] = {[14] = true, [20] = true, [38] = true},  -- Brown Kodo
		[18793] = {[16] = true, [21] = true, [37] = true},  -- Great White Kodo

		
		[13331] = {[14] = true, [20] = true, [38] = true},  -- Red Skeletal Horse
		[18791] = {[16] = true, [21] = true, [37] = true},  -- Purple Skeletal Warhorse
		
		-- Below are not used for detection, only used to prevent being reported as unknown mounts
		[783] = {[28] = true, spell = true}, -- GOGO_DRUID_TRAVELFORM
		[2645] = {[28] = true, spell = true}, -- GOGO_SHAMAN_GHOSTWOLF
	
	}

	for k,v in pairs(addonTable.MountDB) do
		if not v.spell then
			v[4] = true
		end
	end

	addonTable.MountsItems = addonTable.MountDB

else

	addonTable.TalentIndexDB = {
		ImpGhostWolf = {2, 3, 2},
		FeralSwiftness = {2, 12, 1}
	}

	addonTable.MountDB = {
		[25953] = {[16] = true, [21] = true, [38] = true, [50] = true, [51] = true},  -- Blue Qiraji Battle Tank
		[26055] = {[16] = true, [21] = true, [38] = true, [50] = true, [51] = true},  -- Yellow Qiraji Battle Tank
		[26054] = {[16] = true, [21] = true, [38] = true, [50] = true, [51] = true},  -- Red Qiraji Battle Tank
		[26056] = {[16] = true, [21] = true, [38] = true, [50] = true, [51] = true},  -- Green Qiraji Battle Tank
		[26656] = {[16] = true, [21] = true, [37] = true, [51] = true},  -- Black Qiraji Battle Tank

		[30174] = {[15] = true, [25] = true, [39] = true},  -- Riding Turtle
		[64731] = {[5] = true, [15] = true, [25] = true, [39] = true},  -- Sea Turtle
		
		[33189] = {[4] = true, [15] = true, [25] = true, [39] = true},  -- Rickety Magic Broom  --  itemid

		[37011] = {[9] = true, [3] = true, [4] = true, [14] = true, [20] = true, [21] = true, [22] = true, [23] = true, [29] = true, [38] = true},  -- Magic Broom -- itemid

		[33183] = {[16] = true, [20] = true, [38] = true, [4] = true},  -- Magic Broom  --  itemid

		[33176] = {[12] = true, [22] = true, [36] = true, [9] = true, [4] = true},  -- Flying Broom  --  itemid

		[33182] = {[11] = true, [23] = true, [35] = true, [9] = true, [4] = true},  -- Swift Flying Broom  --  itemid
		[33184] = {[16] = true, [23] = true, [37] = true, [9] = true, [4] = true, [999] = true},  -- Swift Magic Broom  --  itemid

		[32243] = {[12] = true, [22] = true, [36] = true, [9] = true},  -- Tawny Wind Rider
		[32244] = {[12] = true, [22] = true, [36] = true, [9] = true},  -- Blue Wind Rider
		[32245] = {[12] = true, [22] = true, [36] = true, [9] = true},  -- Green Wind Rider
		[32246] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Swift Red Wind Rider
		[32295] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Swift Green Wind Rider
		[32296] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Swift Yellow Wind Rider
		[32297] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Swift Purple Wind Rider
		[44229] = {[18] = true, [22] = true, [39] = true, [9] = true, [4] = true, [52] = true},  -- Loaned Wind Rider Reins
		[61230] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Armored Blue Wind Rider

		[37015] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Swift Nether Drake
		[41513] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Onyx Netherwing Drake
		[41514] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Azure Netherwing Drake
		[41515] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Cobalt Netherwing Drake
		[41516] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Purple Netherwing Drake
		[41517] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Veridian Netherwing Drake
		[41518] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Violet Netherwing Drake
		[44317] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Merciless Nether Drake
		[44744] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Merciless Nether Drake
		[49193] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Vengeful Nether Drake
		[58615] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Brutal Nether Drake

		[39798] = {[11] = true, [23] = true, [35] = true, [9] = true, [70] = true},  -- Green Riding Nether Ray
		[39800] = {[11] = true, [23] = true, [35] = true, [9] = true, [70] = true},  -- Red Riding Nether Ray
		[39801] = {[11] = true, [23] = true, [35] = true, [9] = true, [70] = true},  -- Purple Riding Nether Ray
		[39802] = {[11] = true, [23] = true, [35] = true, [9] = true, [70] = true},  -- Silver Riding Nether Ray
		[39803] = {[11] = true, [23] = true, [35] = true, [9] = true, [70] = true},  -- Blue Riding Nether Ray

		[46199] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- X-51 Nether-Rocket X-TREME
		[46197] = {[12] = true, [22] = true, [36] = true, [9] = true},  -- X-51 Nether-Rocket
		[71342] = {[9] = true, [3] = true, [14] = true, [20] = true, [21] = true, [22] = true, [29] = true, [23] = true, [38] = true},  -- Big Love Rocket
		[75973] = {[9] = true, [2] = true, [6] = true, [12] = true, [22] = true, [23] = true, [24] = false, [36] = true},  -- X-53 Touring Rocket
		
		[43927] = {[11] = true, [23] = true, [35] = true, [9] = true, [71] = true},  -- Cenarion War Hippogryph
		[63844] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Argent Hippogryph
		[66087] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Silver Covenant Hippogryph
		[74856] = {[9] = true, [3] = true, [14] = true, [20] = true, [21] = true, [22] = true, [29] = true, [23] = true, [38] = true, [24] = true},  -- Blazing Hippogryph

		[43810] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Frost Wyrm
		[51960] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Frostwyrm Mount
		[64927] = {[9] = true, [11] = true, [24] = true, [35] = true},  -- Deadly Gladiator's Frostwyrm
		[65439] = {[9] = true, [11] = true, [24] = true, [35] = true},  -- Furious Gladiator's Frost Wyrm
		[67336] = {[9] = true, [11] = true, [24] = true, [35] = true},  -- Relentless Gladiator's Frost Wyrm
		[71810] = {[9] = true, [11] = true, [24] = true, [35] = true},  -- Wrathful Gladiator's Frost Wyrm
		
		[72807] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Icebound Frostbrood Vanquisher
		[72808] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Bloodbathed Frostbrood Vanquisher

		[3363] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Nether Drake
		[28828] = {[11] = true, [26] = true, [35] = true, [9] = true},  -- Nether Drake
		[37815] = {[11] = true, [9] = true, [4] = true, [54] = true},  -- Emerald Drake
		[37859] = {[11] = true, [9] = true, [4] = true, [54] = true},  -- Amber Drake
		[37860] = {[11] = true, [9] = true, [4] = true, [54] = true},  -- Ruby Drake
		[59567] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Azure Drake
		[59568] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Blue Drake
		[59569] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Bronze Drake
		[59570] = {[11] = true, [23] = true, [35] = true, [9] = true, [72] = true},  -- Red Drake
		[59571] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Twilight Drake
		[59650] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Black Drake
		[60025] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Albino Drake
		[69395] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Onyxian Drake

		[59961] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Red Proto-Drake
		[59976] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Black Proto-Drake
		[59996] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Blue Proto-Drake
		[60002] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Time-Lost Proto-Drake
		[60021] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Plagued Proto-Drake
		[60024] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Violet Proto-Drake
		[61294] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Green Proto-Drake
		[63956] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Ironbound Proto-Drake
		[63963] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Rusted Proto-Drake

		[32345] = {[11] = true, [24] = true, [9] = true},  -- Peep the Phoenix Mount
		[40192] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Ashes of Al'ar

		[54726] = {[12] = true, [29] = true, [9] = true, [36] = true, [22] = true, [23] = true, [100] = true},  -- Winged Steed of the Ebon Blade
		[54727] = {[12] = true, [29] = true, [9] = true, [36] = true, [22] = true, [23] = true, [100] = true},  -- Winged Steed of the Ebon Blade
		[54729] = {[12] = true, [29] = true, [9] = true, [36] = true, [22] = true, [23] = true, [100] = true},  -- Winged Steed of the Ebon Blade

		[32235] = {[12] = true, [22] = true, [36] = true, [9] = true},  -- Golden Gryphon
		[32239] = {[12] = true, [22] = true, [36] = true, [9] = true},  -- Ebon Gryphon
		[32240] = {[12] = true, [22] = true, [36] = true, [9] = true},  -- Snowy Gryphon
		[32242] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Swift Blue Gryphon
		[32289] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Swift Red Gryphon
		[32290] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Swift Green Gryphon
		[32292] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Swift Purple Gryphon
		[44221] = {[18] = true, [22] = true, [39] = true, [9] = true, [4] = true, [52] = true},  -- Loaned Gryphon Reins
		[55164] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Swift Spectral Gryphon
		[61229] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Armored Snowy Gryphon

		[578] = {[14] = true, [20] = true, [38] = true},  -- Black Wolf
		[579] = {[16] = true, [21] = true, [37] = true},  -- Red Wolf
		[580] = {[14] = true, [20] = true, [38] = true},  -- Timber Wolf
		[581] = {[14] = true, [20] = true, [38] = true},  -- Winter Wolf
		[6653] = {[14] = true, [20] = true, [38] = true},  -- Dire Wolf
		[6654] = {[14] = true, [20] = true, [38] = true},  -- Brown Wolf
		[16080] = {[16] = true, [21] = true, [37] = true},  -- Red Wolf
		[16081] = {[16] = true, [21] = true, [37] = true},  -- Winter Wolf
		[22724] = {[16] = true, [21] = true, [37] = true},  -- Black War Wolf
		[23250] = {[16] = true, [21] = true, [37] = true},  -- Swift Brown Wolf
		[23251] = {[16] = true, [21] = true, [37] = true},  -- Swift Timber Wolf
		[23252] = {[16] = true, [21] = true, [37] = true},  -- Swift Gray Wolf
		[23509] = {[16] = true, [21] = true, [37] = true},  -- Frostwolf Howler
		[63640] = {[16] = true, [21] = true, [37] = true},  -- Origimmar Wolf (Swift Orgrimmar Wolf)
		[64658] = {[14] = true, [20] = true, [38] = true},  -- Black Wolf
		[65646] = {[16] = true, [21] = true, [37] = true},  -- Swift Burgundy Wolf
		[68056] = {[16] = true, [21] = true, [37] = true},  -- Swift Horde Wolf

		[18363] = {[14] = true, [20] = true, [38] = true},  -- Riding Kodo
		[18989] = {[14] = true, [20] = true, [38] = true},  -- Gray Kodo
		[18990] = {[14] = true, [20] = true, [38] = true},  -- Brown Kodo
		[18991] = {[16] = true, [21] = true, [37] = true},  -- Green Kodo
		[18992] = {[16] = true, [21] = true, [37] = true},  -- Teal Kodo
		[22718] = {[16] = true, [21] = true, [37] = true},  -- Black War Kodo
		[23247] = {[16] = true, [21] = true, [37] = true},  -- Great White Kodo
		[23248] = {[16] = true, [21] = true, [37] = true},  -- Great Gray Kodo
		[23249] = {[16] = true, [21] = true, [37] = true},  -- Great Brown Kodo
		[49378] = {[14] = true, [20] = true, [38] = true},  -- Brewfest Riding Kodo
		[49379] = {[16] = true, [21] = true, [37] = true},  -- Great Brewfest Kodo
		[50869] = {[14] = true, [20] = true, [38] = true},  -- Brewfest Kodo
		[63641] = {[16] = true, [21] = true, [37] = true},  -- Thunder Bluff Kodo (Great Mulgore Kodo)
		[64657] = {[14] = true, [20] = true, [38] = true},  -- White Kodo
		[65641] = {[16] = true, [21] = true, [37] = true},  -- Great Golden Kodo
		[69820] = {[16] = true, [21] = true, [37] = true},  -- Sunwalker Kodo
		[69826] = {[16] = true, [21] = true, [37] = true},  -- Sunwalker Kodo

		[34795] = {[14] = true, [20] = true, [38] = true},  -- Red Hawkstrider
		[35018] = {[14] = true, [20] = true, [38] = true},  -- Purple Hawkstrider
		[35020] = {[14] = true, [20] = true, [38] = true},  -- Blue Hawkstrider
		[35022] = {[14] = true, [20] = true, [38] = true},  -- Black Hawkstrider
		[33660] = {[16] = true, [21] = true, [37] = true},  -- Swift Pink Hawkstrider
		[35025] = {[16] = true, [21] = true, [37] = true},  -- Swift Green Hawkstrider
		[35027] = {[16] = true, [21] = true, [37] = true},  --Swift Purple Hawkstrider
		[35028] = {[16] = true, [21] = true, [37] = true},  -- Swift Warstrider
		[46628] = {[16] = true, [21] = true, [37] = true},  -- Swift White Hawkstrider
		[41252] = {[11] = true, [21] = true, [37] = true},  -- Raven Lord
		[63642] = {[16] = true, [21] = true, [37] = true},  -- Silvermoon Hawkstrider (Swift Silvermoon Hawkstrider)
		[65639] = {[16] = true, [21] = true, [37] = true},  -- Swift Red Hawkstrider
		[66091] = {[16] = true, [21] = true, [37] = true},  -- Sunreaver Hawkstrider

		[65917] = {[16] = true, [21] = true, [37] = true},  -- Magic Rooster
		[66122] = {[16] = true, [21] = true, [37] = true},  -- Magic Rooster
		[66123] = {[16] = true, [21] = true, [37] = true},  -- Magic Rooster
		[66124] = {[16] = true, [21] = true, [37] = true},  -- Magic Rooster

		[34790] = {[16] = true, [21] = true, [37] = true},  -- Dark War Talbuk
		[34896] = {[16] = true, [21] = true, [37] = true},  -- Cobalt War Talbuk
		[34897] = {[16] = true, [21] = true, [37] = true},  -- White War Talbuk
		[34898] = {[16] = true, [21] = true, [37] = true},  -- Silver War Talbuk
		[34899] = {[16] = true, [21] = true, [37] = true},  -- Tan War Talbuk
		[39315] = {[16] = true, [21] = true, [37] = true},  -- Cobalt Riding Talbuk
		[39316] = {[16] = true, [21] = true, [37] = true},  -- Dark Riding Talbuk
		[39317] = {[16] = true, [21] = true, [37] = true},  -- Silver Riding Talbuk
		[39318] = {[16] = true, [21] = true, [37] = true},  -- Tan Riding Talbuk
		[39319] = {[16] = true, [21] = true, [37] = true},  -- White Riding Talbuk

		[6777] = {[14] = true, [20] = true, [38] = true},  -- Gray Ram
		[6898] = {[14] = true, [20] = true, [38] = true},  -- White Ram
		[6899] = {[14] = true, [20] = true, [38] = true},  -- Brown Ram
		[17460] = {[16] = true, [21] = true, [37] = true},  -- Frost Ram
		[17461] = {[16] = true, [21] = true, [37] = true},  -- Black Ram
		[22720] = {[16] = true, [21] = true, [37] = true},  -- Black War Ram
		[23238] = {[16] = true, [21] = true, [37] = true},  -- Swift Brown Ram
		[23239] = {[16] = true, [21] = true, [37] = true},  -- Swift Gray Ram
		[23240] = {[16] = true, [21] = true, [37] = true},  -- Swift White Ram
		[23510] = {[16] = true, [21] = true, [37] = true},  -- Stormpike Battle Charger
		[43899] = {[14] = true, [20] = true, [38] = true},  -- Brewfest Ram
		[43900] = {[16] = true, [21] = true, [37] = true},  -- Swift Brewfest Ram
		[63636] = {[16] = true, [21] = true, [37] = true},  -- Ironforge Ram (Swift Ironforge Ram)
		[65643] = {[16] = true, [21] = true, [37] = true},  -- Swift Violet Ram

		[10873] = {[14] = true, [20] = true, [38] = true},  -- Red Mechanostrider
		[10969] = {[14] = true, [20] = true, [38] = true},  -- Blue Mechanostrider
		[15779] = {[16] = true, [21] = true, [37] = true},  -- White Mechanostrider Mod B
		[15780] = {[14] = true, [20] = true, [38] = true},  -- Green Mechanostrider
		[15781] = {[14] = true, [20] = true, [38] = true},  -- Steel Mechanostrider
		[17453] = {[14] = true, [20] = true, [38] = true},  -- Green Mechanostrider
		[17454] = {[14] = true, [20] = true, [38] = true},  -- Unpainted Mechanostrider
		[17455] = {[14] = true, [20] = true, [38] = true},  -- Purple Mechanostrider
		[17456] = {[14] = true, [20] = true, [38] = true},  -- Red and Blue Mechanostrider
		[17458] = {[14] = true, [20] = true, [38] = true},  -- Fluorescent Green Mechanostrider
		[17459] = {[16] = true, [21] = true, [37] = true},  -- Icy Blue Mechanostrider Mod A
		[22719] = {[16] = true, [21] = true, [37] = true},  -- Black Battlestrider
		[23222] = {[16] = true, [21] = true, [37] = true},  -- Swift Yellow Mechanostrider
		[23223] = {[16] = true, [21] = true, [37] = true},  -- Swift White Mechanostrider
		[23225] = {[16] = true, [21] = true, [37] = true},  -- Swift Green Mechanostrider
		[33630] = {[14] = true, [20] = true, [38] = true},  -- Blue Mechanostrider
		[63638] = {[16] = true, [21] = true, [37] = true},  -- Gnomeregan Mechanostrider (Turbostrider)
		[65642] = {[16] = true, [21] = true, [37] = true},  -- Turbostrider

		[8395] = {[14] = true, [20] = true, [38] = true},  -- Emerald Raptor
		[10795] = {[14] = true, [20] = true, [38] = true},  -- Ivory Raptor
		[10796] = {[14] = true, [20] = true, [38] = true},  -- Turquoise Raptor
		[10799] = {[14] = true, [20] = true, [38] = true},  -- Violet Raptor
		[16084] = {[16] = true, [21] = true, [37] = true},  -- Mottled Red Raptor
		[17450] = {[16] = true, [21] = true, [37] = true},  -- Ivory Raptor
		[22721] = {[16] = true, [21] = true, [37] = true},  -- Black War Raptor
		[23241] = {[16] = true, [21] = true, [37] = true},  -- Swift Blue Raptor
		[23242] = {[16] = true, [21] = true, [37] = true},  -- Swift Olive Raptor
		[23243] = {[16] = true, [21] = true, [37] = true},  -- Swift Orange Raptor
		[24242] = {[16] = true, [21] = true, [37] = true},  -- Swift Razzashi Raptor
		[63635] = {[16] = true, [21] = true, [37] = true},  -- Darkspear Raptor (Swift Darkspear Raptor)
		[64659] = {[16] = true, [21] = true, [38] = true},  -- Venomhide Ravasaur
		[65644] = {[16] = true, [21] = true, [37] = true},  -- Swift Purple Raptor

		[43688] = {[11] = true, [21] = true, [37] = true},  -- Amani War Bear
		[51412] = {[16] = true, [21] = true, [37] = true},  -- Big Battle Bear
		[54753] = {[16] = true, [21] = true, [37] = true},  -- White Polar Bear Mount
		[58983] = {[14] = true, [21] = true, [38] = true, [20] = true, [29] = true},  -- Big Blizzard Bear
		[59572] = {[16] = true, [21] = true, [37] = true},  -- Black Polar Bear
		[59573] = {[16] = true, [21] = true, [37] = true},  -- Brown Polar Bear
		[60114] = {[16] = true, [21] = true, [37] = true},  -- Armored Brown Bear
		[60116] = {[16] = true, [21] = true, [37] = true},  -- Armored Brown Bear
		[60118] = {[16] = true, [21] = true, [37] = true},  -- Black War Bear
		[60119] = {[16] = true, [21] = true, [37] = true},  -- Black War Bear

		[8394] = {[14] = true, [20] = true, [38] = true},  -- Striped Frostsaber
		[10789] = {[14] = true, [20] = true, [38] = true},  -- Spotted Frostsaber
		[10793] = {[14] = true, [20] = true, [38] = true},  -- Striped Nightsaber
		[16055] = {[16] = true, [21] = true, [37] = true},  -- Black Nightsaber
		[16056] = {[16] = true, [21] = true, [37] = true},  -- Ancient Frostsaber
		[16058] = {[14] = true, [20] = true, [38] = true},  -- Primal Leopard
		[16059] = {[14] = true, [20] = true, [38] = true},  -- Tawny Sabercat
		[16060] = {[14] = true, [20] = true, [38] = true},  -- Golden Sabercat
		[17229] = {[16] = true, [21] = true, [38] = true},  -- Winterspring Frostsaber
		[22723] = {[16] = true, [21] = true, [37] = true},  -- Black War Tiger
		[23219] = {[16] = true, [21] = true, [37] = true},  -- Swift Mistsaber
		[23220] = {[16] = true, [21] = true, [37] = true},  -- Swift Dawnsaber
		[23221] = {[16] = true, [21] = true, [37] = true},  -- Swift Frostsaber
		[23338] = {[16] = true, [21] = true, [37] = true},  -- Swift Stormsaber
		[24252] = {[16] = true, [21] = true, [37] = true},  -- Swift Zulian Tiger
		[42776] = {[14] = true, [20] = true, [38] = true},  -- Spectral Tiger
		[42777] = {[16] = true, [21] = true, [37] = true},  -- Swift Spectral Tiger
		[63637] = {[16] = true, [21] = true, [37] = true},  -- Darnassian Nightsaber (Swift Darnassian Mistsaber)
		[65638] = {[16] = true, [21] = true, [37] = true},  -- Swift Moonsaber
		[66847] = {[14] = true, [20] = true, [38] = true},  -- Striped Dawnsaber
		
		[458] = {[14] = true, [20] = true, [38] = true},  -- Brown Horse
		[468] = {[14] = true, [20] = true, [38] = true},  -- White Stallion
		[470] = {[14] = true, [20] = true, [38] = true},  -- Black Stallion
		[471] = {[14] = true, [20] = true, [38] = true},  -- Palamino
		[472] = {[14] = true, [20] = true, [38] = true},  -- Pinto
		[5784] = {[14] = true, [20] = true, [38] = true},  -- Felsteed
		[6648] = {[14] = true, [20] = true, [38] = true},  -- Chestnut Mare
		[13819] = {[14] = true, [20] = true, [38] = true},  -- Warhorse
		[16082] = {[16] = true, [21] = true, [37] = true},  -- Palomino
		[16083] = {[16] = true, [21] = true, [37] = true},  -- White Stallion
		[17462] = {[14] = true, [20] = true, [38] = true},  -- Red Skeletal Horse
		[17463] = {[14] = true, [20] = true, [38] = true},  -- Blue Skeletal Horse
		[17464] = {[14] = true, [20] = true, [38] = true},  -- Brown Skeletal Horse
		[17465] = {[16] = true, [21] = true, [37] = true},  -- Green Skeletal Warhorse
		[17481] = {[16] = true, [21] = true, [37] = true},  -- Rivendare's Deathcharger
		[22717] = {[16] = true, [21] = true, [37] = true},  -- Black War Steed
		[22722] = {[16] = true, [21] = true, [37] = true},  -- Red Skeletal Warhorse
		[23161] = {[16] = true, [21] = true, [37] = true},  -- Dreadsteed
		[23214] = {[16] = true, [21] = true, [37] = true},  -- Charger
		[23227] = {[16] = true, [21] = true, [37] = true},  -- Swift Palomino
		[23228] = {[16] = true, [21] = true, [37] = true},  -- Swift White Steed
		[23229] = {[16] = true, [21] = true, [37] = true},  -- Swift Brown Steed
		[23246] = {[16] = true, [21] = true, [37] = true},  -- Purple Skeletal Warhorse
		[34767] = {[16] = true, [21] = true, [37] = true},  -- Summon Charger
		[34769] = {[14] = true, [20] = true, [38] = true},  -- Summon Warhorse
		[36702] = {[16] = true, [21] = true, [37] = true},  -- Fiery Warhorse
		[48025] = {[16] = true, [21] = true, [38] = true, [20] = true, [22] = true, [23] = true, [29] = true, [3] = true, [9] = true},  -- Headless Horseman's Mount
		[48778] = {[16] = true, [21] = true, [37] = true},  -- Acherus Deathcharger
		[58819] = {[16] = true, [21] = true, [37] = true},  -- Swift Brown Steed
		[63232] = {[16] = true, [21] = true, [37] = true},  -- Stormwind Steed (Swift Stormwind Steed)
		[63643] = {[16] = true, [21] = true, [37] = true},  -- Forsaken Warhorse
		[64656] = {[16] = true, [21] = true, [37] = true},  -- Blue Skeletal Warhorse
		[64977] = {[14] = true, [20] = true, [38] = true},  -- Black Skeletal Horse
		[65640] = {[16] = true, [21] = true, [37] = true},  -- Swift Gray Steed
		[65645] = {[16] = true, [21] = true, [37] = true},  -- White Skeletal Warhorse
		[66090] = {[16] = true, [21] = true, [37] = true},  -- Quel'dorei Steed
		[66846] = {[16] = true, [21] = true, [37] = true},  -- Ochre Skeletal Warhorse
		[66906] = {[16] = true, [21] = true, [37] = true},  -- Argent Charger
		[66907] = {[14] = true, [20] = true, [38] = true},  -- Argent Warhorse
		[67466] = {[16] = true, [21] = true, [37] = true},  -- Argent Warhorse
		[68057] = {[16] = true, [21] = true, [37] = true},  -- Swift Alliance Steed
		[68187] = {[16] = true, [21] = true, [37] = true},  -- Crusader's White Warhorse
		[68188] = {[16] = true, [21] = true, [37] = true},  -- Crusader's Black Warhorse
		[72286] = {[9] = true, [3] = true, [14] = true, [20] = true, [21] = true, [22] = true, [29] = true, [23] = true, [38] = true, [24] = true},  -- Invincible
		[73313] = {[16] = true, [21] = true, [37] = true},  -- Crimson Deathcharger
		[75614] = {[9] = true, [3] = true, [6] = true, [14] = true, [20] = true, [21] = true, [22] = true, [29] = true, [23] = true, [38] = true},  -- Celestial Steed
		--[394209] = {[9] = true, [3] = true, [6] = true, [14] = true, [20] = true, [21] = true, [22] = true, [29] = true, [23] = true, [38] = true},  -- Festering Emerald Drake
		--[372677] = {[9] = true, [2] = true, [6] = true, [12] = true, [22] = true, [23] = true, [24] = false, [36] = true},  -- Kalu'ak Whalebone Glider
		
		[34406] = {[14] = true, [20] = true, [38] = true},  -- Brown Elekk
		[34407] = {[16] = true, [21] = true, [37] = true},  -- Great Elite Elekk
		[35710] = {[14] = true, [20] = true, [38] = true},  -- Gray Elekk
		[35711] = {[14] = true, [20] = true, [38] = true},  -- Purple Elekk
		[35712] = {[16] = true, [21] = true, [37] = true},  -- Great Green Elekk
		[35713] = {[16] = true, [21] = true, [37] = true},  -- Great Blue Elekk
		[35714] = {[16] = true, [21] = true, [37] = true},  -- Great Purple Elekk
		[47037] = {[16] = true, [21] = true, [37] = true},  -- Swift War Elekk
		[48027] = {[16] = true, [21] = true, [37] = true},  -- Black War Elekk
		[63639] = {[16] = true, [21] = true, [37] = true},  -- Exodar Elekk  (Great Azuremyst Elekk)
		[65637] = {[16] = true, [21] = true, [37] = true},  -- Grea Red Elekk (Blizzard typo on PTR?)

		[50281] = {[16] = true, [21] = true, [37] = true},  -- Black Warp Stalker

		[59785] = {[16] = true, [21] = true, [37] = true},  -- Black War Mammoth
		[59788] = {[16] = true, [21] = true, [37] = true},  -- Black War Mammoth
		[59791] = {[16] = true, [21] = true, [37] = true},  -- Wooly Mammoth
		[59793] = {[16] = true, [21] = true, [37] = true},  -- Wooly Mammoth
		[59797] = {[16] = true, [21] = true, [37] = true, [73] = true},  -- Ice Mammoth
		[59799] = {[16] = true, [21] = true, [37] = true, [73] = true},  -- Ice Mammoth
		[59802] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Ice Mammoth
		[59804] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Ice Mammoth
		[59810] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Black War Mammoth
		[59811] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Black War Mammoth
		[60136] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Caravan Mammoth
		[60140] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Caravan Mammoth
		[61425] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Traveler's Tundra Mammoth
		[61447] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Traveler's Tundra Mammoth
		[61465] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Black War Mammoth
		[61466] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Black War Mammoth
		[61467] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Black War Mammoth
		[61469] = {[16] = true, [21] = true, [37] = true, [2] = true},  -- Grand Ice Mammoth
		[61470] = {[16] = true, [21] = true, [37] = true, [2] = true, [73] = true},  -- Grand Ice Mammoth
		
		[48954] = {[16] = true, [21] = true, [37] = true},  -- Swift Zhevra
		[49322] = {[16] = true, [21] = true, [37] = true},  -- Swift Zhevra

		[44151] = {[11] = true, [23] = true, [39] = true, [46] = true, [9] = true},  -- Turbo-Charged Flying Machine
		[44153] = {[12] = true, [22] = true, [36] = true, [45] = true, [9] = true},  -- Flying Machine
		[55531] = {[17] = true, [21] = true, [37] = true, [2] = true},  -- Mechano-hog
		[60424] = {[17] = true, [21] = true, [37] = true, [2] = true},  -- Mekgineer's Chopper
		[63796] = {[11] = true, [24] = true, [35] = true, [9] = true},  -- Mimiron's Head

		[61309] = {[11] = true, [23] = true, [49] = true, [9] = true, [35] = true},  -- Magnificent Flying Carpet
		[61442] = {[11] = true, [47] = true, [9] = true, [23] = true, [35] = true},  -- Swift Mooncloth Carpet
		[61444] = {[11] = true, [47] = true, [9] = true, [23] = true, [35] = true},  -- Swift Shadoweave Carpet
		[61446] = {[11] = true, [47] = true, [9] = true, [23] = true, [35] = true},  -- Swift Spellfire Carpet
		[61451] = {[12] = true, [48] = true, [9] = true, [22] = true, [36] = true},  -- Flying Carpet
		[75596] = {[11] = true, [23] = true, [9] = true, [49] = true, [35] = true},  -- Frosty Flying Carpet

		[61996] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Blue Dragonhawk
		[61997] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Red Dragonhawk
		[62048] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Black Dragonhawk Mount
		[66088] = {[11] = true, [23] = true, [35] = true, [9] = true},  -- Sunreaver Dragonhawk
		
		[74918] = {[16] = true, [21] = true, [37] = true},  -- Wooly White Rhino
		
		-- Below are not used for detection, only used to prevent being reported as unknown mounts
		[40120] = {[9] = true, [11] = true, [23] = true},  -- GOGO_DRUID_FAST_FLIGHTFORM
		[33943] = {[9] = true, [11] = true, [22] = true},  -- GOGO_DRUID_FLIGHTFORM
		[783] = {[28] = true}, -- GOGO_DRUID_TRAVELFORM
		[2645] = {[28] = true}, -- GOGO_SHAMAN_GHOSTWOLF
	}

	addonTable.MountsItems = {
		[33189] = true, -- Rickety Magic Broom
		[37011] = true, -- Magic Broom
		[33183] = true, -- Old Magic Broom
		[33176] = true, -- Flying Broom
		[33182] = true, -- Swift Flying Broom
		[33184] = true, -- Swift Magic Broom
		[44229] = true, -- Loaned Wind Rider Reins
		[44221] = true, -- Loaned Gryphon Reins
		[37859] = true, -- Amber Essence
		[37860] = true, -- Ruby Essence
		[37815] = true, -- Emerald Essence
	}
end