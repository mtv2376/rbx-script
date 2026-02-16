
--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║         ESCAPE TSUNAMI BRAINROT FARM v4.0                    ║
    ║         + АНТИКИЛЛ СИСТЕМА                                   ║
    ║         God Mode + NoClip + Стабильный полёт                 ║
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
    FlyHeight = 50,
    FlySpeed = 150,
    VerticalSpeed = 100,
    DescendSpeed = 200,
    
    -- АНТИКИЛЛ СИСТЕМА
    AntiKill = true,
    GodMode = true,
    NoClip = true,
    AntiVoid = true,
    AutoRespawn = true,
    FreezeOnCollect = true,
    SafeHeight = 100,
    
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
    LuckyBlocksCollected = 0,
    Deaths = 0,
    Revives = 0
}

-- Состояние полёта
local IsFlying = false
local FlyBodyVelocity = nil
local FlyBodyGyro = nil
local AntiKillConnection = nil
local NoClipConnection = nil
local LastSafePosition = nil

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ GUI
-- ═══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BrainrotFarmV4"
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
    Error = Color3.fromRGB(255, 80, 80),
    Shield = Color3.fromRGB(100, 200, 255)
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
        fly = Color3.fromRGB(100, 200, 255),
        shield = Theme.Shield
    }
    
    local icons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌",
        collect = "🎁",
        fly = "✈️",
        shield = "🛡️"
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
MainFrame.Size = IsMobile and UDim2.new(0.95, 0, 0.92, 0) or UDim2.new(0, 500, 0, 720)
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
Header.Size = UDim2.new(1, 0, 0, 58)
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
Logo.Size = UDim2.new(0, 48, 0, 48)
Logo.Position = UDim2.new(0, 8, 0.5, -24)
Logo.BackgroundTransparency = 1
Logo.Text = "🧠"
Logo.TextSize = 32
Logo.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 0, 26)
Title.Position = UDim2.new(0, 60, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "BRAINROT FARM"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 200, 0, 14)
Subtitle.Position = UDim2.new(0, 60, 0, 34)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "v4.0 - AntiKill System"
Subtitle.TextColor3 = Color3.fromRGB(200, 200, 220)
Subtitle.TextSize = 10
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Кнопки
local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(0, 85, 0, 38)
BtnContainer.Position = UDim2.new(1, -95, 0.5, -19)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = Header

local BtnLayout = Instance.new("UIListLayout")
BtnLayout.FillDirection = Enum.FillDirection.Horizontal
BtnLayout.Padding = UDim.new(0, 6)
BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
BtnLayout.Parent = BtnContainer

local function CreateHeaderBtn(icon, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 36, 0, 36)
    Btn.BackgroundColor3 = color
    Btn.Text = icon
    Btn.TextSize = 15
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
StatusPanel.Size = UDim2.new(1, -20, 0, 140)
StatusPanel.Position = UDim2.new(0, 10, 0, 63)
StatusPanel.BackgroundColor3 = Theme.Card
StatusPanel.BorderSizePixel = 0
StatusPanel.Parent = MainFrame
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 12)

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Size = UDim2.new(0, 45, 0, 45)
StatusIcon.Position = UDim2.new(0, 10, 0, 10)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "⏸️"
StatusIcon.TextSize = 28
StatusIcon.Parent = StatusPanel

local StatusTitle = Instance.new("TextLabel")
StatusTitle.Size = UDim2.new(0.5, -65, 0, 18)
StatusTitle.Position = UDim2.new(0, 60, 0, 10)
StatusTitle.BackgroundTransparency = 1
StatusTitle.Text = "Статус: Ожидание"
StatusTitle.TextColor3 = Theme.Text
StatusTitle.TextSize = 12
StatusTitle.Font = Enum.Font.GothamBold
StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
StatusTitle.Parent = StatusPanel

local StatusInfo = Instance.new("TextLabel")
StatusInfo.Size = UDim2.new(0.5, -65, 0, 16)
StatusInfo.Position = UDim2.new(0, 60, 0, 30)
StatusInfo.BackgroundTransparency = 1
StatusInfo.Text = "Собрано: 0 | 🧠 0 | 🎁 0"
StatusInfo.TextColor3 = Theme.TextDim
StatusInfo.TextSize = 10
StatusInfo.Font = Enum.Font.Gotham
StatusInfo.TextXAlignment = Enum.TextXAlignment.Left
StatusInfo.Parent = StatusPanel

local FlyStatus = Instance.new("TextLabel")
FlyStatus.Size = UDim2.new(0.5, -65, 0, 16)
FlyStatus.Position = UDim2.new(0, 60, 0, 48)
FlyStatus.BackgroundTransparency = 1
FlyStatus.Text = "✈️ Полёт: Ожидание"
FlyStatus.TextColor3 = Color3.fromRGB(100, 200, 255)
FlyStatus.TextSize = 10
FlyStatus.Font = Enum.Font.Gotham
FlyStatus.TextXAlignment = Enum.TextXAlignment.Left
FlyStatus.Parent = StatusPanel

-- АНТИКИЛЛ СТАТУС
local ShieldStatus = Instance.new("TextLabel")
ShieldStatus.Size = UDim2.new(0.5, -65, 0, 16)
ShieldStatus.Position = UDim2.new(0, 60, 0, 66)
ShieldStatus.BackgroundTransparency = 1
ShieldStatus.Text = "🛡️ Защита: Активна"
ShieldStatus.TextColor3 = Theme.Shield
ShieldStatus.TextSize = 10
ShieldStatus.Font = Enum.Font.GothamBold
ShieldStatus.TextXAlignment = Enum.TextXAlignment.Left
ShieldStatus.Parent = StatusPanel

-- Прогресс бар
local HoldProgressBG = Instance.new("Frame")
HoldProgressBG.Size = UDim2.new(0.5, -20, 0, 14)
HoldProgressBG.Position = UDim2.new(0, 60, 0, 88)
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
HoldProgressText.Text = "⌨️ E: —"
HoldProgressText.TextColor3 = Color3.fromRGB(255, 255, 255)
HoldProgressText.TextSize = 8
HoldProgressText.Font = Enum.Font.GothamBold
HoldProgressText.Parent = HoldProgressBG

-- Кнопка Start/Stop
local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(0, 125, 0, 90)
StartButton.Position = UDim2.new(1, -140, 0.5, -45)
StartButton.BackgroundColor3 = Theme.Success
StartButton.Text = "▶️ СТАРТ"
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.TextSize = 15
StartButton.Font = Enum.Font.GothamBold
StartButton.Parent = StatusPanel
Instance.new("UICorner", StartButton).CornerRadius = UDim.new(0, 12)

-- ═══════════════════════════════════════════════════════════════
-- ТАБЫ
-- ═══════════════════════════════════════════════════════════════
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 0, 40)
TabContainer.Position = UDim2.new(0, 10, 0, 208)
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
    {Name = "🎁", FullName = "Блоки"},
    {Name = "🛡️", FullName = "АнтиКилл"},
    {Name = "✈️", FullName = "Полёт"},
    {Name = "⚙️", FullName = "Настройки"}
}

local TabButtons = {}
local TabContents = {}
local CurrentTab = 1

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -265)
ContentContainer.Position = UDim2.new(0, 10, 0, 253)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ClipsDescendants = true
ContentContainer.Parent = MainFrame

for i, tab in ipairs(Tabs) do
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, IsMobile and 70 or 88, 0, 30)
    TabBtn.BackgroundColor3 = i == 1 and Theme.Primary or Color3.fromRGB(50, 45, 75)
    TabBtn.Text = IsMobile and tab.Name or (tab.Name .. " " .. tab.FullName)
    TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabBtn.TextSize = IsMobile and 14 or 10
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
    Layout.Padding = UDim.new(0, 6)
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
    Section.Size = UDim2.new(1, 0, 0, 30)
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
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Section
end

local function CreateRarityToggle(parent, rarityName, configTable)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, 42)
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
    NameLabel.Size = UDim2.new(0.6, -20, 1, 0)
    NameLabel.Position = UDim2.new(0, 20, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = rarityName
    NameLabel.TextColor3 = RarityColors[rarityName] or Theme.Text
    NameLabel.TextSize = 12
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Toggle
    
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 45, 0, 22)
    SwitchBG.Position = UDim2.new(1, -55, 0.5, -11)
    SwitchBG.BackgroundColor3 = configTable[rarityName] and Theme.Success or Color3.fromRGB(60, 60, 80)
    SwitchBG.Parent = Toggle
    Instance.new("UICorner", SwitchBG).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = configTable[rarityName] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
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
            Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
    end)
end

local function CreateToggle(parent, name, configKey, desc, color)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, desc and 50 or 40)
    Toggle.BackgroundColor3 = Theme.Card
    Toggle.BorderSizePixel = 0
    Toggle.Parent = parent
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.65, 0, 0, 18)
    NameLabel.Position = UDim2.new(0, 12, 0, desc and 7 or 11)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = color or Theme.Text
    NameLabel.TextSize = 11
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Toggle
    
    if desc then
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(0.65, 0, 0, 14)
        DescLabel.Position = UDim2.new(0, 12, 0, 26)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = desc
        DescLabel.TextColor3 = Theme.TextDim
        DescLabel.TextSize = 9
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.Parent = Toggle
    end
    
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 45, 0, 22)
    SwitchBG.Position = UDim2.new(1, -55, 0.5, -11)
    SwitchBG.BackgroundColor3 = Config[configKey] and Theme.Success or Color3.fromRGB(60, 60, 80)
    SwitchBG.Parent = Toggle
    Instance.new("UICorner", SwitchBG).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = Config[configKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
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
            Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
    end)
end

local function CreateSlider(parent, name, configKey, min, max, step)
    step = step or 1
    
    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, 0, 0, 52)
    Slider.BackgroundColor3 = Theme.Card
    Slider.BorderSizePixel = 0
    Slider.Parent = parent
    Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.6, 0, 0, 18)
    NameLabel.Position = UDim2.new(0, 12, 0, 6)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Theme.Text
    NameLabel.TextSize = 10
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Slider
    
    local ValueBG = Instance.new("Frame")
    ValueBG.Size = UDim2.new(0, 45, 0, 18)
    ValueBG.Position = UDim2.new(1, -55, 0, 5)
    ValueBG.BackgroundColor3 = Theme.Primary
    ValueBG.Parent = Slider
    Instance.new("UICorner", ValueBG).CornerRadius = UDim.new(0, 5)
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(1, 0, 1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(Config[configKey])
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 9
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Parent = ValueBG
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -24, 0, 8)
    SliderBar.Position = UDim2.new(0, 12, 0, 35)
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
    Button.Size = UDim2.new(1, 0, 0, 40)
    Button.BackgroundColor3 = color or Theme.Primary
    Button.Text = ""
    Button.Parent = parent
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 10)
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 32, 1, 0)
    Icon.Position = UDim2.new(0, 8, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = icon or ""
    Icon.TextSize = 16
    Icon.Parent = Button
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -45, 1, 0)
    Label.Position = UDim2.new(0, 42, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 11
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

-- ТАБ 3: АНТИКИЛЛ
CreateSection(TabContents[3], "🛡️ ГЛАВНАЯ ЗАЩИТА", "🛡️")
CreateToggle(TabContents[3], "🛡️ АнтиКилл система", "AntiKill", "Полная защита от смерти", Theme.Shield)
CreateToggle(TabContents[3], "❤️ Бессмертие (God Mode)", "GodMode", "Бесконечное здоровье", Color3.fromRGB(255, 100, 100))
CreateToggle(TabContents[3], "👻 NoClip", "NoClip", "Проход сквозь стены", Color3.fromRGB(150, 150, 255))
CreateToggle(TabContents[3], "🕳️ Анти-Войд", "AntiVoid", "Защита от падения", Color3.fromRGB(255, 150, 100))
CreateToggle(TabContents[3], "🔄 Авто-Респавн", "AutoRespawn", "Автоматическое возрождение", Color3.fromRGB(100, 255, 150))
CreateToggle(TabContents[3], "🧊 Заморозка при сборе", "FreezeOnCollect", "Стабилизация при сборе", Color3.fromRGB(150, 220, 255))

CreateSection(TabContents[3], "⚙️ НАСТРОЙКИ БЕЗОПАСНОСТИ", "⚙️")
CreateSlider(TabContents[3], "Безопасная высота", "SafeHeight", 50, 200, 10)

CreateSection(TabContents[3], "📊 СТАТИСТИКА ЗАЩИТЫ", "📊")

local ProtectStats = Instance.new("Frame")
ProtectStats.Size = UDim2.new(1, 0, 0, 70)
ProtectStats.BackgroundColor3 = Theme.Card
ProtectStats.Parent = TabContents[3]
Instance.new("UICorner", ProtectStats).CornerRadius = UDim.new(0, 10)

local ProtectText = Instance.new("TextLabel")
ProtectText.Name = "ProtectText"
ProtectText.Size = UDim2.new(1, -20, 1, -10)
ProtectText.Position = UDim2.new(0, 10, 0, 5)
ProtectText.BackgroundTransparency = 1
ProtectText.Text = "💀 Смертей предотвращено: 0\n🔄 Авто-воскрешений: 0\n🛡️ Статус: Ожидание"
ProtectText.TextColor3 = Theme.TextDim
ProtectText.TextSize = 11
ProtectText.Font = Enum.Font.Gotham
ProtectText.TextXAlignment = Enum.TextXAlignment.Left
ProtectText.TextYAlignment = Enum.TextYAlignment.Center
ProtectText.Parent = ProtectStats

-- ТАБ 4: ПОЛЁТ
CreateSection(TabContents[4], "НАСТРОЙКИ ПОЛЁТА", "✈️")
CreateSlider(TabContents[4], "Высота полёта", "FlyHeight", 20, 150, 10)
CreateSlider(TabContents[4], "Скорость полёта", "FlySpeed", 50, 300, 10)
CreateSlider(TabContents[4], "Скорость подъёма", "VerticalSpeed", 50, 200, 10)
CreateSlider(TabContents[4], "Скорость спуска", "DescendSpeed", 100, 400, 20)

CreateSection(TabContents[4], "УДЕРЖАНИЕ E", "⌨️")
CreateSlider(TabContents[4], "Время удержания (сек)", "HoldDuration", 1, 6, 0.5)

-- ТАБ 5: НАСТРОЙКИ
CreateSection(TabContents[5], "ОСНОВНЫЕ", "⚙️")
CreateToggle(TabContents[5], "Анти-АФК", "AntiAFK", "Не кикает за бездействие")
CreateToggle(TabContents[5], "Авто-сбор", "AutoCollect", "Автоматически собирать")
CreateToggle(TabContents[5], "Возврат на базу", "TeleportBack", "Возвращаться после сбора")

CreateSection(TabContents[5], "ТАЙМИНГИ", "⏱️")
CreateSlider(TabContents[5], "Задержка после сбора", "CollectDelay", 0.1, 2, 0.1)
CreateSlider(TabContents[5], "Частота сканирования", "ScanDelay", 0.2, 2, 0.1)

CreateSection(TabContents[5], "ДЕЙСТВИЯ", "⚡")

CreateButton(TabContents[5], "Сохранить базу", "📍", Color3.fromRGB(80, 150, 200), function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        Config.SavedPosition = root.CFrame
        LastSafePosition = root.CFrame
        Notify("База", "Позиция сохранена", 2, "success")
    end
end)

CreateButton(TabContents[5], "Телепорт на базу", "🏠", Color3.fromRGB(100, 180, 100), function()
    if Config.SavedPosition then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = Config.SavedPosition end
    end
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
    StopAntiKill()
    ScreenGui:Destroy()
end)

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
-- 🛡️ АНТИКИЛЛ СИСТЕМА
-- ═══════════════════════════════════════════════════════════════

local function EnableGodMode()
    local char = GetCharacter()
    local hum = GetHumanoid()
    if not char or not hum then return end
    
    -- Бесконечное здоровье
    hum.Health = hum.MaxHealth
    
    -- Отключаем состояния смерти
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
end

local function EnableNoClip()
    local char = GetCharacter()
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function DisableNoClip()
    local char = GetCharacter()
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
        end
    end
end

local function CheckAntiVoid()
    local root = GetRootPart()
    if not root then return end
    
    if root.Position.Y < -50 then
        if LastSafePosition then
            root.CFrame = LastSafePosition
        elseif Config.SavedPosition then
            root.CFrame = Config.SavedPosition
        else
            root.CFrame = CFrame.new(0, Config.SafeHeight, 0)
        end
        Stats.Revives = Stats.Revives + 1
        Notify("🛡️ Анти-Войд", "Спасён от падения!", 2, "shield")
    end
end

local function SaveSafePosition()
    local root = GetRootPart()
    if root and root.Position.Y > 0 then
        LastSafePosition = root.CFrame
    end
end

local function StartAntiKill()
    if AntiKillConnection then return end
    
    AntiKillConnection = RunService.Heartbeat:Connect(function()
        if not Config.AntiKill then return end
        
        local char = GetCharacter()
        local hum = GetHumanoid()
        local root = GetRootPart()
        
        if not char or not hum or not root then return end
        
        -- God Mode
        if Config.GodMode then
            EnableGodMode()
        end
        
        -- NoClip
        if Config.NoClip then
            EnableNoClip()
        end
        
        -- Anti-Void
        if Config.AntiVoid then
            CheckAntiVoid()
        end
        
        -- Сохраняем безопасную позицию
        if not IsFlying and root.Position.Y > 10 then
            SaveSafePosition()
        end
        
        -- Обновляем статус
        local protectText = ProtectStats:FindFirstChild("ProtectText")
        if protectText then
            protectText.Text = string.format(
                "💀 Смертей предотвращено: %d\n🔄 Авто-воскрешений: %d\n🛡️ Статус: %s",
                Stats.Deaths,
                Stats.Revives,
                Config.AntiKill and "✅ Активна" or "❌ Отключена"
            )
        end
        
        ShieldStatus.Text = Config.AntiKill and "🛡️ Защита: ✅ Активна" or "🛡️ Защита: ❌ Отключена"
    end)
    
    -- Отслеживание смерти для авто-респавна
    local char = GetCharacter()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                Stats.Deaths = Stats.Deaths + 1
                if Config.AutoRespawn then
                    task.wait(0.5)
                    -- Принудительный респавн
                    LocalPlayer:LoadCharacter()
                    Stats.Revives = Stats.Revives + 1
                    Notify("🔄 Авто-респавн", "Возрождение...", 2, "shield")
                end
            end)
        end
    end
end

local function StopAntiKill()
    if AntiKillConnection then
        AntiKillConnection:Disconnect()
        AntiKillConnection = nil
    end
    
    DisableNoClip()
end

-- Авто-респавн отслеживание
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    
    if Config.AntiKill then
        StartAntiKill()
    end
    
    -- Восстанавливаем защиту
    local hum = char:WaitForChild("Humanoid", 5)
    if hum and Config.GodMode then
        EnableGodMode()
    end
    
    -- Отслеживаем смерть нового персонажа
    if hum then
        hum.Died:Connect(function()
            Stats.Deaths = Stats.Deaths + 1
            if Config.AutoRespawn then
                task.wait(0.5)
                pcall(function()
                    LocalPlayer:LoadCharacter()
                end)
                Stats.Revives = Stats.Revives + 1
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- СТАБИЛЬНЫЙ ПОЛЁТ С BODYMOVERS
-- ═══════════════════════════════════════════════════════════════

local function CreateFlyBody()
    local root = GetRootPart()
    local hum = GetHumanoid()
    if not root or not hum then return false end
    
    -- Удаляем старые
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
    if FlyBodyGyro then FlyBodyGyro:Destroy() end
    
    -- BodyVelocity для движения
    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.Parent = root
    
    -- BodyGyro для стабилизации вращения
    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyGyro.P = 9e4
    FlyBodyGyro.D = 1000
    FlyBodyGyro.CFrame = root.CFrame
    FlyBodyGyro.Parent = root
    
    -- Отключаем физику гуманоида
    hum.PlatformStand = true
    
    IsFlying = true
    return true
end

local function DestroyFlyBody()
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
    
    IsFlying = false
end

local function StableFlyTo(targetPosition, speed)
    local root = GetRootPart()
    if not root then return false end
    
    if not FlyBodyVelocity or not FlyBodyGyro then
        if not CreateFlyBody() then return false end
    end
    
    local startPos = root.Position
    local direction = (targetPosition - startPos)
    local distance = direction.Magnitude
    
    if distance < 2 then return true end
    
    direction = direction.Unit
    
    while Config.Farming do
        root = GetRootPart()
        if not root or not FlyBodyVelocity then return false end
        
        local currentPos = root.Position
        local remaining = (targetPosition - currentPos)
        local dist = remaining.Magnitude
        
        if dist < 3 then break end
        
        -- Плавное торможение при приближении
        local actualSpeed = math.min(speed, dist * 2)
        
        FlyBodyVelocity.Velocity = remaining.Unit * actualSpeed
        FlyBodyGyro.CFrame = CFrame.lookAt(currentPos, targetPosition)
        
        -- God Mode во время полёта
        if Config.GodMode then
            EnableGodMode()
        end
        
        -- NoClip во время полёта
        if Config.NoClip then
            EnableNoClip()
        end
        
        RunService.Heartbeat:Wait()
    end
    
    -- Останавливаемся
    if FlyBodyVelocity then
        FlyBodyVelocity.Velocity = Vector3.zero
    end
    
    -- Точная позиция
    root = GetRootPart()
    if root then
        root.CFrame = CFrame.new(targetPosition)
    end
    
    return true
end

local function FreezePosition()
    local root = GetRootPart()
    if not root then return end
    
    if FlyBodyVelocity then
        FlyBodyVelocity.Velocity = Vector3.zero
    end
    
    -- Создаём временную заморозку
    local freezePos = root.Position
    local freezeConnection
    
    freezeConnection = RunService.Heartbeat:Connect(function()
        root = GetRootPart()
        if root then
            root.CFrame = CFrame.new(freezePos) * CFrame.Angles(0, root.CFrame:ToEulerAnglesYXZ())
        end
    end)
    
    return function()
        if freezeConnection then
            freezeConnection:Disconnect()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ПЛАВНЫЙ ПОЛЁТ К ЦЕЛИ
-- ═══════════════════════════════════════════════════════════════

local function FlyToCollect(targetPosition, originalPosition)
    local root = GetRootPart()
    if not root then return false end
    
    -- Включаем защиту
    if Config.NoClip then EnableNoClip() end
    if Config.GodMode then EnableGodMode() end
    
    -- Создаём fly body
    if not CreateFlyBody() then return false end
    
    local startPos = root.Position
    local flyHeight = math.max(startPos.Y, targetPosition.Y) + Config.FlyHeight
    
    -- ═══ ПУТЬ К ЦЕЛИ ═══
    
    -- 1. Взлёт
    FlyStatus.Text = "✈️ Полёт: 🛫 Взлёт..."
    local upTarget = Vector3.new(startPos.X, flyHeight, startPos.Z)
    if not StableFlyTo(upTarget, Config.VerticalSpeed) then
        DestroyFlyBody()
        return false
    end
    task.wait(0.1)
    
    -- 2. Горизонтальный полёт
    FlyStatus.Text = "✈️ Полёт: ✈️ К цели..."
    local flyTarget = Vector3.new(targetPosition.X, flyHeight, targetPosition.Z)
    if not StableFlyTo(flyTarget, Config.FlySpeed) then
        DestroyFlyBody()
        return false
    end
    task.wait(0.1)
    
    -- 3. Спуск
    FlyStatus.Text = "✈️ Полёт: 🛬 Спуск..."
    local downTarget = Vector3.new(targetPosition.X, targetPosition.Y + 3, targetPosition.Z)
    if not StableFlyTo(downTarget, Config.DescendSpeed) then
        DestroyFlyBody()
        return false
    end
    
    return true
end

local function FlyBackToBase(originalPosition)
    local root = GetRootPart()
    if not root then return false end
    
    local currentPos = root.Position
    local flyHeight = math.max(currentPos.Y, originalPosition.Y) + Config.FlyHeight
    
    -- ═══ ПУТЬ НАЗАД ═══
    
    -- 1. Взлёт
    FlyStatus.Text = "✈️ Полёт: 🛫 Возврат..."
    local upTarget = Vector3.new(currentPos.X, flyHeight, currentPos.Z)
    if not StableFlyTo(upTarget, Config.VerticalSpeed) then
        DestroyFlyBody()
        return false
    end
    task.wait(0.1)
    
    -- 2. Горизонтальный полёт к базе
    FlyStatus.Text = "✈️ Полёт: ✈️ К базе..."
    local flyTarget = Vector3.new(originalPosition.X, flyHeight, originalPosition.Z)
    if not StableFlyTo(flyTarget, Config.FlySpeed) then
        DestroyFlyBody()
        return false
    end
    task.wait(0.1)
    
    -- 3. Спуск на базу
    FlyStatus.Text = "✈️ Полёт: 🛬 Посадка..."
    if not StableFlyTo(originalPosition, Config.DescendSpeed) then
        DestroyFlyBody()
        return false
    end
    
    -- Выключаем полёт
    DestroyFlyBody()
    
    FlyStatus.Text = "✈️ Полёт: ✅ На базе"
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- УДЕРЖАНИЕ E
-- ═══════════════════════════════════════════════════════════════

local function HoldKeyE(duration)
    duration = duration or Config.HoldDuration
    
    local startTime = tick()
    local unfreezeFunc = nil
    
    -- Замораживаем позицию при сборе
    if Config.FreezeOnCollect then
        unfreezeFunc = FreezePosition()
    end
    
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
        HoldProgressText.Text = string.format("⌨️ E: %.1fs", elapsed)
        
        -- Поддерживаем защиту
        if Config.GodMode then EnableGodMode() end
        
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
    
    -- Размораживаем
    if unfreezeFunc then
        unfreezeFunc()
    end
    
    HoldProgressFill.Size = UDim2.new(1, 0, 1, 0)
    HoldProgressText.Text = "✅ Собрано!"
    
    task.wait(0.2)
    HoldProgressFill.Size = UDim2.new(0, 0, 1, 0)
    HoldProgressText.Text = "⌨️ E: —"
    
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
-- СБОР ПРЕДМЕТА
-- ═══════════════════════════════════════════════════════════════

local function CollectItemWithFlight(item)
    local root = GetRootPart()
    if not root then return false end
    
    local basePosition = Config.SavedPosition and Config.SavedPosition.Position or root.Position
    
    StatusTitle.Text = "Статус: ✈️ Летим к " .. item.Rarity
    
    -- Летим к цели
    if not FlyToCollect(item.Position, basePosition) then
        DestroyFlyBody()
        return false
    end
    
    -- Собираем
    StatusTitle.Text = "Статус: ⌨️ Сбор..."
    FlyStatus.Text = "✈️ Полёт: 📦 Сбор"
    
    -- Активируем ProximityPrompt
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
    
    -- Возвращаемся
    if Config.TeleportBack then
        StatusTitle.Text = "Статус: ✈️ Возвращаемся"
        if not FlyBackToBase(basePosition) then
            DestroyFlyBody()
            -- Аварийный телепорт
            root = GetRootPart()
            if root then
                root.CFrame = CFrame.new(basePosition)
            end
        end
    else
        DestroyFlyBody()
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
            LastSafePosition = root.CFrame
            Notify("База", "Позиция автоматически сохранена", 2, "info")
        end
        
        -- Запускаем АнтиКилл
        if Config.AntiKill then
            StartAntiKill()
        end
        
        StartButton.Text = "⏹️ СТОП"
        StartButton.BackgroundColor3 = Theme.Error
        StatusTitle.Text = "Статус: 🟢 Активен"
        StatusIcon.Text = "🟢"
        
        Notify("Фарм запущен", "🛡️ АнтиКилл активирован", 2, "success")
    else
        StartButton.Text = "▶️ СТАРТ"
        StartButton.BackgroundColor3 = Theme.Success
        StatusTitle.Text = "Статус: ⏸️ Остановлен"
        StatusIcon.Text = "⏸️"
        FlyStatus.Text = "✈️ Полёт: Остановлен"
        
        -- Выключаем полёт
        DestroyFlyBody()
        
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
                    "🛡️ Защищённый сбор",
                    2,
                    "collect"
                )
            end
            
            task.wait(0.3)
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

-- Анимация появления
MainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
    Position = UDim2.new(0.5, 0, 0.5, 0)
}):Play()

-- Запускаем АнтиКилл
task.delay(0.5, function()
    if Config.AntiKill then
        StartAntiKill()
    end
    Notify("🛡️ АнтиКилл", "Система защиты активирована", 3, "shield")
end)

-- ═══════════════════════════════════════════════════════════════
print("═══════════════════════════════════════════════════════════")
print("  🧠 ESCAPE TSUNAMI BRAINROT FARM v4.0")
print("  🛡️ АнтиКилл система активна")
print("  ✈️ Стабильный полёт с BodyMovers")
print("═══════════════════════════════════════════════════════════")
