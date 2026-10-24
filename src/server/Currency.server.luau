-- Monedas: arranca la billetera y pone los botones de recolectar en el piso, cerca de donde aparecés.
local Wallet = require(script.Parent.Wallet)
local Pads = require(script.Parent.Pads)

Wallet.start()
Pads.build(CFrame.new(0, 0, -12))
