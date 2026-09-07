local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remotes=RS:WaitForChild("VelocityRemotes")
local inputEvent,stateEvent,itemEvent=remotes.Input,remotes.State,remotes.UseItem

local gui=Instance.new("ScreenGui"); gui.Name="VelocityHUD"; gui.ResetOnSpawn=false; gui.Parent=player.PlayerGui
local function label(name,text,size,pos,fontSize)
    local l=Instance.new("TextLabel"); l.Name=name; l.Text=text; l.Size=size; l.Position=pos; l.BackgroundTransparency=1
    l.TextColor3=Color3.new(1,1,1); l.TextStrokeTransparency=.25; l.Font=Enum.Font.GothamBlack; l.TextScaled=false; l.TextSize=fontSize; l.Parent=gui; return l
end
local title=label("Title","VELOCITY RIVALS",UDim2.fromOffset(360,50),UDim2.fromOffset(22,14),28); title.TextXAlignment=Enum.TextXAlignment.Left
local lap=label("Lap","LAP 1 / 3",UDim2.fromOffset(230,55),UDim2.new(0,22,0,64),25); lap.TextXAlignment=Enum.TextXAlignment.Left
local speed=label("Speed","000",UDim2.fromOffset(220,95),UDim2.new(1,-245,1,-125),64); speed.TextXAlignment=Enum.TextXAlignment.Right
local unit=label("Unit","KPH",UDim2.fromOffset(100,30),UDim2.new(1,-125,1,-48),18)
local count=label("Countdown","",UDim2.fromScale(.35,.25),UDim2.fromScale(.325,.3),84)
local item=label("Item","NO ITEM",UDim2.fromOffset(260,62),UDim2.new(1,-285,0,22),23)
item.BackgroundTransparency=.15; item.BackgroundColor3=Color3.fromRGB(20,20,32)
local hint=label("Hint","WASD / arrows · Shift drift · E item · R reset",UDim2.new(1,-40,0,34),UDim2.new(0,20,1,-42),17)
local driftBg=Instance.new("Frame"); driftBg.Size=UDim2.fromOffset(220,10); driftBg.Position=UDim2.new(.5,-110,1,-62); driftBg.BackgroundColor3=Color3.fromRGB(30,35,45); driftBg.Parent=gui
local drift=Instance.new("Frame"); drift.Size=UDim2.fromScale(0,1); drift.BackgroundColor3=Color3.fromRGB(0,240,205); drift.Parent=driftBg

local held={}; local touchThrottle,touchSteer=0,0
UIS.InputBegan:Connect(function(i,g) if g then return end held[i.KeyCode]=true if i.KeyCode==Enum.KeyCode.E then itemEvent:FireServer() end end)
UIS.InputEnded:Connect(function(i) held[i.KeyCode]=nil end)

local function mobileButton(text,pos,callback)
    local b=Instance.new("TextButton"); b.Text=text; b.Size=UDim2.fromOffset(76,76); b.Position=pos; b.BackgroundColor3=Color3.fromRGB(20,24,35); b.BackgroundTransparency=.2; b.TextColor3=Color3.new(1,1,1); b.TextSize=28; b.Font=Enum.Font.GothamBold; b.Parent=gui
    b.InputBegan:Connect(function() callback(true) end); b.InputEnded:Connect(function() callback(false) end); return b
end
if UIS.TouchEnabled then
    hint.Visible=false
    mobileButton("◀",UDim2.new(0,18,1,-100),function(v) touchSteer=v and -1 or 0 end)
    mobileButton("▶",UDim2.new(0,104,1,-100),function(v) touchSteer=v and 1 or 0 end)
    mobileButton("▲",UDim2.new(1,-180,1,-100),function(v) touchThrottle=v and 1 or 0 end)
    mobileButton("ITEM",UDim2.new(1,-94,1,-100),function(v) if v then itemEvent:FireServer() end end)
end

task.spawn(function() while task.wait(.05) do
    local forward=(held[Enum.KeyCode.W] or held[Enum.KeyCode.Up]) and 1 or 0
    local backward=(held[Enum.KeyCode.S] or held[Enum.KeyCode.Down]) and 1 or 0
    local right=(held[Enum.KeyCode.D] or held[Enum.KeyCode.Right]) and 1 or 0
    local left=(held[Enum.KeyCode.A] or held[Enum.KeyCode.Left]) and 1 or 0
    local throttle=touchThrottle+forward-backward
    local steer=touchSteer+right-left
    inputEvent:FireServer({throttle=math.clamp(throttle,-1,1),steer=math.clamp(steer,-1,1),drift=held[Enum.KeyCode.LeftShift] or held[Enum.KeyCode.RightShift],reset=held[Enum.KeyCode.R]})
end end)

stateEvent.OnClientEvent:Connect(function(data)
    if data.type=="tick" then speed.Text=string.format("%03d",data.speed); lap.Text="LAP "..data.lap.." / 3"; drift.Size=UDim2.fromScale(data.drift,1)
    elseif data.type=="countdown" then count.Text=tostring(data.value); task.delay(.75,function() if count.Text==tostring(data.value) then count.Text="" end end)
    elseif data.type=="item" then item.Text=data.item or "NO ITEM"
    elseif data.type=="finish" then count.Text="#"..data.place.." FINISH\n"..string.format("%.2fs",data.time); count.TextSize=54
    end
end)
