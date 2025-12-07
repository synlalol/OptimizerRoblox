-- Legit Aim — Full Script (Wall Highlight added)
-- Features: Launcher, Aim (delay/smooth/jitter/random offset), Distance-based smoothing, Humanize Aim (threshold editable),
-- Visuals (ESP, tracers, name, Wall Highlight), Misc (Head copy for everyone), dead-checks

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Random generator
local rnd = Random.new(tick() % 1e9)

-- ---------- GUI ----------
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

-- Launcher Button
local launcher = Instance.new("TextButton")
launcher.Size = UDim2.new(0, 40, 0, 40)
launcher.Position = UDim2.new(0, 15, 0.5, -20)
launcher.Text = "LA"
launcher.Font = Enum.Font.Code
launcher.TextColor3 = Color3.fromRGB(180, 0, 255)
launcher.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
launcher.BorderSizePixel = 0
launcher.AutoButtonColor = false
launcher.Parent = gui
local round1 = Instance.new("UICorner"); round1.CornerRadius = UDim.new(0,10); round1.Parent = launcher

-- Panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 300, 0, 200)
panel.Position = UDim2.new(0.5, -150, 0.5, -100)
panel.BackgroundColor3 = Color3.fromRGB(10,10,10)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
local outline = Instance.new("UIStroke"); outline.Color = Color3.fromRGB(180,0,255); outline.Thickness = 2; outline.Parent = panel
local round2 = Instance.new("UICorner"); round2.CornerRadius = UDim.new(0,12); round2.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "Legit Aim"
title.Font = Enum.Font.Code
title.TextColor3 = Color3.fromRGB(180,0,255)
title.TextSize = 18
title.Parent = panel

-- Tabs
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -10, 0, 28)
tabsFrame.Position = UDim2.new(0, 5, 0, 30)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = panel

local function makeTabBtn(parent, posX, text)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1/3, -6, 1, 0)
	b.Position = UDim2.new(posX, (posX==2/3) and 6 or 0, 0, 0)
	b.BackgroundColor3 = Color3.fromRGB(20,20,20)
	b.BorderSizePixel = 0
	b.Font = Enum.Font.Code
	b.Text = text
	b.TextColor3 = Color3.fromRGB(180,0,255)
	b.Parent = parent
	local r = Instance.new("UICorner"); r.CornerRadius = UDim.new(0,6); r.Parent = b
	return b
end

local aimTabBtn = makeTabBtn(tabsFrame, 0/3, "Aim")
aimTabBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
local visualsTabBtn = makeTabBtn(tabsFrame, 1/3, "Visuals")
local miscTabBtn = makeTabBtn(tabsFrame, 2/3, "Misc")

-- Content area offsets
local contentY = 60

-- Create a ScrollingFrame builder
local function makeScroll(parent)
	local s = Instance.new("ScrollingFrame")
	s.Size = UDim2.new(1, -10, 1, -(contentY + 5))
	s.Position = UDim2.new(0, 5, 0, contentY)
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 5
	s.CanvasSize = UDim2.new(0,0,0,0)
	s.Visible = false
	s.Parent = parent
	local layout = Instance.new("UIListLayout"); layout.Parent = s; layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,10)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		s.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
	end)
	return s, layout
end

local aimScroll, aimLayout = makeScroll(panel); aimScroll.Visible = true
local visualsScroll, visualsLayout = makeScroll(panel)
local miscScroll, miscLayout = makeScroll(panel)

-- Helper UI creators
local function createCheckbox(parent, text)
	local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,25); frame.BackgroundTransparency = 1; frame.Parent = parent
	local box = Instance.new("TextButton"); box.Size = UDim2.new(0,20,0,20); box.BackgroundColor3 = Color3.fromRGB(20,20,20); box.BorderSizePixel = 0; box.AutoButtonColor = false; box.Parent = frame
	local round = Instance.new("UICorner"); round.CornerRadius = UDim.new(0,5); round.Parent = box
	local label = Instance.new("TextLabel"); label.Text = text; label.Size = UDim2.new(1, -30,1,0); label.Position = UDim2.new(0,30,0,0); label.BackgroundTransparency = 1; label.TextColor3 = Color3.fromRGB(180,0,255); label.Font = Enum.Font.Code; label.TextSize = 16; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
	local toggled = false
	box.MouseButton1Click:Connect(function() toggled = not toggled; box.BackgroundColor3 = toggled and Color3.fromRGB(180,0,255) or Color3.fromRGB(20,20,20) end)
	return frame, function() return toggled end
end

local function createTextbox(parent, text, placeholder)
	local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,25); frame.BackgroundTransparency = 1; frame.Parent = parent
	local label = Instance.new("TextLabel"); label.Text = text; label.Size = UDim2.new(0.5,0,1,0); label.BackgroundTransparency = 1; label.TextColor3 = Color3.fromRGB(180,0,255); label.Font = Enum.Font.Code; label.TextSize = 16; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
	local box = Instance.new("TextBox"); box.Size = UDim2.new(0.45,0,1,0); box.Position = UDim2.new(0.52,0,0,0); box.BackgroundColor3 = Color3.fromRGB(20,20,20); box.TextColor3 = Color3.fromRGB(180,0,255); box.Text = placeholder or ""; box.ClearTextOnFocus = false; box.Font = Enum.Font.Code; box.TextSize = 16; box.BorderSizePixel = 0; box.Parent = frame
	local round = Instance.new("UICorner"); round.CornerRadius = UDim.new(0,5); round.Parent = box
	return frame, box
end

local function createDropdown(parent, labelText, options)
	local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,0,30); frame.BackgroundTransparency = 1; frame.Parent = parent
	local label = Instance.new("TextLabel"); label.Text = labelText; label.Size = UDim2.new(0.5,0,1,0); label.BackgroundTransparency = 1; label.TextColor3 = Color3.fromRGB(180,0,255); label.Font = Enum.Font.Code; label.TextSize = 16; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
	local button = Instance.new("TextButton"); button.Size = UDim2.new(0.45,0,1,0); button.Position = UDim2.new(0.52,0,0,0); button.BackgroundColor3 = Color3.fromRGB(20,20,20); button.TextColor3 = Color3.fromRGB(180,0,255); button.Text = options[1]; button.Font = Enum.Font.Code; button.TextSize = 16; button.BorderSizePixel = 0; button.Parent = frame
	local round = Instance.new("UICorner"); round.CornerRadius = UDim.new(0,5); round.Parent = button
	local dropdownFrame = Instance.new("Frame"); dropdownFrame.Size = UDim2.new(1,0,0,#options*25); dropdownFrame.Position = UDim2.new(0,0,1,0); dropdownFrame.BackgroundColor3 = Color3.fromRGB(20,20,20); dropdownFrame.Visible = false; dropdownFrame.Parent = button
	local dropdownLayout = Instance.new("UIListLayout"); dropdownLayout.Parent = dropdownFrame; dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local selected = options[1]
	for i,opt in ipairs(options) do
		local optBtn = Instance.new("TextButton"); optBtn.Size = UDim2.new(1,0,0,25); optBtn.BackgroundColor3 = Color3.fromRGB(30,30,30); optBtn.BorderSizePixel = 0; optBtn.TextColor3 = Color3.fromRGB(180,0,255); optBtn.Text = opt; optBtn.Font = Enum.Font.Code; optBtn.TextSize = 16; optBtn.Parent = dropdownFrame
		local roundOpt = Instance.new("UICorner"); roundOpt.CornerRadius = UDim.new(0,5); roundOpt.Parent = optBtn
		optBtn.MouseButton1Click:Connect(function() button.Text = opt; selected = opt; dropdownFrame.Visible = false end)
	end
	button.MouseButton1Click:Connect(function() dropdownFrame.Visible = not dropdownFrame.Visible end)
	return frame, function() return selected end
end

-- Aim UI
local aimFrame, aimToggle = createCheckbox(aimScroll, "Enable Aimlock")
local smoothFrame, smoothBox = createTextbox(aimScroll, "Smoothness", "0.2")
local distanceSmoothFrame, distanceSmoothToggle = createCheckbox(aimScroll, "Distance-based Smoothness")
local smoothRangeNoteFrame, _ = createTextbox(aimScroll, "Smooth caps are 0.1 (far) -> 0.4 (close)", "")
local humanizeFrame, humanizeToggle = createCheckbox(aimScroll, "Humanize Aim (stop locking while you're aiming at them)")
local humanizeThresholdFrame, humanizeThresholdBox = createTextbox(aimScroll, "Humanize Threshold (pixels)", "8")
local delayFrame, delayBox = createTextbox(aimScroll, "Delay", "0.5")
local randIntervalFrame, randIntervalBox = createTextbox(aimScroll, "Random Offset Interval (s)", "1.0")
local jitterFrame, jitterBox = createTextbox(aimScroll, "Jitter Amount (studs)", "0.05")
local teamFrame, teamToggle = createCheckbox(aimScroll, "Team Check")
local wallFrame, wallToggle = createCheckbox(aimScroll, "Wall Check")
local fovFrame, fovToggle = createCheckbox(aimScroll, "Show FOV Circle")
local fovSizeFrame, fovSizeBox = createTextbox(aimScroll, "FOV Size", "100")
local distanceFrame, distanceBox = createTextbox(aimScroll, "Distance Limit (Studs)", "100")
local aimPartFrame, aimPartDropdown = createDropdown(aimScroll, "Aim Part", {"Head","HumanoidRootPart","Random"})

-- Visuals UI (added Wall Highlight checkbox here)
local boxESPFrame, boxEspToggle = createCheckbox(visualsScroll, "Box ESP")
local healthESPFrame, healthEspToggle = createCheckbox(visualsScroll, "Healthbar ESP")
local nameESPFrame, nameEspToggle = createCheckbox(visualsScroll, "Name ESP")
local visualsTeamFrame, visualsTeamToggle = createCheckbox(visualsScroll, "Team Color (Blue=Team, Red=Enemy)")
local visibleColorFrame, visibleColorToggle = createCheckbox(visualsScroll, "Visible Color (Yellow=Enemy, LightBlue=Team)")
local wallHighlightFrame, wallHighlightToggle = createCheckbox(visualsScroll, "Wall Highlight (Teammates=Purple, Enemies=Pink)") -- NEW
local tracersFrame, tracersToggle = createCheckbox(visualsScroll, "Tracers")

-- Misc UI (Headbox Expander for everyone)
local headScaleFrame, headScaleBox = createTextbox(miscScroll, "Head Scale (multiplier)", "3")
local followFrame, followToggle = createCheckbox(miscScroll, "Follow Targets")
local spawnBtnFrame = Instance.new("Frame"); spawnBtnFrame.Size = UDim2.new(1,0,0,28); spawnBtnFrame.BackgroundTransparency = 1; spawnBtnFrame.Parent = miscScroll
local spawnBtn = Instance.new("TextButton"); spawnBtn.Size = UDim2.new(1,0,1,0); spawnBtn.Position = UDim2.new(0,0,0,0); spawnBtn.BackgroundColor3 = Color3.fromRGB(30,30,30); spawnBtn.BorderSizePixel = 0; spawnBtn.Font = Enum.Font.Code; spawnBtn.Text = "Spawn Head Copies (Everyone)"; spawnBtn.TextColor3 = Color3.fromRGB(180,0,255); spawnBtn.Parent = spawnBtnFrame
local roundSpawn = Instance.new("UICorner"); roundSpawn.CornerRadius = UDim.new(0,6); roundSpawn.Parent = spawnBtn

-- Tab switching
local function selectTab(tab)
	aimScroll.Visible, visualsScroll.Visible, miscScroll.Visible = false, false, false
	aimTabBtn.BackgroundColor3, visualsTabBtn.BackgroundColor3, miscTabBtn.BackgroundColor3 = Color3.fromRGB(20,20,20), Color3.fromRGB(20,20,20), Color3.fromRGB(20,20,20)
	if tab == "Aim" then aimScroll.Visible = true; aimTabBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
	elseif tab == "Visuals" then visualsScroll.Visible = true; visualsTabBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
	elseif tab == "Misc" then miscScroll.Visible = true; miscTabBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
	end
end
aimTabBtn.MouseButton1Click:Connect(function() selectTab("Aim") end)
visualsTabBtn.MouseButton1Click:Connect(function() selectTab("Visuals") end)
miscTabBtn.MouseButton1Click:Connect(function() selectTab("Misc") end)

-- Toggle main panel
local open = false
launcher.MouseButton1Click:Connect(function() open = not open; panel.Visible = open end)

-- ---------- Drawing FOV ----------
local fovCircle = Drawing and Drawing.new("Circle")
if fovCircle then
	fovCircle.Visible = false
	fovCircle.Color = Color3.fromRGB(180,0,255)
	fovCircle.Thickness = 2
	fovCircle.Filled = false
end

-- ---------- AIM LOGIC ----------
local currentTarget = nil
local currentTargetPart = nil
local targetStartTime = 0
local currentTargetOffset = Vector3.new(0,0,0)
local lastOffsetChangeTime = 0

-- Humanize: blocked players map
local humanBlocked = {} -- player -> bool

-- ---------- ESP (Drawing API) ----------
local drawings = {}

local function getBoundingBox(parts)
	local points = {}
	for _, part in pairs(parts) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local corners = {
				part.CFrame * Vector3.new(-part.Size.X/2,-part.Size.Y/2,-part.Size.Z/2),
				part.CFrame * Vector3.new(-part.Size.X/2,-part.Size.Y/2,part.Size.Z/2),
				part.CFrame * Vector3.new(-part.Size.X/2,part.Size.Y/2,-part.Size.Z/2),
				part.CFrame * Vector3.new(-part.Size.X/2,part.Size.Y/2,part.Size.Z/2),
				part.CFrame * Vector3.new(part.Size.X/2,-part.Size.Y/2,-part.Size.Z/2),
				part.CFrame * Vector3.new(part.Size.X/2,-part.Size.Y/2,part.Size.Z/2),
				part.CFrame * Vector3.new(part.Size.X/2,part.Size.Y/2,-part.Size.Z/2),
				part.CFrame * Vector3.new(part.Size.X/2,part.Size.Y/2,part.Size.Z/2),
			}
			for _, corner in pairs(corners) do
				local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
				if onScreen then table.insert(points, Vector2.new(screenPos.X, screenPos.Y)) end
			end
		end
	end
	if #points == 0 then return nil end
	local minX, minY = points[1].X, points[1].Y
	local maxX, maxY = points[1].X, points[1].Y
	for _, p in pairs(points) do
		if p.X < minX then minX = p.X end
		if p.Y < minY then minY = p.Y end
		if p.X > maxX then maxX = p.X end
		if p.Y > maxY then maxY = p.Y end
	end
	return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

local function createESP(player)
	if player == LocalPlayer then return end
	if not Drawing then return end
	local boxOutline = Drawing.new("Square"); boxOutline.Thickness = 3; boxOutline.Color = Color3.fromRGB(0,0,0); boxOutline.Filled = false; boxOutline.Visible = false
	local box = Drawing.new("Square"); box.Thickness = 1.5; box.Color = Color3.fromRGB(255,0,0); box.Filled = false; box.Visible = false
	local healthBar = Drawing.new("Square"); healthBar.Filled = true; healthBar.Transparency = 1; healthBar.Color = Color3.fromRGB(0,255,0); healthBar.Visible = false
	local nameOutline = Drawing.new("Text"); nameOutline.Size = 14; nameOutline.Center = true; nameOutline.Color = Color3.fromRGB(0,0,0); nameOutline.Visible = false
	local nameText = Drawing.new("Text"); nameText.Size = 14; nameText.Center = true; nameText.Color = Color3.fromRGB(255,255,255); nameText.Visible = false
	local tracer = Drawing.new("Line"); tracer.Thickness = 1.5; tracer.Visible = false; tracer.From = Vector2.new(0,0); tracer.To = Vector2.new(0,0)
	pcall(function() nameOutline.Font = Drawing.Fonts and Drawing.Fonts.Code or Drawing.Fonts end)
	pcall(function() nameText.Font = Drawing.Fonts and Drawing.Fonts.Code or Drawing.Fonts end)
	drawings[player] = {Outline = boxOutline, Box = box, HealthBar = healthBar, NameOutline = nameOutline, NameText = nameText, Tracer = tracer}
end

local function removeESP(player)
	if drawings[player] then
		for _, d in pairs(drawings[player]) do
			pcall(function() d:Remove() end)
		end
		drawings[player] = nil
	end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(function(p) createESP(p) end)
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

local function partIsVisible(part, player)
	if not part or not part.Parent then return false end
	local origin = Camera.CFrame.Position
	local dir = (part.Position - origin)
	local hit = workspace:FindPartOnRay(Ray.new(origin, dir.Unit * (dir.Magnitude + 1)), LocalPlayer.Character)
	if hit == nil then
		local _, onScreen = Camera:WorldToViewportPoint(part.Position)
		return onScreen
	end
	return hit:IsDescendantOf(player.Character)
end

-- helper: check if part is behind a wall (ray hits non-character before target)
local function partIsBehindWall(part, player)
	if not part or not part.Parent then return false end
	local origin = Camera.CFrame.Position
	local dir = (part.Position - origin)
	local hit = workspace:FindPartOnRay(Ray.new(origin, dir.Unit * (dir.Magnitude + 1)), LocalPlayer.Character)
	if hit and not hit:IsDescendantOf(player.Character) then
		return true
	end
	return false
end

-- ---------- Head copies (Misc) ----------
local headCopies = {} -- player -> {Part, Scale}
local spawnedForAll = false

local function createHeadCopyFor(player, scale)
	if not player or player == LocalPlayer then return nil end
	if not player.Character then return nil end
	local head = player.Character:FindFirstChild("Head")
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health <= 0 then return nil end
	if not head then return nil end

	-- remove existing
	if headCopies[player] then
		pcall(function() headCopies[player].Part:Destroy() end)
		headCopies[player] = nil
	end

	local ok, clone = pcall(function() return head:Clone() end)
	if not ok or not clone then return nil end
	clone.Name = "Head"
	clone.Parent = workspace
	clone.CanCollide = false
	if clone:IsA("BasePart") then
		clone.Anchored = true
		local scaleNum = tonumber(scale) or 3
		clone.Size = clone.Size * scaleNum
		for _, child in pairs(clone:GetChildren()) do
			if child:IsA("SpecialMesh") then
				child.Scale = child.Scale * scaleNum
			end
		end
	else
		clone:Destroy()
		return nil
	end

	headCopies[player] = {Part = clone, Scale = tonumber(scale) or 3, Target = player}
	return headCopies[player]
end

local function removeHeadCopyFor(player)
	if headCopies[player] then
		pcall(function() if headCopies[player].Part then headCopies[player].Part:Destroy() end end)
		headCopies[player] = nil
	end
end

local function spawnHeadCopiesForAll()
	local scale = tonumber(headScaleBox.Text) or 3
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hum = p.Character:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				pcall(function() createHeadCopyFor(p, scale) end)
			end
		end
	end
	spawnedForAll = true
	spawnBtn.Text = "Remove Head Copies"
end

local function removeAllHeadCopies()
	for p,_ in pairs(headCopies) do removeHeadCopyFor(p) end
	spawnedForAll = false
	spawnBtn.Text = "Spawn Head Copies (Everyone)"
end

spawnBtn.MouseButton1Click:Connect(function()
	if spawnedForAll then removeAllHeadCopies() else spawnHeadCopiesForAll() end
end)

-- Character/humanoid monitoring (dead-check + auto respawn copy)
local function handleCharacter(player, character)
	if not player or not character then return end
	local humanoid = character:FindFirstChildWhichIsA("Humanoid") or character:FindFirstChild("Humanoid")
	if humanoid then
		if humanoid.Health <= 0 then removeHeadCopyFor(player) end
		local conn
		conn = humanoid.HealthChanged:Connect(function(hp)
			if not player then
				if conn then pcall(function() conn:Disconnect() end) end
				return
			end
			if hp <= 0 then
				removeHeadCopyFor(player)
				-- also clear humanBlocked if they die (so they don't stay blocked)
				humanBlocked[player] = nil
			else
				-- revived: if spawnedForAll, create
				if spawnedForAll then
					task.delay(0.1, function()
						if player and player.Character and player.Character.Parent then
							pcall(function() createHeadCopyFor(player, tonumber(headScaleBox.Text) or 3) end)
						end
					end)
				end
			end
		end)
		player.CharacterRemoving:Connect(function()
			removeHeadCopyFor(player)
			humanBlocked[player] = nil
			if conn then pcall(function() conn:Disconnect() end); conn = nil end
		end)
	else
		removeHeadCopyFor(player)
		humanBlocked[player] = nil
	end
end

-- attach for existing & future
for _, p in pairs(Players:GetPlayers()) do
	if p.Character then handleCharacter(p, p.Character) end
	p.CharacterAdded:Connect(function(char) handleCharacter(p, char) end)
end
Players.PlayerAdded:Connect(function(p)
	createESP(p)
	p.CharacterAdded:Connect(function(char) handleCharacter(p, char) end)
end)
Players.PlayerRemoving:Connect(function(p) removeESP(p); removeHeadCopyFor(p); humanBlocked[p] = nil end)

-- ---------- Main Run loop (with Wall Highlight) ----------
RunService.RenderStepped:Connect(function()
	-- params
	local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	local fovRadius = tonumber(fovSizeBox.Text) or 100
	local delayTime = tonumber(delayBox.Text) or 0.5
	local offsetInterval = tonumber(randIntervalBox.Text) or 1.0
	local jitterAmount = tonumber(jitterBox.Text) or 0.05
	local smoothTextboxVal = tonumber(smoothBox.Text) or 0.2
	local distanceLimit = tonumber(distanceBox.Text) or 100
	local aimPartSelected = aimPartDropdown()

	-- smoothness caps for distance-based mode
	local minSmooth = 0.1
	local maxSmooth = 0.4

	-- read humanize threshold live from textbox, fallback to 8
	local humanizeThreshold = tonumber(humanizeThresholdBox.Text) or 8
	if humanizeThreshold < 0 then humanizeThreshold = 0 end

	-- sanity-check current target: if dead or invalid, clear
	if currentTarget then
		local ok = true
		if not currentTarget.Character or not currentTarget.Character.Parent then ok = false end
		local hum = currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid")
		if hum and hum.Health <= 0 then ok = false end
		if currentTargetPart and (not currentTargetPart.Parent) then ok = false end
		if not ok then
			currentTarget = nil
			currentTargetPart = nil
			targetStartTime = 0
			currentTargetOffset = Vector3.new(0,0,0)
		end
	end

	-- aim selection
	if aimToggle() then
		local closestDist = math.huge
		local closestPlayer = nil
		local closestPart = nil

		for _, plr in pairs(Players:GetPlayers()) do
			-- basic validity
			if plr ~= LocalPlayer and plr.Character and plr.Character.Parent then
				local hum = plr.Character:FindFirstChild("Humanoid")
				if hum and hum.Health <= 0 then continue end -- skip dead players early

				-- get candidate parts (Head/HRP/Random)
				local parts = {}
				if aimPartSelected == "Head" then
					if plr.Character:FindFirstChild("Head") then parts = {plr.Character.Head} end
				elseif aimPartSelected == "HumanoidRootPart" then
					if plr.Character:FindFirstChild("HumanoidRootPart") then parts = {plr.Character.HumanoidRootPart} end
				elseif aimPartSelected == "Random" then
					local tmp = {}
					if plr.Character:FindFirstChild("Head") then table.insert(tmp, plr.Character.Head) end
					if plr.Character:FindFirstChild("HumanoidRootPart") then table.insert(tmp, plr.Character.HumanoidRootPart) end
					parts = tmp
				end

				-- For each part candidate
				for _, part in pairs(parts) do
					if part and part.Parent then
						-- humanize check: if humanize enabled, compute screen distance and block/unblock accordingly
						local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
						local aimDist = math.huge
						if onScreen then
							aimDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
						end

						-- If currently blocked and aim moved away enough -> unblock
						if humanBlocked[plr] and aimDist > humanizeThreshold then
							humanBlocked[plr] = nil
						end

						-- If humanize enabled and player is being aimed at (onScreen & within threshold), block them and skip
						if humanizeToggle() and onScreen and aimDist <= humanizeThreshold then
							-- immediate block and skip
							humanBlocked[plr] = true
							-- If this was your current target, clear it immediately
							if currentTarget == plr then
								currentTarget = nil
								currentTargetPart = nil
								targetStartTime = 0
								currentTargetOffset = Vector3.new(0,0,0)
							end
							-- skip this player
							continue
						end

						-- skip if blocked by humanization
						if humanBlocked[plr] then
							continue
						end

						-- team check
						if teamToggle() and plr.Team == LocalPlayer.Team then continue end

						-- wall check
						if wallToggle() then
							local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 500)
							local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
							if hit and not hit:IsDescendantOf(plr.Character) then continue end
						end

						-- distance limit
						local distFromCamera = (part.Position - Camera.CFrame.Position).Magnitude
						if distFromCamera > distanceLimit then continue end

						-- on-screen and within FOV?
						if onScreen then
							local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
							if dist <= fovRadius and dist < closestDist then
								closestDist = dist
								closestPlayer = plr
								closestPart = part
							end
						end
					end
				end
			end
		end

		-- target changed?
		if closestPlayer ~= currentTarget then
			currentTarget = closestPlayer
			currentTargetPart = closestPart
			targetStartTime = currentTarget and os.clock() or 0
			lastOffsetChangeTime = os.clock()

			if currentTargetPart and currentTargetPart.Parent then
				local s = currentTargetPart.Size
				currentTargetOffset = Vector3.new(
					rnd:NextNumber(-s.X * 0.4, s.X * 0.4),
					rnd:NextNumber(-s.Y * 0.4, s.Y * 0.4),
					rnd:NextNumber(-s.Z * 0.4, s.Z * 0.4)
				)
			else
				currentTargetOffset = Vector3.new(0,0,0)
			end
		else
			if currentTarget and (not currentTargetPart or not currentTargetPart.Parent) then
				currentTargetPart = closestPart
				if currentTargetPart and currentTargetPart.Parent then
					local s = currentTargetPart.Size
					currentTargetOffset = Vector3.new(
						rnd:NextNumber(-s.X * 0.4, s.X * 0.4),
						rnd:NextNumber(-s.Y * 0.4, s.Y * 0.4),
						rnd:NextNumber(-s.Z * 0.4, s.Z * 0.4)
					)
					lastOffsetChangeTime = os.clock()
				else
					currentTarget = nil; currentTargetPart = nil; targetStartTime = 0; currentTargetOffset = Vector3.new(0,0,0)
				end
			end
		end

		-- periodic regen of offset
		if currentTarget and currentTargetPart and currentTargetPart.Parent and os.clock() - lastOffsetChangeTime >= offsetInterval then
			local s = currentTargetPart.Size
			currentTargetOffset = Vector3.new(
				rnd:NextNumber(-s.X * 0.4, s.X * 0.4),
				rnd:NextNumber(-s.Y * 0.4, s.Y * 0.4),
				rnd:NextNumber(-s.Z * 0.4, s.Z * 0.4)
			)
			lastOffsetChangeTime = os.clock()
		end

		-- determine final smooth value (either distance-based or from textbox)
		local smooth = smoothTextboxVal
		if distanceSmoothToggle() and currentTarget and currentTargetPart and currentTargetPart.Parent then
			local distCam = (currentTargetPart.Position - Camera.CFrame.Position).Magnitude
			local farRef = math.max(distanceLimit, 1)
			local t = math.clamp(1 - (distCam / farRef), 0, 1)
			smooth = minSmooth + t * (maxSmooth - minSmooth)
		end

		-- lock if ready and target alive
		if currentTarget and currentTarget.Character and currentTargetPart and currentTargetPart.Parent then
			local hum = currentTarget.Character:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 and os.clock() - targetStartTime >= delayTime then
				-- final check: if humanize enabled and player is being aimed at right now, skip locking (should be already blocked above, but double-check)
				if humanizeToggle() then
					local sp, onS = Camera:WorldToViewportPoint(currentTargetPart.Position)
					if onS then
						local aimDistNow = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
						if aimDistNow <= humanizeThreshold then
							-- block them and skip locking
							humanBlocked[currentTarget] = true
							currentTarget = nil
							currentTargetPart = nil
							targetStartTime = 0
							currentTargetOffset = Vector3.new(0,0,0)
						else
							local jitterVec = Vector3.new(
								rnd:NextNumber(-jitterAmount, jitterAmount),
								rnd:NextNumber(-jitterAmount, jitterAmount),
								rnd:NextNumber(-jitterAmount, jitterAmount)
							)
							local targetPos = currentTargetPart.Position + currentTargetOffset + jitterVec
							local currentCFrame = Camera.CFrame
							Camera.CFrame = currentCFrame:Lerp(CFrame.new(currentCFrame.Position, targetPos), smooth)
						end
					end
				else
					local jitterVec = Vector3.new(
						rnd:NextNumber(-jitterAmount, jitterAmount),
						rnd:NextNumber(-jitterAmount, jitterAmount),
						rnd:NextNumber(-jitterAmount, jitterAmount)
					)
					local targetPos = currentTargetPart.Position + currentTargetOffset + jitterVec
					local currentCFrame = Camera.CFrame
					Camera.CFrame = currentCFrame:Lerp(CFrame.new(currentCFrame.Position, targetPos), smooth)
				end
			else
				if hum and hum.Health <= 0 then currentTarget = nil; currentTargetPart = nil; targetStartTime = 0; currentTargetOffset = Vector3.new(0,0,0) end
			end
		end
	end

	-- update FOV circle
	if fovCircle then
		fovCircle.Visible = fovToggle()
		fovCircle.Position = screenCenter
		fovCircle.Radius = fovRadius
	end

	-- ---------- Update ESP drawings (respect Wall Highlight) ----------
	if Drawing then
		local drawBoxes = boxEspToggle()
		local drawHealth = healthEspToggle()
		local drawNames = nameEspToggle()
		local teamColorMode = visualsTeamToggle()
		local visibleColorMode = visibleColorToggle()
		local wallHighlightMode = wallHighlightToggle() -- new toggle
		local drawTracers = tracersToggle()
		local bottomCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y - 5)

		-- special colors for wall highlight
		local wallTeamColor = Color3.fromRGB(160, 0, 255) -- purple for teammates behind a wall
		local wallEnemyColor = Color3.fromRGB(255, 105, 180) -- pink for enemies behind a wall

		for player, draw in pairs(drawings) do
			local character = player.Character
			local humanoid = character and character:FindFirstChild("Humanoid")
			if character and humanoid and humanoid.Health > 0 then
				local parts = {}
				for _, part in pairs(character:GetChildren()) do if part:IsA("BasePart") then table.insert(parts, part) end end
				local pos, size = getBoundingBox(parts)
				if pos and size then
					local defaultColor = Color3.fromRGB(255,0,0)
					local teamColor = Color3.fromRGB(0,120,255)
					local visibleEnemyColor = Color3.fromRGB(255,215,0)
					local visibleTeamColor = Color3.fromRGB(170,210,255)
					local isTeam = (player.Team == LocalPlayer.Team)

					-- visibility & behind-wall checks (use head or hrp)
					local checkPart = (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
					local visible = false
					local behindWall = false
					if checkPart then
						visible = partIsVisible(checkPart, player)
						behindWall = partIsBehindWall(checkPart, player) -- true if a non-character part is hit first
					end

					-- choose color priority:
					local boxColor = defaultColor

					-- If wall highlight mode active and player is behind a wall -> override to purple/pink
					if wallHighlightMode and behindWall then
						boxColor = isTeam and wallTeamColor or wallEnemyColor
					else
						-- else fall back to existing logic (visible color > team color > default)
						if visibleColorMode and visible then
							boxColor = isTeam and visibleTeamColor or visibleEnemyColor
						elseif teamColorMode and isTeam then
							boxColor = teamColor
						else
							boxColor = defaultColor
						end
					end

					-- Box outline & box
					if drawBoxes then
						draw.Outline.Position = Vector2.new(pos.X - 1.5, pos.Y - 1.5)
						draw.Outline.Size = Vector2.new(size.X + 3, size.Y + 3)
						draw.Outline.Visible = true

						draw.Box.Position = pos
						draw.Box.Size = size
						draw.Box.Color = boxColor
						draw.Box.Visible = true
					else
						draw.Outline.Visible = false
						draw.Box.Visible = false
					end

					-- Healthbar
					if drawHealth then
						local hpPercent = math.clamp(humanoid.Health / (humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100), 0, 1)
						local barWidth = 4
						local barHeight = size.Y * hpPercent
						local barX = pos.X + size.X + 2
						local barY = pos.Y + (size.Y - barHeight)

						draw.HealthBar.Position = Vector2.new(barX, barY)
						draw.HealthBar.Size = Vector2.new(barWidth, barHeight)
						draw.HealthBar.Visible = true
					else
						draw.HealthBar.Visible = false
					end

					-- Name ESP (above the box)
					if drawNames then
						local namePos = Vector2.new(pos.X + size.X/2, pos.Y - 8)
						-- outline (black)
						draw.NameOutline.Position = namePos
						draw.NameOutline.Text = player.Name
						draw.NameOutline.Size = 14
						draw.NameOutline.Center = true
						draw.NameOutline.Color = Color3.fromRGB(0,0,0)
						draw.NameOutline.Visible = true

						-- fill (white)
						draw.NameText.Position = namePos
						draw.NameText.Text = player.Name
						draw.NameText.Size = 14
						draw.NameText.Center = true
						draw.NameText.Color = Color3.fromRGB(255,255,255)
						draw.NameText.Visible = true
					else
						draw.NameOutline.Visible = false
						draw.NameText.Visible = false
					end

					-- Tracer
					if drawTracers then
						draw.Tracer.From = bottomCenter
						draw.Tracer.To = Vector2.new(pos.X + size.X/2, pos.Y + size.Y/2)
						draw.Tracer.Color = boxColor
						draw.Tracer.Visible = true
					else
						draw.Tracer.Visible = false
					end
				else
					draw.Outline.Visible = false
					draw.Box.Visible = false
					draw.HealthBar.Visible = false
					draw.NameOutline.Visible = false
					draw.NameText.Visible = false
					draw.Tracer.Visible = false
				end
			else
				-- no character or dead: hide
				if draw then
					draw.Outline.Visible = false
					draw.Box.Visible = false
					draw.HealthBar.Visible = false
					draw.NameOutline.Visible = false
					draw.NameText.Visible = false
					draw.Tracer.Visible = false
				end
			end
		end
	end

	-- ---------- Update head copies follow logic ----------
	local follow = followToggle()
	for player, data in pairs(headCopies) do
		if not data or not data.Part or not player or not player.Character then
			removeHeadCopyFor(player)
		else
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health <= 0 then
				removeHeadCopyFor(player)
			else
				if follow then
					local head = player.Character:FindFirstChild("Head")
					if head and head.Parent then
						local offsetY = (data.Part.Size.Y / 2) + 1.5
						local newPos = head.Position + Vector3.new(0, offsetY, 0)
						data.Part.CFrame = CFrame.new(newPos)
					end
				end
			end
		end
	end
end)

-- ---------- Cleanup ----------
local function cleanupAllHeads()
	for p,_ in pairs(headCopies) do removeHeadCopyFor(p) end
	humanBlocked = {}
end
game:BindToClose(function() cleanupAllHeads() end)

-- end of script
