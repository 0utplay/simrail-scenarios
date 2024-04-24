---@diagnostic disable: trailing-space
-- SimRail - The Railway Simulator
-- LUA Scripting scenario
-- Version: 1.0
--
require("SimRailCore")

VdReady = false -- state of virtual dispatcher
SpawnedTrains = {} -- Trains that were spawned in
StartPosition = {9209.63, 315.07, 16237.56} -- The position where the player is spawning

-- =============================
--    SimRail Event Listeners
-- =============================

--- Variable function to check if script is running in developer mode
DeveloperMode = function()
    return true
end

--- Function called by SimRail when the loading of scenario starts - generally designed for setting up necessery data and preloading-assets
function PrepareScenario()

end

--- Function called by SimRail when the loading finishes - you should set scenario time in here, spawn trains etc. After calling this mission recorder is started and stuff gets registered
function StartScenario()
    StartRecorder()
    SetDateTime(DateTimeCreate(2024, 06, 12, 12, 00, 00))
    SetTestScenario()
end

-- Functions below are called by SimRail if they exist if not, they are ignored
--- Function called when trainset is being split into 2 trainsets on disconnecting couplers
---@param oldTrainset TrainsetInfo
---@param newTrainset TrainsetInfo
function OnTrainsetsSplit(oldTrainset, newTrainset)
    DisplayChatText("Trainsets were split: " .. oldTrainset.name .. " now has some vehicles in new trainset: " ..newTrainset.name)
end

--- Function below is called by SimRail when joining trainsets
---@param builtTrainset TrainsetInfo This trainsets stays after execution of function below
---@param destroyedTrainset TrainsetInfo This trainset will no longer be accessible after executing code below
function OnTrainsetsJoined(builtTrainset, destroyedTrainset)
   DisplayChatText("Trainsets were joined: " .. builtTrainset.name .. " and " .. destroyedTrainset.name .. " is now just " .. builtTrainset.name)
end

--- Function below is called by SimRail when a square gets loaded
---@param x integer Position X
---@param z integer Position Z
---@param sceneGO GameObject Reference to scene's main object
function OnSquareLoaded(x, z, sceneGO) 
    DisplayChatText_Formatted("Square loaded: x={0}; z={1}", tostring(x), tostring(z))
end

--- Function below in called by SimRail when square gets unloaded
---@param x integer Position X
---@param z integer Position Z
function OnSquareUnloaded(x, z)
    DisplayChatText_Formatted("Square unloaded: x={0}; z={1}", tostring(x), tostring(z))
end

--- Function below is called by SimRail when presssing a radio call button (Polish ZEW 1/3)
---@param trainset TrainsetInfo Rerefernce to trainset
---@param radioCall integer Which radio call was used
---@param channel integer Which radio channel was used
function OnPlayerRadioCall(trainset, radioCall, channel)
    DisplayChatText_Formatted("Received radio call {0} on channel {1} from train {2}", tostring(radioCall), tostring(channel), trainset.name)
end

--- Function below is called by SimRail responds to VD request
---@param orderId integer Order ID
---@param status VDReponseCode response code
function OnVirtualDispatcherResponseReceived(orderId, status)
    DisplayChatText("Recived VD resonse (order=" .. orderId .. "; status=" .. status .. ")")
end

--- Function below is called by SimRail when VD is ready to start receiving orders
function OnVirtualDispatcherReady()
    VdReady = true
    DisplayChatText("Virtual dispatcher called in ready!")

    --VDSetRoute("Gr_M1", "Gr_P3", VDOrderType.TrainRoute);
    --VDSetRoute("Gr_P3", "Gr_Ykps", VDOrderType.TrainRoute);

    -- VDSetSwitchPosition("WZD_217b", true)
    -- VDSetSwitchPosition("WZD_218a", true)
    -- VDSetSwitchPosition("WZD_219", false)
    -- VDSetSwitchPosition("WZD_220", true)
    -- VDSetSwitchPosition("z1329", false)

    -- AllowPassingStopSignal("WZD_S1G", function(passing_train)
    --     return passing_train == RailstockGetPlayerTrainset()
    -- end)
    -- VDSetSubstituteSignal("WZD_S1G", true)
    -- VDSetManualSignalLightsState("WZD_S1G", SignalLightType.Red1, LuaSignalLightState.AlwaysOff)
    -- VDSetManualSignalLightsState("WZD_S1G", SignalLightType.White1, LuaSignalLightState.AlwaysOn)
    -- VDSetManualSignalLightsState("WZD_S1G", SignalLightType.W21_50, LuaSignalLightState.AlwaysOn)

    --VDSetSwitchPosition("z1329", false)

    -- VDSetRoute("WZD_Tm213", "WZD_Tm215", VDOrderType.ManeuverRoute)
    -- VDSetRoute("WZD_Tm215", "t18446", VDOrderType.ManeuverRoute)
    
    -- CreateCoroutine(function ()
    --     local Switch51Order = VDSetSwitchPosition("Gr_51", false);
    --     local Switch57Order = VDSetSwitchPosition("Gr_57", false);
    --     coroutine.yield(CoroutineYields.WaitForVDRouteResponded, Switch51Order)
    --     coroutine.yield(CoroutineYields.WaitForVDRouteResponded, Switch57Order)

    --     local SetRoute = VDSetRoute("Gr_M1", "Gr_P3", VDOrderType.TrainRoute);
    --     VDSetRoute("Gr_P3", "Gr_Y", VDOrderType.TrainRoute);
    --     coroutine.yield(CoroutineYields.WaitForVDRouteResponded, SetRoute)
    --     --VDSetRoute("Gr_P3", "Gr_Y", VDOrderType.TrainRoute);
    -- end)
end

--- Sets the initial shunting routes in Zachodnia
--- Visualization: https://brouter.de/brouter-web/#map=15/52.2195/20.9390/osm-mapnik-german_style&lonlats=20.961442,52.221385;20.948353,52.217323;20.944005,52.21599&profile=rail
function SetRoutesShuntingWzdInitial()
    VDSetRoute("WZD_S1G", "WZD_Tm213", VDOrderType.ManeuverRoute)
    VDSetRoute("WZD_Tm213", "WCz_H", VDOrderType.ManeuverRoute)
    VDSetRoute("WCz_H", "WCz_Tm15", VDOrderType.ManeuverRoute)
end

--- Sets shunting route from first step in Zachodnia to entry signal
--- Visualization: https://brouter.de/brouter-web/#map=18/52.21685/20.94556/osm-mapnik-german_style&lonlats=20.944005,52.21599;20.954028,52.21818&profile=rail
function SetRoutesShutningWzdBeforeEnter()
    VDSetRoute("WCz_Tm10", "WZD_S201", VDOrderType.ManeuverRoute)

    -- spawns a pendolino which enters the station on track 6 / peron 5
    SpawnAiTrainsetAtSignal(FindSignal("WZD_Y"), 1100, true, { CreateNewSpawnVehicleDescriptor(LocomotiveNames.ED250_018, false)}, function(_)
        VDSetRoute("WZD_Y", "WZD_G6", VDOrderType.TrainRoute)
    end)

    -- spawns a dummy train that just stands in zachodnia
    SpawnAiTrainsetAtSignal(FindSignal("WZD_R610"), 10, false, {
        CreateNewSpawnVehicleDescriptor(LocomotiveNames.ET22_256, false),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5349_475_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5349_475_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, "", 80, BrakeRegime.P),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, "", 80, BrakeRegime.P),
    })

    -- spawns an ET22 with regio train attached, which enters zachodnia on track 25 / peron 4
    SpawnAiTrainsetAtSignal(FindSignal("WCz_M"), 5, true, {
        CreateNewSpawnVehicleDescriptor(LocomotiveNames.ET22_256, false);
        CreateNewSpawnFullVehicleDescriptor(LocomotiveNames.EN76_022, false, "", 70, BrakeRegime.G);
    }, function(_) 
        VDSetRoute("WCz_M", "WCz_Kkps", VDOrderType.TrainRoute)
        VDSetRoute("WZD_N", "WZD_L104", VDOrderType.TrainRoute)
        VDSetRoute("WZD_L104", "WZD_H36", VDOrderType.TrainRoute)
    end)

    -- spawns a regional train that departs towards the regional tracks
    -- VDSetRoute("WZD_G2", "WZD_Bkps", VDOrderType.TrainRoute) gives exit to regional tracks for spawned train below
    -- VDSetRoute("WSD_C", "WSD_K22", VDOrderType.TrainRoute) gives entry to peron 6 / track 22 in Wschodnia
    -- VDSetRoute("WSD_K22", "WSD_N26", VDOrderType.TrainRoute) & VDSetRoute("WSD_N26", "WSD_Skps", VDOrderType.TrainRoute) gives route to despawn signal
    SpawnAiTrainsetAtSignal(FindSignal("WZD_G2"),  5, true, {
            CreateNewSpawnVehicleDescriptor(LocomotiveNames.EN57_1000, false),
            CreateNewSpawnVehicleDescriptor(LocomotiveNames.EN57_1000, false),
            CreateNewSpawnVehicleDescriptor(LocomotiveNames.EN57_1000, false),
    }, function (trainset)
        local StopTrigger
        StopTrigger = CreateTrackTrigger(FindTrack("t24585"), 7, -1, {
            check = function(triggering_trainset) return triggering_trainset == trainset end,
            result = function(trainset) 
                trainset.SetState(DynamicState.dsStop, TrainsetState.tsTrain, false)
                RemoveTrackTrigger(StopTrigger)
            end
        })   

    end);
end

-- Sets the train routes through Wzd towards Wzc via regional tracks
--- Visualization:
function SetRoutesTrainWzdToWdc()
    VDSetRoute("WZD_S201", "WZD_G1", VDOrderType.TrainRoute)
    VDSetRoute("WZD_G1", "WZD_Ekps", VDOrderType.TrainRoute)
    RailstockGetPlayerTrainset().SetState(DynamicState.dsAccCoast, TrainsetState.tsTrain, false);
end

-- =============================
--    Utility Functions
-- =============================

--- Displays an ingame chat message, if developer mode is enabled
---@param key string Key to obtain
---@param ... string Paramters as strings that replace {0}, {1} etc.
function DebugChatLogMessage(key, ...)
    if DeveloperMode() then
        DisplayChatText_Formatted("[Script-Debug] " .. key, ...)
    end
end

--- Removes all explicitly spawned trainsets, only works in development mode
function DebugRemoveSpawnedTrains()
    if DeveloperMode() then
        for index = #SpawnedTrains, 1, -1 do
            local trainset = table.remove(SpawnedTrains, index)
            DespawnTrainset(trainset)
        end
        DebugChatLogMessage("Removed all explicitly spawned trainsets (except main player trainsets)")
    end
end

--- Spawns and registers an AI train asynchroniously.
---@param signal SignalNetworkHolder Signal at which the train should be spawned.
---@param distanceToSignal number Distance to the signal where the train should be placed on the tracks.
---@param activateTrainset boolean If the trainset should be marked active after calling the spawn callback.
---@param trainset table<SpawnVehicleDescription> The train parts that should be placed on the tracks.
---@param spawnCallback function|nil Function to execute when the trainset was placed. Takes the reference to the spawned trainset as argument.
function SpawnAiTrainsetAtSignal(signal, distanceToSignal, activateTrainset, trainset, spawnCallback)
    local TrainSetId = GenerateUID()
    SpawnTrainsetOnSignalAsync(TrainSetId, signal, distanceToSignal, false, false, true, trainset, function (trainset) 
        -- register the spawned train
        table.insert(SpawnedTrains, trainset)

        -- call the spawn callback if given
        if spawnCallback ~= nil then
            spawnCallback(trainset)
        end

        -- mark the trainset as active, else mark the set as inactive
        if activateTrainset then
            trainset.SetState(DynamicState.dsStop, TrainsetState.tsTrain, true)
        else
            trainset.SetState(DynamicState.dsCold, TrainsetState.tsDeactivation, false)
        end
    end)
end

-- =============================
--    Mission Related Stuff
-- =============================

function SetTestScenario()
    -- SetWeather(WeatherConditionCode.ClearSky, 26, 1000, 100, 2000, 0, 10, 0, true)
    -- WZD_S1G
    local PlayerTrainset = SpawnTrainsetOnSignal("test", FindSignal("WCz_Tm10"), 10, true, true, false, true, {
        CreateNewSpawnVehicleDescriptor(LocomotiveNames.E6ACTadb_027, false);
        --CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5349_475_9, false, FreightLoads_412W.Coal, 10000, BrakeRegime.S),
        --CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, FreightLoads_412W.Coal, 10000, BrakeRegime.S),
        --CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3351_5356_394_5, false, FreightLoads_412W.Coal, 10000, BrakeRegime.S),
        --CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3356_5300_118_0, false, FreightLoads_412W.Coal, 10000, BrakeRegime.S),
        --CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3356_5300_177_6, false, FreightLoads_412W.Coal, 10000, BrakeRegime.S),
    })
    PlayerTrainset.SetState(DynamicState.dsStop, TrainsetState.tsShunting, true)
    PlayerTrainset.SetRadioChannel(PlayerTrainset.GetIntendedRadioChannel(), true)
end
