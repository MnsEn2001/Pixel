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
localPlayer.CharacterAdded:Connect(function()
    charData = updateCharacterData()
    if charData and charData.HumanoidRootPart then
        if teleportEnabled then
            Workspace.Gravity = 0
            charData.HumanoidRootPart.Anchored = true
            print("Gravity set to 0 and HumanoidRootPart anchored on character respawn")
        else
            Workspace.Gravity = defaultGravity
            charData.HumanoidRootPart.Anchored = false
            print("Gravity restored to default and HumanoidRootPart unanchored on character respawn: ", defaultGravity)
        end
    else
        warn("Cannot set gravity or anchor on respawn: charData or HumanoidRootPart missing")
    end
end)

local selectedPart = "None"
local teleportEnabled = false
local autoSellEnabled = false
local lastTeleportedPart = nil
local Remote_Farm = false
local guiCheckConnection = nil
local lastTeleportTime = 0 -- ตัวแปรควบคุมความถี่การวาร์ป

-- Table to store folder creation times
local folderCreationTimes = {}

-- Monitor new folders in PlayerGui.Data.Animals
local function monitorAnimalFolders()
    local success, animalsFolder = pcall(function()
        return localPlayer.PlayerGui:WaitForChild("Data", 5):WaitForChild("Animals", 5)
    end)
    if success and animalsFolder then
        animalsFolder.ChildAdded:Connect(function(child)
            if child:IsA("Folder") and tonumber(child.Name) then
                folderCreationTimes[child.Name] = tick()
                print("New folder detected: ", child.Name, " at time: ", folderCreationTimes[child.Name])
            end
        end)
        animalsFolder.ChildRemoved:Connect(function(child)
            if child:IsA("Folder") and tonumber(child.Name) then
                folderCreationTimes[child.Name] = nil
                print("Folder removed: ", child.Name)
            end
        end)
    else
        warn("Failed to access PlayerGui.Data.Animals for monitoring")
    end
end

-- Start monitoring folders when the script loads
monitorAnimalFolders()

local function getNearestPart()
    local mobFolder = Workspace:FindFirstChild("MobFolder")
    if not mobFolder then
        warn("MobFolder not found in workspace")
        return nil
    end
    local objects = mobFolder:GetChildren()
    if #objects == 0 then
        warn("No objects found in workspace.MobFolder")
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
    else
        warn("Player position not available or no part selected")
    end
    if not nearestPart then
        warn("No valid parts found in workspace.MobFolder for selected part: ", selectedPart)
    end
    return nearestPart
end

local function safeTeleportToPart(targetPosition, currentPart)
    local success, errorMsg = pcall(function()
        if charData and charData.Humanoid and charData.Humanoid.Health > 0 and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
            local adjustedPosition = targetPosition + Vector3.new(0, -10, 0)
            charData.HumanoidRootPart.CFrame = CFrame.new(adjustedPosition)
            
            -- Check if this is a new part
            if lastTeleportedPart ~= currentPart then
                charData.HumanoidRootPart.Anchored = false
                task.wait(1) -- Wait for 1 second
                if teleportEnabled and charData and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
                    charData.HumanoidRootPart.Anchored = true
                end
            else
                -- If not a new part, maintain the teleportEnabled state
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
                            if currentTime - creationTime <= 5 then -- Only sell folders created within 5 seconds
                                local success, result = pcall(function()
                                    local args = {
                                        [1] = {
                                            [1] = folderName
                                        }
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SellSlotsRemote"):InvokeServer(unpack(args))
                                end)
                                if success then
                                    print("Sold folder: ", folderName, " (created ", currentTime - creationTime, " seconds ago)")
                                else
                                    warn("Auto Sell failed for folder ", folderName, ": ", result)
                                end
                            else
                                print("Skipped folder: ", folderName, " (older than 5 seconds)")
                            end
                        end
                    end
                else
                    warn("Auto Sell: PlayerGui.Data.Animals not found")
                end
            end
            lastTeleportedPart = currentPart
        else
            warn("Character or Humanoid not valid for teleport")
        end
    end)
    if not success then
        warn("Teleport to Part failed: ", errorMsg)
    end
end

local function Remote_Lasso()
    local nearestPart = getNearestPart()
    if nearestPart and nearestPart:IsDescendantOf(Workspace) then
        local success, result = pcall(function()
            local tameEvent = nearestPart:FindFirstChild("TameEvent")
            if tameEvent and tameEvent:IsA("RemoteEvent") then
                local argsBegin = {
                    [1] = "BeginAggro"
                }
                tameEvent:FireServer(unpack(argsBegin))
                print("Called BeginAggro for Part: ", nearestPart.Name)
                task.wait(0.1)
                if nearestPart:IsDescendantOf(Workspace) then
                    local argsFeed = {
                        [1] = "SuccessfulFeed"
                    }
                    tameEvent:FireServer(unpack(argsFeed))
                    print("Called SuccessfulFeed for Part: ", nearestPart.Name)
                else
                    warn("Part was removed before SuccessfulFeed: ", nearestPart.Name)
                end
            else
                warn("TameEvent not found in Part: ", nearestPart.Name)
            end
        end)
        if not success then
            warn("Failed to interact with Part: ", result)
        end
    else
        warn("Cannot interact: no valid part found")
    end
end

local function start_Remote_Lasso()
    task.spawn(function()
        while Remote_Farm and teleportEnabled do
            if selectedPart ~= "None" then
                Remote_Lasso()
            end
            task.wait(0.5)
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
                print("Called BeginAggro for Part: ", nearestPart.Name)
                task.wait(0.5)
                if nearestPart:IsDescendantOf(Workspace) then
                    local argsFeed = {
                        [1] = "SuccessfulFeed"
                    }
                    tameEvent:FireServer(unpack(argsFeed))
                    print("Called SuccessfulFeed for Part: ", nearestPart.Name)
                else
                    warn("Part was removed before SuccessfulFeed: ", nearestPart.Name)
                end
            else
                warn("TameEvent not found in Part: ", nearestPart.Name)
            end
        end)
        if not success then
            warn("Failed to interact with Part: ", result)
        end
    else
        warn("Cannot interact: no valid part found")
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
    Options = {"None", "Horse", "Fae", "Fairy", "Flora", "Gargoyle", "Gray", "Kelpie", "Peryton", "Unicorn", "All"},
    Default = "None",
    Callback = function(selected)
        selectedPart = selected
        lastTeleportedPart = nil
        print("Selected Part to Lasso changed to: ", selected)
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
                    print("PromptFrame.Visible set to false")
                elseif not successPrompt then
                    warn("Failed to access PromptGui.PromptFrame: ", promptFrame)
                elseif promptFrame and not promptFrame.Visible then
                    print("PromptFrame is already invisible")
                else
                    warn("PromptGui.PromptFrame not found")
                end

                local successContainer, containerFrame = pcall(function()
                    local displayGui = localPlayer.PlayerGui:FindFirstChild("DisplayAnimalGui")
                    return displayGui and displayGui:FindFirstChild("ContainerFrame")
                end)
                if successContainer and containerFrame and containerFrame.Visible then
                    containerFrame.Visible = false
                    print("DisplayAnimalGui.ContainerFrame.Visible set to false")
                elseif not successContainer then
                    warn("Failed to access DisplayAnimalGui.ContainerFrame: ", containerFrame)
                elseif containerFrame and not containerFrame.Visible then
                    print("DisplayAnimalGui.ContainerFrame is already invisible")
                else
                    warn("DisplayAnimalGui.ContainerFrame not found")
                end

                Workspace.Gravity = 0
                charData.HumanoidRootPart.Anchored = true
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
                            print("PromptFrame.Visible set to false in loop")
                        elseif not successPromptLoop then
                            warn("Failed to access PromptGui.PromptFrame in loop: ", promptFrameLoop)
                        elseif promptFrameLoop and not promptFrameLoop.Visible then
                            print("PromptFrame is already invisible in loop")
                        else
                            warn("PromptGui.PromptFrame not found in loop")
                        end

                        local successContainerLoop, containerFrameLoop = pcall(function()
                            local displayGui = localPlayer.PlayerGui:FindFirstChild("DisplayAnimalGui")
                            return displayGui and displayGui:FindFirstChild("ContainerFrame")
                        end)
                        if successContainerLoop and containerFrameLoop and containerFrameLoop.Visible then
                            containerFrameLoop.Visible = false
                            print("DisplayAnimalGui.ContainerFrame.Visible set to false in loop")
                        elseif not successContainerLoop then
                            warn("Failed to access DisplayAnimalGui.ContainerFrame in loop: ", containerFrameLoop)
                        elseif containerFrameLoop and not containerFrameLoop.Visible then
                            print("DisplayAnimalGui.ContainerFrame is already invisible in loop")
                        else
                            warn("DisplayAnimalGui.ContainerFrame not found in loop")
                        end

                        task.wait(0.5)
                    end
                end)

                print("Teleport to Part enabled")
            else
                Workspace.Gravity = defaultGravity
                if charData and charData.HumanoidRootPart then
                    charData.HumanoidRootPart.Anchored = false
                    -- Tween character 60 units upward
                    local TweenService = game:GetService("TweenService")
                    local currentPosition = charData.HumanoidRootPart.Position
                    local targetPosition = currentPosition + Vector3.new(0, 60, 0)
                    local tweenInfo = TweenInfo.new(
                        1, -- Duration (1 second)
                        Enum.EasingStyle.Linear, -- Easing style
                        Enum.EasingDirection.Out -- Easing direction
                    )
                    local tween = TweenService:Create(
                        charData.HumanoidRootPart,
                        tweenInfo,
                        {CFrame = CFrame.new(targetPosition)}
                    )
                    local success, errorMsg = pcall(function()
                        tween:Play()
                    end)
                    if not success then
                        warn("Failed to play tween: ", errorMsg)
                        -- Fallback to instant teleport if tween fails
                        charData.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                    end
                end
                Remote_Farm = false
                if guiCheckConnection then
                    task.cancel(guiCheckConnection)
                    guiCheckConnection = nil
                end
                print("Teleport to Part disabled")
            end
        else
            warn("Cannot enable teleport: charData or HumanoidRootPart missing")
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
                    print("PromptFrame.Visible set to false")
                elseif not successPrompt then
                    warn("Failed to access PromptGui.PromptFrame: ", promptFrame)
                elseif promptFrame and not promptFrame.Visible then
                    print("PromptFrame is already invisible")
                else
                    warn("PromptGui.PromptFrame not found")
                end

                local successContainer, containerFrame = pcall(function()
                    local displayGui = localPlayer.PlayerGui:FindFirstChild("DisplayAnimalGui")
                    return displayGui and displayGui:FindFirstChild("ContainerFrame")
                end)
                if successContainer and containerFrame and containerFrame.Visible then
                    containerFrame.Visible = false
                    print("DisplayAnimalGui.ContainerFrame.Visible set to false")
                elseif not successContainer then
                    warn("Failed to access DisplayAnimalGui.ContainerFrame: ", containerFrame)
                elseif containerFrame and not containerFrame.Visible then
                    print("DisplayAnimalGui.ContainerFrame is already invisible")
                else
                    warn("DisplayAnimalGui.ContainerFrame not found")
                end

                Workspace.Gravity = 0
                charData.HumanoidRootPart.Anchored = true
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
                            print("PromptFrame.Visible set to false in loop")
                        elseif not successPromptLoop then
                            warn("Failed to access PromptGui.PromptFrame in loop: ", promptFrameLoop)
                        elseif promptFrameLoop and not promptFrameLoop.Visible then
                            print("PromptFrame is already invisible in loop")
                        else
                            warn("PromptGui.PromptFrame not found in loop")
                        end

                        local successContainerLoop, containerFrameLoop = pcall(function()
                            local displayGui = localPlayer.PlayerGui:FindFirstChild("DisplayAnimalGui")
                            return displayGui and displayGui:FindFirstChild("ContainerFrame")
                        end)
                        if successContainerLoop and containerFrameLoop and containerFrameLoop.Visible then
                            containerFrameLoop.Visible = false
                            print("DisplayAnimalGui.ContainerFrame.Visible set to false in loop")
                        elseif not successContainerLoop then
                            warn("Failed to access DisplayAnimalGui.ContainerFrame in loop: ", containerFrameLoop)
                        elseif containerFrameLoop and not containerFrameLoop.Visible then
                            print("DisplayAnimalGui.ContainerFrame is already invisible in loop")
                        else
                            warn("DisplayAnimalGui.ContainerFrame not found in loop")
                        end

                        task.wait(0.5)
                    end
                end)

                print("Teleport to Part enabled")
            else
                Workspace.Gravity = defaultGravity
                if charData and charData.HumanoidRootPart then
                    charData.HumanoidRootPart.Anchored = false
                    -- Tween character 20 units upward
                    local TweenService = game:GetService("TweenService")
                    local currentPosition = charData.HumanoidRootPart.Position
                    local targetPosition = currentPosition + Vector3.new(0, 20, 0)
                    local tweenInfo = TweenInfo.new(
                        1, -- Duration (1 second)
                        Enum.EasingStyle.Linear, -- Easing style
                        Enum.EasingDirection.Out -- Easing direction
                    )
                    local tween = TweenService:Create(
                        charData.HumanoidRootPart,
                        tweenInfo,
                        {CFrame = CFrame.new(targetPosition)}
                    )
                    local success, errorMsg = pcall(function()
                        tween:Play()
                    end)
                    if not success then
                        warn("Failed to play tween: ", errorMsg)
                        -- Fallback to instant teleport if tween fails
                        charData.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                    end
                end
                Remote_Farm = false
                if guiCheckConnection then
                    task.cancel(guiCheckConnection)
                    guiCheckConnection = nil
                end
                print("Teleport to Part disabled")
            end
        else
            warn("Cannot enable teleport: charData or HumanoidRootPart missing")
            teleportEnabled = false
        end
    end
})

Section1_Tab1:AddToggle({
    Name = "Auto Sell",
    Default = false,
    Callback = function(state)
        autoSellEnabled = state
        print("Auto Sell toggled: ", state and "Enabled" or "Disabled")
    end
})

local teleportConnection
teleportConnection = RunService.Heartbeat:Connect(function()
    if teleportEnabled and selectedPart ~= "None" and charData and charData.Humanoid and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
        local currentTime = tick()
        if currentTime - lastTeleportTime >= 0.1 then -- วาร์ปทุก 0.1 วินาที
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

local function farmJumpsEXP()
    local success, errorMsg = pcall(function()
        local args = {
            [1] = Workspace:WaitForChild("Jumps"):WaitForChild("JumpBirch")
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("JumpedObstacleRemote"):FireServer(unpack(args))
    end)
    if not success then
        warn("Farm Jumps EXP failed: ", errorMsg)
    end
end

local function activateBoostPads()
    local success, errorMsg = pcall(function()
        Workspace:WaitForChild("BoostPads"):WaitForChild("Speed"):WaitForChild("RemoteEvent"):FireServer()
    end)
    if not success then
        warn("BoostPads activation failed: ", errorMsg)
    end
end

local function farmFood()
    local success, errorMsg = pcall(function()
        local resources = selectedFood == "All" and {
            "AppleBarrel", "BerryBush", "FallenTree", "FoodPallet",
            "LargeBerryBush", "StoneDeposit", "Stump", "Treasure", "SilkBush"
        } or {selectedFood}
        for _, resource in ipairs(resources) do
            local args1 = {
                [1] = 5,
                [2] = true
            }
            Workspace:WaitForChild("Interactions"):WaitForChild("Resource"):WaitForChild(resource):WaitForChild("RemoteEvent"):InvokeServer(unpack(args1))
            local args2 = {
                [1] = localPlayer.Character and localPlayer.Character.Animals:FindFirstChild("3")
            }
            if args2[1] then
                Workspace:WaitForChild("Interactions"):WaitForChild("Resource"):WaitForChild(resource):WaitForChild("RemoteEvent"):InvokeServer(unpack(args2))
            else
                warn("Animal ID 3 not found for resource ", resource)
            end
        end
    end)
    if not success then
        warn("Farm Food failed for resource ", selectedFood, ": ", errorMsg)
    end
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
    if not success then
        warn("SendDropsRemote failed: ", errorMsg)
    end
end

Section1_Tab2:AddToggle({
    Name = "Farm Jumps EXP",
    Default = false,
    Callback = function(state)
        FarmToggles.FarmJumpsEXP = state
        print("Farm Jumps EXP toggled: ", state and "Enabled" or "Disabled")
    end
})

Section1_Tab2:AddToggle({
    Name = "BoostPads",
    Default = false,
    Callback = function(state)
        FarmToggles.BoostPads = state
        print("BoostPads toggled: ", state and "Enabled" or "Disabled")
    end
})

Section2_Tab2:AddDropdown({
    Name = "Select Food",
    Options = {"AppleBarrel", "BerryBush", "FallenTree", "FoodPallet", "LargeBerryBush", "StoneDeposit", "Stump", "Treasure", "SilkBush", "All"},
    Default = "SilkBush",
    Callback = function(selected)
        selectedFood = selected
        print("Selected Food changed to: ", selected)
    end
})

Section2_Tab2:AddToggle({
    Name = "Farm Food",
    Default = false,
    Callback = function(state)
        FarmToggles.FarmFood = state
        print("Farm Food toggled: ", state and "Enabled" or "Disabled")
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
