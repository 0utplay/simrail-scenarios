--- Utility functions to create setups using dialogues in SimRail.
require("SimRailCore")

--- A step in the setup process.
---@class SetupStep
---@field key string The key of the setup step. The message and option messages will be derived from the given key.
---@field results table<any> The results that can be selected from the step.
SetupStep = {}
SetupStep.__index = SetupStep

---@param key string The key of the setup step. The message and option messages will be derived from the given key.
---@param results table<any> The results that can be selected from the step.
---@return SetupStep
function SetupStep.new(key, results)
    local self = setmetatable({}, SetupStep)
    self.key = key
    self.results = results
    return self
end

---@param step SetupStep The setup step to display
---@param callback function The callback to call when an option gets selected. Takes the selected option as param.
local function DisplayNextStep(step, callback)
    -- collect the options available for the setup step
    local options = {}
    for optionIndex = 1, #step.results do
        local optionMessageKey = "Setup_" .. step.key .. "_option_" .. tostring(optionIndex)
        table.insert(options, {
            ["Text"] = optionMessageKey,
            ["OnClick"] = function()
                local stepResult = step.results[optionIndex]
                callback(stepResult)
            end,
        })
    end

    -- display a message box that allows for selection of the options
    local stepMessageKey = "Setup_" .. step.key
    ShowMessageBox(stepMessageKey, table.unpack(options))
end

---@param steps table<SetupStep> The setup steps to execute.
---@param callback function The callback that gets called when all setup steps were executed. Takes table<string, any> (containing the step results) as param.
function ExecuteSetup(steps, callback)
    -- call all setup steps and collect results
    local results = {}
    for index = 1, #steps do
        local step = steps[index]
        DisplayNextStep(step, function(result)
            results[step.key] = result
            if index == #steps then
                -- call the callback with the collected results
                callback(results)
            end
        end)
    end
end
