--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║         ESCAPE TSUNAMI BRAINROT FARM v3.0                    ║
    ║         Плавный полёт вместо телепорта                       ║
    ║         Подъём → Полёт → Спуск → Сбор → Возврат              ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
-- СЕРВИСЫ
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local IsMobile = UserInputService.TouchEnabled

-- ═══════════════════════════════════════════════════════════════
-- КОНФИГУРАЦИЯ
-- ═══════════════════════════════════════════════════════════════
local Config = {
    Farming = false,
    AntiAFK = true,
    AutoCollect = true,
    TeleportBack = true,
    
    -- ТАЙМИНГИ
    HoldDuration = 3.5,
    CollectDelay = 0.3,
    ScanDelay = 0.5,
    
    -- ПОЛЁТ
    FlyHeight = 50,          -- Высота полёта
    FlySpeed = 150,          -- Скорость горизонтального полёта
    VerticalSpeed = 100,     -- Скорость подъёма/спуска
    DescendSpeed = 200,      -- Скорость быстрого спуска
    
    SavedPosition = nil,
    
    -- Редкости
    Brainrots = {
        Common = false,
        Uncommon = false,
        Rare = false,
        Epic = false,
        Legendary = true,
        Mythic = true,
        Secret = true,
        Divine = true,
        Exclusive = true
    },
    
    LuckyBlocks = {
        Common = false,
        Uncommon = false,
        Rare = false,
        Epic = false,
        Legendary = true,
        Mythic = true,
        Secret = true,
        Divine = true,
        Exclusive = true
    }
}

-- Цвета редкостей
local RarityColors = {
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(80, 200, 80),
    Rare = Color3.fromRGB(80, 150, 255),
    Epic = Color3.fromRGB(180, 80, 255),
    Legendary = Color3.fromRGB(255, 180, 50),
    Mythic = Color3.fromRGB(255, 80, 150),
    Secret = Color3.fromRGB(255, 50, 50),
    Divine = Color3.fromRGB(255, 215, 0),
    Exclusive = Color3.fromRGB(50, 255, 255)
}

-- Ключевые слова
local RarityKeywords = {
    Common = {"common", "обычн"},
    Uncommon = {"uncommon", "необычн"},
    Rare = {"rare", "редк"},
    Epic = {"epic", "эпич"},
    Legendary = {"legendary", "legend", "легенд"},
    Mythic = {"mythic", "myth", "мифич"},
    Secret = {"secret", "секрет"},
    Divine = {"divine", "божеств"},
    Exclusive = {"exclusive", "эксклюзив"}
}

local BrainrotKeywords = {
    "brainrot", "brain", "rot", "skibidi", "toilet", "ohio", 
    "sigma", "rizz", "gyatt", "fanum", "tax", "mewing",
    "pet", "aura", "collectible", "npc", "spawn"
}

local LuckyBlockKeywords = {
    "lucky", "block", "luckyblock", "crate", "chest", "box", 
    "reward", "loot", "prize", "gift", "present"
}

-- Статистика
local Stats = {
    Collected = 0,
    BrainrotsCollected = 0,
    LuckyBlocksCollected = 0
}

-- Состояние полёта
local IsFlying = false
local FlyConnection = nil

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ GUI
-- ═══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BrainrotFarm"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

pcall(function() if syn then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = gethui and gethui() or game:GetService("CoreGui")

-- Уведомления
local NotifContainer = Instance.new("Frame")
NotifContainer.Size = UDim2.new(0, 320, 1, 0)
NotifContainer.Position = UDim2.new(1, -330, 0, 0)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = ScreenGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifLayout.Parent = NotifContainer

-- ═══════════════════════════════════════════════════════════════
-- ТЕМА
-- ═══════════════════════════════════════════════════════════════
local Theme = {
    Primary = Color3.fromRGB(100, 50, 200),
    Secondary = Color3.fromRGB(70, 30, 150),
    Background = Color3.fromRGB(20, 15, 35),
    Card = Color3.fromRGB(30, 25, 50),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 140, 180),
    Success = Color3.fromRGB(80, 200, 100),
    Warning = Color3.fromRGB(255, 180, 50),
    Error = Color3.fromRGB(255, 80, 80)
}

-- ═══════════════════════════════════════════════════════════════
-- УВЕДОМЛЕНИЯ
-- ═══════════════════════════════════════════════════════════════
local function Notify(title, message, duration, notifType)
    duration = duration or 3
    
    local colors = {
        info = Theme.Primary,
        success = Theme.Success,
        warning = Theme.Warning,
        error = Theme.Error,
        collect = Color3.fromRGB(255, 215, 0),
        fly = Color3.fromRGB(100, 200, 255)
    }
    
    local icons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌",
        collect = "🎁",
        fly = "✈️"
    }
    
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 70)
    Notif.Position = UDim2.new(1, 50, 0, 0)
    Notif.BackgroundColor3 = Theme.Card
    Notif.BorderSizePixel = 0
    Notif.Parent = NotifContainer
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 12)
    
    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(0, 4, 1, 0)
    Accent.BackgroundColor3 = colors[notifType] or colors.info
    Accent.BorderSizePixel = 0
    Accent.Parent = Notif
    Instance.new("UICorner", Accent).CornerRadius = UDim.new(0, 12)
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 40, 0, 40)
    Icon.Position = UDim2.new(0, 12, 0.5, -20)
    Icon.BackgroundTransparency = 1
    Icon.Text = icons[notifType] or "ℹ️"
    Icon.TextSize = 24
    Icon.Parent = Notif
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -65, 0, 22)
    TitleLabel.Position = UDim2.new(0, 55, 0, 12)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 13
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Notif
    
    local MsgLabel = Instance.new("TextLabel")
    MsgLabel.Size = UDim2.new(1, -65, 0, 25)
    MsgLabel.Position = UDim2.new(0, 55, 0, 35)
    MsgLabel.BackgroundTransparency = 1
    MsgLabel.Text = message
    MsgLabel.TextColor3 = Theme.TextDim
    MsgLabel.TextSize = 11
    MsgLabel.Font = Enum.Font.Gotham
    MsgLabel.TextXAlignment = Enum.TextXAlignment.Left
    MsgLabel.TextWrapped = true
    MsgLabel.Parent = Notif
    
    TweenService:Create(Notif, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    task.delay(duration, function()
        TweenService:Create(Notif, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 50, 0, 0)
        }):Play()
        task.wait(0.3)
        Notif:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНОЕ ОКНО
-- ═══════════════════════════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = IsMobile and UDim2.new(0.95, 0, 0.9, 0) or UDim2.new(0, 480, 0, 700)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Primary
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local BGGradient = Instance.new("UIGradient")
BGGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 25, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 10, 30))
})
BGGradient.Rotation = 45
BGGradient.Parent = MainFrame

-- ═══════════════════════════════════════════════════════════════
-- HEADER
-- ═══════════════════════════════════════════════════════════════
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = Theme.Card
Header.BorderSizePixel = 0
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Primary),
    ColorSequenceKeypoint.new(1, Theme.Secondary)
})
HeaderGradient.Parent = Header

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, 50, 0, 50)
Logo.Position = UDim2.new(0, 10, 0.5, -25)
Logo.BackgroundTransparency = 1
Logo.Text = "🧠"
Logo.TextSize = 35
Logo.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 0, 28)
Title.Position = UDim2.new(0, 65, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "BRAINROT FARM"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 200, 0, 16)
Subtitle.Position = UDim2.new(0, 65, 0, 36)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "v3.0 - Smooth Flight"
Subtitle.TextColor3 = Color3.fromRGB(200, 200, 220)
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Кнопки
local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(0, 90, 0, 40)
BtnContainer.Position = UDim2.new(1, -100, 0.5, -20)
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
    Btn.TextSize = 16
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.Parent = BtnContainer
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

local MinBtn = CreateHeaderBtn("—", Color3.fromRGB(80, 80, 120), function() end)
local CloseBtn = CreateHeaderBtn("✕", Color3.fromRGB(200, 60, 60), function() end)

-- ═══════════════════════════════════════════════════════════════
-- СТАТУС ПАНЕЛЬ
-- ═══════════════════════════════════════════════════════════════
local StatusPanel = Instance.new("Frame")
StatusPanel.Size = UDim2.new(1, -20, 0, 130)
StatusPanel.Position = UDim2.new(0, 10, 0, 65)
StatusPanel.BackgroundColor3 = Theme.Card
StatusPanel.BorderSizePixel = 0
StatusPanel.Parent = MainFrame
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 12)

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Size = UDim2.new(0, 50, 0, 50)
StatusIcon.Position = UDim2.new(0, 10, 0, 10)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "⏸️"
StatusIcon.TextSize = 30
StatusIcon.Parent = StatusPanel

local StatusTitle = Instance.new("TextLabel")
StatusTitle.Size = UDim2.new(0.5, -70, 0, 20)
StatusTitle.Position = UDim2.new(0, 65, 0, 10)
StatusTitle.BackgroundTransparency = 1
StatusTitle.Text = "Статус: Ожидание"
StatusTitle.TextColor3 = Theme.Text
StatusTitle.TextSize = 13
StatusTitle.Font = Enum.Font.GothamBold
StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
StatusTitle.Parent = StatusPanel

local StatusInfo = Instance.new("TextLabel")
StatusInfo.Size = UDim2.new(0.5, -70, 0, 18)
StatusInfo.Position = UDim2.new(0, 65, 0, 32)
StatusInfo.BackgroundTransparency = 1
StatusInfo.Text = "Собрано: 0 | 🧠 0 | 🎁 0"
StatusInfo.TextColor3 = Theme.TextDim
StatusInfo.TextSize = 10
StatusInfo.Font = Enum.Font.Gotham
StatusInfo.TextXAlignment = Enum.TextXAlignment.Left
StatusInfo.Parent = StatusPanel

-- Статус полёта
local FlyStatus = Instance.new("TextLabel")
FlyStatus.Size = UDim2.new(0.5, -70, 0, 18)
FlyStatus.Position = UDim2.new(0, 65, 0, 52)
FlyStatus.BackgroundTransparency = 1
FlyStatus.Text = "✈️ Полёт: Ожидание"
FlyStatus.TextColor3 = Color3.fromRGB(100, 200, 255)
FlyStatus.TextSize = 10
FlyStatus.Font = Enum.Font.Gotham
FlyStatus.TextXAlignment = Enum.TextXAlignment.Left
FlyStatus.Parent = StatusPanel

-- Прогресс бар для удержания E
local HoldProgressBG = Instance.new("Frame")
HoldProgressBG.Size = UDim2.new(0.55, -20, 0, 16)
HoldProgressBG.Position = UDim2.new(0, 65, 0, 75)
HoldProgressBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
HoldProgressBG.BorderSizePixel = 0
HoldProgressBG.Parent = StatusPanel
Instance.new("UICorner", HoldProgressBG).CornerRadius = UDim.new(1, 0)

local HoldProgressFill = Instance.new("Frame")
HoldProgressFill.Size = UDim2.new(0, 0, 1, 0)
HoldProgressFill.BackgroundColor3 = Theme.Success
HoldProgressFill.BorderSizePixel = 0
HoldProgressFill.Parent = HoldProgressBG
Instance.new("UICorner", HoldProgressFill).CornerRadius = UDim.new(1, 0)

local HoldProgressText = Instance.new("TextLabel")
HoldProgressText.Size = UDim2.new(1, 0, 1, 0)
HoldProgressText.BackgroundTransparency = 1
HoldProgressText.Text = "⌨️ Удержание E: —"
HoldProgressText.TextColor3 = Color3.fromRGB(255, 255, 255)
HoldProgressText.TextSize = 9
HoldProgressText.Font = Enum.Font.GothamBold
HoldProgressText.Parent = HoldProgressBG

-- Кнопка Start/Stop
local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(0, 130, 0, 80)
StartButton.Position = UDim2.new(1, -145, 0.5, -40)
StartButton.BackgroundColor3 = Theme.Success
StartButton.Text = "▶️ СТАРТ"
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.TextSize = 16
StartButton.Font = Enum.Font.GothamBold
StartButton.Parent = StatusPanel
Instance.new("UICorner", StartButton).CornerRadius = UDim.new(0, 12)

-- ═══════════════════════════════════════════════════════════════
-- ТАБЫ
-- ═══════════════════════════════════════════════════════════════
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 0, 42)
TabContainer.Position = UDim2.new(0, 10, 0, 200)
TabContainer.BackgroundColor3 = Theme.Card
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame
Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 10)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent = TabContainer

local Tabs = {
    {Name = "🧠", FullName = "Брейнроты"},
    {Name = "🎁", FullName = "Лаки Блоки"},
    {Name = "✈️", FullName = "Полёт"},
    {Name = "⚙️", FullName = "Настройки"}
}

local TabButtons = {}
local TabContents = {}
local CurrentTab = 1

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -260)
ContentContainer.Position = UDim2.new(0, 10, 0, 248)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ClipsDescendants = true
ContentContainer.Parent = MainFrame

for i, tab in ipairs(Tabs) do
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, IsMobile and 85 or 105, 0, 32)
    TabBtn.BackgroundColor3 = i == 1 and Theme.Primary or Color3.fromRGB(50, 45, 75)
    TabBtn.Text = tab.Name .. " " .. tab.FullName
    TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabBtn.TextSize = IsMobile and 10 or 12
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.Parent = TabContainer
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)
    
    TabButtons[i] = TabBtn
    
    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, 0, 1, 0)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = Theme.Primary
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.Visible = i == 1
    Content.Parent = ContentContainer
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 7)
    Layout.Parent = Content
    
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
    end)
    
    TabContents[i] = Content
    
    TabBtn.MouseButton1Click:Connect(function()
        for j, btn in ipairs(TabButtons) do
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = j == i and Theme.Primary or Color3.fromRGB(50, 45, 75)
            }):Play()
            TabContents[j].Visible = j == i
        end
        CurrentTab = i
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- UI BUILDER
-- ═══════════════════════════════════════════════════════════════

local function CreateSection(parent, name, icon)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 32)
    Section.BackgroundColor3 = Theme.Primary
    Section.BorderSizePixel = 0
    Section.Parent = parent
    Instance.new("UICorner", Section).CornerRadius = UDim.new(0, 8)
    
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(1, Theme.Secondary)
    })
    Gradient.Parent = Section
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = (icon or "") .. " " .. name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Section
end

local function CreateRarityToggle(parent, rarityName, configTable)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, 45)
    Toggle.BackgroundColor3 = Theme.Card
    Toggle.BorderSizePixel = 0
    Toggle.Parent = parent
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 10)
    
    local RarityBadge = Instance.new("Frame")
    RarityBadge.Size = UDim2.new(0, 5, 0.6, 0)
    RarityBadge.Position = UDim2.new(0, 8, 0.2, 0)
    RarityBadge.BackgroundColor3 = RarityColors[rarityName] or Theme.Primary
    RarityBadge.BorderSizePixel = 0
    RarityBadge.Parent = Toggle
    Instance.new("UICorner", RarityBadge).CornerRadius = UDim.new(0, 3)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.6, -25, 1, 0)
    NameLabel.Position = UDim2.new(0, 22, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = rarityName
    NameLabel.TextColor3 = RarityColors[rarityName] or Theme.Text
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Toggle
    
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 48, 0, 24)
    SwitchBG.Position = UDim2.new(1, -60, 0.5, -12)
    SwitchBG.BackgroundColor3 = configTable[rarityName] and Theme.Success or Color3.fromRGB(60, 60, 80)
    SwitchBG.Parent = Toggle
    Instance.new("UICorner", SwitchBG).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = configTable[rarityName] and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = SwitchBG
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    
    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.Parent = Toggle
    
    ClickBtn.MouseButton1Click:Connect(function()
        configTable[rarityName] = not configTable[rarityName]
        local enabled = configTable[rarityName]
        
        TweenService:Create(SwitchBG, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Theme.Success or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Position = enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
    end)
end

local function CreateToggle(parent, name, configKey, desc)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, desc and 52 or 42)
    Toggle.BackgroundColor3 = Theme.Card
    Toggle.BorderSizePixel = 0
    Toggle.Parent = parent
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.65, 0, 0, 20)
    NameLabel.Position = UDim2.new(0, 12, 0, desc and 8 or 11)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Theme.Text
    NameLabel.TextSize = 12
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Toggle
    
    if desc then
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(0.65, 0, 0, 14)
        DescLabel.Position = UDim2.new(0, 12, 0, 28)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = desc
        DescLabel.TextColor3 = Theme.TextDim
        DescLabel.TextSize = 9
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.Parent = Toggle
    end
    
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 48, 0, 24)
    SwitchBG.Position = UDim2.new(1, -60, 0.5, -12)
    SwitchBG.BackgroundColor3 = Config[configKey] and Theme.Success or Color3.fromRGB(60, 60, 80)
    SwitchBG.Parent = Toggle
    Instance.new("UICorner", SwitchBG).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = Config[configKey] and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
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
            BackgroundColor3 = enabled and Theme.Success or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Position = enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
    end)
end

local function CreateSlider(parent, name, configKey, min, max, step)
    step = step or 1
    
    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, 0, 0, 55)
    Slider.BackgroundColor3 = Theme.Card
    Slider.BorderSizePixel = 0
    Slider.Parent = parent
    Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.6, 0, 0, 20)
    NameLabel.Position = UDim2.new(0, 12, 0, 6)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Theme.Text
    NameLabel.TextSize = 11
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Slider
    
    local ValueBG = Instance.new("Frame")
    ValueBG.Size = UDim2.new(0, 50, 0, 20)
    ValueBG.Position = UDim2.new(1, -62, 0, 5)
    ValueBG.BackgroundColor3 = Theme.Primary
    ValueBG.Parent = Slider
    Instance.new("UICorner", ValueBG).CornerRadius = UDim.new(0, 5)
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(1, 0, 1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(Config[configKey])
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 10
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Parent = ValueBG
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -24, 0, 8)
    SliderBar.Position = UDim2.new(0, 12, 0, 38)
    SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    SliderBar.Parent = Slider
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)
    
    local pct = math.clamp((Config[configKey] - min) / (max - min), 0, 1)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Primary
    Fill.Parent = SliderBar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    
    local Handle = Instance.new("Frame")
    Handle.Size = UDim2.new(0, 14, 0, 14)
    Handle.Position = UDim2.new(pct, -7, 0.5, -7)
    Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handle.Parent = SliderBar
    Instance.new("UICorner", Handle).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    
    local function Update(inputX)
        local barStart = SliderBar.AbsolutePosition.X
        local barWidth = SliderBar.AbsoluteSize.X
        local newPct = math.clamp((inputX - barStart) / barWidth, 0, 1)
        local newVal = min + (max - min) * newPct
        newVal = math.floor(newVal / step + 0.5) * step
        
        Config[configKey] = newVal
        ValueLabel.Text = tostring(newVal)
        Fill.Size = UDim2.new(newPct, 0, 1, 0)
        Handle.Position = UDim2.new(newPct, -7, 0.5, -7)
    end
    
    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Update(input.Position.X)
        end
    end)
    
    SliderBar.InputEnded:Connect(function() dragging = false end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input.Position.X)
        end
    end)
end

local function CreateButton(parent, name, icon, color, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 42)
    Button.BackgroundColor3 = color or Theme.Primary
    Button.Text = ""
    Button.Parent = parent
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 10)
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 35, 1, 0)
    Icon.Position = UDim2.new(0, 8, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = icon or ""
    Icon.TextSize = 18
    Icon.Parent = Button
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 45, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button
    
    Button.MouseButton1Click:Connect(callback)
end

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ КОНТЕНТА
-- ═══════════════════════════════════════════════════════════════

-- ТАБ 1: БРЕЙНРОТЫ
CreateSection(TabContents[1], "РЕДКОСТИ", "🧠")

local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine", "Exclusive"}

for _, rarity in ipairs(rarities) do
    CreateRarityToggle(TabContents[1], rarity, Config.Brainrots)
end

CreateSection(TabContents[1], "БЫСТРЫЙ ВЫБОР", "⚡")

CreateButton(TabContents[1], "Выбрать все", "✅", Theme.Success, function()
    for _, r in ipairs(rarities) do Config.Brainrots[r] = true end
    Notify("Брейнроты", "Все выбраны", 2, "success")
end)

CreateButton(TabContents[1], "Только редкие+", "💎", Color3.fromRGB(180, 100, 255), function()
    for _, r in ipairs(rarities) do
        Config.Brainrots[r] = r ~= "Common" and r ~= "Uncommon"
    end
    Notify("Брейнроты", "Rare+ выбраны", 2, "success")
end)

CreateButton(TabContents[1], "Снять все", "❌", Theme.Error, function()
    for _, r in ipairs(rarities) do Config.Brainrots[r] = false end
    Notify("Брейнроты", "Все сняты", 2, "info")
end)

-- ТАБ 2: ЛАКИ БЛОКИ
CreateSection(TabContents[2], "РЕДКОСТИ", "🎁")

for _, rarity in ipairs(rarities) do
    CreateRarityToggle(TabContents[2], rarity, Config.LuckyBlocks)
end

CreateSection(TabContents[2], "БЫСТРЫЙ ВЫБОР", "⚡")

CreateButton(TabContents[2], "Выбрать все", "✅", Theme.Success, function()
    for _, r in ipairs(rarities) do Config.LuckyBlocks[r] = true end
    Notify("Лаки блоки", "Все выбраны", 2, "success")
end)

CreateButton(TabContents[2], "Только редкие+", "💎", Color3.fromRGB(180, 100, 255), function()
    for _, r in ipairs(rarities) do
        Config.LuckyBlocks[r] = r ~= "Common" and r ~= "Uncommon"
    end
    Notify("Лаки блоки", "Rare+ выбраны", 2, "success")
end)

CreateButton(TabContents[2], "Снять все", "❌", Theme.Error, function()
    for _, r in ipairs(rarities) do Config.LuckyBlocks[r] = false end
    Notify("Лаки блоки", "Все сняты", 2, "info")
end)

-- ТАБ 3: ПОЛЁТ
CreateSection(TabContents[3], "НАСТРОЙКИ ПОЛЁТА", "✈️")
CreateSlider(TabContents[3], "Высота полёта (studs)", "FlyHeight", 20, 150, 10)
CreateSlider(TabContents[3], "Скорость полёта", "FlySpeed", 50, 300, 10)
CreateSlider(TabContents[3], "Скорость подъёма", "VerticalSpeed", 50, 200, 10)
CreateSlider(TabContents[3], "Скорость спуска", "DescendSpeed", 100, 400, 20)

CreateSection(TabContents[3], "УДЕРЖАНИЕ E", "⌨️")
CreateSlider(TabContents[3], "Время удержания (сек)", "HoldDuration", 1, 6, 0.5)

CreateSection(TabContents[3], "ОПИСАНИЕ", "📖")

local DescFrame = Instance.new("Frame")
DescFrame.Size = UDim2.new(1, 0, 0, 100)
DescFrame.BackgroundColor3 = Theme.Card
DescFrame.Parent = TabContents[3]
Instance.new("UICorner", DescFrame).CornerRadius = UDim.new(0, 10)

local DescText = Instance.new("TextLabel")
DescText.Size = UDim2.new(1, -20, 1, -10)
DescText.Position = UDim2.new(0, 10, 0, 5)
DescText.BackgroundTransparency = 1
DescText.Text = "🛫 Персонаж ПОДНИМАЕТСЯ вверх\n✈️ Летит ГОРИЗОНТАЛЬНО к цели\n🛬 БЫСТРО ОПУСКАЕТСЯ к предмету\n⌨️ Зажимает E на время сбора\n🔄 Возвращается тем же путём"
DescText.TextColor3 = Theme.TextDim
DescText.TextSize = 11
DescText.Font = Enum.Font.Gotham
DescText.TextXAlignment = Enum.TextXAlignment.Left
DescText.TextYAlignment = Enum.TextYAlignment.Top
DescText.TextWrapped = true
DescText.Parent = DescFrame

-- ТАБ 4: НАСТРОЙКИ
CreateSection(TabContents[4], "ОСНОВНЫЕ", "⚙️")
CreateToggle(TabContents[4], "Анти-АФК", "AntiAFK", "Не кикает за бездействие")
CreateToggle(TabContents[4], "Авто-сбор", "AutoCollect", "Автоматически собирать")
CreateToggle(TabContents[4], "Возврат на базу", "TeleportBack", "Возвращаться после сбора")

CreateSection(TabContents[4], "ТАЙМИНГИ", "⏱️")
CreateSlider(TabContents[4], "Задержка после сбора (сек)", "CollectDelay", 0.1, 2, 0.1)
CreateSlider(TabContents[4], "Частота сканирования (сек)", "ScanDelay", 0.2, 2, 0.1)

CreateSection(TabContents[4], "ДЕЙСТВИЯ", "⚡")

CreateButton(TabContents[4], "Сохранить позицию базы", "📍", Color3.fromRGB(80, 150, 200), function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        Config.SavedPosition = root.CFrame
        Notify("База", "Позиция сохранена", 2, "success")
    end
end)

CreateButton(TabContents[4], "Телепорт на базу", "🏠", Color3.fromRGB(100, 180, 100), function()
    if Config.SavedPosition then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = Config.SavedPosition end
    else
        Notify("Ошибка", "Сначала сохраните базу", 2, "error")
    end
end)

CreateButton(TabContents[4], "Сбросить статистику", "🔄", Color3.fromRGB(100, 100, 150), function()
    Stats.Collected = 0
    Stats.BrainrotsCollected = 0
    Stats.LuckyBlocksCollected = 0
    Notify("Статистика", "Сброшена", 2, "info")
end)

-- ═══════════════════════════════════════════════════════════════
-- МИНИ-КНОПКА
-- ═══════════════════════════════════════════════════════════════
local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(0, 55, 0, 55)
MiniButton.Position = UDim2.new(0, 15, 0.5, -27)
MiniButton.BackgroundColor3 = Theme.Primary
MiniButton.Text = "🧠"
MiniButton.TextSize = 28
MiniButton.Visible = false
MiniButton.Parent = ScreenGui
Instance.new("UICorner", MiniButton).CornerRadius = UDim.new(1, 0)

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color = Theme.Primary
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
    if dragMini then
        local delta = input.Position - dragStartMini
        MiniButton.Position = UDim2.new(startPosMini.X.Scale, startPosMini.X.Offset + delta.X, startPosMini.Y.Scale, startPosMini.Y.Offset + delta.Y)
    end
end)

MiniButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniButton.Visible = false
end)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniButton.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    Config.Farming = false
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
    if dragMain then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════════════════════════════
-- СИСТЕМА ПЛАВНОГО ПОЛЁТА
-- ═══════════════════════════════════════════════════════════════

-- Плавное перемещение к позиции
local function SmoothMoveTo(targetPosition, speed, updateStatus)
    local root = GetRootPart()
    if not root then return false end
    
    local startPos = root.Position
    local direction = (targetPosition - startPos)
    local distance = direction.Magnitude
    
    if distance < 1 then return true end
    
    direction = direction.Unit
    local duration = distance / speed
    local startTime = tick()
    
    while tick() - startTime < duration do
        if not Config.Farming then return false end
        
        root = GetRootPart()
        if not root then return false end
        
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Плавное движение с easing
        local easedProgress = 1 - math.pow(1 - progress, 2)
        local newPos = startPos:Lerp(targetPosition, easedProgress)
        
        root.CFrame = CFrame.new(newPos) * CFrame.Angles(0, root.CFrame:ToEulerAnglesYXZ())
        
        if updateStatus then
            updateStatus(progress)
        end
        
        RunService.Heartbeat:Wait()
    end
    
    -- Финальная позиция
    root = GetRootPart()
    if root then
        root.CFrame = CFrame.new(targetPosition) * CFrame.Angles(0, root.CFrame:ToEulerAnglesYXZ())
    end
    
    return true
end

-- Подъём вверх
local function FlyUp(targetHeight)
    local root = GetRootPart()
    if not root then return false end
    
    local startPos = root.Position
    local targetPos = Vector3.new(startPos.X, targetHeight, startPos.Z)
    
    FlyStatus.Text = "✈️ Полёт: 🛫 Взлёт..."
    
    return SmoothMoveTo(targetPos, Config.VerticalSpeed, function(progress)
        FlyStatus.Text = string.format("✈️ Полёт: 🛫 Взлёт %.0f%%", progress * 100)
    end)
end

-- Горизонтальный полёт
local function FlyHorizontal(targetX, targetZ, currentHeight)
    local root = GetRootPart()
    if not root then return false end
    
    local targetPos = Vector3.new(targetX, currentHeight, targetZ)
    
    FlyStatus.Text = "✈️ Полёт: ✈️ В пути..."
    
    return SmoothMoveTo(targetPos, Config.FlySpeed, function(progress)
        FlyStatus.Text = string.format("✈️ Полёт: ✈️ В пути %.0f%%", progress * 100)
    end)
end

-- Быстрый спуск
local function FlyDown(targetY)
    local root = GetRootPart()
    if not root then return false end
    
    local startPos = root.Position
    local targetPos = Vector3.new(startPos.X, targetY, startPos.Z)
    
    FlyStatus.Text = "✈️ Полёт: 🛬 Спуск..."
    
    return SmoothMoveTo(targetPos, Config.DescendSpeed, function(progress)
        FlyStatus.Text = string.format("✈️ Полёт: 🛬 Спуск %.0f%%", progress * 100)
    end)
end

-- Полный цикл полёта к цели и обратно
local function FlyToTargetAndBack(targetPosition, originalPosition)
    local root = GetRootPart()
    if not root then return false end
    
    local startPos = root.Position
    local flyHeight = math.max(startPos.Y, targetPosition.Y) + Config.FlyHeight
    
    -- ═══ ПУТЬ К ЦЕЛИ ═══
    
    -- 1. Взлёт
    FlyStatus.Text = "✈️ Полёт: 🛫 Взлёт..."
    if not FlyUp(flyHeight) then return false end
    task.wait(0.1)
    
    -- 2. Горизонтальный полёт к цели
    FlyStatus.Text = "✈️ Полёт: ✈️ К цели..."
    if not FlyHorizontal(targetPosition.X, targetPosition.Z, flyHeight) then return false end
    task.wait(0.1)
    
    -- 3. Быстрый спуск к предмету
    FlyStatus.Text = "✈️ Полёт: 🛬 Спуск к цели..."
    if not FlyDown(targetPosition.Y + 3) then return false end
    
    return true
end

local function FlyBackToBase(originalPosition)
    local root = GetRootPart()
    if not root then return false end
    
    local currentPos = root.Position
    local flyHeight = math.max(currentPos.Y, originalPosition.Y) + Config.FlyHeight
    
    -- ═══ ПУТЬ НАЗАД ═══
    
    -- 1. Взлёт от места сбора
    FlyStatus.Text = "✈️ Полёт: 🛫 Взлёт (возврат)..."
    if not FlyUp(flyHeight) then return false end
    task.wait(0.1)
    
    -- 2. Горизонтальный полёт к базе
    FlyStatus.Text = "✈️ Полёт: ✈️ К базе..."
    if not FlyHorizontal(originalPosition.X, originalPosition.Z, flyHeight) then return false end
    task.wait(0.1)
    
    -- 3. Спуск на базу
    FlyStatus.Text = "✈️ Полёт: 🛬 Посадка..."
    if not FlyDown(originalPosition.Y) then return false end
    
    FlyStatus.Text = "✈️ Полёт: ✅ На базе"
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- УДЕРЖАНИЕ E
-- ═══════════════════════════════════════════════════════════════

local function HoldKeyE(duration)
    duration = duration or Config.HoldDuration
    
    local startTime = tick()
    
    -- Начинаем удержание
    if keypress then
        pcall(function() keypress(0x45) end)
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        end)
    end
    
    -- Обновляем прогресс
    while tick() - startTime < duration do
        if not Config.Farming then break end
        
        local elapsed = tick() - startTime
        local progress = elapsed / duration
        
        HoldProgressFill.Size = UDim2.new(progress, 0, 1, 0)
        HoldProgressText.Text = string.format("⌨️ E: %.1fs / %.1fs", elapsed, duration)
        
        task.wait(0.05)
    end
    
    -- Отпускаем
    if keyrelease then
        pcall(function() keyrelease(0x45) end)
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
    end
    
    HoldProgressFill.Size = UDim2.new(1, 0, 1, 0)
    HoldProgressText.Text = "✅ Собрано!"
    
    task.wait(0.3)
    HoldProgressFill.Size = UDim2.new(0, 0, 1, 0)
    HoldProgressText.Text = "⌨️ Удержание E: —"
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- ПОИСК ПРЕДМЕТОВ
-- ═══════════════════════════════════════════════════════════════

local function GetRarity(object)
    local name = object.Name:lower()
    
    local rarityAttr = object:GetAttribute("Rarity") or object:GetAttribute("rarity")
    if rarityAttr then
        local attrLower = tostring(rarityAttr):lower()
        for rarity, keywords in pairs(RarityKeywords) do
            for _, keyword in ipairs(keywords) do
                if attrLower:find(keyword) then return rarity end
            end
        end
    end
    
    for rarity, keywords in pairs(RarityKeywords) do
        for _, keyword in ipairs(keywords) do
            if name:find(keyword) then return rarity end
        end
    end
    
    for _, desc in ipairs(object:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local text = desc.Text:lower()
            for rarity, keywords in pairs(RarityKeywords) do
                for _, keyword in ipairs(keywords) do
                    if text:find(keyword) then return rarity end
                end
            end
        end
    end
    
    if object.Parent then
        local parentName = object.Parent.Name:lower()
        for rarity, keywords in pairs(RarityKeywords) do
            for _, keyword in ipairs(keywords) do
                if parentName:find(keyword) then return rarity end
            end
        end
    end
    
    return nil
end

local function IsBrainrot(object)
    local name = object.Name:lower()
    for _, keyword in ipairs(BrainrotKeywords) do
        if name:find(keyword) then return true end
    end
    return false
end

local function IsLuckyBlock(object)
    local name = object.Name:lower()
    for _, keyword in ipairs(LuckyBlockKeywords) do
        if name:find(keyword) then return true end
    end
    return false
end

local function FindAllCollectibles()
    local found = {}
    
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local parent = prompt.Parent
            if parent then
                local rarity = GetRarity(parent)
                local isBrainrot = IsBrainrot(parent)
                local isLucky = IsLuckyBlock(parent)
                
                if (isBrainrot and rarity and Config.Brainrots[rarity]) or
                   (isLucky and rarity and Config.LuckyBlocks[rarity]) or
                   (rarity and (Config.Brainrots[rarity] or Config.LuckyBlocks[rarity])) then
                    
                    local pos = parent:IsA("Model") and parent:GetPivot().Position or 
                               parent:IsA("BasePart") and parent.Position or
                               prompt.Parent:IsA("BasePart") and prompt.Parent.Position
                    
                    if pos then
                        table.insert(found, {
                            Object = parent,
                            Prompt = prompt,
                            Position = pos,
                            Rarity = rarity,
                            Type = isBrainrot and "Brainrot" or (isLucky and "LuckyBlock" or "Unknown")
                        })
                    end
                end
            end
        end
    end
    
    return found
end

-- ═══════════════════════════════════════════════════════════════
-- СБОР ПРЕДМЕТА С ПОЛЁТОМ
-- ═══════════════════════════════════════════════════════════════

local function CollectItemWithFlight(item)
    local root = GetRootPart()
    if not root then return false end
    
    -- Сохраняем стартовую позицию (база)
    local basePosition = Config.SavedPosition and Config.SavedPosition.Position or root.Position
    
    StatusTitle.Text = "Статус: ✈️ Летим к " .. item.Rarity
    
    -- Летим к цели
    if not FlyToTargetAndBack(item.Position, basePosition) then
        return false
    end
    
    -- Собираем (удержание E)
    StatusTitle.Text = "Статус: ⌨️ Сбор..."
    FlyStatus.Text = "✈️ Полёт: 📦 Сбор предмета"
    
    -- Активируем ProximityPrompt если есть
    if item.Prompt then
        if fireproximityprompt then
            pcall(function() fireproximityprompt(item.Prompt, Config.HoldDuration) end)
        end
    end
    
    -- Удерживаем E
    HoldKeyE(Config.HoldDuration)
    
    -- Касаемся объекта
    root = GetRootPart()
    if root and item.Object then
        local part = item.Object:IsA("BasePart") and item.Object or 
                    (item.Object:IsA("Model") and (item.Object.PrimaryPart or item.Object:FindFirstChildOfClass("BasePart")))
        if part then
            pcall(function()
                firetouchinterest(root, part, 0)
                task.wait(0.1)
                firetouchinterest(root, part, 1)
            end)
        end
    end
    
    task.wait(Config.CollectDelay)
    
    -- Возвращаемся на базу
    if Config.TeleportBack then
        StatusTitle.Text = "Статус: ✈️ Возвращаемся"
        if not FlyBackToBase(basePosition) then
            -- Если не получилось плавно - телепортируемся
            root = GetRootPart()
            if root then
                root.CFrame = CFrame.new(basePosition)
            end
        end
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- КНОПКА СТАРТ
-- ═══════════════════════════════════════════════════════════════

StartButton.MouseButton1Click:Connect(function()
    Config.Farming = not Config.Farming
    
    if Config.Farming then
        local root = GetRootPart()
        if root and not Config.SavedPosition then
            Config.SavedPosition = root.CFrame
            Notify("База", "Позиция автоматически сохранена", 2, "info")
        end
        
        StartButton.Text = "⏹️ СТОП"
        StartButton.BackgroundColor3 = Theme.Error
        StatusTitle.Text = "Статус: 🟢 Активен"
        StatusIcon.Text = "🟢"
        
        Notify("Фарм запущен", "Плавный полёт активирован", 2, "success")
    else
        StartButton.Text = "▶️ СТАРТ"
        StartButton.BackgroundColor3 = Theme.Success
        StatusTitle.Text = "Статус: ⏸️ Остановлен"
        StatusIcon.Text = "⏸️"
        FlyStatus.Text = "✈️ Полёт: Остановлен"
        
        Notify("Фарм остановлен", "Собрано: " .. Stats.Collected, 2, "info")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНЫЙ ЦИКЛ
-- ═══════════════════════════════════════════════════════════════

spawn(function()
    while ScreenGui.Parent do
        task.wait(Config.ScanDelay)
        
        StatusInfo.Text = string.format("Собрано: %d | 🧠 %d | 🎁 %d", 
            Stats.Collected, Stats.BrainrotsCollected, Stats.LuckyBlocksCollected)
        
        if not Config.Farming then 
            FlyStatus.Text = "✈️ Полёт: Ожидание"
            continue 
        end
        
        local char = GetCharacter()
        local root = GetRootPart()
        if not char or not root then continue end
        
        -- Ищем предметы
        local items = FindAllCollectibles()
        
        if #items > 0 then
            StatusTitle.Text = "Статус: 🔍 Найдено: " .. #items
            FlyStatus.Text = "✈️ Полёт: Готов к вылету"
        else
            StatusTitle.Text = "Статус: 🟢 Сканирование..."
            FlyStatus.Text = "✈️ Полёт: Поиск целей"
        end
        
        for _, item in ipairs(items) do
            if not Config.Farming then break end
            if not item.Object or not item.Object.Parent then continue end
            
            if CollectItemWithFlight(item) then
                Stats.Collected = Stats.Collected + 1
                
                if item.Type == "Brainrot" or item.Type == "Unknown" then
                    Stats.BrainrotsCollected = Stats.BrainrotsCollected + 1
                else
                    Stats.LuckyBlocksCollected = Stats.LuckyBlocksCollected + 1
                end
                
                Notify(
                    item.Rarity .. " " .. item.Type .. "!",
                    "Успешно собран",
                    2,
                    "collect"
                )
            end
            
            task.wait(0.5)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- АНТИ-АФК
-- ═══════════════════════════════════════════════════════════════

spawn(function()
    while ScreenGui.Parent do
        task.wait(25)
        if Config.AntiAFK then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            
            local hum = GetHumanoid()
            if hum and not Config.Farming then
                hum:Move(Vector3.new(0, 0, 0))
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- АНИМАЦИИ
-- ═══════════════════════════════════════════════════════════════

spawn(function()
    local hue = 0
    while ScreenGui.Parent do
        hue = (hue + 0.005) % 1
        local color = Color3.fromHSV(hue, 0.6, 0.9)
        MainStroke.Color = color
        MiniStroke.Color = color
        task.wait(0.03)
    end
end)

spawn(function()
    while ScreenGui.Parent do
        if MiniButton.Visible then
            TweenService:Create(MiniButton, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 60, 0, 60)}):Play()
            task.wait(0.8)
            TweenService:Create(MiniButton, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 55, 0, 55)}):Play()
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

task.delay(0.5, function()
    Notify("Добро пожаловать!", "Плавный полёт v3.0", 3, "fly")
end)

-- ═══════════════════════════════════════════════════════════════
print("═══════════════════════════════════════════════════════════")
print("  🧠 ESCAPE TSUNAMI BRAINROT FARM v3.0")
print("  ✈️ Плавный полёт: Взлёт → Полёт → Спуск")
print("  📱 Поддержка мобильных устройств")
print("═══════════════════════════════════════════════════════════")
