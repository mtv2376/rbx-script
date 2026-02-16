--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║           SLAP BATTLES ULTIMATE v3.0                         ║
    ║           Полная версия с выбором цели                       ║
    ║           + Улучшенный GUI + Анимации                        ║
    ╚═══════════════════════════════════════════════════════════════╝
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
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

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
    
    -- Агрессия
    AggressionMode = false,
    AggroSpeed = 30,
    AggroRange = 100,
    AggroSwitchOnFall = true,
    SelectedTarget = nil,
    TargetLock = false,
    
    -- Настройки
    AttackRange = 15,
    FarmSpeed = 150,
    TargetMode = "Nearest",
    
    -- Движение
    SpeedBoost = false,
    NoClip = false,
    Fly = false,
    InfiniteJump = false,
    SpinBot = false,
    WalkSpeed = 50,
    JumpPower = 100,
    FlySpeed = 80,
    SpinSpeed = 20,
    
    -- Защита
    AntiAFK = false,
    AntiVoid = false,
    GodMode = false,
    
    -- Визуал
    ESP = false,
    HighlightESP = false,
    Tracers = false,
    TargetInfo = false,
    CameraLock = false,
    ESPColor = Color3.fromRGB(255, 50, 50),
    
    -- Кастомизация
    Theme = "Purple",
    Notifications = true,
    SoundEffects = true,
    
    -- Whitelist/Blacklist
    Whitelist = {},
    Blacklist = {}
}

-- Темы
local Themes = {
    Purple = {
        Primary = Color3.fromRGB(130, 80, 220),
        Secondary = Color3.fromRGB(100, 50, 180),
        Background = Color3.fromRGB(18, 18, 28),
        Card = Color3.fromRGB(28, 28, 42),
        Text = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(180, 130, 255)
    },
    Red = {
        Primary = Color3.fromRGB(220, 60, 60),
        Secondary = Color3.fromRGB(180, 40, 40),
        Background = Color3.fromRGB(28, 18, 18),
        Card = Color3.fromRGB(42, 28, 28),
        Text = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(255, 130, 130)
    },
    Blue = {
        Primary = Color3.fromRGB(60, 120, 220),
        Secondary = Color3.fromRGB(40, 90, 180),
        Background = Color3.fromRGB(18, 22, 32),
        Card = Color3.fromRGB(28, 35, 50),
        Text = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(130, 180, 255)
    },
    Green = {
        Primary = Color3.fromRGB(60, 180, 80),
        Secondary = Color3.fromRGB(40, 140, 60),
        Background = Color3.fromRGB(18, 28, 20),
        Card = Color3.fromRGB(28, 42, 32),
        Text = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(130, 255, 150)
    },
    Gold = {
        Primary = Color3.fromRGB(220, 180, 60),
        Secondary = Color3.fromRGB(180, 140, 40),
        Background = Color3.fromRGB(28, 25, 18),
        Card = Color3.fromRGB(42, 38, 28),
        Text = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(255, 220, 130)
    }
}

-- Статистика сессии
local Stats = {
    TotalSlaps = 0,
    Kills = 0,
    Deaths = 0,
    SessionTime = 0,
    BestCombo = 0,
    CurrentCombo = 0,
    ComboTimer = 0
}

-- Состояние
local CurrentTarget = nil
local AggroCurrentTarget = nil
local IsFlying = false
local FlyBodyVelocity, FlyBodyGyro = nil, nil
local HighlightObjects = {}
local KillFeed = {}

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ GUI
-- ═══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SlapUltimate"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

pcall(function() if syn then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui")

-- Папки
local ESPFolder = Instance.new("Folder", ScreenGui)
ESPFolder.Name = "ESP"

local NotificationFolder = Instance.new("Frame")
NotificationFolder.Name = "Notifications"
NotificationFolder.Size = UDim2.new(0, 300, 1, 0)
NotificationFolder.Position = UDim2.new(1, -310, 0, 0)
NotificationFolder.BackgroundTransparency = 1
NotificationFolder.Parent = ScreenGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Parent = NotificationFolder

-- ═══════════════════════════════════════════════════════════════
-- ФУНКЦИЯ ПОЛУЧЕНИЯ ТЕМЫ
-- ═══════════════════════════════════════════════════════════════
local function GetTheme()
    return Themes[Config.Theme] or Themes.Purple
end

-- ═══════════════════════════════════════════════════════════════
-- СИСТЕМА УВЕДОМЛЕНИЙ
-- ═══════════════════════════════════════════════════════════════
local function Notify(title, message, duration, notifType)
    if not Config.Notifications then return end
    
    duration = duration or 3
    local theme = GetTheme()
    
    local colors = {
        info = theme.Primary,
        success = Color3.fromRGB(80, 200, 80),
        warning = Color3.fromRGB(220, 180, 60),
        error = Color3.fromRGB(220, 60, 60),
        kill = Color3.fromRGB(255, 50, 50)
    }
    
    local icons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌",
        kill = "💀"
    }
    
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 70)
    Notif.Position = UDim2.new(1, 50, 0, 0)
    Notif.BackgroundColor3 = theme.Card
    Notif.BorderSizePixel = 0
    Notif.Parent = NotificationFolder
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 10)
    
    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(0, 4, 1, 0)
    Accent.BackgroundColor3 = colors[notifType] or colors.info
    Accent.BorderSizePixel = 0
    Accent.Parent = Notif
    Instance.new("UICorner", Accent).CornerRadius = UDim.new(0, 10)
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 40, 0, 40)
    Icon.Position = UDim2.new(0, 15, 0.5, -20)
    Icon.BackgroundTransparency = 1
    Icon.Text = icons[notifType] or "ℹ️"
    Icon.TextSize = 24
    Icon.Parent = Notif
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -70, 0, 25)
    TitleLabel.Position = UDim2.new(0, 60, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = theme.Text
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Notif
    
    local MsgLabel = Instance.new("TextLabel")
    MsgLabel.Size = UDim2.new(1, -70, 0, 25)
    MsgLabel.Position = UDim2.new(0, 60, 0, 35)
    MsgLabel.BackgroundTransparency = 1
    MsgLabel.Text = message
    MsgLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    MsgLabel.TextSize = 12
    MsgLabel.Font = Enum.Font.Gotham
    MsgLabel.TextXAlignment = Enum.TextXAlignment.Left
    MsgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    MsgLabel.Parent = Notif
    
    -- Анимация появления
    TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    -- Анимация исчезновения
    task.delay(duration, function()
        TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, 50, 0, 0)
        }):Play()
        task.wait(0.3)
        Notif:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНЫЙ ФРЕЙМ
-- ═══════════════════════════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = IsMobile and UDim2.new(0.95, 0, 0.9, 0) or UDim2.new(0, 500, 0, 650)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = GetTheme().Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = GetTheme().Primary
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Градиент фона
local BGGradient = Instance.new("UIGradient")
BGGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 25, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
})
BGGradient.Rotation = 45
BGGradient.Parent = MainFrame

-- ═══════════════════════════════════════════════════════════════
-- HEADER
-- ═══════════════════════════════════════════════════════════════
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = GetTheme().Card
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, GetTheme().Primary),
    ColorSequenceKeypoint.new(1, GetTheme().Secondary)
})
HeaderGradient.Parent = Header

Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)

-- Фикс углов
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 20)
HeaderFix.Position = UDim2.new(0, 0, 1, -20)
HeaderFix.BackgroundColor3 = GetTheme().Primary
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Логотип
local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, 50, 0, 50)
Logo.Position = UDim2.new(0, 10, 0.5, -25)
Logo.BackgroundTransparency = 1
Logo.Text = "🥊"
Logo.TextSize = 35
Logo.Parent = Header

-- Название
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 0, 30)
Title.Position = UDim2.new(0, 65, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "SLAP ULTIMATE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 200, 0, 20)
Subtitle.Position = UDim2.new(0, 65, 0, 35)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "v3.0 Ultimate Edition"
Subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Кнопки управления
local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(0, 130, 0, 40)
BtnContainer.Position = UDim2.new(1, -140, 0.5, -20)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = Header

local BtnLayout = Instance.new("UIListLayout")
BtnLayout.FillDirection = Enum.FillDirection.Horizontal
BtnLayout.Padding = UDim.new(0, 8)
BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
BtnLayout.Parent = BtnContainer

local function CreateHeaderBtn(icon, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 38, 0, 38)
    Btn.BackgroundColor3 = color
    Btn.Text = icon
    Btn.TextSize = 18
    Btn.Font = Enum.Font.GothamBold
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Parent = BtnContainer
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
    
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 42, 0, 42)}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 38, 0, 38)}):Play()
    end)
    Btn.MouseButton1Click:Connect(callback)
    
    return Btn
end

local MinBtn = CreateHeaderBtn("—", Color3.fromRGB(80, 80, 120), function() end)
local CloseBtn = CreateHeaderBtn("✕", Color3.fromRGB(200, 60, 60), function() end)

-- ═══════════════════════════════════════════════════════════════
-- TABS
-- ═══════════════════════════════════════════════════════════════
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 0, 45)
TabContainer.Position = UDim2.new(0, 10, 0, 65)
TabContainer.BackgroundColor3 = GetTheme().Card
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame
Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 10)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 5)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent = TabContainer

local Tabs = {
    {Name = "🎮", FullName = "Фарм"},
    {Name = "💀", FullName = "Агрессия"},
    {Name = "👥", FullName = "Игроки"},
    {Name = "🏃", FullName = "Движение"},
    {Name = "👁️", FullName = "Визуал"},
    {Name = "⚙️", FullName = "Настройки"}
}

local TabButtons = {}
local TabContents = {}
local CurrentTab = 1

-- Контейнер контента
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -180)
ContentContainer.Position = UDim2.new(0, 10, 0, 115)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ClipsDescendants = true
ContentContainer.Parent = MainFrame

-- Создание табов
for i, tab in ipairs(Tabs) do
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, IsMobile and 45 or 70, 0, 35)
    TabBtn.BackgroundColor3 = i == 1 and GetTheme().Primary or Color3.fromRGB(50, 50, 70)
    TabBtn.Text = IsMobile and tab.Name or (tab.Name .. " " .. tab.FullName)
    TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabBtn.TextSize = IsMobile and 16 or 12
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.Parent = TabContainer
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)
    
    TabButtons[i] = TabBtn
    
    -- Контент таба
    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, 0, 1, 0)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = GetTheme().Primary
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.Visible = i == 1
    Content.Parent = ContentContainer
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
    Layout.Parent = Content
    
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
    end)
    
    TabContents[i] = Content
    
    TabBtn.MouseButton1Click:Connect(function()
        for j, btn in ipairs(TabButtons) do
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = j == i and GetTheme().Primary or Color3.fromRGB(50, 50, 70)
            }):Play()
            TabContents[j].Visible = j == i
        end
        CurrentTab = i
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- СТАТУС БАР (ВНИЗУ)
-- ═══════════════════════════════════════════════════════════════
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -20, 0, 55)
StatusBar.Position = UDim2.new(0, 10, 1, -60)
StatusBar.BackgroundColor3 = GetTheme().Card
StatusBar.BorderSizePixel = 0
StatusBar.Parent = MainFrame
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 10)

local StatusGrid = Instance.new("Frame")
StatusGrid.Size = UDim2.new(1, -20, 1, -10)
StatusGrid.Position = UDim2.new(0, 10, 0, 5)
StatusGrid.BackgroundTransparency = 1
StatusGrid.Parent = StatusBar

local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0.25, -5, 1, 0)
GridLayout.CellPadding = UDim2.new(0, 5, 0, 0)
GridLayout.Parent = StatusGrid

local function CreateStatBox(icon, valueName, defaultValue)
    local Box = Instance.new("Frame")
    Box.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    Box.BorderSizePixel = 0
    Box.Parent = StatusGrid
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 8)
    
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Size = UDim2.new(1, 0, 0.5, 0)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = icon
    IconLabel.TextSize = 16
    IconLabel.Parent = Box
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = valueName
    ValueLabel.Size = UDim2.new(1, 0, 0.5, 0)
    ValueLabel.Position = UDim2.new(0, 0, 0.5, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = defaultValue
    ValueLabel.TextColor3 = GetTheme().Accent
    ValueLabel.TextSize = 14
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Parent = Box
    
    return ValueLabel
end

local SlapsLabel = CreateStatBox("🥊", "Slaps", "0")
local KillsLabel = CreateStatBox("💀", "Kills", "0")
local ComboLabel = CreateStatBox("🔥", "Combo", "0x")
local TargetLabel = CreateStatBox("🎯", "Target", "—")

-- ═══════════════════════════════════════════════════════════════
-- UI BUILDER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function CreateSection(parent, name, icon)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 35)
    Section.BackgroundColor3 = GetTheme().Primary
    Section.BorderSizePixel = 0
    Section.Parent = parent
    Instance.new("UICorner", Section).CornerRadius = UDim.new(0, 8)
    
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GetTheme().Primary),
        ColorSequenceKeypoint.new(1, GetTheme().Secondary)
    })
    Gradient.Parent = Section
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = (icon or "") .. " " .. name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Section
end

local function CreateToggle(parent, name, configKey, desc)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, desc and 58 or 48)
    Toggle.BackgroundColor3 = GetTheme().Card
    Toggle.BorderSizePixel = 0
    Toggle.Parent = parent
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.65, 0, 0, 24)
    NameLabel.Position = UDim2.new(0, 15, 0, desc and 8 or 12)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = GetTheme().Text
    NameLabel.TextSize = 14
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Toggle
    
    if desc then
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(0.65, 0, 0, 18)
        DescLabel.Position = UDim2.new(0, 15, 0, 32)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = desc
        DescLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
        DescLabel.TextSize = 11
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.Parent = Toggle
    end
    
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 55, 0, 28)
    SwitchBG.Position = UDim2.new(1, -70, 0.5, -14)
    SwitchBG.BackgroundColor3 = Config[configKey] and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 80)
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
            BackgroundColor3 = enabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Position = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        }):Play()
        
        -- Анимация фрейма
        TweenService:Create(Toggle, TweenInfo.new(0.1), {
            BackgroundColor3 = enabled and Color3.fromRGB(40, 50, 40) or GetTheme().Card
        }):Play()
        task.wait(0.1)
        TweenService:Create(Toggle, TweenInfo.new(0.2), {
            BackgroundColor3 = GetTheme().Card
        }):Play()
        
        if Config.SoundEffects then
            -- Звуковой эффект (если доступен)
        end
    end)
end

local function CreateSlider(parent, name, configKey, min, max)
    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, 0, 0, 65)
    Slider.BackgroundColor3 = GetTheme().Card
    Slider.BorderSizePixel = 0
    Slider.Parent = parent
    Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.5, 0, 0, 24)
    NameLabel.Position = UDim2.new(0, 15, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = GetTheme().Text
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Slider
    
    local ValueBG = Instance.new("Frame")
    ValueBG.Size = UDim2.new(0, 60, 0, 26)
    ValueBG.Position = UDim2.new(1, -75, 0, 6)
    ValueBG.BackgroundColor3 = GetTheme().Primary
    ValueBG.Parent = Slider
    Instance.new("UICorner", ValueBG).CornerRadius = UDim.new(0, 6)
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(1, 0, 1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(Config[configKey])
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 13
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Parent = ValueBG
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -30, 0, 12)
    SliderBar.Position = UDim2.new(0, 15, 0, 42)
    SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    SliderBar.Parent = Slider
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)
    
    local pct = math.clamp((Config[configKey] - min) / (max - min), 0, 1)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = GetTheme().Primary
    Fill.Parent = SliderBar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    
    local FillGradient = Instance.new("UIGradient")
    FillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GetTheme().Primary),
        ColorSequenceKeypoint.new(1, GetTheme().Accent)
    })
    FillGradient.Parent = Fill
    
    local Handle = Instance.new("Frame")
    Handle.Size = UDim2.new(0, 20, 0, 20)
    Handle.Position = UDim2.new(pct, -10, 0.5, -10)
    Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handle.Parent = SliderBar
    Instance.new("UICorner", Handle).CornerRadius = UDim.new(1, 0)
    
    local HandleStroke = Instance.new("UIStroke")
    HandleStroke.Color = GetTheme().Primary
    HandleStroke.Thickness = 2
    HandleStroke.Parent = Handle
    
    local dragging = false
    
    local function Update(inputX)
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
            Update(input.Position.X)
        end
    end)
    
    SliderBar.InputEnded:Connect(function()
        dragging = false
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input.Position.X)
        end
    end)
end

local function CreateButton(parent, name, icon, color, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 48)
    Button.BackgroundColor3 = color or GetTheme().Primary
    Button.Text = ""
    Button.Parent = parent
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 10)
    
    local ButtonGradient = Instance.new("UIGradient")
    ButtonGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color or GetTheme().Primary),
        ColorSequenceKeypoint.new(1, Color3.new(
            (color or GetTheme().Primary).R * 0.7,
            (color or GetTheme().Primary).G * 0.7,
            (color or GetTheme().Primary).B * 0.7
        ))
    })
    ButtonGradient.Rotation = 90
    ButtonGradient.Parent = Button
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 40, 1, 0)
    Icon.Position = UDim2.new(0, 10, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = icon or ""
    Icon.TextSize = 20
    Icon.Parent = Button
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 50, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button
    
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {
            Size = UDim2.new(1, 0, 0, 52)
        }):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {
            Size = UDim2.new(1, 0, 0, 48)
        }):Play()
    end)
    
    Button.MouseButton1Click:Connect(function()
        -- Ripple эффект
        local Ripple = Instance.new("Frame")
        Ripple.Size = UDim2.new(0, 0, 0, 0)
        Ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        Ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        Ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Ripple.BackgroundTransparency = 0.7
        Ripple.Parent = Button
        Instance.new("UICorner", Ripple).CornerRadius = UDim.new(1, 0)
        
        TweenService:Create(Ripple, TweenInfo.new(0.4), {
            Size = UDim2.new(2, 0, 2, 0),
            BackgroundTransparency = 1
        }):Play()
        
        task.delay(0.4, function()
            Ripple:Destroy()
        end)
        
        callback()
    end)
end

local function CreateDropdown(parent, name, configKey, options)
    local opened = false
    
    local Dropdown = Instance.new("Frame")
    Dropdown.Size = UDim2.new(1, 0, 0, 48)
    Dropdown.BackgroundColor3 = GetTheme().Card
    Dropdown.ClipsDescendants = true
    Dropdown.Parent = parent
    Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.5, 0, 0, 48)
    NameLabel.Position = UDim2.new(0, 15, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = GetTheme().Text
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Dropdown
    
    local SelectedBtn = Instance.new("TextButton")
    SelectedBtn.Size = UDim2.new(0, 110, 0, 32)
    SelectedBtn.Position = UDim2.new(1, -125, 0, 8)
    SelectedBtn.BackgroundColor3 = GetTheme().Primary
    SelectedBtn.Text = Config[configKey] .. " ▼"
    SelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectedBtn.TextSize = 12
    SelectedBtn.Font = Enum.Font.GothamBold
    SelectedBtn.Parent = Dropdown
    Instance.new("UICorner", SelectedBtn).CornerRadius = UDim.new(0, 8)
    
    local OptionsContainer = Instance.new("Frame")
    OptionsContainer.Size = UDim2.new(1, -20, 0, #options * 38)
    OptionsContainer.Position = UDim2.new(0, 10, 0, 52)
    OptionsContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    OptionsContainer.Visible = false
    OptionsContainer.Parent = Dropdown
    Instance.new("UICorner", OptionsContainer).CornerRadius = UDim.new(0, 8)
    
    local OptLayout = Instance.new("UIListLayout")
    OptLayout.Padding = UDim.new(0, 3)
    OptLayout.Parent = OptionsContainer
    
    for _, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, -6, 0, 34)
        OptBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 80)
        OptBtn.Text = opt
        OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        OptBtn.TextSize = 12
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.Parent = OptionsContainer
        Instance.new("UICorner", OptBtn).CornerRadius = UDim.new(0, 6)
        
        OptBtn.MouseEnter:Connect(function()
            TweenService:Create(OptBtn, TweenInfo.new(0.1), {BackgroundColor3 = GetTheme().Primary}):Play()
        end)
        OptBtn.MouseLeave:Connect(function()
            TweenService:Create(OptBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(55, 55, 80)}):Play()
        end)
        
        OptBtn.MouseButton1Click:Connect(function()
            Config[configKey] = opt
            SelectedBtn.Text = opt .. " ▼"
            opened = false
            OptionsContainer.Visible = false
            TweenService:Create(Dropdown, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = UDim2.new(1, 0, 0, 48)
            }):Play()
        end)
    end
    
    SelectedBtn.MouseButton1Click:Connect(function()
        opened = not opened
        OptionsContainer.Visible = opened
        TweenService:Create(Dropdown, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = opened and UDim2.new(1, 0, 0, 58 + #options * 38) or UDim2.new(1, 0, 0, 48)
        }):Play()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ТАБ 1: ФАРМ
-- ═══════════════════════════════════════════════════════════════
CreateSection(TabContents[1], "ОСНОВНОЙ ФАРМ", "🎮")
CreateToggle(TabContents[1], "Автофарм", "Farming", "Автоматический фарм пощёчин")
CreateToggle(TabContents[1], "Авто-атака", "AutoAttack", "Бить ближайших игроков")
CreateToggle(TabContents[1], "Телепорт к цели", "TeleportToTarget", "ТП за спину жертве")
CreateToggle(TabContents[1], "Авто-респавн", "AutoRespawn", "Возрождение после смерти")
CreateToggle(TabContents[1], "Авто-экипировка", "AutoEquip", "Надевать перчатку")

CreateSection(TabContents[1], "НАСТРОЙКИ АТАКИ", "⚔️")
CreateSlider(TabContents[1], "Дистанция атаки", "AttackRange", 5, 50)
CreateSlider(TabContents[1], "Задержка (мс)", "FarmSpeed", 50, 500)
CreateDropdown(TabContents[1], "Режим цели", "TargetMode", {"Nearest", "Random", "MostSlaps", "LowestHP"})

-- ═══════════════════════════════════════════════════════════════
-- ТАБ 2: АГРЕССИЯ
-- ═══════════════════════════════════════════════════════════════
CreateSection(TabContents[2], "РЕЖИМ АГРЕССИИ", "💀")
CreateToggle(TabContents[2], "🔥 Режим агрессии", "AggressionMode", "Максимальная скорость атаки")
CreateToggle(TabContents[2], "🎯 Лок на цель", "TargetLock", "Не переключаться на других")
CreateToggle(TabContents[2], "Смена при падении", "AggroSwitchOnFall", "Новая цель когда враг упал")
CreateSlider(TabContents[2], "Скорость атаки (мс)", "AggroSpeed", 10, 200)
CreateSlider(TabContents[2], "Радиус поиска", "AggroRange", 20, 500)

CreateSection(TabContents[2], "БЫСТРЫЕ ДЕЙСТВИЯ", "⚡")
CreateButton(TabContents[2], "Убить ближайшего", "💀", Color3.fromRGB(200, 50, 50), function()
    local target = GetNearestPlayer()
    if target then
        Config.SelectedTarget = target
        Config.AggressionMode = true
        Notify("Агрессия", "Цель: " .. target.Name, 2, "kill")
    end
end)

CreateButton(TabContents[2], "Убить всех", "☠️", Color3.fromRGB(150, 30, 30), function()
    Config.SelectedTarget = nil
    Config.AggressionMode = true
    Notify("Агрессия", "Режим: все игроки", 2, "warning")
end)

CreateButton(TabContents[2], "Остановить", "🛑", Color3.fromRGB(100, 100, 100), function()
    Config.AggressionMode = false
    Config.SelectedTarget = nil
    Notify("Агрессия", "Остановлено", 2, "info")
end)

-- ═══════════════════════════════════════════════════════════════
-- ТАБ 3: СПИСОК ИГРОКОВ
-- ═══════════════════════════════════════════════════════════════

local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Size = UDim2.new(1, 0, 0, 300)
PlayerListFrame.BackgroundColor3 = GetTheme().Card
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.Parent = TabContents[3]
Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0, 10)

local PlayerListTitle = Instance.new("TextLabel")
PlayerListTitle.Size = UDim2.new(1, 0, 0, 35)
PlayerListTitle.BackgroundColor3 = GetTheme().Primary
PlayerListTitle.Text = "👥 ВЫБОР ЦЕЛИ"
PlayerListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerListTitle.TextSize = 14
PlayerListTitle.Font = Enum.Font.GothamBold
PlayerListTitle.Parent = PlayerListFrame
Instance.new("UICorner", PlayerListTitle).CornerRadius = UDim.new(0, 10)

local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Size = UDim2.new(1, -10, 1, -45)
PlayerScroll.Position = UDim2.new(0, 5, 0, 40)
PlayerScroll.BackgroundTransparency = 1
PlayerScroll.ScrollBarThickness = 4
PlayerScroll.ScrollBarImageColor3 = GetTheme().Primary
PlayerScroll.Parent = PlayerListFrame

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.Padding = UDim.new(0, 5)
PlayerLayout.Parent = PlayerScroll

local function RefreshPlayerList()
    for _, child in ipairs(PlayerScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local PlayerCard = Instance.new("Frame")
            PlayerCard.Size = UDim2.new(1, -10, 0, 60)
            PlayerCard.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
            PlayerCard.BorderSizePixel = 0
            PlayerCard.Parent = PlayerScroll
            Instance.new("UICorner", PlayerCard).CornerRadius = UDim.new(0, 8)
            
            -- Аватар
            local Avatar = Instance.new("ImageLabel")
            Avatar.Size = UDim2.new(0, 45, 0, 45)
            Avatar.Position = UDim2.new(0, 8, 0.5, -22)
            Avatar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            Avatar.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            Avatar.Parent = PlayerCard
            Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)
            
            -- Имя
            local NameLabel = Instance.new("TextLabel")
            NameLabel.Size = UDim2.new(0.5, -60, 0, 20)
            NameLabel.Position = UDim2.new(0, 60, 0, 10)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Text = player.Name
            NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            NameLabel.TextSize = 13
            NameLabel.Font = Enum.Font.GothamBold
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Parent = PlayerCard
            
            -- Статус
            local StatusLabel = Instance.new("TextLabel")
            StatusLabel.Size = UDim2.new(0.5, -60, 0, 16)
            StatusLabel.Position = UDim2.new(0, 60, 0, 32)
            StatusLabel.BackgroundTransparency = 1
            StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
            StatusLabel.TextSize = 11
            StatusLabel.Font = Enum.Font.Gotham
            StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
            StatusLabel.Parent = PlayerCard
            
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            StatusLabel.Text = hum and ("HP: " .. math.floor(hum.Health)) or "Мёртв"
            
            -- Кнопка выбора цели
            local TargetBtn = Instance.new("TextButton")
            TargetBtn.Size = UDim2.new(0, 70, 0, 35)
            TargetBtn.Position = UDim2.new(1, -80, 0.5, -17)
            TargetBtn.BackgroundColor3 = Config.SelectedTarget == player and Color3.fromRGB(200, 50, 50) or GetTheme().Primary
            TargetBtn.Text = Config.SelectedTarget == player and "✓" or "🎯"
            TargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            TargetBtn.TextSize = 16
            TargetBtn.Font = Enum.Font.GothamBold
            TargetBtn.Parent = PlayerCard
            Instance.new("UICorner", TargetBtn).CornerRadius = UDim.new(0, 8)
            
            TargetBtn.MouseButton1Click:Connect(function()
                if Config.SelectedTarget == player then
                    Config.SelectedTarget = nil
                    TargetBtn.Text = "🎯"
                    TargetBtn.BackgroundColor3 = GetTheme().Primary
                    Notify("Цель", "Цель снята", 2, "info")
                else
                    Config.SelectedTarget = player
                    RefreshPlayerList()
                    Notify("Цель", "Выбрана: " .. player.Name, 2, "success")
                end
            end)
            
            -- Whitelist кнопка
            local WLBtn = Instance.new("TextButton")
            WLBtn.Size = UDim2.new(0, 35, 0, 35)
            WLBtn.Position = UDim2.new(1, -120, 0.5, -17)
            WLBtn.BackgroundColor3 = Config.Whitelist[player.Name] and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 80)
            WLBtn.Text = "✓"
            WLBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            WLBtn.TextSize = 14
            WLBtn.Parent = PlayerCard
            Instance.new("UICorner", WLBtn).CornerRadius = UDim.new(0, 8)
            
            WLBtn.MouseButton1Click:Connect(function()
                Config.Whitelist[player.Name] = not Config.Whitelist[player.Name]
                WLBtn.BackgroundColor3 = Config.Whitelist[player.Name] and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 80)
                Notify("Whitelist", Config.Whitelist[player.Name] and (player.Name .. " добавлен") or (player.Name .. " удалён"), 2, "info")
            end)
        end
    end
    
    PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, PlayerLayout.AbsoluteContentSize.Y + 10)
end

CreateButton(TabContents[3], "🔄 Обновить список", "🔄", GetTheme().Secondary, RefreshPlayerList)

-- Обновляем при изменении игроков
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(RefreshPlayerList)
task.defer(RefreshPlayerList)

-- ═══════════════════════════════════════════════════════════════
-- ТАБ 4: ДВИЖЕНИЕ
-- ═══════════════════════════════════════════════════════════════
CreateSection(TabContents[4], "СКОРОСТЬ", "🏃")
CreateToggle(TabContents[4], "Ускорение", "SpeedBoost", "Быстрая скорость")
CreateSlider(TabContents[4], "Скорость ходьбы", "WalkSpeed", 16, 200)
CreateSlider(TabContents[4], "Сила прыжка", "JumpPower", 50, 200)

CreateSection(TabContents[4], "СПОСОБНОСТИ", "✨")
CreateToggle(TabContents[4], "NoClip", "NoClip", "Проходить сквозь стены")
CreateToggle(TabContents[4], "Полёт", "Fly", "Летать (WASD + Space/Shift)")
CreateToggle(TabContents[4], "Бесконечный прыжок", "InfiniteJump", "Прыгать в воздухе")
CreateToggle(TabContents[4], "🌀 SpinBot", "SpinBot", "Вращение персонажа")
CreateSlider(TabContents[4], "Скорость полёта", "FlySpeed", 20, 200)
CreateSlider(TabContents[4], "Скорость вращения", "SpinSpeed", 5, 50)

CreateSection(TabContents[4], "ЗАЩИТА", "🛡️")
CreateToggle(TabContents[4], "Анти-АФК", "AntiAFK", "Не кикает за АФК")
CreateToggle(TabContents[4], "Анти-войд", "AntiVoid", "Телепорт при падении")
CreateToggle(TabContents[4], "Бессмертие", "GodMode", "Бесконечное здоровье")

-- ═══════════════════════════════════════════════════════════════
-- ТАБ 5: ВИЗУАЛ
-- ═══════════════════════════════════════════════════════════════
CreateSection(TabContents[5], "ESP", "👁️")
CreateToggle(TabContents[5], "ESP (имена)", "ESP", "Имена над головами")
CreateToggle(TabContents[5], "✨ Highlight ESP", "HighlightESP", "Подсветка игроков")
CreateToggle(TabContents[5], "Линии (Tracers)", "Tracers", "Линии к игрокам")
CreateToggle(TabContents[5], "Инфо о цели", "TargetInfo", "Показывает данные цели")
CreateToggle(TabContents[5], "🎥 Camera Lock", "CameraLock", "Камера следит за целью")

CreateSection(TabContents[5], "ЦВЕТА", "🎨")

local ColorPicker = Instance.new("Frame")
ColorPicker.Size = UDim2.new(1, 0, 0, 55)
ColorPicker.BackgroundColor3 = GetTheme().Card
ColorPicker.Parent = TabContents[5]
Instance.new("UICorner", ColorPicker).CornerRadius = UDim.new(0, 10)

local CPLabel = Instance.new("TextLabel")
CPLabel.Size = UDim2.new(0.3, 0, 1, 0)
CPLabel.Position = UDim2.new(0, 15, 0, 0)
CPLabel.BackgroundTransparency = 1
CPLabel.Text = "Цвет ESP"
CPLabel.TextColor3 = GetTheme().Text
CPLabel.TextSize = 13
CPLabel.Font = Enum.Font.GothamBold
CPLabel.TextXAlignment = Enum.TextXAlignment.Left
CPLabel.Parent = ColorPicker

local ColorOptions = {
    {Color3.fromRGB(255, 50, 50), "🔴"},
    {Color3.fromRGB(50, 255, 50), "🟢"},
    {Color3.fromRGB(50, 150, 255), "🔵"},
    {Color3.fromRGB(255, 255, 50), "🟡"},
    {Color3.fromRGB(255, 50, 255), "🟣"},
    {Color3.fromRGB(50, 255, 255), "🔵"},
    {Color3.fromRGB(255, 150, 50), "🟠"},
    {Color3.fromRGB(255, 255, 255), "⚪"}
}

for i, colorData in ipairs(ColorOptions) do
    local ColorBtn = Instance.new("TextButton")
    ColorBtn.Size = UDim2.new(0, 35, 0, 35)
    ColorBtn.Position = UDim2.new(0, 100 + (i-1) * 40, 0.5, -17)
    ColorBtn.BackgroundColor3 = colorData[1]
    ColorBtn.Text = ""
    ColorBtn.Parent = ColorPicker
    Instance.new("UICorner", ColorBtn).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = Config.ESPColor == colorData[1] and 3 or 0
    stroke.Parent = ColorBtn
    
    ColorBtn.MouseButton1Click:Connect(function()
        Config.ESPColor = colorData[1]
        for _, child in ipairs(ColorPicker:GetChildren()) do
            if child:IsA("TextButton") then
                local s = child:FindFirstChildOfClass("UIStroke")
                if s then
                    TweenService:Create(s, TweenInfo.new(0.2), {
                        Thickness = child.BackgroundColor3 == colorData[1] and 3 or 0
                    }):Play()
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ТАБ 6: НАСТРОЙКИ
-- ═══════════════════════════════════════════════════════════════
CreateSection(TabContents[6], "ИНТЕРФЕЙС", "🎨")

-- Выбор темы
local ThemeFrame = Instance.new("Frame")
ThemeFrame.Size = UDim2.new(1, 0, 0, 55)
ThemeFrame.BackgroundColor3 = GetTheme().Card
ThemeFrame.Parent = TabContents[6]
Instance.new("UICorner", ThemeFrame).CornerRadius = UDim.new(0, 10)

local ThemeLabel = Instance.new("TextLabel")
ThemeLabel.Size = UDim2.new(0.3, 0, 1, 0)
ThemeLabel.Position = UDim2.new(0, 15, 0, 0)
ThemeLabel.BackgroundTransparency = 1
ThemeLabel.Text = "Тема"
ThemeLabel.TextColor3 = GetTheme().Text
ThemeLabel.TextSize = 13
ThemeLabel.Font = Enum.Font.GothamBold
ThemeLabel.TextXAlignment = Enum.TextXAlignment.Left
ThemeLabel.Parent = ThemeFrame

local ThemeOptions = {"Purple", "Red", "Blue", "Green", "Gold"}
for i, themeName in ipairs(ThemeOptions) do
    local ThemeBtn = Instance.new("TextButton")
    ThemeBtn.Size = UDim2.new(0, 45, 0, 35)
    ThemeBtn.Position = UDim2.new(0, 100 + (i-1) * 50, 0.5, -17)
    ThemeBtn.BackgroundColor3 = Themes[themeName].Primary
    ThemeBtn.Text = Config.Theme == themeName and "✓" or ""
    ThemeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ThemeBtn.TextSize = 16
    ThemeBtn.Font = Enum.Font.GothamBold
    ThemeBtn.Parent = ThemeFrame
    Instance.new("UICorner", ThemeBtn).CornerRadius = UDim.new(0, 8)
    
    ThemeBtn.MouseButton1Click:Connect(function()
        Config.Theme = themeName
        Notify("Тема", "Выбрана: " .. themeName, 2, "success")
        -- Обновление требует перезагрузки
    end)
end

CreateToggle(TabContents[6], "Уведомления", "Notifications", "Показывать уведомления")
CreateToggle(TabContents[6], "Звуковые эффекты", "SoundEffects", "Звуки при действиях")

CreateSection(TabContents[6], "ДЕЙСТВИЯ", "⚡")
CreateButton(TabContents[6], "Респавн", "💀", Color3.fromRGB(180, 60, 60), function()
    local char = LocalPlayer.Character
    if char then char:BreakJoints() end
end)

CreateButton(TabContents[6], "На спавн", "📍", Color3.fromRGB(60, 130, 180), function()
    TeleportToSpawn()
end)

CreateButton(TabContents[6], "Сбросить статистику", "🔄", Color3.fromRGB(100, 100, 150), function()
    Stats.TotalSlaps = 0
    Stats.Kills = 0
    Stats.CurrentCombo = 0
    Stats.BestCombo = 0
    Notify("Статистика", "Сброшена", 2, "info")
end)

CreateSection(TabContents[6], "ИНФОРМАЦИЯ", "ℹ️")

local InfoFrame = Instance.new("Frame")
InfoFrame.Size = UDim2.new(1, 0, 0, 80)
InfoFrame.BackgroundColor3 = GetTheme().Card
InfoFrame.Parent = TabContents[6]
Instance.new("UICorner", InfoFrame).CornerRadius = UDim.new(0, 10)

local InfoText = Instance.new("TextLabel")
InfoText.Size = UDim2.new(1, -20, 1, -10)
InfoText.Position = UDim2.new(0, 10, 0, 5)
InfoText.BackgroundTransparency = 1
InfoText.Text = "🥊 Slap Battles Ultimate v3.0\n\n👤 Made with ❤️\n📱 Поддержка мобильных устройств"
InfoText.TextColor3 = Color3.fromRGB(180, 180, 200)
InfoText.TextSize = 12
InfoText.Font = Enum.Font.Gotham
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.TextYAlignment = Enum.TextYAlignment.Top
InfoText.Parent = InfoFrame

-- ═══════════════════════════════════════════════════════════════
-- МИНИ-КНОПКА
-- ═══════════════════════════════════════════════════════════════
local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(0, 60, 0, 60)
MiniButton.Position = UDim2.new(0, 15, 0.5, -30)
MiniButton.BackgroundColor3 = GetTheme().Primary
MiniButton.Text = "🥊"
MiniButton.TextSize = 30
MiniButton.Visible = false
MiniButton.Parent = ScreenGui
Instance.new("UICorner", MiniButton).CornerRadius = UDim.new(1, 0)

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color = GetTheme().Accent
MiniStroke.Thickness = 3
MiniStroke.Parent = MiniButton

-- Перетаскивание
local dragMini = false
local dragStartMini, startPosMini

MiniButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragMini = true
        dragStartMini = input.Position
        startPosMini = MiniButton.Position
    end
end)

MiniButton.InputEnded:Connect(function() dragMini = false end)

UserInputService.InputChanged:Connect(function(input)
    if dragMini and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartMini
        MiniButton.Position = UDim2.new(startPosMini.X.Scale, startPosMini.X.Offset + delta.X, startPosMini.Y.Scale, startPosMini.Y.Offset + delta.Y)
    end
end)

MiniButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniButton.Visible = false
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
end)

MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, 0, 1.5, 0)
    }):Play()
    task.wait(0.3)
    MainFrame.Visible = false
    MiniButton.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    Config.Farming = false
    Config.AggressionMode = false
    Config.Fly = false
    ClearAllESP()
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

Header.InputEnded:Connect(function() dragMain = false end)

UserInputService.InputChanged:Connect(function(input)
    if dragMain and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

function GetCharacter() return LocalPlayer.Character end
function GetHumanoid() local c = GetCharacter() return c and c:FindFirstChildOfClass("Humanoid") end
function GetRootPart() local c = GetCharacter() return c and c:FindFirstChild("HumanoidRootPart") end

function GetNearestPlayer()
    local myRoot = GetRootPart()
    if not myRoot then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not Config.Whitelist[player.Name] then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < nearestDist then nearestDist, nearest = dist, player end
                end
            end
        end
    end
    return nearest
end

function GetTargetPlayer()
    -- Если есть выбранная цель
    if Config.SelectedTarget and Config.SelectedTarget.Character then
        local hum = Config.SelectedTarget.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return Config.SelectedTarget
        end
    end
    
    if Config.TargetMode == "Nearest" then return GetNearestPlayer()
    elseif Config.TargetMode == "Random" then
        local valid = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not Config.Whitelist[p.Name] and p.Character then
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then table.insert(valid, p) end
            end
        end
        return #valid > 0 and valid[math.random(#valid)] or nil
    elseif Config.TargetMode == "MostSlaps" then
        local best, max = nil, -1
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not Config.Whitelist[p.Name] and p.Character then
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then
                    local ls = p:FindFirstChild("leaderstats")
                    local slaps = ls and ls:FindFirstChild("Slaps") and ls.Slaps.Value or 0
                    if slaps > max then max, best = slaps, p end
                end
            end
        end
        return best
    elseif Config.TargetMode == "LowestHP" then
        local best, low = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not Config.Whitelist[p.Name] and p.Character then
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 and h.Health < low then low, best = h.Health, p end
            end
        end
        return best
    end
    return GetNearestPlayer()
end

function IsPlayerFallen(player)
    if not player or not player.Character then return true end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    return not root or not hum or hum.Health <= 0 or root.Position.Y < -50
end

function TeleportBehindPlayer(player)
    if not player or not player.Character then return end
    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
    local myRoot = GetRootPart()
    if targetRoot and myRoot then
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    end
end

function TeleportToSpawn()
    local root = GetRootPart()
    if not root then return end
    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    root.CFrame = spawn and spawn.CFrame + Vector3.new(0, 5, 0) or CFrame.new(0, 50, 0)
end

function EquipGlove()
    local char = GetCharacter()
    local hum = GetHumanoid()
    if not char or not hum then return false end
    if char:FindFirstChildOfClass("Tool") then return true end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local tool = bp:FindFirstChildOfClass("Tool")
        if tool then hum:EquipTool(tool) return true end
    end
    return false
end

function Attack()
    local char = GetCharacter()
    if not char then return end
    local glove = char:FindFirstChildOfClass("Tool")
    if not glove then EquipGlove() task.wait(0.05) glove = char:FindFirstChildOfClass("Tool") end
    if glove then
        for _, child in ipairs(glove:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                child:FireServer()
                return
            end
        end
        glove:Activate()
    end
end

function ClearAllESP()
    ESPFolder:ClearAllChildren()
    for _, h in pairs(HighlightObjects) do if h then h:Destroy() end end
    HighlightObjects = {}
end

function UpdateHighlightESP()
    for _, h in pairs(HighlightObjects) do if h then h:Destroy() end end
    HighlightObjects = {}
    if not Config.HighlightESP then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = player.Character
                highlight.FillColor = player == Config.SelectedTarget and Color3.fromRGB(255, 215, 0) or Config.ESPColor
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = player.Character
                HighlightObjects[player.Name] = highlight
            end
        end
    end
end

function UpdateESP()
    ESPFolder:ClearAllChildren()
    if not Config.ESP then return end
    local myRoot = GetRootPart()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if head and root and hum and hum.Health > 0 then
                local bb = Instance.new("BillboardGui")
                bb.Adornee = head
                bb.Size = UDim2.new(0, 160, 0, 60)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Parent = ESPFolder
                
                local nl = Instance.new("TextLabel")
                nl.Size = UDim2.new(1, 0, 0.4, 0)
                nl.BackgroundTransparency = 1
                nl.Text = (player == Config.SelectedTarget and "🎯 " or "") .. player.Name
                nl.TextColor3 = player == Config.SelectedTarget and Color3.fromRGB(255, 215, 0) or Config.ESPColor
                nl.TextStrokeTransparency = 0
                nl.TextSize = 14
                nl.Font = Enum.Font.GothamBold
                nl.Parent = bb
                
                local il = Instance.new("TextLabel")
                il.Size = UDim2.new(1, 0, 0.6, 0)
                il.Position = UDim2.new(0, 0, 0.4, 0)
                il.BackgroundTransparency = 1
                il.TextColor3 = Color3.fromRGB(200, 200, 255)
                il.TextStrokeTransparency = 0
                il.TextSize = 11
                il.Font = Enum.Font.Gotham
                il.Parent = bb
                local dist = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 0
                il.Text = "HP: " .. math.floor(hum.Health) .. " | " .. dist .. "m"
            end
        end
    end
end

function UpdateTracers()
    -- Tracers в ESPFolder (добавляется после ESP)
    if not Config.Tracers then return end
    local myRoot = GetRootPart()
    if not myRoot then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToScreenPoint(root.Position)
                if onScreen then
                    local line = Instance.new("Frame")
                    line.AnchorPoint = Vector2.new(0.5, 0.5)
                    line.BackgroundColor3 = player == Config.SelectedTarget and Color3.fromRGB(255, 215, 0) or Config.ESPColor
                    line.BorderSizePixel = 0
                    line.Parent = ESPFolder
                    
                    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    local target = Vector2.new(pos.X, pos.Y)
                    local dist = (target - center).Magnitude
                    local angle = math.atan2(target.Y - center.Y, target.X - center.X)
                    
                    line.Size = UDim2.new(0, dist, 0, 2)
                    line.Position = UDim2.new(0, (center.X + target.X) / 2, 0, (center.Y + target.Y) / 2)
                    line.Rotation = math.deg(angle)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FLY & NOCLIP
-- ═══════════════════════════════════════════════════════════════
function StartFly()
    local root = GetRootPart()
    local hum = GetHumanoid()
    if not root or not hum then return end
    IsFlying = true
    FlyBodyVelocity = Instance.new("BodyVelocity", root)
    FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyGyro = Instance.new("BodyGyro", root)
    FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyGyro.P = 9e4
    hum.PlatformStand = true
end

function StopFly()
    IsFlying = false
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
    local hum = GetHumanoid()
    if hum then hum.PlatformStand = false end
end

function UpdateFly()
    if not IsFlying or not FlyBodyVelocity then return end
    local dir = Vector3.zero
    local cam = Camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
    FlyBodyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * Config.FlySpeed or Vector3.zero
    FlyBodyGyro.CFrame = cam
end

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНЫЕ ЦИКЛЫ
-- ═══════════════════════════════════════════════════════════════

-- Главный цикл
spawn(function()
    while ScreenGui.Parent do
        local delay = Config.AggressionMode and (Config.AggroSpeed / 1000) or (Config.FarmSpeed / 1000)
        task.wait(delay)
        
        local char = GetCharacter()
        local hum = GetHumanoid()
        local root = GetRootPart()
        
        -- Обновление статуса
        SlapsLabel.Text = tostring(Stats.TotalSlaps)
        KillsLabel.Text = tostring(Stats.Kills)
        ComboLabel.Text = Stats.CurrentCombo .. "x"
        
        local targetName = (Config.SelectedTarget and Config.SelectedTarget.Name) or 
                          (AggroCurrentTarget and AggroCurrentTarget.Name) or 
                          (CurrentTarget and CurrentTarget.Name) or "—"
        TargetLabel.Text = string.sub(targetName, 1, 8)
        
        if not char or not hum or not root or hum.Health <= 0 then continue end
        
        -- Защита
        if Config.GodMode then hum.Health = hum.MaxHealth end
        if Config.SpeedBoost then hum.WalkSpeed = Config.WalkSpeed hum.JumpPower = Config.JumpPower end
        if Config.AntiVoid and root.Position.Y < -50 then TeleportToSpawn() end
        if Config.AutoEquip then EquipGlove() end
        
        -- SpinBot
        if Config.SpinBot then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0)
        end
        
        -- Режим агрессии
        if Config.AggressionMode then
            -- Проверка текущей цели
            if AggroCurrentTarget and IsPlayerFallen(AggroCurrentTarget) then
                if Config.AggroSwitchOnFall then
                    Stats.Kills = Stats.Kills + 1
                    Notify("Kill", AggroCurrentTarget.Name .. " упал!", 2, "kill")
                    if not Config.TargetLock then
                        AggroCurrentTarget = nil
                    end
                end
            end
            
            if not AggroCurrentTarget or IsPlayerFallen(AggroCurrentTarget) then
                AggroCurrentTarget = Config.SelectedTarget or GetTargetPlayer()
            end
            
            if AggroCurrentTarget and AggroCurrentTarget.Character then
                local targetRoot = AggroCurrentTarget.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (targetRoot.Position - root.Position).Magnitude
                    if dist > 5 then TeleportBehindPlayer(AggroCurrentTarget) end
                    if dist <= Config.AttackRange then
                        Attack()
                        Stats.TotalSlaps = Stats.TotalSlaps + 1
                        Stats.CurrentCombo = Stats.CurrentCombo + 1
                        if Stats.CurrentCombo > Stats.BestCombo then
                            Stats.BestCombo = Stats.CurrentCombo
                        end
                    end
                end
            end
        -- Обычный фарм
        elseif Config.Farming or Config.AutoAttack then
            CurrentTarget = GetTargetPlayer()
            if CurrentTarget and CurrentTarget.Character then
                local targetRoot = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (targetRoot.Position - root.Position).Magnitude
                    if Config.TeleportToTarget and dist > 5 then TeleportBehindPlayer(CurrentTarget) end
                    if dist <= Config.AttackRange then
                        Attack()
                        Stats.TotalSlaps = Stats.TotalSlaps + 1
                        Stats.CurrentCombo = Stats.CurrentCombo + 1
                    end
                end
            end
        else
            Stats.CurrentCombo = 0
        end
        
        -- Camera Lock
        if Config.CameraLock then
            local lockTarget = Config.SelectedTarget or AggroCurrentTarget or CurrentTarget
            if lockTarget and lockTarget.Character then
                local targetRoot = lockTarget.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot and root then
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetRoot.Position)
                end
            end
        end
    end
end)

-- NoClip
spawn(function()
    while ScreenGui.Parent do
        task.wait()
        if Config.NoClip then
            local char = GetCharacter()
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end
    end
end)

-- Fly
spawn(function()
    while ScreenGui.Parent do
        task.wait()
        if Config.Fly then
            if not IsFlying then StartFly() end
            UpdateFly()
        else
            if IsFlying then StopFly() end
        end
    end
end)

-- ESP
spawn(function()
    while ScreenGui.Parent do
        task.wait(0.15)
        UpdateESP()
        UpdateHighlightESP()
        UpdateTracers()
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Anti-AFK
spawn(function()
    while ScreenGui.Parent do
        task.wait(30)
        if Config.AntiAFK then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- АНИМАЦИИ
-- ═══════════════════════════════════════════════════════════════

-- Rainbow stroke
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

-- Пульсация мини-кнопки
spawn(function()
    while ScreenGui.Parent do
        if MiniButton.Visible then
            TweenService:Create(MiniButton, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 65, 0, 65)}):Play()
            task.wait(0.8)
            TweenService:Create(MiniButton, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 60, 0, 60)}):Play()
            task.wait(0.8)
        else
            task.wait(0.5)
        end
    end
end)

-- Анимация появления
MainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
    Position = UDim2.new(0.5, 0, 0.5, 0)
}):Play()

-- Приветствие
task.delay(0.5, function()
    Notify("Добро пожаловать!", "Slap Ultimate v3.0 загружен", 3, "success")
end)

-- ═══════════════════════════════════════════════════════════════
print("═══════════════════════════════════════════════════════════")
print("  🥊 SLAP BATTLES ULTIMATE v3.0")
print("  ✅ Все функции работают")
print("  🎯 Выбор цели добавлен")
print("  ✨ Улучшенный GUI")
print("═══════════════════════════════════════════════════════════")
