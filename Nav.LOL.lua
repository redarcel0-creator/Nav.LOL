--// Nav.LOL

local plrs = game:GetService("Players")
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")

local lp = plrs.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local locked = false
local tgt = nil
local savedKey = "NAV_UI_POS"

local function hsv(h,s,v)
	local i = math.floor(h*6)
	local f = h*6 - i
	local p = v*(1-s)
	local q = v*(1-f*s)
	local t = v*(1-(1-f)*s)
	i = i%6
	if i==0 then return Color3.new(v,t,p)
	elseif i==1 then return Color3.new(q,v,p)
	elseif i==2 then return Color3.new(p,v,t)
	elseif i==3 then return Color3.new(p,q,v)
	elseif i==4 then return Color3.new(t,p,v)
	else return Color3.new(v,p,q) end
end

local function alive(p)
	if not p.Character then return false end
	local h = p.Character:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0
end

local function getClosest()
	local closest,dist
	local vp = cam.ViewportSize
	local mid = Vector2.new(vp.X/2,vp.Y/2)
	for _,p in pairs(plrs:GetPlayers()) do
		if p~=lp and alive(p) then
			local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local pos,on = cam:WorldToViewportPoint(hrp.Position)
				if on then
					local m = (Vector2.new(pos.X,pos.Y)-mid).Magnitude
					if not dist or m<dist then
						dist = m
						closest = p
					end
				end
			end
		end
	end
	return closest
end

local function respawnTrack(p,lbl)
	p.CharacterAdded:Connect(function()
		if p==tgt and locked then
			lbl.Text = "Target: "..p.Name.." (respawned)"
		end
	end)
end

-- Intro with RGB borders
local function intro()
	local scr = Instance.new("ScreenGui",gui)
	scr.Name = "NAV_INTRO"
	scr.ResetOnSpawn = false

	local f = Instance.new("Frame",scr)
	f.Size = UDim2.new(1,0,1,0)
	f.BackgroundColor3 = Color3.fromRGB(0,0,0)

	local borderThickness = 4
	local top = Instance.new("Frame", f)
	top.Size = UDim2.new(1,0,0,borderThickness)
	top.Position = UDim2.new(0,0,0,0)
	top.BackgroundColor3 = Color3.fromRGB(255,0,0)

	local bottom = Instance.new("Frame", f)
	bottom.Size = UDim2.new(1,0,0,borderThickness)
	bottom.Position = UDim2.new(0,0,1,-borderThickness)
	bottom.BackgroundColor3 = Color3.fromRGB(255,0,0)

	local left = Instance.new("Frame", f)
	left.Size = UDim2.new(0,borderThickness,1,0)
	left.Position = UDim2.new(0,0,0,0)
	left.BackgroundColor3 = Color3.fromRGB(255,0,0)

	local right = Instance.new("Frame", f)
	right.Size = UDim2.new(0,borderThickness,1,0)
	right.Position = UDim2.new(1,-borderThickness,0,0)
	right.BackgroundColor3 = Color3.fromRGB(255,0,0)

	local txt = Instance.new("TextLabel",f)
	txt.AnchorPoint = Vector2.new(0.5,0.5)
	txt.Position = UDim2.new(0.5,0,0.5,0)
	txt.Size = UDim2.new(0.8,0,0.3,0)
	txt.Font = Enum.Font.GothamBlack
	txt.TextScaled = true
	txt.BackgroundTransparency = 1
	txt.TextTransparency = 1
	txt.Text = ""

	local hue = 0
	local conn
	conn = run.RenderStepped:Connect(function(dt)
		hue = (hue + dt*0.5)%1
		local color = hsv(hue,1,1)
		top.BackgroundColor3 = color
		bottom.BackgroundColor3 = color
		left.BackgroundColor3 = color
		right.BackgroundColor3 = color
		txt.TextColor3 = hsv((hue+0.2)%1,1,1)
	end)

	local function fadeText(label, text)
		label.Text = text
		local t = 1
		while t >= 0 do
			label.TextTransparency = t
			t = t - 0.05
			task.wait(0.05)
		end
		task.wait(0.5)
		t = 0
		while t <= 1 do
			label.TextTransparency = t
			t = t + 0.05
			task.wait(0.05)
		end
	end

	fadeText(txt, "Introducing")
	fadeText(txt, "Nav.LOL")

	conn:Disconnect()
	scr:Destroy()
end

-- Main UI with original size and RGB
local function makeUI()
	local scr = Instance.new("ScreenGui",gui)
	scr.Name = "NAV_UI"
	scr.ResetOnSpawn = false

	local btn = Instance.new("TextButton",scr)
	btn.Size = UDim2.new(0,200,0,50) -- restored original size
	btn.BackgroundColor3 = Color3.fromRGB(25,25,25) -- keep black background
	btn.BorderColor3 = Color3.fromRGB(0,120,255) -- original RGB style
	btn.BorderSizePixel = 3
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 18
	btn.Text = "Nav.LOL"
	btn.TextColor3 = Color3.new(1,1,1)

	local save = getshared and getshared(savedKey)
	if save and typeof(save)=="UDim2" then
		btn.Position = save
	else
		btn.Position = UDim2.new(0,15,0,15)
	end

	local lbl = Instance.new("TextLabel",btn)
	lbl.AnchorPoint = Vector2.new(0,1)
	lbl.Position = UDim2.new(0,5,1,-3)
	lbl.Size = UDim2.new(1,-10,0,14)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 12
	lbl.TextColor3 = Color3.fromRGB(200,200,200)
	lbl.Text = "No target"

	local dragging=false
	local dragStart,posStart
	local activeTouch=nil
	local function upd(i)
		local d = i.Position - dragStart
		btn.Position = UDim2.new(posStart.X.Scale,posStart.X.Offset+d.X,posStart.Y.Scale,posStart.Y.Offset+d.Y)
	end

	btn.InputBegan:Connect(function(i)
		if (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1) and not activeTouch then
			activeTouch = i
			dragging=true
			dragStart=i.Position
			posStart=btn.Position

			local move,stop
			move = uis.InputChanged:Connect(function(m)
				if dragging and (m==activeTouch) then
					upd(m)
				end
			end)

			stop = i.Changed:Connect(function()
				if i.UserInputState==Enum.UserInputState.End then
					dragging=false
					activeTouch=nil
					move:Disconnect()
					stop:Disconnect()
					if setshared then setshared(savedKey,btn.Position) end
				end
			end)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		locked=not locked
		if locked then
			tgt=getClosest()
			if tgt then
				lbl.Text="Target: "..tgt.Name
				respawnTrack(tgt,lbl)
			else
				lbl.Text="No valid target"
			end
		else
			tgt=nil
			lbl.Text="No target"
		end
	end)

	run.RenderStepped:Connect(function()
		local h=(tick()*0.25)%1
		local color = hsv(h,1,1)
		btn.BorderColor3 = color
		btn.TextColor3 = hsv((h+0.5)%1,1,1)
		lbl.TextColor3 = hsv((h+0.2)%1,1,1)

		if locked and tgt and alive(tgt) then
			local prt = tgt.Character:FindFirstChild("HumanoidRootPart") or tgt.Character:FindFirstChild("Head")
			if prt then
				cam.CFrame = CFrame.new(cam.CFrame.Position, prt.Position)
			end
		end
	end)
end

intro()
makeUI()
