-- Monedas en el cliente: la barra de arriba, los íconos sobre los botones y el "+99" al recolectar.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyHud = require(script.Parent.CurrencyHud)
local CollectPopup = require(script.Parent.CollectPopup)

CurrencyHud.start()
CollectPopup.markPads()

local remotes = ReplicatedStorage:WaitForChild("Remotes")
remotes:WaitForChild("Collected").OnClientEvent:Connect(function(id: string, amount: number, position: Vector3)
	CollectPopup.show(id, amount, position)
	CurrencyHud.bump(id)
end)
