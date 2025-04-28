local PixelLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/MnsEn2001/Xlib/refs/heads/main/Lib/PixLib.lua"))()
local GuiService = game:GetService("GuiService")

-- ฟังก์ชันคำนวณขนาด GUI ตามขนาดหน้าจอ
local function calculateGuiSize()
    local viewportSize = game.Workspace.CurrentCamera.ViewportSize
    local screenWidth, screenHeight = viewportSize.X, viewportSize.Y
    local scaleWidth, scaleHeight = 0.6, 0.7
    local minSize = Vector2.new(400, 300)
    local maxSize = Vector2.new(800, 600)
    local guiWidth = math.clamp(screenWidth * scaleWidth, minSize.X, maxSize.X)
    local guiHeight = math.clamp(screenHeight * scaleHeight, minSize.Y, maxSize.Y)
    local tabWidth = math.floor(guiWidth * 0.2)
    return UDim2.fromOffset(guiWidth, guiHeight), tabWidth
end

local guiSize, tabWidth = calculateGuiSize()
local Window = PixelLib:CreateGui({
    NameHub = "Pixel Hub",
    Description = "#VIP : Treasure Quest - V2",
    Color = Color3.fromRGB(0, 140, 255),
    TabWidth = tabWidth,
    SizeUI = guiSize
})

local TabControls = Window
local Tab1 = TabControls:CreateTab({
    Name = "Player",
    Icon = "rbxassetid://7072719338"
})
local Section1_Tab1 = Tab1:AddSection("Lasso", true)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local defaultGravity = Workspace.Gravity
repeat wait() until game:IsLoaded()

local selectedPart = "None"
local teleportEnabled = false
local autoSellEnabled = false
local lastTeleportedPart = nil
local Remote_Farm = false
local guiCheckConnection = nil
local noclipConnection = nil
local lastTeleportTime = 0
local eventFarmEnabled = false
local lastLocationCheckTime = 0
local checkInterval = 2

local folderCreationTimes = {}
local currentSpawnIndex = {}

local horseSpawnLocations = {
    Horse = {
        Vector3.new(984.6898193359375, 39.22307586669922, -518.1824340820312),
        Vector3.new(818.211181640625, 114.06318664550781, -1181.5826416015625),
        Vector3.new(-59.995033264160156, 33.38571548461914, -1437.0189208984375),
        Vector3.new(79.7146987915039, 33.891783714294434, -358.8204650878906)
    },
    Pony = {
        Vector3.new(1624.859130859375, 36.201045989990234, -1250.9278564453125),
        Vector3.new(1884.79248046875, 86.3497314453125, -1540.4468994140625),
        Vector3.new(2227.81005859375, 127.64604949951172, -1389.865478515625),
        Vector3.new(2517.466796875, 129.38569641113281, -1129.2296142578125)
    },
    Equus = {
        Vector3.new(-438.0946350097656, 33.38571548461914, -1356.0174560546875),
        Vector3.new(-847.9989013671875, 33.38571548461914, -1315.01171875),
        Vector3.new(-1153.6031494140625, 35.502039909362793, -926.2833862304688),
        Vector3.new(-1438.77734375, 63.290462493896484, -1006.0366821289062)
    },
    Bisorse = {
        Vector3.new(-683.4973754882812, 33.38571548461914, -1550.816650390625),
        Vector3.new(-567.2005615234375, 33.38571548461914, -1803.713134765625),
        Vector3.new(-840.0972290039062, 33.38571548461914, -1688.2135009765625),
        Vector3.new(-1095.99609375, 33.38571548461914, -1557.0150146484375)
    },
    Caprine = {
        Vector3.new(1960.3861083984375, 294.4034118652344, -1963.986572265625),
        Vector3.new(2532.993896484375, 227.6634979248047, -1927.2379150390625),
        Vector3.new(2230.986328125, 293.17193603515625, -2357.87548828125)
    },
    Unicorn = {
        Vector3.new(-987.5292358398438, 87.77334594726562, -572.630126953125),
        Vector3.new(-70.70305633544922, 102.58036041259766, -1016.5503540039062),
        Vector3.new(182.00498962402344, 94.60444641113281, -1203.017333984375),
        Vector3.new(2156.201416015625, 35.253561973571777, -728.2118530273438)
    },
    Gargoyle = {
        Vector3.new(1603.007080078125, 36.1668701171875, -856.3812255859375),
        Vector3.new(541.2142333984375, 122.05838012695312, -1205.2183837890625),
        Vector3.new(209.0157012939453, 94.9813003540039, -957.6135864257812),
        Vector3.new(-590.1075439453125, 78.375797271728516, -899.4979248046875)
    },
    Kelpie = {
        Vector3.new(1154.5999755859375, 29.38571548461914, -1062.0999755859375),
        Vector3.new(989.5, 31.42807674407959, -1022.5),
        Vector3.new(1005.4000854492188, 29.08884048461914, -44.70001220703125),
        Vector3.new(344.79998779296875, 29.38571548461914, 490.70001220703125)
    },
    Peryton = {
        Vector3.new(1037.5689697265625, 34.385714530944824, -59.87628936767578),
        Vector3.new(1355.152099609375, 38.43065643310547, -65.8502197265625),
        Vector3.new(1422.689453125, 34.657703399658203, 184.85623168945312),
        Vector3.new(1381.643310546875, 39.400794982910156, -384.83648681640625)
    },
    Fae = {
        Vector3.new(1135.14208984375, 36.126983642578125, -1428.2923583984375),
        Vector3.new(431.415283203125, 33.557772636413574, -1412.1160888671875),
        Vector3.new(1658.6077880859375, 34.75033187866211, -448.96539306640625),
        Vector3.new(-1298.1317138671875, 43.40003776550293, -898.4066162109375)
    },
    Plush = {
    },
    Flora = {
        Vector3.new(1726.3236083984375, 291.7519226074219, -2615.569091796875),
        Vector3.new(2159.229248046875, 251.445556640625, -1673.8619384765625),
        Vector3.new(1414.741455078125, 90.96279907226562, -1780.8643798828125),
        Vector3.new(2055.52490234375, 85.42382049560547, -1465.525390625)
    },

    Cybred = {
    },
    Celestial = {
    },
    Wolper = {
    },
    Saurequine = {
    },
    Alces = {
    },
    Pastrequine = {
    },
    Ghoulsteed = {
    },
    Fairy = {
        Vector3.new(-1545.54052734375, 63.22039031982422, -413.19921875),
        Vector3.new(-1712.9837646484375, 59.50642395019531, -360.1767272949219)
    },
    Gray = {
        Vector3.new(633.1749267578125, 37.64652442932129, -1504.0126953125)
    }
}

local function updateCharacterData()
    local success, result = pcall(function()
        local charactersFolder = Workspace:WaitForChild("Characters", 5)
        local char = charactersFolder:WaitForChild(localPlayer.Name, 5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        return {
            Character = char,
            HumanoidRootPart = hrp,
            Humanoid = hum
        }
    end)
    if success then
        return result
    else
        warn("ไม่พบตัวละครใน Workspace.Characters: ", result)
        return nil
    end
end

local charData = updateCharacterData()
local function enableNoclip()
    if noclipConnection then
        return
    end
    noclipConnection = RunService.Stepped:Connect(function()
        if charData and charData.Character and teleportEnabled then
            for _, part in ipairs(charData.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
        if charData and charData.Character then
            for _, part in ipairs(charData.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

localPlayer.CharacterAdded:Connect(function()
    charData = updateCharacterData()
    if charData and charData.HumanoidRootPart then
        if teleportEnabled then
            Workspace.Gravity = 0
            charData.HumanoidRootPart.Anchored = true
            enableNoclip()
        else
            Workspace.Gravity = defaultGravity
            charData.HumanoidRootPart.Anchored = false
            disableNoclip()
        end
    end
end)

local function monitorAnimalFolders()
    local success, animalsFolder = pcall(function()
        return localPlayer.PlayerGui:WaitForChild("Data", 5):WaitForChild("Animals", 5)
    end)
    if success and animalsFolder then
        animalsFolder.ChildAdded:Connect(function(child)
            if child:IsA("Folder") and tonumber(child.Name) then
                folderCreationTimes[child.Name] = tick()
            end
        end)
        animalsFolder.ChildRemoved:Connect(function(child)
            if child:IsA("Folder") and tonumber(child.Name) then
                folderCreationTimes[child.Name] = nil
            end
        end)
    end
end

monitorAnimalFolders()

local function getNearestPart()
    local mobFolder = Workspace:FindFirstChild("MobFolder")
    if not mobFolder then
        return nil
    end
    local objects = mobFolder:GetChildren()
    if #objects == 0 then
        return nil
    end
    local nearestPart = nil
    local minDistance = math.huge
    local playerPos = charData and charData.HumanoidRootPart and charData.HumanoidRootPart.Position
    if playerPos and selectedPart ~= "None" then
        for _, obj in ipairs(objects) do
            if obj:IsA("BasePart") and obj:IsDescendantOf(Workspace) and obj.Position then
                local partName = obj.Name
                if selectedPart == "All" or partName == selectedPart then
                    local partPos = obj.Position
                    local distance = (playerPos - partPos).Magnitude
                    if distance < minDistance and distance < 1000 then
                        minDistance = distance
                        nearestPart = obj
                    end
                end
            end
        end
    end
    return nearestPart
end

local function safeTeleportToPart(targetPosition, currentPart)
    local success, errorMsg = pcall(function()
        if charData and charData.Humanoid and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) and charData.Humanoid.Health > 0 then
            local playerPos = charData.HumanoidRootPart.Position
            local distance = (playerPos - targetPosition).Magnitude
            if distance > 5000 then
                return
            end
            local adjustedPosition = targetPosition + Vector3.new(0, -10, 0)
            charData.HumanoidRootPart.CFrame = CFrame.new(adjustedPosition)
            if lastTeleportedPart ~= currentPart then
                charData.HumanoidRootPart.Anchored = false
                task.wait(0.5)
                if teleportEnabled and charData and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
                    charData.HumanoidRootPart.Anchored = true
                end
            else
                charData.HumanoidRootPart.Anchored = teleportEnabled
            end
            if teleportEnabled and autoSellEnabled then
                local animalsFolder = localPlayer.PlayerGui:FindFirstChild("Data") and localPlayer.PlayerGui.Data:FindFirstChild("Animals")
                if animalsFolder then
                    local currentTime = tick()
                    for _, folder in ipairs(animalsFolder:GetChildren()) do
                        if folder:IsA("Folder") and tonumber(folder.Name) then
                            local folderName = folder.Name
                            local creationTime = folderCreationTimes[folderName] or 0
                            if currentTime - creationTime <= 10 then
                                local success, result = pcall(function()
                                    local args = {
                                        [1] = {
                                            [1] = folderName
                                        }
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SellSlotsRemote"):InvokeServer(unpack(args))
                                end)
                            end
                        end
                    end
                end
            end
            lastTeleportedPart = currentPart
        end
    end)
end

local function teleportToNextSpawnLocation()
    if selectedPart == "None" or selectedPart == "All" then
        return false
    end
    local spawnLocations = horseSpawnLocations[selectedPart]
    if not spawnLocations or #spawnLocations == 0 then
        warn("No spawn locations defined for: ", selectedPart)
        return false
    end
    -- Initialize spawn index for this horse if not set
    if not currentSpawnIndex[selectedPart] then
        currentSpawnIndex[selectedPart] = 1
    end
    -- Get the current spawn location
    local targetPosition = spawnLocations[currentSpawnIndex[selectedPart]]
    if targetPosition then
        safeTeleportToPart(targetPosition, nil)
        -- Move to the next spawn location (cycle back to 1 if at the end)
        currentSpawnIndex[selectedPart] = currentSpawnIndex[selectedPart] + 1
        if currentSpawnIndex[selectedPart] > #spawnLocations then
            currentSpawnIndex[selectedPart] = 1
        end
        return true
    end
    return false
end

local function Remote_Lasso()
    local nearestPart = getNearestPart()
    if nearestPart and nearestPart:IsDescendantOf(Workspace) then
        local success, result = pcall(function()
            local tameEvent = nearestPart:FindFirstChild("TameEvent")
            if tameEvent and tameEvent:IsA("RemoteEvent") then
                local argsBegin = {
                    [1] = "Begin"
                }
                tameEvent:FireServer(unpack(argsBegin))
                task.wait(0.1)
                if nearestPart:IsDescendantOf(Workspace) then
                    local argsFeed = {
                        [1] = "SuccessfulFeed"
                    }
                    tameEvent:FireServer(unpack(argsFeed))
                end
            end
        end)
    end
end

local function start_Remote_Lasso()
    task.spawn(function()
        while Remote_Farm and teleportEnabled do
            if selectedPart ~= "None" then
                Remote_Lasso()
            end
            task.wait(0.1)
        end
    end)
end

local function Remote_Food()
    local nearestPart = getNearestPart()
    if nearestPart and nearestPart:IsDescendantOf(Workspace) then
        local success, result = pcall(function()
            local tameEvent = nearestPart:FindFirstChild("TameEvent")
            if tameEvent and tameEvent:IsA("RemoteEvent") then
                local argsBegin = {
                    [1] = "Begin"
                }
                tameEvent:FireServer(unpack(argsBegin))
                task.wait(0.5)
                if nearestPart:IsDescendantOf(Workspace) then
                    local argsFeed = {
                        [1] = "SuccessfulFeed"
                    }
                    tameEvent:FireServer(unpack(argsFeed))
                end
            end
        end)
    end
end

local function start_Remote_Food()
    task.spawn(function()
        while Remote_Farm and teleportEnabled do
            if selectedPart ~= "None" then
                Remote_Food()
            end
            task.wait(0.5)
        end
    end)
end

Section1_Tab1:AddDropdown({
    Name = "Select Horse",
    Options = {"None", "Horse", "Pony",
                "Equus", "Bisorse", "Caprine",
                "Unicorn", "Gargoyle", "Kelpie",
                "Peryton", "Fae", "Plush",
                "Flora", "Cybred", "Celestial",
                "Wolper", "Saurequine", "Alces",
                "Pastrequine", "Ghoulsteed", "Fairy",
                "Gray", "All"},
    Default = "None",
    Callback = function(selected)
        selectedPart = selected
        lastTeleportedPart = nil
        currentSpawnIndex[selected] = 1
        lastLocationCheckTime = 0
    end
})

Section1_Tab1:AddToggle({
    Name = "Auto Farm Use -- Lasso --",
    Default = false,
    Callback = function(state)
        teleportEnabled = state
        lastTeleportedPart = nil
        lastLocationCheckTime = 0 -- Reset check time when toggling
        if charData and charData.HumanoidRootPart and charData.Humanoid then
            if state then
                local successPrompt, promptFrame = pcall(function()
                    local promptGui = localPlayer.PlayerGui:FindFirstChild("PromptGui")
                    return promptGui and promptGui:FindFirstChild("PromptFrame")
                end)
                if successPrompt and promptFrame and promptFrame.Visible then
                    promptFrame.Visible = false
                end

                local successContainer, containerFrame = pcall(function()
                    local displayGui = localPlayer.PlayerGui:FindFirstChild("DisplayAnimalGui")
                    return displayGui and displayGui:FindFirstChild("ContainerFrame")
                end)
                if successContainer and containerFrame and containerFrame.Visible then
                    containerFrame.Visible = false
                end

                Workspace.Gravity = 0
                charData.HumanoidRootPart.Anchored = true
                enableNoclip()
                Remote_Farm = true
                start_Remote_Lasso()
                guiCheckConnection = task.spawn(function()
                    while teleportEnabled do
                        local successPromptLoop, promptFrameLoop = pcall(function()
                            local promptGui = localPlayer.PlayerGui:FindFirstChild("PromptGui")
                            return promptGui and promptGui:FindFirstChild("PromptFrame")
                        end)
                        if successPromptLoop and promptFrameLoop and promptFrameLoop.Visible then
                            promptFrameLoop.Visible = false
                        end

                        local successContainerLoop, containerFrameLoop = pcall(function()
                            local displayGui = localPlayer.PlayerGui:FindFirstChild("DisplayAnimalGui")
                            return displayGui and displayGui:FindFirstChild("ContainerFrame")
                        end)
                        if successContainerLoop and containerFrameLoop and containerFrameLoop.Visible then
                            containerFrameLoop.Visible = false
                        end

                        task.wait(0.1)
                    end
                end)
            else
                Workspace.Gravity = defaultGravity
                if charData and charData.HumanoidRootPart then
                    local targetCFrame = CFrame.new(
                        Vector3.new(-36.923317, 22.54938221, -23.4148331)
                    )
                    local success, errorMsg = pcall(function()
                        charData.HumanoidRootPart.Anchored = true
                        charData.HumanoidRootPart.CFrame = targetCFrame
                        task.wait(0.1)
                        charData.HumanoidRootPart.Anchored = false
                    end)
                    disableNoclip()
                end
                Remote_Farm = false
                if guiCheckConnection then
                    task.cancel(guiCheckConnection)
                    guiCheckConnection = nil
                end
            end
        else
            teleportEnabled = false
        end
    end
})

Section1_Tab1:AddToggle({
    Name = "Auto Farm Use -- Food --",
    Default = false,
    Callback = function(state)
        teleportEnabled = state
        lastTeleportedPart = nil
        lastLocationCheckTime = 0 -- Reset check time when toggling
        if charData and charData.HumanoidRootPart and charData.Humanoid then
            if state then
                local successPrompt, promptFrame = pcall(function()
                    local promptGui = localPlayer.PlayerGui:FindFirstChild("PromptGui")
                    return promptGui and promptGui:FindFirstChild("PromptFrame")
                end)
                if successPrompt and promptFrame and promptFrame.Visible then
                    promptFrame.Visible = false
                end

                local successContainer, containerFrame = pcall(function()
                    local displayGui = localPlayer.PlayerGui:FindFirstChild("DisplayAnimalGui")
                    return displayGui and displayGui:FindFirstChild("ContainerFrame")
                end)
                if successContainer and containerFrame and containerFrame.Visible then
                    containerFrame.Visible = false
                end

                Workspace.Gravity = 0
                charData.HumanoidRootPart.Anchored = true
                enableNoclip()
                Remote_Farm = true
                start_Remote_Food()
                guiCheckConnection = task.spawn(function()
                    while teleportEnabled do
                        local successPromptLoop, promptFrameLoop = pcall(function()
                            local promptGui = localPlayer.PlayerGui:FindFirstChild("PromptGui")
                            return promptGui and promptGui:FindFirstChild("PromptFrame")
                        end)
                        if successPromptLoop and promptFrameLoop and promptFrameLoop.Visible then
                            promptFrameLoop.Visible = false
                        end

                        local successContainerLoop, containerFrameLoop = pcall(function()
                            local displayGui = localPlayer.PlayerGui:FindFirstChild("DisplayAnimalGui")
                            return displayGui and displayGui:FindFirstChild("ContainerFrame")
                        end)
                        if successContainerLoop and containerFrameLoop and containerFrameLoop.Visible then
                            containerFrameLoop.Visible = false
                        end

                        task.wait(0.5)
                    end
                end)
            else
                Workspace.Gravity = defaultGravity
                if charData and charData.HumanoidRootPart then
                    local targetCFrame = CFrame.new(
                        Vector3.new(-36.923317, 22.54938221, -23.4148331)
                    )
                    local success, errorMsg = pcall(function()
                        charData.HumanoidRootPart.Anchored = true
                        charData.HumanoidRootPart.CFrame = targetCFrame
                        task.wait(0.1)
                        charData.HumanoidRootPart.Anchored = false
                    end)
                    disableNoclip()
                end
                Remote_Farm = false
                if guiCheckConnection then
                    task.cancel(guiCheckConnection)
                    guiCheckConnection = nil
                end
            end
        else
            teleportEnabled = false
        end
    end
})

Section1_Tab1:AddToggle({
    Name = "Auto Sell",
    Default = false,
    Callback = function(state)
        autoSellEnabled = state
    end
})

local teleportConnection
teleportConnection = RunService.Heartbeat:Connect(function()
    if teleportEnabled and selectedPart ~= "None" and charData and charData.Humanoid and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
        local currentPos = charData.HumanoidRootPart.Position
        local safePosition = Vector3.new(-36.923317, 22.54938221, -23.4148331)
        if (currentPos - safePosition).Magnitude > 5000 then
            charData.HumanoidRootPart.CFrame = CFrame.new(safePosition)
            teleportEnabled = false
            return
        end
        local currentTime = tick()
        if currentTime - lastTeleportTime >= 0.5 then
            local nearestPart = getNearestPart()
            if nearestPart and nearestPart:IsDescendantOf(Workspace) then
                -- If a horse is found, teleport to it and catch it
                safeTeleportToPart(nearestPart.Position, nearestPart)
                lastTeleportTime = currentTime
                lastLocationCheckTime = currentTime -- Reset check timer when a horse is found
            elseif currentTime - lastLocationCheckTime >= checkInterval then
                -- If no horse is found and enough time has passed, teleport to the next spawn location
                if teleportToNextSpawnLocation() then
                    lastTeleportTime = currentTime
                    lastLocationCheckTime = currentTime -- Reset check timer after teleporting
                end
            end
        end
    end
end)

local Tab2 = TabControls:CreateTab({
    Name = "Farm",
    Icon = "rbxassetid://7072719338"
})
local Section1_Tab2 = Tab2:AddSection("Auto Farm", true)
local Section2_Tab2 = Tab2:AddSection("Auto Farm Food", true)

local FarmToggles = {
    FarmJumpsEXP = false,
    BoostPads = false,
    FarmFood = false
}
local dropCounter = 1
local lastFarmTime = 0
local selectedFood = "SilkBush"

local foodTeleportPositions = {
    AppleBarrel = Vector3.new(577.5712890625, 23.5939579010009766, -17.890897750854492),
    FoodPallet = Vector3.new(577.5712890625, 23.5939579010009766, -17.890897750854492),
    BerryBush = Vector3.new(798.4374389648438, 49.213836669921875, -120.74653625488281),
    FallenTree = Vector3.new(523.5050659179688, 75.62639617919922, -844.544677734375),
    LargeBerryBush = Vector3.new(1509.814697265625, 294.0887451171875, -268.6426696777344),
    StoneDeposit = Vector3.new(1664.91796875, 47.65071678161621, -1449.3878173828125),
    Stump = Vector3.new(577.5712890625, 23.5939579010009766, -17.890897750854492),
    Treasure = Vector3.new(-63.46995544433594, 23.444576263427734, -271.19671630859375),
    SilkBush = Vector3.new(-1333.2440185546875, 47.825965881347656, -581.406982421875)
}

local function farmJumpsEXP()
    local success, errorMsg = pcall(function()
        local args = {
            [1] = Workspace:WaitForChild("Jumps"):WaitForChild("JumpBirch")
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("JumpedObstacleRemote"):FireServer(unpack(args))
    end)
end

local function activateBoostPads()
    local success, errorMsg = pcall(function()
        Workspace:WaitForChild("BoostPads"):WaitForChild("Speed"):WaitForChild("RemoteEvent"):FireServer()
    end)
end

local function farmFood()
    local success, errorMsg = pcall(function()
        local resources = selectedFood == "All" and {
            "AppleBarrel", "BerryBush", "FallenTree", "FoodPallet",
            "LargeBerryBush", "StoneDeposit", "Stump", "Treasure", "SilkBush"
        } or {selectedFood}

        for _, resource in ipairs(resources) do
            local resourceFolder = Workspace:FindFirstChild("Interactions") and 
                                Workspace.Interactions:FindFirstChild("Resource") and 
                                Workspace.Interactions.Resource:FindFirstChild(resource)
            
            if resourceFolder then
                local remoteEvent = resourceFolder:FindFirstChild("RemoteEvent")
                if remoteEvent then
                    local args1 = {
                        [1] = 5,
                        [2] = true
                    }
                    remoteEvent:InvokeServer(unpack(args1))

                    task.wait(0.1)
                    local args2 = {
                        [1] = localPlayer.Character and localPlayer.Character.Animals:FindFirstChild("3")
                    }
                    if args2[1] then
                        remoteEvent:InvokeServer(unpack(args2))
                    end
                end
            end
        end
    end)
end

local function sendDrops()
    local success, errorMsg = pcall(function()
        local args = {
            [1] = "\\" .. dropCounter
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SendDropsRemote"):FireServer(unpack(args))
        dropCounter = dropCounter + 1
        if dropCounter > 100 then
            dropCounter = 1
        end
    end)
end

local function teleportToPosition(position)
    local success, errorMsg = pcall(function()
        if charData and charData.Humanoid and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
            charData.HumanoidRootPart.CFrame = CFrame.new(position)
        end
    end)
end

local function startAllFoodTeleport()
    task.spawn(function()
        while FarmToggles.FarmFood and charData and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) do
            for food, position in pairs(foodTeleportPositions) do
                if FarmToggles.FarmFood then
                    teleportToPosition(position)
                    task.wait(30)
                else
                    break
                end
            end
        end
    end)
end

local function teleportCurrencyNodes()
    local success, currencyNodes = pcall(function()
        return Workspace:WaitForChild("Interactions"):WaitForChild("CurrencyNodes")
    end)
    if success and currencyNodes then
        for _, part in ipairs(currencyNodes:GetChildren()) do
            if part:IsA("BasePart") and part:IsDescendantOf(Workspace) and charData and charData.HumanoidRootPart then
                local success, result = pcall(function()
                    part.CFrame = charData.HumanoidRootPart.CFrame
                end)
            end
        end
    end
end

local function startEventFarm()
    task.spawn(function()
        while eventFarmEnabled and charData and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) do
            teleportCurrencyNodes()
            task.wait(0.1)
        end
    end)
end

Section1_Tab2:AddToggle({
    Name = "Farm Jumps EXP",
    Default = false,
    Callback = function(state)
        FarmToggles.FarmJumpsEXP = state
    end
})

Section1_Tab2:AddToggle({
    Name = "BoostPads",
    Default = false,
    Callback = function(state)
        FarmToggles.BoostPads = state
    end
})

Section1_Tab2:AddToggle({
    Name = "Event Farm",
    Default = false,
    Callback = function(state)
        eventFarmEnabled = state
        if state then
            startEventFarm()
        end
    end
})

Section2_Tab2:AddDropdown({
    Name = "Select Food",
    Options = {"AppleBarrel", "FoodPallet", "BerryBush", "FallenTree", "LargeBerryBush", "StoneDeposit", "Stump", "Treasure", "SilkBush", "All"},
    Default = "SilkBush",
    Callback = function(selected)
        selectedFood = selected
    end
})

Section2_Tab2:AddToggle({
    Name = "Farm Food while Catching Horses",
    Default = false,
    Callback = function(state)
        FarmToggles.FarmFood = state
        if state and charData and charData.HumanoidRootPart then
            task.spawn(function()
                while FarmToggles.FarmFood do
                    farmFood()
                    sendDrops()
                    task.wait(0.01)
                end
            end)
        end
    end
})

Section2_Tab2:AddToggle({
    Name = "Farm Food Only",
    Default = false,
    Callback = function(state)
        FarmToggles.FarmFood = state
        if state and charData and charData.HumanoidRootPart then
            if selectedFood == "All" then
                startAllFoodTeleport()
            else
                local position = foodTeleportPositions[selectedFood]
                if position then
                    teleportToPosition(position)
                end
            end
        end
    end
})

RunService.Heartbeat:Connect(function()
    if charData and charData.Character and charData.Character:IsDescendantOf(Workspace) then
        local currentTime = tick()
        if currentTime - lastFarmTime >= 0.1 then
            if FarmToggles.FarmJumpsEXP then
                farmJumpsEXP()
            end
            if FarmToggles.BoostPads then
                activateBoostPads()
            end
            if FarmToggles.FarmFood then
                farmFood()
                sendDrops()
            end
            lastFarmTime = currentTime
        end
    end
end)
