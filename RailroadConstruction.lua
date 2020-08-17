-- RailroadConstruction
-- Author: Olorin
-- DateCreated: 8/5/2020 6:35:56 PM
--------------------------------------------------------------

print("RAILYARD SCRIPT LOADED!!!!")

local iRailyard = GameInfo.Districts["DISTRICT_RAILYARD"].Index;
local iRailstation = GameInfo.Buildings["BUILDING_RAILYARD_STATION"].Index;
local iSubway = GameInfo.Buildings["BUILDING_RAILYARD_SUBWAY"].Index;
local Railroad = GameInfo.Routes["ROUTE_RAILROAD"];
local iRailBuilder = GameInfo.Units["UNIT_RAILROAD_BUILDER"].Index;

local buildTracker = {}

-- EVENT RESPONSES
function OnDistrictFinished(playerID:number, districtID, cityID, X, Y, districtType, era, civilization, percentComplete, Appeal, isPillaged)
	--print("District Type: "..districtType)
	if isRailyard(districtType) then
		if (percentComplete == 100) then
			city = getCity(playerID, cityID)
			if not(city == nil) then
				ConnectCapitalByRailroad(city, X, Y)
			end
		end
	end
end

function OnBuildingConstructed(playerID:number, cityID, buildingID, plotID, bOriginalConstruction)
	local city = getCity(playerID, cityID)
	print("Plot ID = "..plotID..", Building ID = "..buildingID);

	if (buildingID == iRailstation) then
		CreateRailbuilder()
		--BuildRailroadsInCity(city);
	else
		if (buildingID == iSubway) then
			ConnectDistrictsByRailroads(city)
		end
	end
end

function OnBuildingAdded(iX:number, iY:number, buildingID:number, playerID:number, misc2, misc3)
	if (buildingID == iRailstation) then
		print("Railstation added");
		local plot = Map.GetPlot(iX, iY)
		RouteBuilder.SetRouteType(plot, Railroad.Index);
		CreateRailbuilder(playerID, iX, iY)
		--BuildRailroadsInCity(city);
	else
		if (buildingID == iSubway) then
			ConnectDistrictsByRailroads(city)
		end
	end
end

function OnTileOwnershipChanged(playerID:number, cityID, X, Y)
	--print("CITY CHANGED EVENT");
	--printArgTable(arg);
	UpdateRailroads(playerID, cityID)
end

function OnUnitMoved(playerID:number, unitID, tileX, tileY)
	local unit = getPlayer(playerID):GetUnits():FindID(unitID);
	local unitType = GameInfo.Units[unit:GetType()];

	if (unitType.UnitType == "UNIT_RAILROAD_BUILDER") then
		
		local dmg = unit:GetDamage();
		--print("Unit Damage = "..dmg)
		--print("Unit Loc = {"..tileX..", "..tileY.."}");
		
		local plot = Map.GetPlot(tileX, tileY);
		local routeType = plot:GetRouteType();
		
		if (not plot:IsWater() and not(routeType == Railroad.Index) and HasAdjacentRailroad(plot)) then
			RouteBuilder.SetRouteType(plot, Railroad.Index);
			local charges = buildTracker[playerID][unitID]
			buildTracker[playerID][unitID] = charges - 1;
			if (charges <= 0) then				
				print("Destroying Rail Builder");
				UnitManager.Kill(unit);
				buildTracker[playerID][unitID] = nil;
			else
				print("Rail Builder has "..buildTracker[playerID][unitID].." charges remaining");
			end
		end
	end
end

function OnUnitAdded(playerID:number, unitID)
	local unit = getPlayer(playerID):GetUnits():FindID(unitID);
	local unitType = GameInfo.Units[unit:GetType()];
	
	if (unitType.UnitType == "UNIT_RAILROAD_BUILDER") then
		print("Railbuilder added")
		--unit["BuildsRemaining"] = 10;
		--printArgTable(unit)

		if buildTracker[playerID] == nil then
			buildTracker[playerID] = {}
		end

		buildTracker[playerID][unitID] = 10;

		local tileX = unit:GetX()
		local tileY = unit:GetY()

		local city = CityManager.GetCityAt(tileX, tileY)
		local railyardX, railyardY = getRailyardTile(city)

		if (railyardX >= 0) then
			UnitManager.PlaceUnit(unit, railyardX, railyardY)
		end
	end
end

-- ACTIONS
function ConnectCapitalByRailroad(city, X, Y)
	
end

function ConnectDistrictsByRailroads(city)
	local city = getCity(playerID, cityID)
	local Districts = city:GetDistricts()
	for _,district in ipairs(Districts) do
		
	end
end

function UpdateRailroads(playerID, cityID)
	local city = getCity(playerID, cityID)
	if hasRailyard(city) then
		BuildRailroadsInCity(city);
	end
end

function BuildRailroadsInCity(city)
	Plots = city:GetOwnedPlots();
	--print("PLOTS:: Type = "..type(Plots));
	for _,plot in ipairs(Plots) do
		routeType = plot:GetRouteType();
		if not(routeType == -1) then
			RouteBuilder.SetRouteType(plot, Railroad.Index);
		end
	end
end

function CreateRailbuilder(playerID, locX, locY)
	local player = getPlayer(playerID)
	player:GetUnits():Create(iRailBuilder, locX, locY);
end

-- ACCESS
function getCity(playerID, cityID)
	return getPlayer(playerID):GetCities():FindID(cityID);
end

function getPlayer(playerID)
	return PlayerManager.GetPlayer(playerID)
end

function getRailyardTile(city)
	local locX = -1;
	local locY = -1;
	if hasRailyard(city) then
		local railyard = city:GetDistricts():GetDistrict(iRailyard)
		locX = railyard:GetX();
		locY = railyard:GetY();
	end
	return locX, locY;
end

-- BOOLEAN CHECKS
function isRailyard(districtType)
	return districtType == iRailyard;
end

function hasRailyard(city)
	return city:GetDistricts():HasDistrict(iRailyard);
end

function hasRailstation(city)
	return city:GetBuildings():HasBuilding(iRailstation);
end

function OnDistrictPillaged()

end

function HasAdjacentRailroad(plot)
	local startX = plot:GetX();
	local startY = plot:GetY();
	print("Start = {"..startX..", "..startY.."}")
	for i = 0, 5 do
		adjPlot = Map.GetAdjacentPlot(startX, startY, i)
		print ("Adj = {"..adjPlot:GetX()..", "..adjPlot:GetY().."}")
		local routeType = adjPlot:GetRouteType();
		if adjPlot and routeType == Railroad.Index then return true; end
	end
	return false;
end

-- UTILITY
function printArgTable(argTable)
	for k,v in ipairs(argTable) do
		print("Arg "..k..": "..v)
	end
end

Events.DistrictBuildProgressChanged.Add(OnDistrictFinished)
--Events.DistrictPillaged.Add(OnDistrictPillaged)

Events.UnitAddedToMap.Add(OnUnitAdded);
Events.UnitMoved.Add(OnUnitMoved);
--Events.CityTileOwnershipChanged.Add(OnTileOwnershipChanged);
--Events.BuildingConstructed.Add(OnBuildingConstructed);
Events.BuildingAddedToMap.Add(OnBuildingAdded);