--[[
	V3R4X_B01 V3.5  |  Universal Hub for Delta
	Tabs: PLAYER, WORLD, PLAYERS, COMBAT, FIGHT, EMOTES, EXECUTOR, UTILITY, CMDS, INFO
	RightShift = hide / show (PC)
	NO KEY SYSTEM
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local lp = Players.LocalPlayer

local BG = Color3.fromRGB(12, 12, 14)
local PANEL = Color3.fromRGB(24, 24, 28)
local HOVER = Color3.fromRGB(34, 34, 40)
local OUTLINE = Color3.fromRGB(42, 42, 50)
local ACCENT = Color3.fromRGB(0, 255, 120)
local TEXT = Color3.fromRGB(235, 235, 235)
local DIM = Color3.fromRGB(150, 150, 150)
local OFFC = Color3.fromRGB(60, 60, 66)

------------------------------------------------------------
-- helpers
------------------------------------------------------------
local function mk(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end
local function corner(o, r) mk("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function stroke(o, c, t) return mk("UIStroke", {Color = c or ACCENT, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o) end
local function tw(o, p, t)
	TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local function guiParent()
	local ok, res = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
	if ok and res then return res end
	return lp:WaitForChild("PlayerGui")
end

pcall(function()
	local old = guiParent():FindFirstChild("V3R4X_B01")
	if old then old:Destroy() end
end)

------------------------------------------------------------
-- splash: "Made in V3R4X_B01"
------------------------------------------------------------
do
	local g = mk("ScreenGui", {Name = "V3R4X_B01_Splash", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, guiParent())
	local bg = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0}, g)
	local lbl = mk("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 420, 0, 60), BackgroundTransparency = 1, Text = "Made in V3R4X_B01", TextColor3 = ACCENT, Font = Enum.Font.GothamBlack, TextSize = 30, TextTransparency = 1}, bg)
	local st = mk("UIStroke", {Color = ACCENT, Thickness = 1, Transparency = 1}, lbl)
	tw(bg, {BackgroundTransparency = 0.35}, 0.4)
	tw(lbl, {TextTransparency = 0}, 0.5)
	tw(st, {Transparency = 0.6}, 0.5)
	task.wait(2)
	tw(lbl, {TextTransparency = 1}, 0.4)
	tw(st, {Transparency = 1}, 0.4)
	tw(bg, {BackgroundTransparency = 1}, 0.5)
	task.wait(0.55)
	g:Destroy()
end

local toast = function() end
local function safe(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[V3R4X_B01] " .. tostring(err))
		toast("Feature error (see console)")
	end
end

------------------------------------------------------------
-- state
------------------------------------------------------------
local State = {
	speedOn = false, speed = 50, jumpOn = false, jump = 100,
	fly = false, flySpeed = 60, noclip = false, infjump = false, spin = false,
	bhop = false, slowfall = false, airwalk = false, freeze = false, deathback = false,
	gravOn = false, gravity = 100, fovOn = false, fov = 90, camunlock = false,
	fullbright = false, nofog = false, timeOn = false, time = 12,
	esp = false, spectate = false, orbit = false, follow = false, headsit = false, backpack = false,
	orbitRadius = 8, orbitSpeed = 3, target = nil,
	aimbot = false, aimFov = 250, aimSmooth = 4, aimHead = true, aimWall = true, aimTeam = false, aimHold = false,
	npckill = false, npcRange = 150,
	ring = false, ringRadius = 20, ringSpeed = 4, ringHeight = 3, ringMax = 120, ringRange = 150,
	ctrlclick = false, antiafk = false, antikick = false, antifling = false,
	antivoid = false, autoclick = false, cps = 10, autorejoin = false,
	emoteLoop = true, emoteStopMove = true, emoteSpeed = 10,
	fightEffects = true, autocombo = false, comboDelay = 3,
}
local base = {speed = 16, jump = 50, usejp = true}
local origGravity = workspace.Gravity
local origCam = {zoom = lp.CameraMaxZoomDistance, occ = lp.DevCameraOcclusionMode}
local origLight = {
	Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
}
local conns = {}
local alive = true
local savedCF, specTarget, lastSafe, lastAlivePos = nil, nil, nil, nil
local T, S = {}, {} -- toggle / slider registries (used by command bar)

local function getChar() return lp.Character end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function aliveRoot(p)
	local c = p and p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if h and r and h.Health > 0 then return r, h end
end
local function findPlayer(name)
	name = (name or ""):lower()
	if name == "" then return nil end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and (p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name) then
			return p
		end
	end
end
local function nearestPlayer()
	local me = getRoot()
	if not me then return end
	local bp, bd = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			local r = aliveRoot(p)
			if r then
				local d = (r.Position - me.Position).Magnitude
				if d < bd then bd, bp = d, p end
			end
		end
	end
	return bp
end

local function raycastFrom(x, y)
	local cam = workspace.CurrentCamera
	local ray = cam:ViewportPointToRay(x, y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {getChar()}
	return workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
end

local function SendChatMessage(message)
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if ch then ch:SendAsync(message) end
	else
		local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		local say = ev and ev:FindFirstChild("SayMessageRequest")
		if say then say:FireServer(message, "All") end
	end
end

-- try to claim physics ownership of nearby parts (needed for NPC kill / super ring)
local function claimNetwork()
	pcall(function() sethiddenproperty(lp, "SimulationRadius", math.huge) end)
	pcall(function() lp.MaximumSimulationRadius = math.huge end)
end

------------------------------------------------------------
-- emotes + fighter animations (played on your own Animator = seen by everyone)
------------------------------------------------------------
local EMOTE_LIST = {
	{"Wave", "wave"}, {"Point", "point"}, {"Cheer", "cheer"}, {"Laugh", "laugh"},
	{"Dance", "dance"}, {"Dance 2", "dance2"}, {"Dance 3", "dance3"},
	{"Salute (R15)", "salute"}, {"Stadium (R15)", "stadium"}, {"Tilt (R15)", "tilt"},
	{"Shrug (R15)", "shrug"}, {"Hello (R15)", "hello"},
}
local EMOTE_IDS_R15 = {
	wave = 507770239, point = 507770453, cheer = 507770677, laugh = 507770818,
	dance = 507771019, dance2 = 507776043, dance3 = 507777268,
	salute = 3333432454, stadium = 3333136415, tilt = 3334538554, shrug = 3334392772, hello = 3576686446,
}
local EMOTE_IDS_R6 = {
	wave = 128777973, point = 128853357, cheer = 129423030, laugh = 129423131,
	dance = 182435998, dance2 = 182436842, dance3 = 182436935,
}
-- Roblox's own tool/sword animations (work for everyone, no permission problems)
local FIGHT_R15 = {slash = 522635514, lunge = 522638767, hold = 507768375}
local FIGHT_R6 = {slash = 129967390, lunge = 129967478, hold = 182393478}

local emoteTrack, emoteFight = nil, false
local function stopEmote()
	if emoteTrack then
		pcall(function() emoteTrack:Stop() end)
		emoteTrack = nil
	end
	emoteFight = false
end

local function playAnimId(id, loop, fight)
	local h = getHum()
	if not h then return false end
	local animator = h:FindFirstChildOfClass("Animator")
	if not animator then return false end
	stopEmote()
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok or not track then return false end
	local t0 = tick()
	while track.Length == 0 and tick() - t0 < 1 do task.wait() end
	if track.Length == 0 then
		pcall(function() track:Stop() end)
		return false
	end
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = loop
	track:Play()
	track:AdjustSpeed(State.emoteSpeed / 10)
	emoteTrack = track
	emoteFight = fight and true or false
	return true
end

local function playDefaultEmote(name)
	local h = getHum()
	if not h then return false end
	stopEmote()
	local ok, res = pcall(function() return h:PlayEmote(name) end)
	if ok and res then return true end
	local ids = (h.RigType == Enum.HumanoidRigType.R15) and EMOTE_IDS_R15 or EMOTE_IDS_R6
	if ids[name] then return playAnimId(ids[name], State.emoteLoop) end
	return false
end

-- attack ring effect (local, visual only)
local function attackEffect()
	if not State.fightEffects then return end
	local r = getRoot()
	if not r then return end
	local ring = mk("Part", {Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 4, 4), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Material = Enum.Material.Neon, Color = ACCENT, Transparency = 0.2, CFrame = CFrame.new(r.Position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.rad(90))}, workspace)
	tw(ring, {Size = Vector3.new(0.2, 16, 16), Transparency = 1}, 0.45)
	task.delay(0.5, function() ring:Destroy() end)
end

local function playFight(kind)
	local h = getHum()
	if not h then return false end
	local ids = (h.RigType == Enum.HumanoidRigType.R15) and FIGHT_R15 or FIGHT_R6
	local id = ids[kind]
	if not id then return false end
	local ok = playAnimId(id, kind == "hold", true)
	if ok and kind ~= "hold" then attackEffect() end
	return ok
end

local function doCombo()
	for _, k in ipairs({"slash", "slash", "lunge"}) do
		if not playFight(k) then return end
		local len = emoteTrack and emoteTrack.Length or 0.5
		task.wait(math.max(len / (State.emoteSpeed / 10), 0.2) + State.comboDelay / 10)
	end
end

task.spawn(function()
	while alive do
		if State.autocombo then
			pcall(doCombo)
			task.wait(0.1)
		else
			task.wait(0.2)
		end
	end
end)

local SAVE_FILE = "V3R4X_B01_emotes.json"
local saved = {}
pcall(function()
	if isfile and isfile(SAVE_FILE) then saved = HttpService:JSONDecode(readfile(SAVE_FILE)) end
end)
if type(saved) ~= "table" then saved = {} end
local function persist()
	pcall(function()
		if writefile then writefile(SAVE_FILE, HttpService:JSONEncode(saved)) end
	end)
end

------------------------------------------------------------
-- super ring (pull loose parts and orbit them around you)
------------------------------------------------------------
local ringParts, ringOrig, ringAngle = {}, {}, 0
local function restoreRing()
	for p, c in pairs(ringOrig) do
		if p and p.Parent then pcall(function() p.CanCollide = c end) end
	end
	ringOrig, ringParts = {}, {}
end
local airPart -- declared early so the ring can skip it
local function rebuildRing()
	local me = getRoot()
	if not me then ringParts = {} return end
	claimNetwork()
	local list, n = {}, 0
	local myChar = getChar()
	for _, d in ipairs(workspace:GetDescendants()) do
		n = n + 1
		if n % 400 == 0 then task.wait() end
		if d:IsA("BasePart") and not d.Anchored and d ~= airPart and not d:IsDescendantOf(myChar) then
			local m = d:FindFirstAncestorOfClass("Model")
			if not (m and m:FindFirstChildOfClass("Humanoid")) and not d:FindFirstAncestorOfClass("Tool") then
				if d.Size.Magnitude < 30 and (d.Position - me.Position).Magnitude <= State.ringRange then
					if ringOrig[d] == nil then ringOrig[d] = d.CanCollide end
					list[#list + 1] = d
					if #list >= State.ringMax then break end
				end
			end
		end
	end
	ringParts = list
end
task.spawn(function()
	while alive do
		if State.ring then
			pcall(rebuildRing)
			task.wait(1.5)
		else
			if next(ringOrig) then restoreRing() end
			task.wait(0.5)
		end
	end
end)

------------------------------------------------------------
-- NPC tools (physics method: needs network ownership of the NPC; NPCs only)
------------------------------------------------------------
local function forEachNpc(range, fn)
	claimNetwork()
	local me = getRoot()
	if not me then return 0 end
	local count, n = 0, 0
	for _, d in ipairs(workspace:GetDescendants()) do
		n = n + 1
		if n % 400 == 0 then task.wait() end
		if d:IsA("Humanoid") and d.Health > 0 then
			local m = d.Parent
			if m and m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
				local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
				if r and (r.Position - me.Position).Magnitude <= range then
					pcall(fn, d, r)
					count = count + 1
				end
			end
		end
	end
	return count
end
local function killNpcs(range, silent)
	local c = forEachNpc(range, function(h, r)
		h.Health = 0
		h:ChangeState(Enum.HumanoidStateType.Dead)
		r.CFrame = CFrame.new(r.Position.X, workspace.FallenPartsDestroyHeight - 50, r.Position.Z)
	end)
	if not silent then toast("Sent " .. c .. " NPC(s) to the void") end
	return c
end
local function launchNpcs(range)
	local c = forEachNpc(range, function(h, r)
		r.AssemblyLinearVelocity = Vector3.new(math.random(-120, 120), 250, math.random(-120, 120))
	end)
	toast("Launched " .. c .. " NPC(s)")
end
task.spawn(function()
	while alive do
		if State.npckill then
			pcall(killNpcs, State.npcRange, true)
			task.wait(1.5)
		else
			task.wait(0.4)
		end
	end
end)

------------------------------------------------------------
-- feature logic
------------------------------------------------------------
local function restoreLight()
	for k, v in pairs(origLight) do pcall(function() Lighting[k] = v end) end
end

-- air walk platform (local only)
local airY
local function airWalkOn()
	local r = getRoot()
	if not r then return false end
	airY = r.Position.Y - 3.5
	airPart = mk("Part", {Size = Vector3.new(10, 1, 10), Anchored = true, Transparency = 1, CanCollide = true, CFrame = CFrame.new(r.Position.X, airY, r.Position.Z)}, workspace)
	return true
end
local function airWalkOff()
	if airPart then airPart:Destroy() airPart = nil end
end

-- Heartbeat
conns[#conns + 1] = RunService.Heartbeat:Connect(function(dt)
	local h, r = getHum(), getRoot()
	if h then
		if State.speedOn then h.WalkSpeed = State.speed end
		if State.jumpOn then h.UseJumpPower = true h.JumpPower = State.jump end
		if State.bhop and h.MoveDirection.Magnitude > 0 and h.FloorMaterial ~= Enum.Material.Air then
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		if State.emoteStopMove and emoteTrack and not emoteFight and h.MoveDirection.Magnitude > 0 then stopEmote() end
		if h.Health > 0 and r then lastAlivePos = r.CFrame end
	end
	if State.gravOn then workspace.Gravity = State.gravity end
	if State.fullbright then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(178, 178, 178)
		Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
	end
	if State.nofog then Lighting.FogEnd = 9e9 end
	if State.timeOn and not State.fullbright then Lighting.ClockTime = State.time end
	if r then
		if State.spin then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(720 * dt), 0) end
		if State.slowfall and not State.fly then
			local v = r.AssemblyLinearVelocity
			if v.Y < -25 then r.AssemblyLinearVelocity = Vector3.new(v.X, -25, v.Z) end
		end
		if State.airwalk and airPart then
			airPart.CFrame = CFrame.new(r.Position.X, airY, r.Position.Z)
		end
		if State.ring and #ringParts > 0 then
			ringAngle = ringAngle + State.ringSpeed * dt
			local count = #ringParts
			for i, p in ipairs(ringParts) do
				if p.Parent and not p.Anchored then
					local a = ringAngle + i * (2 * math.pi / count)
					local goal = r.Position + Vector3.new(math.cos(a) * State.ringRadius, State.ringHeight, math.sin(a) * State.ringRadius)
					local v = (goal - p.Position) * 12
					if v.Magnitude > 250 then v = v.Unit * 250 end
					p.CanCollide = false
					p.AssemblyLinearVelocity = v
					p.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
	end
	if State.camunlock then
		lp.CameraMaxZoomDistance = 9999
		lp.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	end
end)

-- return to death spot
conns[#conns + 1] = lp.CharacterAdded:Connect(function(c)
	if State.deathback and lastAlivePos then
		local cf = lastAlivePos
		local nr = c:WaitForChild("HumanoidRootPart", 5)
		if nr then
			task.wait(0.2)
			nr.CFrame = cf
		end
	end
end)

-- RenderStepped: fly, fov, spectate, orbit / follow / headsit / backpack
local flyBV, flyBG
local function stopFly()
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
	local h = getHum()
	if h then h.PlatformStand = false end
end
local orbitAngle = 0
conns[#conns + 1] = RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if State.fovOn then cam.FieldOfView = State.fov end
	if State.spectate then
		local _, h = aliveRoot(specTarget)
		if h then cam.CameraSubject = h end
	end
	local root, hum = getRoot(), getHum()
	if State.fly and root and hum then
		if not flyBV or flyBV.Parent ~= root then
			if flyBV then flyBV:Destroy() end
			flyBV = mk("BodyVelocity", {MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.zero}, root)
		end
		if not flyBG or flyBG.Parent ~= root then
			if flyBG then flyBG:Destroy() end
			flyBG = mk("BodyGyro", {MaxTorque = Vector3.new(9e9, 9e9, 9e9), P = 9e4}, root)
		end
		local lm = cam.CFrame:VectorToObjectSpace(hum.MoveDirection)
		local vec = cam.CFrame.LookVector * (-lm.Z) + cam.CFrame.RightVector * lm.X
		flyBV.Velocity = vec * State.flySpeed
		flyBG.CFrame = cam.CFrame
		hum.PlatformStand = true
	end
	if root and State.target and (State.orbit or State.follow or State.headsit or State.backpack) then
		local tr = aliveRoot(State.target)
		if tr then
			if State.orbit then
				orbitAngle = orbitAngle + State.orbitSpeed * dt
				local pos = tr.Position + Vector3.new(math.cos(orbitAngle) * State.orbitRadius, 0, math.sin(orbitAngle) * State.orbitRadius)
				root.CFrame = CFrame.lookAt(pos, Vector3.new(tr.Position.X, pos.Y, tr.Position.Z))
				root.AssemblyLinearVelocity = Vector3.zero
			elseif State.follow then
				local pos = tr.Position - tr.CFrame.LookVector * 4
				root.CFrame = CFrame.lookAt(pos, Vector3.new(tr.Position.X, pos.Y, tr.Position.Z))
				root.AssemblyLinearVelocity = Vector3.zero
			elseif State.headsit then
				local head = State.target.Character and State.target.Character:FindFirstChild("Head")
				if head then
					root.CFrame = head.CFrame * CFrame.new(0, 1.8, 0)
					root.AssemblyLinearVelocity = Vector3.zero
					if hum then hum.Sit = true end
				end
			elseif State.backpack then
				root.CFrame = tr.CFrame * CFrame.new(0, 0.2, 1.3)
				root.AssemblyLinearVelocity = Vector3.zero
				if hum then hum.Sit = true end
			end
		end
	end
end)

-- aimbot (camera lock on players)
local function aimTarget()
	local cam = workspace.CurrentCamera
	local center = cam.ViewportSize / 2
	local bestPart, bestDist = nil, State.aimFov
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and p.Character then
			local r = aliveRoot(p)
			local teamOk = not (State.aimTeam and p.Team and p.Team == lp.Team)
			if r and teamOk then
				local part = (State.aimHead and p.Character:FindFirstChild("Head")) or r
				local sp, onScreen = cam:WorldToViewportPoint(part.Position)
				if onScreen then
					local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
					if d < bestDist then
						local visible = true
						if State.aimWall then
							local params = RaycastParams.new()
							params.FilterType = Enum.RaycastFilterType.Exclude
							params.FilterDescendantsInstances = {getChar(), p.Character}
							local hit = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
							visible = (hit == nil)
						end
						if visible then bestPart, bestDist = part, d end
					end
				end
			end
		end
	end
	return bestPart
end
pcall(function() RunService:UnbindFromRenderStep("V3R4X_AIM") end)
RunService:BindToRenderStep("V3R4X_AIM", Enum.RenderPriority.Camera.Value + 1, function()
	if not State.aimbot then return end
	if State.aimHold and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
	local part = aimTarget()
	if not part then return end
	local cam = workspace.CurrentCamera
	local goal = CFrame.lookAt(cam.CFrame.Position, part.Position)
	cam.CFrame = cam.CFrame:Lerp(goal, 1 / math.max(State.aimSmooth, 1))
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
		local r = getRoot()
		if r and not State.fly then
			if r.AssemblyAngularVelocity.Magnitude > 50 then r.AssemblyAngularVelocity = Vector3.zero end
			if r.AssemblyLinearVelocity.Magnitude > 120 then r.AssemblyLinearVelocity = Vector3.zero end
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

-- auto rejoin when kicked / disconnected
conns[#conns + 1] = GuiService.ErrorMessageChanged:Connect(function()
	if State.autorejoin then
		task.wait(2)
		TeleportService:Teleport(game.PlaceId, lp)
	end
end)

-- ctrl + click teleport (PC)
conns[#conns + 1] = UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if State.ctrlclick and i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		local m = UIS:GetMouseLocation()
		local hit = raycastFrom(m.X, m.Y)
		local r = getRoot()
		if hit and r then r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) * (r.CFrame - r.CFrame.Position) end
	end
end)

-- anti-void + last safe position
task.spawn(function()
	while alive do
		local r, h = getRoot(), getHum()
		if r and h then
			local limit = workspace.FallenPartsDestroyHeight
			if h.FloorMaterial ~= Enum.Material.Air and r.Position.Y > limit + 100 then lastSafe = r.CFrame end
			if State.antivoid and lastSafe and r.Position.Y < limit + 60 then
				r.CFrame = lastSafe + Vector3.new(0, 4, 0)
				r.AssemblyLinearVelocity = Vector3.zero
			end
		end
		task.wait(0.15)
	end
end)

-- auto clicker
task.spawn(function()
	while alive do
		if State.autoclick then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton1(Vector2.new(0, 0))
			end)
			task.wait(1 / math.max(State.cps, 1))
		else
			task.wait(0.2)
		end
	end
end)

-- anti-kick (client side, needs hookmetamethod)
local kickHooked = false
local function hookKick()
	if kickHooked then return true end
	local ok = pcall(function()
		local old
		old = hookmetamethod(game, "__namecall", function(self, ...)
			if State.antikick and self == lp and getnamecallmethod():lower() == "kick" then return end
			return old(self, ...)
		end)
	end)
	if ok then kickHooked = true end
	return ok
end

-- esp
local espObjs, espInfo = {}, {}
local function clearEsp()
	for p, o in pairs(espObjs) do
		for _, x in ipairs(o) do pcall(function() x:Destroy() end) end
		espObjs[p], espInfo[p] = nil, nil
	end
end
local function addEsp(p)
	local c = p.Character
	if not c then return end
	local list = {mk("Highlight", {FillColor = ACCENT, OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.6, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, c)}
	local head = c:FindFirstChild("Head")
	if head then
		local bb = mk("BillboardGui", {Size = UDim2.new(0, 130, 0, 32), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true}, head)
		local lbl = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = p.DisplayName, TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextScaled = true}, bb)
		local bar = mk("Frame", {Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 22), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, bb)
		local fill = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = ACCENT, BorderSizePixel = 0}, bar)
		list[2] = bb
		espInfo[p] = {fill = fill, label = lbl}
	end
	espObjs[p] = list
end
task.spawn(function()
	while alive do
		if State.esp then
			local me = getRoot()
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= lp and p.Character then
					local o = espObjs[p]
					if not o or not o[1] or o[1].Parent ~= p.Character then
						if o then for _, x in ipairs(o) do pcall(function() x:Destroy() end) end end
						espInfo[p] = nil
						addEsp(p)
					end
					local info, h, r = espInfo[p], p.Character:FindFirstChildOfClass("Humanoid"), p.Character:FindFirstChild("HumanoidRootPart")
					if info and h then
						local f = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
						info.fill.Size = UDim2.new(f, 0, 1, 0)
						info.fill.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - f)), math.floor(255 * f), 60)
						local dist = (me and r) and math.floor((me.Position - r.Position).Magnitude) or 0
						info.label.Text = p.DisplayName .. " [" .. math.floor(h.Health) .. "] " .. dist .. "m"
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

-- fps boost
local function fpsBoost()
	task.spawn(function()
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
		pcall(function()
			Lighting.GlobalShadows = false
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
				if v:IsA("BasePart") then v.Material = Enum.Material.Plastic v.Reflectance = 0
				elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
				elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false end
			end)
			n = n + 1
			if n % 500 == 0 then task.wait() end
		end
		toast("FPS boost applied")
	end)
end

-- server tools
local function rejoin()
	if #Players:GetPlayers() <= 1 then
		TeleportService:Teleport(game.PlaceId, lp)
	else
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
	end
end
local function serverHop()
	task.spawn(function()
		local ok, found = pcall(function()
			local data = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
			for _, s in ipairs(data.data) do
				if s.id ~= game.JobId and s.playing < s.maxPlayers then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, lp)
					return true
				end
			end
		end)
		if not (ok and found) then toast("No server found") end
	end)
end

-- teleport helpers
local function tpToPlayer(p)
	local r, me = p and aliveRoot(p), getRoot()
	if r and me then me.CFrame = r.CFrame * CFrame.new(0, 0, 3) else toast("Player not found") end
end
local function tpSpawn()
	local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local me = getRoot()
	if sp and me then me.CFrame = sp.CFrame + Vector3.new(0, 5, 0) else toast("No spawn found") end
end
local function tpCrosshair()
	local r = getRoot()
	if not r then return end
	local c = workspace.CurrentCamera.ViewportSize / 2
	local hit = raycastFrom(c.X, c.Y)
	if hit then
		r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) * (r.CFrame - r.CFrame.Position)
	else
		toast("No surface found")
	end
end
local function dash()
	local r = getRoot()
	if not r then return end
	local look = workspace.CurrentCamera.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude > 0 then
		r.AssemblyLinearVelocity = flat.Unit * 130 + Vector3.new(0, 25, 0)
	end
end
local function respawnHere()
	local r, h = getRoot(), getHum()
	if not (r and h) then return end
	local cf = r.CFrame
	h.Health = 0
	local c = lp.CharacterAdded:Wait()
	local nr = c:WaitForChild("HumanoidRootPart", 5)
	if nr then
		task.wait(0.15)
		nr.CFrame = cf
	end
end
local function startSpectate(p)
	if p and aliveRoot(p) then
		specTarget = p
		State.spectate = true
		toast("Spectating " .. p.DisplayName)
	else
		toast("Player not found")
	end
end
local function stopSpectate()
	State.spectate = false
	local h = getHum()
	if h then workspace.CurrentCamera.CameraSubject = h end
end

-- R15 -> R6 (client side)
local function toR6()
	local char, hum, root = getChar(), getHum(), getRoot()
	if not (char and hum and root) then toast("No character found") return end
	if hum.RigType == Enum.HumanoidRigType.R6 then toast("You are already R6") return end
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
	if ok then toast("R6 applied") else warn(err) toast("R6 failed") end
end

------------------------------------------------------------
-- UI
------------------------------------------------------------
local sg = mk("ScreenGui", {Name = "V3R4X_B01", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, guiParent())

toast = function(msg)
	task.spawn(function()
		local t = mk("TextLabel", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.new(0, 280, 0, 30), BackgroundColor3 = PANEL, BackgroundTransparency = 1, Text = msg, TextColor3 = ACCENT, TextTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 50}, sg)
		corner(t, 8)
		local ts = stroke(t, ACCENT, 1)
		ts.Transparency = 1
		tw(t, {BackgroundTransparency = 0.1, TextTransparency = 0}, 0.2)
		tw(ts, {Transparency = 0.5}, 0.2)
		task.wait(2)
		tw(t, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
		tw(ts, {Transparency = 1}, 0.3)
		task.wait(0.35)
		t:Destroy()
	end)
end

local function makeDraggable(handle, target)
	local dragging, startPos, startFrame, moved = false, nil, nil, false
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			startPos, startFrame = i.Position, target.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startPos
			if d.Magnitude > 6 then moved = true end
			target.Position = UDim2.new(startFrame.X.Scale, startFrame.X.Offset + d.X, startFrame.Y.Scale, startFrame.Y.Offset + d.Y)
		end
	end)
	return function() return moved end
end

local main = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = BG, BorderSizePixel = 0, ClipsDescendants = true}, sg)
corner(main, 14)
mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(20, 20, 25), Color3.fromRGB(8, 8, 10)), Rotation = 90}, main)
local mainStroke = stroke(main, ACCENT, 2)
local strokeGrad = mk("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, ACCENT), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 150, 255)), ColorSequenceKeypoint.new(1, ACCENT)}), Rotation = 45}, mainStroke)
tw(main, {Size = UDim2.new(0, 480, 0, 330)}, 0.4)

-- animated border
conns[#conns + 1] = RunService.RenderStepped:Connect(function()
	strokeGrad.Rotation = (tick() * 45) % 360
end)

local titleBar = mk("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Color3.fromRGB(8, 8, 10), BackgroundTransparency = 0.2, BorderSizePixel = 0}, main)
mk("TextLabel", {Size = UDim2.new(0, 160, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = "V3R4X_B01  <font color='#00ff78'>V3.5</font>", RichText = true, TextColor3 = TEXT, Font = Enum.Font.GothamBlack, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left}, titleBar)
mk("TextLabel", {Size = UDim2.new(0, 160, 1, 0), Position = UDim2.new(0, 170, 0, 0), BackgroundTransparency = 1, Text = "universal hub", TextColor3 = DIM, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, titleBar)
mk("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.75, BorderSizePixel = 0}, titleBar)
local minBtn = mk("TextButton", {Size = UDim2.new(0, 28, 0, 24), Position = UDim2.new(1, -70, 0, 7), BackgroundColor3 = PANEL, Text = "-", TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 18}, titleBar)
local xBtn = mk("TextButton", {Size = UDim2.new(0, 28, 0, 24), Position = UDim2.new(1, -38, 0, 7), BackgroundColor3 = PANEL, Text = "X", TextColor3 = Color3.fromRGB(255, 90, 90), Font = Enum.Font.GothamBold, TextSize = 14}, titleBar)
corner(minBtn, 6) corner(xBtn, 6)
makeDraggable(titleBar, main)

local sidebar = mk("ScrollingFrame", {Position = UDim2.new(0, 8, 0, 46), Size = UDim2.new(0, 100, 1, -74), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y}, main)
mk("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
local content = mk("Frame", {Position = UDim2.new(0, 116, 0, 46), Size = UDim2.new(1, -124, 1, -74), BackgroundTransparency = 1}, main)

local function newPage()
	local s = mk("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, content)
	mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, s)
	mk("UIPadding", {PaddingRight = UDim.new(0, 5)}, s)
	return s
end

local pages, tabBtns, tabBars = {}, {}, {}
local tabNames = {"PLAYER", "WORLD", "PLAYERS", "COMBAT", "FIGHT", "EMOTES", "EXECUTOR", "UTILITY", "CMDS", "INFO"}
local function selectTab(name)
	for n, p in pairs(pages) do
		local show = (n == name)
		if show and not p.Visible then
			p.Position = UDim2.new(0, 14, 0, 0)
			tw(p, {Position = UDim2.new(0, 0, 0, 0)}, 0.2)
		end
		p.Visible = show
		tw(tabBtns[n], {BackgroundColor3 = show and Color3.fromRGB(0, 60, 36) or PANEL})
		tw(tabBars[n], {Size = UDim2.new(0, 3, 0, show and 16 or 0)}, 0.15)
		tabBtns[n].TextColor3 = show and ACCENT or DIM
	end
end
for i, name in ipairs(tabNames) do
	local b = mk("TextButton", {Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = PANEL, Text = name, TextColor3 = DIM, Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i}, sidebar)
	corner(b, 8)
	mk("UIPadding", {PaddingLeft = UDim.new(0, 14)}, b)
	local bar = mk("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -10, 0.5, 0), Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = ACCENT, BorderSizePixel = 0}, b)
	corner(bar, 2)
	tabBtns[name], tabBars[name] = b, bar
	pages[name] = newPage()
	b.MouseButton1Click:Connect(function() selectTab(name) end)
end

-- widgets
local function section(parent, text)
	local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1}, parent)
	mk("TextLabel", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = text, TextColor3 = ACCENT, Font = Enum.Font.GothamBlack, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, f)
	mk("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.75, BorderSizePixel = 0}, f)
end

local function button(parent, text, cb)
	local b = mk("TextButton", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = PANEL, Text = text, TextColor3 = TEXT, Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = false}, parent)
	corner(b, 8)
	local bs = stroke(b, OUTLINE, 1)
	b.MouseEnter:Connect(function() tw(b, {BackgroundColor3 = HOVER}, 0.1) tw(bs, {Color = ACCENT}, 0.1) end)
	b.MouseLeave:Connect(function() tw(b, {BackgroundColor3 = PANEL}, 0.1) tw(bs, {Color = OUTLINE}, 0.1) end)
	b.MouseButton1Click:Connect(function()
		tw(b, {BackgroundColor3 = Color3.fromRGB(0, 70, 40)}, 0.08)
		task.delay(0.12, function() tw(b, {BackgroundColor3 = PANEL}, 0.15) end)
		safe(cb, b)
	end)
	return b
end

local function toggle(parent, text, cb, default, key)
	local on = default or false
	local row = mk("TextButton", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = PANEL, Text = "", AutoButtonColor = false}, parent)
	corner(row, 8)
	local rs = stroke(row, on and ACCENT or OUTLINE, 1)
	mk("TextLabel", {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = TEXT, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, row)
	local sw = mk("Frame", {Size = UDim2.new(0, 38, 0, 18), Position = UDim2.new(1, -48, 0.5, -9), BackgroundColor3 = on and ACCENT or OFFC, BorderSizePixel = 0}, row)
	corner(sw, 9)
	local knob = mk("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, sw)
	corner(knob, 7)
	local ctl = {}
	local function set(v)
		on = v
		tw(sw, {BackgroundColor3 = on and ACCENT or OFFC})
		tw(knob, {Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
		tw(rs, {Color = on and ACCENT or OUTLINE})
		safe(cb, v)
	end
	ctl.Set = set
	ctl.Get = function() return on end
	row.MouseButton1Click:Connect(function() set(not on) end)
	row.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = HOVER}, 0.1) end)
	row.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = PANEL}, 0.1) end)
	if on then safe(cb, true) end
	if key then T[key] = ctl end
	return ctl
end

local function slider(parent, text, min, max, default, cb, key)
	local row = mk("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = PANEL, BorderSizePixel = 0}, parent)
	corner(row, 8)
	stroke(row, OUTLINE, 1)
	mk("TextLabel", {Size = UDim2.new(1, -70, 0, 20), Position = UDim2.new(0, 10, 0, 4), BackgroundTransparency = 1, Text = text, TextColor3 = TEXT, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, row)
	local val = mk("TextLabel", {Size = UDim2.new(0, 60, 0, 20), Position = UDim2.new(1, -70, 0, 4), BackgroundTransparency = 1, Text = tostring(default), TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right}, row)
	local bar = mk("Frame", {Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 33), BackgroundColor3 = OFFC, BorderSizePixel = 0}, row)
	corner(bar, 3)
	local a0 = (default - min) / (max - min)
	local fill = mk("Frame", {Size = UDim2.new(a0, 0, 1, 0), BackgroundColor3 = ACCENT, BorderSizePixel = 0}, bar)
	corner(fill, 3)
	mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(0, 150, 255), ACCENT)}, fill)
	local knob = mk("Frame", {Size = UDim2.new(0, 14, 0, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(a0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, bar)
	corner(knob, 7)
	stroke(knob, ACCENT, 2)
	local function apply(v)
		v = math.clamp(math.floor(v + 0.5), min, max)
		local a = (v - min) / (max - min)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		val.Text = tostring(v)
		safe(cb, v)
	end
	local dragging = false
	local function setFrom(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		apply(min + (max - min) * a)
	end
	local hit = mk("TextButton", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 20), BackgroundTransparency = 1, Text = ""}, row)
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			pcall(function() parent.ScrollingEnabled = false end)
			setFrom(i.Position.X)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			setFrom(i.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			pcall(function() parent.ScrollingEnabled = true end)
		end
	end)
	local ctl = {Set = apply}
	if key then S[key] = ctl end
	return ctl
end

local function textbox(parent, placeholder)
	local tb = mk("TextBox", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = PANEL, Text = "", PlaceholderText = placeholder, PlaceholderColor3 = DIM, TextColor3 = ACCENT, Font = Enum.Font.GothamMedium, TextSize = 13, ClearTextOnFocus = false}, parent)
	corner(tb, 8)
	local ts = stroke(tb, OUTLINE, 1)
	tb.Focused:Connect(function() tw(ts, {Color = ACCENT}, 0.1) end)
	tb.FocusLost:Connect(function() tw(ts, {Color = OUTLINE}, 0.1) end)
	return tb
end

local function infoLabel(parent)
	local l = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = PANEL, Text = "", TextColor3 = TEXT, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, parent)
	corner(l, 8)
	stroke(l, OUTLINE, 1)
	mk("UIPadding", {PaddingLeft = UDim.new(0, 10)}, l)
	return l
end

------------------------------------------------------------
-- PLAYER page
------------------------------------------------------------
local P = pages.PLAYER
section(P, "MOVEMENT")
toggle(P, "Custom Speed", function(v)
	State.speedOn = v
	local h = getHum()
	if v then if h then base.speed = h.WalkSpeed end elseif h then h.WalkSpeed = base.speed end
end, false, "speed")
slider(P, "Walk Speed", 16, 300, 50, function(v) State.speed = v end, "speedS")
toggle(P, "Custom Jump", function(v)
	State.jumpOn = v
	local h = getHum()
	if v then
		if h then base.jump, base.usejp = h.JumpPower, h.UseJumpPower end
	elseif h then
		h.UseJumpPower = base.usejp
		h.JumpPower = base.jump
	end
end, false, "jump")
slider(P, "Jump Power", 50, 300, 100, function(v) State.jump = v end, "jumpS")
toggle(P, "Fly", function(v)
	State.fly = v
	if not v then stopFly() end
end, false, "fly")
slider(P, "Fly Speed", 10, 300, 60, function(v) State.flySpeed = v end, "flyS")
toggle(P, "Noclip", function(v) State.noclip = v end, false, "noclip")
toggle(P, "Infinite Jump", function(v) State.infjump = v end, false, "infjump")
toggle(P, "Bunny Hop (auto jump)", function(v) State.bhop = v end, false, "bhop")
toggle(P, "Slow Fall (parachute)", function(v) State.slowfall = v end, false, "slowfall")
toggle(P, "Spin", function(v) State.spin = v end, false, "spin")
button(P, "Dash Forward", function() dash() end)
section(P, "AIR WALK")
toggle(P, "Air Walk (invisible platform)", function(v)
	if v then
		State.airwalk = airWalkOn()
		if not State.airwalk then toast("No character") end
	else
		State.airwalk = false
		airWalkOff()
	end
end, false, "airwalk")
button(P, "Air Walk Up", function() if airPart then airY = airY + 4 end end)
button(P, "Air Walk Down", function() if airPart then airY = airY - 4 end end)
section(P, "PHYSICS / CAMERA")
toggle(P, "Custom Gravity", function(v)
	State.gravOn = v
	if not v then workspace.Gravity = origGravity end
end, false, "gravity")
slider(P, "Gravity", 0, 400, 100, function(v) State.gravity = v end, "gravS")
toggle(P, "Custom FOV", function(v)
	State.fovOn = v
	if not v then workspace.CurrentCamera.FieldOfView = 70 end
end, false, "fov")
slider(P, "FOV", 30, 120, 90, function(v) State.fov = v end, "fovS")
toggle(P, "Camera Unlock (zoom + see through walls)", function(v)
	State.camunlock = v
	if not v then
		lp.CameraMaxZoomDistance = origCam.zoom
		lp.DevCameraOcclusionMode = origCam.occ
	end
end, false, "camunlock")
section(P, "CHARACTER")
toggle(P, "Freeze Character", function(v)
	State.freeze = v
	local r = getRoot()
	if r then r.Anchored = v end
end, false, "freeze")
toggle(P, "Return to Death Spot", function(v) State.deathback = v end, false, "deathback")
button(P, "Respawn Here (same spot)", function() respawnHere() end)
button(P, "Sit", function() local h = getHum() if h then h.Sit = true end end)
button(P, "Reset Character", function() local h = getHum() if h then h.Health = 0 end end)

------------------------------------------------------------
-- WORLD page
------------------------------------------------------------
local W = pages.WORLD
section(W, "LIGHTING")
toggle(W, "Fullbright", function(v)
	State.fullbright = v
	if not v then restoreLight() end
end, false, "fullbright")
toggle(W, "No Fog", function(v)
	State.nofog = v
	if not v then Lighting.FogEnd = origLight.FogEnd end
end, false, "nofog")
toggle(W, "Custom Time of Day", function(v)
	State.timeOn = v
	if not v then Lighting.ClockTime = origLight.ClockTime end
end, false, "time")
slider(W, "Time (0-24)", 0, 24, 12, function(v) State.time = v end, "timeS")
section(W, "WORLD")
toggle(W, "X-Ray", function(v) setXray(v) end, false, "xray")
button(W, "FPS Boost (Low Graphics)", function() fpsBoost() end)

------------------------------------------------------------
-- PLAYERS page
------------------------------------------------------------
local PL = pages.PLAYERS
section(PL, "TARGET PLAYER")
local nameBox = textbox(PL, "Player name (or part of it)")
button(PL, "Teleport to Player", function() tpToPlayer(findPlayer(nameBox.Text)) end)
button(PL, "Teleport to Nearest", function() tpToPlayer(nearestPlayer()) end)
button(PL, "Spectate Player", function() startSpectate(findPlayer(nameBox.Text)) end)
button(PL, "Stop Spectate", function() stopSpectate() end)
section(PL, "TRACKING")
toggle(PL, "ESP (name, health, distance)", function(v) State.esp = v end, false, "esp")

local modeToggles = {}
local function targetToggle(parent, text, stateKey)
	local ctl
	ctl = toggle(parent, text, function(v)
		if v then
			local p = findPlayer(nameBox.Text)
			if not p then
				toast("Player not found")
				State[stateKey] = false
				ctl.Set(false)
				return
			end
			State.target = p
			for k, c in pairs(modeToggles) do
				if k ~= stateKey and c.Get() then c.Set(false) end
			end
			State[stateKey] = true
		else
			State[stateKey] = false
			if stateKey == "headsit" or stateKey == "backpack" then
				local h = getHum()
				if h then h.Sit = false end
			end
		end
	end, false, stateKey)
	modeToggles[stateKey] = ctl
	return ctl
end

section(PL, "TARGET MODES")
targetToggle(PL, "Orbit Target Player", "orbit")
slider(PL, "Orbit Radius", 3, 40, 8, function(v) State.orbitRadius = v end, "orbitR")
slider(PL, "Orbit Speed", 1, 20, 3, function(v) State.orbitSpeed = v end, "orbitS")
targetToggle(PL, "Follow Target Player", "follow")
targetToggle(PL, "Head Sit on Target", "headsit")
targetToggle(PL, "Backpack on Target", "backpack")

section(PL, "TELEPORT")
toggle(PL, "Ctrl + Click Teleport (PC)", function(v) State.ctrlclick = v end, false, "ctrlclick")
button(PL, "Teleport to Screen Center", function() tpCrosshair() end)
button(PL, "Teleport to Spawn", function() tpSpawn() end)
button(PL, "Save Position", function()
	local r = getRoot()
	if r then savedCF = r.CFrame toast("Position saved") end
end)
button(PL, "Teleport to Saved", function()
	local r = getRoot()
	if r and savedCF then r.CFrame = savedCF else toast("Nothing saved") end
end)
section(PL, "PLAYER LIST (tap to select)")
local listFrame = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, PL)
mk("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)
local function refreshList()
	for _, c in ipairs(listFrame:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			local b = mk("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = PANEL, Text = p.DisplayName .. " (@" .. p.Name .. ")", TextColor3 = TEXT, Font = Enum.Font.Gotham, TextSize = 12, AutoButtonColor = false}, listFrame)
			corner(b, 6)
			stroke(b, OUTLINE, 1)
			b.MouseButton1Click:Connect(function()
				nameBox.Text = p.Name
				toast("Selected " .. p.DisplayName)
			end)
		end
	end
end
refreshList()
conns[#conns + 1] = Players.PlayerAdded:Connect(function() task.wait(0.5) refreshList() end)
conns[#conns + 1] = Players.PlayerRemoving:Connect(function() task.wait(0.2) refreshList() end)

------------------------------------------------------------
-- COMBAT page
------------------------------------------------------------
local CB = pages.COMBAT
section(CB, "AIMBOT (players)")
toggle(CB, "Aimbot", function(v) State.aimbot = v end, false, "aimbot")
slider(CB, "Aim FOV (pixels from center)", 50, 800, 250, function(v) State.aimFov = v end, "aimFovS")
slider(CB, "Smoothness (1 = instant)", 1, 20, 4, function(v) State.aimSmooth = v end, "aimSmoothS")
toggle(CB, "Aim at Head (off = body)", function(v) State.aimHead = v end, true, "aimhead")
toggle(CB, "Wall Check (visible only)", function(v) State.aimWall = v end, true, "aimwall")
toggle(CB, "Team Check", function(v) State.aimTeam = v end, false, "aimteam")
toggle(CB, "Hold Right Mouse to aim (PC)", function(v) State.aimHold = v end, false, "aimhold")
section(CB, "ORBIT")
local orbNear
orbNear = toggle(CB, "Orbit Nearest Player", function(v)
	if v then
		local p = nearestPlayer()
		if not p then toast("No player nearby") orbNear.Set(false) return end
		nameBox.Text = p.Name
		modeToggles.orbit.Set(true)
	else
		modeToggles.orbit.Set(false)
	end
end, false, "orbitnear")
section(CB, "NPC TOOLS (NPCs only)")
toggle(CB, "Auto Kill NPCs", function(v)
	State.npckill = v
	if v then claimNetwork() end
end, false, "autokill")
slider(CB, "NPC Range (studs)", 20, 500, 150, function(v) State.npcRange = v end, "npcRangeS")
button(CB, "Kill NPCs Now", function() killNpcs(State.npcRange, false) end)
button(CB, "Launch NPCs (fling NPCs)", function() launchNpcs(State.npcRange) end)
section(CB, "SUPER RING")
toggle(CB, "Super Ring (pull loose parts)", function(v)
	State.ring = v
	if v then claimNetwork() else restoreRing() end
end, false, "ring")
slider(CB, "Ring Radius", 5, 60, 20, function(v) State.ringRadius = v end, "ringRS")
slider(CB, "Ring Speed", 1, 20, 4, function(v) State.ringSpeed = v end, "ringSpS")
slider(CB, "Ring Height", -10, 30, 3, function(v) State.ringHeight = v end, "ringHS")
slider(CB, "Max Parts", 10, 300, 120, function(v) State.ringMax = v end, "ringMaxS")
slider(CB, "Pull Range (studs)", 20, 500, 150, function(v) State.ringRange = v end, "ringRangeS")

------------------------------------------------------------
-- FIGHT page
------------------------------------------------------------
local F = pages.FIGHT
section(F, "FIGHTER ANIMATIONS (seen by everyone)")
local lRig = infoLabel(F)
button(F, "Slash", function() if not playFight("slash") then toast("Animation failed") end end)
button(F, "Lunge", function() if not playFight("lunge") then toast("Animation failed") end end)
button(F, "Fight Stance (hold)", function() if not playFight("hold") then toast("Animation failed") end end)
button(F, "Combo (3 hits)", function() task.spawn(doCombo) end)
button(F, "Stop Animation", function() stopEmote() end)
section(F, "AUTO")
toggle(F, "Auto Combo", function(v)
	State.autocombo = v
	if not v then stopEmote() end
end, false, "autocombo")
slider(F, "Combo Delay (x0.1s)", 0, 20, 3, function(v) State.comboDelay = v end, "comboDelayS")
slider(F, "Animation Speed (10 = normal)", 1, 30, 10, function(v)
	State.emoteSpeed = v
	if emoteTrack then pcall(function() emoteTrack:AdjustSpeed(v / 10) end) end
end, "fightSpeedS")
toggle(F, "Attack Effects (visual ring)", function(v) State.fightEffects = v end, true, "fighteffects")
section(F, "CUSTOM FIGHTER ANIMATION ID")
local fightIdBox = textbox(F, "Fighter animation ID (R6 or R15)")
local function readFightId()
	local s = fightIdBox.Text:match("%d+")
	return s and tonumber(s)
end
button(F, "Play as Attack", function()
	local id = readFightId()
	if not id then toast("Enter an animation ID") return end
	if playAnimId(id, false, true) then attackEffect() else toast("Failed: wrong rig or not allowed") end
end)
button(F, "Play as Stance (loop)", function()
	local id = readFightId()
	if not id then toast("Enter an animation ID") return end
	if not playAnimId(id, true, true) then toast("Failed: wrong rig or not allowed") end
end)

------------------------------------------------------------
-- EMOTES page
------------------------------------------------------------
local E = pages.EMOTES
section(E, "ROBLOX EMOTES (seen by everyone)")
for _, e in ipairs(EMOTE_LIST) do
	button(E, e[1], function()
		if not playDefaultEmote(e[2]) then toast("Emote not supported here") end
	end)
end
section(E, "CONTROL")
button(E, "Stop Emote", function() stopEmote() end)
slider(E, "Animation Speed (10 = normal)", 1, 30, 10, function(v)
	State.emoteSpeed = v
	if emoteTrack then pcall(function() emoteTrack:AdjustSpeed(v / 10) end) end
end, "emoteSpeedS")
toggle(E, "Loop custom animation", function(v) State.emoteLoop = v end, true, "emoteloop")
toggle(E, "Stop emote when moving", function(v) State.emoteStopMove = v end, true, "emotemove")
section(E, "CUSTOM ANIMATION ID")
local idBox = textbox(E, "Animation ID (numbers)")
local saveNameBox = textbox(E, "Save as name (optional)")
local function readId()
	local s = idBox.Text:match("%d+")
	return s and tonumber(s)
end
button(E, "Play Custom ID", function()
	local id = readId()
	if not id then toast("Enter an animation ID") return end
	if not playAnimId(id, State.emoteLoop) then toast("Failed: wrong rig or not allowed") end
end)
local savedFrame = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, E)
mk("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, savedFrame)
local function refreshSaved()
	for _, c in ipairs(savedFrame:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for idx, item in ipairs(saved) do
		local row = mk("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = PANEL, BorderSizePixel = 0}, savedFrame)
		corner(row, 6)
		stroke(row, OUTLINE, 1)
		local play = mk("TextButton", {Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1, Text = "> " .. tostring(item.name), TextColor3 = TEXT, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
		mk("UIPadding", {PaddingLeft = UDim.new(0, 10)}, play)
		local del = mk("TextButton", {Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = "X", TextColor3 = Color3.fromRGB(255, 90, 90), Font = Enum.Font.GothamBold, TextSize = 12}, row)
		play.MouseButton1Click:Connect(function()
			safe(function()
				if not playAnimId(item.id, State.emoteLoop) then toast("Failed: wrong rig or not allowed") end
			end)
		end)
		del.MouseButton1Click:Connect(function()
			table.remove(saved, idx)
			persist()
			refreshSaved()
		end)
	end
end
button(E, "Save Custom Emote", function()
	local id = readId()
	if not id then toast("Enter an animation ID") return end
	local name = saveNameBox.Text ~= "" and saveNameBox.Text or ("Emote " .. (#saved + 1))
	table.insert(saved, {name = name, id = id})
	persist()
	refreshSaved()
	saveNameBox.Text = ""
	toast("Saved: " .. name)
end)
section(E, "SAVED EMOTES (tap to play)")
savedFrame.Parent = nil
savedFrame.Parent = E
refreshSaved()

------------------------------------------------------------
-- EXECUTOR page
------------------------------------------------------------
local X = pages.EXECUTOR
section(X, "SCRIPT BOX (paste code or a loadstring)")
local codeBox = mk("TextBox", {Size = UDim2.new(1, 0, 0, 130), BackgroundColor3 = PANEL, Text = "", PlaceholderText = "Paste your script here...", PlaceholderColor3 = DIM, TextColor3 = ACCENT, Font = Enum.Font.Code, TextSize = 12, ClearTextOnFocus = false, MultiLine = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, X)
corner(codeBox, 8)
stroke(codeBox, OUTLINE, 1)
mk("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, codeBox)
local resultLabel = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = PANEL, Text = "Ready", TextColor3 = DIM, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left}, X)
corner(resultLabel, 8)
mk("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, resultLabel)
local function setResult(msg, good)
	resultLabel.Text = msg
	resultLabel.TextColor3 = good and ACCENT or Color3.fromRGB(255, 120, 120)
end
button(X, "Execute", function()
	local code = codeBox.Text
	if code == "" then toast("Script box is empty") return end
	task.spawn(function()
		local fn, err = loadstring(code)
		if not fn then setResult("Syntax error: " .. tostring(err), false) return end
		setResult("Running...", true)
		local ok, e = pcall(fn)
		if ok then setResult("Executed OK", true) else setResult("Error: " .. tostring(e), false) end
	end)
end)
button(X, "Clear", function()
	codeBox.Text = ""
	setResult("Cleared", true)
end)
button(X, "Copy Script", function()
	if setclipboard then setclipboard(codeBox.Text) toast("Copied") else toast("Clipboard not supported") end
end)
button(X, "R6 (R15 to R6)", function() toR6() end)
section(X, "LOAD FROM URL")
local urlBox = textbox(X, "https://raw.githubusercontent.com/...")
button(X, "Execute URL", function()
	local url = urlBox.Text
	if url == "" then toast("Enter a URL") return end
	task.spawn(function()
		setResult("Loading URL...", true)
		local ok, e = pcall(function() loadstring(game:HttpGet(url))() end)
		if ok then setResult("Executed OK", true) else setResult("Error: " .. tostring(e), false) end
	end)
end)

------------------------------------------------------------
-- UTILITY page
------------------------------------------------------------
local U = pages.UTILITY
section(U, "SERVER")
button(U, "Rejoin", function() rejoin() end)
button(U, "Server Hop", function() toast("Searching server...") serverHop() end)
button(U, "Copy Job ID", function()
	if setclipboard then setclipboard(game.JobId) toast("Job ID copied") else toast("Clipboard not supported") end
end)
toggle(U, "Auto Rejoin (when kicked)", function(v) State.autorejoin = v end, false, "autorejoin")
section(U, "CHAT")
local chatBox = textbox(U, "Message to send")
button(U, "Send Message", function()
	if chatBox.Text ~= "" then
		SendChatMessage(chatBox.Text)
		chatBox.Text = ""
	end
end)
section(U, "AUTOMATION")
toggle(U, "Auto Clicker", function(v) State.autoclick = v end, false, "autoclick")
slider(U, "Clicks per second", 1, 30, 10, function(v) State.cps = v end, "cpsS")
toggle(U, "Anti-AFK", function(v) State.antiafk = v end, true, "antiafk")
toggle(U, "Anti-Void (rescue from falling)", function(v) State.antivoid = v end, false, "antivoid")
section(U, "PROTECTION")
toggle(U, "Anti-Kick", function(v)
	State.antikick = v
	if v and not hookKick() then toast("Anti-Kick not supported by this executor") end
end, false, "antikick")
toggle(U, "Anti-Fling", function(v) State.antifling = v end, false, "antifling")

------------------------------------------------------------
-- INFO page
------------------------------------------------------------
local I = pages.INFO
section(I, "GAME")
local lGame, lPlace, lPlayers = infoLabel(I), infoLabel(I), infoLabel(I)
section(I, "PERFORMANCE")
local lFps, lPing = infoLabel(I), infoLabel(I)
section(I, "ABOUT")
local lAbout = infoLabel(I)
lAbout.Text = "Made in V3R4X_B01  -  V3.5"
lPlace.Text = "Place ID: " .. game.PlaceId
task.spawn(function()
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
	lGame.Text = "Game: " .. ((ok and info and info.Name) or "Unknown")
end)
local frames, lastT = 0, tick()
conns[#conns + 1] = RunService.RenderStepped:Connect(function() frames = frames + 1 end)
task.spawn(function()
	while alive do
		local now = tick()
		local fps = math.floor(frames / math.max(now - lastT, 0.01))
		frames, lastT = 0, now
		lFps.Text = "FPS: " .. fps
		lPlayers.Text = "Players: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers
		local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end)
		lPing.Text = "Ping: " .. (ok and ping or "N/A")
		local h = getHum()
		lRig.Text = "Your rig: " .. (h and (h.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6") or "N/A")
		task.wait(0.5)
	end
end)

------------------------------------------------------------
-- CMDS page (command bar)
------------------------------------------------------------
local function runCommand(str)
	local cmd, arg = str:match("^;?%s*(%S+)%s*(.*)$")
	if not cmd then return end
	cmd = cmd:lower()
	local num = tonumber(arg)

	local numMap = {
		speed = {"speedS", "speed"}, jump = {"jumpS", "jump"}, flyspeed = {"flyS", nil},
		gravity = {"gravS", "gravity"}, fov = {"fovS", "fov"}, time = {"timeS", "time"},
		aimfov = {"aimFovS", nil}, aimsmooth = {"aimSmoothS", nil},
		ringradius = {"ringRS", nil}, ringspeed = {"ringSpS", nil}, npcrange = {"npcRangeS", nil},
	}
	if numMap[cmd] then
		local sk, tk = numMap[cmd][1], numMap[cmd][2]
		if num then
			S[sk].Set(num)
			if tk then T[tk].Set(true) end
		elseif tk then
			T[tk].Set(false)
		end
		return
	end

	local toggles = {"fly", "noclip", "infjump", "spin", "bhop", "slowfall", "airwalk", "freeze", "deathback", "fullbright", "nofog", "xray", "esp", "ctrlclick", "antiafk", "antikick", "antifling", "antivoid", "autoclick", "autorejoin", "camunlock", "aimbot", "ring", "autokill", "autocombo"}
	for _, k in ipairs(toggles) do
		if cmd == k then T[k].Set(not T[k].Get()) return end
	end

	if cmd == "goto" then tpToPlayer(findPlayer(arg))
	elseif cmd == "view" then startSpectate(findPlayer(arg))
	elseif cmd == "unview" then stopSpectate()
	elseif cmd == "orbit" or cmd == "follow" or cmd == "headsit" or cmd == "backpack" then
		nameBox.Text = arg
		T[cmd].Set(true)
	elseif cmd == "unlink" or cmd == "unorbit" or cmd == "unfollow" then
		for _, c in pairs(modeToggles) do c.Set(false) end
	elseif cmd == "fight" then
		local k = arg:lower()
		if k ~= "slash" and k ~= "lunge" and k ~= "hold" then k = "slash" end
		if not playFight(k) then toast("Animation failed") end
	elseif cmd == "combo" then task.spawn(doCombo)
	elseif cmd == "killnpcs" then killNpcs(State.npcRange, false)
	elseif cmd == "launchnpcs" then launchNpcs(State.npcRange)
	elseif cmd == "r6" then toR6()
	elseif cmd == "emote" then
		if not playDefaultEmote(arg:lower()) then toast("Unknown emote") end
	elseif cmd == "anim" then
		local id = tonumber(arg)
		if id and not playAnimId(id, State.emoteLoop) then toast("Animation failed") end
	elseif cmd == "stopemote" or cmd == "stopanim" then stopEmote()
	elseif cmd == "say" then SendChatMessage(arg)
	elseif cmd == "save" then local r = getRoot() if r then savedCF = r.CFrame toast("Position saved") end
	elseif cmd == "back" then local r = getRoot() if r and savedCF then r.CFrame = savedCF else toast("Nothing saved") end
	elseif cmd == "spawn" then tpSpawn()
	elseif cmd == "dash" then dash()
	elseif cmd == "tpc" then tpCrosshair()
	elseif cmd == "respawn" then respawnHere()
	elseif cmd == "reset" then local h = getHum() if h then h.Health = 0 end
	elseif cmd == "sit" then local h = getHum() if h then h.Sit = true end
	elseif cmd == "rejoin" then rejoin()
	elseif cmd == "hop" then serverHop()
	elseif cmd == "help" then toast("Command list is below")
	else toast("Unknown command: " .. cmd) end
end

local C = pages.CMDS
section(C, "COMMAND BAR")
local cmdBox = textbox(C, "Type a command, e.g. speed 100")
cmdBox.FocusLost:Connect(function(enter)
	if enter and cmdBox.Text ~= "" then
		safe(runCommand, cmdBox.Text)
		cmdBox.Text = ""
	end
end)
button(C, "Run Command", function()
	if cmdBox.Text ~= "" then
		safe(runCommand, cmdBox.Text)
		cmdBox.Text = ""
	end
end)
section(C, "COMMANDS")
local help = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = PANEL, TextColor3 = DIM, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	Text = "speed N, jump N, flyspeed N, gravity N, fov N, time N\nfly, noclip, infjump, spin, bhop, slowfall, airwalk, freeze, deathback, camunlock\nesp, xray, fullbright, nofog, ctrlclick\nantiafk, antikick, antifling, antivoid, autoclick, autorejoin\naimbot, aimfov N, aimsmooth N\nring, ringradius N, ringspeed N\nautokill, killnpcs, launchnpcs, npcrange N\nfight slash|lunge|hold, combo, autocombo\ngoto NAME, view NAME, orbit NAME, follow NAME, headsit NAME, backpack NAME\nunview, unlink, save, back, spawn, tpc, dash, respawn, r6\nemote NAME (wave, point, cheer, laugh, dance, dance2, dance3)\nanim ID, stopanim, say TEXT, reset, sit, rejoin, hop"}, C)
corner(help, 8)
stroke(help, OUTLINE, 1)
mk("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}, help)

selectTab("PLAYER")

mk("TextLabel", {Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -20), BackgroundTransparency = 1, Text = "Made in V3R4X_B01", TextColor3 = ACCENT, TextTransparency = 0.8, Font = Enum.Font.Gotham, TextSize = 11}, main)

------------------------------------------------------------
-- minimize / close / hide key
------------------------------------------------------------
local mini = mk("TextButton", {Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0, 20, 0.5, 0), BackgroundColor3 = BG, Text = "V3R", TextColor3 = ACCENT, Font = Enum.Font.GothamBlack, TextSize = 15, Visible = false}, sg)
corner(mini, 27)
stroke(mini, ACCENT, 2)
local miniMoved = makeDraggable(mini, mini)

minBtn.MouseButton1Click:Connect(function()
	local ap = main.AbsolutePosition
	mini.Position = UDim2.new(0, ap.X, 0, ap.Y + 36)
	main.Visible = false
	mini.Visible = true
end)
mini.MouseButton1Click:Connect(function()
	if miniMoved() then return end
	mini.Visible = false
	main.Visible = true
end)
conns[#conns + 1] = UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightShift then
		if mini.Visible then mini.Visible = false main.Visible = true else main.Visible = not main.Visible end
	end
end)

local confirm = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.15, Visible = false, ZIndex = 20, Active = true}, main)
mk("TextLabel", {Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0.32, 0), BackgroundTransparency = 1, Text = "Do you want to close?", TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 20, ZIndex = 21}, confirm)
local yes = mk("TextButton", {Size = UDim2.new(0, 100, 0, 36), Position = UDim2.new(0.5, -110, 0.55, 0), BackgroundColor3 = PANEL, Text = "YES", TextColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 16, ZIndex = 21}, confirm)
local no = mk("TextButton", {Size = UDim2.new(0, 100, 0, 36), Position = UDim2.new(0.5, 10, 0.55, 0), BackgroundColor3 = PANEL, Text = "NO", TextColor3 = Color3.fromRGB(255, 90, 90), Font = Enum.Font.GothamBold, TextSize = 16, ZIndex = 21}, confirm)
corner(yes, 8) corner(no, 8)
stroke(yes, ACCENT, 1) stroke(no, Color3.fromRGB(255, 90, 90), 1)

xBtn.MouseButton1Click:Connect(function() confirm.Visible = true end)
no.MouseButton1Click:Connect(function() confirm.Visible = false end)
yes.MouseButton1Click:Connect(function()
	alive = false
	for k, v in pairs(State) do
		if type(v) == "boolean" then State[k] = false end
	end
	pcall(function() RunService:UnbindFromRenderStep("V3R4X_AIM") end)
	stopFly()
	stopSpectate()
	stopEmote()
	airWalkOff()
	restoreRing()
	clearEsp()
	setXray(false)
	restoreLight()
	workspace.Gravity = origGravity
	workspace.CurrentCamera.FieldOfView = 70
	lp.CameraMaxZoomDistance = origCam.zoom
	lp.DevCameraOcclusionMode = origCam.occ
	local r, h = getRoot(), getHum()
	if r then r.Anchored = false end
	if h then
		h.Sit = false
		h.WalkSpeed = base.speed
		h.UseJumpPower = base.usejp
		h.JumpPower = base.jump
	end
	for _, c in ipairs(conns) do c:Disconnect() end
	sg:Destroy()
end)

toast("V3R4X_B01 V3.5 loaded")
