-- Botones en el piso: pisás uno y recolectás una cantidad al azar de su moneda.
-- El servidor elige la cantidad, la suma a la billetera y le avisa al cliente (para el "+99").
--   Pads.build(CFrame.new(0, 0, -12))   -- arma los tres en fila, centrados en ese punto
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)
local Currencies = require(ReplicatedStorage.Shared.Currencies)
local Wallet = require(script.Parent.Wallet)

local Parts = Kit.Parts

local Pads = {}

local GAP = 9 -- studs entre botón y botón
local SIZE = 6 -- diámetro del botón

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local collected = Instance.new("RemoteEvent")
collected.Name = "Collected" -- (id de moneda, cantidad, posición del botón)
collected.Parent = remotes

local rng = Random.new()

-- Hunde el botón un momento y lo vuelve a subir.
local function press(button: BasePart, home: CFrame)
	button.CFrame = home * CFrame.new(-0.25, 0, 0) -- el cilindro está acostado: su -X es hacia abajo
	task.delay(0.25, function()
		button.CFrame = home
	end)
end

local function buildPad(currency, cframe: CFrame, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Pad_" .. currency.id
	model:SetAttribute("Currency", currency.id)

	Parts.cylinder("Base", 0.4, SIZE + 1.2, cframe * CFrame.new(0, 0.2, 0), Color3.fromRGB(70, 75, 90), model)
	local ring = Parts.neon(Parts.cylinder("Ring", 0.45, SIZE + 0.4, cframe * CFrame.new(0, 0.25, 0), currency.color, model))
	ring.Transparency = 0.2
	local button = Parts.cylinder("Button", 0.5, SIZE, cframe * CFrame.new(0, 0.55, 0), currency.color, model)
	button.Material = Enum.Material.SmoothPlastic
	local home = button.CFrame

	-- Lo que detecta la pisada: una caja invisible un poco más alta que el botón.
	local sensor = Instance.new("Part")
	sensor.Name = "Sensor"
	sensor.Anchored = true
	sensor.CanCollide = false
	sensor.Transparency = 1
	sensor.Size = Vector3.new(SIZE - 0.5, 2, SIZE - 0.5)
	sensor.CFrame = cframe * CFrame.new(0, 1.5, 0)
	sensor.Parent = model

	-- El ícono flotante y el nombre los dibuja el cliente (Hud de monedas) sobre este punto.
	local anchor = Instance.new("Attachment")
	anchor.Name = "IconAnchor"
	anchor.Position = Vector3.new(0, 3, 0)
	anchor.Parent = sensor

	local lastUse: { [Player]: number } = {}
	sensor.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local now = os.clock()
		if lastUse[player] and now - lastUse[player] < currency.pad.cooldown then
			return
		end
		lastUse[player] = now
		local amount = rng:NextInteger(currency.pad.min, currency.pad.max)
		if Wallet.add(player, currency.id, amount) then
			press(button, home)
			collected:FireClient(player, currency.id, amount, sensor.Position)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)

	model.Parent = parent
	return model
end

function Pads.build(center: CFrame, parent: Instance?): Folder
	local folder = Instance.new("Folder")
	folder.Name = "CollectPads"
	for i, currency in Currencies.list do
		local offset = (i - (#Currencies.list + 1) / 2) * GAP
		buildPad(currency, center * CFrame.new(offset, 0, 0), folder)
	end
	folder.Parent = parent or workspace
	return folder
end

return Pads
