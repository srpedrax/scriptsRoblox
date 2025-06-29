--[[
    @author depso (depthso)
    @description Grow a Garden auto-farm script
    https://www.roblox.com/games/126884695634066
]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

local ShecklesCount = Leaderstats.Sheckles
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

--// Magic
local Magic = loadstring(game:HttpGet("https://raw.githubusercontent.com/srpedrax/Magic-Library/main/source/Source.lua"))()
local UI = Magic:CreateWindow({ Title = GameName .. " | AutoFarm" })

--// Folders
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

local Accent = {
    DarkGreen = Color3.fromRGB(45, 95, 25),
    Green = Color3.fromRGB(69, 142, 40),
    Brown = Color3.fromRGB(26, 20, 8),
}

--// Dicts
local SeedStock = {}
local OwnedSeeds = {}
local HarvestIgnores = {
	Normal = false,
	Gold = false,
	Rainbow = false
}

--// Globals
local SelectedSeed = ""
local SelectedSeedStock = ""
local AutoPlantRandom, AutoPlant, AutoHarvest, AutoBuy, AutoSell = false, false, false, false, false
local SellThreshold = 15
local NoClip = false
local AutoWalk, AutoWalkAllowRandom, AutoWalkMaxWait = false, true, 10
local AutoWalkStatus = { Text = "" }
local OnlyShowStock = true

--// Interface functions
local function Plant(Position: Vector3, Seed: string)
	GameEvents.Plant_RE:FireServer(Position, Seed)
	task.wait(0.3)
end

local function GetFarms()
	return Farms:GetChildren()
end

local function GetFarmOwner(Farm: Folder): string
	return Farm.Important.Data.Owner.Value
end

local function GetFarm(PlayerName: string): Folder?
	for _, Farm in next, GetFarms() do
		if GetFarmOwner(Farm) == PlayerName then
			return Farm
		end
	end
end

local IsSelling = false
local function SellInventory()
	local Character = LocalPlayer.Character
	local Previous = Character:GetPivot()
	local PreviousSheckles = ShecklesCount.Value
	if IsSelling then return end
	IsSelling = true

	Character:PivotTo(CFrame.new(62, 4, -26))
	while task.wait() do
		if ShecklesCount.Value ~= PreviousSheckles then break end
		GameEvents.Sell_Inventory:FireServer()
	end
	Character:PivotTo(Previous)
	task.wait(0.2)
	IsSelling = false
end

local function BuySeed(Seed: string)
	GameEvents.BuySeedStock:FireServer(Seed)
end

local function BuyAllSelectedSeeds()
	local Seed = SelectedSeedStock
	local Stock = SeedStock[Seed]
	if not Stock or Stock <= 0 then return end
	for _ = 1, Stock do
		BuySeed(Seed)
	end
end

local function GetSeedInfo(Seed: Tool): number?
	local PlantName = Seed:FindFirstChild("Plant_Name")
	local Count = Seed:FindFirstChild("Numbers")
	if not PlantName then return end
	return PlantName.Value, Count.Value
end

local function CollectSeedsFromParent(Parent, Seeds: table)
	for _, Tool in next, Parent:GetChildren() do
		local Name, Count = GetSeedInfo(Tool)
		if Name then
			Seeds[Name] = { Count = Count, Tool = Tool }
		end
	end
end

local function CollectCropsFromParent(Parent, Crops: table)
	for _, Tool in next, Parent:GetChildren() do
		local Name = Tool:FindFirstChild("Item_String")
		if Name then
			table.insert(Crops, Tool)
		end
	end
end

local function GetOwnedSeeds(): table
	CollectSeedsFromParent(Backpack, OwnedSeeds)
	CollectSeedsFromParent(LocalPlayer.Character, OwnedSeeds)
	return OwnedSeeds
end

local function GetInvCrops(): table
	local Crops = {}
	CollectCropsFromParent(Backpack, Crops)
	CollectCropsFromParent(LocalPlayer.Character, Crops)
	return Crops
end

local function GetArea(Base: BasePart)
	local Center = Base:GetPivot()
	local Size = Base.Size
	local X1 = math.ceil(Center.X - (Size.X / 2))
	local Z1 = math.ceil(Center.Z - (Size.Z / 2))
	local X2 = math.floor(Center.X + (Size.X / 2))
	local Z2 = math.floor(Center.Z + (Size.Z / 2))
	return X1, Z1, X2, Z2
end

local function EquipCheck(Tool)
	if Tool.Parent == Backpack then
		LocalPlayer.Character.Humanoid:EquipTool(Tool)
	end
end

--// Auto farm functions
local MyFarm = GetFarm(LocalPlayer.Name)
local MyImportant = MyFarm.Important
local PlantLocations = MyImportant.Plant_Locations
local PlantsPhysical = MyImportant.Plants_Physical

local Dirt = PlantLocations:FindFirstChildOfClass("Part")
local X1, Z1, X2, Z2 = GetArea(Dirt)

local function GetRandomFarmPoint(): Vector3
	local FarmLands = PlantLocations:GetChildren()
	local FarmLand = FarmLands[math.random(1, #FarmLands)]
	local X1, Z1, X2, Z2 = GetArea(FarmLand)
	return Vector3.new(math.random(X1, X2), 4, math.random(Z1, Z2))
end

local function AutoPlantLoop()
	local Seed = SelectedSeed
	local SeedData = OwnedSeeds[Seed]
	if not SeedData or SeedData.Count <= 0 then return end
	EquipCheck(SeedData.Tool)
	local Planted = 0
	local Step = 1

	if AutoPlantRandom then
		for _ = 1, SeedData.Count do
			Plant(GetRandomFarmPoint(), Seed)
		end
	end

	for X = X1, X2, Step do
		for Z = Z1, Z2, Step do
			if Planted > SeedData.Count then break end
			Plant(Vector3.new(X, 0.13, Z), Seed)
			Planted += 1
		end
	end
end

local function CanHarvest(Plant)
	local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
	return Prompt and Prompt.Enabled
end

local function CollectHarvestable(Parent, Plants, IgnoreDistance)
	local PlayerPosition = LocalPlayer.Character:GetPivot().Position
	for _, Plant in next, Parent:GetChildren() do
		if Plant:FindFirstChild("Fruits") then
			CollectHarvestable(Plant.Fruits, Plants, IgnoreDistance)
		end
		if not IgnoreDistance and (PlayerPosition - Plant:GetPivot().Position).Magnitude > 15 then continue end
		local Variant = Plant:FindFirstChild("Variant")
		if Variant and HarvestIgnores[Variant.Value] then continue end
		if CanHarvest(Plant) then
			table.insert(Plants, Plant)
		end
	end
end

local function GetHarvestablePlants(IgnoreDistance)
	local Plants = {}
	CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
	return Plants
end

local function HarvestPlants()
	for _, Plant in next, GetHarvestablePlants() do
		fireproximityprompt(Plant:FindFirstChild("ProximityPrompt", true))
	end
end

local function AutoSellCheck()
	if AutoSell and #GetInvCrops() >= SellThreshold then
		SellInventory()
	end
end

local function AutoWalkLoop()
	if IsSelling then return end
	local Character = LocalPlayer.Character
	local Humanoid = Character.Humanoid
	local Plants = GetHarvestablePlants(true)
	local DoRandom = #Plants == 0 or math.random(1, 3) == 2

	if AutoWalkAllowRandom and DoRandom then
		Humanoid:MoveTo(GetRandomFarmPoint())
		AutoWalkStatus.Text = "Random point"
		return
	end

	for _, Plant in next, Plants do
		Humanoid:MoveTo(Plant:GetPivot().Position)
		AutoWalkStatus.Text = Plant.Name
	end
end

local function NoclipLoop()
	if NoClip and LocalPlayer.Character then
		for _, Part in LocalPlayer.Character:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanCollide = false
			end
		end
	end
end

local function MakeLoop(Flag, Func)
	coroutine.wrap(function()
		while task.wait(0.01) do
			if Flag then Func() end
		end
	end)()
end

local function StartServices()
	MakeLoop(AutoWalk, function()
		AutoWalkLoop()
		task.wait(math.random(1, AutoWalkMaxWait))
	end)

	MakeLoop(AutoHarvest, HarvestPlants)
	MakeLoop(AutoBuy, BuyAllSelectedSeeds)
	MakeLoop(AutoPlant, AutoPlantLoop)

	while task.wait(0.1) do
		GetSeedStock()
		GetOwnedSeeds()
	end
end

--// Connections
RunService.Stepped:Connect(NoclipLoop)
Backpack.ChildAdded:Connect(AutoSellCheck)

--// Start
StartServices()
