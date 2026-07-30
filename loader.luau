--[[
    MitHub CRAZY - Violence District Edition
    Uses MitHub UI Library (custom UI inspired by the requested design)
    Layout: sidebar left + sections + iOS toggles + lime accent.
    Toggle: tap "M" floating button (mobile) / press Insert / RightShift / F4 / P (PC)
]]

-- ============================================================
-- Load MitHub UI library (replace URL with your own GitHub raw later)
-- ============================================================
local MitHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/MitHubUI/main/source.luau"))()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local CoreGui          = game:GetService("CoreGui")
local Teams            = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Cleanup previous
if CoreGui:FindFirstChild("MitHubUI_Main") then CoreGui.MitHubUI_Main:Destroy() end

local Notification = MitHub:CreateNotification()
local Logging      = MitHub:CreateLogger()

local Window = MitHub:CreateWindow({
    Name    = "MITHUB CRAZY",
    Content = "Violence District",
    Size    = IsMobile and MitHub.Scales.Mobile or MitHub.Scales.Default,
    Keybind = "Insert",
})

-- Watermark with live ping
local Watermark = MitHub:CreateWatermark(Window)
local PingBlock = Watermark:AddBlock(nil, "0MS")
local _ = Watermark:AddBlock(nil, "MitHub")

task.spawn(function()
    while true do
        task.wait(1)
        local ok, ping = pcall(function()
            return math.floor(LocalPlayer:GetNetworkPing() * 1000)
        end)
        PingBlock:SetText((ok and tostring(ping) or "0") .. "MS")
    end
end)

Notification.new({
    Title   = "MITHUB CRAZY",
    Content = "Tap 'X' on top-right to close. Tap 'M' floating button to reopen. Press Insert/RightShift/F4/P on PC.",
    Duration = 8,
})

-- ============================================================
-- STATES (verbatim from original Violence District script)
-- ============================================================
local States = {
    Noclip = false, PlayerESP = false, GeneratorESP = false, PalletESP = false,
    WindowESP = false, InstantHeal = false, InstantHealOthers = false,
    AutoHealAll = false, AutoLever = false, AutoDodge = false,
}

local Extras = {
    antiFallEnabled   = false,
    fovEnabled        = false,
    fovValue          = 90,
    myersGrabEnabled  = false,
    myersGrabKey      = Enum.KeyCode.Unknown,
    listeningMyersKey = false,
    MIN_HEALTH_MYERS  = 30,
    breakGenEnabled   = false,
    breakGenCount     = 10,
    breakGenCaptured  = nil,
    breakGenFired     = false,
    myersDragging    = false,
    myersDragLocked  = false,
    myersDragStart   = nil,
    myersDragStartPos = nil,
    autoGeneratorEnabled = false,
    lastGoalRotation     = nil,
    hasClickedThisGoal   = false,
    lastLineRotation     = nil,
    lastTick             = nil,
    wasActive            = false,
    fastAnimSpeed    = 2.0,
    fastAnimEnabled  = false,
    fastAnimHeartbeat = nil,
    speedBoostConn   = nil,
    NoSlowdown       = false,
    CustomSpeed      = 17,
    genBoostEnabled = false,
    genBoostLoop = nil,
    instantSkillcheckEnabled = false,
    instantSkillcheckMode    = false,
    isStatusActive = function(val)
        return val == true or (type(val) == "number" and val > 0)
    end,
}

local TARGET_OFFSET        = 106.5
local TOLERANCE            = 2.5
local LATENCY_COMPENSATION = 0
local perfectSkillcheck    = true

local VAULT_SLIDE_SET = {
    ["WalkingVaultAnimation"]=true, ["RunningVaultAnimation"]=true, ["RunningVaultAnimation2"]=true,
    ["RunningSlideAnimation"]=true, ["RunningSlideAnimation2"]=true,
    ["RunningSlideAnimationReversed"]=true, ["RunningSlideAnimationReversed2"]=true,
    ["RunningSlideWalkAnimation"]=true, ["RunningSlideWalkAnimation2"]=true,
    ["RunningSlideWalkAnimationRe"]=true, ["RunningSlideWalkAnimationRe2"]=true,
    ["PalletDropAnimation"]=true, ["PalletDropAnimation2"]=true,
    ["PalletDropAnimationReversed"]=true, ["PalletDropAnimationReversed2"]=true,
    ["Vault"]=true, ["BreakPallet"]=true,
}

-- ============================================================
-- FAST ANIMATIONS + Anti-Fall + NoSlowdown (verbatim)
-- ============================================================
local function setupFastAnimations()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local animator = hum:WaitForChild("Animator")

    animator.AnimationPlayed:Connect(function(track)
        local animName = track.Animation and track.Animation.Name
        if not VAULT_SLIDE_SET[animName] then return end
        if Extras.fastAnimEnabled then
            pcall(function() track:AdjustSpeed(Extras.fastAnimSpeed) end)
        end
        if Extras.speedBoostConn then Extras.speedBoostConn:Disconnect() end
        hum.WalkSpeed = 30
        Extras.speedBoostConn = RunService.Heartbeat:Connect(function()
            if hum and hum.Parent then hum.WalkSpeed = 30 end
        end)
        track.Stopped:Once(function()
            if Extras.speedBoostConn then Extras.speedBoostConn:Disconnect(); Extras.speedBoostConn = nil end
            if hum and hum.Parent then hum.WalkSpeed = hum:GetAttribute("WalkSpeed") or 16 end
        end)
    end)

    if Extras.fastAnimHeartbeat then Extras.fastAnimHeartbeat:Disconnect() end
    Extras.fastAnimHeartbeat = RunService.Heartbeat:Connect(function()
        if not Extras.fastAnimEnabled then return end
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local animName = track.Animation and track.Animation.Name
            if VAULT_SLIDE_SET[animName] and track.Speed ~= Extras.fastAnimSpeed then
                pcall(function() track:AdjustSpeed(Extras.fastAnimSpeed) end)
            end
        end
    end)

    char.AncestryChanged:Connect(function()
        if not char:IsDescendantOf(game) then
            if Extras.fastAnimHeartbeat then Extras.fastAnimHeartbeat:Disconnect(); Extras.fastAnimHeartbeat = nil end
            if Extras.speedBoostConn then Extras.speedBoostConn:Disconnect(); Extras.speedBoostConn = nil end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    setupFastAnimations()
end)
setupFastAnimations()

RunService.Heartbeat:Connect(function()
    if not Extras.antiStunEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if char:GetAttribute("Stunned") then char:SetAttribute("Stunned", false) end
        local stunnedVal = char:FindFirstChild("Stunned")
        if stunnedVal and stunnedVal:IsA("BoolValue") then stunnedVal.Value = false end
        if hum.PlatformStand then hum.PlatformStand = false end
        if hum.Sit then hum.Sit = false end
    end)
end)

local antiFallHookRef
antiFallHookRef = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if Extras.antiFallEnabled and method == "FireServer" then
        local ok, name = pcall(function() return self.Name:lower() end)
        if ok and (name:find("falldamage") or name:find("fall") or name:find("ragdollfall")) then
            return
        end
    end
    return antiFallHookRef(self, ...)
end))

RunService.Heartbeat:Connect(function(dt)
    if not Extras.NoSlowdown then return end
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myHum or not myRoot then return end
    local isImmobilized =
        Extras.isStatusActive(myChar:GetAttribute("IsHooked"))
        or Extras.isStatusActive(myChar:GetAttribute("Carried"))
        or Extras.isStatusActive(myChar:GetAttribute("Grabbed"))
    local isDoingCriticalAction = false
    for _, track in ipairs(myHum:GetPlayingAnimationTracks()) do
        if track.Animation then
            local name = track.Animation.Name:lower()
            if name:find("hook") or name:find("grab") or name:find("pickup") or name:find("place") then
                isDoingCriticalAction = true; break
            end
        end
    end
    if myHum.Health > 0
    and not isImmobilized
    and not isDoingCriticalAction
    and myHum.MoveDirection.Magnitude > 0 then
        local currentWalkSpeed = myHum.WalkSpeed
        local desiredSpeed = currentWalkSpeed
        if currentWalkSpeed < Extras.CustomSpeed then desiredSpeed = Extras.CustomSpeed end
        local speedDiff = desiredSpeed - currentWalkSpeed
        if speedDiff > 0 then
            local offset = myHum.MoveDirection * (speedDiff * dt)
            pcall(function() myRoot.CFrame = myRoot.CFrame + offset end)
        end
    end
end)

-- ============================================================
-- INSTANT SKILLCHECK (verbatim)
-- ============================================================
local ISC = {
    LastTriggerTick = 0, LastGoalRotation = 0, LastGoalInstance = nil,
    CurrentGoalID = 0, HasClicked = false, isForcingRotation = false,
    RotationConnection = nil,
}
local ISC_Kingscourge = { Active = false, ID = nil, Count = 0 }

local function ISC_GetNearestGenProgress()
    local char = LocalPlayer.Character
    local myHRP = char and char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return 0 end
    local nearest, nearestDist = nil, math.huge
    local map = workspace:FindFirstChild("Map")
    local newGensFolder = map and map:FindFirstChild("new Generators")
    if newGensFolder then
        for _, gen in ipairs(newGensFolder:GetChildren()) do
            if gen.Name == "Generator" then
                local part = gen:FindFirstChild("HitBox", true) or gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
                if part then
                    local dist = (part.Position - myHRP.Position).Magnitude
                    if dist < nearestDist then nearestDist = dist; nearest = gen end
                end
            end
        end
    end
    if not nearest then return 0 end
    local pct = tonumber(nearest:GetAttribute("RepairProgress")) or 0
    if pct <= 1 then pct = pct * 100 end
    return pct
end

local function ISC_PressSkill()
    if tick() - ISC.LastTriggerTick < 0.03 then return end
    ISC.LastTriggerTick = tick()
    if IsMobile then
        local btn = PlayerGui:FindFirstChild("check", true)
        if btn and btn:IsA("GuiObject") then
            local pos = btn.AbsolutePosition; local size = btn.AbsoluteSize
            local inset = game:GetService("GuiService"):GetGuiInset()
            local x = pos.X + size.X / 2 + inset.X
            local y = pos.Y + size.Y / 2 + inset.Y
            task.spawn(function()
                pcall(function()
                    VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.Begin.Value, x, y)
                    task.wait()
                    VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.End.Value, x, y)
                end)
            end)
            pcall(function() if firesignal and btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end end)
        end
    else
        task.spawn(function()
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
        end)
    end
end

local function PressSkill()
    if IsMobile then
        local btn = PlayerGui:FindFirstChild("check", true)
        if btn and btn:IsA("GuiObject") then
            local pos = btn.AbsolutePosition; local size = btn.AbsoluteSize
            local inset = game:GetService("GuiService"):GetGuiInset()
            local x = pos.X + (size.X / 2) + inset.X
            local y = pos.Y + (size.Y / 2) + inset.Y
            pcall(function() VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.Begin.Value, x, y) end)
            task.wait(0.01)
            pcall(function() VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.End.Value, x, y) end)
            pcall(function() if firesignal and btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end end)
        end
    else
        pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)
        task.wait(0.01)
        pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
    end
end

local function GetSkillCheck()
    for _, guiName in ipairs({"SkillCheckPromptGui", "SkillCheckPromptGui-con"}) do
        local gui = PlayerGui:FindFirstChild(guiName, true)
        if gui then
            local check = gui:FindFirstChild("Check", true)
            if check and check.Visible then
                local line = check:FindFirstChild("Line", true)
                local goal = check:FindFirstChild("Goal", true)
                if line and goal then return line, goal end
            end
        end
    end
end

local function AngularDelta(from, to)
    local d = to - from
    if d > 180  then d = d - 360 end
    if d < -180 then d = d + 360 end
    return d
end

local function CrossedZone(prevLr, lr, startPos, endPos)
    local function inZone(r)
        if startPos > endPos then return r >= startPos or r <= endPos
        else return r >= startPos and r <= endPos end
    end
    if inZone(lr) then return true end
    if prevLr == nil then return false end
    local delta = AngularDelta(prevLr, lr)
    local steps = math.abs(math.floor(delta))
    if steps < 2 then return false end
    local stepSize = delta / steps
    for i = 1, steps do
        local sample = (prevLr + stepSize * i) % 360
        if inZone(sample) then return true end
    end
    return false
end

RunService.RenderStepped:Connect(function()
    if not Extras.autoGeneratorEnabled then return end
    local line, goal = GetSkillCheck()
    if not (line and goal) then
        Extras.lastGoalRotation = nil; Extras.hasClickedThisGoal = false
        Extras.lastLineRotation = nil; Extras.lastTick = nil; Extras.wasActive = false
        return
    end
    local lr = line.Rotation % 360
    local gr = goal.Rotation % 360
    local currentTick = os.clock()
    if not Extras.wasActive then
        Extras.wasActive = true; Extras.hasClickedThisGoal = false
        Extras.lastGoalRotation = gr; Extras.lastLineRotation = lr
        Extras.lastTick = currentTick; return
    end
    if Extras.lastGoalRotation ~= nil then
        if math.abs(AngularDelta(Extras.lastGoalRotation, gr)) > 5 then
            Extras.hasClickedThisGoal = false
            Extras.lastLineRotation = nil; Extras.lastTick = nil
        end
    end
    Extras.lastGoalRotation = gr
    if Extras.hasClickedThisGoal then
        Extras.lastLineRotation = lr; Extras.lastTick = currentTick; return
    end
    if Extras.lastLineRotation and Extras.lastTick then
        local dt = currentTick - Extras.lastTick
        if dt > 0 then
            local lineSpeed = AngularDelta(Extras.lastLineRotation, lr) / dt
            local predictedLr = (lr + lineSpeed * dt * LATENCY_COMPENSATION) % 360
            local targetOffset = perfectSkillcheck and 106.5 or 118.0
            local tolerance = perfectSkillcheck and 2.5 or 2.0
            local startPos = (gr + targetOffset - tolerance) % 360
            local endPos = (gr + targetOffset + tolerance) % 360
            if CrossedZone(Extras.lastLineRotation, predictedLr, startPos, endPos) then
                Extras.hasClickedThisGoal = true
                task.spawn(PressSkill)
            end
        end
    end
    Extras.lastLineRotation = lr; Extras.lastTick = currentTick
end)

local lastGenCheck = 0
local cachedProgress = 0
RunService.RenderStepped:Connect(function()
    if not Extras.instantSkillcheckEnabled then return end
    if ISC_Kingscourge.Active then return end
    if tick() - lastGenCheck >= 0.5 then
        lastGenCheck = tick()
        cachedProgress = ISC_GetNearestGenProgress()
    end
    Extras.instantSkillcheckMode = true
    local line, goal = GetSkillCheck()
    if not (line and goal) then
        ISC.HasClicked = false; ISC.LastGoalRotation = 0
        ISC.LastGoalInstance = nil; ISC.CurrentGoalID = 0
        if ISC.RotationConnection then ISC.RotationConnection:Disconnect(); ISC.RotationConnection = nil end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        return
    end
    local gr = goal.Rotation % 360
    local offsetStart = perfectSkillcheck and 104 or 100
    local offsetEnd   = perfectSkillcheck and 108 or 102
    local perfectRot  = (gr + (offsetStart + offsetEnd) / 2) % 360
    if not ISC.isForcingRotation then
        ISC.isForcingRotation = true
        pcall(function() line.Rotation = perfectRot end)
        ISC.isForcingRotation = false
    end
    local isNewGoal = false
    local goalDiff = math.abs(gr - ISC.LastGoalRotation)
    if goalDiff > 180 then goalDiff = 360 - goalDiff end
    if (goalDiff > 0.5) or (ISC.LastGoalInstance ~= goal) then
        isNewGoal = true; ISC.HasClicked = false
    end
    ISC.LastGoalRotation = gr; ISC.LastGoalInstance = goal
    if isNewGoal then
        ISC.CurrentGoalID += 1
        local assignedID = ISC.CurrentGoalID
        if ISC.RotationConnection then ISC.RotationConnection:Disconnect() end
        ISC.RotationConnection = line:GetPropertyChangedSignal("Rotation"):Connect(function()
            if ISC.isForcingRotation then return end
            ISC.isForcingRotation = true
            pcall(function()
                local _, cGoal = GetSkillCheck()
                if cGoal then line.Rotation = (cGoal.Rotation % 360 + (offsetStart + offsetEnd) / 2) % 360 end
            end)
            ISC.isForcingRotation = false
        end)
        if not ISC.HasClicked then
            ISC.HasClicked = true
            task.spawn(function()
                task.wait(0.05)
                if ISC.CurrentGoalID == assignedID then
                    local cl, cg = GetSkillCheck()
                    if cl and cg then
                        ISC_PressSkill()
                        if ISC.RotationConnection then ISC.RotationConnection:Disconnect(); ISC.RotationConnection = nil end
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    local KillerPerks = Remotes and Remotes:WaitForChild("KillerPerks", 5)
    local kingscourgeFolder = KillerPerks and KillerPerks:WaitForChild("kingscourge", 5)
    if kingscourgeFolder then
        local KingScourgeStart = kingscourgeFolder:WaitForChild("KingScourgeStart")
        local KingScourgeHit = kingscourgeFolder:WaitForChild("KingScourgeHit")
        local KingScourgeEnd = kingscourgeFolder:WaitForChild("KingScourgeEnd")
        KingScourgeStart.OnClientEvent:Connect(function(p1, p2, p3)
            if not Extras.instantSkillcheckEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local checkInt = char:FindFirstChild("CheckInterractable")
            if not (checkInt and checkInt:GetAttribute("isRepairing")) then return end
            ISC_Kingscourge.Active = true
            ISC_Kingscourge.ID = p2
            ISC_Kingscourge.Count = p3 or 5
            task.spawn(function()
                for i = 1, ISC_Kingscourge.Count do
                    if not ISC_Kingscourge.Active then break end
                    pcall(function() KingScourgeHit:FireServer(ISC_Kingscourge.ID, "success") end)
                    task.wait(0.03)
                end
                ISC_Kingscourge.Active = false
            end)
        end)
        KingScourgeEnd.OnClientEvent:Connect(function(p1)
            if p1 == ISC_Kingscourge.ID then ISC_Kingscourge.Active = false end
        end)
    end
end)

-- ============================================================
-- GEN BYPASS (verbatim)
-- ============================================================
local GenBypass = {
    Enabled = false, Button = nil, UI = nil, Cache = {}, CacheTimer = 0,
    Processed = {}, HotkeyCode = Enum.KeyCode.G,
}
local RepairEvent = ReplicatedStorage:FindFirstChild("Remotes")
    and ReplicatedStorage.Remotes:FindFirstChild("Generator")
    and ReplicatedStorage.Remotes.Generator:FindFirstChild("RepairEvent")

local function GB_GetAllGenerators()
    local now = tick()
    if now - GenBypass.CacheTimer < 5 then return GenBypass.Cache end
    GenBypass.Cache = {}; GenBypass.CacheTimer = now
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return GenBypass.Cache end
    pcall(function()
        for _, v in pairs(mapFolder:GetDescendants()) do
            if not v:IsA("Model") then continue end
            if v.Name ~= "Generator" then continue end
            local isReal = v:GetAttribute("RepairProgress") ~= nil
                or v:GetAttribute("kickcount") ~= nil
                or v:GetAttribute("ProgressRepair") ~= nil
            if isReal then table.insert(GenBypass.Cache, v) end
        end
    end)
    return GenBypass.Cache
end

local function GB_GetPoints(genModel)
    local points = {}
    pcall(function()
        for _, obj in pairs(genModel:GetChildren()) do
            if obj.Name:find("GeneratorPoint") and obj:IsA("BasePart") then
                table.insert(points, obj)
            end
        end
    end)
    return points
end

local function GB_WaitRepairing(point, timeout)
    local start = tick()
    while tick() - start < (timeout or 1) do
        if point:GetAttribute("IsRepairing") == true then return true end
        task.wait(0.05)
    end
    return false
end

local function GB_DoRepair(targetPoint)
    local genModel = targetPoint.Parent
    if GenBypass.Processed[genModel] then return end
    GenBypass.Processed[genModel] = true
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then GenBypass.Processed[genModel] = nil return end
    local originalCFrame = hrp.CFrame
    pcall(function()
        for _, point in pairs(GB_GetPoints(genModel)) do
            if point ~= targetPoint and point.Parent then
                hrp.Anchored = true; hrp.CFrame = point.CFrame
                task.wait(0.15)
                pcall(function() if RepairEvent then RepairEvent:FireServer(point, true) end end)
                if not GB_WaitRepairing(point, 0.8) then
                    pcall(function() if RepairEvent then RepairEvent:FireServer(point, false) end end)
                    task.wait(0.1); hrp.CFrame = point.CFrame; task.wait(0.15)
                    pcall(function() if RepairEvent then RepairEvent:FireServer(point, true) end end)
                    GB_WaitRepairing(point, 0.5)
                end
                hrp.Anchored = false; task.wait(0.05)
            end
        end
    end)
    pcall(function()
        if hrp and hrp.Parent then
            hrp.Anchored = false; hrp.CFrame = originalCFrame
        end
    end)
    task.wait(0.1)
    pcall(function() if RepairEvent then RepairEvent:FireServer(targetPoint, false) end end)
end

local function GB_GetNearestPoint()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local bestPoint, bestDist = nil, math.huge
    for _, gen in pairs(GB_GetAllGenerators()) do
        for _, point in pairs(GB_GetPoints(gen)) do
            local d = (hrp.Position - point.Position).Magnitude
            if d < bestDist then bestDist = d; bestPoint = point end
        end
    end
    return bestPoint, bestDist
end

local function GB_IsPromptVisible()
    local ok, frame = pcall(function() return LocalPlayer.PlayerGui.pcprompts.Frame.GeneratorRepair end)
    return ok and frame and frame.Visible
end

local function GB_UpdateButton()
    if GenBypass.Button then GenBypass.Button.Visible = GenBypass.Enabled and IsMobile end
end

local function GB_CreateButton()
    local oldUI = LocalPlayer.PlayerGui:FindFirstChild("BypassGenUI")
    if oldUI then oldUI:Destroy() end
    GenBypass.UI = Instance.new("ScreenGui")
    GenBypass.UI.Name = "BypassGenUI"
    GenBypass.UI.ResetOnSpawn = false
    GenBypass.UI.IgnoreGuiInset = true
    GenBypass.UI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    GenBypass.Button = Instance.new("ImageButton")
    GenBypass.Button.Name = "BypassGenButton"
    GenBypass.Button.Size = UDim2.new(0, 55, 0, 55)
    GenBypass.Button.Position = UDim2.new(0.88, 0, 0.55, 0)
    GenBypass.Button.AnchorPoint = Vector2.new(0.5, 0.5)
    GenBypass.Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    GenBypass.Button.BackgroundTransparency = 0.15
    GenBypass.Button.AutoButtonColor = true
    GenBypass.Button.Visible = false
    GenBypass.Button.ZIndex = 10
    GenBypass.Button.Parent = GenBypass.UI
    Instance.new("UICorner", GenBypass.Button).CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", GenBypass.Button)
    s.Color = Color3.fromRGB(255, 255, 255); s.Thickness = 1.5; s.Transparency = 0.4
    local lbl = Instance.new("TextLabel", GenBypass.Button)
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = "BOOST"; lbl.TextColor3 = Color3.fromRGB(170, 255, 80)
    lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold; lbl.ZIndex = 11
    GenBypass.Button.MouseButton1Click:Connect(function()
        if not GenBypass.Enabled then return end
        local bestPoint, bestDist = GB_GetNearestPoint()
        if bestPoint and bestDist <= 8 then GB_DoRepair(bestPoint) end
    end)
end
GB_CreateButton()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5); GB_CreateButton(); GB_UpdateButton()
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if IsMobile then return end
    if input.KeyCode == GenBypass.HotkeyCode and GenBypass.Enabled then
        if not GB_IsPromptVisible() then return end
        local bestPoint, bestDist = GB_GetNearestPoint()
        if not bestPoint or bestDist > 8 then return end
        if GenBypass.Processed[bestPoint.Parent] then return end
        GB_DoRepair(bestPoint)
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not GenBypass.Enabled then return end
    if not GB_IsPromptVisible() then return end
    local bestPoint, bestDist = GB_GetNearestPoint()
    if not bestPoint or bestDist > 8 then return end
    if GenBypass.Processed[bestPoint.Parent] then return end
    GB_DoRepair(bestPoint)
end)

task.spawn(function()
    while true do
        task.wait(2)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for genModel in pairs(GenBypass.Processed) do
                if not genModel or not genModel.Parent then
                    GenBypass.Processed[genModel] = nil; continue
                end
                local nearAny = false
                for _, point in pairs(GB_GetPoints(genModel)) do
                    if point.Parent and (hrp.Position - point.Position).Magnitude <= 10 then
                        nearAny = true; break
                    end
                end
                if not nearAny then GenBypass.Processed[genModel] = nil end
            end
        end
    end
end)

-- ============================================================
-- VEIL CONFIG (verbatim)
-- ============================================================
local VeilConfig = {
    Enabled = false, ShowFOV = true, FOV = 150, SpearSpeed = 165,
    Gravity = workspace.Gravity * 0.5, MaxDist = 200,
    AutoPredict = false, TargetPart = "Torso",
}
local VeilState = {
    chargingSpear = false, touchInput = nil, attackCooldown = false,
    passiveCooldown = false, remoteHooked = false, lastPredictedPos = nil,
}
local VeilVelocityCache = {}
local VeilDraw = {
    FOVCircle = Drawing.new("Circle"),
    Highlight = Instance.new("Highlight"),
    Tracer = Drawing.new("Circle"),
    SpeedText = Drawing.new("Text"),
}
VeilDraw.FOVCircle.Color = Color3.fromRGB(170, 255, 80)
VeilDraw.FOVCircle.Thickness = 1.5
VeilDraw.FOVCircle.Filled = false
VeilDraw.FOVCircle.Visible = false
VeilDraw.Highlight.Name = "VD_VeilTarget"
VeilDraw.Highlight.FillColor = Color3.fromRGB(255, 0, 0)
VeilDraw.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
VeilDraw.Highlight.FillTransparency = 0.5
VeilDraw.Highlight.OutlineTransparency = 0
VeilDraw.Tracer.Thickness = 2
VeilDraw.Tracer.Radius = 5
VeilDraw.Tracer.Color = Color3.fromRGB(170, 255, 80)
VeilDraw.Tracer.Filled = true
VeilDraw.Tracer.Visible = false
VeilDraw.SpeedText.Size = 18
VeilDraw.SpeedText.Color = Color3.fromRGB(170, 255, 80)
VeilDraw.SpeedText.Outline = true
VeilDraw.SpeedText.Center = true
VeilDraw.SpeedText.Visible = false

local function Veil_GetRealVelocity(part, playerName)
    if not part then return Vector3.zero end
    local currentPos = part.Position
    local currentTime = tick()
    if not VeilVelocityCache[playerName] then
        VeilVelocityCache[playerName] = {lastPos = currentPos, lastTime = currentTime, velocity = Vector3.zero}
        return Vector3.zero
    end
    local cache = VeilVelocityCache[playerName]
    local dt = currentTime - cache.lastTime
    if dt > 0.01 then
        local rawVelocity = (currentPos - cache.lastPos) / dt
        if rawVelocity.Magnitude < 100 then cache.velocity = cache.velocity:Lerp(rawVelocity, 0.4) end
    end
    cache.lastPos = currentPos; cache.lastTime = currentTime
    return cache.velocity
end

local function GetHorizontalPrediction(speed)
    if speed < 2 then return 0
    elseif speed >= 2 and speed <= 10 then return 1.8
    elseif speed > 10 and speed <= 16 then return 3.4
    elseif speed > 16 and speed <= 20 then return 4.2
    else return 5.0 end
end

local function veil_getTargetPart(char)
    if VeilConfig.TargetPart == "Head" then return char:FindFirstChild("Head")
    elseif VeilConfig.TargetPart == "Root" then return char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("HumanoidRootPart")
    end
end

local function veil_getClosestSurvivor()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local cam = workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local bestDist = VeilConfig.FOV
    local bestTarget = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
            local char = p.Character
            local hum  = char:FindFirstChildOfClass("Humanoid")
            local part = veil_getTargetPart(char)
            if hum and hum.Health > 0 and part then
                local dist3D = (part.Position - myRoot.Position).Magnitude
                if dist3D <= VeilConfig.MaxDist then
                    local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist2D < bestDist then
                            bestDist = dist2D; bestTarget = { Player = p, Part = part }
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local function veil_setupInterceptor()
    if VeilState.remoteHooked then return end
    task.spawn(function()
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                if getnamecallmethod() == "FireServer" and not checkcaller() then
                    if self.Name == "Spearthrow" and VeilConfig.Enabled then return nil end
                end
                return oldNamecall(self, ...)
            end)
            VeilState.remoteHooked = true
        end)
    end)
end
veil_setupInterceptor()

local function veil_fire()
    if VeilState.attackCooldown then return end
    local myChar = LocalPlayer.Character
    local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local startPos = hrp.Position + (hrp.CFrame.LookVector * 3)
    local targetInfo = veil_getClosestSurvivor()
    local aimDir = workspace.CurrentCamera.CFrame.LookVector
    if targetInfo and targetInfo.Part then
        local targetPart = targetInfo.Part
        local targetPlayer = targetInfo.Player
        local targetPos = targetPart.Position
        local velocity = Veil_GetRealVelocity(targetPart, targetPlayer.Name)
        local horizontalVel = Vector3.new(velocity.X, 0, velocity.Z)
        local speed = horizontalVel.Magnitude
        local predMagnitude = GetHorizontalPrediction(speed)
        local horizontalPredict = Vector3.zero
        if speed >= 2 then horizontalPredict = horizontalVel.Unit * predMagnitude end
        local predictedPos = targetPos + horizontalPredict
        local distance = (targetPos - startPos).Magnitude
        local timeToHit = distance / VeilConfig.SpearSpeed
        local distMult = math.clamp(distance / 100, 1, 2.5)
        local autoGravity = math.max(0, distance - 8)
        local gravity = VeilConfig.AutoPredict and autoGravity or VeilConfig.Gravity
        local drop = 0.5 * gravity * (timeToHit ^ 2) * distMult
        local finalPos = predictedPos + Vector3.new(0, drop, 0)
        local dirToTarget = (finalPos - startPos).Unit
        if hrp.CFrame.LookVector:Dot(dirToTarget) > 0 then
            aimDir = dirToTarget
            VeilState.lastPredictedPos = finalPos
        else
            VeilState.lastPredictedPos = nil
        end
    else
        VeilState.lastPredictedPos = nil
    end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local killers = remotes:FindFirstChild("Killers")
            if killers then
                local veil = killers:FindFirstChild("Veil")
                if veil and veil:FindFirstChild("Spearthrow") then
                    veil.Spearthrow:FireServer(aimDir, VeilConfig.SpearSpeed, startPos)
                    VeilState.attackCooldown = true
                    task.delay(1, function() VeilState.attackCooldown = false end)
                end
            end
        end
    end)
    if not VeilState.passiveCooldown then
        VeilState.passiveCooldown = true
        task.delay(30, function() VeilState.passiveCooldown = false end)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if gp and not isTouch then return end
    local char = LocalPlayer.Character
    local isSpearMode = char and char:GetAttribute("spearmode") == true
    if not VeilConfig.Enabled then return end
    if not isSpearMode then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        VeilState.chargingSpear = true
    elseif isTouch then
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local slasher = pGui:FindFirstChild("Slasher-mob")
            if slasher then
                local ctrl = slasher:FindFirstChild("Controls")
                if ctrl then
                    local attackBtn = ctrl:FindFirstChild("attack")
                    if attackBtn and attackBtn.Visible then
                        local pos = input.Position
                        local absPos = attackBtn.AbsolutePosition
                        local absSize = attackBtn.AbsoluteSize
                        if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
                        and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
                            VeilState.chargingSpear = true
                            VeilState.touchInput = input
                        end
                    end
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if VeilState.chargingSpear
    and (input == VeilState.touchInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
        VeilState.chargingSpear = false
        if VeilState.touchInput == input then VeilState.touchInput = nil end
        veil_fire()
    end
end)

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    local myChar = LocalPlayer.Character
    local isSpearMode = myChar and myChar:GetAttribute("spearmode") == true
    if VeilConfig.Enabled and VeilConfig.ShowFOV and isSpearMode then
        VeilDraw.FOVCircle.Visible = true
        VeilDraw.FOVCircle.Radius = VeilConfig.FOV
        VeilDraw.FOVCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    else
        VeilDraw.FOVCircle.Visible = false
    end
    if VeilState.chargingSpear and VeilConfig.Enabled and isSpearMode then
        local targetInfo = veil_getClosestSurvivor()
        if targetInfo and targetInfo.Part and targetInfo.Part.Parent then
            VeilDraw.Highlight.Parent = targetInfo.Part.Parent
            local rawVel = Veil_GetRealVelocity(targetInfo.Part, targetInfo.Player.Name)
            local spd = Vector3.new(rawVel.X, 0, rawVel.Z).Magnitude
            VeilDraw.SpeedText.Text = string.format("Speed: %.1f", spd)
            VeilDraw.SpeedText.Position = Vector2.new(cam.ViewportSize.X / 2, (cam.ViewportSize.Y / 2) + VeilConfig.FOV + 10)
            VeilDraw.SpeedText.Visible = true
        else
            VeilDraw.Highlight.Parent = nil
            VeilDraw.SpeedText.Visible = false
        end
    else
        VeilDraw.Highlight.Parent = nil
        VeilDraw.SpeedText.Visible = false
    end
    if VeilConfig.Enabled and isSpearMode and VeilState.lastPredictedPos then
        local screenPos, onScreen = cam:WorldToViewportPoint(VeilState.lastPredictedPos)
        local viewport = cam.ViewportSize
        local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
        if onScreen then
            VeilDraw.Tracer.Position = Vector2.new(screenPos.X, screenPos.Y)
        else
            local dx = screenPos.X - center.X
            local dy = screenPos.Y - center.Y
            if math.abs(dx) < 1 and math.abs(dy) < 1 then
                VeilDraw.Tracer.Position = center
            else
                local maxX = viewport.X / 2 - 10
                local maxY = viewport.Y / 2 - 10
                local scaleX = maxX / math.abs(dx)
                local scaleY = maxY / math.abs(dy)
                local scale = math.min(scaleX, scaleY)
                VeilDraw.Tracer.Position = Vector2.new(center.X + dx * scale, center.Y + dy * scale)
            end
        end
        VeilDraw.Tracer.Visible = true
    else
        VeilDraw.Tracer.Visible = false
    end
end)

RunService:BindToRenderStep("MitHubFOV", Enum.RenderPriority.Camera.Value + 1, function()
    if Extras.fovEnabled and workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = Extras.fovValue
    end
end)

-- ============================================================
-- Connections + ESP tables (verbatim)
-- ============================================================
local Connections = {
    selectedHealTarget = nil, healConnection = nil, healOthersConnection = nil,
    autoDodgeConnection = nil, autoHealAllConnection = nil,
}
local ESP = {
    PlayerESP = { Objects = {}, Connections = {} },
    GeneratorESP = { Objects = {}, Connections = {} },
    PalletESP = { Objects = {}, Connections = {} },
    WindowESP = { Objects = {}, Connections = {} },
    scpESP = { Objects = {}, Connections = {} },
}

local SilentAimEnabled = false
local ShootToggleEnabled = false
local SilentAimKey = Enum.KeyCode.H
local ShootToggleKey = Enum.KeyCode.Unknown
local FOV_RADIUS = 150
local SilentTargetMode = "All"
local MobileShootEnabled = false
local MobileShootLocked = false
local currentTarget = nil
local velocityCache = {}
local listeningForSilentKey = false
local listeningForShootKey = false
local HitChance = 100
local TargetPartName = "HumanoidRootPart"

local fovCircle = Drawing.new("Circle")
fovCircle.Filled = false
fovCircle.NumSides = 100
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(170, 255, 80)
fovCircle.Visible = false

-- ============================================================
-- Helpers (verbatim)
-- ============================================================
local function getHrp() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end
local function alive(i) return i and i.Parent end
local function validPart(p) return p and p:IsA("BasePart") and alive(p) end
local function studs(a, b) return math.floor((a - b).Magnitude) end

local function makeBillboard(part, sizeY, espTable)
    local existing = part:FindFirstChild("ESP_Billboard")
    if existing then return existing.TextLabel end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Billboard"
    bb.Adornee = part
    bb.Size = UDim2.new(0, 150, 0, sizeY or 18)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 300
    local tl = Instance.new("TextLabel")
    tl.Name = "TextLabel"
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextStrokeTransparency = 0.3
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.Font = Enum.Font.GothamSemibold
    tl.TextSize = 11
    tl.Parent = bb
    bb.Parent = part
    if espTable then table.insert(espTable, bb) end
    return tl
end

local function createHighlight(obj, color, espTable)
    local existing = obj:FindFirstChild("ESP_Highlight")
    if existing then existing.FillColor = color; return existing end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = obj
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = obj
    if espTable then table.insert(espTable, highlight) end
    return highlight
end

local function doSelfHeal()
    local char = LocalPlayer.Character
    if not char then return end
    local skillCheckRemote = ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function() skillCheckRemote:FireServer("success", 100, char) end)
end

local function doSelfHealTrue()
    local char = LocalPlayer.Character
    if not char then return end
    local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function() healRemote:FireServer(hrp, true) end)
end

local function doSelfHealFalse()
    local char = LocalPlayer.Character
    if not char then return end
    local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function() healRemote:FireServer(hrp, false) end)
end

local function doOthersHealSkillCheck(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local skillCheckRemote = ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent
    pcall(function() skillCheckRemote:FireServer("success", 100, targetPlayer.Character) end)
end

local function doOthersHealTrue(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
    pcall(function() healRemote:FireServer(targetHRP, true) end)
end

local function doOthersHealFalse(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
    pcall(function() healRemote:FireServer(targetHRP, false) end)
end

local function getLever()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    if map:FindFirstChild("Rooftop") then
        local rooftopLever = map.Rooftop:FindFirstChild("Gate")
        if rooftopLever and rooftopLever:FindFirstChild("ExitLever") then
            return rooftopLever.ExitLever:FindFirstChild("Main")
        end
    end
    local normalGate = map:FindFirstChild("Gate")
    if normalGate and normalGate:FindFirstChild("ExitLever") then
        return normalGate.ExitLever:FindFirstChild("Main")
    end
    return nil
end

local function fireLever(state)
    local lever = getLever()
    if lever then
        pcall(function() ReplicatedStorage.Remotes.Exit.LeverEvent:FireServer(lever, state) end)
    end
end

local function makeGenBillboard(part, espTable)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_GenBillboard"
    bb.Adornee = part
    bb.Size = UDim2.new(0, 100, 0, 25)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 300
    local tl = Instance.new("TextLabel")
    tl.Name = "TextLabel"
    tl.Size = UDim2.new(1, 0, 0, 12)
    tl.Position = UDim2.new(0, 0, 0, 0)
    tl.BackgroundTransparency = 1
    tl.Font = Enum.Font.GothamSemibold
    tl.TextSize = 11
    tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tl.TextStrokeTransparency = 0.3
    tl.Parent = bb
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.Size = UDim2.new(1, -4, 0, 5)
    barBg.Position = UDim2.new(0, 2, 1, -7)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    barBg.BorderSizePixel = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
    barBg.Parent = bb
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(170, 255, 80)
    barFill.BorderSizePixel = 0
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
    barFill.Parent = barBg
    bb.Parent = part
    if espTable then table.insert(espTable, bb) end
    return tl, barFill, barBg
end

-- ESP colors
local survivorColor = Color3.fromRGB(0, 255, 0)
local injuredColor = Color3.fromRGB(255, 255, 0)
local killerColor = Color3.fromRGB(255, 60, 60)
local genColor = Color3.fromRGB(0, 170, 255)
local palletColor = Color3.fromRGB(255, 140, 0)
local windowColor = Color3.fromRGB(200, 200, 200)

-- ============================================================
-- COMBAT helpers (verbatim)
-- ============================================================
local LaserLine = Drawing.new("Line")
LaserLine.Visible = false
LaserLine.Color = Color3.fromRGB(170, 255, 80)
LaserLine.Thickness = 2
LaserLine.Transparency = 1

local function getRealVelocity(hrp, playerName)
    if not hrp then return Vector3.zero end
    local currentPos = hrp.Position
    local currentTime = tick()
    if not velocityCache[playerName] then
        velocityCache[playerName] = {lastPos = currentPos, lastTime = currentTime, velocity = Vector3.zero}
        return Vector3.zero
    end
    local cache = velocityCache[playerName]
    local dt = currentTime - cache.lastTime
    if dt > 0.01 then
        local rawVelocity = (currentPos - cache.lastPos) / dt
        if rawVelocity.Magnitude < 100 then cache.velocity = cache.velocity:Lerp(rawVelocity, 0.4) end
    end
    cache.lastPos = currentPos; cache.lastTime = currentTime
    return cache.velocity
end

local function getGunParts()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local tool = char:FindFirstChild("Twist of Fate")
    if not tool then return nil, nil end
    local rightArm = tool:FindFirstChild("Right Arm")
    if not rightArm then return nil, nil end
    local gun = rightArm:FindFirstChild("EmperorGun") or rightArm:FindFirstChild("gun")
    if not gun then return nil, nil end
    local gunPart = gun:FindFirstChildWhichIsA("BasePart")
    if not gunPart then return nil, nil end
    return gun, gunPart
end

local function getMyHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getAutoPrediction(speed, distance)
    if speed < 4 then return 0 end
    if distance < 10 then return 0 end
    if distance <= 20 then return 2.80 end
    return 3.60
end

local function getPredictedPosition(target)
    local hrp = target.Part
    local player = target.Player
    if not hrp then return target.Position, target.Position, 0, 0 end
    local velocity = getRealVelocity(hrp, player.Name)
    local horizontalVel = Vector3.new(velocity.X, 0, velocity.Z)
    local speed = horizontalVel.Magnitude
    local myHRP = getMyHRP()
    local distance = myHRP and (hrp.Position - myHRP.Position).Magnitude or 50
    local targetPos = hrp.Position
    local predValue = getAutoPrediction(speed, distance)
    local horizontalPrediction = Vector3.zero
    if speed > 4 and predValue > 0 then horizontalPrediction = horizontalVel.Unit * predValue end
    local predictedPos = targetPos + horizontalPrediction
    return targetPos, predictedPos, speed, distance
end

local function fireHitscan(targetPos)
    local gun, gunPart = getGunParts()
    if not gun or not gunPart then return false end
    local fireRemote = ReplicatedStorage:FindFirstChild("Remotes")
    if fireRemote then
        fireRemote = fireRemote:FindFirstChild("Items")
        if fireRemote then
            fireRemote = fireRemote:FindFirstChild("Twist of Fate")
            if fireRemote then fireRemote = fireRemote:FindFirstChild("Fire") end
        end
    end
    if not fireRemote then return false end
    local myHRP = getMyHRP()
    if not myHRP then return false end
    local origin = myHRP.Position + Vector3.new(0, 1.2, 0)
    local direction = (targetPos - origin).Unit
    pcall(function() fireRemote:FireServer(gun, direction) end)
    return true
end

local function isValidTargetForMode(player)
    if SilentTargetMode == "All" then return true end
    local isKiller = player.Team == Teams:FindFirstChild("Killer")
    if SilentTargetMode == "Killer" then return isKiller end
    if SilentTargetMode == "Survivor" then return not isKiller end
    return true
end

local function getNearestTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local closestTarget = nil
    local closestDist = 500
    local centerX = camera.ViewportSize.X / 2
    local centerY = camera.ViewportSize.Y / 2
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isValidTargetForMode(player) then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = player.Character:FindFirstChild(TargetPartName)
            if not targetPart then targetPart = player.Character:FindFirstChild("HumanoidRootPart") end
            if hum and hum.Health > 0 and targetPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dx = screenPos.X - centerX
                    local dy = screenPos.Y - centerY
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < closestDist then
                        closestDist = dist
                        closestTarget = {Player = player, Part = targetPart, Position = targetPart.Position, Distance = dist}
                    end
                end
            end
        end
    end
    return closestTarget
end

local function doSilentAimFire()
    if not SilentAimEnabled then return end
    currentTarget = getNearestTarget()
    if currentTarget then
        local chanceHit = math.random(1, 100)
        if chanceHit <= HitChance then
            local _, predictedPos = getPredictedPosition(currentTarget)
            fireHitscan(predictedPos)
        else
            local _, predictedPos = getPredictedPosition(currentTarget)
            local missOffset = Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
            fireHitscan(predictedPos + missOffset)
        end
    end
end

-- ============================================================
-- AUTO PARRY BOT (module-level state)
-- ============================================================
local ParryState = {
    AUTO_PARRY_DISTANCE = 14, AUTO_LOOK_THRESHOLD = 0.45,
    Enabled = false, ShowCircle = true, canParry = true,
    isParrying = false, waitingResult = false,
    killerAnimator = nil, killerChar = nil, killerPlayer = nil,
    parryConnections = {}, firedTracks = {}, gradients = {},
}
local ParryRemote, ParryResult
do
    local daggerFolder = ReplicatedStorage.Remotes.Items:WaitForChild("Parrying Dagger")
    ParryRemote = daggerFolder:WaitForChild("parry")
    ParryResult = daggerFolder:WaitForChild("parryResult")
end
local COLOR_READY = Color3.fromRGB(255, 255, 255)
local COLOR_COOLDOWN = Color3.fromRGB(77, 77, 77)

local function _addGradient(g)
    if not (g and g:IsA("UIGradient")) then return end
    for _, v in ipairs(ParryState.gradients) do if v == g then return end end
    g.Offset = Vector2.new(0, 0.25)
    table.insert(ParryState.gradients, g)
end

local function _setIconsColor(color)
    for _, g in ipairs(ParryState.gradients) do
        if g and g.Parent and g.Parent.Parent then
            local container = g.Parent.Parent
            local icon = container:FindFirstChild("icon")
            if icon then icon.ImageColor3 = color end
            if container.Parent then
                local outerGui = container.Parent:FindFirstChild("Gui")
                if outerGui then outerGui.ImageColor3 = color end
            end
        end
    end
end

local function _refreshParryVisual()
    if not ParryState.canParry or ParryState.isParrying then _setIconsColor(COLOR_COOLDOWN)
    else _setIconsColor(COLOR_READY) end
end

local function _playCooldownTween(duration)
    for _, g in ipairs(ParryState.gradients) do
        if g and g.Parent then
            g.Offset = Vector2.new(0, 0.75)
            local tw = TweenService:Create(g, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Offset = Vector2.new(0, 0.25) })
            tw:Play()
            tw.Completed:Connect(function()
                if g.Offset.Y <= 0.26 then _refreshParryVisual() end
            end)
        end
    end
end

local function _bindPcGradient()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    local survivor = pg:FindFirstChild("Survivor") or pg:FindFirstChild("Survivor-con")
    if not survivor then return end
    local gen = survivor:FindFirstChild("Gen")
    if not gen then return end
    local itemFrame = gen:FindFirstChild("ItemFrame")
    if not itemFrame then return end
    local gui2 = itemFrame:FindFirstChild("Gui")
    if not gui2 then return end
    local bar = gui2:FindFirstChild("Bar")
    if not bar then return end
    local uig = bar:FindFirstChild("UIGradient")
    if uig then _addGradient(uig) end
end

local function _bindMobileGradient()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    local mob = pg:FindFirstChild("Survivor-mob")
    if not mob then return end
    local controls = mob:FindFirstChild("Controls")
    if not controls then return end
    for _, child in ipairs(controls:GetChildren()) do
        if child:IsA("ImageButton") and child.Name == "Gui-mob" then
            local bar = child:FindFirstChild("Bar")
            if bar then
                local uig = bar:FindFirstChild("UIGradient")
                if uig then _addGradient(uig) end
            end
        end
    end
end

local function _tryBindGradients()
    task.wait(0.5); _bindPcGradient(); _bindMobileGradient(); _refreshParryVisual()
end

task.spawn(function()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not pg then return end
    _tryBindGradients()
    pg.ChildAdded:Connect(function(child)
        local n = child.Name
        if n == "Survivor" or n == "Survivor-con" or n == "Survivor-mob" then
            task.wait(0.3); _bindPcGradient(); _bindMobileGradient(); _refreshParryVisual()
        end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5); ParryState.gradients = {}; _tryBindGradients()
end)

ParryResult.OnClientEvent:Connect(function(success, cooldownValue)
    if not ParryState.waitingResult then return end
    ParryState.waitingResult = false
    local cd = tonumber(cooldownValue)
    if cd and cd > 0 then
        ParryState.isParrying = false; ParryState.canParry = false
        _playCooldownTween(cd); _refreshParryVisual()
        task.delay(cd, function()
            ParryState.canParry = true; ParryState.isParrying = false
            _refreshParryVisual()
        end)
    else
        ParryState.canParry = true; ParryState.isParrying = false
        _refreshParryVisual()
    end
end)

local ParryAnimation = Instance.new("Animation")
ParryAnimation.AnimationId = "rbxassetid://127096285501517"

local ATTACK_ANIMS = {
    ["rbxassetid://113255068724446"] = true, ["rbxassetid://74968262036854"] = true,
    ["rbxassetid://110355011987939"] = true, ["rbxassetid://139369275981139"] = true,
    ["rbxassetid://132817836308238"] = true, ["rbxassetid://129784271201071"] = true,
    ["rbxassetid://133963973694098"] = true, ["rbxassetid://117042998468241"] = true,
    ["rbxassetid://105374834496520"] = true, ["rbxassetid://111920872708571"] = true,
    ["rbxassetid://78432063483146"] = true, ["rbxassetid://118907603246885"] = true,
    ["rbxassetid://138720291317243"] = true, ["rbxassetid://115244153053858"] = true,
    ["rbxassetid://130593238885843"] = true, ["rbxassetid://122812055447896"] = true,
    ["rbxassetid://78935059863801"] = true, ["rbxassetid://135002183282873"] = true,
    ["rbxassetid://121216847022485"] = true,
}

local Parry_cachedRoot, Parry_cachedHum
local function _parryRefreshLocalCache()
    local char = LocalPlayer.Character
    if char then
        Parry_cachedRoot = char:FindFirstChild("HumanoidRootPart")
        Parry_cachedHum  = char:FindFirstChildOfClass("Humanoid")
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3); _parryRefreshLocalCache()
    ParryState.canParry = true; ParryState.isParrying = false
    ParryState.waitingResult = false; _refreshParryVisual()
end)
_parryRefreshLocalCache()

local function _playParryAnimation()
    if not Parry_cachedHum then return end
    local anim = Parry_cachedHum:LoadAnimation(ParryAnimation)
    anim:Play()
end

local function _isLocalBusy()
    local char = LocalPlayer.Character
    if not char then return true end
    if LocalPlayer:GetAttribute("IsDead") then return true end
    if char:GetAttribute("IsCarried") then return true end
    if char:GetAttribute("IsHooked") then return true end
    if char:GetAttribute("Knocked") then return true end
    if Parry_cachedRoot and CollectionService:HasTag(Parry_cachedRoot, "doing action") then return true end
    local check = char:FindFirstChild("CheckInterractable")
    if check then
        for _, attr in ipairs({"isVaulting", "isSliding", "isDroppingPallet", "isRepairing", "isHealing", "isUnhooking", "isExiting"}) do
            if check:GetAttribute(attr) then return true end
        end
    end
    return false
end

local function _isPathBlocked(fromPos, toPos)
    local direction = (toPos - fromPos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignoreList = {}
    if ParryState.killerChar then table.insert(ignoreList, ParryState.killerChar) end
    if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
    params.FilterDescendantsInstances = ignoreList
    local result = workspace:Raycast(fromPos, direction, params)
    if result then
        local hitDist = (result.Position - fromPos).Magnitude
        local targetDist = direction.Magnitude
        if hitDist < targetDist - 1 then return true end
    end
    return false
end

local function _doParryBot()
    if not ParryState.canParry or not ParryState.Enabled or ParryState.isParrying then return false end
    if _isLocalBusy() then return false end
    if not Parry_cachedRoot then _parryRefreshLocalCache() end
    if not Parry_cachedRoot then return false end
    local enemyRoot = ParryState.killerChar and ParryState.killerChar:FindFirstChild("HumanoidRootPart")
    if not enemyRoot then return false end
    local distance = (enemyRoot.Position - Parry_cachedRoot.Position).Magnitude
    if distance > ParryState.AUTO_PARRY_DISTANCE then return false end
    local toMe = (Parry_cachedRoot.Position - enemyRoot.Position).Unit
    if enemyRoot.CFrame.LookVector:Dot(toMe) < ParryState.AUTO_LOOK_THRESHOLD then return false end
    if _isPathBlocked(enemyRoot.Position, Parry_cachedRoot.Position) then return false end
    ParryState.canParry = false; ParryState.isParrying = true; ParryState.waitingResult = true
    _refreshParryVisual()
    ParryRemote:FireServer()
    _playParryAnimation()
    task.delay(15, function()
        if ParryState.waitingResult then
            ParryState.waitingResult = false; ParryState.canParry = true
            ParryState.isParrying = false; _refreshParryVisual()
        end
    end)
    return true
end

local function _onTrackDetected(track)
    if not track.Animation then return end
    if ATTACK_ANIMS[track.Animation.AnimationId] then _doParryBot() end
end

local function _parryDisconnectAll()
    for _, c in ipairs(ParryState.parryConnections) do pcall(function() c:Disconnect() end) end
    ParryState.parryConnections = {}
end

local function _parryResetKiller()
    _parryDisconnectAll()
    ParryState.killerAnimator = nil; ParryState.killerChar = nil; ParryState.killerPlayer = nil
end

local function _parryGetKiller()
    local killerTeam = Teams:FindFirstChild("Killer")
    if not killerTeam then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team == killerTeam then return p end
    end
end

function _parryHookKiller()
    local killer = _parryGetKiller()
    if not killer then _parryResetKiller() return false end
    if ParryState.killerPlayer == killer and ParryState.killerAnimator then return true end
    _parryResetKiller()
    ParryState.killerPlayer = killer
    if not killer.Character then killer.CharacterAdded:Wait() end
    ParryState.killerChar = killer.Character
    local hum = ParryState.killerChar:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    ParryState.killerAnimator = hum:FindFirstChildOfClass("Animator")
    if not ParryState.killerAnimator then return false end
    table.insert(ParryState.parryConnections, ParryState.killerAnimator.AnimationPlayed:Connect(_onTrackDetected))
    return true
end

local rangeAdornment = Instance.new("CylinderHandleAdornment")
rangeAdornment.Name = "ParryRange"
rangeAdornment.Radius = ParryState.AUTO_PARRY_DISTANCE
rangeAdornment.InnerRadius = ParryState.AUTO_PARRY_DISTANCE - 0.25
rangeAdornment.Height = 0.05
rangeAdornment.Color3 = Color3.fromRGB(170, 255, 80)
rangeAdornment.AlwaysOnTop = false
rangeAdornment.Adornee = workspace:FindFirstChildOfClass("Terrain")
rangeAdornment.Transparency = 1
rangeAdornment.Parent = CoreGui

RunService.PreRender:Connect(function()
    local char = LocalPlayer.Character
    if not char or not ParryState.Enabled or not ParryState.ShowCircle then
        rangeAdornment.Transparency = 1
    else
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then rangeAdornment.Transparency = 1
        else
            rangeAdornment.Transparency = 0.3
            rangeAdornment.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.6, 0)) * CFrame.Angles(math.pi / 2, 0, 0)
        end
    end
    if not ParryState.Enabled then return end
    if ParryState.isParrying and Parry_cachedHum then Parry_cachedHum.WalkSpeed = 0 end
    if not ParryState.canParry or ParryState.isParrying then return end
    if not ParryState.killerAnimator then _parryHookKiller() end
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() if ParryState.Enabled then _parryHookKiller() end end)
    p:GetPropertyChangedSignal("Team"):Connect(function() if ParryState.Enabled then _parryHookKiller() end end)
end)
for _, p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function() if ParryState.Enabled then _parryHookKiller() end end)
    p:GetPropertyChangedSignal("Team"):Connect(function() if ParryState.Enabled then _parryHookKiller() end end)
end

-- ============================================================
-- KILLER TAB (Counter Auto Parry - module-level state)
-- ============================================================
KillerState = { Enabled = false, Range = 15, Cooldown = 4, lastCounterTick = 0 }
local fakeAttackAnim = Instance.new("Animation")
fakeAttackAnim.AnimationId = "rbxassetid://113255068724446"

local function _getClosestSurvivorForCounter()
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local closestTarget = nil
    local shortestDist = KillerState.Range
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist <= shortestDist then
                    local toSurv = (hrp.Position - myHRP.Position).Unit
                    if myHRP.CFrame.LookVector:Dot(toSurv) > 0.4 then
                        shortestDist = dist; closestTarget = char
                    end
                end
            end
        end
    end
    return closestTarget
end

local function _doFakeAttack()
    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHum then return end
    local animator = myHum:FindFirstChildOfClass("Animator")
    if animator then
        local track = animator:LoadAnimation(fakeAttackAnim)
        track.Priority = Enum.AnimationPriority.Action
        track:Play()
        track:AdjustSpeed(0)
        task.delay(0.2, function() if track then track:Stop(0) end end)
    end
end

RunService.Heartbeat:Connect(function()
    if not KillerState.Enabled then return end
    local now = tick()
    if now - KillerState.lastCounterTick < KillerState.Cooldown then return end
    if not _getClosestSurvivorForCounter() then return end
    KillerState.lastCounterTick = now
    _doFakeAttack()
end)

-- ============================================================
-- MOBILE SHOOT BUTTON (floating FAB, only visible when enabled)
-- ============================================================
local MobileShootBtn = Instance.new("TextButton", CoreGui)
MobileShootBtn.Name = "MitHubMobileShoot"
MobileShootBtn.Size = UDim2.new(0, 70, 0, 70)
MobileShootBtn.Position = UDim2.new(0.85, 0, 0.75, 0)
MobileShootBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
MobileShootBtn.BackgroundTransparency = 0.1
MobileShootBtn.Text = "Shoot"
MobileShootBtn.Font = Enum.Font.GothamBold
MobileShootBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MobileShootBtn.TextSize = 13
MobileShootBtn.Visible = false
MobileShootBtn.ZIndex = 10
Instance.new("UICorner", MobileShootBtn).CornerRadius = UDim.new(1, 0)
local msBtnStroke = Instance.new("UIStroke", MobileShootBtn)
msBtnStroke.Color = Color3.fromRGB(170, 255, 80)
msBtnStroke.Thickness = 2
msBtnStroke.Transparency = 0.2

local msDragging, msDragStart, msStartPos
MobileShootBtn.InputBegan:Connect(function(input)
    if MobileShootLocked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        msDragging = true; msDragStart = input.Position; msStartPos = MobileShootBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if MobileShootLocked then msDragging = false; return end
    if msDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - msDragStart
        MobileShootBtn.Position = UDim2.new(msStartPos.X.Scale, msStartPos.X.Offset + delta.X, msStartPos.Y.Scale, msStartPos.Y.Offset + delta.Y)
    end
end)
MobileShootBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then msDragging = false end
end)
MobileShootBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MobileShootBtn, TweenInfo.new(0.08), {BackgroundTransparency = 0}):Play()
    task.delay(0.12, function()
        TweenService:Create(MobileShootBtn, TweenInfo.new(0.08), {BackgroundTransparency = 0.1}):Play()
    end)
    doSilentAimFire()
end)

-- Combat Laser Tracker
RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end
    if not SilentAimEnabled then currentTarget = nil; LaserLine.Visible = false; return end
    currentTarget = getNearestTarget()
    if currentTarget and currentTarget.Part then
        local screenPos, onScreen = camera:WorldToViewportPoint(currentTarget.Part.Position)
        if onScreen then
            LaserLine.Visible = true
            LaserLine.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            LaserLine.To = Vector2.new(screenPos.X, screenPos.Y)
        else
            LaserLine.Visible = false
        end
    else
        LaserLine.Visible = false
    end
end)

-- ============================================================
-- UI STRUCTURE (using MitHub library)
-- ============================================================
local TabMain   = Window:AddTab({Name = "Main",   Icon = "rbxassetid://6035047377"})
local TabEsp    = Window:AddTab({Name = "ESP",    Icon = "rbxassetid://6034753464"})
local TabMisc   = Window:AddTab({Name = "Misc",   Icon = "rbxassetid://6031263436"})
local TabSpeed  = Window:AddTab({Name = "Speed",  Icon = "rbxassetid://6031280842"})
local TabCombat = Window:AddTab({Name = "Combat", Icon = "rbxassetid://6034753404"})
local TabKiller = Window:AddTab({Name = "Killer", Icon = "rbxassetid://6035047391"})
local TabParry  = Window:AddTab({Name = "Parry",  Icon = "rbxassetid://6031280272"})
local TabVeil   = Window:AddTab({Name = "Veil",   Icon = "rbxassetid://6031280836"})

-- MAIN TAB
local MainSec = TabMain:AddSection({Name = "Main"})
MainSec:AddLabel("Noclip"):AddToggle({Default = false, Flag = "noclip", Callback = function(v)
    States.Noclip = v
    if v then
        _G.NLoop = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if _G.NLoop then _G.NLoop:Disconnect() end
    end
end})
MainSec:AddButton({Name = "FullBright", Callback = function()
    Lighting.Brightness = 2; Lighting.ClockTime = 14
    Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
end})
MainSec:AddButton({Name = "NoFog", Callback = function()
    Lighting.FogStart = 0; Lighting.FogEnd = 999999
end})
MainSec:AddLabel("Anti Fall Damage"):AddToggle({Default = false, Flag = "antifall", Callback = function(v) Extras.antiFallEnabled = v end})
local faLabel = MainSec:AddLabel("Fast Animations")
faLabel:AddToggle({Default = false, Flag = "fastanim", Callback = function(v) Extras.fastAnimEnabled = v end})
faLabel:AddSlider({Min = 2, Max = 10, Default = Extras.fastAnimSpeed, Flag = "fastanim_speed", Callback = function(v) Extras.fastAnimSpeed = v end})
local fovLabel = MainSec:AddLabel("FOV Changer")
fovLabel:AddToggle({Default = false, Flag = "fov_on", Callback = function(v)
    Extras.fovEnabled = v
    if not Extras.fovEnabled and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 70 end
end})
fovLabel:AddSlider({Min = 50, Max = 150, Default = Extras.fovValue, Flag = "fov_val", Callback = function(v) Extras.fovValue = v end})

-- ESP TAB
local EspSec = TabEsp:AddSection({Name = "ESP"})
EspSec:AddLabel("Players ESP"):AddToggle({Default = false, Flag = "p_esp", Callback = function(v)
    States.PlayerESP = v
    if not v then
        for _, obj in pairs(ESP.PlayerESP.Objects) do pcall(function() obj:Destroy() end) end
        ESP.PlayerESP.Objects = {}
        for _, conn in pairs(ESP.PlayerESP.Connections) do pcall(function() conn:Disconnect() end) end
        ESP.PlayerESP.Connections = {}
        return
    end
    local processedPlayers = {}
    local function setupPlayer(player)
        if player == LocalPlayer then return end
        if processedPlayers[player] then return end
        processedPlayers[player] = true
        local function bind(char)
            if not char then return end
            local hrp = char:WaitForChild("HumanoidRootPart", 10)
            local head = char:WaitForChild("Head", 10)
            local hum = char:WaitForChild("Humanoid", 10)
            if not validPart(hrp) or not validPart(head) or not hum then return end
            local label = makeBillboard(head, 18, ESP.PlayerESP.Objects)
            local highlight = nil
            local conn = RunService.Heartbeat:Connect(function()
                if not States.PlayerESP then return end
                if not alive(char) or hum.Health <= 0 then return end
                local myHRP = getHrp()
                if not myHRP then return end
                local isKiller = player.Team == Teams:FindFirstChild("Killer")
                local targetColor = survivorColor
                if isKiller then targetColor = killerColor
                elseif hum.Health < hum.MaxHealth or char:GetAttribute("IsInjured") or char:GetAttribute("Injured") then
                    targetColor = injuredColor
                end
                label.TextColor3 = targetColor
                if not highlight then highlight = createHighlight(char, targetColor, ESP.PlayerESP.Objects) end
                highlight.FillColor = targetColor; highlight.OutlineColor = targetColor
                label.Text = string.format("%s [%d]", player.Name, studs(myHRP.Position, hrp.Position))
            end)
            table.insert(ESP.PlayerESP.Connections, conn)
        end
        if player.Character then bind(player.Character) end
        local charConn = player.CharacterAdded:Connect(bind)
        table.insert(ESP.PlayerESP.Connections, charConn)
    end
    for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
    table.insert(ESP.PlayerESP.Connections, Players.PlayerAdded:Connect(setupPlayer))
end})

EspSec:AddLabel("Generator ESP"):AddToggle({Default = false, Flag = "g_esp", Callback = function(v)
    States.GeneratorESP = v
    if not v then
        for _, obj in pairs(ESP.GeneratorESP.Objects) do pcall(function() obj:Destroy() end) end
        ESP.GeneratorESP.Objects = {}
        for _, conn in pairs(ESP.GeneratorESP.Connections) do pcall(function() conn:Disconnect() end) end
        ESP.GeneratorESP.Connections = {}
        return
    end
    local processedGens = {}
    local function setupGen(gen)
        if not gen:IsA("Model") or gen.Name ~= "Generator" then return end
        if processedGens[gen] then return end
        processedGens[gen] = true
        local part = gen:FindFirstChild("HitBox", true) or gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart", true)
        if not validPart(part) then return end
        local highlight = createHighlight(gen, Color3.fromRGB(0, 170, 255), ESP.GeneratorESP.Objects)
        highlight.FillTransparency = 0.7; highlight.OutlineColor = Color3.fromRGB(0, 200, 255)
        local label, barFill, barBg = makeGenBillboard(part, ESP.GeneratorESP.Objects)
        label.TextColor3 = genColor
        local conn = RunService.Heartbeat:Connect(function()
            if not States.GeneratorESP or not alive(gen) then label.Text = ""; return end
            local repairAttr = gen:GetAttribute("RepairProgress")
            local pct = 0
            if repairAttr then
                pct = tonumber(repairAttr) or 0
                if pct <= 1 then pct = pct * 100 end
            end
            pct = math.clamp(pct, 0, 100)
            local myHRP = getHrp()
            local dist = myHRP and studs(myHRP.Position, part.Position) or 0
            label.Text = string.format("GEN %d%% [%ds]", pct, dist)
            local barColor = Color3.fromRGB(255, 0, 0)
            if pct >= 100 then barColor = Color3.fromRGB(0, 255, 0)
            elseif pct > 80 then barColor = Color3.fromRGB(100, 255, 0)
            elseif pct > 50 then barColor = Color3.fromRGB(255, 255, 0)
            elseif pct > 20 then barColor = Color3.fromRGB(255, 150, 0) end
            barFill.BackgroundColor3 = barColor
            barFill.Size = UDim2.new(pct / 100, 0, 1, 0)
            if pct >= 100 then
                label.Visible = false; barBg.Visible = false; barFill.Visible = false; highlight.Enabled = false
            else
                label.Visible = true; barBg.Visible = true; barFill.Visible = true; highlight.Enabled = true
            end
        end)
        table.insert(ESP.GeneratorESP.Connections, conn)
    end
    if workspace:FindFirstChild("Map") then
        for _, o in ipairs(workspace.Map:GetDescendants()) do setupGen(o) end
        table.insert(ESP.GeneratorESP.Connections, workspace.Map.DescendantAdded:Connect(setupGen))
    end
end})

EspSec:AddLabel("Pallets ESP"):AddToggle({Default = false, Flag = "pa_esp", Callback = function(v)
    States.PalletESP = v
    if not v then
        for _, obj in pairs(ESP.PalletESP.Objects) do pcall(function() obj:Destroy() end) end
        ESP.PalletESP.Objects = {}; ESP.PalletESP.Connections = {}
        for _, conn in pairs(ESP.PalletESP.Connections) do pcall(function() conn:Disconnect() end) end
        return
    end
    local processed = {}
    local function handlePallet(m)
        if not m:IsA("Model") or processed[m] then return end
        local lname = m.Name:lower()
        if not (lname:find("pallet") and not lname:find("crate")) then return end
        local part = m:FindFirstChildWhichIsA("BasePart", true)
        if not validPart(part) then return end
        processed[m] = true
        local label = makeBillboard(part, 16, ESP.PalletESP.Objects)
        label.Text = "Pallet"; label.TextColor3 = palletColor
    end
    if workspace:FindFirstChild("Map") then
        for _, o in ipairs(workspace.Map:GetDescendants()) do handlePallet(o) end
        table.insert(ESP.PalletESP.Connections, workspace.Map.DescendantAdded:Connect(handlePallet))
    end
end})

EspSec:AddLabel("Windows ESP"):AddToggle({Default = false, Flag = "w_esp", Callback = function(v)
    States.WindowESP = v
    if not v then
        for _, obj in pairs(ESP.WindowESP.Objects) do pcall(function() obj:Destroy() end) end
        ESP.WindowESP.Objects = {}; ESP.WindowESP.Connections = {}
        for _, conn in pairs(ESP.WindowESP.Connections) do pcall(function() conn:Disconnect() end) end
        return
    end
    local processed = {}
    local function handleWindow(m)
        if not m:IsA("Model") or processed[m] then return end
        if m.Name:lower() ~= "window" then return end
        local part = m:FindFirstChild("inviswall", true) or m:FindFirstChildWhichIsA("BasePart", true)
        if not validPart(part) then return end
        processed[m] = true
        local label = makeBillboard(part, 16, ESP.WindowESP.Objects)
        label.Text = "Window"; label.TextColor3 = windowColor
    end
    if workspace:FindFirstChild("Map") then
        for _, o in ipairs(workspace.Map:GetDescendants()) do handleWindow(o) end
        table.insert(ESP.WindowESP.Connections, workspace.Map.DescendantAdded:Connect(handleWindow))
    end
end})

EspSec:AddLabel("SCP ESP"):AddToggle({Default = false, Flag = "s_esp", Callback = function(v)
    if not v then
        for _, obj in pairs(ESP.scpESP.Objects) do pcall(function() obj:Destroy() end) end
        ESP.scpESP.Objects = {}; ESP.scpESP.Connections = {}
        for _, conn in pairs(ESP.scpESP.Connections) do pcall(function() conn:Disconnect() end) end
        return
    end
    local function setupSCP(model)
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local highlight = createHighlight(model, Color3.fromRGB(120, 0, 180), ESP.scpESP.Objects)
        highlight.OutlineColor = Color3.fromRGB(180, 0, 255); highlight.Enabled = false
        local label = makeBillboard(hrp, 16, ESP.scpESP.Objects)
        label.TextColor3 = Color3.fromRGB(200, 0, 255); label.Text = ""
        local activated = false; local lastPos = hrp.Position
        local conn = RunService.Heartbeat:Connect(function()
            if not alive(model) then label.Text = ""; highlight.Enabled = false; return end
            local myHRP = getHrp()
            if not myHRP then return end
            local hum = model:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if not activated then
                local moved = (hrp.Position - lastPos).Magnitude; lastPos = hrp.Position
                if moved > 0.05 then activated = true else return end
            end
            if hum.Health > 0 then
                label.Text = string.format("%s [%d]", model.Name, studs(myHRP.Position, hrp.Position))
                highlight.Enabled = true
            else label.Text = ""; highlight.Enabled = false end
        end)
        table.insert(ESP.scpESP.Connections, conn)
    end
    local function scanMap()
        local map = workspace:FindFirstChild("Map")
        if not map then return end
        for _, area in ipairs(map:GetChildren()) do
            for _, child in ipairs(area:GetChildren()) do
                local name = child.Name:lower()
                if name == "scp" or name:match("^scp%d$") then setupSCP(child) end
            end
        end
    end
    scanMap()
    table.insert(ESP.scpESP.Connections, workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if name == "scp" or name:match("^scp%d$") then task.wait(0.2); setupSCP(obj) end
        end
    end))
end})

-- MISC TAB
local MiscSec = TabMisc:AddSection({Name = "Misc"})
MiscSec:AddLabel("Instant Heal (Self)"):AddToggle({Default = false, Flag = "ih_self", Callback = function(v)
    States.InstantHeal = v
    if v then
        local sc, t, f = 0, 0, 0
        local active = false
        Connections.healConnection = RunService.Heartbeat:Connect(function(dt)
            if not States.InstantHeal then return end
            local myHum = getHum()
            if not myHum or myHum.Health >= myHum.MaxHealth * 0.9 then return end
            sc = sc + dt; if sc >= 0.05 then sc = 0; doSelfHeal() end
            t = t + dt; if t >= 0.06 and not active then t = 0; active = true; doSelfHealTrue() end
            f = f + dt; if f >= 0.09 and active then f = 0; active = false; doSelfHealFalse(); t = -0.10 end
        end)
    else
        if Connections.healConnection then Connections.healConnection:Disconnect(); Connections.healConnection = nil end
    end
end})

local healOthersLabel = MiscSec:AddLabel("Instant Heal Others")
local healOthersDropdown = healOthersLabel:AddDropdown({
    Default = "(none)", Values = {"(none)"}, Multi = false, Flag = "ih_others",
    Callback = function(selected)
        if selected == "(none)" or not selected then
            States.InstantHealOthers = false; Connections.selectedHealTarget = nil
            if Connections.healOthersConnection then Connections.healOthersConnection:Disconnect(); Connections.healOthersConnection = nil end
            return
        end
        local target = Players:FindFirstChild(selected)
        if not target then return end
        Connections.selectedHealTarget = target
        States.InstantHealOthers = true
        if Connections.healOthersConnection then Connections.healOthersConnection:Disconnect() end
        local sc, t, f = 0, 0, 0; local active = false
        Connections.healOthersConnection = RunService.Heartbeat:Connect(function(dt)
            if not States.InstantHealOthers or not Connections.selectedHealTarget then return end
            local targetChar = Connections.selectedHealTarget.Character
            local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
            if not targetHum or targetHum.Health >= targetHum.MaxHealth * 0.9 then return end
            sc = sc + dt; if sc >= 0.05 then sc = 0; doOthersHealSkillCheck(Connections.selectedHealTarget) end
            t = t + dt; if t >= 0.09 and not active then t = 0; active = true; doOthersHealTrue(Connections.selectedHealTarget) end
            f = f + dt; if f >= 0.07 and active then f = 0; active = false; doOthersHealFalse(Connections.selectedHealTarget); t = -0.10 end
        end)
    end,
})

local function _updateHealOthersList()
    local list = {"(none)"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    pcall(function() healOthersDropdown:SetValues(list) end)
end
Players.PlayerAdded:Connect(_updateHealOthersList)
Players.PlayerRemoving:Connect(_updateHealOthersList)
_updateHealOthersList()

MiscSec:AddLabel("Auto Heal All heh)"):AddToggle({Default = false, Flag = "ah_all", Callback = function(v)
    States.AutoHealAll = v
    if v then
        local timers = {}
        Connections.autoHealAllConnection = RunService.Heartbeat:Connect(function(dt)
            if not States.AutoHealAll then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.9 then
                        if not timers[player] then timers[player] = {sc=0, t=0, f=0, active=false} end
                        local tm = timers[player]
                        tm.sc = tm.sc + dt; if tm.sc >= 0.05 then tm.sc = 0; doOthersHealSkillCheck(player) end
                        tm.t = tm.t + dt; if tm.t >= 0.09 and not tm.active then tm.t = 0; tm.active = true; doOthersHealTrue(player) end
                        tm.f = tm.f + dt; if tm.f >= 0.07 and tm.active then tm.f = 0; tm.active = false; doOthersHealFalse(player); tm.t = -0.10 end
                    else timers[player] = nil end
                end
            end
        end)
    else
        if Connections.autoHealAllConnection then Connections.autoHealAllConnection:Disconnect(); Connections.autoHealAllConnection = nil end
    end
end})

local gbLabel = MiscSec:AddLabel("Gen Fast Bypass")
gbLabel:AddToggle({Default = false, Flag = "gb_on", Callback = function(v)
    GenBypass.Enabled = v; GB_UpdateButton()
end})
gbLabel:AddKeybind({Default = "G", Flag = "gb_key", Callback = function()
    if not GenBypass.Enabled then return end
    if not GB_IsPromptVisible() then return end
    local bestPoint, bestDist = GB_GetNearestPoint()
    if not bestPoint or bestDist > 8 then return end
    if GenBypass.Processed[bestPoint.Parent] then return end
    GB_DoRepair(bestPoint)
end})

MiscSec:AddLabel("Auto Generator"):AddToggle({Default = false, Flag = "a_gen", Callback = function(v) Extras.autoGeneratorEnabled = v end})
MiscSec:AddLabel("Perfect Mode"):AddToggle({Default = true, Flag = "perfect", Callback = function(v) perfectSkillcheck = v end})
MiscSec:AddLabel("Generator Boost"):AddToggle({Default = false, Flag = "gen_boost", Callback = function(v)
    Extras.genBoostEnabled = v
    if v then
        task.spawn(function()
            while Extras.genBoostEnabled do
                pcall(function() ReplicatedStorage.Remotes.Perks.perfectionistplanning:FireServer("applyBoost", "fast") end)
                task.wait(0.2)
            end
        end)
    end
end})
MiscSec:AddLabel("Instant Skillcheck"):AddToggle({Default = false, Flag = "isc", Callback = function(v)
    Extras.instantSkillcheckEnabled = v
    if not v then
        Extras.instantSkillcheckMode = false
        if ISC.RotationConnection then ISC.RotationConnection:Disconnect(); ISC.RotationConnection = nil end
        ISC.HasClicked = false; ISC.LastGoalInstance = nil; ISC.CurrentGoalID = 0
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end})
MiscSec:AddLabel("Auto Dodge"):AddToggle({Default = false, Flag = "a_dodge", Callback = function(v)
    States.AutoDodge = v
    if v then
        task.spawn(function()
            while States.AutoDodge do
                pcall(function() ReplicatedStorage.Remotes.Mechanics.ChangeAttribute:FireServer("Crouchingserver", true) end)
                task.wait(0.20)
            end
        end)
    end
end})
MiscSec:AddLabel("Auto Lever"):AddToggle({Default = false, Flag = "a_lever", Callback = function(v)
    States.AutoLever = v
    if v then
        fireLever(true)
        task.spawn(function() while States.AutoLever do fireLever(true); task.wait(0.5) end end)
    else fireLever(false) end
end})

-- SPEED TAB
local SpeedSec = TabSpeed:AddSection({Name = "Speed"})
local nsLabel = SpeedSec:AddLabel("NoSlowdown")
nsLabel:AddToggle({Default = false, Flag = "ns_on", Callback = function(v) Extras.NoSlowdown = v end})
nsLabel:AddSlider({Min = 0, Max = 100, Default = Extras.CustomSpeed, Flag = "ns_speed", Callback = function(v) Extras.CustomSpeed = v end})
SpeedSec:AddButton({Name = "Reset Speed", Callback = function()
    Extras.CustomSpeed = 17
    if Extras.NoSlowdown then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 17 end
    end
end})
SpeedSec:AddLabel("NoSlowdown boosts walk speed while moving. Set 17 = normal, 30+ = fast.", true)

-- COMBAT TAB
local CombatSec = TabCombat:AddSection({Name = "Combat"})
local saLabel = CombatSec:AddLabel("Silent Aim")
saLabel:AddToggle({Default = false, Flag = "sa_on", Callback = function(v)
    SilentAimEnabled = v
    if not v then currentTarget = nil; velocityCache = {}; LaserLine.Visible = false end
    MobileShootBtn.Visible = SilentAimEnabled and MobileShootEnabled
end})
saLabel:AddKeybind({Default = "H", Flag = "sa_key", Callback = function()
    SilentAimEnabled = not SilentAimEnabled
    if not SilentAimEnabled then currentTarget = nil; velocityCache = {}; LaserLine.Visible = false end
    MobileShootBtn.Visible = SilentAimEnabled and MobileShootEnabled
end})
CombatSec:AddLabel("Target Part"):AddDropdown({Default = "Root", Values = {"Root", "Head", "Torso"}, Multi = false, Flag = "sa_part", Callback = function(v)
    if v == "Root" then TargetPartName = "HumanoidRootPart" else TargetPartName = v end
end})
CombatSec:AddLabel("Hit Chance (%)"):AddSlider({Min = 1, Max = 100, Default = 100, Flag = "sa_chance", Callback = function(v) HitChance = v end})
CombatSec:AddLabel("Target Selection"):AddDropdown({Default = "All", Values = {"All", "Survivor", "Killer"}, Multi = false, Flag = "sa_target", Callback = function(v) SilentTargetMode = v end})
local shootLabel = CombatSec:AddLabel("Shoot Toggle")
shootLabel:AddToggle({Default = false, Flag = "st_on", Callback = function(v) ShootToggleEnabled = v end})
shootLabel:AddKeybind({Default = nil, Flag = "st_key", Callback = function() if ShootToggleEnabled then doSilentAimFire() end end})
CombatSec:AddLabel("Mobile Shoot Button"):AddToggle({Default = false, Flag = "ms_btn", Callback = function(v)
    MobileShootEnabled = v; MobileShootBtn.Visible = MobileShootEnabled and SilentAimEnabled
end})
CombatSec:AddLabel("Lock Mobile Toggle"):AddToggle({Default = false, Flag = "lm_lock", Callback = function(v) MobileShootLocked = v end})

-- KILLER TAB
local KillerSec = TabKiller:AddSection({Name = "Counter Auto Parry"})
KillerSec:AddLabel("Counter Auto Parry"):AddToggle({Default = false, Flag = "cap_on", Callback = function(v) KillerState.Enabled = v end})
KillerSec:AddLabel("Counter Range"):AddSlider({Min = 5, Max = 30, Default = 15, Flag = "cap_range", Callback = function(v) KillerState.Range = v end})
KillerSec:AddLabel("Cooldown (sec)"):AddSlider({Min = 1, Max = 15, Default = 4, Flag = "cap_cd", Callback = function(v) KillerState.Cooldown = v end})
KillerSec:AddLabel("Counter Auto Parry triggers fake attack animation when survivor is in range, causing their auto-parry bot to waste their parry.", true)

-- PARRY TAB
local ParrySec = TabParry:AddSection({Name = "Auto Parry Bot"})
ParrySec:AddLabel("Auto Parry Bot"):AddToggle({Default = false, Flag = "ap_on", Callback = function(v)
    ParryState.Enabled = v
    if v then _parryHookKiller()
    else _parryResetKiller(); rangeAdornment.Transparency = 1 end
    _refreshParryVisual()
end})
ParrySec:AddLabel("Parry Circle"):AddToggle({Default = true, Flag = "ap_circle", Callback = function(v)
    ParryState.ShowCircle = v
    if not ParryState.Enabled then rangeAdornment.Transparency = 1 end
end})
ParrySec:AddLabel("Range (studs)"):AddSlider({Min = 1, Max = 60, Default = 14, Flag = "ap_range", Callback = function(v)
    ParryState.AUTO_PARRY_DISTANCE = v
    rangeAdornment.Radius = v
    rangeAdornment.InnerRadius = v - 0.25
end})

-- VEIL TAB
local VeilSec = TabVeil:AddSection({Name = "Veil"})
VeilSec:AddLabel("Silent Aim (Spear)"):AddToggle({Default = false, Flag = "v_sa", Callback = function(v)
    VeilConfig.Enabled = v
    if not v then
        VeilDraw.FOVCircle.Visible = false; VeilDraw.Highlight.Parent = nil
        VeilDraw.Tracer.Visible = false; VeilDraw.SpeedText.Visible = false
    end
end})
VeilSec:AddLabel("Auto Predict (Fisika)"):AddToggle({Default = false, Flag = "v_ap", Callback = function(v) VeilConfig.AutoPredict = v end})
VeilSec:AddLabel("Show FOV Circle"):AddToggle({Default = true, Flag = "v_fov", Callback = function(v) VeilConfig.ShowFOV = v end})
VeilSec:AddLabel("FOV Radius"):AddSlider({Min = 50, Max = 500, Default = 150, Flag = "v_fov_r", Callback = function(v) VeilConfig.FOV = v end})
VeilSec:AddLabel("Spear Speed"):AddSlider({Min = 50, Max = 400, Default = 165, Flag = "v_spd", Callback = function(v) VeilConfig.SpearSpeed = v end})
VeilSec:AddLabel("Target Part"):AddDropdown({Default = "Torso", Values = {"Torso", "Head", "Root"}, Multi = false, Flag = "v_part", Callback = function(v) VeilConfig.TargetPart = v end})

-- USER SETTINGS
Window.UserSettings:AddLabel("Menu Keybind"):AddKeybind({Default = "Insert", Callback = function(v) Window.Keybind = v end})
Window.UserSettings:AddLabel("Menu Scale"):AddDropdown({
    Default = "Default", Values = {"Default", "Large", "Mobile", "Small"},
    Callback = function(v) Window:SetSize(MitHub.Scales[v]) end
})

Notification.new({Title = "MITHUB CRAZY", Content = "All features loaded. Have fun!", Duration = 5})
