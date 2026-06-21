-- ========================================================
-- 🔥 DUELOS HACK v1.0 BETA 🔥
-- Desarrollado por: Vaxxzu
-- Características: Hitbox ESP (Rayos X), Aimbot 80%, UI Moderna.
-- ========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ===================== CONFIGURACIÓN =====================
local CONFIG = {
    Wallhack = true,      -- Activar Rayos X (Hitboxes)
    Aimbot = true,        -- Activar Aimbot
    AimbotAccuracy = 0.8, -- 80% precisión
    TeamMode = "2v2",
    MaxRounds = 5,
}

-- ===================== VARIABLES GLOBALES =====================
local EspObjects = {}     -- Almacena todos los objetos de dibujo para limpiarlos
local PlayerKills = {}
local IsSpectator = false

-- ===================== FUNCIÓN: OBTENER HITBOXES =====================
-- Devuelve una tabla con partes del cuerpo para dibujar hitboxes reales
local function GetCharacterParts(character)
    local parts = {}
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return parts end

    -- Partes principales de la hitbox (cabeza, torso, extremidades)
    local head = character:FindFirstChild("Head")
    local upperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local lowerTorso = character:FindFirstChild("LowerTorso")
    local leftArm = character:FindFirstChild("LeftArm")
    local rightArm = character:FindFirstChild("RightArm")
    local leftLeg = character:FindFirstChild("LeftLeg")
    local rightLeg = character:FindFirstChild("RightLeg")

    if head then table.insert(parts, {Part = head, Color = Color3.fromRGB(255, 50, 50)}) end     -- Rojo neón
    if upperTorso then table.insert(parts, {Part = upperTorso, Color = Color3.fromRGB(0, 200, 255)}) end -- Cian
    if lowerTorso then table.insert(parts, {Part = lowerTorso, Color = Color3.fromRGB(0, 150, 200)}) end
    if leftArm then table.insert(parts, {Part = leftArm, Color = Color3.fromRGB(255, 200, 50)}) end      -- Amarillo
    if rightArm then table.insert(parts, {Part = rightArm, Color = Color3.fromRGB(255, 200, 50)}) end
    if leftLeg then table.insert(parts, {Part = leftLeg, Color = Color3.fromRGB(50, 255, 100)}) end      -- Verde
    if rightLeg then table.insert(parts, {Part = rightLeg, Color = Color3.fromRGB(50, 255, 100)}) end

    return parts
end

-- ===================== FUNCIÓN: CALCULAR RECTÁNGULO DE UNA PARTE =====================
-- Convierte los 8 vértices de una parte a pantalla para dibujar la hitbox exacta
local function GetPartScreenRect(part)
    local cframe = part.CFrame
    local size = part.Size / 2
    local corners = {
        cframe:PointToWorldSpace(Vector3.new(-size.X, -size.Y, -size.Z)),
        cframe:PointToWorldSpace(Vector3.new( size.X, -size.Y, -size.Z)),
        cframe:PointToWorldSpace(Vector3.new(-size.X,  size.Y, -size.Z)),
        cframe:PointToWorldSpace(Vector3.new( size.X,  size.Y, -size.Z)),
        cframe:PointToWorldSpace(Vector3.new(-size.X, -size.Y,  size.Z)),
        cframe:PointToWorldSpace(Vector3.new( size.X, -size.Y,  size.Z)),
        cframe:PointToWorldSpace(Vector3.new(-size.X,  size.Y,  size.Z)),
        cframe:PointToWorldSpace(Vector3.new( size.X,  size.Y,  size.Z))
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local allOnScreen = true

    for _, point in ipairs(corners) do
        local vec, onScreen = Camera:WorldToScreenPoint(point)
        if not onScreen then 
            allOnScreen = false
            -- Aún así procesamos para no romper el box si está medio fuera
        end
        local x, y = vec.X, vec.Y
        if x < minX then minX = x end
        if x > maxX then maxX = x end
        if y < minY then minY = y end
        if y > maxY then maxY = y end
    end

    -- Si está completamente fuera de pantalla, devolvemos nil
    if maxX < 0 or minX > Camera.ViewportSize.X or maxY < 0 or minY > Camera.ViewportSize.Y then
        return nil
    end

    return {
        X = minX,
        Y = minY,
        Width = maxX - minX,
        Height = maxY - minY,
        OnScreen = allOnScreen
    }
end

-- ===================== DIBUJAR ESP (RAYOS X) =====================
local function ClearEsp()
    for _, obj in ipairs(EspObjects) do
        pcall(function() obj:Remove() end)
    end
    EspObjects = {}
end

local function DrawHitbox(rect, color, name)
    if not rect or rect.Width < 1 or rect.Height < 1 then return end

    -- 1. Fondo transparente moderno (relleno)
    local fill = Drawing.new("Rectangle")
    fill.Size = Vector2.new(rect.Width, rect.Height)
    fill.Position = Vector2.new(rect.X, rect.Y)
    fill.Color = color
    fill.Transparency = 0.3 -- Transparencia para efecto "moderno"
    fill.Filled = true
    fill.Visible = CONFIG.Wallhack
    table.insert(EspObjects, fill)

    -- 2. Borde neón (más grueso)
    local border = Drawing.new("Rectangle")
    border.Size = Vector2.new(rect.Width, rect.Height)
    border.Position = Vector2.new(rect.X, rect.Y)
    border.Color = color
    border.Transparency = 0.1
    border.Filled = false
    border.Thickness = 2
    border.Visible = CONFIG.Wallhack
    table.insert(EspObjects, border)

    -- 3. Nombre del jugador DEBAJO de la hitbox (no encima de la cabeza)
    if name then
        local text = Drawing.new("Text")
        text.Text = name
        text.Size = 16
        text.Font = Drawing.Fonts.UI
        text.Color = Color3.fromRGB(255, 255, 255)
        text.Transparency = 0.2
        text.Center = true
        text.Outline = true
        text.OutlineColor = Color3.fromRGB(0, 0, 0)
        text.Position = Vector2.new(rect.X + (rect.Width / 2), rect.Y + rect.Height + 5) -- Debajo de la caja
        text.Visible = CONFIG.Wallhack
        table.insert(EspObjects, text)
    end
end

local function UpdateEsp()
    ClearEsp()

    if not CONFIG.Wallhack then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        -- Obtener partes para hitbox
        local parts = GetCharacterParts(character)
        if #parts == 0 then continue end

        -- Dibujar cada hitbox (cabeza, torso, brazos, piernas)
        for _, partData in ipairs(parts) do
            local rect = GetPartScreenRect(partData.Part)
            if rect then
                DrawHitbox(rect, partData.Color, nil) -- No poner nombre en cada parte
            end
        end

        -- Dibujar el nombre DEBAJO del torso o de toda la hitbox (usamos UpperTorso o Head para referencia)
        local refPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("Head")
        if refPart then
            local rect = GetPartScreenRect(refPart)
            if rect then
                -- Ampliamos el rect para que el nombre se vea bien, o simplemente usamos la posición inferior
                local nameText = Drawing.new("Text")
                nameText.Text = player.Name
                nameText.Size = 18
                nameText.Font = Drawing.Fonts.UI
                nameText.Color = Color3.fromRGB(255, 255, 255)
                nameText.Transparency = 0.1
                nameText.Center = true
                nameText.Outline = true
                nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
                nameText.Position = Vector2.new(rect.X + (rect.Width / 2), rect.Y + rect.Height + 18) 
                nameText.Visible = CONFIG.Wallhack
                table.insert(EspObjects, nameText)

                -- Pequeña barra de vida simplificada debajo del nombre (toque moderno)
                local healthBarBg = Drawing.new("Rectangle")
                healthBarBg.Size = Vector2.new(rect.Width * 0.8, 4)
                healthBarBg.Position = Vector2.new(rect.X + (rect.Width * 0.1), rect.Y + rect.Height + 35)
                healthBarBg.Color = Color3.fromRGB(30, 30, 30)
                healthBarBg.Transparency = 0.3
                healthBarBg.Filled = true
                healthBarBg.Visible = CONFIG.Wallhack
                table.insert(EspObjects, healthBarBg)

                local healthBar = Drawing.new("Rectangle")
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                healthBar.Size = Vector2.new(rect.Width * 0.8 * healthPercent, 4)
                healthBar.Position = Vector2.new(rect.X + (rect.Width * 0.1), rect.Y + rect.Height + 35)
                healthBar.Color = Color3.fromRGB(0, 255, 100)
                if healthPercent < 0.3 then healthBar.Color = Color3.fromRGB(255, 50, 50) end
                healthBar.Transparency = 0.2
                healthBar.Filled = true
                healthBar.Visible = CONFIG.Wallhack
                table.insert(EspObjects, healthBar)
            end
        end
    end
end

-- ===================== AIMBOT (80%) =====================
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
            local pos, onScreen = Camera:WorldToScreenPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(centerX, centerY)).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = enemy
                end
            end
        end
    end
    return closest
end

local function MoveMouseTo(target)
    if not target then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    local pos, onScreen = Camera:WorldToScreenPoint(head.Position)
    if not onScreen then return end

    local accuracy = CONFIG.AimbotAccuracy
    local noiseX = (math.random() - 0.5) * 30 * (1 - accuracy) * 2
    local noiseY = (math.random() - 0.5) * 30 * (1 - accuracy) * 2

    local targetX = pos.X + noiseX
    local targetY = pos.Y + noiseY

    if mouse then
        mouse.Move(targetX, targetY)
    else
        local m = syn and syn.mouse or (getgenv and getgenv().mouse) or mouse
        if m and m.Move then m.Move(targetX, targetY)
        elseif m and m.mousemoveabs then m.mousemoveabs(targetX, targetY) end
    end
end

-- ===================== ESPECTADOR =====================
local function SetSpectatorMode()
    if IsSpectator then return end
    IsSpectator = true
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 50, 0))
end

local function ResetSpectatorMode()
    IsSpectator = false
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

-- ===================== INTERFAZ MODERNA (UI) =====================
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DuelosHackUI"
    screenGui.Parent = LocalPlayer.PlayerGui

    -- Fondo principal (estilo oscuro con bordes neón)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 340)
    frame.Position = UDim2.new(0, 15, 0.5, -170)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    frame.Parent = screenGui

    -- Título con BETA y créditos
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "⚡ DUELOS HACK [BETA] ⚡"
    title.TextColor3 = Color3.fromRGB(0, 220, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    -- Créditos (By Vaxxzu)
    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1, 0, 0, 20)
    credit.Position = UDim2.new(0, 0, 0, 30)
    credit.Text = "Desarrollado por Vaxxzu | Beta v1.0"
    credit.TextColor3 = Color3.fromRGB(150, 150, 180)
    credit.BackgroundTransparency = 1
    credit.Font = Enum.Font.Gotham
    credit.TextSize = 12
    credit.Parent = frame

    -- Botón Rayos X
    local whBtn = Instance.new("TextButton")
    whBtn.Size = UDim2.new(0.9, 0, 0, 32)
    whBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
    whBtn.Text = "🔲 Hitbox ESP: ON"
    whBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 200)
    whBtn.TextColor3 = Color3.new(1, 1, 1)
    whBtn.Font = Enum.Font.Gotham
    whBtn.TextSize = 14
    whBtn.Parent = frame
    whBtn.MouseButton1Click:Connect(function()
        CONFIG.Wallhack = not CONFIG.Wallhack
        whBtn.Text = CONFIG.Wallhack and "🔲 Hitbox ESP: ON" or "🔲 Hitbox ESP: OFF"
        whBtn.BackgroundColor3 = CONFIG.Wallhack and Color3.fromRGB(0, 180, 200) or Color3.fromRGB(80, 30, 30)
    end)

    -- Botón Aimbot
    local aimBtn = Instance.new("TextButton")
    aimBtn.Size = UDim2.new(0.9, 0, 0, 32)
    aimBtn.Position = UDim2.new(0.05, 0, 0.34, 0)
    aimBtn.Text = "🎯 Aimbot 80%: ON"
    aimBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 200)
    aimBtn.TextColor3 = Color3.new(1, 1, 1)
    aimBtn.Font = Enum.Font.Gotham
    aimBtn.TextSize = 14
    aimBtn.Parent = frame
    aimBtn.MouseButton1Click:Connect(function()
        CONFIG.Aimbot = not CONFIG.Aimbot
        aimBtn.Text = CONFIG.Aimbot and "🎯 Aimbot 80%: ON" or "🎯 Aimbot 80%: OFF"
        aimBtn.BackgroundColor3 = CONFIG.Aimbot and Color3.fromRGB(0, 180, 200) or Color3.fromRGB(80, 30, 30)
    end)

    -- Selector de Modo
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(0.9, 0, 0, 20)
    modeLabel.Position = UDim2.new(0.05, 0, 0.48, 0)
    modeLabel.Text = "Modo: " .. CONFIG.TeamMode
    modeLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.TextSize = 13
    modeLabel.Parent = frame

    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0.9, 0, 0, 26)
    modeBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
    modeBtn.Text = "🔄 Cambiar Modo"
    modeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    modeBtn.TextColor3 = Color3.new(1, 1, 1)
    modeBtn.Font = Enum.Font.Gotham
    modeBtn.TextSize = 13
    modeBtn.Parent = frame
    modeBtn.MouseButton1Click:Connect(function()
        local modes = {"1v1", "2v2", "3v3", "4v4", "5v5"}
        for i, v in ipairs(modes) do if v == CONFIG.TeamMode then
            CONFIG.TeamMode = modes[i % #modes + 1]
            break
        end end
        modeLabel.Text = "Modo: " .. CONFIG.TeamMode
    end)

    -- Estadísticas
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0.9, 0, 0, 50)
    statsLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
    statsLabel.Text = "Ronda: 0/5\nTus bajas: 0"
    statsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 13
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = frame

    -- Footer de la UI
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 18)
    footer.Position = UDim2.new(0, 0, 1, -18)
    footer.Text = "🧠 By Vaxxzu | Prohibida su venta"
    footer.TextColor3 = Color3.fromRGB(80, 80, 100)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 10
    footer.Parent = frame

    spawn(function()
        while true do
            wait(0.5)
            local kills = PlayerKills[LocalPlayer.Name] or 0
            statsLabel.Text = "Ronda: " .. (CurrentRound or 0) .. "/5\nTus bajas: " .. kills
        end
    end)
end

-- ===================== EVENTOS =====================
local CurrentRound = 0

LocalPlayer.CharacterAdded:Connect(function(character)
    ResetSpectatorMode()
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(SetSpectatorMode)
end)

spawn(function()
    while true do
        wait(10)
        CurrentRound = (CurrentRound or 0) + 1
        if CurrentRound > 5 then CurrentRound = 0; PlayerKills = {} end
    end
end)

-- ===================== BUCLE PRINCIPAL =====================
CreateUI()

RunService.RenderStepped:Connect(function()
    UpdateEsp()
    if CONFIG.Aimbot then
        local target = GetClosestEnemy()
        if target then MoveMouseTo(target) end
    end
end)

-- Limpieza al salir
LocalPlayer.OnTeleport:Connect(ClearEsp)

print("🔥 DUELOS HACK BETA v1.0 ")
print("👤 Desarrollado por Vaxxzu")
print("📌 Hitboxes activadas. Nombres debajo de las cajas.")
