-- El "+99" que sale del botón cuando recolectás: letras crema con borde marrón y el ícono de la
-- moneda al lado. Aparece con un salto, sube y se desvanece.
--   CollectPopup.show(currencyId, amount, worldPosition)
--   CollectPopup.markPads()   -- ícono flotando arriba de cada botón del piso
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Kit = require(ReplicatedStorage.Kit)
local Currencies = require(ReplicatedStorage.Shared.Currencies)
local CurrencyIcon = require(script.Parent.CurrencyIcon)

local Ui = Kit.Ui

local CollectPopup = {}

local CREAM_TOP = Color3.fromRGB(255, 250, 225)
local CREAM_BOTTOM = Color3.fromRGB(240, 205, 130)
local OUTLINE = Color3.fromRGB(95, 55, 20)

local function tween(instance: Instance, seconds: number, props, style: Enum.EasingStyle?)
	local t = TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function CollectPopup.show(id: string, amount: number, position: Vector3)
	local currency = Currencies.byId[id]
	if not currency then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "CollectPopup"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position + Vector3.new(0, 1.5, 0)
	anchor.Parent = workspace

	local gui = Ui.new("BillboardGui", {
		Size = UDim2.fromOffset(260, 90),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Brightness = 1.4,
		Adornee = anchor,
		Parent = anchor,
	})
	local row = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local scale = Ui.new("UIScale", { Scale = 0.3, Parent = row })

	local text = Ui.new("TextLabel", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 70),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextSize = 54,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "+" .. Currencies.format(amount),
		Parent = row,
	})
	Ui.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(CREAM_TOP, CREAM_BOTTOM), Parent = text })
	local outline = Ui.new("UIStroke", { Color = OUTLINE, Thickness = 4, LineJoinMode = Enum.LineJoinMode.Round, Parent = text })

	local icon = CurrencyIcon.new(currency, row, 64)
	icon.LayoutOrder = 2

	-- Salto de entrada, sube y se desvanece.
	tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(anchor, 1.3, { Position = anchor.Position + Vector3.new(0, 5, 0) })
	task.delay(0.7, function()
		local fade = Instance.new("NumberValue")
		fade.Changed:Connect(function(value)
			text.TextTransparency = value
			outline.Transparency = value
			CurrencyIcon.fade(icon, value)
		end)
		tween(fade, 0.6, { Value = 1 }).Completed:Connect(function()
			fade:Destroy()
			anchor:Destroy()
		end)
	end)
end

-- Ícono que flota y sube y baja arriba de cada botón del piso.
function CollectPopup.markPads()
	local floating: { { gui: BillboardGui, phase: number } } = {}
	local function mark(pad: Instance)
		local id = pad:GetAttribute("Currency")
		local currency = id and Currencies.byId[id]
		local sensor = pad:WaitForChild("Sensor", 5)
		local anchor = sensor and sensor:WaitForChild("IconAnchor", 5)
		if not currency or not anchor then
			return
		end
		local gui = Ui.new("BillboardGui", {
			Name = "PadIcon",
			Size = UDim2.fromOffset(84, 84),
			LightInfluence = 0,
			Brightness = 1.6, -- un poco más brillante que el resto, para que resalte
			MaxDistance = 80,
			Adornee = anchor,
			Parent = anchor,
		})
		-- Halo del color de la moneda detrás del ícono.
		local glow = Ui.new("Frame", {
			Name = "Glow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
			BackgroundColor3 = currency.color,
			BackgroundTransparency = 0.55,
			Parent = gui,
		})
		Ui.round(glow, 40)
		Ui.new("UIGradient", {
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Rotation = 90,
			Parent = glow,
		})
		local icon = CurrencyIcon.new(currency, gui, 84)
		icon.Position = UDim2.fromScale(0, 0)
		icon.ZIndex = 2
		table.insert(floating, { gui = gui, phase = math.random() * 6 })
	end
	local function watch(folder: Instance)
		for _, pad in folder:GetChildren() do
			task.spawn(mark, pad)
		end
		folder.ChildAdded:Connect(function(pad)
			task.spawn(mark, pad)
		end)
	end
	task.spawn(function()
		watch(workspace:WaitForChild("CollectPads"))
	end)
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for _, entry in floating do
			entry.gui.StudsOffset = Vector3.new(0, math.sin(now * 2 + entry.phase) * 0.35, 0)
		end
	end)
end

return CollectPopup
