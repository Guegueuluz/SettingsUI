--[[
    EMOTE → ANIMATION ID CONVERTER
    ServerScript

    ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local InsertService = game:GetService("InsertService")

--------------------------------------------------
-- REMOTE
--------------------------------------------------

local remote = ReplicatedStorage:FindFirstChild(
	"EmoteConverterRemote"
)

if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "EmoteConverterRemote"
	remote.Parent = ReplicatedStorage
end

--------------------------------------------------
-- CACHE
--------------------------------------------------

local cache = {}

--------------------------------------------------
-- EXTRACT ID
--------------------------------------------------

local function extractAnimation(root)

	if not root then
		return nil
	end

	-- Primeiro procura diretamente por Animation.
	local animation = root:FindFirstChildWhichIsA(
		"Animation",
		true
	)

	if animation then

		local animationId = animation.AnimationId

		if animationId and animationId ~= "" then

			local id = animationId:match("%d+")

			if id then
				return tonumber(id)
			end
		end
	end

	return nil
end

--------------------------------------------------
-- MARKETPLACE INFO
--------------------------------------------------

local function getMarketplaceInfo(assetId)

	local success, result = pcall(function()
		return MarketplaceService:GetProductInfoAsync(
			assetId,
			Enum.InfoType.Asset
		)
	end)

	if not success then
		return nil, tostring(result)
	end

	return result, nil
end

--------------------------------------------------
-- LOAD ASSET
--------------------------------------------------

local function loadMarketplaceAsset(assetId)

	local success, result = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if not success then
		return nil, tostring(result)
	end

	return result, nil
end

--------------------------------------------------
-- CONVERT
--------------------------------------------------

local function convertEmote(assetId)

	if cache[assetId] then
		return {
			Success = true,
			Name = cache[assetId].Name,
			AnimationId = cache[assetId].AnimationId
		}
	end

	--------------------------------------------------
	-- MARKETPLACE
	--------------------------------------------------

	local info, infoError = getMarketplaceInfo(assetId)

	if not info then
		return {
			Success = false,
			Message =
				"Não foi possível obter informações do Marketplace: "
				.. tostring(infoError)
		}
	end

	--------------------------------------------------
	-- LOAD
	--------------------------------------------------

	local model, loadError = loadMarketplaceAsset(assetId)

	if not model then
		return {
			Success = false,
			Message =
				"O Roblox não permitiu carregar esse asset. "
				.. tostring(loadError)
		}
	end

	--------------------------------------------------
	-- FIND ANIMATION
	--------------------------------------------------

	local animationId = extractAnimation(model)

	model:Destroy()

	if not animationId then

		return {
			Success = false,
			Message =
				"O asset foi encontrado, mas não foi encontrada "
				.. "uma Animation dentro dele."
		}
	end

	--------------------------------------------------
	-- CACHE
	--------------------------------------------------

	cache[assetId] = {
		Name = info.Name or "Emote",
		AnimationId = animationId
	}

	return {
		Success = true,
		Name = info.Name or "Emote",
		AnimationId = animationId
	}
end

--------------------------------------------------
-- REQUEST
--------------------------------------------------

remote.OnServerEvent:Connect(function(player, action, assetId)

	if action ~= "Convert" then
		return
	end

	if typeof(assetId) ~= "number" then
		remote:FireClient(player, "Result", {
			Success = false,
			Message = "Marketplace ID inválido."
		})

		return
	end

	-- Proteção simples contra valores absurdos.
	if assetId <= 0 or assetId % 1 ~= 0 then
		remote:FireClient(player, "Result", {
			Success = false,
			Message = "Marketplace ID inválido."
		})

		return
	end

	local result = convertEmote(assetId)

	remote:FireClient(
		player,
		"Result",
		result
	)
end)
