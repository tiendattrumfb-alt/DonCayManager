--[[ Info HUD (Bold Everything + Boot Note) • Blue Glass • autosave per-account
     • no JobId autosave • Timer auto start • Time+FPS bold RichText
     • Blur glass background • Setting tab restored • Teleport boot note
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

local function now() return time() end
local function notify(t) pcall(function()
  StarterGui:SetCore("SendNotification",{Title="Thông báo";Text=t;Duration=2})
end) end

-- ===== storage per-account =====
local FOLDER="ram_orders"
if makefolder and (not isfolder or not isfolder(FOLDER)) then pcall(function() makefolder(FOLDER) end) end
local STORE_FILE=("%s/ram_order_%s.json"):format(FOLDER,LP.Name)
local can_write=(writefile and readfile and isfile) and true or false
local qot=(syn and syn.queue_on_teleport) or queue_on_teleport
local function jencode(t) return HttpService:JSONEncode(t) end
local function jdecode(s) local ok,r=pcall(function() return HttpService:JSONDecode(s) end) return ok and r or nil end
local function deepcopy(t) local r={} for k,v in pairs(t) do r[k]=type(v)=="table" and deepcopy(v) or v end return r end

local DEFAULT={description="",status="Đang làm",elapsed=0,run_since=nil}
getgenv().RAM_ORDER=getgenv().RAM_ORDER or deepcopy(DEFAULT)
local function saveData(d) d=d or getgenv().RAM_ORDER if can_write then pcall(function() writefile(STORE_FILE,jencode(d)) end) else getgenv().RAM_ORDER=deepcopy(d) end end
local function loadData()
  if can_write and isfile and isfile(STORE_FILE) then
    local ok,res=pcall(function() return jdecode(readfile(STORE_FILE)) end)
    if ok and type(res)=="table" then for k,v in pairs(DEFAULT) do if res[k]==nil then res[k]=v end end getgenv().RAM_ORDER=res return res end
  end
  return getgenv().RAM_ORDER
end

local DATA=loadData()
DATA.run_since=now(); DATA.status="Đang làm"; saveData(DATA)

-- ===== THEME =====
local C={
  glassBG=Color3.fromRGB(20,22,28),
  glassAlpha=0.38,
  stroke=Color3.fromRGB(255,205,95),
  pillActive=Color3.fromRGB(70,150,255),
  pillOff=Color3.fromRGB(70,72,90),
  text=Color3.fromRGB(240,240,248),
  sub=Color3.fromRGB(205,210,225),
  gold=Color3.fromRGB(255,220,120),
  inputBG=Color3.fromRGB(44,46,60),
  inputStroke=Color3.fromRGB(255,205,95),
}
local function tween(o,p,t) TweenService:Create(o,TweenInfo.new(t or .12,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),p):Play() end

-- ===== UI ROOT =====
local sg=Instance.new("ScreenGui") sg.Name="HUD_Info" sg.ResetOnSpawn=false
if syn and syn.protect_gui then pcall(syn.protect_gui,sg) end
sg.Parent=(gethui and gethui()) or game:GetService("CoreGui")

local blur=Instance.new("BlurEffect",Lighting) blur.Size=4

local holder=Instance.new("Frame",sg)
holder.Size=UDim2.fromOffset(360,190)
holder.Position=UDim2.new(0,40,0,120)
holder.BackgroundColor3=C.glassBG
holder.BackgroundTransparency=C.glassAlpha
Instance.new("UICorner",holder).CornerRadius=UDim.new(0,14)
local stroke=Instance.new("UIStroke",holder) stroke.Color=C.stroke stroke.Thickness=1.4 stroke.Transparency=0.18

-- header tabs
local header=Instance.new("Frame",holder) header.BackgroundTransparency=1
header.Size=UDim2.new(1,-20,0,34) header.Position=UDim2.new(0,10,0,8)
local function pill(text,x,active)
  local b=Instance.new("TextButton",header) b.Size=UDim2.fromOffset(140,26) b.Position=UDim2.new(0,x,0,4)
  b.Font=Enum.Font.GothamBold b.TextSize=13 b.Text=text b.AutoButtonColor=false
  b.TextColor3=active and Color3.fromRGB(255,255,255) or C.sub
  b.BackgroundColor3=active and C.pillActive or C.pillOff
  Instance.new("UICorner",b).CornerRadius=UDim.new(0,9)
  local s=Instance.new("UIStroke",b) s.Color=active and Color3.fromRGB(150,200,255) or Color3.fromRGB(90,90,110) s.Thickness=1
  b.MouseEnter:Connect(function() tween(b,{BackgroundColor3=active and Color3.fromRGB(100,170,255) or Color3.fromRGB(82,84,104)}) end)
  b.MouseLeave:Connect(function() tween(b,{BackgroundColor3=active and C.pillActive or C.pillOff}) end)
  return b
end
local tabInfo=pill("Information",20,true)
local tabSetting=pill("Setting",180,false)

local pageInfo=Instance.new("Frame",holder) pageInfo.BackgroundTransparency=1
pageInfo.Size=UDim2.new(1,-20,1,-68) pageInfo.Position=UDim2.new(0,10,0,44)
local pageSetting=Instance.new("Frame",holder) pageSetting.BackgroundTransparency=1
pageSetting.Size=pageInfo.Size pageSetting.Position=pageInfo.Position pageSetting.Visible=false

local function switch(onInfo)
  pageInfo.Visible=onInfo pageSetting.Visible=not onInfo
  if onInfo then
    tabInfo.BackgroundColor3=C.pillActive; tabInfo.TextColor3=Color3.fromRGB(255,255,255)
    tabSetting.BackgroundColor3=C.pillOff; tabSetting.TextColor3=C.sub
  else
    tabInfo.BackgroundColor3=C.pillOff; tabInfo.TextColor3=C.sub
    tabSetting.BackgroundColor3=C.pillActive; tabSetting.TextColor3=Color3.fromRGB(255,255,255)
  end
end
tabInfo.MouseButton1Click:Connect(function() switch(true) end)
tabSetting.MouseButton1Click:Connect(function() switch(false) end)

-- Username / Task / Time
local function mkLabelRow(parent,label,y)
  local lb=Instance.new("TextLabel",parent)
  lb.Position=UDim2.new(0,0,0,y)
  lb.Size=UDim2.new(0,120,0,22)
  lb.BackgroundTransparency=1
  lb.Font=Enum.Font.GothamBold lb.TextSize=16
  lb.TextXAlignment=Enum.TextXAlignment.Left lb.TextColor3=C.text
  lb.Text=label return lb
end
mkLabelRow(pageInfo,"Username:",0)
local uiUser=Instance.new("TextLabel",pageInfo)
uiUser.Position=UDim2.new(0,120,0,0)
uiUser.Size=UDim2.new(1,-120,0,22)
uiUser.BackgroundTransparency=1 uiUser.Font=Enum.Font.GothamBold uiUser.TextSize=16
uiUser.TextXAlignment=Enum.TextXAlignment.Left uiUser.TextColor3=Color3.fromRGB(255,120,120)
uiUser.Text=(#LP.Name<=4 and LP.Name.."****") or (LP.Name:sub(1,4).."****")

mkLabelRow(pageInfo,"Task:",24)
local uiTask=Instance.new("TextButton",pageInfo)
uiTask.Position=UDim2.new(0,120,0,24)
uiTask.Size=UDim2.new(1,-120,0,22)
uiTask.BackgroundTransparency=1 uiTask.Font=Enum.Font.GothamBold uiTask.TextSize=16
uiTask.TextXAlignment=Enum.TextXAlignment.Left uiTask.TextColor3=C.gold
uiTask.Text=(DATA.description~="" and DATA.description or "—")
uiTask.AutoButtonColor=false uiTask.ZIndex=10
uiTask.MouseButton1Click:Connect(function()
  local tb=Instance.new("TextBox",pageInfo) tb.ZIndex=11 tb.Position=UDim2.new(0,120,0,24)
  tb.Size=UDim2.fromOffset(220,22) tb.BackgroundColor3=C.inputBG tb.Font=Enum.Font.Gotham tb.TextSize=15
  tb.TextColor3=C.text tb.PlaceholderText="Nhập Task..." tb.PlaceholderColor3=Color3.fromRGB(170,175,190)
  tb.Text=DATA.description tb.ClearTextOnFocus=false Instance.new("UICorner",tb).CornerRadius=UDim.new(0,8)
  local st=Instance.new("UIStroke",tb) st.Color=C.inputStroke
  tb:CaptureFocus() tb.FocusLost:Connect(function()
    DATA.description=tb.Text uiTask.Text=(DATA.description~="" and DATA.description or "—") saveData(DATA) tb:Destroy()
  end)
end)

mkLabelRow(pageInfo,"Time:",48)
local timeValue=Instance.new("TextLabel",pageInfo)
timeValue.Position=UDim2.new(0,120,0,48) timeValue.Size=UDim2.new(1,-120,0,26)
timeValue.BackgroundTransparency=1 timeValue.Font=Enum.Font.GothamBold timeValue.TextSize=20
timeValue.TextXAlignment=Enum.TextXAlignment.Left timeValue.TextColor3=C.text timeValue.RichText=true
timeValue.Text="0m 00s   •   FPS: <b>0</b>"

-- JobId bar
local jobWrap=Instance.new("Frame",holder) jobWrap.Size=UDim2.new(1,-20,0,30)
jobWrap.Position=UDim2.new(0,10,1,-38) jobWrap.BackgroundColor3=C.inputBG
Instance.new("UICorner",jobWrap).CornerRadius=UDim.new(0,9)
local jobStroke=Instance.new("UIStroke",jobWrap) jobStroke.Color=C.inputStroke jobStroke.Transparency=0.2
local jobBox=Instance.new("TextBox",jobWrap) jobBox.BackgroundTransparency=1 jobBox.Size=UDim2.new(1,-16,1,-6)
jobBox.Position=UDim2.new(0,8,0,3) jobBox.Font=Enum.Font.GothamBold jobBox.TextSize=15
jobBox.TextXAlignment=Enum.TextXAlignment.Center jobBox.TextColor3=C.text jobBox.PlaceholderText="JobId"
jobBox.PlaceholderColor3=Color3.fromRGB(170,175,190) jobBox.ClearTextOnFocus=false jobBox.Text=""
jobBox.FocusLost:Connect(function(enter)
  if enter then local j=jobBox.Text:gsub("%s+","")
    if j=="" then notify("Chưa nhập JobId") else TeleportService:TeleportToPlaceInstance(game.PlaceId,j,LP) end end
end)

-- Setting page
local function mkSmallLbl(parent,t,y)
  local lb=Instance.new("TextLabel",parent) lb.Position=UDim2.new(0,0,0,y) lb.Size=UDim2.new(0,90,0,22)
  lb.BackgroundTransparency=1 lb.Font=Enum.Font.Gotham lb.TextSize=14 lb.TextXAlignment=Enum.TextXAlignment.Left lb.TextColor3=C.sub lb.Text=t
end
mkSmallLbl(pageSetting,"Đơn",0)
local tbTask=Instance.new("TextBox",pageSetting)
tbTask.Position=UDim2.new(0,90,0,0) tbTask.Size=UDim2.fromOffset(220,22)
tbTask.BackgroundColor3=C.inputBG tbTask.Font=Enum.Font.Gotham tbTask.TextSize=15 tbTask.TextColor3=C.text
tbTask.ClearTextOnFocus=false tbTask.PlaceholderText="Nhập Task..." tbTask.PlaceholderColor3=Color3.fromRGB(160,165,180)
tbTask.Text=DATA.description Instance.new("UICorner",tbTask).CornerRadius=UDim.new(0,8) local tbS=Instance.new("UIStroke",tbTask) tbS.Color=C.inputStroke
tbTask.FocusLost:Connect(function() DATA.description=tbTask.Text uiTask.Text=(DATA.description~="" and DATA.description or "—") saveData(DATA) end)

mkSmallLbl(pageSetting,"Trạng thái",24)
local statusBtn=Instance.new("TextButton",pageSetting) statusBtn.Position=UDim2.new(0,90,0,24)
statusBtn.Size=UDim2.fromOffset(160,22) statusBtn.Font=Enum.Font.GothamBold statusBtn.TextSize=14
statusBtn.TextColor3=C.text statusBtn.AutoButtonColor=true Instance.new("UICorner",statusBtn).CornerRadius=UDim.new(0,8)
local statusStroke=Instance.new("UIStroke",statusBtn) statusStroke.Thickness=1
local STATUS={"Đang làm","Tạm dừng","Hoàn thành"}
local STYLE={["Đang làm"]={bg=C.pillActive,stroke=Color3.fromRGB(150,200,255)},["Tạm dừng"]={bg=Color3.fromRGB(255,185,70),stroke=Color3.fromRGB(255,210,125)},["Hoàn thành"]={bg=Color3.fromRGB(70,190,120),stroke=Color3.fromRGB(110,230,170)}}
local function applyStatus(s)local st=STYLE[s] or STYLE["Đang làm"] statusBtn.Text=s statusBtn.BackgroundColor3=st.bg statusStroke.Color=st.stroke end
local sidx=1 for i,v in ipairs(STATUS) do if v==DATA.status then sidx=i end end applyStatus(DATA.status)
local function startTimer() DATA.run_since=now() saveData(DATA) end
local function pauseTimer() if DATA.run_since then DATA.elapsed=math.max(0,(DATA.elapsed or 0)+(now()-DATA.run_since)) DATA.run_since=nil saveData(DATA) end end
statusBtn.MouseButton1Click:Connect(function() sidx=sidx%#STATUS+1 DATA.status=STATUS[sidx] applyStatus(DATA.status) if DATA.status=="Đang làm" then startTimer() else pauseTimer() end end)

-- LOOP
local acc,frames,fps=0,0,60
local function fmtTime(t)t=math.max(0,math.floor(t+0.5))local m=math.floor((t%3600)/60)local s=t%60 return string.format("<b>%dm %02ds</b>",m,s)end
local function fpsRGB(f)if f<40 then return"235,80,80"elseif f<80 then return"240,190,70"else return"70,190,110"end end
RunService.RenderStepped:Connect(function(dt)acc+=dt;frames+=1;if acc>=0.5 then fps=math.floor(frames/acc+0.5)acc=0 frames=0 end local e=DATA.elapsed or 0 if DATA.run_since then e=e+math.max(0,now()-DATA.run_since)end timeValue.Text=string.format('%s   •   FPS: <font color="rgb(%s)"><b>%d</b></font>',fmtTime(e),fpsRGB(fps),fps)end)

-- DRAG
local UIS=game:GetService("UserInputService")local dragging,dragStart,startPos=false,nil,nil
holder.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true dragStart=i.Position startPos=holder.Position end end)
holder.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
UIS.InputChanged:Connect(function(i)if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dragStart holder.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)end end)

-- Boot note on teleport (no JobId save)
if qot then
  local BOOT = (string.format([[
local HttpService=game:GetService("HttpService")
local f="%s"; local c=(writefile and readfile and isfile) and true or false; local d={}
if c and isfile and isfile(f) then local ok,r=pcall(function()return HttpService:JSONDecode(readfile(f))end) if ok and type(r)=="table"then d=r end end
getgenv().RAM_ORDER=d
local sg=Instance.new("ScreenGui",game:GetService("CoreGui"))
local t=Instance.new("TextLabel",sg)
t.Size=UDim2.new(0,300,0,56); t.Position=UDim2.new(0,26,0,96)
t.BackgroundColor3=Color3.fromRGB(18,20,26); t.BackgroundTransparency=0.38
Instance.new("UICorner",t).CornerRadius=UDim.new(0,10)
t.Font=Enum.Font.Gotham; t.TextSize=14; t.TextColor3=Color3.fromRGB(230,230,240); t.TextWrapped=true
t.Text=string.format("Đơn: %s | Trạng thái: %s", d.description or "", d.status or "")
  ]], STORE_FILE))
  LP.OnTeleport:Connect(function(state)
    if state==Enum.TeleportState.Started then
      if DATA.run_since then DATA.elapsed=math.max(0,(DATA.elapsed or 0)+(now()-DATA.run_since)) DATA.run_since=nil end
      saveData(DATA); pcall(function() qot(BOOT) end)
    end
  end)
end
