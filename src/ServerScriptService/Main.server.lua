local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)

local remotes = Instance.new("Folder")
remotes.Name = "VelocityRemotes"
remotes.Parent = ReplicatedStorage
local inputEvent = Instance.new("RemoteEvent"); inputEvent.Name = "Input"; inputEvent.Parent = remotes
local stateEvent = Instance.new("RemoteEvent"); stateEvent.Name = "State"; stateEvent.Parent = remotes
local itemEvent = Instance.new("RemoteEvent"); itemEvent.Name = "UseItem"; itemEvent.Parent = remotes

local world = Instance.new("Folder"); world.Name = "VelocityWorld"; world.Parent = workspace

local function part(name, size, cf, color, material, parent)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame = name, size, cf
    p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
    p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent or world
    return p
end

-- Neon harbour circuit: broad enough for overtaking, with an infield lake.
part("Ground", Vector3.new(620, 4, 460), CFrame.new(0, -4, 0), Color3.fromRGB(23, 30, 43), Enum.Material.Slate)
part("Lake", Vector3.new(240, 1, 155), CFrame.new(0, -1.4, 0), Color3.fromRGB(17, 117, 168), Enum.Material.Glass)

local waypoints = {
    Vector3.new(-210,0,125), Vector3.new(0,0,125), Vector3.new(205,0,110),
    Vector3.new(240,0,0), Vector3.new(195,0,-120), Vector3.new(0,0,-150),
    Vector3.new(-205,0,-115), Vector3.new(-245,0,0),
}

local function roadBetween(a,b)
    local mid=(a+b)/2; local length=(b-a).Magnitude
    local road=part("Road",Vector3.new(76,2,length),CFrame.lookAt(mid+Vector3.new(0,0.1,0),b),Color3.fromRGB(48,52,63),Enum.Material.Asphalt)
    part("Stripe",Vector3.new(1,2.05,length),road.CFrame,Color3.fromRGB(255,205,54),Enum.Material.Neon)
end
for i=1,#waypoints do roadBetween(waypoints[i],waypoints[i%#waypoints+1]) end

local checkpoints = {}
for i,p in ipairs(waypoints) do
    local nextP=waypoints[i%#waypoints+1]
    local cp=part("Checkpoint"..i,Vector3.new(76,12,5),CFrame.lookAt(p+Vector3.new(0,5,0),nextP),Color3.fromRGB(0,220,255),Enum.Material.Neon)
    cp.Transparency= i==1 and 0.25 or 1; cp.CanCollide=false
    cp:SetAttribute("Index",i); checkpoints[i]=cp
end
checkpoints[1].Color=Color3.fromRGB(255,255,255)

for i,p in ipairs({Vector3.new(65,2,125),Vector3.new(215,2,-65),Vector3.new(-70,2,-150),Vector3.new(-240,2,45)}) do
    local box=part("ItemBox",Vector3.new(7,7,7),CFrame.new(p)*CFrame.Angles(0,math.rad(45),math.rad(45)),Color3.fromRGB(187,73,255),Enum.Material.Neon)
    box.CanCollide=false; box:SetAttribute("ItemBox",true)
end
for _,p in ipairs({Vector3.new(150,1.4,122),Vector3.new(-155,1.4,-135)}) do
    local pad=part("BoostPad",Vector3.new(24,0.5,12),CFrame.new(p),Color3.fromRGB(0,255,190),Enum.Material.Neon)
    pad:SetAttribute("BoostPad",true)
end

local race = {started=false, startAt=0, racers={}, finishCount=0}
local colours={Color3.fromRGB(255,68,68),Color3.fromRGB(34,181,255),Color3.fromRGB(255,196,49),Color3.fromRGB(79,235,126),Color3.fromRGB(194,92,255),Color3.fromRGB(255,116,33)}

local function createKart(player,index)
    local model=Instance.new("Model"); model.Name=player.Name.."_Kart"; model.Parent=world
    local chassis=part("Chassis",Vector3.new(7,1.5,10),CFrame.new(-210+(index-1)*10,3,125),colours[(index-1)%#colours+1],Enum.Material.Metal,model)
    chassis.Anchored=false; chassis.CustomPhysicalProperties=PhysicalProperties.new(0.8,0.25,0.1)
    local seat=Instance.new("VehicleSeat"); seat.Name="DriverSeat"; seat.Size=Vector3.new(4,1,4); seat.CFrame=chassis.CFrame*CFrame.new(0,1.3,0.5); seat.Color=chassis.Color; seat.Parent=model
    local weld=Instance.new("WeldConstraint"); weld.Part0=chassis; weld.Part1=seat; weld.Parent=seat
    for _,x in ipairs({-3.8,3.8}) do for _,z in ipairs({-3.1,3.1}) do
        local w=Instance.new("Part"); w.Shape=Enum.PartType.Cylinder; w.Size=Vector3.new(2.2,2.2,1.2); w.Color=Color3.new(.03,.03,.04); w.Material=Enum.Material.Rubber
        w.CFrame=chassis.CFrame*CFrame.new(x,-.3,z)*CFrame.Angles(0,0,math.rad(90)); w.CanCollide=false; w.Parent=model
        local ww=Instance.new("WeldConstraint"); ww.Part0=chassis; ww.Part1=w; ww.Parent=w
    end end
    local gyro=Instance.new("BodyGyro"); gyro.MaxTorque=Vector3.new(0,math.huge,0); gyro.P=8500; gyro.D=700; gyro.CFrame=chassis.CFrame; gyro.Parent=chassis
    local vel=Instance.new("BodyVelocity"); vel.MaxForce=Vector3.new(90000,0,90000); vel.P=3000; vel.Parent=chassis
    model.PrimaryPart=chassis
    return model,seat,gyro,vel
end

local function resetPlayer(player)
    local r=race.racers[player]; if not r then return end
    local p=waypoints[math.max(1,r.checkpoint)]
    local n=waypoints[math.max(1,r.checkpoint)%#waypoints+1]
    r.kart:PivotTo(CFrame.lookAt(p+Vector3.new(0,4,0),n)); r.speed=0
end

local function addPlayer(player)
    local index=0; for _ in pairs(race.racers) do index+=1 end; index+=1
    local kart,seat,gyro,vel=createKart(player,index)
    race.racers[player]={kart=kart,seat=seat,gyro=gyro,vel=vel,speed=0,steer=0,throttle=0,drift=false,driftCharge=0,boostUntil=0,checkpoint=1,lap=1,item=nil,finished=false}
    player.CharacterAdded:Connect(function(char)
        task.wait(.25); local hum=char:FindFirstChildOfClass("Humanoid"); if hum then seat:Sit(hum) end
    end)
    if player.Character then local hum=player.Character:FindFirstChildOfClass("Humanoid"); if hum then seat:Sit(hum) end end
    task.delay(2,function() stateEvent:FireClient(player,{type="joined",laps=Config.Laps}) end)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(p) local r=race.racers[p]; if r then r.kart:Destroy(); race.racers[p]=nil end end)
for _,p in ipairs(Players:GetPlayers()) do addPlayer(p) end

inputEvent.OnServerEvent:Connect(function(player,data)
    local r=race.racers[player]; if not r or typeof(data)~="table" then return end
    r.throttle=math.clamp(tonumber(data.throttle) or 0,-1,1)
    r.steer=math.clamp(tonumber(data.steer) or 0,-1,1)
    r.drift=data.drift==true
    if data.reset then resetPlayer(player) end
end)

itemEvent.OnServerEvent:Connect(function(player)
    local r=race.racers[player]; if not r or not r.item or os.clock()<(r.itemReady or 0) then return end
    r.itemReady=os.clock()+Config.ItemCooldown
    if r.item=="TURBO" then r.boostUntil=os.clock()+1.8
    elseif r.item=="SHOCKWAVE" then
        for p,other in pairs(race.racers) do if p~=player and (other.kart.PrimaryPart.Position-r.kart.PrimaryPart.Position).Magnitude<32 then other.speed*=.25 end end
    elseif r.item=="BARRIER" then r.shieldUntil=os.clock()+4 end
    r.item=nil; stateEvent:FireClient(player,{type="item",item=false})
end)

local items={"TURBO","TURBO","SHOCKWAVE","BARRIER"}
for _,obj in ipairs(world:GetChildren()) do if obj:GetAttribute("ItemBox") then obj.Touched:Connect(function(hit)
    local model=hit:FindFirstAncestorOfClass("Model")
    for player,r in pairs(race.racers) do if model==r.kart and not r.item and obj.Transparency<1 then
        r.item=items[math.random(#items)]; obj.Transparency=1; stateEvent:FireClient(player,{type="item",item=r.item})
        task.delay(4,function() if obj then obj.Transparency=0 end end)
    end end
end) elseif obj:GetAttribute("BoostPad") then obj.Touched:Connect(function(hit)
    local model=hit:FindFirstAncestorOfClass("Model"); for _,r in pairs(race.racers) do if model==r.kart then r.boostUntil=os.clock()+.75 end end
end) end end

task.spawn(function()
    while #Players:GetPlayers()==0 do task.wait(1) end
    for n=Config.Countdown,1,-1 do stateEvent:FireAllClients({type="countdown",value=n}); task.wait(1) end
    race.started=true; race.startAt=os.clock(); stateEvent:FireAllClients({type="countdown",value="GO!"})
end)

RunService.Heartbeat:Connect(function(dt)
    for player,r in pairs(race.racers) do
        local root=r.kart.PrimaryPart
        if root.Position.Y < -12 then resetPlayer(player) end
        local allowed=race.started and not r.finished
        local target=allowed and (r.throttle>=0 and r.throttle*Config.TopSpeed or r.throttle*Config.ReverseSpeed) or 0
        if os.clock()<r.boostUntil then target+=Config.DriftBoost end
        r.speed += (target-r.speed)*math.min(1,Config.Acceleration*dt)
        if r.drift and math.abs(r.steer)>.25 and math.abs(r.speed)>25 then r.driftCharge+=dt else
            if r.driftCharge>=Config.DriftChargeTime then r.boostUntil=os.clock()+Config.DriftBoostTime end
            r.driftCharge=0
        end
        local turn=r.steer*Config.Steering*dt*math.clamp(math.abs(r.speed)/25,.2,1)*(r.speed>=0 and 1 or -1)
        r.gyro.CFrame=r.gyro.CFrame*CFrame.Angles(0,-turn,0)
        local forward=r.gyro.CFrame.LookVector
        r.vel.Velocity=Vector3.new(forward.X,0,forward.Z)*r.speed
        local nextIndex=r.checkpoint%#checkpoints+1
        if (root.Position-checkpoints[nextIndex].Position).Magnitude<48 then
            r.checkpoint=nextIndex
            if nextIndex==1 then
                r.lap+=1
                if r.lap>Config.Laps then r.finished=true; race.finishCount+=1; r.speed=0; stateEvent:FireClient(player,{type="finish",place=race.finishCount,time=os.clock()-race.startAt})
                else stateEvent:FireClient(player,{type="lap",lap=r.lap}) end
            end
        end
        local progress=(r.lap-1)*#checkpoints+r.checkpoint
        stateEvent:FireClient(player,{type="tick",speed=math.floor(math.abs(r.speed)),lap=math.min(r.lap,Config.Laps),progress=progress,drift=math.min(1,r.driftCharge/Config.DriftChargeTime)})
    end
end)
