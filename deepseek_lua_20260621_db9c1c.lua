-- ============================================================
-- 🔥 DUELOS HACK v1.5 BETA 🔥
-- Desarrollado por: Vaxxzu
-- Modos: Wallbang (disparo a través de paredes), Invisibilidad total, AutoWin.
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ===================== CONFIGURACIÓN =====================
local CONFIG = {
    Wallhack = true,      -- Rayos X con hitboxes
    Aimbot = true,        -- Aimbot activado
    Wallbang = true,      -- Disparar a través de paredes (AUTO FIRE)
    Invisible = true,     -- Volverse invisible
    AutoWinActive = false,-- Estado del AutoWin
    AimbotAccuracy = 0.8, -- 80%
    TeamMode = "2v2",
}

-- ===================== VARIABLES GLOBALES =====================
local EspObjects = {}
local PlayerKills = {}
local IsSpectator = false
local CurrentRound = 0
local IsFiring = false

-- ===================== FUNCIÓN: INVISIBILIDAD =====================
local function ApplyInvisibility(state)
    local character = LocalPlayer.Character
    if not character then return end

    -- Ocultar todas las partes del cuerpo
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = state and 1 or 0
            part.CanCollide = not state
        end
        if part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = state and 1 or 0
        end
    end

    -- Ocultar Humanoid (barra de vida y nombre)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.HealthDisplayDistance = state and 0 or 100
        humanoid.NameDisplayDistance = state and 0 or 100
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, not state)
    end

    -- Ocultar accesorios y herramientas
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Tool") then
            child.Handle.Transparency = state and 1 or 0
        end
    end
end

-- ===================== FUNCIÓN: OBTENER HITBOXES =====================
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
        if not onScreen then allOnScreen = false end
        local x, y = vec.X, vec.Y
        if x < minX then minX = x end
        if x > maxX then maxX = x end
        if y < minY then minY = y end
        if y > maxY then maxY = y end
    end

    if maxX < 0 or minX > Camera.ViewportSize.X or maxY < 0 or minY > Camera.ViewportSize.Y then
        return nil
    end
    return { X = minX, Y = minY, Width = maxX - minX, Height = maxY - minY, OnScreen = allOnScreen }
end

-- ===================== DIBUJAR ESP =====================
local function ClearEsp()
    for _, obj in ipairs(EspObjects) do pcall(function() obj:Remove() end) end
    EspObjects = {}
end

local function DrawHitbox(rect, color)
    if not rect or rect.Width < 1 or rect.Height < 1 then return end
    local fill = Drawing.new("Rectangle")
    fill.Size = Vector2.new(rect.Width, rect.Height)
    fill.Position = Vector2.new(rect.X, rect.Y)
    fill.Color = color
    fill.Transparency = 0.3
    fill.Filled = true
    fill.Visible = CONFIG.Wallhack
    table.insert(EspObjects, fill)

    local border = Drawing.new("Rectangle")
    border.Size = Vector2.new(rect.Width, rect.Height)
    border.Position = Vector2.new(rect.X, rect.Y)
    border.Color = color
    border.Transparency = 0.1
    border.Filled = false
    border.Thickness = 2
    border.Visible = CONFIG.Wallhack
    table.insert(EspObjects, border)
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

        local parts = GetCharacterParts(character)
        for _, partData in ipairs(parts) do
            local rect = GetPartScreenRect(partData.Part)
            if rect then DrawHitbox(rect, partData.Color) end
        end

        local refPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("Head")
        if refPart then
            local rect = GetPartScreenRect(refPart)
            if rect then
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
            local pos, onScreen = Camera:WorldToScreenPoint(head.Position)
            -- WALLBANG: ignoramos si está en pantalla o no, solo usamos la posición proyectada
            local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(centerX, centerY)).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = enemy
            end
        end
    end
    return closest
end

-- Función para disparar (simular clic izquierdo)
local function FireWeapon()
    if not Mouse then return end
    -- Simular presión y liberación del botón izquierdo
    if Mouse.Button1Down and Mouse.Button1Up then
        Mouse.Button1Down()
        task.wait(0.05)
        Mouse.Button1Up()
    else
        -- Fallback: usar UserInputService
        UserInputService:SetMouseButtonEnabled(Enum.UserInputType.MouseButton1, true)
        UserInputService:SetMouseButtonEnabled(Enum.UserInputType.MouseButton1, false)
    end
end

local function MoveMouseTo(target)
    if not target then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    local pos, _ = Camera:WorldToScreenPoint(head.Position) -- No importa si está fuera de pantalla

    local accuracy = CONFIG.AimbotAccuracy
    local noiseX = (math.random() - 0.5) * 30 * (1 - accuracy) * 2
    local noiseY = (math.random() - 0.5) * 30 * (1 - accuracy) * 2

    local targetX = pos.X + noiseX
    local targetY = pos.Y + noiseY

    -- Movemos el mouse
    if mouse then
        mouse.Move(targetX, targetY)
    else
        local m = syn and syn.mouse or (getgenv and getgenv().mouse) or mouse
        if m and m.Move then m.Move(targetX, targetY)
        elseif m and m.mousemoveabs then m.mousemoveabs(targetX, targetY) end
    end

    -- Si Wallbang está activado, DISPARAMOS AUTOMÁTICAMENTE a través de las paredes
    if CONFIG.Wallbang then
        FireWeapon()
    end
end

-- ===================== AUTO WIN (VICTORIA AUTOMÁTICA) =====================
local function AutoWin()
    if CONFIG.AutoWinActive then return end
    CONFIG.AutoWinActive = true
    print("⚡ INICIANDO AUTO WIN... ELIMINANDO A TODOS.")

    -- Intentar forzar la victoria por RemoteEvent (común en juegos de Roblox)
    local success = false
    for _, obj in pairs(getconnections and getconnections(game:GetService("ReplicatedStorage"):GetDescendants()) or {}) do
        -- Intentar disparar eventos que parezcan de victoria
        pcall(function()
            if obj and obj.Fire then
                obj:FireServer("Win", "RoundWin")
                success = true
            end
        end)
    end

    -- Si no funcionó el Remote, usamos el método agresivo: matar a todos manualmente
    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            table.insert(enemies, player)
        end
    end

    if #enemies == 0 then
        print("✅ Ya no hay enemigos vivos. Victoria asegurada.")
        CONFIG.AutoWinActive = false
        return
    end

    -- Matar a todos los enemigos uno por uno
    for _, enemy in ipairs(enemies) do
        local head = enemy.Character:FindFirstChild("Head")
        if head then
            local pos, _ = Camera:WorldToScreenPoint(head.Position)
            -- Apuntar directamente a la cabeza sin ruido
            if mouse and mouse.Move then
                mouse.Move(pos.X, pos.Y)
            elseif syn and syn.mouse and syn.mouse.Move then
                syn.mouse.Move(pos.X, pos.Y)
            end
            task.wait(0.1)
            -- Disparar varias veces para asegurar
            for i = 1, 3 do
                FireWeapon()
                task.wait(0.05)
            end
            task.wait(0.1)
        end
    end

    print("✅ AUTO WIN COMPLETADO. ¡TODOS LOS ENEMIGOS ELIMINADOS!")
    CONFIG.AutoWinActive = false
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

-- ===================== INTERFAZ MODERNA =====================
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DuelosHackUI"
    screenGui.Parent = LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 420)
    frame.Position = UDim2.new(0, 15, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "⚡ DUELOS HACK [BETA] ⚡"
    title.TextColor3 = Color3.fromRGB(0, 220, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame

    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1, 0, 0, 20)
    credit.Position = UDim2.new(0, 0, 0, 30)
    credit.Text = "By Vaxxzu | Beta v1.5 (Wallbang + Invis + AutoWin)"
    credit.TextColor3 = Color3.fromRGB(150, 150, 180)
    credit.BackgroundTransparency = 1
    credit.Font = Enum.Font.Gotham
    credit.TextSize = 12
    credit.Parent = frame

    -- Botón 1: Rayos X
    local whBtn = Instance.new("TextButton")
    whBtn.Size = UDim2.new(0.9, 0, 0, 30)
    whBtn.Position = UDim2.new(0.05, 0, 0.18, 0)
    whBtn.Text = "🔲 Hitbox ESP: ON"
    whBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 200)
    whBtn.TextColor3 = Color3.new(1, 1, 1)
    whBtn.Font = Enum.Font.Gotham
    whBtn.TextSize = 13
    whBtn.Parent = frame
    whBtn.MouseButton1Click:Connect(function()
        CONFIG.Wallhack = not CONFIG.Wallhack
        whBtn.Text = CONFIG.Wallhack and "🔲 Hitbox ESP: ON" or "🔲 Hitbox ESP: OFF"
        whBtn.BackgroundColor3 = CONFIG.Wallhack and Color3.fromRGB(0, 180, 200) or Color3.fromRGB(80, 30, 30)
    end)

    -- Botón 2: Aimbot
    local aimBtn = Instance.new("TextButton")
    aimBtn.Size = UDim2.new(0.9, 0, 0, 30)
    aimBtn.Position = UDim2.new(0.05, 0, 0.30, 0)
    aimBtn.Text = "🎯 Aimbot 80%: ON"
    aimBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 200)
    aimBtn.TextColor3 = Color3.new(1, 1, 1)
    aimBtn.Font = Enum.Font.Gotham
    aimBtn.TextSize = 13
    aimBtn.Parent = frame
    aimBtn.MouseButton1Click:Connect(function()
        CONFIG.Aimbot = not CONFIG.Aimbot
        aimBtn.Text = CONFIG.Aimbot and "🎯 Aimbot 80%: ON" or "🎯 Aimbot 80%: OFF"
        aimBtn.BackgroundColor3 = CONFIG.Aimbot and Color3.fromRGB(0, 180, 200) or Color3.fromRGB(80, 30, 30)
    end)

    -- Botón 3: Wallbang (Disparo a través de paredes)
    local wallbangBtn = Instance.new("TextButton")
    wallbangBtn.Size = UDim2.new(0.9, 0, 0, 30)
    wallbangBtn.Position = UDim2.new(0.05, 0, 0.42, 0)
    wallbangBtn.Text = "🧱 Wallbang (AutoFire): ON"
    wallbangBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    wallbangBtn.TextColor3 = Color3.new(1, 1, 1)
    wallbangBtn.Font = Enum.Font.Gotham
    wallbangBtn.TextSize = 13
    wallbangBtn.Parent = frame
    wallbangBtn.MouseButton1Click:Connect(function()
        CONFIG.Wallbang = not CONFIG.Wallbang
        wallbangBtn.Text = CONFIG.Wallbang and "🧱 Wallbang (AutoFire): ON" or "🧱 Wallbang (AutoFire): OFF"
        wallbangBtn.BackgroundColor3 = CONFIG.Wallbang and Color3.fromRGB(200, 100, 0) or Color3.fromRGB(80, 30, 30)
    end)

    -- Botón 4: Invisibilidad
    local invisBtn = Instance.new("TextButton")
    invisBtn.Size = UDim2.new(0.9, 0, 0, 30)
    invisBtn.Position = UDim2.new(0.05, 0, 0.54, 0)
    invisBtn.Text = "👻 Invisibilidad: ON"
    invisBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
    invisBtn.TextColor3 = Color3.new(1, 1, 1)
    invisBtn.Font = Enum.Font.Gotham
    invisBtn.TextSize = 13
    invisBtn.Parent = frame
    invisBtn.MouseButton1Click:Connect(function()
        CONFIG.Invisible = not CONFIG.Invisible
        invisBtn.Text = CONFIG.Invisible and "👻 Invisibilidad: ON" or "👻 Invisibilidad: OFF"
        invisBtn.BackgroundColor3 = CONFIG.Invisible and Color3.fromRGB(100, 0, 200) or Color3.fromRGB(80, 30, 30)
        ApplyInvisibility(CONFIG.Invisible)
    end)

    -- Botón 5: AUTO WIN (el botón mágico)
    local autoWinBtn = Instance.new("TextButton")
    autoWinBtn.Size = UDim2.new(0.9, 0, 0, 35)
    autoWinBtn.Position = UDim2.new(0.05, 0, 0.67, 0)
    autoWinBtn.Text = "⚡ AUTO WIN (¡Click para ganar!)"
    autoWinBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    autoWinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    autoWinBtn.Font = Enum.Font.GothamBold
    autoWinBtn.TextSize = 14
    autoWinBtn.Parent = frame
    autoWinBtn.MouseButton1Click:Connect(function()
        spawn(function()
            AutoWin()
        end)
    end)

    -- Selector de Modo
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(0.9, 0, 0, 16)
    modeLabel.Position = UDim2.new(0.05, 0, 0.82, 0)
    modeLabel.Text = "Modo: " .. CONFIG.TeamMode
    modeLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.TextSize = 12
    modeLabel.Parent = frame

    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0.4, 0, 0, 22)
    modeBtn.Position = UDim2.new(0.3, 0, 0.87, 0)
    modeBtn.Text = "Cambiar"
    modeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    modeBtn.TextColor3 = Color3.new(1, 1, 1)
    modeBtn.Font = Enum.Font.Gotham
    modeBtn.TextSize = 12
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
    statsLabel.Size = UDim2.new(0.9, 0, 0, 30)
    statsLabel.Position = UDim2.new(0.05, 0, 0.92, 0)
    statsLabel.Text = "Ronda: 0/5 | Bajas: 0"
    statsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 12
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = frame

    spawn(function()
        while true do
            task.wait(0.5)
            local kills = PlayerKills[LocalPlayer.Name] or 0
            statsLabel.Text = "Ronda: " .. (CurrentRound or 0) .. "/5 | Bajas: " .. kills
        end
    end)
end

-- ===================== EVENTOS DE JUEGO =====================
LocalPlayer.CharacterAdded:Connect(function(character)
    ResetSpectatorMode()
    -- Aplicar invisibilidad automáticamente si está activada
    if CONFIG.Invisible then
        task.wait(0.1)
        ApplyInvisibility(true)
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

-- ===================== BUCLE PRINCIPAL =====================
CreateUI()
ApplyInvisibility(CONFIG.Invisible) -- Aplicar al inicio

RunService.RenderStepped:Connect(function()
    UpdateEsp()
    if CONFIG.Aimbot then
        local target = GetClosestEnemy()
        if target then
            MoveMouseTo(target)
        end
    end
end)

-- Limpieza
LocalPlayer.OnTeleport:Connect(ClearEsp)

print("🔥 DUELOS HACK v1.5 BETA CARGADO")
print("👤 By Vaxxzu")
print("🧱 Wallbang activado (disparo automático a través de paredes)")
print("👻 Invisibilidad activada")
print("⚡ Presiona 'AUTO WIN' para ganar sin mover un dedo.")
