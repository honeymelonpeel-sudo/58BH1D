local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")

local hwidFileName = "k8P3mQ9aR2"
local HWID
if pcall(function() return readfile(hwidFileName) end) then
    HWID = readfile(hwidFileName)
else
    HWID = HttpService:GenerateGUID(false)
    writefile(hwidFileName, HWID)
end

local API_BASE = "https://www.luoyeyun.icu/api.php"
local APP_ID = "10245"
local LOGIN_API = API_BASE .. "?api=kmlogon&app=" .. APP_ID
local NOTICE_API = API_BASE .. "?api=notice&app=" .. APP_ID
local UNBIND_API = API_BASE .. "?api=kmunmachine&app=" .. APP_ID

local currentKami = ""
local autoVerifyTask
local verifyGui
local loadedMainGuis = {}

local function safeHttpGetJson(url)
    local ok, raw = pcall(function() return game:HttpGet(url) end)
    if not ok then return false, tostring(raw) end
    local ok2, json = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 then return false, tostring(raw) end
    return true, json
end

local function formatMsg(msg)
    if typeof(msg) == "table" then
        local t = {}
        for k,v in pairs(msg) do
            if k ~= "kami" then table.insert(t, k..":"..tostring(v)) end
        end
        return table.concat(t," | ")
    end
    return tostring(msg)
end

local function timestampToDate(ts)
    local d = os.date("*t", tonumber(ts))
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", d.year,d.month,d.day,d.hour,d.min,d.sec)
end

local function verifyKami(kami)
    local url = LOGIN_API.."&kami="..HttpService:UrlEncode(kami).."&markcode="..HttpService:UrlEncode(HWID)
    local ok, res = safeHttpGetJson(url)
    if not ok then return false, res end
    if res.code == 200 then return true, res.msg end
    return false, formatMsg(res.msg)
end

local function unbindKami(kami)
    local url = UNBIND_API.."&kami="..HttpService:UrlEncode(kami).."&markcode="..HttpService:UrlEncode(HWID)
    local ok, res = safeHttpGetJson(url)
    if not ok then return false, res end
    if res.code == 200 then return true, res.msg end
    return false, formatMsg(res.msg)
end

local function fetchNotice()
    local ok, res = safeHttpGetJson(NOTICE_API)
    if not ok then return false, res end
    if res.code == 200 then return true, res.msg end
    return false, formatMsg(res.msg)
end

local function sendNotificationText(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "卡密系统",
            Text = text,
            Duration = 5
        })
    end)
end

local function destroyAllUI()
    if loadedMainGuis then
        for _, gui in ipairs(loadedMainGuis) do
            if gui and gui.Parent then
                pcall(function() gui:Destroy() end)
            end
        end
        loadedMainGuis = {}
    end
    if verifyGui and verifyGui.Parent then
        pcall(function() verifyGui:Destroy() end)
        verifyGui = nil
    end
end

local function showBanUI(reason)
    destroyAllUI()
    local blur = Instance.new("BlurEffect")
    blur.Size = 24
    blur.Parent = Lighting
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    local f = Instance.new("Frame", screenGui)
    f.Size = UDim2.new(0,400,0,200)
    f.Position = UDim2.new(0.5,-200,0.5,-100)
    f.BackgroundColor3 = Color3.fromRGB(50,50,50)
    f.BackgroundTransparency = 0.25
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,16)
    local title = Instance.new("TextLabel", f)
    title.Size = UDim2.new(1,0,0,50)
    title.Position = UDim2.new(0,0,0,10)
    title.Text = "卡密系统"
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255,255,255)
    local content = Instance.new("TextLabel", f)
    content.Size = UDim2.new(1,-20,0,60)
    content.Position = UDim2.new(0,10,0,70)
    content.Text = reason
    content.TextWrapped = true
    content.TextScaled = true
    content.BackgroundTransparency = 1
    content.TextColor3 = Color3.fromRGB(255,200,200)
end

local function createUI()
    verifyGui = Instance.new("ScreenGui")
    verifyGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    verifyGui.ResetOnSpawn = false
    local f = Instance.new("Frame", verifyGui)
    f.Size = UDim2.new(0,380,0,300)
    f.Position = UDim2.new(0.5,-190,0.5,-150)
    f.BackgroundColor3 = Color3.fromRGB(35,35,45)
    f.BackgroundTransparency = 0.35
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,28)
    local dragging, dragInput, dragStart, startPos
    f.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = f.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    f.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            f.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset + delta.X,startPos.Y.Scale,startPos.Y.Offset + delta.Y)
        end
    end)
    local hwidLabel = Instance.new("TextLabel", f)
    hwidLabel.Size = UDim2.new(1,-20,0,40)
    hwidLabel.Position = UDim2.new(0,10,0,10)
    hwidLabel.BackgroundTransparency = 1
    hwidLabel.TextColor3 = Color3.fromRGB(255,255,255)
    hwidLabel.TextXAlignment = Enum.TextXAlignment.Left
    hwidLabel.TextWrapped = true
    hwidLabel.Text = "设备号(HWID): "..HWID
    local kami = Instance.new("TextBox", f)
    kami.Size = UDim2.new(1,-60,0,36)
    kami.Position = UDim2.new(0,30,0,105)
    kami.PlaceholderText = "输入卡密"
    kami.TextColor3 = Color3.fromRGB(255,255,255)
    kami.BackgroundColor3 = Color3.fromRGB(50,50,60)
    kami.BackgroundTransparency = 0.35
    Instance.new("UICorner", kami).CornerRadius = UDim.new(0,16)
    local btnVerify = Instance.new("TextButton", f)
    btnVerify.Size = UDim2.new(0.31,-10,0,40)
    btnVerify.Position = UDim2.new(0.03,0,0,155)
    btnVerify.Text = "验证"
    btnVerify.TextColor3 = Color3.fromRGB(255,255,255)
    btnVerify.BackgroundColor3 = Color3.fromRGB(100,140,255)
    btnVerify.BackgroundTransparency = 0.25
    Instance.new("UICorner", btnVerify).CornerRadius = UDim.new(0,18)
    local btnUnbind = Instance.new("TextButton", f)
    btnUnbind.Size = UDim2.new(0.31,-10,0,40)
    btnUnbind.Position = UDim2.new(0.35,0,0,155)
    btnUnbind.Text = "解绑"
    btnUnbind.TextColor3 = Color3.fromRGB(255,255,255)
    btnUnbind.BackgroundColor3 = Color3.fromRGB(255,180,0)
    btnUnbind.BackgroundTransparency = 0.25
    Instance.new("UICorner", btnUnbind).CornerRadius = UDim.new(0,18)
    local btnNotice = Instance.new("TextButton", f)
    btnNotice.Size = UDim2.new(0.31,-10,0,40)
    btnNotice.Position = UDim2.new(0.67,0,0,155)
    btnNotice.Text = "公告"
    btnNotice.TextColor3 = Color3.fromRGB(255,255,255)
    btnNotice.BackgroundColor3 = Color3.fromRGB(255,120,120)
    btnNotice.BackgroundTransparency = 0.25
    Instance.new("UICorner", btnNotice).CornerRadius = UDim.new(0,18)
    local result = Instance.new("TextLabel", f)
    result.Size = UDim2.new(1,-60,0,40)
    result.Position = UDim2.new(0,30,0,210)
    result.BackgroundTransparency = 1
    result.TextColor3 = Color3.fromRGB(255,255,255)
    result.TextWrapped = true

    task.spawn(function()
        result.Text = "公告加载中..."
        local ok, info = fetchNotice()
        if ok and typeof(info)=="table" and info.app_gg and info.app_gg~="" then
            result.Text = "公告: "..info.app_gg
        else
            result.Text = "公告: 暂无公告"
        end
    end)

    btnVerify.MouseButton1Click:Connect(function()
        result.Text = "验证中..."
        task.spawn(function()
            local ok, info = verifyKami(kami.Text)
            if ok then
                currentKami = kami.Text
                local vip = info.vip and timestampToDate(info.vip) or "无"
                sendNotificationText("验证成功！到期时间："..vip)
                destroyAllUI()
                loadstring(game:HttpGet("https://pastefy.app/s9PijnvT/raw"))()
                if autoVerifyTask then autoVerifyTask:Disconnect() autoVerifyTask = nil end

                autoVerifyTask = RunService.Heartbeat:Connect(function()
                    if tick()%2 < 0.03 then
                        local valid, info2 = verifyKami(currentKami)
                        if not valid then
                            local reasonText = tostring(info2 or "")
                            if string.find(reasonText,"封") or string.find(reasonText,"禁") then
                                showBanUI("卡密被禁用，请手动退出服务器")
                                task.wait(0.5)
                                LocalPlayer:Kick("卡密被禁用")
                            else
                                showBanUI("卡密到期，请手动退出服务器")
                                task.wait(0.5)
                                LocalPlayer:Kick("卡密到期")
                            end
                            if autoVerifyTask then autoVerifyTask:Disconnect() autoVerifyTask = nil end
                        end
                    end
                end)

            else
                result.Text = "验证失败: "..info
            end
        end)
    end)

    btnUnbind.MouseButton1Click:Connect(function()
        result.Text = "解绑中..."
        task.spawn(function()
            local ok, info = unbindKami(kami.Text)
            if ok then
                result.Text = "解绑成功"
            else
                sendNotificationText("解绑失败: "..info)
            end
        end)
    end)

    btnNotice.MouseButton1Click:Connect(function()
        result.Text = "获取公告..."
        task.spawn(function()
            local ok, info = fetchNotice()
            if ok and typeof(info)=="table" and info.app_gg and info.app_gg~="" then
                result.Text = "公告: "..info.app_gg
            else
                result.Text = "公告: 暂无公告"
            end
        end)
    end)
end

pcall(createUI)