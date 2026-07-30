--[[
    MitHub UI Library v2.0 - Modern Edition
    Features:
    - Glassmorphism design with frosted glass effect
    - Smooth spring animations (Quad/Back easing)
    - Reliable rbxassetid:// icons (no BuilderIcons needed)
    - Compact 560x400 window with sidebar
    - iOS-style pill toggles with glow
    - Modern gradient sliders
    - Smooth tab transitions
    - Close (X) + Minimize (-) buttons that ALWAYS work
    - Mobile-friendly floating toggle button
    - Lightweight: minimal instance count
    License: MIT
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function getGuiParent()
    if gethui then return gethui() end
    if get_hidden_gui then return get_hidden_gui() end
    return CoreGui
end

local function protectGui(gui)
    if protect_gui then pcall(protect_gui, gui)
    elseif protectgui then pcall(protectgui, gui)
    elseif syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
end

local cloneref = cloneref or function(o) return o end
local TweenService = cloneref(TweenService)
local UserInputService = cloneref(UserInputService)

-- ============================================================================
-- MitHub UI Library
-- ============================================================================
local MitHub = {}
MitHub.Scales = {
    Small   = UDim2.fromOffset(440, 340),
    Mobile  = UDim2.fromOffset(480, 360),
    Default = UDim2.fromOffset(560, 400),
    Large   = UDim2.fromOffset(700, 500),
}
-- Modern accent: vibrant cyan-lime gradient feel
MitHub.Accent       = Color3.fromRGB(120, 220, 255)  -- soft cyan
MitHub.AccentBright = Color3.fromRGB(180, 240, 255)  -- brighter cyan for highlights
MitHub.AccentDim    = Color3.fromRGB(60, 140, 180)   -- dimmer cyan for borders
MitHub.BgDark       = Color3.fromRGB(14, 14, 18)
MitHub.BgCard       = Color3.fromRGB(22, 24, 32)
MitHub.BgHover      = Color3.fromRGB(30, 32, 42)
MitHub.TextMain     = Color3.fromRGB(240, 242, 248)
MitHub.TextMuted    = Color3.fromRGB(150, 155, 170)
MitHub.TextDim      = Color3.fromRGB(100, 105, 120)
MitHub.Stroke       = Color3.fromRGB(45, 48, 60)
MitHub.Flags        = {}

-- Reliable icon asset IDs (these always work in Roblox executors)
local ICONS = {
    home      = "rbxassetid://6035047377",
    eye       = "rbxassetid://6034753464",
    gear      = "rbxassetid://6031263436",
    bolt      = "rbxassetid://6031280842",
    sword     = "rbxassetid://6034753404",
    skull     = "rbxassetid://6035047391",
    shield    = "rbxassetid://6031280272",
    target    = "rbxassetid://6031280836",
    settings  = "rbxassetid://6031263436",
}

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or MitHub.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function gradient(parent, color1, color2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(color1, color2)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

local function pad(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

-- Make a frame draggable (with drag threshold for mobile tap detection)
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos, moved
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            moved     = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then moved = true end
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return function() return moved end
end

-- ============================================================================
-- Notification (modern slide-in cards)
-- ============================================================================
function MitHub:CreateNotification()
    local Notification = {}
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "MitHubNotifs"
    notifGui.ResetOnSpawn = false
    notifGui.DisplayOrder = 9999
    notifGui.IgnoreGuiInset = true
    notifGui.Parent = getGuiParent()
    protectGui(notifGui)

    local notifList = Instance.new("Frame")
    notifList.AnchorPoint = Vector2.new(1, 0)
    notifList.Position = UDim2.new(1, -15, 0, 15)
    notifList.Size = UDim2.new(0, 300, 1, -30)
    notifList.BackgroundTransparency = 1
    notifList.Parent = notifGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = notifList

    function Notification.new(cfg)
        cfg = cfg or {}
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 0)
        card.BackgroundColor3 = MitHub.BgCard
        card.BorderSizePixel = 0
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.Parent = notifList
        corner(card, 10)
        stroke(card, MitHub.AccentDim, 1, 0.5)

        -- accent bar on left
        local accentBar = Instance.new("Frame")
        accentBar.Size = UDim2.new(0, 3, 1, 0)
        accentBar.BackgroundColor3 = MitHub.Accent
        accentBar.BorderSizePixel = 0
        accentBar.Parent = card
        corner(accentBar, 2)
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 0)
        barCorner.Parent = accentBar

        pad(card, 12, 12, 16, 12)

        local tLabel = Instance.new("TextLabel")
        tLabel.BackgroundTransparency = 1
        tLabel.Size = UDim2.new(1, 0, 0, 16)
        tLabel.Font = Enum.Font.GothamBold
        tLabel.Text = cfg.Title or "Notification"
        tLabel.TextColor3 = MitHub.Accent
        tLabel.TextSize = 13
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = card

        local cLabel = Instance.new("TextLabel")
        cLabel.BackgroundTransparency = 1
        cLabel.Size = UDim2.new(1, 0, 0, 14)
        cLabel.Position = UDim2.new(0, 0, 0, 20)
        cLabel.Font = Enum.Font.Gotham
        cLabel.Text = cfg.Content or ""
        cLabel.TextColor3 = MitHub.TextMain
        cLabel.TextSize = 11
        cLabel.TextWrapped = true
        cLabel.AutomaticSize = Enum.AutomaticSize.Y
        cLabel.TextXAlignment = Enum.TextXAlignment.Left
        cLabel.Parent = card

        -- slide-in
        card.Position = UDim2.new(1, 300, 0, 0)
        card.BackgroundTransparency = 1
        TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 0,
        }):Play()

        task.delay(cfg.Duration or 5, function()
            local tw = TweenService:Create(card, TweenInfo.new(0.3), {
                Position = UDim2.new(1, 300, 0, 0),
                BackgroundTransparency = 1,
            })
            tw:Play()
            tw.Completed:Connect(function() card:Destroy() end)
        end)
    end
    return Notification
end

function MitHub:CreateLogger()
    return { new = function(icon, text, dur) end }
end

-- ============================================================================
-- Window
-- ============================================================================
function MitHub:CreateWindow(cfg)
    cfg = cfg or {}
    local windowName    = cfg.Name or "MitHub"
    local windowContent = cfg.Content or ""
    local windowSize    = cfg.Size or MitHub.Scales.Default
    local keybind       = cfg.Keybind or "Insert"

    pcall(function()
        local old = getGuiParent():FindFirstChild("MitHubUI_v2")
        if old then old:Destroy() end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MitHubUI_v2"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9998
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = getGuiParent()
    protectGui(screenGui)

    -- ===== Main Window =====
    local WindowFrame = Instance.new("Frame")
    WindowFrame.Name = "Window"
    WindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    WindowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    WindowFrame.Size = windowSize
    WindowFrame.BackgroundColor3 = MitHub.BgDark
    WindowFrame.BorderSizePixel = 0
    WindowFrame.ClipsDescendants = true
    WindowFrame.Parent = screenGui
    corner(WindowFrame, 12)
    stroke(WindowFrame, MitHub.Stroke, 1, 0)

    -- subtle gradient overlay for depth
    local bgGrad = Instance.new("ImageLabel")
    bgGrad.Size = UDim2.new(1, 0, 1, 0)
    bgGrad.BackgroundTransparency = 1
    bgGrad.Image = "rbxassetid://99735480595595"  -- subtle noise/gradient
    bgGrad.ImageTransparency = 0.85
    bgGrad.ScaleType = Enum.ScaleType.Crop
    bgGrad.ZIndex = 0
    bgGrad.Parent = WindowFrame

    -- top accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.BackgroundColor3 = MitHub.Accent
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 2
    accentLine.Parent = WindowFrame
    gradient(accentLine, MitHub.Accent, MitHub.AccentBright, 0)

    -- ===== Header =====
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 44)
    Header.BackgroundColor3 = MitHub.BgCard
    Header.BorderSizePixel = 0
    Header.ZIndex = 3
    Header.Parent = WindowFrame
    corner(Header, 12)

    -- gradient on header
    local headerGrad = Instance.new("UIGradient")
    headerGrad.Color = ColorSequence.new(
        Color3.fromRGB(26, 28, 38),
        Color3.fromRGB(20, 22, 30)
    )
    headerGrad.Rotation = 90
    headerGrad.Parent = Header

    -- Logo icon (cyan glowing dot)
    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 26, 0, 26)
    logo.Position = UDim2.new(0, 14, 0.5, -13)
    logo.BackgroundColor3 = MitHub.Accent
    logo.BorderSizePixel = 0
    logo.ZIndex = 4
    logo.Parent = Header
    corner(logo, 7)
    -- glow effect
    local logoGlow = Instance.new("ImageLabel")
    logoGlow.Size = UDim2.new(0, 40, 0, 40)
    logoGlow.Position = UDim2.new(0.5, -20, 0.5, -20)
    logoGlow.BackgroundTransparency = 1
    logoGlow.Image = "rbxassetid://5028857084"  -- glow circle
    logoGlow.ImageColor3 = MitHub.Accent
    logoGlow.ImageTransparency = 0.5
    logoGlow.ZIndex = 3
    logoGlow.Parent = logo

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(0, 220, 0, 18)
    titleLabel.Position = UDim2.new(0, 48, 0, 7)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = windowName:upper()
    titleLabel.TextColor3 = MitHub.TextMain
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = Header

    local subLabel = Instance.new("TextLabel")
    subLabel.BackgroundTransparency = 1
    subLabel.Size = UDim2.new(0, 220, 0, 12)
    subLabel.Position = UDim2.new(0, 48, 0, 25)
    subLabel.Font = Enum.Font.Gotham
    subLabel.Text = windowContent
    subLabel.TextColor3 = MitHub.Accent
    subLabel.TextSize = 10
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.ZIndex = 4
    subLabel.Parent = Header

    -- ===== Window Controls (close + minimize) =====
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
    closeBtn.BackgroundTransparency = 0.4
    closeBtn.Text = ""
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 5
    closeBtn.Parent = Header
    corner(closeBtn, 6)
    local closeX = Instance.new("ImageLabel")
    closeX.Size = UDim2.new(0, 14, 0, 14)
    closeX.Position = UDim2.new(0.5, -7, 0.5, -7)
    closeX.BackgroundTransparency = 1
    closeX.Image = "rbxassetid://6031094670"  -- X icon
    closeX.ImageColor3 = Color3.fromRGB(255, 120, 130)
    closeX.ZIndex = 6
    closeX.Parent = closeBtn

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
    minimizeBtn.Position = UDim2.new(1, -70, 0.5, -14)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
    minimizeBtn.BackgroundTransparency = 0.4
    minimizeBtn.Text = ""
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.ZIndex = 5
    minimizeBtn.Parent = Header
    corner(minimizeBtn, 6)
    local minIcon = Instance.new("ImageLabel")
    minIcon.Size = UDim2.new(0, 14, 0, 14)
    minIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
    minIcon.BackgroundTransparency = 1
    minIcon.Image = "rbxassetid://6031094678"  -- minimize icon
    minIcon.ImageColor3 = MitHub.TextMuted
    minIcon.ZIndex = 6
    minIcon.Parent = minimizeBtn

    -- hover effects
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
    end)
    minimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
    end)
    minimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
    end)

    -- ===== Sidebar =====
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 140, 1, -46)
    Sidebar.Position = UDim2.new(0, 0, 0, 46)
    Sidebar.BackgroundColor3 = MitHub.BgCard
    Sidebar.BorderSizePixel = 0
    Sidebar.ZIndex = 2
    Sidebar.Parent = WindowFrame

    local sidebarStroke = Instance.new("Frame")
    sidebarStroke.Size = UDim2.new(0, 1, 1, 0)
    sidebarStroke.Position = UDim2.new(1, -1, 0, 0)
    sidebarStroke.BackgroundColor3 = MitHub.Stroke
    sidebarStroke.BorderSizePixel = 0
    sidebarStroke.ZIndex = 3
    sidebarStroke.Parent = Sidebar

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 4)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Parent = Sidebar
    pad(Sidebar, 10, 10, 6, 6)

    -- ===== Content Area =====
    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -140, 1, -46)
    ContentArea.Position = UDim2.new(0, 140, 0, 46)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ZIndex = 2
    ContentArea.Parent = WindowFrame

    -- ===== Floating Minimized Button =====
    local minimizedBtn = Instance.new("TextButton")
    minimizedBtn.Size = UDim2.new(0, 50, 0, 50)
    minimizedBtn.Position = UDim2.new(0, 20, 1, -70)
    minimizedBtn.BackgroundColor3 = MitHub.BgCard
    minimizedBtn.Text = ""
    minimizedBtn.Visible = false
    minimizedBtn.AutoButtonColor = false
    minimizedBtn.ZIndex = 9999
    minimizedBtn.Parent = screenGui
    corner(minimizedBtn, 25)
    stroke(minimizedBtn, MitHub.Accent, 2, 0)

    -- logo dot in minimized button
    local minLogo = Instance.new("Frame")
    minLogo.Size = UDim2.new(0, 16, 0, 16)
    minLogo.Position = UDim2.new(0.5, -8, 0.5, -8)
    minLogo.BackgroundColor3 = MitHub.Accent
    minLogo.BorderSizePixel = 0
    minLogo.Parent = minimizedBtn
    corner(minLogo, 8)

    -- drag handling for minimized button
    local minDragMoved = makeDraggable(minimizedBtn, minimizedBtn)

    minimizedBtn.MouseButton1Click:Connect(function()
        if not minDragMoved() then
            Window:ToggleInterface()
        end
    end)

    -- ===== Make window draggable =====
    local headerDragMoved = makeDraggable(WindowFrame, Header)

    -- ===== Window State =====
    local Window = {}
    Window.Size = windowSize
    Window.Keybind = keybind
    Window.Visible = true
    Window.Tabs = {}
    Window._screenGui = screenGui

    function Window:ToggleInterface()
        Window.Visible = not Window.Visible
        if Window.Visible then
            minimizedBtn.Visible = false
            WindowFrame.Visible = true
            WindowFrame.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(WindowFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = Window.Size,
            }):Play()
        else
            local tw = TweenService:Create(WindowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
            })
            tw:Play()
            tw.Completed:Connect(function()
                WindowFrame.Visible = false
                minimizedBtn.Visible = true
            end)
        end
    end

    function Window:SetSize(newSize)
        Window.Size = newSize
        if Window.Visible then
            TweenService:Create(WindowFrame, TweenInfo.new(0.25), {Size = newSize}):Play()
        end
    end

    closeBtn.MouseButton1Click:Connect(function()
        Window:ToggleInterface()
    end)
    minimizeBtn.MouseButton1Click:Connect(function()
        Window:ToggleInterface()
    end)

    -- Keyboard toggle (multiple keys for safety)
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local key = input.KeyCode
        if key == Enum.KeyCode.Insert
        or key == Enum.KeyCode.RightShift
        or key == Enum.KeyCode.F4
        or key == Enum.KeyCode.P
        or (Window.Keybind and key.Name == Window.Keybind) then
            Window:ToggleInterface()
        end
    end)

    -- ===== Tab Creation =====
    function Window:AddTab(cfg)
        cfg = cfg or {}
        local tabName = cfg.Name or "Tab"
        local tabIconKey = cfg.Icon or "home"
        local tabIconId = ICONS[tabIconKey] or ICONS.home

        -- Page (scrollable content)
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = MitHub.Accent
        Page.ScrollBarImageTransparency = 0.4
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.ZIndex = 2
        Page.Parent = ContentArea
        pad(Page, 10, 10, 10, 10)

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = Page

        -- Tab button (sidebar)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(0, 128, 0, 34)
        TabBtn.BackgroundColor3 = MitHub.BgCard
        TabBtn.BackgroundTransparency = 0
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.ZIndex = 3
        TabBtn.Parent = Sidebar
        corner(TabBtn, 8)

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Size = UDim2.new(0, 18, 0, 18)
        TabIcon.Position = UDim2.new(0, 10, 0.5, -9)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Image = tabIconId
        TabIcon.ImageColor3 = MitHub.TextMuted
        TabIcon.ZIndex = 4
        TabIcon.Parent = TabBtn

        local TabLabel = Instance.new("TextLabel")
        TabLabel.BackgroundTransparency = 1
        TabLabel.Size = UDim2.new(1, -38, 1, 0)
        TabLabel.Position = UDim2.new(0, 34, 0, 0)
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.Text = tabName
        TabLabel.TextColor3 = MitHub.TextMuted
        TabLabel.TextSize = 12
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.ZIndex = 4
        TabLabel.Parent = TabBtn

        -- active indicator (left accent bar)
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 0, 0)
        indicator.Position = UDim2.new(0, 0, 0.5, 0)
        indicator.BackgroundColor3 = MitHub.Accent
        indicator.BorderSizePixel = 0
        indicator.ZIndex = 5
        indicator.Parent = TabBtn
        corner(indicator, 2)

        local Tab = {}
        Tab.Button = TabBtn
        Tab.Page = Page
        Tab._active = false

        local function activate()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                t._active = false
                TweenService:Create(t.Button, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
                local ic = t.Button:FindFirstChildOfClass("ImageLabel")
                local lb = t.Button:FindFirstChildOfClass("TextLabel")
                local ind = t.Button:FindFirstChild("Frame")
                if ic then TweenService:Create(ic, TweenInfo.new(0.2), {ImageColor3 = MitHub.TextMuted}):Play() end
                if lb then TweenService:Create(lb, TweenInfo.new(0.2), {TextColor3 = MitHub.TextMuted}):Play() end
                if ind then TweenService:Create(ind, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 0)}):Play() end
            end
            Page.Visible = true
            Tab._active = true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
            TweenService:Create(TabIcon, TweenInfo.new(0.2), {ImageColor3 = MitHub.Accent}):Play()
            TweenService:Create(TabLabel, TweenInfo.new(0.2), {TextColor3 = MitHub.TextMain}):Play()
            TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 3, 0, 20)}):Play()
        end

        TabBtn.MouseButton1Click:Connect(activate)
        TabBtn.MouseEnter:Connect(function()
            if not Tab._active then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
                TweenService:Create(TabIcon, TweenInfo.new(0.15), {ImageColor3 = MitHub.TextMain}):Play()
                TweenService:Create(TabLabel, TweenInfo.new(0.15), {TextColor3 = MitHub.TextMain}):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if not Tab._active then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
                TweenService:Create(TabIcon, TweenInfo.new(0.15), {ImageColor3 = MitHub.TextMuted}):Play()
                TweenService:Create(TabLabel, TweenInfo.new(0.15), {TextColor3 = MitHub.TextMuted}):Play()
            end
        end)

        -- ===== Section =====
        function Tab:AddSection(cfg)
            cfg = cfg or {}
            local secName = cfg.Name or "SECTION"

            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size = UDim2.new(1, 0, 0, 0)
            sectionFrame.BackgroundColor3 = MitHub.BgCard
            sectionFrame.BorderSizePixel = 0
            sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            sectionFrame.ZIndex = 2
            sectionFrame.Parent = Page
            corner(sectionFrame, 10)
            stroke(sectionFrame, MitHub.Stroke, 1, 0)
            pad(sectionFrame, 10, 10, 12, 12)

            local secLayout = Instance.new("UIListLayout")
            secLayout.Padding = UDim.new(0, 6)
            secLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secLayout.Parent = sectionFrame

            local secLabel = Instance.new("TextLabel")
            secLabel.BackgroundTransparency = 1
            secLabel.Size = UDim2.new(1, 0, 0, 14)
            secLabel.Font = Enum.Font.GothamBold
            secLabel.Text = secName:upper()
            secLabel.TextColor3 = MitHub.Accent
            secLabel.TextSize = 11
            secLabel.TextXAlignment = Enum.TextXAlignment.Left
            secLabel.ZIndex = 3
            secLabel.Parent = sectionFrame

            local Section = {}

            -- ===== Label (row) =====
            function Section:AddLabel(text, warp)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundColor3 = MitHub.BgCard
                row.BackgroundTransparency = 0.5
                row.BorderSizePixel = 0
                row.ZIndex = 3
                row.Parent = sectionFrame
                corner(row, 6)
                stroke(row, MitHub.Stroke, 1, 0.3)

                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, -16, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.Font = Enum.Font.Gotham
                lbl.Text = text or ""
                lbl.TextColor3 = MitHub.TextMain
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.TextWrapped = warp or false
                lbl.ZIndex = 4
                lbl.Parent = row

                local handle = {}

                row.MouseEnter:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
                end)
                row.MouseLeave:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play()
                end)

                -- ===== Toggle =====
                function handle:AddToggle(cfg)
                    cfg = cfg or {}
                    local default = cfg.Default or false
                    local callback = cfg.Callback or function() end
                    local flag = cfg.Flag

                    local switch = Instance.new("TextButton")
                    switch.Size = UDim2.new(0, 40, 0, 20)
                    switch.Position = UDim2.new(1, -48, 0.5, -10)
                    switch.BackgroundColor3 = default and MitHub.Accent or Color3.fromRGB(35, 38, 48)
                    switch.Text = ""
                    switch.AutoButtonColor = false
                    switch.ZIndex = 5
                    switch.Parent = row
                    corner(switch, 10)
                    local ss = stroke(switch, MitHub.Stroke, 1, 0)

                    local dot = Instance.new("Frame")
                    dot.Size = UDim2.new(0, 16, 0, 16)
                    dot.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                    dot.BackgroundColor3 = default and MitHub.BgDark or MitHub.TextMuted
                    dot.BorderSizePixel = 0
                    dot.ZIndex = 6
                    dot.Parent = switch
                    corner(dot, 8)

                    local state = default
                    local function setState(v, fireCb)
                        state = v
                        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            Position = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                            BackgroundColor3 = v and MitHub.BgDark or MitHub.TextMuted,
                        }):Play()
                        TweenService:Create(switch, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            BackgroundColor3 = v and MitHub.Accent or Color3.fromRGB(35, 38, 48),
                        }):Play()
                        if fireCb ~= false then
                            task.spawn(function() callback(v) end)
                        end
                    end

                    switch.MouseButton1Click:Connect(function()
                        setState(not state)
                    end)

                    if flag then
                        MitHub.Flags[flag] = {
                            GetValue = function() return state end,
                            SetValue = function(v) setState(v, true) end,
                        }
                    end

                    local lib = {}
                    function lib:GetValue() return state end
                    function lib:SetValue(v) setState(v, true) end
                    return lib
                end

                -- ===== Slider =====
                function handle:AddSlider(cfg)
                    cfg = cfg or {}
                    local minV = cfg.Min or 0
                    local maxV = cfg.Max or 100
                    local def   = cfg.Default or minV
                    local cb    = cfg.Callback or function() end
                    local flag  = cfg.Flag

                    local sRow = Instance.new("Frame")
                    sRow.Size = UDim2.new(1, 0, 0, 38)
                    sRow.BackgroundColor3 = MitHub.BgCard
                    sRow.BackgroundTransparency = 0.5
                    sRow.BorderSizePixel = 0
                    sRow.ZIndex = 3
                    sRow.Parent = sectionFrame
                    corner(sRow, 6)
                    stroke(sRow, MitHub.Stroke, 1, 0.3)

                    local sLabel = Instance.new("TextLabel")
                    sLabel.BackgroundTransparency = 1
                    sLabel.Size = UDim2.new(1, -50, 0, 16)
                    sLabel.Position = UDim2.new(0, 10, 0, 6)
                    sLabel.Font = Enum.Font.Gotham
                    sLabel.Text = (text or "") .. ":"
                    sLabel.TextColor3 = MitHub.TextMain
                    sLabel.TextSize = 11
                    sLabel.TextXAlignment = Enum.TextXAlignment.Left
                    sLabel.ZIndex = 4
                    sLabel.Parent = sRow

                    local valLabel = Instance.new("TextLabel")
                    valLabel.BackgroundTransparency = 1
                    valLabel.Size = UDim2.new(0, 40, 0, 16)
                    valLabel.Position = UDim2.new(1, -48, 0, 6)
                    valLabel.Font = Enum.Font.GothamBold
                    valLabel.Text = tostring(def)
                    valLabel.TextColor3 = MitHub.Accent
                    valLabel.TextSize = 11
                    valLabel.TextXAlignment = Enum.TextXAlignment.Right
                    valLabel.ZIndex = 4
                    valLabel.Parent = sRow

                    local track = Instance.new("Frame")
                    track.Size = UDim2.new(1, -20, 0, 4)
                    track.Position = UDim2.new(0, 10, 0, 28)
                    track.BackgroundColor3 = Color3.fromRGB(40, 42, 52)
                    track.BorderSizePixel = 0
                    track.ZIndex = 4
                    track.Parent = sRow
                    corner(track, 2)

                    local fill = Instance.new("Frame")
                    fill.Size = UDim2.new((def - minV) / math.max(1, maxV - minV), 0, 1, 0)
                    fill.BorderSizePixel = 0
                    fill.ZIndex = 5
                    fill.Parent = track
                    corner(fill, 2)
                    gradient(fill, MitHub.AccentDim, MitHub.Accent, 0)

                    local state = def
                    local function setVal(v, fireCb)
                        v = math.clamp(v, minV, maxV)
                        state = v
                        TweenService:Create(fill, TweenInfo.new(0.05), {
                            Size = UDim2.new((v - minV) / math.max(1, maxV - minV), 0, 1, 0),
                        }):Play()
                        valLabel.Text = tostring(v)
                        if fireCb ~= false then
                            task.spawn(function() cb(v) end)
                        end
                    end

                    local dragging = false
                    track.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            local scale = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                            setVal(minV + scale * (maxV - minV))
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if not dragging then return end
                        if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                            local scale = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                            setVal(minV + scale * (maxV - minV))
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)

                    if flag then
                        MitHub.Flags[flag] = {
                            GetValue = function() return state end,
                            SetValue = function(v) setVal(v, true) end,
                        }
                    end
                    local lib = {}
                    function lib:GetValue() return state end
                    function lib:SetValue(v) setVal(v, true) end
                    return lib
                end

                -- ===== Dropdown =====
                function handle:AddDropdown(cfg)
                    cfg = cfg or {}
                    local values = cfg.Values or {}
                    local def    = cfg.Default or (values[1] or "")
                    local cb     = cfg.Callback or function() end
                    local flag   = cfg.Flag

                    local dRow = Instance.new("Frame")
                    dRow.Size = UDim2.new(1, 0, 0, 30)
                    dRow.BackgroundColor3 = MitHub.BgCard
                    dRow.BackgroundTransparency = 0.5
                    dRow.BorderSizePixel = 0
                    dRow.ZIndex = 3
                    dRow.Parent = sectionFrame
                    corner(dRow, 6)
                    stroke(dRow, MitHub.Stroke, 1, 0.3)

                    local dLabel = Instance.new("TextLabel")
                    dLabel.BackgroundTransparency = 1
                    dLabel.Size = UDim2.new(1, -90, 1, 0)
                    dLabel.Position = UDim2.new(0, 10, 0, 0)
                    dLabel.Font = Enum.Font.Gotham
                    dLabel.Text = text or ""
                    dLabel.TextColor3 = MitHub.TextMain
                    dLabel.TextSize = 11
                    dLabel.TextXAlignment = Enum.TextXAlignment.Left
                    dLabel.ZIndex = 4
                    dLabel.Parent = dRow

                    local dBtn = Instance.new("TextButton")
                    dBtn.Size = UDim2.new(0, 75, 0, 22)
                    dBtn.Position = UDim2.new(1, -83, 0.5, -11)
                    dBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
                    dBtn.Text = tostring(def)
                    dBtn.Font = Enum.Font.GothamMedium
                    dBtn.TextColor3 = MitHub.Accent
                    dBtn.TextSize = 10
                    dBtn.AutoButtonColor = false
                    dBtn.ZIndex = 4
                    dBtn.Parent = dRow
                    corner(dBtn, 5)
                    stroke(dBtn, MitHub.Stroke, 1, 0)

                    local state = def
                    local idx = table.find(values, def) or 1

                    dBtn.MouseButton1Click:Connect(function()
                        idx = idx % #values + 1
                        state = values[idx]
                        TweenService:Create(dBtn, TweenInfo.new(0.1), {BackgroundColor3 = MitHub.AccentDim}):Play()
                        task.delay(0.1, function()
                            TweenService:Create(dBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 38, 48)}):Play()
                        end)
                        dBtn.Text = tostring(state)
                        task.spawn(function() cb(state) end)
                    end)

                    local lib = {}
                    function lib:GetValue() return state end
                    function lib:SetValue(v) state = v; dBtn.Text = tostring(v) end
                    function lib:SetValues(newValues) values = newValues end
                    return lib
                end

                -- ===== Keybind =====
                function handle:AddKeybind(cfg)
                    cfg = cfg or {}
                    local def = cfg.Default
                    local cb  = cfg.Callback or function() end
                    local flag = cfg.Flag

                    local kBtn = Instance.new("TextButton")
                    kBtn.Size = UDim2.new(0, 48, 0, 22)
                    kBtn.Position = UDim2.new(1, -56, 0.5, -11)
                    kBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
                    kBtn.Text = def and tostring(def) or "None"
                    kBtn.Font = Enum.Font.GothamBold
                    kBtn.TextColor3 = MitHub.Accent
                    kBtn.TextSize = 10
                    kBtn.AutoButtonColor = false
                    kBtn.ZIndex = 4
                    kBtn.Parent = row
                    corner(kBtn, 5)
                    stroke(kBtn, MitHub.Stroke, 1, 0)

                    local state = def
                    local listening = false

                    kBtn.MouseButton1Click:Connect(function()
                        if listening then return end
                        listening = true
                        kBtn.Text = "..."
                        TweenService:Create(kBtn, TweenInfo.new(0.1), {BackgroundColor3 = MitHub.AccentDim}):Play()
                        local conn
                        conn = UserInputService.InputBegan:Connect(function(input, gp)
                            if gp then return end
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                state = input.KeyCode.Name
                                kBtn.Text = state
                                listening = false
                                TweenService:Create(kBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 38, 48)}):Play()
                                task.spawn(function() cb(state) end)
                                conn:Disconnect()
                            end
                        end)
                    end)

                    local lib = {}
                    function lib:GetValue() return state end
                    function lib:SetValue(v) state = v; kBtn.Text = tostring(v) end
                    return lib
                end

                -- ===== Button =====
                function handle:AddButton(cfg)
                    cfg = cfg or {}
                    local name = cfg.Name or text or "Button"
                    local cb   = cfg.Callback or function() end

                    local bRow = Instance.new("TextButton")
                    bRow.Size = UDim2.new(1, 0, 0, 32)
                    bRow.BackgroundColor3 = MitHub.BgCard
                    bRow.BackgroundTransparency = 0.3
                    bRow.Text = ""
                    bRow.AutoButtonColor = false
                    bRow.ZIndex = 3
                    bRow.Parent = sectionFrame
                    corner(bRow, 6)
                    stroke(bRow, MitHub.Accent, 1, 0.6)

                    local bLabel = Instance.new("TextLabel")
                    bLabel.BackgroundTransparency = 1
                    bLabel.Size = UDim2.new(1, -20, 1, 0)
                    bLabel.Position = UDim2.new(0, 10, 0, 0)
                    bLabel.Font = Enum.Font.GothamMedium
                    bLabel.Text = name
                    bLabel.TextColor3 = MitHub.Accent
                    bLabel.TextSize = 12
                    bLabel.TextXAlignment = Enum.TextXAlignment.Left
                    bLabel.ZIndex = 4
                    bLabel.Parent = bRow

                    bRow.MouseEnter:Connect(function()
                        TweenService:Create(bRow, TweenInfo.new(0.15), {
                            BackgroundColor3 = MitHub.Accent,
                            BackgroundTransparency = 0.85,
                        }):Play()
                    end)
                    bRow.MouseLeave:Connect(function()
                        TweenService:Create(bRow, TweenInfo.new(0.15), {
                            BackgroundColor3 = MitHub.BgCard,
                            BackgroundTransparency = 0.3,
                        }):Play()
                    end)
                    bRow.MouseButton1Click:Connect(function()
                        TweenService:Create(bRow, TweenInfo.new(0.08), {BackgroundTransparency = 0.6}):Play()
                        task.delay(0.12, function()
                            TweenService:Create(bRow, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
                        end)
                        task.spawn(cb)
                    end)
                    return {}
                end

                return handle
            end

            function Section:AddButton(cfg)
                local dummy = Section:AddLabel("")
                return dummy:AddButton(cfg)
            end

            return Section
        end

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then
            activate()
        end

        return Tab
    end

    -- UserSettings tab (gear at bottom of sidebar)
    local UserSettingsTab = Window:AddTab({Name = "Config", Icon = "settings"})
    Window.UserSettings = UserSettingsTab:AddSection({Name = "Menu Settings"})

    return Window
end

-- Watermark
function MitHub:CreateWatermark(parentWindow)
    local screenGui = parentWindow and parentWindow._screenGui
    if not screenGui then return {AddBlock = function() return {SetText = function() end, Input = function() end} end} end

    local wm = Instance.new("Frame")
    wm.AnchorPoint = Vector2.new(1, 0)
    wm.Position = UDim2.new(1, -10, 0, 10)
    wm.Size = UDim2.new(0, 0, 0, 30)
    wm.BackgroundColor3 = MitHub.BgCard
    wm.BackgroundTransparency = 0.2
    wm.BorderSizePixel = 0
    wm.AutomaticSize = Enum.AutomaticSize.X
    wm.Parent = screenGui
    corner(wm, 15)
    stroke(wm, MitHub.Accent, 1, 0.4)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = wm
    pad(wm, 0, 0, 12, 12)

    local Watermark = {}
    function Watermark:AddBlock(icon, defaultText)
        local block = Instance.new("TextButton")
        block.Size = UDim2.new(0, 60, 0, 22)
        block.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
        block.BackgroundTransparency = 0.4
        block.Text = defaultText or ""
        block.Font = Enum.Font.GothamMedium
        block.TextColor3 = MitHub.TextMain
        block.TextSize = 10
        block.AutoButtonColor = false
        block.Parent = wm
        corner(block, 11)

        local b = {}
        function b:SetText(t) block.Text = t end
        function b:Input(cb) block.MouseButton1Click:Connect(cb) end
        return b
    end
    return Watermark
end

return MitHub
