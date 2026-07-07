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

ESP.Array = {}
ESP.Array.__index = ESP.Array

function ESP.Array.Build(self)
	local esp = self.esp
	local sgui = esp._sgui
	local cfg = esp._config
	local render = self.rendered

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

	render.healthback = Instance.new("Frame")
	render.healthback.BackgroundColor3 = c3(0, 1, 0)
	render.healthback.BorderSizePixel = 0
	render.healthback.Parent = sgui

	render.health = Instance.new("Frame")
	render.health.BackgroundColor3 = c3(0, 0, 0)
	render.health.BorderSizePixel = 0
	render.health.Parent = render.healthback

	render.healthgrad = Instance.new("UIGradient")
	render.healthgrad.Rotation = 90
	render.healthgrad.Parent = render.healthback

	render.name = Instance.new("TextLabel")
	render.name.BackgroundTransparency = 1
	render.name.TextStrokeTransparency = 0
	render.name.FontFace = esp.font
	render.name.TextSize = cfg.text.name_size or 12
	render.name.TextColor3 = c3(1, 1, 1)
	render.name.Parent = sgui

	render.weapon = Instance.new("TextLabel")
	render.weapon.BackgroundTransparency = 1
	render.weapon.TextStrokeTransparency = 0
	render.weapon.FontFace = esp.font
	render.weapon.TextSize = cfg.text.weapon_size or 9
	render.weapon.TextColor3 = c3(1, 1, 1)
	render.weapon.Parent = sgui

	render.flag_cont = Instance.new("Frame")
	render.flag_cont.BackgroundTransparency = 1
	render.flag_cont.BorderSizePixel = 0
	render.flag_cont.Parent = sgui

	render.flag_list = Instance.new("UIListLayout")
	render.flag_list.Parent = render.flag_cont

	local flags = self.flags

	local function _make_flag(name, default_text)
		local lbl = Instance.new("TextLabel")
		lbl.Text = default_text or name
		lbl.FontFace = esp.flag_font
		lbl.TextSize = cfg.text.flag_size or 9
		lbl.BackgroundTransparency = 1
		lbl.TextStrokeTransparency = 0
		lbl.TextColor3 = c3(1, 1, 1)
		lbl.TextXAlignment = "Left"
		lbl.Size = ud2(0, 0, 0, 10)
		lbl.Parent = render.flag_cont
		lbl.Visible = false
		return lbl
	end

	flags.distance = _make_flag("distance", "0m")
	flags.team = _make_flag("team", "")
	flags.weapon_flag = _make_flag("weapon_flag", "")
end

function ESP.Array.Remove(self)
	for _, v in pairs(self.rendered) do
		pcall(function() v:Destroy() end)
	end
	for _, v in pairs(self.flags) do
		pcall(function() v:Destroy() end)
	end
end

function ESP.Array.Hide(self)
	for _, v in pairs(self.rendered) do
		if v:IsA("Frame") or v:IsA("TextLabel") then
			v.Visible = false
		end
	end
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

	local pos, size, vis = esp:_box_math(plr.Character.HumanoidRootPart)

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

	do
		self.rendered.box.Position = ud2(0, pos.X, 0, pos.Y)
		self.rendered.box.Size = ud2(0, size.X, 0, size.Y)
		self.rendered.box.Visible = vis and cfg.box.enabled

		self.rendered.outline.Position = ud2(0, 1, 0, 1)
		self.rendered.outline.Size = ud2(1, -2, 1, -2)
		self.rendered.outline.Visible = vis and cfg.box.enabled
		self.rendered.outline.ZIndex = -2

		self.rendered.box_stroke.Color = cfg.box.color
	end

	do
		local lbl = self.rendered.name
		lbl.Position = ud2(0, size.X / 2 + pos.X, 0, pos.Y + cfg.offsets.name_y)
		lbl.Text = plr.Name
		lbl.Visible = vis and cfg.name.enabled

		if cfg.name.color_by_team then
			lbl.TextColor3 = esp:_get_team_color(plr)
		else
			lbl.TextColor3 = cfg.name.color
		end
	end

	do
		if alive and plr.Character and plr.Character:FindFirstChild("Humanoid") then
			local hum = plr.Character.Humanoid
			local back = self.rendered.healthback
			local fill = self.rendered.health
			local grad = self.rendered.healthgrad

			back.Position = ud2(0, pos.X + cfg.offsets.health_x, 0, pos.Y - 1)
			back.Size = ud2(0, 1, 0, size.Y + 2)

			if cfg.health.gradient then
				back.BackgroundColor3 = c3(1, 1, 1)
				grad.Enabled = true
				grad.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, cfg.health.color),
					ColorSequenceKeypoint.new(1, cfg.health.gradient_color),
				}
			else
				back.BackgroundColor3 = cfg.health.color
				grad.Enabled = false
			end

			back.Visible = vis and cfg.health.enabled

			local health_fraction = hum.Health / hum.MaxHealth
			fill.Position = ud2(0, 0, 0, 0)
			fill.Size = ud2(0, 1, 0, size.Y - (health_fraction * size.Y))
			fill.Visible = vis and cfg.health.enabled
		else
			self.rendered.health.Visible = false
			self.rendered.healthback.Visible = false
		end
	end

	do
		local lbl = self.rendered.weapon
		lbl.Position = ud2(0, size.X / 2 + pos.X, 0, pos.Y + size.Y + cfg.offsets.weapon_y)
		lbl.Text = esp:_get_weapon_name(plr)
		lbl.Visible = vis and cfg.weapon.enabled
		lbl.TextColor3 = cfg.weapon.color
	end

	do
		local cont = self.rendered.flag_cont
		cont.Position = ud2(0, pos.X + size.X + cfg.offsets.flags_x, 0, pos.Y + cfg.offsets.flags_y)
		cont.Size = ud2(0, 20, 0, 1000)
		cont.Visible = vis and cfg.flags.enabled

		local dist = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			and math.floor((plr.Character.HumanoidRootPart.Position - cam.CFrame.Position).Magnitude * 0.28)
			or 0

		self.flags.distance.Text = dist .. "m"
		self.flags.distance.Visible = cfg.flags.enabled and table.find(cfg.flags.list, "distance") ~= nil

		self.flags.team.Text = plr.Team and plr.Team.Name or ""
		self.flags.team.TextColor3 = esp:_get_team_color(plr)
		self.flags.team.Visible = cfg.flags.enabled and table.find(cfg.flags.list, "team") ~= nil
	end

	return true
end

function ESP.Create_Array(esp, player)
	local arr = setmetatable({
		player = player,
		character = player and player.Character,
		rendered = {},
		flags = {},
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
		},
		weapon = {
			enabled = true,
			color = c3(1, 1, 1),
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

function ESP:_box_math(torso)
	local cam = self._camera
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

task.wait(10)
esp:Destroy()
