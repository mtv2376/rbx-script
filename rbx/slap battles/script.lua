--[[
    Slap Battles Auto Farm - Mobile Edition
    + RemoteALL функция для локальной имитации робуксов
    Оптимизировано для телефонов
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
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Определение мобильного устройства
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ═══════════════════════════════════════════════════════════════
-- КОНФИГУРАЦИЯ
-- ═══════════════════════════════════════════════════════════════
local Config = {
    Farming = false,
    AutoRespawn = true,
    SelectedGlove = "Default",
    AttackRange = 15,
    FarmSpeed = 0.1,
    TeleportBack = true,
    AvoidEdge = true,
    TargetMode = "Nearest",
    SafeZoneY = -50,
    SpawnPosition = Vector3.new(0, 50, 0),
    RemoteALL = false,
    AutoEquip = true,
    AntiAFK = true,
    SpeedBoost = false,
    GodMode = false
}

-- Список перчаток с ID
local GlovesList = {
    {Name = "Default", ID = 0, Robux = 0},
    {Name = "Brick", ID = 1, Robux = 0},
    {Name = "Bob", ID = 2, Robux = 0},
    {Name = "Flash", ID = 3, Robux = 75},
    {Name = "Coil", ID = 4, Robux = 0},
    {Name = "Extended Coil", ID = 5, Robux = 0},
    {Name = "Reverse", ID = 6, Robux = 0},
    {Name = "Killstreak", ID = 7, Robux = 0},
    {Name = "Reaper", ID = 8, Robux = 150},
    {Name = "Phantom", ID = 9, Robux = 0},
    {Name = "Nuclear", ID = 10, Robux = 0},
    {Name = "Mitten", ID = 11, Robux = 0},
    {Name = "Spider", ID = 12, Robux = 0},
    {Name = "Duelist", ID = 13, Robux = 0},
    {Name = "Blade", ID = 14, Robux = 199},
    {Name = "Spin", ID = 15, Robux = 0},
    {Name = "Curse", ID = 16, Robux = 0},
    {Name = "Tycoon", ID = 17, Robux = 399},
    {Name = "Overkill", ID = 18, Robux = 299},
    {Name = "Glitch", ID = 19, Robux = 0},
    {Name = "SLAPPLE", ID = 20, Robux = 0},
    {Name = "Elude", ID = 21, Robux = 0},
    {Name = "God Hand", ID = 22, Robux = 999},
    {Name = "One Shot", ID = 23, Robux = 499},
    {Name = "Lasso", ID = 24, Robux = 0},
    {Name = "Orbit", ID = 25, Robux = 0},
    {Name = "Snake", ID = 26, Robux = 0},
    {Name = "Uppercut", ID = 27, Robux = 0},
    {Name = "Combo", ID = 28, Robux = 0},
    {Name = "Gravity", ID = 29, Robux = 0},
    {Name = "Push", ID = 30, Robux = 0},
    {Name = "Pull", ID = 31, Robux = 0},
    {Name = "Mega Rock", ID = 32, Robux = 799},
    {Name = "Diamond", ID = 33, Robux = 1999},
    {Name = "Dev", ID = 34, Robux = 0},
    {Name = "Custom", ID = 35, Robux = 599}
}

-- ═══════════════════════════════════════════════════════════════
-- REMOTEALL СИСТЕМА
-- ═══════════════════════════════════════════════════════════════
local RemoteALLSystem = {}
RemoteALLSystem.Enabled = false
RemoteALLSystem.SpoofedRobux = 999999
RemoteALLSystem.OwnedGloves = {}
RemoteALLSystem.OriginalFunctions = {}

function RemoteALLSystem:Init()
    -- Помечаем все перчатки как купленные локально
    for _, glove in ipairs(GlovesList) do
        self.OwnedGloves[glove.Name] = true
        self.OwnedGloves[glove.ID] = true
    end
    
    -- Перехват MarketplaceService
    if hookfunction then
        -- Перехватываем проверку владения геймпассом
        local oldUserOwnsGamePassAsync = MarketplaceService.UserOwnsGamePassAsync
        self.OriginalFunctions.UserOwnsGamePassAsync = oldUserOwnsGamePassAsync
        
        hookfunction(MarketplaceService.UserOwnsGamePassAsync, function(self2, userId, gamePassId)
            if RemoteALLSystem.Enabled then
                return true -- Всегда возвращаем что владеем
            end
            return oldUserOwnsGamePassAsync(self2, userId, gamePassId)
        end)
        
        -- Перехватываем PlayerOwnsAsset
        local oldPlayerOwnsAsset = MarketplaceService.PlayerOwnsAsset
        self.OriginalFunctions.PlayerOwnsAsset = oldPlayerOwnsAsset
        
        hookfunction(MarketplaceService.PlayerOwnsAsset, function(self2, player, assetId)
            if RemoteALLSystem.Enabled then
                return true
            end
            return oldPlayerOwnsAsset(self2, player, assetId)
        end)
    end
    
    -- Перехват Remote Events для магазина
    self:HookRemotes()
end

function RemoteALLSystem:HookRemotes()
    -- Ищем remote события магазина
    local function findRemotes(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local name = child.Name:lower()
                if name:find("buy") or name:find("purchase") or name:find("shop") or 
                   name:find("glove") or name:find("unlock") or name:find("robux") then
                    self:HookRemote(child)
                end
            end
        end
    end
    
    findRemotes(ReplicatedStorage)
    
    -- Следим за новыми remote событиями
    ReplicatedStorage.DescendantAdded:Connect(function(child)
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            local name = child.Name:lower()
            if name:find("buy") or name:find("purchase") or name:find("shop") or 
               name:find("glove") or name:find("unlock") then
                task.wait(0.1)
                self:HookRemote(child)
            end
        end
    end)
end

function RemoteALLSystem:HookRemote(remote)
    if self.OriginalFunctions[remote] then return end
    
    if remote:IsA("RemoteEvent") then
        local oldFire = remote.FireServer
        self.OriginalFunctions[remote] = oldFire
        
        -- Создаём обёртку
        local mt = getrawmetatable(remote)
        if mt and setreadonly then
            setreadonly(mt, false)
            local oldNamecall = mt.__namecall
            mt.__namecall = newcclosure(function(self2, ...)
                local method = getnamecallmethod()
                if method == "FireServer" and RemoteALLSystem.Enabled then
                    local args = {...}
                    -- Модифицируем аргументы покупки
                    for i, arg in ipairs(args) do
                        if type(arg) == "table" then
                            if arg.robux then arg.robux = 0 end
                            if arg.price then arg.price = 0 end
                            if arg.cost then arg.cost = 0 end
                        end
                    end
                    return oldNamecall(self2, unpack(args))
                end
                return oldNamecall(self2, ...)
            end)
            setreadonly(mt, true)
        end
    end
end

function RemoteALLSystem:SpoofGloveOwnership()
    -- Ищем локальные данные о перчатках
    local playerData = LocalPlayer:FindFirstChild("PlayerData") or 
                       LocalPlayer:FindFirstChild("Data") or
                       LocalPlayer:FindFirstChild("Stats")
    
    if playerData then
        local gloves = playerData:FindFirstChild("Gloves") or 
                       playerData:FindFirstChild("OwnedGloves") or
                       playerData:FindFirstChild("UnlockedGloves")
        
        if gloves then
            for _, glove in ipairs(GlovesList) do
                local gloveVal = gloves:FindFirstChild(glove.Name)
                if gloveVal and gloveVal:IsA("BoolValue") then
                    gloveVal.Value = true
                elseif not gloveVal then
                    local newVal = Instance.new("BoolValue")
                    newVal.Name = glove.Name
                    newVal.Value = true
                    newVal.Parent = gloves
                end
            end
        end
    end
    
    -- Спуфим GUI магазина
    self:SpoofShopGUI()
end

function RemoteALLSystem:SpoofShopGUI()
    -- Ищем GUI магазина и меняем отображение
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    for _, gui in ipairs(playerGui:GetDescendants()) do
        -- Меняем текст цен на "FREE" или "OWNED"
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local text = gui.Text:lower()
            if text:find("r%$") or text:find("robux") or text:find("%d+") then
                if text:find("buy") or text:find("purchase") then
                    gui.Text = "✅ FREE"
                    gui.TextColor3 = Color3.fromRGB(0, 255, 0)
                end
            end
        end
        
        -- Разблокируем заблокированные кнопки
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            if gui.Name:lower():find("locked") or gui.Name:lower():find("buy") then
                gui.Active = true
                gui.Visible = true
                if gui:FindFirstChild("Lock") then
                    gui.Lock.Visible = false
                end
            end
        end
    end
end

function RemoteALLSystem:Enable()
    self.Enabled = true
    self:SpoofGloveOwnership()
    
    -- Постоянно обновляем спуф
    spawn(function()
        while self.Enabled do
            self:SpoofGloveOwnership()
            task.wait(1)
        end
    end)
end

function RemoteALLSystem:Disable()
    self.Enabled = false
end

-- Инициализация
RemoteALLSystem:Init()

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ МОБИЛЬНОГО GUI
-- ═══════════════════════════════════════════════════════════════

-- Размеры для мобильных устройств
local ScreenSize = Camera.ViewportSize
local Scale = IsMobile and math.min(ScreenSize.X / 400, 1.2) or 1
local ButtonSize = IsMobile and 50 or 40
local FontSize = IsMobile and 16 or 14

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SlapFarmMobile"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Защита GUI
if syn then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════════════════════
-- КНОПКА ОТКРЫТИЯ (МОБИЛЬНАЯ)
-- ═══════════════════════════════════════════════════════════════

local OpenButton = Instance.new("ImageButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0, 60, 0, 60)
OpenButton.Position = UDim2.new(0, 15, 0.5, -30)
OpenButton.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
OpenButton.Image = ""
OpenButton.AutoButtonColor = true
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenButton

local OpenIcon = Instance.new("TextLabel")
OpenIcon.Size = UDim2.new(1, 0, 1, 0)
OpenIcon.BackgroundTransparency = 1
OpenIcon.Text = "🥊"
OpenIcon.TextSize = 30
OpenIcon.Font = Enum.Font.GothamBold
OpenIcon.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(150, 100, 255)
OpenStroke.Thickness = 3
OpenStroke.Parent = OpenButton

-- Делаем кнопку перетаскиваемой
local draggingOpen = false
local dragStartOpen = nil
local startPosOpen = nil

OpenButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingOpen = true
        dragStartOpen = input.Position
        startPosOpen = OpenButton.Position
    end
end)

OpenButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingOpen = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingOpen and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartOpen
        OpenButton.Position = UDim2.new(
            startPosOpen.X.Scale, startPosOpen.X.Offset + delta.X,
            startPosOpen.Y.Scale, startPosOpen.Y.Offset + delta.Y
        )
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНЫЙ ФРЕЙМ (МОБИЛЬНАЯ ВЕРСИЯ)
-- ═══════════════════════════════════════════════════════════════

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = IsMobile and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0, 360, 0, 550)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(100, 50, 200)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Градиент фона
local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 15, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20))
})
MainGradient.Rotation = 45
MainGradient.Parent = MainFrame

-- ═══════════════════════════════════════════════════════════════
-- ЗАГОЛОВОК
-- ═══════════════════════════════════════════════════════════════

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 55)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 16)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 20)
TitleFix.Position = UDim2.new(0, 0, 1, -20)
TitleFix.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -120, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🥊 SLAP FARM PRO"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 20
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Кнопка свернуть
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "Minimize"
MinimizeButton.Size = UDim2.new(0, 45, 0, 45)
MinimizeButton.Position = UDim2.new(1, -100, 0, 5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 24
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 10)
MinCorner.Parent = MinimizeButton

-- Кнопка закрытия
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "Close"
CloseButton.Size = UDim2.new(0, 45, 0, 45)
CloseButton.Position = UDim2.new(1, -50, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 10)
CloseCorner.Parent = CloseButton

-- ═══════════════════════════════════════════════════════════════
-- ТАБЫ
-- ═══════════════════════════════════════════════════════════════

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -20, 0, 50)
TabBar.Position = UDim2.new(0, 10, 0, 60)
TabBar.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 10)
TabCorner.Parent = TabBar

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabBar

local Tabs = {"🎮 Фарм", "🥊 Перчатки", "💎 RemoteALL", "⚙️ Настройки"}
local TabButtons = {}
local TabContents = {}
local CurrentTab = 1

for i, tabName in ipairs(Tabs) do
    local TabButton = Instance.new("TextButton")
    TabButton.Name = "Tab" .. i
    TabButton.Size = UDim2.new(0, 80, 0, 40)
    TabButton.BackgroundColor3 = i == 1 and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(50, 45, 70)
    TabButton.Text = tabName
    TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabButton.TextSize = IsMobile and 11 or 12
    TabButton.Font = Enum.Font.GothamBold
    TabButton.TextWrapped = true
    TabButton.Parent = TabBar
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = TabButton
    
    TabButtons[i] = TabButton
end

-- ═══════════════════════════════════════════════════════════════
-- КОНТЕНТ ТАБОВ
-- ═══════════════════════════════════════════════════════════════

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -20, 1, -130)
ContentContainer.Position = UDim2.new(0, 10, 0, 120)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- Функция создания контента таба
local function CreateTabContent(index)
    local Content = Instance.new("ScrollingFrame")
    Content.Name = "Content" .. index
    Content.Size = UDim2.new(1, 0, 1, 0)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 200)
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.Visible = index == 1
    Content.Parent = ContentContainer
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Content
    
    -- Авто-размер canvas
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
    end)
    
    TabContents[index] = Content
    return Content
end

for i = 1, #Tabs do
    CreateTabContent(i)
end

-- ═══════════════════════════════════════════════════════════════
-- ФУНКЦИИ UI
-- ═══════════════════════════════════════════════════════════════

local function CreateMobileToggle(parent, name, default, callback)
    local Toggle = Instance.new("Frame")
    Toggle.Name = name
    Toggle.Size = UDim2.new(1, 0, 0, 55)
    Toggle.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    Toggle.BorderSizePixel = 0
    Toggle.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Toggle
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = IsMobile and 15 or 14
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.Parent = Toggle
    
    local ToggleButton = Instance.new("Frame")
    ToggleButton.Size = UDim2.new(0, 65, 0, 32)
    ToggleButton.Position = UDim2.new(1, -80, 0.5, -16)
    ToggleButton.BackgroundColor3 = default and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 55, 80)
    ToggleButton.Parent = Toggle
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleButton
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 26, 0, 26)
    Circle.Position = default and UDim2.new(1, -29, 0.5, -13) or UDim2.new(0, 3, 0.5, -13)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = ToggleButton
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle
    
    local enabled = default
    
    local ClickButton = Instance.new("TextButton")
    ClickButton.Size = UDim2.new(1, 0, 1, 0)
    ClickButton.BackgroundTransparency = 1
    ClickButton.Text = ""
    ClickButton.Parent = Toggle
    
    ClickButton.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
        
        TweenService:Create(ToggleButton, tweenInfo, {
            BackgroundColor3 = enabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 55, 80)
        }):Play()
        
        TweenService:Create(Circle, tweenInfo, {
            Position = enabled and UDim2.new(1, -29, 0.5, -13) or UDim2.new(0, 3, 0.5, -13)
        }):Play()
        
        callback(enabled)
    end)
    
    return Toggle, function(val)
        enabled = val
        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
        TweenService:Create(ToggleButton, tweenInfo, {
            BackgroundColor3 = enabled and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 55, 80)
        }):Play()
        TweenService:Create(Circle, tweenInfo, {
            Position = enabled and UDim2.new(1, -29, 0.5, -13) or UDim2.new(0, 3, 0.5, -13)
        }):Play()
    end
end

local function CreateMobileButton(parent, name, color, callback)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 55)
    Button.BackgroundColor3 = color or Color3.fromRGB(100, 50, 200)
    Button.Text = name
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = IsMobile and 16 or 14
    Button.Font = Enum.Font.GothamBold
    Button.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Button
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(150, 100, 255)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.5
    Stroke.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        -- Анимация нажатия
        TweenService:Create(Button, TweenInfo.new(0.1), {
            Size = UDim2.new(0.98, 0, 0, 52)
        }):Play()
        task.wait(0.1)
        TweenService:Create(Button, TweenInfo.new(0.1), {
            Size = UDim2.new(1, 0, 0, 55)
        }):Play()
        
        callback()
    end)
    
    return Button
end

local function CreateMobileSlider(parent, name, min, max, default, callback)
    local Slider = Instance.new("Frame")
    Slider.Name = name
    Slider.Size = UDim2.new(1, 0, 0, 70)
    Slider.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    Slider.BorderSizePixel = 0
    Slider.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Slider
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 30)
    Label.Position = UDim2.new(0, 15, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = IsMobile and 15 or 14
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Slider
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "Value"
    ValueLabel.Size = UDim2.new(0, 60, 0, 28)
    ValueLabel.Position = UDim2.new(1, -75, 0, 5)
    ValueLabel.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 14
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Parent = Slider
    
    local ValCorner = Instance.new("UICorner")
    ValCorner.CornerRadius = UDim.new(0, 8)
    ValCorner.Parent = ValueLabel
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -30, 0, 12)
    SliderBar.Position = UDim2.new(0, 15, 0, 45)
    SliderBar.BackgroundColor3 = Color3.fromRGB(50, 45, 75)
    SliderBar.Parent = Slider
    
    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = SliderBar
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    SliderFill.Parent = SliderBar
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = SliderFill
    
    -- Ручка слайдера
    local Handle = Instance.new("Frame")
    Handle.Size = UDim2.new(0, 24, 0, 24)
    Handle.Position = UDim2.new((default - min) / (max - min), -12, 0.5, -12)
    Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handle.Parent = SliderBar
    
    local HandleCorner = Instance.new("UICorner")
    HandleCorner.CornerRadius = UDim.new(1, 0)
    HandleCorner.Parent = Handle
    
    local SliderButton = Instance.new("TextButton")
    SliderButton.Size = UDim2.new(1, 20, 1, 20)
    SliderButton.Position = UDim2.new(0, -10, 0, -10)
    SliderButton.BackgroundTransparency = 1
    SliderButton.Text = ""
    SliderButton.Parent = SliderBar
    
    local dragging = false
    
    local function UpdateSlider(inputPos)
        local barPos = SliderBar.AbsolutePosition.X
        local barSize = SliderBar.AbsoluteSize.X
        
        local percent = math.clamp((inputPos - barPos) / barSize, 0, 1)
        local value = math.floor(min + (max - min) * percent)
        
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        Handle.Position = UDim2.new(percent, -12, 0.5, -12)
        ValueLabel.Text = tostring(value)
        callback(value)
    end
    
    SliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateSlider(input.Position.X)
        end
    end)
    
    SliderButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            UpdateSlider(input.Position.X)
        end
    end)
    
    return Slider
end

local function CreateSection(parent, name)
    local Section = Instance.new("Frame")
    Section.Name = name
    Section.Size = UDim2.new(1, 0, 0, 35)
    Section.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
    Section.BorderSizePixel = 0
    Section.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Section
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(180, 140, 255)
    Label.TextSize = IsMobile and 15 or 14
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Section
    
    return Section
end

local function CreateGloveButton(parent, gloveData)
    local GloveBtn = Instance.new("TextButton")
    GloveBtn.Name = gloveData.Name
    GloveBtn.Size = UDim2.new(1, 0, 0, 60)
    GloveBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
    GloveBtn.Text = ""
    GloveBtn.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = GloveBtn
    
    local GloveName = Instance.new("TextLabel")
    GloveName.Size = UDim2.new(0.6, 0, 0.5, 0)
    GloveName.Position = UDim2.new(0, 15, 0, 5)
    GloveName.BackgroundTransparency = 1
    GloveName.Text = "🥊 " .. gloveData.Name
    GloveName.TextColor3 = Color3.fromRGB(255, 255, 255)
    GloveName.TextSize = IsMobile and 15 or 14
    GloveName.Font = Enum.Font.GothamBold
    GloveName.TextXAlignment = Enum.TextXAlignment.Left
    GloveName.Parent = GloveBtn
    
    local PriceLabel = Instance.new("TextLabel")
    PriceLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
    PriceLabel.Position = UDim2.new(0, 15, 0.5, 0)
    PriceLabel.BackgroundTransparency = 1
    PriceLabel.Text = gloveData.Robux > 0 and ("💎 " .. gloveData.Robux .. " R$") or "✅ Бесплатно"
    PriceLabel.TextColor3 = gloveData.Robux > 0 and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(100, 255, 100)
    PriceLabel.TextSize = IsMobile and 13 or 12
    PriceLabel.Font = Enum.Font.Gotham
    PriceLabel.TextXAlignment = Enum.TextXAlignment.Left
    PriceLabel.Parent = GloveBtn
    
    local SelectBtn = Instance.new("TextButton")
    SelectBtn.Size = UDim2.new(0, 80, 0, 35)
    SelectBtn.Position = UDim2.new(1, -95, 0.5, -17)
    SelectBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    SelectBtn.Text = "Выбрать"
    SelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectBtn.TextSize = 12
    SelectBtn.Font = Enum.Font.GothamBold
    SelectBtn.Parent = GloveBtn
    
    local SelCorner = Instance.new("UICorner")
    SelCorner.CornerRadius = UDim.new(0, 8)
    SelCorner.Parent = SelectBtn
    
    SelectBtn.MouseButton1Click:Connect(function()
        Config.SelectedGlove = gloveData.Name
        
        -- Обновляем визуал всех кнопок
        for _, btn in ipairs(parent:GetChildren()) do
            if btn:IsA("TextButton") then
                local sel = btn:FindFirstChild("TextButton")
                if sel then
                    sel.BackgroundColor3 = btn.Name == gloveData.Name and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(100, 50, 200)
                    sel.Text = btn.Name == gloveData.Name and "✓" or "Выбрать"
                end
            end
        end
        
        -- Если RemoteALL включен, пытаемся экипировать
        if Config.RemoteALL then
            EquipGlove(gloveData.Name)
        end
    end)
    
    return GloveBtn
end

-- ═══════════════════════════════════════════════════════════════
-- СТАТУС ПАНЕЛЬ
-- ═══════════════════════════════════════════════════════════════

local StatusPanel = Instance.new("Frame")
StatusPanel.Name = "StatusPanel"
StatusPanel.Size = UDim2.new(1, 0, 0, 70)
StatusPanel.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
StatusPanel.BorderSizePixel = 0
StatusPanel.Parent = TabContents[1]

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 12)
StatusCorner.Parent = StatusPanel

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Size = UDim2.new(0, 50, 1, 0)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "⏸️"
StatusIcon.TextSize = 30
StatusIcon.Font = Enum.Font.GothamBold
StatusIcon.Parent = StatusPanel

local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, -60, 1, -10)
StatusText.Position = UDim2.new(0, 55, 0, 5)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Статус: Ожидание\nЦель: Нет\nПощёчины: 0"
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.TextSize = IsMobile and 13 or 12
StatusText.Font = Enum.Font.Gotham
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextYAlignment = Enum.TextYAlignment.Center
StatusText.Parent = StatusPanel

-- ═══════════════════════════════════════════════════════════════
-- ЗАПОЛНЕНИЕ ТАБОВ
-- ═══════════════════════════════════════════════════════════════

-- ТАБ 1: ФАРМ
CreateSection(TabContents[1], "⚡ ОСНОВНОЕ")

local farmToggle, setFarmToggle = CreateMobileToggle(TabContents[1], "🎮 Автофарм", false, function(enabled)
    Config.Farming = enabled
    StatusIcon.Text = enabled and "🟢" or "⏸️"
end)

CreateMobileToggle(TabContents[1], "🔄 Авто-респавн", true, function(enabled)
    Config.AutoRespawn = enabled
end)

CreateMobileToggle(TabContents[1], "📍 Телепорт назад", true, function(enabled)
    Config.TeleportBack = enabled
end)

CreateMobileToggle(TabContents[1], "🛡️ Избегать края", true, function(enabled)
    Config.AvoidEdge = enabled
end)

CreateSection(TabContents[1], "🎯 НАСТРОЙКИ ЦЕЛИ")

CreateMobileSlider(TabContents[1], "📏 Дистанция атаки", 5, 50, 15, function(value)
    Config.AttackRange = value
end)

CreateMobileSlider(TabContents[1], "⚡ Скорость (мс)", 50, 500, 100, function(value)
    Config.FarmSpeed = value / 1000
end)

CreateSection(TabContents[1], "🔧 БЫСТРЫЕ ДЕЙСТВИЯ")

CreateMobileButton(TabContents[1], "💀 Респавн", Color3.fromRGB(200, 80, 80), function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end)

CreateMobileButton(TabContents[1], "📍 Телепорт на спавн", Color3.fromRGB(80, 150, 200), function()
    TeleportToSpawn()
end)

CreateMobileButton(TabContents[1], "🎯 К ближайшему игроку", Color3.fromRGB(200, 150, 80), function()
    local target = GetNearestPlayer()
    if target then
        TeleportToTarget(target)
    end
end)

-- ТАБ 2: ПЕРЧАТКИ
CreateSection(TabContents[2], "🥊 ВЫБЕРИТЕ ПЕРЧАТКУ")

for _, gloveData in ipairs(GlovesList) do
    CreateGloveButton(TabContents[2], gloveData)
end

-- ТАБ 3: REMOTEALL
CreateSection(TabContents[3], "💎 REMOTEALL СИСТЕМА")

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 80)
InfoLabel.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
InfoLabel.Text = "⚠️ RemoteALL позволяет локально разблокировать все перчатки.\n\n💡 Другие игроки видят ваши удары, но не видят какую перчатку вы используете локально."
InfoLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
InfoLabel.TextSize = IsMobile and 13 or 12
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextWrapped = true
InfoLabel.Parent = TabContents[3]

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 12)
InfoCorner.Parent = InfoLabel

local remoteToggle, setRemoteToggle = CreateMobileToggle(TabContents[3], "💎 RemoteALL Активен", false, function(enabled)
    Config.RemoteALL = enabled
    if enabled then
        RemoteALLSystem:Enable()
    else
        RemoteALLSystem:Disable()
    end
end)

CreateSection(TabContents[3], "🔓 БЫСТРЫЕ ДЕЙСТВИЯ")

CreateMobileButton(TabContents[3], "🔓 Разблокировать все перчатки", Color3.fromRGB(80, 200, 80), function()
    if Config.RemoteALL then
        RemoteALLSystem:SpoofGloveOwnership()
    else
        setRemoteToggle(true)
        Config.RemoteALL = true
        RemoteALLSystem:Enable()
    end
end)

CreateMobileButton(TabContents[3], "🛒 Открыть магазин (спуф)", Color3.fromRGB(200, 150, 50), function()
    RemoteALLSystem:SpoofShopGUI()
end)

-- Информация о робуксах
local RobuxInfo = Instance.new("Frame")
RobuxInfo.Size = UDim2.new(1, 0, 0, 60)
RobuxInfo.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
RobuxInfo.Parent = TabContents[3]

local RobuxCorner = Instance.new("UICorner")
RobuxCorner.CornerRadius = UDim.new(0, 12)
RobuxCorner.Parent = RobuxInfo

local RobuxText = Instance.new("TextLabel")
RobuxText.Size = UDim2.new(1, -20, 1, 0)
RobuxText.Position = UDim2.new(0, 10, 0, 0)
RobuxText.BackgroundTransparency = 1
RobuxText.Text = "💰 Локальные Робуксы: 999,999 R$\n✅ Все перчатки доступны локально"
RobuxText.TextColor3 = Color3.fromRGB(100, 255, 100)
RobuxText.TextSize = IsMobile and 14 or 13
RobuxText.Font = Enum.Font.GothamBold
RobuxText.Parent = RobuxInfo

-- ТАБ 4: НАСТРОЙКИ
CreateSection(TabContents[4], "⚙️ ОБЩИЕ НАСТРОЙКИ")

CreateMobileToggle(TabContents[4], "🎮 Авто-экипировка", true, function(enabled)
    Config.AutoEquip = enabled
end)

CreateMobileToggle(TabContents[4], "☕ Анти-АФК", true, function(enabled)
    Config.AntiAFK = enabled
end)

CreateMobileToggle(TabContents[4], "⚡ Ускорение (WalkSpeed)", false, function(enabled)
    Config.SpeedBoost = enabled
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = enabled and 32 or 16
    end
end)

CreateSection(TabContents[4], "🎯 РЕЖИМ ВЫБОРА ЦЕЛИ")

local TargetModes = {"Nearest", "Random", "MostSlaps"}
for _, mode in ipairs(TargetModes) do
    local ModeBtn = Instance.new("TextButton")
    ModeBtn.Size = UDim2.new(1, 0, 0, 50)
    ModeBtn.BackgroundColor3 = Config.TargetMode == mode and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(40, 35, 60)
    ModeBtn.Text = mode == "Nearest" and "📍 Ближайший" or (mode == "Random" and "🎲 Случайный" or "🏆 Больше пощёчин")
    ModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ModeBtn.TextSize = IsMobile and 15 or 14
    ModeBtn.Font = Enum.Font.GothamBold
    ModeBtn.Parent = TabContents[4]
    
    local ModeCorner = Instance.new("UICorner")
    ModeCorner.CornerRadius = UDim.new(0, 10)
    ModeCorner.Parent = ModeBtn
    
    ModeBtn.MouseButton1Click:Connect(function()
        Config.TargetMode = mode
        for _, btn in ipairs(TabContents[4]:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = btn.Text:find(mode == "Nearest" and "Ближайший" or (mode == "Random" and "Случайный" or "пощёчин")) and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(40, 35, 60)
            end
        end
    end)
end

CreateSection(TabContents[4], "📱 ИНТЕРФЕЙС")

CreateMobileButton(TabContents[4], "🔄 Сбросить позицию GUI", Color3.fromRGB(150, 100, 200), function()
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    OpenButton.Position = UDim2.new(0, 15, 0.5, -30)
end)

-- ═══════════════════════════════════════════════════════════════
-- ПЕРЕКЛЮЧЕНИЕ ТАБОВ
-- ═══════════════════════════════════════════════════════════════

for i, btn in ipairs(TabButtons) do
    btn.MouseButton1Click:Connect(function()
        CurrentTab = i
        
        for j, tabBtn in ipairs(TabButtons) do
            TweenService:Create(tabBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = j == i and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(50, 45, 70)
            }):Play()
        end
        
        for j, content in ipairs(TabContents) do
            content.Visible = j == i
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

function GetNearestPlayer()
    local nearestPlayer = nil
    local nearestDistance = math.huge
    
    local myCharacter = LocalPlayer.Character
    if not myCharacter or not myCharacter:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local myPosition = myCharacter.HumanoidRootPart.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local distance = (character.HumanoidRootPart.Position - myPosition).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
    end
    
    return nearestPlayer
end

function GetRandomPlayer()
    local validPlayers = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    table.insert(validPlayers, player)
                end
            end
        end
    end
    
    if #validPlayers > 0 then
        return validPlayers[math.random(1, #validPlayers)]
    end
    
    return nil
end

function GetPlayerWithMostSlaps()
    local targetPlayer = nil
    local maxSlaps = -1
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local slaps = 0
                    if player:FindFirstChild("leaderstats") then
                        local slapsVal = player.leaderstats:FindFirstChild("Slaps")
                        if slapsVal then
                            slaps = slapsVal.Value
                        end
                    end
                    
                    if slaps > maxSlaps then
                        maxSlaps = slaps
                        targetPlayer = player
                    end
                end
            end
        end
    end
    
    return targetPlayer
end

function GetTargetPlayer()
    if Config.TargetMode == "Nearest" then
        return GetNearestPlayer()
    elseif Config.TargetMode == "Random" then
        return GetRandomPlayer()
    elseif Config.TargetMode == "MostSlaps" then
        return GetPlayerWithMostSlaps()
    end
    return GetNearestPlayer()
end

function TeleportToTarget(target)
    if not target or not target.Character then return false end
    
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    
    local myCharacter = LocalPlayer.Character
    if not myCharacter then return false end
    
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    
    local offset = targetRoot.CFrame.LookVector * -3
    myRoot.CFrame = targetRoot.CFrame + offset + Vector3.new(0, 1, 0)
    
    return true
end

function TeleportToSpawn()
    local character = LocalPlayer.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local spawnLocation = Workspace:FindFirstChildOfClass("SpawnLocation")
    if spawnLocation then
        root.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
    else
        root.CFrame = CFrame.new(Config.SpawnPosition)
    end
end

function EquipGlove(gloveName)
    local character = LocalPlayer.Character
    if not character then return end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    
    -- Ищем перчатку
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(gloveName:lower()) then
            character.Humanoid:EquipTool(tool)
            return true
        end
    end
    
    -- Проверяем уже экипированную
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            return true
        end
    end
    
    -- Экипируем первую доступную
    local firstTool = backpack:FindFirstChildOfClass("Tool")
    if firstTool then
        character.Humanoid:EquipTool(firstTool)
        return true
    end
    
    return false
end

function Attack()
    local character = LocalPlayer.Character
    if not character then return end
    
    local glove = nil
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            glove = tool
            break
        end
    end
    
    if not glove then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local firstTool = backpack:FindFirstChildOfClass("Tool")
            if firstTool then
                character.Humanoid:EquipTool(firstTool)
                task.wait(0.1)
                glove = firstTool
            end
        end
    end
    
    if glove then
        -- Разные способы активации
        if glove:FindFirstChild("Slap") then
            glove.Slap:FireServer()
        elseif glove:FindFirstChild("SlapRemote") then
            glove.SlapRemote:FireServer()
        elseif glove:FindFirstChild("RemoteEvent") then
            glove.RemoteEvent:FireServer()
        elseif glove:FindFirstChild("Attack") then
            glove.Attack:FireServer()
        else
            glove:Activate()
        end
    end
end

function CheckIfFallen()
    local character = LocalPlayer.Character
    if not character then return true end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return true end
    
    return root.Position.Y < Config.SafeZoneY
end

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНОЙ ЦИКЛ ФАРМА
-- ═══════════════════════════════════════════════════════════════

local SlapCount = 0

local function FarmLoop()
    while task.wait(Config.FarmSpeed) do
        if not Config.Farming then
            StatusText.Text = "Статус: ⏸️ Пауза\nЦель: —\nПощёчины: " .. SlapCount
            continue
        end
        
        local character = LocalPlayer.Character
        if not character then
            StatusText.Text = "Статус: ⏳ Загрузка...\nЦель: —\nПощёчины: " .. SlapCount
            continue
        end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            if Config.AutoRespawn then
                StatusText.Text = "Статус: 💀 Респавн...\nЦель: —\nПощёчины: " .. SlapCount
                task.wait(1)
            end
            continue
        end
        
        -- Проверка падения
        if CheckIfFallen() then
            if Config.TeleportBack then
                StatusText.Text = "Статус: 📍 Возврат...\nЦель: —\nПощёчины: " .. SlapCount
                TeleportToSpawn()
                task.wait(0.5)
            end
            continue
        end
        
        -- Применяем буст скорости
        if Config.SpeedBoost then
            humanoid.WalkSpeed = 32
        end
        
        -- Поиск цели
        local target = GetTargetPlayer()
        
        if target then
            local targetChar = target.Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                local myRoot = character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local distance = (targetChar.HumanoidRootPart.Position - myRoot.Position).Magnitude
                    
                    if distance <= Config.AttackRange then
                        TeleportToTarget(target)
                        task.wait(0.05)
                        Attack()
                        SlapCount = SlapCount + 1
                        StatusText.Text = "Статус: 🥊 Атака!\nЦель: " .. target.Name .. "\nПощёчины: " .. SlapCount
                    else
                        TeleportToTarget(target)
                        StatusText.Text = "Статус: 🏃 Движение\nЦель: " .. target.Name .. "\nПощёчины: " .. SlapCount
                    end
                end
            end
        else
            StatusText.Text = "Статус: 🔍 Поиск...\nЦель: —\nПощёчины: " .. SlapCount
        end
    end
end

spawn(FarmLoop)

-- ═══════════════════════════════════════════════════════════════
-- АНТИ-АФК
-- ═══════════════════════════════════════════════════════════════

spawn(function()
    while task.wait(60) do
        if Config.AntiAFK then
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ОБРАБОТЧИКИ СОБЫТИЙ
-- ═══════════════════════════════════════════════════════════════

-- Кнопка открытия
OpenButton.MouseButton1Click:Connect(function()
    if not draggingOpen or (dragStartOpen and (UserInputService:GetMouseLocation() - Vector2.new(dragStartOpen.X, dragStartOpen.Y)).Magnitude < 10) then
        MainFrame.Visible = not MainFrame.Visible
        
        if MainFrame.Visible then
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                Size = IsMobile and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0, 360, 0, 550)
            }):Play()
        end
    end
end)

-- Кнопка свернуть
MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Кнопка закрытия
CloseButton.MouseButton1Click:Connect(function()
    Config.Farming = false
    ScreenGui:Destroy()
end)

-- Обработка смерти
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Config.AutoEquip then
        EquipGlove(Config.SelectedGlove)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- АНИМАЦИИ
-- ═══════════════════════════════════════════════════════════════

-- Анимация обводки
spawn(function()
    local hue = 0
    while ScreenGui.Parent do
        hue = (hue + 0.003) % 1
        MainStroke.Color = Color3.fromHSV(hue, 0.7, 0.9)
        OpenStroke.Color = Color3.fromHSV(hue, 0.7, 0.9)
        task.wait(0.03)
    end
end)

-- Пульсация кнопки открытия
spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(OpenButton, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.new(0, 65, 0, 65)
        }):Play()
        task.wait(1)
        TweenService:Create(OpenButton, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.new(0, 60, 0, 60)
        }):Play()
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- УВЕДОМЛЕНИЕ
-- ═══════════════════════════════════════════════════════════════

local Notification = Instance.new("Frame")
Notification.Size = UDim2.new(0, 280, 0, 80)
Notification.Position = UDim2.new(0.5, -140, 0, -100)
Notification.AnchorPoint = Vector2.new(0, 0)
Notification.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
Notification.Parent = ScreenGui

local NotifCorner = Instance.new("UICorner")
NotifCorner.CornerRadius = UDim.new(0, 12)
NotifCorner.Parent = Notification

local NotifText = Instance.new("TextLabel")
NotifText.Size = UDim2.new(1, -20, 1, 0)
NotifText.Position = UDim2.new(0, 10, 0, 0)
NotifText.BackgroundTransparency = 1
NotifText.Text = "✅ Slap Farm PRO загружен!\n🥊 Нажмите на кнопку слева\n💎 RemoteALL доступен"
NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
NotifText.TextSize = 14
NotifText.Font = Enum.Font.GothamBold
NotifText.TextWrapped = true
NotifText.Parent = Notification

-- Анимация уведомления
TweenService:Create(Notification, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
    Position = UDim2.new(0.5, -140, 0, 20)
}):Play()

task.delay(4, function()
    TweenService:Create(Notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -140, 0, -100)
    }):Play()
    task.wait(0.5)
    Notification:Destroy()
end)

print("═══════════════════════════════════════")
print("  🥊 SLAP BATTLES FARM PRO")
print("  📱 Mobile Edition + RemoteALL")
print("  💜 Скрипт успешно загружен!")
print("═══════════════════════════════════════")
