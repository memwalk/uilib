local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local Lighting = game:GetService('Lighting')
local LocalPlayer = Players.LocalPlayer

local function getGuiParent()
    local ok, hui = pcall(function()
        return gethui and gethui()
    end)
    if ok and typeof(hui) == 'Instance' and hui.Name ~= 'CoreGui' then
        return hui
    end
    return LocalPlayer:FindFirstChildOfClass('PlayerGui') or LocalPlayer:WaitForChild('PlayerGui')
end

pcall(function()
    local parent = getGuiParent()
    local old = parent:FindFirstChild('BapDeltaUIv2')
    if old then old:Destroy() end
    local blur = Lighting:FindFirstChild('BapDeltaUIBlur')
    if blur then blur:Destroy() end
end)

local Theme = {
    bg = Color3.fromRGB(18, 18, 22),
    bgPanel = Color3.fromRGB(24, 24, 30),
    bgDeep = Color3.fromRGB(14, 14, 18),
    bgHover = Color3.fromRGB(32, 34, 42),
    bgActive = Color3.fromRGB(38, 42, 52),
    stroke = Color3.fromRGB(42, 44, 54),
    strokeSoft = Color3.fromRGB(34, 36, 44),
    text = Color3.fromRGB(228, 230, 236),
    textDim = Color3.fromRGB(140, 146, 160),
    textMute = Color3.fromRGB(96, 102, 116),
    accent = Color3.fromRGB(120, 210, 255),
    accentDim = Color3.fromRGB(70, 140, 175),
    accentSoft = Color3.fromRGB(40, 70, 88),
    success = Color3.fromRGB(110, 220, 150),
    danger = Color3.fromRGB(255, 110, 120),
    warn = Color3.fromRGB(255, 190, 70),
    esp = Color3.fromRGB(180, 90, 255),
    font = Enum.Font.GothamMedium,
    fontBold = Enum.Font.GothamBold,
    fontMono = Enum.Font.Code,
}

local Library = {
    Open = false,
    Accent = Theme.accent,
    UIKey = Enum.KeyCode.RightShift,
    ScreenGUI = nil,
    Holder = nil,
    Shell = nil,
    Flags = {},
    UnNamedFlags = 0,
    PageAmount = 0,
    Pages = {},
    Sections = {},
    ThemeObjects = {},
    Connections = {},
    Notifs = {},
    Theme = Theme,
    Watermark = nil,
    TargetHUD = nil,
    SkinBrowser = nil,
    CharPreview = nil,
    Keys = {
        [Enum.KeyCode.LeftShift] = 'LShift',
        [Enum.KeyCode.RightShift] = 'RShift',
        [Enum.KeyCode.LeftControl] = 'LCtrl',
        [Enum.KeyCode.RightControl] = 'RCtrl',
        [Enum.KeyCode.LeftAlt] = 'LAlt',
        [Enum.KeyCode.RightAlt] = 'RAlt',
        [Enum.KeyCode.CapsLock] = 'Caps',
        [Enum.KeyCode.One] = '1',
        [Enum.KeyCode.Two] = '2',
        [Enum.KeyCode.Three] = '3',
        [Enum.KeyCode.Four] = '4',
        [Enum.KeyCode.Five] = '5',
        [Enum.KeyCode.Six] = '6',
        [Enum.KeyCode.Seven] = '7',
        [Enum.KeyCode.Eight] = '8',
        [Enum.KeyCode.Nine] = '9',
        [Enum.KeyCode.Zero] = '0',
        [Enum.UserInputType.MouseButton1] = 'MB1',
        [Enum.UserInputType.MouseButton2] = 'MB2',
        [Enum.UserInputType.MouseButton3] = 'MB3',
    },
}

local function nextFlag(name)
    if type(name) == 'string' and name ~= '' then return name end
    Library.UnNamedFlags += 1
    return 'Flag_' .. Library.UnNamedFlags
end

function Library.NextFlag()
    return nextFlag(nil)
end

local function stripRichText(s)
    return tostring(s or ''):gsub('<.->', '')
end

function Library:Connection(signal, callback)
    local conn = signal:Connect(callback)
    Library.Connections[#Library.Connections + 1] = conn
    return conn
end

function Library:Disconnect(connection)
    if connection then
        pcall(function() connection:Disconnect() end)
    end
end

function Library:ChangeAccent(color)
    if typeof(color) ~= 'Color3' then return end
    Theme.accent = color
    Library.Accent = color
    Theme.accentDim = Color3.new(color.R * 0.55, color.G * 0.55, color.B * 0.55)
    Theme.accentSoft = Color3.new(color.R * 0.28, color.G * 0.28, color.B * 0.28)
    for _, obj in ipairs(Library.ThemeObjects) do
        pcall(function()
            if obj:IsA('GuiObject') and (obj.Name == 'Accent' or obj.Name == 'topLine') then
                obj.BackgroundColor3 = color
            elseif obj:IsA('UIStroke') then
                obj.Color = color
            end
        end)
    end
end

local function resolveKey(v)
    if v == nil or v == '' then return nil end
    if typeof(v) == 'EnumItem' then return v end
    if type(v) ~= 'string' then return nil end
    local raw = v:gsub('%s+', '')
    raw = raw:gsub('^Enum%.KeyCode%.', ''):gsub('^Enum%.UserInputType%.', '')
    local mouse = {
        MB1 = 'MouseButton1', MB2 = 'MouseButton2', MB3 = 'MouseButton3',
        MB4 = 'MouseButton4', MB5 = 'MouseButton5',
        MouseButton1 = 'MouseButton1', MouseButton2 = 'MouseButton2',
        MouseButton3 = 'MouseButton3', MouseButton4 = 'MouseButton4',
        MouseButton5 = 'MouseButton5',
    }
    if mouse[raw] then
        local ok, item = pcall(function() return Enum.UserInputType[mouse[raw]] end)
        if ok and item then return item end
    end
    if raw:match('^MouseButton%d+$') then
        local ok, item = pcall(function() return Enum.UserInputType[raw] end)
        if ok and item then return item end
    end
    local aliases = {
        LShift = 'LeftShift', RShift = 'RightShift',
        LCtrl = 'LeftControl', RCtrl = 'RightControl',
        LAlt = 'LeftAlt', RAlt = 'RightAlt',
        LeftControl = 'LeftControl', RightControl = 'RightControl',
        LeftShift = 'LeftShift', RightShift = 'RightShift',
        LeftAlt = 'LeftAlt', RightAlt = 'RightAlt',
    }
    local name = aliases[raw] or raw
    local ok, item = pcall(function() return Enum.KeyCode[name] end)
    if ok and typeof(item) == 'EnumItem' then return item end
    return nil
end

local function keyMatches(key, input)
    if not key or not input then return false end
    if typeof(key) ~= 'EnumItem' then return false end
    if key.EnumType == Enum.KeyCode then
        return input.KeyCode == key
    end
    if key.EnumType == Enum.UserInputType then
        return input.UserInputType == key
    end
    return false
end

local function decimalsToRounding(decimals)
    if type(decimals) ~= 'number' then return 0 end
    if decimals >= 1 then return 0 end
    if decimals <= 0 then return 0 end
    return math.clamp(math.floor(-math.log10(decimals) + 0.5), 0, 4)
end

local function tween(obj, props, t, style, dir)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(t or 0.14, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local blurState = { effect = nil, depth = 0 }
local function pushBlur(size)
    blurState.depth += 1
    if not blurState.effect or not blurState.effect.Parent then
        local b = Instance.new('BlurEffect')
        b.Name = 'BapDeltaUIBlur'
        b.Size = 0
        b.Parent = Lighting
        blurState.effect = b
    end
    tween(blurState.effect, { Size = size or 18 }, 0.3)
end
local function popBlur()
    blurState.depth = math.max(0, blurState.depth - 1)
    if blurState.depth <= 0 and blurState.effect then
        local b = blurState.effect
        tween(b, { Size = 0 }, 0.25)
        task.delay(0.28, function()
            if blurState.depth <= 0 and b and b.Parent then b:Destroy() end
            if blurState.effect == b then blurState.effect = nil end
        end)
    end
end
local function clearBlur()
    blurState.depth = 0
    blurState.effect = nil
    pcall(function()
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA('BlurEffect') and (c.Name == 'BapDeltaUIBlur' or string.find(c.Name, 'BapDelta', 1, true)) then
                c:Destroy()
            end
        end
    end)
end
Library.ClearBlur = clearBlur

local function corner(parent, r)
    local c = Instance.new('UICorner')
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end
local function stroke(parent, color, thickness)
    local s = Instance.new('UIStroke')
    s.Color = color or Theme.stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end
local function pad(parent, t, r, b, l)
    local p = Instance.new('UIPadding')
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.Parent = parent
    return p
end
local function list(parent, padding, fillDir)
    local l = Instance.new('UIListLayout')
    l.FillDirection = fillDir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment = Enum.VerticalAlignment.Top
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, padding or 6)
    l.Parent = parent
    return l
end
local function label(parent, props)
    local l = Instance.new('TextLabel')
    l.BackgroundTransparency = 1
    l.Font = props.font or Theme.font
    l.TextSize = props.size or 13
    l.TextColor3 = props.color or Theme.text
    l.TextXAlignment = props.x or Enum.TextXAlignment.Left
    l.TextYAlignment = props.y or Enum.TextYAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Text = props.text or ''
    l.Size = props.sizeUDim or UDim2.new(1, 0, 0, props.h or 18)
    l.Position = props.pos or UDim2.new()
    l.ZIndex = props.z or 5
    l.Parent = parent
    return l
end

local function makeDraggable(handle, target)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local LOGO_IMAGE = 'rbxassetid://117508562938981'

local EXTRA_MOUSE = {}
for i = 1, 8 do
    local ok, enumItem = pcall(function()
        return Enum.UserInputType['MouseButton' .. i]
    end)
    if ok and enumItem then
        EXTRA_MOUSE[enumItem] = 'MB' .. i
    end
end

local function keyNameFromInput(input)
    if not input then return nil end
    if input.KeyCode == Enum.KeyCode.Escape then return nil end

    local uit = input.UserInputType
    if EXTRA_MOUSE[uit] then
        return EXTRA_MOUSE[uit]
    end

    local okName, uitName = pcall(function() return uit.Name end)
    if okName and type(uitName) == 'string' then
        local n = uitName:match('^MouseButton(%d+)$')
        if n then return 'MB' .. n end
        if uitName == 'MouseWheel' then return 'Scroll' end
    end


    if uit == Enum.UserInputType.Keyboard or (input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown) then
        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Escape then
            return input.KeyCode.Name
        end
    end

    return nil
end

local function prettyKey(name)
    local map = {
        LeftShift = 'LShift', RightShift = 'RShift',
        LeftControl = 'LCtrl', RightControl = 'RCtrl',
        LeftAlt = 'LAlt', RightAlt = 'RAlt',
        MouseButton1 = 'MB1', MouseButton2 = 'MB2', MouseButton3 = 'MB3',
        MouseButton4 = 'MB4', MouseButton5 = 'MB5',
        MB1 = 'MB1', MB2 = 'MB2', MB3 = 'MB3', MB4 = 'MB4', MB5 = 'MB5',
    }
    local pretty = map[name] or name
    if type(pretty) == 'string' and #pretty > 8 then
        return pretty:sub(1, 7) .. '…'
    end
    return pretty
end

function Library:CreateWatermark(opts)
    opts = opts or {}
    local gui = Library.ScreenGUI
    if not gui then return end
    local frame = Instance.new('Frame')
    frame.Name = 'Watermark'
    frame.Position = UDim2.new(0, 14, 0, 14)
    frame.Size = UDim2.new(0, 0, 0, 30)
    frame.AutomaticSize = Enum.AutomaticSize.X
    frame.BackgroundColor3 = Theme.bgPanel
    frame.BorderSizePixel = 0
    frame.ZIndex = 200
    frame.Parent = gui
    corner(frame, 7)
    stroke(frame, Theme.stroke, 1)
    local accent = Instance.new('Frame')
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.BackgroundColor3 = Theme.accent
    accent.BorderSizePixel = 0
    accent.ZIndex = 201
    accent.Parent = frame
    local row = Instance.new('Frame')
    row.BackgroundTransparency = 1
    row.Position = UDim2.new(0, 0, 0, 2)
    row.Size = UDim2.new(0, 0, 1, -2)
    row.AutomaticSize = Enum.AutomaticSize.X
    row.ZIndex = 201
    row.Parent = frame
    pad(row, 0, 12, 0, 12)
    local lay = list(row, 8, Enum.FillDirection.Horizontal)
    lay.VerticalAlignment = Enum.VerticalAlignment.Center
    local function chip(text, color, bold)
        local l = Instance.new('TextLabel')
        l.BackgroundTransparency = 1
        l.AutomaticSize = Enum.AutomaticSize.X
        l.Size = UDim2.new(0, 0, 1, 0)
        l.Font = bold and Theme.fontBold or Theme.fontMono
        l.TextSize = 12
        l.TextColor3 = color or Theme.text
        l.Text = text
        l.ZIndex = 202
        l.Parent = row
        return l
    end
    local titleChip = chip(opts.Title or opts.Name or 'bap delta', Theme.accent, true)
    chip('|', Theme.textMute)
    local fpsL = chip('0 fps', Theme.textDim)
    chip('|', Theme.textMute)
    local pingL = chip('0 ms', Theme.textDim)
    chip('|', Theme.textMute)
    chip(LocalPlayer.DisplayName or LocalPlayer.Name, Theme.text)
    local frames, last = 0, tick()
    Library:Connection(RunService.RenderStepped, function()
        if not frame.Parent then return end
        frames += 1
        local now = tick()
        if now - last >= 0.5 then
            fpsL.Text = math.floor(frames / (now - last) + 0.5) .. ' fps'
            frames = 0
            last = now
            local ping = 0
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5) end)
            pingL.Text = ping .. ' ms'
        end
    end)
    local wm = {
        Frame = frame,
        Name = opts.Title or opts.Name or 'bap delta',
        SetVisible = function(_, v) frame.Visible = v == true end,
        UpdateText = function(_, text)
            titleChip.Text = tostring(text)
            wm.Name = tostring(text)
        end,
        Position = function(_, x, y)
            frame.Position = UDim2.new(0, x or 14, 0, y or 14)
        end,
    }
    Library.Watermark = wm
    return wm
end

function Library:EnsureWatermark(properties)
    properties = properties or {}
    if Library.Watermark and type(Library.Watermark) == 'table' and Library.Watermark.Frame and Library.Watermark.Frame.Parent then
        if properties.Name then Library.Watermark:UpdateText(properties.Name) end
        return Library.Watermark
    end
    return Library:CreateWatermark({ Title = properties.Name or properties.Title or 'Bap Delta' })
end

function Library:CreateTargetHUD(opts)
    opts = opts or {}
    if Library.TargetHUD and Library.TargetHUD.Frame and Library.TargetHUD.Frame.Parent then
        return Library.TargetHUD
    end
    local gui = Library.ScreenGUI
    if not gui then return end
    local frame = Instance.new('Frame')
    frame.Name = 'TargetHUD'
    frame.AnchorPoint = Vector2.new(0.5, 1)
    frame.Position = UDim2.new(0.5, 0, 1, -36)
    frame.Size = UDim2.new(0, 340, 0, 104)
    frame.BackgroundColor3 = Theme.bg
    frame.BorderSizePixel = 0
    frame.Visible = opts.Visible == true
    frame.ZIndex = 210
    frame.Parent = gui
    corner(frame, 9)
    stroke(frame, Theme.stroke, 1)
    local inline = Instance.new('Frame')
    inline.Size = UDim2.new(1, -2, 1, -2)
    inline.Position = UDim2.new(0, 1, 0, 1)
    inline.BackgroundColor3 = Theme.bgDeep
    inline.BorderSizePixel = 0
    inline.ZIndex = 211
    inline.Parent = frame
    corner(inline, 8)
    local top = Instance.new('Frame')
    top.Name = 'Accent'
    top.Size = UDim2.new(1, 0, 0, 2)
    top.BackgroundColor3 = Theme.accent
    top.BorderSizePixel = 0
    top.ZIndex = 212
    top.Parent = inline
    Library.ThemeObjects[#Library.ThemeObjects + 1] = top
    local avatar = Instance.new('ImageLabel')
    avatar.BackgroundColor3 = Theme.bgPanel
    avatar.BorderSizePixel = 0
    avatar.Position = UDim2.new(0, 10, 0, 12)
    avatar.Size = UDim2.new(0, 52, 0, 52)
    avatar.Image = ''
    avatar.ZIndex = 213
    avatar.Parent = inline
    corner(avatar, 8)
    local function mk(pos, size, text, color, align)
        local l = label(inline, { text = text, font = Theme.fontMono, size = 11, color = color or Theme.textDim, h = size.Y.Offset, z = 213, x = align })
        l.Position = pos
        l.Size = size
        return l
    end
    local nameL = mk(UDim2.new(0, 74, 0, 10), UDim2.new(0, 160, 0, 14), 'user  —', Theme.text)
    nameL.Font = Theme.fontBold
    local distL = mk(UDim2.new(0, 230, 0, 10), UDim2.new(0, 100, 0, 14), 'dist  —', Theme.textDim, Enum.TextXAlignment.Right)
    local kdL = mk(UDim2.new(0, 74, 0, 28), UDim2.new(0, 160, 0, 14), 'kd  —', Theme.textDim)
    local statusL = mk(UDim2.new(0, 230, 0, 28), UDim2.new(0, 100, 0, 14), 'status  —', Theme.textDim, Enum.TextXAlignment.Right)
    local playL = mk(UDim2.new(0, 74, 0, 46), UDim2.new(0, 160, 0, 14), 'playtime  —', Theme.textDim)
    local reportsL = mk(UDim2.new(0, 230, 0, 46), UDim2.new(0, 100, 0, 14), 'reports  0', Theme.textDim, Enum.TextXAlignment.Right)
    local toolL = mk(UDim2.new(0, 74, 0, 64), UDim2.new(0, 160, 0, 14), 'tool  —', Theme.textDim)
    local visorL = mk(UDim2.new(0, 230, 0, 64), UDim2.new(0, 100, 0, 14), 'visor  —', Theme.textDim, Enum.TextXAlignment.Right)
    local hpBg = Instance.new('Frame')
    hpBg.Position = UDim2.new(0, 10, 1, -20)
    hpBg.Size = UDim2.new(1, -20, 0, 14)
    hpBg.BackgroundColor3 = Theme.bg
    hpBg.BorderSizePixel = 0
    hpBg.ClipsDescendants = true
    hpBg.ZIndex = 213
    hpBg.Parent = inline
    corner(hpBg, 4)
    local hpFill = Instance.new('Frame')
    hpFill.Size = UDim2.new(0, 0, 1, 0)
    hpFill.BackgroundColor3 = Theme.success
    hpFill.BorderSizePixel = 0
    hpFill.ZIndex = 214
    hpFill.Parent = hpBg
    corner(hpFill, 4)
    local hpText = label(hpBg, {
        text = '',
        font = Theme.fontBold,
        size = 10,
        color = Theme.text,
        h = 14,
        z = 216,
        x = Enum.TextXAlignment.Center,
    })
    hpText.Position = UDim2.new(0, 0, 0, 0)
    hpText.Size = UDim2.new(1, 0, 1, 0)
    hpText.TextYAlignment = Enum.TextYAlignment.Center
    hpText.TextStrokeTransparency = 0.35
    hpText.TextStrokeColor3 = Color3.new(0, 0, 0)

    local hud = {
        Frame = frame,
        SetVisible = function(_, v)
            frame.Visible = v == true
        end,
        Update = function(_, data)
            data = data or {}
            if data.Visible == false then
                frame.Visible = false
                return
            end
            if data.Name then nameL.Text = 'user  ' .. tostring(data.Name) end
            if data.Distance then distL.Text = 'dist  ' .. tostring(data.Distance) end
            if data.KD then kdL.Text = tostring(data.KD) end
            if data.Status then
                statusL.Text = 'status  ' .. tostring(data.Status)
                statusL.TextColor3 = data.StatusColor or (tostring(data.Status) == 'visible' and Theme.success or Theme.danger)
            end
            if data.Playtime then playL.Text = 'playtime  ' .. tostring(data.Playtime) end
            if data.Reports ~= nil then
                reportsL.Text = 'reports  ' .. tostring(data.Reports)
                reportsL.TextColor3 = (tonumber(data.Reports) or 0) > 0 and Theme.danger or Theme.textDim
            end
            if data.Tool then toolL.Text = 'tool  ' .. tostring(data.Tool) end
            if data.Visor then
                visorL.Text = 'visor  ' .. tostring(data.Visor)
                visorL.TextColor3 = tostring(data.Visor) == 'on' and Theme.success or Theme.textDim
            end
            if data.Health and data.MaxHealth then
                local pct = math.clamp((tonumber(data.Health) or 0) / math.max(tonumber(data.MaxHealth) or 1, 1), 0, 1)
                hpFill.Size = UDim2.new(pct, 0, 1, 0)
                hpFill.BackgroundColor3 = pct > 0.5 and Theme.success or (pct > 0.25 and Theme.warn or Theme.danger)
                hpText.Text = string.format('%d/%d', math.floor(data.Health), math.floor(data.MaxHealth))
            end
            if data.UserId then
                avatar.Image = string.format('rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150', data.UserId)
            end
            frame.Visible = true
        end,
    }
    Library.TargetHUD = hud
    return hud
end

function Library:CreateSkinBrowser()
    if Library.SkinBrowser and Library.SkinBrowser.Frame and Library.SkinBrowser.Frame.Parent then
        return Library.SkinBrowser
    end
    local gui = Library.ScreenGUI
    if not gui then return end
    local panel = Instance.new('Frame')
    panel.Name = 'SkinBrowser'
    panel.AnchorPoint = Vector2.new(1, 0.5)
    panel.Position = UDim2.new(1, -16, 0.5, 0)
    panel.Size = UDim2.new(0, 640, 0, 420)
    panel.BackgroundColor3 = Theme.bg
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ClipsDescendants = true
    panel.ZIndex = 230
    panel.Parent = gui
    corner(panel, 10)
    stroke(panel, Theme.stroke, 1)
    local top = Instance.new('Frame')
    top.Name = 'Accent'
    top.Size = UDim2.new(1, 0, 0, 2)
    top.BackgroundColor3 = Theme.accent
    top.BorderSizePixel = 0
    top.ZIndex = 231
    top.Parent = panel
    Library.ThemeObjects[#Library.ThemeObjects + 1] = top
    local header = Instance.new('Frame')
    header.Position = UDim2.new(0, 0, 0, 2)
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Theme.bgDeep
    header.BorderSizePixel = 0
    header.ZIndex = 231
    header.Parent = panel
    makeDraggable(header, panel)
    label(header, { text = 'skin changer', font = Theme.fontBold, size = 14, color = Theme.text, h = 22, z = 232 }).Position = UDim2.new(0, 14, 0, 4)
    local statusL = label(header, {
        text = 'select an item, then a skin',
        font = Theme.fontMono,
        size = 11,
        color = Theme.textMute,
        h = 16,
        z = 232,
    })
    statusL.Position = UDim2.new(0, 14, 0, 24)
    statusL.Size = UDim2.new(1, -100, 0, 16)
    local close = Instance.new('TextButton')
    close.AutoButtonColor = false
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(1, -12, 0.5, 0)
    close.Size = UDim2.new(0, 64, 0, 24)
    close.BackgroundColor3 = Theme.bgPanel
    close.Font = Theme.fontMono
    close.TextSize = 11
    close.TextColor3 = Theme.textDim
    close.Text = 'close'
    close.ZIndex = 233
    close.Parent = header
    corner(close, 6)
    stroke(close, Theme.strokeSoft, 1)
    local content = Instance.new('Frame')
    content.Name = 'Content'
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 0, 0, 46)
    content.Size = UDim2.new(1, 0, 1, -46)
    content.ClipsDescendants = true
    content.ZIndex = 232
    content.Parent = panel
    local browser = {
        Frame = panel,
        Content = content,
        Status = statusL,
        Open = function()
            panel.Visible = true
            panel.Size = UDim2.new(0, 620, 0, 400)
            tween(panel, { Size = UDim2.new(0, 640, 0, 420) }, 0.2, Enum.EasingStyle.Back)
        end,
        Close = function()
            panel.Visible = false
        end,
        IsOpen = function()
            return panel.Visible
        end,
        SetStatus = function(_, text)
            statusL.Text = tostring(text or '')
        end,
    }
    close.MouseButton1Click:Connect(function()
        browser.Close()
        if Library.Flags.SkinChanger_obj then
            pcall(function() Library.Flags.SkinChanger_obj:Set(false) end)
        end
    end)
    Library.SkinBrowser = browser
    return browser
end

function Library:CreateCharPreview(shell, height, xOffset)
    local PREVIEW_W = 230
    local ESP_DEFAULT = Theme.esp
    local TEXT_SIZE = 14
    local TEXT_PAD = 2
    local SIDE_GAP = 6
    local BOX_PAD_X, BOX_PAD_Y = 8, 6

    local panel = Instance.new('Frame')
    panel.Name = 'CharPreview'
    panel.Position = UDim2.new(0, xOffset or 0, 0, 0)
    panel.Size = UDim2.new(0, PREVIEW_W, 1, 0)
    panel.BackgroundColor3 = Theme.bg
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.ZIndex = 2
    panel.Parent = shell
    corner(panel, 10)
    stroke(panel, Theme.stroke, 1)

    local previewGrain = Instance.new('ImageLabel')
    previewGrain.Name = 'Grain'
    previewGrain.BackgroundTransparency = 1
    previewGrain.Size = UDim2.new(1, 0, 1, 0)
    previewGrain.Image = 'rbxassetid://2151741365'
    previewGrain.ImageTransparency = 0.94
    previewGrain.ImageColor3 = Color3.fromRGB(180, 210, 230)
    previewGrain.ScaleType = Enum.ScaleType.Tile
    previewGrain.TileSize = UDim2.new(0, 140, 0, 140)
    previewGrain.ZIndex = 2
    previewGrain.Parent = panel

    local accent = Instance.new('Frame')
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.BackgroundColor3 = Theme.accent
    accent.BorderSizePixel = 0
    accent.ZIndex = 3
    accent.Parent = panel

    local headBar = Instance.new('Frame')
    headBar.Position = UDim2.new(0, 0, 0, 2)
    headBar.Size = UDim2.new(1, 0, 0, 34)
    headBar.BackgroundColor3 = Theme.bgDeep
    headBar.BorderSizePixel = 0
    headBar.ZIndex = 3
    headBar.Parent = panel
    label(headBar, { text = 'ESP PREVIEW', font = Theme.fontMono, size = 11, color = Theme.textDim, h = 34, z = 4, x = Enum.TextXAlignment.Center })

    local vp = Instance.new('ViewportFrame')
    vp.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    vp.BorderSizePixel = 0
    vp.Position = UDim2.new(0, 8, 0, 42)
    vp.Size = UDim2.new(1, -16, 1, -78)
    vp.ZIndex = 3
    vp.Parent = panel
    corner(vp, 8)

    local world = Instance.new('WorldModel')
    world.Parent = vp
    local cam = Instance.new('Camera')
    cam.FieldOfView = 58
    cam.Parent = vp
    vp.CurrentCamera = cam

    local overlay = Instance.new('Frame')
    overlay.Name = 'EspOverlay'
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ClipsDescendants = false
    overlay.ZIndex = 20
    overlay.Parent = panel

    local function syncOverlay()
        local panelPos = panel.AbsolutePosition
        local vpPos = vp.AbsolutePosition
        local vpSize = vp.AbsoluteSize
        if vpSize.X < 2 or vpSize.Y < 2 then
            overlay.Position = vp.Position
            overlay.Size = vp.Size
            return
        end
        overlay.Position = UDim2.fromOffset(vpPos.X - panelPos.X, vpPos.Y - panelPos.Y)
        overlay.Size = UDim2.fromOffset(vpSize.X, vpSize.Y)
    end
    syncOverlay()

    local function makeEspText(name)
        local lbl = Instance.new('TextLabel')
        lbl.Name = name
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = TEXT_SIZE
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.TextStrokeTransparency = 1
        lbl.RichText = false
        lbl.TextScaled = false
        lbl.TextWrapped = false
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.AnchorPoint = Vector2.new(0.5, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.XY
        lbl.Size = UDim2.fromOffset(0, 18)
        lbl.ZIndex = 24
        lbl.Visible = false
        lbl.Parent = overlay
        local s = Instance.new('UIStroke')
        s.Name = 'Outline'
        s.Color = Color3.new(0, 0, 0)
        s.Thickness = 1.35
        s.Transparency = 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        s.LineJoinMode = Enum.LineJoinMode.Round
        s.Parent = lbl
        return lbl
    end

    local nameTag = makeEspText('Name')
    local visTag = makeEspText('Visible')
    local distTag = makeEspText('Distance')
    local hpText = makeEspText('Health')
    local toolTag = makeEspText('Weapon')
    local attTag = makeEspText('Attachments')

    local boxOuter = Instance.new('Frame')
    boxOuter.BackgroundTransparency = 1
    boxOuter.BorderSizePixel = 0
    boxOuter.ZIndex = 21
    boxOuter.Visible = false
    boxOuter.Parent = overlay
    local boxOuterStroke = stroke(boxOuter, Color3.new(0, 0, 0), 3)

    local boxInner = Instance.new('Frame')
    boxInner.BackgroundTransparency = 1
    boxInner.BorderSizePixel = 0
    boxInner.ZIndex = 22
    boxInner.Visible = false
    boxInner.Parent = overlay
    local boxInnerStroke = stroke(boxInner, ESP_DEFAULT, 1)

    local hpBg = Instance.new('Frame')
    hpBg.BorderSizePixel = 0
    hpBg.BackgroundColor3 = Color3.new(0, 0, 0)
    hpBg.ZIndex = 23
    hpBg.Visible = false
    hpBg.Parent = overlay
    local hpFill = Instance.new('Frame')
    hpFill.BorderSizePixel = 0
    hpFill.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
    hpFill.ZIndex = 24
    hpFill.Parent = hpBg

    local bonePool = {}
    local function getBone(i)
        local pair = bonePool[i]
        if not pair then
            local outer = Instance.new('Frame')
            outer.AnchorPoint = Vector2.new(0.5, 0.5)
            outer.BorderSizePixel = 0
            outer.BackgroundColor3 = Color3.new(0, 0, 0)
            outer.ZIndex = 21
            outer.Visible = false
            outer.Parent = overlay
            local inner = Instance.new('Frame')
            inner.AnchorPoint = Vector2.new(0.5, 0.5)
            inner.BorderSizePixel = 0
            inner.BackgroundColor3 = ESP_DEFAULT
            inner.ZIndex = 22
            inner.Visible = false
            inner.Parent = overlay
            pair = { outer = outer, inner = inner }
            bonePool[i] = pair
        end
        return pair
    end

    local footer = label(panel, {
        text = 'live · mirrors your ESP settings',
        font = Theme.fontMono,
        size = 10,
        color = Theme.textMute,
        h = 24,
        z = 4,
        x = Enum.TextXAlignment.Center,
    })
    footer.Position = UDim2.new(0, 0, 1, -28)

    local cloneModel
    local chamsHighlight
    local angle = 0.35
    local liveHp, liveMaxHp, liveWeapon, liveName = 100, 100, 'Unarmed', LocalPlayer.DisplayName or LocalPlayer.Name

    local R15_BONES = {
        { 'Head', 'UpperTorso' },
        { 'UpperTorso', 'LowerTorso' },
        { 'UpperTorso', 'LeftUpperArm' },
        { 'LeftUpperArm', 'LeftLowerArm' },
        { 'LeftLowerArm', 'LeftHand' },
        { 'UpperTorso', 'RightUpperArm' },
        { 'RightUpperArm', 'RightLowerArm' },
        { 'RightLowerArm', 'RightHand' },
        { 'LowerTorso', 'LeftUpperLeg' },
        { 'LeftUpperLeg', 'LeftLowerLeg' },
        { 'LeftLowerLeg', 'LeftFoot' },
        { 'LowerTorso', 'RightUpperLeg' },
        { 'RightUpperLeg', 'RightLowerLeg' },
        { 'RightLowerLeg', 'RightFoot' },
    }
    local R6_BONES = {
        { 'Head', 'Torso' },
        { 'Torso', 'Left Arm' },
        { 'Torso', 'Right Arm' },
        { 'Torso', 'Left Leg' },
        { 'Torso', 'Right Leg' },
    }
    local BOX_PARTS = {
        'Head', 'Torso', 'UpperTorso', 'LowerTorso',
        'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg',
        'LeftUpperArm', 'RightUpperArm', 'LeftLowerArm', 'RightLowerArm',
        'LeftHand', 'RightHand', 'LeftUpperLeg', 'RightUpperLeg', 'LeftLowerLeg', 'RightLowerLeg',
        'LeftFoot', 'RightFoot',
    }

    local function flagOn(name)
        return Library.Flags[name] == true
    end
    local function flagColor(name, fallback)
        local v = Library.Flags[name]
        if typeof(v) == 'Color3' then return v end
        return fallback or ESP_DEFAULT
    end
    local function flagNum(name, fallback)
        local v = tonumber(Library.Flags[name])
        if v then return v end
        return fallback
    end

    local function project(worldPos)
        local size = vp.AbsoluteSize
        if size.X < 2 or size.Y < 2 then
            return Vector2.zero, false
        end
        local relative = cam.CFrame:PointToObjectSpace(worldPos)
        if relative.Z >= -0.05 then
            return Vector2.zero, false
        end
        local aspect = size.X / size.Y
        local tanHalf = math.tan(math.rad(cam.FieldOfView * 0.5))
        local nx = (relative.X / -relative.Z) / (tanHalf * aspect)
        local ny = (relative.Y / -relative.Z) / tanHalf
        local x = (nx + 1) * 0.5 * size.X
        local y = (1 - ny) * 0.5 * size.Y
        return Vector2.new(x, y), true
    end

    local function setText(lbl, text, x, y, visible, color, align)
        if not lbl then return false end
        if not visible or text == nil or text == '' or x == nil or y == nil then
            lbl.Visible = false
            return false
        end
        local col = color or Color3.new(1, 1, 1)
        local lum = col.R * 0.299 + col.G * 0.587 + col.B * 0.114
        if lum < 0.2 then col = Color3.new(1, 1, 1) end
        local anchorX = 0.5
        local textAlign = Enum.TextXAlignment.Center
        if align == 'left' then
            anchorX = 1
            textAlign = Enum.TextXAlignment.Right
        elseif align == 'right' then
            anchorX = 0
            textAlign = Enum.TextXAlignment.Left
        end
        lbl.Text = tostring(text)
        lbl.TextSize = TEXT_SIZE
        lbl.TextColor3 = col
        lbl.AnchorPoint = Vector2.new(anchorX, 0)
        lbl.TextXAlignment = textAlign
        lbl.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
        lbl.Visible = true
        return true
    end

    local function placeBone(pair, a, b, color, thick, outline)
        local mid = (a + b) * 0.5
        local delta = b - a
        local len = delta.Magnitude
        if len < 1 then
            pair.outer.Visible = false
            pair.inner.Visible = false
            return
        end
        local rot = math.deg(math.atan2(delta.Y, delta.X))
        local oThick = thick + (outline and 2.2 or 0.5)
        pair.outer.Size = UDim2.fromOffset(math.max(2, len), oThick)
        pair.outer.Position = UDim2.fromOffset(mid.X, mid.Y)
        pair.outer.Rotation = rot
        pair.outer.BackgroundColor3 = Color3.new(0, 0, 0)
        pair.outer.Visible = outline == true
        pair.inner.Size = UDim2.fromOffset(math.max(2, len), thick)
        pair.inner.Position = UDim2.fromOffset(mid.X, mid.Y)
        pair.inner.Rotation = rot
        pair.inner.BackgroundColor3 = color
        pair.inner.Visible = true
    end

    local function hideAllEsp()
        boxOuter.Visible = false
        boxInner.Visible = false
        hpBg.Visible = false
        nameTag.Visible = false
        visTag.Visible = false
        distTag.Visible = false
        hpText.Visible = false
        toolTag.Visible = false
        attTag.Visible = false
        for _, pair in ipairs(bonePool) do
            pair.outer.Visible = false
            pair.inner.Visible = false
        end
        if chamsHighlight then chamsHighlight.Enabled = false end
    end

    local function updateEspOverlay()
        if not cloneModel or not cam then return end
        syncOverlay()

        local master = flagOn('ESPEnabled')
        if not master then
            hideAllEsp()
            return
        end

        local showBox = flagOn('BoxESP')
        local showSkeleton = flagOn('SkeletonESP')
        local showChams = flagOn('ChamsESP')
        local showName = flagOn('NameESP')
        local showDistance = flagOn('DistanceESP')
        local showVisible = flagOn('VisibleESP')
        local showHealthText = flagOn('HealthTextESP')
        local showHealthBar = flagOn('HealthBarESP')
        local showWeapon = flagOn('HeldWeaponESP')
        local showAtt = showWeapon and flagOn('WeaponAttachments')
        local outline = Library.Flags.ESPOutline ~= false
        local boxColor = flagColor('BoxESPColor', ESP_DEFAULT)
        local skeletonColor = flagColor('SkeletonESPColor', ESP_DEFAULT)
        local chamsColor = flagColor('ChamsESPColor', ESP_DEFAULT)
        local nameColor = flagColor('NameESPColor', ESP_DEFAULT)
        local distanceColor = flagColor('DistanceESPColor', ESP_DEFAULT)
        local visibleColor = flagColor('VisibleESPColor', Color3.fromRGB(80, 255, 120))
        local healthTextColor = flagColor('HealthTextESPColor', ESP_DEFAULT)
        local healthBarColor = flagColor('HealthBarESPColor', Color3.fromRGB(80, 180, 255))
        local weaponColor = flagColor('HeldWeaponESPColor', Color3.fromRGB(255, 200, 75))
        local attColor = flagColor('AttachmentsESPColor', Color3.fromRGB(200, 200, 210))
        local skelThick = flagNum('SkeletonThickness', 1.8)
        local chamsFill = flagNum('ChamsFill', 0.55)

        local partMap = {}
        for _, n in ipairs(BOX_PARTS) do
            local p = cloneModel:FindFirstChild(n)
            if p and p:IsA('BasePart') then
                partMap[n] = p
            end
        end

        local vpSize = vp.AbsoluteSize
        local boxPos, boxSize
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local validCount = 0
        for _, n in ipairs(BOX_PARTS) do
            local p = partMap[n]
            if p then
                local cf, sz = p.CFrame, p.Size * 0.5
                for _, ox in ipairs({ -1, 1 }) do
                    for _, oy in ipairs({ -1, 1 }) do
                        for _, oz in ipairs({ -1, 1 }) do
                            local screen, ok = project((cf * CFrame.new(ox * sz.X, oy * sz.Y, oz * sz.Z)).Position)
                            if ok then
                                validCount += 1
                                if screen.X < minX then minX = screen.X end
                                if screen.Y < minY then minY = screen.Y end
                                if screen.X > maxX then maxX = screen.X end
                                if screen.Y > maxY then maxY = screen.Y end
                            end
                        end
                    end
                end
            end
        end
        if validCount >= 4 then
            local width, height = maxX - minX, maxY - minY
            if width >= 2 and height >= 2 then
                boxPos = Vector2.new(math.floor(minX - BOX_PAD_X), math.floor(minY - BOX_PAD_Y))
                boxSize = Vector2.new(
                    math.max(10, math.floor(width + BOX_PAD_X * 2)),
                    math.max(10, math.floor(height + BOX_PAD_Y * 2))
                )
            end
        end

        local function boxLooksValid()
            if not boxPos or not boxSize or vpSize.X < 2 then return false end
            if boxSize.X < 24 or boxSize.Y < 36 then return false end
            local cx = boxPos.X + boxSize.X * 0.5
            local cy = boxPos.Y + boxSize.Y * 0.5
            if cx < vpSize.X * 0.18 or cx > vpSize.X * 0.82 then return false end
            if cy < vpSize.Y * 0.12 or cy > vpSize.Y * 0.88 then return false end
            return true
        end
        if not boxLooksValid() then
            local bw = math.floor(vpSize.X * 0.38)
            local bh = math.floor(vpSize.Y * 0.78)
            boxPos = Vector2.new(math.floor((vpSize.X - bw) * 0.5), math.floor(vpSize.Y * 0.08))
            boxSize = Vector2.new(bw, bh)
        end

        if showBox and boxPos and boxSize then
            boxOuter.Visible = outline
            boxOuter.Position = UDim2.fromOffset(boxPos.X, boxPos.Y)
            boxOuter.Size = UDim2.fromOffset(boxSize.X, boxSize.Y)
            boxOuterStroke.Thickness = outline and 3 or 1
            boxOuterStroke.Color = Color3.new(0, 0, 0)
            boxInner.Visible = true
            boxInner.Position = UDim2.fromOffset(boxPos.X, boxPos.Y)
            boxInner.Size = UDim2.fromOffset(boxSize.X, boxSize.Y)
            boxInnerStroke.Color = boxColor
            boxInnerStroke.Thickness = 1
        else
            boxOuter.Visible = false
            boxInner.Visible = false
        end

        if showChams and cloneModel then
            if not chamsHighlight or not chamsHighlight.Parent then
                chamsHighlight = Instance.new('Highlight')
                chamsHighlight.Name = 'PreviewChams'
                chamsHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                chamsHighlight.Parent = cloneModel
            end
            chamsHighlight.Enabled = true
            chamsHighlight.FillColor = chamsColor
            chamsHighlight.OutlineColor = outline and Color3.new(0, 0, 0) or chamsColor
            chamsHighlight.FillTransparency = 1 - math.clamp(chamsFill, 0, 1)
            chamsHighlight.OutlineTransparency = outline and 0.15 or 1
        elseif chamsHighlight then
            chamsHighlight.Enabled = false
        end

        local bones = partMap.UpperTorso and R15_BONES or R6_BONES
        local used = 0
        if showSkeleton then
            for _, pairNames in ipairs(bones) do
                local aPart, bPart = partMap[pairNames[1]], partMap[pairNames[2]]
                if aPart and bPart then
                    local a, aOk = project(aPart.Position)
                    local b, bOk = project(bPart.Position)
                    if aOk and bOk then
                        used += 1
                        placeBone(getBone(used), a, b, skeletonColor, skelThick, outline)
                    end
                end
            end
        end
        for i = used + 1, #bonePool do
            bonePool[i].outer.Visible = false
            bonePool[i].inner.Visible = false
        end

        if not boxPos or not boxSize then
            nameTag.Visible = false
            visTag.Visible = false
            distTag.Visible = false
            hpText.Visible = false
            toolTag.Visible = false
            attTag.Visible = false
            hpBg.Visible = false
            return
        end

        local textX = boxPos.X + boxSize.X * 0.5
        local sideY = boxPos.Y
        local topY = boxPos.Y - TEXT_SIZE - TEXT_PAD
        local bottomY = boxPos.Y + boxSize.Y + TEXT_PAD
        local lineHeight = TEXT_SIZE + TEXT_PAD
        local barW = 4
        local barX = boxPos.X - barW - 4

        local above = 0
        if setText(nameTag, liveName, textX, topY, showName, nameColor, 'center') then
            above += 1
        end
        if setText(
            visTag,
            'VISIBLE',
            textX,
            topY - above * lineHeight,
            showVisible,
            visibleColor,
            'center'
        ) then
            above += 1
        end

        local hpTextX = showHealthBar and (barX - SIDE_GAP) or (boxPos.X - SIDE_GAP)
        setText(hpText, string.format('%d/%d', liveHp, liveMaxHp), hpTextX, sideY, showHealthText, healthTextColor, 'left')
        setText(distTag, '3m', boxPos.X + boxSize.X + SIDE_GAP, sideY, showDistance, distanceColor, 'right')

        local below = 0
        if setText(toolTag, liveWeapon, textX, bottomY, showWeapon, weaponColor, 'center') then
            below += 1
        end
        setText(attTag, showAtt and 'Stock / Grip' or nil, textX, bottomY + below * lineHeight, showAtt, attColor, 'center')

        if showHealthBar then
            local pct = math.clamp(liveHp / math.max(liveMaxHp, 1), 0, 1)
            local barColor = healthBarColor
            if pct <= 0.25 then
                barColor = Color3.fromRGB(255, 70, 70)
            elseif pct <= 0.55 then
                barColor = Color3.fromRGB(255, 190, 70)
            end
            local fillH = math.max(1, math.floor(boxSize.Y * pct))
            hpBg.Visible = true
            hpBg.Position = UDim2.fromOffset(barX - 1, boxPos.Y - 1)
            hpBg.Size = UDim2.fromOffset(barW + 2, boxSize.Y + 2)
            hpFill.Position = UDim2.fromOffset(1, 1 + (boxSize.Y - fillH))
            hpFill.Size = UDim2.fromOffset(barW, fillH)
            hpFill.BackgroundColor3 = barColor
        else
            hpBg.Visible = false
        end
    end

    local function stripClone(model)
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA('BaseScript') or d:IsA('LocalScript') or d:IsA('Script') or d:IsA('ForceField') or d:IsA('Highlight') then
                d:Destroy()
            end
        end
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA('BasePart') then
                d.Anchored = true
                d.CanCollide = false
                d.Massless = true
            end
        end
    end

    local function recenter(model)
        local root = model.PrimaryPart
            or model:FindFirstChild('HumanoidRootPart')
            or model:FindFirstChild('Torso')
            or model:FindFirstChild('UpperTorso')
            or model:FindFirstChildWhichIsA('BasePart')
        if not root then return end
        model.PrimaryPart = root
        local cf = root.CFrame
        local offset = CFrame.new(-cf.Position.X, -cf.Position.Y + 1.15, -cf.Position.Z)
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA('BasePart') then
                p.CFrame = offset * p.CFrame
            end
        end
    end

    local function refreshHud()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass('Humanoid')
        if not hum then return end
        liveWeapon = 'Unarmed'
        pcall(function()
            local t = char:FindFirstChildOfClass('Tool')
            if t then liveWeapon = t.Name end
        end)
        liveHp = math.floor(hum.Health + 0.5)
        liveMaxHp = math.max(1, math.floor(hum.MaxHealth + 0.5))
        liveName = tostring(LocalPlayer.DisplayName ~= '' and LocalPlayer.DisplayName or LocalPlayer.Name)
    end

    local function rebuild()
        chamsHighlight = nil
        if cloneModel then
            cloneModel:Destroy()
            cloneModel = nil
        end
        local char = LocalPlayer.Character
        if not char then return end
        if not char:FindFirstChildOfClass('Humanoid') then return end
        local ok, clone = pcall(function()
            char.Archivable = true
            local c = char:Clone()
            char.Archivable = false
            return c
        end)
        if not ok or not clone then return end
        stripClone(clone)
        clone.Name = 'PreviewClone'
        clone.Parent = world
        cloneModel = clone
        recenter(clone)
        refreshHud()
    end

    rebuild()
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        rebuild()
    end)

    task.spawn(function()
        while panel.Parent do
            task.wait(0.35)
            if Library.Open then refreshHud() end
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        if not panel.Parent or not panel.Visible then return end
        if not cloneModel or not cloneModel.PrimaryPart then return end
        angle += dt * 0.45
        local dist = 10.2
        local focus = cloneModel.PrimaryPart.Position + Vector3.new(0, 0.35, 0)
        local orbit = CFrame.new(focus)
            * CFrame.Angles(0, angle, 0)
            * CFrame.new(0, 0.55, dist)
        cam.CFrame = CFrame.lookAt(orbit.Position, focus, Vector3.yAxis)
        updateEspOverlay()
    end)

    Library.CharPreview = {
        Frame = panel,
        Width = PREVIEW_W,
        Rebuild = rebuild,
        SetVisible = function(_, v) panel.Visible = v == true end,
    }
    return Library.CharPreview
end

function Library:Window(opts)
    opts = opts or {}
    local title = stripRichText(opts.Name or opts.name or 'Bap Delta')
    local subtitle = opts.Subtitle or 'project delta'
    local width = opts.Width or 720
    local height = opts.Height or 500
    local previewW = 230
    local gap = 10
    Library.PageAmount = opts.Amount or opts.amount or Library.PageAmount or 6

    local parent = getGuiParent()
    local gui = Instance.new('ScreenGui')
    gui.Name = 'BapDeltaUIv2'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 500
    gui.Parent = parent
    Library.ScreenGUI = gui

    local shell = Instance.new('Frame')
    shell.Name = 'Shell'
    shell.AnchorPoint = Vector2.new(0.5, 0.5)
    shell.Position = UDim2.new(0.5, 0, 0.5, 0)
    shell.Size = UDim2.new(0, width + gap + previewW, 0, height)
    shell.BackgroundTransparency = 1
    shell.Visible = false
    shell.ZIndex = 1
    shell.Parent = gui
    Library.Shell = shell

    local root = Instance.new('Frame')
    root.Name = 'Window'
    root.Size = UDim2.new(0, width, 1, 0)
    root.BackgroundColor3 = Theme.bg
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.ZIndex = 2
    root.Parent = shell
    corner(root, 10)
    stroke(root, Theme.stroke, 1)
    Library.Holder = root
    Library._windowRoot = root
    Library._uiBlurOn = false
    Library._winW = width
    Library._winH = height

    local topLine = Instance.new('Frame')
    topLine.Name = 'topLine'
    topLine.Size = UDim2.new(1, 0, 0, 2)
    topLine.BackgroundColor3 = Theme.accent
    topLine.BorderSizePixel = 0
    topLine.ZIndex = 10
    topLine.Parent = root
    Library.ThemeObjects[#Library.ThemeObjects + 1] = topLine

    local titleBar = Instance.new('Frame')
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundColor3 = Theme.bgDeep
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 3
    titleBar.Parent = root
    makeDraggable(titleBar, shell)

    label(titleBar, { text = title, font = Theme.fontBold, size = 15, color = Theme.text, h = 18, z = 4 }).Position = UDim2.new(0, 16, 0, 8)
    local brandL = titleBar:FindFirstChildOfClass('TextLabel')
    if brandL then brandL.Size = UDim2.new(1, -24, 0, 18) end
    local subL = label(titleBar, { text = subtitle, font = Theme.fontMono, size = 11, color = Theme.textMute, h = 14, z = 4 })
    subL.Position = UDim2.new(0, 16, 0, 26)
    subL.Size = UDim2.new(1, -24, 0, 14)


    local grain = Instance.new('ImageLabel')
    grain.Name = 'Grain'
    grain.BackgroundTransparency = 1
    grain.Size = UDim2.new(1, 0, 1, 0)
    grain.Image = 'rbxassetid://2151741365'
    grain.ImageTransparency = 0.93
    grain.ImageColor3 = Color3.fromRGB(180, 210, 230)
    grain.ScaleType = Enum.ScaleType.Tile
    grain.TileSize = UDim2.new(0, 140, 0, 140)
    grain.ZIndex = 2
    grain.Parent = root

    local sheen = Instance.new('Frame')
    sheen.Name = 'Sheen'
    sheen.BackgroundColor3 = Color3.new(1, 1, 1)
    sheen.BackgroundTransparency = 0.97
    sheen.BorderSizePixel = 0
    sheen.Size = UDim2.new(1, 0, 1, 0)
    sheen.ZIndex = 2
    sheen.Parent = root
    local sheenGrad = Instance.new('UIGradient')
    sheenGrad.Rotation = 110
    sheenGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.45, 1),
        NumberSequenceKeypoint.new(1, 0.35),
    })
    sheenGrad.Parent = sheen

    Library:CreateCharPreview(shell, height, width + gap)

    local body = Instance.new('Frame')
    body.Position = UDim2.new(0, 0, 0, 44)
    body.Size = UDim2.new(1, 0, 1, -44)
    body.BackgroundTransparency = 1
    body.ClipsDescendants = true
    body.ZIndex = 3
    body.Parent = root

    local side = Instance.new('Frame')
    side.Size = UDim2.new(0, 140, 1, 0)
    side.BackgroundColor3 = Theme.bgDeep
    side.BorderSizePixel = 0
    side.ClipsDescendants = true
    side.ZIndex = 4
    side.Parent = body
    local sideSep = Instance.new('Frame')
    sideSep.Size = UDim2.new(0, 1, 1, 0)
    sideSep.Position = UDim2.new(1, -1, 0, 0)
    sideSep.BackgroundColor3 = Theme.strokeSoft
    sideSep.BorderSizePixel = 0
    sideSep.ZIndex = 5
    sideSep.Parent = side

    local nav = Instance.new('Frame')
    nav.BackgroundTransparency = 1
    nav.Position = UDim2.new(0, 0, 0, 10)
    nav.Size = UDim2.new(1, 0, 1, -16)
    nav.ClipsDescendants = true
    nav.ZIndex = 5
    nav.Parent = side
    pad(nav, 0, 10, 8, 10)
    list(nav, 4)

    local content = Instance.new('Frame')
    content.Position = UDim2.new(0, 140, 0, 0)
    content.Size = UDim2.new(1, -140, 1, 0)
    content.BackgroundColor3 = Theme.bg
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.ZIndex = 4
    content.Parent = body


    local CONTENT_W = width - 140
    local COL_GAP = 10
    local COL_PAD_L, COL_PAD_R = 16, 28
    local COL_PAD_Y = 12

    local COL_W = math.floor((CONTENT_W - COL_PAD_L - COL_PAD_R - COL_GAP - 12) / 2)

    local openColorPopups = {}

    local pages, current = {}, nil
    local openDropdowns = {}
    local Window = { Pages = pages, Root = root, Gui = gui, Shell = shell }

    local function closeMenus()
        for _, m in ipairs(openDropdowns) do
            if m and m.Parent then m.Visible = false end
        end
    end

    local function makeSection(secName, parentCol)
        local card = Instance.new('Frame')
        card.Name = secName
        card.BackgroundColor3 = Theme.bgPanel
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.ClipsDescendants = true
        card.ZIndex = 6
        card.Parent = parentCol
        corner(card, 8)
        stroke(card, Theme.strokeSoft, 1)
        card.BackgroundTransparency = 1
        tween(card, { BackgroundTransparency = 0 }, 0.18)

        local head = Instance.new('Frame')
        head.Size = UDim2.new(1, 0, 0, 28)
        head.BackgroundTransparency = 1
        head.ZIndex = 7
        head.Parent = card
        local ha = Instance.new('Frame')
        ha.Size = UDim2.new(0, 3, 0, 12)
        ha.Position = UDim2.new(0, 10, 0.5, -6)
        ha.BackgroundColor3 = Theme.accent
        ha.BorderSizePixel = 0
        ha.ZIndex = 8
        ha.Parent = head
        corner(ha, 2)
        local hl = label(head, { text = string.upper(secName), font = Theme.fontMono, size = 10, color = Theme.textDim, h = 28, z = 8 })
        hl.Position = UDim2.new(0, 20, 0, 0)
        hl.Size = UDim2.new(1, -28, 1, 0)

        local bodySec = Instance.new('Frame')
        bodySec.BackgroundTransparency = 1
        bodySec.Position = UDim2.new(0, 0, 0, 28)
        bodySec.Size = UDim2.new(1, 0, 0, 0)
        bodySec.AutomaticSize = Enum.AutomaticSize.Y
        bodySec.ClipsDescendants = true
        bodySec.ZIndex = 7
        bodySec.Parent = card
        pad(bodySec, 0, 12, 10, 10)
        list(bodySec, 7)

        local Section = {}
        local function row(h)
            local r = Instance.new('Frame')
            r.BackgroundTransparency = 1
            r.Size = UDim2.new(1, 0, 0, h or 26)
            r.ClipsDescendants = true
            r.ZIndex = 8
            r.Parent = bodySec
            return r
        end

        function Section:AddLabel(text)
            local r = row(16)
            label(r, { text = tostring(text), font = Theme.fontMono, size = 10, color = Theme.textMute, h = 16, z = 9 })
            return Section
        end

        function Section:AddToggle(flag, o)
            o = o or {}
            flag = nextFlag(flag)
            local default = o.Default == true
            local cb = o.Callback or function() end
            local TOGGLE_W = 34
            local r = row(26)
            local textLbl = label(r, { text = o.Text or flag, size = 12, color = Theme.text, h = 26, z = 9 })
            textLbl.Size = UDim2.new(1, -(TOGGLE_W + 12), 1, 0)
            local box = Instance.new('TextButton')
            box.AutoButtonColor = false
            box.AnchorPoint = Vector2.new(1, 0.5)
            box.Position = UDim2.new(1, -2, 0.5, 0)
            box.Size = UDim2.new(0, TOGGLE_W, 0, 18)
            box.BackgroundColor3 = default and Theme.accentSoft or Theme.bgDeep
            box.Text = ''
            box.ZIndex = 9
            box.Parent = r
            corner(box, 9)
            local bs = stroke(box, default and Theme.accentDim or Theme.stroke, 1)
            local knob = Instance.new('Frame')
            knob.Size = UDim2.new(0, 12, 0, 12)
            knob.Position = default and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
            knob.BackgroundColor3 = default and Theme.accent or Theme.textDim
            knob.BorderSizePixel = 0
            knob.ZIndex = 10
            knob.Parent = box
            corner(knob, 6)
            local state = { Value = default }
            local function set(v, fire)
                state.Value = v == true
                Library.Flags[flag] = state.Value
                tween(box, { BackgroundColor3 = state.Value and Theme.accentSoft or Theme.bgDeep }, 0.12)
                tween(knob, {
                    Position = state.Value and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
                    BackgroundColor3 = state.Value and Theme.accent or Theme.textDim,
                    Size = UDim2.new(0, 13, 0, 13),
                }, 0.12, Enum.EasingStyle.Back)
                task.delay(0.08, function()
                    if knob.Parent then tween(knob, { Size = UDim2.new(0, 12, 0, 12) }, 0.1) end
                end)
                bs.Color = state.Value and Theme.accentDim or Theme.stroke
                if fire ~= false then task.spawn(cb, state.Value) end
            end
            box.MouseButton1Click:Connect(function() set(not state.Value, true) end)
            function state:Set(v) set(v, true) end
            Library.Flags[flag .. '_obj'] = state
            set(default, false)

            local colorCount = 0
            local toggleApi = state
            function toggleApi:Colorpicker(props)
                props = props or {}
                colorCount += 1
                local sw, gap = 18, 4
                local right = TOGGLE_W + 6 + colorCount * (sw + gap)
                textLbl.Size = UDim2.new(1, -(right + 6), 1, 0)
                Section:AddColorPicker(props.Flag or props.flag, {
                    Default = props.Default or props.default or Color3.new(1, 1, 1),
                    Callback = props.Callback or props.callback,
                    ParentRow = r,
                    InlineOffset = colorCount,
                    ToggleWidth = TOGGLE_W,
                })
                return toggleApi
            end
            function toggleApi:Keybind(props)
                props = props or {}
                return Section:AddKeybind(props.Flag or props.flag, {
                    Text = props.Name or props.name or 'Key',
                    Default = props.Default or props.State or props.default,
                    Mode = props.Mode or props.mode or 'Toggle',
                    Callback = props.Callback or props.callback,
                })
            end
            return toggleApi
        end

        function Section:AddSlider(flag, o)
            o = o or {}
            flag = nextFlag(flag)
            local min, max = o.Min or 0, o.Max or 100
            local rounding = o.Rounding or 0
            local default = tonumber(o.Default) or min
            local cb = o.Callback or function() end
            local wrap = row(38)
            label(wrap, { text = o.Text or flag, size = 12, color = Theme.text, h = 16, z = 9 }).Size = UDim2.new(1, -44, 0, 16)
            local valueL = label(wrap, { text = tostring(default), font = Theme.fontMono, size = 11, color = Theme.accent, h = 16, z = 9, x = Enum.TextXAlignment.Right })
            valueL.Position = UDim2.new(1, -44, 0, 0)
            valueL.Size = UDim2.new(0, 44, 0, 16)
            local track = Instance.new('Frame')
            track.Position = UDim2.new(0, 0, 0, 22)
            track.Size = UDim2.new(1, 0, 0, 6)
            track.BackgroundColor3 = Theme.bgDeep
            track.BorderSizePixel = 0
            track.ZIndex = 9
            track.Parent = wrap
            corner(track, 3)
            local fill = Instance.new('Frame')
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = Theme.accent
            fill.BorderSizePixel = 0
            fill.ZIndex = 10
            fill.Parent = track
            corner(fill, 3)
            local thumb = Instance.new('Frame')
            thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            thumb.Size = UDim2.new(0, 10, 0, 10)
            thumb.Position = UDim2.new(0, 0, 0.5, 0)
            thumb.BackgroundColor3 = Theme.text
            thumb.BorderSizePixel = 0
            thumb.ZIndex = 11
            thumb.Parent = track
            corner(thumb, 5)
            local state = { Value = default }
            local function round(n)
                if rounding <= 0 then return math.floor(n + 0.5) end
                local m = 10 ^ rounding
                return math.floor(n * m + 0.5) / m
            end
            local function set(v, fire, instant)
                v = round(math.clamp(tonumber(v) or min, min, max))
                state.Value = v
                Library.Flags[flag] = v
                local a = (max == min) and 0 or ((v - min) / (max - min))
                valueL.Text = tostring(v)
                if instant then
                    fill.Size = UDim2.new(a, 0, 1, 0)
                    thumb.Position = UDim2.new(a, 0, 0.5, 0)
                else

                    tween(thumb, { Position = UDim2.new(a, 0, 0.5, 0) }, 0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    tween(fill, { Size = UDim2.new(a, 0, 1, 0) }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end
                if fire ~= false then task.spawn(cb, v) end
            end
            local dragging = false
            local function from(input)
                local rel = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
                set(min + (max - min) * math.clamp(rel, 0, 1), true, false)
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    tween(thumb, { Size = UDim2.new(0, 14, 0, 14) }, 0.12, Enum.EasingStyle.Back)
                    from(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
                    dragging = false
                    tween(thumb, { Size = UDim2.new(0, 10, 0, 10) }, 0.12)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then from(input) end
            end)
            function state:Set(v) set(v, true, false) end
            set(default, false, true)
            Library.Flags[flag .. '_obj'] = state
            return state
        end

        function Section:AddDropdown(flag, o)
            o = o or {}
            flag = nextFlag(flag)
            local values = o.Values or { 'A' }
            local default = o.Default or values[1]
            local cb = o.Callback or function() end
            local wrap = row(46)
            label(wrap, { text = o.Text or flag, size = 12, color = Theme.text, h = 16, z = 9 })
            local btn = Instance.new('TextButton')
            btn.AutoButtonColor = false
            btn.Position = UDim2.new(0, 0, 0, 18)
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.BackgroundColor3 = Theme.bgDeep
            btn.Text = ''
            btn.ZIndex = 9
            btn.Parent = wrap
            corner(btn, 6)
            stroke(btn, Theme.stroke, 1)
            local valueL = label(btn, { text = tostring(default), size = 12, color = Theme.text, h = 26, z = 10 })
            valueL.Position = UDim2.new(0, 8, 0, 0)
            valueL.Size = UDim2.new(1, -26, 1, 0)
            local chev = label(btn, { text = '▾', size = 11, color = Theme.textMute, h = 26, z = 10, x = Enum.TextXAlignment.Center })
            chev.AnchorPoint = Vector2.new(1, 0)
            chev.Position = UDim2.new(1, -4, 0, 0)
            chev.Size = UDim2.new(0, 16, 1, 0)

            local menu = Instance.new('Frame')
            menu.Visible = false
            menu.BackgroundColor3 = Theme.bgPanel
            menu.BorderSizePixel = 0
            menu.ZIndex = 90
            menu.ClipsDescendants = true
            menu.Parent = gui
            corner(menu, 6)
            stroke(menu, Theme.stroke, 1)
            pad(menu, 4, 4, 4, 4)
            list(menu, 2)
            openDropdowns[#openDropdowns + 1] = menu

            local state = { Value = default }
            local function place()
                menu.Position = UDim2.new(0, btn.AbsolutePosition.X, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 4)
                menu.Size = UDim2.new(0, btn.AbsoluteSize.X, 0, math.min(148, #values * 26 + 8))
            end
            local function set(v, fire)
                state.Value = v
                Library.Flags[flag] = v
                valueL.Text = tostring(v)
                menu.Visible = false
                tween(chev, { Rotation = 0 }, 0.12)
                if fire ~= false then task.spawn(cb, v) end
            end
            local function rebuildOptions(listValues)
                values = listValues or values
                for _, child in ipairs(menu:GetChildren()) do
                    if child:IsA('TextButton') then child:Destroy() end
                end
                for _, v in ipairs(values) do
                    local opt = Instance.new('TextButton')
                    opt.AutoButtonColor = false
                    opt.Size = UDim2.new(1, 0, 0, 24)
                    opt.BackgroundColor3 = Theme.bgDeep
                    opt.Text = tostring(v)
                    opt.Font = Theme.font
                    opt.TextSize = 12
                    opt.TextColor3 = Theme.text
                    opt.ZIndex = 91
                    opt.Parent = menu
                    corner(opt, 5)
                    opt.MouseEnter:Connect(function()
                        tween(opt, { BackgroundColor3 = Theme.bgHover, TextColor3 = Theme.accent }, 0.1)
                    end)
                    opt.MouseLeave:Connect(function()
                        tween(opt, { BackgroundColor3 = Theme.bgDeep, TextColor3 = Theme.text }, 0.1)
                    end)
                    opt.MouseButton1Click:Connect(function() set(v, true) end)
                end
            end
            rebuildOptions(values)
            btn.MouseButton1Click:Connect(function()
                local open = not menu.Visible
                closeMenus()
                if open then
                    place()
                    menu.Visible = true
                    menu.Size = UDim2.new(0, btn.AbsoluteSize.X, 0, 0)
                    tween(menu, { Size = UDim2.new(0, btn.AbsoluteSize.X, 0, math.min(148, #values * 26 + 8)) }, 0.14, Enum.EasingStyle.Back)
                    tween(chev, { Rotation = 180 }, 0.12)
                end
            end)
            function state:Set(v) set(v, true) end
            function state:Refresh(listValues)
                rebuildOptions(listValues or {})
                if #values > 0 then
                    local keep = false
                    for _, v in ipairs(values) do
                        if v == state.Value then keep = true break end
                    end
                    if not keep then set(values[1], false) end
                end
            end
            set(default, false)
            Library.Flags[flag .. '_obj'] = state
            Library.Flags[flag .. '_LIST'] = state
            return state
        end

        function Section:AddKeybind(flag, o)
            o = o or {}
            flag = nextFlag(flag)
            local mode = o.Mode or 'Toggle'
            local cb = o.Callback or function() end
            local key = resolveKey(o.Default) or resolveKey('E')
            local r = row(26)
            label(r, { text = o.Text or 'Key', size = 12, color = Theme.text, h = 26, z = 9 }).Size = UDim2.new(1, -70, 1, 0)
            local btn = Instance.new('TextButton')
            btn.AutoButtonColor = false
            btn.AnchorPoint = Vector2.new(1, 0.5)
            btn.Position = UDim2.new(1, -1, 0.5, 0)
            btn.Size = UDim2.new(0, 64, 0, 22)
            btn.BackgroundColor3 = Theme.bgDeep
            btn.Font = Theme.fontMono
            btn.TextSize = 10
            btn.TextColor3 = Theme.accent
            btn.TextTruncate = Enum.TextTruncate.AtEnd
            btn.ClipsDescendants = true
            btn.ZIndex = 9
            btn.Parent = r
            corner(btn, 6)
            local st = stroke(btn, Theme.accentDim, 1)
            st.Transparency = 0.35

            local active = (mode == 'Always')
            local state = {
                Value = key,
                Mode = mode,
                Listening = false,
                ArmedAt = 0,
                Active = active,
            }

            Library.Flags[flag] = active
            Library.Flags[flag .. '_KEY'] = key
            Library.Flags[flag .. '_KEY STATE'] = mode

            local function displayKey(k)
                if not k then return 'None' end
                return prettyKey(Library.Keys[k] or tostring(k):gsub('Enum%.KeyCode%.', ''):gsub('Enum%.UserInputType%.', ''))
            end
            btn.Text = displayKey(key)

            local function setActive(on, fire)
                active = on == true
                state.Active = active
                Library.Flags[flag] = active
                if fire ~= false then task.spawn(cb, active) end
            end

            local function applyKey(newKey)
                if not newKey then return end
                key = newKey
                state.Value = key
                Library.Flags[flag .. '_KEY'] = key
                btn.Text = displayKey(key)
                btn.TextColor3 = Theme.accent
                state.Listening = false
                tween(btn, { BackgroundColor3 = Theme.bgDeep }, 0.12)
                st.Transparency = 0.35
            end

            btn.MouseEnter:Connect(function()
                if not state.Listening then tween(btn, { BackgroundColor3 = Theme.bgHover }, 0.1) end
            end)
            btn.MouseLeave:Connect(function()
                if not state.Listening then tween(btn, { BackgroundColor3 = Theme.bgDeep }, 0.1) end
            end)
            btn.MouseButton1Click:Connect(function()
                state.Listening = true
                state.ArmedAt = tick()
                btn.Text = '...'
                btn.TextColor3 = Theme.textDim
                tween(btn, { BackgroundColor3 = Theme.accentSoft }, 0.12)
                st.Transparency = 0
            end)

            -- Right-click cycles Hold / Toggle / Always (Linoria-style)
            btn.MouseButton2Click:Connect(function()
                local order = { 'Hold', 'Toggle', 'Always' }
                local idx = 1
                for i, m in ipairs(order) do
                    if m == mode then idx = i break end
                end
                local nextMode = order[(idx % #order) + 1]
                state:Set(nextMode)
                btn.Text = displayKey(key) .. ' [' .. nextMode:sub(1, 1) .. ']'
                task.delay(0.85, function()
                    if not state.Listening then
                        btn.Text = displayKey(key)
                    end
                end)
            end)

            local function isKeyDownNow()
                if typeof(key) ~= 'EnumItem' then return false end
                if key.EnumType == Enum.KeyCode then
                    local ok, down = pcall(function()
                        return UserInputService:IsKeyDown(key)
                    end)
                    return ok and down == true
                end
                if key.EnumType == Enum.UserInputType then
                    local ok, down = pcall(function()
                        return UserInputService:IsMouseButtonPressed(key)
                    end)
                    return ok and down == true
                end
                return false
            end

            Library:Connection(UserInputService.InputBegan, function(input, gp)
                if state.Listening then
                    if tick() - (state.ArmedAt or 0) < 0.18 then return end
                    local name = keyNameFromInput(input)
                    if not name then return end
                    applyKey(resolveKey(name) or (input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode) or input.UserInputType)
                    return
                end
                if not keyMatches(key, input) then return end
                if mode == 'Hold' then
                    setActive(true, true)
                elseif mode == 'Toggle' then
                    setActive(not active, true)
                end
            end)
            Library:Connection(UserInputService.InputEnded, function(input)
                if state.Listening then
                    local uit = input.UserInputType
                    local isMouse = EXTRA_MOUSE[uit] ~= nil
                    if not isMouse then
                        local ok, n = pcall(function() return uit.Name end)
                        isMouse = ok and type(n) == 'string' and n:match('^MouseButton%d+$') ~= nil
                    end
                    if isMouse and tick() - (state.ArmedAt or 0) >= 0.18 then
                        local name = keyNameFromInput(input)
                        if name then applyKey(resolveKey(name) or uit) end
                    end
                    return
                end
                if mode == 'Hold' and keyMatches(key, input) then
                    setActive(false, true)
                end
            end)

            function state:Set(v)
                if type(v) == 'string' and (v == 'Hold' or v == 'Toggle' or v == 'Always') then
                    mode = v
                    state.Mode = mode
                    Library.Flags[flag .. '_KEY STATE'] = mode
                    if mode == 'Always' then setActive(true, true)
                    elseif mode == 'Hold' then setActive(false, false) end
                    return
                end
                local resolved = resolveKey(v)
                if resolved then applyKey(resolved) end
            end
            function state:GetState()
                if mode == 'Always' then
                    return true
                end
                if mode == 'Hold' then
                    local down = isKeyDownNow()
                    if down ~= active then
                        setActive(down, false)
                    end
                    return down
                end
                return active == true
            end

            if mode == 'Always' then setActive(true, false) end
            Library.Flags[flag .. '_obj'] = state
            return state
        end

        function Section:AddColorPicker(flag, o)
            o = o or {}
            flag = nextFlag(flag)
            local default = o.Default or Theme.accent
            local cb = o.Callback or function() end
            local parentRow = o.ParentRow
            local inlineOffset = tonumber(o.InlineOffset) or 0
            local toggleW = tonumber(o.ToggleWidth) or 0
            local r
            local swatch = Instance.new('TextButton')
            swatch.AutoButtonColor = false
            swatch.BackgroundColor3 = default
            swatch.Text = ''
            swatch.ZIndex = 11
            if parentRow then
                r = parentRow
                local sw, gap = 18, 4
                swatch.AnchorPoint = Vector2.new(1, 0.5)
                swatch.Position = UDim2.new(1, -(toggleW + 6 + (inlineOffset - 1) * (sw + gap)), 0.5, 0)
                swatch.Size = UDim2.new(0, sw, 0, 18)
            else
                r = row(26)
                local title = o.Text
                if title and title ~= '' then
                    label(r, { text = title, size = 12, color = Theme.text, h = 26, z = 9 }).Size = UDim2.new(1, -36, 1, 0)
                end
                swatch.AnchorPoint = Vector2.new(1, 0.5)
                swatch.Position = UDim2.new(1, -1, 0.5, 0)
                swatch.Size = UDim2.new(0, 28, 0, 18)
                swatch.ZIndex = 9
            end
            swatch.Parent = r
            corner(swatch, 5)
            stroke(swatch, Theme.stroke, 1)

            local popup = Instance.new('Frame')
            popup.Visible = false
            popup.BackgroundColor3 = Theme.bgPanel
            popup.BorderSizePixel = 0
            popup.Size = UDim2.new(0, 178, 0, 158)
            popup.ZIndex = 95
            popup.Parent = gui
            corner(popup, 8)
            stroke(popup, Theme.stroke, 1)
            openColorPopups[#openColorPopups + 1] = { popup = popup, swatch = swatch }

            local sat = Instance.new('ImageButton')
            sat.AutoButtonColor = false
            sat.Position = UDim2.new(0, 10, 0, 10)
            sat.Size = UDim2.new(0, 124, 0, 104)
            sat.BackgroundColor3 = Color3.fromHSV(0.55, 1, 1)
            sat.Image = ''
            sat.ClipsDescendants = true
            sat.ZIndex = 96
            sat.Parent = popup
            corner(sat, 6)
            local white = Instance.new('Frame')
            white.Size = UDim2.new(1, 0, 1, 0)
            white.BackgroundColor3 = Color3.new(1, 1, 1)
            white.BorderSizePixel = 0
            white.ZIndex = 97
            white.Parent = sat
            corner(white, 6)
            local wg = Instance.new('UIGradient')
            wg.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            wg.Parent = white
            local black = Instance.new('Frame')
            black.Size = UDim2.new(1, 0, 1, 0)
            black.BackgroundColor3 = Color3.new(0, 0, 0)
            black.BorderSizePixel = 0
            black.ZIndex = 98
            black.Parent = sat
            corner(black, 6)
            local bg = Instance.new('UIGradient')
            bg.Rotation = 90
            bg.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
            bg.Parent = black


            local satDot = Instance.new('Frame')
            satDot.AnchorPoint = Vector2.new(0.5, 0.5)
            satDot.Size = UDim2.new(0, 12, 0, 12)
            satDot.BackgroundColor3 = Color3.new(1, 1, 1)
            satDot.BorderSizePixel = 0
            satDot.ZIndex = 100
            satDot.Parent = sat
            corner(satDot, 6)
            local satDotStroke = stroke(satDot, Color3.new(0, 0, 0), 1.5)

            local hue = Instance.new('TextButton')
            hue.AutoButtonColor = false
            hue.Text = ''
            hue.Position = UDim2.new(0, 144, 0, 10)
            hue.Size = UDim2.new(0, 22, 0, 104)
            hue.BackgroundColor3 = Color3.new(1, 1, 1)
            hue.BorderSizePixel = 0
            hue.ClipsDescendants = false
            hue.ZIndex = 96
            hue.Parent = popup
            corner(hue, 5)
            local hg = Instance.new('UIGradient')
            hg.Rotation = 90
            hg.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(0.2, Color3.fromHSV(0.2, 1, 1)),
                ColorSequenceKeypoint.new(0.4, Color3.fromHSV(0.4, 1, 1)),
                ColorSequenceKeypoint.new(0.6, Color3.fromHSV(0.6, 1, 1)),
                ColorSequenceKeypoint.new(0.8, Color3.fromHSV(0.8, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
            })
            hg.Parent = hue


            local hueDot = Instance.new('Frame')
            hueDot.AnchorPoint = Vector2.new(0.5, 0.5)
            hueDot.Size = UDim2.new(1, 6, 0, 4)
            hueDot.Position = UDim2.new(0.5, 0, 0, 0)
            hueDot.BackgroundColor3 = Color3.new(1, 1, 1)
            hueDot.BorderSizePixel = 0
            hueDot.ZIndex = 100
            hueDot.Parent = hue
            corner(hueDot, 2)
            stroke(hueDot, Color3.new(0, 0, 0), 1)

            local h, sVal, vVal = default:ToHSV()
            local state = { Value = default }
            local function syncDots()
                satDot.Position = UDim2.new(sVal, 0, 1 - vVal, 0)
                hueDot.Position = UDim2.new(0.5, 0, h, 0)
                local c = Color3.fromHSV(h, sVal, vVal)
                satDot.BackgroundColor3 = c
                satDotStroke.Color = (vVal > 0.55 and sVal < 0.35) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
            end
            local function apply(fire)
                local c = Color3.fromHSV(h, sVal, vVal)
                state.Value = c
                Library.Flags[flag] = c
                swatch.BackgroundColor3 = c
                sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                syncDots()
                if fire ~= false then task.spawn(cb, c) end
            end
            local function satInput(input)
                local relX = math.clamp((input.Position.X - sat.AbsolutePosition.X) / math.max(sat.AbsoluteSize.X, 1), 0, 1)
                local relY = math.clamp((input.Position.Y - sat.AbsolutePosition.Y) / math.max(sat.AbsoluteSize.Y, 1), 0, 1)
                sVal, vVal = relX, 1 - relY
                apply(true)
            end
            local function hueInput(input)
                local relY = math.clamp((input.Position.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
                h = relY
                apply(true)
            end
            local draggingSat, draggingHue = false, false
            sat.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSat = true
                    satInput(input)
                end
            end)
            hue.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingHue = true
                    hueInput(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSat, draggingHue = false, false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if draggingSat then satInput(input) end
                if draggingHue then hueInput(input) end
            end)

            local function closePopup()
                popup.Visible = false
            end
            local function openPopup()
                for _, entry in ipairs(openColorPopups) do
                    if entry.popup ~= popup then entry.popup.Visible = false end
                end
                popup.Visible = true
                popup.Position = UDim2.new(0, swatch.AbsolutePosition.X - 148, 0, swatch.AbsolutePosition.Y + 24)
                popup.Size = UDim2.new(0, 178, 0, 0)
                syncDots()
                tween(popup, { Size = UDim2.new(0, 178, 0, 158) }, 0.16, Enum.EasingStyle.Back)
            end

            swatch.MouseButton1Click:Connect(function()
                if popup.Visible then closePopup() else openPopup() end
            end)

            function state:Set(c)
                h, sVal, vVal = c:ToHSV()
                apply(true)
            end
            apply(false)
            Library.Flags[flag .. '_obj'] = state
            return state
        end

        function Section:AddButton(o)
            o = o or {}
            local btn = Instance.new('TextButton')
            btn.AutoButtonColor = false
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Theme.bgDeep
            btn.Font = Theme.font
            btn.TextSize = 12
            btn.TextColor3 = Theme.text
            btn.Text = o.Text or 'Button'
            btn.ZIndex = 8
            btn.Parent = bodySec
            corner(btn, 6)
            stroke(btn, Theme.stroke, 1)
            btn.MouseEnter:Connect(function()
                tween(btn, { BackgroundColor3 = Theme.bgHover, TextColor3 = Theme.accent }, 0.1)
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, { BackgroundColor3 = Theme.bgDeep, TextColor3 = Theme.text }, 0.1)
            end)
            btn.MouseButton1Click:Connect(function()
                tween(btn, { BackgroundColor3 = Theme.accentSoft }, 0.08)
                task.delay(0.1, function()
                    if btn.Parent then tween(btn, { BackgroundColor3 = Theme.bgHover }, 0.1) end
                end)
                task.spawn(o.Callback or function() end)
            end)
            return Section
        end

        function Section:AddInput(flag, o)
            o = o or {}
            flag = nextFlag(flag)
            local wrap = row(46)
            label(wrap, { text = o.Text or flag, size = 12, color = Theme.text, h = 16, z = 9 })
            local box = Instance.new('TextBox')
            box.Position = UDim2.new(0, 0, 0, 18)
            box.Size = UDim2.new(1, 0, 0, 26)
            box.BackgroundColor3 = Theme.bgDeep
            box.Font = Theme.fontMono
            box.TextSize = 11
            box.TextColor3 = Theme.text
            box.PlaceholderText = o.Placeholder or ''
            box.PlaceholderColor3 = Theme.textMute
            box.Text = tostring(o.Default or '')
            box.ClearTextOnFocus = false
            box.ZIndex = 9
            box.Parent = wrap
            corner(box, 6)
            stroke(box, Theme.stroke, 1)
            local cb = o.Callback or function() end
            Library.Flags[flag] = box.Text
            local state = { Value = box.Text }
            local function commit()
                state.Value = box.Text
                Library.Flags[flag] = box.Text
                task.spawn(cb, box.Text)
            end
            box.FocusLost:Connect(commit)
            function state:Set(v)
                box.Text = tostring(v or '')
                commit()
            end
            Library.Flags[flag .. '_obj'] = state
            return state
        end


        function Section:Toggle(props)
            props = props or {}
            return Section:AddToggle(props.Flag or props.flag, {
                Text = props.Name or props.name,
                Default = props.Default or props.State or props.default or false,
                Callback = props.Callback or props.callback,
            })
        end
        function Section:Slider(props)
            props = props or {}
            return Section:AddSlider(props.Flag or props.flag, {
                Text = props.Name or props.name,
                Min = props.Min or props.min or 0,
                Max = props.Max or props.max or 100,
                Default = props.Default or props.default or props.Min or 0,
                Rounding = props.Rounding or decimalsToRounding(props.Decimals),
                Callback = props.Callback or props.callback,
            })
        end
        function Section:List(props)
            props = props or {}
            return Section:AddDropdown(props.Flag or props.flag, {
                Text = props.Name or props.name,
                Values = props.Options or props.Values or {},
                Default = props.Default or props.State,
                Multi = props.Multi,
                Callback = props.Callback or props.callback,
            })
        end
        function Section:Button(props)
            props = props or {}
            return Section:AddButton({
                Text = props.Name or props.name or 'Button',
                Callback = props.Callback or props.callback or props.Func,
            })
        end
        function Section:Textbox(props)
            props = props or {}
            return Section:AddInput(props.Flag or props.flag, {
                Text = props.Name or props.name,
                Default = props.Default or props.default or '',
                Placeholder = props.Placeholder,
                Callback = props.Callback or props.callback,
            })
        end
        function Section:Keybind(props)
            props = props or {}
            return Section:AddKeybind(props.Flag or props.flag, {
                Text = props.Name or props.name or 'Key',
                Default = props.Default or props.State or props.default,
                Mode = props.Mode or props.mode or 'Toggle',
                Callback = props.Callback or props.callback,
            })
        end
        function Section:Colorpicker(props)
            props = props or {}
            return Section:AddColorPicker(props.Flag or props.flag, {
                Text = props.Name or props.name or 'Color',
                Default = props.Default or props.default or Theme.accent,
                Callback = props.Callback or props.callback,
            })
        end
        function Section:Label(props)
            local text = props
            if type(props) == 'table' then text = props.Name or props.Text or props.name or '' end
            Section:AddLabel(text)
            return Section
        end
        function Section:Divider()
            return Section
        end

        return Section
    end

    local function makeColumns(parent)
        local holder = Instance.new('Frame')
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(1, 0, 1, 0)
        holder.ClipsDescendants = true
        holder.ZIndex = 6
        holder.Parent = parent
        pad(holder, COL_PAD_Y, COL_PAD_R, COL_PAD_Y, COL_PAD_L)

        local columns = Instance.new('Frame')
        columns.BackgroundTransparency = 1
        columns.Size = UDim2.new(1, 0, 1, 0)
        columns.ClipsDescendants = true
        columns.ZIndex = 7
        columns.Parent = holder

        local leftCol = Instance.new('Frame')
        leftCol.BackgroundTransparency = 1
        leftCol.Position = UDim2.new(0, 0, 0, 0)
        leftCol.Size = UDim2.new(0, COL_W, 1, 0)
        leftCol.ClipsDescendants = true
        leftCol.ZIndex = 7
        leftCol.Parent = columns
        list(leftCol, 10)

        local rightCol = Instance.new('Frame')
        rightCol.BackgroundTransparency = 1
        rightCol.Position = UDim2.new(0, COL_W + COL_GAP, 0, 0)
        rightCol.Size = UDim2.new(0, COL_W, 1, 0)
        rightCol.ClipsDescendants = true
        rightCol.ZIndex = 7
        rightCol.Parent = columns
        list(rightCol, 10)

        return leftCol, rightCol
    end

    function Window:Page(pageOpts)
        pageOpts = pageOpts or {}
        local pageName = pageOpts.Name or 'Page'
        local icon = pageOpts.Icon or '·'

        local pageBtn = Instance.new('TextButton')
        pageBtn.Size = UDim2.new(1, 0, 0, 32)
        pageBtn.BackgroundColor3 = Theme.bgDeep
        pageBtn.AutoButtonColor = false
        pageBtn.Text = ''
        pageBtn.ZIndex = 6
        pageBtn.Parent = nav
        corner(pageBtn, 7)
        local accentBar = Instance.new('Frame')
        accentBar.Size = UDim2.new(0, 2, 0, 14)
        accentBar.Position = UDim2.new(0, 6, 0.5, -7)
        accentBar.BackgroundColor3 = Theme.accent
        accentBar.BorderSizePixel = 0
        accentBar.Visible = false
        accentBar.ZIndex = 7
        accentBar.Parent = pageBtn
        corner(accentBar, 2)
        local iconL = label(pageBtn, { text = icon, font = Theme.fontMono, size = 13, color = Theme.textMute, h = 32, z = 7, x = Enum.TextXAlignment.Center })
        iconL.Position = UDim2.new(0, 10, 0, 0)
        iconL.Size = UDim2.new(0, 18, 1, 0)
        iconL.TextTruncate = Enum.TextTruncate.None
        local nameL = label(pageBtn, { text = pageName, size = 12, color = Theme.textDim, h = 32, z = 7 })
        nameL.Position = UDim2.new(0, 32, 0, 0)
        nameL.Size = UDim2.new(1, -40, 1, 0)

        local pageRoot = Instance.new('Frame')
        pageRoot.Size = UDim2.new(1, 0, 1, 0)
        pageRoot.BackgroundTransparency = 1
        pageRoot.Visible = false
        pageRoot.ClipsDescendants = true
        pageRoot.ZIndex = 5
        pageRoot.Parent = content

        local subBar = Instance.new('Frame')
        subBar.Size = UDim2.new(1, 0, 0, 34)
        subBar.BackgroundColor3 = Theme.bgDeep
        subBar.BorderSizePixel = 0
        subBar.Visible = false
        subBar.ClipsDescendants = true
        subBar.ZIndex = 6
        subBar.Parent = pageRoot
        local subNav = Instance.new('Frame')
        subNav.BackgroundTransparency = 1
        subNav.Size = UDim2.new(1, 0, 1, 0)
        subNav.ZIndex = 7
        subNav.Parent = subBar
        pad(subNav, 5, 10, 5, 10)
        local subLay = list(subNav, 6, Enum.FillDirection.Horizontal)
        subLay.VerticalAlignment = Enum.VerticalAlignment.Center

        local pageBody = Instance.new('Frame')
        pageBody.Size = UDim2.new(1, 0, 1, 0)
        pageBody.BackgroundTransparency = 1
        pageBody.ClipsDescendants = true
        pageBody.ZIndex = 6
        pageBody.Parent = pageRoot

        local Page = { Name = pageName, Open = false, SubTabs = {}, _currentSub = nil }
        local usingSubs = false
        local defaultLeft, defaultRight = makeColumns(pageBody)

        local function setPageBodyOffset(has)
            subBar.Visible = has
            pageBody.Position = has and UDim2.new(0, 0, 0, 34) or UDim2.new()
            pageBody.Size = has and UDim2.new(1, 0, 1, -34) or UDim2.new(1, 0, 1, 0)
        end

        local function setActive(state)
            Page.Open = state
            pageRoot.Visible = state
            accentBar.Visible = state
            if state then
                pageBtn.BackgroundColor3 = Theme.bgActive
                nameL.TextColor3 = Theme.text
                iconL.TextColor3 = Theme.text
                pageRoot.BackgroundTransparency = 1
            else
                pageBtn.BackgroundColor3 = Theme.bgDeep
                nameL.TextColor3 = Theme.textDim
                iconL.TextColor3 = Theme.textMute
            end
        end
        function Page:Turn(state) setActive(state == true) end

        pageBtn.MouseEnter:Connect(function()
            if not Page.Open then tween(pageBtn, { BackgroundColor3 = Theme.bgHover }, 0.1) end
        end)
        pageBtn.MouseLeave:Connect(function()
            if not Page.Open then tween(pageBtn, { BackgroundColor3 = Theme.bgDeep }, 0.1) end
        end)
        pageBtn.MouseButton1Click:Connect(function()
            if current == Page then return end
            closeMenus()
            if current then current:Turn(false) end
            current = Page
            Page:Turn(true)

            pageBody.Position = UDim2.new(0, 12, pageBody.Position.Y.Scale, pageBody.Position.Y.Offset)
            tween(pageBody, { Position = UDim2.new(0, 0, pageBody.Position.Y.Scale, pageBody.Position.Y.Offset) }, 0.16)
        end)

        function Page:AddLeftGroupbox(name) return makeSection(name, defaultLeft) end
        function Page:AddRightGroupbox(name) return makeSection(name, defaultRight) end

        function Page:Section(props)
            props = props or {}
            local side = tostring(props.Side or props.side or 'Left'):lower()
            if side == 'right' then
                return Page:AddRightGroupbox(props.Name or props.name or 'Section')
            end
            return Page:AddLeftGroupbox(props.Name or props.name or 'Section')
        end

        function Page:AddSubTab(name)
            if type(name) == 'table' then name = name.Name or name.name or 'Sub' end
            if not usingSubs then
                usingSubs = true
                setPageBodyOffset(true)
                for _, c in ipairs(pageBody:GetChildren()) do c:Destroy() end
            end
            local subBtn = Instance.new('TextButton')
            subBtn.AutoButtonColor = false
            subBtn.AutomaticSize = Enum.AutomaticSize.X
            subBtn.Size = UDim2.new(0, 0, 1, 0)
            subBtn.BackgroundColor3 = Theme.bgPanel
            subBtn.Font = Theme.font
            subBtn.TextSize = 11
            subBtn.TextColor3 = Theme.textDim
            subBtn.Text = '  ' .. name .. '  '
            subBtn.ZIndex = 8
            subBtn.Parent = subNav
            corner(subBtn, 6)

            local holder = Instance.new('Frame')
            holder.Size = UDim2.new(1, 0, 1, 0)
            holder.BackgroundTransparency = 1
            holder.Visible = false
            holder.ClipsDescendants = true
            holder.ZIndex = 7
            holder.Parent = pageBody
            local leftCol, rightCol = makeColumns(holder)
            local Sub = {
                Name = name,
                AddLeftGroupbox = function(_, n) return makeSection(n, leftCol) end,
                AddRightGroupbox = function(_, n) return makeSection(n, rightCol) end,
                Section = function(_, props)
                    props = props or {}
                    local side = tostring(props.Side or props.side or 'Left'):lower()
                    if side == 'right' then
                        return makeSection(props.Name or props.name or 'Section', rightCol)
                    end
                    return makeSection(props.Name or props.name or 'Section', leftCol)
                end,
                SubTab = function(_, props)
                    return Page:AddSubTab(props)
                end,
                _holder = holder,
                _btn = subBtn,
            }
            local function activate()
                if Page._currentSub then
                    Page._currentSub._holder.Visible = false
                    Page._currentSub._btn.BackgroundColor3 = Theme.bgPanel
                    Page._currentSub._btn.TextColor3 = Theme.textDim
                end
                Page._currentSub = Sub
                holder.Visible = true
                holder.Position = UDim2.new(0, 10, 0, 0)
                tween(holder, { Position = UDim2.new() }, 0.14)
                subBtn.BackgroundColor3 = Theme.bgActive
                subBtn.TextColor3 = Theme.accent
            end
            subBtn.MouseButton1Click:Connect(function()
                closeMenus()
                activate()
            end)
            Page.SubTabs[#Page.SubTabs + 1] = Sub
            if not Page._currentSub then activate() end
            return Sub
        end

        function Page:SubTab(props)
            props = props or {}
            return Page:AddSubTab(props.Name or props.name or 'Sub')
        end

        pages[#pages + 1] = Page
        Library.Pages[pageName] = Page
        if not current then
            current = Page
            Page:Turn(true)
        end
        return Page
    end


    function Library:SetOpen(bool)
        local want = bool == true
        Library.Open = want
        if want then
            shell.Visible = true
            shell.Size = UDim2.new(0, (width + gap + previewW) * 0.96, 0, height * 0.96)
            tween(shell, { Size = UDim2.new(0, width + gap + previewW, 0, height) }, 0.22, Enum.EasingStyle.Back)
            if Library.CharPreview then Library.CharPreview:SetVisible(true) end
            if not Library._uiBlurOn then
                Library._uiBlurOn = true
                pushBlur(18)
            end
        else
            tween(shell, { Size = UDim2.new(0, (width + gap + previewW) * 0.96, 0, height * 0.96) }, 0.12)
            task.delay(0.12, function()
                if not Library.Open and shell.Parent then shell.Visible = false end
            end)
            Library._uiBlurOn = false
            clearBlur()
            if Library.CharPreview then Library.CharPreview:SetVisible(false) end
        end
        pcall(function() UserInputService.MouseIconEnabled = not want end)
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Library.UIKey and not gp then
            Library:SetOpen(not Library.Open)
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UserInputService:GetMouseLocation()
            local function hit(guiObj)
                if not guiObj then return false end
                local ap, asz = guiObj.AbsolutePosition, guiObj.AbsoluteSize
                return mouse.X >= ap.X and mouse.X <= ap.X + asz.X
                    and mouse.Y >= ap.Y and mouse.Y <= ap.Y + asz.Y
            end
            for _, entry in ipairs(openColorPopups) do
                local p = entry.popup
                if p and p.Visible and not hit(p) and not hit(entry.swatch) then
                    p.Visible = false
                end
            end
        end
    end)

    return Window
end

function Library:Notify(text, duration, kind)
    if not Library.ScreenGUI then return end
    duration = duration or 2.6
    kind = kind or 'info'
    local accent = Theme.accent
    local kindText = 'info'
    if kind == 'success' then
        accent, kindText = Theme.success, 'success'
    elseif kind == 'warn' then
        accent, kindText = Theme.warn, 'warn'
    elseif kind == 'error' then
        accent, kindText = Theme.danger, 'error'
    elseif kind == 'info' then
        kindText = 'info'
    end

    local hold = Library.ScreenGUI:FindFirstChild('NotifyHost')
    if not hold then
        hold = Instance.new('Frame')
        hold.Name = 'NotifyHost'
        hold.AnchorPoint = Vector2.new(1, 0)
        hold.Position = UDim2.new(1, -16, 0, 16)
        hold.Size = UDim2.new(0, 268, 0, 0)
        hold.AutomaticSize = Enum.AutomaticSize.Y
        hold.BackgroundTransparency = 1
        hold.ZIndex = 400
        hold.Parent = Library.ScreenGUI
        list(hold, 6)
    end

    local height = 52
    local n = Instance.new('Frame')
    n.Size = UDim2.new(1, 0, 0, height)
    n.BackgroundColor3 = Theme.bgDeep
    n.BackgroundTransparency = 0.08
    n.BorderSizePixel = 0
    n.ClipsDescendants = true
    n.ZIndex = 401
    n.Parent = hold
    corner(n, 7)
    local border = stroke(n, Theme.strokeSoft, 1)


    local side = Instance.new('Frame')
    side.Size = UDim2.new(0, 2, 1, 0)
    side.BackgroundColor3 = accent
    side.BorderSizePixel = 0
    side.ZIndex = 402
    side.Parent = n

    local title = label(n, {
        text = kindText,
        font = Theme.fontMono,
        size = 10,
        color = accent,
        h = 12,
        z = 402,
    })
    title.Position = UDim2.new(0, 14, 0, 9)
    title.Size = UDim2.new(1, -28, 0, 12)

    local body = label(n, {
        text = tostring(text),
        size = 12,
        color = Theme.text,
        h = 16,
        z = 402,
    })
    body.Position = UDim2.new(0, 14, 0, 24)
    body.Size = UDim2.new(1, -28, 0, 16)
    body.TextTruncate = Enum.TextTruncate.AtEnd

    local track = Instance.new('Frame')
    track.AnchorPoint = Vector2.new(0, 1)
    track.Position = UDim2.new(0, 0, 1, 0)
    track.Size = UDim2.new(1, 0, 0, 2)
    track.BackgroundColor3 = Theme.bgPanel
    track.BorderSizePixel = 0
    track.ZIndex = 402
    track.Parent = n

    local progress = Instance.new('Frame')
    progress.Size = UDim2.new(1, 0, 1, 0)
    progress.BackgroundColor3 = accent
    progress.BackgroundTransparency = 0.25
    progress.BorderSizePixel = 0
    progress.ZIndex = 403
    progress.Parent = track

    n.BackgroundTransparency = 1
    title.TextTransparency = 1
    body.TextTransparency = 1
    side.BackgroundTransparency = 1
    border.Transparency = 1
    n.Position = UDim2.new(0, 16, 0, 0)

    tween(n, { BackgroundTransparency = 0.08, Position = UDim2.new() }, 0.18)
    tween(title, { TextTransparency = 0 }, 0.18)
    tween(body, { TextTransparency = 0 }, 0.18)
    tween(side, { BackgroundTransparency = 0 }, 0.18)
    tween(border, { Transparency = 0 }, 0.18)
    tween(progress, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if not n.Parent then return end
        tween(n, { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0) }, 0.16)
        tween(title, { TextTransparency = 1 }, 0.16)
        tween(body, { TextTransparency = 1 }, 0.16)
        tween(side, { BackgroundTransparency = 1 }, 0.16)
        tween(border, { Transparency = 1 }, 0.16)
        tween(progress, { BackgroundTransparency = 1 }, 0.16)
        task.wait(0.16)
        n:Destroy()
    end)
end

function Library:Notification(message, duration, _color)
    return Library:Notify(tostring(message), duration or 3, 'info')
end

function Library:SetList(flag, values)
    local obj = Library.Flags[flag .. '_obj'] or Library.Flags[flag .. '_LIST']
    if obj and type(obj.Refresh) == 'function' then
        obj:Refresh(values)
    end
end

function Library:GetConfig()
    local lines = {}
    for index, value in pairs(Library.Flags) do
        if type(index) ~= 'string' then continue end
        if index:match('_obj$') or index:match('_LIST$') then continue end
        local final
        if typeof(value) == 'Color3' then
            local h, s, v = value:ToHSV()
            final = ('rgb(%s,%s,%s,%s)'):format(h, s, v, 1)
        elseif typeof(value) == 'EnumItem' then
            final = ('string(%s)'):format(value.Name)
        elseif typeof(value) == 'boolean' then
            final = ('bool(%s)'):format(tostring(value))
        elseif typeof(value) == 'string' then
            final = ('string(%s)'):format(value)
        elseif typeof(value) == 'number' then
            final = ('number(%s)'):format(value)
        else
            continue
        end
        lines[#lines + 1] = index .. ': ' .. final
    end
    return table.concat(lines, '\n')
end

function Library:LoadConfig(config)
    if type(config) ~= 'string' then return end
    local parsed = {}
    for _, line in ipairs(string.split(config, '\n')) do
        local key, rest = line:match('^%s*([^:]+):%s*(.+)$')
        if key and rest and key ~= 'ConfigConfig_List' then
            key = key:gsub('%s+$', '')
            local value = rest:gsub('\r$', '')
            if value:sub(1, 3) == 'rgb' then
                local parts = string.split(value:sub(5, #value - 1), ',')
                value = parts
            elseif value:sub(1, 4) == 'bool' then
                value = value:sub(6, #value - 1) == 'true'
            elseif value:sub(1, 6) == 'string' then
                value = value:sub(8, #value - 1)
            elseif value:sub(1, 6) == 'number' then
                value = tonumber(value:sub(8, #value - 1))
            end
            parsed[key] = value
        end
    end

    -- Old flag names / Linoria keybind suffix variants -> current names
    local FLAG_ALIASES = {
        AimbotKey = 'AimbotAimKey',
        ManipKey = 'ManipAimKey',
        ['AimbotKey_KEY'] = 'AimbotAimKey_KEY',
        ['AimbotKey_KEY STATE'] = 'AimbotAimKey_KEY STATE',
        ['AimbotKey_KEYSTATE'] = 'AimbotAimKey_KEY STATE',
        ['ManipKey_KEY'] = 'ManipAimKey_KEY',
        ['ManipKey_KEY STATE'] = 'ManipAimKey_KEY STATE',
        ['ManipKey_KEYSTATE'] = 'ManipAimKey_KEY STATE',
        ['AimbotAimKey_KEYSTATE'] = 'AimbotAimKey_KEY STATE',
        ['ManipAimKey_KEYSTATE'] = 'ManipAimKey_KEY STATE',
    }
    for old, new in pairs(FLAG_ALIASES) do
        if parsed[old] ~= nil and parsed[new] == nil then
            parsed[new] = parsed[old]
        end
    end

    local function objFor(flag)
        local direct = Library.Flags[flag .. '_obj']
        if direct then return direct, flag end
        local base = flag:match('^(.+)_KEY STATE$')
            or flag:match('^(.+)_KEYSTATE$')
            or flag:match('^(.+)_KEY$')
        if base and Library.Flags[base .. '_obj'] then
            return Library.Flags[base .. '_obj'], base
        end
        return nil, flag
    end

    local function isKeyStateFlag(flag)
        return flag:match('_KEY STATE$') ~= nil or flag:match('_KEYSTATE$') ~= nil
    end
    local function isKeyFlag(flag)
        return flag:match('_KEY$') ~= nil
    end

    -- Deterministic apply: values -> keys -> modes (so Hold/Always wins last)
    local ordered = {}
    for flag, value in pairs(parsed) do
        local rank = 1
        if isKeyFlag(flag) then
            rank = 2
        elseif isKeyStateFlag(flag) then
            rank = 3
        end
        ordered[#ordered + 1] = { flag = flag, value = value, rank = rank }
    end
    table.sort(ordered, function(a, b)
        if a.rank ~= b.rank then return a.rank < b.rank end
        return a.flag < b.flag
    end)

    for i = 1, #ordered do
        local flag = ordered[i].flag
        local value = ordered[i].value
        local obj = objFor(flag)
        if obj and type(obj.Set) == 'function' then
            if isKeyStateFlag(flag) then
                local mode = tostring(value or '')
                if mode == 'Hold' or mode == 'Toggle' or mode == 'Always' then
                    obj:Set(mode)
                end
            elseif isKeyFlag(flag) then
                obj:Set(resolveKey(value) or value)
            elseif type(value) == 'table' and value[1] and tonumber(value[1]) then
                obj:Set(Color3.fromHSV(tonumber(value[1]) or 0, tonumber(value[2]) or 0, tonumber(value[3]) or 1))
            elseif type(value) == 'boolean' or type(value) == 'number' or type(value) == 'string' or typeof(value) == 'Color3' then
                -- Skip bare bools on keybind objs (Linoria sometimes dumps Toggled as the flag)
                if Library.Flags[flag .. '_KEY'] ~= nil or Library.Flags[flag .. '_KEY STATE'] ~= nil then
                    if type(value) == 'boolean' then
                        Library.Flags[flag] = value
                    else
                        obj:Set(value)
                    end
                else
                    obj:Set(value)
                end
            end
        else
            Library.Flags[flag] = value
        end
    end
end

function Library:Unload()
    clearBlur()
    for _, c in ipairs(Library.Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Library.Connections)
    if Library.ScreenGUI then
        pcall(function() Library.ScreenGUI:Destroy() end)
        Library.ScreenGUI = nil
    end
    Library.Open = false
    Library.Holder = nil
    Library.Shell = nil
    Library.Watermark = nil
    Library.TargetHUD = nil
    Library.SkinBrowser = nil
    Library.CharPreview = nil
end

function Library:PlayLoading(opts)
    opts = opts or {}
    local duration = opts.Duration or 2.2
    local gui = Library.ScreenGUI
    if not gui then return end
    local ownedBlur = false
    if not Library._uiBlurOn then
        pushBlur(26)
        ownedBlur = true
    end

    local overlay = Instance.new('Frame')
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
    overlay.BackgroundTransparency = 0.12
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 800
    overlay.Parent = gui

    local logo = Instance.new('ImageLabel')
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0.5, 0, 0.38, 0)
    logo.Size = UDim2.new(0, 0, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Image = LOGO_IMAGE
    logo.ScaleType = Enum.ScaleType.Fit
    logo.ImageTransparency = 1
    logo.ZIndex = 801
    logo.Parent = overlay

    local title = label(overlay, {
        text = 'BAP DELTA',
        font = Theme.fontBold,
        size = 30,
        color = Theme.text,
        h = 34,
        z = 801,
        x = Enum.TextXAlignment.Center,
    })
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.Position = UDim2.new(0.5, 0, 0.38, 188)
    title.Size = UDim2.new(0, 380, 0, 34)
    title.TextTransparency = 1

    local status = label(overlay, {
        text = 'loading',
        font = Theme.fontMono,
        size = 13,
        color = Theme.textDim,
        h = 16,
        z = 801,
        x = Enum.TextXAlignment.Center,
    })
    status.AnchorPoint = Vector2.new(0.5, 0)
    status.Position = UDim2.new(0.5, 0, 0.38, 228)
    status.Size = UDim2.new(0, 280, 0, 16)

    local barBg = Instance.new('Frame')
    barBg.AnchorPoint = Vector2.new(0.5, 0)
    barBg.Position = UDim2.new(0.5, 0, 0.38, 256)
    barBg.Size = UDim2.new(0, 240, 0, 3)
    barBg.BackgroundColor3 = Theme.bgPanel
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 801
    barBg.Parent = overlay
    corner(barBg, 2)
    local barFill = Instance.new('Frame')
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Theme.accent
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 802
    barFill.Parent = barBg
    corner(barFill, 2)

    tween(logo, { Size = UDim2.new(0, 340, 0, 340), ImageTransparency = 0 }, 0.45, Enum.EasingStyle.Back)
    tween(title, { TextTransparency = 0 }, 0.35)

    local t0 = tick()
    while tick() - t0 < duration do
        local a = math.clamp((tick() - t0) / duration, 0, 1)
        local e = 1 - (1 - a) ^ 3
        barFill.Size = UDim2.new(e, 0, 1, 0)
        status.Text = string.format('loading  %d%%', math.floor(e * 100))
        logo.Position = UDim2.new(0.5, 0, 0.38, math.sin(tick() * 2.4) * 6)
        RunService.RenderStepped:Wait()
    end
    status.Text = 'ready'
    tween(overlay, { BackgroundTransparency = 1 }, 0.3)
    tween(logo, { ImageTransparency = 1, Size = UDim2.new(0, 380, 0, 380) }, 0.3)
    tween(title, { TextTransparency = 1 }, 0.25)
    tween(status, { TextTransparency = 1 }, 0.25)
    tween(barBg, { BackgroundTransparency = 1 }, 0.25)
    tween(barFill, { BackgroundTransparency = 1 }, 0.25)
    task.wait(0.32)
    overlay:Destroy()
    if ownedBlur then
        popBlur()
    end
    if not Library.Open then
        clearBlur()
    elseif Library._uiBlurOn and blurState.effect and blurState.effect.Parent then
        tween(blurState.effect, { Size = 18 }, 0.2)
    end
end

local runDemo = true
pcall(function()
    if getgenv and getgenv().BapDeltaLoadingUI then
        runDemo = false
    end
end)

if runDemo then
Library._demoMode = true
local Window = Library:Window({
    Name = 'Bap Delta',
    Subtitle = 'project delta',
    Width = 700,
    Height = 480,
})

local Aim = Window:Page({ Name = 'Aim', Icon = '◎' })
do
    local Aimbot = Aim:AddSubTab('Aimbot')
    local Manip = Aim:AddSubTab('Manip')
    local Weapon = Aim:AddSubTab('Weapon')
    local AimSet = Aim:AddSubTab('FOV')

    local L = Aimbot:AddLeftGroupbox('Aimbot')
    L:AddToggle('AimbotEnabled', { Text = 'Aimbot', Default = false })
    L:AddDropdown('AimMethod', { Text = 'Method', Values = { 'Silent', 'Camera', 'Both' }, Default = 'Silent' })
    L:AddToggle('VisibleCheck', { Text = 'Visible Check', Default = true })
    L:AddToggle('PerfectPrediction', { Text = 'Prediction', Default = false })
    L:AddKeybind('AimbotKey', { Text = 'Aim Key', Default = 'E' })

    local R = Aimbot:AddRightGroupbox('Extras')
    R:AddSlider('AimSmoothness', { Text = 'Smoothness', Default = 0.25, Min = 0, Max = 1, Rounding = 2 })
    R:AddToggle('AimLine', { Text = 'Aim Line', Default = false })
    R:AddSlider('AimLineThickness', { Text = 'Line Thickness', Default = 1, Min = 0.5, Max = 4, Rounding = 1 })
    R:AddColorPicker('AimLineColor', { Text = 'Line Color', Default = Theme.accent })
    R:AddToggle('SilentAimDebug', { Text = 'Silent Debug', Default = false })

    local ML = Manip:AddLeftGroupbox('Bullet TP')
    ML:AddToggle('BulletTP', { Text = 'Bullet TP', Default = false })
    ML:AddDropdown('BulletTPMode', { Text = 'TP Mode', Values = { 'Normal', 'Instant' }, Default = 'Normal' })
    ML:AddSlider('BulletTPDelayScale', { Text = 'Delay Scale', Default = 1, Min = 0, Max = 2, Rounding = 2 })
    ML:AddSlider('BulletTPMaxDist', { Text = 'Max Distance', Default = 800, Min = 50, Max = 2000, Rounding = 0 })
    ML:AddToggle('BulletTPRequireLOS', { Text = 'Require LOS', Default = false })

    local MR = Manip:AddRightGroupbox('Trigger / TP')
    MR:AddToggle('Triggerbot', { Text = 'Triggerbot', Default = false })
    MR:AddKeybind('TriggerbotKey', { Text = 'Trigger Key', Default = 'MB2' })
    MR:AddToggle('ThirdPerson', { Text = 'Third Person', Default = false })
    MR:AddSlider('ThirdPersonDist', { Text = 'Camera Distance', Default = 8, Min = 2, Max = 20, Rounding = 1 })
    MR:AddKeybind('ManipKey', { Text = 'Manip Key', Default = 'Q' })

    local WL = Weapon:AddLeftGroupbox('Mods')
    WL:AddToggle('NoRecoil', { Text = 'No Recoil', Default = false })
    WL:AddToggle('NoSpread', { Text = 'No Spread', Default = false })
    WL:AddToggle('RapidFire', { Text = 'Rapid Fire', Default = false })
    WL:AddSlider('RapidFireSpeed', { Text = 'Fire Rate', Default = 1.5, Min = 1, Max = 5, Rounding = 2 })
    WL:AddToggle('KnifeRapid', { Text = 'Knife Rapid', Default = false })

    local WR = Weapon:AddRightGroupbox('Ballistics')
    WR:AddToggle('BulletSpeed', { Text = 'Bullet Speed', Default = false })
    WR:AddSlider('BulletSpeedValue', { Text = 'Speed Multi', Default = 2, Min = 1, Max = 10, Rounding = 1 })
    WR:AddToggle('BulletTracers', { Text = 'Tracers', Default = false })
    WR:AddSlider('TracerThickness', { Text = 'Thickness', Default = 0.5, Min = 0.1, Max = 3, Rounding = 2 })
    WR:AddColorPicker('TracerColor', { Text = 'Tracer Color', Default = Theme.accent })

    local SL = AimSet:AddLeftGroupbox('Aim FOV')
    SL:AddToggle('AimbotShowFOV', { Text = 'Show FOV', Default = true })
    SL:AddSlider('AimbotFOVSize', { Text = 'FOV Size', Default = 120, Min = 10, Max = 360, Rounding = 0 })
    SL:AddToggle('AimbotFOVOutline', { Text = 'Outline', Default = true })
    SL:AddColorPicker('AimbotFOVColor', { Text = 'FOV Color', Default = Theme.accent })

    local SR = AimSet:AddRightGroupbox('Manip FOV')
    SR:AddToggle('ManipShowFOV', { Text = 'Show FOV', Default = true })
    SR:AddSlider('ManipFOVSize', { Text = 'FOV Size', Default = 140, Min = 10, Max = 360, Rounding = 0 })
    SR:AddToggle('ManipFOVOutline', { Text = 'Outline', Default = true })
    SR:AddColorPicker('ManipFOVColor', { Text = 'FOV Color', Default = Theme.warn })
end

local ESP = Window:Page({ Name = 'ESP', Icon = '◉' })
do
    local Draw = ESP:AddSubTab('Drawing')
    local Info = ESP:AddSubTab('Info')
    local Extra = ESP:AddSubTab('Extra')

    local L = Draw:AddLeftGroupbox('Player')
    L:AddToggle('ESPEnabled', { Text = 'ESP Enabled', Default = true })
    L:AddToggle('BoxESP', { Text = 'Box', Default = true })
    L:AddToggle('SkeletonESP', { Text = 'Skeleton', Default = false })
    L:AddToggle('ChamsESP', { Text = 'Chams', Default = false })
    L:AddColorPicker('ESPColor', { Text = 'ESP Color', Default = Theme.esp })

    local R = Draw:AddRightGroupbox('Style')
    R:AddDropdown('ChamsMethod', { Text = 'Chams', Values = { 'Highlight', 'Transparent' }, Default = 'Highlight' })
    R:AddToggle('ESPOutline', { Text = 'Outline', Default = true })
    R:AddSlider('ChamsFill', { Text = 'Fill', Default = 0.55, Min = 0, Max = 1, Rounding = 2 })
    R:AddSlider('SkeletonThickness', { Text = 'Skeleton', Default = 1.8, Min = 0.5, Max = 4, Rounding = 1 })
    R:AddSlider('MaxDistance', { Text = 'Max Distance', Default = 1000, Min = 50, Max = 3000, Rounding = 0 })

    local IL = Info:AddLeftGroupbox('Labels')
    IL:AddToggle('NameESP', { Text = 'Names', Default = true })
    IL:AddToggle('DistanceESP', { Text = 'Distance', Default = true })
    IL:AddToggle('HealthTextESP', { Text = 'Health Text', Default = true })
    IL:AddToggle('HealthBarESP', { Text = 'Health Bar', Default = true })
    IL:AddToggle('VisibleESP', { Text = 'Visible Flag', Default = true })

    local IR = Info:AddRightGroupbox('Detector')
    IR:AddToggle('CheaterDetector', { Text = 'Cheater Detector', Default = true })
    IR:AddSlider('CheaterSensitivity', { Text = 'Sensitivity', Default = 50, Min = 0, Max = 100, Rounding = 0 })
    IR:AddColorPicker('CheaterColor', { Text = 'Flag Color', Default = Theme.danger })
    IR:AddToggle('TargetHUD', {
        Text = 'Target HUD',
        Default = true,
        Callback = function(on)
            if Library.TargetHUD then Library.TargetHUD:SetVisible(on) end
        end,
    })

    local EL = Extra:AddLeftGroupbox('Gear')
    EL:AddToggle('HeldWeaponESP', { Text = 'Held Weapon', Default = false })
    EL:AddToggle('WeaponAttachments', { Text = 'Attachments', Default = false })
    EL:AddToggle('BeltESP', { Text = 'Belt', Default = false })
    EL:AddToggle('ViewFullInventory', { Text = 'Full Inventory', Default = true })
    EL:AddKeybind('ViewInventoryKey', { Text = 'Inventory Key', Default = 'G' })

    local ER = Extra:AddRightGroupbox('Items')
    ER:AddToggle('ItemChams', { Text = 'Item Chams', Default = false })
    ER:AddDropdown('ItemChamsMethod', { Text = 'Method', Values = { 'Highlight', 'Transparent' }, Default = 'Highlight' })
    ER:AddSlider('ItemChamsFill', { Text = 'Fill', Default = 0.55, Min = 0, Max = 1, Rounding = 2 })
    ER:AddToggle('HitNotifications', { Text = 'Hit Notifs', Default = false })
    ER:AddColorPicker('ItemChamsColor', { Text = 'Item Color', Default = Theme.warn })
end

local LocalTab = Window:Page({ Name = 'Local', Icon = '◐' })
do
    local Cam = LocalTab:AddSubTab('Camera')
    local View = LocalTab:AddSubTab('Viewmodel')
    local Move = LocalTab:AddSubTab('Movement')
    local Vis = LocalTab:AddSubTab('Visuals')

    local CL = Cam:AddLeftGroupbox('Camera')
    CL:AddToggle('ZoomEnabled', { Text = 'Zoom', Default = false })
    CL:AddSlider('ZoomStrength', { Text = 'Zoom FOV', Default = 25, Min = 5, Max = 70, Rounding = 0 })
    CL:AddKeybind('ZoomKey', { Text = 'Zoom Key', Default = 'C' })
    CL:AddSlider('FOVChanger', { Text = 'FOV', Default = 90, Min = 60, Max = 120, Rounding = 0 })

    local CR = Cam:AddRightGroupbox('Freecam')
    CR:AddToggle('FreecamEnabled', { Text = 'Freecam', Default = false })
    CR:AddKeybind('FreecamKey', { Text = 'Freecam Key', Default = 'V' })
    CR:AddToggle('ThirdPersonLocal', { Text = 'Third Person', Default = false })

    local VL = View:AddLeftGroupbox('Model')
    VL:AddToggle('SmallGun', { Text = 'Small Gun', Default = false })
    VL:AddSlider('SmallGunScale', { Text = 'Gun Scale', Default = 0.5, Min = 0.1, Max = 1, Rounding = 2 })
    VL:AddToggle('RemoveArms', { Text = 'Remove Arms', Default = false })
    VL:AddToggle('SkinChanger', {
        Text = 'Skin Changer',
        Default = false,
        Callback = function(on)
            if Library.SkinBrowser then
                if on then Library.SkinBrowser:Open() else Library.SkinBrowser:Close() end
            end
        end,
    })

    local VR = View:AddRightGroupbox('Offsets')
    VR:AddSlider('ViewmodelX', { Text = 'Offset X', Default = 0, Min = -3, Max = 3, Rounding = 2 })
    VR:AddSlider('ViewmodelY', { Text = 'Offset Y', Default = 0, Min = -3, Max = 3, Rounding = 2 })
    VR:AddSlider('ViewmodelZ', { Text = 'Offset Z', Default = 0, Min = -3, Max = 3, Rounding = 2 })

    local ML = Move:AddLeftGroupbox('Climb / Swim')
    ML:AddToggle('WallClimb', { Text = 'Wall Climb', Default = false })
    ML:AddKeybind('WallClimbKey', { Text = 'Climb Key', Default = 'LeftControl' })
    ML:AddSlider('WallClimbSpeed', { Text = 'Climb Speed', Default = 28, Min = 10, Max = 60, Rounding = 0 })
    ML:AddToggle('Jesus', { Text = 'Jesus', Default = false })

    local MR = Move:AddRightGroupbox('Killmove')
    MR:AddToggle('Killmove', { Text = 'Killmove', Default = false })
    MR:AddDropdown('KillmoveMode', {
        Text = 'Mode',
        Values = { 'Pkill (auto elevate)', 'Depth only' },
        Default = 'Pkill (auto elevate)',
    })
    MR:AddSlider('KillmoveDepth', { Text = 'Depth', Default = 60, Min = 10, Max = 150, Rounding = 0 })

    local XL = Vis:AddLeftGroupbox('World FX')
    XL:AddToggle('AntiVisor', { Text = 'Anti Visor', Default = false })
    XL:AddToggle('NoFog', { Text = 'No Fog', Default = false })
    XL:AddToggle('NoFoliage', { Text = 'No Foliage', Default = false })
    XL:AddToggle('NoShadows', { Text = 'No Shadows', Default = false })
    XL:AddToggle('NoInventoryBlur', { Text = 'No Inv Blur', Default = false })

    local XR = Vis:AddRightGroupbox('Misc FX')
    XR:AddToggle('FakeDagr', { Text = 'Fake Dagr', Default = false })
    XR:AddToggle('AntiMine', { Text = 'Anti Mine', Default = false })
    XR:AddToggle('KeyList', { Text = 'Key List', Default = false })
    XR:AddToggle('AmbientLighting', { Text = 'Ambient', Default = false })
    XR:AddColorPicker('AmbientColor', { Text = 'Ambient Color', Default = Color3.fromRGB(180, 180, 200) })
    XR:AddSlider('AmbientBrightness', { Text = 'Brightness', Default = 1, Min = 0.2, Max = 15, Rounding = 1 })
end

local World = Window:Page({ Name = 'World', Icon = '◈' })
do
    local Main = World:AddSubTab('ESP')
    local Filter = World:AddSubTab('Filter')

    local L = Main:AddLeftGroupbox('Entities')
    L:AddToggle('BossESP', { Text = 'Boss ESP', Default = false })
    L:AddToggle('NPCESP', { Text = 'NPC ESP', Default = false })
    L:AddToggle('CorpseESP', { Text = 'Corpse ESP', Default = false })
    L:AddColorPicker('BossESPColor', { Text = 'Boss Color', Default = Color3.fromRGB(255, 105, 180) })

    local R = Main:AddRightGroupbox('Loot')
    R:AddToggle('MilitaryCrateESP', { Text = 'Military Crates', Default = false })
    R:AddToggle('LootESP', { Text = 'Loot ESP', Default = false })
    R:AddToggle('KeyHole', { Text = 'Key Hole', Default = false })
    R:AddColorPicker('LootESPColor', { Text = 'Loot Color', Default = Color3.fromRGB(255, 210, 90) })

    local FL = Filter:AddLeftGroupbox('Whitelist')
    FL:AddToggle('WhitelistFilter', { Text = 'Friend Whitelist', Default = false })
    FL:AddInput('WhitelistNames', { Text = 'Names', Default = '', Placeholder = 'friend1, friend2' })
    local FR = Filter:AddRightGroupbox('Notes')
    FR:AddLabel('Whitelist hides ESP on friends.')
    FR:AddLabel('Colors are visual-only for now.')
end

local Exploit = Window:Page({ Name = 'Exploit', Icon = '⚡' })
do
    local L = Exploit:AddLeftGroupbox('Movement')
    L:AddToggle('NoSlow', { Text = 'No Slow', Default = false })
    L:AddToggle('OmniSprint', { Text = 'Omni Sprint', Default = false })
    L:AddToggle('NoLegBreak', { Text = 'No Leg Break', Default = false })

    local R = Exploit:AddRightGroupbox('Misc')
    R:AddToggle('AntiKick', { Text = 'Anti Kick', Default = true })
    R:AddToggle('AntiCheatBypass', { Text = 'AC Bypass', Default = true })
    R:AddToggle('NoGunSway', { Text = 'No Gun Sway', Default = false })
    R:AddToggle('InstantScope', { Text = 'Instant Scope', Default = false })
    R:AddToggle('NoScope', { Text = 'No Scope', Default = false })
end

local Config = Window:Page({ Name = 'Config', Icon = '⚙' })
do
    local L = Config:AddLeftGroupbox('Configs')
    L:AddInput('ConfigName', { Text = 'Name', Default = '', Placeholder = 'my config' })
    L:AddDropdown('ConfigList', { Text = 'Saved', Values = { 'default', 'rage', 'legit' }, Default = 'default' })
    L:AddButton({ Text = 'Save' })
    L:AddButton({ Text = 'Load' })

    local R = Config:AddRightGroupbox('Menu')
    R:AddToggle('WatermarkOn', {
        Text = 'Watermark',
        Default = true,
        Callback = function(on)
            if Library.Watermark then Library.Watermark:SetVisible(on) end
        end,
    })
    R:AddDropdown('UIKeySelect', {
        Text = 'Menu Key',
        Values = { 'RightShift', 'Insert', 'RightControl' },
        Default = 'RightShift',
        Callback = function(v)
            Library.UIKey = Enum.KeyCode[v] or Enum.KeyCode.RightShift
        end,
    })
    R:AddColorPicker('AccentPreview', {
        Text = 'Accent',
        Default = Theme.accent,
        Callback = function(c)
            Theme.accent = c
            Library.Accent = c
        end,
    })
    R:AddButton({
        Text = 'Open Skins',
        Callback = function()
            if Library.SkinBrowser then Library.SkinBrowser:Open() end
        end,
    })
    R:AddButton({
        Text = 'Notify Test',
        Callback = function()
            Library:Notify('Config saved successfully', 2.4, 'success')
            task.delay(0.35, function()
                Library:Notify('Aimbot locked · 42m', 2.6, 'info')
            end)
            task.delay(0.7, function()
                Library:Notify('High ping · expect delay', 2.8, 'warn')
            end)
        end,
    })
    R:AddButton({
        Text = 'Destroy UI',
        Callback = function()
            clearBlur()
            if Library.ScreenGUI then Library.ScreenGUI:Destroy() end
        end,
    })
end

Library:CreateWatermark({ Title = 'bap delta' })
Library:CreateTargetHUD({ Visible = true })
Library:CreateSkinBrowser()
if Library.Watermark then Library.Watermark:SetVisible(false) end
if Library.TargetHUD then Library.TargetHUD:SetVisible(false) end

Library:PlayLoading({ Duration = 2.2 })

if Library.Watermark then Library.Watermark:SetVisible(Library.Flags.WatermarkOn ~= false) end
if Library.TargetHUD then Library.TargetHUD:SetVisible(Library.Flags.TargetHUD ~= false) end
Library:SetOpen(true)
Library:Notify('Bap Delta ready', 2)
end

return Library
