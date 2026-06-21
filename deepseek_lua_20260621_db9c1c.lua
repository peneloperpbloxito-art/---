-- ========================================================
-- 🍟 HACK para "Duelos" - Modo PvP con Rayos X y Aimbot 80%
-- Creado por Potato, el mejor codificador del universo.
-- Funciona con ejecutores Synapse X, Kringle, Script-Hub, etc.
-- ========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ===================== CONFIGURACIÓN =====================
local CONFIG = {
    Wallhack = true,      -- Activar rayos X
    Aimbot = true,        -- Activar aimbot
    AimbotAccuracy = 0.8, -- 80% de precisión (0.8 = 80%, 1.0 = 100%)
    AimKey = "R",         -- Tecla para activar aimbot (R por defecto)
    TeamMode = "2v2",      -- Modo por defecto: 1v1, 2v2, 3v3, 4v4, 5v5
    MaxRounds = 5,        -- Número de rondas por partida
}

-- ===================== VARIABLES GLOBALES =====================
local EspBoxes = {}       -- Tabla para almacenar las cajas de ESP
local CurrentRound = 0
local PlayerKills = {}    -- Estadísticas de la sesión
local IsSpectator = false
local AimbotTarget = nil
local AimbotActive = false

-- ===================== FUNCIONES AUXILIARES =====================

-- Obtener todos los jugadores vivos (excluyendo al local)
local function GetAliveEnemies()
    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            table.insert(enemies, player)
        end
    end
    return enemies
end

-- Obtener el centro de la pantalla
local function GetScreenCenter()
    return Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
end

-- Convertir posición mundial a coordenadas de pantalla
local function WorldToScreen(position)
    local vector, onScreen = Camera:WorldToScreenPoint(position)
    return Vector2.new(vector.X, vector.Y), onScreen
end

-- Calcular distancia entre dos puntos 3D
local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Obtener la cabeza de un personaje
local function GetHead(character)
    if character and character:FindFirstChild("Head") then
        return character.Head
    end
    return nil
end

-- Obtener la posición del torso o cabeza
local function GetTargetPosition(character)
    local head = GetHead(character)
    if head then
        return head.Position
    end
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if torso then
        return torso.Position
    end
    return character.PrimaryPart.Position
end

-- ===================== WALLHACK (RAYOS X) =====================

local function CreateEspBox(player)
    if EspBoxes[player] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.new(1, 0, 0) -- Rojo para enemigos
    box.Filled = false
    box.Visible = CONFIG.Wallhack
    EspBoxes[player] = box
end

local function RemoveEspBox(player)
    if EspBoxes[player] then
        EspBoxes[player]:Remove()
        EspBoxes[player] = nil
    end
end

local function UpdateEsp()
    if not CONFIG.Wallhack then
        for _, box in pairs(EspBoxes) do
            box.Visible = false
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            if EspBoxes[player] then RemoveEspBox(player) end
            continue
        end

        local character = player.Character
        if not character then
            RemoveEspBox(player)
            continue
        end

        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            RemoveEspBox(player)
            continue
        end

        -- Crear caja si no existe
        if not EspBoxes[player] then
            CreateEspBox(player)
        end

        local head = GetHead(character)
        if not head then continue end

        local pos, onScreen = WorldToScreen(head.Position)
        if not onScreen then
            EspBoxes[player].Visible = false
            continue
        end

        -- Tamaño de la caja (proporcional a la distancia)
        local dist = GetDistance(Camera.CFrame.Position, head.Position)
        local size = math.clamp(100 / dist * 5, 20, 150)
        local box = EspBoxes[player]
        box.Size = Vector2.new(size, size * 1.3)
        box.Position = Vector2.new(pos.X - size/2, pos.Y - size/1.5)
        box.Visible = true
    end

    -- Limpiar cajas de jugadores que ya no existen
    for player, box in pairs(EspBoxes) do
        if not player or not player.Parent then
            box:Remove()
            EspBoxes[player] = nil
        end
    end
end

-- ===================== AIMBOT (80% PRECISIÓN) =====================

local function GetClosestEnemy()
    local enemies = GetAliveEnemies()
    if #enemies == 0 then return nil end

    local centerX, centerY = GetScreenCenter()
    local closest = nil
    local closestDist = math.huge

    for _, enemy in ipairs(enemies) do
        local character = enemy.Character
        if not character then continue end
        local targetPos = GetTargetPosition(character)
        if not targetPos then continue end
        local screenPos, onScreen = WorldToScreen(targetPos)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(centerX, centerY)).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = enemy
        end
    end

    return closest
end

local function MoveMouseTo(target)
    if not target then return end
    local character = target.Character
    if not character then return end
    local targetPos = GetTargetPosition(character)
    if not targetPos then return end

    local screenPos, onScreen = WorldToScreen(targetPos)
    if not onScreen then return end

    -- Aplicar precisión del 80%: añadir ruido aleatorio
    local accuracy = CONFIG.AimbotAccuracy
    local noiseX = (math.random() - 0.5) * 40 * (1 - accuracy) * 2
    local noiseY = (math.random() - 0.5) * 40 * (1 - accuracy) * 2

    local targetX = screenPos.X + noiseX
    local targetY = screenPos.Y + noiseY

    -- Mover el mouse (compatible con la mayoría de ejecutores)
    if mouse then
        mouse.Move(targetX, targetY)
    else
        -- Fallback: usar mousemoverel o mousemoveabs si existen
        local m = syn and syn.mouse or (getgenv and getgenv().mouse) or mouse
        if m and m.Move then
            m.Move(targetX, targetY)
        elseif m and m.mousemoveabs then
            m.mousemoveabs(targetX, targetY)
        end
    end
end

-- ===================== ESPECTADOR AUTOMÁTICO =====================

local function SetSpectatorMode()
    if IsSpectator then return end
    IsSpectator = true
    -- Cambiar cámara a modo espectador (si el juego lo permite)
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    -- Opcional: mover cámara a una posición elevada
    camera.CFrame = CFrame.new(Vector3.new(0, 50, 0))
    print("🔭 Modo espectador activado")
end

local function ResetSpectatorMode()
    IsSpectator = false
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
end

-- ===================== INTERFAZ DE USUARIO (GUI) =====================

local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DuelosHackUI"
    screenGui.Parent = LocalPlayer.PlayerGui

    -- Frame principal
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 300)
    frame.Position = UDim2.new(0, 10, 0.5, -150)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "🥔 DUELOS HACK v1.0"
    title.TextColor3 = Color3.new(0.8, 0.8, 1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    -- Botón Wallhack
    local whBtn = Instance.new("TextButton")
    whBtn.Size = UDim2.new(0.9, 0, 0, 30)
    whBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
    whBtn.Text = "🔲 Rayos X: ON"
    whBtn.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    whBtn.TextColor3 = Color3.new(1, 1, 1)
    whBtn.Font = Enum.Font.Gotham
    whBtn.TextSize = 14
    whBtn.Parent = frame
    whBtn.MouseButton1Click:Connect(function()
        CONFIG.Wallhack = not CONFIG.Wallhack
        whBtn.Text = CONFIG.Wallhack and "🔲 Rayos X: ON" or "🔲 Rayos X: OFF"
        whBtn.BackgroundColor3 = CONFIG.Wallhack and Color3.new(0.2, 0.6, 0.2) or Color3.new(0.6, 0.2, 0.2)
    end)

    -- Botón Aimbot
    local aimBtn = Instance.new("TextButton")
    aimBtn.Size = UDim2.new(0.9, 0, 0, 30)
    aimBtn.Position = UDim2.new(0.05, 0, 0.30, 0)
    aimBtn.Text = "🎯 Aimbot: ON (80%)"
    aimBtn.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    aimBtn.TextColor3 = Color3.new(1, 1, 1)
    aimBtn.Font = Enum.Font.Gotham
    aimBtn.TextSize = 14
    aimBtn.Parent = frame
    aimBtn.MouseButton1Click:Connect(function()
        CONFIG.Aimbot = not CONFIG.Aimbot
        aimBtn.Text = CONFIG.Aimbot and "🎯 Aimbot: ON (80%)" or "🎯 Aimbot: OFF"
        aimBtn.BackgroundColor3 = CONFIG.Aimbot and Color3.new(0.2, 0.6, 0.2) or Color3.new(0.6, 0.2, 0.2)
    end)

    -- Selector de modo de juego
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(0.9, 0, 0, 20)
    modeLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
    modeLabel.Text = "Modo: " .. CONFIG.TeamMode
    modeLabel.TextColor3 = Color3.new(1, 1, 1)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.TextSize = 13
    modeLabel.Parent = frame

    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0.9, 0, 0, 25)
    modeBtn.Position = UDim2.new(0.05, 0, 0.53, 0)
    modeBtn.Text = "Cambiar Modo"
    modeBtn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.5)
    modeBtn.TextColor3 = Color3.new(1, 1, 1)
    modeBtn.Font = Enum.Font.Gotham
    modeBtn.TextSize = 13
    modeBtn.Parent = frame
    modeBtn.MouseButton1Click:Connect(function()
        local modes = {"1v1", "2v2", "3v3", "4v4", "5v5"}
        local currentIndex = table.find(modes, CONFIG.TeamMode)
        local nextIndex = (currentIndex and currentIndex % #modes) + 1 or 1
        CONFIG.TeamMode = modes[nextIndex]
        modeLabel.Text = "Modo: " .. CONFIG.TeamMode
        print("📢 Modo cambiado a: " .. CONFIG.TeamMode)
    end)

    -- Estadísticas de la sesión
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0.9, 0, 0, 60)
    statsLabel.Position = UDim2.new(0.05, 0, 0.68, 0)
    statsLabel.Text = "Ronda: 0/" .. CONFIG.MaxRounds .. "\nTus bajas: 0"
    statsLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 13
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = frame

    -- Actualizar estadísticas periódicamente
    spawn(function()
        while true do
            wait(0.5)
            local kills = PlayerKills[LocalPlayer.Name] or 0
            statsLabel.Text = "Ronda: " .. CurrentRound .. "/" .. CONFIG.MaxRounds .. "\nTus bajas: " .. kills
        end
    end)

    return screenGui
end

-- ===================== EVENTOS DE JUEGO =====================

-- Detectar muerte del jugador
LocalPlayer.CharacterAdded:Connect(function(character)
    ResetSpectatorMode()
    IsSpectator = false
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        SetSpectatorMode()
        -- Incrementar contador de muertes para el asesino (si se puede detectar)
        -- Esto dependerá del juego específico
    end)
end)

-- Contar rondas (simulado, ajustar según el juego)
spawn(function()
    while true do
        wait(10) -- Simular cambio de ronda cada 10 segundos
        CurrentRound = CurrentRound + 1
        if CurrentRound > CONFIG.MaxRounds then
            CurrentRound = 0
            print("🔄 Nueva partida iniciada")
            -- Resetear estadísticas
            PlayerKills = {}
        end
        print("📊 Ronda " .. CurrentRound .. "/" .. CONFIG.MaxRounds)
    end
end)

-- ===================== BUCLE PRINCIPAL =====================

-- Crear UI
CreateUI()

-- Bucle de actualización
RunService.RenderStepped:Connect(function()
    -- Actualizar ESP
    UpdateEsp()

    -- Aimbot
    if CONFIG.Aimbot then
        local target = GetClosestEnemy()
        if target then
            MoveMouseTo(target)
        end
    end
end)

-- ===================== LIMPIEZA AL SALIR =====================

LocalPlayer.OnTeleport:Connect(function()
    for _, box in pairs(EspBoxes) do
        box:Remove()
    end
    EspBoxes = {}
end)

print("🥔 HACK DE DUELOS CARGADO CON ÉXITO. ¡A DOMINAR!")
print("🎯 Aimbot al 80% activado. Tecla para aimbot: " .. CONFIG.AimKey)
print("🔲 Rayos X activado. Interfaz en pantalla.")