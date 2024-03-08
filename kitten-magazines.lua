if not game:IsLoaded() then
	game.Loaded:Wait()
end

if swagware then
	return
end

--[[
	TODO:
		Add cursor offset if toggled
		Add chams
		Heal bot (Advanced, with different configs for bases etc.)

		-- internal
		Using the smooth value to calculate how long it needs to wait (Aimbot)
		Change the trigger bot method, if we don't like it
		BIG MAYBE, bypass anti alt / complete bypass h4xeye
]]

-- globals
local Drawing = Drawing
local getgenv = getgenv

-- setting up random generator
math.randomseed(tick())
local function randomString(length: number)
	local str = ""
	for _ = 1, length do
		str = str .. string.char(math.random(97, 122))
	end
	return str
end

-- globals
getgenv().update_loop_stepped_name = randomString(math.random(15, 35))
getgenv().swagware = true

-- services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- values
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local DummyPart = Instance.new("Part")
local IgnoredInstances = {}
local StartAim = false
local Debounce = false
local CameraLock = false
local IgnoredPlayers = {}
local Gun = false
local Healgun = false
-- TODO: Combine one esplayer and add box etc. to it
local ESPPlayers = {
	Box = {},
	Chams = {}
}
local TriggerBotDelay = 0.5
local TriggerBotDebounce = false

-- error bypass
for _, v in pairs(getconnections(game:GetService("ScriptContext").Error)) do v:Disable() end

-- raycast
local RaycastParam = RaycastParams.new()
RaycastParam.FilterType = Enum.RaycastFilterType.Exclude
RaycastParam.IgnoreWater = true

-- drawing lib objects
local AimDrawing = {
	FovCircle = nil
}

-- character parts
local CharacterParts = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart" }

-- init drawing lib
Drawing.new("Square").Visible = false

--#region Drawing Lib
local function newDrawing(class_name)
	return function(props)
		local inst = Drawing.new(class_name)
		for idx, val in pairs(props) do
			if idx ~= "instance" then
				inst[idx] = val
			end
		end
		return inst
	end
end

local function addOrUpdateInstance(table, child, props)
	local inst = table[child]
	if not inst then
		table[child] = newDrawing(props.instance)(props)
		return inst
	end

	for idx, val in pairs(props) do
		if idx ~= "instance" then
			inst[idx] = val
		end
	end

	return inst
end
--#endregion

--#region UI
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/brodaniell/iniuria/main/SaveManager.lua"))()

local Window = Library:CreateWindow({
	Title = "swagware | v1 | release",
})

local LegitTab = Window:AddTab("Legit")
local LegitTabbox1 = LegitTab:AddLeftGroupbox("General")
LegitTabbox1:AddSlider(
	"MaxDistance",
	{ Text = "Max Distance", Suffix = "m", Default = 5000, Min = 0, Max = 5000, Rounding = 0 }
)
LegitTabbox1:AddSlider(
	"AimbotFOV",
	{ Text = "Aimbot FOV", Suffix = "m", Default = 10, Min = 0, Max = 10, Rounding = 0 }
)
LegitTabbox1:AddDivider()
LegitTabbox1:AddSlider("AimbotAdj", { Text = "Aim Adjustment", Default = 5, Min = 1, Max = 10, Rounding = 0 })
LegitTabbox1:AddSlider(
	"AimbotAdjStr",
	{ Text = "Aim Adjustment Strength", Suffix = "x", Default = 5, Min = 0, Max = 5, Rounding = 0 }
)
LegitTabbox1:AddSlider("AimbotDebug", { Text = "Smoothness", Suffix = "%", Default = 100, Min = 1, Max = 100, Rounding = 0 })
LegitTabbox1:AddToggle("Aimlock", { Text = "Aimlock" })

local LegitTabbox2 = LegitTab:AddRightGroupbox("Global Aimbot Settings")
LegitTabbox2:AddToggle("VCheck", { Text = "Visibility Check" })
LegitTabbox2:AddToggle("TCheck", { Text = "Team Check" })
LegitTabbox2:AddToggle("Camera", { Text = "Disable when using Camera" })

local TriggerbotTab = Window:AddTab("Trigger Bot")
local TriggerbotTabbox1 = TriggerbotTab:AddLeftGroupbox("General")
TriggerbotTabbox1:AddToggle("TriggerBot", { Text = "Enabled" })
TriggerbotTabbox1:AddInput("MyTextbox", {
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
TriggerbotTabbox1:AddSlider("TriggerbotRange", { Text = "Range", Suffix = "m", Default = 5000, Min = 0, Max = 5000, Rounding = 0 })

local HealbotTab = Window:AddTab("Heal bot")
local HealbotTabbox1 = HealbotTab:AddLeftGroupbox("General")
HealbotTabbox1:AddToggle("Healbot", { Text = "Enabled" })
HealbotTabbox1:AddSlider("HealbotRange", { Text = "Range", Suffix = "m", Default = 100, Min = 1, Max = 100, Rounding = 0 })

local HealbotTabbox2 = HealbotTab:AddRightGroupbox("Global Healbot Settings")
HealbotTabbox2:AddLabel("Healing gun"):AddKeyPicker("HealingGun", {
	Default = "Two",
	NoUI = true
})

local VisualTab = Window:AddTab("Visual")
local VisualTabbox1 = VisualTab:AddLeftGroupbox("General")
VisualTabbox1:AddToggle("ESP", {
	Text = "ESP enabled",
})
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

local FunTab = Window:AddTab("Fun")
local FunTabbox1 = FunTab:AddLeftGroupbox("General")
FunTabbox1:AddToggle("Spinbot", {
	Text = "Enables the spinbot"
})

local SettingsTab = Window:AddTab("Settings")
local ThemesTabbox = SettingsTab:AddLeftGroupbox("Themes")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("swagware")
SaveManager:SetFolder("swagware")
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
	--if not character then return nil end
	return character
end

local function getMousePosition()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local mouse = playerGui and playerGui:FindFirstChild("Mouse")
	local mouseOrigin: Frame = mouse and mouse:FindFirstChild("MouseOrigin")
	if mouseOrigin then
		return Vector2.new(mouseOrigin.AbsolutePosition.X, mouseOrigin.AbsolutePosition.Y + 56)
	end
	return UserInputService:GetMouseLocation()
end

local function toViewportPoint(v3: Vector3)
	local screenPos, visible = Camera:WorldToViewportPoint(v3)
	return Vector3.new(screenPos.X, screenPos.Y, screenPos.Z), visible
end

local function getCharacters()
	local characters = {}
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if typeof(character) == 'Instance' and character:IsA("Model") then
			local humanoid = character:FindFirstChildWhichIsA("Humanoid")
			if typeof(humanoid) == 'Instance' and humanoid:IsA("Humanoid") then
				table.insert(characters, character)
			end
		end
	end
	return characters
end

-- TODO: Rewrite it, so the cursor needs to see it
local function canHit(target: Part)
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
		if target and target.Team == LocalPlayer.Team then
			return true
		end
	end
	return false
end

local function hasHealth(character)
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if character and humanoid then
		if humanoid.Health > 0 then
			return true
		end
	end
	return false
end

local function hasEnoughHealth(character)
	if not character then
		return false
	end

	local humanoid: Humanoid = character:FindFirstChildOfClass("Humanoid")
	if character and humanoid then
		if humanoid.Health > 0 and humanoid.Health < 100 then
			return true
		end
	end

	return false
end

local function isInsideFOV(target)
	return (
		(target.X - AimDrawing.FovCircle.Position.X) ^ 2 + (target.Y - AimDrawing.FovCircle.Position.Y) ^ 2
		<= AimDrawing.FovCircle.Radius ^ 2
	)
end

local function getClosestObjectFromMouse()
	local closest = { Distance = Options.MaxDistance.Value * 2, Character = nil }
	local mousePos = getMousePosition()

	for _, char in pairs(getCharacters()) do
		if sameTeam(char) then
			continue
		end
		local hRP = char:FindFirstChild("HumanoidRootPart")
		if hRP then
			local position, _ = toViewportPoint(hRP.Position)
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
			if not table.find(CharacterParts, parts.Name) then
				continue
			end
			local position, _ = toViewportPoint(parts.Position)
			local distance = (mousePos - Vector2.new(position.X, position.Y)).Magnitude
			if distance > closest.Distance then
				continue
			end
			closest = { Part = parts, Distance = distance }
		end
	end
	return closest
end

local function triggerBot()
	if Mouse.Target then
		local target = Mouse.Target
		if target and target.Parent:FindFirstChild("Humanoid") then
			local character = target.Parent
			if hasHealth(character) and not sameTeam(character) and not TriggerBotDebounce then
				TriggerBotDebounce = true
				mouse1click()
				task.wait(TriggerBotDelay)
				TriggerBotDebounce = false
			end
		end
	end
end

local function aimbot()
	local target = getClosestObjectFromMouse().Character
	local closestHitbox = getClosestPartFromMouse(target)
	local headPos = getCharacter():FindFirstChild("Head")
		or getCharacter():WaitForChild("Head", 1000)
	local mousePos = getMousePosition()
	local aimLock = (Toggles.Aimlock.Value and true or (not IgnoredPlayers[target.Name]))
	if target and (headPos and headPos or false) and (closestHitbox and closestHitbox.Part or false) and aimLock then
		local position, visible = toViewportPoint(closestHitbox.Part.Position)
		if visible and canHit(closestHitbox.Part) and isInsideFOV(position) then
			if hasHealth(target) and not sameTeam(target) then
				--[[
					relativeMousePosition: How far the mouse needs to travel to hit the position
					aimbotStrength: Value to calculate how strong your mouse travels to the position (Skipping steps)
					aimbotAdjustment: Value to calculate how fast your mouse travels
					aimbotDebug: Value to calculate how smooth your mouse travels towards the position (1 - 100)
					stabilize: End value to mulitplicate with the relativeMousePosition (The lower the value is the smoother it goes towards the position)
				]]
				local relativeMousePosition = Vector2.new(position.X, position.Y) - mousePos
				local aimbotStrength = math.clamp(Options.AimbotAdjStr.Value, 1, 5)
				local aimbotAdjustment = math.clamp(Options.AimbotAdj.Value, 1, 10)
				local aimbotDebug = math.clamp(Options.AimbotDebug.Value, 1, 100)
				local stabilize = aimbotStrength * (1 + (aimbotAdjustment / 100))
				local endX = (relativeMousePosition.X * stabilize) / aimbotDebug
				local endY = (relativeMousePosition.Y * stabilize) / aimbotDebug
				mousemoverel(endX, endY)
			end
		end
	end
end

local function removePlayersFromIgnore()
	for playerName, character in pairs(IgnoredPlayers) do
		if IgnoredPlayers[playerName] and (character and character:IsA("Model")) then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local position, _ = toViewportPoint(hrp.Position)
				if not isInsideFOV(position) then
					IgnoredPlayers[playerName] = nil
				end
			else
				IgnoredPlayers[playerName] = nil
			end
		else
			IgnoredPlayers[playerName] = nil
		end
	end
end
--#endregion

--#region Healbot
local function getNearestPlayer(player: Player)
	local closest = { Character = nil, Distance = Options.HealbotRange.Value }
	local localCharacter = getCharacter(player)
	for _, v in pairs(Players:GetPlayers()) do
		if v == player then continue end
		local character = v.Character
		local distance = (localCharacter.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
		if distance > closest.Distance then
			continue
		end
		closest = { Character = character, Distance = distance }
	end
	return closest
end

local function healBot()
	local nearestPlayer = getNearestPlayer(LocalPlayer).Character
	local keyCode = Options.HealingGun.Value
	if not StartAim then
		if not Healgun then
			Healgun = true
			keyclick(Enum.KeyCode[keyCode].Value)
		end

		if nearestPlayer and hasEnoughHealth(nearestPlayer) then
			mouse1press()
		end
	else
		Healgun = false
		if not Gun then
			Gun = true
			keyclick(Enum.KeyCode.One.Value)
		end
	end
end
--#endregion

--#region ESP
local function createEsp(player)
   	local drawings = {Box = nil, Outline = nil}

   	addOrUpdateInstance(drawings, "Box", {
		Thickness = 1,
		Filled = false,
		Color = Options.VisibleColor.Value,
		Visible = false,
		ZIndex = 2,
		instance = "Square",
	})

	addOrUpdateInstance(drawings, "Outline", {
		Thickness = 3,
		Filled = false,
		Color = Color3.new(),
		Visible = false,
		ZIndex = 1,
		instance = "Square",
	})

   	ESPPlayers.Box[player] = drawings
end

local function createChams(character)
	local chamsPlayer = {}
	if not (character or character:IsA("Model") or character:FindFirstChildOfClass("Humanoid")) then return end
	for _, v in pairs(character:GetChildren()) do
		if v:IsA("BasePart") and v.Parent:FindFirstChildOfClass("Humanoid") then
			if not table.find(CharacterParts, v.Name) then
				continue
			end

			local chams: BoxHandleAdornment = Instance.new("BoxHandleAdornment", v)
			chams.Adornee = v
			chams.Visible = false
			chams.AlwaysOnTop = false
			chams.Color3 = Options.VisibleColor.Value
			chams.Name = randomString(15)
			chams.Size = v.Size + Vector3.new(0.02, 0.02, 0.02)
			chams.ZIndex = 4
			table.insert(chamsPlayer, chams)
		end
	end

	ESPPlayers.Chams[Players:GetPlayerFromCharacter(character)] = chamsPlayer
end

local function removeEsp(player)
	if rawget(ESPPlayers.Box, player) then
		if ESPPlayers.Box[player] then
			for _, drawing in pairs(ESPPlayers.Box[player]) do
				drawing:Destroy()
			end
		end
		ESPPlayers.Box[player] = nil
	end
end

local function removeChams(player)
	if rawget(ESPPlayers.Chams, player) then
		if ESPPlayers.Chams[player] then
			for _, v in pairs(ESPPlayers.Chams[player]) do
				v:Destroy()
			end
		end
		ESPPlayers.Chams[player] = nil
	end
end

local function updateEsp(player, esp)
	local character = player and player.Character
	local tan, rad = math.tan, math.rad
	local function round(...)
		local rounding = {}

		for i, v in pairs(table.pack(...)) do
			rounding[i] = math.round(v)
		end

		return unpack(rounding)
	end

	if character then
		if Toggles.Box.Value then
			if sameTeam(character) then
				if esp.Box.Visible then
					esp.Box.Visible = false
					esp.Outline.Visible = false
				end
				return
			end

			local cFrame = character:GetModelCFrame()
			local isAlive = hasHealth(character)
			local position, visible = toViewportPoint(cFrame.Position)
			local toggle = Toggles.ESP.Value and Toggles.Box.Value or false
			local playerHead = getCharacter():FindFirstChild("Head") or getCharacter():WaitForChild("Head", 1000)
			local characterHead = character:FindFirstChild("Head") or character:WaitForChild("Head", 1000)
			local camView = Camera and Camera.FieldOfView or 70
			local canSee = nil
			if playerHead and characterHead then
				canSee = canHit(characterHead)
			end

			esp.Box.Visible = (visible and toggle or false)
			esp.Outline.Visible = (visible and toggle or false)

			if cFrame and isAlive and toggle then
				local depth = position.Z
				local scaleFactor = 1 / (depth * tan(rad(camView / 2)) * 2) * 1000
				local width, height = round(4 * scaleFactor, 5 * scaleFactor)
				local x, y = round(position.X, position.Y)
				esp.Box.Size = Vector2.new(width, height)
				esp.Box.Position = Vector2.new(round(x - width / 2, y - height / 2))
				if canSee ~= nil then
					esp.Box.Color = (canSee and Options.VisibleColor.Value or Options.NotVisibleColor.Value)
				else
					esp.Box.Color = Options.VisibleColor.Value
				end
				esp.Box.Transparency = Options.FillOpacity.Value
				esp.Outline.Transparency = Options.OutlineOpacity.Value
				esp.Outline.Size = esp.Box.Size
				esp.Outline.Position = esp.Box.Position
			else
				esp.Box.Visible = false
				esp.Outline.Visible = false
			end
		else
			esp.Box.Visible = false
			esp.Outline.Visible = false
		end
	end
end

local function updateChams(player, tbl)
	local character = player and player.Character
	if not character then return end
	if Toggles.Chams.Value then
		for _, v in pairs(tbl) do
			if typeof(v) == "Instance" and v:IsA("BoxHandleAdornment") then
				local chams :BoxHandleAdornment = v
				if sameTeam(character) then
					if chams.Visible then
						chams.Visible = false
					end
					continue
				end
				
				local cFrame = character:GetModelCFrame()
				local _, visible = toViewportPoint(cFrame.Position)
				local isAlive = hasHealth(character)
				local playerHead = getCharacter():FindFirstChild("Head") or getCharacter():WaitForChild("Head", 1000)
				local characterHead = character:FindFirstChild("Head") or character:WaitForChild("Head", 1000)
				local canSee = nil
				if playerHead and characterHead then
					canSee = canHit(characterHead)
				end
				local toggle = Toggles.ESP.Value and Toggles.Chams.Value or false
				chams.Visible = (visible and toggle or false)
				if isAlive and toggle then
					if canSee ~= nil then
						chams.Color3 = (canSee and Options.VisibleColor.Value or Options.NotVisibleColor.Value)
					else
						chams.Color3 = Options.VisibleColor.Value
					end
					chams.Transparency = Options.FillOpacity.Value
				else
					chams.Visible = false
				end
			end
		end
	else
		for _, v in pairs(tbl) do
			v.Visible = false
		end
	end
end

for _, player in pairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		createEsp(player)
		createChams(player.Character)
	end
end
--#endregion

--#region Bypass
--#endregion

--#region Events
Players.PlayerAdded:Connect(function(player)
	createEsp(player)
	player.CharacterAdded:Connect(function(character)
		createChams(character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	removeEsp(player)
	removeChams(player)
end)

UserInputService.InputBegan:Connect(function(input, _)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not StartAim then
		StartAim = true
	end

	if Toggles.Camera.Value and input.UserInputType == Enum.UserInputType.MouseButton2 then
		CameraLock = true
	end
end)

UserInputService.InputEnded:Connect(function(input, _)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and StartAim then
		StartAim = false
	end

	if Toggles.Camera.Value and input.UserInputType == Enum.UserInputType.MouseButton2 then
		CameraLock = false
	end
end)

Mouse.Move:Connect(function()
	local target = Mouse.Target
	if StartAim and target and target.Parent:FindFirstChild("Humanoid") then
		if not IgnoredPlayers[target.Parent.Name] then
			IgnoredPlayers[target.Parent.Name] = target.Parent
		end
	end
end)

RunService.PostSimulation:Connect(function(_)
	if Toggles.TriggerBot.Value then
		triggerBot()
	end

	--[[if Toggles.Healbot.Value then
		healBot()
	end]]

	local waiting = (Toggles.Aimlock.Value and true) or (Mouse.Move:Wait())
	if waiting and StartAim and not CameraLock then
		if not Debounce then
			Debounce = true
			aimbot()
			task.wait(0.015)
			Debounce = false
		end
	end
end)
--#endregion

--#region RenderStep
local function stepped()
	removePlayersFromIgnore()
	if ESPPlayers.Box then
		for player, drawings in pairs(ESPPlayers.Box) do
			if player and player ~= LocalPlayer then
				updateEsp(player, drawings)
			end
		end
	end

	if ESPPlayers.Chams then
		for player, chams in pairs(ESPPlayers.Chams) do
			if player and player ~= LocalPlayer then
				updateChams(player, chams)
			end
		end
	end

	addOrUpdateInstance(AimDrawing, "FovCircle", {
		Thickness = 1,
		Position = getMousePosition(),
		Radius = (Options.AimbotFOV.Value * 5),
		Visible = false,
		instance = "Circle",
	})
end
--#endregion
RunService:BindToRenderStep(update_loop_stepped_name, 199, stepped)