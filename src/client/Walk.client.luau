-- Caminata leve de los dragones de la galería, en el lugar (solo en tu pantalla).
-- Usa las marcas que deja DragonBuilder: cada pieza dice a qué parte pertenece ("Rig") y los puntos
-- de giro están en los Attachments de "RigRoot". Patas en diagonal como al trote, el cuerpo sube y
-- baja apenas, la cabeza cabecea, la cola se ondula y las alas aletean un poco.
local RunService = game:GetService("RunService")

local RANGE = 60 -- studs: más lejos no se anima
local SPEED = 3.2 -- velocidad del paso
local LEG_SWING = math.rad(14)
local HEAD_NOD = math.rad(3)
local TAIL_SWAY = math.rad(9)
local WING_FLAP = math.rad(5)

-- Fase de cada pata: las diagonales van juntas (delantera izquierda con trasera derecha).
local LEG_PHASE = { legFL = 0, legBR = 0, legFR = math.pi, legBL = math.pi }

local gallery = workspace:WaitForChild("Gallery")

type Rig = {
	home: CFrame,
	parts: { BasePart },
	rel: { CFrame },
	groups: { string },
	bends: { number },
	pivots: { [string]: Vector3 },
	bob: number,
	phase: number,
}

local rigs: { [Model]: Rig } = {}

local function setup(model: Instance)
	if not model:IsA("Model") or not model:GetAttribute("DragonId") or rigs[model] then
		return
	end
	local root = model:FindFirstChild("RigRoot")
	if not root then
		return
	end
	local home = model:GetPivot()
	local pivots = {}
	for _, attachment in root:GetChildren() do
		if attachment:IsA("Attachment") then
			pivots[attachment.Name] = home:PointToObjectSpace(attachment.WorldPosition)
		end
	end
	local parts, rel, groups, bends = {}, {}, {}, {}
	for _, part in model:GetDescendants() do
		local group = part:IsA("BasePart") and part:GetAttribute("Rig")
		if group then
			table.insert(parts, part)
			table.insert(rel, home:ToObjectSpace(part.CFrame))
			table.insert(groups, group)
			table.insert(bends, part:GetAttribute("Bend") or 0)
		end
	end
	local _, size = model:GetBoundingBox()
	rigs[model] = {
		home = home,
		parts = parts,
		rel = rel,
		groups = groups,
		bends = bends,
		pivots = pivots,
		bob = size.Y * 0.012,
		phase = math.random() * math.pi * 2,
	}
end

for _, child in gallery:GetChildren() do
	setup(child)
end
gallery.ChildAdded:Connect(setup)
gallery.ChildRemoved:Connect(function(child)
	rigs[child :: Model] = nil
end)

-- Gira alrededor de un punto (en el espacio del dragón).
local function around(point: Vector3, rotation: CFrame): CFrame
	return CFrame.new(point) * rotation * CFrame.new(-point)
end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	local now = os.clock()
	for _, rig in rigs do
		if (rig.home.Position - camera.CFrame.Position).Magnitude > RANGE then
			continue
		end
		local t = now * SPEED + rig.phase
		-- El cuerpo sube dos veces por paso (una por cada par de patas), nunca por debajo del piso.
		local lift = CFrame.new(0, (1 - math.cos(2 * t)) / 2 * rig.bob, 0)
		local moves = {
			body = lift,
			head = lift * around(rig.pivots.head or Vector3.zero, CFrame.Angles(math.sin(2 * t + 0.6) * HEAD_NOD, 0, 0)),
			wingL = lift * around(rig.pivots.wingL or Vector3.zero, CFrame.Angles(0, 0, math.sin(t * 0.9) * WING_FLAP)),
			wingR = lift * around(rig.pivots.wingR or Vector3.zero, CFrame.Angles(0, 0, -math.sin(t * 0.9) * WING_FLAP)),
		}
		for leg, phase in LEG_PHASE do
			moves[leg] = lift * around(rig.pivots[leg] or Vector3.zero, CFrame.Angles(math.sin(t + phase) * LEG_SWING, 0, 0))
		end
		local tailPivot = rig.pivots.tail or Vector3.zero
		local cframes = table.create(#rig.parts)
		for i, part in rig.parts do
			local group = rig.groups[i]
			local move
			if group == "tail" then
				-- Cada tramo se dobla un poco más que el anterior: la ola va de la base a la punta.
				local b = rig.bends[i]
				move = lift * around(tailPivot, CFrame.Angles(0, math.sin(t - b * 2.2) * TAIL_SWAY * b, 0))
			else
				move = moves[group] or lift
			end
			cframes[i] = rig.home * move * rig.rel[i]
		end
		workspace:BulkMoveTo(rig.parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
