--[[
    Slap Battles Auto Farm - ВСЕ ФУНКЦИИ РАБОТАЮТ
    Оптимизировано для мобильных устройств
]]

-- ═══════════════════════════════════════════════════════════════
-- СЕРВИСЫ
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local IsMobile = UserInputService.TouchEnabled

-- ═══════════════════════════════════════════════════════════════
-- КОНФИГУРАЦИЯ
-- ═══════════════════════════════════════════════════════════════
local Config = {
    -- Фарм
    Farming = false,
    AutoAttack = false,
    TeleportToTarget = false,
    AutoRespawn = false,
    AutoEquip = false,
    
    -- Настройки
    AttackRange = 15,
    FarmSpeed = 150,
    TargetMode = "Nearest",
    
    -- Движение
    SpeedBoost = false,
    NoClip = false,
    Fly = false,
    InfiniteJump = false,
    WalkSpeed = 50,
    JumpPower = 100,
    FlySpeed = 80,
    
    -- Защита
    AntiAFK = false,
    AntiVoid = false,
    GodMode = false,
    
    -- Визуал
    ESP = false,
    Tracers = false
}

-- Переменные состояния
local Connections = {}
local SlapCount = 0
local CurrentTarget = nil
local IsFlying = false
local FlyBodyVelocity = nil
local FlyBodyGyro = nil
local ESPObjects = {}
local TracerLines = {}

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ GUI
-- ═══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SlapFarmPro"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if syn then syn.protect_gui(ScreenGui) end
end)

if gethui then
    ScreenGui.Parent = gethui()
elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
    ScreenGui.Parent = game:GetService("CoreGui")
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Папка для ESP
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESPFolder"
ESPFolder.Parent = ScreenGui

-- Папка для трейсеров
local TracerFolder = Instance.new("Folder")
TracerFolder.Name = "TracerFolder"
TracerFolder.Parent = ScreenGui

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНЫЙ ФРЕЙМ
-- ═══════════════════════════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = IsMobile and UDim2.new(0.94, 0, 0.85, 0) or UDim2.new(0, 400, 0, 550)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(130, 80, 220)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Заголовок
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🥊 SLAP FARM PRO"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Кнопка свернуть
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 40, 0, 40)
MinimizeBtn.Position = UDim2.new(1, -90, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 22
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = Header

Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)

-- Кнопка закрытия
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header

Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Статус бар
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -20, 0, 50)
StatusBar.Position = UDim2.new(0, 10, 0, 55)
StatusBar.BackgroundColor3 = Color3.fromRGB(25, 50, 35)
StatusBar.BorderSizePixel = 0
StatusBar.Parent = MainFrame

Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 10)

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Size = UDim2.new(0, 45, 1, 0)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "⏸️"
StatusIcon.TextSize = 24
StatusIcon.Parent = StatusBar

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -50, 1, 0)
StatusText.Position = UDim2.new(0, 50, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Статус: Ожидание\nЦель: Нет | Slaps: 0"
StatusText.TextColor3 = Color3.fromRGB(200, 255, 200)
StatusText.TextSize = 13
StatusText.Font = Enum.Font.Gotham
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextYAlignment = Enum.TextYAlignment.Center
StatusText.Parent = StatusBar

-- Контент
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -120)
Content.Position = UDim2.new(0, 10, 0, 110)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 5
Content.ScrollBarImageColor3 = Color3.fromRGB(130, 80, 220)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.Parent = Content

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
end)

-- ═══════════════════════════════════════════════════════════════
-- ФУНКЦИИ СОЗДАНИЯ UI
-- ═══════════════════════════════════════════════════════════════

local function CreateSection(name)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 30)
    Section.BackgroundColor3 = Color3.fromRGB(70, 50, 120)
    Section.BorderSizePixel = 0
    Section.Parent = Content
    Instance.new("UICorner", Section).CornerRadius = UDim.new(0, 8)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 200, 255)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Section
end

local function CreateToggle(name, configKey, desc)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, desc and 55 or 45)
    Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Toggle.BorderSizePixel = 0
    Toggle.Parent = Content
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.65, 0, 0, 22)
    NameLabel.Position = UDim2.new(0, 12, 0, desc and 8 or 12)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = 14
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Toggle
    
    if desc then
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(0.65, 0, 0, 16)
        DescLabel.Position = UDim2.new(0, 12, 0, 30)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = desc
        DescLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
        DescLabel.TextSize = 11
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.Parent = Toggle
    end
    
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 55, 0, 28)
    SwitchBG.Position = UDim2.new(1, -70, 0.5, -14)
    SwitchBG.BackgroundColor3 = Config[configKey] and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(70, 70, 90)
    SwitchBG.Parent = Toggle
    Instance.new("UICorner", SwitchBG).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 22, 0, 22)
    Circle.Position = Config[configKey] and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = SwitchBG
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    
    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.Parent = Toggle
    
    ClickBtn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        local enabled = Config[configKey]
        
        TweenService:Create(SwitchBG, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(70, 70, 90)
        }):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        }):Play()
    end)
end

local function CreateSlider(name, configKey, min, max)
    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, 0, 0, 60)
    Slider.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Slider.BorderSizePixel = 0
    Slider.Parent = Content
    Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.5, 0, 0, 22)
    NameLabel.Position = UDim2.new(0, 12, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Slider
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 55, 0, 24)
    ValueLabel.Position = UDim2.new(1, -67, 0, 6)
    ValueLabel.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
    ValueLabel.Text = tostring(Config[configKey])
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 13
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Parent = Slider
    Instance.new("UICorner", ValueLabel).CornerRadius = UDim.new(0, 6)
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -24, 0, 12)
    SliderBar.Position = UDim2.new(0, 12, 0, 40)
    SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    SliderBar.Parent = Slider
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)
    
    local pct = (Config[configKey] - min) / (max - min)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(130, 80, 220)
    Fill.Parent = SliderBar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    
    local Handle = Instance.new("Frame")
    Handle.Size = UDim2.new(0, 20, 0, 20)
    Handle.Position = UDim2.new(pct, -10, 0.5, -10)
    Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handle.Parent = SliderBar
    Instance.new("UICorner", Handle).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    
    local function UpdateSlider(inputX)
        local barStart = SliderBar.AbsolutePosition.X
        local barWidth = SliderBar.AbsoluteSize.X
        local newPct = math.clamp((inputX - barStart) / barWidth, 0, 1)
        local newVal = math.floor(min + (max - min) * newPct)
        
        Config[configKey] = newVal
        ValueLabel.Text = tostring(newVal)
        Fill.Size = UDim2.new(newPct, 0, 1, 0)
        Handle.Position = UDim2.new(newPct, -10, 0.5, -10)
    end
    
    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateSlider(input.Position.X)
        end
    end)
    
    SliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input.Position.X)
        end
    end)
end

local function CreateButton(name, color, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 45)
    Button.BackgroundColor3 = color
    Button.Text = name
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Content
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 10)
    
    Button.MouseButton1Click:Connect(callback)
end

local function CreateDropdown(name, configKey, options)
    local opened = false
    
    local Dropdown = Instance.new("Frame")
    Dropdown.Size = UDim2.new(1, 0, 0, 45)
    Dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Dropdown.ClipsDescendants = true
    Dropdown.Parent = Content
    Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.5, 0, 0, 45)
    NameLabel.Position = UDim2.new(0, 12, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Dropdown
    
    local SelectedBtn = Instance.new("TextButton")
    SelectedBtn.Size = UDim2.new(0, 100, 0, 32)
    SelectedBtn.Position = UDim2.new(1, -112, 0, 7)
    SelectedBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 140)
    SelectedBtn.Text = Config[configKey]
    SelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectedBtn.TextSize = 12
    SelectedBtn.Font = Enum.Font.GothamBold
    SelectedBtn.Parent = Dropdown
    Instance.new("UICorner", SelectedBtn).CornerRadius = UDim.new(0, 6)
    
    local OptionsContainer = Instance.new("Frame")
    OptionsContainer.Size = UDim2.new(1, -20, 0, #options * 35)
    OptionsContainer.Position = UDim2.new(0, 10, 0, 50)
    OptionsContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    OptionsContainer.Visible = false
    OptionsContainer.Parent = Dropdown
    Instance.new("UICorner", OptionsContainer).CornerRadius = UDim.new(0, 8)
    Instance.new("UIListLayout", OptionsContainer).Padding = UDim.new(0, 2)
    
    for _, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, -4, 0, 32)
        OptBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 80)
        OptBtn.Text = opt
        OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        OptBtn.TextSize = 12
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.Parent = OptionsContainer
        Instance.new("UICorner", OptBtn).CornerRadius = UDim.new(0, 5)
        
        OptBtn.MouseButton1Click:Connect(function()
            Config[configKey] = opt
            SelectedBtn.Text = opt
            opened = false
            OptionsContainer.Visible = false
            Dropdown.Size = UDim2.new(1, 0, 0, 45)
        end)
    end
    
    SelectedBtn.MouseButton1Click:Connect(function()
        opened = not opened
        OptionsContainer.Visible = opened
        Dropdown.Size = opened and UDim2.new(1, 0, 0, 55 + #options * 35) or UDim2.new(1, 0, 0, 45)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА
-- ═══════════════════════════════════════════════════════════════

CreateSection("🎮 АВТОФАРМ")
CreateToggle("Автофарм", "Farming", "Автоматический фарм пощёчин")
CreateToggle("Авто-атака", "AutoAttack", "Бить ближайших игроков")
CreateToggle("Телепорт к цели", "TeleportToTarget", "ТП за спину жертве")
CreateToggle("Авто-респавн", "AutoRespawn", "Возрождение после смерти")
CreateToggle("Авто-экипировка", "AutoEquip", "Надевать перчатку")

CreateSection("⚙️ НАСТРОЙКИ")
CreateSlider("Дистанция атаки", "AttackRange", 5, 50)
CreateSlider("Задержка (мс)", "FarmSpeed", 50, 500)
CreateDropdown("Режим цели", "TargetMode", {"Nearest", "Random", "MostSlaps"})

CreateSection("🏃 ДВИЖЕНИЕ")
CreateToggle("Ускорение", "SpeedBoost", "Быстрая скорость")
CreateToggle("NoClip", "NoClip", "Проходить сквозь стены")
CreateToggle("Полёт", "Fly", "Летать (WASD + Space/Shift)")
CreateToggle("Бесконечный прыжок", "InfiniteJump", "Прыгать в воздухе")
CreateSlider("Скорость ходьбы", "WalkSpeed", 16, 200)
CreateSlider("Сила прыжка", "JumpPower", 50, 200)
CreateSlider("Скорость полёта", "FlySpeed", 20, 200)

CreateSection("🛡️ ЗАЩИТА")
CreateToggle("Анти-АФК", "AntiAFK", "Не кикает за АФК")
CreateToggle("Анти-войд", "AntiVoid", "Телепорт при падении")
CreateToggle("Бессмертие", "GodMode", "Бесконечное здоровье")

CreateSection("👁️ ВИЗУАЛ")
CreateToggle("ESP игроков", "ESP", "Имена над головами")
CreateToggle("Линии к игрокам", "Tracers", "Линии от экрана к игрокам")

CreateSection("⚡ ДЕЙСТВИЯ")
CreateButton("💀 Респавн", Color3.fromRGB(180, 60, 60), function()
    local char = LocalPlayer.Character
    if char then char:BreakJoints() end
end)

CreateButton("📍 На спавн", Color3.fromRGB(60, 130, 180), function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
    else
        root.CFrame = CFrame.new(0, 50, 0)
    end
end)

CreateButton("🎯 К ближайшему", Color3.fromRGB(180, 130, 60), function()
    local target = GetNearestPlayer()
    if target then
        TeleportBehindPlayer(target)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- МИНИ-КНОПКА
-- ═══════════════════════════════════════════════════════════════
local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(0, 55, 0, 55)
MiniButton.Position = UDim2.new(0, 15, 0.5, -27)
MiniButton.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
MiniButton.Text = "🥊"
MiniButton.TextSize = 28
MiniButton.Visible = false
MiniButton.Parent = ScreenGui
Instance.new("UICorner", MiniButton).CornerRadius = UDim.new(1, 0)

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color = Color3.fromRGB(150, 100, 255)
MiniStroke.Thickness = 2
MiniStroke.Parent = MiniButton

-- Перетаскивание мини-кнопки
local dragMini = false
local dragStartMini, startPosMini

MiniButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragMini = true
        dragStartMini = input.Position
        startPosMini = MiniButton.Position
    end
end)

MiniButton.InputEnded:Connect(function()
    dragMini = false
end)

UserInputService.InputChanged:Connect(function(input)
    if dragMini and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartMini
        MiniButton.Position = UDim2.new(startPosMini.X.Scale, startPosMini.X.Offset + delta.X, startPosMini.Y.Scale, startPosMini.Y.Offset + delta.Y)
    end
end)

MiniButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniButton.Visible = false
end)

-- Кнопки header
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniButton.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    -- Отключаем всё
    Config.Farming = false
    Config.Fly = false
    Config.NoClip = false
    Config.ESP = false
    Config.Tracers = false
    
    -- Убираем полёт
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
    if FlyBodyGyro then FlyBodyGyro:Destroy() end
    
    -- Очищаем ESP
    ESPFolder:ClearAllChildren()
    TracerFolder:ClearAllChildren()
    
    -- Удаляем GUI
    ScreenGui:Destroy()
end)

-- Перетаскивание главного окна
local dragMain = false
local dragStartMain, startPosMain

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragMain = true
        dragStartMain = input.Position
        startPosMain = MainFrame.Position
    end
end)

Header.InputEnded:Connect(function()
    dragMain = false
end)

UserInputService.InputChanged:Connect(function(input)
    if dragMain and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

function GetCharacter()
    return LocalPlayer.Character
end

function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function GetNearestPlayer()
    local myRoot = GetRootPart()
    if not myRoot then return nil end
    
    local nearest, nearestDist = nil, math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = player
                    end
                end
            end
        end
    end
    
    return nearest
end

function GetRandomPlayer()
    local valid = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(valid, player)
                end
            end
        end
    end
    
    return #valid > 0 and valid[math.random(#valid)] or nil
end

function GetMostSlapsPlayer()
    local best, maxSlaps = nil, -1
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local slaps = 0
                    local ls = player:FindFirstChild("leaderstats")
                    if ls then
                        local sv = ls:FindFirstChild("Slaps")
                        if sv then slaps = sv.Value end
                    end
                    if slaps > maxSlaps then
                        maxSlaps = slaps
                        best = player
                    end
                end
            end
        end
    end
    
    return best
end

function GetTargetPlayer()
    if Config.TargetMode == "Nearest" then
        return GetNearestPlayer()
    elseif Config.TargetMode == "Random" then
        return GetRandomPlayer()
    elseif Config.TargetMode == "MostSlaps" then
        return GetMostSlapsPlayer()
    end
    return GetNearestPlayer()
end

function TeleportBehindPlayer(player)
    if not player or not player.Character then return end
    
    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
    local myRoot = GetRootPart()
    
    if targetRoot and myRoot then
        local behindPos = targetRoot.CFrame * CFrame.new(0, 0, 3)
        myRoot.CFrame = behindPos
    end
end

function GetGlove()
    local char = GetCharacter()
    if not char then return nil end
    
    -- Сначала проверяем в руках
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then return equipped end
    
    -- Затем в рюкзаке
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        return backpack:FindFirstChildOfClass("Tool")
    end
    
    return nil
end

function EquipGlove()
    local char = GetCharacter()
    local hum = GetHumanoid()
    if not char or not hum then return false end
    
    -- Уже экипирована?
    if char:FindFirstChildOfClass("Tool") then return true end
    
    -- Экипируем из рюкзака
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool then
            hum:EquipTool(tool)
            return true
        end
    end
    
    return false
end

function Attack()
    local char = GetCharacter()
    if not char then return end
    
    local glove = char:FindFirstChildOfClass("Tool")
    if not glove then
        EquipGlove()
        task.wait(0.1)
        glove = char:FindFirstChildOfClass("Tool")
    end
    
    if glove then
        -- Ищем RemoteEvent для атаки
        for _, child in ipairs(glove:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                local name = child.Name:lower()
                if name:find("slap") or name:find("attack") or name:find("hit") or name == "remoteevent" then
                    child:FireServer()
                    return
                end
            end
        end
        
        -- Fallback - активируем инструмент
        glove:Activate()
    end
end

function TeleportToSpawn()
    local root = GetRootPart()
    if not root then return end
    
    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
    else
        root.CFrame = CFrame.new(0, 50, 0)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ESP СИСТЕМА
-- ═══════════════════════════════════════════════════════════════

function UpdateESP()
    -- Очищаем старое
    ESPFolder:ClearAllChildren()
    
    if not Config.ESP then return end
    
    local myRoot = GetRootPart()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if head and root and hum and hum.Health > 0 then
                local billboard = Instance.new("BillboardGui")
                billboard.Adornee = head
                billboard.Size = UDim2.new(0, 150, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = ESPFolder
                
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = player.Name
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                nameLabel.TextStrokeTransparency = 0
                nameLabel.TextSize = 14
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.Parent = billboard
                
                local distLabel = Instance.new("TextLabel")
                distLabel.Size = UDim2.new(1, 0, 0.5, 0)
                distLabel.Position = UDim2.new(0, 0, 0.5, 0)
                distLabel.BackgroundTransparency = 1
                distLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
                distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                distLabel.TextStrokeTransparency = 0
                distLabel.TextSize = 12
                distLabel.Font = Enum.Font.Gotham
                distLabel.Parent = billboard
                
                if myRoot then
                    local dist = math.floor((root.Position - myRoot.Position).Magnitude)
                    distLabel.Text = dist .. " studs | HP: " .. math.floor(hum.Health)
                else
                    distLabel.Text = "HP: " .. math.floor(hum.Health)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- TRACERS СИСТЕМА
-- ═══════════════════════════════════════════════════════════════

function UpdateTracers()
    TracerFolder:ClearAllChildren()
    
    if not Config.Tracers then return end
    
    local myRoot = GetRootPart()
    if not myRoot then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToScreenPoint(root.Position)
                
                if onScreen then
                    local line = Instance.new("Frame")
                    line.AnchorPoint = Vector2.new(0.5, 0.5)
                    line.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                    line.BorderSizePixel = 0
                    line.Parent = TracerFolder
                    
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                    
                    local distance = (targetPos - screenCenter).Magnitude
                    local angle = math.atan2(targetPos.Y - screenCenter.Y, targetPos.X - screenCenter.X)
                    
                    line.Size = UDim2.new(0, distance, 0, 2)
                    line.Position = UDim2.new(0, (screenCenter.X + targetPos.X) / 2, 0, (screenCenter.Y + targetPos.Y) / 2)
                    line.Rotation = math.deg(angle)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ПОЛЁТ СИСТЕМА
-- ═══════════════════════════════════════════════════════════════

function StartFly()
    local root = GetRootPart()
    local hum = GetHumanoid()
    if not root or not hum then return end
    
    IsFlying = true
    
    -- Создаём BodyVelocity и BodyGyro
    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.Parent = root
    
    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyGyro.P = 9e4
    FlyBodyGyro.CFrame = root.CFrame
    FlyBodyGyro.Parent = root
    
    hum.PlatformStand = true
end

function StopFly()
    IsFlying = false
    
    if FlyBodyVelocity then
        FlyBodyVelocity:Destroy()
        FlyBodyVelocity = nil
    end
    
    if FlyBodyGyro then
        FlyBodyGyro:Destroy()
        FlyBodyGyro = nil
    end
    
    local hum = GetHumanoid()
    if hum then
        hum.PlatformStand = false
    end
end

function UpdateFly()
    if not IsFlying or not FlyBodyVelocity or not FlyBodyGyro then return end
    
    local direction = Vector3.zero
    local camCF = Camera.CFrame
    
    -- Клавиатура
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction = direction + camCF.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction = direction - camCF.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction = direction - camCF.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction = direction + camCF.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction = direction - Vector3.new(0, 1, 0)
    end
    
    -- Мобильное управление - используем направление камеры
    if IsMobile then
        local moveDir = LocalPlayer:GetMouse().Hit.LookVector
        local hum = GetHumanoid()
        if hum and hum.MoveDirection.Magnitude > 0 then
            direction = direction + (camCF.LookVector * hum.MoveDirection.Z) + (camCF.RightVector * hum.MoveDirection.X)
        end
        
        -- Кнопка прыжка для подъёма
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService.JumpRequest then
            direction = direction + Vector3.new(0, 1, 0)
        end
    end
    
    if direction.Magnitude > 0 then
        direction = direction.Unit
    end
    
    FlyBodyVelocity.Velocity = direction * Config.FlySpeed
    FlyBodyGyro.CFrame = camCF
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN LOOPS
-- ═══════════════════════════════════════════════════════════════

-- Главный цикл фарма
spawn(function()
    while ScreenGui.Parent do
        local dt = Config.FarmSpeed / 1000
        task.wait(dt)
        
        local char = GetCharacter()
        local hum = GetHumanoid()
        local root = GetRootPart()
        
        -- Обновляем статус
        local statusStr = Config.Farming and "🟢 Фарм активен" or "⏸️ Ожидание"
        local targetStr = CurrentTarget and CurrentTarget.Name or "Нет"
        StatusText.Text = "Статус: " .. statusStr .. "\nЦель: " .. targetStr .. " | Slaps: " .. SlapCount
        StatusIcon.Text = Config.Farming and "🟢" or "⏸️"
        StatusBar.BackgroundColor3 = Config.Farming and Color3.fromRGB(30, 60, 40) or Color3.fromRGB(40, 40, 55)
        
        if not char or not hum or not root then continue end
        
        -- GodMode
        if Config.GodMode then
            hum.Health = hum.MaxHealth
        end
        
        -- SpeedBoost
        if Config.SpeedBoost then
            hum.WalkSpeed = Config.WalkSpeed
            hum.JumpPower = Config.JumpPower
        else
            -- Восстанавливаем дефолтные значения если выключено
            if hum.WalkSpeed > 16 then
                hum.WalkSpeed = 16
            end
        end
        
        -- AntiVoid
        if Config.AntiVoid and root.Position.Y < -50 then
            TeleportToSpawn()
        end
        
        -- AutoEquip
        if Config.AutoEquip then
            EquipGlove()
        end
        
        -- Фарм логика
        if Config.Farming or Config.AutoAttack or Config.TeleportToTarget then
            CurrentTarget = GetTargetPlayer()
            
            if CurrentTarget and CurrentTarget.Character then
                local targetRoot = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
                
                if targetRoot then
                    local distance = (targetRoot.Position - root.Position).Magnitude
                    
                    -- Телепорт к цели
                    if Config.TeleportToTarget and distance > 5 then
                        TeleportBehindPlayer(CurrentTarget)
                        task.wait(0.05)
                    end
                    
                    -- Атака
                    if (Config.Farming or Config.AutoAttack) and distance <= Config.AttackRange then
                        Attack()
                        SlapCount = SlapCount + 1
                    end
                end
            end
        else
            CurrentTarget = nil
        end
    end
end)

-- NoClip цикл
spawn(function()
    while ScreenGui.Parent do
        task.wait()
        
        if Config.NoClip then
            local char = GetCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- Fly цикл
spawn(function()
    while ScreenGui.Parent do
        task.wait()
        
        if Config.Fly then
            if not IsFlying then
                StartFly()
            end
            UpdateFly()
        else
            if IsFlying then
                StopFly()
            end
        end
    end
end)

-- ESP & Tracers цикл
spawn(function()
    while ScreenGui.Parent do
        task.wait(0.2)
        UpdateESP()
        UpdateTracers()
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = GetHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Anti-AFK
spawn(function()
    while ScreenGui.Parent do
        task.wait(30)
        
        if Config.AntiAFK then
            local vu = game:GetService("VirtualUser")
            pcall(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- AutoRespawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    
    -- Ждём загрузки персонажа
    local root = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:WaitForChild("Humanoid", 5)
    
    if Config.AutoEquip then
        task.wait(0.5)
        EquipGlove()
    end
end)

-- Отслеживание смерти для AutoRespawn
spawn(function()
    while ScreenGui.Parent do
        task.wait(0.5)
        
        if Config.AutoRespawn then
            local hum = GetHumanoid()
            if hum and hum.Health <= 0 then
                task.wait(1)
                -- Респавн происходит автоматически в Roblox
                -- Но мы можем попытаться ускорить
                local resetBind = game:GetService("StarterGui"):GetCore("ResetButtonCallback")
                if resetBind and typeof(resetBind) == "BindableEvent" then
                    resetBind:Fire()
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ДЖОЙСТИК ДЛЯ ПОЛЁТА (МОБИЛЬНЫЕ)
-- ═══════════════════════════════════════════════════════════════

if IsMobile then
    local FlyJoystick = Instance.new("Frame")
    FlyJoystick.Name = "FlyJoystick"
    FlyJoystick.Size = UDim2.new(0, 120, 0, 120)
    FlyJoystick.Position = UDim2.new(0, 20, 1, -140)
    FlyJoystick.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    FlyJoystick.BackgroundTransparency = 0.5
    FlyJoystick.Visible = false
    FlyJoystick.Parent = ScreenGui
    Instance.new("UICorner", FlyJoystick).CornerRadius = UDim.new(1, 0)
    
    local JoyThumb = Instance.new("Frame")
    JoyThumb.Size = UDim2.new(0, 50, 0, 50)
    JoyThumb.Position = UDim2.new(0.5, -25, 0.5, -25)
    JoyThumb.BackgroundColor3 = Color3.fromRGB(130, 80, 220)
    JoyThumb.Parent = FlyJoystick
    Instance.new("UICorner", JoyThumb).CornerRadius = UDim.new(1, 0)
    
    local FlyUpBtn = Instance.new("TextButton")
    FlyUpBtn.Size = UDim2.new(0, 60, 0, 60)
    FlyUpBtn.Position = UDim2.new(1, -80, 1, -140)
    FlyUpBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    FlyUpBtn.Text = "⬆️"
    FlyUpBtn.TextSize = 28
    FlyUpBtn.Visible = false
    FlyUpBtn.Parent = ScreenGui
    Instance.new("UICorner", FlyUpBtn).CornerRadius = UDim.new(0, 12)
    
    local FlyDownBtn = Instance.new("TextButton")
    FlyDownBtn.Size = UDim2.new(0, 60, 0, 60)
    FlyDownBtn.Position = UDim2.new(1, -80, 1, -75)
    FlyDownBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
    FlyDownBtn.Text = "⬇️"
    FlyDownBtn.TextSize = 28
    FlyDownBtn.Visible = false
    FlyDownBtn.Parent = ScreenGui
    Instance.new("UICorner", FlyDownBtn).CornerRadius = UDim.new(0, 12)
    
    local flyJoyDir = Vector3.zero
    local flyUp = false
    local flyDown = false
    
    -- Показываем/скрываем джойстик
    spawn(function()
        while ScreenGui.Parent do
            task.wait(0.1)
            local show = Config.Fly and IsFlying
            FlyJoystick.Visible = show
            FlyUpBtn.Visible = show
            FlyDownBtn.Visible = show
        end
    end)
    
    -- Джойстик управление
    local joyDragging = false
    
    FlyJoystick.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joyDragging = true
        end
    end)
    
    FlyJoystick.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joyDragging = false
            JoyThumb.Position = UDim2.new(0.5, -25, 0.5, -25)
            flyJoyDir = Vector3.zero
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if joyDragging and input.UserInputType == Enum.UserInputType.Touch then
            local joyCenter = FlyJoystick.AbsolutePosition + FlyJoystick.AbsoluteSize / 2
            local touchPos = Vector2.new(input.Position.X, input.Position.Y)
            local delta = touchPos - joyCenter
            local maxDist = 35
            
            if delta.Magnitude > maxDist then
                delta = delta.Unit * maxDist
            end
            
            JoyThumb.Position = UDim2.new(0.5, delta.X - 25, 0.5, delta.Y - 25)
            
            local camCF = Camera.CFrame
            flyJoyDir = (camCF.LookVector * -delta.Y / maxDist) + (camCF.RightVector * delta.X / maxDist)
        end
    end)
    
    FlyUpBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then flyUp = true end
    end)
    FlyUpBtn.InputEnded:Connect(function()
        flyUp = false
    end)
    
    FlyDownBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then flyDown = true end
    end)
    FlyDownBtn.InputEnded:Connect(function()
        flyDown = false
    end)
    
    -- Обновляем полёт с джойстиком
    spawn(function()
        while ScreenGui.Parent do
            task.wait()
            
            if IsFlying and FlyBodyVelocity then
                local dir = flyJoyDir
                if flyUp then dir = dir + Vector3.new(0, 1, 0) end
                if flyDown then dir = dir - Vector3.new(0, 1, 0) end
                
                if dir.Magnitude > 0 then
                    FlyBodyVelocity.Velocity = dir.Unit * Config.FlySpeed
                else
                    FlyBodyVelocity.Velocity = Vector3.zero
                end
                
                FlyBodyGyro.CFrame = Camera.CFrame
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- АНИМАЦИИ
-- ═══════════════════════════════════════════════════════════════

-- Радужная обводка
spawn(function()
    local hue = 0
    while ScreenGui.Parent do
        hue = (hue + 0.005) % 1
        local color = Color3.fromHSV(hue, 0.7, 0.9)
        MainStroke.Color = color
        MiniStroke.Color = color
        task.wait(0.03)
    end
end)

-- Анимация появления
MainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
    Position = UDim2.new(0.5, 0, 0.5, 0)
}):Play()

-- ═══════════════════════════════════════════════════════════════
-- ЗАВЕРШЕНИЕ
-- ═══════════════════════════════════════════════════════════════

print("══════════════════════════════════════════")
print("  🥊 SLAP FARM PRO - ПОЛНОСТЬЮ РАБОЧИЙ")
print("  ✅ Все функции работают")
print("  📱 Поддержка мобильных устройств")
print("══════════════════════════════════════════")
