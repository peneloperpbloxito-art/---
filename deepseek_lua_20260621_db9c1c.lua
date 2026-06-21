-- ============================================================
-- 🔥 DUELOS HACK v4.0 BETA 🔥
-- Desarrollado por: Vaxxzu
-- GUI Horizontal con animación, ESP por SelectionBox,
-- Fantasma (Highlight local), todo desactivado por defecto.
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ===================== CONFIGURACIÓN (TODO APAGADO) =====================
local CONFIG = {
    Wallhack = false,     -- APAGADO por defecto
    Aimbot = false,       -- APAGADO por defecto
    Wallbang = false,     -- APAGADO por defecto
    Invisible = false,    -- APAGADO por defecto
    AutoWinActive = false,
    AimbotAccuracy = 0.8,
}

-- ===================== VARIABLES GLOBALES =====================
local EspBoxes = {}
local PlayerKills = {}
local CurrentRound = 0
local UI_OPEN = true
local GhostHighlight = nil  -- Para el efecto fantasma local
local MainFrame = nil
local ToggleButton = nil

-- ===================== FUNCIÓN: FANTASMA (INVISIBLE PARA OTROS, SEMI PARA TI) =====================
local function ApplyGhostInvisibility(state)
    local character = LocalPlayer.Character
    if not character then return end

    -- 1. Hacer todas las partes transparentes para TODOS (así los demás no te ven)
    local transparency = state and 1 or 0
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = transparency
        end
        if part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = transparency
        end
    end

    -- 2. Ocultar nombre y vida para los demás
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.HealthDisplayDistance = state and 0 or 100
        humanoid.NameDisplayDistance = state and 0 or 100
    end

    -- 3. Crear/Eliminar Highlight LOCAL (solo tú lo ves)
    if state then
        if not GhostHighlight then
            GhostHighlight = Instance.new("Highlight")
            GhostHighlight.Adornee = character
            GhostHighlight.FillColor = Color3.fromRGB(0, 200, 255)  -- Azul neón
            GhostHighlight.FillTransparency = 0.6  -- Semi-transparente
            GhostHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            GhostHighlight.OutlineTransparency = 0.2
            GhostHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            GhostHighlight.Parent = character
        end
    else
        if GhostHighlight then
            GhostHighlight:Destroy()
            GhostHighlight = nil
        end
        -- Restaurar transparencia a 0
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
            if part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 0
            end
        end
        if humanoid then
            humanoid.HealthDisplayDistance = 100
            humanoid.NameDisplayDistance = 100
        end
    end
end

-- ===================== ESP CON SELECTIONBOX =====================
local function ClearEsp()
    for player, parts in pairs(EspBoxes) do
        for part, box in pairs(parts) do
            pcall(function() box:Destroy() end)
        end
    end
    EspBoxes = {}
end

local function UpdateEsp()
    if not CONFIG.Wallhack then
        ClearEsp()
        return
    end

    -- Limpiar muertos
    for player, parts in pairs(EspBoxes) do
        if not player or not player.Parent or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
            for part, box in pairs(parts) do
                pcall(function() box:Destroy() end)
            end
            EspBoxes[player] = nil
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        if not EspBoxes[player] then EspBoxes[player] = {} end

        -- Partes a marcar
        local parts = {
            character:FindFirstChild("Head"),
            character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
            character:FindFirstChild("LowerTorso"),
            character:FindFirstChild("LeftArm"),
            character:FindFirstChild("RightArm"),
            character:FindFirstChild("LeftLeg"),
            character:FindFirstChild("RightLeg"),
        }

        for _, part in ipairs(parts) do
            if not part then continue end
            if EspBoxes[player][part] then
                local box = EspBoxes[player][part]
                box.Visible = true
                box.Color3 = part.Name == "Head" and Color3.fromRGB(255, 50, 50) or
                             (part.Name:find("Torso") and Color3.fromRGB(0, 200, 255)) or
                             (part.Name:find("Arm") and Color3.fromRGB(255, 200, 50)) or
                             Color3.fromRGB(50, 255, 100)
            else
                local box = Instance.new("SelectionBox")
                box.Adornee = part
                box.Color3 = part.Name == "Head" and Color3.fromRGB(255, 50, 50) or
                             (part.Name:find("Torso") and Color3.fromRGB(0, 200, 255)) or
                             (part.Name:find("Arm") and Color3.fromRGB(255, 200, 50)) or
                             Color3.fromRGB(50, 255, 100)
                box.Transparency = 0.5
                box.LineThickness = 0.1
                box.Visible = true
                box.Parent = part
                EspBoxes[player][part] = box
            end
        end

        -- Nombre y vida (Billboard)
        local nameTag = character:FindFirstChild("NameTagHack")
        if not nameTag and CONFIG.Wallhack then
            local bill = Instance.new("BillboardGui")
            bill.Name = "NameTagHack"
            bill.Size = UDim2.new(0, 120, 0, 40)
            bill.StudsOffset = Vector3.new(0, 3, 0)
            bill.AlwaysOnTop = true
            bill.Parent = character

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = player.Name
            nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            nameLbl.TextStrokeTransparency = 0.3
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 16
            nameLbl.Parent = bill

            local healthLbl = Instance.new("TextLabel")
            healthLbl.Size = UDim2.new(1, 0, 0.5, 0)
            healthLbl.Position = UDim2.new(0, 0, 0.5, 0)
            healthLbl.BackgroundTransparency = 1
            healthLbl.Text = "❤️ " .. math.floor(humanoid.Health)
            healthLbl.TextColor3 = Color3.fromRGB(0, 255, 100)
            healthLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            healthLbl.TextStrokeTransparency = 0.3
            healthLbl.Font = Enum.Font.Gotham
            healthLbl.TextSize = 14
            healthLbl.Parent = bill
        elseif nameTag then
            nameTag.Enabled = CONFIG.Wallhack
            local healthLbl = nameTag:FindFirstChildWhichIsA("TextLabel")
            if healthLbl and healthLbl.Parent == nameTag then
                -- Actualizar vida
                local hpLbl = nameTag:FindFirstChildWhichIsA("TextLabel")
                if hpLbl and hpLbl.Parent == nameTag and hpLbl.Name ~= "Name" then
                    hpLbl.Text = "❤️ " .. math.floor(humanoid.Health)
                end
            end
        end
    end
end

-- ===================== AIMBOT + WALLBANG =====================
local function GetClosestEnemy()
    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            table.insert(enemies, player)
        end
    end
    if #enemies == 0 then return nil end

    local centerX, centerY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    local closest, closestDist = nil, math.huge

    for _, enemy in ipairs(enemies) do
        local head = enemy.Character:FindFirstChild("Head")
        if head then
            local pos, _ = Camera:WorldToScreenPoint(head.Position)
            local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(centerX, centerY)).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = enemy
            end
        end
    end
    return closest
end

local function FireWeapon()
    if Mouse then
        if Mouse.Button1Down and Mouse.Button1Up then
            Mouse.Button1Down()
            task.wait(0.05)
            Mouse.Button1Up()
        end
    end
    UserInputService:SetMouseButtonEnabled(Enum.UserInputType.MouseButton1, true)
    task.wait(0.02)
    UserInputService:SetMouseButtonEnabled(Enum.UserInputType.MouseButton1, false)
end

local function MoveMouseTo(target)
    if not target then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    local pos, _ = Camera:WorldToScreenPoint(head.Position)

    local accuracy = CONFIG.AimbotAccuracy
    local noiseX = (math.random() - 0.5) * 30 * (1 - accuracy) * 2
    local noiseY = (math.random() - 0.5) * 30 * (1 - accuracy) * 2

    local targetX = pos.X + noiseX
    local targetY = pos.Y + noiseY

    if Mouse and Mouse.Move then Mouse.Move(targetX, targetY)
    elseif syn and syn.mouse and syn.mouse.Move then syn.mouse.Move(targetX, targetY)
    elseif mousemoveabs then mousemoveabs(targetX, targetY)
    else UserInputService:MoveMouse(targetX, targetY) end

    if CONFIG.Wallbang then FireWeapon() end
end

-- ===================== AUTO WIN =====================
local function AutoWin()
    if CONFIG.AutoWinActive then return end
    CONFIG.AutoWinActive = true
    print("⚡ AUTO WIN: Eliminando enemigos...")

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            pcall(function()
                if obj:IsA("RemoteEvent") then obj:FireServer("Win", "RoundWin")
                elseif obj:IsA("RemoteFunction") then obj:InvokeServer("Win", "RoundWin") end
            end)
        end
    end

    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            table.insert(enemies, player)
        end
    end

    if #enemies == 0 then
        print("✅ AutoWin: No hay enemigos. ¡Victoria!")
        CONFIG.AutoWinActive = false
        return
    end

    for _, enemy in ipairs(enemies) do
        local head = enemy.Character:FindFirstChild("Head")
        if head then
            local pos, _ = Camera:WorldToScreenPoint(head.Position)
            if Mouse and Mouse.Move then Mouse.Move(pos.X, pos.Y)
            elseif syn and syn.mouse and syn.mouse.Move then syn.mouse.Move(pos.X, pos.Y)
            elseif mousemoveabs then mousemoveabs(pos.X, pos.Y) end
            task.wait(0.05)
            for i = 1, 5 do FireWeapon(); task.wait(0.03) end
            task.wait(0.1)
        end
    end

    task.wait(0.5)
    local remaining = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            remaining = remaining + 1
        end
    end
    if remaining > 0 then CONFIG.AutoWinActive = false; AutoWin()
    else print("✅ AutoWin completado."); CONFIG.AutoWinActive = false end
end

-- ===================== UI HORIZONTAL CON ANIMACIÓN =====================
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DuelosHackUI"
    screenGui.Parent = LocalPlayer.PlayerGui

    -- ===== BOTÓN FLOTANTE (ENGANCHE) =====
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 50)
    toggleBtn.Position = UDim2.new(0, 15, 0.5, -25)
    toggleBtn.Text = "⚙️"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 28
    toggleBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    toggleBtn.BackgroundTransparency = 0.2
    toggleBtn.BorderSizePixel = 2
    toggleBtn.BorderColor3 = Color3.fromRGB(200, 200, 200)
    toggleBtn.Parent = screenGui
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn

    -- ===== PANEL PRINCIPAL (HORIZONTAL) =====
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 480, 0, 90)
    mainFrame.Position = UDim2.new(0.5, -240, 0.5, -45) -- Centrado
    mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = true
    mainFrame.Parent = screenGui
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    -- Título en la barra superior (izquierda)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 180, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Text = "⚡ DUELOS v4.0"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = mainFrame

    -- Botón para cerrar (dentro del panel)
    local closePanelBtn = Instance.new("TextButton")
    closePanelBtn.Size = UDim2.new(0, 30, 0, 30)
    closePanelBtn.Position = UDim2.new(1, -40, 0, 8)
    closePanelBtn.Text = "✕"
    closePanelBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closePanelBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    closePanelBtn.BackgroundTransparency = 0.5
    closePanelBtn.BorderSizePixel = 0
    closePanelBtn.Font = Enum.Font.Gotham
    closePanelBtn.TextSize = 16
    closePanelBtn.Parent = mainFrame
    closePanelBtn.MouseButton1Click:Connect(function()
        togglePanel(false)
    end)

    -- Contenedor de botones (horizontal)
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -10, 1, -35)
    btnContainer.Position = UDim2.new(0, 5, 0, 35)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = mainFrame

    -- Función para crear botones pequeños horizontales
    local function createHoriBtn(text, desc, callback, xPos, active)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 85, 1, -5)
        frame.Position = UDim2.new(0, xPos, 0, 2)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
        frame.Parent = btnContainer
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0.6, 0)
        btn.Position = UDim2.new(0, 0, 0, 0)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = frame

        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, 0, 0.4, 0)
        descLabel.Position = UDim2.new(0, 0, 0.6, 0)
        descLabel.Text = desc
        descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 9
        descLabel.Parent = frame

        -- Indicador (círculo)
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 8, 0, 8)
        indicator.Position = UDim2.new(0.8, 0, 0.1, 0)
        indicator.BackgroundColor3 = active and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(60, 60, 60)
        indicator.BorderSizePixel = 0
        indicator.Parent = frame
        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(1, 0)
        indCorner.Parent = indicator

        btn.MouseButton1Click:Connect(function()
            callback()
            if indicator.BackgroundColor3 == Color3.fromRGB(0, 200, 80) then
                indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            else
                indicator.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
            end
        end)

        return {Btn = btn, Indicator = indicator}
    end

    -- Crear botones (TODOS DESACTIVADOS POR DEFECTO -> active = false)
    local b1 = createHoriBtn("🔲 ESP", "Hitbox", function()
        CONFIG.Wallhack = not CONFIG.Wallhack
        if not CONFIG.Wallhack then ClearEsp() end
    end, 5, false)

    local b2 = createHoriBtn("🎯 Aim", "80%", function()
        CONFIG.Aimbot = not CONFIG.Aimbot
    end, 95, false)

    local b3 = createHoriBtn("🧱 Wall", "AutoFire", function()
        CONFIG.Wallbang = not CONFIG.Wallbang
    end, 185, false)

    local b4 = createHoriBtn("👻 Ghost", "Fantasma", function()
        CONFIG.Invisible = not CONFIG.Invisible
        ApplyGhostInvisibility(CONFIG.Invisible)
    end, 275, false)

    -- Botón AutoWin (especial, dorado)
    local autoFrame = Instance.new("Frame")
    autoFrame.Size = UDim2.new(0, 95, 1, -5)
    autoFrame.Position = UDim2.new(0, 370, 0, 2)
    autoFrame.BackgroundColor3 = Color3.fromRGB(50, 40, 0)
    autoFrame.BackgroundTransparency = 0.3
    autoFrame.BorderSizePixel = 1
    autoFrame.BorderColor3 = Color3.fromRGB(200, 180, 0)
    autoFrame.Parent = btnContainer
    local autoCorner = Instance.new("UICorner")
    autoCorner.CornerRadius = UDim.new(0, 6)
    autoCorner.Parent = autoFrame

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(1, 0, 0.6, 0)
    autoBtn.Position = UDim2.new(0, 0, 0, 0)
    autoBtn.Text = "⚡ WIN"
    autoBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    autoBtn.BackgroundTransparency = 1
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 14
    autoBtn.Parent = autoFrame

    local autoDesc = Instance.new("TextLabel")
    autoDesc.Size = UDim2.new(1, 0, 0.4, 0)
    autoDesc.Position = UDim2.new(0, 0, 0.6, 0)
    autoDesc.Text = "¡Gana ya!"
    autoDesc.TextColor3 = Color3.fromRGB(200, 180, 100)
    autoDesc.BackgroundTransparency = 1
    autoDesc.Font = Enum.Font.Gotham
    autoDesc.TextSize = 10
    autoDesc.Parent = autoFrame

    autoBtn.MouseButton1Click:Connect(function()
        spawn(AutoWin)
    end)

    -- Animación de apertura/cierre
    local function togglePanel(open)
        UI_OPEN = open
        local targetPos = open and UDim2.new(0.5, -240, 0.5, -45) or UDim2.new(1.5, 0, 0.5, -45)
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(mainFrame, tweenInfo, {Position = targetPos})
        tween:Play()
        if open then mainFrame.Visible = true end
        tween.Completed:Connect(function()
            if not open then mainFrame.Visible = false end
        end)
    end

    -- Alternar con el botón flotante
    toggleBtn.MouseButton1Click:Connect(function()
        if mainFrame.Visible then
            togglePanel(false)
        else
            mainFrame.Visible = true
            togglePanel(true)
        end
    end)

    -- Stats en el panel (esquina inferior derecha)
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0, 150, 0, 16)
    statsLabel.Position = UDim2.new(1, -160, 1, -20)
    statsLabel.Text = "Ronda: 0/5 | Bajas: 0"
    statsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 11
    statsLabel.TextXAlignment = Enum.TextXAlignment.Right
    statsLabel.Parent = mainFrame

    spawn(function()
        while true do
            task.wait(0.5)
            local kills = PlayerKills[LocalPlayer.Name] or 0
            statsLabel.Text = "Ronda: " .. (CurrentRound or 0) .. "/5 | Bajas: " .. kills
        end
    end)

    MainFrame = mainFrame
    ToggleButton = toggleBtn
    return mainFrame
end

-- ===================== EVENTOS =====================
LocalPlayer.CharacterAdded:Connect(function(character)
    if CONFIG.Invisible then
        task.wait(0.2)
        ApplyGhostInvisibility(true)
    end
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 50, 0))
    end)
end)

spawn(function()
    while true do
        task.wait(10)
        CurrentRound = (CurrentRound or 0) + 1
        if CurrentRound > 5 then CurrentRound = 0; PlayerKills = {} end
    end
end)

-- ===================== INICIO =====================
CreateUI()
-- Aplicar estado inicial (todo desactivado, pero si Invisible está false, aseguramos que no haya highlight)
ApplyGhostInvisibility(false)

RunService.RenderStepped:Connect(function()
    UpdateEsp()
    if CONFIG.Aimbot then
        local target = GetClosestEnemy()
        if target then MoveMouseTo(target) end
    end
end)

LocalPlayer.OnTeleport:Connect(ClearEsp)

print("🔥 DUELOS HACK v4.0 BETA CARGADO")
print("👤 By Vaxxzu")
print("🔲 Todas las opciones están DESACTIVADAS por defecto.")
print("👻 Fantasma: invisible para otros, semi-transparente para ti.")
