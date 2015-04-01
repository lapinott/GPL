----------------------------------------------
--            GrindSpot Locations           --
--        Edda's XP Collaborative Map       --
----------------------------------------------

-- Main objects
GPL = {}
GPL.Map = {}
GPL.Options = {}
GPL.UserDB = {}

-- User objects
GPL.User = {}
GPL.User.UserDB = {}
GPL.User.Options = {}
GPL.User.UserDB.Add = {}
GPL.User.UserDB.Dismiss = {}
GPL.User.UserDB.Lvl = {}
GPL.User.UserDB.Move = {}
GPL.User.UserDB.Rate = {}
GPL.User.UserDB.Report = {}
GPL.User.UserDB.Cleansed = {}

-- Textures
GPL.Textures = {}
GPL.Textures.InconActiveRated_u = 'GPL/Textures/w_icon_unrated.dds';
GPL.Textures.InconActiveRated_1 = 'GPL/Textures/w_icon_rated_1.dds';
GPL.Textures.InconActiveRated_2 = 'GPL/Textures/w_icon_rated_2.dds';
GPL.Textures.InconActiveRated_3 = 'GPL/Textures/w_icon_rated_3.dds';
GPL.Textures.InconActiveRated_4 = 'GPL/Textures/w_icon_rated_4.dds';
GPL.Textures.InconActiveRated_5 = 'GPL/Textures/w_icon_rated_5.dds';
GPL.Textures.InconDefaultRated_u = 'GPL/Textures/b_icon_unrated.dds';
GPL.Textures.InconDefaultRated_1 = 'GPL/Textures/b_icon_rated_1.dds';
GPL.Textures.InconDefaultRated_2 = 'GPL/Textures/b_icon_rated_2.dds';
GPL.Textures.InconDefaultRated_3 = 'GPL/Textures/b_icon_rated_3.dds';
GPL.Textures.InconDefaultRated_4 = 'GPL/Textures/b_icon_rated_4.dds';
GPL.Textures.InconDefaultRated_5 = 'GPL/Textures/b_icon_rated_5.dds';

-- Pins
GPL.Pins = {}
GPL.Pins.Rated_1 = "GPL_Pin_r_1";
GPL.Pins.Rated_2 = "GPL_Pin_r_2";
GPL.Pins.Rated_3 = "GPL_Pin_r_3";
GPL.Pins.Rated_4 = "GPL_Pin_r_4";
GPL.Pins.Rated_5 = "GPL_Pin_r_5";
GPL.Pins.Rated_u = "GPL_Pin_r_u";

-- Init main vars
GPL.name = "GPL"
GPL.command = "/gpl"
GPL.version = 0.5
GPL.lastTick = 0
GPL.tick = 250
GPL.VarRevision = 1
GPL.MapRevision = Map.MapRevision;
GPL.MergeRevision = Map.MergeRevision;
GPL.zIndex = 120
GPL.pinSize = 70
GPL.pinMinSize = 70
GPL.pinActiveSize = 80
GPL.pinActiveMinSize = 80
GPL.interactionRadius = 0.05
GPL.minimumPinsDistance = 0.05
GPL.activePinId = nil
GPL.closestPinId = nil
GPL.closestPinDistance = nil
GPL.secondClosestPinId = nil
GPL.secondClosestPinDistance = nil

-- Player's related vars
GPL.PlayerName = GetUnitName("player");
GPL.PlayerAccountName = GetDisplayName();
GPL.PlayerX = nil
GPL.PlayerY = nil
GPL.PlayerPositionHeading = nil

-- Options
GPL.User.Options.debug = false

-- Init
function GPL.Initialize(eventCode, addOnName)

	-- Verify Add-On
	if (addOnName ~= GPL.name) then return end
	
	-- Load user's DB
	GPL.User = ZO_SavedVars:NewAccountWide("GPLUserDB", math.floor(GPL.VarRevision), nil, GPL.User, nil);
	
	-- Set loaded variables
	-- GPL.Options.ConsoleMode = GPL.SavedVars.ConsoleMode;
	-- ...
	-- ... if not GPL.Options.UIMode then GPL.ToggleUI(false) end
	
	-- Register the slash command handler
	SLASH_COMMANDS[GPL.command] = GPL.SlashCommands;
	
	-- Attach Event listeners
	EVENT_MANAGER:RegisterForEvent(GPL.name, EVENT_ZONE_CHANGED, GPL.ZoneChanged);
	EVENT_MANAGER:RegisterForEvent(GPL.name, EVENT_ZONE_UPDATE, GPL.ZoneUpdate);
	
	-- Shortcuts - read-only
	setmetatable (GPL.Options, {__index = GPL.User.Options})
	setmetatable (GPL.UserDB, {__index = GPL.User.UserDB})
	setmetatable (GPL.Map, {__index = Map})
	
	-- Player current map info
	SetMapToPlayerLocation() 
	GPL.CurrentMapIndex = GetCurrentMapIndex()
	GPL.CurrentMapZoneIndex = GetCurrentMapZoneIndex()
	GPL.CurrentMapName = GetPlayerLocationName()
	GPL.CurrentMapTexture = GPL.GetMapTextureName()
	
	-- Layout data table
	GPL.pinLayoutData = {
		["level"] = GPL.zIndex,
		["texture"] = function (pin)
				local pinTypeId, pinTag = pin:GetPinTypeAndTag();
				return GPL.GetPinTexturePath (pinTag["PinType"], pinTag["PinId"] == GPL.activePinId);
			end,
		["size"] = GPL.pinSize,
		["minSize"] = GPL.pinMinSize
	}
	
	-- Pin tooltip creator
	GPL.pinTooltipCreator = {
		creator = function (pin)
		
			-- Get pin tag and ID
			local pinTypeId, pinTag = pin:GetPinTypeAndTag();
			
			-- Get pins for current zone
			local userPins = GPL.UserDB["Add"][GPL.CurrentMapTexture];
			local mapPins = GPL.Map["Nodes"][GPL.CurrentMapTexture];
			
			-- Check if node is a user's node or a downloaded node
			local userNode, mapNode;
			if GPL.Count(userPins) > 0 and userPins[pinTag["PinId"]] ~= nil then userNode = true end
			if GPL.Count(mapPins) > 0 and mapPins[pinTag["PinId"]] ~= nil then mapNode = true end
			
			-- Get node type
			local nodeType = pinTag["PinType"];
			
			-- Get note rating
			local nodeRating;
			if userNode then nodeRating = pinTag["PinData"]["rating"] end
			if mapNode then nodeRating = tonumber(pinTag["PinData"]["rating"]) / tonumber(pinTag["PinData"]["rating_count"]) end
			
			-- Get node lvl
			local nodeLvl;
			if userNode then nodeLvl = math.floor(pinTag["PinData"]["lvl"]) end
			if mapNode then nodeLvl = math.floor(pinTag["PinData"]["lvl"] / pinTag["PinData"]["lvl_count"]) end
			
			-- Create tooltip for user's node
			if userNode then
				
				-- Add lines
				InformationTooltip:AddLine("You just created this node !")
				if nodeLvl ~= 0 then InformationTooltip:AddLine("Node lvl : " .. tostring(nodeLvl)) end
				if nodeRating ~= 0 then InformationTooltip:AddLine("Rating : " .. tostring(nodeRating)) end
				InformationTooltip:AddLine("Please upload it !");
				if GPL.User.Options.debug then InformationTooltip:AddLine(pinTag["PinId"]) end
				
			-- Create tooltip for donwloaded node
			elseif mapNode then
					
					-- Time created
					local diffTime = GetTimeStamp() - pinTag["PinData"]["timestamp"];
					local diffDays = math.floor(diffTime / 86400);
					
					-- Created by
					local createdBy;
					if pinTag["PinData"]["merged"] == 1 then createdBy = "Merged node";
					else createdBy = "Node created by " .. pinTag["PinData"]["@player_name"] end
					
					-- Rating
					local rating = pinTag["PinData"]["rating"];
					local rating_count = pinTag["PinData"]["rating_count"];
					
					-- Add lines
					InformationTooltip:AddLine(createdBy);
					InformationTooltip:AddLine("Created " .. tostring(diffDays) .. " days ago.");
					if nodeRating ~= 0 then InformationTooltip:AddLine("Average lvl : " .. tostring(nodeLvl)) end
					if nodeRating ~= 0 then InformationTooltip:AddLine("Rating : " .. string.format("%.2f", rating / rating_count) .. " - " .. tostring(rating_count) .. " votes") end
					if GPL.User.Options.debug then InformationTooltip:AddLine("Node ID : " .. pinTag["PinId"]) end
					if GPL.User.Options.debug then InformationTooltip:AddLine("Account ID : " .. pinTag["PinData"]["@player_account_name"]) end
					
			else InformationTooltip:AddLine('There was a problem locating this node\'s tooltip.') end
		end,
		
		tooltip = InformationTooltip
	}
	
	-- Clean user's local DB
	GPL.CleanLocalDB();
	
	-- Add all available map pins
	GPL.InitMapPins();
	
	-- Load successful
	d(string.format("GPL v%f loaded.", GPL.version));
	d(string.format("GPL.MapRevision : %d", GPL.MapRevision));
	d(string.format("GPL.MergeRevision : %d", GPL.MergeRevision));

	-- Ready
	GPL.READY = true;

	-- Out
	return true
end

-- Player tracking
function GPL.Track ()

	-- Ready ?
	if not GPL.READY then return nil end

	-- Break if tick not reached
	if GetGameTimeMilliseconds() - GPL.lastTick < GPL.tick then return nil end

	-- Else update ticker
	GPL.lastTick = GetGameTimeMilliseconds();
	
	-- Refresh player position
	GPL.PlayerX, GPL.PlayerY, GPL.PlayerPositionHeading = GetMapPlayerPosition("player");
	
	-- Update distances to current zone pins
	GPL.UpdatePinDistances()
	
	-- out
	return nil
end

-- Update current zone pin distances
function GPL.UpdatePinDistances ()
	
	-- Create available pins container
	local availablePins = {}
	
	-- Get pins for current zone
	local userPins = GPL.UserDB["Add"][GPL.CurrentMapTexture];
	local mapPins = GPL.Map["Nodes"][GPL.CurrentMapTexture];
	
	-- Return if no pins available
	if GPL.Count(userPins) == 0 and GPL.Count(mapPins) == 0 then return false end
	
	-- Add to container
	if GPL.Count(userPins) > 0 then for k, v in pairs(userPins) do availablePins[k] = v end end
	if GPL.Count(mapPins) > 0 then for k, v in pairs(mapPins) do availablePins[k] = v end end
	
	-- Find closest pin ID
	local closestDistance, closestPinId, distance;
	for k, v in pairs(availablePins) do
		distance = math.pow((math.pow((GPL.PlayerX - v["x_coordinate"]), 2) + math.pow((GPL.PlayerY - v["y_coordinate"]), 2)), 0.5);
		if closestDistance == nil or distance < closestDistance then
			closestDistance = distance;
			closestPinId = v["nodeId"];
		end
	end
	
	-- Find second closest pin ID
	local secondClosestDistance, secondClosestPinId;
	for k, v in pairs(availablePins) do
		distance = math.pow((math.pow((GPL.PlayerX - v["x_coordinate"]), 2) + math.pow((GPL.PlayerY - v["y_coordinate"]), 2)), 0.5);
		if (secondClosestDistance == nil or distance < secondClosestDistance) and v["nodeId"] ~= closestPinId then
			secondClosestDistance = distance;
			GPL.secondClosestPinDistance = distance;
			GPL.secondClosestPinId = v["nodeId"];
		end
	end
	
	-- If secondClosestDistance is nil we only have 1 pin on map
	if secondClosestDistance == nil then GPL.secondClosestPinId = nil end
	if secondClosestDistance == nil then GPL.secondClosestPinDistance = nil end
	
	-- Save our previous and current closest pins
	local lastClosestPinId = GPL.closestPinId;
	GPL.closestPinId = closestPinId;
	GPL.closestPinDistance = closestDistance;
	
	-- Previous closest pin type
	local lastClosestPinType, lastClosestPinRating;
	if lastClosestPinId ~= nil and userPins ~= nil and userPins[lastClosestPinId] ~= nil then -- User Pin
	
		lastClosestPinRating = userPins[lastClosestPinId]["rating"]
		lastClosestPinType = GPL.GetPinTypeByRating(lastClosestPinRating);
		
	elseif lastClosestPinId ~= nil and mapPins ~= nil and mapPins[lastClosestPinId] ~= nil then -- Downloaded Pin
	
		lastClosestPinRating = tonumber(mapPins[lastClosestPinId]["rating"]) / tonumber(mapPins[lastClosestPinId]["rating_count"]);
		lastClosestPinType = GPL.GetPinTypeByRating(lastClosestPinRating);
	end
	
	-- Current closest pin type
	local closestPinType, closestPinRating;
	if closestPinId ~= nil and userPins ~= nil and userPins[closestPinId] ~= nil then -- User Pin
	
		closestPinRating = userPins[closestPinId]["rating"]
		closestPinType = GPL.GetPinTypeByRating(closestPinRating);
		
	elseif closestPinId ~= nil and mapPins ~= nil and mapPins[closestPinId] ~= nil then -- Downloaded Pin
	
		closestPinRating = tonumber(mapPins[closestPinId]["rating"]) / tonumber(mapPins[closestPinId]["rating_count"]);
		closestPinType = GPL.GetPinTypeByRating(closestPinRating);
	end
	
	-- If closest distance is bigger than interaction radius then cancel active pin and exit
	if closestDistance > GPL.interactionRadius then
		if GPL.activePinId ~= nil then
			GPL.activePinId = nil
			ZO_WorldMap_RefreshCustomPinsOfType(_G[closestPinType])
		end
		--d('interaction radius exit');
		return nil
		
	-- Else if closest pin id is the same then exit
	elseif GPL.activePinId ~= nil and lastClosestPinId ~= nil and GPL.closestPinId ~= nil and lastClosestPinId == GPL.closestPinId then return nil
	
	-- Else set closest pin active and refresh pin types
	else
		GPL.activePinId = GPL.closestPinId;
		if lastClosestPinType == closestPinType or lastClosestPinType == nil then
			ZO_WorldMap_RefreshCustomPinsOfType(_G[closestPinType])
		else
			ZO_WorldMap_RefreshCustomPinsOfType(_G[lastClosestPinType])
			ZO_WorldMap_RefreshCustomPinsOfType(_G[closestPinType])
		end
	end
	
	return nil
end

-- Clean local DB
function GPL.CleanLocalDB ()
	
	-- Get nodes to clean
	local cleanNodes = Map.Clean[GPL.PlayerAccountName];
	
	-- Return if no nodes to clean
	if GPL.Count (cleanNodes) == 0 then return false end
	
	-- Else clean local nodes
	if GPL.Count (cleanNodes) > 0 then
		
		-- Iterate
		for idx, cleanId in pairs(cleanNodes) do
			
			-- Find local node
			for zoneTexture, zoneNodes in pairs(GPL.UserDB.Add) do
				for nodeId, nodeData in pairs(zoneNodes) do
					if nodeId == cleanId then
					
						-- Delete local node
						GPL.UserDB.Add[zoneTexture][nodeId] = nil
						
						-- Notify for upload
						table.insert(GPL.UserDB.Cleansed, nodeId)
						--d(nodeId .. " cleansed !");
					end
				end
			end
		end
	end
	
	return nil
end

-- Init custom map pins
function GPL.InitMapPins ()
	
	-- Hook our custom pins handlers // Enable // Refresh
	ZO_WorldMap_AddCustomPin(GPL.Pins.Rated_1, GPL.pinTypeAddCallback_1, GPL.pinTypeOnResizeCallback, GPL.pinLayoutData, GPL.pinTooltipCreator);
	ZO_WorldMap_SetCustomPinEnabled(_G[GPL.Pins.Rated_1], true)
	ZO_WorldMap_RefreshCustomPinsOfType(_G[GPL.Pins.Rated_1])
	
	ZO_WorldMap_AddCustomPin(GPL.Pins.Rated_2, GPL.pinTypeAddCallback_2, GPL.pinTypeOnResizeCallback, GPL.pinLayoutData, GPL.pinTooltipCreator);
	ZO_WorldMap_SetCustomPinEnabled(_G[GPL.Pins.Rated_2], true)
	ZO_WorldMap_RefreshCustomPinsOfType(_G[GPL.Pins.Rated_2])
	
	ZO_WorldMap_AddCustomPin(GPL.Pins.Rated_3, GPL.pinTypeAddCallback_3, GPL.pinTypeOnResizeCallback, GPL.pinLayoutData, GPL.pinTooltipCreator);
	ZO_WorldMap_SetCustomPinEnabled(_G[GPL.Pins.Rated_3], true)
	ZO_WorldMap_RefreshCustomPinsOfType(_G[GPL.Pins.Rated_3])
	
	ZO_WorldMap_AddCustomPin(GPL.Pins.Rated_4, GPL.pinTypeAddCallback_4, GPL.pinTypeOnResizeCallback, GPL.pinLayoutData, GPL.pinTooltipCreator);
	ZO_WorldMap_SetCustomPinEnabled(_G[GPL.Pins.Rated_4], true)
	ZO_WorldMap_RefreshCustomPinsOfType(_G[GPL.Pins.Rated_4])
	
	ZO_WorldMap_AddCustomPin(GPL.Pins.Rated_5, GPL.pinTypeAddCallback_5, GPL.pinTypeOnResizeCallback, GPL.pinLayoutData, GPL.pinTooltipCreator);
	ZO_WorldMap_SetCustomPinEnabled(_G[GPL.Pins.Rated_5], true)
	ZO_WorldMap_RefreshCustomPinsOfType(_G[GPL.Pins.Rated_5])
	
	ZO_WorldMap_AddCustomPin(GPL.Pins.Rated_u, GPL.pinTypeAddCallback_u, GPL.pinTypeOnResizeCallback, GPL.pinLayoutData, GPL.pinTooltipCreator);
	ZO_WorldMap_SetCustomPinEnabled(_G[GPL.Pins.Rated_u], true)
	ZO_WorldMap_RefreshCustomPinsOfType(_G[GPL.Pins.Rated_u])
	
	return nil
end

-- Get map texture name
function GPL.GetMapTextureName()

	-- Return texture name
	local texturePath = GetMapTileTexture()
	local _, _, _, _, textureName = string.find(string.lower(texturePath), "(maps/)([%w%-]+)/(.*[^%.dds])")
	return textureName
end

-- Get pin texture path
function GPL.GetPinTexturePath(pinTypeId, pinActive)
	
	if		pinTypeId == GPL.Pins.Rated_1 and not	pinActive then return GPL.Textures.InconDefaultRated_1;
	elseif	pinTypeId == GPL.Pins.Rated_1 and		pinActive then return GPL.Textures.InconActiveRated_1;
	elseif	pinTypeId == GPL.Pins.Rated_2 and not	pinActive then return GPL.Textures.InconDefaultRated_2;
	elseif	pinTypeId == GPL.Pins.Rated_2 and		pinActive then return GPL.Textures.InconActiveRated_2;
	elseif	pinTypeId == GPL.Pins.Rated_3 and not	pinActive then return GPL.Textures.InconDefaultRated_3;
	elseif	pinTypeId == GPL.Pins.Rated_3 and		pinActive then return GPL.Textures.InconActiveRated_3;
	elseif	pinTypeId == GPL.Pins.Rated_4 and not	pinActive then return GPL.Textures.InconDefaultRated_4;
	elseif	pinTypeId == GPL.Pins.Rated_4 and		pinActive then return GPL.Textures.InconActiveRated_4;
	elseif	pinTypeId == GPL.Pins.Rated_5 and not	pinActive then return GPL.Textures.InconDefaultRated_5;
	elseif	pinTypeId == GPL.Pins.Rated_5 and		pinActive then return GPL.Textures.InconActiveRated_5;
	elseif	pinTypeId == GPL.Pins.Rated_u and not	pinActive then return GPL.Textures.InconDefaultRated_u;
	elseif	pinTypeId == GPL.Pins.Rated_u and		pinActive then return GPL.Textures.InconActiveRated_u;
	else
		d('No texture found for ' .. pinTypeId .. ' !!');
		return nil
	end
end

-- Get pin type by rating
function GPL.GetPinTypeByRating(rating)
	
	-- Get rating rounding value
	local round = 0;
	if rating % 1 >= 0.5 then round = 1 end
	
	-- Set rounded rating
	rating = math.floor(rating) + round;
	
	-- Return pin type
	if rating == 0 then return GPL.Pins.Rated_u
	elseif rating == 1 then return GPL.Pins.Rated_1
	elseif rating == 2 then return GPL.Pins.Rated_2
	elseif rating == 3 then return GPL.Pins.Rated_3
	elseif rating == 4 then return GPL.Pins.Rated_4
	elseif rating == 5 then return GPL.Pins.Rated_5
	
	-- Wrong rating value
	else return "Wrong rating value" end
end

-- Pin type on resize callback
function GPL.pinTypeOnResizeCallback () return nil end

-- Callback 1
function GPL.pinTypeAddCallback_1 (pinManager)
	GPL.pinTypeAddCallback (pinManager, GPL.Pins.Rated_1)
end

-- Callback 2
function GPL.pinTypeAddCallback_2 (pinManager)
	GPL.pinTypeAddCallback (pinManager, GPL.Pins.Rated_2)
end

-- Callback 3
function GPL.pinTypeAddCallback_3 (pinManager)
	GPL.pinTypeAddCallback (pinManager, GPL.Pins.Rated_3)
end

-- Callback 4
function GPL.pinTypeAddCallback_4 (pinManager)
	GPL.pinTypeAddCallback (pinManager, GPL.Pins.Rated_4)
end

-- Callback 5
function GPL.pinTypeAddCallback_5 (pinManager)
	GPL.pinTypeAddCallback (pinManager, GPL.Pins.Rated_5)
end

-- Callback u
function GPL.pinTypeAddCallback_u (pinManager)
	GPL.pinTypeAddCallback (pinManager, GPL.Pins.Rated_u)
end

-- Pin type add callback
function GPL.pinTypeAddCallback (pinManager, pinType)

	-- Current zone texture name
	GPL.CurrentMapTexture = GPL.GetMapTextureName();
	
	-- Get pins for current zone
	local userPins = GPL.UserDB["Add"][GPL.CurrentMapTexture];
	local mapPins = GPL.Map["Nodes"][GPL.CurrentMapTexture];
	
	-- Return if no pins available
	if GPL.Count(userPins) == 0 and GPL.Count(mapPins) == 0 then return false end
	
	-- Add user pins to map
	if GPL.Count(userPins) > 0 then
		for k, v in pairs(userPins) do
			local GPLPinType = GPL.GetPinTypeByRating(v.rating);
			if GPLPinType == pinType then
				local PinTag = {["PinId"] = k, ["PinType"] = GPLPinType, ["PinData"] = v}
				pinManager:CreatePin(_G[GPLPinType], PinTag, v.x_coordinate, v.y_coordinate);
				--d('fruity loop ' .. GPLPinType .. " " .. k);
			end
		end
	end
	
	-- Add downloaded pins to map
	if GPL.Count(mapPins) > 0 then
		for k, v in pairs(mapPins) do
			local rating = tonumber(v.rating) / tonumber(v.rating_count);
			local GPLPinType = GPL.GetPinTypeByRating(rating);
			if GPLPinType == pinType then
				local PinTag = {["PinId"] = k, ["PinType"] = GPLPinType, ["PinData"] = v}
				pinManager:CreatePin(_G[GPLPinType], PinTag, v.x_coordinate, v.y_coordinate);
				--d('fruity downloaded loop ' .. GPLPinType .. " " .. k);
			end
		end
	end
	
	return nil
end

-- Event zone changed
function GPL.ZoneChanged (event, zoneName, subZoneName, newSubzone)

	-- New player current map info
	GPL.CurrentMapIndex = GetCurrentMapIndex()
	GPL.CurrentMapZoneIndex = GetCurrentMapZoneIndex()
	GPL.CurrentMapName = GetPlayerLocationName()
	GPL.CurrentMapTexture = GPL.GetMapTextureName()
	
	-- Debug msg
	--if GPL.User.Options.debug then d("GPL.CurrentMapIndex : " .. tostring(GPL.CurrentMapIndex)) end
	--if GPL.User.Options.debug then d("GPL.CurrentMapZoneIndex : " .. tostring(GPL.CurrentMapZoneIndex)) end
	--if GPL.User.Options.debug then d("GPL.CurrentMapName : " .. tostring(GPL.CurrentMapName)) end
	if GPL.User.Options.debug then d("GPL.CurrentMapTexture : " .. tostring(GPL.CurrentMapTexture)) end
	
	-- out
	return nil
end

-- Event zone update
function GPL.ZoneUpdate (event, unitTag, newZoneName)

	-- New player current map info
	GPL.CurrentMapIndex = GetCurrentMapIndex()
	GPL.CurrentMapZoneIndex = GetCurrentMapZoneIndex()
	GPL.CurrentMapName = GetPlayerLocationName()
	GPL.CurrentMapTexture = GPL.GetMapTextureName()
	
	-- Debug msg
	--if GPL.User.Options.debug then d("GPL.CurrentMapIndex : " .. tostring(GPL.CurrentMapIndex)) end
	--if GPL.User.Options.debug then d("GPL.CurrentMapZoneIndex : " .. tostring(GPL.CurrentMapZoneIndex)) end
	--if GPL.User.Options.debug then d("GPL.CurrentMapName : " .. tostring(GPL.CurrentMapName)) end
	if GPL.User.Options.debug then d("GPL.CurrentMapTexture : " .. tostring(GPL.CurrentMapTexture)) end
	
	-- out
	return nil
end

-- Add pin
function GPL.Add ()

	-- Exit if we are too close from closest node
	if GPL.closestPinDistance ~= nil and GPL.closestPinDistance < GPL.minimumPinsDistance then
		d('You are too close to a grindspot ! Please move ' .. tostring(GPL.minimumPinsDistance * 1000) .. ' meters or more away or more from any pin - or use the \'/movehere\' command to move active pin to your location.');
		return nil
	end

	-- Refresh player position
	SetMapToPlayerLocation()
	GPL.PlayerX, GPL.PlayerY, GPL.PlayerPositionHeading = GetMapPlayerPosition("player");
	
	-- Refresh player map info
	GPL.CurrentMapIndex = GetCurrentMapIndex()
	GPL.CurrentMapZoneIndex = GetCurrentMapZoneIndex()
	GPL.CurrentMapName = GetPlayerLocationName()
	GPL.CurrentMapTexture = GPL.GetMapTextureName()
	
	-- Create temporary object for DB
	local data = {}
	
	-- Set current data for DB
	data.nodeId = '@' .. tostring(GetTimeStamp());
	data.timestamp = GetTimeStamp()
	data.gametimemilliseconds = GetGameTimeMilliseconds();
	data.player_name = GPL.PlayerName;
	data.player_lvl = GetUnitLevel("player");
	data.player_veteran_rank = GetUnitVeteranRank("player");
	data.map_name = GPL.CurrentMapName;
	data.map_index = GPL.CurrentMapIndex;
	data.map_zone_index = GPL.CurrentMapZoneIndex;
	data.map_texture_id = GPL.CurrentMapTexture;
	data.x_coordinate = GPL.PlayerX;
	data.y_coordinate = GPL.PlayerY;
	data.lvl = GetUnitLevel("player");
	data.rating = 0;
	
	-- Save current data in local DB
	if GPL.UserDB.Add[GPL.CurrentMapTexture] == nil then GPL.UserDB.Add[GPL.CurrentMapTexture] = {} end
	GPL.UserDB.Add[GPL.CurrentMapTexture][data.nodeId] = data;
	
	-- Set created pin active
	GPL.activePinId = data.nodeId;
	GPL.closestPinId = data.nodeId;
	
	-- Refresh pins
	ZO_WorldMap_RefreshCustomPinsOfType(_G[GPL.Pins.Rated_u]);
	
	-- Notify
	d('A new node has been added to your position.');
	d('Please rate this node\'s quality using \'/gpl rate 1-5\'.');
	
	-- out
	return nil
end

-- Dismiss pin
function GPL.Dismiss ()
	
	-- If no active pin return
	if GPL.activePinId == nil then
		d('You currently have no active node ! Please move ' .. tostring(GPL.interactionRadius * 1000) .. 'm or closer to the desired node.');
		return false
	end
	
	-- Get pins for current zone
	local userPins = GPL.UserDB["Add"][GPL.CurrentMapTexture];
	local mapPins = GPL.Map["Nodes"][GPL.CurrentMapTexture];
	
	-- Return if no pins available
	if GPL.Count(userPins) == 0 and GPL.Count(mapPins) == 0 then return false end
	
	-- Check if node is a user's node or a downloaded node
	local userNode, mapNode;
	if GPL.Count(userPins) > 0 and userPins[GPL.activePinId] ~= nil then userNode = true end
	if GPL.Count(mapPins) > 0 and mapPins[GPL.activePinId] ~= nil then mapNode = true end
	
	-- If user's node, delete node and refresh map
	if userNode then
		local nodeType = GPL.GetPinTypeByRating(userPins[GPL.activePinId]["rating"]);
		local nodeId = GPL.activePinId;
		userPins[GPL.activePinId] = nil;
		GPL.activePinId = nil;
		GPL.closestPinId = nil;
		GPL.closestPinDistance = nil;
		ZO_WorldMap_RefreshCustomPinsOfType(_G[nodeType])
		
		d('Node ID ' .. nodeId .. ' removed.');
	
	-- Else if downloaded node, submit request to database
	elseif mapNode then
	
		-- Create temporary object for DB
		local data = {}
		
		-- Set current data for DB
		data.nodeId = GPL.activePinId
		data.timestamp = GetTimeStamp()
		data.player_account_name = GPL.PlayerAccountName
		
		-- Save dismissal in local DB
		GPL.UserDB.Dismiss[GPL.activePinId] = data;
		
		-- Notify
		d('Your dismissal request was submitted to your local database !');
		
	else d('There was a problem locating active node.') end
end

-- Rate node
function GPL.Rate (rating)
	
	-- If no active pin return
	if GPL.activePinId == nil then
		d('You currently have no active node ! Please move ' .. tostring(GPL.interactionRadius * 1000) .. 'm or closer to the desired node.');
		return false
	end
	
	-- Get pins for current zone
	local userPins = GPL.UserDB["Add"][GPL.CurrentMapTexture];
	local mapPins = GPL.Map["Nodes"][GPL.CurrentMapTexture];
	
	-- Return if no pins available
	if GPL.Count(userPins) == 0 and GPL.Count(mapPins) == 0 then return false end
	
	-- Check if node is a user's node or a downloaded node
	local userNode, mapNode;
	if GPL.Count(userPins) > 0 and userPins[GPL.activePinId] ~= nil then userNode = true end
	if GPL.Count(mapPins) > 0 and mapPins[GPL.activePinId] ~= nil then mapNode = true end
	
	-- If user's node, rate node and refresh map
	if userNode then
	
		-- Save node previous type
		local nodePreviousType = GPL.GetPinTypeByRating(userPins[GPL.activePinId]["rating"]);
		
		-- Update node type
		userPins[GPL.activePinId]["rating"] = rating;
		local nodeType = GPL.GetPinTypeByRating(userPins[GPL.activePinId]["rating"]);
		
		-- Refresh map
		ZO_WorldMap_RefreshCustomPinsOfType(_G[nodePreviousType])
		ZO_WorldMap_RefreshCustomPinsOfType(_G[nodeType])
		
		-- Notify
		d('Active node now rated ' .. tostring(rating) .. '.');
	
	-- Else if downloaded node, submit request to database
	elseif mapNode then
	
		-- Create temporary object for DB
		local data = {}
		
		-- Set current data for DB
		data.nodeId = GPL.activePinId
		data.timestamp = GetTimeStamp()
		data.player_account_name = GPL.PlayerAccountName
		data.rating = rating
		data.player_lvl = GetUnitLevel("player");
		data.player_veteran_rank = GetUnitVeteranRank("player");
		
		-- Save rating in local DB
		GPL.UserDB.Rate[GPL.activePinId] = data;
		
		-- Notify
		d('Your rating was submitted to your local database !');
	
	else d('There was a problem locating active node.') end
end

-- Move node
function GPL.Movehere ()
	
	-- If no active pin return
	if GPL.activePinId == nil then
		d('You currently have no active node ! Please move ' .. tostring(GPL.interactionRadius * 1000) .. 'm or closer to the desired node.');
		return false
	end
	
	-- If wrong desired location return
	if GPL.secondClosestPinDistance ~= nil and GPL.secondClosestPinDistance < GPL.minimumPinsDistance then
		d('Your desired location is too close to another pin ! Pins can\'t be closer than ' .. tostring(GPL.minimumPinsDistance * 1000) .. ' meters. To dismiss current active node use \'/gpl dismiss\'.');
		return false
	end
	
	-- Get pins for current zone
	local userPins = GPL.UserDB["Add"][GPL.CurrentMapTexture];
	local mapPins = GPL.Map["Nodes"][GPL.CurrentMapTexture];
	
	-- Return if no pins available
	if GPL.Count(userPins) == 0 and GPL.Count(mapPins) == 0 then return false end
	
	-- Check if node is a user's node or a downloaded node
	local userNode, mapNode;
	if GPL.Count(userPins) > 0 and userPins[GPL.activePinId] ~= nil then userNode = true end
	if GPL.Count(mapPins) > 0 and mapPins[GPL.activePinId] ~= nil then mapNode = true end
	
	-- If user's node, move node to player's location and refresh map
	if userNode then
	
		-- Set node to player's location
		userPins[GPL.activePinId]["x_coordinate"] = GPL.PlayerX;
		userPins[GPL.activePinId]["y_coordinate"] = GPL.PlayerY;
		
		-- Refresh map
		local nodeType = GPL.GetPinTypeByRating(userPins[GPL.activePinId]["rating"]);
		ZO_WorldMap_RefreshCustomPinsOfType(_G[nodeType])
		
		-- Notify
		d('Active node has been moved to your current location.');
		if GPL.User.Options.debug then d('Closest : ' .. GPL.closestPinId .. " : " .. GPL.closestPinDistance) end
		if GPL.User.Options.debug then d('Second closest : ' .. tostring(GPL.secondClosestPinId) .. " : " .. tostring(GPL.secondClosestPinDistance)) end
	
	-- Else if downloaded node, submit request to database
	elseif mapNode then
	
		-- Create temporary object for DB
		local data = {}
		
		-- Set current data for DB
		data.nodeId = GPL.activePinId
		data.timestamp = GetTimeStamp()
		data.player_account_name = GPL.PlayerAccountName
		data.x_coordinate = GPL.PlayerX
		data.y_coordinate = GPL.PlayerY
		
		-- Save rating in local DB
		GPL.UserDB.Move[GPL.activePinId] = data;
		
		-- Notify
		d('Your move request was submitted to your local database !');
	
	else d('There was a problem locating active node.') end
end

-- Set node level
function GPL.Lvl (lvlFloor, lvlCeiling)

	-- If no active pin return
	if GPL.activePinId == nil then
		d('You currently have no active node ! Please move ' .. tostring(GPL.interactionRadius * 1000) .. 'm or closer to the desired node.');
		return false
	end
	
	-- Get pins for current zone
	local userPins = GPL.UserDB["Add"][GPL.CurrentMapTexture];
	local mapPins = GPL.Map["Nodes"][GPL.CurrentMapTexture];
	
	-- Return if no pins available
	if GPL.Count(userPins) == 0 and GPL.Count(mapPins) == 0 then return false end
	
	-- Check if node is a user's node or a downloaded node
	local userNode, mapNode;
	if GPL.Count(userPins) > 0 and userPins[GPL.activePinId] ~= nil then userNode = true end
	if GPL.Count(mapPins) > 0 and mapPins[GPL.activePinId] ~= nil then mapNode = true end
	
	-- Level average
	local lvlAvg = (lvlFloor + lvlCeiling) / 2;
	
	-- If user's node, set node level
	if userNode then
	
		-- Set node level
		userPins[GPL.activePinId]["lvl"] = lvlAvg;
		
		-- Notify
		d('Node level now set to ' .. tostring(math.floor(lvlAvg)) .. '.');
		
	-- Else if downloaded node, submit request to database
	elseif mapNode then
	
		-- Create temporary object for DB
		local data = {}
		
		-- Set current data for DB
		data.nodeId = GPL.activePinId
		data.timestamp = GetTimeStamp()
		data.player_account_name = GPL.PlayerAccountName
		data.lvl = lvlAvg
		
		-- Save rating in local DB
		GPL.UserDB.Lvl[GPL.activePinId] = data;
		
		-- Notify
		d('Your lvl request was submitted to your local database !');
	
	else d('There was a problem locating active node.') end
end

-- Report
function GPL.Report (message)

	-- Clean message
	message = string.gsub(message, "%[", "");
	message = string.gsub(message, "%]", "");
	message = string.gsub(message, "%\\", "");
	
	-- Create object for DB
	local timestamp = GetTimeStamp();
	local reportId = "@" .. tostring(timestamp);
	local data = {}
	data.nodeId = GPL.activePinId or "nil";
	data.report = message;
	data.timestamp = timestamp;
	
	-- Save report in local DB
	GPL.UserDB.Report[reportId] = data;
	
	-- Notify
	d('Your report was successfully saved in your local database.');
	
	return nil
end

-- Zone info
function GPL.GetZoneInfo ()
	
	-- Refresh player position
	GPL.PlayerX, GPL.PlayerY, GPL.PlayerPositionHeading = GetMapPlayerPosition("player");
	
	-- Refresh player map info
	--SetMapToPlayerLocation()
	GPL.CurrentMapIndex = GetCurrentMapIndex()
	GPL.CurrentMapZoneIndex = GetCurrentMapZoneIndex()
	GPL.CurrentMapName = GetPlayerLocationName()
	GPL.CurrentMapTexture = GPL.GetMapTextureName()
	
	-- Print some zone info
	d("Map index : " .. tostring(GPL.CurrentMapIndex));
	d("Map zone index : " .. tostring(GPL.CurrentMapZoneIndex));
	d("Map texture id : " .. tostring(GPL.CurrentMapTexture));
	d("Map name : " .. tostring(GPL.CurrentMapName));
	d("Player X : " .. tostring(GPL.PlayerX));
	d("Player Y : " .. tostring(GPL.PlayerY));
	
	-- out
	return nil
end

-- Debug log
function GPL.Log (text)
	MXPV_UI_DEBUG_LABEL:SetText(text .. "\n" .. MXPV_UI_DEBUG_LABEL:GetText());
	return nil
end

-- String split
function GPL.SplitCommand(command)

	-- Search for white-space indexes
	local chunk = command;
	local index = string.find(command, " ");
	if index == nil then return {command, nil} end

	-- Iterate our command for white-space indexes
	local explode = {};
	local n = 1;
	while index ~= nil do
		explode[n] = string.sub(chunk, 1, index - 1);
		chunk = string.sub(chunk, index + 1, #chunk);
		index = string.find(chunk, " ");
		n = n + 1;
	end

	-- Add chunk after last white-space
	explode[n] = chunk;

	return {explode[1], explode[2], explode[3]};
end

-- Count table size
function GPL.Count (t)
	if type(t) ~= "table" then return 0 end
	if next(t) == nil then return 0 end
	local count = 0;
	for k, v in pairs(t) do
		if rawget(t, k) ~= nil then count = count + 1 end
	end
	return count;
end

-- Help command
function GPL.GetHelpString()
	local helpString = "\n GPL v" .. GPL.version .. " - Usable commands : \n\n ";
	helpString = helpString .. "- 'add' : adds a grind spot at your current location \n ";
	helpString = helpString .. "- 'dismiss' : dismisses current active grindspot \n ";
	helpString = helpString .. "- 'rate [x]' : rates the currect active grindspot. Values can be 1 to 5. \n ";
	helpString = helpString .. "- 'movehere' : moves current active grinspot to your location \n ";
	helpString = helpString .. "- 'lvl [x]' : lets you specify a lvl for the current active grindspot. Can be used as '/gpl lvl' to set your current lvl to the node. \n ";
	helpString = helpString .. "- 'report YourMessage' : send a report for current active grindspot \n ";
	return helpString;
end

--Test func
GPL.Test = function () GPL.CleanLocalDB() end

-- Slash commands
function GPL.SlashCommands(text)

	local command = GPL.SplitCommand(text);
	local trigger = command[1];

	if (trigger == "?") then d(GPL.GetHelpString());
	elseif (trigger == "add") then GPL.Add();
	elseif (trigger == "dismiss") then GPL.Dismiss();
	elseif (trigger == "rate") then
		local rating = tonumber(command[2]);
		if rating ~= 1 and rating ~= 2 and rating ~= 3 and rating ~= 4 and rating ~= 5 then
			d('Possible ratings can be either 1, 2, 3, 4 or 5 ! Please re-submit your rating.');
		else GPL.Rate (rating) end
	elseif (trigger == "movehere") then GPL.Movehere();
	--[[elseif (trigger == "lvl") then
		local lvlFloor = tonumber(command[2]);
		local lvlCeiling = tonumber(command[3]);
		if command[2] == nil then
			GPL.Lvl (GetUnitLevel("player"), GetUnitLevel("player"))
		elseif command[2] ~= nil and lvlFloor == nil or command[3] ~= nil and lvlCeiling == nil then
			d('Wrong input for \'/lvl\'. Please use numbers between 1 and 50.');
		elseif lvlFloor < 1 or lvlFloor > 50 or lvlCeiling ~= nil and (lvlCeiling < 1 or lvlCeiling > 50) then
			d('Wrong input for \'/lvl\'. Please use numbers between 1 and 50.');
		else
			if lvlCeiling ~= nil then GPL.Lvl (lvlFloor, lvlCeiling);
			else GPL.Lvl (lvlFloor, lvlFloor) end
		end]]
	elseif (trigger == "zone") then GPL.GetZoneInfo();
	elseif (trigger == "test") then GPL.Test();
	elseif (trigger == "debug") then
		GPL.User.Options.debug = not GPL.User.Options.debug;
		d('Debug not set to ' .. tostring(GPL.User.Options.debug));
	elseif (trigger == "report") then GPL.Report (text);
	else d("GPL v" .. GPL.version .. " : No input or wrong command. Type '" .. GPL.command .. " ?' for help.") end

	-- Out
	return nil
end

-- Hook initialization onto the ADD_ON_LOADED event
EVENT_MANAGER:RegisterForEvent(GPL.name, EVENT_ADD_ON_LOADED, GPL.Initialize);
