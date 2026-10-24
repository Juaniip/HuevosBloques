-- Hace girar despacio los huevos que tenés cerca, para verlos de todos lados.
-- El giro es solo en tu pantalla (las piezas ancladas que mueve el cliente no se replican).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SPEED = 0.5 -- radianes por segundo
local RANGE = 25 -- studs

local gallery = workspace:WaitForChild("Gallery")
local homes: { [Model]: CFrame } = {}
local angles: { [Model]: number } = {}

gallery.ChildRemoved:Connect(function(child)
	homes[child :: Model] = nil
	angles[child :: Model] = nil
end)

RunService.RenderStepped:Connect(function(dt)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	for _, egg in gallery:GetChildren() do
		if egg:IsA("Model") and egg:GetAttribute("EggId") then
			local home = homes[egg]
			if not home then
				home = egg:GetPivot()
				homes[egg] = home
				angles[egg] = 0
			end
			if (home.Position - root.Position).Magnitude < RANGE then
				angles[egg] += dt * SPEED
				egg:PivotTo(home * CFrame.Angles(0, angles[egg], 0))
			end
		end
	end
end)
