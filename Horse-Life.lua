local PixelLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/MnsEn2001/Xlib/refs/heads/main/Lib/PixLib.lua"))()
local GuiService = game:GetService("GuiService")

-- ฟังก์ชันคำนวณขนาด GUI ตามขนาดหน้าจอ
local function calculateGuiSize()
    local viewportSize = game.Workspace.CurrentCamera.ViewportSize
    local screenWidth, screenHeight = viewportSize.X, viewportSize.Y

    -- กำหนดสัดส่วนของ GUI เทียบกับหน้าจอ (เช่น 60% ของความกว้าง, 70% ของความสูง)
    local scaleWidth, scaleHeight = 0.6, 0.7

    -- กำหนดขนาดขั้นต่ำและสูงสุด (ในหน่วย Offset)
    local minSize = Vector2.new(400, 300) -- ขนาดขั้นต่ำ
    local maxSize = Vector2.new(800, 600) -- ขนาดสูงสุด

    -- คำนวณขนาด GUI
    local guiWidth = math.clamp(screenWidth * scaleWidth, minSize.X, maxSize.X)
    local guiHeight = math.clamp(screenHeight * scaleHeight, minSize.Y, maxSize.Y)

    -- คำนวณ TabWidth เป็นสัดส่วนของ guiWidth (เช่น 20% ของความกว้าง GUI)
    local tabWidth = math.floor(guiWidth * 0.2)

    return UDim2.fromOffset(guiWidth, guiHeight), tabWidth
end

-- คำนวณขนาด GUI และ TabWidth
local guiSize, tabWidth = calculateGuiSize()

-- สร้าง GUI หลัก
local Window = PixelLib:CreateGui({
    NameHub = "Pixel Hub",
    Description = "#VIP : Treasure Quest - V2",
    Color = Color3.fromRGB(0, 140, 255),
    TabWidth = tabWidth,
    SizeUI = guiSize
})

-- ส่วนที่เหลือของโค้ดยังคงเหมือนเดิม
local TabControls = Window

-- แท็บแรก: Player Features
local Tab1 = TabControls:CreateTab({
    Name = "Player",
    Icon = "rbxassetid://7072719338"
})

-- Section 1
local Section1_Tab1 = Tab1:AddSection("Lasso", true)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- เก็บค่า Gravity เริ่มต้น
local defaultGravity = Workspace.Gravity -- ค่าเริ่มต้นของ Roblox มักจะเป็น 196.2

-- รอให้เกมโหลด
repeat wait() until game:IsLoaded()

-- อัพเดทข้อมูลตัวละครจาก Workspace.Characters
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
    -- คืนค่า Gravity และ Anchored ตามสถานะ toggle เมื่อตัวละครเกิดใหม่
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

-- ตัวแปรสำหรับเก็บ Part ที่เลือกจาก Dropdown
local selectedPart = "None" -- ค่าเริ่มต้น

-- ตัวแปรสำหรับเก็บสถานะของ Toggle การวาป
local teleportEnabled = false

-- ตัวแปรสำหรับเก็บสถานะของ Toggle Auto Sell
local autoSellEnabled = false

-- ตัวแปรสำหรับเก็บ Part ที่วาปไปล่าสุด
local lastTeleportedPart = nil

-- ตัวแปรสำหรับเก็บการเชื่อมต่อ RenderStepped (สำหรับกล้อง)
local cameraConnection = nil

-- ตัวแปรสำหรับควบคุมการคลิกอัตโนมัติ
local autoClicking = false

-- Function to find the nearest Part based on selected part
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
                -- ตรวจสอบว่า Part ตรงกับที่เลือกหรือเลือก All
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

-- Safe teleport function for player to Part with anchor toggling and auto-sell
local function safeTeleportToPart(targetPosition, currentPart)
    local success, errorMsg = pcall(function()
        if charData and charData.Humanoid and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
            -- ลดลง 10 หน่วยในแกน Y เพื่อวาปด้านล่าง
            local adjustedPosition = targetPosition + Vector3.new(0, -10, 0)
            -- Use MoveTo to avoid CFrame conflicts
            charData.Humanoid:MoveTo(adjustedPosition)
            -- Ensure the character stays at the target position
            task.spawn(function()
                task.wait(0.1) -- Brief delay to let MoveTo process
                if charData and charData.HumanoidRootPart then
                    charData.HumanoidRootPart.CFrame = CFrame.new(adjustedPosition)
                    -- Toggle Anchored only if this is a new part or first teleport
                    if currentPart ~= lastTeleportedPart or lastTeleportedPart == nil then
                        for i = 1, 3 do
                            charData.HumanoidRootPart.Anchored = true
                            task.wait(0.05)
                            charData.HumanoidRootPart.Anchored = false
                            task.wait(0.05)
                        end

                        if teleportEnabled and autoSellEnabled then
                            local animalsFolder = localPlayer.PlayerGui:FindFirstChild("Data") and localPlayer.PlayerGui.Data:FindFirstChild("Animals")
                            if animalsFolder then
                                for _, folder in ipairs(animalsFolder:GetChildren()) do
                                    if folder:IsA("Folder") and tonumber(folder.Name) then
                                        local folderName = folder.Name
                                        local success, result = pcall(function()
                                            local args = {
                                                [1] = {
                                                    [1] = folderName
                                                }
                                            }
                                            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SellSlotsRemote"):InvokeServer(unpack(args))
                                        end)
                                        if not success then
                                            warn("Auto Sell failed for folder ", folderName, ": ", result)
                                        end
                                    end
                                end
                            else
                                warn("Auto Sell: PlayerGui.Data.Animals not found")
                            end
                        end
                    else
                        print("Skipped anchor toggle: same part as last teleport")
                    end
                    -- Ensure final state is anchored if teleportEnabled
                    charData.HumanoidRootPart.Anchored = teleportEnabled
                    -- Update last teleported part
                    lastTeleportedPart = currentPart
                end
            end)
        else
            warn("Character or Humanoid not valid for teleport")
        end
    end)
    if not success then
        warn("Teleport to Part failed: ", errorMsg)
    end
end

-- Function to update camera to top-down view of the nearest part
local function updateCamera()
    local camera = Workspace.CurrentCamera
    local nearestPart = getNearestPart()
    if nearestPart and nearestPart:IsDescendantOf(Workspace) then
        -- ตั้งตำแหน่งกล้องด้านบน Part (20 studs เหนือ Part)
        local cameraPos = nearestPart.Position + Vector3.new(0, 20, 0)
        -- ตั้งมุมกล้องให้มองลงด้านล่าง
        camera.CFrame = CFrame.new(cameraPos, nearestPart.Position)
        print("Camera updated to top-down view of part")
    else
        warn("Cannot update camera: no valid part found")
    end
end

-- Function to simulate a click/tap at the part's screen position
local function simulateClick()
    local camera = Workspace.CurrentCamera
    local nearestPart = getNearestPart()
    if nearestPart and nearestPart:IsDescendantOf(Workspace) then
        local success, result = pcall(function()
            -- แปลงตำแหน่ง 3D ของ Part เป็นตำแหน่ง 2D บนหน้าจอ
            local screenPos, onScreen = camera:WorldToScreenPoint(nearestPart.Position)
            if onScreen then
                -- จำลองการคลิกซ้าย (หรือแตะบนมือถือ)
                VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 0)
                task.wait(0.05) -- จำลองระยะเวลาการกด
                VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 0)
            else
                warn("Part is off-screen, cannot simulate click")
            end
        end)
        if not success then
            warn("Failed to simulate click: ", result)
        end
    else
        warn("Cannot simulate click: no valid part found")
    end
end

-- Auto-click loop every 0.5 seconds
local function startAutoClickLoop()
    task.spawn(function()
        while autoClicking and teleportEnabled do
            if selectedPart ~= "None" then
                simulateClick()
            end
            task.wait(0.5)
        end
    end)
end

-- Player Tab Dropdown
Section1_Tab1:AddDropdown({
    Name = "Select Part to Lasso",
    Options = {"None", "Horse", "Fae", "Fairy", "Flora", "Gargoyle", "Gray", "Kelpie", "Peryton", "Unicorn", "All"},
    Default = "None",
    Callback = function(selected)
        selectedPart = selected
        lastTeleportedPart = nil -- Reset to ensure teleport to new part
        print("Selected Part to Lasso changed to: ", selected)
    end
})

-- เพิ่ม Toggle สำหรับเปิด/ปิดการวาปไปที่ Part และปรับ Gravity, Anchored, Camera, Auto-Click
Section1_Tab1:AddToggle({
    Name = "Enable Teleport to Part",
    Default = false,
    Callback = function(state)
        teleportEnabled = state
        lastTeleportedPart = nil -- Reset to ensure fresh teleport
        local camera = Workspace.CurrentCamera
        if charData and charData.HumanoidRootPart and charData.Humanoid then
            if state then
                -- ตรวจสอบและตั้งค่า PromptFrame.Visible
                local success, promptFrame = pcall(function()
                    local promptGui = localPlayer.PlayerGui:FindFirstChild("PromptGui")
                    return promptGui and promptGui:FindFirstChild("PromptFrame")
                end)
                if success and promptFrame and promptFrame.Visible then
                    promptFrame.Visible = false
                    print("PromptFrame.Visible set to false")
                elseif not success then
                    warn("Failed to access PromptGui.PromptFrame: ", promptFrame)
                elseif promptFrame and not promptFrame.Visible then
                    print("PromptFrame is already invisible")
                else
                    warn("PromptGui.PromptFrame not found")
                end

                -- ตั้งค่า Gravity และ Anchored
                Workspace.Gravity = 0
                charData.HumanoidRootPart.Anchored = true
                -- ตั้งค่ากล้องเป็น Scriptable และเริ่มติดตาม Part
                camera.CameraType = Enum.CameraType.Scriptable
                updateCamera() -- ตั้งค่ากล้องทันที
                cameraConnection = RunService.RenderStepped:Connect(function()
                    if teleportEnabled then
                        updateCamera()
                    end
                end)
                -- เริ่มการคลิกอัตโนมัติ
                autoClicking = true
                startAutoClickLoop()
                print("Teleport to Part enabled")
            else
                -- คืนค่า Gravity และ Anchored
                Workspace.Gravity = defaultGravity
                charData.HumanoidRootPart.Anchored = false
                -- คืนค่ากล้องเป็น Custom และหยุดการติดตาม
                if cameraConnection then
                    cameraConnection:Disconnect()
                    cameraConnection = nil
                end
                camera.CameraType = Enum.CameraType.Custom
                -- หยุดการคลิกอัตโนมัติ
                autoClicking = false
                print("Teleport to Part disabled")
            end
        else
            warn("Cannot set gravity, anchor, camera, auto-click, or check PromptFrame: charData or HumanoidRootPart missing")
            teleportEnabled = false -- Disable toggle if charData is invalid
        end
    end
})

-- เพิ่ม Toggle สำหรับ Auto Sell
Section1_Tab1:AddToggle({
    Name = "Auto Sell",
    Default = false,
    Callback = function(state)
        autoSellEnabled = state
        print("Auto Sell toggled: ", state and "Enabled" or "Disabled")
    end
})

-- Teleport loop every 0.1 second using RunService.Heartbeat
local teleportConnection
teleportConnection = RunService.Heartbeat:Connect(function()
    if teleportEnabled and selectedPart ~= "None" and charData and charData.Humanoid and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(Workspace) then
        local nearestPart = getNearestPart()
        if nearestPart and nearestPart:IsDescendantOf(Workspace) then
            -- วาปผู้เล่นไปหา Part
            safeTeleportToPart(nearestPart.Position, nearestPart)
        else
            warn("No valid part found for teleportation")
        end
    end
end)

-- แท็บที่สอง: Farm Features
local Tab2 = TabControls:CreateTab({
    Name = "Farm",
    Icon = "rbxassetid://7072719338"
})

local Section1_Tab2 = Tab2:AddSection("Auto Farm", true)
local Section2_Tab2 = Tab2:AddSection("Auto Farm Food", true)

-- ตัวแปรสำหรับเก็บสถานะของแต่ละ Toggle สำหรับ Farm
local FarmToggles = {
    FarmJumpsEXP = false,
    BoostPads = false,
    FarmFood = false
}

-- ตัวแปรสำหรับจัดการการนับ 1-100 สำหรับ Farm Food
local dropCounter = 1
local lastFarmTime = 0
local selectedFood = "SilkBush" -- ค่าเริ่มต้นของ Dropdown

-- ฟังก์ชันสำหรับ Farm Jumps EXP
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

-- ฟังก์ชันสำหรับ BoostPads
local function activateBoostPads()
    local success, errorMsg = pcall(function()
        Workspace:WaitForChild("BoostPads"):WaitForChild("Speed"):WaitForChild("RemoteEvent"):FireServer()
    end)
    if not success then
        warn("BoostPads activation failed: ", errorMsg)
    end
end

-- ฟังก์ชันสำหรับ Farm Food
local function farmFood()
    local success, errorMsg = pcall(function()
        -- รายการทรัพยากรที่จะฟาร์ม
        local resources = selectedFood == "All" and {
            "AppleBarrel", "BerryBush", "FallenTree", "FoodPallet", 
            "LargeBerryBush", "StoneDeposit", "Stump", "Treasure", "SilkBush"
        } or {selectedFood}

        for _, resource in ipairs(resources) do
            -- ส่วนที่ 1: RemoteEvent สำหรับทรัพยากร (แรก)
            local args1 = {
                [1] = 5,
                [2] = true
            }
            Workspace:WaitForChild("Interactions"):WaitForChild("Resource"):WaitForChild(resource):WaitForChild("RemoteEvent"):InvokeServer(unpack(args1))

            -- ส่วนที่ 2: RemoteEvent สำหรับทรัพยากร (ใช้ Animal ID 3)
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

-- ฟังก์ชันสำหรับ SendDropsRemote (สลับ \1 ถึง \100)
local function sendDrops()
    local success, errorMsg = pcall(function()
        local args = {
            [1] = "\\" .. dropCounter
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SendDropsRemote"):FireServer(unpack(args))
        -- อัพเดทตัวนับ
        dropCounter = dropCounter + 1
        if dropCounter > 100 then
            dropCounter = 1
        end
    end)
    if not success then
        warn("SendDropsRemote failed: ", errorMsg)
    end
end

-- Toggle สำหรับ Farm Jumps EXP
Section1_Tab2:AddToggle({
    Name = "Farm Jumps EXP",
    Default = false,
    Callback = function(state)
        FarmToggles.FarmJumpsEXP = state
        print("Farm Jumps EXP toggled: ", state and "Enabled" or "Disabled")
    end
})

-- Toggle สำหรับ BoostPads
Section1_Tab2:AddToggle({
    Name = "BoostPads",
    Default = false,
    Callback = function(state)
        FarmToggles.BoostPads = state
        print("BoostPads toggled: ", state and "Enabled" or "Disabled")
    end
})

-- Farm Tab Dropdown
Section2_Tab2:AddDropdown({
    Name = "Select Food",
    Options = {"AppleBarrel", "BerryBush", "FallenTree", "FoodPallet", "LargeBerryBush", "StoneDeposit", "Stump", "Treasure", "SilkBush", "All"},
    Default = "SilkBush",
    Callback = function(selected)
        selectedFood = selected
        print("Selected Food changed to: ", selected)
    end
})

-- Toggle สำหรับ Farm Food
Section2_Tab2:AddToggle({
    Name = "Farm Food",
    Default = false,
    Callback = function(state)
        FarmToggles.FarmFood = state
        print("Farm Food toggled: ", state and "Enabled" or "Disabled")
    end
})

-- Loop สำหรับจัดการ Farm ทุกๆ 0.1 วินาที
RunService.Heartbeat:Connect(function()
    if charData and charData.Character and charData.Character:IsDescendantOf(Workspace) then
        local currentTime = tick()
        if currentTime - lastFarmTime >= 0.1 then
            -- Farm Jumps EXP
            if FarmToggles.FarmJumpsEXP then
                farmJumpsEXP()
            end

            -- BoostPads
            if FarmToggles.BoostPads then
                activateBoostPads()
            end

            -- Farm Food
            if FarmToggles.FarmFood then
                farmFood()
                sendDrops() -- เรียก SendDropsRemote พร้อมสลับเลข
            end

            lastFarmTime = currentTime
        end
    end
end)
