--[[
    MitHub UI Library v1.0
    Custom UI library inspired by the requested design.
    Layout: left sidebar (icon+text) + content area (sections + rows).
    Visual: dark slate with lime green accent, iOS-style pill toggles,
            standard window controls (minimize/maximize/close) in top-right.
    API mirrors NeverLose for easy porting.
    License: MIT
    Author: MitHub
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Safe GUI parent
local function getGuiParent()
    if gethui then return gethui() end
    if get_hidden_gui then return get_hidden_gui() end
    local ok = pcall(function() return CoreGui end)
    if ok then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function protectGui(gui)
    if protect_gui then pcall(protect_gui, gui)
    elseif protectgui then pcall(protectgui, gui)
    elseif syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
end

-- Clone ref helper (no-op on vanilla Roblox)
local cloneref = cloneref or function(o) return o end
local TweenService = cloneref(TweenService)
local UserInputService = cloneref(UserInputService)

-- ============================================================================
-- MitHub UI Library
-- ============================================================================
local MitHub = {}
MitHub.Scales = {
    Small   = UDim2.fromOffset(420, 320),
    Mobile  = UDim2.fromOffset(460, 380),
    Default = UDim2.fromOffset(540, 420),
    Large   = UDim2.fromOffset(680, 540),
}
MitHub.Accent = Color3.fromRGB(170, 255, 80) -- lime green
MitHub.Flags  = {}

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or MitHub.Accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

-- Make a frame draggable
local function makeDraggable(frame, dragHandle)
    local dragging, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================================
-- Notification
-- ============================================================================
function MitHub:CreateNotification()
    local Notification = {}
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "MitHubNotifications"
    notifGui.ResetOnSpawn = false
    notifGui.DisplayOrder = 9999
    notifGui.Parent = getGuiParent()
    protectGui(notifGui)

    local notifList = Instance.new("Frame")
    notifList.Name = "List"
    notifList.AnchorPoint = Vector2.new(1, 0)
    notifList.Position = UDim2.new(1, -15, 0, 15)
    notifList.Size = UDim2.new(0, 280, 1, -30)
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
        local title   = cfg.Title or "Notification"
        local content = cfg.Content or ""
        local dur     = cfg.Duration or 5

        local card = Instance.new("Frame")
        card.Name = "Card"
        card.Size = UDim2.new(1, 0, 0, 0)
        card.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        card.BorderSizePixel = 0
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.Parent = notifList
        corner(card, 8)
        stroke(card, MitHub.Accent, 1, 0.4)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.BackgroundTransparency = 1
        tLabel.Size = UDim2.new(1, 0, 0, 16)
        tLabel.Position = UDim2.new(0, 0, 0, 0)
        tLabel.Font = Enum.Font.GothamBold
        tLabel.Text = title
        tLabel.TextColor3 = MitHub.Accent
        tLabel.TextSize = 13
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = card

        local cLabel = Instance.new("TextLabel")
        cLabel.BackgroundTransparency = 1
        cLabel.Size = UDim2.new(1, 0, 0, 14)
        cLabel.Position = UDim2.new(0, 0, 0, 18)
        cLabel.Font = Enum.Font.Gotham
        cLabel.Text = content
        cLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
        cLabel.TextSize = 11
        cLabel.TextWrapped = true
        cLabel.AutomaticSize = Enum.AutomaticSize.Y
        cLabel.TextXAlignment = Enum.TextXAlignment.Left
        cLabel.Parent = card

        -- slide-in animation
        card.Position = UDim2.new(1, 280, 0, 0)
        TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()

        task.delay(dur, function()
            local tw = TweenService:Create(card, TweenInfo.new(0.3), {
                Position = UDim2.new(1, 280, 0, 0),
            })
            tw:Play()
            tw.Completed:Connect(function()
                card:Destroy()
            end)
        end)
    end
    return Notification
end

-- ============================================================================
-- Logger
-- ============================================================================
function MitHub:CreateLogger()
    local Logger = {}
    function Logger.new(icon, text, duration)
        duration = duration or 5
        -- simple log: write to notification
        if self._notif then
            self._notif.new({Title = "Log", Content = text, Duration = duration})
        end
    end
    return Logger
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

    -- Destroy any previous instance
    pcall(function()
        local old = getGuiParent():FindFirstChild("MitHubUI_Main")
        if old then old:Destroy() end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MitHubUI_Main"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9998
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = getGuiParent()
    protectGui(screenGui)

    -- Main window frame
    local WindowFrame = Instance.new("Frame")
    WindowFrame.Name = "Window"
    WindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    WindowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    WindowFrame.Size = windowSize
    WindowFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    WindowFrame.BorderSizePixel = 0
    WindowFrame.ClipsDescendants = true
    WindowFrame.Parent = screenGui
    corner(WindowFrame, 10)
    stroke(WindowFrame, Color3.fromRGB(45, 48, 58), 1, 0)

    -- Subtle accent gradient on top edge
    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Size = UDim2.new(1, 0, 0, 2)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = MitHub.Accent
    accentBar.BorderSizePixel = 0
    accentBar.Parent = WindowFrame

    -- Header (title + close button + drag handle)
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.Position = UDim2.new(0, 0, 0, 2)
    Header.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
    Header.BorderSizePixel = 0
    Header.Parent = WindowFrame

    local titleIcon = Instance.new("ImageLabel")
    titleIcon.Name = "Logo"
    titleIcon.Size = UDim2.new(0, 22, 0, 22)
    titleIcon.Position = UDim2.new(0, 14, 0.5, -11)
    titleIcon.BackgroundTransparency = 1
    titleIcon.Image = "rbxassetid://6035047377" -- home icon
    titleIcon.ImageColor3 = MitHub.Accent
    titleIcon.Parent = Header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(0, 200, 0, 18)
    titleLabel.Position = UDim2.new(0, 42, 0, 6)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = windowName:upper()
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = Header

    local subLabel = Instance.new("TextLabel")
    subLabel.Name = "Subtitle"
    subLabel.BackgroundTransparency = 1
    subLabel.Size = UDim2.new(0, 200, 0, 12)
    subLabel.Position = UDim2.new(0, 42, 0, 23)
    subLabel.Font = Enum.Font.Gotham
    subLabel.Text = windowContent
    subLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
    subLabel.TextSize = 10
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.Parent = Header

    -- Window controls (minimize + close) at top-right
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 35)
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.fromRGB(255, 120, 130)
    closeBtn.TextSize = 12
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = Header
    corner(closeBtn, 4)

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "Minimize"
    minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
    minimizeBtn.Position = UDim2.new(1, -68, 0.5, -14)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
    minimizeBtn.BackgroundTransparency = 0.3
    minimizeBtn.Text = "-"
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextColor3 = Color3.fromRGB(180, 195, 220)
    minimizeBtn.TextSize = 16
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.Parent = Header
    corner(minimizeBtn, 4)

    -- Hover effects
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
    end)
    minimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
    end)
    minimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(minimizeBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
    end)

    -- Sidebar (left column - icon + text tabs)
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 130, 1, -42)
    Sidebar.Position = UDim2.new(0, 0, 0, 42)
    Sidebar.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = WindowFrame

    local sidebarStroke = Instance.new("UIStroke")
    sidebarStroke.Color = Color3.fromRGB(45, 48, 58)
    sidebarStroke.Thickness = 1
    sidebarStroke.Transparency = 0.5
    sidebarStroke.Parent = Sidebar

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 4)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Parent = Sidebar

    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.PaddingTop = UDim.new(0, 10)
    sidebarPad.PaddingBottom = UDim.new(0, 10)
    sidebarPad.Parent = Sidebar

    -- Content area (right column)
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "Content"
    ContentArea.Size = UDim2.new(1, -130, 1, -42)
    ContentArea.Position = UDim2.new(0, 130, 0, 42)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = WindowFrame

    -- Floating Minimized button (when minimized)
    local minimizedBtn = Instance.new("TextButton")
    minimizedBtn.Name = "MinimizedBtn"
    minimizedBtn.Size = UDim2.new(0, 50, 0, 50)
    minimizedBtn.Position = UDim2.new(0, 20, 1, -70)
    minimizedBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
    minimizedBtn.Text = "M"
    minimizedBtn.Font = Enum.Font.GothamBold
    minimizedBtn.TextColor3 = MitHub.Accent
    minimizedBtn.TextSize = 22
    minimizedBtn.Visible = false
    minimizedBtn.AutoButtonColor = false
    minimizedBtn.Parent = screenGui
    corner(minimizedBtn, 25)
    stroke(minimizedBtn, MitHub.Accent, 1.5, 0.2)

    -- Draggable window (from header)
    makeDraggable(WindowFrame, Header)

    -- Window state
    local Window = {}
    Window.Size = windowSize
    Window.Keybind = keybind
    Window.Visible = true
    Window.Tabs = {}

    function Window:ToggleInterface()
        Window.Visible = not Window.Visible
        if Window.Visible then
            TweenService:Create(WindowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = Window.Size,
                BackgroundTransparency = 0,
            }):Play()
            WindowFrame.Visible = true
            minimizedBtn.Visible = false
        else
            local tw = TweenService:Create(WindowFrame, TweenInfo.new(0.15), {
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
            TweenService:Create(WindowFrame, TweenInfo.new(0.2), {Size = newSize}):Play()
        end
    end

    -- Close / Minimize handlers
    closeBtn.MouseButton1Click:Connect(function()
        Window:ToggleInterface()
    end)
    minimizedBtn.MouseButton1Click:Connect(function()
        Window:ToggleInterface()
    end)
    minimizeBtn.MouseButton1Click:Connect(function()
        Window:ToggleInterface()
    end)

    -- Keyboard toggle
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

    -- -------------------------------------------------------
    -- Tab creation
    -- -------------------------------------------------------
    function Window:AddTab(cfg)
        cfg = cfg or {}
        local tabName = cfg.Name or "Tab"
        local tabIcon = cfg.Icon or "rbxassetid://6035047377"

        -- Page (content frame)
        local Page = Instance.new("ScrollingFrame")
        Page.Name = "Page_" .. tabName
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = MitHub.Accent
        Page.ScrollBarImageTransparency = 0.4
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.Parent = ContentArea

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = Page

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = Page

        -- Tab button (sidebar)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = "Tab_" .. tabName
        TabBtn.Size = UDim2.new(0, 116, 0, 32)
        TabBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
        TabBtn.BackgroundTransparency = 0
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = Sidebar
        corner(TabBtn, 6)

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        TabIcon.Position = UDim2.new(0, 8, 0.5, -8)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Image = tabIcon
        TabIcon.ImageColor3 = Color3.fromRGB(150, 155, 170)
        TabIcon.Parent = TabBtn

        local TabLabel = Instance.new("TextLabel")
        TabLabel.BackgroundTransparency = 1
        TabLabel.Size = UDim2.new(1, -32, 1, 0)
        TabLabel.Position = UDim2.new(0, 30, 0, 0)
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.Text = tabName
        TabLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
        TabLabel.TextSize = 12
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabBtn

        local Tab = {}
        Tab.Button = TabBtn
        Tab.Page  = Page
        Tab._active = false

        local function activate()
            -- hide all pages
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                t._active = false
                TweenService:Create(t.Button, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 32, 42)}):Play()
                local ic = t.Button:FindFirstChildOfClass("ImageLabel")
                local lb = t.Button:FindFirstChildOfClass("TextLabel")
                if ic then TweenService:Create(ic, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(150, 155, 170)}):Play() end
                if lb then TweenService:Create(lb, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(150, 155, 170)}):Play() end
            end
            Page.Visible = true
            Tab._active = true
            TweenService:Create(TabBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(40, 44, 58)}):Play()
            TweenService:Create(TabIcon, TweenInfo.new(0.12), {ImageColor3 = MitHub.Accent}):Play()
            TweenService:Create(TabLabel, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end

        TabBtn.MouseButton1Click:Connect(activate)
        TabBtn.MouseEnter:Connect(function()
            if not Tab._active then
                TweenService:Create(TabBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(36, 38, 50)}):Play()
                TweenService:Create(TabIcon, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(200, 210, 220)}):Play()
                TweenService:Create(TabLabel, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(200, 210, 220)}):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if not Tab._active then
                TweenService:Create(TabBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 32, 42)}):Play()
                TweenService:Create(TabIcon, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(150, 155, 170)}):Play()
                TweenService:Create(TabLabel, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(150, 155, 170)}):Play()
            end
        end)

        -- -------------------------------------------------------
        -- Section (with header label + content)
        -- -------------------------------------------------------
        function Tab:AddSection(cfg)
            cfg = cfg or {}
            local secName = cfg.Name or "SECTION"
            local pos = cfg.Position or "left" -- (kept for API compatibility; single column)

            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size = UDim2.new(1, 0, 0, 0)
            sectionFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
            sectionFrame.BackgroundTransparency = 0
            sectionFrame.BorderSizePixel = 0
            sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            sectionFrame.Parent = Page
            corner(sectionFrame, 8)
            stroke(sectionFrame, Color3.fromRGB(45, 48, 58), 1, 0)

            local pad2 = Instance.new("UIPadding")
            pad2.PaddingTop = UDim.new(0, 8)
            pad2.PaddingBottom = UDim.new(0, 8)
            pad2.PaddingLeft = UDim.new(0, 10)
            pad2.PaddingRight = UDim.new(0, 10)
            pad2.Parent = sectionFrame

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
            secLabel.Parent = sectionFrame

            local Section = {}

            -- -----------------------------------------------
            -- Label (creates a row + returns handle with Add* methods)
            -- -----------------------------------------------
            function Section:AddLabel(text, warp)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 28)
                row.BackgroundColor3 = Color3.fromRGB(34, 36, 48)
                row.BackgroundTransparency = 0
                row.BorderSizePixel = 0
                row.Parent = sectionFrame
                corner(row, 5)
                stroke(row, Color3.fromRGB(45, 48, 58), 1, 0)

                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, -16, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.Font = Enum.Font.Gotham
                lbl.Text = text or ""
                lbl.TextColor3 = Color3.fromRGB(230, 230, 240)
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextYAlignment = Enum.TextYAlignment.Center
                lbl.TextWrapped = warp or false
                lbl.Parent = row

                local handle = {}

                -- row hover
                row.MouseEnter:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 42, 56)}):Play()
                end)
                row.MouseLeave:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(34, 36, 48)}):Play()
                end)

                -- -----------------------------
                -- Toggle
                -- -----------------------------
                function handle:AddToggle(cfg)
                    cfg = cfg or {}
                    local default = cfg.Default or false
                    local callback = cfg.Callback or function() end
                    local flag = cfg.Flag

                    local switch = Instance.new("TextButton")
                    switch.Size = UDim2.new(0, 38, 0, 18)
                    switch.Position = UDim2.new(1, -46, 0.5, -9)
                    switch.BackgroundColor3 = default and MitHub.Accent or Color3.fromRGB(40, 42, 52)
                    switch.Text = ""
                    switch.AutoButtonColor = false
                    switch.Parent = row
                    corner(switch, 9)
                    local ss = stroke(switch, Color3.fromRGB(60, 65, 80), 1, 0)

                    local dot = Instance.new("Frame")
                    dot.Size = UDim2.new(0, 14, 0, 14)
                    dot.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                    dot.BackgroundColor3 = default and Color3.fromRGB(20, 22, 30) or Color3.fromRGB(180, 185, 195)
                    dot.BorderSizePixel = 0
                    dot.Parent = switch
                    corner(dot, 7)

                    local state = default
                    local function setState(v, fireCallback)
                        state = v
                        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Position = v and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                            BackgroundColor3 = v and Color3.fromRGB(20, 22, 30) or Color3.fromRGB(180, 185, 195),
                        }):Play()
                        TweenService:Create(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            BackgroundColor3 = v and MitHub.Accent or Color3.fromRGB(40, 42, 52),
                        }):Play()
                        if fireCallback ~= false then
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

                -- -----------------------------
                -- Slider
                -- -----------------------------
                function handle:AddSlider(cfg)
                    cfg = cfg or {}
                    local minV = cfg.Min or 0
                    local maxV = cfg.Max or 100
                    local def   = cfg.Default or minV
                    local cb    = cfg.Callback or function() end
                    local flag  = cfg.Flag

                    local sRow = Instance.new("Frame")
                    sRow.Size = UDim2.new(1, 0, 0, 36)
                    sRow.BackgroundColor3 = Color3.fromRGB(34, 36, 48)
                    sRow.BorderSizePixel = 0
                    sRow.Parent = sectionFrame
                    corner(sRow, 5)

                    local sLabel = Instance.new("TextLabel")
                    sLabel.BackgroundTransparency = 1
                    sLabel.Size = UDim2.new(1, -50, 0, 16)
                    sLabel.Position = UDim2.new(0, 10, 0, 4)
                    sLabel.Font = Enum.Font.Gotham
                    sLabel.Text = (text or "") .. ":"
                    sLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
                    sLabel.TextSize = 11
                    sLabel.TextXAlignment = Enum.TextXAlignment.Left
                    sLabel.Parent = sRow

                    local valLabel = Instance.new("TextLabel")
                    valLabel.BackgroundTransparency = 1
                    valLabel.Size = UDim2.new(0, 40, 0, 16)
                    valLabel.Position = UDim2.new(1, -48, 0, 4)
                    valLabel.Font = Enum.Font.GothamBold
                    valLabel.Text = tostring(def)
                    valLabel.TextColor3 = MitHub.Accent
                    valLabel.TextSize = 11
                    valLabel.TextXAlignment = Enum.TextXAlignment.Right
                    valLabel.Parent = sRow

                    local track = Instance.new("Frame")
                    track.Size = UDim2.new(1, -20, 0, 4)
                    track.Position = UDim2.new(0, 10, 0, 26)
                    track.BackgroundColor3 = Color3.fromRGB(50, 52, 64)
                    track.BorderSizePixel = 0
                    track.Parent = sRow
                    corner(track, 2)

                    local fill = Instance.new("Frame")
                    fill.Size = UDim2.new((def - minV) / math.max(1, maxV - minV), 0, 1, 0)
                    fill.BackgroundColor3 = MitHub.Accent
                    fill.BorderSizePixel = 0
                    fill.Parent = track
                    corner(fill, 2)

                    local state = def
                    local function setVal(v, fireCb)
                        v = math.clamp(v, minV, maxV)
                        state = v
                        fill.Size = UDim2.new((v - minV) / math.max(1, maxV - minV), 0, 1, 0)
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

                -- -----------------------------
                -- Dropdown
                -- -----------------------------
                function handle:AddDropdown(cfg)
                    cfg = cfg or {}
                    local values = cfg.Values or {}
                    local def    = cfg.Default or (values[1] or "")
                    local multi  = cfg.Multi or false
                    local cb     = cfg.Callback or function() end
                    local flag   = cfg.Flag

                    local dRow = Instance.new("Frame")
                    dRow.Size = UDim2.new(1, 0, 0, 28)
                    dRow.BackgroundColor3 = Color3.fromRGB(34, 36, 48)
                    dRow.BorderSizePixel = 0
                    dRow.Parent = sectionFrame
                    corner(dRow, 5)

                    local dLabel = Instance.new("TextLabel")
                    dLabel.BackgroundTransparency = 1
                    dLabel.Size = UDim2.new(1, -90, 1, 0)
                    dLabel.Position = UDim2.new(0, 10, 0, 0)
                    dLabel.Font = Enum.Font.Gotham
                    dLabel.Text = (text or "")
                    dLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
                    dLabel.TextSize = 11
                    dLabel.TextXAlignment = Enum.TextXAlignment.Left
                    dLabel.Parent = dRow

                    local dBtn = Instance.new("TextButton")
                    dBtn.Size = UDim2.new(0, 70, 0, 22)
                    dBtn.Position = UDim2.new(1, -78, 0.5, -11)
                    dBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 52)
                    dBtn.Text = tostring(def)
                    dBtn.Font = Enum.Font.GothamMedium
                    dBtn.TextColor3 = MitHub.Accent
                    dBtn.TextSize = 10
                    dBtn.AutoButtonColor = false
                    dBtn.Parent = dRow
                    corner(dBtn, 4)

                    local state = def
                    local idx = table.find(values, def) or 1

                    dBtn.MouseButton1Click:Connect(function()
                        idx = idx % #values + 1
                        state = values[idx]
                        dBtn.Text = tostring(state)
                        task.spawn(function() cb(state) end)
                    end)

                    local lib = {}
                    function lib:GetValue() return state end
                    function lib:SetValue(v)
                        state = v
                        dBtn.Text = tostring(v)
                    end
                    function lib:SetValues(newValues)
                        values = newValues
                    end
                    return lib
                end

                -- -----------------------------
                -- Keybind
                -- -----------------------------
                function handle:AddKeybind(cfg)
                    cfg = cfg or {}
                    local def = cfg.Default
                    local cb  = cfg.Callback or function() end
                    local flag = cfg.Flag

                    local kBtn = Instance.new("TextButton")
                    kBtn.Size = UDim2.new(0, 45, 0, 22)
                    kBtn.Position = UDim2.new(1, -53, 0.5, -11)
                    kBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 52)
                    kBtn.Text = def and tostring(def) or "None"
                    kBtn.Font = Enum.Font.GothamBold
                    kBtn.TextColor3 = MitHub.Accent
                    kBtn.TextSize = 10
                    kBtn.AutoButtonColor = false
                    kBtn.Parent = row
                    corner(kBtn, 4)

                    local state = def
                    local listening = false

                    kBtn.MouseButton1Click:Connect(function()
                        if listening then return end
                        listening = true
                        kBtn.Text = "..."
                        local conn
                        conn = UserInputService.InputBegan:Connect(function(input, gp)
                            if gp then return end
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                state = input.KeyCode.Name
                                kBtn.Text = state
                                listening = false
                                task.spawn(function() cb(state) end)
                                conn:Disconnect()
                            end
                        end)
                    end)

                    local lib = {}
                    function lib:GetValue() return state end
                    function lib:SetValue(v)
                        state = v
                        kBtn.Text = tostring(v)
                    end
                    return lib
                end

                -- -----------------------------
                -- Button (replaces label with a button)
                -- -----------------------------
                function handle:AddButton(cfg)
                    cfg = cfg or {}
                    local name = cfg.Name or text or "Button"
                    local cb   = cfg.Callback or function() end

                    local bRow = Instance.new("TextButton")
                    bRow.Size = UDim2.new(1, 0, 0, 30)
                    bRow.BackgroundColor3 = Color3.fromRGB(34, 36, 48)
                    bRow.Text = ""
                    bRow.AutoButtonColor = false
                    bRow.Parent = sectionFrame
                    corner(bRow, 5)
                    stroke(bRow, MitHub.Accent, 1, 0.5)

                    local bLabel = Instance.new("TextLabel")
                    bLabel.BackgroundTransparency = 1
                    bLabel.Size = UDim2.new(1, -20, 1, 0)
                    bLabel.Position = UDim2.new(0, 10, 0, 0)
                    bLabel.Font = Enum.Font.GothamMedium
                    bLabel.Text = name
                    bLabel.TextColor3 = MitHub.Accent
                    bLabel.TextSize = 12
                    bLabel.TextXAlignment = Enum.TextXAlignment.Left
                    bLabel.Parent = bRow

                    bRow.MouseEnter:Connect(function()
                        TweenService:Create(bRow, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 48, 60)}):Play()
                    end)
                    bRow.MouseLeave:Connect(function()
                        TweenService:Create(bRow, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(34, 36, 48)}):Play()
                    end)
                    bRow.MouseButton1Click:Connect(function()
                        TweenService:Create(bRow, TweenInfo.new(0.08), {BackgroundColor3 = MitHub.Accent}):Play()
                        task.delay(0.1, function()
                            TweenService:Create(bRow, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(34, 36, 48)}):Play()
                        end)
                        task.spawn(cb)
                    end)
                    return {}
                end

                return handle
            end

            function Section:AddButton(cfg)
                -- Direct section-level button (no label needed)
                local dummy = Section:AddLabel("")
                return dummy:AddButton(cfg)
            end

            return Section
        end

        -- Auto-activate first tab
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then
            activate()
        end

        return Tab
    end

    -- UserSettings section (gear icon at bottom of sidebar)
    local UserSettingsTab = Window:AddTab({Name = "Settings", Icon = "rbxassetid://6031263436"})
    Window.UserSettings = UserSettingsTab:AddSection({Name = "Menu"})
    Window._settingsTab = UserSettingsTab

    return Window
end

-- Watermark (top-right HUD with ping + click-to-toggle)
function MitHub:CreateWatermark(parentWindow)
    local screenGui = parentWindow and parentWindow._screenGui or nil
    -- fallback standalone watermark
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MitHubWatermark"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = getGuiParent()
        protectGui(screenGui)
    end

    local wm = Instance.new("Frame")
    wm.Name = "Watermark"
    wm.AnchorPoint = Vector2.new(1, 0)
    wm.Position = UDim2.new(1, -10, 0, 10)
    wm.Size = UDim2.new(0, 0, 0, 28)
    wm.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    wm.BackgroundTransparency = 0.2
    wm.BorderSizePixel = 0
    wm.AutomaticSize = Enum.AutomaticSize.X
    wm.Parent = screenGui
    corner(wm, 14)
    stroke(wm, MitHub.Accent, 1, 0.4)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = wm

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = wm

    local Watermark = {}
    function Watermark:AddBlock(icon, defaultText)
        local block = Instance.new("TextButton")
        block.Size = UDim2.new(0, 60, 0, 22)
        block.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
        block.BackgroundTransparency = 0.4
        block.Text = defaultText or ""
        block.Font = Enum.Font.GothamMedium
        block.TextColor3 = Color3.fromRGB(220, 220, 230)
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
