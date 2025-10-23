-- [[ Quản lý đơn cày – tối giản, auto-save, per-account, colored status ]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- Folder + file riêng mỗi acc
local FOLDER = "ram_orders"
if makefolder and (not isfolder or not isfolder(FOLDER)) then pcall(function() makefolder(FOLDER) end) end
local STORE_FILE = ("%s/ram_order_%s.json"):format(FOLDER, LP.Name)

local can_write = (writefile and readfile and isfile) and true or false
local qot = (syn and syn.queue_on_teleport) or queue_on_teleport

local function jencode(t) return HttpService:JSONEncode(t) end
local function jdecode(s) local ok,r=pcall(function() return HttpService:JSONDecode(s) end) return ok and r or nil end
local function deepcopy(t) local r={} for k,v in pairs(t) do r[k]=type(v)=="table" and deepcopy(v) or v end return r end

local DEFAULT = { description = "", status = "Đang làm" }
getgenv().RAM_ORDER = getgenv().RAM_ORDER or deepcopy(DEFAULT)

local function saveData(d)
  d = d or getgenv().RAM_ORDER
  if can_write then pcall(function() writefile(STORE_FILE, jencode(d)) end)
  else getgenv().RAM_ORDER = deepcopy(d) end
end

local function loadData()
  if can_write and isfile and isfile(STORE_FILE) then
    local ok,res = pcall(function() return jdecode(readfile(STORE_FILE)) end)
    if ok and type(res)=="table" then
      for k,v in pairs(DEFAULT) do if res[k]==nil then res[k]=v end end
      getgenv().RAM_ORDER = res
      return res
    end
  end
  return getgenv().RAM_ORDER
end

local DATA = loadData()

-- ============ UI (no buttons) ============
local sg = Instance.new("ScreenGui")
sg.Name = "DonCayUI"; sg.ResetOnSpawn = false
if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.fromOffset(300, 170)
frame.Position = UDim2.new(0, 30, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(20,22,28)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
local border = Instance.new("UIStroke", frame)
border.Color = Color3.fromRGB(70,90,255); border.Thickness = 1.4

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-16,0,30)
title.Position = UDim2.new(0,8,0,6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(235,235,245)
title.Text = "Quản lý đơn cày"

local function mkLabel(text,y)
  local lb = Instance.new("TextLabel", frame)
  lb.Position = UDim2.new(0,12,0,y)
  lb.Size = UDim2.new(0,80,0,22)
  lb.BackgroundTransparency = 1
  lb.Font = Enum.Font.Gotham
  lb.TextSize = 14
  lb.TextColor3 = Color3.fromRGB(200,205,220)
  lb.TextXAlignment = Enum.TextXAlignment.Left
  lb.Text = text
end

local function mkBox(y,w)
  local b = Instance.new("TextBox", frame)
  b.Position = UDim2.new(0,100,0,y)
  b.Size = UDim2.fromOffset(w or 180,26)
  b.BackgroundColor3 = Color3.fromRGB(30,32,40)
  b.TextColor3 = Color3.fromRGB(230,230,240)
  b.Font = Enum.Font.Gotham
  b.TextSize = 14
  b.ClearTextOnFocus = false
  Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
  Instance.new("UIStroke", b).Color = Color3.fromRGB(55,70,200)
  return b
end

mkLabel("Đơn",44)
local tbDesc = mkBox(44,180); tbDesc.Text = DATA.description

mkLabel("Trạng thái",76)
local statusBtn = Instance.new("TextButton", frame)
statusBtn.Position = UDim2.new(0,100,0,76)
statusBtn.Size = UDim2.fromOffset(130,26)
statusBtn.Font = Enum.Font.GothamBold
statusBtn.TextSize = 14
statusBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", statusBtn).CornerRadius = UDim.new(0,8)
local statusStroke = Instance.new("UIStroke", statusBtn); statusStroke.Thickness = 1.2

-- màu theo trạng thái
local STATUS = {"Đang làm","Tạm dừng","Hoàn thành"}
local STYLE = {
  ["Đang làm"]   = {bg=Color3.fromRGB(40,120,255),  stroke=Color3.fromRGB(70,150,255)},
  ["Tạm dừng"]   = {bg=Color3.fromRGB(255,180,60),  stroke=Color3.fromRGB(255,200,120)},
  ["Hoàn thành"] = {bg=Color3.fromRGB(60,200,100),  stroke=Color3.fromRGB(100,230,150)},
}
local function applyState(s)
  local st = STYLE[s] or STYLE["Đang làm"]
  statusBtn.Text = s
  statusBtn.BackgroundColor3 = st.bg
  statusStroke.Color = st.stroke
end
local idx = 1; for i,v in ipairs(STATUS) do if v==DATA.status then idx=i end end
applyState(DATA.status)

statusBtn.MouseButton1Click:Connect(function()
  idx = idx % #STATUS + 1
  DATA.status = STATUS[idx]
  applyState(DATA.status)
  saveData(DATA)  -- auto save khi đổi trạng thái
end)

-- dòng nhắc trạng thái lưu
local hint = Instance.new("TextLabel", frame)
hint.Position = UDim2.new(0,12,0,108)
hint.Size = UDim2.new(1,-24,0,18)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextColor3 = Color3.fromRGB(160,170,190)
hint.Text = "Đã lưu (auto) ✓"
hint.TextXAlignment = Enum.TextXAlignment.Left

-- auto-save khi rời ô “Đơn”
tbDesc.FocusLost:Connect(function()
  DATA.description = tbDesc.Text
  saveData(DATA)
  hint.Text = "Đã lưu (auto) ✓"
end)

-- kéo di chuyển
local UIS=game:GetService("UserInputService")
local dragging,dragStart,startPos=false,nil,nil
frame.InputBegan:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 then
    dragging=true; dragStart=i.Position; startPos=frame.Position
  end
end)
frame.InputEnded:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
UIS.InputChanged:Connect(function(i)
  if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
    local d=i.Position-dragStart
    frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
  end
end)

-- auto load sau teleport
if qot then
  local BOOT = ([[ 
local HttpService=game:GetService("HttpService")
local f="%s"; local c=(writefile and readfile and isfile) and true or false; local d={}
if c and isfile and isfile(f) then
  local ok,r=pcall(function() return HttpService:JSONDecode(readfile(f)) end)
  if ok and type(r)=="table" then d=r end
end
getgenv().RAM_ORDER=d
local sg=Instance.new("ScreenGui",game:GetService("CoreGui"))
local t=Instance.new("TextLabel",sg)
t.Size=UDim2.new(0,300,0,70); t.Position=UDim2.new(0,30,0,120)
t.BackgroundColor3=Color3.fromRGB(20,22,28); Instance.new("UICorner",t).CornerRadius=UDim.new(0,10)
t.Font=Enum.Font.Gotham; t.TextSize=14; t.TextColor3=Color3.fromRGB(230,230,240); t.TextWrapped=true
t.Text=string.format("Đơn: %s | Trạng thái: %s", d.description or "", d.status or "")
  ]]):format(STORE_FILE)

  LP.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
      saveData(DATA)
      pcall(function() qot(BOOT) end)
    end
  end)
end
