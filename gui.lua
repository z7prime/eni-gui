-- z7prime GUI - ENI'nin özel yapımı
-- K tuşu ile aç/kapat

local Library = nil
local Window = nil
local menuVisible = true

local function createGUI()
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
    Window = Library.CreateLib("z7prime", "BloodTheme")
    
    local guiColors = {
        Background = Color3.fromRGB(20, 20, 20),
        Text = Color3.fromRGB(255, 255, 255),
        Button = Color3.fromRGB(40, 40, 40),
        Accent = Color3.fromRGB(255, 0, 0)
    }
    
    local function updateColors()
        if not Library then return end
        for _, v in pairs(Library:GetChildren()) do
            if v:IsA("Frame") then
                v.BackgroundColor3 = guiColors.Background
                for _, child in pairs(v:GetChildren()) do
                    if child:IsA("TextLabel") then
                        child.TextColor3 = guiColors.Text
                    elseif child:IsA("TextButton") then
                        child.BackgroundColor3 = guiColors.Button
                        child.TextColor3 = guiColors.Text
                    elseif child:IsA("ScrollingFrame") then
                        child.BackgroundColor3 = guiColors.Background
                    elseif child:IsA("Frame") then
                        child.BackgroundColor3 = guiColors.Background
                    end
                end
            end
        end
    end

    local player = game:GetService("Players").LocalPlayer
    local mouse = player:GetMouse()
    local camera = game:GetService("Workspace").CurrentCamera
    local runService = game:GetService("RunService")
    local plrs = game:GetService("Players")
    local lplr = plrs.LocalPlayer

    local aimEnabled = false
    local holdAimEnabled = false
    local fovSize = 90
    local fovVisible = true
    local teamCheck = true
    local targets = {}
    local aimPart = "Head"
    local isMousePressed = false
    local maxAimDistance = 999
    local wallCheckEnabled = true
    local silentAimEnabled = false
    local silentAimTarget = nil
    local silentAimHitbox = "Head"
    local autoShootEnabled = false
    local autoShootDelay = 0.1
    local autoShootTarget = nil
    local lastShootTime = 0
    local autoShootMode = "FOV"
    local triggerbotEnabled = false
    local triggerbotDelay = 0.01
    local triggerbotLastShoot = 0
    local triggerbotMode = "Instant"
    local espEnabled = false
    local espBoxes = {}
    local espNames = {}
    local espHealthBars = {}
    local espTracers = {}
    local espAutoRefresh = true
    local lastESPRefresh = 0
    local refreshInterval = 5
    local speedEnabled = false
    local speedValue = 50
    local jumpEnabled = false
    local jumpValue = 100

    local function isVisible(part)
        if not part or not camera then return false end
        if not wallCheckEnabled then return true end
        local character = lplr.Character
        if not character then return false end
        local origin = camera.CFrame.Position
        local target = part.Position
        local ray = Ray.new(origin, (target - origin).Unit * (target - origin).Magnitude)
        local hit, hitPos = workspace:FindPartOnRay(ray, character)
        if hit then
            if hit:IsDescendantOf(part.Parent) then return true end
            return false
        end
        return true
    end

    local function updateTargets()
        targets = {}
        for _, p in pairs(plrs:GetPlayers()) do
            if p ~= player then table.insert(targets, p) end
        end
    end
    updateTargets()

    plrs.PlayerAdded:Connect(function(p)
        if p ~= player then
            table.insert(targets, p)
            if espEnabled then createESP(p) end
        end
    end)

    plrs.PlayerRemoving:Connect(function(p)
        if espBoxes[p] then espBoxes[p]:Remove() espBoxes[p] = nil end
        if espNames[p] then espNames[p]:Remove() espNames[p] = nil end
        if espHealthBars[p] then espHealthBars[p]:Remove() espHealthBars[p] = nil end
        if espTracers[p] then espTracers[p]:Remove() espTracers[p] = nil end
    end)

    local function createESP(plr)
        if not plr or plr == player then return end
        local box = Drawing.new("Square")
        box.Visible = false
        box.Color = guiColors.Accent
        box.Thickness = 2
        box.Filled = false
        espBoxes[plr] = box
        
        local nameTag = Drawing.new("Text")
        nameTag.Visible = false
        nameTag.Color = guiColors.Text
        nameTag.Size = 16
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.Text = plr.Name
        espNames[plr] = nameTag
        
        local healthText = Drawing.new("Text")
        healthText.Visible = false
        healthText.Color = Color3.fromRGB(0, 255, 0)
        healthText.Size = 14
        healthText.Center = true
        healthText.Outline = true
        espHealthBars[plr] = healthText
        
        local tracer = Drawing.new("Line")
        tracer.Visible = false
        tracer.Color = guiColors.Accent
        tracer.Thickness = 1
        espTracers[plr] = tracer
    end

    for _, plr in pairs(plrs:GetPlayers()) do
        if plr ~= player then createESP(plr) end
    end

    local function refreshESP()
        for plr, box in pairs(espBoxes) do if box then box:Remove() end end
        for plr, name in pairs(espNames) do if name then name:Remove() end end
        for plr, health in pairs(espHealthBars) do if health then health:Remove() end end
        for plr, tracer in pairs(espTracers) do if tracer then tracer:Remove() end end
        espBoxes = {}; espNames = {}; espHealthBars = {}; espTracers = {}
        for _, plr in pairs(plrs:GetPlayers()) do
            if plr ~= player then createESP(plr) end
        end
    end

    spawn(function()
        while wait(1) do
            if espEnabled and espAutoRefresh then
                local currentTime = tick()
                if currentTime - lastESPRefresh >= refreshInterval then
                    refreshESP()
                    lastESPRefresh = currentTime
                end
            end
        end
    end)

    runService.RenderStepped:Connect(function()
        if not espEnabled then
            for _, box in pairs(espBoxes) do if box then box.Visible = false end end
            for _, name in pairs(espNames) do if name then name.Visible = false end end
            for _, health in pairs(espHealthBars) do if health then health.Visible = false end end
            for _, tracer in pairs(espTracers) do if tracer then tracer.Visible = false end end
            return
        end
        
        for _, plr in pairs(plrs:GetPlayers()) do
            if plr == player then continue end
            if not plr.Character then continue end
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            local head = plr.Character:FindFirstChild("Head")
            local humanoid = plr.Character:FindFirstChild("Humanoid")
            if not root or not head or not humanoid then continue end
            local pos = root.Position
            local screenPos, onScreen = camera:WorldToViewportPoint(pos)
            if not onScreen then
                if espBoxes[plr] then espBoxes[plr].Visible = false end
                if espNames[plr] then espNames[plr].Visible = false end
                if espHealthBars[plr] then espHealthBars[plr].Visible = false end
                if espTracers[plr] then espTracers[plr].Visible = false end
                continue
            end
            if espBoxes[plr] then
                local size = Vector2.new(2000 / screenPos.Z, 2500 / screenPos.Z)
                espBoxes[plr].Position = Vector2.new(screenPos.X - size.X/2, screenPos.Y - size.Y/2)
                espBoxes[plr].Size = size
                espBoxes[plr].Visible = true
            end
            if espNames[plr] then
                local headPos = camera:WorldToViewportPoint(head.Position)
                espNames[plr].Position = Vector2.new(headPos.X, headPos.Y - 40)
                espNames[plr].Visible = true
            end
            if espHealthBars[plr] and humanoid then
                local headPos = camera:WorldToViewportPoint(head.Position)
                local health = humanoid.Health
                local maxHealth = humanoid.MaxHealth
                espHealthBars[plr].Text = string.format("%.0f/%.0f", health, maxHealth)
                espHealthBars[plr].Position = Vector2.new(headPos.X, headPos.Y - 20)
                espHealthBars[plr].Visible = true
            end
            if espTracers[plr] then
                local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                espTracers[plr].From = center
                espTracers[plr].To = Vector2.new(screenPos.X, screenPos.Y)
                espTracers[plr].Visible = true
            end
        end
    end)

    local fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Radius = fovSize
    fovCircle.Color = guiColors.Accent
    fovCircle.Thickness = 2
    fovCircle.NumSides = 60
    fovCircle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

    runService.RenderStepped:Connect(function()
        fovCircle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        fovCircle.Radius = fovSize
        fovCircle.Visible = fovVisible and (aimEnabled or silentAimEnabled or autoShootEnabled or triggerbotEnabled or holdAimEnabled)
    end)

    local function getTarget(partName)
        partName = partName or aimPart
        local closestTarget = nil
        local closestDistance = fovSize
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        for _, target in pairs(targets) do
            if target and target.Character and target.Character:FindFirstChild(partName) then
                if teamCheck and target.Team == player.Team then continue end
                local part = target.Character[partName]
                local partPos = part.Position
                local myPos = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                if myPos then
                    local distance = (partPos - myPos.Position).Magnitude
                    if distance > maxAimDistance then continue end
                end
                if wallCheckEnabled and not isVisible(part) then continue end
                if partName == "Head" then partPos = part.Position + Vector3.new(0, part.Size.Y/4, 0) end
                local pos, onScreen = camera:WorldToViewportPoint(partPos)
                if onScreen then
                    local targetPos = Vector2.new(pos.X, pos.Y)
                    local distance = (targetPos - center).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestTarget = part
                    end
                end
            end
        end
        return closestTarget
    end

    mouse.Button1Down:Connect(function() isMousePressed = true end)
    mouse.Button1Up:Connect(function() isMousePressed = false end)

    runService.RenderStepped:Connect(function()
        if holdAimEnabled and isMousePressed then
            local target = getTarget("Head")
            if target then
                camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position + Vector3.new(0, target.Size.Y/4, 0))
            end
        end
    end)

    mouse.Button1Down:Connect(function()
        if aimEnabled and not holdAimEnabled then
            local target = getTarget(aimPart)
            if target then
                camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position + Vector3.new(0, target.Size.Y/4, 0))
            end
        end
    end)

    local function getCrosshairTarget()
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local smallestDist = math.huge
        local bestTarget = nil
        for _, target in pairs(targets) do
            if target and target.Character and target.Character:FindFirstChild("Head") then
                if teamCheck and target.Team == player.Team then continue end
                local head = target.Character.Head
                local myPos = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                if myPos then
                    local distance = (head.Position - myPos.Position).Magnitude
                    if distance > maxAimDistance then continue end
                end
                if wallCheckEnabled and not isVisible(head) then continue end
                local headPos, onScreen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y/4, 0))
                if onScreen then
                    local headScreen = Vector2.new(headPos.X, headPos.Y)
                    local dist = (headScreen - center).Magnitude
                    if dist < 20 then
                        if dist < smallestDist then
                            smallestDist = dist
                            bestTarget = head
                        end
                    end
                end
            end
        end
        return bestTarget
    end

    runService.RenderStepped:Connect(function()
        if not triggerbotEnabled then return end
        local target = getCrosshairTarget()
        if target then
            local currentTime = tick()
            if triggerbotMode == "Instant" then
                camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position + Vector3.new(0, target.Size.Y/4, 0))
                mouse1click()
            elseif triggerbotMode == "Delay" then
                if currentTime - triggerbotLastShoot >= triggerbotDelay then
                    camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position + Vector3.new(0, target.Size.Y/4, 0))
                    mouse1click()
                    triggerbotLastShoot = currentTime
                end
            end
        end
    end)

    runService.RenderStepped:Connect(function()
        if silentAimEnabled then silentAimTarget = getTarget(silentAimHitbox) end
        if autoShootEnabled then
            if autoShootMode == "FOV" then
                autoShootTarget = getTarget("Head")
            elseif autoShootMode == "Closest" then
                local closest = nil
                local closestDist = math.huge
                local myPos = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") and lplr.Character.HumanoidRootPart.Position
                if myPos then
                    for _, target in pairs(targets) do
                        if target and target.Character and target.Character:FindFirstChild("Head") then
                            if not (teamCheck and target.Team == player.Team) then
                                local dist = (target.Character.Head.Position - myPos).Magnitude
                                if dist <= maxAimDistance then
                                    if (not wallCheckEnabled) or isVisible(target.Character.Head) then
                                        if dist < closestDist then
                                            closestDist = dist
                                            closest = target.Character.Head
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                autoShootTarget = closest
            elseif autoShootMode == "Random" then
                local valid = {}
                for _, target in pairs(targets) do
                    if target and target.Character and target.Character:FindFirstChild("Head") then
                        if not (teamCheck and target.Team == player.Team) then
                            local myPos = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                            if myPos then
                                local dist = (target.Character.Head.Position - myPos.Position).Magnitude
                                if dist <= maxAimDistance then
                                    if (not wallCheckEnabled) or isVisible(target.Character.Head) then
                                        table.insert(valid, target.Character.Head)
                                    end
                                end
                            end
                        end
                    end
                end
                if #valid > 0 then autoShootTarget = valid[math.random(1, #valid)] end
            end
        end
    end)

    local function autoShoot()
        if not autoShootEnabled or not autoShootTarget then return end
        local currentTime = tick()
        if currentTime - lastShootTime >= autoShootDelay then
            camera.CFrame = CFrame.new(camera.CFrame.Position, autoShootTarget.Position + Vector3.new(0, autoShootTarget.Size.Y/4, 0))
            wait(0.01)
            mouse1click()
            lastShootTime = currentTime
        end
    end
    runService.RenderStepped:Connect(autoShoot)

    lplr.CharacterAdded:Connect(function()
        wait(1)
        if speedEnabled and lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            lplr.Character.Humanoid.WalkSpeed = speedValue
        end
        if jumpEnabled and lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            lplr.Character.Humanoid.JumpPower = jumpValue
        end
    end)

    -- SEKMELER
    local MainTab = Window:NewTab("Aimlock")
    local MainSection = MainTab:NewSection("Aimlock")
    MainSection:NewToggle("Normal Aimlock", "", function(state) aimEnabled = state if state and holdAimEnabled then holdAimEnabled = false end end)
    MainSection:NewToggle("Basılı Tut Aimlock", "", function(state) holdAimEnabled = state if state and aimEnabled then aimEnabled = false end end)
    MainSection:NewToggle("Silent Aim", "", function(state) silentAimEnabled = state end)
    MainSection:NewDropdown("Aim Part", "", {"Head", "HumanoidRootPart", "Torso"}, function(value) aimPart = value end)
    MainSection:NewSlider("FOV", "", 500, 30, function(value) fovSize = value end)
    MainSection:NewToggle("FOV Görünür", "", function(state) fovVisible = state end)
    MainSection:NewToggle("Team Check", "", function(state) teamCheck = state end)

    local AimSettingsTab = Window:NewTab("Aim Ayarları")
    local AimSettingsSection = AimSettingsTab:NewSection("Aim Ayarları")
    AimSettingsSection:NewSlider("Max Mesafe", "", 1000, 100, function(value) maxAimDistance = value end)
    AimSettingsSection:NewToggle("Duvar Kontrolü", "", function(state) wallCheckEnabled = state end)

    local ColorTab = Window:NewTab("Renk Ayarları")
    local ColorSection = ColorTab:NewSection("GUI Renkleri")
    ColorSection:NewColorPicker("Arkaplan", "", guiColors.Background, function(color) guiColors.Background = color updateColors() end)
    ColorSection:NewColorPicker("Yazı Rengi", "", guiColors.Text, function(color) guiColors.Text = color updateColors() end)
    ColorSection:NewColorPicker("Buton Rengi", "", guiColors.Button, function(color) guiColors.Button = color updateColors() end)
    ColorSection:NewColorPicker("Vurgu Rengi", "", guiColors.Accent, function(color)
        guiColors.Accent = color
        fovCircle.Color = color
        for _, box in pairs(espBoxes) do if box then box.Color = color end end
        for _, tracer in pairs(espTracers) do if tracer then tracer.Color = color end end
    end)
    ColorSection:NewButton("Varsayılan", "", function()
        guiColors.Background = Color3.fromRGB(20, 20, 20)
        guiColors.Text = Color3.fromRGB(255, 255, 255)
        guiColors.Button = Color3.fromRGB(40, 40, 40)
        guiColors.Accent = Color3.fromRGB(255, 0, 0)
        updateColors()
        fovCircle.Color = guiColors.Accent
        for _, box in pairs(espBoxes) do if box then box.Color = guiColors.Accent end end
        for _, tracer in pairs(espTracers) do if tracer then tracer.Color = guiColors.Accent end end
    end)

    local TriggerTab = Window:NewTab("Trigger")
    local TriggerSection = TriggerTab:NewSection("Trigger")
    TriggerSection:NewToggle("Triggerbot", "", function(state) triggerbotEnabled = state end)
    TriggerSection:NewDropdown("Mod", "", {"Instant", "Delay"}, function(value) triggerbotMode = value end)
    TriggerSection:NewSlider("Gecikme", "", 0.5, 0.01, function(value) triggerbotDelay = value end)

    local AutoTab = Window:NewTab("Auto")
    local AutoSection = AutoTab:NewSection("Auto")
    AutoSection:NewToggle("Otomatik Vurma", "", function(state) autoShootEnabled = state end)
    AutoSection:NewDropdown("Mod", "", {"FOV", "Closest", "Random"}, function(value) autoShootMode = value end)
    AutoSection:NewSlider("Hız", "", 1, 0.05, function(value) autoShootDelay = value end)

    local ESPTab = Window:NewTab("ESP")
    local ESPSection = ESPTab:NewSection("ESP")
    ESPSection:NewToggle("ESP Aç", "", function(state) 
        espEnabled = state 
        if state then refreshESP() lastESPRefresh = tick() end
    end)
    ESPSection:NewToggle("Otomatik Yenile (5sn)", "", function(state) espAutoRefresh = state end)
    ESPSection:NewButton("Şimdi Yenile", "", refreshESP)

    local MoveTab = Window:NewTab("Movement")
    local MoveSection = MoveTab:NewSection("Movement")
    MoveSection:NewToggle("Speed", "", function(state)
        speedEnabled = state
        if state and lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            lplr.Character.Humanoid.WalkSpeed = speedValue
        elseif lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            lplr.Character.Humanoid.WalkSpeed = 16
        end
    end)
    MoveSection:NewSlider("Speed", "", 200, 16, function(value)
        speedValue = value
        if speedEnabled and lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            lplr.Character.Humanoid.WalkSpeed = value
        end
    end)
    MoveSection:NewToggle("Jump", "", function(state)
        jumpEnabled = state
        if state and lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            lplr.Character.Humanoid.JumpPower = jumpValue
        elseif lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            lplr.Character.Humanoid.JumpPower = 50
        end
    end)
    MoveSection:NewSlider("Jump", "", 200, 50, function(value)
        jumpValue = value
        if jumpEnabled and lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
            lplr.Character.Humanoid.JumpPower = value
        end
    end)
    
    wait(1)
    updateColors()
end

createGUI()

local uis = game:GetService("UserInputService")
uis.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.K then
        menuVisible = not menuVisible
        if menuVisible then
            createGUI()
        else
            if Library then
                for _, v in pairs(Library:GetChildren()) do
                    v:Destroy()
                end
                Library = nil
                Window = nil
            end
        end
    end
end)
