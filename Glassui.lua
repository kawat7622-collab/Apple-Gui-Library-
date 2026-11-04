local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer

local GlassUI = {
	Version = "1.0.0",
	Windows = {},
}

local Theme = {
	Tint = Color3.fromRGB(18, 22, 30),
	Glass = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextSoft = Color3.fromRGB(240, 244, 250),
	Secondary = Color3.fromRGB(222, 228, 238),
	Tertiary = Color3.fromRGB(200, 208, 220),
	Red = Color3.fromRGB(255, 59, 48),
	Green = Color3.fromRGB(52, 199, 89),
	Shadow = Color3.fromRGB(20, 26, 38),
	LightRed = Color3.fromRGB(255, 95, 87),
	LightYellow = Color3.fromRGB(254, 188, 46),
	LightGreen = Color3.fromRGB(40, 200, 64),

	Panel = 0.94,
	PanelHover = 0.9,
	Primary = 0.82,
	PrimaryHover = 0.72,
	Rim = 0.4,

	WindowRadius = 26,
	CardRadius = 18,

	Font = Enum.Font.BuilderSans,
	FontMedium = Enum.Font.BuilderSansMedium,
	FontBold = Enum.Font.BuilderSansBold,
}
GlassUI.Theme = Theme

local QUINT = Enum.EasingStyle.Quint
local QUAD = Enum.EasingStyle.Quad
local BACK = Enum.EasingStyle.Back
local OUT = Enum.EasingDirection.Out
local IN = Enum.EasingDirection.In
local INOUT = Enum.EasingDirection.InOut

local TITLEBAR_HEIGHT = 44
local NAV_TOP = 74
local NAV_ITEM_HEIGHT = 32
local NAV_ITEM_GAP = 2
local ICON_BUTTON_SIZE = 34
local MINI_SIZE = 56

local function create(className, props)
	local obj = Instance.new(className)
	for key, value in pairs(props) do
		if key ~= "Parent" then
			obj[key] = value
		end
	end
	obj.Parent = props.Parent
	return obj
end

local function tween(obj, props, t, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t or 0.2, style or QUINT, dir or OUT), props)
	tw:Play()
	return tw
end

local function corner(radius, parent)
	return create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or Theme.Text, Thickness = thickness or 1, Transparency = transparency or Theme.Rim,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent,
	})
end

local function rimLight(strokeObj)
	return create("UIGradient", {
		Rotation = 35,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.45, 0.75),
			NumberSequenceKeypoint.new(0.75, 0.85),
			NumberSequenceKeypoint.new(1, 0.35),
		}),
		Parent = strokeObj,
	})
end

local function sheen(obj)
	if obj:IsA("CanvasGroup") then
		local frame = create("Frame", {
			Name = "Sheen", BackgroundColor3 = Theme.Glass, BackgroundTransparency = 0.94, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0.55, 0), ZIndex = 0, Active = false, Parent = obj,
		})
		create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Parent = frame,
		})
		return
	end
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.35) }),
		Parent = obj,
	})
end

local function innerEdge(obj, radius)
	local edge = create("Frame", {
		Name = "InnerEdge", BackgroundTransparency = 1, Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2), ZIndex = obj.ZIndex, Active = false, Parent = obj,
	})
	corner(math.max(radius - 1, 0), edge)
	local s = stroke(edge, Theme.Text, 1, 0.8)
	create("UIGradient", {
		Rotation = 215,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.35, 0.9),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = s,
	})
	return edge
end

local function glass(obj, transparency, radius, rimTransparency)
	obj.BackgroundColor3 = Theme.Glass
	obj.BackgroundTransparency = transparency or Theme.Panel
	obj.BorderSizePixel = 0
	if radius then
		corner(radius, obj)
		if radius >= 12 then
			innerEdge(obj, radius)
		end
	end
	sheen(obj)
	local s = stroke(obj, Theme.Text, 1, rimTransparency or Theme.Rim)
	rimLight(s)
	return s
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function trackDrag(onMove, onEnd)
	local moveConn, endConn
	moveConn = UserInputService.InputChanged:Connect(function(input)
		if isMove(input) then
			onMove(input)
		end
	end)
	endConn = UserInputService.InputEnded:Connect(function(input)
		if isPress(input) then
			moveConn:Disconnect()
			endConn:Disconnect()
			if onEnd then
				onEnd()
			end
		end
	end)
end

local function offsetBy(pos, delta)
	return UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y)
end

local function swapText(label, text)
	if label.Text == text then return end
	local fadeOut = tween(label, { TextTransparency = 1 }, 0.1, QUAD, IN)
	fadeOut.Completed:Connect(function(state)
		if state ~= Enum.PlaybackState.Completed then return end
		label.Text = text
		tween(label, { TextTransparency = 0 }, 0.18, QUAD, OUT)
	end)
end

local function addPressScale(button, pressed)
	local scale = create("UIScale", { Parent = button })
	button.MouseButton1Down:Connect(function()
		tween(scale, { Scale = pressed or 0.97 }, 0.1, QUAD, OUT)
	end)
	button.MouseButton1Up:Connect(function()
		tween(scale, { Scale = 1 }, 0.35, BACK, OUT)
	end)
	button.MouseLeave:Connect(function()
		tween(scale, { Scale = 1 }, 0.3, QUINT, OUT)
	end)
	return scale
end

local function makeChevron(parent, rotation, position)
	local chevron = create("Frame", {
		Name = "Chevron", AnchorPoint = Vector2.new(0.5, 0.5), Position = position,
		Size = UDim2.new(0, 16, 0, 16), BackgroundTransparency = 1, Rotation = rotation, Parent = parent,
	})
	for _, side in ipairs({ -1, 1 }) do
		local bar = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, side * 3, 0.5, 0),
			Size = UDim2.new(0, 9, 0, 2), Rotation = side * -40, BackgroundColor3 = Theme.Text,
			BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = chevron,
		})
		corner(1, bar)
	end
	return chevron
end

local function canUseFiles()
	return typeof(writefile) == "function" and typeof(readfile) == "function"
end

local function readJSON(path)
	if not canUseFiles() then return nil end
	local ok, raw = pcall(readfile, path)
	if not ok or type(raw) ~= "string" or raw == "" then return nil end
	local decoded, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if decoded and type(data) == "table" then
		return data
	end
	return nil
end

local function writeJSON(folder, path, data)
	if not canUseFiles() then return end
	if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
		local current = ""
		for part in string.gmatch(folder, "[^/]+") do
			current = current == "" and part or (current .. "/" .. part)
			pcall(function()
				if not isfolder(current) then
					makefolder(current)
				end
			end)
		end
	end
	pcall(function()
		writefile(path, HttpService:JSONEncode(data))
	end)
end

local function toAsset(id)
	if type(id) == "number" then
		return "rbxassetid://" .. tostring(id)
	end
	if type(id) == "string" and id ~= "" then
		if string.match(id, "^%d+$") then
			return "rbxassetid://" .. id
		end
		return id
	end
	return nil
end

local function resolveImage(imageObj, assetId)
	task.spawn(function()
		local loaded = false
		pcall(function()
			ContentProvider:PreloadAsync({ imageObj }, function(_, status)
				if status == Enum.AssetFetchStatus.Success then
					loaded = true
				end
			end)
		end)
		if loaded then return end
		local ok, objects = pcall(function()
			return game:GetObjects(assetId)
		end)
		if ok and objects and objects[1] then
			local obj = objects[1]
			if obj:IsA("Decal") or obj:IsA("Texture") then
				imageObj.Image = obj.Texture
			elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				imageObj.Image = obj.Image
			end
		end
	end)
end

local function toKeyCode(value)
	if typeof(value) == "EnumItem" then
		return value
	end
	if type(value) == "string" and value ~= "" and value ~= "None" then
		local ok, key = pcall(function()
			return Enum.KeyCode[value]
		end)
		if ok then
			return key
		end
	end
	return nil
end

local function getGuiParent()
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then
			return hui
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Elements = {}

function Window:_connect(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(self.Connections, conn)
	return conn
end

function Window:_saved(flag)
	if flag == nil then return nil end
	return self.SavedData[flag]
end

function Window:_queueSave()
	if not self.ConfigPath or self.SavePending then return end
	self.SavePending = true
	task.delay(0.3, function()
		self.SavePending = false
		local payload = {}
		for key, value in pairs(self.SavedData) do
			payload[key] = value
		end
		for key, value in pairs(self.Flags) do
			payload[key] = value
		end
		payload.__ToggleKey = self.ToggleKey and self.ToggleKey.Name or "K"
		payload.__Transparency = self.Transparency
		payload.__Notifications = self.NotificationsEnabled
		self.SavedData = payload
		writeJSON(self.ConfigFolder, self.ConfigPath, payload)
	end)
end

function Window:_setFlag(flag, value)
	if flag == nil then return end
	self.Flags[flag] = value
	if value == nil then
		self.SavedData[flag] = nil
	end
	self:_queueSave()
end

function Window:_logo(parent, size, textSize)
	if self.Logo then
		local image = create("ImageLabel", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = size, Image = self.LogoLabel and self.LogoLabel.Image or self.Logo, ImageColor3 = Theme.Text,
			ScaleType = Enum.ScaleType.Fit, ZIndex = parent.ZIndex + 1, Parent = parent,
		})
		if self.LogoLabel then
			self.LogoLabel:GetPropertyChangedSignal("Image"):Connect(function()
				image.Image = self.LogoLabel.Image
			end)
		end
		return image
	end
	return create("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Theme.FontBold,
		Text = string.upper(string.sub(self.Title, 1, 1)), TextColor3 = Theme.Text, TextSize = textSize or 18,
		ZIndex = parent.ZIndex + 1, Parent = parent,
	})
end

local function buildBase(W)
	W.Gui = create("ScreenGui", {
		Name = "GlassUI_" .. W.Title, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true, DisplayOrder = 100, Parent = getGuiParent(),
	})

	W.Main = create("CanvasGroup", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = W.Size, BackgroundColor3 = Theme.Tint, BackgroundTransparency = W.Transparency,
		BorderSizePixel = 0, ClipsDescendants = true, Parent = W.Gui,
	})
	corner(Theme.WindowRadius, W.Main)
	sheen(W.Main)
	rimLight(stroke(W.Main, Theme.Text, 1.5, 0.2))
	innerEdge(W.Main, Theme.WindowRadius)
	W.Scale = create("UIScale", { Parent = W.Main })

	W.SidebarBg = create("Frame", {
		Name = "Sidebar", Size = UDim2.new(0, W.SidebarWidth, 1, 0), BackgroundColor3 = Theme.Glass,
		BackgroundTransparency = 0.97, BorderSizePixel = 0, ZIndex = 1, Parent = W.Main,
	})
	create("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 16), Size = UDim2.new(0, 1, 1, -32),
		BackgroundColor3 = Theme.Text, BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = W.SidebarBg,
	})

	W.Content = create("Frame", {
		Name = "Content", Position = UDim2.new(0, W.SidebarWidth, 0, TITLEBAR_HEIGHT),
		Size = UDim2.new(1, -W.SidebarWidth, 1, -TITLEBAR_HEIGHT), BackgroundTransparency = 1,
		ClipsDescendants = true, ZIndex = 1, Parent = W.Main,
	})

	local function softShadow(obj)
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			obj.TextStrokeColor3 = Theme.Shadow
			obj.TextStrokeTransparency = 0.8
		end
	end
	W:_connect(W.Gui.DescendantAdded, softShadow)
end

local function buildToasts(W)
	local TOAST_WIDTH = 320
	local TOAST_HEIGHT = 66
	local TOAST_GAP = 10
	local TOAST_MAX = 4

	local holder = create("Frame", {
		Name = "Notifications", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 64),
		Size = UDim2.new(0, TOAST_WIDTH, 1, -80), BackgroundTransparency = 1, ZIndex = 50, Parent = W.Gui,
	})
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 0), Parent = holder,
	})

	local order = 0
	local active = {}

	local function dismiss(entry)
		if entry.closing then return end
		entry.closing = true
		if entry.conn then
			entry.conn:Disconnect()
		end
		local index = table.find(active, entry)
		if index then
			table.remove(active, index)
		end
		tween(entry.toast, { Position = UDim2.new(0, 40, 0, 0), GroupTransparency = 1 }, 0.3, QUINT, IN)
		tween(entry.overlay, { Position = UDim2.new(0, 40, 0, 0) }, 0.3, QUINT, IN)
		tween(entry.closeBtn, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.15, QUAD, OUT)
		tween(entry.closeStroke, { Transparency = 1 }, 0.15, QUAD, OUT)
		task.delay(0.2, function()
			local collapse = tween(entry.slot, { Size = UDim2.new(1, 0, 0, 0) }, 0.32, QUINT, INOUT)
			collapse.Completed:Connect(function()
				entry.slot:Destroy()
			end)
		end)
	end

	function W:_toast(title, content, duration)
		if #active >= TOAST_MAX then
			dismiss(active[1])
		end
		order = order + 1

		local slot = create("Frame", {
			Name = "Toast", LayoutOrder = -order, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			ZIndex = 50, Parent = holder,
		})
		local toast = create("CanvasGroup", {
			Position = UDim2.new(0, 40, 0, 0), Size = UDim2.new(1, 0, 0, TOAST_HEIGHT), GroupTransparency = 1,
			ZIndex = 50, Parent = slot,
		})
		glass(toast, 0.72, 22, 0.2)
		toast.BackgroundColor3 = Theme.Tint

		local iconTile = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.new(0, 40, 0, 40),
			ZIndex = 51, Parent = toast,
		})
		glass(iconTile, 0.88, 20, 0.3)
		self:_logo(iconTile, UDim2.new(0, 28, 0, 12), 18)

		create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 64, 0, 13), Size = UDim2.new(1, -120, 0, 18),
			Font = Theme.FontBold, Text = title, TextColor3 = Theme.Text, TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 51, Parent = toast,
		})
		create("TextLabel", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14),
			Size = UDim2.new(0, 40, 0, 16), Font = Theme.Font, Text = "now", TextColor3 = Theme.Secondary,
			TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 51, Parent = toast,
		})
		create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 64, 0, 33), Size = UDim2.new(1, -78, 0, 18),
			Font = Theme.Font, Text = content, TextColor3 = Theme.TextSoft, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 51, Parent = toast,
		})
		local hitArea = create("TextButton", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false,
			ZIndex = 53, Parent = toast,
		})
		local overlay = create("Frame", {
			Position = toast.Position, Size = toast.Size, BackgroundTransparency = 1, ZIndex = 54, Parent = slot,
		})
		local closeBtn = create("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 4, 0, 4), Size = UDim2.new(0, 20, 0, 20),
			BackgroundColor3 = Theme.Tint, BackgroundTransparency = 1, AutoButtonColor = false, Font = Theme.FontBold,
			Text = "×", TextColor3 = Theme.TextSoft, TextTransparency = 1, TextSize = 14, ZIndex = 55, Parent = overlay,
		})
		corner(10, closeBtn)
		local closeStroke = stroke(closeBtn, Theme.Text, 1, 1)

		local entry = {
			slot = slot, toast = toast, overlay = overlay, closeBtn = closeBtn, closeStroke = closeStroke, closing = false,
		}
		table.insert(active, entry)

		tween(slot, { Size = UDim2.new(1, 0, 0, TOAST_HEIGHT + TOAST_GAP) }, 0.4, QUINT, OUT)
		tween(toast, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }, 0.5, QUINT, OUT)
		tween(overlay, { Position = UDim2.new(0, 0, 0, 0) }, 0.5, QUINT, OUT)

		local hoverToast, hoverClose = false, false
		local function refreshHover()
			if entry.closing then return end
			local show = hoverToast or hoverClose
			tween(closeBtn, { BackgroundTransparency = show and 0 or 1, TextTransparency = show and 0 or 1 }, 0.18, QUINT, OUT)
			tween(closeStroke, { Transparency = show and 0.3 or 1 }, 0.18, QUINT, OUT)
			tween(toast, { BackgroundTransparency = show and 0.64 or 0.72 }, 0.2, QUINT, OUT)
		end
		hitArea.MouseEnter:Connect(function()
			hoverToast = true
			refreshHover()
		end)
		hitArea.MouseLeave:Connect(function()
			hoverToast = false
			refreshHover()
		end)
		closeBtn.MouseEnter:Connect(function()
			hoverClose = true
			refreshHover()
		end)
		closeBtn.MouseLeave:Connect(function()
			hoverClose = false
			refreshHover()
		end)
		hitArea.MouseButton1Click:Connect(function()
			dismiss(entry)
		end)
		closeBtn.MouseButton1Click:Connect(function()
			dismiss(entry)
		end)

		local elapsed = 0
		entry.conn = self:_connect(RunService.Heartbeat, function(dt)
			if hoverToast or hoverClose then return end
			elapsed = elapsed + dt
			if elapsed >= duration then
				dismiss(entry)
			end
		end)
	end
end

local function buildTitleBar(W)
	local titleBar = create("Frame", {
		Name = "TitleBar", Size = UDim2.new(1, 0, 0, TITLEBAR_HEIGHT), BackgroundTransparency = 1,
		ZIndex = 10, Parent = W.Main,
	})

	local titleCenter = create("Frame", {
		BackgroundTransparency = 1, Position = UDim2.new(0, W.SidebarWidth, 0, 0),
		Size = UDim2.new(1, -W.SidebarWidth, 1, 0), ZIndex = 10, Parent = titleBar,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = titleCenter,
	})
	if W.Logo then
		W.LogoLabel = create("ImageLabel", {
			Name = "Logo", LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.new(0, 30, 0, 13),
			Image = W.Logo, ImageColor3 = Theme.Text, ScaleType = Enum.ScaleType.Fit, ZIndex = 10, Parent = titleCenter,
		})
		resolveImage(W.LogoLabel, W.Logo)
	end
	W.TitleLabel = create("TextLabel", {
		LayoutOrder = 2, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 18), Font = Theme.FontMedium, Text = W.Title, TextColor3 = Theme.TextSoft,
		TextSize = 15, ZIndex = 10, Parent = titleCenter,
	})

	local lights = create("Frame", {
		Name = "TrafficLights", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.new(0, 52, 0, 12), BackgroundTransparency = 1, ZIndex = 11, Parent = titleBar,
	})
	local glyphs = {}

	local function makeLight(index, color, glyph)
		local light = create("TextButton", {
			Position = UDim2.new(0, (index - 1) * 20, 0, 0), Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = color,
			BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 11, Parent = lights,
		})
		corner(6, light)
		stroke(light, Color3.fromRGB(0, 0, 0), 1, 0.82)

		local glyphColor = color:Lerp(Color3.fromRGB(0, 0, 0), 0.62)
		local bars = {}
		if glyph == "close" then
			bars = { { center = true, w = 7, h = 1.5, r = 45 }, { center = true, w = 7, h = 1.5, r = -45 } }
		elseif glyph == "minimize" then
			bars = { { x = 3, y = 5, w = 6, h = 2 } }
		else
			bars = { { x = 3, y = 5, w = 6, h = 2 }, { x = 5, y = 3, w = 2, h = 6 } }
		end
		for _, bar in ipairs(bars) do
			local b = create("Frame", {
				Size = UDim2.new(0, bar.w, 0, bar.h), BackgroundColor3 = glyphColor, BackgroundTransparency = 1,
				BorderSizePixel = 0, ZIndex = 12, Parent = light,
			})
			if bar.center then
				b.AnchorPoint = Vector2.new(0.5, 0.5)
				b.Position = UDim2.new(0.5, 0, 0.5, 0)
				b.Rotation = bar.r
			else
				b.Position = UDim2.new(0, bar.x, 0, bar.y)
			end
			corner(1, b)
			table.insert(glyphs, b)
		end

		local pressedColor = color:Lerp(Color3.fromRGB(0, 0, 0), 0.25)
		light.MouseButton1Down:Connect(function()
			tween(light, { BackgroundColor3 = pressedColor }, 0.08, QUAD, OUT)
		end)
		light.MouseButton1Up:Connect(function()
			tween(light, { BackgroundColor3 = color }, 0.2, QUAD, OUT)
		end)
		light.MouseLeave:Connect(function()
			tween(light, { BackgroundColor3 = color }, 0.2, QUAD, OUT)
		end)
		return light
	end

	local closeLight = makeLight(1, Theme.LightRed, "close")
	local minimizeLight = makeLight(2, Theme.LightYellow, "minimize")
	local zoomLight = makeLight(3, Theme.LightGreen, "zoom")

	lights.MouseEnter:Connect(function()
		for _, g in ipairs(glyphs) do
			tween(g, { BackgroundTransparency = 0.15 }, 0.15, QUAD, OUT)
		end
	end)
	lights.MouseLeave:Connect(function()
		for _, g in ipairs(glyphs) do
			tween(g, { BackgroundTransparency = 1 }, 0.2, QUAD, OUT)
		end
	end)

	closeLight.MouseButton1Click:Connect(function()
		W:Hide()
		if W.CloseHints < 2 and W.NotificationsEnabled then
			W.CloseHints = W.CloseHints + 1
			W:Notify({ Title = W.Title, Content = "Menu closed – press " .. W.ToggleKey.Name .. " to open", Duration = 3.5 })
		end
	end)
	minimizeLight.MouseButton1Click:Connect(function()
		task.spawn(function()
			W:Minimize()
		end)
	end)
	zoomLight.MouseButton1Click:Connect(function()
		tween(W.Main, { Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.5, QUINT, OUT)
	end)

	local function makeDraggable(handle)
		handle.InputBegan:Connect(function(input)
			if not isPress(input) then return end
			local dragStart = input.Position
			local startPos = W.Main.Position
			trackDrag(function(moveInput)
				W.Main.Position = offsetBy(startPos, moveInput.Position - dragStart)
			end)
		end)
	end
	makeDraggable(titleBar)
	makeDraggable(W.SidebarBg)
end

local function buildSidebar(W)
	create("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 50), Size = UDim2.new(0, W.SidebarWidth - 30, 0, 16),
		Font = Theme.FontBold, Text = W.Options.SidebarHeader or "General", TextColor3 = Theme.Tertiary, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = W.Main,
	})

	local pillLayer = create("Frame", {
		Name = "PillLayer", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, NAV_TOP),
		Size = UDim2.new(0, W.SidebarWidth, 1, -NAV_TOP), ZIndex = 2, Active = false, Parent = W.Main,
	})
	W.Pill = create("CanvasGroup", {
		Name = "SelectionPill", Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 0, NAV_ITEM_HEIGHT),
		GroupTransparency = 1, ZIndex = 2, Parent = pillLayer,
	})
	glass(W.Pill, 0.87, NAV_ITEM_HEIGHT / 2, 0.3)

	W.Nav = create("ScrollingFrame", {
		Name = "Tabs", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, NAV_TOP),
		Size = UDim2.new(0, W.SidebarWidth, 1, -(NAV_TOP + ICON_BUTTON_SIZE + 24)), ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = W.Main,
	})
	create("UIListLayout", { Padding = UDim.new(0, NAV_ITEM_GAP), SortOrder = Enum.SortOrder.LayoutOrder, Parent = W.Nav })
	create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = W.Nav })
	W:_connect(W.Nav:GetPropertyChangedSignal("CanvasPosition"), function()
		pillLayer.Position = UDim2.new(0, 0, 0, NAV_TOP - W.Nav.CanvasPosition.Y)
	end)

	local bottom = create("Frame", {
		Name = "BottomBar", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -14),
		Size = UDim2.new(0, ICON_BUTTON_SIZE * 2 + 8, 0, ICON_BUTTON_SIZE), ZIndex = 3, Parent = W.Main,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center, Parent = bottom,
	})

	local function makeIconButton(order, isActive)
		local btn = create("TextButton", {
			LayoutOrder = order, Size = UDim2.new(0, ICON_BUTTON_SIZE, 0, ICON_BUTTON_SIZE), AutoButtonColor = false,
			Text = "", ZIndex = 3, Parent = bottom,
		})
		glass(btn, 0.88, ICON_BUTTON_SIZE / 2, 0.3)
		local function rest()
			return (isActive and isActive()) and 0.7 or 0.88
		end
		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundTransparency = math.min(0.78, rest()) }, 0.18, QUINT, OUT)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundTransparency = rest() }, 0.28, QUINT, OUT)
		end)
		addPressScale(btn, 0.9)
		return btn
	end

	if W.Options.Settings ~= false then
		W.GearButton = makeIconButton(1, function()
			return W.CurrentTab ~= nil and W.CurrentTab == W.SettingsTab
		end)
		W.GearButton.Name = "SettingsButton"
		local gear = create("Frame", {
			Name = "Gear", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1, ZIndex = 4, Parent = W.GearButton,
		})
		local ring = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 10, 0, 10),
			BackgroundTransparency = 1, ZIndex = 4, Parent = gear,
		})
		corner(5, ring)
		create("UIStroke", { Color = Theme.Text, Thickness = 2.5, Parent = ring })
		for i = 0, 7 do
			local angle = math.rad(i * 45)
			local tooth = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, math.cos(angle) * 7.5, 0.5, math.sin(angle) * 7.5),
				Size = UDim2.new(0, 4, 0, 4), Rotation = i * 45, BackgroundColor3 = Theme.Text, BorderSizePixel = 0,
				ZIndex = 4, Parent = gear,
			})
			corner(1, tooth)
		end
		W.GearButton.MouseEnter:Connect(function()
			tween(gear, { Rotation = 45 }, 0.45, QUINT, OUT)
		end)
		W.GearButton.MouseLeave:Connect(function()
			tween(gear, { Rotation = 0 }, 0.45, QUINT, OUT)
		end)
		W.GearButton.MouseButton1Click:Connect(function()
			if W.SettingsTab then
				W:SelectTab(W.SettingsTab)
			end
		end)
	end

	if W.Options.Discord then
		local discordBtn = makeIconButton(2)
		discordBtn.Name = "DiscordButton"
		local icon = toAsset(W.Options.DiscordIcon)
		if icon then
			local image = create("ImageLabel", {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 30, 0, 30), Image = icon, ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = discordBtn,
			})
			resolveImage(image, icon)
		else
			create("TextLabel", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Theme.FontBold, Text = "#",
				TextColor3 = Theme.Text, TextSize = 16, ZIndex = 4, Parent = discordBtn,
			})
		end
		discordBtn.MouseButton1Click:Connect(function()
			local clip = setclipboard or toclipboard
			local ok = clip and pcall(clip, W.Options.Discord)
			if ok then
				W:Notify({ Title = "Discord", Content = "Invite link copied to clipboard", Duration = 3 })
			else
				W:Notify({ Title = "Discord", Content = W.Options.Discord, Duration = 6, Force = true })
			end
		end)
	end
end

local function buildMini(W)
	local mini = create("CanvasGroup", {
		Name = "MinimizedIcon", Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE), Visible = false, Parent = W.Gui,
	})
	glass(mini, 0.72, 18, 0.2)
	mini.BackgroundColor3 = Theme.Tint
	local scale = create("UIScale", { Parent = mini })
	local button = create("TextButton", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), AutoButtonColor = false, Text = "", ZIndex = 2, Parent = mini,
	})
	W:_logo(button, UDim2.new(0, 40, 0, 17), 22)
	W.Mini = mini
	W.MiniScale = scale

	local hovering = false
	button.MouseEnter:Connect(function()
		hovering = true
		if not W.Animating then
			tween(scale, { Scale = 1.08 }, 0.3, QUINT, OUT)
		end
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		if not W.Animating then
			tween(scale, { Scale = 1 }, 0.3, QUINT, OUT)
		end
	end)

	button.InputBegan:Connect(function(input)
		if not isPress(input) or W.Animating then return end
		local startPos = input.Position
		local startMini = mini.Position
		local moved = false
		tween(scale, { Scale = 0.94 }, 0.12, QUAD, OUT)
		trackDrag(function(moveInput)
			local delta = moveInput.Position - startPos
			if not moved and Vector2.new(delta.X, delta.Y).Magnitude > 4 then
				moved = true
				tween(scale, { Scale = 1.05 }, 0.2, QUINT, OUT)
			end
			if moved then
				mini.Position = offsetBy(startMini, delta)
			end
		end, function()
			if moved then
				tween(scale, { Scale = hovering and 1.08 or 1 }, 0.4, BACK, OUT)
			else
				task.spawn(function()
					W:Restore()
				end)
			end
		end)
	end)
end

local function buildToggleKey(W)
	W:_connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed or W.Animating or W.ListeningForKey then return end
		if W.ToggleKey and input.KeyCode == W.ToggleKey then
			if W.Minimized then
				W:_setMiniVisible(W.Mini.GroupTransparency > 0.5 or not W.Mini.Visible)
			else
				W:Toggle()
			end
		end
	end)
end

local function newTab(W, name, hidden)
	local tab = setmetatable({}, Tab)
	tab.Window = W
	tab.Name = name
	tab.Order = 0
	tab.Hidden = hidden

	tab.Page = create("CanvasGroup", {
		Name = name, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0,
		ClipsDescendants = true, Visible = false, Parent = W.Content,
	})
	tab.Container = create("ScrollingFrame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Secondary, ScrollBarImageTransparency = 0.5,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = tab.Page,
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 22),
		PaddingBottom = UDim.new(0, 18), Parent = tab.Container,
	})
	create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tab.Container })
	tab.TitleLabel = create("TextLabel", {
		LayoutOrder = 0, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Font = Theme.FontBold, Text = name,
		TextColor3 = Theme.Text, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Left, Parent = tab.Container,
	})

	if not hidden then
		table.insert(W.TabList, tab)
		local button = create("TextButton", {
			Name = name, LayoutOrder = #W.TabList, Size = UDim2.new(1, 0, 0, NAV_ITEM_HEIGHT),
			BackgroundColor3 = Theme.Glass, BackgroundTransparency = 1, AutoButtonColor = false, Text = "",
			ZIndex = 3, Parent = W.Nav,
		})
		corner(NAV_ITEM_HEIGHT / 2, button)
		tab.NavButton = button
		tab.NavLabel = create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -20, 1, 0),
			Font = Theme.FontMedium, Text = name, TextColor3 = Theme.TextSoft, TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4, Parent = button,
		})
		button.MouseEnter:Connect(function()
			if W.CurrentTab ~= tab then
				tween(button, { BackgroundTransparency = 0.94 }, 0.18, QUINT, OUT)
			end
		end)
		button.MouseLeave:Connect(function()
			tween(button, { BackgroundTransparency = 1 }, 0.28, QUINT, OUT)
		end)
		addPressScale(button)
		button.MouseButton1Click:Connect(function()
			W:SelectTab(tab)
		end)
	end

	W.Tabs[name] = tab
	if not hidden and W.CurrentTab == nil then
		W:SelectTab(tab, true)
	end
	return tab
end

local function buildSettings(W)
	local tab = newTab(W, "Settings", true)
	W.SettingsTab = tab
	W.Settings = tab

	tab:CreateSection("Interface")
	tab:CreateKeybind({
		Title = "Toggle Menu",
		Description = "Key that opens and closes the menu",
		Default = W.ToggleKey,
		AllowNone = false,
		Blacklist = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.Slash },
		ChangedCallback = function(key)
			if key then
				W.ToggleKey = key
				W:_queueSave()
			end
		end,
	})
	tab:CreateSlider({
		Title = "Menu Transparency",
		Description = "How see-through the window is",
		Min = 0,
		Max = 95,
		Increment = 1,
		Suffix = "%",
		Default = math.floor(W.Transparency * 100 + 0.5),
		Callback = function(value)
			W:SetTransparency(value / 100)
		end,
	})
	tab:CreateToggle({
		Title = "Notifications",
		Description = "Show notifications from this script",
		Default = W.NotificationsEnabled,
		Callback = function(on)
			W.NotificationsEnabled = on
			W:_queueSave()
		end,
	})
end

function GlassUI:CreateWindow(options)
	options = options or {}
	local W = setmetatable({}, Window)
	W.Options = options
	W.Title = options.Title or "GlassUI"
	W.Logo = toAsset(options.Logo)
	W.Size = options.Size or UDim2.new(0, 580, 0, 390)
	W.SidebarWidth = options.SidebarWidth or 170
	W.Flags = {}
	W.Tabs = {}
	W.TabList = {}
	W.Connections = {}
	W.Shown = true
	W.Minimized = false
	W.Animating = false
	W.ListeningForKey = false
	W.VisibilityToken = 0
	W.CloseHints = 0
	W.ToggleKey = toKeyCode(options.ToggleKey) or Enum.KeyCode.K
	W.Transparency = math.clamp(options.Transparency or 0.8, 0, 0.95)
	W.NotificationsEnabled = options.Notifications ~= false
	W.SavedData = {}

	if options.ConfigName then
		W.ConfigFolder = "GlassUI/" .. tostring(options.ConfigName)
		W.ConfigPath = W.ConfigFolder .. "/" .. tostring(LocalPlayer.UserId) .. ".json"
		W.SavedData = readJSON(W.ConfigPath) or {}
		local data = W.SavedData
		W.ToggleKey = toKeyCode(data.__ToggleKey) or W.ToggleKey
		if type(data.__Transparency) == "number" then
			W.Transparency = math.clamp(data.__Transparency, 0, 0.95)
		end
		if type(data.__Notifications) == "boolean" then
			W.NotificationsEnabled = data.__Notifications
		end
	end

	buildBase(W)
	buildToasts(W)
	buildTitleBar(W)
	buildSidebar(W)
	buildMini(W)
	buildToggleKey(W)
	if options.Settings ~= false then
		buildSettings(W)
	end

	W.Scale.Scale = 0.95
	W.Main.GroupTransparency = 1
	tween(W.Scale, { Scale = 1 }, 0.5, QUINT, OUT)
	tween(W.Main, { GroupTransparency = 0 }, 0.35, QUAD, OUT)

	table.insert(GlassUI.Windows, W)
	return W
end

function Window:CreateTab(name)
	return newTab(self, name or ("Tab " .. tostring(#self.TabList + 1)), false)
end
Window.AddTab = Window.CreateTab

function Window:SelectTab(target, instant)
	local tab = type(target) == "string" and self.Tabs[target] or target
	if tab == nil or tab == self.CurrentTab then return end
	local old = self.CurrentTab
	self.CurrentTab = tab

	for _, t in ipairs(self.TabList) do
		local color = t == tab and Theme.Text or Theme.TextSoft
		if instant then
			t.NavLabel.TextColor3 = color
		else
			tween(t.NavLabel, { TextColor3 = color }, 0.25, QUINT, OUT)
		end
		if t == tab then
			tween(t.NavButton, { BackgroundTransparency = 1 }, 0.2, QUINT, OUT)
		end
	end

	local index = table.find(self.TabList, tab)
	if index then
		local pos = UDim2.new(0, 10, 0, (index - 1) * (NAV_ITEM_HEIGHT + NAV_ITEM_GAP))
		if instant or self.Pill.GroupTransparency > 0.5 then
			self.Pill.Position = pos
			if instant then
				self.Pill.GroupTransparency = 0
			else
				tween(self.Pill, { GroupTransparency = 0 }, 0.25, QUAD, OUT)
			end
		else
			tween(self.Pill, { Position = pos }, 0.42, QUINT, OUT)
		end
	else
		tween(self.Pill, { GroupTransparency = 1 }, 0.2, QUAD, OUT)
	end

	if self.GearButton then
		tween(self.GearButton, { BackgroundTransparency = tab == self.SettingsTab and 0.7 or 0.88 }, 0.28, QUINT, OUT)
	end

	if old then
		local fade = tween(old.Page, { GroupTransparency = 1, Position = UDim2.new(0, -10, 0, 0) }, 0.18, QUINT, OUT)
		fade.Completed:Connect(function()
			if self.CurrentTab ~= old then
				old.Page.Visible = false
				old.Page.Position = UDim2.new(0, 0, 0, 0)
				old.Page.GroupTransparency = 0
			end
		end)
	end

	if instant then
		tab.Page.Visible = true
		tab.Page.Position = UDim2.new(0, 0, 0, 0)
		tab.Page.GroupTransparency = 0
	else
		if not tab.Page.Visible then
			tab.Page.Position = UDim2.new(0, 12, 0, 0)
			tab.Page.GroupTransparency = 1
			tab.Page.Visible = true
		end
		tween(tab.Page, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.35, QUINT, OUT)
	end
end

function Window:Notify(a, b, c)
	local opts = type(a) == "table" and a or { Title = a, Content = b, Duration = c }
	if not self.NotificationsEnabled and not opts.Force then return end
	self:_toast(tostring(opts.Title or self.Title), tostring(opts.Content or ""), opts.Duration or 3)
end

function Window:Show()
	if self.Minimized then
		task.spawn(function()
			self:Restore()
		end)
		return
	end
	self.VisibilityToken = self.VisibilityToken + 1
	self.Shown = true
	if not self.Main.Visible then
		self.Scale.Scale = 0.95
		self.Main.GroupTransparency = 1
		self.Main.Visible = true
	end
	tween(self.Scale, { Scale = 1 }, 0.45, QUINT, OUT)
	tween(self.Main, { GroupTransparency = 0 }, 0.3, QUAD, OUT)
end

function Window:Hide()
	self.VisibilityToken = self.VisibilityToken + 1
	local token = self.VisibilityToken
	self.Shown = false
	tween(self.Scale, { Scale = 0.95 }, 0.22, QUINT, IN)
	local fade = tween(self.Main, { GroupTransparency = 1 }, 0.22, QUAD, IN)
	fade.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and token == self.VisibilityToken then
			self.Main.Visible = false
		end
	end)
end

function Window:Toggle()
	if self.Shown then
		self:Hide()
	else
		self:Show()
	end
end

function Window:Minimize()
	if self.Minimized or self.Animating or not self.Shown then return end
	self.Minimized = true
	self.Animating = true

	local halfW, halfH = self.Size.X.Offset / 2, self.Size.Y.Offset / 2
	local p = self.Main.Position
	local left, top = p.X.Offset - halfW, p.Y.Offset - halfH
	self.Mini.Position = UDim2.new(p.X.Scale, left, p.Y.Scale, top)
	local miniCenter = UDim2.new(p.X.Scale, left + MINI_SIZE / 2, p.Y.Scale, top + MINI_SIZE / 2)

	tween(self.Scale, { Scale = MINI_SIZE / self.Size.X.Offset }, 0.42, QUINT, INOUT)
	tween(self.Main, { Position = miniCenter }, 0.42, QUINT, INOUT)
	local fade = tween(self.Main, { GroupTransparency = 1 }, 0.36, QUAD, IN)

	task.delay(0.22, function()
		self.Mini.GroupTransparency = 1
		self.MiniScale.Scale = 0.55
		self.Mini.Visible = true
		tween(self.Mini, { GroupTransparency = 0 }, 0.25, QUAD, OUT)
		tween(self.MiniScale, { Scale = 1 }, 0.5, BACK, OUT)
	end)

	fade.Completed:Wait()
	self.Main.Visible = false
	self.Shown = false
	task.wait(0.3)
	self.Animating = false
end

function Window:Restore()
	if not self.Minimized or self.Animating then return end
	self.Minimized = false
	self.Animating = true
	self.VisibilityToken = self.VisibilityToken + 1

	local halfW, halfH = self.Size.X.Offset / 2, self.Size.Y.Offset / 2
	local p = self.Mini.Position
	local target = UDim2.new(p.X.Scale, p.X.Offset + halfW, p.Y.Scale, p.Y.Offset + halfH)
	local fromCenter = UDim2.new(p.X.Scale, p.X.Offset + MINI_SIZE / 2, p.Y.Scale, p.Y.Offset + MINI_SIZE / 2)

	tween(self.MiniScale, { Scale = 0.6 }, 0.2, QUINT, IN)
	local miniFade = tween(self.Mini, { GroupTransparency = 1 }, 0.18, QUAD, IN)
	miniFade.Completed:Connect(function()
		if not self.Minimized then
			self.Mini.Visible = false
			self.MiniScale.Scale = 1
		end
	end)

	self.Main.Position = fromCenter
	self.Scale.Scale = MINI_SIZE / self.Size.X.Offset
	self.Main.GroupTransparency = 1
	self.Main.Visible = true
	self.Shown = true

	tween(self.Scale, { Scale = 1 }, 0.5, QUINT, OUT)
	tween(self.Main, { Position = target }, 0.5, QUINT, OUT)
	local grow = tween(self.Main, { GroupTransparency = 0 }, 0.3, QUAD, OUT)
	grow.Completed:Wait()
	task.wait(0.2)
	self.Animating = false
end

function Window:_setMiniVisible(visible)
	self.MiniToken = (self.MiniToken or 0) + 1
	local token = self.MiniToken
	if visible then
		if not self.Mini.Visible then
			self.Mini.GroupTransparency = 1
			self.MiniScale.Scale = 0.6
			self.Mini.Visible = true
		end
		tween(self.Mini, { GroupTransparency = 0 }, 0.25, QUAD, OUT)
		tween(self.MiniScale, { Scale = 1 }, 0.45, BACK, OUT)
	else
		tween(self.MiniScale, { Scale = 0.6 }, 0.2, QUINT, IN)
		local fade = tween(self.Mini, { GroupTransparency = 1 }, 0.2, QUAD, IN)
		fade.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and token == self.MiniToken then
				self.Mini.Visible = false
			end
		end)
	end
end

function Window:SetTransparency(value)
	self.Transparency = math.clamp(value, 0, 0.95)
	self.Main.BackgroundTransparency = self.Transparency
	self:_queueSave()
end

function Window:SetToggleKey(key)
	local keyCode = toKeyCode(key)
	if keyCode then
		self.ToggleKey = keyCode
		self:_queueSave()
	end
end

function Window:SetTitle(title)
	self.Title = title
	self.TitleLabel.Text = title
end

function Window:Destroy()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
	self.Gui:Destroy()
	local index = table.find(GlassUI.Windows, self)
	if index then
		table.remove(GlassUI.Windows, index)
	end
end

function GlassUI:Notify(a, b, c)
	local window = self.Windows[#self.Windows]
	if window then
		window:Notify(a, b, c)
	end
end

function Tab:_order()
	self.Order = self.Order + 1
	return self.Order
end

function Tab:Select()
	self.Window:SelectTab(self)
end

function Tab:SetTitle(title)
	self.Name = title
	self.TitleLabel.Text = title
	if self.NavLabel then
		self.NavLabel.Text = title
	end
end

local function hasText(value)
	return value ~= nil and value ~= ""
end

local function baseCard(tab, height, clickable, baseT, hoverT)
	baseT = baseT or Theme.Panel
	hoverT = hoverT or Theme.PanelHover
	local card = create(clickable and "TextButton" or "Frame", {
		LayoutOrder = tab:_order(), Size = UDim2.new(1, 0, 0, height), Parent = tab.Container,
	})
	if clickable then
		card.AutoButtonColor = false
		card.Text = ""
	end
	glass(card, baseT, Theme.CardRadius)
	card.MouseEnter:Connect(function()
		tween(card, { BackgroundTransparency = hoverT }, 0.25, QUINT, OUT)
	end)
	card.MouseLeave:Connect(function()
		tween(card, { BackgroundTransparency = baseT }, 0.35, QUINT, OUT)
	end)
	return card
end

local function cardText(card, title, description, rightInset, areaHeight)
	local width = UDim2.new(1, -(18 + rightInset), 0, 18)
	if hasText(description) then
		local titleLabel = create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, math.floor(areaHeight / 2) - 19), Size = width,
			Font = Theme.FontMedium, Text = title, TextColor3 = Theme.Text, TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
		})
		local descLabel = create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, math.floor(areaHeight / 2)),
			Size = UDim2.new(1, -(18 + rightInset), 0, 16), Font = Theme.Font, Text = description,
			TextColor3 = Theme.Secondary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
		})
		return titleLabel, descLabel
	end
	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(1, -(18 + rightInset), 0, areaHeight),
		Font = Theme.FontMedium, Text = title, TextColor3 = Theme.Text, TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
	})
	return titleLabel, nil
end

local function textApi(obj, titleLabel, descLabel)
	function obj:SetTitle(text)
		titleLabel.Text = text
	end
	function obj:SetDescription(text)
		if descLabel then
			descLabel.Text = text
		end
	end
end

function Elements.Section(tab, opt)
	local text = type(opt) == "table" and (opt.Title or opt.Text) or tostring(opt or "Section")
	local label = create("TextLabel", {
		LayoutOrder = tab:_order(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Font = Theme.FontBold,
		Text = text, TextColor3 = Theme.Secondary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom, Parent = tab.Container,
	})
	create("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = label })
	local obj = { Instance = label }
	function obj:Set(value)
		label.Text = value
	end
	return obj
end

function Elements.Label(tab, opt)
	if type(opt) ~= "table" then
		opt = { Text = tostring(opt or "") }
	end
	local label = create("TextLabel", {
		LayoutOrder = tab:_order(), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), Font = Theme.Font, Text = opt.Text or "", TextColor3 = opt.Color or Theme.Secondary,
		TextSize = opt.TextSize or 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = tab.Container,
	})
	create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = label })
	local obj = { Instance = label }
	function obj:Set(value)
		label.Text = value
	end
	return obj
end

function Elements.Paragraph(tab, opt)
	opt = opt or {}
	local card = create("Frame", {
		LayoutOrder = tab:_order(), AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = tab.Container,
	})
	glass(card, Theme.Panel, Theme.CardRadius)
	local inner = create("Frame", {
		BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card,
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18), Parent = inner,
	})
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })
	local titleLabel = create("TextLabel", {
		LayoutOrder = 1, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
		Font = Theme.FontBold, Text = opt.Title or "", TextColor3 = Theme.Text, TextSize = 15, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, Visible = hasText(opt.Title), Parent = inner,
	})
	local contentLabel = create("TextLabel", {
		LayoutOrder = 2, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
		Font = Theme.Font, Text = opt.Content or "", TextColor3 = Theme.Secondary, TextSize = 14, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = inner,
	})
	local obj = { Instance = card }
	function obj:SetTitle(text)
		titleLabel.Text = text
		titleLabel.Visible = hasText(text)
	end
	function obj:SetContent(text)
		contentLabel.Text = text
	end
	function obj:Set(value)
		if type(value) == "table" then
			if value.Title ~= nil then
				obj:SetTitle(value.Title)
			end
			if value.Content ~= nil then
				obj:SetContent(value.Content)
			end
		else
			obj:SetContent(tostring(value))
		end
	end
	return obj
end

function Elements.Button(tab, opt)
	opt = opt or {}
	local style = string.lower(opt.Style or "default")
	local baseT, hoverT = Theme.Panel, Theme.PanelHover
	if style == "primary" then
		baseT, hoverT = Theme.Primary, Theme.PrimaryHover
	elseif style == "destructive" then
		baseT, hoverT = 0.55, 0.4
	end
	local height = hasText(opt.Description) and 60 or 46
	local card = baseCard(tab, height, true, baseT, hoverT)
	if style == "destructive" then
		card.BackgroundColor3 = Theme.Red
	end
	local titleLabel, descLabel = cardText(card, opt.Title or "Button", opt.Description, 44, height)
	if style == "destructive" then
		titleLabel.Font = Theme.FontBold
	end
	makeChevron(card, -90, UDim2.new(1, -24, 0.5, 0))
	addPressScale(card, 0.98)

	local obj = { Instance = card }
	textApi(obj, titleLabel, descLabel)
	function obj:Fire()
		if opt.Callback then
			task.spawn(opt.Callback)
		end
	end
	card.MouseButton1Click:Connect(function()
		obj:Fire()
	end)
	return obj
end

function Elements.Toggle(tab, opt)
	opt = opt or {}
	local W = tab.Window
	local value = opt.Default == true
	local saved = W:_saved(opt.Flag)
	local fromSave = type(saved) == "boolean"
	if fromSave then
		value = saved
	end

	local height = hasText(opt.Description) and 60 or 46
	local card = baseCard(tab, height, true)
	local titleLabel, descLabel = cardText(card, opt.Title or "Toggle", opt.Description, 80, height)

	local track = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 46, 0, 28), Parent = card,
	})
	glass(track, 0.86, 14, 0.35)
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = Theme.Text,
		BorderSizePixel = 0, ZIndex = 3, Parent = track,
	})
	corner(12, knob)

	local function render(instant)
		local pos = value and UDim2.new(0, 20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		local color = value and Theme.Green or Theme.Glass
		local t = value and 0.15 or 0.86
		if instant then
			knob.Position = pos
			track.BackgroundColor3 = color
			track.BackgroundTransparency = t
		else
			tween(knob, { Position = pos }, 0.3, BACK, OUT)
			tween(track, { BackgroundColor3 = color, BackgroundTransparency = t }, 0.25, QUINT, OUT)
		end
	end

	local obj = { Instance = card }
	textApi(obj, titleLabel, descLabel)
	function obj:Set(newValue, silent)
		value = newValue and true or false
		render(false)
		W:_setFlag(opt.Flag, value)
		if not silent and opt.Callback then
			task.spawn(opt.Callback, value)
		end
	end
	function obj:Get()
		return value
	end

	card.MouseButton1Down:Connect(function()
		tween(knob, { Size = UDim2.new(0, 28, 0, 24) }, 0.12, QUAD, OUT)
	end)
	card.MouseButton1Up:Connect(function()
		tween(knob, { Size = UDim2.new(0, 24, 0, 24) }, 0.25, QUINT, OUT)
	end)
	card.MouseLeave:Connect(function()
		tween(knob, { Size = UDim2.new(0, 24, 0, 24) }, 0.25, QUINT, OUT)
	end)
	card.MouseButton1Click:Connect(function()
		obj:Set(not value)
	end)

	render(true)
	if opt.Flag then
		W.Flags[opt.Flag] = value
	end
	if fromSave and opt.Callback then
		task.spawn(opt.Callback, value)
	end
	return obj
end

function Elements.Slider(tab, opt)
	opt = opt or {}
	local W = tab.Window
	local min = opt.Min or 0
	local max = opt.Max or 100
	if max <= min then
		max = min + 1
	end
	local increment = opt.Increment or 1
	local suffix = opt.Suffix or ""
	local decimals = 0
	local incText = tostring(increment)
	local dot = string.find(incText, ".", 1, true)
	if dot then
		decimals = math.min(#incText - dot, 3)
	end

	local function snap(v)
		v = math.clamp(v, min, max)
		v = min + math.floor((v - min) / increment + 0.5) * increment
		v = math.clamp(v, min, max)
		local m = 10 ^ decimals
		return math.floor(v * m + 0.5) / m
	end
	local function format(v)
		return string.format("%." .. decimals .. "f", v) .. suffix
	end
	local function alphaOf(v)
		return (v - min) / (max - min)
	end

	local value = snap(opt.Default or min)
	local saved = W:_saved(opt.Flag)
	local fromSave = type(saved) == "number"
	if fromSave then
		value = snap(saved)
	end

	local hasDesc = hasText(opt.Description)
	local top = hasDesc and 60 or 46
	local card = baseCard(tab, top + 22, false)
	local titleLabel, descLabel = cardText(card, opt.Title or "Slider", opt.Description, 100, top)

	local valueLabel = create("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0, math.floor(top / 2)),
		Size = UDim2.new(0, 90, 0, 18), Font = Theme.FontBold, Text = format(value), TextColor3 = Theme.Text,
		TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right, Parent = card,
	})
	local hit = create("TextButton", {
		BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Position = UDim2.new(0, 18, 0, top - 6),
		Size = UDim2.new(1, -36, 0, 22), Parent = card,
	})
	local track = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6), Parent = hit,
	})
	glass(track, 0.82, 3, 0.45)
	local fill = create("Frame", {
		BackgroundColor3 = Theme.Text, BackgroundTransparency = 0.25, BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0), Parent = track,
	})
	corner(3, fill)
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 3, Parent = hit,
	})
	corner(9, knob)
	stroke(knob, Color3.fromRGB(0, 0, 0), 1, 0.85)

	local currentAlpha = alphaOf(value)
	local targetAlpha = currentAlpha
	local dragging = false
	local followConn = nil

	local function draw(alpha)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
	end

	local function follow()
		if followConn then return end
		followConn = RunService.RenderStepped:Connect(function(dt)
			local diff = targetAlpha - currentAlpha
			if math.abs(diff) < 0.001 then
				currentAlpha = targetAlpha
				draw(currentAlpha)
				if not dragging and followConn then
					followConn:Disconnect()
					followConn = nil
				end
				return
			end
			currentAlpha = currentAlpha + diff * math.min(1, dt * 22)
			draw(currentAlpha)
		end)
	end

	local function commit(v, silent)
		targetAlpha = alphaOf(v)
		follow()
		if v == value then return end
		value = v
		valueLabel.Text = format(v)
		W:_setFlag(opt.Flag, v)
		if not silent and opt.Callback then
			task.spawn(opt.Callback, v)
		end
	end

	local function alphaFromX(x)
		local left = hit.AbsolutePosition.X
		local width = math.max(hit.AbsoluteSize.X, 1)
		return math.clamp((x - left) / width, 0, 1)
	end

	hit.InputBegan:Connect(function(input)
		if not isPress(input) then return end
		dragging = true
		commit(snap(min + alphaFromX(input.Position.X) * (max - min)))
		tween(knob, { Size = UDim2.new(0, 22, 0, 22) }, 0.15, QUINT, OUT)
		trackDrag(function(moveInput)
			commit(snap(min + alphaFromX(moveInput.Position.X) * (max - min)))
		end, function()
			dragging = false
			follow()
			tween(knob, { Size = UDim2.new(0, 18, 0, 18) }, 0.3, BACK, OUT)
		end)
	end)

	local obj = { Instance = card }
	textApi(obj, titleLabel, descLabel)
	function obj:Set(v, silent)
		commit(snap(tonumber(v) or min), silent)
	end
	function obj:Get()
		return value
	end

	draw(currentAlpha)
	if opt.Flag then
		W.Flags[opt.Flag] = value
	end
	if fromSave and opt.Callback then
		task.spawn(opt.Callback, value)
	end
	return obj
end

function Elements.Input(tab, opt)
	opt = opt or {}
	local W = tab.Window
	local value = tostring(opt.Default or "")
	local saved = W:_saved(opt.Flag)
	local fromSave = type(saved) == "string"
	if fromSave then
		value = saved
	end

	local boxWidth = opt.Width or 170
	local height = hasText(opt.Description) and 60 or 46
	local card = baseCard(tab, height, false)
	local titleLabel, descLabel = cardText(card, opt.Title or "Input", opt.Description, boxWidth + 30, height)

	local box = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, boxWidth, 0, 30),
		ClearTextOnFocus = opt.ClearOnFocus == true, Font = Theme.Font, PlaceholderText = opt.Placeholder or "Type here…",
		PlaceholderColor3 = Theme.Tertiary, Text = value, TextColor3 = Theme.Text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true,
		Parent = card,
	})
	local boxStroke = glass(box, 0.88, 15, 0.35)
	create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = box })

	box.Focused:Connect(function()
		tween(box, { BackgroundTransparency = 0.8 }, 0.18, QUINT, OUT)
		tween(boxStroke, { Transparency = 0.15 }, 0.18, QUINT, OUT)
	end)

	if opt.Numeric then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local filtered = string.gsub(box.Text, "[^%d%.%-]", "")
			if filtered ~= box.Text then
				box.Text = filtered
			end
		end)
	end

	local obj = { Instance = card }
	textApi(obj, titleLabel, descLabel)

	box.FocusLost:Connect(function(enterPressed)
		tween(box, { BackgroundTransparency = 0.88 }, 0.25, QUINT, OUT)
		tween(boxStroke, { Transparency = 0.35 }, 0.25, QUINT, OUT)
		value = box.Text
		W:_setFlag(opt.Flag, value)
		if opt.Callback then
			task.spawn(opt.Callback, value, enterPressed)
		end
	end)

	function obj:Set(text, silent)
		value = tostring(text or "")
		box.Text = value
		W:_setFlag(opt.Flag, value)
		if not silent and opt.Callback then
			task.spawn(opt.Callback, value, false)
		end
	end
	function obj:Get()
		return value
	end

	if opt.Flag then
		W.Flags[opt.Flag] = value
	end
	if fromSave and opt.Callback then
		task.spawn(opt.Callback, value, false)
	end
	return obj
end

function Elements.Keybind(tab, opt)
	opt = opt or {}
	local W = tab.Window
	local key = toKeyCode(opt.Default)
	local saved = W:_saved(opt.Flag)
	local fromSave = type(saved) == "string"
	if fromSave then
		key = toKeyCode(saved)
	end

	local blacklist = { [Enum.KeyCode.Unknown] = true }
	for _, k in ipairs(opt.Blacklist or {}) do
		blacklist[k] = true
	end

	local height = hasText(opt.Description) and 60 or 46
	local card = baseCard(tab, height, false)
	local titleLabel, descLabel = cardText(card, opt.Title or "Keybind", opt.Description, 130, height)

	local function keyName()
		return key and key.Name or "None"
	end

	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 104, 0, 30),
		AutoButtonColor = false, Font = Theme.FontMedium, Text = keyName(), TextColor3 = Theme.Text, TextSize = 14,
		Parent = card,
	})
	glass(button, Theme.Primary, 15, 0.3)
	button.MouseEnter:Connect(function()
		tween(button, { BackgroundTransparency = Theme.PrimaryHover }, 0.18, QUINT, OUT)
	end)
	button.MouseLeave:Connect(function()
		tween(button, { BackgroundTransparency = Theme.Primary }, 0.28, QUINT, OUT)
	end)
	addPressScale(button, 0.95)

	local obj = { Instance = card }
	textApi(obj, titleLabel, descLabel)

	local listening = false
	local listenConn = nil

	local function stopListening()
		listening = false
		task.defer(function()
			W.ListeningForKey = false
		end)
		if listenConn then
			listenConn:Disconnect()
			listenConn = nil
		end
		swapText(button, keyName())
	end

	function obj:Set(newKey, silent)
		key = toKeyCode(newKey)
		swapText(button, keyName())
		W:_setFlag(opt.Flag, keyName())
		if not silent and opt.ChangedCallback then
			task.spawn(opt.ChangedCallback, key)
		end
	end
	function obj:Get()
		return key
	end

	button.MouseButton1Click:Connect(function()
		if listening then
			stopListening()
			return
		end
		listening = true
		W.ListeningForKey = true
		swapText(button, "Press a key…")
		listenConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			if input.KeyCode == Enum.KeyCode.Escape then
				stopListening()
				return
			end
			if input.KeyCode == Enum.KeyCode.Backspace and opt.AllowNone ~= false then
				key = nil
				stopListening()
				W:_setFlag(opt.Flag, "None")
				if opt.ChangedCallback then
					task.spawn(opt.ChangedCallback, nil)
				end
				return
			end
			if blacklist[input.KeyCode] then
				swapText(button, "Not allowed")
				return
			end
			key = input.KeyCode
			stopListening()
			W:_setFlag(opt.Flag, keyName())
			if opt.ChangedCallback then
				task.spawn(opt.ChangedCallback, key)
			end
		end)
	end)

	W:_connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed or W.ListeningForKey or key == nil then return end
		if input.KeyCode == key and opt.Callback then
			task.spawn(opt.Callback)
		end
	end)

	if opt.Flag then
		W.Flags[opt.Flag] = keyName()
	end
	if fromSave and opt.ChangedCallback then
		task.spawn(opt.ChangedCallback, key)
	end
	return obj
end

function Elements.Dropdown(tab, opt)
	opt = opt or {}
	local W = tab.Window
	local multi = opt.Multi == true
	local options = opt.Options or {}
	local ROW = 34
	local MAX_ROWS = opt.MaxVisible or 6

	local value
	if multi then
		value = {}
		for _, v in ipairs(type(opt.Default) == "table" and opt.Default or {}) do
			table.insert(value, v)
		end
	else
		value = opt.Default
	end
	local saved = W:_saved(opt.Flag)
	local fromSave = false
	if multi and type(saved) == "table" then
		value = {}
		for _, v in ipairs(saved) do
			table.insert(value, v)
		end
		fromSave = true
	elseif not multi and type(saved) == "string" then
		value = saved
		fromSave = true
	end

	local top = hasText(opt.Description) and 60 or 46
	local card = baseCard(tab, top, false)
	card.ClipsDescendants = true

	local header = create("TextButton", {
		BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, top), Parent = card,
	})
	local titleLabel, descLabel = cardText(header, opt.Title or "Dropdown", opt.Description, 200, top)
	local summary = create("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -46, 0, math.floor(top / 2)),
		Size = UDim2.new(0, 150, 0, 18), Font = Theme.Font, TextColor3 = Theme.Secondary, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
	})
	local chevron = makeChevron(header, 0, UDim2.new(1, -26, 0, math.floor(top / 2)))
	local separator = create("Frame", {
		Position = UDim2.new(0, 18, 0, top - 1), Size = UDim2.new(1, -36, 0, 1), BackgroundColor3 = Theme.Text,
		BackgroundTransparency = 1, BorderSizePixel = 0, Parent = card,
	})
	local list = create("ScrollingFrame", {
		Position = UDim2.new(0, 8, 0, top + 6), Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Secondary,
		ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, Parent = card,
	})
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local rows = {}
	local open = false
	local obj = { Instance = card }
	textApi(obj, titleLabel, descLabel)

	local function isSelected(option)
		if multi then
			return table.find(value, option) ~= nil
		end
		return value == option
	end

	local function summaryText()
		if multi then
			if #value == 0 then
				return "None"
			elseif #value <= 2 then
				local names = {}
				for _, v in ipairs(value) do
					table.insert(names, tostring(v))
				end
				return table.concat(names, ", ")
			end
			return tostring(#value) .. " selected"
		end
		return value ~= nil and tostring(value) or "None"
	end

	local function refresh()
		for _, row in ipairs(rows) do
			local selected = isSelected(row.Option)
			tween(row.Dot, { BackgroundTransparency = selected and 0 or 1 }, 0.2, QUINT, OUT)
			tween(row.Button, { BackgroundTransparency = selected and 0.9 or 1 }, 0.2, QUINT, OUT)
			row.Label.TextColor3 = selected and Theme.Text or Theme.TextSoft
		end
		summary.Text = summaryText()
	end

	local function listHeight()
		return math.min(#options, MAX_ROWS) * (ROW + 2)
	end

	local function setOpen(state)
		open = state
		local h = listHeight()
		if state then
			list.Visible = true
		end
		list.Size = UDim2.new(1, -16, 0, h)
		local resize = tween(card, { Size = UDim2.new(1, 0, 0, state and (top + h + 14) or top) }, 0.4, QUINT, OUT)
		tween(chevron, { Rotation = state and 180 or 0 }, 0.4, QUINT, OUT)
		tween(separator, { BackgroundTransparency = state and 0.85 or 1 }, 0.25, QUAD, OUT)
		resize.Completed:Connect(function()
			if not open then
				list.Visible = false
			end
		end)
	end

	local function fire()
		if multi then
			local copy = {}
			for _, v in ipairs(value) do
				table.insert(copy, v)
			end
			W:_setFlag(opt.Flag, copy)
			if opt.Callback then
				task.spawn(opt.Callback, copy)
			end
		else
			W:_setFlag(opt.Flag, value)
			if opt.Callback then
				task.spawn(opt.Callback, value)
			end
		end
	end

	local function choose(option)
		if multi then
			local index = table.find(value, option)
			if index then
				table.remove(value, index)
			else
				table.insert(value, option)
			end
		else
			value = option
		end
		refresh()
		fire()
		if not multi and opt.CloseOnSelect ~= false then
			setOpen(false)
		end
	end

	local function buildRows()
		for _, row in ipairs(rows) do
			row.Button:Destroy()
		end
		rows = {}
		for i, option in ipairs(options) do
			local button = create("TextButton", {
				LayoutOrder = i, Size = UDim2.new(1, -4, 0, ROW), BackgroundColor3 = Theme.Glass,
				BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Parent = list,
			})
			corner(10, button)
			local label = create("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -44, 1, 0),
				Font = Theme.FontMedium, Text = tostring(option), TextColor3 = Theme.TextSoft, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = button,
			})
			local dot = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 8, 0, 8),
				BackgroundColor3 = Theme.Text, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = button,
			})
			corner(4, dot)
			button.MouseEnter:Connect(function()
				if not isSelected(option) then
					tween(button, { BackgroundTransparency = 0.94 }, 0.15, QUINT, OUT)
				end
			end)
			button.MouseLeave:Connect(function()
				tween(button, { BackgroundTransparency = isSelected(option) and 0.9 or 1 }, 0.25, QUINT, OUT)
			end)
			button.MouseButton1Click:Connect(function()
				choose(option)
			end)
			table.insert(rows, { Option = option, Button = button, Label = label, Dot = dot })
		end
		refresh()
	end

	header.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	function obj:Set(newValue, silent)
		if multi then
			value = {}
			for _, v in ipairs(type(newValue) == "table" and newValue or { newValue }) do
				table.insert(value, v)
			end
		else
			value = newValue
		end
		refresh()
		if silent then
			W:_setFlag(opt.Flag, value)
		else
			fire()
		end
	end
	function obj:Get()
		return value
	end
	function obj:SetOptions(newOptions)
		options = newOptions or {}
		if multi then
			local kept = {}
			for _, v in ipairs(value) do
				if table.find(options, v) then
					table.insert(kept, v)
				end
			end
			value = kept
		elseif value ~= nil and not table.find(options, value) then
			value = nil
		end
		W:_setFlag(opt.Flag, value)
		buildRows()
		if open then
			setOpen(true)
		end
	end
	obj.Refresh = obj.SetOptions

	buildRows()
	if opt.Flag then
		W.Flags[opt.Flag] = value
	end
	if fromSave and opt.Callback then
		task.spawn(opt.Callback, value)
	end
	return obj
end

for name, fn in pairs(Elements) do
	Tab["Create" .. name] = fn
	Tab["Add" .. name] = fn
end

return GlassUI
