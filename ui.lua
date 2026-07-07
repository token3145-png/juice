--[[
	Juicebox UI Library

	local UI = Library.new("Window Title")

	UI:CreateWatermark(text)
	UI:SetWatermark(text)
	UI:SetMenuKeybind(key)
	UI:ShowKeybinds(bool)
	UI:GetState(flag)
	UI:Notify(text, isWarning)
	UI:Refresh()
	UI:Unload()
	UI:OnUnload(callback)

	--- Config ---
	UI:SaveConfig(name)
	UI:LoadConfig(name) -> bool
	UI:LoadLastConfig() -> bool
	UI:GetConfigs() -> {string}
	UI:DeleteConfig(name)

	--- Tabs & Sections ---
	local tab = UI:CreateTab(name)
	UI:SelectTab(tab)
	local sec = UI:CreateSection(tab, name, side)

	--- Elements ---
	local toggle = UI:CreateToggle(sec, { name, flag, default, callback })
	toggle:CreateColorPicker({ default, flag, callback })
	toggle:CreateKeybind({ default, mode, flag, callback })
	local ctx = toggle:AddContextMenu()

	UI:CreateButton(sec, { name, callback, confirm = bool })
	UI:CreateLabel(sec, "text") or UI:CreateLabel(sec, { name, color, keybind })
	UI:CreateSlider(sec, { name, flag, min, max, step, default, callback })
	UI:CreateRangeSlider(sec, { name, flag, min, max, step, defaultMin, defaultMax, callback })
	UI:CreateDropdown(sec, { name, flag, options, multi, default, callback })
	UI:CreateColorPicker(sec, { name, default, flag, callback })
	UI:RegisterKeybindLabel(flag, name)
	UI:CreateTextBox(sec, { name, default, placeholder, flag })

	--- Theme ---
	Accent = Color3
	BgDark = Color3
	BgMid = Color3
	BgLight = Color3
	StrokeColor = Color3
	TextBright = Color3
	TextDim = Color3
]]

local Accent = Color3.fromRGB(74, 199, 224)
local BgDark = Color3.fromRGB(14, 14, 14)
local BgMid = Color3.fromRGB(13, 13, 13)
local BgLight = Color3.fromRGB(21, 21, 21)
local StrokeColor = Color3.fromRGB(31, 31, 31)
local TextBright = Color3.fromRGB(255, 255, 255)
local TextDim = Color3.fromRGB(86, 86, 86)
local BgToggle = Color3.fromRGB(11, 11, 11)
local BgButton = Color3.fromRGB(23, 23, 23)
local ui_FontSize = 12
local ui_Font = nil
local HttpService = game:GetService("HttpService")

local KEY_SHORT = {
	MouseButton1 = "mb1", MouseButton2 = "mb2", MouseButton3 = "mb3",
	LeftControl = "lctrl", RightControl = "rctrl",
	LeftShift = "lshf", RightShift = "rshf",
	LeftAlt = "lalt", RightAlt = "ralt",
	Backspace = "bksp", Return = "enter", Space = "space",
	CapsLock = "caps", Tab = "tab",
	Insert = "ins", Delete = "del", Home = "home", EndKey = "end",
	PageUp = "pgup", PageDown = "pgdn",
	Escape = "esc", PrintScreen = "prtsc",
	ScrollLock = "scrlk", Pause = "pause", NumLock = "numlk",
	LeftSuper = "lwin", RightSuper = "rwin", Menu = "menu",
	Up = "up", Down = "down", Left = "left", Right = "right",
	KeypadZero = "kp0", KeypadOne = "kp1", KeypadTwo = "kp2", KeypadThree = "kp3", KeypadFour = "kp4",
	KeypadFive = "kp5", KeypadSix = "kp6", KeypadSeven = "kp7", KeypadEight = "kp8", KeypadNine = "kp9",
	KeypadMultiply = "kp*", KeypadPlus = "kp+", KeypadMinus = "kp-", KeypadPeriod = "kp.", KeypadDivide = "kp/",
	KeypadEnter = "kpe", KeypadEquals = "kp=",
	LeftBracket = "[", RightBracket = "]", Semicolon = ";", Quote = "'",
	Comma = ",", Period = ".", Slash = "/", Backslash = "\\", Minus = "-", Equals = "=",
	Backquote = "`",
	F1 = "f1", F2 = "f2", F3 = "f3", F4 = "f4", F5 = "f5", F6 = "f6",
	F7 = "f7", F8 = "f8", F9 = "f9", F10 = "f10", F11 = "f11", F12 = "f12",
}

local function shortKey(name)
	return KEY_SHORT[name] or name
end

local function get_input_name(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return shortKey(input.KeyCode.Name)
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.UserInputType == Enum.UserInputType.MouseButton3 then
		return shortKey(input.UserInputType.Name)
	end
end

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
    ui_Font = CustomFont:New("ProggyClean", 400, "Regular", {
        Id = "ProggyClean",
        Url = "https://github.com/chrissimpkins/codeface/raw/refs/heads/master/fonts/proggy-clean/ProggyClean.ttf"
    })
end

local Library = {
	menukey = Enum.KeyCode.RightShift,
	flags = {},
	theme = {
		accent = Accent,
		background = BgDark,
		inline = BgMid,
		defaults = {
			accent = Accent,
			background = BgDark,
			inline = BgMid,
		}
	},
	_themeObjects = {},
}

Library.__index = Library

local function theme_value(data)
	local key = data
	local shade = nil
	if type(data) == "table" then key = data[1]; shade = data[2] end
	local color = Library.theme[key]
	if not color then return nil end
	return shade and shade_color(color, shade) or color
end

function Library:_trackTheme(obj, prop, data)
	local color = theme_value(data)
	if not color then return obj end
	obj[prop] = color
	local objects = Library._themeObjects
	objects[#objects + 1] = {obj = obj, prop = prop, data = data, key = type(data) == "table" and data[1] or data}
	return obj
end

function Library:_applyThemeKey(key)
	local objects = Library._themeObjects
	for i = #objects, 1, -1 do
		local info = objects[i]
		local obj = info.obj
		if not obj or obj.Parent == nil then table.remove(objects, i)
		elseif info.key == key then
			local color = theme_value(info.data)
			if color then obj[info.prop] = color end
		end
	end
end

function Library:_refreshTabs()
	if not self.tabs then return end
	for i = 1, #self.tabs do
		local tab = self.tabs[i]
		if tab == self.current_tab then
			tab.page.Visible = true
			tab.button.TextColor3 = Accent
		else
			tab.page.Visible = false
			tab.button.TextColor3 = TextBright
		end
	end
end

function Library:_runThemeRefresh()
	if self._themeRefreshElements then
		for i = 1, #self._themeRefreshElements do self._themeRefreshElements[i]() end
	end
	self:_refreshTabs()
	if self._kbEntries then self:_rebuildKeybindList() end
end

function Library:SetThemeColor(key, color, force)
	if typeof(color) ~= "Color3" then return end
	if not force and Library.flags.theme_enabled == false then return end
	if key ~= "accent" and key ~= "background" and key ~= "inline" then return end
	Library.theme[key] = color
	if key == "accent" then Accent = color end
	self:_applyThemeKey(key)
	self:_runThemeRefresh()
end

function Library:SetThemeEnabled(enabled)
	Library.theme.enabled = enabled == true
	Library.flags.theme_enabled = Library.theme.enabled
	if not Library.theme.enabled then
		local defaults = Library.theme.defaults
		self:SetThemeColor("accent", defaults.accent, true)
		self:SetThemeColor("background", defaults.background, true)
		self:SetThemeColor("inline", defaults.inline, true)
		return
	end
	self:SetThemeColor("accent", Library.flags.theme_accent or Library.theme.accent, true)
	self:SetThemeColor("background", Library.flags.theme_background or Library.theme.background, true)
	self:SetThemeColor("inline", Library.flags.theme_inline or Library.theme.inline, true)
end

function Library:AddConnection(conn)
	if not self._connections then self._connections = {} end
	self._connections[#self._connections + 1] = conn
	return conn
end

function Library:RemoveConnection(conn)
	if not self._connections then return end
	for i = #self._connections, 1, -1 do
		if self._connections[i] == conn then
			conn:Disconnect()
			table.remove(self._connections, i)
			return
		end
	end
end

function Library:RemoveAllConnections()
	if not self._connections then return end
	for _, c in ipairs(self._connections) do c:Disconnect() end
	self._connections = {}
end

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local TI_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function tween(obj, props, info)
	local ti = info or TI_FAST
	local t = TweenService:Create(obj, ti, props)
	t:Play()
	return t
end

local function shade_color(color, amount)
	if amount > 0 then return color:Lerp(Color3.fromRGB(255, 255, 255), amount)
	elseif amount < 0 then return color:Lerp(Color3.fromRGB(0, 0, 0), -amount)
	else return color end
end

local function MakeDraggable(element, lockCheck)
	local dragStart, startPos, dragging
	element.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if lockCheck and lockCheck() then return end
			dragStart = input.Position
			startPos = element.Position
			dragging = true
		end
	end)
	element.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	return UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			element.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function Create(className, parent, name, props)
	local obj = Instance.new(className, parent)
	if name then obj.Name = name end
	if props then
		for k, v in pairs(props) do
			if k ~= "_theme" then obj[k] = v end
		end
		if props._theme then
			for prop, data in pairs(props._theme) do
				Library:_trackTheme(obj, prop, data)
			end
		end
	end
	if obj:IsA("TextButton") or obj:IsA("ImageButton") then obj.AutoButtonColor = false end
	return obj
end

local function AddStroke(obj, border)
	return Create("UIStroke", obj, nil, border and {
		Color = StrokeColor,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter,
	} or {
		Color = StrokeColor,
		LineJoinMode = Enum.LineJoinMode.Miter,
	})
end

local function closeIfNotOver(frames, closeCallback)
	local hovered = false
	for _, f in ipairs(frames) do
		f.MouseEnter:Connect(function() hovered = true end)
		f.MouseLeave:Connect(function() hovered = false end)
	end
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not hovered then conn:Disconnect(); closeCallback() end
		end
	end)
	return conn
end

local TI_PRESS = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_RELEASE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function _btnFlash(btn, origColor)
	local bc = origColor or btn.BackgroundColor3
	local lit = bc:Lerp(Color3.fromRGB(255, 255, 255), 0.15)
	btn.MouseButton1Down:Connect(function() tween(btn, {BackgroundColor3 = lit}, TI_PRESS) end)
	local function restore() tween(btn, {BackgroundColor3 = bc}, TI_RELEASE) end
	btn.MouseButton1Up:Connect(restore)
	btn.MouseLeave:Connect(restore)
end

function Library.new(title)
	local self = setmetatable({}, Library)
	self.tabs = {}
	self.current_tab = nil
	self._refreshElements = {}
	self._themeRefreshElements = {}
	self._connections = {}
	self._configFolder = "juicebox"
	self._onUnloadCallback = nil
	self._colorPickerActive = nil
	self._colorPickerCallback = nil
	self._colorPickerFlag = nil
	self._cpHovered = false

	self.gui = Create("ScreenGui", gethui(), "Juicebox", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	self.mainCanvas = Create("CanvasGroup", self.gui, "MainCanvas", {
		BorderSizePixel = 0,
		BackgroundColor3 = BgDark,
		Size = UDim2.new(0, 438, 0, 505),
		Position = UDim2.new(0.32463, 0, 0.1589, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		GroupTransparency = 0,
	})

	self.main = Create("Frame", self.mainCanvas, "Main", {
		BorderSizePixel = 0,
		BackgroundColor3 = BgDark,
		Size = UDim2.new(1, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", self.main, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", self.main, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })

	Create("UIPadding", self.main, nil, {
		PaddingRight = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 8),
	})

	self.titleLabel = Create("TextLabel", self.main, "Title", {
		BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), FontFace = ui_Font,
		TextColor3 = TextBright, BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 0, 24), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = title,
	})
	Create("UIStroke", self.titleLabel, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	self.tabbar = Create("Frame", self.main, "Tabbar", {
		BorderSizePixel = 0, BackgroundColor3 = BgMid,
		Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 25),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", self.tabbar, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", self.tabbar, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })

	Create("UIListLayout", self.tabbar, nil, {
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		VerticalFlex = Enum.UIFlexAlignment.Fill,
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
	})

	self.tabFolder = Create("Folder", self.main, "Tabs")

	self:AddConnection(MakeDraggable(self.mainCanvas, function() return self._vpDragging end))

	self._resizeBtn = Create("ImageButton", self.main, "Resize", {
		BorderSizePixel = 0, BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ImageColor3 = Color3.fromRGB(75, 75, 75), Image = "rbxassetid://18161819135",
		Size = UDim2.new(0, 25, 0, 25), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Rotation = -45, Position = UDim2.new(1,-5,1,-5),
	})
	self:_setupResize()

	self._cpHue, self._cpSat, self._cpVal, self._cpTrans = 0, 0, 1, 0
	self:_buildColorPicker()

	self._menuVisible = true

	self:AddConnection(UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Library.menukey then self:ToggleMenu() end
	end))

	return self
end

function Library:_setupResize()
	local dragStart, startSize, dragging
	self._resizeBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if self._vpDragging then return end
			dragStart = input.Position
			startSize = self.mainCanvas.AbsoluteSize
			dragging = true
		end
	end)
	self:AddConnection(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			self.mainCanvas.GroupTransparency = 0.001
			task.defer(function() self.mainCanvas.GroupTransparency = 0 end)
		end
	end))
	self:AddConnection(UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			local w = math.clamp(startSize.X + delta.X, 100, 800)
			local h = math.clamp(startSize.Y + delta.Y, 100, 800)
			self.mainCanvas.Size = UDim2.new(0, w, 0, h)
		end
	end))

	self._resizeBtn.MouseButton2Click:Connect(function()
		tween(self.mainCanvas, {Size = UDim2.new(0, 438, 0, 505)}, TI_BOUNCE)
	end)
end

function Library:SetMenuKeybind(key)
	if typeof(key) == "EnumItem" then Library.menukey = key
	else Library.menukey = Enum.KeyCode[key] or key end
end
Library.SetToggleBind = Library.SetMenuKeybind

function Library:_setMenuVisible(visible)
	if not self.mainCanvas then return end
	if self._menuVisible == visible then return end
	self._menuVisible = visible
	if self._menuFade then self._menuFade:Cancel(); self._menuFade = nil end
	if visible then
		self.mainCanvas.Visible = true
		self.mainCanvas.GroupTransparency = 1
		self._menuFade = tween(self.mainCanvas, {GroupTransparency = 0}, TI_FAST)
	else
		self._menuFade = tween(self.mainCanvas, {GroupTransparency = 1}, TI_FAST)
		task.delay(0.13, function()
			if self.mainCanvas and not self._menuVisible then self.mainCanvas.Visible = false end
		end)
	end
end

function Library:ToggleMenu()
	self:_setMenuVisible(not self._menuVisible)
end

function Library:Unload()
	if self._onUnloadCallback then
		local cb = self._onUnloadCallback; self._onUnloadCallback = nil; cb()
	end
	if self._menuFade then self._menuFade:Cancel(); self._menuFade = nil end
	self:RemoveAllConnections()
	if self.gui then self.gui:Destroy(); self.gui = nil end
end

function Library:OnUnload(callback)
	self._onUnloadCallback = callback
end

function Library:_buildColorPicker()
	local cp = Create("CanvasGroup", self.gui, "ColorMenu", {
		BorderSizePixel = 0, BackgroundColor3 = BgDark,
		Size = UDim2.new(0, 190, 0, 183), Position = UDim2.new(0.68026, 0, 0.1589, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Visible = false, GroupTransparency = 1,
	})
	self._cpPopup = cp
	cp.MouseEnter:Connect(function() self._cpHovered = true end)
	cp.MouseLeave:Connect(function() self._cpHovered = false end)

	Create("UIStroke", cp, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", cp, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIPadding", cp, nil, { PaddingRight = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8) })

	Create("TextLabel", cp, "title", {
		BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), FontFace = ui_Font,
		TextColor3 = TextBright, BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 0, 24), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "Color menu",
	})
	Create("UIStroke", cp.title, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local picker = Create("CanvasGroup", cp, "MainPicker", {
		BorderSizePixel = 0, BackgroundColor3 = BgMid,
		Size = UDim2.new(1, 0, 1, -21), Position = UDim2.new(0, 0, 0, 25),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", picker, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", picker, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })

	local sat = Create("Frame", picker, "Sat", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0, 124, 0, 118), Position = UDim2.new(0, 6, 0, 6),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", sat, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", sat, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })

	self._cpSatGrad = Create("UIGradient", sat, nil, { Rotation = 0 })
	local satOverlay = Create("Frame", sat, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 0,
	})
	self._cpSatOverlayGrad = Create("UIGradient", satOverlay, nil, {
		Rotation = 90,
		Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)},
	})

	local satBtn = Create("ImageButton", sat, nil, {
		AutoButtonColor = false, ImageTransparency = 1, BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 5,
	})

	self._cpSatCursor = Create("Frame", sat, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0, 6, 0, 6), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 6,
	})
	AddStroke(self._cpSatCursor)

	local hue = Create("Frame", picker, "Hue", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 15, 0, 118),
		Position = UDim2.new(0.8, 0, 0, 6), BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", hue, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", hue, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIGradient", hue, nil, {
		Rotation = 90,
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		},
	})

	local hueBtn = Create("ImageButton", hue, nil, {
		AutoButtonColor = false, ImageTransparency = 1, BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 5,
	})

	self._cpHueMarker = Create("Frame", hue, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 2), BorderColor3 = Color3.fromRGB(0, 0, 0),
	})

	local trans = Create("Frame", picker, "Transp", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 15, 0, 118),
		Position = UDim2.new(1, -6, 0, 6), BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", trans, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", trans, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })

	self._cpTransColor = trans
	self._cpTransGrad = Create("UIGradient", trans, nil, {
		Rotation = 90,
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
		},
	})

	local transBtn = Create("ImageButton", trans, nil, {
		AutoButtonColor = false, ImageTransparency = 1, BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 3,
	})

	self._cpTransMarker = Create("Frame", trans, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 2), BorderColor3 = Color3.fromRGB(0, 0, 0), ZIndex = 4,
	})

	local applyBtn = Create("TextButton", picker, "ApplyColor", {
		BorderSizePixel = 0, TextSize = ui_FontSize, TextColor3 = TextBright,
		BackgroundColor3 = BgToggle, FontFace = ui_Font,
		AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(0, 78, 0, 20),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Text = "Apply",
		Position = UDim2.new(0, 5, 1, -4),
	})
	Create("UIStroke", applyBtn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", applyBtn, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })
	_btnFlash(applyBtn)

	local cancelBtn = Create("TextButton", picker, "Cancel", {
		BorderSizePixel = 0, TextSize = ui_FontSize, TextColor3 = TextBright,
		BackgroundColor3 = BgToggle, FontFace = ui_Font,
		AnchorPoint = Vector2.new(1, 1), Size = UDim2.new(0, 78, 0, 20),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Text = "Cancel",
		Position = UDim2.new(1, -5, 1, -4),
	})
	Create("UIStroke", cancelBtn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", cancelBtn, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })
	_btnFlash(cancelBtn)

	local svDragging, hueDragging, transDragging = false, false, false

	satBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			svDragging = true
		end
	end)
	satBtn.MouseButton1Down:Connect(function()
		local abs = sat.AbsolutePosition; local sz = sat.AbsoluteSize
		local mp = UIS:GetMouseLocation()
		self._cpSat = math.clamp((mp.X - abs.X) / sz.X, 0, 1)
		self._cpVal = math.clamp(1 - (mp.Y - abs.Y) / sz.Y, 0, 1)
		self:_cpUpdate()
	end)

	hueBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hueDragging = true
		end
	end)
	hueBtn.MouseButton1Down:Connect(function()
		self._cpHue = math.clamp((UIS:GetMouseLocation().Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
		self:_cpUpdate()
	end)

	transBtn.MouseButton1Down:Connect(function()
		transDragging = true
		self._cpTrans = math.clamp((UIS:GetMouseLocation().Y - trans.AbsolutePosition.Y) / trans.AbsoluteSize.Y, 0, 1)
		self:_cpUpdate()
	end)

	applyBtn.MouseButton1Click:Connect(function()
		local c = Color3.fromHSV(self._cpHue, self._cpSat, self._cpVal)
		if self._colorPickerFlag then
			Library.flags = Library.flags or {}
			Library.flags[self._colorPickerFlag] = c
		end
		if self._colorPickerCallback then
			self._colorPickerCallback(c)
		end
		tween(cp, {GroupTransparency = 1}, TI_FAST)
		task.delay(0.15, function() cp.Visible = false end)
	end)

	cancelBtn.MouseButton1Click:Connect(function()
		if self._colorPickerFlag and self._cpOriginalColor then
			Library.flags = Library.flags or {}
			Library.flags[self._colorPickerFlag] = self._cpOriginalColor
			if self._colorPickerActive then
				self._colorPickerActive.BackgroundColor3 = self._cpOriginalColor
			end
			if self._colorPickerCallback then
				self._colorPickerCallback(self._cpOriginalColor)
			end
		end
		tween(cp, {GroupTransparency = 1}, TI_FAST)
		task.delay(0.15, function() cp.Visible = false end)
	end)

	self:AddConnection(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			svDragging = false; hueDragging = false; transDragging = false
		end
	end))
	self:AddConnection(UIS.InputChanged:Connect(function(input)
		if svDragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local abs = sat.AbsolutePosition; local sz = sat.AbsoluteSize
				self._cpSat = math.clamp((input.Position.X - abs.X) / sz.X, 0, 1)
				self._cpVal = math.clamp(1 - (input.Position.Y - abs.Y) / sz.Y, 0, 1)
				self:_cpUpdate()
			end
		end
		if hueDragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				self._cpHue = math.clamp((input.Position.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
				self:_cpUpdate()
			end
		end
		if transDragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				self._cpTrans = math.clamp((input.Position.Y - trans.AbsolutePosition.Y) / trans.AbsoluteSize.Y, 0, 1)
				self:_cpUpdate()
			end
		end
	end))

	UIS.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if cp.Visible and not self._cpHovered then
				tween(cp, {GroupTransparency = 1}, TI_FAST)
				task.delay(0.15, function() cp.Visible = false end)
			end
		end
	end)
end

function Library:_cpUpdate()
	local c = Color3.fromHSV(self._cpHue, self._cpSat, self._cpVal)
	self._cpSatGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(self._cpHue, 1, 1)),
	}
	self._cpSatOverlayGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
	}
	self._cpSatCursor.Position = UDim2.new(self._cpSat, 0, 1 - self._cpVal, 0)
	self._cpHueMarker.Position = UDim2.new(0, 0, self._cpHue, 0)
	self._cpTransMarker.Position = UDim2.new(0, 0, self._cpTrans, 0)

	if self._cpTransColor then
		if self._cpTransGrad then
			self._cpTransGrad.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromHSV(self._cpHue, self._cpSat, self._cpVal)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
			}
		end
	end

	if self._colorPickerActive then
		self._colorPickerActive.BackgroundColor3 = c
		if self._cpActiveBtn then
			self._cpActiveBtn.BackgroundColor3 = c
		end
	end
end

function Library:_startKeyDetect(target, flag, callback, mode)
	target.Text = "..."
	if self._keyDetectConn then self:RemoveConnection(self._keyDetectConn) end
	self._keyDetectConn = self:AddConnection(UIS.InputBegan:Connect(function(input, gameProcessed)
		local keyName = get_input_name(input)
		local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseButton3
		if gameProcessed and not isMouse then return end
		if keyName then
			target.Text = keyName
			Library.flags[flag] = {key = keyName, mode = mode or "Toggle"}
			if callback then callback(keyName, mode) end
			if self._keybinds then
				for _, kb in ipairs(self._keybinds) do
					if kb.flag == flag then kb.key = keyName; kb.active = false; break end
				end
				self:_rebuildKeybindList()
			end
		end
		if self._keyDetectConn then self:RemoveConnection(self._keyDetectConn); self._keyDetectConn = nil end
	end))
end

function Library:CreateTab(name)
	local tab_page = Create("CanvasGroup", self.tabFolder, name, {
		BorderSizePixel = 0, BackgroundColor3 = BgMid,
		Size = UDim2.new(1, 0, 1, -53), Position = UDim2.new(0, 0, 0, 53),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Visible = false,
	})
	Create("UIStroke", tab_page, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", tab_page, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })

	local left = Create("ScrollingFrame", tab_page, "left", {
		Active = true, BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0.5, 0, 1, 0), ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.new(0, 0, 0, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
		ScrollBarThickness = 0, BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})
	Create("UIPadding", left, nil, { PaddingTop = UDim.new(0, 8), PaddingRight = UDim.new(0, 5), PaddingLeft = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })
	Create("UIListLayout", left, nil, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

	local right = Create("ScrollingFrame", tab_page, "right", {
		Active = true, BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0.5, 0, 1, 0), ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.new(0.5, 0, 0, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
		ScrollBarThickness = 0, BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})
	Create("UIPadding", right, nil, { PaddingTop = UDim.new(0, 8), PaddingRight = UDim.new(0, 5), PaddingLeft = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })
	Create("UIListLayout", right, nil, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

	local btn = Create("TextButton", self.tabbar, name, {
		BorderSizePixel = 0, TextTransparency = 1, TextSize = ui_FontSize,
		TextColor3 = TextBright, BackgroundColor3 = BgButton, FontFace = ui_Font,
		Size = UDim2.new(0, 200, 0, 50), BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIGradient", btn, nil, {
		Rotation = 90,
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 128, 128))},
	})
	local btnLabel = Create("TextLabel", btn, nil, {
		BorderSizePixel = 0, TextSize = ui_FontSize, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		FontFace = ui_Font, TextColor3 = TextDim, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = name,
	})
	Create("UIStroke", btnLabel, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local active_bar = Create("Frame", btn, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Accent,
		AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0.5, 0, 0, 2),
		Position = UDim2.new(0.5, 0, 1, -2), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
	})
	Create("UIGradient", active_bar, nil, {
		Rotation = -90,
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(101, 101, 101)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))},
	})

	local tab = { page = tab_page, left = left, right = right, button = btn, label = btnLabel, bar = active_bar }

	_btnFlash(btn)

	btn.Activated:Connect(function() self:SelectTab(tab) end)

	table.insert(self.tabs, tab)
	if #self.tabs == 1 then self:SelectTab(tab) end

	return tab
end

function Library:SelectTab(tab)
	if self.current_tab then
		self.current_tab.page.Visible = false
		tween(self.current_tab.button, {BackgroundColor3 = BgButton})
		tween(self.current_tab.label, {TextColor3 = TextDim})
		tween(self.current_tab.bar, {BackgroundTransparency = 1})
	end
	self.current_tab = tab
	tab.page.Visible = true
	tween(tab.button, {BackgroundColor3 = BgMid})
	tween(tab.label, {TextColor3 = TextBright})
	tween(tab.bar, {BackgroundTransparency = 0})
end

function Library:CreateSection(tab, name, side)
	if type(side) == "string" then
		side = side == "right" and tab.right or tab.left
	else
		side = side or tab.left
	end

	local section = Create("Frame", side, "section", {
		BorderSizePixel = 0, BackgroundColor3 = BgLight,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", section, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", section, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })

	local padIgnore = Create("Folder", section, "PADDING_IGNORE")

	local titleBar = Create("Frame", padIgnore, "sectionbar", {
		ZIndex = 2, BorderSizePixel = 0, BackgroundColor3 = BgLight,
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 8),
		Position = UDim2.new(0, -2, 0, -2), BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("TextLabel", titleBar, "sectiontitle", {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(154, 154, 154), FontFace = ui_Font,
		TextColor3 = TextDim, BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 8),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Text = name,
	})
	Create("UIStroke", titleBar.sectiontitle, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIPadding", titleBar, nil, { PaddingRight = UDim.new(0, 4) })

	local accentLine = Create("Frame", padIgnore, "sectionbar", {
		BorderSizePixel = 0, BackgroundColor3 = Accent,
		Size = UDim2.new(1, 16, 0, 2), Position = UDim2.new(0, -8, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIGradient", accentLine, nil, {
		Rotation = -90,
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(101, 101, 101)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))},
	})

	Create("UIPadding", section, nil, { PaddingRight = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8) })

	local content = Create("Frame", section, "container", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 10),
		BorderColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1,
	})
	Create("UIPadding", content, nil, { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })
	Create("UIListLayout", content, nil, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

	return content
end

function Library:CreateToggle(parent, config)
	local toggle = Create("Frame", parent, "Toggle", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
	})

	local btn = Create("TextButton", toggle, "maintoggle", {
		BorderSizePixel = 0, TextTransparency = 1, TextSize = 14,
		TextColor3 = Color3.fromRGB(0, 0, 0), BackgroundColor3 = BgToggle,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Size = UDim2.new(0, 10, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", btn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIGradient", btn, nil, {
		Rotation = -90,
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(149, 149, 149)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))},
	})

	Create("TextLabel", toggle, nil, {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(154, 154, 154), FontFace = ui_Font,
		TextColor3 = TextDim, BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = config.name, Position = UDim2.new(0, 18, 0, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	Create("UIStroke", toggle:FindFirstChildOfClass("TextLabel"), nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local holding = Create("Frame", toggle, "holder", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 5, 1, 0),
		Position = UDim2.new(1, 0, 0, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
	})
	Create("UIListLayout", holding, nil, {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
	})

	local enabled = config.default or false

	local function update_visual()
		if enabled then
			tween(btn, {BackgroundColor3 = Accent})
		else
			tween(btn, {BackgroundColor3 = BgToggle})
		end
	end

	update_visual()

	btn.MouseButton1Click:Connect(function()
		enabled = not enabled
		update_visual()
		if config.flag then
			Library.flags = Library.flags or {}
			Library.flags[config.flag] = enabled
		end
		if config.callback then config.callback(enabled) end
		if config.keybind then
			local kbF = config.keybind.flag or ((config.flag or "kb") .. "_key")
			if self._keybinds then
				for _, kb in ipairs(self._keybinds) do
					if kb.flag == kbF then kb.enabled = enabled; if kb.mode == "Always" then kb.active = true end; break end
				end
				self:_rebuildKeybindList()
			end
		end
	end)

	if config.color then self:_addColorButton(holding, config.color) end
	if config.flag then Library.flags = Library.flags or {}; Library.flags[config.flag] = enabled end
	if config.keybind then self:_addKeybindButton(holding, config, config.keybind, enabled) end

	self._refreshElements[#self._refreshElements + 1] = function()
		if config.flag then
			local v = Library.flags[config.flag]
			if v ~= nil then enabled = v; update_visual() end
		end
	end

	return setmetatable({toggle = toggle, button = btn, holding = holding}, {
		__index = {
			CreateKeybind = function(td, kbConfig)
				self:_addKeybindButton(holding, config, kbConfig, enabled)
				return td
			end,
			CreateColorPicker = function(td, cpConfig)
				self:_addColorButton(holding, cpConfig)
				return td
			end,
			AddContextMenu = function(td)
				return self:CreateContext(td)
			end,
		}
	})
end

function Library:_addColorButton(holding, colorConfig)
	local current_color = colorConfig.default or Accent
	local cp_btn = Create("TextButton", holding, "colorpickerbtn", {
		BorderSizePixel = 0, TextTransparency = 1, TextSize = 14,
		TextColor3 = Color3.fromRGB(0, 0, 0), BackgroundColor3 = current_color,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Size = UDim2.new(0, 20, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.new(-3, 0, 0, 0),
	})
	Create("UIStroke", cp_btn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIGradient", cp_btn, nil, {
		Rotation = -90,
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(222, 222, 222)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(221, 221, 221)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))},
	})

	cp_btn.MouseButton1Click:Connect(function()
		local c = Library.flags[colorConfig.flag] or current_color
		self._cpOriginalColor = c
		local h, s, v = Color3.toHSV(c)
		self._cpHue, self._cpSat, self._cpVal = h, s, v
		self._colorPickerActive = cp_btn
		self._cpActiveBtn = cp_btn
		self._colorPickerCallback = colorConfig.callback
		self._colorPickerFlag = colorConfig.flag
		self:_cpUpdate()
		self._cpPopup.Position = UDim2.new(0, cp_btn.AbsolutePosition.X - 85, 0, cp_btn.AbsolutePosition.Y + 16)
		self._cpPopup.Visible = true
		tween(self._cpPopup, {GroupTransparency = 0}, TI_BOUNCE)
	end)

	if colorConfig.flag then Library.flags = Library.flags or {}; Library.flags[colorConfig.flag] = current_color end
	self._refreshElements[#self._refreshElements + 1] = function()
		if colorConfig.flag then
			local c = Library.flags[colorConfig.flag]
			if c and typeof(c) == "Color3" then cp_btn.BackgroundColor3 = c end
		end
	end
end

function Library:_addKeybindButton(holding, config, kbConfig, enabled)
	local kbDefault = kbConfig.default or "E"
	local kbFlag = kbConfig.flag or ((config.flag or "kb") .. "_key")
	local kbCb = kbConfig.callback

	self._keybinds = self._keybinds or {}
	local mode = kbConfig.mode or "Toggle"
	table.insert(self._keybinds, {name = config.name, flag = kbFlag, key = shortKey(kbDefault), mode = mode, enabled = enabled or false, active = (mode == "Always")})
	self:_rebuildKeybindList()

	local kbBtn = Create("TextButton", holding, "keybindbtn", {
		BorderSizePixel = 0, TextSize = ui_FontSize, TextColor3 = TextBright,
		BackgroundColor3 = BgToggle, FontFace = ui_Font,
		Size = UDim2.new(0, 25, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = shortKey(kbDefault), Position = UDim2.new(-9, 0, 0, 0),
	})
	Create("UIStroke", kbBtn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })

	local kmPopup = Create("CanvasGroup", self.gui, "KeybindCtx", {
		BorderSizePixel = 0, BackgroundColor3 = BgDark,
		Size = UDim2.new(0, 68, 0, 65), Position = UDim2.new(0.68026, 0, 0.40685, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Visible = false, GroupTransparency = 1,
	})
	Create("UIStroke", kmPopup, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", kmPopup, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })

	local kmMode = mode
	local kmButtons = {}
	local kmCloseConn = nil

	local function makeModeBtn(name, y, y2)
		local b = Create("TextButton", kmPopup, nil, {
			BorderSizePixel = 0, TextSize = ui_FontSize, TextColor3 = TextBright,
			BackgroundColor3 = BgLight, FontFace = ui_Font,
			Size = UDim2.new(0, 60, 0, 15), BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = name, Position = UDim2.new(0.0595, 0, y, y2),
		})
		Create("UIStroke", b, nil, { Color = StrokeColor, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
		Create("UIStroke", b, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })
		return b
	end

	kmButtons.Hold = makeModeBtn("Hold", 0.071, 0)
	kmButtons.Toggle = makeModeBtn("Toggle", 0.386, 0)
	kmButtons.Always = makeModeBtn("Always", 0.81, -7)

	local function kmHighlight(md)
		for m, b in pairs(kmButtons) do
			b.TextColor3 = m == md and Accent or TextBright
		end
	end

	local function onModeClick(md)
		kmMode = md
		kmHighlight(md)
		if kmCloseConn then kmCloseConn:Disconnect(); kmCloseConn = nil end
		tween(kmPopup, {GroupTransparency = 1}, TI_FAST)
		task.delay(0.15, function() kmPopup.Visible = false end)
		Library.flags = Library.flags or {}
		local existing = Library.flags[kbFlag]
		if existing then existing.mode = md else Library.flags[kbFlag] = {key = nil, mode = md} end
		if kbCb then kbCb(existing and existing.key, md) end
		if self._keybinds then
			for _, kb in ipairs(self._keybinds) do
				if kb.flag == kbFlag then kb.mode = md; if md == "Always" then kb.active = true else kb.active = false end; break end
			end
			self:_rebuildKeybindList()
		end
	end

	kmButtons.Hold.MouseButton1Click:Connect(function() onModeClick("Hold") end)
	kmButtons.Toggle.MouseButton1Click:Connect(function() onModeClick("Toggle") end)
	kmButtons.Always.MouseButton1Click:Connect(function() onModeClick("Always") end)

	kbBtn.MouseButton1Click:Connect(function()
		Library.flags = Library.flags or {}
		local existing = Library.flags[kbFlag]
		kmMode = (existing and existing.mode) or kbConfig.mode or "Toggle"
		self:_startKeyDetect(kbBtn, kbFlag, kbCb, kmMode)
	end)
	kbBtn.MouseButton2Click:Connect(function()
		Library.flags = Library.flags or {}
		local existing = Library.flags[kbFlag]
		kmMode = (existing and existing.mode) or kbConfig.mode or "Toggle"
		kmHighlight(kmMode)
		if kmCloseConn then kmCloseConn:Disconnect() end
		kmPopup.Position = UDim2.new(0, kbBtn.AbsolutePosition.X - 34, 0, kbBtn.AbsolutePosition.Y + 16)
		kmPopup.Visible = true
		tween(kmPopup, {GroupTransparency = 0}, TI_FAST)
		kmCloseConn = closeIfNotOver({kmPopup}, function()
			tween(kmPopup, {GroupTransparency = 1}, TI_FAST)
			task.delay(0.15, function() kmPopup.Visible = false end)
		end)
	end)

	self._refreshElements[#self._refreshElements + 1] = function()
		local kb = Library.flags[kbFlag]
		if kb and kb.key then kbBtn.Text = kb.key end
	end
end

function Library:CreateButton(parent, config)
	local frame = Create("Frame", parent, "Button", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 10),
		BorderColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1,
	})

	local btn = Create("TextButton", frame, "BtnMain", {
		BorderSizePixel = 0, TextSize = ui_FontSize, TextColor3 = TextDim,
		BackgroundColor3 = BgToggle, FontFace = ui_Font,
		Size = UDim2.new(1, 0, 0, 16), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = config.name,
	})
	Create("UIStroke", btn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
	_btnFlash(btn)

	btn.MouseButton1Click:Connect(function()
		if config.callback then config.callback() end
	end)

	return {frame = frame, button = btn}
end

function Library:CreateLabel(parent, config)
	if type(config) == "string" then config = {name = config} end
	local frame = Create("Frame", parent, "Label", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 10),
		BorderColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1,
	})

	Create("TextLabel", frame, nil, {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(154, 154, 154), FontFace = ui_Font,
		TextColor3 = TextBright, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = config.name,
	})
	Create("UIStroke", frame:FindFirstChildOfClass("TextLabel"), nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local holding = Create("Frame", frame, "holder", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 5, 1, 0),
		Position = UDim2.new(1, 0, 0, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
	})
	Create("UIListLayout", holding, nil, {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
	})

	if config.color then self:_addColorButton(holding, config.color) end
	if config.keybind then self:_addKeybindButton(holding, config, config.keybind, true) end

	return {frame = frame, holding = holding}
end

function Library:CreateContext(parent)
	local cogBtn = Create("ImageButton", parent.holding, "contextmenubtn", {
		BorderSizePixel = 0, BackgroundColor3 = BgToggle, Image = "rbxassetid://6793572208",
		Size = UDim2.new(0, 10, 0, 10), ClipsDescendants = true,
		BorderColor3 = Color3.fromRGB(0, 0, 0), Position = UDim2.new(0.74866, -2, 0, 0),
	})
	Create("UIStroke", cogBtn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })

	local ctxPopup = Create("CanvasGroup", self.gui, "ContextMenu", {
		BorderSizePixel = 0, BackgroundColor3 = BgDark,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(0, 240, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Visible = false, GroupTransparency = 1,
	})
	Create("UIStroke", ctxPopup, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", ctxPopup, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIPadding", ctxPopup, nil, { PaddingRight = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8) })

	local inner = Create("CanvasGroup", ctxPopup, "Container", {
		BorderSizePixel = 0, BackgroundColor3 = BgMid,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 4), BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", inner, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", inner, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIPadding", inner, nil, { PaddingRight = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8) })

	local content = Create("Frame", inner, "container", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 25), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
	})
	Create("UIPadding", content, nil, { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })
	Create("UIListLayout", content, nil, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

	local ctxCloseConn = nil
	local function open()
		if ctxCloseConn then ctxCloseConn:Disconnect() end
		ctxPopup.Position = UDim2.new(0, cogBtn.AbsolutePosition.X - 100, 0, cogBtn.AbsolutePosition.Y + 16)
		ctxPopup.Visible = true
		tween(ctxPopup, {GroupTransparency = 0}, TI_FAST)
		ctxCloseConn = closeIfNotOver({ctxPopup, cogBtn}, function()
			tween(ctxPopup, {GroupTransparency = 1}, TI_FAST)
			task.delay(0.15, function() ctxPopup.Visible = false end)
		end)
	end

	_btnFlash(cogBtn)
	cogBtn.MouseButton1Click:Connect(open)
	return content
end

function Library:CreateColorPicker(parent, config)
	local frame = Create("Frame", parent, "ColorPicker", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
	})
	Create("TextLabel", frame, nil, {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(154, 154, 154), FontFace = ui_Font,
		TextColor3 = TextBright, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = config.name,
	})
	Create("UIStroke", frame:FindFirstChildOfClass("TextLabel"), nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local current_color = config.default or Accent
	local cp_btn = Create("TextButton", frame, "colorpickerbtn", {
		BorderSizePixel = 0, TextTransparency = 1, TextSize = 14,
		TextColor3 = Color3.fromRGB(0, 0, 0), BackgroundColor3 = current_color,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Size = UDim2.new(0, 20, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
	})
	Create("UIStroke", cp_btn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIGradient", cp_btn, nil, {
		Rotation = -90,
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(222, 222, 222)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(221, 221, 221)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))},
	})

	cp_btn.MouseButton1Click:Connect(function()
		local c = Library.flags[config.flag] or current_color
		self._cpOriginalColor = c
		local h, s, v = Color3.toHSV(c)
		self._cpHue, self._cpSat, self._cpVal = h, s, v
		self._colorPickerActive = cp_btn
		self._cpActiveBtn = cp_btn
		self._colorPickerCallback = config.callback
		self._colorPickerFlag = config.flag
		self:_cpUpdate()
		self._cpPopup.Position = UDim2.new(0, cp_btn.AbsolutePosition.X - 85, 0, cp_btn.AbsolutePosition.Y + 16)
		self._cpPopup.Visible = true
		tween(self._cpPopup, {GroupTransparency = 0}, TI_BOUNCE)
	end)

	if config.flag then Library.flags = Library.flags or {}; Library.flags[config.flag] = current_color end
	self._refreshElements[#self._refreshElements + 1] = function()
		if config.flag then
			local c = Library.flags[config.flag]
			if c and typeof(c) == "Color3" then cp_btn.BackgroundColor3 = c end
		end
	end
	return cp_btn
end

function Library:RegisterKeybindLabel(flag, name)
	self._keybinds = self._keybinds or {}
	table.insert(self._keybinds, {name = name, flag = flag, key = "?", mode = "Toggle", enabled = true, active = false})
	self:_rebuildKeybindList()
	self._refreshElements[#self._refreshElements + 1] = function()
		local existing = Library.flags[flag]
		if existing then
			for _, kb in ipairs(self._keybinds) do
				if kb.flag == flag then kb.key = existing.key or kb.key; kb.mode = existing.mode or kb.mode; break end
			end
		end
	end
end

function Library:CreateTextBox(parent, config)
	local frame = Create("Frame", parent, "TextBox", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 16), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
	})
	local box = Create("TextBox", frame, nil, {
		BorderSizePixel = 0, TextSize = ui_FontSize, ClearTextOnFocus = false,
		BackgroundColor3 = BgToggle, FontFace = ui_Font,
		TextColor3 = TextDim, Size = UDim2.new(1, 0, 0, 16),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = config.default or "", PlaceholderText = config.placeholder or "",
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	Create("UIStroke", box, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if config.flag then Library.flags = Library.flags or {}; Library.flags[config.flag] = box.Text end
	end)
	if config.flag then Library.flags = Library.flags or {}; if not Library.flags[config.flag] then Library.flags[config.flag] = config.default or "" end end
	return {frame = frame, box = box}
end

function Library:CreateSlider(parent, config)
local slider = Create("Frame", parent, "Slider", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 1.66667, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
	})

	local bar = Create("TextButton", slider, "mainbtn", {
		BorderSizePixel = 0, TextTransparency = 1, TextSize = 14,
		TextColor3 = Color3.fromRGB(0, 0, 0), BackgroundColor3 = BgToggle,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Size = UDim2.new(1, 0, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.new(0, 0, 1, -10),
	})
	Create("UIStroke", bar, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })

	local fill = Create("Frame", bar, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Accent,
		Size = UDim2.new(0.5, 0, 1, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIGradient", fill, nil, {
		Rotation = -90,
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(149, 149, 149)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))},
	})

	Create("TextLabel", slider, "name", {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), FontFace = ui_Font,
		TextColor3 = TextBright, BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = config.name, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	Create("UIStroke", slider.name, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local value_label = Create("TextLabel", slider, "amt", {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), FontFace = ui_Font,
		TextColor3 = TextDim, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 57, 0, 10),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Text = "num", Position = UDim2.new(1, 0, 0, 0),
	})
	Create("UIStroke", value_label, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local min = config.min or 0
	local max = config.max or 100
	local step = config.step or 1
	local value = config.default or min

	local function update(new_value)
		value = math.clamp(new_value, min, max)
		local fraction = (value - min) / (max - min)
		tween(fill, {Size = UDim2.new(fraction, 0, 1, 0)})
		local display = step == 1 and math.floor(value) or string.format("%.2f", value)
		value_label.Text = display
		if config.flag then Library.flags = Library.flags or {}; Library.flags[config.flag] = value end
		if config.callback then config.callback(value) end
	end

	update(value)

	local dragging = false
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
	end)
	self:AddConnection(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))
	self:AddConnection(UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local fraction = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			update(min + fraction * (max - min))
		end
	end))
	bar.MouseButton1Down:Connect(function()
		local pos = UIS:GetMouseLocation()
		local fraction = math.clamp((pos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		update(min + fraction * (max - min))
	end)

	self._refreshElements[#self._refreshElements + 1] = function()
		if config.flag then local v = Library.flags[config.flag]; if v ~= nil then update(v) end end
	end

	return {slider = slider, bar = bar, fill = fill, value_label = value_label}
end

function Library:CreateRangeSlider(parent, config)
	local slider = Create("Frame", parent, "RangeSlider", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 1.66667, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
	})

	local bar = Create("TextButton", slider, "mainbtn", {
		BorderSizePixel = 0, TextTransparency = 1, TextSize = 14,
		TextColor3 = Color3.fromRGB(0, 0, 0), BackgroundColor3 = BgToggle,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Size = UDim2.new(1, 0, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.new(0, 0, 1, -10),
	})
	Create("UIStroke", bar, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })

	local fill = Create("Frame", bar, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Accent,
		Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0.2, 0, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIGradient", fill, nil, {
		Rotation = -90,
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(149, 149, 149)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))},
	})

	Create("TextLabel", slider, "name", {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), FontFace = ui_Font,
		TextColor3 = TextBright, BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = config.name, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	Create("UIStroke", slider.name, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local value_label = Create("TextLabel", slider, "amt", {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), FontFace = ui_Font,
		TextColor3 = TextDim, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 57, 0, 10),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Text = "num - num", Position = UDim2.new(1, 0, 0, 0),
	})
	Create("UIStroke", value_label, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local min = config.min or 0
	local max = config.max or 100
	local step = config.step or 1
	local lowVal = config.defaultMin or min
	local highVal = config.defaultMax or max
	local draggingLow, draggingHigh = false, false

	local function update()
		local lowFrac = math.clamp((lowVal - min) / (max - min), 0, 1)
		local highFrac = math.clamp((highVal - min) / (max - min), 0, 1)
		tween(fill, {Position = UDim2.new(lowFrac, 0, 0, 0), Size = UDim2.new(highFrac - lowFrac, 0, 1, 0)})
		local dLow = step == 1 and math.floor(lowVal) or string.format("%.2f", lowVal)
		local dHigh = step == 1 and math.floor(highVal) or string.format("%.2f", highVal)
		value_label.Text = dLow .. " - " .. dHigh
		if config.flag then Library.flags = Library.flags or {}; Library.flags[config.flag] = {lowVal, highVal} end
		if config.callback then config.callback(lowVal, highVal) end
	end

	update()

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local frac = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local clickVal = min + frac * (max - min)
			local distLow = math.abs(clickVal - lowVal)
			local distHigh = math.abs(clickVal - highVal)
			if distLow < distHigh then draggingLow = true else draggingHigh = true end
		end
	end)
	self:AddConnection(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingLow = false; draggingHigh = false
		end
	end))
	self:AddConnection(UIS.InputChanged:Connect(function(input)
		if not draggingLow and not draggingHigh then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local frac = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local val = min + frac * (max - min)
			if draggingLow then lowVal = math.clamp(val, min, highVal); update() end
			if draggingHigh then highVal = math.clamp(val, lowVal, max); update() end
		end
	end))
	bar.MouseButton1Down:Connect(function()
		local pos = UIS:GetMouseLocation()
		local frac = math.clamp((pos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local clickVal = min + frac * (max - min)
		if math.abs(clickVal - lowVal) < math.abs(clickVal - highVal) then
			lowVal = math.clamp(clickVal, min, highVal)
			draggingLow = true
		else
			highVal = math.clamp(clickVal, lowVal, max)
			draggingHigh = true
		end
		update()
	end)

	self._refreshElements[#self._refreshElements + 1] = function()
		if config.flag then
			local v = Library.flags[config.flag]
			if type(v) == "table" and #v >= 2 then lowVal = v[1]; highVal = v[2]; update() end
		end
	end

	return {slider = slider, bar = bar, fill = fill, value_label = value_label}
end

function Library:CreateDropdown(parent, config)
	local multi = config.multi or false
	local options = config.options or {}

	local selected = {}
	if multi then
		if type(config.default) == "table" then for _, v in ipairs(config.default) do selected[v] = true end end
	else
		local def = config.default or options[1]
		if def then selected[def] = true end
	end

	local frame = Create("Frame", parent, "Dropdown", {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0.66667, 10),
		BorderColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1,
	})

	Create("TextLabel", frame, "title", {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(154, 154, 154), FontFace = ui_Font,
		TextColor3 = TextBright, BackgroundTransparency = 1,
		Size = UDim2.new(0, 57, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = config.name, Position = UDim2.new(0, 0, 0, 4),
	})
	Create("UIStroke", frame.title, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local dropdown_btn = Create("TextButton", frame, "mainbtn", {
		BorderSizePixel = 0, TextTransparency = 1, TextSize = 14,
		TextColor3 = Color3.fromRGB(0, 0, 0), BackgroundColor3 = BgToggle,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0.5, 0, 0, 16),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Position = UDim2.new(1, 0, 0, 0),
	})
	Create("UIStroke", dropdown_btn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })

	local value_label = Create("TextLabel", dropdown_btn, nil, {
		ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(154, 154, 154), FontFace = ui_Font,
		TextColor3 = Color3.fromRGB(151, 151, 151), BackgroundTransparency = 1,
		Size = UDim2.new(0, 57, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "...", Position = UDim2.new(0, 6, 0, 4),
	})
	Create("UIStroke", value_label, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	local arrowBtn = Create("TextButton", dropdown_btn, "DONOTTOUCHVISUALONLY", {
		Interactable = false, BorderSizePixel = 0, TextTransparency = 1, TextSize = 14,
		TextColor3 = Color3.fromRGB(0, 0, 0), BackgroundColor3 = Color3.fromRGB(37, 37, 37),
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 16, 0, 16),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Position = UDim2.new(1, 0, 0, 0),
	})
	Create("ImageLabel", arrowBtn, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(0.5, 0.5), Image = "rbxassetid://8539638324",
		Size = UDim2.new(0, 10, 0, 10), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1, Rotation = 180, Position = UDim2.new(0.5, 0, 0.5, 0),
	})

	local option_list = Create("Frame", dropdown_btn, "holder", {
		Visible = false, BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, ZIndex = 100,
	})
	Create("UIPadding", option_list, nil, { PaddingTop = UDim.new(0, 20) })
	Create("UIListLayout", option_list, nil, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

	local option_buttons = {}
	for _, opt in ipairs(options) do
		local opt_btn = Create("TextButton", option_list, "optionbtn", {
			BorderSizePixel = 0, TextTransparency = 1, TextSize = 14,
			TextColor3 = Color3.fromRGB(0, 0, 0), BackgroundColor3 = BgToggle,
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Size = UDim2.new(1, 0, 0, 16), BorderColor3 = Color3.fromRGB(0, 0, 0),
		})
		Create("UIStroke", opt_btn, nil, { ZIndex = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter })
		local opt_label = Create("TextLabel", opt_btn, nil, {
			ZIndex = 3, BorderSizePixel = 0, TextSize = ui_FontSize,
			BackgroundColor3 = Color3.fromRGB(154, 154, 154), FontFace = ui_Font,
			TextColor3 = Color3.fromRGB(151, 151, 151), BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0), BorderColor3 = Color3.fromRGB(0, 0, 0), Text = opt,
		})
		Create("UIStroke", opt_label, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })
		option_buttons[opt] = {button = opt_btn, label = opt_label}
	end

	local open = false
	local close_connection = nil

	local function update_value_text()
		if multi then
			local parts = {}
			for _, opt in ipairs(options) do if selected[opt] then table.insert(parts, opt) end end
			value_label.Text = #parts > 0 and table.concat(parts, ",") or "..."
		else
			for _, opt in ipairs(options) do if selected[opt] then value_label.Text = opt; return end end
			value_label.Text = "..."
		end
	end

	local function refresh_option_colors()
		for opt, data in pairs(option_buttons) do
			data.label.TextColor3 = selected[opt] and Accent or Color3.fromRGB(151, 151, 151)
		end
	end

	local function close()
		open = false; option_list.Visible = false
		if close_connection then close_connection:Disconnect(); close_connection = nil end
	end

	local function toggle_dd()
		if open then close(); return end
		open = true; refresh_option_colors(); option_list.Visible = true
		close_connection = closeIfNotOver({frame, option_list}, close)
	end

	for opt, data in pairs(option_buttons) do
		data.button.MouseButton1Click:Connect(function()
			if multi then selected[opt] = not selected[opt]
			else for k in pairs(selected) do selected[k] = false end; selected[opt] = true; close() end
			update_value_text(); refresh_option_colors()
			if config.flag then
				Library.flags = Library.flags or {}
				if multi then
					local sel_list = {}
					for _, o in ipairs(options) do if selected[o] then table.insert(sel_list, o) end end
					Library.flags[config.flag] = sel_list
				else Library.flags[config.flag] = opt end
			end
			if config.callback then config.callback(opt, selected[opt]) end
		end)
	end

	dropdown_btn.MouseButton1Click:Connect(toggle_dd)
	update_value_text()

	self._refreshElements[#self._refreshElements + 1] = function()
		if config.flag then
			local f = Library.flags[config.flag]
			if f ~= nil then
				for k in pairs(selected) do selected[k] = false end
				if multi and type(f) == "table" then for _, o in ipairs(f) do selected[o] = true end
				elseif not multi and type(f) == "string" then selected[f] = true end
				update_value_text(); refresh_option_colors()
			end
		end
	end

	return {frame = frame, button = dropdown_btn, value_label = value_label, option_list = option_list, close = close, toggle = toggle_dd}
end

function Library:SaveConfig(name)
	local function isColor3(v)
		local ok = pcall(function() return v.R, v.G, v.B end)
		return ok and type(v.R) == "number"
	end
	local function serialize(v)
		if isColor3(v) then return {__color3 = {v.R, v.G, v.B}}
		elseif type(v) == "table" then local t = {}; for kk, vv in pairs(v) do t[kk] = serialize(vv) end; return t end
		return v
	end
	local filtered = {}
	for k, v in pairs(Library.flags) do if type(k) == "string" then filtered[k] = serialize(v) end end
	local json = HttpService:JSONEncode(filtered)
	makefolder(self._configFolder)
	writefile(self._configFolder .. "/" .. name .. ".json", json)
	writefile(self._configFolder .. "/_last.txt", name)
end

function Library:LoadConfig(name)
	local function deserialize(v)
		if type(v) == "table" and v.__color3 then return Color3.new(v.__color3[1], v.__color3[2], v.__color3[3])
		elseif type(v) == "table" then local t = {}; for kk, vv in pairs(v) do t[kk] = deserialize(vv) end; return t end
		return v
	end
	local path = self._configFolder .. "/" .. name .. ".json"
	if not isfile(path) then return false end
	local json = readfile(path)
	local data = HttpService:JSONDecode(json)
	if type(data) ~= "table" then return false end
	for k, v in pairs(data) do Library.flags[k] = deserialize(v) end
	writefile(self._configFolder .. "/_last.txt", name)
	self:Refresh()
	return true
end

function Library:LoadLastConfig()
	local path = self._configFolder .. "/_last.txt"
	if not isfile(path) then return false end
	local name = readfile(path)
	if name and name ~= "" then return self:LoadConfig(name) end
	return false
end

function Library:GetConfigs()
	local configs = {}
	if not isfolder(self._configFolder) then return configs end
	for _, file in ipairs(listfiles(self._configFolder)) do
		local name = file:match("([^/\\]+)%.json$")
		if name then table.insert(configs, name) end
	end
	return configs
end

function Library:DeleteConfig(name)
	local path = self._configFolder .. "/" .. name .. ".json"
	if isfile(path) then delfile(path) end
end

function Library:Refresh()
	Library.flags = Library.flags or {}
	if self._refreshElements then for _, fn in ipairs(self._refreshElements) do fn() end end
	self:_rebuildKeybindList()
end

function Library:GetState(flag)
	if not self._keybinds then return false end
	for _, kb in ipairs(self._keybinds) do if kb.flag == flag then return kb.active end end
	return false
end

function Library:ShowKeybinds(enabled)
	if self._kbList then self._kbList:Destroy(); self._kbList = nil end
	if self._keyStateConn then self:RemoveConnection(self._keyStateConn); self._keyStateConn = nil end
	if self._keyStateEndConn then self:RemoveConnection(self._keyStateEndConn); self._keyStateEndConn = nil end
	if not enabled then return end

	self._kbList = Create("Frame", self.gui, "KeybindList", {
		BorderSizePixel = 0, BackgroundColor3 = BgDark,
		Size = UDim2.new(0, 86, 0, 17), Position = UDim2.new(0, 10, 0.5, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", self._kbList, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", self._kbList, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })

	Create("TextLabel", self._kbList, nil, {
		BorderSizePixel = 0, TextSize = ui_FontSize, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		FontFace = ui_Font, TextColor3 = TextBright, BackgroundTransparency = 1,
		Size = UDim2.new(0, 86, 0, 17), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = "Keybinds",
	})

	self:AddConnection(MakeDraggable(self._kbList, function() return not self._menuVisible end))

	self._kbEntries = Create("Frame", self._kbList, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0, 86, 0, 31), Position = UDim2.new(0, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1,
	})
	Create("UIListLayout", self._kbEntries, nil, { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })

	self:_rebuildKeybindList()
end
Library.KeybindList = Library.ShowKeybinds

function Library:_rebuildKeybindList()
	if not self._kbEntries then return end
	for _, c in ipairs(self._kbEntries:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if not self._keybinds then return end

	if not self._keyStateConn then
		self._keyStateConn = self:AddConnection(UIS.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			local kn = get_input_name(input)
			if not kn then return end
			if not self._keybinds then return end
			for _, kb in ipairs(self._keybinds) do
				if kb.key == kn then
					if kb.mode == "Hold" then kb.active = true
					elseif kb.mode == "Toggle" then kb.active = not kb.active end
				end
			end
			self:_rebuildKeybindList()
		end))
		self._keyStateEndConn = self:AddConnection(UIS.InputEnded:Connect(function(input)
			local kn = get_input_name(input)
			if not kn then return end
			if not self._keybinds then return end
			local changed = false
			for _, kb in ipairs(self._keybinds) do
				if kb.mode == "Hold" and kb.key == kn then kb.active = false; changed = true end
			end
			if changed then self:_rebuildKeybindList() end
		end))
	end

	local active = {}
	for _, kb in ipairs(self._keybinds) do if kb.active then active[#active + 1] = kb end end
	if #active == 0 then self._kbEntries.Size = UDim2.new(0, 86, 0, 0); return end

	local entries = {}
	local HORIZONTAL_PADDING = 8

	for _, kb in ipairs(active) do
		local bindText = "[" .. kb.key .. "] " .. kb.name
		local measureLabel = Create("TextLabel", self._kbEntries, nil, {
			BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), FontFace = ui_Font,
			TextColor3 = Accent, BackgroundTransparency = 1,
			Size = UDim2.new(0, 9999, 1, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = bindText, Visible = false,
		})
		local naturalW = measureLabel.TextBounds.X + HORIZONTAL_PADDING
		measureLabel:Destroy()

		local bf = Create("Frame", self._kbEntries, nil, {
			BorderSizePixel = 0, BackgroundColor3 = BgDark,
			Size = UDim2.new(0, naturalW, 0, 17), BorderColor3 = Color3.fromRGB(0, 0, 0),
		})
		Create("UIStroke", bf, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
		Create("UIStroke", bf, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })

		local blendingframe = Create("Frame", bf, nil, {
			BorderSizePixel = 0, BackgroundColor3 = BgDark,
			Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, -2),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
		})

		Create("TextLabel", bf, nil, {
			BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), FontFace = ui_Font,
			TextColor3 = Accent, BackgroundTransparency = 1,
			Size = UDim2.new(0, naturalW, 1, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
			Text = bindText,
		})

		entries[#entries + 1] = {frame = bf, width = naturalW, blend = blendingframe}
	end

	for i, e in ipairs(entries) do
		if i == 1 then
			e.blend.Size = UDim2.new(0, 86, 0, 2)
			if e.width <= 86 then e.frame.Size = UDim2.new(0, 86, 0, 17) end
		else
			local width = e.width
			if e.width >= entries[i - 1].width then width = entries[i - 1].width end
			e.blend.Size = UDim2.new(0, width, 0, 2)
		end
	end

	self._kbEntries.Size = UDim2.new(0, 86, 0, #entries * 19)
end

function Library:Notify(text, arg2, arg3)
	local duration, isWarning
	if type(arg2) == "number" then duration = arg2; isWarning = arg3
	else duration = 3; isWarning = arg2 end

	local barColor = type(isWarning) == "boolean" and isWarning and Color3.fromRGB(255, 200, 0) or Accent

	if not self.notifyHolder then
		self.notifyHolder = Create("Frame", self.gui, "NotifyHolder", {
			BackgroundTransparency = 1, Size = UDim2.new(0, 220, 1, -20),
			Position = UDim2.new(0.008, 0, 0.03, 0), ZIndex = 999,
			BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
		})
		Create("UIListLayout", self.notifyHolder, nil, {
			Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	end

	local notifyFrame = Create("CanvasGroup", self.notifyHolder, nil, {
		BackgroundColor3 = BgDark, Size = UDim2.new(0, 0, 0, 22),
		BorderColor3 = Color3.fromRGB(0, 0, 0), GroupTransparency = 1, ZIndex = 999, BorderSizePixel = 0,
	})
	Create("UIStroke", notifyFrame, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", notifyFrame, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })

	local notifyText = Create("TextLabel", notifyFrame, nil, {
		TextStrokeTransparency = 0, BorderSizePixel = 0, TextSize = ui_FontSize,
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		FontFace = ui_Font, TextColor3 = isWarning and barColor or TextDim,
		BackgroundTransparency = 1, RichText = true, Size = UDim2.new(0, 0, 1, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0), Text = text or "", Position = UDim2.new(0, 6, 0, 0),
	})

	local textWidth = notifyText.TextBounds.X
	local textHeight = notifyText.TextBounds.Y
	local frameHeight = math.max(22, math.ceil(textHeight) + 6)
	local frameWidth = math.clamp(math.ceil(textWidth) + 52, 120, 400)
	notifyFrame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
	notifyText.Size = UDim2.new(0, frameWidth - 36, 1, 0)

	local timerLabel = Create("TextLabel", notifyFrame, nil, {
		TextStrokeTransparency = 0, BorderSizePixel = 0, TextSize = ui_FontSize,
		TextXAlignment = Enum.TextXAlignment.Right, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		FontFace = ui_Font, TextColor3 = barColor, BackgroundTransparency = 1,
		Size = UDim2.new(0, 28, 1, 0), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = duration .. "s", Position = UDim2.new(1, -32, 0, 0),
	})

	local timerBar = Create("Frame", notifyFrame, nil, {
		BorderSizePixel = 0, BackgroundColor3 = barColor,
		Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	AddStroke(timerBar)

	tween(notifyFrame, {GroupTransparency = 0}, TI_FAST)
	tween(timerBar, {Size = UDim2.new(0, 0, 0, 2)}, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out))

	if isWarning then
		local flashTween = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		local flashColor = Color3.fromRGB(100, 100, 0)
		for i = 1, 6 do
			task.delay((i - 1) * 0.5, function()
				local target = i % 2 == 1 and barColor or flashColor
				tween(timerBar, {BackgroundColor3 = target}, flashTween)
			end)
		end
	end

	for i = duration - 1, 0, -1 do
		task.delay(duration - i, function()
			if notifyFrame and notifyFrame.Parent then timerLabel.Text = i .. "s" end
		end)
	end

	task.delay(duration, function()
		tween(notifyFrame, {GroupTransparency = 1}, TI_FAST)
		task.delay(0.15, function()
			if notifyFrame and notifyFrame.Parent then notifyFrame:Destroy() end
		end)
	end)
end

function Library:CreateWatermark(text)
	if self._watermark then self._watermark:Destroy(); self._watermark = nil end
	if not text then return end

	self._watermark = Create("CanvasGroup", self.gui, "Watermark", {
		BorderSizePixel = 0, BackgroundColor3 = BgDark,
		Size = UDim2.new(0, 274, 0, 30), Position = UDim2.new(0, 10, 0.05, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIStroke", self._watermark, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", self._watermark, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })

	local accentLine = Create("Frame", self._watermark, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Accent,
		AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1.00182, 0, 0, 2),
		Position = UDim2.new(0.49909, 0, 0.06667, -2),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
	})
	Create("UIGradient", accentLine, nil, {
		Rotation = -90,
		Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(101, 101, 101)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))},
	})

	self:AddConnection(MakeDraggable(self._watermark, function() return not self._menuVisible end))

	Create("ImageLabel", self._watermark, nil, {
		BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Image = "rbxassetid://81144545895084",
		Size = UDim2.new(0, 28, 0, 28), BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.06667, 0),
	})

	Create("TextLabel", self._watermark, "Title", {
		BorderSizePixel = 0, TextSize = ui_FontSize, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), FontFace = ui_Font,
		TextColor3 = TextBright, BackgroundTransparency = 1,
		Size = UDim2.new(0.89781, 0, 0.06667, 24), BorderColor3 = Color3.fromRGB(0, 0, 0),
		Text = text, Position = UDim2.new(0.10219, 0, 0.13333, 0),
	})
	Create("UIStroke", self._watermark.Title, nil, { ZIndex = 0, LineJoinMode = Enum.LineJoinMode.Miter })

	self._wmText = text
end
Library.Watermark = Library.CreateWatermark

function Library:SetWatermark(text)
	self._wmText = text or ""
	if self._watermark then self._watermark:Destroy(); self._watermark = nil end
	if text and text ~= "" then self:CreateWatermark(text) end
end

function Library:AddPreviewRig(parent, userId)
	local Players = game:GetService("Players")
	local Lighting = game:GetService("Lighting")

	local container = Create("Frame", parent, nil, {
		BorderSizePixel = 0, BackgroundColor3 = BgMid,
		Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1,
	})
	Create("UIStroke", container, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", container, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })

	local vp = Create("ViewportFrame", container, "PreviewRig", {
		BorderSizePixel = 0, BackgroundColor3 = BgMid,
		Size = UDim2.new(1, 0, 1, 0),
	})
	Create("UIStroke", vp, nil, { Color = StrokeColor, LineJoinMode = Enum.LineJoinMode.Miter })
	Create("UIStroke", vp, nil, { ZIndex = 0, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter })

	local worldModel = Instance.new("WorldModel", vp)
	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("Sky") or obj:IsA("Atmosphere") then
			obj:Clone().Parent = worldModel
		end
	end

	local id = userId and tonumber(userId) or game.Players.LocalPlayer.UserId
	local rig = nil
	local humanoid = nil

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromUserId(id)
	end)

	if ok and model then
		rig = model
		rig.Parent = worldModel
		rig:MoveTo(Vector3.new(0, 1.5, -8))

		for _, obj in ipairs(rig:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.Anchored = true
				obj.CanCollide = false
			end
		end

		humanoid = rig:FindFirstChildOfClass("Humanoid")
	end

	if not rig then
		rig = Instance.new("Model", worldModel)
		rig.Name = "Fallback"
		local t = Instance.new("Part", rig)
		t.Size = Vector3.new(2, 2, 1)
		t.Anchored = true
		t.Color = Color3.fromRGB(128, 128, 128)
		t.CFrame = CFrame.new(0, 0, -8)
		local h = Instance.new("Part", rig)
		h.Size = Vector3.new(2, 1, 1)
		h.Anchored = true
		h.Color = Color3.fromRGB(128, 128, 128)
		h.CFrame = CFrame.new(0, 1.5, -8)
		Instance.new("SpecialMesh", h).Scale = Vector3.new(1.25, 1.25, 1.25)
		Instance.new("Decal", h).Texture = "rbxasset://textures/face.png"
		humanoid = Instance.new("Humanoid", rig)
		humanoid.RigType = Enum.HumanoidRigType.R6
		Instance.new("Animator", humanoid)
	end

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://180435571"
	local track = humanoid:LoadAnimation(anim)
	if track then
		track.Looped = true
		track:Play()
	end

	local cam = Instance.new("Camera", vp)
	vp.CurrentCamera = cam

	local angle, pitch, radius = 0, -0.3, 6
	local rotSpeed = 0.3
	local dragging, dragStart, startAngle, startPitch = false, nil, 0, 0

	local function cam_update()
		local cp = math.clamp(pitch, -1.4, 1.4)
		local x = math.sin(angle) * math.cos(cp) * radius
		local y = math.sin(cp) * radius
		local z = math.cos(angle) * math.cos(cp) * radius - 8
		cam.CFrame = CFrame.new(Vector3.new(x, y, z), Vector3.new(0, 0, -8))
	end

	cam_update()

	self:AddConnection(game:GetService("RunService").Heartbeat:Connect(function(dt)
		if not dragging then angle = angle + rotSpeed * dt end
		cam_update()
	end))

	vp.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			self._vpDragging = true
			dragging = true
			dragStart = input.Position
			startAngle = angle
			startPitch = pitch
		end
	end)

	self:AddConnection(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			self._vpDragging = false
			dragging = false
		end
	end))

	self:AddConnection(UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			angle = startAngle - delta.X * 0.01
			pitch = startPitch + delta.Y * 0.01
			cam_update()
		end
	end))

	return rig
end

return Library
