local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local MPS = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")

local pgui = Players.LocalPlayer:WaitForChild("PlayerGui")
if pgui:FindFirstChild("AuraMenu") then pgui.AuraMenu:Destroy() end
if SoundService:FindFirstChild("AuraSound") then SoundService.AuraSound:Destroy() end

local WIN_W, WIN_H, TOP, SB = 400, 250, 34, 92
local EASE, DIR = Enum.EasingStyle, Enum.EasingDirection
local C = {
	bg = Color3.fromRGB(15, 15, 22), bar = Color3.fromRGB(21, 21, 30),
	card = Color3.fromRGB(27, 27, 39), card2 = Color3.fromRGB(40, 40, 57),
	text = Color3.fromRGB(236, 236, 246), sub = Color3.fromRGB(142, 142, 168),
	off = Color3.fromRGB(55, 55, 75), bad = Color3.fromRGB(255, 95, 105),
}
local accent = Color3.fromRGB(130, 100, 255)
local reg = {}
local rainbow, hue = false, 0

local function tw(o, p, t, st, dr)
	local tween = TS:Create(o, TweenInfo.new(t or .2, st or EASE.Quint, dr or DIR.Out), p)
	tween:Play()
	return tween
end

local lo = 0
local function new(class, props, parent)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
	for k, v in pairs(props) do o[k] = v end
	if parent then
		if o:IsA("GuiObject") and parent:FindFirstChildOfClass("UIListLayout") then lo += 1; o.LayoutOrder = lo end
		o.Parent = parent
	end
	return o
end

local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end

local function acc(o, prop, get)
	get = get or function() return accent end
	o[prop] = get()
	reg[#reg + 1] = function(instant)
		if instant then o[prop] = get() else tw(o, {[prop] = get()}, .35) end
	end
end

local function light(c) return c:Lerp(Color3.new(1, 1, 1), .65) end
local function dark(c) return c:Lerp(Color3.new(0, 0, 0), .8) end
local function loop(o, props, t)
	TS:Create(o, TweenInfo.new(t, EASE.Linear, DIR.InOut, -1), props):Play()
end

local function grad(parent, mk, props)
	local g = new("UIGradient", props or {}, parent)
	g.Color = mk()
	reg[#reg + 1] = function() g.Color = mk() end
	return g
end

local function lbl(parent, text, size, color, extra)
	local p = {BackgroundTransparency = 1, Text = text, TextSize = size or 13, TextColor3 = color or C.text,
		Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromScale(1, 1),
		TextTruncate = Enum.TextTruncate.AtEnd}
	for k, v in pairs(extra or {}) do p[k] = v end
	return new("TextLabel", p, parent)
end

local function press(b)
	local s = new("UIScale", {}, b)
	b.ClipsDescendants = true
	b.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		tw(s, {Scale = .93}, .1)
		local sz = b.AbsoluteSize
		if sz.X < 1 then return end

		local rp = new("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = .75, AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromScale((i.Position.X - b.AbsolutePosition.X) / sz.X, (i.Position.Y - b.AbsolutePosition.Y) / sz.Y),
			Size = UDim2.fromOffset(0, 0), ZIndex = 5}, b)
		round(rp, 100)
		tw(rp, {Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1}, .55).Completed:Connect(function() rp:Destroy() end)
	end)
	b.InputEnded:Connect(function(i) if isPress(i) then tw(s, {Scale = 1}, .3, EASE.Back) end end)
end

local gui = new("ScreenGui", {Name = "AuraMenu", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100}, pgui)

local blur = new("BlurEffect", {Size = 0}, Lighting)
local blurOn = true

local toastF
local function toast(text)
	if toastF then toastF:Destroy() end
	local f = new("Frame", {AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, -50), Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.bar}, gui)
	toastF = f
	round(f, 16)
	new("UIPadding", {PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)}, f)
	new("UIStroke", {Thickness = 1.5, Color = accent, Transparency = .3}, f)
	lbl(f, text, 13, nil, {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None})
	tw(f, {Position = UDim2.new(.5, 0, 0, 14)}, .5, EASE.Back)
	task.delay(2.2, function()
		if f.Parent then tw(f, {Position = UDim2.new(.5, 0, 0, -50)}, .4, EASE.Quad, DIR.In).Completed:Connect(function() f:Destroy() end) end
	end)
end

local function drag(handle, target, bounds)
	local st = {moved = false}
	local active, inp, origin, start
	handle.InputBegan:Connect(function(i)
		if isPress(i) then
			active, inp, origin, start, st.moved = true, i, i.Position, target.Position, false
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then active = false end end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if active and (i == inp or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - origin
			if d.Magnitude > 6 then st.moved = true end
			if not st.moved then return end
			local W, H = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
			local x0, x1, y0, y1 = bounds(W, H)
			local nx = math.clamp(start.X.Scale * W + start.X.Offset + d.X, x0, x1) - start.X.Scale * W
			local ny = math.clamp(start.Y.Scale * H + start.Y.Offset + d.Y, y0, y1) - start.Y.Scale * H
			tw(target, {Position = UDim2.new(start.X.Scale, nx, start.Y.Scale, ny)}, .06, EASE.Quad)
		end
	end)
	return st
end

local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(800, 400)
if vp.Y < 150 then vp = Vector2.new(800, 400) end
local baseScale = math.clamp((vp.Y - 40) / WIN_H, .6, 1)
local baseGT, opened, collapsed, openTok = 0, false, false, 0
local startPos = UDim2.new(.5, 0, 0, math.max(6, (vp.Y - WIN_H * baseScale) / 2))

local holder = new("Frame", {Size = UDim2.fromOffset(WIN_W, WIN_H), AnchorPoint = Vector2.new(.5, 0),
	Position = startPos, BackgroundTransparency = 1}, gui)
local main = new("CanvasGroup", {AnchorPoint = Vector2.new(.5, 0), Position = UDim2.fromScale(.5, 0),
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1, Visible = false}, holder)
round(main, 12)
local mscale = new("UIScale", {Scale = baseScale}, main)
local mstroke = new("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = .15}, main)

loop(grad(mstroke, function() return ColorSequence.new({ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(.5, dark(accent)), ColorSequenceKeypoint.new(1, accent)}) end), {Rotation = 360}, 5)

for _ = 1, 12 do
	local sz, d = math.random(3, 6), math.random(60, 110) / 10
	local pt = new("Frame", {BackgroundTransparency = .9, Size = UDim2.fromOffset(sz, sz), AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(math.random(), 1.05)}, main)
	round(pt, 3); acc(pt, "BackgroundColor3")
	TS:Create(pt, TweenInfo.new(d, EASE.Linear, DIR.Out, -1), {Position = UDim2.fromScale(math.random(), -.05)}):Play()
	TS:Create(pt, TweenInfo.new(d / 2, EASE.Sine, DIR.InOut, -1, true), {BackgroundTransparency = .55}):Play()
end

local top = new("Frame", {Size = UDim2.new(1, 0, 0, TOP), BackgroundColor3 = C.bar, BorderSizePixel = 0}, main)
local title = lbl(top, "AURA", 16, Color3.new(1, 1, 1), {Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(56, TOP), Font = Enum.Font.GothamBlack})
loop(grad(title, function() return ColorSequence.new({ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(.5, light(accent)), ColorSequenceKeypoint.new(1, accent)}) end,
	{Offset = Vector2.new(-.5, 0)}), {Offset = Vector2.new(.5, 0)}, 1.8)
lbl(top, "mobile menu", 11, C.sub, {Position = UDim2.fromOffset(70, 1), Size = UDim2.fromOffset(110, TOP)})
local line = new("Frame", {Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0}, top)
acc(line, "BackgroundColor3")
loop(new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .9), NumberSequenceKeypoint.new(.5, 0), NumberSequenceKeypoint.new(1, .9)}),
	Offset = Vector2.new(-1, 0)}, line), {Offset = Vector2.new(1, 0)}, 2.2)

local function topBtn(txt, n)
	local b = new("TextButton", {Text = txt, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.text,
		AutoButtonColor = false, BackgroundColor3 = C.card2, Size = UDim2.fromOffset(28, 22),
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8 - (n - 1) * 34, .5, -1)}, top)
	round(b, 6); press(b)
	return b
end
local closeB, colB = topBtn("×", 1), topBtn("–", 2)

drag(top, holder, function(W, H) return 40, W - 40, 0, H - 40 end)

local side = new("Frame", {Position = UDim2.fromOffset(6, TOP + 8), Size = UDim2.new(0, SB, 1, -TOP - 14), BackgroundTransparency = 1}, main)
local CPOS = UDim2.fromOffset(SB + 12, TOP + 8)
local content = new("CanvasGroup", {Position = CPOS, Size = UDim2.new(1, -SB - 18, 1, -TOP - 14), BackgroundTransparency = 1}, main)

local function setOpen(v)
	if opened == v then return end
	opened = v; openTok += 1
	local my = openTok
	if v then
		main.Visible = true
		tw(blur, {Size = blurOn and 14 or 0}, .5)
		mscale.Scale = baseScale * .86
		tw(main, {GroupTransparency = baseGT}, .28)
		tw(mscale, {Scale = baseScale}, .5, EASE.Back)
	else
		tw(main, {GroupTransparency = 1}, .2)
		tw(blur, {Size = 0}, .3)
		tw(mscale, {Scale = baseScale * .86}, .2, EASE.Quad, DIR.In)
		task.delay(.22, function() if openTok == my then main.Visible = false end end)
	end
end

local function setCollapsed(v)
	collapsed = v
	colB.Text = v and "+" or "–"
	tw(main, {Size = v and UDim2.new(1, 0, 0, TOP) or UDim2.fromScale(1, 1)}, .45, EASE.Quint)
end
closeB.Activated:Connect(function() setOpen(false) end)
colB.Activated:Connect(function() setCollapsed(not collapsed) end)

local fab = new("TextButton", {Text = "A", Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = Color3.new(1, 1, 1),
	AutoButtonColor = false, Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 14, .5, -23)}, gui)
round(fab, 23); acc(fab, "BackgroundColor3"); press(fab)
local fs = new("UIStroke", {Thickness = 2, Transparency = .5}, fab); acc(fs, "Color")
TS:Create(fs, TweenInfo.new(1.4, EASE.Sine, DIR.InOut, -1, true), {Thickness = 6, Transparency = .9}):Play()
local fabDrag = drag(fab, fab, function(W, H) return 0, W - 46, 0, H - 46 end)
fab.Activated:Connect(function()
	if fabDrag.moved then return end
	setOpen(not opened)
	tw(fab, {Rotation = fab.Rotation + 360}, .7, EASE.Back)
end)

local function card(p, h)
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.card, BorderSizePixel = 0}, p)
	round(f, 8)
	return f
end

local function section(p, text)
	return lbl(p, text, 11, C.sub, {Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.GothamBold})
end

local function row(p, h)
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1}, p)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, f)
	return f
end

local function button(p, text, cb, primary, size)
	local b = new("TextButton", {Text = text, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text,
		AutoButtonColor = false, BackgroundColor3 = C.card2, Size = size or UDim2.new(1, 0, 0, 32)}, p)
	round(b, 8); press(b)
	if primary then acc(b, "BackgroundColor3") end
	if cb then b.Activated:Connect(cb) end
	return b
end

local function toggle(p, text, def, cb)
	local f = card(p, 36)
	lbl(f, text, 13, nil, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -60, 1, 0)})
	local b = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, f)
	local on = def and true or false
	local sw = new("Frame", {AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(36, 20)}, f)
	round(sw, 10)
	acc(sw, "BackgroundColor3", function() return on and accent or C.off end)
	local knob = new("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, on and 19 or 3, .5, 0)}, sw)
	round(knob, 7)
	local obj = {}
	function obj.Set(v, silent)
		on = v
		tw(sw, {BackgroundColor3 = on and accent or C.off}, .2)
		tw(knob, {Position = UDim2.new(0, on and 19 or 3, .5, 0)}, .3, EASE.Back)
		if not silent and cb then cb(on) end
	end
	b.Activated:Connect(function() obj.Set(not on) end)
	return obj
end

local function slider(p, text, min, max, def, fmt, cb, step)
	local f = card(p, 50)
	lbl(f, text, 13, nil, {Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -90, 0, 20)})
	local val = lbl(f, "", 12, C.sub, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 5),
		Size = UDim2.fromOffset(76, 20), TextXAlignment = Enum.TextXAlignment.Right})
	local hit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 24)}, f)
	local track = new("Frame", {BackgroundColor3 = C.card2, AnchorPoint = Vector2.new(0, .5),
		Position = UDim2.new(0, 10, .5, 0), Size = UDim2.new(1, -20, 0, 6)}, hit)
	round(track, 3)
	local fill = new("Frame", {Size = UDim2.fromScale(0, 1)}, track); round(fill, 3); acc(fill, "BackgroundColor3")
	local knob = new("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(.5, .5),
		Size = UDim2.fromOffset(14, 14), Position = UDim2.fromScale(0, .5)}, track)
	round(knob, 7)
	local ks = new("UIStroke", {Thickness = 0, Transparency = .55}, knob); acc(ks, "Color")
	local obj = {Label = val, Dragging = false}
	local function set(v, silent, instant)
		v = math.clamp(v, min, max)
		if step then v = math.floor(v / step + .5) * step end
		local a = (v - min) / (max - min)
		if instant then
			fill.Size = UDim2.fromScale(a, 1); knob.Position = UDim2.fromScale(a, .5)
		else
			tw(fill, {Size = UDim2.fromScale(a, 1)}, .1, EASE.Linear)
			tw(knob, {Position = UDim2.fromScale(a, .5)}, .1, EASE.Linear)
		end
		val.Text = fmt and fmt(v) or tostring(v)
		if not silent and cb then cb(v) end
	end
	local function fromX(x)
		set(min + (max - min) * math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
	end
	hit.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		obj.Dragging = true
		local sf = f:FindFirstAncestorOfClass("ScrollingFrame")
		if sf then sf.ScrollingEnabled = false end
		fromX(i.Position.X)
		tw(knob, {Size = UDim2.fromOffset(19, 19)}, .15); tw(ks, {Thickness = 5}, .2)
		local conn = UIS.InputChanged:Connect(function(c)
			if c == i or c.UserInputType == Enum.UserInputType.MouseMovement then fromX(c.Position.X) end
		end)
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				conn:Disconnect(); obj.Dragging = false
				if sf then sf.ScrollingEnabled = true end
				tw(knob, {Size = UDim2.fromOffset(14, 14)}, .25, EASE.Back); tw(ks, {Thickness = 0}, .3)
			end
		end)
	end)
	obj.Set = set
	set(def, true, true)
	return obj
end

local function selector(p, text, opts)
	local f = card(p, 36)
	lbl(f, text, 13, nil, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(.5, -10, 1, 0)})
	local b = new("TextButton", {Text = opts[1], Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text,
		AutoButtonColor = false, BackgroundColor3 = C.card2, AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -8, .5, 0), Size = UDim2.new(.5, -14, 0, 24)}, f)
	round(b, 6); press(b)
	local n = 1
	b.Activated:Connect(function()
		n = n % #opts + 1
		b.Text = opts[n]; b.TextTransparency = 1
		tw(b, {TextTransparency = 0}, .25)
	end)
end

local pages, order = {}, {"Музыка", "Эффекты", "Визуал", "Разное", "Настройки"}
local function page(name)
	local p = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false}, content)
	new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, p)
	new("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, p)
	acc(p, "ScrollBarImageColor3")
	pages[name] = p
	return p
end

local sound = new("Sound", {Name = "AuraSound", Volume = 1}, SoundService)
local pitch = new("PitchShiftSoundEffect", {Octave = 1, Enabled = false}, sound)
local eq = new("EqualizerSoundEffect", {LowGain = 0, MidGain = 0, HighGain = 0}, sound)
local reverb = new("ReverbSoundEffect", {Enabled = false, DecayTime = 2.8, DryLevel = -2, WetLevel = -4}, sound)
local echo = new("EchoSoundEffect", {Enabled = false, Delay = .35, Feedback = .45, DryLevel = 0, WetLevel = -6}, sound)

local S = {speed = 1, semi = 0, tape = true, db = 0}
local function applyAudio()
	sound.PlaybackSpeed = S.speed

	local target = 2 ^ (S.semi / 12) * (S.tape and S.speed or 1)
	local oct = math.clamp(target / S.speed, .5, 2)
	pitch.Octave = oct
	pitch.Enabled = math.abs(oct - 1) > .001
	sound.Volume = math.min(10 ^ (S.db / 20), 10)
end

local statusL, histBox, box, play
local history, playTok = {}, 0
local function setStatus(t, col) statusL.Text = t; statusL.TextColor3 = col or C.sub end

local function addHistory(id)
	local i = table.find(history, id); if i then table.remove(history, i) end
	table.insert(history, 1, id); if #history > 3 then table.remove(history) end
	for _, c in ipairs(histBox:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for _, v in ipairs(history) do
		local b = new("TextButton", {Text = v, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.text,
			AutoButtonColor = false, BackgroundColor3 = C.card, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0)}, histBox)
		round(b, 6); press(b)
		new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, b)
		b.Activated:Connect(function() box.Text = v; play(v) end)
	end
	histBox.Visible = true
end

function play(raw)
	local id = tostring(raw or ""):gsub("%D", "")
	if id == "" then setStatus("Введите числовой ID", C.bad) return end
	playTok += 1
	local my = playTok
	sound:Stop()
	sound.SoundId = "rbxassetid://" .. id
	applyAudio()
	sound:Play()
	setStatus("Загрузка...")
	local t0 = os.clock()
	while my == playTok and not sound.IsLoaded and os.clock() - t0 < 8 do task.wait(.1) end
	if my ~= playTok then return end
	if sound.IsLoaded and sound.TimeLength > 0 then
		local ok, info = pcall(function() return MPS:GetProductInfo(tonumber(id)) end)
		if my ~= playTok then return end
		setStatus("Играет: " .. ((ok and info and info.Name) or id), C.text); toast("Трек загружен")
		addHistory(id)
	else
		sound:Stop()
		setStatus("Не загрузилось: ID закрыт или неверный", C.bad); toast("Не удалось загрузить ID")
	end
end

local pg = page("Музыка")
local spd, tapeT, semi, vol, bassS, midS, trebS, reverbT, echoT, prog, pauseB
local function resetAll()
	spd.Set(1); tapeT.Set(true); semi.Set(0); vol.Set(0)
	bassS.Set(0); midS.Set(0); trebS.Set(0); reverbT.Set(false); echoT.Set(false)
end
local function dbfmt(v) return string.format("%+.0f dB", v) end

section(pg, "ПЛЕЕР")
local idc = card(pg, 42)
box = new("TextBox", {PlaceholderText = "Вставьте ID песни", Text = "", ClearTextOnFocus = false, Font = Enum.Font.GothamMedium,
	TextSize = 13, TextColor3 = C.text, PlaceholderColor3 = C.sub, BackgroundColor3 = C.card2, TextXAlignment = Enum.TextXAlignment.Left,
	ClipsDescendants = true, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -94, 1, -12)}, idc)
round(box, 6); new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, box)
box.FocusLost:Connect(function(enter)
	box.Text = (box.Text:gsub("%D", ""))
	if enter then play(box.Text) end
end)
local go = button(idc, "Играть", function() play(box.Text) end, true, UDim2.new(0, 76, 1, -12))
go.Position = UDim2.new(1, -82, 0, 6)

statusL = lbl(pg, "Введите ID и нажмите «Играть»", 12, C.sub, {Size = UDim2.new(1, 0, 0, 16)})
histBox = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Visible = false}, pg)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5)}, histBox)

local vc = card(pg, 46)
local bars = {}
for n = 1, 28 do
	local b = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((n - 1) / 28, 2, 1, -5), Size = UDim2.new(1 / 28, -3, 0, 3)}, vc)
	round(b, 2); acc(b, "BackgroundColor3")
	bars[n] = {f = b, h = 0}
end
prog = slider(pg, "Трек", 0, 1, 0, function() return "" end, function(v)
	if sound.TimeLength > 0 then sound.TimePosition = v * sound.TimeLength end
end)
local r = row(pg, 32)
local q = UDim2.new(.25, -5, 1, 0)
button(r, "-10с", function() sound.TimePosition = math.max(0, sound.TimePosition - 10) end, false, q)
pauseB = button(r, "Пауза", function()
	if sound.IsPlaying then sound:Pause() elseif sound.IsPaused then sound:Resume() elseif sound.SoundId ~= "" then sound:Play() end
end, true, q)
button(r, "Стоп", function() playTok += 1; sound:Stop(); setStatus("Остановлено") end, false, q)
button(r, "+10с", function() sound.TimePosition = math.min(sound.TimeLength, sound.TimePosition + 10) end, false, q)
toggle(pg, "Повтор трека", false, function(v) sound.Looped = v end)

section(pg, "СКОРОСТЬ И ТОНАЛЬНОСТЬ")
spd = slider(pg, "Скорость", .25, 3, 1, function(v) return string.format("%.2fx", v) end, function(v) S.speed = v; applyAudio() end, .05)
tapeT = toggle(pg, "Менять тон со скоростью", true, function(v) S.tape = v; applyAudio() end)
semi = slider(pg, "Тональность", -12, 12, 0, function(v) return string.format("%+.0f пт", v) end, function(v) S.semi = v; applyAudio() end, 1)
section(pg, "ГРОМКОСТЬ")
vol = slider(pg, "Усиление", -40, 20, 0, dbfmt, function(v) S.db = v; applyAudio() end, 1)
button(pg, "Сбросить всё", resetAll)

local pe = page("Эффекты")
section(pe, "ПРЕСЕТЫ")
local pr = row(pe, 30)
button(pr, "Night", function() spd.Set(1.25); tapeT.Set(true); semi.Set(0); toast("Пресет: Night") end, false, q)
button(pr, "Slowed", function() spd.Set(.85); tapeT.Set(true); reverbT.Set(true); toast("Пресет: Slowed") end, false, q)
button(pr, "Bass", function() bassS.Set(10); toast("Пресет: Bass") end, false, q)
button(pr, "Сброс", function() resetAll(); toast("Всё сброшено") end, false, q)
section(pe, "ЭКВАЛАЙЗЕР")
bassS = slider(pe, "Низкие", -20, 10, 0, dbfmt, function(v) eq.LowGain = v end, 1)
midS = slider(pe, "Средние", -20, 10, 0, dbfmt, function(v) eq.MidGain = v end, 1)
trebS = slider(pe, "Высокие", -20, 10, 0, dbfmt, function(v) eq.HighGain = v end, 1)
section(pe, "ПРОСТРАНСТВО")
reverbT = toggle(pe, "Реверберация", false, function(v) reverb.Enabled = v end)
echoT = toggle(pe, "Эхо", false, function(v) echo.Enabled = v end)

local function dummy(name, items)
	local p = page(name)
	for _, it in ipairs(items) do
		local k = it[1]
		if k == "s" then section(p, it[2])
		elseif k == "t" then toggle(p, it[2], it[3])
		elseif k == "sl" then slider(p, it[2], it[3], it[4], it[5], function(v) return string.format("%.0f", v) end, nil, 1)
		elseif k == "sel" then selector(p, it[2], it[3])
		else button(p, it[2]) end
	end
end
dummy("Визуал", {{"s", "ОТОБРАЖЕНИЕ"}, {"t", "Подсветка игроков", true}, {"t", "Скелет"}, {"t", "Имена", true},
	{"t", "Дистанция"}, {"sl", "Дальность", 0, 500, 250}, {"sel", "Стиль", {"Контур", "Заливка", "Градиент"}}})
dummy("Разное", {{"s", "ОБЩЕЕ"}, {"t", "Анти-АФК", true}, {"t", "Показывать FPS"}, {"t", "Авто-перезаход"},
	{"sl", "Поле зрения", 50, 120, 70}, {"sel", "Язык", {"Русский", "English"}}, {"b", "Сохранить конфиг"}})

local hb
local ps = page("Настройки")
section(ps, "ЦВЕТ АКЦЕНТА")
local swc = card(ps, 42)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10)}, swc)
for _, col in ipairs({Color3.fromRGB(130, 100, 255), Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 85, 150),
	Color3.fromRGB(60, 220, 130), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 75, 85)}) do
	local b = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = col, Size = UDim2.fromOffset(26, 26)}, swc)
	round(b, 13); press(b)
	b.Activated:Connect(function() rainbow = false; accent = col; for _, f in ipairs(reg) do f() end; toast("Акцент изменён") end)
end
local rb = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromOffset(26, 26)}, swc)
round(rb, 13); press(rb)
new("UIGradient", {Rotation = 45, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(.33, Color3.fromRGB(80, 255, 120)), ColorSequenceKeypoint.new(.66, Color3.fromRGB(80, 140, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 200))})}, rb)
rb.Activated:Connect(function() rainbow = not rainbow; toast(rainbow and "Радужный режим" or "Радуга выключена") end)
section(ps, "ОКНО")
slider(ps, "Прозрачность", 0, 50, 0, function(v) return string.format("%.0f%%", v) end, function(v)
	baseGT = v / 100
	if opened then tw(main, {GroupTransparency = baseGT}, .2) end
end, 1)
slider(ps, "Размер меню", 60, 130, baseScale * 100, function(v) return string.format("%.0f%%", v) end, function(v)
	baseScale = v / 100
	tw(mscale, {Scale = baseScale}, .25)
end, 5)
toggle(ps, "Размытие фона", true, function(v)
	blurOn = v
	if opened then tw(blur, {Size = v and 14 or 0}, .3) end
end)
button(ps, "Сбросить позицию", function() tw(holder, {Position = startPos}, .6, EASE.Back) end)
button(ps, "Выгрузить меню", function() hb:Disconnect(); gui:Destroy(); sound:Destroy(); blur:Destroy() end)

local tabBtns, cur, tok = {}, nil, nil
local ind = new("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = .8}, side)
round(ind, 8); acc(ind, "BackgroundColor3")
local bar = new("Frame", {Size = UDim2.new(0, 3, .6, 0), AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 4, .5, 0)}, ind)
round(bar, 2); acc(bar, "BackgroundColor3")

local function popIn(name)
	local n = 0
	for _, c in ipairs(pages[name]:GetChildren()) do
		if c:IsA("GuiObject") then
			local sc = c:FindFirstChild("Pop")
			if not sc and c:FindFirstChildOfClass("UIScale") then continue end
			n += 1
			sc = sc or new("UIScale", {Name = "Pop"}, c)
			sc.Scale = .8
			task.delay(n * .035, function() tw(sc, {Scale = 1}, .45, EASE.Back) end)
		end
	end
end

local function selectTab(name, instant)
	if cur == name then return end
	cur = name
	local my = {}
	tok = my
	for n, b in pairs(tabBtns) do tw(b, {TextColor3 = n == name and C.text or C.sub}, .25) end
	tw(ind, {Position = UDim2.fromOffset(0, (table.find(order, name) - 1) * 36)}, .4, EASE.Back)
	local function swap() for n, p in pairs(pages) do p.Visible = n == name end end
	if instant then swap(); popIn(name) return end
	task.spawn(function()
		tw(content, {GroupTransparency = 1, Position = CPOS + UDim2.fromOffset(0, 10)}, .12).Completed:Wait()
		if tok ~= my then return end
		swap()
		content.Position = CPOS - UDim2.fromOffset(0, 10); popIn(name)
		tw(content, {GroupTransparency = 0, Position = CPOS}, .3)
	end)
end

for i, name in ipairs(order) do
	local b = new("TextButton", {Text = name, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.sub,
		BackgroundTransparency = 1, AutoButtonColor = false, Position = UDim2.fromOffset(0, (i - 1) * 36),
		Size = UDim2.new(1, 0, 0, 32)}, side)
	tabBtns[name] = b
	b.Activated:Connect(function() selectTab(name) end)
end

local function fmtT(s) s = math.floor(s); return string.format("%d:%02d", s // 60, s % 60) end
sound.Ended:Connect(function() if not sound.Looped then setStatus("Трек закончился") end end)
hb = RS.Heartbeat:Connect(function()
	if rainbow then
		hue = (hue + .004) % 1
		accent = Color3.fromHSV(hue, .65, 1)
		for _, f in ipairs(reg) do f(true) end
	end
	if not main.Visible or not pages["Музыка"].Visible then return end
	local len = sound.TimeLength
	local t, loud = os.clock(), math.clamp(sound.PlaybackLoudness / 350, 0, 1)
	for n, b in ipairs(bars) do
		local target = sound.IsPlaying and loud * (.35 + .65 * math.abs(math.sin(t * 5 + n * .8) * math.cos(t * 2.3 + n * .37))) or 0
		b.h += (target - b.h) * .3
		b.f.Size = UDim2.new(1 / 28, -3, 0, 3 + b.h * 34)
	end
	if len > 0 and not prog.Dragging then prog.Set(sound.TimePosition / len, true, true) end
	prog.Label.Text = fmtT(sound.TimePosition) .. " / " .. fmtT(len)
	pauseB.Text = sound.IsPlaying and "Пауза" or "Играть"
end)

selectTab(order[1], true)
setOpen(true)
task.delay(.9, function() toast("AURA загружено") end)
