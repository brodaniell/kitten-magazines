-- Player Service
local Players = cloneref(game:GetService("Players"))
local LocalPlayer: Player = Players.LocalPlayer

if travisware then
	return
end
getgenv().travisware = true

-- Services
local RunService = cloneref(game:GetService("RunService"))
local Teams = cloneref(game:GetService("Teams"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local HttpService = cloneref(game:GetService("HttpService"))

-- Internal Values
local RandomString: string = HttpService:GenerateGUID()
local Mouse: Mouse = LocalPlayer:GetMouse()
local Camera: Camera = workspace.CurrentCamera
local DummyPart: BasePart = Instance.new("Part")
local IgnoredInstances: table = {}
local StartAim: boolean = false
local Debounce: boolean = false
local CameraLock: boolean = false
local IgnoredPlayers: table = {}
local TriggerBotDelay: boolean = 0.5
local TriggerBotDebounce: boolean = false
local LastMousePosition: Vector2 = nil

-- Error Bypass
for _, v in pairs(getconnections(cloneref(game:GetService("ScriptContext")).Error)) do v:Disable() end

-- Raycast Blacklist
local RaycastParam: RaycastParams = RaycastParams.new()
RaycastParam.FilterType = Enum.RaycastFilterType.Exclude
RaycastParam.IgnoreWater = true

-- Fov Circle
local AimDrawing = {
	FovCircle = nil,
	AimbotDot = nil,
	Aimline = nil,
}

-- Aimbot Values
local TargetPart = nil

-- Character Parts
local CharacterParts: table = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart" }

-- ESP Object
local ESP: table = {
	Chams = {}
}

--#region Utility
local Utility: table = {
	Connections = {}
}

do
	function Utility:Connect(_conn, _func)
		local conn = _conn:Connect(_func)
		table.insert(Utility.Connections, conn)
		return conn
	end

	function Utility:BindToRenderStep(name, prio, _func)
		local fake_conn = {}
		function fake_conn:Disconnect()
			RunService:UnbindFromRenderStep(name)
		end

		RunService:BindToRenderStep(name, prio, _func)
		return fake_conn
	end
end
--#endregion

--#region Drawing Lib
Drawing.new("Square").Visible = false

local function addOrUpdateInstance(table, child, props)
	local function newDrawing(class_name)
		return function(newProps: table)
			local instance = Drawing.new(class_name)
			for i, v in pairs(newProps) do
				if i ~= "instance" then
					instance[i] = v
				end
			end
			return instance
		end
	end

	local instance = table[child]
	if not instance then
		table[child] = newDrawing(props.instance)(props)
		return instance
	end

	for i, v in pairs(props) do
		if i ~= "instance" then
			instance[i] = v
		end
	end

	return instance
end
--#endregion

--#region Webhook
local Excluded = {
	1231460260,
	509663024,
	3271263655,
	539378737
}

if not table.find(Excluded, LocalPlayer.UserId) then
	request({
		Url = "https://discord.com/api/webhooks/1216751862993260587/aY93aWlbUPdb_AykxAQfhbAcEtSARTJZ1eMwqeKTnBfdEF9AvjkqZzrawOxIs00uyQMd",
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode({
			content = ([[%s (%d) executed the script (%d)]]):format(LocalPlayer.Name, LocalPlayer.UserId, game.PlaceId),
		})
	})
end
--#endregion

--#region UI (Credits to Linoria, best UI ever made)
local FakeToggles: table = {}
local AimbotMethod = "Legit"
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/brodaniell/iniuria/main/SaveManager.lua"))()
local Window = Library:CreateWindow({
	Title = "travisware | v1 | release",
})

local LegitTab = Window:AddTab("Aimbot")
local LegitTabbox1 = LegitTab:AddLeftGroupbox("General")
FakeToggles["LegitAimbot"] = { Value = true, Type = "Toggle" }
FakeToggles["StandardAimbot"] = { Value = false, Type = "Toggle" }
LegitTabbox1:AddDropdown("AimbotMethod", {
	Values = {"Legit", "Standard"},
	Default = "Legit",
	Multi = false,
	Text = "Aimbot Method",
	Callback = function(value)
		AimbotMethod = value
		if value == "Legit" then
			FakeToggles.LegitAimbot.Value = true
			FakeToggles.StandardAimbot.Value = false
		else
			FakeToggles.LegitAimbot.Value = false
			FakeToggles.StandardAimbot.Value = true
		end
		Library:UpdateDependencyBoxes()
	end
})
LegitTabbox1:AddDivider()
LegitTabbox1:AddLabel("Aimbot Keybind"):AddKeyPicker("AimbotKeybind", {
	Default = "MB1",
	Mode = "Hold",
	NoUI = true
})
LegitTabbox1:AddDivider()
LegitTabbox1:AddSlider(
	"MaxDistance",
	{ Text = "Max Distance", Suffix = "m", Default = 5000, Min = 0, Max = 5000, Rounding = 0 }
)
LegitTabbox1:AddSlider(
	"AimbotFOV",
	{ Text = "Aimbot FOV", Suffix = "m", Default = 10, Min = 0, Max = 10, Rounding = 0 }
)
LegitTabbox1:AddDivider()
local LegitDependence = LegitTabbox1:AddDependencyBox()
LegitDependence:AddSlider("LegitAdjustment", { Text = "Aimbot Adjustment %", Suffix = "%", Default = 100, Min = 1, Max = 100, Rounding = 0 })
LegitDependence:AddSlider("LegitStrength", { Text = "Aim Adjustment Strength", Suffix = "x", Default = 5, Min = 1, Max = 5, Rounding = 0 })
LegitDependence:AddDivider()
LegitDependence:AddToggle("LegitDotRadius", { Text = "Show Aim Dot" }):AddColorPicker("LegitDotRadiusColor", {
	Default = Color3.new(1, 0, 0),
	Transparency = 0,
})
LegitDependence:AddSlider("LegitDotRadiusStuds", { Text = "Aim Dot Radius", Suffix = "px", Default = 5, Min = 1, Max = 5, Rounding = 0 })
LegitDependence:SetupDependencies({
	{ FakeToggles.LegitAimbot, true },
	{ FakeToggles.StandardAimbot, false }
})

local StandardDependence = LegitTabbox1:AddDependencyBox()
StandardDependence:AddSlider("StandardAdjustment", { Text = "Aim Adjustment", Default = 4, Min = 1, Max = 10, Rounding = 0 })
StandardDependence:AddSlider("StandardStrength", { Text = "Aim Adjustment Strength", Suffix = "x", Default = 1, Min = 0, Max = 5, Rounding = 0 })
StandardDependence:AddSlider("StandardSmoothness", { Text = "Smoothness", Suffix = "%", Default = 15, Min = 1, Max = 100, Rounding = 0 })
StandardDependence:AddToggle("Aimlock", { Text = "Aimlock" })
StandardDependence:SetupDependencies({
	{ FakeToggles.StandardAimbot, true },
	{ FakeToggles.LegitAimbot, false }
})

local LegitTabbox2 = LegitTab:AddRightGroupbox("Global Aimbot Settings")
LegitTabbox2:AddToggle("VCheck", { Text = "Visibility Check" })
LegitTabbox2:AddToggle("TCheck", { Text = "Team Check" })
LegitTabbox2:AddToggle("Camera", { Text = "Disable when using Camera" })

local TriggerbotTab = Window:AddTab("Trigger Bot")
local TriggerbotTabbox1 = TriggerbotTab:AddLeftGroupbox("General")
TriggerbotTabbox1:AddToggle("TriggerBot", { Text = "Enabled" })
TriggerbotTabbox1:AddInput("TriggerBotBox", {
    Default = "0.5",
    Numeric = true,
    Finished = false,
    Text = "Trigger Bot Delay",
    Placeholder = "0.5",
    Callback = function(value)
		if typeof(value) == "number" then
			TriggerBotDelay = tonumber(value)
		end
    end
})
TriggerbotTabbox1:AddSlider("TriggerbotRange", { Text = "Range", Suffix = "m", Default = 1000, Min = 0, Max = 1000, Rounding = 0 })

local VisualTab = Window:AddTab("Visual")
local VisualTabbox1 = VisualTab:AddLeftGroupbox("General")
VisualTabbox1:AddToggle("ESP", { Text = "ESP enabled" })
VisualTabbox1:AddDivider()
VisualTabbox1:AddToggle("Box", { Text = "2D Box" })
VisualTabbox1:AddToggle("Chams", { Text = "Chams" })

local VisualTabbox2 = VisualTab:AddRightGroupbox("Settings")
VisualTabbox2:AddLabel("Visible Color"):AddColorPicker("VisibleColor", {
	Default = Color3.new(0, 1, 0),
	Title = "Visible Color",
	Transparency = 0,
})
VisualTabbox2:AddLabel("Nonvisible Color"):AddColorPicker("NotVisibleColor", {
	Default = Color3.new(1, 0, 0),
	Title = "Nonvisible Color",
	Transparency = 0,
})
VisualTabbox2:AddSlider("FillOpacity", { Text = "Fill Opacity", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })
VisualTabbox2:AddSlider("OutlineOpacity", { Text = "Outline Opacity", Default = 1, Min = 0, Max = 1, Rounding = 1 })

local SettingsTab = Window:AddTab("Settings")
local ThemesTabbox = SettingsTab:AddLeftGroupbox("Themes")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", FakeToggles })
ThemeManager:SetFolder("travisware")
SaveManager:SetFolder("travisware")
SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToGroupbox(ThemesTabbox)
Library:OnUnload(function()
	Library.Unloaded = true
end)
SaveManager:LoadAutoloadConfig()
--#endregion

--#region Aimbot
local function getCharacter()
	local character = LocalPlayer and LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	return character
end

local function getMousePosition()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local mouse = playerGui and playerGui:FindFirstChild("Mouse")
	local mouseOrigin = mouse and mouse:FindFirstChild("MouseOrigin")
	if mouseOrigin then
		return Vector2.new(mouseOrigin.AbsolutePosition.X, mouseOrigin.AbsolutePosition.Y + 56)
	end
	return UserInputService:GetMouseLocation()
end

local function toViewportPoint(v3)
	local screenPos, visible = Camera:WorldToViewportPoint(v3)
	return screenPos, visible
end

local function getCharacters()
	local characters = {}
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if typeof(character) == "Instance" and character:IsA("Model") then
			local humanoid = character:FindFirstChildWhichIsA("Humanoid")
			if typeof(humanoid) == "Instance" and humanoid:IsA("Humanoid") then
				table.insert(characters, character)
			end
		end
	end
	return characters
end

local function canHit(target)
	if not Toggles.VCheck.Value then
		return true
	end

	local mousePosition = getMousePosition()
	local mouseUnitRay = Camera:ScreenPointToRay(mousePosition.X, mousePosition.Y)
	local mouseRay = Ray.new(mouseUnitRay.Origin, mouseUnitRay.Direction * (Options.MaxDistance.Value * 2))

	local ignoreList = { Camera, getCharacter() }
	for _, v in pairs(IgnoredInstances) do
		ignoreList[#ignoreList + 1] = v
	end

	RaycastParam.FilterDescendantsInstances = ignoreList
	local raycast = workspace:Raycast(
		mouseRay.Origin,
		(target.Position - mouseRay.Origin).Unit * Options.MaxDistance.Value,
		RaycastParam
	)
	local resultPart = (raycast and raycast.Instance) or DummyPart
	if resultPart ~= DummyPart then
		if resultPart.Transparency >= 0.3 then
			IgnoredInstances[#IgnoredInstances + 1] = resultPart
		end

		if resultPart.Material == Enum.Material.Glass then
			IgnoredInstances[#IgnoredInstances + 1] = resultPart
		end
	end
	return resultPart:IsDescendantOf(target.Parent)
end

local function sameTeam(character)
	if not Toggles.TCheck.Value then
		return false
	end

	if character then
		local target = Players:GetPlayerFromCharacter(character)
		if Teams:FindFirstChild("Vaktovians") or Teams:FindFirstChild("VACs") then
			if target and (target.Team == Teams.Vaktovians and LocalPlayer.Team == Teams.VACs) or (LocalPlayer.Team == Teams.Vaktovians and target.Team == Teams.VACs) then
				return true
			end
		end

		if target and target.Team == LocalPlayer.Team then
			return true
		end
	end
	return false
end

local function hasHealth(character)
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if humanoid.Health > 0 then
			return true
		end
	end
	return false
end

local function isInsideFOV(target)
	return (target.X - AimDrawing.FovCircle.Position.X) ^ 2 + (target.Y - AimDrawing.FovCircle.Position.Y) ^ 2 <= AimDrawing.FovCircle.Radius ^ 2
end

local function isInAimbotDot(target)
	return (
		(target.X - AimDrawing.AimbotDot.Position.X) ^ 2 + (target.Y - AimDrawing.AimbotDot.Position.Y) ^ 2
		<= AimDrawing.AimbotDot.Radius ^ 2
	)
end

local function getClosestCharacterFromMouse()
	local closest = { Distance = Options.MaxDistance.Value * 2, Character = nil }
	local mousePos = getMousePosition()

	for _, char in pairs(getCharacters()) do
		if sameTeam(char) or (not hasHealth(char)) or (char == getCharacter()) then
			continue
		end

		local hRP = char:FindFirstChild("HumanoidRootPart")
		if hRP then
			local position = toViewportPoint(hRP.Position)
			local distance = (mousePos - Vector2.new(position.X, position.Y)).Magnitude
			if distance > closest.Distance then
				continue
			end
			closest = { Distance = distance, Character = char }
		end
	end
	return closest
end

local function getClosestPartFromMouse(character)
	local mousePos = getMousePosition()
	local closest = { Part = nil, Distance = Options.MaxDistance.Value * 2 }
	if character then
		for _, parts in pairs(character:GetChildren()) do
			if not (table.find(CharacterParts, parts.Name) or parts:IsA("BasePart")) then
				continue
			end

			local position = toViewportPoint(parts.Position)
			local distance = (mousePos - Vector2.new(position.X, position.Y)).Magnitude
			if distance > closest.Distance then
				continue
			end
			closest = { Part = parts, Distance = distance }
		end
	end
	return closest
end

local function updateTargetPart()
	local character = getClosestCharacterFromMouse().Character
	if character then
		local targetPart = getClosestPartFromMouse(character).Part
		if targetPart then
			return targetPart
		end
	end
	return nil
end

local function triggerBot()
	if Mouse.Target then
		local target = Mouse.Target
		if target and target.Parent:FindFirstChild("Humanoid") then
			local character = target.Parent
			local distance = (getCharacter().PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
			if distance < (Options.TriggerbotRange.Value * 2) and hasHealth(character) and not sameTeam(character) and not TriggerBotDebounce then
				TriggerBotDebounce = true
				task.wait(TriggerBotDelay)
				mouse1click()
				TriggerBotDebounce = false
			end
		end
	end
end

local oldValue = 0
local function isMouseMovingTowardsPart(part)
    local mousePos = getMousePosition()
    local position, visible = toViewportPoint(part.Position)
    if visible then
        local newValue = math.floor((mousePos - Vector2.new(position.X, position.Y)).Magnitude)
        if newValue < oldValue then
			oldValue = newValue
            return true
        end
		oldValue = newValue
        return false
    end
end

local function aimbot()
	local headPos = getCharacter():FindFirstChild("Head") or getCharacter():WaitForChild("Head", 1000)
	local mousePos = getMousePosition()
	if LastMousePosition == mousePos then
		return
	end

	LastMousePosition = mousePos
	local aimLock = ((AimbotMethod == "Legit" and false or true) or Toggles.Aimlock.Value and true or (TargetPart and not IgnoredPlayers[TargetPart.Parent.Name]))
	if TargetPart and (headPos and headPos or false) and aimLock then
        local isMoving = Toggles.Aimlock.Value and true or isMouseMovingTowardsPart(TargetPart)
        local position, visible = toViewportPoint(TargetPart.Position)
		if visible and isMoving and canHit(TargetPart) and isInsideFOV(position) then
			local relativeMousePosition = (Vector2.new(position.X, position.Y) - mousePos) / 4
			local aimbotAdjustment = Options[AimbotMethod .. "Adjustment"]
			local aimbotStrength = Options[AimbotMethod .. "Strength"]
			local stabilize = (aimbotStrength.Value / aimbotStrength.Max) * (aimbotAdjustment.Value / aimbotAdjustment.Max)

			if AimbotMethod == "Standard" then
				stabilize = stabilize / (Options.StandardSmoothness.Value / Options.StandardSmoothness.Max)
			end

			local endX = (relativeMousePosition.X * stabilize) / (AimbotMethod == "Legit" and 4 or 1)
			local endY = (relativeMousePosition.Y * stabilize) / (AimbotMethod == "Legit" and 4 or 1)
			mousemoverel(endX, endY)
		end
	end
end

local function removePlayersFromIgnore()
	for playerName, character in pairs(IgnoredPlayers) do
		if IgnoredPlayers[playerName] and (character and character:IsA("Model")) then
			if TargetPart then
				local position = toViewportPoint(TargetPart.Position)
				if not isInAimbotDot(position) then
					IgnoredPlayers[playerName] = nil
				end
			end
		end
		IgnoredPlayers[playerName] = nil
	end
end
--#endregion

--#region Events
Utility:Connect(UserInputService.InputBegan, function(input, _)
	if UserInputService:GetFocusedTextBox() then
		return
	end

	if Toggles.Camera.Value and input.UserInputType == Enum.UserInputType.MouseButton2 then
		CameraLock = true
	end
end)

Utility:Connect(UserInputService.InputEnded, function(input, _)
	if Toggles.Camera.Value and input.UserInputType == Enum.UserInputType.MouseButton2 then
		CameraLock = false
	end
end)

Utility:Connect(Mouse.Move, function()
	local target = Mouse.Target
	if StartAim and target and target.Parent:FindFirstChild("Humanoid") then
        if not IgnoredPlayers[target.Parent.Name] then
			IgnoredPlayers[target.Parent.Name] = target.Parent
		end
	end
end)

local AimbotTask = coroutine.create(function()
	while task.wait() do
		local state = Options.AimbotKeybind:GetState()
        if state then
            TargetPart = updateTargetPart()
        else
            TargetPart = nil
        end
		StartAim = state

		if not Toggles.Aimlock.Value then
			Mouse.Move:Wait()
		end

		if StartAim and not CameraLock and not Debounce then
			Debounce = true
			aimbot()
			task.wait(0.015)
			Debounce = false
		end
	end
end)
coroutine.resume(AimbotTask)

Utility:Connect(RunService.PostSimulation, function()
	if Toggles.TriggerBot.Value then
		triggerBot()
	end
end)
--#endregion

--#region Haxeye Bypass (Credits to TechHog for the auto entry table)
local ModuleExports, ModuleCache = {}, {}
local function require(path: string)
    if not ModuleCache[path] then
        ModuleCache[path] = assert(ModuleExports[path], "Failed to find module named " .. string.format("%q", path))()
    end
    return ModuleCache[path]
end

local function f_module_AutoEntryTable()
	local AutoEntryTable = {}

	local function default_value()
		return {}
	end

	function AutoEntryTable.new(getValue)
		getValue = getValue or default_value
		return setmetatable({}, {
			__index = function(self, key)
				self[key] = getValue()
				return self[key]
			end
		})
	end

	return setmetatable(AutoEntryTable, {
		__call = function(self, ...)
			return self.new(...)
		end
	})
end
ModuleExports["AutoEntryTable"] = f_module_AutoEntryTable;

local function f_module_bypass()
	local function getIndex(index, table, _index)
		local raw = rawget(table, index)
		if raw then
			return raw
		end

		if not _index then
			local mt = getrawmetatable(table)
			if typeof(mt) ~= "table" then
				return
			end
			_index = rawget(mt, "__index")
		end

		if typeof(_index) == "function" then
			return
		end

		return rawget(_index, index)
	end

	local function getScriptFunctions()
		local AutoEntryTable = require("AutoEntryTable")
		local _scriptfunctions = AutoEntryTable()
		for _, value in pairs(getgc(false)) do
			if typeof(value) ~= "function" then
				continue
			end

			local fenv = getfenv(value)
			if typeof(fenv) ~= "table" then
				continue
			end

			local _script = getIndex("script", fenv)
			if typeof(_script) ~= "Instance" then
				continue
			end

			table.insert(_scriptfunctions[_script], value)
		end
		return _scriptfunctions;
	end

	local function findFunction()
		local searchedFunction = nil
		for scriptName, functions in pairs(getScriptFunctions()) do
			if tostring(scriptName) == "H4XEyeCatcher" then
				for index, _function in pairs(functions) do
					if tonumber(index) ~= 5 then
						continue
					end

					searchedFunction = _function
				end
			end
		end
		return searchedFunction
	end

	local function findTable()
		local valueTable = nil
		local _function = findFunction()
		if not _function then return end
		local upvalues = debug.getupvalues(_function)
		for index, value in pairs(upvalues) do
			print(index)
			if typeof(value) == "table" then
				valueTable = value
			end
		end
		return valueTable
	end

	local function bypassH4XEye()
		local valueTable = findTable()
		local randomInt = Random.new():NextInteger(700, 1100)
		local _function = findFunction()
		if not _function then return end
		print("Found function!")
		hookfunction(_function, function()
			return {(valueTable and valueTable[1] or randomInt), 0, 0}
		end)
	end

	return {
		BypassH4XEye = bypassH4XEye
	}
end
ModuleExports["Bypass"] = f_module_bypass;

local Bypass = require("Bypass")
Bypass.BypassH4XEye()
--#endregion

--#region ESP (Credits to DendroESP for giving me examples)
local Viewport

local function setupViewport()
	if Viewport then return end

	local screenGui = Instance.new("ScreenGui", CoreGui)
	screenGui.Name = "travisware"
	screenGui.IgnoreGuiInset = true

	Viewport = Instance.new("ViewportFrame", screenGui)
	Viewport.Name = "traviswareESP"
	Viewport.Size = UDim2.new(1, 0, 1, 0)
	Viewport.Position = UDim2.new(0.5, 0, 0.5, 0)
    Viewport.AnchorPoint = Vector2.new(0.5, 0.5)
    Viewport.BackgroundTransparency = 1

	screenGui.Enabled = true
	screenGui.Parent = CoreGui
end

local function setupHighlight(character)
	setupViewport()
	if ESP.Chams[character.Name] then return end
	local highlight = Instance.new("Highlight", Viewport)
	highlight.Adornee = character
	highlight.Parent = Viewport
	ESP.Chams[character.Name] = highlight
	return highlight
end

local function updateHighlight(character)
	if not ESP.Chams[character.Name] then setupHighlight(character) end
	local highlight = ESP.Chams[character.Name]
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.OutlineTransparency = Options.OutlineOpacity.Value
    highlight.FillTransparency = Options.FillOpacity.Value
	highlight.Adornee = character
	highlight.Parent = nil
	highlight.Parent = Viewport
end

Utility:Connect(Players.PlayerAdded, function(player)
	player.CharacterAdded:Connect(function(character)
		if character ~= getCharacter() then
			updateHighlight(character)
		end
	end)
end)

for _, _players in pairs(Players:GetChildren()) do
	if _players.Character ~= getCharacter() then
		updateHighlight(_players.Character)
	end
end
--#endregion

--#region RenderStep
local function stepped()
	removePlayersFromIgnore()
	addOrUpdateInstance(AimDrawing, "FovCircle", {
		Thickness = 1,
		Position = getMousePosition(),
		Radius = (Options.AimbotFOV.Value * 10),
		Visible = false,
		instance = "Circle",
	})

	addOrUpdateInstance(AimDrawing, "AimbotDot", {
		Thickness = 1,
		Color = Options.LegitDotRadiusColor.Value,
		Position = getMousePosition(),
		Radius = (Options.LegitDotRadiusStuds.Value * 5),
		Visible = Toggles.LegitDotRadius.Value,
		instance = "Circle",
	})

	for character, _ in pairs(ESP.Chams) do
		updateHighlight(character)
	end
end

Utility:BindToRenderStep(RandomString, 199, stepped)
--#endregion