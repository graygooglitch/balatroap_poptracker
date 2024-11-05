-- this is an example/default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via thier ids
-- it will also keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
-- if you run into issues when touching A LOT of items/locations here, see the comment about Tracker.AllowDeferredLogicUpdate in autotracking.lua
ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")

CUR_INDEX = -1
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}
STAKE_ORDER = {}
STAKE_UNLOCK_MODE = 0
JOKER_BUNDLES = {}
PLANET_BUNDLES = {}
SPECTRAL_BUNDLES = {}
TAROT_BUNDLES = {}
ALL_DECKS = {
	"red",
	"blue",
	"yellow",
	"green",
	"black",
	"magic",
	"nebula",
	"ghost",
	"abandoned",
	"checkered",
	"zodiac",
	"painted",
	"anaglyph",
	"plasma",
	"erratic"
}
INCLUDED_DECKS = {}
INCLUDED_DECK_MAP ={
	"b_red",
	"b_blue",
	"b_yellow",
	"b_green",
	"b_black",
	"b_magic",
	"b_nebula",
	"b_ghost",
	"b_abandoned",
	"b_checkered",
	"b_zodiac",
	"b_painted",
	"b_anaglyph",
	"b_plasma",
	"b_erratic"
}
ALL_STAKES = {
	"whitestake",
	"redstake",
	"greenstake",
	"blackstake",
	"bluestake",
	"purplestake",
	"orangestake",
	"goldstake"
}

-- resets an item to it's inital state
function resetItem(item_code, item_type)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: resetting item %s of type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = false
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			obj.CurrentStage = 0
			obj.Active = false
		elseif item_type == "consumable" then
			obj.AcquiredCount = 0
		elseif item_type == "custom" then
			-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: tried to reset static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"resetItem: tried to reset composite_toggle item %s but composite_toggle cannot be accessed via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("resetItem: could not find item object for code %s", item_code))
	end
end

-- advances the state of an item
function incrementItem(item_code, item_type)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: code: %s, type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = true
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			if obj.Active then
				obj.CurrentStage = obj.CurrentStage + 1
			else
				obj.Active = true
			end
		elseif item_type == "consumable" then
			obj.AcquiredCount = obj.AcquiredCount + obj.Increment
		elseif item_type == "custom" then
			-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: tried to increment static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"incrementItem: tried to increment composite_toggle item %s but composite_toggle cannot be access via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: unknown item type %s for code %s", item_type, item_code))
		end
		if STAKE_UNLOCK_MODE == 0 then
			local deckid = 0
			if string.find(item_code,"reddeck") then deckid = 1 end
			if string.find(item_code,"bluedeck") then deckid = 2 end
			if string.find(item_code,"yellowdeck") then deckid = 3 end
			if string.find(item_code,"greendeck") then deckid = 4 end
			if string.find(item_code,"blackdeck") then deckid = 5 end
			if string.find(item_code,"magicdeck") then deckid = 6 end
			if string.find(item_code,"nebuladeck") then deckid = 7 end
			if string.find(item_code,"ghostdeck") then deckid = 8 end
			if string.find(item_code,"abandoneddeck") then deckid = 9 end
			if string.find(item_code,"checkereddeck") then deckid = 10 end
			if string.find(item_code,"tarotdeck") then deckid = 11 end
			if string.find(item_code,"painteddeck") then deckid = 12 end
			if string.find(item_code,"anaglyphdeck") then deckid = 13 end
			if string.find(item_code,"plasmadeck") then deckid = 14 end
			if string.find(item_code,"erraticdeck") then deckid = 15 end
			if deckid ~= 0 then
				--it was a deck
				for index, stakes in ipairs(STAKE_ORDER) do
					Tracker:FindObjectForCode(ALL_DECKS[deckid].."deck"..ALL_STAKES[STAKE_ORDER[index]].."access").Active = true
				end
			end
		end

		if STAKE_UNLOCK_MODE == 1 or STAKE_UNLOCK_MODE == 2 then
			local deckid = 0
			if string.find(item_code,"reddeck") then deckid = 1 end
			if string.find(item_code,"bluedeck") then deckid = 2 end
			if string.find(item_code,"yellowdeck") then deckid = 3 end
			if string.find(item_code,"greendeck") then deckid = 4 end
			if string.find(item_code,"blackdeck") then deckid = 5 end
			if string.find(item_code,"magicdeck") then deckid = 6 end
			if string.find(item_code,"nebuladeck") then deckid = 7 end
			if string.find(item_code,"ghostdeck") then deckid = 8 end
			if string.find(item_code,"abandoneddeck") then deckid = 9 end
			if string.find(item_code,"checkereddeck") then deckid = 10 end
			if string.find(item_code,"tarotdeck") then deckid = 11 end
			if string.find(item_code,"painteddeck") then deckid = 12 end
			if string.find(item_code,"anaglyphdeck") then deckid = 13 end
			if string.find(item_code,"plasmadeck") then deckid = 14 end
			if string.find(item_code,"erraticdeck") then deckid = 15 end
			if deckid ~= 0 then
				--it was a deck
				-- Unlock in order, find first and unlock all active decks for that stake
				local firststake = STAKE_ORDER[1]
				for incindex, incdeck in pairs( INCLUDED_DECKS ) do
					local activedeck = 0
					for deckindex, deck in pairs(INCLUDED_DECK_MAP) do
						if INCLUDED_DECK_MAP[deckindex] == incdeck then activedeck = deckindex end
					end
					if Tracker:FindObjectForCode(ALL_DECKS[activedeck].."deck").Active == true then
						Tracker:FindObjectForCode(ALL_DECKS[activedeck].."deck"..ALL_STAKES[firststake].."access").Active = true
					end
				end
			end
		end

		-- Handle Access tokens for 3
		if STAKE_UNLOCK_MODE == 3 then 
			-- if color stake then unlock all access tokens for included decks
			-- if deck then unlock all access tokens for included stakes
			local deckid = 0
			local stakeid = 0
			if string.find(item_code,"whitestake") then stakeid=1 end
			if string.find(item_code,"redstake") then stakeid=2 end
			if string.find(item_code,"greenstake") then stakeid=3 end
			if string.find(item_code,"blackstake") then stakeid=4 end
			if string.find(item_code,"bluestake") then stakeid=5 end
			if string.find(item_code,"purplestake") then stakeid=6 end
			if string.find(item_code,"orangestake") then stakeid=7 end
			if string.find(item_code,"goldstake") then stakeid=8 end
			if string.find(item_code,"reddeck") then deckid = 1 end
			if string.find(item_code,"bluedeck") then deckid = 2 end
			if string.find(item_code,"yellowdeck") then deckid = 3 end
			if string.find(item_code,"greendeck") then deckid = 4 end
			if string.find(item_code,"blackdeck") then deckid = 5 end
			if string.find(item_code,"magicdeck") then deckid = 6 end
			if string.find(item_code,"nebuladeck") then deckid = 7 end
			if string.find(item_code,"ghostdeck") then deckid = 8 end
			if string.find(item_code,"abandoneddeck") then deckid = 9 end
			if string.find(item_code,"checkereddeck") then deckid = 10 end
			if string.find(item_code,"tarotdeck") then deckid = 11 end
			if string.find(item_code,"painteddeck") then deckid = 12 end
			if string.find(item_code,"anaglyphdeck") then deckid = 13 end
			if string.find(item_code,"plasmadeck") then deckid = 14 end
			if string.find(item_code,"erraticdeck") then deckid = 15 end
			
			if deckid ~= 0 then
				--it was a deck
				for index, stakes in ipairs(STAKE_ORDER) do
					if Tracker:FindObjectForCode(ALL_STAKES[STAKE_ORDER[index]]).Active then
						Tracker:FindObjectForCode(ALL_DECKS[deckid].."deck"..ALL_STAKES[STAKE_ORDER[index]].."access").Active = true
					end
				end
			elseif stakeid ~=0 then
				--it was a stake
				for incindex, incdeck in pairs( INCLUDED_DECKS ) do
					local activedeck = 0
					for deckindex, deck in pairs(INCLUDED_DECK_MAP) do
						if INCLUDED_DECK_MAP[deckindex] == incdeck then activedeck = deckindex end
					end
					if Tracker:FindObjectForCode(ALL_DECKS[activedeck].."deck").Active then
						Tracker:FindObjectForCode(ALL_DECKS[activedeck].."deck"..ALL_STAKES[stakeid].."access").Active = true
					end
				end
			end
		end

		-- Handles Deck and Stake item unlocks for 4
		if STAKE_UNLOCK_MODE == 4 then 
			if string.match(item_code,"access") then
				if string.find(item_code,"whitestake") then Tracker:FindObjectForCode("whitestake").Active = true end
				if string.find(item_code,"redstake") then Tracker:FindObjectForCode("redstake").Active = true end
				if string.find(item_code,"greenstake") then Tracker:FindObjectForCode("greenstake").Active = true end
				if string.find(item_code,"blackstake") then Tracker:FindObjectForCode("blackstake").Active = true end
				if string.find(item_code,"bluestake") then Tracker:FindObjectForCode("bluestake").Active = true end
				if string.find(item_code,"purplestake") then Tracker:FindObjectForCode("purplestake").Active = true end
				if string.find(item_code,"orangestake") then Tracker:FindObjectForCode("orangestake").Active = true end
				if string.find(item_code,"goldstake") then Tracker:FindObjectForCode("goldstake").Active = true end
				if string.find(item_code,"reddeck") then Tracker:FindObjectForCode("reddeck").Active = true end
				if string.find(item_code,"bluedeck") then Tracker:FindObjectForCode("bluedeck").Active = true end
				if string.find(item_code,"yellowdeck") then Tracker:FindObjectForCode("yellowdeck").Active = true end
				if string.find(item_code,"greendeck") then Tracker:FindObjectForCode("greendeck").Active = true end
				if string.find(item_code,"blackdeck") then Tracker:FindObjectForCode("blackdeck").Active = true end
				if string.find(item_code,"magicdeck") then Tracker:FindObjectForCode("magicdeck").Active = true end
				if string.find(item_code,"nebuladeck") then Tracker:FindObjectForCode("nebuladeck").Active = true end
				if string.find(item_code,"ghostdeck") then Tracker:FindObjectForCode("ghostdeck").Active = true end
				if string.find(item_code,"abandoneddeck") then Tracker:FindObjectForCode("abandoneddeck").Active = true end
				if string.find(item_code,"checkereddeck") then Tracker:FindObjectForCode("checkereddeck").Active = true end
				if string.find(item_code,"tarotdeck") then Tracker:FindObjectForCode("tarotdeck").Active = true end
				if string.find(item_code,"painteddeck") then Tracker:FindObjectForCode("painteddeck").Active = true end
				if string.find(item_code,"anaglyphdeck") then Tracker:FindObjectForCode("anaglyphdeck").Active = true end
				if string.find(item_code,"plasmadeck") then Tracker:FindObjectForCode("plasmadeck").Active = true end
				if string.find(item_code,"erraticdeck") then Tracker:FindObjectForCode("erraticdeck").Active = true end
			end
		end
		if string.match(item_code,"jb") then
			local num = tonumber(string.sub(item_code,3,-1))
			if num==0 then
				--there is no big joker budnle
			else
				local bundle = JOKER_BUNDLES[num]
				for _, joker in ipairs(bundle) do
					Tracker:FindObjectForCode(ITEM_MAPPING[joker][1][1]).Active=true
				end
			end
			reconcile_joker_count()		
		elseif string.match(item_code,"pb") then
			local num = tonumber(string.sub(item_code,3,-1))
			if num==0 then
				for i = 5606236, 5606248, 1 do
					Tracker:FindObjectForCode(ITEM_MAPPING[i][1][1]).Active=true
				end
			else
				local bundle = PLANET_BUNDLES[num]
				for _, planet in ipairs(bundle) do
					Tracker:FindObjectForCode(ITEM_MAPPING[planet][1][1]).Active=true
				end
			end		
			reconcile_planet_count()
		elseif string.match(item_code,"sb") then
			local num = tonumber(string.sub(item_code,3,-1))
			if num==0 then
				--big bundle release everything
				for i = 5606249, 5606267, 1 do
					Tracker:FindObjectForCode(ITEM_MAPPING[i][1][1]).Active=true
				end
			else
				local bundle = SPECTRAL_BUNDLES[num]
				for _, spec in ipairs(bundle) do
					Tracker:FindObjectForCode(ITEM_MAPPING[spec][1][1]).Active=true
				end
			end		
			reconcile_spectral_count()
		elseif string.match(item_code,"tb") then
			local num = tonumber(string.sub(item_code,3,-1))
			if num==0 then
				for i = 5606213, 5606235, 1 do
					Tracker:FindObjectForCode(ITEM_MAPPING[i][1][1]).Active=true
				end
			else
				local bundle = TAROT_BUNDLES[num]
				for _, tarot in ipairs(bundle) do
					Tracker:FindObjectForCode(ITEM_MAPPING[tarot][1][1]).Active=true
				end
			end
		end
		reconcile_tarot_count()
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("incrementItem: could not find object for code %s", item_code))
	end
end

function reconcile_joker_count()
	local num = 0
	for i = 5606016, 5606165, 1 do
		if Tracker:FindObjectForCode(ITEM_MAPPING[i][1][1]).Active==true then
			num= num + 1
		end
	end
	Tracker:FindObjectForCode("jokercount").AcquiredCount = num
end
function reconcile_planet_count()
	local num = 0
	for i = 5606236, 5606248, 1 do
		if Tracker:FindObjectForCode(ITEM_MAPPING[i][1][1]).Active==true then
			num= num + 1
		end
	end
	Tracker:FindObjectForCode("planetcount").AcquiredCount = num
end
function reconcile_spectral_count()
	local num = 0
	for i = 5606249, 5606267, 1 do
		if Tracker:FindObjectForCode(ITEM_MAPPING[i][1][1]).Active==true then
			num= num + 1
		end
	end
	Tracker:FindObjectForCode("spectralcount").AcquiredCount = num
end
function reconcile_tarot_count()
	local num = 0
	for i = 5606213, 5606235, 1 do
		if Tracker:FindObjectForCode(ITEM_MAPPING[i][1][1]).Active==true then
			num= num + 1
		end
	end
	Tracker:FindObjectForCode("tarotcount").AcquiredCount = num
end

-- apply everything needed from slot_data, called from onClear
function apply_slot_data(slot_data)
	
	-- put any code here that slot_data should affect (toggling setting items for example)
	STAKE_UNLOCK_MODE = slot_data["stake_unlock_mode"]
	JOKER_BUNDLES = slot_data["jokerbundles"]
	PLANET_BUNDLES = slot_data["planet_bundles"]
	SPECTRAL_BUNDLES = slot_data["spectral_bundles"]
	TAROT_BUNDLES = slot_data["tarot_bundles"]
	INCLUDED_DECKS = slot_data["included_decks"]
	STAKE_ORDER = slot_data["included_stakes"]
	local planet_bundles = slot_data["planet_bundles"]
	local tarot_bundles = slot_data["tarot_bundles"]
	local spectral_bundles = slot_data["spectral_bundles"]
	local joker_bundles = slot_data["jokerbundles"]

	--handle setting consumables max
	local consumables = slot_data["consumable_pool_locations"]
	local consumables_length = 0
	for Index, Value in pairs( consumables ) do
		consumables_length = consumables_length + 1
	end
	local obj = Tracker:FindObjectForCode("@Grid/Consumables/Consumables")
	obj.AvailableChestCount = consumables_length
	local shops = slot_data["stake1_shop_locations"]
	local shop_length = 0
	for Index, Value in pairs( shops ) do
		shop_length = shop_length + 1
	end
	--Assign Shops the same length
	obj = Tracker:FindObjectForCode("@Grid/Shop Items, White Stakes/Shop Items")
	obj.AvailableChestCount = shop_length
	obj = Tracker:FindObjectForCode("@Grid/Shop Items, Red Stakes/Shop Items")
	obj.AvailableChestCount = shop_length
	obj = Tracker:FindObjectForCode("@Grid/Shop Items, Green Stakes/Shop Items")
	obj.AvailableChestCount = shop_length
	obj = Tracker:FindObjectForCode("@Grid/Shop Items, Black Stakes/Shop Items")
	obj.AvailableChestCount = shop_length
	obj = Tracker:FindObjectForCode("@Grid/Shop Items, Blue Stakes/Shop Items")
	obj.AvailableChestCount = shop_length
	obj = Tracker:FindObjectForCode("@Grid/Shop Items, Purple Stakes/Shop Items")
	obj.AvailableChestCount = shop_length
	obj = Tracker:FindObjectForCode("@Grid/Shop Items, Orange Stakes/Shop Items")
	obj.AvailableChestCount = shop_length
	obj = Tracker:FindObjectForCode("@Grid/Shop Items, Gold Stakes/Shop Items")
	obj.AvailableChestCount = shop_length
	--
	-- get number of bundles for each bundle and set maximium on the consumable
	
	local bundle_length = 0
	for Index, Value in pairs( planet_bundles ) do
		bundle_length = bundle_length + 1
	end
	obj = Tracker:FindObjectForCode("pbcon")
	obj.MaxCount = bundle_length

	bundle_length = 0
	for Index, Value in pairs( spectral_bundles ) do
		bundle_length = bundle_length + 1
	end
	obj = Tracker:FindObjectForCode("sbcon")
	obj.MaxCount = bundle_length 

	bundle_length = 0
	for Index, Value in pairs( tarot_bundles ) do
		bundle_length = bundle_length + 1
	end
	obj = Tracker:FindObjectForCode("tbcon")
	obj.MaxCount = bundle_length 

	bundle_length = 0
	for Index, Value in pairs( joker_bundles ) do
		bundle_length = bundle_length + 1
	end
	obj = Tracker:FindObjectForCode("jbcon")
	obj.MaxCount = bundle_length 
	--set visibility for decks and stakes
	for _, stake in ipairs(STAKE_ORDER) do
		if stake == 1 then Tracker:FindObjectForCode("whitesip").Active = true end
		if stake == 2 then Tracker:FindObjectForCode("redsip").Active = true end
		if stake == 3 then Tracker:FindObjectForCode("greensip").Active = true end
		if stake == 4 then Tracker:FindObjectForCode("blacksip").Active = true end
		if stake == 5 then Tracker:FindObjectForCode("bluesip").Active = true end
		if stake == 6 then Tracker:FindObjectForCode("purplesip").Active = true end
		if stake == 7 then Tracker:FindObjectForCode("orangesip").Active = true end
		if stake == 8 then Tracker:FindObjectForCode("goldsip").Active = true end
	end
	for incindex, incdeck in pairs( INCLUDED_DECKS ) do
		local activedeck = 0
		for deckindex, deck in pairs(INCLUDED_DECK_MAP) do
			if INCLUDED_DECK_MAP[deckindex] == incdeck then activedeck = deckindex end
		end
		Tracker:FindObjectForCode(ALL_DECKS[activedeck].."dip").Active = true
	end
	--Handle Access tokens for 0,3,4
	if STAKE_UNLOCK_MODE == 0 then

		for _, stake in pairs(ALL_STAKES) do
			for _, deck in pairs(ALL_DECKS) do	
				if Tracker:FindObjectForCode(deck.."deck").Active == true then
					Tracker:FindObjectForCode(deck.."deck"..stake.."access").Active = true
				end
			end
		end
	--Handle initial Access tokens for 1 & 2
	elseif STAKE_UNLOCK_MODE == 1 or STAKE_UNLOCK_MODE == 2 then
		-- Unlock in order, find first and unlock all active decks for that stake
		local firststake = STAKE_ORDER[1]
		for incindex, incdeck in pairs( INCLUDED_DECKS ) do
			local activedeck = 0
			for deckindex, deck in pairs(INCLUDED_DECK_MAP) do
				if INCLUDED_DECK_MAP[deckindex] == incdeck then activedeck = deckindex end
			end
			if Tracker:FindObjectForCode(ALL_DECKS[activedeck].."deck").Active == true then
				Tracker:FindObjectForCode(ALL_DECKS[activedeck].."deck"..ALL_STAKES[firststake].."access").Active = true
			end
		end
	end	
	print(dump_table(slot_data))
end

-- called right after an AP slot is connected
function onClear(slot_data)
	-- use bulk update to pause logic updates until we are done resetting all items/locations
	Tracker.BulkUpdate = true	
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
	end
	CUR_INDEX = -1
	-- reset locations
	for _, mapping_entry in pairs(LOCATION_MAPPING) do
		for _, location_table in ipairs(mapping_entry) do
			if location_table then
				local location_code = location_table[1]
				if location_code then
					if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
						print(string.format("onClear: clearing location %s", location_code))
					end
					if location_code:sub(1, 1) == "@" then
						local obj = Tracker:FindObjectForCode(location_code)
						if obj then
							obj.AvailableChestCount = obj.ChestCount
						elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
							print(string.format("onClear: could not find location object for code %s", location_code))
						end
					else
						-- reset hosted item
						local item_type = location_table[2]
						resetItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping location_table with no location_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty location_table"))
			end
		end
	end
	-- reset items
	for _, mapping_entry in pairs(ITEM_MAPPING) do
		for _, item_table in ipairs(mapping_entry) do
			if item_table then
				local item_code = item_table[1]
				local item_type = item_table[2]
				if item_code then
					resetItem(item_code, item_type)
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping item_table with no item_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty item_table"))
			end
		end
	end
	apply_slot_data(slot_data)
	LOCAL_ITEMS = {}
	GLOBAL_ITEMS = {}
	Tracker.BulkUpdate = false
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
	end
	if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
		return
	end
	if index <= CUR_INDEX then
		return
	end
	local is_local = player_number == Archipelago.PlayerNumber
	CUR_INDEX = index;
	local mapping_entry = ITEM_MAPPING[item_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onItem: could not find item mapping for id %s", item_id))
		end
		return
	end
	for _, item_table in pairs(mapping_entry) do
		if item_table then
			local item_code = item_table[1]
			local item_type = item_table[2]
			if item_code then
				incrementItem(item_code, item_type)
				-- keep track which items we touch are local and which are global
				if is_local then
					if LOCAL_ITEMS[item_code] then
						LOCAL_ITEMS[item_code] = LOCAL_ITEMS[item_code] + 1
					else
						LOCAL_ITEMS[item_code] = 1
					end
				else
					if GLOBAL_ITEMS[item_code] then
						GLOBAL_ITEMS[item_code] = GLOBAL_ITEMS[item_code] + 1
					else
						GLOBAL_ITEMS[item_code] = 1
					end
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping item_table with no item_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onClear: skipping empty item_table"))
		end
	end
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
		print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
	end
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onLocation: %s, %s", location_id, location_name))
	end
	if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local mapping_entry = LOCATION_MAPPING[location_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: could not find location mapping for id %s", location_id))
		end
		return
	end
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			if location_code then
				local obj = Tracker:FindObjectForCode(location_code)
				if obj then
					if location_code:sub(1, 1) == "@" then
						obj.AvailableChestCount = obj.AvailableChestCount - 1
					else
						-- increment hosted item
						local item_type = location_table[2]
						incrementItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onLocation: could not find object for code %s", location_code))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onLocation: skipping location_table with no location_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: skipping empty location_table"))
		end
	end

	-- Handle distributing Access tokens for 1 & 2
	if STAKE_UNLOCK_MODE == 1 or STAKE_UNLOCK_MODE == 2 then
		if string.find(location_name,"Ante 8") then 
			local deckid = 1
			local stakeid = 1
			if string.find(location_name,"White Stake") then stakeid = 1 end
			if string.find(location_name,"Red Stake") then stakeid = 2 end
			if string.find(location_name,"Green Stake") then stakeid = 3 end
			if string.find(location_name,"Black Stake") then stakeid = 4 end
			if string.find(location_name,"Blue Stake") then stakeid = 5 end
			if string.find(location_name,"Purple Stake") then stakeid = 6 end
			if string.find(location_name,"Orange Stake") then stakeid = 7 end
			if string.find(location_name,"Gold Stake") then stakeid = 8 end
			if string.find(location_name,"Red Deck") then deckid=1 end
			if string.find(location_name,"Blue Deck") then deckid=2 end
			if string.find(location_name,"Yellow Deck") then deckid=3 end
			if string.find(location_name,"Green Deck") then deckid=4 end
			if string.find(location_name,"Black Deck") then deckid=5 end
			if string.find(location_name,"Magic Deck") then deckid=6 end
			if string.find(location_name,"Nebula Deck") then deckid=7 end
			if string.find(location_name,"Ghost Deck") then deckid=8 end
			if string.find(location_name,"Abandoned Deck") then deckid=9 end
			if string.find(location_name,"Checkered Deck") then deckid=10 end
			if string.find(location_name,"Tarot Deck") then deckid=11 end
			if string.find(location_name,"Painted Deck") then deckid=12 end
			if string.find(location_name,"Anaglyph Deck") then deckid=13 end
			if string.find(location_name,"Plasma Deck") then deckid=14 end
			if string.find(location_name,"Erratic Deck") then deckid=15 end
			for index, stakes in ipairs(STAKE_ORDER) do
				if stakes == stakeid then 
				Tracker:FindObjectForCode(ALL_DECKS[deckid].."deck"..ALL_STAKES[STAKE_ORDER[index+1]].."access").Active = true
				end
			end
		end
	end
end

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
			item_player))
	end
	-- not implemented yet :(
end

-- called when a bounce message is received
function onBounce(json)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onBounce: %s", dump_table(json)))
	end
	-- your code goes here
end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
	Archipelago:AddLocationHandler("location handler", onLocation)
end
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)
