-- VERAX_BOI HUB - SUPER FINAL with EXTRA TAB by Verax_boi
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Gui = Instance.new("ScreenGui")
Gui.Name = "VERAX_BOI_HUB_EXTRA"
Gui.ResetOnSpawn = false
Gui.Parent = Player:WaitForChild("PlayerGui")

local GREEN = Color3.fromRGB(40,220,80)
local BLACK = Color3.fromRGB(0,0,0)

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function stroke(obj) make("UIStroke", { Color = BLACK, Thickness = 2 }, obj) end

local Main = make("Frame", { Size = UDim2.fromOffset(285,440), Position = UDim2.new(.5,-142,.5,-220), BackgroundColor3 = Color3.fromRGB(20,20,20), BorderSizePixel = 0 }, Gui)
stroke(Main)
local Header = make("Frame", { Size = UDim2.new(1,0,0,42), BackgroundColor3 = GREEN, BorderSizePixel = 0 }, Main)
make("TextLabel", { Size = UDim2.new(1,-45,1,0), BackgroundTransparency = 1, Text = "VERAX_BOI HUB", TextColor3 = BLACK, Font = Enum.Font.GothamBold, TextSize = 16 }, Header)
local Close = make("TextButton", { Size = UDim2.fromOffset(40,40), Position = UDim2.new(1,-40,0,0), BackgroundColor3 = BLACK, Text = "X", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 20 }, Header)

-- 3 TABS
local TabBar = make("Frame", { Position = UDim2.fromOffset(0,42), Size = UDim2.new(1,0,0,38), BackgroundColor3 = BLACK }, Main)
local MainTab = make("TextButton", { Position = UDim2.new(0,0,0,0), Size = UDim2.new(.33,0,1,0), BackgroundColor3 = GREEN, Text = "MAIN", TextColor3 = BLACK, Font = Enum.Font.GothamBold, TextSize = 14 }, TabBar)
local JabTab = make("TextButton", { Position = UDim2.new(.33,0,0,0), Size = UDim2.new(.33,0,1,0), BackgroundColor3 = Color3.fromRGB(35,35,35), Text = "JAB", TextColor3 = GREEN, Font = Enum.Font.GothamBold, TextSize = 14 }, TabBar)
local ExtraTab = make("TextButton", { Position = UDim2.new(.66,0,0,0), Size = UDim2.new(.34,0,1,0), BackgroundColor3 = Color3.fromRGB(35,35,35), Text = "EXTRA", TextColor3 = GREEN, Font = Enum.Font.GothamBold, TextSize = 14 }, TabBar)

local MainPage = make("Frame", { Position = UDim2.fromOffset(0,80), Size = UDim2.new(1,0,1,-80), BackgroundTransparency = 1 }, Main)
local JabPage = make("ScrollingFrame", { Position = UDim2.fromOffset(0,80), Size = UDim2.new(1,0,1,-80), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0,600), Visible = false }, Main)
local ExtraPage = make("ScrollingFrame", { Position = UDim2.fromOffset(0,80), Size = UDim2.new(1,0,1,-80), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0,500), Visible = false }, Main)

local layout1 = make("UIListLayout", { Padding = UDim.new(0,8), HorizontalAlignment = Enum.HorizontalAlignment.Center }, JabPage)
local layout2 = make("UIListLayout", { Padding = UDim.new(0,8), HorizontalAlignment = Enum.HorizontalAlignment.Center }, ExtraPage)

-- MAIN PAGE UI
local function label(parent,text,y) return make("TextLabel", { Position = UDim2.fromOffset(15,y), Size = UDim2.new(1,-30,0,24), BackgroundTransparency = 1, Text = text, TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 14 }, parent) end
local function inputBox(parent,placeholder,y,value) return make("TextBox", { Position = UDim2.fromOffset(15,y), Size = UDim2.new(1,-30,0,34), BackgroundColor3 = Color3.fromRGB(40,40,40), TextColor3 = WHITE, PlaceholderText = placeholder, Text = tostring(value), Font = Enum.Font.Gotham, TextSize = 15 }, parent) end
local function btn(parent,text,y) local b = make("TextButton", { Position = UDim2.fromOffset(15,y), Size = UDim2.new(1,-30,0,34), BackgroundColor3 = GREEN, Text = text, TextColor3 = BLACK, Font = Enum.Font.GothamBold, TextSize = 14 }, parent) stroke(b) return b end

label(MainPage,"CUSTOM SPEED",5)
local SpeedBox = inputBox(MainPage,"Speed",30,16)
label(MainPage,"CUSTOM JUMP",70)
local JumpBox = inputBox(MainPage,"Jump",95,50)
label(MainPage,"FLY SPEED",135)
local FlySpeedBox = inputBox(MainPage,"Fly Speed (ex 50)",160,50)
local Apply = btn(MainPage,"APPLY",205)
local FlyButton = btn(MainPage,"FLY: OFF",247)
local Reset = btn(MainPage,"RESET",289)

local function jabBtn(parent,name)
    local b = make("TextButton", { Size = UDim2.new(1,-25,0,45), BackgroundColor3 = GREEN, Text = name, TextColor3 = BLACK, Font = Enum.Font.GothamBold, TextSize = 14 }, parent)
    stroke(b)
    return b
end

-- JAB BUTTONS
local GodBtn = jabBtn(JabPage,"GOD MODE [OFF]")
local FloatBtn = jabBtn(JabPage,"FLOAT [OFF]")
local AntiBtn = jabBtn(JabPage,"ANTI-FLING [OFF]")
local EspBtn = jabBtn(JabPage,"ESP PLAYER [OFF]")
local LowBtn = jabBtn(JabPage,"LOW GRAPHICS [OFF]")
local AfkBtn = jabBtn(JabPage,"ANTI-AFK [OFF]")
local VoidBtn = jabBtn(JabPage,"VOID RETURN [ON]")

-- EXTRA BUTTONS - NEW TAB
local NoclipBtn = jabBtn(ExtraPage,"NOCLIP [OFF]")
local InfJumpBtn = jabBtn(ExtraPage,"INFINITE JUMP [OFF]")
local HopBtn = jabBtn(ExtraPage,"SERVER HOP")
local RejoinBtn = jabBtn(ExtraPage,"REJOIN SERVER")
local CopyPosBtn = jabBtn(ExtraPage,"COPY POSITION")

-- === JAB LOGIC ===
local godOn = false
local oldSpeed, oldJump
GodBtn.MouseButton1Click:Connect(function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if not godOn then godOn = true oldSpeed = hum.WalkSpeed oldJump = hum.JumpPower hum.WalkSpeed = 100 hum.JumpPower = 150 GodBtn.Text = "GOD MODE [ON]" GodBtn.BackgroundColor3 = Color3.fromRGB(0,180,100)
    else godOn = false hum.WalkSpeed = oldSpeed or 16 hum.JumpPower = oldJump or 50 GodBtn.Text = "GOD MODE [OFF]" GodBtn.BackgroundColor3 = GREEN end
end)

local floatOn = false
local fConn, fVel, fGyro
FloatBtn.MouseButton1Click:Connect(function()
    local char = Player.Character local root = char and char:FindFirstChild("HumanoidRootPart") local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if not floatOn then floatOn = true FloatBtn.Text = "FLOAT [ON]" FloatBtn.BackgroundColor3 = Color3.fromRGB(0,180,100) hum.PlatformStand = true fVel = Instance.new("BodyVelocity") fVel.MaxForce = Vector3.new(1e6,1e6,1e6) fVel.Velocity = Vector3.new(0,0,0) fVel.Parent = root fGyro = Instance.new("BodyGyro") fGyro.MaxTorque = Vector3.new(1e6,1e6,1e6) fGyro.Parent = root fConn = RunService.RenderStepped:Connect(function() fVel.Velocity = Vector3.new(0,0.5,0) fGyro.CFrame = workspace.CurrentCamera.CFrame end)
    else floatOn = false FloatBtn.Text = "FLOAT [OFF]" FloatBtn.BackgroundColor3 = GREEN if fConn then fConn:Disconnect() fConn=nil end if fVel then fVel:Destroy() fVel=nil end if fGyro then fGyro:Destroy() fGyro=nil end hum.PlatformStand = false end
end)

local antiOn = false
local antiLoaded = false
AntiBtn.MouseButton1Click:Connect(function()
    if not antiOn then antiOn = true AntiBtn.Text = "ANTI-FLING [ON]" AntiBtn.BackgroundColor3 = Color3.fromRGB(0,180,100) if not antiLoaded then pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/sytcal/antifling/main/9999"))() end) antiLoaded = true end
    else antiOn = false AntiBtn.Text = "ANTI-FLING [OFF]" AntiBtn.BackgroundColor3 = GREEN end
end)

local espOn = false
local espConns = {}
local function createEsp(plr)
    if plr == Player then return end
    local function add(char) if char:FindFirstChild("VERAX_ESP") then return end local hl = Instance.new("Highlight") hl.Name="VERAX_ESP" hl.FillColor=Color3.fromRGB(0,255,0) hl.OutlineColor=Color3.fromRGB(255,255,255) hl.FillTransparency=0.5 hl.Parent=char local head = char:FindFirstChild("Head") if head then local bb = Instance.new("BillboardGui") bb.Name="VERAX_NAME" bb.Size=UDim2.new(0,100,0,20) bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true bb.Parent=head local lbl = Instance.new("TextLabel") lbl.Size=UDim2.new(1,0,1,0) lbl.BackgroundTransparency=1 lbl.Text=plr.Name lbl.TextColor3=Color3.fromRGB(0,255,0) lbl.Font=Enum.Font.GothamBold lbl.TextSize=13 lbl.Parent=bb end end
    if plr.Character then add(plr.Character) end plr.CharacterAdded:Connect(add)
end
local function clearEsp() for _,v in pairs(workspace:GetDescendants()) do if v.Name=="VERAX_ESP" or v.Name=="VERAX_NAME" then v:Destroy() end end end
EspBtn.MouseButton1Click:Connect(function()
    if not espOn then espOn=true EspBtn.Text="ESP PLAYER [ON]" EspBtn.BackgroundColor3=Color3.fromRGB(0,180,100) for _,plr in pairs(Players:GetPlayers()) do createEsp(plr) end table.insert(espConns, Players.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Wait() task.wait(0.5) if espOn then createEsp(plr) end end))
    else espOn=false EspBtn.Text="ESP PLAYER [OFF]" EspBtn.BackgroundColor3=GREEN clearEsp() for _,c in pairs(espConns) do c:Disconnect() end espConns={} end
end)

local lowOn=false
LowBtn.MouseButton1Click:Connect(function()
    if not lowOn then lowOn=true LowBtn.Text="LOW GRAPHICS [ON]" LowBtn.BackgroundColor3=Color3.fromRGB(0,180,100) for _,v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.Material=Enum.Material.SmoothPlastic end if v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end end
    else lowOn=false LowBtn.Text="LOW GRAPHICS [OFF]" LowBtn.BackgroundColor3=GREEN end
end)

local afkOn=false
local afkConn
AfkBtn.MouseButton1Click:Connect(function()
    if not afkOn then afkOn=true AfkBtn.Text="ANTI-AFK [ON]" AfkBtn.BackgroundColor3=Color3.fromRGB(0,180,100) afkConn=Player.Idled:Connect(function() game:GetService("VirtualUser"):CaptureController() game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end)
    else afkOn=false AfkBtn.Text="ANTI-AFK [OFF]" AfkBtn.BackgroundColor3=GREEN if afkConn then afkConn:Disconnect() end end
end)

local voidOn=true
RunService.Heartbeat:Connect(function() if not voidOn then return end local char=Player.Character local root=char and char:FindFirstChild("HumanoidRootPart") if root and root.Position.Y < -100 then root.CFrame=CFrame.new(0,50,0) end end)
VoidBtn.MouseButton1Click:Connect(function() voidOn=not voidOn VoidBtn.Text= voidOn and "VOID RETURN [ON]" or "VOID RETURN [OFF]" VoidBtn.BackgroundColor3= voidOn and Color3.fromRGB(0,180,100) or GREEN end)

-- === EXTRA TAB LOGIC ===
local noclipOn = false
local noclipConn
NoclipBtn.MouseButton1Click:Connect(function()
    noclipOn = not noclipOn
    NoclipBtn.Text = noclipOn and "NOCLIP [ON]" or "NOCLIP [OFF]"
    NoclipBtn.BackgroundColor3 = noclipOn and Color3.fromRGB(0,180,100) or GREEN
    if noclipOn then
        noclipConn = RunService.Stepped:Connect(function()
            if Player.Character then
                for _,v in pairs(Player.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() end
    end
end)

local infJumpOn = false
local infJumpConn
InfJumpBtn.MouseButton1Click:Connect(function()
    infJumpOn = not infJumpOn
    InfJumpBtn.Text = infJumpOn and "INFINITE JUMP [ON]" or "INFINITE JUMP [OFF]"
    InfJumpBtn.BackgroundColor3 = infJumpOn and Color3.fromRGB(0,180,100) or GREEN
    if infJumpOn then
        infJumpConn = UIS.JumpRequest:Connect(function()
            if infJumpOn then local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect() end
    end
end)

HopBtn.MouseButton1Click:Connect(function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
end)

RejoinBtn.MouseButton1Click:Connect(function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end)

CopyPosBtn.MouseButton1Click:Connect(function()
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        setclipboard(tostring(root.CFrame))
        game.StarterGui:SetCore("SendNotification",{Title="VERAX_BOI", Text="Position Copied!", Duration=2})
    end
end)

-- TAB SWITCH
local function showPage(name)
    MainPage.Visible = name=="MAIN"
    JabPage.Visible = name=="JAB"
    ExtraPage.Visible = name=="EXTRA"
    MainTab.BackgroundColor3 = name=="MAIN" and GREEN or Color3.fromRGB(35,35,35)
    MainTab.TextColor3 = name=="MAIN" and BLACK or GREEN
    JabTab.BackgroundColor3 = name=="JAB" and GREEN or Color3.fromRGB(35,35,35)
    JabTab.TextColor3 = name=="JAB" and BLACK or GREEN
    ExtraTab.BackgroundColor3 = name=="EXTRA" and GREEN or Color3.fromRGB(35,35,35)
    ExtraTab.TextColor3 = name=="EXTRA" and BLACK or GREEN
end
MainTab.MouseButton1Click:Connect(function() showPage("MAIN") end)
JabTab.MouseButton1Click:Connect(function() showPage("JAB") end)
ExtraTab.MouseButton1Click:Connect(function() showPage("EXTRA") end)
showPage("MAIN")

-- FLY
local function getHumanoid() local char=Player.Character return char and char:FindFirstChildOfClass("Humanoid") end
Apply.MouseButton1Click:Connect(function() local h=getHumanoid() if not h then return end local speed=tonumber(SpeedBox.Text) local jump=tonumber(JumpBox.Text) if speed then h.WalkSpeed=math.clamp(speed,0,200) end if jump then h.UseJumpPower=true h.JumpPower=math.clamp(jump,0,300) end end)
Reset.MouseButton1Click:Connect(function() local h=getHumanoid() if h then h.WalkSpeed=16 h.JumpPower=50 end SpeedBox.Text="16" JumpBox.Text="50" FlySpeedBox.Text="50" end)

local flying2, upHeld, downHeld, flyConn2, vel2, gyro2
local Controls = make("Frame", { Size = UDim2.fromOffset(120,110), Position = UDim2.new(1,-140,.5,-55), BackgroundTransparency = 1, Visible = false }, Gui)
local Up = make("TextButton", { Size = UDim2.fromOffset(55,45), Position = UDim2.fromOffset(30,0), BackgroundColor3 = GREEN, Text = "UP", TextColor3 = BLACK, Font = Enum.Font.GothamBold }, Controls)
local Down = make("TextButton", { Size = UDim2.fromOffset(55,45), Position = UDim2.fromOffset(30,60), BackgroundColor3 = GREEN, Text = "DOWN", TextColor3 = BLACK, Font = Enum.Font.GothamBold }, Controls)
local function hold(btn, cb) btn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then cb(true) end end) btn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then cb(false) end end) end
hold(Up,function(v) upHeld=v end) hold(Down,function(v) downHeld=v end)
local function stopFly() flying2=false Controls.Visible=false if flyConn2 then flyConn2:Disconnect() flyConn2=nil end if vel2 then vel2:Destroy() vel2=nil end if gyro2 then gyro2:Destroy() gyro2=nil end local h=getHumanoid() if h then h.PlatformStand=false end FlyButton.Text="FLY: OFF" end
local function startFly() local char=Player.Character local h=getHumanoid() local root=char and char:FindFirstChild("HumanoidRootPart") if not root or not h then return end flying2=true h.PlatformStand=true vel2=Instance.new("BodyVelocity") vel2.MaxForce=Vector3.new(1e6,1e6,1e6) vel2.Parent=root gyro2=Instance.new("BodyGyro") gyro2.MaxTorque=Vector3.new(1e6,1e6,1e6) gyro2.Parent=root Controls.Visible=true FlyButton.Text="FLY: ON" flyConn2=RunService.RenderStepped:Connect(function() if not flying2 or not root.Parent then stopFly() return end local cam=workspace.CurrentCamera local vertical=(upHeld and 1 or 0)-(downHeld and 1 or 0) local flySpeed=tonumber(FlySpeedBox.Text) or 50 vel2.Velocity=h.MoveDirection*flySpeed+Vector3.new(0,vertical*flySpeed,0) gyro2.CFrame=cam.CFrame end) end
FlyButton.MouseButton1Click:Connect(function() if flying2 then stopFly() else startFly() end end)

local Mini = make("TextButton", { Size = UDim2.fromOffset(58,58), Position = UDim2.new(0,20,.5,-29), BackgroundColor3 = GREEN, Text = "VBH", TextColor3 = BLACK, Font = Enum.Font.GothamBold, TextSize = 19, Visible = false }, Gui)
stroke(Mini) make("UICorner", { CornerRadius = UDim.new(0,10) }, Mini)
Close.MouseButton1Click:Connect(function() Main.Visible=false Mini.Visible=true end)
Mini.MouseButton1Click:Connect(function() Main.Visible=true Mini.Visible=false end)
local function draggable(frame,handle) local active,start,origin handle.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then active=true start=input.Position origin=frame.Position end end) UIS.InputChanged:Connect(function(input) if active and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then local delta=input.Position-start frame.Position=UDim2.new(origin.X.Scale,origin.X.Offset+delta.X,origin.Y.Scale,origin.Y.Offset+delta.Y) end end) UIS.InputEnded:Connect(function() active=false end) end
draggable(Main,Header) draggable(Mini,Mini)

layout1:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() JabPage.CanvasSize = UDim2.fromOffset(0,layout1.AbsoluteContentSize.Y + 15) end)
layout2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ExtraPage.CanvasSize = UDim2.fromOffset(0,layout2.AbsoluteContentSize.Y + 15) end)

print("VERAX_BOI HUB EXTRA LOADED")
