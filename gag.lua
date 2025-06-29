--[[
    @author: adaptado por ChatGPT
    @descrição: Grow a Garden Auto-Farm (Magic Library)
]]

--// Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Backpack = Player.Backpack
local Gui = Player.PlayerGui
local Character = Player.Character or Player.CharacterAdded:Wait()
local Events = ReplicatedStorage:WaitForChild("GameEvents")
local Farm = workspace:WaitForChild("Farm")

--// Variáveis
local Sheckles = Player.leaderstats.Sheckles
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

--// Magic Library
local Magic = loadstring(game:HttpGet("https://raw.githubusercontent.com/srpedrax/Magic-Library/main/source/Source.lua"))()
local UI = Magic:CreateWindow({ Title = GameName .. " | AutoFarm" })

--// UI Tabs e Seções
local tabMain = UI:MakeTab({ Name = "AutoFarm", TabTitle = true })
local sectionPlant = UI:addSection(tabMain, { Name = "Auto-Plant 🌱" })
local sectionHarvest = UI:addSection(tabMain, { Name = "Auto-Harvest 🚜" })
local sectionBuy = UI:addSection(tabMain, { Name = "Auto-Buy 🛒" })
local sectionSell = UI:addSection(tabMain, { Name = "Auto-Sell 💰" })
local sectionWalk = UI:addSection(tabMain, { Name = "Auto-Walk 🚶" })

--// Funções auxiliares
local function getMyFarm()
    for _, f in ipairs(Farm:GetChildren()) do
        if f:FindFirstChild("Important") and f.Important.Data.Owner.Value == Player.Name then
            return f
        end
    end
end

local function firePrompt(model)
    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then fireproximityprompt(prompt) end
end

local function getSeeds()
    local data = {}
    for _, src in pairs({Backpack, Character}) do
        for _, tool in ipairs(src:GetChildren()) do
            local name = tool:FindFirstChild("Plant_Name")
            local count = tool:FindFirstChild("Numbers")
            if name and count then
                data[name.Value] = { Tool = tool, Count = count.Value }
            end
        end
    end
    return data
end

local function getInventoryCrops()
    local result = {}
    for _, src in pairs({Backpack, Character}) do
        for _, tool in ipairs(src:GetChildren()) do
            local str = tool:FindFirstChild("Item_String")
            if str then table.insert(result, tool) end
        end
    end
    return result
end

local SeedStock = {}

local function getSeedStock(onlyWithStock)
    local SeedShop = Gui:FindFirstChild("Seed_Shop")
    if not SeedShop then return {} end

    local ItemsParent = SeedShop:FindFirstChild("Blueberry", true)
    if not ItemsParent or not ItemsParent.Parent then return {} end
    local Items = ItemsParent.Parent:GetChildren()

    local result = {}

    for _, Item in pairs(Items) do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end

        local StockText = MainFrame.Stock_Text.Text
        local StockCount = tonumber(StockText:match("%d+")) or 0

        if onlyWithStock then
            if StockCount > 0 then
                result[Item.Name] = StockCount
            end
        else
            SeedStock[Item.Name] = StockCount
        end
    end

    if onlyWithStock then
        return result
    else
        return SeedStock
    end
end


--// Funções de ação
local function plantAll(seed, random)
    local farm = getMyFarm()
    if not farm then return end
    local land = farm.Important.Plant_Locations
    local seeds = getSeeds()
    local data = seeds[seed]
    if not data then return end
    local toPlant = data.Count
    local equipped = Character:FindFirstChildWhichIsA("Humanoid")
    equipped:EquipTool(data.Tool)

    local tiles = land:GetChildren()
    for _, tile in pairs(tiles) do
        if toPlant <= 0 then break end
        local pos = tile.Position + Vector3.new(0, 0.13, 0)
        if random then
            pos = Vector3.new(
                math.random(tile.Position.X - 4, tile.Position.X + 4),
                0.13,
                math.random(tile.Position.Z - 4, tile.Position.Z + 4)
            )
        end
        Events.Plant_RE:FireServer(pos, seed)
        toPlant -= 1
        task.wait(0.3)
    end
end

local function harvestAll(ignores)
    local plants = getMyFarm().Important.Plants_Physical:GetChildren()
    for _, p in pairs(plants) do
        local variant = p:FindFirstChild("Variant")
        if variant and not ignores[variant.Value] then
            firePrompt(p)
        end
    end
end

local function sellCrops()
    local prev = Character:GetPivot()
    Character:PivotTo(CFrame.new(62, 4, -26))
    local before = Sheckles.Value
    repeat
        Events.Sell_Inventory:FireServer()
        task.wait()
    until Sheckles.Value ~= before
    Character:PivotTo(prev)
end

--// Variáveis de controle
local state = {
    autoPlant = false,
    autoHarvest = false,
    autoBuy = false,
    autoSell = false,
    autoWalk = false,
    noClip = false,
    onlyWithStock = false,
    seed = "",
    seedBuy = "",
    threshold = 15,
    ignores = {
        Normal = false,
        Gold = false,
        Rainbow = false
    },
    randomPlant = false,
    allowRandomWalk = true,
    walkDelay = 10
}

--// UI Auto-Plant
UI:AddDropdown(sectionPlant, {
    Name = "Selecionar Semente",
    Options = table.keys(getSeedStock(false)),
    Default = "",
    Callback = function(v) state.seed = v end
})
UI:AddToggle(sectionPlant, {
    Name = "Ativar Auto-Plant",
    Default = false,
    Callback = function(v) state.autoPlant = v end
})
UI:AddToggle(sectionPlant, {
    Name = "Plantio aleatório",
    Default = false,
    Callback = function(v) state.randomPlant = v end
})
UI:AddButton(sectionPlant, {
    Name = "Plantar Tudo Agora",
    Callback = function() plantAll(state.seed, state.randomPlant) end
})

--// UI Auto-Harvest
UI:AddToggle(sectionHarvest, {
    Name = "Ativar Auto-Harvest",
    Default = false,
    Callback = function(v) state.autoHarvest = v end
})
for k in pairs(state.ignores) do
    UI:AddToggle(sectionHarvest, {
        Name = "Ignorar " .. k,
        Default = false,
        Callback = function(v) state.ignores[k] = v end
    })
end

--// UI Auto-Buy
UI:AddDropdown(sectionBuy, {
    Name = "Semente para Comprar",
    Options = table.keys(getSeedStock(false)),
    Default = "",
    Callback = function(v) state.seedBuy = v end
})
UI:AddToggle(sectionBuy, {
    Name = "Auto-Buy ativado",
    Default = false,
    Callback = function(v) state.autoBuy = v end
})
UI:AddToggle(sectionBuy, {
    Name = "Apenas com estoque",
    Default = false,
    Callback = function(v) state.onlyWithStock = v end
})
UI:AddButton(sectionBuy, {
    Name = "Comprar Tudo Agora",
    Callback = function()
        local stock = getSeedStock(false)
        local count = stock[state.seedBuy]
        for i = 1, count do
            Events.BuySeedStock:FireServer(state.seedBuy)
        end
    end
})

--// UI Auto-Sell
UI:AddToggle(sectionSell, {
    Name = "Ativar Auto-Sell",
    Default = false,
    Callback = function(v) state.autoSell = v end
})
UI:AddSlider(sectionSell, {
    Name = "Qtd mínima para vender",
    Min = 1,
    Max = 199,
    DefaultValue = 15,
    Callback = function(v) state.threshold = v end
})
UI:AddButton(sectionSell, {
    Name = "Vender Agora",
    Callback = sellCrops
})

--// UI Walk
UI:AddToggle(sectionWalk, {
    Name = "Auto-Walk ativado",
    Default = false,
    Callback = function(v) state.autoWalk = v end
})
UI:AddToggle(sectionWalk, {
    Name = "Permitir andada aleatória",
    Default = true,
    Callback = function(v) state.allowRandomWalk = v end
})
UI:AddToggle(sectionWalk, {
    Name = "NoClip",
    Default = false,
    Callback = function(v) state.noClip = v end
})
UI:AddSlider(sectionWalk, {
    Name = "Delay (s)",
    Min = 1,
    Max = 30,
    DefaultValue = 10,
    Callback = function(v) state.walkDelay = v end
})

--// Loops
RunService.Stepped:Connect(function()
    if state.noClip then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

Backpack.ChildAdded:Connect(function()
    if state.autoSell and #getInventoryCrops() >= state.threshold then
        sellCrops()
    end
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        if state.autoHarvest then harvestAll(state.ignores) end
        if state.autoPlant then plantAll(state.seed, state.randomPlant) end
        if state.autoBuy then
            local list = getSeedStock(state.onlyWithStock)
            local count = list[state.seedBuy] or 0
            for i = 1, count do Events.BuySeedStock:FireServer(state.seedBuy) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(math.random(1, state.walkDelay))
        if not state.autoWalk then continue end
        local plants = getMyFarm().Important.Plants_Physical:GetChildren()
        local move = plants[math.random(1, #plants)]
        if move and move:FindFirstChild("PrimaryPart") then
            Character:MoveTo(move:GetPivot().Position)
        elseif state.allowRandomWalk then
            Character:MoveTo(Vector3.new(math.random(-50, 50), 4, math.random(-50, 50)))
        end
    end
end)
