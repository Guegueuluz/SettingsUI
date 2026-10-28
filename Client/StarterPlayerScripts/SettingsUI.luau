	--[[
		SettingsUI.client.lua
		----------------------------------------------------------------
		SETTINGS UI - Guegueuluz
		Versão 0.3 Privada

		COMPATIBILIDADE
			• PC
			• Smartphone
			• Tablet
			• Console / Gamepad
			• TV / Ten-Foot Interface

		RECURSOS
			• Topbar
			• Categorias
			• Sidebar responsiva
			• Animações modernas
			• Smart Focus
			• Fullscreen
			• Ícone fullscreen desenhado por Frames
			• Blur de fundo
			• Responsive Layout
			• Touch Support
			• Gamepad Focus
			• Aviso experimental de fotossensibilidade
			• Modo reduzido
			• Switch com pressão para confirmar
			• Cancelamento seguro
			• Anti-spam
			• Cooldown de 2 segundos
			• Fade-Off completo
			• UIStroke incluído no Fade
			• Canvas automático
			• Animation Tokens
		----------------------------------------------------------------
	]]

-- Mailo0370 ou Google Materials para ícones!

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SoundService = game:GetService("SoundService")

local SettingsSounds =
	SoundService:FindFirstChild("SettingsUI")

if not SettingsSounds then
	SettingsSounds =
		Instance.new("Folder")

	SettingsSounds.Name = "SettingsUI"
	SettingsSounds.Parent = SoundService
end

local SaveButtonSound = SettingsSounds:FindFirstChild("SaveButton")
if not SaveButtonSound then
	SaveButtonSound = Instance.new("Sound")
	SaveButtonSound.Name = "SaveButton"
	SaveButtonSound.Volume = 0.7
	SaveButtonSound.Parent = SettingsSounds
end

local SecretSettingsMusic = SettingsSounds:FindFirstChild("SecretSettingsMusic")
if not SecretSettingsMusic then
	SecretSettingsMusic = Instance.new("Sound")
	SecretSettingsMusic.Name = "SecretSettingsMusic"
	SecretSettingsMusic.Looped = true
	SecretSettingsMusic.Volume = 0
	SecretSettingsMusic.Parent = SettingsSounds
end

local BUILDER_ICONS =
	"rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"

local function Icon(name)
	return string.format(
		"<font family='%s'>%s</font>",
		BUILDER_ICONS,
		name
	)
end

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

local CONFIG = {

	Topbar = {
		Size = 50,
		Offset = 10,
		CornerRadius = 30,
		IconSize = 30,
		Icon = "rbxassetid://123953064101933",
		WarningIcon = "rbxassetid://11745872910",
	},

	PanelWidth = 700,
	PanelHeight = 470,	

	Animation = {
		Open = 0.42,
		Close = 0.30,

		Fast = 0.12,
		Medium = 0.20,
		Slow = 0.36,

		Stagger = 0.035,

		Focus = 0.14,
		Press = 0.08,

		Warning = 0.30,
	},

	Interaction = {
		Cooldown = 2,

		SwitchHoldDuration = 0.45,
		SwitchCenterDuration = 0.20,
		SwitchCancelDuration = 0.16,

		FocusScale = 1.02,
		PressScale = 0.97,
	},

	Audio = {

		-- Deixe vazio para configurar a música diretamente no SoundService.
		-- Exemplo: "rbxassetid://1234567890"
		MusicId = "",

		MusicEnabledDefault = true,
		MusicVolumeDefault = 0.525,
	},

	Accessibility = {

		-- Recurso experimental.
		-- Usado para testes de avisos relacionados à
		-- sensibilidade a efeitos visuais.

		WarningEnabled = true,

		-- Se true, o aviso aparece novamente sempre
		-- que a interface for aberta.
		--
		-- Recomendado FALSE para uso normal.
		ForceWarningForTesting = false,

		ReducedMotionDefault = false,
	},

	Fullscreen = {

		PanelTransparency = 0.12,

		BlurSize = 14,

		OpenDuration = 0.42,
		CloseDuration = 0.34,

		PC = UDim2.fromScale(0.94, 0.88),
		PC_Large = UDim2.fromScale(0.94, 0.88),

		Tablet = UDim2.fromScale(0.93, 0.88),

		Mobile = UDim2.fromScale(0.96, 0.86),

		Console = UDim2.fromScale(0.90, 0.86),

		TV = UDim2.fromScale(0.88, 0.86),
	},

	Themes = {
		Dark = {
			Black = Color3.fromRGB(10, 10, 10),
			Dark = Color3.fromRGB(16, 16, 16),
			Darker = Color3.fromRGB(12, 12, 12),
			White = Color3.fromRGB(255, 255, 255),
			Secondary = Color3.fromRGB(150, 150, 150),
			Description = Color3.fromRGB(170, 170, 170),
			Border = Color3.fromRGB(55, 55, 55),
			Focus = Color3.fromRGB(70, 70, 70),
			Warning = Color3.fromRGB(255, 196, 76),
			WarningDark = Color3.fromRGB(45, 36, 18),
		},

		Light = {
			Black = Color3.fromRGB(246, 246, 248),
			Dark = Color3.fromRGB(236, 236, 239),
			Darker = Color3.fromRGB(226, 226, 230),
			White = Color3.fromRGB(28, 28, 32),
			Secondary = Color3.fromRGB(92, 92, 98),
			Description = Color3.fromRGB(112, 112, 118),
			Border = Color3.fromRGB(205, 205, 210),
			Focus = Color3.fromRGB(218, 218, 223),
			Warning = Color3.fromRGB(205, 145, 28),
			WarningDark = Color3.fromRGB(255, 246, 220),
		},
	},

	-- A paleta ativa continua em CONFIG.Colors para preservar a
	-- compatibilidade com o restante do script.
	Colors = nil,
}

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------

local Opened = false
local CurrentCategory = "Geral"
local CurrentPage = "Main"

-- Estado de navegação preservado ao fechar/reabrir a interface.
local SavedCategory = "Geral"
local SavedPage = "Main"

local FullscreenEnabled = false
local Transitioning = false
local TransitionStartedAt = 0

local AnimationToken = 0
local SettingsCooldownUntil = 0
local TopbarClickLocked = false
local ThemeRestarting = false

local SettingRows = {}
local CategoryButtons = {}
local SaveButton = nil
local UpdateSaveButtonVisual = function() end
local SettingsPersistenceRemote = nil
local SettingsInitialized = false
local SettingsDirty = false
local SaveCooldownActive = false
local SaveInProgress = false
local SettingsRevision = 0
local SecretSettingsTriggered = false
local SecretSettingsTimer = nil
local SecretSettingsEnvironment = nil
local SecretSettingsMusicFadeToken = 0

local ViewportConnection = nil
local InputConnection = nil

local PhotosensitivityConfirmed = false
local PhotosensitivityProtectionEnabled = true
local NotificationsEnabled = true
local VibrationEnabled = true
local InterfaceAnimationsEnabled = true

local PhotosensitivityWarningPending =
	CONFIG.Accessibility.WarningEnabled

local InterfaceSoundsEnabled = true

local MusicEnabled =
	CONFIG.Audio.MusicEnabledDefault == true

local MusicVolume =
	math.clamp(
		CONFIG.Audio.MusicVolumeDefault or 0.35,
		0,
		1
	)

local BackgroundMusic = SoundService.SettingsUI:FindFirstChild("Music")

if not BackgroundMusic then
	BackgroundMusic =
		Instance.new("Sound")

	BackgroundMusic.Name = "Music"
	BackgroundMusic.Parent = SoundService
end

BackgroundMusic.Looped = true
BackgroundMusic.Volume = MusicVolume

if CONFIG.Audio.MusicId ~= "" then
	BackgroundMusic.SoundId = CONFIG.Audio.MusicId
end

local function ApplyMusicState()
	BackgroundMusic.Volume = MusicVolume

	if SecretSettingsTriggered and MusicEnabled then
		SecretSettingsTriggered = false
		CancelSecretSettingsTimer()
		RestoreSecretSettingsEnvironment()
		StopSecretSettingsMusic(2)
	end

	if not MusicEnabled then
		if BackgroundMusic.IsPlaying then
			BackgroundMusic:Pause()
		end
		return
	end

	if BackgroundMusic.SoundId == ""
		or BackgroundMusic.SoundId == "rbxassetid://0"
	then
		return
	end

	if not BackgroundMusic.IsPlaying then
		BackgroundMusic:Play()
	end
end

local function MarkSettingsDirty()
	SettingsRevision += 1
	SettingsDirty = true
	UpdateSaveButtonVisual()
end

local function CancelSecretSettingsTimer()
	if SecretSettingsTimer then
		task.cancel(SecretSettingsTimer)
		SecretSettingsTimer = nil
	end
end

local function RestoreSecretSettingsEnvironment()
	if not SecretSettingsEnvironment then
		return
	end

	local brightness = SecretSettingsEnvironment.Brightness
	local ambient = SecretSettingsEnvironment.OutdoorAmbient
	local ambientDark = SecretSettingsEnvironment.Ambient
	local clock = SecretSettingsEnvironment.ClockTime

	Tween(Lighting, {
		Brightness = brightness,
		OutdoorAmbient = ambient,
		Ambient = ambientDark,
		ClockTime = clock,
	}, 0.7)

	if SettingsBlur then
		Tween(SettingsBlur, { Size = 0 }, 0.7)
		task.delay(0.7, function()
			SettingsBlur.Enabled = false
			SettingsBlur.Size = 0
		end)
	end

	SecretSettingsEnvironment = nil
end

local function StartSecretSettingsTimer()
	CancelSecretSettingsTimer()

	SecretSettingsTimer = task.delay(60, function()
		if not Opened or MusicEnabled or SecretSettingsTriggered then
			return
		end

		if type(TriggerSecretSettings) == "function" then
			TriggerSecretSettings()
		end
	end)
end

local function TriggerSecretSettings()
	if SecretSettingsTriggered or MusicEnabled then
		return
	end

	SecretSettingsTriggered = true
	SecretSettingsMusicFadeToken += 1
	local fadeToken = SecretSettingsMusicFadeToken

	if not SecretSettingsEnvironment then
		SecretSettingsEnvironment = {
			Brightness = Lighting.Brightness,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			Ambient = Lighting.Ambient,
			ClockTime = Lighting.ClockTime,
		}
	end

	if SettingsBlur then
		SettingsBlur.Enabled = true
		Tween(SettingsBlur, { Size = 18 }, 0.9)
	end

	if SecretSettingsMusic and SecretSettingsMusic.Parent then
		SecretSettingsMusic.Volume = 0
		SecretSettingsMusic:Play()
	end

	Tween(Lighting, {
		Brightness = math.max(Lighting.Brightness * 0.7, 1),
		OutdoorAmbient = Color3.fromRGB(26, 27, 34),
		Ambient = Color3.fromRGB(30, 32, 39),
	}, 0.9)

	task.spawn(function()
		if not SecretSettingsMusic or not SecretSettingsMusic.Parent then
			return
		end

		local targetVolume = 0.22
		for step = 1, 28 do
			if SecretSettingsMusicFadeToken ~= fadeToken then
				return
			end
			SecretSettingsMusic.Volume = targetVolume * (step / 28)
			task.wait(0.12)
		end
		SecretSettingsMusic.Volume = targetVolume
	end)
end

local function StopSecretSettingsMusic(fadeOutSeconds)
	if not SecretSettingsMusic or not SecretSettingsMusic.Parent then
		return
	end

	SecretSettingsMusicFadeToken += 1
	local fadeToken = SecretSettingsMusicFadeToken
	local startVolume = SecretSettingsMusic.Volume

	if fadeOutSeconds and fadeOutSeconds > 0 then
		task.spawn(function()
			for step = 1, 20 do
				if SecretSettingsMusicFadeToken ~= fadeToken then
					return
				end
				SecretSettingsMusic.Volume = startVolume * (1 - (step / 20))
				task.wait(0.1)
			end
			if SecretSettingsMusicFadeToken == fadeToken then
				SecretSettingsMusic.Volume = 0
				SecretSettingsMusic:Stop()
			end
		end)
		return
	end

	SecretSettingsMusic.Volume = 0
	SecretSettingsMusic:Stop()
end

local AccessibilityGateActive = false

local ReducedMotionEnabled =
	CONFIG.Accessibility.ReducedMotionDefault

local FadeRegistry = {}

local ThemeRegistry = {}
local CurrentTheme = "Dark"

local ThemeIcons = {
	-- Substitua pelos IDs das suas imagens.
	-- Dark = ícone exibido enquanto o tema atual é Dark (ex.: Lua/escuro).
	-- Light = ícone exibido enquanto o tema atual é Light (ex.: Sol/claro).
	Dark = "rbxassetid://73473029348351",
	Light = "rbxassetid://79398225282535",
}

CONFIG.Colors = CONFIG.Themes[CurrentTheme]

----------------------------------------------------------------
-- DEVICE STATE (declarado cedo de propósito)
----------------------------------------------------------------

-- IMPORTANTE: CurrentDevice, DetectDevice e IsPCDevice são
-- globais (sem "local") de propósito, pois são usados por
-- funções definidas ANTES deles no arquivo (ex: BuildAbout,
-- CreateCategoryButton, GetRowHeight). Em Lua, uma "local
-- function" só é visível a partir da linha em que é declarada;
-- se ficar mais abaixo no arquivo, qualquer referência a ela em
-- funções definidas antes vira uma variável global inexistente
-- (nil), causando "attempt to call a nil value". Por isso essas
-- funções permanecem globais e são definidas aqui em cima.

CurrentDevice = "PC"

function DetectDevice()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return "PC"
	end

	local viewport =
		camera.ViewportSize

	local width =
		viewport.X

	local height =
		viewport.Y

	if GuiService:IsTenFootInterface() then
		return "TV"
	end

	local lastInput =
		UserInputService:GetLastInputType()

	if lastInput ==
		Enum.UserInputType.Gamepad1
		or lastInput ==
		Enum.UserInputType.Gamepad2
	then

		return "Console"

	end

	local aspectRatio = width / math.max(height, 1)

	-- Celulares podem aparecer em preview em landscape e ainda
	-- devem ser tratados como Mobile, mantendo a mesma estrutura
	-- visual do PC, mas com escala reduzida.
	if width <= 900 or (width <= 980 and (height <= 760 or aspectRatio <= 1.6)) then
		return "Mobile"
	end

	if width < 1100 then
		return "Tablet"
	end

	if width >= 1600 then
		return "PC_Large"
	end

	return "PC"

end

function IsPCDevice(device)

	return device == "PC"
		or device == "PC_Large"

end

----------------------------------------------------------------
-- UI SOUNDS
----------------------------------------------------------------

local function PlaySettingsSound(
	soundName
)

	if not InterfaceSoundsEnabled then
		return
	end

	if not SettingsSounds then
		return
	end

	local sound =
		SettingsSounds:FindFirstChild(
			soundName
		)

	if not sound then

		warn(
			"[SettingsUI] Som não encontrado:",
			soundName
		)

		return

	end

	SoundService:PlayLocalSound(
		sound
	)

end

----------------------------------------------------------------
-- INTERACTION
----------------------------------------------------------------

local function IsCooldownActive()

	return os.clock() < SettingsCooldownUntil

end


local function StartSettingsCooldown()

	SettingsCooldownUntil =
		os.clock() + CONFIG.Interaction.Cooldown

end


local function CanToggleSettings()

	if Transitioning then
		return false
	end

	return true

end


local function CanInteract()

	return not Transitioning

end


local function BeginTransition()

	if Transitioning then
		return nil
	end

	Transitioning = true
	TransitionStartedAt = os.clock()

	AnimationToken += 1

	return AnimationToken

end


local function EndTransition(
	token,
	startCooldown
)

	if token ~= AnimationToken then
		return
	end

	Transitioning = false
	TransitionStartedAt = 0

	if startCooldown then
		StartSettingsCooldown()
	end

end


local function IsValidToken(token)

	return token == AnimationToken

end

----------------------------------------------------------------
-- MOTION
----------------------------------------------------------------

local function MotionDuration(duration)

	if ReducedMotionEnabled then

		return math.min(
			duration,
			0.08
		)

	end

	return duration

end


local function MotionScale()

	if ReducedMotionEnabled then
		return 1
	end

	return 1

end

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------

local function ColorsEqual(a, b)
	if typeof(a) ~= "Color3" or typeof(b) ~= "Color3" then
		return false
	end

	return math.abs(a.R - b.R) < 0.0001
		and math.abs(a.G - b.G) < 0.0001
		and math.abs(a.B - b.B) < 0.0001
end

local function GetThemeRole(color)
	if typeof(color) ~= "Color3" then
		return nil
	end

	for _, palette in pairs(CONFIG.Themes) do
		for role, paletteColor in pairs(palette) do
			if ColorsEqual(color, paletteColor) then
				return role
			end
		end
	end

	return nil
end

local function ThemeColor(role)
	return CONFIG.Colors[role] or CONFIG.Themes.Dark[role]
end

local function RegisterThemeProperty(object, property, role)
	if not object or not role then
		return
	end

	table.insert(ThemeRegistry, {
		Object = object,
		Property = property,
		Role = role,
	})
end

local function RegisterThemeSequence(object, property, sequence)
	if not object or not sequence then
		return
	end

	local roles = {}
	local hasRole = false

	for index, keypoint in ipairs(sequence.Keypoints) do
		local role = GetThemeRole(keypoint.Value)
		roles[index] = role
		if role then
			hasRole = true
		end
	end

	if not hasRole then
		return
	end

	table.insert(ThemeRegistry, {
		Object = object,
		Property = property,
		Sequence = sequence,
		Roles = roles,
	})
end

local function ApplyTheme(themeName)
	if themeName ~= "Light" and themeName ~= "Dark" then
		themeName = "Dark"
	end

	CurrentTheme = themeName
	CONFIG.Colors = CONFIG.Themes[CurrentTheme]

	for index = #ThemeRegistry, 1, -1 do
		local entry = ThemeRegistry[index]
		local object = entry.Object

		if not object or object.Parent == nil then
			table.remove(ThemeRegistry, index)
		elseif entry.Sequence then
			local keypoints = {}
			for keyIndex, keypoint in ipairs(entry.Sequence.Keypoints) do
				local role = entry.Roles[keyIndex]
				keypoints[keyIndex] = ColorSequenceKeypoint.new(
					keypoint.Time,
					role and ThemeColor(role) or keypoint.Value
				)
			end
			object[entry.Property] = ColorSequence.new(keypoints)
		else
			object[entry.Property] = ThemeColor(entry.Role)
		end
	end
end

local function Create(
	className,
	properties
)

	local object =
		Instance.new(className)

	for property, value in pairs(properties) do

		local themedValue = value

		if typeof(value) == "Color3" then
			local role = GetThemeRole(value)
			if role then
				themedValue = ThemeColor(role)
				RegisterThemeProperty(object, property, role)
			end
		elseif typeof(value) == "ColorSequence" then
			themedValue = value
			local keypoints = {}
			local hasRole = false

			for index, keypoint in ipairs(value.Keypoints) do
				local role = GetThemeRole(keypoint.Value)
				if role then
					hasRole = true
					keypoints[index] = ColorSequenceKeypoint.new(
						keypoint.Time,
						ThemeColor(role)
					)
				else
					keypoints[index] = keypoint
				end
			end

			if hasRole then
				themedValue = ColorSequence.new(keypoints)
			end
		end

		object[property] = themedValue

	end

	for property, value in pairs(properties) do
		if typeof(value) == "ColorSequence" then
			RegisterThemeSequence(object, property, value)
		end
	end

	if className == "TextLabel"
		or className == "TextButton"
		or className == "TextBox"
	then

		object.RichText = true

	end

	return object

end


local function Corner(
	parent,
	radius
)

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(
			0,
			radius
		)

	corner.Parent = parent

	return corner

end


local function Stroke(
	parent,
	color,
	transparency,
	thickness
)

	local stroke =
		Instance.new("UIStroke")

	local role = GetThemeRole(color)
	stroke.Color = role and ThemeColor(role) or color
	if role then
		RegisterThemeProperty(stroke, "Color", role)
	end
	stroke.Transparency = transparency or 0
	stroke.Thickness = thickness or 1

	stroke.Parent = parent

	return stroke

end


local function Tween(
	object,
	properties,
	duration,
	easingStyle,
	easingDirection
)

	if not object then
		return
	end

	local tweenInfo =
		TweenInfo.new(
			MotionDuration(duration or CONFIG.Animation.Medium),

			easingStyle
			or Enum.EasingStyle.Quint,

			easingDirection
			or Enum.EasingDirection.Out
		)

	local tween =
		TweenService:Create(
			object,
			tweenInfo,
			properties
		)

	tween:Play()

	return tween

end


local function PlayScale(
	scaleObject,
	target,
	duration,
	style,
	direction
)

	if not scaleObject then
		return
	end

	if ReducedMotionEnabled then
		scaleObject.Scale = 1
		return
	end

	return Tween(
		scaleObject,
		{
			Scale = target
		},
		duration,
		style,
		direction
	)

end

----------------------------------------------------------------
-- FADE SYSTEM
----------------------------------------------------------------

local function CaptureFadeObject(object)

	if FadeRegistry[object] then
		return
	end

	local data = {}

	if object:IsA("GuiObject") then

		data.BackgroundTransparency =
			object.BackgroundTransparency

	end

	if object:IsA("TextLabel")
		or object:IsA("TextButton")
		or object:IsA("TextBox")
	then

		data.TextTransparency =
			object.TextTransparency

		data.TextStrokeTransparency =
			object.TextStrokeTransparency

	end

	if object:IsA("ImageLabel")
		or object:IsA("ImageButton")
	then

		data.ImageTransparency =
			object.ImageTransparency

	end

	if object:IsA("ScrollingFrame") then

		data.ScrollBarImageTransparency =
			object.ScrollBarImageTransparency

	end

	if object:IsA("UIStroke") then

		data.Transparency =
			object.Transparency

	end

	FadeRegistry[object] = data

end


local function CaptureFadeTree(root)

	if not root then
		return
	end

	CaptureFadeObject(root)

	for _, descendant in ipairs(
		root:GetDescendants()
		) do

		CaptureFadeObject(descendant)

	end

end


local function RegisterFadeObject(object)

	if object then
		CaptureFadeObject(object)
	end

end


local function RegisterFadeTree(root)

	if not root then
		return
	end

	CaptureFadeTree(root)

end


local function FadeObject(
	object,
	hidden,
	duration
)

	local data =
		FadeRegistry[object]

	if not data then
		return
	end

	local goals = {}

	if data.BackgroundTransparency ~= nil then

		goals.BackgroundTransparency =
			hidden
			and 1
			or data.BackgroundTransparency

	end

	if data.TextTransparency ~= nil then

		goals.TextTransparency =
			hidden
			and 1
			or data.TextTransparency

	end

	if data.TextStrokeTransparency ~= nil then

		goals.TextStrokeTransparency =
			hidden
			and 1
			or data.TextStrokeTransparency

	end

	if data.ImageTransparency ~= nil then

		goals.ImageTransparency =
			hidden
			and 1
			or data.ImageTransparency

	end

	if data.ScrollBarImageTransparency ~= nil then

		goals.ScrollBarImageTransparency =
			hidden
			and 1
			or data.ScrollBarImageTransparency

	end

	if data.Transparency ~= nil then

		goals.Transparency =
			hidden
			and 1
			or data.Transparency

	end

	if next(goals) then

		Tween(
			object,
			goals,
			duration or CONFIG.Animation.Medium
		)

	end

end


local function FadePanel(
	root,
	hidden,
	duration
)

	if not root then
		return
	end

	for object in pairs(FadeRegistry) do

		if object
			and object.Parent
			and (
				object == root
					or object:IsDescendantOf(root)
			)
		then

			FadeObject(
				object,
				hidden,
				duration
			)

		end

	end

end

local function FadeOverlayFade(
	visible,
	duration
)

	if not OverlayFade then
		return
	end

	OverlayFade.Visible = true
	OverlayFade.BackgroundTransparency = visible and 0 or 1

end

----------------------------------------------------------------
-- BLUR
----------------------------------------------------------------

local SettingsBlur =
	Lighting:FindFirstChild(
		"SettingsUIBlur"
	)

if not SettingsBlur then

	SettingsBlur =
		Instance.new("BlurEffect")

	SettingsBlur.Name =
		"SettingsUIBlur"

	SettingsBlur.Size = 0
	SettingsBlur.Enabled = false

	SettingsBlur.Parent =
		Lighting

end

----------------------------------------------------------------
-- SCREEN GUI
----------------------------------------------------------------

local ScreenGui =
	PlayerGui:FindFirstChild(
		"SettingsUI"
	)

if not ScreenGui then

	ScreenGui =
		Instance.new("ScreenGui")

	ScreenGui.Name =
		"SettingsUI"

	ScreenGui.ResetOnSpawn =
		false

	ScreenGui.IgnoreGuiInset =
		true

	ScreenGui.ScreenInsets =
		Enum.ScreenInsets.None

	ScreenGui.ZIndexBehavior =
		Enum.ZIndexBehavior.Sibling

	ScreenGui.DisplayOrder = 100

	ScreenGui.Parent =
		PlayerGui

end

local TopbarGui =
	PlayerGui:FindFirstChild(
		"SettingsTopbarUI"
	)

if not TopbarGui then

	TopbarGui =
		Instance.new("ScreenGui")

	TopbarGui.Name =
		"SettingsTopbarUI"

	TopbarGui.ResetOnSpawn =
		false

	TopbarGui.IgnoreGuiInset =
		true

	TopbarGui.ClipToDeviceSafeArea = false

	TopbarGui.ScreenInsets = Enum.ScreenInsets.None

	TopbarGui.ZIndexBehavior =
		Enum.ZIndexBehavior.Sibling

	TopbarGui.DisplayOrder = 101

	TopbarGui.Parent =
		PlayerGui

end

----------------------------------------------------------------
-- TOPBAR
----------------------------------------------------------------

local SettingsButton =
	Create(
		"TextButton",
		{
			Name = "SettingsButton",

			Parent = TopbarGui,

			AnchorPoint =
			Vector2.new(1, 1),

			Position =
			UDim2.new(
				1,
				-CONFIG.Topbar.Offset,
				1,
				-CONFIG.Topbar.Offset
			),

			Size =
			UDim2.fromOffset(
				CONFIG.Topbar.Size,
				CONFIG.Topbar.Size
			),

			BackgroundColor3 =
			CONFIG.Colors.Black,

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			Text = "",

			AutoButtonColor = false,

			Visible = false,

			Active = false,

			Selectable = false,

			ZIndex = 100,
		}
	)

Corner(
	SettingsButton,
	CONFIG.Topbar.CornerRadius
)

local SettingsStroke =
	Stroke(
		SettingsButton,
		CONFIG.Colors.Border,
		0.20,
		1
	)

local SettingsScale =
	Create(
		"UIScale",
		{
			Parent = SettingsButton,
			Scale = 1,
		}
	)

local SettingsIcon =
	Create(
		"ImageLabel",
		{
			Name = "Icon",

			Parent = SettingsButton,

			AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

			Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

			Size =
			UDim2.fromOffset(
				CONFIG.Topbar.IconSize,
				CONFIG.Topbar.IconSize
			),

			BackgroundTransparency = 1,

			Image =
			CONFIG.Topbar.Icon,

			ImageColor3 =
			CONFIG.Colors.White,

			ZIndex = 101,
		}
	)

----------------------------------------------------------------
-- OVERLAY
----------------------------------------------------------------

local Overlay =
	Create(
		"TextButton",
		{
			Name = "Overlay",

			Parent = ScreenGui,

			Size =
			UDim2.fromScale(
				1,
				1
			),

			BackgroundColor3 =
			Color3.new(
				0,
				0,
				0
			),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			Text = "",

			AutoButtonColor = false,

			Visible = false,

			ZIndex = 10,
		}
	)

local OverlayFade =
	Create(
		"Frame",
		{
			Name = "OverlayFade",
			Parent = Overlay,
			AnchorPoint = Vector2.new(0,0),
			Position = UDim2.fromScale(0,0),
			Size = UDim2.fromScale(1,1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 11,
		}
	)

local OverlayGradient =
	Create(
		"UIGradient",
		{
			Parent = OverlayFade,
			Color =
			ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 35)),
			}),
			Rotation = 90,
			Transparency =
			NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}
	)

OverlayGradient.Enabled = true

-- A cor base do OverlayFade também acompanha o tema e é interpolada
-- junto com as cores do gradiente durante a troca de tema.
local OverlayFadeColor =
	Instance.new("Color3Value")
OverlayFadeColor.Name = "OverlayFadeColor"
OverlayFadeColor.Value = Color3.fromRGB(0, 0, 0)

local function UpdateOverlayFadeColor()
	OverlayFade.BackgroundColor3 = OverlayFadeColor.Value
end

OverlayFadeColor:GetPropertyChangedSignal("Value"):Connect(
	UpdateOverlayFadeColor
)

-- As cores do gradiente acompanham o tema e podem ser interpoladas
-- durante a troca para evitar uma mudança instantânea de cor.
local OverlayGradientStart =
	Instance.new("Color3Value")
OverlayGradientStart.Name = "OverlayGradientStart"
OverlayGradientStart.Value = Color3.fromRGB(0, 0, 0)

local OverlayGradientEnd =
	Instance.new("Color3Value")
OverlayGradientEnd.Name = "OverlayGradientEnd"
OverlayGradientEnd.Value = Color3.fromRGB(30, 30, 35)

local function UpdateOverlayGradient()
	OverlayGradient.Color =
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, OverlayGradientStart.Value),
			ColorSequenceKeypoint.new(1, OverlayGradientEnd.Value),
		})
end

OverlayGradientStart:GetPropertyChangedSignal("Value"):Connect(
	UpdateOverlayGradient
)

OverlayGradientEnd:GetPropertyChangedSignal("Value"):Connect(
	UpdateOverlayGradient
)

local OverlayGradientThemes = {
	Dark = {
		Base = Color3.fromRGB(0, 0, 0),
		Start = Color3.fromRGB(0, 0, 0),
		End = Color3.fromRGB(30, 30, 35),
	},

	Light = {
		Base = Color3.fromRGB(255, 255, 255),
		Start = Color3.fromRGB(255, 255, 255),
		End = Color3.fromRGB(235, 235, 240),
	},
}

local function SetOverlayGradientTheme(themeName, duration)
	local theme =
		OverlayGradientThemes[themeName]

	if not theme then
		return
	end

	local transitionDuration =
		MotionDuration(
			duration or CONFIG.Animation.Medium
		)

	-- Sincroniza a cor sólida do OverlayFade com o mesmo timing
	-- usado pelo gradiente.
	Tween(
		OverlayFadeColor,
		{
			Value = theme.Base,
		},
		transitionDuration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)

	Tween(
		OverlayGradientStart,
		{
			Value = theme.Start,
		},
		transitionDuration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)

	Tween(
		OverlayGradientEnd,
		{
			Value = theme.End,
		},
		transitionDuration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)
end

----------------------------------------------------------------
-- THEME RESTART INPUT SHIELD
----------------------------------------------------------------

local ThemeTransitionShield =
	Instance.new("TextButton")

ThemeTransitionShield.Name = "ThemeTransitionShield"
ThemeTransitionShield.Parent = ScreenGui
ThemeTransitionShield.Size = UDim2.fromScale(1, 1)
ThemeTransitionShield.Position = UDim2.fromScale(0, 0)
ThemeTransitionShield.BackgroundColor3 = Color3.new(0, 0, 0)
ThemeTransitionShield.BackgroundTransparency = 1
ThemeTransitionShield.BorderSizePixel = 0
ThemeTransitionShield.Text = ""
ThemeTransitionShield.AutoButtonColor = false
ThemeTransitionShield.Selectable = false
ThemeTransitionShield.Active = true
ThemeTransitionShield.Modal = true
ThemeTransitionShield.Visible = false
ThemeTransitionShield.ZIndex = 1000

----------------------------------------------------------------
-- MAIN PANEL
----------------------------------------------------------------

local MainPanel =
	Create(
		"Frame",
		{
			Name = "MainPanel",

			Parent = ScreenGui,

			AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

			Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

			Size =
			UDim2.fromOffset(
				CONFIG.PanelWidth,
				CONFIG.PanelHeight
			),

			BackgroundColor3 =
			CONFIG.Colors.Black,

			BackgroundTransparency = 0,

			BorderSizePixel = 0,

			Visible = false,

			ZIndex = 20,
		}
	)

Corner(
	MainPanel,
	16
)

local MainStroke =
	Stroke(
		MainPanel,
		CONFIG.Colors.Border,
		0.15,
		1
	)

local MainScale =
	Create(
		"UIScale",
		{
			Parent = MainPanel,
			Scale = 0.88,
		}
	)

----------------------------------------------------------------
-- HEADER
----------------------------------------------------------------

local Header =
	Create(
		"Frame",
		{
			Name = "Header",

			Parent = MainPanel,

			Position =
			UDim2.fromOffset(
				20,
				18
			),

			Size =
			UDim2.new(
				1,
				-40,
				0,
				65
			),

			BackgroundTransparency = 1,

			ZIndex = 21,
		}
	)

local Title =
	Create(
		"TextLabel",
		{
			Parent = Header,

			Size =
			UDim2.new(
				1,
				-180,
				0,
				30
			),

			BackgroundTransparency = 1,

			Text = "Configurações",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 25,

			Font =
			Enum.Font.GothamBold,

			TextXAlignment =
			Enum.TextXAlignment.Left,

			ZIndex = 22,
		}
	)

local Subtitle =
	Create(
		"TextLabel",
		{
			Parent = Header,

			Position =
			UDim2.fromOffset(
				0,
				31
			),

			Size =
			UDim2.new(
				1,
				-180,
				0,
				22
			),

			BackgroundTransparency = 1,

			Text =
			"Personalize sua experiência",

			TextColor3 =
			CONFIG.Colors.Secondary,

			TextSize = 14,

			Font =
			Enum.Font.Gotham,

			TextXAlignment =
			Enum.TextXAlignment.Left,

			ZIndex = 22,
		}
	)

local function UpdateHeaderAlignment()
	local isMobile = CurrentDevice == "Mobile"

	if isMobile then
		Title.Size = UDim2.new(1, 0, 0, 30)
		Title.Position = UDim2.fromOffset(0, 0)
		Title.TextXAlignment = Enum.TextXAlignment.Center
		Title.TextSize = 23

		Subtitle.Size = UDim2.new(1, 0, 0, 22)
		Subtitle.Position = UDim2.fromOffset(0, 31)
		Subtitle.TextXAlignment = Enum.TextXAlignment.Center
		Subtitle.TextSize = 13
	else
		Title.Size = UDim2.new(1, -180, 0, 30)
		Title.Position = UDim2.fromOffset(0, 0)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.TextSize = 25

		Subtitle.Size = UDim2.new(1, -180, 0, 22)
		Subtitle.Position = UDim2.fromOffset(0, 31)
		Subtitle.TextXAlignment = Enum.TextXAlignment.Left
		Subtitle.TextSize = 14
	end
end

----------------------------------------------------------------
-- WINDOW CONTROLS
----------------------------------------------------------------

local WindowControls =
	Create(
		"Frame",
		{
			Name = "WindowControls",
			Parent = Header,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(160, 34),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 23,
		}
	)

local WindowControlsLayout =
	Create(
		"UIListLayout",
		{
			Parent = WindowControls,
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}
	)

----------------------------------------------------------------
-- SAVE SETTINGS BUTTON
----------------------------------------------------------------

SaveButton =
	Create(
		"TextButton",
		{
			Name = "SaveSettingsButton",
			Parent = WindowControls,
			LayoutOrder = 1,
			Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Active = false,
			Selectable = false,
			ZIndex = 23,
		}
	)

Corner(SaveButton, 10)
Stroke(SaveButton, CONFIG.Colors.Border, 0.25, 1)

local SaveScale =
	Create(
		"UIScale",
		{
			Parent = SaveButton,
			Scale = 1,
		}
	)

local SaveButtonIcon =
	Create(
		"TextLabel",
		{
			Name = "Icon",
			Parent = SaveButton,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = Icon("floppy-disk"),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 17,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 24,
		}
	)

----------------------------------------------------------------
-- CLOSE BUTTON
----------------------------------------------------------------

local CloseButton =
	Create(
		"TextButton",
		{
			Name = "CloseButton",

			Parent = WindowControls,

			LayoutOrder = 4,

			Size =
			UDim2.fromOffset(
				34,
				34
			),

			BackgroundColor3 =
			CONFIG.Colors.Dark,

			BackgroundTransparency = 0,

			BorderSizePixel = 0,

			Text = "×",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 24,

			Font =
			Enum.Font.GothamMedium,

			AutoButtonColor = false,

			Selectable = true,

			ZIndex = 23,
		}
	)

Corner(
	CloseButton,
	10
)

Stroke(
	CloseButton,
	CONFIG.Colors.Border,
	0.25,
	1
)

local CloseScale =
	Create(
		"UIScale",
		{
			Parent = CloseButton,
			Scale = 1,
		}
	)

----------------------------------------------------------------
-- FULLSCREEN BUTTON
----------------------------------------------------------------

local FullscreenButton =
	Create(
		"TextButton",
		{
			Name = "FullscreenButton",

			Parent = WindowControls,

			LayoutOrder = 2,

			Size =
			UDim2.fromOffset(
				34,
				34
			),

			BackgroundColor3 =
			CONFIG.Colors.Dark,

			BorderSizePixel = 0,

			Text = "",

			AutoButtonColor = false,

			Selectable = true,

			ZIndex = 23,
		}
	)

Corner(
	FullscreenButton,
	10
)

Stroke(
	FullscreenButton,
	CONFIG.Colors.Border,
	0.25,
	1
)

local FullscreenScale =
	Create(
		"UIScale",
		{
			Parent = FullscreenButton,
			Scale = 1,
		}
	)

----------------------------------------------------------------
-- THEME BUTTON
----------------------------------------------------------------

local ThemeButton =
	Create(
		"TextButton",
		{
			Name = "ThemeButton",
			Parent = WindowControls,
			LayoutOrder = 3,
			Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = CONFIG.Colors.Dark,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Selectable = true,
			ZIndex = 23,
		}
	)

Corner(ThemeButton, 10)

Stroke(
	ThemeButton,
	CONFIG.Colors.Border,
	0.25,
	1
)

local ThemeScale =
	Create(
		"UIScale",
		{
			Parent = ThemeButton,
			Scale = 1,
		}
	)

local ThemeIcon =
	Create(
		"ImageLabel",
		{
			Name = "Icon",
			Parent = ThemeButton,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1,
			Image = ThemeIcons[CurrentTheme],
			ImageColor3 = CONFIG.Colors.White,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 24,
		}
	)

----------------------------------------------------------------
-- FULLSCREEN ICON
----------------------------------------------------------------

local FullscreenIcon =
	Create(
		"Frame",
		{
			Parent = FullscreenButton,

			AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

			Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

			Size =
			UDim2.fromOffset(
				16,
				16
			),

			BackgroundTransparency = 1,

			ZIndex = 24,
		}
	)

local ExitIcon =
	Create(
		"Frame",
		{
			Parent = FullscreenButton,

			AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

			Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

			Size =
			UDim2.fromOffset(
				16,
				16
			),

			BackgroundTransparency = 1,

			Visible = false,

			ZIndex = 24,
		}
	)


local function DrawFullscreenIcon(parent)

	local thickness = 2
	local length = 6

	local positions = {
		{0, 0, length, thickness},
		{0, 0, thickness, length},

		{16 - length, 0, length, thickness},
		{16 - thickness, 0, thickness, length},

		{0, 16 - thickness, length, thickness},
		{0, 16 - length, thickness, length},

		{16 - length, 16 - thickness, length, thickness},
		{16 - thickness, 16 - length, thickness, length},
	}

	for _, data in ipairs(positions) do

		Create(
			"Frame",
			{
				Parent = parent,

				Position =
					UDim2.fromOffset(
						data[1],
						data[2]
					),

				Size =
					UDim2.fromOffset(
						data[3],
						data[4]
					),

				BackgroundColor3 =
					CONFIG.Colors.White,

				BorderSizePixel = 0,

				ZIndex = 25,
			}
		)

	end

end

DrawFullscreenIcon(FullscreenIcon)


local function DrawExitIcon(parent)

	local thickness = 2
	local length = 6

	local positions = {
		{0, 0, length, thickness},
		{0, 0, thickness, length},

		{16 - length, 0, length, thickness},
		{16 - thickness, 0, thickness, length},

		{0, 16 - thickness, length, thickness},
		{0, 16 - length, thickness, length},

		{16 - length, 16 - thickness, length, thickness},
		{16 - thickness, 16 - length, thickness, length},
	}

	for _, data in ipairs(positions) do

		Create(
			"Frame",
			{
				Parent = parent,

				Position =
					UDim2.fromOffset(
						data[1],
						data[2]
					),

				Size =
					UDim2.fromOffset(
						data[3],
						data[4]
					),

				BackgroundColor3 =
					CONFIG.Colors.White,

				BorderSizePixel = 0,

				ZIndex = 25,
			}
		)

	end

end

DrawExitIcon(ExitIcon)


local function SetFullscreenIcon(enabled)

	FullscreenIcon.Visible = not enabled
	ExitIcon.Visible = enabled

end

local function SetTheme(themeName, persist)
	if themeName ~= "Light" and themeName ~= "Dark" then
		themeName = "Dark"
	end

	local themeChanged = CurrentTheme ~= themeName
	ApplyTheme(themeName)

	if ThemeIcon then
		ThemeIcon.Image = ThemeIcons[CurrentTheme]
	end

	if persist then
		Player:SetAttribute("SettingsTheme", CurrentTheme)
		if themeChanged then
			MarkSettingsDirty()
		end
	end

	if UpdateSaveButtonVisual then
		UpdateSaveButtonVisual()
	end
end

local function GetSettingsSnapshot()
	return {
		Theme = CurrentTheme,
		NotificationsEnabled = NotificationsEnabled,
		ReducedMotionEnabled = ReducedMotionEnabled,
		PhotosensitivityProtectionEnabled = PhotosensitivityProtectionEnabled,
		VibrationEnabled = VibrationEnabled,
		InterfaceAnimationsEnabled = InterfaceAnimationsEnabled,
		MusicEnabled = MusicEnabled,
		MusicVolume = MusicVolume,
		InterfaceSoundsEnabled = InterfaceSoundsEnabled,
	}
end

local SaveButtonPulseToken = 0
local SaveButtonPulseActive = false

local function StopSaveButtonPulse()
	SaveButtonPulseActive = false
	SaveButtonPulseToken += 1

	if SaveButtonIcon and SaveButtonIcon.Parent then
		SaveButtonIcon.TextTransparency = 0
		SaveButtonIcon.TextStrokeTransparency = 0.2
	end
end

local function StartSaveButtonPulse()
	if not SaveButtonIcon or not SaveButtonIcon.Parent then
		return
	end

	SaveButtonPulseActive = false
	SaveButtonPulseToken += 1
	local pulseToken = SaveButtonPulseToken
	SaveButtonPulseActive = true

	task.spawn(function()
		if not SaveButtonIcon or not SaveButtonIcon.Parent then
			return
		end

		while SaveButtonPulseActive and SaveButtonPulseToken == pulseToken and (SaveCooldownActive or SaveInProgress) do
			for _, transparency in ipairs({0, 0.22, 0.5, 0.78, 0.5, 0.22, 0}) do
				if not SaveButtonPulseActive or SaveButtonPulseToken ~= pulseToken then
					break
				end

				SaveButtonIcon.TextTransparency = transparency
				SaveButtonIcon.TextStrokeTransparency = math.clamp(transparency + 0.2, 0, 1)
				task.wait(0.45)
			end
		end

		if SaveButtonPulseToken == pulseToken then
			SaveButtonPulseActive = false
			if SaveButtonIcon and SaveButtonIcon.Parent then
				SaveButtonIcon.TextTransparency = 0
				SaveButtonIcon.TextStrokeTransparency = 0.2
			end
		end
	end)
end

UpdateSaveButtonVisual = function()
	if not SaveButton or not SaveButton.Parent then
		return
	end

	local isWaiting = SaveCooldownActive or SaveInProgress
	local baseBackground = CurrentTheme == "Dark" and CONFIG.Colors.Black or CONFIG.Colors.Dark
	local readyTint = Color3.fromRGB(107, 228, 137)
	local waitingTint = Color3.fromRGB(234, 76, 76)
	local neutralTint = CurrentTheme == "Dark" and Color3.fromRGB(255, 255, 255) or CONFIG.Colors.White

	local iconTint
	local buttonBackground
	local iconTransparency = 0

	if isWaiting then
		buttonBackground = baseBackground
		iconTint = waitingTint
		StartSaveButtonPulse()
	elseif not SettingsInitialized then
		buttonBackground = baseBackground
		iconTint = neutralTint
		StopSaveButtonPulse()
	elseif SettingsDirty then
		buttonBackground = baseBackground
		iconTint = readyTint
		StopSaveButtonPulse()
	else
		buttonBackground = baseBackground
		iconTint = neutralTint
		StopSaveButtonPulse()
	end

	SaveButton.BackgroundColor3 = buttonBackground
	SaveButtonIcon.TextColor3 = iconTint
	SaveButtonIcon.TextTransparency = iconTransparency
	SaveButtonIcon.TextStrokeTransparency = 0.2
	SaveButtonIcon.TextStrokeColor3 = CurrentTheme == "Dark" and Color3.fromRGB(31, 31, 31) or CONFIG.Colors.Border
	SaveButton.Active = SettingsInitialized
		and SettingsDirty
		and not SaveCooldownActive
		and not SaveInProgress
	SaveButton.Selectable = SaveButton.Active
end

local function ApplyLoadedSettings(settings)
	if typeof(settings) ~= "table" then
		return false
	end

	if settings.Theme == "Light" or settings.Theme == "Dark" then
		SetTheme(settings.Theme, false)
		Player:SetAttribute("SettingsTheme", settings.Theme)
	end

	if typeof(settings.NotificationsEnabled) == "boolean" then
		NotificationsEnabled = settings.NotificationsEnabled
	end
	if typeof(settings.ReducedMotionEnabled) == "boolean" then
		ReducedMotionEnabled = settings.ReducedMotionEnabled
	end
	if typeof(settings.PhotosensitivityProtectionEnabled) == "boolean" then
		PhotosensitivityProtectionEnabled = settings.PhotosensitivityProtectionEnabled
	end
	if typeof(settings.VibrationEnabled) == "boolean" then
		VibrationEnabled = settings.VibrationEnabled
	end
	if typeof(settings.InterfaceAnimationsEnabled) == "boolean" then
		InterfaceAnimationsEnabled = settings.InterfaceAnimationsEnabled
	end
	if typeof(settings.MusicEnabled) == "boolean" then
		MusicEnabled = settings.MusicEnabled
	end
	if typeof(settings.MusicVolume) == "number" then
		MusicVolume = math.clamp(settings.MusicVolume, 0, 1)
	end
	if typeof(settings.InterfaceSoundsEnabled) == "boolean" then
		InterfaceSoundsEnabled = settings.InterfaceSoundsEnabled
	end

	ApplyMusicState()
	SetOverlayGradientTheme(CurrentTheme, 0)
	return true
end

----------------------------------------------------------------
-- BODY
----------------------------------------------------------------

local Body =
	Create(
		"Frame",
		{
			Name = "Body",

			Parent = MainPanel,

			Position =
			UDim2.fromOffset(
				18,
				90
			),

			Size =
			UDim2.new(
				1,
				-36,
				1,
				-108
			),

			BackgroundTransparency = 1,

			ZIndex = 21,
		}
	)

----------------------------------------------------------------
-- SIDEBAR
----------------------------------------------------------------

local Sidebar =
	Create(
		"Frame",
		{
			Name = "Sidebar",

			Parent = Body,

			Size =
			UDim2.new(
				0,
				155,
				1,
				0
			),

			BackgroundColor3 =
			CONFIG.Colors.Dark,

			BorderSizePixel = 0,

			ZIndex = 22,
		}
	)

Corner(
	Sidebar,
	13
)

Stroke(
	Sidebar,
	CONFIG.Colors.Border,
	0.25,
	1
)

----------------------------------------------------------------
-- CATEGORY TITLE
----------------------------------------------------------------

local CategoryTitle =
	Create(
		"TextLabel",
		{
			Name = "CategoryTitle",

			Parent = Sidebar,

			Position =
			UDim2.fromOffset(
				10,
				8
			),

			Size =
			UDim2.new(
				1,
				-20,
				0,
				34
			),

			BackgroundTransparency = 1,

			Text = "Categorias",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 16,

			Font =
			Enum.Font.GothamBold,

			TextXAlignment =
			Enum.TextXAlignment.Center,

			TextYAlignment =
			Enum.TextYAlignment.Center,

			ZIndex = 23,
		}
	)

----------------------------------------------------------------
-- CATEGORY LIST
----------------------------------------------------------------

local CategoryList =
	Create(
		"ScrollingFrame",
		{
			Name = "CategoryList",

			Parent = Sidebar,

			Position =
			UDim2.fromOffset(
				6,
				48
			),

			Size =
			UDim2.new(
				1,
				-12,
				1,
				-54
			),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			CanvasSize =
			UDim2.fromOffset(
				0,
				0
			),

			AutomaticCanvasSize =
			Enum.AutomaticSize.Y,

			ScrollBarThickness = 2,

			ScrollBarImageColor3 =
			CONFIG.Colors.Secondary,

			ScrollBarImageTransparency = 0.4,

			ScrollingDirection =
			Enum.ScrollingDirection.Y,

			ZIndex = 23,
		}
	)

local CategoryLayout =
	Create(
		"UIListLayout",
		{
			Parent = CategoryList,

			Padding =
			UDim.new(
				0,
				5
			),

			SortOrder =
			Enum.SortOrder.LayoutOrder,

			HorizontalAlignment =
			Enum.HorizontalAlignment.Center,
		}
	)

----------------------------------------------------------------
-- PAGE AREA
----------------------------------------------------------------

local PageArea =
	Create(
		"Frame",
		{
			Name = "PageArea",

			Parent = Body,

			Position =
			UDim2.new(
				0,
				165,
				0,
				0
			),

			Size =
			UDim2.new(
				1,
				-165,
				1,
				0
			),

			BackgroundTransparency = 1,

			ZIndex = 22,
		}
	)

local PageTitle =
	Create(
		"TextLabel",
		{
			Name = "PageTitle",

			Parent = PageArea,

			Position =
			UDim2.fromOffset(
				0,
				0
			),

			Size =
			UDim2.new(
				1,
				0,
				0,
				28
			),

			BackgroundTransparency = 1,

			Text = "Geral",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 20,

			Font =
			Enum.Font.GothamBold,

			TextXAlignment =
			Enum.TextXAlignment.Left,

			ZIndex = 23,
		}
	)

local PageIcon =
	Create(
		"TextLabel",
		{
			Name = "PageIcon",

			Parent = PageArea,

			Position =
			UDim2.fromOffset(
				0,
				0
			),

			Size =
			UDim2.fromOffset(28, 28),

			BackgroundTransparency = 1,

			Text = "",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 22,

			Font =
			Enum.Font.GothamBold,

			TextXAlignment =
			Enum.TextXAlignment.Center,

			TextYAlignment =
			Enum.TextYAlignment.Center,

			Visible = false,

			ZIndex = 24,
		}
	)

local PageDescription =
	Create(
		"TextLabel",
		{
			Name = "PageDescription",

			Parent = PageArea,

			Position =
			UDim2.fromOffset(
				0,
				30
			),

			Size =
			UDim2.new(
				1,
				0,
				0,
				28
			),

			BackgroundTransparency = 1,

			Text = "",

			TextColor3 =
			CONFIG.Colors.Description,

			TextSize = 11,

			Font =
			Enum.Font.Gotham,

			TextWrapped = true,

			TextXAlignment =
			Enum.TextXAlignment.Left,

			TextYAlignment =
			Enum.TextYAlignment.Top,

			ZIndex = 23,
		}
	)

----------------------------------------------------------------
-- PAGE SCROLL
----------------------------------------------------------------

local PageScroll =
	Create(
		"ScrollingFrame",
		{
			Name = "PageScroll",

			Parent = PageArea,

			Position =
			UDim2.fromOffset(
				0,
				68
			),

			Size =
			UDim2.new(
				1,
				0,
				1,
				-68
			),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			CanvasSize =
			UDim2.fromOffset(
				0,
				0
			),

			AutomaticCanvasSize =
			Enum.AutomaticSize.None,

			ScrollingDirection =
			Enum.ScrollingDirection.Y,

			ScrollBarThickness = 3,

			ScrollBarImageColor3 =
			CONFIG.Colors.Secondary,

			ScrollBarImageTransparency = 1,

			ZIndex = 23,
		}
	)

local PageLayout =
	Create(
		"UIListLayout",
		{
			Parent = PageScroll,

			Padding =
			UDim.new(
				0,
				8
			),

			SortOrder =
			Enum.SortOrder.LayoutOrder,

			HorizontalAlignment =
			Enum.HorizontalAlignment.Center,
		}
	)

RegisterFadeTree(WindowControls)

----------------------------------------------------------------
-- CATEGORIES
----------------------------------------------------------------

local Categories = {

	{
		Name = "Geral",
		Icon = Icon("slack"),
		Description =
			"Preferências gerais da experiência.",
	},

	{
		Name = "Acessibilidade",
		Icon = Icon("key-command"),
		Description =
			"Recursos para tornar a experiência mais confortável.",
	},

	{
		Name = "Controles",
		Icon = Icon("two-switches-horizontal"),
		Description =
			"Configure sua forma de interação.",
	},

	{
		Name = "Interface",
		Icon = Icon("windows-app-restore"),
		Description =
			"Personalize elementos da interface.",
	},

	{
		Name = "Áudio",
		Icon = Icon("speaker"),
		Description =
			"Controle música e sons.",
	},

	{
		Name = "Sobre",
		Icon = Icon("square-dual-arrows-to-corner"),
		Description =
			"Informações da experiência e da interface.",
	},

	{
		Name = "Emote por ID",
		Icon = Icon("building-store"),
		Description =
			"Converta IDs de Emotes do Marketplace da plataforma Roblox em Animation IDs.",
	},
}

----------------------------------------------------------------
-- CATEGORY PRESENTATION
----------------------------------------------------------------

-- A apresentação do cabeçalho é independente dos títulos da sidebar.
-- Não animamos PageTitle aqui: categorias longas não devem alterar o
-- tamanho/posição do conteúdo da página durante a troca.
local CategoryPresentation = {
	["Emote por ID"] = {
		ShowTitle = true,
		ShowIcon = true,
	},
}

local function ApplyCategoryPresentation(categoryData)

	local presentation =
		CategoryPresentation[categoryData.Name]
		or {
			ShowTitle = true,
			ShowIcon = false,
		}

	PageTitle.Visible = presentation.ShowTitle == true
	PageIcon.Visible = presentation.ShowIcon == true

	if presentation.ShowIcon then
		PageIcon.Text = categoryData.Icon or ""
	end

	-- Sempre restaura o estado-base antes de aplicar a combinação escolhida.
	PageTitle.Position = UDim2.fromOffset(0, 0)
	PageTitle.Size = UDim2.new(1, 0, 0, 28)
	PageIcon.Position = UDim2.fromOffset(0, 0)
	PageIcon.Size = UDim2.fromOffset(28, 28)

	if presentation.ShowTitle and presentation.ShowIcon then
		PageTitle.Position = UDim2.fromOffset(36, 0)
		PageTitle.Size = UDim2.new(1, -36, 0, 28)
	end

	if presentation.ShowTitle or presentation.ShowIcon then
		PageDescription.Position = UDim2.fromOffset(0, 30)
	else
		PageDescription.Position = UDim2.fromOffset(0, 0)
	end

end

----------------------------------------------------------------
-- CATEGORY BUTTON
----------------------------------------------------------------

local function UpdateCategoryVisuals()

	for name, data in pairs(
		CategoryButtons
		) do

		local button =
			data.Button

		local label =
			data.Label

		local icon =
			data.Icon

		local selected =
			name == CurrentCategory

		Tween(
			button,
			{
				BackgroundTransparency =
					selected
					and 0
					or 1,

				BackgroundColor3 =
					CONFIG.Colors.Focus,
			},
			CONFIG.Animation.Fast
		)

		Tween(
			label,
			{
				TextColor3 =
					selected
					and CONFIG.Colors.White
					or CONFIG.Colors.Secondary,
			},
			CONFIG.Animation.Fast
		)

		Tween(
			icon,
			{
				TextColor3 =
					selected
					and CONFIG.Colors.White
					or CONFIG.Colors.Secondary,
			},
			CONFIG.Animation.Fast
		)

		-- Atualiza o alvo de Fade do botão.
		local fadeData =
			FadeRegistry[button]

		if fadeData then

			fadeData.BackgroundTransparency =
				selected
				and 0
				or 1

		end

	end

end


local function CreateCategoryButton(
category,
index
)

local categoryButtonHeight =
	44

	local button =
		Create(
			"TextButton",
			{
				Name =
				"Category_" ..
				category.Name,

				Parent =
				CategoryList,

				Size =
				UDim2.new(
					1,
					-4,
					0,
					categoryButtonHeight
				),

				BackgroundColor3 =
				CONFIG.Colors.Focus,

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				Text = "",

				AutoButtonColor = false,

				Selectable = true,

				LayoutOrder = index,

				ZIndex = 24,
			}
		)

	Corner(
		button,
		9
	)

	Stroke(
		button,
		CONFIG.Colors.Border,
		0.75,
		1
	)

	local scale =
		Create(
			"UIScale",
			{
				Parent = button,
				Scale = 1,
			}
		)

	local icon =
		Create(
			"TextLabel",
			{
				Parent = button,

				Position =
				UDim2.fromOffset(
					10,
					0
				),

				Size =
				UDim2.fromOffset(
					24,
					categoryButtonHeight
				),

				BackgroundTransparency = 1,

				Text =
				category.Icon,

				TextColor3 =
				CONFIG.Colors.Secondary,

				TextSize = 16,

				Font =
				Enum.Font.GothamBold,

				TextXAlignment =
				Enum.TextXAlignment.Center,

				TextYAlignment =
				Enum.TextYAlignment.Center,

				ZIndex = 25,
			}
		)

	local label =
		Create(
			"TextLabel",
			{
				Parent = button,

				Position =
				UDim2.fromOffset(
					40,
					0
				),

				Size =
				UDim2.new(
					1,
					-48,
					1,
					0
				),

				BackgroundTransparency = 1,

				Text =
				category.Name,

				TextColor3 =
				CONFIG.Colors.Secondary,

				TextSize = 14,

				Font =
				Enum.Font.GothamMedium,

				TextXAlignment =
				Enum.TextXAlignment.Left,

				TextYAlignment =
				Enum.TextYAlignment.Center,

				ZIndex = 25,
			}
		)

	CategoryButtons[
	category.Name
	] = {

		Button = button,
		Label = label,
		Icon = icon,
		Scale = scale,
	}

	RegisterFadeTree(button)

	----------------------------------------------------------------
	-- MOUSE
	----------------------------------------------------------------

	button.MouseEnter:Connect(function()

		if not CanInteract() then
			return
		end

		if CurrentCategory ~= category.Name then

			ApplySmartFocus(
				scale,
				true
			)

		end

	end)


	button.MouseLeave:Connect(function()

		ApplySmartFocus(
			scale,
			false
		)

	end)


	button.MouseButton1Down:Connect(function()

		if not CanInteract() then
			return
		end

		if ReducedMotionEnabled then
			return
		end

		PlayScale(
			scale,
			CONFIG.Interaction.PressScale,
			CONFIG.Animation.Press
		)

	end)


	button.MouseButton1Up:Connect(function()

		if not CanInteract() then
			return
		end

		PlayScale(
			scale,
			CONFIG.Interaction.FocusScale,
			CONFIG.Animation.Focus
		)

	end)

	----------------------------------------------------------------
	-- ACTIVATED
	----------------------------------------------------------------

	button.Activated:Connect(function()

		if not CanInteract() then
			return
		end

		if CurrentCategory ==
			category.Name
		then
			return
		end

		PlaySettingsSound(
			"CategoryButton"
		)

		BuildCategory(
			category.Name,
			true
		)

	end)

	----------------------------------------------------------------
	-- GAMEPAD
	----------------------------------------------------------------

	button.SelectionGained:Connect(function()

		ApplySmartFocus(
			scale,
			true
		)

	end)


	button.SelectionLost:Connect(function()

		ApplySmartFocus(
			scale,
			false
		)

	end)

end


----------------------------------------------------------------
-- SMART FOCUS
----------------------------------------------------------------

function ApplySmartFocus(
	scaleObject,
	focused
)

	if not scaleObject then
		return
	end

	if ReducedMotionEnabled then

		scaleObject.Scale = 1

		return

	end

	Tween(
		scaleObject,
		{
			Scale =
				focused
				and CONFIG.Interaction.FocusScale
				or 1
		},
		CONFIG.Interaction.FocusScale
			and CONFIG.Animation.Focus
			or 0.12
	)

end

----------------------------------------------------------------
-- CREATE CATEGORY BUTTONS
----------------------------------------------------------------

for index, category in ipairs(Categories) do

	CreateCategoryButton(
		category,
		index
	)

end

----------------------------------------------------------------
-- SETTING ROW
----------------------------------------------------------------

local function GetRowHeight()

if CurrentDevice == "Tablet" then
		return 74
	end

	if CurrentDevice == "Console" then
		return 72
	end

	if CurrentDevice == "TV" then
		return 76
	end

	return 62

end


local function CreateToggle(
	title,
	description,
	defaultValue,
	layoutOrder,
	onChanged
)

	local row =
		Create(
			"TextButton",
			{
				Name =
				"Setting_" ..
				title,

				Parent = PageScroll,

				Size =
				UDim2.new(
					1,
					-6,
					0,
					GetRowHeight()
				),

				BackgroundColor3 =
				CONFIG.Colors.Dark,

				BackgroundTransparency = 0,

				BorderSizePixel = 0,

				Text = "",

				AutoButtonColor = false,

				Selectable = true,

				LayoutOrder =
				layoutOrder or 1,

				ZIndex = 24,
			}
		)

	Corner(
		row,
		12
	)

	Stroke(
		row,
		CONFIG.Colors.Border,
		0.30,
		1
	)

	local rowScale =
		Create(
			"UIScale",
			{
				Parent = row,
				Scale = 1,
			}
		)

	local titleLabel =
		Create(
			"TextLabel",
			{
				Parent = row,

				Position =
				UDim2.fromOffset(
					16,
					8
				),

				Size =
				UDim2.new(
					1,
					-90,
					0,
					24
				),

				BackgroundTransparency = 1,

				Text = title,

				TextColor3 =
				CONFIG.Colors.White,

				TextSize = 15,

				Font =
				Enum.Font.GothamMedium,

				TextXAlignment =
				Enum.TextXAlignment.Left,

				ZIndex = 25,
			}
		)

	local descriptionLabel =
		Create(
			"TextLabel",
			{
				Parent = row,

				Position =
				UDim2.fromOffset(
					16,
					32
				),

				Size =
				UDim2.new(
					1,
					-90,
					0,
					20
				),

				BackgroundTransparency = 1,

				Text =
				description,

				TextColor3 =
				CONFIG.Colors.Description,

				TextSize = 11,

				Font =
				Enum.Font.Gotham,

				TextWrapped = true,

				TextXAlignment =
				Enum.TextXAlignment.Left,

				TextYAlignment =
				Enum.TextYAlignment.Top,

				ZIndex = 25,
			}
		)

	----------------------------------------------------------------
	-- TOGGLE
	----------------------------------------------------------------

	local toggle =
		Create(
			"Frame",
			{
				Name = "Toggle",

				Parent = row,

				AnchorPoint =
				Vector2.new(
					1,
					0.5
				),

				Position =
				UDim2.new(
					1,
					-16,
					0.5,
					0
				),

				Size =
				UDim2.fromOffset(
					42,
					24
				),

				BackgroundColor3 =
				CONFIG.Colors.Dark,

				BorderSizePixel = 0,

				ZIndex = 26,
			}
		)

	Corner(
		toggle,
		12
	)

	local toggleStroke =
		Stroke(
			toggle,
			CONFIG.Colors.Border,
			0.20,
			1
		)

	local knob =
		Create(
			"Frame",
			{
				Name = "Knob",

				Parent = toggle,

				AnchorPoint =
				Vector2.new(
					0,
					0.5
				),

				Position =
				UDim2.new(
					0,
					4,
					0.5,
					0
				),

				Size =
				UDim2.fromOffset(
					15,
					15
				),

				BackgroundColor3 =
				CONFIG.Colors.Secondary,

				BorderSizePixel = 0,

				ZIndex = 27,
			}
		)

	Corner(
		knob,
		8
	)

	local enabled =
		defaultValue == true

	local pressing = false
	local holdCompleted = false
	local pressToken = 0

	local function Set(
		value,
		instant
	)

		enabled = value == true

		local trackColor =
			enabled
			and CONFIG.Colors.White
			or CONFIG.Colors.Dark

		local knobColor =
			enabled
			and CONFIG.Colors.Black
			or CONFIG.Colors.Secondary

		local knobPosition =
			enabled
			and UDim2.new(
				1,
				-19,
				0.5,
				0
			)
			or UDim2.new(
				0,
				4,
				0.5,
				0
			)

		if instant then

			toggle.BackgroundColor3 =
				trackColor

			knob.BackgroundColor3 =
				knobColor

			knob.Position =
				knobPosition

		else

			Tween(
				toggle,
				{
					BackgroundColor3 =
						trackColor,
				},
				CONFIG.Animation.Fast
			)

			Tween(
				knob,
				{
					BackgroundColor3 =
						knobColor,

					Position =
						knobPosition,
				},
				CONFIG.Animation.Medium
			)

		end

		if not instant then

			PlaySettingsSound(
				"ButtonSwitch"
			)

			if onChanged then
				onChanged(enabled)
			end

			MarkSettingsDirty()

		end

	end

	local function CancelPress(
		token
	)

		if token
			and token ~= pressToken
		then
			return
		end

		pressing = false
		holdCompleted = false

		pressToken += 1

		Tween(
			rowScale,
			{
				Scale = 1,
			},
			CONFIG.Interaction.SwitchCancelDuration
		)

		Tween(
			knob,
			{
				Position =
					enabled
					and UDim2.new(
						1,
						-19,
						0.5,
						0
					)
					or UDim2.new(
						0,
						4,
						0.5,
						0
					),
			},
			CONFIG.Interaction.SwitchCancelDuration
		)

	end


	local function BeginPress()

		if not CanInteract() then
			return
		end

		if pressing then
			return
		end

		pressing = true
		holdCompleted = false

		pressToken += 1

		local token =
			pressToken

		if not ReducedMotionEnabled then

			Tween(
				rowScale,
				{
					Scale = 0.985,
				},
				CONFIG.Interaction.SwitchCancelDuration
			)

			Tween(
				knob,
				{
					Position =
						UDim2.new(
							0.5,
							-7.5,
							0.5,
							0
						),
				},
				CONFIG.Interaction.SwitchCenterDuration
			)

		end

		task.delay(
			CONFIG.Interaction.SwitchHoldDuration,
			function()

				if not IsValidToken(
					AnimationToken
					) then
					return
				end

				if token ~= pressToken then
					return
				end

				if not pressing then
					return
				end

				holdCompleted = true

				if not ReducedMotionEnabled then

					Tween(
						knob,
						{
							Size =
								UDim2.fromOffset(
									17,
									17
								),
						},
						0.10
					)

				end

			end
		)

	end


	local function FinishPress()

		if not pressing then
			return
		end

		pressing = false

		if not holdCompleted then

			CancelPress()

			return

		end

		holdCompleted = false

		Tween(
			rowScale,
			{
				Scale = 1,
			},
			CONFIG.Animation.Fast
		)

		Tween(
			knob,
			{
				Size =
					UDim2.fromOffset(
						15,
						15
					),
			},
			CONFIG.Animation.Fast
		)

		Set(
			not enabled,
			false
		)

	end


	Set(
		enabled,
		true
	)

	RegisterFadeTree(row)

	----------------------------------------------------------------
	-- INPUT
	----------------------------------------------------------------

	row.InputBegan:Connect(function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch
			or input.KeyCode ==
			Enum.KeyCode.ButtonA
		then

			BeginPress()

		end

	end)


	row.InputEnded:Connect(function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch
			or input.KeyCode ==
			Enum.KeyCode.ButtonA
		then

			FinishPress()

		end

	end)


	row.SelectionGained:Connect(function()

		ApplySmartFocus(
			rowScale,
			true
		)

	end)


	row.SelectionLost:Connect(function()

		ApplySmartFocus(
			rowScale,
			false
		)

		if pressing then
			CancelPress()
		end

	end)

	----------------------------------------------------------------
	-- STORE
	----------------------------------------------------------------

	table.insert(
		SettingRows,
		{
			Row = row,

			Title = titleLabel,

			Description =
				descriptionLabel,

			Toggle = toggle,

			Knob = knob,

			Set = Set,
		}
	)

	return row

end

----------------------------------------------------------------
-- INFO ROW
----------------------------------------------------------------

local function CreateInfoRow(
	title,
	description,
	layoutOrder
)

	local row =
		Create(
			"Frame",
			{
				Name =
				"Info_" ..
				title,

				Parent = PageScroll,

				Size =
				UDim2.new(
					1,
					-6,
					0,
					GetRowHeight()
				),

				BackgroundColor3 =
				CONFIG.Colors.Dark,

				BorderSizePixel = 0,

				LayoutOrder =
				layoutOrder or 1,

				ZIndex = 24,
			}
		)

	Corner(
		row,
		12
	)

	Stroke(
		row,
		CONFIG.Colors.Border,
		0.30,
		1
	)

	local titleLabel =
		Create(
			"TextLabel",
			{
				Parent = row,

				Position =
				UDim2.fromOffset(
					16,
					8
				),

				Size =
				UDim2.new(
					1,
					-32,
					0,
					24
				),

				BackgroundTransparency = 1,

				Text = title,

				TextColor3 =
				CONFIG.Colors.White,

				TextSize = 15,

				Font =
				Enum.Font.GothamMedium,

				TextXAlignment =
				Enum.TextXAlignment.Left,

				ZIndex = 25,
			}
		)

	Create(
		"TextLabel",
		{
			Parent = row,

			Position =
				UDim2.fromOffset(
					16,
					32
				),

			Size =
				UDim2.new(
					1,
					-32,
					0,
					20
				),

			BackgroundTransparency = 1,

			Text = description,

			TextColor3 =
				CONFIG.Colors.Description,

			TextSize = 11,

			Font =
				Enum.Font.Gotham,

			TextWrapped = true,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 25,
		}
	)

	RegisterFadeTree(row)

	table.insert(
		SettingRows,
		{
			Row = row,
			Title = titleLabel,
		}
	)

	return row

end


----------------------------------------------------------------
-- MUSIC VOLUME SLIDER
----------------------------------------------------------------

local function CreateMusicVolumeSlider(
	layoutOrder
)

	local rowHeight = 78

	local row =
		Create(
			"TextButton",
			{
				Name = "MusicVolume",
				Parent = PageScroll,
				Size = UDim2.new(1, -6, 0, rowHeight),
				BackgroundColor3 = CONFIG.Colors.Dark,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Selectable = true,
				LayoutOrder = layoutOrder or 1,
				ZIndex = 24,
			}
		)

	Corner(row, 12)
	Stroke(row, CONFIG.Colors.Border, 0.30, 1)

	local titleLabel =
		Create(
			"TextLabel",
			{
				Parent = row,
				Position = UDim2.fromOffset(16, 8),
				Size = UDim2.new(1, -100, 0, 22),
				BackgroundTransparency = 1,
				Text = "Volume da música",
				TextColor3 = CONFIG.Colors.White,
				TextSize = 15,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 25,
			}
		)

	local valueLabel =
		Create(
			"TextLabel",
			{
				Parent = row,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -16, 0, 8),
				Size = UDim2.fromOffset(60, 22),
				BackgroundTransparency = 1,
				TextColor3 = CONFIG.Colors.Secondary,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 25,
			}
		)

	local descriptionLabel =
		Create(
			"TextLabel",
			{
				Parent = row,
				Position = UDim2.fromOffset(16, 29),
				Size = UDim2.new(1, -32, 0, 18),
				BackgroundTransparency = 1,
				Text = "Ajuste o volume da música de fundo.",
				TextColor3 = CONFIG.Colors.Description,
				TextSize = 11,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 25,
			}
		)

	local bar =
		Create(
			"Frame",
			{
				Parent = row,
				Position = UDim2.new(0, 16, 1, -18),
				Size = UDim2.new(1, -32, 0, 5),
				BackgroundColor3 = CONFIG.Colors.Black,
				BorderSizePixel = 0,
				ZIndex = 26,
			}
		)

	Corner(bar, 3)

	local fill =
		Create(
			"Frame",
			{
				Parent = bar,
				Size = UDim2.new(MusicVolume, 0, 1, 0),
				BackgroundColor3 = CONFIG.Colors.White,
				BorderSizePixel = 0,
				ZIndex = 27,
			}
		)

	Corner(fill, 3)

	local knob =
		Create(
			"Frame",
			{
				Parent = bar,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(MusicVolume, 0, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				BackgroundColor3 = CONFIG.Colors.White,
				BorderSizePixel = 0,
				ZIndex = 28,
			}
		)

	Corner(knob, 7)

	local rowScale = Create("UIScale", {Parent = row, Scale = 1})

	local function UpdateVisual(instant)
		local percent = math.round(MusicVolume * 100)
		valueLabel.Text = tostring(percent) .. "%"

		local tweenTime = instant and 0 or CONFIG.Animation.Fast
		Tween(fill, {Size = UDim2.new(MusicVolume, 0, 1, 0)}, tweenTime)
		Tween(knob, {Position = UDim2.new(MusicVolume, 0, 0.5, 0)}, tweenTime)
	end

	local function SetVolumeFromX(x)
		if bar.AbsoluteSize.X <= 0 then
			return
		end

		local previousVolume = MusicVolume
		MusicVolume = math.clamp(
			(x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
			0,
			1
		)

		UpdateVisual(false)
		BackgroundMusic.Volume = MusicVolume
		ApplyMusicState()
		if MusicVolume ~= previousVolume then
			MarkSettingsDirty()
		end
	end

	local dragging = false
	local inputConnection

	local function BeginSliderInput(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			SetVolumeFromX(input.Position.X)
		end
	end

	row.InputBegan:Connect(function(input)
		BeginSliderInput(input)
	end)

	inputConnection = UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			SetVolumeFromX(input.Position.X)
		end
	end)

	row.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	row.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Left
			or input.KeyCode == Enum.KeyCode.DPadLeft
		then
			local previousVolume = MusicVolume
			MusicVolume = math.clamp(MusicVolume - 0.05, 0, 1)
			UpdateVisual(false)
			ApplyMusicState()
			if MusicVolume ~= previousVolume then
				MarkSettingsDirty()
			end
		elseif input.KeyCode == Enum.KeyCode.Right
			or input.KeyCode == Enum.KeyCode.DPadRight
		then
			local previousVolume = MusicVolume
			MusicVolume = math.clamp(MusicVolume + 0.05, 0, 1)
			UpdateVisual(false)
			ApplyMusicState()
			if MusicVolume ~= previousVolume then
				MarkSettingsDirty()
			end
		end
	end)

	row.AncestryChanged:Connect(function(_, parent)
		if parent == nil and inputConnection then
			inputConnection:Disconnect()
			inputConnection = nil
		end
	end)

	row.SelectionGained:Connect(function()
		ApplySmartFocus(rowScale, true)
	end)

	row.SelectionLost:Connect(function()
		ApplySmartFocus(rowScale, false)
	end)

	RegisterFadeTree(row)
	UpdateVisual(true)

	table.insert(
		SettingRows,
		{
			Row = row,
			Title = titleLabel,
			Description = descriptionLabel,
		}
	)

	return row

end

----------------------------------------------------------------
-- ABOUT CARD
----------------------------------------------------------------

local function CreateAboutCard(
	label,
	value,
	description,
	position,
	size,
	iconName,
	accentColor
)
	accentColor = accentColor or CONFIG.Colors.Secondary
	local device = DetectDevice()
	local compact = device == "Mobile" or device == "Tablet"
	local labelSize = compact and 13 or 16
	local valueSize = compact and 18 or 26
	local descriptionSize = compact and 11 or 12

	local card =
		Create(
			"Frame",
			{
				Name = "AboutCard_" .. label,
				Parent = PageScroll,
				Position = position,
				Size = size,
				BackgroundColor3 = CONFIG.Colors.Dark,
				BorderSizePixel = 0,
				ZIndex = 24,
			}
		)

	Corner(card, 18)

	local cardGradient =
		Create(
			"UIGradient",
			{
				Parent = card,
				Color =
				ColorSequence.new({
					ColorSequenceKeypoint.new(0, CONFIG.Colors.Dark),
					ColorSequenceKeypoint.new(1, CONFIG.Colors.Black),
				}),
				Rotation = 90,
			}
		)
	cardGradient.Enabled = true

	local accentStroke =
		Create(
			"UIStroke",
			{
				Parent = card,
				Color = accentColor,
				Transparency = 0.82,
				Thickness = 1.25,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}
		)

	local shine =
		Create(
			"Frame",
			{
				Parent = card,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = CONFIG.Colors.White,
				BackgroundTransparency = 0.96,
				BorderSizePixel = 0,
				ZIndex = 25,
			}
		)

	local iconWrap =
		Create(
			"Frame",
			{
				Parent = card,
				Position = UDim2.fromOffset(18, 18),
				Size = UDim2.fromOffset(54, 54),
				BackgroundColor3 = accentColor,
				BorderSizePixel = 0,
				ZIndex = 26,
			}
		)
	Corner(iconWrap, 16)

	local iconGlow =
		Create(
			"UIGradient",
			{
				Parent = iconWrap,
				Color =
				ColorSequence.new({
					ColorSequenceKeypoint.new(0, accentColor),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
				}),
				Rotation = 45,
			}
		)
	iconGlow.Enabled = true

	Create(
		"TextLabel",
		{
			Parent = iconWrap,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.fromScale(1, 1),
			Text = Icon(iconName or "square-dual-arrows-to-corner"),
			TextColor3 = CONFIG.Colors.White,
			TextSize = 22,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 27,
		}
	)

	Create(
		"TextLabel",
		{
			Parent = card,
			Position = UDim2.fromOffset(84, 22),
			Size = UDim2.new(1, -96, 0, 22),
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = CONFIG.Colors.White,
			TextSize = labelSize,
			Font = Enum.Font.Gotham,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 25,
		}
	)

	Create(
		"TextLabel",
		{
			Parent = card,
			Position = UDim2.fromOffset(84, 45),
			Size = UDim2.new(1, -96, 0, compact and 34 or 36),
			BackgroundTransparency = 1,
			Text = value,
			TextColor3 = CONFIG.Colors.White,
			TextSize = valueSize,
			Font = Enum.Font.GothamBold,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 25,
		}
	)

	Create(
		"TextLabel",
		{
			Parent = card,
			Position = UDim2.fromOffset(18, 96),
			Size = UDim2.new(1, -36, 0, compact and 48 or 44),
			BackgroundTransparency = 1,
			Text = description,
			TextColor3 = CONFIG.Colors.Description,
			TextSize = descriptionSize,
			Font = Enum.Font.Gotham,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 25,
		}
	)

	RegisterFadeTree(card)
	return card
end

----------------------------------------------------------------
-- CLEAR PAGE
----------------------------------------------------------------

local function UpdatePageScrollCanvasSize(extraPadding)
	if not PageScroll then
		return
	end

	local padding = extraPadding or 32
	local maxBottom = 0

	for _, child in ipairs(PageScroll:GetChildren()) do
		if child:IsA("GuiObject") then
			local absY = child.AbsolutePosition.Y - PageScroll.AbsolutePosition.Y
			local bottom = absY + child.AbsoluteSize.Y
			if bottom > maxBottom then
				maxBottom = bottom
			end
		end
	end

	PageScroll.CanvasSize = UDim2.new(
		0,
		0,
		0,
		math.max(maxBottom + padding, PageScroll.AbsoluteSize.Y)
	)
end

local function ClearPage()

	if PageLayout.Parent ~= PageScroll then
		PageLayout.Parent = PageScroll
	end

	for _, child in ipairs(
		PageScroll:GetChildren()
		) do

		if child:IsA("GuiObject") then

			child:Destroy()

		end

	end

	table.clear(
		SettingRows
	)

	PageScroll.CanvasSize = UDim2.fromOffset(0, 0)

end

----------------------------------------------------------------
-- BUILD PAGES
----------------------------------------------------------------

local EmoteConverterConnection = nil
local EmoteConverterTrack = nil
local EmoteConverterAnimation = nil
local EmoteConverterLoopEnabled = false
local EmoteConverterCountdownSeconds = 0
local EmoteConverterCountdownToken = 0
local CategoryTitleAnimationToken = 0

local function StopCategoryTitleAnimation()
	CategoryTitleAnimationToken += 1
end

local function BuildGeneral()

	CreateToggle(
		"Notificações",
		"Exibe notificações importantes da experiência.",
		NotificationsEnabled,
		1,
		function(value)
			NotificationsEnabled = value == true
		end
	)

end


local function BuildAccessibility()

	CreateToggle(
		"Reduzir efeitos visuais",
		"Reduz movimentos e efeitos visuais da interface.",
		ReducedMotionEnabled,
		1,

		function(value)

			ReducedMotionEnabled =
				value == true

		end
	)

	CreateToggle(
		"Proteção contra fotossensibilidade",
		"Recurso experimental de aviso e redução para testes de acessibilidade.",
		PhotosensitivityProtectionEnabled,
		2,

		function(value)

			PhotosensitivityProtectionEnabled =
				value == true

			if value
				and not PhotosensitivityConfirmed
			then

				OpenWarning()

			end

		end
	)

end


local function BuildControls()

	CreateInfoRow(
		"Controles",
		"Os controles podem variar de acordo com o dispositivo utilizado.",
		1
	)

	CreateToggle(
		"Vibração",
		"Permite feedback de vibração em dispositivos compatíveis.",
		VibrationEnabled,
		2,
		function(value)
			VibrationEnabled = value == true
		end
	)

end


local function BuildInterface()

	CreateToggle(
		"Animações da interface",
		"Ativa as animações e transições da interface.",
		InterfaceAnimationsEnabled,
		1,
		function(value)
			InterfaceAnimationsEnabled = value == true
		end
	)

	CreateToggle(
		"Modo reduzido",
		"Reduz movimento, escala e duração das animações / Reduz efeitos visuais da interface. \nObs : Tá meio bugado",
		ReducedMotionEnabled,
		2,

		function(value)

			ReducedMotionEnabled =
				value == true

		end
	)

end


local function BuildAudio()

	-- Seção Música: permanece dentro de Áudio e não cria uma nova categoria.
	CreateInfoRow(
		"Música",
		"Controle a música de fundo da experiência.",
		1
	)

	CreateToggle(
		"Música de fundo",
		"Ativa ou pausa a música principal da experiência.",
		MusicEnabled,
		2,

		function(value)
			MusicEnabled = value == true
			if MusicEnabled then
				if SecretSettingsTriggered then
					SecretSettingsTriggered = false
					CancelSecretSettingsTimer()
					RestoreSecretSettingsEnvironment()
					StopSecretSettingsMusic(2)
				end
			end
			ApplyMusicState()
		end
	)

	CreateMusicVolumeSlider(3)

	CreateInfoRow(
		"Sons",
		"Controle os sons produzidos pela experiência e pela interface.",
		4
	)

	CreateToggle(
		"Sons da interface",
		"Controla sons produzidos pela interface.",
		InterfaceSoundsEnabled,
		5,

		function(value)

			InterfaceSoundsEnabled =
				value == true

		end
	)

	ApplyMusicState()

end

local function BuildEmoteConverter()

	local ReplicatedStorage =
		game:GetService("ReplicatedStorage")

	local currentAnimationId = nil
	local requestBusy = false
	local requestToken = 0

	local function SetStatus(label, text, role)
		if label and label.Parent then
			label.Text = text
			label.TextColor3 =
				role == "Success"
				and CONFIG.Colors.Focus
				or role == "Warning"
				and CONFIG.Colors.Warning
				or role == "Error"
				and CONFIG.Colors.Warning
				or CONFIG.Colors.Description
		end
	end

	if EmoteConverterConnection then
		EmoteConverterConnection:Disconnect()
		EmoteConverterConnection = nil
	end

	if EmoteConverterTrack then
		pcall(function()
			EmoteConverterTrack:Stop(0.15)
			EmoteConverterTrack:Destroy()
		end)
		EmoteConverterTrack = nil
	end

	local card =
		Create(
			"Frame",
			{
				Name = "EmoteConverterCard",
				Parent = PageScroll,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(1, -14, 0, 430),
				ClipsDescendants = true,
				BackgroundColor3 = CONFIG.Colors.Dark,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				ZIndex = 24,
			}
		)

	Corner(card, 14)
	Stroke(card, CONFIG.Colors.Border, 0.25, 1)
	RegisterFadeTree(card)

	Create(
		"TextLabel",
		{
			Parent = card,
			Position = UDim2.fromOffset(16, 14),
			Size = UDim2.new(1, -32, 0, 22),
			BackgroundTransparency = 1,
			Text = "Emote por ID",
			TextColor3 = CONFIG.Colors.White,
			TextSize = 15,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 25,
		}
	)

	local input =
		Create(
			"TextBox",
			{
				Name = "MarketplaceIDInput",
				Parent = card,
				Position = UDim2.fromOffset(16, 43),
				Size = UDim2.new(1, -32, 0, 42),
				BackgroundColor3 = CONFIG.Colors.Black,
				BorderSizePixel = 0,
				ClearTextOnFocus = false,
				PlaceholderText = "Ex.: 1234567890 ou URL do catálogo",
				PlaceholderColor3 = CONFIG.Colors.Secondary,
				Text = "",
				TextColor3 = CONFIG.Colors.White,
				TextSize = 13,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 25,
			}
		)

	Corner(input, 10)
	Stroke(input, CONFIG.Colors.Border, 0.25, 1)

	local convertButton =
		Create(
			"TextButton",
			{
				Parent = card,
				Position = UDim2.fromOffset(16, 94),
				Size = UDim2.new(1, -32, 0, 42),
				BackgroundColor3 = CONFIG.Colors.Focus,
				BorderSizePixel = 0,
				Text = "CONVERTER ID",
				TextColor3 = CONFIG.Colors.White,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Selectable = true,
				ZIndex = 25,
			}
		)

	Corner(convertButton, 10)
	Stroke(convertButton, CONFIG.Colors.Border, 0.20, 1)

	local emoteName =
		Create(
			"TextLabel",
			{
				Parent = card,
				Position = UDim2.fromOffset(16, 147),
				Size = UDim2.new(1, -32, 0, 20),
				BackgroundTransparency = 1,
				Text = "Emote: —",
				TextColor3 = CONFIG.Colors.White,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 25,
			}
		)

	local animationIdLabel =
		Create(
			"TextLabel",
			{
				Parent = card,
				Position = UDim2.fromOffset(16, 169),
				Size = UDim2.new(1, -32, 0, 20),
				BackgroundTransparency = 1,
				Text = "Animation ID: —",
				TextColor3 = CONFIG.Colors.Secondary,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 25,
			}
		)

	local resultBox =
		Create(
			"TextBox",
			{
				Name = "AnimationResult",
				Parent = card,
				Position = UDim2.fromOffset(16, 194),
				Size = UDim2.new(1, -32, 0, 38),
				BackgroundColor3 = CONFIG.Colors.Black,
				BorderSizePixel = 0,
				ClearTextOnFocus = false,
				Text = "",
				PlaceholderText = "rbxassetid://...",
				PlaceholderColor3 = CONFIG.Colors.Secondary,
				TextColor3 = CONFIG.Colors.White,
				TextSize = 12,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 25,
			}
		)

	Corner(resultBox, 10)
	Stroke(resultBox, CONFIG.Colors.Border, 0.25, 1)

	local copyButton =
		Create(
			"TextButton",
			{
				Parent = card,
				Position = UDim2.fromOffset(16, 243),
				Size = UDim2.new(0.32, -12, 0, 34),
				BackgroundColor3 = CONFIG.Colors.Dark,
				BorderSizePixel = 0,
				Text = "COPIAR",
				TextColor3 = CONFIG.Colors.White,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Selectable = true,
				ZIndex = 25,
			}
		)

	local playButton =
		Create(
			"TextButton",
			{
				Parent = card,
				Position = UDim2.new(0.34, -6, 0, 243),
				Size = UDim2.new(0.32, -12, 0, 34),
				BackgroundColor3 = CONFIG.Colors.Dark,
				BorderSizePixel = 0,
				Text = "PLAY",
				TextColor3 = CONFIG.Colors.White,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Selectable = true,
				ZIndex = 25,
			}
		)

	local stopButton =
		Create(
			"TextButton",
			{
				Parent = card,
				Position = UDim2.new(0.68, 0, 0, 243),
				Size = UDim2.new(0.32, -16, 0, 34),
				BackgroundColor3 = CONFIG.Colors.Dark,
				BorderSizePixel = 0,
				Text = "STOP",
				TextColor3 = CONFIG.Colors.White,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Selectable = true,
				ZIndex = 25,
			}
		)

	for _, button in ipairs({copyButton, playButton, stopButton}) do
		Corner(button, 9)
		Stroke(button, CONFIG.Colors.Border, 0.25, 1)
	end

	local loopButton =
		Create(
			"TextButton",
			{
				Parent = card,
				Position = UDim2.fromOffset(16, 286),
				Size = UDim2.new(0.32, -12, 0, 34),
				BackgroundColor3 = CONFIG.Colors.Dark,
				BorderSizePixel = 0,
				Text = "LOOP: OFF",
				TextColor3 = CONFIG.Colors.Secondary,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Selectable = true,
				ZIndex = 25,
			}
		)
	Corner(loopButton, 9)
	Stroke(loopButton, CONFIG.Colors.Border, 0.25, 1)

	local countdownInput =
		Create(
			"TextBox",
			{
				Parent = card,
				Position = UDim2.new(0.34, -6, 0, 286),
				Size = UDim2.new(0.32, -12, 0, 34),
				BackgroundColor3 = CONFIG.Colors.Black,
				BorderSizePixel = 0,
				ClearTextOnFocus = false,
				PlaceholderText = "Countdown (0 = imediato)",
				PlaceholderColor3 = CONFIG.Colors.Secondary,
				Text = "0",
				TextColor3 = CONFIG.Colors.White,
				TextSize = 11,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 25,
			}
		)
	Corner(countdownInput, 9)
	Stroke(countdownInput, CONFIG.Colors.Border, 0.25, 1)

	local countdownPlayButton =
		Create(
			"TextButton",
			{
				Parent = card,
				Position = UDim2.new(0.68, 0, 0, 286),
				Size = UDim2.new(0.32, -16, 0, 34),
				BackgroundColor3 = CONFIG.Colors.Dark,
				BorderSizePixel = 0,
				Text = "PLAY + COUNTDOWN",
				TextColor3 = CONFIG.Colors.White,
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Selectable = true,
				ZIndex = 25,
			}
		)
	Corner(countdownPlayButton, 9)
	Stroke(countdownPlayButton, CONFIG.Colors.Border, 0.25, 1)

	local status =
		Create(
			"TextLabel",
			{
				Parent = card,
				Position = UDim2.fromOffset(16, 326),
				Size = UDim2.new(1, -32, 0, 34),
				BackgroundTransparency = 1,
				Text = "Pronto. Digite um ID de Emote do Marketplace.",
				TextColor3 = CONFIG.Colors.Description,
				TextSize = 11,
				Font = Enum.Font.Gotham,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 25,
			}
		)

	local function GetAnimator()
		local character = Player.Character
		if not character then
			character = Player.CharacterAdded:Wait()
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return nil
		end

		return humanoid:FindFirstChildOfClass("Animator")
			or humanoid:WaitForChild("Animator", 5)
	end

	local function StopAnimation(silent)
		if EmoteConverterTrack then
			pcall(function()
				EmoteConverterTrack:Stop(0.15)
				EmoteConverterTrack:Destroy()
			end)
			EmoteConverterTrack = nil
		end
		if EmoteConverterAnimation then
			pcall(function() EmoteConverterAnimation:Destroy() end)
			EmoteConverterAnimation = nil
		end
		EmoteConverterCountdownToken += 1

		if not silent then
			SetStatus(status, "Animação parada.")
		end
	end

	local function PlayAnimation()
		if not currentAnimationId then
			SetStatus(status, "Nenhuma Animation ID disponível.", "Warning")
			return
		end

		local animator = GetAnimator()
		if not animator then
			SetStatus(status, "Não foi possível encontrar o Animator.", "Error")
			return
		end

		StopAnimation(true)

		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. tostring(currentAnimationId)

		local success, trackOrError = pcall(function()
			return animator:LoadAnimation(animation)
		end)

		if not success or not trackOrError then
			animation:Destroy()
			SetStatus(status, "Falhou: a Animation não pôde ser carregada.", "Error")
			return
		end

		EmoteConverterAnimation = animation
		EmoteConverterTrack = trackOrError
		EmoteConverterTrack.Priority = Enum.AnimationPriority.Action
		EmoteConverterTrack.Looped = EmoteConverterLoopEnabled

		local played = pcall(function()
			EmoteConverterTrack:Play(0.15, 1, 1)
		end)

		if played then
			SetStatus(
				status,
				EmoteConverterLoopEnabled
					and "FUNCIONOU! Emote em loop."
					or "FUNCIONOU! A animação está sendo reproduzida.",
				"Success"
			)
		else
			SetStatus(status, "Falhou ao iniciar a animação.", "Error")
		end
	end

	local function ReadCountdown()
		local value = tonumber(countdownInput.Text) or 0
		value = math.clamp(value, 0, 60)
		countdownInput.Text = tostring(value)
		EmoteConverterCountdownSeconds = value
		return value
	end

	local function PlayWithCountdown()
		local seconds = ReadCountdown()
		if seconds <= 0 then
			PlayAnimation()
			return
		end
		if not currentAnimationId then
			SetStatus(status, "Nenhuma Animation ID disponível.", "Warning")
			return
		end

		EmoteConverterCountdownToken += 1
		local token = EmoteConverterCountdownToken

		task.spawn(function()
			for remaining = math.ceil(seconds), 1, -1 do
				if token ~= EmoteConverterCountdownToken then return end
				SetStatus(status, "Emote começa em " .. tostring(remaining) .. "...", "Warning")
				task.wait(1)
			end
			if token == EmoteConverterCountdownToken then
				PlayAnimation()
			end
		end)
	end


	local function ConnectRemote(remote)
		if EmoteConverterConnection then
			EmoteConverterConnection:Disconnect()
		end

		EmoteConverterConnection = remote.OnClientEvent:Connect(function(action, data)
			if action ~= "Result" then
				return
			end

			requestBusy = false
			requestToken += 1

			if not data or data.Success ~= true then
				currentAnimationId = nil
				animationIdLabel.Text = "Animation ID: —"
				emoteName.Text = "Emote: —"
				resultBox.Text = ""
				SetStatus(
					status,
					"NÃO FUNCIONOU: " .. tostring(data and data.Message or "erro desconhecido"),
					"Error"
				)
				return
			end

			currentAnimationId = data.AnimationId
			emoteName.Text = "Emote: " .. tostring(data.Name or "Desconhecido")
			animationIdLabel.Text = "Animation ID: " .. tostring(data.AnimationId)
			resultBox.Text = "rbxassetid://" .. tostring(data.AnimationId)

			SetStatus(
				status,
				"Conversão concluída! Clique em PLAY para testar.",
				"Success"
			)
		end)
	end

	local function GetRemote()
		local remote =
			ReplicatedStorage:FindFirstChild("EmoteConverterRemote")

		if not remote then
			SetStatus(
				status,
				"EmoteConverterRemote não foi encontrado no ReplicatedStorage.",
				"Error"
			)
			return nil
		end

		if not remote:IsA("RemoteEvent") then
			SetStatus(
				status,
				"EmoteConverterRemote não é um RemoteEvent válido.",
				"Error"
			)
			return nil
		end

		ConnectRemote(remote)
		return remote
	end

	local function Convert()
		if requestBusy then
			return
		end

		local raw =
			input.Text:gsub("%s+", "")

		if raw == "" then
			SetStatus(status, "Digite um Marketplace Emote ID.", "Warning")
			return
		end

		local id = raw:match("%d+")
		if not id then
			SetStatus(status, "ID inválido.", "Error")
			return
		end

		local remote = GetRemote()
		if not remote then
			return
		end

		requestBusy = true
		requestToken += 1
		local token = requestToken

		SetStatus(status, "Consultando o Marketplace...", nil)
		resultBox.Text = ""
		animationIdLabel.Text = "Animation ID: procurando..."
		emoteName.Text = "Emote: procurando..."

		local success, err = pcall(function()
			remote:FireServer("Convert", tonumber(id))
		end)

		if not success then
			requestBusy = false
			SetStatus(status, "Falha ao enviar a solicitação: " .. tostring(err), "Error")
			return
		end

		task.delay(15, function()
			if requestBusy and token == requestToken then
				requestBusy = false
				SetStatus(status, "Tempo esgotado. O servidor não respondeu.", "Error")
			end
		end)
	end

	convertButton.Activated:Connect(Convert)
	playButton.Activated:Connect(PlayAnimation)
	countdownPlayButton.Activated:Connect(PlayWithCountdown)
	loopButton.Activated:Connect(function()
		EmoteConverterLoopEnabled = not EmoteConverterLoopEnabled
		loopButton.Text = EmoteConverterLoopEnabled and "LOOP: ON" or "LOOP: OFF"
		loopButton.TextColor3 = EmoteConverterLoopEnabled and CONFIG.Colors.White or CONFIG.Colors.Secondary
		if EmoteConverterTrack then
			EmoteConverterTrack.Looped = EmoteConverterLoopEnabled
		end
	end)
	countdownInput.FocusLost:Connect(function()
		ReadCountdown()
	end)
	stopButton.Activated:Connect(function()
		StopAnimation(false)
	end)

	copyButton.Activated:Connect(function()
		if not currentAnimationId then
			SetStatus(status, "Não existe Animation ID para copiar.", "Warning")
			return
		end

		resultBox:CaptureFocus()
		resultBox.SelectionStart = 1
		resultBox.CursorPosition = #resultBox.Text + 1

		SetStatus(status, "ID selecionado. Pressione Ctrl+C para copiar.", "Success")
	end)

	input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			Convert()
		end
	end)

	-- A conexão só é criada enquanto esta página está ativa.
	local remote =
		ReplicatedStorage:FindFirstChild("EmoteConverterRemote")
	if remote and remote:IsA("RemoteEvent") then
		ConnectRemote(remote)
	else
		SetStatus(status, "Pronto. O Remote será localizado ao converter.")
	end


	table.insert(
		SettingRows,
		{
			Row = card,
			Title = nil,
			Description = nil,
			FixedHeight = true,
		}
	)

end

local function BuildAbout()
	if not PageScroll or not MainPanel then
		return
	end

	local device = DetectDevice()
	local compact = device == "Mobile"
	local scale = math.max(MainScale and MainScale.Scale or 1, 0.01)
	local pageWidth = PageScroll.AbsoluteSize.X / scale
	if pageWidth <= 0 then
		pageWidth = math.max(MainPanel.AbsoluteSize.X / scale - 220, 280)
	end
	pageWidth = math.max(pageWidth, 280)

	local sidePadding = compact and 12 or 24
	local horizontalGap = compact and 12 or 18
	local verticalGap = compact and 12 or 18
	local contentTopPadding = compact and 12 or 16
	local cardHeight = compact and 182 or 190
	local minCardWidth = compact and 180 or 220
	local columns = 1

	if device == "Mobile" then
		columns = pageWidth >= 560 and 2 or 1
	elseif device == "Tablet" then
		columns = pageWidth >= 760 and 2 or 1
	elseif device == "Console" or device == "TV" then
		columns = pageWidth >= 1200 and 3 or 2
	else
		columns = math.clamp(
			math.floor((pageWidth - sidePadding * 2 + horizontalGap) / (minCardWidth + horizontalGap)),
			1,
			3
		)
	end

	columns = math.clamp(columns, 1, 3)
	local cardWidth = math.floor((pageWidth - sidePadding * 2 - horizontalGap * (columns - 1)) / columns)
	PageLayout.Parent = nil

	local cardData = {
		{ "Versão do jogo", "2026.1.0", "Identificação da versão atual da experiência.", "clock-spin-reverse-dashed", Color3.fromRGB(83, 148, 255) },
		{ "Sobre a experiência", "Mansão da Barra", "Uma experiência social de convivência, interpretação e exploração.", "circle-i", Color3.fromRGB(183, 112, 255) },
		{ "Desempenho", "Experiência otimizada", "Recursos e interface projetados para uma navegação fluida.", "lightning-bolt", Color3.fromRGB(91, 255, 176) },
		{ "Personalização", "Sua experiência, suas escolhas", "Preferências visuais e opções de interface disponíveis no jogo.", "two-rulers-cursor", Color3.fromRGB(232, 118, 255) },
		{ "Comunidade", "Respeito faz parte do jogo", "Informações sobre convivência, respeito entre jogadores e comportamento esperado.", "three-people", Color3.fromRGB(91, 140, 255) },
	}

	local rowsNeeded = math.ceil(#cardData / columns)
	for index, data in ipairs(cardData) do
		local label, value, description, iconName, accentColor = data[1], data[2], data[3], data[4], data[5]
		local column = (index - 1) % columns
		local row = math.floor((index - 1) / columns)
		local x = sidePadding + column * (cardWidth + horizontalGap)
		local y = contentTopPadding + row * (cardHeight + verticalGap)

		CreateAboutCard(
			label,
			value,
			description,
			UDim2.fromOffset(x, y),
			UDim2.fromOffset(cardWidth, cardHeight),
			iconName,
			accentColor
		)
	end

	local footer =
		Create(
			"Frame",
			{
				Parent = PageScroll,
				Position = UDim2.fromOffset(0, contentTopPadding + rowsNeeded * (cardHeight + verticalGap) + 8),
				Size = UDim2.new(1, -20, 0, 48),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 22,
			}
		)

	local footerWidth = math.max(pageWidth - 20, 0)
	local showFooterTagline = footerWidth >= 520

	Create(
		"TextLabel",
		{
			Parent = footer,
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.new(0, 180, 0, 28),
			BackgroundTransparency = 1,
			Text = "Settings UI | Build 2026",
			TextColor3 = CONFIG.Colors.White,
			TextSize = 15,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 23,
		}
	)

	if showFooterTagline then
		Create(
			"TextLabel",
			{
				Parent = footer,
				Position = UDim2.new(1, -300, 0, 10),
				Size = UDim2.new(0, 290, 0, 28),
				BackgroundTransparency = 1,
				Text = "Inovação • Desempenho • Experiência",
				TextColor3 = CONFIG.Colors.Description,
				TextSize = 14,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 23,
			}
		)
	end
	RegisterFadeTree(footer)

	UpdatePageScrollCanvasSize(32)

end

----------------------------------------------------------------
-- BUILD CATEGORY
----------------------------------------------------------------

function BuildCategory(
	categoryName,
	animate,
	force
)

	if Transitioning
		and not force
	then
		return
	end

	local categoryData

	for _, category in ipairs(
		Categories
		) do

		if category.Name ==
			categoryName
		then

			categoryData =
				category

			break

		end

	end

	if not categoryData then
		return
	end

	CurrentCategory =
		categoryName

	-- Mantém a última categoria visitada disponível para o próximo abrir.
	SavedCategory = CurrentCategory

	if EmoteConverterConnection and categoryName ~= "Emote por ID" then
		EmoteConverterConnection:Disconnect()
		EmoteConverterConnection = nil
	end

	if EmoteConverterTrack and categoryName ~= "Emote por ID" then
		pcall(function()
			EmoteConverterTrack:Stop(0.15)
			EmoteConverterTrack:Destroy()
		end)
		EmoteConverterTrack = nil
	end

	UpdateCategoryVisuals()

	-- Evita o frame intermediário em que os elementos recém-criados
	-- podem ser renderizados antes do layout/fade terminar de ser
	-- aplicado. O PageScroll só volta a ficar visível depois que a
	-- categoria foi completamente construída.
	local pageWasVisible = PageScroll.Visible
	PageScroll.Visible = false

	ClearPage()

	PageTitle.Text =
		categoryData.Name

	PageDescription.Text =
		categoryData.Description

	ApplyCategoryPresentation(categoryData)

	if categoryName == "Geral" then

		BuildGeneral()

	elseif categoryName == "Acessibilidade" then

		BuildAccessibility()

	elseif categoryName == "Controles" then

		BuildControls()

	elseif categoryName == "Interface" then

		BuildInterface()

	elseif categoryName == "Áudio" then

		BuildAudio()

	elseif categoryName == "Sobre" then

		BuildAbout()

	elseif categoryName == "Emote por ID" then

		BuildEmoteConverter()

	end

	-- Agora que todos os elementos, constraints, tamanhos responsivos
	-- e registros de fade já existem, podemos exibir a página.
	PageScroll.Visible = pageWasVisible
	UpdatePageScrollCanvasSize(32)

	if not animate then
		if CurrentCategory == "Sobre" and FullscreenEnabled then
			if type(ApplyResponsiveUIScale) == "function" then
				local currentScale = ApplyResponsiveUIScale(DetectDevice())
				if MainScale then
					MainScale.Scale = currentScale
				end
			end
		end
		return
	end

	local token =
		AnimationToken

	PageTitle.TextTransparency =
		PageTitle.Visible and 1 or 0
	PageIcon.TextTransparency =
		PageIcon.Visible and 1 or 0
	PageDescription.TextTransparency = 1

	if PageTitle.Visible then
		Tween(
			PageTitle,
			{
				TextTransparency = 0,
			},
			0.20
		)
	end

	if PageIcon.Visible then
		Tween(
			PageIcon,
			{
				TextTransparency = 0,
			},
			0.20
		)
	end

	Tween(
		PageDescription,
		{
			TextTransparency = 0,
		},
		0.22
	)

	for index, data in ipairs(
		SettingRows
		) do

		local row =
			data.Row

		if row
			and row.Parent
		then

			local title =
				data.Title

			local description =
				data.Description

			if title then
				title.TextTransparency = 1
			end

			if description then
				description.TextTransparency = 1
			end

			task.delay(
				(index - 1)
					* CONFIG.Animation.Stagger,

				function()

					if token ~= AnimationToken then
						return
					end

					if not row.Parent then
						return
					end

					if title then

						Tween(
							title,
							{
								TextTransparency = 0,
							},
							CONFIG.Animation.Medium
						)

					end

					if description then

						Tween(
							description,
							{
								TextTransparency = 0,
							},
							CONFIG.Animation.Medium
						)

					end

				end
			)

		end

	end

end

----------------------------------------------------------------
-- WARNING PANEL
----------------------------------------------------------------

local WarningPanel =
	Create(
		"Frame",
		{
			Name = "WarningPanel",

			Parent = ScreenGui,

			AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

			Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

			Size =
			UDim2.fromOffset(
				540,
				430
			),

			BackgroundColor3 =
			CONFIG.Colors.Black,

			BorderSizePixel = 0,

			Visible = false,

			ZIndex = 60,
		}
	)

Corner(
	WarningPanel,
	16
)

Stroke(
	WarningPanel,
	CONFIG.Colors.Border,
	0.15,
	1
)

local WarningScale =
	Create(
		"UIScale",
		{
			Parent = WarningPanel,
			Scale = 0.94,
		}
	)

local WarningIcon =
	Create(
		"ImageLabel",
		{
			Parent = WarningPanel,

			Position =
			UDim2.fromOffset(
				22,
				22
			),

			Size =
			UDim2.fromOffset(
				30,
				30
			),

			BackgroundTransparency = 1,

			Image =
			CONFIG.Topbar.WarningIcon,

			ImageColor3 =
			CONFIG.Colors.Warning,

			ZIndex = 62,
		}
	)

local WarningTitle =
	Create(
		"TextLabel",
		{
			Parent = WarningPanel,

			Position =
			UDim2.fromOffset(
				62,
				17
			),

			Size =
			UDim2.new(
				1,
				-115,
				0,
				48
			),

			BackgroundTransparency = 1,

			Text =
			"Atenção aos usuários\ncom sensibilidade à luz",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 17,

			Font =
			Enum.Font.GothamBold,

			TextWrapped = true,

			TextXAlignment =
			Enum.TextXAlignment.Left,

			TextYAlignment =
			Enum.TextYAlignment.Center,

			ZIndex = 62,
		}
	)

local WarningClose =
	Create(
		"TextButton",
		{
			Parent = WarningPanel,

			AnchorPoint =
			Vector2.new(
				1,
				0
			),

			Position =
			UDim2.new(
				1,
				-18,
				0,
				18
			),

			Size =
			UDim2.fromOffset(
				34,
				34
			),

			BackgroundColor3 =
			CONFIG.Colors.Dark,

			BorderSizePixel = 0,

			Text = "×",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 23,

			Font =
			Enum.Font.GothamMedium,

			AutoButtonColor = false,

			Selectable = true,

			ZIndex = 63,
		}
	)

Corner(
	WarningClose,
	10
)

Stroke(
	WarningClose,
	CONFIG.Colors.Border,
	0.25,
	1
)

----------------------------------------------------------------
----------------------------------------------------------------
-- WARNING "SAIBA MAIS"
----------------------------------------------------------------

local WarningMore =
	Create(
		"TextButton",
		{
			Parent = WarningPanel,

			AnchorPoint =
			Vector2.new(
				0.5,
				0
			),

			Position =
			UDim2.new(
				0.5,
				0,
				0,
				315
			),

			Size =
			UDim2.fromOffset(
				80,
				22
			),

			BackgroundColor3 =
			CONFIG.Colors.Dark,

			BorderSizePixel = 0,

			Text =
			"Saiba mais",

			TextColor3 =
			CONFIG.Colors.Warning,

			TextSize = 10,

			Font =
			Enum.Font.GothamBold,

			AutoButtonColor = false,

			Selectable = true,

			ZIndex = 66,
		}
	)

Corner(
	WarningMore,
	8
)

Stroke(
	WarningMore,
	CONFIG.Colors.Border,
	0.25,
	1
)

----------------------------------------------------------------
-- WARNING CONTENT
----------------------------------------------------------------

local WarningContent =
	Create(
		"TextLabel",
		{
			Parent = WarningPanel,

			Position =
			UDim2.fromOffset(
				24,
				85
			),

			Size =
			UDim2.new(
				1,
				-48,
				0,
				145
			),

			BackgroundTransparency = 1,

			Text =
			"Esta experiência pode utilizar efeitos visuais, " ..
			"mudanças de iluminação, partículas, movimentos " ..
			"e transições de interface.\n\n" ..

			"Alguns usuários podem apresentar desconforto " ..
			"ao visualizar determinados efeitos luminosos ou " ..
			"movimentos rápidos.\n\n" ..

			"Se você possui sensibilidade a esses efeitos, " ..
			"recomenda-se utilizar o modo reduzido.",

			TextColor3 =
			CONFIG.Colors.Description,

			TextSize = 13,

			Font =
			Enum.Font.Gotham,

			TextWrapped = true,

			TextXAlignment =
			Enum.TextXAlignment.Left,

			TextYAlignment =
			Enum.TextYAlignment.Top,

			ZIndex = 62,
		}
	)

----------------------------------------------------------------
-- WARNING BOX
----------------------------------------------------------------

local WarningBox =
	Create(
		"Frame",
		{
			Parent = WarningPanel,

			Position =
			UDim2.fromOffset(
				24,
				245
			),

			Size =
			UDim2.new(
				1,
				-48,
				0,
				65
			),

			BackgroundColor3 =
			CONFIG.Colors.WarningDark,

			BorderSizePixel = 0,

			ZIndex = 62,
		}
	)

Corner(
	WarningBox,
	10
)

Stroke(
	WarningBox,
	CONFIG.Colors.Warning,
	0.20,
	1
)

Create(
	"TextLabel",
	{
		Parent = WarningBox,

		Position =
			UDim2.fromOffset(
				14,
				8
			),

		Size =
			UDim2.new(
				1,
				-28,
				1,
				-16
			),

		BackgroundTransparency = 1,

		Text =
			"Este aviso é experimental e faz parte dos " ..
			"testes de acessibilidade da versão privada.",

		TextColor3 =
			CONFIG.Colors.Warning,

		TextSize = 12,

		Font =
			Enum.Font.GothamMedium,

		TextWrapped = true,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextYAlignment =
			Enum.TextYAlignment.Center,

		ZIndex = 63,
	}
)

----------------------------------------------------------------
-- WARNING EMERGENCY INFO
----------------------------------------------------------------

local EmergencyLabel =
	Create(
		"TextLabel",
		{
			Parent = WarningPanel,

			Position =
			UDim2.fromOffset(
				24,
				322
			),

			Size =
			UDim2.new(
				1,
				-48,
				0,
				40
			),

			BackgroundTransparency = 1,

			Text =
			"Se sentir algum mal-estar, pare de jogar imediatamente. Em caso de emergência, procure ajuda de autoridades.",

			TextColor3 =
			CONFIG.Colors.Secondary,

			TextSize = 10,

			Font =
			Enum.Font.Gotham,

			TextWrapped = true,

			TextXAlignment =
			Enum.TextXAlignment.Left,

			ZIndex = 62,
		}
	)

----------------------------------------------------------------
-- WARNING BUTTONS
----------------------------------------------------------------

local WarningReduced =
	Create(
		"TextButton",
		{
			Parent = WarningPanel,

			Position =
			UDim2.fromOffset(
				24,
				390
			),

			Size =
			UDim2.new(
				0.5,
				-28,
				0,
				34
			),

			BackgroundColor3 =
			CONFIG.Colors.Dark,

			BorderSizePixel = 0,

			Text =
			"Modo reduzido",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 11,

			Font =
			Enum.Font.GothamMedium,

			AutoButtonColor = false,

			Selectable = true,

			ZIndex = 63,
		}
	)

Corner(
	WarningReduced,
	10
)

Stroke(
	WarningReduced,
	CONFIG.Colors.Border,
	0.15,
	1
)


local WarningConfirm =
	Create(
		"TextButton",
		{
			Parent = WarningPanel,

			Position =
			UDim2.new(
				0.5,
				4,
				0,
				390
			),

			Size =
			UDim2.new(
				0.5,
				-28,
				0,
				34
			),

			BackgroundColor3 =
			CONFIG.Colors.White,

			BorderSizePixel = 0,

			Text =
			"Continuar",

			TextColor3 =
			CONFIG.Colors.Black,

			TextSize = 11,

			Font =
			Enum.Font.GothamBold,

			AutoButtonColor = false,

			Selectable = true,

			ZIndex = 63,
		}
	)

Corner(
	WarningConfirm,
	10
)

RegisterFadeTree(
	WarningPanel
)

----------------------------------------------------------------
-- TERMS PANEL
----------------------------------------------------------------

local TermsPanel =
	Create(
		"Frame",
		{
			Name = "TermsPanel",

			Parent = ScreenGui,

			AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

			Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

			Size =
			UDim2.fromOffset(
				560,
				430
			),

			BackgroundColor3 =
			CONFIG.Colors.Black,

			BorderSizePixel = 0,

			Visible = false,

			ZIndex = 70,
		}
	)

Corner(
	TermsPanel,
	16
)

Stroke(
	TermsPanel,
	CONFIG.Colors.Border,
	0.15,
	1
)

local TermsScale =
	Create(
		"UIScale",
		{
			Parent = TermsPanel,
			Scale = 0.94,
		}
	)

local TermsTitle =
	Create(
		"TextLabel",
		{
			Parent = TermsPanel,

			Position =
			UDim2.fromOffset(
				24,
				18
			),

			Size =
			UDim2.new(
				1,
				-80,
				0,
				30
			),

			BackgroundTransparency = 1,

			Text =
			"Termos de Uso",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 18,

			Font =
			Enum.Font.GothamBold,

			TextWrapped = true,

			TextXAlignment =
			Enum.TextXAlignment.Left,

			ZIndex = 72,
		}
	)

local TermsClose =
	Create(
		"TextButton",
		{
			Parent = TermsPanel,

			AnchorPoint =
			Vector2.new(
				1,
				0
			),

			Position =
			UDim2.new(
				1,
				-18,
				0,
				16
			),

			Size =
			UDim2.fromOffset(
				34,
				34
			),

			BackgroundColor3 =
			CONFIG.Colors.Dark,

			BorderSizePixel = 0,

			Text = "×",

			TextColor3 =
			CONFIG.Colors.White,

			TextSize = 23,

			Font =
			Enum.Font.GothamMedium,

			AutoButtonColor = false,

			Selectable = true,

			ZIndex = 73,
		}
	)

Corner(
	TermsClose,
	10
)

Stroke(
	TermsClose,
	CONFIG.Colors.Border,
	0.25,
	1
)

local TermsContentFrame =
	Create(
		"ScrollingFrame",
		{
			Parent = TermsPanel,

			Position =
			UDim2.fromOffset(
				20,
				65
			),

			Size =
			UDim2.new(
				1,
				-40,
				1,
				-100
			),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			CanvasSize =
			UDim2.new(
				0,
				0,
				0,
				620
			),

			ScrollBarThickness = 4,

			ScrollBarImageColor3 =
			CONFIG.Colors.Focus,

			AutomaticCanvasSize =
			Enum.AutomaticSize.Y,

			ScrollingDirection =
			Enum.ScrollingDirection.Y,

			ZIndex = 72,
		}
	)

local TermsText =
	Create(
		"TextLabel",
		{
			Parent = TermsContentFrame,

			Position =
			UDim2.fromOffset(
				0,
				0
			),

			Size =
			UDim2.new(
				1,
				-12,
				0,
				620
			),

			BackgroundTransparency = 1,

			Text =
			"Termos de Uso e aviso de fotossensibilidade\n\n" ..
			"Ao participar desta experiência, o usuário reconhece que a interface e os efeitos visuais podem incluir iluminação, partículas, transições rápidas, cenários com luz intensa e alterações de contraste. Esses recursos são utilizados para melhorar a imersão, mas também podem causar desconforto em pessoas com sensibilidade à luz ou movimentos rápidos.\n\n" ..
			"Responsabilidade do Dono da Experiência: O criador desta experiência deve manter a interface acessível, fornecer avisos claros sobre efeitos visuais e oferecer mecanismos como modo reduzido, aviso de fotossensibilidade e alternância de recursos visuais. O criador não deve ocultar riscos conhecidos nem impedir o usuário de escolher configurações mais seguras.\n\n" ..
			"Responsabilidade da Roblox: A Roblox oferece a plataforma para hospedagem e execução da experiência, mas não garante, individualmente, que todos os efeitos visuais, elementos de gráfica ou campanhas de acessibilidade sejam adequados a cada usuário. A Roblox se reserva o direito de aplicar políticas de segurança, proteção de comunidade e manutenção da plataforma.\n\n" ..
			"Responsabilidade do Usuário: O Usuário é responsável por ler este aviso, identificar seu nível de sensibilidade aos efeitos visuais e escolher, com autonomia, continuar, reduzir o movimento, ativar o modo reduzido ou interromper a experiência. Em caso de mal-estar, tontura, dor de cabeça, náusea ou qualquer sintoma relacionado à luz ou ao movimento, o usuário deve interromper imediatamente a experiência e buscar apoio ou atendimento médico sempre que necessário.\n\n" ..
			"Links úteis sobre fotossensibilidade:\n" ..
			"https://www.saudebemestar.pt/pt/clinica/oftalmologia/fotofobia\n" ..
			"https://www.allaboutvision.com/pt/condicoes/fotofobia\n\n" ..
			"Este aviso não substitui orientação médica nem exime a experiência de priorizar o cuidado com o usuário. Sempre que o usuário apresentar desconforto, o acesso deve ser interrompido e o conteúdo visual deve permitir alternativas mais seguras.",

			TextColor3 =
			CONFIG.Colors.Description,

			TextSize = 12,

			Font =
			Enum.Font.Gotham,

			TextWrapped = true,

			TextXAlignment =
			Enum.TextXAlignment.Left,

			TextYAlignment =
			Enum.TextYAlignment.Top,

			ZIndex = 74,
		}
	)

local termsTextHeight =
	math.max(
		TermsText.TextBounds.Y + 40,
		140
	)

TermsText.Size =
	UDim2.new(
		1,
		-12,
		0,
		termsTextHeight
	)

TermsContentFrame.CanvasSize =
	UDim2.new(
		0,
		0,
		0,
		termsTextHeight + 44
	)

RegisterFadeTree(
	TermsPanel
)

----------------------------------------------------------------
-- RESPONSIVE
----------------------------------------------------------------
-- OBS: DetectDevice, IsPCDevice e CurrentDevice já foram
-- definidos no topo do arquivo (seção "DEVICE STATE") para
-- corrigir o bug relatado. Esta seção continua com o restante
-- da lógica responsiva normalmente.
----------------------------------------------------------------

local function GetPanelSize(
	fullscreen
)

	local device =
		DetectDevice()

	CurrentDevice =
		device

	if fullscreen then

		if device == "Tablet" then
			return CONFIG.Fullscreen.Tablet

		elseif device == "Console" then
			return CONFIG.Fullscreen.Console

		elseif device == "TV" then
			return CONFIG.Fullscreen.TV

		elseif device == "PC_Large" then
			return CONFIG.Fullscreen.PC_Large

		else
			return CONFIG.Fullscreen.PC
		end

	end

	if device == "Tablet" then

		return UDim2.fromScale(
			0.86,
			0.82
		)

	elseif device == "Console" then

		return UDim2.fromOffset(
			760,
			540
		)

	elseif device == "TV" then

		return UDim2.fromScale(
			0.82,
			0.80
		)

	elseif device == "PC_Large" then

		return UDim2.fromOffset(
			760,
			500
		)

	end

	return UDim2.fromOffset(
		CONFIG.PanelWidth,
		CONFIG.PanelHeight
	)

end


function GetResponsiveUIScale(device)
	if device == "Mobile" then
		return 0.7
	elseif device == "Tablet" then
		return 1.3
	elseif device == "Console" then
		return 2
	elseif device == "TV" then
		return 2
	end

	return 1
end

function ApplyResponsiveUIScale(device)
	local scale = GetResponsiveUIScale(device)

	if MainScale then
		MainScale.Scale = scale
	end

	if WarningScale then
		WarningScale.Scale = scale
	end

	if TermsScale then
		TermsScale.Scale = scale
	end

	return scale
end

local function UpdateResponsiveLayout(
	instant
)

	local device =
		DetectDevice()

	CurrentDevice =
		device

	UpdateHeaderAlignment()
	ApplyResponsiveUIScale(device)

	-- Fullscreen control should remain visible only on
	-- desktop-like sessions. Mobile, tablet, console,
	-- and TV flows use the same settings UI but avoid
	-- forcing a desktop-only layout affordance.
	if IsPCDevice(device) then
		FullscreenButton.Visible = true
		WindowControls.Size = UDim2.fromOffset(160, 34)
	else
		FullscreenButton.Visible = false
		WindowControls.Size = UDim2.fromOffset(118, 34)
	end

	local target =
		GetPanelSize(
			FullscreenEnabled
		)

	if instant then

		MainPanel.Size =
			target

	else

		Tween(
			MainPanel,
			{
				Size = target,
			},
			CONFIG.Animation.Medium
		)

	end

	----------------------------------------------------------------
	-- MOBILE PAGE HEADER / LIST COMFORT
	----------------------------------------------------------------

	if device == "Mobile" then
		PageTitle.TextXAlignment =
			Enum.TextXAlignment.Left
		PageTitle.TextSize = 20
		PageTitle.Position =
			UDim2.fromOffset(
				0,
				0
			)
		PageTitle.Size =
			UDim2.new(
				1,
				0,
				0,
				28
			)

		PageDescription.TextXAlignment =
			Enum.TextXAlignment.Left
		PageDescription.TextSize = 11
		PageDescription.Position =
			UDim2.fromOffset(
				0,
				30
			)
		PageDescription.Size =
			UDim2.new(
				1,
				0,
				0,
				28
			)

		PageScroll.Position =
			UDim2.fromOffset(
				0,
				68
			)
		PageScroll.Size =
			UDim2.new(
				1,
				0,
				1,
				-68
			)
		PageLayout.Padding =
			UDim.new(
				0,
				8
			)

	else

		PageTitle.TextXAlignment =
			Enum.TextXAlignment.Left
		PageDescription.TextXAlignment =
			Enum.TextXAlignment.Left
		PageTitle.Position =
			UDim2.fromOffset(
				0,
				0
			)
		PageDescription.Position =
			UDim2.fromOffset(
				0,
				30
			)
		PageScroll.Position =
			UDim2.fromOffset(
				0,
				68
			)
		PageScroll.Size =
			UDim2.new(
				1,
				0,
				1,
				-68
			)
		PageLayout.Padding =
			UDim.new(
				0,
				8
			)

	end

	----------------------------------------------------------------
	-- CATEGORIES SIDEBAR MOBILE COMFORT
	----------------------------------------------------------------

	for _, data in pairs(CategoryButtons) do

		if data and data.Button then

			data.Button.Size =
				UDim2.new(
					1,
					-4,
					0,
					44
				)

		end

		if data and data.Icon then

			data.Icon.Size =
				UDim2.fromOffset(
					24,
					44
				)

		end

		if data and data.Label then

			data.Label.Position =
				UDim2.fromOffset(
					40,
					0
				)

		end

	end

	CategoryLayout.Padding =
		UDim.new(
			0,
			5
		)

	----------------------------------------------------------------
	-- WARNING
	----------------------------------------------------------------

	if device == "Tablet" then

		WarningPanel.Size =
			UDim2.fromScale(
				0.80,
				0.76
			)

	else

		WarningPanel.Size =
			UDim2.fromOffset(
				540,
				430
			)

	end

	----------------------------------------------------------------
	-- TEXT
	----------------------------------------------------------------

	if device == "Console"
		or device == "TV"
	then

		Title.TextSize = 27
		PageTitle.TextSize = 22

		CategoryTitle.TextSize = 17

	else

		Title.TextSize = 25
		PageTitle.TextSize = 20

		CategoryTitle.TextSize = 16

	end

	----------------------------------------------------------------
	-- ROWS
	----------------------------------------------------------------

	for _, data in ipairs(
		SettingRows
		) do

		if data.Row
			and data.Row.Parent
			and not data.FixedHeight
		then

			data.Row.Size =
				UDim2.new(
					1,
					-6,
					0,
					GetRowHeight()
				)

		end

	end

	for _, category in ipairs(Categories) do
		if category.Name == CurrentCategory then
			ApplyCategoryPresentation(category)
			break
		end
	end

end

----------------------------------------------------------------
-- FULLSCREEN
----------------------------------------------------------------

local function SetFullscreen(
	enabled
)

	if not Opened then
		return
	end

	if Transitioning then
		return
	end

	local token =
		BeginTransition()

	if not token then
		return
	end

	FullscreenEnabled =
		enabled == true

	SetFullscreenIcon(
		FullscreenEnabled
	)

	local targetSize =
		GetPanelSize(
			FullscreenEnabled
		)

	if FullscreenEnabled then

		SettingsBlur.Enabled =
			true

		Tween(
			SettingsBlur,
			{
				Size =
					CONFIG.Fullscreen.BlurSize,
			},
			CONFIG.Fullscreen.OpenDuration
		)

		Tween(
			MainPanel,
			{
				Size = targetSize,

				BackgroundTransparency =
					CONFIG.Fullscreen.PanelTransparency,
			},
			CONFIG.Fullscreen.OpenDuration
		)

	else

		Tween(
			SettingsBlur,
			{
				Size = 0,
			},
			CONFIG.Fullscreen.CloseDuration
		)

		Tween(
			MainPanel,
			{
				Size = targetSize,

				BackgroundTransparency = 0,
			},
			CONFIG.Fullscreen.CloseDuration
		)

		task.delay(
			MotionDuration(
				CONFIG.Fullscreen.CloseDuration
			),
			function()

				if IsValidToken(token)
					and not FullscreenEnabled
				then

					SettingsBlur.Enabled =
						false

				end

			end
		)

	end

	task.delay(
		MotionDuration(
			FullscreenEnabled
				and CONFIG.Fullscreen.OpenDuration
				or CONFIG.Fullscreen.CloseDuration
		),
		function()

			if not IsValidToken(token) then
				return
			end

			-- Os cards de "Sobre" usam o tamanho real de PageScroll.
			-- Depois da animação de fullscreen, reconstruímos a página
			-- para recalcular largura, altura e posição dos cards.
			if CurrentCategory == "Sobre" then

				local savedScrollY =
					PageScroll.CanvasPosition.Y

				BuildCategory(
					"Sobre",
					false,
					true
				)

				task.defer(
					function()

						if not PageScroll.Parent then
							return
						end

						local maxScrollY =
							math.max(
								0,
								PageScroll.AbsoluteCanvasSize.Y
								- PageScroll.AbsoluteWindowSize.Y
							)

						PageScroll.CanvasPosition =
							Vector2.new(
								0,
								math.min(savedScrollY, maxScrollY)
							)

					end
				)

				if FullscreenEnabled then
					PageScroll.Visible = true
				end

			end

			EndTransition(
				token,
				false
			)

		end
	)

end

----------------------------------------------------------------
-- WARNING
----------------------------------------------------------------

local function ShouldShowWarning()

	if not CONFIG.Accessibility.WarningEnabled then
		return false
	end

	if PhotosensitivityConfirmed
		and not CONFIG.Accessibility.ForceWarningForTesting
	then
		return false
	end

	if CONFIG.Accessibility.ForceWarningForTesting then
		return true
	end

	return PhotosensitivityWarningPending

end


function OpenWarning()

	if not Opened then
		return
	end

	if Transitioning then
		return
	end

	local token =
		BeginTransition()

	if not token then
		return
	end

	PlaySettingsSound(
		"Warning"
	)

	CurrentPage =
		"Warning"

	AccessibilityGateActive =
		true

	MainPanel.Visible =
		false

	WarningPanel.Visible =
		true

	WarningPanel.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	local responsiveScale = GetResponsiveUIScale(DetectDevice())
	WarningScale.Scale =
		ReducedMotionEnabled
		and responsiveScale
		or responsiveScale * 0.94

	WarningPanel.BackgroundTransparency =
		0

	FadePanel(
		WarningPanel,
		true,
		0
	)

	Tween(
		Overlay,
		{
			BackgroundTransparency =
				1,
		},
		CONFIG.Animation.Warning
	)

	Tween(
		WarningPanel,
		{
			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),
		},
		CONFIG.Animation.Warning
	)

	PlayScale(
		WarningScale,
		GetResponsiveUIScale(DetectDevice()),
		CONFIG.Animation.Warning
	)

	FadePanel(
		WarningPanel,
		false,
		CONFIG.Animation.Warning
	)

	task.delay(
		MotionDuration(
			CONFIG.Animation.Warning
		),
		function()

			EndTransition(
				token,
				true
			)

		end
	)

end

----------------------------------------------------------------
-- CLOSE WARNING
----------------------------------------------------------------

local function CloseWarning()

	if not Opened then
		return
	end

	if Transitioning then
		return
	end

	local token =
		BeginTransition()

	if not token then
		return
	end

	FadePanel(
		WarningPanel,
		true,
		CONFIG.Animation.Fast
	)

	Tween(
		WarningPanel,
		{
			Position =
				UDim2.new(
					0.5,
					0,
					0.5,
					20
				),
		},
		CONFIG.Animation.Warning
	)

	Tween(
		Overlay,
		{
			BackgroundTransparency = 1,
		},
		CONFIG.Animation.Warning
	)

	task.delay(
		MotionDuration(
			CONFIG.Animation.Warning
		),
		function()

			if not IsValidToken(token) then
				return
			end

			WarningPanel.Visible =
				false

			Opened = false
			AccessibilityGateActive = false

			EndTransition(
				token,
				true
			)

		end
	)

end

----------------------------------------------------------------
-- WARNING CONFIRM
----------------------------------------------------------------

local function ConfirmWarning(
	reduced
)

	if Transitioning then
		return
	end

	PhotosensitivityConfirmed =
		true

	PhotosensitivityWarningPending =
		false

	AccessibilityGateActive =
		false

	if reduced then

		ReducedMotionEnabled =
			true

	end

	local token =
		BeginTransition()

	if not token then
		return
	end

	FadePanel(
		WarningPanel,
		true,
		CONFIG.Animation.Fast
	)

	Tween(
		Overlay,
		{
			BackgroundTransparency = 1,
		},
		CONFIG.Animation.Fast
	)

	task.delay(
		MotionDuration(
			CONFIG.Animation.Fast
		),
		function()

			if not IsValidToken(token) then
				return
			end

			WarningPanel.Visible =
				false

			CurrentPage =
				"Main"

			MainPanel.Visible =
				true

			MainPanel.BackgroundTransparency =
				0

			local responsiveScale = GetResponsiveUIScale(DetectDevice())
			MainScale.Scale =
				ReducedMotionEnabled
				and responsiveScale
				or responsiveScale * 0.88

			BuildCategory(
				"Geral",
				false,
				true
			)

			FadePanel(
				MainPanel,
				true,
				0
			)

			Tween(
				Overlay,
				{
					BackgroundTransparency =
						1,
				},
				CONFIG.Animation.Open
			)

			PlayScale(
				MainScale,
				GetResponsiveUIScale(DetectDevice()),
				CONFIG.Animation.Open
			)

			FadePanel(
				MainPanel,
				false,
				CONFIG.Animation.Open
			)

			task.delay(
				MotionDuration(
					CONFIG.Animation.Open
				),
				function()

					EndTransition(
						token,
						true
					)

				end
			)

		end
	)

end

----------------------------------------------------------------
-- CLOSE TERMS
----------------------------------------------------------------

local function CloseTerms()

	if not Opened then
		return
	end

	if Transitioning then
		return
	end

	if CurrentPage ~= "Terms" then
		return
	end

	local token =
		BeginTransition()

	if not token then
		return
	end

	FadePanel(
		TermsPanel,
		true,
		CONFIG.Animation.Fast
	)

	Tween(
		WarningPanel,
		{
			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),
		},
		CONFIG.Animation.Medium
	)

	Tween(
		Overlay,
		{
			BackgroundTransparency =
				1,
		},
		CONFIG.Animation.Medium
	)

	task.delay(
		MotionDuration(
			CONFIG.Animation.Medium
		),
		function()

			if not IsValidToken(token) then
				return
			end

			TermsPanel.Visible =
				false

			CurrentPage =
				"Warning"

			EndTransition(
				token,
				false
			)

		end
	)

end

----------------------------------------------------------------
-- OPEN SETTINGS
----------------------------------------------------------------

local function OpenSettings()

	if Opened then
		return
	end

	if not CanToggleSettings() then
		return
	end

	local token =
		BeginTransition()

	if not token then
		return
	end

	Opened = true
	SecretSettingsTriggered = false
	CancelSecretSettingsTimer()
	RestoreSecretSettingsEnvironment()
	if SecretSettingsMusic and SecretSettingsMusic.Parent then
		SecretSettingsMusic.Volume = 0
		SecretSettingsMusic:Stop()
	end

	-- Restaura a última posição de navegação.
	-- Warning/Terms continuam sendo controlados pelo fluxo de acessibilidade.
	CurrentCategory =
		SavedCategory

	CurrentPage =
		"Main"

	FullscreenEnabled =
		false

	SetFullscreenIcon(
		false
	)

	AccessibilityGateActive =
		ShouldShowWarning()

	UpdateResponsiveLayout(
		true
	)

	MainPanel.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	MainPanel.BackgroundTransparency =
		0

	local responsiveScale = GetResponsiveUIScale(DetectDevice())
	MainScale.Scale =
		ReducedMotionEnabled
		and responsiveScale
		or responsiveScale * 0.88

	MainPanel.Visible =
		not AccessibilityGateActive

	WarningPanel.Visible =
		false

	Overlay.Visible =
		true

	Overlay.BackgroundTransparency =
		1
	OverlayFade.BackgroundTransparency = 1

	SettingsBlur.Size =
		0

	SettingsBlur.Enabled =
		false

	BuildCategory(
		CurrentCategory,
		false,
		true
	)

	if AccessibilityGateActive then

		PlaySettingsSound(
			"Warning"
		)
		CurrentPage =
			"Warning"

		WarningPanel.Visible =
			true

		WarningPanel.Position =
			UDim2.fromScale(
				0.5,
				0.5
			)

		local responsiveScale = GetResponsiveUIScale(DetectDevice())
		WarningScale.Scale =
			ReducedMotionEnabled
			and responsiveScale
			or responsiveScale * 0.94

		FadePanel(
			WarningPanel,
			true,
			0
		)

		FadeOverlayFade(
			true,
			CONFIG.Animation.Warning
		)

		Tween(
			Overlay,
			{
				BackgroundTransparency =
					1,
			},
			CONFIG.Animation.Warning
		)

		PlayScale(
			WarningScale,
			GetResponsiveUIScale(DetectDevice()),
			CONFIG.Animation.Warning
		)

		FadePanel(
			WarningPanel,
			false,
			CONFIG.Animation.Warning
		)

		task.delay(
			MotionDuration(
				CONFIG.Animation.Warning
			),
			function()

				EndTransition(
					token,
					true
				)

			end
		)

		return

	end

	----------------------------------------------------------------
	-- NORMAL OPEN
	----------------------------------------------------------------

	PlaySettingsSound(
		"OpenSettings"
	)
	StartSecretSettingsTimer()

	FadePanel(
		MainPanel,
		true,
		0
	)

	FadeOverlayFade(
		true,
		CONFIG.Animation.Open
	)

	Tween(
		Overlay,
		{
			BackgroundTransparency =
				1,
		},
		CONFIG.Animation.Open
	)

	PlayScale(
		MainScale,
		GetResponsiveUIScale(DetectDevice()),
		CONFIG.Animation.Open
	)

	FadePanel(
		MainPanel,
		false,
		CONFIG.Animation.Open
	)

	task.delay(
		MotionDuration(
			CONFIG.Animation.Open
		),
		function()

			EndTransition(
				token,
				true
			)

		end
	)

end

----------------------------------------------------------------
-- CLOSE SETTINGS
----------------------------------------------------------------

local function CloseSettings()

	if not Opened then
		return
	end

	if Transitioning then
		return
	end

	local token =
		BeginTransition()

	if not token then
		return
	end

	PlaySettingsSound(
		"CloseSettings"
	)
	CancelSecretSettingsTimer()
	if SecretSettingsTriggered then
		RestoreSecretSettingsEnvironment()
		StopSecretSettingsMusic(2)
		SecretSettingsTriggered = false
	end

	-- Guarda a posição antes de desmontar o estado visual.
	SavedCategory = CurrentCategory
	if CurrentPage ~= "Warning" and CurrentPage ~= "Terms" then
		SavedPage = CurrentPage
	end

	Opened = false
	StopCategoryTitleAnimation()

	CurrentPage =
		"Main"

	AccessibilityGateActive =
		false

	FullscreenEnabled =
		false

	SetFullscreenIcon(
		false
	)

	----------------------------------------------------------------
	-- WARNING
	----------------------------------------------------------------

	if WarningPanel.Visible then

		FadePanel(
			WarningPanel,
			true,
			CONFIG.Animation.Close
		)

		Tween(
			WarningPanel,
			{
				Position =
					UDim2.new(
						0.5,
						0,
						0.5,
						18
					),
			},
			CONFIG.Animation.Close
		)

	end

	----------------------------------------------------------------
	-- TERMS
	----------------------------------------------------------------

	if TermsPanel.Visible then

		FadePanel(
			TermsPanel,
			true,
			CONFIG.Animation.Close
		)

		Tween(
			TermsPanel,
			{
				Position =
					UDim2.new(
						0.5,
						0,
						0.5,
						18
					),
			},
			CONFIG.Animation.Close,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.In
		)

	end


	----------------------------------------------------------------
	-- MAIN
	----------------------------------------------------------------

	-- Revarre a árvore porque a categoria atual pode ter sido criada
	-- dinamicamente depois do último CaptureFadeTree(MainPanel).
	CaptureFadeTree(MainPanel)

	FadePanel(
		MainPanel,
		true,
		CONFIG.Animation.Close
	)

	Tween(
		MainPanel,
		{
			Position =
				UDim2.new(
					0.5,
					0,
					0.5,
					8
				),

			BackgroundTransparency = 1,
		},
		CONFIG.Animation.Close,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.In
	)

	FadeOverlayFade(
		false,
		CONFIG.Animation.Close
	)

	Tween(
		Overlay,
		{
			BackgroundTransparency = 1,
		},
		CONFIG.Animation.Close
	)

	Tween(
		SettingsBlur,
		{
			Size = 0,
		},
		CONFIG.Animation.Close
	)

	task.delay(
		MotionDuration(
			CONFIG.Animation.Close
		),
		function()

			if not IsValidToken(token) then
				return
			end

			MainPanel.Visible =
				false

			WarningPanel.Visible =
				false

			TermsPanel.Visible =
				false

			Overlay.Visible =
				false

			MainPanel.Position =
				UDim2.fromScale(
					0.5,
					0.5
				)

			MainPanel.BackgroundTransparency =
				0

			MainScale.Scale = GetResponsiveUIScale(DetectDevice())

			SettingsBlur.Size =
				0

			SettingsBlur.Enabled =
				false

			EndTransition(
				token,
				true
			)

		end
	)

end

----------------------------------------------------------------
-- THEME RESTART
----------------------------------------------------------------

local function RestartSettingsForTheme(themeName)
	if not Opened or Transitioning or ThemeRestarting then
		return
	end

	ThemeRestarting = true

	-- TESTE: sem fade-to-black. O Shield continua presente, porém
	-- totalmente transparente, apenas para impedir intervenção do jogador.
	ThemeTransitionShield.Visible = true
	ThemeTransitionShield.BackgroundTransparency = 1

	-- Preserva exatamente a categoria/aba antes da reinicialização.
	SavedCategory = CurrentCategory
	if CurrentPage ~= "Warning" and CurrentPage ~= "Terms" then
		SavedPage = CurrentPage
	end

	-- O Overlay acompanha a troca de tema durante a própria transição:
	-- Dark = preto, Light = branco.
	SetOverlayGradientTheme(
		themeName,
		CONFIG.Animation.Close
	)

	SetTheme(themeName, true)
	CloseSettings()

	while Transitioning do
		task.wait()
	end

	OpenSettings()

	while Transitioning do
		task.wait()
	end

	-- Fim do modo de teste: libera a interação somente depois que
	-- o SettingsUI terminou de abrir novamente.
	ThemeTransitionShield.BackgroundTransparency = 1
	ThemeTransitionShield.Visible = false
	ThemeRestarting = false
end

----------------------------------------------------------------
-- INPUT
----------------------------------------------------------------

InputConnection =
	UserInputService.InputBegan:Connect(
		function(
			input,
			gameProcessed
		)

			if ThemeRestarting then
				return
			end

			if gameProcessed then
				return
			end

			----------------------------------------------------------------
			-- ESC
			----------------------------------------------------------------

			if input.KeyCode ==
				Enum.KeyCode.Escape
			then

				if not Opened then
					return
				end

				if CurrentPage == "Warning" then

					CloseSettings()


				else

					CloseSettings()

				end

				return

			end

			----------------------------------------------------------------
			-- PC FULLSCREEN KEY: F
			----------------------------------------------------------------

			if input.KeyCode ==
				Enum.KeyCode.F
			then

				if not Opened then
					return
				end

				if not IsPCDevice(DetectDevice()) then
					return
				end

				if CurrentPage == "Warning" then
					return
				end

				SetFullscreen(
					not FullscreenEnabled
				)

				return

			end

			----------------------------------------------------------------
			-- GAMEPAD B
			----------------------------------------------------------------

			if input.KeyCode ==
				Enum.KeyCode.ButtonB
			then

				if not Opened then
					return
				end

				if CurrentPage == "Warning" then

					CloseSettings()


				elseif CurrentPage == "Terms" then

					CloseTerms()

				else

					CloseSettings()

				end

				return

			end

		end
	)

----------------------------------------------------------------
-- TOPBAR EVENTS
----------------------------------------------------------------

SaveButton.Activated:Connect(function()
	if not Opened
		or not CanInteract()
		or not SettingsInitialized
		or not SettingsDirty
		or SaveCooldownActive
		or SaveInProgress
	then
		return
	end

	if not SettingsPersistenceRemote then
		warn("[SettingsUI] Serviço de salvamento ainda não está disponível.")
		return
	end

	PlaySettingsSound("SaveButton")
	SaveCooldownActive = true
	SaveInProgress = true
	local revisionAtSave = SettingsRevision
	UpdateSaveButtonVisual()

	task.delay(5, function()
		SaveCooldownActive = false
		UpdateSaveButtonVisual()
	end)

	task.spawn(function()
		local success, response = pcall(function()
			return SettingsPersistenceRemote:InvokeServer(
				"Save",
				GetSettingsSnapshot()
			)
		end)

		SaveInProgress = false

		if not success then
			warn("[SettingsUI] Falha ao salvar configurações:", response)
			UpdateSaveButtonVisual()
			return
		end

		if typeof(response) ~= "table" or response.Success ~= true then
			local message = typeof(response) == "table"
				and response.Error
				or "Resposta inválida do servidor."
			warn("[SettingsUI] Falha ao salvar configurações:", message)
			UpdateSaveButtonVisual()
			return
		end

		if SettingsRevision == revisionAtSave then
			SettingsDirty = false
		end
		UpdateSaveButtonVisual()
	end)
end)

SaveButton.SelectionGained:Connect(function()
	ApplySmartFocus(SaveScale, true)
end)

SaveButton.SelectionLost:Connect(function()
	ApplySmartFocus(SaveScale, false)
end)

local function ToggleSettingsFromTopbar()

	if ThemeRestarting then
		return
	end

	if TopbarClickLocked then
		return
	end

	TopbarClickLocked = true

	task.defer(function()
		TopbarClickLocked = false
	end)

	if Opened then

		if CurrentPage == "Terms" then
			CloseTerms()
			return
		end

		CloseSettings()
	else
		OpenSettings()
	end

end

SettingsButton.Activated:Connect(
	function()
		ToggleSettingsFromTopbar()
	end
)

SettingsButton.MouseEnter:Connect(
	function()

		PlayScale(
			SettingsScale,
			1.08,
			CONFIG.Animation.Focus
		)

		Tween(
			SettingsIcon,
			{
				Rotation = 25,
			},
			CONFIG.Animation.Focus
		)

	end
)


SettingsButton.MouseLeave:Connect(
	function()

		PlayScale(
			SettingsScale,
			1,
			CONFIG.Animation.Focus
		)

		Tween(
			SettingsIcon,
			{
				Rotation = 0,
			},
			CONFIG.Animation.Focus
		)

	end
)


SettingsButton.MouseButton1Down:Connect(
	function()

		PlayScale(
			SettingsScale,
			0.92,
			CONFIG.Animation.Press
		)

	end
)


SettingsButton.MouseButton1Up:Connect(
	function()

		PlayScale(
			SettingsScale,
			1.08,
			CONFIG.Animation.Focus
		)

	end
)

----------------------------------------------------------------
-- OVERLAY
----------------------------------------------------------------

Overlay.Activated:Connect(
	function()

		if not Opened then
			return
		end

		if CurrentPage == "Warning" then

			CloseSettings()


		elseif CurrentPage == "Terms" then

			CloseTerms()

		else

			CloseSettings()

		end

	end
)

----------------------------------------------------------------
-- CLOSE
----------------------------------------------------------------

CloseButton.Activated:Connect(
	function()

		CloseSettings()

	end
)

-- COMMON WARNING INTERACTION GUARD
local function WarningBlockedByTerms()
	return CurrentPage == "Terms" or TermsPanel.Visible
end

----------------------------------------------------------------
-- WARNING "SAIBA MAIS"
----------------------------------------------------------------

WarningMore.Activated:Connect(
	function()

		if not Opened then
			return
		end

		if Transitioning then
			return
		end

		if WarningBlockedByTerms() then
			return
		end

		local token =
			BeginTransition()

		if not token then
			return
		end

		CurrentPage =
			"Terms"

		TermsPanel.Visible =
			true

		TermsPanel.Position =
			UDim2.fromScale(
				0.5,
				0.5
			)

		local responsiveScale = GetResponsiveUIScale(DetectDevice())
		TermsScale.Scale =
			ReducedMotionEnabled
			and responsiveScale
			or responsiveScale * 0.94

		TermsPanel.BackgroundTransparency =
			0

		FadePanel(
			TermsPanel,
			true,
			0
		)

		Tween(
			WarningPanel,
			{
				Position =
					UDim2.new(
						0.5,
						-35,
						0.5,
						0
					),
			},
			CONFIG.Animation.Medium
		)

		Tween(
			TermsPanel,
			{
				Position =
					UDim2.fromScale(
						0.5,
						0.5
					),
			},
			CONFIG.Animation.Medium
		)

		PlayScale(
			TermsScale,
			GetResponsiveUIScale(DetectDevice()),
			CONFIG.Animation.Medium
		)

		FadePanel(
			TermsPanel,
			false,
			CONFIG.Animation.Medium
		)

		Tween(
			Overlay,
			{
				BackgroundTransparency =
					0.42,
			},
			CONFIG.Animation.Medium
		)

		WarningPanel.Visible =
			true

		WarningPanel.BackgroundTransparency =
			0

		TermsPanel.Visible =
			true

		-- keep warning visible but shifted left as requested
		WarningPanel.Position =
			UDim2.new(
				0.5,
				-35,
				0.5,
				0
			)

		task.delay(
			MotionDuration(
				CONFIG.Animation.Medium
			),
			function()

				EndTransition(
					token,
					false
				)

			end
		)

	end
)

TermsClose.Activated:Connect(
	function()

		if not Opened then
			return
		end

		if Transitioning then
			return
		end

		CloseTerms()

	end
)


----------------------------------------------------------------
-- THEME
----------------------------------------------------------------

ThemeButton.MouseEnter:Connect(function()
	if not CanInteract() then
		return
	end

	PlayScale(
		ThemeScale,
		CONFIG.Interaction.FocusScale,
		CONFIG.Animation.Focus
	)
end)

ThemeButton.MouseLeave:Connect(function()
	PlayScale(
		ThemeScale,
		1,
		CONFIG.Animation.Focus
	)
end)

ThemeButton.MouseButton1Down:Connect(function()
	if not CanInteract() or ReducedMotionEnabled then
		return
	end

	PlayScale(
		ThemeScale,
		CONFIG.Interaction.PressScale,
		CONFIG.Animation.Press
	)
end)

ThemeButton.MouseButton1Up:Connect(function()
	if not CanInteract() then
		return
	end

	PlayScale(
		ThemeScale,
		1,
		CONFIG.Animation.Focus
	)
end)

ThemeButton.SelectionGained:Connect(function()
	ApplySmartFocus(ThemeScale, true)
end)

ThemeButton.SelectionLost:Connect(function()
	ApplySmartFocus(ThemeScale, false)
end)

ThemeButton.Activated:Connect(function()
	if not Opened or not CanInteract() or ThemeRestarting then
		return
	end

	PlaySettingsSound("CategoryButton")

	local nextTheme = CurrentTheme == "Dark" and "Light" or "Dark"
	task.spawn(
		RestartSettingsForTheme,
		nextTheme
	)
end)

----------------------------------------------------------------
-- FULLSCREEN
----------------------------------------------------------------

FullscreenButton.Activated:Connect(
	function()

		if not Opened then
			return
		end

		SetFullscreen(
			not FullscreenEnabled
		)

	end
)

----------------------------------------------------------------
-- WARNING
----------------------------------------------------------------

WarningClose.Activated:Connect(
	function()

		if WarningBlockedByTerms() then
			return
		end

		CloseSettings()

	end
)

WarningConfirm.Activated:Connect(
	function()

		if WarningBlockedByTerms() then
			return
		end

		ConfirmWarning(
			false
		)

	end
)

WarningReduced.Activated:Connect(
	function()

		if WarningBlockedByTerms() then
			return
		end

		ConfirmWarning(
			true
		)

	end
)

----------------------------------------------------------------
-- WARNING BUTTON FOCUS
----------------------------------------------------------------

WarningReduced.SelectionGained:Connect(
	function()

		if ReducedMotionEnabled then
			return
		end

		Tween(
			WarningReduced,
			{
				BackgroundColor3 =
					CONFIG.Colors.Focus,
			},
			CONFIG.Animation.Focus
		)

	end
)

WarningReduced.SelectionLost:Connect(
	function()

		Tween(
			WarningReduced,
			{
				BackgroundColor3 =
					CONFIG.Colors.Dark,
			},
			CONFIG.Animation.Focus
		)

	end
)

WarningConfirm.SelectionGained:Connect(
	function()

		if ReducedMotionEnabled then
			return
		end

		Tween(
			WarningConfirm,
			{
				BackgroundColor3 =
					Color3.fromRGB(
						225,
						225,
						225
					),
			},
			CONFIG.Animation.Focus
		)

	end
)

WarningConfirm.SelectionLost:Connect(
	function()

		Tween(
			WarningConfirm,
			{
				BackgroundColor3 =
					CONFIG.Colors.White,
			},
			CONFIG.Animation.Focus
		)

	end
)

----------------------------------------------------------------
-- RESPONSIVE CONNECTION
----------------------------------------------------------------

local function ConnectViewport()

	if ViewportConnection then

		ViewportConnection:Disconnect()

		ViewportConnection = nil

	end

	local camera =
		workspace.CurrentCamera

	if not camera then
		return
	end

	ViewportConnection =
		camera:GetPropertyChangedSignal(
			"ViewportSize"
		):Connect(
		function()

			if not Transitioning then

				UpdateResponsiveLayout(
					false
				)

			end

		end
	)

end

ConnectViewport()

workspace:GetPropertyChangedSignal(
	"CurrentCamera"
):Connect(
	function()

		ConnectViewport()

	end
)

----------------------------------------------------------------
-- INPUT DEVICE CHANGES
----------------------------------------------------------------

UserInputService.LastInputTypeChanged:Connect(
	function()

		if not Transitioning then

			UpdateResponsiveLayout(
				false
			)

		end

	end
)

----------------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------------

local SavedTheme = Player:GetAttribute("SettingsTheme")
if SavedTheme == "Light" or SavedTheme == "Dark" then
	CurrentTheme = SavedTheme
end

SetTheme(CurrentTheme, false)
ApplyMusicState()
SetOverlayGradientTheme(
	CurrentTheme,
	0
)

UpdateResponsiveLayout(
	true
)

SetFullscreenIcon(
	false
)

MainPanel.Visible =
	false


WarningPanel.Visible =
	false

Overlay.Visible =
	false

SettingsBlur.Size =
	0

SettingsBlur.Enabled =
	false

----------------------------------------------------------------
-- INITIAL FADE REGISTRY
----------------------------------------------------------------

CaptureFadeTree(
	MainPanel
)


CaptureFadeTree(
	WarningPanel
)

----------------------------------------------------------------
-- DEFAULT SELECTION
----------------------------------------------------------------

UpdateCategoryVisuals()

--Testing!

task.spawn(function()
	local initialSettings = GetSettingsSnapshot()
	local remote = ReplicatedStorage:WaitForChild(
		"SettingsPersistenceRemote",
		15
	)

	if not remote or not remote:IsA("RemoteFunction") then
		warn("[SettingsUI] Serviço de preferências não encontrado ou inválido.")
		return
	end

	SettingsPersistenceRemote = remote
	local success, response = pcall(function()
		return remote:InvokeServer("Load")
	end)

	if not success then
		warn("[SettingsUI] Não foi possível carregar as configurações:", response)
		return
	end

	if typeof(response) ~= "table"
		or response.Success ~= true
		or typeof(response.Settings) ~= "table"
	then
		local message = typeof(response) == "table"
			and response.Error
			or "Resposta inválida do servidor."
		warn("[SettingsUI] Não foi possível carregar as configurações:", message)
		return
	end

	local mergedSettings = table.clone(response.Settings)
	local currentSettings = GetSettingsSnapshot()
	local hasPendingChanges = false
	for settingName, currentValue in pairs(currentSettings) do
		if currentValue ~= initialSettings[settingName] then
			mergedSettings[settingName] = currentValue
			hasPendingChanges = true
		end
	end

	ApplyLoadedSettings(mergedSettings)
	SettingsDirty = hasPendingChanges
	SettingsInitialized = true
	UpdateSaveButtonVisual()

	if Opened and CurrentPage == "Main" then
		BuildCategory(CurrentCategory, false, true)
	end
end)