-- SimRail - The Railway Simulator
-- LUA Scripting scenario
-- Version: 1.0
--
require("SimRailCore")

require("Setup")
require("MissionTrainsets")
require("TrainGenerationUtil")

-- =============================
--    SimRail Information
-- =============================
--- Variable function to check if script is running in developer mode
DeveloperMode = function()
    return true
end

--- The position where the player is spawning initially.
---@type table<number>
StartPosition = { 121905.20, 134.20, 221491.90 }

-- =============================
--    Type Definitions
-- =============================
--- Enum describing the current state of this scenario.
---@enum ScenarioState
ScenarioState = {
    EarlyInit = -1,
    WaitingForVdInitialization = 0,
    WaitingForInitialPlayerTrainPrep = 1,
}

-- =============================
--    Global Variables
-- =============================
--- Initilization state of virtual dispatcher
---@type ScenarioState
CurrentScenarioState = ScenarioState.EarlyInit

--- The trainsets that were spawned into the current game as AI trains.
---@type table<TrainsetInfo>
SpawnedTrains = {}

--- The reference to the current player controller.
---@type GameObject
PlayerController = nil

--- The reference to the player trainset.
---@type TrainsetInfo
PlayerTrainset = nil

--- The trainset that was selected by the player to be used.
---@type MissionTrainset
MissionTrainset = nil

--- The camera that should be forced on the player, nil to not force any camera
---@type CameraView|nil
ForcedCameraView = nil

-- =============================
--    SimRail Event Listeners
-- =============================
--- Function called by SimRail when the loading of scenario starts - generally designed for setting up necessery data and preloading-assets
function PrepareScenario()
end

-- Function called by SimRail between loading finish and scenario start.
function EarlyScenarioStart()
    -- Set initial datetime and weather
    SetDateTime(DateTimeCreate(2024, 06, 12, 03, 30, 00))
    SetWeather(WeatherConditionCode.ScatteredClouds, 3, 1000, 42, 200, 0, 13, 0, true)

    DisplayChatText("a")
    DisplayChatText(DragonTrainset.locomotive)
    DisplayChatText("b")
    PlayerController = GetPlayerController()

    -- Display the setup for the locomotive to use
    local locomotiveSetupStep = SetupStep.new("locomotive", {DragonTrainset, Et22Trainset})
    ExecuteSetup({locomotiveSetupStep}, function(results)
        MissionTrainset = results["locomotive"]
        SpawnPlayerTrainSet()
    end)
end

--- Function called by SimRail when the loading finishes. After calling this mission recorder is started and stuff gets registered
function StartScenario()
    -- Early init done, wait for dispatcher init finish
    StartRecorder()

    -- Initial camera setup for welcome animation flight during init
    CameraTurn(23.5, -5)
    SetCameraView(CameraView.InAnimation)
    DisplayMessage("StateVdLoading", -1)

    -- Set current scenario state to init of the dispatcher (launches the init cutscene)
    CurrentScenarioState = ScenarioState.WaitingForVdInitialization
end

--- Function called by SimRail each frame.
function PerformUpdate()
    -- Ensure that the player is in the forced camera
    if ForcedCameraView ~= nil and GetCameraView() ~= ForcedCameraView then
        SetCameraView(ForcedCameraView)
    end

    -- Check for initial dispatcher loading state, if currently active move the camera of the player forward (start cutscene)
    if CurrentScenarioState == ScenarioState.WaitingForVdInitialization then
        PlayerController.transform.position = (PlayerController.transform.position + Vector3Create(0.03, 0, 0.01))
        return
    end
end

-- Functions below are called by SimRail if they exist if not, they are ignored
--- Function called when trainset is being split into 2 trainsets on disconnecting couplers
---@param oldTrainset TrainsetInfo
---@param newTrainset TrainsetInfo
function OnTrainsetsSplit(oldTrainset, newTrainset)
    Log("Trainsets were split: " .. oldTrainset.name .. " now has some vehicles in new trainset: " .. newTrainset.name)
end

--- Function below is called by SimRail when joining trainsets
---@param builtTrainset TrainsetInfo This trainsets stays after execution of function below
---@param destroyedTrainset TrainsetInfo This trainset will no longer be accessible after executing code below
function OnTrainsetsJoined(builtTrainset, destroyedTrainset)
    Log("Trainsets were joined: " .. builtTrainset.name .. " and " .. destroyedTrainset.name .. " is now just " .. builtTrainset.name)
end

--- Function below is called by SimRail when a square gets loaded
---@param x integer Position X
---@param z integer Position Z
---@param sceneGO GameObject Reference to scene's main object
function OnSquareLoaded(x, z, sceneGO)
end

--- Function below in called by SimRail when square gets unloaded
---@param x integer Position X
---@param z integer Position Z
function OnSquareUnloaded(x, z)
end

--- Function below is called by SimRail when presssing a radio call button (Polish ZEW 1/3)
---@param trainset TrainsetInfo Rerefernce to trainset
---@param radioCall integer Which radio call was used
---@param channel integer Which radio channel was used
function OnPlayerRadioCall(trainset, radioCall, channel)
    Log("Received radio call " .. tostring(radioCall) .. " on channel " .. tostring(channel) .. " from train " .. trainset.name)
end

--- Function below is called by SimRail responds to VD request
---@param orderId integer Order ID
---@param status VDReponseCode response code
function OnVirtualDispatcherResponseReceived(orderId, status)
    Log("Recived VD resonse (order=" .. orderId .. "; status=" .. status .. ")")
end

--- Function below is called by SimRail when a signal gets passed in a dangerous situation (for example when displaying STOP).
function OnSingalPassedAtDanger()
    Log("Signal passed at danger!")
end

--- Function below is called by SimRail when the player activates or deactivates the bot driver.
---@param active boolean If the bot is currently activate.
function OnBotStateChange(active)
    Log("Bot activation state change to " .. tostring(active))
end

--- Function below is called by SimRail when VD is ready to start receiving orders
function OnVirtualDispatcherReady()
    if CurrentScenarioState == ScenarioState.WaitingForVdInitialization then
        -- remove the displayed "loading scenario" mesage & move into next scenario state
        DisplayMessage("", -1)
        CurrentScenarioState = ScenarioState.WaitingForInitialPlayerTrainPrep

        -- teleport the player to the trainset that was spawned
        local TeleportTarget = Vector3Create(121943.40, 113.5, 221714.40)
        local CameraParentLocalPosition = PlayerController.transform.parent.localPosition
        local StartPosVec3 = Vector3Create(StartPosition[1], StartPosition[2], StartPosition[3])
        local RelativeTeleportTarget = CameraParentLocalPosition + (TeleportTarget - StartPosVec3)
        PlayerController.transform.parent.localPosition = RelativeTeleportTarget

        -- let the player look towards the trainset door & change camera to let him walk around freely
        local SuspectedEntryDoor = PlayerTrainset.transform.GetChild(0).Find(MissionTrainset.doorTransform)
        CameraTurnTowards(SuspectedEntryDoor.position, false)
        SetCameraView(CameraView.FirstPersonWalkingOutside)
    end
end

-- =============================
--    Utility Functions
-- =============================
--- Removes all explicitly spawned trainsets, only works in development mode
function DebugRemoveSpawnedTrains()
    if DeveloperMode() then
        for index = #SpawnedTrains, 1, -1 do
            local trainset = table.remove(SpawnedTrains, index)
            DespawnTrainset(trainset)
        end
        Log("Removed all explicitly spawned trainsets (except main player trainsets)")
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
    SpawnTrainsetOnSignalAsync(TrainSetId, signal, distanceToSignal, false, false, true, trainset, function(trainset)
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
--- Spawns the player trainset after the player decided which one to use.
function SpawnPlayerTrainSet()
    -- Spawns player trainset
    local InitialStartSignal = FindSignal("WZD_S1G")
    local InitialTrainset = { CreateNewSpawnVehicleDescriptor(MissionTrainset.locomotive, false) }
    PlayerTrainset = SpawnTrainsetOnSignal("PlayerTrainset", InitialStartSignal, 12, true, true, false, false, InitialTrainset)
    if DeveloperMode() then
        -- Shortcut for development reasons, just mark the trainset as ready
        PlayerTrainset.SetState(DynamicState.dsStop, TrainsetState.tsShunting, true)
        PlayerTrainset.SetRadioChannel(PlayerTrainset.GetIntendedRadioChannel(), true)
    else
        -- Mark the trainset as cold start, require the player to set it up
        PlayerTrainset.SetState(DynamicState.dsCold, TrainsetState.tsDeactivation, true)
    end
end

--- Sets the initial shunting routes in Zachodnia
function SetRoutesShuntingWzdInitial()
    VDSetRoute("WZD_S1G", "WZD_Tm213", VDOrderType.ManeuverRoute)
    VDSetRoute("WZD_Tm213", "WCz_H", VDOrderType.ManeuverRoute)
    VDSetRoute("WCz_H", "WCz_Tm15", VDOrderType.ManeuverRoute)
end

--- Sets shunting route from first step in Zachodnia to entry signal
function SetRoutesShutningWzdBeforeEnter()
    VDSetRoute("WCz_Tm10", "WZD_S201", VDOrderType.ManeuverRoute)

    -- spawns a pendolino which enters the station on track 6 / peron 5
    SpawnAiTrainsetAtSignal(FindSignal("WZD_Y"), 1100, true,
        { CreateNewSpawnVehicleDescriptor(LocomotiveNames.ED250_018, false) }, function(_)
            VDSetRoute("WZD_Y", "WZD_G6", VDOrderType.TrainRoute)
        end)

    -- spawns a dummy train that just stands in zachodnia
    SpawnAiTrainsetAtSignal(FindSignal("WZD_R610"), 10, false, {
        CreateNewSpawnVehicleDescriptor(LocomotiveNames.ET22_256, false),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, FreightLoads_412W_v4.Coal, 80, BrakeRegime.G),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, FreightLoads_412W_v4.Coal, 80, BrakeRegime.G),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5349_475_9, false, FreightLoads_412W_v4.Coal, 80, BrakeRegime.G),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5349_475_9, false, FreightLoads_412W_v4.Coal, 80, BrakeRegime.G),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.EAOS_3151_5351_989_9, false, FreightLoads_412W_v4.Coal, 80, BrakeRegime.G),

        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.Zaes_3351_0079_375_1, false, FreightLoads_406Ra.Petrol, 80, BrakeRegime.G),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.Zaes_3351_0079_375_1, false, FreightLoads_406Ra.Petrol, 80, BrakeRegime.G),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.Zaes_3351_0079_375_1, false, FreightLoads_406Ra.Petrol, 80, BrakeRegime.G),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.Zaes_3351_0079_375_1, false, FreightLoads_406Ra.Petrol, 80, BrakeRegime.G),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.Zaes_3351_0079_375_1, false, FreightLoads_406Ra.Petrol, 80, BrakeRegime.G),

        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.SGS_3151_3944_773_6, false, FreightLoads_412W.RandomContainerAll, 80, BrakeRegime.G),
        CreateNewSpawnFullVehicleDescriptor(FreightWagonNames.SGS_3151_3944_773_6, false, FreightLoads_412W.RandomContainerAll, 80, BrakeRegime.G),
    })

    -- spawns an ET22 with regio train attached, which enters zachodnia on track 25 / peron 4
    SpawnAiTrainsetAtSignal(FindSignal("WCz_M"), 5, true, {
        CreateNewSpawnVehicleDescriptor(LocomotiveNames.ET22_256, false),
        CreateNewSpawnFullVehicleDescriptor(LocomotiveNames.EN76_022, false, "", 70, BrakeRegime.G),
    }, function(_)
        VDSetRoute("WCz_M", "WCz_Kkps", VDOrderType.TrainRoute)
        VDSetRoute("WZD_N", "WZD_L104", VDOrderType.TrainRoute)
        VDSetRoute("WZD_L104", "WZD_H36", VDOrderType.TrainRoute)
    end)

    -- spawns a regional train that departs towards the regional tracks
    -- VDSetRoute("WZD_G2", "WZD_Bkps", VDOrderType.TrainRoute) gives exit to regional tracks for spawned train below
    -- VDSetRoute("WSD_C", "WSD_K22", VDOrderType.TrainRoute) gives entry to peron 6 / track 22 in Wschodnia
    -- VDSetRoute("WSD_K22", "WSD_N26", VDOrderType.TrainRoute) & VDSetRoute("WSD_N26", "WSD_Skps", VDOrderType.TrainRoute) gives route to despawn signal
    SpawnAiTrainsetAtSignal(FindSignal("WZD_G2"), 5, true, {
        CreateNewSpawnVehicleDescriptor(LocomotiveNames.EN57_1000, false),
        CreateNewSpawnVehicleDescriptor(LocomotiveNames.EN57_1000, false),
        CreateNewSpawnVehicleDescriptor(LocomotiveNames.EN57_1000, false),
    }, function(trainset)
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
function SetRoutesTrainWzdToWdc()
    VDSetRoute("WZD_S201", "WZD_G1", VDOrderType.TrainRoute)
    VDSetRoute("WZD_G1", "WZD_Ekps", VDOrderType.TrainRoute)
    RailstockGetPlayerTrainset().SetState(DynamicState.dsAccCoast, TrainsetState.tsTrain, false);
end
