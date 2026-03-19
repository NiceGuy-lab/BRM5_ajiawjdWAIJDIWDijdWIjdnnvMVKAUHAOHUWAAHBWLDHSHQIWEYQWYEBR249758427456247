local TARGET_FRIENDLY_NAME = "poopfullx"
local MENU_TOGGLE_KEY = Enum.KeyCode.Insert

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local _G_State = {
	MenuVisible = true,
	ESP_Enabled = false,
	ESP_ShowEnemies = true,
	ESP_ShowTeam = true,
	ESP_EnemyColor = Color3.fromRGB(255, 0, 0),
	ESP_TeamColor = Color3.fromRGB(0, 0, 255),
	FPV_ESP_Enabled = false,
	FPV_ShowEnemies = true,
	FPV_ShowTeam = true,
	FPV_EnemyColor = Color3.fromRGB(255, 60, 60),
	FPV_TeamColor = Color3.fromRGB(60, 60, 255),
	Aimbot_Enabled = false,
	Aimbot_Key = Enum.UserInputType.MouseButton2,
	Aimbot_ToggleMode = false,
	Aimbot_TargetPart = "Head",
	Aimbot_TargetEnemies = true,
	Aimbot_TargetTeam = false,
	WarningAccepted = false
}

local ESP_Highlights = {}
local FPV_Highlights = {}
local Connections = {}
local Aimbot_ToggledOn = false

local function IsTeam(player)
	if player.Name == TARGET_FRIENDLY_NAME or player == LocalPlayer then
		return true
	end
	return false
end

local function GetAimPart(character)
	if not character then return nil end
	local partName = _G_State.Aimbot_TargetPart
	if partName == "Torso" then
		return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	end
	return character:FindFirstChild("Head")
end

local function ClearHighlightList(list)
	for obj, hl in pairs(list) do
		if hl then hl:Destroy() end
		list[obj] = nil
	end
end

local function DestroyEverything()
	_G_State.MenuVisible = false
	_G_State.ESP_Enabled = false
	_G_State.FPV_ESP_Enabled = false
	_G_State.Aimbot_Enabled = false
	Aimbot_ToggledOn = false
	
	for name, conn in pairs(Connections) do
		conn:Disconnect()
		Connections[name] = nil
	end
	
	ClearHighlightList(ESP_Highlights)
	ClearHighlightList(FPV_Highlights)
	
	local gui = CoreGui:FindFirstChild("ProjectMenuGui")
	if gui then gui:Destroy() end
	
	script:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProjectMenuGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = CoreGui

local function AddUICorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 5)
	corner.Parent = parent
	return corner
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 350)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
AddUICorner(MainFrame, 8)
MainFrame.Parent = ScreenGui

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 2)
UIPadding.PaddingLeft = UDim.new(0, 2)
UIPadding.PaddingRight = UDim.new(0, 2)
UIPadding.PaddingBottom = UDim.new(0, 2)
UIPadding.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TopBar.BorderSizePixel = 0
AddUICorner(TopBar, 8)
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Project Menu | v1.0 | Internal"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.Parent = TopBar

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, 0, 1, -35)
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(0, 120, 1, 0)
TabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TabBar.BorderSizePixel = 0
AddUICorner(TabBar, 6)
TabBar.Parent = ContentFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 2)
TabListLayout.Parent = TabBar

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 5)
TabPadding.PaddingLeft = UDim.new(0, 5)
TabPadding.PaddingRight = UDim.new(0, 5)
TabPadding.Parent = TabBar

local PagesFolder = Instance.new("Folder")
PagesFolder.Name = "Pages"
PagesFolder.Parent = ContentFrame

local currentPage = nil

local UIUtils = {}

function UIUtils.CreateTab(name, layoutOrder)
	local Button = Instance.new("TextButton")
	Button.Name = name .. "Tab"
	Button.Size = UDim2.new(1, 0, 0, 30)
	Button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	Button.BorderSizePixel = 0
	Button.Text = name
	Button.TextColor3 = Color3.fromRGB(150, 150, 150)
	Button.Font = Enum.Font.Gotham
	Button.TextSize = 13
	Button.LayoutOrder = layoutOrder
	AddUICorner(Button, 4)
	Button.Parent = TabBar
	
	local Page = Instance.new("ScrollingFrame")
	Page.Name = name .. "Page"
	Page.Size = UDim2.new(1, -125, 1, 0)
	Page.Position = UDim2.new(0, 125, 0, 0)
	Page.BackgroundTransparency = 1
	Page.Visible = false
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.ScrollBarThickness = 2
	Page.Parent = PagesFolder
	
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 5)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = Page
	
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingRight = UDim.new(0, 5)
	pad.PaddingTop = UDim.new(0, 5)
	pad.Parent = Page
	
	Button.MouseButton1Click:Connect(function()
		for _, p in pairs(PagesFolder:GetChildren()) do p.Visible = false end
		for _, b in pairs(TabBar:GetChildren()) do 
			if b:IsA("TextButton") then 
				b.TextColor3 = Color3.fromRGB(150, 150, 150) 
				b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end 
		end
		Page.Visible = true
		Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		currentPage = Page
	end)
	
	if layoutOrder == 1 then
		Page.Visible = true
		Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		currentPage = Page
	end
	
	return Page
end

function UIUtils.CreateToggle(parent, text, default, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 30)
	Frame.BackgroundTransparency = 1
	Frame.Parent = parent
	
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -40, 1, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0, 35, 0, 20)
	Button.Position = UDim2.new(1, -35, 0.5, -10)
	Button.BackgroundColor3 = default and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
	Button.Text = ""
	AddUICorner(Button, 10)
	Button.Parent = Frame
	
	local state = default
	Button.MouseButton1Click:Connect(function()
		state = not state
		TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)}):Play()
		callback(state)
	end)
end

function UIUtils.CreateMinitab(parent, text)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 25)
	Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	AddUICorner(Frame, 4)
	Frame.Parent = parent
	
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 1, 0)
	Label.Position = UDim2.new(0, 5, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = ":: " .. text
	Label.TextColor3 = Color3.fromRGB(180, 180, 180)
	Label.Font = Enum.Font.GothamBold
	Label.TextSize = 12
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	
	local Container = Instance.new("Frame")
	Container.Name = text .. "_Container"
	Container.Size = UDim2.new(1, 0, 0, 0)
	Container.AutomaticSize = Enum.AutomaticSize.Y
	Container.BackgroundTransparency = 1
	Container.Parent = parent
	
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 2)
	list.Parent = Container
	
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.Parent = Container
	
	return Container
end

function UIUtils.CreateColorPicker(parent, text, defaultColor, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 50)
	Frame.BackgroundTransparency = 1
	Frame.Parent = parent
	
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0, 100, 0, 20)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = Color3.fromRGB(180, 180, 180)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 12
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	
	local Preview = Instance.new("Frame")
	Preview.Size = UDim2.new(0, 15, 0, 15)
	Preview.Position = UDim2.new(0, 110, 0, 2)
	Preview.BackgroundColor3 = defaultColor
	AddUICorner(Preview, 4)
	Preview.Parent = Frame
	
	local currentR, currentG, currentB = defaultColor.R, defaultColor.G, defaultColor.B
	
	local function createSlider(yPos, colorName, defaultVal, cb)
		local SliderFrame = Instance.new("Frame")
		SliderFrame.Size = UDim2.new(1, -140, 0, 10)
		SliderFrame.Position = UDim2.new(0, 130, 0, yPos)
		SliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		AddUICorner(SliderFrame, 5)
		SliderFrame.Parent = Frame
		
		local Fill = Instance.new("Frame")
		Fill.Size = UDim2.new(defaultVal, 0, 1, 0)
		Fill.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		AddUICorner(Fill, 5)
		Fill.Parent = SliderFrame
		
		local function updateSlider(input)
			local pos = math.clamp((input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
			Fill.Size = UDim2.new(pos, 0, 1, 0)
			cb(pos)
		end
		
		local dragging = false
		SliderFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true updateSlider(input) end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	end
	
	local function updateFinalColor()
		local newCol = Color3.new(currentR, currentG, currentB)
		Preview.BackgroundColor3 = newCol
		callback(newCol)
	end
	
	createSlider(5, "R", currentR, function(v) currentR = v updateFinalColor() end)
	createSlider(20, "G", currentG, function(v) currentG = v updateFinalColor() end)
	createSlider(35, "B", currentB, function(v) currentB = v updateFinalColor() end)
end

function UIUtils.CreateDropdown(parent, text, options, default, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 30)
	Frame.BackgroundTransparency = 1
	Frame.ZIndex = 2
	Frame.Parent = parent
	
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0, 100, 1, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -110, 0, 20)
	Button.Position = UDim2.new(0, 110, 0.5, -10)
	Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Button.Text = default
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.Font = Enum.Font.Gotham
	Button.TextSize = 12
	AddUICorner(Button, 4)
	Button.Parent = Frame
	
	local Droplist = Instance.new("Frame")
	Droplist.Size = UDim2.new(1, 0, 0, #options * 20)
	Droplist.Position = UDim2.new(0, 0, 1, 2)
	Droplist.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	Droplist.Visible = false
	Droplist.ZIndex = 5
	AddUICorner(Droplist, 4)
	Droplist.Parent = Button
	
	local dlist = Instance.new("UIListLayout")
	dlist.Parent = Droplist
	
	for _, opt in pairs(options) do
		local OptBtn = Instance.new("TextButton")
		OptBtn.Size = UDim2.new(1, 0, 0, 20)
		OptBtn.BackgroundTransparency = 1
		OptBtn.Text = opt
		OptBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		OptBtn.Font = Enum.Font.Gotham
		OptBtn.TextSize = 11
		OptBtn.ZIndex = 6
		OptBtn.Parent = Droplist
		
		OptBtn.MouseButton1Click:Connect(function()
			Button.Text = opt
			Droplist.Visible = false
			callback(opt)
		end)
	end
	
	Button.MouseButton1Click:Connect(function()
		Droplist.Visible = not Droplist.Visible
	end)
end

local WarningGui = Instance.new("Frame")
WarningGui.Name = "WarningAimbot"
WarningGui.Size = UDim2.new(0, 400, 0, 200)
WarningGui.Position = UDim2.new(0.5, -200, 0.5, -100)
WarningGui.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
WarningGui.BorderSizePixel = 0
WarningGui.Visible = false
WarningGui.Active = true
WarningGui.Draggable = true
AddUICorner(WarningGui, 10)
WarningGui.Parent = ScreenGui

local WarnTopBar = Instance.new("Frame")
WarnTopBar.Size = UDim2.new(1, 0, 0, 25)
WarnTopBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
WarnTopBar.Parent = WarningGui
AddUICorner(WarnTopBar, 10)

local WarnClose = Instance.new("TextButton")
WarnClose.Size = UDim2.new(0, 25, 0, 25)
WarnClose.Position = UDim2.new(0, 0, 0, 0)
WarnClose.BackgroundTransparency = 1
WarnClose.Text = "X"
WarnClose.TextColor3 = Color3.fromRGB(255, 50, 50)
WarnClose.Font = Enum.Font.GothamBold
WarnClose.TextSize = 16
WarnClose.Parent = WarnTopBar

local WarnTitle = Instance.new("TextLabel")
WarnTitle.Size = UDim2.new(1, -30, 1, 0)
WarnTitle.Position = UDim2.new(0, 30, 0, 0)
WarnTitle.BackgroundTransparency = 1
WarnTitle.Text = "⚠️ AIMBOT USAGE WARNING"
WarnTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
WarnTitle.Font = Enum.Font.GothamBold
WarnTitle.TextSize = 12
WarnTitle.Parent = WarnTopBar

local WarnText = Instance.new("TextLabel")
WarnText.Size = UDim2.new(1, -20, 1, -40)
WarnText.Position = UDim2.new(0, 10, 0, 35)
WarnText.BackgroundTransparency = 1
WarnText.Text = "Before you use aimbot you need to be aware that everytime before using aimbot you need to aim your weapon and only THEN use aimbot till you leave aim but if you use default aimbot button then no worries i guess"
WarnText.TextColor3 = Color3.fromRGB(230, 230, 230)
WarnText.Font = Enum.Font.Gotham
WarnText.TextSize = 13
WarnText.TextWrapped = true
WarnText.TextYAlignment = Enum.TextYAlignment.Top
WarnText.Parent = WarningGui

WarnClose.MouseButton1Click:Connect(function()
	WarningGui.Visible = false
	_G_State.WarningAccepted = true
end)

local MainPage = UIUtils.CreateTab("Main", 1)

UIUtils.CreateToggle(MainPage, "ESP Players (Highlight)", _G_State.ESP_Enabled, function(v)
	_G_State.ESP_Enabled = v
	if not v then ClearHighlightList(ESP_Highlights) end
end)

local espSet = UIUtils.CreateMinitab(MainPage, "ESP Team settings")
UIUtils.CreateToggle(espSet, "Show Enemies", _G_State.ESP_ShowEnemies, function(v) _G_State.ESP_ShowEnemies = v end)
UIUtils.CreateToggle(espSet, "Show Team ("..TARGET_FRIENDLY_NAME..")", _G_State.ESP_ShowTeam, function(v) _G_State.ESP_ShowTeam = v end)
UIUtils.CreateColorPicker(espSet, "Enemy Color", _G_State.ESP_EnemyColor, function(v) _G_State.ESP_EnemyColor = v end)
UIUtils.CreateColorPicker(espSet, "Team Color", _G_State.ESP_TeamColor, function(v) _G_State.ESP_TeamColor = v end)

local spacer = Instance.new("Frame"); spacer.Size = UDim2.new(1,0,0,10); spacer.BackgroundTransparency = 1; spacer.Parent = MainPage

UIUtils.CreateToggle(MainPage, "FPV ESP (ignoreFolder__D)", _G_State.FPV_ESP_Enabled, function(v)
	_G_State.FPV_ESP_Enabled = v
	if not v then ClearHighlightList(FPV_Highlights) end
end)

local fpvSet = UIUtils.CreateMinitab(MainPage, "F-ESP Team settings")
UIUtils.CreateColorPicker(fpvSet, "Object Highlight Color", _G_State.FPV_EnemyColor, function(v) _G_State.FPV_EnemyColor = v end)

local spacer2 = Instance.new("Frame"); spacer2.Size = UDim2.new(1,0,0,10); spacer2.BackgroundTransparency = 1; spacer2.Parent = MainPage

UIUtils.CreateToggle(MainPage, "AIMBOT", _G_State.Aimbot_Enabled, function(v)
	_G_State.Aimbot_Enabled = v
	if v and not _G_State.WarningAccepted then
		WarningGui.Visible = true
	elseif not v then
		WarningGui.Visible = false
		Aimbot_ToggledOn = false
	end
end)

local aimSet = UIUtils.CreateMinitab(MainPage, "AIMBOT Settings")

UIUtils.CreateDropdown(aimSet, "Aim Key", {"RightMouse", "LeftMouse"}, "RightMouse", function(v)
	if v == "RightMouse" then _G_State.Aimbot_Key = Enum.UserInputType.MouseButton2
	else _G_State.Aimbot_Key = Enum.UserInputType.MouseButton1 end
end)

UIUtils.CreateDropdown(aimSet, "Aim Mode", {"Hold", "Toggle"}, "Hold", function(v)
	_G_State.Aimbot_ToggleMode = (v == "Toggle")
	Aimbot_ToggledOn = false
end)

UIUtils.CreateDropdown(aimSet, "Target Part", {"Head", "Torso"}, "Head", function(v)
	_G_State.Aimbot_TargetPart = v
end)

UIUtils.CreateToggle(aimSet, "Target Enemies", _G_State.Aimbot_TargetEnemies, function(v) _G_State.Aimbot_TargetEnemies = v end)
UIUtils.CreateToggle(aimSet, "Target Team", _G_State.Aimbot_TargetTeam, function(v) _G_State.Aimbot_TargetTeam = v end)

local function ApplyHighlight(obj, isPlayerESP, isFriendly)
	local storage = isPlayerESP and ESP_Highlights or FPV_Highlights
	local hl = storage[obj]
	
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "ProjectHL"
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.Parent = CoreGui
		storage[obj] = hl
	end
	
	if isPlayerESP then
		if isFriendly then
			hl.FillColor = _G_State.ESP_TeamColor
			hl.OutlineColor = Color3.new(1,1,1)
			hl.Enabled = _G_State.ESP_ShowTeam
		else
			hl.FillColor = _G_State.ESP_EnemyColor
			hl.OutlineColor = Color3.new(0,0,0)
			hl.Enabled = _G_State.ESP_ShowEnemies
		end
	else
		hl.FillColor = _G_State.FPV_EnemyColor
		hl.OutlineColor = Color3.new(1,1,1)
		hl.Enabled = true
	end
	
	if not obj.Parent then
		hl:Destroy()
		storage[obj] = nil
	end
end

Connections.ESP_Loop = RunService.Heartbeat:Connect(function()
	if _G_State.ESP_Enabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				ApplyHighlight(player.Character, true, IsTeam(player))
			end
		end
		
		for char, hl in pairs(ESP_Highlights) do
			if not char.Parent or not char:FindFirstChild("HumanoidRootPart") then
				hl:Destroy()
				ESP_Highlights[char] = nil
			end
		end
	end
	
	if _G_State.FPV_ESP_Enabled then
		local ignoreFolder = Workspace:FindFirstChild("ignoreFolder__D")
		if ignoreFolder then
			for _, obj in pairs(ignoreFolder:GetChildren()) do
				if obj:IsA("Model") or obj:IsA("BasePart") then
					ApplyHighlight(obj, false, false)
				end
			end
		end
		for obj, hl in pairs(FPV_Highlights) do
			if not obj.Parent then
				hl:Destroy()
				FPV_Highlights[obj] = nil
			end
		end
	end
end)

local function GetClosestTarget()
	local closestDist = math.huge
	local targetChar = nil
	local targetPart = nil
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			
			local isFriendly = IsTeam(player)
			
			local canTarget = false
			if isFriendly and _G_State.Aimbot_TargetTeam then canTarget = true end
			if not isFriendly and _G_State.Aimbot_TargetEnemies then canTarget = true end
			
			if canTarget then
				local part = GetAimPart(player.Character)
				if part then
					local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
					
					if onScreen then
						local mousePos = Vector2.new(Mouse.X, Mouse.Y)
						local partPos2D = Vector2.new(pos.X, pos.Y)
						local dist = (mousePos - partPos2D).Magnitude
						
						if dist < closestDist then
							closestDist = dist
							targetChar = player.Character
							targetPart = part
						end
					end
				end
			end
		end
	end
	return targetPart
end

local aimbotActive = false

Connections.AimInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not _G_State.Aimbot_Enabled or not _G_State.WarningAccepted then return end
	
	if input.UserInputType == _G_State.Aimbot_Key or input.KeyCode == _G_State.Aimbot_Key then
		if _G_State.Aimbot_ToggleMode then
			Aimbot_ToggledOn = not Aimbot_ToggledOn
			aimbotActive = Aimbot_ToggledOn
		else
			aimbotActive = true
		end
	end
end)

Connections.AimInputEnded = UserInputService.InputEnded:Connect(function(input)
	if not _G_State.Aimbot_Enabled then return end
	if _G_State.Aimbot_ToggleMode then return end
	
	if input.UserInputType == _G_State.Aimbot_Key or input.KeyCode == _G_State.Aimbot_Key then
		aimbotActive = false
	end
end)

Connections.Aimbot_Loop = RunService.RenderStepped:Connect(function()
	if _G_State.Aimbot_Enabled and _G_State.WarningAccepted and aimbotActive then
		local targetPart = GetClosestTarget()
		if targetPart then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
		end
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	DestroyEverything()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == MENU_TOGGLE_KEY then
		_G_State.MenuVisible = not _G_State.MenuVisible
		MainFrame.Visible = _G_State.MenuVisible
	end
end)