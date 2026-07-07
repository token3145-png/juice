local v2 = Vector2.new
local v3 = Vector3.new
local cf = CFrame.new
local c3 = Color3.new
local ud2 = UDim2.new
local HttpService = game:GetService("HttpService")


local CustomFont = {} do
	function CustomFont:New(Name, Weight, Style, FontData)
		if not isfile(FontData.Id) then
			writefile(FontData.Id, game:HttpGet(FontData.Url))
		end
		local fontConfig = {
			name = Name,
			faces = {{
				name = Name,
				weight = Weight,
				style = Style,
				assetId = getcustomasset(FontData.Id)
			}}
		}
		writefile(`{Name}.font`, HttpService:JSONEncode(fontConfig))
		return Font.new(getcustomasset(`{Name}.font`))
	end
end

local ESP = {
    font = CustomFont:New("ProggyClean", 400, "Regular", {
        Id = "ProggyClean",
        Url = "https://github.com/chrissimpkins/codeface/raw/refs/heads/master/fonts/proggy-clean/ProggyClean.ttf"
    }),
    flag_font = CustomFont:New("SmallestPixel1", 400, "Regular", {
        Id = "SmallestPixel1",
        Url = "https://github.com/token3145-png/juice/raw/refs/heads/main/smallest_pixel-7.ttf"
    })
}
ESP.__index = ESP

local R6_BONES = {
	{"Head", "Torso"},
	{"Torso", "Left Arm"},
	{"Torso", "Right Arm"},
	{"Torso", "Left Leg"},
	{"Torso", "Right Leg"},
}

local R15_BONES = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"},
	{"LeftUpperArm", "LeftLowerArm"},
	{"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"},
	{"RightUpperArm", "RightLowerArm"},
	{"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"},
	{"LeftUpperLeg", "LeftLowerLeg"},
	{"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"},
	{"RightUpperLeg", "RightLowerLeg"},
	{"RightLowerLeg", "RightFoot"},
}

ESP.Array = {}
ESP.Array.__index = ESP.Array

function ESP.Array.Build(self)
	local esp = self.esp
	local sgui = esp._sgui
	local cfg = esp._config
	local render = self.rendered

	self._elements = {}

	render.box = Instance.new("Frame")
	render.box.BackgroundTransparency = 1
	render.box.Parent = sgui

	render.box_stroke = Instance.new("UIStroke")
	render.box_stroke.LineJoinMode = "Miter"
	render.box_stroke.Thickness = 1
	render.box_stroke.Parent = render.box

	render.outline = Instance.new("Frame")
	render.outline.BackgroundTransparency = 1
	render.outline.Parent = render.box

	render.out_stroke = Instance.new("UIStroke")
	render.out_stroke.LineJoinMode = "Miter"
	render.out_stroke.Thickness = 3
	render.out_stroke.Color = c3(0, 0, 0)
	render.out_stroke.Parent = render.outline

	self:Add_Bar("health", "right")

	self:Add_Text("name", "right")
	self:Add_Text("weapon", "bottom")
	self:Add_Text("distance", "right")
	self:Add_Text("team", "right")

	render.skeleton = {}
	for i = 1, 14 do
		local line = Instance.new("Frame")
		line.BackgroundColor3 = c3(1, 1, 1)
		line.BorderSizePixel = 0
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Visible = false
		line.ZIndex = -1
		line.Parent = sgui
		render.skeleton[i] = line
	end
end

function ESP.Array.Add_Bar(self, id, side)
	local sgui = self.esp._sgui
	local bg = Instance.new("Frame")
	bg.BackgroundColor3 = c3(0, 1, 0)
	bg.BorderSizePixel = 0
	bg.Visible = false
	bg.Parent = sgui

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = c3(0, 0, 0)
	fill.BorderSizePixel = 0
	fill.Visible = false
	fill.Parent = bg

	local outline = Instance.new("UIStroke")
	outline.LineJoinMode = "Miter"
	outline.Thickness = 1
	outline.Color = c3(0, 0, 0)
	outline.Parent = bg

	local el = {
		id = id,
		type = "bar",
		side = side,
		rendered = { bg = bg, fill = fill, outline = outline },
		_frac = 1,
		_color = c3(0, 1, 0),
		_bg = c3(0, 0, 0),
	}

	table.insert(self._elements, el)
	return el
end

function ESP.Array.Add_Text(self, id, side)
	local sgui = self.esp._sgui
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.TextStrokeTransparency = 0
	lbl.FontFace = self.esp.font
	lbl.TextSize = 12
	lbl.TextColor3 = c3(1, 1, 1)
	lbl.TextXAlignment = "Center"
	lbl.Visible = false
	lbl.Parent = sgui

    local outline = Instance.new("UIStroke")
	outline.LineJoinMode = "Miter"
	outline.Thickness = 1
	outline.Color = c3(0, 0, 0)
	outline.Parent = lbl

	local el = {
		id = id,
		type = "text",
		side = side,
		rendered = { lbl = lbl, outline = outline },
		_text = "",
		_color = c3(1, 1, 1),
	}

	table.insert(self._elements, el)
	return el
end

function ESP.Array.Update_Bar(self, id, fraction, color, bg_color)
	local el = self:_find_element(id)
	if not el then return end
	el._frac = fraction
	if color then el._color = color end
	if bg_color then el._bg = bg_color end
    if outline ~= nil then 
        el.rendered.outline.Transparency = outline and 0 or not outline and 1
    end
end

function ESP.Array.Update_Text(self, id, text, color, outline)
	local el = self:_find_element(id)
	if not el then return end
	el._text = text or ""
	if color then el._color = color end
    if outline ~= nil then 
        el.rendered.outline.Transparency = outline and 0 or not outline and 1
    end
end

function ESP.Array.Set_Side(self, id, side)
	local el = self:_find_element(id)
	if el then el.side = side end
end

function ESP.Array.Remove_Element(self, id)
	for i, el in ipairs(self._elements) do
		if el.id == id then
			for _, v in pairs(el.rendered) do
				pcall(function() v:Destroy() end)
			end
			table.remove(self._elements, i)
			return
		end
	end
end

function ESP.Array._find_element(self, id)
	for _, el in ipairs(self._elements) do
		if el.id == id then return el end
	end
	return nil
end

function ESP.Array.Layout(self, bx, by, bw, bh, vis)
	local cfg = self.esp._config
	local gap = 2
	local bar_w = 2

	local sides = { left = {}, right = {}, top = {}, bottom = {} }
	for _, el in ipairs(self._elements) do
		local bucket = sides[el.side]
		if bucket then
			if el.type == "bar" then
				table.insert(bucket, el)
			end
		end
	end
	for _, el in ipairs(self._elements) do
		local bucket = sides[el.side]
		if bucket then
			if el.type == "text" then
				table.insert(bucket, el)
			end
		end
	end

	local lx = bx
	local ly = by
	for _, el in ipairs(sides.left) do
		if el.type == "bar" then
			lx = lx - bar_w - gap
			el.rendered.bg.Position = ud2(0, lx, 0, by - 1)
			el.rendered.bg.Size = ud2(0, bar_w, 0, bh + 2)
			el.rendered.bg.BackgroundColor3 = el._bg
			el.rendered.bg.Visible = vis
			el.rendered.fill.Position = ud2(0, 0, 0, 0)
			el.rendered.fill.Size = ud2(0, bar_w, 0, bh + 2 - (el._frac * (bh + 2)))
			el.rendered.fill.BackgroundColor3 = el._color
			el.rendered.fill.Visible = vis
		else
			el.rendered.lbl.Position = ud2(0, lx, 0, ly)
			el.rendered.lbl.Size = ud2(0, 0, 0, 0)
			el.rendered.lbl.Text = el._text
			el.rendered.lbl.TextColor3 = el._color
			el.rendered.lbl.TextXAlignment = "Right"
			el.rendered.lbl.TextYAlignment = "Top"
			el.rendered.lbl.Visible = vis and el._text ~= ""
			el.rendered.lbl.Rotation = -90
			ly = ly + 10
		end
	end

	local rx = bx + bw
	local ry = by
	for _, el in ipairs(sides.right) do
		if el.type == "bar" then
			rx = rx + gap
			el.rendered.bg.Position = ud2(0, rx, 0, by - 1)
			el.rendered.bg.Size = ud2(0, bar_w, 0, bh + 2)
			el.rendered.bg.BackgroundColor3 = el._bg
			el.rendered.bg.Visible = vis
			el.rendered.fill.Position = ud2(0, 0, 0, 0)
			el.rendered.fill.Size = ud2(0, bar_w, 0, bh + 2 - (el._frac * (bh + 2)))
			el.rendered.fill.BackgroundColor3 = el._color
			el.rendered.fill.Visible = vis
			rx = rx + bar_w
		else
			el.rendered.lbl.Position = ud2(0, rx + gap, 0, ry)
			el.rendered.lbl.Size = ud2(0, 0, 0, 10)
			el.rendered.lbl.Text = el._text
			el.rendered.lbl.TextColor3 = el._color
			el.rendered.lbl.TextXAlignment = "Left"
			el.rendered.lbl.TextYAlignment = "Top"
			el.rendered.lbl.Visible = vis and el._text ~= ""
			el.rendered.lbl.Rotation = 0
			ry = ry + 10
		end
	end

	local ty = by
	for i = #sides.top, 1, -1 do
		local el = sides.top[i]
		if el.type == "bar" then
			ty = ty - bar_w - gap
			el.rendered.bg.Position = ud2(0, bx - 1, 0, ty)
			el.rendered.bg.Size = ud2(0, bw + 2, 0, bar_w)
			el.rendered.bg.BackgroundColor3 = el._bg
			el.rendered.bg.Visible = vis
			el.rendered.fill.Position = ud2(0, 0, 0, 0)
			el.rendered.fill.Size = ud2(0, bw + 2 - (el._frac * (bw + 2)), 0, bar_w)
			el.rendered.fill.BackgroundColor3 = el._color
			el.rendered.fill.Visible = vis
		else
			ty = ty - 10 - gap
			el.rendered.lbl.Position = ud2(0, bx, 0, ty)
			el.rendered.lbl.Size = ud2(0, bw, 0, 10)
			el.rendered.lbl.Text = el._text
			el.rendered.lbl.TextColor3 = el._color
			el.rendered.lbl.TextXAlignment = "Center"
			el.rendered.lbl.TextYAlignment = "Top"
			el.rendered.lbl.Visible = vis and el._text ~= ""
			el.rendered.lbl.Rotation = 0
		end
	end

	local by2 = by + bh + gap
	for _, el in ipairs(sides.bottom) do
		if el.type == "bar" then
			el.rendered.bg.Position = ud2(0, bx - 1, 0, by2)
			el.rendered.bg.Size = ud2(0, bw + 2, 0, bar_w)
			el.rendered.bg.BackgroundColor3 = el._bg
			el.rendered.bg.Visible = vis
			el.rendered.fill.Position = ud2(0, 0, 0, 0)
			el.rendered.fill.Size = ud2(0, bw + 2 - (el._frac * (bw + 2)), 0, bar_w)
			el.rendered.fill.BackgroundColor3 = el._color
			el.rendered.fill.Visible = vis
			by2 = by2 + bar_w + gap
		else
			el.rendered.lbl.Position = ud2(0, bx, 0, by2)
			el.rendered.lbl.Size = ud2(0, bw, 0, 10)
			el.rendered.lbl.Text = el._text
			el.rendered.lbl.TextColor3 = el._color
			el.rendered.lbl.TextXAlignment = "Center"
			el.rendered.lbl.TextYAlignment = "Top"
			el.rendered.lbl.Visible = vis and el._text ~= ""
			el.rendered.lbl.Rotation = 0
			by2 = by2 + 10 + gap
		end
	end
end

function ESP.Array.Remove(self)
	for _, el in ipairs(self._elements) do
		for _, v in pairs(el.rendered) do
			pcall(function() v:Destroy() end)
		end
	end
	self._elements = {}
	if self.rendered.box then
		pcall(function() self.rendered.box:Destroy() end)
	end
	if self.rendered.skeleton then
		for _, sv in ipairs(self.rendered.skeleton) do
			pcall(function() sv:Destroy() end)
		end
	end
end

function ESP.Array.Hide(self)
	for _, el in ipairs(self._elements) do
		for _, v in pairs(el.rendered) do
			pcall(function() v.Visible = false end)
		end
	end
	if self.rendered.box then
		pcall(function() self.rendered.box.Visible = false end)
	end
	if self.rendered.skeleton then
		for _, sv in ipairs(self.rendered.skeleton) do
			pcall(function() sv.Visible = false end)
		end
	end
end

local function find_bone(char, name)
	local part = char:FindFirstChild(name)
	if part then return part end
	local nospace = name:gsub(" ", "")
	part = char:FindFirstChild(nospace)
	return part
end

function ESP.Array.Update(self)
	local esp = self.esp
	local cfg = esp._config
	local cam = esp._camera
	local client = esp._client
	local plr = self.player

	if not plr or not plr.Parent then
		return false
	end

	self.character = plr.Character

	local alive = esp:_is_alive(plr)
	local client_alive = esp:_is_alive(client)

	if not client_alive or not alive or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
		self:Hide()
		return true
	end

	local pos, size, vis = esp:_box_math(plr.Character.HumanoidRootPart, plr.Character, cfg.box.tight)

	if cfg.distance.enabled and cfg.distance.max > 0 then
		local dist = math.floor((cam.CFrame.Position - plr.Character.HumanoidRootPart.Position).Magnitude * 0.28)
		if dist > cfg.distance.max then
			self:Hide()
			return true
		end
	end

	if cfg.team_check and client_alive and plr.Team == client.Team then
		self:Hide()
		return true
	end

	self.rendered.box.Position = ud2(0, pos.X, 0, pos.Y)
	self.rendered.box.Size = ud2(0, size.X, 0, size.Y)
	self.rendered.box.Visible = vis and cfg.box.enabled

	self.rendered.outline.Position = ud2(0, 1, 0, 1)
	self.rendered.outline.Size = ud2(1, -2, 1, -2)
	self.rendered.outline.Visible = vis and cfg.box.enabled
	self.rendered.outline.ZIndex = -2

	self.rendered.box_stroke.Color = cfg.box.color

	if cfg.skeleton.enabled and plr.Character then
		local rigType = plr.Character:FindFirstChild("LowerTorso") and "R15" or "R6"
		local bones = rigType == "R15" and R15_BONES or R6_BONES
		local lines = self.rendered.skeleton

		for i, pair in ipairs(bones) do
			local a = find_bone(plr.Character, pair[1])
			local b = find_bone(plr.Character, pair[2])
			if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
				local sa, va = cam:WorldToViewportPoint(a.Position)
				local sb, vb = cam:WorldToViewportPoint(b.Position)
				local line = lines[i]
				if line and va and vb then
					local dx = sb.X - sa.X
					local dy = sb.Y - sa.Y
					local dist = math.sqrt(dx * dx + dy * dy)
					local angle = math.deg(math.atan2(dy, dx))
					local cx = (sa.X + sb.X) * 0.5
					local cy = (sa.Y + sb.Y) * 0.5
					line.Position = ud2(0, cx, 0, cy)
					line.Size = ud2(0, dist, 0, cfg.skeleton.thickness)
					line.Rotation = angle
					line.BackgroundColor3 = cfg.skeleton.color
					line.Visible = vis
				elseif line then
					line.Visible = false
				end
			elseif lines[i] then
				lines[i].Visible = false
			end
		end
	else
		for _, line in ipairs(self.rendered.skeleton) do
			line.Visible = false
		end
	end

	self:Update_Bar("health",
		plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health / plr.Character.Humanoid.MaxHealth or 1,
		cfg.health.color,
		cfg.health.gradient and c3(1, 1, 1) or cfg.health.color, 
        cfg.health.outline or false
	)
    
	self:Update_Text("name",
		cfg.name.enabled and plr.Name or "",
		cfg.name.color_by_team and esp:_get_team_color(plr) or cfg.name.color
	)

	self:Update_Text("weapon",
		cfg.weapon.enabled and esp:_get_weapon_name(plr) or "",
		cfg.weapon.color
	)

	local dist = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		and math.floor((plr.Character.HumanoidRootPart.Position - cam.CFrame.Position).Magnitude * 0.28)
		or 0

	self:Update_Text("distance",
		cfg.flags.enabled and cfg.distance.enabled and table.find(cfg.flags.list, "distance") and (dist .. "m") or "",
		cfg.distance.color
	)

	self:Update_Text("team",
		cfg.flags.enabled and table.find(cfg.flags.list, "team") and (plr.Team and plr.Team.Name or "") or "",
		esp:_get_team_color(plr)
	)

	self:Layout(pos.X, pos.Y, size.X, size.Y, vis)

	return true
end

function ESP.Create_Array(esp, player)
	local arr = setmetatable({
		player = player,
		character = player and player.Character,
		rendered = {},
		esp = esp,
	}, ESP.Array)

	arr:Build()
	return arr
end

function ESP.new(config)
	local self = setmetatable({
		arrays = {},
		_connections = {},
		_running = false,
		_config = {},
		_sgui = nil,
		_services = {},
	}, ESP)

	self:_bootstrap(config)
	return self
end

function ESP:_bootstrap(config)
	local svc = self._services
	svc.players = game:GetService("Players")
	svc.workspace = game:GetService("Workspace")
	svc.runservice = game:GetService("RunService")
	svc.uis = game:GetService("UserInputService")
	svc.coregui = game:GetService("CoreGui")

	self._camera = svc.workspace.CurrentCamera
	self._client = svc.players.LocalPlayer

	self._sgui = Instance.new("ScreenGui")
	self._sgui.Name = "esp_library"
	self._sgui.IgnoreGuiInset = true
	self._sgui.Parent = svc.coregui

	self.font = ESP.font
	self.flag_font = ESP.flag_font

	self:_apply_config(config or {})

	self:_connect_player_added()
	self:_setup_existing_players()

	self._connections.render = svc.runservice.RenderStepped:Connect(function()
		self:_update()
	end)
	self._running = true
end

function ESP:_default_config()
	return {
		box = {
			enabled = true,
			color = c3(1, 1, 1),
			tight = true,
		},
		name = {
			enabled = true,
			color = c3(1, 1, 1),
			color_by_team = false,
		},
		health = {
			enabled = true,
			color = c3(0, 1, 0),
			gradient = false,
			gradient_color = c3(1, 0, 0),
            outline = false
		},
		weapon = {
			enabled = true,
			color = c3(1, 1, 1),
		},
		skeleton = {
			enabled = true,
			color = c3(1, 1, 1),
			thickness = 1,
		},
		distance = {
			enabled = true,
			color = c3(1, 1, 1),
			max = 1000,
		},
		flags = {
			enabled = true,
			list = { "distance", "team" },
		},
		team_check = false,
		team_colors = {},
		text = {
			name_size = 12,
			flag_size = 9,
			weapon_size = 12,
		},
		offsets = {
			box_up = 1.8,
			box_down = 2.5,
			name_y = -9,
			weapon_y = 5,
			health_x = -5,
			flags_x = 3,
			flags_y = -3,
		},
	}
end

function ESP:_apply_config(config)
	local def = self:_default_config()
	for k, v in pairs(config) do
		if type(v) == "table" and type(def[k]) == "table" then
			for sk, sv in pairs(v) do
				def[k][sk] = sv
			end
		else
			def[k] = v
		end
	end
	self._config = def
end

function ESP:Configure(config)
	self:_apply_config(config)
end

function ESP:_box_math(torso, character, tight)
	local cam = self._camera

	if tight and character then
		local minX, minY, minZ = math.huge, math.huge, math.huge
		local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
		local any = false

		for _, part in ipairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				any = true
				local p = part.Position
				if p.X < minX then minX = p.X end
				if p.Y < minY then minY = p.Y end
				if p.Z < minZ then minZ = p.Z end
				if p.X > maxX then maxX = p.X end
				if p.Y > maxY then maxY = p.Y end
				if p.Z > maxZ then maxZ = p.Z end
			end
		end

		if not any then
			return v2(0, 0), v2(0, 0), false
		end

		local corners = {
			v3(minX, minY, minZ), v3(minX, minY, maxZ),
			v3(minX, maxY, minZ), v3(minX, maxY, maxZ),
			v3(maxX, minY, minZ), v3(maxX, minY, maxZ),
			v3(maxX, maxY, minZ), v3(maxX, maxY, maxZ),
		}

		local sminX, sminY = math.huge, math.huge
		local smaxX, smaxY = -math.huge, -math.huge

		for _, corner in ipairs(corners) do
			local sp, onScreen = cam:WorldToViewportPoint(corner)
			if onScreen then
				if sp.X < sminX then sminX = sp.X end
				if sp.Y < sminY then sminY = sp.Y end
				if sp.X > smaxX then smaxX = sp.X end
				if sp.Y > smaxY then smaxY = sp.Y end
			end
		end

		sminX = sminX - 1
		sminY = sminY - 1
		smaxX = smaxX + 1
		smaxY = smaxY + 1

		local w = math.max(math.floor(smaxX - sminX), 3)
		local h = math.max(math.floor(smaxY - sminY), 3)
		return v2(math.floor(sminX), math.floor(sminY)), v2(w, h), true
	end

	local vTop = torso.Position + (torso.CFrame.UpVector * self._config.offsets.box_up) + cam.CFrame.UpVector
	local vBottom = torso.Position - (torso.CFrame.UpVector * self._config.offsets.box_down) - cam.CFrame.UpVector

	local top, topRendered = cam:WorldToViewportPoint(vTop)
	local bottom, bottomRendered = cam:WorldToViewportPoint(vBottom)

	local w = math.max(math.floor(math.abs(top.X - bottom.X)), 3)
	local h = math.max(math.floor(math.max(math.abs(bottom.Y - top.Y), w / 2)), 3)
	local boxSize = v2(math.floor(math.max(h / 1.5, w)), h)
	local boxPos = v2(math.floor(top.X * 0.5 + bottom.X * 0.5 - boxSize.X * 0.5), math.floor(math.min(top.Y, bottom.Y)))

	return boxPos, boxSize, (topRendered or bottomRendered)
end

function ESP:_is_alive(player)
	local char = player and player.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not (hrp and hum) then return false end
	return hum.Health > 0
end

function ESP:_get_weapon_name(player)
	if not self:_is_alive(player) then return "" end
	local tool = player.Character:FindFirstChildWhichIsA("Tool")
	return tool and tool.Name or ""
end

function ESP:_get_team_color(player)
	local cfg = self._config

	if cfg.team_colors and player.Team and cfg.team_colors[player.Team.Name] then
		return cfg.team_colors[player.Team.Name]
	end
	return c3(1, 1, 1)
end

function ESP:Get_Array(player)
	return self.arrays[player]
end

function ESP:Get_Arrays()
	return self.arrays
end

function ESP:_connect_player_added()
	local conn = self._services.players.PlayerAdded:Connect(function(player)
		self:Add_Player(player)
	end)
	table.insert(self._connections, conn)
end

function ESP:_setup_existing_players()
	for _, player in ipairs(self._services.players:GetPlayers()) do
		if player ~= self._client then
			self:Add_Player(player)
		end
	end
end

function ESP:Add_Player(player)
	if not player or player == self._client then return end
	if self.arrays[player] then return end

	self.arrays[player] = ESP.Create_Array(self, player)
end

function ESP:AddPlayer(player)
	self:Add_Player(player)
end

function ESP:Remove_Player(player)
	local arr = self.arrays[player]
	if not arr then return end

	arr:Remove()
	self.arrays[player] = nil
end

function ESP:RemovePlayer(player)
	self:Remove_Player(player)
end

function ESP:_update()
	for player, arr in pairs(self.arrays) do
		if not arr:Update() then
			arr:Remove()
			self.arrays[player] = nil
		end
	end
end

function ESP:Start()
	if self._running then return end
	self._connections.render = self._services.runservice.RenderStepped:Connect(function()
		self:_update()
	end)
	self._running = true
end

function ESP:Stop()
	if self._connections.render then
		self._connections.render:Disconnect()
		self._connections.render = nil
	end
	self._running = false
	for _, arr in pairs(self.arrays) do
		arr:Hide()
	end
end

function ESP:Destroy()
	self:Stop()
	for _, conn in ipairs(self._connections) do
		pcall(function() conn:Disconnect() end)
	end
	self._connections = {}
	for player, _ in pairs(self.arrays) do
		self:Remove_Player(player)
	end
	if self._sgui then
		self._sgui:Destroy()
		self._sgui = nil
	end
end

function ESP:GetPlayers()
	local list = {}
	for player, _ in pairs(self.arrays) do
		table.insert(list, player)
	end
	return list
end

function ESP:IsRunning()
	return self._running
end

return ESP
