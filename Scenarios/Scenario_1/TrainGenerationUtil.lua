--- Utility functions to work with AI trains on the tracks
require("SimRailCore")
require("MoreSimrailEnums")

--- The trainsets that were spawned in as AI trains.
---@type table<TrainsetInfo>
local SpawnedAiTrains = {}

-- =============================
--    Private Utilities
-- =============================
--- Collects all enum (table) values in the given input enum table
---@param enum table<string, string> The input enum to extract the values of.
---@return table<string>
local function CollectEnumValues(enum)
    local values = {}
    for _, value in pairs(enum) do
        table.insert(values, value)
    end
    return values
end

-- =============================
--    Type Definitions
-- =============================
---@class WagonTypeMapping
---@field wagonName string The name of the wagon.
---@field length integer The length of the wagon (in meters).
---@field weight number The weight of the wagon when empty (in tons).
---@field maxSpeed integer The maximum speed of the wagon (in kilometers per hour).
---@field maxCargoWeight number The maximum weight that can be carried (in tons).
---@field freightTypes table<string>|nil The possible freights that can be carried, nil if not a freight wagon.
---@field requiredDlcId string|nil The id of the required DLC to use the wagon.
local WagonTypeMapping = {}
WagonTypeMapping.__index = WagonTypeMapping

--- Constructs a new wagon type mapping
---@param wagonName string The name of the wagon.
---@param length integer The length of the wagon (in meters).
---@param weight number The weight of the wagon when empty (in tons).
---@param maxSpeed integer The maximum speed of the wagon (in kilometers per hour).
---@param maxCargoWeight number The maximum weight that can be carried (in tons).
---@param freightTypes table<string>|nil The possible freights that can be carried.
---@param requiredDlcId string|nil The id of the required DLC to use the wagon.
---@return WagonTypeMapping
function WagonTypeMapping.new(wagonName, length, weight, maxSpeed, maxCargoWeight, freightTypes, requiredDlcId)
    local self = setmetatable({}, WagonTypeMapping)
    self.wagonName = wagonName
    self.length = length
    self.weight = weight
    self.maxSpeed = maxSpeed
    self.maxCargoWeight = maxCargoWeight
    self.freightTypes = freightTypes
    self.requiredDlcId = requiredDlcId
    return self
end

--- Get if the current wagon mapping is representing a freight wagon.
---@return boolean
function WagonTypeMapping:isFreight()
    return self.freightTypes ~= nil
end

--- Get if the current wagon mapping requires a DLC to be installed.
---@return boolean
function WagonTypeMapping:requiresDlc()
    return self.requiredDlcId ~= nil
end

---@class LocomotiveTypeMapping
---@field locomotiveName string The name of the locomotive.
---@field length integer The length of the locomotive (in meters).
---@field weight number The weight of the locomotive when empty (in tons).
---@field maxSpeed integer The maximum speed of the locomotive (in kilometers per hour).
---@field freight boolean If the locomotive can be used on freight trains.
---@field passenger boolean If the locomotive can be used on passenger trains.
---@field requiredDlcId string|nil The id of the required DLC to use the locomotive.
local LocomotiveTypeMapping = {}
LocomotiveTypeMapping.__index = LocomotiveTypeMapping

--- Constructs a new locomotove type mapping
---@param locomotiveName string The name of the locomotive.
---@param length integer The length of the locomotive (in meters).
---@param weight number The weight of the locomotive when empty (in tons).
---@param maxSpeed integer The maximum speed of the locomotive (in kilometers per hour).
---@param freight boolean If the locomotive can be used on freight trains.
---@param passenger boolean If the locomotive can be used on passenger trains.
---@param requiredDlcId string|nil The id of the required DLC to use the locomotive.
---@return LocomotiveTypeMapping
function LocomotiveTypeMapping.new(locomotiveName, length, weight, maxSpeed, freight, passenger, requiredDlcId)
    local self = setmetatable({}, LocomotiveTypeMapping)
    self.locomotiveName = locomotiveName
    self.length = length
    self.weight = weight
    self.maxSpeed = maxSpeed
    self.freight = freight
    self.passenger = passenger
    self.requiredDlcId = requiredDlcId
    return self
end

---@class EmuTypeMapping
---@field unitName string The name of the unit.
---@field length integer The length of the unit (in meters).
---@field weight number The weight of the unit when empty (in tons).
---@field maxSpeed integer The maximum speed of the unit (in kilometers per hour).
---@field requiredDlcId string|nil The id of the required DLC to use the unit.
local EmuTypeMapping = {}
EmuTypeMapping.__index = EmuTypeMapping

--- Constructs a new electrical multiple unit type mapping
---@param unitName string The name of the unit.
---@param length integer The length of the unit (in meters).
---@param weight number The weight of the unit when empty (in tons).
---@param maxSpeed integer The maximum speed of the unit (in kilometers per hour).
---@param requiredDlcId string|nil The id of the required DLC to use the unit.
---@return EmuTypeMapping
function EmuTypeMapping.new(unitName, length, weight, maxSpeed, requiredDlcId)
    local self = setmetatable({}, EmuTypeMapping)
    self.unitName = unitName
    self.length = length
    self.weight = weight
    self.maxSpeed = maxSpeed
    self.requiredDlcId = requiredDlcId
    return self
end

-- =============================
--          Mappings
-- =============================
--- Actual freights that can be carried by a 441V wagon.
---@enum Actual441VFreights
local Actual441VFreights = {
    FreightLoads_412W_v4.Coal,
    FreightLoads_412W_v4.Sand,
    FreightLoads_412W_v4.Ballast,
}

--- List of all possible freight wagons.
---@type table<WagonTypeMapping>
local FreigthWagons = {
    -- Tank wagons introduced with ET22 DLC.
    WagonTypeMapping.new(FreightWagonNames.Zaes_3351_0079_375_1, 12, 23, 100, 57, CollectEnumValues(FreightLoads_406Ra), SimRailDlc.ET22), -- grey
    WagonTypeMapping.new(FreightWagonNames.Zaes_3351_7881_520_5, 12, 23, 100, 57, CollectEnumValues(FreightLoads_406Ra), SimRailDlc.ET22), -- blue
    WagonTypeMapping.new(FreightWagonNames.Zaes_3351_7980_031_3, 12, 23, 100, 57, CollectEnumValues(FreightLoads_406Ra), SimRailDlc.ET22), -- white
    WagonTypeMapping.new(FreightWagonNames.Zaes_3351_7982_861_1, 12, 23, 100, 57, CollectEnumValues(FreightLoads_406Ra), SimRailDlc.ET22), -- brighter white
    WagonTypeMapping.new(FreightWagonNames.Zaes_3451_7981_215_0, 12, 23, 100, 57, CollectEnumValues(FreightLoads_406Ra), SimRailDlc.ET22), -- red
    WagonTypeMapping.new(FreightWagonNames.Zas_8451_7862_699_8, 12, 23, 100, 57, CollectEnumValues(FreightLoads_406Ra), SimRailDlc.ET22), -- red

    -- High granulation bulk cargo (such as coal or gravel) wagons introduced with ET22 DLC.
    WagonTypeMapping.new(FreightWagonNames._441V_31516635283_3, 14, 26, 120, 64, Actual441VFreights, SimRailDlc.ET22), -- blue
    WagonTypeMapping.new(FreightWagonNames._441V_31516635512_5, 14, 26, 120, 64, Actual441VFreights, SimRailDlc.ET22), -- red

    -- Bulk cargo (such as coal or gravel) and one piece cargo (such as wood logs) wagons.
    WagonTypeMapping.new(FreightWagonNames.EAOS_3151_5349_475_9, 14, 20, 100, 60, CollectEnumValues(FreightLoads_412W_v4)), -- red
    WagonTypeMapping.new(FreightWagonNames.EAOS_3151_5351_989_9, 14, 20, 100, 60, CollectEnumValues(FreightLoads_412W_v4)), -- blue
    WagonTypeMapping.new(FreightWagonNames.EAOS_3351_5356_394_5, 14, 20, 100, 60, CollectEnumValues(FreightLoads_412W_v4)), -- light blue
    WagonTypeMapping.new(FreightWagonNames.EAOS_3356_5300_118_0, 14, 20, 100, 60, CollectEnumValues(FreightLoads_412W_v4)), -- blue white green
    WagonTypeMapping.new(FreightWagonNames.EAOS_3356_5300_177_6, 14, 20, 100, 60, CollectEnumValues(FreightLoads_412W_v4)), -- blue white green (rounded)

    -- Dry bulk (such as cement or ashes) wagon.
    WagonTypeMapping.new(FreightWagonNames.UACS_3351_9307_587_6, 14, 24.5, 120, 55.7, {}), -- grey

    -- Platform wagons for containers.
    WagonTypeMapping.new(FreightWagonNames.SGS_3151_3944_773_6, 20, 22, 120, 58, CollectEnumValues(FreightLoads_412W)), -- blue
    WagonTypeMapping.new(FreightWagonNames.SGS_3151_3944_773_6, 20, 22, 120, 58, CollectEnumValues(FreightLoads_412W)), -- red
}

--- List of all possible person wagons.
---@type table<WagonTypeMapping>
local PassengerWagons = {
    -- Br 111A
    WagonTypeMapping.new(PassengerWagonNames.B10ou_5051_2000_608_3, 25, 38, 160, 38), -- light green white
    WagonTypeMapping.new(PassengerWagonNames.B10nou_5051_2008_607_7, 25, 38, 120, 38), -- green white
    WagonTypeMapping.new(PassengerWagonNames.B10ou_5151_2070_829_9, 25, 38, 160, 38), -- blue white
    WagonTypeMapping.new(PassengerWagonNames.B10nouz_5151_2071_102_0, 25, 38, 160, 38), -- blue white (different roof)

    -- Br 112A
    WagonTypeMapping.new(PassengerWagonNames.Adnu_5051_1900_189_7, 25, 38, 120, 38), -- red white
    WagonTypeMapping.new(PassengerWagonNames.Adnu_5051_1908_095_8_, 25, 38, 160, 38), -- red white, but zooooooom
    WagonTypeMapping.new(PassengerWagonNames.A9ou_5051_1908_136_0, 25, 38, 120, 38), -- blue white
    WagonTypeMapping.new(PassengerWagonNames.A9ou_5151_1970_003_4, 25, 38, 160, 38), -- blue white, but zooooooom

    -- Br 156A
    WagonTypeMapping.new(PassengerWagonNames.B10bmnouz_6151_2071_105_1, 26, 50, 160, 50), -- blue white (modern)

    -- Br B91
    WagonTypeMapping.new(PassengerWagonNames.B11gmnouz_6151_2170_107_7, 26, 38, 160, 38), -- blue white
    WagonTypeMapping.new(PassengerWagonNames.A9mnouz_6151_1970_214_5, 26, 38, 160, 38), -- blue white
    WagonTypeMapping.new(PassengerWagonNames.A9mnouz_6151_1970_234_3, 26, 38, 160, 38), -- blue white

    -- Br G90
    WagonTypeMapping.new(PassengerWagonNames.B11bmnouz_6151_2170_064_0, 26, 38, 160, 38), -- blue white
    WagonTypeMapping.new(PassengerWagonNames.B11bmnouz_6151_2170_098_8, 26, 38, 160, 38), -- blue white

    -- Br 406A
    WagonTypeMapping.new(PassengerWagonNames.WRmnouz_6151_8870_191_1, 26, 48, 160, 48), -- blue white red
}

--- List of all possible freight locomotives.
---@type table<LocomotiveTypeMapping>
local FreightLocomotives = {
    -- Br 4E
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_005, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_068, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_085, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_092, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_096, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_241, 16, 80, 125, true, true),

    -- Br E186
    LocomotiveTypeMapping.new(LocomotiveNames.E186_134, 19, 85, 140, true, false),
    LocomotiveTypeMapping.new(LocomotiveNames.E186_929, 19, 85, 140, true, false),

    -- Br E6ACTa
    LocomotiveTypeMapping.new(LocomotiveNames.ET25_002, 20, 119, 120, true, false),
    LocomotiveTypeMapping.new(LocomotiveNames.E6ACTa_014, 20, 119, 120, true, false),
    LocomotiveTypeMapping.new(LocomotiveNames.E6ACTa_016, 20, 119, 120, true, false),
    LocomotiveTypeMapping.new(LocomotiveNames.E6ACTadb_027, 20, 119, 120, true, false),

    -- Br Ty2 (not yet implemented)
    -- LocomotiveTypeMapping.new(LocomotiveNames.Ty2_540, 23, 143.6, 80, true, false),

    -- Br 201E
    LocomotiveTypeMapping.new(LocomotiveNames.ET22_243, 19, 120, 125, true, false, SimRailDlc.ET22),
    LocomotiveTypeMapping.new(LocomotiveNames.ET22_256, 19, 120, 125, true, false, SimRailDlc.ET22),
    LocomotiveTypeMapping.new(LocomotiveNames.ET22_644, 19, 120, 125, true, false, SimRailDlc.ET22),
    LocomotiveTypeMapping.new(LocomotiveNames.ET22_836, 19, 120, 125, true, false, SimRailDlc.ET22),
    LocomotiveTypeMapping.new(LocomotiveNames.ET22_911, 19, 120, 125, true, false, SimRailDlc.ET22),
    LocomotiveTypeMapping.new(LocomotiveNames.ET22_1163, 19, 120, 125, true, false, SimRailDlc.ET22),
}

--- List of all possible passenger locomotives.
---@type table<LocomotiveTypeMapping>
local PassengerLocomotives = {
    -- Br 4E
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_005, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_068, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_085, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_092, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_096, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EU07_241, 16, 80, 125, true, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EP07_135, 16, 80, 125, false, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EP07_174, 16, 80, 125, false, true),

    -- Br 102E
    LocomotiveTypeMapping.new(LocomotiveNames.EP08_001, 16, 80, 140, false, true),
    LocomotiveTypeMapping.new(LocomotiveNames.EP08_013, 16, 80, 140, false, true),
}

--- List of all possible electrical multiple units (except pendolino).
---@type table<EmuTypeMapping>
local ElectricalMultipleUnits = {
    -- Br 34WE
    EmuTypeMapping.new(LocomotiveNames.EN96_001, 43, 83.2, 160),

    -- Br 22WE
    EmuTypeMapping.new(LocomotiveNames.EN76_006, 75, 135, 160),
    EmuTypeMapping.new(LocomotiveNames.EN76_022, 75, 135, 160),

    -- Br EN57
    EmuTypeMapping.new(LocomotiveNames.EN57_009, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_047, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_614, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1000, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1003, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1051, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1219, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1316, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1458, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1567, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1571, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1752, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1755, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1796, 65, 126.5, 110),
    EmuTypeMapping.new(LocomotiveNames.EN57_1821, 65, 126.5, 110),

    -- Br EN71
    EmuTypeMapping.new(LocomotiveNames.EN71_005, 87, 182, 110),
    EmuTypeMapping.new(LocomotiveNames.EN71_011, 87, 182, 110),
}

--- List of all pendolino units.
---@type table<EmuTypeMapping>
local PendolinoUnits = {
    -- Br ED250
    EmuTypeMapping.new(LocomotiveNames.ED250_018, 187, 410, 250),
}

-- =============================
--    Internal Functions
-- =============================
--- Picks a random element from the given table.
---@param table table<any> The input table to pick a random element from.
---@return any
local function PickRandomElement(table)
    local randomIndex = math.random(#table)
    return table[randomIndex]
end

--- Contructs a freight trainset to spawn based on the given input parameters
---@param maxLength integer The maximum length of the train to construct, in meters.
---@param maxWagonCount integer The maximum count of wagons to append to the train, must be positive (can be 0).
---@param prependLocomotive boolean If a locomotive should be prepended to the trainset.
---@param reversed boolean If the wagons and locomotive should be spawned reversed.
---@return table<SpawnVehicleDescription>
local function ConstructFreightTrain(maxLength, maxWagonCount, prependLocomotive, reversed)
    -- The resulting constructed trainset
    local result = {}

    -- Pick a locomotive for the trainset first
    local currentLength = 0
    if prependLocomotive then
        local locomotive = PickRandomElement(FreightLocomotives)
        currentLength = locomotive.length
        table.insert(result, CreateNewSpawnFullVehicleDescriptor(locomotive.locomotiveName, reversed, "", 0, BrakeRegime.G))
    end

    -- Register X freight wagons to the spawned trainset
    local wagonCount = 0
    for _ = 1, maxWagonCount do
        -- Pick a random wagon, break train construction if adding it would exceed the given maximum size
        local randomWagon = PickRandomElement(FreigthWagons)
        currentLength = currentLength + randomWagon.length
        if currentLength > maxLength then
            break
        end

        -- Wagons >5 seem to be in brake regime P instead of G, apply that
        wagonCount = wagonCount + 1
        local brakeRegime = BrakeRegime.G
        if wagonCount > 5 then
            brakeRegime = BrakeRegime.P
        end

        -- Pick a random freight & mass (in kilograms) for the wagon
        local possibleFreight = randomWagon.freightTypes
        local randomFreightMass = math.random(10, randomWagon.maxCargoWeight) * 1000
        if #possibleFreight > 0 then
            -- Wagon has freight that can be carried, pick a random one
            local randomeFreight = PickRandomElement(possibleFreight)
            table.insert(result, CreateNewSpawnFullVehicleDescriptor(randomWagon.wagonName, reversed, randomeFreight, randomFreightMass, brakeRegime))
        else
            -- Wagon has no freight that can be carried
            table.insert(result, CreateNewSpawnFullVehicleDescriptor(randomWagon.wagonName, reversed, "", randomFreightMass, brakeRegime))
        end
    end

    return result
end

--- Contructs a passenger trainset with locomotive to spawn based on the given input parameters
---@param maxLength integer The maximum length of the train to construct, in meters.
---@param maxWagonCount integer The maximum count of wagons to append to the train, must be positive (can be 0).
---@param prependLocomotive boolean If a locomotive should be prepended to the trainset.
---@param reversed boolean If the wagons and locomotive should be spawned reversed.
---@return table<SpawnVehicleDescription>
local function ConstructPassengerTrainWithLocomotive(maxLength, maxWagonCount, prependLocomotive, reversed)
    -- The resulting constructed trainset
    local result = {}

    -- Pick a locomotive for the trainset first, if requested
    local currentLength = 0
    if prependLocomotive then
        local locomotive = PickRandomElement(PassengerLocomotives)
        currentLength = locomotive.length
        table.insert(result, CreateNewSpawnFullVehicleDescriptor(locomotive.locomotiveName, reversed, "", 0, BrakeRegime.P))
    end

    -- Register X passenger wagons to the spawned trainset 
    for _ = 1, maxWagonCount do
        -- Pick a random wagon, break train construction if adding it would exceed the given maximum size
        local randomWagon = PickRandomElement(PassengerWagons)
        currentLength = currentLength + randomWagon.length
        if currentLength > maxLength then
            break
        end

        -- Register the picked wagon to the trainset
        table.insert(result, CreateNewSpawnFullVehicleDescriptor(randomWagon.wagonName, reversed, "", 0, BrakeRegime.P))
    end

    return result
end

--- Contructs a passenger trainset consisting of electrical multiple units to spawn based on the given input parameters.
---@param units table<EmuTypeMapping> The units to pick from.
---@param maxLength integer The maximum length of the train to construct, in meters.
---@param maxUnitCount integer The maximum count of units to append, must 1 or more.
---@param reversed boolean If the units should be spawned reversed.
---@return table<SpawnVehicleDescription>
local function ConstructPassengerTrainEmu(units, maxLength, maxUnitCount, reversed)
    -- The resulting constructed trainset
    local result = {}

    -- Find a random fitting unit to build the train based on
    local unit = nil
    for _ = 1, 10 do
        local randomUnit = PickRandomElement(units)
        if randomUnit.length <= maxLength then
            unit = randomUnit
            break
        end
    end

    -- Validate that a base unit was found successfully
    if unit == nil then
        error("unable to find a base unit for train with maximum length " .. tostring(maxLength))
    end

    -- Register the unit max times to the resulting trainset, or when the trainset length overflows
    local currentLength = 0
    for _ = 1, maxUnitCount do
        -- Check if an additional unit would overflow the max train length
        currentLength = currentLength + unit.length
        if currentLength > maxLength then
            break
        end

        -- Register an additional unit to the trainset
        table.insert(result, CreateNewSpawnFullVehicleDescriptor(unit.unitName, reversed, "", 0, BrakeRegime.P))
    end

    return result
end

-- =============================
--    Exposed API Stuff
-- =============================
--- The possible types of trains that can be spawned using this module
---@enum TrainSpawnType
TrainSpawnType = {
    --- A freight train.
    Freight = 1,
    --- A passenger train using a locomotive and wagons.
    Passenger_Locomotive = 2,
    --- A passenger train consisting of electrical multiple units (except pendolino).
    Passenger_Emu = 3,
    --- A passenger train consisting of pendolino units.
    Passenger_Pendolino = 4,
}

--- Initilizes the randomness used for train generation.
function InitializeSpawnRandomness()
    math.randomseed(os.time())
    for _ = 1, 10 do
        math.random()
    end
end

--- Creates a spawnable trainset based on the given input parameters.
---@param type TrainSpawnType The type of trainset to create.
---@param maxLength integer A positive integer that sets the maximum length of the trainset to spawn (in meters).
---@param maxUnitCount integer A positive integer that sets the maximum count of vehicles to spawn.
---@param prependLocomotive boolean|nil If the trainset should be prepended with a locomotive. Defaults to true, has no effect for emus.
---@param reversed boolean|nil If the trainset should be spawned in reverse. Defaults to false.
---@return table<SpawnVehicleDescription>
function CreateTrainset(type, maxLength, maxUnitCount, prependLocomotive, reversed)
    local reverse = reversed ~= nil and reversed
    local prependLoco = prependLocomotive ~= nil and prependLocomotive
    if type == TrainSpawnType.Freight then
        return ConstructFreightTrain(maxLength, maxUnitCount, prependLoco, reverse)
    elseif type == TrainSpawnType.Passenger_Locomotive then
        return ConstructPassengerTrainWithLocomotive(maxLength, maxUnitCount, prependLoco, reverse)
    elseif type == TrainSpawnType.Passenger_Emu then
        return ConstructPassengerTrainEmu(ElectricalMultipleUnits, maxLength, maxUnitCount, reverse)
    elseif type == TrainSpawnType.Passenger_Pendolino then
        return ConstructPassengerTrainEmu(PendolinoUnits, maxLength, maxUnitCount, reverse)
    else
        error("invalid trainset spawn type provided")
    end
end

--- Creates a spawnable trainset based on the given input parameters. The returned set has a maximum of 50 units.
---@param type TrainSpawnType The type of trainset to create.
---@param maxLength integer A positive integer that sets the maximum length of the trainset to spawn (in meters).
---@param reversed boolean|nil If the trainset should be spawned in reverse. Defaults to false.
---@return table<SpawnVehicleDescription>
function CreateTrainsetLengthLimited(type, maxLength, reversed)
    return CreateTrainset(type, maxLength, 50, reversed)
end

--- Creates a spawnable trainset based on the given input parameters. The returned set has a maximum length of 500 meters.
---@param type TrainSpawnType The type of trainset to create.
---@param maxUnitCount integer A positive integer that sets the maximum count of vehicles to spawn.
---@param reversed boolean|nil If the trainset should be spawned in reverse. Defaults to false.
---@return table<SpawnVehicleDescription>
function CreateTrainsetUnitLimited(type, maxUnitCount, reversed)
    return CreateTrainset(type, 500, maxUnitCount, reversed)
end
