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

local folderCreationTimes = {}

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
            if obj:IsA("BasePart") and obj:IsDescendantOf(Workspace) then
                local partName = obj.Name
                if selectedPart == "All" or partName == selectedPart then
                    local partPos = obj.Position
                    local distance = (playerPos - partPos).Magnitude
                    if distance < minDistance then
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
        if charData and charData.Humanoid and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
            local adjustedPosition = targetPosition + Vector3.new(0, -10, 0)
            charData.HumanoidRootPart.CFrame = CFrame.new(adjustedPosition)
            if lastTeleportedPart ~= currentPart then
                charData.HumanoidRootPart.Anchored = false
                task.wait(0.1)
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
                            if currentTime - creationTime <= 15 then
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

local lastProcessedPart = nil
local function Remote_Lasso()
    local nearestPart = getNearestPart()
    if nearestPart and nearestPart:IsDescendantOf(Workspace) then
        local success, result = pcall(function()
            local tameEvent = nearestPart:FindFirstChild("TameEvent")
            if tameEvent and tameEvent:IsA("RemoteEvent") then
                if nearestPart ~= lastProcessedPart then
                    local argsBegin = {
                        [1] = "BeginAggro"
                    }
                    tameEvent:FireServer(unpack(argsBegin))
                    lastProcessedPart = nearestPart
                    task.wait(0.1)
                end
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
                if nearestPart ~= lastProcessedPart then
                    local argsBegin = {
                        [1] = "Begin"
                    }
                    tameEvent:FireServer(unpack(argsBegin))
                    lastProcessedPart = nearestPart
                    task.wait(0.1)
                end
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
            task.wait(1)
        end
    end)
end

Section1_Tab1:AddDropdown({
    Name = "Select Horse",
    Options = {"None", "Horse", "Fae", "Fairy", "Flora", "Gargoyle", "Gray", "Kelpie", "Peryton", "Equus", "Unicorn", "All"},
    Default = "None",
    Callback = function(selected)
        selectedPart = selected
        lastTeleportedPart = nil
    end
})

Section1_Tab1:AddToggle({
    Name = "Auto Farm Use -- Lasso --",
    Default = false,
    Callback = function(state)
        teleportEnabled = state
        lastTeleportedPart = nil
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
    Name = "Auto Farm Use -- Food --",
    Default = false,
    Callback = function(state)
        teleportEnabled = state
        lastTeleportedPart = nil
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
        local currentTime = tick()
        if currentTime - lastTeleportTime >= 0.1 then
            local nearestPart = getNearestPart()
            if nearestPart and nearestPart:IsDescendantOf(Workspace) then
                safeTeleportToPart(nearestPart.Position, nearestPart)
                lastTeleportTime = currentTime
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
    Treasure = Vector3.new(570.73388671875, 17.773395538330078, -1131.123291015625),
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
        if charData and charData.Humanoid and charData.Humanoid.Health > 0 and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
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

Section2_Tab2:AddToggle({
    Name = "Farm DailyChest and Shovel",
    Default = false,
    Callback = function(state)
        
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

