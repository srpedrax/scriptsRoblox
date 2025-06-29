--[[
    @author depso (depthso)
    @adapted_by ChatGPT for Magic Library
    @description Grow a Garden auto-farm script
    https://www.roblox.com/games/126884695634066
]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ShecklesCount = Leaderstats:WaitForChild("Sheckles")
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

--// Magic UI
local Magic = loadstring(game:HttpGet("https://raw.githubusercontent.com/srpedrax/Magic-Library/main/source/Source.lua"))()
local UI = Magic:CreateWindow({ Title = GameName .. " | AutoFarm" })

--// Game References
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Farms = workspace:WaitForChild("Farm")

--// Data
local SeedStock, OwnedSeeds = {}, {}
local HarvestIgnores = { Normal = false, Gold = false, Rainbow = false }

--// Globals
local SelectedSeed = ""
local SelectedSeedStock = ""
local AutoPlant, AutoPlantRandom = false, false
local AutoHarvest, AutoBuy = false, false
local AutoSell, NoClip = false, false
local AutoWalk, AutoWalkAllowRandom = false, true
local SellThreshold, AutoWalkMaxWait = 15, 10

--// Farm detection
local function GetFarm(PlayerName)
    for _, Farm in ipairs(Farms:GetChildren()) do
        if Farm.Important.Data.Owner.Value == PlayerName then
            return Farm
        end
    end
end

local MyFarm = GetFarm(LocalPlayer.Name)
local PlantLocations = MyFarm.Important.Plant_Locations
local PlantsPhysical = MyFarm.Important.Plants_Physical

local function GetArea(Base)
    local Center, Size = Base.Position, Base.Size
    local X1 = math.ceil(Center.X - Size.X/2)
    local Z1 = math.ceil(Center.Z - Size.Z/2)
    local X2 = math.floor(Center.X + Size.X/2)
    local Z2 = math.floor(Center.Z + Size.Z/2)
    return X1, Z1, X2, Z2
end

local Dirt = PlantLocations:FindFirstChildOfClass("Part")
local X1, Z1, X2, Z2 = GetArea(Dirt)

--// Utility Functions
local function Plant(pos, seed)
    GameEvents.Plant_RE:FireServer(pos, seed)
end

local function GetOwnedSeeds()
    OwnedSeeds = {}
    for _, Tool in ipairs(Backpack:GetChildren()) do
        local nameObj = Tool:FindFirstChild("Plant_Name")
        local countObj = Tool:FindFirstChild("Numbers")
        if nameObj and countObj then
            OwnedSeeds[nameObj.Value] = { Count = countObj.Value, Tool = Tool }
        end
    end
    return OwnedSeeds
end

local function GetSeedStock(onlyStock)
    local items = PlayerGui:WaitForChild("Seed_Shop"):FindFirstChild("Blueberry", true).Parent:GetChildren()
    local result = {}
    for _, item in pairs(items) do
        local frame = item:FindFirstChild("Main_Frame")
        if frame then
            local stock = tonumber(frame.Stock_Text.Text:match("%d+")) or 0
            if not onlyStock or stock > 0 then
                result[item.Name] = stock
                SeedStock[item.Name] = stock
            end
        end
    end
    return result
end

local function GetRandomFarmPoint()
    local parts = PlantLocations:GetChildren()
    local part = parts[math.random(1, #parts)]
    local x1, z1, x2, z2 = GetArea(part)
    return Vector3.new(math.random(x1, x2), 4, math.random(z1, z2))
end

local function AutoPlantLoop()
    local seeds = GetOwnedSeeds()
    local data = seeds[SelectedSeed]
    if not data then return end

    local count, tool = data.Count, data.Tool
    if count <= 0 then return end
    LocalPlayer.Character.Humanoid:EquipTool(tool)

    for i = 1, count do
        local pos = AutoPlantRandom and GetRandomFarmPoint() or Vector3.new(X1 + (i % (X2-X1)), 0.13, Z1 + math.floor(i / (X2-X1)))
        Plant(pos, SelectedSeed)
    end
end

local function HarvestPlants()
    for _, Plant in ipairs(PlantsPhysical:GetDescendants()) do
        local prompt = Plant:FindFirstChild("ProximityPrompt", true)
        local variant = Plant:FindFirstChild("Variant")
        if prompt and prompt.Enabled and variant and not HarvestIgnores[variant.Value] then
            fireproximityprompt(prompt)
        end
    end
end

local function BuyAllSelectedSeeds()
    local stock = SeedStock[SelectedSeedStock] or 0
    for i = 1, stock do
        GameEvents.BuySeedStock:FireServer(SelectedSeedStock)
    end
end

local function SellInventory()
    local char = LocalPlayer.Character
    local before = ShecklesCount.Value
    if not char then return end
    char:PivotTo(CFrame.new(62, 4, -26))
    while wait() do
        if ShecklesCount.Value ~= before then break end
        GameEvents.Sell_Inventory:FireServer()
    end
end

local function AutoWalkLoop()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if AutoWalkAllowRandom then
        hum:MoveTo(GetRandomFarmPoint())
    end
end

local function NoclipLoop()
    if not NoClip then return end
    for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end
end

--// UI
local tab = UI:MakeTab({ Name = "AutoFarm", TabTitle = true })

local function listKeys(tbl)
    local t = {}
    for k in pairs(tbl) do table.insert(t, k) end
    return t
end

local s1 = UI:addSection(tab, { Name = "Plant" })
UI:AddDropdown(s1, {
    Name = "Selecionar Semente",
    Options = listKeys(GetSeedStock(true)),
    Default = "",
    Callback = function(v) SelectedSeed = v end
})
UI:AddToggle(s1, { Name = "Auto-Plant", Default = false, Callback = function(v) AutoPlant = v end })
UI:AddToggle(s1, { Name = "Pontos Aleatórios", Default = false, Callback = function(v) AutoPlantRandom = v end })
UI:AddButton(s1, { Name = "Plantar Agora", Callback = AutoPlantLoop })

local s2 = UI:addSection(tab, { Name = "Harvest" })
UI:AddToggle(s2, { Name = "Auto-Harvest", Default = false, Callback = function(v) AutoHarvest = v end })
for k in pairs(HarvestIgnores) do
    UI:AddToggle(s2, { Name = "Ignorar "..k, Default = false, Callback = function(v) HarvestIgnores[k] = v end })
end

local s3 = UI:addSection(tab, { Name = "Buy" })
UI:AddDropdown(s3, {
    Name = "Semente para Comprar",
    Options = listKeys(GetSeedStock(true)),
    Default = "",
    Callback = function(v) SelectedSeedStock = v end
})
UI:AddToggle(s3, { Name = "Auto-Buy", Default = false, Callback = function(v) AutoBuy = v end })
UI:AddButton(s3, { Name = "Comprar Tudo", Callback = BuyAllSelectedSeeds })

local s4 = UI:addSection(tab, { Name = "Sell" })
UI:AddToggle(s4, { Name = "Auto-Sell", Default = false, Callback = function(v) AutoSell = v end })
UI:AddSlider(s4, {
    Name = "Qtd mínima",
    Min = 1,
    Max = 199,
    DefaultValue = 15,
    Callback = function(v) SellThreshold = v end
})
UI:AddButton(s4, { Name = "Vender Agora", Callback = SellInventory })

local s5 = UI:addSection(tab, { Name = "Walk & Noclip" })
UI:AddToggle(s5, { Name = "Auto-Walk", Default = false, Callback = function(v) AutoWalk = v end })
UI:AddToggle(s5, { Name = "Andar Aleatoriamente", Default = true, Callback = function(v) AutoWalkAllowRandom = v end })
UI:AddToggle(s5, { Name = "NoClip", Default = false, Callback = function(v) NoClip = v end })
UI:AddSlider(s5, {
    Name = "Delay (s)",
    Min = 1,
    Max = 30,
    DefaultValue = 10,
    Callback = function(v) AutoWalkMaxWait = v end
})

--// Loops
RunService.Stepped:Connect(NoclipLoop)
Backpack.ChildAdded:Connect(function()
    if AutoSell and #Backpack:GetChildren() >= SellThreshold then
        SellInventory()
    end
end)

--// Main Services
coroutine.wrap(function()
    while true do wait(1)
        GetSeedStock(true)
        GetOwnedSeeds()
        if AutoBuy then BuyAllSelectedSeeds() end
        if AutoPlant then AutoPlantLoop() end
        if AutoHarvest then HarvestPlants() end
        if AutoWalk then AutoWalkLoop() wait(AutoWalkMaxWait) end
    end
end)()
