-- onhub
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")
local controllers = lp:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers")

local env = (type(getgenv) == "function" and getgenv()) or _G
if type(env.ONhubCleanup) == "function" then
	pcall(env.ONhubCleanup)
	env.ONhubCleanup = nil
end

pcall(function()
	local hui = type(gethui) == "function" and gethui()
	if hui and hui:FindFirstChild("ONhubGui") then hui.ONhubGui:Destroy() end
end)
pcall(function()
	if CoreGui:FindFirstChild("ONhubGui") then CoreGui.ONhubGui:Destroy() end
end)
if pg:FindFirstChild("ONhubGui") then pg.ONhubGui:Destroy() end

local LOGO = "rbxthumb://type=Asset&id=109941029950733&w=420&h=420"
local CFG_NAME = "ONhub_ThrowFood.json"

local Icons = {
	Throw = "rbxassetid://17127979242",
	Farm = "rbxassetid://122634913225226",
	Plot = "rbxassetid://105642295248032",
	Areas = "rbxassetid://72945207836197",
	Settings = "rbxassetid://117323693178558",
}

local Theme = {
	Window = Color3.fromRGB(13, 19, 15),
	Sidebar = Color3.fromRGB(10, 15, 12),
	Row = Color3.fromRGB(20, 30, 24),
	RowHover = Color3.fromRGB(26, 40, 32),
	Well = Color3.fromRGB(12, 18, 14),
	Border = Color3.fromRGB(38, 64, 48),
	Accent = Color3.fromRGB(46, 204, 113),
	AccentSoft = Color3.fromRGB(24, 58, 39),
	AccentBright = Color3.fromRGB(115, 240, 168),
	Text = Color3.fromRGB(238, 245, 240),
	Muted = Color3.fromRGB(152, 178, 162),
	Dim = Color3.fromRGB(108, 134, 118),
	TrackOff = Color3.fromRGB(30, 44, 36),
	KnobOff = Color3.fromRGB(165, 186, 173),
	KnobOn = Color3.fromRGB(245, 252, 247),
	Amber = Color3.fromRGB(234, 179, 8),
	Danger = Color3.fromRGB(224, 92, 92),
	DangerBg = Color3.fromRGB(48, 22, 24),
}

local GlowSeq = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(16, 26, 20)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(32, 64, 44)),
	ColorSequenceKeypoint.new(0.46, Color3.fromRGB(52, 210, 122)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(170, 255, 208)),
	ColorSequenceKeypoint.new(0.54, Color3.fromRGB(52, 210, 122)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(32, 64, 44)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(16, 26, 20)),
})

local fBold = Font.fromEnum(Enum.Font.BuilderSansBold)
local fSemi = Font.fromEnum(Enum.Font.BuilderSansMedium)
local fMono = Font.new(Font.fromEnum(Enum.Font.RobotoMono).Family, Enum.FontWeight.Medium)

local State = {
	AutoThrow = false,
	InstantThrow = false,
	AlwaysPerfect = true,
	Target = "Manual",
	ThrowDelay = 0.20,
	ThrowPower = 100,

	AutoTrain = false,
	AutoCycle = false,
	AutoClaim = false,
	AntiAfk = true,
	TrainTime = 20,
	ThrowCatches = 5,

	AutoEquipBest = false,
	AutoSell = false,
	KeepMutated = true,
	KeepRarity = "Rare",
	AutoBuyFood = false,
	AutoUpStand = false,
	AutoUpFence = false,

	AutoSave = true,
	CooldownHud = true,
	BgTransparency = 8,
	BorderGlow = true,
	GlowSpeed = 90,
	UiScale = 1.0,
	ScaleLabel = "100%",
	ToggleKey = Enum.KeyCode.RightShift,
}

local SavedKeys = {
	"InstantThrow", "AlwaysPerfect", "Target", "ThrowDelay", "ThrowPower",
	"AutoClaim", "AntiAfk", "TrainTime", "ThrowCatches",
	"KeepMutated", "KeepRarity",
	"AutoSave", "CooldownHud", "BgTransparency", "BorderGlow", "GlowSpeed", "UiScale", "ScaleLabel",
}

local function saveCfg()
	if not State.AutoSave or type(writefile) ~= "function" then return end
	local out = { ToggleKey = State.ToggleKey.Name }
	for _, k in pairs(SavedKeys) do
		out[k] = State[k]
	end
	pcall(writefile, CFG_NAME, HttpService:JSONEncode(out))
end

local function loadCfg()
	if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
	local ok, exists = pcall(isfile, CFG_NAME)
	if not ok or not exists then return end
	local okR, raw = pcall(readfile, CFG_NAME)
	if not okR or type(raw) ~= "string" or raw == "" then return end
	local okD, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not okD or type(data) ~= "table" then return end

	for _, k in pairs(SavedKeys) do
		if data[k] ~= nil and type(data[k]) == type(State[k]) then
			State[k] = data[k]
		end
	end
	if type(data.ToggleKey) == "string" then
		pcall(function()
			local kc = Enum.KeyCode[data.ToggleKey]
			if kc then State.ToggleKey = kc end
		end)
	end
end

loadCfg()

local conns = {}
local function track(c)
	table.insert(conns, c)
	return c
end

local function tw(obj, dur, props, style, dir)
	local t = ts:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function corner(p, px, sc)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(sc or 0, px or 0)
	c.Parent = p
	return c
end

local function stroke(p, col, thick, tr)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = thick
	s.Transparency = tr or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end


local Gui = Instance.new("ScreenGui")
Gui.Name = "ONhubGui"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.AutoLocalize = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 100
Gui.Parent = pg

local alive = true
track(Gui.Destroying:Connect(function()
	alive = false
end))
-- game hides guis on throws
track(Gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if alive and not Gui.Enabled then
		Gui.Enabled = true
	end
end))

local ORB_POS = UDim2.new(1, -80, 0, 96)

local OrbButton = Instance.new("ImageButton")
OrbButton.Name = "FloatingOrb"
OrbButton.Size = UDim2.fromOffset(58, 58)
OrbButton.Position = ORB_POS
OrbButton.BackgroundTransparency = 1
OrbButton.AutoButtonColor = false
OrbButton.Image = ""
OrbButton.ZIndex = 30
OrbButton.Parent = Gui
corner(OrbButton, 0, 1)

local OrbScale = Instance.new("UIScale")
OrbScale.Scale = 1
OrbScale.Parent = OrbButton

local OrbStroke = stroke(OrbButton, Color3.fromRGB(34, 88, 54), 1.4, 0)

local OrbLogo = Instance.new("ImageLabel")
OrbLogo.Name = "Logo"
OrbLogo.Size = UDim2.fromScale(1, 1)
OrbLogo.BackgroundTransparency = 1
OrbLogo.Image = LOGO
OrbLogo.ScaleType = Enum.ScaleType.Crop
OrbLogo.ZIndex = 31
OrbLogo.Parent = OrbButton
corner(OrbLogo, 0, 1)

local WIN_W, WIN_H = 640, 446
local SIDEBAR_W = 168

local Window = Instance.new("Frame")
Window.Name = "MainWindow"
Window.Size = UDim2.fromOffset(WIN_W, WIN_H)
Window.Position = UDim2.fromScale(0.5, 0.5)
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.BackgroundColor3 = Theme.Window
Window.BackgroundTransparency = State.BgTransparency / 100
Window.BorderSizePixel = 0
Window.Active = true
Window.Visible = true
Window.ZIndex = 10
Window.Parent = Gui
corner(Window, 14, 0)

local WinScale = Instance.new("UIScale", Window)
local WinStroke = stroke(Window, Color3.new(1, 1, 1), 2.0, 0)
local WinGrad = Instance.new("UIGradient", WinStroke)
WinGrad.Color = GlowSeq
WinGrad.Rotation = 0

local isMobile = uis.TouchEnabled and not uis.KeyboardEnabled

local function getScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local pad = isMobile and 20 or 40
	local fit = math.min((vp.X - pad) / WIN_W, (vp.Y - pad) / WIN_H, 1.0)
	return math.clamp(fit * State.UiScale, 0.48, 1.45)
end
WinScale.Scale = getScale()

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -16)
Sidebar.Position = UDim2.fromOffset(8, 8)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BackgroundTransparency = math.clamp(State.BgTransparency / 100 + 0.04, 0, 0.85)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 11
Sidebar.Parent = Window
corner(Sidebar, 10, 0)
stroke(Sidebar, Theme.Border, 1, 0.45)

local BrandBox = Instance.new("Frame")
BrandBox.Name = "Brand"
BrandBox.Size = UDim2.new(1, 0, 0, 56)
BrandBox.BackgroundTransparency = 1
BrandBox.ZIndex = 12
BrandBox.Parent = Sidebar

local BrandLogo = Instance.new("ImageLabel")
BrandLogo.Size = UDim2.fromOffset(34, 34)
BrandLogo.Position = UDim2.fromOffset(12, 11)
BrandLogo.BackgroundColor3 = Theme.Well
BrandLogo.Image = LOGO
BrandLogo.ScaleType = Enum.ScaleType.Crop
BrandLogo.ZIndex = 13
BrandLogo.Parent = BrandBox
corner(BrandLogo, 0, 1)
stroke(BrandLogo, Theme.Border, 1, 0.3)

local BrandTitle = Instance.new("TextLabel")
BrandTitle.Size = UDim2.new(1, -56, 0, 18)
BrandTitle.Position = UDim2.fromOffset(54, 10)
BrandTitle.BackgroundTransparency = 1
BrandTitle.Text = "ONhub"
BrandTitle.TextColor3 = Theme.Text
BrandTitle.FontFace = fBold
BrandTitle.TextSize = 16
BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
BrandTitle.ZIndex = 13
BrandTitle.Parent = BrandBox

local SideStatusRow = Instance.new("Frame")
SideStatusRow.Size = UDim2.new(1, -56, 0, 14)
SideStatusRow.Position = UDim2.fromOffset(54, 30)
SideStatusRow.BackgroundTransparency = 1
SideStatusRow.ZIndex = 13
SideStatusRow.Parent = BrandBox

local SideStatusDot = Instance.new("Frame")
SideStatusDot.Size = UDim2.fromOffset(7, 7)
SideStatusDot.Position = UDim2.new(0, 0, 0.5, -3)
SideStatusDot.BackgroundColor3 = Theme.Dim
SideStatusDot.BorderSizePixel = 0
SideStatusDot.ZIndex = 14
SideStatusDot.Parent = SideStatusRow
corner(SideStatusDot, 0, 1)

local SideStatusLbl = Instance.new("TextLabel")
SideStatusLbl.Size = UDim2.new(1, -12, 1, 0)
SideStatusLbl.Position = UDim2.fromOffset(12, 0)
SideStatusLbl.BackgroundTransparency = 1
SideStatusLbl.Text = "Idle"
SideStatusLbl.TextColor3 = Theme.Muted
SideStatusLbl.FontFace = fSemi
SideStatusLbl.TextSize = 12
SideStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
SideStatusLbl.ZIndex = 14
SideStatusLbl.Parent = SideStatusRow

local BrandRule = Instance.new("Frame")
BrandRule.Size = UDim2.new(1, -20, 0, 1)
BrandRule.Position = UDim2.fromOffset(10, 56)
BrandRule.BackgroundColor3 = Theme.Border
BrandRule.BackgroundTransparency = 0.4
BrandRule.BorderSizePixel = 0
BrandRule.ZIndex = 12
BrandRule.Parent = Sidebar

local NavContainer = Instance.new("Frame")
NavContainer.Name = "NavContainer"
NavContainer.Size = UDim2.new(1, -16, 1, -142)
NavContainer.Position = UDim2.fromOffset(8, 66)
NavContainer.BackgroundTransparency = 1
NavContainer.ZIndex = 12
NavContainer.Parent = Sidebar

local ActiveHighlight = Instance.new("Frame")
ActiveHighlight.Name = "ActiveHighlight"
ActiveHighlight.Size = UDim2.new(1, 0, 0, 38)
ActiveHighlight.Position = UDim2.fromOffset(0, 0)
ActiveHighlight.BackgroundColor3 = Theme.AccentSoft
ActiveHighlight.BackgroundTransparency = 0.25
ActiveHighlight.BorderSizePixel = 0
ActiveHighlight.ZIndex = 12
ActiveHighlight.Parent = NavContainer
corner(ActiveHighlight, 8, 0)
stroke(ActiveHighlight, Theme.Accent, 1, 0.55)

local ActiveBar = Instance.new("Frame")
ActiveBar.Size = UDim2.fromOffset(3, 18)
ActiveBar.Position = UDim2.new(0, 5, 0.5, -9)
ActiveBar.BackgroundColor3 = Theme.AccentBright
ActiveBar.BorderSizePixel = 0
ActiveBar.ZIndex = 14
ActiveBar.Parent = ActiveHighlight
corner(ActiveBar, 0, 1)

local NavButtonsFrame = Instance.new("Frame")
NavButtonsFrame.Name = "NavButtons"
NavButtonsFrame.Size = UDim2.fromScale(1, 1)
NavButtonsFrame.BackgroundTransparency = 1
NavButtonsFrame.ZIndex = 13
NavButtonsFrame.Parent = NavContainer

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 5)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavButtonsFrame

local DISCORD_CODE = "J3EqkKCS2B"
local DISCORD_URL = "https://discord.gg/" .. DISCORD_CODE
local DISCORD_ICON = "rbxthumb://type=Asset&id=10367063084&w=150&h=150"

local DiscordSideBtn = Instance.new("TextButton")
DiscordSideBtn.Name = "DiscordBtn"
DiscordSideBtn.Size = UDim2.new(1, -20, 0, 30)
DiscordSideBtn.Position = UDim2.new(0, 10, 1, -70)
DiscordSideBtn.BackgroundColor3 = Theme.AccentSoft
DiscordSideBtn.BackgroundTransparency = 0.2
DiscordSideBtn.Text = ""
DiscordSideBtn.AutoButtonColor = false
DiscordSideBtn.ZIndex = 13
DiscordSideBtn.Parent = Sidebar
corner(DiscordSideBtn, 7, 0)
stroke(DiscordSideBtn, Theme.Accent, 1, 0.5)

local DiscordIconWrap = Instance.new("Frame")
DiscordIconWrap.Name = "IconWrap"
DiscordIconWrap.Size = UDim2.fromOffset(18, 18)
DiscordIconWrap.Position = UDim2.new(0, 9, 0.5, -9)
DiscordIconWrap.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
DiscordIconWrap.BorderSizePixel = 0
DiscordIconWrap.ZIndex = 14
DiscordIconWrap.Parent = DiscordSideBtn
corner(DiscordIconWrap, 6, 0)

local DiscordSideIcon = Instance.new("ImageLabel")
DiscordSideIcon.AnchorPoint = Vector2.new(0.5, 0.5)
DiscordSideIcon.Size = UDim2.fromOffset(15, 12)
DiscordSideIcon.Position = UDim2.fromScale(0.5, 0.5)
DiscordSideIcon.BackgroundTransparency = 1
DiscordSideIcon.Image = DISCORD_ICON
DiscordSideIcon.ScaleType = Enum.ScaleType.Stretch
DiscordSideIcon.ZIndex = 15
DiscordSideIcon.Parent = DiscordIconWrap
corner(DiscordSideIcon, 3, 0)

local DiscordSideLbl = Instance.new("TextLabel")
DiscordSideLbl.Size = UDim2.new(1, -36, 1, 0)
DiscordSideLbl.Position = UDim2.fromOffset(33, 0)
DiscordSideLbl.BackgroundTransparency = 1
DiscordSideLbl.Text = "Discord"
DiscordSideLbl.TextColor3 = Theme.AccentBright
DiscordSideLbl.FontFace = fSemi
DiscordSideLbl.TextSize = 12
DiscordSideLbl.TextXAlignment = Enum.TextXAlignment.Left
DiscordSideLbl.ZIndex = 14
DiscordSideLbl.Parent = DiscordSideBtn

local discordCooldown = false
DiscordSideBtn.MouseButton1Click:Connect(function()
	if discordCooldown then return end
	discordCooldown = true

	local copied = false
	pcall(function()
		local clip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
		if type(clip) == "function" then
			clip(DISCORD_URL)
			copied = true
		end
	end)

	if not isMobile then
		local req = (type(request) == "function" and request)
			or (type(http_request) == "function" and http_request)
			or (syn and type(syn.request) == "function" and syn.request)
			or (http and type(http.request) == "function" and http.request)
		if req then
			task.spawn(function()
				local ok, res = pcall(req, {
					Url = "http://127.0.0.1:6463/rpc?v=1",
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json",
						["Origin"] = "https://discord.com",
					},
					Body = HttpService:JSONEncode({
						cmd = "INVITE_BROWSER",
						nonce = HttpService:GenerateGUID(false),
						args = { code = DISCORD_CODE },
					}),
				})
				if ok and res and (res.StatusCode == 200 or res.Success) then
					DiscordSideLbl.Text = "Opened!"
				end
			end)
		end
	end

	DiscordSideLbl.Text = copied and "Copied!" or "J3EqkKCS2B"
	DiscordSideLbl.TextColor3 = Theme.Text
	task.delay(2.2, function()
		if DiscordSideLbl and DiscordSideLbl.Parent then
			DiscordSideLbl.Text = "Discord"
			DiscordSideLbl.TextColor3 = Theme.AccentBright
		end
		discordCooldown = false
	end)
end)

local FooterLbl = Instance.new("TextLabel")
FooterLbl.Size = UDim2.new(1, -20, 0, 26)
FooterLbl.Position = UDim2.new(0, 10, 1, -34)
FooterLbl.BackgroundColor3 = Theme.Well
FooterLbl.BackgroundTransparency = 0.25
FooterLbl.Text = isMobile and "Tap Orb" or State.ToggleKey.Name
FooterLbl.TextColor3 = Theme.Dim
FooterLbl.FontFace = fMono
FooterLbl.TextSize = 11
FooterLbl.ZIndex = 13
FooterLbl.Parent = Sidebar
corner(FooterLbl, 7, 0)

local WORK_X = SIDEBAR_W + 18

local Workspace = Instance.new("Frame")
Workspace.Name = "Workspace"
Workspace.Size = UDim2.new(1, -WORK_X, 1, 0)
Workspace.Position = UDim2.fromOffset(WORK_X, 0)
Workspace.BackgroundTransparency = 1
Workspace.ZIndex = 11
Workspace.Parent = Window

local TopHeader = Instance.new("Frame")
TopHeader.Name = "TopHeader"
TopHeader.Size = UDim2.new(1, -14, 0, 48)
TopHeader.BackgroundTransparency = 1
TopHeader.ZIndex = 12
TopHeader.Parent = Workspace

local PageIcon = Instance.new("ImageLabel")
PageIcon.Name = "PageIcon"
PageIcon.Size = UDim2.fromOffset(18, 18)
PageIcon.Position = UDim2.new(0, 2, 0.5, -9)
PageIcon.BackgroundTransparency = 1
PageIcon.Image = Icons.Throw
PageIcon.ScaleType = Enum.ScaleType.Fit
PageIcon.ZIndex = 13
PageIcon.Parent = TopHeader

local PageTitle = Instance.new("TextLabel")
PageTitle.Size = UDim2.new(1, -144, 1, 0)
PageTitle.Position = UDim2.fromOffset(26, 0)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = "Throw"
PageTitle.TextColor3 = Theme.Text
PageTitle.FontFace = fBold
PageTitle.TextSize = 16
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.ZIndex = 13
PageTitle.Parent = TopHeader

local StatusBadge = Instance.new("TextLabel")
StatusBadge.Size = UDim2.fromOffset(64, 24)
StatusBadge.Position = UDim2.new(1, -98, 0.5, -12)
StatusBadge.BackgroundColor3 = Theme.Row
StatusBadge.BackgroundTransparency = 0.15
StatusBadge.Text = "Idle"
StatusBadge.TextColor3 = Theme.Muted
StatusBadge.FontFace = fMono
StatusBadge.TextSize = 11
StatusBadge.ZIndex = 13
StatusBadge.Parent = TopHeader
corner(StatusBadge, 7, 0)
stroke(StatusBadge, Theme.Border, 1, 0.35)

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.fromOffset(28, 28)
MinBtn.Position = UDim2.new(1, -28, 0.5, -14)
MinBtn.BackgroundColor3 = Theme.Row
MinBtn.BackgroundTransparency = 0.15
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.Muted
MinBtn.FontFace = fBold
MinBtn.TextSize = 14
MinBtn.AutoButtonColor = false
MinBtn.ZIndex = 14
MinBtn.Parent = TopHeader
corner(MinBtn, 7, 0)
stroke(MinBtn, Theme.Border, 1, 0.35)

MinBtn.MouseEnter:Connect(function()
	tw(MinBtn, 0.12, { BackgroundColor3 = Theme.RowHover, TextColor3 = Theme.Text })
end)
MinBtn.MouseLeave:Connect(function()
	tw(MinBtn, 0.12, { BackgroundColor3 = Theme.Row, TextColor3 = Theme.Muted })
end)

local HeaderRule = Instance.new("Frame")
HeaderRule.Size = UDim2.new(1, -14, 0, 1)
HeaderRule.Position = UDim2.fromOffset(0, 48)
HeaderRule.BackgroundColor3 = Theme.Border
HeaderRule.BackgroundTransparency = 0.45
HeaderRule.BorderSizePixel = 0
HeaderRule.ZIndex = 12
HeaderRule.Parent = Workspace

local PagesHost = Instance.new("Frame")
PagesHost.Name = "PagesHost"
PagesHost.Size = UDim2.new(1, -14, 1, -64)
PagesHost.Position = UDim2.fromOffset(0, 56)
PagesHost.BackgroundTransparency = 1
PagesHost.ClipsDescendants = true
PagesHost.ZIndex = 12
PagesHost.Parent = Workspace


local surfaces = {}
local function addSurface(inst, off)
	table.insert(surfaces, { inst = inst, off = off })
end

local insetY = GuiService:GetGuiInset().Y
local HUD_POS = UDim2.fromOffset(14, (insetY > 0 and insetY or 58) + 12)

local HudBox = Instance.new("Frame")
HudBox.Name = "CooldownHud"
HudBox.Size = UDim2.fromOffset(192, 104)
HudBox.Position = HUD_POS
HudBox.BackgroundColor3 = Theme.Window
HudBox.BackgroundTransparency = State.BgTransparency / 100
HudBox.BorderSizePixel = 0
HudBox.Active = true
HudBox.Visible = false
HudBox.ZIndex = 20
HudBox.Parent = Gui
corner(HudBox, 10, 0)
addSurface(HudBox, 0)

local HudScale = Instance.new("UIScale", HudBox)
HudScale.Scale = math.clamp(getScale(), 0.62, 1.0)

local HudStroke = stroke(HudBox, Color3.new(1, 1, 1), 1.6, 0)
local HudGrad = Instance.new("UIGradient", HudStroke)
HudGrad.Color = GlowSeq
HudGrad.Rotation = 15

local HudDot = Instance.new("Frame")
HudDot.Size = UDim2.fromOffset(7, 7)
HudDot.Position = UDim2.fromOffset(10, 14)
HudDot.BackgroundColor3 = Theme.AccentBright
HudDot.BorderSizePixel = 0
HudDot.ZIndex = 21
HudDot.Parent = HudBox
corner(HudDot, 0, 1)

local HudModeLbl = Instance.new("TextLabel")
HudModeLbl.Size = UDim2.fromOffset(96, 18)
HudModeLbl.Position = UDim2.fromOffset(22, 8)
HudModeLbl.BackgroundTransparency = 1
HudModeLbl.Text = "Auto Cycle"
HudModeLbl.TextColor3 = Theme.Text
HudModeLbl.FontFace = fBold
HudModeLbl.TextSize = 12
HudModeLbl.TextXAlignment = Enum.TextXAlignment.Left
HudModeLbl.ZIndex = 21
HudModeLbl.Parent = HudBox

local HudPhasePill = Instance.new("TextLabel")
HudPhasePill.Size = UDim2.fromOffset(58, 18)
HudPhasePill.Position = UDim2.new(1, -68, 0, 8)
HudPhasePill.BackgroundColor3 = Theme.AccentSoft
HudPhasePill.BackgroundTransparency = 0.2
HudPhasePill.Text = "TRAIN"
HudPhasePill.TextColor3 = Theme.AccentBright
HudPhasePill.FontFace = fMono
HudPhasePill.TextSize = 10
HudPhasePill.ZIndex = 21
HudPhasePill.Parent = HudBox
corner(HudPhasePill, 5, 0)
local HudPhaseStroke = stroke(HudPhasePill, Theme.Accent, 1, 0.5)

local HudRule = Instance.new("Frame")
HudRule.Size = UDim2.new(1, -20, 0, 1)
HudRule.Position = UDim2.fromOffset(10, 32)
HudRule.BackgroundColor3 = Theme.Border
HudRule.BackgroundTransparency = 0.45
HudRule.BorderSizePixel = 0
HudRule.ZIndex = 21
HudRule.Parent = HudBox

local HudTimerLbl = Instance.new("TextLabel")
HudTimerLbl.Size = UDim2.fromOffset(88, 16)
HudTimerLbl.Position = UDim2.fromOffset(10, 38)
HudTimerLbl.BackgroundTransparency = 1
HudTimerLbl.Text = "Next: Throw"
HudTimerLbl.TextColor3 = Theme.Muted
HudTimerLbl.FontFace = fSemi
HudTimerLbl.TextSize = 11
HudTimerLbl.TextXAlignment = Enum.TextXAlignment.Left
HudTimerLbl.ZIndex = 21
HudTimerLbl.Parent = HudBox

local HudTimerVal = Instance.new("TextLabel")
HudTimerVal.Size = UDim2.fromOffset(84, 16)
HudTimerVal.Position = UDim2.new(1, -94, 0, 38)
HudTimerVal.BackgroundTransparency = 1
HudTimerVal.Text = "20.0s"
HudTimerVal.TextColor3 = Theme.Text
HudTimerVal.FontFace = fMono
HudTimerVal.TextSize = 11
HudTimerVal.TextXAlignment = Enum.TextXAlignment.Right
HudTimerVal.ZIndex = 21
HudTimerVal.Parent = HudBox

local HudBar = Instance.new("Frame")
HudBar.Size = UDim2.new(1, -20, 0, 5)
HudBar.Position = UDim2.fromOffset(10, 58)
HudBar.BackgroundColor3 = Theme.TrackOff
HudBar.BorderSizePixel = 0
HudBar.ZIndex = 21
HudBar.Parent = HudBox
corner(HudBar, 0, 1)

local HudFill = Instance.new("Frame")
HudFill.Size = UDim2.fromScale(0, 1)
HudFill.BackgroundColor3 = Theme.Accent
HudFill.BorderSizePixel = 0
HudFill.ZIndex = 22
HudFill.Parent = HudBar
corner(HudFill, 0, 1)

local HudCdLbl = Instance.new("TextLabel")
HudCdLbl.Size = UDim2.fromOffset(83, 22)
HudCdLbl.Position = UDim2.fromOffset(10, 72)
HudCdLbl.BackgroundColor3 = Theme.Well
HudCdLbl.BackgroundTransparency = 0.2
HudCdLbl.Text = "CD: Ready"
HudCdLbl.TextColor3 = Theme.AccentBright
HudCdLbl.FontFace = fMono
HudCdLbl.TextSize = 10
HudCdLbl.ZIndex = 21
HudCdLbl.Parent = HudBox
corner(HudCdLbl, 6, 0)
addSurface(HudCdLbl, 0.12)

local HudStatLbl = Instance.new("TextLabel")
HudStatLbl.Size = UDim2.fromOffset(83, 22)
HudStatLbl.Position = UDim2.fromOffset(99, 72)
HudStatLbl.BackgroundColor3 = Theme.Well
HudStatLbl.BackgroundTransparency = 0.2
HudStatLbl.Text = "Cycles: 0"
HudStatLbl.TextColor3 = Theme.Muted
HudStatLbl.FontFace = fMono
HudStatLbl.TextSize = 10
HudStatLbl.ZIndex = 21
HudStatLbl.Parent = HudBox
corner(HudStatLbl, 6, 0)
addSurface(HudStatLbl, 0.12)

local function updateAlpha()
	local base = math.clamp(State.BgTransparency / 100, 0, 0.70)
	Window.BackgroundTransparency = base
	Sidebar.BackgroundTransparency = math.clamp(base + 0.04, 0, 0.85)
	for _, s in pairs(surfaces) do
		s.inst.BackgroundTransparency = math.clamp(base + s.off, 0, 0.90)
	end
end

local function anyRunning()
	return State.AutoThrow or State.AutoTrain or State.AutoCycle
		or State.AutoEquipBest or State.AutoSell or State.AutoBuyFood
		or State.AutoUpStand or State.AutoUpFence
end

local function updateStatus()
	local on = anyRunning()
	local txt = on and "Active" or "Idle"
	local col = on and Theme.AccentBright or Theme.Dim

	SideStatusLbl.Text = txt
	SideStatusLbl.TextColor3 = on and Theme.AccentBright or Theme.Muted
	SideStatusDot.BackgroundColor3 = col
	StatusBadge.Text = txt
	StatusBadge.TextColor3 = on and Theme.AccentBright or Theme.Muted
	StatusBadge.BackgroundColor3 = on and Theme.AccentSoft or Theme.Row
	HudBox.Visible = State.CooldownHud and (State.AutoCycle or State.AutoThrow or State.AutoTrain)
end

local function updateGlow()
	local on = State.BorderGlow
	WinGrad.Enabled = on
	HudGrad.Enabled = on
	WinStroke.Color = on and Color3.new(1, 1, 1) or Theme.Border
	HudStroke.Color = on and Color3.new(1, 1, 1) or Theme.Border
end

local isOpen, animLock = true, false
local function toggleWin(open)
	if animLock and isOpen == open then return end
	isOpen = open
	animLock = true
	if isOpen then
		Window.Visible = true
		WinScale.Scale = getScale() * 0.92
		local t = tw(WinScale, 0.22, { Scale = getScale() }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		t.Completed:Connect(function() animLock = false end)
	else
		local t = tw(WinScale, 0.15, { Scale = getScale() * 0.92 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		t.Completed:Connect(function()
			if not isOpen then Window.Visible = false end
			animLock = false
		end)
	end
end

MinBtn.MouseButton1Click:Connect(function()
	toggleWin(false)
end)

local tabs = {}
local curTab = ""

local function selectTab(id)
	if curTab == id then return end
	curTab = id
	for _, tab in pairs(tabs) do
		local picked = tab.id == id
		tab.page.Visible = picked
		if picked then
			PageTitle.Text = tab.title
			PageIcon.Image = tab.icon
			tw(ActiveHighlight, 0.2, { Position = UDim2.fromOffset(0, (tab.order - 1) * 43) })
			tw(tab.label, 0.14, { TextColor3 = Theme.Text })
			tw(tab.iconImg, 0.14, { ImageTransparency = 0 })
		else
			tw(tab.label, 0.14, { TextColor3 = Theme.Muted })
			tw(tab.iconImg, 0.14, { ImageTransparency = 0.4 })
		end
	end
end

local function makeTab(id, title, icon)
	local idx = #tabs + 1

	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. id
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.LayoutOrder = idx
	btn.ZIndex = 14
	btn.Parent = NavButtonsFrame

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromOffset(17, 17)
	img.Position = UDim2.new(0, 13, 0.5, -8)
	img.BackgroundTransparency = 1
	img.Image = icon
	img.ImageTransparency = 0.4
	img.ScaleType = Enum.ScaleType.Fit
	img.ZIndex = 15
	img.Parent = btn

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -40, 1, 0)
	lbl.Position = UDim2.fromOffset(36, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = title
	lbl.TextColor3 = Theme.Muted
	lbl.FontFace = fSemi
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 15
	lbl.Parent = btn

	local page = Instance.new("ScrollingFrame")
	page.Name = "Page_" .. id
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = Theme.Border
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.fromOffset(0, 0)
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	page.Visible = false
	page.ZIndex = 12
	page.Parent = PagesHost

	local lay = Instance.new("UIListLayout", page)
	lay.Padding = UDim.new(0, 6)
	lay.SortOrder = Enum.SortOrder.LayoutOrder

	local pad = Instance.new("UIPadding", page)
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)

	btn.MouseEnter:Connect(function()
		if curTab ~= id then
			tw(lbl, 0.1, { TextColor3 = Theme.Text })
			tw(img, 0.1, { ImageTransparency = 0.1 })
		end
	end)
	btn.MouseLeave:Connect(function()
		if curTab ~= id then
			tw(lbl, 0.1, { TextColor3 = Theme.Muted })
			tw(img, 0.1, { ImageTransparency = 0.4 })
		end
	end)
	btn.MouseButton1Click:Connect(function()
		selectTab(id)
	end)

	table.insert(tabs, { id = id, title = title, icon = icon, order = idx, btn = btn, label = lbl, iconImg = img, page = page })
	return page
end

local function addToggle(parent, order, text, key, cb)
	local row = Instance.new("TextButton")
	row.Name = "Toggle_" .. key
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Theme.Row
	row.Text = ""
	row.AutoButtonColor = false
	row.LayoutOrder = order
	row.ZIndex = 13
	row.Parent = parent
	corner(row, 9, 0)
	stroke(row, Theme.Border, 1, 0.5)
	addSurface(row, 0.08)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -72, 1, 0)
	lbl.Position = UDim2.fromOffset(14, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Theme.Text
	lbl.FontFace = fSemi
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 14
	lbl.Parent = row

	local trk = Instance.new("Frame")
	trk.Size = UDim2.fromOffset(42, 22)
	trk.Position = UDim2.new(1, -54, 0.5, -11)
	trk.BackgroundColor3 = Theme.TrackOff
	trk.BorderSizePixel = 0
	trk.ZIndex = 14
	trk.Parent = row
	corner(trk, 0, 1)
	local trkStroke = stroke(trk, Theme.Border, 1, 0.2)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.Position = UDim2.fromOffset(3, 3)
	knob.BackgroundColor3 = Theme.KnobOff
	knob.BorderSizePixel = 0
	knob.ZIndex = 15
	knob.Parent = trk
	corner(knob, 0, 1)

	local function draw(v, snap)
		if snap then
			trk.BackgroundColor3 = v and Theme.Accent or Theme.TrackOff
			trkStroke.Color = v and Theme.AccentBright or Theme.Border
			knob.Position = v and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
			knob.BackgroundColor3 = v and Theme.KnobOn or Theme.KnobOff
		else
			tw(trk, 0.16, { BackgroundColor3 = v and Theme.Accent or Theme.TrackOff })
			tw(trkStroke, 0.16, { Color = v and Theme.AccentBright or Theme.Border })
			tw(knob, 0.16, {
				Position = v and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
				BackgroundColor3 = v and Theme.KnobOn or Theme.KnobOff,
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end

	draw(State[key] == true, true)
	row.MouseEnter:Connect(function() tw(row, 0.1, { BackgroundColor3 = Theme.RowHover }) end)
	row.MouseLeave:Connect(function() tw(row, 0.1, { BackgroundColor3 = Theme.Row }) end)
	row.MouseButton1Click:Connect(function()
		local nxt = not State[key]
		State[key] = nxt
		draw(nxt, false)
		updateStatus()
		if cb then cb(nxt) end
	end)
end

local function addSlider(parent, order, text, key, minV, maxV, step, suffix, fmt, cb)
	local row = Instance.new("Frame")
	row.Name = "Slider_" .. key
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Theme.Row
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.ZIndex = 13
	row.Parent = parent
	corner(row, 9, 0)
	stroke(row, Theme.Border, 1, 0.5)
	addSurface(row, 0.08)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -92, 0, 18)
	lbl.Position = UDim2.fromOffset(14, 8)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Theme.Text
	lbl.FontFace = fSemi
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 14
	lbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.fromOffset(64, 20)
	valLbl.Position = UDim2.new(1, -78, 0, 7)
	valLbl.BackgroundColor3 = Theme.Well
	valLbl.BackgroundTransparency = 0.2
	valLbl.TextColor3 = Theme.AccentBright
	valLbl.FontFace = fMono
	valLbl.TextSize = 11
	valLbl.ZIndex = 14
	valLbl.Parent = row
	corner(valLbl, 5, 0)

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, -24, 0, 26)
	hit.Position = UDim2.fromOffset(12, 28)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.ZIndex = 15
	hit.Parent = row

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.Position = UDim2.new(0, 0, 0.5, -3)
	bar.BackgroundColor3 = Theme.TrackOff
	bar.BorderSizePixel = 0
	bar.ZIndex = 14
	bar.Parent = hit
	corner(bar, 0, 1)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0.5, 1)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.ZIndex = 15
	fill.Parent = bar
	corner(fill, 0, 1)

	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.fromOffset(14, 14)
	thumb.Position = UDim2.new(0.5, -7, 0.5, -7)
	thumb.BackgroundColor3 = Theme.KnobOn
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 16
	thumb.Parent = bar
	corner(thumb, 0, 1)

	local function setVal(v)
		v = math.round(math.clamp(math.round(v / step) * step, minV, maxV) * 1000) / 1000
		State[key] = v
		local a = (v - minV) / math.max(0.0001, maxV - minV)
		fill.Size = UDim2.fromScale(a, 1)
		thumb.Position = UDim2.new(a, -7, 0.5, -7)
		valLbl.Text = (fmt and string.format(fmt, v) or tostring(v)) .. suffix
		if cb then cb(v) end
	end

	setVal(tonumber(State[key]) or minV)

	local dragInp = nil
	local function slideTo(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
		setVal(minV + a * (maxV - minV))
	end

	hit.InputBegan:Connect(function(inp)
		if not dragInp and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
			dragInp = inp
			slideTo(inp.Position.X)
		end
	end)
	track(uis.InputChanged:Connect(function(inp)
		if not dragInp then return end
		if (dragInp.UserInputType == Enum.UserInputType.Touch and inp == dragInp)
			or (dragInp.UserInputType == Enum.UserInputType.MouseButton1 and inp.UserInputType == Enum.UserInputType.MouseMovement) then
			slideTo(inp.Position.X)
		end
	end))
	track(uis.InputEnded:Connect(function(inp)
		if dragInp and inp == dragInp then
			dragInp = nil
		end
	end))
end

local function addSegmented(parent, order, text, key, opts, cb)
	local row = Instance.new("Frame")
	row.Name = "Seg_" .. key
	row.Size = UDim2.new(1, 0, 0, 58)
	row.BackgroundColor3 = Theme.Row
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.ZIndex = 13
	row.Parent = parent
	corner(row, 9, 0)
	stroke(row, Theme.Border, 1, 0.5)
	addSurface(row, 0.08)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -28, 0, 16)
	lbl.Position = UDim2.fromOffset(14, 6)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Theme.Muted
	lbl.FontFace = fSemi
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 14
	lbl.Parent = row

	local trk = Instance.new("Frame")
	trk.Size = UDim2.new(1, -28, 0, 28)
	trk.Position = UDim2.fromOffset(14, 24)
	trk.BackgroundColor3 = Theme.Well
	trk.BackgroundTransparency = 0.2
	trk.BorderSizePixel = 0
	trk.ZIndex = 14
	trk.Parent = row
	corner(trk, 7, 0)

	local n = #opts
	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(1 / n, -4, 1, -4)
	pill.Position = UDim2.fromOffset(2, 2)
	pill.BackgroundColor3 = Theme.AccentSoft
	pill.BorderSizePixel = 0
	pill.ZIndex = 15
	pill.Parent = trk
	corner(pill, 5, 0)
	stroke(pill, Theme.Accent, 1, 0.5)

	local btns = {}
	local function pick(idx, snap)
		State[key] = opts[idx]
		local pos = UDim2.new((idx - 1) / n, 2, 0, 2)
		if snap then pill.Position = pos else tw(pill, 0.16, { Position = pos }) end
		for i, b in ipairs(btns) do
			b.TextColor3 = (i == idx) and Theme.Text or Theme.Dim
		end
	end

	local startIdx = 1
	for i, opt in ipairs(opts) do
		if opt == State[key] then startIdx = i end
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1 / n, 0, 1, 0)
		b.Position = UDim2.fromScale((i - 1) / n, 0)
		b.BackgroundTransparency = 1
		b.Text = opt
		b.TextColor3 = Theme.Dim
		b.FontFace = fSemi
		b.TextSize = 12
		b.AutoButtonColor = false
		b.ZIndex = 16
		b.Parent = trk
		table.insert(btns, b)
		b.MouseButton1Click:Connect(function()
			pick(i, false)
			if cb then cb(opt) end
		end)
	end
	pick(startIdx, true)
end

local function addCycleRow(parent, order, text, key, opts, cb)
	local row = Instance.new("Frame")
	row.Name = "Cycle_" .. key
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Theme.Row
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.ZIndex = 13
	row.Parent = parent
	corner(row, 9, 0)
	stroke(row, Theme.Border, 1, 0.5)
	addSurface(row, 0.08)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -184, 1, 0)
	lbl.Position = UDim2.fromOffset(14, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Theme.Text
	lbl.FontFace = fSemi
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 14
	lbl.Parent = row

	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(160, 28)
	box.Position = UDim2.new(1, -172, 0.5, -14)
	box.BackgroundColor3 = Theme.Well
	box.BackgroundTransparency = 0.2
	box.BorderSizePixel = 0
	box.ZIndex = 14
	box.Parent = row
	corner(box, 7, 0)
	stroke(box, Theme.Border, 1, 0.35)

	local prevB = Instance.new("TextButton")
	prevB.Size = UDim2.fromOffset(26, 28)
	prevB.BackgroundTransparency = 1
	prevB.Text = "<"
	prevB.TextColor3 = Theme.Muted
	prevB.FontFace = fBold
	prevB.TextSize = 13
	prevB.AutoButtonColor = false
	prevB.ZIndex = 15
	prevB.Parent = box

	local nextB = Instance.new("TextButton")
	nextB.Size = UDim2.fromOffset(26, 28)
	nextB.Position = UDim2.new(1, -26, 0, 0)
	nextB.BackgroundTransparency = 1
	nextB.Text = ">"
	nextB.TextColor3 = Theme.Muted
	nextB.FontFace = fBold
	nextB.TextSize = 13
	nextB.AutoButtonColor = false
	nextB.ZIndex = 15
	nextB.Parent = box

	local valB = Instance.new("TextButton")
	valB.Size = UDim2.new(1, -52, 1, 0)
	valB.Position = UDim2.fromOffset(26, 0)
	valB.BackgroundTransparency = 1
	valB.Text = tostring(State[key] or opts[1])
	valB.TextColor3 = Theme.AccentBright
	valB.FontFace = fSemi
	valB.TextSize = 12
	valB.AutoButtonColor = false
	valB.ZIndex = 15
	valB.Parent = box

	local cur = 1
	for i, o in ipairs(opts) do
		if o == State[key] then cur = i break end
	end

	local function setIdx(idx, fire)
		cur = ((idx - 1) % #opts) + 1
		local opt = opts[cur]
		State[key] = opt
		valB.Text = opt
		valB.TextColor3 = (opt == "Sell All") and Theme.Amber or Theme.AccentBright
		if fire and cb then cb(opt) end
	end

	setIdx(cur, false)
	prevB.MouseButton1Click:Connect(function() setIdx(cur - 1, true) end)
	nextB.MouseButton1Click:Connect(function() setIdx(cur + 1, true) end)
	valB.MouseButton1Click:Connect(function() setIdx(cur + 1, true) end)
end


local function req(m)
	if not m or not m:IsA("ModuleScript") then return nil end
	local ok, res = pcall(require, m)
	return ok and res or nil
end

local shared = rs:FindFirstChild("Shared")
local cfgDir = rs:FindFirstChild("Config")

local Remotes = req(shared and shared:FindFirstChild("Remotes"))
local ThrowMeterMath = req(shared and shared:FindFirstChild("ThrowMeterMath"))
local BalanceCurve = req(shared and shared:FindFirstChild("BalanceCurve"))
local LevelConfig = req(cfgDir and cfgDir:FindFirstChild("LevelConfig"))
local AreasConfig = req(cfgDir and cfgDir:FindFirstChild("AreasConfig"))
local GameConfig = req(cfgDir and cfgDir:FindFirstChild("GameConfig"))
local IconImages = req(cfgDir and cfgDir:FindFirstChild("IconImages"))
local AnimalEconomy = req(cfgDir and cfgDir:FindFirstChild("AnimalEconomy"))
local RarityConfig = req(cfgDir and cfgDir:FindFirstChild("RarityConfig"))
local FoodsConfig = req(cfgDir and cfgDir:FindFirstChild("FoodsConfig"))
local StandsConfig = req(cfgDir and cfgDir:FindFirstChild("StandsConfig"))
local FenceConfig = req(cfgDir and cfgDir:FindFirstChild("FenceConfig"))
local IndexRewardsConfig = req(cfgDir and cfgDir:FindFirstChild("IndexRewardsConfig"))

local DataCtrl = req(controllers:FindFirstChild("DataController"))
local ClientState = req(controllers:FindFirstChild("ClientState"))
local ThrowCtrl = req(controllers:FindFirstChild("ThrowController"))
local ThrowMeter = req(controllers:FindFirstChild("ThrowMeter"))
local TrainCtrl = req(controllers:FindFirstChild("TrainingController"))
local IndexCtrl = req(controllers:FindFirstChild("IndexRewardsController"))
local AfkCtrl = req(controllers:FindFirstChild("AFKRejoin"))
local origAfkIdle = (GameConfig and GameConfig.AFKRejoin and GameConfig.AFKRejoin.IdleSeconds) or 1080

local halfPeriod = (ThrowMeterMath and type(ThrowMeterMath.HalfPeriod) == "function") and ThrowMeterMath.HalfPeriod() or 1.0858

local function syncPerfect()
	if ThrowMeter then
		ThrowMeter.TestAutoTap = State.AlwaysPerfect and halfPeriod or nil
	end
end

local lastPow, powSeq = nil, 0

local function getPowerVal()
	if not (DataCtrl and LevelConfig) then return 0 end
	local lvl = DataCtrl:Get("Level") or 1
	local maxP = LevelConfig.ThrowPowerForLevel(lvl)
	local minP = math.min(LevelConfig.MinThrowPower, maxP)

	if State.Target == "Nearest" then return minP end
	if State.Target == "Rarest" or State.ThrowPower >= 100 then return 0 end

	local a = math.clamp(State.ThrowPower / 100, 0, 1)
	local val = math.floor(minP + a * (maxP - minP) + 0.5)
	return (val >= maxP) and 0 or val
end

local function pushPower(now)
	if not Remotes then return end
	local want = getPowerVal()
	if want == lastPow then return end

	if now then
		lastPow = want
		local ok, res = pcall(Remotes.Invoke, "Player_SetThrowPower", want)
		if not (ok and type(res) == "table" and res.Ok) then lastPow = nil end
		return
	end

	powSeq += 1
	local seq = powSeq
	task.delay(0.12, function()
		if not alive or seq ~= powSeq then return end
		local d = getPowerVal()
		if d == lastPow then return end
		lastPow = d
		local ok, res = pcall(Remotes.Invoke, "Player_SetThrowPower", d)
		if not (ok and type(res) == "table" and res.Ok) then lastPow = nil end
	end)
end

local function getLineCF(inside)
	local sa = workspace:FindFirstChild("StarterArea")
	local cl = sa and sa:FindFirstChild("CrossLine")
	local z = cl and cl.Position.Z or (sa and (sa.Position.Z + sa.Size.Z * 0.5) or -40)
	local y = sa and (sa.Position.Y + sa.Size.Y * 0.5 + 3.2) or 5.5
	local x = sa and sa.Position.X or 0
	local tz = inside and (z - 2.0) or (z + 1.5)
	return CFrame.lookAt(Vector3.new(x, y, tz), Vector3.new(x, y, tz - 10))
end

local function getTrainCF()
	local idx = lp:GetAttribute("PlotIndex")
	local plot = idx and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(tostring(idx))
	if not (plot and plot:IsA("BasePart")) then return nil end
	local off = GameConfig and GameConfig.Plot and GameConfig.Plot.TrainingSpotOffset or Vector3.new(-16, 0.5, -30.5)
	return CFrame.new(plot.Position + off + Vector3.new(0, 3.0, 0))
end

local function waitWhile(sec, keepFn)
	local tEnd = os.clock() + sec
	while alive and keepFn() and os.clock() < tEnd do
		task.wait(math.min(0.08, tEnd - os.clock()))
	end
	return alive and keepFn()
end

local function exactWait(sec, keepFn)
	if sec <= 0 then return alive and keepFn() end
	local t0 = os.clock()
	if sec > 0.04 and not waitWhile(sec - 0.03, keepFn) then return false end
	while alive and keepFn() and (os.clock() - t0) < sec do
		RunService.Heartbeat:Wait()
	end
	return alive and keepFn()
end

local phase = "Throw"
local phaseStart, phaseDur = os.clock(), State.TrainTime
local phaseCatches = 0
local cycleCount, throwCount = 0, 0
local remoteThrowing, remoteTraining = false, false

local function onCatch()
	throwCount += 1
	if State.AutoCycle and phase == "Throw" then
		phaseCatches += 1
	end
end

if ThrowCtrl and ThrowCtrl.Finished then
	track(ThrowCtrl.Finished:Connect(onCatch))
end

local function shouldThrow()
	if State.AutoCycle then return phase == "Throw" and phaseCatches < State.ThrowCatches end
	return State.AutoThrow
end

local function shouldTrain()
	if State.AutoCycle then return phase == "Train" end
	return State.AutoTrain
end

local function stopTrain()
	local running = TrainCtrl and type(TrainCtrl.IsRunning) == "function" and TrainCtrl.IsRunning()
	if remoteTraining or lp:GetAttribute("Training") == true or running then
		remoteTraining = false
		if TrainCtrl and type(TrainCtrl.Stop) == "function" and running then
			pcall(TrainCtrl.Stop)
		elseif Remotes then
			pcall(Remotes.Invoke, "Training_Stop")
		end
	end
end

local function doThrow(keepFn)
	if not (Remotes and ThrowCtrl) then task.wait(0.3) return end

	if ClientState and ClientState.Busy then task.wait(0.2) return end
	if lp:GetAttribute("Training") == true then
		stopTrain()
		task.wait(0.2)
		return
	end

	local readyAt = lp:GetAttribute("ThrowReadyAt")
	if type(readyAt) == "number" then
		local rem = readyAt - workspace:GetServerTimeNow()
		if rem > 0.02 and not waitWhile(rem + 0.05, keepFn) then return end
	end

	local char = lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum and hum.Health > 0) then task.wait(0.3) return end

	pushPower(true)
	syncPerfect()

	if State.InstantThrow then
		local lineCF = getLineCF(false)
		local moved = (hrp.Position - lineCF.Position).Magnitude > 10
		local oldCF = hrp.CFrame

		if moved then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = lineCF
			task.wait(0.15)
			if not alive or not keepFn() then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = oldCF
				return
			end
		end

		local okS, res = pcall(Remotes.Invoke, "Throw_Start")
		if moved and hrp.Parent then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = oldCF
		end

		if not (okS and type(res) == "table" and res.Ok) then
			if type(res) == "table" and res.Reason == "TooFar" then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = lineCF
				task.wait(0.2)
			else
				task.wait(0.3)
			end
			return
		end

		remoteThrowing = true
		pcall(function() Remotes.Event("Throw_MeterStarted"):FireServer() end)

		local meter = 0
		if State.AlwaysPerfect then
			if not exactWait(halfPeriod, keepFn) then
				pcall(Remotes.Invoke, "Throw_Cancel", "Aborted")
				remoteThrowing = false
				return
			end
			meter = 1.0
		end

		local okR, rRes = pcall(Remotes.Invoke, "Throw_Resolve", meter)
		if okR and type(rRes) == "table" and rRes.Ok then
			pcall(function() Remotes.Event("Throw_Revealed"):FireServer() end)
			pcall(Remotes.Invoke, "Throw_Complete")
			onCatch()
		else
			pcall(Remotes.Invoke, "Throw_Cancel", "ResolveFailed")
		end
		remoteThrowing = false

		if State.ThrowDelay > 0 then waitWhile(State.ThrowDelay, keepFn) end
	else
		local lineCF = getLineCF(false)
		if (hrp.Position - lineCF.Position).Magnitude > 10 then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = lineCF
			task.wait(0.15)
		end

		if type(ThrowCtrl.Start) == "function" then
			task.spawn(ThrowCtrl.Start)
		else
			hrp.CFrame = getLineCF(true)
		end

		local deadline = os.clock() + 20
		task.wait(0.2)
		while alive and keepFn() and ClientState and ClientState.Busy == "Throw" and os.clock() < deadline do
			task.wait(0.15)
		end
		if not (ThrowCtrl and ThrowCtrl.Finished) then
			onCatch()
		end
		if State.ThrowDelay > 0 then waitWhile(State.ThrowDelay, keepFn) end
	end
end


local PageThrow = makeTab("Throw", "Throw", Icons.Throw)
addToggle(PageThrow, 1, "Auto Throw", "AutoThrow")
addToggle(PageThrow, 2, "Instant Throw", "InstantThrow", saveCfg)
addToggle(PageThrow, 3, "Always Perfect", "AlwaysPerfect", function()
	syncPerfect()
	saveCfg()
end)
addSegmented(PageThrow, 4, "Target", "Target", { "Nearest", "Rarest", "Manual" }, function()
	pushPower(false)
	saveCfg()
end)
addSlider(PageThrow, 5, "Throw Delay", "ThrowDelay", 0.0, 2.0, 0.05, "s", "%.2f", saveCfg)
addSlider(PageThrow, 6, "Throw Power", "ThrowPower", 50, 100, 1, "%", "%d", function()
	pushPower(false)
	saveCfg()
end)

local PageFarm = makeTab("Farm", "Farm", Icons.Farm)
addToggle(PageFarm, 1, "Auto Train", "AutoTrain", function(on)
	if not on and not State.AutoCycle then stopTrain() end
end)
addToggle(PageFarm, 2, "Auto Cycle", "AutoCycle", function(on)
	if on then
		local stand = DataCtrl and (DataCtrl:Get("Stand") or 0) or 0
		phase = (stand >= 1) and "Train" or "Throw"
		phaseStart = os.clock()
		phaseDur = State.TrainTime
		phaseCatches = 0
		cycleCount = 0
	else
		stopTrain()
	end
end)
addToggle(PageFarm, 3, "Auto Claim", "AutoClaim", saveCfg)

local oldIdled = {}
local function resetGameIdle()
	if AfkCtrl and type(AfkCtrl.IdleSeconds) == "function" and debug and type(debug.setupvalue) == "function" then
		pcall(debug.setupvalue, AfkCtrl.IdleSeconds, 1, os.clock())
	end
end

local function onIdled()
	if not alive or not State.AntiAfk then return end
	resetGameIdle()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end

local function setAntiAfk(on)
	if on then
		if GameConfig and GameConfig.AFKRejoin and not table.isfrozen(GameConfig.AFKRejoin) then
			GameConfig.AFKRejoin.IdleSeconds = math.huge
		end
		resetGameIdle()
		local gc = getconnections or get_signal_cons
		if not gc then return end
		pcall(function()
			for _, c in pairs(gc(lp.Idled)) do
				if c.Function ~= onIdled then
					if c.Disable then
						c:Disable()
						table.insert(oldIdled, c)
					elseif c.Disconnect then
						c:Disconnect()
					end
				end
			end
		end)
	else
		resetGameIdle()
		if GameConfig and GameConfig.AFKRejoin and not table.isfrozen(GameConfig.AFKRejoin) then
			GameConfig.AFKRejoin.IdleSeconds = origAfkIdle
		end
		for _, c in pairs(oldIdled) do
			pcall(function() if c.Enable then c:Enable() end end)
		end
		table.clear(oldIdled)
	end
end

addToggle(PageFarm, 4, "Anti-AFK", "AntiAfk", function(on)
	setAntiAfk(on)
	saveCfg()
end)
addSlider(PageFarm, 5, "Train Time", "TrainTime", 5, 120, 5, "s", "%d", saveCfg)
addSlider(PageFarm, 6, "Throw Catches", "ThrowCatches", 1, 25, 1, "", "%d", saveCfg)

local PagePlot = makeTab("Plot", "Plot", Icons.Plot)
addToggle(PagePlot, 1, "Auto Equip Best", "AutoEquipBest")
addToggle(PagePlot, 2, "Auto Sell", "AutoSell")
addToggle(PagePlot, 3, "Keep Mutated", "KeepMutated", saveCfg)
addCycleRow(PagePlot, 4, "Keep Rarity", "KeepRarity", {
	"Sell All", "Uncommon", "Rare", "Epic", "Legendary", "Mythic",
	"Secret", "Divine", "Celestial", "Eternal", "Cosmic", "Supreme", "Sovereign",
}, saveCfg)
addToggle(PagePlot, 5, "Auto Buy Food", "AutoBuyFood")
addToggle(PagePlot, 6, "Auto Upgrade Stand", "AutoUpStand")
addToggle(PagePlot, 7, "Auto Upgrade Fence", "AutoUpFence")

local PageAreas = makeTab("Areas", "Areas", Icons.Areas)

do
	local areaList = (AreasConfig and AreasConfig.List) or {}
	local curAreaIdx = 1
	local curAnimIdx = 1
	local curAnimals = {}

	local function fmtNum(n)
		n = tonumber(n) or 0
		local abs = math.abs(n)
		local units = {
			{ 1e69, "Dvg" }, { 1e66, "Uvg" }, { 1e63, "Vg" }, { 1e60, "Nod" },
			{ 1e57, "Ocd" }, { 1e54, "Spd" }, { 1e51, "Sxd" }, { 1e48, "Qid" },
			{ 1e45, "Qad" }, { 1e42, "Td" }, { 1e39, "Dd" }, { 1e36, "Ud" },
			{ 1e33, "Dc" }, { 1e30, "No" }, { 1e27, "Oc" }, { 1e24, "Sp" },
			{ 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qd" }, { 1e12, "T" },
			{ 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" },
		}
		for _, u in ipairs(units) do
			if abs >= u[1] then
				return string.format("%.2f%s", n / u[1], u[2]):gsub("%.00", "")
			end
		end
		return tostring(math.floor(n + 0.5))
	end

	local function powerForDist(d)
		if not LevelConfig then return 0, 1 end
		local lv = LevelConfig.LevelForDistance(d)
		return LevelConfig.ThrowPowerForLevel(lv), lv
	end

	if #areaList > 0 and DataCtrl and LevelConfig then
		local myPow = LevelConfig.ThrowPowerForLevel(DataCtrl:Get("Level") or 1)
		for i, a in ipairs(areaList) do
			local pStart = powerForDist(a.StartDistance or 0)
			if myPow >= pStart then curAreaIdx = i end
		end
	end

	local AreaBar = Instance.new("Frame")
	AreaBar.Size = UDim2.new(1, 0, 0, 42)
	AreaBar.BackgroundColor3 = Theme.Row
	AreaBar.BorderSizePixel = 0
	AreaBar.LayoutOrder = 1
	AreaBar.ZIndex = 13
	AreaBar.Parent = PageAreas
	corner(AreaBar, 9, 0)
	stroke(AreaBar, Theme.Border, 1, 0.5)
	addSurface(AreaBar, 0.08)

	local PrevArea = Instance.new("TextButton")
	PrevArea.Size = UDim2.fromOffset(34, 42)
	PrevArea.BackgroundTransparency = 1
	PrevArea.Text = "<"
	PrevArea.TextColor3 = Theme.Muted
	PrevArea.FontFace = fBold
	PrevArea.TextSize = 15
	PrevArea.AutoButtonColor = false
	PrevArea.ZIndex = 14
	PrevArea.Parent = AreaBar

	local NextArea = Instance.new("TextButton")
	NextArea.Size = UDim2.fromOffset(34, 42)
	NextArea.Position = UDim2.new(1, -34, 0, 0)
	NextArea.BackgroundTransparency = 1
	NextArea.Text = ">"
	NextArea.TextColor3 = Theme.Muted
	NextArea.FontFace = fBold
	NextArea.TextSize = 15
	NextArea.AutoButtonColor = false
	NextArea.ZIndex = 14
	NextArea.Parent = AreaBar

	local AreaTitle = Instance.new("TextButton")
	AreaTitle.Size = UDim2.new(1, -68, 1, 0)
	AreaTitle.Position = UDim2.fromOffset(34, 0)
	AreaTitle.BackgroundTransparency = 1
	AreaTitle.Text = "Forest (1/20)"
	AreaTitle.TextColor3 = Theme.Text
	AreaTitle.FontFace = fBold
	AreaTitle.TextSize = 14
	AreaTitle.AutoButtonColor = false
	AreaTitle.ZIndex = 14
	AreaTitle.Parent = AreaBar

	local StatsCard = Instance.new("Frame")
	StatsCard.Size = UDim2.new(1, 0, 0, 62)
	StatsCard.BackgroundColor3 = Theme.Row
	StatsCard.BorderSizePixel = 0
	StatsCard.LayoutOrder = 2
	StatsCard.ZIndex = 13
	StatsCard.Parent = PageAreas
	corner(StatsCard, 9, 0)
	stroke(StatsCard, Theme.Border, 1, 0.5)
	addSurface(StatsCard, 0.08)

	local AreaPowLbl = Instance.new("TextLabel")
	AreaPowLbl.Size = UDim2.new(1, -110, 0, 22)
	AreaPowLbl.Position = UDim2.fromOffset(12, 8)
	AreaPowLbl.BackgroundTransparency = 1
	AreaPowLbl.Text = "Power: 18 - 173"
	AreaPowLbl.TextColor3 = Theme.AccentBright
	AreaPowLbl.FontFace = fMono
	AreaPowLbl.TextSize = 13
	AreaPowLbl.TextXAlignment = Enum.TextXAlignment.Left
	AreaPowLbl.ZIndex = 14
	AreaPowLbl.Parent = StatsCard

	local AreaMetaLbl = Instance.new("TextLabel")
	AreaMetaLbl.Size = UDim2.new(1, -24, 0, 18)
	AreaMetaLbl.Position = UDim2.fromOffset(12, 34)
	AreaMetaLbl.BackgroundTransparency = 1
	AreaMetaLbl.Text = "Min Level: 1  |  Distance: 5m - 173m"
	AreaMetaLbl.TextColor3 = Theme.Muted
	AreaMetaLbl.FontFace = fSemi
	AreaMetaLbl.TextSize = 11
	AreaMetaLbl.TextXAlignment = Enum.TextXAlignment.Left
	AreaMetaLbl.ZIndex = 14
	AreaMetaLbl.Parent = StatsCard

	local ReachBadge = Instance.new("TextLabel")
	ReachBadge.Size = UDim2.fromOffset(88, 22)
	ReachBadge.Position = UDim2.new(1, -98, 0, 8)
	ReachBadge.BackgroundColor3 = Theme.AccentSoft
	ReachBadge.BackgroundTransparency = 0.2
	ReachBadge.Text = "Unlocked"
	ReachBadge.TextColor3 = Theme.AccentBright
	ReachBadge.FontFace = fMono
	ReachBadge.TextSize = 10
	ReachBadge.ZIndex = 14
	ReachBadge.Parent = StatsCard
	corner(ReachBadge, 6, 0)

	local AnimCard = Instance.new("Frame")
	AnimCard.Size = UDim2.new(1, 0, 0, 188)
	AnimCard.BackgroundColor3 = Theme.Row
	AnimCard.BorderSizePixel = 0
	AnimCard.LayoutOrder = 3
	AnimCard.ZIndex = 13
	AnimCard.Parent = PageAreas
	corner(AnimCard, 9, 0)
	stroke(AnimCard, Theme.Border, 1, 0.5)
	addSurface(AnimCard, 0.08)

	local Vpf = Instance.new("Frame")
	Vpf.Name = "AnimalPreviewBox"
	Vpf.Size = UDim2.fromOffset(162, 162)
	Vpf.Position = UDim2.fromOffset(12, 13)
	Vpf.BackgroundColor3 = Theme.Well
	Vpf.BackgroundTransparency = 0.15
	Vpf.BorderSizePixel = 0
	Vpf.ZIndex = 14
	Vpf.Parent = AnimCard
	corner(Vpf, 9, 0)
	local VpfStroke = stroke(Vpf, Theme.Border, 1.2, 0.3)

	local AnimImg = Instance.new("ImageLabel")
	AnimImg.Name = "AnimalIcon"
	AnimImg.Size = UDim2.new(1, -12, 1, -12)
	AnimImg.Position = UDim2.fromOffset(6, 6)
	AnimImg.BackgroundTransparency = 1
	AnimImg.Image = ""
	AnimImg.ScaleType = Enum.ScaleType.Fit
	AnimImg.ZIndex = 15
	AnimImg.Parent = Vpf

	local AnimNameLbl = Instance.new("TextLabel")
	AnimNameLbl.Size = UDim2.new(1, -196, 0, 22)
	AnimNameLbl.Position = UDim2.fromOffset(186, 14)
	AnimNameLbl.BackgroundTransparency = 1
	AnimNameLbl.Text = "Snail"
	AnimNameLbl.TextColor3 = Theme.Text
	AnimNameLbl.FontFace = fBold
	AnimNameLbl.TextSize = 15
	AnimNameLbl.TextXAlignment = Enum.TextXAlignment.Left
	AnimNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	AnimNameLbl.ZIndex = 14
	AnimNameLbl.Parent = AnimCard

	local AnimRarLbl = Instance.new("TextLabel")
	AnimRarLbl.Size = UDim2.new(1, -196, 0, 18)
	AnimRarLbl.Position = UDim2.fromOffset(186, 37)
	AnimRarLbl.BackgroundTransparency = 1
	AnimRarLbl.Text = "Common"
	AnimRarLbl.TextColor3 = Theme.Muted
	AnimRarLbl.FontFace = fSemi
	AnimRarLbl.TextSize = 12
	AnimRarLbl.TextXAlignment = Enum.TextXAlignment.Left
	AnimRarLbl.ZIndex = 14
	AnimRarLbl.Parent = AnimCard

	local AnimPowLbl = Instance.new("TextLabel")
	AnimPowLbl.Size = UDim2.new(1, -196, 0, 20)
	AnimPowLbl.Position = UDim2.fromOffset(186, 66)
	AnimPowLbl.BackgroundTransparency = 1
	AnimPowLbl.Text = "Power: ~28"
	AnimPowLbl.TextColor3 = Theme.AccentBright
	AnimPowLbl.FontFace = fMono
	AnimPowLbl.TextSize = 12
	AnimPowLbl.TextXAlignment = Enum.TextXAlignment.Left
	AnimPowLbl.ZIndex = 14
	AnimPowLbl.Parent = AnimCard

	local AnimLvlLbl = Instance.new("TextLabel")
	AnimLvlLbl.Size = UDim2.new(1, -196, 0, 18)
	AnimLvlLbl.Position = UDim2.fromOffset(186, 88)
	AnimLvlLbl.BackgroundTransparency = 1
	AnimLvlLbl.Text = "Est. Level: 3"
	AnimLvlLbl.TextColor3 = Theme.Muted
	AnimLvlLbl.FontFace = fMono
	AnimLvlLbl.TextSize = 11
	AnimLvlLbl.TextXAlignment = Enum.TextXAlignment.Left
	AnimLvlLbl.ZIndex = 14
	AnimLvlLbl.Parent = AnimCard

	local AnimIncLbl = Instance.new("TextLabel")
	AnimIncLbl.Size = UDim2.new(1, -196, 0, 18)
	AnimIncLbl.Position = UDim2.fromOffset(186, 108)
	AnimIncLbl.BackgroundTransparency = 1
	AnimIncLbl.Text = "Income: $1/s"
	AnimIncLbl.TextColor3 = Theme.Amber
	AnimIncLbl.FontFace = fMono
	AnimIncLbl.TextSize = 11
	AnimIncLbl.TextXAlignment = Enum.TextXAlignment.Left
	AnimIncLbl.ZIndex = 14
	AnimIncLbl.Parent = AnimCard

	local AnimNav = Instance.new("Frame")
	AnimNav.Size = UDim2.new(1, -198, 0, 30)
	AnimNav.Position = UDim2.fromOffset(186, 144)
	AnimNav.BackgroundColor3 = Theme.Well
	AnimNav.BackgroundTransparency = 0.2
	AnimNav.BorderSizePixel = 0
	AnimNav.ZIndex = 14
	AnimNav.Parent = AnimCard
	corner(AnimNav, 7, 0)
	stroke(AnimNav, Theme.Border, 1, 0.35)

	local PrevAnim = Instance.new("TextButton")
	PrevAnim.Size = UDim2.fromOffset(32, 30)
	PrevAnim.BackgroundTransparency = 1
	PrevAnim.Text = "<"
	PrevAnim.TextColor3 = Theme.Muted
	PrevAnim.FontFace = fBold
	PrevAnim.TextSize = 14
	PrevAnim.AutoButtonColor = false
	PrevAnim.ZIndex = 15
	PrevAnim.Parent = AnimNav

	local NextAnim = Instance.new("TextButton")
	NextAnim.Size = UDim2.fromOffset(32, 30)
	NextAnim.Position = UDim2.new(1, -32, 0, 0)
	NextAnim.BackgroundTransparency = 1
	NextAnim.Text = ">"
	NextAnim.TextColor3 = Theme.Muted
	NextAnim.FontFace = fBold
	NextAnim.TextSize = 14
	NextAnim.AutoButtonColor = false
	NextAnim.ZIndex = 15
	NextAnim.Parent = AnimNav

	local AnimCountLbl = Instance.new("TextLabel")
	AnimCountLbl.Size = UDim2.new(1, -64, 1, 0)
	AnimCountLbl.Position = UDim2.fromOffset(32, 0)
	AnimCountLbl.BackgroundTransparency = 1
	AnimCountLbl.Text = "1 / 8"
	AnimCountLbl.TextColor3 = Theme.Text
	AnimCountLbl.FontFace = fMono
	AnimCountLbl.TextSize = 11
	AnimCountLbl.ZIndex = 15
	AnimCountLbl.Parent = AnimNav

	local function load3D(modelName, rarCol)
		local id = modelName and IconImages and IconImages.Animals and IconImages.Animals[modelName]
		if id then
			AnimImg.Image = "rbxassetid://" .. string.format("%.0f", tonumber(id) or 0)
		else
			AnimImg.Image = ""
		end
		VpfStroke.Color = rarCol or Theme.Border
	end

	local function renderAnimal()
		local area = areaList[curAreaIdx]
		if not area or #curAnimals == 0 then
			AnimNameLbl.Text = "No animals"
			AnimCountLbl.Text = "0 / 0"
			load3D(nil)
			return
		end
		curAnimIdx = ((curAnimIdx - 1) % #curAnimals) + 1
		local entry = curAnimals[curAnimIdx]
		local mName = entry.ModelName or entry.Name
		local econ = AnimalEconomy and AnimalEconomy.Get and AnimalEconomy.Get(mName)
		local rarName = (econ and econ.Rarity) or "Common"
		local rarInfo = RarityConfig and RarityConfig.ByName and RarityConfig.ByName[rarName]

		AnimNameLbl.Text = entry.Name or mName
		AnimRarLbl.Text = rarName
		AnimRarLbl.TextColor3 = (rarInfo and rarInfo.Color) or Theme.Muted

		local rank = (econ and tonumber(econ.Rank)) or curAnimIdx
		local estDist = (area.StartDistance or 0) + ((rank - 0.5) / math.max(1, #curAnimals)) * (area.Length or 168)
		local estPow, estLv = powerForDist(estDist)
		AnimPowLbl.Text = "Power: ~" .. fmtNum(estPow)
		AnimLvlLbl.Text = "Est. Level: " .. tostring(estLv)
		AnimIncLbl.Text = "Income: $" .. fmtNum(econ and econ.Income or 0) .. "/s"
		AnimCountLbl.Text = string.format("%d / %d", curAnimIdx, #curAnimals)
		load3D(mName, rarInfo and rarInfo.Color)
	end

	local function renderArea()
		if #areaList == 0 then return end
		curAreaIdx = ((curAreaIdx - 1) % #areaList) + 1
		local area = areaList[curAreaIdx]
		local sDist = area.StartDistance or 0
		local eDist = sDist + (area.Length or 0)
		local pStart, lvStart = powerForDist(sDist)
		local pEnd = powerForDist(eDist)

		AreaTitle.Text = string.format("%s (%d/%d)", area.Name or area.Key, curAreaIdx, #areaList)
		AreaPowLbl.Text = string.format("Power: %s - %s", fmtNum(pStart), fmtNum(pEnd))
		AreaMetaLbl.Text = string.format("Min Level: %d  |  Dist: %dm - %dm", lvStart, math.floor(sDist), math.floor(eDist))

		local myPow = (DataCtrl and LevelConfig) and LevelConfig.ThrowPowerForLevel(DataCtrl:Get("Level") or 1) or 0
		if myPow >= pStart then
			ReachBadge.Text = "Unlocked"
			ReachBadge.TextColor3 = Theme.AccentBright
			ReachBadge.BackgroundColor3 = Theme.AccentSoft
		else
			ReachBadge.Text = "Need +" .. fmtNum(pStart - myPow)
			ReachBadge.TextColor3 = Theme.Amber
			ReachBadge.BackgroundColor3 = Theme.Well
		end

		curAnimals = {}
		if AnimalEconomy and type(AnimalEconomy.List) == "table" then
			for mName, info in pairs(AnimalEconomy.List) do
				if type(info) == "table" and info.Area == area.Key then
					table.insert(curAnimals, {
						ModelName = mName,
						Name = info.DisplayName or info.Name or mName,
						Rank = tonumber(info.Rank) or 999,
					})
				end
			end
			table.sort(curAnimals, function(a, b) return a.Rank < b.Rank end)
		end
		curAnimIdx = 1
		renderAnimal()
	end

	PrevArea.MouseButton1Click:Connect(function() curAreaIdx -= 1 renderArea() end)
	NextArea.MouseButton1Click:Connect(function() curAreaIdx += 1 renderArea() end)
	AreaTitle.MouseButton1Click:Connect(function() curAreaIdx += 1 renderArea() end)
	PrevAnim.MouseButton1Click:Connect(function() curAnimIdx -= 1 renderAnimal() end)
	NextAnim.MouseButton1Click:Connect(function() curAnimIdx += 1 renderAnimal() end)

	renderArea()
end

local PageSettings = makeTab("Settings", "Settings", Icons.Settings)
addToggle(PageSettings, 1, "Auto Save Config", "AutoSave", function(on)
	if on then saveCfg() end
end)
addSlider(PageSettings, 2, "Background Transparency", "BgTransparency", 0, 70, 5, "%", "%d", function()
	updateAlpha()
	saveCfg()
end)
addToggle(PageSettings, 3, "Border Glow", "BorderGlow", function()
	updateGlow()
	saveCfg()
end)
addSlider(PageSettings, 4, "Glow Speed", "GlowSpeed", 30, 220, 10, "", "%d", saveCfg)
addToggle(PageSettings, 5, "Cooldown HUD", "CooldownHud", function()
	updateStatus()
	saveCfg()
end)
addSegmented(PageSettings, 6, "UI Scale", "ScaleLabel", { "85%", "100%", "115%", "130%" }, function(val)
	local map = { ["85%"] = 0.85, ["100%"] = 1.0, ["115%"] = 1.15, ["130%"] = 1.30 }
	State.UiScale = map[val] or 1.0
	local sc = getScale()
	tw(WinScale, 0.16, { Scale = sc })
	HudScale.Scale = math.clamp(sc, 0.62, 1.0)
	saveCfg()
end)

local KeyRow = Instance.new("Frame")
KeyRow.Name = "Keybind_ToggleKey"
KeyRow.Size = UDim2.new(1, 0, 0, 44)
KeyRow.BackgroundColor3 = Theme.Row
KeyRow.BorderSizePixel = 0
KeyRow.LayoutOrder = 7
KeyRow.ZIndex = 13
KeyRow.Parent = PageSettings
corner(KeyRow, 9, 0)
stroke(KeyRow, Theme.Border, 1, 0.5)
addSurface(KeyRow, 0.08)

local KeyLbl = Instance.new("TextLabel")
KeyLbl.Size = UDim2.new(1, -130, 1, 0)
KeyLbl.Position = UDim2.fromOffset(14, 0)
KeyLbl.BackgroundTransparency = 1
KeyLbl.Text = "Toggle Key"
KeyLbl.TextColor3 = Theme.Text
KeyLbl.FontFace = fSemi
KeyLbl.TextSize = 14
KeyLbl.TextXAlignment = Enum.TextXAlignment.Left
KeyLbl.ZIndex = 14
KeyLbl.Parent = KeyRow

local KeyBtn = Instance.new("TextButton")
KeyBtn.Size = UDim2.fromOffset(104, 26)
KeyBtn.Position = UDim2.new(1, -116, 0.5, -13)
KeyBtn.BackgroundColor3 = Theme.Well
KeyBtn.BackgroundTransparency = 0.2
KeyBtn.Text = State.ToggleKey.Name
KeyBtn.TextColor3 = Theme.AccentBright
KeyBtn.FontFace = fMono
KeyBtn.TextSize = 11
KeyBtn.AutoButtonColor = false
KeyBtn.ZIndex = 14
KeyBtn.Parent = KeyRow
corner(KeyBtn, 6, 0)

local bindingKey = false
KeyBtn.MouseButton1Click:Connect(function()
	bindingKey = true
	KeyBtn.Text = "..."
	KeyBtn.TextColor3 = Theme.Amber
end)

local ActionRow = Instance.new("Frame")
ActionRow.Size = UDim2.new(1, 0, 0, 38)
ActionRow.BackgroundTransparency = 1
ActionRow.LayoutOrder = 8
ActionRow.ZIndex = 13
ActionRow.Parent = PageSettings

local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(0.5, -4, 1, 0)
ResetBtn.BackgroundColor3 = Theme.Row
ResetBtn.Text = "Reset Position"
ResetBtn.TextColor3 = Theme.Text
ResetBtn.FontFace = fSemi
ResetBtn.TextSize = 13
ResetBtn.AutoButtonColor = false
ResetBtn.ZIndex = 14
ResetBtn.Parent = ActionRow
corner(ResetBtn, 8, 0)
stroke(ResetBtn, Theme.Border, 1, 0.4)
addSurface(ResetBtn, 0.08)

local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Size = UDim2.new(0.5, -4, 1, 0)
UnloadBtn.Position = UDim2.new(0.5, 4, 0, 0)
UnloadBtn.BackgroundColor3 = Theme.DangerBg
UnloadBtn.BackgroundTransparency = 0.15
UnloadBtn.Text = "Unload"
UnloadBtn.TextColor3 = Theme.Danger
UnloadBtn.FontFace = fSemi
UnloadBtn.TextSize = 13
UnloadBtn.AutoButtonColor = false
UnloadBtn.ZIndex = 14
UnloadBtn.Parent = ActionRow
corner(UnloadBtn, 8, 0)
stroke(UnloadBtn, Theme.Danger, 1, 0.55)

ResetBtn.MouseButton1Click:Connect(function()
	tw(Window, 0.2, { Position = UDim2.fromScale(0.5, 0.5) })
	tw(OrbButton, 0.2, { Position = ORB_POS })
	tw(HudBox, 0.2, { Position = HUD_POS })
end)


do
	local dragInp, dStart, pStart = nil, Vector3.zero, Window.Position
	Window.InputBegan:Connect(function(inp)
		if not dragInp and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
			if (inp.Position.Y - Window.AbsolutePosition.Y) <= 52 * WinScale.Scale then
				dragInp = inp
				dStart = inp.Position
				pStart = Window.Position
			end
		end
	end)
	track(uis.InputChanged:Connect(function(inp)
		if not dragInp then return end
		if (dragInp.UserInputType == Enum.UserInputType.Touch and inp == dragInp)
			or (dragInp.UserInputType == Enum.UserInputType.MouseButton1 and inp.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = inp.Position - dStart
			Window.Position = UDim2.new(pStart.X.Scale, pStart.X.Offset + d.X, pStart.Y.Scale, pStart.Y.Offset + d.Y)
		end
	end))
	track(uis.InputEnded:Connect(function(inp)
		if dragInp and inp == dragInp then
			dragInp = nil
		end
	end))
end

do
	local dragInp, moved = nil, false
	local startInp, startPos = Vector3.zero, OrbButton.Position

	OrbButton.MouseEnter:Connect(function()
		tw(OrbScale, 0.12, { Scale = 1.07 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
	OrbButton.MouseLeave:Connect(function()
		tw(OrbScale, 0.12, { Scale = 1.0 })
	end)
	OrbButton.InputBegan:Connect(function(inp)
		if not dragInp and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
			dragInp = inp
			moved = false
			startInp = inp.Position
			startPos = OrbButton.Position
			tw(OrbScale, 0.08, { Scale = 0.94 })
		end
	end)
	track(uis.InputChanged:Connect(function(inp)
		if not dragInp then return end
		if (dragInp.UserInputType == Enum.UserInputType.Touch and inp == dragInp)
			or (dragInp.UserInputType == Enum.UserInputType.MouseButton1 and inp.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = inp.Position - startInp
			local thresh = (dragInp.UserInputType == Enum.UserInputType.Touch) and 9 or 6
			if d.Magnitude >= thresh then moved = true end
			if moved then
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
				local nx = math.clamp(startPos.X.Scale * vp.X + startPos.X.Offset + d.X, 8, vp.X - 66)
				local ny = math.clamp(startPos.Y.Scale * vp.Y + startPos.Y.Offset + d.Y, 8, vp.Y - 66)
				OrbButton.Position = UDim2.fromOffset(nx, ny)
			end
		end
	end))
	track(uis.InputEnded:Connect(function(inp)
		if dragInp and inp == dragInp then
			dragInp = nil
			tw(OrbScale, 0.12, { Scale = 1.0 })
			if not moved then toggleWin(not isOpen) end
		end
	end))
end

track(uis.InputBegan:Connect(function(inp, gpe)
	if bindingKey then
		if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode ~= Enum.KeyCode.Unknown then
			bindingKey = false
			State.ToggleKey = inp.KeyCode
			KeyBtn.Text = inp.KeyCode.Name
			KeyBtn.TextColor3 = Theme.AccentBright
			if not isMobile then FooterLbl.Text = inp.KeyCode.Name end
			saveCfg()
		end
		return
	end
	if not gpe and inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == State.ToggleKey then
		toggleWin(not isOpen)
	end
end))

do
	local dragInp, dStart, pStart = nil, Vector3.zero, HudBox.Position
	HudBox.InputBegan:Connect(function(inp)
		if not dragInp and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
			dragInp = inp
			dStart = inp.Position
			pStart = HudBox.Position
		end
	end)
	track(uis.InputChanged:Connect(function(inp)
		if not dragInp then return end
		if (dragInp.UserInputType == Enum.UserInputType.Touch and inp == dragInp)
			or (dragInp.UserInputType == Enum.UserInputType.MouseButton1 and inp.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = inp.Position - dStart
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
			local w = math.max(120, HudBox.AbsoluteSize.X)
			local h = math.max(64, HudBox.AbsoluteSize.Y)
			local nx = math.clamp(pStart.X.Offset + d.X, 6, math.max(6, vp.X - w - 6))
			local ny = math.clamp(pStart.Y.Offset + d.Y, 6, math.max(6, vp.Y - h - 6))
			HudBox.Position = UDim2.fromOffset(nx, ny)
		end
	end))
	track(uis.InputEnded:Connect(function(inp)
		if dragInp and inp == dragInp then
			dragInp = nil
		end
	end))
end

local vpConn = nil
local function onViewportChanged()
	if not alive then return end
	local sc = getScale()
	if not animLock then
		WinScale.Scale = sc
	end
	HudScale.Scale = math.clamp(sc, 0.62, 1.0)
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize
	if vp and vp.X > 0 and vp.Y > 0 then
		if OrbButton.Position.X.Scale == 0 and OrbButton.Position.Y.Scale == 0 then
			OrbButton.Position = UDim2.fromOffset(
				math.clamp(OrbButton.Position.X.Offset, 8, math.max(8, vp.X - 66)),
				math.clamp(OrbButton.Position.Y.Offset, 8, math.max(8, vp.Y - 66))
			)
		end
		local w = math.max(120, HudBox.AbsoluteSize.X)
		local h = math.max(64, HudBox.AbsoluteSize.Y)
		HudBox.Position = UDim2.fromOffset(
			math.clamp(HudBox.Position.X.Offset, 6, math.max(6, vp.X - w - 6)),
			math.clamp(HudBox.Position.Y.Offset, 6, math.max(6, vp.Y - h - 6))
		)
	end
end

local function watchCamera()
	if vpConn then pcall(function() vpConn:Disconnect() end) end
	local cam = workspace.CurrentCamera
	if cam then
		vpConn = track(cam:GetPropertyChangedSignal("ViewportSize"):Connect(onViewportChanged))
	end
end
watchCamera()
track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera))

local glowSpd = State.GlowSpeed
local lastHudTick, lastCdMax = 0, 0
track(RunService.RenderStepped:Connect(function(dt)
	if not alive then return end

	if State.BorderGlow then
		local want = anyRunning() and math.max(State.GlowSpeed * 2.2, 200) or State.GlowSpeed
		glowSpd += (want - glowSpd) * math.min(1, dt * 8)
		local step = dt * glowSpd
		if Window.Visible then
			WinGrad.Rotation = (WinGrad.Rotation + step) % 360
		end
		if HudBox.Visible then
			HudGrad.Rotation = (HudGrad.Rotation + step * 0.85) % 360
		end
	end

	local now = os.clock()
	if HudBox.Visible and (now - lastHudTick) >= 0.06 then
		lastHudTick = now

		local readyAt = lp:GetAttribute("ThrowReadyAt")
		local cdRem = (type(readyAt) == "number") and math.max(0, readyAt - workspace:GetServerTimeNow()) or 0
		if cdRem > lastCdMax then
			lastCdMax = cdRem
		elseif cdRem <= 0.02 then
			lastCdMax = 0
		end

		if cdRem > 0.05 then
			HudCdLbl.Text = string.format("CD: %.1fs", cdRem)
			HudCdLbl.TextColor3 = Theme.Amber
		else
			HudCdLbl.Text = "CD: Ready"
			HudCdLbl.TextColor3 = Theme.AccentBright
		end

		if State.AutoCycle then
			local isTrain = (phase == "Train")

			HudModeLbl.Text = "Auto Cycle"
			HudPhasePill.Text = isTrain and "TRAIN" or "THROW"
			HudPhasePill.TextColor3 = isTrain and Theme.AccentBright or Theme.Amber
			HudPhasePill.BackgroundColor3 = isTrain and Theme.AccentSoft or Theme.Well
			HudPhaseStroke.Color = isTrain and Theme.Accent or Theme.Amber

			if isTrain then
				local dur = math.max(1, phaseDur)
				local elapsed = math.clamp(now - phaseStart, 0, dur)
				local left = math.max(0, dur - elapsed)
				HudTimerLbl.Text = "Next: Throw"
				HudTimerVal.Text = string.format("%.1fs / %ds", left, dur)
				HudFill.Size = UDim2.fromScale(math.clamp(1 - (elapsed / dur), 0, 1), 1)
				HudFill.BackgroundColor3 = Theme.Accent
			else
				local target = math.max(1, State.ThrowCatches)
				local done = math.min(phaseCatches, target)
				HudTimerLbl.Text = "Catches"
				HudTimerVal.Text = string.format("%d / %d", done, target)
				HudFill.Size = UDim2.fromScale(math.clamp(done / target, 0, 1), 1)
				HudFill.BackgroundColor3 = Theme.Amber
			end

			HudStatLbl.Text = "Cycles: " .. tostring(cycleCount)
			HudStatLbl.TextColor3 = Theme.Muted
		elseif State.AutoThrow then
			HudModeLbl.Text = "Auto Throw"
			HudPhasePill.Text = State.InstantThrow and "INSTANT" or "THROW"
			HudPhasePill.TextColor3 = Theme.AccentBright
			HudPhasePill.BackgroundColor3 = Theme.AccentSoft
			HudPhaseStroke.Color = Theme.Accent

			HudTimerLbl.Text = "Throw CD"
			if cdRem > 0.05 then
				HudTimerVal.Text = string.format("%.1fs", cdRem)
				local a = (lastCdMax > 0) and math.clamp(1 - (cdRem / lastCdMax), 0, 1) or 0
				HudFill.Size = UDim2.fromScale(a, 1)
				HudFill.BackgroundColor3 = Theme.Amber
			else
				HudTimerVal.Text = "Ready"
				HudFill.Size = UDim2.fromScale(1, 1)
				HudFill.BackgroundColor3 = Theme.Accent
			end

			HudStatLbl.Text = "Catches: " .. tostring(throwCount)
			HudStatLbl.TextColor3 = Theme.Muted
		elseif State.AutoTrain then
			local isRun = lp:GetAttribute("Training") == true or (TrainCtrl and type(TrainCtrl.IsRunning) == "function" and TrainCtrl.IsRunning())
			HudModeLbl.Text = "Auto Train"
			HudPhasePill.Text = isRun and "ACTIVE" or "WAIT"
			HudPhasePill.TextColor3 = Theme.AccentBright
			HudPhasePill.BackgroundColor3 = Theme.AccentSoft
			HudPhaseStroke.Color = Theme.Accent

			HudTimerLbl.Text = "Status"
			HudTimerVal.Text = isRun and "Training" or "Starting"
			HudFill.Size = UDim2.fromScale(isRun and 1 or 0.35, 1)
			HudFill.BackgroundColor3 = Theme.Accent

			HudStatLbl.Text = State.AntiAfk and "AFK: Safe" or "AFK: Off"
			HudStatLbl.TextColor3 = State.AntiAfk and Theme.AccentBright or Theme.Dim
		end
	end
end))

local function cleanup()
	alive = false
	pcall(setAntiAfk, false)
	if ThrowMeter then ThrowMeter.TestAutoTap = nil end
	if remoteThrowing and Remotes then
		remoteThrowing = false
		task.spawn(pcall, Remotes.Invoke, "Throw_Cancel", "Unload")
	end
	if remoteTraining and Remotes then
		remoteTraining = false
		task.spawn(pcall, Remotes.Invoke, "Training_Stop")
	end
	for _, c in pairs(conns) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(conns)
	pcall(function() if Gui then Gui:Destroy() end end)
end


local function hit2x()
	local tseq = pg:FindFirstChild("TrainingSequence")
	local layer = tseq and tseq:FindFirstChild("TapBonusLayer", true)
	local btn = layer and layer:FindFirstChildWhichIsA("ImageButton")
	if btn and btn.Parent and btn.Active and type(firesignal) == "function" then
		pcall(firesignal, btn.Activated)
		return true
	end
	return false
end

if Remotes then
	local ok, ev = pcall(Remotes.Event, "Training_Bonus")
	if ok and ev then
		track(ev.OnClientEvent:Connect(function(bonusId)
			if not alive or bonusId == nil then return end
			if State.AutoTrain or State.AutoCycle then
				task.delay(0.18, function()
					if not alive or not (State.AutoTrain or State.AutoCycle) then return end
					if not hit2x() then
						pcall(Remotes.Invoke, "Training_TapBonus", bonusId)
					end
				end)
			end
		end))
	end
end

track(pg.DescendantAdded:Connect(function(d)
	if not alive or not (State.AutoTrain or State.AutoCycle) then return end
	if d:IsA("ImageButton") and d.Parent and d.Parent.Name == "TapBonusLayer" then
		task.delay(0.18, function()
			if alive and (State.AutoTrain or State.AutoCycle) and d.Parent and d.Active and type(firesignal) == "function" then
				pcall(firesignal, d.Activated)
			end
		end)
	end
end))

track(lp.Idled:Connect(onIdled))
setAntiAfk(State.AntiAfk)

task.spawn(function()
	while alive do
		if shouldThrow() then
			doThrow(shouldThrow)
		else
			task.wait(0.15)
		end
	end
end)

task.spawn(function()
	while alive do
		if shouldTrain() then
			local stand = DataCtrl and (DataCtrl:Get("Stand") or 0) or 0
			local running = TrainCtrl and type(TrainCtrl.IsRunning) == "function" and TrainCtrl.IsRunning()
			if stand < 1 then
				task.wait(0.8)
			elseif ClientState and ClientState.Busy == "Throw" then
				task.wait(0.25)
			elseif not running and lp:GetAttribute("Training") ~= true then
				local char = lp.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local spot = getTrainCF()
				if hrp and spot and (hrp.Position - spot.Position).Magnitude > 10 then
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.CFrame = spot
					task.wait(0.15)
				end
				if TrainCtrl and type(TrainCtrl.Start) == "function" then
					remoteTraining = true
					task.spawn(TrainCtrl.Start)
					task.wait(0.6)
				elseif Remotes then
					local okS, res = pcall(Remotes.Invoke, "Training_Start")
					if okS and type(res) == "table" and res.Ok then
						remoteTraining = true
					else
						task.wait(0.8)
					end
				else
					task.wait(0.5)
				end
			else
				hit2x()
				task.wait(0.3)
			end
		else
			if remoteTraining or (TrainCtrl and type(TrainCtrl.IsRunning) == "function" and TrainCtrl.IsRunning()) then
				stopTrain()
			end
			task.wait(0.2)
		end
	end
end)

task.spawn(function()
	while alive do
		if State.AutoCycle then
			local stand = DataCtrl and (DataCtrl:Get("Stand") or 0) or 0
			if stand >= 1 then
				phase = "Train"
				phaseStart = os.clock()
				phaseDur = State.TrainTime
				if not waitWhile(State.TrainTime, function() return State.AutoCycle end) then
					stopTrain()
					continue
				end
				stopTrain()
				task.wait(0.25)
			end

			phase = "Throw"
			phaseCatches = 0
			while alive and State.AutoCycle and phaseCatches < State.ThrowCatches do
				task.wait(0.1)
			end
			if not State.AutoCycle then
				continue
			end
			cycleCount += 1
			task.wait(0.25)
		else
			task.wait(0.25)
		end
	end
end)

task.spawn(function()
	local freeCd, idxCd = 0, 0
	while alive do
		if State.AutoClaim and Remotes and DataCtrl then
			local off = DataCtrl:Get("OfflinePending")
			if type(off) == "table" and ((tonumber(off.Base) or 0) > 0 or (tonumber(off.DoubleBase) or 0) > 0) then
				pcall(Remotes.Invoke, "Offline_Claim")
			end
			if DataCtrl:Get("FreeAnimalClaimed") == false and os.clock() >= freeCd then
				local ok, res = pcall(Remotes.Invoke, "Shop_ClaimFree")
				if not (ok and type(res) == "table" and res.Ok) then
					freeCd = os.clock() + 30
				end
			end
			if IndexRewardsConfig and IndexCtrl and os.clock() >= idxCd then
				for _, col in pairs(IndexRewardsConfig.Collections or {}) do
					if not alive or not State.AutoClaim then break end
					local ok, st = pcall(IndexCtrl.State, col.Key)
					if ok and st == "Claim" then
						pcall(Remotes.Invoke, "IndexRewards_Claim", col.Key)
						task.wait(0.2)
					end
				end
				idxCd = os.clock() + 12
			end
		end
		task.wait(6)
	end
end)

local function rarityOf(name)
	if not (AnimalEconomy and RarityConfig and RarityConfig.ByName) then return 1 end
	local econ = (type(AnimalEconomy.Get) == "function" and AnimalEconomy.Get(name))
		or (AnimalEconomy.List and AnimalEconomy.List[name])
	local info = RarityConfig.ByName[econ and econ.Rarity or "Common"]
	return (info and tonumber(info.Index)) or 1
end

local function ownsFood(tbl, idx)
	return type(tbl) == "table" and (tbl[idx] == true or tbl[tostring(idx)] == true)
end

task.spawn(function()
	while alive do
		local active = State.AutoEquipBest or State.AutoSell or State.AutoBuyFood or State.AutoUpStand or State.AutoUpFence
		if active and Remotes and DataCtrl then
			if State.AutoEquipBest then
				local animals = DataCtrl:Get("Animals")
				if type(animals) == "table" then
					for _, v in pairs(animals) do
						if type(v) == "table" and v.Placed ~= true then
							pcall(Remotes.Invoke, "Plot_EquipBest")
							task.wait(0.2)
							break
						end
					end
				end
			end

			if State.AutoSell then
				local animals = DataCtrl:Get("Animals")
				if type(animals) == "table" then
					if State.KeepRarity == "Sell All" and not State.KeepMutated then
						for _, v in pairs(animals) do
							if type(v) == "table" and v.Placed ~= true then
								pcall(Remotes.Invoke, "Plot_SellAll")
								task.wait(0.2)
								break
							end
						end
					else
						local minKeep = 999
						if State.KeepRarity ~= "Sell All" then
							local info = RarityConfig and RarityConfig.ByName and RarityConfig.ByName[State.KeepRarity]
							minKeep = (info and tonumber(info.Index)) or 3
						end
						local sellIds = {}
						for id, v in pairs(animals) do
							if type(v) == "table" and v.Placed ~= true then
								local mut = type(v.Mutation) == "string" and v.Mutation ~= ""
								if not (State.KeepMutated and mut) and rarityOf(tostring(v.ModelName or "")) < minKeep then
									table.insert(sellIds, tostring(id))
								end
							end
						end
						for _, id in pairs(sellIds) do
							if not alive or not State.AutoSell then break end
							pcall(Remotes.Invoke, "Plot_SellAnimal", id)
							task.wait(0.15)
						end
					end
				end
			end

			if State.AutoBuyFood and FoodsConfig and BalanceCurve then
				local money = tonumber(DataCtrl:Get("Money")) or 0
				local owned = DataCtrl:Get("OwnedFoods")
				local eq = tonumber(DataCtrl:Get("EquippedFood")) or 1
				local best, buyIdx = eq, nil

				for i = 1, FoodsConfig.CountAll() do
					local f = FoodsConfig.GetAny(i)
					if f and not FoodsConfig.IsLocked(i) then
						local idx = tonumber(f.Index) or i
						if ownsFood(owned, idx) then
							if idx > best then best = idx end
						elseif idx > best then
							local price = tonumber(BalanceCurve.GetItemPrice(lp, f)) or math.huge
							if money >= price then buyIdx = idx end
						end
					end
				end

				if buyIdx then
					local ok, res = pcall(Remotes.Invoke, "Shop_Buy", buyIdx)
					if ok and type(res) == "table" and res.Ok and buyIdx > best then
						best = buyIdx
					end
					task.wait(0.15)
				end
				if best > (tonumber(DataCtrl:Get("EquippedFood")) or 1) then
					pcall(Remotes.Invoke, "Shop_Equip", best)
					task.wait(0.1)
				end
			end

			if State.AutoUpStand and StandsConfig and BalanceCurve then
				local cur = tonumber(DataCtrl:Get("Stand")) or 0
				local nxt = StandsConfig.Get(cur + 1)
				if nxt then
					local money = tonumber(DataCtrl:Get("Money")) or 0
					local price = tonumber(BalanceCurve.GetItemPrice(lp, nxt)) or math.huge
					if money >= price then
						pcall(Remotes.Invoke, "Stand_Upgrade")
						task.wait(0.2)
					end
				end
			end

			if State.AutoUpFence and FenceConfig then
				local cur = tonumber(DataCtrl:Get("FenceLevel")) or 0
				local nxt = FenceConfig.Get(cur + 1)
				if nxt then
					local money = tonumber(DataCtrl:Get("Money")) or 0
					if money >= (tonumber(nxt.Price) or math.huge) then
						pcall(Remotes.Invoke, "Plot_UpgradeFence")
						task.wait(0.2)
					end
				end
			end

			task.wait(2.5)
		else
			task.wait(0.5)
		end
	end
end)

env.ONhubCleanup = cleanup
UnloadBtn.MouseButton1Click:Connect(function()
	cleanup()
	env.ONhubCleanup = nil
end)

syncPerfect()
updateAlpha()
updateGlow()
updateStatus()
selectTab("Throw")
