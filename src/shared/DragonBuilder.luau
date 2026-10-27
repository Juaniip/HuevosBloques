-- Arma un dragón de bloques a partir de su especie (ver Dragons/) y la fase ("bebe", "joven", "adulto").
--   DragonBuilder.build(especie, "bebe", parent, cframe?) -> Model
-- El dragón mira hacia -Z y queda parado sobre el origen (el pivote está en el piso, bajo el cuerpo).
-- Cada fase es una lista de medidas: cuerpo, patas, cuello, cabeza, cuernos, cresta, alas y cola.
-- El tamaño final en la galería lo da `escala` de cada fase.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)

local Parts = Kit.Parts
local Particles = Kit.Particles

local DragonBuilder = {}

local CYLINDER = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local AXIS = CFrame.Angles(0, math.pi / 2, 0) -- lleva el eje X de un cilindro hacia -Z (adelante)

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

	local model = Instance.new("Model")
	model.Name = `{species.name} {P.name}`
	model:SetAttribute("DragonId", species.id)
	model:SetAttribute("Stage", stageId)

	-- Piezas ---------------------------------------------------------------------------------
	local function style(part: BasePart, key: string): BasePart
		local entry = palette[key] or error(`[DragonBuilder] {species.id}: el color "{key}" no está en la paleta`)
		part.Anchored = true
		part.CanTouch = false
		part.Color = entry.color
		if entry.neon then
			part.Material = Enum.Material.Neon
		end
		part.Transparency = entry.glass or 0
		part.Reflectance = entry.shine or 0
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
		local upVector = up or Vector3.yAxis
		if math.abs(dir.Unit:Dot(upVector)) > 0.97 then
			upVector = Vector3.zAxis
		end
		return brick(name, Vector3.new(width, height, dir.Magnitude), CFrame.lookAt((a + b) / 2, b, upVector), key)
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
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		wedge("Membrane", Vector3.new(thickness, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2, right, up, back), key)
		wedge("Membrane", Vector3.new(thickness, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2, -right, up, -back), key)
	end

	-- Cuerpo ---------------------------------------------------------------------------------
	local body = P.body
	local halfL = body.length / 2
	local bodyY = body.lift + body.height / 2
	local top = body.lift + body.height

	brick("Body", Vector3.new(body.width, body.height, body.length), CFrame.new(0, bodyY, 0), "body")
	smooth("Rump", Vector3.new(body.width * 0.98, body.height, body.height), CFrame.new(0, bodyY, halfL), "body", CYLINDER)
	smooth("Front", Vector3.new(body.width * 0.98, body.height, body.height), CFrame.new(0, bodyY, -halfL), "body", CYLINDER)
	brick("Back", Vector3.new(body.width * 0.7, 0.4, body.length * 0.85), CFrame.new(0, top + 0.2, 0), "dark")
	brick("Belly", Vector3.new(body.width * 0.8, body.height * 0.4, body.length * 0.9), CFrame.new(0, body.lift + body.height * 0.15, 0), "belly")
	brick("Chest", Vector3.new(body.width * 0.72, body.height * 0.75, 0.8), CFrame.new(0, bodyY - body.height * 0.08, -halfL - body.height * 0.42), "belly")

	-- Llamas pintadas a los costados.
	if P.flankFlames then
		for _, sx in { -1, 1 } do
			for i, spec in { { -0.15, 1.4, "wing1" }, { 0.2, 1.1, "wing2" }, { 0.45, 0.8, "wing1" } } do
				local z = spec[1] * body.length
				local cf = CFrame.new(sx * (body.width / 2 + 0.06), bodyY + 0.1 * i, z) * CFrame.Angles(math.rad(-20), math.pi, 0)
				wedge("FlankFlame", Vector3.new(0.12, spec[2], spec[2] * 1.4), cf, spec[3])
			end
		end
	end

	-- Púas sobre el lomo (la cara alta hacia la cabeza, la pendiente hacia la cola).
	for i = 1, P.spikes or 0 do
		local z = -halfL + 0.6 + (i - 1) * (body.length - 0.6) / math.max(1, P.spikes - 1)
		wedge("BackSpike", Vector3.new(0.3, 0.8, 0.9), CFrame.new(0, top + 0.75, z) * CFrame.Angles(0, math.pi, 0), "horn")
	end

	-- Patas ----------------------------------------------------------------------------------
	local legs = P.legs
	local function leg(x: number, z: number, isBack: boolean)
		local thick = legs.thick * (if isBack then 1.15 else 1)
		local hipY = body.lift + body.height * 0.35
		local sx = if x > 0 then 1 else -1
		local haunch = thick * (if isBack then 2 else 1.6)
		smooth("Haunch", Vector3.new(0.5, haunch, haunch), CFrame.new(x + sx * 0.3, hipY, z), "dark", CYLINDER)
		brick("Leg", Vector3.new(thick, hipY - 0.4, thick), CFrame.new(x, (hipY + 0.4) / 2, z), "body")
		brick("Foot", Vector3.new(thick * 1.15, 0.5, thick * 1.5), CFrame.new(x, 0.25, z - thick * 0.25), "body")
		for k = -1, 1 do
			wedge("Claw", Vector3.new(0.3, 0.4, 0.6), CFrame.new(x + k * thick * 0.36, 0.2, z - thick * 1.0 - 0.3), "claw")
		end
	end
	for _, sx in { -1, 1 } do
		local x = sx * (body.width / 2 - legs.thick / 2 + 0.15)
		leg(x, -halfL + legs.thick * 0.5, false)
		leg(x, halfL - legs.thick * 0.5, true)
	end

	-- Cuello ---------------------------------------------------------------------------------
	local H = P.head
	local neckBase = Vector3.new(0, top - 0.4, -halfL + 0.3)
	local headPos
	if P.neck then
		local n = P.neck
		local tip = neckBase + Vector3.new(0, n.rise, -n.forward)
		local bend = neckBase + Vector3.new(0, n.rise * 0.55, n.forward * 0.15)
		local prev = neckBase
		for i = 1, n.segments do
			local t = i / n.segments
			local point = bezier(neckBase, bend, tip, t)
			local thick = n.thick * (1 - 0.25 * t)
			beam("Neck", prev, point, thick, thick * 1.1, "body", Vector3.new(0, 0, -1))
			ball("NeckJoint", point, thick * 1.08, "body")
			local throat = Vector3.new(0, 0, -thick * 0.4)
			beam("Throat", prev + throat, point + throat, thick * 0.7, thick * 0.5, "belly", Vector3.new(0, 0, -1))
			if (P.spikes or 0) > 0 then
				wedge("NeckSpike", Vector3.new(0.25, 0.6, 0.7), CFrame.new(point + Vector3.new(0, 0, thick * 0.55)) * CFrame.Angles(math.rad(60), math.pi, 0), "horn")
			end
			prev = point
		end
		headPos = tip + Vector3.new(0, H.height * 0.25, -H.length * 0.2)
	else
		headPos = Vector3.new(0, top + H.raise, -halfL - H.forward)
	end

	-- Cabeza ---------------------------------------------------------------------------------
	local head = CFrame.new(headPos) * CFrame.Angles(math.rad(H.pitch or 0), 0, 0)
	brick("Skull", Vector3.new(H.width, H.height, H.length), head, "body")
	local snout = head * CFrame.new(0, -H.height * 0.18, -H.length / 2 - H.snout / 2 + 0.2)
	brick("Snout", Vector3.new(H.width * 0.72, H.height * 0.55, H.snout), snout, "body")
	brick("Jaw", Vector3.new(H.width * 0.66, H.height * 0.22, H.snout + H.length * 0.45), head * CFrame.new(0, -H.height * 0.44, -H.length * 0.18 - H.snout * 0.4), H.jaw or "dark")
	for _, sx in { -1, 1 } do
		smooth("Nostril", Vector3.new(0.25, 0.18, 0.12), snout * CFrame.new(sx * H.width * 0.18, H.height * 0.18, -H.snout / 2 - 0.02), "nostril")
		smooth("Tooth", Vector3.new(0.22, H.tooth or 0.4, 0.22), snout * CFrame.new(sx * H.width * 0.24, -H.height * 0.3, -H.snout / 2 + 0.25), "tooth")
	end

	-- Ojos: grandes y redondos (bebé) o chiquitos y amarillos con ceja (joven y adulto).
	for _, sx in { -1, 1 } do
		if H.cartoon then
			local d = H.height * 0.52
			local eye = head * CFrame.new(sx * (H.width / 2 + 0.05), H.height * 0.12, -H.length * 0.12)
			smooth("EyeWhite", Vector3.new(0.2, d, d), eye, "eyeWhite", CYLINDER)
			smooth("Iris", Vector3.new(0.22, d * 0.66, d * 0.66), eye * CFrame.new(sx * 0.04, 0, -d * 0.08), "iris", CYLINDER)
			smooth("Pupil", Vector3.new(0.24, d * 0.38, d * 0.38), eye * CFrame.new(sx * 0.07, 0, -d * 0.1), "pupil", CYLINDER)
			smooth("Shine", Vector3.new(0.26, d * 0.16, d * 0.16), eye * CFrame.new(sx * 0.09, d * 0.14, -d * 0.2), "eyeWhite", CYLINDER)
		else
			local eye = head * CFrame.new(sx * (H.width / 2 + 0.02), H.height * 0.15, -H.length * 0.2)
			smooth("Eye", Vector3.new(0.12, 0.42, 0.62), eye, "eye")
			smooth("Pupil", Vector3.new(0.14, 0.4, 0.14), eye * CFrame.new(sx * 0.02, 0, 0), "pupil")
			wedge("Brow", Vector3.new(0.3, 0.35, 0.9), eye * CFrame.new(-sx * 0.05, 0.35, 0.05) * CFrame.Angles(0, math.pi, 0), "dark")
		end
	end

	-- Cuernos que salen para atrás.
	if P.horns then
		local horns = P.horns
		for _, sx in { -1, 1 } do
			local base = (head * CFrame.new(sx * H.width * 0.32, H.height / 2, H.length * 0.15)).Position
			local mid = base + Vector3.new(sx * 0.2, horns.length * 0.55, horns.length * 0.35)
			local tip = mid + Vector3.new(sx * 0.1, horns.length * 0.3, horns.length * 0.6)
			rod("Horn", base, mid, horns.thick, "horn")
			ball("HornJoint", mid, horns.thick, "horn")
			rod("HornTip", mid, tip, horns.thick * 0.55, "horn")
		end
	end

	-- Cresta: bloques apilados (bebé) o un abanico de púas (joven y adulto).
	local crest = P.crest
	if crest and crest.kind == "blocks" then
		local crown = head * CFrame.new(0, H.height / 2, H.length * 0.1)
		brick("Crest", Vector3.new(H.width * 0.75, 0.6, H.length * 0.55), crown * CFrame.new(0, 0.3, 0), "crest")
		brick("Crest", Vector3.new(H.width * 0.5, 0.6, H.length * 0.4), crown * CFrame.new(-H.width * 0.12, 0.85, 0.1), "crest")
		brick("Crest", Vector3.new(H.width * 0.3, 0.5, H.length * 0.3), crown * CFrame.new(H.width * 0.2, 0.85, -0.2), "crestDark")
	elseif crest and crest.kind == "spikes" then
		local root = (head * CFrame.new(0, H.height * 0.35, H.length * 0.4)).Position
		for i = 1, crest.count do
			local t = (i - 1) / math.max(1, crest.count - 1)
			local angle = math.rad(15 + t * 70) -- desde casi vertical hasta casi para atrás
			local length = crest.length * (1 - math.abs(t - 0.35) * 0.6)
			local x = (if i % 2 == 0 then 1 else -1) * 0.25
			local tipPoint = root + Vector3.new(x, math.cos(angle) * length, math.sin(angle) * length)
			beam("CrestSpike", root + Vector3.new(x, 0, 0), tipPoint, 0.3, 0.45, "crest")
		end
	end

	-- Alas -----------------------------------------------------------------------------------
	local W = P.wings
	if W then
		local fingers = if W.fingers == 3
			then { { 0.55, 0.9 }, { 0.85, 0.5 }, { 0.75, 0.05 } }
			else { { 0.45, 1.0 }, { 0.8, 0.78 }, { 1.0, 0.42 }, { 0.85, 0.05 } }
		for _, sx in { -1, 1 } do
			local shoulder = Vector3.new(sx * body.width * 0.35, top + 0.1, -halfL + body.length * 0.3)
			local tilt = math.rad(W.tilt or 25)
			local upward = Vector3.new(sx * math.sin(tilt), math.cos(tilt), 0)
			local function at(back: number, up: number): Vector3
				return shoulder + Vector3.zAxis * (back * W.span) + upward * (up * W.span)
			end
			local elbow, wrist = at(0.05, 0.5), at(-0.12, 0.88)
			local tips = {}
			for i, spec in fingers do
				tips[i] = at(spec[1], spec[2])
			end
			-- Membrana: de afuera (amarillo) hacia adentro (rojo).
			local colors = W.colors
			for i = 1, #tips - 1 do
				triangle(wrist, tips[i], tips[i + 1], colors[math.min(i, #colors)], 0.15)
			end
			triangle(wrist, tips[#tips], elbow, colors[#colors], 0.15)
			triangle(elbow, tips[#tips], shoulder, colors[#colors], 0.15)
			-- Huesos.
			rod("WingArm", shoulder, elbow, W.bone, "bone")
			ball("WingJoint", elbow, W.bone * 1.1, "bone")
			rod("WingArm", elbow, wrist, W.bone * 0.9, "bone")
			ball("WingJoint", wrist, W.bone * 1.1, "bone")
			for _, tip in tips do
				rod("WingFinger", wrist, tip, W.bone * 0.55, "bone")
			end
			wedge("WingClaw", Vector3.new(0.25, 0.5, 0.5), CFrame.new(wrist + Vector3.new(0, W.bone * 0.6, 0)) * CFrame.Angles(0, math.pi, 0), "horn")
		end
	end

	-- Cola con la llama en la punta -------------------------------------------------------
	local T = P.tail
	local start = Vector3.new(0, bodyY, halfL)
	local prev = start
	for i = 1, T.segments do
		local t = i / T.segments
		local point = start + Vector3.new(math.sin(t * math.pi) * (T.sway or 0), -math.sin(t * math.pi) * T.drop + t ^ 3 * T.rise, t * T.length)
		local d = T.thick * (1 - t * 0.7)
		rod("Tail", prev, point, d, "body")
		ball("TailJoint", point, d, "body")
		if (P.spikes or 0) > 0 and i % 2 == 0 and i < T.segments - 1 then
			local dir = (point - prev).Unit
			wedge("TailSpike", Vector3.new(0.22, 0.5, 0.6), CFrame.lookAt(point, point - dir) * CFrame.new(0, d / 2 + 0.15, 0), "horn")
		end
		prev = point
	end
	local flame = T.flame or 1.5
	for _, spec in { { 0, 1.7, "flame" }, { -28, 1.2, "flame" }, { 28, 1.3, "flame" }, { 0, 1, "flameCore" } } do
		local cf = CFrame.new(prev) * CFrame.Angles(0, math.rad(-35), math.rad(spec[1])) * CFrame.new(0, spec[2] * flame / 2, 0)
		wedge("Flame", Vector3.new(0.2, spec[2] * flame, 0.7 * flame), cf, spec[3])
	end
	local tipAttachment = Instance.new("Attachment")
	tipAttachment.Name = "FlameTip"
	local flamePart = smooth("FlameBase", Vector3.one * 0.3, CFrame.new(prev), "flameCore", BALL)
	flamePart.Transparency = 1
	tipAttachment.Parent = flamePart
	Particles.fire(tipAttachment, { Rate = 14, Size = NumberSequence.new(0.9 * flame, 0.1), Speed = NumberRange.new(1, 2) })
	Particles.light(flamePart, palette.flame.color, 8, 1)

	model.WorldPivot = CFrame.new()
	if cframe then
		model:PivotTo(cframe)
	end
	model.Parent = parent
	return model
end

return DragonBuilder
