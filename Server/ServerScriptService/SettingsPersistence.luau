local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STORE = DataStoreService:GetDataStore("SettingsUI_UserSettings_v1")
local SAVE_COOLDOWN = 5
local lastSaveAt = {}

local DEFAULT_SETTINGS = {
	Theme = "Dark",
	NotificationsEnabled = true,
	ReducedMotionEnabled = false,
	PhotosensitivityProtectionEnabled = true,
	VibrationEnabled = true,
	InterfaceAnimationsEnabled = true,
	MusicEnabled = true,
	MusicVolume = 0.525,
	InterfaceSoundsEnabled = true,
}

local remote = ReplicatedStorage:FindFirstChild("SettingsPersistenceRemote")
if remote and not remote:IsA("RemoteFunction") then
	error("[SettingsUI] SettingsPersistenceRemote must be a RemoteFunction.")
end

if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = "SettingsPersistenceRemote"
	remote.Parent = ReplicatedStorage
end

local function validateSettings(value)
	if typeof(value) ~= "table" then
		return nil, "Configurações inválidas."
	end

	if value.Theme ~= "Dark" and value.Theme ~= "Light" then
		return nil, "Tema inválido."
	end

	for _, field in ipairs({
		"NotificationsEnabled",
		"ReducedMotionEnabled",
		"PhotosensitivityProtectionEnabled",
		"VibrationEnabled",
		"InterfaceAnimationsEnabled",
		"MusicEnabled",
		"InterfaceSoundsEnabled",
	}) do
		if typeof(value[field]) ~= "boolean" then
			return nil, "Preferência inválida: " .. field
		end
	end

	if typeof(value.MusicVolume) ~= "number"
		or value.MusicVolume ~= value.MusicVolume
		or math.abs(value.MusicVolume) == math.huge
	then
		return nil, "Volume inválido."
	end

	return {
		Theme = value.Theme,
		NotificationsEnabled = value.NotificationsEnabled,
		ReducedMotionEnabled = value.ReducedMotionEnabled,
		PhotosensitivityProtectionEnabled = value.PhotosensitivityProtectionEnabled,
		VibrationEnabled = value.VibrationEnabled,
		InterfaceAnimationsEnabled = value.InterfaceAnimationsEnabled,
		MusicEnabled = value.MusicEnabled,
		MusicVolume = math.clamp(value.MusicVolume, 0, 1),
		InterfaceSoundsEnabled = value.InterfaceSoundsEnabled,
	}
end

local function loadSettings(player)
	local success, stored = pcall(function()
		return STORE:GetAsync(tostring(player.UserId))
	end)

	if not success then
		warn("[SettingsUI] DataStore load failed for user " .. player.UserId .. ": " .. tostring(stored))
		return {
			Success = false,
			Error = "Não foi possível carregar as configurações.",
		}
	end

	if stored == nil then
		return {
			Success = true,
			Settings = table.clone(DEFAULT_SETTINGS),
		}
	end

	local validated, validationError = validateSettings(stored)
	if not validated then
		warn("[SettingsUI] Invalid stored settings for user " .. player.UserId .. ": " .. validationError)
		return {
			Success = false,
			Error = "Os dados salvos estão inválidos.",
		}
	end

	return {
		Success = true,
		Settings = validated,
	}
end

local function saveSettings(player, settings)
	local validated, validationError = validateSettings(settings)
	if not validated then
		return {
			Success = false,
			Error = validationError,
		}
	end

	local now = os.clock()
	local previousSave = lastSaveAt[player.UserId]
	if previousSave and now - previousSave < SAVE_COOLDOWN then
		return {
			Success = false,
			Error = "Aguarde antes de salvar novamente.",
		}
	end
	lastSaveAt[player.UserId] = now

	local success, saveError = pcall(function()
		STORE:UpdateAsync(tostring(player.UserId), function()
			return validated
		end)
	end)

	if not success then
		warn("[SettingsUI] DataStore save failed for user " .. player.UserId .. ": " .. tostring(saveError))
		return {
			Success = false,
			Error = "Não foi possível salvar as configurações.",
		}
	end

	return {
		Success = true,
	}
end

remote.OnServerInvoke = function(player, action, settings)
	if action == "Load" then
		return loadSettings(player)
	elseif action == "Save" then
		return saveSettings(player, settings)
	end

	return {
		Success = false,
		Error = "Ação de configurações desconhecida.",
	}
end

Players.PlayerRemoving:Connect(function(player)
	lastSaveAt[player.UserId] = nil
end)
