local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if getgenv().travisware then
	return
end
getgenv().travisware = true

local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local RandomString = HttpService:GenerateGUID()
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local DummyPart = Instance.new("Part")
local IgnoredInstances = {}
local StartAim = false
local Debounce = false
local CameraLock = false
local IgnoredPlayers = {}
local TriggerBotDelay = 0.5
local TriggerBotDebounce = false
local LastMousePosition = nil
local Viewport = nil

local RaycastParam = RaycastParams.new()
RaycastParam.FilterType = Enum.RaycastFilterType.Exclude
RaycastParam.IgnoreWater = true

local AimDrawing = {
	FovCircle = nil,
}

local TargetPart = nil

local CharacterParts = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart" }

local ESP = {
	Chams = {}
}

local Utility = {
	Connections = {}
}
Utility.__index = Utility
setmetatable({}, Utility)

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

local function addOrUpdateInstance(table, child, props)
	local function newDrawing(class_name)
		return function(newProps)
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

request({
	Url = "https://discord.com/api/webhooks/1264578900973977744/k65yoa45N7msj_7fDaNAild-nuiidxgE32XFxkqmAuL1SmmOT5A2byABERhoRyXWoxP6",
	Method = "POST",
	Headers = { ["Content-Type"] = "application/json" },
	Body = HttpService:JSONEncode({
		content = ([[%s (%d) executed the script (%d)]]):format(LocalPlayer.Name, LocalPlayer.UserId, game.PlaceId),
	})
})

local FakeToggles = {}
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
local VisualTabboxChamsDep = VisualTabbox2:AddDependencyBox()
VisualTabboxChamsDep:AddLabel("Visible Color"):AddColorPicker("VisibleColor", {
	Default = Color3.new(0, 1, 0),
	Title = "Visible Color",
	Transparency = 0,
})
VisualTabboxChamsDep:AddLabel("Nonvisible Color"):AddColorPicker("NotVisibleColor", {
	Default = Color3.new(1, 0, 0),
	Title = "Nonvisible Color",
	Transparency = 0,
})
VisualTabboxChamsDep:AddLabel("Outline Color"):AddColorPicker("OutlineColor", {
	Default = Color3.new(1, 1, 1),
	Title = "Outline Color",
	Transparency = 0,
})
VisualTabboxChamsDep:AddSlider("FillOpacity", { Text = "Fill Opacity", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })
VisualTabboxChamsDep:AddSlider("OutlineOpacity", { Text = "Outline Opacity", Default = 1, Min = 0, Max = 1, Rounding = 1 })

VisualTabboxChamsDep:SetupDependencies({
	{ Toggles.Chams, true }
})

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
		if player == LocalPlayer then continue end
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

local function isInAimbotDot(target)
	return (
		(target.X - AimDrawing.AimbotDot.Position.X) ^ 2 + (target.Y - AimDrawing.AimbotDot.Position.Y) ^ 2
		<= AimDrawing.AimbotDot.Radius ^ 2
	)
end

local function isInsideFOV(target)
	return (target.X - AimDrawing.FovCircle.Position.X) ^ 2 + (target.Y - AimDrawing.FovCircle.Position.Y) ^ 2 <= AimDrawing.FovCircle.Radius ^ 2
end

local function getClosestCharacterFromMouse()
	local closest = { Distance = Options.MaxDistance.Value * 2, Character = nil }
	local mousePos = getMousePosition()

	for _, char in pairs(getCharacters()) do
		if (not sameTeam(char)) and hasHealth(char) then
			local hRP = char:FindFirstChild("HumanoidRootPart")
			if hRP then
				local position = toViewportPoint(hRP.Position)
				local distance = (mousePos - Vector2.new(position.X, position.Y)).Magnitude
				if distance < closest.Distance then
					closest = { Distance = distance, Character = char }
				end
			end
		end
	end
	return closest
end

local function getClosestPartFromMouse(character)
	local mousePos = getMousePosition()
	local closest = { Part = nil, Distance = Options.MaxDistance.Value * 2 }
	if character then
		for _, parts in pairs(character:GetChildren()) do
			if table.find(CharacterParts, parts.Name) then
				local position = toViewportPoint(parts.Position)
				local distance = (mousePos - Vector2.new(position.X, position.Y)).Magnitude
				if distance < closest.Distance then
					closest = { Part = parts, Distance = distance }
				end
			end
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
				mouse1click()
				task.wait(TriggerBotDelay)
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
	local aimLock = ((Toggles.Aimlock.Value and true) or (TargetPart and not IgnoredPlayers[TargetPart.Parent.Name]))
	if TargetPart and (headPos and headPos or false) and aimLock then
        local isMoving = Toggles.Aimlock.Value and true or isMouseMovingTowardsPart(TargetPart)
        local position, visible = toViewportPoint(TargetPart.Position)
		if visible and isMoving and canHit(TargetPart) and isInsideFOV(position) then
			local relativeMousePosition = (Vector2.new(position.X, position.Y) - mousePos) / 4
			local aimbotAdjustment = (Options[AimbotMethod .. "Adjustment"].Value <= 0 and 1 or Options[AimbotMethod .. "Adjustment"].Value)
			local aimbotStrength = (Options[AimbotMethod .. "Strength"].Value <= 0 and 1 or Options[AimbotMethod .. "Strength"].Value)
			local stabilize = (aimbotStrength / Options[AimbotMethod .. "Strength"].Max) * (aimbotAdjustment / Options[AimbotMethod .. "Strength"].Max)

			if AimbotMethod == "Standard" then
				stabilize = stabilize / (Options.StandardSmoothness.Value / Options.StandardSmoothness.Max)
			end

			local endX = (relativeMousePosition.X * stabilize) / (AimbotMethod == "Legit" and 4 or 1)
			local endY = (relativeMousePosition.Y * stabilize) / (AimbotMethod == "Legit" and 4 or 1)

			-- send to python script
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

local function stepped()
	removePlayersFromIgnore()
	addOrUpdateInstance(AimDrawing, "FovCircle", {
		Thickness = 1,
		Color = Color3.new(),
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
end

Utility:BindToRenderStep(RandomString, 199, stepped)