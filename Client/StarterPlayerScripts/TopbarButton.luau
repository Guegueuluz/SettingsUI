-- TopbarButton.luau
-- LocalScript de exemplo para criar um botão de topbar com visual parecido com SettingsUI.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local CONFIG = {
	Topbar = {
		Size = 45,
		Offset = 10,
		CornerRadius = 100,
		IconSize = 25,
		Icon = "rbxassetid://75598433925609",
	},
	Colors = {
		RobloxTopbar = Color3.fromRGB(22, 22, 22),
		TopbarButton = Color3.fromRGB(22, 22, 22),
		ButtonHover = Color3.fromRGB(21, 21, 21),
		ButtonPressed = Color3.fromRGB(22, 22, 22),
		White = Color3.fromRGB(255, 255, 255),
		Secondary = Color3.fromRGB(150, 150, 150),
		Border = Color3.fromRGB(55, 55, 55),
		Focus = Color3.fromRGB(70, 70, 70),
	},
	Animation = {
		Fast = 0.12,
		Medium = 0.20,
		Open = 0.42,
	},
	Cooldown = 0.45,
}

local existing = PlayerGui:FindFirstChild("SettingsTopbarButtonUI")
if existing then
	existing:Destroy()
end

local UI = Instance.new("ScreenGui")
UI.Name = "SettingsTopbarButtonUI"
UI.ResetOnSpawn = false
UI.IgnoreGuiInset = true
UI.ScreenInsets = Enum.ScreenInsets.None
UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.Parent = PlayerGui

local Root = Instance.new("Frame")
Root.Name = "TopbarRoot"
Root.AnchorPoint = Vector2.new(1, 0)
Root.BackgroundColor3 = CONFIG.Colors.RobloxTopbar
Root.BackgroundTransparency = 0.10
Root.BorderSizePixel = 0
Root.Size = UDim2.fromOffset(CONFIG.Topbar.Size, CONFIG.Topbar.Size)
Root.Position = UDim2.new(1, -CONFIG.Topbar.Offset, 0, CONFIG.Topbar.Offset)
Root.ClipsDescendants = true
Root.Visible = true
Root.Parent = UI

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, CONFIG.Topbar.CornerRadius)
UICorner.Parent = Root

local Button = Instance.new("TextButton")
Button.Name = "SettingsButton"
Button.AutoButtonColor = false
Button.BackgroundColor3 = CONFIG.Colors.TopbarButton
Button.BackgroundTransparency = 0.10
Button.BorderSizePixel = 0
Button.Size = UDim2.new(1, 0, 1, 0)
Button.Text = ""
Button.Parent = Root

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, CONFIG.Topbar.CornerRadius)
ButtonCorner.Parent = Button

local IconImage = Instance.new("ImageLabel")
IconImage.Name = "Icon"
IconImage.BackgroundTransparency = 1
IconImage.Size = UDim2.fromOffset(CONFIG.Topbar.IconSize, CONFIG.Topbar.IconSize)
IconImage.Position = UDim2.fromOffset(10, (CONFIG.Topbar.Size - CONFIG.Topbar.IconSize) / 2)
IconImage.Image = CONFIG.Topbar.Icon
IconImage.ImageColor3 = CONFIG.Colors.White
IconImage.ScaleType = Enum.ScaleType.Fit
IconImage.Parent = Button

local Label = Instance.new("TextLabel")
Label.Name = "Title"
Label.BackgroundTransparency = 1
Label.Position = UDim2.fromOffset(CONFIG.Topbar.Size + 12, 0)
Label.Size = UDim2.fromOffset(120, CONFIG.Topbar.Size)
Label.Font = Enum.Font.BuilderSansBold
Label.Text = "Configurações"
Label.TextColor3 = CONFIG.Colors.White
Label.TextSize = 15
Label.TextTransparency = 1
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.TextTruncate = Enum.TextTruncate.AtEnd
Label.Parent = Root

local hoverButtonTween = TweenService:Create(Button, TweenInfo.new(CONFIG.Animation.Fast), {
	BackgroundColor3 = CONFIG.Colors.ButtonHover,
})

local pressedButtonTween = TweenService:Create(Button, TweenInfo.new(CONFIG.Animation.Fast), {
	BackgroundColor3 = CONFIG.Colors.ButtonPressed,
})

local expandTween = TweenService:Create(Root, TweenInfo.new(CONFIG.Animation.Fast), {
	Size = UDim2.fromOffset(160, CONFIG.Topbar.Size),
})

local shrinkTween = TweenService:Create(Root, TweenInfo.new(CONFIG.Animation.Fast), {
	Size = UDim2.fromOffset(CONFIG.Topbar.Size, CONFIG.Topbar.Size),
})

local revealTextTween = TweenService:Create(Label, TweenInfo.new(CONFIG.Animation.Fast), {
	TextTransparency = 0,
})

local hideTextTween = TweenService:Create(Label, TweenInfo.new(CONFIG.Animation.Fast), {
	TextTransparency = 1,
})

local LastSettingsPulse = 0
local SettingsButtonOpenPosition = UDim2.new(1, -CONFIG.Topbar.Offset, 1, -CONFIG.Topbar.Offset)
local SettingsButtonHiddenPosition = UDim2.new(1, -CONFIG.Topbar.Offset, 1, 260)

local function TrySettingsButtonReveal(settingsButton)
	if not settingsButton then
		return
	end

	settingsButton.Visible = true
	settingsButton.Active = true
	settingsButton.Selectable = true
	settingsButton.Position = SettingsButtonHiddenPosition

	TweenService:Create(
		settingsButton,
		TweenInfo.new(CONFIG.Animation.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Position = SettingsButtonOpenPosition,
		}
	):Play()
end

local function TrySettingsButtonHide(settingsButton)
	if not settingsButton or settingsButton.Visible == false then
		return
	end

	settingsButton.Visible = true
	settingsButton.Active = false
	settingsButton.Selectable = false
	settingsButton.Position = SettingsButtonOpenPosition

	local closeTween = TweenService:Create(
		settingsButton,
		TweenInfo.new(CONFIG.Animation.Open, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{
			Position = SettingsButtonHiddenPosition,
		}
	)

	closeTween:Play()
	closeTween.Completed:Connect(function()
		settingsButton.Visible = false
		settingsButton.Active = false
		settingsButton.Selectable = false
		settingsButton.Position = SettingsButtonHiddenPosition
	end)
end

Button.MouseEnter:Connect(function()
	expandTween:Play()
	revealTextTween:Play()
	hoverButtonTween:Play()
end)

Button.MouseLeave:Connect(function()
	shrinkTween:Play()
	hideTextTween:Play()
	TweenService:Create(Button, TweenInfo.new(CONFIG.Animation.Fast), {
		BackgroundColor3 = CONFIG.Colors.TopbarButton,
	}):Play()
end)

Button.MouseButton1Down:Connect(function()
	pressedButtonTween:Play()
end)

Button.MouseButton1Up:Connect(function()
	hoverButtonTween:Play()
end)

Button.MouseButton1Click:Connect(function()
	local now = os.clock()
	if now - LastSettingsPulse < CONFIG.Cooldown then
		return
	end
	LastSettingsPulse = now

	local SettingsTopbar = PlayerGui:FindFirstChild("SettingsTopbarUI")
	if not SettingsTopbar or not SettingsTopbar:FindFirstChild("SettingsButton") then
		return
	end

	local SettingsButtonFromUI = SettingsTopbar.SettingsButton
	if not SettingsButtonFromUI:IsA("TextButton") then
		return
	end

	if SettingsButtonFromUI.Visible then
		TrySettingsButtonHide(SettingsButtonFromUI)
	else
		TrySettingsButtonReveal(SettingsButtonFromUI)
	end
end)
