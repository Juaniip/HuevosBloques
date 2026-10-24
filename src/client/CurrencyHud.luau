-- Barra de monedas arriba al centro: gemas, oro y comida, cada una con su ícono grande, el número
-- y el botón verde "+". El número sube contando y el ícono salta cuando ganás.
--   CurrencyHud.start()
--   CurrencyHud.plusClicked:Connect(function(currencyId) ... end)   -- para la tienda que viene
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Kit = require(ReplicatedStorage.Kit)
local Currencies = require(ReplicatedStorage.Shared.Currencies)
local CurrencyIcon = require(script.Parent.CurrencyIcon)

local Ui = Kit.Ui
local player = Players.LocalPlayer

local CurrencyHud = {}

local plusEvent = Instance.new("BindableEvent")
CurrencyHud.plusClicked = plusEvent.Event

local ITEM_WIDTH = 210
local ITEM_HEIGHT = 56
local GAP = 26
local FONT = Enum.Font.FredokaOne

local icons: { [string]: GuiObject } = {}

local function bounce(target: GuiObject)
	local scale = target:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = target
	scale.Scale = 1.3
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function plusButton(parent: Instance, currency)
	local button = Ui.new("TextButton", {
		Name = "Plus",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 4, 0.5, 0),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 4,
		Parent = parent,
	})
	Ui.round(button, 9)
	-- El "+" va en su propio texto: el degradé verde del botón también teñiría el texto del botón.
	local plus = Ui.new("TextLabel", {
		Name = "Sign",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = "+",
		TextSize = 38,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 5,
		Parent = button,
	})
	Ui.new("UIStroke", { Color = Color3.fromRGB(30, 95, 20), Thickness = 2, Parent = plus })
	Ui.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(150, 230, 80), Color3.fromRGB(60, 165, 35)),
		Parent = button,
	})
	Ui.new("UIStroke", { Color = Color3.fromRGB(30, 95, 20), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = button })
	button.Activated:Connect(function()
		bounce(button)
		plusEvent:Fire(currency.id)
	end)
	return button
end

local function item(parent: Instance, currency, order: number)
	local holder = Ui.new("Frame", {
		Name = currency.id,
		LayoutOrder = order,
		Size = UDim2.fromOffset(ITEM_WIDTH, ITEM_HEIGHT),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	-- Píldora oscura semitransparente.
	local bar = Ui.new("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 22, 0.5, 0),
		Size = UDim2.new(1, -22, 0, 40),
		BackgroundColor3 = Color3.fromRGB(15, 20, 30),
		BackgroundTransparency = 0.45,
		Parent = holder,
	})
	Ui.round(bar, 8)
	local amount = Ui.new("TextLabel", {
		Name = "Amount",
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -92, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "0",
		ZIndex = 2,
		Parent = bar,
	})
	Ui.new("UIStroke", { Color = Color3.fromRGB(10, 10, 15), Thickness = 2, Parent = amount })
	plusButton(bar, currency)

	local icon = CurrencyIcon.new(currency, holder, ITEM_HEIGHT)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.fromScale(0, 0.5)
	icon.ZIndex = 5
	icons[currency.id] = icon

	-- Número: cuenta hasta el valor nuevo cuando cambia el atributo del jugador.
	local shown = player:GetAttribute(currency.id) or 0
	amount.Text = Currencies.format(shown)
	player:GetAttributeChangedSignal(currency.id):Connect(function()
		local value = player:GetAttribute(currency.id) or 0
		if value > shown then
			bounce(icon)
		end
		Ui.countTo(amount, shown, value, Currencies.format)
		shown = value
	end)
end

-- Achica la barra en pantallas angostas (celulares).
local function fitToScreen(container: Frame, scale: UIScale)
	local camera = workspace.CurrentCamera
	local function update()
		local total = 0
		for _, currency in Currencies.list do
			if currency.bar ~= false then
				total += ITEM_WIDTH + GAP
			end
		end
		scale.Scale = math.min(1, (camera.ViewportSize.X - 24) / total)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
end

function CurrencyHud.start()
	local gui = Ui.new("ScreenGui", {
		Name = "CurrencyHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local container = Ui.new("Frame", {
		Name = "Currencies",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(0, ITEM_HEIGHT),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = container,
	})
	fitToScreen(container, Ui.new("UIScale", { Parent = container }))
	for order, currency in Currencies.list do
		if currency.bar ~= false then
			item(container, currency, order)
		end
	end
end

-- Hace saltar el ícono de una moneda (lo usa el "+99" al llegar).
function CurrencyHud.bump(id: string)
	local icon = icons[id]
	if icon then
		bounce(icon)
	end
end

return CurrencyHud
