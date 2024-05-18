---@class MissionTrainset
---@field locomotive string
---@field doorTransform string
MissionTrainset = {}
MissionTrainset.__index = MissionTrainset

--- Constructs a new mission trainset instance.
---@param locomotive string The name of the locomotive to use for the trainset.
---@param doorTransform string The transform name of one of the doors in the trainset.
---@return MissionTrainset
function MissionTrainset.new(locomotive, doorTransform)
    local self = setmetatable({}, MissionTrainset)
    self.locomotive = locomotive
    self.doorTransform = doorTransform
    return self
end

--- The mission trainset that uses a dragon as locomotive.
---@type MissionTrainset
DragonTrainset = MissionTrainset.new(
    LocomotiveNames.E6ACTa_016,
    "e6act_chasis/ET25_chassis/Doors2/doors")

--- The mission trainset that uses an ET22 as locomotive.
---@type MissionTrainset
Et22Trainset = MissionTrainset.new(
    LocomotiveNames.ET22_836,
    "Chassis/ChassisBujanie/INTERIOR/ET22_kabina A/drzwi_kabina_r_handler/drzwi_kabina_r")
