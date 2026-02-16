--[[
    Slap Battles Auto Farm
    Все функции с переключателями
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
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local IsMobile = UserInputService.TouchEnabled

-- ═══════════════════════════════════════════════════════════════
-- КОНФИГУРАЦИЯ
-- ═══════════════════════════════════════════════════════════════
local Config = {
    -- Основные
    Farming = false,
    AutoRespawn = false,
    TeleportBack = false,
    AutoEquip = false,
    
    -- Атака
    AutoAttack = false,
    TeleportToTarget = false,
    AttackRange = 15,
    FarmSpeed = 100,
    
    -- RemoteALL
    RemoteALL = false,
    UnlockAllGloves = false,
    SpoofRobux = false,
    BypassPurchase = false,
    
    -- Движение
    SpeedBoost = false,
    NoClip = false,
    Fly = false,
    InfiniteJump = false,
    
    -- Защита
    AntiAFK = false,
    AntiVoid = false,
    GodMode = false,
    AntiKnockback = false,
    
    -- Визуал
    ESP = false,
    ShowDistance = false,
    Tracers = false,
    
    -- Настройки
    TargetMode = "Nearest",
    SelectedGlove = "Default",
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 50
}

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ GUI
-- ═══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SlapFarmPro"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if syn then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНЫЙ ФРЕЙМ
-- ═══════════════════════════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = IsMobile and UDim2.new(0.92, 0, 0.88, 0) or UDim2.new(0, 380, 0, 580)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(120, 60, 220)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- ═══════════════════════════════════════════════════════════════
-- ЗАГОЛОВОК
-- ═══════════════════════════════════════════════════════════════
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 15)
HeaderFix.Position = UDim2.new(0, 0, 1, -15)
HeaderFix.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🥊 SLAP FARM PRO"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Кнопка свернуть
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 40, 0, 40)
MinBtn.Position = UDim2.new(1, -90, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 20
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinBtn

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

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- ═══════════════════════════════════════════════════════════════
-- СТАТУС ПАНЕЛЬ
-- ═══════════════════════════════════════════════════════════════
local StatusBar = Instance.new("Frame")
StatusBar.Name = "StatusBar"
StatusBar.Size = UDim2.new(1, -20, 0, 45)
StatusBar.Position = UDim2.new(0, 10, 0, 55)
StatusBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
StatusBar.BorderSizePixel = 0
StatusBar.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 10)
StatusCorner.Parent = StatusBar

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Size = UDim2.new(0, 40, 1, 0)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "⏸️"
StatusIcon.TextSize = 22
StatusIcon.Parent = StatusBar

local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, -45, 1, 0)
StatusText.Position = UDim2.new(0, 45, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Готов к работе | Цель: — | Slaps: 0"
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.TextSize = IsMobile and 12 or 13
StatusText.Font = Enum.Font.Gotham
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextTruncate = Enum.TextTruncate.AtEnd
StatusText.Parent = StatusBar

-- ═══════════════════════════════════════════════════════════════
-- КОНТЕНТ (СКРОЛЛ)
-- ═══════════════════════════════════════════════════════════════
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -20, 1, -115)
Content.Position = UDim2.new(0, 10, 0, 105)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Color3.fromRGB(120, 60, 220)
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

local function CreateSection(name, icon)
    local Section = Instance.new("Frame")
    Section.Name = "Section_" .. name
    Section.Size = UDim2.new(1, 0, 0, 32)
    Section.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
    Section.BorderSizePixel = 0
    Section.Parent = Content
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Section
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = (icon or "▸") .. " " .. name
    Label.TextColor3 = Color3.fromRGB(200, 170, 255)
    Label.TextSize = IsMobile and 14 or 13
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Section
    
    return Section
end

local function CreateToggle(name, configKey, description)
    local Toggle = Instance.new("Frame")
    Toggle.Name = "Toggle_" .. configKey
    Toggle.Size = UDim2.new(1, 0, 0, description and 52 or 44)
    Toggle.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    Toggle.BorderSizePixel = 0
    Toggle.Parent = Content
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Toggle
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.7, -10, 0, 22)
    NameLabel.Position = UDim2.new(0, 12, 0, description and 6 or 11)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = IsMobile and 14 or 13
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Toggle
    
    if description then
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(0.7, -10, 0, 18)
        DescLabel.Position = UDim2.new(0, 12, 0, 28)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = description
        DescLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
        DescLabel.TextSize = IsMobile and 11 or 10
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
        DescLabel.Parent = Toggle
    end
    
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 55, 0, 28)
    SwitchBG.Position = UDim2.new(1, -67, 0.5, -14)
    SwitchBG.BackgroundColor3 = Config[configKey] and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 80)
    SwitchBG.Parent = Toggle
    
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBG
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 22, 0, 22)
    Circle.Position = Config[configKey] and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = SwitchBG
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle
    
    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.Parent = Toggle
    
    local function UpdateVisual()
        local enabled = Config[configKey]
        TweenService:Create(SwitchBG, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Position = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        }):Play()
    end
    
    ClickBtn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        UpdateVisual()
    end)
    
    return Toggle, UpdateVisual
end

local function CreateSlider(name, configKey, min, max, description)
    local Slider = Instance.new("Frame")
    Slider.Name = "Slider_" .. configKey
    Slider.Size = UDim2.new(1, 0, 0, 65)
    Slider.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    Slider.BorderSizePixel = 0
    Slider.Parent = Content
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Slider
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.6, 0, 0, 20)
    NameLabel.Position = UDim2.new(0, 12, 0, 8)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = IsMobile and 13 or 12
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Slider
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 50, 0, 22)
    ValueLabel.Position = UDim2.new(1, -62, 0, 6)
    ValueLabel.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
    ValueLabel.Text = tostring(Config[configKey])
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 12
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Parent = Slider
    
    local ValCorner = Instance.new("UICorner")
    ValCorner.CornerRadius = UDim.new(0, 6)
    ValCorner.Parent = ValueLabel
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -24, 0, 10)
    SliderBar.Position = UDim2.new(0, 12, 0, 42)
    SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    SliderBar.Parent = Slider
    
    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = SliderBar
    
    local percent = (Config[configKey] - min) / (max - min)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(percent, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
    Fill.Parent = SliderBar
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill
    
    local Handle = Instance.new("Frame")
    Handle.Size = UDim2.new(0, 20, 0, 20)
    Handle.Position = UDim2.new(percent, -10, 0.5, -10)
    Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handle.Parent = SliderBar
    
    local HandleCorner = Instance.new("UICorner")
    HandleCorner.CornerRadius = UDim.new(1, 0)
    HandleCorner.Parent = Handle
    
    local SliderBtn = Instance.new("TextButton")
    SliderBtn.Size = UDim2.new(1, 20, 1, 20)
    SliderBtn.Position = UDim2.new(0, -10, 0, -10)
    SliderBtn.BackgroundTransparency = 1
    SliderBtn.Text = ""
    SliderBtn.Parent = SliderBar
    
    local dragging = false
    
    local function Update(inputX)
        local barPos = SliderBar.AbsolutePosition.X
        local barSize = SliderBar.AbsoluteSize.X
        local pct = math.clamp((inputX - barPos) / barSize, 0, 1)
        local value = math.floor(min + (max - min) * pct)
        
        Config[configKey] = value
        ValueLabel.Text = tostring(value)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        Handle.Position = UDim2.new(pct, -10, 0.5, -10)
    end
    
    SliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Update(input.Position.X)
        end
    end)
    
    SliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            Update(input.Position.X)
        end
    end)
    
    return Slider
end

local function CreateButton(name, icon, color, callback)
    local Button = Instance.new("TextButton")
    Button.Name = "Button_" .. name
    Button.Size = UDim2.new(1, 0, 0, 44)
    Button.BackgroundColor3 = color or Color3.fromRGB(100, 60, 180)
    Button.Text = (icon or "") .. " " .. name
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = IsMobile and 14 or 13
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Content
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.1), {Size = UDim2.new(0.98, 0, 0, 42)}):Play()
        task.wait(0.1)
        TweenService:Create(Button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 44)}):Play()
        callback()
    end)
    
    return Button
end

local function CreateDropdown(name, configKey, options)
    local Dropdown = Instance.new("Frame")
    Dropdown.Name = "Dropdown_" .. configKey
    Dropdown.Size = UDim2.new(1, 0, 0, 44)
    Dropdown.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    Dropdown.BorderSizePixel = 0
    Dropdown.ClipsDescendants = true
    Dropdown.Parent = Content
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Dropdown
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(0.5, 0, 0, 44)
    NameLabel.Position = UDim2.new(0, 12, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = IsMobile and 13 or 12
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Dropdown
    
    local SelectedBtn = Instance.new("TextButton")
    SelectedBtn.Size = UDim2.new(0, 110, 0, 30)
    SelectedBtn.Position = UDim2.new(1, -122, 0, 7)
    SelectedBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 140)
    SelectedBtn.Text = Config[configKey] .. " ▼"
    SelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectedBtn.TextSize = 11
    SelectedBtn.Font = Enum.Font.GothamBold
    SelectedBtn.Parent = Dropdown
    
    local SelCorner = Instance.new("UICorner")
    SelCorner.CornerRadius = UDim.new(0, 6)
    SelCorner.Parent = SelectedBtn
    
    local OptionsFrame = Instance.new("Frame")
    OptionsFrame.Size = UDim2.new(1, -20, 0, #options * 32 + 5)
    OptionsFrame.Position = UDim2.new(0, 10, 0, 48)
    OptionsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    OptionsFrame.Visible = false
    OptionsFrame.Parent = Dropdown
    
    local OptCorner = Instance.new("UICorner")
    OptCorner.CornerRadius = UDim.new(0, 8)
    OptCorner.Parent = OptionsFrame
    
    local OptLayout = Instance.new("UIListLayout")
    OptLayout.Padding = UDim.new(0, 2)
    OptLayout.Parent = OptionsFrame
    
    local isOpen = false
    
    for _, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, -6, 0, 30)
        OptBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
        OptBtn.Text = opt
        OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        OptBtn.TextSize = 11
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.Parent = OptionsFrame
        
        local OptBtnCorner = Instance.new("UICorner")
        OptBtnCorner.CornerRadius = UDim.new(0, 5)
        OptBtnCorner.Parent = OptBtn
        
        OptBtn.MouseButton1Click:Connect(function()
            Config[configKey] = opt
            SelectedBtn.Text = opt .. " ▼"
            isOpen = false
            OptionsFrame.Visible = false
            TweenService:Create(Dropdown, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 44)}):Play()
        end)
    end
    
    SelectedBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        OptionsFrame.Visible = isOpen
        TweenService:Create(Dropdown, TweenInfo.new(0.2), {
            Size = isOpen and UDim2.new(1, 0, 0, 52 + #options * 32) or UDim2.new(1, 0, 0, 44)
        }):Play()
    end)
    
    return Dropdown
end

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ ВСЕХ ЭЛЕМЕНТОВ
-- ═══════════════════════════════════════════════════════════════

-- ОСНОВНОЕ
CreateSection("ОСНОВНОЙ ФАРМ", "🎮")
CreateToggle("Автофарм", "Farming", "Автоматически фармит пощёчины")
CreateToggle("Авто-атака", "AutoAttack", "Автоматически бьёт рядом")
CreateToggle("Телепорт к цели", "TeleportToTarget", "Телепортирует к игроку")
CreateToggle("Авто-респавн", "AutoRespawn", "Возрождение после смерти")
CreateToggle("Телепорт назад", "TeleportBack", "Возврат при падении")
CreateToggle("Авто-экипировка", "AutoEquip", "Экипирует перчатку")

-- НАСТРОЙКИ АТАКИ
CreateSection("НАСТРОЙКИ АТАКИ", "⚔️")
CreateSlider("Дистанция атаки", "AttackRange", 5, 50)
CreateSlider("Скорость (ms)", "FarmSpeed", 50, 500)
CreateDropdown("Режим цели", "TargetMode", {"Nearest", "Random", "MostSlaps", "LowestHP"})

-- REMOTEALL
CreateSection("REMOTEALL СИСТЕМА", "💎")
CreateToggle("RemoteALL", "RemoteALL", "Локальный спуф покупок")
CreateToggle("Разблокировать перчатки", "UnlockAllGloves", "Все перчатки доступны")
CreateToggle("Спуф робуксов", "SpoofRobux", "Показывает 999999 R$")
CreateToggle("Обход покупки", "BypassPurchase", "Покупка без оплаты")

-- ДВИЖЕНИЕ
CreateSection("ДВИЖЕНИЕ", "🏃")
CreateToggle("Ускорение", "SpeedBoost", "Увеличивает скорость")
CreateToggle("NoClip", "NoClip", "Проход сквозь стены")
CreateToggle("Полёт", "Fly", "Летать по карте")
CreateToggle("Бесконечный прыжок", "InfiniteJump", "Прыгать в воздухе")
CreateSlider("Скорость ходьбы", "WalkSpeed", 16, 200)
CreateSlider("Сила прыжка", "JumpPower", 50, 200)
CreateSlider("Скорость полёта", "FlySpeed", 20, 200)

-- ЗАЩИТА
CreateSection("ЗАЩИТА", "🛡️")
CreateToggle("Анти-АФК", "AntiAFK", "Не выкидывает за АФК")
CreateToggle("Анти-войд", "AntiVoid", "Защита от падения")
CreateToggle("Бессмертие", "GodMode", "Бесконечное здоровье")
CreateToggle("Анти-отброс", "AntiKnockback", "Нет отбрасывания")

-- ВИЗУАЛ
CreateSection("ВИЗУАЛ", "👁️")
CreateToggle("ESP игроков", "ESP", "Видеть игроков сквозь стены")
CreateToggle("Показать дистанцию", "ShowDistance", "Расстояние до игроков")
CreateToggle("Линии к игрокам", "Tracers", "Линии к целям")

-- БЫСТРЫЕ ДЕЙСТВИЯ
CreateSection("БЫСТРЫЕ ДЕЙСТВИЯ", "⚡")
CreateButton("Респавн", "💀", Color3.fromRGB(200, 80, 80), function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end)

CreateButton("Телепорт на спавн", "📍", Color3.fromRGB(80, 150, 200), function()
    TeleportToSpawn()
end)

CreateButton("К ближайшему игроку", "🎯", Color3.fromRGB(200, 150, 80), function()
    local target = GetNearestPlayer()
    if target then TeleportToTarget(target) end
end)

CreateButton("Обновить перчатки", "🔄", Color3.fromRGB(100, 180, 100), function()
    if Config.RemoteALL then
        SpoofAllGloves()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- МИНИ КНОПКА (ПРИ СВОРАЧИВАНИИ)
-- ═══════════════════════════════════════════════════════════════
local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"
MiniButton.Size = UDim2.new(0, 55, 0, 55)
MiniButton.Position = UDim2.new(0, 15, 0.5, -27)
MiniButton.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
MiniButton.Text = "🥊"
MiniButton.TextSize = 28
MiniButton.Font = Enum.Font.GothamBold
MiniButton.Visible = false
MiniButton.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(1, 0)
MiniCorner.Parent = MiniButton

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color = Color3.fromRGB(150, 100, 255)
MiniStroke.Thickness = 2
MiniStroke.Parent = MiniButton

-- Перетаскивание мини кнопки
local draggingMini = false
local dragStartMini, startPosMini

MiniButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMini = true
        dragStartMini = input.Position
        startPosMini = MiniButton.Position
    end
end)

MiniButton.InputEnded:Connect(function(input)
    draggingMini = false
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingMini then
        local delta = input.Position - dragStartMini
        MiniButton.Position = UDim2.new(
            startPosMini.X.Scale, startPosMini.X.Offset + delta.X,
            startPosMini.Y.Scale, startPosMini.Y.Offset + delta.Y
        )
    end
end)

MiniButton.MouseButton1Click:Connect(function()
    if not draggingMini or (dragStartMini and (Vector2.new(dragStartMini.X, dragStartMini.Y) - UserInputService:GetMouseLocation()).Magnitude < 10) then
        MainFrame.Visible = true
        MiniButton.Visible = false
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ОБРАБОТЧИКИ КНОПОК HEADER
-- ═══════════════════════════════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniButton.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    Config.Farming = false
    ScreenGui:Destroy()
end)

-- Перетаскивание главного окна
local draggingMain = false
local dragStartMain, startPosMain

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMain = true
        dragStartMain = input.Position
        startPosMain = MainFrame.Position
    end
end)

Header.InputEnded:Connect(function(input)
    draggingMain = false
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingMain then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(
            startPosMain.X.Scale, startPosMain.X.Offset + delta.X,
            startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y
        )
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

function GetNearestPlayer()
    local nearest, dist = nil, math.huge
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local d = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
                if d < dist then dist, nearest = d, plr end
            end
        end
    end
    return nearest
end

function GetRandomPlayer()
    local valid = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then table.insert(valid, plr) end
        end
    end
    return #valid > 0 and valid[math.random(#valid)] or nil
end

function GetMostSlapsPlayer()
    local target, maxSlaps = nil, -1
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local slaps = 0
                if plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Slaps") then
                    slaps = plr.leaderstats.Slaps.Value
                end
                if slaps > maxSlaps then maxSlaps, target = slaps, plr end
            end
        end
    end
    return target
end

function GetLowestHPPlayer()
    local target, lowestHP = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 and hum.Health < lowestHP then
                lowestHP, target = hum.Health, plr
            end
        end
    end
    return target
end

function GetTarget()
    local mode = Config.TargetMode
    if mode == "Nearest" then return GetNearestPlayer()
    elseif mode == "Random" then return GetRandomPlayer()
    elseif mode == "MostSlaps" then return GetMostSlapsPlayer()
    elseif mode == "LowestHP" then return GetLowestHPPlayer()
    end
    return GetNearestPlayer()
end

function TeleportToTarget(target)
    if not target or not target.Character then return end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local myChar = LocalPlayer.Character
    if not targetRoot or not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -3)
end

function TeleportToSpawn()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    root.CFrame = spawn and spawn.CFrame + Vector3.new(0, 5, 0) or CFrame.new(0, 50, 0)
end

function Attack()
    local char = LocalPlayer.Character
    if not char then return end
    
    local glove = char:FindFirstChildOfClass("Tool")
    if not glove then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            glove = bp:FindFirstChildOfClass("Tool")
            if glove and char:FindFirstChild("Humanoid") then
                char.Humanoid:EquipTool(glove)
                task.wait(0.1)
            end
        end
    end
    
    if glove then
        local remote = glove:FindFirstChild("Slap") or glove:FindFirstChild("SlapRemote") or 
                       glove:FindFirstChild("RemoteEvent") or glove:FindFirstChild("Attack")
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer()
        else
            glove:Activate()
        end
    end
end

function SpoofAllGloves()
    -- Ищем данные игрока
    local data = LocalPlayer:FindFirstChild("PlayerData") or LocalPlayer:FindFirstChild("Data")
    if data then
        local gloves = data:FindFirstChild("Gloves") or data:FindFirstChild("OwnedGloves")
        if gloves then
            for _, child in ipairs(gloves:GetChildren()) do
                if child:IsA("BoolValue") then child.Value = true end
            end
        end
    end
    
    -- Спуфим GUI
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        for _, desc in ipairs(gui:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                local txt = desc.Text:lower()
                if txt:find("r%$") or txt:find("robux") then
                    if txt:find("buy") or txt:find("purchase") or txt:find("unlock") then
                        desc.Text = "✅ FREE"
                        desc.TextColor3 = Color3.fromRGB(100, 255, 100)
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНОЙ ЦИКЛ
-- ═══════════════════════════════════════════════════════════════
local SlapCount = 0

spawn(function()
    while task.wait(Config.FarmSpeed / 1000) do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        -- Статус
        local status = Config.Farming and "🟢 Активен" or "⏸️ Пауза"
        local target = Config.Farming and GetTarget()
        local targetName = target and target.Name or "—"
        StatusText.Text = status .. " | Цель: " .. targetName .. " | Slaps: " .. SlapCount
        StatusIcon.Text = Config.Farming and "🟢" or "⏸️"
        
        if not char or not hum or hum.Health <= 0 then continue end
        
        -- Скорость
        if Config.SpeedBoost then
            hum.WalkSpeed = Config.WalkSpeed
            hum.JumpPower = Config.JumpPower
        end
        
        -- GodMode
        if Config.GodMode then
            hum.Health = hum.MaxHealth
        end
        
        -- Анти-войд
        if Config.AntiVoid and root and root.Position.Y < -50 then
            TeleportToSpawn()
        end
        
        -- Телепорт назад
        if Config.TeleportBack and root and root.Position.Y < -50 then
            TeleportToSpawn()
        end
        
        -- Фарм
        if Config.Farming and target then
            if Config.TeleportToTarget then
                TeleportToTarget(target)
            end
            
            if Config.AutoAttack then
                local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot and root then
                    local dist = (targetRoot.Position - root.Position).Magnitude
                    if dist <= Config.AttackRange then
                        Attack()
                        SlapCount = SlapCount + 1
                    end
                end
            end
        end
        
        -- RemoteALL
        if Config.RemoteALL and Config.UnlockAllGloves then
            SpoofAllGloves()
        end
    end
end)

-- NoClip
spawn(function()
    while task.wait() do
        if Config.NoClip then
            local char = LocalPlayer.Character
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

-- Fly
local Flying = false
local FlyBV, FlyBG

spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if Config.Fly and not Flying and root and hum then
            Flying = true
            FlyBV = Instance.new("BodyVelocity", root)
            FlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            FlyBV.Velocity = Vector3.zero
            
            FlyBG = Instance.new("BodyGyro", root)
            FlyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            FlyBG.P = 9e4
            
        elseif not Config.Fly and Flying then
            Flying = false
            if FlyBV then FlyBV:Destroy() end
            if FlyBG then FlyBG:Destroy() end
        end
        
        if Flying and FlyBV and FlyBG then
            local cam = Camera.CFrame
            local dir = Vector3.zero
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
            
            FlyBV.Velocity = dir * Config.FlySpeed
            FlyBG.CFrame = cam
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Anti-AFK
spawn(function()
    while task.wait(60) do
        if Config.AntiAFK then
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.zero)
        end
    end
end)

-- Anti-Knockback
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root:GetPropertyChangedSignal("Velocity"):Connect(function()
            if Config.AntiKnockback then
                root.Velocity = Vector3.zero
                root.RotVelocity = Vector3.zero
            end
        end)
    end
end)

-- ESP
local ESPFolder = Instance.new("Folder", game.CoreGui)
ESPFolder.Name = "ESP"

spawn(function()
    while task.wait(0.5) do
        for _, child in ipairs(ESPFolder:GetChildren()) do child:Destroy() end
        
        if not Config.ESP then continue end
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    local bill = Instance.new("BillboardGui")
                    bill.Adornee = head
                    bill.Size = UDim2.new(0, 100, 0, 40)
                    bill.StudsOffset = Vector3.new(0, 2, 0)
                    bill.AlwaysOnTop = true
                    bill.Parent = ESPFolder
                    
                    local name = Instance.new("TextLabel", bill)
                    name.Size = UDim2.new(1, 0, 0.5, 0)
                    name.BackgroundTransparency = 1
                    name.Text = plr.Name
                    name.TextColor3 = Color3.fromRGB(255, 255, 255)
                    name.TextStrokeTransparency = 0
                    name.TextSize = 14
                    name.Font = Enum.Font.GothamBold
                    
                    if Config.ShowDistance then
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            local dist = math.floor((head.Position - myRoot.Position).Magnitude)
                            local distLabel = Instance.new("TextLabel", bill)
                            distLabel.Size = UDim2.new(1, 0, 0.5, 0)
                            distLabel.Position = UDim2.new(0, 0, 0.5, 0)
                            distLabel.BackgroundTransparency = 1
                            distLabel.Text = dist .. "m"
                            distLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
                            distLabel.TextStrokeTransparency = 0
                            distLabel.TextSize = 12
                            distLabel.Font = Enum.Font.Gotham
                        end
                    end
                end
            end
        end
    end
end)

-- Анимация обводки
spawn(function()
    local hue = 0
    while ScreenGui.Parent do
        hue = (hue + 0.003) % 1
        MainStroke.Color = Color3.fromHSV(hue, 0.7, 0.9)
        MiniStroke.Color = Color3.fromHSV(hue, 0.7, 0.9)
        task.wait(0.03)
    end
end)

-- Анимация появления
MainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
    Position = UDim2.new(0.5, 0, 0.5, 0)
}):Play()

print("═══════════════════════════════════════")
print("  🥊 SLAP FARM PRO LOADED")
print("  📱 All features with toggles")
print("  💎 RemoteALL included")
print("═══════════════════════════════════════")
