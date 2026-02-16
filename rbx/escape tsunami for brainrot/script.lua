--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║         ESCAPE TSUNAMI BRAINROT FARM v1.0                    ║
    ║         Автоматический сбор брейнротов и лаки блоков         ║
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
    CollectDelay = 0.3,
    ScanDelay = 0.5,
    TeleportRange = 5,
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

-- Ключевые слова для поиска
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
MainFrame.Size = IsMobile and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0, 450, 0, 600)
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

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 20)
HeaderFix.Position = UDim2.new(0, 0, 1, -20)
HeaderFix.BackgroundColor3 = Theme.Primary
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

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
Subtitle.Text = "Escape Tsunami Edition"
Subtitle.TextColor3 = Color3.fromRGB(200, 200, 220)
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Кнопки управления
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
    
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 44, 0, 44)}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 40, 0, 40)}):Play()
    end)
    Btn.MouseButton1Click:Connect(callback)
    
    return Btn
end

local MinBtn = CreateHeaderBtn("—", Color3.fromRGB(80, 80, 120), function() end)
local CloseBtn = CreateHeaderBtn("✕", Color3.fromRGB(200, 60, 60), function() end)

-- ═══════════════════════════════════════════════════════════════
-- СТАТУС ПАНЕЛЬ
-- ═══════════════════════════════════════════════════════════════
local StatusPanel = Instance.new("Frame")
StatusPanel.Size = UDim2.new(1, -20, 0, 80)
StatusPanel.Position = UDim2.new(0, 10, 0, 70)
StatusPanel.BackgroundColor3 = Theme.Card
StatusPanel.BorderSizePixel = 0
StatusPanel.Parent = MainFrame
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 12)

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Size = UDim2.new(0, 60, 1, 0)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "⏸️"
StatusIcon.TextSize = 35
StatusIcon.Parent = StatusPanel

local StatusTitle = Instance.new("TextLabel")
StatusTitle.Size = UDim2.new(0.5, -70, 0, 25)
StatusTitle.Position = UDim2.new(0, 65, 0, 15)
StatusTitle.BackgroundTransparency = 1
StatusTitle.Text = "Статус: Ожидание"
StatusTitle.TextColor3 = Theme.Text
StatusTitle.TextSize = 14
StatusTitle.Font = Enum.Font.GothamBold
StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
StatusTitle.Parent = StatusPanel

local StatusInfo = Instance.new("TextLabel")
StatusInfo.Size = UDim2.new(0.5, -70, 0, 20)
StatusInfo.Position = UDim2.new(0, 65, 0, 42)
StatusInfo.BackgroundTransparency = 1
StatusInfo.Text = "Собрано: 0 | Брейнроты: 0 | Блоки: 0"
StatusInfo.TextColor3 = Theme.TextDim
StatusInfo.TextSize = 11
StatusInfo.Font = Enum.Font.Gotham
StatusInfo.TextXAlignment = Enum.TextXAlignment.Left
StatusInfo.Parent = StatusPanel

-- Кнопка Start/Stop
local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(0, 120, 0, 50)
StartButton.Position = UDim2.new(1, -135, 0.5, -25)
StartButton.BackgroundColor3 = Theme.Success
StartButton.Text = "▶️ СТАРТ"
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.TextSize = 14
StartButton.Font = Enum.Font.GothamBold
StartButton.Parent = StatusPanel
Instance.new("UICorner", StartButton).CornerRadius = UDim.new(0, 10)

-- ═══════════════════════════════════════════════════════════════
-- ТАБЫ
-- ═══════════════════════════════════════════════════════════════
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 0, 45)
TabContainer.Position = UDim2.new(0, 10, 0, 155)
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
ContentContainer.Size = UDim2.new(1, -20, 1, -220)
ContentContainer.Position = UDim2.new(0, 10, 0, 205)
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
    
    -- Цветовая метка редкости
    local RarityBadge = Instance.new("Frame")
    RarityBadge.Size = UDim2.new(0, 8, 0.7, 0)
    RarityBadge.Position = UDim2.new(0, 8, 0.15, 0)
    RarityBadge.BackgroundColor3 = RarityColors[rarityName] or Theme.Primary
    RarityBadge.BorderSizePixel = 0
    RarityBadge.Parent = Toggle
    Instance.new("UICorner", RarityBadge).CornerRadius = UDim.new(0, 4)
    
    -- Иконка редкости
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
    NameLabel.Size = UDim2.new(0.5, -80, 0, 20)
    NameLabel.Position = UDim2.new(0, 70, 0, 10)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = rarityName
    NameLabel.TextColor3 = RarityColors[rarityName] or Theme.Text
    NameLabel.TextSize = 15
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Toggle
    
    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(0.5, -80, 0, 16)
    DescLabel.Position = UDim2.new(0, 70, 0, 32)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Text = "Нажмите чтобы " .. (configTable[rarityName] and "отключить" or "включить")
    DescLabel.TextColor3 = Theme.TextDim
    DescLabel.TextSize = 11
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.Parent = Toggle
    
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
        
        DescLabel.Text = "Нажмите чтобы " .. (enabled and "отключить" or "включить")
        
        TweenService:Create(SwitchBG, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Theme.Success or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Position = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        }):Play()
        
        -- Подсветка
        TweenService:Create(Toggle, TweenInfo.new(0.1), {
            BackgroundColor3 = enabled and Color3.fromRGB(40, 55, 45) or Theme.Card
        }):Play()
        task.wait(0.15)
        TweenService:Create(Toggle, TweenInfo.new(0.2), {
            BackgroundColor3 = Theme.Card
        }):Play()
    end)
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
    
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 54)}):Play()
    end)
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 50)}):Play()
    end)
    Button.MouseButton1Click:Connect(callback)
end

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ КОНТЕНТА
-- ═══════════════════════════════════════════════════════════════

-- ТАБ 1: БРЕЙНРОТЫ
CreateSection(TabContents[1], "ВЫБЕРИТЕ РЕДКОСТИ", "🧠")

local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine", "Exclusive"}

for _, rarity in ipairs(rarities) do
    CreateRarityToggle(TabContents[1], rarity, Config.Brainrots)
end

CreateSection(TabContents[1], "БЫСТРЫЙ ВЫБОР", "⚡")

CreateButton(TabContents[1], "Выбрать все", "✅", Theme.Success, function()
    for _, r in ipairs(rarities) do
        Config.Brainrots[r] = true
    end
    Notify("Брейнроты", "Все редкости выбраны", 2, "success")
    -- Обновляем UI
    for _, child in ipairs(TabContents[1]:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("TextButton") then
            local switchBG = child:FindFirstChild("Frame", true)
            if switchBG and switchBG.Size == UDim2.new(0, 55, 0, 28) then
                TweenService:Create(switchBG, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Success}):Play()
            end
        end
    end
end)

CreateButton(TabContents[1], "Снять все", "❌", Theme.Error, function()
    for _, r in ipairs(rarities) do
        Config.Brainrots[r] = false
    end
    Notify("Брейнроты", "Все редкости сняты", 2, "info")
end)

CreateButton(TabContents[1], "Только редкие+", "💎", Color3.fromRGB(180, 100, 255), function()
    for _, r in ipairs(rarities) do
        Config.Brainrots[r] = r ~= "Common" and r ~= "Uncommon"
    end
    Notify("Брейнроты", "Выбраны: Rare и выше", 2, "success")
end)

-- ТАБ 2: ЛАКИ БЛОКИ
CreateSection(TabContents[2], "ВЫБЕРИТЕ РЕДКОСТИ", "🎁")

for _, rarity in ipairs(rarities) do
    CreateRarityToggle(TabContents[2], rarity, Config.LuckyBlocks)
end

CreateSection(TabContents[2], "БЫСТРЫЙ ВЫБОР", "⚡")

CreateButton(TabContents[2], "Выбрать все", "✅", Theme.Success, function()
    for _, r in ipairs(rarities) do
        Config.LuckyBlocks[r] = true
    end
    Notify("Лаки блоки", "Все редкости выбраны", 2, "success")
end)

CreateButton(TabContents[2], "Снять все", "❌", Theme.Error, function()
    for _, r in ipairs(rarities) do
        Config.LuckyBlocks[r] = false
    end
    Notify("Лаки блоки", "Все редкости сняты", 2, "info")
end)

CreateButton(TabContents[2], "Только редкие+", "💎", Color3.fromRGB(180, 100, 255), function()
    for _, r in ipairs(rarities) do
        Config.LuckyBlocks[r] = r ~= "Common" and r ~= "Uncommon"
    end
    Notify("Лаки блоки", "Выбраны: Rare и выше", 2, "success")
end)

-- ТАБ 3: НАСТРОЙКИ
CreateSection(TabContents[3], "ОСНОВНЫЕ", "⚙️")
CreateToggle(TabContents[3], "Анти-АФК", "AntiAFK", "Не кикает за бездействие")
CreateToggle(TabContents[3], "Авто-сбор", "AutoCollect", "Автоматически собирать предметы")
CreateToggle(TabContents[3], "Телепорт назад", "TeleportBack", "Возвращаться на место")

CreateSection(TabContents[3], "ТАЙМИНГИ", "⏱️")
CreateSlider(TabContents[3], "Задержка сбора (сек)", "CollectDelay", 0.1, 2)
CreateSlider(TabContents[3], "Задержка скана (сек)", "ScanDelay", 0.2, 3)
CreateSlider(TabContents[3], "Дистанция ТП", "TeleportRange", 3, 15)

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
            Notify("Телепорт", "Выполнен", 2, "success")
        end
    else
        Notify("Ошибка", "Позиция не сохранена", 2, "error")
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
    TweenService:Create(MainFrame, TweenInfo.new(0.3), {
        Position = UDim2.new(0.5, 0, 1.5, 0)
    }):Play()
    task.wait(0.3)
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

-- Определение редкости по имени/цвету
local function GetRarity(object)
    local name = object.Name:lower()
    
    -- Проверяем атрибуты
    local rarityAttr = object:GetAttribute("Rarity") or object:GetAttribute("rarity")
    if rarityAttr then
        return tostring(rarityAttr)
    end
    
    -- Проверяем по имени
    for rarity, keywords in pairs(RarityKeywords) do
        for _, keyword in ipairs(keywords) do
            if name:find(keyword) then
                return rarity
            end
        end
    end
    
    -- Проверяем цвет (если есть)
    local primaryPart = object:IsA("Model") and object.PrimaryPart or (object:IsA("BasePart") and object)
    if primaryPart and primaryPart:IsA("BasePart") then
        local color = primaryPart.Color
        
        -- Примерное определение по цвету
        if color.R > 0.8 and color.G > 0.8 and color.B > 0.8 then
            return "Common"
        elseif color.G > 0.7 and color.R < 0.5 and color.B < 0.5 then
            return "Uncommon"
        elseif color.B > 0.7 and color.R < 0.5 and color.G < 0.7 then
            return "Rare"
        elseif color.R > 0.5 and color.B > 0.7 then
            return "Epic"
        elseif color.R > 0.8 and color.G > 0.5 and color.B < 0.3 then
            return "Legendary"
        elseif color.R > 0.8 and color.G < 0.4 then
            return "Mythic"
        end
    end
    
    -- Проверяем в потомках на GUI с редкостью
    for _, desc in ipairs(object:GetDescendants()) do
        if desc:IsA("TextLabel") then
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
    
    return nil
end

-- Поиск брейнротов
local function FindBrainrots()
    local found = {}
    
    -- Ищем в Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        
        -- Проверяем является ли это брейнротом
        local isBrainrot = name:find("brainrot") or 
                          name:find("brain") or 
                          name:find("rot") or
                          name:find("pet") or
                          name:find("collectible") or
                          name:find("spawn")
        
        if isBrainrot and (obj:IsA("Model") or obj:IsA("BasePart")) then
            local rarity = GetRarity(obj)
            if rarity and Config.Brainrots[rarity] then
                local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                table.insert(found, {
                    Object = obj,
                    Position = pos,
                    Rarity = rarity,
                    Type = "Brainrot"
                })
            end
        end
    end
    
    return found
end

-- Поиск лаки блоков
local function FindLuckyBlocks()
    local found = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        
        -- Проверяем является ли это лаки блоком
        local isLuckyBlock = name:find("lucky") or 
                            name:find("block") or 
                            name:find("crate") or
                            name:find("chest") or
                            name:find("box") or
                            name:find("reward")
        
        if isLuckyBlock and (obj:IsA("Model") or obj:IsA("BasePart")) then
            local rarity = GetRarity(obj)
            if rarity and Config.LuckyBlocks[rarity] then
                local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                table.insert(found, {
                    Object = obj,
                    Position = pos,
                    Rarity = rarity,
                    Type = "LuckyBlock"
                })
            end
        end
    end
    
    return found
end

-- Телепорт к объекту
local function TeleportTo(position)
    local root = GetRootPart()
    if not root then return false end
    
    root.CFrame = CFrame.new(position + Vector3.new(0, Config.TeleportRange, 0))
    return true
end

-- Сбор объекта
local function CollectObject(item)
    local root = GetRootPart()
    if not root then return false end
    
    -- Телепортируемся к объекту
    TeleportTo(item.Position)
    task.wait(Config.CollectDelay)
    
    -- Пытаемся взаимодействовать
    local obj = item.Object
    
    -- Метод 1: ProximityPrompt
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            fireproximityprompt(desc)
            return true
        end
    end
    
    -- Метод 2: ClickDetector
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("ClickDetector") then
            fireclickdetector(desc)
            return true
        end
    end
    
    -- Метод 3: Touch
    if obj:IsA("BasePart") then
        firetouchinterest(root, obj, 0)
        task.wait(0.1)
        firetouchinterest(root, obj, 1)
        return true
    elseif obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
        if part then
            firetouchinterest(root, part, 0)
            task.wait(0.1)
            firetouchinterest(root, part, 1)
            return true
        end
    end
    
    -- Метод 4: Remote Events
    local remotes = ReplicatedStorage:GetDescendants()
    for _, remote in ipairs(remotes) do
        if remote:IsA("RemoteEvent") then
            local name = remote.Name:lower()
            if name:find("collect") or name:find("claim") or name:find("pickup") or name:find("grab") then
                pcall(function()
                    remote:FireServer(obj)
                end)
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
        -- Сохраняем позицию
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
        StatusInfo.Text = string.format(
            "Собрано: %d | Брейнроты: %d | Блоки: %d",
            Stats.Collected,
            Stats.BrainrotsCollected,
            Stats.LuckyBlocksCollected
        )
        
        if not Config.Farming then continue end
        
        local char = GetCharacter()
        local root = GetRootPart()
        if not char or not root then continue end
        
        -- Сохраняем текущую позицию если включён возврат
        local returnPosition = Config.TeleportBack and root.CFrame or nil
        
        -- Ищем брейнроты
        local brainrots = FindBrainrots()
        for _, item in ipairs(brainrots) do
            if not Config.Farming then break end
            
            StatusTitle.Text = "Статус: 🔍 Нашёл " .. item.Rarity .. " Brainrot"
            
            if CollectObject(item) then
                Stats.Collected = Stats.Collected + 1
                Stats.BrainrotsCollected = Stats.BrainrotsCollected + 1
                
                Notify(
                    item.Rarity .. " Brainrot!",
                    "Успешно собран",
                    2,
                    "collect"
                )
            end
            
            task.wait(Config.CollectDelay)
        end
        
        -- Ищем лаки блоки
        local luckyBlocks = FindLuckyBlocks()
        for _, item in ipairs(luckyBlocks) do
            if not Config.Farming then break end
            
            StatusTitle.Text = "Статус: 🔍 Нашёл " .. item.Rarity .. " Lucky Block"
            
            if CollectObject(item) then
                Stats.Collected = Stats.Collected + 1
                Stats.LuckyBlocksCollected = Stats.LuckyBlocksCollected + 1
                
                Notify(
                    item.Rarity .. " Lucky Block!",
                    "Успешно собран",
                    2,
                    "collect"
                )
            end
            
            task.wait(Config.CollectDelay)
        end
        
        -- Возвращаемся на позицию
        if Config.TeleportBack and returnPosition and Config.Farming then
            root.CFrame = returnPosition
            StatusTitle.Text = "Статус: 🟢 Сканирование..."
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
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            
            -- Дополнительно - движение камеры
            local hum = GetHumanoid()
            if hum then
                hum:Move(Vector3.new(0, 0, 0))
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- АНИМАЦИИ
-- ═══════════════════════════════════════════════════════════════

-- Радужная обводка
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

-- Пульсация мини-кнопки
spawn(function()
    while ScreenGui.Parent do
        if MiniButton.Visible then
            TweenService:Create(MiniButton, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
                Size = UDim2.new(0, 65, 0, 65)
            }):Play()
            task.wait(0.8)
            TweenService:Create(MiniButton, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
                Size = UDim2.new(0, 60, 0, 60)
            }):Play()
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
    Notify("Добро пожаловать!", "Brainrot Farm загружен", 3, "success")
end)

-- ═══════════════════════════════════════════════════════════════
print("═══════════════════════════════════════════════════════════")
print("  🧠 ESCAPE TSUNAMI BRAINROT FARM v1.0")
print("  ✅ Скрипт загружен")
print("  📱 Поддержка мобильных устройств")
print("═══════════════════════════════════════════════════════════")
