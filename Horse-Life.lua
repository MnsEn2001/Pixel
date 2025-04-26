local PixelLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/MnsEn2001/Xlib/refs/heads/main/Lib/PixLib.lua"))()

-- สร้าง GUI หลัก
local Window = PixelLib:CreateGui({
    NameHub = "Pixel Hub",
    Description = "#VIP : Treasure Quest - V2",
    Color = Color3.fromRGB(0, 140, 255),
    TabWidth = 140,
    SizeUI = UDim2.fromOffset(650, 450)
})

local TabControls = Window

-- แท็บแรก: Player Features
local PlayerTab = TabControls:CreateTab({
    Name = "Player",
    Icon = "rbxassetid://7072719338"
})

-- Section 1: Movement
local MovementSection = PlayerTab:AddSection("Movement", true)
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- รอให้เกมโหลด
repeat wait() until game:IsLoaded()

-- อัพเดทข้อมูลตัวละคร
local function updateCharacterData()
    local success, result = pcall(function()
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
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
        warn("ไม่พบตัวละคร: ", result)
        return nil
    end
end

local charData = updateCharacterData()
localPlayer.CharacterAdded:Connect(function()
    charData = updateCharacterData()
end)

-- ตัวแปรสำหรับเก็บสถานะของแต่ละ Part (ปรับให้ตรงกับชื่อใน MobFolder)
local PartToggles = {
    Horse = false,
    Fae = false,
    Fairy = false,
    Flora = false,
    Gargoyle = false,
    Gray = false,
    Kelpie = false,
    Peryton = false,
    Unicorn = false,
    All = false
}

-- ตัวแปรสำหรับสลับโหมด: true = Part วาปมาหา, false = วาปไปหา Part
local PullPartMode = false

-- ตัวแปรสำหรับเก็บ Part ที่สร้างไว้
local currentPlatform = nil

-- ฟังก์ชันสร้าง Part ขนาด 30x30x1 ใต้ตัวละคร 3 หน่วย
local function createPlatform(position)
    -- ลบ Part เก่าถ้ามี
    if currentPlatform then
        currentPlatform:Destroy()
        currentPlatform = nil
    end

    local platform = Instance.new("Part")
    platform.Size = Vector3.new(30, 1, 30) -- ขนาด 30x1x30
    platform.Position = position + Vector3.new(0, -3, 0) -- วางใต้ตัวละคร 3 หน่วย
    platform.Anchored = true
    platform.CanCollide = true
    platform.Name = "TeleportPlatform"
    platform.Parent = workspace
    currentPlatform = platform
end

-- Function to find the nearest Part based on selected toggles
local function getNearestPart()
    local mobFolder = workspace:FindFirstChild("MobFolder")
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

    if playerPos then
        for _, obj in ipairs(objects) do
            if obj:IsA("BasePart") and obj:IsDescendantOf(workspace) then
                local partName = obj.Name
                -- ตรวจสอบว่า Part นี้ถูกเลือกหรือเลือก All
                if PartToggles.All or (PartToggles[partName] and PartToggles[partName] == true) then
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
        warn("Player position not available")
    end

    if not nearestPart then
        warn("No valid parts found in workspace.MobFolder for selected toggles")
    end
    return nearestPart
end

-- Safe teleport function for player to Part
local function safeTeleportToPart(targetPosition)
    local success, errorMsg = pcall(function()
        if charData and charData.Humanoid and charData.HumanoidRootPart and charData.HumanoidRootPart:IsDescendantOf(workspace) then
            -- ลดลง 10 หน่วยในแกน Y เพื่อวาปด้านล่าง
            local adjustedPosition = targetPosition + Vector3.new(0, -10, 0)
            -- สร้าง Part ขนาด 30x30x1 ใต้ตัวละคร 3 หน่วย
            createPlatform(adjustedPosition)
            -- Use MoveTo to avoid CFrame conflicts
            charData.Humanoid:MoveTo(adjustedPosition)
            -- Ensure the character stays at the target position
            task.spawn(function()
                task.wait(0.1) -- Brief delay to let MoveTo process
                if charData and charData.HumanoidRootPart then
                    charData.HumanoidRootPart.CFrame = CFrame.new(adjustedPosition)
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

-- Safe teleport function for Part to player
local function safeTeleportPartToPlayer(part)
    local success, errorMsg = pcall(function()
        if charData and charData.HumanoidRootPart and part and part:IsDescendantOf(workspace) then
            -- ตำแหน่งด้านล่างผู้เล่น 10 หน่วย
            local playerPos = charData.HumanoidRootPart.Position
            local adjustedPosition = playerPos + Vector3.new(0, -10, 0)
            -- สร้าง Part ขนาด 30x30x1 ใต้ตัวละคร 3 หน่วย
            createPlatform(adjustedPosition)
            part.Position = adjustedPosition
        else
            warn("Character or Part not valid for teleport")
        end
    end)
    if not success then
        warn("Teleport Part to player failed: ", errorMsg)
    end
end

-- เพิ่ม Toggle สำหรับแต่ละ Part (ชื่อภาษาไทย)
local partNames = {"ม้า ธรรมดา", "ม้า เฟ", "ม้า เฟรี่", "ม้า ฟลอรา", "ม้า การ์กอยล์", "ม้า เคลพี", "ม้า เพอริตัน", "ม้า ยูนิคอร์น", "ทุกตัว"}
-- แมพชื่อภาษาไทยกับชื่อใน MobFolder
local partNameMapping = {
    ["ม้า ธรรมดา"] = "Horse",
    ["ม้า เฟ"] = "Fae",
    ["ม้า เฟรี่"] = "Fairy",
    ["ม้า ฟลอรา"] = "Flora",
    ["ม้า การ์กอยล์"] = "Gargoyle",
    ["ม้า เคลพี"] = "Kelpie",
    ["ม้า เพอริตัน"] = "Peryton",
    ["ม้า ยูนิคอร์น"] = "Unicorn",
    ["ทุกตัว"] = "All"
}
for _, partName in ipairs(partNames) do
    MovementSection:AddToggle({
        Name = partName,
        Default = false,
        Callback = function(state)
            local mappedName = partNameMapping[partName]
            PartToggles[mappedName] = state
        end
    })
end

-- เพิ่ม Toggle สำหรับสลับโหมดการวาป
MovementSection:AddToggle({
    Name = "ม้า วาปมาที่เรา Beta",
    Default = false,
    Callback = function(state)
        PullPartMode = state
    end
})

-- Teleport loop every 0.1 second
local lastTeleportTime = 0
RunService.Heartbeat:Connect(function()
    -- ตรวจสอบว่ามี Toggle ใดๆ ถูกเปิดหรือไม่
    local anyToggleActive = PartToggles.All or false
    for _, state in pairs(PartToggles) do
        if state then
            anyToggleActive = true
            break
        end
    end

    if anyToggleActive and charData and charData.Humanoid and charData.HumanoidRootPart then
        local currentTime = tick()
        if currentTime - lastTeleportTime >= 0.1 then
            local nearestPart = getNearestPart()
            if nearestPart and nearestPart:IsDescendantOf(workspace) then
                if PullPartMode then
                    -- โหมดให้ Part วาปมาหาผู้เล่น
                    safeTeleportPartToPlayer(nearestPart)
                else
                    -- โหมดผู้เล่นวาปไปหา Part
                    safeTeleportToPart(nearestPart.Position)
                end
            else
                warn("No valid part found for teleportation")
            end
            lastTeleportTime = currentTime
        end
    end
end)

-- ลบ Part เมื่อสคริปต์หยุดทำงาน
game:BindToClose(function()
    if currentPlatform then
        currentPlatform:Destroy()
        currentPlatform = nil
    end
end)
