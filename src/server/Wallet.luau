-- Billetera de cada jugador: oro, gemas y comida. Se guardan con Kit.DataStore y se publican como
-- atributos del jugador ("gold", "gems", "food") para que la interfaz los muestre.
--   Wallet.start()
--   Wallet.add(player, "gold", 120)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)
local Currencies = require(ReplicatedStorage.Shared.Currencies)

local Wallet = {}

local Saves = Kit.DataStore.new({
	name = "HuevosBloques_Wallet_v1",
	defaults = function()
		local data = {}
		for _, currency in Currencies.list do
			data[currency.id] = 0
		end
		return data
	end,
})

local function publish(player: Player)
	local data = Saves.get(player)
	if not data then
		return
	end
	for _, currency in Currencies.list do
		player:SetAttribute(currency.id, data[currency.id])
	end
end

function Wallet.get(player: Player, id: string): number
	local data = Saves.get(player)
	return if data then data[id] or 0 else 0
end

function Wallet.add(player: Player, id: string, amount: number): boolean
	local data = Saves.get(player)
	if not data or not Currencies.byId[id] then
		return false
	end
	data[id] = math.max(0, (data[id] or 0) + amount)
	player:SetAttribute(id, data[id])
	return true
end

function Wallet.start()
	Saves.start()
	local function onPlayerAdded(player: Player)
		Saves.load(player)
		publish(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		Saves.release(player)
	end)
end

return Wallet
