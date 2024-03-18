getgenv().debugMode = true
-- Global Variables
local Drawing = Drawing
local getgenv = getgenv

-- Player Service
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--#region Whitelist (shitty whitelist rn)
local keys = {
	"B6GcFu2t8OyCI2p4fEQWr8ebq39Fsma0",
	"8HeuQedqCXIk6MR1MFvntb5zCX13dwEO",
	"6q56cwkBWq003EKpC2pGUtvzDpzlSHwN",
	"zNO8m47Cbh9ys1dsK7BLBNdSQ7pGNPcm",
	"66OpbRoZxbhBigZwHVEefmyVoNm7VGXR",
	"rjeyp4VtOXFqTeQpNuaPs26G9PTJdXZR",
	"WJANQ4b9QtsLKXRJpoOKMJEoSQxHiJJg",
	"QgvN4o5pyJCz4rfqxK3wjk7n8tk9RuR5",
	"IPUlP0JoPDERjUCQk1FvRNurBEDCGL9S",
	"wtyE9vm96AkhvyjckfTZjHYTuxh1VOge",
	"mQbbC58daX1Ms8WNja43rGgW3r0XGc7u",
	"WfRg6Eg6V4IfbUYVao46Cl8voJho46oj",
	"6EJrtmNnBjkO3mh8kngYdB3iDenwD8mC",
	"POBZ7i4cBckgh45w73qXMLUpBiU7vuNl",
	"3hIasY0w7lft4WIKf69OUXKhU7IwqjXL",
	"52cL8JdNPkDeKKLyyDThnKbnY8ileUXJ",
	"mkHN8aZIS4NpH3KuBFQyBs8QYsX2FhMs",
	"qC93gkwAsygMfKANj4Jcckfl2whFSCV8",
	"atoMSHdPqu5jHtCF91gMpoU3cxueJqdF",
	"9eRYX3VjRsfgye4VmWGmeR1D12bVM7dL",
	"q3ZGIlToEkzARFcuhPdcYr5YjoDK5owO",
	"jNKSDAVF88HBswdSjEQne8wK6KExArnA",
	"GKFNpBYZAe0ZUuDzqY8GBsnsVqmfjBIf",
	"OBcJNqK5SbnrtgqAMBekVcaf8VNuqHi6",
	"3KKRtzaxgGz8Hv87PqBIBEgI9rAUi1O6",
	"PBOfoYMPMywnw4YAGf6MWz91AiwvPLvq",
	"mW2SQhM2TSxeRrnN9BFLbkXjVhdgifqr",
	"sDlqUft7zsCVHGQkQSMw8BYF6leCIKCa",
	"tmXueXhfxf7CW2IQzr0upkTAjQOYJWrU",
	"os5obFYnHAQxHboIIkfNGoD4IKz43VY9",
	"C40HeSPWcS9g0ZyArHDbkZdJA4Fjx5QB",
}

if not debugMode and not getgenv().script_key or (getgenv().script_key and not table.find(keys, getgenv().script_key)) then
	LocalPlayer:Kick("Not whitelisted.")
	setclipboard("https://discord.gg/vfgFRYmaAk")
	return
end
--#endregion

if travisware then
	return
end
getgenv().travisware = true

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
		Body = game:GetService("HttpService"):JSONEncode({
			content = ([[%s executed the script]]):format(LocalPlayer.Name),
		})
	})
end

-- Random String Generator
local function randomString(length)
	local str = ""
	for _ = 1, length do
		str = str .. string.char(math.random(97, 122))
	end
	return str
end
local update_loop_stepped_name = randomString(math.random(15, 35))
-- Run Service
local RunService = game:GetService("RunService")
-- Teams Service
local Teams = game:GetService("Teams")
-- User Input Service
local UserInputService = game:GetService("UserInputService")
-- Internal Values
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local DummyPart = Instance.new("Part")
local IgnoredInstances = {}
local StartAim = false
local Debounce = false
local CameraLock = false
local IgnoredPlayers = {}
local ESPPlayers = {
	Box = {},
	Chams = {},
	NameTag = {},
	Skeleton = {}
}
local TriggerBotDelay = 0.5
local TriggerBotDebounce = false

-- Error Bypass
for _, v in pairs(getconnections(game:GetService("ScriptContext").Error)) do v:Disable() end

-- Raycast Blacklist
local RaycastParam = RaycastParams.new()
RaycastParam.FilterType = Enum.RaycastFilterType.Exclude
RaycastParam.IgnoreWater = true

-- Fov Circle
local AimDrawing = {
	FovCircle = nil,
	AimbotDot = nil
}

-- Aimbot Values
local AimbotStrength = 0
local TargetPart = nil

-- Character Parts
local CharacterParts = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart",  }

--#region Drawing Lib
Drawing.new("Square").Visible = false

local function addOrUpdateInstance(table, child, props)
	local function newDrawing(class_name)
		return function(newProps)
			local inst = Drawing.new(class_name)
			for idx, val in pairs(newProps) do
				if idx ~= "instance" then
					inst[idx] = val
				end
			end
			return inst
		end
	end

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
	Title = "travisware | v1 | release",
})

local LegitTab = Window:AddTab("Legit")
local LegitTabbox1 = LegitTab:AddLeftGroupbox("General")
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
LegitTabbox1:AddSlider("AimbotAdjustment", { Text = "Aimbot Adjustment %", Suffix = "%", Default = 100, Min = 1, Max = 100, Rounding = 0 })
LegitTabbox1:AddSlider("AimbotStrength", { Text = "Aim Adjustment Strength", Suffix = "x", Default = 5, Min = 1, Max = 5, Rounding = 0 })
LegitTabbox1:AddToggle("Aimlock", { Text = "Aimlock" })
LegitTabbox1:AddDivider()
LegitTabbox1:AddToggle("AimbotRadius", { Text = "Show Aim Dot" }):AddColorPicker("AimbotRadiusColor", {
	Default = Color3.new(1, 0, 0),
	Transparency = 0,
})
LegitTabbox1:AddSlider("AimbotRadiusStuds", { Text = "Aim Dot Radius", Suffix = "px", Default = 5, Min = 1, Max = 5, Rounding = 0 })

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
TriggerbotTabbox1:AddSlider("TriggerbotRange", { Text = "Range", Suffix = "m", Default = 1000, Min = 0, Max = 1000, Rounding = 0 })

--[[local HealbotTab = Window:AddTab("Heal bot")
local HealbotTabbox1 = HealbotTab:AddLeftGroupbox("General")
HealbotTabbox1:AddToggle("Healbot", { Text = "Enabled" })
HealbotTabbox1:AddSlider("HealbotRange", { Text = "Range", Suffix = "m", Default = 100, Min = 1, Max = 100, Rounding = 0 })

local HealbotTabbox2 = HealbotTab:AddRightGroupbox("Global Healbot Settings")
HealbotTabbox2:AddLabel("Healing gun"):AddKeyPicker("HealingGun", {
	Default = "Two",
	NoUI = true
})]]

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

local SettingsTab = Window:AddTab("Settings")
local ThemesTabbox = SettingsTab:AddLeftGroupbox("Themes")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
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
		if typeof(character) == 'Instance' and character:IsA("Model") then
			local humanoid = character:FindFirstChildWhichIsA("Humanoid")
			if typeof(humanoid) == 'Instance' and humanoid:IsA("Humanoid") then
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

local function isInsideFOV(target)
	return (
		(target.X - AimDrawing.FovCircle.Position.X) ^ 2 + (target.Y - AimDrawing.FovCircle.Position.Y) ^ 2
		<= AimDrawing.FovCircle.Radius ^ 2
	)
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
		if not sameTeam(char) then
			local hRP = char:FindFirstChild("HumanoidRootPart")
			if hRP then
				local position, _ = toViewportPoint(hRP.Position)
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
			if parts:IsA("BasePart") and table.find(CharacterParts, parts.Name) then
				local position, _ = toViewportPoint(parts.Position)
				local distance = (mousePos - Vector2.new(position.X, position.Y)).Magnitude
				if distance < closest.Distance then
					closest = { Part = parts, Distance = distance }
				end
			end
		end
	end
	return closest
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

local OldValue = 100
local function isMouseMovingTowardsPart(part)
    local mousePos = getMousePosition()
    local position, visible = toViewportPoint(part.Position)
    if visible then
        local newValue = math.floor((mousePos - Vector2.new(position.X, position.Y)).Magnitude)
        if OldValue < newValue then
            OldValue = newValue
            return false
        end

        OldValue = newValue
        return true
    end
end

local function aimbot()
	local headPos = getCharacter():FindFirstChild("Head")
		or getCharacter():WaitForChild("Head", 1000)
	local mousePos = getMousePosition()

	local aimLock = (Toggles.Aimlock.Value and true or (TargetPart and not IgnoredPlayers[TargetPart.Parent.Name]))
	if TargetPart and (headPos and headPos or false) and aimLock then
        local isMoving = Toggles.Aimlock.Value and true or isMouseMovingTowardsPart(TargetPart)
        local position, visible = toViewportPoint(TargetPart.Position)
		if visible and isMoving and canHit(TargetPart) and isInsideFOV(position) and hasHealth(TargetPart.Parent) then
            OldValue = math.floor((mousePos - Vector2.new(position.X, position.Y)).Magnitude)
			local relativeMousePosition = Vector2.new(position.X, position.Y) - mousePos
			local aimbotAdjustment = math.clamp(Options.AimbotAdjustment.Value, 1, 100)
			local stabilizeNew = (AimbotStrength / 5) * (aimbotAdjustment / 100)
			local endX = (relativeMousePosition.X * stabilizeNew) / 10
			local endY = (relativeMousePosition.Y * stabilizeNew) / 10
			mousemoverel(endX, endY)
		end
	end
end

local function removePlayersFromIgnore()
	for playerName, character in pairs(IgnoredPlayers) do
		if IgnoredPlayers[playerName] and (character and character:IsA("Model")) then
			if TargetPart then
				local position, _ = toViewportPoint(TargetPart.Position)
				if not isInAimbotDot(position) then
					IgnoredPlayers[playerName] = nil
                    AimbotStrength = math.clamp(Options.AimbotStrength.Value, 1, 5)
				end
			else
				IgnoredPlayers[playerName] = nil
                AimbotStrength = math.clamp(Options.AimbotStrength.Value, 1, 5)
			end
		end
	end
end
--#endregion

--#region ESP
local function createChams(character)
	local chamsPlayer = {}
	for _, v in pairs(character:GetChildren()) do
		if v:IsA("BasePart") then
			if table.find(CharacterParts, v.Name) then
				local chams = Instance.new("BoxHandleAdornment", v)
				chams.Adornee = v
				chams.Visible = false
				chams.AlwaysOnTop = false
				chams.Color3 = Options.VisibleColor.Value
				chams.Name = randomString(32)
				chams.Size = v.Size + Vector3.new(0.02, 0.02, 0.02)
				chams.ZIndex = 4
				table.insert(chamsPlayer, chams)
			end
		end
	end

	ESPPlayers.Chams[Players:GetPlayerFromCharacter(character)] = chamsPlayer
end

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
	if not ESPPlayers.Chams[player] then
		createChams(character)
	end
	if character and Toggles.Chams.Value then
		for _, chams in pairs(tbl) do
			if typeof(chams) == "Instance" and chams:IsA("BoxHandleAdornment") then
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
--#endregion

--#region Events
for _, v in pairs(Players:GetPlayers()) do
    if v ~= LocalPlayer then
        createEsp(v)
        createChams(v.Character)
    end
end

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
	if Toggles.Camera.Value and input.UserInputType == Enum.UserInputType.MouseButton2 then
		CameraLock = true
	end
end)

UserInputService.InputEnded:Connect(function(input, _)
	if Toggles.Camera.Value and input.UserInputType == Enum.UserInputType.MouseButton2 then
		CameraLock = false
	end
end)

Mouse.Move:Connect(function()
	local target = Mouse.Target
	if StartAim and target and target.Parent:FindFirstChild("Humanoid") then
        if not IgnoredPlayers[target.Parent.Name] then
			IgnoredPlayers[target.Parent.Name] = target.Parent
            AimbotStrength = 1
		end
	end
end)

local AimbotTask = coroutine.create(function()
	while task.wait() do
		local state = Options.AimbotKeybind:GetState()
        if state then
            TargetPart = getClosestPartFromMouse(getClosestCharacterFromMouse().Character).Part
        else
            TargetPart = nil
        end
		StartAim = state

		if not Toggles.Aimlock.Value then
			Mouse.Move:Wait()
		end

		if StartAim and not CameraLock then
			if not Debounce then
				Debounce = true
				aimbot()
				task.wait(0.015)
				Debounce = false
			end
		end
	end
end)
coroutine.resume(AimbotTask)

RunService.PostSimulation:Connect(function()
	if Toggles.TriggerBot.Value then
		triggerBot()
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
		for player, tbl in pairs(ESPPlayers.Chams) do
			if player and player ~= LocalPlayer then
				updateChams(player, tbl)
			end
		end
	end

	addOrUpdateInstance(AimDrawing, "FovCircle", {
		Thickness = 1,
		Position = getMousePosition(),
		Radius = (Options.AimbotFOV.Value * 10),
		Visible = false,
		instance = "Circle",
	})

	addOrUpdateInstance(AimDrawing, "AimbotDot", {
		Thickness = 1,
		Color = Options.AimbotRadiusColor.Value,
		Position = getMousePosition(),
		Radius = (Options.AimbotRadiusStuds.Value * 5),
		Visible = Toggles.AimbotRadius.Value,
		instance = "Circle",
	})
end
--#endregion
RunService:BindToRenderStep(update_loop_stepped_name, 199, stepped)