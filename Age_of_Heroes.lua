-- Primeiro, carregue a Orion Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local player = Players.LocalPlayer

local Module = require(ReplicatedStorage.Modules.SharedLocal)
local punchEvent = ReplicatedStorage.Events.Punch
local upgradeEvent = ReplicatedStorage.Events.UpgradeAbility

for _, v in next, getconnections(player.Idled) do
    v:Disable()
end

if not player.Character then
    repeat wait();
        getsenv(player:WaitForChild('PlayerScripts'):WaitForChild('IntroScript')).Play()
    until player.Character and Module.IsValidActor(player.Character)
end

spawn(function()
    while task.wait() do
        getsenv(player.PlayerScripts.GameClient)._G.energy = math.huge
    end
end)

function lightPunch()
    task.spawn(function() punchEvent:FireServer(0,0.1,1) end)
end

function heavyPunch()
    task.spawn(function() punchEvent:FireServer(0.4,0.1,1) end)
end

function goInvisible()
    invisibleStatus = true
    local ogPosition = player.Character.HumanoidRootPart.CFrame
    
    player.Character.HumanoidRootPart.CFrame = CFrame.new(-2463.92822, 256.457916, -2009.25574)
    wait(0.5)
    local Clone = player.Character.LowerTorso.Root:Clone()
    player.Character.LowerTorso.Root:Destroy()
    Clone.Parent = player.Character.LowerTorso
    wait(0.5)
    player.Character.HumanoidRootPart.CFrame = ogPosition
end
player.Character.Humanoid.Died:Connect(function()
    invisibleStatus = false
end)

function upgradeStatistic(stat, types, amount)
    if stat == nil then return end
    if types == nil then return end
    if amount == nil then return end

    if types == "default" then
        upgradeEvent:InvokeServer(stat)
    elseif types == "fast" then
        for i = 1, amount do
            task.spawn(function()
                upgradeEvent:InvokeServer(stat)
            end)
        end
    end 
end

function killPlayer(target)
    target = Players:FindFirstChild(target)
    local pos = player.Character.HumanoidRootPart.CFrame
    if target ~= nil and Module.IsValidActor(target.Character) and Module.NotProtected(target.Character) and Module.IsValidActor(player.Character) then
        if target.Character:FindFirstChild('ForceField') then
            repeat task.wait();
            until not target.Character:FindFirstChild('ForceField')
        end

        Connection = target.Character.DescendantAdded:connect(function(na)
            if na.Name == "ForceField" then
                abortStatus = true
            end
        end)

        repeat
            task.wait()
            if target.Character:FindFirstChild('HumanoidRootPart') and player.Character:FindFirstChild('HumanoidRootPart') then
                player.Character.HumanoidRootPart.CFrame = (target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 0.7))
                for i = 1, 20 do
                    heavyPunch()
                end
            end
        until not killPlayerStatus or not Module.IsValidActor(target.Character) or not Module.NotProtected(target.Character) or not Module.IsValidActor(player.Character)
        Connection:Disconnect()
        player.Character.HumanoidRootPart.CFrame = pos
    end
end

local function findPlayer(name)
    for _, Player in ipairs(Players:GetPlayers()) do
        if (string.lower(name) == string.sub(string.lower(Player.Name), 1, #name)) then
            return Player;
        end
    end
end

function spec()
    local plrtoview = selectedPlayer
    if not plrtoview then return end
    
    local ptv = findPlayer(plrtoview)
    if not ptv or not game.Workspace:FindFirstChild(ptv.Name) then return end
    
    spectate = true
    local Camera = game.Workspace.CurrentCamera
    Camera.CameraSubject = game.Workspace[ptv.Name].Humanoid
    Camera.CameraType = Enum.CameraType.Follow
    
    while spectate and game.Workspace:FindFirstChild(ptv.Name) do
        task.wait()
    end
    
    Camera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
    Camera.CameraType = Enum.CameraType.Custom
end

-- Title Destroyer (the thing above your head)
task.spawn(function()
    while task.wait() do
        if hidePlayerTitle or invisibleStatus then
            pcall(function()
                player.Character.HumanoidRootPart.titleGui.Frame:Destroy()
            end)
        end
    end
end)

-- Orb Farm
task.spawn(function()
    while task.wait() do
        if orbFarm then
            pcall(function()
                for i,v in pairs(workspace.ExperienceOrbs:GetChildren()) do
                    firetouchinterest(player.Character.HumanoidRootPart, v, 0)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if autoStats then
            upgradeStatistic(selectedStat, statMethod, statAmount)
        end
    end
end)

-- Hero Farm (farms thugs)
task.spawn(function()
    while task.wait() do
        if heroFarm then
            local target = workspace:FindFirstChild('Thug')
            if target then
                repeat wait(.1)
                    pcall(function()
                        player.Character.HumanoidRootPart.CFrame = (target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 0.7))
                        heavyPunch()
                    end)
                until not Module.IsValidActor(target) or not Module.IsValidActor(player.Character) or target.Humanoid.Health <= 0
                target:Destroy()
            end
        end
    end
end)

-- Villian Farm (farms civilians and police)
task.spawn(function()
    while task.wait() do
        if villianFarm then
            local target = workspace:FindFirstChild('Civilian') or workspace:FindFirstChild('Police')
            if target then
                repeat wait(.1)
                    pcall(function()
                        player.Character.HumanoidRootPart.CFrame = (target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 0.7))
                        heavyPunch()
                    end)
                until not Module.IsValidActor(target) or not Module.IsValidActor(player.Character) or target.Humanoid.Health <= 0
                target:Destroy()
            end
        end
    end
end)

-- Farm All (farms civilians and police and thugs)
task.spawn(function()
    while task.wait() do
        if villianFarm then
            local target = workspace:FindFirstChild('Civilian') or workspace:FindFirstChild('Police') or workspace:FindFirstChild('Thug')
            if target then
                repeat wait(.1)
                    pcall(function()
                        player.Character.HumanoidRootPart.CFrame = (target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 0.7))
                        heavyPunch()
                    end)
                until not Module.IsValidActor(target) or not Module.IsValidActor(player.Character) or target.Humanoid.Health <= 0
                target:Destroy()
            end
        end
    end
end)

-- Criando o menu usando a Orion Library
local Window = OrionLib:MakeWindow({Name = "Zen X » Age of Heroes (Rewritten)", HidePremium = false, SaveConfig = true, ConfigFolder = "ZenX"})

-- Tabs
local MainTab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- Seções
local auto_farm = MainTab:AddSection({Name = "Auto Farm"})
local auto_stats = MainTab:AddSection({Name = "Auto Stats"})
local target_section = MainTab:AddSection({Name = "Target"})
local misc_section = MainTab:AddSection({Name = "Misc"})

-- Auto Farm Section
auto_farm:AddToggle({Name = "Auto collect orbs", Default = false, Callback = function(value) orbFarm = value end})
auto_farm:AddToggle({Name = "Hero Farm", Default = false, Callback = function(value) heroFarm = value end})
auto_farm:AddToggle({Name = "Villian Farm", Default = false, Callback = function(value) villianFarm = value end})
auto_farm:AddToggle({Name = "Farm All", Default = false, Callback = function(value) farmAll = value end})

-- Auto Stats Section
auto_stats:AddToggle({Name = "Auto Stats", Default = false, Callback = function(value) autoStats = value end})
auto_stats:AddTextbox({Name = "Method (default, fast)", Default = "", TextDisappear = true, Callback = function(value) statMethod = value statAmount = 10 end})
auto_stats:AddTextbox({Name = "Statistic", Default = "", TextDisappear = true, Callback = function(value) selectedStat = value end})

-- Target Section
target_section:AddTextbox({Name = "Player", Default = "", TextDisappear = true, Callback = function(value) selectedPlayer = value end})
target_section:AddButton({Name = "Kill Player", Callback = function() killPlayer(selectedPlayer) end})
target_section:AddButton({Name = "Spectate", Callback = function() spec() end})

-- Misc Section
misc_section:AddButton({Name = "Invisible", Callback = function() goInvisible() end})
misc_section:AddToggle({Name = "Hide Title", Default = false, Callback = function(value) hidePlayerTitle = value end})

OrionLib:Init()
