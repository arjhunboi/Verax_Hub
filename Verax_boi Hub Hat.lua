--[[
	VERAX HAT HUB  |  Created by: Verax_boi
	For Delta executor. Tabs: MAIN, HUB HAT, SCRIPT, TSB
	Colors: green + black
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer

local GREEN = Color3.fromRGB(0, 255, 100)
local BLACK = Color3.fromRGB(10, 10, 10)

------------------------------------------------------------
-- helpers
------------------------------------------------------------
local function mk(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end

local function notify(text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "VERAX HAT HUB", Text = text, Duration = 3})
	end)
end

local function guiParent()
	local ok, res = pcall(function()
		return (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if ok and res then return res end
	return lp:WaitForChild("PlayerGui")
end

-- remove old copy
pcall(function()
	local p = guiParent()
	local old = p:FindFirstChild("VeraxHatHub")
	if old then old:Destroy() end
end)

local function round(obj, r)
	mk("UICorner", {CornerRadius = UDim.new(0, r or 6)}, obj)
end
local function stroke(obj, t)
	mk("UIStroke", {Color = GREEN, Thickness = t or 1}, obj)
end

local function makeDraggable(handle, target)
	local dragging, startPos, startFramePos, moved = false, nil, nil, false
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			startPos = i.Position
			startFramePos = target.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startPos
			if d.Magnitude > 6 then moved = true end
			target.Position = UDim2.new(startFramePos.X.Scale, startFramePos.X.Offset + d.X, startFramePos.Y.Scale, startFramePos.Y.Offset + d.Y)
		end
	end)
	return function() return moved end
end

------------------------------------------------------------
-- state / features
------------------------------------------------------------
local State = {
	applyOn = false, speed = 16, jump = 50, flySpeed = 60,
	fly = false, noclip = false, antifling = false,
	infjump = false, esp = false, xray = false, antiafk = false, antikick = false,
	facenearest = false, aimlock = false, orbit = false, orbitSpeed = 3, orbitRadius = 8,
}
local conns = {}
local alive = true

local function getChar() return lp.Character end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- apply speed / jump
conns[#conns + 1] = RunService.Heartbeat:Connect(function()
	if State.applyOn then
		local h = getHum()
		if h then
			h.WalkSpeed = State.speed
			h.UseJumpPower = true
			h.JumpPower = State.jump
		end
	end
end)

local function resetStats()
	State.applyOn = false
	local h = getHum()
	if h then
		h.WalkSpeed = 16
		h.UseJumpPower = true
		h.JumpPower = 50
	end
end

-- fly
local flyBV, flyBG
local function stopFlyObjects()
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
	local h = getHum()
	if h then h.PlatformStand = false end
end

conns[#conns + 1] = RunService.RenderStepped:Connect(function()
	if not State.fly then return end
	local root, hum = getRoot(), getHum()
	if not root or not hum then return end
	if not flyBV or flyBV.Parent ~= root then
		if flyBV then flyBV:Destroy() end
		flyBV = mk("BodyVelocity", {MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.zero}, root)
	end
	if not flyBG or flyBG.Parent ~= root then
		if flyBG then flyBG:Destroy() end
		flyBG = mk("BodyGyro", {MaxTorque = Vector3.new(9e9, 9e9, 9e9), P = 9e4}, root)
	end
	local cam = workspace.CurrentCamera
	local localMove = cam.CFrame:VectorToObjectSpace(hum.MoveDirection)
	local vec = cam.CFrame.LookVector * (-localMove.Z) + cam.CFrame.RightVector * localMove.X
	flyBV.Velocity = vec * State.flySpeed
	flyBG.CFrame = cam.CFrame
	hum.PlatformStand = true
end)

-- noclip + anti-fling
conns[#conns + 1] = RunService.Stepped:Connect(function()
	if State.noclip then
		local c = getChar()
		if c then
			for _, v in ipairs(c:GetDescendants()) do
				if v:IsA("BasePart") then v.CanCollide = false end
			end
		end
	end
	if State.antifling then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp and p.Character then
				for _, v in ipairs(p.Character:GetDescendants()) do
					if v:IsA("BasePart") then v.CanCollide = false end
				end
			end
		end
		local root = getRoot()
		if root and not State.fly then
			if root.AssemblyAngularVelocity.Magnitude > 50 then
				root.AssemblyAngularVelocity = Vector3.zero
			end
			if root.AssemblyLinearVelocity.Magnitude > 120 then
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
end)

-- infinite jump
conns[#conns + 1] = UIS.JumpRequest:Connect(function()
	if State.infjump then
		local h = getHum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- anti-afk
conns[#conns + 1] = lp.Idled:Connect(function()
	if State.antiafk then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- anti-kick (client side only)
local kickHooked = false
local function hookKick()
	if kickHooked then return true end
	local ok = pcall(function()
		local old
		old = hookmetamethod(game, "__namecall", function(self, ...)
			if State.antikick and self == lp and getnamecallmethod():lower() == "kick" then
				return
			end
			return old(self, ...)
		end)
	end)
	if ok then kickHooked = true end
	return ok
end

-- low graphics / fps booster
local function fpsBoost()
	task.spawn(function()
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			for _, v in ipairs(Lighting:GetChildren()) do
				if v:IsA("PostEffect") then v.Enabled = false end
			end
		end)
		pcall(function()
			local t = workspace.Terrain
			t.WaterWaveSize, t.WaterWaveSpeed, t.WaterReflectance, t.WaterTransparency = 0, 0, 0, 0
		end)
		local n = 0
		for _, v in ipairs(workspace:GetDescendants()) do
			pcall(function()
				if v:IsA("BasePart") then
					v.Material = Enum.Material.Plastic
					v.Reflectance = 0
				elseif v:IsA("Decal") or v:IsA("Texture") then
					v.Transparency = 1
				elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
					v.Enabled = false
				end
			end)
			n = n + 1
			if n % 500 == 0 then task.wait() end
		end
		notify("Low graphics applied")
	end)
end

-- esp + health bar
local espObjs = {}
local espInfo = {}
local function clearEsp()
	for p, o in pairs(espObjs) do
		for _, x in ipairs(o) do pcall(function() x:Destroy() end) end
		espObjs[p] = nil
		espInfo[p] = nil
	end
end
local function addEsp(p)
	local c = p.Character
	if not c then return end
	local hl = mk("Highlight", {FillColor = GREEN, OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.6, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, c)
	local list = {hl}
	local head = c:FindFirstChild("Head")
	if head then
		local bb = mk("BillboardGui", {Size = UDim2.new(0, 110, 0, 30), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true}, head)
		local nameL = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = p.DisplayName, TextColor3 = GREEN, Font = Enum.Font.GothamBold, TextScaled = true}, bb)
		local barBg = mk("Frame", {Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 20), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, bb)
		local fill = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = GREEN, BorderSizePixel = 0}, barBg)
		list[2] = bb
		espInfo[p] = {fill = fill, label = nameL}
	end
	espObjs[p] = list
end
task.spawn(function()
	while alive do
		if State.esp then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= lp and p.Character then
					local o = espObjs[p]
					if not o or not o[1] or o[1].Parent ~= p.Character then
						if o then for _, x in ipairs(o) do pcall(function() x:Destroy() end) end end
						espInfo[p] = nil
						addEsp(p)
					end
					local info = espInfo[p]
					local h = p.Character:FindFirstChildOfClass("Humanoid")
					if info and h then
						local f = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
						info.fill.Size = UDim2.new(f, 0, 1, 0)
						info.fill.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - f)), math.floor(255 * f), 60)
						info.label.Text = p.DisplayName .. " [" .. math.floor(h.Health) .. "]"
					end
				end
			end
		else
			clearEsp()
		end
		task.wait(0.2)
	end
end)

-- x-ray
local xrayOrig = {}
local function setXray(on)
	task.spawn(function()
		if on then
			local n = 0
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") and v.Transparency < 0.5 then
					local m = v:FindFirstAncestorOfClass("Model")
					if not (m and m:FindFirstChildOfClass("Humanoid")) then
						xrayOrig[v] = v.Transparency
						v.Transparency = 0.6
					end
				end
				n = n + 1
				if n % 500 == 0 then task.wait() end
			end
		else
			for v, t in pairs(xrayOrig) do
				if v and v.Parent then v.Transparency = t end
			end
			xrayOrig = {}
		end
	end)
end

-- rejoin
local function rejoin()
	if #Players:GetPlayers() <= 1 then
		TeleportService:Teleport(game.PlaceId, lp)
	else
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
	end
end

-- R15 -> R6 (client side)
local function toR6()
	local char, hum, root = getChar(), getHum(), getRoot()
	if not (char and hum and root) then notify("No character found") return end
	if hum.RigType == Enum.HumanoidRigType.R6 then notify("You are already R6") return end
	local ok, err = pcall(function()
		local desc = hum:GetAppliedDescription()
		local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
		model.Name = lp.Name
		local animate = char:FindFirstChild("Animate")
		if animate then animate:Clone().Parent = model end
		local cf = root.CFrame
		model.Parent = workspace
		model:PivotTo(cf)
		lp.Character = model
		workspace.CurrentCamera.CameraSubject = model:FindFirstChildOfClass("Humanoid")
		char.Parent = nil
	end)
	if ok then notify("R6 applied") else warn(err) notify("R6 failed") end
end

-- TSB: nearest / orbit / aimlock / teleport
local function aliveRoot(p)
	local c = p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if h and r and h.Health > 0 then return r, h end
end

local function nearestPlayer()
	local myRoot = getRoot()
	if not myRoot then return end
	local bestRoot, bestPlayer, bestDist = nil, nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			local r = aliveRoot(p)
			if r then
				local d = (r.Position - myRoot.Position).Magnitude
				if d < bestDist then bestDist, bestRoot, bestPlayer = d, r, p end
			end
		end
	end
	return bestRoot, bestPlayer
end

local orbitTarget, orbitAngle = nil, 0
conns[#conns + 1] = RunService.RenderStepped:Connect(function(dt)
	local myRoot = getRoot()
	if not myRoot then return end
	if State.orbit then
		if not orbitTarget or not aliveRoot(orbitTarget) then
			local _, p = nearestPlayer()
			orbitTarget = p
		end
		if orbitTarget then
			local r = aliveRoot(orbitTarget)
			if r then
				orbitAngle = orbitAngle + State.orbitSpeed * dt
				local pos = r.Position + Vector3.new(math.cos(orbitAngle) * State.orbitRadius, 0, math.sin(orbitAngle) * State.orbitRadius)
				myRoot.CFrame = CFrame.lookAt(pos, Vector3.new(r.Position.X, pos.Y, r.Position.Z))
				myRoot.AssemblyLinearVelocity = Vector3.zero
			end
		end
	elseif State.facenearest then
		local r = nearestPlayer()
		if r then
			myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(r.Position.X, myRoot.Position.Y, r.Position.Z))
		end
	end
	if State.aimlock then
		local r = nearestPlayer()
		if r then
			local cam = workspace.CurrentCamera
			cam.CFrame = CFrame.lookAt(cam.CFrame.Position, r.Position)
		end
	end
end)

local function findPlayer(name)
	name = name:lower()
	if name == "" then return nil end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and (p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name) then
			return p
		end
	end
end

local function tpTo(p)
	local r = p and aliveRoot(p)
	local m = getRoot()
	if r and m then
		m.CFrame = r.CFrame * CFrame.new(0, 0, 3)
	else
		notify("Player not found")
	end
end

------------------------------------------------------------
-- hat scripts
------------------------------------------------------------
local function SendChatMessage(message)
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if ch then ch:SendAsync(message) else warn("RBXGeneral channel not found!") end
	else
		local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		local say = ev and ev:FindFirstChild("SayMessageRequest")
		if say then say:FireServer(message, "All") else warn("Legacy chat system not found!") end
	end
end

local function runFeSatan()
	--[[
	fe satan converted by maxilito
	-gh 10775031176, 12103236257, 9867481700, 9867487176, 9350274205, 2493590711, 9350274205, 9402600266, 2309346267
	]]
	if not ReplicatedStorage:FindFirstChild("01_server") then
		local gui = mk("ScreenGui", {IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, lp:WaitForChild("PlayerGui"))
		CollectionService:AddTag(gui, "main")
		local fr = mk("Frame", {BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), AnchorPoint = Vector2.new(.5, .5), Size = UDim2.new(.36316, 0, .46667, 0), Position = UDim2.new(.5, 0, .5, 0), BackgroundTransparency = .5}, gui)
		mk("UICorner", {CornerRadius = UDim.new(.04, 0)}, fr)
		mk("TextLabel", {TextWrapped = true, BorderSizePixel = 0, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.new(.81159, 0, .32143, 0), Position = UDim2.new(.0942, 0, .13095, 0), Text = "You are in the wrong game, please copy the link below and enter the game. (game: Just a baseplate., game creator: dreammazestudio/ the local maze)"}, fr)
		mk("TextBox", {BorderSizePixel = 0, ClearTextOnFocus = false, Size = UDim2.new(.81159, 0, .29762, 0), Position = UDim2.new(.1087, 0, .5119, 0), Text = "https://www.roblox.com/games/123974602339071/UP-Just-a-baseplate", TextScaled = true}, fr)
		mk("UIAspectRatioConstraint", {AspectRatio = 1.64286}, fr)
		game:GetService("TeleportService"):Teleport(123974602339071, lp)
		return
	end

	SendChatMessage("-gh 10775031176, 12103236257, 9867481700, 9867487176, 9350274205, 2493590711, 9350274205, 9402600266, 2309346267")
	wait(2.1)

	RunService.RenderStepped:Connect(function()
		if lp.Character then
			for _, v in pairs(lp.Character:GetDescendants()) do
				if v:IsA("BasePart") then v.CanCollide = false end
			end
		end
	end)
	wait(1.5)
	task.delay(5.6, function() SendChatMessage("-net") end)

	loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/Qwerty/refs/heads/main/qwerty36.lua"))()
end

local function runFeVereus()
	--[[
	by supr14, converted by maxilito, reanim used: Myworld#4430
	-gh 6531967293,12103270510,3403874988,10775031176,2493590711,9350274205,4381828509
	Required hat: 7
	]]
	SendChatMessage("-gh 6531967293,12103270510,3403874988,10775031176,2493590711,9350274205,4381828509")
	wait(2.1)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/Qwerty/main/qwerty5.lua"))()
end

local function runKdv3()
	loadstring(game:HttpGet("https://scriptblox.com/raw/UP-Just-a-baseplate.-WORKING-KDV3-MODDED-227082"))()
end

local function runMsTrueHub()
	loadstring(game:HttpGet("https://scriptblox.com/raw/UP-Just-a-baseplate.-MS-TRUEHUB-229118"))()
end

------------------------------------------------------------
-- UI
------------------------------------------------------------
local sg = mk("ScreenGui", {Name = "VeraxHatHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, guiParent())

local main = mk("Frame", {Size = UDim2.new(0, 320, 0, 350), Position = UDim2.new(0.5, -160, 0.5, -175), BackgroundColor3 = BLACK, BorderSizePixel = 0}, sg)
round(main, 8) stroke(main, 2)

local titleBar = mk("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0}, main)
round(titleBar, 8)
mk("TextLabel", {Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "VERAX HAT HUB", TextColor3 = GREEN, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left}, titleBar)

local minBtn = mk("TextButton", {Size = UDim2.new(0, 28, 0, 24), Position = UDim2.new(1, -66, 0, 5), BackgroundColor3 = BLACK, Text = "-", TextColor3 = GREEN, Font = Enum.Font.GothamBold, TextSize = 18}, titleBar)
round(minBtn, 5) stroke(minBtn)
local xBtn = mk("TextButton", {Size = UDim2.new(0, 28, 0, 24), Position = UDim2.new(1, -34, 0, 5), BackgroundColor3 = BLACK, Text = "X", TextColor3 = GREEN, Font = Enum.Font.GothamBold, TextSize = 14}, titleBar)
round(xBtn, 5) stroke(xBtn)

makeDraggable(titleBar, main)

-- tabs
local tabBar = mk("Frame", {Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0, 6, 0, 38), BackgroundTransparency = 1}, main)
local tabButtons = {}
local function makeTab(text, idx)
	local b = mk("TextButton", {Size = UDim2.new(1/4, -4, 1, 0), Position = UDim2.new(idx / 4, 2, 0, 0), BackgroundColor3 = BLACK, Text = text, TextColor3 = GREEN, Font = Enum.Font.GothamBold, TextSize = 12}, tabBar)
	round(b, 5) stroke(b)
	return b
end

local function makePage()
	local s = mk("ScrollingFrame", {Size = UDim2.new(1, -12, 1, -98), Position = UDim2.new(0, 6, 0, 72), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = GREEN, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, main)
	mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, s)
	mk("UIPadding", {PaddingRight = UDim.new(0, 4)}, s)
	return s
end

local pages = {MAIN = makePage(), HAT = makePage(), SCRIPT = makePage(), TSB = makePage()}
tabButtons.MAIN = makeTab("MAIN", 0)
tabButtons.HAT = makeTab("HUB HAT", 1)
tabButtons.SCRIPT = makeTab("SCRIPT", 2)
tabButtons.TSB = makeTab("TSB", 3)

local function selectTab(name)
	for k, p in pairs(pages) do
		p.Visible = (k == name)
		tabButtons[k].BackgroundColor3 = (k == name) and Color3.fromRGB(0, 70, 30) or BLACK
	end
end
for k, b in pairs(tabButtons) do
	b.MouseButton1Click:Connect(function() selectTab(k) end)
end
selectTab("MAIN")

-- widgets
local function button(parent, text, cb)
	local b = mk("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = BLACK, Text = text, TextColor3 = GREEN, Font = Enum.Font.GothamBold, TextSize = 14}, parent)
	round(b, 5) stroke(b)
	b.MouseButton1Click:Connect(function() cb(b) end)
	return b
end

local function toggle(parent, text, cb)
	local on = false
	local b
	b = button(parent, text .. ": OFF", function()
		on = not on
		b.Text = text .. (on and ": ON" or ": OFF")
		b.BackgroundColor3 = on and Color3.fromRGB(0, 90, 40) or BL
