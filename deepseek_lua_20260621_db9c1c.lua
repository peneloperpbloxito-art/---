-- ============================================================
-- 🔥 DUELOS HACK v1.0 BETA 🔥
-- Desarrollado por: Vaxxzu
-- ESP con SelectionBox (estable), UI Negra, Icono flotante.
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ===================== CONFIGURACIÓN =====================
local CONFIG = {
    Wallhack = true,
    Aimbot = true,
    Wallbang = true,
    Invisible = true,
    AutoWinActive = false,
    AimbotAccuracy = 0.8,
}

-- ===================== VARIABLES GLOBALES =====================
local EspBoxes = {}          -- {Player -> {Part -> SelectionBox}}
local PlayerKills = {}
local IsSpectator = false
local CurrentRound = 0
local UI_OPEN = true
local MainFrame = nil

-- ===================== INVISIBILIDAD FANTASMA =====================
local function ApplyGhostInvisibility(state)
    local character = LocalPlayer.Character
    if not character then return end

    local transparency = state and 1 or 0
    local localModifier = state and 0.5 or 0

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = transparency
        end
        if part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = transparency
        end
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.HealthDisplayDistance = state and 0 or 100
        humanoid.NameDisplayDistance = state and 0 or 100
        humanoid:SetAttribute("LocalTransparencyModifier", localModifier)
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Tool") then
            if child:FindFirstChild("Handle") then
                child.Handle.Transparency = transparency
            end
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
    -- Limpiar boxes de jugadores que ya no existen o están muertos
    for player, parts in pairs(EspBoxes) do
        if not player or not player.Parent or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
            for part, box in pairs(parts) do
                pcall(function() box:Destroy() end)
            end
            EspBoxes[player] = nil
        end
    end

    if not CONFIG.Wallhack then
        ClearEsp()
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        -- Obtener partes del cuerpo
        local parts = {
            character:FindFirstChild("Head"),
            character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
            character:FindFirstChild("LowerTorso"),
            character:FindFirstChild("LeftArm"),
            character:FindFirstChild("RightArm"),
            character:FindFirstChild("LeftLeg"),
            character:FindFirstChild("RightLeg"),
        }

        -- Inicializar tabla para este jugador si no existe
        if not EspBoxes[player] then EspBoxes[player] = {} end

        for _, part in ipairs(parts) do
            if not part then continue end
            -- Si ya existe un box para esta parte, actualizar su color/visibilidad
            if EspBoxes[player][part] then
                local box = EspBoxes[player][part]
                box.Visible = true
                box.Color3 = part.Name == "Head" and Color3.fromRGB(255, 50, 50) or
                             (part.Name:find("Torso") and Color3.fromRGB(0, 200, 255)) or
                             (part.Name:find("Arm") and Color3.fromRGB(255, 200, 50)) or
                             Color3.fromRGB(50, 255, 100)
                box.Transparency = 0.5
            else
                -- Crear nuevo SelectionBox
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

        -- Añadir nombre y vida (opcional: con BillboardGui)
        -- Lo haremos simple con un TextLabel en el workspace (más estable)
        local nameTag = character:FindFirstChild("NameTag")
        if not nameTag and CONFIG.Wallhack then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "NameTag"
            billboard.Size = UDim2.new(0, 100, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = character

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = player.Name
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.TextStrokeTransparency = 0.2
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16
            label.Parent = billboard
        elseif nameTag then
            nameTag.Enabled = CONFIG.Wallhack
        end
    end
end

-- ===================== AIMBOT CON WALLBANG =====================
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

    if Mouse and Mouse.Move then
        Mouse.Move(targetX, targetY)
    elseif syn and syn.mouse and syn.mouse.Move then
        syn.mouse.Move(targetX, targetY)
    elseif mousemoveabs then
        mousemoveabs(targetX, targetY)
    else
        UserInputService:MoveMouse(targetX, targetY)
    end

    if CONFIG.Wallbang then
        FireWeapon()
    end
end

-- ===================== AUTO WIN =====================
local function AutoWin()
    if CONFIG.AutoWinActive then return end
    CONFIG.AutoWinActive = true
    print("⚡ AUTO WIN: Eliminando enemigos...")

    -- Intentar RemoteEvent
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            pcall(function()
                if obj:IsA("RemoteEvent") then obj:FireServer("Win", "RoundWin")
                elseif obj:IsA("RemoteFunction") then obj:InvokeServer("Win", "RoundWin") end
            end)
        end
    end

    -- Matar manualmente
    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            table.insert(enemies, player)
        end
    end

    if #enemies == 0 then
        print("✅ AutoWin: No hay enemigos vivos. ¡Victoria!")
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
    if remaining > 0 then
        CONFIG.AutoWinActive = false
        AutoWin()
    else
        print("✅ AutoWin completado. ¡Victoria!")
        CONFIG.AutoWinActive = false
    end
end

-- ===================== UI NEGRA CON ICONO FLOTANTE =====================
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DuelosHackUI"
    screenGui.Parent = LocalPlayer.PlayerGui

    -- Icono flotante (siempre visible, abre/cierra el menú)
    local toggleBtn = Instance.new("ImageButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 50)
    toggleBtn.Position = UDim2.new(0, 10, 0.5, -25)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    toggleBtn.BackgroundTransparency = 0.2
    toggleBtn.BorderSizePixel = 2
    toggleBtn.BorderColor3 = Color3.fromRGB(200, 200, 200)
    toggleBtn.Image = "rbxassetid://1297195572" -- Icono de ajustes (engranaje)
    toggleBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Parent = screenGui

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn

    -- Menú principal (negro con bordes blancos)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = true
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    -- Barra de título negra
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.8, 0, 1, 0)
    titleText.Position = UDim2.new(0.05, 0, 0, 0)
    titleText.Text = "⚡ DUELOS HACK v3.0"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.BackgroundTransparency = 1
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Botón cerrar (X) dentro del menú
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextSize = 16
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
        UI_OPEN = mainFrame.Visible
    end)

    -- Alternar menú con el icono flotante
    toggleBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
        UI_OPEN = mainFrame.Visible
    end)

    -- ScrollView para opciones
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -60)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 450)
    scroll.Parent = mainFrame

    -- Función para crear botones en el menú negro
    local function createBlackButton(text, desc, callback, yPos, active)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 50)
        frame.Position = UDim2.new(0, 5, 0, yPos)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
        frame.Parent = scroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.Position = UDim2.new(0, 0, 0, 0)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = frame

        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.8, 0, 0, 16)
        descLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
        descLabel.Text = desc
        descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 11
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = frame

        -- Indicador de estado (círculo)
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 12, 0, 12)
        indicator.Position = UDim2.new(1, -20, 0.5, -6)
        indicator.BackgroundColor3 = active and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(60, 60, 60)
        indicator.BorderSizePixel = 0
        indicator.Parent = frame
        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(1, 0)
        indCorner.Parent = indicator

        btn.MouseButton1Click:Connect(function()
            callback()
            indicator.BackgroundColor3 = indicator.BackgroundColor3 == Color3.fromRGB(0, 200, 80) and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(0, 200, 80)
        end)

        return {Btn = btn, Indicator = indicator}
    end

    -- Secciones visuales
    local header1 = Instance.new("TextLabel")
    header1.Size = UDim2.new(1, 0, 0, 20)
    header1.Position = UDim2.new(0, 0, 0, 0)
    header1.Text = "── VISUAL ──"
    header1.TextColor3 = Color3.fromRGB(150, 150, 150)
    header1.BackgroundTransparency = 1
    header1.Font = Enum.Font.Gotham
    header1.TextSize = 12
    header1.TextXAlignment = Enum.TextXAlignment.Center
    header1.Parent = scroll

    local wh = createBlackButton("🔲 Hitbox ESP", "Muestra hitboxes en 3D", function()
        CONFIG.Wallhack = not CONFIG.Wallhack
        if not CONFIG.Wallhack then ClearEsp() end
    end, 25, CONFIG.Wallhack)

    local header2 = Instance.new("TextLabel")
    header2.Size = UDim2.new(1, 0, 0, 20)
    header2.Position = UDim2.new(0, 0, 0, 80)
    header2.Text = "── COMBATE ──"
    header2.TextColor3 = Color3.fromRGB(150, 150, 150)
    header2.BackgroundTransparency = 1
    header2.Font = Enum.Font.Gotham
    header2.TextSize = 12
    header2.TextXAlignment = Enum.TextXAlignment.Center
    header2.Parent = scroll

    local aim = createBlackButton("🎯 Aimbot 80%", "Apunta automáticamente", function()
        CONFIG.Aimbot = not CONFIG.Aimbot
    end, 105, CONFIG.Aimbot)

    local wb = createBlackButton("🧱 Wallbang", "Dispara a través de paredes", function()
        CONFIG.Wallbang = not CONFIG.Wallbang
    end, 160, CONFIG.Wallbang)

    local header3 = Instance.new("TextLabel")
    header3.Size = UDim2.new(1, 0, 0, 20)
    header3.Position = UDim2.new(0, 0, 0, 215)
    header3.Text = "── ESPECIALES ──"
    header3.TextColor3 = Color3.fromRGB(150, 150, 150)
    header3.BackgroundTransparency = 1
    header3.Font = Enum.Font.Gotham
    header3.TextSize = 12
    header3.TextXAlignment = Enum.TextXAlignment.Center
    header3.Parent = scroll

    local inv = createBlackButton("👻 Fantasma", "Invisible para otros, semi para ti", function()
        CONFIG.Invisible = not CONFIG.Invisible
        ApplyGhostInvisibility(CONFIG.Invisible)
    end, 240, CONFIG.Invisible)

    -- AutoWin (botón dorado especial)
    local autoFrame = Instance.new("Frame")
    autoFrame.Size = UDim2.new(1, -10, 0, 50)
    autoFrame.Position = UDim2.new(0, 5, 0, 300)
    autoFrame.BackgroundColor3 = Color3.fromRGB(50, 40, 0)
    autoFrame.BackgroundTransparency = 0.3
    autoFrame.BorderSizePixel = 1
    autoFrame.BorderColor3 = Color3.fromRGB(200, 180, 0)
    autoFrame.Parent = scroll

    local autoCorner = Instance.new("UICorner")
    autoCorner.CornerRadius = UDim.new(0, 8)
    autoCorner.Parent = autoFrame

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(1, 0, 1, 0)
    autoBtn.Position = UDim2.new(0, 0, 0, 0)
    autoBtn.Text = "⚡ AUTO WIN (¡Gana al instante!)"
    autoBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    autoBtn.BackgroundTransparency = 1
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 16
    autoBtn.Parent = autoFrame
    autoBtn.MouseButton1Click:Connect(function()
        spawn(AutoWin)
    end)

    -- Footer
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 20)
    footer.Position = UDim2.new(0, 0, 1, -25)
    footer.Text = "By Vaxxzu | Beta v3.0 | Prohibida su venta"
    footer.TextColor3 = Color3.fromRGB(80, 80, 80)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 10
    footer.Parent = mainFrame

    -- Stats
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(0.8, 0, 0, 16)
    stats.Position = UDim2.new(0.1, 0, 1, -45)
    stats.Text = "Ronda: 0/5 | Bajas: 0"
    stats.TextColor3 = Color3.fromRGB(150, 150, 150)
    stats.BackgroundTransparency = 1
    stats.Font = Enum.Font.Gotham
    stats.TextSize = 11
    stats.TextXAlignment = Enum.TextXAlignment.Center
    stats.Parent = mainFrame

    spawn(function()
        while true do
            task.wait(0.5)
            local kills = PlayerKills[LocalPlayer.Name] or 0
            stats.Text = "Ronda: " .. (CurrentRound or 0) .. "/5 | Bajas: " .. kills
        end
    end)

    MainFrame = mainFrame
    return mainFrame
end

-- ===================== EVENTOS =====================
LocalPlayer.CharacterAdded:Connect(function(character)
    IsSpectator = false
    if CONFIG.Invisible then
        task.wait(0.2)
        ApplyGhostInvisibility(true)
    end
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        IsSpectator = true
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
ApplyGhostInvisibility(CONFIG.Invisible)

RunService.RenderStepped:Connect(function()
    UpdateEsp()
    if CONFIG.Aimbot then
        local target = GetClosestEnemy()
        if target then MoveMouseTo(target) end
    end
end)

LocalPlayer.OnTeleport:Connect(ClearEsp)

print("🔥 DUELOS HACK v3.0 BETA CARGADO")
print("👤 By Vaxxzu")
print("🔲 ESP con SelectionBox (estable)")
print("👻 Fantasma activado")
print("⚡ AutoWin listo")
