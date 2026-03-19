local MENU_TITLE = "BlackHawk RM: 5"
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
	ESP_Players_Enabled = false,
	ESP_PlayerColor = Color3.fromRGB(0, 170, 255),
	ESP_NPCs_Enabled = false,
	ESP_NPCColor = Color3.fromRGB(255, 50, 50),
	Aimbot_Enabled = false,
	Aimbot_Key = Enum.UserInputType.MouseButton2,
	Aimbot_ToggleMode = false,
	Aimbot_TargetPart = "Head",
	Aimbot_TargetPlayers = false,
	Aimbot_TargetNPCs = true,
	Aimbot_Crosshair = nil,
	Aimbot_Smoothness = 0.5,
	AutoReload = true,
	Calibrating = false,
	WarningAccepted = false
}

local ESP_Player_Highlights = {}
local ESP_NPC_Highlights = {}
local Connections = {}
local Aimbot_ToggledOn = false
local CalibrateBtnRef = nil

local CachedNPCs = {}
local LastNPCCheck = 0

local function ScanEntities()
	local newNPCs = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= LocalPlayer.Character then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local head = obj:FindFirstChild("Head")
				local root = obj:FindFirstChild("HumanoidRootPart")
				local torso = obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("Torso")
				
				if head and root and torso then
					if not Players:GetPlayerFromCharacter(obj) then
						newNPCs[obj] = true
					end
				end
			end
		end
	end
	CachedNPCs = newNPCs
	LastNPCCheck = tick()
end

task.spawn(ScanEntities)

local function GetAnyPart(obj)
	if not obj then return nil end
	return obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("Torso") or obj:FindFirstChild("Head")
end

local function GetAimPart(character)
	if not character then return nil end
	local partName = _G_State.Aimbot_TargetPart
	if partName == "Torso" then
		return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
	end
	return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function ClearHighlightList(list)
	for obj, hl in pairs(list) do
		if hl then hl:Destroy() end
		list[obj] = nil
	end
end

local function DestroyEverything()
	_G_State.MenuVisible = false
	_G_State.ESP_Players_Enabled = false
	_G_State.ESP_NPCs_Enabled = false
	_G_State.Aimbot_Enabled = false
	Aimbot_ToggledOn = false
	
	for name, conn in pairs(Connections) do
		conn:Disconnect()
		Connections[name] = nil
	end
	
	ClearHighlightList(ESP_Player_Highlights)
	ClearHighlightList(ESP_NPC_Highlights)
	
	local targetUIFolder = (type(gethui) == "function" and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
	local gui = targetUIFolder:FindFirstChild("ProjectMenuGui")
	if gui then gui:Destroy() end
end

local targetUIFolder = (type(gethui) == "function" and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProjectMenuGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = targetUIFolder

local CrosshairDot = Instance.new("Frame")
CrosshairDot.Name = "CustomCrosshair"
CrosshairDot.Size = UDim2.new(0, 4, 0, 4)
CrosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CrosshairDot.BorderSizePixel = 0
CrosshairDot.Visible = false
CrosshairDot.ZIndex = 9999999
local CHDCorner = Instance.new("UICorner")
CHDCorner.CornerRadius = UDim.new(1, 0)
CHDCorner.Parent = CrosshairDot
CrosshairDot.Parent = ScreenGui

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

local draggingMenu = false
local dragStartPos
local startFramePos

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingMenu = true
		dragStartPos = input.Position
		startFramePos = MainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingMenu and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStartPos
		MainFrame.Position = UDim2.new(
			startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
			startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingMenu = false
	end
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = MENU_TITLE
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
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.ScrollBarThickness = 4
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

function UIUtils.CreateButton(parent, text, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 30)
	Frame.BackgroundTransparency = 1
	Frame.Parent = parent
	
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 1, -4)
	Button.Position = UDim2.new(0, 0, 0, 2)
	Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Button.Text = text
	Button.TextColor3 = Color3.fromRGB(200, 200, 200)
	Button.Font = Enum.Font.Gotham
	Button.TextSize = 13
	AddUICorner(Button, 4)
	Button.Parent = Frame
	
	Button.MouseButton1Click:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
		callback()
		task.wait(0.1)
		TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
	end)
	
	return Button
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

function UIUtils.CreateSlider(parent, text, min, max, defaultVal, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 45)
	Frame.BackgroundTransparency = 1
	Frame.Parent = parent
	
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -10, 0, 20)
	Label.Position = UDim2.new(0, 5, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text .. ": " .. tostring(defaultVal)
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	
	local SliderBg = Instance.new("Frame")
	SliderBg.Size = UDim2.new(1, -10, 0, 12)
	SliderBg.Position = UDim2.new(0, 5, 0, 25)
	SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	AddUICorner(SliderBg, 6)
	SliderBg.Parent = Frame
	
	local Fill = Instance.new("Frame")
	local defPct = math.clamp((defaultVal - min) / (max - min), 0, 1)
	Fill.Size = UDim2.new(defPct, 0, 1, 0)
	Fill.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	AddUICorner(Fill, 6)
	Fill.Parent = SliderBg
	
	local dragging = false
	
	local function updateSlider(input)
		local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
		Fill.Size = UDim2.new(pos, 0, 1, 0)
		local val = min + (max - min) * pos
		val = math.floor(val * 10) / 10
		Label.Text = text .. ": " .. tostring(val)
		callback(val)
	end
	
	SliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateSlider(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

function UIUtils.CreateMinitab(parent, text)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 0, 25)
	Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	AddUICorner(Frame, 4)
	Frame.Parent = parent
	
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 1, 0)
	Button.Position = UDim2.new(0, 5, 0, 0)
	Button.BackgroundTransparency = 1
	Button.Text = "[+]  " .. text
	Button.TextColor3 = Color3.fromRGB(180, 180, 180)
	Button.Font = Enum.Font.GothamBold
	Button.TextSize = 12
	Button.TextXAlignment = Enum.TextXAlignment.Left
	Button.Parent = Frame
	
	local Container = Instance.new("Frame")
	Container.Name = text .. "_Container"
	Container.Size = UDim2.new(1, 0, 0, 0)
	Container.AutomaticSize = Enum.AutomaticSize.Y
	Container.BackgroundTransparency = 1
	Container.Visible = false
	Container.Parent = parent
	
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 2)
	list.Parent = Container
	
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.Parent = Container
	
	local expanded = false
	Button.MouseButton1Click:Connect(function()
		expanded = not expanded
		Container.Visible = expanded
		if expanded then
			Button.Text = "[-]  " .. text
		else
			Button.Text = "[+]  " .. text
		end
	end)
	
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
	
	local function createSliderLocal(yPos, colorName, defaultVal, cb)
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
	
	createSliderLocal(5, "R", currentR, function(v) currentR = v updateFinalColor() end)
	createSliderLocal(20, "G", currentG, function(v) currentG = v updateFinalColor() end)
	createSliderLocal(35, "B", currentB, function(v) currentB = v updateFinalColor() end)
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

UIUtils.CreateToggle(MainPage, "ESP Players", _G_State.ESP_Players_Enabled, function(v)
	_G_State.ESP_Players_Enabled = v
	if not v then
		for char, hl in pairs(ESP_Player_Highlights) do
			hl:Destroy()
			ESP_Player_Highlights[char] = nil
		end
	end
end)

local espPlayerSet = UIUtils.CreateMinitab(MainPage, "Player ESP Settings")
UIUtils.CreateColorPicker(espPlayerSet, "Player Color", _G_State.ESP_PlayerColor, function(v) _G_State.ESP_PlayerColor = v end)

local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1,0,0,10) spacer.BackgroundTransparency = 1 spacer.Parent = MainPage

UIUtils.CreateToggle(MainPage, "ESP NPCs", _G_State.ESP_NPCs_Enabled, function(v)
	_G_State.ESP_NPCs_Enabled = v
	if not v then
		for char, hl in pairs(ESP_NPC_Highlights) do
			hl:Destroy()
			ESP_NPC_Highlights[char] = nil
		end
	end
end)

local espNPCSet = UIUtils.CreateMinitab(MainPage, "NPC ESP Settings")
UIUtils.CreateColorPicker(espNPCSet, "NPC Color", _G_State.ESP_NPCColor, function(v) _G_State.ESP_NPCColor = v end)

local spacer2 = Instance.new("Frame")
spacer2.Size = UDim2.new(1,0,0,10) spacer2.BackgroundTransparency = 1 spacer2.Parent = MainPage

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

CalibrateBtnRef = UIUtils.CreateButton(aimSet, "Set Custom Crosshair", function()
	if not _G_State.Calibrating then
		_G_State.Calibrating = true
		if CalibrateBtnRef then
			CalibrateBtnRef.Text = "Waiting for Click..."
			CalibrateBtnRef.TextColor3 = Color3.fromRGB(255, 255, 0)
		end
	end
end)

UIUtils.CreateButton(aimSet, "Reset Crosshair", function()
	_G_State.Aimbot_Crosshair = nil
	_G_State.Calibrating = false
	CrosshairDot.Visible = false
	if CalibrateBtnRef then
		CalibrateBtnRef.Text = "Set Custom Crosshair"
		CalibrateBtnRef.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end)

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

UIUtils.CreateSlider(aimSet, "Aimbot Smoothness", 0.1, 1.0, 0.5, function(v)
	_G_State.Aimbot_Smoothness = v
end)

UIUtils.CreateToggle(aimSet, "Target Players", _G_State.Aimbot_TargetPlayers, function(v) _G_State.Aimbot_TargetPlayers = v end)
UIUtils.CreateToggle(aimSet, "Target NPCs", _G_State.Aimbot_TargetNPCs, function(v) _G_State.Aimbot_TargetNPCs = v end)

local ConfigPage = UIUtils.CreateTab("Configure", 2)

UIUtils.CreateButton(ConfigPage, "Manual Reload Entities", function()
	task.spawn(ScanEntities)
end)

local AutoReloadBtn = nil
AutoReloadBtn = UIUtils.CreateButton(ConfigPage, "Auto-Reload: ON", function()
	_G_State.AutoReload = not _G_State.AutoReload
	if _G_State.AutoReload then
		AutoReloadBtn.Text = "Auto-Reload: ON"
		LastNPCCheck = tick()
	else
		AutoReloadBtn.Text = "Auto-Reload: OFF"
	end
end)

local function ApplyHighlight(obj, isPlayer)
	local storage = isPlayer and ESP_Player_Highlights or ESP_NPC_Highlights
	local hl = storage[obj]
	
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "ProjectHL"
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.Parent = obj
		storage[obj] = hl
	end
	
	if isPlayer then
		hl.FillColor = _G_State.ESP_PlayerColor
		hl.OutlineColor = Color3.new(1,1,1)
		hl.Enabled = _G_State.ESP_Players_Enabled
	else
		hl.FillColor = _G_State.ESP_NPCColor
		hl.OutlineColor = Color3.new(1,1,1)
		hl.Enabled = _G_State.ESP_NPCs_Enabled
	end
	
	if not obj.Parent or not GetAnyPart(obj) then
		hl:Destroy()
		storage[obj] = nil
	end
end

Connections.ScannerLoop = RunService.Heartbeat:Connect(function()
	if _G_State.AutoReload and (tick() - LastNPCCheck >= 120) then
		task.spawn(ScanEntities)
	end
end)

Connections.ESP_Loop = RunService.Heartbeat:Connect(function()
	if _G_State.ESP_Players_Enabled then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character and GetAnyPart(plr.Character) then
				ApplyHighlight(plr.Character, true)
			end
		end
	end
	
	if _G_State.ESP_NPCs_Enabled then
		for npc, _ in pairs(CachedNPCs) do
			if npc.Parent and GetAnyPart(npc) then
				ApplyHighlight(npc, false)
			else
				CachedNPCs[npc] = nil
				if ESP_NPC_Highlights[npc] then
					ESP_NPC_Highlights[npc]:Destroy()
					ESP_NPC_Highlights[npc] = nil
				end
			end
		end
	end
	
	for char, hl in pairs(ESP_Player_Highlights) do
		if not _G_State.ESP_Players_Enabled or not char.Parent or not GetAnyPart(char) then
			hl:Destroy()
			ESP_Player_Highlights[char] = nil
		end
	end
	
	for npc, hl in pairs(ESP_NPC_Highlights) do
		if not _G_State.ESP_NPCs_Enabled or not npc.Parent or not GetAnyPart(npc) then
			hl:Destroy()
			ESP_NPC_Highlights[npc] = nil
		end
	end
end)

local function GetScreenCenter()
	if _G_State.Aimbot_Crosshair then
		return _G_State.Aimbot_Crosshair, true
	else
		return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2), false
	end
end

local function GetClosestTarget()
	local closestDist = math.huge
	local targetChar = nil
	local targetPart = nil
	
	local validTargets = {}
	
	if _G_State.Aimbot_TargetPlayers then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				validTargets[player.Character] = true
			end
		end
	end
	
	if _G_State.Aimbot_TargetNPCs then
		for npc, _ in pairs(CachedNPCs) do
			if npc.Parent then
				validTargets[npc] = true
			end
		end
	end
	
	local refPoint, isCustom = GetScreenCenter()
	
	for char, _ in pairs(validTargets) do
		local hum = char:FindFirstChild("Humanoid") or char:FindFirstChildWhichIsA("Humanoid")
		if hum and hum.Health > 0 then
			local part = GetAimPart(char)
			if part then
				local pos, onScreen
				if isCustom then
					pos, onScreen = Camera:WorldToScreenPoint(part.Position)
				else
					pos, onScreen = Camera:WorldToViewportPoint(part.Position)
				end
				
				if onScreen then
					local partPos2D = Vector2.new(pos.X, pos.Y)
					local dist = (refPoint - partPos2D).Magnitude
					
					if dist < closestDist then
						closestDist = dist
						targetChar = char
						targetPart = part
					end
				end
			end
		end
	end
	
	return targetPart
end

local aimbotActive = false

Connections.CalibrateClick = UserInputService.InputBegan:Connect(function(input)
	if _G_State.Calibrating and input.UserInputType == Enum.UserInputType.MouseButton1 then
		_G_State.Aimbot_Crosshair = Vector2.new(input.Position.X, input.Position.Y)
		_G_State.Calibrating = false
		
		CrosshairDot.Position = UDim2.new(0, input.Position.X, 0, input.Position.Y)
		CrosshairDot.Visible = true
		
		if CalibrateBtnRef then
			CalibrateBtnRef.Text = "Set Custom Crosshair"
			CalibrateBtnRef.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end
end)

Connections.AimInputBegan = UserInputService.InputBegan:Connect(function(input)
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
			local refPoint, isCustom = GetScreenCenter()
			local pos, onScreen
			
			if isCustom then
				pos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
			else
				pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
			end
			
			if onScreen then
				if type(mousemoverel) == "function" then
					local deltaX = pos.X - refPoint.X
					local deltaY = pos.Y - refPoint.Y
					mousemoverel(deltaX * _G_State.Aimbot_Smoothness, deltaY * _G_State.Aimbot_Smoothness)
				else
					Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
				end
			end
		end
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	DestroyEverything()
end)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == MENU_TOGGLE_KEY then
		_G_State.MenuVisible = not _G_State.MenuVisible
		MainFrame.Visible = _G_State.MenuVisible
	end
end)
