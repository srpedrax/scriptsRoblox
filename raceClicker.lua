-- Library
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local delay = 0.1
local autoFinish, autoClick, autoRebirth, autoHatch, autoCraft, autoEquipBest = false, false, false, false, false, false

-- Variables
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

-- Tables
local Maps = {"Home - 0 Rebirth", "Space - 2 Rebirth", "Ocean - 4 Rebirth"}
local Eggs = {"5 Wins", "25 Wins", "175 Wins", "1k Wins", "10k Wins", "75k Wins", "250k Wins", "1M Wins", "2.5M Wins", "5M Wins"}
local Codes = {"UPDATECLICKCODE", "hallowx3", "Accelhidden", "opx3code", "500KLikes", "Almost100MVisits", "1MGroupMembers", "Thankyou50M", "NewUpdate", "LetsGo5KLikes", "ThanksFor5MillionsVisits"}

-- Main
local Window = OrionLib:MakeWindow({Name = "🏆 - Race Clicker Script", HidePremium = false, SaveConfig = true, ConfigFolder = "OrionTest"})

local Tab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local Section = Tab:AddSection({
    Name = "Actions"
})

Section:AddSlider({
    Name = "Auto Race Delay ( /s )",
    Min = 0.01,
    Max = 1,
    Default = 0.1,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Delay",
    Callback = function(value)
      delay = value
    end    
})

Section:AddToggle({
    Name = "Auto Race",
    Default = false,
    Callback = function(bool)
        autoFinish = bool
        
        task.spawn(function()
            while autoFinish do
                task.wait(delay)
                pcall(function()
                    if lp.PlayerGui.TimerUI.RaceTimer.Visible then
                        local char = lp.Character
                        local hrp = char.HumanoidRootPart
                        hrp.CFrame = hrp.CFrame + Vector3.new(50000, 0, 0)
                    end
                end)
            end
        end)
    end
})

Section:AddToggle({
    Name = "Auto Speed",
    Default = false,
    Callback = function(bool)
        autoClick = bool
        
        task.spawn(function()
            while autoClick do
                task.wait()
                if lp.PlayerGui.ClicksUI.ClickHelper.Visible == true then
                    game:GetService("ReplicatedStorage").Packages.Knit.Services.ClickService.RF.Click:InvokeServer()
                end
            end
        end)
    end
})

Section:AddToggle({
    Name = "Auto Rebirth",
    Default = false,
    Callback = function(bool)
        autoRebirth = bool
        
        task.spawn(function()
            while autoRebirth do
                task.wait(5)
                game:GetService("ReplicatedStorage").Packages.Knit.Services.RebirthService.RF.Rebirth:InvokeServer()
            end
        end)
    end
})

Section:AddLabel("===========")

local choosed_egg
Section:AddDropdown({
    Name = "Choose Egg",
    Default = "Select",
    Options = Eggs,
    Callback = function(egg)
        local eggIndex = table.find(Eggs, egg)
        if eggIndex == 1 then choosed_egg = "Starter01"
        elseif eggIndex == 2 then choosed_egg = "Starter02"
        elseif eggIndex == 3 then choosed_egg = "Starter03"
        elseif eggIndex == 4 then choosed_egg = "Starter04"
        elseif eggIndex == 5 then choosed_egg = "Pro01"
        elseif eggIndex == 6 then choosed_egg = "Pro02"
        elseif eggIndex == 7 then choosed_egg = "Pro03"
        elseif eggIndex == 8 then choosed_egg = "Space01"
        elseif eggIndex == 9 then choosed_egg = "Ocean01"
        end
    end
})

Section:AddToggle({
    Name = "Auto Hatch",
    Default = false,
    Callback = function(bool)
        autoHatch = bool
        
        task.spawn(function()
            while autoHatch do
                task.wait()
                if choosed_egg then
                    local args = {[1] = choosed_egg, [2] = "1", [3] = {}}
                    game:GetService("ReplicatedStorage").Packages.Knit.Services.EggService.RF.Open:InvokeServer(unpack(args))
                else
                    warn("Please, choose your egg!")
                end
            end
        end)
    end
})

Section:AddToggle({
    Name = "Auto Craft",
    Default = false,
    Callback = function(bool)
        autoCraft = bool
        
        task.spawn(function()
            while autoCraft do
                task.wait(3)
                game:GetService("ReplicatedStorage").Packages.Knit.Services.PetsService.RF.CraftAll:InvokeServer()
            end
        end)
    end
})

Section:AddToggle({
    Name = "Auto Equip",
    Default = false,
    Callback = function(bool)
        autoEquipBest = bool
        
        task.spawn(function()
            while autoEquipBest do
                task.wait(3)
                game:GetService("ReplicatedStorage").Packages.Knit.Services.PetsService.RF.EquipBest:InvokeServer()
            end
        end)
    end
})

Section:AddLabel("===========")

Section:AddDropdown({
    Name = "Map Teleport",
    Default = "Select",
    Options = Maps,
    Callback = function(map)
        local mapIndex = table.find(Maps, map)
        if mapIndex == 1 then
            game:GetService("ReplicatedStorage").Packages.Knit.Services.WorldService.RF.Travel:InvokeServer("Home")
        elseif mapIndex == 2 then
            game:GetService("ReplicatedStorage").Packages.Knit.Services.WorldService.RF.Travel:InvokeServer("Space")
        elseif mapIndex == 3 then
            game:GetService("ReplicatedStorage").Packages.Knit.Services.WorldService.RF.Travel:InvokeServer("Ocean")
        end  
    end
})

Section:AddButton({
    Name = "Redeem Codes",
    Callback = function()
        for _, code in pairs(Codes) do
            game:GetService("ReplicatedStorage").Packages.Knit.Services.CodesService.RF.Redeem:InvokeServer(code)
        end
    end
})

local Credits = Window:MakeTab({
    Name = "Credits",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local CreditsSection = Credits:AddSection({
    Name = "Credits"
})

CreditsSection:AddLabel("UI : Wally UI V3")
CreditsSection:AddLabel("Made by : SQK#9773")
CreditsSection:AddLabel("Any Problems? ^ Add me :)")

OrionLib:Init()
