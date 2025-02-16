
 
	◦	
gamedata/shared/Items/Emote.lua
return {
-- ✰ Developer ✰ --
["Dance"] = {
Name = "Dance",
Rarity = "Developer",
Description = "",
Image = "rbxassetid://17732805786",
-- CanWalk = true,
},
}


--[[
[""] = {
Name = "",
Rarity = "Exclusive",
Description = '',
Image = "",
},
]]
gamedata/shared/Items/init.lua
return {
Emote = require(script.Emote),
}
gamedata/shared/GameInfo.lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")

return require(ReplicatedFirst.GameInfo)
gamedata/shared/Keybinds.lua
return {
PC = {
Dive = Enum.UserInputType.MouseButton2,
Shoot = Enum.UserInputType.MouseButton1,

Tackle = Enum.KeyCode.E,
Skill = Enum.KeyCode.Q,

RequestBall = Enum.KeyCode.R,
Sprint = Enum.KeyCode.LeftShift,
ShiftLock = Enum.KeyCode.LeftControl,

Emote = Enum.KeyCode.B,
},
Console = {
Shoot = Enum.KeyCode.ButtonR2,

Dive = Enum.KeyCode.ButtonL1,
Tackle = Enum.KeyCode.ButtonL1,
Skill = Enum.KeyCode.ButtonL1,

RequestBall = Enum.KeyCode.ButtonR1,
Sprint = Enum.KeyCode.ButtonY,

Emote = Enum.KeyCode.DPadLeft,
ShiftLock = Enum.KeyCode.ButtonL3,
}
}
gamedata/shared/TeamInfo.lua

return {

["Team 1"] = {
["Text"] = "Team 1",
["Identifier"] = "White",
["MainColor"] = Color3.fromRGB(255, 255, 255),
},

["Team 2"] = {
["Text"] = "Team 2",
["Identifier"] = "Red",
["MainColor"] = Color3.fromRGB(139, 22, 37),
},

}
modules/SmoothShiftLock/init.lua
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorkspaceService = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Lib = require(ReplicatedStorage.Lib)

local Spring = require(ReplicatedStorage.Modules.Spring)
local Trove = require(ReplicatedStorage.Modules.Trove)

local trove = Trove.new()

local config = {
["CHARACTER_SMOOTH_ROTATION"] = true, --// If your character should rotate smoothly or not
["MANUALLY_TOGGLEABLE"] = true, --// If the shift lock an be toggled manually by player
["CHARACTER_ROTATION_SPEED"] = 2, --// How quickly character rotates smoothly
["TRANSITION_SPRING_DAMPER"] = 0.7, --// Camera transition spring damper, test it out to see what works for you
["CAMERA_TRANSITION_IN_SPEED"] = 10, --// How quickly locked camera moves to offset position
["CAMERA_TRANSITION_OUT_SPEED"] = 14, --// How quickly locked camera moves back from offset position
["LOCKED_CAMERA_OFFSET"] = Vector3.new(0, 0, 0), --// Locked camera offset
["LOCKED_MOUSE_ICON"] = --// Locked mouse icon
"rbxasset://textures/MouseLockedCursor.png",
["LOCKED_MOUSE_VISIBLE"] = true,
}

local ENABLED = false

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local mouseUnlocked = false


local SmoothShiftLock = {}

function SmoothShiftLock:Init()
local managerTrove = Trove.new();
managerTrove:Connect(localPlayer.CharacterAdded, function()
self:CharacterAdded()
end)
if localPlayer.Character then
task.spawn(function()
self:CharacterAdded()
end)
end
end

function SmoothShiftLock:CharacterAdded()
--// Instances
self.Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
self.RootPart = self.Character:WaitForChild("HumanoidRootPart")
self.Humanoid = self.Character:WaitForChild("Humanoid")
self.Head = self.Character:WaitForChild("Head")
--// Other
self.Camera = WorkspaceService.CurrentCamera
--// Setup
self._connectionsTrove = Trove.new()
self.camOffsetSpring = Spring.new(Vector3.new(0, 0, 0))
self.camOffsetSpring.Damper = config.TRANSITION_SPRING_DAMPER

return self
end

function SmoothShiftLock:IsEnabled(): boolean
return ENABLED
end

function SmoothShiftLock:SetMouseState(enabled : boolean)
enabled = enabled and not playerGui.EmoteWheel.Enabled and not playerGui.TeamSelect.Enabled and (ENABLED or localPlayer:GetAttribute("MouseLocked"))
if mouseUnlocked then
enabled = false
end
UserInputService.MouseBehavior = enabled and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
UserInputService.MouseIcon = enabled and "rbxasset://textures/MouseLockedCursor.png" or ""
-- UserInputService.MouseIconEnabled = UserInputService.MouseBehavior == Enum.MouseBehavior.Default
end

function SmoothShiftLock:TransitionLockOffset(enable : boolean)
if self.camOffsetSpring == nil then
warn("Couldn't find offset spring!")
return
end
if enable then
self.camOffsetSpring.Speed = config.CAMERA_TRANSITION_IN_SPEED;
self.camOffsetSpring.Target = config.LOCKED_CAMERA_OFFSET;
else
self.camOffsetSpring.Speed = config.CAMERA_TRANSITION_OUT_SPEED;
self.camOffsetSpring.Target = Vector3.new(0, 0, 0);
end;
end

function SmoothShiftLock:ToggleShiftLock(enable : boolean)
assert(typeof(enable) == typeof(false), "Enable value is not a boolean.")
ENABLED = enable

self:SetMouseState(ENABLED)
self:TransitionLockOffset(ENABLED)

trove:Clean()
if self.Humanoid then
self.Humanoid.AutoRotate = not ENABLED
end

mouseUnlocked = false

if self.Character == nil or self.Character.Parent == nil then
return
end

if ENABLED then
trove:Connect(RunService.RenderStepped, function(delta)
if not ENABLED then
trove:Clean()
return
end

local character = self.Character
if character == nil or character:HasTag("Ragdoll") then
return
end
if not self.Humanoid or not self.RootPart then
return
end

local emoteData = character:GetAttribute("EmoteData")
if emoteData ~= nil then
emoteData = HttpService:JSONDecode(emoteData)
local shiftLockDisabled = emoteData[3]
if shiftLockDisabled then
return
end
end
end)
end

trove:Connect(playerGui.EmoteWheel:GetPropertyChangedSignal("Enabled"), function()
self:SetMouseState(true)
self:TransitionLockOffset(true)
end)
trove:Connect(playerGui.TeamSelect:GetPropertyChangedSignal("Enabled"), function()
self:SetMouseState(true)
self:TransitionLockOffset(true)
end)
trove:Add(task.spawn(function()
while not Lib.playerInGameOrPaused() do
task.wait()
end
if not ENABLED then
local function checkMouseLocked()
local mouseLocked = localPlayer:GetAttribute("MouseLocked")
self:SetMouseState(mouseLocked)
self:TransitionLockOffset(mouseLocked)
end
checkMouseLocked()
trove:Connect(localPlayer:GetAttributeChangedSignal("MouseLocked"), checkMouseLocked)
end
end))

return self
end

return SmoothShiftLock
modules/Zone/Enum/Accuracy.lua
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorkspaceService = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Lib = require(ReplicatedStorage.Lib)

local Spring = require(ReplicatedStorage.Modules.Spring)
local Trove = require(ReplicatedStorage.Modules.Trove)

local trove = Trove.new()

local config = {
["CHARACTER_SMOOTH_ROTATION"] = true, --// If your character should rotate smoothly or not
["MANUALLY_TOGGLEABLE"] = true, --// If the shift lock an be toggled manually by player
["CHARACTER_ROTATION_SPEED"] = 2, --// How quickly character rotates smoothly
["TRANSITION_SPRING_DAMPER"] = 0.7, --// Camera transition spring damper, test it out to see what works for you
["CAMERA_TRANSITION_IN_SPEED"] = 10, --// How quickly locked camera moves to offset position
["CAMERA_TRANSITION_OUT_SPEED"] = 14, --// How quickly locked camera moves back from offset position
["LOCKED_CAMERA_OFFSET"] = Vector3.new(0, 0, 0), --// Locked camera offset
["LOCKED_MOUSE_ICON"] = --// Locked mouse icon
"rbxasset://textures/MouseLockedCursor.png",
["LOCKED_MOUSE_VISIBLE"] = true,
}

local ENABLED = false

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local mouseUnlocked = false


local SmoothShiftLock = {}

function SmoothShiftLock:Init()
local managerTrove = Trove.new();
managerTrove:Connect(localPlayer.CharacterAdded, function()
self:CharacterAdded()
end)
if localPlayer.Character then
task.spawn(function()
self:CharacterAdded()
end)
end
end

function SmoothShiftLock:CharacterAdded()
--// Instances
self.Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
self.RootPart = self.Character:WaitForChild("HumanoidRootPart")
self.Humanoid = self.Character:WaitForChild("Humanoid")
self.Head = self.Character:WaitForChild("Head")
--// Other
self.Camera = WorkspaceService.CurrentCamera
--// Setup
self._connectionsTrove = Trove.new()
self.camOffsetSpring = Spring.new(Vector3.new(0, 0, 0))
self.camOffsetSpring.Damper = config.TRANSITION_SPRING_DAMPER

return self
end

function SmoothShiftLock:IsEnabled(): boolean
return ENABLED
end

function SmoothShiftLock:SetMouseState(enabled : boolean)
enabled = enabled and not playerGui.EmoteWheel.Enabled and not playerGui.TeamSelect.Enabled and (ENABLED or localPlayer:GetAttribute("MouseLocked"))
if mouseUnlocked then
enabled = false
end
UserInputService.MouseBehavior = enabled and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
UserInputService.MouseIcon = enabled and "rbxasset://textures/MouseLockedCursor.png" or ""
-- UserInputService.MouseIconEnabled = UserInputService.MouseBehavior == Enum.MouseBehavior.Default
end

function SmoothShiftLock:TransitionLockOffset(enable : boolean)
if self.camOffsetSpring == nil then
warn("Couldn't find offset spring!")
return
end
if enable then
self.camOffsetSpring.Speed = config.CAMERA_TRANSITION_IN_SPEED;
self.camOffsetSpring.Target = config.LOCKED_CAMERA_OFFSET;
else
self.camOffsetSpring.Speed = config.CAMERA_TRANSITION_OUT_SPEED;
self.camOffsetSpring.Target = Vector3.new(0, 0, 0);
end;
end

function SmoothShiftLock:ToggleShiftLock(enable : boolean)
assert(typeof(enable) == typeof(false), "Enable value is not a boolean.")
ENABLED = enable

self:SetMouseState(ENABLED)
self:TransitionLockOffset(ENABLED)

trove:Clean()
if self.Humanoid then
self.Humanoid.AutoRotate = not ENABLED
end

mouseUnlocked = false

if self.Character == nil or self.Character.Parent == nil then
return
end

if ENABLED then
trove:Connect(RunService.RenderStepped, function(delta)
if not ENABLED then
trove:Clean()
return
end

local character = self.Character
if character == nil or character:HasTag("Ragdoll") then
return
end
if not self.Humanoid or not self.RootPart then
return
end

local emoteData = character:GetAttribute("EmoteData")
if emoteData ~= nil then
emoteData = HttpService:JSONDecode(emoteData)
local shiftLockDisabled = emoteData[3]
if shiftLockDisabled then
return
end
end
end)
end

trove:Connect(playerGui.EmoteWheel:GetPropertyChangedSignal("Enabled"), function()
self:SetMouseState(true)
self:TransitionLockOffset(true)
end)
trove:Connect(playerGui.TeamSelect:GetPropertyChangedSignal("Enabled"), function()
self:SetMouseState(true)
self:TransitionLockOffset(true)
end)
trove:Add(task.spawn(function()
while not Lib.playerInGameOrPaused() do
task.wait()
end
if not ENABLED then
local function checkMouseLocked()
local mouseLocked = localPlayer:GetAttribute("MouseLocked")
self:SetMouseState(mouseLocked)
self:TransitionLockOffset(mouseLocked)
end
checkMouseLocked()
trove:Connect(localPlayer:GetAttributeChangedSignal("MouseLocked"), checkMouseLocked)
end
end))

return self
end

return SmoothShiftLock
modules/Zone/Enum/Detection.lua
-- Important note: Precision checks currently only for 'players' and the 'localplayer', not 'parts'.

-- enumName, enumValue, additionalProperty
return {
{"WholeBody", 1}, -- Multiple checks will be casted over an entire players character
{"Centre", 2}, -- A singular check will be performed on the players HumanoidRootPart
--{"Automatic", 3}, -- REMOVED DUE TO UNECESSARY COMPLEXITY. ZonePlus will dynamically switch between 'WholeBody' and 'Centre' depending upon the number of players in a server (this typically only occurs for servers with 100+ players when volume checks begin to exceed 0.5% in script performance).
}
modules/Zone/Enum/init.lua
-- Custom enum implementation that provides an effective way to compare, send
-- and store values. Instead of returning a userdata value, enum items return
-- their corresponding itemValue (an integer) when indexed. Enum items can
-- also associate a 'property', specified as the third element, which can be
-- retrieved by doing ``enum.getProperty(ITEM_NAME_OR_VALUE)``
-- This ultimately means groups of data can be easily categorised, efficiently
-- transmitted over networks and saved without throwing errors.
-- Ben Horton (ForeverHD)



-- LOCAL
local Enum = {}
local enums = {}
Enum.enums = enums



-- METHODS
function Enum.createEnum(enumName, details)
assert(typeof(enumName) == "string", "bad argument #1 - enums must be created using a string name!")
assert(typeof(details) == "table", "bad argument #2 - enums must be created using a table!")
assert(not enums[enumName], ("enum '%s' already exists!"):format(enumName))

local enum = {}
local usedNames = {}
local usedValues = {}
local usedProperties = {}
local enumMetaFunctions = {
getName = function(valueOrProperty)
valueOrProperty = tostring(valueOrProperty)
local index = usedValues[valueOrProperty]
if not index then
index = usedProperties[valueOrProperty]
end
if index then
return details[index][1]
end
end,
getValue = function(nameOrProperty)
nameOrProperty = tostring(nameOrProperty)
local index = usedNames[nameOrProperty]
if not index then
index = usedProperties[nameOrProperty]
end
if index then
return details[index][2]
end
end,
getProperty = function(nameOrValue)
nameOrValue = tostring(nameOrValue)
local index = usedNames[nameOrValue]
if not index then
index = usedValues[nameOrValue]
end
if index then
return details[index][3]
end
end
}
for i, detail in pairs(details) do
assert(typeof(detail) == "table", ("bad argument #2.%s - details must only be comprised of tables!"):format(i))
local name = detail[1]
assert(typeof(name) == "string", ("bad argument #2.%s.1 - detail name must be a string!"):format(i))
assert(typeof(not usedNames[name]), ("bad argument #2.%s.1 - the detail name '%s' already exists!"):format(i, name))
assert(typeof(not enumMetaFunctions[name]), ("bad argument #2.%s.1 - that name is reserved."):format(i, name))
usedNames[tostring(name)] = i
local value = detail[2]
local valueString = tostring(value)
--assert(typeof(value) == "number" and math.ceil(value)/value == 1, ("bad argument #2.%s.2 - detail value must be an integer!"):format(i))
assert(typeof(not usedValues[valueString]), ("bad argument #2.%s.2 - the detail value '%s' already exists!"):format(i, valueString))
usedValues[valueString] = i
local property = detail[3]
if property then
assert(typeof(not usedProperties[property]), ("bad argument #2.%s.3 - the detail property '%s' already exists!"):format(i, tostring(property)))
usedProperties[tostring(property)] = i
end
enum[name] = value
setmetatable(enum, {
__index = function(_, index)
return(enumMetaFunctions[index])
end
})
end

enums[enumName] = enum
return enum
end

function Enum.getEnums()
return enums
end



-- SETUP ENUMS
local createEnum = Enum.createEnum
for _, childModule in pairs(script:GetChildren()) do
if childModule:IsA("ModuleScript") then
local enumDetail = require(childModule)
createEnum(childModule.Name, enumDetail)
end
end

--[[
-- Example enum
createEnum("Color", {
{"White", 1, Color3.fromRGB(255, 255, 255)},
{"Black", 2, Color3.fromRGB(0, 0, 0)},
})
--]]



return Enum
modules/Zone/ZoneController/CollectiveWorldModel.lua
local CollectiveWorldModel = {}
local worldModel
local runService = game:GetService("RunService")



-- FUNCTIONS
function CollectiveWorldModel.setupWorldModel(zone)
if worldModel then
return worldModel
end
local location = (runService:IsClient() and "ReplicatedStorage") or "ServerStorage"
worldModel = Instance.new("WorldModel")
worldModel.Name = "ZonePlusWorldModel"
worldModel.Parent = game:GetService(location)
return worldModel
end



-- METHODS
function CollectiveWorldModel:_getCombinedResults(methodName, ...)
local results = workspace[methodName](workspace, ...)
if worldModel then
local additionalResults = worldModel[methodName](worldModel, ...)
for _, result in pairs(additionalResults) do
table.insert(results, result)
end
end
return results
end

function CollectiveWorldModel:GetPartBoundsInBox(cframe, size, overlapParams)
return self:_getCombinedResults("GetPartBoundsInBox", cframe, size, overlapParams)
end

function CollectiveWorldModel:GetPartBoundsInRadius(position, radius, overlapParams)
return self:_getCombinedResults("GetPartBoundsInRadius", position, radius, overlapParams)
end

function CollectiveWorldModel:GetPartsInPart(part, overlapParams)
return self:_getCombinedResults("GetPartsInPart", part, overlapParams)
end



return CollectiveWorldModel
modules/Zone/ZoneController/Tracker.lua
-- This enables data on volumes, HumanoidRootParts, etc to be handled on an event-basis, instead of being retrieved every interval

-- LOCAL
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local heartbeat = runService.Heartbeat
local Signal = require(script.Parent.Parent.Signal)
local Janitor = require(script.Parent.Parent.Janitor)



-- PUBLIC
local Tracker = {}
Tracker.__index = Tracker
local trackers = {}
Tracker.trackers = trackers
Tracker.itemAdded = Signal.new()
Tracker.itemRemoved = Signal.new()
Tracker.bodyPartsToIgnore = {
-- We ignore these due to their insignificance (e.g. we ignore the lower and
-- upper torso because the HumanoidRootPart also covers these areas)
-- This ultimately reduces the burden on the player region checks
UpperTorso = true,
LowerTorso = true,
Torso = true,
LeftHand = true,
RightHand = true,
LeftFoot = true,
RightFoot = true,
}



-- FUNCTIONS
function Tracker.getCombinedTotalVolumes()
local combinedVolume = 0
for tracker, _ in pairs(trackers) do
combinedVolume += tracker.totalVolume
end
return combinedVolume
end

function Tracker.getCharacterSize(character)
local head = character and character:FindFirstChild("Head")
local hrp = character and character:FindFirstChild("HumanoidRootPart")
if not(hrp and head) then return nil end
if not head:IsA("BasePart") then
head = hrp
end
local headY = head.Size.Y
local hrpSize = hrp.Size
local charSize = (hrpSize * Vector3.new(2, 2, 1)) + Vector3.new(0, headY, 0)
local charCFrame = hrp.CFrame * CFrame.new(0, headY/2 - hrpSize.Y/2, 0)
return charSize, charCFrame
end



-- CONSTRUCTOR
function Tracker.new(name)
local self = {}
setmetatable(self, Tracker)

self.name = name
self.totalVolume = 0
self.parts = {}
self.partToItem = {}
self.items = {}
self.whitelistParams = nil
self.characters = {}
self.baseParts = {}
self.exitDetections = {}
self.janitor = Janitor.new()

if name == "player" then
local function updatePlayerCharacters()
local characters = {}
for _, player in pairs(players:GetPlayers()) do
local character = player.Character
if character then
characters[character] = true
end
end
self.characters = characters
end

local function playerAdded(player)
local function charAdded(character)
local humanoid = character:WaitForChild("Humanoid", 3)
if humanoid then
updatePlayerCharacters()
self:update()
for _, valueInstance in pairs(humanoid:GetChildren()) do
if valueInstance:IsA("NumberValue") then
valueInstance.Changed:Connect(function()
self:update()
end)
end
end
end
end
if player.Character then
charAdded(player.Character)
end
player.CharacterAdded:Connect(charAdded)
player.CharacterRemoving:Connect(function(removingCharacter)
self.exitDetections[removingCharacter] = nil
end)
end

players.PlayerAdded:Connect(playerAdded)
for _, player in pairs(players:GetPlayers()) do
playerAdded(player)
end

players.PlayerRemoving:Connect(function(player)
updatePlayerCharacters()
self:update()
end)


elseif name == "item" then
local function updateItem(itemDetail, newValue)
if itemDetail.isCharacter then
self.characters[itemDetail.item] = newValue
elseif itemDetail.isBasePart then
self.baseParts[itemDetail.item] = newValue
end
self:update()
end
Tracker.itemAdded:Connect(function(itemDetail)
updateItem(itemDetail, true)
end)
Tracker.itemRemoved:Connect(function(itemDetail)
self.exitDetections[itemDetail.item] = nil
updateItem(itemDetail, nil)
end)
end

trackers[self] = true
task.defer(self.update, self)
return self
end



-- METHODS
function Tracker:_preventMultiFrameUpdates(methodName, ...)
-- This prevents the funtion being called twice within a single frame
-- If called more than once, the function will initally be delayed again until the next frame, then all others cancelled
self._preventMultiDetails = self._preventMultiDetails or {}
local detail = self._preventMultiDetails[methodName]
if not detail then
detail = {
calling = false,
callsThisFrame = 0,
updatedThisFrame = false,
}
self._preventMultiDetails[methodName] = detail
end

detail.callsThisFrame += 1
if detail.callsThisFrame == 1 then
local args = table.pack(...)
task.defer(function()
local newCallsThisFrame = detail.callsThisFrame
detail.callsThisFrame = 0
if newCallsThisFrame > 1 then
self[methodName](self, unpack(args))
end
end)
return false
end
return true
end

function Tracker:update()
if self:_preventMultiFrameUpdates("update") then
return
end

self.totalVolume = 0
self.parts = {}
self.partToItem = {}
self.items = {}

-- This tracks the bodyparts of a character
for character, _ in pairs(self.characters) do
local charSize = Tracker.getCharacterSize(character)
if not charSize then
continue
end
local rSize = charSize
local charVolume = rSize.X*rSize.Y*rSize.Z
self.totalVolume += charVolume

local characterJanitor = self.janitor:add(Janitor.new(), "destroy", "trackCharacterParts-"..self.name)
local function updateTrackerOnParentChanged(instance)
characterJanitor:add(instance.AncestryChanged:Connect(function()
if not instance:IsDescendantOf(game) then
if instance.Parent == nil and characterJanitor ~= nil then
characterJanitor:destroy()
characterJanitor = nil
self:update()
end
end
end), "Disconnect")
end

for _, part in pairs(character:GetChildren()) do
if part:IsA("BasePart") and not Tracker.bodyPartsToIgnore[part.Name] then
self.partToItem[part] = character
table.insert(self.parts, part)
updateTrackerOnParentChanged(part)
end
end
updateTrackerOnParentChanged(character)
table.insert(self.items, character)
end

-- This tracks any additional baseParts
for additionalPart, _ in pairs(self.baseParts) do
local rSize = additionalPart.Size
local partVolume = rSize.X*rSize.Y*rSize.Z
self.totalVolume += partVolume
self.partToItem[additionalPart] = additionalPart
table.insert(self.parts, additionalPart)
table.insert(self.items, additionalPart)
end

-- This creates the whitelist so that
self.whitelistParams = OverlapParams.new()
self.whitelistParams.FilterType = Enum.RaycastFilterType.Whitelist
self.whitelistParams.MaxParts = #self.parts
self.whitelistParams.FilterDescendantsInstances = self.parts
end



return Tracker
modules/Zone/ZoneController/init.lua
-- CONFIG
local WHOLE_BODY_DETECTION_LIMIT = 729000 -- This is roughly the volume where Region3 checks begin to exceed 0.5% in Script Performance



-- LOCAL
local Janitor = require(script.Parent.Janitor)
local Enum_ = require(script.Parent.Enum)
local Signal = require(script.Parent.Signal)
local Tracker = require(script.Tracker)
local CollectiveWorldModel = require(script.CollectiveWorldModel)
local enum = Enum_.enums
local players = game:GetService("Players")
local activeZones = {}
local activeZonesTotalVolume = 0
local activeTriggers = {}
local registeredZones = {}
local activeParts = {}
local activePartToZone = {}
local allParts = {}
local allPartToZone = {}
local activeConnections = 0
local runService = game:GetService("RunService")
local heartbeat = runService.Heartbeat
local heartbeatConnections = {}
local localPlayer = runService:IsClient() and players.LocalPlayer



-- PUBLIC
local ZoneController = {}
local trackers = {}
trackers.player = Tracker.new("player")
trackers.item = Tracker.new("item")
ZoneController.trackers = trackers



-- LOCAL FUNCTIONS
local function dictLength(dictionary)
local count = 0
for _, _ in pairs(dictionary) do
count += 1
end
return count
end

local function fillOccupants(zonesAndOccupantsTable, zone, occupant)
local occupantsDict = zonesAndOccupantsTable[zone]
if not occupantsDict then
occupantsDict = {}
zonesAndOccupantsTable[zone] = occupantsDict
end
local prevCharacter = occupant:IsA("Player") and occupant.Character
occupantsDict[occupant] = (prevCharacter or true)
end

local heartbeatActions = {
["player"] = function(recommendedDetection)
return ZoneController._getZonesAndItems("player", activeZones, activeZonesTotalVolume, true, recommendedDetection)
end,
["localPlayer"] = function(recommendedDetection)
local zonesAndOccupants = {}
local character = localPlayer.Character
if not character then
return zonesAndOccupants
end
local touchingZones = ZoneController.getTouchingZones(character, true, recommendedDetection, trackers.player)
for _, zone in pairs(touchingZones) do
if zone.activeTriggers["localPlayer"] then
fillOccupants(zonesAndOccupants, zone, localPlayer)
end
end
return zonesAndOccupants
end,
["item"] = function(recommendedDetection)
return ZoneController._getZonesAndItems("item", activeZones, activeZonesTotalVolume, true, recommendedDetection)
end,
}



-- PRIVATE FUNCTIONS
function ZoneController._registerZone(zone)
registeredZones[zone] = true
local registeredJanitor = zone.janitor:add(Janitor.new(), "destroy")
zone._registeredJanitor = registeredJanitor
registeredJanitor:add(zone.updated:Connect(function()
ZoneController._updateZoneDetails()
end), "Disconnect")
ZoneController._updateZoneDetails()
end

function ZoneController._deregisterZone(zone)
registeredZones[zone] = nil
zone._registeredJanitor:destroy()
zone._registeredJanitor = nil
ZoneController._updateZoneDetails()
end

function ZoneController._registerConnection(registeredZone, registeredTriggerType)
local originalItems = dictLength(registeredZone.activeTriggers)
activeConnections += 1
if originalItems == 0 then
activeZones[registeredZone] = true
ZoneController._updateZoneDetails()
end
local currentTriggerCount = activeTriggers[registeredTriggerType]
activeTriggers[registeredTriggerType] = (currentTriggerCount and currentTriggerCount+1) or 1
registeredZone.activeTriggers[registeredTriggerType] = true
if registeredZone.touchedConnectionActions[registeredTriggerType] then
registeredZone:_formTouchedConnection(registeredTriggerType)
end
if heartbeatActions[registeredTriggerType] then
ZoneController._formHeartbeat(registeredTriggerType)
end
end

-- This decides what to do if detection is 'Automatic'
-- This is placed in ZoneController instead of the Zone object due to the ZoneControllers all-knowing group-minded logic
function ZoneController.updateDetection(zone)
local detectionTypes = {
["enterDetection"] = "_currentEnterDetection",
["exitDetection"] = "_currentExitDetection",
}
for detectionType, currentDetectionName in pairs(detectionTypes) do
local detection = zone[detectionType]
local combinedTotalVolume = Tracker.getCombinedTotalVolumes()
if detection == enum.Detection.Automatic then
if combinedTotalVolume > WHOLE_BODY_DETECTION_LIMIT then
detection = enum.Detection.Centre
else
detection = enum.Detection.WholeBody
end
end
zone[currentDetectionName] = detection
end
end

function ZoneController._formHeartbeat(registeredTriggerType)
local heartbeatConnection = heartbeatConnections[registeredTriggerType]
if heartbeatConnection then return end
-- This will only ever connect once per triggerType per server
-- This means instead of initiating a loop per-zone we can handle everything within
-- a singular connection. This is particularly beneficial for player/item-orinetated
-- checking, where a check only needs to be cast once per interval, as apposed
-- to every zone per interval
-- I utilise heartbeat with os.clock() to provide precision (where needed) and flexibility
local nextCheck = 0
heartbeatConnection = heartbeat:Connect(function()
local clockTime = os.clock()
if clockTime >= nextCheck then
local lowestAccuracy
local lowestDetection
for zone, _ in pairs(activeZones) do
if zone.activeTriggers[registeredTriggerType] then
local zAccuracy = zone.accuracy
if lowestAccuracy == nil or zAccuracy < lowestAccuracy then
lowestAccuracy = zAccuracy
end
ZoneController.updateDetection(zone)
local zDetection = zone._currentEnterDetection
if lowestDetection == nil or zDetection < lowestDetection then
lowestDetection = zDetection
end
end
end
local highestAccuracy = lowestAccuracy
local zonesAndOccupants = heartbeatActions[registeredTriggerType](lowestDetection)

-- If a zone belongs to a settingsGroup with 'onlyEnterOnceExitedAll = true' , and the occupant already exists in a member group, then
-- ignore all incoming occupants for the other zones (preventing the enteredSignal from being fired until the occupant has left
-- all other zones within the same settingGroup)
local occupantsToBlock = {}
local zonesToPotentiallyIgnore = {}
for zone, newOccupants in pairs(zonesAndOccupants) do
local settingsGroup = (zone.settingsGroupName and ZoneController.getGroup(zone.settingsGroupName))
if settingsGroup and settingsGroup.onlyEnterOnceExitedAll == true then
--local currentOccupants = zone.occupants[registeredTriggerType]
--if currentOccupants then
for newOccupant, _ in pairs(newOccupants) do
--if currentOccupants[newOccupant] then
local groupDetail = occupantsToBlock[zone.settingsGroupName]
if not groupDetail then
groupDetail = {}
occupantsToBlock[zone.settingsGroupName] = groupDetail
end
groupDetail[newOccupant] = zone
--end
end
zonesToPotentiallyIgnore[zone] = newOccupants
--end
end
end
for zone, newOccupants in pairs(zonesToPotentiallyIgnore) do
local groupDetail = occupantsToBlock[zone.settingsGroupName]
if groupDetail then
for newOccupant, _ in pairs(newOccupants) do
local occupantToKeepZone = groupDetail[newOccupant]
if occupantToKeepZone and occupantToKeepZone ~= zone then
newOccupants[newOccupant] = nil
end
end
end
end

-- This deduces what signals should be fired
local collectiveSignalsToFire = {{}, {}}
for zone, _ in pairs(activeZones) do
if zone.activeTriggers[registeredTriggerType] then
local zAccuracy = zone.accuracy
local occupantsDict = zonesAndOccupants[zone] or {}
local occupantsPresent = false
for k,v in pairs(occupantsDict) do
occupantsPresent = true
break
end
if occupantsPresent and zAccuracy > highestAccuracy then
highestAccuracy = zAccuracy
end
local signalsToFire = zone:_updateOccupants(registeredTriggerType, occupantsDict)
collectiveSignalsToFire[1][zone] = signalsToFire.exited
collectiveSignalsToFire[2][zone] = signalsToFire.entered
end
end

-- This ensures all exited signals and called before entered signals
local indexToSignalType = {"Exited", "Entered"}
for index, zoneAndOccupants in pairs(collectiveSignalsToFire) do
local signalType = indexToSignalType[index]
local signalName = registeredTriggerType..signalType
for zone, occupants in pairs(zoneAndOccupants) do
local signal = zone[signalName]
if signal then
for _, occupant in pairs(occupants) do
signal:Fire(occupant)
end
end
end
end

local cooldown = enum.Accuracy.getProperty(highestAccuracy)
nextCheck = clockTime + cooldown
end
end)
heartbeatConnections[registeredTriggerType] = heartbeatConnection
end

function ZoneController._deregisterConnection(registeredZone, registeredTriggerType)
activeConnections -= 1
if activeTriggers[registeredTriggerType] == 1 then
activeTriggers[registeredTriggerType] = nil
local heartbeatConnection = heartbeatConnections[registeredTriggerType]
if heartbeatConnection then
heartbeatConnections[registeredTriggerType] = nil
heartbeatConnection:Disconnect()
end
else
activeTriggers[registeredTriggerType] -= 1
end
registeredZone.activeTriggers[registeredTriggerType] = nil
if dictLength(registeredZone.activeTriggers) == 0 then
activeZones[registeredZone] = nil
ZoneController._updateZoneDetails()
end
if registeredZone.touchedConnectionActions[registeredTriggerType] then
registeredZone:_disconnectTouchedConnection(registeredTriggerType)
end
end

function ZoneController._updateZoneDetails()
activeParts = {}
activePartToZone = {}
allParts = {}
allPartToZone = {}
activeZonesTotalVolume = 0
for zone, _ in pairs(registeredZones) do
local isActive = activeZones[zone]
if isActive then
activeZonesTotalVolume += zone.volume
end
for _, zonePart in pairs(zone.zoneParts) do
if isActive then
table.insert(activeParts, zonePart)
activePartToZone[zonePart] = zone
end
table.insert(allParts, zonePart)
allPartToZone[zonePart] = zone
end
end
end

function ZoneController._getZonesAndItems(trackerName, zonesDictToCheck, zoneCustomVolume, onlyActiveZones, recommendedDetection)
local totalZoneVolume = zoneCustomVolume
if not totalZoneVolume then
for zone, _ in pairs(zonesDictToCheck) do
totalZoneVolume += zone.volume
end
end
local zonesAndOccupants = {}
local tracker = trackers[trackerName]
if tracker.totalVolume < totalZoneVolume then
-- If the volume of all *characters/items* within the server is *less than* the total
-- volume of all active zones (i.e. zones which listen for .playerEntered)
-- then it's more efficient cast checks within each character and
-- then determine the zones they belong to
for _, item in pairs(tracker.items) do
local touchingZones = ZoneController.getTouchingZones(item, onlyActiveZones, recommendedDetection, tracker)
for _, zone in pairs(touchingZones) do
if not onlyActiveZones or zone.activeTriggers[trackerName] then
local finalItem = item
if trackerName == "player" then
finalItem = players:GetPlayerFromCharacter(item)
end
if finalItem then
fillOccupants(zonesAndOccupants, zone, finalItem)
end
end
end
end
else
-- If the volume of all *active zones* within the server is *less than* the total
-- volume of all characters/items, then it's more efficient to perform the
-- checks directly within each zone to determine players inside
for zone, _ in pairs(zonesDictToCheck) do
if not onlyActiveZones or zone.activeTriggers[trackerName] then
local result = CollectiveWorldModel:GetPartBoundsInBox(zone.region.CFrame, zone.region.Size, tracker.whitelistParams)
local finalItemsDict = {}
for _, itemOrChild in pairs(result) do
local correspondingItem = tracker.partToItem[itemOrChild]
if not finalItemsDict[correspondingItem] then
finalItemsDict[correspondingItem] = true
end
end
for item, _ in pairs(finalItemsDict) do
if trackerName == "player" then
local player = players:GetPlayerFromCharacter(item)
if zone:findPlayer(player) then
fillOccupants(zonesAndOccupants, zone, player)
end
elseif zone:findItem(item) then
fillOccupants(zonesAndOccupants, zone, item)
end
end
end
end
end
return zonesAndOccupants
end



-- PUBLIC FUNCTIONS
function ZoneController.getZones()
local registeredZonesArray = {}
for zone, _ in pairs(registeredZones) do
table.insert(registeredZonesArray, zone)
end
return registeredZonesArray
end

--[[
-- the player touched events which utilise active zones at the moment may change to the new CanTouch method for parts in the future
-- hence im disabling this as it may be depreciated quite soon
function ZoneController.getActiveZones()
local zonesArray = {}
for zone, _ in pairs(activeZones) do
table.insert(zonesArray, zone)
end
return zonesArray
end
--]]

function ZoneController.getTouchingZones(item, onlyActiveZones, recommendedDetection, tracker)
local exitDetection, finalDetection
if tracker then
exitDetection = tracker.exitDetections[item]
tracker.exitDetections[item] = nil
end
finalDetection = exitDetection or recommendedDetection

local itemSize, itemCFrame
local itemIsBasePart = item:IsA("BasePart")
local itemIsCharacter = not itemIsBasePart
local bodyPartsToCheck = {}
if itemIsBasePart then
itemSize, itemCFrame = item.Size, item.CFrame
table.insert(bodyPartsToCheck, item)
elseif finalDetection == enum.Detection.WholeBody then
itemSize, itemCFrame = Tracker.getCharacterSize(item)
bodyPartsToCheck = item:GetChildren()
else
local hrp = item:FindFirstChild("HumanoidRootPart")
if hrp then
itemSize, itemCFrame = hrp.Size, hrp.CFrame
table.insert(bodyPartsToCheck, hrp)
end
end
if not itemSize or not itemCFrame then return {} end

--[[
local part = Instance.new("Part")
part.Size = itemSize
part.CFrame = itemCFrame
part.Anchored = true
part.CanCollide = false
part.Color = Color3.fromRGB(255, 0, 0)
part.Transparency = 0.4
part.Parent = workspace
game:GetService("Debris"):AddItem(part, 2)
--]]
local partsTable = (onlyActiveZones and activeParts) or allParts
local partToZoneDict = (onlyActiveZones and activePartToZone) or allPartToZone

local boundParams = OverlapParams.new()
boundParams.FilterType = Enum.RaycastFilterType.Whitelist
boundParams.MaxParts = #partsTable
boundParams.FilterDescendantsInstances = partsTable

-- This retrieves the bounds (the rough shape) of all parts touching the item/character
-- If the corresponding zone is made up of *entirely* blocks then the bound will
-- be the actual shape of the part.
local touchingPartsDictionary = {}
local zonesDict = {}
local boundParts = CollectiveWorldModel:GetPartBoundsInBox(itemCFrame, itemSize, boundParams)
local boundPartsThatRequirePreciseChecks = {}
for _, boundPart in pairs(boundParts) do
local correspondingZone = partToZoneDict[boundPart]
if correspondingZone and correspondingZone.allZonePartsAreBlocks then
zonesDict[correspondingZone] = true
touchingPartsDictionary[boundPart] = correspondingZone
else
table.insert(boundPartsThatRequirePreciseChecks, boundPart)
end
end

-- If the bound parts belong to a zone that isn't entirely made up of blocks, then
-- we peform additional checks using GetPartsInPart which enables shape
-- geometries to be precisely determined for non-block baseparts.
local totalRemainingBoundParts = #boundPartsThatRequirePreciseChecks
local precisePartsCount = 0
if totalRemainingBoundParts > 0 then

local preciseParams = OverlapParams.new()
preciseParams.FilterType = Enum.RaycastFilterType.Whitelist
preciseParams.MaxParts = totalRemainingBoundParts
preciseParams.FilterDescendantsInstances = boundPartsThatRequirePreciseChecks

local character = item
for _, bodyPart in pairs(bodyPartsToCheck) do
local endCheck = false
if not bodyPart:IsA("BasePart") or (itemIsCharacter and Tracker.bodyPartsToIgnore[bodyPart.Name]) then
continue
end
local preciseParts = CollectiveWorldModel:GetPartsInPart(bodyPart, preciseParams)
for _, precisePart in pairs(preciseParts) do
if not touchingPartsDictionary[precisePart] then
local correspondingZone = partToZoneDict[precisePart]
if correspondingZone then
zonesDict[correspondingZone] = true
touchingPartsDictionary[precisePart] = correspondingZone
precisePartsCount += 1
end
if precisePartsCount == totalRemainingBoundParts then
endCheck = true
break
end
end
end
if endCheck then
break
end
end
end

local touchingZonesArray = {}
local newExitDetection
for zone, _ in pairs(zonesDict) do
if newExitDetection == nil or zone._currentExitDetection < newExitDetection then
newExitDetection = zone._currentExitDetection
end
table.insert(touchingZonesArray, zone)
end
if newExitDetection and tracker then
tracker.exitDetections[item] = newExitDetection
end
return touchingZonesArray, touchingPartsDictionary
end

local settingsGroups = {}
function ZoneController.setGroup(settingsGroupName, properties)
local group = settingsGroups[settingsGroupName]
if not group then
group = {}
settingsGroups[settingsGroupName] = group
end


-- PUBLIC PROPERTIES --
group.onlyEnterOnceExitedAll = true

-- PRIVATE PROPERTIES --
group._name = settingsGroupName
group._memberZones = {}


if typeof(properties) == "table" then
for k, v in pairs(properties) do
group[k] = v
end
end
return group
end

function ZoneController.getGroup(settingsGroupName)
return settingsGroups[settingsGroupName]
end

local workspaceContainer
local workspaceContainerName = string.format("ZonePlus%sContainer", (runService:IsClient() and "Client") or "Server")
function ZoneController.getWorkspaceContainer()
local container = workspaceContainer or workspace:FindFirstChild(workspaceContainerName)
if not container then
container = Instance.new("Folder")
container.Name = workspaceContainerName
container.Parent = workspace
workspaceContainer = container
end
return container
end



return ZoneController
modules/Zone/Janitor.lua
-- Janitor
-- Original by Validark
-- Modifications by pobammer
-- roblox-ts support by OverHash and Validark
-- LinkToInstance fixed by Elttob.

local RunService = game:GetService("RunService")
local Heartbeat = RunService.Heartbeat

local IndicesReference = newproxy(true)
getmetatable(IndicesReference).__tostring = function()
return "IndicesReference"
end

local LinkToInstanceIndex = newproxy(true)
getmetatable(LinkToInstanceIndex).__tostring = function()
return "LinkToInstanceIndex"
end

local METHOD_NOT_FOUND_ERROR = "Object %s doesn't have method %s, are you sure you want to add it? Traceback: %s"
--local NOT_A_PROMISE = "Invalid argument #1 to 'Janitor:AddPromise' (Promise expected, got %s (%s))"

local Janitor = {
ClassName = "Janitor";
__index = {
CurrentlyCleaning = true;
[IndicesReference] = nil;
};
}

local TypeDefaults = {
["function"] = true;
RBXScriptConnection = "Disconnect";
}

--[[**
Instantiates a new Janitor object.
@returns [t:Janitor]
**--]]
function Janitor.new()
return setmetatable({
CurrentlyCleaning = false;
[IndicesReference] = nil;
}, Janitor)
end

--[[**
Determines if the passed object is a Janitor.
@param [t:any] Object The object you are checking.
@returns [t:boolean] Whether or not the object is a Janitor.
**--]]
function Janitor.Is(Object)
return type(Object) == "table" and getmetatable(Object) == Janitor
end

Janitor.is = Janitor.Is

--[[**
Adds an `Object` to Janitor for later cleanup, where `MethodName` is the key of the method within `Object` which should be called at cleanup time. If the `MethodName` is `true` the `Object` itself will be called instead. If passed an index it will occupy a namespace which can be `Remove()`d or overwritten. Returns the `Object`.
@param [t:any] Object The object you want to clean up.
@param [t:string|true?] MethodName The name of the method that will be used to clean up. If not passed, it will first check if the object's type exists in TypeDefaults, and if that doesn't exist, it assumes `Destroy`.
@param [t:any?] Index The index that can be used to clean up the object manually.
@returns [t:any] The object that was passed.
**--]]
function Janitor.__index:Add(Object, MethodName, Index)
if Index == nil then
Index = newproxy(false)
end

if Index then
self:Remove(Index)

local This = self[IndicesReference]
if not This then
This = {}
self[IndicesReference] = This
end

This[Index] = Object
end
--[[
if Promise.is(Object) then
local Id = newproxy(false)
if Object:getStatus() == Promise.Status.Started then
local NewPromise = self:Add(Promise.resolve(Object), "cancel", Id)
NewPromise:finallyCall(self.Remove, self, Id)
return NewPromise, Id
else
return Object
end
end--]]

MethodName = MethodName or TypeDefaults[typeof(Object)] or "Destroy"
if type(Object) ~= "function" and not Object[MethodName] then
warn(string.format(METHOD_NOT_FOUND_ERROR, tostring(Object), tostring(MethodName), debug.traceback(nil, 2)))
end

self[Object] = MethodName
return Object, Index
end

Janitor.__index.Give = Janitor.__index.Add

-- My version of Promise has PascalCase, but I converted it to use lowerCamelCase for this release since obviously that's important to do.

--[[**
Adds a promise to the janitor. If the janitor is cleaned up and the promise is not completed, the promise will be cancelled.
@param [t:Promise] PromiseObject The promise you want to add to the janitor.
@returns [t:Promise]
**--]]
--[[
function Janitor.__index:AddPromise(PromiseObject)
if not Promise.is(PromiseObject) then
error(string.format(NOT_A_PROMISE, typeof(PromiseObject), tostring(PromiseObject)))
end

if PromiseObject:getStatus() == Promise.Status.Started then
local Id = newproxy(false)
local NewPromise = self:Add(Promise.resolve(PromiseObject), "cancel", Id)
NewPromise:finallyCall(self.Remove, self, Id)
return NewPromise, Id
else
return PromiseObject
end
end
--]]

--Janitor.__index.GivePromise = Janitor.__index.AddPromise

-- This will assume whether or not the object is a Promise or a regular object.
function Janitor.__index:AddObject(Object)
local Id = newproxy(false)
--[[
if Promise.is(Object) then
if Object:getStatus() == Promise.Status.Started then
local NewPromise = self:Add(Promise.resolve(Object), "cancel", Id)
NewPromise:finallyCall(self.Remove, self, Id)
return NewPromise, Id
else
return Object
end
else
return self:Add(Object, false, Id), Id
end---]]
return self:Add(Object, false, Id), Id
end

Janitor.__index.GiveObject = Janitor.__index.AddObject

--[[**
Cleans up whatever `Object` was set to this namespace by the 3rd parameter of `:Add()`.
@param [t:any] Index The index you want to remove.
@returns [t:Janitor] The same janitor, for chaining reasons.
**--]]
function Janitor.__index:Remove(Index)
local This = self[IndicesReference]

if This then
local Object = This[Index]

if Object then
local MethodName = self[Object]

if MethodName then
if MethodName == true then
Object()
else
local ObjectMethod = Object[MethodName]
if ObjectMethod then
ObjectMethod(Object)
end
end

self[Object] = nil
end

This[Index] = nil
end
end

return self
end

--[[**
Gets whatever object is stored with the given index, if it exists. This was added since Maid allows getting the job using `__index`.
@param [t:any] Index The index that the object is stored under.
@returns [t:any?] This will return the object if it is found, but it won't return anything if it doesn't exist.
**--]]
function Janitor.__index:Get(Index)
local This = self[IndicesReference]
if This then
return This[Index]
end
end

--[[**
Calls each Object's `MethodName` (or calls the Object if `MethodName == true`) and removes them from the Janitor. Also clears the namespace. This function is also called when you call a Janitor Object (so it can be used as a destructor callback).
@returns [t:void]
**--]]
function Janitor.__index:Cleanup()
if not self.CurrentlyCleaning then
self.CurrentlyCleaning = nil
for Object, MethodName in next, self do
if Object == IndicesReference then
continue
end

-- Weird decision to rawset directly to the janitor in Agent. This should protect against it though.
local TypeOf = type(Object)
if TypeOf == "string" or TypeOf == "number" then
self[Object] = nil
continue
end

if MethodName == true then
Object()
else
local ObjectMethod = Object[MethodName]
if ObjectMethod then
ObjectMethod(Object)
end
end

self[Object] = nil
end

local This = self[IndicesReference]
if This then
for Index in next, This do
This[Index] = nil
end

self[IndicesReference] = {}
end

self.CurrentlyCleaning = false
end
end

Janitor.__index.Clean = Janitor.__index.Cleanup

--[[**
Calls `:Cleanup()` and renders the Janitor unusable.
@returns [t:void]
**--]]
function Janitor.__index:Destroy()
self:Cleanup()
--table.clear(self)
--setmetatable(self, nil)
end

Janitor.__call = Janitor.__index.Cleanup

--- Makes the Janitor clean up when the instance is destroyed
-- @param Instance Instance The Instance the Janitor will wait for to be Destroyed
-- @returns Disconnectable table to stop Janitor from being cleaned up upon Instance Destroy (automatically cleaned up by Janitor, btw)
-- @author Corecii
local Disconnect = {Connected = true}
Disconnect.__index = Disconnect
function Disconnect:Disconnect()
if self.Connected then
self.Connected = false
self.Connection:Disconnect()
end
end

function Disconnect:__tostring()
return "Disconnect<" .. tostring(self.Connected) .. ">"
end

--[[**
"Links" this Janitor to an Instance, such that the Janitor will `Cleanup` when the Instance is `Destroyed()` and garbage collected. A Janitor may only be linked to one instance at a time, unless `AllowMultiple` is true. When called with a truthy `AllowMultiple` parameter, the Janitor will "link" the Instance without overwriting any previous links, and will also not be overwritable. When called with a falsy `AllowMultiple` parameter, the Janitor will overwrite the previous link which was also called with a falsy `AllowMultiple` parameter, if applicable.
@param [t:Instance] Object The instance you want to link the Janitor to.
@param [t:boolean?] AllowMultiple Whether or not to allow multiple links on the same Janitor.
@returns [t:RbxScriptConnection] A pseudo RBXScriptConnection that can be disconnected.
**--]]
function Janitor.__index:LinkToInstance(Object, AllowMultiple)
local Connection
local IndexToUse = AllowMultiple and newproxy(false) or LinkToInstanceIndex
local IsNilParented = Object.Parent == nil
local ManualDisconnect = setmetatable({}, Disconnect)

local function ChangedFunction(_DoNotUse, NewParent)
if ManualDisconnect.Connected then
_DoNotUse = nil
IsNilParented = NewParent == nil

if IsNilParented then
coroutine.wrap(function()
Heartbeat:Wait()
if not ManualDisconnect.Connected then
return
elseif not Connection.Connected then
self:Cleanup()
else
while IsNilParented and Connection.Connected and ManualDisconnect.Connected do
Heartbeat:Wait()
end

if ManualDisconnect.Connected and IsNilParented then
self:Cleanup()
end
end
end)()
end
end
end

Connection = Object.AncestryChanged:Connect(ChangedFunction)
ManualDisconnect.Connection = Connection

if IsNilParented then
ChangedFunction(nil, Object.Parent)
end

Object = nil
return self:Add(ManualDisconnect, "Disconnect", IndexToUse)
end

--[[**
Links several instances to a janitor, which is then returned.
@param [t:...Instance] ... All the instances you want linked.
@returns [t:Janitor] A janitor that can be used to manually disconnect all LinkToInstances.
**--]]
function Janitor.__index:LinkToInstances(...)
local ManualCleanup = Janitor.new()
for _, Object in ipairs({...}) do
ManualCleanup:Add(self:LinkToInstance(Object, true), "Disconnect")
end

return ManualCleanup
end

for FunctionName, Function in next, Janitor.__index do
local NewFunctionName = string.sub(string.lower(FunctionName), 1, 1) .. string.sub(FunctionName, 2)
Janitor.__index[NewFunctionName] = Function
end

return Janitor
modules/Zone/OldSignal.lua
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local heartbeat = RunService.Heartbeat
local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"
Signal.totalConnections = 0



-- CONSTRUCTOR
function Signal.new(createConnectionsChangedSignal)
local self = setmetatable({}, Signal)

if createConnectionsChangedSignal then
self.connectionsChanged = Signal.new()
end

self.connections = {}
self.totalConnections = 0
self.waiting = {}
self.totalWaiting = 0

return self
end



-- METHODS
function Signal:Fire(...)
for _, connection in pairs(self.connections) do
--connection.Handler(...)
task.spawn(connection.Handler, ...)
end
if self.totalWaiting > 0 then
local packedArgs = table.pack(...)
for waitingId, _ in pairs(self.waiting) do
self.waiting[waitingId] = packedArgs
end
end
end
Signal.fire = Signal.Fire

function Signal:Connect(handler)
if not (type(handler) == "function") then
error(("connect(%s)"):format(typeof(handler)), 2)
end

local signal = self
local connectionId = HttpService:GenerateGUID(false)
local connection = {}
connection.Connected = true
connection.ConnectionId = connectionId
connection.Handler = handler
self.connections[connectionId] = connection

function connection:Disconnect()
signal.connections[connectionId] = nil
connection.Connected = false
signal.totalConnections -= 1
if signal.connectionsChanged then
signal.connectionsChanged:Fire(-1)
end
end
connection.Destroy = connection.Disconnect
connection.destroy = connection.Disconnect
connection.disconnect = connection.Disconnect
self.totalConnections += 1
if self.connectionsChanged then
self.connectionsChanged:Fire(1)
end

return connection
end
Signal.connect = Signal.Connect

function Signal:Wait()
local waitingId = HttpService:GenerateGUID(false)
self.waiting[waitingId] = true
self.totalWaiting += 1
repeat heartbeat:Wait() until self.waiting[waitingId] ~= true
self.totalWaiting -= 1
local args = self.waiting[waitingId]
self.waiting[waitingId] = nil
return unpack(args)
end
Signal.wait = Signal.Wait

function Signal:Destroy()
if self.bindableEvent then
self.bindableEvent:Destroy()
self.bindableEvent = nil
end
if self.connectionsChanged then
self.connectionsChanged:Fire(-self.totalConnections)
self.connectionsChanged:Destroy()
self.connectionsChanged = nil
end
self.totalConnections = 0
for connectionId, connection in pairs(self.connections) do
self.connections[connectionId] = nil
end
end
Signal.destroy = Signal.Destroy
Signal.Disconnect = Signal.Destroy
Signal.disconnect = Signal.Destroy



return Signal
modules/Zone/Signal.lua
--------------------------------------------------------------------------------
-- Batched Yield-Safe Signal Implementation --
-- This is a Signal class which has effectively identical behavior to a --
-- normal RBXScriptSignal, with the only difference being a couple extra --
-- stack frames at the bottom of the stack trace when an error is thrown. --
-- This implementation caches runner coroutines, so the ability to yield in --
-- the signal handlers comes at minimal extra cost over a naive signal --
-- implementation that either always or never spawns a thread. --
-- --
-- API: --
-- local Signal = require(THIS MODULE) --
-- local sig = Signal.new() --
-- local connection = sig:Connect(function(arg1, arg2, ...) ... end) --
-- sig:Fire(arg1, arg2, ...) --
-- connection:Disconnect() --
-- sig:DisconnectAll() --
-- local arg1, arg2, ... = sig:Wait() --
-- --
-- Licence: --
-- Licenced under the MIT licence. --
-- --
-- Authors: --
-- stravant - July 31st, 2021 - Created the file. --
--------------------------------------------------------------------------------

-- The currently idle thread to run the next handler on
local freeRunnerThread = nil

-- Function which acquires the currently idle handler runner thread, runs the
-- function fn on it, and then releases the thread, returning it to being the
-- currently idle one.
-- If there was a currently idle runner thread already, that's okay, that old
-- one will just get thrown and eventually GCed.
local function acquireRunnerThreadAndCallEventHandler(fn, ...)
local acquiredRunnerThread = freeRunnerThread
freeRunnerThread = nil
fn(...)
-- The handler finished running, this runner thread is free again.
freeRunnerThread = acquiredRunnerThread
end

-- Coroutine runner that we create coroutines of. The coroutine can be
-- repeatedly resumed with functions to run followed by the argument to run
-- them with.
local function runEventHandlerInFreeThread(...)
acquireRunnerThreadAndCallEventHandler(...)
while true do
acquireRunnerThreadAndCallEventHandler(coroutine.yield())
end
end

-- Connection class
local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
return setmetatable({
_connected = true,
_signal = signal,
_fn = fn,
_next = false,
}, Connection)
end

function Connection:Disconnect()
assert(self._connected, "Can't disconnect a connection twice.", 2)
self._connected = false

-- Unhook the node, but DON'T clear it. That way any fire calls that are
-- currently sitting on this node will be able to iterate forwards off of
-- it, but any subsequent fire calls will not hit it, and it will be GCed
-- when no more fire calls are sitting on it.
local signal = self._signal
if signal._handlerListHead == self then
signal._handlerListHead = self._next
else
local prev = signal._handlerListHead
while prev and prev._next ~= self do
prev = prev._next
end
if prev then
prev._next = self._next
end
end

if signal.connectionsChanged then
signal.totalConnections -= 1
signal.connectionsChanged:Fire(-1)
end
end

-- Make Connection strict
setmetatable(Connection, {
__index = function(tb, key)
error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
end,
__newindex = function(tb, key, value)
error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
end
})

-- Signal class
local Signal = {}
Signal.__index = Signal

function Signal.new(createConnectionsChangedSignal)
local self = setmetatable({
_handlerListHead = false,
}, Signal)
if createConnectionsChangedSignal then
self.totalConnections = 0
self.connectionsChanged = Signal.new()
end
return self
end

function Signal:Connect(fn)
local connection = Connection.new(self, fn)
if self._handlerListHead then
connection._next = self._handlerListHead
self._handlerListHead = connection
else
self._handlerListHead = connection
end

if self.connectionsChanged then
self.totalConnections += 1
self.connectionsChanged:Fire(1)
end
return connection
end

-- Disconnect all handlers. Since we use a linked list it suffices to clear the
-- reference to the head handler.
function Signal:DisconnectAll()
self._handlerListHead = false

if self.connectionsChanged then
self.connectionsChanged:Fire(-self.totalConnections)
self.connectionsChanged:Destroy()
self.connectionsChanged = nil
self.totalConnections = 0
end
end
Signal.Destroy = Signal.DisconnectAll
Signal.destroy = Signal.DisconnectAll

-- Signal:Fire(...) implemented by running the handler functions on the
-- coRunnerThread, and any time the resulting thread yielded without returning
-- to us, that means that it yielded to the Roblox scheduler and has been taken
-- over by Roblox scheduling, meaning we have to make a new coroutine runner.
function Signal:Fire(...)
local item = self._handlerListHead
while item do
if item._connected then
if not freeRunnerThread then
freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
end
task.spawn(freeRunnerThread, item._fn, ...)
end
item = item._next
end
end

-- Implement Signal:Wait() in terms of a temporary connection using
-- a Signal:Connect() which disconnects itself.
function Signal:Wait()
local waitingCoroutine = coroutine.running()
local cn;
cn = self:Connect(function(...)
cn:Disconnect()
task.spawn(waitingCoroutine, ...)
end)
return coroutine.yield()
end


return Signal
modules/Zone/VERSION.lua
-- v3.2.0
modules/Zone/ZonePlusReference.lua
-- This module enables you to place Zone wherever you like within the data model while
-- still enabling third-party applications (such as HDAdmin/Nanoblox) to locate it
-- This is necessary to prevent two ZonePlus applications initiating at runtime which would
-- diminish it's overall efficiency

local replicatedStorage = game:GetService("ReplicatedStorage")
local ZonePlusReference = {}

function ZonePlusReference.addToReplicatedStorage()
local existingItem = replicatedStorage:FindFirstChild(script.Name)
if existingItem then
return false
end
local objectValue = Instance.new("ObjectValue")
objectValue.Name = script.Name
objectValue.Value = script.Parent
objectValue.Parent = replicatedStorage
local locationValue = Instance.new("BoolValue")
locationValue.Name = (game:GetService("RunService"):IsClient() and "Client") or "Server"
locationValue.Value = true
locationValue.Parent = objectValue
return objectValue
end

function ZonePlusReference.getObject()
local objectValue = replicatedStorage:FindFirstChild(script.Name)
if objectValue then
return objectValue
end
return false
end

return ZonePlusReference
modules/Zone/init.lua
-- LOCAL
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local heartbeat = runService.Heartbeat
local localPlayer = runService:IsClient() and players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")
local Enum_ = require(script.Enum)
local enum = Enum_.enums
local Janitor = require(script.Janitor)
local Signal = require(script.Signal)
local ZonePlusReference = require(script.ZonePlusReference)
local referenceObject = ZonePlusReference.getObject()
local zoneControllerModule = script.ZoneController
local trackerModule = zoneControllerModule.Tracker
local collectiveWorldModelModule = zoneControllerModule.CollectiveWorldModel
local ZoneController = require(zoneControllerModule)
local referenceLocation = (game:GetService("RunService"):IsClient() and "Client") or "Server"
local referencePresent = referenceObject and referenceObject:FindFirstChild(referenceLocation)
if referencePresent then
return require(referenceObject.Value)
end

local Zone = {}
Zone.__index = Zone
if not referencePresent then
ZonePlusReference.addToReplicatedStorage()
end
Zone.enum = enum



-- CONSTRUCTORS
function Zone.new(container)
local self = {}
setmetatable(self, Zone)

-- Validate container
local INVALID_TYPE_WARNING = "The zone container must be a model, folder, basepart or table!"
local containerType = typeof(container)
if not(containerType == "table" or containerType == "Instance") then
error(INVALID_TYPE_WARNING)
end

-- Configurable
self.accuracy = enum.Accuracy.High
self.autoUpdate = true
self.respectUpdateQueue = true
--self.maxPartsAddition = 20
--self.ignoreRecommendedMaxParts = false

-- Variable
local janitor = Janitor.new()
self.janitor = janitor
self._updateConnections = janitor:add(Janitor.new(), "destroy")
self.container = container
self.zoneParts = {}
self.overlapParams = {}
self.region = nil
self.volume = nil
self.boundMin = nil
self.boundMax = nil
self.recommendedMaxParts = nil
self.zoneId = httpService:GenerateGUID()
self.activeTriggers = {}
self.occupants = {}
self.trackingTouchedTriggers = {}
self.enterDetection = enum.Detection.Centre
self.exitDetection = enum.Detection.Centre
self._currentEnterDetection = nil -- This will update automatically internally
self._currentExitDetection = nil -- This will also update automatically internally
self.totalPartVolume = 0
self.allZonePartsAreBlocks = true
self.trackedItems = {}
self.settingsGroupName = nil
self.worldModel = workspace
self.onItemDetails = {}
self.itemsToUntrack = {}

-- This updates _currentEnterDetection and _currentExitDetection right away to prevent nil comparisons
ZoneController.updateDetection(self)

-- Signals
self.updated = janitor:add(Signal.new(), "destroy")
local triggerTypes = {
"player",
"part",
"localPlayer",
"item"
}
local triggerEvents = {
"entered",
"exited",
}
for _, triggerType in pairs(triggerTypes) do
local activeConnections = 0
local previousActiveConnections = 0
for i, triggerEvent in pairs(triggerEvents) do
-- this enables us to determine when a developer connects to an event
-- so that we can act accoridngly (i.e. begin or end a checker loop)
local signal = janitor:add(Signal.new(true), "destroy")
local triggerEventUpper = triggerEvent:sub(1,1):upper()..triggerEvent:sub(2)
local signalName = triggerType..triggerEventUpper
self[signalName] = signal
signal.connectionsChanged:Connect(function(increment)
if triggerType == "localPlayer" and not localPlayer and increment == 1 then
error(("Can only connect to 'localPlayer%s' on the client!"):format(triggerEventUpper))
end
previousActiveConnections = activeConnections
activeConnections += increment
if previousActiveConnections == 0 and activeConnections > 0 then
-- At least 1 connection active, begin loop
ZoneController._registerConnection(self, triggerType, triggerEventUpper)
elseif previousActiveConnections > 0 and activeConnections == 0 then
-- All connections have disconnected, end loop
ZoneController._deregisterConnection(self, triggerType)
end
end)
end
end

-- Setup touched receiver functions where applicable
Zone.touchedConnectionActions = {}
for _, triggerType in pairs(triggerTypes) do
local methodName = ("_%sTouchedZone"):format(triggerType)
local correspondingMethod = self[methodName]
if correspondingMethod then
self.trackingTouchedTriggers[triggerType] = {}
Zone.touchedConnectionActions[triggerType] = function(touchedItem)
correspondingMethod(self, touchedItem)
end
end
end

-- This constructs the zones boundaries, region, etc
self:_update()

-- Register/deregister zone
ZoneController._registerZone(self)
janitor:add(function()
ZoneController._deregisterZone(self)
end, true)

return self
end

function Zone.fromRegion(cframe, size)
local MAX_PART_SIZE = 2024
local container = Instance.new("Model")
local function createCube(cubeCFrame, cubeSize)
if cubeSize.X > MAX_PART_SIZE or cubeSize.Y > MAX_PART_SIZE or cubeSize.Z > MAX_PART_SIZE then
local quarterSize = cubeSize * 0.25
local halfSize = cubeSize * 0.5
createCube(cubeCFrame * CFrame.new(-quarterSize.X, -quarterSize.Y, -quarterSize.Z), halfSize)
createCube(cubeCFrame * CFrame.new(-quarterSize.X, -quarterSize.Y, quarterSize.Z), halfSize)
createCube(cubeCFrame * CFrame.new(-quarterSize.X, quarterSize.Y, -quarterSize.Z), halfSize)
createCube(cubeCFrame * CFrame.new(-quarterSize.X, quarterSize.Y, quarterSize.Z), halfSize)
createCube(cubeCFrame * CFrame.new(quarterSize.X, -quarterSize.Y, -quarterSize.Z), halfSize)
createCube(cubeCFrame * CFrame.new(quarterSize.X, -quarterSize.Y, quarterSize.Z), halfSize)
createCube(cubeCFrame * CFrame.new(quarterSize.X, quarterSize.Y, -quarterSize.Z), halfSize)
createCube(cubeCFrame * CFrame.new(quarterSize.X, quarterSize.Y, quarterSize.Z), halfSize)
else
local part = Instance.new("Part")
part.CFrame = cubeCFrame
part.Size = cubeSize
part.Anchored = true
part.Parent = container
end
end
createCube(cframe, size)
local zone = Zone.new(container)
zone:relocate()
return zone
end



-- PRIVATE METHODS
function Zone:_calculateRegion(tableOfParts, dontRound)
local bounds = {["Min"] = {}, ["Max"] = {}}
for boundType, details in pairs(bounds) do
details.Values = {}
function details.parseCheck(v, currentValue)
if boundType == "Min" then
return (v <= currentValue)
elseif boundType == "Max" then
return (v >= currentValue)
end
end
function details:parse(valuesToParse)
for i,v in pairs(valuesToParse) do
local currentValue = self.Values[i] or v
if self.parseCheck(v, currentValue) then
self.Values[i] = v
end
end
end
end
for _, part in pairs(tableOfParts) do
local sizeHalf = part.Size * 0.5
local corners = {
part.CFrame * CFrame.new(-sizeHalf.X, -sizeHalf.Y, -sizeHalf.Z),
part.CFrame * CFrame.new(-sizeHalf.X, -sizeHalf.Y, sizeHalf.Z),
part.CFrame * CFrame.new(-sizeHalf.X, sizeHalf.Y, -sizeHalf.Z),
part.CFrame * CFrame.new(-sizeHalf.X, sizeHalf.Y, sizeHalf.Z),
part.CFrame * CFrame.new(sizeHalf.X, -sizeHalf.Y, -sizeHalf.Z),
part.CFrame * CFrame.new(sizeHalf.X, -sizeHalf.Y, sizeHalf.Z),
part.CFrame * CFrame.new(sizeHalf.X, sizeHalf.Y, -sizeHalf.Z),
part.CFrame * CFrame.new(sizeHalf.X, sizeHalf.Y, sizeHalf.Z),
}
for _, cornerCFrame in pairs(corners) do
local x, y, z = cornerCFrame:GetComponents()
local values = {x, y, z}
bounds.Min:parse(values)
bounds.Max:parse(values)
end
end
local minBound = {}
local maxBound = {}
-- Rounding a regions coordinates to multiples of 4 ensures the region optimises the region
-- by ensuring it aligns on the voxel grid
local function roundToFour(to_round)
local ROUND_TO = 4
local divided = (to_round+ROUND_TO/2) / ROUND_TO
local rounded = ROUND_TO * math.floor(divided)
return rounded
end
for boundName, boundDetail in pairs(bounds) do
for _, v in pairs(boundDetail.Values) do
local newTable = (boundName == "Min" and minBound) or maxBound
local newV = v
if not dontRound then
local roundOffset = (boundName == "Min" and -2) or 2
newV = roundToFour(v+roundOffset) -- +-2 to ensures the zones region is not rounded down/up
end
table.insert(newTable, newV)
end
end
local boundMin = Vector3.new(unpack(minBound))
local boundMax = Vector3.new(unpack(maxBound))
local region = Region3.new(boundMin, boundMax)
return region, boundMin, boundMax
end

function Zone:_displayBounds()
if not self.displayBoundParts then
self.displayBoundParts = true
local boundParts = {BoundMin = self.boundMin, BoundMax = self.boundMax}
for boundName, boundCFrame in pairs(boundParts) do
local part = Instance.new("Part")
part.Anchored = true
part.CanCollide = false
part.Transparency = 0.5
part.Size = Vector3.new(1,1,1)
part.Color = Color3.fromRGB(255,0,0)
part.CFrame = CFrame.new(boundCFrame)
part.Name = boundName
part.Parent = workspace
self.janitor:add(part, "Destroy")
end
end
end

function Zone:_update()
local container = self.container
local zoneParts = {}
local updateQueue = 0
self._updateConnections:clean()

local containerType = typeof(container)
local holders = {}
local INVALID_TYPE_WARNING = "The zone container must be a model, folder, basepart or table!"
if containerType == "table" then
for _, part in pairs(container) do
if part:IsA("BasePart") then
table.insert(zoneParts, part)
end
end
elseif containerType == "Instance" then
if container:IsA("BasePart") then
table.insert(zoneParts, container)
else
table.insert(holders, container)
for _, part in pairs(container:GetDescendants()) do
if part:IsA("BasePart") then
table.insert(zoneParts, part)
else
table.insert(holders, part)
end
end
end
end
self.zoneParts = zoneParts
self.overlapParams = {}

local allZonePartsAreBlocksNew = true
for _, zonePart in pairs(zoneParts) do
local success, shapeName = pcall(function() return zonePart.Shape.Name end)
if shapeName ~= "Block" then
allZonePartsAreBlocksNew = false
end
end
self.allZonePartsAreBlocks = allZonePartsAreBlocksNew

local zonePartsWhitelist = OverlapParams.new()
zonePartsWhitelist.FilterType = Enum.RaycastFilterType.Whitelist
zonePartsWhitelist.MaxParts = #zoneParts
zonePartsWhitelist.FilterDescendantsInstances = zoneParts
self.overlapParams.zonePartsWhitelist = zonePartsWhitelist

local zonePartsIgnorelist = OverlapParams.new()
zonePartsIgnorelist.FilterType = Enum.RaycastFilterType.Blacklist
zonePartsIgnorelist.FilterDescendantsInstances = zoneParts
self.overlapParams.zonePartsIgnorelist = zonePartsIgnorelist

-- this will call update on the zone when the container parts size or position changes, and when a
-- child is removed or added from a holder (anything which isn't a basepart)
local function update()
if self.autoUpdate then
local executeTime = os.clock()
if self.respectUpdateQueue then
updateQueue += 1
executeTime += 0.1
end
local updateConnection
updateConnection = runService.Heartbeat:Connect(function()
if os.clock() >= executeTime then
updateConnection:Disconnect()
if self.respectUpdateQueue then
updateQueue -= 1
end
if updateQueue == 0 and self.zoneId then
self:_update()
end
end
end)
end
end
local partProperties = {"Size", "Position"}
local function verifyDefaultCollision(instance)
if instance.CollisionGroupId ~= 0 then
error("Zone parts must belong to the 'Default' (0) CollisionGroup! Consider using zone:relocate() if you wish to move zones outside of workspace to prevent them interacting with other parts.")
end
end
for _, part in pairs(zoneParts) do
for _, prop in pairs(partProperties) do
self._updateConnections:add(part:GetPropertyChangedSignal(prop):Connect(update), "Disconnect")
end
verifyDefaultCollision(part)
self._updateConnections:add(part:GetPropertyChangedSignal("CollisionGroupId"):Connect(function()
verifyDefaultCollision(part)
end), "Disconnect")
end
local containerEvents = {"ChildAdded", "ChildRemoved"}
for _, holder in pairs(holders) do
for _, event in pairs(containerEvents) do
self._updateConnections:add(self.container[event]:Connect(function(child)
if child:IsA("BasePart") then
update()
end
end), "Disconnect")
end
end

local region, boundMin, boundMax = self:_calculateRegion(zoneParts)
local exactRegion, _, _ = self:_calculateRegion(zoneParts, true)
self.region = region
self.exactRegion = exactRegion
self.boundMin = boundMin
self.boundMax = boundMax
local rSize = region.Size
self.volume = rSize.X*rSize.Y*rSize.Z

-- Update: I was going to use this for the old part detection until the CanTouch property was released
-- everything below is now irrelevant however I'll keep just in case I use again for future
-------------------------------------------------------------------------------------------------
-- When a zones region is determined, we also check for parts already existing within the zone
-- these parts are likely never to move or interact with the zone, so we set the number of these
-- to the baseline MaxParts value. 'recommendMaxParts' is then determined through the sum of this
-- and maxPartsAddition. This ultimately optimises region checks as they can be generated with
-- minimal MaxParts (i.e. recommendedMaxParts can be used instead of math.huge every time)
--[[
local result = self.worldModel:FindPartsInRegion3(region, nil, math.huge)
local maxPartsBaseline = #result
self.recommendedMaxParts = maxPartsBaseline + self.maxPartsAddition
--]]

self:_updateTouchedConnections()

self.updated:Fire()
end

function Zone:_updateOccupants(trackerName, newOccupants)
local previousOccupants = self.occupants[trackerName]
if not previousOccupants then
previousOccupants = {}
self.occupants[trackerName] = previousOccupants
end
local signalsToFire = {}
for occupant, prevItem in pairs(previousOccupants) do
local newItem = newOccupants[occupant]
if newItem == nil or newItem ~= prevItem then
previousOccupants[occupant] = nil
if not signalsToFire.exited then
signalsToFire.exited = {}
end
table.insert(signalsToFire.exited, occupant)
end
end
for occupant, _ in pairs(newOccupants) do
if previousOccupants[occupant] == nil then
local isAPlayer = occupant:IsA("Player")
previousOccupants[occupant] = (isAPlayer and occupant.Character) or true
if not signalsToFire.entered then
signalsToFire.entered = {}
end
table.insert(signalsToFire.entered, occupant)
end
end
return signalsToFire
end

function Zone:_formTouchedConnection(triggerType)
local touchedJanitorName = "_touchedJanitor"..triggerType
local touchedJanitor = self[touchedJanitorName]
if touchedJanitor then
touchedJanitor:clean()
else
touchedJanitor = self.janitor:add(Janitor.new(), "destroy")
self[touchedJanitorName] = touchedJanitor
end
self:_updateTouchedConnection(triggerType)
end

function Zone:_updateTouchedConnection(triggerType)
local touchedJanitorName = "_touchedJanitor"..triggerType
local touchedJanitor = self[touchedJanitorName]
if not touchedJanitor then return end
for _, basePart in pairs(self.zoneParts) do
touchedJanitor:add(basePart.Touched:Connect(self.touchedConnectionActions[triggerType], self), "Disconnect")
end
end

function Zone:_updateTouchedConnections()
for triggerType, _ in pairs(self.touchedConnectionActions) do
local touchedJanitorName = "_touchedJanitor"..triggerType
local touchedJanitor = self[touchedJanitorName]
if touchedJanitor then
touchedJanitor:cleanup()
self:_updateTouchedConnection(triggerType)
end
end
end

function Zone:_disconnectTouchedConnection(triggerType)
local touchedJanitorName = "_touchedJanitor"..triggerType
local touchedJanitor = self[touchedJanitorName]
if touchedJanitor then
touchedJanitor:cleanup()
self[touchedJanitorName] = nil
end
end

local function round(number, decimalPlaces)
return math.round(number * 10^decimalPlaces) * 10^-decimalPlaces
end
function Zone:_partTouchedZone(part)
local trackingDict = self.trackingTouchedTriggers["part"]
if trackingDict[part] then return end
local nextCheck = 0
local verifiedEntrance = false
local enterPosition = part.Position
local enterTime = os.clock()
local partJanitor = self.janitor:add(Janitor.new(), "destroy")
trackingDict[part] = partJanitor
local instanceClassesToIgnore = {Seat = true, VehicleSeat = true}
local instanceNamesToIgnore = {HumanoidRootPart = true}
if not (instanceClassesToIgnore[part.ClassName] or not instanceNamesToIgnore[part.Name]) then
part.CanTouch = false
end
--
local partVolume = round((part.Size.X * part.Size.Y * part.Size.Z), 5)
self.totalPartVolume += partVolume
--
partJanitor:add(heartbeat:Connect(function()
local clockTime = os.clock()
if clockTime >= nextCheck then
----
local cooldown = enum.Accuracy.getProperty(self.accuracy)
nextCheck = clockTime + cooldown
----

-- We initially perform a singular point check as this is vastly more lightweight than a large part check
-- If the former returns false, perform a whole part check in case the part is on the outer bounds.
local withinZone = self:findPoint(part.CFrame)
if not withinZone then
withinZone = self:findPart(part)
end
if not verifiedEntrance then
if withinZone then
verifiedEntrance = true
self.partEntered:Fire(part)
elseif (part.Position - enterPosition).Magnitude > 1.5 and clockTime - enterTime >= cooldown then
-- Even after the part has exited the zone, we track it for a brief period of time based upon the criteria
-- in the line above to ensure the .touched behaviours are not abused
partJanitor:cleanup()
end
elseif not withinZone then
verifiedEntrance = false
enterPosition = part.Position
enterTime = os.clock()
self.partExited:Fire(part)
end
end
end), "Disconnect")
partJanitor:add(function()
trackingDict[part] = nil
part.CanTouch = true
self.totalPartVolume = round((self.totalPartVolume - partVolume), 5)
end, true)
end

local partShapeActions = {
["Ball"] = function(part)
return "GetPartBoundsInRadius", {part.Position, part.Size.X}
end,
["Block"] = function(part)
return "GetPartBoundsInBox", {part.CFrame, part.Size}
end,
["Other"] = function(part)
return "GetPartsInPart", {part}
end,
}
function Zone:_getRegionConstructor(part, overlapParams)
local success, shapeName = pcall(function() return part.Shape.Name end)
local methodName, args
if success and self.allZonePartsAreBlocks then
local action = partShapeActions[shapeName]
if action then
methodName, args = action(part)
end
end
if not methodName then
methodName, args = partShapeActions.Other(part)
end
if overlapParams then
table.insert(args, overlapParams)
end
return methodName, args
end



-- PUBLIC METHODS
function Zone:findLocalPlayer()
if not localPlayer then
error("Can only call 'findLocalPlayer' on the client!")
end
return self:findPlayer(localPlayer)
end

function Zone:_find(trackerName, item)
ZoneController.updateDetection(self)
local tracker = ZoneController.trackers[trackerName]
local touchingZones = ZoneController.getTouchingZones(item, false, self._currentEnterDetection, tracker)
for _, zone in pairs(touchingZones) do
if zone == self then
return true
end
end
return false
end

function Zone:findPlayer(player)
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
if not humanoid then
return false
end
return self:_find("player", player.Character)
end

function Zone:findItem(item)
return self:_find("item", item)
end

function Zone:findPart(part)
local methodName, args = self:_getRegionConstructor(part, self.overlapParams.zonePartsWhitelist)
local touchingZoneParts = self.worldModel[methodName](self.worldModel, unpack(args))
--local touchingZoneParts = self.worldModel:GetPartsInPart(part, self.overlapParams.zonePartsWhitelist)
if #touchingZoneParts > 0 then
return true, touchingZoneParts
end
return false
end

function Zone:getCheckerPart()
local checkerPart = self.checkerPart
if not checkerPart then
checkerPart = self.janitor:add(Instance.new("Part"), "Destroy")
checkerPart.Size = Vector3.new(0.1, 0.1, 0.1)
checkerPart.Name = "ZonePlusCheckerPart"
checkerPart.Anchored = true
checkerPart.Transparency = 1
checkerPart.CanCollide = false
self.checkerPart = checkerPart
end
local checkerParent = self.worldModel
if checkerParent == workspace then
checkerParent = ZoneController.getWorkspaceContainer()
end
if checkerPart.Parent ~= checkerParent then
checkerPart.Parent = checkerParent
end
return checkerPart
end

function Zone:findPoint(positionOrCFrame)
local cframe = positionOrCFrame
if typeof(positionOrCFrame) == "Vector3" then
cframe = CFrame.new(positionOrCFrame)
end
local checkerPart = self:getCheckerPart()
checkerPart.CFrame = cframe
--checkerPart.Parent = self.worldModel
local methodName, args = self:_getRegionConstructor(checkerPart, self.overlapParams.zonePartsWhitelist)
local touchingZoneParts = self.worldModel[methodName](self.worldModel, unpack(args))
--local touchingZoneParts = self.worldModel:GetPartsInPart(self.checkerPart, self.overlapParams.zonePartsWhitelist)
if #touchingZoneParts > 0 then
return true, touchingZoneParts
end
return false
end

function Zone:_getAll(trackerName)
ZoneController.updateDetection(self)
local itemsArray = {}
local zonesAndOccupants = ZoneController._getZonesAndItems(trackerName, {self = true}, self.volume, false, self._currentEnterDetection)
local occupantsDict = zonesAndOccupants[self]
if occupantsDict then
for item, _ in pairs(occupantsDict) do
table.insert(itemsArray, item)
end
end
return itemsArray
end

function Zone:getPlayers()
return self:_getAll("player")
end

function Zone:getItems()
return self:_getAll("item")
end

function Zone:getParts()
-- This is designed for infrequent 'one off' use
-- If you plan on checking for parts within a zone frequently, it's recommended you
-- use the .partEntered and .partExited events instead.
local partsArray = {}
if self.activeTriggers["part"] then
local trackingDict = self.trackingTouchedTriggers["part"]
for part, _ in pairs(trackingDict) do
table.insert(partsArray, part)
end
return partsArray
end
local partsInRegion = self.worldModel:GetPartBoundsInBox(self.region.CFrame, self.region.Size, self.overlapParams.zonePartsIgnorelist)
for _, part in pairs(partsInRegion) do
if self:findPart(part) then
table.insert(partsArray, part)
end
end
return partsArray
end

function Zone:getRandomPoint()
local region = self.exactRegion
local size = region.Size
local cframe = region.CFrame
local random = Random.new()
local randomCFrame
local success, touchingZoneParts
local pointIsWithinZone
repeat
randomCFrame = cframe * CFrame.new(random:NextNumber(-size.X/2,size.X/2), random:NextNumber(-size.Y/2,size.Y/2), random:NextNumber(-size.Z/2,size.Z/2))
success, touchingZoneParts = self:findPoint(randomCFrame)
if success then
pointIsWithinZone = true
end
until pointIsWithinZone
local randomVector = randomCFrame.Position
return randomVector, touchingZoneParts
end

function Zone:setAccuracy(enumIdOrName)
local enumId = tonumber(enumIdOrName)
if not enumId then
enumId = enum.Accuracy[enumIdOrName]
if not enumId then
error(("'%s' is an invalid enumName!"):format(enumIdOrName))
end
else
local enumName = enum.Accuracy.getName(enumId)
if not enumName then
error(("%s is an invalid enumId!"):format(enumId))
end
end
self.accuracy = enumId
end

function Zone:setDetection(enumIdOrName)
local enumId = tonumber(enumIdOrName)
if not enumId then
enumId = enum.Detection[enumIdOrName]
if not enumId then
error(("'%s' is an invalid enumName!"):format(enumIdOrName))
end
else
local enumName = enum.Detection.getName(enumId)
if not enumName then
error(("%s is an invalid enumId!"):format(enumId))
end
end
self.enterDetection = enumId
self.exitDetection = enumId
end

function Zone:trackItem(instance)
local isBasePart = instance:IsA("BasePart")
local isCharacter = false
if not isBasePart then
isCharacter = instance:FindFirstChildOfClass("Humanoid") and instance:FindFirstChild("HumanoidRootPart")
end

assert(isBasePart or isCharacter, "Only BaseParts or Characters/NPCs can be tracked!")

if self.trackedItems[instance] then
return
end
if self.itemsToUntrack[instance] then
self.itemsToUntrack[instance] = nil
end

local itemJanitor = self.janitor:add(Janitor.new(), "destroy")
local itemDetail = {
janitor = itemJanitor,
item = instance,
isBasePart = isBasePart,
isCharacter = isCharacter,
}
self.trackedItems[instance] = itemDetail

itemJanitor:add(instance.AncestryChanged:Connect(function()
if not instance:IsDescendantOf(game) then
self:untrackItem(instance)
end
end), "Disconnect")

local Tracker = require(trackerModule)
Tracker.itemAdded:Fire(itemDetail)
end

function Zone:untrackItem(instance)
local itemDetail = self.trackedItems[instance]
if itemDetail then
itemDetail.janitor:destroy()
end
self.trackedItems[instance] = nil

local Tracker = require(trackerModule)
Tracker.itemRemoved:Fire(itemDetail)
end

function Zone:bindToGroup(settingsGroupName)
self:unbindFromGroup()
local group = ZoneController.getGroup(settingsGroupName) or ZoneController.setGroup(settingsGroupName)
group._memberZones[self.zoneId] = self
self.settingsGroupName = settingsGroupName
end

function Zone:unbindFromGroup()
if self.settingsGroupName then
local group = ZoneController.getGroup(self.settingsGroupName)
if group then
group._memberZones[self.zoneId] = nil
end
self.settingsGroupName = nil
end
end

function Zone:relocate()
if self.hasRelocated then
return
end

local CollectiveWorldModel = require(collectiveWorldModelModule)
local worldModel = CollectiveWorldModel.setupWorldModel(self)
self.worldModel = worldModel
self.hasRelocated = true

local relocationContainer = self.container
if typeof(relocationContainer) == "table" then
relocationContainer = Instance.new("Folder")
for _, zonePart in pairs(self.zoneParts) do
zonePart.Parent = relocationContainer
end
end
self.relocationContainer = self.janitor:add(relocationContainer, "Destroy", "RelocationContainer")
relocationContainer.Parent = worldModel
end

function Zone:_onItemCallback(eventName, desiredValue, instance, callbackFunction)
local detail = self.onItemDetails[instance]
if not detail then
detail = {}
self.onItemDetails[instance] = detail
end
if #detail == 0 then
self.itemsToUntrack[instance] = true
end
table.insert(detail, instance)
self:trackItem(instance)

local function triggerCallback()
callbackFunction()
if self.itemsToUntrack[instance] then
self.itemsToUntrack[instance] = nil
self:untrackItem(instance)
end
end

local inZoneAlready = self:findItem(instance)
if inZoneAlready == desiredValue then
triggerCallback()
else
local connection
connection = self[eventName]:Connect(function(item)
if connection and item == instance then
connection:Disconnect()
connection = nil
triggerCallback()
end
end)
--[[
if typeof(expireAfterSeconds) == "number" then
task.delay(expireAfterSeconds, function()
if connection ~= nil then
print("EXPIRE!")
connection:Disconnect()
connection = nil
triggerCallback()
end
end)
end
--]]
end
end

function Zone:onItemEnter(...)
self:_onItemCallback("itemEntered", true, ...)
end

function Zone:onItemExit(...)
self:_onItemCallback("itemExited", false, ...)
end

function Zone:destroy()
self:unbindFromGroup()
self.janitor:destroy()
end
Zone.Destroy = Zone.destroy



return Zone
modules/Abbreviate.lua
local ABBREVIATIONS = {
Dvg = 10^69,
Uvg = 10^66,
Vg = 10^63,
Nod = 10^60,
Ocd = 10^57,
Spd = 10^54,
Sxd = 10^51,
Qid = 10^48,
Qad = 10^45,
Td = 10^42,
Dd = 10^39,
Ud = 10^36,
Dc = 10^33,
No = 10^30,
Oc = 10^27,
Sp = 10^24,
Sx = 10^21,
Qn = 10^18,
Qd = 10^15,
T = 10^12,
B = 10^9,
M = 10^6,
K = 10^3
}
local DECIMAL = 100

return function(number)
if type(number) ~= "number"
or number < 100000 then
return number
end

local abbreviatedNum = number
local abbreviationChosen = 0

for abbreviation, num in pairs(ABBREVIATIONS) do
if number >= num and num > abbreviationChosen then
local shortNum = number / num
local intNum = math.floor(shortNum*DECIMAL)/DECIMAL

abbreviatedNum = tostring(intNum) .. abbreviation
abbreviationChosen = num
end
end

return abbreviatedNum
end
modules/AnimationManager.lua
local ContentProvider = game:GetService("ContentProvider")


local function SetRecursive(tbl, call)
local newTbl = {}
for i, v in pairs(tbl) do
if type(v) == "table" then
newTbl[i] = SetRecursive(v, call)
continue
end
newTbl[i] = call(v)
end

return newTbl
end

local function SetRecursiveFolder(folder, call)
local newTbl = {}
for _, v in pairs(folder:GetChildren()) do
if v:IsA("Folder") then
newTbl[v.Name] = SetRecursiveFolder(v, call)
continue
end
newTbl[v.Name] = call(v)
end

return newTbl
end

local function LoadAnimations(animator: Animator, animations)
if type(animations) == "table" then

return SetRecursive(animations, function(animId)
local animObject = Instance.new("Animation")
animObject.AnimationId = "rbxassetid://" .. animId
task.spawn(function()
ContentProvider:PreloadAsync({animObject})
end)
return animator:LoadAnimation(animObject)
end)
elseif typeof(animations) == "Instance" and animations:IsA("Folder") then

return SetRecursiveFolder(animations, function(animObject)
task.spawn(function()
ContentProvider:PreloadAsync({animObject})
end)

return animator:LoadAnimation(animObject)
end)
else
return warn("[Animation Manager] Did not provide a folder or table!")
end
end


local AnimationManager = {}
AnimationManager.__index = AnimationManager

function AnimationManager.new(character, animations)
local self = setmetatable({}, AnimationManager)
self.character = character

local animatorParent
local start = time()
while animatorParent == nil do
if time() - start > 50 then
return warn("[AnimationManager] Humanoid doesn't exist for character: " .. character.Name)
end
animatorParent = character:FindFirstChild("Humanoid") or character:FindFirstChild("AnimationController")
if animatorParent == nil then
task.wait()
end
end
self.animator = animatorParent:WaitForChild("Animator")

self.animations = LoadAnimations(self.animator, animations)

return self
end

function AnimationManager:StopAll(ignoreList: {string}?)
SetRecursive(self.animations, function(animObject)
if ignoreList and table.find(ignoreList, animObject.Name) then
return
end
animObject:Stop()
end)
end

function AnimationManager:SetNewAnimation(animName: string, animObject)
task.spawn(function()
ContentProvider:PreloadAsync({animObject})
end)

self.animations[animName] = self.animator:LoadAnimation(animObject)
end

function AnimationManager:FindAnimation(animationToFind: string) -- Recursive
for _, subsection: {AnimationTrack} in pairs(self.animations) do
if type(subsection) ~= "table" then continue end
for name, animationTrack in pairs(subsection) do
if name == animationToFind then
return animationTrack
end
end
end
end

function AnimationManager:Destroy()
SetRecursive(self.animations, function(animObject)
animObject:Stop()
animObject:Destroy()
end)
self.animations = nil
end

return AnimationManager
modules/AnimationTrack.lua
local DEFAULT_FADE_TIME = 0.100000001


local AnimationTrack = {}
AnimationTrack.__index = AnimationTrack

function AnimationTrack.new(animId, character)
if typeof(animId) == "Instance" then
animId = animId.AnimationId
elseif type(animId) == "number" then
animId = "rbxassetid://" .. animId
end

local self = setmetatable({}, AnimationTrack)
self._instance = Instance.new("Animation")
self._instance.AnimationId = animId

self.character = character
self.track = self:CreateAnimationTrack()

return self
end


function AnimationTrack:IsPlaying()
return self.track.IsPlaying
end

function AnimationTrack:Play(weight)
weight = weight or 1
self.track:Play(DEFAULT_FADE_TIME, weight)
end

function AnimationTrack:AdjustSpeed(speed)
speed = speed or 1
self.track:AdjustSpeed(speed)
end

function AnimationTrack:Stop()
self.track:Stop()
end

function AnimationTrack:Destroy()
self:Stop()
self._instance:Destroy()
end

function AnimationTrack:GetMarkerReachedSignal(name)
return self.track:GetMarkerReachedSignal(name)
end

function AnimationTrack:OnEnded()
return self.track.Stopped
end


function AnimationTrack:CreateAnimationTrack()
local humanoid: Humanoid = self.character:WaitForChild("Humanoid")
local animator: Animator = humanoid:WaitForChild("Animator")

return animator:LoadAnimation(self._instance)
end

return AnimationTrack
modules/Base64.lua
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function enc(data)
return ((data:gsub('.', function(x)
local r, b = '', x:byte()
for i = 8, 1, -1 do
r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0')
end
return r
end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
if (#x < 6) then
return ''
end
local c = 0
for i = 1, 6 do
c = c + (x:sub(i,i)=='1' and 2^(6-i) or 0)
end
return b:sub(c+1,c+1)
end) .. ({ '', '==', '=' })[#data%3+1])
end

-- decoding
function dec(data)
data = string.gsub(data, '[^'..b..'=]', '')
return (data:gsub('.', function(x)
if (x == '=') then return '' end
local r, f = '', b:find(x)-1
for i = 6, 1, -1 do
r = r .. (f%2^i-f%2^(i-1)>0 and '1' or '0')
end
return r
end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
if (#x ~= 8) then
return ''
end
local c = 0
for i = 1, 8 do
c=c+(x:sub(i,i)=='1' and 2^(7-i) or 0)
end
return string.char(c)
end))
end

return {encode = enc, decode = dec}
modules/BitBuffer.lua
local CHAR_SET = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/]]

-- Tradition is to use chars for the lookup table instead of codepoints.
-- But due to how we're running the encode function, it's faster to use codepoints.
local encode_char_set = {}
local decode_char_set = {}
for i = 1, 64 do
encode_char_set[i - 1] = string.byte(CHAR_SET, i, i)
decode_char_set[string.byte(CHAR_SET, i, i)] = i - 1
end

-- stylua: ignore
local HEX_TO_BIN = {
["0"] = "0000", ["1"] = "0001", ["2"] = "0010", ["3"] = "0011",
["4"] = "0100", ["5"] = "0101", ["6"] = "0110", ["7"] = "0111",
["8"] = "1000", ["9"] = "1001", ["a"] = "1010", ["b"] = "1011",
["c"] = "1100", ["d"] = "1101", ["e"] = "1110", ["f"] = "1111"
}

-- stylua: ignore
local NORMAL_ID_VECTORS = { -- [Enum.Value] = Vector3.fromNormalId(Enum)
[0] = Vector3.new(1, 0, 0), -- Enum.NormalId.Right
[1] = Vector3.new(0, 1, 0), -- Enum.NormalId.Top
[2] = Vector3.new(0, 0, 1), -- Enum.NormalId.Back
[3] = Vector3.new(-1, 0, 0), -- Enum.NormalId.Left
[4] = Vector3.new(0, -1, 0), -- Enum.NormalId.Bottom
[5] = Vector3.new(0, 0, -1) -- Enum.NormalId.Front
}

local ONES_VECTOR = Vector3.new(1, 1, 1)

local BOOL_TO_BIT = { [true] = 1, [false] = 0 }

local CRC32_POLYNOMIAL = 0xedb88320

local crc32_poly_lookup = {}
for i = 0, 255 do
local crc = i
for _ = 1, 8 do
local mask = -bit32.band(crc, 1)
crc = bit32.bxor(bit32.rshift(crc, 1), bit32.band(CRC32_POLYNOMIAL, mask))
end
crc32_poly_lookup[i] = crc
end

local powers_of_2 = {}
for i = 0, 64 do
powers_of_2[i] = 2 ^ i
end

local byte_to_hex = {}
for i = 0, 255 do
byte_to_hex[i] = string.format("%02x", i)
end

local function bitBuffer(stream)
if stream ~= nil then
assert(type(stream) == "string", "argument to BitBuffer constructor must be either nil or a string")
end

-- The bit buffer works by keeping an array of bytes, a 'final' byte, and how many bits are currently in that last byte
-- Bits are not kept track of on their own, and are instead combined to form a byte, which is stored in the last space in the array.
-- This byte is also stored seperately, so that table operations aren't needed to read or modify its value.
-- The byte array is called `bytes`. The last byte is stored in `lastByte`. The bit counter is stored in `bits`.

local bits = 0 -- How many free floating bits there are.
local bytes = {} --! -- Array of bytes currently in the buffer
local lastByte = 0 -- The most recent byte in the buffer, made up of free floating bits

local byteCount = 0 -- This variable keeps track of how many bytes there are total in the bit buffer.
local bitCount = 0 -- This variable keeps track of how many bits there are total in the bit buffer

local pointer = 0 -- This variable keeps track of what bit the read functions start at
local pointerByte = 1 -- This variable keeps track of what byte the pointer is at. It starts at 1 since the byte array starts at 1.

if stream then
byteCount = #stream
bitCount = byteCount * 8

bytes = table.create(#stream)

for i = 1, byteCount do
bytes[i] = string.byte(stream, i, i)
end
end

local function dumpBinary()
-- This function is for debugging or analysis purposes.
-- It dumps the contents of the byte array and the remaining bits into a string of binary digits.
-- Thus, bytes [97, 101] with bits [1, 1, 0] would output "01100001 01100101 110"
local output = table.create(byteCount) --!
for i, v in ipairs(bytes) do
output[i] = string.gsub(byte_to_hex[v], "%x", HEX_TO_BIN)
end
if bits ~= 0 then
-- Because the last byte (where the free floating bits are stored) is in the byte array, it has to be overwritten.
output[byteCount] = string.sub(output[byteCount], 1, bits)
end

return table.concat(output, " ")
end

local function dumpString()
-- This function is for accessing the total contents of the bitbuffer.
-- This function combines all the bytes, including the last byte, into a string of binary data.
-- Thus, bytes [97, 101] and bits [1, 1, 0] would become (in hex) "0x61 0x65 0x06"

-- It's substantially faster to create several smaller strings before using table.concat.
local output = table.create(math.ceil(byteCount / 4096)) --!
local c = 1
for i = 1, byteCount, 4096 do -- groups of 4096 bytes is the point at which there are diminishing returns
output[c] = string.char(table.unpack(bytes, i, math.min(byteCount, i + 4095)))
c = c + 1
end

return table.concat(output, "")
end

local function dumpHex()
-- This function is for getting the hex of the bitbuffer's contents, should that be desired
local output = table.create(byteCount) --!
for i, v in ipairs(bytes) do
output[i] = byte_to_hex[v]
end

return table.concat(output, "")
end

local function dumpBase64()
-- Base64 is a safe and easy way to convert binary data to be entirely printable
-- It works on the principle that groups of 3 bytes (24 bits) can evenly be divided into 4 groups of 6
-- And 2^6 is a mere 64, far less than the number of printable characters.
-- If there are any missing bytes, `=` is added to the end as padding.
-- Base64 increases the size of its input by 33%.
local output = table.create(math.ceil(byteCount * 1.333)) --!

local c = 1
for i = 1, byteCount, 3 do
local b1, b2, b3 = bytes[i], bytes[i + 1], bytes[i + 2]
local packed = bit32.bor(bit32.lshift(b1, 16), bit32.lshift(b2 or 0, 8), b3 or 0)

-- This can be done with bit32.extract (and/or bit32.lshift, bit32.band, bit32.rshift)
-- But bit masking and shifting is more eloquent in my opinion.
output[c] = encode_char_set[bit32.rshift(bit32.band(packed, 0xfc0000), 0x12)]
output[c + 1] = encode_char_set[bit32.rshift(bit32.band(packed, 0x3f000), 0xc)]
output[c + 2] = b2 and encode_char_set[bit32.rshift(bit32.band(packed, 0xfc0), 0x6)] or 0x3d -- 0x3d == "="
output[c + 3] = b3 and encode_char_set[bit32.band(packed, 0x3f)] or 0x3d

c = c + 4
end
c = c - 1 -- c will always be 1 more than the length of `output`

local realOutput = table.create(math.ceil(c / 0x1000)) --!
local k = 1
for i = 1, c, 0x1000 do
realOutput[k] = string.char(table.unpack(output, i, math.min(c, i + 0xfff)))
k = k + 1
end

return table.concat(realOutput, "")
end

local function exportChunk(chunkLength)
assert(type(chunkLength) == "number", "argument #1 to BitBuffer.exportChunk should be a number")
assert(chunkLength > 0, "argument #1 to BitBuffer.exportChunk should be above zero")
assert(chunkLength % 1 == 0, "argument #1 to BitBuffer.exportChunk should be an integer")

-- Since `i` is being returned, the most eloquent way to handle this is with a coroutine
-- This allows returning the existing value of `i` without having to increment it first.
-- The alternative was starting at `i = -(chunkLength-1)` and incrementing at the start of the iterator function.
return coroutine.wrap(function()
local realChunkLength = chunkLength - 1
-- Since this function only has one 'state', it's perfectly fine to use a for-loop.
for i = 1, byteCount, chunkLength do
local chunk = string.char(table.unpack(bytes, i, math.min(byteCount, i + realChunkLength)))
coroutine.yield(i, chunk)
end
end)
end

local function exportBase64Chunk(chunkLength)
chunkLength = chunkLength or 76
assert(type(chunkLength) == "number", "argument #1 to BitBuffer.exportBase64Chunk should be a number")
assert(chunkLength > 0, "argument #1 to BitBuffer.exportBase64Chunk should be above zero")
assert(chunkLength % 1 == 0, "argument #1 to BitBuffer.exportBase64Chunk should be an integer")

local output = table.create(math.ceil(byteCount * 0.333)) --!

local c = 1
for i = 1, byteCount, 3 do
local b1, b2, b3 = bytes[i], bytes[i + 1], bytes[i + 2]
local packed = bit32.bor(bit32.lshift(b1, 16), bit32.lshift(b2 or 0, 8), b3 or 0)

output[c] = encode_char_set[bit32.rshift(bit32.band(packed, 0xfc0000), 0x12)]
output[c + 1] = encode_char_set[bit32.rshift(bit32.band(packed, 0x3f000), 0xc)]
output[c + 2] = b2 and encode_char_set[bit32.rshift(bit32.band(packed, 0xfc0), 0x6)] or 0x3d
output[c + 3] = b3 and encode_char_set[bit32.band(packed, 0x3f)] or 0x3d

c = c + 4
end
c = c - 1

return coroutine.wrap(function()
local realChunkLength = chunkLength - 1
for i = 1, c, chunkLength do
local chunk = string.char(table.unpack(output, i, math.min(c, i + realChunkLength)))
coroutine.yield(chunk)
end
end)
end

local function exportHexChunk(chunkLength)
assert(type(chunkLength) == "number", "argument #1 to BitBuffer.exportHexChunk should be a number")
assert(chunkLength > 0, "argument #1 to BitBuffer.exportHexChunk should be above zero")
assert(chunkLength % 1 == 0, "argument #1 to BitBuffer.exportHexChunk should be an integer")

local halfLength = math.floor(chunkLength / 2)

if chunkLength % 2 == 0 then
return coroutine.wrap(function()
local output = {} --!
for i = 1, byteCount, halfLength do
for c = 0, halfLength - 1 do
output[c] = byte_to_hex[bytes[i + c]]
end
coroutine.yield(table.concat(output, "", 0))
end
end)
else
return coroutine.wrap(function()
local output = { [0] = "" } --!
local remainder = ""

local i = 1
while i <= byteCount do
if remainder == "" then
output[0] = ""
for c = 0, halfLength - 1 do
output[c + 1] = byte_to_hex[bytes[i + c]]
end
local endByte = byte_to_hex[bytes[i + halfLength]]
if endByte then
output[halfLength + 1] = string.sub(endByte, 1, 1)
remainder = string.sub(endByte, 2, 2)
end
i = i + 1
else
output[0] = remainder
for c = 0, halfLength - 1 do
output[c + 1] = byte_to_hex[bytes[i + c]]
end
output[halfLength + 1] = ""
remainder = ""
end

coroutine.yield(table.concat(output, "", 0))
i = i + halfLength
end
end)
end
end

local function crc32()
local crc = 0xffffffff -- 2^32

for _, v in ipairs(bytes) do
local poly = crc32_poly_lookup[bit32.band(bit32.bxor(crc, v), 255)]
crc = bit32.bxor(bit32.rshift(crc, 8), poly)
end

return bit32.bnot(crc) % 0xffffffff -- 2^32
end

local function getLength()
return bitCount
end

local function getByteLength()
return byteCount
end

local function getPointer()
-- This function gets the value of the pointer. This is self-explanatory.
return pointer
end

local function setPointer(n)
assert(type(n) == "number", "argument #1 to BitBuffer.setPointer should be a number")
assert(n >= 0, "argument #1 to BitBuffer.setPointer should be zero or higher")
assert(n % 1 == 0, "argument #1 to BitBuffer.setPointer should be an integer")
assert(n <= bitCount, "argument #1 to BitBuffer.setPointerByte should within range of the buffer")
-- This function sets the value of pointer. This is self-explanatory.
pointer = n
pointerByte = math.floor(n / 8) + 1
end

local function setPointerFromEnd(n)
assert(type(n) == "number", "argument #1 to BitBuffer.setPointerFromEnd should be a number")
assert(n >= 0, "argument #1 to BitBuffer.setPointerFromEnd should be zero or higher")
assert(n % 1 == 0, "argument #1 to BitBuffer.setPointerFromEnd should be an integer")
assert(n <= bitCount, "argument #1 to BitBuffer.setPointerFromEnd should within range of the buffer")

pointer = bitCount - n
pointerByte = math.floor(pointer / 8 + 1)
end

local function getPointerByte()
return pointerByte
end

local function setPointerByte(n)
assert(type(n) == "number", "argument #1 to BitBuffer.setPointerByte should be a number")
assert(n > 0, "argument #1 to BitBuffer.setPointerByte should be positive")
assert(n % 1 == 0, "argument #1 to BitBuffer.setPointerByte should be an integer")
assert(n <= byteCount, "argument #1 to BitBuffer.setPointerByte should be within range of the buffer")
-- Sets the value of the pointer in bytes instead of bits
pointer = n * 8
pointerByte = n
end

local function setPointerByteFromEnd(n)
assert(type(n) == "number", "argument #1 to BitBuffer.setPointerByteFromEnd should be a number")
assert(n >= 0, "argument #1 to BitBuffer.setPointerByteFromEnd should be zero or higher")
assert(n % 1 == 0, "argument #1 to BitBuffer.setPointerByteFromEnd should be an integer")
assert(n <= byteCount, "argument #1 to BitBuffer.setPointerByteFromEnd should be within range of the buffer")

pointerByte = byteCount - n
pointer = pointerByte * 8
end

local function isFinished()
return pointer == bitCount
end

local function writeBits(...)
-- The first of two main functions for the actual 'writing' of the bitbuffer.
-- This function takes a vararg of 1s and 0s and writes them to the buffer.
local bitN = select("#", ...)
if bitN == 0 then
return
end -- Throwing here seems unnecessary
bitCount = bitCount + bitN
local packed = table.pack(...)
for _, v in ipairs(packed) do
assert(v == 1 or v == 0, "arguments to BitBuffer.writeBits should be either 1 or 0")
if bits == 0 then -- If the bit count is 0, increment the byteCount
-- This is the case at the beginning of the buffer as well as when the the buffer reaches 7 bits,
-- so it's done at the beginning of the loop.
byteCount = byteCount + 1
end
lastByte = lastByte + (v == 1 and powers_of_2[7 - bits] or 0) -- Add the current bit to lastByte, from right to left
bits = bits + 1
if bits == 8 then -- If the bit count is 8, set it to 0, write lastByte to the byte list, and set lastByte to 0
bits = 0
bytes[byteCount] = lastByte
lastByte = 0
end
end
if bits ~= 0 then -- If there are some bits in lastByte, it has to be put into lastByte
-- If this is done regardless of the bit count, there might be a trailing zero byte
bytes[byteCount] = lastByte
end
end

local function writeByte(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeByte should be a number")
assert(n >= 0 and n <= 255, "argument #1 to BitBuffer.writeByte should be in the range [0, 255]")
assert(n % 1 == 0, "argument #1 to BitBuffer.writeByte should be an integer")
-- The second of two main functions for the actual 'writing' of the bitbuffer.
-- This function takes a byte (an 8-bit integer) and writes it to the buffer.
if bits == 0 then
-- If there aren't any free-floating bits, this is easy.
byteCount = byteCount + 1
bytes[byteCount] = n
else
local nibble = bit32.rshift(n, bits) -- Shift `bits` number of bits out of `n` (they go into the aether)
bytes[byteCount] = lastByte + nibble -- Manually set the most recent byte to the lastByte + the front part of `n`
byteCount = byteCount + 1
lastByte = bit32.band(bit32.lshift(n, 8 - bits), 255) -- Shift `n` forward `8-bits` and get what remains in the first 8 bits
bytes[byteCount] = lastByte
end
bitCount = bitCount + 8 -- Increment the bit counter
end

local function writeUnsigned(width, n)
assert(type(width) == "number", "argument #1 to BitBuffer.writeUnsigned should be a number")
assert(width >= 1 and width <= 64, "argument #1 to BitBuffer.writeUnsigned should be in the range [1, 64]")
assert(width % 1 == 0, "argument #1 to BitBuffer.writeUnsigned should be an integer")

assert(type(n) == "number", "argument #2 to BitBuffer.writeUnsigned should be a number")
assert(n >= 0 and n <= powers_of_2[width] - 1, "argument #2 to BitBuffer.writeUnsigned is out of range")
assert(n % 1 == 0, "argument #2 to BitBuffer.writeUnsigned should be an integer")
-- Writes unsigned integers of arbitrary length to the buffer.
-- This is the first function that uses other functions in the buffer to function.
-- This is done because the space taken up would be rather large for very little performance gain.

-- Get the number of bytes and number of floating bits in the specified width
local bytesInN, bitsInN = math.floor(width / 8), width % 8
local extractedBits = table.create(bitsInN) --!

-- If the width is less than or equal to 32-bits, bit32 can be used without any problem.
if width <= 32 then
-- Counting down from the left side, the bytes are written to the buffer
local c = width
for _ = 1, bytesInN do
c = c - 8
writeByte(bit32.extract(n, c, 8))
end
-- Any remaining bits are stored in an array
for i = bitsInN - 1, 0, -1 do
extractedBits[bitsInN - i] = BOOL_TO_BIT[bit32.btest(n, powers_of_2[i])]
end
-- Said array is then used to write them to the buffer
writeBits(table.unpack(extractedBits))
else
-- If the width is greater than 32, the number has to be divided up into a few 32-bit or less numbers
local leastSignificantChunk = n % 0x100000000 -- Get bits 0-31 (counting from the right side). 0x100000000 is 2^32.
local mostSignificantChunk = math.floor(n / 0x100000000) -- Get any remaining bits by manually right shifting by 32 bits

local c = width - 32 -- The number of bits in mostSignificantChunk is variable, but a counter is still needed
for _ = 1, bytesInN - 4 do -- 32 bits is 4 bytes
c = c - 8
writeByte(bit32.extract(mostSignificantChunk, c, 8))
end
-- `bitsInN` is always going to be the number of spare bits in `mostSignificantChunk`
-- which comes before `leastSignificantChunk`
for i = bitsInN - 1, 0, -1 do
extractedBits[bitsInN - i] = BOOL_TO_BIT[bit32.btest(mostSignificantChunk, powers_of_2[i])]
end
writeBits(table.unpack(extractedBits))

for i = 3, 0, -1 do -- Then of course, write all 4 bytes of leastSignificantChunk
writeByte(bit32.extract(leastSignificantChunk, i * 8, 8))
end
end
end

local function writeSigned(width, n)
assert(type(width) == "number", "argument #1 to BitBuffer.writeSigned should be a number")
assert(width >= 2 and width <= 64, "argument #1 to BitBuffer.writeSigned should be in the range [2, 64]")
assert(width % 1 == 0, "argument #1 to BitBuffer.writeSigned should be an integer")

assert(type(n) == "number", "argument #2 to BitBuffer.writeSigned should be a number")
assert(
n >= -powers_of_2[width - 1] and n <= powers_of_2[width - 1] - 1,
"argument #2 to BitBuffer.writeSigned is out of range"
)
assert(n % 1 == 0, "argument #2 to BitBuffer.writeSigned should be an integer")
-- Writes signed integers of arbitrary length to the buffer.
-- These integers are stored using two's complement.
-- Essentially, this means the first bit in the number is used to store whether it's positive or negative
-- If the number is positive, it's stored normally.
-- If it's negative, the number that's stored is equivalent to the max value of the width + the number
if n >= 0 then
writeBits(0)
writeUnsigned(width - 1, n) -- One bit is used for the sign, so the stored number's width is actually width-1
else
writeBits(1)
writeUnsigned(width - 1, powers_of_2[width - 1] + n)
end
end

local function writeFloat(exponentWidth, mantissaWidth, n)
assert(type(exponentWidth) == "number", "argument #1 to BitBuffer.writeFloat should be a number")
assert(
exponentWidth >= 1 and exponentWidth <= 64,
"argument #1 to BitBuffer.writeFloat should be in the range [1, 64]"
)
assert(exponentWidth % 1 == 0, "argument #1 to BitBuffer.writeFloat should be an integer")

assert(type(mantissaWidth) == "number", "argument #2 to BitBuffer.writeFloat should be a number")
assert(
mantissaWidth >= 1 and mantissaWidth <= 64,
"argument #2 to BitBuffer.writeFloat should be in the range [1, 64]"
)
assert(mantissaWidth % 1 == 0, "argument #2 to BitBuffer.writeFloat should be an integer")

assert(type(n) == "number", "argument #3 to BitBuffer.writeFloat should be a number")

-- Given that floating point numbers are particularly hard to grasp, this function is annotated heavily.
-- This stackoverflow answer is a great help if you just want an overview:
-- https://stackoverflow.com/a/7645264
-- Essentially, floating point numbers are scientific notation in binary.
-- Instead of expressing numbers like 10^e*m, floating points instead use 2^e*m.
-- For the sake of this function, `e` is referred to as `exponent` and `m` is referred to as `mantissa`.

-- Floating point numbers are stored in memory as a sequence of bitfields.
-- Every float has a set number of bits assigned for exponent values and mantissa values, along with one bit for the sign.
-- The order of the bits in the memory is: sign, exponent, mantissa.

-- Given that floating points have to represent numbers less than zero as well as those above them,
-- some parts of the exponent are set aside to be negative exponents. In the case of floats,
-- this is about half of the values. To calculate the 'real' value of an exponent a number that's half of the max exponent
-- is added to the exponent. More info can be found here: https://stackoverflow.com/q/2835278
-- This number is called the 'bias'.
local bias = powers_of_2[exponentWidth - 1] - 1

local sign = n < 0 -- The sign of a number is important.
-- In this case, since we're using a lookup table for the sign bit, we want `sign` to indicate if the number is negative or not.
n = math.abs(n) -- But it's annoying to work with negative numbers and the sign isn't important for decomposition.

-- Lua has a function specifically for decomposing (or taking apart) a floating point number into its pieces.
-- These pieces, as listed above, are the mantissa and exponent.
local mantissa, exponent = math.frexp(n)

-- Before we go further, there are some concepts that get special treatment in the floating point format.
-- These have to be accounted for before normal floats are written to the buffer.

if n == math.huge then
-- Positive and negative infinities are specifically indicated with an exponent that's all 1s
-- and a mantissa that's all 0s.
writeBits(BOOL_TO_BIT[sign]) -- As previously said, there's a bit for the sign
writeUnsigned(exponentWidth, powers_of_2[exponentWidth] - 1) -- Then comes the exponent
writeUnsigned(mantissaWidth, 0) -- And finally the mantissa
return
elseif n ~= n then
-- NaN is indicated with an exponent that's all 1s and a mantissa that isn't 0.
-- In theory, the individual bits of NaN should be maintained but Lua doesn't allow that,
-- so the mantissa is just being set to 10 for no particular reason.
writeBits(BOOL_TO_BIT[sign])
writeUnsigned(exponentWidth, powers_of_2[exponentWidth] - 1)
writeUnsigned(mantissaWidth, 10)
return
elseif n == 0 then
-- Zero is represented with an exponent that's zero and a mantissa that's also zero.
-- Lua doesn't have a signed zero, so that translates to the entire number being all 0s.
writeUnsigned(exponentWidth + mantissaWidth + 1, 0)
return
elseif exponent + bias <= 1 then
-- Subnormal numbers are a number that's exponent (when biased) is zero.
-- Because of a quirk with the way Lua and C decompose numbers, subnormal numbers actually have an exponent of one when biased.

-- The process behind this is explained below, so for the sake of brevity it isn't explained here.
-- The only difference between processing subnormal and normal numbers is with the mantissa.
-- As subnormal numbers always start with a 0 (in binary), it doesn't need to be removed or shifted out
-- so it's a simple shift and round.
mantissa = math.floor(mantissa * powers_of_2[mantissaWidth] + 0.5)

writeBits(BOOL_TO_BIT[sign])
writeUnsigned(exponentWidth, 0) -- Subnormal numbers always have zero for an exponent
writeUnsigned(mantissaWidth, mantissa)
return
end

-- In every normal case, the mantissa of a number will have a 1 directly after the decimal point (in binary).
-- As an example, 0.15625 has a mantissa of 0.625, which is 0.101 in binary. The 1 after the decimal point is always there.
-- That means that for the sake of space efficiency that can be left out.
-- The bit has to be removed. This uses subtraction and multiplication to do it since bit32 is for integers only.
-- The mantissa is then shifted up by the width of the mantissa field and rounded.
mantissa = math.floor((mantissa - 0.5) * 2 * powers_of_2[mantissaWidth] + 0.5)
-- (The first fraction bit is equivalent to 0.5 in decimal)

-- After that, it's just a matter of writing to the stream:
writeBits(BOOL_TO_BIT[sign])
writeUnsigned(exponentWidth, exponent + bias - 1) -- The bias is added to the exponent to properly offset it
-- The extra -1 is added because Lua, for whatever reason, doesn't normalize its results
-- This is the cause of the 'quirk' mentioned when handling subnormal number
-- As an example, math.frexp(0.15625) = 0.625, -2
-- This means that 0.15625 = 0.625*2^-2
-- Or, in binary: 0.00101 = 0.101 >> 2
-- This is a correct statement but the actual result is meant to be:
-- 0.00101 = 1.01 >> 3, or 0.15625 = 1.25*2^-3
-- A small but important distinction that has made writing this module frustrating because no documentation notates this.
writeUnsigned(mantissaWidth, mantissa)
end

local function writeBase64(input)
assert(type(input) == "string", "argument #1 to BitBuffer.writeBase64 should be a string")
assert(
not string.find(input, "[^%w%+/=]"),
"argument #1 to BitBuffer.writeBase64 should only contain valid base64 characters"
)

for i = 1, #input, 4 do
local b1, b2, b3, b4 = string.byte(input, i, i + 3)

b1 = decode_char_set[b1]
b2 = decode_char_set[b2]
b3 = decode_char_set[b3]
b4 = decode_char_set[b4]

local packed = bit32.bor(bit32.lshift(b1, 18), bit32.lshift(b2, 12), bit32.lshift(b3 or 0, 6), b4 or 0)

writeByte(bit32.rshift(packed, 16))
if not b3 then
break
end
writeByte(bit32.band(bit32.rshift(packed, 8), 0xff))
if not b4 then
break
end
writeByte(bit32.band(packed, 0xff))
end
end

local function writeString(str)
assert(type(str) == "string", "argument #1 to BitBuffer.writeString should be a string")
-- The default mode of writing strings is length-prefixed.
-- This means that the length of the string is written before the contents of the string.
-- For the sake of speed it has to be an even byte.
-- One and two bytes is too few characters (255 bytes and 65535 bytes respectively), so it has to be higher.
-- Three bytes is roughly 16.77mb, and four is roughly 4.295gb. Given this is Lua and is thus unlikely to be processing strings
-- that large, this function uses three bytes, or 24 bits for the length

writeUnsigned(24, #str)

for i = 1, #str do
writeByte(string.byte(str, i, i))
end
end

local function writeTerminatedString(str)
assert(type(str) == "string", "argument #1 to BitBuffer.writeTerminatedString should be a string")
-- This function writes strings that are null-terminated.
-- Null-terminated strings are strings of bytes that end in a 0 byte (\0)
-- This isn't the default because it doesn't allow for binary data to be written cleanly.

for i = 1, #str do
writeByte(string.byte(str, i, i))
end
writeByte(0)
end

local function writeSetLengthString(str)
assert(type(str) == "string", "argument #1 to BitBuffer.writeSetLengthString should be a string")
-- This function writes strings as a pure string of bytes
-- It doesn't store any data about the length of the string,
-- so reading it requires knowledge of how many characters were stored

for i = 1, #str do
writeByte(string.byte(str, i, i))
end
end

local function writeField(...)
-- This is equivalent to having a writeBitfield function.
-- It combines all of the passed 'bits' into an unsigned number, then writes it.
local field = 0
local bools = table.pack(...)
for i = 1, bools.n do
field = field * 2 -- Shift `field`. Equivalent to field<<1. At the beginning of the loop to avoid an extra shift.

local v = bools[i]
if v then
field = field + 1 -- If the bit is truthy, turn it on (it defaults to off so it's fine to not have a branch)
end
end

writeUnsigned(bools.n, field)
end

-- All write functions below here are shorthands. For the sake of performance, these functions are implemented manually.
-- As an example, while it would certainly be easier to make `writeInt16(n)` just call `writeUnsigned(16, n),
-- it's more performant to just manually call writeByte twice for it.

local function writeUInt8(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeUInt8 should be a number")
assert(n >= 0 and n <= 255, "argument #1 to BitBuffer.writeUInt8 should be in the range [0, 255]")
assert(n % 1 == 0, "argument #1 to BitBuffer.writeUInt8 should be an integer")

writeByte(n)
end

local function writeUInt16(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeUInt16 should be a number")
assert(n >= 0 and n <= 65535, "argument #1 to BitBuffer.writeInt16 should be in the range [0, 65535]")
assert(n % 1 == 0, "argument #1 to BitBuffer.writeUInt16 should be an integer")

writeByte(bit32.rshift(n, 8))
writeByte(bit32.band(n, 255))
end

local function writeUInt32(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeUInt32 should be a number")
assert(
n >= 0 and n <= 4294967295,
"argument #1 to BitBuffer.writeUInt32 should be in the range [0, 4294967295]"
)
assert(n % 1 == 0, "argument #1 to BitBuffer.writeUInt32 should be an integer")

writeByte(bit32.rshift(n, 24))
writeByte(bit32.band(bit32.rshift(n, 16), 255))
writeByte(bit32.band(bit32.rshift(n, 8), 255))
writeByte(bit32.band(n, 255))
end

local function writeInt8(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeInt8 should be a number")
assert(n >= -128 and n <= 127, "argument #1 to BitBuffer.writeInt8 should be in the range [-128, 127]")
assert(n % 1 == 0, "argument #1 to BitBuffer.writeInt8 should be an integer")

if n < 0 then
n = (128 + n) + 128
end

writeByte(n)
end

local function writeInt16(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeInt16 should be a number")
assert(n >= -32768 and n <= 32767, "argument #1 to BitBuffer.writeInt16 should be in the range [-32768, 32767]")
assert(n % 1 == 0, "argument #1 to BitBuffer.writeInt16 should be an integer")

if n < 0 then
n = (32768 + n) + 32768
end

writeByte(bit32.rshift(n, 8))
writeByte(bit32.band(n, 255))
end

local function writeInt32(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeInt32 should be a number")
assert(
n >= -2147483648 and n <= 2147483647,
"argument #1 to BitBuffer.writeInt32 should be in the range [-2147483648, 2147483647]"
)
assert(n % 1 == 0, "argument #1 to BitBuffer.writeInt32 should be an integer")

if n < 0 then
n = (2147483648 + n) + 2147483648
end

writeByte(bit32.rshift(n, 24))
writeByte(bit32.band(bit32.rshift(n, 16), 255))
writeByte(bit32.band(bit32.rshift(n, 8), 255))
writeByte(bit32.band(n, 255))
end

local function writeFloat16(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeFloat16 should be a number")

local sign = n < 0
n = math.abs(n)

local mantissa, exponent = math.frexp(n)

if n == math.huge then
if sign then
writeByte(252) -- 11111100
else
writeByte(124) -- 01111100
end
writeByte(0) -- 00000000
return
elseif n ~= n then
-- 01111111 11111111
writeByte(127)
writeByte(255)
return
elseif n == 0 then
writeByte(0)
writeByte(0)
return
elseif exponent + 15 <= 1 then -- Bias for halfs is 15
mantissa = math.floor(mantissa * 1024 + 0.5)
if sign then
writeByte(128 + bit32.rshift(mantissa, 8)) -- Sign bit, 5 empty bits, 2 from mantissa
else
writeByte(bit32.rshift(mantissa, 8))
end
writeByte(bit32.band(mantissa, 255)) -- Get last 8 bits from mantissa
return
end

mantissa = math.floor((mantissa - 0.5) * 2048 + 0.5)

-- The bias for halfs is 15, 15-1 is 14
if sign then
writeByte(128 + bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8))
else
writeByte(bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8))
end
writeByte(bit32.band(mantissa, 255))
end

local function writeFloat32(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeFloat32 should be a number")

local sign = n < 0
n = math.abs(n)

local mantissa, exponent = math.frexp(n)

if n == math.huge then
if sign then
writeByte(255) -- 11111111
else
writeByte(127) -- 01111111
end
writeByte(128) -- 10000000
writeByte(0) -- 00000000
writeByte(0) -- 00000000
return
elseif n ~= n then
-- 01111111 11111111 11111111 11111111
writeByte(127)
writeByte(255)
writeByte(255)
writeByte(255)
return
elseif n == 0 then
writeByte(0)
writeByte(0)
writeByte(0)
writeByte(0)
return
elseif exponent + 127 <= 1 then -- bias for singles is 127
mantissa = math.floor(mantissa * 8388608 + 0.5)
if sign then
writeByte(128) -- Sign bit, 7 empty bits for exponent
else
writeByte(0)
end
writeByte(bit32.rshift(mantissa, 16))
writeByte(bit32.band(bit32.rshift(mantissa, 8), 255))
writeByte(bit32.band(mantissa, 255))
return
end

mantissa = math.floor((mantissa - 0.5) * 16777216 + 0.5)

-- 127-1 = 126
if sign then -- sign + 7 exponent
writeByte(128 + bit32.rshift(exponent + 126, 1))
else
writeByte(bit32.rshift(exponent + 126, 1))
end
writeByte(bit32.band(bit32.lshift(exponent + 126, 7), 255) + bit32.rshift(mantissa, 16)) -- 1 exponent + 7 mantissa
writeByte(bit32.band(bit32.rshift(mantissa, 8), 255)) -- 8 mantissa
writeByte(bit32.band(mantissa, 255)) -- 8 mantissa
end

local function writeFloat64(n)
assert(type(n) == "number", "argument #1 to BitBuffer.writeFloat64 should be a number")

local sign = n < 0
n = math.abs(n)

local mantissa, exponent = math.frexp(n)

if n == math.huge then
if sign then
writeByte(255) -- 11111111
else
writeByte(127) -- 01111111
end
writeByte(240) -- 11110000
writeByte(0) -- 00000000
writeByte(0) -- 00000000
writeByte(0) -- 00000000
writeByte(0) -- 00000000
writeByte(0) -- 00000000
writeByte(0) -- 00000000
return
elseif n ~= n then
-- 01111111 11111111 11111111 11111111 11111111 11111111 11111111 11111111
writeByte(127)
writeByte(255)
writeByte(255)
writeByte(255)
writeByte(255)
writeByte(255)
writeByte(255)
writeByte(255)
return
elseif n == 0 then
writeByte(0)
return
elseif exponent + 1023 <= 1 then -- bias for doubles is 1023
mantissa = math.floor(mantissa * 4503599627370496 + 0.5)
if sign then
writeByte(128) -- Sign bit, 7 empty bits for exponent
else
writeByte(0)
end

-- This is labeled better below
local leastSignificantChunk = mantissa % 0x100000000 -- 32 bits
local mostSignificantChunk = math.floor(mantissa / 0x100000000) -- 20 bits

writeByte(bit32.rshift(mostSignificantChunk, 16))
writeByte(bit32.band(bit32.rshift(mostSignificantChunk, 8), 255))
writeByte(bit32.band(mostSignificantChunk, 255))
writeByte(bit32.rshift(leastSignificantChunk, 24))
writeByte(bit32.band(bit32.rshift(leastSignificantChunk, 16), 255))
writeByte(bit32.band(bit32.rshift(leastSignificantChunk, 8), 255))
writeByte(bit32.band(leastSignificantChunk, 255))
return
end

mantissa = math.floor((mantissa - 0.5) * 9007199254740992 + 0.5)

--1023-1 = 1022
if sign then
writeByte(128 + bit32.rshift(exponent + 1022, 4)) -- shift out 4 of the bits in exponent
else
writeByte(bit32.rshift(exponent + 1022, 4)) -- 01000001 0110
end
-- Things start to get a bit wack here because the mantissa is 52 bits, so bit32 *can't* be used.
-- As the Offspring once said... You gotta keep 'em seperated.
local leastSignificantChunk = mantissa % 0x100000000 -- 32 bits
local mostSignificantChunk = math.floor(mantissa / 0x100000000) -- 20 bits

-- First, the last 4 bits of the exponent and the first 4 bits of the mostSignificantChunk:
writeByte(bit32.band(bit32.lshift(exponent + 1022, 4), 255) + bit32.rshift(mostSignificantChunk, 16))
-- Then, the next 16 bits:
writeByte(bit32.band(bit32.rshift(mostSignificantChunk, 8), 255))
writeByte(bit32.band(mostSignificantChunk, 255))
-- Then... 4 bytes of the leastSignificantChunk
writeByte(bit32.rshift(leastSignificantChunk, 24))
writeByte(bit32.band(bit32.rshift(leastSignificantChunk, 16), 255))
writeByte(bit32.band(bit32.rshift(leastSignificantChunk, 8), 255))
writeByte(bit32.band(leastSignificantChunk, 255))
end

-- All write functions below here are Roblox specific datatypes.

local function writeBrickColor(n)
assert(typeof(n) == "BrickColor", "argument #1 to BitBuffer.writeBrickColor should be a BrickColor")

writeUInt16(n.Number)
end

local function writeColor3(c3)
assert(typeof(c3) == "Color3", "argument #1 to BitBuffer.writeColor3 should be a Color3")

writeByte(math.floor(c3.R * 0xff + 0.5))
writeByte(math.floor(c3.G * 0xff + 0.5))
writeByte(math.floor(c3.B * 0xff + 0.5))
end

local function writeCFrame(cf)
assert(typeof(cf) == "CFrame", "argument #1 to BitBuffer.writeCFrame should be a CFrame")
-- CFrames can be rather lengthy (if stored naively, they would each be 48 bytes long) so some optimization is done here.
-- Specifically, if a CFrame is axis-aligned (it's only rotated in 90 degree increments), the rotation matrix isn't stored.
-- Instead, an 'id' for its orientation is generated and that's stored instead of the rotation.
-- This means that for the most common rotations, only 13 bytes are used.
-- The downside is that non-axis-aligned CFrames use 49 bytes instead of 48, but that's a small price to pay.

local upVector = cf.UpVector
local rightVector = cf.RightVector

-- This is an easy trick to check if a CFrame is axis-aligned:
-- Essentially, in order for a vector to be axis-aligned, two of the components have to be 0
-- This means that the dot product between the vector and a vector of all 1s will be 1 (0*x = 0)
-- Since these are all unit vectors, there is no other combination that results in 1.
local rightAligned = math.abs(rightVector:Dot(ONES_VECTOR))
local upAligned = math.abs(upVector:Dot(ONES_VECTOR))
-- At least one of these two vectors is guaranteed to not result in 0.

local axisAligned = (math.abs(1 - rightAligned) < 0.00001 or rightAligned == 0)
and (math.abs(1 - upAligned) < 0.00001 or upAligned == 0)
-- There are limitations to `math.abs(a-b) < epsilon` but they're not relevant:
-- The range of numbers is [0, 1] and this just needs to know if the number is approximately 1

--todo special code for quaternions (0x01 in Roblox's format, would clash with 0x00 here)
if axisAligned then
local position = cf.Position
-- The ID of an orientation is generated through what can best be described as 'hand waving';
-- This is how Roblox does it and it works, so it was chosen to do it this way too.
local rightNormal, upNormal
for i = 0, 5 do
local v = NORMAL_ID_VECTORS[i]
if 1 - v:Dot(rightVector) < 0.00001 then
rightNormal = i
end
if 1 - v:Dot(upVector) < 0.00001 then
upNormal = i
end
end
-- The ID generated here is technically off by 1 from what Roblox would store, but that's not important
-- It just means that 0x02 is actually 0x01 for the purposes of this module's implementation.
writeByte(rightNormal * 6 + upNormal)
writeFloat32(position.X)
writeFloat32(position.Y)
writeFloat32(position.Z)
else
-- If the CFrame isn't axis-aligned, the entire rotation matrix has to be written...
writeByte(0) -- Along with a byte to indicate the matrix was written.
local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
writeFloat32(x)
writeFloat32(y)
writeFloat32(z)
writeFloat32(r00)
writeFloat32(r01)
writeFloat32(r02)
writeFloat32(r10)
writeFloat32(r11)
writeFloat32(r12)
writeFloat32(r20)
writeFloat32(r21)
writeFloat32(r22)
end
end

local function writeVector3(v3)
assert(typeof(v3) == "Vector3", "argument #1 to BitBuffer.writeVector3 should be a Vector3")

writeFloat32(v3.X)
writeFloat32(v3.Y)
writeFloat32(v3.Z)
end

local function writeVector2(v2)
assert(typeof(v2) == "Vector2", "argument #1 to BitBuffer.writeVector2 should be a Vector2")

writeFloat32(v2.X)
writeFloat32(v2.Y)
end

local function writeUDim2(u2)
assert(typeof(u2) == "UDim2", "argument #1 to BitBuffer.writeUDim2 should be a UDim2")

writeFloat32(u2.X.Scale)
writeInt32(u2.X.Offset)
writeFloat32(u2.Y.Scale)
writeInt32(u2.Y.Offset)
end

local function writeUDim(u)
assert(typeof(u) == "UDim", "argument #1 to BitBuffer.writeUDim should be a UDim")

writeFloat32(u.Scale)
writeInt32(u.Offset)
end

local function writeRay(ray)
assert(typeof(ray) == "Ray", "argument #1 to BitBuffer.writeRay should be a Ray")

writeFloat32(ray.Origin.X)
writeFloat32(ray.Origin.Y)
writeFloat32(ray.Origin.Z)

writeFloat32(ray.Direction.X)
writeFloat32(ray.Direction.Y)
writeFloat32(ray.Direction.Z)
end

local function writeRect(rect)
assert(typeof(rect) == "Rect", "argument #1 to BitBuffer.writeRect should be a Rect")

writeFloat32(rect.Min.X)
writeFloat32(rect.Min.Y)

writeFloat32(rect.Max.X)
writeFloat32(rect.Max.Y)
end

local function writeRegion3(region)
assert(typeof(region) == "Region3", "argument #1 to BitBuffer.writeRegion3 should be a Region3")

local min = region.CFrame.Position - (region.Size / 2)
local max = region.CFrame.Position + (region.Size / 2)

writeFloat32(min.X)
writeFloat32(min.Y)
writeFloat32(min.Z)

writeFloat32(max.X)
writeFloat32(max.Y)
writeFloat32(max.Z)
end

local function writeEnum(enum)
assert(typeof(enum) == "EnumItem", "argument #1 to BitBuffer.writeEnum should be an EnumItem")

-- Relying upon tostring is generally not good, but there's not any other options for this.
writeTerminatedString(tostring(enum.EnumType))
writeUInt16(enum.Value) -- Optimistically assuming no Roblox Enum value will ever pass 65,535
end

local function writeNumberRange(range)
assert(typeof(range) == "NumberRange", "argument #1 to BitBuffer.writeNumberRange should be a NumberRange")

writeFloat32(range.Min)
writeFloat32(range.Max)
end

local function writeNumberSequence(sequence)
assert(
typeof(sequence) == "NumberSequence",
"argument #1 to BitBuffer.writeNumberSequence should be a NumberSequence"
)

writeUInt32(#sequence.Keypoints)
for _, keypoint in ipairs(sequence.Keypoints) do
writeFloat32(keypoint.Time)
writeFloat32(keypoint.Value)
writeFloat32(keypoint.Envelope)
end
end

local function writeColorSequence(sequence)
assert(
typeof(sequence) == "ColorSequence",
"argument #1 to BitBuffer.writeColorSequence should be a ColorSequence"
)

writeUInt32(#sequence.Keypoints)
for _, keypoint in ipairs(sequence.Keypoints) do
local c3 = keypoint.Value
writeFloat32(keypoint.Time)
writeByte(math.floor(c3.R * 0xff + 0.5))
writeByte(math.floor(c3.G * 0xff + 0.5))
writeByte(math.floor(c3.B * 0xff + 0.5))
end
end

-- These are the read functions for the 'abstract' data types. At the bottom, there are shorthand read functions.

local function readBits(n)
assert(type(n) == "number", "argument #1 to BitBuffer.readBits should be a number")
assert(n > 0, "argument #1 to BitBuffer.readBits should be greater than zero")
assert(n % 1 == 0, "argument #1 to BitBuffer.readBits should be an integer")

assert(pointer + n <= bitCount, "BitBuffer.readBits cannot read past the end of the stream")

-- The first of two main functions for the actual 'reading' of the bitbuffer.
-- Reads `n` bits and returns an array of their values.
local output = table.create(n) --!
local byte = bytes[pointerByte] -- For the sake of efficiency, the current byte that the bits are coming from is stored
local c = pointer % 8 -- A counter is set with the current position of the pointer in the byte
for i = 1, n do
-- Then, it's as easy as moving through the bits of the byte
-- And getting the individiual bit values
local pow = powers_of_2[7 - c]
output[i] = BOOL_TO_BIT[bit32.btest(byte, pow)] -- Test if a bit is on by &ing it by 2^[bit position]
c = c + 1
if c == 8 then -- If the byte boundary is reached, increment pointerByte and store the new byte in `byte`
pointerByte = pointerByte + 1
byte = bytes[pointerByte]
c = 0
end
end
pointer = pointer + n -- Move the pointer forward
return output
end

local function readByte()
assert(pointer + 8 <= bitCount, "BitBuffer.readByte cannot read past the end of the stream")
-- The second of two main functions for the actual 'reading' of the bitbuffer.
-- Reads a byte and returns it
local c = pointer % 8 -- How far into the pointerByte the pointer is
local byte1 = bytes[pointerByte] -- The pointerByte
pointer = pointer + 8
if c == 0 then -- Trivial if the pointer is at the beginning of the pointerByte
pointerByte = pointerByte + 1
return byte1
else
pointerByte = pointerByte + 1
-- Get the remainder of the first pointerByte and add it to the part of the new pointerByte that's required
-- Both these methods are explained in writeByte
return bit32.band(bit32.lshift(byte1, c), 255) + bit32.rshift(bytes[pointerByte], 8 - c)
end
end

local function readUnsigned(width)
assert(type(width) == "number", "argument #1 to BitBuffer.readUnsigned should be a number")
assert(width >= 1 and width <= 64, "argument #1 to BitBuffer.readUnsigned should be in the range [1, 64]")
assert(width % 1 == 0, "argument #1 to BitBuffer.readUnsigned should be an integer")

assert(pointer + width <= bitCount, "BitBuffer.readUnsigned cannot read past the end of the stream")
-- Implementing this on its own was considered because of a worry that it would be inefficient to call
-- readByte and readBit several times, but it was decided the simplicity is worth a minor performance hit.
local bytesInN, bitsInN = math.floor(width / 8), width % 8

-- No check is required for if the width is greater than 32 because bit32 isn't used.
local n = 0
-- Shift and add a read byte however many times is necessary
-- Adding after shifting is importnat - it prevents there from being 8 empty bits of space
for _ = 1, bytesInN do
n = n * 0x100 -- 2^8; equivalent to n << 8
n = n + readByte()
end
-- The bits are then read and added to the number
if bitsInN ~= 0 then
for _, v in ipairs(readBits(width % 8)) do --todo benchmark against concat+tonumber; might be worth the code smell
n = n * 2
n = n + v
end
end
return n
end

local function readSigned(width)
assert(type(width) == "number", "argument #1 to BitBuffer.readSigned should be a number")
assert(width >= 2 and width <= 64, "argument #1 to BitBuffer.readSigned should be in the range [2, 64]")
assert(width % 1 == 0, "argument #1 to BitBuffer.readSigned should be an integer")

assert(pointer + 8 <= bitCount, "BitBuffer.readSigned cannot read past the end of the stream")
local sign = readBits(1)[1]
local n = readUnsigned(width - 1) -- Again, width-1 is because one bit is used for the sign

-- As said in writeSigned, the written number is unmodified if the number is positive (the sign bit is 0)
if sign == 0 then
return n
else
-- And the number is equal to max value of the width + the number if the number is negative (the sign bit is 1)
-- To reverse that, the max value is subtracted from the stored number.
return n - powers_of_2[width - 1]
end
end

local function readFloat(exponentWidth, mantissaWidth)
assert(type(exponentWidth) == "number", "argument #1 to BitBuffer.readFloat should be a number")
assert(
exponentWidth >= 1 and exponentWidth <= 64,
"argument #1 to BitBuffer.readFloat should be in the range [1, 64]"
)
assert(exponentWidth % 1 == 0, "argument #1 to BitBuffer.readFloat should be an integer")

assert(type(mantissaWidth) == "number", "argument #2 to BitBuffer.readFloat should be a number")
assert(
mantissaWidth >= 1 and mantissaWidth <= 64,
"argument #2 to BitBuffer.readFloat should be in the range [1, 64]"
)
assert(mantissaWidth % 1 == 0, "argument #2 to BitBuffer.readFloat should be an integer")

assert(
pointer + exponentWidth + mantissaWidth + 1 <= bitCount,
"BitBuffer.readFloat cannot read past the end of the stream"
)
-- Recomposing floats is rather straightfoward.
-- The bias is subtracted from the exponent, the mantissa is shifted back by mantissaWidth, one is added to the mantissa
-- and the whole thing is recomposed with math.ldexp (this is identical to mantissa*(2^exponent)).

local bias = powers_of_2[exponentWidth - 1] - 1

local sign = readBits(1)[1]
local exponent = readUnsigned(exponentWidth)
local mantissa = readUnsigned(mantissaWidth)

-- Before normal numbers are handled though, special cases and subnormal numbers are once again handled seperately
if exponent == powers_of_2[exponentWidth] - 1 then
if mantissa ~= 0 then -- If the exponent is all 1s and the mantissa isn't zero, the number is NaN
return 0 / 0
else -- Otherwise, it's positive or negative infinity
return sign == 0 and math.huge or -math.huge
end
elseif exponent == 0 then
if mantissa == 0 then -- If the exponent and mantissa are both zero, the number is zero.
return 0
else -- If the exponent is zero and the mantissa is not zero, the number is subnormal
-- Subnormal numbers are straightforward: shifting the mantissa so that it's a fraction is all that's required
mantissa = mantissa / powers_of_2[mantissaWidth]

-- Since the exponent is 0, it's actual value is just -bias (it would be exponent-bias)
-- As previously touched on in writeFloat, the exponent value is off by 1 in Lua though.
return sign == 1 and -math.ldexp(mantissa, -bias + 1) or math.ldexp(mantissa, -bias + 1)
end
end

-- First, the mantissa is shifted back by the mantissaWidth
-- Then, 1 is added to it to 'normalize' it.
mantissa = (mantissa / powers_of_2[mantissaWidth]) + 1

-- Because the mantissa is normalized above (the leading 1 is in the ones place), it's accurate to say exponent-bias
return sign == 1 and -math.ldexp(mantissa, exponent - bias) or math.ldexp(mantissa, exponent - bias)
end

local function readString()
assert(pointer + 24 <= bitCount, "BitBuffer.readString cannot read past the end of the stream")
-- Reading a length-prefixed string is rather straight forward.
-- The length is read, then that many bytes are read and put in a string.

local stringLength = readUnsigned(24)
assert(pointer + (stringLength * 8) <= bitCount, "BitBuffer.readString cannot read past the end of the stream")

local outputCharacters = table.create(stringLength) --!

for i = 1, stringLength do
outputCharacters[i] = readByte()
end

local output = table.create(math.ceil(stringLength / 4096))
local k = 1
for i = 1, stringLength, 4096 do
output[k] = string.char(table.unpack(outputCharacters, i, math.min(stringLength, i + 4095)))
k = k + 1
end

return table.concat(output)
end

local function readTerminatedString()
local outputCharacters = {}

-- Bytes are read continuously until either a nul-character is reached or until the stream runs out.
local length = 0
while true do
local byte = readByte()
if not byte then -- Stream has ended
error("BitBuffer.readTerminatedString cannot read past the end of the stream", 2)
elseif byte == 0 then -- String has ended
break
else -- Add byte to string
length = length + 1
outputCharacters[length] = byte
end
end

local output = table.create(math.ceil(length / 4096))
local k = 1
for l = 1, length, 4096 do
output[k] = string.char(table.unpack(outputCharacters, l, math.min(length, l + 4095)))
k = k + 1
end

return table.concat(output)
end

local function readSetLengthString(length)
assert(type(length) == "number", "argument #1 to BitBuffer.readSetLengthString should be a number")
assert(length >= 0, "argument #1 to BitBuffer.readSetLengthString should be zero or higher.")
assert(length % 1 == 0, "argument #1 to BitBuffer.readSetLengthString should be an integer")

assert(
pointer + (length * 8) <= bitCount,
"BitBuffer.readSetLengthString cannot read past the end of the stream"
)
-- `length` number of bytes are read and put into a string

local outputCharacters = table.create(length) --!

for i = 1, length do
outputCharacters[i] = readByte()
end

local output = table.create(math.ceil(length / 4096))
local k = 1
for i = 1, length, 4096 do
output[k] = string.char(table.unpack(outputCharacters, i, math.min(length, i + 4095)))
k = k + 1
end

return table.concat(output)
end

local function readField(n)
assert(type(n) == "number", "argument #1 to BitBuffer.readField should be a number")
assert(n > 0, "argument #1 to BitBuffer.readField should be above 0")
assert(n % 1 == 0, "argument #1 to BitBuffer.readField should be an integer")

assert(pointer + n <= bitCount, "BitBuffer.readField cannot read past the end of the stream")
-- Reading a bit field is again rather simple. You read the actual field, then take the bits out.
local readInt = readUnsigned(n)
local output = table.create(n) --!

for i = n, 1, -1 do -- In reverse order since we're pulling bits out from lsb to msb
output[i] = readInt % 2 == 1 -- Equivalent to an extraction of the lsb
readInt = math.floor(readInt / 2) -- Equivalent to readInt>>1
end

return output
end

-- All read functions below here are shorthands.
-- As with their write variants, these functions are implemented manually using readByte for performance reasons.

local function readUInt8()
assert(pointer + 8 <= bitCount, "BitBuffer.readUInt8 cannot read past the end of the stream")

return readByte()
end

local function readUInt16()
assert(pointer + 16 <= bitCount, "BitBuffer.readUInt16 cannot read past the end of the stream")

return bit32.lshift(readByte(), 8) + readByte()
end

local function readUInt32()
assert(pointer + 32 <= bitCount, "BitBuffer.readUInt32 cannot read past the end of the stream")

return bit32.lshift(readByte(), 24) + bit32.lshift(readByte(), 16) + bit32.lshift(readByte(), 8) + readByte()
end

local function readInt8()
assert(pointer + 8 <= bitCount, "BitBuffer.readInt8 cannot read past the end of the stream")

local n = readByte()
local sign = bit32.btest(n, 128)
n = bit32.band(n, 127)

if sign then
return n - 128
else
return n
end
end

local function readInt16()
assert(pointer + 16 <= bitCount, "BitBuffer.readInt16 cannot read past the end of the stream")

local n = bit32.lshift(readByte(), 8) + readByte()
local sign = bit32.btest(n, 32768)
n = bit32.band(n, 32767)

if sign then
return n - 32768
else
return n
end
end

local function readInt32()
assert(pointer + 32 <= bitCount, "BitBuffer.readInt32 cannot read past the end of the stream")

local n = bit32.lshift(readByte(), 24) + bit32.lshift(readByte(), 16) + bit32.lshift(readByte(), 8) + readByte()
local sign = bit32.btest(n, 2147483648)
n = bit32.band(n, 2147483647)

if sign then
return n - 2147483648
else
return n
end
end

local function readFloat16()
assert(pointer + 16 <= bitCount, "BitBuffer.readFloat16 cannot read past the end of the stream")

local b0 = readByte()
local sign = bit32.btest(b0, 128)
local exponent = bit32.rshift(bit32.band(b0, 127), 2)
local mantissa = bit32.lshift(bit32.band(b0, 3), 8) + readByte()

if exponent == 31 then --2^5-1
if mantissa ~= 0 then
return 0 / 0
else
return sign and -math.huge or math.huge
end
elseif exponent == 0 then
if mantissa == 0 then
return 0
else
return sign and -math.ldexp(mantissa / 1024, -14) or math.ldexp(mantissa / 1024, -14)
end
end

mantissa = (mantissa / 1024) + 1

return sign and -math.ldexp(mantissa, exponent - 15) or math.ldexp(mantissa, exponent - 15)
end

local function readFloat32()
assert(pointer + 32 <= bitCount, "BitBuffer.readFloat32 cannot read past the end of the stream")

local b0 = readByte()
local b1 = readByte()
local sign = bit32.btest(b0, 128)
local exponent = bit32.band(bit32.lshift(b0, 1), 255) + bit32.rshift(b1, 7)
local mantissa = bit32.lshift(bit32.band(b1, 127), 23 - 7)
+ bit32.lshift(readByte(), 23 - 7 - 8)
+ bit32.lshift(readByte(), 23 - 7 - 8 - 8)

if exponent == 255 then -- 2^8-1
if mantissa ~= 0 then
return 0 / 0
else
return sign and -math.huge or math.huge
end
elseif exponent == 0 then
if mantissa == 0 then
return 0
else
-- -126 is the 0-bias+1
return sign and -math.ldexp(mantissa / 8388608, -126) or math.ldexp(mantissa / 8388608, -126)
end
end

mantissa = (mantissa / 8388608) + 1

return sign and -math.ldexp(mantissa, exponent - 127) or math.ldexp(mantissa, exponent - 127)
end

local function readFloat64()
assert(pointer + 64 <= bitCount, "BitBuffer.readFloat64 cannot read past the end of the stream")

local b0 = readByte()
local b1 = readByte()

local sign = bit32.btest(b0, 128)
local exponent = bit32.lshift(bit32.band(b0, 127), 4) + bit32.rshift(b1, 4)
local mostSignificantChunk = bit32.lshift(bit32.band(b1, 15), 16) + bit32.lshift(readByte(), 8) + readByte()
local leastSignificantChunk = bit32.lshift(readByte(), 24)
+ bit32.lshift(readByte(), 16)
+ bit32.lshift(readByte(), 8)
+ readByte()

-- local mantissa = (bit32.lshift(bit32.band(b1, 15), 16)+bit32.lshift(readByte(), 8)+readByte())*0x100000000+
-- bit32.lshift(readByte(), 24)+bit32.lshift(readByte(), 16)+bit32.lshift(readByte(), 8)+readByte()

local mantissa = mostSignificantChunk * 0x100000000 + leastSignificantChunk

if exponent == 2047 then -- 2^11-1
if mantissa ~= 0 then
return 0 / 0
else
return sign and -math.huge or math.huge
end
elseif exponent == 0 then
if mantissa == 0 then
return 0
else
return sign and -math.ldexp(mantissa / 4503599627370496, -1022)
or math.ldexp(mantissa / 4503599627370496, -1022)
end
end

mantissa = (mantissa / 4503599627370496) + 1

return sign and -math.ldexp(mantissa, exponent - 1023) or math.ldexp(mantissa, exponent - 1023)
end

-- All read functions below here are Roblox specific datatypes.

local function readBrickColor()
assert(pointer + 16 <= bitCount, "BitBuffer.readBrickColor cannot read past the end of the stream")

return BrickColor.new(readUInt16())
end

local function readColor3()
assert(pointer + 24 <= bitCount, "BitBuffer.readColor3 cannot read past the end of the stream")

return Color3.fromRGB(readByte(), readByte(), readByte())
end

local function readCFrame()
assert(pointer + 8 <= bitCount, "BitBuffer.readCFrame cannot read past the end of the stream")

local id = readByte()

if id == 0 then
assert(pointer + 384 <= bitCount, "BitBuffer.readCFrame cannot read past the end of the stream") -- 4*12 bytes = 383 bits

-- stylua: ignore
return CFrame.new(
readFloat32(), readFloat32(), readFloat32(),
readFloat32(), readFloat32(), readFloat32(),
readFloat32(), readFloat32(), readFloat32(),
readFloat32(), readFloat32(), readFloat32()
)
else
assert(pointer + 96 <= bitCount, "BitBuffer.readCFrame cannot read past the end of the stream") -- 4*3 bytes = 96 bits

local rightVector = NORMAL_ID_VECTORS[math.floor(id / 6)]
local upVector = NORMAL_ID_VECTORS[id % 6]
local lookVector = rightVector:Cross(upVector)

-- CFrame's full-matrix constructor takes right/up/look vectors as columns...
-- stylua: ignore
return CFrame.new(
readFloat32(), readFloat32(), readFloat32(),
rightVector.X, upVector.X, lookVector.X,
rightVector.Y, upVector.Y, lookVector.Y,
rightVector.Z, upVector.Z, lookVector.Z
)
end
end

local function readVector3()
assert(pointer + 96 <= bitCount, "BitBuffer.readVector3 cannot read past the end of the stream")

return Vector3.new(readFloat32(), readFloat32(), readFloat32())
end

local function readVector2()
assert(pointer + 64 <= bitCount, "BitBuffer.readVector2 cannot read past the end of the stream")

return Vector2.new(readFloat32(), readFloat32())
end

local function readUDim2()
assert(pointer + 128 <= bitCount, "BitBuffer.readUDim2 cannot read past the end of the stream")

return UDim2.new(readFloat32(), readInt32(), readFloat32(), readInt32())
end

local function readUDim()
assert(pointer + 64 <= bitCount, "BitBuffer.readUDim cannot read past the end of the stream")

return UDim.new(readFloat32(), readInt32())
end

local function readRay()
assert(pointer + 192 <= bitCount, "BitBuffer.readRay cannot read past the end of the stream")

return Ray.new(
Vector3.new(readFloat32(), readFloat32(), readFloat32()),
Vector3.new(readFloat32(), readFloat32(), readFloat32())
)
end

local function readRect()
assert(pointer + 128 <= bitCount, "BitBuffer.readRect cannot read past the end of the stream")

return Rect.new(readFloat32(), readFloat32(), readFloat32(), readFloat32())
end

local function readRegion3()
assert(pointer + 192 <= bitCount, "BitBuffer.readRegion3 cannot read past the end of the stream")

return Region3.new(
Vector3.new(readFloat32(), readFloat32(), readFloat32()),
Vector3.new(readFloat32(), readFloat32(), readFloat32())
)
end

local function readEnum()
assert(pointer + 8 <= bitCount, "BitBuffer.readEnum cannot read past the end of the stream")

local name = readTerminatedString() -- This might expose an error from readString to the end-user but it's not worth the hassle to fix.

assert(pointer + 16 <= bitCount, "BitBuffer.readEnum cannot read past the end of the stream")

local value = readUInt16() -- Again, optimistically assuming no Roblox Enum value will ever pass 65,535

-- Catching a potential error only to throw it with different formatting seems... Superfluous.
-- Open an issue on github if you feel otherwise.
for _, v in ipairs(Enum[name]:GetEnumItems()) do
if v.Value == value then
return v
end
end

error(
"BitBuffer.readEnum could not get value: `"
.. tostring(value)
.. "` is not a valid member of `"
.. name
.. "`",
2
)
end

local function readNumberRange()
assert(pointer + 64 <= bitCount, "BitBuffer.readNumberRange cannot read past the end of the stream")

return NumberRange.new(readFloat32(), readFloat32())
end

local function readNumberSequence()
assert(pointer + 32 <= bitCount, "BitBuffer.readNumberSequence cannot read past the end of the stream")

local keypointCount = readUInt32()

assert(pointer + keypointCount * 96, "BitBuffer.readColorSequence cannot read past the end of the stream")

local keypoints = table.create(keypointCount)

-- As it turns out, creating a NumberSequence with a negative value as its first argument (in the first and second constructor)
-- creates NumberSequenceKeypoints with negative envelopes. The envelope is read and saved properly, as you would expect,
-- but you can't create a NumberSequence with a negative envelope if you're using a table of keypoints (which is happening here).
-- If you're confused, run this snippet: NumberSequence.new(NumberSequence.new(-1).Keypoints)
-- As a result, there has to be some branching logic in this function.
-- ColorSequences don't have envelopes so it's not necessary for them.

for i = 1, keypointCount do
local time, value, envelope = readFloat32(), readFloat32(), readFloat32()
if value < 0 then
envelope = nil
end
keypoints[i] = NumberSequenceKeypoint.new(time, value, envelope)
end

return NumberSequence.new(keypoints)
end

local function readColorSequence()
assert(pointer + 32 <= bitCount, "BitBuffer.readColorSequence cannot read past the end of the stream")

local keypointCount = readUInt32()

assert(pointer + keypointCount * 56, "BitBuffer.readColorSequence cannot read past the end of the stream")

local keypoints = table.create(keypointCount)

for i = 1, keypointCount do
keypoints[i] = ColorSequenceKeypoint.new(readFloat32(), Color3.fromRGB(readByte(), readByte(), readByte()))
end

return ColorSequence.new(keypoints)
end

return {
dumpBinary = dumpBinary,
dumpString = dumpString,
dumpHex = dumpHex,
dumpBase64 = dumpBase64,
exportChunk = exportChunk,
exportBase64Chunk = exportBase64Chunk,
exportHexChunk = exportHexChunk,

crc32 = crc32,
getLength = getLength,
getByteLength = getByteLength,
getPointer = getPointer,
setPointer = setPointer,
setPointerFromEnd = setPointerFromEnd,
getPointerByte = getPointerByte,
setPointerByte = setPointerByte,
setPointerByteFromEnd = setPointerByteFromEnd,
isFinished = isFinished,

writeBits = writeBits,
writeByte = writeByte,
writeUnsigned = writeUnsigned,
writeSigned = writeSigned,
writeFloat = writeFloat,
writeBase64 = writeBase64,
writeString = writeString,
writeTerminatedString = writeTerminatedString,
writeSetLengthString = writeSetLengthString,
writeField = writeField,

writeUInt8 = writeUInt8,
writeUInt16 = writeUInt16,
writeUInt32 = writeUInt32,
writeInt8 = writeInt8,
writeInt16 = writeInt16,
writeInt32 = writeInt32,

writeFloat16 = writeFloat16,
writeFloat32 = writeFloat32,
writeFloat64 = writeFloat64,

writeBrickColor = writeBrickColor,
writeColor3 = writeColor3,
writeCFrame = writeCFrame,
writeVector3 = writeVector3,
writeVector2 = writeVector2,
writeUDim2 = writeUDim2,
writeUDim = writeUDim,
writeRay = writeRay,
writeRect = writeRect,
writeRegion3 = writeRegion3,
writeEnum = writeEnum,
writeNumberRange = writeNumberRange,
writeNumberSequence = writeNumberSequence,
writeColorSequence = writeColorSequence,

readBits = readBits,
readByte = readByte,
readUnsigned = readUnsigned,
readSigned = readSigned,
readFloat = readFloat,
readString = readString,
readTerminatedString = readTerminatedString,
readSetLengthString = readSetLengthString,
readField = readField,

readUInt8 = readUInt8,
readUInt16 = readUInt16,
readUInt32 = readUInt32,
readInt8 = readInt8,
readInt16 = readInt16,
readInt32 = readInt32,

readFloat16 = readFloat16,
readFloat32 = readFloat32,
readFloat64 = readFloat64,

readBrickColor = readBrickColor,
readColor3 = readColor3,
readCFrame = readCFrame,
readVector3 = readVector3,
readVector2 = readVector2,
readUDim2 = readUDim2,
readUDim = readUDim,
readRay = readRay,
readRect = readRect,
readRegion3 = readRegion3,
readEnum = readEnum,
readNumberRange = readNumberRange,
readNumberSequence = readNumberSequence,
readColorSequence = readColorSequence,
}
end

return bitBuffer
modules/Constraints.lua
local Constraints = {}

function Constraints.motor6D(p0, p1, name)
local motor = Instance.new("Motor6D")
motor.Part0 = p0
motor.Part1 = p1
motor.Name = name or p1.Name
motor.Parent = p0

return motor
end

function Constraints.weldConstraint(p0, p1, name)
local weld = Instance.new("WeldConstraint")
weld.Part0 = p0
weld.Part1 = p1
weld.Name = name or p1.Name
weld.Parent = p0

return weld
end

function Constraints.weld(p0, p1, name)
local weld = Instance.new("Weld")
weld.Part0 = p0
weld.Part1 = p1
weld.Name = name or p1.Name
weld.Parent = p0

return weld
end

return Constraints
modules/Cooldown.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Signal)


local Cooldown = {}
Cooldown.__index = Cooldown

function Cooldown.new(initial)
local self = setmetatable({}, Cooldown)
self.cooldown = initial
self._time = os.clock() - initial

self.CooldownUpdated = Signal.new()

return self
end

function Cooldown:IsFinished()
local now = os.clock()
return now - self._time >= self.cooldown
end

function Cooldown:Update()
local now = os.clock()
self._time = now

self.CooldownUpdated:Fire()
end

function Cooldown:SetNewCooldown(cooldown)
cooldown = cooldown or self.cooldown

self._time = os.clock()
self.cooldown = cooldown
end

function Cooldown:GetRemainingTime()
local delta = os.clock() - self._time
return math.clamp(self.cooldown - delta, 0, self.cooldown)
end

function Cooldown:Finish()
self._time = os.clock() - self.cooldown
end

return Cooldown
modules/MathUtils.lua
--!native
local MathUtils = {}

function MathUtils:EvalColorSequence(sequence: ColorSequence, time: number)
-- If time is 0 or 1, return the first or last value respectively
if time == 0 then
return sequence.Keypoints[1].Value
elseif time == 1 then
return sequence.Keypoints[#sequence.Keypoints].Value
end

-- Otherwise, step through each sequential pair of keypoints
for i = 1, #sequence.Keypoints - 1 do
local thisKeypoint = sequence.Keypoints[i]
local nextKeypoint = sequence.Keypoints[i + 1]
if time >= thisKeypoint.Time and time < nextKeypoint.Time then
-- Calculate how far alpha lies between the points
local alpha = (time - thisKeypoint.Time) / (nextKeypoint.Time - thisKeypoint.Time)
-- Evaluate the real value between the points using alpha
return Color3.new(
(nextKeypoint.Value.R - thisKeypoint.Value.R) * alpha + thisKeypoint.Value.R,
(nextKeypoint.Value.G - thisKeypoint.Value.G) * alpha + thisKeypoint.Value.G,
(nextKeypoint.Value.B - thisKeypoint.Value.B) * alpha + thisKeypoint.Value.B
)
end
end
end

return MathUtils
modules/Quaternion.lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
return require(ReplicatedFirst.Chickynoid.Shared.Simulation.Quaternion)
modules/Signal.lua
-- -----------------------------------------------------------------------------
-- Batched Yield-Safe Signal Implementation --
-- This is a Signal class which has effectively identical behavior to a --
-- normal RBXScriptSignal, with the only difference being a couple extra --
-- stack frames at the bottom of the stack trace when an error is thrown. --
-- This implementation caches runner coroutines, so the ability to yield in --
-- the signal handlers comes at minimal extra cost over a naive signal --
-- implementation that either always or never spawns a thread. --
-- --
-- License: --
-- Licensed under the MIT license. --
-- --
-- Authors: --
-- stravant - July 31st, 2021 - Created the file. --
-- sleitnick - August 3rd, 2021 - Modified for Knit. --
-- -----------------------------------------------------------------------------

-- Signal types
export type Connection = {
Disconnect: (self: Connection) -> (),
Destroy: (self: Connection) -> (),
Connected: boolean,
}

export type Signal<T...> = {
Fire: (self: Signal<T...>, T...) -> (),
FireDeferred: (self: Signal<T...>, T...) -> (),
Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
Once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
DisconnectAll: (self: Signal<T...>) -> (),
GetConnections: (self: Signal<T...>) -> { Connection },
Destroy: (self: Signal<T...>) -> (),
Wait: (self: Signal<T...>) -> T...,
}

-- The currently idle thread to run the next handler on
local freeRunnerThread = nil

-- Function which acquires the currently idle handler runner thread, runs the
-- function fn on it, and then releases the thread, returning it to being the
-- currently idle one.
-- If there was a currently idle runner thread already, that's okay, that old
-- one will just get thrown and eventually GCed.
local function acquireRunnerThreadAndCallEventHandler(fn, ...)
local acquiredRunnerThread = freeRunnerThread
freeRunnerThread = nil
fn(...)
-- The handler finished running, this runner thread is free again.
freeRunnerThread = acquiredRunnerThread
end

-- Coroutine runner that we create coroutines of. The coroutine can be
-- repeatedly resumed with functions to run followed by the argument to run
-- them with.
local function runEventHandlerInFreeThread(...)
acquireRunnerThreadAndCallEventHandler(...)
while true do
acquireRunnerThreadAndCallEventHandler(coroutine.yield())
end
end

--[=[
@within Signal
@interface SignalConnection
.Connected boolean
.Disconnect (SignalConnection) -> ()

Represents a connection to a signal.
```lua
local connection = signal:Connect(function() end)
print(connection.Connected) --> true
connection:Disconnect()
print(connection.Connected) --> false
```
]=]

-- Connection class
local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
if not self.Connected then
return
end
self.Connected = false

-- Unhook the node, but DON'T clear it. That way any fire calls that are
-- currently sitting on this node will be able to iterate forwards off of
-- it, but any subsequent fire calls will not hit it, and it will be GCed
-- when no more fire calls are sitting on it.
if self._signal._handlerListHead == self then
self._signal._handlerListHead = self._next
else
local prev = self._signal._handlerListHead
while prev and prev._next ~= self do
prev = prev._next
end
if prev then
prev._next = self._next
end
end
end

Connection.Destroy = Connection.Disconnect

-- Make Connection strict
setmetatable(Connection, {
__index = function(_tb, key)
error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
end,
__newindex = function(_tb, key, _value)
error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
end,
})

--[=[
@within Signal
@type ConnectionFn (...any) -> ()

A function connected to a signal.
]=]

--[=[
@class Signal

A Signal is a data structure that allows events to be dispatched
and observed.

This implementation is a direct copy of the de facto standard, [GoodSignal](https://devforum.roblox.com/t/lua-signal-class-comparison-optimal-goodsignal-class/1387063),
with some added methods and typings.

For example:
```lua
local signal = Signal.new()

-- Subscribe to a signal:
signal:Connect(function(msg)
print("Got message:", msg)
end)

-- Dispatch an event:
signal:Fire("Hello world!")
```
]=]
local Signal = {}
Signal.__index = Signal

--[=[
Constructs a new Signal

@return Signal
]=]
function Signal.new<T...>(): Signal<T...>
local self = setmetatable({
_handlerListHead = false,
_proxyHandler = nil,
_yieldedThreads = nil,
}, Signal)

return self
end

--[=[
Constructs a new Signal that wraps around an RBXScriptSignal.

@param rbxScriptSignal RBXScriptSignal -- Existing RBXScriptSignal to wrap
@return Signal

For example:
```lua
local signal = Signal.Wrap(workspace.ChildAdded)
signal:Connect(function(part) print(part.Name .. " added") end)
Instance.new("Part").Parent = workspace
```
]=]
function Signal.Wrap<T...>(rbxScriptSignal: RBXScriptSignal): Signal<T...>
assert(
typeof(rbxScriptSignal) == "RBXScriptSignal",
"Argument #1 to Signal.Wrap must be a RBXScriptSignal; got " .. typeof(rbxScriptSignal)
)

local signal = Signal.new()
signal._proxyHandler = rbxScriptSignal:Connect(function(...)
signal:Fire(...)
end)

return signal
end

--[=[
Checks if the given object is a Signal.

@param obj any -- Object to check
@return boolean -- `true` if the object is a Signal.
]=]
function Signal.Is(obj: any): boolean
return type(obj) == "table" and getmetatable(obj) == Signal
end

--[=[
@param fn ConnectionFn
@return SignalConnection

Connects a function to the signal, which will be called anytime the signal is fired.
```lua
signal:Connect(function(msg, num)
print(msg, num)
end)

signal:Fire("Hello", 25)
```
]=]
function Signal:Connect(fn)
local connection = setmetatable({
Connected = true,
_signal = self,
_fn = fn,
_next = false,
}, Connection)

if self._handlerListHead then
connection._next = self._handlerListHead
self._handlerListHead = connection
else
self._handlerListHead = connection
end

return connection
end

--[=[
@deprecated v1.3.0 -- Use `Signal:Once` instead.
@param fn ConnectionFn
@return SignalConnection
]=]
function Signal:ConnectOnce(fn)
return self:Once(fn)
end

--[=[
@param fn ConnectionFn
@return SignalConnection

Connects a function to the signal, which will be called the next time the signal fires. Once
the connection is triggered, it will disconnect itself.
```lua
signal:Once(function(msg, num)
print(msg, num)
end)

signal:Fire("Hello", 25)
signal:Fire("This message will not go through", 10)
```
]=]
function Signal:Once(fn)
local connection
local done = false

connection = self:Connect(function(...)
if done then
return
end

done = true
connection:Disconnect()
fn(...)
end)

return connection
end

function Signal:GetConnections()
local items = {}

local item = self._handlerListHead
while item do
table.insert(items, item)
item = item._next
end

return items
end

-- Disconnect all handlers. Since we use a linked list it suffices to clear the
-- reference to the head handler.
--[=[
Disconnects all connections from the signal.
```lua
signal:DisconnectAll()
```
]=]
function Signal:DisconnectAll()
local item = self._handlerListHead
while item do
item.Connected = false
item = item._next
end
self._handlerListHead = false

local yieldedThreads = rawget(self, "_yieldedThreads")
if yieldedThreads then
for thread in yieldedThreads do
if coroutine.status(thread) == "suspended" then
warn(debug.traceback(thread, "signal disconnected; yielded thread cancelled", 2))
task.cancel(thread)
end
end
table.clear(self._yieldedThreads)
end
end

-- Signal:Fire(...) implemented by running the handler functions on the
-- coRunnerThread, and any time the resulting thread yielded without returning
-- to us, that means that it yielded to the Roblox scheduler and has been taken
-- over by Roblox scheduling, meaning we have to make a new coroutine runner.
--[=[
@param ... any

Fire the signal, which will call all of the connected functions with the given arguments.
```lua
signal:Fire("Hello")

-- Any number of arguments can be fired:
signal:Fire("Hello", 32, {Test = "Test"}, true)
```
]=]
function Signal:Fire(...)
local item = self._handlerListHead
while item do
if item.Connected then
if not freeRunnerThread then
freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
end
task.spawn(freeRunnerThread, item._fn, ...)
end
item = item._next
end
end

--[=[
@param ... any

Same as `Fire`, but uses `task.defer` internally & doesn't take advantage of thread reuse.
```lua
signal:FireDeferred("Hello")
```
]=]
function Signal:FireDeferred(...)
local item = self._handlerListHead
while item do
local conn = item
task.defer(function(...)
if conn.Connected then
conn._fn(...)
end
end, ...)
item = item._next
end
end

--[=[
@return ... any
@yields

Yields the current thread until the signal is fired, and returns the arguments fired from the signal.
Yielding the current thread is not always desirable. If the desire is to only capture the next event
fired, using `Once` might be a better solution.
```lua
task.spawn(function()
local msg, num = signal:Wait()
print(msg, num) --> "Hello", 32
end)
signal:Fire("Hello", 32)
```
]=]
function Signal:Wait()
local yieldedThreads = rawget(self, "_yieldedThreads")
if not yieldedThreads then
yieldedThreads = {}
rawset(self, "_yieldedThreads", yieldedThreads)
end

local thread = coroutine.running()
yieldedThreads[thread] = true

self:Once(function(...)
yieldedThreads[thread] = nil
task.spawn(thread, ...)
end)

return coroutine.yield()
end

--[=[
Cleans up the signal.

Technically, this is only necessary if the signal is created using
`Signal.Wrap`. Connections should be properly GC'd once the signal
is no longer referenced anywhere. However, it is still good practice
to include ways to strictly clean up resources. Calling `Destroy`
on a signal will also disconnect all connections immediately.
```lua
signal:Destroy()
```
]=]
function Signal:Destroy()
self:DisconnectAll()

local proxyHandler = rawget(self, "_proxyHandler")
if proxyHandler then
proxyHandler:Disconnect()
end
end

-- Make signal strict
setmetatable(Signal, {
__index = function(_tb, key)
error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
end,
__newindex = function(_tb, key, _value)
error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
end,
})

return table.freeze({
new = Signal.new,
Wrap = Signal.Wrap,
Is = Signal.Is,
})
modules/Sound.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Sound = {}

function Sound.play(id, positionOrPart, volume)
volume = volume or 1

local sound
if typeof(id) == "Instance" and id:IsA("Sound") then
sound = id:Clone()
if sound.SoundId == "" then
sound.SoundId = sound:GetAttribute("SoundId")
end
else
if tonumber(id) == id then
id = "rbxassetid://".. tostring(id)
end
sound = Instance.new("Sound")
sound.SoundId = id
sound.Volume = volume
end

local attachment = Instance.new("Attachment")
sound.Parent = attachment
if typeof(positionOrPart) == "Vector3" then
attachment.WorldPosition = positionOrPart
attachment.Parent = workspace.Terrain
elseif typeof(positionOrPart) == "Instance" then
attachment.Parent = positionOrPart
end

local soundDelay = sound:GetAttribute("PlayDelay")
if soundDelay and soundDelay > 0 then
task.wait(soundDelay)
end
sound:Play()

local fadeDelay = sound:GetAttribute("FadeDelay")
if fadeDelay then
task.delay(fadeDelay, function()
local fadeTime = sound:GetAttribute("FadeTime") or 1
TweenService:Create(sound, TweenInfo.new(fadeTime), {
Volume = 0,
}):Play()
end)
end

sound.Ended:Connect(function()
attachment:Destroy()
end)
return sound
end

function Sound.playInReplicatedStorage(sound: Sound, volume)
volume = volume or 1

sound = sound:Clone()
if sound.SoundId == "" then
sound.SoundId = sound:GetAttribute("SoundId")
end
sound.Parent = ReplicatedStorage.EffectStorage

local soundDelay = sound:GetAttribute("PlayDelay")
if soundDelay and soundDelay > 0 then
task.delay(soundDelay, function()
sound:Play()
end)
else
sound:Play()
end

local fadeDelay = sound:GetAttribute("FadeDelay")
if fadeDelay then
task.delay(fadeDelay, function()
local fadeTime = sound:GetAttribute("FadeTime") or 1
TweenService:Create(sound, TweenInfo.new(fadeTime), {
Volume = 0,
}):Play()
end)
end

sound.Ended:Connect(function()
sound:Destroy()
end)

local despawnTime = sound:GetAttribute("DespawnTime")
if despawnTime == nil and sound.Looped then
despawnTime = 10
end
if despawnTime then
game.Debris:AddItem(sound, despawnTime)
end

return sound
end

return Sound
modules/Spring.lua
--[=[
A physical model of a spring, useful in many applications.
A spring is an object that will compute based upon Hooke's law. Properties only evaluate
upon index making this model good for lazy applications.
```lua
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local spring = Spring.new(Vector3.new(0, 0, 0))
RunService.RenderStepped:Connect(function()
if UserInputService:IsKeyDown(Enum.KeyCode.W) then
spring.Target = Vector3.new(0, 0, 1)
else
spring.Target = Vector3.new(0, 0, 0)
end
print(spring.Position) -- A smoothed out version of the input keycode W
end)
```
A good visualization can be found here, provided by Defaultio:
https://www.desmos.com/calculator/hn2i9shxbz
@class Spring
]=]
local Spring = {}

--[=[
Constructs a new Spring at the position and target specified, of type T.
```lua
-- Linear spring
local linearSpring = Spring.new(0)
-- Vector2 spring
local vector2Spring = Spring.new(Vector2.new(0, 0))
-- Vector3 spring
local vector3Spring = Spring.new(Vector3.new(0, 0, 0))
```
@param initial T -- The initial parameter is a number or Vector3 (anything with * number and addition/subtraction).
@param clock? () -> number -- The clock function is optional, and is used to update the spring
@return Spring<T>
]=]
function Spring.new(initial, clock)
local target = initial or 0
clock = clock or os.clock
return setmetatable({
_clock = clock;
_time0 = clock();
_position0 = target;
_velocity0 = 0*target;
_target = target;
_damper = 1;
_speed = 1;
}, Spring)
end

--[=[
Impulses the spring, increasing velocity by the amount given. This is useful to make something shake,
like a Mac password box failing.
@param velocity T -- The velocity to impulse with
@return ()
]=]
function Spring:Impulse(velocity)
self.Velocity = self.Velocity + velocity
end

--[=[
Instantly skips the spring forwards by that amount time
@param delta number -- Time to skip forwards
@return ()
]=]
function Spring:TimeSkip(delta)
local now = self._clock()
local position, velocity = self:_positionVelocity(now+delta)
self._position0 = position
self._velocity0 = velocity
self._time0 = now
end

--[=[
The current position at the given clock time. Assigning the position will change the spring to have that position.
```lua
local spring = Spring.new(0)
print(spring.Position) --> 0
```
@prop Position T
@within Spring
]=]
--[=[
Alias for [Spring.Position](/api/Spring#Position)
@prop p T
@within Spring
]=]
--[=[
The current velocity. Assigning the velocity will change the spring to have that velocity.
```lua
local spring = Spring.new(0)
print(spring.Velocity) --> 0
```
@prop Velocity T
@within Spring
]=]
--[=[
Alias for [Spring.Velocity](/api/Spring#Velocity)
@prop v T
@within Spring
]=]
--[=[
The current target. Assigning the target will change the spring to have that target.
```lua
local spring = Spring.new(0)
print(spring.Target) --> 0
```
@prop Target T
@within Spring
]=]
--[=[
Alias for [Spring.Target](/api/Spring#Target)
@prop t T
@within Spring
]=]
--[=[
The current damper, defaults to 1. At 1 the spring is critically damped. At less than 1, it
will be underdamped, and thus, bounce, and at over 1, it will be critically damped.
@prop Damper number
@within Spring
]=]
--[=[
Alias for [Spring.Damper](/api/Spring#Damper)
@prop d number
@within Spring
]=]
--[=[
The speed, defaults to 1, but should be between [0, infinity)
@prop Speed number
@within Spring
]=]
--[=[
Alias for [Spring.Speed](/api/Spring#Speed)
@prop s number
@within Spring
]=]
--[=[
The current clock object to syncronize the spring against.
@prop Clock () -> number
@within Spring
]=]
function Spring:__index(index)
if Spring[index] then
return Spring[index]
elseif index == "Value" or index == "Position" or index == "p" then
local position, _ = self:_positionVelocity(self._clock())
return position
elseif index == "Velocity" or index == "v" then
local _, velocity = self:_positionVelocity(self._clock())
return velocity
elseif index == "Target" or index == "t" then
return self._target
elseif index == "Damper" or index == "d" then
return self._damper
elseif index == "Speed" or index == "s" then
return self._speed
elseif index == "Clock" then
return self._clock
else
error(("%q is not a valid member of Spring"):format(tostring(index)), 2)
end
end

function Spring:__newindex(index, value)
local now = self._clock()

if index == "Value" or index == "Position" or index == "p" then
local _, velocity = self:_positionVelocity(now)
self._position0 = value
self._velocity0 = velocity
self._time0 = now
elseif index == "Velocity" or index == "v" then
local position, _ = self:_positionVelocity(now)
self._position0 = position
self._velocity0 = value
self._time0 = now
elseif index == "Target" or index == "t" then
local position, velocity = self:_positionVelocity(now)
self._position0 = position
self._velocity0 = velocity
self._target = value
self._time0 = now
elseif index == "Damper" or index == "d" then
local position, velocity = self:_positionVelocity(now)
self._position0 = position
self._velocity0 = velocity
self._damper = value
self._time0 = now
elseif index == "Speed" or index == "s" then
local position, velocity = self:_positionVelocity(now)
self._position0 = position
self._velocity0 = velocity
self._speed = value < 0 and 0 or value
self._time0 = now
elseif index == "Clock" then
local position, velocity = self:_positionVelocity(now)
self._position0 = position
self._velocity0 = velocity
self._clock = value
self._time0 = value()
else
error(("%q is not a valid member of Spring"):format(tostring(index)), 2)
end
end

function Spring:_positionVelocity(now)
local p0 = self._position0
local v0 = self._velocity0
local p1 = self._target
local d = self._damper
local s = self._speed

local t = s*(now - self._time0)
local d2 = d*d

local h, si, co
if d2 < 1 then
h = math.sqrt(1 - d2)
local ep = math.exp(-d*t)/h
co, si = ep*math.cos(h*t), ep*math.sin(h*t)
elseif d2 == 1 then
h = 1
local ep = math.exp(-d*t)/h
co, si = ep, ep*t
else
h = math.sqrt(d2 - 1)
local u = math.exp((-d + h)*t)/(2*h)
local v = math.exp((-d - h)*t)/(2*h)
co, si = u + v, u - v
end

local a0 = h*co + d*si
local a1 = 1 - (h*co + d*si)
local a2 = si/s

local b0 = -s*si
local b1 = s*si
local b2 = h*co - d*si

return
a0*p0 + a1*p1 + a2*v0,
b0*p0 + b1*p1 + b2*v0
end

return Spring
modules/Trove.lua
-- Trove
-- Stephen Leitnick
-- October 16, 2021

local FN_MARKER = newproxy()
local THREAD_MARKER = newproxy()
local GENERIC_OBJECT_CLEANUP_METHODS = { "Destroy", "Disconnect", "destroy", "disconnect" }

local RunService = game:GetService("RunService")

type Trove = {
__index: Trove,

new: () -> (Trove),
Extend: (self: Trove) -> (Trove),
Construct: (self: Trove, class: table | () -> (), any...) -> (),
Connect: (self: Trove, signal: RBXScriptSignal, fn: (any...) -> ()) -> (RBXScriptConnection),
BindToRenderStep: (self: Trove, name: string, priority: number, fn: (dt: number) -> ()) -> (),
AddPromise: (self: Trove, promise: any) -> (),
Add: (self: Trove, object: any, cleanupMethod: string?) -> (any),
Remove: (self: Trove, object: any) -> (any),
Clean: (self: Trove) -> (),
AttachToInstance: (self: Trove, instance: Instance) -> (RBXScriptConnection),
Destroy: (self: Trove) -> (),
}

local function GetObjectCleanupFunction(object, cleanupMethod)
local t = typeof(object)
if t == "function" then
return FN_MARKER
elseif t == "thread" then
return THREAD_MARKER
end
if cleanupMethod then
return cleanupMethod
end
if t == "Instance" then
return "Destroy"
elseif t == "RBXScriptConnection" then
return "Disconnect"
elseif t == "table" then
for _, genericCleanupMethod in GENERIC_OBJECT_CLEANUP_METHODS do
if typeof(object[genericCleanupMethod]) == "function" then
return genericCleanupMethod
end
end
end
error("Failed to get cleanup function for object " .. t .. ": " .. tostring(object), 3)
end

local function AssertPromiseLike(object)
if
typeof(object) ~= "table"
or typeof(object.getStatus) ~= "function"
or typeof(object.finally) ~= "function"
or typeof(object.cancel) ~= "function"
then
error("Did not receive a Promise as an argument", 3)
end
end

--[=[
@class Trove
A Trove is helpful for tracking any sort of object during
runtime that needs to get cleaned up at some point.
]=]
local Trove = {} :: Trove
Trove.__index = Trove

--[=[
@return Trove
Constructs a Trove object.
]=]
function Trove.new()
local self = setmetatable({}, Trove)
self._objects = {}
self._cleaning = false
return self
end

--[=[
@return Trove
Creates and adds another trove to itself. This is just shorthand
for `trove:Construct(Trove)`. This is useful for contexts where
the trove object is present, but the class itself isn't.

:::note
This does _not_ clone the trove. In other words, the objects in the
trove are not given to the new constructed trove. This is simply to
construct a new Trove and add it as an object to track.
:::

```lua
local trove = Trove.new()
local subTrove = trove:Extend()

trove:Clean() -- Cleans up the subTrove too
```
]=]
function Trove:Extend()
if self._cleaning then
error("Cannot call trove:Extend() while cleaning", 2)
end
return self:Construct(Trove)
end

--[=[
Clones the given instance and adds it to the trove. Shorthand for
`trove:Add(instance:Clone())`.
]=]
function Trove:Clone(instance: Instance): Instance
if self._cleaning then
error("Cannot call trove:Clone() while cleaning", 2)
end
return self:Add(instance:Clone())
end

--[=[
@param class table | (...any) -> any
@param ... any
@return any
Constructs a new object from either the
table or function given.

If a table is given, the table's `new`
function will be called with the given
arguments.

If a function is given, the function will
be called with the given arguments.

The result from either of the two options
will be added to the trove.

This is shorthand for `trove:Add(SomeClass.new(...))`
and `trove:Add(SomeFunction(...))`.

```lua
local Signal = require(somewhere.Signal)

-- All of these are identical:
local s = trove:Construct(Signal)
local s = trove:Construct(Signal.new)
local s = trove:Construct(function() return Signal.new() end)
local s = trove:Add(Signal.new())

-- Even Roblox instances can be created:
local part = trove:Construct(Instance, "Part")
```
]=]
function Trove:Construct(class, ...)
if self._cleaning then
error("Cannot call trove:Construct() while cleaning", 2)
end
local object = nil
local t = type(class)
if t == "table" then
object = class.new(...)
elseif t == "function" then
object = class(...)
end
return self:Add(object)
end

--[=[
@param signal RBXScriptSignal
@param fn (...: any) -> ()
@return RBXScriptConnection
Connects the function to the signal, adds the connection
to the trove, and then returns the connection.

This is shorthand for `trove:Add(signal:Connect(fn))`.

```lua
trove:Connect(workspace.ChildAdded, function(instance)
print(instance.Name .. " added to workspace")
end)
```
]=]
function Trove:Connect(signal, fn)
if self._cleaning then
error("Cannot call trove:Connect() while cleaning", 2)
end
return self:Add(signal:Connect(fn))
end

--[=[
@param name string
@param priority number
@param fn (dt: number) -> ()
Calls `RunService:BindToRenderStep` and registers a function in the
trove that will call `RunService:UnbindFromRenderStep` on cleanup.

```lua
trove:BindToRenderStep("Test", Enum.RenderPriority.Last.Value, function(dt)
-- Do something
end)
```
]=]
function Trove:BindToRenderStep(name: string, priority: number, fn: (dt: number) -> ())
if self._cleaning then
error("Cannot call trove:BindToRenderStep() while cleaning", 2)
end
RunService:BindToRenderStep(name, priority, fn)
self:Add(function()
RunService:UnbindFromRenderStep(name)
end)
end

--[=[
@param promise Promise
@return Promise
Gives the promise to the trove, which will cancel the promise if the trove is cleaned up or if the promise
is removed. The exact promise is returned, thus allowing chaining.

```lua
trove:AddPromise(doSomethingThatReturnsAPromise())
:andThen(function()
print("Done")
end)
-- Will cancel the above promise (assuming it didn't resolve immediately)
trove:Clean()

local p = trove:AddPromise(doSomethingThatReturnsAPromise())
-- Will also cancel the promise
trove:Remove(p)
```

:::caution Promise v4 Only
This is only compatible with the [roblox-lua-promise](https://eryn.io/roblox-lua-promise/) library, version 4.
:::
]=]
function Trove:AddPromise(promise)
if self._cleaning then
error("Cannot call trove:AddPromise() while cleaning", 2)
end
AssertPromiseLike(promise)
if promise:getStatus() == "Started" then
promise:finally(function()
if self._cleaning then
return
end
self:_findAndRemoveFromObjects(promise, false)
end)
self:Add(promise, "cancel")
end
return promise
end

--[=[
@param object any -- Object to track
@param cleanupMethod string? -- Optional cleanup name override
@return object: any
Adds an object to the trove. Once the trove is cleaned or
destroyed, the object will also be cleaned up.

The following types are accepted (e.g. `typeof(object)`):

| Type | Cleanup |
| ---- | ------- |
| `Instance` | `object:Destroy()` |
| `RBXScriptConnection` | `object:Disconnect()` |
| `function` | `object()` |
| `thread` | `task.cancel(object)` |
| `table` | `object:Destroy()` _or_ `object:Disconnect()` _or_ `object:destroy()` _or_ `object:disconnect()` |
| `table` with `cleanupMethod` | `object:<cleanupMethod>()` |

Returns the object added.

```lua
-- Add a part to the trove, then destroy the trove,
-- which will also destroy the part:
local part = Instance.new("Part")
trove:Add(part)
trove:Destroy()

-- Add a function to the trove:
trove:Add(function()
print("Cleanup!")
end)
trove:Destroy()

-- Standard cleanup from table:
local tbl = {}
function tbl:Destroy()
print("Cleanup")
end
trove:Add(tbl)

-- Custom cleanup from table:
local tbl = {}
function tbl:DoSomething()
print("Do something on cleanup")
end
trove:Add(tbl, "DoSomething")
```
]=]
function Trove:Add(object: any, cleanupMethod: string?): any
if self._cleaning then
error("Cannot call trove:Add() while cleaning", 2)
end
local cleanup = GetObjectCleanupFunction(object, cleanupMethod)
table.insert(self._objects, { object, cleanup })
return object
end

--[=[
@param object any -- Object to remove
Removes the object from the Trove and cleans it up.

```lua
local part = Instance.new("Part")
trove:Add(part)
trove:Remove(part)
```
]=]
function Trove:Remove(object: any): boolean
if self._cleaning then
error("Cannot call trove:Remove() while cleaning", 2)
end
return self:_findAndRemoveFromObjects(object, true)
end

--[=[
Cleans up all objects in the trove. This is
similar to calling `Remove` on each object
within the trove. The ordering of the objects
removed is _not_ guaranteed.
]=]
function Trove:Clean()
if self._cleaning then
return
end
self._cleaning = true
for _, obj in self._objects do
self:_cleanupObject(obj[1], obj[2])
end
table.clear(self._objects)
self._cleaning = false
end

function Trove:_findAndRemoveFromObjects(object: any, cleanup: boolean): boolean
local objects = self._objects
for i, obj in ipairs(objects) do
if obj[1] == object then
local n = #objects
objects[i] = objects[n]
objects[n] = nil
if cleanup then
self:_cleanupObject(obj[1], obj[2])
end
return true
end
end
return false
end

function Trove:_cleanupObject(object, cleanupMethod)
if cleanupMethod == FN_MARKER then
object()
elseif cleanupMethod == THREAD_MARKER then
pcall(task.cancel, object)
else
pcall(function()
object[cleanupMethod](object)
end)
end
end

--[=[
@param instance Instance
@return RBXScriptConnection
Attaches the trove to a Roblox instance. Once this
instance is removed from the game (parent or ancestor's
parent set to `nil`), the trove will automatically
clean up.

:::caution
Will throw an error if `instance` is not a descendant
of the game hierarchy.
:::
]=]
function Trove:AttachToInstance(instance: Instance)
if self._cleaning then
error("Cannot call trove:AttachToInstance() while cleaning", 2)
elseif not instance:IsDescendantOf(game) then
error("Instance is not a descendant of the game hierarchy", 2)
end
return self:Connect(instance.Destroying, function()
self:Destroy()
end)
end

--[=[
Alias for `trove:Clean()`.
]=]
function Trove:Destroy()
self:Clean()
end

return Trove
modules/TweenLib.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Maid = require(ReplicatedStorage.Modules.Maid)

local maid = Maid.new()


local function Lerp(a, b, t)
return a+(b-a)*t
end


local TweenLib = {}

function TweenLib.tweenBeamTransparency(beam: Beam, tweenInfo: TweenInfo, enabled)
if enabled then
beam.Enabled = true
end

local startTrans = beam.Transparency
if not beam:GetAttribute("Transparency") then
beam:SetAttribute("Transparency", startTrans)
end

local idxMap = {}

local goal = beam:GetAttribute("Transparency")
if not enabled then
local newKeypoints = {}
for _, keypoint: NumberSequenceKeypoint in pairs(goal.Keypoints) do
table.insert(newKeypoints, NumberSequenceKeypoint.new(keypoint.Time, 1))
end
goal = NumberSequence.new(newKeypoints)
end

for i, keypoint in pairs(goal.Keypoints) do
for _, startKeypoint in pairs(startTrans.Keypoints) do
if startKeypoint.Time == keypoint.Time then
idxMap[i] = startKeypoint
end
end
end

maid[beam] = nil

local start = time()
maid[beam] = RunService.RenderStepped:Connect(function()
local now = time()
local deltaTime = now - start

if beam == nil then
maid[beam] = nil
return
end

local alpha = math.clamp(deltaTime / tweenInfo.Time, 0, 1)
local tweenAlpha = TweenService:GetValue(alpha, tweenInfo.EasingStyle, tweenInfo.EasingDirection)

local newKeypoints = {}
for i, keypoint: NumberSequenceKeypoint in pairs(goal.Keypoints) do
table.insert(newKeypoints, NumberSequenceKeypoint.new(
keypoint.Time,
Lerp(idxMap[i].Value, keypoint.Value, tweenAlpha)
))
end
beam.Transparency = NumberSequence.new(newKeypoints)

if deltaTime >= tweenInfo.Time then
beam.Enabled = enabled
maid[beam] = nil
return
end
end)
end

return TweenLib
modules/spr.lua
--!strict
---------------------------------------------------------------------
-- spr - Spring-driven motion library
--
-- Copyright (c) 2023 Fractality. All rights reserved.
-- Released under the MIT license.
--
-- Docs & license can be found at https://github.com/Fraktality/spr
--
-- API Summary:
--
-- spr.target(
-- Instance obj,
-- number dampingRatio,
-- number undampedFrequency,
-- dict<string, Variant> targetProperties)
--
-- Animates the given properties towardes the target values,
-- given damping ratio and undamped frequency.
--
--
-- spr.stop(
-- Instance obj[,
-- string property])
--
-- Stops the specified property on an Instance from animating.
-- If no property is specified, all properties of the Instance
-- will stop animating.
--
-- Visualizer: https://www.desmos.com/calculator/rzvw27ljh9
---------------------------------------------------------------------

local STRICT_RUNTIME_TYPES = true -- assert on parameter and property type mismatch
local SLEEP_OFFSET_SQ_LIMIT = (1/3840)^2 -- square of the offset sleep limit
local SLEEP_VELOCITY_SQ_LIMIT = 1e-2^2 -- square of the velocity sleep limit
local SLEEP_ROTATION_OFFSET = math.rad(0.01) -- rad
local SLEEP_ROTATION_VELOCITY = math.rad(0.1) -- rad/s
local EPS = 1e-5 -- epsilon for stability checks around pathological frequency/damping values
local AXIS_MATRIX_EPS = 1e-6 -- epsilon for converting from axis-angle to matrix

local RunService = game:GetService("RunService")

local pi = math.pi
local exp = math.exp
local sin = math.sin
local cos = math.cos
local min = math.min
local sqrt = math.sqrt
local round = math.round

local function magnitudeSq(vec: {number})
local out = 0
for _, v in vec do
out += v^2
end
return out
end

local function distanceSq(vec0: {number}, vec1: {number})
local out = 0
for i0, v0 in vec0 do
out += (vec1[i0] - v0)^2
end
return out
end

type TypeMetadata<T> = {
springType: (dampingRatio: number, frequency: number, pos: number, typedat: TypeMetadata<T>, rawTarget: T) -> LinearSpring<T>,
toIntermediate: (T) -> {number},
fromIntermediate: ({number}) -> T,
}

-- Spring for an array of linear values
local LinearSpring = {}

type LinearSpring<T> = typeof(setmetatable({} :: {
d: number,
f: number,
g: {number},
p: {number},
v: {number},
typedat: TypeMetadata<T>,
rawTarget: T,
}, LinearSpring))

do
LinearSpring.__index = LinearSpring

function LinearSpring.new<T>(dampingRatio: number, frequency: number, pos: T, rawGoal: T, typedat)
local linearPos = typedat.toIntermediate(pos)
return setmetatable(
{
d = dampingRatio,
f = frequency,
g = linearPos,
p = linearPos,
v = table.create(#linearPos, 0),
typedat = typedat,
rawGoal = rawGoal
},
LinearSpring
)
end

function LinearSpring.setGoal<T>(self, goal: T)
self.rawGoal = goal
self.g = self.typedat.toIntermediate(goal)
end

function LinearSpring.setDampingRatio<T>(self: LinearSpring<T>, dampingRatio: number)
self.d = dampingRatio
end

function LinearSpring.setFrequency<T>(self: LinearSpring<T>, frequency: number)
self.f = frequency
end

function LinearSpring.canSleep<T>(self)
if magnitudeSq(self.v) > SLEEP_VELOCITY_SQ_LIMIT then
return false
end

if distanceSq(self.p, self.g) > SLEEP_OFFSET_SQ_LIMIT then
return false
end

return true
end

function LinearSpring.step<T>(self: LinearSpring<T>, dt: number)
-- Advance the spring simulation by dt seconds.
-- Take the damped harmonic oscillator ODE:
-- f^2*(X[t] - g) + 2*d*f*X'[t] + X''[t] = 0
-- Where X[t] is position at time t, g is target position,
-- f is undamped angular frequency, and d is damping ratio.
-- Apply constant initial conditions:
-- X[0] = p0
-- X'[0] = v0
-- Solve the IVP to get analytic expressions for X[t] and X'[t].
-- The solution takes one of three forms for 0<=d<1, d=1, and d>1

local d = self.d
local f = self.f*2*pi -- Hz -> Rad/s
local g = self.g
local p = self.p
local v = self.v

if d == 1 then -- critically damped
local q = exp(-f*dt)
local w = dt*q

local c0 = q + w*f
local c2 = q - w*f
local c3 = w*f*f

for idx = 1, #p do
local o = p[idx] - g[idx]
p[idx] = o*c0 + v[idx]*w + g[idx]
v[idx] = v[idx]*c2 - o*c3
end

elseif d < 1 then -- underdamped
local q = exp(-d*f*dt)
local c = sqrt(1 - d*d)

local i = cos(dt*f*c)
local j = sin(dt*f*c)

-- Damping ratios approaching 1 can cause division by very small numbers.
-- To mitigate that, group terms around z=j/c and find an approximation for z.
-- Start with the definition of z:
-- z = sin(dt*f*c)/c
-- Substitute a=dt*f:
-- z = sin(a*c)/c
-- Take the Maclaurin expansion of z with respect to c:
-- z = a - (a^3*c^2)/6 + (a^5*c^4)/120 + O(c^6)
-- z ≈ a - (a^3*c^2)/6 + (a^5*c^4)/120
-- Rewrite in Horner form:
-- z ≈ a + ((a*a)*(c*c)*(c*c)/20 - c*c)*(a*a*a)/6

local z
if c > EPS then
z = j/c
else
local a = dt*f
z = a + ((a*a)*(c*c)*(c*c)/20 - c*c)*(a*a*a)/6
end

-- Frequencies approaching 0 present a similar problem.
-- We want an approximation for y as f approaches 0, where:
-- y = sin(dt*f*c)/(f*c)
-- Substitute b=dt*c:
-- y = sin(b*c)/b
-- Now reapply the process from z.

local y
if f*c > EPS then
y = j/(f*c)
else
local b = f*c
y = dt + ((dt*dt)*(b*b)*(b*b)/20 - b*b)*(dt*dt*dt)/6
end

for idx = 1, #p do
local o = p[idx] - g[idx]
p[idx] = (o*(i + z*d) + v[idx]*y)*q + g[idx]
v[idx] = (v[idx]*(i - z*d) - o*(z*f))*q
end

else -- overdamped
local c = sqrt(d*d - 1)

local r1 = -f*(d - c)
local r2 = -f*(d + c)

local ec1 = exp(r1*dt)
local ec2 = exp(r2*dt)

for idx = 1, #p do
local o = p[idx] - g[idx]
local co2 = (v[idx] - o*r1)/(2*f*c)
local co1 = ec1*(o - co2)

p[idx] = co1 + co2*ec2 + g[idx]
v[idx] = co1*r1 + co2*ec2*r2
end
end

return self.typedat.fromIntermediate(self.p)
end
end

local RotationSpring = {}

type RotationSpring = typeof(setmetatable({} :: {
d: number,
f: number,
g: CFrame,
p: CFrame,
v: Vector3,
}, RotationSpring))

do
RotationSpring.__index = RotationSpring

local function angleBetween(c0: CFrame, c1: CFrame)
local _, angle = (c1:ToObjectSpace(c0)):ToAxisAngle()
return math.abs(angle)
end

local function matrixToAxis(m: CFrame)
local axis, angle = m:ToAxisAngle()
return axis*angle
end

local function axisToMatrix(v: Vector3)
local mag = v.Magnitude
if mag > AXIS_MATRIX_EPS then
return CFrame.fromAxisAngle(v.Unit, mag)
end
return CFrame.identity
end

function RotationSpring.new(d: number, f: number, p: CFrame, g: CFrame)
return setmetatable(
{
d = d,
f = f,
g = g,
p = p,
v = Vector3.zero
},
RotationSpring
)
end

function RotationSpring.setGoal(self: RotationSpring, value: CFrame)
self.g = value
end

function RotationSpring.setDampingRatio(self: RotationSpring, dampingRatio: number)
self.d = dampingRatio
end

function RotationSpring.setFrequency(self: RotationSpring, frequency: number)
self.f = frequency
end

function RotationSpring.canSleep(self: RotationSpring)
local sleepP = angleBetween(self.p, self.g) < SLEEP_ROTATION_OFFSET
local sleepV = self.v.Magnitude < SLEEP_ROTATION_VELOCITY
return sleepP and sleepV
end

function RotationSpring.step(self: RotationSpring, dt: number): CFrame
local d = self.d
local f = self.f*2*pi
local g = self.g
local p0 = self.p
local v0 = self.v

local offset = matrixToAxis(p0*g:Inverse())
local decay = exp(-d*f*dt)

local pt: CFrame
local vt: Vector3

if d == 1 then -- critically damped
local w = dt*decay

pt = axisToMatrix((offset*(1 + f*dt) + v0*dt)*decay)*g
vt = (v0*(1 - dt*f) - offset*(dt*f*f))*decay

elseif d < 1 then -- underdamped
local c = sqrt(1 - d*d)

local i = cos(dt*f*c)
local j = sin(dt*f*c)

local y = j/(f*c)
local z = j/c

pt = axisToMatrix((offset*(i + z*d) + v0*y)*decay)*g
vt = (v0*(i - z*d) - offset*(z*f))*decay

else -- overdamped
local c = sqrt(d*d - 1)

local r1 = -f*(d - c)
local r2 = -f*(d + c)

local co2 = (v0 - offset*r1)/(2*f*c)
local co1 = offset - co2

local e1 = co1*exp(r1*dt)
local e2 = co2*exp(r2*dt)

pt = axisToMatrix(e1 + e2)*g
vt = e1*r1 + e2*r2
end

self.p = pt
self.v = vt

return pt
end
end

-- Defined early to be used by CFrameSpring
local typeMetadata_Vector3 = {
springType = LinearSpring.new,

toIntermediate = function(value)
return {value.X, value.Y, value.Z}
end,

fromIntermediate = function(value: {number})
return Vector3.new(value[1], value[2], value[3])
end,
}

-- Encapsulates a CFrame - Separates translation from rotation
local CFrameSpring = {}
do
CFrameSpring.__index = CFrameSpring

function CFrameSpring.new(
dampingRatio: number,
frequency: number,
valueCurrent: CFrame,
valueGoal: CFrame,
_: any
)
return setmetatable(
{
rawGoal = valueGoal,
_position = LinearSpring.new(dampingRatio, frequency, valueCurrent.Position, valueGoal.Position, typeMetadata_Vector3),
_rotation = RotationSpring.new(dampingRatio, frequency, valueCurrent.Rotation, valueGoal.Rotation)
},
CFrameSpring
)
end

function CFrameSpring:setGoal(value: CFrame)
self.rawGoal = value
self._position:setGoal(value.Position)
self._rotation:setGoal(value.Rotation)
end

function CFrameSpring:setDampingRatio(value: number)
self._position:setDampingRatio(value)
self._rotation:setDampingRatio(value)
end

function CFrameSpring:setFrequency(value: number)
self._position:setFrequency(value)
self._rotation:setFrequency(value)
end

function CFrameSpring:canSleep()
return self._position:canSleep() and self._rotation:canSleep()
end

function CFrameSpring:step(dt): CFrame
local p: Vector3 = self._position:step(dt)
local r: CFrame = self._rotation:step(dt)
return r + p
end
end

-- Color conversions
local rgbToLuv
local luvToRgb
do
local function inverseGammaCorrectD65(c)
return c < 0.0404482362771076 and c/12.92 or 0.87941546140213*(c + 0.055)^2.4
end

local function gammaCorrectD65(c)
return c < 3.1306684425e-3 and 12.92*c or 1.055*c^(1/2.4) - 0.055
end

function rgbToLuv(value: Color3): {number}
-- convert RGB to a variant of cieluv space
local r, g, b = value.R, value.G, value.B

-- D65 sRGB inverse gamma correction
r = inverseGammaCorrectD65(r)
g = inverseGammaCorrectD65(g)
b = inverseGammaCorrectD65(b)

-- sRGB -> xyz
local x = 0.9257063972951867*r - 0.8333736323779866*g - 0.09209820666085898*b
local y = 0.2125862307855956*r + 0.71517030370341085*g + 0.0722004986433362*b
local z = 3.6590806972265883*r + 11.4426895800574232*g + 4.1149915024264843*b

-- xyz -> scaled cieluv
local l = y > 0.008856451679035631 and 116*y^(1/3) - 16 or 903.296296296296*y

local u, v
if z > 1e-14 then
u = l*x/z
v = l*(9*y/z - 0.46832)
else
u = -0.19783*l
v = -0.46832*l
end

return {l, u, v}
end

function luvToRgb(value: {number}): Color3
-- convert back from modified cieluv to rgb space
local l = value[1]
if l < 0.0197955 then
return Color3.new(0, 0, 0)
end
local u = value[2]/l + 0.19783
local v = value[3]/l + 0.46832

-- cieluv -> xyz
local y = (l + 16)/116
y = y > 0.206896551724137931 and y*y*y or 0.12841854934601665*y - 0.01771290335807126
local x = y*u/v
local z = y*((3 - 0.75*u)/v - 5)

-- xyz -> D65 sRGB
local r = 7.2914074*x - 1.5372080*y - 0.4986286*z
local g = -2.1800940*x + 1.8757561*y + 0.0415175*z
local b = 0.1253477*x - 0.2040211*y + 1.0569959*z

-- clamp minimum sRGB component
if r < 0 and r < g and r < b then
r, g, b = 0, g - r, b - r
elseif g < 0 and g < b then
r, g, b = r - g, 0, b - g
elseif b < 0 then
r, g, b = r - b, g - b, 0
end

-- gamma correction from D65
-- clamp to avoid undesirable overflow wrapping behavior on certain properties (e.g. BasePart.Color)
return Color3.new(
min(gammaCorrectD65(r), 1),
min(gammaCorrectD65(g), 1),
min(gammaCorrectD65(b), 1)
)
end
end

-- Type definitions
-- Transforms Roblox types into intermediate types, converting
-- between spaces as necessary to preserve perceptual linearity
local typeMetadata = {
boolean = {
springType = LinearSpring.new,

toIntermediate = function(value)
return {value and 1 or 0}
end,

fromIntermediate = function(value)
return value[1] >= 0.5
end,
},

number = {
springType = LinearSpring.new,

toIntermediate = function(value)
return {value}
end,

fromIntermediate = function(value)
return value[1]
end,
},

NumberRange = {
springType = LinearSpring.new,

toIntermediate = function(value)
return {value.Min, value.Max}
end,

fromIntermediate = function(value)
return NumberRange.new(value[1], value[2])
end,
},

UDim = {
springType = LinearSpring.new,

toIntermediate = function(value)
return {value.Scale, value.Offset}
end,

fromIntermediate = function(value: {number})
return UDim.new(value[1], round(value[2]))
end,
},

UDim2 = {
springType = LinearSpring.new,

toIntermediate = function(value)
local x = value.X
local y = value.Y
return {x.Scale, x.Offset, y.Scale, y.Offset}
end,

fromIntermediate = function(value: {number})
return UDim2.new(value[1], round(value[2]), value[3], round(value[4]))
end,
},

Vector2 = {
springType = LinearSpring.new,

toIntermediate = function(value)
return {value.X, value.Y}
end,

fromIntermediate = function(value: {number})
return Vector2.new(value[1], value[2])
end,
},

Vector3 = typeMetadata_Vector3,

Color3 = {
springType = LinearSpring.new,
toIntermediate = rgbToLuv,
fromIntermediate = luvToRgb,
},

-- Only interpolates start and end keypoints
ColorSequence = {
springType = LinearSpring.new,

toIntermediate = function(value)
local keypoints = value.Keypoints

local luv0 = rgbToLuv(keypoints[1].Value)
local luv1 = rgbToLuv(keypoints[#keypoints].Value)

return {
luv0[1], luv0[2], luv0[3],
luv1[1], luv1[2], luv1[3],
}
end,

fromIntermediate = function(value: {})
return ColorSequence.new(
luvToRgb{value[1], value[2], value[3]},
luvToRgb{value[4], value[5], value[6]}
)
end,
},

CFrame = {
springType = CFrameSpring.new,
toIntermediate = error, -- custom (CFrameSpring)
fromIntermediate = error, -- custom (CFrameSpring)
}
}

type PropertyOverride = {
[string]: {
class: string,
get: (any)->(),
set: (any, any)->(),
}
}

local PSEUDO_PROPERTIES: PropertyOverride = {
Pivot = {
class = "PVInstance",
get = function(inst: PVInstance)
return inst:GetPivot()
end,
set = function(inst: PVInstance, value: CFrame)
inst:PivotTo(value)
end
},
Scale = {
class = "Model",
get = function(inst: Model)
return inst:GetScale()
end,
set = function(inst: Model, value: number)
inst:ScaleTo(value)
end
}
}

-- Frame loop
local springStates: {[Instance]: {[string]: any}} = {} -- {[instance] = {[property] = spring}
local completedCallbacks: {[Instance]: {()->()}} = {}

RunService.Heartbeat:Connect(function(dt)
for instance, state in springStates do
for propName, spring in state do
local override = PSEUDO_PROPERTIES[propName]

if override and instance:IsA(override.class) then
if spring:canSleep() then
state[propName] = nil
override.set(instance, spring.rawGoal)
else
override.set(instance, spring:step(dt))
end
else
if spring:canSleep() then
state[propName] = nil
(instance :: any)[propName] = spring.rawGoal
else
(instance :: any)[propName] = spring:step(dt)
end
end
end

if not next(state) then
springStates[instance] = nil

-- trigger completed callbacks when all properties finish animating
local callbackList = completedCallbacks[instance]
if callbackList then
-- flush callback list before we run any callbacks in case
-- one of the callbacks recursively adds another callback
completedCallbacks[instance] = nil

for _, callback in callbackList do
task.spawn(callback)
end
end
end
end
end)

-- API
local spr = {}
do
local function assertType(argNum: number, fnName: string, expectedType: string, value: unknown)
if not expectedType:find(typeof(value)) then
error(`bad argument #{argNum} to {fnName} ({expectedType} expected, got {typeof(value)})`, 3)
end
end

function spr.target(instance: Instance, dampingRatio: number, frequency: number, properties: {[string]: any})
if STRICT_RUNTIME_TYPES then
assertType(1, "spr.target", "Instance", instance)
assertType(2, "spr.target", "number", dampingRatio)
assertType(3, "spr.target", "number", frequency)
assertType(4, "spr.target", "table", properties)
end

if dampingRatio ~= dampingRatio or dampingRatio < 0 then
error(("expected damping ratio >= 0; got %.2f"):format(dampingRatio), 2)
end

if frequency ~= frequency or frequency < 0 then
error(("expected undamped frequency >= 0; got %.2f"):format(frequency), 2)
end

local state = springStates[instance]
if not state then
state = {}
springStates[instance] = state
end

for propName, propTarget in properties do
local propValue
local override = PSEUDO_PROPERTIES[propName]
if override and instance:IsA(override.class) then
propValue = override.get(instance)
else
propValue = (instance :: any)[propName]
end

if STRICT_RUNTIME_TYPES and typeof(propTarget) ~= typeof(propValue) then
error(`bad property {propName} to spr.target ({typeof(propValue)} expected, got {typeof(propTarget)})`, 2)
end

-- Special case infinite frequency for an instantaneous change
if frequency == math.huge then
(instance :: any)[propName] = propTarget
state[propName] = nil
continue
end

local spring = state[propName]
if not spring then
local md = typeMetadata[typeof(propTarget)]
if not md then
error("unsupported type: " .. typeof(propTarget), 2)
end

spring = md.springType(dampingRatio, frequency, propValue, propTarget, md)
state[propName] = spring
end

spring:setGoal(propTarget)
spring:setDampingRatio(dampingRatio)
spring:setFrequency(frequency)
end

if not next(state) then
springStates[instance] = nil
end
end

function spr.stop(instance: Instance, property: string?)
if STRICT_RUNTIME_TYPES then
assertType(1, "spr.stop", "Instance", instance)
assertType(2, "spr.stop", "string|nil", property)
end

if property then
local state = springStates[instance]
if state then
state[property] = nil
end
else
springStates[instance] = nil
end
end

function spr.completed(instance: Instance, callback: ()->())
if STRICT_RUNTIME_TYPES then
assertType(1, "spr.completed", "Instance", instance)
assertType(2, "spr.completed", "function", callback)
end

local callbackList = completedCallbacks[instance]
if callbackList then
table.insert(callbackList, callback)
else
completedCallbacks[instance] = {callback}
end
end
end

return table.freeze(spr)
modules/t.lua
-- t: a runtime typechecker for Roblox

local t = {}

function t.type(typeName)
return function(value)
local valueType = type(value)
if valueType == typeName then
return true
else
return false, string.format("%s expected, got %s", typeName, valueType)
end
end
end

function t.typeof(typeName)
return function(value)
local valueType = typeof(value)
if valueType == typeName then
return true
else
return false, string.format("%s expected, got %s", typeName, valueType)
end
end
end

--[[**
matches any type except nil

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
function t.any(value)
if value ~= nil then
return true
else
return false, "any expected, got nil"
end
end

--Lua primitives

--[[**
ensures Lua primitive boolean type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.boolean = t.typeof("boolean")

--[[**
ensures Lua primitive thread type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.thread = t.typeof("thread")

--[[**
ensures Lua primitive callback type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.callback = t.typeof("function")
t["function"] = t.callback

--[[**
ensures Lua primitive none type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.none = t.typeof("nil")
t["nil"] = t.none

--[[**
ensures Lua primitive string type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.string = t.typeof("string")

--[[**
ensures Lua primitive table type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.table = t.typeof("table")

--[[**
ensures Lua primitive userdata type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.userdata = t.type("userdata")

--[[**
ensures value is a number and non-NaN

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
function t.number(value)
local valueType = typeof(value)
if valueType == "number" then
if value == value then
return true
else
return false, "unexpected NaN value"
end
else
return false, string.format("number expected, got %s", valueType)
end
end

--[[**
ensures value is NaN

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
function t.nan(value)
local valueType = typeof(value)
if valueType == "number" then
if value ~= value then
return true
else
return false, "unexpected non-NaN value"
end
else
return false, string.format("number expected, got %s", valueType)
end
end

-- roblox types

--[[**
ensures Roblox Axes type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Axes = t.typeof("Axes")

--[[**
ensures Roblox BrickColor type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.BrickColor = t.typeof("BrickColor")

--[[**
ensures Roblox CatalogSearchParams type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.CatalogSearchParams = t.typeof("CatalogSearchParams")

--[[**
ensures Roblox CFrame type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.CFrame = t.typeof("CFrame")

--[[**
ensures Roblox Color3 type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Color3 = t.typeof("Color3")

--[[**
ensures Roblox ColorSequence type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.ColorSequence = t.typeof("ColorSequence")

--[[**
ensures Roblox ColorSequenceKeypoint type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.ColorSequenceKeypoint = t.typeof("ColorSequenceKeypoint")

--[[**
ensures Roblox DateTime type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.DateTime = t.typeof("DateTime")

--[[**
ensures Roblox DockWidgetPluginGuiInfo type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.DockWidgetPluginGuiInfo = t.typeof("DockWidgetPluginGuiInfo")

--[[**
ensures Roblox Enum type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Enum = t.typeof("Enum")

--[[**
ensures Roblox EnumItem type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.EnumItem = t.typeof("EnumItem")

--[[**
ensures Roblox Enums type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Enums = t.typeof("Enums")

--[[**
ensures Roblox Faces type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Faces = t.typeof("Faces")

--[[**
ensures Roblox FloatCurveKey type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.FloatCurveKey = t.typeof("FloatCurveKey")

--[[**
ensures Roblox Font type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Font = t.typeof("Font")

--[[**
ensures Roblox Instance type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Instance = t.typeof("Instance")

--[[**
ensures Roblox NumberRange type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.NumberRange = t.typeof("NumberRange")

--[[**
ensures Roblox NumberSequence type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.NumberSequence = t.typeof("NumberSequence")

--[[**
ensures Roblox NumberSequenceKeypoint type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.NumberSequenceKeypoint = t.typeof("NumberSequenceKeypoint")

--[[**
ensures Roblox OverlapParams type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.OverlapParams = t.typeof("OverlapParams")

--[[**
ensures Roblox PathWaypoint type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.PathWaypoint = t.typeof("PathWaypoint")

--[[**
ensures Roblox PhysicalProperties type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.PhysicalProperties = t.typeof("PhysicalProperties")

--[[**
ensures Roblox Random type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Random = t.typeof("Random")

--[[**
ensures Roblox Ray type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Ray = t.typeof("Ray")

--[[**
ensures Roblox RaycastParams type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.RaycastParams = t.typeof("RaycastParams")

--[[**
ensures Roblox RaycastResult type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.RaycastResult = t.typeof("RaycastResult")

--[[**
ensures Roblox RBXScriptConnection type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.RBXScriptConnection = t.typeof("RBXScriptConnection")

--[[**
ensures Roblox RBXScriptSignal type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.RBXScriptSignal = t.typeof("RBXScriptSignal")

--[[**
ensures Roblox Rect type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Rect = t.typeof("Rect")

--[[**
ensures Roblox Region3 type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Region3 = t.typeof("Region3")

--[[**
ensures Roblox Region3int16 type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Region3int16 = t.typeof("Region3int16")

--[[**
ensures Roblox TweenInfo type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.TweenInfo = t.typeof("TweenInfo")

--[[**
ensures Roblox UDim type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.UDim = t.typeof("UDim")

--[[**
ensures Roblox UDim2 type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.UDim2 = t.typeof("UDim2")

--[[**
ensures Roblox Vector2 type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Vector2 = t.typeof("Vector2")

--[[**
ensures Roblox Vector2int16 type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Vector2int16 = t.typeof("Vector2int16")

--[[**
ensures Roblox Vector3 type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Vector3 = t.typeof("Vector3")

--[[**
ensures Roblox Vector3int16 type

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
t.Vector3int16 = t.typeof("Vector3int16")

--[[**
ensures value is a given literal value

@param literal The literal to use

@returns A function that will return true iff the condition is passed
**--]]
function t.literal(...)
local size = select("#", ...)
if size == 1 then
local literal = ...
return function(value)
if value ~= literal then
return false, string.format("expected %s, got %s", tostring(literal), tostring(value))
end

return true
end
else
local literals = {}
for i = 1, size do
local value = select(i, ...)
literals[i] = t.literal(value)
end

return t.union(table.unpack(literals, 1, size))
end
end

--[[**
DEPRECATED
Please use t.literal
**--]]
t.exactly = t.literal

--[[**
Returns a t.union of each key in the table as a t.literal

@param keyTable The table to get keys from

@returns True iff the condition is satisfied, false otherwise
**--]]
function t.keyOf(keyTable)
local keys = {}
local length = 0
for key in pairs(keyTable) do
length = length + 1
keys[length] = key
end

return t.literal(table.unpack(keys, 1, length))
end

--[[**
Returns a t.union of each value in the table as a t.literal

@param valueTable The table to get values from

@returns True iff the condition is satisfied, false otherwise
**--]]
function t.valueOf(valueTable)
local values = {}
local length = 0
for _, value in pairs(valueTable) do
length = length + 1
values[length] = value
end

return t.literal(table.unpack(values, 1, length))
end

--[[**
ensures value is an integer

@param value The value to check against

@returns True iff the condition is satisfied, false otherwise
**--]]
function t.integer(value)
local success, errMsg = t.number(value)
if not success then
return false, errMsg or ""
end

if value % 1 == 0 then
return true
else
return false, string.format("integer expected, got %s", value)
end
end

--[[**
ensures value is a number where min <= value

@param min The minimum to use

@returns A function that will return true iff the condition is passed
**--]]
function t.numberMin(min)
return function(value)
local success, errMsg = t.number(value)
if not success then
return false, errMsg or ""
end

if value >= min then
return true
else
return false, string.format("number >= %s expected, got %s", min, value)
end
end
end

--[[**
ensures value is a number where value <= max

@param max The maximum to use

@returns A function that will return true iff the condition is passed
**--]]
function t.numberMax(max)
return function(value)
local success, errMsg = t.number(value)
if not success then
return false, errMsg
end

if value <= max then
return true
else
return false, string.format("number <= %s expected, got %s", max, value)
end
end
end

--[[**
ensures value is a number where min < value

@param min The minimum to use

@returns A function that will return true iff the condition is passed
**--]]
function t.numberMinExclusive(min)
return function(value)
local success, errMsg = t.number(value)
if not success then
return false, errMsg or ""
end

if min < value then
return true
else
return false, string.format("number > %s expected, got %s", min, value)
end
end
end

--[[**
ensures value is a number where value < max

@param max The maximum to use

@returns A function that will return true iff the condition is passed
**--]]
function t.numberMaxExclusive(max)
return function(value)
local success, errMsg = t.number(value)
if not success then
return false, errMsg or ""
end

if value < max then
return true
else
return false, string.format("number < %s expected, got %s", max, value)
end
end
end

--[[**
ensures value is a number where value > 0

@returns A function that will return true iff the condition is passed
**--]]
t.numberPositive = t.numberMinExclusive(0)

--[[**
ensures value is a number where value < 0

@returns A function that will return true iff the condition is passed
**--]]
t.numberNegative = t.numberMaxExclusive(0)

--[[**
ensures value is a number where min <= value <= max

@param min The minimum to use
@param max The maximum to use

@returns A function that will return true iff the condition is passed
**--]]
function t.numberConstrained(min, max)
assert(t.number(min))
assert(t.number(max))
local minCheck = t.numberMin(min)
local maxCheck = t.numberMax(max)

return function(value)
local minSuccess, minErrMsg = minCheck(value)
if not minSuccess then
return false, minErrMsg or ""
end

local maxSuccess, maxErrMsg = maxCheck(value)
if not maxSuccess then
return false, maxErrMsg or ""
end

return true
end
end

--[[**
ensures value is a number where min < value < max

@param min The minimum to use
@param max The maximum to use

@returns A function that will return true iff the condition is passed
**--]]
function t.numberConstrainedExclusive(min, max)
assert(t.number(min))
assert(t.number(max))
local minCheck = t.numberMinExclusive(min)
local maxCheck = t.numberMaxExclusive(max)

return function(value)
local minSuccess, minErrMsg = minCheck(value)
if not minSuccess then
return false, minErrMsg or ""
end

local maxSuccess, maxErrMsg = maxCheck(value)
if not maxSuccess then
return false, maxErrMsg or ""
end

return true
end
end

--[[**
ensures value matches string pattern

@param string pattern to check against

@returns A function that will return true iff the condition is passed
**--]]
function t.match(pattern)
assert(t.string(pattern))
return function(value)
local stringSuccess, stringErrMsg = t.string(value)
if not stringSuccess then
return false, stringErrMsg
end

if string.match(value, pattern) == nil then
return false, string.format("%q failed to match pattern %q", value, pattern)
end

return true
end
end

--[[**
ensures value is either nil or passes check

@param check The check to use

@returns A function that will return true iff the condition is passed
**--]]
function t.optional(check)
assert(t.callback(check))
return function(value)
if value == nil then
return true
end

local success, errMsg = check(value)
if success then
return true
else
return false, string.format("(optional) %s", errMsg or "")
end
end
end

--[[**
matches given tuple against tuple type definition

@param ... The type definition for the tuples

@returns A function that will return true iff the condition is passed
**--]]
function t.tuple(...)
local checks = { ... }
return function(...)
local args = { ... }
for i, check in ipairs(checks) do
local success, errMsg = check(args[i])
if success == false then
return false, string.format("Bad tuple index #%s:\n\t%s", i, errMsg or "")
end
end

return true
end
end

--[[**
ensures all keys in given table pass check

@param check The function to use to check the keys

@returns A function that will return true iff the condition is passed
**--]]
function t.keys(check)
assert(t.callback(check))
return function(value)
local tableSuccess, tableErrMsg = t.table(value)
if tableSuccess == false then
return false, tableErrMsg or ""
end

for key in pairs(value) do
local success, errMsg = check(key)
if success == false then
return false, string.format("bad key %s:\n\t%s", tostring(key), errMsg or "")
end
end

return true
end
end

--[[**
ensures all values in given table pass check

@param check The function to use to check the values

@returns A function that will return true iff the condition is passed
**--]]
function t.values(check)
assert(t.callback(check))
return function(value)
local tableSuccess, tableErrMsg = t.table(value)
if tableSuccess == false then
return false, tableErrMsg or ""
end

for key, val in pairs(value) do
local success, errMsg = check(val)
if success == false then
return false, string.format("bad value for key %s:\n\t%s", tostring(key), errMsg or "")
end
end

return true
end
end

--[[**
ensures value is a table and all keys pass keyCheck and all values pass valueCheck

@param keyCheck The function to use to check the keys
@param valueCheck The function to use to check the values

@returns A function that will return true iff the condition is passed
**--]]
function t.map(keyCheck, valueCheck)
assert(t.callback(keyCheck))
assert(t.callback(valueCheck))
local keyChecker = t.keys(keyCheck)
local valueChecker = t.values(valueCheck)

return function(value)
local keySuccess, keyErr = keyChecker(value)
if not keySuccess then
return false, keyErr or ""
end

local valueSuccess, valueErr = valueChecker(value)
if not valueSuccess then
return false, valueErr or ""
end

return true
end
end

--[[**
ensures value is a table and all keys pass valueCheck and all values are true

@param valueCheck The function to use to check the values

@returns A function that will return true iff the condition is passed
**--]]
function t.set(valueCheck)
return t.map(valueCheck, t.literal(true))
end

do
local arrayKeysCheck = t.keys(t.integer)
--[[**
ensures value is an array and all values of the array match check

@param check The check to compare all values with

@returns A function that will return true iff the condition is passed
**--]]
function t.array(check)
assert(t.callback(check))
local valuesCheck = t.values(check)

return function(value)
local keySuccess, keyErrMsg = arrayKeysCheck(value)
if keySuccess == false then
return false, string.format("[array] %s", keyErrMsg or "")
end

-- # is unreliable for sparse arrays
-- Count upwards using ipairs to avoid false positives from the behavior of #
local arraySize = 0

for _ in ipairs(value) do
arraySize = arraySize + 1
end

for key in pairs(value) do
if key < 1 or key > arraySize then
return false, string.format("[array] key %s must be sequential", tostring(key))
end
end

local valueSuccess, valueErrMsg = valuesCheck(value)
if not valueSuccess then
return false, string.format("[array] %s", valueErrMsg or "")
end

return true
end
end

--[[**
ensures value is an array of a strict makeup and size

@param check The check to compare all values with

@returns A function that will return true iff the condition is passed
**--]]
function t.strictArray(...)
local valueTypes = { ... }
assert(t.array(t.callback)(valueTypes))

return function(value)
local keySuccess, keyErrMsg = arrayKeysCheck(value)
if keySuccess == false then
return false, string.format("[strictArray] %s", keyErrMsg or "")
end

-- If there's more than the set array size, disallow
if #valueTypes < #value then
return false, string.format("[strictArray] Array size exceeds limit of %d", #valueTypes)
end

for idx, typeFn in pairs(valueTypes) do
local typeSuccess, typeErrMsg = typeFn(value[idx])
if not typeSuccess then
return false, string.format("[strictArray] Array index #%d - %s", idx, typeErrMsg)
end
end

return true
end
end
end

do
local callbackArray = t.array(t.callback)
--[[**
creates a union type

@param ... The checks to union

@returns A function that will return true iff the condition is passed
**--]]
function t.union(...)
local checks = { ... }
assert(callbackArray(checks))

return function(value)
for _, check in ipairs(checks) do
if check(value) then
return true
end
end

return false, "bad type for union"
end
end

--[[**
Alias for t.union
**--]]
t.some = t.union

--[[**
creates an intersection type

@param ... The checks to intersect

@returns A function that will return true iff the condition is passed
**--]]
function t.intersection(...)
local checks = { ... }
assert(callbackArray(checks))

return function(value)
for _, check in ipairs(checks) do
local success, errMsg = check(value)
if not success then
return false, errMsg or ""
end
end

return true
end
end

--[[**
Alias for t.intersection
**--]]
t.every = t.intersection
end

do
local checkInterface = t.map(t.any, t.callback)
--[[**
ensures value matches given interface definition

@param checkTable The interface definition

@returns A function that will return true iff the condition is passed
**--]]
function t.interface(checkTable)
assert(checkInterface(checkTable))
return function(value)
local tableSuccess, tableErrMsg = t.table(value)
if tableSuccess == false then
return false, tableErrMsg or ""
end

for key, check in pairs(checkTable) do
local success, errMsg = check(value[key])
if success == false then
return false, string.format("[interface] bad value for %s:\n\t%s", tostring(key), errMsg or "")
end
end

return true
end
end

--[[**
ensures value matches given interface definition strictly

@param checkTable The interface definition

@returns A function that will return true iff the condition is passed
**--]]
function t.strictInterface(checkTable)
assert(checkInterface(checkTable))
return function(value)
local tableSuccess, tableErrMsg = t.table(value)
if tableSuccess == false then
return false, tableErrMsg or ""
end

for key, check in pairs(checkTable) do
local success, errMsg = check(value[key])
if success == false then
return false, string.format("[interface] bad value for %s:\n\t%s", tostring(key), errMsg or "")
end
end

for key in pairs(value) do
if not checkTable[key] then
return false, string.format("[interface] unexpected field %q", tostring(key))
end
end

return true
end
end
end

--[[**
ensure value is an Instance and it's ClassName matches the given ClassName

@param className The class name to check for

@returns A function that will return true iff the condition is passed
**--]]
function t.instanceOf(className, childTable)
assert(t.string(className))

local childrenCheck
if childTable ~= nil then
childrenCheck = t.children(childTable)
end

return function(value)
local instanceSuccess, instanceErrMsg = t.Instance(value)
if not instanceSuccess then
return false, instanceErrMsg or ""
end

if value.ClassName ~= className then
return false, string.format("%s expected, got %s", className, value.ClassName)
end

if childrenCheck then
local childrenSuccess, childrenErrMsg = childrenCheck(value)
if not childrenSuccess then
return false, childrenErrMsg
end
end

return true
end
end

t.instance = t.instanceOf

--[[**
ensure value is an Instance and it's ClassName matches the given ClassName by an IsA comparison

@param className The class name to check for

@returns A function that will return true iff the condition is passed
**--]]
function t.instanceIsA(className, childTable)
assert(t.string(className))

local childrenCheck
if childTable ~= nil then
childrenCheck = t.children(childTable)
end

return function(value)
local instanceSuccess, instanceErrMsg = t.Instance(value)
if not instanceSuccess then
return false, instanceErrMsg or ""
end

if not value:IsA(className) then
return false, string.format("%s expected, got %s", className, value.ClassName)
end

if childrenCheck then
local childrenSuccess, childrenErrMsg = childrenCheck(value)
if not childrenSuccess then
return false, childrenErrMsg
end
end

return true
end
end

--[[**
ensures value is an enum of the correct type

@param enum The enum to check

@returns A function that will return true iff the condition is passed
**--]]
function t.enum(enum)
assert(t.Enum(enum))
return function(value)
local enumItemSuccess, enumItemErrMsg = t.EnumItem(value)
if not enumItemSuccess then
return false, enumItemErrMsg
end

if value.EnumType == enum then
return true
else
return false, string.format("enum of %s expected, got enum of %s", tostring(enum), tostring(value.EnumType))
end
end
end

do
local checkWrap = t.tuple(t.callback, t.callback)

--[[**
wraps a callback in an assert with checkArgs

@param callback The function to wrap
@param checkArgs The function to use to check arguments in the assert

@returns A function that first asserts using checkArgs and then calls callback
**--]]
function t.wrap(callback, checkArgs)
assert(checkWrap(callback, checkArgs))
return function(...)
assert(checkArgs(...))
return callback(...)
end
end
end

--[[**
asserts a given check

@param check The function to wrap with an assert

@returns A function that simply wraps the given check in an assert
**--]]
function t.strict(check)
return function(...)
assert(check(...))
end
end

do
local checkChildren = t.map(t.string, t.callback)

--[[**
Takes a table where keys are child names and values are functions to check the children against.
Pass an instance tree into the function.
If at least one child passes each check, the overall check passes.

Warning! If you pass in a tree with more than one child of the same name, this function will always return false

@param checkTable The table to check against

@returns A function that checks an instance tree
**--]]
function t.children(checkTable)
assert(checkChildren(checkTable))

return function(value)
local instanceSuccess, instanceErrMsg = t.Instance(value)
if not instanceSuccess then
return false, instanceErrMsg or ""
end

local childrenByName = {}
for _, child in ipairs(value:GetChildren()) do
local name = child.Name
if checkTable[name] then
if childrenByName[name] then
return false, string.format("Cannot process multiple children with the same name %q", name)
end

childrenByName[name] = child
end
end

for name, check in pairs(checkTable) do
local success, errMsg = check(childrenByName[name])
if not success then
return false, string.format("[%s.%s] %s", value:GetFullName(), name, errMsg or "")
end
end

return true
end
end
end

return t
replicatedfirst/Chickynoid/Client/BallModel.lua
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
--!native
local BallModel = {}
BallModel.__index = BallModel

--[=[
@class BallModel
@client

Represents the client side view of a ball model

Consumes a BallData
]=]

local path = game.ReplicatedFirst.Chickynoid
local Enums = require(path.Shared.Enums)
local FastSignal = require(path.Shared.Vendor.FastSignal)
local ClientMods = require(path.Client.ClientMods)
local Animations = require(path.Shared.Simulation.Animations)

local Quaternion = require(script.Parent.Parent.Shared.Simulation.Quaternion)

local localPlayer = Players.LocalPlayer

BallModel.template = nil
BallModel.characterModelCallbacks = {}


function BallModel:ModuleSetup()
self.template = path.Assets:FindFirstChild("Ball")
self.modelPool = {}
end


function BallModel.new(ballId)
local self = setmetatable({
model = nil,
modelData = nil,
modelReady = false,

ballId = ballId,
mispredict = Vector3.new(0, 0, 0),
onModelCreated = FastSignal.new(),
onModelDestroyed = FastSignal.new(),
updated=false,


}, BallModel)

return self
end

function BallModel:CreateModel()

self:DestroyModel()

--print("CreateModel ", self.ballId)
task.spawn(function()

self.coroutineStarted = true

local srcModel: BasePart = self.template:Clone()

self.model = srcModel
self.modelReady = true

srcModel:AddTag("Ball")

local ballModelObject = Instance.new("ObjectValue")
ballModelObject.Name = "BallModel"
ballModelObject.Value = srcModel
ballModelObject.Parent = localPlayer
srcModel.CanCollide = false

self.model.Parent = game.Workspace
self.onModelCreated:Fire(self.model)

self.coroutineStarted = false
end)
end

function BallModel:DestroyModel()

self.destroyed = true

task.spawn(function()

--The coroutine for loading the appearance might still be running while we've already asked to destroy ourselves
--We wait for it to finish, then clean up
while (self.coroutineStarted == true) do
wait()
end

if (self.model == nil) then
return
end
self.onModelDestroyed:Fire()

self.playingTrack = nil
self.model:Destroy()

self.modelPool[self.ballId] = nil
self.modelReady = false


end)
end


--you shouldnt ever have to call this directly, change the characterData to trigger this
function BallModel:Think(_deltaTime, dataRecord, bulkMoveToList, rotationQuaternion: typeof(Quaternion.new()))
if self.model == nil then
return
end

local newCF = rotationQuaternion:ToCFrame(dataRecord.pos + self.mispredict)
if (bulkMoveToList) then
table.insert(bulkMoveToList.parts, self.model)
table.insert(bulkMoveToList.cframes, newCF)
else
self.model.CFrame = newCF
end
end


BallModel:ModuleSetup()

return BallModel
replicatedfirst/Chickynoid/Client/CharacterModel.lua
--!native
local CharacterModel = {}
CharacterModel.__index = CharacterModel

--[=[
@class CharacterModel
@client

Represents the client side view of a character model
the local player and all other players get one of these each
Todo: think about allowing a serverside version of this to exist for perhaps querying rays against?

Consumes a CharacterData
]=]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local AnimationRemoteEvent = ReplicatedStorage:WaitForChild("AnimationReplication") :: RemoteEvent

local path = game.ReplicatedFirst.Chickynoid
local Enums = require(path.Shared.Enums)
local FastSignal = require(path.Shared.Vendor.FastSignal)
local ClientMods = require(path.Client.ClientMods)
local Animations = require(path.Shared.Simulation.Animations)
local GameInfo = require(ReplicatedFirst.GameInfo)

local Quaternion = require(script.Parent.Parent.Shared.Simulation.Quaternion)

local localPlayer = Players.LocalPlayer

CharacterModel.template = nil
CharacterModel.characterModelCallbacks = {}


function CharacterModel:ModuleSetup()
self.template = path.Assets:FindFirstChild("R6Rig")
self.modelPool = {}
end


function CharacterModel.new(userId, characterMod)
local self = setmetatable({
model = nil,
tracks = {},
animator = nil,
modelData = nil,
playingTrack0 = nil,
playingTrack1 = nil,
runAnimTrack = nil,
playingTrackNum0 = nil,
playingTrackNum1 = nil,
animCounter = -1,
modelOffset = Vector3.new(0, 0.5, 0),
modelReady = false,
startingAnimation = "Idle",
userId = userId,
characterMod = characterMod,
mispredict = Vector3.new(0, 0, 0),
onModelCreated = FastSignal.new(),
onModelDestroyed = FastSignal.new(),
updated=false,


}, CharacterModel)

return self
end

function CharacterModel:CreateModel(avatarDescription: {string}?)

self:DestroyModel()

--print("CreateModel ", self.userId)
task.spawn(function()

self.coroutineStarted = true

local srcModel: Model = nil

-- Download custom character
if (self.modelPool[self.userId] == nil) then
for _, characterModelCallback in ipairs(self.characterModelCallbacks) do
local result = characterModelCallback(self.userId);
if (result) then
srcModel = result:Clone()
end
end

--Check the character mod
local success, humanoidDescription = pcall(function()
local userId = self.userId
if (string.sub(userId, 1, 1) == "-") then
userId = string.sub(userId, 2, string.len(userId)) --drop the -
end

local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(userId)
humanoidDescription.Head = 0
humanoidDescription.LeftArm = 0
humanoidDescription.LeftLeg = 0
humanoidDescription.RightArm = 0
humanoidDescription.RightLeg = 0
humanoidDescription.Torso = 0

local accessoryList = humanoidDescription:GetAccessories(true)
for _, accessoryInfo in ipairs(table.clone(accessoryList)) do
local accessoryWhitelist = {Enum.AccessoryType.Hat, Enum.AccessoryType.Hair, Enum.AccessoryType.Face, Enum.AccessoryType.Eyebrow, Enum.AccessoryType.Eyelash}
if not table.find(accessoryWhitelist, accessoryInfo.AccessoryType) then
table.remove(accessoryList, table.find(accessoryList, accessoryInfo))
end
end
humanoidDescription:SetAccessories(accessoryList, true)

return humanoidDescription
end)
if not success then
humanoidDescription = Instance.new("HumanoidDescription")
end

local originalHumanoidDescription = humanoidDescription:Clone()
if (srcModel == nil) then
if (self.characterMod) then
local loadedModule = ClientMods:GetMod("characters", self.characterMod)
if (loadedModule and loadedModule.GetCharacterModel) then
local template = loadedModule:GetCharacterModel(self.userId, avatarDescription, humanoidDescription)
if (template) then
srcModel = template:Clone()
end
end
end
end

if (srcModel == nil) then
srcModel = self.template:Clone()
srcModel.Parent = game.Lighting --needs to happen so loadAppearance works

local userId = ""
local result, err = pcall(function()

userId = self.userId
srcModel:SetAttribute("userid", userId)

local player = Players:GetPlayerByUserId(userId)
if player then
srcModel.Name = player.Name
end

--Bot id?
srcModel.Humanoid:ApplyDescriptionReset(humanoidDescription)
end)
if (result == false) then
warn("Loading " .. userId .. ":" ..err)
end
end

--setup the hip
local hip = srcModel.Humanoid.HipHeight
srcModel.Humanoid.CameraOffset = GameInfo.CAMERA_OFFSET

self.modelData = {
model = srcModel,
modelOffset = Vector3.new(0, hip, 0),
humanoidDescription = originalHumanoidDescription,
}
self.modelPool[self.userId] = self.modelData
end

self.modelData = self.modelPool[self.userId]
self.model = self.modelData.model
self.primaryPart = self.model.PrimaryPart
self.model.Parent = game.Lighting -- must happen to load animations

--Load on the animations
self.animator = self.model:FindFirstChild("Animator", true)
local humanoid = self.model:FindFirstChild("Humanoid")
if (not self.animator) then
if (humanoid) then
self.animator = self.template:FindFirstChild("Animator", true):Clone()
self.animator.Parent = humanoid
end
end
self.tracks = {}

self:SetupLobbyChickynoid()
for _, value in pairs(self.animator:GetDescendants()) do
if value:IsA("Animation") then
local track = self.animator:LoadAnimation(value)
self.tracks[value.Name] = track
end
end

self.modelReady = true

if self.playingTrackNum0 then
self:PlayAnimation(self.playingTrackNum0, false, Enums.AnimChannel.Channel0)
else
self:PlayAnimation(self.startingAnimation, true, Enums.AnimChannel.Channel0)
end


local function adjustCollisions(part: BasePart)
if not part:IsA("BasePart") then return end
if part:HasTag("Ball") then
return
end
part.CollisionGroup = "Character"
end
for _, child in pairs(srcModel:GetChildren()) do
adjustCollisions(child)
end
srcModel.ChildAdded:Connect(adjustCollisions)

self.model.Parent = game.Workspace
self.onModelCreated:Fire(self.model)
self:SetupFieldChickynoid()

local player = Players:GetPlayerByUserId(self.userId)
if player then
local function setEmoteData()
self.model:SetAttribute("EmoteData", player:GetAttribute("EmoteData"))
end
setEmoteData()
player:GetAttributeChangedSignal("EmoteData"):Connect(setEmoteData)
end

for _, stateType in pairs(Enum.HumanoidStateType:GetEnumItems()) do
if stateType == Enum.HumanoidStateType.None then continue end
if localPlayer == player and stateType == Enum.HumanoidStateType.Jumping then continue end
humanoid:SetStateEnabled(stateType, false)
end


self.resetRagdoll = false
self.model:GetAttributeChangedSignal("ResetRagdoll"):Connect(function()
self.resetRagdoll = self.model:GetAttribute("ResetRagdoll")
end)

self.applyFreezeRotation = false
self.model:GetAttributeChangedSignal("ApplyFreezeRotation"):Connect(function()
self.applyFreezeRotation = self.model:GetAttribute("ApplyFreezeRotation")
end)

self.applyRagdollKnockback = false
self.model:GetAttributeChangedSignal("ApplyRagdollKnockback"):Connect(function()
self.applyRagdollKnockback = self.model:GetAttribute("ApplyRagdollKnockback")
end)

self.coroutineStarted = false
end)
end

function CharacterModel:ReplaceModel(avatarDescription: {string}?)
if self.coroutineStarted then
return
end

task.spawn(function()

self.coroutineStarted = true

local srcModel = self.model
local humanoidDescription: HumanoidDescription = self.modelData.humanoidDescription:Clone()

local isFieldPlayer = self.characterMod == "FieldChickynoid" or self.characterMod == "GoalkeeperChickynoid"
if isFieldPlayer then
local userId = self.userId
local result, err = pcall(function()
local loadedModule = ClientMods:GetMod("characters", self.characterMod)
loadedModule:DoStuffToModel(userId, srcModel, avatarDescription, humanoidDescription)
end)
if (result == false) then
warn("Loading " .. userId .. ":" ..err)
end
else
local userId = ""
local result, err = pcall(function()

userId = self.userId
--Bot id?
if (string.sub(userId, 1, 1) == "-") then
userId = string.sub(userId, 2, string.len(userId)) --drop the -
end

srcModel.Humanoid:ApplyDescriptionReset(humanoidDescription)

local torso = srcModel.Torso
local kitInfo: SurfaceGui = torso:FindFirstChild("KitInfo")
if kitInfo then
kitInfo.Enabled = false
end

if self.userId == localPlayer.UserId then
srcModel.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
else
srcModel.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
end
end)
if (result == false) then
warn("Loading " .. userId .. ":" ..err)
end
end

self.modelData.modelOffset = Vector3.new(0, srcModel.Humanoid.HipHeight, 0)
self.primaryPart = self.model.PrimaryPart

--Load on the animations
self.animator = self.model:FindFirstChild("Animator", true)
if (not self.animator) then
local humanoid = self.model:FindFirstChild("Humanoid")
if (humanoid) then
self.animator = self.template:FindFirstChild("Animator", true):Clone()
self.animator.Parent = humanoid
end
end

for _, value in pairs(self.animator:GetPlayingAnimationTracks()) do
value:Stop()
end
self.tracks = {}

self.animator:ClearAllChildren()
local characterWithAnims = self.template
if self.characterMod == "FieldChickynoid" then
characterWithAnims = path.Assets:FindFirstChild("FieldRig")
elseif self.characterMod == "GoalkeeperChickynoid" then
characterWithAnims = path.Assets:FindFirstChild("GoalkeeperRig")
end
for _, animation: Animation in pairs(characterWithAnims.Humanoid.Animator:GetChildren()) do
animation:Clone().Parent = self.animator
end

self:SetupLobbyChickynoid()
for _, value in pairs(self.animator:GetDescendants()) do
if value:IsA("Animation") then
local track = self.animator:LoadAnimation(value)
self.tracks[value.Name] = track
end
end

self.modelReady = true

if self.playingTrackNum0 then
self:PlayAnimation(self.playingTrackNum0, false, Enums.AnimChannel.Channel0)
else
self:PlayAnimation(self.startingAnimation, true, Enums.AnimChannel.Channel0)
end

self.onModelCreated:Fire(self.model)
self:SetupFieldChickynoid()

self.coroutineStarted = false
end)
end

function CharacterModel:SetupLobbyChickynoid()
if self.characterMod ~= "HumanoidChickynoid" then
return
end
self.model:RemoveTag("ChickynoidCharacter")
self.model:RemoveTag("BuildRagdoll")

self.model:SetAttribute("AppliedDescription", false)
end

function CharacterModel:SetupFieldChickynoid()
local isFieldPlayer = self.characterMod == "FieldChickynoid" or self.characterMod == "GoalkeeperChickynoid"
if not isFieldPlayer then
return
end
self.model:AddTag("ChickynoidCharacter")
self.model:AddTag("BuildRagdoll")
self.model.PrimaryPart.Anchored = true

self.model:SetAttribute("AppliedDescription", true)

local isGoalkeeper = self.characterMod == "GoalkeeperChickynoid"
self.model:SetAttribute("Goalkeeper", isGoalkeeper)


local player = Players:GetPlayerByUserId(self.userId) :: Player
if player == nil then
player = {}
player.UserId = 0
function player:GetAttribute()

end
function player:GetAttributeChangedSignal()
return localPlayer:GetAttributeChangedSignal("testattribute")
end
function player:SetAttribute()

end
end

local Trove = require(ReplicatedStorage.Modules.Trove)

local assets = ReplicatedStorage.Assets
local animationFolder = assets.Animations

local trove = Trove.new()
if type(player) ~= "table" then
trove:AttachToInstance(player)
end
trove:Connect(self.onModelCreated, function()
trove:Destroy()
end)

if not isGoalkeeper then
local function updateGroundSkill()
local skillAnimations = animationFolder.Skills
local groundSkill: string = player:GetAttribute("GroundSkill") or "Feint"
self.tracks.Skill:Stop()
self.tracks.Skill = self.animator:LoadAnimation(skillAnimations.Ground[groundSkill])
end
updateGroundSkill()
trove:Connect(player:GetAttributeChangedSignal("GroundSkill"), updateGroundSkill)
end

local character = self.model
if self.characterMod == "GoalkeeperChickynoid" then
local holdAnimation = self.tracks.Hold
trove:Connect(player.Ball.Changed, function(ball: BasePart?)
if character:GetAttribute("Goalkeeper") then
if ball ~= nil then
holdAnimation:Play()
else
holdAnimation:Stop()
end
end
end)
end
end


function CharacterModel:DestroyModel()

self.destroyed = true

task.spawn(function()

--The coroutine for loading the appearance might still be running while we've already asked to destroy ourselves
--We wait for it to finish, then clean up
while (self.coroutineStarted == true) do
wait()
end

if (self.model == nil) then
return
end
self.onModelDestroyed:Fire()

self.playingTrack0 = nil
self.playingTrack1 = nil
self.modelData = nil
self.animator = nil
self.tracks = {}
self.model:Destroy()

if self.modelData and self.modelData.model then
self.modelData.model:Destroy()
end

self.modelData = nil
self.modelPool[self.userId] = nil
self.modelReady = false


end)
end

function CharacterModel:PlayerDisconnected(userId)

local modelData = self.modelPool[self.userId]
if (modelData and modelData.model) then
modelData.model:Destroy()
end
end


--you shouldnt ever have to call this directly, change the characterData to trigger this
function CharacterModel:PlayAnimation(enum, force, animChannel)

local name = Animations:GetAnimation(enum)
if (name == nil) then
name = "Idle"
end

if self.modelReady == false then
--Model not instantiated yet
local startingAnimationIndex = "startingAnimation"..animChannel
self[startingAnimationIndex] = name
return
end

if not self.modelData then
return
end

local tracks = self.tracks
local track = tracks[name]

local stunIdleAnim = tracks.StunIdle
if stunIdleAnim and animChannel == Enums.AnimChannel.Channel1 then
stunIdleAnim:Stop()
end

local playingTrackIndex = "playingTrack" .. animChannel
local playingTrackNumIndex = "playingTrackNum"..animChannel
local playingTrack = self[playingTrackIndex]
if name == "Stop" then

-- Stop anim
if playingTrack then
playingTrack:Stop()
self[playingTrackIndex] = nil
self[playingTrackNumIndex] = nil
end
return
end

if track == nil then
return
end
if playingTrack == track and force ~= true then
return
end

if playingTrack then
if animChannel ~= Enums.AnimChannel.Channel1 or table.find({"StunFlip", "StunIdle", "StunLand"}, name) then
playingTrack:Stop()
end
end

local weights = {
ChargeShot = 0.3, LowCatch = 0, HighCatch = 0,
}
track:Play(weights[name])
if name == "StunLand" and stunIdleAnim then
stunIdleAnim:Play()
end


if animChannel == Enums.AnimChannel.Channel1 then
-- local priorities = {RequestBall = Enum.AnimationPriority.Action}
-- track.Priority = priorities[name] or Enum.AnimationPriority.Action1
elseif animChannel == Enums.AnimChannel.Channel0 then
track.Priority = Enum.AnimationPriority.Core
end

self[playingTrackIndex] = track
self[playingTrackNumIndex] = enum


-- local player = self.player
-- if self.player == nil then
-- self.player = Players:GetPlayerByUserId(self.userId)
-- player = self.player
-- end

-- local controllers = localPlayer.PlayerScripts.ClientScripts.Controllers
-- local EffectController = require(controllers.EffectController)
-- if table.find({"Shoot"}, name) then
-- EffectController:CreateEffect("ballKicked", {player})
-- end
end

function CharacterModel:Think(_deltaTime, dataRecord, bulkMoveToList, customData: {ballRotation: Vector3, w: number, leanAngle: Vector2, animDir: number})
if self.model == nil then
return
end

if self.modelData == nil then
return
end

local player = self.player
if self.player == nil then
self.player = Players:GetPlayerByUserId(self.userId)
player = self.player
end
local isLocalPlayer = localPlayer == player

if isLocalPlayer then
debug.profilebegin("Chickynoid Local Character Animate")
end

--Flag that something has changed on all channels
for animChannel = 0,3,1 do

-- get anim counter index/name from for loop counter
local animCounterIndex = "animCounter"..animChannel

if self[animCounterIndex] ~= dataRecord[animCounterIndex] then
-- DATA CHANGED!

-- update anim counter
self[animCounterIndex] = dataRecord[animCounterIndex]

-- Play animation
local animNum = dataRecord["animNum"..animChannel]
self:PlayAnimation(animNum, true, animChannel)
end
end

if isLocalPlayer then
debug.profileend()
end


local newCF

local position = dataRecord.pos

local root = self.model.HumanoidRootPart.RootJoint
local isRagdolled = self.model:HasTag("Ragdoll")
if isRagdolled then
if isLocalPlayer then
debug.profilebegin("Chickynoid Local Character Ragdolled/Frozen")
end
root.C0 = CFrame.new(root.C0.Position)

if isRagdolled then
self.primaryPart.Anchored = true
else
self.primaryPart.Anchored = false
end
local success, warning = pcall(function()
if self.applyRagdollKnockback and isRagdolled then
self.model:SetAttribute("ApplyRagdollKnockback", nil)
if localPlayer == player then
for _, animation in pairs(self.model.Humanoid.Animator:GetPlayingAnimationTracks()) do
animation:Stop(0)
end
end
end

local currentPivot: CFrame = self.model:GetPivot()
local newPosition = dataRecord.pos + self.modelData.modelOffset + self.mispredict + Vector3.new(0, dataRecord.stepUp, 0)
if (position + self.mispredict).Y < 48 then
newPosition = Vector3.new(newPosition.X, currentPivot.Y, newPosition.Z)
end
newCF = CFrame.new(newPosition) * currentPivot.Rotation
end)
if not success then
warn(warning)
newCF = CFrame.new(dataRecord.pos + self.modelData.modelOffset + self.mispredict + Vector3.new(0, dataRecord.stepUp, 0))
* CFrame.fromEulerAnglesXYZ(0, dataRecord.angle, 0)
end
if isLocalPlayer then
debug.profileend()
end
else
self.primaryPart.Anchored = true


if isLocalPlayer then
debug.profilebegin("Chickynoid Local Character Set Lean Angle")
end

local leanAngle = CFrame.new()
if self.characterMod ~= "HumanoidChickynoid" then
if player == localPlayer then
local newAngle = CFrame.Angles(-customData.leanAngle.X, customData.leanAngle.Y, 0)
leanAngle = newAngle
else
local newAngle = CFrame.Angles(-dataRecord.leanAngle.X, dataRecord.leanAngle.Y, 0)
leanAngle = newAngle
end
end
root.C0 = CFrame.new(root.C0.Position) * CFrame.fromEulerAnglesYXZ(math.rad(-90), math.rad(-180), math.rad(0)) * leanAngle

if isLocalPlayer then
debug.profileend()
end

local animDir = customData and customData.animDir or dataRecord.animDir
if animDir == 0 then
animDir = 1
else
animDir = -1
end

if self.playingTrackNum0 == Animations:GetAnimationIndex("Sprint") then
animDir = 1
end

if isLocalPlayer then
debug.profilebegin("Chickynoid Local Character Adjust Speeds")
end
if self.playingTrackNum0 == Animations:GetAnimationIndex("Sprint") then
local vel = dataRecord.flatSpeed
local playbackSpeed = (vel / 16) --Todo: Persistant player stats
self.playingTrack0:AdjustSpeed(playbackSpeed * animDir)
elseif self.playingTrackNum0 == Animations:GetAnimationIndex("Walk") then
local isFieldPlayer = self.characterMod == "FieldChickynoid" or self.characterMod == "GoalkeeperChickynoid"
if isFieldPlayer then
local vel = dataRecord.flatSpeed
local playbackSpeed = vel / 16
self.playingTrack0:AdjustSpeed(playbackSpeed * animDir)
else
local vel = dataRecord.flatSpeed
local playbackSpeed = vel / 16
self.playingTrack0:AdjustSpeed(playbackSpeed)
end
end

if self.playingTrackNum0 == Animations:GetAnimationIndex("Push") then
local vel = 14
local playbackSpeed = (vel / 16) --Todo: Persistant player stats
self.playingTrack0:AdjustSpeed(playbackSpeed * animDir)
end
if isLocalPlayer then
debug.profileend()
end


if isLocalPlayer then
debug.profilebegin("Chickynoid Local Character Reset Ragdoll")
end
local resetTime = self.resetRagdoll
if resetTime then
if localPlayer == player then
localPlayer:SetAttribute("ClientRagdollAnimation", nil)
end

if self.playingTrack0 and not self.playingTrack0.IsPlaying then
self.playingTrack0:Play()
elseif self.playingTrack0 and self.playingTrack0.Speed == 0 then
self.playingTrack0:AdjustSpeed(1)
end

local timePassed = os.clock() - resetTime
local alpha = timePassed / 0.5
if alpha > 1 then
self.model:SetAttribute("ResetRagdoll", nil)
newCF = CFrame.new(dataRecord.pos + self.modelData.modelOffset + self.mispredict + Vector3.new(0, dataRecord.stepUp, 0))
* CFrame.fromEulerAnglesXYZ(0, dataRecord.angle, 0)
else
local currentPivot: CFrame = self.model:GetPivot()
local goalPosition = dataRecord.pos + self.modelData.modelOffset + self.mispredict + Vector3.new(0, dataRecord.stepUp, 0)
local currentPosition = Vector3.new(goalPosition.X, currentPivot.Y, goalPosition.Z)
newCF = CFrame.new(currentPosition:Lerp(goalPosition, alpha)) * currentPivot.Rotation:Lerp(CFrame.fromEulerAnglesXYZ(0, dataRecord.angle, 0), alpha)
end
else
newCF = CFrame.new(dataRecord.pos + self.modelData.modelOffset + self.mispredict + Vector3.new(0, dataRecord.stepUp, 0))
* CFrame.fromEulerAnglesXYZ(0, dataRecord.angle, 0)
end
if isLocalPlayer then
debug.profileend()
end
end

if (bulkMoveToList) then
table.insert(bulkMoveToList.parts, self.primaryPart)
table.insert(bulkMoveToList.cframes, newCF)
else
workspace:BulkMoveTo({self.primaryPart}, {newCF}, Enum.BulkMoveMode.FireCFrameChanged)
-- self.model:PivotTo(newCF)
end
end

function CharacterModel:SetCharacterModel(callback)
table.insert(self.characterModelCallbacks, callback)
end


CharacterModel:ModuleSetup()

return CharacterModel
replicatedfirst/Chickynoid/Client/ClientBallController.lua

--[=[
@class ClientBallController
@client

A Chickynoid class that handles ball simulation and command generation for the client
]=]
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local RemoteEvent = ReplicatedStorage:WaitForChild("ChickynoidReplication") :: RemoteEvent
local UnreliableRemoteEvent = ReplicatedStorage:WaitForChild("ChickynoidUnreliableReplication") :: UnreliableRemoteEvent

local path = game.ReplicatedFirst.Chickynoid
local BallSimulation = require(path.Shared.Simulation.BallSimulation)
local ClientMods = require(path.Client.ClientMods)
local CollisionModule = require(path.Shared.Simulation.CollisionModule)
local DeltaTable = require(path.Shared.Vendor.DeltaTable)

local CommandLayout = require(path.Shared.Simulation.CommandLayout)

local TrajectoryModule = require(path.Shared.Simulation.TrajectoryModule)
local Enums = require(path.Shared.Enums)
local EventType = Enums.EventType

local ClientBallController = {}
ClientBallController.__index = ClientBallController

--[=[
Constructs a new ClientChickynoid for the local player, spawning it at the specified
position. The position is just to prevent a mispredict.

@param position Vector3 -- The position to spawn this character, provided by the server.
@return ClientChickynoid
]=]
function ClientBallController.new(position: Vector3)
local self = setmetatable({

simulation = BallSimulation.new(localPlayer.UserId),
localStateCache = {},
characterMod = "DefaultBallController",
localFrame = 0,

ignoreServerState = nil,
lastConfirmedGuid = nil,
aheadOfServerBy = 0,

mispredict = Vector3.new(0, 0, 0),

commandPacketlossPrevention = true, -- set this to true to duplicate packets

debug = {
processedCommands = 0,
showDebugSpheres = false,
useSkipResimulationOptimization = false,
debugParts = nil,
},
}, ClientBallController)

self.simulation.state.pos = position

--Apply the characterMod
if (self.characterMod) then
local loadedModule = ClientMods:GetMod("balls", self.characterMod)
loadedModule:Setup(self.simulation)
end

self:HandleLocalPlayer()


return self
end

function ClientBallController:HandleLocalPlayer() end


--[=[
The server sends each client an updated world state on a fixed timestep. This
handles state updates for this character.

@param state table -- The new state sent by the server.
@param stateDeltaFrame -- The serverFrame this delta compressed against - due to packetloss the server can't just send you the newest stuff.
@param lastConfirmed number -- The serial number of the last command confirmed by the server - can be nil!
@param serverTime - Time when command was confirmed
@param playerStateFrame -- Current frame on the server, used for tracking playerState
]=]
function ClientBallController:HandleNewPlayerState(stateDelta, stateDeltaTime, lastConfirmed, serverTime, playerStateFrame, totalCommandsToRun: number)
totalCommandsToRun = totalCommandsToRun or 1

self:ClearDebugSpheres()

local stateRecord = DeltaTable:DeepCopy(stateDelta)

--Set the last server frame we saw a command from
self.lastSeenPlayerStateFrame = playerStateFrame

-- Build a list of the commands the server has not confirmed yet
local resimulate = true

--Check to see if we can skip simulation
--Todo: This needs to check a lot more than position and velocity - the server should always be able to force a reconcile/resim
if (self.debug.useSkipResimulationOptimization == true) then

if (lastConfirmed ~= nil) then
local cacheRecord = self.localStateCache[lastConfirmed]
if cacheRecord and cacheRecord.stateRecord.state.guid == stateRecord.state.guid then
-- This is the state we were in, if the server agrees with this, we dont have to resim\
if (cacheRecord.stateRecord.state.ownerId ~= 0 or (cacheRecord.stateRecord.state.pos - stateRecord.state.pos).Magnitude < 0.05)
and (cacheRecord.stateRecord.state.vel - stateRecord.state.vel).Magnitude < 0.1 then
resimulate = false
-- print("skipped resim")
end
end

-- Clear all the ones older than lastConfirmed
for key, _ in pairs(self.localStateCache) do
if key < lastConfirmed then
self.localStateCache[key] = nil
end
end
end
end


if self.lastLocalFrame and self.lastLocalFrame > lastConfirmed then
return
end
self.lastLocalFrame = lastConfirmed

local ignoreServerState = self.ignoreServerState
if ignoreServerState then
if tick() - ignoreServerState < 0 then
resimulate = false
else
resimulate = true
self.skipResimulation = false
self.ignoreServerState = nil
end
end


local playerIsNetworkOwner = stateRecord.state.netId == localPlayer.UserId

local isGoalkeeper = localPlayer:GetAttribute("Position") == "Goalkeeper"
local framesToGoal = stateRecord.state.framesToGoal
if isGoalkeeper and framesToGoal then
resimulate = false
-- elseif not playerIsNetworkOwner then
-- resimulate = true
-- self.skipResimulation = false
-- self.ignoreServerState = nil
end

local lastConfirmedGuid = self.lastConfirmedGuid

local guidChanged = stateRecord.state.guid ~= lastConfirmedGuid
if guidChanged then
self.lastConfirmedGuid = stateRecord.state.guid
-- self.ignoreServerState = nil
self.skipResimulation = false
resimulate = true

if lastConfirmed then
self.localFrame = lastConfirmed
end

if not playerIsNetworkOwner then
self.mispredict = Vector3.zero
localPlayer:SetAttribute("ClearTrail", true)
end

local ballModel = localPlayer.BallModel
if not playerIsNetworkOwner then
local ball: BasePart = ballModel.Value
ball.Trail:Clear()
end
end

self.simulation:DoServerAttributeChecks()
if self.lastSlippery and self.lastSlippery ~= self.simulation.constants.slippery then
self.skipResimulation = false
resimulate = true
end
self.lastSlippery = self.simulation.constants.slippery


local becameNetworkOwner = self.simulation.state.netId ~= localPlayer.UserId and playerIsNetworkOwner

if lastConfirmed > self.localFrame+5 and not (isGoalkeeper and framesToGoal) then
self.skipResimulation = false
self.ignoreServerState = nil
resimulate = true
end
if resimulate == true and stateRecord ~= nil and not self.skipResimulation then
debug.profilebegin("Ball Controller Resimulation")

if playerIsNetworkOwner or true then
self.skipResimulation = true
end
if isGoalkeeper and framesToGoal then
self.skipResimulation = true
end

local extrapolatedServerTime = serverTime

-- Record our old state
local oldPos = self.simulation.state.pos

-- Reset our base simulation to match the server
self.simulation:ReadState(stateRecord)

-- Marker for where the server said we were
self:SpawnDebugSphere(self.simulation.state.pos, Color3.fromRGB(255, 170, 0))

CollisionModule:UpdateDynamicParts()

self.simulation.ballData:SetIsResimulating(true)


local hasOwner = stateRecord.state.ownerId ~= 0
if not hasOwner then
local ballModel = localPlayer.BallModel.Value
ballModel.BallOwner.Value = nil
end
-- Resimulate all of the commands the server has not confirmed yet

local maximumCommands = 1
if playerIsNetworkOwner then
maximumCommands = 60
end
local newCommandsToRun = math.min(totalCommandsToRun, maximumCommands)
for i = 1, newCommandsToRun do
self.localFrame += 1

local command = {}

command.deltaTime = 1/60
extrapolatedServerTime += command.deltaTime

TrajectoryModule:PositionWorld(extrapolatedServerTime, command.deltaTime)

local doCollisionChecks = i == newCommandsToRun and playerIsNetworkOwner and false
self.simulation:ProcessCommand(command, doCollisionChecks)

-- Resimulated positions
self:SpawnDebugSphere(self.simulation.state.pos, Color3.fromRGB(255, 255, 0))
end

-- Did we make a misprediction? We can tell if our predicted position isn't the same after reconstructing everything
local delta = oldPos - self.simulation.state.pos
--Add the offset to mispredict so we can blend it off
self.mispredict += delta

if (delta.magnitude > 0.1) then
mispredicted = true
end

local currentAction = stateRecord.state.action
if guidChanged then
self.simulation.ballData.teleported = currentAction == Enums.BallActions.Teleport
if stateRecord.state.action == Enums.BallActions.Deflect then
if becameNetworkOwner then
localPlayer:SetAttribute("DisableChargeShot", true)
localPlayer:SetAttribute("DisableChargeShot", nil)
end
elseif currentAction == Enums.BallActions.Teleport then
self.mispredict = Vector3.zero
localPlayer:SetAttribute("ClearTrail", true)
mispredicted = false
end

local ownerId = stateRecord.state.ownerId
if type(ownerId) == "number" then
local owner = Players:GetPlayerByUserId(ownerId)

local ballModel = localPlayer.BallModel.Value
ballModel.BallOwner.Value = owner
if owner then
owner.Ball.Value = ballModel
self.simulation.state.pos = ballModel.CFrame.Position
end
end
end

if hasOwner then
self.mispredict = Vector3.zero
mispredicted = false
end

self.simulation.ballData:SetIsResimulating(false)

debug.profileend()
end

return becameNetworkOwner, stateRecord.state.action
end

--Entry point every "frame"
function ClientBallController:Heartbeat(command, serverTime: number, deltaTime: number)
self.localFrame += 1

--Write the local frame for prediction later
command.localFrame = self.localFrame
self.aheadOfServerBy += 1

-- Step this frame
self.debug.processedCommands += 1

local hitPlayer = self.simulation:ProcessCommand(command, nil, true, true)

-- Marker for positions added since the last server update
self:SpawnDebugSphere(self.simulation.state.pos, Color3.fromRGB(44, 140, 39))

debug.profilebegin("Chickynoid Write To State")
if (self.debug.useSkipResimulationOptimization == true) then
-- Add to our state cache, which we can use for skipping resims
local cacheRecord = {}
cacheRecord.localFrame = command.localFrame
cacheRecord.stateRecord = self.simulation:WriteState()

self.localStateCache[command.localFrame] = cacheRecord
end
debug.profileend()

--Remove any sort of smoothing accumulating in the characterData
self.simulation.ballData:ClearSmoothing()

return command, hitPlayer
end

function ClientBallController:SpawnDebugSphere(pos, color)
if (self.debug.showDebugSpheres ~= true) then
return
end

if (self.debug.debugParts == nil) then
self.debug.debugParts = Instance.new("Folder")
self.debug.debugParts.Name = "ChickynoidDebugSpheres"
self.debug.debugParts.Parent = workspace
end

local part = Instance.new("Part")
part.Anchored = true
part.Color = color
part.Shape = Enum.PartType.Ball
part.Size = Vector3.new(5, 5, 5)
part.Position = pos
part.Transparency = 0.25
part.TopSurface = Enum.SurfaceType.Smooth
part.BottomSurface = Enum.SurfaceType.Smooth

part.Parent = self.debug.debugParts
end

function ClientBallController:ClearDebugSpheres()
if (self.debug.showDebugSpheres ~= true) then
return
end
if (self.debug.debugParts ~= nil) then
self.debug.debugParts:ClearAllChildren()
end
end

function ClientBallController:Destroy() end

return ClientBallController
replicatedfirst/Chickynoid/Client/ClientChickynoid.lua

--[=[
@class ClientChickynoid
@client

A Chickynoid class that handles character simulation and command generation for the client
There is only one of these for the local player
]=]
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local RemoteEvent = ReplicatedStorage:WaitForChild("ChickynoidReplication") :: RemoteEvent
local UnreliableRemoteEvent = ReplicatedStorage:WaitForChild("ChickynoidUnreliableReplication") :: UnreliableRemoteEvent

local path = game.ReplicatedFirst.Chickynoid
local Simulation = require(path.Shared.Simulation.Simulation)
local ClientMods = require(path.Client.ClientMods)
local CollisionModule = require(path.Shared.Simulation.CollisionModule)
local DeltaTable = require(path.Shared.Vendor.DeltaTable)

local CommandLayout = require(path.Shared.Simulation.CommandLayout)

local TrajectoryModule = require(path.Shared.Simulation.TrajectoryModule)
local Enums = require(path.Shared.Enums)
local EventType = Enums.EventType

local ClientChickynoid = {}
ClientChickynoid.__index = ClientChickynoid

--[=[
Constructs a new ClientChickynoid for the local player, spawning it at the specified
position. The position is just to prevent a mispredict.

@param position Vector3 -- The position to spawn this character, provided by the server.
@return ClientChickynoid
]=]
function ClientChickynoid.new(position: Vector3, characterMod: string)
local self = setmetatable({

simulation = Simulation.new(localPlayer.UserId),
predictedCommands = {},
commandTimes = {}, --for ping calcs
localStateCache = {},
characterMod = characterMod,
localFrame = 0,

lastSeenPlayerStateFrame = 0, --For the last playerState we got - the serverFrame the server was on when it was sent
prevNetworkStates = {},

mispredict = Vector3.new(0, 0, 0),

commandPacketlossPrevention = true, -- set this to true to duplicate packets

debug = {
processedCommands = 0,
showDebugSpheres = false,
useSkipResimulationOptimization = true,
debugParts = nil,
},
}, ClientChickynoid)

self.simulation.state.pos = position

--Apply the characterMod
if (self.characterMod) then
local loadedModule = ClientMods:GetMod("characters", self.characterMod)
loadedModule:Setup(self.simulation)
end

self:HandleLocalPlayer()


return self
end

function ClientChickynoid:HandleLocalPlayer() end


--[=[
The server sends each client an updated world state on a fixed timestep. This
handles state updates for this character.

@param state table -- The new state sent by the server.
@param stateDeltaFrame -- The serverFrame this delta compressed against - due to packetloss the server can't just send you the newest stuff.
@param lastConfirmed number -- The serial number of the last command confirmed by the server - can be nil!
@param serverTime - Time when command was confirmed
@param playerStateFrame -- Current frame on the server, used for tracking playerState
]=]
function ClientChickynoid:HandleNewPlayerState(stateDelta, stateDeltaTime, lastConfirmed, serverTime, playerStateFrame)
self:ClearDebugSpheres()

local stateRecord = nil

--Find the one we delta compressed against
if (stateDeltaTime ~= nil) then

local previousConfirmedState = self.prevNetworkStates[stateDeltaTime]

if (previousConfirmedState == nil) then
print("Previous confirmed time not found" , stateDeltaTime)
stateRecord = DeltaTable:DeepCopy(stateDelta)
else
stateRecord = DeltaTable:ApplyDeltaTable(previousConfirmedState, stateDelta)
end

self.prevNetworkStates[playerStateFrame] = DeltaTable:DeepCopy(stateRecord)

--Delete the older ones
for timeStamp, record in self.prevNetworkStates do
if (timeStamp < stateDeltaTime) then
self.prevNetworkStates[timeStamp] = nil
end
end
else
stateRecord = DeltaTable:DeepCopy(stateDelta)
self.prevNetworkStates[playerStateFrame] = DeltaTable:DeepCopy(stateRecord)
end

--Set the last server frame we saw a command from
self.lastSeenPlayerStateFrame = playerStateFrame

-- Build a list of the commands the server has not confirmed yet
local remainingCommands = {}

if (lastConfirmed ~= nil) then
-- For knockback due to power-ups because the local frame is extrapolated based on ping
self.localFrame = math.max(lastConfirmed, self.localFrame)


for _, cmd in self.predictedCommands do
-- event.lastConfirmed = serial number of last confirmed command by server
if cmd.localFrame > lastConfirmed then
-- Server hasn't processed this yet
table.insert(remainingCommands, cmd)
end
if cmd.localFrame == lastConfirmed then
local pingTick = self.commandTimes[cmd]
if (pingTick ~= nil) then
self.ping = (tick() - pingTick) * 1000

for key,timeStamp in self.commandTimes do
if (timeStamp < pingTick) then
self.commandTimes[key] = nil
end
end
end

end
end
end

self.predictedCommands = remainingCommands
local resimulate = true
local mispredicted = false

--Check to see if we can skip simulation
--Todo: This needs to check a lot more than position and velocity - the server should always be able to force a reconcile/resim
if (self.debug.useSkipResimulationOptimization == true) then

if (lastConfirmed ~= nil) then
local cacheRecord = self.localStateCache[lastConfirmed]
if cacheRecord then
-- This is the state we were in, if the server agrees with this, we dont have to resim
if (cacheRecord.stateRecord.state.pos - stateRecord.state.pos).magnitude < 0.05 and (cacheRecord.stateRecord.state.vel - stateRecord.state.vel).magnitude < 0.1
and not (cacheRecord.stateRecord.state.knockback == 0 and stateRecord.state.knockback > 0) then
resimulate = false
-- print("skipped resim")
end
end

-- Clear all the ones older than lastConfirmed
for key, _ in pairs(self.localStateCache) do
if key < lastConfirmed then
self.localStateCache[key] = nil
end
end
end
end

local commandsRun = 0
for _, command in remainingCommands do
commandsRun += 1
end



if resimulate == true and stateRecord ~= nil then
local extrapolatedServerTime = serverTime

-- Record our old state
local oldPos = self.simulation.state.pos

-- Reset our base simulation to match the server
self.simulation:ReadState(stateRecord)

-- Marker for where the server said we were
self:SpawnDebugSphere(self.simulation.state.pos, Color3.fromRGB(255, 170, 0))

CollisionModule:UpdateDynamicParts()

self.simulation.characterData:SetIsResimulating(true)

-- Resimulate all of the commands the server has not confirmed yet
-- print("winding forward", #remainingCommands, "commands")
debug.profilebegin("Chickynoid Resimulation")
self.simulation:DoPlayerAttributeChecks()
for _, command in remainingCommands do
extrapolatedServerTime += command.deltaTime

TrajectoryModule:PositionWorld(extrapolatedServerTime, command.deltaTime)

self.simulation:ProcessCommand(command)

-- Resimulated positions
self:SpawnDebugSphere(self.simulation.state.pos, Color3.fromRGB(255, 255, 0))

if (self.debug.useSkipResimulationOptimization == true) then
-- Add to our state cache, which we can use for skipping resims
local cacheRecord = {}
cacheRecord.localFrame = command.localFrame
cacheRecord.stateRecord = self.simulation:WriteState()

self.localStateCache[command.localFrame] = cacheRecord
end
end
debug.profileend()

self.simulation.characterData:SetIsResimulating(false)

-- Did we make a misprediction? We can tell if our predicted position isn't the same after reconstructing everything
local delta = oldPos - self.simulation.state.pos
--Add the offset to mispredict so we can blend it off

if delta.Magnitude < 10 then
self.mispredict += delta
end

-- if self.mispredict.Magnitude > 0 then
-- print(self.mispredict)
-- end
if (delta.magnitude > 0.1) then
--Mispredicted
mispredicted = true
end
end

return mispredicted, self.ping, commandsRun
end

--Entry point every "frame"
function ClientChickynoid:Heartbeat(command, serverTime: number, deltaTime: number)
self.localFrame += 1

--Store it
table.insert(self.predictedCommands, command)
self.commandTimes[command] = tick() -- record the time so we have it for ping calcs

--Write the local frame for prediction later
command.localFrame = self.localFrame

-- Step this frame
self.debug.processedCommands += 1

self.simulation:ProcessCommand(command, true)

-- Marker for positions added since the last server update
self:SpawnDebugSphere(self.simulation.state.pos, Color3.fromRGB(44, 140, 39))

debug.profilebegin("Chickynoid Write To State")
if (self.debug.useSkipResimulationOptimization == true) then
-- Add to our state cache, which we can use for skipping resims
local cacheRecord = {}
cacheRecord.localFrame = command.localFrame
cacheRecord.stateRecord = self.simulation:WriteState()

self.localStateCache[command.localFrame] = cacheRecord
end
debug.profileend()

--Remove any sort of smoothing accumulating in the characterData
self.simulation.characterData:ClearSmoothing()


return command
end

function ClientChickynoid:SpawnDebugSphere(pos, color)
if (self.debug.showDebugSpheres ~= true) then
return
end

if (self.debug.debugParts == nil) then
self.debug.debugParts = Instance.new("Folder")
self.debug.debugParts.Name = "ChickynoidDebugSpheres"
self.debug.debugParts.Parent = workspace
end

local part = Instance.new("Part")
part.Anchored = true
part.Color = color
part.Shape = Enum.PartType.Ball
part.Size = Vector3.new(5, 5, 5)
part.Position = pos
part.Transparency = 0.25
part.TopSurface = Enum.SurfaceType.Smooth
part.BottomSurface = Enum.SurfaceType.Smooth

part.Parent = self.debug.debugParts
end

function ClientChickynoid:ClearDebugSpheres()
if (self.debug.showDebugSpheres ~= true) then
return
end
if (self.debug.debugParts ~= nil) then
self.debug.debugParts:ClearAllChildren()
end
end

function ClientChickynoid:Destroy() end

return ClientChickynoid
replicatedfirst/Chickynoid/Client/ClientMods.lua
--!native
local module = {}

module.mods = {}

--[=[
Registers a single ModuleScript as a mod.
@param mod ModuleScript -- Individual ModuleScript to be loaded as a mod.
]=]
function module:RegisterMod(context: string, mod: ModuleScript)

if not mod:IsA("ModuleScript") then
warn("Attempted to load", mod:GetFullName(), "as a mod but it is not a ModuleScript")
return
end

local contents = require(mod)

if (contents == nil) then
warn("Attempted to load", mod:GetFullName(), "as a mod, but it's contents is empty.")
return
end

if (self.mods[context] == nil) then
self.mods[context] = {}
end

--Mark the name and priorty
if (contents.GetPriority ~= nil) then
contents.priority = contents:GetPriority()
else
contents.priority = 0
end
contents.name = mod.Name

table.insert(self.mods[context], contents)

table.sort(self.mods[context], function(a,b)
return a.priority > b.priority
end)
end

--[=[
Registers all descendants under this container as a mod.
@param container Instance -- Container holding mods.
]=]
function module:RegisterMods(context: string, container: Instance)

for _, mod in ipairs(container:GetDescendants()) do
if not mod:IsA("ModuleScript") then
continue
end

module:RegisterMod(context, mod)
end
end

function module:GetMod(context, name)

local list = self.mods[context]

for key,contents in pairs(list) do
if (contents.name == name) then
return contents
end
end

return nil
end

function module:GetMods(context)

if (self.mods[context] == nil) then
self.mods[context] = {}
end
return self.mods[context]
end

return module
replicatedfirst/Chickynoid/Client/ClientModule.lua
--!native
--[=[
@class ClientModule
@client

Client namespace for the Chickynoid package.
]=]

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local RemoteEvent = ReplicatedStorage:WaitForChild("ChickynoidReplication") :: RemoteEvent
local UnreliableRemoteEvent = ReplicatedStorage:WaitForChild("ChickynoidUnreliableReplication") :: RemoteEvent

local path = script.Parent.Parent

local ClientChickynoid = require(script.Parent.ClientChickynoid)
local CollisionModule = require(path.Shared.Simulation.CollisionModule)
local CharacterModel = require(script.Parent.CharacterModel)
local CharacterData = require(path.Shared.Simulation.CharacterData)
local FastSignal = require(path.Shared.Vendor.FastSignal)
local ClientMods = require(path.Client.ClientMods)
local Animations = require(path.Shared.Simulation.Animations)

local ClientBallController = require(script.Parent.ClientBallController)
local BallData = require(path.Shared.Simulation.BallData)
local BallModel = require(script.Parent.BallModel)

local Enums = require(path.Shared.Enums)
local MathUtils = require(path.Shared.Simulation.MathUtils)
local CrunchTable = require(path.Shared.Vendor.CrunchTable)
local CommandLayout = require(path.Shared.Simulation.CommandLayout)
local BallInfoLayout = require(path.Shared.Simulation.BallInfoLayout)

local FpsGraph = require(path.Client.FpsGraph)
local NetGraph = require(path.Client.NetGraph)

local Lib = require(ReplicatedFirst.Lib)

local EventType = Enums.EventType
local ClientModule = {}

ClientModule.localChickynoid = nil
ClientModule.snapshots = {}

ClientModule.localBallController = nil
ClientModule.ballModel = nil
ClientModule.prevLocalBallData = nil


ClientModule.estimatedServerTime = 0 --This is the time estimated from the snapshots
ClientModule.estimatedServerTimeOffset = 0
ClientModule.snapshotServerFrame = 0 --Server frame of the last snapshot we got
ClientModule.mostRecentSnapshotComparedTo = nil --When we've successfully compared against a previous snapshot, mark what it was (so we don't delete it!)

ClientModule.validServerTime = false
ClientModule.startTime = tick()
ClientModule.characters = {}
ClientModule.localFrame = 0
ClientModule.worldState = nil
ClientModule.fpsMax = 144 --Think carefully about changing this! Every extra frame clients make, puts load on the server
ClientModule.fpsIsCapped = true --Dynamically sets to true if your fps is fpsMax + 5
ClientModule.fpsMin = 25 --If you're slower than this, your step will be broken up

ClientModule.cappedElapsedTime = 0 --
ClientModule.timeSinceLastThink = 0
ClientModule.timeUntilRetryReset = tick() + 15 -- 15 seconds grace on connection
ClientModule.frameCounter = 0
ClientModule.frameSimCounter = 0
ClientModule.frameCounterTime = 0
ClientModule.stateCounter = 0 --Num states coming in

ClientModule.accumulatedTime = 0

ClientModule.debugBoxes = {}
ClientModule.debugMarkPlayers = nil

--Netgraph settings
ClientModule.showFpsGraph = false
ClientModule.showNetGraph = false
ClientModule.showDebugMovement = true

ClientModule.ping = 0
ClientModule.pings = {}

ClientModule.useSubFrameInterpolation = true
ClientModule.prevLocalCharacterData = nil

ClientModule.timeOfLastData = tick()

--The local character
ClientModule.characterModel = nil

--Server provided collision data
ClientModule.playerSize = Vector3.new(2,5,5)
ClientModule.collisionRoot = game.Workspace

--Milliseconds of *extra* buffer time to account for ping flux
ClientModule.interpolationBuffer = 20

--Signals
ClientModule.OnNetworkEvent = FastSignal.new()
ClientModule.OnCharacterModelCreated = FastSignal.new()
ClientModule.OnCharacterModelDestroyed = FastSignal.new()

--Callbacks
ClientModule.characterModelCallbacks = {}

ClientModule.partialSnapshot = nil
ClientModule.partialSnapshotFrame = 0

ClientModule.gameRunning = false

ClientModule.flags = {
HANDLE_CAMERA = true,
USE_PRIMARY_PART = false,
USE_ALTERNATE_TIMING = false,
}

ClientModule.shotInfo = nil :: {}?
ClientModule.doShotOnClient = true :: boolean
ClientModule.deflectInfo = nil :: {}?
ClientModule.doDeflectOnClient = false :: boolean
ClientModule.playerAction = nil :: string?
ClientModule.skillServerTime = nil :: number?
ClientModule.skillGuid = nil :: number?

ClientModule.lastResimulatedFrame = 0
ClientModule.lastResimulatedBallFrame = 0

local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera



function ClientModule:Setup()
self.localBallController = ClientBallController.new(Vector3.zero)
self.ballModel = BallModel.new()
self.ballModel:CreateModel()

local eventHandler = {}

eventHandler[EventType.DebugBox] = function(event)
ClientModule:DebugBox(event.pos, event.text)
end

--EventType.ChickynoidAdded
eventHandler[EventType.ChickynoidAdded] = function(event)
local position = event.position
print("Chickynoid spawned at", position)

if self.localChickynoid == nil then
self.localChickynoid = ClientChickynoid.new(position, event.characterMod)
end
--Force the state
self.localChickynoid.simulation:ReadState(event.state)
self.prevLocalCharacterData = nil
end

eventHandler[EventType.ChickynoidRemoving] = function(_event)
print("Local chickynoid removing")

if self.localChickynoid ~= nil then
self.localChickynoid:Destroy()
self.localChickynoid = nil
end

self.prevLocalCharacterData = nil
self.characterModel:DestroyModel()
self.characterModel = nil
localPlayer.Character = nil :: any

self.characters[localPlayer.UserId] = nil
end

-- EventType.State
local function ballStateChanged(becameNetworkOwner: boolean, newAction: number)
if not becameNetworkOwner then
return
end

if newAction == Enums.BallActions.Deflect then
local playerSimulation = self.localChickynoid.simulation
playerSimulation.characterData:PlayAnimation("Shoot", Enums.AnimChannel.Channel1, true, 0.01)
end
if newAction ~= Enums.BallActions.ServerClaim then
return
end

local isGoalkeeper = localPlayer:GetAttribute("Position") == "Goalkeeper"
if isGoalkeeper then
return
end

local ballState = self.localBallController.simulation.state
local deflectInfo = self.deflectInfo
if deflectInfo == nil then
local action = self.playerAction
local realAction = action
if realAction == "Shoot" then
realAction = "DeflectShoot"
end

if realAction then

local shotDirection = Lib.getShotDirection()
local curveFactor = localPlayer:GetAttribute("CurveFactor")
local shotPower = localPlayer:GetAttribute("ShotPower")
self.deflectInfo = {
guid = ballState.guid,
shotType = realAction,
shotPower = shotPower,
shotDirection = shotDirection,
curveFactor = curveFactor,
}
deflectInfo = self.deflectInfo
end
end

if deflectInfo == nil then
return
end
deflectInfo.guid = ballState.guid
deflectInfo.serverClaimOverride = true
self.doDeflectOnClient = true
-- ballState.ownerId = 0
-- self:DoBallDeflectionOnClient()
end
eventHandler[EventType.State] = function(event)
if self.localChickynoid == nil then
return
end

if self.lastResimulatedFrame == self.localFrame then
return
end
self.lastResimulatedFrame = self.localFrame

local mispredicted, ping, commandsRun = self.localChickynoid:HandleNewPlayerState(event.playerStateDelta, event.playerStateDeltaFrame, event.lastConfirmedCommand, event.serverTime, event.serverFrame)
if event.ballState then
local becameNetworkOwner, newAction = self.localBallController:HandleNewPlayerState(event.ballState, nil, event.ballFrame, event.serverTime, event.serverFrame, commandsRun)
ballStateChanged(becameNetworkOwner, newAction)
end

if (ping) then
--Keep a rolling history of pings
table.insert(self.pings, ping)
if #self.pings > 20 then
table.remove(self.pings, 1)
end

self.stateCounter += 1

if (self.showNetGraph == true) then
self:AddPingToNetgraph(mispredicted, event.s, event.e, ping)
end

if (mispredicted) then
FpsGraph:SetFpsColor(Color3.new(1,1,0))
else
FpsGraph:SetFpsColor(Color3.new(0,1,0))
end
end
end
eventHandler[EventType.BallState] = function(event)
if self.localChickynoid == nil then
return
end

if self.lastResimulatedBallFrame == self.localFrame then
return
end
self.lastResimulatedBallFrame = self.localFrame

local remainingCommands = {}
for _, cmd in self.localChickynoid.predictedCommands do
if cmd.localFrame > event.lastConfirmedCommand then
table.insert(remainingCommands, cmd)
end
end
local becameNetworkOwner, newAction = self.localBallController:HandleNewPlayerState(event.ballState, nil, event.ballFrame, event.serverTime, event.serverFrame, #remainingCommands)
ballStateChanged(becameNetworkOwner, newAction)
end

-- EventType.WorldState
eventHandler[EventType.WorldState] = function(event)
-- print("Got worldstate")
self.worldState = event.worldState

Animations:SetAnimationsFromWorldState(event.worldState.animations)
end


-- EventType.Snapshot
eventHandler[EventType.Snapshot] = function(event)


event = self:DeserializeSnapshot(event)

if (event == nil) then
return
end


if (self.partialSnapshot ~= nil and event.f < self.partialSnapshotFrame) then
--Discard, part of an abandoned snapshot
warn("Discarding old snapshot piece.")
return
end

if (self.partialSnapshot ~= nil and event.f ~= self.partialSnapshotFrame) then
warn("Didnt get all the pieces of a snapshot, discarding and starting anew")
self.partialSnapshot = nil
end

if (self.partialSnapshot == nil) then
self.partialSnapshot = {}
self.partialSnapshotFrame = event.f
end

if (event.f == self.partialSnapshotFrame) then
--Store it

self.partialSnapshot[event.s] = event

local foundAll = true
for j=1,event.m do

if (self.partialSnapshot[j] == nil) then
foundAll = false
break
end
end

if (foundAll == true) then

self:SetupTime(event.serverTime)

--Concatenate all the player records in here
local newRecords = {}
for _,snap in self.partialSnapshot do
for key,rec in snap.charData do
newRecords[key] = rec
end
end
event.charData = newRecords

--Record our snapshotServerFrame - this is used to let the server know what we have correctly seen
self.snapshotServerFrame = event.f

--Record the snapshot
table.insert(self.snapshots, event)
self.previousSnapshot = event

--Remove old ones, but keep the most recent one we compared to
while (#self.snapshots > 40) do
table.remove(self.snapshots,1)
end
--Clear the partial
self.partialSnapshot = nil
end
end
end

eventHandler[EventType.CollisionData] = function(event)
self.playerSize = event.playerSize
self.collisionRoot = event.data
CollisionModule:MakeWorld(self.collisionRoot, self.playerSize)
end

eventHandler[EventType.PlayerDisconnected] = function(event)
local characterRecord = self.characters[event.userId]
if (characterRecord and characterRecord.characterModel) then
characterRecord.characterModel:DestroyModel()
end
--Final Cleanup
CharacterModel:PlayerDisconnected(event.userId)
end


RemoteEvent.OnClientEvent:Connect(function(event)
self.timeOfLastData = tick()

local func = eventHandler[event.t]
if func ~= nil then
func(event)
else
self.OnNetworkEvent:Fire(self, event)
end
end)


UnreliableRemoteEvent.OnClientEvent:Connect(function(event)
self.timeOfLastData = tick()

local func = eventHandler[event.t]
if func ~= nil then
func(event)
else
self.OnNetworkEvent:Fire(self, event)
end
end)


local function Step(deltaTime)

if (self.gameRunning == false) then
return
end

if (self.showFpsGraph == false) then
FpsGraph:Hide()
end
if (self.showNetGraph == false) then
NetGraph:Hide()
end

self:DoFpsCount(deltaTime)

--Do a framerate cap to 144? fps
self.cappedElapsedTime += deltaTime
self.timeSinceLastThink += deltaTime
local fraction = 1 / self.fpsMax

--Do we process a frame?
if self.cappedElapsedTime < fraction and self.fpsIsCapped == true then
return --If not enough time for a whole frame has elapsed
end
self.cappedElapsedTime = math.fmod(self.cappedElapsedTime, fraction)


--Netgraph
if (self.showFpsGraph == true) then
FpsGraph:Scroll()
local fps = 1 / self.timeSinceLastThink
FpsGraph:AddBar(fps / 2, FpsGraph.fpsColor, 0)
end

--Think
self:ProcessFrame(self.timeSinceLastThink)

--Do Client Mods
local modules = ClientMods:GetMods("clientmods")
for _, value in pairs(modules) do
value:Step(self, self.timeSinceLastThink)
end

self.timeSinceLastThink = 0
end


local bindToRenderStepLatch = false

--BindToRenderStep is the correct place to step your own custom simulations. The dt is the same one used by particle systems and cameras.
--1) The deltaTime is sampled really early in the frame and has the least flux (way less than heartbeat)
--2) Functionally, this is similar to PreRender, but PreRender runs AFTER the camera has updated, but we need to run before it
-- (hence Enum.RenderPriority.Input)
--3) Oh No. BindToRenderStep is not called in the background, so we use heartbeat to call Step if BindToRenderStep is not available
RunService:BindToRenderStep("chickynoidCharacterUpdate", Enum.RenderPriority.Input.Value, function(dt)

if (self.flags.USE_ALTERNATE_TIMING == true) then
if (dt > 0.2) then
dt = 0.2
end
Step(dt)
bindToRenderStepLatch = false
else

end
end)

-- task.spawn(function()
-- while true do
-- local dt = task.wait()
-- xpcall(function()
-- Step(dt)
-- end, function(errorMessage)
-- warn("[ClientModule] Failed to step: " .. errorMessage)
-- end)
-- end
-- end)
RunService.Heartbeat:Connect(function(dt)

if (self.flags.USE_ALTERNATE_TIMING == true) then
if (bindToRenderStepLatch == true) then
Step(dt)
end
bindToRenderStepLatch = true
else
Step(dt)
end
end)

--Load the mods
local mods = ClientMods:GetMods("clientmods")
for _, mod in mods do
mod:Setup(self)
print("Loaded", _)
end

--Wait for the game to be loaded
task.spawn(function()

while(game:IsLoaded() == false) do
wait()
end
print("Sending loaded event")
self.gameRunning = true

--Notify the server
local event = {}
event.id = "loaded"
RemoteEvent:FireServer(event)
end)


end

function ClientModule:GetClientChickynoid()
return self.localChickynoid
end

function ClientModule:GetCollisionRoot()
return self.collisionRoot
end


function ClientModule:DoFpsCount(deltaTime)
self.frameCounter += 1
self.frameCounterTime += deltaTime

if self.frameCounterTime > 1 then
while self.frameCounterTime > 1 do
self.frameCounterTime -= 1
end
--print("FPS: real ", self.frameCounter, "( physics: ",self.frameSimCounter ,")")

if self.frameCounter > self.fpsMax + 5 then
if (self.showFpsGraph == true) then
FpsGraph:SetWarning("(Cap your fps to " .. self.fpsMax .. ")")
end
self.fpsIsCapped = true
else
if (self.showFpsGraph == true) then
FpsGraph:SetWarning("")
end
self.fpsIsCapped = false
end
if (self.showFpsGraph == true) then
if self.frameCounter == self.frameSimCounter then
FpsGraph:SetFpsText("Fps: " .. self.frameCounter .. " CmdRate: " .. self.stateCounter)
else
FpsGraph:SetFpsText("Fps: " .. self.frameCounter .. " Sim: " .. self.frameSimCounter)
end
end

self.frameCounter = 0
self.frameSimCounter = 0
self.stateCounter = 0
end
end

--Use this instead of raw tick()
function ClientModule:LocalTick()
return tick() - self.startTime
end



local ballHitbox = Instance.new("Part")
ballHitbox.Shape = Enum.PartType.Ball
ballHitbox.Size = Vector3.new(2, 2, 2)
ballHitbox.Transparency = 1
ballHitbox.Anchored = true
ballHitbox.CanCollide = false
ballHitbox.CanQuery = true
ballHitbox.CanTouch = false
function ClientModule:DoBallDeflectionOnClient()
local networkPing = localPlayer:GetAttribute("NetworkPing") or 0
local lagCompensation = networkPing/1000 + 0.3

local deflectInfo = self.deflectInfo
local shotType, shotPower, shotDirection, curveFactor = deflectInfo.shotType, deflectInfo.shotPower, deflectInfo.shotDirection, deflectInfo.curveFactor

local ballSimulation = self.localBallController.simulation
local vel, angVel = Lib.getShotVelocity(ballSimulation.constants.gravity, shotType, shotPower, shotDirection, curveFactor)
ballSimulation.state.vel = vel
ballSimulation.state.angVel = angVel

local boundary = workspace.MapItems.BallBoundary
local playerSimulation = self.localChickynoid.simulation
local playerCF = CFrame.new(playerSimulation.state.pos) * CFrame.Angles(0, playerSimulation.state.angle, 0)
local ballPos = (playerCF * CFrame.new(0, -1.65, -2)).Position
ballSimulation.state.pos = Lib.clampToBoundary(ballPos, boundary)
ballSimulation.ballData:SetTargetPosition(ballSimulation.state.pos)


ballSimulation.state.ownerId = 0
self.localBallController.mispredict = Vector3.zero
self.localBallController.ignoreServerState = tick() + lagCompensation


localPlayer:SetAttribute("DisableChargeShot", true)
localPlayer:SetAttribute("DisableChargeShot", false)

localPlayer:SetAttribute("ClearTrail", true)

local controllers = localPlayer.PlayerScripts.ClientScripts.Controllers
local EffectController = require(controllers.EffectController)
EffectController:CreateEffect("ballKicked", {localPlayer})
end

function ClientModule:ProcessFrame(deltaTime)
if self.worldState == nil then
--Waiting for worldstate
return
end
--Have we at least tried to figure out the server time?
if self.validServerTime == false then
return
end

debug.profilebegin("Chickynoid Set Up ProcessFrame")
--stats
self.frameSimCounter += 1

--Do a new frame!!
self.localFrame += 1

--Start building the world view, based on us having enough snapshots to do so
self.estimatedServerTime = self:LocalTick() - self.estimatedServerTimeOffset

--Calc the SERVER point in time to render out
--Because we need to be between two snapshots, the minimum search time is "timeBetweenFrames"
--But because there might be network flux, we add some extra buffer too
local timeBetweenServerFrames = (1 / self.worldState.serverHz)
local searchPad = math.clamp(self.interpolationBuffer, 0, 500) * 0.001
local pointInTimeToRender = self.estimatedServerTime - (timeBetweenServerFrames + searchPad)

local subFrameFraction = 0

local bulkMoveToList = { parts = {}, cframes = {} }
debug.profileend()

--Step the chickynoid
if self.localChickynoid then
local fixedPhysics = nil
if self.worldState.fpsMode == Enums.FpsMode.Hybrid then
if deltaTime >= 1 / 30 then
fixedPhysics = 30
end
elseif self.worldState.fpsMode == Enums.FpsMode.Fixed30 then
fixedPhysics = 20
elseif self.worldState.fpsMode == Enums.FpsMode.Fixed60 then
fixedPhysics = 60
elseif self.worldState.fpsMode == Enums.FpsMode.Uncapped then
fixedPhysics = nil
else
warn("Unhandled FPS Mode")
end

if fixedPhysics ~= nil then
--Fixed physics steps
local frac = 1 / fixedPhysics

deltaTime = math.min(frac*4, deltaTime)

self.accumulatedTime += deltaTime
local count = 0

local simulatingFrames = self.accumulatedTime > 0
if simulatingFrames then
debug.profilebegin("Chickynoid Do Attribute Checks")
self.localChickynoid.simulation:DoPlayerAttributeChecks()
self.localBallController.simulation:DoServerAttributeChecks()
debug.profileend()
end

while self.accumulatedTime > 0 do
self.accumulatedTime -= frac

if self.useSubFrameInterpolation == true then
--Todo: could do a small (rarely used) optimization here and only copy the 2nd to last one..
if self.localChickynoid.simulation.characterData ~= nil then
--Capture the state of the client before the current simulation
debug.profilebegin("Chickynoid Serialize CharacterData")
self.prevLocalCharacterData = self.localChickynoid.simulation.characterData:Serialize()
self.prevLocalCustomData = table.clone(self.localChickynoid.simulation.custom)
debug.profileend()
end
if self.localBallController.simulation.ballData ~= nil then
--Capture the state of the client before the current simulation
debug.profilebegin("Chickynoid Serialize BallData")
self.prevLocalBallData = self.localBallController.simulation.ballData:Serialize()
self.prevBallRotation = self.localBallController.simulation.rotation
debug.profileend()
end
end

--Step!

debug.profilebegin("Chickynoid Generate Command")
local command = self:GenerateCommandBase(pointInTimeToRender, frac)
debug.profileend()

self.localChickynoid:Heartbeat(command, pointInTimeToRender, frac)
local _, hitPlayer = self.localBallController:Heartbeat(table.clone(command), pointInTimeToRender, frac)





-- Custom system to work with Power-Up Soccer
local dataToSend = {}

-- Shooting
local function setShotInfo(override)
local info = override or self.shotInfo or {}

local shotSerial = {"Shoot"}
dataToSend.sGuid = info.guid
dataToSend.sType = table.find(shotSerial, info.shotType)
dataToSend.sPower = info.shotPower
dataToSend.sDirection = info.shotDirection
dataToSend.sCurveFactor = info.curveFactor
end

local Lib = require(ReplicatedStorage.Lib)

debug.profilebegin("Chickynoid Shot Info")
local ballSimulation = self.localBallController.simulation
local ballState = ballSimulation.state
local shotInfo = self.shotInfo
if shotInfo and shotInfo.guid < ballState.guid then
self.shotInfo = nil
shotInfo = nil
setShotInfo()
Lib.removeCooldown(localPlayer, "ClientBallClaimCooldown")
end

local networkPing = localPlayer:GetAttribute("NetworkPing") or 0
local lagCompensation = networkPing/1000 + 0.3
if shotInfo and self.doShotOnClient then
self.doShotOnClient = false
task.spawn(function()
if not game:IsLoaded() then
return
end

local shotType, shotPower, shotDirection, curveFactor = shotInfo.shotType, shotInfo.shotPower, shotInfo.shotDirection, shotInfo.curveFactor
Lib.setCooldown(localPlayer, "ClientBallClaimCooldown", lagCompensation)

local boundary = workspace.MapItems.BallBoundary
local playerSimulation = self.localChickynoid.simulation
local playerCF = CFrame.new(playerSimulation.state.pos) * CFrame.Angles(0, playerSimulation.state.angle, 0)
local ballPos = (playerCF * CFrame.new(0, -1.65, -2)).Position
if localPlayer:GetAttribute("Position") == "Goalkeeper" then
ballPos = (playerCF * CFrame.new(0, 1, -2)).Position
end
ballSimulation.state.pos = Lib.clampToBoundary(ballPos, boundary)
ballSimulation.ballData:SetTargetPosition(ballSimulation.state.pos)

local vel, angVel = Lib.getShotVelocity(ballSimulation.constants.gravity, shotType, shotPower, shotDirection, curveFactor)
ballSimulation.state.vel = vel
ballSimulation.state.angVel = angVel

ballSimulation.state.ownerId = 0

self.localBallController.mispredict = Vector3.zero
self.localBallController.ignoreServerState = tick() + lagCompensation

local controllers = localPlayer.PlayerScripts.ClientScripts.Controllers
local EffectController = require(controllers.EffectController)
EffectController:CreateEffect("ballKicked", {localPlayer})
end)
end
setShotInfo() -- keep sending it in case it gets lost, shooting is something that needs to always be received by the server
debug.profileend()


debug.profilebegin("Chickynoid Deflect Info")
-- Deflection
local simulation = self.localChickynoid.simulation
local function setDeflectInfo(override)
local info = override or self.deflectInfo or {}

local shotSerial = {"DeflectShoot"}
dataToSend.dGuid = info.guid
dataToSend.dType = table.find(shotSerial, info.shotType)
dataToSend.dPower = info.shotPower
dataToSend.dDirection = info.shotDirection
dataToSend.dCurveFactor = info.curveFactor
dataToSend.dServerDeflect = if info.serverClaimOverride then 1 else nil
end
local deflectInfo = self.deflectInfo
if deflectInfo and deflectInfo.guid < ballState.guid then
self.deflectInfo = nil
deflectInfo = nil
setDeflectInfo()
end
if deflectInfo and deflectInfo.serverClaimOverride then
dataToSend.claimPos = ballSimulation.state.pos
setDeflectInfo()
if self.doDeflectOnClient then
self.doDeflectOnClient = false
self:DoBallDeflectionOnClient()
end
elseif hitPlayer and not Lib.isOnCooldown(localPlayer, "ClientBallClaimCooldown") then
dataToSend.claimPos = ballSimulation.state.pos
setDeflectInfo()

local action = self.playerAction
local realAction = action
if realAction == "Shoot" then
realAction = "DeflectShoot"
end

if realAction == nil then
self.deflectInfo = nil
end

local isGoalkeeper = localPlayer:GetAttribute("Position") == "Goalkeeper"
local ignoreServerState = self.localBallController.ignoreServerState
if not isGoalkeeper and (ignoreServerState == nil or tick() - ignoreServerState > 0) and not Lib.playerIsStunned(localPlayer) then
-- Deflection
local shotDirection = Lib.getShotDirection()

local curveFactor = localPlayer:GetAttribute("CurveFactor")

if realAction then
if deflectInfo == nil then
local shotPower = localPlayer:GetAttribute("ShotPower")
self.deflectInfo = {
guid = ballState.guid,
shotType = realAction,
shotPower = shotPower,
shotDirection = shotDirection,
curveFactor = curveFactor,
}
setDeflectInfo()

if ballSimulation.state.netId == localPlayer.UserId then
self:DoBallDeflectionOnClient()
end
end
else
if ballSimulation.state.netId == localPlayer.UserId and not deflectInfo then
ballSimulation.state.ownerId = localPlayer.UserId
self.localBallController.ignoreServerState = tick() + lagCompensation
end
end
end

if not self.deflectInfo and realAction then
dataToSend.claimPos = nil
end
end
if dataToSend.claimPos == nil and localPlayer:GetAttribute("Position") == "Goalkeeper" then
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("GoalHitbox")
local goalHitBox = workspace:GetPartBoundsInRadius(ballSimulation.state.pos, 1, overlapParams)
if goalHitBox[1] ~= nil then
dataToSend.enteredGoal = 1
end
end
debug.profileend()


debug.profilebegin("Chickynoid Tackle")
-- Tackling
local assets = ReplicatedStorage.Assets
if localPlayer:GetAttribute("InGame") and simulation.state.tackle > 0 then
xpcall(function()
local tackleHitBox: BasePart = assets.Hitboxes.Tackle
if localPlayer:GetAttribute("Position") == "Goalkeeper" then
local diveHitboxTemplate = assets.Hitboxes.Dive:FindFirstChild(localPlayer:GetAttribute("ClientDiveHitbox"))
if diveHitboxTemplate == nil then
return
end
tackleHitBox = diveHitboxTemplate
end

local filter = {}
for _, characterInfo in pairs(self.characters) do
if characterInfo.userId == localPlayer.UserId then
continue
end
local characterModel = characterInfo.characterModel
if characterModel and characterModel.model then
table.insert(filter, characterModel.model)
end
end

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = filter

local playerSimulation = self.localChickynoid.simulation
local playerCF = CFrame.new(playerSimulation.state.pos) * CFrame.Angles(0, playerSimulation.state.angle, 0)
local charactersToTackle = workspace:GetPartBoundsInBox(playerCF * tackleHitBox.PivotOffset:Inverse(), tackleHitBox.Size, overlapParams)
for _, part in pairs(charactersToTackle) do
local character = part.Parent
local userid = character:GetAttribute("userid")
if userid == nil then continue end
local player = Players:GetPlayerByUserId(userid)
if player == nil then continue end
if player.Ball.Value == nil then continue end
dataToSend.tackledEnemy = 1
break
end
end, function(errorMessage)
warn("[ClientModule] Tackle Hitbox error: " .. errorMessage)
end)
end
debug.profileend()

debug.profilebegin("Chickynoid Skill")
local skillServerTime = self.skillServerTime
local skillGuid = self.skillGuid
if skillServerTime and (skillGuid and skillGuid ~= ballSimulation.state.guid or self.estimatedServerTime - skillServerTime > 0.5) then
self.skillServerTime = nil
self.skillGuid = nil
skillServerTime = nil
end
if skillServerTime then
dataToSend.skill = skillServerTime
setDeflectInfo({})
self.skillGuid = ballSimulation.state.guid
end
debug.profileend()

-- Pass to server
debug.profilebegin("Chickynoid Encode Commands")
dataToSend = BallInfoLayout:EncodeCommand(dataToSend)
local event = {}
event[1] = {
CommandLayout:EncodeCommand(command),
dataToSend,
}

local chickynoid = self.localChickynoid

local prevCommand = nil
if (#chickynoid.predictedCommands > 1 and chickynoid.commandPacketlossPrevention == true) then
prevCommand = chickynoid.predictedCommands[#chickynoid.predictedCommands - 1]
event[2] = {
CommandLayout:EncodeCommand(prevCommand),
self.lastDataSent,
}
end
self.lastDataSent = dataToSend
debug.profileend()

debug.profilebegin("Chickynoid Send To Server")
UnreliableRemoteEvent:FireServer(event)
debug.profileend()

count += 1
end
if simulatingFrames then
self.localChickynoid.simulation:UpdatePlayerAttributes()
end

if self.useSubFrameInterpolation == true then
--if this happens, we have over-simulated
if self.accumulatedTime < 0 then
--we need to do a sub-frame positioning
local subFrame = math.abs(self.accumulatedTime) --How far into the next frame are we (we've already simulated 100% of this)
subFrame /= frac --0..1
if subFrame < 0 or subFrame > 1 then
warn("Subframe calculation wrong", subFrame)
end
subFrameFraction = 1 - subFrame
end
end

if (self.showFpsGraph == true) then
if count > 0 then
local pixels = 1000 / fixedPhysics
FpsGraph:AddPoint((count * pixels), Color3.new(0, 1, 1), 3)
FpsGraph:AddBar(math.abs(self.accumulatedTime * 1000), Color3.new(1, 1, 0), 2)
else
FpsGraph:AddBar(math.abs(self.accumulatedTime * 1000), Color3.new(1, 1, 0), 2)
end
end
else
--For this to work, the server has to accept deltaTime from the client
local command = self:GenerateCommandBase(pointInTimeToRender, deltaTime)
self.localChickynoid:Heartbeat(command, pointInTimeToRender, deltaTime)
end

local mod = self:GetPlayerDataByUserId(localPlayer.UserId)
if self.characterModel == nil and self.localChickynoid ~= nil then
debug.profilebegin("Chickynoid Local Character Creation")

--Spawn the character in
-- print("Creating local model for UserId", localPlayer.UserId)
self.characterModel = CharacterModel.new(localPlayer.UserId, mod.characterMod)
for _, characterModelCallback in ipairs(self.characterModelCallbacks) do
self.characterModel:SetCharacterModel(characterModelCallback)
end

self.characterModel.onModelCreated:Connect(function()
self.OnCharacterModelCreated:Fire(self.characterModel)
end)
self.characterModel:CreateModel(mod.avatar)

local record = {}
record.userId = localPlayer.UserId
record.characterModel = self.characterModel
record.localPlayer = true
self.characters[record.userId] = record

debug.profileend()
elseif self.characterModel and self.characterModel.characterMod ~= mod.characterMod then
if not self.characterModel.coroutineStarted then
debug.profilebegin("Chickynoid Replace Local Character Model")
self.characterModel.characterMod = mod.characterMod
self.characterModel:ReplaceModel(mod.avatar)
debug.profileend()
end
end

if self.characterModel ~= nil then
--Blend out the mispredict value

debug.profilebegin("Chickynoid Local Character Mispredict")
self.localChickynoid.mispredict = MathUtils:VelocityFriction(
self.localChickynoid.mispredict,
0.1,
deltaTime
)
self.characterModel.mispredict = self.localChickynoid.mispredict

self.localBallController.mispredict = MathUtils:VelocityFriction(
self.localBallController.mispredict,
0.1,
deltaTime
)
self.ballModel.mispredict = self.localBallController.mispredict
debug.profileend()


local localRecord = self.characters[localPlayer.UserId]

if
self.useSubFrameInterpolation == false
or subFrameFraction == 0
or self.prevLocalCharacterData == nil
then
self.characterModel:Think(deltaTime, self.localChickynoid.simulation.characterData.serialized, bulkMoveToList, self.localChickynoid.simulation.custom)
localRecord.characterData = self.localChickynoid.simulation.characterData
else
--Calculate a sub-frame interpolation
debug.profilebegin("Chickynoid Local Character Interpolation")
local data = CharacterData:Interpolate(
self.prevLocalCharacterData,
self.localChickynoid.simulation.characterData.serialized,
subFrameFraction
)

local currentCustomData = self.localChickynoid.simulation.custom
local customData = table.clone(self.prevLocalCustomData)
customData.animDir = currentCustomData.animDir
customData.leanAngle = MathUtils:Vector2Lerp(customData.leanAngle, currentCustomData.leanAngle, subFrameFraction)
customData.ballQuaternion = customData.ballQuaternion:Slerp(currentCustomData.ballQuaternion, subFrameFraction)
debug.profileend()

self.characterModel:Think(deltaTime, data, bulkMoveToList, customData)
localRecord.characterData = data
self.recordCustomData = customData
end

debug.profilebegin("Chickynoid Local Ball Think")
local currentRotation = self.localBallController.simulation.rotation
if
self.useSubFrameInterpolation == false
or subFrameFraction == 0
or self.prevLocalBallData == nil
then
self.ballModel:Think(deltaTime, self.localBallController.simulation.ballData.serialized, bulkMoveToList, currentRotation)
else
local ballData = BallData:Interpolate(
self.prevLocalBallData,
self.localBallController.simulation.ballData.serialized,
subFrameFraction
)
self.ballModel:Think(deltaTime, ballData, bulkMoveToList, self.prevBallRotation:Slerp(currentRotation, subFrameFraction))
end
debug.profileend()

--store local data
localRecord.frame = self.localFrame
localRecord.position = localRecord.characterData.pos

if (self.showFpsGraph == true) then
if self.showDebugMovement == true then
local pos = localRecord.position
if self.previousPos ~= nil then
local delta = pos - self.previousPos
FpsGraph:AddPoint(delta.magnitude * 200, Color3.new(0, 0, 1), 4)
end
self.previousPos = pos
end
end

-- Bind the camera
if (self.flags.HANDLE_CAMERA ~= false) then
local camera = game.Workspace.CurrentCamera

if (self.flags.USE_PRIMARY_PART == true) then
--if you dont care about first person, this is the correct way to do it
--for models with no humanoid (head tracking)
if ( self.characterModel.model and self.characterModel.model.PrimaryPart) then
if camera.CameraSubject ~= self.characterModel.model.PrimaryPart then
camera.CameraSubject = self.characterModel.model.PrimaryPart
camera.CameraType = Enum.CameraType.Custom
end
end
else
--if you do, set it to the model
if self.characterModel.model and camera.CameraSubject ~= self.characterModel.model then
if not localPlayer:GetAttribute("Spectating") and not localPlayer:GetAttribute("GoalScoredFocus") then
debug.profilebegin("Chickynoid - setting camera subject")
camera.CameraSubject = self.characterModel.model
camera.CameraType = Enum.CameraType.Custom
debug.profileend()
end
end
end
end

--Bind the local character, which activates all the thumbsticks etc
debug.profilebegin("Chickynoid Local Character Set")
localPlayer.Character = self.characterModel.model
debug.profileend()
end
end

debug.profilebegin("Chickynoid Snapshot Finder")
local last = nil
local prev = self.snapshots[1]
for _, value in pairs(self.snapshots) do
if value.serverTime > pointInTimeToRender then
last = value
break
end
prev = value
end
debug.profileend()

local debugData = {}

debug.profilebegin("Chickynoid Character Creation/Thinking")

if prev and last and prev ~= last then

--So pointInTimeToRender is between prev.t and last.t
local frac = (pointInTimeToRender - prev.serverTime) / timeBetweenServerFrames

debugData.frac = frac
debugData.prev = prev.t
debugData.last = last.t


for userId, lastData in last.charData do

local prevData = prev.charData[userId]

if prevData == nil then
continue
end

local dataRecord = CharacterData:Interpolate(prevData, lastData, frac)
local character = self.characters[userId]

--Add the character
local mod = self:GetPlayerDataByUserId(userId)
if character == nil then
local record = {}
record.userId = userId
record.characterModel = CharacterModel.new(userId, mod.characterMod)

record.characterModel.onModelCreated:Connect(function()
self.OnCharacterModelCreated:Fire(record.characterModel)
end)
record.characterModel:CreateModel(mod.avatar)

character = record
self.characters[userId] = record
elseif character.characterModel and mod and character.characterModel.characterMod ~= mod.characterMod then
local characterModel = character.characterModel
if not characterModel.coroutineStarted then
characterModel.characterMod = mod.characterMod
characterModel:ReplaceModel(mod.avatar)
end
end

character.frame = self.localFrame
character.position = dataRecord.pos
character.characterData = dataRecord


--Update it
character.characterModel:Think(deltaTime, dataRecord, bulkMoveToList)
end


--Remove any characters who were not in this snapshot
for key, value in self.characters do

if (key == localPlayer.UserId) then
continue
end

if value.frame ~= self.localFrame then
self.OnCharacterModelDestroyed:Fire(value.characterModel)

value.characterModel:DestroyModel()
value.characterModel = nil

self.characters[key] = nil
end
end
end

debug.profileend()

--bulkMoveTo
debug.profilebegin("Chickynoid BulkMoveTo")
if (bulkMoveToList) then
game.Workspace:BulkMoveTo(bulkMoveToList.parts, bulkMoveToList.cframes, Enum.BulkMoveMode.FireCFrameChanged)
if localPlayer:GetAttribute("ClearTrail") then
localPlayer:SetAttribute("ClearTrail", nil)
self.ballModel.model.Trail:Clear()
end
end
debug.profileend()

--render in the rockets
-- local timeToRenderRocketsAt = self.estimatedServerTime

if (self.debugMarkPlayers ~= nil) then
self:DrawBoxOnAllPlayers(self.debugMarkPlayers)
self.debugMarkPlayers = nil
end
end

function ClientModule:GetCharacters()
return self.characters
end

-- This tries to figure out a correct delta for the server time
-- Better to update this infrequently as it will cause a "pop" in prediction
-- Thought: Replace with roblox solution or converging solution?
function ClientModule:SetupTime(serverActualTime)
local oldDelta = self.estimatedServerTimeOffset
local newDelta = self:LocalTick() - serverActualTime
self.validServerTime = true

local delta = oldDelta - newDelta
if math.abs(delta * 1000) > 50 then --50ms out? try again
self.estimatedServerTimeOffset = newDelta
end
end

-- Register a callback that will determine a character model
function ClientModule:SetCharacterModel(callback)
table.insert(self.characterModelCallbacks, callback)
end

function ClientModule:GetPlayerDataBySlotId(slotId)
local slotString = tostring(slotId)
if (self.worldState == nil) then
return nil
end
--worldState.players is indexed by a *STRING* not a int
return self.worldState.players[slotString]
end

function ClientModule:GetBallDataBySlotId(slotId)
local slotString = tostring(slotId)
if (self.worldState == nil) then
return nil
end
--worldState.players is indexed by a *STRING* not a int
return self.worldState.balls[slotString]
end

function ClientModule:GetPlayerDataByUserId(userId)

if (self.worldState == nil) then
return nil
end
for key,value in pairs(self.worldState.players) do
if (value.userId == userId) then
return value
end
end

return nil
end


function ClientModule:DeserializeSnapshot(event)

local offset = 0
local bitBuffer = event.b
local recordCount = buffer.readu8(bitBuffer,offset)
offset+=1

--Find what this was delta compressed against
local previousSnapshot = nil

for key, value in self.snapshots do
if (value.f == event.cf) then
previousSnapshot = value
break
end
end
if (previousSnapshot == nil and event.cf ~= nil) then
if RunService:IsStudio() then
warn("Prev snapshot not found" , event.cf)
print("num snapshots", #self.snapshots)
end
return nil
end
self.mostRecentSnapshotComparedTo = previousSnapshot

event.charData = {}

for _ = 1, recordCount do
local record = CharacterData.new()

--CharacterData.CopyFrom(self.previous)

local slotId = buffer.readu8(bitBuffer,offset)
offset+=1

local user = self:GetPlayerDataBySlotId(slotId)
if user then
if previousSnapshot ~= nil then
local previousRecord = previousSnapshot.charData[user.userId]
if previousRecord then
record:CopySerialized(previousRecord)
end
end
offset = record:DeserializeFromBitBuffer(bitBuffer, offset)

event.charData[user.userId] = record.serialized
else

warn("UserId for slot " .. slotId .. " not found!")
--So things line up
offset = record:DeserializeFromBitBuffer(bitBuffer, offset)
end
end


return event
end

function ClientModule:GetGui()
local gui = localPlayer:FindFirstChild("PlayerGui")
return gui
end

function ClientModule:DebugMarkAllPlayers(text)
self.debugMarkPlayers = text
end

function ClientModule:DrawBoxOnAllPlayers(text)
if self.worldState == nil then
return
end
if self.worldState.flags.DEBUG_ANTILAG ~= true then
return
end

local models = self:GetCharacters()
for _, record in pairs(models) do

if (record.localPlayer == true) then
continue
end

local instance = Instance.new("Part")
instance.Size = Vector3.new(3, 5, 3)
instance.Transparency = 0.5
instance.Color = Color3.new(0, 1, 0)
instance.Anchored = true
instance.CanCollide = false
instance.CanTouch = false
instance.CanQuery = false
instance.Position = record.position
instance.Parent = game.Workspace

self:AdornText(instance, Vector3.new(0,3,0), text, Color3.new(0.5,1,0.5))

self.debugBoxes[instance] = tick() + 5
end

for key, value in pairs(self.debugBoxes) do
if tick() > value then
key:Destroy()
self.debugBoxes[key] = nil
end
end
end

function ClientModule:DebugBox(pos, text)
local instance = Instance.new("Part")
instance.Size = Vector3.new(3, 5, 3)
instance.Transparency = 1
instance.Color = Color3.new(1, 0, 0)
instance.Anchored = true
instance.CanCollide = false
instance.CanTouch = false
instance.CanQuery = false
instance.Position = pos
instance.Parent = game.Workspace

local adornment = Instance.new("SelectionBox")
adornment.Adornee = instance
adornment.Parent = instance

self.debugBoxes[instance] = tick() + 5

self:AdornText(instance, Vector3.new(0,6,0), text, Color3.new(0, 0.501960, 1))
end

function ClientModule:AdornText(part, offset, text, color)

local attachment = Instance.new("Attachment")
attachment.Parent = part
attachment.Position = offset

local billboard = Instance.new("BillboardGui")
billboard.AlwaysOnTop = true
billboard.Size = UDim2.new(0,50,0,20)
billboard.Adornee = attachment
billboard.Parent = attachment

local textLabel = Instance.new("TextLabel")
textLabel.TextScaled = true
textLabel.TextColor3 = color
textLabel.BackgroundTransparency = 1
textLabel.Size = UDim2.new(1,0,1,0)
textLabel.Text = text
textLabel.Parent = billboard
textLabel.AutoLocalize = false
end


function ClientModule:AddPingToNetgraph(mispredicted, serverHealthFps, networkProblem, ping)

--Ping graph
local total = 0
for _, ping in pairs(self.pings) do
total += ping
end
total /= #self.pings

NetGraph:Scroll()

local color1 = Color3.new(1, 1, 1)
local color2 = Color3.new(1, 1, 0)
if mispredicted == false then
NetGraph:AddPoint(ping * 0.25, color1, 4)
NetGraph:AddPoint(total * 0.25, color2, 3)
else
NetGraph:AddPoint(ping * 0.25, color1, 4)
local tint = Color3.new(0.5, 1, 0.5)
NetGraph:AddPoint(total * 0.25, tint, 3)
NetGraph:AddBar(10 * 0.25, tint, 1)
end

--Server fps
if serverHealthFps >= 60 then
NetGraph:AddPoint(serverHealthFps, Color3.new(0.101961, 1, 0), 2)
elseif serverHealthFps >= 50 then
NetGraph:AddPoint(serverHealthFps, Color3.new(1, 0.666667, 0), 2)
else
NetGraph:AddPoint(serverHealthFps, Color3.new(1, 0, 0), 2)
end

--Blue bar
if networkProblem == Enums.NetworkProblemState.TooFarBehind then
NetGraph:AddBar(100, Color3.new(0, 0, 1), 0)
end
--Yellow bar
if networkProblem == Enums.NetworkProblemState.TooFarAhead then
NetGraph:AddBar(100, Color3.new(1, 0.615686, 0), 0)
end
--Orange bar
if networkProblem == Enums.NetworkProblemState.TooManyCommands then
NetGraph:AddBar(100, Color3.new(1, 0.666667, 0), 0)
end
--teal bar
if networkProblem == Enums.NetworkProblemState.CommandUnderrun then
NetGraph:AddBar(100, Color3.new(0, 1, 1), 0)
end

--Yellow bar
if networkProblem == Enums.NetworkProblemState.DroppedPacketGood then
NetGraph:AddBar(100, Color3.new(0.898039, 1, 0), 0)
end
--Red Bar
if networkProblem == Enums.NetworkProblemState.DroppedPacketBad then
NetGraph:AddBar(100, Color3.new(1, 0, 0), 0)
end


NetGraph:SetFpsText("Ping: " .. math.floor(total) .. "ms")
NetGraph:SetOtherFpsText("ServerFps: " .. serverHealthFps)
end

function ClientModule:IsConnectionBad()

local pings
if #self.pings > 10 and self.ping > 2000 then
return true
end
return false
end

function ClientModule:GenerateCommandBase(serverTime, deltaTime)

local command = {}
command.serverTime = serverTime --For rollback - a locally interpolated value
command.deltaTime = deltaTime --How much time this command simulated
command.snapshotServerFrame = self.snapshotServerFrame --Confirm to the server the last snapshot we saw
command.playerStateFrame = self.localChickynoid.lastSeenPlayerStateFrame --Confirm to server the last playerState we saw

command.x = 0
command.y = 0
command.z = 0

local modules = ClientMods:GetMods("clientmods")

for key,mod in modules do
if (mod.GenerateCommand) then
command = mod:GenerateCommand(command, serverTime, deltaTime, ClientModule)
end
end

return command
end


return ClientModule
replicatedfirst/Chickynoid/Client/Effects.lua
local RunService = game:GetService("RunService")

local module = {}

module.root = script.Parent.Parent.Assets:FindFirstChild("Effects")
module.particles = {}

--Ultra simple effects module.
function module:SpawnEffect(name, pos)
local src = module.root:FindFirstChild(name, true)

if src == nil then
warn("Effect not found " .. name)
return
end

local clone = src:Clone() :: BasePart
clone.Position = pos
clone.Parent = game.Workspace

local record = {}
record.instance = clone
record.emitters = {}
record.sounds = {}

for _, value in pairs(clone:GetDescendants()) do
if value:IsA("ParticleEmitter") then
value = value :: ParticleEmitter -- Luau types moment :(

local emitterRecord = {}
emitterRecord.instance = value
emitterRecord.life = 0

emitterRecord.afterLife = value.Lifetime.Max
local lifeAttribute = value:GetAttribute("life")
if lifeAttribute ~= nil then
emitterRecord.life = lifeAttribute
end

local emitAttribute = value:GetAttribute("emit")
if emitAttribute then
emitterRecord.instance:Emit(emitAttribute)
emitterRecord.instance.Rate = 0
emitterRecord.life = 0
end

record.emitters[value] = emitterRecord
elseif value:IsA("Sound") then
value = value :: Sound -- Luau types moment x2 :(

value:Play()

local variation = value:GetAttribute("variation")

if variation then
value.PlaybackSpeed *= 1 + (math.random() * variation)
end

local soundRecord = {}
soundRecord.life = value.TimeLength / value.PlaybackSpeed
soundRecord.instance = value
record.sounds[value] = soundRecord
end
end

module.particles[clone] = record

return clone
end

function module:Heartbeat(deltaTime)
for key, record in pairs(module.particles) do
local allDone = true
for _, particleRecord in pairs(record.emitters) do
if particleRecord.life > 0 then
particleRecord.life -= deltaTime
if particleRecord.life <= 0 then
--stop emitting
particleRecord.instance.Rate = 0
end
else
particleRecord.afterLife -= deltaTime
end

if particleRecord.afterLife < 0 and particleRecord.instance ~= nil then
particleRecord.instance:Destroy()
end

if particleRecord.afterLife > 0 then
allDone = false
end
end
for _, soundRecord in pairs(record.sounds) do
if soundRecord.life > 0 then
allDone = false
soundRecord.life -= deltaTime
end
end

if allDone == true then
record.instance:Destroy()
module.particles[key] = nil
end
end
end

-- TODO: We shouldn't connect to heartbeat here. Refactor this later.
RunService.Heartbeat:Connect(function(deltaTime)
module:Heartbeat(deltaTime)
end)

function Preload()
task.spawn(function()

local list = {}
for key,value in module.root:GetDescendants() do

if (value:IsA("ParticleEmitter")) then
table.insert(list, value.Texture)
end
end
print("Preloading ", #list, " assets")
game.ContentProvider:PreloadAsync(list)
end)
end
Preload()

return module
replicatedfirst/Chickynoid/Client/FpsGraph.lua
--!native
local module = {}
module.ui = nil
module.fpsColor = Color3.new(0,1,0)

function module:SetFpsColor(color)
module.fpsColor = color
end

function module:AddPoint(y, color, layer)
self:GetGui()

if module.ui == nil then
return
end

local points = module.ui.Frame:FindFirstChild("Points")
if points == nil then
return
end
if layer == nil then
layer = 0
end
if y == nil then
y = 0
end
y = math.clamp(y, 1, 100)

local child = Instance.new("Frame")
child.BorderSizePixel = 0
child.Size = UDim2.new(0, 1, 0, 1)
child.Position = UDim2.new(0, points.AbsoluteSize.x - 1, 0, 100 - math.floor(y))
child.Parent = points
child.ZIndex = layer
child.BackgroundTransparency = 0.5

if color == nil then
child.BackgroundColor3 = Color3.new(0, 0, 0)
else
child.BackgroundColor3 = color
end
end


function module:AddBar(y, color, layer)
self:GetGui()

if module.ui == nil then
return
end

local points = module.ui.Frame:FindFirstChild("Points")
if points == nil then
return
end
if layer == nil then
layer = 0
end
if y == nil then
y = 0
end
y = math.clamp(y, 1, 100)

local child = Instance.new("Frame")
child.BorderSizePixel = 0
child.Size = UDim2.new(0, 1, 0, math.floor(y))
child.Position = UDim2.new(0, points.AbsoluteSize.x - 1, 0, points.AbsoluteSize.y - math.floor(y))
child.ZIndex = layer
child.BackgroundTransparency = 0.5
child.Name = "Bar"


if color == nil then
child.BackgroundColor3 = Color3.new(0, 0, 0)
else
child.BackgroundColor3 = color
end
child.Parent = points
end

function module:SetWarning(warningText)
self:GetGui()

if module.ui == nil then
return
end

local warning = module.ui.Frame.Warning
if warning == nil then
return
end
warning.Text = warningText
end

function module:SetFpsText(warningText)
self:GetGui()

if module.ui == nil then
return
end

local warning = module.ui.Frame.FpsText
if warning == nil then
return
end
warning.Text = warningText
end

function module:Scroll()
self:GetGui()

if module.ui == nil then
return
end

local points = module.ui.Frame:FindFirstChild("Points")
if points == nil then
return
end

for _, point in pairs(points:GetChildren()) do
local pos = point.Position
if pos.X.Offset <= 0 then
point:Destroy()
else
point.Position = UDim2.new(pos.X.Scale, pos.X.Offset - 1, pos.Y.Scale, pos.Y.Offset)
end
end
end

function module:GetGui()
if game.Players.LocalPlayer == nil then
return nil
end
if game.Players.LocalPlayer.PlayerGui == nil then
return nil
end

if module.ui == nil then
module.ui = script.Parent:FindFirstChild("FpsGraphUI"):Clone()
module.ui.Parent = game.Players.LocalPlayer.PlayerGui
end

return module.ui
end

function module:Hide()
if module.ui ~= nil then
module.ui:Destroy()
module.ui = nil
end
end

return module
replicatedfirst/Chickynoid/Client/NetGraph.lua
--!native
local module = {}
module.ui = nil

function module:AddPoint(y, color, layer)
self:GetGui()

if module.ui == nil then
return
end

local points = module.ui.Frame:FindFirstChild("Points")
if points == nil then
return
end
if layer == nil then
layer = 0
end
if y == nil then
y = 0
end
y = math.clamp(y, 1, 100)

local child = Instance.new("Frame")
child.BorderSizePixel = 0
child.Size = UDim2.new(0, 1, 0, 1)
child.Position = UDim2.new(0, points.AbsoluteSize.x - 1, 0, 100 - math.floor(y))
child.Parent = points
child.ZIndex = layer
child.BackgroundTransparency = 0

if color == nil then
child.BackgroundColor3 = Color3.new(0, 0, 0)
else
child.BackgroundColor3 = color
end
end

function module:AddBar(y, color, layer)
self:GetGui()

if module.ui == nil then
return
end

local points = module.ui.Frame:FindFirstChild("Points")
if points == nil then
return
end
if layer == nil then
layer = 0
end
if y == nil then
y = 0
end
y = math.clamp(y, 1, 100)

local child = Instance.new("Frame")
child.BorderSizePixel = 0
child.Size = UDim2.new(0, 1, 0, math.floor(y))
child.Position = UDim2.new(0, points.AbsoluteSize.x - 1, 0, 100 - math.floor(y))
child.Parent = points
child.ZIndex = layer
child.BackgroundTransparency = 0.5
if color == nil then
child.BackgroundColor3 = Color3.new(0, 0, 0)
else
child.BackgroundColor3 = color
end
end

function module:SetWarning(warningText)
self:GetGui()

if module.ui == nil then
return
end

local warning = module.ui.Frame.Warning
if warning == nil then
return
end
warning.Text = warningText
end

function module:SetFpsText(warningText)
self:GetGui()

if module.ui == nil then
return
end

local warning = module.ui.Frame.FpsText
if warning == nil then
return
end
warning.Text = warningText
end

function module:SetOtherFpsText(warningText)
self:GetGui()

if module.ui == nil then
return
end

local warning = module.ui.Frame.OtherFpsText
if warning == nil then
return
end
warning.Text = warningText
end

function module:Scroll()
self:GetGui()

if module.ui == nil then
return
end

local points = module.ui.Frame:FindFirstChild("Points")
if points == nil then
return
end

for _, point in pairs(points:GetChildren()) do
local pos = point.Position
if pos.X.Offset <= 0 then
point:Destroy()
else
point.Position = UDim2.new(pos.X.Scale, pos.X.Offset - 1, pos.Y.Scale, pos.Y.Offset)
end
end
end

function module:GetGui()
if game.Players.LocalPlayer == nil then
return nil
end
if game.Players.LocalPlayer.PlayerGui == nil then
return nil
end

if module.ui == nil then
module.ui = script.Parent:FindFirstChild("NetGraphUI"):Clone()
module.ui.Parent = game.Players.LocalPlayer.PlayerGui
end

return module.ui
end

function module:Hide()
if module.ui ~= nil then
module.ui:Destroy()
module.ui = nil
end
end

return module
replicatedfirst/Chickynoid/Client/WeaponsClient.lua
local module = {}

local path = game.ReplicatedFirst.Chickynoid
local EffectsModule = require(path.Client.Effects)
local Enums = require(path.Shared.Enums)

local FastSignal = require(path.Shared.Vendor.FastSignal)
local DeltaTable = require(path.Shared.Vendor.DeltaTable)
local ClientMods = require(path.Client.ClientMods)

module.rockets = {}
module.weapons = {}
module.customWeapons = {}
module.currentWeapon = nil
module.OnBulletImpact = FastSignal.new()
module.OnBulletFire = FastSignal.new()

function module:HandleEvent(client, event)
if event.t == Enums.EventType.BulletImpact then

--partially decode this packet so we can route it..
local bitBuffer = event.b

--these two first!
local offset = 0
event.weaponId = buffer.readi16(bitBuffer,offset)
offset+=2
event.slot = buffer.readu8(bitBuffer, offset)
offset+=1

event.weaponModule = self:GetWeaponModuleByWeaponId(event.weaponId)
if (event.weaponModule == nil) then
return
end
if (event.weaponModule.UnpackPacket) then
event = event.weaponModule:UnpackPacket(event)
end

--Append player
local player = client:GetPlayerDataBySlotId(event.slot)
if player == nil then
return
end
event.player = player
self.OnBulletImpact:Fire(client, event)

if event.weaponModule and event.weaponModule.ClientOnBulletImpact then
event.weaponModule:ClientOnBulletImpact(client, event)
end

return
end

if event.t == Enums.EventType.BulletFire then

--partially decode this packet so we can route it..
local bitBuffer = event.b

--these two first!
local offset = 0
event.weaponId = buffer.readi16(bitBuffer,offset)
offset+=2
event.slot = buffer.readu8(bitBuffer, offset)
offset+=1

event.weaponModule = self:GetWeaponModuleByWeaponId(event.weaponId)
if (event.weaponModule == nil) then
return
end
if (event.weaponModule.UnpackPacket) then
event = event.weaponModule:UnpackPacket(event)
end

--Append player
local player = client:GetPlayerDataBySlotId(event.slot)
if player == nil then
return
end
event.player = player
self.OnBulletFire:Fire(client, event)

if event.weaponModule and event.weaponModule.ClientOnBulletFire then
event.weaponModule:ClientOnBulletFire(client, event)
end

return
end

if event.t == Enums.EventType.WeaponDataChanged then
if event.s == Enums.WeaponData.WeaponAdd then
print("Added weapon:", event.name)

local existingWeaponRecord = self.weapons[event.serial]
if existingWeaponRecord then
error("Weapon already added: " .. event.name .. " " .. event.serial)
return
end

local sourceModule = ClientMods:GetMod("weapons",event.name)
local weaponRecord = sourceModule.new()
weaponRecord.serial = event.serial
weaponRecord.name = event.name
weaponRecord.client = client
weaponRecord.weaponModule = module
weaponRecord.clientState = DeltaTable:DeepCopy(event.serverState)
weaponRecord.serverState = DeltaTable:DeepCopy(event.serverState)
weaponRecord.preservePredictedStateTimer = 0
weaponRecord.serverStateDirty = false
weaponRecord.totalTime = 0

-- selene: allow(shadowing)
function weaponRecord:SetPredictedState()
--Call this to delay the server from stomping on our state: eg: when firing rapidly
--when you let off the trigger this will allow the server state to take priority
weaponRecord.preservePredictedStateTimer = tick() + 0.5 --500ms
end

weaponRecord:ClientSetup()

--Add to inventory
self.weapons[weaponRecord.serial] = weaponRecord
end

--Remove
if event.s == Enums.WeaponData.WeaponRemove then
if event.serial ~= nil then
local weaponRecord = self.weapons[event.serial]
if weaponRecord == nil then
warn("Requested remove weapon not found")
return
end
print("Removed ", weaponRecord.name)

weaponRecord:ClientRemoved()

self.weapons[weaponRecord.serial] = nil
end
end

if event.s == Enums.WeaponData.WeaponState then
local weaponRecord = self.weapons[event.serial]
if weaponRecord == nil then
warn("Got state for a weapon we dont have.")
return
end
weaponRecord.serverStateDirty = true
--Apply the delta compressed packet
weaponRecord.serverState = DeltaTable:ApplyDeltaTable(weaponRecord.serverState, event.deltaTable)
end

--Dequip
if event.s == Enums.WeaponData.Dequip then
if self.currentWeapon ~= nil then
self.currentWeapon:ClientDequip()
self.currentWeapon = nil
end
end

--Equip
if event.s == Enums.WeaponData.Equip then
if event.serial ~= nil then
local weaponRecord = self.weapons[event.serial]
if weaponRecord == nil then
warn("Requested Equip weapon not found")
return
end
print("Equipped ", weaponRecord.name)
weaponRecord:ClientEquip();
self.currentWeapon = weaponRecord
end
end

return
end
end

function module:ProcessCommand(command)
--Don't get tricked, this can be invoked multiple times in a single frame if the framerate is low
if self.currentWeapon ~= nil then
self.currentWeapon.totalTime += command.deltaTime
self.currentWeapon:ClientProcessCommand(command)
end
end

function module:Think(_predictedServerTime, deltaTime)
--Copy the new server states over?
for _, weapon in pairs(self.weapons) do
if weapon.serverStateDirty == true then
if tick() > weapon.preservePredictedStateTimer then
weapon.serverStateDirty = false

weapon.clientState = DeltaTable:DeepCopy(weapon.serverState)
if self.NewServerState then
self:NewServerState()
end
end
end
end

if self.currentWeapon ~= nil then
self.currentWeapon:ClientThink(deltaTime)
end

end

function module:GetWeaponModuleByWeaponId(weaponId)
return self.customWeapons[weaponId]
end

function module:Setup(_client)

local mods = ClientMods:GetMods("weapons")
for name,module in pairs(mods) do

local customWeapon = module.new()
table.insert(self.customWeapons, customWeapon)
--set the id
customWeapon.weaponId = #self.customWeapons

end
end


return module
replicatedfirst/Chickynoid/Client/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/Chickynoid/Examples/Balls/Utils/MoveTypeDefault.lua
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local IsClient = RunService:IsClient()

local module = {}

local localPlayer = Players.LocalPlayer

local path = game.ReplicatedFirst.Chickynoid
local MathUtils = require(path.Shared.Simulation.MathUtils)
local Enums = require(path.Shared.Enums)
local Quaternion = require(path.Shared.Simulation.Quaternion)

local GameInfo = require(game.ReplicatedFirst.GameInfo)

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include


--Call this on both the client and server!
function module:ModifySimulation(simulation)
simulation:RegisterMoveState("Ball", self.ActiveThink, self.AlwaysThink, nil, nil)
simulation:SetMoveState("Ball")
end

function module.AlwaysThink(simulation, cmd)

end

--Imagine this is inside Simulation...
function module.ActiveThink(simulation, cmd, server, doCollisionEffects)
if simulation.state.pos.Magnitude < 1 then
return
end


local ownerId: number | Model = simulation.state.ownerId
local netId: number | Model = simulation.state.netId

if not simulation.ballData.isResimulating then
if IsClient then
local ballModel = localPlayer.BallModel.Value

if type(ownerId) == "number" then
local owner = Players:GetPlayerByUserId(ownerId)
ballModel.BallOwner.Value = owner
if owner then
owner.Ball.Value = ballModel
simulation.state.pos = ballModel.CFrame.Position
end
elseif ownerId ~= nil then
local humanoidRootPart = ownerId:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
ballModel.BallOwner.Value = ownerId
local playerCF = humanoidRootPart.CFrame
simulation.state.pos = (playerCF * CFrame.new(0, -1.65, -2)).Position
end
end
local ballOwner = ballModel.BallOwner.Value
ballModel.Transparency = if ballOwner ~= nil then 1 else 0
else
if type(ownerId) == "number" then
local playerRecord = server:GetPlayerByUserId(ownerId)
if playerRecord then
simulation.state.vel = Vector3.zero
simulation.state.angVel = Vector3.zero

local playerSimulation = playerRecord.chickynoid.simulation
local playerCF = CFrame.new(playerSimulation.state.pos) * CFrame.Angles(0, playerSimulation.state.angle, 0)
simulation.state.pos = (playerCF * CFrame.new(0, -1.65, -2)).Position
else
simulation.state.ownerId = 0
end
elseif ownerId ~= nil then
simulation.state.vel = Vector3.zero
simulation.state.angVel = Vector3.zero

local humanoidRootPart = ownerId:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
local playerCF = humanoidRootPart.CFrame
simulation.state.pos = (playerCF * CFrame.new(0, -1.65, -2)).Position
else
simulation.state.ownerId = 0
end
end
if type(netId) == "number" and server:GetPlayerByUserId(netId) == nil then
simulation.state.netId = 0
end
end
end

if ownerId ~= 0 then
return
end


local deltaTime = cmd.deltaTime or 1/60

local quaternion = simulation.rotation
local newPos, newVel, newAngularVel, newQuaternion, hitPlayer, hitNet = simulation:ProjectVelocity(simulation.state.pos, simulation.state.vel, simulation.state.angVel, quaternion, deltaTime, doCollisionEffects)
local moveDelta = (newPos - simulation.state.pos).Magnitude

simulation.state.pos = newPos
simulation.state.vel = newVel
simulation.state.angVel = newAngularVel
simulation.rotation = newQuaternion

if not hitPlayer and not simulation.ballData.isResimulating then
if IsClient then
local radius = 1

local character = localPlayer.Character
local humanoidRootPart = character and character.HumanoidRootPart
if humanoidRootPart and (humanoidRootPart.CFrame.Position - newPos).Magnitude < 10 then
local filter = {character}
local diveHitBox: BasePart?

local Lib = require(ReplicatedStorage.Lib)
if localPlayer:GetAttribute("Position") == "Goalkeeper" and Lib.isOnCooldown(localPlayer, "ClientDiveEnd") then
local diveHitboxTemplate = ReplicatedStorage.Assets.Hitboxes.Dive:FindFirstChild(localPlayer:GetAttribute("ClientDiveHitbox"))
if diveHitboxTemplate then
diveHitBox = diveHitboxTemplate:Clone()
diveHitBox:PivotTo(humanoidRootPart.CFrame)
diveHitBox.Parent = workspace
table.insert(filter, diveHitBox)
end
end

overlapParams.FilterDescendantsInstances = filter

local foundCharacter = workspace:GetPartBoundsInRadius(newPos, radius, overlapParams)
if diveHitBox then
diveHitBox:Destroy()
end
if foundCharacter[1] then
hitPlayer = true
end
end
else
local Lib = require(ReplicatedStorage.Lib)

local filter = {}
local characterHitBoxFilter = CollectionService:GetTagged("ServerCharacterHitbox")
for _, character: Model in pairs(characterHitBoxFilter) do
local userId = character:GetAttribute("player")
if userId == simulation.state.netId then continue end
local player = Players:GetPlayerByUserId(userId)
if player == nil then continue end
if Lib.isOnCooldown(player, "BallClaimCooldown")
or not Lib.playerInGame(player) or Lib.playerIsStunned(player) then
continue
end
table.insert(filter, character)
end
table.insert(filter, CollectionService:GetTagged("Goalkeeper"))
overlapParams.FilterDescendantsInstances = filter

local characters = workspace:GetPartBoundsInRadius(newPos, 1, overlapParams)
for _, character in pairs(characters) do
local userId = character:GetAttribute("player")
if userId == nil then
character = character.Parent
if character:HasTag("Goalkeeper") then
hitPlayer = character
break
end
continue
end
if userId == simulation.state.netId then continue end
local player = Players:GetPlayerByUserId(userId)
if player:GetAttribute("Position") == "Goalkeeper" then -- Goalkeeper has priority over others
hitPlayer = character
break
elseif hitPlayer == nil and moveDelta > 0.01 then -- if barely moving, don't do server claim detection
hitPlayer = character
end
end
end
end
return hitPlayer, hitNet, moveDelta
end

return module
replicatedfirst/Chickynoid/Examples/Balls/DefaultBallController.lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

local GameInfo = require(ReplicatedFirst:WaitForChild("GameInfo"))

local BallControllerStyle = {}
BallControllerStyle.__index = BallControllerStyle

--Gets called on both client and server
function BallControllerStyle:Setup(simulation)
local MoveTypeDefault = require(script.Parent.Utils.MoveTypeDefault)
MoveTypeDefault:ModifySimulation(simulation)
end

return BallControllerStyle
replicatedfirst/Chickynoid/Examples/Characters/Utils/MoveTypeDive.lua
--!native
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local IsClient = RunService:IsClient()

local module = {}

local path = game.ReplicatedFirst.Chickynoid
local MathUtils = require(path.Shared.Simulation.MathUtils)
local Enums = require(path.Shared.Enums)

local GameInfo = require(game.ReplicatedFirst.GameInfo)


local boundaryFolder = workspace.MapItems.GoalkeeperBoundaries
local homeBoundary = boundaryFolder:WaitForChild("Home")
local awayBoundary = boundaryFolder:WaitForChild("Away")
local boundaries = {
Home = {
Position = homeBoundary.Position,
Size = homeBoundary.Size,
},
Away = {
Position = awayBoundary.Position,
Size = awayBoundary.Size,
},
}


--Call this on both the client and server!
function module:ModifySimulation(simulation)
simulation:RegisterMoveState("Dive", self.ActiveThink, self.AlwaysThink, nil)
end

--Imagine this is inside Simulation...
function module.AlwaysThink(simulation, cmd)
if simulation.state.knockback > 0 then
return
end

if simulation.state.stam - GameInfo.DIVE_STAMINA_CONSUMPTION < 0 then
return
end

local player = simulation.player
if player == nil then
return
end

if simulation.completeFreeze then
return
end

local diveDir = cmd.diveDir
if (simulation.state.tackleCooldown == 0 and diveDir and diveDir.Magnitude > 0) then
local velocity = cmd.diveDir

local diveAnims = {
[0] = "LeftDive", [1] = "FrontDive", [2] = "RightDive",
}

local diveAnim: string = diveAnims[cmd.diveAnim]
if diveAnim == nil then
warn("[MoveTypeDive] Dive animation doesn't exist for:", cmd.diveAnim)
return
end

local movingLeft, movingForward, movingRight = diveAnim == "LeftDive", diveAnim == "FrontDive", diveAnim == "RightDive"
if movingForward then
simulation.state.tackleDir = velocity
velocity *= 1.2
elseif movingRight then
simulation.state.tackleDir = -velocity:Cross(Vector3.yAxis)
elseif movingLeft then
simulation.state.tackleDir = velocity:Cross(Vector3.yAxis)
end

simulation.state.stam -= GameInfo.DIVE_STAMINA_CONSUMPTION
simulation.state.stamRegCD = 0.5
simulation.state.vel += velocity * 70

simulation.state.tackle = GameInfo.DIVE_VELOCITY_DURATION
simulation.state.tackleCooldown = GameInfo.DIVE_DURATION + GameInfo.DIVE_COOLDOWN
simulation:SetMoveState("Dive")
simulation.characterData:PlayAnimation(diveAnim, Enums.AnimChannel.Channel1, true)

if not simulation.characterData.isResimulating then
if IsClient then
player:SetAttribute("CMDDiveDir", nil)
player:SetAttribute("ClientDiveHitbox", diveAnim)

local Lib = require(ReplicatedStorage.Lib)
Lib.setCooldown(player, "ClientDiveEnd", GameInfo.DIVE_DURATION)
else
local services = ServerScriptService.ServerScripts.Services
local CharacterService = require(services.CharacterService)

CharacterService:DiveStart(player, diveAnim)
end
end
end
end

--Imagine this is inside Simulation...
function module.ActiveThink(simulation, cmd)
local player = simulation.player
local walkReset = simulation.emoteWalkReset
if not IsClient and walkReset and os.clock() - walkReset >= 0 then
local function setNewEmote(newEmote)
local function generateShortGUID()
local guid = HttpService:GenerateGUID(false)
guid = guid:gsub("-", "")
return string.lower(guid)
end
player:SetAttribute("EmoteData", HttpService:JSONEncode({newEmote, generateShortGUID()}))
end
setNewEmote(nil)
elseif IsClient and not simulation.characterData.isResimulating then
player:SetAttribute("EndEmote", true)
player:SetAttribute("EndEmote", nil)
end
if IsClient and not simulation.characterData.isResimulating and simulation.runningSound then
simulation.runningSound.Playing = false
end

if simulation.completeFreeze then
return
end

--Check ground
local onGround = nil
onGround = simulation:DoGroundCheck(simulation.state.pos)

--If the player is on too steep a slope, its not ground
if (onGround ~= nil and onGround.normal.Y < simulation.constants.maxGroundSlope) then

--See if we can move downwards?
if (simulation.state.vel.Y < 0.1) then
onGround.normal = Vector3.new(0,1,0)
else
onGround = nil
end
end


--Mark if we were onground at the start of the frame
local startedOnGround = onGround

--Simplify - whatever we are at the start of the frame goes.
simulation.lastGround = onGround


--Did the player have a movement request?
local wishDir = nil
if cmd.x ~= 0 or cmd.z ~= 0 then
wishDir = Vector3.new(cmd.x, 0, cmd.z).Unit
simulation.state.pushDir = Vector2.new(cmd.x, cmd.z)
else
simulation.state.pushDir = Vector2.new(0, 0)
end
if simulation.state.sprint == 1 and wishDir ~= nil then
simulation.state.stam -= GameInfo.SPRINT_STAMINA_CONSUMPTION * cmd.deltaTime
simulation.state.stamRegCD = 0.5
end

--Create flat velocity to operate our input command on
--In theory this should be relative to the ground plane instead...
local flatVel = MathUtils:FlatVec(simulation.state.vel)

--Does the player have an input?
flatVel = MathUtils:VelocityFriction(flatVel, 0.24, cmd.deltaTime)

--Turn out flatvel back into our vel
simulation.state.vel = Vector3.new(flatVel.x, simulation.state.vel.y, flatVel.z)

--Do jumping?
if simulation.state.jump > 0 then
simulation.state.jump -= cmd.deltaTime
if simulation.state.jump < 0 then
simulation.state.jump = 0
end
end


--In air?
if onGround == nil then
simulation.state.inAir += cmd.deltaTime
if simulation.state.inAir > 10 then
simulation.state.inAir = 10 --Capped just to keep the state var reasonable
end

--Jump thrust
if cmd.y > 0 then
if simulation.state.jumpThrust > 0 then
simulation.state.vel += Vector3.new(0, simulation.state.jumpThrust * cmd.deltaTime, 0)
simulation.state.jumpThrust = MathUtils:Friction(
simulation.state.jumpThrust,
simulation.constants.jumpThrustDecay,
cmd.deltaTime
)
end
if simulation.state.jumpThrust < 0.001 then
simulation.state.jumpThrust = 0
end
else
simulation.state.jumpThrust = 0
end

--gravity
simulation.state.vel += Vector3.new(0, simulation.constants.gravity * cmd.deltaTime, 0)

--Switch to falling if we've been off the ground for a bit
if simulation.state.vel.y <= 0.01 and simulation.state.inAir > 0.5 then
-- simulation.characterData:PlayAnimation("Fall", Enums.AnimChannel.Channel0, false)
end
else
simulation.state.inAir = 0
end

--Sweep the player through the world, once flat along the ground, and once "step up'd"
local stepUpResult = nil
local walkNewPos, walkNewVel, hitSomething = simulation:ProjectVelocity(simulation.state.pos, simulation.state.vel, cmd.deltaTime)


-- Do we attempt a stepup? (not jumping!)
if onGround ~= nil and hitSomething == true and simulation.state.jump == 0 then
stepUpResult = simulation:DoStepUp(simulation.state.pos, simulation.state.vel, cmd.deltaTime)
end

--Choose which one to use, either the original move or the stepup
if stepUpResult ~= nil then
simulation.state.stepUp += stepUpResult.stepUp
simulation.state.pos = stepUpResult.pos
simulation.state.vel = stepUpResult.vel
else
simulation.state.pos = walkNewPos
simulation.state.vel = walkNewVel
end

--Do stepDown
if true then
if startedOnGround ~= nil and simulation.state.jump == 0 and simulation.state.vel.y <= 0 then
local stepDownResult = simulation:DoStepDown(simulation.state.pos)
if stepDownResult ~= nil then
simulation.state.stepUp += stepDownResult.stepDown
simulation.state.pos = stepDownResult.pos
end
end
end

--Do angles
simulation.state.targetAngle = MathUtils:PlayerVecToAngle(simulation.state.tackleDir)
simulation.state.angle = MathUtils:LerpAngle(
simulation.state.angle,
simulation.state.targetAngle,
simulation.constants.turnSpeedFrac * cmd.deltaTime
)

if simulation.isGoalkeeper and simulation.teleported and simulation:IsInMatch() then
local boundary = boundaries[player.Team.Name]
if boundary == nil then
return
end

simulation.state.pos = MathUtils:ClampToBoundary(simulation.state.pos, boundary.Position, boundary.Size)
end
end

return module
replicatedfirst/Chickynoid/Examples/Characters/Utils/MoveTypeRagdoll.lua
--!native
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()

local module = {}

local path = game.ReplicatedFirst.Chickynoid
local MathUtils = require(path.Shared.Simulation.MathUtils)
local Enums = require(path.Shared.Enums)
local Animations = require(path.Shared.Simulation.Animations)


--Call this on both the client and server!
function module:ModifySimulation(simulation)
simulation:RegisterMoveState("Ragdoll", self.ActiveThink, self.AlwaysThink, self.StartState, self.EndState)
simulation.state.knockback = 0
end

--Imagine this is inside Simulation...
function module.AlwaysThink(simulation, cmd)
if (simulation.state.knockback > 0) then
simulation.state.knockback = math.max(simulation.state.knockback - cmd.deltaTime, 0)
else
local animChannel = Enums.AnimChannel.Channel1
local slotString = "animNum"..animChannel
if simulation.characterData.serialized[slotString] == Animations:GetAnimationIndex("StunLand") then
simulation.characterData:PlayAnimation("Stop", Enums.AnimChannel.Channel1, true)
end
end

local player = simulation.player
if player == nil then
return
end

if simulation.isGoalkeeper then
simulation.state.knockback = 0
return
end

if cmd.knockback ~= nil and cmd.freeze ~= 1 then
if cmd.knockback.X == 0 and cmd.knockback.Z == 0 then
simulation.state.vel = (simulation.state.vel * Vector3.new(1, 0, 1)) + cmd.knockback
else
simulation.state.vel = cmd.knockback
end
simulation.state.knockback = math.max(simulation.state.knockback, cmd.knockbackDuration)
simulation:SetMoveState("Ragdoll")
if cmd.tackleRagdoll then
simulation.characterData:PlayAnimation("StunLand", Enums.AnimChannel.Channel1, true)
else
simulation.characterData:PlayAnimation("StunFlip", Enums.AnimChannel.Channel1, true)
end
if not IsClient then
player:SetAttribute("ServerChickyRagdoll", true)
end
end
end

function module.StartState(simulation)

end

function module.EndState(simulation)
local player = simulation.player
if not IsClient then
player:SetAttribute("ServerChickyRagdoll", nil)
end
end

--Imagine this is inside Simulation...
function module.ActiveThink(simulation, cmd)
local player: Player = simulation.player
local walkReset = simulation.emoteWalkReset
if not IsClient and walkReset and os.clock() - walkReset >= 0 then
local function setNewEmote(newEmote)
local function generateShortGUID()
local guid = HttpService:GenerateGUID(false)
guid = guid:gsub("-", "")
return string.lower(guid)
end
player:SetAttribute("EmoteData", HttpService:JSONEncode({newEmote, generateShortGUID()}))
end
setNewEmote(nil)
elseif IsClient and not simulation.characterData.isResimulating then
player:SetAttribute("EndEmote", true)
player:SetAttribute("EndEmote", nil)
end
if IsClient and not simulation.characterData.isResimulating and simulation.runningSound then
simulation.runningSound.Playing = false
end

if simulation.completeFreeze then
return
end

--Check ground
local onGround = nil
onGround = simulation:DoGroundCheck(simulation.state.pos)

--If the player is on too steep a slope, its not ground
if (onGround ~= nil and onGround.normal.Y < simulation.constants.maxGroundSlope) then

--See if we can move downwards?
if (simulation.state.vel.Y < 0.1) then
onGround.normal = Vector3.new(0,1,0)
else
onGround = nil
end
end


local startedOnGround = onGround

simulation.lastGround = onGround

--Create flat velocity to operate our input command on
--In theory this should be relative to the ground plane instead...
local flatVel = MathUtils:FlatVec(simulation.state.vel)
if onGround then
local friction = 0.1 + simulation.constants.slippery
flatVel = MathUtils:VelocityFriction(flatVel, friction, cmd.deltaTime)
end

--Does the player have an input?
-- flatVel = MathUtils:VelocityFriction(flatVel, GameInfo.TACKLE_FRICTION, cmd.deltaTime)

--Turn out flatvel back into our vel
simulation.state.vel = Vector3.new(flatVel.x, simulation.state.vel.y, flatVel.z)

--Do jumping?
if simulation.state.jump > 0 then
simulation.state.jump -= cmd.deltaTime
if simulation.state.jump < 0 then
simulation.state.jump = 0
end
end


--In air?
if onGround == nil then
simulation.state.inAir += cmd.deltaTime
if simulation.state.inAir > 10 then
simulation.state.inAir = 10 --Capped just to keep the state var reasonable
end

--Jump thrust
if cmd.y > 0 then
if simulation.state.jumpThrust > 0 then
simulation.state.vel += Vector3.new(0, simulation.state.jumpThrust * cmd.deltaTime, 0)
simulation.state.jumpThrust = MathUtils:Friction(
simulation.state.jumpThrust,
simulation.constants.jumpThrustDecay,
cmd.deltaTime
)
end
if simulation.state.jumpThrust < 0.001 then
simulation.state.jumpThrust = 0
end
else
simulation.state.jumpThrust = 0
end

--gravity
simulation.state.vel += Vector3.new(0, simulation.constants.gravity * cmd.deltaTime, 0)
else
simulation.state.inAir = 0
end

--Sweep the player through the world, once flat along the ground, and once "step up'd"
local stepUpResult = nil
local walkNewPos, walkNewVel, hitSomething = simulation:ProjectVelocity(simulation.state.pos, simulation.state.vel, cmd.deltaTime)

-- Do we attempt a stepup? (not jumping!)
if onGround ~= nil and hitSomething == true and simulation.state.jump == 0 then
stepUpResult = simulation:DoStepUp(simulation.state.pos, simulation.state.vel, cmd.deltaTime)
end

--Choose which one to use, either the original move or the stepup
if stepUpResult ~= nil then
simulation.state.stepUp += stepUpResult.stepUp
simulation.state.pos = stepUpResult.pos
simulation.state.vel = stepUpResult.vel
else
simulation.state.pos = walkNewPos
simulation.state.vel = walkNewVel
end

if simulation.playerInGameOrPausedOrEnded then
if simulation:DoGroundCheck(simulation.state.pos) and simulation.state.vel.Y < 0 then
simulation.characterData:PlayAnimation("StunLand", Enums.AnimChannel.Channel1, false)
else
simulation.characterData:PlayAnimation("StunFlip", Enums.AnimChannel.Channel1, false)
end
end

--Do stepDown
if true then
if startedOnGround ~= nil and simulation.state.jump == 0 and simulation.state.vel.y <= 0 then
local stepDownResult = simulation:DoStepDown(simulation.state.pos)
if stepDownResult ~= nil then
simulation.state.stepUp += stepDownResult.stepDown
simulation.state.pos = stepDownResult.pos
end
end
end
end

return module
replicatedfirst/Chickynoid/Examples/Characters/Utils/MoveTypeTackle.lua
--!native
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local IsClient = RunService:IsClient()

local module = {}

local path = game.ReplicatedFirst.Chickynoid
local MathUtils = require(path.Shared.Simulation.MathUtils)
local Enums = require(path.Shared.Enums)

local GameInfo = require(game.ReplicatedFirst.GameInfo)


--Call this on both the client and server!
function module:ModifySimulation(simulation)
simulation:RegisterMoveState("Tackle", self.ActiveThink, self.AlwaysThink, self.StartState, nil)
simulation.state.tackleCooldown = 0
simulation.state.tackleDir = Vector3.new(1, 0, 0)
simulation.state.tackle = 0
end

--Imagine this is inside Simulation...
function module.AlwaysThink(simulation, cmd)
if (simulation.state.tackleCooldown > 0) then
simulation.state.tackleCooldown = math.max(simulation.state.tackleCooldown - cmd.deltaTime, 0)
end
if (simulation.state.tackle > 0) then
simulation.state.tackle = math.max(simulation.state.tackle - cmd.deltaTime, 0)
end

local tackleDir = cmd.tackleDir
if (simulation.state.tackleCooldown == 0 and tackleDir and tackleDir.Magnitude > 0) then
local privateServerInfo: Configuration = ReplicatedStorage.PrivateServerInfo

simulation.state.tackleDir = tackleDir
simulation.state.vel += tackleDir * 80 * (simulation.constants.maxSpeed/16)

local tackleDuration = GameInfo.TACKLE_VELOCITY_DURATION
simulation.state.tackle = tackleDuration
simulation.state.tackleCooldown = privateServerInfo:GetAttribute("TackleCD") + tackleDuration
simulation:SetMoveState("Tackle")
simulation.characterData:PlayAnimation("SlideTackle", Enums.AnimChannel.Channel1, true)
end
end

function module.StartState(simulation, cmd)
if not simulation.characterData.isResimulating then
local player = simulation.player
if player == nil then
return
end

if IsClient then
player:SetAttribute("CMDTackleDir", nil)
else
local services = ServerScriptService.ServerScripts.Services
local CharacterService = require(services.CharacterService)

CharacterService:TackleStart(player)
end
end
end

--Imagine this is inside Simulation...
function module.ActiveThink(simulation, cmd)
local player = simulation.player
local walkReset = simulation.emoteWalkReset
if not IsClient and walkReset and os.clock() - walkReset >= 0 then
local function setNewEmote(newEmote)
local function generateShortGUID()
local guid = HttpService:GenerateGUID(false)
guid = guid:gsub("-", "")
return string.lower(guid)
end
player:SetAttribute("EmoteData", HttpService:JSONEncode({newEmote, generateShortGUID()}))
end
setNewEmote(nil)
elseif IsClient and not simulation.characterData.isResimulating then
player:SetAttribute("EndEmote", true)
player:SetAttribute("EndEmote", nil)
end
if IsClient and not simulation.characterData.isResimulating and simulation.runningSound then
simulation.runningSound.Playing = false
end

if simulation.completeFreeze then
return
end

--Check ground
local onGround = nil
onGround = simulation:DoGroundCheck(simulation.state.pos)

--If the player is on too steep a slope, its not ground
if (onGround ~= nil and onGround.normal.Y < simulation.constants.maxGroundSlope) then

--See if we can move downwards?
if (simulation.state.vel.Y < 0.1) then
onGround.normal = Vector3.new(0,1,0)
else
onGround = nil
end
end


--Mark if we were onground at the start of the frame
local startedOnGround = onGround

--Simplify - whatever we are at the start of the frame goes.
simulation.lastGround = onGround


--Did the player have a movement request?
local wishDir = nil
if cmd.x ~= 0 or cmd.z ~= 0 then
wishDir = Vector3.new(cmd.x, 0, cmd.z).Unit
simulation.state.pushDir = Vector2.new(cmd.x, cmd.z)
else
simulation.state.pushDir = Vector2.new(0, 0)
end
if simulation.state.sprint == 1 and wishDir ~= nil then
simulation.state.stam -= GameInfo.SPRINT_STAMINA_CONSUMPTION * cmd.deltaTime
simulation.state.stamRegCD = 0.5
end

--Create flat velocity to operate our input command on
--In theory this should be relative to the ground plane instead...
local flatVel = MathUtils:FlatVec(simulation.state.vel)

--Does the player have an input?
local friction = GameInfo.TACKLE_FRICTION
if simulation:IsInMatch() then
friction += simulation.constants.slippery * 0.1
end
flatVel = MathUtils:VelocityFriction(flatVel, friction, cmd.deltaTime)

--Turn out flatvel back into our vel
simulation.state.vel = Vector3.new(flatVel.x, simulation.state.vel.y, flatVel.z)

--Do jumping?
if simulation.state.jump > 0 then
simulation.state.jump -= cmd.deltaTime
if simulation.state.jump < 0 then
simulation.state.jump = 0
end
end


--In air?
if onGround == nil then
simulation.state.inAir += cmd.deltaTime
if simulation.state.inAir > 10 then
simulation.state.inAir = 10 --Capped just to keep the state var reasonable
end

--Jump thrust
if cmd.y > 0 then
if simulation.state.jumpThrust > 0 then
simulation.state.vel += Vector3.new(0, simulation.state.jumpThrust * cmd.deltaTime, 0)
simulation.state.jumpThrust = MathUtils:Friction(
simulation.state.jumpThrust,
simulation.constants.jumpThrustDecay,
cmd.deltaTime
)
end
if simulation.state.jumpThrust < 0.001 then
simulation.state.jumpThrust = 0
end
else
simulation.state.jumpThrust = 0
end

--gravity
simulation.state.vel += Vector3.new(0, simulation.constants.gravity * cmd.deltaTime, 0)

--Switch to falling if we've been off the ground for a bit
if simulation.state.vel.y <= 0.01 and simulation.state.inAir > 0.5 then
-- simulation.characterData:PlayAnimation("Fall", Enums.AnimChannel.Channel0, false)
end
else
simulation.state.inAir = 0
end

--Sweep the player through the world, once flat along the ground, and once "step up'd"
local stepUpResult = nil
local walkNewPos, walkNewVel, hitSomething = simulation:ProjectVelocity(simulation.state.pos, simulation.state.vel, cmd.deltaTime)


-- Do we attempt a stepup? (not jumping!)
if onGround ~= nil and hitSomething == true and simulation.state.jump == 0 then
stepUpResult = simulation:DoStepUp(simulation.state.pos, simulation.state.vel, cmd.deltaTime)
end

--Choose which one to use, either the original move or the stepup
if stepUpResult ~= nil then
simulation.state.stepUp += stepUpResult.stepUp
simulation.state.pos = stepUpResult.pos
simulation.state.vel = stepUpResult.vel
else
simulation.state.pos = walkNewPos
simulation.state.vel = walkNewVel
end

--Do stepDown
if true then
if startedOnGround ~= nil and simulation.state.jump == 0 and simulation.state.vel.y <= 0 then
local stepDownResult = simulation:DoStepDown(simulation.state.pos)
if stepDownResult ~= nil then
simulation.state.stepUp += stepDownResult.stepDown
simulation.state.pos = stepDownResult.pos
end
end
end

--Do angles
if cmd.shiftLock == 1 and cmd.fa and typeof(cmd.fa) == "Vector3" then
local vec = cmd.fa

simulation.state.targetAngle = MathUtils:PlayerVecToAngle(vec)
simulation.state.angle = MathUtils:LerpAngle(
simulation.state.angle,
simulation.state.targetAngle,
simulation.constants.turnSpeedFrac * cmd.deltaTime
)
else
simulation.state.targetAngle = MathUtils:PlayerVecToAngle(simulation.state.tackleDir)
simulation.state.angle = MathUtils:LerpAngle(
simulation.state.angle,
simulation.state.targetAngle,
simulation.constants.turnSpeedFrac * cmd.deltaTime
)
end
end

return module
replicatedfirst/Chickynoid/Examples/Characters/Utils/MoveTypeWalking.lua
--!native
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local IsClient = RunService:IsClient()

local module = {}

local localPlayer = Players.LocalPlayer

local path = game.ReplicatedFirst.Chickynoid
local MathUtils = require(path.Shared.Simulation.MathUtils)
local Enums = require(path.Shared.Enums)
local FootstepSounds = require(path.Shared.FootstepSounds)
local Animations = require(path.Shared.Simulation.Animations)

local GameInfo = require(game.ReplicatedFirst.GameInfo)


local boundaryFolder = workspace.MapItems.GoalkeeperBoundaries
local homeBoundary = boundaryFolder:WaitForChild("Home")
local awayBoundary = boundaryFolder:WaitForChild("Away")
local boundaries = {
Home = {
Position = homeBoundary.Position,
Size = homeBoundary.Size,
},
Away = {
Position = awayBoundary.Position,
Size = awayBoundary.Size,
},
}


--Call this on both the client and server!
function module:ModifySimulation(simulation)
simulation.state.skillCd = 0

simulation:RegisterMoveState("Walking", self.ActiveThink, self.AlwaysThink, nil, nil)
simulation:SetMoveState("Walking")
end

function module.AlwaysThink(simulation, cmd)
if (simulation.state.skillCd > 0) then
simulation.state.skillCd = math.max(simulation.state.skillCd - cmd.deltaTime, 0)
end

if (simulation.state.stamRegCD > 0) then
simulation.state.stamRegCD = math.max(simulation.state.stamRegCD - cmd.deltaTime, 0)
end
if simulation.state.stamRegCD == 0 and simulation.state.stam < simulation.constants.maxStamina then
simulation.state.stam = math.min(simulation.state.stam + GameInfo.STAMINA_REGEN * cmd.deltaTime, simulation.constants.maxStamina)
end
if simulation.state.stam <= 0 then
simulation.state.stam = 0
simulation.state.sprint = 0
end

local player = simulation.player
if player == nil then
return
end

if cmd.charge == 1 then
simulation.characterData:PlayAnimation("ChargeShot", Enums.AnimChannel.Channel2, false, 0.3)
else
local animChannel = Enums.AnimChannel.Channel2
local slotString = "animNum"..animChannel
local animNum = simulation.characterData.serialized[slotString]
if animNum == Animations:GetAnimationIndex("ChargeShot") then
simulation.characterData:PlayAnimation("Shoot", Enums.AnimChannel.Channel1, true, 0.01)
end
if animNum ~= Animations:GetAnimationIndex("Stop") then
simulation.characterData:PlayAnimation("Stop", Enums.AnimChannel.Channel2, true)
end
end

if simulation.movementDisabled then
simulation.state.vel *= Vector3.new(0, 1, 0)
end

local moveState = simulation:GetMoveState()
if moveState.name ~= "Walking" and not (simulation.state.tackle == 0 and simulation.state.knockback == 0 or simulation.movementDisabled) or simulation.completeFreeze then
local alpha = math.min(1, cmd.deltaTime*8)
simulation:LerpLeanAngle(Vector2.zero, alpha)
end

if simulation.completeFreeze then
if simulation.runningSound then
simulation.runningSound.Playing = false
end
simulation.state.sprint = 0
simulation.characterData:PlayAnimation("Idle", Enums.AnimChannel.Channel0, true, 0.2)
return
end
if cmd.skill == 1 and simulation.state.skillCd == 0 then
local privateServerInfo: Configuration = ReplicatedStorage.PrivateServerInfo
simulation.state.skillCd = privateServerInfo:GetAttribute("SkillCD") + GameInfo.SKILL_DURATION

if IsClient then
simulation.characterData:PlayAnimation("Skill", Enums.AnimChannel.Channel1, true)
else
local services = ServerScriptService.ServerScripts.Services
local CharacterService = require(services.CharacterService)
CharacterService:Skill(player)
end
end

if (moveState.name ~= "Walking") then
if simulation.state.tackle == 0 and simulation.state.knockback == 0 or simulation.movementDisabled then
simulation:SetMoveState("Walking")
end
end
if cmd.sprinting == 1 and simulation.state.stam > 0 then
simulation.state.sprint = 1
else
simulation.state.sprint = 0
end
end

--Imagine this is inside Simulation...
function module.ActiveThink(simulation, cmd)
local player = simulation.player
if simulation.completeFreeze then
return
end

--Check ground
local onGround = nil
onGround = simulation:DoGroundCheck(simulation.state.pos)

--If the player is on too steep a slope, its not ground
if (onGround ~= nil and onGround.normal.Y < simulation.constants.maxGroundSlope) then

--See if we can move downwards?
if (simulation.state.vel.Y < 0.1) then
onGround.normal = Vector3.new(0,1,0)
else
onGround = nil
end
end


--Mark if we were onground at the start of the frame
local startedOnGround = onGround

--Simplify - whatever we are at the start of the frame goes.
simulation.lastGround = onGround


--Did the player have a movement request?

local wishDir = nil
if (cmd.x ~= 0 or cmd.z ~= 0) then
wishDir = Vector3.new(cmd.x, 0, cmd.z).Unit
simulation.state.pushDir = Vector2.new(cmd.x, cmd.z)
else
simulation.state.pushDir = Vector2.new(0, 0)
end

if simulation.state.sprint == 1 and wishDir ~= nil then
if player and not simulation.isGoalkeeper then
simulation.state.stam -= GameInfo.SPRINT_STAMINA_CONSUMPTION * cmd.deltaTime
simulation.state.stamRegCD = 0.5
end
end

--Create flat velocity to operate our input command on
--In theory this should be relative to the ground plane instead...
local flatVel = MathUtils:FlatVec(simulation.state.vel)
if wishDir ~= nil and player then
local walkReset = simulation.emoteWalkReset
if not IsClient and walkReset and os.clock() - walkReset >= 0 then
local function setNewEmote(newEmote)
local function generateShortGUID()
local guid = HttpService:GenerateGUID(false)
guid = guid:gsub("-", "")
return string.lower(guid)
end
player:SetAttribute("EmoteData", HttpService:JSONEncode({newEmote, generateShortGUID()}))
end
setNewEmote(nil)
elseif IsClient and not simulation.characterData.isResimulating then
player:SetAttribute("EndEmote", true)
player:SetAttribute("EndEmote", nil)
end
end

--Do angles
if (cmd.shiftLock == 1) then

if (cmd.fa and typeof(cmd.fa) == "Vector3") then
local vec = cmd.fa

simulation.state.targetAngle = MathUtils:PlayerVecToAngle(vec)
simulation.state.angle = MathUtils:LerpAngle(
simulation.state.angle,
simulation.state.targetAngle,
simulation.constants.turnSpeedFrac * cmd.deltaTime
)
end
else
if wishDir ~= nil then
simulation.state.targetAngle = MathUtils:PlayerVecToAngle(wishDir)
simulation.state.angle = MathUtils:LerpAngle(
simulation.state.angle,
simulation.state.targetAngle,
simulation.constants.turnSpeedFrac * cmd.deltaTime
)
end
end


--Does the player have an input?
local brakeFriction = 0.02
local slipFriction = brakeFriction
local slipAccel = simulation.constants.accel
if simulation:IsInMatch() then
slipFriction += simulation.constants.slippery
slipAccel *= (1 - simulation.constants.slippery*0.99)
end

local walked = false
if wishDir ~= nil then
local multi = simulation.state.sprint == 1 and 1.6 or 1

-- local add = isUsingSkill and 5 or 0
local add = 0
if onGround then
--Moving along the ground under player input

flatVel = MathUtils:GroundAccelerate(
wishDir,
simulation.constants.maxSpeed * multi + add,
slipAccel * multi + add,
flatVel,
cmd.deltaTime
)

--Good time to trigger our walk anim
if simulation.state.pushing > 0 then
simulation.characterData:PlayAnimation("Push", Enums.AnimChannel.Channel0, false)
else
local moveAnim = simulation.state.sprint == 1 and "Sprint" or "Walk"
simulation.characterData:PlayAnimation(moveAnim, Enums.AnimChannel.Channel0, false)
end
walked = true
else
--Moving through the air under player control
flatVel = MathUtils:GroundAccelerate(wishDir, simulation.constants.maxSpeed * multi, slipAccel * multi, flatVel, cmd.deltaTime)
end
else
if onGround ~= nil then
--Just standing around
flatVel = MathUtils:VelocityFriction(flatVel, slipFriction, cmd.deltaTime)

--Enter idle
simulation.characterData:PlayAnimation("Idle", Enums.AnimChannel.Channel0, false)
-- else
--moving through the air with no input
else
flatVel = MathUtils:VelocityFriction(flatVel, slipFriction, cmd.deltaTime)
end
end

--Turn out flatvel back into our vel
simulation.state.vel = Vector3.new(flatVel.x, simulation.state.vel.y, flatVel.z)

--Do jumping?
if simulation.state.jump > 0 then
simulation.state.jump -= cmd.deltaTime
if simulation.state.jump < 0 then
simulation.state.jump = 0
end
end

local isGoalkeeper = simulation.isGoalkeeper

local playerInGame = simulation.playerInGame
if onGround ~= nil then
--jump!

if cmd.y > 0 and simulation.state.jump <= 0 and simulation.state.stam - GameInfo.JUMP_STAMINA_CONSUMPTION >= 0 then
simulation.state.vel = Vector3.new(simulation.state.vel.X, simulation.constants.jumpPunch, simulation.state.vel.Z)
simulation.state.jump = 0.2 --jumping has a cooldown (think jumping up a staircase)
simulation.state.jumpThrust = simulation.constants.jumpThrustPower
simulation.characterData:PlayAnimation("Jump", Enums.AnimChannel.Channel0, true, 0.2)

if playerInGame then
simulation.state.stam -= GameInfo.JUMP_STAMINA_CONSUMPTION
simulation.state.stamRegCD = 0.5
end
end
end

--In air?
if onGround == nil then
simulation.state.inAir += cmd.deltaTime
if simulation.state.inAir > 10 then
simulation.state.inAir = 10 --Capped just to keep the state var reasonable
end

--Jump thrust
if cmd.y > 0 then
if simulation.state.jumpThrust > 0 then
simulation.state.vel += Vector3.new(0, simulation.state.jumpThrust * cmd.deltaTime, 0)
simulation.state.jumpThrust = MathUtils:Friction(
simulation.state.jumpThrust,
simulation.constants.jumpThrustDecay,
cmd.deltaTime
)
end
if simulation.state.jumpThrust < 0.001 then
simulation.state.jumpThrust = 0
end
else
simulation.state.jumpThrust = 0
end

--gravity
simulation.state.vel += Vector3.new(0, simulation.constants.gravity * cmd.deltaTime, 0)

--Switch to falling if we've been off the ground for a bit
if simulation.state.vel.y <= 0.01 and simulation.state.inAir > 0.5 then
simulation.characterData:PlayAnimation("Fall", Enums.AnimChannel.Channel0, false)
end
else
simulation.state.inAir = 0
end

--Sweep the player through the world, once flat along the ground, and once "step up'd"
local stepUpResult = nil
local walkNewPos, walkNewVel, hitSomething = simulation:ProjectVelocity(simulation.state.pos, simulation.state.vel, cmd.deltaTime)

-- Ball rotation and character lean
if not simulation.characterData.isResimulating and simulation.playerInGameOrPausedOrEnded then
local moveDirection: Vector3 = walkNewVel * Vector3.new(1, 0, 1)
local vel = (moveDirection.Magnitude / 16)

moveDirection = moveDirection.Unit
local angle = simulation.state.angle
local characterDirection = -Vector3.new(math.sin(angle), 0, math.cos(angle))
local dot = moveDirection:Dot(characterDirection)

local rightAngle = math.acos(math.min(1, math.abs(dot)))
local cross = moveDirection:Cross(characterDirection)
local rotateRight = math.sin(rightAngle) * math.sign(cross.Y)

local rotateMulti = vel*0.125
local rotateCFrame = CFrame.Angles(rotateMulti * dot, 0, rotateMulti * rotateRight)

local walkAnimDir = dot
if walkAnimDir > -0.1 then
walkAnimDir = 0
else
walkAnimDir = 1
end

local alpha = math.min(1, cmd.deltaTime*8)

if IsClient then
if walked and moveDirection == moveDirection then
simulation:ChangeBallRotation(rotateCFrame)
simulation:SetAnimDir(walkAnimDir)
end

local realLeanAngle = Vector2.new(rotateMulti * dot, rotateMulti * rotateRight)
if realLeanAngle ~= realLeanAngle then
realLeanAngle = Vector2.zero
end
simulation:LerpLeanAngle(-realLeanAngle, alpha)
else
if walked and moveDirection == moveDirection then
simulation.characterData:ChangeBallRotation(rotateCFrame)
simulation.characterData:SetAnimDir(walkAnimDir)
end

local realLeanAngle = Vector2.new(rotateMulti * dot, rotateMulti * rotateRight)
if realLeanAngle == realLeanAngle then
simulation.characterData:LerpLeanAngle(-realLeanAngle, alpha)
end
end
elseif player and not simulation.characterData.isResimulating then
if IsClient and localPlayer == player then
simulation:SetLeanAngle(Vector2.zero)
elseif not IsClient then
simulation.characterData:SetAnimDir(0)
end
end

if IsClient and not simulation.characterData.isResimulating and simulation.playerInGameOrPausedOrEnded
and onGround == nil and simulation.state.vel.Y < -30 then
--Land after jump
local groundTopPos =42.777+1.299 /2 + 2.5
local groundCheck = walkNewPos.Y - groundTopPos < 0.1
if groundCheck then
-- player landed on floor
end
end
if IsClient and not simulation.characterData.isResimulating and simulation.runningSound then
if onGround then
if wishDir ~= nil and not simulation.movementDisabled then
local floorMaterial = "Plastic"
if simulation.playerInGameOrPausedOrEnded then
floorMaterial = simulation.groundType
end

local materialSoundData = FootstepSounds[floorMaterial]
simulation.runningSound.SoundId = materialSoundData.id
simulation.runningSound.Volume = materialSoundData.volume * 2
simulation.runningSound.PlaybackSpeed = (flatVel.Magnitude / 16) * materialSoundData.speed
simulation.runningSound.Playing = true
else
simulation.runningSound.Playing = false
end
else
simulation.runningSound.Playing = false
end
end


-- Do we attempt a stepup? (not jumping!)
if onGround ~= nil and hitSomething == true and simulation.state.jump == 0 then
stepUpResult = simulation:DoStepUp(simulation.state.pos, simulation.state.vel, cmd.deltaTime)
end

--Choose which one to use, either the original move or the stepup
if stepUpResult ~= nil then
simulation.state.stepUp += stepUpResult.stepUp
simulation.state.pos = stepUpResult.pos
simulation.state.vel = stepUpResult.vel
else
simulation.state.pos = walkNewPos
simulation.state.vel = walkNewVel
end

--Do stepDown
if true then
if startedOnGround ~= nil and simulation.state.jump == 0 and simulation.state.vel.y <= 0 then
local stepDownResult = simulation:DoStepDown(simulation.state.pos)
if stepDownResult ~= nil then
simulation.state.stepUp += stepDownResult.stepDown
simulation.state.pos = stepDownResult.pos
end
end
end

if isGoalkeeper and simulation.teleported and simulation:IsInMatch() then
local boundary = boundaries[player.Team.Name]
if boundary == nil then
return
end

simulation.state.pos = MathUtils:ClampToBoundary(simulation.state.pos, boundary.Position, boundary.Size)
end
end

return module
replicatedfirst/Chickynoid/Examples/Characters/Utils/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/Chickynoid/Examples/Characters/FieldChickynoid.lua
local Players = game:GetService("Players")
local path = game.ReplicatedFirst.Chickynoid

local ChickynoidStyle = {}
ChickynoidStyle.__index = ChickynoidStyle
setmetatable(ChickynoidStyle, require(script.Parent.HumanoidChickynoid))

function ChickynoidStyle:GetCharacterModel(userId: string, avatarDescription: {}?, humanoidDescription: HumanoidDescription?)
local srcModel = path.Assets:FindFirstChild("FieldRig"):Clone()
srcModel.Parent = game.Lighting --needs to happen so loadAppearance works

local result, err = pcall(function()
srcModel:SetAttribute("userid", userId)

local player = Players:GetPlayerByUserId(userId)
if player then
srcModel.Name = player.Name
end

self:DoStuffToModel(userId, srcModel, avatarDescription, humanoidDescription)
end)
if (result == false) then
warn("Loading " .. userId .. ":" ..err)
end

return srcModel
end

function ChickynoidStyle:DoStuffToModel(userId: string, srcModel: Model, avatarDescription: {}?, humanoidDescription: HumanoidDescription?)
local player = Players:GetPlayerByUserId(userId)

if (string.sub(userId, 1, 1) == "-") then
userId = string.sub(userId, 2, string.len(userId)) --drop the -
end

local torso = srcModel.Torso
local kitInfo: SurfaceGui = torso:FindFirstChild("KitInfo")
if kitInfo == nil then
kitInfo = path.Assets.KitInfo:Clone()
kitInfo.Parent = torso
end
kitInfo.DisplayName.Text = avatarDescription[3]
kitInfo.PlayerNumber.Text = avatarDescription[4]
kitInfo.Enabled = true

srcModel.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

humanoidDescription = humanoidDescription or game.Players:GetHumanoidDescriptionFromUserId(userId)
humanoidDescription.Shirt = 0
humanoidDescription.Pants = 0
humanoidDescription.GraphicTShirt = 0

humanoidDescription.Head = 0
humanoidDescription.LeftArm = 0
humanoidDescription.LeftLeg = 0
humanoidDescription.RightArm = 0
humanoidDescription.RightLeg = 0
humanoidDescription.Torso = 0

humanoidDescription.FrontAccessory = ""
humanoidDescription.BackAccessory = ""
humanoidDescription.NeckAccessory = ""
humanoidDescription.ShouldersAccessory = ""
humanoidDescription.WaistAccessory = ""
local accessoryList = humanoidDescription:GetAccessories(true)
for _, accessoryInfo in ipairs(table.clone(accessoryList)) do
local accessoryWhitelist = {Enum.AccessoryType.Hat, Enum.AccessoryType.Hair, Enum.AccessoryType.Face, Enum.AccessoryType.Eyebrow, Enum.AccessoryType.Eyelash}
if not table.find(accessoryWhitelist, accessoryInfo.AccessoryType) then
table.remove(accessoryList, table.find(accessoryList, accessoryInfo))
end
end
humanoidDescription:SetAccessories(accessoryList, true)

srcModel.Humanoid:ApplyDescriptionReset(humanoidDescription)

local shirt = srcModel:FindFirstChildOfClass("Shirt")
local pants = srcModel:FindFirstChildOfClass("Pants")
if not shirt then
shirt = Instance.new("Shirt")
shirt.Parent = srcModel
end
if not pants then
pants = Instance.new("Pants")
pants.Parent = srcModel
end

shirt.ShirtTemplate = avatarDescription[1]
pants.PantsTemplate = avatarDescription[2]
end

return ChickynoidStyle
replicatedfirst/Chickynoid/Examples/Characters/GoalkeeperChickynoid.lua
local Players = game:GetService("Players")
local path = game.ReplicatedFirst.Chickynoid

local ChickynoidStyle = {}
ChickynoidStyle.__index = ChickynoidStyle
setmetatable(ChickynoidStyle, require(script.Parent.FieldChickynoid))

function ChickynoidStyle:GetCharacterModel(userId: string, avatarDescription: {}?)
local srcModel = path.Assets:FindFirstChild("GoalkeeperRig"):Clone()
srcModel.Parent = game.Lighting --needs to happen so loadAppearance works

local result, err = pcall(function()
srcModel:SetAttribute("userid", userId)

local player = Players:GetPlayerByUserId(userId)
if player then
srcModel.Name = player.Name
end

self:DoStuffToModel(userId, srcModel, avatarDescription)
end)
if (result == false) then
warn("Loading " .. userId .. ":" ..err)
end

return srcModel
end

return ChickynoidStyle
replicatedfirst/Chickynoid/Examples/Characters/HumanoidChickynoid.lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local GameInfo = require(ReplicatedFirst:WaitForChild("GameInfo"))

local ChickynoidStyle = {}
ChickynoidStyle.__index = ChickynoidStyle

--Gets called on both client and server
function ChickynoidStyle:Setup(simulation)
simulation.state.stam = GameInfo.MAX_STAMINA
simulation.state.stamRegCD = 0
simulation.state.dive = 0
simulation.state.tackle = 0
simulation.state.sprint = 0


local MoveTypeWalking = require(script.Parent.Utils.MoveTypeWalking)
MoveTypeWalking:ModifySimulation(simulation)

local MoveTypeTackle = require(script.Parent.Utils.MoveTypeTackle)
MoveTypeTackle:ModifySimulation(simulation)

local MoveTypeDive = require(script.Parent.Utils.MoveTypeDive)
MoveTypeDive:ModifySimulation(simulation)

local MoveTypeRagdoll = require(script.Parent.Utils.MoveTypeRagdoll)
MoveTypeRagdoll:ModifySimulation(simulation)
end

return ChickynoidStyle
replicatedfirst/Chickynoid/Examples/Characters/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/Chickynoid/Examples/ClientMods/GenerateCommand.lua
local module = {}
--Module for how to pass user input to the chickynoid system
--It's not really an example (you need a version of this to play!) But you'll need to clone/remove/edit this to do your own input functionality

module.client = nil
module.useInbuiltDebugCheats = false
module.shiftLock = 0
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera

--For access to control vectors
local ControlModule = nil --require(PlayerModule:WaitForChild("ControlModule"))

local function GetControlModule()
if ControlModule == nil then
local scripts = localPlayer:FindFirstChild("PlayerScripts")
if scripts == nil then
return nil
end

local playerModule = scripts:FindFirstChild("PlayerModule")
if playerModule == nil then
return nil
end

local controlModule = playerModule:FindFirstChild("ControlModule")
if controlModule == nil then
return nil
end

ControlModule = require(
localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule")
)
end

return ControlModule
end

local coreCall do
local MAX_RETRIES = 8

local StarterGui = game:GetService('StarterGui')
local RunService = game:GetService('RunService')

function coreCall(method, ...)
local result = {}
for retries = 1, MAX_RETRIES do
result = {pcall(StarterGui[method], StarterGui, ...)}
if result[1] then
break
end
RunService.Stepped:Wait()
end
return unpack(result)
end
end

function module:Setup(_client)
self.client = _client

UserInputService:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
self.shiftLock = 1

end
if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
self.shiftLock = 0

end

end)

local resetBindable = Instance.new("BindableEvent")
resetBindable.Event:connect(function()
self.resetRequested = true
end)

coreCall('SetCore', 'ResetButtonCallback', resetBindable)
end

function module:Step(_client, _deltaTime) end


function module:GenerateCommand(command, serverTime: number, dt: number, ClientModule)
local Lib = require(ReplicatedStorage.Lib)

command.x = 0
command.y = 0
command.z = 0

GetControlModule()

local chickynoid = ClientModule:GetClientChickynoid()
local simulation = chickynoid and chickynoid.simulation

local movementDisabled = localPlayer:GetAttribute("MovementDisabled") or localPlayer:GetAttribute("ServerChickyRagdoll") or localPlayer:GetAttribute("ServerChickyFrozen") or localPlayer:GetAttribute("StopInputs")
if localPlayer:GetAttribute("ClientLoaded") and not movementDisabled then
if ControlModule ~= nil then
local moveVector = ControlModule:GetMoveVector() :: Vector3
if moveVector.Magnitude > 0 then
moveVector = moveVector.Unit
command.x = moveVector.X
command.y = moveVector.Y
command.z = moveVector.Z
end
end
end

local jumpDisabled = localPlayer:GetAttribute("JumpDisabled")
if not UserInputService:GetFocusedTextBox() then

local jump = UserInputService:IsKeyDown(Enum.KeyCode.Space)
local crouch = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
command.y = 0
if (jump and not jumpDisabled) then
command.y = 1
else
if (crouch) then
command.y = -1
end
end

--Fire!
command.f = UserInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0


if (self.useInbuiltDebugCheats == true) then
--Fly?
if UserInputService:IsKeyDown(Enum.KeyCode.F8) then
command.flying = 1
end

--Cheat #1 - speed cheat!
if UserInputService:IsKeyDown(Enum.KeyCode.P) then
command.deltaTime *= 3
end

--Cheat #2 - suspend!
if UserInputService:IsKeyDown(Enum.KeyCode.L) then
local function test(f)
return f
end
for j = 1, 2000000 do
local a = j * 12
test(a)
end
end
end
end

local isJumping = self:GetIsJumping() == true
if isJumping and not jumpDisabled then
command.y = 1
elseif not isJumping then
localPlayer:SetAttribute("JumpDisabled", false)
end

local ball = localPlayer.Ball.Value

local hasBall = ball ~= nil
if hasBall or movementDisabled then
command.y = 0
end

if command.y == 1 and Lib.playerInGameOrPaused(localPlayer) and simulation and simulation.lastGround then
if localPlayer:GetAttribute("Position") ~= "Goalkeeper" then
localPlayer:SetAttribute("JumpDisabled", true)
end
end

--fire angles
command.fa = currentCamera.CFrame.LookVector

--Shiftlock
local serverInfo: Configuration = ReplicatedStorage.ServerInfo
local gameStatus = serverInfo:GetAttribute("GameStatus")
local gameEnded = gameStatus == "GameEnded"
if not gameEnded and localPlayer:GetAttribute("Sprinting") then
command.sprinting = 1
end

local shiftLockDisabled
local emoteData = localPlayer:GetAttribute("EmoteData")
if emoteData ~= nil then
emoteData = HttpService:JSONDecode(emoteData)
shiftLockDisabled = emoteData[3]
end
if not shiftLockDisabled then
if localPlayer:GetAttribute("ShiftLock") or currentCamera.Focus and (currentCamera.CFrame.Position - currentCamera.Focus.Position).Magnitude < 0.6 then
command.shiftLock = 1
end
end

command.tackleDir = Vector3.zero
command.diveDir = Vector3.zero
command.diveAnim = 0

local cmdTackleDir = localPlayer:GetAttribute("CMDTackleDir")
if not gameEnded and cmdTackleDir and not movementDisabled and not hasBall then
command.tackleDir = cmdTackleDir
end
local cmdDiveDir = localPlayer:GetAttribute("CMDDiveDir")
if not gameEnded and cmdDiveDir and not movementDisabled and not hasBall then
command.diveDir = cmdDiveDir
command.diveAnim = localPlayer:GetAttribute("CMDDiveAnim")
end

if localPlayer:GetAttribute("ChargingShot") then
command.charge = 1
end


command.skill = 0
if ClientModule.skillServerTime ~= nil then
command.skill = 1
end


--Translate the move vector relative to the camera
local rawMoveVector = self:CalculateRawMoveVector(Vector3.new(command.x, 0, command.z))
command.x = rawMoveVector.X
command.z = rawMoveVector.Z

--reset requested?
-- if self.resetRequested == true then
-- command.reset = true
-- self.resetRequested = false
-- end

return command
end

function module:CalculateRawMoveVector(cameraRelativeMoveVector: Vector3)
local Camera = workspace.CurrentCamera
local _, yaw = Camera.CFrame:ToEulerAnglesYXZ()
return CFrame.fromEulerAnglesYXZ(0, yaw, 0) * Vector3.new(cameraRelativeMoveVector.X, 0, cameraRelativeMoveVector.Z)
end

function module:GetIsJumping()
if ControlModule == nil then
return false
end
if ControlModule.activeController == nil then
return false
end

return ControlModule.activeController:GetIsJumping()
or (ControlModule.touchJumpController and ControlModule.touchJumpController:GetIsJumping())
end

local mouse = localPlayer:GetMouse()
function module:GetAimPoint()
local ray = game.Workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include

local whiteList = { game.Workspace.Terrain }
local collisionRoot = self.client:GetCollisionRoot()
if (collisionRoot) then
table.insert(whiteList, collisionRoot)
end
raycastParams.FilterDescendantsInstances = whiteList

local raycastResults = game.Workspace:Raycast(ray.Origin, ray.Direction * 2000, raycastParams)
if raycastResults then
return raycastResults.Position
end
--We hit the sky perhaps?
return ray.Origin + (ray.Direction * 2000)
end

return module
replicatedfirst/Chickynoid/Examples/ClientMods/NetgraphHotkeys.lua
local module = {}
module.heldKeys = {}
module.frameCounter = 0
local UserInputService = game:GetService("UserInputService")

function module:Setup(_client)
self.client = _client
-- _client.showFpsGraph = true
-- _client.showNetGraph = true
end

function module:Step(_client, _deltaTime)

self.frameCounter += 1

local keys = UserInputService:GetKeysPressed()

local keysThisFrame = {}
for _,key in pairs(keys) do
if (self.heldKeys[key.KeyCode] == nil) then
self.heldKeys[key.KeyCode] = 0
end
self.heldKeys[key.KeyCode] += 1

keysThisFrame[key.KeyCode] = 1
end
for key,counter in pairs(self.heldKeys) do
if (keysThisFrame[key] == nil) then
self.heldKeys[key] = nil
end
end

if (self.heldKeys[Enum.KeyCode.F7] == 1) then --first frame!
-- _client.showFpsGraph = not _client.showFpsGraph
-- _client.showNetGraph = _client.showFpsGraph
end
end


return module
replicatedfirst/Chickynoid/Examples/ClientMods/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/Chickynoid/Examples/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/Chickynoid/Shared/Simulation/Animations.lua
local module = {}

module.animations = {} --num, string
module.reverseLookups = {} --string, num

function module:RegisterAnimation(name : string)
if (self.reverseLookups[name] ~= nil) then
return self.reverseLookups[name]
end

table.insert(self.animations, name)
local index = #self.animations
self.reverseLookups[name] = index
end

function module:GetAnimationIndex(name : string) : number
return self.reverseLookups[name]
end

function module:GetAnimation(index : number) : string
return self.animations[index]
end

function module:SetAnimationsFromWorldState(animations : any)

self.animations = animations
self.reverseLookups = {}
for key,value in self.animations do
self.reverseLookups[value] = key
end
end

function module:ServerSetup()

--Register some default animations
self:RegisterAnimation("Stop")
self:RegisterAnimation("Idle")
self:RegisterAnimation("Walk")
self:RegisterAnimation("Push")
self:RegisterAnimation("Jump")
self:RegisterAnimation("Fall")

self:RegisterAnimation("Sprint")

self:RegisterAnimation("ChargeShot")
self:RegisterAnimation("RequestBall")
self:RegisterAnimation("Shoot")
self:RegisterAnimation("Skill")
self:RegisterAnimation("SlideTackle")

self:RegisterAnimation("FrontDive")
self:RegisterAnimation("RightDive")
self:RegisterAnimation("LeftDive")

self:RegisterAnimation("StunLand")
self:RegisterAnimation("StunIdle")
self:RegisterAnimation("StunFlip")
end

return module
replicatedfirst/Chickynoid/Shared/Simulation/BallCommandLayout.lua
local module = {}


local CrunchTable = require(script.Parent.Parent.Vendor.CrunchTable)

function module:GetCommandLayout()

if (self.commandLayout == nil) then
self.commandLayout = CrunchTable:CreateLayout()

self.commandLayout:Add("localFrame",CrunchTable.Enum.INT32)
-- self.commandLayout:Add("serverTime", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("deltaTime", CrunchTable.Enum.FLOAT)
end

return self.commandLayout
end

function module:EncodeCommand(command)
return CrunchTable:BinaryEncodeTable(command, self:GetCommandLayout())
end

function module:DecodeCommand(command)
return CrunchTable:BinaryDecodeTable(command, self:GetCommandLayout())
end

return module
replicatedfirst/Chickynoid/Shared/Simulation/BallData.lua
local RunService = game:GetService("RunService")
--!native
local BallData = {}
BallData.__index = BallData

local EPSILION = 0.00001
local mathUtils = require(script.Parent.MathUtils)
local Quaternion = require(script.Parent.Quaternion)



local function Lerp(a, b, frac)
return a:Lerp(b, frac)
end

local function AngleLerp(a, b, frac)
return mathUtils:LerpAngle(a, b, frac)
end

local function NumberLerp(a, b, frac)
return (a * (1 - frac)) + (b * frac)
end

local function Raw(_a, b, _frac)
return b
end

local MAX_FLOAT16 = math.pow(2, 16)
local function ValidateFloat16(float)
return math.clamp(float, -MAX_FLOAT16, MAX_FLOAT16)
end

local MAX_BYTE = 255
local function ValidateByte(byte)
return math.clamp(byte, 0, MAX_BYTE)
end

local function ValidateVector3(input)
return input
end

local function ValidateNumber(input)
return input
end

local function CompareVector3(a, b)
if math.abs(a.x - b.x) > EPSILION or math.abs(a.y - b.y) > EPSILION or math.abs(a.z - b.z) > EPSILION then
return false
end
return true
end

local function CompareByte(a, b)
return a == b
end

local function CompareFloat16(a, b)
return a == b
end

local function CompareNumber(a, b)
return a == b
end

local function WriteVector3(buf : buffer, offset : number, value : Vector3 ) : number
buffer.writef32(buf, offset, value.X)
offset+=4
buffer.writef32(buf, offset, value.Y)
offset+=4
buffer.writef32(buf, offset, value.Z)
offset+=4
return offset
end

local function ReadVector3(buf : buffer, offset : number)
local x = buffer.readf32(buf, offset)
offset+=4
local y = buffer.readf32(buf, offset)
offset+=4
local z = buffer.readf32(buf, offset)
offset+=4
return Vector3.new(x,y,z), offset
end

local function WriteFloat32(buf : buffer, offset : number, value : number ) : number
buffer.writef32(buf, offset, value)
offset+=4
return offset
end

local function ReadFloat32(buf : buffer, offset : number)
local x = buffer.readf32(buf, offset)
offset+=4
return x, offset
end

local function WriteByte(buf : buffer, offset : number, value : number ) : number
buffer.writeu8(buf, offset, value)
offset+=1
return offset
end

local function ReadByte(buf : buffer, offset : number)
local x = buffer.readu8(buf, offset)
offset+=1
return x, offset
end

local function WriteFloat16(buf : buffer, offset : number, value : number ) : number

local sign = value < 0
value = math.abs(value)

local mantissa, exponent = math.frexp(value)

if value == math.huge then
if sign then
buffer.writeu8(buf,offset,252)-- 11111100
offset+=1
else
buffer.writeu8(buf,offset,124) -- 01111100
offset+=1
end
buffer.writeu8(buf,offset,0) -- 00000000
offset+=1
return offset
elseif value ~= value or value == 0 then
buffer.writeu8(buf,offset,0)
offset+=1
buffer.writeu8(buf,offset,0)
offset+=1
return offset
elseif exponent + 15 <= 1 then -- Bias for halfs is 15
mantissa = math.floor(mantissa * 1024 + 0.5)
if sign then
buffer.writeu8(buf,offset,(128 + bit32.rshift(mantissa, 8))) -- Sign bit, 5 empty bits, 2 from mantissa
offset+=1
else
buffer.writeu8(buf,offset,(bit32.rshift(mantissa, 8)))
offset+=1
end
buffer.writeu8(buf,offset,bit32.band(mantissa, 255)) -- Get last 8 bits from mantissa
offset+=1
return offset
end

mantissa = math.floor((mantissa - 0.5) * 2048 + 0.5)

-- The bias for halfs is 15, 15-1 is 14
if sign then
buffer.writeu8(buf,offset,(128 + bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8)))
offset+=1
else
buffer.writeu8(buf,offset,(bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8)))
offset+=1
end
buffer.writeu8(buf,offset,bit32.band(mantissa, 255))
offset+=1

return offset
end

local function ReadFloat16(buf : buffer, offset : number)

local b0 = buffer.readu8(buf, offset)
offset+=1
local b1 = buffer.readu8(buf, offset)
offset+=1

local sign = bit32.btest(b0, 128)
local exponent = bit32.rshift(bit32.band(b0, 127), 2)
local mantissa = bit32.lshift(bit32.band(b0, 3), 8) + b1

if exponent == 31 then --2^5-1
if mantissa ~= 0 then
return (0 / 0), offset
else
return (sign and -math.huge or math.huge), offset
end
elseif exponent == 0 then
if mantissa == 0 then
return 0, offset
else
return (sign and -math.ldexp(mantissa / 1024, -14) or math.ldexp(mantissa / 1024, -14)), offset
end
end

mantissa = (mantissa / 1024) + 1

return (sign and -math.ldexp(mantissa, exponent - 15) or math.ldexp(mantissa, exponent - 15)), offset
end

function BallData:SetIsResimulating(bool)
self.isResimulating = bool
end

function BallData:ModuleSetup()
BallData.methods = {}
BallData.methods["Vector3"] = {
write = WriteVector3,
read = ReadVector3,
validate = ValidateVector3,
compare = CompareVector3,
}
BallData.methods["Float16"] = {
write = WriteFloat16,
read = ReadFloat16,
validate = ValidateFloat16,
compare = CompareFloat16,
}
BallData.methods["Float32"] = {
write = WriteFloat32,
read = ReadFloat32,
validate = ValidateNumber,
compare = CompareNumber,
}

BallData.methods["Byte"] = {
write = WriteByte,
read = ReadByte,
validate = ValidateByte,
compare = CompareByte,
}

BallData.packFunctions = {
pos = "Vector3",
}

BallData.keys =
{
"pos",
}


BallData.lerpFunctions = {
pos = Lerp,
}

end

function BallData.new()
local self = setmetatable({
serialized = {
pos = Vector3.zero,
},

--Be extremely careful about having any kind of persistant nonserialized data!
--If in doubt, stick it in the serialized!
isResimulating = false,
targetPosition = Vector3.zero,

}, BallData)

return self
end

--This smoothing is performed on the server only.
--On client, use GetPosition
function BallData:SmoothPosition(deltaTime, smoothScale)
if (smoothScale == 1 or smoothScale == 0) then
self.serialized.pos = self.targetPosition
else
self.serialized.pos = mathUtils:SmoothLerp(self.serialized.pos, self.targetPosition, smoothScale, deltaTime)
end
end

function BallData:ClearSmoothing()
self.serialized.pos = self.targetPosition
end

--Sets the target position
function BallData:SetTargetPosition(pos, teleport)
self.targetPosition = pos
-- if (teleport) then
self:ClearSmoothing()
-- end
end

function BallData:GetPosition()
return self.serialized.pos
end

function BallData:Serialize()
local ret = {}
--Todo: Add bitpacking
for key, _ in pairs(self.serialized) do
ret[key] = self.serialized[key]
end

return ret
end

function BallData:SerializeToBitBuffer(previousData, buf : buffer, offset: number)

if (previousData == nil) then
return self:SerializeToBitBufferFast(buf, offset)
end

local contentWritePos = offset
offset += 2 --2 bytes contents

local contentBits = 0
local bitIndex = 0

if previousData == nil then

--Slow path that wont be hit
contentBits = 0xFFFF

for keyIndex, key in BallData.keys do
local value = self.serialized[key]
local func = BallData.methods[BallData.packFunctions[key]]
offset = func.write(buf, offset, value)
end
else
--calculate bits
for keyIndex, key in BallData.keys do
local value = self.serialized[key]
local func = BallData.methods[BallData.packFunctions[key]]

local valueA = previousData.serialized[key]
local valueB = value

if func.compare(valueA, valueB) == false then
contentBits = bit32.bor(contentBits, bit32.lshift(1, bitIndex))
offset = func.write(buf, offset, value)
end
bitIndex += 1
end

end

buffer.writeu16(buf, contentWritePos, contentBits)
return offset
end


function BallData:SerializeToBitBufferFast(buf : buffer, offset: number)

local contentWritePos = offset
offset += 2 --2 bytes contents

local contentBits = 0xFFFF

local serialized = self.serialized

offset = WriteVector3(buf, offset, serialized.pos)

buffer.writeu16(buf, contentWritePos, contentBits)
return offset
end



function BallData:DeserializeFromBitBuffer(buf : buffer, offset: number)

local contentBits = buffer.readu16(buf, offset)
offset+=2

local bitIndex = 0
for keyIndex, key in BallData.keys do
local value = self.serialized[key]
local hasBit = bit32.band(contentBits, bit32.lshift(1, bitIndex)) > 0

if hasBit then
local func = BallData.methods[BallData.packFunctions[key]]
self.serialized[key],offset = func.read(buf, offset)
end
bitIndex += 1
end
return offset
end

function BallData:CopySerialized(otherSerialized)
for key, value in pairs(otherSerialized) do
self.serialized[key] = value
end
end

function BallData:Interpolate(dataA, dataB, fraction)
local dataRecord = {}
for key, _ in pairs(dataA) do
if key == "pos" and dataA.pos == Vector3.zero or dataB.pos == Vector3.zero then
dataRecord[key] = dataB.pos
continue
end

local func = BallData.lerpFunctions[key]
if func == nil then
dataRecord[key] = dataB[key]
else
dataRecord[key] = func(dataA[key], dataB[key], fraction)
end
end

return dataRecord
end

BallData:ModuleSetup()
return BallData
replicatedfirst/Chickynoid/Shared/Simulation/BallInfoLayout.lua
local module = {}


local CrunchTable = require(script.Parent.Parent.Vendor.CrunchTable)

function module:GetCommandLayout()

if (self.commandLayout == nil) then
self.commandLayout = CrunchTable:CreateLayout()

self.commandLayout:Add("tackledEnemy", CrunchTable.Enum.UBYTE)
self.commandLayout:Add("skill", CrunchTable.Enum.FLOAT)

self.commandLayout:Add("claimPos", CrunchTable.Enum.VECTOR3)

self.commandLayout:Add("sGuid", CrunchTable.Enum.INT32)
self.commandLayout:Add("sType", CrunchTable.Enum.UBYTE)
self.commandLayout:Add("sPower", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("sDirection", CrunchTable.Enum.VECTOR3)
self.commandLayout:Add("sCurveFactor", CrunchTable.Enum.FLOAT)

self.commandLayout:Add("dGuid", CrunchTable.Enum.INT32)
self.commandLayout:Add("dType", CrunchTable.Enum.UBYTE)
self.commandLayout:Add("dPower", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("dDirection", CrunchTable.Enum.VECTOR3)
self.commandLayout:Add("dCurveFactor", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("dServerDeflect", CrunchTable.Enum.FLOAT)

self.commandLayout:Add("enteredGoal", CrunchTable.Enum.UBYTE)
end

return self.commandLayout
end

function module:EncodeCommand(command)
return CrunchTable:BinaryEncodeTable(command, self:GetCommandLayout())
end

function module:DecodeCommand(command)
return CrunchTable:BinaryDecodeTable(command, self:GetCommandLayout())
end

return module
replicatedfirst/Chickynoid/Shared/Simulation/BallSimulation.lua
--!native
--[=[
@class BallSimulation
BallSimulation handles physics for characters on both the client and server.
]=]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local IsClient = RunService:IsClient()

local localPlayer = Players.LocalPlayer

local BallSimulation = {}
BallSimulation.__index = BallSimulation

local CollisionModule = require(script.Parent.CollisionModule)
local BallData = require(script.Parent.BallData)
local MathUtils = require(script.Parent.MathUtils)
local Enums = require(script.Parent.Parent.Enums)
local DeltaTable = require(script.Parent.Parent.Vendor.DeltaTable)
local Quaternion = require(script.Parent.Quaternion)


function BallSimulation.new(ballId)
local self = setmetatable({}, BallSimulation)

self.ballId = ballId

self.moveStates = {}
self.moveStateNames = {}
self.executionOrder = {}

self.state = {}

self.state.pos = Vector3.new(0, 0, 0)
self.state.vel = Vector3.new(0, 0, 0)
self.state.angVel = Vector3.new(0, 0, 0)
self.state.ownerId = 0
self.state.netId = 0
self.state.guid = 1
self.state.action = 0
self.state.framesToGoal = nil
self.state.refFrame = nil

self.state.moveState = 0

self.state.curve = 0

self.ballData = BallData.new()

self.constants = {}
self.constants.elasticity = 0.4
self.constants.gravity = -153.7 -- adjusted for ball

self.rotation = Quaternion.new(1, 0, 0, 1) -- don't keep it in state because resimulating can make it look weird

self.radius = 1

return self
end

function BallSimulation:GetMoveState()
local record = self.moveStates[self.state.moveState]
return record
end

function BallSimulation:RegisterMoveState(name, updateState, alwaysThink, startState, endState, alwaysThinkLate, executionOrder)
local index = 0
for key,value in pairs(self.moveStateNames) do
index+=1
end
self.moveStateNames[name] = index

local record = {}
record.name = name
record.updateState = updateState
record.alwaysThink = alwaysThink
record.startState = startState
record.endState = endState
record.alwaysThinkLate = alwaysThinkLate
record.executionOrder = executionOrder or 0
self.moveStates[index] = record

self.executionOrder = {}
for key,value in self.moveStates do
table.insert(self.executionOrder, value)
end

table.sort(self.executionOrder, function(a,b)
return a.executionOrder < b.executionOrder
end)
end

function BallSimulation:SetMoveState(name)

local index = self.moveStateNames[name]
if (index) then

local record = self.moveStates[index]
if (record) then

local prevRecord = self.moveStates[self.state.moveState]
if (prevRecord and prevRecord.endState) then
prevRecord.endState(self, name)
end
if (record.startState) then
if (prevRecord) then
record.startState(self, prevRecord.name)
else
record.startState(self, "")
end
end
self.state.moveState = index
end
end
end


-- It is very important that this method rely only on whats in the cmd object
-- and no other client or server state can "leak" into here
-- or the server and client state will get out of sync.
local privateServerInfo: Configuration = ReplicatedStorage:WaitForChild("PrivateServerInfo")
function BallSimulation:DoServerAttributeChecks()
self.constants.slippery = privateServerInfo:GetAttribute("Slippery")
self.constants.gravity = -153.7 / (196.2 / privateServerInfo:GetAttribute("Gravity"))
end

function BallSimulation:ProcessCommand(cmd: {}, server, doCollisionEffects: boolean, shouldDebug: boolean?)
if shouldDebug then
debug.profilebegin("Ball Always Think")
end
for key,record in self.executionOrder do

if (record.alwaysThink) then
record.alwaysThink(self, cmd)
end
end
if shouldDebug then
debug.profileend()
end

if shouldDebug then
debug.profilebegin("Ball Update State")
end
local hitPlayer, hitNet, moveDelta
local record = self.moveStates[self.state.moveState]
if (record and record.updateState) then
hitPlayer, hitNet, moveDelta = record.updateState(self, cmd, server, doCollisionEffects)
else
warn("No such updateState: ", self.state.moveState)
end
if shouldDebug then
debug.profileend()
end

if shouldDebug then
debug.profilebegin("Ball Always Think Late")
end
for key,record in self.executionOrder do
if (record.alwaysThinkLate) then
record.alwaysThinkLate(self, cmd)
end
end
if shouldDebug then
debug.profileend()
end

--Input/Movement is done, do the update of timers and write out values

--position the debug visualizer
if self.debugModel ~= nil then
self.debugModel:PivotTo(CFrame.new(self.state.pos))
end

--Write this to the characterData
self.ballData:SetTargetPosition(self.state.pos)

return hitPlayer, hitNet, moveDelta
end

function BallSimulation:SetAngle(angle, teleport)
-- self.state.angle = angle
-- if (teleport == true) then
-- self.state.targetAngle = angle
-- self.characterData:SetAngle(self.state.angle, true)
-- end
end

function BallSimulation:SetPosition(position, teleport)
self.state.position = position
self.ballData:SetTargetPosition(self.state.pos, teleport)
end

function BallSimulation:Destroy()
if self.debugModel then
self.debugModel:Destroy()
end
end


local function ballHitPart(raycastResult: RaycastResult)
if not game:IsLoaded() then
return
end

local Lib = require(ReplicatedStorage.Lib)

local Sound = require(ReplicatedStorage.Modules.Sound)

local assets = ReplicatedStorage.Assets

local hitPosition = raycastResult.Position

local part = raycastResult.Instance
-- do something with the part that was hit, sounds etc.
end

local magnusCoefficient = 0.5 -- Arbitrary coefficient to scale Magnus force
local airDensity = 1.225 -- Air density in kg/m^3 for the Magnus effect

local function calculateMagnusForce(velocity, angularVelocity)
local magnusForce = magnusCoefficient * airDensity * (1 ^ 3) * angularVelocity:Cross(velocity)
return magnusForce
end

local mapItems = workspace:WaitForChild("MapItems")

function BallSimulation:ProjectVelocity(startPos: Vector3, linearVelocity: Vector3, angularVelocity: Vector3, quaternion: typeof(Quaternion), deltaTime: number, doCollisionEffects: boolean)
local radius = 1
local floorHeight = 42.777+1.299/2+radius
startPos = Vector3.new(startPos.X, math.max(floorHeight, startPos.Y), startPos.Z)

local filter = {mapItems}

local Lib = require(ReplicatedStorage.Lib)
if not self.ballData.isResimulating then
if IsClient then
local character = localPlayer and localPlayer.Character
if character then
table.insert(filter, character)
end
else
local characterHitBoxFilter = CollectionService:GetTagged("ServerCharacterHitbox")
for _, character: Model in pairs(characterHitBoxFilter) do
local userId = character:GetAttribute("player")
if userId == self.state.netId then continue end
local player = Players:GetPlayerByUserId(userId)
if player == nil then continue end
if Lib.isOnCooldown(player, "BallClaimCooldown")
or not Lib.playerInGame(player) or Lib.playerIsStunned(player) then
continue
end
table.insert(filter, character)
end
table.insert(filter, CollectionService:GetTagged("Goalkeeper"))
end
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.CollisionGroup = "Ball"
raycastParams.RespectCanCollide = true
raycastParams.FilterDescendantsInstances = filter

local gravity = Vector3.new(0, self.constants.gravity, 0)
local elasticity = self.constants.elasticity

local acceleration = Vector3.zero
local oldVelocity = linearVelocity


local distanceToGround = startPos.Y - floorHeight
if distanceToGround < 0.1 and linearVelocity.Y <= 0 then
linearVelocity = MathUtils:VelocityFriction(linearVelocity, 0.6, deltaTime)
-- if linearVelocity.Magnitude < 4 then
-- linearVelocity = Vector3.zero
-- oldVelocity = linearVelocity
-- end
elseif distanceToGround >= 0 then
acceleration = gravity
local magnusForce = calculateMagnusForce(linearVelocity.Unit, angularVelocity * Vector3.yAxis * 12)
if magnusForce == magnusForce and magnusForce.Magnitude > 0 then
acceleration += magnusForce
end

local function solveQuadratic(a, b, c, operation)
if operation == "+" then
return (-b + math.sqrt((b^2) - (4*a*c))) / (2*a)
else
return (-b - math.sqrt((b^2) - (4*a*c))) / (2*a)
end
end

local a, b, c = gravity.Y, linearVelocity.Y, distanceToGround
local quadratic = solveQuadratic(a, b, c, "-")
linearVelocity += acceleration*math.min(deltaTime, quadratic)
end

local direction = acceleration * deltaTime^2 + oldVelocity * deltaTime

local function doRaycast(rayDirection: Vector3): (RaycastResult?, boolean)
local length = rayDirection.Magnitude
if length == 0 or length > 1_000 then
return
end

local unitDirection = rayDirection.Unit
if unitDirection ~= unitDirection or length ~= length then
length = 1
unitDirection = Vector3.one
end

local skinThickness = 0.01
local raycastResult = workspace:Spherecast(startPos - unitDirection*skinThickness, radius, (unitDirection * (length + skinThickness*2)), raycastParams)
local distance = nil
if raycastResult then
distance = raycastResult.Distance + skinThickness
end
return raycastResult, distance
end

local hitPlayer: Player?, hitNet: BasePart?
if direction.Magnitude > 0 then
local raycastResult, distance = doRaycast(direction)

if raycastResult and not self.ballData.isResimulating and IsClient then
local character = localPlayer.Character
if character and raycastResult.Instance:IsDescendantOf(character) then
table.remove(filter, table.find(filter, character))
raycastParams.FilterDescendantsInstances = filter

hitPlayer = true
raycastResult, distance = doRaycast(direction)
end
end
local function checkIfHitPlayer()
local character = raycastResult.Instance
if not character:HasTag("ServerCharacterHitbox") then
character = character.Parent
if not character:HasTag("Goalkeeper") then
return
end
end
filter = {mapItems}
raycastParams.FilterDescendantsInstances = filter

hitPlayer = character
raycastResult, distance = doRaycast(direction)
end
if raycastResult and not IsClient then
checkIfHitPlayer()
end

doCollisionEffects = doCollisionEffects or not self.ballData.isResimulating
if raycastResult then
local newElasticity = elasticity
if raycastResult.Instance:HasTag("InvisibleBorder") then
newElasticity = 0.5
elseif raycastResult.Instance:HasTag("Net") then
newElasticity = 0.2
hitNet = raycastResult.Instance
end

local hitNormal = raycastResult.Normal
local hitPoint = raycastResult.Position

startPos = hitPoint + hitNormal * radius

local normalVelocityComponent = linearVelocity:Dot(hitNormal) * hitNormal
local tangentVelocityComponent = linearVelocity - normalVelocityComponent

normalVelocityComponent *= -newElasticity
tangentVelocityComponent *= 0.7

linearVelocity = normalVelocityComponent + tangentVelocityComponent
if linearVelocity.Y >= 1 then
angularVelocity = Vector3.new(tangentVelocityComponent.Z, 0, -tangentVelocityComponent.X) * newElasticity
end

if localPlayer and doCollisionEffects then
task.spawn(function()
ballHitPart(raycastResult)
end)
end

if linearVelocity.Y < 0.1 then
linearVelocity *= Vector3.new(1, 0, 1)
end
angularVelocity *= Vector3.new(1, 0, 1)
else
startPos += direction
end
end


if angularVelocity.Magnitude < 0.01 then
return startPos, linearVelocity, angularVelocity, quaternion, hitPlayer, hitNet
end

distanceToGround = startPos.Y - floorHeight
if distanceToGround < 0.1 then
local friction = 1.5 + self.constants.slippery*6
angularVelocity = MathUtils:VelocityFriction(angularVelocity, friction, deltaTime)

local realAngularVelocity = angularVelocity * deltaTime
local velocity = realAngularVelocity:Cross(Vector3.yAxis)
local raycastResult, distance = doRaycast(velocity)
local function checkIfHitPlayer()
local character = raycastResult.Instance
if not character:HasTag("ServerCharacterHitbox") then
character = character.Parent
if not character:HasTag("Goalkeeper") then
return
end
end
filter = {mapItems}
raycastParams.FilterDescendantsInstances = filter

hitPlayer = character
raycastResult, distance = doRaycast(velocity)
end
if raycastResult and not IsClient then
checkIfHitPlayer()
end

if raycastResult then
local newElasticity = elasticity
if raycastResult.Instance:HasTag("Net") then
hitNet = raycastResult.Instance
newElasticity = 0.5
end
local reflect = MathUtils:Reflect(velocity / deltaTime, raycastResult.Normal) * newElasticity
angularVelocity = Vector3.yAxis:Cross(reflect)

local hitNormal = raycastResult.Normal
local hitPoint = raycastResult.Position
startPos = hitPoint + hitNormal * radius

if localPlayer and doCollisionEffects then
task.spawn(function()
ballHitPart(raycastResult)
end)
end

angularVelocity *= Vector3.new(1, 0, 1)
else
startPos += velocity
end

local rotateCF = CFrame.fromAxisAngle(realAngularVelocity, realAngularVelocity.Magnitude)
if rotateCF == rotateCF and not self.ballData.isResimulating then
local moveQuaternion = Quaternion.fromCFrame(CFrame.fromAxisAngle(realAngularVelocity, realAngularVelocity.Magnitude))
quaternion = moveQuaternion:Mul(quaternion)
end
else
local realAngularVelocity = angularVelocity * deltaTime
local rotateCF = CFrame.fromAxisAngle(realAngularVelocity, realAngularVelocity.Magnitude)
if rotateCF == rotateCF and not self.ballData.isResimulating then
local moveQuaternion = Quaternion.fromCFrame(CFrame.fromAxisAngle(realAngularVelocity, realAngularVelocity.Magnitude))
quaternion = moveQuaternion:Mul(quaternion)
end
end

return startPos, linearVelocity, angularVelocity, quaternion, hitPlayer, hitNet
end


--This gets deltacompressed by the client/server chickynoids automatically
function BallSimulation:WriteState()
local record = {}
record.state = DeltaTable:DeepCopy(self.state)
return record
end

function BallSimulation:ReadState(record)
self.state = DeltaTable:DeepCopy(record.state)
end

return BallSimulation
replicatedfirst/Chickynoid/Shared/Simulation/CharacterData.lua
--!native
local CharacterData = {}
CharacterData.__index = CharacterData
local Animations = require(game.ReplicatedFirst.Chickynoid.Shared.Simulation.Animations)

local EPSILION = 0.00001
local mathUtils = require(script.Parent.MathUtils)
local Quaternion = require(script.Parent.Quaternion)



local function Lerp(a, b, frac)
return a:Lerp(b, frac)
end

local function AngleLerp(a, b, frac)
return mathUtils:LerpAngle(a, b, frac)
end

local function NumberLerp(a, b, frac)
return (a * (1 - frac)) + (b * frac)
end

local function Raw(_a, b, _frac)
return b
end

local MAX_FLOAT16 = math.pow(2, 16)
local function ValidateFloat16(float)
return math.clamp(float, -MAX_FLOAT16, MAX_FLOAT16)
end

local MAX_BYTE = 255
local function ValidateByte(byte)
return math.clamp(byte, 0, MAX_BYTE)
end

local function ValidateVector3(input)
return input
end

local function ValidateNumber(input)
return input
end

local function CompareVector3(a, b)
if math.abs(a.x - b.x) > EPSILION or math.abs(a.y - b.y) > EPSILION or math.abs(a.z - b.z) > EPSILION then
return false
end
return true
end

local function CompareVector2(a, b)
if math.abs(a.x - b.x) > EPSILION or math.abs(a.y - b.y) > EPSILION then
return false
end
return true
end

local function CompareByte(a, b)
return a == b
end

local function CompareFloat16(a, b)
return a == b
end

local function CompareNumber(a, b)
return a == b
end

local function WriteVector3(buf : buffer, offset : number, value : Vector3 ) : number
buffer.writef32(buf, offset, value.X)
offset+=4
buffer.writef32(buf, offset, value.Y)
offset+=4
buffer.writef32(buf, offset, value.Z)
offset+=4
return offset
end

local function ReadVector3(buf : buffer, offset : number)
local x = buffer.readf32(buf, offset)
offset+=4
local y = buffer.readf32(buf, offset)
offset+=4
local z = buffer.readf32(buf, offset)
offset+=4
return Vector3.new(x,y,z), offset
end

local function WriteFloat32(buf : buffer, offset : number, value : number ) : number
buffer.writef32(buf, offset, value)
offset+=4
return offset
end

local function ReadFloat32(buf : buffer, offset : number)
local x = buffer.readf32(buf, offset)
offset+=4
return x, offset
end

local function WriteByte(buf : buffer, offset : number, value : number ) : number
buffer.writeu8(buf, offset, value)
offset+=1
return offset
end

local function ReadByte(buf : buffer, offset : number)
local x = buffer.readu8(buf, offset)
offset+=1
return x, offset
end

local function WriteFloat16(buf : buffer, offset : number, value : number ) : number

local sign = value < 0
value = math.abs(value)

local mantissa, exponent = math.frexp(value)

if value == math.huge then
if sign then
buffer.writeu8(buf,offset,252)-- 11111100
offset+=1
else
buffer.writeu8(buf,offset,124) -- 01111100
offset+=1
end
buffer.writeu8(buf,offset,0) -- 00000000
offset+=1
return offset
elseif value ~= value or value == 0 then
buffer.writeu8(buf,offset,0)
offset+=1
buffer.writeu8(buf,offset,0)
offset+=1
return offset
elseif exponent + 15 <= 1 then -- Bias for halfs is 15
mantissa = math.floor(mantissa * 1024 + 0.5)
if sign then
buffer.writeu8(buf,offset,(128 + bit32.rshift(mantissa, 8))) -- Sign bit, 5 empty bits, 2 from mantissa
offset+=1
else
buffer.writeu8(buf,offset,(bit32.rshift(mantissa, 8)))
offset+=1
end
buffer.writeu8(buf,offset,bit32.band(mantissa, 255)) -- Get last 8 bits from mantissa
offset+=1
return offset
end

mantissa = math.floor((mantissa - 0.5) * 2048 + 0.5)

-- The bias for halfs is 15, 15-1 is 14
if sign then
buffer.writeu8(buf,offset,(128 + bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8)))
offset+=1
else
buffer.writeu8(buf,offset,(bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8)))
offset+=1
end
buffer.writeu8(buf,offset,bit32.band(mantissa, 255))
offset+=1

return offset
end

local function ReadFloat16(buf : buffer, offset : number)

local b0 = buffer.readu8(buf, offset)
offset+=1
local b1 = buffer.readu8(buf, offset)
offset+=1

local sign = bit32.btest(b0, 128)
local exponent = bit32.rshift(bit32.band(b0, 127), 2)
local mantissa = bit32.lshift(bit32.band(b0, 3), 8) + b1

if exponent == 31 then --2^5-1
if mantissa ~= 0 then
return (0 / 0), offset
else
return (sign and -math.huge or math.huge), offset
end
elseif exponent == 0 then
if mantissa == 0 then
return 0, offset
else
return (sign and -math.ldexp(mantissa / 1024, -14) or math.ldexp(mantissa / 1024, -14)), offset
end
end

mantissa = (mantissa / 1024) + 1

return (sign and -math.ldexp(mantissa, exponent - 15) or math.ldexp(mantissa, exponent - 15)), offset
end

local function WriteVector2(buf : buffer, offset : number, value : Vector2 ) : number
buffer.writef32(buf, offset, value.X)
offset+=4
buffer.writef32(buf, offset, value.Y)
offset+=4
return offset
end

local function ReadVector2(buf : buffer, offset : number)
local x = buffer.readf32(buf, offset)
offset+=4
local y = buffer.readf32(buf, offset)
offset+=4
return Vector2.new(x, y), offset
end

function CharacterData:SetIsResimulating(bool)
self.isResimulating = bool
end

function CharacterData:ModuleSetup()
CharacterData.methods = {}
CharacterData.methods["Vector3"] = {
write = WriteVector3,
read = ReadVector3,
validate = ValidateVector3,
compare = CompareVector3,
}
CharacterData.methods["Vector2"] = {
write = WriteVector2,
read = ReadVector2,
validate = ValidateVector3,
compare = CompareVector2,
}
CharacterData.methods["Float16"] = {
write = WriteFloat16,
read = ReadFloat16,
validate = ValidateFloat16,
compare = CompareFloat16,
}
CharacterData.methods["Float32"] = {
write = WriteFloat32,
read = ReadFloat32,
validate = ValidateNumber,
compare = CompareNumber,
}

CharacterData.methods["Byte"] = {
write = WriteByte,
read = ReadByte,
validate = ValidateByte,
compare = CompareByte,
}

CharacterData.packFunctions = {
pos = "Vector3",
ballRotation = "Vector3",
leanAngle = "Vector2",

w = "Float32",
animDir = "Byte",

angle = "Float16",
stepUp = "Float16",
flatSpeed = "Float16",
exclusiveAnimTime = "Float32",

animCounter0 = "Byte",
animNum0 = "Byte",
animCounter1 = "Byte",
animNum1 = "Byte",
animCounter2 = "Byte",
animNum2 = "Byte",
}

CharacterData.keys =
{
"pos",
"ballRotation",
"leanAngle",

"w",
"animDir",

"angle",
"stepUp",
"flatSpeed",
"exclusiveAnimTime",

"animCounter0",
"animNum0",
"animCounter1",
"animNum1",
"animCounter2",
"animNum2",
}


CharacterData.lerpFunctions = {
pos = Lerp,
ballRotation = Lerp,
leanAngle = Lerp,

w = NumberLerp,
animDir = Raw,

angle = AngleLerp,
stepUp = NumberLerp,
flatSpeed = NumberLerp,
exclusiveAnimTime = Raw,

animCounter0 = Raw,
animNum0 = Raw,
animCounter1 = Raw,
animNum1 = Raw,
animCounter2 = Raw,
animNum2 = Raw,
}


--This isn't serialized, instead the characterMod field is used to run the same modifications on client and server
self.animationNames = {}
self.animationIndices = {}

self:RegisterAnimationName("Idle")
self:RegisterAnimationName("Walk")
self:RegisterAnimationName("Jump")
self:RegisterAnimationName("Fall")
self:RegisterAnimationName("Push")

end

function CharacterData.new()
local self = setmetatable({
serialized = {
pos = Vector3.zero,
ballRotation = Vector3.xAxis,
leanAngle = Vector2.zero,

w = 1,
animDir = 0,

angle = 0,
stepUp = 0,
flatSpeed = 0,
exclusiveAnimTime = 0,

animCounter0 = 0,
animNum0 = 0,
animCounter1 = 0,
animNum1 = 0,
animCounter2 = 0,
animNum2 = 0,
},

--Be extremely careful about having any kind of persistant nonserialized data!
--If in doubt, stick it in the serialized!
isResimulating = false,
targetPosition = Vector3.zero,

}, CharacterData)

return self
end

--This smoothing is performed on the server only.
--On client, use GetPosition
function CharacterData:SmoothPosition(deltaTime, smoothScale)
if (smoothScale == 1 or smoothScale == 0) then
self.serialized.pos = self.targetPosition
else
self.serialized.pos = mathUtils:SmoothLerp(self.serialized.pos, self.targetPosition, smoothScale, deltaTime)
end
end

function CharacterData:ClearSmoothing()
self.serialized.pos = self.targetPosition
end

--Sets the target position
function CharacterData:SetTargetPosition(pos, teleport)
self.targetPosition = pos
if (teleport) then
self:ClearSmoothing()
end
end

function CharacterData:GetPosition()
return self.serialized.pos
end

function CharacterData:SetFlatSpeed(num)
self.serialized.flatSpeed = num
end

function CharacterData:SetAngle(angle)
self.serialized.angle = angle
end

function CharacterData:ChangeBallRotation(rotateCFrame: CFrame)
local ballRotation = self.serialized.ballRotation
local quaternion1 = Quaternion.new(ballRotation.X, ballRotation.Y, ballRotation.Z, self.serialized.w)
local quaternion2 = Quaternion.fromCFrame(rotateCFrame)
local newQuaternion = quaternion1:Mul(quaternion2)
self.serialized.ballRotation = Vector3.new(newQuaternion.X, newQuaternion.Y, newQuaternion.Z)
self.serialized.w = newQuaternion.W
end

function CharacterData:SetAnimDir(animDir)
self.serialized.animDir = animDir
end

function CharacterData:LerpLeanAngle(newAngle: Vector2, alpha: number)
self.serialized.leanAngle = self.serialized.leanAngle:Lerp(newAngle, alpha)
end

function CharacterData:GetAngle()
return self.serialized.angle
end

function CharacterData:SetStepUp(amount)
self.serialized.stepUp = amount
end

function CharacterData:PlayAnimation(animName : string, animChannel, forceRestart, exclusiveTime)

local animIndex =Animations:GetAnimationIndex(animName)
if (animIndex == nil) then
animIndex = 1
end
self:PlayAnimationIndex(animIndex, animChannel, forceRestart, exclusiveTime, animName)
end

function CharacterData:PlayAnimationIndex(animNum, animChannel, forceRestart, exclusiveTime, animName)
--Dont change animations during resim
if self.isResimulating == true then
return
end

if (animChannel < 0 or animChannel > 3) then
return
end

--If we're in an exclusive window of having an animation play, ignore this request
if tick() < self.serialized.exclusiveAnimTime and forceRestart == false then
return
end
if exclusiveTime ~= nil and exclusiveTime > 0 then
self.serialized.exclusiveAnimTime = tick() + exclusiveTime
end

local counterString = "animCounter"..animChannel
local slotString = "animNum"..animChannel

--Restart this anim, or its a different anim than we're currently playing
if forceRestart == true or self.serialized[slotString] ~= animNum then
self.serialized[counterString] += 1
if self.serialized[counterString] > 255 then
self.serialized[counterString] = 0
end
end
self.serialized[slotString] = animNum
end


function CharacterData:InternalSetAnim(animChannel, animNum)
local counterString = "animCounter"..animChannel
local slotString = "animNum"..animChannel

self.serialized[counterString] += 1
if self.serialized[counterString] > 255 then
self.serialized[counterString] = 0
end
self.serialized[slotString] = 0
end
function CharacterData:StopAnimation(animChannel)
self:InternalSetAnim(animChannel, 0)
end

function CharacterData:StopAllAnimation()
self.serialized.exclusiveAnimTime = 0
self:InternalSetAnim(0, 0)
self:InternalSetAnim(1, 0)
self:InternalSetAnim(2, 0)
self:InternalSetAnim(3, 0)
end


function CharacterData:Serialize()
local ret = {}
--Todo: Add bitpacking
for key, _ in pairs(self.serialized) do
ret[key] = self.serialized[key]
end

return ret
end

function CharacterData:SerializeToBitBuffer(previousData, buf : buffer, offset: number)

if (previousData == nil) then
return self:SerializeToBitBufferFast(buf, offset)
end

local contentWritePos = offset
offset += 2 --2 bytes contents

local contentBits = 0
local bitIndex = 0

if previousData == nil then

--Slow path that wont be hit
contentBits = 0xFFFF

for keyIndex, key in CharacterData.keys do
local value = self.serialized[key]
local func = CharacterData.methods[CharacterData.packFunctions[key]]
offset = func.write(buf, offset, value)
end
else
--calculate bits
for keyIndex, key in CharacterData.keys do
local value = self.serialized[key]
local func = CharacterData.methods[CharacterData.packFunctions[key]]

local valueA = previousData.serialized[key]
local valueB = value

if func.compare(valueA, valueB) == false then
contentBits = bit32.bor(contentBits, bit32.lshift(1, bitIndex))
offset = func.write(buf, offset, value)
end
bitIndex += 1
end

end

buffer.writeu16(buf, contentWritePos, contentBits)
return offset
end


function CharacterData:SerializeToBitBufferFast(buf : buffer, offset: number)

local contentWritePos = offset
offset += 2 --2 bytes contents

local contentBits = 0xFFFF

local serialized = self.serialized

offset = WriteVector3(buf, offset, serialized.pos)
offset = WriteVector3(buf, offset, serialized.ballRotation)
offset = WriteVector2(buf, offset, serialized.leanAngle)

offset = WriteFloat32(buf, offset, serialized.w)
offset = WriteByte(buf, offset, serialized.animDir)

offset = WriteFloat16(buf, offset, serialized.angle)
offset = WriteFloat16(buf, offset, serialized.stepUp)
offset = WriteFloat16(buf, offset, serialized.flatSpeed)
offset = WriteFloat32(buf, offset, serialized.exclusiveAnimTime)

offset = WriteByte(buf, offset, serialized.animCounter0)
offset = WriteByte(buf, offset, serialized.animNum0)
offset = WriteByte(buf, offset, serialized.animCounter1)
offset = WriteByte(buf, offset, serialized.animNum1)
offset = WriteByte(buf, offset, serialized.animCounter2)
offset = WriteByte(buf, offset, serialized.animNum2)

buffer.writeu16(buf, contentWritePos, contentBits)
return offset
end



function CharacterData:DeserializeFromBitBuffer(buf : buffer, offset: number)

local contentBits = buffer.readu16(buf, offset)
offset+=2

local bitIndex = 0
for keyIndex, key in CharacterData.keys do
local value = self.serialized[key]
local hasBit = bit32.band(contentBits, bit32.lshift(1, bitIndex)) > 0

if hasBit then
local func = CharacterData.methods[CharacterData.packFunctions[key]]
self.serialized[key],offset = func.read(buf, offset)
end
bitIndex += 1
end
return offset
end

function CharacterData:CopySerialized(otherSerialized)
for key, value in pairs(otherSerialized) do
self.serialized[key] = value
end
end

function CharacterData:Interpolate(dataA, dataB, fraction)
local dataRecord = {}
for key, _ in pairs(dataA) do
if key == "w" then continue end
if key == "ballRotation" then
local posA = dataA.ballRotation
local quaternionA = Quaternion.new(posA.X, posA.Y, posA.Z, dataA.w)
local posB = dataB.ballRotation
local quaternionB = Quaternion.new(posB.X, posB.Y, posB.Z, dataB.w)
local newQuaternion = quaternionA:Slerp(quaternionB, fraction)
dataRecord.ballRotation = Vector3.new(newQuaternion.X, newQuaternion.Y, newQuaternion.Z)
dataRecord.w = newQuaternion.W
continue
end

local func = CharacterData.lerpFunctions[key]

if func == nil then
dataRecord[key] = dataB[key]
else
dataRecord[key] = func(dataA[key], dataB[key], fraction)
end
end

return dataRecord
end

function CharacterData:AnimationNameToAnimationIndex(name)

return self.animationNames[name]
end

function CharacterData:AnimationIndexToAnimationName(index)
return self.animationIndices[index]
end

function CharacterData:RegisterAnimationName(name)

table.insert(self.animationIndices, name)
local index = #self.animationIndices

if (index > 255) then
error("Too many animations registered, you'll need to use a int16")
end
self.animationNames[name] = index

end

function CharacterData:ClearAnimationNames()
self.animationNames = {}
self.animationIndices = {}
end

CharacterData:ModuleSetup()
return CharacterData
replicatedfirst/Chickynoid/Shared/Simulation/CollisionModule.lua
--@!native
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local path = script.Parent.Parent

local MinkowskiSumInstance = require(script.Parent.MinkowskiSumInstance)
local TerrainModule = require(script.Parent.TerrainCollision)
local FastSignal = require(path.Vendor.FastSignal)

local module = {}
module.hullRecords = {}
module.dynamicRecords = {}

local SKIN_THICKNESS = 0.05 --closest you can get to a wall
module.planeNum = 0
module.gridSize = 4
module.fatGridSize = 16
module.fatPartSize = 32
module.profile = false

module.grid = {}
module.fatGrid = {}
module.cache = {}
module.cacheCount = 0
module.maxCacheCount = 1000

module.loadProgress = 0
module.OnLoadProgressChanged = FastSignal.new()

module.expansionSize = Vector3.new(2, 5, 2)

local debugParts = false

local corners = {
Vector3.new(0.5, 0.5, 0.5),
Vector3.new(0.5, 0.5, -0.5),
Vector3.new(-0.5, 0.5, 0.5),
Vector3.new(-0.5, 0.5, -0.5),
Vector3.new(0.5, -0.5, 0.5),
Vector3.new(0.5, -0.5, -0.5),
Vector3.new(-0.5, -0.5, 0.5),
Vector3.new(-0.5, -0.5, -0.5),
}

function module:FetchCell(x, y, z)
local key = Vector3.new(x,y,z)
return self.grid[key]
end

function module:FetchFatCell(x, y, z)
local key = Vector3.new(x,y,z)
return self.fatGrid[key]
end

function module:CreateAndFetchCell(x, y, z)
local key = Vector3.new(x,y,z)
local res = self.grid[key]
if (res == nil) then
res = {}
self.grid[key] = res
end
return res
end

function module:CreateAndFetchFatCell(x, y, z)
local key = Vector3.new(x,y,z)
local res = self.fatGrid[key]
if (res == nil) then
res = {}
self.fatGrid[key] = res
end
return res
end

function module:FindAABB(part)
local orientation = part.CFrame
local size = part.Size

local minx = math.huge
local miny = math.huge
local minz = math.huge
local maxx = -math.huge
local maxy = -math.huge
local maxz = -math.huge

for _, corner in pairs(corners) do
local vec = orientation * (size * corner)
if vec.x < minx then
minx = vec.x
end
if vec.y < miny then
miny = vec.y
end
if vec.z < minz then
minz = vec.z
end
if vec.x > maxx then
maxx = vec.x
end
if vec.y > maxy then
maxy = vec.y
end
if vec.z > maxz then
maxz = vec.z
end
end
return minx, miny, minz, maxx, maxy, maxz
end

function module:FindPointsAABB(points)
local minx = math.huge
local miny = math.huge
local minz = math.huge
local maxx = -math.huge
local maxy = -math.huge
local maxz = -math.huge

for _, vec in pairs(points) do
if vec.x < minx then
minx = vec.x
end
if vec.y < miny then
miny = vec.y
end
if vec.z < minz then
minz = vec.z
end
if vec.x > maxx then
maxx = vec.x
end
if vec.y > maxy then
maxy = vec.y
end
if vec.z > maxz then
maxz = vec.z
end
end
return minx, miny, minz, maxx, maxy, maxz
end


function module:WritePartToHashMap(instance, hullRecord)
local minx, miny, minz, maxx, maxy, maxz = self:FindAABB(instance)

if (maxx-minx > self.fatPartSize or maxy-miny > self.fatPartSize or maxz-minz > self.fatPartSize) then

--Part is fat
for x = (minx // self.fatGridSize), (maxx // self.fatGridSize) do
for z = (minz // self.fatGridSize), (maxz // self.fatGridSize) do
for y = (miny // self.fatGridSize), (maxy // self.fatGridSize) do
local cell = self:CreateAndFetchFatCell(x, y, z)
cell[instance] = hullRecord
end
end
end
--print("Fat part", instance.Name)

--[[
if (game["Run Service"]:IsClient() and instance:GetAttribute("showdebug")) then
for x = math.floor(minx / self.fatGridSize), math.ceil(maxx/self.fatGridSize)-1 do
for z = math.floor(minz / self.fatGridSize), math.ceil(maxz/self.fatGridSize)-1 do
for y = math.floor(miny / self.fatGridSize), math.ceil(maxy/self.fatGridSize)-1 do

self:SpawnDebugFatGridBox(x,y,z, Color3.new(math.random(),1,1))
end
end
end
end
]]--
else
for x = (minx // self.gridSize), (maxx // self.gridSize) do
for z = (minz // self.gridSize), (maxz // self.gridSize) do
for y = (miny // self.gridSize), (maxy // self.gridSize) do
local cell = self:CreateAndFetchCell(x, y, z)
cell[instance] = hullRecord
end
end
end
--[[
if (game["Run Service"]:IsClient() and instance:GetAttribute("showdebug")) then
for x = math.floor(minx / self.gridSize), math.ceil(maxx/self.gridSize)-1 do
for z = math.floor(minz / self.gridSize), math.ceil(maxz/self.gridSize)-1 do
for y = math.floor(miny / self.gridSize), math.ceil(maxy/self.gridSize)-1 do

self:SpawnDebugGridBox(x,y,z, Color3.new(math.random(),1,1))
end
end
end
end]]
--
end
end



function module:RemovePartFromHashMap(instance)
if instance:GetAttribute("ChickynoidIgnoreRemoval") then
return
end

local minx, miny, minz, maxx, maxy, maxz = self:FindAABB(instance)

if (maxx-minx > self.fatPartSize or maxy-miny > self.fatPartSize or maxz-minz > self.fatPartSize) then

for x = (minx // self.fatGridSize), (maxx // self.fatGridSize) do
for z = (minz // self.fatGridSize), (maxz // self.fatGridSize) do
for y = (miny // self.fatGridSize), (maxy // self.fatGridSize) do
local cell = self:FetchFatCell(x, y, z)
if cell then
cell[instance] = nil
end
end
end
end

else
for x = (minx // self.gridSize), (maxx // self.gridSize) do
for z = (minz // self.gridSize), (maxz // self.gridSize) do
for y = (miny // self.gridSize), (maxy // self.gridSize) do
local cell = self:FetchCell(x, y, z)
if cell then
cell[instance] = nil
end
end
end
end
end
end

function module:FetchHullsForPoint(point)
local cell = self:FetchCell(
point.x // self.gridSize,
point.y // self.gridSize,
point.z // self.gridSize
)
local hullRecords = {}
if cell then
for _, hull in cell do
hullRecords[hull] = hull
end
end

local cell = self:FetchFatCell(
point.x // self.fatGridSize,
point.y // self.fatGridSize,
point.z // self.fatGridSize
)
local hullRecords = {}
if cell then
for _, hull in cell do
hullRecords[hull] = hull
end
end

return hullRecords
end

function module:FetchHullsForBox(min, max)
local minx = min.x
local miny = min.y
local minz = min.z
local maxx = max.x
local maxy = max.y
local maxz = max.z

if minx > maxx then
local t = minx
minx = maxx
maxx = t
end
if miny > maxy then
local t = miny
miny = maxy
maxy = t
end
if minz > maxz then
local t = minz
minz = maxz
maxz = t
end

local key = Vector3.new(minx, minz, miny) // self.gridSize
local otherKey = Vector3.new(maxx, maxy, maxz) // self.gridSize


local cached = self.cache[key]
if (cached) then
local rec = cached[otherKey]
if (rec) then
return rec
end
end


local hullRecords = {}

--Expanded by 1, so objects right on borders will be in the appropriate query
for x = (minx // self.gridSize) - 1, (maxx // self.gridSize)+1 do
for z = (minz // self.gridSize) - 1, (maxz // self.gridSize)+1 do
for y = (miny // self.gridSize) - 1, (maxy // self.gridSize)+1 do
local cell = self:FetchCell(x, y, z)
if cell then
for _, hull in cell do
hullRecords[hull] = hull
end
end

local terrainHull = TerrainModule:FetchCell(x, y, z)
if terrainHull then
for _, hull in pairs(terrainHull) do
hullRecords[hull] = hull
end
end
end
end
end

--Expanded by 1, so objects right on borders will be in the appropriate query
for x = (minx // self.fatGridSize) - 1, (maxx // self.fatGridSize)+1 do
for z = (minz // self.fatGridSize) - 1, (maxz // self.fatGridSize)+1 do
for y = (miny // self.fatGridSize) - 1, (maxy // self.fatGridSize)+1 do
local cell = self:FetchFatCell(x, y, z)
if cell then
for _, hull in cell do
hullRecords[hull] = hull
end
end
end
end
end


self.cacheCount+=1
if (self.cacheCount > self.maxCacheCount) then
self:ClearCache()
end

--Store it
local cached = self.cache[key]
if (cached == nil) then
cached = {}
self.cache[key] = cached
end
cached[otherKey] = hullRecords


--Inflate missing hulls
for key,record in pairs(hullRecords) do

if (record.hull == nil) then
record.hull = self:GenerateConvexHullAccurate(record.instance, module.expansionSize, self:GenerateSnappedCFrame(record.instance))


if (record.hull == nil) then
hullRecords[key] = nil
end
end
end


return hullRecords
end

function module:GenerateConvexHullAccurate(part, expansionSize, cframe)
local debugRoot = nil
if debugParts == true and RunService:IsClient() then
debugRoot = game.Workspace.Terrain
end

local hull, counter = MinkowskiSumInstance:GetPlanesForInstance(
part,
expansionSize,
cframe,
self.planeNum,
debugRoot
)
self.planeNum = counter
return hull
end


--1/100th of a degree 0.01 etc
local function RoundOrientation(num)
return math.floor(num * 100 + 0.5) / 100
end

function module:GenerateSnappedCFrame(instance)

--Because roblox cannot guarentee perfect replication of part orientation, we'll take what is replicated and rount it after a certain level of precision
--techically positions might have the same problem, but orientations were mispredicting on sloped surfaces
local x = RoundOrientation(instance.Orientation.X)
local y = RoundOrientation(instance.Orientation.Y)
local z = RoundOrientation(instance.Orientation.Z)

local newCF = CFrame.new(instance.CFrame.Position) * CFrame.fromOrientation(math.rad(x), math.rad(y), math.rad(z))
return newCF
end

function module:ProcessCollisionOnInstance(instance, playerSize)
if instance:IsA("BasePart") then
if instance.CanCollide == false then
return
end

if module.hullRecords[instance] ~= nil then
return
end

--[[
if CollectionService:HasTag(instance, "Dynamic") then
local record = {}
record.instance = instance
record.hull = self:GenerateConvexHullAccurate(instance, playerSize, instance.CFrame)
record.currentCFrame = instance.CFrame

-- Weird Selene shadowing bug here
-- selene: allow(shadowing)
function record:Update()
if
((record.currentCFrame.Position - instance.CFrame.Position).magnitude < 0.00001)
and (record.currentCFrame.LookVector:Dot(instance.CFrame.LookVector) > 0.999)
then
return
end

record.hull = module:GenerateConvexHullAccurate(instance, playerSize, instance.CFrame)
record.currentCFrame = instance.CFrame
end

table.insert(module.dynamicRecords, record)

return
end]]--

local record = {}
record.instance = instance
--record.hull = self:GenerateConvexHullAccurate(instance, playerSize, self:GenerateSnappedCFrame(instance))
self:WritePartToHashMap(record.instance, record)

module.hullRecords[instance] = record
end
end

function module:SpawnDebugGridBox(x, y, z, color)
local instance = Instance.new("Part")
instance.Size = Vector3.new(self.gridSize, self.gridSize, self.gridSize)
instance.Position = (Vector3.new(x, y, z) * self.gridSize)
+ (Vector3.new(self.gridSize, self.gridSize, self.gridSize) * 0.5)
instance.Transparency = 0.75
instance.Color = color
instance.Parent = game.Workspace
instance.Anchored = true
instance.TopSurface = Enum.SurfaceType.Smooth
instance.BottomSurface = Enum.SurfaceType.Smooth
end

function module:SpawnDebugFatGridBox(x, y, z, color)
local instance = Instance.new("Part")
instance.Size = Vector3.new(self.fatGridSize, self.fatGridSize, self.fatGridSize)
instance.Position = (Vector3.new(x, y, z) * self.fatGridSize)
+ (Vector3.new(self.fatGridSize, self.fatGridSize, self.fatGridSize) * 0.5)
instance.Transparency = 0.75
instance.Color = color
instance.Parent = game.Workspace
instance.Anchored = true
instance.TopSurface = Enum.SurfaceType.Smooth
instance.BottomSurface = Enum.SurfaceType.Smooth
end

function module:SimpleRayTest(a, b, hull)
-- Compute direction vector for the segment
local d = b - a
-- Set initial interval to being the whole segment. For a ray, tlast should be
-- set to +FLT_MAX. For a line, additionally tfirst should be set to –FLT_MAX
local tfirst = -1
local tlast = 1

--Intersect segment against each plane

for _, p in pairs(hull) do
local denom = p.n:Dot(d)
local dist = p.ed - (p.n:Dot(a))

--Test if segment runs parallel to the plane
if denom == 0 then
-- If so, return “no intersection” if segment lies outside plane
if dist > 0 then
return nil
end
else
-- Compute parameterized t value for intersection with current plane
local t = dist / denom
if denom < 0 then
-- When entering halfspace, update tfirst if t is larger
if t > tfirst then
tfirst = t
end
else
-- When exiting halfspace, update tlast if t is smaller
if t < tlast then
tlast = t
end
end

-- Exit with “no intersection” if intersection becomes empty
if tfirst > tlast then
return nil
end
end
end
-- A nonzero logical intersection, so the segment intersects the polyhedron
return tfirst, tlast
end

function module:CheckBrushPoint(data, hullRecord)
local startsOut = false

for _, p in pairs(hullRecord.hull) do
local startDistance = data.startPos:Dot(p.n) - p.ed

if startDistance > 0 then
startsOut = true
break
end
end

if startsOut == false then
data.startSolid = true
data.allSolid = true
return
end

data.hullRecord = hullRecord
end

--Checks a brush, but doesn't handle it well if the start point is inside a brush
function module:CheckBrush(data, hullRecord)
local startFraction = -1.0
local endFraction = 1.0
local startsOut = false
local endsOut = false
local lastPlane = nil

for _, p in pairs(hullRecord.hull) do
local startDistance = data.startPos:Dot(p.n) - p.ed
local endDistance = data.endPos:Dot(p.n) - p.ed

if startDistance > 0 then
startsOut = true
end
if endDistance > 0 then
endsOut = true
end

-- make sure the trace isn't completely on one side of the brush
if startDistance > 0 and (endDistance >= SKIN_THICKNESS or endDistance >= startDistance) then
return --both are in front of the plane, its outside of this brush
end
if startDistance <= 0 and endDistance <= 0 then
--both are behind this plane, it will get clipped by another one
continue
end

if startDistance > endDistance then
-- line is entering into the brush
local fraction = (startDistance - SKIN_THICKNESS) / (startDistance - endDistance)
if fraction < 0 then
fraction = 0
end
if fraction > startFraction then
startFraction = fraction
lastPlane = p
end
else
--line is leaving the brush
local fraction = (startDistance + SKIN_THICKNESS) / (startDistance - endDistance)
if fraction > 1 then
fraction = 1
end
if fraction < endFraction then
endFraction = fraction
end
end
end

if startsOut == false then
data.startSolid = true
if endsOut == false then
--Allsolid
data.allSolid = true
return
end
end

--Update the output fraction
if startFraction < endFraction then
if startFraction > -1 and startFraction < data.fraction then
if startFraction < 0 then
startFraction = 0
end
data.fraction = startFraction
data.normal = lastPlane.n
data.planeD = lastPlane.ed
data.planeNum = lastPlane.planeNum
data.hullRecord = hullRecord
end
end
end

--Checks a brush, but is smart enough to ignore the brush entirely if the start point is inside but the ray is "exiting" or "exited"
function module:CheckBrushNoStuck(data, hullRecord)
local startFraction = -1.0
local endFraction = 1.0
local startsOut = false
local endsOut = false
local lastPlane = nil

local nearestStart = -math.huge
local nearestEnd = -math.huge

for _, p in pairs(hullRecord.hull) do
local startDistance = data.startPos:Dot(p.n) - p.ed
local endDistance = data.endPos:Dot(p.n) - p.ed

if startDistance > 0 then
startsOut = true
end

if endDistance > 0 then
endsOut = true
end

-- make sure the trace isn't completely on one side of the brush
if startDistance > 0 and (endDistance >= SKIN_THICKNESS or endDistance >= startDistance) then
return --both are in front of the plane, its outside of this brush
end

--Record the distance to this plane
nearestStart = math.max(nearestStart, startDistance)
nearestEnd = math.max(nearestEnd, endDistance)

if startDistance <= 0 and endDistance <= 0 then
--both are behind this plane, it will get clipped by another one
continue
end

if startDistance > endDistance then
-- line is entering into the brush
local fraction = (startDistance - SKIN_THICKNESS) / (startDistance - endDistance)
if fraction < 0 then
fraction = 0
end
if fraction > startFraction then
startFraction = fraction
lastPlane = p
end
else
--line is leaving the brush
local fraction = (startDistance + SKIN_THICKNESS) / (startDistance - endDistance)
if fraction > 1 then
fraction = 1
end
if fraction < endFraction then
endFraction = fraction
end
end
end

--Point started inside this brush
if startsOut == false then
data.startSolid = true

--We might be both start-and-end solid
--If thats the case, we want to pretend we never saw this brush if we are moving "out"
--This is either: we exited - or -
-- the end point is nearer any plane than the start point is
if endsOut == false and nearestEnd < nearestStart then
--Allsolid
data.allSolid = true
return
end

--Not stuck! We should pretend we never touched this brush
data.startSolid = false
return --Ignore this brush
end

--Update the output fraction
if startFraction < endFraction then
if startFraction > -1 and startFraction < data.fraction then
if startFraction < 0 then
startFraction = 0
end
data.fraction = startFraction
data.normal = lastPlane.n
data.planeD = lastPlane.ed
data.planeNum = lastPlane.planeNum
data.hullRecord = hullRecord
end
end
end

function module:PlaneLineIntersect(normal, distance, V1, V2)
local diff = V2 - V1
local denominator = normal:Dot(diff)
if denominator == 0 then
return nil
end
local u = (normal.x * V1.x + normal.y * V1.y + normal.z * V1.z + distance) / -denominator

return (V1 + u * (V2 - V1))
end

function module:Sweep(startPos, endPos)
local data = {}
data.startPos = startPos
data.endPos = endPos
data.fraction = 1
data.startSolid = false
data.allSolid = false
data.planeNum = 0
data.planeD = 0
data.normal = Vector3.new(0, 1, 0)
data.checks = 0
data.hullRecord = nil

if (startPos - endPos).magnitude > 1000 then
return data
end
if (self.profile == true) then
debug.profilebegin("Sweep")
end
--calc bounds of sweep
if (self.profile == true) then
debug.profilebegin("Fetch")
end
local hullRecords = self:FetchHullsForBox(startPos, endPos)
if (self.profile==true) then
debug.profileend()
end

if (self.profile == true) then
debug.profilebegin("Collide")
end
for _, hullRecord in pairs(hullRecords) do
data.checks += 1

if (hullRecord.hull ~= nil) then
self:CheckBrushNoStuck(data, hullRecord)
if data.allSolid == true then
data.fraction = 0
break
end
if data.fraction < SKIN_THICKNESS then
break
end
end
end
if (self.profile == true) then
debug.profileend()
end

--Collide with dynamic objects
if data.fraction >= SKIN_THICKNESS or data.allSolid == false then
for _, hullRecord in pairs(self.dynamicRecords) do
data.checks += 1

self:CheckBrushNoStuck(data, hullRecord)
if (data.allSolid == true) then
data.fraction = 0
break
end
if data.fraction < SKIN_THICKNESS then
break
end
end
end

if data.fraction < 1 then
local vec = (endPos - startPos)
data.endPos = startPos + (vec * data.fraction)
end

if (self.profile == true) then
debug.profileend()
end
return data
end

function module:BoxTest(pos)
local data = {}
data.startPos = pos
data.endPos = pos
data.fraction = 1
data.startSolid = false
data.allSolid = false
data.planeNum = 0
data.planeD = 0
data.normal = Vector3.new(0, 1, 0)
data.checks = 0
data.hullRecord = nil

debug.profilebegin("PointTest")
--calc bounds of sweep
local hullRecords = self:FetchHullsForPoint(pos)

for _, hullRecord in pairs(hullRecords) do
data.checks += 1
self:CheckBrushPoint(data, hullRecord)
if data.allSolid == true then
data.fraction = 0
break
end
end

debug.profileend()
return data
end

--Call this before you try and simulate
function module:UpdateDynamicParts()
for _, record in pairs(self.dynamicRecords) do
if record.Update then
record:Update()
end
end
end

function module:MakeWorld(folder, playerSize)

debug.setmemorycategory("ChickynoidCollision")

self.expansionSize = playerSize
self.hulls = {}
self:ClearCache()

if (self.processing == true) then
return
end
self.processing = true
TerrainModule:Setup(self.gridSize, playerSize)

local startTime = tick()
local meshTime = 0

coroutine.wrap(function()
local list = folder:GetDescendants()
local total = #folder:GetDescendants()

local lastTime = tick()
for counter = 1, total do
local instance = list[counter]

if (instance:IsA("BasePart") and instance.CanCollide == true) then

local begin = tick()
self:ProcessCollisionOnInstance(instance, playerSize)
local timeTaken = tick()- begin
if (instance:IsA("MeshPart")) then
meshTime += timeTaken
end
end

local maxTime = 0.2

if (tick() - lastTime > maxTime) then
lastTime = tick()

wait()

local progress = counter/total;
module.loadProgress = progress;
module.OnLoadProgressChanged:Fire(progress)
print("Collision processing: " .. math.floor(progress * 100) .. "%")
end
end
module.loadProgress = 1
module.OnLoadProgressChanged:Fire(1)
print("Collision processing: 100%")
self.processing = false

if (game["Run Service"]:IsServer()) then
print("Server Time Taken: ", math.floor(tick() - startTime), "seconds")

else
print("Client Time Taken: ", math.floor(tick() - startTime), "seconds")
end
print("Mesh time: ", meshTime, "seconds")
print("Tracing time:", MinkowskiSumInstance.timeSpentTracing, "seconds")
self:ClearCache()

end)()



folder.DescendantAdded:Connect(function(instance)
self:ClearCache()
self:ProcessCollisionOnInstance(instance, playerSize)
end)

folder.DescendantRemoving:Connect(function(instance)
local record = module.hullRecords[instance]

if record then
self:ClearCache()
self:RemovePartFromHashMap(instance)
end
end)
end

function module:ClearCache()
self.cache = {}
self.cacheCount = 0
end

return module
replicatedfirst/Chickynoid/Shared/Simulation/CommandLayout.lua
local module = {}


local CrunchTable = require(script.Parent.Parent.Vendor.CrunchTable)

function module:GetCommandLayout()

if (self.commandLayout == nil) then
self.commandLayout = CrunchTable:CreateLayout()

self.commandLayout:Add("localFrame",CrunchTable.Enum.INT32)
self.commandLayout:Add("serverTime", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("deltaTime", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("snapshotServerFrame", CrunchTable.Enum.INT32)
self.commandLayout:Add("playerStateFrame", CrunchTable.Enum.INT32)
self.commandLayout:Add("shiftLock", CrunchTable.Enum.UBYTE)
self.commandLayout:Add("x", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("y", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("z", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("fa", CrunchTable.Enum.VECTOR3)
self.commandLayout:Add("f", CrunchTable.Enum.FLOAT)
self.commandLayout:Add("j", CrunchTable.Enum.FLOAT)

self.commandLayout:Add("j", CrunchTable.Enum.FLOAT)

self.commandLayout:Add("sprinting", CrunchTable.Enum.UBYTE)
self.commandLayout:Add("tackleDir", CrunchTable.Enum.VECTOR3)
self.commandLayout:Add("diveDir", CrunchTable.Enum.VECTOR3)
end

return self.commandLayout
end

function module:EncodeCommand(command)
return CrunchTable:BinaryEncodeTable(command, self:GetCommandLayout())
end

function module:DecodeCommand(command)
return CrunchTable:BinaryDecodeTable(command, self:GetCommandLayout())
end

return module
replicatedfirst/Chickynoid/Shared/Simulation/MathUtils.lua
--!native
local MathUtils = {}

local THETA = math.pi * 2
function MathUtils:AngleAbs(angle)
while angle < 0 do
angle = angle + THETA
end
while angle > THETA do
angle = angle - THETA
end
return angle
end

function MathUtils:AngleShortest(a0, a1)
local d1 = self:AngleAbs(a1 - a0)
local d2 = -self:AngleAbs(a0 - a1)
return math.abs(d1) > math.abs(d2) and d2 or d1
end

function MathUtils:LerpAngle(a0, a1, frac)
return a0 + self:AngleShortest(a0, a1) * frac
end

function MathUtils:PlayerVecToAngle(vec)
return math.atan2(-vec.z, vec.x) - math.rad(90)
end

function MathUtils:PlayerAngleToVec(angle)
return Vector3.new(math.sin(angle), 0, math.cos(angle))
end

--dt variable decay function
function MathUtils:Friction(val, fric, deltaTime)
return (1 / (1 + (deltaTime / fric))) * val
end

function MathUtils:VelocityFriction(vel, fric, deltaTime)
local speed = vel.magnitude
speed = self:Friction(speed, fric, deltaTime)

if speed < 0.001 then
return Vector3.new(0, 0, 0)
end
vel = vel.unit * speed

return vel
end

function MathUtils:FlatVec(vec)
return Vector3.new(vec.x, 0, vec.z)
end


--Redirects velocity
function MathUtils:GroundAccelerate(wishDir, wishSpeed, accel, velocity, dt)
--Cap velocity
local speed = velocity.Magnitude
if speed > wishSpeed then
velocity = velocity.unit * wishSpeed
end

local wishVel = wishDir * wishSpeed
local pushDir = wishVel - velocity

local pushLen = pushDir.magnitude

local canPush = accel * dt * wishSpeed

if canPush > pushLen then
canPush = pushLen
end
if canPush < 0.00001 then
return velocity
end
return velocity + (canPush * pushDir.Unit)
end

function MathUtils:Accelerate(wishDir, wishSpeed, accel, velocity, dt)
local speed = velocity.magnitude

local currentSpeed = velocity:Dot(wishDir)
local addSpeed = wishSpeed - currentSpeed

if addSpeed <= 0 then
return velocity
end

local accelSpeed = accel * dt * wishSpeed
if accelSpeed > addSpeed then
accelSpeed = addSpeed
end

velocity = velocity + (accelSpeed * wishDir)

--if we're already going over max speed, don't go any faster than that
--Or you'll get strafe jumping!
if speed > wishSpeed and velocity.magnitude > speed then
velocity = velocity.unit * speed
end
return velocity
end

function MathUtils:CapVelocity(velocity, maxSpeed)
local mag = velocity.magnitude
mag = math.min(mag, maxSpeed)
if mag > 0.01 then
return velocity.Unit * mag
end
return Vector3.zero
end


function MathUtils:ClipVelocity(input, normal, overbounce)
local backoff = input:Dot(normal)

if backoff < 0 then
backoff = backoff * overbounce
else
backoff = backoff / overbounce
end

local changex = normal.x * backoff
local changey = normal.y * backoff
local changez = normal.z * backoff

return Vector3.new(input.x - changex, input.y - changey, input.z - changez)
end

--Smoothlerp for lua. "Zeno would be proud!"
--Use it in a feedback loop over multiple frames to converge A towards B, in a deltaTime safe way
--eg: cameraPos = SmoothLerp(cameraPos, target, 0.5, deltaTime)
--Handles numbers and types that implement Lerp like Vector3 and CFrame

function MathUtils:SmoothLerp(variableA, variableB, fraction, deltaTime)

local f = 1.0 - math.pow(1.0 - fraction, deltaTime)

if (type(variableA) == "number") then
return ((1-f) * variableA) + (variableB * f)
end

variableA = Vector3.new(variableA.X, variableB.Y, variableA.Z)
return variableA:Lerp(variableB, f)
end

-- Ulldren's edits
function MathUtils:Reflect(velocity: Vector3, normal: Vector3)
return -2 * velocity:Dot(normal) * normal + velocity
end

function MathUtils:LinearToAngular(v0: Vector3, normal: Vector3, r: number)
return (normal*r):Cross(v0) / (r * r)
end

function MathUtils:ClampToBoundary(position: Vector3, boundaryPos: Vector3, boundarySize: Vector3)
return Vector3.new(
math.clamp(position.X, boundaryPos.X - boundarySize.X/2, boundaryPos.X + boundarySize.X/2),
math.clamp(position.Y, boundaryPos.Y - boundarySize.Y/2, boundaryPos.Y + boundarySize.Y/2),
math.clamp(position.Z, boundaryPos.Z - boundarySize.Z/2, boundaryPos.Z + boundarySize.Z/2)
)
end

function MathUtils:NumberLerp(a: number, b: number, t: number)
return a + (b - a) * t
end

function MathUtils:Vector2Lerp(a: Vector2, b: Vector2, t: number)
return a:Lerp(b, t)
end

function MathUtils:Vector3Lerp(a: Vector3, b: Vector3, t: number)
return a:Lerp(b, t)
end

return MathUtils
replicatedfirst/Chickynoid/Shared/Simulation/MinkowskiSumInstance.lua
--!native
local Root = script.Parent.Parent
local Vendor = Root.Vendor

local TrianglePart = require(Vendor.TrianglePart)
local QuickHull2 = require(Vendor.QuickHull2)

local module = {}
module.meshCache = {}
module.timeSpentTracing = 0

local corners = {
Vector3.new(0.5, 0.5, 0.5),
Vector3.new(0.5, 0.5, -0.5),
Vector3.new(-0.5, 0.5, 0.5),
Vector3.new(-0.5, 0.5, -0.5),
Vector3.new(0.5, -0.5, 0.5),
Vector3.new(0.5, -0.5, -0.5),
Vector3.new(-0.5, -0.5, 0.5),
Vector3.new(-0.5, -0.5, -0.5),
}

local wedge = {
Vector3.new( 0.5,-0.5, -0.5),
Vector3.new(-0.5,-0.5, -0.5),
Vector3.new( 0.5,-0.5, 0.5),
Vector3.new(-0.5,-0.5, 0.5),
Vector3.new( 0.5, 0.5, 0.5),
Vector3.new(-0.5, 0.5, 0.5),
}

local cornerWedge = {
Vector3.new( 0.5, 0.5,-0.5),
Vector3.new( 0.5,-0.5, 0.5),
Vector3.new(-0.5,-0.5, 0.5),
Vector3.new( 0.5,-0.5,-0.5),
Vector3.new(-0.5,-0.5,-0.5),
}


local function IsUnique(list, normal, d)
local EPS = 0.01
local normalTol = 0.95

for _, rec in pairs(list) do
if (math.abs(rec.ed - d) < EPS and rec.n:Dot(normal) > normalTol) then
return false
end
end
return true
end

local function IsUniquePoint(list, point)
local EPS = 0.001

for _, src in pairs(list) do
if (src-point).magnitude < EPS then
return false
end
end
return true
end


local function IsUniqueTri(list, normal, d)
local EPS = 0.001

for _, rec in pairs(list) do
if math.abs(rec[5] - d) > EPS then
continue
end
if rec[4]:Dot(normal) < 1 - EPS then
continue
end
return false --got a match
end
return true
end

-- local function IsUniquePoints(list, p)
-- local EPS = 0.001

-- for _, point in pairs(list) do
-- if (point - p).magnitude < EPS then
-- return false
-- end
-- end
-- return true
-- end

local function IsValidTri(tri, origin)

local normal = (tri[1] - tri[2]):Cross(tri[1] - tri[3]).unit
local pos = (tri[1]+tri[2]+tri[3]) / 3
local vec = (pos-origin).unit

if (vec:Dot(normal) > 0.75 ) then
return true
end
return false
end


--Generates a very accurate minkowski summed convex hull from an instance and player box size
--Forces you to pass in the part cframe manually, because we need to snap it for client/server precision reasons
--Not a speedy thing to do!
function module:GetPlanesForInstance(instance, playerSize, cframe, basePlaneNum, showDebugParentPart)

if (true and instance:IsA("MeshPart") and instance.Anchored == true) then
if (instance.CollisionFidelity == Enum.CollisionFidelity.Hull or instance.CollisionFidelity == Enum.CollisionFidelity.PreciseConvexDecomposition) then
return module:GetPlanesForInstanceMeshPart(instance, playerSize, cframe, basePlaneNum, showDebugParentPart)
end
end

--generate worldspace points
local points = self:GeneratePointsForInstance(instance, playerSize, cframe)
if showDebugParentPart ~= nil then
self:VisualizePlanesForPoints(points, showDebugParentPart)
end

return self:GetPlanesForPoints(points, basePlaneNum)
end

function module:GetPlanesForPointsExpanded(points, playerSize, basePlaneNum, debugPart)
local newPoints = {}
for _, point in pairs(points) do
for _, v in pairs(corners) do
table.insert(newPoints, point + (v * playerSize))
end
end

if debugPart ~= nil then
self:VisualizePlanesForPoints(newPoints, debugPart)
end
return self:GetPlanesForPoints(newPoints, basePlaneNum)
end

--Same thing but for worldspace point cloud
function module:VisualizePlanesForPoints(points, debugPart)


--Run quickhull

local r = QuickHull2:GenerateHull(points)
local recs = {}

self:VisualizeTriangles(r, Vector3.zero)
end


function module:VisualizeTriangles(tris, offset)

local color = Color3.fromHSV(math.random(), 0.5, 1)

--Add triangles
for _, tri in pairs(tris) do
local a, b = TrianglePart:Triangle(tri[1] + offset, tri[2] + offset, tri[3] + offset)
a.Parent = game.Workspace.Terrain
a.Color = color
b.Parent = game.Workspace.Terrain
b.Color = color


--Add a normal
local normal = (tri[1] - tri[2]):Cross(tri[1] - tri[3]).unit
local pos = (tri[1]+tri[2]+tri[3]) / 3
local instance = Instance.new("Part")
instance.Size =Vector3.new(0.1,0.1,2)
instance.CFrame = CFrame.lookAt( pos + (normal), pos + (normal*2))
instance.Parent = game.Workspace.Terrain
instance.CanCollide = false
instance.Anchored = true

end
end

--Same thing but for worldspace point cloud
function module:GetPlanesForPoints(points, basePlaneNum)
--Run quickhull
local r = QuickHull2:GenerateHull(points)
local recs = {}

--Generate unique planes in n+d format
if (r ~= nil) then
for _, tri in pairs(r) do
local normal = (tri[1] - tri[2]):Cross(tri[1] - tri[3]).unit
local ed = tri[1]:Dot(normal) --expanded distance
basePlaneNum += 1

if IsUnique(recs, normal, ed) then
table.insert(recs, {
n = normal,
ed = ed, --expanded
planeNum = basePlaneNum,
})
end
end
end

return recs, basePlaneNum
end

--Same thing but for worldspace point cloud
function module:GetPlanePointForPoints(points)
--Run quickhull
local r = QuickHull2:GenerateHull(points)
local recs = {}

--Generate unique planes in n+d format
if (r ~= nil) then
for _, tri in pairs(r) do
local normal = (tri[1] - tri[2]):Cross(tri[1] - tri[3]).unit
local ed = tri[1]:Dot(normal) --expanded distance

if IsUniqueTri(recs, normal, ed) then
table.insert(recs, { tri[1],tri[2], tri[3], normal, ed })
end
end
end

return recs
end

function module:PointInsideHull(hullRecord,point)

for _, p in pairs(hullRecord) do
local dist = point:Dot(p.n) - p.ed

if (dist > 0) then
return true
end
end
return false
end

function module:GeneratePointsForInstance(instance, playerSize, cframe)

local points = {}


local srcPoints = corners

if (instance:IsA("Part")) then
srcPoints = corners
elseif (instance:IsA("WedgePart")) then
srcPoints = wedge
elseif (instance:IsA("CornerWedgePart")) then
srcPoints = cornerWedge
end

for _, v in pairs(srcPoints) do
local part_corner = cframe * CFrame.new(v * instance.Size)

for _, c in pairs(corners) do
table.insert(points, (part_corner + c * playerSize).Position)
end
end


return points
end

--As they say - if it's stupid and it works...
--So the idea here is we scale a mesh down to 1,1,1
--Fire a grid of rays at it
--And return this array of points to build a convex hull out of
function module:GetRaytraceInstancePoints(instance, cframe)

local start = tick()
local points = self.meshCache[instance.MeshId]

if (points == nil) then
print("Raytracing ", instance.Name, instance.MeshId)
points = {}
local step = 0.2

local function AddUnique(list, point)
for key,value in pairs(list) do
if ((value-point).magnitude < 0.1) then
return
end
end
table.insert(list, point)
end

local meshCopy = instance:Clone()
meshCopy.CFrame = CFrame.new(Vector3.new(0,0,0))
meshCopy.Size = Vector3.one
meshCopy.Parent = game.Workspace
meshCopy.CanQuery = true

local raycastParam = RaycastParams.new()
raycastParam.FilterType = Enum.RaycastFilterType.Include
raycastParam.FilterDescendantsInstances = { meshCopy }

for x=-0.5, 0.5, step do
for y=-0.5, 0.5, step do
local pos = Vector3.new(x,-2,y)
local dir = Vector3.new(0,4,0)
local result = game.Workspace:Raycast(pos, dir, raycastParam)
if (result) then
AddUnique(points, result.Position)

--we hit something, trace from the other side too
local pos = Vector3.new(x,2,y)
local dir = Vector3.new(0,-4,0)
local result = game.Workspace:Raycast(pos, dir, raycastParam)
if (result) then
AddUnique(points, result.Position)
end
end
end
end

for x=-0.5, 0.5, step do
for y=-0.5, 0.5, step do
local pos = Vector3.new(-2,x,y)
local dir = Vector3.new(4,0,0)
local result = game.Workspace:Raycast(pos, dir, raycastParam)
if (result) then
AddUnique(points, result.Position)

--we hit something, trace from the other side too
local pos = Vector3.new(2,x,y)
local dir = Vector3.new(-4,0,0)
local result = game.Workspace:Raycast(pos, dir, raycastParam)
if (result) then
AddUnique(points, result.Position)
end
end
end
end

for x=-0.5, 0.5, step do
for y=-0.5, 0.5, step do
local pos = Vector3.new(x,y,-2)
local dir = Vector3.new(0,0,4)
local result = game.Workspace:Raycast(pos, dir, raycastParam)
if (result) then
AddUnique(points, result.Position)

--we hit something, trace from the other side too
local pos = Vector3.new(x,y,2)
local dir = Vector3.new(0,0,-4)
local result = game.Workspace:Raycast(pos, dir, raycastParam)
if (result) then
AddUnique(points, result.Position)
end
end
end
end

meshCopy:Destroy()



--Optimize the points down
local hull = QuickHull2:GenerateHull(points)

if (hull ~= nil) then
local recs = {}

for _, tri in pairs(hull) do
local normal = (tri[1] - tri[2]):Cross(tri[1] - tri[3]).unit
local ed = tri[1]:Dot(normal) --expanded distance

if IsUnique(recs, normal, ed) then
table.insert(recs, {
n = normal,
ed = ed, --expanded
tri = tri
})
end
end
local points = {}
for key,record in pairs(recs) do

if (IsUniquePoint(points, record.tri[1])) then
table.insert(points,record.tri[1])
end
if (IsUniquePoint(points, record.tri[2])) then
table.insert(points,record.tri[2])
end
if (IsUniquePoint(points, record.tri[3])) then
table.insert(points,record.tri[3])
end
end
self.meshCache[instance.MeshId] = points
else
self.meshCache[instance.MeshId] = {}
end

end


local finals = {}
local size = instance.Size

for key,point in pairs(points) do
local p = cframe:PointToWorldSpace(point * size)
table.insert(finals, p)
end

if (false and game["Run Service"]:IsClient()) then
for key,point in pairs(finals) do

local debugInstance = Instance.new("Part")
debugInstance.Parent = game.Workspace
debugInstance.Anchored = true
debugInstance.Size = Vector3.new(1,1,1)
debugInstance.Position = point
debugInstance.Shape = Enum.PartType.Ball
debugInstance.Color = Color3.new(0,1,0)
end

self:VisualizePlanesForPoints(finals, game.Workspace)
end

self.timeSpentTracing += tick() - start

return finals
end

function module:GetPlanesForInstanceMeshPart(instance, playerSize, cframe, basePlaneNum, showDebugParentPart)

local sourcePoints = self:GetRaytraceInstancePoints(instance, cframe)
local points = {}

for _, point in pairs(sourcePoints) do
for _, c in pairs(corners) do
table.insert(points, point + (c * playerSize))
end
end

local r = QuickHull2:GenerateHull(points)

local recs = {}

--Generate unique planes in n+d format
if (r == nil) then
return nil, basePlaneNum
end
for _, tri in pairs(r) do
local normal = (tri[1] - tri[2]):Cross(tri[1] - tri[3]).unit
local ed = tri[1]:Dot(normal) --expanded distance
basePlaneNum += 1

if IsUnique(recs, normal, ed) then
table.insert(recs, {
n = normal,
ed = ed, --expanded
planeNum = basePlaneNum,
})
end
end

if showDebugParentPart ~= nil and game["Run Service"]:IsClient() then
--self:VisualizeTriangles(r, Vector3.zero)
end

return recs, basePlaneNum
end

return module
replicatedfirst/Chickynoid/Shared/Simulation/Quaternion.lua
--!strict
--[[
Source: https://github.com/probablytukars/LuaQuaternion
[MIT LICENSE]
]]

local Quaternion = {
_type = "Quaternion",
_TO_STRING_CHAR = nil
}

type CachedProperties = {
unit: Quaternion?,
magnitude: number?
}

type t_quaternion = {
-- Constructors

new: (qX: number?, qY: number?, qZ: number?, qW: number?) -> Quaternion,
fromAxisAngle: (axis: Vector3, angle: number) -> Quaternion,
fromAxisAngleFast: (axis: Vector3, angle: number) -> Quaternion,
fromEulerVector: (eulerVector: Vector3) -> Quaternion,
fromCFrame: (cframe: CFrame) -> Quaternion,
fromCFrameFast: (cframe: CFrame) -> Quaternion,
fromMatrix: (vX: Vector3, vY: Vector3, vZ: Vector3?) -> Quaternion,
fromMatrixFast: (vX: Vector3, vY: Vector3, vZ: Vector3?) -> Quaternion,
lookAt: (from: Vector3, lookAt: Vector3, up: Vector3?) -> Quaternion,
fromEulerAnglesXYZ: (rx: number, ry: number, rz: number) -> Quaternion,
Angles: (rx: number, ry: number, rz: number) -> Quaternion,
fromEulerAnglesYXZ: (rx: number, ry: number, rz: number) -> Quaternion,
fromOrientation: (rx: number, ry: number, rz: number) -> Quaternion,
fromEulerAngles: (
rx: number, ry: number, rz: number, rotationOrder: Enum.RotationOrder?
) -> Quaternion,
fromVector: (vector: Vector3, W: number?) -> Quaternion,
RandomQuaternion: (seed: number) -> () -> Quaternion,


-- Constants

identity: Quaternion,
zero: Quaternion,


-- Properties

X: number,
Y: number,
Z: number,
W: number,
_cached: CachedProperties,
Unit: Quaternion,
Magnitude: number,


-- Math operations

Add: (q0: Quaternion, q1: Quaternion) -> Quaternion,
Sub: (q0: Quaternion, q1: Quaternion) -> Quaternion,
Mul: (q0: Quaternion, q1: Quaternion) -> Quaternion,
Scale: (q0: Quaternion, scale: number) -> Quaternion,
MulCFrameR: (q0: Quaternion, cframe: CFrame) -> CFrame,
MulCFrameL: (q0: Quaternion, cframe: CFrame) -> CFrame,
RotateVector: (q0: Quaternion, vector: Vector3) -> Vector3,
CombineImaginary: (q0: Quaternion, vector: Vector3) -> Quaternion,
Div: (op0: Quaternion, op1: Quaternion) -> Quaternion,
ScaleInv: (q0: Quaternion, scale: number) -> Quaternion,
Unm: (q0: Quaternion) -> Quaternion,
Pow: (q0: Quaternion, power: number) -> Quaternion,
Len: (q0: Quaternion) -> number,
Lt: (q0: Quaternion, q1: Quaternion) -> boolean,
Le: (q0: Quaternion, q1: Quaternion) -> boolean,
Eq: (q0: Quaternion, q1: Quaternion) -> boolean,


-- Methods

Exp: (q0: Quaternion) -> Quaternion,
ExpMap: (q0: Quaternion, q1: Quaternion) -> Quaternion,
ExpMapSym: (q0: Quaternion, q1: Quaternion) -> Quaternion,
Log: (q0: Quaternion) -> Quaternion,
LogMap: (q0: Quaternion, q1: Quaternion) -> Quaternion,
LogMapSym: (q0: Quaternion, q1: Quaternion) -> Quaternion,
Length: (q0: Quaternion) -> number,
LengthSquared: (q0: Quaternion) -> number,
Hypot: (q0: Quaternion) -> number,
Normalize: (q0: Quaternion) -> Quaternion,
IsUnit: (q0: Quaternion, epsilon: number) -> boolean,
Dot: (q0: Quaternion, q1: Quaternion) -> number,
Conjugate: (q0: Quaternion) -> Quaternion,
Inverse: (q0: Quaternion) -> Quaternion,
Negate: (q0: Quaternion) -> Quaternion,
Difference: (q0: Quaternion, q1: Quaternion) -> Quaternion,
Distance: (q0: Quaternion, q1: Quaternion) -> number,
DistanceSym: (q0: Quaternion, q1: Quaternion) -> number,
DistanceChord: (q0: Quaternion, q1: Quaternion) -> number,
DistanceAbs: (q0: Quaternion, q1: Quaternion) -> number,
Slerp: (q0: Quaternion, q1: Quaternion, alpha: number) -> Quaternion,
IdentitySlerp: (q1: Quaternion, alpha: number) -> Quaternion,
SlerpFunction: (q0: Quaternion, q1: Quaternion)
-> (alpha: number) -> Quaternion,
Intermediates: (
q0: Quaternion, q1: Quaternion, n: number, includeEndpoints: boolean?
) -> {Quaternion},
Derivative: (q0: Quaternion, rate: Vector3) -> Quaternion,
Integrate: (q0: Quaternion, rate: Vector3, timestep: number) -> Quaternion,
AngularVelocity: (q0: Quaternion, q1: Quaternion, timestep: number) -> Vector3,
MinimalRotation: (q0: Quaternion, q1: Quaternion) -> Quaternion,
ApproxEq: (q0: Quaternion, q1: Quaternion, epsilon: number) -> boolean,
IsNaN: (q0: Quaternion) -> boolean,


-- Deconstructors

ToCFrame: (q0: Quaternion, position: Vector3?) -> CFrame,
ToAxisAngle: (q0: Quaternion) -> (Vector3, number),
ToEulerVector: (q0: Quaternion) -> Vector3,
ToEulerAnglesXYZ: (q0: Quaternion) -> (number, number, number),
ToEulerAnglesYXZ: (q0: Quaternion) -> (number, number, number),
ToOrientation: (q0: Quaternion) -> (number, number, number),
ToEulerAngles: (
q0: Quaternion, rotationOrder: Enum.RotationOrder?
) -> (number, number, number),
ToMatrix: (q0: Quaternion) ->
(
number, number, number,
number, number, number,
number, number, number
) ,
ToMatrixVectors: (q0: Quaternion) -> (Vector3, Vector3, Vector3),
Vector: (q0: Quaternion) -> Vector3,
Scalar: (q0: Quaternion) -> number,
Imaginary: (q0: Quaternion) -> Quaternion,
GetComponents: (q0: Quaternion) -> (number, number, number, number),
components: (q0: Quaternion) -> (number, number, number, number),
ToString: (q0: Quaternion, decimalPlaces: number?) -> string,
}

export type Quaternion = typeof(setmetatable({} :: t_quaternion, Quaternion))

local EPSILON = 5e-7

--[=[
@class Quaternion
@grouporder ["Constructors", "Methods", "Deconstructors", "Math Operations"]

Quaternions represent rotations in 3D space.

It is important to note that quaternions have double cover, meaning
that `q0` and `-q0` encode the same rotation.


This class is **immutable** which means once a quaternion has been
created, its components cannot be changed. All methods create new
quaternions.


Some helpful tips for rearranging quaternion formulas:

When rearraning a formula to solve for a specific value, it will involve
using inverses and mulitplication, the order is very important as
multiplication is non-commutative.


For example, given `a b = c`


To solve for `b`,

Multiply both sides by `a^-1` on the left sides of the equation:

`a^-1 a b = a^-1 c`

This simplifies to:

`b = a^-1 c`.


To solve for `a`,

Multiply both sides by `b^-1` on the right sides of the equation:

`a b b^-1 = c b^-1`

This simplifies to:

`a = c b^-1`.


Another important rule to remember is the following:

`a^-1 b^-1 = (b a)^-1`.

`a b^-1 = (b^-1 a)^-1`.

In general, this means flip the order, inverse each individual,
and then inverse them as a group.


Given the formula `a b c d = e` where `a`,`b`,`c`,`d`, and `e` are
quaternions.

Using rules from earlier:


Solving for `a`:

`a = e d^-1 c^-1 b^-1`

Or more commonly written as:

`a = e (b c d)^-1`


Solving for `b`:

`b = a^-1 e (c d)^-1`


Solving for `c`:

`c = (a b)^-1 e d`


Solving for `d`:

`d = (a b c)^-1 e`


Quaternion multiplication is associative, so the following is equivalent:

`(a b) c = a (b c)`


Using these rules, you should be able to rearrange any formula to solve
for the desired quaternion.


Note that often you might not want the exact quaternion but instead the
negated version (which represents the same rotation), as that rotation
would actually end up being shorter than the exact quaternion.

In this case `a:Inverse() \* b` can be written as `a:Difference(b)`.
]=]
--[=[
@prop X number
--]=]
--[=[
@prop Y number
--]=]
--[=[
@prop Z number
--]=]
--[=[
@prop W number
--]=]
--[=[
@prop Unit Quaternion

A quaternion with unit length. Result is cached.
]=]
--[=[
@prop Magnitude number

Returns the magnitude of the quaternion.
Result is cached.
]=]
--[=[
@prop identity Quaternion

An identity quaternion with no rotation.
This is constant and should be accessed through the Quaternion class
rather than an individual Quaternion object.
]=]
--[=[
@prop zero Quaternion

The zero quaternion, this does not represent any
rotation as it has a magnitude of zero. This is a constant and should
be accessed through the Quaternion class rather than an individual
Quaternion object.
]=]


-- Internal functions for type checking and throwing errors

local function GetType(obj: any): string
if obj == nil then return "nil" end
local objMetatable = getmetatable(obj)
if type(objMetatable) == "table" and objMetatable._type ~= nil then
return tostring(objMetatable._type)
else
return typeof(obj)
end
end

local function _safeUnit(vector: Vector3, default: Vector3): Vector3
if vector.Magnitude > EPSILON then
return vector.Unit
else
return default
end
end

--[=[
@function
@group Constructors

Creates a new quaternion with X, Y, Z, W values, where the
X, Y, Z are the imaginary components and the W component is the real
component.
]=]
@native
local function new(qX: number?, qY: number?, qZ: number?, qW: number?): Quaternion
local self = setmetatable({
X = qX or 0,
Y = qY or 0,
Z = qZ or 0,
W = qW or 1,
_cached = {}
} :: t_quaternion, Quaternion)

table.freeze(self)

return self
end

Quaternion.new = new
Quaternion.identity = new(0, 0, 0, 1)
Quaternion.zero = new(0, 0, 0, 0)

-- Private Methods

local function _Orthonormalize(rightVector: Vector3, upVector: Vector3, backVector: Vector3): (Vector3, Vector3, Vector3)
local xBasis = _safeUnit(rightVector, Vector3.xAxis)
local _upVector = _safeUnit(upVector, Vector3.yAxis)

local zBasis = xBasis:Cross(_upVector)
if zBasis.Magnitude > EPSILON then
zBasis = zBasis.Unit
else
zBasis = xBasis:Cross(Vector3.yAxis)
if zBasis.Magnitude > EPSILON then
zBasis = zBasis.Unit
else
zBasis = Vector3.xAxis
end
end

local yBasis = zBasis:Cross(xBasis).Unit
if zBasis:Dot(backVector) < 0 then
zBasis = -zBasis
end
return xBasis, yBasis, zBasis
end


local function _fromOrthonormalizedMatrix(vX: Vector3, vY: Vector3, vZ: Vector3): Quaternion
local m00, m10, m20 = vX.X, vX.Y, vX.Z
local m01, m11, m21 = vY.X, vY.Y, vY.Z
local m02, m12, m22 = vZ.X, vZ.Y, vZ.Z

local trace = m00 + m11 + m22

local qX, qY, qZ, qW

if trace > 0 then
local S = math.sqrt(trace + 1) * 2
qX = (m21 - m12) / S;
qY = (m02 - m20) / S;
qZ = (m10 - m01) / S;
qW = 0.25 * S;
elseif m00 > m11 and m00 > m22 then
local S = math.sqrt(1 + m00 - m11 - m22) * 2
qX = 0.25 * S;
qY = (m01 + m10) / S;
qZ = (m02 + m20) / S;
qW = (m21 - m12) / S;
elseif m11 > m22 then
local S = math.sqrt(1 + m11 - m00 - m22) * 2
qX = (m01 + m10) / S;
qY = 0.25 * S;
qZ = (m12 + m21) / S;
qW = (m02 - m20) / S;
else
local S = math.sqrt(1 + m22 - m00 - m11) * 2
qX = (m02 + m20) / S;
qY = (m12 + m21) / S;
qZ = 0.25 * S;
qW = (m10 - m01) / S;
end

return new(qX, qY, qZ, qW)
end

-- Public Methods

--[=[
@function
@group Constructors

Creates a quaternion from an axis and angle.
Will always return a valid unit quaternion. Normalizes axis.
]=]
local function fromAxisAngle(axis: Vector3, angle: number): Quaternion
axis = _safeUnit(axis, Vector3.xAxis)

local ha = angle / 2
local sha = math.sin(ha)

local X = sha * axis.X
local Y = sha * axis.Y
local Z = sha * axis.Z
local W = math.cos(ha)

return new(X, Y, Z, W)
end

Quaternion.fromAxisAngle = fromAxisAngle

--[=[
@function
@group Constructors

Creates a quaternion from an axis and angle.
Assumes axis is already normalized.
]=]
local function fromAxisAngleFast(axis: Vector3, angle: number): Quaternion
local ha = angle / 2
local sha = math.sin(ha)
local shaxis = axis * sha
local X = shaxis.X
local Y = shaxis.Y
local Z = shaxis.Z
local W = math.cos(ha)

return new(X, Y, Z, W)
end


Quaternion.fromAxisAngleFast = fromAxisAngleFast

--[=[
@function
@group Constructors

Creates a quaternion from a euler (compact axis-angles) vector.
Will always return a valid unit quaternion.
]=]
local function fromEulerVector(eulerVector: Vector3): Quaternion
local angle = eulerVector.Magnitude
if angle > 0 then
local axis = eulerVector / angle
return fromAxisAngleFast(axis, angle)
else
return Quaternion.identity
end
end

Quaternion.fromEulerVector = fromEulerVector


--[=[
@function
@group Constructors

Creates a quaternion from a CFrame.
Will always return a valid unit quaternion.
]=]
local function fromCFrame(cframe: CFrame): Quaternion
local axis, angle = cframe:Orthonormalize():ToAxisAngle()
return fromAxisAngle(axis, angle)
end

Quaternion.fromCFrame = fromCFrame

--[=[
@function
@group Constructors

Creates a quaternion from a CFrame.
Assumes that the CFrame has already been orthonormalized, otherwise its
possible that this will return a quaternion with NaN values.
]=]
local function fromCFrameFast(cframe: CFrame): Quaternion
local axis, angle = cframe:ToAxisAngle()
return fromAxisAngleFast(axis, angle)
end

Quaternion.fromCFrameFast = fromCFrameFast

--[=[
@function
@group Constructors

Creates a quaternion from three vectors describing a rotation
matrix.
Will always return a valid unit quaternion.
]=]
local function fromMatrix(vX: Vector3, vY: Vector3, vZ: Vector3?): Quaternion
local vXo, vYo = vX, vY
local vZo = if vZ then vZ else vX:Cross(vY)
return _fromOrthonormalizedMatrix(_Orthonormalize(vXo, vYo, vZo))
end

Quaternion.fromMatrix = fromMatrix

--[=[
@function
@group Constructors

Creates a quaternion from three vectors describing a rotation
matrix.
Assumes the matrix is already orthonormalized, if not orthonormalized, it
can return NaN or invalid Quaternion.
]=]
local function fromMatrixFast(vX: Vector3, vY: Vector3, vZ: Vector3?): Quaternion
local vXo, vYo = vX.Unit, vY.Unit
local vZo = if vZ then vZ else vX:Cross(vY).Unit
return _fromOrthonormalizedMatrix(vXo, vYo, vZo)
end

Quaternion.fromMatrixFast = fromMatrixFast

--[=[
@function
@group Constructors

Returns a quaternion looking at Vector3 `lookAt`, from the
Vector3 `from`, with an optional upVector Vector3 `up`. Maintains
the same functionality as Roblox's `CFrame.lookAt`.
Will always return a valid unit quaternion.
]=]
local function lookAt(from: Vector3, lookAt: Vector3, up: Vector3?): Quaternion
local lookVector = _safeUnit(lookAt - from, Vector3.zAxis)
local _up = _safeUnit(up or Vector3.yAxis, Vector3.yAxis)

local rightVector = lookVector:Cross(_up)
if rightVector.Magnitude > EPSILON then
local rightVector = rightVector.Unit
local upVector = rightVector:Cross(lookVector).Unit
return _fromOrthonormalizedMatrix(rightVector, upVector, -lookVector)
end

local selectVector = lookVector:Cross(Vector3.xAxis)
if selectVector.Magnitude > EPSILON then
local rightVector = selectVector.Unit
local upVector = rightVector:Cross(lookVector).Unit
return _fromOrthonormalizedMatrix(rightVector, upVector, -lookVector)
end

local upVector = Vector3.zAxis:Cross(lookVector)
local upSign = upVector:Dot(Vector3.yAxis)
upVector *= upSign
local rightVector = lookVector:Cross(upVector)
return _fromOrthonormalizedMatrix(rightVector, upVector, -lookVector)
end

Quaternion.lookAt = lookAt

--[=[
@function
@group Constructors

Creates a quaternion using angles `rx`, `ry`, and `rz` in
radians. Rotation is applied in Z, Y, X order.
]=]
local function fromEulerAnglesXYZ(rx: number, ry: number, rz: number): Quaternion
local xCos = math.cos(rx / 2)
local xSin = math.sin(rx / 2)
local yCos = math.cos(ry / 2)
local ySin = math.sin(ry / 2)
local zCos = math.cos(rz / 2)
local zSin = math.sin(rz / 2)

local xSinyCos = xSin * yCos
local xCosySin = xCos * ySin
local xCosyCos = xCos * yCos
local xSinySin = xSin * ySin

local qX = xSinyCos * zCos + xCosySin * zSin
local qY = xCosySin * zCos - xSinyCos * zSin
local qZ = xCosyCos * zSin + xSinySin * zCos
local qW = xCosyCos * zCos - xSinySin * zSin

return new(qX, qY, qZ, qW)
end

Quaternion.fromEulerAnglesXYZ = fromEulerAnglesXYZ


--[=[
@function
@group Constructors
@alias fromEulerAnglesXYZ
]=]
Quaternion.Angles = fromEulerAnglesXYZ

--[=[
@function
@group Constructors

Creates a quaternion using angles `rx`, `ry`, and `rz` in
radians. Rotation is applied in Z, X, Y order.
]=]
local function fromEulerAnglesYXZ(rx: number, ry: number, rz: number): Quaternion
local xCos = math.cos(rx / 2)
local xSin = math.sin(rx / 2)
local yCos = math.cos(ry / 2)
local ySin = math.sin(ry / 2)
local zCos = math.cos(rz / 2)
local zSin = math.sin(rz / 2)

local xSinyCos = xSin * yCos
local xCosySin = xCos * ySin
local xCosyCos = xCos * yCos
local xSinySin = xSin * ySin

local qX = xSinyCos * zCos + xCosySin * zSin
local qY = xCosySin * zCos - xSinyCos * zSin
local qZ = xCosyCos * zSin - xSinySin * zCos
local qW = xCosyCos * zCos + xSinySin * zSin

return new(qX, qY, qZ, qW)
end



Quaternion.fromEulerAnglesYXZ = fromEulerAnglesYXZ


--[=[
@function
@group Constructors
@alias fromEulerAnglesYXZ
]=]
Quaternion.fromOrientation = fromEulerAnglesYXZ

--[=[
@function
@group Constructors

Creates a quaternion using angles `rx`, `ry`, and `rz` in
radians. Rotation is applied in the order given by `rotationOrder`.
]=]
local function fromEulerAngles(rx: number, ry: number, rz: number, rotationOrder: Enum.RotationOrder?): Quaternion
local l_rotationOrder = rotationOrder or Enum.RotationOrder.XYZ

local xCos = math.cos(rx / 2)
local yCos = math.cos(ry / 2)
local zCos = math.cos(rz / 2)

local xSin = math.sin(rx / 2)
local ySin = math.sin(ry / 2)
local zSin = math.sin(rz / 2)

local xSinyCos = xSin * yCos
local xCosySin = xCos * ySin
local xCosyCos = xCos * yCos
local xSinySin = xSin * ySin

local qX, qY, qZ, qW

local order = l_rotationOrder.Name
if order == "XYZ" then
qX = xSinyCos * zCos + xCosySin * zSin;
qY = xCosySin * zCos - xSinyCos * zSin;
qZ = xCosyCos * zSin + xSinySin * zCos;
qW = xCosyCos * zCos - xSinySin * zSin;
elseif order == "YXZ" then
qX = xSinyCos * zCos + xCosySin * zSin;
qY = xCosySin * zCos - xSinyCos * zSin;
qZ = xCosyCos * zSin - xSinySin * zCos;
qW = xCosyCos * zCos + xSinySin * zSin;
elseif order == "ZXY" then
qX = xSinyCos * zCos - xCosySin * zSin;
qY = xCosySin * zCos + xSinyCos * zSin;
qZ = xCosyCos * zSin + xSinySin * zCos;
qW = xCosyCos * zCos - xSinySin * zSin;
elseif order == "ZYX" then
qX = xSinyCos * zCos - xCosySin * zSin;
qY = xCosySin * zCos + xSinyCos * zSin;
qZ = xCosyCos * zSin - xSinySin * zCos;
qW = xCosyCos * zCos + xSinySin * zSin;
elseif order == "YZX" then
qX = xSinyCos * zCos + xCosySin * zSin;
qY = xCosySin * zCos + xSinyCos * zSin;
qZ = xCosyCos * zSin - xSinySin * zCos;
qW = xCosyCos * zCos - xSinySin * zSin;
elseif order == "XZY" then
qX = xSinyCos * zCos - xCosySin * zSin;
qY = xCosySin * zCos - xSinyCos * zSin;
qZ = xCosyCos * zSin + xSinySin * zCos;
qW = xCosyCos * zCos + xSinySin * zSin;
end

return new(qX, qY, qZ, qW)
end

Quaternion.fromEulerAngles = fromEulerAngles

--[=[
@function
@group Constructors

Creates a quaternion from a vector, where the imaginary
components of the quaternion are set by the vector components.
Can also set the `W` component with the second argument, which defaults
to zero.
]=]
local function fromVector(vector: Vector3, W: number?): Quaternion
return new(vector.X, vector.Y, vector.Z, W or 0)
end

Quaternion.fromVector = fromVector

--[=[
@function
@group Constructors

Returns a function which will return a new random quaternion every
time that it is called.
]=]
local function RandomQuaternion(seed: number): () -> Quaternion
local seed = seed or 1
local random = Random.new(seed)

local tau = 2 * math.pi
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
return function()
local u = random:NextNumber(0, 1)
local v = random:NextNumber(0, 1)
local w = random:NextNumber(0, 1)

local omu = 1 - u
local squ = sqrt(u)
local sqmu = sqrt(omu)

local tpv = tau * v
local tpw = tau * w

local qX = sqmu * sin(tpv)
local qY = sqmu * cos(tpv)
local qZ = squ * sin(tpw)
local qW = squ * cos(tpw)
return new(qX, qY, qZ, qW)

end
end

Quaternion.RandomQuaternion = RandomQuaternion

--[=[
@operator add
@operand1 Quaternion
@operand2 Quaternion
@return Quaternion
@group Math Operations

Adds the the second quaternion to the first quaternion using
component-wise addition.
]=]

--[=[
@operator sub
@operand1 Quaternion
@operand2 Quaternion
@return Quaternion
@group Math Operations

Subtracts the the second quaternion from the first quaternion
using component-wise subtraction.
]=]

--[=[
@operator mul
@operand1 Quaternion
@operand2 Quaternion
@return Quaternion
@group Math Operations

Multiplies the first quaternion by the second quaternion using
the Hamilton product. The order of multiplication is crucial, and in
nearly all cases, (where q0 and q1 are quaternions) q0 \* q1 is not
equal to q1 \* q0.
]=]

--[=[
@operator div
@operand1 Quaternion
@operand2 Quaternion
@return Quaternion
@group Math Operations

Multiplies the the first quaternion by the inverse of the
second quaternion. Equivalent to `q0 * q1:Inverse()`.
]=]

--[=[
@operator unm
@operand1 Quaternion
@return Quaternion
@group Math Operations

Negates each component of the Quaternion.
]=]

--[=[
@operator pow
@operand1 Quaternion
@operand2 number
@return Quaternion
@group Math Operations

Raises quaternion by the given power. Has the effect of
scaling a rotation around the identity quaternion. For example,
if a quaternion `q0` represents a rotation of 60 degrees around the
X axis, doing `q0 ^ 0.5` will return a quaternion with a rotation of
of 30 degrees around the X axis. Doing `q0 ^ 2` will return a rotation
of 120 degrees around the X axis. The power can be any real number.
]=]

--[=[
@operator eq
@operand1 Quaternion
@operand2 Quaternion
@return Quaternion
@group Math Operations

Checks if each component of one quaternion is exactly equal
to the components of another quaternion.
]=]

--[=[
@operator lt
@operand1 Quaternion
@operand2 Quaternion
@return boolean
@group Math Operations

Returns true if the first Quaternion has a smaller length than the
second Quaternion.
]=]

--[=[
@operator le
@operand1 Quaternion
@operand2 Quaternion
@return boolean
@group Math Operations

Returns true if the first quaternion has a smaller or equal
length than the second Quaternion.
]=]

--[=[
@operator gt
@operand1 Quaternion
@operand2 Quaternion
@return boolean
@group Math Operations

Returns true if the first quaternion has a greater length than the second Quaternion.
]=]

--[=[
@operator ge
@operand1 Quaternion
@operand2 Quaternion
@return boolean
@group Math Operations

Returns true if the first quaternion has a greater or equal length than the second Quaternion.
]=]

--[=[
@operator len
@operand1 Quaternion
@return number
@group Math Operations

The length of the quaternion.
]=]
@native
local function Add(q0: Quaternion, q1: Quaternion): Quaternion
return new(q0.X + q1.X, q0.Y + q1.Y, q0.Z + q1.Z, q0.W + q1.W)
end

Quaternion.__add = Add
Quaternion.Add = Add

local function Sub(q0: Quaternion, q1: Quaternion): Quaternion
return new(q0.X - q1.X, q0.Y - q1.Y, q0.Z - q1.Z, q0.W - q1.W)
end

Quaternion.__sub = Sub
Quaternion.Sub = Sub

@native
local function Mul(q0: Quaternion, q1: Quaternion): Quaternion
local q0X, q0Y, q0Z, q0W = q0.X, q0.Y, q0.Z, q0.W
local q1X, q1Y, q1Z, q1W = q1.X, q1.Y, q1.Z, q1.W
return new(
q0W * q1X + q0X * q1W + q0Y * q1Z - q0Z * q1Y,
q0W * q1Y - q0X * q1Z + q0Y * q1W + q0Z * q1X,
q0W * q1Z + q0X * q1Y - q0Y * q1X + q0Z * q1W,
q0W * q1W - q0X * q1X - q0Y * q1Y - q0Z * q1Z
)
end

Quaternion.__mul = Mul
Quaternion.Mul = Mul


--[=[
@function
@group Math Operations

Scale the components of the quaternion by a number.
]=]
@native
local function Scale(q0: Quaternion, scale: number): Quaternion
return new(q0.X * scale, q0.Y * scale, q0.Z * scale, q0.W * scale)
end

Quaternion.Scale = Scale

--[=[
@function
@group Math Operations

Multiply a quaternion with a cframe, in the order quaternion * cframe.
]=]
local function MulCFrameR(q0: Quaternion, cframe: CFrame): CFrame
return q0:ToCFrame() * cframe
end

Quaternion.MulCFrameR = MulCFrameR

--[=[
@function
@group Math Operations

Multiply a quaternion with a cframe, in the order cframe * quaternion.
]=]
local function MulCFrameL(q0: Quaternion, cframe: CFrame): CFrame
return cframe * q0:ToCFrame()
end

Quaternion.MulCFrameL = MulCFrameL

--[=[
@function
@group Math Operations

Rotate a vector by a quaternion.
]=]
local function RotateVector(q0: Quaternion, vector: Vector3): Vector3
return Mul(q0 * fromVector(vector), q0:Conjugate()):Vector()
end

Quaternion.RotateVector = RotateVector

--[=[
@function
@group Math Operations

Constructs a quaternion from the vector with the vector as imaginary components, and multiplies with the given
quaternion.
]=]
local function CombineImaginary(q0: Quaternion, vector: Vector3): Quaternion
return Mul(fromVector(vector), q0)
end

Quaternion.CombineImaginary = CombineImaginary


local function Div(op0: Quaternion, op1: Quaternion): Quaternion
return Mul(op0, op1:Inverse())
end

Quaternion.__div = Div
Quaternion.Div = Div


--[=[
@function
@group Math Operations

Divide each component of the quaternion by some scale value.
]=]
@native
local function ScaleInv(q0: Quaternion, scale: number): Quaternion
return new(q0.X / scale, q0.Y / scale, q0.Z / scale, q0.W / scale)
end

Quaternion.ScaleInv = ScaleInv


local function unm(q0: Quaternion): Quaternion
return new(-q0.X, -q0.Y, -q0.Z, -q0.W)
end

Quaternion.__unm = unm
Quaternion.Unm = unm
Quaternion.Negate = unm

local function Pow(q0: Quaternion, number: number)
if number == -1 then return q0:Inverse() end

local aW, aX, aY, aZ = q0.W, q0.X, q0.Y, q0.Z

local im = aX*aX + aY*aY + aZ*aZ
local aMag = math.sqrt(aW*aW + im)
local aIm = math.sqrt(im)
local cMag = aMag ^ number

if aIm <= EPSILON * aMag then
return Quaternion.new(0, 0, 0, cMag)
end

local rx = aX / aIm
local ry = aY / aIm
local rz = aZ / aIm

local cAng = number * math.atan2(aIm, aW)
local cCos = math.cos(cAng)
local cSin = math.sin(cAng)
local cMagcSin = cMag * cSin

local cW = cMag*cCos
local cX = cMagcSin * rx
local cY = cMagcSin * ry
local cZ = cMagcSin * rz

return Quaternion.new(cX, cY, cZ, cW)
end

Quaternion.__pow = Pow
Quaternion.Pow = Pow

local function eq(q0: Quaternion, q1: Quaternion): boolean
local op0type = GetType(q0)
local op1type = GetType(q1)

if (op0type == "Quaternion" and op1type == op0type) then
return q0.X == q1.X and q0.Y == q1.Y and q0.Z == q1.Z and q0.W == q1.W
else
return false
end
end

Quaternion.__eq = eq
Quaternion.Eq = eq

local function lt(q0: Quaternion, q1:Quaternion)
local q0l = q0:Length()
local q1l = q1:Length()

return q0l < q1l
end

Quaternion.__lt = lt
Quaternion.Lt = lt

local function le(q0: Quaternion, q1:Quaternion)
local q0l = q0:Length()
local q1l = q1:Length()

return q0l <= q1l
end

Quaternion.__le = le
Quaternion.Le = le

--[=[
@method
@group Methods

The exponential of a quaternion.
]=]
local function Exp(q0: Quaternion): Quaternion
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W

local m = math.exp(qW)
local vv = qX*qX + qY*qY + qZ*qZ
if vv > 0 then
local v = vv ^ 0.5
local s = m * math.sin(v) / v
return new(qX * s, qY * s, qZ * s, m * math.cos(v))
else
return new(0, 0, 0, m)
end
end

Quaternion.Exp = Exp

--[=[
@method
@group Methods

The exponential map on the Riemannian manifold described by
the quaternion space.
]=]
local function ExpMap(q0: Quaternion, q1: Quaternion): Quaternion
return Mul(q0, Exp(q1))
end

Quaternion.ExpMap = ExpMap

--[=[
@method
@group Methods

The symmetrized exponential map on the quaternion Riemannian
manifold.
]=]
local function ExpMapSym(q0: Quaternion, q1: Quaternion): Quaternion
local sqrtQ = Pow(q0, 0.5)
return Mul(Mul(sqrtQ, Exp(q1)), sqrtQ)
end

Quaternion.ExpMapSym = ExpMapSym

--[=[
@method
@group Methods

The logarithm of a quaternion.
]=]
local function Log(q0: Quaternion): Quaternion
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W

local vv = qX*qX + qY*qY + qZ*qZ
local mm = qW*qW + vv
if mm > 0 then
if vv > 0 then
local m = mm ^ 0.5
local s = math.acos(qW / m) / (vv ^ 0.5)
return new(qX * s, qY * s, qZ * s, math.log(m))
else
return new(0, 0, 0, math.log(mm)/2)
end
else
return new(0, 0, 0, -math.huge)
end
end

Quaternion.Log = Log

--[=[
@method
@group Methods

The logarithm map on the quaternion Riemannian manifold.
]=]
local function LogMap(q0: Quaternion, q1: Quaternion): Quaternion
return Log(Mul(q0:Inverse(), q1))
end

Quaternion.LogMap = LogMap

--[=[
@method
@group Methods

The symmetrized logarithm map on the quaternion Riemannian
manifold.
]=]
local function LogMapSym(q0: Quaternion, q1: Quaternion): Quaternion
local invSqrtq0 = Pow(q0, -0.5)
return Log(Mul(Mul(invSqrtq0, q1), invSqrtq0))
end

Quaternion.LogMapSym = LogMapSym

--[=[
@method
@group Methods

The length of the quaternion.
]=]
@native
local function Length(q0: Quaternion): number
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
return (qX * qX + qY * qY + qZ * qZ + qW * qW) ^ 0.5
end

Quaternion.Length = Length
Quaternion.__len = Length

--[=[
@method
@group Methods

The sum of the squares length of the quaternion.
]=]
local function LengthSquared(q0: Quaternion): number
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
return qX * qX + qY * qY + qZ * qZ + qW * qW
end

Quaternion.LengthSquared = LengthSquared

--[=[
@method
@group Methods

A numerically stable way to get the length of a quaternion.
]=]
local function Hypot(q0: Quaternion): number
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
local maxComp = math.max(qX, qY, qZ, qW)
if maxComp > 0 then
local normalizedQ = ScaleInv(q0, maxComp)
local length = Length(normalizedQ) * maxComp

return length
end
return 0
end

Quaternion.Hypot = Hypot

--[=[
@method
@group Methods

The normalized quaternion with a length of one. Passing the
zero Quaternion into this will return the identity Quaternion.
]=]
@native
local function Normalize(q0: Quaternion): Quaternion
local length = Length(q0)
if length > 0 then
return ScaleInv(q0, length)
else
return Quaternion.identity
end
end

Quaternion.Normalize = Normalize

--[=[
@method
@group Methods

Returns true if the given quaternion has a length close to
one, within 1 +- epsilon range.
]=]
local function IsUnit(q0: Quaternion, epsilon: number): boolean
local l_epsilon = epsilon or EPSILON
return math.abs(1 - Length(q0)) < l_epsilon
end

Quaternion.IsUnit = IsUnit

--[=[
@method
@group Deconstructors

Returns a CFrame with the same rotation as the given
quaternion. If a position is supplied, the CFrame will have that
position. The given quaternion will be normalized.
]=]
local function ToCFrame(q0: Quaternion, position: Vector3?): CFrame
q0 = Normalize(q0)

local vectorPos = position or Vector3.new()
return CFrame.new(
vectorPos.X, vectorPos.Y, vectorPos.Z,
q0.X, q0.Y, q0.Z, q0.W
)
end

Quaternion.ToCFrame = ToCFrame

--[=[
@method
@group Methods

Returns the dot product between two quaternions.
]=]
@native
local function Dot(q0: Quaternion, q1: Quaternion): number
return q0.X * q1.X + q0.Y * q1.Y + q0.Z * q1.Z + q0.W * q1.W
end

Quaternion.Dot = Dot

--[=[
@method
@group Methods

The conjugate of the Quaternion. The imaginary components are
negated.
]=]
local function Conjugate(q0: Quaternion): Quaternion
return new(-q0.X, -q0.Y, -q0.Z, q0.W)
end

Quaternion.Conjugate = Conjugate

--[=[
@method
@group Methods

The inverse of the Quaternion. Mulitplying a quaternion by
its own inverse will result in the identity Quaternion.
]=]
local function Inverse(q0: Quaternion): Quaternion
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
local length = qX * qX + qY * qY + qZ * qZ + qW * qW

return new(-q0.X / length, -q0.Y/ length, -q0.Z / length, q0.W / length)
end

Quaternion.Inverse = Inverse

--[=[
@method
@group Methods

Returns the negated version of the given quaternion.
]=]
local function Negate(q0: Quaternion): Quaternion
return new(-q0.X, -q0.Y, -q0.Z, -q0.W)
end

Quaternion.Negate = Negate
Quaternion.__unm = Negate

--[=[
@method
@group Methods

Returns the quaternion which has the minimal rotation to get
from `q0` to `q1` using the double cover property of quaternions.
If `q2 = q0:Difference(q1)`, then `q0 \* q2 = q1`, or `q0 \* q2 = -q1`
(the same rotation). If you don't want to take advantage of the double
cover property, then you can do `q2 = q0 \* q1:Inverse()`, where
`q0 \* q2 = q1` all of the time.
]=]
local function Difference(q0: Quaternion, q1: Quaternion): Quaternion
if Dot(q0, q1) < 0 then
q0 = unm(q0)
end
return Mul(Inverse(q0), q1)
end

Quaternion.Difference = Difference

--[=[
@method
@group Methods

Returns the intrinsic geodesic distance between two
quaternions. Output will be in the range 0-2pi for unit quaternions.
]=]
local function Distance(q0: Quaternion, q1: Quaternion): number
return Length(LogMap(q0, q1)) * 2
end

Quaternion.Distance = Distance

--[=[
@method
@group Methods

Returns the symmetrized geodesic distance between two
quaternions. Output will be in the range 0-pi for unit quaternions.
]=]
local function DistanceSym(q0: Quaternion, q1: Quaternion): number
return Length(Log(Difference(q0, q1))) * 2
end

Quaternion.DistanceSym = DistanceSym

--[=[
@method
@group Methods

Returns the chord distance of the shortest path/arc between
two quaternions.
]=]
local function DistanceChord(q0: Quaternion, q1: Quaternion): number
return math.sin(DistanceSym(q0, q1) / 2) * 2
end

Quaternion.DistanceChord = DistanceChord

--[=[
@method
@group Methods

Returns the absolute distance between two
quaternions, accounting for sign ambiguity.
]=]
local function DistanceAbs(q0: Quaternion, q1: Quaternion): number
local q0minusq1 = Sub(q0, q1)
local q0plusq1 = Add(q0, q1)
local dMinus = Length(q0minusq1)
local dPlus = Length(q0plusq1)

if dMinus < dPlus then
return dMinus
end
return dPlus
end

Quaternion.DistanceAbs = DistanceAbs

--[=[
@method
@group Methods

Returns a quaternion along the great circle arc between two
existing quaternion endpoints lying on the unit radius hypersphere.
Alpha can be any real number.
]=]
@native
local function Slerp(q0: Quaternion, q1: Quaternion, alpha: number): Quaternion
q0 = Normalize(q0)
q1 = Normalize(q1)

local dot = Dot(q0, q1)

if dot < 0 then
q0 = unm(q0)
dot = -dot
end

if dot >= 1 then
return Normalize(Add(q0, Scale(Sub(q1, q0), alpha)))
end

local theta0 = math.acos(dot)
local sinTheta0 = math.sin(theta0)

local theta = theta0 * alpha
local sinTheta = math.sin(theta)

local s0 = math.cos(theta) - dot * sinTheta / sinTheta0
local s1 = sinTheta / sinTheta0
return Normalize(Add(Scale(q0, s0), Scale(q1, s1)))
end

Quaternion.Slerp = Slerp

--[=[
@method
@group Methods

Returns a quaternion along the great circle arc between the
identity quaternion and the given quaternion lying on the unit radius
hypersphere. Alpha can be any real number.

Equivalent to `Quaternion.identity:Slerp(q0, alpha)` but much faster.
]=]
local function IdentitySlerp(q0: Quaternion, alpha: number): Quaternion
if (q0.W < 0) then
return -Pow(-q0, alpha)
end
return Pow(q0, alpha)
end

Quaternion.IdentitySlerp = IdentitySlerp

--[=[
@method
@group Methods

Returns a function which can be used to calculate a quaternion
along the great circle arc between the two given quaternions lying on
the unit radius hypersphere. For example:
`slerp = q0:SlerpFunction(q1)`, and then `q2 = slerp(alpha)`.
]=]
local function SlerpFunction(q0: Quaternion, q1: Quaternion): (alpha: number) -> Quaternion
q0 = Normalize(q0)
q1 = Normalize(q1)

local dot = Dot(q0, q1)

if dot < 0 then
q0 = unm(q0)
dot = -dot
end

if dot >= 1 then
local subQ = Sub(q1, q0)

return function(alpha: number)
return Normalize(Add(q0, Scale(subQ, alpha)))
end
end

local theta0 = math.acos(dot)
local sinTheta0 = math.sin(theta0)

return function(alpha: number)
local theta = theta0 * alpha
local sinTheta = math.sin(theta)

local s0 = math.cos(theta) - dot * sinTheta / sinTheta0
local s1 = sinTheta / sinTheta0
return Normalize(Add(Scale(q0, s0), Scale(q1, s1)))
end
end

Quaternion.SlerpFunction = SlerpFunction

--[=[
@method
@group Methods

Generates an iterable sequence of n evenly spaces quaternion
rotations between any two existing quaternion endpoints lying on the
unit radius hypersphere.
]=]
local function Intermediates(q0: Quaternion, q1: Quaternion, n: number, includeEndpoints: boolean?): {Quaternion}
includeEndpoints = includeEndpoints or false

local stepSize = 1 / (n + 1)
local steps =
if includeEndpoints
then {q0}
else {}

local slerpFunc = SlerpFunction(q0, q1)

for i = 1, n do
local qi = slerpFunc(stepSize * i)
table.insert(steps, qi)
end

if includeEndpoints then
table.insert(steps, q1)
end

return steps
end

Quaternion.Intermediates = Intermediates

--[=[
@method
@group Methods

The instantaneous quaternion derivative representing a
quaternion rotating at a 3D rate vector `rate`.
]=]
local function Derivative(q0: Quaternion, rate: Vector3): Quaternion
return Mul(Scale(q0, 0.5), fromVector(rate))
end

Quaternion.Derivative = Derivative

--[=[
@method
@group Methods

Advance a time varying Quaternion to its value at a time
`timestep` in the future. The solution is closed form given the
assumption that rate is constant over the interval of length
`timestep`.
]=]
local function Integrate(q0: Quaternion, rate: Vector3, timestep: number): Quaternion
q0 = Normalize(q0)

local rotationVector = (rate * timestep)
local rotationMag = rotationVector.Magnitude
if rotationMag > 0 then
local axis = rotationVector / rotationMag
local angle = rotationMag
local q1 = fromAxisAngle(axis, angle)
return Normalize(Mul(q0, q1))
else
return q0
end
end

Quaternion.Integrate = Integrate

--[=[
@method
@group Methods

Get the euler (compact axis-angles) vector which represents the angular
velocity from `q0` to `q1` over the given `timestep`.
If `timestep` is zero or negative, the zero vector is returned.
]=]
local function AngularVelocity(q0: Quaternion, q1: Quaternion, timestep: number): Vector3
if timestep > 0 then
local q2 = q0:Difference(q1)
return q2:ToEulerVector() / timestep
end
return Vector3.new()
end

Quaternion.AngularVelocity = AngularVelocity

--[=[
@method
@group Methods

This function returns the Quaternion which represents the shortest
arc rotation between `q0` and `q1` upVector (in matrix form).
To get the new quaternion which has the same upVector as `q1`, multiply
as `q2 * q0`, where `q2` is the derived Quaternion from this method.
]=]
local function MinimalRotation(q0: Quaternion, q1: Quaternion): Quaternion
local _, sup, _ = q0:ToMatrixVectors()
local _, tup, _ = q1:ToMatrixVectors()
local rotationAxis = sup:Cross(tup)
local rotationAngle = math.atan2(rotationAxis.Magnitude, sup:Dot(tup))
return fromAxisAngle(rotationAxis, rotationAngle)
end

Quaternion.MinimalRotation = MinimalRotation

--[=[
@method
@group Methods

Returns true if the symmetrized geodesic distance is less
than `epsilon`.
]=]
local function ApproxEq(q0: Quaternion, q1: Quaternion, epsilon: number?): boolean
local l_epsilon = epsilon or EPSILON
return DistanceSym(q0, q1) < l_epsilon
end

Quaternion.ApproxEq = ApproxEq

--[=[
@method
@group Methods

Returns true if any component of the quaternion is NaN.
]=]
local function IsNaN(q0: Quaternion): boolean
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
return qX ~= qX or qY ~= qY or qZ ~= qZ or qW ~= qW
end

Quaternion.IsNaN = IsNaN

local function _toRotationMatrix(q0: Quaternion)
q0 = Normalize(q0)
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W

local sqX = qX * qX
local sqY = qY * qY
local sqZ = qZ * qZ
local sqW = qW * qW

local m00 = sqX - sqY - sqZ + sqW
local m11 = -sqX + sqY - sqZ + sqW
local m22 = -sqX - sqY + sqZ + sqW

local qXqY = qX * qY
local qZqW = qZ * qW
local m10 = 2 * (qXqY + qZqW)
local m01 = 2 * (qXqY - qZqW)

local qXqZ = qX * qZ
local qYqW = qY * qW
local m20 = 2 * (qXqZ - qYqW)
local m02 = 2 * (qXqZ + qYqW)

local qYqZ = qY * qZ
local qXqW = qX * qW
local m21 = 2 * (qYqZ + qXqW)
local m12 = 2 * (qYqZ - qXqW)

return m00, m01, m02, m10, m11, m12, m20, m21, m22
end

--[=[
@method
@group Deconstructors

Converts quaternion to axis angle representation. Quaternion
is normalized before conversion.
]=]
local function ToAxisAngle(q0: Quaternion): (Vector3, number)
q0 = Normalize(q0)
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W

local angle = 2 * math.acos(qW);
local s = math.sqrt(1 - qW * qW);

if s < EPSILON then
return Vector3.new(qX, qY, qZ), angle
else
return Vector3.new(qX / s, qY / s, qZ / s), angle
end
end

Quaternion.ToAxisAngle = ToAxisAngle

--[=[
@method
@group Deconstructors

Converts quaternion to euler (compact axis-angles) vector representation.
Quaternion is normalized before conversion.
]=]
local function ToEulerVector(q0: Quaternion): Vector3
q0 = Normalize(q0)
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W

local angle = 2 * math.acos(qW);
local s = math.sqrt(1 - qW * qW);

if s < EPSILON then
return Vector3.new(qX, qY, qZ) * angle
else
return Vector3.new(qX / s, qY / s, qZ / s) * angle
end
end

Quaternion.ToEulerVector = ToEulerVector

--[=[
@method
@group Deconstructors

Converts quaternion to it's matrix representation in
`m00, m01, m02, m10, m11, m12, m20, m21, m22` order as a tuple.
Quaternion is normalized before conversion.
]=]
local function ToMatrix(q0: Quaternion): (number, number, number, number, number, number,number, number, number)
return _toRotationMatrix(q0)
end

Quaternion.ToMatrix = ToMatrix

--[=[
@method
@group Deconstructors

Converts quaternion to it's matrix representation with three
vectors, each representation a column of the rotation matrix.
Quaternion is normalized before conversion.
Returns RightVector, UpVector, BackVector.
]=]
local function ToMatrixVectors(q0: Quaternion): (Vector3, Vector3, Vector3)
local m00, m01, m02, m10, m11, m12, m20, m21, m22 = _toRotationMatrix(q0)

--Right, Up, Back
return Vector3.new(m00, m10, m20), Vector3.new(m01, m11, m21), Vector3.new(m02, m12, m22)
end

Quaternion.ToMatrixVectors = ToMatrixVectors

--[=[
@method
@group Deconstructors

Returns the imaginary components of the quaternion as a Vector.
]=]
local function Vector(q0: Quaternion): Vector3
return Vector3.new(q0.X, q0.Y, q0.Z)
end

Quaternion.Vector = Vector

--[=[
@method
@group Deconstructors

Returns a new quaternion with the same real component as
the given quaternion, but with the imaginary components set to zero.
]=]
local function Real(q0: Quaternion): Quaternion
return new(0, 0, 0, q0.W)
end

Quaternion.Real = Real

--[=[
@method
@group Deconstructors

Returns a new quaternion with the same imaginary components as
the given quaternion, but with the real component set to zero.
]=]
local function Imaginary(q0: Quaternion): Quaternion
return new(q0.X, q0.Y, q0.Z, 0)
end

Quaternion.Imaginary = Imaginary

--[=[
@method
@group Deconstructors

Converts the quaternion to euler angles representation in
X, Y, Z order. Quaternion is normalized before conversion.
]=]
local function ToEulerAnglesXYZ(q0: Quaternion): (number, number, number)
q0 = Normalize(q0)
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
local rX, rY, rZ

local test = qY * qW + qX * qZ
if math.abs(test) > 0.5 - EPSILON then
local sign = test > 0 and 1 or -1
rX = sign * 2 * math.atan2(qZ, qW)
rY = sign * math.pi / 2
rZ = 0
return rX, rY, rZ
end

local sqy = qY * qY
rX = math.atan2(2 * (qX * qW - qY * qZ), 1 - 2 * (qX * qX + sqy))
rY = math.asin(2 * test)
rZ = math.atan2(2 * (qZ * qW - qX * qY), 1 - 2 * (qZ * qZ + sqy))

return rX, rY, rZ
end

local function ToEulerAnglesXZY(q0: Quaternion): (number, number, number)
q0 = Normalize(q0)
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
local rX, rY, rZ

local test = qZ * qW - qX * qY
if math.abs(test) > 0.5 - EPSILON then
local sign = test >= 0 and 1 or -1
rX = sign * 2 * -math.atan2(qY, qW)
rY = 0
rZ = sign * math.pi / 2
return rX, rY, rZ
end

local sqz = qZ * qZ
rX = math.atan2(2 * (qX * qW + qY * qZ), 1 - 2 * (qX * qX + sqz))
rY = math.atan2(2 * (qX * qZ + qY * qW), 1 - 2 * (qY * qY + sqz))
rZ = math.asin(2 * test)

return rX, rY, rZ
end

--[=[
@method
@group Deconstructors

Converts the quaternion to euler angles representation in
Y, X, Z order. Quaternion is normalized before conversion.
]=]
local function ToEulerAnglesYXZ(q0: Quaternion): (number, number, number)
q0 = Normalize(q0)
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
local rX, rY, rZ

local test = qX * qW - qY * qZ
if math.abs(test) > 0.5 - EPSILON then
local sign = test >= 0 and 1 or -1
rX = sign * math.pi / 2
rY = sign * 2 * -math.atan2(qZ, qW)
rZ = 0
return rX, rY, rZ
end

local sqx = qX * qX
rX = math.asin(2 * test)
rY = math.atan2(2 * (qX * qZ + qY * qW), 1 - 2 * (qY * qY + sqx))
rZ = math.atan2(2 * (qX * qY + qZ * qW), 1 - 2 * (qZ * qZ + sqx))

return rX, rY, rZ
end

local function ToEulerAnglesYZX(q0: Quaternion): (number, number, number)
q0 = Normalize(q0)
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
local rX, rY, rZ

local test = qZ * qW + qX * qY
if math.abs(test) > 0.5 - EPSILON then
local sign = test >= 0 and 1 or -1
rX = 0
rY = sign * 2 * math.atan2(qX, qW)
rZ = sign * math.pi / 2
return rX, rY, rZ
end

local sqz = qZ * qZ
rX = math.atan2(2 * (qX * qW - qY * qZ), 1 - 2 * (qX * qX + sqz))
rY = math.atan2(2 * (qY * qW - qX * qZ), 1 - 2 * (qY * qY + sqz))
rZ = math.asin(2 * test)

return rX, rY, rZ
end

local function ToEulerAnglesZXY(q0: Quaternion): (number, number, number)
q0 = Normalize(q0)
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
local rX, rY, rZ

local test = qX * qW + qY * qZ
if math.abs(test) > 0.5 - EPSILON then
local sign = test >= 0 and 1 or -1
rX = sign * math.pi / 2
rY = 0
rZ = sign * 2 * math.atan2(qY, qW)
return rX, rY, rZ
end

local sqx = qX * qX
rX = math.asin(2 * test)
rY = math.atan2(2 * (qY * qW - qX * qZ), 1 - 2 * (qY * qY + sqx))
rZ = math.atan2(2 * (qZ * qW - qX * qY), 1 - 2 * (qZ * qZ + sqx))

return rX, rY, rZ
end

local function ToEulerAnglesZYX(q0: Quaternion): (number, number, number)
q0 = Normalize(q0)
local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
local rX, rY, rZ

local test = qY * qW - qX * qZ
if math.abs(test) > 0.5 - EPSILON then
local sign = test >= 0 and 1 or -1
rX = 0
rY = sign * math.pi / 2
rZ = sign * 2 * -math.atan2(qX, qW)
return rX, rY, rZ
end

local sqy = qY * qY
rX = math.atan2(2 * (qX * qW + qY * qZ), 1 - 2 * (qX * qX + sqy))
rY = math.asin(2 * test)
rZ = math.atan2(2 * (qX * qY + qZ * qW), 1 - 2 * (qZ * qZ + sqy))

return rX, rY, rZ
end

local TO_EULER_ANGLES_MAP = {
["XYZ"] = ToEulerAnglesXYZ,
["XZY"] = ToEulerAnglesXZY,
["YZX"] = ToEulerAnglesYZX,
["YXZ"] = ToEulerAnglesYXZ,
["ZXY"] = ToEulerAnglesZXY,
["ZYX"] = ToEulerAnglesZYX
}

--[=[
@method
@group Deconstructors

Converts the quaternion to euler angles representation.
Quaternion is normalized before conversion. The result is dependent
on the given `rotationOrder`. Defaults to "XYZ".
]=]
local function ToEulerAngles(q0: Quaternion, rotationOrder: Enum.RotationOrder?): (number, number, number)
local l_rotationOrder = rotationOrder or Enum.RotationOrder.XYZ
return TO_EULER_ANGLES_MAP[l_rotationOrder.Name](q0)
end


Quaternion.ToEulerAngles = ToEulerAngles
Quaternion.ToEulerAnglesXYZ = ToEulerAnglesXYZ
Quaternion.ToEulerAnglesYXZ = ToEulerAnglesYXZ

--[=[
@method
@group Deconstructors
@alias ToEulerAnglesYXZ
]=]
Quaternion.ToOrientation = ToEulerAnglesYXZ

--[=[
@method
@group Deconstructors

Returns the components of the quaternion in X, Y, Z, W order.
]=]
local function GetComponents(q0: Quaternion): (number, number, number, number)
return q0.X, q0.Y, q0.Z, q0.W
end

Quaternion.GetComponents = GetComponents

--[=[
@method
@group Deconstructors
@alias GetComponents
]=]
Quaternion.components = GetComponents

local function round(number: number, decimalPlaces: number?): string
if decimalPlaces then
decimalPlaces = math.max(0, decimalPlaces)
local formatString = string.format("%%.%df", decimalPlaces)
local roundedNumberString = string.format(formatString, number)
return roundedNumberString
end
return tostring(number)
end

--[=[
@method
@group Deconstructors

Converts quaternion to string representation. If
`decimalPlaces` is given, each component in the string will be rounded
to the given places.
]=]
local function ToString(q0: Quaternion, decimalPlaces: number?): string
if Quaternion._TO_STRING_CHAR then
decimalPlaces = Quaternion._TO_STRING_CHAR
end
return
round(q0.X, decimalPlaces) .. ", "
.. round(q0.Y, decimalPlaces) .. ", "
.. round(q0.Z, decimalPlaces) .. ", "
.. round(q0.W, decimalPlaces)
end

Quaternion.__tostring = ToString
Quaternion.ToString = ToString


function Quaternion.__index(q0, key)
local functionIndex = Quaternion[key]
if functionIndex then
return functionIndex
end
local lower = string.lower(key)
local cached = rawget(q0, "_cached")
if lower == "unit" then
if not cached.unit then
local norm = Normalize(q0)
cached.unit = norm
return norm
end
return cached.unit
elseif lower == "magnitude" then
if not cached.magnitude then
local mag = Length(q0)
cached.magnitude = mag
return mag
end
return cached.magnitude
end
return nil
end

function Quaternion.__newindex(_, key)
error(tostring(key) .. " cannot be assigned to")
end

table.freeze(Quaternion)

return Quaternion

--[==[
Sources:
[1]: https://github.com/KieranWynn/pyquaternion/blob/master/pyquaternion
/quaternion.py
[2]: https://www.euclideanspace.com/maths/geometry/rotations/conversions
[3]: https://github.com/Quenty/NevermoreEngine/blob/main/src/qframe/src
/Shared/QFrame.lua
[4]: https://github.com/Quenty/NevermoreEngine/blob/main/src/quaternion/src
/Shared/Quaternion.lua
[5]: https://www.andre-gaschler.com/rotationconverter/
[6]: https://stackoverflow.com/questions/31600717
[7]: https://stackoverflow.com/questions/1171849/
--]==]
replicatedfirst/Chickynoid/Shared/Simulation/Simulation.lua
--!native
--[=[
@class Simulation
Simulation handles physics for characters on both the client and server.
]=]

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()

local Simulation = {}
Simulation.__index = Simulation

local CollisionModule = require(script.Parent.CollisionModule)
local CharacterData = require(script.Parent.CharacterData)
local MathUtils = require(script.Parent.MathUtils)
local Enums = require(script.Parent.Parent.Enums)
local DeltaTable = require(script.Parent.Parent.Vendor.DeltaTable)
local Quaternion = require(script.Parent.Quaternion)

local Lib = require(ReplicatedStorage.Lib)
local GameInfo = require(ReplicatedFirst.GameInfo)

local localPlayer = Players.LocalPlayer


function Simulation.new(userId)
local self = setmetatable({}, Simulation)

self.userId = userId

self.moveStates = {}
self.moveStateNames = {}
self.executionOrder = {}

self.state = {}

self.state.pos = Vector3.new(0, 5, 0)
self.state.vel = Vector3.new(0, 0, 0)
self.state.pushDir = Vector2.new(0, 0)

self.state.jump = 0
self.state.angle = 0
self.state.targetAngle = 0
self.state.stepUp = 0
self.state.inAir = 0
self.state.jumpThrust = 0
self.state.pushing = 0 --External flag comes from server (ungh >_<')
self.state.moveState = 0 --Walking!

self.characterData = CharacterData.new()

self.lastGround = nil --Used for platform stand on servers only

--Roblox Humanoid defaultish
self.constants = {}
self.constants.maxSpeed = 16 --Units per second
self.constants.accel = 40 --Units per second per second
self.constants.jumpPunch = 60 --Raw velocity, just barely enough to climb on a 7 unit tall block
self.constants.turnSpeedFrac = 8 --seems about right? Very fast.
self.constants.maxGroundSlope = 0.05 --about 89o
self.constants.jumpThrustPower = 0 --No variable height jumping
self.constants.jumpThrustDecay = 0
self.constants.gravity = -196.2
self.constants.crashLandBehavior = Enums.Crashland.FULL_BHOP_FORWARD

self.constants.pushSpeed = 16 --set this lower than maxspeed if you want stuff to feel heavy
self.constants.stepSize = 2.2 --How high you can step over something
self.constants.gravity = -196.2

self.constants.slippery = 0
self.constants.maxStamina = GameInfo.MAX_STAMINA


self.custom = {}
self.custom.ballQuaternion = Quaternion.new(1, 0, 0, 1)
self.custom.leanAngle = Vector2.new(0, 0)
self.custom.animDir = 0

return self
end

function Simulation:GetMoveState()
local record = self.moveStates[self.state.moveState]
return record
end

function Simulation:RegisterMoveState(name, updateState, alwaysThink, startState, endState, alwaysThinkLate, executionOrder)
local index = 0
for key,value in pairs(self.moveStateNames) do
index+=1
end
self.moveStateNames[name] = index

local record = {}
record.name = name
record.updateState = updateState
record.alwaysThink = alwaysThink
record.startState = startState
record.endState = endState
record.alwaysThinkLate = alwaysThinkLate
record.executionOrder = executionOrder or 0
self.moveStates[index] = record

self.executionOrder = {}
for key,value in self.moveStates do
table.insert(self.executionOrder, value)
end

table.sort(self.executionOrder, function(a,b)
return a.executionOrder < b.executionOrder
end)
end

function Simulation:SetMoveState(name)

local index = self.moveStateNames[name]
if (index) then

local record = self.moveStates[index]
if (record) then

local prevRecord = self.moveStates[self.state.moveState]
if (prevRecord and prevRecord.endState) then
prevRecord.endState(self, name)
end
if (record.startState) then
if (prevRecord) then
record.startState(self, prevRecord.name)
else
record.startState(self, "")
end
end
self.state.moveState = index
end
end
end


-- It is very important that this method rely only on whats in the cmd object
-- and no other client or server state can "leak" into here
-- or the server and client state will get out of sync.
local privateServerInfo: Configuration = ReplicatedStorage:WaitForChild("PrivateServerInfo")

local runningSound: Sound
function Simulation:DoPlayerAttributeChecks()
local player = Players:GetPlayerByUserId(self.userId)
if player == nil then
return
end
self.player = player
self.completeFreeze = player:GetAttribute("CompleteFreeze")
self.isGoalkeeper = player:GetAttribute("Position") == "Goalkeeper"

self.playerInGame = Lib.playerInGameOrPaused(player)
self.playerInGameOrPausedOrEnded = Lib.playerInGameOrPausedOrEnded(player)

self.movementDisabled = player:GetAttribute("MovementDisabled")
self.teleported = player:GetAttribute("Teleported")
self.emoteWalkReset = player:GetAttribute("EmoteWalkReset")

self.groundType = workspace.MapItems.Ground:GetAttribute("GroundType")

if self.isGoalkeeper and false then
self.constants.gravity = -196.2+70
self.constants.jumpPunch = 50
else
local gravity = privateServerInfo:GetAttribute("Gravity")
self.constants.gravity = -gravity
self.constants.jumpPunch = 50
end
self.constants.maxSpeed = privateServerInfo:GetAttribute("WalkSpeed")
self.constants.slippery = privateServerInfo:GetAttribute("Slippery")

local maxStamina = GameInfo.MAX_STAMINA
if player:GetAttribute("InfiniteStamina") then
maxStamina = math.huge
elseif player:GetAttribute("x2Stamina") then
maxStamina *= 2
end
self.constants.maxStamina = maxStamina

if runningSound == nil then
local character = player.Character
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
runningSound = humanoidRootPart.Running
end
end
self.runningSound = runningSound
end

function Simulation:ProcessCommand(cmd, shouldDebug: boolean?)
if shouldDebug then
debug.profilebegin("Chickynoid Always Think")
end
for key,record in self.executionOrder do

if (record.alwaysThink) then
record.alwaysThink(self, cmd)
end
end
if shouldDebug then
debug.profileend()
end

if shouldDebug then
debug.profilebegin("Chickynoid Update State")
end
local record = self.moveStates[self.state.moveState]
if (record and record.updateState) then
record.updateState(self, cmd)
else
warn("No such updateState: ", self.state.moveState)
end
if shouldDebug then
debug.profileend()
end

if shouldDebug then
debug.profilebegin("Chickynoid Always Think Late")
end
for key, record in self.executionOrder do

if (record.alwaysThinkLate) then
record.alwaysThinkLate(self, cmd)
end
end
if shouldDebug then
debug.profileend()
end

--Input/Movement is done, do the update of timers and write out values

--Adjust stepup
if shouldDebug then
debug.profilebegin("Chickynoid Decay Step Up")
end
self:DecayStepUp(cmd.deltaTime)
if shouldDebug then
debug.profileend()
end

--position the debug visualizer
if self.debugModel ~= nil then
self.debugModel:PivotTo(CFrame.new(self.state.pos))
end

--Do pushing animation timer
self:DoPushingTimer(cmd)

--Write this to the characterData
if shouldDebug then
debug.profilebegin("Chickynoid Write To Character Data")
end
self.characterData:SetTargetPosition(self.state.pos)
self.characterData:SetAngle(self.state.angle)
self.characterData:SetStepUp(self.state.stepUp)
self.characterData:SetFlatSpeed( MathUtils:FlatVec(self.state.vel).Magnitude)
if shouldDebug then
debug.profileend()
end
end

function Simulation:UpdatePlayerAttributes()
if localPlayer and not self.characterData.isResimulating then
local stamina = self.state.stam
if stamina then
debug.profilebegin("Chickynoid Update Stamina")
localPlayer:SetAttribute("Stamina", stamina)
debug.profileend()
end
local tackle = self.state.tackle
if tackle then
debug.profilebegin("Chickynoid Update Tackle/Dive")
localPlayer:SetAttribute("Tackle", tackle > 0)
localPlayer:SetAttribute("Dive", tackle > 0)
debug.profileend()
end
end
end

function Simulation:SetAngle(angle, teleport)
self.state.angle = angle
if (teleport == true) then
self.state.targetAngle = angle
self.characterData:SetAngle(self.state.angle, true)
end
end

function Simulation:SetPosition(position, teleport)
self.state.position = position
self.characterData:SetTargetPosition(self.state.pos, teleport)
end

function Simulation:CrashLand(vel, ground)


if (self.constants.crashLandBehavior == Enums.Crashland.FULL_BHOP) then
return Vector3.new(vel.x, 0, vel.z)
end

if (self.constants.crashLandBehavior == Enums.Crashland.CAPPED_BHOP) then
--cap velocity
local returnVel = Vector3.new(vel.x, 0, vel.z)
returnVel = MathUtils:CapVelocity(returnVel, self.constants.maxSpeed)
return returnVel
end

if (self.constants.crashLandBehavior == Enums.Crashland.CAPPED_BHOP_FORWARD) then

local flat = Vector3.new(ground.normal.x, 0, ground.normal.z).Unit
local forward = MathUtils:PlayerAngleToVec(self.state.angle)

if (forward:Dot(flat) < 0) then --bhop forward if the slope is the way we're facing

local returnVel = Vector3.new(vel.x, 0, vel.z)
returnVel = MathUtils:CapVelocity(returnVel, self.constants.maxSpeed)
return returnVel
end
--else stop
return Vector3.new(0,0,0)
end

if (self.constants.crashLandBehavior == Enums.Crashland.FULL_BHOP_FORWARD) then

local flat = Vector3.new(ground.normal.x, 0, ground.normal.z).Unit
local forward = MathUtils:PlayerAngleToVec(self.state.angle)

if (forward:Dot(flat) < 0) then --bhop forward if the slope is the way we're facing
return vel
end
--else stop
return Vector3.new(0,0,0)
end

--stop
return Vector3.new(0,0,0)
end


--STEPUP - the magic that lets us traverse uneven world geometry
--the idea is that you redo the player movement but "if I was x units higher in the air"

function Simulation:DoStepUp(pos, vel, deltaTime)
if self:IsInMatch(pos) then
return nil
end

local flatVel = MathUtils:FlatVec(vel)

local stepVec = Vector3.new(0, self.constants.stepSize, 0)
--first move upwards as high as we can go

local headHit = CollisionModule:Sweep(pos, pos + stepVec)

--Project forwards
local stepUpNewPos, stepUpNewVel, _stepHitSomething = self:ProjectVelocity(headHit.endPos, flatVel, deltaTime)

--Trace back down
local traceDownPos = stepUpNewPos
local hitResult = CollisionModule:Sweep(traceDownPos, traceDownPos - stepVec)

stepUpNewPos = hitResult.endPos

--See if we're mostly on the ground after this? otherwise rewind it
local ground = self:DoGroundCheck(stepUpNewPos)

--Slope check
if ground ~= nil then
if ground.normal.Y < self.constants.maxGroundSlope or ground.startSolid == true then
return nil
end
end

if ground ~= nil then
local result = {
stepUp = self.state.pos.y - stepUpNewPos.y,
pos = stepUpNewPos,
vel = stepUpNewVel,
}
return result
end

return nil
end

--Magic to stick to the ground instead of falling on every stair
function Simulation:DoStepDown(pos)
if self:IsInMatch(pos) then -- in match
return nil
end

local stepVec = Vector3.new(0, self.constants.stepSize, 0)
local hitResult = CollisionModule:Sweep(pos, pos - stepVec)

if
hitResult.startSolid == false
and hitResult.fraction < 1
and hitResult.normal.Y >= self.constants.maxGroundSlope
then
local delta = pos.y - hitResult.endPos.y

if delta > 0.001 then
local result = {

pos = hitResult.endPos,
stepDown = delta,
}
return result
end
end

return nil
end

function Simulation:Destroy()
if self.debugModel then
self.debugModel:Destroy()
end
end

function Simulation:DecayStepUp(deltaTime)
self.state.stepUp = MathUtils:Friction(self.state.stepUp, 0.05, deltaTime) --higher == slower
end

function Simulation:DoGroundCheck(pos)
if self:IsInMatch(pos) then -- in match
local groundTopPos = 42.777+1.299/2 + 2.5
if pos.Y - groundTopPos < 0.1 then
local data = {}
data.normal = Vector3.new(0, 1, 0)
return data
else
return nil
end
end


local results = CollisionModule:Sweep(pos + Vector3.new(0, 0.1, 0), pos + Vector3.new(0, -0.1, 0))

if results.allSolid == true or results.startSolid == true then
--We're stuck, pretend we're in the air

results.fraction = 1
return results
end

if results.fraction < 1 then
return results
end
return nil
end

local playerSize = Vector3.new(2, 5, 2)
local boundary = {
Position = Vector3.new(86.013, 85.303, -306.262),
Size = Vector3.new(388.875, 83.59, 270.292) - playerSize,
}
function Simulation:ProjectVelocity(startPos: Vector3, startVel: Vector3, deltaTime: number, shouldBounce: boolean?)
if self:IsInMatch(startPos) then -- in match
local originalPos = startPos
startPos += startVel*deltaTime
local lastPos = startPos
startPos = MathUtils:ClampToBoundary(startPos, boundary.Position, boundary.Size)
if lastPos.Y ~= startPos.Y and startPos.Y > boundary.Position.Y then
startVel *= Vector3.new(1, -1, 1)
end
if lastPos.X ~= startPos.X or lastPos.Z ~= startPos.Z then
startVel = Vector3.new((startPos.X - originalPos.X) / deltaTime, startVel.Y, (startPos.Z - originalPos.Z) / deltaTime)
end

return startPos, startVel, false
end


local movePos = startPos
local moveVel = startVel
local hitSomething = false


--Project our movement through the world
local planes = {}
local timeLeft = deltaTime

for _ = 0, 3 do
if moveVel.Magnitude < 0.001 then
--done
break
end

if moveVel:Dot(startVel) < 0 then
--we projected back in the opposite direction from where we started. No.
moveVel = Vector3.new(0, 0, 0)
break
end

--We only operate on a scaled down version of velocity
local result = CollisionModule:Sweep(movePos, movePos + (moveVel * timeLeft))

--Update our position
if result.fraction > 0 then
movePos = result.endPos
end

--See if we swept the whole way?
if result.fraction == 1 then
break
end

if result.fraction < 1 then
hitSomething = true
end

if result.allSolid == true then
--all solid, don't do anything
--(this doesn't mean we wont project along a normal!)
moveVel = Vector3.new(0, 0, 0)
break
end

--Hit!
timeLeft -= (timeLeft * result.fraction)

if planes[result.planeNum] == nil then
planes[result.planeNum] = true

--Deflect the velocity and keep going
moveVel = MathUtils:ClipVelocity(moveVel, result.normal, 1.0)
else
--We hit the same plane twice, push off it a bit
movePos += result.normal * 0.01
moveVel += result.normal
break
end
end

return movePos, moveVel, hitSomething
end

function Simulation:IsInMatch(startPos: Vector3)
startPos = startPos or self.state.pos
return startPos.Z < -150
end


--This gets deltacompressed by the client/server chickynoids automatically
function Simulation:WriteState()
local record = {}
record.state = DeltaTable:DeepCopy(self.state)
-- record.constants = DeltaTable:DeepCopy(self.constants)
return record
end

function Simulation:ReadState(record)
self.state = DeltaTable:DeepCopy(record.state)
-- self.constants = DeltaTable:DeepCopy(record.constants)
end

function Simulation:DoPlatformMove(lastGround, deltaTime)
--Do platform move
if lastGround and lastGround.hullRecord and lastGround.hullRecord.instance then
local instance = lastGround.hullRecord.instance
if instance.Velocity.Magnitude > 0 then
self.state.pos += instance.Velocity * deltaTime
end
end
end

function Simulation:DoPushingTimer(cmd)
if IsClient == true then
return
end

if self.state.pushing > 0 then
self.state.pushing -= cmd.deltaTime
if self.state.pushing < 0 then
self.state.pushing = 0
end
end
end

function Simulation:GetStandingPart()
if self.lastGround and self.lastGround.hullRecord then
return self.lastGround.hullRecord.instance
end
return nil
end


function Simulation:ChangeBallRotation(rotateCFrame: CFrame)
self.custom.ballQuaternion = self.custom.ballQuaternion:Mul(Quaternion.fromCFrame(rotateCFrame))
end

function Simulation:SetAnimDir(animDir)
self.custom.animDir = animDir
end

function Simulation:LerpLeanAngle(newAngle: Vector2, alpha: number)
self.custom.leanAngle = self.custom.leanAngle:Lerp(newAngle, alpha)
end

function Simulation:SetLeanAngle(newAngle: Vector2)
self.custom.leanAngle = newAngle
end

return Simulation
replicatedfirst/Chickynoid/Shared/Simulation/TerrainCollision.lua
--!native
local RunService = game:GetService("RunService")

local MinkowskiSumInstance = require(script.Parent.MinkowskiSumInstance)

local module = {}
module.grid = {}
module.div = 0
module.counter = 0
module.planeNum = 1000000
module.expansionSize = Vector3.new(1, 1, 1)
module.boxCorners = {}

module.hullCache = {}

local cutoff = 0.20
local terrainQuantization = 8
local showHulls = false
local showCells = false


local corners = {
Vector3.new(0.5, 0.5, 0.5),
Vector3.new(0.5, 0.5, -0.5),
Vector3.new(-0.5, 0.5, 0.5),
Vector3.new(-0.5, 0.5, -0.5),
Vector3.new(0.5, -0.5, 0.5),
Vector3.new(0.5, -0.5, -0.5),
Vector3.new(-0.5, -0.5, 0.5),
Vector3.new(-0.5, -0.5, -0.5),
}

function module:RawFetchCell(key)
--store in x,z,y order

return self.grid[key]
end

function module:FetchCell(x, y, z)
return self:FetchCellMarching(x, y, z)
end

local function Sample(occs, x, y, z)
local avg = occs[x + 0][y + 0][z + 0]
avg += occs[x + 1][y + 0][z + 0]
avg += occs[x + 0][y + 0][z + 1]
avg += occs[x + 1][y + 0][z + 1]
avg += occs[x + 0][y + 1][z + 0]
avg += occs[x + 1][y + 1][z + 0]
avg += occs[x + 0][y + 1][z + 1]
avg += occs[x + 1][y + 1][z + 1]

avg /= 8

avg = math.floor(avg * terrainQuantization) / terrainQuantization
return avg
end


local function EmitSolidPoint(list, pos, val)
if val >= cutoff then
--table.insert(list, pos)
for _, c in pairs(module.boxCorners) do
table.insert(list, pos + c)
end
end
end

local function Frac(min, max, cross)
local range = max - min
local frac = (cross - min) / range
return frac
--return math.floor(frac*4)/4
end

local function SpanCheck(list, aval, bval, apos, bpos)
--if its a mismatch
if aval < cutoff and bval >= cutoff then
local frac = Frac(aval, bval, cutoff)

if (frac == 0 or frac == 1) then
-- return
end
local pos = apos:Lerp(bpos, frac) --TopD

for _, c in pairs(module.boxCorners) do
table.insert(list, pos + c)
end

elseif aval >= cutoff and bval < cutoff then
local frac = Frac(bval, aval, cutoff)

if (frac == 0 or frac == 1) then
-- return
end

local pos = bpos:Lerp(apos, frac) --TopD
for _, c in pairs(module.boxCorners) do
table.insert(list, pos + c)
end
end
end



function module:Lookup(a,b,c,d,e,f,g,h)

local key0 = Vector3.new(a,b,c)
local key1 = Vector3.new(d,e,f)
local key2 = Vector3.new(g,h,0)

local lookup0 = self.hullCache[key0]
if (lookup0 == nil) then
return nil
end

local lookup1 = lookup0[key1]
if (lookup1 == nil) then
return nil
end

return lookup1[key2]

end

function module:Write(a,b,c,d,e,f,g,h, tris)

local key0 = Vector3.new(a,b,c)
local key1 = Vector3.new(d,e,f)
local key2 = Vector3.new(g,h,0)

if (self.hullCache[key0] == nil) then
self.hullCache[key0] = {}
end
if (self.hullCache[key0][key1] == nil) then
self.hullCache[key0][key1] = {}
end

self.hullCache[key0][key1][key2] = tris
end


function module:FetchCellMarching(x, y, z)

local key = Vector3.new(x,y,z)
local rawCell = self:RawFetchCell(key)
if rawCell then
return rawCell
end

debug.profilebegin("FetchCellMarching")

local cell = self:CreateAndFetchCell(key)

local max = self.div - 1

local corner = Vector3.new(x, y, z) * self.gridSize

local region = Region3.new(
corner + Vector3.new(-4, -4, -4),
corner + Vector3.new(self.gridSize + 4, self.gridSize + 4, self.gridSize + 4)
)

local _materials, occs = game.Workspace.Terrain:ReadVoxels(region, 4)

local topAPos = Vector3.new(0, 4, 0)
local topBPos = Vector3.new(4, 4, 0)
local topCPos = Vector3.new(0, 4, 4)
local topDPos = Vector3.new(4, 4, 4)
local botAPos = Vector3.new(0, 0, 0)
local botBPos = Vector3.new(4, 0, 0)
local botCPos = Vector3.new(0, 0, 4)
local botDPos = Vector3.new(4, 0, 4)

local new = 0
local old = 0

for xx = 0, max do
for yy = 0, max do
for zz = 0, max do

if showCells and RunService:IsClient() then
local instance = Instance.new("Part")

instance.Size = Vector3.new(4, 4, 4)
local center = corner + Vector3.new(xx * 4, yy * 4, zz * 4)
instance.Position = center + Vector3.new(2, 2, 2)
instance.Transparency = 0.9

instance.Shape = Enum.PartType.Block
instance.Color = Color3.new(1, 0.3, 0.3)
instance.Parent = game.Workspace
instance.Anchored = true
instance.TopSurface = Enum.SurfaceType.Smooth
instance.BottomSurface = Enum.SurfaceType.Smooth
end

local xd = xx + 1
local yd = yy + 1
local zd = zz + 1

local topA = Sample(occs, xd + 0, yd + 1, zd + 0)
local topB = Sample(occs, xd + 1, yd + 1, zd + 0)
local topC = Sample(occs, xd + 0, yd + 1, zd + 1)
local topD = Sample(occs, xd + 1, yd + 1, zd + 1)
local botA = Sample(occs, xd + 0, yd + 0, zd + 0)
local botB = Sample(occs, xd + 1, yd + 0, zd + 0)
local botC = Sample(occs, xd + 0, yd + 0, zd + 1)
local botD = Sample(occs, xd + 1, yd + 0, zd + 1)

--All empty
if
topA < cutoff
and topB < cutoff
and topC < cutoff
and topD < cutoff
and botA < cutoff
and botB < cutoff
and botC < cutoff
and botD < cutoff
then
continue
end

local tris = self:Lookup(topA,topB, topC, topD, botA, botB, botC, botD)
if (tris == nil) then
local list = {}
--All solid ?
if
topA >= cutoff
and topB >= cutoff
and topC >= cutoff
and topD >= cutoff
and botA >= cutoff
and botB >= cutoff
and botC >= cutoff
and botD >= cutoff
then
continue
else
--Generate a new hull
--See if any of the corners are solid
EmitSolidPoint(list, topAPos, topA)
EmitSolidPoint(list, topBPos, topB)
EmitSolidPoint(list, topCPos, topC)
EmitSolidPoint(list, topDPos, topD)
EmitSolidPoint(list, botAPos, botA)
EmitSolidPoint(list, botBPos, botB)
EmitSolidPoint(list, botCPos, botC)
EmitSolidPoint(list, botDPos, botD)

--Vertical spans
SpanCheck(list, topA, botA, topAPos, botAPos)
SpanCheck(list, topB, botB, topBPos, botBPos)
SpanCheck(list, topC, botC, topCPos, botCPos)
SpanCheck(list, topD, botD, topDPos, botDPos)

--Bottom spans
SpanCheck(list, botA, botB, botAPos, botBPos)
SpanCheck(list, botC, botD, botCPos, botDPos)
SpanCheck(list, botA, botC, botAPos, botCPos)
SpanCheck(list, botB, botD, botBPos, botDPos)

--Top spans
SpanCheck(list, topA, topB, topAPos, topBPos)
SpanCheck(list, topC, topD, topCPos, topDPos)
SpanCheck(list, topA, topC, topAPos, topCPos)
SpanCheck(list, topB, topD, topBPos, topDPos)
end

if #list > 3 then
tris = MinkowskiSumInstance:GetPlanePointForPoints(list)
self:Write(topA,topB, topC, topD, botA, botB, botC, botD, tris)
new+=1
end
end

--We have tris now
if (tris ~= nil) then
local center = corner + Vector3.new(xx * 4, yy * 4, zz * 4)
local hull = self:BuildHullFromPlanePoint(tris, center)
table.insert(cell, { hull = hull })

if showHulls and RunService:IsClient() then
local points = {}
for key,tri in pairs(tris) do
table.insert(points, tri[1]+center)
table.insert(points, tri[2]+center)
table.insert(points, tri[3]+center)
end
MinkowskiSumInstance:VisualizePlanesForPoints(points)
end
end
end
end
end
if (new > 0) then
--print("new ", new)
end

debug.profileend()

return cell
end

function module:BuildHullFromPlanePoint(tris, offset)

local records = {}

--Generate unique planes in n+d format
for _, tri in pairs(tris) do
local normal = tri[4]
local ed = (tri[1]+offset):Dot(normal) --expanded distance

table.insert(records, {
n = normal,
ed = ed,
planeNum = self.planeNum,
})
self.planeNum+=1
end

return records
end

function module:SpawnDebugGridBox(x, y, z, color, grid)
local instance = Instance.new("Part")

instance.Size = Vector3.new(grid, grid, grid)
instance.Position = (Vector3.new(x, y, z) * self.gridSize) + (Vector3.new(grid, grid, grid) * 0.5)
instance.Transparency = 0

instance.Color = color
instance.Parent = game.Workspace
instance.Anchored = true
instance.TopSurface = Enum.SurfaceType.Smooth
instance.BottomSurface = Enum.SurfaceType.Smooth
end

function module:CreateAndFetchCell(key)

local cell = self.grid[key]
if (cell == nil) then
cell = {}
self.grid[key] = cell
end
return cell
end

function module:Setup(gridSize, expansionSize)
self.grid = {}
self.expansionSize = expansionSize

self.gridSize = gridSize
self.boxSize = 4
self.div = self.gridSize / self.boxSize

self.expandedCorners = {}
for _, corner in pairs(corners) do
table.insert(self.expandedCorners, (corner * self.boxSize) + (corner * self.expansionSize))
end
self.boxCorners = {}
for _, corner in pairs(corners) do
table.insert(self.boxCorners, (corner * self.expansionSize))
end

local testPart = Instance.new("Part")
testPart.Size = Vector3.new(self.boxSize, self.boxSize, self.boxSize)
testPart.CanCollide = false
self.testPart = testPart

if (game:GetService("RunService"):IsServer() == true) then
-- self:PreprocessTerrain()
end
end

function module:PreprocessTerrain()

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = { game.Workspace.Terrain}
rayParams.FilterType = Enum.RaycastFilterType.Include

local counter = 0
coroutine.wrap(function()
print("Starting preprocess")
local height = -200
for x=-2048,2048, self.gridSize do
for z=-2048, 2048, self.gridSize do
local hit = game.Workspace:Raycast(Vector3.new(x + self.gridSize*0.5,height,z+ self.gridSize*0.5), Vector3.new(0,-1000,0))
if (hit) then
local xx = math.floor(x / self.gridSize)
local yy = math.floor(hit.Position.Y / self.gridSize)
local zz = math.floor(z / self.gridSize)
self:FetchCell(xx,yy,zz)
end
counter+=1
if (counter >1000) then
counter = 0
print(x,z)
wait()
end
end
end
end)()
end

return module
replicatedfirst/Chickynoid/Shared/Simulation/TrajectoryModule.lua
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local module = {}

function module:PositionWorld(serverTime, deltaTime)
if true then
return
end
local movers = CollectionService:GetTagged("Dynamic")

for _, value: BasePart in pairs(movers) do
local basePos = value:GetAttribute("BasePos")

value.Position = basePos + Vector3.new(0, math.sin(serverTime) * 3, 0)
local PrevPosition = basePos + Vector3.new(0, math.sin(serverTime - deltaTime) * 3, 0)

value.AssemblyLinearVelocity = (value.Position - PrevPosition) / deltaTime
end
end

function module:ServerInit()
if true then
return
end
local movers = CollectionService:GetTagged("Dynamic")
for _, value: BasePart in pairs(movers) do
value:SetAttribute("BasePos", value.Position)
end
end

-- TODO: This shouldn't be done here
if RunService:IsServer() then
module:ServerInit()
end

return module
replicatedfirst/Chickynoid/Shared/Simulation/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/Chickynoid/Shared/Vendor/CrunchTable.lua
--CrunchTable lets you define compression schemes for simple tables to be sent by roblox
--If a field in a table is not defined in the layout, it will be ignored and stay in the table
--If a field in a table is not present, but is defined in the layout, it'll default to 0 (or equiv)

local module = {}

module.Enum = {
FLOAT = 1,
VECTOR3 = 2,
INT32 = 3,
UBYTE = 4,
}
table.freeze(module.Enum)

module.Sizes = {
4,
12,
4,
1
}
table.freeze(module.Sizes)

function module:CreateLayout()
local layout = {}
layout.pairTable = {}

layout.totalBytes = 0

function layout:Add(field :string, enum : number)
table.insert(self.pairTable, {field = field, enum = enum})
module:CalcSize(self)
end
return layout
end

function module:CalcSize(layout)
local totalBytes = 0
for index,rec in layout.pairTable do

rec.size = module.Sizes[rec.enum]
totalBytes += rec.size

end
local numBytesForIndex = 2
layout.totalBytes = totalBytes + numBytesForIndex
end

function module:DeepCopy(sourceTable)
local function Deep(tbl)
local tCopy = table.create(#tbl)
for k, v in pairs(tbl) do
if type(v) == "table" then
tCopy[k] = Deep(v)
else
tCopy[k] = v
end
end
return tCopy
end
return Deep(sourceTable)
end


function module:BinaryEncodeTable(srcData, layout)

local newPacket = self:DeepCopy(srcData)

local buf = buffer.create(layout.totalBytes)
local numBytesForIndex = 2
local offset = numBytesForIndex
local contentBits = 0
local bitIndex = 0

for index,rec in layout.pairTable do

local key = rec.field
local encodeChar = rec.enum

local srcValue = newPacket[key]

if (encodeChar == module.Enum.INT32) then
if (srcValue ~= nil and srcValue ~= 0) then
buffer.writei32(buf,offset, srcValue)
offset+=rec.size
contentBits = bit32.bor(contentBits, bit32.lshift(1, bitIndex))
end
elseif (encodeChar == module.Enum.FLOAT) then
if (srcValue ~= nil and srcValue ~= 0) then
buffer.writef32(buf,offset,srcValue)
offset+=rec.size
contentBits = bit32.bor(contentBits, bit32.lshift(1, bitIndex))
end
elseif (encodeChar == module.Enum.UBYTE) then
if (srcValue ~= nil and srcValue ~= 0) then
buffer.writeu8(buf,offset,srcValue)
offset+=rec.size
contentBits = bit32.bor(contentBits, bit32.lshift(1, bitIndex))
end
elseif (encodeChar == module.Enum.VECTOR3) then
if (srcValue ~= nil and srcValue.magnitude > 0) then
buffer.writef32(buf,offset,srcValue.X)
offset+=4
buffer.writef32(buf,offset,srcValue.Y)
offset+=4
buffer.writef32(buf,offset,srcValue.Z)
offset+=4
contentBits = bit32.bor(contentBits, bit32.lshift(1, bitIndex))
end
end

newPacket[key] = nil

bitIndex += 1
end

--Write the contents
buffer.writeu16(buf,0, contentBits)

--Copy it to a new buffer
local finalBuffer = buffer.create(offset)
buffer.copy(finalBuffer, 0, buf, 0, offset)

newPacket._b = finalBuffer

--leave the other fields untouched
return newPacket
end


function module:BinaryDecodeTable(srcData, layout)

local command = self:DeepCopy(srcData)
if (command._b == nil) then
error("missing _b field")
return
end
local buf = command._b
command._b = nil

local offset = 0

local contentBits = buffer.readu16(buf, 0)
offset+=2

local bitIndex = 0

for index,rec in layout.pairTable do
local key = rec.field
local encodeChar = rec.enum

local hasBit = bit32.band(contentBits, bit32.lshift(1, bitIndex)) > 0

if (hasBit == false) then
if (encodeChar == module.Enum.INT32) then
command[key] = 0
elseif (encodeChar == module.Enum.FLOAT) then
command[key] = 0
elseif (encodeChar == module.Enum.UBYTE) then
command[key] = 0
elseif (encodeChar == module.Enum.VECTOR3) then
command[key] = Vector3.zero
end
else
if (encodeChar == module.Enum.INT32) then
command[key] = buffer.readi32(buf,offset)
offset+=rec.size
elseif (encodeChar == module.Enum.FLOAT) then
command[key] = buffer.readf32(buf,offset)
offset+=rec.size
elseif (encodeChar == module.Enum.UBYTE) then
command[key] = buffer.readu8(buf,offset)
offset+=rec.size
elseif (encodeChar == module.Enum.VECTOR3) then
local x = buffer.readf32(buf,offset)
offset+=4
local y = buffer.readf32(buf,offset)
offset+=4
local z = buffer.readf32(buf,offset)
offset+=4
command[key] = Vector3.new(x,y,z)
end
end
bitIndex+=1
end
return command
end

return module
replicatedfirst/Chickynoid/Shared/Vendor/DeltaTable.lua
local module = {}

--Compares two tables, and produces a new table containing the differences
function module:MakeDeltaTable(oldTable, newTable)

if (oldTable == nil) then
return self:DeepCopy(newTable)
end

local deltaTable = {}
local changes = 0
for var, data in pairs(newTable) do
if oldTable[var] == nil then
deltaTable[var] = data
else
if type(newTable[var]) == "table" then
--its a table, recurse
local newtable, num = module:MakeDeltaTable(oldTable[var], newTable[var])
if num > 0 then
changes = changes + 1
deltaTable[var] = newtable
end
else
local a = newTable[var]
local b = oldTable[var]
if a ~= b then
changes = changes + 1
deltaTable[var] = a
end
end
end
end
--Check for deletions
for var, _ in pairs(oldTable) do
if newTable[var] == nil then
if deltaTable.__deletions == nil then
deltaTable.__deletions = {}
end
table.insert(deltaTable.__deletions, var)
end
end

return deltaTable, changes
end

--Produces a new table that is the combination of a target, and a deltaTable produced by MakeDeltaTable
function module:ApplyDeltaTable(target, deltaTable)

if (target == nil) then
target = {}
end
local newTable = self:DeepCopy(target)
if newTable == nil then
newTable = {}
end

for var, _ in pairs(deltaTable) do
if type(deltaTable[var]) == "table" then
newTable[var] = self:ApplyDeltaTable(target[var], deltaTable[var])
else
newTable[var] = deltaTable[var]
end
end

if newTable.__deletions ~= nil then
for _, var in pairs(newTable.__deletions) do
newTable[var] = nil
--print("deleted ", var)
end
end

return newTable
end

function module:DeepCopy(sourceTable)
local function Deep(tbl)
local tCopy = table.create(#tbl)
for k, v in pairs(tbl) do
if type(v) == "table" then
tCopy[k] = Deep(v)
else
tCopy[k] = v
end
end
return tCopy
end
return Deep(sourceTable)
end

function module:DeepCopySharedTable(sourceTable)
local function Deep(tbl)
local tCopy = {}
for k, v in tbl do
if type(v) == "table" then
tCopy[k] = Deep(v)
else
tCopy[k] = v
end
end
return tCopy
end
return Deep(sourceTable)
end


return module
replicatedfirst/Chickynoid/Shared/Vendor/FastSignal.lua
--https://github.com/RBLXUtils/FastSignal/

--[=[
A class which holds data and methods for ScriptSignals.

@class ScriptSignal
]=]
local ScriptSignal = {}
ScriptSignal.__index = ScriptSignal

--[=[
A class which holds data and methods for ScriptConnections.

@class ScriptConnection
]=]
local ScriptConnection = {}
ScriptConnection.__index = ScriptConnection

--[=[
A boolean which determines if a ScriptConnection is active or not.

@prop Connected boolean
@within ScriptConnection

@readonly
@ignore
]=]

export type Class = typeof(setmetatable({
_active = true,
_head = nil :: ScriptConnectionNode?,
}, ScriptSignal))

export type ScriptConnection = typeof(setmetatable({
Connected = true,
_node = nil :: ScriptConnectionNode?,
}, ScriptConnection))

type ScriptConnectionNode = {
_signal: Class,
_connection: ScriptConnection?,
_handler: (...any) -> (),

_next: ScriptConnectionNode?,
_prev: ScriptConnectionNode?,
}

local FreeThread: thread? = nil

local function RunHandlerInFreeThread(handler, ...)
local thread = FreeThread :: thread
FreeThread = nil

handler(...)

FreeThread = thread
end

local function CreateFreeThread()
FreeThread = coroutine.running()

while true do
RunHandlerInFreeThread(coroutine.yield())
end
end

--[=[
Creates a ScriptSignal object.

@return ScriptSignal
@ignore
]=]
function ScriptSignal.new(): Class
return setmetatable({
_active = true,
_head = nil,
}, ScriptSignal)
end

--[=[
Returns a boolean determining if the object is a ScriptSignal.

```lua
local janitor = Janitor.new()
local signal = ScriptSignal.new()

ScriptSignal.Is(signal) -> true
ScriptSignal.Is(janitor) -> false
```

@param object any
@return boolean
@ignore
]=]
function ScriptSignal.Is(object): boolean
return typeof(object) == "table" and getmetatable(object) == ScriptSignal
end

--[=[
Returns a boolean determing if a ScriptSignal object is active.

```lua
ScriptSignal:IsActive() -> true
ScriptSignal:Destroy()
ScriptSignal:IsActive() -> false
```

@return boolean
@ignore
]=]
function ScriptSignal:IsActive(): boolean
return self._active == true
end

--[=[
Connects a handler to a ScriptSignal object.

```lua
ScriptSignal:Connect(function(text)
print(text)
end)

ScriptSignal:Fire("Something")
ScriptSignal:Fire("Something else")

-- "Something" and then "Something else" are printed
```

@param handler (...: any) -> ()
@return ScriptConnection
@ignore
]=]
function ScriptSignal:Connect(handler: (...any) -> ()): ScriptConnection
assert(typeof(handler) == "function", "Must be function")

if self._active ~= true then
return setmetatable({
Connected = false,
_node = nil,
}, ScriptConnection)
end

local _head: ScriptConnectionNode? = self._head

local node: ScriptConnectionNode = {
_signal = self :: Class,
_connection = nil,
_handler = handler,

_next = _head,
_prev = nil,
}

if _head ~= nil then
_head._prev = node
end

self._head = node

local connection = setmetatable({
Connected = true,
_node = node,
}, ScriptConnection)

node._connection = connection

return connection :: ScriptConnection
end

--[=[
Connects a handler to a ScriptSignal object, but only allows that
connection to run once. Any `:Fire` calls called afterwards won't trigger anything.

```lua
ScriptSignal:ConnectOnce(function()
print("Connection fired")
end)

ScriptSignal:Fire()
ScriptSignal:Fire()

-- "Connection fired" is only fired once
```

@param handler (...: any) -> ()
@ignore
]=]
function ScriptSignal:ConnectOnce(handler: (...any) -> ())
assert(typeof(handler) == "function", "Must be function")

local connection
connection = self:Connect(function(...)
connection:Disconnect()
handler(...)
end)
end

--[=[
Yields the thread until a `:Fire` call occurs, returns what the signal was fired with.

```lua
task.spawn(function()
print(
ScriptSignal:Wait()
)
end)

ScriptSignal:Fire("Arg", nil, 1, 2, 3, nil)
-- "Arg", nil, 1, 2, 3, nil are printed
```

@yields
@return ...any
@ignore
]=]
function ScriptSignal:Wait(): (...any)
local thread
do
thread = coroutine.running()

local connection
connection = self:Connect(function(...)
connection:Disconnect()
task.spawn(thread, ...)
end)
end

return coroutine.yield()
end

--[=[
Fires a ScriptSignal object with the arguments passed.

```lua
ScriptSignal:Connect(function(text)
print(text)
end)

ScriptSignal:Fire("Some Text...")

-- "Some Text..." is printed twice
```

@param ... any
@ignore
]=]
function ScriptSignal:Fire(...: any)
local node: ScriptConnectionNode? = self._head
while node ~= nil do
if node._connection ~= nil then
if FreeThread == nil then
task.spawn(CreateFreeThread)
end

task.spawn(FreeThread :: thread, node._handler, ...)
end

node = node._next
end
end

--[=[
Disconnects all connections from a ScriptSignal object without making it unusable.

```lua
local connection = ScriptSignal:Connect(function() end)

connection.Connected -> true
ScriptSignal:DisconnectAll()
connection.Connected -> false
```

@ignore
]=]
function ScriptSignal:DisconnectAll()
local node: ScriptConnectionNode? = self._head
while node ~= nil do
local _connection = node._connection

if _connection ~= nil then
_connection.Connected = false
_connection._node = nil
node._connection = nil
end

node = node._next
end

self._head = nil
end

--[=[
Destroys a ScriptSignal object, disconnecting all connections and making it unusable.

```lua
ScriptSignal:Destroy()

local connection = ScriptSignal:Connect(function() end)
connection.Connected -> false
```

@ignore
]=]
function ScriptSignal:Destroy()
if self._active ~= true then
return
end

self:DisconnectAll()
self._active = false
end

--[=[
Disconnects a connection, any `:Fire` calls from now on will not
invoke this connection's handler.

```lua
local connection = ScriptSignal:Connect(function() end)

connection.Connected -> true
connection:Disconnect()
connection.Connected -> false
```

@ignore
]=]
function ScriptConnection:Disconnect()
if self.Connected ~= true then
return
end

self.Connected = false

local _node: ScriptConnectionNode = self._node
local _prev = _node._prev
local _next = _node._next

if _next ~= nil then
_next._prev = _prev
end

if _prev ~= nil then
_prev._next = _next
else
-- _node == _signal._head

_node._signal._head = _next
end

_node._connection = nil
self._node = nil
end
ScriptConnection.Destroy = ScriptConnection.Disconnect

return ScriptSignal
replicatedfirst/Chickynoid/Shared/Vendor/Profiler.lua
local module = {}

active = false
module.tags = {}
module.tagStack = {}

function module:BeginSample(name)

local rec = self.tags[name]
if (rec == nil) then
rec = {}
rec.averages = {}
rec.average = 0
rec.currentSample = 0
self.tags[name] = rec
end

rec.startTime = tick()

table.insert(module.tagStack, name)
end

function module:EndSample()

if (#module.tagStack == 0) then
warn("Profile tagstack already empty")
return
end
local rec = module.tags[module.tagStack[#module.tagStack]]
table.remove(module.tagStack, #module.tagStack)
rec.currentSample = tick() - rec.startTime

table.insert(rec.averages, rec.currentSample)

if (#rec.averages > 10) then
table.remove(rec.averages,1)
end

end

function module:Print(name)
local rec = module.tags[name]
if (rec == nil) then
warn("Unknown tag")
return
end
local average = 0
local counter = 0
for key,value in rec.averages do
average += value
counter += 1
end
average /= counter

print(name, string.format("%.3f", rec.currentSample*1000) .. "ms avg:", string.format("%.3f", average*1000) .. "ms")
end

local nextTick = tick() + 1
if (active == true) then
game["Run Service"].Heartbeat:Connect(function()
if (tick() > nextTick) then
nextTick = tick() + 1

for key,value in module.tags do
module:Print(key)
end
end
end)
end

return module
replicatedfirst/Chickynoid/Shared/Vendor/QuickHull2.lua
--Port of
--https://github.com/OskarSigvardsson/unity-quickhull/blob/master/Scripts/ConvexHullCalculator.cs
--Which is under the MIT license

local module = {}

local UNASSIGNED = -2
local INSIDE = -1
local EPSILON = 0.0001
local NaN = math.NaN
local counter = 0

--Notes: openSetTail correctly bumped to be 1-based

local function Cross(a, b)
return Vector3.new(
a.y*b.z - a.z*b.y,
a.z*b.x - a.x*b.z,
a.x*b.y - a.y*b.x)
end

local function Dot(a, b)
return a.x*b.x + a.y*b.y + a.z*b.z
end

local function PointFaceDistance(point, pointOnFace, face)
return Dot(face.Normal, point - pointOnFace)
end

local function Normal(v0, v1, v2)
return Cross(v1 - v0, v2 - v0).Unit
end

local function AreCoincident(a, b)
return (a - b).Magnitude <= EPSILON
end

local function AreCollinear(a, b, c)
return Cross(c - a, c - b).Magnitude <= EPSILON
end

local function AreCoplanar(a, b, c, d)
local n1 = Cross(c - a, c - b)
local n2 = Cross(d - a, d - b)

local m1 = n1.Magnitude
local m2 = n2.Magnitude

return m1 <= EPSILON
or m2 <= EPSILON
or AreCollinear(Vector3.zero, (1.0 / m1) * n1, (1.0 / m2) * n2)
end

local function Face(v0, v1, v2, o0, o1, o2, normal)

return {
Vertex0 = v0,
Vertex1 = v1,
Vertex2 = v2,
Opposite0 = o0,
Opposite1 = o1,
Opposite2 = o2,
Normal = normal,
}
end

function FaceEquals(left, other)
return (left.Vertex0 == other.Vertex0)
and (left.Vertex1 == other.Vertex1)
and (left.Vertex2 == other.Vertex2)
and (left.Opposite0 == other.Opposite0)
and (left.Opposite1 == other.Opposite1)
and (left.Opposite2 == other.Opposite2)
and (left.Normal == other.Normal)
end

local function PointFace(p, f, d)
return {
Point = p,
Face = f,
Distance = d
}
end

local function HorizonEdge(f, e0, e1)
return {
Face = f,
Edge0 = e0,
Edge1 = e1
}
end

local function Contains(list, item)
for key,value in pairs(list) do

if (item == value) then
return true
end
end
return false
end

local function Count(list)
return #list
end


local faces = {}
local openSet = {}
local litFaces = {}
local horizon = {}

local openSetTail = -1
local faceCount = 0



local function HasEdge(f, e0, e1)
return (f.Vertex0 == e0 and f.Vertex1 == e1)
or (f.Vertex1 == e0 and f.Vertex2 == e1)
or (f.Vertex2 == e0 and f.Vertex0 == e1)
end

local function VerifyFaces(points)
for kvpKey, kpvValue in pairs(faces) do
local fi = kvpKey
local face = kpvValue

assert(faces[face.Opposite0] ~= nil)
assert(faces[face.Opposite1] ~= nil)
assert(faces[face.Opposite2] ~= nil)

assert(face.Opposite0 ~= fi)
assert(face.Opposite1 ~= fi)
assert(face.Opposite2 ~= fi)

assert(face.Vertex0 ~= face.Vertex1)
assert(face.Vertex0 ~= face.Vertex2)
assert(face.Vertex1 ~= face.Vertex2)

assert(HasEdge(faces[face.Opposite0], face.Vertex2, face.Vertex1))
assert(HasEdge(faces[face.Opposite1], face.Vertex0, face.Vertex2))
assert(HasEdge(faces[face.Opposite2], face.Vertex1, face.Vertex0))

--[[ assert((face.Normal - Normal(
points[face.Vertex0],
points[face.Vertex1],
points[face.Vertex2])).Magnitude < EPSILON)]]--
end
end



--[[
Reassign points based on the new faces added by ConstructCone().

Only points that were previous assigned to a removed face need to
be updated, so check litFaces while looping through the open set.

There is a potential optimization here: there's no reason to loop
through the entire openSet here. If each face had it's own
openSet, we could just loop through the openSets in the removed
faces. That would make the loop here shorter.

However, to do that, we would have to juggle A LOT more List<T>'s,
and we would need an object pool to manage them all without
generating a whole bunch of garbage. I don't think it's worth
doing that to make this loop shorter, a straight for-loop through
a list is pretty darn fast. Still, it might be worth trying
]]--

local function ReassignPoints(points)

if (false) then
for key,value in pairs(openSet) do
print("OpenSet" , value.Face-1, value.Point-1, value.Distance)
end
for key,value in pairs(faces) do
print( "Face" , key-1, value.Vertex0-1 )
end
end
--0123
--for (int i = 0; i <= openSetTail; i++)
local i = 0
--for i = 1, openSetTail do --@@@
while(i < openSetTail) do --@@@
i+=1

--print("looking up", i-1)
local fp = openSet[i]

if (Contains(litFaces, fp.Face)) then
local assigned = false
local point = points[fp.Point]

for kvpKey,kvpValue in pairs(faces) do
local fi = kvpKey
local face = kvpValue

local dist = PointFaceDistance(
point,
points[face.Vertex0],
face)

if (dist > EPSILON) then
assigned = true

fp.Face = fi
fp.Distance = dist

openSet[i] = fp

--print("Assign ", i-1)
break
end
end

if (assigned == false) then
--[[
// If point hasn't been assigned, then it's inside the
// convex hull. Swap it with openSetTail, and decrement
// openSetTail. We also have to decrement i, because
// there's now a new thing in openSet[i], so we need i
// to remain the same the next iteration of the loop.
]]--
fp.Face = INSIDE
fp.Distance = NaN

openSet[i] = openSet[openSetTail]
openSet[openSetTail] = fp

--print("Assign B", i-1)

i-=1
openSetTail-=1
end
end
end

if (false) then
print("After")
for key,value in pairs(openSet) do
print("OpenSet" , value.Face-1, value.Point-1, value.Distance)
end
for key,value in pairs(faces) do
print( "Face" , key-1, value.Vertex0-1 )
end
end
end

local function VerifyOpenSet(points)
--for (int i = 0; i < openSet.Count; i++) --@@@
for i=1, Count(openSet) do --@@@
if (i > openSetTail) then
assert(openSet[i].Face == INSIDE)
else
assert(openSet[i].Face ~= INSIDE)
assert(openSet[i].Face ~= UNASSIGNED)

assert(PointFaceDistance(
points[openSet[i].Point],
points[faces[openSet[i].Face].Vertex0],
faces[openSet[i].Face]) > 0.0)
end
end
end

local function VerifyHorizon()
--for (int i = 0; i < horizon.Count; i++) --@@@

for i = 1, Count(horizon) do --@@@
--local prev = i == 0 ? horizon.Count - 1 : i - 1
local prev
if (i == 1) then --i == 0 --@@@
prev = Count(horizon) --Last index
else
prev = i - 1
end

assert(horizon[prev].Edge1 == horizon[i].Edge0)
assert(HasEdge(faces[horizon[i].Face], horizon[i].Edge1, horizon[i].Edge0))
end
end

-- Recursively search to find the horizon or lit set.
local function SearchHorizon(points, point, prevFaceIndex, faceCount, face)
--assert(prevFaceIndex >= 0)
-- assert(litFaces.Contains(prevFaceIndex))
--assert(litFaces.Contains(faceCount) == false)
-- assert(FaceEquals(faces[faceCount],face))


--litFaces.Add(faceCount)
table.insert(litFaces,faceCount)

--[[
Use prevFaceIndex to determine what the next face to search will
be, and what edges we need to cross to get there. It's important
that the search proceeds in counter-clockwise order from the
previous face.
]]--
local nextFaceIndex0 = 0
local nextFaceIndex1 = 0
local edge0 = 0
local edge1 = 0
local edge2 = 0

if (prevFaceIndex == face.Opposite0) then
nextFaceIndex0 = face.Opposite1
nextFaceIndex1 = face.Opposite2

edge0 = face.Vertex2
edge1 = face.Vertex0
edge2 = face.Vertex1
elseif (prevFaceIndex == face.Opposite1) then
nextFaceIndex0 = face.Opposite2;
nextFaceIndex1 = face.Opposite0;

edge0 = face.Vertex0;
edge1 = face.Vertex1;
edge2 = face.Vertex2;
else
--assert(prevFaceIndex == face.Opposite2)

nextFaceIndex0 = face.Opposite0
nextFaceIndex1 = face.Opposite1

edge0 = face.Vertex1
edge1 = face.Vertex2
edge2 = face.Vertex0
end

if (Contains(litFaces, nextFaceIndex0) == false) then
local oppositeFace = faces[nextFaceIndex0]

local dist = PointFaceDistance(
point,
points[oppositeFace.Vertex0],
oppositeFace)

if (dist <= 0.0) then
table.insert(horizon,HorizonEdge(nextFaceIndex0, edge0, edge1))
else
SearchHorizon(points, point, faceCount, nextFaceIndex0, oppositeFace)
end
end

if (Contains(litFaces, nextFaceIndex1) == false) then
local oppositeFace = faces[nextFaceIndex1]

local dist = PointFaceDistance(
point,
points[oppositeFace.Vertex0],
oppositeFace)

if (dist <= 0.0) then
table.insert(horizon,HorizonEdge(nextFaceIndex1, edge1, edge2))

else
SearchHorizon(points, point, faceCount, nextFaceIndex1, oppositeFace)
end
end
end

--[[
Start the search for the horizon.

The search is a DFS search that searches neighboring triangles in
a counter-clockwise fashion. When it find a neighbor which is not
lit, that edge will be a line on the horizon. If the search always
proceeds counter-clockwise, the edges of the horizon will be found
in counter-clockwise order.

The heart of the search can be found in the recursive
SearchHorizon() method, but the the first iteration of the search
is special, because it has to visit three neighbors (all the
neighbors of the initial triangle), while the rest of the search
only has to visit two (because one of them has already been
visited, the one you came from).
]]--

local function FindHorizon(points, point, fi, face)

-- TODO should I use epsilon in the PointFaceDistance comparisons?

litFaces = {}
horizon = {}

table.insert(litFaces, fi)

--assert(PointFaceDistance(point, points[face.Vertex0], face) > 0.0)

-- For the rest of the recursive search calls, we first check if the
-- triangle has already been visited and is part of litFaces.
-- However, in this first call we can skip that because we know it
-- can't possibly have been visited yet, since the only thing in
-- litFaces is the current triangle.

local oppositeFace = faces[face.Opposite0]

local dist = PointFaceDistance(
point,
points[oppositeFace.Vertex0],
oppositeFace)

if (dist <= 0.0) then
--horizon.Add(HorizonEdge(face.Opposite0,face.Vertex1,face.Vertex2))
table.insert(horizon,HorizonEdge(face.Opposite0,face.Vertex1,face.Vertex2))
else
SearchHorizon(points, point, fi, face.Opposite0, oppositeFace)
end


if (Contains(litFaces, face.Opposite1) == false) then
local oppositeFace = faces[face.Opposite1]

local dist = PointFaceDistance(
point,
points[oppositeFace.Vertex0],
oppositeFace);

if (dist <= 0.0) then
table.insert(horizon, HorizonEdge(face.Opposite1,face.Vertex2, face.Vertex0))
else
SearchHorizon(points, point, fi, face.Opposite1, oppositeFace)
end
end

if (Contains(litFaces, face.Opposite2) == false) then
local oppositeFace = faces[face.Opposite2]

local dist = PointFaceDistance(point, points[oppositeFace.Vertex0], oppositeFace)

if (dist <= 0.0) then
table.insert(horizon, HorizonEdge(face.Opposite2, face.Vertex0, face.Vertex1))
else
SearchHorizon(points, point, fi, face.Opposite2, oppositeFace)
end
end
end


--[[
Find four points in the point cloud that are not coplanar for the
seed hull
]]--

local function FindInitialHullIndices(points)
local count = Count(points)

--for (int i0 = 0; i0 < count - 3; i0++) ---@@@@
for i0 = 1, count - 2 do

--for (int i1 = i0 + 1; i1 < count - 2; i1++) --@@@@
for i1 = i0 + 1, count - 1 do
local p0 = points[i0]
local p1 = points[i1]

if (AreCoincident(p0, p1)) then
continue
end

--for (int i2 = i1 + 1; i2 < count - 1; i2++) --@@@@
for i2 = i1 + 1, count do
local p2 = points[i2]

if (AreCollinear(p0, p1, p2)) then
continue
end

--for (int i3 = i2 + 1; i3 < count - 0; i3++) --@@@@
for i3 = i2 + 1, count + 1 do
local p3 = points[i3]

if(AreCoplanar(p0, p1, p2, p3)) then
continue
end
return i0, i1, i2, i3
end
end
end
end
error("Can't generate hull, points are coplanar")
end

local function GenerateInitialHull(points)
--[[
Find points suitable for use as the seed hull. Some varieties of
this algorithm pick extreme points here, but I'm not convinced
you gain all that much from that. Currently what it does is just
find the first four points that are not coplanar.
]]--

local b0, b1, b2, b3 = FindInitialHullIndices(points)

local v0 = points[b0]
local v1 = points[b1]
local v2 = points[b2]
local v3 = points[b3]

local above = Dot(v3 - v1, Cross(v1 - v0, v2 - v0)) > 0.0

--[[
Create the faces of the seed hull. You need to draw a diagram
here, otherwise it's impossible to know what's going on :)

Basically: there are two different possible start-tetrahedrons,
depending on whether the fourth point is above or below the base
triangle. If you draw a tetrahedron with these coordinates (in a
right-handed coordinate-system):

b0 = (0,0,0)
b1 = (1,0,0)
b2 = (0,1,0)
b3 = (0,0,1)

you can see the first case (set b3 = (0,0,-1) for the second
case). The faces are added with the proper references to the
faces opposite each vertex
]]--


--Bump the indices (3,1,2 etc by 1, because lua 1 array)
faceCount = 0 -- stays on 0, its the number of faces in the array: correct elsewhere!
if (above) then
faces[faceCount+1] = Face(b0, b2, b1, 3+1, 1+1, 2+1, Normal(points[b0], points[b2], points[b1]))
faceCount+=1
faces[faceCount+1] = Face(b0, b1, b3, 3+1, 2+1, 0+1, Normal(points[b0], points[b1], points[b3]))
faceCount+=1
faces[faceCount+1] = Face(b0, b3, b2, 3+1, 0+1, 1+1, Normal(points[b0], points[b3], points[b2]))
faceCount+=1
faces[faceCount+1] = Face(b1, b2, b3, 2+1, 1+1, 0+1, Normal(points[b1], points[b2], points[b3]))
faceCount+=1
else
faces[faceCount+1] = Face(b0, b1, b2, 3+1, 2+1, 1+1, Normal(points[b0], points[b1], points[b2]))
faceCount+=1
faces[faceCount+1] = Face(b0, b3, b1, 3+1, 0+1, 2+1, Normal(points[b0], points[b3], points[b1]))
faceCount+=1
faces[faceCount+1] = Face(b0, b2, b3, 3+1, 1+1, 0+1, Normal(points[b0], points[b2], points[b3]))
faceCount+=1
faces[faceCount+1] = Face(b1, b3, b2, 2+1, 0+1, 1+1, Normal(points[b1], points[b3], points[b2]))
faceCount+=1
end

--VerifyFaces(points)

--[[
Create the openSet. Add all points except the points of the seed
hull.
]]--

--for (int i = 0; i < points.Count; i++) --@@@
for i = 1, Count(points) do
if (i == b0 or i == b1 or i == b2 or i == b3) then
continue
end

--openSet.Add(PointFace(i, UNASSIGNED, 0.0))
table.insert(openSet, PointFace(i, UNASSIGNED, 0.0))
end

--[[
Add the seed hull verts to the tail of the list.
]]--

table.insert(openSet,PointFace(b0, INSIDE, NaN))
table.insert(openSet,PointFace(b1, INSIDE, NaN))
table.insert(openSet,PointFace(b2, INSIDE, NaN))
table.insert(openSet,PointFace(b3, INSIDE, NaN))
--openSet.Add(PointFace(b0, INSIDE, NaN))
--openSet.Add(PointFace(b1, INSIDE, NaN))
--openSet.Add(PointFace(b2, INSIDE, NaN))
--openSet.Add(PointFace(b3, INSIDE, NaN))

--[[
Set the openSetTail value. Last item in the array is
openSet.Count - 1, but four of the points (the verts of the seed
hull) are part of the closed set, so move openSetTail to just
before those.

(last is now #openSet !)
]]--
--openSetTail = openSet.Count - 5 --@@@@
openSetTail = Count(openSet) - 4

--assert(Count(openSet) == Count(points))

--[[
Assign all points of the open set. This does basically the same
thing as ReassignPoints()
]]--

--for (int i = 0; i <= openSetTail; i++) ----@@@@
local i = 0
while (i < openSetTail) do
i += 1

--for i = 1, openSetTail do
--assert(openSet[i].Face == UNASSIGNED)
--assert(openSet[openSetTail].Face == UNASSIGNED)
--assert(openSet[openSetTail + 1].Face == INSIDE)

local assigned = false
local fp = openSet[i]

--assert(Count(faces) == 4)
--assert(Count(faces) == faceCount)
--for (int j = 0; j < 4; j++) ---@@@@
for j = 1, 4 do
-- assert(faces[j] ~= nil)

local face = faces[j]

local dist = PointFaceDistance(points[fp.Point], points[face.Vertex0], face);

if (dist > 0) then
fp.Face = j
fp.Distance = dist
openSet[i] = fp

assigned = true
break
end
end

if (assigned == false) then
-- Point is inside
fp.Face = INSIDE
fp.Distance = NaN

--[[
Point is inside seed hull: swap point with tail, and move
openSetTail back. We also have to decrement i, because
there's a new item at openSet[i], and we need to process
it next iteration
]]--
openSet[i] = openSet[openSetTail]
openSet[openSetTail] = fp

openSetTail -= 1
i -= 1
end
end
--VerifyOpenSet(points)
end

--[[
Remove all lit faces and construct new faces from the horizon in a
"cone-like" fashion.

This is a relatively straight-forward procedure, given that the
horizon is handed to it in already sorted counter-clockwise. The
neighbors of the new faces are easy to find: they're the previous
and next faces to be constructed in the cone, as well as the face
on the other side of the horizon. We also have to update the face
on the other side of the horizon to reflect it's new neighbor from
the cone.
]]--

local function ConstructCone(points, farthestPoint)

--foreach (var fi in litFaces) ---@@
for _,fi in pairs(litFaces) do
-- assert(faces[fi] ~= nil) -- ??
--faces.Remove(fi)
faces[fi] = nil
end

local firstNewFace = faceCount --Facecount is # of faces, make sure to +1 before using it to write/read

--for (int i = 0; i < horizon.Count; i++) --@@@
for i = 1, Count(horizon) do
-- Vertices of the new face, the farthest point as well as the
-- edge on the horizon. Horizon edge is CCW, so the triangle
-- should be as well.
local v0 = farthestPoint
local v1 = horizon[i].Edge0
local v2 = horizon[i].Edge1

-- Opposite faces of the triangle. First, the edge on the other
-- side of the horizon, then the next/prev faces on the new cone
local o0 = horizon[i].Face

--local o1 = (i == horizon.Count - 1) ? firstNewFace : firstNewFace + i + 1
local o1
if (i == Count(horizon)) then --Last index --@@@@ horizon.Count-1
o1 = firstNewFace + 1
else
o1 = firstNewFace + i + 1
end

--local o2 = (i == 0) ? (firstNewFace + horizon.Count - 1) : firstNewFace + i - 1
local o2
if (i == 1) then
o2 = firstNewFace + Count(horizon)
else
o2 = firstNewFace + i - 1
end

--print(i-1, "o0", o0-1, "o1", o1-1, "o2", o2-1 )

local fi = faceCount + 1
faceCount+=1

--faces[fi] = Face( ----@@@@@@ incremented faceCount by 1, because 1 based
faces[fi] = Face(
v0, v1, v2,
o0, o1, o2,
Normal(points[v0], points[v1], points[v2]))

local horizonFace = faces[horizon[i].Face]

if (horizonFace.Vertex0 == v1) then
--assert(v2 == horizonFace.Vertex2)
horizonFace.Opposite1 = fi
elseif (horizonFace.Vertex1 == v1) then
--assert(v2 == horizonFace.Vertex0)
horizonFace.Opposite2 = fi
else
-- assert(v1 == horizonFace.Vertex2)
-- assert(v2 == horizonFace.Vertex1)
horizonFace.Opposite0 = fi
end

--@@@@@ faces[horizon[i].Face] = horizonFace
faces[horizon[i].Face] = horizonFace
end
end



--[[
Grow the hull. This method takes the current hull, and expands it
to encompass the point in openSet with the point furthest away
from its face.
]]--

local function GrowHull(points)

--print("GROW HULL", counter)
counter+=1
-- assert(openSetTail >= 0)
--assert(openSet[1].Face ~= INSIDE) -- assert(openSet[0].Face ~= INSIDE) --@@@@

-- Find farthest point and first lit face.
local farthestPoint = 1

local dist = openSet[1].Distance -----local dist = openSet[0].Distance -- @@@

--for (int i = 1; i <= openSetTail; i++) ---@@@@
for i = 2, openSetTail do
if (openSet[i].Distance > dist) then
farthestPoint = i
dist = openSet[i].Distance
end
end

-- Use lit face to find horizon and the rest of the lit
-- faces.
FindHorizon(
points,
points[openSet[farthestPoint].Point],
openSet[farthestPoint].Face,
faces[openSet[farthestPoint].Face])

--VerifyHorizon()

--Construct new cone from horizon
ConstructCone(points, openSet[farthestPoint].Point)

--VerifyFaces(points)

--Reassign points
ReassignPoints(points)
end


function module:GenerateHull(points)
if (#points < 4) then
return nil
end

faceCount = 0
openSetTail = -1
faces = {}

openSet = {}
litFaces = {}
horizon = {}

GenerateInitialHull(points)

while (openSetTail >= 1) do
GrowHull(points)
end

--unroll
local tris = {}
for key,value in pairs(faces) do
local tri = {}
table.insert(tri, points[value.Vertex0])
table.insert(tri, points[value.Vertex1])
table.insert(tri, points[value.Vertex2])
table.insert(tris, tri)
end
return tris
end

return module
replicatedfirst/Chickynoid/Shared/Vendor/ReadBuffer.lua
local module = {}

local module = {}
module.__index = module

function module.new(buf : buffer)
local self = setmetatable({
offset = 0,
buf = buf,
},module)
return self
end

function module:ResetReadPos()
self.offset = 0
end

function module:ReadU8()

local data = buffer.readu8(self.buf, self.offset)
self.offset+=1
return data
end


function module:ReadI16()
local data = buffer.readu16(self.buf, self.offset)
self.offset+=2
return data
end

function module:ReadVector3()

local x,y,z
x = buffer.readf32(self.buf, self.offset)
self.offset+=4
y = buffer.readf32(self.buf, self.offset)
self.offset+=4
z = buffer.readf32(self.buf, self.offset)
self.offset+=4
return Vector3.new(x,y,z)
end


function module:ReadFloat16()

local b0 = buffer.readu8(self.buf, self.offset)
self.offset+=1
local b1 = buffer.readu8(self.buf, self.offset)
self.offset+=1

local sign = bit32.btest(b0, 128)
local exponent = bit32.rshift(bit32.band(b0, 127), 2)
local mantissa = bit32.lshift(bit32.band(b0, 3), 8) + b1

if exponent == 31 then --2^5-1
if mantissa ~= 0 then
return (0 / 0)
else
return (sign and -math.huge or math.huge)
end
elseif exponent == 0 then
if mantissa == 0 then
return 0
else
return (sign and -math.ldexp(mantissa / 1024, -14) or math.ldexp(mantissa / 1024, -14))
end
end

mantissa = (mantissa / 1024) + 1

return (sign and -math.ldexp(mantissa, exponent - 15) or math.ldexp(mantissa, exponent - 15))
end


return module
replicatedfirst/Chickynoid/Shared/Vendor/TrianglePart.lua
local Triangle = {}

local ref = Instance.new("WedgePart")
ref.Color = Color3.fromRGB(200, 255, 200)
ref.Material = Enum.Material.SmoothPlastic
ref.Reflectance = 0
ref.Transparency = 0
ref.Name = "Tri"
ref.Anchored = true
ref.CanCollide = false
ref.CanTouch = false
ref.CanQuery = false
ref.CFrame = CFrame.new()
ref.Size = Vector3.new(0.25, 0.25, 0.25)
ref.BottomSurface = Enum.SurfaceType.Smooth
ref.TopSurface = Enum.SurfaceType.Smooth

local function fromAxes(p, x, y, z)
return CFrame.new(p.x, p.y, p.z, x.x, y.x, z.x, x.y, y.y, z.y, x.z, y.z, z.z)
end

function Triangle:Triangle(a, b, c)
local ab, ac, bc = b - a, c - a, c - b
local abl, acl, bcl = ab.magnitude, ac.magnitude, bc.magnitude
if abl > bcl and abl > acl then
c, a = a, c
elseif acl > bcl and acl > abl then
a, b = b, a
end
ab, ac, bc = b - a, c - a, c - b
local out = ac:Cross(ab).unit
local wb = ref:Clone()
local wc = ref:Clone()
local biDir = bc:Cross(out).unit
local biLen = math.abs(ab:Dot(biDir))
local norm = bc.magnitude
wb.Size = Vector3.new(0, math.abs(ab:Dot(bc)) / norm, biLen)
wc.Size = Vector3.new(0, biLen, math.abs(ac:Dot(bc)) / norm)
bc = -bc.unit
wb.CFrame = fromAxes((a + b) / 2, -out, bc, -biDir)
wc.CFrame = fromAxes((a + c) / 2, -out, biDir, bc)

return wb, wc
end

return Triangle
replicatedfirst/Chickynoid/Shared/Vendor/WriteBuffer.lua
local module = {}

local module = {}
module.__index = module

function module.new(startSize)

if (startSize == nil) then
startSize = 0
else
startSize = math.max(startSize,0)
end

local self = setmetatable({
offset = 0,
currentSize = 0,
startSize = startSize,
stepSize = 128,
buf = nil,
},module)
return self
end


function module:GetBuffer()

if (buffer.len(self.buf) == self.offset) then
return self.buf
end

local finalBuffer = buffer.create(self.offset)
self.currentSize = self.offset

buffer.copy(finalBuffer,0,self.buf,0,self.offset)
self.buf = finalBuffer
return finalBuffer
end

function module:CheckSize(add : number)

local checkSize = self.offset + add
if (self.buf == nil or checkSize > self.currentSize) then

if (self.buf == nil) then
self.currentSize = math.max(self.startSize, add)
else
self.currentSize += math.max(self.stepSize, add)
end
local newBuf = buffer.create(self.currentSize)
if (self.buf) then
buffer.copy(newBuf, 0, self.buf,0, self.offset)
end
self.buf = newBuf
end
end

function module:WriteU8(byte : number)
self:CheckSize(1)
buffer.writeu8(self.buf, self.offset, byte)
self.offset+=1
end


function module:WriteI16(u16 : number)
self:CheckSize(2)
buffer.writeu16(self.buf,self.offset, u16)
self.offset+=2
end

function module:WriteVector3(vec : Vector3)
self:CheckSize(12)
buffer.writef32(self.buf, self.offset, vec.X)
self.offset+=4
buffer.writef32(self.buf, self.offset, vec.Y)
self.offset+=4
buffer.writef32(self.buf, self.offset, vec.Z)
self.offset+=4

end


function module:WriteFloat16(value : number)
self:CheckSize(2)
local sign = value < 0
value = math.abs(value)

local mantissa, exponent = math.frexp(value)

if value == math.huge then
if sign then
buffer.writeu8(self.buf,self.offset,252)-- 11111100
self.offset+=1
else
buffer.writeu8(self.buf,self.offset,124) -- 01111100
self.offset+=1
end
buffer.writeu8(self.buf,self.offset,0) -- 00000000
self.offset+=1
return
elseif value ~= value or value == 0 then
buffer.writeu8(self.buf,self.offset,0)
self.offset+=1
buffer.writeu8(self.buf,self.offset,0)
self.offset+=1
return
elseif exponent + 15 <= 1 then -- Bias for halfs is 15
mantissa = math.floor(mantissa * 1024 + 0.5)
if sign then
buffer.writeu8(self.buf,self.offset,(128 + bit32.rshift(mantissa, 8))) -- Sign bit, 5 empty bits, 2 from mantissa
self.offset+=1
else
buffer.writeu8(self.buf,self.offset,(bit32.rshift(mantissa, 8)))
self.offset+=1
end
buffer.writeu8(self.buf,self.offset,bit32.band(mantissa, 255)) -- Get last 8 bits from mantissa
self.offset+=1
return
end

mantissa = math.floor((mantissa - 0.5) * 2048 + 0.5)

-- The bias for halfs is 15, 15-1 is 14
if sign then
buffer.writeu8(self.buf,self.offset,(128 + bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8)))
self.offset+=1
else
buffer.writeu8(self.buf,self.offset,(bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8)))
self.offset+=1
end
buffer.writeu8(self.buf,self.offset,bit32.band(mantissa, 255))
self.offset+=1
end

return module
replicatedfirst/Chickynoid/Shared/Vendor/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/Chickynoid/Shared/DebugInfo.lua
return {
DEBUG = false,
PING = 500/1000,
PACKET_LOSS = 20/100,
}
replicatedfirst/Chickynoid/Shared/Enums.lua
local Enums = {}

Enums.EventType = {
ChickynoidAdded = 0,
ChickynoidRemoving = 1,
Command = 2,
State = 3,
Snapshot = 4,
WorldState = 5,
CollisionData = 6,

WeaponDataChanged = 8,
BulletFire = 9,
BulletImpact = 10,

DebugBox = 11,

PlayerDisconnected = 12,

BallState = 13,
}
table.freeze(Enums.EventType)

Enums.NetworkProblemState = {
None = 0,
TooFarBehind = 1,
TooFarAhead = 2,
TooManyCommands = 3,
DroppedPacketGood = 4,
DroppedPacketBad = 5
}
table.freeze(Enums.NetworkProblemState)

Enums.FpsMode = {
Uncapped = 0,
Hybrid = 1,
Fixed60 = 2,
Fixed30 = 3,
}
table.freeze(Enums.FpsMode)

Enums.AnimChannel = {
Channel0 = 0,
Channel1 = 1,
Channel2 = 2,
Channel3 = 3,
}
table.freeze(Enums.AnimChannel)

Enums.WeaponData = {
WeaponAdd = 0,
WeaponRemove = 1,
WeaponState = 2,
Equip = 3,
Dequip = 4,
}
table.freeze(Enums.WeaponData)

Enums.Crashland = {
STOP = 0,
FULL_BHOP = 1,
FULL_BHOP_FORWARD = 2,
CAPPED_BHOP = 3,
CAPPED_BHOP_FORWARD = 4,

}
table.freeze(Enums.Crashland)

Enums.BallActions = {
Teleport = 0,
Shoot = 1,
Deflect = 2,
Reset = 3,
Claim = 4,
BicycleKick = 5,
PowerUpKnockback = 6,
ServerClaim = 7,
}
table.freeze(Enums.BallActions)

return Enums
replicatedfirst/Chickynoid/Shared/FootstepSounds.lua
return {
Air = {id = "rbxassetid://329997777", volume = 0, speed = 1.00},
Asphalt = {id = "rbxassetid://277067660", volume = 0.60, speed = 1.00},
Basalt = {id = "rbxassetid://3190903775", volume = 0.60, speed = 1.00},
Brick = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Cobblestone = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Concrete = {id = "rbxassetid://277067660", volume = 0.60, speed = 1.00},
CorrodedMetal = {id = "rbxassetid://177940974", volume = 0.60, speed = 1.00},
CrackedLava = {id = "rbxassetid://3190903775", volume = 0.60, speed = 1.00},
DiamondPlate = {id = "rbxassetid://177940974", volume = 0.60, speed = 1.00},
Fabric = {id = "rbxassetid://9083849830", volume = 0.40, speed = 1.00},
Foil = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Forcefield = {id = "rbxassetid://329997777", volume = 0.60, speed = 1.00},
Glass = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Granite = {id = "rbxassetid://178054124", volume = 0.60, speed = 1.00},
Grass = {id = "rbxassetid://9064714296", volume = 0.60, speed = 1.00},
Glacier = {id = "rbxassetid://7047108275", volume = 0.40, speed = 1.00},
Ground = {id = "rbxassetid://9064714296", volume = 0.60, speed = 1.00},
Ice = {id = "rbxassetid://7047108275", volume = 0.40, speed = 1.00},
Limestone = {id = "rbxassetid://9083846829", volume = 0.60, speed = 1.00},
LeafyGrass = {id = "rbxassetid://3098847639", volume = 0.60, speed = 1.00},
Marble = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Metal = {id = "rbxassetid://177940974", volume = 0.60, speed = 1.00},
Mud = {id = "rbxassetid://6441160246", volume = 0.60, speed = 1.00},
Neon = {id = "rbxassetid://177940974", volume = 0.60, speed = 1.00},
Pebble = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Plastic = {id = "rbxassetid://4416041299", volume = 0.60, speed = 1.40},
Pavement = {id = "rbxassetid://277067660", volume = 0.60, speed = 1.00},
Rock = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Sand = {id = "rbxassetid://9083846829", volume = 0.40, speed = 1.00},
Slate = {id = "rbxassetid://178054124", volume = 0.60, speed = 1.00},
Snow = {id = "rbxassetid://8453425942", volume = 0.60, speed = 1.00},
Salt = {id = "rbxassetid://9083846829", volume = 0.40, speed = 1.00},
Sandstone = {id = "rbxassetid://3190903775", volume = 0.60, speed = 0.75},
SmoothPlastic = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Wood = {id = "rbxassetid://3199270096", volume = 0.60, speed = 1.00},
WoodPlanks = {id = "rbxassetid://211987063", volume = 0.60, speed = 1.00}
}
replicatedfirst/Chickynoid/Shared/Types.lua
--[=[
@class Types
All types used by Chickynoid.
]=]

--[=[
@interface ISimulationConfig
@within Types
.raycastWhitelist {BasePart} -- Raycast whitelist used for collision checks.
.feetHeight number -- Players feet height. Height goes from -2.5 to +2.5 so any point below this number is considered the players feet. The distance between middle and feetHeight is "ledge".
.stepSize number -- How big an object we can step over?

The config passed to the Chickynoid [Simulation] class.
]=]
export type ISimulationConfig = {
raycastWhitelist: { BasePart },
feetHeight: number,
stepSize: number,
}

--[=[
@interface IServerConfig
@within Types
.simulationConfig ISimulationConfig -- The config passed to the Chickynoid [Simulation] class.
]=]
export type IServerConfig = {
simulationConfig: ISimulationConfig,
}

--[=[
@interface IClientConfig
@within Types
.simulationConfig ISimulationConfig -- The config passed to the Chickynoid [Simulation] class.
]=]
export type IClientConfig = {
simulationConfig: ISimulationConfig,
}

return nil
replicatedfirst/Chickynoid/Shared/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/Chickynoid/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/LoadingScreen/init.client.lua
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local loadingGui: ScreenGui = script:WaitForChild("LoadingScreen")
loadingGui.Parent = playerGui

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)


ContextActionService:BindAction("FreezeInputs", function()
return Enum.ContextActionResult.Sink
end, false, unpack(Enum.PlayerActions:GetEnumItems()))

local function checkFullyLoaded()
for _, loaded in pairs(loadingGui:GetAttributes()) do
if not loaded then
return
end
end
loadingGui:Destroy()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)

ContextActionService:UnbindAction("FreezeInputs")

localPlayer:SetAttribute("ClientLoaded", true)

script:Destroy()
end

localPlayer.CharacterAdded:Connect(function()
loadingGui:SetAttribute("Character", true)
end)

if not game:IsLoaded() then
game.Loaded:Wait()
end
for attributeName in pairs(loadingGui:GetAttributes()) do
loadingGui:GetAttributeChangedSignal(attributeName):Connect(function()
print(attributeName .. " loaded!")
checkFullyLoaded()
end)
end
replicatedfirst/LoadingScreen/init.meta.json
{
"ignoreUnknownInstances": true
}
replicatedfirst/BallCompatibility.client.lua
local Players = game:GetService("Players")


local function addPlayer(player: Player)
local ballObject = Instance.new("ObjectValue")
ballObject.Name = "Ball"
ballObject.Parent = player

local conn: RBXScriptConnection?
ballObject:GetPropertyChangedSignal("Parent"):Connect(function()
if conn then
conn:Disconnect()
conn = nil
end
end)
ballObject.Changed:Connect(function(ball: BasePart | nil)
if conn then
conn:Disconnect()
conn = nil
end
if ball == nil then
return
end
conn = ball.BallOwner.Changed:Connect(function(newOwner: Player | nil)
if newOwner == player then return end
ballObject.Value = nil
end)
end)
end

Players.PlayerAdded:Connect(addPlayer)
for _, player in pairs(Players:GetPlayers()) do
addPlayer(player)
end
replicatedfirst/CoreScripts.client.lua
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
replicatedfirst/GameInfo.lua
return {

MAX_TEAM_PLAYERS = 6,

SPRINT_STAMINA_CONSUMPTION = 5,
JUMP_STAMINA_CONSUMPTION = 4,
DIVE_STAMINA_CONSUMPTION = 16,


CAMERA_OFFSET = Vector3.new(0, 1.5, 0),

MAX_STAMINA = 200,
STAMINA_REGEN = 20,

SHOT_CHARGE_MULTIPLIER = 2,
SHOT_RECEDE_MULTIPLIER = 4,

CURVE_FACTOR_CHARGE_MULTIPLIER = 1.5,
CURVE_FACTOR_RECEDE_MULTIPLIER = 8.5,
MAXIMUM_CURVE_FACTOR = 3.3,
MINIMUM_CURVE_FACTOR = 0.3,

SHOT_DISTANCE_MULTIPLIER = 1,

DIVE_COOLDOWN = 1,
DIVE_VELOCITY_DURATION = 0.5,
DIVE_DURATION = 0.4,

TACKLE_FRICTION = 0.19,
TACKLE_VELOCITY_DURATION = 0.4,
TACKLE_DURATION = 0.6,
SKILL_DURATION = 0.7,

TACKLE_RAGDOLL_TIME = 2,

}
replicatedfirst/Lib.luau
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local GameInfo = require(ReplicatedStorage.Data.GameInfo)

local Trove = require(ReplicatedStorage.Modules.Trove)

local serverInfo: Configuration = ReplicatedStorage.ServerInfo

local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera

local homeTeam: Team, awayTeam: Team = Teams.Home, Teams.Away


local Lib = {}

-- Server
function Lib.clampToBoundary(position: Vector3, boundary: BasePart)
local boundaryPos = boundary.CFrame.Position
local boundarySize = boundary.Size
return Vector3.new(
math.clamp(position.X, boundaryPos.X - boundarySize.X/2, boundaryPos.X + boundarySize.X/2),
math.clamp(position.Y, boundaryPos.Y - boundarySize.Y/2, boundaryPos.Y + boundarySize.Y/2),
math.clamp(position.Z, boundaryPos.Z - boundarySize.Z/2, boundaryPos.Z + boundarySize.Z/2)
)
end

-- Client
function Lib.playerInGameOrPaused(player: Player?): boolean | nil
player = player or localPlayer
if player == nil then
return warn("Couldn't find player!")
end
local gameStatus = serverInfo:GetAttribute("GameStatus")
return (gameStatus == "InProgress" or gameStatus == "Paused" or gameStatus == "Practice") and (player.Team == homeTeam or player.Team == awayTeam)
end

function Lib.playerInGameOrPausedOrEnded(player: Player?): boolean | nil
player = player or localPlayer
if player == nil then
return warn("Couldn't find player!")
end
local gameStatus = serverInfo:GetAttribute("GameStatus")
return (gameStatus == "InProgress" or gameStatus == "Paused" or gameStatus == "GameEnded" or gameStatus == "Practice") and (player.Team == homeTeam or player.Team == awayTeam)
end

function Lib.getHumanoid(player: Player?): Humanoid | nil
player = player or localPlayer
if player == nil then
return warn("Couldn't find player!")
end

local character = player.Character
local humanoid = character and character:FindFirstChild("Humanoid")
return humanoid
end

-- Shared
function Lib.getShotVelocity(gravity: number, shotType: string, shotPower: number, shotDirection: Vector3, curveFactor: number?)
local basePower = 50
if shotType == "DeflectShoot" then
basePower = 50
end

local multiplier = 0.5
shotPower *= multiplier
shotPower += basePower

local shotVelocity = shotDirection.Unit * shotPower * GameInfo.SHOT_DISTANCE_MULTIPLIER

local vel, angVel = shotVelocity, Vector3.zero
if curveFactor and math.abs(curveFactor) > GameInfo.MINIMUM_CURVE_FACTOR and shotDirection.Y > 0.3 then
if shotPower < 70 then
curveFactor *= ((shotPower/70)^1.6)
end

local realCurveFactor = curveFactor - math.sign(curveFactor) * GameInfo.MINIMUM_CURVE_FACTOR
-- print(realCurveFactor)
local ratio = math.abs(realCurveFactor) / (GameInfo.MAXIMUM_CURVE_FACTOR - GameInfo.MINIMUM_CURVE_FACTOR)
vel *= Vector3.new(1 - ratio*0.2, 1 - ratio*0.2, 1 - ratio*0.2)

angVel = -Vector3.yAxis * realCurveFactor * 8
end
return vel, angVel
end

function Lib.getShotDirection()
local humanoidRootPart = localPlayer.Character.HumanoidRootPart :: BasePart

local shotDirection = (currentCamera.CFrame.Position + currentCamera.CFrame.LookVector*1000) - humanoidRootPart.CFrame.Position
shotDirection = (shotDirection.Unit + Vector3.new(0, 0.5, 0)).Unit
return shotDirection
end


function Lib.playerInGame(player: Player): boolean | nil
player = player or localPlayer
if player == nil then
return warn("Couldn't find player!")
end

local gameStatus = serverInfo:GetAttribute("GameStatus")
return (gameStatus == "InProgress" or gameStatus == "Practice")
and (player.Team == homeTeam or player.Team == awayTeam)
end

function Lib.playerIsStunned(player: Player?)
player = player or localPlayer
return player:GetAttribute("ServerChickyRagdoll") or player:GetAttribute("ServerChickyFrozen")
end


function Lib.generateShortGUID()
local guid = HttpService:GenerateGUID(false)
guid = guid:gsub("-", "")
return string.lower(guid)
end


function Lib.setCooldown(instance: Instance, attribute: string, cooldown: number)
local now = workspace:GetServerTimeNow()
local currentCD = instance:GetAttribute(attribute)
if currentCD and currentCD - now > cooldown then
return
end
instance:SetAttribute(attribute, now + cooldown)

local trove = Trove.new()
trove:AttachToInstance(instance)
trove:Add(task.delay(cooldown, function()
trove:Destroy()
instance:SetAttribute(attribute, nil)
end))
trove:Connect(instance:GetAttributeChangedSignal(attribute), function()
trove:Destroy()
end)
end

function Lib.removeCooldown(instance: Instance, attribute: string)
instance:SetAttribute(attribute, nil)
end

function Lib.getCooldown(instance: Instance, attribute: string)
local value = instance:GetAttribute(attribute)
return value and math.max(0, value - workspace:GetServerTimeNow())
end

function Lib.isOnCooldown(instance: Instance, attribute: string, lagCompensation: number | nil)
local value = instance:GetAttribute(attribute)
if value and lagCompensation then
value += lagCompensation
end
return value and value - workspace:GetServerTimeNow() > 0
end


function Lib.setHiddenCooldown(instance: Instance, attribute: string, cooldown: number)
if not instance:IsA("Player") then
return
end
instance = instance.HiddenAttributes.Value

local now = workspace:GetServerTimeNow()
local currentCD = instance:GetAttribute(attribute)
if currentCD and currentCD - now > cooldown then
return
end
instance:SetAttribute(attribute, now + cooldown)

local trove = Trove.new()
trove:AttachToInstance(instance)
trove:Add(task.delay(cooldown, function()
trove:Destroy()
instance:SetAttribute(attribute, nil)
end))
trove:Connect(instance:GetAttributeChangedSignal(attribute), function()
trove:Destroy()
end)
end

function Lib.removeHiddenCooldown(instance: Instance, attribute: string)
if not instance:IsA("Player") then
return
end
instance = instance.HiddenAttributes.Value

instance:SetAttribute(attribute, nil)
end

function Lib.getHiddenCooldown(instance: Instance, attribute: string)
if not instance:IsA("Player") then
return
end
instance = instance.HiddenAttributes.Value

local value = instance:GetAttribute(attribute)
return value and math.max(0, value - workspace:GetServerTimeNow())
end

function Lib.isOnHiddenCooldown(instance: Instance, attribute: string, lagCompensation: number | nil)
if not instance:IsA("Player") then
return
end
instance = instance.HiddenAttributes.Value

local value = instance:GetAttribute(attribute)
if value and lagCompensation then
value += lagCompensation
end
return value and value - workspace:GetServerTimeNow() > 0
end


function Lib.getHiddenAttribute(player: Player, attribute: string)
if not player:IsA("Player") then
return
end
local hiddenAttributes = player:WaitForChild("HiddenAttributes", 3)
if hiddenAttributes == nil then
return
end
hiddenAttributes = hiddenAttributes.Value
return hiddenAttributes:GetAttribute(attribute)
end

function Lib.setHiddenAttribute(player: Player, attribute: string, value: any)
if not player:IsA("Player") then
return
end
local hiddenAttributes = player:WaitForChild("HiddenAttributes", 3)
if hiddenAttributes == nil then
return
end
hiddenAttributes = hiddenAttributes.Value
return hiddenAttributes:SetAttribute(attribute, value)
end

function Lib.getHiddenAttributeChangedSignal(player: Player, attribute: string)
if not player:IsA("Player") then
return
end
local hiddenAttributes = player:WaitForChild("HiddenAttributes", 3)
if hiddenAttributes == nil then
return
end
hiddenAttributes = hiddenAttributes.Value
return hiddenAttributes:GetAttributeChangedSignal(attribute)
end

return Lib
replicatedfirst/init.meta.json
{
"ignoreUnknownInstances": true
}
src/StarterPlayerScripts/RbxCharacterSounds/AtomicBinding.lua
--!nonstrict
local ROOT_ALIAS = "root"

local function parsePath(pathStr)
local pathArray = string.split(pathStr, "/")
for idx = #pathArray, 1, -1 do
if pathArray[idx] == "" then
table.remove(pathArray, idx)
end
end
return pathArray
end

local function isManifestResolved(resolvedManifest, manifestSizeTarget)
local manifestSize = 0
for _ in pairs(resolvedManifest) do
manifestSize += 1
end

assert(manifestSize <= manifestSizeTarget, manifestSize)
return manifestSize == manifestSizeTarget
end

local function unbindNodeDescend(node, resolvedManifest)
if node.instance == nil then
return -- Do not try to unbind nodes that are already unbound
end

node.instance = nil

local connections = node.connections
if connections then
for _, conn in ipairs(connections) do
conn:Disconnect()
end
table.clear(connections)
end

if resolvedManifest and node.alias then
resolvedManifest[node.alias] = nil
end

local children = node.children
if children then
for _, childNode in pairs(children) do
unbindNodeDescend(childNode, resolvedManifest)
end
end
end

local AtomicBinding = {}
AtomicBinding.__index = AtomicBinding

function AtomicBinding.new(manifest, boundFn)
local dtorMap = {} -- { [root] -> dtor }
local connections = {} -- { Connection, ... }
local rootInstToRootNode = {} -- { [root] -> rootNode }
local rootInstToManifest = {} -- { [root] -> { [alias] -> instance } }

local parsedManifest = {} -- { [alias] = {Name, ...} }
local manifestSizeTarget = 1 -- Add 1 because root isn't explicitly on the manifest

for alias, rawPath in pairs(manifest) do
parsedManifest[alias] = parsePath(rawPath)
manifestSizeTarget += 1
end

return setmetatable({
_boundFn = boundFn,
_parsedManifest = parsedManifest,
_manifestSizeTarget = manifestSizeTarget,

_dtorMap = dtorMap,
_connections = connections,
_rootInstToRootNode = rootInstToRootNode,
_rootInstToManifest = rootInstToManifest,
}, AtomicBinding)
end

function AtomicBinding:_startBoundFn(root, resolvedManifest)
local boundFn = self._boundFn
local dtorMap = self._dtorMap

local oldDtor = dtorMap[root]
if oldDtor then
oldDtor()
dtorMap[root] = nil
end

local dtor = boundFn(resolvedManifest)
if dtor then
dtorMap[root] = dtor
end
end

function AtomicBinding:_stopBoundFn(root)
local dtorMap = self._dtorMap

local dtor = dtorMap[root]
if dtor then
dtor()
dtorMap[root] = nil
end
end

function AtomicBinding:bindRoot(root)
debug.profilebegin("AtomicBinding:BindRoot")

local parsedManifest = self._parsedManifest
local rootInstToRootNode = self._rootInstToRootNode
local rootInstToManifest = self._rootInstToManifest
local manifestSizeTarget = self._manifestSizeTarget

assert(rootInstToManifest[root] == nil)

local resolvedManifest = {}
rootInstToManifest[root] = resolvedManifest

debug.profilebegin("BuildTree")

local rootNode = {}
rootNode.alias = ROOT_ALIAS
rootNode.instance = root
if next(parsedManifest) then
-- No need to assign child data if there are no children
rootNode.children = {}
rootNode.connections = {}
end

rootInstToRootNode[root] = rootNode

for alias, parsedPath in pairs(parsedManifest) do
local parentNode = rootNode

for idx, childName in ipairs(parsedPath) do
local leaf = idx == #parsedPath
local childNode = parentNode.children[childName] or {}

if leaf then
if childNode.alias ~= nil then
error("Multiple aliases assigned to one instance")
end

childNode.alias = alias

else
childNode.children = childNode.children or {}
childNode.connections = childNode.connections or {}
end

parentNode.children[childName] = childNode
parentNode = childNode
end
end

debug.profileend() -- BuildTree

-- Recursively descend into the tree, resolving each node.
-- Nodes start out as empty and instance-less; the resolving process discovers instances to map to nodes.
local function processNode(node)
local instance = assert(node.instance)

local children = node.children
local alias = node.alias
local isLeaf = not children

if alias then
resolvedManifest[alias] = instance
end

if not isLeaf then
local function processAddChild(childInstance)
local childName = childInstance.Name
local childNode = children[childName]
if not childNode or childNode.instance ~= nil then
return
end

childNode.instance = childInstance
processNode(childNode)
end

local function processDeleteChild(childInstance)
-- Instance deletion - Parent A detects that child B is being removed
-- 1. A removes B from `children`
-- 2. A traverses down from B,
-- i. Disconnecting inputs
-- ii. Removing nodes from the resolved manifest
-- 3. stopBoundFn is called because we know the tree is no longer complete, or at least has to be refreshed
-- 4. We search A for a replacement for B, and attempt to re-resolve using that replacement if it exists.
-- To support the above sanely, processAddChild needs to avoid resolving nodes that are already resolved.

local childName = childInstance.Name
local childNode = children[childName]

if not childNode then
return -- There's no child node corresponding to the deleted instance, ignore
end

if childNode.instance ~= childInstance then
return -- A child was removed with the same name as a node instance, ignore
end

self:_stopBoundFn(root) -- Happens before the tree is unbound so the manifest is still valid in the destructor.
unbindNodeDescend(childNode, resolvedManifest) -- Unbind the tree

assert(childNode.instance == nil) -- If this triggers, unbindNodeDescend failed

-- Search for a replacement
local replacementChild = instance:FindFirstChild(childName)
if replacementChild then
processAddChild(replacementChild)
end
end

for _, child in ipairs(instance:GetChildren()) do
processAddChild(child)
end

table.insert(node.connections, instance.ChildAdded:Connect(processAddChild))
table.insert(node.connections, instance.ChildRemoved:Connect(processDeleteChild))
end

if isLeaf and isManifestResolved(resolvedManifest, manifestSizeTarget) then
self:_startBoundFn(root, resolvedManifest)
end
end

debug.profilebegin("ResolveTree")
processNode(rootNode)
debug.profileend() -- ResolveTree

debug.profileend() -- AtomicBinding:BindRoot
end

function AtomicBinding:unbindRoot(root)
local rootInstToRootNode = self._rootInstToRootNode
local rootInstToManifest = self._rootInstToManifest

self:_stopBoundFn(root)

local rootNode = rootInstToRootNode[root]
if rootNode then
local resolvedManifest = assert(rootInstToManifest[root])
unbindNodeDescend(rootNode, resolvedManifest)
rootInstToRootNode[root] = nil
end

rootInstToManifest[root] = nil
end

function AtomicBinding:destroy()
debug.profilebegin("AtomicBinding:destroy")

for _, dtor in pairs(self._dtorMap) do
dtor:destroy()
end
table.clear(self._dtorMap)

for _, conn in ipairs(self._connections) do
conn:Disconnect()
end
table.clear(self._connections)

local rootInstToManifest = self._rootInstToManifest
for rootInst, rootNode in pairs(self._rootInstToRootNode) do
local resolvedManifest = assert(rootInstToManifest[rootInst])
unbindNodeDescend(rootNode, resolvedManifest)
end
table.clear(self._rootInstToManifest)
table.clear(self._rootInstToRootNode)

debug.profileend()
end

return AtomicBinding
src/StarterPlayerScripts/RbxCharacterSounds/FootstepSounds.lua
return {
Air = {id = "rbxassetid://329997777", volume = 0, speed = 1.00},
Asphalt = {id = "rbxassetid://277067660", volume = 0.60, speed = 1.00},
Basalt = {id = "rbxassetid://3190903775", volume = 0.60, speed = 1.00},
Brick = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Cobblestone = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Concrete = {id = "rbxassetid://277067660", volume = 0.60, speed = 1.00},
CorrodedMetal = {id = "rbxassetid://177940974", volume = 0.60, speed = 1.00},
CrackedLava = {id = "rbxassetid://3190903775", volume = 0.60, speed = 1.00},
DiamondPlate = {id = "rbxassetid://177940974", volume = 0.60, speed = 1.00},
Fabric = {id = "rbxassetid://9083849830", volume = 0.40, speed = 1.00},
Foil = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Forcefield = {id = "rbxassetid://329997777", volume = 0.60, speed = 1.00},
Glass = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Granite = {id = "rbxassetid://178054124", volume = 0.60, speed = 1.00},
Grass = {id = "rbxassetid://9064714296", volume = 0.60, speed = 1.00},
Glacier = {id = "rbxassetid://7047108275", volume = 0.40, speed = 1.00},
Ground = {id = "rbxassetid://9064714296", volume = 0.60, speed = 1.00},
Ice = {id = "rbxassetid://7047108275", volume = 0.40, speed = 1.00},
Limestone = {id = "rbxassetid://9083846829", volume = 0.60, speed = 1.00},
LeafyGrass = {id = "rbxassetid://3098847639", volume = 0.60, speed = 1.00},
Marble = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Metal = {id = "rbxassetid://177940974", volume = 0.60, speed = 1.00},
Mud = {id = "rbxassetid://6441160246", volume = 0.60, speed = 1.00},
Neon = {id = "rbxassetid://177940974", volume = 0.60, speed = 1.00},
Pebble = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Plastic = {id = "rbxassetid://4416041299", volume = 0.60, speed = 1.40},
Pavement = {id = "rbxassetid://277067660", volume = 0.60, speed = 1.00},
Rock = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Sand = {id = "rbxassetid://9083846829", volume = 0.40, speed = 1.00},
Slate = {id = "rbxassetid://178054124", volume = 0.60, speed = 1.00},
Snow = {id = "rbxassetid://8453425942", volume = 0.60, speed = 1.00},
Salt = {id = "rbxassetid://9083846829", volume = 0.40, speed = 1.00},
Sandstone = {id = "rbxassetid://3190903775", volume = 0.60, speed = 0.75},
SmoothPlastic = {id = "rbxassetid://178190837", volume = 0.60, speed = 1.00},
Wood = {id = "rbxassetid://3199270096", volume = 0.60, speed = 1.00},
WoodPlanks = {id = "rbxassetid://211987063", volume = 0.60, speed = 1.00}
}
src/StarterPlayerScripts/RbxCharacterSounds/init.client.lua
--!nonstrict
-- Roblox character sound script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AtomicBinding = require(script:WaitForChild("AtomicBinding"))
local FootstepSounds = require(script:WaitForChild("FootstepSounds"))

local Trove = require(ReplicatedStorage.Modules.Trove)

local function loadFlag(flag: string)
local success, result = pcall(function()
return UserSettings():IsUserFeatureEnabled(flag)
end)
return success and result
end

local FFlagUserSoundsUseRelativeVelocity = loadFlag('UserSoundsUseRelativeVelocity2')

local SOUND_DATA : { [string]: {[string]: any}} = {
Climbing = {
SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3",
Looped = true,
},
Died = {
SoundId = "rbxasset://sounds/uuhhh.mp3",
},
FreeFalling = {
SoundId = "rbxasset://sounds/action_falling.mp3",
Looped = true,
},
GettingUp = {
SoundId = "rbxasset://sounds/action_get_up.mp3",
},
Jumping = {
SoundId = "rbxasset://sounds/action_jump.mp3",
},
Landing = {
SoundId = "rbxasset://sounds/action_jump_land.mp3",
},
Running = {
SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3",
Looped = true,
Pitch = 1.85,
},
Splash = {
SoundId = "rbxasset://sounds/impact_water.mp3",
},
Swimming = {
SoundId = "rbxasset://sounds/action_swim.mp3",
Looped = true,
Pitch = 1.6,
},
}

-- map a value from one range to another
local function map(x: number, inMin: number, inMax: number, outMin: number, outMax: number): number
return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
end

local function getRelativeVelocity(cm, velocity)
if not cm then
return velocity
end
local activeSensor = cm.ActiveController and
(
(cm.ActiveController:IsA("GroundController") and cm.GroundSensor) or
(cm.ActiveController:IsA("ClimbController") and cm.ClimbSensor)
)
if activeSensor and activeSensor.SensedPart then
-- Calculate the platform relative velocity by subtracting the velocity of the surface we're attached to or standing on.
local platformVelocity = activeSensor.SensedPart:GetVelocityAtPosition(cm.RootPart.Position)
return velocity - platformVelocity
end
return velocity
end

local function playSound(sound: Sound)
sound.TimePosition = 0
sound.Playing = true
end

local function initializeSoundSystem(instances)
local trove = Trove.new()

local humanoid: Humanoid = instances.humanoid
local rootPart: BasePart = instances.rootPart

local cm = nil
if FFlagUserSoundsUseRelativeVelocity then
local character = humanoid.Parent
cm = character:FindFirstChild('ControllerManager')
end

local sounds: {[string]: Sound} = {}

-- initialize sounds
for name: string, props: {[string]: any} in pairs(SOUND_DATA) do
local sound: Sound = Instance.new("Sound")
sound.Name = name
trove:Add(sound)

-- set default values
sound.Archivable = false
sound.RollOffMinDistance = 5
sound.RollOffMaxDistance = 150
sound.Volume = 0.65

for propName, propValue: any in pairs(props) do
(sound :: any)[propName] = propValue
end

sound.Parent = rootPart
sounds[name] = sound
end

local playingLoopedSounds: {[Sound]: boolean?} = {}

local function stopPlayingLoopedSounds(except: Sound?)
for sound in pairs(table.clone(playingLoopedSounds)) do
if sound ~= except then
sound.Playing = false
playingLoopedSounds[sound] = nil
end
end
end

-- state transition callbacks.
local stateTransitions: {[Enum.HumanoidStateType]: () -> ()} = {
[Enum.HumanoidStateType.FallingDown] = function()
stopPlayingLoopedSounds()
end,

[Enum.HumanoidStateType.GettingUp] = function()
stopPlayingLoopedSounds()
playSound(sounds.GettingUp)
end,

[Enum.HumanoidStateType.Jumping] = function()
stopPlayingLoopedSounds()
playSound(sounds.Jumping)
end,

[Enum.HumanoidStateType.Swimming] = function()
local verticalSpeed = math.abs(rootPart.AssemblyLinearVelocity.Y)
if verticalSpeed > 0.1 then
sounds.Splash.Volume = math.clamp(map(verticalSpeed, 100, 350, 0.28, 1), 0, 1)
playSound(sounds.Splash)
end
stopPlayingLoopedSounds(sounds.Swimming)
sounds.Swimming.Playing = true
playingLoopedSounds[sounds.Swimming] = true
end,

[Enum.HumanoidStateType.Freefall] = function()
sounds.FreeFalling.Volume = 0
stopPlayingLoopedSounds(sounds.FreeFalling)
playingLoopedSounds[sounds.FreeFalling] = true
end,

[Enum.HumanoidStateType.Landed] = function()
stopPlayingLoopedSounds()
local verticalSpeed = math.abs(rootPart.AssemblyLinearVelocity.Y)
if verticalSpeed > 75 then
sounds.Landing.Volume = math.clamp(map(verticalSpeed, 50, 100, 0, 1), 0, 1)
playSound(sounds.Landing)
end
end,

[Enum.HumanoidStateType.Running] = function()
stopPlayingLoopedSounds(sounds.Running)
sounds.Running.Playing = true
playingLoopedSounds[sounds.Running] = true
end,

[Enum.HumanoidStateType.Climbing] = function()
local sound = sounds.Climbing
local partVelocity = rootPart.AssemblyLinearVelocity
local velocity = if FFlagUserSoundsUseRelativeVelocity then getRelativeVelocity(cm, partVelocity) else partVelocity
if math.abs(velocity.Y) > 0.1 then
sound.Playing = true
stopPlayingLoopedSounds(sound)
else
stopPlayingLoopedSounds()
end
playingLoopedSounds[sound] = true
end,

[Enum.HumanoidStateType.Seated] = function()
stopPlayingLoopedSounds()
end,

[Enum.HumanoidStateType.Dead] = function()
stopPlayingLoopedSounds()
playSound(sounds.Died)
end,
}

-- updaters for looped sounds
local loopedSoundUpdaters: {[Sound]: (number, Sound, Vector3) -> ()} = {
[sounds.Climbing] = function(_, sound: Sound, vel: Vector3)
local velocity = if FFlagUserSoundsUseRelativeVelocity then getRelativeVelocity(cm, vel) else vel
sound.Playing = velocity.Magnitude > 0.1
end,

[sounds.FreeFalling] = function(dt: number, sound: Sound, vel: Vector3): ()
if vel.Magnitude > 75 then
sound.Volume = math.clamp(sound.Volume + 0.9*dt, 0, 1)
else
sound.Volume = 0
end
end,

[sounds.Running] = function(_, sound: Sound, vel: Vector3)
sound.Playing = vel.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5
end,
}

-- state substitutions to avoid duplicating entries in the state table
local stateRemap: {[Enum.HumanoidStateType]: Enum.HumanoidStateType} = {
[Enum.HumanoidStateType.RunningNoPhysics] = Enum.HumanoidStateType.Running,
}

local activeState: Enum.HumanoidStateType = stateRemap[humanoid:GetState()] or humanoid:GetState()

local function transitionTo(state)
local transitionFunc: () -> () = stateTransitions[state]

if transitionFunc then
transitionFunc()
end

activeState = state
end

transitionTo(activeState)

-- trove:Connect(humanoid.StateChanged, function(_, state)
-- state = stateRemap[state] or state

-- if state ~= activeState then
-- transitionTo(state)
-- end
-- end)
-- trove:Connect(RunService.Stepped, function(_, worldDt: number)
-- -- update looped sounds on stepped
-- for sound in pairs(playingLoopedSounds) do
-- local updater: (number, Sound, Vector3) -> () = loopedSoundUpdaters[sound]

-- if updater then
-- updater(worldDt, sound, rootPart.AssemblyLinearVelocity)
-- end
-- end
-- end)


local function terminate()
trove:Destroy()
table.clear(sounds)
end

return terminate
end

local binding = AtomicBinding.new({
humanoid = "Humanoid",
rootPart = "HumanoidRootPart",
}, initializeSoundSystem)

local playerConnections = {}

local function characterAdded(character)
binding:bindRoot(character)
end

local function characterRemoving(character)
binding:unbindRoot(character)
end

local function playerAdded(player: Player)
local connections = playerConnections[player]
if not connections then
connections = {}
playerConnections[player] = connections
end

if player.Character then
characterAdded(player.Character)
end
table.insert(connections, player.CharacterAdded:Connect(characterAdded))
table.insert(connections, player.CharacterRemoving:Connect(characterRemoving))
end

local function playerRemoving(player: Player)
local connections = playerConnections[player]
if connections then
for _, conn in ipairs(connections) do
conn:Disconnect()
end
playerConnections[player] = nil
end

if player.Character then
characterRemoving(player.Character)
end
end

for _, player in ipairs(Players:GetPlayers()) do
task.spawn(playerAdded, player)
end
Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)
src/client/Controllers/UIController/Overlays/Controls.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lib = require(ReplicatedStorage.Lib)

local serverInfo: Configuration = ReplicatedStorage.ServerInfo

local assets = ReplicatedStorage.Assets
local baseGUI = assets.GUI.Base

local localPlayer = Players.LocalPlayer


local Controls = {}
Controls.__index = Controls

function Controls.new()
local self = setmetatable({}, Controls)
self.gui = baseGUI.Controls:Clone()

return self
end

function Controls:Init()
self.gui.Enabled = false

local function updateVisibility()
self.gui.Enabled = Lib.playerInGameOrPaused()
end
updateVisibility()
serverInfo:GetAttributeChangedSignal("GameStatus"):Connect(updateVisibility)
localPlayer:GetPropertyChangedSignal("Team"):Connect(updateVisibility)
end

return Controls
src/client/Controllers/UIController/Overlays/EmoteWheel.lua
local ContextActionService = game:GetService("ContextActionService")
local GamepadService = game:GetService("GamepadService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local EmoteService = Knit.GetService("EmoteService")

local Keybinds = require(ReplicatedStorage.Data.Keybinds)

local assets = ReplicatedStorage.Assets
local baseGUI = assets.GUI.Base

local localPlayer = Players.LocalPlayer


local EmoteWheel = {}
EmoteWheel.__index = EmoteWheel

EmoteWheel.gui = nil :: ScreenGui?

function EmoteWheel.new()
local self = setmetatable({}, EmoteWheel)
self.gui = baseGUI.EmoteWheel:Clone()

return self
end

function EmoteWheel:Init()
local container = self.gui.Container
for _, slotButton: TextButton in pairs(container.Slots:GetChildren()) do
self:AddEmoteSlot(slotButton)
end

ContextActionService:BindActionAtPriority("Emote", function(_, inputState)
if inputState == Enum.UserInputState.Begin then
local character = localPlayer.Character
local emoteData = character and character:GetAttribute("EmoteData")
if emoteData then
emoteData = HttpService:JSONDecode(emoteData)
local emote = emoteData[1]
if emote then
local emoteGUID = emoteData[2]
EmoteService:EndEmote(emoteGUID)
return
end
end
self.gui.Enabled = not self.gui.Enabled
end
end, false, 1, Keybinds.PC.Emote, Keybinds.Console.Emote)

-- Gamepad Navigation
if not UserInputService.GamepadEnabled then
return
end
self.gui:GetPropertyChangedSignal("Enabled"):Connect(function()
if self.gui.Enabled then
GamepadService:EnableGamepadCursor(container.Slots['1'])
else
GamepadService:DisableGamepadCursor()
end
end)
end

function EmoteWheel:AddEmoteSlot(slotButton: TextButton)
local slotNumber = tonumber(slotButton.Name)
slotButton.Activated:Connect(function()
self.gui.Enabled = false
EmoteService:UseEmote(slotNumber)
end)
end

return EmoteWheel
src/client/Controllers/UIController/Overlays/PowerBar.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local privateServerInfo: Configuration = ReplicatedStorage.PrivateServerInfo

local assets = ReplicatedStorage.Assets
local baseGUI = assets.GUI.Base

local localPlayer = Players.LocalPlayer


local PowerBar = {}
PowerBar.__index = PowerBar

function PowerBar.new()
local self = setmetatable({}, PowerBar)
self.gui = baseGUI.PowerBar:Clone()

return self
end

function PowerBar:Init()
self.gui.Enabled = false

local container = self.gui.Container

local lastPower = 0
localPlayer:GetAttributeChangedSignal("ShotPower"):Connect(function()
local ratio = localPlayer:GetAttribute("ShotPower") / privateServerInfo:GetAttribute("MaxShotPower")
ratio = math.min(1, ratio)
container.Background.Bar.Size = UDim2.fromScale(ratio, 1)

local currentPower = localPlayer:GetAttribute("ShotPower")
local difference = currentPower - lastPower
lastPower = currentPower
self.gui.Enabled = difference > 0
end)
end

return PowerBar
src/client/Controllers/UIController/Overlays/Scoreboard.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverInfo: Configuration = ReplicatedStorage.ServerInfo

local assets = ReplicatedStorage.Assets
local baseGUI = assets.GUI.Base

local localPlayer = Players.LocalPlayer


local Scoreboard = {}
Scoreboard.__index = Scoreboard

function Scoreboard.new()
local self = setmetatable({}, Scoreboard)
self.gui = baseGUI.Scoreboard:Clone()

return self
end

function Scoreboard:Init()
local container = self.gui.Container
local timerFrame = container.Timer
local function updateVisibility()
local gameStatus = serverInfo:GetAttribute("GameStatus")
timerFrame.Visible = gameStatus == "InProgress" or gameStatus == "Paused"
self.gui.Enabled = not localPlayer:GetAttribute("FreecamEnabled")
and (gameStatus == "InProgress" or gameStatus == "Team Selection" or gameStatus == "Paused" or (gameStatus == "Practice" and localPlayer.Team.Name == "Fans"))
end
updateVisibility()
serverInfo:GetAttributeChangedSignal("GameStatus"):Connect(updateVisibility)
localPlayer:GetPropertyChangedSignal("Team"):Connect(updateVisibility)


local function updateTimerLabel()
local roundTime = serverInfo:GetAttribute("RoundTime")
roundTime = math.floor(roundTime)
timerFrame.TextLabel.Text = tostring(roundTime)
timerFrame.TextLabel.TextColor3 = roundTime > 10 and Color3.new(1, 1, 1) or Color3.new(1, 0, 0)
end
updateTimerLabel()
serverInfo:GetAttributeChangedSignal("RoundTime"):Connect(updateTimerLabel)

local function updateScore()
container.Score.ScoreLabel.Text = `{serverInfo:GetAttribute("HomeScore")} - {serverInfo:GetAttribute("AwayScore")}`
end
updateScore()

serverInfo:GetAttributeChangedSignal("HomeScore"):Connect(updateScore)
serverInfo:GetAttributeChangedSignal("AwayScore"):Connect(updateScore)
end

return Scoreboard
src/client/Controllers/UIController/Overlays/Stamina.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = ReplicatedStorage.Assets
local baseGUI = assets.GUI.Base

local localPlayer = Players.LocalPlayer


local Stamina = {}
Stamina.__index = Stamina

function Stamina.new()
local self = setmetatable({}, Stamina)
self.gui = baseGUI.Stamina:Clone()

return self
end

function Stamina:Init()
local bar: Frame = self.gui.Container.Bar

local lastStamina = localPlayer:GetAttribute("Stamina") or 100
localPlayer:GetAttributeChangedSignal("Stamina"):Connect(function()
local maxStamina = localPlayer:GetAttribute("MaxStamina")

local ratio = localPlayer:GetAttribute("Stamina") / maxStamina
bar.Size = UDim2.fromScale(1, ratio)

local currentStamina = localPlayer:GetAttribute("Stamina")
local difference = lastStamina - currentStamina
lastStamina = currentStamina

if difference > 0 then
self.gui.Enabled = true
elseif currentStamina == localPlayer:GetAttribute("MaxStamina") then
self.gui.Enabled = false
end
end)

localPlayer.CharacterAdded:Connect(function(character)
self:AddCharacter(character)
end)
if localPlayer.Character then
task.spawn(function()
self:AddCharacter(localPlayer.Character)
end)
end
end

function Stamina:AddCharacter(character)
self.gui.Adornee = nil
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
self.gui.Adornee = humanoidRootPart
self.gui.Enabled = false
end

return Stamina
src/client/Controllers/UIController/Overlays/TeamSelect.lua
local GamepadService = game:GetService("GamepadService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local GameService = Knit.GetService("GameService")

local Trove = require(ReplicatedStorage.Modules.Trove)
local Zone = require(ReplicatedStorage.Modules.Zone)

local trove = Trove.new()

local serverInfo: Configuration = ReplicatedStorage.ServerInfo

local assets = ReplicatedStorage.Assets
local baseGUI = assets.GUI.Base

local localPlayer = Players.LocalPlayer

local homeTeam: Team, awayTeam: Team = Teams.Home, Teams.Away


local TeamSelect = {}
TeamSelect.__index = TeamSelect

function TeamSelect.new()
local self = setmetatable({}, TeamSelect)
self.gui = baseGUI.TeamSelect:Clone()

return self
end

function TeamSelect:Init()
self:SetupButtons()

-- local roleSelectFrame: Frame = self.gui.RoleSelect
-- local closeButton: TextButton = roleSelectFrame.Close
-- BaseButton(closeButton)
-- closeButton.Activated:Connect(function()
-- self.gui.Enabled = false
-- end)


local function checkGameStatus()
local gameStatus = serverInfo:GetAttribute("GameStatus")
local enabled = (gameStatus == "InProgress" or gameStatus == "Team Selection" or gameStatus == "Paused" or gameStatus == "Practice")
and localPlayer.Team ~= homeTeam and localPlayer.Team ~= awayTeam
self.gui.Enabled = enabled
end

task.spawn(function()
local enterZone = Zone.new(workspace.Lobby.Zones:WaitForChild("ChooseTeamEnter"))
enterZone.localPlayerEntered:Connect(checkGameStatus)
serverInfo:GetAttributeChangedSignal("GameStatus"):Connect(function()
if not enterZone:findLocalPlayer() then return end
checkGameStatus()
end)

local leaveZone = Zone.new(workspace.Lobby.Zones:WaitForChild("ChooseTeamLeave"))
leaveZone.localPlayerExited:Connect(function()
self.gui.Enabled = false
end)
end)
localPlayer:GetPropertyChangedSignal("Team"):Connect(function()
if not self.gui.Enabled then return end
checkGameStatus()
end)

self.gui:GetPropertyChangedSignal("Enabled"):Connect(function()
trove:Clean()

-- Gamepad Navigation
if not UserInputService.GamepadEnabled then
return
end
if self.gui.Enabled then
GamepadService:EnableGamepadCursor(self.gui.Container)
else
GamepadService:DisableGamepadCursor()
end
end)
end

function TeamSelect:SetupButtons()
local container = self.gui.Container
local holder = container.Main.Holder

local homeFrame: TextButton = holder.Home
homeFrame.Activated:Connect(function()
self:ShowRoles("Home")
end)
local awayFrame: TextButton = holder.Away
awayFrame.Activated:Connect(function()
self:ShowRoles("Away")
end)
end

function TeamSelect:ShowRoles(teamName: string)
self.gui.Container.Visible = false
self.gui.RoleSelect.Visible = true

trove:Add(function()
self.gui.Container.Visible = true
self.gui.RoleSelect.Visible = false
end)

local roleSelectFrame: Frame = self.gui.RoleSelect

local roleObjects = serverInfo[teamName]
for _, roleButton: ImageButton in pairs(roleSelectFrame.Main.Roles:GetChildren()) do
local role = roleButton.Name
local roleObject: ObjectValue = roleObjects:FindFirstChild(role)
local function updateRoleOccupation()
local playerInRole: Player = roleObject.Value
roleButton.Player.Text = playerInRole and playerInRole.Name or "No One"
roleButton.Player.TextColor3 = playerInRole and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(126, 126, 126)
roleButton.ImageColor3 = playerInRole and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(126, 126, 126)
end
updateRoleOccupation()
trove:Connect(roleObject.Changed, updateRoleOccupation)
trove:Connect(roleButton.Activated, function()
GameService:SelectTeam(teamName, role)
self.gui.Enabled = false
end)
end
end

return TeamSelect
src/client/Controllers/UIController/init.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui


local function deepCopy(original)
local copy = {}
for k, v in pairs(original) do
if type(v) == "table" then
v = deepCopy(v)
end
copy[k] = v
end
return copy
end


local UIController = {
Name = "UIController",
uiModules = {},

overlayList = {},
}

function UIController:KnitStart()
for _, module in pairs(script.Overlays:GetChildren()) do
local uiModule = require(module).new()
self.uiModules[module.Name] = uiModule
table.insert(self.overlayList, module.Name)

local screenGui = uiModule.gui
screenGui.Parent = playerGui
end

local promises = {}
for moduleName, uiModule in pairs(self.uiModules) do
table.insert(promises, Promise.new(function(resolve, reject)
local success, errorMessage = pcall(function()
uiModule:Init()
end)
if success then
resolve()
else
warn(`[UIController] Promise -- Failed to load {moduleName} -- {errorMessage}`)
reject()
end
end))
end
end

return UIController
src/client/Controllers/CharacterController.lua
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local privateServerInfo: Configuration = ReplicatedStorage.PrivateServerInfo
local serverInfo: Configuration = ReplicatedStorage.ServerInfo

local Knit = require(ReplicatedStorage.Packages.Knit)
local CharacterService

local GameInfo = require(ReplicatedStorage.Data.GameInfo)
local Keybinds = require(ReplicatedStorage.Data.Keybinds)

local Cooldown = require(ReplicatedStorage.Modules.Cooldown)
local Lib = require(ReplicatedStorage.Lib)
local Signal = require(ReplicatedStorage.Modules.Signal)
local SmoothShiftLock = require(ReplicatedStorage.Modules.SmoothShiftLock)
local spr = require(ReplicatedStorage.Modules.spr)
local Trove = require(ReplicatedStorage.Modules.Trove)

local trove = Trove.new()
local staminaDrainTrove = trove:Extend()
local shotTrove = trove:Extend()
local keybindTrove = trove:Extend()
local characterTrove = trove:Extend()
local gameTrove = trove:Extend()

local shootCooldown = Cooldown.new(0.1)
local skillCooldown = Cooldown.new(privateServerInfo:GetAttribute("SkillCD"))
local requestBallCooldown = Cooldown.new(2)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui
local currentCamera = workspace.CurrentCamera
local realBallObject: ObjectValue = localPlayer:WaitForChild("Ball")

local action = nil

local chargingShot = false

localPlayer:SetAttribute("CurveFactor", 0)
local buttonBasedCurving = false


local shotAttachment0 = Instance.new("Attachment")
shotAttachment0.Name = "ShotAttachment0"
shotAttachment0.Parent = workspace.Terrain
local shotAttachment1 = Instance.new("Attachment")
shotAttachment1.Name = "ShotAttachment1"
shotAttachment1.Parent = workspace.Terrain


local function hasBall(): boolean
return realBallObject.Value ~= nil
end

local function rotateVectorAround(v, amount, axis)
return CFrame.fromAxisAngle(axis, amount):VectorToWorldSpace(v)
end

local function getClosestAngle(ang, ref)
return (ang - ref + math.pi)%(2 * math.pi) - math.pi + ref
end

local function actionAvailable(simulation: {state: {tackle: number, dive: number}}): boolean | nil
return not (
simulation.state.tackle > 0
or simulation.state.dive > 0
)
end


local CharacterController = {
Name = "CharacterController",
}
CharacterController.shiftLockEnabled = true

function CharacterController:KnitInit()
local Packages = ReplicatedFirst.Chickynoid
self.ClientModule = require(Packages.Client.ClientModule)
self.ClientMods = require(Packages.Client.ClientMods)

self.ClientMods:RegisterMods("clientmods", Packages.Examples.ClientMods)
self.ClientMods:RegisterMods("characters", Packages.Examples.Characters)
self.ClientMods:RegisterMods("balls", Packages.Examples.Balls)

self.ClientModule:Setup()


local TextChatService = game:GetService("TextChatService")
TextChatService.OnBubbleAdded = function(message: TextChatMessage, adornee: Instance)
-- Check if the chat message has a TextSource (sender) associated with it
if message.TextSource then
-- Create a new BubbleChatMessageProperties instance to customize the chat bubble
local bubbleProperties = Instance.new("BubbleChatMessageProperties")

-- Get the user who sent the chat message based on their UserId
local player = Players:GetPlayerByUserId(message.TextSource.UserId)
if player ~= localPlayer and adornee == nil then
local characterData = CharacterController.ClientModule.characters[player.UserId]
if characterData == nil then
return
end
local characterModel = characterData.characterModel
if characterData == nil then
return
end
local character = characterModel.model
if character == nil or not character:IsDescendantOf(workspace) then
return
end
TextChatService:DisplayBubble(character.Head, message.Text)
end

return bubbleProperties
end
return
end

task.spawn(function()
local chickynoid = self.ClientModule:GetClientChickynoid()
while chickynoid == nil do
task.wait(0.5)
chickynoid = self.ClientModule:GetClientChickynoid()
end

local characterModel = self.ClientModule.characterModel
while characterModel == nil do
task.wait(0.5)
characterModel = self.ClientModule.characterModel
end

while chickynoid.mispredict.Magnitude ~= 0 do
task.wait(0.5)
end

local loadingGui: ScreenGui = playerGui.LoadingScreen
loadingGui:SetAttribute("Chickynoid", true)
end)


localPlayer:SetAttribute("Stamina", GameInfo.MAX_STAMINA)
localPlayer:SetAttribute("MaxStamina", GameInfo.MAX_STAMINA)
localPlayer:SetAttribute("ShotPower", 0)

localPlayer:SetAttribute("Tackle", false)


RunService.Heartbeat:Connect(function(deltaTime)
if buttonBasedCurving then
return
end
if localPlayer:GetAttribute("AdjustedCurve") then
return
end

deltaTime *= GameInfo.CURVE_FACTOR_RECEDE_MULTIPLIER
local curveFactor = localPlayer:GetAttribute("CurveFactor")
local sign = math.sign(curveFactor)
if sign == -1 then
localPlayer:SetAttribute("CurveFactor", curveFactor - math.max(curveFactor, sign*deltaTime))
elseif sign == 1 then
localPlayer:SetAttribute("CurveFactor", curveFactor - math.min(curveFactor, sign*deltaTime))
end
end)


CollectionService:GetInstanceAddedSignal("Ragdoll"):Connect(function(character)
if character ~= localPlayer.Character then return end
self:EndShot()
end)
end

function CharacterController:KnitStart()
local controllers = script.Parent
UIController = require(controllers.UIController)

CharacterService = Knit.GetService("CharacterService")

local lastPosition: string | nil = localPlayer:GetAttribute("Position")
self:PositionChanged()
localPlayer:GetAttributeChangedSignal("Position"):Connect(function()
local currentPosition = localPlayer:GetAttribute("Position")
if lastPosition ~= nil and currentPosition ~= nil then
lastPosition = currentPosition
return
end
lastPosition = currentPosition
self:PositionChanged()
end)

-- Keybinds
SmoothShiftLock:Init()

ContextActionService:BindAction("ShiftLock", function(_, inputState)
self:CallKeybindFunction("ShiftLock", inputState)
end, false, Keybinds.PC.ShiftLock, Keybinds.Console.ShiftLock)
end

function CharacterController:PositionChanged()
if localPlayer:GetAttribute("Position") == nil then
localPlayer:SetAttribute("ShiftLock", false)
localPlayer:SetAttribute("JumpDisabled", false)

self:StopSprint()
self:UnbindKeybinds(true)
trove:Clean()
return
end


local characterAddedTrove = gameTrove:Extend()
local function runCharacterAdded()
local character = localPlayer.Character
characterAddedTrove:Clean()
characterAddedTrove:Add(task.spawn(function()
self:CharacterAdded(character)
end))
characterAddedTrove:Connect(character:GetAttributeChangedSignal("Goalkeeper"), runCharacterAdded)
end
runCharacterAdded()

gameTrove:Connect(serverInfo:GetAttributeChangedSignal("GameStatus"), function()
local gameStatus = serverInfo:GetAttribute("GameStatus")
if gameStatus ~= "GameEnded" then
return
end
shotTrove:Clean()
localPlayer:SetAttribute("ShotPower", 0)
localPlayer:SetAttribute("LeanAngle", CFrame.new())
self:StopSprint()
self:EndShot()
end)
end

function CharacterController:CharacterAdded(character)
spr.target(currentCamera, 1, 5, {FieldOfView = 70})

characterTrove:Clean()
characterTrove:Add(function()
localPlayer:SetAttribute("ShotPower", 0)
end)

keybindTrove:Clean()
self:UnbindKeybinds()


local shouldRun = true
characterTrove:Add(function()
shouldRun = false
end)

self:EndShot()
while not Lib.playerInGameOrPaused() do
task.wait()
if not shouldRun then
return
end
end

self:SetKeybinds()
self:ToggleShiftLock(self.shiftLockEnabled)


characterTrove:Connect(RunService.Heartbeat, function()
self.ClientModule.playerAction = action
end)


localPlayer:SetAttribute("ShotPower", 0)
localPlayer:SetAttribute("JumpDisabled", false)

characterTrove:Connect(localPlayer:GetAttributeChangedSignal("DisableChargeShot"), function()
if not localPlayer:GetAttribute("DisableChargeShot") then
return
end
self:EndShot()
end)
end

-- Keybinds
local function bindAction(actionName: string)

end

local function unbindAction(actionName: string)
ContextActionService:UnbindAction(actionName)
end

function CharacterController:GetCurrentCommand()
local cmd = {}
cmd.x = 0
cmd.y = 0
cmd.z = 0

local modules = self.ClientMods:GetMods("clientmods")

for key, mod in modules do
if (mod.GenerateCommand) then
cmd = mod:GenerateCommand(cmd, nil, nil, self.ClientModule)
end
end
return cmd
end

CharacterController.keybindFunctions = {
["Shoot"] = function(self, inputState)
if not (shootCooldown:IsFinished() and not Lib.playerIsStunned()) then
return
end

if inputState == Enum.UserInputState.Begin then
self:BeginShot()
elseif inputState == Enum.UserInputState.End then
self:ShootBall("Shoot")
end
end,

["Dive"] = function(self: typeof(CharacterController), inputState)
if Lib.playerIsStunned() then return end

local chickynoid = self.ClientModule:GetClientChickynoid()
if chickynoid == nil then
return
end
local simulation = chickynoid.simulation

if inputState == Enum.UserInputState.Begin and actionAvailable(simulation) then
local cmd = self:GetCurrentCommand()

local velocity = Vector3.new(0, 0, 0)
if (cmd.x ~= 0 or cmd.z ~= 0) then
velocity = Vector3.new(cmd.x, 0, cmd.z).Unit
end

local shiftLock = cmd.shiftLock
local diveAnim: number
if velocity.Magnitude > 0 and shiftLock then
local movingForward, movingBackward, movingRight, movingLeft

local cameraCFrame = CFrame.lookAt(Vector3.zero, cmd.fa)
local _, y, _ = cameraCFrame:ToEulerAnglesYXZ()

local movementDirection = rotateVectorAround(velocity, -y, Vector3.yAxis)

-- Add 0.01 to Z to prioritize front dive if diagonal
if math.abs(movementDirection.X) >= math.abs(movementDirection.Z) + 0.01
--math.abs(movementDirection.X) >= math.abs(movementDirection.Z) + 0.05
then
movingRight = movementDirection.X >= 0
movingLeft = movementDirection.X < 0
else
movingBackward = movementDirection.Z >= 0
movingForward = movementDirection.Z < 0
end

if movingForward or movingBackward then
diveAnim = 1
elseif movingBackward then
return
elseif movingRight then
diveAnim = 2
velocity = (cameraCFrame.RightVector * Vector3.new(1, 0, 1)).Unit
elseif movingLeft then
diveAnim = 0
velocity = (-cameraCFrame.RightVector * Vector3.new(1, 0, 1)).Unit
end
elseif velocity.Magnitude > 0 and not shiftLock then
diveAnim = 1
else
diveAnim = 1

local angle = simulation.state.angle
local characterDirection = -Vector3.new(math.sin(angle), 0, math.cos(angle))
velocity = characterDirection
end

localPlayer:SetAttribute("CMDDiveDir", velocity)
localPlayer:SetAttribute("CMDDiveAnim", diveAnim)
else
localPlayer:SetAttribute("CMDDiveDir", nil)
localPlayer:SetAttribute("CMDDiveAnim", nil)
end
end,
["SlideTackle"] = function(self, inputState)
if Lib.playerIsStunned() then return end

local chickynoid = self.ClientModule:GetClientChickynoid()
if chickynoid == nil then
return
end
local simulation = chickynoid.simulation

if inputState == Enum.UserInputState.Begin and actionAvailable(simulation) then
local cmd = self:GetCurrentCommand()

local tackleDir = Vector3.new(1, 0, 0)
if cmd.shiftLock == 0 and (cmd.x ~= 0 or cmd.z ~= 0) then
tackleDir = Vector3.new(cmd.x, 0, cmd.z).Unit
elseif cmd.shiftLock == 1 and cmd.fa and typeof(cmd.fa) == "Vector3" then
local vec = cmd.fa * Vector3.new(1, 0, 1)
if vec.Magnitude > 0 then
tackleDir = vec.Unit
end
else
local angle = simulation.state.angle
local characterDirection = -Vector3.new(math.sin(angle), 0, math.cos(angle))
tackleDir = characterDirection
end

localPlayer:SetAttribute("CMDTackleDir", tackleDir)
else
localPlayer:SetAttribute("CMDTackleDir", nil)
end
end,
["Skill"] = function(self, inputState)
if Lib.playerIsStunned() then return end

local chickynoid = self.ClientModule:GetClientChickynoid()
if chickynoid == nil then
return
end
local simulation = chickynoid.simulation

if inputState == Enum.UserInputState.Begin and hasBall() and actionAvailable(simulation) then
self:Skill()
end
end,

["RequestBall"] = function(self, inputState)
if inputState ~= Enum.UserInputState.Begin then return end
if Lib.playerIsStunned() then return end
self:RequestBall()
end,
["Sprint"] = function(self, inputState)
if UserInputService.TouchEnabled or UserInputService.GamepadEnabled then
if inputState ~= Enum.UserInputState.Begin then return end
if localPlayer:GetAttribute("Sprinting") then
self:StopSprint()
else
self:StartSprint()
end
else
if inputState == Enum.UserInputState.Begin then
self:StartSprint()
elseif inputState == Enum.UserInputState.End then
self:StopSprint()
end
end
end,
["ShiftLock"] = function(self, inputState)
if inputState ~= Enum.UserInputState.Begin then return end
self:ToggleShiftLock()
end,
}
CharacterController.shiftLockSignal = Signal.new()

function CharacterController:CallKeybindFunction(actionName: string, inputState)
local keybindFunction: (typeof(CharacterController), string) -> () = self.keybindFunctions[actionName]
if keybindFunction == nil then
return warn("Couldn't find keybind function for:", actionName)
end
keybindFunction(self, inputState)
end

function CharacterController:SetKeybinds()
local function bindShoot()
bindAction("Shoot")
ContextActionService:BindActionAtPriority("Shoot", function(_, inputState)
self:CallKeybindFunction("Shoot", inputState)
end, false, 1, Keybinds.PC.Shoot, Keybinds.Console.Shoot)
end

local function bindDive()
bindAction("Dive")
ContextActionService:BindAction("Dive", function(_, inputState)
self:CallKeybindFunction("Dive", inputState)
end, false, Keybinds.PC.Dive, Keybinds.Console.Dive)
end
local function bindTackle()
bindAction("SlideTackle")
ContextActionService:BindAction("SlideTackle", function(_, inputState)
self:CallKeybindFunction("SlideTackle", inputState)
end, false, Keybinds.PC.Tackle, Keybinds.Console.Tackle)
end
local function bindSkill()
bindAction("Skill")
ContextActionService:BindAction("Skill", function(_, inputState)
self:CallKeybindFunction("Skill", inputState)
end, false, Keybinds.PC.Skill, Keybinds.Console.Skill)
end

local function bindRequestBall()
bindAction("RequestBall")
ContextActionService:BindAction("RequestBall", function(_, inputState)
self:CallKeybindFunction("RequestBall", inputState)
end, false, Keybinds.PC.RequestBall, Keybinds.Console.RequestBall)
end
local function bindSprint()
bindAction("Sprint")
ContextActionService:BindAction("Sprint", function(_, inputState)
self:CallKeybindFunction("Sprint", inputState)
end, false, Keybinds.PC.Sprint, Keybinds.Console.Sprint)
end

keybindTrove:Clean()

local character = localPlayer.Character
if character:GetAttribute("Goalkeeper") then
bindShoot()

bindSprint()

local function ballChanged()
unbindAction("Dive")
unbindAction("RequestBall")
if not hasBall() then
bindRequestBall()
bindDive()
end
end
ballChanged()
keybindTrove:Connect(realBallObject.Changed, ballChanged)
else
bindShoot()

bindSprint()

local function ballChanged()
unbindAction("SlideTackle")
unbindAction("Skill")
unbindAction("RequestBall")
if not hasBall() then
bindRequestBall()
bindTackle()
else
bindSkill()
end
end
ballChanged()
keybindTrove:Connect(realBallObject.Changed, ballChanged)
end

local lastState = Lib.playerIsStunned()
keybindTrove:Connect(RunService.Heartbeat, function()
local isStunned = Lib.playerIsStunned()
if lastState == isStunned then
return
end

if isStunned then
lastState = isStunned
self:UnbindKeybinds(true)
else
self:SetKeybinds()
end
end)
end

function CharacterController:UnbindKeybinds(ignoreShiftLock)
unbindAction("Shoot")
unbindAction("Dive")
unbindAction("Sprint")
unbindAction("SlideTackle")
unbindAction("Skill")
unbindAction("RequestBall")
end

-- Mechanics
function CharacterController:ToggleShiftLock(enabled)
self.shiftLockEnabled = if enabled ~= nil then enabled else not self.shiftLockEnabled
self.shiftLockSignal:Fire()
localPlayer:SetAttribute("ShiftLock", self.shiftLockEnabled)
SmoothShiftLock:ToggleShiftLock(self.shiftLockEnabled)
end

function CharacterController:RequestBall()
if not Lib.playerInGameOrPaused() then return end
if hasBall() then return end

if not requestBallCooldown:IsFinished() then return end
requestBallCooldown:Update()

local simulation = self.ClientModule:GetClientChickynoid().simulation
simulation.characterData:PlayAnimation("RequestBall", 1, true)

CharacterService:RequestBall()
end

function CharacterController:Skill()
if not Lib.playerInGameOrPaused() then return end
if not hasBall() then return end

skillCooldown.cooldown = privateServerInfo:GetAttribute("SkillCD") + GameInfo.SKILL_DURATION
if not skillCooldown:IsFinished() then return end
skillCooldown:Update()

self:EndShot()
self.ClientModule.skillServerTime = self.ClientModule.estimatedServerTime
end

-- Shooting
function CharacterController:ShootBall(shotType, multiplier)
if not Lib.playerInGameOrPaused() then return end
if not chargingShot then return end

if not hasBall() then
self:EndShot()
return
end

multiplier = multiplier or 1
local shotDirection = Lib.getShotDirection()
local shotPower = localPlayer:GetAttribute("ShotPower")
shotPower = math.clamp(shotPower, 0, privateServerInfo:GetAttribute("MaxShotPower"))

local ballController = self.ClientModule.localBallController
self.ClientModule.shotInfo = {
guid = ballController.simulation.state.guid,
shotType = shotType,
shotPower = shotPower,
shotDirection = shotDirection,
curveFactor = localPlayer:GetAttribute("CurveFactor"),
}
self.ClientModule.doShotOnClient = true

self:EndShot()
end

function CharacterController:BeginShot()
if not Lib.playerInGameOrPaused() then return end

if not shootCooldown:IsFinished() then
return
end

action = "Shoot"
self:BeginChargeShot(action)
end

function CharacterController:BeginChargeShot(shotType: string)
shotTrove:Clean()
chargingShot = true

local humanoid = Lib.getHumanoid()
spr.target(humanoid, 1, 3, {
CameraOffset = GameInfo.CAMERA_OFFSET + Vector3.new(1.5, 0, 0),
})

localPlayer:SetAttribute("ChargingShot", true)
shotTrove:Add(function()
localPlayer:SetAttribute("AdjustedCurve", false)
chargingShot = false
localPlayer:SetAttribute("ChargingShot", false)

spr.target(humanoid, 1, 3, {
CameraOffset = GameInfo.CAMERA_OFFSET,
})
end)

local actualPower = localPlayer:GetAttribute("ShotPower")


if shotType == "Shoot" then
localPlayer:SetAttribute("CurveFactor", 0)
end
local lastCameraRotation: number
local function chargeShot(deltaTime)
if humanoid == nil or humanoid.Parent == nil or humanoid.Health == 0 then
self:EndShot()
return
end

local maxShotPower = privateServerInfo:GetAttribute("MaxShotPower")
actualPower += deltaTime*maxShotPower*GameInfo.SHOT_CHARGE_MULTIPLIER

local newPower = math.min(maxShotPower, actualPower)
localPlayer:SetAttribute("ShotPower", newPower)

if actualPower >= privateServerInfo:GetAttribute("MaxShotPower")*3 then
self:ShootBall("Shoot")
return
end


-- Curve shot updater
if shotType == "Shoot" and not buttonBasedCurving then
local _, cameraRotation, _ = currentCamera.CFrame:ToEulerAnglesYXZ()
if lastCameraRotation and lastCameraRotation ~= cameraRotation then
local difference = getClosestAngle(cameraRotation, lastCameraRotation) - lastCameraRotation
local increment = -difference * GameInfo.CURVE_FACTOR_CHARGE_MULTIPLIER
local curveFactor = localPlayer:GetAttribute("CurveFactor")
if math.sign(curveFactor) ~= math.sign(increment) then
local multipliedIncrement = math.sign(increment) * math.min(math.abs(increment), math.abs(curveFactor / 3))
curveFactor += multipliedIncrement*3
increment -= multipliedIncrement
localPlayer:SetAttribute("AdjustedCurve", true)
else
localPlayer:SetAttribute("AdjustedCurve", false)
end
localPlayer:SetAttribute("CurveFactor", math.clamp(curveFactor + increment, -GameInfo.MAXIMUM_CURVE_FACTOR, GameInfo.MAXIMUM_CURVE_FACTOR))
else
localPlayer:SetAttribute("AdjustedCurve", false)
end
lastCameraRotation = cameraRotation
end
end
chargeShot(0)
shotTrove:Connect(RunService.RenderStepped, chargeShot)
end

CharacterController.shotEnded = Signal.new()
function CharacterController:EndShot()
-- if not Lib.playerInGameOrPaused() then return end

self.shotEnded:Fire()
shootCooldown:Update()

action = nil
shotTrove:Clean()

localPlayer:SetAttribute("ShotPower", 0)
end

-- Sprint
function CharacterController:StartSprint()
if localPlayer:GetAttribute("MovementDisabled") then
return
end

if not Lib.playerInGameOrPaused() then return end

local chickynoid = self.ClientModule:GetClientChickynoid()
if chickynoid == nil then
return
end
local simulation = chickynoid.simulation

if not actionAvailable(simulation) then return end
if Lib.playerIsStunned() then return end

localPlayer:SetAttribute("Sprinting", true)

local humanoid = Lib.getHumanoid()
if humanoid == nil then return end

staminaDrainTrove:Clean()
staminaDrainTrove:Connect(RunService.Heartbeat, function(deltaTime)
if humanoid == nil or humanoid.Parent == nil or humanoid.Health == 0 then
staminaDrainTrove:Clean()
return
end
if localPlayer:GetAttribute("ServerChickyRagdoll") or humanoid.MoveDirection.Magnitude == 0 or humanoid.WalkSpeed == 0 then
spr.target(currentCamera, 1, 3, {FieldOfView = 70})
return
end

if localPlayer:HasTag("Ragdoll") then
self:StopSprint()
return
end

spr.target(currentCamera, 1, 3, {FieldOfView = 80})

if localPlayer:GetAttribute("Stamina") == 0 then
self:StopSprint()
staminaDrainTrove:Clean()
end
end)
end

function CharacterController:StopSprint()
-- if not Lib.playerInGameOrPaused() then return end
localPlayer:SetAttribute("Sprinting", false)

staminaDrainTrove:Clean()

spr.target(currentCamera, 1, 3, {FieldOfView = 70})
end

return CharacterController
src/client/Controllers/EffectController.lua
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local EffectService

local effectMethods = {}


local EffectController = {
Name = "EffectController"
}

function EffectController:KnitStart()
EffectService = Knit.GetService("EffectService")
EffectService.OnEffectCreated:Connect(function(...)
self:CreateEffect(...)
end)
EffectService.OnReliableEffectCreated:Connect(function(...)
self:CreateEffect(...)
end)
end

function EffectController:KnitInit()
for _, moduleScript in pairs(ReplicatedStorage.ClientEffectModules:GetDescendants()) do
if not moduleScript:IsA("ModuleScript") then continue end
if moduleScript.Parent:IsA("ModuleScript") then continue end

local _, effectModule = xpcall(function()
return require(moduleScript)
end, function(errorMessage)
warn("Failed to load effect: " .. moduleScript.Name .. " error - " .. errorMessage)
end)

if not effectModule then continue end
for effectName, method in pairs(effectModule) do
effectMethods[effectName] = method
end
end
end

function EffectController:CreateEffect(effectName, effectInfo)
if not effectInfo then
effectInfo = {}
end


local effectMethod = effectMethods[effectName]
if effectMethod == nil then return end
xpcall(function()
effectMethod(effectInfo)
end, function(errorMessage)
warn("[EffectController] Effect method error: " .. effectName .. " - " .. errorMessage)
end)
end

return EffectController
src/client/Controllers/EmoteController.lua
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local EmoteService

local controllers = script.Parent
local CharacterController = require(controllers.CharacterController)

local Trove = require(ReplicatedStorage.Modules.Trove)

local assets = ReplicatedStorage.Assets
local animations = assets.Animations

local localPlayer = Players.LocalPlayer


local EmoteController = {
Name = "EmoteController"
}

function EmoteController:KnitInit()

end

function EmoteController:EmoteChanged(trove: typeof(Trove), player, character, endEmoteCallback: (string) -> ()?, looped: boolean?)
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

local humanoid: Humanoid = character:FindFirstChild("Humanoid")
local animator: Animator = humanoid:FindFirstChild("Animator")

local emoteData = character:GetAttribute("EmoteData")
local oldEmoteData = emoteData

trove:Clean()
if emoteData == nil then
return
end

emoteData = HttpService:JSONDecode(emoteData)
local emote = emoteData[1]
if emote == nil then
return
end

local canWalk = emoteData[4]
if character == localPlayer.Character and not canWalk then
trove:Connect(localPlayer:GetAttributeChangedSignal("EndEmote"), function()
local emoteGUID = emoteData[2]
EmoteService:EndEmote(emoteGUID)
trove:Clean()
end)

local playerModule = localPlayer.PlayerScripts:FindFirstChild("PlayerModule")
if playerModule then
playerModule = require(playerModule)
local movementController = playerModule:GetControls():GetActiveController()
movementController:Enable(false)
movementController:Enable(true)
end
end


if oldEmoteData ~= character:GetAttribute("EmoteData") then
return
end

local animation = animations.Emotes:FindFirstChild(emote, true)
if animation == nil or not animation:IsA("Animation") then
warn("Couldn't find animation for emote: " .. emote)
return
end
local emoteAnim = animator:LoadAnimation(animation)
emoteAnim.Priority = Enum.AnimationPriority.Action2
emoteAnim:Play()
if looped ~= nil then
emoteAnim.Looped = looped
end
trove:Add(function()
emoteAnim:Stop()
end)

if player == localPlayer and endEmoteCallback then
trove:Connect(emoteAnim.Ended, function()
local emoteGUID = emoteData[2]
EmoteService:EndEmote(emoteGUID)
end)
end
if player == nil and endEmoteCallback then
trove:Connect(emoteAnim.Stopped, endEmoteCallback)
end

if emote == "Dance" then
local characterScale = humanoidRootPart.Size.Y/2

local discoBall = Instance.new("Part")
discoBall.Name = 'DiscoBall'
discoBall.Locked = true
discoBall.FormFactor = Enum.FormFactor.Symmetric
discoBall.Shape = Enum.PartType.Ball
discoBall.Size = Vector3.new(1, 1, 1) * 4 * characterScale
discoBall.TopSurface = Enum.SurfaceType.Smooth
discoBall.BottomSurface = Enum.SurfaceType.Smooth
for _, enum in next, Enum.NormalId:GetEnumItems() do
local decal = Instance.new'Decal'
decal.Parent = discoBall
decal.Texture = 'http://www.roblox.com/asset/?id=27831454'
decal.Face = enum
end
discoBall.Position = humanoidRootPart.CFrame.Position + Vector3.new(0, 5, 0) * characterScale -- account for different body sizes

local discoSparkles = Instance.new('Sparkles')
discoSparkles.Parent = discoBall
local bodyPos = Instance.new('BodyPosition')
bodyPos.Position = humanoidRootPart.CFrame.Position + Vector3.new(0, 8, 0) * characterScale
bodyPos.P = 10000
bodyPos.D = 1000
bodyPos.maxForce = Vector3.new(1, 1, 1) * bodyPos.P
bodyPos.Parent = discoBall
trove:Connect(RunService.Heartbeat, function()
local rootPos = humanoidRootPart.CFrame.Position
discoBall.Position = Vector3.new(rootPos.X, discoBall.CFrame.Position.Y, rootPos.Z)
end)

local bodyAngularVelocity = Instance.new('BodyAngularVelocity')
bodyAngularVelocity.P = 100000
bodyAngularVelocity.angularvelocity = Vector3.new(0, 1000, 0)
bodyAngularVelocity.maxTorque = Vector3.new(1, 1, 1)*bodyAngularVelocity.P
bodyAngularVelocity.Parent = discoBall

discoBall.Parent = workspace
trove:Add(discoBall)

local song = Instance.new("Sound")
song.SoundId = "http://www.roblox.com/asset/?id=27808972"
song.Volume = 2
song.Looped = true
song.Parent = humanoidRootPart
song:Play()

trove:Add(song)
end
end

function EmoteController:KnitStart()
EmoteService = Knit.GetService("EmoteService")

local function characterAdded(character)
local trove = Trove.new()
trove:AttachToInstance(character)

local userid = character:GetAttribute("userid")
if userid == nil then
return
end
local player = Players:GetPlayerByUserId(userid)
if player == nil then
return
end

character:GetAttributeChangedSignal("EmoteData"):Connect(function()
self:EmoteChanged(trove, player, character)
end)
self:EmoteChanged(trove, player, character)
end


local clientModule = CharacterController.ClientModule
for _, player in pairs(Players:GetPlayers()) do
local chickynoidCharacter = clientModule.characters[player.UserId]
local characterModel = chickynoidCharacter and chickynoidCharacter.characterModel
if characterModel == nil then
continue
end
local character = characterModel.model
if character == nil or not character:IsDescendantOf(workspace) then
continue
end
task.spawn(function()
characterAdded(character)
end)
end
clientModule.OnCharacterModelCreated:Connect(function(characterModel)
task.spawn(function()
characterAdded(characterModel.model)
end)
end)
end

return EmoteController
src/client/Controllers/ServiceCommController.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera


local ServiceCommController = {
Name = "ServiceCommController"
}

function ServiceCommController:KnitStart()
local controllers = script.Parent
local CharacterController = require(controllers.CharacterController)

local GameService = Knit.GetService("GameService")

local function onTp(freezeCFrame: CFrame, disableShiftLock: boolean)
if disableShiftLock then
CharacterController:ToggleShiftLock(false)
end

if freezeCFrame ~= nil then
local character = localPlayer.Character
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.CFrame.Position) * freezeCFrame.Rotation
end

local _, yRot, _ = freezeCFrame:ToEulerAnglesYXZ()
local x, _, z = currentCamera.CFrame:ToEulerAnglesYXZ()
currentCamera.CFrame = CFrame.new(currentCamera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(x, yRot, z)

localPlayer:SetAttribute("DisableFollowCamera", true)
task.delay(0.5, function()
localPlayer:SetAttribute("DisableFollowCamera", nil)
end)
end

localPlayer:SetAttribute("Stamina", localPlayer:GetAttribute("MaxStamina"))
end
GameService.InstantTeleport:Connect(onTp)
GameService.PlayerTeleported:Connect(function(freezeCFrame: CFrame, disableShiftLock: boolean)
task.wait(1.25)
onTp(freezeCFrame, disableShiftLock)
end)
end

return ServiceCommController
src/client/Observers/Ball.client.lua
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local serverInfo: Configuration = ReplicatedStorage.ServerInfo

local TeamInfo = require(ReplicatedStorage.Data.TeamInfo)

local Lib = require(ReplicatedStorage.Lib)
local spr = require(ReplicatedStorage.Modules.spr)
local Trove = require(ReplicatedStorage.Modules.Trove)
local Quaternion = require(ReplicatedStorage.Modules.Quaternion)

local assets = ReplicatedStorage.Assets
local billboardGuis: {BillboardGui} = assets.GUI.Billboard

local localPlayer = Players.LocalPlayer

-- Load texture for mobile
assets.BallOwnerCircle:Clone().Parent = workspace.Lobby


local placeholderBallObject = Instance.new("ObjectValue")
placeholderBallObject.Name = "PlaceholderBallModel"
placeholderBallObject.Parent = localPlayer


local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await()

local controllers = script.Parent.Parent.Controllers
local CharacterController = require(controllers.CharacterController)


local troves = {}
local function tagAdded(ball: BasePart)
if not ball:IsDescendantOf(workspace) then
return
end

local trove = Trove.new()
trove:AttachToInstance(ball)
trove:Add(function()
troves[ball] = nil
end)
troves[ball] = trove

local ownerCircle: MeshPart = assets.BallOwnerCircle:Clone()
ownerCircle.Parent = ReplicatedStorage.EffectStorage
trove:Add(ownerCircle)

local ballOwner: ObjectValue = ball:WaitForChild("BallOwner")
local networkOwner: ObjectValue = ball:WaitForChild("NetworkOwner")

-- Effects
local function updateCircleCFrame(deltaTime)
local owner: Player = ballOwner.Value
local character = owner
if owner:IsA("Player") then
local chickynoidCharacter = CharacterController.ClientModule.characters[owner.UserId]
local characterModel = chickynoidCharacter and chickynoidCharacter.characterModel
if characterModel == nil then
return
end
character = characterModel.model
end
local humanoidRootPart = character and character.HumanoidRootPart
if humanoidRootPart == nil then
return
end

ownerCircle.CFrame = CFrame.new(humanoidRootPart.Position + Vector3.new(0, -2.9, 0))
end
local function updateBallRotation(placeholderBall: BasePart, rootMotor: Motor6D, handMotor: Motor6D)
local owner: Player = ballOwner.Value
if owner:GetAttribute("Position") == "Goalkeeper" then
return
end

if not owner:IsA("Player") then
return
end

local chickynoidCharacter = CharacterController.ClientModule.characters[owner.UserId]
local characterModel = chickynoidCharacter and chickynoidCharacter.characterModel
if characterModel == nil then
return
end

local dataRecord = if owner == localPlayer then
CharacterController.ClientModule.recordCustomData
else
chickynoidCharacter.characterData

if dataRecord == nil then
return
end
local ballRotation: Vector3 = dataRecord.ballRotation
local w: number = dataRecord.w

local quaternion = dataRecord.ballQuaternion or Quaternion.new(ballRotation.X, ballRotation.Y, ballRotation.Z, w)
rootMotor.C1 = quaternion:ToCFrame(Vector3.zero)

local leanAngle = dataRecord.leanAngle
rootMotor.C0 = CFrame.new(0, -2.15, -2) * CFrame.new(-leanAngle.Y*2, 0, leanAngle.X)
end
local function updateBallMotors(placeholderBall: BasePart, rootMotor: Motor6D, handMotor: Motor6D)
local owner: Player = ballOwner.Value
if owner == nil then
rootMotor.Part0 = nil
handMotor.Part0 = nil
return
end

local character = owner
if owner:IsA("Player") then
local chickynoidCharacter = CharacterController.ClientModule.characters[owner.UserId]
local characterModel = chickynoidCharacter and chickynoidCharacter.characterModel
if characterModel == nil then
return
end
character = characterModel.model
end
if character == nil then
return
end

local isGoalkeeper = character == owner or character:GetAttribute("Goalkeeper")
rootMotor.Part0 = not isGoalkeeper and character:FindFirstChild("HumanoidRootPart") or nil
handMotor.Part0 = isGoalkeeper and character:FindFirstChild("Right Arm") or nil
end

local highlightTrove = trove:Extend()
local trail: Trail = ball:WaitForChild("Trail")
local circleTrove = trove:Extend()
local function ballOwnerChanged()
highlightTrove:Clean()
trail:Clear()
circleTrove:Clean()

local owner: Player = ballOwner.Value
trail.Enabled = owner == nil
if owner == nil then
ball.Transparency = 0
return
end

local ownerTeam = owner.Team
if owner:IsA("Model") then
ownerTeam = ownerTeam.Value
end
local teamInfo = TeamInfo[ownerTeam:GetAttribute("TeamName")]
local newColor: Color3 = teamInfo.MainColor

ownerCircle.Color = newColor


ball.Transparency = 1
local placeholderBall: BasePart = assets.Ball:Clone()
placeholderBall.CanCollide = false
placeholderBall.Anchored = false
placeholderBallObject.Value = placeholderBall
placeholderBall:PivotTo(ball.CFrame)
circleTrove:Add(placeholderBall)

local rootMotor: Motor6D = placeholderBall.RootMotor
local handMotor: Motor6D = placeholderBall.HandMotor
updateBallMotors(placeholderBall, rootMotor, handMotor)
updateBallRotation(placeholderBall, rootMotor, handMotor)
updateCircleCFrame(0)
ball:PivotTo(placeholderBall.CFrame)

circleTrove:Connect(RunService.RenderStepped, function(deltaTime)
updateBallMotors(placeholderBall, rootMotor, handMotor)
updateBallRotation(placeholderBall, rootMotor, handMotor)
updateCircleCFrame(deltaTime)
ball:PivotTo(placeholderBall.CFrame)
end)

ownerCircle.Transparency = 0.015
ownerCircle.Parent = workspace.Effects


local character = owner
if owner:IsA("Player") then
local chickynoidCharacter = CharacterController.ClientModule.characters[owner.UserId]
local characterModel = chickynoidCharacter and chickynoidCharacter.characterModel
if characterModel then
character = characterModel.model
placeholderBall.Parent = character
else
character = nil
end
else
placeholderBall.Parent = workspace
end

circleTrove:Add(function()
ownerCircle.Parent = ReplicatedStorage.EffectStorage

if owner and owner:IsDescendantOf(game) then
if owner == localPlayer then
owner:SetAttribute("BallRotation", nil)
end
end
end)
end
task.spawn(ballOwnerChanged)
trove:Connect(ballOwner.Changed, ballOwnerChanged)
end
local function tagRemoved(instance: Instance)
local trove = troves[instance]
if trove == nil then
return
end
trove:Clean()
end

local TAG = "Ball"
CollectionService:GetInstanceAddedSignal(TAG):Connect(tagAdded)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(tagRemoved)
for _, instance in pairs(CollectionService:GetTagged(TAG)) do
tagAdded(instance)
end
src/client/BeamLODFix.client.lua
-- Credits to nurokoi

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local QualityFactor = math.max(0, math.min(1, UserSettings().GameSettings.SavedQualityLevel.Value / 10))
local function recalculateBeamSegments()
for _, beamObject : Beam in CollectionService:GetTagged("Beam") do
local Attachment0 = beamObject.Attachment0
local Attachment1 = beamObject.Attachment1

if not Attachment0 or not Attachment1 then continue end

local SegmentCount = beamObject:GetAttribute("DesiredSegments")

if not beamObject:GetAttribute("DesiredSegments") then
SegmentCount = beamObject.Segments
beamObject:SetAttribute("DesiredSegments", beamObject.Segments)
end

local CameraLocation = workspace.CurrentCamera.CFrame
local Distance = math.max((CameraLocation.Position - Attachment0.WorldPosition).Magnitude, (CameraLocation.Position - Attachment1.WorldPosition).Magnitude)

local QualityDistanceScalar = math.clamp((1 - (Distance - 200) / 800) * QualityFactor, 0.1, 1)

beamObject.Segments = math.ceil(SegmentCount / QualityDistanceScalar)
end
end

RunService:BindToRenderStep("BeamLOD", Enum.RenderPriority.Camera.Value + 1, recalculateBeamSegments)
while task.wait(1) do
QualityFactor = math.max(0, math.min(1, UserSettings().GameSettings.SavedQualityLevel.Value / 10))
end
src/client/LobbyResetButton.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await()
local GameService = Knit.GetService("GameService")

local localPlayer = Players.LocalPlayer


localPlayer.Idled:Connect(function()
if localPlayer:GetAttribute("Position") ~= "Goalkeeper" then return end
GameService:ResetBackToLobby()
end)


local bindableEvent = Instance.new("BindableEvent")
bindableEvent.Event:Connect(function()
GameService:ResetBackToLobby()
end)
repeat
local success = pcall(function()
StarterGui:SetCore("ResetButtonCallback", bindableEvent)
end)
task.wait()
until success
src/client/RagdollClient.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.RagdollHandler)
src/client/Runtime.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

for _, controllerModule: ModuleScript in pairs(script.Parent.Controllers:GetChildren()) do
if not controllerModule:IsA("ModuleScript") then continue end
local controller = require(controllerModule)
Knit.CreateController(controller)
end
Knit.Start()
src/replicatedstorage/ClientEffectModules/Mechanics.lua
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer


local Mechanics = {}

function Mechanics.ballKicked(effectInfo)
local ballModel = localPlayer:FindFirstChild("BallModel")
if ballModel then
local ball: BasePart = ballModel.Value
ball.KickSound:Play()
end
end

return Mechanics
src/replicatedstorage/Lib.lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
return require(ReplicatedFirst.Lib)
src/replicatedstorage/init.meta.json
{
"ignoreUnknownInstances": true
}
src/server/Chickynoid/Examples/ServerMods/init.meta.json
{
"ignoreUnknownInstances": true
}
src/server/Chickynoid/Examples/init.meta.json
{
"ignoreUnknownInstances": true
}
src/server/Chickynoid/Server/Antilag.lua
--!native
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lib = require(ReplicatedStorage.Lib)

local timeToKeepInHistory = 0.5

local module = {}
module.history = {}
module.temporaryPositions = {}

local path = game.ReplicatedFirst.Chickynoid
local Enums = require(path.Shared.Enums)

function module:Setup(server)
module.server = server
end

function module:WritePlayerPositions(serverTime)
local players = self.server:GetPlayers()

local snapshot = {}
snapshot.serverTime = serverTime
snapshot.players = {}
for _, playerRecord in pairs(players) do
if playerRecord.chickynoid then
local record = {}
record.position = playerRecord.chickynoid.simulation.characterData:GetPosition() --get current visual position
local player = Players:GetPlayerByUserId(playerRecord.userId)
if player then
record.skill = Lib.isOnHiddenCooldown(player, "SkillEnd")
end
snapshot.players[playerRecord.userId] = record
end
end

table.insert(self.history, snapshot)

for counter = #self.history, 1, -1 do
local oldSnapshot = self.history[counter]

--only keep 1s of history
if oldSnapshot.serverTime < serverTime - timeToKeepInHistory then
table.remove(self.history, counter)
end
end
end

function module:PushPlayerPositionsToTime(playerRecord, serverTime, debugText)
local players = self.server:GetPlayers()

if #self.temporaryPositions > 0 then
warn("POP not called after a PushPlayerPositionsToTime")
end

--find the two records
local prevRecord = nil
local nextRecord = nil
for counter = #self.history - 1, 1, -1 do
if self.history[counter].serverTime < serverTime then
prevRecord = self.history[counter]
nextRecord = self.history[counter + 1]
break
end
end

if prevRecord == nil then
warn("Could not find antilag time for ", serverTime)
return
end

local frac = ((serverTime - prevRecord.serverTime) / (nextRecord.serverTime - prevRecord.serverTime))
local debugFlag = self.server.flags.DEBUG_ANTILAG
if debugFlag == true then
print(
"Prev time ",
prevRecord.serverTime,
" Next Time ",
nextRecord.serverTime,
" des time ",
serverTime,
" frac ",
frac
)
end

self.temporaryPositions = {}
for userId, prevPlayerRecord in pairs(prevRecord.players) do
if userId == playerRecord.userId then
continue --Dont move us
end

local nextPlayerRecord = nextRecord.players[userId]
if nextPlayerRecord == nil then
continue
end

local otherPlayerRecord = players[userId]
if otherPlayerRecord == nil then
continue
end

if otherPlayerRecord.chickynoid == nil then
continue
end
if otherPlayerRecord.chickynoid.hitBox then
local oldPos = otherPlayerRecord.chickynoid.hitBox.Position
self.temporaryPositions[userId] = oldPos --Store it

local pos = prevPlayerRecord.position:Lerp(nextPlayerRecord.position, frac)

--place it just how it was when the server saw it
local hitBox: BasePart = otherPlayerRecord.chickynoid.hitBox
hitBox.Position = pos
hitBox:SetAttribute("Skill", nextPlayerRecord.skill)

if debugFlag == true then
local event = {}
event.t = Enums.EventType.DebugBox
event.pos = pos
event.text = debugText
playerRecord:SendEventToClient(event)
end
end
end
end

function module:Pop()
local players = self.server:GetPlayers()

for userId, pos in pairs(self.temporaryPositions) do
local playerRecord = players[userId]

if playerRecord and playerRecord.chickynoid then
if playerRecord.chickynoid.hitBox then
playerRecord.chickynoid.hitBox.Position = pos
end
end
end

self.temporaryPositions = {}
end

return module
src/server/Chickynoid/Server/BallPositionHistory.lua
local RunService = game:GetService("RunService")
--!native
local module = {}
module.history = {}
module.temporaryPositions = {}

local path = game.ReplicatedFirst.Chickynoid
local Enums = require(path.Shared.Enums)

function module:Setup(server)
module.server = server
end

function module:WriteBallPosition(serverTime)
local snapshot = {}
snapshot.serverTime = serverTime
local ballRecord = self.server.ballRecord
local ballController = ballRecord.ballController
if ballRecord.ballController then
snapshot.claimCooldown = ballController:isOnCooldown("ClaimCooldown")
snapshot.lagSaveLeniency = ballController:getAttribute("LagSaveLeniency")
snapshot.ballPos = ballController.simulation.ballData:GetPosition()
end

table.insert(self.history, snapshot)

for counter = #self.history, 1, -1 do
local oldSnapshot = self.history[counter]

--only keep 1s of history
if oldSnapshot.serverTime < serverTime - 1 then
table.remove(self.history, counter)
end
end
end

function module:GetPreviousPosition(serverTime, position: Vector3)
--find the two records
for counter = #self.history - 1, 1, -1 do
local record = self.history[counter]
local previousRecord = self.history[counter - 1] or {}
if (record.ballPos - position).Magnitude < 0.001 then
return record.ballPos, record.claimCooldown, previousRecord.ballPos, record.lagSaveLeniency
end
end

if RunService:IsStudio() then
-- warn("Could not find antilag time for ", serverTime)
end
end

function module:Pop()
local ballRecord = self.server.ballRecord
local ballController = ballRecord.ballController
if ballController then
if ballController.hitBox then
ballController.hitBox.Position = self.temporaryPosition
end
end

self.temporaryPosition = nil
end

return module
src/server/Chickynoid/Server/Bots.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Enums = require(game.ReplicatedFirst.Chickynoid.Shared.Enums)

local path = game.ReplicatedFirst.Chickynoid
local CommandLayout = require(path.Shared.Simulation.CommandLayout)

local TeamInfo = require(ReplicatedStorage.Data.TeamInfo)

local module = {}
module.nextValidBotUserId = 26000
module.highFpsTest = true

--debug harness
local debugPlayers = {}
local invalidUserIds = {
[26003]=1,
[26020]=1,
[26021]=1,
[26038]=1,
[26075]=1,
[26068]=1,
[26056]=1,
[26084]=1,
[26025]=1,
[26066]=1,
[26049]=1,
[26045]=1,
[26083]=1,
[26058]=1,
[26047]=1,
[26055]=1,
[26032]=1,
[26105]=1,
[26108]=1,
[26110]=1,
[26118]=1,
}

local kits = ServerStorage.Assets.Kits:GetChildren() :: {Model}
function module:MakeBots(Server, numBots)

--Always the same seed
math.randomseed(1)

if (numBots > 200) then
numBots = 200
warn("200 bots max")
end

for counter = 1, numBots do

local userId = module.nextValidBotUserId

while (invalidUserIds[userId] ~= nil) do
userId += 1
end
--save it
module.nextValidBotUserId = userId+1

--Set it to negative
userId = -userId


local playerRecord = Server:AddConnection(userId, nil)

if (playerRecord == nil) then
continue
end

playerRecord.name = "RandomBot" .. counter
playerRecord.respawnTime = tick() + counter * 0.1

local kitClothing
repeat
kitClothing = kits[Random.new():NextInteger(1, #kits)]
until TeamInfo[kitClothing.Name] ~= nil

playerRecord.avatarDescription = {
kitClothing.Shirt.ShirtTemplate,
kitClothing.Pants.PantsTemplate,
playerRecord.name,
math.random(1, 99),
TeamInfo[kitClothing.Name].MainColor,
}
-- playerRecord.characterMod = "FieldChickynoid"

playerRecord:HandlePlayerLoaded()


playerRecord.waitTime = 0 --Bot AI
playerRecord.leftOrRight = 1

if (math.random()>0.5) then
playerRecord.leftOrRight = -1
end

--Spawn them in someplace
playerRecord.OnBeforePlayerSpawn:Connect(function()
playerRecord.chickynoid:SetPosition(Vector3.new(
math.random(-100, -60)+150,
40.6+2.5,
math.random(-300, -260)-30
), true)

end)


table.insert(debugPlayers, playerRecord)


playerRecord.BotThink = function(deltaTime)


if (playerRecord.waitTime > 0) then
playerRecord.waitTime -= deltaTime
end

local event = {}

local command = {}
command.localFrame = playerRecord.frame
command.playerStateFrame = 0
command.x = 0
command.y = 0
command.z = 0
command.serverTime = tick()
command.deltaTime = deltaTime
-- command.sprinting = 1



if (playerRecord.waitTime <=0) then
command.x = math.sin(playerRecord.frame*0.03 * playerRecord.leftOrRight)
command.y = 0
command.z = math.cos(playerRecord.frame*0.03 * playerRecord.leftOrRight)

if (math.random() < 0.05) then
command.y = 1
end
end

-- if (math.random() < 0.01) then
-- playerRecord.waitTime = math.random() * 5
-- end
event[1] = {
CommandLayout:EncodeCommand(command)
}
playerRecord.frame += 1
if (playerRecord.chickynoid) then
playerRecord.chickynoid:HandleEvent(Server, event)
end
end

task.delay(10, function()
playerRecord.characterMod = "FieldChickynoid"
Server:SetWorldStateDirty()
end)
end

end

return module
src/server/Chickynoid/Server/ServerBallController.lua
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
--!native
--[=[
@class ServerChickynoid
@server

Server-side character which exposes methods for manipulating a player's simulation
such as teleporting and applying impulses.
]=]

local path = game.ReplicatedFirst.Chickynoid

local Enums = require(path.Shared.Enums)
local EventType = Enums.EventType
local FastSignal = require(path.Shared.Vendor.FastSignal)

local BallSimulation = require(path.Shared.Simulation.BallSimulation)
local TrajectoryModule = require(path.Shared.Simulation.TrajectoryModule)

local DeltaTable = require(path.Shared.Vendor.DeltaTable)
local BallCommandLayout = require(path.Shared.Simulation.BallCommandLayout)

local ServerMods = require(script.Parent.ServerMods)

local ServerBallController = {}
ServerBallController.__index = ServerBallController

--[=[
Constructs a new [ServerChickynoid] and attaches it to the specified player.
@param playerRecord any -- The player record.
@return ServerChickynoid
]=]
function ServerBallController.new(ballRecord)
local self = setmetatable({
ballRecord = ballRecord,

simulation = BallSimulation.new(ballRecord.ballId),
characterMod = "DefaultBallController",

attributes = {},

unprocessedCommands = {},
commandSerial = 0,
lastConfirmedCommand = nil,
elapsedTime = 0,
playerElapsedTime = 0,

processedTimeSinceLastSnapshot = 0,

errorState = Enums.NetworkProblemState.None,

speedCheatThreshhold = 150 , --milliseconds

maxCommandsPerSecond = 400, --things have gone wrong if this is hit, but it's good server protection against possible uncapped fps
smoothFactor = 0.9999, --Smaller is smoother

serverFrames = 0,

ballSpawned = FastSignal.new(),
attributeChanged = FastSignal.new(),
hitBoxCreated = FastSignal.new(),
storedStates = {}, --table of the last few states we've send the client, because we use unreliables, we need to switch to ome of these to delta comrpess against once its confirmed

unreliableCommandSerials = 0, --This number only ever goes up, and discards anything out of order

prevCharacterData = {}, -- Rolling history key'd to serverFrame

debug = {
processedCommands = 0,
fakeCommandsThisSecond = 0,
antiwarpPerSecond = 0,
timeOfNextSecond = 0,
ping = 0
},
}, ServerBallController)
-- TODO: The simulation shouldn't create a debug model like this.
-- For now, just delete it server-side.
if self.simulation.debugModel then
self.simulation.debugModel:Destroy()
self.simulation.debugModel = nil
end

--Apply the characterMod
if (self.ballRecord.characterMod) then
local loadedModule = ServerMods:GetMod("balls", self.ballRecord.characterMod)
if (loadedModule) then
loadedModule:Setup(self.simulation)
end
end

return self
end



-- Ulldren Edits
local Lib = require(ReplicatedStorage.Lib)

local Services = script.Parent.Parent.Parent.Services
local CharacterService = require(Services.CharacterService)
local GameService = require(Services.GameService)

local Trove = require(ReplicatedStorage.Modules.Trove)

local ballTimeTrove = Trove.new()
local highlightTrove = Trove.new()
local scoreTrove = Trove.new()

local serverInfo: Configuration = ReplicatedStorage.ServerInfo


function ServerBallController:setBallOwner(server, ownerId: number | Model)
local ballSimulation = self.simulation
local lastOwnerId = ballSimulation.state.ownerId
if lastOwnerId then
if type(lastOwnerId) == "number" then
local playerRecord = server:GetPlayerByUserId(lastOwnerId)
if playerRecord then
playerRecord.hasBall = false
end
else
local goalkeeper: Model = lastOwnerId
goalkeeper:SetAttribute("HasBall", false)
end
end

ballSimulation.state.ownerId = ownerId
Lib.removeCooldown(serverInfo, "HoldDuration")
ballTimeTrove:Clean()

highlightTrove:Clean()

if type(ownerId) == "number" then
local player = Players:GetPlayerByUserId(ownerId)
local playerRecord = server:GetPlayerByUserId(ownerId)
if player ~= nil and playerRecord ~= nil then
if not playerRecord.hasBall then
pcall(function()
CharacterService.BallOwnerChanged:Fire(ownerId)
end)
end
playerRecord.hasBall = true

local lastNetId = ballSimulation.state.netId
local lastNetworkOwner = if type(lastNetId) == "number" then Players:GetPlayerByUserId(lastNetId) else lastNetId
local lastOwnerTeam
if lastNetworkOwner and lastNetworkOwner.Parent ~= nil then
if lastNetworkOwner:IsA("Player") then
lastOwnerTeam = lastNetworkOwner.Team
else
lastOwnerTeam = lastNetworkOwner.Team.Value
end
end
local onSameTeam = lastNetworkOwner and player and lastOwnerTeam == player.Team
if not onSameTeam then
Lib.setHiddenCooldown(player, "TackleInvulnerability", 0.4)
end

self:setAttribute("LagSaveLeniency", nil)
self:setNetworkOwner(server, ownerId)

local isGoalkeeper = player:GetAttribute("Position") == "Goalkeeper"
if isGoalkeeper then
Lib.setCooldown(serverInfo, "HoldDuration", 10)
ballTimeTrove:Connect(RunService.Heartbeat, function(deltaTime: number)
if player == nil or player.Parent == nil or player:GetAttribute("Position") ~= "Goalkeeper" then
ballTimeTrove:Clean()
return
end

if not Lib.isOnCooldown(serverInfo, "HoldDuration") then
Lib.setHiddenCooldown(player, "BallClaimCooldown", 10)
server.CharacterService:ResetBall(player)
end
end)
end

self:setAttribute("Team", player.Team.Name)
end
else
local goalkeeper: Model = ownerId
goalkeeper:SetAttribute("HasBall", true)
self:setNetworkOwner(server, ownerId)

Lib.setCooldown(serverInfo, "HoldDuration", 10)
ballTimeTrove:Connect(RunService.Heartbeat, function(deltaTime: number)
if goalkeeper == nil or goalkeeper.Parent == nil then
ballTimeTrove:Clean()
return
end

if not Lib.isOnCooldown(serverInfo, "HoldDuration") then
Lib.setCooldown(goalkeeper, "BallClaimCooldown", 10)
server.CharacterService:ResetBall(goalkeeper)
end
end)

self:setAttribute("Team", goalkeeper.Team.Value.Name)
end
self:setAttribute("TimeSinceChanged", os.clock()) -- use this to check if assist counts
end

function ServerBallController:setNetworkOwner(server, ownerId: number | Model)
local ballSimulation = self.simulation
local lastNetId = ballSimulation.state.netId
if lastNetId ~= ownerId and ownerId ~= 0 then
pcall(function()
self:setAttribute("LastTouchedNet", nil)
CharacterService.NetworkOwnerChanged:Fire(ownerId)
end)
end
ballSimulation.state.netId = ownerId

local timeSinceChanged = self:getAttribute("TimeSinceChanged")
local isAssistEligible = timeSinceChanged and os.clock() - timeSinceChanged < 10
if not isAssistEligible then
self:setAttribute("AssistPlayer", nil)
end

local player = if type(ownerId) == "number" then Players:GetPlayerByUserId(ownerId) else ownerId
local lastNetworkOwner = if type(lastNetId) == "number" then Players:GetPlayerByUserId(lastNetId) else lastNetId
if player and lastNetworkOwner and lastNetworkOwner:GetAttribute("Position") == "Goalkeeper" then
Lib.removeHiddenCooldown(lastNetworkOwner, "BallClaimCooldown")
end

local lastOwnerTeam
if lastNetworkOwner and lastNetworkOwner.Parent ~= nil then
if lastNetworkOwner:IsA("Player") then
lastOwnerTeam = lastNetworkOwner.Team
else
lastOwnerTeam = lastNetworkOwner.Team.Value
end
end
local onSameTeam = lastNetworkOwner and player and lastOwnerTeam == player.Team
if isAssistEligible and onSameTeam and lastNetworkOwner:IsA("Player") and lastNetworkOwner ~= player then
self:setAttribute("AssistPlayer", lastNetworkOwner)
self:setAttribute("AssistTime", os.clock())
task.spawn(function()
if lastNetworkOwner == nil then
return
end
GameService:BallPassed(lastNetworkOwner)
end)
elseif not onSameTeam then
self:setAttribute("AssistPlayer", nil)
self:setAttribute("AssistTime", os.clock())
end

lastNetworkOwner = player
if player then
if player:IsA("Player") then
self:setAttribute("OwnerName", player.DisplayName)
self:setAttribute("Team", player.Team.Name)
else
local teamName = player.Team.Value.Name
self:setAttribute("Team", teamName)
self:setAttribute("OwnerName", serverInfo:GetAttribute(teamName .. "Name") .. "'s Goalkeeper")
end
else
self:setAttribute("OwnerName", nil)
end
end

function ServerBallController:setAttribute(attribute: string, value: any)
self.attributes[attribute] = value

pcall(function()
self.attributeChanged:Fire(attribute, value)
end)
end

function ServerBallController:getAttribute(attribute: string)
return self.attributes[attribute]
end

function ServerBallController:setCooldown(attribute: string, cooldown: number)
local now = workspace:GetServerTimeNow()
local currentCD = self.attributes[attribute]
if currentCD and currentCD - now > cooldown then
return
end
self.attributes[attribute] = now + cooldown
end

function ServerBallController:removeCooldown(attribute: string)
self.attributes[attribute] = nil
end

function ServerBallController:getCooldown(attribute: string)
local value = self.attributes[attribute]
return value and math.max(0, value - workspace:GetServerTimeNow())
end

function ServerBallController:isOnCooldown(attribute: string, lagCompensation: number | nil)
local value = self.attributes[attribute]
if value and lagCompensation then
value += lagCompensation
end
return value and value - workspace:GetServerTimeNow() > 0
end

local flareGuid = nil
local netTouchedSignal = FastSignal.new()
function ServerBallController:CreateGoalEffect(teamScoredOn: string, callback: () -> () | nil)
local playerWhoScored: Player = Players:GetPlayerByUserId(self.simulation.state.netId)


local goalEffectTrove = Trove.new()
local ballPos = self.simulation.state.pos
local function doGoalEffect(net: MeshPart, setCFrame: boolean)
goalEffectTrove:Destroy()

if callback then
task.spawn(callback)
end

-- do goal effect stuff

-- if you want the ball to disappear after a goal
-- self:SetPosition(Vector3.zero)
-- self.simulation.state.guid += 1
-- self.simulation.state.action = Enums.BallActions.Teleport
self.simulation.state.netId = 0
end

local lastTouchedNet: MeshPart = self:getAttribute("LastTouchedNet")
if lastTouchedNet ~= nil and lastTouchedNet.Parent.Parent.Name == teamScoredOn then
ballPos = self:getAttribute("NetTouchedPos")
doGoalEffect(lastTouchedNet, true)
return
end

goalEffectTrove:Connect(netTouchedSignal, function(net: MeshPart)
if not net:HasTag("Net") or net.Parent.Parent.Name ~= teamScoredOn then
return
end
doGoalEffect(net, false)
end)
goalEffectTrove:Add(task.delay(1, doGoalEffect))
end

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = {CollectionService:GetTagged("GoalHitbox")}
function ServerBallController:OnTouchedGoal(goalHitbox)
local gameStatus = serverInfo:GetAttribute("GameStatus")
if gameStatus ~= "InProgress" and gameStatus ~= "Practice" then
return
end
if self:getAttribute("GoalScored") then
return
end
if self.simulation.state.ownerId ~= 0 then
return
end

local goalTeam = goalHitbox.Name
self:setAttribute("GoalTeam", goalTeam)
local function doScored()
scoreTrove:Clean()

if self:getAttribute("GoalScored") then
return
end
self:setAttribute("GoalScored", true)

if serverInfo:GetAttribute("GameStatus") == "InProgress" then
self:CreateGoalEffect(goalTeam, function()
GameService:GoalScored(goalTeam)
end)
elseif serverInfo:GetAttribute("GameStatus") == "Practice" then
self:CreateGoalEffect(goalTeam)
end
end

local teamGoalkeeper: Player = serverInfo[goalTeam].Goalkeeper.Value
if teamGoalkeeper == nil then
doScored()
else
if self:getAttribute("LagSaveLeniency") then
return
end
self:setAttribute("LagSaveLeniency", true)

local networkPing = teamGoalkeeper:GetNetworkPing()
if teamGoalkeeper.UserId < 0 then
networkPing = 0.5
end
local leniency = math.min(0.5, networkPing + 0.1)
scoreTrove:Add(task.delay(leniency, doScored))
scoreTrove:Connect(self.attributeChanged, function(attributeName, value)
if attributeName == "LagSaveLeniency" and value == nil then
scoreTrove:Clean()
elseif attributeName.Name == "GoalkeeperConfirmed" then
doScored()
end
end)
end
end


function ServerBallController:Destroy()
if self.pushPart then
self.pushPart:Destroy()
self.pushPart = nil
end

if self.hitBox then
self.hitBox:Destroy()
self.hitBox = nil
end

if self.pushes ~= nil then
for _, record in pairs(self.pushes) do
record.attachment:Destroy()
record.pusher:Destroy()
end
self.pushes = {}
end
end

function ServerBallController:HandleEvent(server, event)
-- self:HandleClientUnreliableEvent(server, event, false)
end

--[=[
Sets the position of the character and replicates it to clients.
]=]
function ServerBallController:SetPosition(position: Vector3, teleport)
self.simulation.state.pos = position
-- self.simulation.characterData:SetTargetPosition(position, teleport)
end

--[=[
Returns the position of the character.
]=]
function ServerBallController:GetPosition()
return self.simulation.state.pos
end

function ServerBallController:BallThink(server, deltaTime)
local command = {}
command.localFrame = self.ballRecord.frame
command.serverTime = tick()
command.deltaTime = deltaTime

local event = {}
event[1] = BallCommandLayout:EncodeCommand(command)
self:HandleClientUnreliableEvent(server, event, true)
end

function ServerBallController:GenerateFakeCommand(server, deltaTime, command: {}?)

command = command or {}
command.localFrame = self.unreliableCommandSerials + 1
command.deltaTime = deltaTime

local event = {}
event[1] = BallCommandLayout:EncodeCommand(command)
self:HandleClientUnreliableEvent(server, event, true)
-- print("created fake command")


-- self.debug.fakeCommandsThisSecond += 1
end

--[=[
Steps the simulation forward by one frame. This loop handles the simulation
and replication timings.
]=]
function ServerBallController:Think(server, _serverSimulationTime, deltaTime)
-- Anticheat methods
-- We keep X ms of commands unprocessed, so that if players stop sending upstream, we have some commands to keep going with
-- We only allow the player to get +150ms ahead of the servers estimated sim time (Speed cheat), if they're over this, we discard commands
-- The server will generate a fake command if you underrun (do not have any commands during time between snapshots)
-- todo: We only allow 15 commands per server tick (ratio of 5:1) if the user somehow has more than 15 commands that are legitimately needing processing, we discard them all

self.elapsedTime += deltaTime

--Sort commands by their serial
table.sort(self.unprocessedCommands, function(a, b)
return a.serial < b.serial
end)

local maxCommandsPerFrame = math.ceil(self.maxCommandsPerSecond * deltaTime)

local processCounter = 0
for _, command in pairs(self.unprocessedCommands) do

processCounter += 1

--print("server", command.l, command.serverTime)
TrajectoryModule:PositionWorld(command.serverTime, command.deltaTime)
self.debug.processedCommands += 1

--Step simulation!
self.simulation:DoServerAttributeChecks()
local hitCharacter: BasePart | Model, hitNet, moveDelta = self.simulation:ProcessCommand(command, server)
self:RobloxPhysicsStep(server)

if hitCharacter then
xpcall(function()
if hitCharacter:HasTag("Goalkeeper") then
CharacterService:ClaimBall(hitCharacter, true)
return
end

local userId = hitCharacter:GetAttribute("player")
if userId == nil then
return
end
local actualPlayer = Players:GetPlayerByUserId(userId)
if actualPlayer == nil then
return
end
if actualPlayer:GetAttribute("Position") ~= "Goalkeeper" and moveDelta < 0.01 then -- if barely moving, don't do server claim detection
return
end
CharacterService:ClaimBall(actualPlayer, true)
end, function(errorMessage)
warn("[ServerBallController] Think - hit player: " .. errorMessage)
end)
end
local pos = self.simulation.state.pos
local goalHitbox = workspace:GetPartBoundsInRadius(pos, 1, overlapParams)[1]
if goalHitbox then
xpcall(function()
self:OnTouchedGoal(goalHitbox)
end, function(errorMessage)
warn("[ServerBallController] Think - touched goal failed: " .. errorMessage)
end)
end
if hitNet then
xpcall(function()
if self:getAttribute("LastTouchedNet") == nil then
self:setAttribute("LastTouchedNet", hitNet)
self:setAttribute("NetTouchedPos", self.simulation.state.pos)
end
netTouchedSignal:Fire(hitNet)
end, function(errorMessage)
warn("[ServerBallController] Think - net touched signal failed: " .. errorMessage)
end)
end

command.processed = true

if command.localFrame and tonumber(command.localFrame) ~= nil then
self.lastConfirmedCommand = command.localFrame
self.lastProcessedCommand = command
end

self.processedTimeSinceLastSnapshot += command.deltaTime

if (processCounter > maxCommandsPerFrame and false) then
--dump the remaining commands
self.errorState = Enums.NetworkProblemState.TooManyCommands
self.unprocessedCommands = {}
break
end
end

local newList = {}
for _, command in pairs(self.unprocessedCommands) do
if command.processed ~= true then
table.insert(newList, command)
end
end

self.unprocessedCommands = newList


--debug stuff, too many commands a second stuff
if (tick() > self.debug.timeOfNextSecond) then

self.debug.timeOfNextSecond = tick() + 1
self.debug.antiwarpPerSecond = self.debug.fakeCommandsThisSecond
self.debug.fakeCommandsThisSecond = 0

if (self.debug.antiwarpPerSecond > 0) then
print("Lag: ",self.debug.antiwarpPerSecond )
end
end
end



--[=[
Callback for handling movement commands from the client

@param event table -- The event sent by the client.
@private
]=]
function ServerBallController:HandleClientUnreliableEvent(server, event, fakeCommand)

if (event[2] ~= nil) then
local prevCommand = BallCommandLayout:DecodeCommand(event[2])
self:ProcessCommand(server, prevCommand, fakeCommand, true)
end

if (event[1] ~= nil) then
local command = BallCommandLayout:DecodeCommand(event[1])
self:ProcessCommand(server, command, fakeCommand, false)
end
end

function ServerBallController:ProcessCommand(server, command, fakeCommand, resent)


if command and typeof(command) == "table" then

if (command.localFrame == nil or typeof(command.localFrame) ~= "number" or command.localFrame ~= command.localFrame) then
if fakeCommand then
print("1")
end
return
end

if (command.localFrame <= self.unreliableCommandSerials) then
if fakeCommand then
print("2")
print(command.localFrame, self.unreliableCommandSerials)
end
return
end

if (command.localFrame - self.unreliableCommandSerials > 1) then
-- if fakeCommand then
-- print("3")
-- end
--warn("Skipped a packet", command.l - self.unreliableCommandSerials)

if (resent) then
self.errorState = Enums.NetworkProblemState.DroppedPacketGood
else
self.errorState = Enums.NetworkProblemState.DroppedPacketBad
end
end

self.unreliableCommandSerials = command.localFrame

--Sanitize
--todo: clean this into a function per type

if command.deltaTime == nil
or typeof(command.deltaTime) ~= "number"
or command.deltaTime ~= command.deltaTime
then
if fakeCommand then
print("9")
end
return
end

--sanitize
if (fakeCommand == false) then
if server.config.fpsMode == Enums.FpsMode.Uncapped then
--Todo: really slow players need to be penalized harder.
if command.deltaTime > 0.5 then
command.deltaTime = 0.5
end

--500fps cap
if command.deltaTime < 1 / 500 then
command.deltaTime = 1 / 500
--print("Player over 500fps:", self.playerRecord.name)
end
elseif server.config.fpsMode == Enums.FpsMode.Hybrid then
--Players under 30fps are simualted at 30fps
if command.deltaTime > 1 / 30 then
command.deltaTime = 1 / 30
end

--500fps cap
if command.deltaTime < 1 / 500 then
command.deltaTime = 1 / 500
--print("Player over 500fps:", self.playerRecord.name)
end
elseif server.config.fpsMode == Enums.FpsMode.Fixed60 then
command.deltaTime = 1/60
elseif server.config.fpsMode == Enums.FpsMode.Fixed30 then
command.deltaTime = 1/20
else
warn("Unhandled FPS mode")
end
end

if command.deltaTime then
--On the first command, init
if self.playerElapsedTime == 0 then
self.playerElapsedTime = self.elapsedTime
end
local delta = self.playerElapsedTime - self.elapsedTime

--see if they've fallen too far behind
if (delta < -(self.speedCheatThreshhold / 1000)) then
self.playerElapsedTime = self.elapsedTime
self.errorState = Enums.NetworkProblemState.TooFarBehind
end

--test if this is wthin speed cheat range?
--print("delta", self.playerElapsedTime - self.elapsedTime)
if self.playerElapsedTime > self.elapsedTime + (self.speedCheatThreshhold / 1000) and not fakeCommand then
--print("Player too far ahead", self.playerRecord.name)
--Skipping this command
self.errorState = Enums.NetworkProblemState.TooFarAhead
else


--write it!
self.playerElapsedTime += command.deltaTime

command.elapsedTime = self.elapsedTime --Players real time when this was written.

command.playerElapsedTime = self.playerElapsedTime
command.fakeCommand = fakeCommand
command.serial = self.commandSerial
self.commandSerial += 1

--This is the only place where commands get written for the rest of the system
table.insert(self.unprocessedCommands, command)
end

--Debug ping
if (command.serverTime ~= nil and fakeCommand == false and self.playerRecord.dummy == false) then
self.debug.ping = math.floor((server.serverSimulationTime - command.serverTime) * 1000)
self.debug.ping -= ( (1 / server.config.serverHz) * 1000)
end
end
end

end

--Constructs a playerState based on "now" delta'd against the last playerState the player has confirmed seeing (self.lastConfirmedPlayerState)
--If they have not confirmed anything, return a whole state
function ServerBallController:ConstructBallStateDelta()

local currentState = self.simulation:WriteState()
local lastProcessedCommand = self.lastProcessedCommand or {}
return currentState, lastProcessedCommand.localFrame
end


--[=[
Picks a location to spawn the character and replicates it to the client.
@private
]=]
function ServerBallController:SpawnChickynoid()

--If you need to change anything about the chickynoid initial state like pos or rotation, use OnBeforePlayerSpawn
-- if self.playerRecord.dummy == false then
-- local event = {}
-- event.t = EventType.ChickynoidAdded
-- event.state = self.simulation:WriteState()
-- event.characterMod = self.playerRecord.characterMod
-- self.playerRecord:SendEventToClient(event)
-- end
--@@print("Spawned character and sent event for player:", self.playerRecord.name)
end

function ServerBallController:PostThink(server, deltaTime)
self:UpdateServerCollisionBox(server)

-- self.simulation.ballData:SmoothPosition(deltaTime, self.smoothFactor)
end

function ServerBallController:UpdateServerCollisionBox(server)
--Update their hitbox - this is used for raycasts on the server against the player
if self.hitBox == nil then
--This box is also used to stop physics props from intersecting the player. Doesn't always work!
--But if a player does get stuck, they should just be able to move away from it
local ball = ReplicatedStorage.Assets.Ball:Clone()
ball.Transparency = 0
ball.Size = Vector3.new(2, 2, 2)
ball.Parent = server.worldRoot
ball.CFrame = CFrame.new(self.simulation.state.pos)
ball.Anchored = true
ball.CanTouch = true
ball.CanCollide = false
ball.CanQuery = true
ball.Shape = Enum.PartType.Ball
ball:AddTag("ServerBallHitbox")
ball:SetAttribute("ballId", self.ballRecord.ballId)
self.hitBox = ball
self.hitBoxCreated:Fire(self.hitBox);
end
self.hitBox.CFrame = CFrame.new(self.simulation.state.pos)
self.hitBox.Velocity = self.simulation.state.vel
end

function ServerBallController:RobloxPhysicsStep(server, _deltaTime)

self:UpdateServerCollisionBox(server)

end

return ServerBallController
src/server/Chickynoid/Server/ServerChickynoid.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--!native
--[=[
@class ServerChickynoid
@server

Server-side character which exposes methods for manipulating a player's simulation
such as teleporting and applying impulses.
]=]

local path = game.ReplicatedFirst.Chickynoid

local Enums = require(path.Shared.Enums)
local EventType = Enums.EventType
local FastSignal = require(path.Shared.Vendor.FastSignal)

local Simulation = require(path.Shared.Simulation.Simulation)
local TrajectoryModule = require(path.Shared.Simulation.TrajectoryModule)

local DeltaTable = require(path.Shared.Vendor.DeltaTable)
local CommandLayout = require(path.Shared.Simulation.CommandLayout)
local DebugInfo = require(path.Shared.DebugInfo)

local ServerMods = require(script.Parent.ServerMods)

local Lib = require(ReplicatedStorage.Lib)



local ServerChickynoid = {}
ServerChickynoid.__index = ServerChickynoid

--[=[
Constructs a new [ServerChickynoid] and attaches it to the specified player.
@param playerRecord any -- The player record.
@return ServerChickynoid
]=]
function ServerChickynoid.new(playerRecord)
local self = setmetatable({
playerRecord = playerRecord,

simulation = Simulation.new(playerRecord.userId),

ballInfos = {},
unprocessedCommands = {},
commandSerial = 0,
lastConfirmedCommand = nil,
elapsedTime = 0,
playerElapsedTime = 0,

processedTimeSinceLastSnapshot = 0,

errorState = Enums.NetworkProblemState.None,

speedCheatThreshhold = 150 , --milliseconds

maxCommandsPerSecond = 120, --things have gone wrong if this is hit, but it's good server protection against possible uncapped fps
smoothFactor = 0.9999, --Smaller is smoother

serverFrames = 0,

hitBoxCreated = FastSignal.new(),
storedStates = {}, --table of the last few states we've send the client, because we use unreliables, we need to switch to ome of these to delta comrpess against once its confirmed

unreliableCommandSerials = 0, --This number only ever goes up, and discards anything out of order
lastConfirmedPlayerStateFrame = nil, --Client tells us they've seen this playerstate, so we delta compress against it

prevCharacterData = {}, -- Rolling history key'd to serverFrame

debug = {
processedCommands = 0,
fakeCommandsThisSecond = 0,
antiwarpPerSecond = 0,
timeOfNextSecond = 0,
ping = 0
},
}, ServerChickynoid)
-- TODO: The simulation shouldn't create a debug model like this.
-- For now, just delete it server-side.
if self.simulation.debugModel then
self.simulation.debugModel:Destroy()
self.simulation.debugModel = nil
end

--Apply the characterMod
if (self.playerRecord.characterMod) then
local loadedModule = ServerMods:GetMod("characters", self.playerRecord.characterMod)
if (loadedModule) then
loadedModule:Setup(self.simulation)
end
end

return self
end

function ServerChickynoid:Destroy()
if self.pushPart then
self.pushPart:Destroy()
self.pushPart = nil
end

if self.hitBox then
self.hitBox:Destroy()
self.hitBox = nil
end

if self.pushes ~= nil then
for _, record in pairs(self.pushes) do
record.attachment:Destroy()
record.pusher:Destroy()
end
self.pushes = {}
end
end

function ServerChickynoid:HandleEvent(server, event)
self:HandleClientUnreliableEvent(server, event, false)
end

--[=[
Sets the position of the character and replicates it to clients.
]=]
function ServerChickynoid:SetPosition(position: Vector3, teleport)
self.simulation.state.pos = position
self.simulation.characterData:SetTargetPosition(position, teleport)
end

--[=[
Returns the position of the character.
]=]
function ServerChickynoid:GetPosition()
return self.simulation.state.pos
end

function ServerChickynoid:GenerateFakeCommand(server, deltaTime)

if (self.lastProcessedCommand == nil) then
return
end

local command = DeltaTable:DeepCopy(self.lastProcessedCommand)
command.localFrame = self.unreliableCommandSerials + 1
command.deltaTime = deltaTime

local event = {}
event[1] = {
CommandLayout:EncodeCommand(command)
}
self:HandleClientUnreliableEvent(server, event, true)
-- print("created fake command")


-- self.debug.fakeCommandsThisSecond += 1
end

-- Ulldren's edits
function ServerChickynoid:GenerateKnockbackCommand(server, knockback: Vector3, duration: number, freeze: boolean?, tackle: boolean?)

if (self.lastProcessedCommand == nil) then
return
end

local command = DeltaTable:DeepCopy(self.lastProcessedCommand)

local player = game.Players:GetPlayerByUserId(self.playerRecord.userId)
local ping = Lib.getHiddenAttribute(player, "ServerNetworkPing") or player:GetNetworkPing()*1000
local pingFrames = math.clamp(ping / server.config.serverHz, 1, 100)
command.localFrame = self.unreliableCommandSerials + pingFrames
command.deltaTime = 0
command.knockback = knockback
command.knockbackDuration = duration
if freeze then
command.freeze = 1
end
if tackle then
command.tackleRagdoll = 1
end

local event = {}
event[1] = {
CommandLayout:EncodeCommand(command)
}
self:HandleClientUnreliableEvent(server, event, true)

-- self.debug.fakeCommandsThisSecond += 1
end

--[=[
Steps the simulation forward by one frame. This loop handles the simulation
and replication timings.
]=]
function ServerChickynoid:Think(server, _serverSimulationTime, deltaTime)
-- Anticheat methods
-- We keep X ms of commands unprocessed, so that if players stop sending upstream, we have some commands to keep going with
-- We only allow the player to get +150ms ahead of the servers estimated sim time (Speed cheat), if they're over this, we discard commands
-- The server will generate a fake command if you underrun (do not have any commands during time between snapshots)
-- todo: We only allow 15 commands per server tick (ratio of 5:1) if the user somehow has more than 15 commands that are legitimately needing processing, we discard them all

self.elapsedTime += deltaTime

--Sort commands by their serial
table.sort(self.unprocessedCommands, function(a, b)
return a.serial < b.serial
end)

local maxCommandsPerFrame = math.ceil(self.maxCommandsPerSecond * deltaTime)


self.simulation:DoPlayerAttributeChecks()
local processCounter = 0
for _, command in pairs(self.unprocessedCommands) do

processCounter += 1

--print("server", command.l, command.serverTime)
TrajectoryModule:PositionWorld(command.serverTime, command.deltaTime)
self.debug.processedCommands += 1

--Check for reset
self:CheckForReset(server, command)

--Step simulation!
self.simulation:ProcessCommand(command)
self:RobloxPhysicsStep(server)

--Fire weapons!
self.playerRecord:ProcessWeaponCommand(command)

command.processed = true

if command.localFrame and tonumber(command.localFrame) ~= nil then
self.lastConfirmedCommand = command.localFrame
self.lastProcessedCommand = command
end
local ballInfo = self.ballInfos[command.serial]
if ballInfo then
xpcall(function()
server:HandlePlayerBallInfo(self.playerRecord, ballInfo, command.serverTime)
end, function(errorMessage)
warn("[ServerChickynoid] Failed to process ball info: " .. errorMessage)
end)
end
self.ballInfos[command.serial] = nil

self.processedTimeSinceLastSnapshot += command.deltaTime

if (processCounter > maxCommandsPerFrame and false) then
--dump the remaining commands
self.errorState = Enums.NetworkProblemState.TooManyCommands
self.unprocessedCommands = {}
break
end
end

local newList = {}
for _, command in pairs(self.unprocessedCommands) do
if command.processed ~= true then
table.insert(newList, command)
end
end

self.unprocessedCommands = newList


--debug stuff, too many commands a second stuff
if (tick() > self.debug.timeOfNextSecond) then

self.debug.timeOfNextSecond = tick() + 1
self.debug.antiwarpPerSecond = self.debug.fakeCommandsThisSecond
self.debug.fakeCommandsThisSecond = 0

if (self.debug.antiwarpPerSecond > 0) then
print("Lag: ",self.debug.antiwarpPerSecond )
end
end
end



--[=[
Callback for handling movement commands from the client

@param event table -- The event sent by the client.
@private
]=]
local random = Random.new()
function ServerChickynoid:HandleClientUnreliableEvent(server, event, fakeCommand)
if DebugInfo.DEBUG then
if random:NextNumber() < DebugInfo.PACKET_LOSS then
return
end
task.wait(DebugInfo.PING/2)

local player = Players:GetPlayerByUserId(self.playerRecord.userId)
if player == nil then
return
end
end

if (event[2] ~= nil) then
local eventData = event[2]
local prevCommand = CommandLayout:DecodeCommand(eventData[1])
self:ProcessCommand(server, prevCommand, fakeCommand, true, eventData[2])
end

if (event[1] ~= nil) then
local eventData = event[1]
local command = CommandLayout:DecodeCommand(eventData[1])
self:ProcessCommand(server, command, fakeCommand, false, eventData[2])
end

end

function ServerChickynoid:CheckForReset(server, command)
if (command.reset == true) then
self.playerRecord.reset = true
end
end

function ServerChickynoid:ProcessCommand(server, command, fakeCommand, resent, ballInfo: {}?)


if command and typeof(command) == "table" then

if (command.localFrame == nil or typeof(command.localFrame) ~= "number" or command.localFrame ~= command.localFrame) then
if fakeCommand then
print("1")
end
return
end

if (command.localFrame <= self.unreliableCommandSerials) then
if fakeCommand then
print("2")
print(command.localFrame, self.unreliableCommandSerials)
end
return
end

if (command.localFrame - self.unreliableCommandSerials > 1) then
-- if fakeCommand then
-- print("3")
-- end
--warn("Skipped a packet", command.l - self.unreliableCommandSerials)

if (resent) then
self.errorState = Enums.NetworkProblemState.DroppedPacketGood
else
self.errorState = Enums.NetworkProblemState.DroppedPacketBad
end
end

self.unreliableCommandSerials = command.localFrame

--Sanitize
--todo: clean this into a function per type
if command.x == nil or typeof(command.x) ~= "number" or command.x ~= command.x then
if fakeCommand then
print("4")
end
return
end
if command.y == nil or typeof(command.y) ~= "number" or command.y ~= command.y then
if fakeCommand then
print("5")
end
return
end
if command.z == nil or typeof(command.z) ~= "number" or command.z ~= command.z then
if fakeCommand then
print("6")
end
return
end

if command.serverTime == nil or typeof(command.serverTime) ~= "number" or command.serverTime ~= command.serverTime then
if fakeCommand then
print("7")
end
return
end

if command.playerStateFrame == nil or typeof(command.playerStateFrame) ~= "number" or command.playerStateFrame ~= command.playerStateFrame then
if fakeCommand then
print("8")
end
return
end

if (command.snapshotServerFrame ~= nil) then

--0 is nil
if (command.snapshotServerFrame > 0) then
self.playerRecord.lastConfirmedSnapshotServerFrame = command.snapshotServerFrame
end
end

if command.deltaTime == nil
or typeof(command.deltaTime) ~= "number"
or command.deltaTime ~= command.deltaTime
then
if fakeCommand then
print("9")
end
return
end

if command.fa and (typeof(command.fa) == "Vector3") then
local vec = command.fa
if vec.X == vec.X and vec.Y == vec.Y and vec.Z == vec.Z then
command.fa = vec
else
command.fa = nil
end
else
command.fa = nil
end

if command.tackleDir and (typeof(command.tackleDir) == "Vector3") then
local vec = command.tackleDir
if vec.X == vec.X and vec.Y == vec.Y and vec.Z == vec.Z then
command.tackleDir = (vec * Vector3.new(1, 0, 1)).Unit
else
command.tackleDir = Vector3.zero
end
else
command.tackleDir = Vector3.zero
end
if command.diveDir and (typeof(command.diveDir) == "Vector3") then
local vec = command.diveDir
if vec.X == vec.X and vec.Y == vec.Y and vec.Z == vec.Z then
command.diveDir = (vec * Vector3.new(1, 0, 1)).Unit
else
command.diveDir = Vector3.zero
end
else
command.diveDir = Vector3.zero
end
if command.diveAnim and (type(command.diveAnim) == "number") then
command.diveAnim = math.floor(command.diveAnim)
if command.diveAnim > 2 then
command.diveAnim = 1
end
else
command.diveAnim = 1
end

--sanitize
if (fakeCommand == false) then
command.knockback = nil
command.knockbackDuration = nil
command.freeze = nil
command.tackleRagdoll = nil


self:SetLastSeenPlayerStateToServerFrame(command.playerStateFrame)

if server.config.fpsMode == Enums.FpsMode.Uncapped then
--Todo: really slow players need to be penalized harder.
if command.deltaTime > 0.5 then
command.deltaTime = 0.5
end

--500fps cap
if command.deltaTime < 1 / 500 then
command.deltaTime = 1 / 500
--print("Player over 500fps:", self.playerRecord.name)
end
elseif server.config.fpsMode == Enums.FpsMode.Hybrid then
--Players under 30fps are simualted at 30fps
if command.deltaTime > 1 / 30 then
command.deltaTime = 1 / 30
end

--500fps cap
if command.deltaTime < 1 / 500 then
command.deltaTime = 1 / 500
--print("Player over 500fps:", self.playerRecord.name)
end
elseif server.config.fpsMode == Enums.FpsMode.Fixed60 then
command.deltaTime = 1/60
elseif server.config.fpsMode == Enums.FpsMode.Fixed30 then
command.deltaTime = 1/20
else
warn("Unhandled FPS mode")
end
end


local player = Players:GetPlayerByUserId(self.playerRecord.userId)
if player then
local movementDisabled = player:GetAttribute("MovementDisabled") or player:GetAttribute("ServerChickyRagdoll") or player:GetAttribute("ServerChickyFrozen")
if movementDisabled then
command.x, command.y, command.z = 0, 0, 0
end
local canJumpWithBall = Lib.isOnHiddenCooldown(player, "CanJumpWithBall")
local hasBall = self.playerRecord.hasBall and not canJumpWithBall
if hasBall then
command.y = 0
end
if not self.playerRecord.hasBall then
command.skill = 0
end

local playerInGame = Lib.playerInGameOrPaused(player)
if not playerInGame then
command.sprinting = 0
command.charge = 0
command.skill = 0
end

if movementDisabled or hasBall or not playerInGame then
command.tackleDir = Vector3.zero
command.diveDir = Vector3.zero
end

local isGoalkeeper = player:GetAttribute("Position") == "Goalkeeper"
if isGoalkeeper then
command.tackleDir = Vector3.zero
else
command.diveDir = Vector3.zero
end
end

if command.deltaTime then
--On the first command, init
if self.playerElapsedTime == 0 then
self.playerElapsedTime = self.elapsedTime
end
local delta = self.playerElapsedTime - self.elapsedTime

--see if they've fallen too far behind
if (delta < -(self.speedCheatThreshhold / 1000)) then
self.playerElapsedTime = self.elapsedTime
self.errorState = Enums.NetworkProblemState.TooFarBehind
end

--test if this is wthin speed cheat range?
--print("delta", self.playerElapsedTime - self.elapsedTime)
if self.playerElapsedTime > self.elapsedTime + (self.speedCheatThreshhold / 1000) and not fakeCommand then
--print("Player too far ahead", self.playerRecord.name)
--Skipping this command
self.errorState = Enums.NetworkProblemState.TooFarAhead
else


--write it!
self.playerElapsedTime += command.deltaTime

command.elapsedTime = self.elapsedTime --Players real time when this was written.

command.playerElapsedTime = self.playerElapsedTime
command.fakeCommand = fakeCommand
command.serial = self.commandSerial
self.commandSerial += 1

--This is the only place where commands get written for the rest of the system

self.ballInfos[command.serial] = ballInfo -- unreliable event byte limit, don't need to type check
table.insert(self.unprocessedCommands, command)
end

--Debug ping
if (command.serverTime ~= nil and fakeCommand == false and self.playerRecord.dummy == false) then
self.debug.ping = math.floor((server.serverSimulationTime - command.serverTime) * 1000)
self.debug.ping -= ( (1 / server.config.serverHz) * 1000)

Lib.setHiddenAttribute(player, "ServerNetworkPing", math.max(1, self.debug.ping))
end
end
end

end

--We can only delta compress against states that we know for sure the player has seen
function ServerChickynoid:SetLastSeenPlayerStateToServerFrame(serverFrame : number)
--we have a queue of these, so find the one the player says they've seen and update to that one
local record = self.storedStates[serverFrame]
if (record ~= nil) then
self.lastSeenState = DeltaTable:DeepCopy(record)
self.lastConfirmedPlayerStateFrame = serverFrame

--delete any older than this
for timeStamp, record in self.storedStates do
if (timeStamp < serverFrame) then
self.storedStates[timeStamp] = nil
end
end
end
end

--Constructs a playerState based on "now" delta'd against the last playerState the player has confirmed seeing (self.lastConfirmedPlayerState)
--If they have not confirmed anything, return a whole state
function ServerChickynoid:ConstructPlayerStateDelta(serverFrame : number)

local currentState = self.simulation:WriteState()
if (self.lastSeenState == nil) then
self.storedStates[serverFrame] = DeltaTable:DeepCopy(currentState)
return currentState, nil
end

--we have one!
local stateDelta = DeltaTable:MakeDeltaTable(self.lastSeenState, currentState)
self.storedStates[serverFrame] = DeltaTable:DeepCopy(currentState)
return stateDelta, self.lastConfirmedPlayerStateFrame
end


--[=[
Picks a location to spawn the character and replicates it to the client.
@private
]=]
function ServerChickynoid:SpawnChickynoid()

--If you need to change anything about the chickynoid initial state like pos or rotation, use OnBeforePlayerSpawn
if self.playerRecord.dummy == false then
local event = {}
event.t = EventType.ChickynoidAdded
event.state = self.simulation:WriteState()
event.characterMod = self.playerRecord.characterMod
self.playerRecord:SendEventToClient(event)
end
--@@print("Spawned character and sent event for player:", self.playerRecord.name)
end

function ServerChickynoid:PostThink(server, deltaTime)
self:UpdateServerCollisionBox(server)

self.simulation.characterData:SmoothPosition(deltaTime, self.smoothFactor)
end

local assets = ReplicatedStorage.Assets
function ServerChickynoid:UpdateServerCollisionBox(server)
--Update their hitbox - this is used for raycasts on the server against the player
if self.hitBox == nil then
--This box is also used to stop physics props from intersecting the player. Doesn't always work!
--But if a player does get stuck, they should just be able to move away from it
local box = Instance.new("Part")
box.Size = Vector3.new(4, 5, 2)
box.Parent = server.worldRoot
box.CFrame = CFrame.new(self.simulation.state.pos) * CFrame.Angles(0, self.simulation.state.angle, 0)
box.Anchored = true
box.CanTouch = true
box.CanCollide = true
box.CanQuery = true
box.CollisionGroup = "Character"
if Players:GetPlayerByUserId(self.playerRecord.userId) then
box:AddTag("ServerCharacterHitbox")
end
box:SetAttribute("player", self.playerRecord.userId)
self.hitBox = box
self.hitBoxCreated:Fire(self.hitBox);

--for streaming enabled games...
if self.playerRecord.player then
self.playerRecord.player.ReplicationFocus = self.hitBox
end
end
self.hitBox.CFrame = CFrame.new(self.simulation.state.pos) * CFrame.Angles(0, self.simulation.state.angle, 0)
self.hitBox.Velocity = self.simulation.state.vel

local player = Players:GetPlayerByUserId(self.playerRecord.userId)
if player then
self.hitBox.Size = Vector3.new(4, 5, 2)
end
end

function ServerChickynoid:RobloxPhysicsStep(server, _deltaTime)

self:UpdateServerCollisionBox(server)

end

return ServerChickynoid
src/server/Chickynoid/Server/ServerMods.lua
--!native
local module = {}

module.mods = {}

--[=[
Registers a single ModuleScript as a mod.
@param mod ModuleScript -- Individual ModuleScript to be loaded as a mod.
]=]
function module:RegisterMod(context: string, mod: ModuleScript)

if not mod:IsA("ModuleScript") then
warn("Attempted to load", mod:GetFullName(), "as a mod but it is not a ModuleScript")
return
end

local contents = require(mod)

if (contents == nil) then
warn("Attempted to load", mod:GetFullName(), "as a mod, but it's contents is empty.")
return
end

if (self.mods[context] == nil) then
self.mods[context] = {}
end

--Mark the name and priorty
if (contents.GetPriority ~= nil) then
contents.priority = contents:GetPriority()
else
contents.priority = 0
end
contents.name = mod.Name

table.insert(self.mods[context], contents)

table.sort(self.mods[context], function(a,b)
return a.priority > b.priority
end)
end

--[=[
Registers all descendants under this container as a mod.
@param container Instance -- Container holding mods.
]=]
function module:RegisterMods(context: string, container: Instance)

for _, mod in ipairs(container:GetDescendants()) do
if not mod:IsA("ModuleScript") then
continue
end

module:RegisterMod(context, mod)
end
end

function module:GetMod(context, name)
local list = self.mods[context]

for key,contents in pairs(list) do
if (contents.name == name) then
return contents
end
end

return nil
end

function module:GetMods(context)

if (self.mods[context] == nil) then
self.mods[context] = {}
end
return self.mods[context]
end

return module
src/server/Chickynoid/Server/ServerModule.lua
--!native
--[=[
@class ChickynoidServer
@server

Server namespace for the Chickynoid package.
]=]

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local path = game.ReplicatedFirst.Chickynoid

local Enums = require(path.Shared.Enums)
local EventType = Enums.EventType
local ServerChickynoid = require(script.Parent.ServerChickynoid)
local ServerBallController = require(script.Parent.ServerBallController)
local CharacterData = require(path.Shared.Simulation.CharacterData)
local BallInfoLayout = require(path.Shared.Simulation.BallInfoLayout)
local DebugInfo = require(path.Shared.DebugInfo)


local DeltaTable = require(path.Shared.Vendor.DeltaTable)
local WeaponsModule = require(script.Parent.WeaponsServer)
local CollisionModule = require(path.Shared.Simulation.CollisionModule)
local Antilag = require(script.Parent.Antilag)
local BallPositionHistory = require(script.Parent.BallPositionHistory)
local FastSignal = require(path.Shared.Vendor.FastSignal)
local ServerMods = require(script.Parent.ServerMods)
local Animations = require(path.Shared.Simulation.Animations)

local Profiler = require(path.Shared.Vendor.Profiler)

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "ChickynoidReplication"
RemoteEvent.Parent = ReplicatedStorage

local UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
UnreliableRemoteEvent.Name = "ChickynoidUnreliableReplication"
UnreliableRemoteEvent.Parent = ReplicatedStorage

local ServerSnapshotGen = require(script.Parent.ServerSnapshotGen)

local ServerModule = {}

ServerModule.playerRecords = {}
ServerModule.loadingPlayerRecords = {}
ServerModule.serverStepTimer = 0
ServerModule.serverLastSnapshotFrame = -1 --Frame we last sent snapshots on
ServerModule.serverTotalFrames = 0
ServerModule.serverSimulationTime = 0
ServerModule.framesPerSecondCounter = 0 --Purely for stats
ServerModule.framesPerSecondTimer = 0 --Purely for stats
ServerModule.framesPerSecond = 0 --Purely for stats
ServerModule.accumulatedTime = 0 --fps

ServerModule.ballRecord = nil
ServerModule.serverBallStepTimer = 0
ServerModule.serverBallTotalFrames = 0

ServerModule.startTime = tick()
ServerModule.slots = {}
ServerModule.collisionRootFolder = nil
ServerModule.absoluteMaxSizeOfBuffer = 4096

ServerModule.playerSize = Vector3.new(2, 5, 2)


--[=[
@interface ServerConfig
@within ChickynoidServer
.maxPlayers number -- Theoretical max, use a byte for player id
.fpsMode FpsMode
.serverHz number
Server config for Chickynoid.
]=]
ServerModule.config = {
maxPlayers = 255,
fpsMode = Enums.FpsMode.Fixed60,
serverHz = 20,
antiWarp = false,
}

--API
ServerModule.OnPlayerSpawn = FastSignal.new()
ServerModule.OnPlayerDespawn = FastSignal.new()
ServerModule.OnBeforePlayerSpawn = FastSignal.new()
ServerModule.OnPlayerConnected = FastSignal.new() --Technically this is OnPlayerLoaded


ServerModule.flags = {}
ServerModule.flags.DEBUG_ANTILAG = false
ServerModule.flags.DEBUG_BOT_BANDWIDTH = false



ServerModule.CharacterService = nil



--[=[
Creates connections so that Chickynoid can run on the server.
]=]
function ServerModule:Setup()
self.worldRoot = self:GetDoNotReplicate()

Players.PlayerAdded:Connect(function(player)
self:PlayerConnected(player)
end)

--If there are any players already connected, push them through the connection function
for _, player in pairs(game.Players:GetPlayers()) do
self:PlayerConnected(player)
end

Players.PlayerRemoving:Connect(function(player)
self:PlayerDisconnected(player.UserId)
end)

RunService.Heartbeat:Connect(function(deltaTime)
self:RobloxHeartbeat(deltaTime)
end)

RunService.Stepped:Connect(function(_, deltaTime)
self:RobloxPhysicsStep(deltaTime)
end)

UnreliableRemoteEvent.OnServerEvent:Connect(function(player: Player, event)
local playerRecord = self:GetPlayerByUserId(player.UserId)

if playerRecord then
if playerRecord.chickynoid then
playerRecord.chickynoid:HandleEvent(self, event)
end
end
end)

RemoteEvent.OnServerEvent:Connect(function(player: Player, event: any)

--Handle events from loading players
local loadingPlayerRecord = ServerModule.loadingPlayerRecords[player.UserId]

if (loadingPlayerRecord ~= nil) then
if (event.id == "loaded") then
if (loadingPlayerRecord.loaded == false) then
loadingPlayerRecord:HandlePlayerLoaded()
end
end
return
end

end)

Animations:ServerSetup()

WeaponsModule:Setup(self)

Antilag:Setup(self)
BallPositionHistory:Setup(self)

--Load the mods
local modules = ServerMods:GetMods("servermods")
for _, mod in pairs(modules) do
mod:Setup(self)
-- print("Loaded", _)
end
end

function ServerModule:PlayerConnected(player)
local playerRecord = self:AddConnection(player.UserId, player)

if (playerRecord) then
--Spawn the gui
for _, child in pairs(game.StarterGui:GetChildren()) do
local clone = child:Clone() :: ScreenGui
if clone:IsA("ScreenGui") then
clone.ResetOnSpawn = false
end
clone.Parent = playerRecord.player.PlayerGui
end
end

end

function ServerModule:AssignSlot(playerRecord)

--Only place this is assigned
for j = 1, self.config.maxPlayers do
if self.slots[j] == nil then
self.slots[j] = playerRecord
playerRecord.slot = j
return true
end
end
warn("Slot not found!")
return false
end

type PlayerRecord = {
userId: number,
hasBall: boolean,

slot: number,
loaded: boolean,
chickynoid: typeof(ServerChickynoid),
frame: number,
pendingWorldState: boolean,
visHistoryList: {},
characterMod: string,
lastConfirmedSnapshotServerFrame: number,

SendEventToClient: (self: PlayerRecord, event: {}) -> (),
SendUnreliableEventToClient: (self: PlayerRecord, event: {}) -> (),
SendEventToClients: (self: PlayerRecord, event: {}) -> (),
SendEventToOtherClients: (self: PlayerRecord, event: {}) -> (),
SendCollisionData: (self: PlayerRecord, event: {}) -> (),
Despawn: (self: PlayerRecord, event: {}) -> (),
SetCharacterMod: (self: PlayerRecord, event: {}) -> (),
Spawn: (self: PlayerRecord, event: {}) -> (),
HandlePlayerLoaded: (self: PlayerRecord, event: {}) -> (),
}

function ServerModule:AddConnection(userId, player)
if self.playerRecords[userId] ~= nil or self.loadingPlayerRecords[userId] ~= nil then
warn("Player was already connected.", userId)
self:PlayerDisconnected(userId)
end

--Create the players server connection record
local playerRecord = {}
self.loadingPlayerRecords[userId] = playerRecord

playerRecord.userId = userId
playerRecord.hasBall = false

playerRecord.slot = 0 -- starts 0, 0 is an invalid slot.
playerRecord.loaded = false

playerRecord.previousCharacterData = nil
playerRecord.chickynoid = nil :: typeof(ServerChickynoid)
playerRecord.frame = 0

playerRecord.pendingWorldState = true

playerRecord.allowedToSpawn = true
playerRecord.respawnDelay = 1
playerRecord.respawnTime = tick() + playerRecord.respawnDelay

playerRecord.OnBeforePlayerSpawn = FastSignal.new()
playerRecord.visHistoryList = {}

playerRecord.characterMod = "HumanoidChickynoid"

playerRecord.lastConfirmedSnapshotServerFrame = nil --Stays nil til a player confirms they've seen a whole snapshot, for delta compression purposes

local assignedSlot = self:AssignSlot(playerRecord)
self:DebugSlots()
if (assignedSlot == false) then
if (player ~= nil) then
player:Kick("Server full, no free chickynoid slots")
end
self.loadingPlayerRecords[userId] = nil
return nil
end


playerRecord.player = player
if playerRecord.player ~= nil then
playerRecord.dummy = false
playerRecord.name = player.name
else
--Is a bot
playerRecord.dummy = true
end

-- selene: allow(shadowing)
function playerRecord:SendEventToClient(event)
if (playerRecord.loaded == false) then
print("warning, player not loaded yet")
end
if playerRecord.player then
RemoteEvent:FireClient(playerRecord.player, event)
end
end

-- selene: allow(shadowing)
function playerRecord:SendUnreliableEventToClient(event)
if (playerRecord.loaded == false) then
print("warning, player not loaded yet")
end
if playerRecord.player == nil then
return
end
if DebugInfo.DEBUG then
task.delay(DebugInfo.PING/2, function()
UnreliableRemoteEvent:FireClient(playerRecord.player, event)
end)
else
UnreliableRemoteEvent:FireClient(playerRecord.player, event)
end
end

-- selene: allow(shadowing)
function playerRecord:SendEventToClients(event)
if playerRecord.player then
for _, record in ServerModule.playerRecords do
if record.loaded == false or record.dummy == true then
continue
end
RemoteEvent:FireClient(record.player, event)
end
end
end

-- selene: allow(shadowing)
function playerRecord:SendEventToOtherClients(event)
for _, record in ServerModule.playerRecords do
if record.loaded == false or record.dummy == true then
continue
end
if record == playerRecord then
continue
end
RemoteEvent:FireClient(record.player, event)
end
end

-- selene: allow(shadowing)
function playerRecord:SendCollisionData()

if ServerModule.collisionRootFolder ~= nil then
local event = {}
event.t = Enums.EventType.CollisionData
event.playerSize = ServerModule.playerSize
event.data = ServerModule.collisionRootFolder
self:SendEventToClient(event)
end
end

-- selene: allow(shadowing)
function playerRecord:Despawn()
if self.chickynoid then
ServerModule.OnPlayerDespawn:Fire(self)

print("Despawned!")
self.chickynoid:Destroy()
self.chickynoid = nil
self.respawnTime = tick() + self.respawnDelay

local event = { t = EventType.ChickynoidRemoving }
playerRecord:SendEventToClient(event)
end
end

function playerRecord:SetCharacterMod(characterModName)
self.characterMod = characterModName
ServerModule:SetWorldStateDirty()
end

-- selene: allow(shadowing)
function playerRecord:Spawn()

if (playerRecord.loaded == false) then
warn("Spawn() called before player loaded")
return
end
self:Despawn()

local chickynoid = ServerChickynoid.new(playerRecord)
self.chickynoid = chickynoid
chickynoid.playerRecord = self

local list = {}
for _, obj: SpawnLocation in pairs(workspace:GetDescendants()) do
if obj:IsA("SpawnLocation") and obj.Enabled == true then
table.insert(list, obj)
end
end

if #list > 0 then
local spawn = list[math.random(1, #list)]
chickynoid:SetPosition(Vector3.new(spawn.Position.x, spawn.Position.y + 5, spawn.Position.z), true)

local _, yRot, _ = spawn.CFrame:ToEulerAnglesYXZ()
chickynoid.simulation:SetAngle(yRot, true)
else
chickynoid:SetPosition(Vector3.new(0, 10, 0), true)
end

self.OnBeforePlayerSpawn:Fire()
ServerModule.OnBeforePlayerSpawn:Fire(self, playerRecord)

chickynoid:SpawnChickynoid()

ServerModule.OnPlayerSpawn:Fire(self, playerRecord)
return self.chickynoid
end

function playerRecord:HandlePlayerLoaded()

print("Player loaded:", playerRecord.name)
playerRecord.loaded = true

--Move them from loadingPlayerRecords to playerRecords
ServerModule.playerRecords[playerRecord.userId] = playerRecord
ServerModule.loadingPlayerRecords[playerRecord.userId] = nil

self:SendCollisionData()

WeaponsModule:OnPlayerConnected(ServerModule, playerRecord)

ServerModule.OnPlayerConnected:Fire(ServerModule, playerRecord)
ServerModule:SetWorldStateDirty()
end


return playerRecord
end

function ServerModule:AddBall()
if self.ballRecord ~= nil then
return
end

--Create the players server connection record
local ballRecord = {}
ballRecord.characterMod = "DefaultBallController"

ballRecord.previousCharacterData = nil

local ballController = ServerBallController.new(ballRecord)
ballController.playerRecord = self
ballController:SpawnChickynoid()
ballRecord.ballController = ballController
ballRecord.frame = 0

local server = self
function ballRecord:Spawn(position: Vector3)
ballController:SetPosition(position, true)

local ballState = ballController.simulation.state
ballState.vel = Vector3.zero
ballState.angVel = Vector3.zero
ballState.guid += 1
ballState.action = Enums.BallActions.Teleport

ballController:setBallOwner(server, 0)
ballController:setNetworkOwner(server, 0)
ballController:setAttribute("HitTime", nil)
ballController.attributes = {}

task.spawn(function()
ballController.ballSpawned:Fire()
end)

server:SetWorldStateDirty()

return self.ballController
end

self.ballRecord = ballRecord

return ballRecord
end

function ServerModule:SendEventToClients(event)
RemoteEvent:FireAllClients(event)
end

function ServerModule:SetWorldStateDirty()
for _, data in pairs(self.playerRecords) do
data.pendingWorldState = true
end
end

function ServerModule:SendWorldState(playerRecord)

if (playerRecord.loaded == false) then
return
end

local event = {}
event.t = Enums.EventType.WorldState
event.worldState = {}
event.worldState.flags = self.flags

event.worldState.players = {}
for _, data in pairs(self.playerRecords) do
local info = {}
info.name = data.name
info.userId = data.userId
info.characterMod = data.characterMod
info.avatar = data.avatarDescription
event.worldState.players[tostring(data.slot)] = info
end

event.worldState.serverHz = self.config.serverHz
event.worldState.fpsMode = self.config.fpsMode
event.worldState.animations = Animations.animations

playerRecord:SendEventToClient(event)

playerRecord.pendingWorldState = false
end

function ServerModule:PlayerDisconnected(userId)

local loadingPlayerRecord = self.loadingPlayerRecords[userId]
if (loadingPlayerRecord ~= nil) then
print("Player ".. loadingPlayerRecord.player.Name .. " disconnected")
self.loadingPlayerRecords[userId] = nil
end

local playerRecord = self.playerRecords[userId]
if playerRecord then
print("Player ".. playerRecord.player.Name .. " disconnected")

playerRecord:Despawn()

--nil this out
playerRecord.previousCharacterData = nil
self.slots[playerRecord.slot] = nil
playerRecord.slot = nil

self.playerRecords[userId] = nil

self:DebugSlots()
end

--Tell everyone
for _, data in pairs(self.playerRecords) do
local event = {}
event.t = Enums.EventType.PlayerDisconnected
event.userId = userId
data:SendEventToClient(event)
end
self:SetWorldStateDirty()
end

function ServerModule:DebugSlots()
--print a count
local free = 0
local used = 0
for j = 1, self.config.maxPlayers do
if self.slots[j] == nil then
free += 1

else
used += 1
end
end
print("Players:", used, " (Free:", free, ")")
end

function ServerModule:GetPlayerByUserId(userId): PlayerRecord?
return self.playerRecords[userId]
end

function ServerModule:GetPlayers()
return self.playerRecords
end

function ServerModule:RobloxHeartbeat(deltaTime)

if (true) then
self.accumulatedTime += deltaTime

local frac = 1/30
if self.config.fpsMode == Enums.FpsMode.Fixed60 then
frac = 1/60
elseif self.config.fpsMode == Enums.FpsMode.Fixed30 then
frac = 1/20
else
warn("Unhandled FPS mode")
end

local maxSteps = 0
while self.accumulatedTime > 0 do
self.accumulatedTime -= frac
self:Think(frac)

maxSteps+=1
if (maxSteps > 2) then
self.accumulatedTime = 0
break
end
end

--Discard accumulated time if its a tiny fraction
local errorSize = 0.001 --1ms
if self.accumulatedTime > -errorSize then
self.accumulatedTime = 0
end
else

--Much simpler - assumes server runs at 60.
self.accumulatedTime = 0
local frac = 1 / 60
self:Think(deltaTime)
end


end

function ServerModule:RobloxPhysicsStep(deltaTime)
for _, playerRecord in pairs(self.playerRecords) do
if playerRecord.chickynoid then
playerRecord.chickynoid:RobloxPhysicsStep(self, deltaTime)
end
end
end

function ServerModule:GetDoNotReplicate()
local camera = game.Workspace:FindFirstChild("DoNotReplicate")
if camera == nil then
camera = Instance.new("Camera")
camera.Name = "DoNotReplicate"
camera.Parent = game.Workspace
end
return camera
end

function ServerModule:UpdateTiming(deltaTime)
--Do fps work
self.framesPerSecondCounter += 1
self.framesPerSecondTimer += deltaTime
if self.framesPerSecondTimer > 1 then
self.framesPerSecondTimer = math.fmod(self.framesPerSecondTimer, 1)
self.framesPerSecond = self.framesPerSecondCounter
self.framesPerSecondCounter = 0
end

self.serverSimulationTime = tick() - self.startTime
end

function ServerModule:Think(deltaTime)

self:UpdateTiming(deltaTime)

self:SendWorldStates()

self:SpawnPlayers()

CollisionModule:UpdateDynamicParts()

self:UpdateBallThinks(deltaTime)
self:UpdateBallPostThinks(deltaTime)
BallPositionHistory:WriteBallPosition(self.serverSimulationTime)

self:UpdatePlayerThinks(deltaTime)
self:UpdatePlayerPostThinks(deltaTime)

WeaponsModule:Think(self, deltaTime)

self:StepServerMods(deltaTime)

self:Do20HzOperations(deltaTime)
self:UpdateBallStatesToPlayers()
end

function ServerModule:StepServerMods(deltaTime)
--Step the server mods
local modules = ServerMods:GetMods("servermods")
for _, mod in pairs(modules) do
if (mod.Step) then
mod:Step(self, deltaTime)
end
end
end


function ServerModule:Do20HzOperations(deltaTime)

--Calc timings
self.serverStepTimer += deltaTime
self.serverTotalFrames += 1

local fraction = (1 / self.config.serverHz)

--Too soon
if self.config.fpsMode ~= Enums.FpsMode.Fixed30 then
if self.serverStepTimer < fraction then
return
end

while self.serverStepTimer > fraction do -- -_-'
self.serverStepTimer -= fraction
end
end


self:WriteCharacterDataForSnapshots()

--Playerstate, for reconciliation of client prediction
self:UpdatePlayerStatesToPlayers()

--we write the antilag at 20hz, to match when we replicate snapshots to players
Antilag:WritePlayerPositions(self.serverSimulationTime)

--Figures out who can see who, for replication purposes
self:DoPlayerVisibilityCalculations()

--Generate the snapshots for all players
self:WriteSnapshotsForPlayers()

end


function ServerModule:WriteCharacterDataForSnapshots()

for userId, playerRecord in pairs(self.playerRecords) do
if (playerRecord.chickynoid == nil) then
continue
end

--Grab a copy at this serverTotalFrame, because we're going to be referencing this for building snapshots with
playerRecord.chickynoid.prevCharacterData[self.serverTotalFrames] = DeltaTable:DeepCopy( playerRecord.chickynoid.simulation.characterData)

--Toss it out if its over a second old
for timeStamp, rec in playerRecord.chickynoid.prevCharacterData do
if (timeStamp < self.serverTotalFrames - 60) then
playerRecord.chickynoid.prevCharacterData[timeStamp] = nil
end
end
end
end

function ServerModule:KnockbackPlayer(player: Player, knockback: Vector3, duration: number, freeze: boolean?, tackle: boolean?)
if typeof(knockback) ~= "Vector3" then
return warn("[ServerModule] KnockbackPlayer - Wrong type (knockback)!")
end
if type(duration) ~= "number" then
return warn("[ServerModule] KnockbackPlayer - Wrong type (duration)!")
end

local playerRecord = self:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end

local chickynoid = playerRecord.chickynoid
if chickynoid == nil then
return
end

chickynoid:GenerateKnockbackCommand(self, knockback, duration, freeze, tackle)
chickynoid:Think(self, self.serverSimulationTime, 0)

playerRecord.chickynoid.processedTimeSinceLastSnapshot = 0

--Send results of server move
local event = {}
event.t = EventType.State


--bonus fields
event.e = playerRecord.chickynoid.errorState
event.s = self.framesPerSecond

--required fields
event.lastConfirmedCommand = playerRecord.chickynoid.lastConfirmedCommand
event.serverTime = self.serverSimulationTime
event.serverFrame = self.serverTotalFrames
event.playerStateDelta, event.playerStateDeltaFrame = playerRecord.chickynoid:ConstructPlayerStateDelta(self.serverTotalFrames)

playerRecord:SendUnreliableEventToClient(event)

--Clear the error state flag
playerRecord.chickynoid.errorState = Enums.NetworkProblemState.None
end

function ServerModule:UpdatePlayerStatesToPlayers()

for userId, playerRecord in pairs(self.playerRecords) do

--Bots dont generate snapshots, unless we're testing for performance
if (self.flags.DEBUG_BOT_BANDWIDTH ~= true) then
if playerRecord.dummy == true then
continue
end
end

if playerRecord.chickynoid ~= nil then

--see if we need to antiwarp people

local player = Players:GetPlayerByUserId(userId)
if player:GetAttribute("MovementDisabled")
-- or playerRecord.chickynoid.simulation.state.knockback > 0
then
local timeElapsed = playerRecord.chickynoid.processedTimeSinceLastSnapshot

local possibleStep = playerRecord.chickynoid.elapsedTime - playerRecord.chickynoid.playerElapsedTime

if (timeElapsed == 0 and playerRecord.chickynoid.lastProcessedCommand ~= nil) then
--This player didn't move this snapshot
playerRecord.chickynoid.errorState = Enums.NetworkProblemState.CommandUnderrun

local timeToPatchOver = 1 / self.config.serverHz
playerRecord.chickynoid:GenerateFakeCommand(self, timeToPatchOver)

--print("Adding fake command ", timeToPatchOver)

--Move them.
playerRecord.chickynoid:Think(self, self.serverSimulationTime, 0)
end
--print("e:" , timeElapsed * 1000)
end

playerRecord.chickynoid.processedTimeSinceLastSnapshot = 0

--Send results of server move
local event = {}
event.t = EventType.State


--bonus fields
event.e = playerRecord.chickynoid.errorState
event.s = self.framesPerSecond

--required fields
event.lastConfirmedCommand = playerRecord.chickynoid.lastConfirmedCommand
event.serverTime = self.serverSimulationTime
event.serverFrame = self.serverTotalFrames
event.playerStateDelta, event.playerStateDeltaFrame = playerRecord.chickynoid:ConstructPlayerStateDelta(self.serverTotalFrames)


local ballRecord = self.ballRecord
if ballRecord.ballController ~= nil then
event.ballState, event.ballFrame = ballRecord.ballController:ConstructBallStateDelta()
end


playerRecord:SendUnreliableEventToClient(event)

--Clear the error state flag
playerRecord.chickynoid.errorState = Enums.NetworkProblemState.None
end


end

end

function ServerModule:UpdateBallStatesToPlayers()
if true then
return
end


local ballRecord = self.ballRecord
local ballController = ballRecord.ballController
if ballController == nil then
return
end
if self.lastGuid == ballController.simulation.state.guid then
return
end
self.lastGuid = ballController.simulation.state.guid

for userId, playerRecord in pairs(self.playerRecords) do

--Bots dont generate snapshots, unless we're testing for performance
if (self.flags.DEBUG_BOT_BANDWIDTH ~= true) then
if playerRecord.dummy == true then
continue
end
end

if playerRecord.chickynoid ~= nil then

--Send results of server move
local event = {}
event.t = EventType.BallState

event.serverFrame = self.serverTotalFrames

event.lastConfirmedCommand = playerRecord.chickynoid.lastConfirmedCommand
if event.lastConfirmedCommand == nil then
continue
end

event.serverTime = self.serverSimulationTime
-- if ballController.simulation.state.netId == playerRecord.userId then
-- continue
-- end


event.ballState, event.ballFrame = ballController:ConstructBallStateDelta()
if event.ballState == nil then
continue
end
playerRecord:SendUnreliableEventToClient(event)
end


end
end

function ServerModule:SendWorldStates()
--send worldstate
for _, playerRecord in pairs(self.playerRecords) do
if (playerRecord.pendingWorldState == true) then
self:SendWorldState(playerRecord)
end
end
end

function ServerModule:SpawnPlayers()
--Spawn players
for _, playerRecord in self.playerRecords do
if (playerRecord.loaded == false) then
continue
end

-- if (playerRecord.chickynoid ~= nil and playerRecord.reset == true) then
-- playerRecord.reset = false
-- playerRecord:Despawn()
-- end

if playerRecord.chickynoid == nil and playerRecord.allowedToSpawn == true then
if tick() > playerRecord.respawnTime then
playerRecord:Spawn()
end
end
end
end

local services = script.Parent.Parent.Parent.Services
local GameService = require(services.GameService)
function ServerModule:UpdatePlayerThinks(deltaTime)

debug.profilebegin("UpdatePlayerThinks")
--1st stage, pump the commands
for _, playerRecord in self.playerRecords do
if playerRecord.dummy == true then
playerRecord.BotThink(deltaTime)
end

if playerRecord.chickynoid then
playerRecord.chickynoid:Think(self, self.serverSimulationTime, deltaTime)
pcall(function()
local selectPart = playerRecord.chickynoid.simulation:GetStandingPart()
if selectPart == nil then
return
end
if selectPart.Parent.Name ~= "MapSelect" then
return
end
local player = Players:GetPlayerByUserId(playerRecord.userId)
if player == nil then
return
end
GameService:VoteForMap(player, tonumber(selectPart.Name))
end)

if playerRecord.chickynoid.simulation.state.pos.y < -2000 then
playerRecord:Despawn()
end
end
end
debug.profileend()
end

function ServerModule:UpdatePlayerPostThinks(deltaTime)


for _, playerRecord in self.playerRecords do
if playerRecord.chickynoid then
playerRecord.chickynoid:PostThink(self, deltaTime)
end
end

end

function ServerModule:UpdateBallThinks(deltaTime)

debug.profilebegin("UpdateBallThinks")
--1st stage, pump the commands
local ballRecord = self.ballRecord
if ballRecord.ballController then
ballRecord.ballController:GenerateFakeCommand(self, deltaTime)
ballRecord.ballController:Think(self, self.serverSimulationTime, deltaTime)

-- if ballRecord.ballController.simulation.state.pos.y < -2000 then
-- ballRecord:Despawn()
-- end
end
debug.profileend()
end

function ServerModule:UpdateBallPostThinks(deltaTime)

local ballRecord = self.ballRecord
if ballRecord.ballController then
ballRecord.ballController:PostThink(self, deltaTime)
end

end

function ServerModule:DoPlayerVisibilityCalculations()

debug.profilebegin("DoPlayerVisibilityCalculations")

--This gets done at 20hz
local modules = ServerMods:GetMods("servermods")

for key,mod in modules do
if (mod.UpdateVisibility ~= nil) then
mod:UpdateVisibility(self, self.flags.DEBUG_BOT_BANDWIDTH)
end
end


--Store the current visibility table for the current server frame
for userId, playerRecord in self.playerRecords do
playerRecord.visHistoryList[self.serverTotalFrames] = playerRecord.visibilityList

--Store two seconds tops
local cutoff = self.serverTotalFrames - 120
if (playerRecord.lastConfirmedSnapshotServerFrame ~= nil) then
cutoff = math.max(playerRecord.lastConfirmedSnapshotServerFrame, cutoff)
end

for timeStamp, rec in playerRecord.visHistoryList do
if (timeStamp < cutoff) then
playerRecord.visHistoryList[timeStamp] = nil
end
end
end

debug.profileend()
end


function ServerModule:WriteSnapshotsForPlayers()

ServerSnapshotGen:DoWork(self.playerRecords, self.serverTotalFrames, self.serverSimulationTime, self.flags.DEBUG_BOT_BANDWIDTH)

self.serverLastSnapshotFrame = self.serverTotalFrames

end

function ServerModule:RecreateCollisions(rootFolder)
self.collisionRootFolder = rootFolder

for _, playerRecord in self.playerRecords do
playerRecord:SendCollisionData()
end

CollisionModule:MakeWorld(self.collisionRootFolder, self.playerSize)
end






-- Ball
local ballHitbox = Instance.new("Part")
ballHitbox.Shape = Enum.PartType.Ball
ballHitbox.Size = Vector3.new(2, 2, 2)
ballHitbox.Transparency = 0
ballHitbox.Anchored = true
ballHitbox.CanCollide = true
ballHitbox.CanQuery = true
ballHitbox.CanTouch = true

local characterHitbox = Instance.new("Part")
characterHitbox.Shape = Enum.PartType.Block
characterHitbox.Size = Vector3.new(4, 5, 1) + Vector3.one
characterHitbox.Transparency = 1
characterHitbox.Anchored = true
characterHitbox.CanCollide = false
characterHitbox.CanQuery = true
characterHitbox.CanTouch = false

local characterHitbox2 = Instance.new("Part")
characterHitbox2.Shape = Enum.PartType.Block
characterHitbox2.Size = Vector3.new(4, 5, 1) + Vector3.one
characterHitbox2.Transparency = 0
characterHitbox2.Anchored = true
characterHitbox2.CanCollide = false
characterHitbox2.CanQuery = false
characterHitbox2.CanTouch = false



type BallInfo = {
tackledEnemy: number?,
skill: number?,

claimPos: Vector3?,
shotInfo: {
guid: number,
shotType: string,
shotPower: number,
shotDirection: Vector3,
curveFactor: number,
}?,
deflectInfo: {
guid: number,
shotType: string,
shotPower: number,
shotDirection: Vector3,
curveFactor: number,
serverDeflect: boolean,
}?,

enteredGoal: number?,
}

local Lib = require(ReplicatedStorage.Lib)

local EffectService = require(services.EffectService)

local GameInfo = require(ReplicatedStorage.Data.GameInfo)

local t = require(ReplicatedStorage.Modules.t)
local Trove = require(ReplicatedStorage.Modules.Trove)

local privateServerInfo = ReplicatedStorage.PrivateServerInfo

local assets = ReplicatedStorage.Assets


function ServerModule:HandlePlayerBallInfo(playerRecord: PlayerRecord, ballInfo: BallInfo, serverTime: number)
-- Note: make sure to validate these types later
if playerRecord == nil or playerRecord.chickynoid == nil then
return
end
local simulation = playerRecord.chickynoid.simulation

local ballRecord = self.ballRecord
local ballController = ballRecord.ballController
if ballController == nil then
return
end

local ballSimulation = ballController.simulation

local player = Players:GetPlayerByUserId(playerRecord.userId)
if not Lib.playerInGame(player) or Lib.playerIsStunned(player) then
return
end

local isGoalkeeper = player:GetAttribute("Position") == "Goalkeeper"
characterHitbox.Size = Vector3.new(4, 5, 1) + Vector3.one


local function pushBallForward()
local frac = 1/60
if self.config.FpsMode == Enums.FpsMode.Fixed30 then
frac = 1/20
end
self:UpdateBallThinks(frac)
self:UpdateBallPostThinks(frac)
BallPositionHistory:WriteBallPosition(self.serverSimulationTime)
end


ballInfo = BallInfoLayout:DecodeCommand(ballInfo)

-- sanitize
for idx, value in pairs(table.clone(ballInfo)) do
if type(value) == "number" then
if value == 0 then
ballInfo[idx] = nil
end
elseif typeof(value) == "Vector3" then
if value.Magnitude == 0 then
ballInfo[idx] = nil
end
end
end

-- convert to normal layout
if ballInfo.sGuid then
local shotSerial = {"Shoot"}
ballInfo.sType = shotSerial[ballInfo.sType]
ballInfo.shotInfo = {
guid = ballInfo.sGuid,
shotType = ballInfo.sType,
shotPower = ballInfo.sPower,
shotDirection = ballInfo.sDirection,
curveFactor = ballInfo.sCurveFactor or 0,
}
end
if ballInfo.dGuid then
local shotSerial = {"DeflectShoot"}
ballInfo.dType = shotSerial[ballInfo.dType]
ballInfo.deflectInfo = {
guid = ballInfo.dGuid,
shotType = ballInfo.dType,
shotPower = ballInfo.dPower or 0, -- volley compatibility
shotDirection = ballInfo.dDirection,
curveFactor = ballInfo.dCurveFactor or 0,
serverDeflect = ballInfo.dServerDeflect == 1,
}
end


if ballInfo.enteredGoal then
if not isGoalkeeper then
return
end
if not ballController:getAttribute("LagSaveLeniency") then
return
end
if ballController:getAttribute("GoalkeeperConfirmed") then
return
end
if player.Team.Name ~= ballController:getAttribute("GoalTeam") then
return
end
ballController:setAttribute("GoalkeeperConfirmed", true)

return
end

-- local serverTime = self.serverSimulationTime
local skillServerTime = ballInfo.skill
if skillServerTime then
if type(skillServerTime) ~= "number" or skillServerTime ~= skillServerTime then
return
end

if player:GetAttribute("LastSkill") ~= skillServerTime then
if skillServerTime - serverTime > 1 then -- player probably wouldn't want to skill 1 second later
return
end
if not playerRecord.hasBall then
return
end
player:SetAttribute("LastSkill", skillServerTime)
self.CharacterService:Skill(player)
end
end

local networkPing = player:GetAttribute("NetworkPing") or 0
networkPing /= 1000
networkPing += 0.15
networkPing = math.min(networkPing, 0.5)
serverTime = math.max(serverTime, self.serverSimulationTime - networkPing)
local tackledEnemy = ballInfo.tackledEnemy
if tackledEnemy then
if not player:GetAttribute("CanStealClient") or not player:GetAttribute("CanSteal") then
return
end

local enemyId = ballSimulation.state.ownerId
local enemyRecord = self:GetPlayerByUserId(enemyId)
if enemyRecord == nil then
return
end
local enemyChickynoid = enemyRecord.chickynoid
if enemyChickynoid == nil then
return
end

local enemyHitBox = enemyChickynoid.hitBox
if enemyHitBox == nil then
return
end

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = {enemyHitBox}

local characterCF = CFrame.new(simulation.state.pos) * CFrame.Angles(0, simulation.state.angle, 0)

local tackleHitBox: BasePart = assets.Hitboxes.Tackle
if isGoalkeeper then
local diveHitboxTemplate = assets.Hitboxes.Dive:FindFirstChild(Lib.getHiddenAttribute(player, "ServerDiveHitbox"))
if diveHitboxTemplate == nil then
return
end
tackleHitBox = diveHitboxTemplate
end

-- local visualHitbox = tackleHitBox:Clone()
-- visualHitbox.Transparency = 0
-- visualHitbox.Anchored = true
-- visualHitbox.CFrame = characterCF * tackleHitBox.PivotOffset:Inverse()
-- visualHitbox.Size += Vector3.one
-- visualHitbox.Parent = workspace

-- characterHitbox.CFrame = characterCF
-- characterHitbox.Parent = workspace

Antilag:PushPlayerPositionsToTime(playerRecord, serverTime)
-- characterHitbox2.CFrame = enemyHitBox.CFrame
-- characterHitbox2.Parent = workspace
local enemyCharacter = workspace:GetPartBoundsInBox(characterCF * tackleHitBox.PivotOffset:Inverse(), tackleHitBox.Size + Vector3.one, overlapParams)[1]
Antilag:Pop()

local ballOwner = Players:GetPlayerByUserId(enemyRecord.userId)
if enemyCharacter == nil then
if isGoalkeeper then
return -- Don't do "missed tackles" for goalkeeper
end

Lib.setHiddenAttribute(player, "CanStealClient", false)

if ballOwner:GetAttribute("Position") == "Goalkeeper" then
return
end

local tackleTrove = Trove.new()
tackleTrove:AttachToInstance(player)
tackleTrove:Add(task.delay(Lib.getCooldown(player, "TackleEnd"), function()
tackleTrove:Destroy()
if player == nil or player.Parent == nil then
return
end
end))
tackleTrove:Connect(player:GetAttributeChangedSignal("CanSteal"), function()
tackleTrove:Destroy()
end)

return
end
local stealString = "CanSteal"
if not isGoalkeeper and enemyCharacter:GetAttribute("Skill") then
Lib.setHiddenAttribute(player, stealString, false)
-- missed tackle

return
end

self.CharacterService:StealBall(player)

return
end

local claimPos = ballInfo.claimPos
if claimPos then
local ownerId = ballSimulation.state.ownerId
local serverDeflect = not (
ownerId ~= player.UserId
or ballInfo.deflectInfo == nil
or not ballInfo.deflectInfo.serverDeflect
or ballSimulation.state.action ~= Enums.BallActions.ServerClaim
or tick() - ballController.claimTime > 0.7
)

if ownerId ~= 0 then
if not serverDeflect then -- For if the player wanted to deflect before the server made them automatically claim the ball, also give them only 0.7s after server claims so they can't deflect after a lot of time has passed
return
end
end

if typeof(claimPos) ~= "Vector3" or claimPos ~= claimPos then
return
end

-- to-do: make this only go back to a certain point depending on the player's ping
if not serverDeflect then
local currentPos, claimCooldown, previousPos, alreadyHadLagSaveLeniency = BallPositionHistory:GetPreviousPosition(serverTime, claimPos)
if alreadyHadLagSaveLeniency then
return
end
if currentPos == nil then
currentPos = ballSimulation.state.pos
claimCooldown = ballController:isOnCooldown("ClaimCooldown")
if ballController:getAttribute("LagSaveLeniency") then
return
end
end
if claimCooldown then
return
end
if ballSimulation.state.netId ~= player.UserId then
local characterCFrame = CFrame.new(simulation.state.pos) * CFrame.Angles(0, simulation.state.angle, 0)

local filter = {characterHitbox}
local diveHitBox: BasePart?
if player:GetAttribute("Position") == "Goalkeeper" and Lib.isOnHiddenCooldown(player, "DiveEnd") then
local diveHitboxTemplate = assets.Hitboxes.Dive:FindFirstChild(Lib.getHiddenAttribute(player, "ServerDiveHitbox"))
if diveHitboxTemplate then
diveHitBox = diveHitboxTemplate:Clone()
diveHitBox:PivotTo(characterCFrame)
diveHitBox.Parent = self.worldRoot
table.insert(filter, diveHitBox)
end
end

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = filter

characterHitbox.CFrame = characterCFrame

characterHitbox.Parent = self.worldRoot
local characters = workspace:GetPartBoundsInRadius(currentPos, 1, overlapParams)
if characters[1] == nil then
if previousPos then
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = filter
local function doRaycast(startPos, rayDirection: Vector3): (RaycastResult?, boolean)
local radius = 1
local raycastResult = workspace:Spherecast(startPos, radius, rayDirection, raycastParams)
local lineRaycast = false
if raycastResult == nil then
raycastResult = workspace:Raycast(startPos, rayDirection + rayDirection.Unit*radius, raycastParams)
lineRaycast = true
end
return raycastResult, lineRaycast
end

local raycastResult = doRaycast(previousPos, (currentPos - previousPos))
if diveHitBox then
diveHitBox:Destroy()
end
if raycastResult == nil then
return
end
else
if diveHitBox then
diveHitBox:Destroy()
end
return
end
end
else
-- note: extrapolate position or do something to figure out where the ball should be on the client
local distance = (currentPos - simulation.state.pos).Magnitude
-- print(distance)
if distance > 8 then
return
end
end
end

local deflectInfo = ballInfo.deflectInfo
if deflectInfo then
local shotType, shotPower, shotDirection, curveFactor = deflectInfo.shotType, deflectInfo.shotPower, deflectInfo.shotDirection, deflectInfo.curveFactor
if not t.tuple(t.string, t.number, t.Vector3, t.number)(shotType, shotPower, shotDirection, curveFactor) then
return
end
if not table.find({"DeflectShoot"}, shotType) then
return
end
shotPower = math.clamp(shotPower, 0, privateServerInfo:GetAttribute("MaxShotPower"))
if shotPower ~= shotPower then -- nan
return
end
shotDirection = shotDirection.Unit
if shotDirection ~= shotDirection or shotDirection.Magnitude == 0 then
return
end
if curveFactor ~= curveFactor or curveFactor > GameInfo.MAXIMUM_CURVE_FACTOR then
return
end
self.CharacterService:DeflectBall(player, shotType, shotPower, shotDirection, curveFactor, true)
pushBallForward()
else
self.CharacterService:ClaimBall(player)
pushBallForward()
end

return
end

local shotInfo = ballInfo.shotInfo
if shotInfo and shotInfo.guid == ballSimulation.state.guid then
if ballSimulation.state.ownerId ~= playerRecord.userId then
return
end

local shotType, shotPower, shotDirection, curveFactor = shotInfo.shotType, shotInfo.shotPower, shotInfo.shotDirection, shotInfo.curveFactor
if not t.tuple(t.string, t.number, t.Vector3, t.number)(shotType, shotPower, shotDirection, curveFactor) then
return
end
if not table.find({"Shoot"}, shotType) then
return
end
shotPower = math.clamp(shotPower, 0, privateServerInfo:GetAttribute("MaxShotPower"))
if shotPower ~= shotPower then -- nan
return
end
shotDirection = shotDirection.Unit
if shotDirection ~= shotDirection or shotDirection.Magnitude == 0 then
return
end
if curveFactor ~= curveFactor or curveFactor > GameInfo.MAXIMUM_CURVE_FACTOR then
return
end

self.CharacterService:ShootBall(player, shotType, shotPower, shotDirection, curveFactor)
pushBallForward()
end
end

return ServerModule
src/server/Chickynoid/Server/ServerSnapshotGen.lua
--!native
local module = {}

local UnreliableRemoteEvent = game.ReplicatedStorage:WaitForChild("ChickynoidUnreliableReplication") :: RemoteEvent

local path = game.ReplicatedFirst.Chickynoid
local Profiler = require(path.Shared.Vendor.Profiler)
local CharacterData = require(path.Shared.Simulation.CharacterData)

local DeltaTable = require(path.Shared.Vendor.DeltaTable)
local Enums = require(path.Shared.Enums)
local EventType = Enums.EventType
local absoluteMaxSizeOfBuffer = 4096
local smallBufferSize = 64
local timeToKeepCache = 30 --in frames
local doCRC = false

local cache = {}

local function GetCacheItem(otherUserId, serverFrame, comparisonFrame)

local cacheLine = cache[otherUserId]
if (cacheLine == nil) then
return nil
end

local rec = cacheLine[serverFrame]
if (rec == nil) then
return nil
end

if (comparisonFrame == nil) then
return rec.raw
end

--we have to find the cache for compariston
local subRec = rec.comparisons[comparisonFrame]
return subRec
end

local function StoreCacheItem(otherUserId, serverFrame, comparisonFrame, cacheRec)

local cacheLine = cache[otherUserId]
if (cacheLine == nil) then
cacheLine = {}
cache[otherUserId] = cacheLine
end

local rec = cacheLine[serverFrame]

if (rec == nil) then
local newRec = {}
newRec.raw = cacheRec
newRec.comparisons = {}
cacheLine[serverFrame] = newRec
else
if (comparisonFrame == nil) then
rec.raw = cacheRec
else
rec.comparisons[comparisonFrame] = cacheRec
end
end

--Cleanup old records
for timeStamp, record in cacheLine do
if (timeStamp < serverFrame - timeToKeepCache) then
cacheLine[timeStamp] = nil
end
end
end


local function CreateAndQueueSnapshotPacket(currentPacket, playerRecord, fullSnapshot, queue, serverTotalFrames, serverSimulationTime, comparisonFrame)
local snapshot = {}
snapshot.t = EventType.Snapshot
snapshot.full = fullSnapshot

local finalBuffer = buffer.create(currentPacket.offset)
buffer.copy(finalBuffer,0,currentPacket.writeBuffer,0,currentPacket.offset)

snapshot.b = finalBuffer
snapshot.f = serverTotalFrames
snapshot.cf = comparisonFrame
snapshot.serverTime = serverSimulationTime
snapshot.s = #queue + 1
table.insert(queue,snapshot)
end


function module:DoWork(playerRecords, serverTotalFrames, serverSimulationTime, debugBotBandwidth)

Profiler:BeginSample("BuildSnapshots")

--generate
local tempQueues = {}
local statistics = {}
statistics.generated = 0
statistics.cached = 0

for userId,playerRecord in playerRecords do

if (playerRecord.dummy == true and debugBotBandwidth == false) then
continue
end

--Start building the final data
local fullSnapshot = false
fullSnapshot = true

local currentPacket = nil
local series = 0
local queue = {}
tempQueues[userId] = queue

local comparisonFrame = playerRecord.lastConfirmedSnapshotServerFrame

--in case there are no other players visible
currentPacket = {}
currentPacket.writeBuffer = buffer.create(absoluteMaxSizeOfBuffer)
currentPacket.offset = 1 --skip a byte to write the recordCound
currentPacket.recordCount = 0

local visList = playerRecord.visibilityList
if (visList == nil) then
visList = playerRecords
end
local comparisonVisList = playerRecord.visHistoryList[comparisonFrame]
if (comparisonVisList == nil) then
comparisonVisList = {} --Assume we couldn't see anything
end


for _,otherPlayerRecord in visList do

local otherUserId = otherPlayerRecord.userId
if (otherUserId == userId) then
continue
end

if otherPlayerRecord.chickynoid == nil then
continue
end

local characterData = otherPlayerRecord.chickynoid.simulation.characterData

--Create a new packet?
if (currentPacket == nil) then
currentPacket = {}
currentPacket.writeBuffer = buffer.create(absoluteMaxSizeOfBuffer)
currentPacket.offset = 1 --skip a byte to write the recordCound
currentPacket.recordCount = 0
end
currentPacket.recordCount += 1

local cachedBufferRec = nil

--if we could see them last time, look up our delta to them
local couldSeeThemLastTime = true
if (comparisonVisList[otherUserId] == nil) then
couldSeeThemLastTime = false
end

if (couldSeeThemLastTime == true) then
cachedBufferRec = GetCacheItem(otherUserId, serverTotalFrames, comparisonFrame)
end

if (cachedBufferRec == nil) then
--Generate the cached item
local prevCharacterData = nil
if (comparisonFrame ~= nil and couldSeeThemLastTime == true) then
--Find the previous character data to compare to
prevCharacterData = otherPlayerRecord.chickynoid.prevCharacterData[comparisonFrame]
end
local cacheRec = {}
cacheRec.writeBuffer = buffer.create(smallBufferSize)
buffer.writeu8(cacheRec.writeBuffer, 0, otherPlayerRecord.slot)
cacheRec.offset = 1
cacheRec.offset = CharacterData.SerializeToBitBuffer(characterData, prevCharacterData, cacheRec.writeBuffer, cacheRec.offset)

if (prevCharacterData == nil) then
--if its not deltacompressed, store it raw (comparisonFrame = nil)
StoreCacheItem(otherUserId, serverTotalFrames, nil, cacheRec)
else
--store it and flag it as being a delta
StoreCacheItem(otherUserId, serverTotalFrames, comparisonFrame, cacheRec)
end
cachedBufferRec = cacheRec

statistics.generated+=1
else
--print("got cached ", comparisonFrame)
statistics.cached += 1
end

buffer.copy(currentPacket.writeBuffer, currentPacket.offset, cachedBufferRec.writeBuffer, 0, cachedBufferRec.offset)
currentPacket.offset+= cachedBufferRec.offset

if (currentPacket.offset > 700) then
--Send snapshot
buffer.writeu8(currentPacket.writeBuffer, 0, currentPacket.recordCount)
CreateAndQueueSnapshotPacket(currentPacket, playerRecord, fullSnapshot, queue, serverTotalFrames, serverSimulationTime, comparisonFrame)
currentPacket = nil
end
end

--Wasn't finished, so finish the last one
if (currentPacket ~= nil) then
buffer.writeu8(currentPacket.writeBuffer, 0, currentPacket.recordCount)
CreateAndQueueSnapshotPacket(currentPacket, playerRecord, fullSnapshot, queue, serverTotalFrames, serverSimulationTime, comparisonFrame)
end
end

for userId,playerRecord in playerRecords do

if playerRecord.dummy == false then
--Transmit!
local queue = tempQueues[userId]

for _,snapshot in queue do
snapshot.m = #queue

playerRecord:SendUnreliableEventToClient(snapshot)
end
end
end

--print(statistics.generated, " vs ", statistics.cached)
Profiler:EndSample()
end

return module
src/server/Chickynoid/Server/WeaponsServer.lua
--!native
local module = {}

module.rocketSerial = 0
module.rockets = {}
module.weaponSerials = 0
module.customWeapons = {}

local path = game.ReplicatedFirst.Chickynoid

local DeltaTable = require(path.Shared.Vendor.DeltaTable)
local Enums = require(path.Shared.Enums)
local Antilag = require(script.Parent.Antilag)
local ServerMods = require(script.Parent.ServerMods)

local requiredMethods = {
"ClientThink",
"ServerThink",
"ClientProcessCommand",
"ServerProcessCommand",
"ClientSetup",
"ServerSetup",
"ClientEquip",
"ServerEquip",
"ClientDequip",
"ServerDequip",
"ClientRemoved",
"ServerRemoved",
}

--Server Lifecycle:
-- ServerSetup
-- ServerEquip
-- ServerProcessCommand (x many?)
-- ServerThink
-- ServerDequip
-- ServerRemoved

--Client Lifecycle:
-- ClientSetup
-- ClientEquip
-- ClientProcessCommand (x many?)
-- ClientThink
-- ClientDequip
-- ClientRemoved

--Note, ProcesCommand, Think and Dequip all only get called if this is item is equipped

function module:Setup(server)

local weapons = ServerMods:GetMods("weapons")

for name, module in pairs(weapons) do

local customWeapon = module

local doError = false
for _, values in pairs(requiredMethods) do
if customWeapon[values] == nil then
warn("WeaponModule " .. name .. " missing " .. values .. " implementation.")
doError = true
end
end

if (doError) then
error("Aborting module")
end
table.insert(self.customWeapons, customWeapon)
--set the id
customWeapon.weaponId = #self.customWeapons
end
end

function module:OnPlayerConnected(server, playerRecord)
playerRecord.weapons = {}

playerRecord.currentWeapon = nil

-- selene: allow(shadowing)
function playerRecord:DequipWeapon()
if self.currentWeapon ~= nil then
self.currentWeapon:ServerDequip()

local event = {}
event.t = Enums.EventType.WeaponDataChanged
event.s = Enums.WeaponData.Dequip
self:SendEventToClient(event)

self.currentWeapon = nil
end
end

-- selene: allow(shadowing)
function playerRecord:EquipWeapon(serial)

self:DequipWeapon()

if serial ~= nil then
local weaponRecord = self.weapons[serial]
if weaponRecord == nil then
warn("Weapon not found:", serial)
return
end

self.currentWeapon = weaponRecord
weaponRecord:ServerEquip()

local event = {}
event.t = Enums.EventType.WeaponDataChanged
event.s = Enums.WeaponData.Equip
event.serial = serial
self:SendEventToClient(event)
end
end

-- selene: allow(shadowing)
function playerRecord:GetWeapons()
return self.weapons
end

-- selene: allow(shadowing)
function playerRecord:RemoveWeaponRecord(weaponRecord)

if (self.currentWeapon == weaponRecord) then
self:DequipWeapon()
end

weaponRecord:ServerRemoved()

local event = {}
event.t = Enums.EventType.WeaponDataChanged
event.s = Enums.WeaponData.WeaponRemove
event.serial = weaponRecord.serial
self:SendEventToClient(event)

self.weapons[weaponRecord.serial] = nil
end

-- selene: allow(shadowing)
function playerRecord:ClearWeapons()
for _, weaponRecord in pairs(self.weapons) do
self:RemoveWeaponRecord(weaponRecord)
end
end

-- selene: allow(shadowing)
function playerRecord:AddWeaponByName(name, equip, recordParam)
local sourceModule = ServerMods:GetMod("weapons", name)
if sourceModule == nil then
warn("Weapon ", name, " not found!")
return
end

local weaponRecord = sourceModule.new(recordParam)
weaponRecord.serial = module.weaponSerials
module.weaponSerials += 1

weaponRecord.playerRecord = playerRecord
weaponRecord.server = server
weaponRecord.weaponModule = module
weaponRecord.totalTime = 0
weaponRecord.state = {}
weaponRecord.previousState = {}

weaponRecord:ServerSetup()

--Add to inventory
playerRecord.weapons[weaponRecord.serial] = weaponRecord

local event = {}
event.t = Enums.EventType.WeaponDataChanged
event.serial = weaponRecord.serial
event.name = name
event.s = Enums.WeaponData.WeaponAdd
event.serverState = weaponRecord.state
playerRecord:SendEventToClient(event)

--Last state, as seen by this client
weaponRecord.previousState = DeltaTable:DeepCopy(weaponRecord.state)

--Equip it
if equip then
self:EquipWeapon(weaponRecord.serial)
end

return weaponRecord;
end

-- selene: allow(shadowing)
function playerRecord:ProcessWeaponCommand(command)
if self.currentWeapon ~= nil then
self.currentWeapon.totalTime += command.deltaTime
self.currentWeapon:ServerProcessCommand(command)
end
end

-- Happens after the command for this frame
-- selene: allow(shadowing)
function playerRecord:WeaponThink(deltaTime)
if self.currentWeapon ~= nil then
self.currentWeapon:ServerThink(deltaTime)

--Check if we need updates
local deltaTable, numChanges = DeltaTable:MakeDeltaTable(self.currentWeapon.previousState, self.currentWeapon.state)

if numChanges > 0 then
--Send the client the change to the state
local event = {}
event.t = Enums.EventType.WeaponDataChanged
event.s = Enums.WeaponData.WeaponState
event.serial = self.currentWeapon.serial
event.deltaTable = deltaTable
playerRecord:SendEventToClient(event)

--Record what they saw
self.currentWeapon.previousState = DeltaTable:DeepCopy(self.currentWeapon.state)
end
end
end
end

function module:QueryBullet(playerRecord, server, origin, dir, serverTime, debugText, raycastParams, range)
Antilag:PushPlayerPositionsToTime(playerRecord, serverTime, debugText)

if range == nil then
range = 1000
end

local rayCastResult = game.Workspace:Raycast(origin, dir * range, raycastParams)

local pos = nil
local normal = nil
local otherPlayerRecord = nil
local hitInstance = nil
if rayCastResult == nil then
pos = origin + dir * range
else
pos = rayCastResult.Position
normal = rayCastResult.Normal
hitInstance = rayCastResult.Instance

--See if its a player
local userId = rayCastResult.Instance:GetAttribute("player")
if userId then
otherPlayerRecord = server:GetPlayerByUserId(userId)
end
end

Antilag:Pop() --Don't forget!

return pos, normal, otherPlayerRecord, hitInstance
end

function module:QueryShotgun(playerRecord, server, origins, directions, serverTime, debugText, raycastParams, range)

Antilag:PushPlayerPositionsToTime(playerRecord, serverTime, debugText)

if range == nil then
range = 1000
end

local results = {}

for counter = 1, #origins do
local origin = origins[counter]
local dir = directions[counter]
if (dir == nil) then
continue
end

local rayCastResult = game.Workspace:Raycast(origin, dir * range, raycastParams)

if rayCastResult == nil then
local record = {}
record.pos = origin + dir * range
record.origin = origin
record.dir = dir
table.insert(results, record)
else
local record = {}
record.pos = rayCastResult.Position
record.normal = rayCastResult.Normal
record.hitInstance = rayCastResult.Instance
record.origin = origin
record.dir = dir

--See if its a player
local userId = rayCastResult.Instance:GetAttribute("player")
if userId then
record.otherPlayerRecord = server:GetPlayerByUserId(userId)
end
table.insert(results, record)
end
end

Antilag:Pop() --Don't forget!

return results
end


function module:Think(server, deltaTime)
for _, playerRecord in pairs(server:GetPlayers()) do
playerRecord:WeaponThink(deltaTime)
end

for serial, rocket in pairs(self.rockets) do
local timePassed = server.serverSimulationTime - rocket.o

local oldPos = rocket.pos

if oldPos == nil then
oldPos = rocket.p
end
rocket.pos = rocket.p + (rocket.v * rocket.c * timePassed)

--Trace a line
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { game.Workspace.Terrain, server:GetCollisionRoot() }
local results = game.Workspace:Raycast(oldPos, rocket.pos - oldPos, params)
if results ~= nil then
timePassed = 1000 --Boom
rocket.n = results.Normal
else
local result = self:RayTestPlayers(oldPos, rocket.pos - oldPos, server)
if result ~= nil then
timePassed = 1000
rocket.n = Vector3.new(0, 1, 0)
end
end

if timePassed > 5 then
local event = {}
event.t = Enums.EventType.RocketDie
event.s = rocket.s
event.n = rocket.n
server:SendEventToClients(event)

self.rockets[serial] = nil
self:DoExplosion(server, rocket.pos, 15, 60)
end
end
end

function module:DoExplosion(server, explosionPos, _radius, force)
--Get All the players
for _, playerRecord in pairs(server.playerRecords) do
local sim = playerRecord.chickynoid.simulation
local pos = sim.state.pos

local vec = pos - explosionPos
if vec.magnitude < 10 then
--Always upwards
local dir = vec.unit
dir = Vector3.new(dir.x, math.abs(dir.y), dir.z)
sim.state.vel += dir.unit * force
end
end
end

function module:RayTestPlayers(rayOrigin, vec, server)
--[[
--Get All the players
for key,playerRecord in pairs(server.playerRecords) do

local sim = playerRecord.chickynoid.simulation
local pos = sim.state.pos

local vec = pos - explosionPos
if (vec.magnitude < 10) then

--Always upwards
local dir = vec.unit
dir = Vector3.new(dir.x, 1, dir.z)
sim.state.vel += dir.unit * force
end
end
]]
--
if server.worldRoot == nil then
return nil
end

local rayCastResult = game.Workspace:Raycast(rayOrigin, vec)
return rayCastResult
end

return module
src/server/Chickynoid/Server/init.meta.json
{
"ignoreUnknownInstances": true
}
src/server/Chickynoid/init.meta.json
{
"ignoreUnknownInstances": true
}
src/server/Services/CharacterService.lua
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AnimationRemoteEvent = Instance.new("RemoteEvent")
AnimationRemoteEvent.Name = "AnimationReplication"
AnimationRemoteEvent.Parent = ReplicatedStorage

local Enums = require(ReplicatedFirst.Chickynoid.Shared.Enums)

local EffectService
local EmoteService

local Lib = require(ReplicatedStorage.Lib)

local GameInfo = require(ReplicatedStorage.Data.GameInfo)

local Constraints = require(ReplicatedStorage.Modules.Constraints)
local Trove = require(ReplicatedStorage.Modules.Trove)

local privateServerInfo: Configuration = ReplicatedStorage.PrivateServerInfo

local assets = ReplicatedStorage.Assets
local animations = assets.Animations


local CharacterService = {
Name = "CharacterService",
Client = {},
BallOwnerChanged = Instance.new("BindableEvent").Event,
NetworkOwnerChanged = Instance.new("BindableEvent").Event,
}

function CharacterService:KnitInit()
local Packages = ServerScriptService.ServerScripts.Chickynoid.Server
self.ServerModule = require(Packages.ServerModule)
self.ServerModule.CharacterService = self
self.ServerMods = require(Packages.ServerMods)

self.ServerModule:RecreateCollisions(workspace.MapItems.ChickynoidCollisions)

self.ServerMods:RegisterMods("servermods", ServerScriptService.ServerScripts.Chickynoid.Examples.ServerMods)
self.ServerMods:RegisterMods("characters", ReplicatedFirst.Chickynoid.Examples.Characters)
self.ServerMods:RegisterMods("balls", ReplicatedFirst.Chickynoid.Examples.Balls)

self.ServerModule:Setup()
self.ServerModule:AddBall()

-- local Bots = require(ServerScriptService.ServerScripts.Chickynoid.Server.Bots)
-- Bots:MakeBots(self.ServerModule, 11)
end

function CharacterService:KnitStart()
local services = script.Parent
EffectService = require(services.EffectService)
EmoteService = require(services.EmoteService)

for _, player in pairs(Players:GetPlayers()) do
task.spawn(function()
self:PlayerAdded(player)
end)
end
Players.PlayerAdded:Connect(function(player)
self:PlayerAdded(player)
end)
Players.PlayerRemoving:Connect(function(player)
self:ResetBall(player)
end)

local function resetBall(character)
local player = Players:GetPlayerFromCharacter(character)
if player == nil then
return
end
self:ResetBall(player)
EmoteService:EndEmote(player)
end
CollectionService:GetInstanceAddedSignal("Ragdoll"):Connect(resetBall)
end

function CharacterService:PlayerAdded(player: Player)
player:GetAttributeChangedSignal("ServerChickyRagdoll"):Connect(function()
self:ResetBall(player)
end)
player:GetAttributeChangedSignal("ServerChickyFrozen"):Connect(function()
self:ResetBall(player)
end)

player:GetPropertyChangedSignal("Team"):Connect(function()
self:ResetBall(player)
end)
end

function CharacterService:ResetBall(player: Player)
if player:IsA("Player") then
local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end
if not playerRecord.hasBall then
return
end
playerRecord.hasBall = false
local ballRecord = self.ServerModule.ballRecord
local ballController = ballRecord.ballController
local ballSimulation = ballController.simulation
if ballSimulation.state.ownerId == player.UserId then
ballSimulation.state.guid += 1
ballSimulation.state.action = Enums.BallActions.Reset
ballController:setBallOwner(self.ServerModule, 0)
ballController:setNetworkOwner(self.ServerModule, 0)
end
else
if not player:GetAttribute("HasBall") then
return
end
local ballRecord = self.ServerModule.ballRecord
local ballController = ballRecord.ballController
local ballSimulation = ballController.simulation
ballSimulation.state.guid += 1
ballSimulation.state.action = Enums.BallActions.Reset
ballController:setBallOwner(self.ServerModule, 0)
ballController:setNetworkOwner(self.ServerModule, 0)
end
end

-- Basics
local function checkSave(player: Player, ballController)
if not Lib.playerInGame(player) or Lib.playerIsStunned(player) then
return
end
if player:GetAttribute("Position") ~= "Goalkeeper" then
return
end

if ballController:getAttribute("Team") == player.Team.Name then
return
end

task.spawn(function()
-- saved ball
end)
end

function CharacterService:ClaimBall(player: Player, serverClaim: boolean?)
if player:IsA("Player") then
if not Lib.playerInGame(player) or Lib.playerIsStunned(player) then
return
end
end

local ballRecord = self.ServerModule.ballRecord
local ballController = ballRecord.ballController
if ballController == nil then
return
end

local ballSimulation = ballController.simulation
if ballSimulation.state.ownerId ~= 0 then
return
end

if ballController:getAttribute("GoalScored") then
return
end
if ballController:getAttribute("LagSaveLeniency") and player:GetAttribute("Position") ~= "Goalkeeper" then
return
end


if player:IsA("Player") then
local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end
if playerRecord.hasBall then
return
end

local chickynoid = playerRecord.chickynoid
if chickynoid == nil then
return
end
local simulation = chickynoid.simulation

local netId = ballSimulation.state.netId
local networkOwner: Player = if type(netId) == "number" then Players:GetPlayerByUserId(netId) else netId
if ballController:isOnCooldown("ClaimCooldown", -0.1) and player:GetAttribute("Position") ~= "Goalkeeper" -- add lag comp of -0.1 because this can only be called on the server
and networkOwner and networkOwner ~= player then
return
end

-- If the goalkeeper threw the ball, it should ignore players on the other team for a bit
if ballController:isOnCooldown("ClaimCooldown") and networkOwner and networkOwner:GetAttribute("Position") == "Goalkeeper" and networkOwner.Team ~= player.Team then
return
end
if Lib.isOnHiddenCooldown(player, "BallClaimCooldown") then
return
end

if ballController:isOnCooldown("SpawnClaimCooldown") then
return
end

checkSave(player, ballController)

Lib.setHiddenCooldown(player, "CanJumpWithBall", 1)

Lib.setHiddenCooldown(player, "BallClaimCooldown", 0.3)

ballController.claimTime = tick()
ballSimulation.state.guid += 1
if serverClaim then
ballSimulation.state.action = Enums.BallActions.ServerClaim
else
ballSimulation.state.action = Enums.BallActions.Claim
end
ballController:setBallOwner(self.ServerModule, player.UserId)


if player:GetAttribute("Position") == "Goalkeeper" then
local typeOfCatch = ballSimulation.state.pos.Y - simulation.state.pos.Y > 1 and "High" or "Low"
simulation.characterData:PlayAnimation(typeOfCatch .. "Catch", Enums.AnimChannel.Channel1, true)
end
else
if player:GetAttribute("HasBall") then
return
end

local character = player
local humanoidRootPart: BasePart = character and character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart == nil then
return
end

local humanoid = character:FindFirstChild("Humanoid")
if humanoid == nil or humanoid.Health == 0 then
return
end

if Lib.isOnHiddenCooldown(player, "BallClaimCooldown") then
return
end

Lib.setHiddenCooldown(player, "BallClaimCooldown", 0.3)

ballController.claimTime = tick()
ballSimulation.state.guid += 1
if serverClaim then
ballSimulation.state.action = Enums.BallActions.ServerClaim
else
ballSimulation.state.action = Enums.BallActions.Claim
end
ballController:setBallOwner(self.ServerModule, player)

local typeOfCatch = ballSimulation.state.pos.Y - humanoidRootPart.CFrame.Position.Y > 1 and "High" or "Low"
local animator: Animator = humanoid:FindFirstChild("Animator")
if animator == nil then
return
end
local catchAnimation = animator:LoadAnimation(animations[typeOfCatch .. "Catch"])
catchAnimation:Play(0)
end
end

function CharacterService:StealBall(player: Player)
if player:IsA("Player") then
if not Lib.playerInGame(player) or Lib.playerIsStunned(player) then
return
end
end

local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end
if playerRecord.hasBall then
return
end

local chickynoid = playerRecord.chickynoid
if chickynoid == nil then
return
end


local stealString = "CanSteal"
if not Lib.getHiddenAttribute(player, stealString) then
return
end

local ballRecord = self.ServerModule.ballRecord
local ballController = ballRecord.ballController
if ballController == nil then
return
end
if ballController:getAttribute("GoalScored") then
return
end

local ballSimulation = ballController.simulation

if ballController:getAttribute("LagSaveLeniency") and player:GetAttribute("Position") ~= "Goalkeeper" then
return
end

local ownerId = ballSimulation.state.ownerId
local ballOwner = Players:GetPlayerByUserId(ownerId)
local ballOwnerTeam
if ballOwner then
ballOwnerTeam = ballOwner:IsA("Player") and ballOwner.Team or ballOwner.Team.Value
end
local playerTeam = player:IsA("Player") and player.Team or player.Team.Value
if ballOwner == nil or ballOwnerTeam == playerTeam or ballOwner:GetAttribute("Position") == "Goalkeeper" then
return
end

local enemyPlayerRecord = self.ServerModule:GetPlayerByUserId(ownerId)
local enemyChickynoid = enemyPlayerRecord.chickynoid
if enemyChickynoid == nil then
return
end


if not Lib.isOnHiddenCooldown(player, "TackleEnd")
and not Lib.isOnHiddenCooldown(player, "DiveEnd") then
return
end

if Lib.isOnHiddenCooldown(player, "BallClaimCooldown") then
return
end

local tackleTime = ballController:getAttribute("TackleTime")
if player:GetAttribute("Position") ~= "Goalkeeper" and tackleTime and tackleTime > Lib.getHiddenAttribute(player, "TackleStart") then
return
end


if player:GetAttribute("Position") ~= "Goalkeeper" and Lib.isOnHiddenCooldown(ballOwner, "TackleInvulnerability") then
Lib.setHiddenAttribute(player, stealString, false)
return
end
if player:GetAttribute("Position") ~= "Goalkeeper" and Lib.isOnHiddenCooldown(ballOwner, "SkillEnd") then
Lib.setHiddenAttribute(player, stealString, false)

-- missed tackle, player successfully used skill
return
end

ballController:setAttribute("TackleTime", workspace:GetServerTimeNow())
Lib.setHiddenAttribute(player, "CanSteal", false)
Lib.setHiddenAttribute(player, "CanStealClient", false)

Lib.setHiddenCooldown(player, "BallClaimCooldown", 0.3)

ballSimulation.state.guid += 1
ballSimulation.state.action = Enums.BallActions.Claim
ballController:setBallOwner(self.ServerModule, player.UserId)


local knockback = enemyChickynoid.simulation.state.vel
if knockback then
knockback = knockback.Unit
end
if knockback ~= knockback or knockback.Magnitude == 0 then
knockback = Vector3.new(0, 3, 0)
end
self.ServerModule:KnockbackPlayer(ballOwner, knockback, GameInfo.TACKLE_RAGDOLL_TIME, nil, true)

if player:GetAttribute("Position") == "Goalkeeper" then
-- steal
else
-- tackled
end
end

function CharacterService:AIGoalkeeperStealBall(player: Player)
local ballRecord = self.ServerModule.ballRecord
local ballController = ballRecord.ballController
if ballController == nil then
return
end
if ballController:getAttribute("GoalScored") then
return
end

if ballController:getAttribute("LagSaveLeniency") and player:GetAttribute("Position") ~= "Goalkeeper" then
return
end

local ballSimulation = ballController.simulation

local ownerId = ballSimulation.state.ownerId
local ballOwner = Players:GetPlayerByUserId(ownerId)
local ballOwnerTeam
if ballOwner then
ballOwnerTeam = ballOwner:IsA("Player") and ballOwner.Team or ballOwner.Team.Value
end
local playerTeam = player:IsA("Player") and player.Team or player.Team.Value
if ballOwner == nil or ballOwnerTeam == playerTeam or ballOwner:GetAttribute("Position") == "Goalkeeper" then
return
end

local enemyPlayerRecord = self.ServerModule:GetPlayerByUserId(ownerId)
local enemyChickynoid = enemyPlayerRecord.chickynoid
if enemyChickynoid == nil then
return
end


ballController:setAttribute("TackleTime", workspace:GetServerTimeNow())

Lib.setHiddenCooldown(player, "BallClaimCooldown", 0.3)

ballSimulation.state.guid += 1
ballSimulation.state.action = Enums.BallActions.Claim
ballController:setBallOwner(self.ServerModule, player)

local knockback = enemyChickynoid.simulation.state.vel
if knockback then
knockback = knockback.Unit
end
if knockback ~= knockback or knockback.Magnitude == 0 then
knockback = Vector3.new(0, 3, 0)
end
self.ServerModule:KnockbackPlayer(ballOwner, knockback, GameInfo.TACKLE_RAGDOLL_TIME, nil, true)
end

function CharacterService:ShootBall(player: Player, shotType: string, shotPower: number, shotDirection: Vector3, curveFactor: number)
if player:IsA("Player") then
if not Lib.playerInGame(player) or Lib.playerIsStunned(player) then
return
end
end

local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil or playerRecord.chickynoid == nil then
return
end
local simulation = playerRecord.chickynoid.simulation

local ballRecord = self.ServerModule.ballRecord
local ballController = ballRecord.ballController
if ballController == nil then
return
end
if ballController:getAttribute("GoalScored") then
return
end

ballController:setAttribute("HitTime", workspace:GetServerTimeNow())

local ballSimulation = ballController.simulation

local boundary = workspace.MapItems.BallBoundary
local playerCF = CFrame.new(simulation.state.pos) * CFrame.Angles(0, simulation.state.angle, 0)
local ballPos = (playerCF * CFrame.new(0, -1.65, -2)).Position
if player:GetAttribute("Position") == "Goalkeeper" then
ballPos = (playerCF * CFrame.new(0, 1, -2)).Position
end
ballSimulation.state.pos = Lib.clampToBoundary(ballPos, boundary)

local vel, angVel = Lib.getShotVelocity(ballSimulation.constants.gravity, shotType, shotPower, shotDirection, curveFactor)
ballSimulation.state.vel = vel
ballSimulation.state.angVel = angVel

ballSimulation.state.guid += 1
ballSimulation.state.action = Enums.BallActions.Shoot
ballController:setBallOwner(self.ServerModule, 0)
ballController:setNetworkOwner(self.ServerModule, player.UserId)

EffectService:CreateEffect("ballKicked", {player}, player)


ballController:setAttribute("ShootPosition", ballSimulation.state.pos)
ballController:setCooldown("ClaimCooldown", 0.1)
if player:IsA("Player") then
Lib.setHiddenCooldown(player, "BallClaimCooldown", 0.1)
end

if player:GetAttribute("Position") == "Goalkeeper" then
ballController:setCooldown("ClaimCooldown", 0.5)
Lib.setHiddenCooldown(player, "BallClaimCooldown", 10)

local claimCooldownTrove = Trove.new()
claimCooldownTrove:AttachToInstance(player)
claimCooldownTrove:Add(task.delay(10, function()
claimCooldownTrove:Destroy()
end))
claimCooldownTrove:Connect(self.NetworkOwnerChanged, function()
Lib.removeHiddenCooldown(player, "BallClaimCooldown")
claimCooldownTrove:Destroy()
end)
end
end

function CharacterService:AIGoalkeeperShootBall(character: Model, shotType: string, shotPower: number, shotDirection: Vector3, curveFactor: number)
local ballRecord = self.ServerModule.ballRecord
local ballController = ballRecord.ballController
if ballController == nil then
return
end
if ballController:getAttribute("GoalScored") then
return
end

ballController:setAttribute("HitTime", workspace:GetServerTimeNow())

local ballSimulation = ballController.simulation

local boundary = workspace.MapItems.BallBoundary
local playerCF = character.HumanoidRootPart.CFrame
local ballPos = (playerCF * CFrame.new(0, 1, -2)).Position
ballSimulation.state.pos = Lib.clampToBoundary(ballPos, boundary)

local vel, angVel = Lib.getShotVelocity(ballSimulation.constants.gravity, shotType, shotPower, shotDirection, curveFactor)
ballSimulation.state.vel = vel
ballSimulation.state.angVel = angVel

ballSimulation.state.guid += 1
ballSimulation.state.action = Enums.BallActions.Shoot
ballController:setBallOwner(self.ServerModule, 0)
ballController:setNetworkOwner(self.ServerModule, character)

EffectService:CreateEffect("ballKicked", {})


ballController:setAttribute("ShootPosition", ballSimulation.state.pos)

ballController:setCooldown("ClaimCooldown", 0.1)

ballController:setCooldown("ClaimCooldown", 0.5)
Lib.setCooldown(character, "BallClaimCooldown", 10)

local claimCooldownTrove = Trove.new()
claimCooldownTrove:AttachToInstance(character)
claimCooldownTrove:Add(task.delay(10, function()
claimCooldownTrove:Destroy()
end))
claimCooldownTrove:Connect(self.NetworkOwnerChanged, function()
Lib.removeCooldown(character, "BallClaimCooldown")
claimCooldownTrove:Destroy()
end)
end

function CharacterService:DeflectBall(player: Player, shotType: string, shotPower: number, shotDirection: Vector3, deflectCurveFactor: number, serverDeflect: boolean?)
if player:IsA("Player") then
if not Lib.playerInGame(player) or Lib.playerIsStunned(player) then
return
end
end

if player:GetAttribute("Position") == "Goalkeeper" then
return
end

local ballRecord = self.ServerModule.ballRecord
local ballController = ballRecord.ballController
if ballController == nil then
return
end

local ballSimulation = ballController.simulation
if ballController:getAttribute("GoalScored") then
return
end

local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end

local chickynoid = playerRecord.chickynoid
if chickynoid == nil then
return
end
local simulation = chickynoid.simulation

if not serverDeflect then
local netId = ballSimulation.state.netId
local networkOwner: Player | Model = if type(netId) == "number" then Players:GetPlayerByUserId(netId) else netId
if ballController:isOnCooldown("ClaimCooldown") and player:GetAttribute("Position") ~= "Goalkeeper"
and networkOwner and networkOwner ~= player then
return
end
if ballController:isOnCooldown("ClaimCooldown") and networkOwner and networkOwner:GetAttribute("Position") == "Goalkeeper" and networkOwner.Team ~= player.Team then
return
end
if Lib.isOnHiddenCooldown(player, "BallClaimCooldown") then
return
end

if ballController:isOnCooldown("SpawnClaimCooldown") then
return
end
end

ballController:setAttribute("HitTime", workspace:GetServerTimeNow())

local boundary = workspace.MapItems.BallBoundary
local playerCF = CFrame.new(simulation.state.pos) * CFrame.Angles(0, simulation.state.angle, 0)
local ballPos = (playerCF * CFrame.new(0, -1.65, -2)).Position
ballSimulation.state.pos = Lib.clampToBoundary(ballPos, boundary)

if shotType == "Shoot" then
shotType = "DeflectShoot"
end
local vel, angVel = Lib.getShotVelocity(ballSimulation.constants.gravity, shotType, shotPower, shotDirection, deflectCurveFactor)
ballSimulation.state.vel = vel
ballSimulation.state.angVel = angVel

local playerIsNetworkOwner = ballSimulation.state.netId == player.UserId

ballSimulation.state.guid += 1
ballSimulation.state.action = Enums.BallActions.Deflect
ballController:setBallOwner(self.ServerModule, 0)
ballController:setNetworkOwner(self.ServerModule, player.UserId)

ballSimulation.state.netId = player.UserId
playerRecord.hasBall = false

EmoteService:EndEmote(player)


ballController:setAttribute("ShootPosition", ballSimulation.state.pos)
ballController:setCooldown("ClaimCooldown", 0.1)
Lib.setHiddenCooldown(player, "BallClaimCooldown", 0.1)
end

-- Mechanics
function CharacterService:CreatePlayerHitbox(player: Player, humanoidRootPart: BasePart?, hitboxTemplate: BasePart, hitboxDuration: number, tackleCallback: () -> ())
if humanoidRootPart == nil then
warn("[Lib] createHitbox: HumanoidRootPart doesn't exist!")
return
end


local hitbox: BasePart = hitboxTemplate:Clone()
if not player:IsA("Player") then
local function lerp(a, b, t)
return a + (b - a) * t
end
local savedShots = player:GetAttribute("SavedShots")
if savedShots <= 1 then
hitbox.Size *= 4
else
hitbox.Size *= lerp(2.5, 0.8, math.clamp((savedShots-1)*1/3, 0, 1))
end
if savedShots >= 3 or not player:GetAttribute("ShouldDoActions") then -- don't do dive hitboxes if this is true
return
end
end
hitbox:PivotTo(humanoidRootPart.CFrame)
Constraints.weldConstraint(hitbox, humanoidRootPart)

if RunService:IsServer() then
hitbox.Color = Color3.fromRGB(0, 0, 255)
hitbox:AddTag("ServerHitbox")
else
hitbox.Color = Color3.fromRGB(255, 0, 0)
end

if not player:IsA("Player") then
hitbox.CollisionGroup = "Goalkeeper"
hitbox.Parent = player
else
hitbox.Transparency = 0
hitbox.Parent = self.ServerModule.worldRoot
end
game.Debris:AddItem(hitbox, hitboxDuration)


if tackleCallback == nil then
return
end

local function checkTackle(part: BasePart)
if player:IsA("Player") then
local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil or playerRecord.hasBall then
hitbox:Destroy()
return
end
end

local ownerId = self.ServerModule.ballRecord.ballController.simulation.state.ownerId
if part:HasTag("ServerBallHitbox") then
if player:IsA("Player") then
if ownerId == player.UserId then
return
end
elseif ownerId == player then
return
end
hitbox:Destroy()
if ownerId ~= 0 then
tackleCallback()
else
self:ClaimBall(player, true)
end
return
end

local tackleUserId = part:GetAttribute("player")
if tackleUserId == nil then
return
end
if ownerId ~= tackleUserId then
return
end

tackleCallback()
end

local hitboxTrove = Trove.new()
hitboxTrove:AttachToInstance(hitbox)

local filter = {CollectionService:GetTagged("ServerBallHitbox")}

local userId = humanoidRootPart:GetAttribute("player") -- Chickynoid compatibility
for _, otherPlayerHitbox in pairs(CollectionService:GetTagged("ServerCharacterHitbox")) do
local otherPlayerUserId = otherPlayerHitbox:GetAttribute("player")
if otherPlayerUserId == userId then continue end
local otherPlayer = Players:GetPlayerByUserId(otherPlayerUserId)
if not Lib.playerInGame(otherPlayer) then continue end

table.insert(filter, otherPlayerHitbox)
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = filter

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = filter

local simulationEvent = RunService:IsServer() and RunService.Heartbeat or RunService.RenderStepped
local lastCFrame = hitbox.CFrame
hitboxTrove:Connect(simulationEvent, function()
local currentCFrame = hitbox.CFrame
for _, part in pairs(workspace:GetPartBoundsInBox(currentCFrame, hitbox.Size, overlapParams)) do
checkTackle(part)
end

if lastCFrame.Position == currentCFrame.Position then
return
end
local raycastResult = workspace:Blockcast(lastCFrame, hitbox.Size, lastCFrame.Position - currentCFrame.Position, raycastParams)
lastCFrame = currentCFrame
if raycastResult == nil then
return
end
checkTackle(raycastResult.Instance)
end)
end

function CharacterService:DiveStart(player: Player, diveAnimName: string)
if player:GetAttribute("Position") ~= "Goalkeeper" then
return
end
if type(diveAnimName) ~= "string" then
return
end
local hitboxTemplate = assets.Hitboxes.Dive:FindFirstChild(diveAnimName)
if hitboxTemplate == nil then
return
end

if player:IsA("Player") then
if not Lib.playerInGameOrPaused(player) or Lib.playerIsStunned(player) then
return
end

local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end

local chickynoid = playerRecord.chickynoid
if chickynoid == nil or chickynoid.hitBox == nil then
return
end

Lib.setHiddenCooldown(player, "DiveEnd", GameInfo.DIVE_DURATION)
Lib.setHiddenAttribute(player, "CanSteal", true)

Lib.setHiddenAttribute(player, "ServerDiveHitbox", diveAnimName)
self:CreatePlayerHitbox(player, chickynoid.hitBox, hitboxTemplate, GameInfo.DIVE_DURATION, function()
self:StealBall(player)
end)
else
if Lib.isOnHiddenCooldown(player, "DiveCooldown") then
return
end

local goalkeeper: Model = player
if goalkeeper:GetAttribute("HasBall") then
return
end

local humanoidRootPart = goalkeeper:FindFirstChild("HumanoidRootPart")
if humanoidRootPart == nil then
return
end

Lib.setHiddenCooldown(player, "DiveEnd", GameInfo.DIVE_DURATION+0.3)
Lib.setHiddenCooldown(player, "DiveCooldown", GameInfo.DIVE_COOLDOWN-0.3)
Lib.setHiddenAttribute(player, "CanSteal", true)


self:CreatePlayerHitbox(goalkeeper, goalkeeper.HumanoidRootPart, hitboxTemplate, GameInfo.DIVE_DURATION, function()
self:AIGoalkeeperStealBall(goalkeeper)
end)
end
end

function CharacterService:TackleStart(player: Player)
if player:GetAttribute("Position") == "Goalkeeper" then
return
end
if not Lib.playerInGameOrPaused(player) or Lib.playerIsStunned(player) then
return
end


local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end

local chickynoid = playerRecord.chickynoid
if chickynoid == nil or chickynoid.hitBox == nil then
return
end

Lib.setHiddenCooldown(player, "TackleEnd", GameInfo.TACKLE_DURATION+0.3)
Lib.setHiddenAttribute(player, "CanSteal", true)
Lib.setHiddenAttribute(player, "CanStealClient", true)
Lib.setHiddenAttribute(player, "TackleStart", workspace:GetServerTimeNow())

self:CreatePlayerHitbox(player, chickynoid.hitBox, assets.Hitboxes.Tackle, GameInfo.TACKLE_DURATION, function()
self:StealBall(player)
end)
end

function CharacterService:Skill(player: Player)
if player:GetAttribute("Position") == "Goalkeeper" then
return
end
if not Lib.playerInGame(player) or Lib.playerIsStunned(player) then
return
end


local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end
if not playerRecord.hasBall then
return
end

if Lib.isOnHiddenCooldown(player, "SkillCooldown") then
return
end

local chickynoid = playerRecord.chickynoid
if chickynoid == nil then
return
end
local simulation = chickynoid.simulation

Lib.setHiddenCooldown(player, "SkillEnd", GameInfo.SKILL_DURATION)
Lib.setHiddenCooldown(player, "SkillCooldown", privateServerInfo:GetAttribute("SkillCD") - 0.3)

simulation.characterData:PlayAnimation("Skill", Enums.AnimChannel.Channel1, true)
end

-- Animations
function CharacterService:RequestBall(player: Player)
if not Lib.playerInGameOrPaused(player) then
return
end

local playerRecord = self.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end
if playerRecord.hasBall then
return
end

local chickynoid = playerRecord.chickynoid
if chickynoid == nil then
return
end
local simulation = chickynoid.simulation

if Lib.isOnHiddenCooldown(player, "RequestBallCooldown") then
return
end
Lib.setHiddenCooldown(player, "RequestBallCooldown", 1.5)

simulation.characterData:PlayAnimation("RequestBall", Enums.AnimChannel.Channel1, true)
end


-- Client Events

-- Animations
function CharacterService.Client:RequestBall(...)
self.Server:RequestBall(...)
end

return CharacterService
src/server/Services/EffectService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)


local EffectService = {
Name = "EffectService",
Client = {
OnEffectCreated = Knit.CreateUnreliableSignal(),
OnReliableEffectCreated = Knit.CreateSignal(),
},
}

type EffectService = typeof(EffectService)

function EffectService:CreateEffect(eventName: string, effectInfo: {any}, playerToIgnore: Player?)
if playerToIgnore then
self.Client.OnEffectCreated:FireExcept(playerToIgnore, eventName, effectInfo)
else
self.Client.OnEffectCreated:FireAll(eventName, effectInfo)
end
end

function EffectService:CreateClientEffect(player: Player, eventName: string, effectInfo: {any})
self.Client.OnEffectCreated:Fire(player, eventName, effectInfo)
end

function EffectService:CreateReliableEffect(eventName: string, effectInfo: {any})
self.Client.OnReliableEffectCreated:FireAll(eventName, effectInfo)
end

function EffectService:CreateReliableClientEffect(player: Player, eventName: string, effectInfo: {any})
self.Client.OnReliableEffectCreated:Fire(player, eventName, effectInfo)
end

return EffectService
src/server/Services/EmoteService.lua
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterService

local Lib = require(ReplicatedStorage.Lib)
local Trove = require(ReplicatedStorage.Modules.Trove)
local Items = require(ReplicatedStorage.Data.Items)


local EmoteService = {
Name = "EmoteService",
Client = {},
}

function EmoteService:KnitStart()
local services = script.Parent
CharacterService = require(services.CharacterService)
end

function EmoteService:UseEmote(player: Player, emoteSlot: number)
-- if not player:GetAttribute("Loaded") then
-- return
-- end

local playerRecord = CharacterService.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil or playerRecord.hasBall then
return
end

local selectedEmote = "Dance"
if selectedEmote ~= nil and Lib.isOnHiddenCooldown(player, "EmoteCooldown") then
return
end


Lib.setHiddenCooldown(player, "EmoteCooldown", 1)


local emoteInfo = Items.Emote[selectedEmote]
if emoteInfo == nil then
return
end


Lib.setCooldown(player, "EmoteCooldown", 1)

local function setNewEmote(newEmote)
local emoteInfo = Items.Emote[newEmote]
player:SetAttribute("EmoteData", HttpService:JSONEncode({
newEmote,
Lib.generateShortGUID(),
emoteInfo and emoteInfo.ShiftLockDisabled,
emoteInfo and emoteInfo.CanWalk
}))
end
setNewEmote(selectedEmote)


if selectedEmote == nil then
return
end

local trove = Trove.new()
trove:AttachToInstance(player)
trove:Connect(player:GetAttributeChangedSignal("EmoteData"), function()
trove:Destroy()
end)
trove:Connect(CharacterService.BallOwnerChanged, function(ownerId)
if ownerId ~= player.UserId then
return
end
setNewEmote(nil)
trove:Destroy()
end)

player:SetAttribute("EmoteWalkReset", nil)
if not emoteInfo.CanWalk then
player:SetAttribute("EmoteWalkReset", os.clock() + 1)
end
end

function EmoteService:EndEmote(player: Player, emoteGUID: string)
local emoteData = player:GetAttribute("EmoteData")
if emoteData == nil then
return
end

emoteData = HttpService:JSONDecode(emoteData)
local emote = emoteData[1]
if emote == nil then
return
end
if emoteGUID and emoteGUID ~= emoteData[2] then
return
end

local function setNewEmote(newEmote)
local emoteInfo = Items.Emote[newEmote]
player:SetAttribute("EmoteData", HttpService:JSONEncode({newEmote, Lib.generateShortGUID(), emoteInfo and emoteInfo.ShiftLockDisabled}))
end
setNewEmote(nil)
end

-- Client Events
function EmoteService.Client:EndEmote(...)
self.Server:EndEmote(...)
end

function EmoteService.Client:UseEmote(...)
self.Server:UseEmote(...)
end

return EmoteService
src/server/Services/GameService.lua
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local Lib = require(ReplicatedStorage.Lib)

local Knit = require(ReplicatedStorage.Packages.Knit)
local CharacterService
local EmoteService

local GameInfo = require(ReplicatedStorage.Data.GameInfo)

local Trove = require(ReplicatedStorage.Modules.Trove)
local TeamInfo = require(ReplicatedStorage.Data.TeamInfo)

local trove = Trove.new()

local MINIMUM_PLAYERS = 1

local INTERMISSION_TIME = 10
local TEAM_SELECT_TIME = 15
local GOAL_FOCUS_TIME = 10
local CELEBRATION_TIME = 10

local teamNames = {}
for teamName in pairs(TeamInfo) do
table.insert(teamNames, teamName)
end

local serverAssets = ServerStorage.Assets
local kits: Folder = serverAssets.Kits


local privateServerInfo = ReplicatedStorage.PrivateServerInfo
local serverInfo = ReplicatedStorage.ServerInfo
if RunService:IsStudio() then
MINIMUM_PLAYERS = 1

INTERMISSION_TIME = 0
VOTING_TIME = 0
TEAM_SELECT_TIME = 0
PRE_GAME_TIME = 0
end

local homeTeam, awayTeam = Teams.Home, Teams.Away


local function doSomethingWithPlayersInGame(callback)
for _, player in pairs(Players:GetPlayers()) do
if player.Team ~= homeTeam and player.Team ~= awayTeam then continue end
callback(player)
end
end

local function getEligiblePlayers()
local eligiblePlayers = {}
for _, player in pairs(Players:GetPlayers()) do
-- if not player:GetAttribute("Loaded") then continue end
table.insert(eligiblePlayers, player)
end
return eligiblePlayers
end

local function getUniqueNames()
local clonedList = table.clone(teamNames)
local homeIndex = math.random(1, #clonedList)
local homeName = clonedList[homeIndex]
table.remove(clonedList, homeIndex)

local homeInfo = TeamInfo[homeName]
while #clonedList > 0 do
local awayIndex = math.random(1, #clonedList)
local awayName = clonedList[awayIndex]
local awayInfo = TeamInfo[awayName]
if true then
return homeName, awayName
end
end
return
end

local function clearRole(player: Player)
local roleObjects: {ObjectValue} = serverInfo:GetDescendants()
for _, roleObject in pairs(roleObjects) do
if not roleObject:IsA("ObjectValue") then continue end
if roleObject.Value == player then
roleObject.Value = nil
break
end
end
end


local GameService = {
Name = "GameService",
Client = {
InstantTeleport = Knit.CreateSignal(),
PlayerTeleported = Knit.CreateSignal(),
},
}

function GameService:KnitInit()
local function changeServerAttribute(attributeName, value)
serverInfo:SetAttribute(attributeName, serverInfo:GetAttribute(attributeName) + value)
end
homeTeam.PlayerAdded:Connect(function()
changeServerAttribute("HomePlayers", 1)
end)
homeTeam.PlayerRemoved:Connect(function(player)
clearRole(player)
changeServerAttribute("HomePlayers", -1)
end)
awayTeam.PlayerAdded:Connect(function()
changeServerAttribute("AwayPlayers", 1)
end)
awayTeam.PlayerRemoved:Connect(function(player)
clearRole(player)
changeServerAttribute("AwayPlayers", -1)
end)

local function addRoleObject(roleObject)
local lastPlayer: Player | nil = nil
roleObject.Changed:Connect(function(newPlayer)
if newPlayer == nil and lastPlayer ~= nil then
lastPlayer:SetAttribute("Position", nil)
end
lastPlayer = newPlayer
if newPlayer ~= nil then
newPlayer:SetAttribute("Position", roleObject.Name)
end
end)
end
for _, roleObject in pairs(serverInfo.Home:GetChildren()) do
addRoleObject(roleObject)
end
for _, roleObject in pairs(serverInfo.Away:GetChildren()) do
addRoleObject(roleObject)
end
end

function GameService:KnitStart()
local services = script.Parent
CharacterService = require(services.CharacterService)
EmoteService = require(services.EmoteService)

Players.PlayerRemoving:Connect(function(player)
self:PlayerRemoving(player)
end)
Players.PlayerAdded:Connect(function(player)
self:PlayerAdded(player)
end)
for _, player in pairs(Players:GetPlayers()) do
task.spawn(function()
self:PlayerAdded(player)
end)
end

serverInfo:GetAttributeChangedSignal("GameStatus"):Connect(function()
if serverInfo:GetAttribute("GameStatus") ~= "InProgress" then
return
end
for _, player in pairs(Players:GetPlayers()) do
if player.Team ~= homeTeam and player.Team ~= awayTeam then continue end
task.spawn(function()
self:UpdateMoveability(player)
end)
end
for _, goalkeeper in pairs(CollectionService:GetTagged("Goalkeeper")) do
task.spawn(function()
self:UpdateMoveability(goalkeeper)
end)
end
end)


-- Leaderboard Ping
task.spawn(function()
while task.wait(1) do
for _, player in pairs(Players:GetPlayers()) do
local serverNetworkPing = Lib.getHiddenAttribute(player, "ServerNetworkPing")
if serverNetworkPing then
player:SetAttribute("NetworkPing", serverNetworkPing)
else
player:SetAttribute("NetworkPing", math.clamp(math.floor(player:GetNetworkPing()*2000), 0, 1000))
end
end
end
end)

self:WaitForPlayers()
end

function GameService:PlayerAdded(player: Player)
local function characterAdded()
local character = player.Character
character:WaitForChild("HumanoidRootPart")
if player.Team ~= homeTeam and player.Team ~= awayTeam then
return
end
task.defer(function()
self:TeleportPlayer(player, nil, true)
end)
end

if player.Character then
task.spawn(characterAdded)
end
player.CharacterAdded:Connect(characterAdded)
end

function GameService:PlayerRemoving(player: Player)
if player:GetAttribute("Position") ~= "Goalkeeper" then
return
end

if player.Team == homeTeam then
serverInfo.Home.Goalkeeper.Value = nil
elseif player.Team == awayTeam then
serverInfo.Away.Goalkeeper.Value = nil
end
end

-- Ball Utility
function GameService:ClearAllBalls()
local function removeBall(ball: BasePart)
ball:RemoveTag("Ball")
ball:Destroy()
end

local balls = workspace.GameItems.Balls
for _, ball: BasePart in pairs(balls:GetChildren()) do
removeBall(ball)
end
for _, ball: BasePart in pairs(CollectionService:GetTagged("Ball")) do
if not ball:IsDescendantOf(workspace) then
continue
end
removeBall(ball)
end
end

-- Round Handling
function GameService:TeleportPlayer(player: Player | Model, spawnPart: BasePart, ignoreLoadingScreen: boolean, disableShiftLock: boolean)
if player:IsA("Player") then
local playerRecord = CharacterService.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end

if player:IsA("Player") and player:GetAttribute("Position") == nil then
return
end

if spawnPart == nil then
local mapSpawns = workspace.MapItems.TeamSpawns

local team = player.Team
if player:HasTag("Goalkeeper") then
team = team.Value
end

local teamSpawns = mapSpawns:FindFirstChild(team.Name)
if teamSpawns == nil then
return warn("Couldn't find team spawn for: " .. team.Name)
end
spawnPart = teamSpawns[player:GetAttribute("Position")]
end

local freezeCFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
local function teleport()
player:SetAttribute("Teleported", true)

local _, yRot, _ = freezeCFrame:ToEulerAnglesYXZ()
local chickynoid = playerRecord.chickynoid
if chickynoid then
chickynoid:SetPosition(freezeCFrame.Position, true)
chickynoid.simulation:SetAngle(yRot, true)
chickynoid.simulation.state.tackleCooldown = 0
else
playerRecord.position = freezeCFrame.Position
playerRecord.angle = yRot
end

self:UpdateMoveability(player, disableShiftLock)
end

player:SetAttribute("Teleported", nil)
if ignoreLoadingScreen then
self.Client.InstantTeleport:Fire(player, freezeCFrame, disableShiftLock)
teleport()
else
self.Client.PlayerTeleported:Fire(player, freezeCFrame, disableShiftLock)

player:SetAttribute("Teleported", false)
local teleportTrove = Trove.new()
teleportTrove:AttachToInstance(player)
teleportTrove:Connect(player:GetAttributeChangedSignal("Teleported"), function()
teleportTrove:Destroy()
end)
teleportTrove:Add(task.delay(1, teleport))
end
else
local character = player
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart == nil then
return
end

if spawnPart == nil then
local mapSpawns = workspace.MapItems.TeamSpawns

local team = player.Team
if player:HasTag("Goalkeeper") then
team = team.Value
end

local teamSpawns = mapSpawns:FindFirstChild(team.Name)
if teamSpawns == nil then
warn("Couldn't find team spawn for: " .. team.Name)
return
end
spawnPart = teamSpawns[player:GetAttribute("Position")]
end

local freezeCFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
local function teleport()
if not character:GetAttribute("TeleportedToField") then
task.delay(1, function()
character:SetAttribute("TeleportedToField", true)
end)
end
character:PivotTo(freezeCFrame)
character:SetAttribute("FreezePosition", freezeCFrame.Position)
self:UpdateMoveability(player)
end
teleport()
end
end

function GameService:UpdateMoveability(player: Player, completeFreeze: boolean?)
local gameStatus = serverInfo:GetAttribute("GameStatus")
local movementDisabled = player.Team.Name ~= "Fans" and (gameStatus == "Paused" or gameStatus == "GameEnded") and not serverInfo:GetAttribute("CanStillMove")
player:SetAttribute("MovementDisabled", movementDisabled)
player:SetAttribute("CompleteFreeze", completeFreeze)
end

function GameService:BallPassed(passingPlayer: Player)
-- player passed
end

function GameService:GoalScored(teamScoredOn: string)
local ballController = CharacterService.ServerModule.ballRecord.ballController

local oppositeTeam = teamScoredOn == "Home" and "Away" or "Home"
local scoreAttribute = oppositeTeam .. "Score"
serverInfo:SetAttribute(scoreAttribute, serverInfo:GetAttribute(scoreAttribute) + 1)

serverInfo:SetAttribute("CanStillMove", true)
serverInfo:SetAttribute("GameStatus", "Paused")


local ballState = ballController.simulation.state
local playerWhoScored: Player = Players:GetPlayerByUserId(ballState.netId)
task.delay(0.5, function()
serverInfo.SpectateOverride.Value = playerWhoScored
end)

if ballController:getAttribute("Team") == nil then
ballController:setAttribute("Team", oppositeTeam)
end
local nameWhoScored: string = ballController:getAttribute("OwnerName") or serverInfo:GetAttribute(ballController:getAttribute("Team") .. "Name")

local scoredOnOwnGoal = ballController:getAttribute("Team") == teamScoredOn

local assistName: string = nil
local assistPlayer: Player = ballController:getAttribute("AssistPlayer")
local assistTime: number = ballController:getAttribute("AssistTime")
if not scoredOnOwnGoal
and assistPlayer ~= nil and assistPlayer ~= playerWhoScored and assistPlayer.Team and assistPlayer.Team.Name == ballController:getAttribute("Team")
and assistTime and os.clock() - assistTime < GameInfo.MAX_ASSIST_TIME then
assistName = assistPlayer.DisplayName
end

task.spawn(function()
if playerWhoScored == nil or playerWhoScored:HasTag("Goalkeeper") then return end

if scoredOnOwnGoal then
-- playerWhoScored scored an own goal
return
end

-- scored goal
end)
task.spawn(function()
if assistPlayer == nil or scoredOnOwnGoal then return end

-- assistPlayer assisted
end)


task.wait(GOAL_FOCUS_TIME)

serverInfo:SetAttribute("CanStillMove", false)
if serverInfo:GetAttribute("RoundTime") == 0 then
serverInfo:SetAttribute("GameStatus", "GameEnded")
task.wait(1)
return
end

self:StartNewRound(teamScoredOn)

doSomethingWithPlayersInGame(function(player)
task.spawn(function()
self:TeleportPlayer(player)
end)
end)
for _, goalkeeper in pairs(CollectionService:GetTagged("Goalkeeper")) do
task.spawn(function()
self:TeleportPlayer(goalkeeper)
end)
end

serverInfo.SpectateOverride.Value = nil
task.wait(3)

serverInfo:SetAttribute("GameStatus", "InProgress")
end

function GameService:StartNewRound(teamAdvantage: string)
workspace.GameItems.Balls:ClearAllChildren()


local ballSpawn = workspace.MapItems.BallSpawn
local function createBall()
local ballRecord = CharacterService.ServerModule.ballRecord
ballRecord:Spawn(ballSpawn.CFrame.Position)
end
createBall()
end

-- Round Loop
function GameService:WaitForPlayers()
trove:Clean()

self:ClearAllBalls()

for _, roleObject: ObjectValue in pairs(serverInfo.Home:GetChildren()) do
roleObject.Value = nil
end
for _, roleObject: ObjectValue in pairs(serverInfo.Away:GetChildren()) do
roleObject.Value = nil
end

serverInfo:SetAttribute("RoundTime", privateServerInfo:GetAttribute("MatchTime") * 60)
serverInfo:SetAttribute("GameStatus", "Waiting")
for _, player in pairs(Players:GetPlayers()) do
self:UpdateMoveability(player)
end

self:StartIntermission()
end

function GameService:StartIntermission()
serverInfo:SetAttribute("StatusTime", INTERMISSION_TIME)
serverInfo:SetAttribute("GameStatus", "Intermission")

repeat
local deltaTime = task.wait(0.1)
local newTime = math.max(0, serverInfo:GetAttribute("StatusTime") - deltaTime)
serverInfo:SetAttribute("StatusTime", newTime)
while #getEligiblePlayers() < MINIMUM_PLAYERS do
self:WaitForPlayers()
return
end
until newTime == 0

self:StartTeamSelect()
end

function GameService:StartTeamSelect()
self:MakeNewTeams()

serverInfo:SetAttribute("StatusTime", TEAM_SELECT_TIME)
serverInfo:SetAttribute("GameStatus", "Team Selection")
repeat
local deltaTime = task.wait(0.1)
local newTime = math.max(0, serverInfo:GetAttribute("StatusTime") - deltaTime)
serverInfo:SetAttribute("StatusTime", newTime)
until newTime == 0

self:StartGame()
end

function GameService:StartGame()
serverInfo:SetAttribute("GameStatus", "Paused")
self:StartNewRound()

doSomethingWithPlayersInGame(function(player)
task.spawn(function()
self:TeleportPlayer(player)
end)
end)

task.wait(2)

serverInfo:SetAttribute("GameStatus", "InProgress")
self:StartGameCountdown()
end

function GameService:StartGameCountdown()
repeat
local deltaTime = task.wait(0.1)

local updatedTime = serverInfo:GetAttribute("RoundTime")
if serverInfo:GetAttribute("GameStatus") == "InProgress" then
updatedTime = math.max(0, updatedTime - deltaTime)
serverInfo:SetAttribute("RoundTime", updatedTime)
end
until updatedTime == 0


local function isTied()
return serverInfo:GetAttribute("HomeScore") == serverInfo:GetAttribute("AwayScore")
end
if isTied() then
-- do tied stuff idk
end

-- If it was a golden goal, wait until the score cutscene ends
while serverInfo:GetAttribute("GameStatus") ~= "InProgress" and serverInfo:GetAttribute("GameStatus") ~= "GameEnded" do
task.wait(0.1)
end

self:EndGame()
end

function GameService:EndGame()
serverInfo:SetAttribute("CanStillMove", true)
serverInfo:SetAttribute("GameStatus", "GameEnded")

task.wait(3.5)
serverInfo:SetAttribute("CanStillMove", false)

self:ClearAllBalls()

local teamWhoWon = serverInfo:GetAttribute("HomeScore") > serverInfo:GetAttribute("AwayScore") and "Home" or "Away"
local teamWhoLost = serverInfo:GetAttribute("HomeScore") > serverInfo:GetAttribute("AwayScore") and "Away" or "Home"


task.wait(0.5)
doSomethingWithPlayersInGame(function(player: Player)
local playerRecord = CharacterService.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return
end
playerRecord:SetCharacterMod("FieldChickynoid")

if player.Team and player.Team.Name ~= teamWhoWon then
return
end
end)


doSomethingWithPlayersInGame(function(player: Player)
-- send data
end)

doSomethingWithPlayersInGame(function(player: Player)
if player.Team and player.Team.Name ~= teamWhoWon then
return
end

--- player won
end)

local realTeamName = serverInfo:GetAttribute(teamWhoWon .. "Name")

local realLosingTeamName = serverInfo:GetAttribute(teamWhoLost .. "Name")

task.wait(CELEBRATION_TIME)
doSomethingWithPlayersInGame(function(player: Player)
-- player.Team = Teams.Fans
-- task.spawn(function()
-- player:LoadCharacter()
-- end)
self:ResetBackToLobby(player)
end)
task.wait(1.5)
self:WaitForPlayers()
end

-- Teams
function GameService:UpdateKit(player: Player)
if player.Team ~= homeTeam and player.Team ~= awayTeam then return end
local teamName = player.Team == homeTeam and serverInfo:GetAttribute("HomeName") or serverInfo:GetAttribute("AwayName")
local kitClothing = kits:FindFirstChild(teamName)


local playerRecord = CharacterService.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
return warn("[GameService] Player record doesn't exist! | :UpdateKit()")
end

playerRecord.avatarDescription = {
kitClothing.Shirt.ShirtTemplate,
kitClothing.Pants.PantsTemplate,
player:GetAttribute("KitName") or player.DisplayName,
player:GetAttribute("KitNumber") or math.random(1, 99),
player.Team:GetAttribute("TeamColor"),
}
playerRecord:SetCharacterMod(if player:GetAttribute("Position") == "Goalkeeper" then "GoalkeeperChickynoid" else "FieldChickynoid")
end

function GameService:MakeNewTeams()
local homeName, awayName = getUniqueNames()
serverInfo:SetAttribute("HomeName", homeName)
serverInfo:SetAttribute("AwayName", awayName)
serverInfo:SetAttribute("HomeScore", 0)
serverInfo:SetAttribute("AwayScore", 0)
homeTeam:SetAttribute("TeamName", homeName)
awayTeam:SetAttribute("TeamName", awayName)

local homeColor = TeamInfo[homeName].MainColor
local awayColor = TeamInfo[awayName].MainColor
homeTeam:SetAttribute("TeamColor", homeColor)
awayTeam:SetAttribute("TeamColor", awayColor)
homeTeam.TeamColor = BrickColor.new(homeColor)
awayTeam.TeamColor = BrickColor.new(awayColor)
if homeTeam.TeamColor == awayTeam.TeamColor then
warn("Same team colors: ", homeName, awayName)
end
end

function GameService:SelectTeam(player: Player, teamName: string, role: string)
-- if not player:GetAttribute("Loaded") then
-- return
-- end

local playerRecord = CharacterService.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
warn("[GameService] Player record doesn't exist! | :SelectTeam()")
return
end


if player.Team.Name == "Home" or player.Team.Name == "Away" then
teamName = player.Team.Name
end
if type(teamName) ~= "string" or (teamName ~= "Home" and teamName ~= "Away") then
return
end
local gameStatus = serverInfo:GetAttribute("GameStatus")
if gameStatus ~= "InProgress" and gameStatus ~= "Team Selection" and gameStatus ~= "Paused" and gameStatus ~= "Practice" then
return
end

if Lib.isOnHiddenCooldown(player, "TeamSelectCooldown") then
return
end


local homePlayers, awayPlayers = serverInfo:GetAttribute("HomePlayers"), serverInfo:GetAttribute("AwayPlayers")
if player:GetAttribute("Position") == "Goalkeeper" then
if (teamName == "Home" and homePlayers - 1 > awayPlayers) or (teamName == "Away" and awayPlayers - 1 > homePlayers) then
-- team has too many players
return
end
elseif not RunService:IsStudio() then
if (teamName == "Home" and homePlayers > awayPlayers) or (teamName == "Away" and awayPlayers > homePlayers) then
-- team has too many players
return
end
end

if type(role) ~= "string" then
return
end
local roles = serverInfo[teamName]
local roleObject: ObjectValue = roles:FindFirstChild(role)
if roleObject == nil or roleObject.Value ~= nil then
-- position already taken
return
end

Lib.removeHiddenCooldown(player, "BallClaimCooldown")
Lib.setHiddenCooldown(player, "TeamSelectCooldown", 1)
local oldPosition = player:GetAttribute("Position")
if oldPosition == "Goalkeeper" then
if Lib.isOnCooldown(player, "SwitchOnFieldCD") then
-- on cd
return
end

Lib.setCooldown(player, "GoalkeeperCD", 10)
task.spawn(function()
CharacterService:ResetBall(player, true)
end)
clearRole(player)
roleObject.Value = player

self:UpdateKit(player)
if gameStatus == "InProgress" or gameStatus == "Paused" or gameStatus == "Practice" then
self:TeleportPlayer(player, nil, oldPosition ~= nil)
EmoteService:EndEmote(player)
end
else
if player.Team.Name == "Home" or player.Team.Name == "Away" then
return
end
local team = Teams:FindFirstChild(teamName)
if team == nil then
return
end

roleObject.Value = player
player.Team = team


self:UpdateKit(player)
if gameStatus == "InProgress" or gameStatus == "Paused" or gameStatus == "Practice" then
self:TeleportPlayer(player, nil, oldPosition ~= nil)
EmoteService:EndEmote(player)
end
end
end

function GameService:ResetBackToLobby(player: Player)
if player.Team ~= homeTeam and player.Team ~= awayTeam then
return
end

local playerRecord = CharacterService.ServerModule:GetPlayerByUserId(player.UserId)
local chickynoid = playerRecord.chickynoid
if chickynoid == nil then
return
end

local list = {}
for _, obj in pairs(workspace:GetDescendants()) do
if obj:IsA("SpawnLocation") and obj.Enabled == true then
table.insert(list, obj)
end
end

if #list > 0 then
task.delay(0.5, function()
if player == nil or not player:IsDescendantOf(game) then
return
end
playerRecord.avatarDescription = nil
playerRecord:SetCharacterMod("HumanoidChickynoid")
end)

local spawn = list[math.random(1, #list)]
self:TeleportPlayer(player, spawn)
end

player.Team = Teams.Fans
end

-- Goalkeeper
function GameService:BecomeGoalkeeper(player: Player)
if not Lib.playerInGame(player) then
return
end

local playerRecord = CharacterService.ServerModule:GetPlayerByUserId(player.UserId)
if playerRecord == nil then
warn("[GameService] Player record doesn't exist! | :BecomeGoalkeeper()")
return
end


local roles = serverInfo[player.Team.Name]
local roleObject: ObjectValue = roles.Goalkeeper
if roleObject.Value ~= nil then
return
end

local gameStatus = serverInfo:GetAttribute("GameStatus")
if gameStatus ~= "InProgress" and gameStatus ~= "Team Selection" and gameStatus ~= "Paused" and gameStatus ~= "Practice" then
return
end

if Lib.isOnCooldown(player, "GoalkeeperCD") then
-- on cd
return
end

Lib.setCooldown(player, "SwitchOnFieldCD", 10)
task.spawn(function()
CharacterService:ResetBall(player, true)
end)
clearRole(player)
roleObject.Value = player


self:UpdateKit(player)
self:TeleportPlayer(player, nil, true)
end


-- Client Events

-- Goalkeeper
function GameService.Client:BecomeGoalkeeper(...)
self.Server:BecomeGoalkeeper(...)
end

-- Teams/Leaving
function GameService.Client:ResetBackToLobby(...)
self.Server:ResetBackToLobby(...)
end

function GameService.Client:SelectTeam(...)
self.Server:SelectTeam(...)
end

return GameService
src/server/HiddenAttributes.server.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Trove = require(ReplicatedStorage.Modules.Trove)

local hiddenAttributeFolder = Instance.new("Folder")
hiddenAttributeFolder.Name = "HiddenAttributes"
hiddenAttributeFolder.Parent = ServerStorage


Players.PlayerAdded:Connect(function(player)
local trove = Trove.new()
trove:AttachToInstance(player)

local hiddenAttributes = Instance.new("Folder")
hiddenAttributes.Name = player.Name
hiddenAttributes.Parent = hiddenAttributeFolder
trove:Add(hiddenAttributes)

local attributeObject = Instance.new("ObjectValue")
attributeObject.Name = "HiddenAttributes"
attributeObject.Value = hiddenAttributes
attributeObject.Parent = player
end)
src/server/RagdollServer.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.RagdollHandler)
src/server/Runtime.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)


for _, serviceModule: ModuleScript in pairs(script.Parent.Services:GetChildren()) do
if not serviceModule:IsA("ModuleScript") then continue end
local service = require(serviceModule)
Knit.CreateService(service)
end
Knit.Start()
src/server/StarterGuiToReplicatedStorage.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local assets = ReplicatedStorage.Assets
local baseGUI = assets.GUI.Base


for _, gui in pairs(StarterGui:GetChildren()) do
gui.Parent = baseGUI
end
src/main.rs
fn main() {
println!("Hello, world!");
}
