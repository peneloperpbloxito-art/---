-- ============================================================
-- 🔥 DUELOS HACK v3.2.6 BETA 🔥
-- Desarrollado por: Vaxxzu
-- GUI IDÉNTICA al menú "Murderers VS Sheriffs".
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
    -- Player Cheats
    Knife = false,
    AimbotBannable = false,
    AimbotLegit = false,
    ESP = false,
    Hitbox = false,      -- Vinculado a ESP
    ExternalScripts = false,
    Events = false,
    Boxes = false,

    -- Invisibilidad
    Invisible = false,
    GhostBubble = false,
    InvisibleKey = "G",

    -- Movimiento
    JumpPower = false,
    JumpPowerValue = 25,
    InfiniteJump = false,
    Speed = false,
    SpeedValue = 16,

    -- Internos
    AutoWinActive = false,
    AimbotTarget = nil,
}

-- ===================== VARIABLES GLOBALES =====================
local EspBoxes = {}
local PlayerKills = {}
local CurrentRound = 0
local UI_OPEN = true
local GhostHighlight = nil
local MainFrame = nil
local ToggleButton = nil
local InfiniteJumpActive = false
local CurrentSpeed = 16
local CurrentJumpPower = 25

-- ===================== FUNCIONES DE UTILIDAD =====================
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    if char then return char:FindFirstChild("Humanoid") end
    return nil
end

-- ===================== CUCHILLO (KNIFE) =====================
local function ToggleKnife(state)
    CONFIG.Knife = state
    local char = GetCharacter()
    if not char then return end
    -- Buscar cualquier herramienta y equiparla / o simular ataque
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        if state then
            tool.Parent = char
            task.wait(0.1)
            -- Simular clic para atacar
            if tool:FindFirstChild("Activate") then
                tool.Activate:FireServer()
            end
        end
    end
    print("🔪 Cuchillo: " .. (state and "ACTIVADO" or "DESACTIVADO"))
end

-- ===================== AIMBOT (BANNABLE Y LEGIT) =====================
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

local function MoveMouseTo(target, smooth)
    if not target then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    local pos, _ = Camera:WorldToScreenPoint(head.Position)

    if not smooth then
        -- Modo Bannable: movimiento instantáneo
        if Mouse and Mouse.Move then Mouse.Move(pos.X, pos.Y)
        elseif syn and syn.mouse and syn.mouse.Move then syn.mouse.Move(pos.X, pos.Y)
        elseif mousemoveabs then mousemoveabs(pos.X, pos.Y)
        else UserInputService:MoveMouse(pos.X, pos.Y) end
    else
        -- Modo Legit: movimiento suave (lerp)
        local currentX, currentY = Mouse.X, Mouse.Y
        local steps = 10
        for i = 1, steps do
            local alpha = i / steps
            local targetX = currentX + (pos.X - currentX) * alpha
            local targetY = currentY + (pos.Y - currentY) * alpha
            if Mouse and Mouse.Move then Mouse.Move(targetX, targetY)
            elseif syn and syn.mouse and syn.mouse.Move then syn.mouse.Move(targetX, targetY)
            elseif mousemoveabs then mousemoveabs(targetX, targetY)
            else UserInputService:MoveMouse(targetX, targetY) end
            task.wait(0.01)
        end
    end
    -- Disparamos si está activo el modo bannable (o siempre)
    if CONFIG.AimbotBannable then
        FireWeapon()
    end
end

-- ===================== ESP, HITBOX Y BOXES =====================
local function ClearEsp()
    for player, parts in pairs(EspBoxes) do
        for part, box in pairs(parts) do
            pcall(function() box:Destroy() end)
        end
    end
    EspBoxes = {}
end

local function UpdateEsp()
    -- Si ESP está desactivado, limpiamos todo
    if not CONFIG.ESP then
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

        -- Partes a marcar (si Hitbox está activado, mostramos todas, si no, solo la cabeza)
        local parts = {}
        if CONFIG.Hitbox then
            parts = {
                character:FindFirstChild("Head"),
                character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
                character:FindFirstChild("LowerTorso"),
                character:FindFirstChild("LeftArm"),
                character:FindFirstChild("RightArm"),
                character:FindFirstChild("LeftLeg"),
                character:FindFirstChild("RightLeg"),
            }
        else
            parts = { character:FindFirstChild("Head") }
        end

        for _, part in ipairs(parts) do
            if not part then continue end
            if EspBoxes[player][part] then
                local box = EspBoxes[player][part]
                box.Visible = CONFIG.Boxes
                box.Color3 = part.Name == "Head" and Color3.fromRGB(255, 50, 50) or
                             (part.Name:find("Torso") and Color3.fromRGB(0, 200, 255)) or
                             (part.Name:find("Arm") and Color3.fromRGB(255, 200, 50)) or
                             Color3.fromRGB(50, 255, 100)
            else
                if CONFIG.Boxes then
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
        end
    end
end

-- ===================== FANTASMA + BURBUJA + TECLA =====================
local function ApplyGhostInvisibility(state)
    local character = GetCharacter()
    if not character then return end

    local transparency = state and 1 or 0

    -- 1. Transparencia total para otros
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = transparency
        end
        if part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = transparency
        end
    end

    -- 2. Ocultar nombre y vida
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.HealthDisplayDistance = state and 0 or 100
        humanoid.NameDisplayDistance = state and 0 or 100
    end

    -- 3. Highlight local (fantasma)
    if state then
        if not GhostHighlight then
            GhostHighlight = Instance.new("Highlight")
            GhostHighlight.Adornee = character
            GhostHighlight.FillColor = Color3.fromRGB(0, 200, 255)
            GhostHighlight.FillTransparency = 0.6
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

    -- Burbuja Ghost (ForceField visual o efecto de burbuja)
    local bubble = character:FindFirstChild("GhostBubble")
    if CONFIG.GhostBubble and state then
        if not bubble then
            local forceField = Instance.new("ForceField")
            forceField.Name = "GhostBubble"
            forceField.Visible = true
            forceField.Parent = character
        end
    else
        if bubble then bubble:Destroy() end
    end
end

-- ===================== SALTO, VELOCIDAD, SALTO INFINITO =====================
local function ApplyMovementMods()
    local humanoid = GetHumanoid()
    if not humanoid then return end

    -- Velocidad
    if CONFIG.Speed then
        humanoid.WalkSpeed = CONFIG.SpeedValue
    else
        humanoid.WalkSpeed = 16
    end

    -- Potencia de Salto
    if CONFIG.JumpPower then
        humanoid.JumpPower = CONFIG.JumpPowerValue
    else
        humanoid.JumpPower = 50
    end
end

-- Salto Infinito
local function SetupInfiniteJump()
    local humanoid = GetHumanoid()
    if not humanoid then return end

    if CONFIG.InfiniteJump then
        if not InfiniteJumpActive then
            InfiniteJumpActive = true
            humanoid.StateChanged:Connect(function(oldState, newState)
                if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Freefall then
                    if CONFIG.InfiniteJump then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    else
        InfiniteJumpActive = false
    end
end

-- ===================== AUTO WIN (EVENTS) =====================
local function TriggerEvents()
    if not CONFIG.Events then return end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            pcall(function()
                if obj:IsA("RemoteEvent") then obj:FireServer("Win", "RoundWin")
                elseif obj:IsA("RemoteFunction") then obj:InvokeServer("Win", "RoundWin") end
            end)
        end
    end
end

-- ===================== UI PRINCIPAL (ESTILO MURDERERS VS SHERIFFS) =====================
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DuelosHackUI"
    screenGui.Parent = LocalPlayer.PlayerGui

    -- ===== BOTÓN FLOTANTE =====
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 45, 0, 45)
    toggleBtn.Position = UDim2.new(0, 10, 0.5, -22)
    toggleBtn.Text = "⚙️"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 24
    toggleBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    toggleBtn.BackgroundTransparency = 0.2
    toggleBtn.BorderSizePixel = 2
    toggleBtn.BorderColor3 = Color3.fromRGB(200, 200, 200)
    toggleBtn.Parent = screenGui
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn

    -- ===== PANEL PRINCIPAL (VERTICAL) =====
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = true
    mainFrame.Parent = screenGui
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    -- ===== BARRA SUPERIOR (TÍTULO) =====
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.Text = "DUELOS HACK"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local subTitle = Instance.new("TextLabel")
    subTitle.Size = UDim2.new(0.4, 0, 1, 0)
    subTitle.Position = UDim2.new(0.6, 0, 0, 0)
    subTitle.Text = "Vaxxzu"
    subTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    subTitle.BackgroundTransparency = 1
    subTitle.Font = Enum.Font.Gotham
    subTitle.TextSize = 14
    subTitle.TextXAlignment = Enum.TextXAlignment.Right
    subTitle.Parent = titleBar

    -- Botón cerrar (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 8)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextSize = 16
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        togglePanel(false)
    end)

    -- ===== SCROLL VIEW PARA OPCIONES =====
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -55)
    scroll.Position = UDim2.new(0, 5, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 680)
    scroll.Parent = mainFrame

    -- ===== FUNCIÓN PARA CREAR SECCIONES =====
    local function createHeader(text, yPos)
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, 0, 0, 20)
        header.Position = UDim2.new(0, 0, 0, yPos)
        header.Text = text
        header.TextColor3 = Color3.fromRGB(150, 150, 150)
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.GothamBold
        header.TextSize = 12
        header.TextXAlignment = Enum.TextXAlignment.Center
        header.Parent = scroll
        return header
    end

    local function createToggle(text, desc, callback, yPos, active)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 40)
        frame.Position = UDim2.new(0, 5, 0, yPos)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
        frame.Parent = scroll
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.7, 0, 1, 0)
        btn.Position = UDim2.new(0, 5, 0, 0)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = frame

        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.7, 0, 0, 14)
        descLabel.Position = UDim2.new(0, 5, 0, 22)
        descLabel.Text = desc
        descLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 10
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = frame

        -- Indicador (círculo)
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 12, 0, 12)
        indicator.Position = UDim2.new(0.9, 0, 0.5, -6)
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

    -- ===== CREACIÓN DE OPCIONES (BASADO EN LA IMAGEN) =====
    local y = 0

    -- SECCIÓN: Settings (lo ponemos como header)
    createHeader("── SETTINGS ──", y)
    y = y + 25

    -- SECCIÓN: Player Cheats
    createHeader("── PLAYER CHEATS ──", y)
    y = y + 25

    -- Knife
    local knifeToggle = createToggle("🔪 Knife", "Activa el cuchillo", function()
        CONFIG.Knife = not CONFIG.Knife
        ToggleKnife(CONFIG.Knife)
    end, y, false)
    y = y + 45

    -- Aimbot (bannable)
    local aimBannable = createToggle("🎯 Aimbot (bannable)", "Apunta y dispara instantáneo", function()
        CONFIG.AimbotBannable = not CONFIG.AimbotBannable
        if CONFIG.AimbotBannable then CONFIG.AimbotLegit = false end
    end, y, false)
    y = y + 45

    -- Aimbot Legit
    local aimLegit = createToggle("🎯 Aimbot Legit", "Apunta suave (menos detectable)", function()
        CONFIG.AimbotLegit = not CONFIG.AimbotLegit
        if CONFIG.AimbotLegit then CONFIG.AimbotBannable = false end
    end, y, false)
    y = y + 45

    -- ESP & Hitbox
    local espToggle = createToggle("👁️ ESP & Hitbox", "Muestra hitboxes y nombres", function()
        CONFIG.ESP = not CONFIG.ESP
        if not CONFIG.ESP then ClearEsp() end
    end, y, false)
    y = y + 45

    -- External Scripts (placeholder visual)
    local extToggle = createToggle("📦 External Scripts", "Scripts externos (beta)", function()
        CONFIG.ExternalScripts = not CONFIG.ExternalScripts
        print("📦 External Scripts: " .. (CONFIG.ExternalScripts and "ON" or "OFF"))
    end, y, false)
    y = y + 45

    -- Events (Auto Win)
    local eventsToggle = createToggle("⚡ Events", "Activa eventos de victoria", function()
        CONFIG.Events = not CONFIG.Events
        if CONFIG.Events then TriggerEvents() end
    end, y, false)
    y = y + 45

    -- Boxes
    local boxesToggle = createToggle("📦 Boxes", "Muestra cajas alrededor de las hitboxes", function()
        CONFIG.Boxes = not CONFIG.Boxes
        if not CONFIG.Boxes then ClearEsp() else CONFIG.ESP = true end
    end, y, false)
    y = y + 45

    -- Versión
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, 0, 0, 20)
    versionLabel.Position = UDim2.new(0, 0, 0, y)
    versionLabel.Text = "v3.2.6"
    versionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextSize = 12
    versionLabel.TextXAlignment = Enum.TextXAlignment.Center
    versionLabel.Parent = scroll
    y = y + 25

    -- SECCIÓN: Invisible
    createHeader("── INVISIBLE ──", y)
    y = y + 25

    -- Invisible (Modo Fantasma)
    local invisToggle = createToggle("👻 Invisible (Modo Fantasma)", "Te vuelves invisible para otros", function()
        CONFIG.Invisible = not CONFIG.Invisible
        ApplyGhostInvisibility(CONFIG.Invisible)
    end, y, false)
    y = y + 45

    -- Burbuja Ghost
    local bubbleToggle = createToggle("🫧 Burbuja Ghost", "Añade una burbuja protectora", function()
        CONFIG.GhostBubble = not CONFIG.GhostBubble
        ApplyGhostInvisibility(CONFIG.Invisible) -- Refresca
    end, y, false)
    y = y + 45

    -- Tecla Invisible (configurable)
    local keyFrame = Instance.new("Frame")
    keyFrame.Size = UDim2.new(1, -10, 0, 35)
    keyFrame.Position = UDim2.new(0, 5, 0, y)
    keyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    keyFrame.BackgroundTransparency = 0.3
    keyFrame.BorderSizePixel = 1
    keyFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
    keyFrame.Parent = scroll
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 6)
    keyCorner.Parent = keyFrame

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(0.5, 0, 1, 0)
    keyLabel.Position = UDim2.new(0, 5, 0, 0)
    keyLabel.Text = "🔑 Tecla Invisible:"
    keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextSize = 13
    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyLabel.Parent = keyFrame

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0.3, 0, 0.6, 0)
    keyBox.Position = UDim2.new(0.6, 0, 0.2, 0)
    keyBox.Text = CONFIG.InvisibleKey
    keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    keyBox.BorderSizePixel = 1
    keyBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
    keyBox.Font = Enum.Font.GothamBold
    keyBox.TextSize = 14
    keyBox.Parent = keyFrame
    keyBox.FocusLost:Connect(function()
        local key = string.upper(string.sub(keyBox.Text, 1, 1))
        CONFIG.InvisibleKey = key
        keyBox.Text = key
    end)

    y = y + 45

    -- SECCIÓN: Movimiento
    createHeader("── MOVIMIENTO ──", y)
    y = y + 25

    -- Activar Potencia de Salto
    local jumpToggle = createToggle("🦘 Activar Potencia de Salto", "Modifica la altura del salto", function()
        CONFIG.JumpPower = not CONFIG.JumpPower
        ApplyMovementMods()
    end, y, false)
    y = y + 45

    -- Slider de Potencia de Salto (valor numérico)
    local jumpFrame = Instance.new("Frame")
    jumpFrame.Size = UDim2.new(1, -10, 0, 30)
    jumpFrame.Position = UDim2.new(0, 5, 0, y)
    jumpFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    jumpFrame.BackgroundTransparency = 0.3
    jumpFrame.BorderSizePixel = 1
    jumpFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
    jumpFrame.Parent = scroll
    local jumpCorner = Instance.new("UICorner")
    jumpCorner.CornerRadius = UDim.new(0, 6)
    jumpCorner.Parent = jumpFrame

    local jumpLabel = Instance.new("TextLabel")
    jumpLabel.Size = UDim2.new(0.5, 0, 1, 0)
    jumpLabel.Position = UDim2.new(0, 5, 0, 0)
    jumpLabel.Text = "Potencia de Salto"
    jumpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    jumpLabel.BackgroundTransparency = 1
    jumpLabel.Font = Enum.Font.Gotham
    jumpLabel.TextSize = 12
    jumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    jumpLabel.Parent = jumpFrame

    local jumpBox = Instance.new("TextBox")
    jumpBox.Size = UDim2.new(0.2, 0, 0.6, 0)
    jumpBox.Position = UDim2.new(0.75, 0, 0.2, 0)
    jumpBox.Text = tostring(CONFIG.JumpPowerValue)
    jumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    jumpBox.BorderSizePixel = 1
    jumpBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
    jumpBox.Font = Enum.Font.GothamBold
    jumpBox.TextSize = 14
    jumpBox.Parent = jumpFrame
    jumpBox.FocusLost:Connect(function()
        local val = tonumber(jumpBox.Text) or 25
        CONFIG.JumpPowerValue = math.clamp(val, 10, 300)
        jumpBox.Text = tostring(CONFIG.JumpPowerValue)
        if CONFIG.JumpPower then ApplyMovementMods() end
    end)

    y = y + 35

    -- Activar Salto Infinito
    local infJumpToggle = createToggle("♾️ Activar Salto Infinito", "Salta en el aire infinitamente", function()
        CONFIG.InfiniteJump = not CONFIG.InfiniteJump
        SetupInfiniteJump()
    end, y, false)
    y = y + 45

    -- Activar Velocidad
    local speedToggle = createToggle("💨 Activar Velocidad", "Aumenta la velocidad de movimiento", function()
        CONFIG.Speed = not CONFIG.Speed
        ApplyMovementMods()
    end, y, false)
    y = y + 45

    -- Slider de Velocidad (valor numérico)
    local speedFrame = Instance.new("Frame")
    speedFrame.Size = UDim2.new(1, -10, 0, 30)
    speedFrame.Position = UDim2.new(0, 5, 0, y)
    speedFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    speedFrame.BackgroundTransparency = 0.3
    speedFrame.BorderSizePixel = 1
    speedFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
    speedFrame.Parent = scroll
    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 6)
    speedCorner.Parent = speedFrame

    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.5, 0, 1, 0)
    speedLabel.Position = UDim2.new(0, 5, 0, 0)
    speedLabel.Text = "Velocidad"
    speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 12
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = speedFrame

    local speedBox = Instance.new("TextBox")
    speedBox.Size = UDim2.new(0.2, 0, 0.6, 0)
    speedBox.Position = UDim2.new(0.75, 0, 0.2, 0)
    speedBox.Text = tostring(CONFIG.SpeedValue)
    speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    speedBox.BorderSizePixel = 1
    speedBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
    speedBox.Font = Enum.Font.GothamBold
    speedBox.TextSize = 14
    speedBox.Parent = speedFrame
    speedBox.FocusLost:Connect(function()
        local val = tonumber(speedBox.Text) or 16
        CONFIG.SpeedValue = math.clamp(val, 16, 200)
        speedBox.Text = tostring(CONFIG.SpeedValue)
        if CONFIG.Speed then ApplyMovementMods() end
    end)

    y = y + 45

    -- Actualizar canvas size
    scroll.CanvasSize = UDim2.new(0, 0, 0, y + 30)

    -- ===== ANIMACIÓN DE PANEL =====
    local function togglePanel(open)
        UI_OPEN = open
        local targetPos = open and UDim2.new(0.5, -160, 0.5, -240) or UDim2.new(1.5, 0, 0.5, -240)
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(mainFrame, tweenInfo, {Position = targetPos})
        tween:Play()
        if open then mainFrame.Visible = true end
        tween.Completed:Connect(function()
            if not open then mainFrame.Visible = false end
        end)
    end

    toggleBtn.MouseButton1Click:Connect(function()
        if mainFrame.Visible then
            togglePanel(false)
        else
            mainFrame.Visible = true
            togglePanel(true)
        end
    end)

    -- ===== KEYBIND PARA INVISIBLE =====
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = string.upper(input.KeyCode.Name)
            if key == CONFIG.InvisibleKey then
                CONFIG.Invisible = not CONFIG.Invisible
                ApplyGhostInvisibility(CONFIG.Invisible)
                -- Actualizar indicador visual en el toggle (si existe)
                -- No es necesario, pero se puede hacer
            end
        end
    end)

    -- ===== STATS EN EL PIE =====
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, 0, 0, 18)
    statsLabel.Position = UDim2.new(0, 0, 1, -20)
    statsLabel.Text = "Ronda: 0/5 | Bajas: 0"
    statsLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 10
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

-- ===================== EVENTOS Y BUCLE PRINCIPAL =====================
LocalPlayer.CharacterAdded:Connect(function(character)
    if CONFIG.Invisible then
        task.wait(0.2)
        ApplyGhostInvisibility(true)
    end
    task.wait(0.1)
    ApplyMovementMods()
    SetupInfiniteJump()

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

-- ===================== INICIALIZACIÓN =====================
CreateUI()
ApplyGhostInvisibility(false)
ApplyMovementMods()
SetupInfiniteJump()

RunService.RenderStepped:Connect(function()
    UpdateEsp()

    -- Aimbot Bannable (instantáneo)
    if CONFIG.AimbotBannable then
        local target = GetClosestEnemy()
        if target then
            MoveMouseTo(target, false)
        end
    end

    -- Aimbot Legit (suave)
    if CONFIG.AimbotLegit then
        local target = GetClosestEnemy()
        if target then
            MoveMouseTo(target, true)
        end
    end
end)

LocalPlayer.OnTeleport:Connect(ClearEsp)

print("🔥 DUELOS HACK v3.2.6 BETA CARGADO")
print("👤 Desarrollado por Vaxxzu")
print("📋 Menú estilo 'Murderers VS Sheriffs'")
print("🔑 Tecla para Invisible: " .. CONFIG.InvisibleKey)
print("⚡ Todas las opciones están DESACTIVADAS por defecto.")
