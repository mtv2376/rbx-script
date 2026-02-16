--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║         ESCAPE TSUNAMI BRAINROT FARM v2.0                    ║
    ║         Исправлен сбор через E (ProximityPrompt)             ║
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
local ProximityPromptService = game:GetService("ProximityPromptService")

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
    CollectDelay = 0.5,
    ScanDelay = 0.3,
    TeleportRange = 3,
    SavedPosition = nil,
    
    -- Выбранные редкости брейнротов
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
    
    -- Выбранные редкости лаки блоков
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

-- Ключевые слова для определения редкости
local RarityKeywords = {
    Common = {"common", "обычн", "обычный"},
    Uncommon = {"uncommon", "необычн", "необычный"},
    Rare = {"rare", "редк", "редкий"},
    Epic = {"epic", "эпич", "эпический"},
    Legendary = {"legendary", "legend", "легенд", "легендарн"},
    Mythic = {"mythic", "myth", "мифич", "мифический"},
    Secret = {"secret", "секрет", "секретн"},
    Divine = {"divine", "божеств", "божественн"},
    Exclusive = {"exclusive", "эксклюзив"}
}

-- Ключевые слова для поиска брейнротов
local BrainrotKeywords = {
    "brainrot", "brain", "rot", "skibidi", "toilet", "ohio", 
    "sigma", "rizz", "gyatt", "fanum", "tax", "mewing",
    "pet", "aura", "collectible", "npc", "spawn"
}

-- Ключевые слова для лаки блоков
local LuckyBlockKeywords = {
    "lucky", "block", "luckyblock", "crate", "chest", "box", 
    "reward", "loot", "prize", "gift", "present"
}

-- Статистика
local Stats = {
    Collected = 0,
    BrainrotsCollected = 0,
    LuckyBlocksCollected = 0,
    SessionTime = 0
}

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
    CardHover = Color3.fromRGB(40, 35, 65),
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
        collect = Color3.fromRGB(255, 215, 0)
    }
    
    local icons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌",
        collect = "🎁"
    }
    
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 75)
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
    Icon.Size = UDim2.new(0, 45, 0, 45)
    Icon.Position = UDim2.new(0, 15, 0.5, -22)
    Icon.BackgroundTransparency = 1
    Icon.Text = icons[notifType] or "ℹ️"
    Icon.TextSize = 26
    Icon.Parent = Notif
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -75, 0, 25)
    TitleLabel.Position = UDim2.new(0, 65, 0, 12)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Notif
    
    local MsgLabel = Instance.new("TextLabel")
    MsgLabel.Size = UDim2.new(1, -75, 0, 30)
    MsgLabel.Position = UDim2.new(0, 65, 0, 38)
    MsgLabel.BackgroundTransparency = 1
    MsgLabel.Text = message
    MsgLabel.TextColor3 = Theme.TextDim
    MsgLabel.TextSize = 12
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
MainFrame.Size = IsMobile and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0, 450, 0, 620)
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

-- Градиент
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
Header.Size = UDim2.new(1, 0, 0, 65)
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
Logo.Size = UDim2.new(0, 55, 0, 55)
Logo.Position = UDim2.new(0, 10, 0.5, -27)
Logo.BackgroundTransparency = 1
Logo.Text = "🧠"
Logo.TextSize = 38
Logo.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 250, 0, 30)
Title.Position = UDim2.new(0, 70, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "BRAINROT FARM"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 250, 0, 18)
Subtitle.Position = UDim2.new(0, 70, 0, 40)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "v2.0 - E Key Collection"
Subtitle.TextColor3 = Color3.fromRGB(200, 200, 220)
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Кнопки
local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(0, 90, 0, 45)
BtnContainer.Position = UDim2.new(1, -100, 0.5, -22)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = Header

local BtnLayout = Instance.new("UIListLayout")
BtnLayout.FillDirection = Enum.FillDirection.Horizontal
BtnLayout.Padding = UDim.new(0, 8)
BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
BtnLayout.Parent = BtnContainer

local function CreateHeaderBtn(icon, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 40, 0, 40)
    Btn.BackgroundColor3 = color
    Btn.Text = icon
    Btn.TextSize = 18
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
StatusPanel.Size = UDim2.new(1, -20, 0, 90)
StatusPanel.Position = UDim2.new(0, 10, 0, 70)
StatusPanel.BackgroundColor3 = Theme.Card
StatusPanel.BorderSizePixel = 0
StatusPanel.Parent = MainFrame
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 12)

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Size = UDim2.new(0, 60, 0, 60)
StatusIcon.Position = UDim2.new(0, 5, 0, 5)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "⏸️"
StatusIcon.TextSize = 35
StatusIcon.Parent = StatusPanel

local StatusTitle = Instance.new("TextLabel")
StatusTitle.Size = UDim2.new(0.55, -70, 0, 25)
StatusTitle.Position = UDim2.new(0, 65, 0, 10)
StatusTitle.BackgroundTransparency = 1
StatusTitle.Text = "Статус: Ожидание"
StatusTitle.TextColor3 = Theme.Text
StatusTitle.TextSize = 14
StatusTitle.Font = Enum.Font.GothamBold
StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
StatusTitle.Parent = StatusPanel

local StatusInfo = Instance.new("TextLabel")
StatusInfo.Size = UDim2.new(0.55, -70, 0, 20)
StatusInfo.Position = UDim2.new(0, 65, 0, 35)
StatusInfo.BackgroundTransparency = 1
StatusInfo.Text = "Собрано: 0"
StatusInfo.TextColor3 = Theme.TextDim
StatusInfo.TextSize = 11
StatusInfo.Font = Enum.Font.Gotham
StatusInfo.TextXAlignment = Enum.TextXAlignment.Left
StatusInfo.Parent = StatusPanel

local StatusInfo2 = Instance.new("TextLabel")
StatusInfo2.Size = UDim2.new(0.55, -70, 0, 20)
StatusInfo2.Position = UDim2.new(0, 65, 0, 55)
StatusInfo2.BackgroundTransparency = 1
StatusInfo2.Text = "🧠 0 | 🎁 0"
StatusInfo2.TextColor3 = Theme.TextDim
StatusInfo2.TextSize = 11
StatusInfo2.Font = Enum.Font.Gotham
StatusInfo2.TextXAlignment = Enum.TextXAlignment.Left
StatusInfo2.Parent = StatusPanel

-- Кнопка Start/Stop
local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(0, 130, 0, 60)
StartButton.Position = UDim2.new(1, -145, 0.5, -30)
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
TabContainer.Size = UDim2.new(1, -20, 0, 45)
TabContainer.Position = UDim2.new(0, 10, 0, 165)
TabContainer.BackgroundColor3 = Theme.Card
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
    {Name = "🧠", FullName = "Брейнроты"},
    {Name = "🎁", FullName = "Лаки Блоки"},
    {Name = "⚙️", FullName = "Настройки"}
}

local TabButtons = {}
local TabContents = {}
local CurrentTab = 1

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -230)
ContentContainer.Position = UDim2.new(0, 10, 0, 215)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ClipsDescendants = true
ContentContainer.Parent = MainFrame

for i, tab in ipairs(Tabs) do
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, IsMobile and 100 or 130, 0, 35)
    TabBtn.BackgroundColor3 = i == 1 and Theme.Primary or Color3.fromRGB(50, 45, 75)
    TabBtn.Text = tab.Name .. " " .. tab.FullName
    TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabBtn.TextSize = 13
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
    Layout.Padding = UDim.new(0, 8)
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
    Section.Size = UDim2.new(1, 0, 0, 35)
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
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Section
end

local function CreateRarityToggle(parent, rarityName, configTable)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, 55)
    Toggle.BackgroundColor3 = Theme.Card
    Toggle.BorderSizePixel = 0
    Toggle.Parent = parent
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 10)
    
    local RarityBadge = Instance.new("Frame")
    RarityBadge.Size = UDim2.new(0, 8, 0.7, 0)
    RarityBadge.Position = UDim2.new(0, 8, 0.15, 0)
    RarityBadge.BackgroundColor3 = RarityColors[rarityName] or Theme.Primary
    RarityBadge.BorderSizePixel = 0
    RarityBadge.Parent = Toggle
    Instance.new("UICorner", RarityBadge).CornerRadius = UDim.new(0, 4)
    
    local RarityIcon = Instance.new("TextLabel")
    RarityIcon.Size = UDim2.new(0, 35, 0, 35)
    RarityIcon.Position = UDim2.new(0, 25, 0.5, -17)
    RarityIcon.BackgroundColor3 = RarityColors[rarityName] or Theme.Primary
    RarityIcon.BackgroundTransparency = 0.8
    RarityIcon.Text = rarityName == "Common" and "⚪" or 
                      rarityName == "Uncommon" and "🟢" or
                      rarityName == "Rare" and "🔵" or
                      rarityName == "Epic" and "🟣" or
                      rarityName == "Legendary" and "🟡" or
                      rarityName == "Mythic" and "🔴" or
                      rarityName == "Secret" and "❤️" or
                      rarityName == "Divine" and "✨" or "💎"
    RarityIcon.TextSize = 20
    RarityIcon.Parent = Toggle
    Instance.new("UICorner", RarityIcon).CornerRadius = UDim.new(0, 8)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.5, -80, 0, 25)
    NameLabel.Position = UDim2.new(0, 70, 0.5, -12)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = rarityName
    NameLabel.TextColor3 = RarityColors[rarityName] or Theme.Text
    NameLabel.TextSize = 15
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Toggle
    
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 55, 0, 28)
    SwitchBG.Position = UDim2.new(1, -70, 0.5, -14)
    SwitchBG.BackgroundColor3 = configTable[rarityName] and Theme.Success or Color3.fromRGB(60, 60, 80)
    SwitchBG.Parent = Toggle
    Instance.new("UICorner", SwitchBG).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 22, 0, 22)
    Circle.Position = configTable[rarityName] and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
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
            Position = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        }):Play()
    end)
    
    return SwitchBG, Circle
end

local function CreateToggle(parent, name, configKey, desc)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, desc and 58 or 48)
    Toggle.BackgroundColor3 = Theme.Card
    Toggle.BorderSizePixel = 0
    Toggle.Parent = parent
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.65, 0, 0, 24)
    NameLabel.Position = UDim2.new(0, 15, 0, desc and 8 or 12)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Theme.Text
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
        DescLabel.TextColor3 = Theme.TextDim
        DescLabel.TextSize = 11
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.Parent = Toggle
    end
    
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 55, 0, 28)
    SwitchBG.Position = UDim2.new(1, -70, 0.5, -14)
    SwitchBG.BackgroundColor3 = Config[configKey] and Theme.Success or Color3.fromRGB(60, 60, 80)
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
            BackgroundColor3 = enabled and Theme.Success or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Position = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        }):Play()
    end)
end

local function CreateSlider(parent, name, configKey, min, max)
    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, 0, 0, 65)
    Slider.BackgroundColor3 = Theme.Card
    Slider.BorderSizePixel = 0
    Slider.Parent = parent
    Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 10)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.5, 0, 0, 24)
    NameLabel.Position = UDim2.new(0, 15, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Theme.Text
    NameLabel.TextSize = 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Slider
    
    local ValueBG = Instance.new("Frame")
    ValueBG.Size = UDim2.new(0, 55, 0, 24)
    ValueBG.Position = UDim2.new(1, -70, 0, 6)
    ValueBG.BackgroundColor3 = Theme.Primary
    ValueBG.Parent = Slider
    Instance.new("UICorner", ValueBG).CornerRadius = UDim.new(0, 6)
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(1, 0, 1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(Config[configKey])
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 12
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Parent = ValueBG
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -30, 0, 10)
    SliderBar.Position = UDim2.new(0, 15, 0, 45)
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
    Handle.Size = UDim2.new(0, 18, 0, 18)
    Handle.Position = UDim2.new(pct, -9, 0.5, -9)
    Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handle.Parent = SliderBar
    Instance.new("UICorner", Handle).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    
    local function Update(inputX)
        local barStart = SliderBar.AbsolutePosition.X
        local barWidth = SliderBar.AbsoluteSize.X
        local newPct = math.clamp((inputX - barStart) / barWidth, 0, 1)
        local newVal = min + (max - min) * newPct
        newVal = math.floor(newVal * 10) / 10
        
        Config[configKey] = newVal
        ValueLabel.Text = tostring(newVal)
        Fill.Size = UDim2.new(newPct, 0, 1, 0)
        Handle.Position = UDim2.new(newPct, -9, 0.5, -9)
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
    Button.Size = UDim2.new(1, 0, 0, 50)
    Button.BackgroundColor3 = color or Theme.Primary
    Button.Text = ""
    Button.Parent = parent
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 10)
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 45, 1, 0)
    Icon.Position = UDim2.new(0, 10, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = icon or ""
    Icon.TextSize = 22
    Icon.Parent = Button
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -65, 1, 0)
    Label.Position = UDim2.new(0, 55, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button
    
    Button.MouseButton1Click:Connect(callback)
end

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ КОНТЕНТА
-- ═══════════════════════════════════════════════════════════════

-- ТАБ 1: БРЕЙНРОТЫ
CreateSection(TabContents[1], "ВЫБЕРИТЕ РЕДКОСТИ", "🧠")

local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine", "Exclusive"}
local brainrotToggles = {}

for _, rarity in ipairs(rarities) do
    brainrotToggles[rarity] = {CreateRarityToggle(TabContents[1], rarity, Config.Brainrots)}
end

CreateSection(TabContents[1], "БЫСТРЫЙ ВЫБОР", "⚡")

CreateButton(TabContents[1], "Выбрать все", "✅", Theme.Success, function()
    for _, r in ipairs(rarities) do
        Config.Brainrots[r] = true
        local switchBG, circle = brainrotToggles[r][1], brainrotToggles[r][2]
        TweenService:Create(switchBG, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Success}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -25, 0.5, -11)}):Play()
    end
    Notify("Брейнроты", "Все редкости выбраны", 2, "success")
end)

CreateButton(TabContents[1], "Снять все", "❌", Theme.Error, function()
    for _, r in ipairs(rarities) do
        Config.Brainrots[r] = false
        local switchBG, circle = brainrotToggles[r][1], brainrotToggles[r][2]
        TweenService:Create(switchBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -11)}):Play()
    end
    Notify("Брейнроты", "Все редкости сняты", 2, "info")
end)

CreateButton(TabContents[1], "Только редкие+", "💎", Color3.fromRGB(180, 100, 255), function()
    for _, r in ipairs(rarities) do
        local enabled = r ~= "Common" and r ~= "Uncommon"
        Config.Brainrots[r] = enabled
        local switchBG, circle = brainrotToggles[r][1], brainrotToggles[r][2]
        TweenService:Create(switchBG, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Theme.Success or Color3.fromRGB(60, 60, 80)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)}):Play()
    end
    Notify("Брейнроты", "Выбраны: Rare и выше", 2, "success")
end)

-- ТАБ 2: ЛАКИ БЛОКИ
CreateSection(TabContents[2], "ВЫБЕРИТЕ РЕДКОСТИ", "🎁")

local luckyToggles = {}

for _, rarity in ipairs(rarities) do
    luckyToggles[rarity] = {CreateRarityToggle(TabContents[2], rarity, Config.LuckyBlocks)}
end

CreateSection(TabContents[2], "БЫСТРЫЙ ВЫБОР", "⚡")

CreateButton(TabContents[2], "Выбрать все", "✅", Theme.Success, function()
    for _, r in ipairs(rarities) do
        Config.LuckyBlocks[r] = true
        local switchBG, circle = luckyToggles[r][1], luckyToggles[r][2]
        TweenService:Create(switchBG, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Success}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -25, 0.5, -11)}):Play()
    end
    Notify("Лаки блоки", "Все редкости выбраны", 2, "success")
end)

CreateButton(TabContents[2], "Снять все", "❌", Theme.Error, function()
    for _, r in ipairs(rarities) do
        Config.LuckyBlocks[r] = false
        local switchBG, circle = luckyToggles[r][1], luckyToggles[r][2]
        TweenService:Create(switchBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -11)}):Play()
    end
    Notify("Лаки блоки", "Все редкости сняты", 2, "info")
end)

CreateButton(TabContents[2], "Только редкие+", "💎", Color3.fromRGB(180, 100, 255), function()
    for _, r in ipairs(rarities) do
        local enabled = r ~= "Common" and r ~= "Uncommon"
        Config.LuckyBlocks[r] = enabled
        local switchBG, circle = luckyToggles[r][1], luckyToggles[r][2]
        TweenService:Create(switchBG, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Theme.Success or Color3.fromRGB(60, 60, 80)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)}):Play()
    end
    Notify("Лаки блоки", "Выбраны: Rare и выше", 2, "success")
end)

-- ТАБ 3: НАСТРОЙКИ
CreateSection(TabContents[3], "ОСНОВНЫЕ", "⚙️")
CreateToggle(TabContents[3], "Анти-АФК", "AntiAFK", "Не кикает за бездействие")
CreateToggle(TabContents[3], "Авто-сбор", "AutoCollect", "Автоматически собирать")
CreateToggle(TabContents[3], "Телепорт назад", "TeleportBack", "Возвращаться после сбора")

CreateSection(TabContents[3], "ТАЙМИНГИ", "⏱️")
CreateSlider(TabContents[3], "Задержка сбора (сек)", "CollectDelay", 0.1, 2)
CreateSlider(TabContents[3], "Задержка скана (сек)", "ScanDelay", 0.1, 2)
CreateSlider(TabContents[3], "Дистанция ТП", "TeleportRange", 1, 10)

CreateSection(TabContents[3], "ДЕЙСТВИЯ", "⚡")
CreateButton(TabContents[3], "Сбросить статистику", "🔄", Color3.fromRGB(100, 100, 150), function()
    Stats.Collected = 0
    Stats.BrainrotsCollected = 0
    Stats.LuckyBlocksCollected = 0
    Notify("Статистика", "Сброшена", 2, "info")
end)

CreateButton(TabContents[3], "Сохранить позицию", "📍", Color3.fromRGB(80, 150, 200), function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        Config.SavedPosition = root.CFrame
        Notify("Позиция", "Сохранена", 2, "success")
    end
end)

CreateButton(TabContents[3], "Телепорт на позицию", "🏠", Color3.fromRGB(100, 180, 100), function()
    if Config.SavedPosition then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = Config.SavedPosition
        end
    else
        Notify("Ошибка", "Сохраните позицию сначала", 2, "error")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- МИНИ-КНОПКА
-- ═══════════════════════════════════════════════════════════════
local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(0, 60, 0, 60)
MiniButton.Position = UDim2.new(0, 15, 0.5, -30)
MiniButton.BackgroundColor3 = Theme.Primary
MiniButton.Text = "🧠"
MiniButton.TextSize = 32
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
    if dragMini and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
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
    if dragMain and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
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
-- ФУНКЦИЯ СБОРА ЧЕРЕЗ E (PROXIMITY PROMPT)
-- ═══════════════════════════════════════════════════════════════

local function FireProximityPrompt(prompt, holdDuration)
    holdDuration = holdDuration or prompt.HoldDuration
    
    -- Метод 1: fireproximityprompt (лучший)
    if fireproximityprompt then
        fireproximityprompt(prompt, holdDuration)
        return true
    end
    
    -- Метод 2: Через события
    local success = pcall(function()
        -- Симулируем начало взаимодействия
        prompt:InputHoldBegin()
        
        if holdDuration > 0 then
            task.wait(holdDuration + 0.1)
        else
            task.wait(0.1)
        end
        
        prompt:InputHoldEnd()
    end)
    
    if success then return true end
    
    -- Метод 3: Триггер напрямую
    success = pcall(function()
        prompt.Triggered:Fire()
    end)
    
    if success then return true end
    
    -- Метод 4: Через ProximityPromptService
    success = pcall(function()
        ProximityPromptService.PromptTriggered:Fire(prompt, LocalPlayer)
    end)
    
    return success
end

-- Симуляция нажатия E
local function PressE()
    -- Метод 1: VirtualInputManager
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    
    -- Метод 2: keypress
    if keypress and keyrelease then
        pcall(function()
            keypress(0x45) -- E key
            task.wait(0.05)
            keyrelease(0x45)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ОПРЕДЕЛЕНИЕ РЕДКОСТИ
-- ═══════════════════════════════════════════════════════════════

local function GetRarity(object)
    -- Проверяем имя объекта
    local name = object.Name:lower()
    
    -- Проверяем атрибуты
    local rarityAttr = object:GetAttribute("Rarity") or object:GetAttribute("rarity") or object:GetAttribute("RARITY")
    if rarityAttr then
        local attrLower = tostring(rarityAttr):lower()
        for rarity, keywords in pairs(RarityKeywords) do
            for _, keyword in ipairs(keywords) do
                if attrLower:find(keyword) then
                    return rarity
                end
            end
        end
    end
    
    -- Проверяем по имени объекта
    for rarity, keywords in pairs(RarityKeywords) do
        for _, keyword in ipairs(keywords) do
            if name:find(keyword) then
                return rarity
            end
        end
    end
    
    -- Проверяем в потомках (GUI, TextLabels)
    for _, desc in ipairs(object:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local text = desc.Text:lower()
            for rarity, keywords in pairs(RarityKeywords) do
                for _, keyword in ipairs(keywords) do
                    if text:find(keyword) then
                        return rarity
                    end
                end
            end
        end
    end
    
    -- Проверяем родителя
    if object.Parent then
        local parentName = object.Parent.Name:lower()
        for rarity, keywords in pairs(RarityKeywords) do
            for _, keyword in ipairs(keywords) do
                if parentName:find(keyword) then
                    return rarity
                end
            end
        end
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- ПОИСК ОБЪЕКТОВ
-- ═══════════════════════════════════════════════════════════════

local function IsBrainrot(object)
    local name = object.Name:lower()
    for _, keyword in ipairs(BrainrotKeywords) do
        if name:find(keyword) then
            return true
        end
    end
    return false
end

local function IsLuckyBlock(object)
    local name = object.Name:lower()
    for _, keyword in ipairs(LuckyBlockKeywords) do
        if name:find(keyword) then
            return true
        end
    end
    return false
end

local function FindAllCollectibles()
    local found = {}
    
    -- Ищем все ProximityPrompts в игре
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local parent = prompt.Parent
            if parent then
                local name = parent.Name:lower()
                local rarity = GetRarity(parent)
                
                -- Проверяем, является ли это брейнротом
                local isBrainrot = IsBrainrot(parent)
                if isBrainrot and rarity and Config.Brainrots[rarity] then
                    local pos = parent:IsA("Model") and parent:GetPivot().Position or 
                               parent:IsA("BasePart") and parent.Position or
                               prompt.Parent:IsA("BasePart") and prompt.Parent.Position
                    
                    if pos then
                        table.insert(found, {
                            Object = parent,
                            Prompt = prompt,
                            Position = pos,
                            Rarity = rarity,
                            Type = "Brainrot"
                        })
                    end
                end
                
                -- Проверяем, является ли это лаки блоком
                local isLucky = IsLuckyBlock(parent)
                if isLucky and rarity and Config.LuckyBlocks[rarity] then
                    local pos = parent:IsA("Model") and parent:GetPivot().Position or 
                               parent:IsA("BasePart") and parent.Position or
                               prompt.Parent:IsA("BasePart") and prompt.Parent.Position
                    
                    if pos then
                        table.insert(found, {
                            Object = parent,
                            Prompt = prompt,
                            Position = pos,
                            Rarity = rarity,
                            Type = "LuckyBlock"
                        })
                    end
                end
                
                -- Если редкость определена но тип неизвестен - проверяем просто по редкости
                if not isBrainrot and not isLucky and rarity then
                    -- Проверяем брейнроты
                    if Config.Brainrots[rarity] then
                        local pos = parent:IsA("Model") and parent:GetPivot().Position or 
                                   parent:IsA("BasePart") and parent.Position or
                                   prompt.Parent:IsA("BasePart") and prompt.Parent.Position
                        
                        if pos then
                            table.insert(found, {
                                Object = parent,
                                Prompt = prompt,
                                Position = pos,
                                Rarity = rarity,
                                Type = "Unknown"
                            })
                        end
                    end
                end
            end
        end
    end
    
    -- Также ищем модели без ProximityPrompt но с определённой редкостью
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and not obj:FindFirstChildOfClass("ProximityPrompt") then
            local rarity = GetRarity(obj)
            if rarity then
                local isBrainrot = IsBrainrot(obj)
                local isLucky = IsLuckyBlock(obj)
                
                if (isBrainrot and Config.Brainrots[rarity]) or (isLucky and Config.LuckyBlocks[rarity]) then
                    -- Проверяем есть ли ProximityPrompt в потомках
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                    local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                    
                    if pos then
                        table.insert(found, {
                            Object = obj,
                            Prompt = prompt,
                            Position = pos,
                            Rarity = rarity,
                            Type = isBrainrot and "Brainrot" or "LuckyBlock"
                        })
                    end
                end
            end
        end
    end
    
    return found
end

-- ═══════════════════════════════════════════════════════════════
-- ФУНКЦИЯ СБОРА
-- ═══════════════════════════════════════════════════════════════

local function CollectItem(item)
    local root = GetRootPart()
    if not root then return false end
    
    -- Сохраняем позицию
    local originalPosition = root.CFrame
    
    -- Телепортируемся к объекту
    local targetPos = item.Position + Vector3.new(0, Config.TeleportRange, 0)
    root.CFrame = CFrame.new(targetPos)
    
    task.wait(0.1)
    
    -- Пытаемся собрать через ProximityPrompt
    local collected = false
    
    if item.Prompt then
        -- Способ 1: fireproximityprompt
        collected = FireProximityPrompt(item.Prompt)
        task.wait(Config.CollectDelay)
    end
    
    -- Если не сработало, пробуем найти промпт рядом
    if not collected then
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local promptPos = prompt.Parent and prompt.Parent:IsA("BasePart") and prompt.Parent.Position
                if promptPos then
                    local dist = (promptPos - item.Position).Magnitude
                    if dist < 15 then
                        FireProximityPrompt(prompt)
                        task.wait(0.2)
                        collected = true
                        break
                    end
                end
            end
        end
    end
    
    -- Дополнительно нажимаем E
    PressE()
    task.wait(0.1)
    PressE()
    
    -- Касаемся объекта
    if item.Object and item.Object:IsA("BasePart") then
        pcall(function()
            firetouchinterest(root, item.Object, 0)
            task.wait(0.1)
            firetouchinterest(root, item.Object, 1)
        end)
    elseif item.Object and item.Object:IsA("Model") then
        local part = item.Object.PrimaryPart or item.Object:FindFirstChildOfClass("BasePart")
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
        root.CFrame = originalPosition
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
        end
        
        StartButton.Text = "⏹️ СТОП"
        StartButton.BackgroundColor3 = Theme.Error
        StatusTitle.Text = "Статус: 🟢 Активен"
        StatusIcon.Text = "🟢"
        
        Notify("Фарм запущен", "Сканирование началось", 2, "success")
    else
        StartButton.Text = "▶️ СТАРТ"
        StartButton.BackgroundColor3 = Theme.Success
        StatusTitle.Text = "Статус: ⏸️ Остановлен"
        StatusIcon.Text = "⏸️"
        
        Notify("Фарм остановлен", "Собрано: " .. Stats.Collected, 2, "info")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНЫЙ ЦИКЛ
-- ═══════════════════════════════════════════════════════════════

spawn(function()
    while ScreenGui.Parent do
        task.wait(Config.ScanDelay)
        
        -- Обновляем статус
        StatusInfo.Text = "Собрано: " .. Stats.Collected
        StatusInfo2.Text = "🧠 " .. Stats.BrainrotsCollected .. " | 🎁 " .. Stats.LuckyBlocksCollected
        
        if not Config.Farming then continue end
        
        local char = GetCharacter()
        local root = GetRootPart()
        if not char or not root then continue end
        
        -- Сохраняем позицию для возврата
        local returnPosition = root.CFrame
        
        -- Ищем все предметы
        local items = FindAllCollectibles()
        
        if #items > 0 then
            StatusTitle.Text = "Статус: 🔍 Найдено: " .. #items
        else
            StatusTitle.Text = "Статус: 🟢 Сканирование..."
        end
        
        for _, item in ipairs(items) do
            if not Config.Farming then break end
            
            -- Проверяем что объект ещё существует
            if not item.Object or not item.Object.Parent then continue end
            
            StatusTitle.Text = "Статус: 📍 " .. item.Rarity .. " " .. item.Type
            
            if CollectItem(item) then
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
            
            task.wait(0.2)
        end
        
        -- Возвращаемся на позицию
        if Config.TeleportBack and Config.SavedPosition then
            root.CFrame = Config.SavedPosition
        elseif Config.TeleportBack then
            root.CFrame = returnPosition
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- АНТИ-АФК
-- ═══════════════════════════════════════════════════════════════

spawn(function()
    while ScreenGui.Parent do
        task.wait(30)
        if Config.AntiAFK then
            -- VirtualUser
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            
            -- Движение
            local hum = GetHumanoid()
            if hum then
                hum:Move(Vector3.new(0, 0, 0))
                hum.Jump = true
            end
            
            -- Нажатие клавиши
            pcall(function()
                if keypress then
                    keypress(0x57) -- W
                    task.wait(0.1)
                    keyrelease(0x57)
                end
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

-- Пульсация
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

task.delay(0.5, function()
    Notify("Добро пожаловать!", "Brainrot Farm v2.0 - E Key Collection", 3, "success")
end)

-- ═══════════════════════════════════════════════════════════════
print("═══════════════════════════════════════════════════════════")
print("  🧠 ESCAPE TSUNAMI BRAINROT FARM v2.0")
print("  ✅ Исправлен сбор через E (ProximityPrompt)")
print("  📱 Поддержка мобильных устройств")
print("═══════════════════════════════════════════════════════════")
