-- ============================================================
-- 🔥 DUELOS HACK v1.0 BETA 🔥
-- Desarrollado por: Vaxxzu
-- Características: Hitbox ESP (Frames), Aimbot 80% con Wallbang,
-- Invisibilidad Fantasma, AutoWin mejorado, UI Premium Blanca/Negra.
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
    TeamMode = "2v2",
}

-- ===================== VARIABLES GLOBALES =====================
local EspFrames = {}          -- Almacena los frames de ESP
local PlayerKills = {}
local IsSpectator = false
local CurrentRound = 0
local UIClosed = false        -- Estado de la ventana

-- ===================== INVISIBILIDAD FANTASMA =====================
local function ApplyGhostInvisibility(state)
    local character = LocalPlayer.Character
    if not character then return end

    -- Para los demás: transparencia total (invisible)
    local transparencyForOthers = state and 1 or 0
    -- Para el jugador local: semi-transparente usando LocalTransparencyModifier
    local localModifier = state and 0.5 or 0  -- 0.5 = semi-transparente

    -- Aplicar transparencia a todas las partes (visible para todos)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = transparencyForOthers
        end
        if part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = transparencyForOthers
        end
    end

    -- Aplicar modificador local (solo para el jugador local)
    if character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        -- Usamos un atributo o una variable para almacenar el modificador
        -- En Roblox, no hay propiedad directa, pero podemos usar un valor en el Humanoid
        humanoid:SetAttribute("LocalTransparencyModifier", localModifier)
    end

    -- Ocultar nombre y barra de vida para los demás
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.HealthDisplayDistance = state and 0 or 100
        humanoid.NameDisplayDistance = state and 0 or 100
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, not state)
    end

    -- Ocultar accesorios y herramientas
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Tool") then
            if child:FindFirstChild("Handle") then
                child.Handle.Transparency = transparencyForOthers
            end
        end
    end
end

-- ===================== OBTENER HITBOX (PARTES) =====================
local function GetCharacterParts(character)
    local parts = {}
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return parts end

    local head = character:FindFirstChild("Head")
    local upperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local lowerTorso = character:FindFirstChild("LowerTorso")
    local leftArm = character:FindFirstChild("LeftArm")
    local rightArm = character:FindFirstChild("RightArm")
    local leftLeg = character:FindFirstChild("LeftLeg")
    local rightLeg = character:FindFirstChild("RightLeg")

    if head then table.insert(parts, {Part = head, Color = Color3.fromRGB(255, 50, 50)}) end
    if upperTorso then table.insert(parts, {Part = upperTorso, Color = Color3.fromRGB(0, 200, 255)}) end
    if lowerTorso then table.insert(parts, {Part = lowerTorso, Color = Color3.fromRGB(0, 150, 200)}) end
    if leftArm then table.insert(parts, {Part = leftArm, Color = Color3.fromRGB(255, 200, 50)}) end
    if rightArm then table.insert(parts, {Part = rightArm, Color = Color3.fromRGB(255, 200, 50)}) end
    if leftLeg then table.insert(parts, {Part = leftLeg, Color = Color3.fromRGB(50, 255, 100)}) end
    if rightLeg then table.insert(parts, {Part = rightLeg, Color = Color3.fromRGB(50, 255, 100)}) end
    return parts
end

-- ===================== ESP CON FRAMES (ESTABLE) =====================
local function ClearEsp()
    for _, data in ipairs(EspFrames) do
        pcall(function()
            data.Frame:Destroy()
            if data.NameLabel then data.NameLabel:Destroy() end
            if data.HealthBar then data.HealthBar:Destroy() end
        end)
    end
    EspFrames = {}
end

local function UpdateEsp()
    ClearEsp()
    if not CONFIG.Wallhack then return end

    local gui = LocalPlayer.PlayerGui:FindFirstChild("DuelosHackUI")
    if not gui then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        -- Usamos la cabeza como referencia principal
        local head = character:FindFirstChild("Head")
        if not head then continue end

        local pos, onScreen = Camera:WorldToScreenPoint(head.Position)
        if not onScreen then continue end

        -- Calcular tamaño de la hitbox basado en la distancia
        local dist = (Camera.CFrame.Position - head.Position).Magnitude
        local size = math.clamp(150 / dist * 4, 30, 120)

        -- Crear Frame para la hitbox
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, size, 0, size * 1.3)
        frame.Position = UDim2.new(0, pos.X - size/2, 0, pos.Y - size/1.5)
        frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        frame.BackgroundTransparency = 0.8
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
        frame.Visible = true
        frame.Parent = gui

        -- Nombre debajo
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, size * 1.2, 0, 20)
        nameLabel.Position = UDim2.new(0, pos.X - size*0.6, 0, pos.Y + size*0.3)
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.Parent = gui

        -- Barra de vida simplificada
        local healthBar = Instance.new("Frame")
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        healthBar.Size = UDim2.new(0, size * 0.8 * healthPercent, 0, 4)
        healthBar.Position = UDim2.new(0, pos.X - size*0.4, 0, pos.Y + size*0.3 + 20)
        healthBar.BackgroundColor3 = healthPercent > 0.3 and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
        healthBar.BackgroundTransparency = 0.3
        healthBar.BorderSizePixel = 0
        healthBar.Parent = gui

        -- Guardar referencias
        table.insert(EspFrames, {
            Frame = frame,
            NameLabel = nameLabel,
            HealthBar = healthBar,
            Player = player
        })
    end
end

-- ===================== AIMBOT CON WALLBANG Y AUTOFIRE =====================
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

-- Función para disparar (simular clic)
local function FireWeapon()
    -- Simular presión y liberación del botón izquierdo
    if Mouse then
        if Mouse.Button1Down and Mouse.Button1Up then
            Mouse.Button1Down()
            task.wait(0.05)
            Mouse.Button1Up()
        end
    end
    -- Fallback con UserInputService
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

    -- Mover el mouse de forma absoluta
    if Mouse and Mouse.Move then
        Mouse.Move(targetX, targetY)
    elseif syn and syn.mouse and syn.mouse.Move then
        syn.mouse.Move(targetX, targetY)
    elseif mousemoveabs then
        mousemoveabs(targetX, targetY)
    else
        -- Último recurso: mover por UserInputService (no siempre funciona)
        UserInputService:MoveMouse(targetX, targetY)
    end

    -- Si Wallbang está activado, disparar automáticamente
    if CONFIG.Wallbang then
        FireWeapon()
    end
end

-- ===================== AUTO WIN MEJORADO =====================
local function AutoWin()
    if CONFIG.AutoWinActive then return end
    CONFIG.AutoWinActive = true
    print("⚡ AUTO WIN: Eliminando enemigos...")

    -- 1. Intentar forzar victoria por RemoteEvent (común en juegos)
    local remoteSuccess = false
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local success = pcall(function()
                if obj:IsA("RemoteEvent") then
                    obj:FireServer("Win", "RoundWin", "victory")
                elseif obj:IsA("RemoteFunction") then
                    obj:InvokeServer("Win", "RoundWin")
                end
            end)
            if success then remoteSuccess = true end
        end
    end

    -- 2. Si no funcionó, matar a todos manualmente con disparos
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

    -- Apuntar y disparar a cada enemigo múltiples veces
    for _, enemy in ipairs(enemies) do
        local head = enemy.Character:FindFirstChild("Head")
        if head then
            local pos, _ = Camera:WorldToScreenPoint(head.Position)
            -- Mover el mouse a la cabeza exacta (sin ruido)
            if Mouse and Mouse.Move then
                Mouse.Move(pos.X, pos.Y)
            elseif syn and syn.mouse and syn.mouse.Move then
                syn.mouse.Move(pos.X, pos.Y)
            elseif mousemoveabs then
                mousemoveabs(pos.X, pos.Y)
            end
            task.wait(0.05)
            -- Disparar rápidamente
            for i = 1, 5 do
                FireWeapon()
                task.wait(0.03)
            end
            task.wait(0.1)
        end
    end

    -- Verificar si quedan vivos y repetir si es necesario
    task.wait(0.5)
    local remaining = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            remaining = remaining + 1
        end
    end
    if remaining > 0 then
        print("⚠️ AutoWin: Quedan " .. remaining .. " enemigos. Repitiendo...")
        CONFIG.AutoWinActive = false
        AutoWin() -- Recursivo
    else
        print("✅ AutoWin completado. ¡Victoria asegurada!")
        CONFIG.AutoWinActive = false
    end
end

-- ===================== UI PREMIUM BLANCO Y NEGRO =====================
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DuelosHackUI"
    screenGui.Parent = LocalPlayer.PlayerGui

    -- Ventana principal (estilo vidrio, bordes redondeados)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    -- Sombra (efecto premium)
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(-0.03, 0, -0.03, 0)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045215" -- Sombra difusa
    shadow.ImageTransparency = 0.6
    shadow.Parent = mainFrame

    -- Borde redondeado (usamos un Frame con corner)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Barra de título (arrastre opcional)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.8, 0, 1, 0)
    titleText.Position = UDim2.new(0.05, 0, 0, 0)
    titleText.Text = "⚡ DUELOS HACK v2.0"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.BackgroundTransparency = 1
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Botón de cerrar (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextSize = 16
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
        UIClosed = not UIClosed
    end)

    -- Contenedor de categorías (ScrollView opcional)
    local categories = Instance.new("ScrollingFrame")
    categories.Size = UDim2.new(1, -20, 1, -60)
    categories.Position = UDim2.new(0, 10, 0, 50)
    categories.BackgroundTransparency = 1
    categories.BorderSizePixel = 0
    categories.ScrollBarThickness = 4
    categories.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
    categories.CanvasSize = UDim2.new(0, 0, 0, 450)
    categories.Parent = mainFrame

    -- Función para crear un botón estilizado
    local function createStyledButton(text, description, callback, yPos, color)
        local btnFrame = Instance.new("Frame")
        btnFrame.Size = UDim2.new(1, -10, 0, 50)
        btnFrame.Position = UDim2.new(0, 5, 0, yPos)
        btnFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        btnFrame.BackgroundTransparency = 0.3
        btnFrame.BorderSizePixel = 0
        btnFrame.Parent = categories

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btnFrame

        local btnText = Instance.new("TextButton")
        btnText.Size = UDim2.new(1, 0, 1, 0)
        btnText.Position = UDim2.new(0, 0, 0, 0)
        btnText.Text = text
        btnText.TextColor3 = Color3.fromRGB(30, 30, 30)
        btnText.BackgroundTransparency = 1
        btnText.Font = Enum.Font.GothamBold
        btnText.TextSize = 14
        btnText.TextXAlignment = Enum.TextXAlignment.Left
        btnText.Parent = btnFrame

        -- Indicador de estado (color)
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 10, 0, 10)
        indicator.Position = UDim2.new(1, -20, 0.5, -5)
        indicator.BackgroundColor3 = color or Color3.fromRGB(100, 100, 100)
        indicator.BorderSizePixel = 0
        indicator.Parent = btnFrame
        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(1, 0)
        indCorner.Parent = indicator

        -- Descripción pequeña
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0.8, 0, 0, 16)
        desc.Position = UDim2.new(0.05, 0, 0.6, 0)
        desc.Text = description
        desc.TextColor3 = Color3.fromRGB(120, 120, 120)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = btnFrame

        btnText.MouseButton1Click:Connect(function()
            callback()
            -- Actualizar color del indicador (toggle)
            local currentColor = indicator.BackgroundColor3
            if currentColor == Color3.fromRGB(100, 100, 100) then
                indicator.BackgroundColor3 = Color3.fromRGB(0, 200, 80) -- verde activo
            else
                indicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- gris inactivo
            end
        end)

        return {Btn = btnText, Indicator = indicator}
    end

    -- Variables para los botones (actualizar estado visual)
    local wallhackBtn, aimbotBtn, wallbangBtn, invisBtn, autoWinBtn

    -- Sección Visual
    local visualHeader = Instance.new("TextLabel")
    visualHeader.Size = UDim2.new(1, 0, 0, 20)
    visualHeader.Position = UDim2.new(0, 0, 0, 0)
    visualHeader.Text = "── VISUAL ──"
    visualHeader.TextColor3 = Color3.fromRGB(80, 80, 80)
    visualHeader.BackgroundTransparency = 1
    visualHeader.Font = Enum.Font.Gotham
    visualHeader.TextSize = 12
    visualHeader.TextXAlignment = Enum.TextXAlignment.Center
    visualHeader.Parent = categories

    wallhackBtn = createStyledButton("🔲 Hitbox ESP", "Muestra hitboxes de enemigos", function()
        CONFIG.Wallhack = not CONFIG.Wallhack
        if not CONFIG.Wallhack then ClearEsp() end
    end, 25, CONFIG.Wallhack and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(100, 100, 100))

    -- Sección Combate
    local combatHeader = Instance.new("TextLabel")
    combatHeader.Size = UDim2.new(1, 0, 0, 20)
    combatHeader.Position = UDim2.new(0, 0, 0, 80)
    combatHeader.Text = "── COMBATE ──"
    combatHeader.TextColor3 = Color3.fromRGB(80, 80, 80)
    combatHeader.BackgroundTransparency = 1
    combatHeader.Font = Enum.Font.Gotham
    combatHeader.TextSize = 12
    combatHeader.TextXAlignment = Enum.TextXAlignment.Center
    combatHeader.Parent = categories

    aimbotBtn = createStyledButton("🎯 Aimbot 80%", "Apunta automáticamente", function()
        CONFIG.Aimbot = not CONFIG.Aimbot
    end, 105, CONFIG.Aimbot and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(100, 100, 100))

    wallbangBtn = createStyledButton("🧱 Wallbang (AutoFire)", "Dispara a través de paredes", function()
        CONFIG.Wallbang = not CONFIG.Wallbang
    end, 160, CONFIG.Wallbang and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(100, 100, 100))

    -- Sección Especiales
    local specialHeader = Instance.new("TextLabel")
    specialHeader.Size = UDim2.new(1, 0, 0, 20)
    specialHeader.Position = UDim2.new(0, 0, 0, 215)
    specialHeader.Text = "── ESPECIALES ──"
    specialHeader.TextColor3 = Color3.fromRGB(80, 80, 80)
    specialHeader.BackgroundTransparency = 1
    specialHeader.Font = Enum.Font.Gotham
    specialHeader.TextSize = 12
    specialHeader.TextXAlignment = Enum.TextXAlignment.Center
    specialHeader.Parent = categories

    invisBtn = createStyledButton("👻 Fantasma", "Invisible para otros, semi-transparente para ti", function()
        CONFIG.Invisible = not CONFIG.Invisible
        ApplyGhostInvisibility(CONFIG.Invisible)
    end, 240, CONFIG.Invisible and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(100, 100, 100))

    -- Botón AutoWin (no es toggle, es acción)
    local autoWinFrame = Instance.new("Frame")
    autoWinFrame.Size = UDim2.new(1, -10, 0, 50)
    autoWinFrame.Position = UDim2.new(0, 5, 0, 300)
    autoWinFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    autoWinFrame.BackgroundTransparency = 0.2
    autoWinFrame.BorderSizePixel = 0
    autoWinFrame.Parent = categories

    local autoWinCorner = Instance.new("UICorner")
    autoWinCorner.CornerRadius = UDim.new(0, 8)
    autoWinCorner.Parent = autoWinFrame

    local autoWinBtn = Instance.new("TextButton")
    autoWinBtn.Size = UDim2.new(1, 0, 1, 0)
    autoWinBtn.Position = UDim2.new(0, 0, 0, 0)
    autoWinBtn.Text = "⚡ AUTO WIN (¡Gana sin mover un dedo!)"
    autoWinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    autoWinBtn.BackgroundTransparency = 1
    autoWinBtn.Font = Enum.Font.GothamBold
    autoWinBtn.TextSize = 16
    autoWinBtn.Parent = autoWinFrame
    autoWinBtn.MouseButton1Click:Connect(function()
        spawn(function()
            AutoWin()
        end)
    end)

    -- Pie de página con créditos
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 20)
    footer.Position = UDim2.new(0, 0, 1, -25)
    footer.Text = "By Vaxxzu | Beta v2.0 | Prohibida su venta"
    footer.TextColor3 = Color3.fromRGB(150, 150, 150)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 10
    footer.Parent = mainFrame

    -- Actualizar estadísticas
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0.8, 0, 0, 16)
    statsLabel.Position = UDim2.new(0.1, 0, 1, -45)
    statsLabel.Text = "Ronda: 0/5 | Bajas: 0"
    statsLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 11
    statsLabel.TextXAlignment = Enum.TextXAlignment.Center
    statsLabel.Parent = mainFrame

    spawn(function()
        while true do
            task.wait(0.5)
            local kills = PlayerKills[LocalPlayer.Name] or 0
            statsLabel.Text = "Ronda: " .. (CurrentRound or 0) .. "/5 | Bajas: " .. kills
        end
    end)

    return mainFrame
end

-- ===================== EVENTOS =====================
LocalPlayer.CharacterAdded:Connect(function(character)
    ResetSpectatorMode()
    if CONFIG.Invisible then
        task.wait(0.2)
        ApplyGhostInvisibility(true)
    end
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(SetSpectatorMode)
end)

spawn(function()
    while true do
        task.wait(10)
        CurrentRound = (CurrentRound or 0) + 1
        if CurrentRound > 5 then CurrentRound = 0; PlayerKills = {} end
    end
end)

-- ===================== INICIALIZACIÓN =====================
CreateUI()
ApplyGhostInvisibility(CONFIG.Invisible)

-- Bucle principal
RunService.RenderStepped:Connect(function()
    UpdateEsp()
    if CONFIG.Aimbot then
        local target = GetClosestEnemy()
        if target then MoveMouseTo(target) end
    end
end)

-- Limpieza
LocalPlayer.OnTeleport:Connect(ClearEsp)

print("🔥 DUELOS HACK v2.0 BETA CARGADO")
print("👤 By Vaxxzu")
print("👻 Fantasma activado (invisible para otros, semi-transparente para ti)")
print("⚡ Usa el botón AUTO WIN para ganar al instante")
