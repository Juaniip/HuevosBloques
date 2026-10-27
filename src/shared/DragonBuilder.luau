-- Arma un dragón de bloques a partir de su especie (ver Dragons/) y la fase ("bebe", "joven", "adulto").
--   DragonBuilder.build(especie, "bebe", parent, cframe?) -> Model
-- El dragón mira hacia -Z y queda parado sobre el origen (el pivote está en el piso, bajo el cuerpo).
-- Las medidas de cada fase están en el archivo de la especie; el tamaño final lo da `scale`.
--
-- Para la animación (Walk.client.luau) cada pieza lleva el atributo "Rig" con la parte a la que
-- pertenece (body, head, tail, wingL, wingR, legFL, legFR, legBL, legBR) y las de la cola llevan
-- "Bend" (0 en la base, 1 en la punta). Los puntos de giro son Attachments dentro de "RigRoot".
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)

local Parts = Kit.Parts
local Particles = Kit.Particles

local DragonBuilder = {}

local CYLINDER = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local AXIS = CFrame.Angles(0, math.pi / 2, 0) -- lleva el eje X de un cilindro hacia -Z (adelante)
local FORWARD = Vector3.new(0, 0, -1)

local function resolvePalette(raw)
	local palette = {}
	for key, entry in raw do
		palette[key] = {
			color = Color3.fromRGB(entry[1], entry[2], entry[3]),
			neon = entry.neon,
			glass = entry.glass,
			shine = entry.shine,
		}
	end
	return palette
end

local function bezier(a: Vector3, c: Vector3, b: Vector3, t: number): Vector3
	return a * (1 - t) ^ 2 + c * (2 * (1 - t) * t) + b * t * t
end

function DragonBuilder.build(species, stageId: string, parent: Instance?, cframe: CFrame?): Model
	local P = species.stages[stageId] or error(`[DragonBuilder] {species.id} no tiene la fase "{stageId}"`)
	local palette = resolvePalette(species.palette)
	for key, entry in resolvePalette(P.palette or {}) do
		palette[key] = entry -- colores propios de esta fase
	end

	local model = Instance.new("Model")
	model.Name = `{species.name} {P.name}`
	model:SetAttribute("DragonId", species.id)
	model:SetAttribute("Stage", stageId)

	-- Puntos de giro para la animación.
	local rigRoot = Instance.new("Part")
	rigRoot.Name = "RigRoot"
	rigRoot.Anchored = true
	rigRoot.CanCollide = false
	rigRoot.CanQuery = false
	rigRoot.CanTouch = false
	rigRoot.Transparency = 1
	rigRoot.Size = Vector3.one * 0.2
	rigRoot.CFrame = CFrame.new()
	rigRoot.Parent = model
	local function pivot(name: string, at: Vector3)
		local attachment = Instance.new("Attachment")
		attachment.Name = name
		attachment.Position = at
		attachment.Parent = rigRoot
	end

	-- Piezas ---------------------------------------------------------------------------------
	local rig, bend = "body", nil :: number?
	local function style(part: BasePart, key: string): BasePart
		local entry = palette[key] or error(`[DragonBuilder] {species.id}: el color "{key}" no está en la paleta`)
		part.Anchored = true
		part.CanTouch = false
		part.CanCollide = false
		part.Color = entry.color
		if entry.neon then
			part.Material = Enum.Material.Neon
		end
		part.Transparency = entry.glass or 0
		part.Reflectance = entry.shine or 0
		part:SetAttribute("Rig", rig)
		if bend then
			part:SetAttribute("Bend", bend)
		end
		part.Parent = model
		return part
	end
	-- Ladrillo con studs.
	local function brick(name: string, size: Vector3, cf: CFrame, key: string)
		return style(Parts.block(name, size, cf, Color3.new(), nil), key)
	end
	-- Pieza lisa (bloque, cilindro o bola).
	local function smooth(name: string, size: Vector3, cf: CFrame, key: string, shape: Enum.PartType?)
		return style(Parts.shaped(name, size, cf, Color3.new(), nil, shape or Enum.PartType.Block), key)
	end
	-- Cuña: la cara alta queda atrás (+Z) y la pendiente baja hacia adelante (-Z).
	local function wedge(name: string, size: Vector3, cf: CFrame, key: string)
		local part = Instance.new("WedgePart")
		part.Name = name
		part.Size = size
		part.CFrame = cf
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		return style(part, key)
	end
	-- Cilindro de `a` a `b`.
	local function rod(name: string, a: Vector3, b: Vector3, diameter: number, key: string)
		local length = (b - a).Magnitude
		if length < 0.01 then
			return nil
		end
		return smooth(name, Vector3.new(length, diameter, diameter), CFrame.lookAt((a + b) / 2, b) * AXIS, key, CYLINDER)
	end
	local function ball(name: string, at: Vector3, diameter: number, key: string)
		return smooth(name, Vector3.one * diameter, CFrame.new(at), key, BALL)
	end
	-- Ladrillo largo de `a` a `b` (su Z va a lo largo); `up` orienta su cara de arriba.
	local function beam(name: string, a: Vector3, b: Vector3, width: number, height: number, key: string, up: Vector3?)
		local dir = b - a
		if dir.Magnitude < 0.01 then
			return nil
		end
		local upVector = up or Vector3.yAxis
		if math.abs(dir.Unit:Dot(upVector)) > 0.97 then
			upVector = if math.abs(dir.Unit.Z) > 0.9 then Vector3.yAxis else Vector3.zAxis
		end
		return brick(name, Vector3.new(width, height, dir.Magnitude), CFrame.lookAt((a + b) / 2, b, upVector), key)
	end
	-- Punta que se afina por tramos (cuernos, garras, púas): pasa por los puntos de `points`.
	local function taper(name: string, points: { Vector3 }, from: number, to: number, key: string)
		for i = 1, #points - 1 do
			local t = (i - 1) / math.max(1, #points - 2)
			local d = from + (to - from) * t
			rod(name, points[i], points[i + 1], d, key)
			if i < #points - 1 then
				ball(name .. "Joint", points[i + 1], d * 0.95, key)
			end
		end
		ball(name .. "Tip", points[#points], to * 0.9, key)
	end
	-- Triángulo de membrana hecho con dos cuñas (para las alas).
	local function triangle(a: Vector3, b: Vector3, c: Vector3, key: string, thickness: number)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		if ac:Cross(ab).Magnitude < 1e-4 then
			return
		end
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		wedge("Membrane", Vector3.new(thickness, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2, right, up, back), key)
		wedge("Membrane", Vector3.new(thickness, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2, -right, up, -back), key)
	end
	-- Escudo redondo con studs (hombros y caderas): mira hacia el costado `sx`.
	local function shield(center: Vector3, sx: number, diameter: number)
		smooth("ShieldRim", Vector3.new(0.3, diameter, diameter), CFrame.new(center), "dark", CYLINDER)
		smooth("Shield", Vector3.new(0.35, diameter * 0.78, diameter * 0.78), CFrame.new(center + Vector3.new(sx * 0.08, 0, 0)), "body", CYLINDER)
		for k = 0, 2 do
			local angle = k * math.pi * 2 / 3 + 0.5
			local offset = Vector3.new(sx * 0.25, math.sin(angle) * diameter * 0.2, math.cos(angle) * diameter * 0.2)
			smooth("ShieldStud", Vector3.new(0.18, 0.32, 0.32), CFrame.new(center + offset), "body", CYLINDER)
		end
	end
	-- Garra amarilla curva que sale de `toe` hacia adelante y abajo.
	local function claw(toe: Vector3, size: number)
		taper("Claw", {
			toe,
			toe + Vector3.new(0, -0.02, -0.35 * size),
			toe + Vector3.new(0, -0.18 * size, -0.62 * size),
			toe + Vector3.new(0, -0.36 * size, -0.72 * size),
		}, 0.34 * size, 0.1 * size, "claw")
	end

	-- Cuerpo ---------------------------------------------------------------------------------
	local body = P.body
	local halfL = body.length / 2
	local bodyY = body.lift + body.height / 2
	local top = body.lift + body.height
	local w = body.width

	brick("Body", Vector3.new(w, body.height, body.length), CFrame.new(0, bodyY, 0), "body")
	smooth("Rump", Vector3.new(w * 0.98, body.height, body.height), CFrame.new(0, bodyY, halfL), "body", CYLINDER)
	smooth("Front", Vector3.new(w * 0.98, body.height, body.height), CFrame.new(0, bodyY, -halfL), "body", CYLINDER)

	-- Placas del lomo, oscuras y rojas alternadas.
	local plates = math.max(2, math.floor(body.length / 0.9))
	for i = 1, plates do
		local z = -halfL + (i - 0.5) * body.length / plates
		brick("BackPlate", Vector3.new(w * 0.72, 0.35, body.length / plates * 0.95), CFrame.new(0, top + 0.17, z), if i % 2 == 0 then "dark" else "body")
	end
	-- Panza crema en franjas y pecho en capas.
	brick("Belly", Vector3.new(w * 0.8, body.height * 0.35, body.length * 0.95), CFrame.new(0, body.lift + body.height * 0.14, 0), "belly")
	local stripes = math.max(2, math.floor(body.length / 0.75))
	for i = 1, stripes do
		local z = -halfL + (i - 0.5) * body.length / stripes
		smooth("BellyStripe", Vector3.new(w * 0.82, 0.12, 0.12), CFrame.new(0, body.lift - 0.02, z), "bellyDark")
	end
	for i, width in { 0.78, 0.68, 0.56 } do
		local y = bodyY - body.height * 0.3 + (i - 1) * body.height * 0.3
		brick("Chest", Vector3.new(w * width, body.height * 0.3, 0.7), CFrame.new(0, y, -halfL - body.height * 0.42 + (i - 1) * 0.08), if i == 2 then "bellyDark" else "belly")
	end

	-- Llamas pintadas a los costados.
	if P.flankFlames then
		for _, sx in { -1, 1 } do
			for i, spec in { { -0.1, 1.5, "wing1" }, { 0.18, 1.15, "wing2" }, { 0.42, 0.85, "wing1" } } do
				local cf = CFrame.new(sx * (w / 2 + 0.08), bodyY + 0.15 * i - 0.2, spec[1] * body.length) * CFrame.Angles(math.rad(-25), math.pi, 0)
				wedge("FlankFlame", Vector3.new(0.12, spec[2], spec[2] * 1.5), cf, spec[3])
			end
		end
	end

	-- Púas sobre el lomo (la cara alta hacia la cabeza, la pendiente hacia la cola).
	for i = 1, P.spikes or 0 do
		local z = -halfL + 0.6 + (i - 1) * (body.length - 0.6) / math.max(1, P.spikes - 1)
		wedge("BackSpike", Vector3.new(0.32, 0.85, 0.95), CFrame.new(0, top + 0.77, z) * CFrame.Angles(0, math.pi, 0), "horn")
	end

	-- Patas ----------------------------------------------------------------------------------
	local legs = P.legs
	local hipY = body.lift + body.height * 0.38
	local function foot(x: number, z: number, thick: number)
		brick("Foot", Vector3.new(thick * 1.25, 0.5, thick * 1.2), CFrame.new(x, 0.25, z), "dark")
		for k = -1, 1 do
			local toe = Vector3.new(x + k * thick * 0.4, 0.32, z - thick * 0.55)
			smooth("Toe", Vector3.new(thick * 0.34, 0.45, 0.5), CFrame.new(toe + Vector3.new(0, 0, -0.1)), "body")
			claw(toe + Vector3.new(0, -0.02, -0.3), legs.claw or 1)
		end
	end
	local function frontLeg(sx: number, z: number)
		local thick = legs.thick
		local x = sx * (w / 2 - thick / 2 + 0.15)
		local hip = Vector3.new(x, hipY, z)
		pivot(rig, hip)
		local elbow = hip + Vector3.new(0, -hipY * 0.5, -0.25)
		local wrist = Vector3.new(x, 0.6, z - 0.05)
		shield(Vector3.new(sx * (w / 2 + 0.2), hipY + 0.25, z), sx, thick * 1.9)
		beam("UpperArm", hip, elbow, thick, thick * 1.05, "body", FORWARD)
		ball("Elbow", elbow, thick * 1.05, "dark")
		beam("Forearm", elbow, wrist, thick * 0.85, thick * 0.85, "body", FORWARD)
		foot(x, z - thick * 0.25, thick)
	end
	local function backLeg(sx: number, z: number)
		local thick = legs.thick * 1.15
		local x = sx * (w / 2 - thick / 2 + 0.2)
		local hip = Vector3.new(x, hipY + 0.1, z)
		pivot(rig, hip)
		local knee = hip + Vector3.new(0, -hipY * 0.42, -thick * 0.7)
		local ankle = Vector3.new(x, hipY * 0.3, z + thick * 0.45)
		local heel = Vector3.new(x, 0.5, z - thick * 0.1)
		shield(Vector3.new(sx * (w / 2 + 0.25), hipY + 0.2, z), sx, thick * 2.2)
		beam("Thigh", hip, knee, thick * 1.2, thick * 1.25, "body", FORWARD)
		ball("Knee", knee, thick * 1.1, "dark")
		beam("Shin", knee, ankle, thick * 0.9, thick * 0.9, "body", FORWARD)
		ball("Ankle", ankle, thick * 0.8, "dark")
		beam("Hock", ankle, heel, thick * 0.7, thick * 0.7, "body", FORWARD)
		foot(x, z - thick * 0.4, thick)
	end
	for _, sx in { -1, 1 } do
		local side = if sx < 0 then "R" else "L"
		rig = "legF" .. side
		frontLeg(sx, -halfL + legs.thick * 0.55)
		rig = "legB" .. side
		backLeg(sx, halfL - legs.thick * 0.55)
	end
	rig = "body"

	-- Cuello y cabeza --------------------------------------------------------------------------
	local H = P.head
	local neckBase = Vector3.new(0, top - 0.4, -halfL + 0.3)
	rig = "head"
	pivot("head", neckBase)
	local headPos
	if P.neck then
		local n = P.neck
		local tip = neckBase + Vector3.new(0, n.rise, -n.forward)
		local bendPoint = neckBase + Vector3.new(0, n.rise * 0.55, n.forward * 0.15)
		local prev = neckBase
		for i = 1, n.segments do
			local t = i / n.segments
			local point = bezier(neckBase, bendPoint, tip, t)
			local thick = n.thick * (1 - 0.25 * t)
			beam("Neck", prev, point, thick, thick * 1.1, "body", FORWARD)
			ball("NeckJoint", point, thick * 1.08, "body")
			local throat = Vector3.new(0, 0, -thick * 0.42)
			beam("Throat", prev + throat, point + throat, thick * 0.72, thick * 0.5, if i % 2 == 0 then "bellyDark" else "belly", FORWARD)
			for _, sx in { -1, 1 } do
				beam("NeckScale", prev + Vector3.new(sx * thick * 0.5, 0, thick * 0.1), point + Vector3.new(sx * thick * 0.45, 0, thick * 0.1), 0.15, thick * 0.55, "dark", FORWARD)
			end
			if (P.spikes or 0) > 0 then
				wedge("NeckSpike", Vector3.new(0.28, 0.65, 0.75), CFrame.new(point + Vector3.new(0, 0, thick * 0.58)) * CFrame.Angles(math.rad(60), math.pi, 0), "horn")
			end
			prev = point
		end
		headPos = tip + Vector3.new(0, H.height * 0.25, -H.length * 0.2)
	else
		headPos = Vector3.new(0, top + H.raise, -halfL - H.forward)
	end

	local head = CFrame.new(headPos) * CFrame.Angles(math.rad(H.pitch or 0), 0, 0)
	local function at(x: number, y: number, z: number): Vector3
		return (head * CFrame.new(x, y, z)).Position
	end
	brick("Skull", Vector3.new(H.width, H.height, H.length), head, "body")

	if H.cartoon then
		-- Bebé: cara redonda, cachetes, hocico ancho, colmillitos y ojos grandes.
		smooth("Dome", Vector3.new(H.width * 0.98, H.height * 0.6, H.length * 0.9), head * CFrame.new(0, H.height * 0.42, 0.05), "body", BALL)
		for _, sx in { -1, 1 } do
			ball("Cheek", at(sx * H.width * 0.38, -H.height * 0.22, -H.length * 0.15), H.height * 0.45, "body")
		end
		local snout = head * CFrame.new(0, -H.height * 0.2, -H.length / 2 - H.snout / 2 + 0.25)
		brick("Snout", Vector3.new(H.width * 0.82, H.height * 0.45, H.snout), snout, "body")
		brick("NoseTop", Vector3.new(H.width * 0.6, 0.3, H.snout * 0.7), snout * CFrame.new(0, H.height * 0.24, -0.05), "body")
		smooth("Mouth", Vector3.new(H.width * 0.7, 0.08, 0.08), snout * CFrame.new(0, -H.height * 0.1, -H.snout / 2 - 0.02), "nostril")
		brick("Chin", Vector3.new(H.width * 0.7, H.height * 0.18, H.snout * 0.9), snout * CFrame.new(0, -H.height * 0.3, 0.05), "body")
		for _, sx in { -1, 1 } do
			smooth("Nostril", Vector3.new(0.25, 0.18, 0.12), snout * CFrame.new(sx * H.width * 0.2, H.height * 0.12, -H.snout / 2 - 0.02), "nostril")
			wedge("Fang", Vector3.new(0.22, 0.42, 0.25), snout * CFrame.new(sx * H.width * 0.22, -H.height * 0.24, -H.snout / 2 + 0.05) * CFrame.Angles(math.rad(-90), 0, 0), "tooth")
			-- Ojo grande: blanco, iris marrón, pupila y brillo.
			local d = H.height * 0.5
			local eye = head * CFrame.new(sx * (H.width / 2 + 0.05), H.height * 0.1, -H.length * 0.12)
			smooth("EyeWhite", Vector3.new(0.2, d, d), eye, "eyeWhite", CYLINDER)
			smooth("Iris", Vector3.new(0.22, d * 0.68, d * 0.68), eye * CFrame.new(sx * 0.04, -d * 0.02, -d * 0.06), "iris", CYLINDER)
			smooth("Pupil", Vector3.new(0.24, d * 0.4, d * 0.4), eye * CFrame.new(sx * 0.07, -d * 0.02, -d * 0.08), "pupil", CYLINDER)
			smooth("Shine", Vector3.new(0.26, d * 0.17, d * 0.17), eye * CFrame.new(sx * 0.09, d * 0.14, -d * 0.18), "eyeWhite", CYLINDER)
			beam("EyeBrow", at(sx * (H.width / 2 + 0.05), H.height * 0.42, -H.length * 0.3), at(sx * (H.width / 2 + 0.05), H.height * 0.36, H.length * 0.1), 0.2, 0.22, "dark")
			-- Aletitas a los costados de la cabeza.
			wedge("EarFin", Vector3.new(0.25, H.height * 0.45, H.length * 0.5), head * CFrame.new(sx * (H.width / 2 + 0.15), H.height * 0.05, H.length * 0.35) * CFrame.Angles(0, math.pi + sx * 0.5, 0), "body")
		end
	else
		-- Joven y adulto: hocico largo, nariz con cuernito, dientes, mandíbula abierta, cejas y aletas.
		local snoutRear = head * CFrame.new(0, -H.height * 0.12, -H.length / 2 - H.snout * 0.25 + 0.15)
		brick("Snout", Vector3.new(H.width * 0.8, H.height * 0.6, H.snout * 0.55), snoutRear, "body")
		local snoutFront = snoutRear * CFrame.new(0, -H.height * 0.05, -H.snout * 0.5)
		brick("SnoutTip", Vector3.new(H.width * 0.62, H.height * 0.48, H.snout * 0.5), snoutFront, "body")
		brick("NoseRidge", Vector3.new(H.width * 0.32, 0.22, H.snout * 0.9), snoutRear * CFrame.new(0, H.height * 0.32, -H.snout * 0.2), "dark")
		local noseTop = (snoutFront * CFrame.new(0, H.height * 0.24, -H.snout * 0.15)).Position
		taper("NoseHorn", { noseTop, noseTop + Vector3.new(0, 0.35, 0.05), noseTop + Vector3.new(0, 0.55, 0.25) }, 0.28, 0.08, "horn")
		for _, sx in { -1, 1 } do
			smooth("Nostril", Vector3.new(0.22, 0.16, 0.12), snoutFront * CFrame.new(sx * H.width * 0.18, H.height * 0.12, -H.snout * 0.25 - 0.02), "nostril")
			for k = 0, 2 do
				local tooth = snoutFront * CFrame.new(sx * H.width * 0.26, -H.height * 0.24, -H.snout * 0.18 + k * H.snout * 0.28)
				wedge("Tooth", Vector3.new(0.16, H.tooth or 0.35, 0.2), tooth * CFrame.Angles(math.rad(-90), 0, 0), "tooth")
			end
		end
		-- Mandíbula de abajo, un poco abierta, con la parte de abajo crema y dos colmillos.
		local hinge = head * CFrame.new(0, -H.height * 0.42, H.length * 0.2) * CFrame.Angles(math.rad(H.jawOpen or 10), 0, 0)
		local jawLength = H.length * 0.7 + H.snout * 0.85
		local jaw = hinge * CFrame.new(0, 0, -jawLength / 2)
		brick("Jaw", Vector3.new(H.width * 0.6, H.height * 0.22, jawLength), jaw, "body")
		brick("JawUnder", Vector3.new(H.width * 0.45, H.height * 0.12, jawLength * 0.8), jaw * CFrame.new(0, -H.height * 0.14, 0.1), "belly")
		for _, sx in { -1, 1 } do
			wedge("Fang", Vector3.new(0.16, 0.3, 0.2), jaw * CFrame.new(sx * H.width * 0.22, H.height * 0.22, -jawLength * 0.4) * CFrame.Angles(math.rad(90), 0, 0), "tooth")
		end
		for _, sx in { -1, 1 } do
			-- Ojo amarillo con pupila y ceja angulosa.
			local eye = head * CFrame.new(sx * (H.width / 2 + 0.02), H.height * 0.12, -H.length * 0.22)
			smooth("Eye", Vector3.new(0.12, 0.45, 0.65), eye, "eye")
			smooth("Pupil", Vector3.new(0.14, 0.42, 0.15), eye * CFrame.new(sx * 0.02, 0, -0.05), "pupil")
			smooth("EyeShine", Vector3.new(0.15, 0.1, 0.1), eye * CFrame.new(sx * 0.03, 0.12, -0.18), "eyeWhite")
			wedge("Brow", Vector3.new(0.35, 0.4, H.length * 0.55), eye * CFrame.new(-sx * 0.05, 0.4, 0.1) * CFrame.Angles(0, math.pi, 0), "dark")
			-- Cuernito sobre el ojo.
			local brow = at(sx * H.width * 0.38, H.height * 0.5, -H.length * 0.05)
			taper("BrowHorn", { brow, brow + Vector3.new(sx * 0.1, 0.4, 0.15), brow + Vector3.new(sx * 0.12, 0.65, 0.45) }, 0.3, 0.08, "horn")
			-- Aletas de las mejillas: abanico oscuro hacia atrás.
			local cheek = at(sx * H.width * 0.45, -H.height * 0.2, H.length * 0.3)
			for k, angle in { -0.5, -0.1, 0.35 } do
				local length = (H.cheek or 1.4) * (1 - k * 0.15)
				local tipPoint = cheek + Vector3.new(sx * length * 0.45, math.sin(angle) * length, math.cos(angle) * length)
				beam("CheekFin", cheek, tipPoint, 0.15, 0.4 - k * 0.06, "crest")
			end
		end
	end

	-- Cuernos: suben y se curvan para atrás.
	if P.horns then
		local horns = P.horns
		local L = horns.length
		for _, sx in { -1, 1 } do
			local base = at(sx * H.width * 0.3, H.height / 2, H.length * 0.15)
			local spread = horns.spread or 0.15
			local p1 = base + Vector3.new(sx * spread, L * 0.45, L * 0.05)
			local p2 = p1 + Vector3.new(sx * spread * 0.4, L * 0.35, L * 0.25)
			local p3 = p2 + Vector3.new(0, L * 0.15, L * 0.4)
			taper("Horn", { base, p1, p2, p3 }, horns.thick, horns.thick * 0.3, "horn")
		end
	end

	-- Cresta: bloques escalonados (bebé) o un abanico de púas con forma de hoja (joven y adulto).
	local crest = P.crest
	if crest and crest.kind == "blocks" then
		local crown = head * CFrame.new(0, H.height / 2 + H.height * 0.18, H.length * 0.12)
		local steps = { { -0.3, 0.6, 0.3, "crest" }, { -0.05, 0.95, 0.35, "crestDark" }, { 0.22, 0.75, 0.3, "crest" }, { 0.42, 0.5, 0.25, "crestDark" } }
		for _, step in steps do
			brick("Crest", Vector3.new(H.width * 0.7, step[2], H.length * step[3]), crown * CFrame.new(0, step[2] / 2, step[1] * H.length), step[4])
		end
	elseif crest and crest.kind == "spikes" then
		local root = at(0, H.height * 0.35, H.length * 0.4)
		for i = 1, crest.count do
			local t = (i - 1) / math.max(1, crest.count - 1)
			local angle = math.rad(10 + t * 75) -- desde casi vertical hasta casi para atrás
			local length = crest.length * (1 - math.abs(t - 0.3) * 0.55)
			local x = (if i % 2 == 0 then 1 else -1) * 0.22
			local dir = Vector3.new(0, math.cos(angle), math.sin(angle))
			local base = root + Vector3.new(x, 0, 0)
			local mid = base + dir * length * 0.55 + Vector3.new(x * 0.4, 0, 0)
			local tipPoint = base + dir * length + Vector3.new(x * 0.6, 0, length * 0.08)
			local key = if i % 2 == 0 then "crestDark" else "crest"
			-- Forma de hoja: ancha en la base y fina en la punta.
			beam("CrestSpike", base, mid, 0.3, 1.0, key)
			beam("CrestSpike", mid, tipPoint, 0.24, 0.5, key)
		end
	end
	rig = "body"

	-- Alas -----------------------------------------------------------------------------------
	local W = P.wings
	if W then
		local fingers = if W.fingers == 3
			then { { 0.55, 0.9 }, { 0.85, 0.5 }, { 0.75, 0.05 } }
			else { { 0.45, 1.0 }, { 0.8, 0.78 }, { 1.0, 0.42 }, { 0.85, 0.05 } }
		for _, sx in { -1, 1 } do
			rig = if sx < 0 then "wingR" else "wingL"
			local shoulder = Vector3.new(sx * w * 0.35, top + 0.1, -halfL + body.length * 0.3)
			pivot(rig, shoulder)
			local tilt = math.rad(W.tilt or 25)
			local upward = Vector3.new(sx * math.sin(tilt), math.cos(tilt), 0)
			local function wingPoint(back: number, up: number): Vector3
				return shoulder + Vector3.zAxis * (back * W.span) + upward * (up * W.span)
			end
			local elbow, wrist = wingPoint(0.05, 0.5), wingPoint(-0.12, 0.88)
			local tips, middles = {}, {}
			for i, spec in fingers do
				tips[i] = wingPoint(spec[1], spec[2])
				middles[i] = wrist:Lerp(tips[i], 0.55)
			end
			-- Membrana: adentro roja/naranja, afuera amarilla, con el borde de atrás en ondas.
			local colors = W.colors
			for i = 1, #tips - 1 do
				local edge = ((tips[i] + tips[i + 1]) / 2):Lerp(wrist, 0.16)
				triangle(wrist, middles[i], middles[i + 1], colors.inner, 0.15)
				triangle(middles[i], tips[i], edge, colors.outer, 0.15)
				triangle(middles[i], edge, middles[i + 1], colors.outer, 0.15)
				triangle(edge, tips[i + 1], middles[i + 1], colors.outer, 0.15)
			end
			triangle(wrist, tips[#tips], elbow, colors.base, 0.15)
			triangle(elbow, tips[#tips], shoulder, colors.base, 0.15)
			-- Huesos.
			rod("WingArm", shoulder, elbow, W.bone, "bone")
			ball("WingJoint", elbow, W.bone * 1.15, "bone")
			rod("WingArm", elbow, wrist, W.bone * 0.9, "bone")
			ball("WingJoint", wrist, W.bone * 1.2, "bone")
			for i, tip in tips do
				rod("WingFinger", wrist, middles[i], W.bone * 0.6, "bone")
				rod("WingFinger", middles[i], tip, W.bone * 0.45, "bone")
				ball("WingKnuckle", middles[i], W.bone * 0.6, "bone")
			end
			local thumb = wrist + Vector3.new(0, W.bone * 0.5, 0)
			taper("WingClaw", { thumb, thumb + Vector3.new(0, 0.35, -0.2), thumb + Vector3.new(0, 0.45, -0.45) }, 0.28, 0.08, "horn")
		end
		rig = "body"
	end

	-- Cola con la llama en la punta -------------------------------------------------------
	local T = P.tail
	local start = Vector3.new(0, bodyY, halfL)
	rig = "tail"
	pivot("tail", start)
	local prev = start
	for i = 1, T.segments do
		local t = i / T.segments
		bend = t
		local point = start + Vector3.new(math.sin(t * math.pi) * (T.sway or 0), -math.sin(t * math.pi) * T.drop + t ^ 3 * T.rise, t * T.length)
		local d = T.thick * (1 - t * 0.72)
		rod("Tail", prev, point, d, "body")
		ball("TailJoint", point, d, "body")
		-- Crema por abajo y placas oscuras arriba en la primera mitad.
		if t < 0.75 then
			rod("TailBelly", prev - Vector3.new(0, d * 0.28, 0), point - Vector3.new(0, d * 0.28, 0), d * 0.7, "belly")
		end
		if t < 0.5 and i % 2 == 1 then
			beam("TailPlate", prev + Vector3.new(0, d * 0.45, 0), point + Vector3.new(0, d * 0.45, 0), d * 0.6, 0.25, "dark")
		end
		if (P.spikes or 0) > 0 and i < T.segments - 1 then
			local dir = (point - prev).Unit
			wedge("TailSpike", Vector3.new(0.22, 0.55 * (1 - t * 0.5), 0.65), CFrame.lookAt(point, point - dir) * CFrame.new(0, d / 2 + 0.15, 0), "horn")
		end
		prev = point
	end

	-- Llama: lenguas de fuego alrededor de la punta, naranjas afuera y amarillas adentro.
	bend = 1
	local flame = T.flame or 1.5
	smooth("FlameRing", Vector3.new(0.3, T.thick * 0.5, T.thick * 0.5), CFrame.new(prev) * CFrame.Angles(0, 0, math.pi / 2), "flame", CYLINDER)
	local tongues = {
		{ 0, 0, 1.8, "flame" },
		{ -30, 40, 1.3, "flame" },
		{ 30, -40, 1.35, "flame" },
		{ -15, 160, 1.1, "flameRed" },
		{ 18, 100, 1.0, "flameRed" },
		{ 0, 0, 1.2, "flameCore" },
		{ -12, -80, 0.8, "flameCore" },
	}
	for _, spec in tongues do
		local cf = CFrame.new(prev) * CFrame.Angles(0, math.rad(spec[2]), math.rad(spec[1])) * CFrame.new(0, spec[3] * flame / 2, 0)
		wedge("Flame", Vector3.new(0.18, spec[3] * flame, 0.7 * flame), cf, spec[4])
	end
	local flamePart = smooth("FlameBase", Vector3.one * 0.3, CFrame.new(prev), "flameCore", BALL)
	flamePart.Transparency = 1
	local tipAttachment = Instance.new("Attachment")
	tipAttachment.Name = "FlameTip"
	tipAttachment.Parent = flamePart
	Particles.fire(tipAttachment, { Rate = 14, Size = NumberSequence.new(0.9 * flame, 0.1), Speed = NumberRange.new(1, 2) })
	Particles.light(flamePart, palette.flame.color, 8, 1)
	bend, rig = nil, "body"

	model.WorldPivot = CFrame.new()
	if cframe then
		model:PivotTo(cframe)
	end
	model.Parent = parent
	return model
end

return DragonBuilder
