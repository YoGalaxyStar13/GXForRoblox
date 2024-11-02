--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.
local GuiLibrary = shared.GuiLibrary
local playersService = game:GetService("Players")
local textService = game:GetService("TextService")
local lightingService = game:GetService("Lighting")
local textChatService = game:GetService("TextChatService")
local inputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vapeConnections = {}
local vapeCachedAssets = {}
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new("BindableEvent")
		return self[index]
	end
})
local vapeTargetInfo = shared.VapeTargetInfo
local vapeInjected = true

local bedwars = {}
local store = {
	attackReach = 0,
	attackReachUpdate = tick(),
	blocks = {},
	blockPlacer = {},
	blockPlace = tick(),
	blockRaycast = RaycastParams.new(),
	equippedKit = "none",
	forgeMasteryPoints = 0,
	forgeUpgrades = {},
	grapple = tick(),
	inventories = {},
	localInventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	localHand = {},
	matchState = 0,
	matchStateChanged = tick(),
	pots = {},
	queueType = "bedwars_test",
	statistics = {
		beds = 0,
		kills = 0,
		lagbacks = 0,
		lagbackEvent = Instance.new("BindableEvent"),
		reported = 0,
		universalLagbacks = 0
	},
	whitelist = {
		chatStrings1 = {helloimusinginhaler = "vape"},
		chatStrings2 = {vape = "helloimusinginhaler"},
		clientUsers = {},
		oldChatFunctions = {}
	},
	zephyrOrb = 0
}
store.blockRaycast.FilterType = Enum.RaycastFilterType.Include
local AutoLeave = {Enabled = false}

table.insert(vapeConnections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA("Camera")
end))
local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil
end
local networkownerswitch = tick()
--ME WHEN THE MOBILE EXPLOITS ADD A DISFUNCTIONAL ISNETWORKOWNER (its for compatability I swear!!)
local isnetworkowner = function(part)
	local suc, res = pcall(function() return gethiddenproperty(part, "NetworkOwnershipRule") end)
	if suc and res == Enum.NetworkOwnership.Manual then
		sethiddenproperty(part, "NetworkOwnershipRule", Enum.NetworkOwnership.Automatic)
		networkownerswitch = tick() + 8
	end
	return networkownerswitch <= tick()
end
local getcustomasset = getsynasset or getcustomasset or function(location) return "rbxasset://"..location end
local queueonteleport = syn and syn.queue_on_teleport or queue_on_teleport or function() end
local synapsev3 = syn and syn.toast_notification and "V3" or ""
local worldtoscreenpoint = function(pos)
	if synapsev3 == "V3" then
		local scr = worldtoscreen({pos})
		return scr[1] - Vector3.new(0, 36, 0), scr[1].Z > 0
	end
	return gameCamera.WorldToScreenPoint(gameCamera, pos)
end
local worldtoviewportpoint = function(pos)
	if synapsev3 == "V3" then
		local scr = worldtoscreen({pos})
		return scr[1], scr[1].Z > 0
	end
	return gameCamera.WorldToViewportPoint(gameCamera, pos)
end

local function vapeGithubRequest(scripturl)
	if not isfile("vape/"..scripturl) then
		local suc, res = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/"..readfile("vape/commithash.txt").."/"..scripturl, true) end)
		assert(suc, res)
		assert(res ~= "404: Not Found", res)
		if scripturl:find(".lua") then res = "--This watermark is used to delete the file if its cached, remove it to make the file persist after commits.\n"..res end
		writefile("vape/"..scripturl, res)
	end
	return readfile("vape/"..scripturl)
end

local function downloadVapeAsset(path)
	if not isfile(path) then
		task.spawn(function()
			local textlabel = Instance.new("TextLabel")
			textlabel.Size = UDim2.new(1, 0, 0, 36)
			textlabel.Text = "Downloading "..path
			textlabel.BackgroundTransparency = 1
			textlabel.TextStrokeTransparency = 0
			textlabel.TextSize = 30
			textlabel.Font = Enum.Font.SourceSans
			textlabel.TextColor3 = Color3.new(1, 1, 1)
			textlabel.Position = UDim2.new(0, 0, 0, -36)
			textlabel.Parent = GuiLibrary.MainGui
			repeat task.wait() until isfile(path)
			textlabel:Destroy()
		end)
		local suc, req = pcall(function() return vapeGithubRequest(path:gsub("vape/assets", "assets")) end)
		if suc and req then
			writefile(path, req)
		else
			return ""
		end
	end
	if not vapeCachedAssets[path] then vapeCachedAssets[path] = getcustomasset(path) end
	return vapeCachedAssets[path]
end

local function warningNotification(title, text, delay)
	local suc, res = pcall(function()
		local frame = GuiLibrary.CreateNotification(title, text, delay, "assets/WarningNotification.png")
		frame.Frame.Frame.ImageColor3 = Color3.fromRGB(236, 129, 44)
		return frame
	end)
	return (suc and res)
end

local function run(func) func() end

local function isFriend(plr, recolor)
	if GuiLibrary.ObjectsThatCanBeSaved["Use FriendsToggle"].Api.Enabled then
		local friend = table.find(GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.ObjectList, plr.Name)
		friend = friend and GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.ObjectListEnabled[friend]
		if recolor then
			friend = friend and GuiLibrary.ObjectsThatCanBeSaved["Recolor visualsToggle"].Api.Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	local friend = table.find(GuiLibrary.ObjectsThatCanBeSaved.TargetsListTextCircleList.Api.ObjectList, plr.Name)
	friend = friend and GuiLibrary.ObjectsThatCanBeSaved.TargetsListTextCircleList.Api.ObjectListEnabled[friend]
	return friend
end

local function isVulnerable(plr)
	return plr.Humanoid.Health > 0 and not plr.Character.FindFirstChildWhichIsA(plr.Character, "ForceField")
end

local function getPlayerColor(plr)
	if isFriend(plr, true) then
		return Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Value)
	end
	return tostring(plr.TeamColor) ~= "White" and plr.TeamColor.Color
end

local function LaunchAngle(v, g, d, h, higherArc)
	local v2 = v * v
	local v4 = v2 * v2
	local root = -math.sqrt(v4 - g*(g*d*d + 2*h*v2))
	return math.atan((v2 + root) / (g * d))
end

local function LaunchDirection(start, target, v, g)
	local horizontal = Vector3.new(target.X - start.X, 0, target.Z - start.Z)
	local h = target.Y - start.Y
	local d = horizontal.Magnitude
	local a = LaunchAngle(v, g, d, h)

	if a ~= a then
		return g == 0 and (target - start).Unit * v
	end

	local vec = horizontal.Unit * v
	local rotAxis = Vector3.new(-horizontal.Z, 0, horizontal.X)
	return CFrame.fromAxisAngle(rotAxis, a) * vec
end

local physicsUpdate = 1 / 60

local function predictGravity(playerPosition, vel, bulletTime, targetPart, Gravity)
	local estimatedVelocity = vel.Y
	local rootSize = (targetPart.Humanoid.HipHeight + (targetPart.RootPart.Size.Y / 2))
	local velocityCheck = (tick() - targetPart.JumpTick) < 0.2
	vel = vel * physicsUpdate

	for i = 1, math.ceil(bulletTime / physicsUpdate) do
		if velocityCheck then
			estimatedVelocity = estimatedVelocity - (Gravity * physicsUpdate)
		else
			estimatedVelocity = 0
			playerPosition = playerPosition + Vector3.new(0, -0.03, 0) -- bw hitreg is so bad that I have to add this LOL
			rootSize = rootSize - 0.03
		end

		local floorDetection = workspace:Raycast(playerPosition, Vector3.new(vel.X, (estimatedVelocity * physicsUpdate) - rootSize, vel.Z), store.blockRaycast)
		if floorDetection then
			playerPosition = Vector3.new(playerPosition.X, floorDetection.Position.Y + rootSize, playerPosition.Z)
			local bouncepad = floorDetection.Instance:FindFirstAncestor("gumdrop_bounce_pad")
			if bouncepad and bouncepad:GetAttribute("PlacedByUserId") == targetPart.Player.UserId then
				estimatedVelocity = 130 - (Gravity * physicsUpdate)
				velocityCheck = true
			else
				estimatedVelocity = targetPart.Humanoid.JumpPower - (Gravity * physicsUpdate)
				velocityCheck = targetPart.Jumping
			end
		end

		playerPosition = playerPosition + Vector3.new(vel.X, velocityCheck and estimatedVelocity * physicsUpdate or 0, vel.Z)
	end

	return playerPosition, Vector3.new(0, 0, 0)
end

local entityLibrary = shared.vapeentity
local whitelist = shared.vapewhitelist
local RunLoops = {RenderStepTable = {}, StepTable = {}, HeartTable = {}}
do
	function RunLoops:BindToRenderStep(name, func)
		if RunLoops.RenderStepTable[name] == nil then
			RunLoops.RenderStepTable[name] = runService.RenderStepped:Connect(func)
		end
	end

	function RunLoops:UnbindFromRenderStep(name)
		if RunLoops.RenderStepTable[name] then
			RunLoops.RenderStepTable[name]:Disconnect()
			RunLoops.RenderStepTable[name] = nil
		end
	end

	function RunLoops:BindToStepped(name, func)
		if RunLoops.StepTable[name] == nil then
			RunLoops.StepTable[name] = runService.Stepped:Connect(func)
		end
	end

	function RunLoops:UnbindFromStepped(name)
		if RunLoops.StepTable[name] then
			RunLoops.StepTable[name]:Disconnect()
			RunLoops.StepTable[name] = nil
		end
	end

	function RunLoops:BindToHeartbeat(name, func)
		if RunLoops.HeartTable[name] == nil then
			RunLoops.HeartTable[name] = runService.Heartbeat:Connect(func)
		end
	end

	function RunLoops:UnbindFromHeartbeat(name)
		if RunLoops.HeartTable[name] then
			RunLoops.HeartTable[name]:Disconnect()
			RunLoops.HeartTable[name] = nil
		end
	end
end

GuiLibrary.SelfDestructEvent.Event:Connect(function()
	vapeInjected = false
	for i, v in pairs(vapeConnections) do
		if v.Disconnect then pcall(function() v:Disconnect() end) continue end
		if v.disconnect then pcall(function() v:disconnect() end) continue end
	end
end)

local function getItem(itemName, inv)
	for slot, item in pairs(inv or store.localInventory.inventory.items) do
		if item.itemType == itemName then
			return item, slot
		end
	end
	return nil
end

local function getItemNear(itemName, inv)
	for slot, item in pairs(inv or store.localInventory.inventory.items) do
		if item.itemType == itemName or item.itemType:find(itemName) then
			return item, slot
		end
	end
	return nil
end

local function getHotbarSlot(itemName)
	for slotNumber, slotTable in pairs(store.localInventory.hotbar) do
		if slotTable.item and slotTable.item.itemType == itemName then
			return slotNumber - 1
		end
	end
	return nil
end

local function getShieldAttribute(char)
	local returnedShield = 0
	for attributeName, attributeValue in pairs(char:GetAttributes()) do
		if attributeName:find("Shield") and type(attributeValue) == "number" then
			returnedShield = returnedShield + attributeValue
		end
	end
	return returnedShield
end

local function getPickaxe()
	return getItemNear("pick")
end

local function getAxe()
	local bestAxe, bestAxeSlot = nil, nil
	for slot, item in pairs(store.localInventory.inventory.items) do
		if item.itemType:find("axe") and item.itemType:find("pickaxe") == nil and item.itemType:find("void") == nil then
			bextAxe, bextAxeSlot = item, slot
		end
	end
	return bestAxe, bestAxeSlot
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage = nil, nil, 0
	for slot, item in pairs(store.localInventory.inventory.items) do
		local swordMeta = bedwars.ItemTable[item.itemType].sword
		if swordMeta then
			local swordDamage = swordMeta.damage or 0
			if swordDamage > bestSwordDamage then
				bestSword, bestSwordSlot, bestSwordDamage = item, slot, swordDamage
			end
		end
	end
	return bestSword, bestSwordSlot
end

local function getBow()
	local bestBow, bestBowSlot, bestBowStrength = nil, nil, 0
	for slot, item in pairs(store.localInventory.inventory.items) do
		if item.itemType:find("bow") then
			local tab = bedwars.ItemTable[item.itemType].projectileSource
			local ammo = tab.projectileType("arrow")
			local dmg = bedwars.ProjectileMeta[ammo].combat.damage
			if dmg > bestBowStrength then
				bestBow, bestBowSlot, bestBowStrength = item, slot, dmg
			end
		end
	end
	return bestBow, bestBowSlot
end

local function getWool()
	local wool = getItemNear("wool")
	return wool and wool.itemType, wool and wool.amount
end

local function getBlock()
	for slot, item in pairs(store.localInventory.inventory.items) do
		if bedwars.ItemTable[item.itemType].block then
			return item.itemType, item.amount
		end
	end
end

local function attackValue(vec)
	return {value = vec}
end

local function getSpeed()
	local speed = 0
	if lplr.Character then
		local SpeedDamageBoost = lplr.Character:GetAttribute("SpeedBoost")
		if SpeedDamageBoost and SpeedDamageBoost > 1 then
			speed = speed + (8 * (SpeedDamageBoost - 1))
		end
		if store.grapple > tick() then
			speed = speed + 90
		end
		if lplr.Character:GetAttribute("GrimReaperChannel") then
			speed = speed + 20
		end
		local armor = store.localInventory.inventory.armor[3]
		if type(armor) ~= "table" then armor = {itemType = ""} end
		if armor.itemType == "speed_boots" then
			speed = speed + 12
		end
		if store.zephyrOrb ~= 0 then
			speed = speed + 12
		end
	end
	return speed
end

local Reach = {Enabled = false}
local blacklistedblocks = {
	bed = true,
	ceramic = true
}
local cachedNormalSides = {}
for i,v in pairs(Enum.NormalId:GetEnumItems()) do if v.Name ~= "Bottom" then table.insert(cachedNormalSides, v) end end
local updateitem = Instance.new("BindableEvent")
table.insert(vapeConnections, updateitem.Event:Connect(function(inputObj)
	if inputService:IsMouseButtonPressed(0) then
		game:GetService("ContextActionService"):CallFunction("block-break", Enum.UserInputState.Begin, newproxy(true))
	end
end))

local function getPlacedBlock(pos)
	local roundedPosition = bedwars.BlockController:getBlockPosition(pos)
	return bedwars.BlockController:getStore():getBlockAt(roundedPosition), roundedPosition
end

local oldpos = Vector3.zero

local function getScaffold(vec, diagonaltoggle)
	local realvec = Vector3.new(math.floor((vec.X / 3) + 0.5) * 3, math.floor((vec.Y / 3) + 0.5) * 3, math.floor((vec.Z / 3) + 0.5) * 3)
	local speedCFrame = (oldpos - realvec)
	local returedpos = realvec
	if entityLibrary.isAlive then
		local angle = math.deg(math.atan2(-entityLibrary.character.Humanoid.MoveDirection.X, -entityLibrary.character.Humanoid.MoveDirection.Z))
		local goingdiagonal = (angle >= 130 and angle <= 150) or (angle <= -35 and angle >= -50) or (angle >= 35 and angle <= 50) or (angle <= -130 and angle >= -150)
		if goingdiagonal and ((speedCFrame.X == 0 and speedCFrame.Z ~= 0) or (speedCFrame.X ~= 0 and speedCFrame.Z == 0)) and diagonaltoggle then
			return oldpos
		end
	end
	return realvec
end

local function getBestTool(block)
	local tool = nil
	local blockmeta = bedwars.ItemTable[block]
	local blockType = blockmeta.block and blockmeta.block.breakType
	if blockType then
		local best = 0
		for i,v in pairs(store.localInventory.inventory.items) do
			local meta = bedwars.ItemTable[v.itemType]
			if meta.breakBlock and meta.breakBlock[blockType] and meta.breakBlock[blockType] >= best then
				best = meta.breakBlock[blockType]
				tool = v
			end
		end
	end
	return tool
end

local function switchItem(tool)
	if lplr.Character.HandInvItem.Value ~= tool then
		bedwars.Client:Get(bedwars.EquipItemRemote):CallServerAsync({
			hand = tool
		})
		local started = tick()
		repeat task.wait() until (tick() - started) > 0.3 or lplr.Character.HandInvItem.Value == tool
	end
end

local function switchToAndUseTool(block, legit)
	local tool = getBestTool(block.Name)
	if tool and (entityLibrary.isAlive and lplr.Character:FindFirstChild("HandInvItem") and lplr.Character.HandInvItem.Value ~= tool.tool) then
		if legit then
			if getHotbarSlot(tool.itemType) then
				bedwars.ClientStoreHandler:dispatch({
					type = "InventorySelectHotbarSlot",
					slot = getHotbarSlot(tool.itemType)
				})
				vapeEvents.InventoryChanged.Event:Wait()
				updateitem:Fire(inputobj)
				return true
			else
				return false
			end
		end
		switchItem(tool.tool)
	end
end

local function isBlockCovered(pos)
	local coveredsides = 0
	for i, v in pairs(cachedNormalSides) do
		local blockpos = (pos + (Vector3.FromNormalId(v) * 3))
		local block = getPlacedBlock(blockpos)
		if block then
			coveredsides = coveredsides + 1
		end
	end
	return coveredsides == #cachedNormalSides
end

local function GetPlacedBlocksNear(pos, normal)
	local blocks = {}
	local lastfound = nil
	for i = 1, 20 do
		local blockpos = (pos + (Vector3.FromNormalId(normal) * (i * 3)))
		local extrablock = getPlacedBlock(blockpos)
		local covered = isBlockCovered(blockpos)
		if extrablock then
			if bedwars.BlockController:isBlockBreakable({blockPosition = blockpos}, lplr) and (not blacklistedblocks[extrablock.Name]) then
				table.insert(blocks, extrablock.Name)
			end
			lastfound = extrablock
			if not covered then
				break
			end
		else
			break
		end
	end
	return blocks
end

local function getLastCovered(pos, normal)
	local lastfound, lastpos = nil, nil
	for i = 1, 20 do
		local blockpos = (pos + (Vector3.FromNormalId(normal) * (i * 3)))
		local extrablock, extrablockpos = getPlacedBlock(blockpos)
		local covered = isBlockCovered(blockpos)
		if extrablock then
			lastfound, lastpos = extrablock, extrablockpos
			if not covered then
				break
			end
		else
			break
		end
	end
	return lastfound, lastpos
end

local function getBestBreakSide(pos)
	local softest, softestside = 9e9, Enum.NormalId.Top
	for i,v in pairs(cachedNormalSides) do
		local sidehardness = 0
		for i2,v2 in pairs(GetPlacedBlocksNear(pos, v)) do
			local blockmeta = bedwars.ItemTable[v2].block
			sidehardness = sidehardness + (blockmeta and blockmeta.health or 10)
			if blockmeta then
				local tool = getBestTool(v2)
				if tool then
					sidehardness = sidehardness - bedwars.ItemTable[tool.itemType].breakBlock[blockmeta.breakType]
				end
			end
		end
		if sidehardness <= softest then
			softest = sidehardness
			softestside = v
		end
	end
	return softestside, softest
end

local function EntityNearPosition(distance, ignore, overridepos)
	local closestEntity, closestMagnitude = nil, distance
	if entityLibrary.isAlive then
		for i, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then continue end
			if isVulnerable(v) then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.RootPart.Position).magnitude
				if overridepos and mag > distance then
					mag = (overridepos - v.RootPart.Position).magnitude
				end
				if mag <= closestMagnitude then
					closestEntity, closestMagnitude = v, mag
				end
			end
		end
		if not ignore then
			for i, v in pairs(collectionService:GetTagged("Monster")) do
				if v.PrimaryPart and v:GetAttribute("Team") ~= lplr:GetAttribute("Team") then
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v2.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then
						closestEntity, closestMagnitude = {Player = {Name = v.Name, UserId = (v.Name == "Duck" and 2020831224 or 1443379645)}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
			for i, v in pairs(collectionService:GetTagged("DiamondGuardian")) do
				if v.PrimaryPart then
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v2.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then
						closestEntity, closestMagnitude = {Player = {Name = "DiamondGuardian", UserId = 1443379645}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
			for i, v in pairs(collectionService:GetTagged("GolemBoss")) do
				if v.PrimaryPart then
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v2.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then
						closestEntity, closestMagnitude = {Player = {Name = "GolemBoss", UserId = 1443379645}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
			for i, v in pairs(collectionService:GetTagged("Drone")) do
				if v.PrimaryPart and tonumber(v:GetAttribute("PlayerUserId")) ~= lplr.UserId then
					local droneplr = playersService:GetPlayerByUserId(v:GetAttribute("PlayerUserId"))
					if droneplr and droneplr.Team == lplr.Team then continue end
					local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
					if overridepos and mag > distance then
						mag = (overridepos - v.PrimaryPart.Position).magnitude
					end
					if mag <= closestMagnitude then -- magcheck
						closestEntity, closestMagnitude = {Player = {Name = "Drone", UserId = 1443379645}, Character = v, RootPart = v.PrimaryPart, JumpTick = tick() + 5, Jumping = false, Humanoid = {HipHeight = 2}}, mag
					end
				end
			end
		end
	end
	return closestEntity
end

local function EntityNearMouse(distance)
	local closestEntity, closestMagnitude = nil, distance
	if entityLibrary.isAlive then
		local mousepos = inputService.GetMouseLocation(inputService)
		for i, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then continue end
			if isVulnerable(v) then
				local vec, vis = worldtoscreenpoint(v.RootPart.Position)
				local mag = (mousepos - Vector2.new(vec.X, vec.Y)).magnitude
				if vis and mag <= closestMagnitude then
					closestEntity, closestMagnitude = v, v.Target and -1 or mag
				end
			end
		end
	end
	return closestEntity
end

local function AllNearPosition(distance, amount, sortfunction, prediction)
	local returnedplayer = {}
	local currentamount = 0
	if entityLibrary.isAlive then
		local sortedentities = {}
		for i, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then continue end
			if isVulnerable(v) then
				local playerPosition = v.RootPart.Position
				local mag = (entityLibrary.character.HumanoidRootPart.Position - playerPosition).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - playerPosition).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, v)
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("Monster")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					if v:GetAttribute("Team") == lplr:GetAttribute("Team") then continue end
					table.insert(sortedentities, {Player = {Name = v.Name, UserId = (v.Name == "Duck" and 2020831224 or 1443379645), GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("DiamondGuardian")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, {Player = {Name = "DiamondGuardian", UserId = 1443379645, GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("GolemBoss")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, {Player = {Name = "GolemBoss", UserId = 1443379645, GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(collectionService:GetTagged("Drone")) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					if tonumber(v:GetAttribute("PlayerUserId")) == lplr.UserId then continue end
					local droneplr = playersService:GetPlayerByUserId(v:GetAttribute("PlayerUserId"))
					if droneplr and droneplr.Team == lplr.Team then continue end
					table.insert(sortedentities, {Player = {Name = "Drone", UserId = 1443379645}, GetAttribute = function() return "none" end, Character = v, RootPart = v.PrimaryPart, Humanoid = v.Humanoid})
				end
			end
		end
		for i, v in pairs(store.pots) do
			if v.PrimaryPart then
				local mag = (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
				if prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - v.PrimaryPart.Position).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, {Player = {Name = "Pot", UserId = 1443379645, GetAttribute = function() return "none" end}, Character = v, RootPart = v.PrimaryPart, Humanoid = {Health = 100, MaxHealth = 100}})
				end
			end
		end
		if sortfunction then
			table.sort(sortedentities, sortfunction)
		end
		for i,v in pairs(sortedentities) do
			table.insert(returnedplayer, v)
			currentamount = currentamount + 1
			if currentamount >= amount then break end
		end
	end
	return returnedplayer
end

--pasted from old source since gui code is hard
local function CreateAutoHotbarGUI(children2, argstable)
	local buttonapi = {}
	buttonapi["Hotbars"] = {}
	buttonapi["CurrentlySelected"] = 1
	local currentanim
	local amount = #children2:GetChildren()
	local sortableitems = {
		{itemType = "swords", itemDisplayType = "diamond_sword"},
		{itemType = "pickaxes", itemDisplayType = "diamond_pickaxe"},
		{itemType = "axes", itemDisplayType = "diamond_axe"},
		{itemType = "shears", itemDisplayType = "shears"},
		{itemType = "wool", itemDisplayType = "wool_white"},
		{itemType = "iron", itemDisplayType = "iron"},
		{itemType = "diamond", itemDisplayType = "diamond"},
		{itemType = "emerald", itemDisplayType = "emerald"},
		{itemType = "bows", itemDisplayType = "wood_bow"},
	}
	local items = bedwars.ItemTable
	if items then
		for i2,v2 in pairs(items) do
			if (i2:find("axe") == nil or i2:find("void")) and i2:find("bow") == nil and i2:find("shears") == nil and i2:find("wool") == nil and v2.sword == nil and v2.armor == nil and v2["dontGiveItem"] == nil and bedwars.ItemTable[i2] and bedwars.ItemTable[i2].image then
				table.insert(sortableitems, {itemType = i2, itemDisplayType = i2})
			end
		end
	end
	local buttontext = Instance.new("TextButton")
	buttontext.AutoButtonColor = false
	buttontext.BackgroundTransparency = 1
	buttontext.Name = "ButtonText"
	buttontext.Text = ""
	buttontext.Name = argstable["Name"]
	buttontext.LayoutOrder = 1
	buttontext.Size = UDim2.new(1, 0, 0, 40)
	buttontext.Active = false
	buttontext.TextColor3 = Color3.fromRGB(162, 162, 162)
	buttontext.TextSize = 17
	buttontext.Font = Enum.Font.SourceSans
	buttontext.Position = UDim2.new(0, 0, 0, 0)
	buttontext.Parent = children2
	local toggleframe2 = Instance.new("Frame")
	toggleframe2.Size = UDim2.new(0, 200, 0, 31)
	toggleframe2.Position = UDim2.new(0, 10, 0, 4)
	toggleframe2.BackgroundColor3 = Color3.fromRGB(38, 37, 38)
	toggleframe2.Name = "ToggleFrame2"
	toggleframe2.Parent = buttontext
	local toggleframe1 = Instance.new("Frame")
	toggleframe1.Size = UDim2.new(0, 198, 0, 29)
	toggleframe1.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	toggleframe1.BorderSizePixel = 0
	toggleframe1.Name = "ToggleFrame1"
	toggleframe1.Position = UDim2.new(0, 1, 0, 1)
	toggleframe1.Parent = toggleframe2
	local addbutton = Instance.new("ImageLabel")
	addbutton.BackgroundTransparency = 1
	addbutton.Name = "AddButton"
	addbutton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	addbutton.Position = UDim2.new(0, 93, 0, 9)
	addbutton.Size = UDim2.new(0, 12, 0, 12)
	addbutton.ImageColor3 = Color3.fromRGB(5, 133, 104)
	addbutton.Image = downloadVapeAsset("vape/assets/AddItem.png")
	addbutton.Parent = toggleframe1
	local children3 = Instance.new("Frame")
	children3.Name = argstable["Name"].."Children"
	children3.BackgroundTransparency = 1
	children3.LayoutOrder = amount
	children3.Size = UDim2.new(0, 220, 0, 0)
	children3.Parent = children2
	local uilistlayout = Instance.new("UIListLayout")
	uilistlayout.Parent = children3
	uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		children3.Size = UDim2.new(1, 0, 0, uilistlayout.AbsoluteContentSize.Y)
	end)
	local uicorner = Instance.new("UICorner")
	uicorner.CornerRadius = UDim.new(0, 5)
	uicorner.Parent = toggleframe1
	local uicorner2 = Instance.new("UICorner")
	uicorner2.CornerRadius = UDim.new(0, 5)
	uicorner2.Parent = toggleframe2
	buttontext.MouseEnter:Connect(function()
		tweenService:Create(toggleframe2, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(79, 78, 79)}):Play()
	end)
	buttontext.MouseLeave:Connect(function()
		tweenService:Create(toggleframe2, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(38, 37, 38)}):Play()
	end)
	local ItemListBigFrame = Instance.new("Frame")
	ItemListBigFrame.Size = UDim2.new(1, 0, 1, 0)
	ItemListBigFrame.Name = "ItemList"
	ItemListBigFrame.BackgroundTransparency = 1
	ItemListBigFrame.Visible = false
	ItemListBigFrame.Parent = GuiLibrary.MainGui
	local ItemListFrame = Instance.new("Frame")
	ItemListFrame.Size = UDim2.new(0, 660, 0, 445)
	ItemListFrame.Position = UDim2.new(0.5, -330, 0.5, -223)
	ItemListFrame.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	ItemListFrame.Parent = ItemListBigFrame
	local ItemListExitButton = Instance.new("ImageButton")
	ItemListExitButton.Name = "ItemListExitButton"
	ItemListExitButton.ImageColor3 = Color3.fromRGB(121, 121, 121)
	ItemListExitButton.Size = UDim2.new(0, 24, 0, 24)
	ItemListExitButton.AutoButtonColor = false
	ItemListExitButton.Image = downloadVapeAsset("vape/assets/ExitIcon1.png")
	ItemListExitButton.Visible = true
	ItemListExitButton.Position = UDim2.new(1, -31, 0, 8)
	ItemListExitButton.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	ItemListExitButton.Parent = ItemListFrame
	local ItemListExitButtonround = Instance.new("UICorner")
	ItemListExitButtonround.CornerRadius = UDim.new(0, 16)
	ItemListExitButtonround.Parent = ItemListExitButton
	ItemListExitButton.MouseEnter:Connect(function()
		tweenService:Create(ItemListExitButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(60, 60, 60), ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end)
	ItemListExitButton.MouseLeave:Connect(function()
		tweenService:Create(ItemListExitButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(26, 25, 26), ImageColor3 = Color3.fromRGB(121, 121, 121)}):Play()
	end)
	ItemListExitButton.MouseButton1Click:Connect(function()
		ItemListBigFrame.Visible = false
		GuiLibrary.MainGui.ScaledGui.ClickGui.Visible = true
	end)
	local ItemListFrameShadow = Instance.new("ImageLabel")
	ItemListFrameShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	ItemListFrameShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	ItemListFrameShadow.Image = downloadVapeAsset("vape/assets/WindowBlur.png")
	ItemListFrameShadow.BackgroundTransparency = 1
	ItemListFrameShadow.ZIndex = -1
	ItemListFrameShadow.Size = UDim2.new(1, 6, 1, 6)
	ItemListFrameShadow.ImageColor3 = Color3.new(0, 0, 0)
	ItemListFrameShadow.ScaleType = Enum.ScaleType.Slice
	ItemListFrameShadow.SliceCenter = Rect.new(10, 10, 118, 118)
	ItemListFrameShadow.Parent = ItemListFrame
	local ItemListFrameText = Instance.new("TextLabel")
	ItemListFrameText.Size = UDim2.new(1, 0, 0, 41)
	ItemListFrameText.BackgroundTransparency = 1
	ItemListFrameText.Name = "WindowTitle"
	ItemListFrameText.Position = UDim2.new(0, 0, 0, 0)
	ItemListFrameText.TextXAlignment = Enum.TextXAlignment.Left
	ItemListFrameText.Font = Enum.Font.SourceSans
	ItemListFrameText.TextSize = 17
	ItemListFrameText.Text = "	New AutoHotbar"
	ItemListFrameText.TextColor3 = Color3.fromRGB(201, 201, 201)
	ItemListFrameText.Parent = ItemListFrame
	local ItemListBorder1 = Instance.new("Frame")
	ItemListBorder1.BackgroundColor3 = Color3.fromRGB(40, 39, 40)
	ItemListBorder1.BorderSizePixel = 0
	ItemListBorder1.Size = UDim2.new(1, 0, 0, 1)
	ItemListBorder1.Position = UDim2.new(0, 0, 0, 41)
	ItemListBorder1.Parent = ItemListFrame
	local ItemListFrameCorner = Instance.new("UICorner")
	ItemListFrameCorner.CornerRadius = UDim.new(0, 4)
	ItemListFrameCorner.Parent = ItemListFrame
	local ItemListFrame1 = Instance.new("Frame")
	ItemListFrame1.Size = UDim2.new(0, 112, 0, 113)
	ItemListFrame1.Position = UDim2.new(0, 10, 0, 71)
	ItemListFrame1.BackgroundColor3 = Color3.fromRGB(38, 37, 38)
	ItemListFrame1.Name = "ItemListFrame1"
	ItemListFrame1.Parent = ItemListFrame
	local ItemListFrame2 = Instance.new("Frame")
	ItemListFrame2.Size = UDim2.new(0, 110, 0, 111)
	ItemListFrame2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	ItemListFrame2.BorderSizePixel = 0
	ItemListFrame2.Name = "ItemListFrame2"
	ItemListFrame2.Position = UDim2.new(0, 1, 0, 1)
	ItemListFrame2.Parent = ItemListFrame1
	local ItemListFramePicker = Instance.new("ScrollingFrame")
	ItemListFramePicker.Size = UDim2.new(0, 495, 0, 220)
	ItemListFramePicker.Position = UDim2.new(0, 144, 0, 122)
	ItemListFramePicker.BorderSizePixel = 0
	ItemListFramePicker.ScrollBarThickness = 3
	ItemListFramePicker.ScrollBarImageTransparency = 0.8
	ItemListFramePicker.VerticalScrollBarInset = Enum.ScrollBarInset.None
	ItemListFramePicker.BackgroundTransparency = 1
	ItemListFramePicker.Parent = ItemListFrame
	local ItemListFramePickerGrid = Instance.new("UIGridLayout")
	ItemListFramePickerGrid.CellPadding = UDim2.new(0, 4, 0, 3)
	ItemListFramePickerGrid.CellSize = UDim2.new(0, 51, 0, 52)
	ItemListFramePickerGrid.Parent = ItemListFramePicker
	ItemListFramePickerGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ItemListFramePicker.CanvasSize = UDim2.new(0, 0, 0, ItemListFramePickerGrid.AbsoluteContentSize.Y * (1 / GuiLibrary["MainRescale"].Scale))
	end)
	local ItemListcorner = Instance.new("UICorner")
	ItemListcorner.CornerRadius = UDim.new(0, 5)
	ItemListcorner.Parent = ItemListFrame1
	local ItemListcorner2 = Instance.new("UICorner")
	ItemListcorner2.CornerRadius = UDim.new(0, 5)
	ItemListcorner2.Parent = ItemListFrame2
	local selectedslot = 1
	local hoveredslot = 0

	local refreshslots
	local refreshList
	refreshslots = function()
		local startnum = 144
		local oldhovered = hoveredslot
		for i2,v2 in pairs(ItemListFrame:GetChildren()) do
			if v2.Name:find("ItemSlot") then
				v2:Remove()
			end
		end
		for i3,v3 in pairs(ItemListFramePicker:GetChildren()) do
			if v3:IsA("TextButton") then
				v3:Remove()
			end
		end
		for i4,v4 in pairs(sortableitems) do
			local ItemFrame = Instance.new("TextButton")
			ItemFrame.Text = ""
			ItemFrame.BackgroundColor3 = Color3.fromRGB(31, 30, 31)
			ItemFrame.Parent = ItemListFramePicker
			ItemFrame.AutoButtonColor = false
			local ItemFrameIcon = Instance.new("ImageLabel")
			ItemFrameIcon.Size = UDim2.new(0, 32, 0, 32)
			ItemFrameIcon.Image = bedwars.getIcon({itemType = v4.itemDisplayType}, true)
			ItemFrameIcon.ResampleMode = (bedwars.getIcon({itemType = v4.itemDisplayType}, true):find("rbxasset://") and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default)
			ItemFrameIcon.Position = UDim2.new(0, 10, 0, 10)
			ItemFrameIcon.BackgroundTransparency = 1
			ItemFrameIcon.Parent = ItemFrame
			local ItemFramecorner = Instance.new("UICorner")
			ItemFramecorner.CornerRadius = UDim.new(0, 5)
			ItemFramecorner.Parent = ItemFrame
			ItemFrame.MouseButton1Click:Connect(function()
				for i5,v5 in pairs(buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"]) do
					if v5.itemType == v4.itemType then
						buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(i5)] = nil
					end
				end
				buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(selectedslot)] = v4
				refreshslots()
				refreshList()
			end)
		end
		for i = 1, 9 do
			local item = buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(i)]
			local ItemListFrame3 = Instance.new("Frame")
			ItemListFrame3.Size = UDim2.new(0, 55, 0, 56)
			ItemListFrame3.Position = UDim2.new(0, startnum - 2, 0, 380)
			ItemListFrame3.BackgroundTransparency = (selectedslot == i and 0 or 1)
			ItemListFrame3.BackgroundColor3 = Color3.fromRGB(35, 34, 35)
			ItemListFrame3.Name = "ItemSlot"
			ItemListFrame3.Parent = ItemListFrame
			local ItemListFrame4 = Instance.new("TextButton")
			ItemListFrame4.Size = UDim2.new(0, 51, 0, 52)
			ItemListFrame4.BackgroundColor3 = (oldhovered == i and Color3.fromRGB(31, 30, 31) or Color3.fromRGB(20, 20, 20))
			ItemListFrame4.BorderSizePixel = 0
			ItemListFrame4.AutoButtonColor = false
			ItemListFrame4.Text = ""
			ItemListFrame4.Name = "ItemListFrame4"
			ItemListFrame4.Position = UDim2.new(0, 2, 0, 2)
			ItemListFrame4.Parent = ItemListFrame3
			local ItemListImage = Instance.new("ImageLabel")
			ItemListImage.Size = UDim2.new(0, 32, 0, 32)
			ItemListImage.BackgroundTransparency = 1
			local img = (item and bedwars.getIcon({itemType = item.itemDisplayType}, true) or "")
			ItemListImage.Image = img
			ItemListImage.ResampleMode = (img:find("rbxasset://") and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default)
			ItemListImage.Position = UDim2.new(0, 10, 0, 10)
			ItemListImage.Parent = ItemListFrame4
			local ItemListcorner3 = Instance.new("UICorner")
			ItemListcorner3.CornerRadius = UDim.new(0, 5)
			ItemListcorner3.Parent = ItemListFrame3
			local ItemListcorner4 = Instance.new("UICorner")
			ItemListcorner4.CornerRadius = UDim.new(0, 5)
			ItemListcorner4.Parent = ItemListFrame4
			ItemListFrame4.MouseEnter:Connect(function()
				ItemListFrame4.BackgroundColor3 = Color3.fromRGB(31, 30, 31)
				hoveredslot = i
			end)
			ItemListFrame4.MouseLeave:Connect(function()
				ItemListFrame4.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				hoveredslot = 0
			end)
			ItemListFrame4.MouseButton1Click:Connect(function()
				selectedslot = i
				refreshslots()
			end)
			ItemListFrame4.MouseButton2Click:Connect(function()
				buttonapi["Hotbars"][buttonapi["CurrentlySelected"]]["Items"][tostring(i)] = nil
				refreshslots()
				refreshList()
			end)
			startnum = startnum + 55
		end
	end

	local function createHotbarButton(num, items)
		num = tonumber(num) or #buttonapi["Hotbars"] + 1
		local hotbarbutton = Instance.new("TextButton")
		hotbarbutton.Size = UDim2.new(1, 0, 0, 30)
		hotbarbutton.BackgroundTransparency = 1
		hotbarbutton.LayoutOrder = num
		hotbarbutton.AutoButtonColor = false
		hotbarbutton.Text = ""
		hotbarbutton.Parent = children3
		buttonapi["Hotbars"][num] = {["Items"] = items or {}, Object = hotbarbutton, ["Number"] = num}
		local hotbarframe = Instance.new("Frame")
		hotbarframe.BackgroundColor3 = (num == buttonapi["CurrentlySelected"] and Color3.fromRGB(54, 53, 54) or Color3.fromRGB(31, 30, 31))
		hotbarframe.Size = UDim2.new(0, 200, 0, 27)
		hotbarframe.Position = UDim2.new(0, 10, 0, 1)
		hotbarframe.Parent = hotbarbutton
		local uicorner3 = Instance.new("UICorner")
		uicorner3.CornerRadius = UDim.new(0, 5)
		uicorner3.Parent = hotbarframe
		local startpos = 11
		for i = 1, 9 do
			local item = buttonapi["Hotbars"][num]["Items"][tostring(i)]
			local hotbarbox = Instance.new("ImageLabel")
			hotbarbox.Name = i
			hotbarbox.Size = UDim2.new(0, 17, 0, 18)
			hotbarbox.Position = UDim2.new(0, startpos, 0, 5)
			hotbarbox.BorderSizePixel = 0
			hotbarbox.Image = (item and bedwars.getIcon({itemType = item.itemDisplayType}, true) or "")
			hotbarbox.ResampleMode = ((item and bedwars.getIcon({itemType = item.itemDisplayType}, true) or ""):find("rbxasset://") and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default)
			hotbarbox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			hotbarbox.Parent = hotbarframe
			startpos = startpos + 18
		end
		hotbarbutton.MouseButton1Click:Connect(function()
			if buttonapi["CurrentlySelected"] == num then
				ItemListBigFrame.Visible = true
				GuiLibrary.MainGui.ScaledGui.ClickGui.Visible = false
				refreshslots()
			end
			buttonapi["CurrentlySelected"] = num
			refreshList()
		end)
		hotbarbutton.MouseButton2Click:Connect(function()
			if buttonapi["CurrentlySelected"] == num then
				buttonapi["CurrentlySelected"] = (num == 2 and 0 or 1)
			end
			table.remove(buttonapi["Hotbars"], num)
			refreshList()
		end)
	end

	refreshList = function()
		local newnum = 0
		local newtab = {}
		for i3,v3 in pairs(buttonapi["Hotbars"]) do
			newnum = newnum + 1
			newtab[newnum] = v3
		end
		buttonapi["Hotbars"] = newtab
		for i,v in pairs(children3:GetChildren()) do
			if v:IsA("TextButton") then
				v:Remove()
			end
		end
		for i2,v2 in pairs(buttonapi["Hotbars"]) do
			createHotbarButton(i2, v2["Items"])
		end
		GuiLibrary["Settings"][children2.Name..argstable["Name"].."ItemList"] = {["Type"] = "ItemList", ["Items"] = buttonapi["Hotbars"], ["CurrentlySelected"] = buttonapi["CurrentlySelected"]}
	end
	buttonapi["RefreshList"] = refreshList

	buttontext.MouseButton1Click:Connect(function()
		createHotbarButton()
	end)

	GuiLibrary["Settings"][children2.Name..argstable["Name"].."ItemList"] = {["Type"] = "ItemList", ["Items"] = buttonapi["Hotbars"], ["CurrentlySelected"] = buttonapi["CurrentlySelected"]}
	GuiLibrary.ObjectsThatCanBeSaved[children2.Name..argstable["Name"].."ItemList"] = {["Type"] = "ItemList", ["Items"] = buttonapi["Hotbars"], ["Api"] = buttonapi, Object = buttontext}

	return buttonapi
end

GuiLibrary.LoadSettingsEvent.Event:Connect(function(res)
	for i,v in pairs(res) do
		local obj = GuiLibrary.ObjectsThatCanBeSaved[i]
		if obj and v.Type == "ItemList" and obj.Api then
			obj.Api.Hotbars = v.Items
			obj.Api.CurrentlySelected = v.CurrentlySelected
			obj.Api.RefreshList()
		end
	end
end)

run(function()
	local function isWhitelistedBed(bed)
		if bed and bed.Name == 'bed' then
			for i, v in pairs(playersService:GetPlayers()) do
				if bed:GetAttribute("Team"..(v:GetAttribute("Team") or 0).."NoBreak") and not ({whitelist:get(v)})[2] then
					return true
				end
			end
		end
		return false
	end

	local function dumpRemote(tab)
		for i,v in pairs(tab) do
			if v == "Client" then
				return tab[i + 1]
			end
		end
		return ""
	end

	local KnitGotten, KnitClient
	repeat
		KnitGotten, KnitClient = pcall(function()
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 6)
		end)
		if KnitGotten then break end
		task.wait()
	until KnitGotten
	repeat task.wait() until debug.getupvalue(KnitClient.Start, 1)
	local Flamework = require(replicatedStorage["rbxts_include"]["node_modules"]["@flamework"].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client
	local InventoryUtil = require(replicatedStorage.TS.inventory["inventory-util"]).InventoryUtil
	local OldGet = getmetatable(Client).Get
	local OldBreak
	local bowConstants = {RelX = 0, RelY = 0, RelZ = 0}

	for i, v in debug.getupvalues(KnitClient.Controllers.ProjectileController.enableBeam) do
		if type(v) == 'table' and rawget(v, 'RelX') then
			bowConstants = v
			break
		end
	end

	bedwars = setmetatable({
		AnimationType = require(replicatedStorage.TS.animation["animation-type"]).AnimationType,
		AnimationUtil = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out["shared"].util["animation-util"]).AnimationUtil,
		AppController = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out.client.controllers["app-controller"]).AppController,
		AbilityController = Flamework.resolveDependency("@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController"),
		AbilityUIController = Flamework.resolveDependency("@easy-games/game-core:client/controllers/ability/ability-ui-controller@AbilityUIController"),
		AttackRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.SwordController.sendServerRequest)),
		BalanceFile = require(replicatedStorage.TS.balance["balance-file"]).BalanceFile,
		BatteryRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.BatteryController.KnitStart, 1), 1))),
		BlockBreaker = KnitClient.Controllers.BlockBreakController.blockBreaker,
		BlockController = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out).BlockEngine,
		BlockPlacer = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.client.placement["block-placer"]).BlockPlacer,
		BlockEngine = require(lplr.PlayerScripts.TS.lib["block-engine"]["client-block-engine"]).ClientBlockEngine,
		BlockEngineClientEvents = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.client["block-engine-client-events"]).BlockEngineClientEvents,
		BowConstantsTable = bowConstants,
		CannonAimRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.CannonController.startAiming, 5))),
		CannonLaunchRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.CannonHandController.launchSelf)),
		ClickHold = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out.client.ui.lib.util["click-hold"]).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage["rbxts_include"]["node_modules"]["@rbxts"].net.out.client),
		ClientDamageBlock = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.shared.remotes).BlockEngineRemotes.Client,
		ClientStoreHandler = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		CombatConstant = require(replicatedStorage.TS.combat["combat-constant"]).CombatConstant,
		ConstantManager = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out["shared"].constant["constant-manager"]).ConstantManager,
		ConsumeSoulRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.GrimReaperController.consumeSoul)),
		CooldownController = Flamework.resolveDependency("@easy-games/game-core:client/controllers/cooldown/cooldown-controller@CooldownController"),
		DamageIndicator = KnitClient.Controllers.DamageIndicatorController.spawnDamageIndicator,
		DefaultKillEffect = require(lplr.PlayerScripts.TS.controllers.game.locker["kill-effect"].effects["default-kill-effect"]),
		DropItem = KnitClient.Controllers.ItemDropController.dropItemInHand,
		DropItemRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.ItemDropController.dropItemInHand)),
		DragonRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.DragonSlayerController.KnitStart, 2), 1))),
		EatRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.ConsumeController.onEnable, 1))),
		EquipItemRemote = dumpRemote(debug.getconstants(debug.getproto(require(replicatedStorage.TS.entity.entities["inventory-entity"]).InventoryEntity.equipItem, 3))),
		EmoteMeta = require(replicatedStorage.TS.locker.emote["emote-meta"]).EmoteMeta,
		ForgeConstants = debug.getupvalue(KnitClient.Controllers.ForgeController.getPurchaseableForgeUpgrades, 2),
		ForgeUtil = debug.getupvalue(KnitClient.Controllers.ForgeController.getPurchaseableForgeUpgrades, 5),
		GameAnimationUtil = require(replicatedStorage.TS.animation["animation-util"]).GameAnimationUtil,
		EntityUtil = require(replicatedStorage.TS.entity["entity-util"]).EntityUtil,
		getIcon = function(item, showinv)
			local itemmeta = bedwars.ItemTable[item.itemType]
			if itemmeta and showinv then
				return itemmeta.image or ""
			end
			return ""
		end,
		getInventory = function(plr)
			local suc, result = pcall(function()
				return InventoryUtil.getInventory(plr)
			end)
			return (suc and result or {
				items = {},
				armor = {},
				hand = nil
			})
		end,
		GuitarHealRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.GuitarController.performHeal)),
		ItemTable = debug.getupvalue(require(replicatedStorage.TS.item["item-meta"]).getItemMeta, 1),
		KillEffectMeta = require(replicatedStorage.TS.locker["kill-effect"]["kill-effect-meta"]).KillEffectMeta,
		KnockbackUtil = require(replicatedStorage.TS.damage["knockback-util"]).KnockbackUtil,
		MatchEndScreenController = Flamework.resolveDependency("client/controllers/game/match/match-end-screen-controller@MatchEndScreenController"),
--		MinerRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.MinerController.onKitEnabled, 1))),
		MageRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.MageController.registerTomeInteraction, 1))),
		MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage["mage-kit-util"]).MageKitUtil,
		PickupMetalRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.MetalDetectorController.KnitStart, 1), 2))),
		PickupRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.ItemDropController.checkForPickup)),
		--PinataRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.PiggyBankController.KnitStart, 2), 5))),
		PinataRemote = '',
		ProjectileMeta = require(replicatedStorage.TS.projectile["projectile-meta"]).ProjectileMeta,
		ProjectileRemote = dumpRemote(debug.getconstants(debug.getupvalue(KnitClient.Controllers.ProjectileController.launchProjectileWithValues, 2))),
		QueryUtil = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out).GameQueryUtil,
		QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui["queue-card"]).QueueCard,
		QueueMeta = require(replicatedStorage.TS.game["queue-meta"]).QueueMeta,
		ReportRemote = dumpRemote(debug.getconstants(require(lplr.PlayerScripts.TS.controllers.global.report["report-controller"]).default.reportPlayer)),
		ResetRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.ResetController.createBindable, 1))),
		Roact = require(replicatedStorage["rbxts_include"]["node_modules"]["@rbxts"]["roact"].src),
		RuntimeLib = require(replicatedStorage["rbxts_include"].RuntimeLib),
		Shop = require(replicatedStorage.TS.games.bedwars.shop["bedwars-shop"]).BedwarsShop,
		ShopItems = debug.getupvalue(debug.getupvalue(require(replicatedStorage.TS.games.bedwars.shop["bedwars-shop"]).BedwarsShop.getShopItem, 1), 3),
		SoundList = require(replicatedStorage.TS.sound["game-sound"]).GameSound,
		SoundManager = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out).SoundManager,
		SpawnRavenRemote = dumpRemote(debug.getconstants(KnitClient.Controllers.RavenController.spawnRaven)),
		TreeRemote = dumpRemote(debug.getconstants(debug.getproto(debug.getproto(KnitClient.Controllers.BigmanController.KnitStart, 1), 2))),
		TrinityRemote = dumpRemote(debug.getconstants(debug.getproto(KnitClient.Controllers.AngelController.onKitEnabled, 1))),
		UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
		WeldTable = require(replicatedStorage.TS.util["weld-util"]).WeldUtil
	}, {
		__index = function(self, ind)
			rawset(self, ind, KnitClient.Controllers[ind])
			return rawget(self, ind)
		end
	})
	OldBreak = bedwars.BlockController.isBlockBreakable

	getmetatable(Client).Get = function(self, remoteName)
		if not vapeInjected then return OldGet(self, remoteName) end
		local originalRemote = OldGet(self, remoteName)
		if remoteName == bedwars.AttackRemote then
			return {
				instance = originalRemote.instance,
				SendToServer = function(self, attackTable, ...)
					local suc, plr = pcall(function() return playersService:GetPlayerFromCharacter(attackTable.entityInstance) end)
					if suc and plr then
						if not ({whitelist:get(plr)})[2] then return end
						if Reach.Enabled then
							local attackMagnitude = ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - attackTable.validate.targetPosition.value).magnitude
							if attackMagnitude > 18 then
								return nil
							end
							attackTable.validate.selfPosition = attackValue(attackTable.validate.selfPosition.value + (attackMagnitude > 14.4 and (CFrame.lookAt(attackTable.validate.selfPosition.value, attackTable.validate.targetPosition.value).lookVector * 4) or Vector3.zero))
						end
						store.attackReach = math.floor((attackTable.validate.selfPosition.value - attackTable.validate.targetPosition.value).magnitude * 100) / 100
						store.attackReachUpdate = tick() + 1
					end
					return originalRemote:SendToServer(attackTable, ...)
				end
			}
		end
		return originalRemote
	end

	bedwars.BlockController.isBlockBreakable = function(self, breakTable, plr)
		local obj = bedwars.BlockController:getStore():getBlockAt(breakTable.blockPosition)
		if isWhitelistedBed(obj) then return false end
		return OldBreak(self, breakTable, plr)
	end

	store.blockPlacer = bedwars.BlockPlacer.new(bedwars.BlockEngine, "wool_white")
	bedwars.placeBlock = function(speedCFrame, customblock)
		if getItem(customblock) then
			store.blockPlacer.blockType = customblock
			return store.blockPlacer:placeBlock(Vector3.new(speedCFrame.X / 3, speedCFrame.Y / 3, speedCFrame.Z / 3))
		end
	end

	local healthbarblocktable = {
		blockHealth = -1,
		breakingBlockPosition = Vector3.zero
	}

	local failedBreak = 0
	bedwars.breakBlock = function(pos, effects, normal, bypass, anim)
		if GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled then
			return
		end
		if lplr:GetAttribute("DenyBlockBreak") then
			return
		end
		local block, blockpos = nil, nil
		if not bypass then block, blockpos = getLastCovered(pos, normal) end
		if not block then block, blockpos = getPlacedBlock(pos) end
		if blockpos and block then
			if bedwars.BlockEngineClientEvents.DamageBlock:fire(block.Name, blockpos, block):isCancelled() then
				return
			end
			local blockhealthbarpos = {blockPosition = Vector3.zero}
			local blockdmg = 0
			if block and block.Parent ~= nil then
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - (blockpos * 3)).magnitude > 30 then return end
				store.blockPlace = tick() + 0.1
				switchToAndUseTool(block)
				blockhealthbarpos = {
					blockPosition = blockpos
				}
				task.spawn(function()
					bedwars.ClientDamageBlock:Get("DamageBlock"):CallServerAsync({
						blockRef = blockhealthbarpos,
						hitPosition = blockpos * 3,
						hitNormal = Vector3.FromNormalId(normal)
					}):andThen(function(result)
						if result ~= "failed" then
							failedBreak = 0
							if healthbarblocktable.blockHealth == -1 or blockhealthbarpos.blockPosition ~= healthbarblocktable.breakingBlockPosition then
								local blockdata = bedwars.BlockController:getStore():getBlockData(blockhealthbarpos.blockPosition)
								local blockhealth = blockdata and (blockdata:GetAttribute("Health") or blockdata:GetAttribute(lplr.Name .. "_Health")) or block:GetAttribute("Health")
								healthbarblocktable.blockHealth = blockhealth
								healthbarblocktable.breakingBlockPosition = blockhealthbarpos.blockPosition
							end
							healthbarblocktable.blockHealth = result == "destroyed" and 0 or healthbarblocktable.blockHealth
							blockdmg = bedwars.BlockController:calculateBlockDamage(lplr, blockhealthbarpos)
							healthbarblocktable.blockHealth = math.max(healthbarblocktable.blockHealth - blockdmg, 0)
							if effects then
								bedwars.BlockBreaker:updateHealthbar(blockhealthbarpos, healthbarblocktable.blockHealth, block:GetAttribute("MaxHealth"), blockdmg, block)
								if healthbarblocktable.blockHealth <= 0 then
									bedwars.BlockBreaker.breakEffect:playBreak(block.Name, blockhealthbarpos.blockPosition, lplr)
									bedwars.BlockBreaker.healthbarMaid:DoCleaning()
									healthbarblocktable.breakingBlockPosition = Vector3.zero
								else
									bedwars.BlockBreaker.breakEffect:playHit(block.Name, blockhealthbarpos.blockPosition, lplr)
								end
							end
							local animation
							if anim then
								animation = bedwars.AnimationUtil:playAnimation(lplr, bedwars.BlockController:getAnimationController():getAssetId(1))
								bedwars.ViewmodelController:playAnimation(15)
							end
							task.wait(0.3)
							if animation ~= nil then
								animation:Stop()
								animation:Destroy()
							end
						else
							failedBreak = failedBreak + 1
						end
					end)
				end)
				task.wait(physicsUpdate)
			end
		end
	end

	local function updateStore(newStore, oldStore)
		if newStore.Game ~= oldStore.Game then
			store.matchState = newStore.Game.matchState
			store.queueType = newStore.Game.queueType or "bedwars_test"
			store.forgeMasteryPoints = newStore.Game.forgeMasteryPoints
			store.forgeUpgrades = newStore.Game.forgeUpgrades
		end
		if newStore.Bedwars ~= oldStore.Bedwars then
			store.equippedKit = newStore.Bedwars.kit ~= "none" and newStore.Bedwars.kit or ""
		end
		if newStore.Inventory ~= oldStore.Inventory then
			local newInventory = (newStore.Inventory and newStore.Inventory.observedInventory or {inventory = {}})
			local oldInventory = (oldStore.Inventory and oldStore.Inventory.observedInventory or {inventory = {}})
			store.localInventory = newStore.Inventory.observedInventory
			if newInventory ~= oldInventory then
				vapeEvents.InventoryChanged:Fire()
			end
			if newInventory.inventory.items ~= oldInventory.inventory.items then
				vapeEvents.InventoryAmountChanged:Fire()
			end
			if newInventory.inventory.hand ~= oldInventory.inventory.hand then
				local currentHand = newStore.Inventory.observedInventory.inventory.hand
				local handType = ""
				if currentHand then
					local handData = bedwars.ItemTable[currentHand.itemType]
					handType = handData.sword and "sword" or handData.block and "block" or currentHand.itemType:find("bow") and "bow"
				end
				store.localHand = {tool = currentHand and currentHand.tool, Type = handType, amount = currentHand and currentHand.amount or 0}
			end
		end
	end

	table.insert(vapeConnections, bedwars.ClientStoreHandler.changed:connect(updateStore))
	updateStore(bedwars.ClientStoreHandler:getState(), {})

	for i, v in pairs({"MatchEndEvent", "EntityDeathEvent", "EntityDamageEvent", "BedwarsBedBreak", "BalloonPopped", "AngelProgress"}) do
		bedwars.Client:WaitFor(v):andThen(function(connection)
			table.insert(vapeConnections, connection:Connect(function(...)
				vapeEvents[v]:Fire(...)
			end))
		end)
	end
	for i, v in pairs({"PlaceBlockEvent", "BreakBlockEvent"}) do
		bedwars.ClientDamageBlock:WaitFor(v):andThen(function(connection)
			table.insert(vapeConnections, connection:Connect(function(...)
				vapeEvents[v]:Fire(...)
			end))
		end)
	end

	store.blocks = collectionService:GetTagged("block")
	store.blockRaycast.FilterDescendantsInstances = {store.blocks}
	table.insert(vapeConnections, collectionService:GetInstanceAddedSignal("block"):Connect(function(block)
		table.insert(store.blocks, block)
		store.blockRaycast.FilterDescendantsInstances = {store.blocks}
	end))
	table.insert(vapeConnections, collectionService:GetInstanceRemovedSignal("block"):Connect(function(block)
		block = table.find(store.blocks, block)
		if block then
			table.remove(store.blocks, block)
			store.blockRaycast.FilterDescendantsInstances = {store.blocks}
		end
	end))
	for _, ent in pairs(collectionService:GetTagged("entity")) do
		if ent.Name == "DesertPotEntity" then
			table.insert(store.pots, ent)
		end
	end
	table.insert(vapeConnections, collectionService:GetInstanceAddedSignal("entity"):Connect(function(ent)
		if ent.Name == "DesertPotEntity" then
			table.insert(store.pots, ent)
		end
	end))
	table.insert(vapeConnections, collectionService:GetInstanceRemovedSignal("entity"):Connect(function(ent)
		ent = table.find(store.pots, ent)
		if ent then
			table.remove(store.pots, ent)
		end
	end))

	local oldZephyrUpdate = bedwars.WindWalkerController.updateJump
	bedwars.WindWalkerController.updateJump = function(self, orb, ...)
		store.zephyrOrb = lplr.Character and lplr.Character:GetAttribute("Health") > 0 and orb or 0
		return oldZephyrUpdate(self, orb, ...)
	end

	GuiLibrary.SelfDestructEvent.Event:Connect(function()
		bedwars.WindWalkerController.updateJump = oldZephyrUpdate
		getmetatable(bedwars.Client).Get = OldGet
		bedwars.BlockController.isBlockBreakable = OldBreak
		store.blockPlacer:disable()
	end)

	local teleportedServers = false
	table.insert(vapeConnections, lplr.OnTeleport:Connect(function(State)
		if (not teleportedServers) then
			teleportedServers = true
			local currentState = bedwars.ClientStoreHandler and bedwars.ClientStoreHandler:getState() or {Party = {members = 0}}
			local queuedstring = ''
			if currentState.Party and currentState.Party.members and #currentState.Party.members > 0 then
				queuedstring = queuedstring..'shared.vapeteammembers = '..#currentState.Party.members..'\n'
			end
			if store.TPString then
				queuedstring = queuedstring..'shared.vapeoverlay = "'..store.TPString..'"\n'
			end
			queueonteleport(queuedstring)
		end
	end))
end)

do
	entityLibrary.animationCache = {}
	entityLibrary.groundTick = tick()
	entityLibrary.selfDestruct()
	entityLibrary.isPlayerTargetable = function(plr)
		return lplr:GetAttribute("Team") ~= plr:GetAttribute("Team") and not isFriend(plr) and ({whitelist:get(plr)})[2]
	end
	entityLibrary.characterAdded = function(plr, char, localcheck)
		local id = game:GetService("HttpService"):GenerateGUID(true)
		entityLibrary.entityIds[plr.Name] = id
		if char then
			task.spawn(function()
				local humrootpart = char:WaitForChild("HumanoidRootPart", 10)
				local head = char:WaitForChild("Head", 10)
				local hum = char:WaitForChild("Humanoid", 10)
				if entityLibrary.entityIds[plr.Name] ~= id then return end
				if humrootpart and hum and head then
					local childremoved
					local newent
					if localcheck then
						entityLibrary.isAlive = true
						entityLibrary.character.Head = head
						entityLibrary.character.Humanoid = hum
						entityLibrary.character.HumanoidRootPart = humrootpart
						table.insert(entityLibrary.entityConnections, char.AttributeChanged:Connect(function(...)
							vapeEvents.AttributeChanged:Fire(...)
						end))
					else
						newent = {
							Player = plr,
							Character = char,
							HumanoidRootPart = humrootpart,
							RootPart = humrootpart,
							Head = head,
							Humanoid = hum,
							Targetable = entityLibrary.isPlayerTargetable(plr),
							Team = plr.Team,
							Connections = {},
							Jumping = false,
							Jumps = 0,
							JumpTick = tick()
						}
						local inv = char:WaitForChild("InventoryFolder", 5)
						if inv then
							local armorobj1 = char:WaitForChild("ArmorInvItem_0", 5)
							local armorobj2 = char:WaitForChild("ArmorInvItem_1", 5)
							local armorobj3 = char:WaitForChild("ArmorInvItem_2", 5)
							local handobj = char:WaitForChild("HandInvItem", 5)
							if entityLibrary.entityIds[plr.Name] ~= id then return end
							if armorobj1 then
								table.insert(newent.Connections, armorobj1.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
							if armorobj2 then
								table.insert(newent.Connections, armorobj2.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
							if armorobj3 then
								table.insert(newent.Connections, armorobj3.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
							if handobj then
								table.insert(newent.Connections, handobj.Changed:Connect(function()
									task.delay(0.3, function()
										if entityLibrary.entityIds[plr.Name] ~= id then return end
										store.inventories[plr] = bedwars.getInventory(plr)
										entityLibrary.entityUpdatedEvent:Fire(newent)
									end)
								end))
							end
						end
						if entityLibrary.entityIds[plr.Name] ~= id then return end
						task.delay(0.3, function()
							if entityLibrary.entityIds[plr.Name] ~= id then return end
							store.inventories[plr] = bedwars.getInventory(plr)
							entityLibrary.entityUpdatedEvent:Fire(newent)
						end)
						table.insert(newent.Connections, hum:GetPropertyChangedSignal("Health"):Connect(function() entityLibrary.entityUpdatedEvent:Fire(newent) end))
						table.insert(newent.Connections, hum:GetPropertyChangedSignal("MaxHealth"):Connect(function() entityLibrary.entityUpdatedEvent:Fire(newent) end))
						table.insert(newent.Connections, hum.AnimationPlayed:Connect(function(state)
							local animnum = tonumber(({state.Animation.AnimationId:gsub("%D+", "")})[1])
							if animnum then
								if not entityLibrary.animationCache[state.Animation.AnimationId] then
									entityLibrary.animationCache[state.Animation.AnimationId] = game:GetService("MarketplaceService"):GetProductInfo(animnum)
								end
								if entityLibrary.animationCache[state.Animation.AnimationId].Name:lower():find("jump") then
									newent.Jumps = newent.Jumps + 1
								end
							end
						end))
						table.insert(newent.Connections, char.AttributeChanged:Connect(function(attr) if attr:find("Shield") then entityLibrary.entityUpdatedEvent:Fire(newent) end end))
						table.insert(entityLibrary.entityList, newent)
						entityLibrary.entityAddedEvent:Fire(newent)
					end
					if entityLibrary.entityIds[plr.Name] ~= id then return end
					childremoved = char.ChildRemoved:Connect(function(part)
						if part.Name == "HumanoidRootPart" or part.Name == "Head" or part.Name == "Humanoid" then
							if localcheck then
								if char == lplr.Character then
									if part.Name == "HumanoidRootPart" then
										entityLibrary.isAlive = false
										local root = char:FindFirstChild("HumanoidRootPart")
										if not root then
											root = char:WaitForChild("HumanoidRootPart", 3)
										end
										if root then
											entityLibrary.character.HumanoidRootPart = root
											entityLibrary.isAlive = true
										end
									else
										entityLibrary.isAlive = false
									end
								end
							else
								childremoved:Disconnect()
								entityLibrary.removeEntity(plr)
							end
						end
					end)
					if newent then
						table.insert(newent.Connections, childremoved)
					end
					table.insert(entityLibrary.entityConnections, childremoved)
				end
			end)
		end
	end
	entityLibrary.entityAdded = function(plr, localcheck, custom)
		table.insert(entityLibrary.entityConnections, plr:GetPropertyChangedSignal("Character"):Connect(function()
			if plr.Character then
				entityLibrary.refreshEntity(plr, localcheck)
			else
				if localcheck then
					entityLibrary.isAlive = false
				else
					entityLibrary.removeEntity(plr)
				end
			end
		end))
		table.insert(entityLibrary.entityConnections, plr:GetAttributeChangedSignal("Team"):Connect(function()
			local tab = {}
			for i,v in next, entityLibrary.entityList do
				if v.Targetable ~= entityLibrary.isPlayerTargetable(v.Player) then
					table.insert(tab, v)
				end
			end
			for i,v in next, tab do
				entityLibrary.refreshEntity(v.Player)
			end
			if localcheck then
				entityLibrary.fullEntityRefresh()
			else
				entityLibrary.refreshEntity(plr, localcheck)
			end
		end))
		if plr.Character then
			task.spawn(entityLibrary.refreshEntity, plr, localcheck)
		end
	end
	entityLibrary.fullEntityRefresh()
	task.spawn(function()
		repeat
			task.wait()
			if entityLibrary.isAlive then
				entityLibrary.groundTick = entityLibrary.character.Humanoid.FloorMaterial ~= Enum.Material.Air and tick() or entityLibrary.groundTick
			end
			for i,v in pairs(entityLibrary.entityList) do
				local state = v.Humanoid:GetState()
				v.JumpTick = (state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.Landed) and tick() or v.JumpTick
				v.Jumping = (tick() - v.JumpTick) < 0.2 and v.Jumps > 1
				if (tick() - v.JumpTick) > 0.2 then
					v.Jumps = 0
				end
			end
		until not vapeInjected
	end)
	local textlabel = Instance.new("TextLabel")
	textlabel.Size = UDim2.new(1, 0, 0, 36)
	textlabel.Text = "The current version of vape is no longer being maintained, join the discord (click the discord icon) to get updates on the latest release."
	textlabel.BackgroundTransparency = 1
	textlabel.ZIndex = 10
	textlabel.TextStrokeTransparency = 0
	textlabel.TextScaled = true
	textlabel.Font = Enum.Font.SourceSans
	textlabel.TextColor3 = Color3.new(1, 1, 1)
	textlabel.Position = UDim2.new(0, 0, 1, -36)
	textlabel.Parent = GuiLibrary.MainGui.ScaledGui.ClickGui
end

run(function()
	local handsquare = Instance.new("ImageLabel")
	handsquare.Size = UDim2.new(0, 26, 0, 27)
	handsquare.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	handsquare.Position = UDim2.new(0, 72, 0, 44)
	handsquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local handround = Instance.new("UICorner")
	handround.CornerRadius = UDim.new(0, 4)
	handround.Parent = handsquare
	local helmetsquare = handsquare:Clone()
	helmetsquare.Position = UDim2.new(0, 100, 0, 44)
	helmetsquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local chestplatesquare = handsquare:Clone()
	chestplatesquare.Position = UDim2.new(0, 127, 0, 44)
	chestplatesquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local bootssquare = handsquare:Clone()
	bootssquare.Position = UDim2.new(0, 155, 0, 44)
	bootssquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local uselesssquare = handsquare:Clone()
	uselesssquare.Position = UDim2.new(0, 182, 0, 44)
	uselesssquare.Parent = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo
	local oldupdate = vapeTargetInfo.UpdateInfo
	vapeTargetInfo.UpdateInfo = function(tab, targetsize)
		local bkgcheck = vapeTargetInfo.Object.GetCustomChildren().Frame.MainInfo.BackgroundTransparency == 1
		handsquare.BackgroundTransparency = bkgcheck and 1 or 0
		helmetsquare.BackgroundTransparency = bkgcheck and 1 or 0
		chestplatesquare.BackgroundTransparency = bkgcheck and 1 or 0
		bootssquare.BackgroundTransparency = bkgcheck and 1 or 0
		uselesssquare.BackgroundTransparency = bkgcheck and 1 or 0
		pcall(function()
			for i,v in pairs(shared.VapeTargetInfo.Targets) do
				local inventory = store.inventories[v.Player] or {}
					if inventory.hand then
						handsquare.Image = bedwars.getIcon(inventory.hand, true)
					else
						handsquare.Image = ""
					end
					if inventory.armor[4] then
						helmetsquare.Image = bedwars.getIcon(inventory.armor[4], true)
					else
						helmetsquare.Image = ""
					end
					if inventory.armor[5] then
						chestplatesquare.Image = bedwars.getIcon(inventory.armor[5], true)
					else
						chestplatesquare.Image = ""
					end
					if inventory.armor[6] then
						bootssquare.Image = bedwars.getIcon(inventory.armor[6], true)
					else
						bootssquare.Image = ""
					end
				break
			end
		end)
		return oldupdate(tab, targetsize)
	end
end)

GuiLibrary.RemoveObject("SilentAimOptionsButton")
GuiLibrary.RemoveObject("ReachOptionsButton")
GuiLibrary.RemoveObject("MouseTPOptionsButton")
GuiLibrary.RemoveObject("PhaseOptionsButton")
GuiLibrary.RemoveObject("AutoClickerOptionsButton")
GuiLibrary.RemoveObject("SpiderOptionsButton")
GuiLibrary.RemoveObject("LongJumpOptionsButton")
GuiLibrary.RemoveObject("HitBoxesOptionsButton")
GuiLibrary.RemoveObject("KillauraOptionsButton")
GuiLibrary.RemoveObject("TriggerBotOptionsButton")
GuiLibrary.RemoveObject("AutoLeaveOptionsButton")
GuiLibrary.RemoveObject("SpeedOptionsButton")
GuiLibrary.RemoveObject("FlyOptionsButton")
GuiLibrary.RemoveObject("ClientKickDisablerOptionsButton")
GuiLibrary.RemoveObject("NameTagsOptionsButton")
GuiLibrary.RemoveObject("SafeWalkOptionsButton")
GuiLibrary.RemoveObject("BlinkOptionsButton")
GuiLibrary.RemoveObject("FOVChangerOptionsButton")
GuiLibrary.RemoveObject("AntiVoidOptionsButton")
GuiLibrary.RemoveObject("SongBeatsOptionsButton")
GuiLibrary.RemoveObject("TargetStrafeOptionsButton")

run(function()
	local AimAssist = {Enabled = false}
	local AimAssistClickAim = {Enabled = false}
	local AimAssistStrafe = {Enabled = false}
	local AimSpeed = {Value = 1}
	local AimAssistTargetFrame = {Players = {Enabled = false}}
	AimAssist = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "AimAssist",
		Function = function(callback)
			if callback then
				RunLoops:BindToRenderStep("AimAssist", function(dt)
					vapeTargetInfo.Targets.AimAssist = nil
					if ((not AimAssistClickAim.Enabled) or (tick() - bedwars.SwordController.lastSwing) < 0.4) then
						local plr = EntityNearPosition(18)
						if plr then
							vapeTargetInfo.Targets.AimAssist = {
								Humanoid = {
									Health = (plr.Character:GetAttribute("Health") or plr.Humanoid.Health) + getShieldAttribute(plr.Character),
									MaxHealth = plr.Character:GetAttribute("MaxHealth") or plr.Humanoid.MaxHealth
								},
								Player = plr.Player
							}
							if store.localHand.Type == "sword" then
								if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
									if store.matchState == 0 then return end
								end
								if AimAssistTargetFrame.Walls.Enabled then
									if not bedwars.SwordController:canSee({instance = plr.Character, player = plr.Player, getInstance = function() return plr.Character end}) then return end
								end
								gameCamera.CFrame = gameCamera.CFrame:lerp(CFrame.new(gameCamera.CFrame.p, plr.Character.HumanoidRootPart.Position), ((1 / AimSpeed.Value) + (AimAssistStrafe.Enabled and (inputService:IsKeyDown(Enum.KeyCode.A) or inputService:IsKeyDown(Enum.KeyCode.D)) and 0.01 or 0)))
							end
						end
					end
				end)
			else
				RunLoops:UnbindFromRenderStep("AimAssist")
				vapeTargetInfo.Targets.AimAssist = nil
			end
		end,
		HoverText = "Smoothly aims to closest valid target with sword"
	})
	AimAssistTargetFrame = AimAssist.CreateTargetWindow({Default3 = true})
	AimAssistClickAim = AimAssist.CreateToggle({
		Name = "Click Aim",
		Function = function() end,
		Default = true,
		HoverText = "Only aim while mouse is down"
	})
	AimAssistStrafe = AimAssist.CreateToggle({
		Name = "Strafe increase",
		Function = function() end,
		HoverText = "Increase speed while strafing away from target"
	})
	AimSpeed = AimAssist.CreateSlider({
		Name = "Smoothness",
		Min = 1,
		Max = 100,
		Function = function(val) end,
		Default = 50
	})
end)

run(function()
	local autoclicker = {Enabled = false}
	local noclickdelay = {Enabled = false}
	local autoclickercps = {GetRandomValue = function() return 1 end}
	local autoclickerblocks = {Enabled = false}
	local AutoClickerThread

	local function isNotHoveringOverGui()
		local mousepos = inputService:GetMouseLocation() - Vector2.new(0, 36)
		for i,v in pairs(lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y)) do
			if v.Active then
				return false
			end
		end
		for i,v in pairs(game:GetService("CoreGui"):GetGuiObjectsAtPosition(mousepos.X, mousepos.Y)) do
			if v.Parent:IsA("ScreenGui") and v.Parent.Enabled then
				if v.Active then
					return false
				end
			end
		end
		return true
	end

	local function AutoClick()
		local firstClick = tick() + 0.1
		AutoClickerThread = task.spawn(function()
			repeat
				task.wait()
				if entityLibrary.isAlive then
					if not autoclicker.Enabled then break end
					if not isNotHoveringOverGui() then continue end
					if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then continue end
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if store.matchState == 0 then continue end
					end
					if store.localHand.Type == "sword" then
						if bedwars.DaoController.chargingMaid == nil then
							task.spawn(function()
								if firstClick <= tick() then
									bedwars.SwordController:swingSwordAtMouse()
								else
									firstClick = tick()
								end
							end)
							task.wait(math.max((1 / autoclickercps.GetRandomValue()), noclickdelay.Enabled and 0 or 0.142))
						end
					elseif store.localHand.Type == "block" then
						if autoclickerblocks.Enabled and bedwars.BlockPlacementController.blockPlacer and firstClick <= tick() then
							if (workspace:GetServerTimeNow() - bedwars.BlockCpsController.lastPlaceTimestamp) > ((1 / 12) * 0.5) then
								local mouseinfo = bedwars.BlockPlacementController.blockPlacer.clientManager:getBlockSelector():getMouseInfo(0)
								if mouseinfo then
									task.spawn(function()
										if mouseinfo.placementPosition == mouseinfo.placementPosition then
											bedwars.BlockPlacementController.blockPlacer:placeBlock(mouseinfo.placementPosition)
										end
									end)
								end
								task.wait((1 / autoclickercps.GetRandomValue()))
							end
						end
					end
				end
			until not autoclicker.Enabled
		end)
	end

	autoclicker = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "AutoClicker",
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function()
						table.insert(autoclicker.Connections, lplr.PlayerGui.MobileUI['2'].MouseButton1Down:Connect(AutoClick))
						table.insert(autoclicker.Connections, lplr.PlayerGui.MobileUI['2'].MouseButton1Up:Connect(function()
							if AutoClickerThread then
								task.cancel(AutoClickerThread)
								AutoClickerThread = nil
							end
						end))
					end)
				end
				table.insert(autoclicker.Connections, inputService.InputBegan:Connect(function(input, gameProcessed)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then AutoClick() end
				end))
				table.insert(autoclicker.Connections, inputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and AutoClickerThread then
						task.cancel(AutoClickerThread)
						AutoClickerThread = nil
					end
				end))
			end
		end,
		HoverText = "Hold attack button to automatically click"
	})
	autoclickercps = autoclicker.CreateTwoSlider({
		Name = "CPS",
		Min = 1,
		Max = 20,
		Function = function(val) end,
		Default = 8,
		Default2 = 12
	})
	autoclickerblocks = autoclicker.CreateToggle({
		Name = "Place Blocks",
		Function = function() end,
		Default = true,
		HoverText = "Automatically places blocks when left click is held."
	})

	local noclickfunc
	noclickdelay = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "NoClickDelay",
		Function = function(callback)
			if callback then
				noclickfunc = bedwars.SwordController.isClickingTooFast
				bedwars.SwordController.isClickingTooFast = function(self)
					self.lastSwing = tick()
					return false
				end
			else
				bedwars.SwordController.isClickingTooFast = noclickfunc
			end
		end,
		HoverText = "Remove the CPS cap"
	})
end)

run(function()
	local ReachValue = {Value = 14}

	Reach = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Reach",
		Function = function(callback)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = callback and ReachValue.Value + 2 or 14.4
		end,
		HoverText = "Extends attack reach"
	})
	ReachValue = Reach.CreateSlider({
		Name = "Reach",
		Min = 0,
		Max = 18,
		Function = function(val)
			if Reach.Enabled then
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = val + 2
			end
		end,
		Default = 18
	})
end)

run(function()
	local Sprint = {Enabled = false}
	local oldSprintFunction
	Sprint = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Sprint",
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function() lplr.PlayerGui.MobileUI["4"].Visible = false end)
				end
				oldSprintFunction = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local originalCall = oldSprintFunction(...)
					bedwars.SprintController:startSprinting()
					return originalCall
				end
				table.insert(Sprint.Connections, lplr.CharacterAdded:Connect(function(char)
					char:WaitForChild("Humanoid", 9e9)
					task.wait(0.5)
					bedwars.SprintController:stopSprinting()
				end))
				task.spawn(function()
					bedwars.SprintController:startSprinting()
				end)
			else
				if inputService.TouchEnabled then
					pcall(function() lplr.PlayerGui.MobileUI["4"].Visible = true end)
				end
				bedwars.SprintController.stopSprinting = oldSprintFunction
				bedwars.SprintController:stopSprinting()
			end
		end,
		HoverText = "Sets your sprinting to true."
	})
end)

run(function()
	local Velocity = {Enabled = false}
	local VelocityHorizontal = {Value = 100}
	local VelocityVertical = {Value = 100}
	local applyKnockback
	Velocity = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Velocity",
		Function = function(callback)
			if callback then
				applyKnockback = bedwars.KnockbackUtil.applyKnockback
				bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
					knockback = knockback or {}
					if VelocityHorizontal.Value == 0 and VelocityVertical.Value == 0 then return end
					knockback.horizontal = (knockback.horizontal or 1) * (VelocityHorizontal.Value / 100)
					knockback.vertical = (knockback.vertical or 1) * (VelocityVertical.Value / 100)
					return applyKnockback(root, mass, dir, knockback, ...)
				end
			else
				bedwars.KnockbackUtil.applyKnockback = applyKnockback
			end
		end,
		HoverText = "Reduces knockback taken"
	})
	VelocityHorizontal = Velocity.CreateSlider({
		Name = "Horizontal",
		Min = 0,
		Max = 100,
		Percent = true,
		Function = function(val) end,
		Default = 0
	})
	VelocityVertical = Velocity.CreateSlider({
		Name = "Vertical",
		Min = 0,
		Max = 100,
		Percent = true,
		Function = function(val) end,
		Default = 0
	})
end)

run(function()
	local AutoLeaveDelay = {Value = 1}
	local AutoPlayAgain = {Enabled = false}
	local AutoLeaveStaff = {Enabled = true}
	local AutoLeaveStaff2 = {Enabled = true}
	local AutoLeaveRandom = {Enabled = false}
	local leaveAttempted = false

	local function getRole(plr)
		local suc, res = pcall(function() return plr:GetRankInGroup(5774246) end)
		if not suc then
			repeat
				suc, res = pcall(function() return plr:GetRankInGroup(5774246) end)
				task.wait()
			until suc
		end
		if plr.UserId == 1774814725 then
			return 200
		end
		return res
	end

	local flyAllowedmodules = {"Sprint", "AutoClicker", "AutoReport", "AutoReportV2", "AutoRelic", "AimAssist", "AutoLeave", "Reach"}
	local function autoLeaveAdded(plr)
		task.spawn(function()
			if not shared.VapeFullyLoaded then
				repeat task.wait() until shared.VapeFullyLoaded
			end
			if getRole(plr) >= 100 then
				if AutoLeaveStaff.Enabled then
					if #bedwars.ClientStoreHandler:getState().Party.members > 0 then
						bedwars.QueueController.leaveParty()
					end
					if AutoLeaveStaff2.Enabled then
						warningNotification("Vape", "Staff Detected : "..(plr.DisplayName and plr.DisplayName.." ("..plr.Name..")" or plr.Name).." : Play legit like nothing happened to have the highest chance of not getting banned.", 60)
						GuiLibrary.SaveSettings = function() end
						for i,v in pairs(GuiLibrary.ObjectsThatCanBeSaved) do
							if v.Type == "OptionsButton" then
								if table.find(flyAllowedmodules, i:gsub("OptionsButton", "")) == nil and tostring(v.Object.Parent.Parent):find("Render") == nil then
									if v.Api.Enabled then
										v.Api.ToggleButton(false)
									end
									v.Api.SetKeybind("")
									v.Object.TextButton.Visible = false
								end
							end
						end
					else
						GuiLibrary.SelfDestruct()
						game:GetService("StarterGui"):SetCore("SendNotification", {
							Title = "Vape",
							Text = "Staff Detected\n"..(plr.DisplayName and plr.DisplayName.." ("..plr.Name..")" or plr.Name),
							Duration = 60,
						})
					end
					return
				else
					warningNotification("Vape", "Staff Detected : "..(plr.DisplayName and plr.DisplayName.." ("..plr.Name..")" or plr.Name), 60)
				end
			end
		end)
	end

	local function isEveryoneDead()
		if #bedwars.ClientStoreHandler:getState().Party.members > 0 then
			for i,v in pairs(bedwars.ClientStoreHandler:getState().Party.members) do
				local plr = playersService:FindFirstChild(v.name)
				if plr and isAlive(plr, true) then
					return false
				end
			end
			return true
		else
			return true
		end
	end

	AutoLeave = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "AutoLeave",
		Function = function(callback)
			if callback then
				table.insert(AutoLeave.Connections, vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if (not leaveAttempted) and deathTable.finalKill and deathTable.entityInstance == lplr.Character then
						leaveAttempted = true
						if isEveryoneDead() and store.matchState ~= 2 then
							task.wait(1 + (AutoLeaveDelay.Value / 10))
							if bedwars.ClientStoreHandler:getState().Game.customMatch == nil and bedwars.ClientStoreHandler:getState().Party.leader.userId == lplr.UserId then
								if not AutoPlayAgain.Enabled then
									bedwars.Client:Get("TeleportToLobby"):SendToServer()
								else
									if AutoLeaveRandom.Enabled then
										local listofmodes = {}
										for i,v in pairs(bedwars.QueueMeta) do
											if not v.disabled and not v.voiceChatOnly and not v.rankCategory then table.insert(listofmodes, i) end
										end
										bedwars.QueueController:joinQueue(listofmodes[math.random(1, #listofmodes)])
									else
										bedwars.QueueController:joinQueue(store.queueType)
									end
								end
							end
						end
					end
				end))
				table.insert(AutoLeave.Connections, vapeEvents.MatchEndEvent.Event:Connect(function(deathTable)
					task.wait(AutoLeaveDelay.Value / 10)
					if not AutoLeave.Enabled then return end
					if leaveAttempted then return end
					leaveAttempted = true
					if bedwars.ClientStoreHandler:getState().Game.customMatch == nil and bedwars.ClientStoreHandler:getState().Party.leader.userId == lplr.UserId then
						if not AutoPlayAgain.Enabled then
							bedwars.Client:Get("TeleportToLobby"):SendToServer()
						else
							if bedwars.ClientStoreHandler:getState().Party.queueState == 0 then
								if AutoLeaveRandom.Enabled then
									local listofmodes = {}
									for i,v in pairs(bedwars.QueueMeta) do
										if not v.disabled and not v.voiceChatOnly and not v.rankCategory then table.insert(listofmodes, i) end
									end
									bedwars.QueueController:joinQueue(listofmodes[math.random(1, #listofmodes)])
								else
									bedwars.QueueController:joinQueue(store.queueType)
								end
							end
						end
					end
				end))
				table.insert(AutoLeave.Connections, playersService.PlayerAdded:Connect(autoLeaveAdded))
				for i, plr in pairs(playersService:GetPlayers()) do
					autoLeaveAdded(plr)
				end
			end
		end,
		HoverText = "Leaves if a staff member joins your game or when the match ends."
	})
	AutoLeaveDelay = AutoLeave.CreateSlider({
		Name = "Delay",
		Min = 0,
		Max = 50,
		Default = 0,
		Function = function() end,
		HoverText = "Delay before going back to the hub."
	})
	AutoPlayAgain = AutoLeave.CreateToggle({
		Name = "Play Again",
		Function = function() end,
		HoverText = "Automatically queues a new game.",
		Default = true
	})
	AutoLeaveStaff = AutoLeave.CreateToggle({
		Name = "Staff",
		Function = function(callback)
			if AutoLeaveStaff2.Object then
				AutoLeaveStaff2.Object.Visible = callback
			end
		end,
		HoverText = "Automatically uninjects when staff joins",
		Default = true
	})
	AutoLeaveStaff2 = AutoLeave.CreateToggle({
		Name = "Staff AutoConfig",
		Function = function() end,
		HoverText = "Instead of uninjecting, It will now reconfig vape temporarily to a more legit config.",
		Default = true
	})
	AutoLeaveRandom = AutoLeave.CreateToggle({
		Name = "Random",
		Function = function(callback) end,
		HoverText = "Chooses a random mode"
	})
	AutoLeaveStaff2.Object.Visible = false
end)

run(function()
	local oldclickhold
	local oldclickhold2
	local roact
	local FastConsume = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "FastConsume",
		Function = function(callback)
			if callback then
				oldclickhold = bedwars.ClickHold.startClick
				oldclickhold2 = bedwars.ClickHold.showProgress
				bedwars.ClickHold.showProgress = function(p5)
					local roact = debug.getupvalue(oldclickhold2, 1)
					local countdown = roact.mount(roact.createElement("ScreenGui", {}, { roact.createElement("Frame", {
						[roact.Ref] = p5.wrapperRef,
						Size = UDim2.new(0, 0, 0, 0),
						Position = UDim2.new(0.5, 0, 0.55, 0),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.8
					}, { roact.createElement("Frame", {
							[roact.Ref] = p5.progressRef,
							Size = UDim2.new(0, 0, 1, 0),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 0.5
						}) }) }), lplr:FindFirstChild("PlayerGui"))
					p5.handle = countdown
					local sizetween = tweenService:Create(p5.wrapperRef:getValue(), TweenInfo.new(0.1), {
						Size = UDim2.new(0.11, 0, 0.005, 0)
					})
					table.insert(p5.tweens, sizetween)
					sizetween:Play()
					local countdowntween = tweenService:Create(p5.progressRef:getValue(), TweenInfo.new(p5.durationSeconds * (FastConsumeVal.Value / 40), Enum.EasingStyle.Linear), {
						Size = UDim2.new(1, 0, 1, 0)
					})
					table.insert(p5.tweens, countdowntween)
					countdowntween:Play()
					return countdown
				end
				bedwars.ClickHold.startClick = function(p4)
					p4.startedClickTime = tick()
					local u2 = p4:showProgress()
					local clicktime = p4.startedClickTime
					bedwars.RuntimeLib.Promise.defer(function()
						task.wait(p4.durationSeconds * (FastConsumeVal.Value / 40))
						if u2 == p4.handle and clicktime == p4.startedClickTime and p4.closeOnComplete then
							p4:hideProgress()
							if p4.onComplete ~= nil then
								p4.onComplete()
							end
							if p4.onPartialComplete ~= nil then
								p4.onPartialComplete(1)
							end
							p4.startedClickTime = -1
						end
					end)
				end
			else
				bedwars.ClickHold.startClick = oldclickhold
				bedwars.ClickHold.showProgress = oldclickhold2
				oldclickhold = nil
				oldclickhold2 = nil
			end
		end,
		HoverText = "Use/Consume items quicker."
	})
	FastConsumeVal = FastConsume.CreateSlider({
		Name = "Ticks",
		Min = 0,
		Max = 40,
		Default = 0,
		Function = function() end
	})
end)

local autobankballoon = false
run(function()
	local Fly = {Enabled = false}
	local FlyMode = {Value = "CFrame"}
	local FlyVerticalSpeed = {Value = 40}
	local FlyVertical = {Enabled = true}
	local FlyAutoPop = {Enabled = true}
	local FlyAnyway = {Enabled = false}
	local FlyAnywayProgressBar = {Enabled = false}
	local FlyDamageAnimation = {Enabled = false}
	local FlyTP = {Enabled = false}
	local FlyAnywayProgressBarFrame
	local olddeflate
	local FlyUp = false
	local FlyDown = false
	local FlyCoroutine
	local groundtime = tick()
	local onground = false
	local lastonground = false
	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}

	local function inflateBalloon()
		if not Fly.Enabled then return end
		if entityLibrary.isAlive and (lplr.Character:GetAttribute("InflatedBalloons") or 0) < 1 then
			autobankballoon = true
			if getItem("balloon") then
				bedwars.BalloonController:inflateBalloon()
				return true
			end
		end
		return false
	end

	Fly = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Fly",
		Function = function(callback)
			if callback then
				olddeflate = bedwars.BalloonController.deflateBalloon
				bedwars.BalloonController.deflateBalloon = function() end

				table.insert(Fly.Connections, inputService.InputBegan:Connect(function(input1)
					if FlyVertical.Enabled and inputService:GetFocusedTextBox() == nil then
						if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
							FlyUp = true
						end
						if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
							FlyDown = true
						end
					end
				end))
				table.insert(Fly.Connections, inputService.InputEnded:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
						FlyUp = false
					end
					if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
						FlyDown = false
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						table.insert(Fly.Connections, jumpButton:GetPropertyChangedSignal("ImageRectOffset"):Connect(function()
							FlyUp = jumpButton.ImageRectOffset.X == 146
						end))
						FlyUp = jumpButton.ImageRectOffset.X == 146
					end)
				end
				table.insert(Fly.Connections, vapeEvents.BalloonPopped.Event:Connect(function(poppedTable)
					if poppedTable.inflatedBalloon and poppedTable.inflatedBalloon:GetAttribute("BalloonOwner") == lplr.UserId then
						lastonground = not onground
						repeat task.wait() until (lplr.Character:GetAttribute("InflatedBalloons") or 0) <= 0 or not Fly.Enabled
						inflateBalloon()
					end
				end))
				table.insert(Fly.Connections, vapeEvents.AutoBankBalloon.Event:Connect(function()
					repeat task.wait() until getItem("balloon")
					inflateBalloon()
				end))

				local balloons
				if entityLibrary.isAlive and (not store.queueType:find("mega")) then
					balloons = inflateBalloon()
				end
				local megacheck = store.queueType:find("mega") or store.queueType == "winter_event"

				task.spawn(function()
					repeat task.wait() until store.queueType ~= "bedwars_test" or (not Fly.Enabled)
					if not Fly.Enabled then return end
					megacheck = store.queueType:find("mega") or store.queueType == "winter_event"
				end)

				local flyAllowed = entityLibrary.isAlive and ((lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
				if flyAllowed <= 0 and shared.damageanim and (not balloons) then
					shared.damageanim()
					bedwars.SoundManager:playSound(bedwars.SoundList["DAMAGE_"..math.random(1, 3)])
				end

				if FlyAnywayProgressBarFrame and flyAllowed <= 0 and (not balloons) then
					FlyAnywayProgressBarFrame.Visible = true
					FlyAnywayProgressBarFrame.Frame:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
				end

				groundtime = tick() + (2.6 + (entityLibrary.groundTick - tick()))
				FlyCoroutine = coroutine.create(function()
					repeat
						repeat task.wait() until (groundtime - tick()) < 0.6 and not onground
						flyAllowed = ((lplr.Character and lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
						if (not Fly.Enabled) then break end
						local Flytppos = -99999
						if flyAllowed <= 0 and FlyTP.Enabled and entityLibrary.isAlive then
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(0, -1000, 0), store.blockRaycast)
							if ray then
								Flytppos = entityLibrary.character.HumanoidRootPart.Position.Y
								local args = {entityLibrary.character.HumanoidRootPart.CFrame:GetComponents()}
								args[2] = ray.Position.Y + (entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight
								entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(unpack(args))
								task.wait(0.12)
								if (not Fly.Enabled) then break end
								flyAllowed = ((lplr.Character and lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
								if flyAllowed <= 0 and Flytppos ~= -99999 and entityLibrary.isAlive then
									local args = {entityLibrary.character.HumanoidRootPart.CFrame:GetComponents()}
									args[2] = Flytppos
									entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(unpack(args))
								end
							end
						end
					until (not Fly.Enabled)
				end)
				coroutine.resume(FlyCoroutine)

				RunLoops:BindToHeartbeat("Fly", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if bedwars.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						local playerMass = (entityLibrary.character.HumanoidRootPart:GetMass() - 1.4) * (delta * 100)
						flyAllowed = ((lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") > 0) or store.matchState == 2 or megacheck) and 1 or 0
						playerMass = playerMass + (flyAllowed > 0 and 4 or 0) * (tick() % 0.4 < 0.2 and -1 or 1)

						if FlyAnywayProgressBarFrame then
							FlyAnywayProgressBarFrame.Visible = flyAllowed <= 0
							FlyAnywayProgressBarFrame.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
							FlyAnywayProgressBarFrame.Frame.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
						end

						if flyAllowed <= 0 then
							local newray = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + Vector3.new(0, (entityLibrary.character.Humanoid.HipHeight * -2) - 1, 0))
							onground = newray and true or false
							if lastonground ~= onground then
								if (not onground) then
									groundtime = tick() + (2.6 + (entityLibrary.groundTick - tick()))
									if FlyAnywayProgressBarFrame then
										FlyAnywayProgressBarFrame.Frame:TweenSize(UDim2.new(0, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, groundtime - tick(), true)
									end
								else
									if FlyAnywayProgressBarFrame then
										FlyAnywayProgressBarFrame.Frame:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
									end
								end
							end
							if FlyAnywayProgressBarFrame then
								FlyAnywayProgressBarFrame.TextLabel.Text = math.max(onground and 2.5 or math.floor((groundtime - tick()) * 10) / 10, 0).."s"
							end
							lastonground = onground
						else
							onground = true
							lastonground = true
						end

						local flyVelocity = entityLibrary.character.Humanoid.MoveDirection * (FlyMode.Value == "Normal" and FlySpeed.Value or 20)
						entityLibrary.character.HumanoidRootPart.Velocity = flyVelocity + (Vector3.new(0, playerMass + (FlyUp and FlyVerticalSpeed.Value or 0) + (FlyDown and -FlyVerticalSpeed.Value or 0), 0))
						if FlyMode.Value ~= "Normal" then
							entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + (entityLibrary.character.Humanoid.MoveDirection * ((FlySpeed.Value + getSpeed()) - 20)) * delta
						end
					end
				end)
			else
				pcall(function() coroutine.close(FlyCoroutine) end)
				autobankballoon = false
				waitingforballoon = false
				lastonground = nil
				FlyUp = false
				FlyDown = false
				RunLoops:UnbindFromHeartbeat("Fly")
				if FlyAnywayProgressBarFrame then
					FlyAnywayProgressBarFrame.Visible = false
				end
				if FlyAutoPop.Enabled then
					if entityLibrary.isAlive and lplr.Character:GetAttribute("InflatedBalloons") then
						for i = 1, lplr.Character:GetAttribute("InflatedBalloons") do
							olddeflate()
						end
					end
				end
				bedwars.BalloonController.deflateBalloon = olddeflate
				olddeflate = nil
			end
		end,
		HoverText = "Makes you go zoom (longer Fly discovered by exelys and Cqded)",
		ExtraText = function()
			return "Heatseeker"
		end
	})
	FlySpeed = Fly.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	FlyVerticalSpeed = Fly.CreateSlider({
		Name = "Vertical Speed",
		Min = 1,
		Max = 100,
		Function = function(val) end,
		Default = 44
	})
	FlyVertical = Fly.CreateToggle({
		Name = "Y Level",
		Function = function() end,
		Default = true
	})
	FlyAutoPop = Fly.CreateToggle({
		Name = "Pop Balloon",
		Function = function() end,
		HoverText = "Pops balloons when Fly is disabled."
	})
	local oldcamupdate
	local camcontrol
	local Flydamagecamera = {Enabled = false}
	FlyDamageAnimation = Fly.CreateToggle({
		Name = "Damage Animation",
		Function = function(callback)
			if Flydamagecamera.Object then
				Flydamagecamera.Object.Visible = callback
			end
			if callback then
				task.spawn(function()
					repeat
						task.wait(0.1)
						for i,v in pairs(getconnections(gameCamera:GetPropertyChangedSignal("CameraType"))) do
							if v.Function then
								camcontrol = debug.getupvalue(v.Function, 1)
							end
						end
					until camcontrol
					local caminput = require(lplr.PlayerScripts.PlayerModule.CameraModule.CameraInput)
					local num = Instance.new("IntValue")
					local numanim
					shared.damageanim = function()
						if numanim then numanim:Cancel() end
						if Flydamagecamera.Enabled then
							num.Value = 1000
							numanim = tweenService:Create(num, TweenInfo.new(0.5), {Value = 0})
							numanim:Play()
						end
					end
					oldcamupdate = camcontrol.Update
					camcontrol.Update = function(self, dt)
						if camcontrol.activeCameraController then
							camcontrol.activeCameraController:UpdateMouseBehavior()
							local newCameraCFrame, newCameraFocus = camcontrol.activeCameraController:Update(dt)
							gameCamera.CFrame = newCameraCFrame * CFrame.Angles(0, 0, math.rad(num.Value / 100))
							gameCamera.Focus = newCameraFocus
							if camcontrol.activeTransparencyController then
								camcontrol.activeTransparencyController:Update(dt)
							end
							if caminput.getInputEnabled() then
								caminput.resetInputForFrameEnd()
							end
						end
					end
				end)
			else
				shared.damageanim = nil
				if camcontrol then
					camcontrol.Update = oldcamupdate
				end
			end
		end
	})
	Flydamagecamera = Fly.CreateToggle({
		Name = "Camera Animation",
		Function = function() end,
		Default = true
	})
	Flydamagecamera.Object.BorderSizePixel = 0
	Flydamagecamera.Object.BackgroundTransparency = 0
	Flydamagecamera.Object.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	Flydamagecamera.Object.Visible = false
	FlyAnywayProgressBar = Fly.CreateToggle({
		Name = "Progress Bar",
		Function = function(callback)
			if callback then
				FlyAnywayProgressBarFrame = Instance.new("Frame")
				FlyAnywayProgressBarFrame.AnchorPoint = Vector2.new(0.5, 0)
				FlyAnywayProgressBarFrame.Position = UDim2.new(0.5, 0, 1, -200)
				FlyAnywayProgressBarFrame.Size = UDim2.new(0.2, 0, 0, 20)
				FlyAnywayProgressBarFrame.BackgroundTransparency = 0.5
				FlyAnywayProgressBarFrame.BorderSizePixel = 0
				FlyAnywayProgressBarFrame.BackgroundColor3 = Color3.new(0, 0, 0)
				FlyAnywayProgressBarFrame.Visible = Fly.Enabled
				FlyAnywayProgressBarFrame.Parent = GuiLibrary.MainGui
				local FlyAnywayProgressBarFrame2 = FlyAnywayProgressBarFrame:Clone()
				FlyAnywayProgressBarFrame2.AnchorPoint = Vector2.new(0, 0)
				FlyAnywayProgressBarFrame2.Position = UDim2.new(0, 0, 0, 0)
				FlyAnywayProgressBarFrame2.Size = UDim2.new(1, 0, 0, 20)
				FlyAnywayProgressBarFrame2.BackgroundTransparency = 0
				FlyAnywayProgressBarFrame2.Visible = true
				FlyAnywayProgressBarFrame2.Parent = FlyAnywayProgressBarFrame
				local FlyAnywayProgressBartext = Instance.new("TextLabel")
				FlyAnywayProgressBartext.Text = "2s"
				FlyAnywayProgressBartext.Font = Enum.Font.Gotham
				FlyAnywayProgressBartext.TextStrokeTransparency = 0
				FlyAnywayProgressBartext.TextColor3 =  Color3.new(0.9, 0.9, 0.9)
				FlyAnywayProgressBartext.TextSize = 20
				FlyAnywayProgressBartext.Size = UDim2.new(1, 0, 1, 0)
				FlyAnywayProgressBartext.BackgroundTransparency = 1
				FlyAnywayProgressBartext.Position = UDim2.new(0, 0, -1, 0)
				FlyAnywayProgressBartext.Parent = FlyAnywayProgressBarFrame
			else
				if FlyAnywayProgressBarFrame then FlyAnywayProgressBarFrame:Destroy() FlyAnywayProgressBarFrame = nil end
			end
		end,
		HoverText = "show amount of Fly time",
		Default = true
	})
	FlyTP = Fly.CreateToggle({
		Name = "TP Down",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local GrappleExploit = {Enabled = false}
	local GrappleExploitMode = {Value = "Normal"}
	local GrappleExploitVerticalSpeed = {Value = 40}
	local GrappleExploitVertical = {Enabled = true}
	local GrappleExploitUp = false
	local GrappleExploitDown = false
	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}
	local projectileRemote = bedwars.Client:Get(bedwars.ProjectileRemote)

	--me when I have to fix bw code omegalol
	bedwars.Client:Get("GrapplingHookFunctions"):Connect(function(p4)
		if p4.hookFunction == "PLAYER_IN_TRANSIT" then
			bedwars.CooldownController:setOnCooldown("grappling_hook", 3.5)
		end
	end)

	GrappleExploit = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "GrappleExploit",
		Function = function(callback)
			if callback then
				local grappleHooked = false
				table.insert(GrappleExploit.Connections, bedwars.Client:Get("GrapplingHookFunctions"):Connect(function(p4)
					if p4.hookFunction == "PLAYER_IN_TRANSIT" then
						store.grapple = tick() + 1.8
						grappleHooked = true
						GrappleExploit.ToggleButton(false)
					end
				end))

				local fireball = getItem("grappling_hook")
				if fireball then
					task.spawn(function()
						repeat task.wait() until bedwars.CooldownController:getRemainingCooldown("grappling_hook") == 0 or (not GrappleExploit.Enabled)
						if (not GrappleExploit.Enabled) then return end
						switchItem(fireball.tool)
						local pos = entityLibrary.character.HumanoidRootPart.CFrame.p
						local offsetshootpos = (CFrame.new(pos, pos + Vector3.new(0, -60, 0)) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).p
						projectileRemote:CallServerAsync(fireball["tool"], nil, "grappling_hook_projectile", offsetshootpos, pos, Vector3.new(0, -60, 0), game:GetService("HttpService"):GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045)
					end)
				else
					warningNotification("GrappleExploit", "missing grapple hook", 3)
					GrappleExploit.ToggleButton(false)
					return
				end

				local startCFrame = entityLibrary.isAlive and entityLibrary.character.HumanoidRootPart.CFrame
				RunLoops:BindToHeartbeat("GrappleExploit", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if bedwars.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						entityLibrary.character.HumanoidRootPart.Velocity = Vector3.zero
						entityLibrary.character.HumanoidRootPart.CFrame = startCFrame
					end
				end)
			else
				GrappleExploitUp = false
				GrappleExploitDown = false
				RunLoops:UnbindFromHeartbeat("GrappleExploit")
			end
		end,
		HoverText = "Makes you go zoom (longer GrappleExploit discovered by exelys and Cqded)",
		ExtraText = function()
			if GuiLibrary.ObjectsThatCanBeSaved["Text GUIAlternate TextToggle"]["Api"].Enabled then
				return alternatelist[table.find(GrappleExploitMode["List"], GrappleExploitMode.Value)]
			end
			return GrappleExploitMode.Value
		end
	})
end)

run(function()
	local InfiniteFly = {Enabled = false}
	local InfiniteFlyMode = {Value = "CFrame"}
	local InfiniteFlySpeed = {Value = 23}
	local InfiniteFlyVerticalSpeed = {Value = 40}
	local InfiniteFlyVertical = {Enabled = true}
	local InfiniteFlyUp = false
	local InfiniteFlyDown = false
	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}
	local clonesuccess = false
	local disabledproper = true
	local oldcloneroot
	local cloned
	local clone
	local bodyvelo
	local FlyOverlap = OverlapParams.new()
	FlyOverlap.MaxParts = 9e9
	FlyOverlap.FilterDescendantsInstances = {}
	FlyOverlap.RespectCanCollide = true

	local function disablefunc()
		if bodyvelo then bodyvelo:Destroy() end
		RunLoops:UnbindFromHeartbeat("InfiniteFlyOff")
		disabledproper = true
		if not oldcloneroot or not oldcloneroot.Parent then return end
		lplr.Character.Parent = game
		oldcloneroot.Parent = lplr.Character
		lplr.Character.PrimaryPart = oldcloneroot
		lplr.Character.Parent = workspace
		oldcloneroot.CanCollide = true
		for i,v in pairs(lplr.Character:GetDescendants()) do
			if v:IsA("Weld") or v:IsA("Motor6D") then
				if v.Part0 == clone then v.Part0 = oldcloneroot end
				if v.Part1 == clone then v.Part1 = oldcloneroot end
			end
			if v:IsA("BodyVelocity") then
				v:Destroy()
			end
		end
		for i,v in pairs(oldcloneroot:GetChildren()) do
			if v:IsA("BodyVelocity") then
				v:Destroy()
			end
		end
		local oldclonepos = clone.Position.Y
		if clone then
			clone:Destroy()
			clone = nil
		end
		lplr.Character.Humanoid.HipHeight = hip or 2
		local origcf = {oldcloneroot.CFrame:GetComponents()}
		origcf[2] = oldclonepos
		oldcloneroot.CFrame = CFrame.new(unpack(origcf))
		oldcloneroot = nil
		warningNotification("InfiniteFly", "Landed!", 3)
	end

	InfiniteFly = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "InfiniteFly",
		Function = function(callback)
			if callback then
				if not entityLibrary.isAlive then
					disabledproper = true
				end
				if not disabledproper then
					warningNotification("InfiniteFly", "Wait for the last fly to finish", 3)
					InfiniteFly.ToggleButton(false)
					return
				end
				table.insert(InfiniteFly.Connections, inputService.InputBegan:Connect(function(input1)
					if InfiniteFlyVertical.Enabled and inputService:GetFocusedTextBox() == nil then
						if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
							InfiniteFlyUp = true
						end
						if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
							InfiniteFlyDown = true
						end
					end
				end))
				table.insert(InfiniteFly.Connections, inputService.InputEnded:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.Space or input1.KeyCode == Enum.KeyCode.ButtonA then
						InfiniteFlyUp = false
					end
					if input1.KeyCode == Enum.KeyCode.LeftShift or input1.KeyCode == Enum.KeyCode.ButtonL2 then
						InfiniteFlyDown = false
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						table.insert(InfiniteFly.Connections, jumpButton:GetPropertyChangedSignal("ImageRectOffset"):Connect(function()
							InfiniteFlyUp = jumpButton.ImageRectOffset.X == 146
						end))
						InfiniteFlyUp = jumpButton.ImageRectOffset.X == 146
					end)
				end
				clonesuccess = false
				if entityLibrary.isAlive and entityLibrary.character.Humanoid.Health > 0 and isnetworkowner(entityLibrary.character.HumanoidRootPart) then
					cloned = lplr.Character
					oldcloneroot = entityLibrary.character.HumanoidRootPart
					if not lplr.Character.Parent then
						InfiniteFly.ToggleButton(false)
						return
					end
					lplr.Character.Parent = game
					clone = oldcloneroot:Clone()
					clone.Parent = lplr.Character
					oldcloneroot.Parent = gameCamera
					bedwars.QueryUtil:setQueryIgnored(oldcloneroot, true)
					clone.CFrame = oldcloneroot.CFrame
					lplr.Character.PrimaryPart = clone
					lplr.Character.Parent = workspace
					for i,v in pairs(lplr.Character:GetDescendants()) do
						if v:IsA("Weld") or v:IsA("Motor6D") then
							if v.Part0 == oldcloneroot then v.Part0 = clone end
							if v.Part1 == oldcloneroot then v.Part1 = clone end
						end
						if v:IsA("BodyVelocity") then
							v:Destroy()
						end
					end
					for i,v in pairs(oldcloneroot:GetChildren()) do
						if v:IsA("BodyVelocity") then
							v:Destroy()
						end
					end
					if hip then
						lplr.Character.Humanoid.HipHeight = hip
					end
					hip = lplr.Character.Humanoid.HipHeight
					clonesuccess = true
				end
				if not clonesuccess then
					warningNotification("InfiniteFly", "Character missing", 3)
					InfiniteFly.ToggleButton(false)
					return
				end
				local goneup = false
				RunLoops:BindToHeartbeat("InfiniteFly", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if store.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						if isnetworkowner(oldcloneroot) then
							local playerMass = (entityLibrary.character.HumanoidRootPart:GetMass() - 1.4) * (delta * 100)

							local flyVelocity = entityLibrary.character.Humanoid.MoveDirection * (InfiniteFlyMode.Value == "Normal" and InfiniteFlySpeed.Value or 20)
							entityLibrary.character.HumanoidRootPart.Velocity = flyVelocity + (Vector3.new(0, playerMass + (InfiniteFlyUp and InfiniteFlyVerticalSpeed.Value or 0) + (InfiniteFlyDown and -InfiniteFlyVerticalSpeed.Value or 0), 0))
							if InfiniteFlyMode.Value ~= "Normal" then
								entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + (entityLibrary.character.Humanoid.MoveDirection * ((InfiniteFlySpeed.Value + getSpeed()) - 20)) * delta
							end

							local speedCFrame = {oldcloneroot.CFrame:GetComponents()}
							speedCFrame[1] = clone.CFrame.X
							if speedCFrame[2] < 1000 or (not goneup) then
								task.spawn(warningNotification, "InfiniteFly", "Teleported Up", 3)
								speedCFrame[2] = 100000
								goneup = true
							end
							speedCFrame[3] = clone.CFrame.Z
							oldcloneroot.CFrame = CFrame.new(unpack(speedCFrame))
							oldcloneroot.Velocity = Vector3.new(clone.Velocity.X, oldcloneroot.Velocity.Y, clone.Velocity.Z)
						else
							InfiniteFly.ToggleButton(false)
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("InfiniteFly")
				if clonesuccess and oldcloneroot and clone and lplr.Character.Parent == workspace and oldcloneroot.Parent ~= nil and disabledproper and cloned == lplr.Character then
					local rayparams = RaycastParams.new()
					rayparams.FilterDescendantsInstances = {lplr.Character, gameCamera}
					rayparams.RespectCanCollide = true
					local ray = workspace:Raycast(Vector3.new(oldcloneroot.Position.X, clone.CFrame.p.Y, oldcloneroot.Position.Z), Vector3.new(0, -1000, 0), rayparams)
					local origcf = {clone.CFrame:GetComponents()}
					origcf[1] = oldcloneroot.Position.X
					origcf[2] = ray and ray.Position.Y + (entityLibrary.character.Humanoid.HipHeight + (oldcloneroot.Size.Y / 2)) or clone.CFrame.p.Y
					origcf[3] = oldcloneroot.Position.Z
					oldcloneroot.CanCollide = true
					bodyvelo = Instance.new("BodyVelocity")
					bodyvelo.MaxForce = Vector3.new(0, 9e9, 0)
					bodyvelo.Velocity = Vector3.new(0, -1, 0)
					bodyvelo.Parent = oldcloneroot
					oldcloneroot.Velocity = Vector3.new(clone.Velocity.X, -1, clone.Velocity.Z)
					RunLoops:BindToHeartbeat("InfiniteFlyOff", function(dt)
						if oldcloneroot then
							oldcloneroot.Velocity = Vector3.new(clone.Velocity.X, -1, clone.Velocity.Z)
							local bruh = {clone.CFrame:GetComponents()}
							bruh[2] = oldcloneroot.CFrame.Y
							local newcf = CFrame.new(unpack(bruh))
							FlyOverlap.FilterDescendantsInstances = {lplr.Character, gameCamera}
							local allowed = true
							for i,v in pairs(workspace:GetPartBoundsInRadius(newcf.p, 2, FlyOverlap)) do
								if (v.Position.Y + (v.Size.Y / 2)) > (newcf.p.Y + 0.5) then
									allowed = false
									break
								end
							end
							if allowed then
								oldcloneroot.CFrame = newcf
							end
						end
					end)
					oldcloneroot.CFrame = CFrame.new(unpack(origcf))
					entityLibrary.character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
					disabledproper = false
					if isnetworkowner(oldcloneroot) then
						warningNotification("InfiniteFly", "Waiting 1.1s to not flag", 3)
						task.delay(1.1, disablefunc)
					else
						disablefunc()
					end
				end
				InfiniteFlyUp = false
				InfiniteFlyDown = false
			end
		end,
		HoverText = "Makes you go zoom",
		ExtraText = function()
			return "Heatseeker"
		end
	})
	InfiniteFlySpeed = InfiniteFly.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	InfiniteFlyVerticalSpeed = InfiniteFly.CreateSlider({
		Name = "Vertical Speed",
		Min = 1,
		Max = 100,
		Function = function(val) end,
		Default = 44
	})
	InfiniteFlyVertical = InfiniteFly.CreateToggle({
		Name = "Y Level",
		Function = function() end,
		Default = true
	})
end)

local killauraNearPlayer
run(function()
	local killauraboxes = {}
	local killauratargetframe = {Players = {Enabled = false}}
	local killaurasortmethod = {Value = "Distance"}
	local killaurarealremote = bedwars.Client:Get(bedwars.AttackRemote).instance
	local killauramethod = {Value = "Normal"}
	local killauraothermethod = {Value = "Normal"}
	local killauraanimmethod = {Value = "Normal"}
	local killaurarange = {Value = 14}
	local killauraangle = {Value = 360}
	local killauratargets = {Value = 10}
	local killauraautoblock = {Enabled = false}
	local killauramouse = {Enabled = false}
	local killauracframe = {Enabled = false}
	local killauragui = {Enabled = false}
	local killauratarget = {Enabled = false}
	local killaurasound = {Enabled = false}
	local killauraswing = {Enabled = false}
	local killaurasync = {Enabled = false}
	local killaurahandcheck = {Enabled = false}
	local killauraanimation = {Enabled = false}
	local killauraanimationtween = {Enabled = false}
	local killauracolor = {Value = 0.44}
	local killauranovape = {Enabled = false}
	local killauratargethighlight = {Enabled = false}
	local killaurarangecircle = {Enabled = false}
	local killaurarangecirclepart
	local killauraaimcircle = {Enabled = false}
	local killauraaimcirclepart
	local killauraparticle = {Enabled = false}
	local killauraparticlepart
	local Killauranear = false
	local killauraplaying = false
	local oldViewmodelAnimation = function() end
	local oldPlaySound = function() end
	local originalArmC0 = nil
	local killauracurrentanim
	local animationdelay = tick()

	local function getStrength(plr)
		local inv = store.inventories[plr.Player]
		local strength = 0
		local strongestsword = 0
		if inv then
			for i,v in pairs(inv.items) do
				local itemmeta = bedwars.ItemTable[v.itemType]
				if itemmeta and itemmeta.sword and itemmeta.sword.damage > strongestsword then
					strongestsword = itemmeta.sword.damage / 100
				end
			end
			strength = strength + strongestsword
			for i,v in pairs(inv.armor) do
				local itemmeta = bedwars.ItemTable[v.itemType]
				if itemmeta and itemmeta.armor then
					strength = strength + (itemmeta.armor.damageReductionMultiplier or 0)
				end
			end
			strength = strength
		end
		return strength
	end

	local kitpriolist = {
		hannah = 5,
		spirit_assassin = 4,
		dasher = 3,
		jade = 2,
		regent = 1
	}

	local killaurasortmethods = {
		Distance = function(a, b)
			return (a.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position).Magnitude < (b.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position).Magnitude
		end,
		Health = function(a, b)
			return a.Humanoid.Health < b.Humanoid.Health
		end,
		Threat = function(a, b)
			return getStrength(a) > getStrength(b)
		end,
		Kit = function(a, b)
			return (kitpriolist[a.Player:GetAttribute("PlayingAsKit")] or 0) > (kitpriolist[b.Player:GetAttribute("PlayingAsKit")] or 0)
		end
	}

	local originalNeckC0
	local originalRootC0
	local anims = {
		Normal = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.05},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.05}
		},
		Slow = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.15}
		},
		New = {
			{CFrame = CFrame.new(0.69, -0.77, 1.47) * CFrame.Angles(math.rad(-33), math.rad(57), math.rad(-81)), Time = 0.12},
			{CFrame = CFrame.new(0.74, -0.92, 0.88) * CFrame.Angles(math.rad(147), math.rad(71), math.rad(53)), Time = 0.12}
		},
		Latest = {
			{CFrame = CFrame.new(0.69, -0.7, 0.1) * CFrame.Angles(math.rad(-65), math.rad(55), math.rad(-51)), Time = 0.1},
			{CFrame = CFrame.new(0.16, -1.16, 0.5) * CFrame.Angles(math.rad(-179), math.rad(54), math.rad(33)), Time = 0.1}
		},
		["Vertical Spin"] = {
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), math.rad(8), math.rad(5)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(180), math.rad(3), math.rad(13)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(90), math.rad(-5), math.rad(8)), Time = 0.1},
			{CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-0), math.rad(-0)), Time = 0.1}
		},
		Exhibition = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.2}
		},
		["Exhibition Old"] = {
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.15},
			{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.05},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.1},
			{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.05},
			{CFrame = CFrame.new(0.63, -0.1, 1.37) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.15}
		}
	}

	local function closestpos(block, pos)
		local blockpos = block:GetRenderCFrame()
		local startpos = (blockpos * CFrame.new(-(block.Size / 2))).p
		local endpos = (blockpos * CFrame.new((block.Size / 2))).p
		local speedCFrame = block.Position + (pos - block.Position)
		local x = startpos.X > endpos.X and endpos.X or startpos.X
		local y = startpos.Y > endpos.Y and endpos.Y or startpos.Y
		local z = startpos.Z > endpos.Z and endpos.Z or startpos.Z
		local x2 = startpos.X < endpos.X and endpos.X or startpos.X
		local y2 = startpos.Y < endpos.Y and endpos.Y or startpos.Y
		local z2 = startpos.Z < endpos.Z and endpos.Z or startpos.Z
		return Vector3.new(math.clamp(speedCFrame.X, x, x2), math.clamp(speedCFrame.Y, y, y2), math.clamp(speedCFrame.Z, z, z2))
	end

	local function getAttackData()
		if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
			if store.matchState == 0 then return false end
		end
		if killauramouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end
		if killauragui.Enabled then
			if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return false end
		end
		local sword = killaurahandcheck.Enabled and store.localHand or getSword()
		if not sword or not sword.tool then return false end
		local swordmeta = bedwars.ItemTable[sword.tool.Name]
		if killaurahandcheck.Enabled then
			if store.localHand.Type ~= "sword" or bedwars.DaoController.chargingMaid then return false end
		end
		return sword, swordmeta
	end

	local function autoBlockLoop()
		if not killauraautoblock.Enabled or not Killaura.Enabled then return end
		repeat
			if store.blockPlace < tick() and entityLibrary.isAlive then
				local shield = getItem("infernal_shield")
				if shield then
					switchItem(shield.tool)
					if not lplr.Character:GetAttribute("InfernalShieldRaised") then
						bedwars.InfernalShieldController:raiseShield()
					end
				end
			end
			task.wait()
		until (not Killaura.Enabled) or (not killauraautoblock.Enabled)
	end

	Killaura = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Killaura",
		Function = function(callback)
			if callback then
				if killauraaimcirclepart then killauraaimcirclepart.Parent = gameCamera end
				if killaurarangecirclepart then killaurarangecirclepart.Parent = gameCamera end
				if killauraparticlepart then killauraparticlepart.Parent = gameCamera end

				task.spawn(function()
					local oldNearPlayer
					repeat
						task.wait()
						if (killauraanimation.Enabled and not killauraswing.Enabled) then
							if killauraNearPlayer then
								pcall(function()
									if originalArmC0 == nil then
										originalArmC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
									end
									if killauraplaying == false then
										killauraplaying = true
										for i,v in pairs(anims[killauraanimmethod.Value]) do
											if (not Killaura.Enabled) or (not killauraNearPlayer) then break end
											if not oldNearPlayer and killauraanimationtween.Enabled then
												gameCamera.Viewmodel.RightHand.RightWrist.C0 = originalArmC0 * v.CFrame
												continue
											end
											killauracurrentanim = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(v.Time), {C0 = originalArmC0 * v.CFrame})
											killauracurrentanim:Play()
											task.wait(v.Time - 0.01)
										end
										killauraplaying = false
									end
								end)
							end
							oldNearPlayer = killauraNearPlayer
						end
					until Killaura.Enabled == false
				end)

				oldViewmodelAnimation = bedwars.ViewmodelController.playAnimation
				oldPlaySound = bedwars.SoundManager.playSound
				bedwars.SoundManager.playSound = function(tab, soundid, ...)
					if (soundid == bedwars.SoundList.SWORD_SWING_1 or soundid == bedwars.SoundList.SWORD_SWING_2) and Killaura.Enabled and killaurasound.Enabled and killauraNearPlayer then
						return nil
					end
					return oldPlaySound(tab, soundid, ...)
				end
				bedwars.ViewmodelController.playAnimation = function(Self, id, ...)
					if id == 15 and killauraNearPlayer and killauraswing.Enabled and entityLibrary.isAlive then
						return nil
					end
					if id == 15 and killauraNearPlayer and killauraanimation.Enabled and entityLibrary.isAlive then
						return nil
					end
					return oldViewmodelAnimation(Self, id, ...)
				end

				local targetedPlayer
				RunLoops:BindToHeartbeat("Killaura", function()
					for i,v in pairs(killauraboxes) do
						if v:IsA("BoxHandleAdornment") and v.Adornee then
							local cf = v.Adornee and v.Adornee.CFrame
							local onex, oney, onez = cf:ToEulerAnglesXYZ()
							v.CFrame = CFrame.new() * CFrame.Angles(-onex, -oney, -onez)
						end
					end
					if entityLibrary.isAlive then
						if killauraaimcirclepart then
							killauraaimcirclepart.Position = targetedPlayer and closestpos(targetedPlayer.RootPart, entityLibrary.character.HumanoidRootPart.Position) or Vector3.new(99999, 99999, 99999)
						end
						if killauraparticlepart then
							killauraparticlepart.Position = targetedPlayer and targetedPlayer.RootPart.Position or Vector3.new(99999, 99999, 99999)
						end
						local Root = entityLibrary.character.HumanoidRootPart
						if Root then
							if killaurarangecirclepart then
								killaurarangecirclepart.Position = Root.Position - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight, 0)
							end
							local Neck = entityLibrary.character.Head:FindFirstChild("Neck")
							local LowerTorso = Root.Parent and Root.Parent:FindFirstChild("LowerTorso")
							local RootC0 = LowerTorso and LowerTorso:FindFirstChild("Root")
							if Neck and RootC0 then
								if originalNeckC0 == nil then
									originalNeckC0 = Neck.C0.p
								end
								if originalRootC0 == nil then
									originalRootC0 = RootC0.C0.p
								end
								if originalRootC0 and killauracframe.Enabled then
									if targetedPlayer ~= nil then
										local targetPos = targetedPlayer.RootPart.Position + Vector3.new(0, 2, 0)
										local direction = (Vector3.new(targetPos.X, targetPos.Y, targetPos.Z) - entityLibrary.character.Head.Position).Unit
										local direction2 = (Vector3.new(targetPos.X, Root.Position.Y, targetPos.Z) - Root.Position).Unit
										local lookCFrame = (CFrame.new(Vector3.zero, (Root.CFrame):VectorToObjectSpace(direction)))
										local lookCFrame2 = (CFrame.new(Vector3.zero, (Root.CFrame):VectorToObjectSpace(direction2)))
										Neck.C0 = CFrame.new(originalNeckC0) * CFrame.Angles(lookCFrame.LookVector.Unit.y, 0, 0)
										RootC0.C0 = lookCFrame2 + originalRootC0
									else
										Neck.C0 = CFrame.new(originalNeckC0)
										RootC0.C0 = CFrame.new(originalRootC0)
									end
								end
							end
						end
					end
				end)
				if killauraautoblock.Enabled then
					task.spawn(autoBlockLoop)
				end
				task.spawn(function()
					repeat
						task.wait()
						if not Killaura.Enabled then break end
						vapeTargetInfo.Targets.Killaura = nil
						local plrs = AllNearPosition(killaurarange.Value, 10, killaurasortmethods[killaurasortmethod.Value], true)
						local firstPlayerNear
						if #plrs > 0 then
							local sword, swordmeta = getAttackData()
							if sword then
								switchItem(sword.tool)
								for i, plr in pairs(plrs) do
									local root = plr.RootPart
									if not root then
										continue
									end
									local localfacing = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
									local vec = (plr.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position).unit
									local angle = math.acos(localfacing:Dot(vec))
									if angle >= (math.rad(killauraangle.Value) / 2) then
										continue
									end
									local selfrootpos = entityLibrary.character.HumanoidRootPart.Position
									if killauratargetframe.Walls.Enabled then
										if not bedwars.SwordController:canSee({player = plr.Player, getInstance = function() return plr.Character end}) then continue end
									end
									if killauranovape.Enabled and store.whitelist.clientUsers[plr.Player.Name] then
										continue
									end
									if not firstPlayerNear then
										firstPlayerNear = true
										killauraNearPlayer = true
										targetedPlayer = plr
										vapeTargetInfo.Targets.Killaura = {
											Humanoid = {
												Health = (plr.Character:GetAttribute("Health") or plr.Humanoid.Health) + getShieldAttribute(plr.Character),
												MaxHealth = plr.Character:GetAttribute("MaxHealth") or plr.Humanoid.MaxHealth
											},
											Player = plr.Player
										}
										if animationdelay <= tick() then
											animationdelay = tick() + (swordmeta.sword.respectAttackSpeedForEffects and swordmeta.sword.attackSpeed or (killaurasync.Enabled and 0.24 or 0.14))
											if not killauraswing.Enabled then
												bedwars.SwordController:playSwordEffect(swordmeta, false)
											end
											if swordmeta.displayName:find(" Scythe") then
												bedwars.ScytheController:playLocalAnimation()
											end
										end
									end
									if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) < 0.02 then
										break
									end
									local selfpos = selfrootpos + (killaurarange.Value > 14 and (selfrootpos - root.Position).magnitude > 14.4 and (CFrame.lookAt(selfrootpos, root.Position).lookVector * ((selfrootpos - root.Position).magnitude - 14)) or Vector3.zero)
									bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
									store.attackReach = math.floor((selfrootpos - root.Position).magnitude * 100) / 100
									store.attackReachUpdate = tick() + 1
									killaurarealremote:FireServer({
										weapon = sword.tool,
										chargedAttack = {chargeRatio = swordmeta.sword.chargedAttack and not swordmeta.sword.chargedAttack.disableOnGrounded and 0.999 or 0},
										entityInstance = plr.Character,
										validate = {
											raycast = {
												cameraPosition = attackValue(root.Position),
												cursorDirection = attackValue(CFrame.new(selfpos, root.Position).lookVector)
											},
											targetPosition = attackValue(root.Position),
											selfPosition = attackValue(selfpos)
										}
									})
									break
								end
							end
						end
						if not firstPlayerNear then
							targetedPlayer = nil
							killauraNearPlayer = false
							pcall(function()
								if originalArmC0 == nil then
									originalArmC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
								end
								if gameCamera.Viewmodel.RightHand.RightWrist.C0 ~= originalArmC0 then
									pcall(function()
										killauracurrentanim:Cancel()
									end)
									if killauraanimationtween.Enabled then
										gameCamera.Viewmodel.RightHand.RightWrist.C0 = originalArmC0
									else
										killauracurrentanim = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.1), {C0 = originalArmC0})
										killauracurrentanim:Play()
									end
								end
							end)
						end
						for i,v in pairs(killauraboxes) do
							local attacked = killauratarget.Enabled and plrs[i] or nil
							v.Adornee = attacked and ((not killauratargethighlight.Enabled) and attacked.RootPart or (not GuiLibrary.ObjectsThatCanBeSaved.ChamsOptionsButton.Api.Enabled) and attacked.Character or nil)
						end
					until (not Killaura.Enabled)
				end)
			else
				vapeTargetInfo.Targets.Killaura = nil
				RunLoops:UnbindFromHeartbeat("Killaura")
				killauraNearPlayer = false
				for i,v in pairs(killauraboxes) do v.Adornee = nil end
				if killauraaimcirclepart then killauraaimcirclepart.Parent = nil end
				if killaurarangecirclepart then killaurarangecirclepart.Parent = nil end
				if killauraparticlepart then killauraparticlepart.Parent = nil end
				bedwars.ViewmodelController.playAnimation = oldViewmodelAnimation
				bedwars.SoundManager.playSound = oldPlaySound
				oldViewmodelAnimation = nil
				pcall(function()
					if entityLibrary.isAlive then
						local Root = entityLibrary.character.HumanoidRootPart
						if Root then
							local Neck = Root.Parent.Head.Neck
							if originalNeckC0 and originalRootC0 then
								Neck.C0 = CFrame.new(originalNeckC0)
								Root.Parent.LowerTorso.Root.C0 = CFrame.new(originalRootC0)
							end
						end
					end
					if originalArmC0 == nil then
						originalArmC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
					end
					if gameCamera.Viewmodel.RightHand.RightWrist.C0 ~= originalArmC0 then
						pcall(function()
							killauracurrentanim:Cancel()
						end)
						if killauraanimationtween.Enabled then
							gameCamera.Viewmodel.RightHand.RightWrist.C0 = originalArmC0
						else
							killauracurrentanim = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.1), {C0 = originalArmC0})
							killauracurrentanim:Play()
						end
					end
				end)
			end
		end,
		HoverText = "Attack players around you\nwithout aiming at them."
	})
	killauratargetframe = Killaura.CreateTargetWindow({})
	local sortmethods = {"Distance"}
	for i,v in pairs(killaurasortmethods) do if i ~= "Distance" then table.insert(sortmethods, i) end end
	killaurasortmethod = Killaura.CreateDropdown({
		Name = "Sort",
		Function = function() end,
		List = sortmethods
	})
	killaurarange = Killaura.CreateSlider({
		Name = "Attack range",
		Min = 1,
		Max = 18,
		Function = function(val)
			if killaurarangecirclepart then
				killaurarangecirclepart.Size = Vector3.new(val * 0.7, 0.01, val * 0.7)
			end
		end,
		Default = 18
	})
	killauraangle = Killaura.CreateSlider({
		Name = "Max angle",
		Min = 1,
		Max = 360,
		Function = function(val) end,
		Default = 360
	})
	local animmethods = {}
	for i,v in pairs(anims) do table.insert(animmethods, i) end
	killauraanimmethod = Killaura.CreateDropdown({
		Name = "Animation",
		List = animmethods,
		Function = function(val) end
	})
	local oldviewmodel
	local oldraise
	local oldeffect
	killauraautoblock = Killaura.CreateToggle({
		Name = "AutoBlock",
		Function = function(callback)
			if callback then
				oldviewmodel = bedwars.ViewmodelController.setHeldItem
				bedwars.ViewmodelController.setHeldItem = function(self, newItem, ...)
					if newItem and newItem.Name == "infernal_shield" then
						return
					end
					return oldviewmodel(self, newItem)
				end
				oldraise = bedwars.InfernalShieldController.raiseShield
				bedwars.InfernalShieldController.raiseShield = function(self)
					if os.clock() - self.lastShieldRaised < 0.4 then
						return
					end
					self.lastShieldRaised = os.clock()
					self.infernalShieldState:SendToServer({raised = true})
					self.raisedMaid:GiveTask(function()
						self.infernalShieldState:SendToServer({raised = false})
					end)
				end
				oldeffect = bedwars.InfernalShieldController.playEffect
				bedwars.InfernalShieldController.playEffect = function()
					return
				end
				if bedwars.ViewmodelController.heldItem and bedwars.ViewmodelController.heldItem.Name == "infernal_shield" then
					local sword, swordmeta = getSword()
					if sword then
						bedwars.ViewmodelController:setHeldItem(sword.tool)
					end
				end
				task.spawn(autoBlockLoop)
			else
				bedwars.ViewmodelController.setHeldItem = oldviewmodel
				bedwars.InfernalShieldController.raiseShield = oldraise
				bedwars.InfernalShieldController.playEffect = oldeffect
			end
		end,
		Default = true
	})
	killauramouse = Killaura.CreateToggle({
		Name = "Require mouse down",
		Function = function() end,
		HoverText = "Only attacks when left click is held.",
		Default = false
	})
	killauragui = Killaura.CreateToggle({
		Name = "GUI Check",
		Function = function() end,
		HoverText = "Attacks when you are not in a GUI."
	})
	killauratarget = Killaura.CreateToggle({
		Name = "Show target",
		Function = function(callback)
			if killauratargethighlight.Object then
				killauratargethighlight.Object.Visible = callback
			end
		end,
		HoverText = "Shows a red box over the opponent."
	})
	killauratargethighlight = Killaura.CreateToggle({
		Name = "Use New Highlight",
		Function = function(callback)
			for i, v in pairs(killauraboxes) do
				v:Remove()
			end
			for i = 1, 10 do
				local killaurabox
				if callback then
					killaurabox = Instance.new("Highlight")
					killaurabox.FillTransparency = 0.39
					killaurabox.FillColor = Color3.fromHSV(killauracolor.Hue, killauracolor.Sat, killauracolor.Value)
					killaurabox.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					killaurabox.OutlineTransparency = 1
					killaurabox.Parent = GuiLibrary.MainGui
				else
					killaurabox = Instance.new("BoxHandleAdornment")
					killaurabox.Transparency = 0.39
					killaurabox.Color3 = Color3.fromHSV(killauracolor.Hue, killauracolor.Sat, killauracolor.Value)
					killaurabox.Adornee = nil
					killaurabox.AlwaysOnTop = true
					killaurabox.Size = Vector3.new(3, 6, 3)
					killaurabox.ZIndex = 11
					killaurabox.Parent = GuiLibrary.MainGui
				end
				killauraboxes[i] = killaurabox
			end
		end
	})
	killauratargethighlight.Object.BorderSizePixel = 0
	killauratargethighlight.Object.BackgroundTransparency = 0
	killauratargethighlight.Object.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	killauratargethighlight.Object.Visible = false
	killauracolor = Killaura.CreateColorSlider({
		Name = "Target Color",
		Function = function(hue, sat, val)
			for i,v in pairs(killauraboxes) do
				v[(killauratargethighlight.Enabled and "FillColor" or "Color3")] = Color3.fromHSV(hue, sat, val)
			end
			if killauraaimcirclepart then
				killauraaimcirclepart.Color = Color3.fromHSV(hue, sat, val)
			end
			if killaurarangecirclepart then
				killaurarangecirclepart.Color = Color3.fromHSV(hue, sat, val)
			end
		end,
		Default = 1
	})
	for i = 1, 10 do
		local killaurabox = Instance.new("BoxHandleAdornment")
		killaurabox.Transparency = 0.5
		killaurabox.Color3 = Color3.fromHSV(killauracolor["Hue"], killauracolor["Sat"], killauracolor.Value)
		killaurabox.Adornee = nil
		killaurabox.AlwaysOnTop = true
		killaurabox.Size = Vector3.new(3, 6, 3)
		killaurabox.ZIndex = 11
		killaurabox.Parent = GuiLibrary.MainGui
		killauraboxes[i] = killaurabox
	end
	killauracframe = Killaura.CreateToggle({
		Name = "Face target",
		Function = function() end,
		HoverText = "Makes your character face the opponent."
	})
	killaurarangecircle = Killaura.CreateToggle({
		Name = "Range Visualizer",
		Function = function(callback)
			if callback then
				--context issues moment
			--[[	killaurarangecirclepart = Instance.new("MeshPart")
				killaurarangecirclepart.MeshId = "rbxassetid://3726303797"
				killaurarangecirclepart.Color = Color3.fromHSV(killauracolor["Hue"], killauracolor["Sat"], killauracolor.Value)
				killaurarangecirclepart.CanCollide = false
				killaurarangecirclepart.Anchored = true
				killaurarangecirclepart.Material = Enum.Material.Neon
				killaurarangecirclepart.Size = Vector3.new(killaurarange.Value * 0.7, 0.01, killaurarange.Value * 0.7)
				if Killaura.Enabled then
					killaurarangecirclepart.Parent = gameCamera
				end
				bedwars.QueryUtil:setQueryIgnored(killaurarangecirclepart, true)]]
			else
				if killaurarangecirclepart then
					killaurarangecirclepart:Destroy()
					killaurarangecirclepart = nil
				end
			end
		end
	})
	killauraaimcircle = Killaura.CreateToggle({
		Name = "Aim Visualizer",
		Function = function(callback)
			if callback then
				killauraaimcirclepart = Instance.new("Part")
				killauraaimcirclepart.Shape = Enum.PartType.Ball
				killauraaimcirclepart.Color = Color3.fromHSV(killauracolor["Hue"], killauracolor["Sat"], killauracolor.Value)
				killauraaimcirclepart.CanCollide = false
				killauraaimcirclepart.Anchored = true
				killauraaimcirclepart.Material = Enum.Material.Neon
				killauraaimcirclepart.Size = Vector3.new(0.5, 0.5, 0.5)
				if Killaura.Enabled then
					killauraaimcirclepart.Parent = gameCamera
				end
				bedwars.QueryUtil:setQueryIgnored(killauraaimcirclepart, true)
			else
				if killauraaimcirclepart then
					killauraaimcirclepart:Destroy()
					killauraaimcirclepart = nil
				end
			end
		end
	})
	killauraparticle = Killaura.CreateToggle({
		Name = "Crit Particle",
		Function = function(callback)
			if callback then
				killauraparticlepart = Instance.new("Part")
				killauraparticlepart.Transparency = 1
				killauraparticlepart.CanCollide = false
				killauraparticlepart.Anchored = true
				killauraparticlepart.Size = Vector3.new(3, 6, 3)
				killauraparticlepart.Parent = cam
				bedwars.QueryUtil:setQueryIgnored(killauraparticlepart, true)
				local particle = Instance.new("ParticleEmitter")
				particle.Lifetime = NumberRange.new(0.5)
				particle.Rate = 500
				particle.Speed = NumberRange.new(0)
				particle.RotSpeed = NumberRange.new(180)
				particle.Enabled = true
				particle.Size = NumberSequence.new(0.3)
				particle.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(67, 10, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 98, 255))})
				particle.Parent = killauraparticlepart
			else
				if killauraparticlepart then
					killauraparticlepart:Destroy()
					killauraparticlepart = nil
				end
			end
		end
	})
	killaurasound = Killaura.CreateToggle({
		Name = "No Swing Sound",
		Function = function() end,
		HoverText = "Removes the swinging sound."
	})
	killauraswing = Killaura.CreateToggle({
		Name = "No Swing",
		Function = function() end,
		HoverText = "Removes the swinging animation."
	})
	killaurahandcheck = Killaura.CreateToggle({
		Name = "Limit to items",
		Function = function() end,
		HoverText = "Only attacks when your sword is held."
	})
	killauraanimation = Killaura.CreateToggle({
		Name = "Custom Animation",
		Function = function(callback)
			if killauraanimationtween.Object then killauraanimationtween.Object.Visible = callback end
		end,
		HoverText = "Uses a custom animation for swinging"
	})
	killauraanimationtween = Killaura.CreateToggle({
		Name = "No Tween",
		Function = function() end,
		HoverText = "Disable's the in and out ease"
	})
	killauraanimationtween.Object.Visible = false
	killaurasync = Killaura.CreateToggle({
		Name = "Synced Animation",
		Function = function() end,
		HoverText = "Times animation with hit attempt"
	})
	killauranovape = Killaura.CreateToggle({
		Name = "No Vape",
		Function = function() end,
		HoverText = "no hit vape user"
	})
	killauranovape.Object.Visible = false
end)

local LongJump = {Enabled = false}
run(function()
	local damagetimer = 0
	local damagetimertick = 0
	local directionvec
	local LongJumpSpeed = {Value = 1.5}
	local projectileRemote = bedwars.Client:Get(bedwars.ProjectileRemote)

	local function calculatepos(vec)
		local returned = vec
		if entityLibrary.isAlive then
			local newray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, returned, store.blockRaycast)
			if newray then returned = (newray.Position - entityLibrary.character.HumanoidRootPart.Position) end
		end
		return returned
	end

	local damagemethods = {
		fireball = function(fireball, pos)
			if not LongJump.Enabled then return end
			pos = pos - (entityLibrary.character.HumanoidRootPart.CFrame.lookVector * 0.2)
			if not (getPlacedBlock(pos - Vector3.new(0, 3, 0)) or getPlacedBlock(pos - Vector3.new(0, 6, 0))) then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://4809574295"
				sound.Parent = workspace
				sound.Ended:Connect(function()
					sound:Destroy()
				end)
				sound:Play()
			end
			local origpos = pos
			local offsetshootpos = (CFrame.new(pos, pos + Vector3.new(0, -60, 0)) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).p
			local ray = workspace:Raycast(pos, Vector3.new(0, -30, 0), store.blockRaycast)
			if ray then
				pos = ray.Position
				offsetshootpos = pos
			end
			task.spawn(function()
				switchItem(fireball.tool)
				bedwars.ProjectileController:createLocalProjectile(bedwars.ProjectileMeta.fireball, "fireball", "fireball", offsetshootpos, "", Vector3.new(0, -60, 0), {drawDurationSeconds = 1})
				projectileRemote:CallServerAsync(fireball.tool, "fireball", "fireball", offsetshootpos, pos, Vector3.new(0, -60, 0), game:GetService("HttpService"):GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045)
			end)
		end,
		tnt = function(tnt, pos2)
			if not LongJump.Enabled then return end
			local pos = Vector3.new(pos2.X, getScaffold(Vector3.new(0, pos2.Y - (((entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight) - 1.5), 0)).Y, pos2.Z)
			local block = bedwars.placeBlock(pos, "tnt")
		end,
		cannon = function(tnt, pos2)
			task.spawn(function()
				local pos = Vector3.new(pos2.X, getScaffold(Vector3.new(0, pos2.Y - (((entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight) - 1.5), 0)).Y, pos2.Z)
				local block = bedwars.placeBlock(pos, "cannon")
				task.delay(0.1, function()
					local block, pos2 = getPlacedBlock(pos)
					if block and block.Name == "cannon" and (entityLibrary.character.HumanoidRootPart.CFrame.p - block.Position).Magnitude < 20 then
						switchToAndUseTool(block)
						local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
						local damage = bedwars.BlockController:calculateBlockDamage(lplr, {
							blockPosition = pos2
						})
						bedwars.Client:Get(bedwars.CannonAimRemote):SendToServer({
							cannonBlockPos = pos2,
							lookVector = vec
						})
						local broken = 0.1
						if damage < block:GetAttribute("Health") then
							task.spawn(function()
								broken = 0.4
								bedwars.breakBlock(block.Position, true, getBestBreakSide(block.Position), true, true)
							end)
						end
						task.delay(broken, function()
							for i = 1, 3 do
								local call = bedwars.Client:Get(bedwars.CannonLaunchRemote):CallServer({cannonBlockPos = bedwars.BlockController:getBlockPosition(block.Position)})
								if call then
									bedwars.breakBlock(block.Position, true, getBestBreakSide(block.Position), true, true)
									task.delay(0.1, function()
										damagetimer = LongJumpSpeed.Value * 5
										damagetimertick = tick() + 2.5
										directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
									end)
									break
								end
								task.wait(0.1)
							end
						end)
					end
				end)
			end)
		end,
		wood_dao = function(tnt, pos2)
			task.spawn(function()
				switchItem(tnt.tool)
				if not (not lplr.Character:GetAttribute("CanDashNext") or lplr.Character:GetAttribute("CanDashNext") < workspace:GetServerTimeNow()) then
					repeat task.wait() until (not lplr.Character:GetAttribute("CanDashNext") or lplr.Character:GetAttribute("CanDashNext") < workspace:GetServerTimeNow()) or not LongJump.Enabled
				end
				if LongJump.Enabled then
					local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
					replicatedStorage["events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"].useAbility:FireServer("dash", {
						direction = vec,
						origin = entityLibrary.character.HumanoidRootPart.CFrame.p,
						weapon = tnt.itemType
					})
					damagetimer = LongJumpSpeed.Value * 3.5
					damagetimertick = tick() + 2.5
					directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
				end
			end)
		end,
		jade_hammer = function(tnt, pos2)
			task.spawn(function()
				if not bedwars.AbilityController:canUseAbility("jade_hammer_jump") then
					repeat task.wait() until bedwars.AbilityController:canUseAbility("jade_hammer_jump") or not LongJump.Enabled
					task.wait(0.1)
				end
				if bedwars.AbilityController:canUseAbility("jade_hammer_jump") and LongJump.Enabled then
					bedwars.AbilityController:useAbility("jade_hammer_jump")
					local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
					damagetimer = LongJumpSpeed.Value * 2.75
					damagetimertick = tick() + 2.5
					directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
				end
			end)
		end,
		void_axe = function(tnt, pos2)
			task.spawn(function()
				if not bedwars.AbilityController:canUseAbility("void_axe_jump") then
					repeat task.wait() until bedwars.AbilityController:canUseAbility("void_axe_jump") or not LongJump.Enabled
					task.wait(0.1)
				end
				if bedwars.AbilityController:canUseAbility("void_axe_jump") and LongJump.Enabled then
					bedwars.AbilityController:useAbility("void_axe_jump")
					local vec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
					damagetimer = LongJumpSpeed.Value * 2.75
					damagetimertick = tick() + 2.5
					directionvec = Vector3.new(vec.X, 0, vec.Z).Unit
				end
			end)
		end
	}
	damagemethods.stone_dao = damagemethods.wood_dao
	damagemethods.iron_dao = damagemethods.wood_dao
	damagemethods.diamond_dao = damagemethods.wood_dao
	damagemethods.emerald_dao = damagemethods.wood_dao

	local oldgrav
	local LongJumpacprogressbarframe = Instance.new("Frame")
	LongJumpacprogressbarframe.AnchorPoint = Vector2.new(0.5, 0)
	LongJumpacprogressbarframe.Position = UDim2.new(0.5, 0, 1, -200)
	LongJumpacprogressbarframe.Size = UDim2.new(0.2, 0, 0, 20)
	LongJumpacprogressbarframe.BackgroundTransparency = 0.5
	LongJumpacprogressbarframe.BorderSizePixel = 0
	LongJumpacprogressbarframe.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
	LongJumpacprogressbarframe.Visible = LongJump.Enabled
	LongJumpacprogressbarframe.Parent = GuiLibrary.MainGui
	local LongJumpacprogressbarframe2 = LongJumpacprogressbarframe:Clone()
	LongJumpacprogressbarframe2.AnchorPoint = Vector2.new(0, 0)
	LongJumpacprogressbarframe2.Position = UDim2.new(0, 0, 0, 0)
	LongJumpacprogressbarframe2.Size = UDim2.new(1, 0, 0, 20)
	LongJumpacprogressbarframe2.BackgroundTransparency = 0
	LongJumpacprogressbarframe2.Visible = true
	LongJumpacprogressbarframe2.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
	LongJumpacprogressbarframe2.Parent = LongJumpacprogressbarframe
	local LongJumpacprogressbartext = Instance.new("TextLabel")
	LongJumpacprogressbartext.Text = "2.5s"
	LongJumpacprogressbartext.Font = Enum.Font.Gotham
	LongJumpacprogressbartext.TextStrokeTransparency = 0
	LongJumpacprogressbartext.TextColor3 =  Color3.new(0.9, 0.9, 0.9)
	LongJumpacprogressbartext.TextSize = 20
	LongJumpacprogressbartext.Size = UDim2.new(1, 0, 1, 0)
	LongJumpacprogressbartext.BackgroundTransparency = 1
	LongJumpacprogressbartext.Position = UDim2.new(0, 0, -1, 0)
	LongJumpacprogressbartext.Parent = LongJumpacprogressbarframe
	LongJump = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "LongJump",
		Function = function(callback)
			if callback then
				table.insert(LongJump.Connections, vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if damageTable.entityInstance == lplr.Character and (not damageTable.knockbackMultiplier or not damageTable.knockbackMultiplier.disabled) then
						local knockbackBoost = damageTable.knockbackMultiplier and damageTable.knockbackMultiplier.horizontal and damageTable.knockbackMultiplier.horizontal * LongJumpSpeed.Value or LongJumpSpeed.Value
						if damagetimertick < tick() or knockbackBoost >= damagetimer then
							damagetimer = knockbackBoost
							damagetimertick = tick() + 2.5
							local newDirection = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
							directionvec = Vector3.new(newDirection.X, 0, newDirection.Z).Unit
						end
					end
				end))
				task.spawn(function()
					task.spawn(function()
						repeat
							task.wait()
							if LongJumpacprogressbarframe then
								LongJumpacprogressbarframe.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
								LongJumpacprogressbarframe2.BackgroundColor3 = Color3.fromHSV(GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Hue, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Sat, GuiLibrary.ObjectsThatCanBeSaved["Gui ColorSliderColor"].Api.Value)
							end
						until (not LongJump.Enabled)
					end)
					local LongJumpOrigin = entityLibrary.isAlive and entityLibrary.character.HumanoidRootPart.Position
					local tntcheck
					for i,v in pairs(damagemethods) do
						local item = getItem(i)
						if item then
							if i == "tnt" then
								local pos = getScaffold(LongJumpOrigin)
								tntcheck = Vector3.new(pos.X, LongJumpOrigin.Y, pos.Z)
								v(item, pos)
							else
								v(item, LongJumpOrigin)
							end
							break
						end
					end
					local changecheck
					LongJumpacprogressbarframe.Visible = true
					RunLoops:BindToHeartbeat("LongJump", function(dt)
						if entityLibrary.isAlive then
							if entityLibrary.character.Humanoid.Health <= 0 then
								LongJump.ToggleButton(false)
								return
							end
							if not LongJumpOrigin then
								LongJumpOrigin = entityLibrary.character.HumanoidRootPart.Position
							end
							local newval = damagetimer ~= 0
							if changecheck ~= newval then
								if newval then
									LongJumpacprogressbarframe2:TweenSize(UDim2.new(0, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 2.5, true)
								else
									LongJumpacprogressbarframe2:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
								end
								changecheck = newval
							end
							if newval then
								local newnum = math.max(math.floor((damagetimertick - tick()) * 10) / 10, 0)
								if LongJumpacprogressbartext then
									LongJumpacprogressbartext.Text = newnum.."s"
								end
								if directionvec == nil then
									directionvec = entityLibrary.character.HumanoidRootPart.CFrame.lookVector
								end
								local longJumpCFrame = Vector3.new(directionvec.X, 0, directionvec.Z)
								local newvelo = longJumpCFrame.Unit == longJumpCFrame.Unit and longJumpCFrame.Unit * (newnum > 1 and damagetimer or 20) or Vector3.zero
								newvelo = Vector3.new(newvelo.X, 0, newvelo.Z)
								longJumpCFrame = longJumpCFrame * (getSpeed() + 3) * dt
								local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, longJumpCFrame, store.blockRaycast)
								if ray then
									longJumpCFrame = Vector3.zero
									newvelo = Vector3.zero
								end

								entityLibrary.character.HumanoidRootPart.Velocity = newvelo
								entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + longJumpCFrame
							else
								LongJumpacprogressbartext.Text = "2.5s"
								entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(LongJumpOrigin, LongJumpOrigin + entityLibrary.character.HumanoidRootPart.CFrame.lookVector)
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
								if tntcheck then
									entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(tntcheck + entityLibrary.character.HumanoidRootPart.CFrame.lookVector, tntcheck + (entityLibrary.character.HumanoidRootPart.CFrame.lookVector * 2))
								end
							end
						else
							if LongJumpacprogressbartext then
								LongJumpacprogressbartext.Text = "2.5s"
							end
							LongJumpOrigin = nil
							tntcheck = nil
						end
					end)
				end)
			else
				LongJumpacprogressbarframe.Visible = false
				RunLoops:UnbindFromHeartbeat("LongJump")
				directionvec = nil
				tntcheck = nil
				LongJumpOrigin = nil
				damagetimer = 0
				damagetimertick = 0
			end
		end,
		HoverText = "Lets you jump farther (Not landing on same level & Spamming can lead to lagbacks)"
	})
	LongJumpSpeed = LongJump.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 52,
		Function = function() end,
		Default = 52
	})
end)

run(function()
	local NoFall = {Enabled = false}
	local oldfall
	NoFall = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "NoFall",
		Function = function(callback)
			if callback then
				bedwars.Client:Get("GroundHit"):SendToServer()
			end
		end,
		HoverText = "Prevents taking fall damage."
	})
end)

run(function()
	local NoSlowdown = {Enabled = false}
	local OldSetSpeedFunc
	NoSlowdown = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "NoSlowdown",
		Function = function(callback)
			if callback then
				OldSetSpeedFunc = bedwars.SprintController.setSpeed
				bedwars.SprintController.setSpeed = function(tab1, val1)
					local hum = entityLibrary.character.Humanoid
					if hum then
						hum.WalkSpeed = math.max(20 * tab1.moveSpeedMultiplier, 20)
					end
				end
				bedwars.SprintController:setSpeed(20)
			else
				bedwars.SprintController.setSpeed = OldSetSpeedFunc
				bedwars.SprintController:setSpeed(20)
				OldSetSpeedFunc = nil
			end
		end,
		HoverText = "Prevents slowing down when using items."
	})
end)

local spiderActive = false
local holdingshift = false
run(function()
	local activatePhase = false
	local oldActivatePhase = false
	local PhaseDelay = tick()
	local Phase = {Enabled = false}
	local PhaseStudLimit = {Value = 1}
	local PhaseModifiedParts = {}
	local raycastparameters = RaycastParams.new()
	raycastparameters.RespectCanCollide = true
	raycastparameters.FilterType = Enum.RaycastFilterType.Whitelist
	local overlapparams = OverlapParams.new()
	overlapparams.RespectCanCollide = true

	local function isPointInMapOccupied(p)
		overlapparams.FilterDescendantsInstances = {lplr.Character, gameCamera}
		local possible = workspace:GetPartBoundsInBox(CFrame.new(p), Vector3.new(1, 2, 1), overlapparams)
		return (#possible == 0)
	end

	Phase = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Phase",
		Function = function(callback)
			if callback then
				RunLoops:BindToHeartbeat("Phase", function()
					if entityLibrary.isAlive and entityLibrary.character.Humanoid.MoveDirection ~= Vector3.zero and (not GuiLibrary.ObjectsThatCanBeSaved.SpiderOptionsButton.Api.Enabled or holdingshift) then
						if PhaseDelay <= tick() then
							raycastparameters.FilterDescendantsInstances = {store.blocks, collectionService:GetTagged("spawn-cage"), workspace.SpectatorPlatform}
							local PhaseRayCheck = workspace:Raycast(entityLibrary.character.Head.CFrame.p, entityLibrary.character.Humanoid.MoveDirection * 1.15, raycastparameters)
							if PhaseRayCheck then
								local PhaseDirection = (PhaseRayCheck.Normal.Z ~= 0 or not PhaseRayCheck.Instance:GetAttribute("GreedyBlock")) and "Z" or "X"
								if PhaseRayCheck.Instance.Size[PhaseDirection] <= PhaseStudLimit.Value * 3 and PhaseRayCheck.Instance.CanCollide and PhaseRayCheck.Normal.Y == 0 then
									local PhaseDestination = entityLibrary.character.HumanoidRootPart.CFrame + (PhaseRayCheck.Normal * (-(PhaseRayCheck.Instance.Size[PhaseDirection]) - (entityLibrary.character.HumanoidRootPart.Size.X / 1.5)))
									if isPointInMapOccupied(PhaseDestination.p) then
										PhaseDelay = tick() + 1
										entityLibrary.character.HumanoidRootPart.CFrame = PhaseDestination
									end
								end
							end
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("Phase")
			end
		end,
		HoverText = "Lets you Phase/Clip through walls. (Hold shift to use Phase over spider)"
	})
	PhaseStudLimit = Phase.CreateSlider({
		Name = "Blocks",
		Min = 1,
		Max = 3,
		Function = function() end
	})
end)

run(function()
	local oldCalculateAim
	local BowAimbotProjectiles = {Enabled = false}
	local BowAimbotPart = {Value = "HumanoidRootPart"}
	local BowAimbotFOV = {Value = 1000}
	local BowAimbot = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "ProjectileAimbot",
		Function = function(callback)
			if callback then
				oldCalculateAim = bedwars.ProjectileController.calculateImportantLaunchValues
				bedwars.ProjectileController.calculateImportantLaunchValues = function(self, projmeta, worldmeta, shootpospart, ...)
					local plr = EntityNearMouse(BowAimbotFOV.Value)
					if plr then
						local startPos = self:getLaunchPosition(shootpospart)
						if not startPos then
							return oldCalculateAim(self, projmeta, worldmeta, shootpospart, ...)
						end

						if (not BowAimbotProjectiles.Enabled) and projmeta.projectile:find("arrow") == nil then
							return oldCalculateAim(self, projmeta, worldmeta, shootpospart, ...)
						end

						local projmetatab = projmeta:getProjectileMeta()
						local projectilePrediction = (worldmeta and projmetatab.predictionLifetimeSec or projmetatab.lifetimeSec or 3)
						local projectileSpeed = (projmetatab.launchVelocity or 100)
						local gravity = (projmetatab.gravitationalAcceleration or 196.2)
						local projectileGravity = gravity * projmeta.gravityMultiplier
						local offsetStartPos = startPos + projmeta.fromPositionOffset
						local pos = plr.Character[BowAimbotPart.Value].Position
						local playerGravity = workspace.Gravity
						local balloons = plr.Character:GetAttribute("InflatedBalloons")

						if balloons and balloons > 0 then
							playerGravity = (workspace.Gravity * (1 - ((balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))))
						end

						if plr.Character.PrimaryPart:FindFirstChild("rbxassetid://8200754399") then
							playerGravity = (workspace.Gravity * 0.3)
						end

						local shootpos, shootvelo = predictGravity(pos, plr.Character.HumanoidRootPart.Velocity, (pos - offsetStartPos).Magnitude / projectileSpeed, plr, playerGravity)
						if projmeta.projectile == "telepearl" then
							shootpos = pos
							shootvelo = Vector3.zero
						end

						local newlook = CFrame.new(offsetStartPos, shootpos) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, 0))
						shootpos = newlook.p + (newlook.lookVector * (offsetStartPos - shootpos).magnitude)
						local calculated = LaunchDirection(offsetStartPos, shootpos, projectileSpeed, projectileGravity, false)
						oldmove = plr.Character.Humanoid.MoveDirection
						if calculated then
							return {
								initialVelocity = calculated,
								positionFrom = offsetStartPos,
								deltaT = projectilePrediction,
								gravitationalAcceleration = projectileGravity,
								drawDurationSeconds = 5
							}
						end
					end
					return oldCalculateAim(self, projmeta, worldmeta, shootpospart, ...)
				end
			else
				bedwars.ProjectileController.calculateImportantLaunchValues = oldCalculateAim
			end
		end
	})
	BowAimbotPart = BowAimbot.CreateDropdown({
		Name = "Part",
		List = {"HumanoidRootPart", "Head"},
		Function = function() end
	})
	BowAimbotFOV = BowAimbot.CreateSlider({
		Name = "FOV",
		Function = function() end,
		Min = 1,
		Max = 1000,
		Default = 1000
	})
	BowAimbotProjectiles = BowAimbot.CreateToggle({
		Name = "Other Projectiles",
		Function = function() end,
		Default = true
	})
end)

--until I find a way to make the spam switch item thing not bad I'll just get rid of it, sorry.
local Scaffold = {Enabled = false}
run(function()
	local scaffoldtext = Instance.new("TextLabel")
	scaffoldtext.Font = Enum.Font.SourceSans
	scaffoldtext.TextSize = 20
	scaffoldtext.BackgroundTransparency = 1
	scaffoldtext.TextColor3 = Color3.fromRGB(255, 0, 0)
	scaffoldtext.Size = UDim2.new(0, 0, 0, 0)
	scaffoldtext.Position = UDim2.new(0.5, 0, 0.5, 30)
	scaffoldtext.Text = "0"
	scaffoldtext.Visible = false
	scaffoldtext.Parent = GuiLibrary.MainGui
	local ScaffoldExpand = {Value = 1}
	local ScaffoldDiagonal = {Enabled = false}
	local ScaffoldTower = {Enabled = false}
	local ScaffoldDownwards = {Enabled = false}
	local ScaffoldStopMotion = {Enabled = false}
	local ScaffoldBlockCount = {Enabled = false}
	local ScaffoldHandCheck = {Enabled = false}
	local ScaffoldMouseCheck = {Enabled = false}
	local ScaffoldAnimation = {Enabled = false}
	local scaffoldstopmotionval = false
	local scaffoldposcheck = tick()
	local scaffoldstopmotionpos = Vector3.zero
	local scaffoldposchecklist = {}
	task.spawn(function()
		for x = -3, 3, 3 do
			for y = -3, 3, 3 do
				for z = -3, 3, 3 do
					if Vector3.new(x, y, z) ~= Vector3.new(0, 0, 0) then
						table.insert(scaffoldposchecklist, Vector3.new(x, y, z))
					end
				end
			end
		end
	end)

	local function checkblocks(pos)
		for i,v in pairs(scaffoldposchecklist) do
			if getPlacedBlock(pos + v) then
				return true
			end
		end
		return false
	end

	local function closestpos(block, pos)
		local startpos = block.Position - (block.Size / 2) - Vector3.new(1.5, 1.5, 1.5)
		local endpos = block.Position + (block.Size / 2) + Vector3.new(1.5, 1.5, 1.5)
		local speedCFrame = block.Position + (pos - block.Position)
		return Vector3.new(math.clamp(speedCFrame.X, startpos.X, endpos.X), math.clamp(speedCFrame.Y, startpos.Y, endpos.Y), math.clamp(speedCFrame.Z, startpos.Z, endpos.Z))
	end

	local function getclosesttop(newmag, pos)
		local closest, closestmag = pos, newmag * 3
		if entityLibrary.isAlive then
			for i,v in pairs(store.blocks) do
				local close = closestpos(v, pos)
				local mag = (close - pos).magnitude
				if mag <= closestmag then
					closest = close
					closestmag = mag
				end
			end
		end
		return closest
	end

	local oldspeed
	Scaffold = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Scaffold",
		Function = function(callback)
			if callback then
				scaffoldtext.Visible = ScaffoldBlockCount.Enabled
				if entityLibrary.isAlive then
					scaffoldstopmotionpos = entityLibrary.character.HumanoidRootPart.CFrame.p
				end
				task.spawn(function()
					repeat
						task.wait()
						if ScaffoldHandCheck.Enabled then
							if store.localHand.Type ~= "block" then continue end
						end
						if ScaffoldMouseCheck.Enabled then
							if not inputService:IsMouseButtonPressed(0) then continue end
						end
						if entityLibrary.isAlive then
							local wool, woolamount = getWool()
							if store.localHand.Type == "block" then
								wool = store.localHand.tool.Name
								woolamount = getItem(store.localHand.tool.Name).amount or 0
							elseif (not wool) then
								wool, woolamount = getBlock()
							end

							scaffoldtext.Text = (woolamount and tostring(woolamount) or "0")
							scaffoldtext.TextColor3 = woolamount and (woolamount >= 128 and Color3.fromRGB(9, 255, 198) or woolamount >= 64 and Color3.fromRGB(255, 249, 18)) or Color3.fromRGB(255, 0, 0)
							if not wool then continue end

							local towering = ScaffoldTower.Enabled and inputService:IsKeyDown(Enum.KeyCode.Space) and game:GetService("UserInputService"):GetFocusedTextBox() == nil
							if towering then
								if (not scaffoldstopmotionval) and ScaffoldStopMotion.Enabled then
									scaffoldstopmotionval = true
									scaffoldstopmotionpos = entityLibrary.character.HumanoidRootPart.CFrame.p
								end
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, 28, entityLibrary.character.HumanoidRootPart.Velocity.Z)
								if ScaffoldStopMotion.Enabled and scaffoldstopmotionval then
									entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(scaffoldstopmotionpos.X, entityLibrary.character.HumanoidRootPart.CFrame.p.Y, scaffoldstopmotionpos.Z))
								end
							else
								scaffoldstopmotionval = false
							end

							for i = 1, ScaffoldExpand.Value do
								local speedCFrame = getScaffold((entityLibrary.character.HumanoidRootPart.Position + ((scaffoldstopmotionval and Vector3.zero or entityLibrary.character.Humanoid.MoveDirection) * (i * 3.5))) + Vector3.new(0, -((entityLibrary.character.HumanoidRootPart.Size.Y / 2) + entityLibrary.character.Humanoid.HipHeight + (inputService:IsKeyDown(Enum.KeyCode.LeftShift) and ScaffoldDownwards.Enabled and 4.5 or 1.5))), 0)
								speedCFrame = Vector3.new(speedCFrame.X, speedCFrame.Y - (towering and 4 or 0), speedCFrame.Z)
								if speedCFrame ~= oldpos then
									if not checkblocks(speedCFrame) then
										local oldspeedCFrame = speedCFrame
										speedCFrame = getScaffold(getclosesttop(20, speedCFrame))
										if getPlacedBlock(speedCFrame) then speedCFrame = oldspeedCFrame end
									end
									if ScaffoldAnimation.Enabled then
										if not getPlacedBlock(speedCFrame) then
										bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
										end
									end
									task.spawn(bedwars.placeBlock, speedCFrame, wool, ScaffoldAnimation.Enabled)
									if ScaffoldExpand.Value > 1 then
										task.wait()
									end
									oldpos = speedCFrame
								end
							end
						end
					until (not Scaffold.Enabled)
				end)
			else
				scaffoldtext.Visible = false
				oldpos = Vector3.zero
				oldpos2 = Vector3.zero
			end
		end,
		HoverText = "Helps you make bridges/scaffold walk."
	})
	ScaffoldExpand = Scaffold.CreateSlider({
		Name = "Expand",
		Min = 1,
		Max = 8,
		Function = function(val) end,
		Default = 1,
		HoverText = "Build range"
	})
	ScaffoldDiagonal = Scaffold.CreateToggle({
		Name = "Diagonal",
		Function = function(callback) end,
		Default = true
	})
	ScaffoldTower = Scaffold.CreateToggle({
		Name = "Tower",
		Function = function(callback)
			if ScaffoldStopMotion.Object then
				ScaffoldTower.Object.ToggleArrow.Visible = callback
				ScaffoldStopMotion.Object.Visible = callback
			end
		end
	})
	ScaffoldMouseCheck = Scaffold.CreateToggle({
		Name = "Require mouse down",
		Function = function(callback) end,
		HoverText = "Only places when left click is held.",
	})
	ScaffoldDownwards  = Scaffold.CreateToggle({
		Name = "Downwards",
		Function = function(callback) end,
		HoverText = "Goes down when left shift is held."
	})
	ScaffoldStopMotion = Scaffold.CreateToggle({
		Name = "Stop Motion",
		Function = function() end,
		HoverText = "Stops your movement when going up"
	})
	ScaffoldStopMotion.Object.BackgroundTransparency = 0
	ScaffoldStopMotion.Object.BorderSizePixel = 0
	ScaffoldStopMotion.Object.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	ScaffoldStopMotion.Object.Visible = ScaffoldTower.Enabled
	ScaffoldBlockCount = Scaffold.CreateToggle({
		Name = "Block Count",
		Function = function(callback)
			if Scaffold.Enabled then
				scaffoldtext.Visible = callback
			end
		end,
		HoverText = "Shows the amount of blocks in the middle."
	})
	ScaffoldHandCheck = Scaffold.CreateToggle({
		Name = "Whitelist Only",
		Function = function() end,
		HoverText = "Only builds with blocks in your hand."
	})
	ScaffoldAnimation = Scaffold.CreateToggle({
		Name = "Animation",
		Function = function() end
	})
end)

local antivoidvelo
run(function()
	local Speed = {Enabled = false}
	local SpeedMode = {Value = "CFrame"}
	local SpeedValue = {Value = 1}
	local SpeedValueLarge = {Value = 1}
	local SpeedJump = {Enabled = false}
	local SpeedJumpHeight = {Value = 20}
	local SpeedJumpAlways = {Enabled = false}
	local SpeedJumpSound = {Enabled = false}
	local SpeedJumpVanilla = {Enabled = false}
	local SpeedAnimation = {Enabled = false}
	local raycastparameters = RaycastParams.new()

	local alternatelist = {"Normal", "AntiCheat A", "AntiCheat B"}
	Speed = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Speed",
		Function = function(callback)
			if callback then
				RunLoops:BindToHeartbeat("Speed", function(delta)
					if GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled then
						if store.matchState == 0 then return end
					end
					if entityLibrary.isAlive then
						if not (isnetworkowner(entityLibrary.character.HumanoidRootPart) and entityLibrary.character.Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing and (not spiderActive) and (not GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled) and (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled)) then return end
						if GuiLibrary.ObjectsThatCanBeSaved.GrappleExploitOptionsButton and GuiLibrary.ObjectsThatCanBeSaved.GrappleExploitOptionsButton.Api.Enabled then return end
						if LongJump.Enabled then return end
						if SpeedAnimation.Enabled then
							for i, v in pairs(entityLibrary.character.Humanoid:GetPlayingAnimationTracks()) do
								if v.Name == "WalkAnim" or v.Name == "RunAnim" then
									v:AdjustSpeed(entityLibrary.character.Humanoid.WalkSpeed / 16)
								end
							end
						end

						local speedValue = SpeedValue.Value + getSpeed()
						local speedVelocity = entityLibrary.character.Humanoid.MoveDirection * (SpeedMode.Value == "Normal" and SpeedValue.Value or 20)
						entityLibrary.character.HumanoidRootPart.Velocity = antivoidvelo or Vector3.new(speedVelocity.X, entityLibrary.character.HumanoidRootPart.Velocity.Y, speedVelocity.Z)
						if SpeedMode.Value ~= "Normal" then
							local speedCFrame = entityLibrary.character.Humanoid.MoveDirection * (speedValue - 20) * delta
							raycastparameters.FilterDescendantsInstances = {lplr.Character}
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, speedCFrame, raycastparameters)
							if ray then speedCFrame = (ray.Position - entityLibrary.character.HumanoidRootPart.Position) end
							entityLibrary.character.HumanoidRootPart.CFrame = entityLibrary.character.HumanoidRootPart.CFrame + speedCFrame
						end

						if SpeedJump.Enabled and (not Scaffold.Enabled) and (SpeedJumpAlways.Enabled or killauraNearPlayer) then
							if (entityLibrary.character.Humanoid.FloorMaterial ~= Enum.Material.Air) and entityLibrary.character.Humanoid.MoveDirection ~= Vector3.zero then
								if SpeedJumpSound.Enabled then
									pcall(function() entityLibrary.character.HumanoidRootPart.Jumping:Play() end)
								end
								if SpeedJumpVanilla.Enabled then
									entityLibrary.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								else
									entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, SpeedJumpHeight.Value, entityLibrary.character.HumanoidRootPart.Velocity.Z)
								end
							end
						end
					end
				end)
			else
				RunLoops:UnbindFromHeartbeat("Speed")
			end
		end,
		HoverText = "Increases your movement.",
		ExtraText = function()
			return "Heatseeker"
		end
	})
	SpeedValue = Speed.CreateSlider({
		Name = "Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	SpeedValueLarge = Speed.CreateSlider({
		Name = "Big Mode Speed",
		Min = 1,
		Max = 23,
		Function = function(val) end,
		Default = 23
	})
	SpeedJump = Speed.CreateToggle({
		Name = "AutoJump",
		Function = function(callback)
			if SpeedJumpHeight.Object then SpeedJumpHeight.Object.Visible = callback end
			if SpeedJumpAlways.Object then
				SpeedJump.Object.ToggleArrow.Visible = callback
				SpeedJumpAlways.Object.Visible = callback
			end
			if SpeedJumpSound.Object then SpeedJumpSound.Object.Visible = callback end
			if SpeedJumpVanilla.Object then SpeedJumpVanilla.Object.Visible = callback end
		end,
		Default = true
	})
	SpeedJumpHeight = Speed.CreateSlider({
		Name = "Jump Height",
		Min = 0,
		Max = 30,
		Default = 25,
		Function = function() end
	})
	SpeedJumpAlways = Speed.CreateToggle({
		Name = "Always Jump",
		Function = function() end
	})
	SpeedJumpSound = Speed.CreateToggle({
		Name = "Jump Sound",
		Function = function() end
	})
	SpeedJumpVanilla = Speed.CreateToggle({
		Name = "Real Jump",
		Function = function() end
	})
	SpeedAnimation = Speed.CreateToggle({
		Name = "Slowdown Anim",
		Function = function() end
	})
end)

run(function()
	local function roundpos(dir, pos, size)
		local suc, res = pcall(function() return Vector3.new(math.clamp(dir.X, pos.X - (size.X / 2), pos.X + (size.X / 2)), math.clamp(dir.Y, pos.Y - (size.Y / 2), pos.Y + (size.Y / 2)), math.clamp(dir.Z, pos.Z - (size.Z / 2), pos.Z + (size.Z / 2))) end)
		return suc and res or Vector3.zero
	end

	local Spider = {Enabled = false}
	local SpiderSpeed = {Value = 0}
	local SpiderMode = {Value = "Normal"}
	local SpiderPart
	Spider = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Spider",
		Function = function(callback)
			if callback then
				table.insert(Spider.Connections, inputService.InputBegan:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.LeftShift then
						holdingshift = true
					end
				end))
				table.insert(Spider.Connections, inputService.InputEnded:Connect(function(input1)
					if input1.KeyCode == Enum.KeyCode.LeftShift then
						holdingshift = false
					end
				end))
				RunLoops:BindToHeartbeat("Spider", function()
					if entityLibrary.isAlive and (GuiLibrary.ObjectsThatCanBeSaved.PhaseOptionsButton.Api.Enabled == false or holdingshift == false) then
						if SpiderMode.Value == "Normal" then
							local vec = entityLibrary.character.Humanoid.MoveDirection * 2
							local newray = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + (vec + Vector3.new(0, 0.1, 0)))
							local newray2 = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + (vec - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight, 0)))
							if newray and (not newray.CanCollide) then newray = nil end
							if newray2 and (not newray2.CanCollide) then newray2 = nil end
							if spiderActive and (not newray) and (not newray2) then
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, 0, entityLibrary.character.HumanoidRootPart.Velocity.Z)
							end
							spiderActive = ((newray or newray2) and true or false)
							if (newray or newray2) then
								entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(newray2 and newray == nil and entityLibrary.character.HumanoidRootPart.Velocity.X or 0, SpiderSpeed.Value, newray2 and newray == nil and entityLibrary.character.HumanoidRootPart.Velocity.Z or 0)
							end
						else
							if not SpiderPart then
								SpiderPart = Instance.new("TrussPart")
								SpiderPart.Size = Vector3.new(2, 2, 2)
								SpiderPart.Transparency = 1
								SpiderPart.Anchored = true
								SpiderPart.Parent = gameCamera
							end
							local newray2, newray2pos = getPlacedBlock(entityLibrary.character.HumanoidRootPart.Position + ((entityLibrary.character.HumanoidRootPart.CFrame.lookVector * 1.5) - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight, 0)))
							if newray2 and (not newray2.CanCollide) then newray2 = nil end
							spiderActive = (newray2 and true or false)
							if newray2 then
								newray2pos = newray2pos * 3
								local newpos = roundpos(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(newray2pos.X, math.min(entityLibrary.character.HumanoidRootPart.Position.Y, newray2pos.Y), newray2pos.Z), Vector3.new(1.1, 1.1, 1.1))
								SpiderPart.Position = newpos
							else
								SpiderPart.Position = Vector3.zero
							end
						end
					end
				end)
			else
				if SpiderPart then SpiderPart:Destroy() end
				RunLoops:UnbindFromHeartbeat("Spider")
				holdingshift = false
			end
		end,
		HoverText = "Lets you climb up walls"
	})
	SpiderMode = Spider.CreateDropdown({
		Name = "Mode",
		List = {"Normal", "Classic"},
		Function = function()
			if SpiderPart then SpiderPart:Destroy() end
		end
	})
	SpiderSpeed = Spider.CreateSlider({
		Name = "Speed",
		Min = 0,
		Max = 40,
		Function = function() end,
		Default = 40
	})
end)

run(function()
	local TargetStrafe = {Enabled = false}
	local TargetStrafeRange = {Value = 18}
	local oldmove
	local controlmodule
	local block
	TargetStrafe = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "TargetStrafe",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if not controlmodule then
						local suc = pcall(function() controlmodule = require(lplr.PlayerScripts.PlayerModule).controls end)
						if not suc then controlmodule = {} end
					end
					oldmove = controlmodule.moveFunction
					local ang = 0
					local oldplr
					block = Instance.new("Part")
					block.Anchored = true
					block.CanCollide = false
					block.Parent = gameCamera
					controlmodule.moveFunction = function(Self, vec, facecam, ...)
						if entityLibrary.isAlive then
							local plr = AllNearPosition(TargetStrafeRange.Value + 5, 10)[1]
							plr = plr and (not workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, (plr.RootPart.Position - entityLibrary.character.HumanoidRootPart.Position), store.blockRaycast)) and workspace:Raycast(plr.RootPart.Position, Vector3.new(0, -70, 0), store.blockRaycast) and plr or nil
							if plr ~= oldplr then
								if plr then
									local x, y, z = CFrame.new(plr.RootPart.Position, entityLibrary.character.HumanoidRootPart.Position):ToEulerAnglesXYZ()
									ang = math.deg(z)
								end
								oldplr = plr
							end
							if plr then
								facecam = false
								local localPos = CFrame.new(plr.RootPart.Position)
								local ray = workspace:Blockcast(localPos, Vector3.new(3, 3, 3), CFrame.Angles(0, math.rad(ang), 0).lookVector * TargetStrafeRange.Value, store.blockRaycast)
								local newPos = localPos + (CFrame.Angles(0, math.rad(ang), 0).lookVector * (ray and ray.Distance - 1 or TargetStrafeRange.Value))
								local factor = getSpeed() > 0 and 6 or 4
								if not workspace:Raycast(newPos.p, Vector3.new(0, -70, 0), store.blockRaycast) then
									newPos = localPos
									factor = 40
								end
								if ((entityLibrary.character.HumanoidRootPart.Position * Vector3.new(1, 0, 1)) - (newPos.p * Vector3.new(1, 0, 1))).Magnitude < 4 or ray then
									ang = ang + factor % 360
								end
								block.Position = newPos.p
								vec = (newPos.p - entityLibrary.character.HumanoidRootPart.Position) * Vector3.new(1, 0, 1)
							end
						end
						return oldmove(Self, vec, facecam, ...)
					end
				end)
			else
				block:Destroy()
				controlmodule.moveFunction = oldmove
			end
		end
	})
	TargetStrafeRange = TargetStrafe.CreateSlider({
		Name = "Range",
		Min = 0,
		Max = 18,
		Function = function() end
	})
end)

run(function()
	local BedESP = {Enabled = false}
	local BedESPFolder = Instance.new("Folder")
	BedESPFolder.Name = "BedESPFolder"
	BedESPFolder.Parent = GuiLibrary.MainGui
	local BedESPTable = {}
	local BedESPColor = {Value = 0.44}
	local BedESPTransparency = {Value = 1}
	local BedESPOnTop = {Enabled = true}
	BedESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "BedESP",
		Function = function(callback)
			if callback then
				table.insert(BedESP.Connections, collectionService:GetInstanceAddedSignal("bed"):Connect(function(bed)
					task.wait(0.2)
					if not BedESP.Enabled then return end
					local BedFolder = Instance.new("Folder")
					BedFolder.Parent = BedESPFolder
					BedESPTable[bed] = BedFolder
					for bedespnumber, bedesppart in pairs(bed:GetChildren()) do
						if bedesppart.Name ~= 'Bed' then continue end
						local boxhandle = Instance.new("BoxHandleAdornment")
						boxhandle.Size = bedesppart.Size + Vector3.new(.01, .01, .01)
						boxhandle.AlwaysOnTop = true
						boxhandle.ZIndex = (bedesppart.Name == "Covers" and 10 or 0)
						boxhandle.Visible = true
						boxhandle.Adornee = bedesppart
						boxhandle.Color3 = bedesppart.Color
						boxhandle.Name = bedespnumber
						boxhandle.Parent = BedFolder
					end
				end))
				table.insert(BedESP.Connections, collectionService:GetInstanceRemovedSignal("bed"):Connect(function(bed)
					if BedESPTable[bed] then
						BedESPTable[bed]:Destroy()
						BedESPTable[bed] = nil
					end
				end))
				for i, bed in pairs(collectionService:GetTagged("bed")) do
					local BedFolder = Instance.new("Folder")
					BedFolder.Parent = BedESPFolder
					BedESPTable[bed] = BedFolder
					for bedespnumber, bedesppart in pairs(bed:GetChildren()) do
						if bedesppart:IsA("BasePart") then
							local boxhandle = Instance.new("BoxHandleAdornment")
							boxhandle.Size = bedesppart.Size + Vector3.new(.01, .01, .01)
							boxhandle.AlwaysOnTop = true
							boxhandle.ZIndex = (bedesppart.Name == "Covers" and 10 or 0)
							boxhandle.Visible = true
							boxhandle.Adornee = bedesppart
							boxhandle.Color3 = bedesppart.Color
							boxhandle.Parent = BedFolder
						end
					end
				end
			else
				BedESPFolder:ClearAllChildren()
				table.clear(BedESPTable)
			end
		end,
		HoverText = "Render Beds through walls"
	})
end)

run(function()
	local function getallblocks2(pos, normal)
		local blocks = {}
		local lastfound = nil
		for i = 1, 20 do
			local blockpos = (pos + (Vector3.FromNormalId(normal) * (i * 3)))
			local extrablock = getPlacedBlock(blockpos)
			local covered = true
			if extrablock and extrablock.Parent ~= nil then
				if bedwars.BlockController:isBlockBreakable({blockPosition = blockpos}, lplr) then
					table.insert(blocks, extrablock:GetAttribute("NoBreak") and "unbreakable" or extrablock.Name)
				else
					table.insert(blocks, "unbreakable")
					break
				end
				lastfound = extrablock
				if covered == false then
					break
				end
			else
				break
			end
		end
		return blocks
	end

	local function getallbedblocks(pos)
		local blocks = {}
		for i,v in pairs(cachedNormalSides) do
			for i2,v2 in pairs(getallblocks2(pos, v)) do
				if table.find(blocks, v2) == nil and v2 ~= "bed" then
					table.insert(blocks, v2)
				end
			end
			for i2,v2 in pairs(getallblocks2(pos + Vector3.new(0, 0, 3), v)) do
				if table.find(blocks, v2) == nil and v2 ~= "bed" then
					table.insert(blocks, v2)
				end
			end
		end
		return blocks
	end

	local function refreshAdornee(v)
		local bedblocks = getallbedblocks(v.Adornee.Position)
		for i2,v2 in pairs(v.Frame:GetChildren()) do
			if v2:IsA("ImageLabel") then
				v2:Remove()
			end
		end
		for i3,v3 in pairs(bedblocks) do
			local blockimage = Instance.new("ImageLabel")
			blockimage.Size = UDim2.new(0, 32, 0, 32)
			blockimage.BackgroundTransparency = 1
			blockimage.Image = bedwars.getIcon({itemType = v3}, true)
			blockimage.Parent = v.Frame
		end
	end

	local BedPlatesFolder = Instance.new("Folder")
	BedPlatesFolder.Name = "BedPlatesFolder"
	BedPlatesFolder.Parent = GuiLibrary.MainGui
	local BedPlatesTable = {}
	local BedPlates = {Enabled = false}

	local function addBed(v)
		local billboard = Instance.new("BillboardGui")
		billboard.Parent = BedPlatesFolder
		billboard.Name = "bed"
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
		billboard.Size = UDim2.new(0, 42, 0, 42)
		billboard.AlwaysOnTop = true
		billboard.Adornee = v
		BedPlatesTable[v] = billboard
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 0.5
		frame.Parent = billboard
		local uilistlayout = Instance.new("UIListLayout")
		uilistlayout.FillDirection = Enum.FillDirection.Horizontal
		uilistlayout.Padding = UDim.new(0, 4)
		uilistlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		uilistlayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			billboard.Size = UDim2.new(0, math.max(uilistlayout.AbsoluteContentSize.X + 12, 42), 0, 42)
		end)
		uilistlayout.Parent = frame
		local uicorner = Instance.new("UICorner")
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = frame
		refreshAdornee(billboard)
	end

	BedPlates = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "BedPlates",
		Function = function(callback)
			if callback then
				table.insert(BedPlates.Connections, vapeEvents.PlaceBlockEvent.Event:Connect(function(p5)
					for i, v in pairs(BedPlatesFolder:GetChildren()) do
						if v.Adornee then
							if ((p5.blockRef.blockPosition * 3) - v.Adornee.Position).magnitude <= 20 then
								refreshAdornee(v)
							end
						end
					end
				end))
				table.insert(BedPlates.Connections, vapeEvents.BreakBlockEvent.Event:Connect(function(p5)
					for i, v in pairs(BedPlatesFolder:GetChildren()) do
						if v.Adornee then
							if ((p5.blockRef.blockPosition * 3) - v.Adornee.Position).magnitude <= 20 then
								refreshAdornee(v)
							end
						end
					end
				end))
				table.insert(BedPlates.Connections, collectionService:GetInstanceAddedSignal("bed"):Connect(function(v)
					addBed(v)
				end))
				table.insert(BedPlates.Connections, collectionService:GetInstanceRemovedSignal("bed"):Connect(function(v)
					if BedPlatesTable[v] then
						BedPlatesTable[v]:Destroy()
						BedPlatesTable[v] = nil
					end
				end))
				for i, v in pairs(collectionService:GetTagged("bed")) do
					addBed(v)
				end
			else
				BedPlatesFolder:ClearAllChildren()
			end
		end
	})
end)

run(function()
	local ChestESPList = {ObjectList = {}, RefreshList = function() end}
	local function nearchestitem(item)
		for i,v in pairs(ChestESPList.ObjectList) do
			if item:find(v) then return v end
		end
	end
	local function refreshAdornee(v)
		local chest = v:FindFirstChild("ChestFolderValue")
		chest = chest and chest.Value or nil
		if not chest then return end
		local chestitems = chest and chest:GetChildren() or {}
		for i2,v2 in pairs(v.Frame:GetChildren()) do
			if v2:IsA("ImageLabel") then
				v2:Remove()
			end
		end
		v.Enabled = false
		local alreadygot = {}
		for itemNumber, item in pairs(chestitems) do
			if alreadygot[item.Name] == nil and (table.find(ChestESPList.ObjectList, item.Name) or nearchestitem(item.Name)) then
				alreadygot[item.Name] = true
				v.Enabled = true
				local blockimage = Instance.new("ImageLabel")
				blockimage.Size = UDim2.new(0, 32, 0, 32)
				blockimage.BackgroundTransparency = 1
				blockimage.Image = bedwars.getIcon({itemType = item.Name}, true)
				blockimage.Parent = v.Frame
			end
		end
	end

	local ChestESPFolder = Instance.new("Folder")
	ChestESPFolder.Name = "ChestESPFolder"
	ChestESPFolder.Parent = GuiLibrary.MainGui
	local ChestESP = {Enabled = false}
	local ChestESPBackground = {Enabled = true}

	local function chestfunc(v)
		task.spawn(function()
			local chest = v:FindFirstChild("ChestFolderValue")
			chest = chest and chest.Value or nil
			if not chest then return end
			local billboard = Instance.new("BillboardGui")
			billboard.Parent = ChestESPFolder
			billboard.Name = "chest"
			billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
			billboard.Size = UDim2.new(0, 42, 0, 42)
			billboard.AlwaysOnTop = true
			billboard.Adornee = v
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundColor3 = Color3.new(0, 0, 0)
			frame.BackgroundTransparency = ChestESPBackground.Enabled and 0.5 or 1
			frame.Parent = billboard
			local uilistlayout = Instance.new("UIListLayout")
			uilistlayout.FillDirection = Enum.FillDirection.Horizontal
			uilistlayout.Padding = UDim.new(0, 4)
			uilistlayout.VerticalAlignment = Enum.VerticalAlignment.Center
			uilistlayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			uilistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				billboard.Size = UDim2.new(0, math.max(uilistlayout.AbsoluteContentSize.X + 12, 42), 0, 42)
			end)
			uilistlayout.Parent = frame
			local uicorner = Instance.new("UICorner")
			uicorner.CornerRadius = UDim.new(0, 4)
			uicorner.Parent = frame
			if chest then
				table.insert(ChestESP.Connections, chest.ChildAdded:Connect(function(item)
					if table.find(ChestESPList.ObjectList, item.Name) or nearchestitem(item.Name) then
						refreshAdornee(billboard)
					end
				end))
				table.insert(ChestESP.Connections, chest.ChildRemoved:Connect(function(item)
					if table.find(ChestESPList.ObjectList, item.Name) or nearchestitem(item.Name) then
						refreshAdornee(billboard)
					end
				end))
				refreshAdornee(billboard)
			end
		end)
	end

	ChestESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "ChestESP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					table.insert(ChestESP.Connections, collectionService:GetInstanceAddedSignal("chest"):Connect(chestfunc))
					for i,v in pairs(collectionService:GetTagged("chest")) do chestfunc(v) end
				end)
			else
				ChestESPFolder:ClearAllChildren()
			end
		end
	})
	ChestESPList = ChestESP.CreateTextList({
		Name = "ItemList",
		TempText = "item or part of item",
		AddFunction = function()
			if ChestESP.Enabled then
				ChestESP.ToggleButton(false)
				ChestESP.ToggleButton(false)
			end
		end,
		RemoveFunction = function()
			if ChestESP.Enabled then
				ChestESP.ToggleButton(false)
				ChestESP.ToggleButton(false)
			end
		end
	})
	ChestESPBackground = ChestESP.CreateToggle({
		Name = "Background",
		Function = function()
			if ChestESP.Enabled then
				ChestESP.ToggleButton(false)
				ChestESP.ToggleButton(false)
			end
		end,
		Default = true
	})
end)

run(function()
	local FieldOfViewValue = {Value = 70}
	local oldfov
	local oldfov2
	local FieldOfView = {Enabled = false}
	local FieldOfViewZoom = {Enabled = false}
	FieldOfView = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "FOVChanger",
		Function = function(callback)
			if callback then
				if FieldOfViewZoom.Enabled then
					task.spawn(function()
						repeat
							task.wait()
						until not inputService:IsKeyDown(Enum.KeyCode[FieldOfView.Keybind ~= "" and FieldOfView.Keybind or "C"])
						if FieldOfView.Enabled then
							FieldOfView.ToggleButton(false)
						end
					end)
				end
				oldfov = bedwars.FovController.setFOV
				oldfov2 = bedwars.FovController.getFOV
				bedwars.FovController.setFOV = function(self, fov) return oldfov(self, FieldOfViewValue.Value) end
				bedwars.FovController.getFOV = function(self, fov) return FieldOfViewValue.Value end
			else
				bedwars.FovController.setFOV = oldfov
				bedwars.FovController.getFOV = oldfov2
			end
			bedwars.FovController:setFOV(bedwars.ClientStoreHandler:getState().Settings.fov)
		end
	})
	FieldOfViewValue = FieldOfView.CreateSlider({
		Name = "FOV",
		Min = 30,
		Max = 120,
		Function = function(val)
			if FieldOfView.Enabled then
				bedwars.FovController:setFOV(bedwars.ClientStoreHandler:getState().Settings.fov)
			end
		end
	})
	FieldOfViewZoom = FieldOfView.CreateToggle({
		Name = "Zoom",
		Function = function() end,
		HoverText = "optifine zoom lol"
	})
end)

run(function()
	local old
	local old2
	local oldhitpart
	local FPSBoost = {Enabled = false}
	local removetextures = {Enabled = false}
	local removetexturessmooth = {Enabled = false}
	local fpsboostdamageindicator = {Enabled = false}
	local fpsboostdamageeffect = {Enabled = false}
	local fpsboostkilleffect = {Enabled = false}
	local originaltextures = {}
	local originaleffects = {}

	local function fpsboosttextures()
		task.spawn(function()
			repeat task.wait() until store.matchState ~= 0
			for i,v in pairs(store.blocks) do
				if v:GetAttribute("PlacedByUserId") == 0 then
					v.Material = FPSBoost.Enabled and removetextures.Enabled and Enum.Material.SmoothPlastic or (v.Name:find("glass") and Enum.Material.SmoothPlastic or Enum.Material.Fabric)
					originaltextures[v] = originaltextures[v] or v.MaterialVariant
					v.MaterialVariant = FPSBoost.Enabled and removetextures.Enabled and "" or originaltextures[v]
					for i2,v2 in pairs(v:GetChildren()) do
						pcall(function()
							v2.Material = FPSBoost.Enabled and removetextures.Enabled and Enum.Material.SmoothPlastic or (v.Name:find("glass") and Enum.Material.SmoothPlastic or Enum.Material.Fabric)
							originaltextures[v2] = originaltextures[v2] or v2.MaterialVariant
							v2.MaterialVariant = FPSBoost.Enabled and removetextures.Enabled and "" or originaltextures[v2]
						end)
					end
				end
			end
		end)
	end

	FPSBoost = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "FPSBoost",
		Function = function(callback)
			local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
			if callback then
				wasenabled = true
				fpsboosttextures()
				if fpsboostdamageindicator.Enabled then
					damagetab.strokeThickness = 0
					damagetab.textSize = 0
					damagetab.blowUpDuration = 0
					damagetab.blowUpSize = 0
				end
				if fpsboostkilleffect.Enabled then
					for i,v in pairs(bedwars.KillEffectController.killEffects) do
						originaleffects[i] = v
						bedwars.KillEffectController.killEffects[i] = {new = function(char) return {onKill = function() end, isPlayDefaultKillEffect = function() return char == lplr.Character end} end}
					end
				end
				if fpsboostdamageeffect.Enabled then
					oldhitpart = bedwars.DamageIndicatorController.hitEffectPart
					bedwars.DamageIndicatorController.hitEffectPart = nil
				end
				old = bedwars.EntityHighlightController.highlight
				old2 = getmetatable(bedwars.StopwatchController).tweenOutGhost
				local highlighttable = {}
				getmetatable(bedwars.StopwatchController).tweenOutGhost = function(p17, p18)
					p18:Destroy()
				end
				bedwars.EntityHighlightController.highlight = function() end
			else
				for i,v in pairs(originaleffects) do
					bedwars.KillEffectController.killEffects[i] = v
				end
				fpsboosttextures()
				if oldhitpart then
					bedwars.DamageIndicatorController.hitEffectPart = oldhitpart
				end
				debug.setupvalue(bedwars.KillEffectController.KnitStart, 2, require(lplr.PlayerScripts.TS["client-sync-events"]).ClientSyncEvents)
				damagetab.strokeThickness = 1.5
				damagetab.textSize = 28
				damagetab.blowUpDuration = 0.125
				damagetab.blowUpSize = 76
				debug.setupvalue(bedwars.DamageIndicator, 10, tweenService)
				if bedwars.DamageIndicatorController.hitEffectPart then
					bedwars.DamageIndicatorController.hitEffectPart.Attachment.Cubes.Enabled = true
					bedwars.DamageIndicatorController.hitEffectPart.Attachment.Shards.Enabled = true
				end
				bedwars.EntityHighlightController.highlight = old
				getmetatable(bedwars.StopwatchController).tweenOutGhost = old2
				old = nil
				old2 = nil
			end
		end
	})
	removetextures = FPSBoost.CreateToggle({
		Name = "Remove Textures",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
	fpsboostdamageindicator = FPSBoost.CreateToggle({
		Name = "Remove Damage Indicator",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
	fpsboostdamageeffect = FPSBoost.CreateToggle({
		Name = "Remove Damage Effect",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
	fpsboostkilleffect = FPSBoost.CreateToggle({
		Name = "Remove Kill Effect",
		Function = function(callback) if FPSBoost.Enabled then FPSBoost.ToggleButton(false) FPSBoost.ToggleButton(false) end end
	})
end)

run(function()
	local GameFixer = {Enabled = false}
	local GameFixerHit = {Enabled = false}
	GameFixer = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "GameFixer",
		Function = function(callback)
			debug.setconstant(bedwars.SwordController.swingSwordAtMouse, 23, callback and 'raycast' or 'Raycast')
			debug.setupvalue(bedwars.SwordController.swingSwordAtMouse, 4, callback and bedwars.QueryUtil or workspace)
		end,
		HoverText = "Fixes game bugs"
	})
end)

run(function()
	local transformed = false
	local GameTheme = {Enabled = false}
	local GameThemeMode = {Value = "GameTheme"}

	local themefunctions = {
		Old = function()
			task.spawn(function()
				local oldbedwarstabofimages = '{"clay_orange":"rbxassetid://7017703219","iron":"rbxassetid://6850537969","glass":"rbxassetid://6909521321","log_spruce":"rbxassetid://6874161124","ice":"rbxassetid://6874651262","marble":"rbxassetid://6594536339","zipline_base":"rbxassetid://7051148904","iron_helmet":"rbxassetid://6874272559","marble_pillar":"rbxassetid://6909323822","clay_dark_green":"rbxassetid://6763635916","wood_plank_birch":"rbxassetid://6768647328","watering_can":"rbxassetid://6915423754","emerald_helmet":"rbxassetid://6931675766","pie":"rbxassetid://6985761399","wood_plank_spruce":"rbxassetid://6768615964","diamond_chestplate":"rbxassetid://6874272898","wool_pink":"rbxassetid://6910479863","wool_blue":"rbxassetid://6910480234","wood_plank_oak":"rbxassetid://6910418127","diamond_boots":"rbxassetid://6874272964","clay_yellow":"rbxassetid://4991097283","tnt":"rbxassetid://6856168996","lasso":"rbxassetid://7192710930","clay_purple":"rbxassetid://6856099740","melon_seeds":"rbxassetid://6956387796","apple":"rbxassetid://6985765179","carrot_seeds":"rbxassetid://6956387835","log_oak":"rbxassetid://6763678414","emerald_chestplate":"rbxassetid://6931675868","wool_yellow":"rbxassetid://6910479606","emerald_boots":"rbxassetid://6931675942","clay_light_brown":"rbxassetid://6874651634","balloon":"rbxassetid://7122143895","cannon":"rbxassetid://7121221753","leather_boots":"rbxassetid://6855466456","melon":"rbxassetid://6915428682","wool_white":"rbxassetid://6910387332","log_birch":"rbxassetid://6763678414","clay_pink":"rbxassetid://6856283410","grass":"rbxassetid://6773447725","obsidian":"rbxassetid://6910443317","shield":"rbxassetid://7051149149","red_sandstone":"rbxassetid://6708703895","diamond_helmet":"rbxassetid://6874272793","wool_orange":"rbxassetid://6910479956","log_hickory":"rbxassetid://7017706899","guitar":"rbxassetid://7085044606","wool_purple":"rbxassetid://6910479777","diamond":"rbxassetid://6850538161","iron_chestplate":"rbxassetid://6874272631","slime_block":"rbxassetid://6869284566","stone_brick":"rbxassetid://6910394475","hammer":"rbxassetid://6955848801","ceramic":"rbxassetid://6910426690","wood_plank_maple":"rbxassetid://6768632085","leather_helmet":"rbxassetid://6855466216","stone":"rbxassetid://6763635916","slate_brick":"rbxassetid://6708836267","sandstone":"rbxassetid://6708657090","snow":"rbxassetid://6874651192","wool_red":"rbxassetid://6910479695","leather_chestplate":"rbxassetid://6876833204","clay_red":"rbxassetid://6856283323","wool_green":"rbxassetid://6910480050","clay_white":"rbxassetid://7017705325","wool_cyan":"rbxassetid://6910480152","clay_black":"rbxassetid://5890435474","sand":"rbxassetid://6187018940","clay_light_green":"rbxassetid://6856099550","clay_dark_brown":"rbxassetid://6874651325","carrot":"rbxassetid://3677675280","clay":"rbxassetid://6856190168","iron_boots":"rbxassetid://6874272718","emerald":"rbxassetid://6850538075","zipline":"rbxassetid://7051148904"}'
				local oldbedwarsicontab = game:GetService("HttpService"):JSONDecode(oldbedwarstabofimages)
				local oldbedwarssoundtable = {
					["QUEUE_JOIN"] = "rbxassetid://6691735519",
					["QUEUE_MATCH_FOUND"] = "rbxassetid://6768247187",
					["UI_CLICK"] = "rbxassetid://6732690176",
					["UI_OPEN"] = "rbxassetid://6732607930",
					["BEDWARS_UPGRADE_SUCCESS"] = "rbxassetid://6760677364",
					["BEDWARS_PURCHASE_ITEM"] = "rbxassetid://6760677364",
					["SWORD_SWING_1"] = "rbxassetid://6760544639",
					["SWORD_SWING_2"] = "rbxassetid://6760544595",
					["DAMAGE_1"] = "rbxassetid://6765457325",
					["DAMAGE_2"] = "rbxassetid://6765470975",
					["DAMAGE_3"] = "rbxassetid://6765470941",
					["CROP_HARVEST"] = "rbxassetid://4864122196",
					["CROP_PLANT_1"] = "rbxassetid://5483943277",
					["CROP_PLANT_2"] = "rbxassetid://5483943479",
					["CROP_PLANT_3"] = "rbxassetid://5483943723",
					["ARMOR_EQUIP"] = "rbxassetid://6760627839",
					["ARMOR_UNEQUIP"] = "rbxassetid://6760625788",
					["PICKUP_ITEM_DROP"] = "rbxassetid://6768578304",
					["PARTY_INCOMING_INVITE"] = "rbxassetid://6732495464",
					["ERROR_NOTIFICATION"] = "rbxassetid://6732495464",
					["INFO_NOTIFICATION"] = "rbxassetid://6732495464",
					["END_GAME"] = "rbxassetid://6246476959",
					["GENERIC_BLOCK_PLACE"] = "rbxassetid://4842910664",
					["GENERIC_BLOCK_BREAK"] = "rbxassetid://4819966893",
					["GRASS_BREAK"] = "rbxassetid://5282847153",
					["WOOD_BREAK"] = "rbxassetid://4819966893",
					["STONE_BREAK"] = "rbxassetid://6328287211",
					["WOOL_BREAK"] = "rbxassetid://4842910664",
					["TNT_EXPLODE_1"] = "rbxassetid://7192313632",
					["TNT_HISS_1"] = "rbxassetid://7192313423",
					["FIREBALL_EXPLODE"] = "rbxassetid://6855723746",
					["SLIME_BLOCK_BOUNCE"] = "rbxassetid://6857999096",
					["SLIME_BLOCK_BREAK"] = "rbxassetid://6857999170",
					["SLIME_BLOCK_HIT"] = "rbxassetid://6857999148",
					["SLIME_BLOCK_PLACE"] = "rbxassetid://6857999119",
					["BOW_DRAW"] = "rbxassetid://6866062236",
					["BOW_FIRE"] = "rbxassetid://6866062104",
					["ARROW_HIT"] = "rbxassetid://6866062188",
					["ARROW_IMPACT"] = "rbxassetid://6866062148",
					["TELEPEARL_THROW"] = "rbxassetid://6866223756",
					["TELEPEARL_LAND"] = "rbxassetid://6866223798",
					["CROSSBOW_RELOAD"] = "rbxassetid://6869254094",
					["VOICE_1"] = "rbxassetid://5283866929",
					["VOICE_2"] = "rbxassetid://5283867710",
					["VOICE_HONK"] = "rbxassetid://5283872555",
					["FORTIFY_BLOCK"] = "rbxassetid://6955762535",
					["EAT_FOOD_1"] = "rbxassetid://4968170636",
					["KILL"] = "rbxassetid://7013482008",
					["ZIPLINE_TRAVEL"] = "rbxassetid://7047882304",
					["ZIPLINE_LATCH"] = "rbxassetid://7047882233",
					["ZIPLINE_UNLATCH"] = "rbxassetid://7047882265",
					["SHIELD_BLOCKED"] = "rbxassetid://6955762535",
					["GUITAR_LOOP"] = "rbxassetid://7084168540",
					["GUITAR_HEAL_1"] = "rbxassetid://7084168458",
					["CANNON_MOVE"] = "rbxassetid://7118668472",
					["CANNON_FIRE"] = "rbxassetid://7121064180",
					["BALLOON_INFLATE"] = "rbxassetid://7118657911",
					["BALLOON_POP"] = "rbxassetid://7118657873",
					["FIREBALL_THROW"] = "rbxassetid://7192289445",
					["LASSO_HIT"] = "rbxassetid://7192289603",
					["LASSO_SWING"] = "rbxassetid://7192289504",
					["LASSO_THROW"] = "rbxassetid://7192289548",
					["GRIM_REAPER_CONSUME"] = "rbxassetid://7225389554",
					["GRIM_REAPER_CHANNEL"] = "rbxassetid://7225389512",
					["TV_STATIC"] = "rbxassetid://7256209920",
					["TURRET_ON"] = "rbxassetid://7290176291",
					["TURRET_OFF"] = "rbxassetid://7290176380",
					["TURRET_ROTATE"] = "rbxassetid://7290176421",
					["TURRET_SHOOT"] = "rbxassetid://7290187805",
					["WIZARD_LIGHTNING_CAST"] = "rbxassetid://7262989886",
					["WIZARD_LIGHTNING_LAND"] = "rbxassetid://7263165647",
					["WIZARD_LIGHTNING_STRIKE"] = "rbxassetid://7263165347",
					["WIZARD_ORB_CAST"] = "rbxassetid://7263165448",
					["WIZARD_ORB_TRAVEL_LOOP"] = "rbxassetid://7263165579",
					["WIZARD_ORB_CONTACT_LOOP"] = "rbxassetid://7263165647",
					["BATTLE_PASS_PROGRESS_LEVEL_UP"] = "rbxassetid://7331597283",
					["BATTLE_PASS_PROGRESS_EXP_GAIN"] = "rbxassetid://7331597220",
					["FLAMETHROWER_UPGRADE"] = "rbxassetid://7310273053",
					["FLAMETHROWER_USE"] = "rbxassetid://7310273125",
					["BRITTLE_HIT"] = "rbxassetid://7310273179",
					["EXTINGUISH"] = "rbxassetid://7310273015",
					["RAVEN_SPACE_AMBIENT"] = "rbxassetid://7341443286",
					["RAVEN_WING_FLAP"] = "rbxassetid://7341443378",
					["RAVEN_CAW"] = "rbxassetid://7341443447",
					["JADE_HAMMER_THUD"] = "rbxassetid://7342299402",
					["STATUE"] = "rbxassetid://7344166851",
					["CONFETTI"] = "rbxassetid://7344278405",
					["HEART"] = "rbxassetid://7345120916",
					["SPRAY"] = "rbxassetid://7361499529",
					["BEEHIVE_PRODUCE"] = "rbxassetid://7378100183",
					["DEPOSIT_BEE"] = "rbxassetid://7378100250",
					["CATCH_BEE"] = "rbxassetid://7378100305",
					["BEE_NET_SWING"] = "rbxassetid://7378100350",
					["ASCEND"] = "rbxassetid://7378387334",
					["BED_ALARM"] = "rbxassetid://7396762708",
					["BOUNTY_CLAIMED"] = "rbxassetid://7396751941",
					["BOUNTY_ASSIGNED"] = "rbxassetid://7396752155",
					["BAGUETTE_HIT"] = "rbxassetid://7396760547",
					["BAGUETTE_SWING"] = "rbxassetid://7396760496",
					["TESLA_ZAP"] = "rbxassetid://7497477336",
					["SPIRIT_TRIGGERED"] = "rbxassetid://7498107251",
					["SPIRIT_EXPLODE"] = "rbxassetid://7498107327",
					["ANGEL_LIGHT_ORB_CREATE"] = "rbxassetid://7552134231",
					["ANGEL_LIGHT_ORB_HEAL"] = "rbxassetid://7552134868",
					["ANGEL_VOID_ORB_CREATE"] = "rbxassetid://7552135942",
					["ANGEL_VOID_ORB_HEAL"] = "rbxassetid://7552136927",
					["DODO_BIRD_JUMP"] = "rbxassetid://7618085391",
					["DODO_BIRD_DOUBLE_JUMP"] = "rbxassetid://7618085771",
					["DODO_BIRD_MOUNT"] = "rbxassetid://7618085486",
					["DODO_BIRD_DISMOUNT"] = "rbxassetid://7618085571",
					["DODO_BIRD_SQUAWK_1"] = "rbxassetid://7618085870",
					["DODO_BIRD_SQUAWK_2"] = "rbxassetid://7618085657",
					["SHIELD_CHARGE_START"] = "rbxassetid://7730842884",
					["SHIELD_CHARGE_LOOP"] = "rbxassetid://7730843006",
					["SHIELD_CHARGE_BASH"] = "rbxassetid://7730843142",
					["ROCKET_LAUNCHER_FIRE"] = "rbxassetid://7681584765",
					["ROCKET_LAUNCHER_FLYING_LOOP"] = "rbxassetid://7681584906",
					["SMOKE_GRENADE_POP"] = "rbxassetid://7681276062",
					["SMOKE_GRENADE_EMIT_LOOP"] = "rbxassetid://7681276135",
					["GOO_SPIT"] = "rbxassetid://7807271610",
					["GOO_SPLAT"] = "rbxassetid://7807272724",
					["GOO_EAT"] = "rbxassetid://7813484049",
					["LUCKY_BLOCK_BREAK"] = "rbxassetid://7682005357",
					["AXOLOTL_SWITCH_TARGETS"] = "rbxassetid://7344278405",
					["HALLOWEEN_MUSIC"] = "rbxassetid://7775602786",
					["SNAP_TRAP_SETUP"] = "rbxassetid://7796078515",
					["SNAP_TRAP_CLOSE"] = "rbxassetid://7796078695",
					["SNAP_TRAP_CONSUME_MARK"] = "rbxassetid://7796078825",
					["GHOST_VACUUM_SUCKING_LOOP"] = "rbxassetid://7814995865",
					["GHOST_VACUUM_SHOOT"] = "rbxassetid://7806060367",
					["GHOST_VACUUM_CATCH"] = "rbxassetid://7815151688",
					["FISHERMAN_GAME_START"] = "rbxassetid://7806060544",
					["FISHERMAN_GAME_PULLING_LOOP"] = "rbxassetid://7806060638",
					["FISHERMAN_GAME_PROGRESS_INCREASE"] = "rbxassetid://7806060745",
					["FISHERMAN_GAME_FISH_MOVE"] = "rbxassetid://7806060863",
					["FISHERMAN_GAME_LOOP"] = "rbxassetid://7806061057",
					["FISHING_ROD_CAST"] = "rbxassetid://7806060976",
					["FISHING_ROD_SPLASH"] = "rbxassetid://7806061193",
					["SPEAR_HIT"] = "rbxassetid://7807270398",
					["SPEAR_THROW"] = "rbxassetid://7813485044",
				}
				for i,v in pairs(bedwars.CombatController.killSounds) do
					bedwars.CombatController.killSounds[i] = oldbedwarssoundtable.KILL
				end
				for i,v in pairs(bedwars.CombatController.multiKillLoops) do
					bedwars.CombatController.multiKillLoops[i] = ""
				end
				for i,v in pairs(bedwars.ItemTable) do
					if oldbedwarsicontab[i] then
						v.image = oldbedwarsicontab[i]
					end
				end
				for i,v in pairs(oldbedwarssoundtable) do
					local item = bedwars.SoundList[i]
					if item then
						bedwars.SoundList[i] = v
					end
				end
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(214, 0, 0)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.ViewmodelController.show, 37, "")
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				sethiddenproperty(lightingService, "Technology", "ShadowMap")
				lightingService.Ambient = Color3.fromRGB(69, 69, 69)
				lightingService.Brightness = 3
				lightingService.EnvironmentDiffuseScale = 1
				lightingService.EnvironmentSpecularScale = 1
				lightingService.OutdoorAmbient = Color3.fromRGB(69, 69, 69)
				lightingService.Atmosphere.Density = 0.1
				lightingService.Atmosphere.Offset = 0.25
				lightingService.Atmosphere.Color = Color3.fromRGB(198, 198, 198)
				lightingService.Atmosphere.Decay = Color3.fromRGB(104, 112, 124)
				lightingService.Atmosphere.Glare = 0
				lightingService.Atmosphere.Haze = 0
				lightingService.ClockTime = 13
				lightingService.GeographicLatitude = 0
				lightingService.GlobalShadows = false
				lightingService.TimeOfDay = "13:00:00"
				lightingService.Sky.SkyboxBk = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxDn = "rbxassetid://6334928194"
				lightingService.Sky.SkyboxFt = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxLf = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxRt = "rbxassetid://7018684000"
				lightingService.Sky.SkyboxUp = "rbxassetid://7018689553"
			end)
		end,
		Winter = function()
			task.spawn(function()
				for i,v in pairs(lightingService:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then
						v:Remove()
					end
				end
				local sky = Instance.new("Sky")
				sky.StarCount = 5000
				sky.SkyboxUp = "rbxassetid://8139676647"
				sky.SkyboxLf = "rbxassetid://8139676988"
				sky.SkyboxFt = "rbxassetid://8139677111"
				sky.SkyboxBk = "rbxassetid://8139677359"
				sky.SkyboxDn = "rbxassetid://8139677253"
				sky.SkyboxRt = "rbxassetid://8139676842"
				sky.SunTextureId = "rbxassetid://6196665106"
				sky.SunAngularSize = 11
				sky.MoonTextureId = "rbxassetid://8139665943"
				sky.MoonAngularSize = 30
				sky.Parent = lightingService
				local sunray = Instance.new("SunRaysEffect")
				sunray.Intensity = 0.03
				sunray.Parent = lightingService
				local bloom = Instance.new("BloomEffect")
				bloom.Threshold = 2
				bloom.Intensity = 1
				bloom.Size = 2
				bloom.Parent = lightingService
				local atmosphere = Instance.new("Atmosphere")
				atmosphere.Density = 0.3
				atmosphere.Offset = 0.25
				atmosphere.Color = Color3.fromRGB(198, 198, 198)
				atmosphere.Decay = Color3.fromRGB(104, 112, 124)
				atmosphere.Glare = 0
				atmosphere.Haze = 0
				atmosphere.Parent = lightingService
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(70, 255, 255)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				debug.setconstant(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar.render, 16, 4653055)
			end)
			task.spawn(function()
				local snowpart = Instance.new("Part")
				snowpart.Size = Vector3.new(240, 0.5, 240)
				snowpart.Name = "SnowParticle"
				snowpart.Transparency = 1
				snowpart.CanCollide = false
				snowpart.Position = Vector3.new(0, 120, 286)
				snowpart.Anchored = true
				snowpart.Parent = workspace
				local snow = Instance.new("ParticleEmitter")
				snow.RotSpeed = NumberRange.new(300)
				snow.VelocitySpread = 35
				snow.Rate = 28
				snow.Texture = "rbxassetid://8158344433"
				snow.Rotation = NumberRange.new(110)
				snow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.16939899325371,0),NumberSequenceKeypoint.new(0.23365999758244,0.62841498851776,0.37158501148224),NumberSequenceKeypoint.new(0.56209099292755,0.38797798752785,0.2771390080452),NumberSequenceKeypoint.new(0.90577298402786,0.51912599802017,0),NumberSequenceKeypoint.new(1,1,0)})
				snow.Lifetime = NumberRange.new(8,14)
				snow.Speed = NumberRange.new(8,18)
				snow.EmissionDirection = Enum.NormalId.Bottom
				snow.SpreadAngle = Vector2.new(35,35)
				snow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.039760299026966,1.3114800453186,0.32786899805069),NumberSequenceKeypoint.new(0.7554469704628,0.98360699415207,0.44038599729538),NumberSequenceKeypoint.new(1,0,0)})
				snow.Parent = snowpart
				local windsnow = Instance.new("ParticleEmitter")
				windsnow.Acceleration = Vector3.new(0,0,1)
				windsnow.RotSpeed = NumberRange.new(100)
				windsnow.VelocitySpread = 35
				windsnow.Rate = 28
				windsnow.Texture = "rbxassetid://8158344433"
				windsnow.EmissionDirection = Enum.NormalId.Bottom
				windsnow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.16939899325371,0),NumberSequenceKeypoint.new(0.23365999758244,0.62841498851776,0.37158501148224),NumberSequenceKeypoint.new(0.56209099292755,0.38797798752785,0.2771390080452),NumberSequenceKeypoint.new(0.90577298402786,0.51912599802017,0),NumberSequenceKeypoint.new(1,1,0)})
				windsnow.Lifetime = NumberRange.new(8,14)
				windsnow.Speed = NumberRange.new(8,18)
				windsnow.Rotation = NumberRange.new(110)
				windsnow.SpreadAngle = Vector2.new(35,35)
				windsnow.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.039760299026966,1.3114800453186,0.32786899805069),NumberSequenceKeypoint.new(0.7554469704628,0.98360699415207,0.44038599729538),NumberSequenceKeypoint.new(1,0,0)})
				windsnow.Parent = snowpart
				repeat
					task.wait()
					if entityLibrary.isAlive then
						snowpart.Position = entityLibrary.character.HumanoidRootPart.Position + Vector3.new(0, 100, 0)
					end
				until not vapeInjected
			end)
		end,
		Halloween = function()
			task.spawn(function()
				for i,v in pairs(lightingService:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then
						v:Remove()
					end
				end
				lightingService.TimeOfDay = "00:00:00"
				pcall(function() workspace.Clouds:Destroy() end)
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(255, 100, 0)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(0, 0, 0) or Color3.new(0, 0, 0))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				local colorcorrection = Instance.new("ColorCorrectionEffect")
				colorcorrection.TintColor = Color3.fromRGB(255, 185, 81)
				colorcorrection.Brightness = 0.05
				colorcorrection.Parent = lightingService
				debug.setconstant(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar.render, 16, 16737280)
			end)
		end,
		Valentines = function()
			task.spawn(function()
				for i,v in pairs(lightingService:GetChildren()) do
					if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then
						v:Remove()
					end
				end
				local sky = Instance.new("Sky")
				sky.SkyboxBk = "rbxassetid://1546230803"
				sky.SkyboxDn = "rbxassetid://1546231143"
				sky.SkyboxFt = "rbxassetid://1546230803"
				sky.SkyboxLf = "rbxassetid://1546230803"
				sky.SkyboxRt = "rbxassetid://1546230803"
				sky.SkyboxUp = "rbxassetid://1546230451"
				sky.Parent = lightingService
				pcall(function() workspace.Clouds:Destroy() end)
				local damagetab = debug.getupvalue(bedwars.DamageIndicator, 2)
				damagetab.strokeThickness = false
				damagetab.textSize = 32
				damagetab.blowUpDuration = 0
				damagetab.baseColor = Color3.fromRGB(255, 132, 178)
				damagetab.blowUpSize = 32
				damagetab.blowUpCompleteDuration = 0
				damagetab.anchoredDuration = 0
				debug.setconstant(bedwars.DamageIndicator, 83, Enum.Font.LuckiestGuy)
				debug.setconstant(bedwars.DamageIndicator, 102, "Enabled")
				debug.setconstant(bedwars.DamageIndicator, 118, 0.3)
				debug.setconstant(bedwars.DamageIndicator, 128, 0.5)
				debug.setupvalue(bedwars.DamageIndicator, 10, {
					Create = function(self, obj, ...)
						task.spawn(function()
							obj.Parent.Parent.Parent.Parent.Velocity = Vector3.new((math.random(-50, 50) / 100) * damagetab.velX, (math.random(50, 60) / 100) * damagetab.velY, (math.random(-50, 50) / 100) * damagetab.velZ)
							local textcompare = obj.Parent.TextColor3
							if textcompare ~= Color3.fromRGB(85, 255, 85) then
								local newtween = tweenService:Create(obj.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
									TextColor3 = (textcompare == Color3.fromRGB(76, 175, 93) and Color3.new(0, 0, 0) or Color3.new(0, 0, 0))
								})
								task.wait(0.15)
								newtween:Play()
							end
						end)
						return tweenService:Create(obj, ...)
					end
				})
				local colorcorrection = Instance.new("ColorCorrectionEffect")
				colorcorrection.TintColor = Color3.fromRGB(255, 199, 220)
				colorcorrection.Brightness = 0.05
				colorcorrection.Parent = lightingService
				debug.setconstant(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar.render, 16, 16745650)
			end)
		end
	}

	GameTheme = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "GameTheme",
		Function = function(callback)
			if callback then
				if not transformed then
					transformed = true
					themefunctions[GameThemeMode.Value]()
				else
					GameTheme.ToggleButton(false)
				end
			else
				warningNotification("GameTheme", "Disabled Next Game", 10)
			end
		end,
		ExtraText = function()
			return GameThemeMode.Value
		end
	})
	GameThemeMode = GameTheme.CreateDropdown({
		Name = "Theme",
		Function = function() end,
		List = {"Old", "Winter", "Halloween", "Valentines"}
	})
end)

run(function()
	local oldkilleffect
	local KillEffectMode = {Value = "Gravity"}
	local KillEffectList = {Value = "None"}
	local KillEffectName2 = {}
	local killeffects = {
		Gravity = function(p3, p4, p5, p6)
			p5:BreakJoints()
			task.spawn(function()
				local partvelo = {}
				for i,v in pairs(p5:GetDescendants()) do
					if v:IsA("BasePart") then
						partvelo[v.Name] = v.Velocity * 3
					end
				end
				p5.Archivable = true
				local clone = p5:Clone()
				clone.Humanoid.Health = 100
				clone.Parent = workspace
				local nametag = clone:FindFirstChild("Nametag", true)
				if nametag then nametag:Destroy() end
				game:GetService("Debris"):AddItem(clone, 30)
				p5:Destroy()
				task.wait(0.01)
				clone.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				clone:BreakJoints()
				task.wait(0.01)
				for i,v in pairs(clone:GetDescendants()) do
					if v:IsA("BasePart") then
						local bodyforce = Instance.new("BodyForce")
						bodyforce.Force = Vector3.new(0, (workspace.Gravity - 10) * v:GetMass(), 0)
						bodyforce.Parent = v
						v.CanCollide = true
						v.Velocity = partvelo[v.Name] or Vector3.zero
					end
				end
			end)
		end,
		Lightning = function(p3, p4, p5, p6)
			p5:BreakJoints()
			local startpos = 1125
			local startcf = p5.PrimaryPart.CFrame.p - Vector3.new(0, 8, 0)
			local newpos = Vector3.new((math.random(1, 10) - 5) * 2, startpos, (math.random(1, 10) - 5) * 2)
			for i = startpos - 75, 0, -75 do
				local newpos2 = Vector3.new((math.random(1, 10) - 5) * 2, i, (math.random(1, 10) - 5) * 2)
				if i == 0 then
					newpos2 = Vector3.zero
				end
				local part = Instance.new("Part")
				part.Size = Vector3.new(1.5, 1.5, 77)
				part.Material = Enum.Material.SmoothPlastic
				part.Anchored = true
				part.Material = Enum.Material.Neon
				part.CanCollide = false
				part.CFrame = CFrame.new(startcf + newpos + ((newpos2 - newpos) * 0.5), startcf + newpos2)
				part.Parent = workspace
				local part2 = part:Clone()
				part2.Size = Vector3.new(3, 3, 78)
				part2.Color = Color3.new(0.7, 0.7, 0.7)
				part2.Transparency = 0.7
				part2.Material = Enum.Material.SmoothPlastic
				part2.Parent = workspace
				game:GetService("Debris"):AddItem(part, 0.5)
				game:GetService("Debris"):AddItem(part2, 0.5)
				bedwars.QueryUtil:setQueryIgnored(part, true)
				bedwars.QueryUtil:setQueryIgnored(part2, true)
				if i == 0 then
					local soundpart = Instance.new("Part")
					soundpart.Transparency = 1
					soundpart.Anchored = true
					soundpart.Size = Vector3.zero
					soundpart.Position = startcf
					soundpart.Parent = workspace
					bedwars.QueryUtil:setQueryIgnored(soundpart, true)
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://6993372814"
					sound.Volume = 2
					sound.Pitch = 0.5 + (math.random(1, 3) / 10)
					sound.Parent = soundpart
					sound:Play()
					sound.Ended:Connect(function()
						soundpart:Destroy()
					end)
				end
				newpos = newpos2
			end
		end
	}
	local KillEffectName = {}
	for i,v in pairs(bedwars.KillEffectMeta) do
		table.insert(KillEffectName, v.name)
		KillEffectName[v.name] = i
	end
	table.sort(KillEffectName, function(a, b) return a:lower() < b:lower() end)
	local KillEffect = {Enabled = false}
	KillEffect = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "KillEffect",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.matchState ~= 0 or not KillEffect.Enabled
					if KillEffect.Enabled then
						lplr:SetAttribute("KillEffectType", "none")
						if KillEffectMode.Value == "Bedwars" then
							lplr:SetAttribute("KillEffectType", KillEffectName[KillEffectList.Value])
						end
					end
				end)
				oldkilleffect = bedwars.DefaultKillEffect.onKill
				bedwars.DefaultKillEffect.onKill = function(p3, p4, p5, p6)
					killeffects[KillEffectMode.Value](p3, p4, p5, p6)
				end
			else
				bedwars.DefaultKillEffect.onKill = oldkilleffect
			end
		end
	})
	local modes = {"Bedwars"}
	for i,v in pairs(killeffects) do
		table.insert(modes, i)
	end
	KillEffectMode = KillEffect.CreateDropdown({
		Name = "Mode",
		Function = function()
			if KillEffect.Enabled then
				KillEffect.ToggleButton(false)
				KillEffect.ToggleButton(false)
			end
		end,
		List = modes
	})
	KillEffectList = KillEffect.CreateDropdown({
		Name = "Bedwars",
		Function = function()
			if KillEffect.Enabled then
				KillEffect.ToggleButton(false)
				KillEffect.ToggleButton(false)
			end
		end,
		List = KillEffectName
	})
end)

run(function()
	local KitESP = {Enabled = false}
	local espobjs = {}
	local espfold = Instance.new("Folder")
	espfold.Parent = GuiLibrary.MainGui

	local function espadd(v, icon)
		local billboard = Instance.new("BillboardGui")
		billboard.Parent = espfold
		billboard.Name = "iron"
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
		billboard.Size = UDim2.new(0, 32, 0, 32)
		billboard.AlwaysOnTop = true
		billboard.Adornee = v
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 0.5
		image.BorderSizePixel = 0
		image.Image = bedwars.getIcon({itemType = icon}, true)
		image.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		image.Size = UDim2.new(0, 32, 0, 32)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Parent = billboard
		local uicorner = Instance.new("UICorner")
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = image
		espobjs[v] = billboard
	end

	local function addKit(tag, icon)
		table.insert(KitESP.Connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			espadd(v.PrimaryPart, icon)
		end))
		table.insert(KitESP.Connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if espobjs[v.PrimaryPart] then
				espobjs[v.PrimaryPart]:Destroy()
				espobjs[v.PrimaryPart] = nil
			end
		end))
		for i,v in pairs(collectionService:GetTagged(tag)) do
			espadd(v.PrimaryPart, icon)
		end
	end

	KitESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "KitESP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.equippedKit ~= ""
					if KitESP.Enabled then
						if store.equippedKit == "metal_detector" then
							addKit("hidden-metal", "iron")
						elseif store.equippedKit == "beekeeper" then
							addKit("bee", "bee")
						elseif store.equippedKit == "bigman" then
							addKit("treeOrb", "natures_essence_1")
						end
					end
				end)
			else
				espfold:ClearAllChildren()
				table.clear(espobjs)
			end
		end
	})
end)

run(function()
	local function floorNameTagPosition(pos)
		return Vector2.new(math.floor(pos.X), math.floor(pos.Y))
	end

	local function removeTags(str)
		str = str:gsub("<br%s*/>", "\n")
		return (str:gsub("<[^<>]->", ""))
	end

	local NameTagsFolder = Instance.new("Folder")
	NameTagsFolder.Name = "NameTagsFolder"
	NameTagsFolder.Parent = GuiLibrary.MainGui
	local nametagsfolderdrawing = {}
	local NameTagsColor = {Value = 0.44}
	local NameTagsDisplayName = {Enabled = false}
	local NameTagsHealth = {Enabled = false}
	local NameTagsDistance = {Enabled = false}
	local NameTagsBackground = {Enabled = true}
	local NameTagsScale = {Value = 10}
	local NameTagsFont = {Value = "SourceSans"}
	local NameTagsTeammates = {Enabled = true}
	local NameTagsShowInventory = {Enabled = false}
	local NameTagsRangeLimit = {Value = 0}
	local fontitems = {"SourceSans"}
	local nametagstrs = {}
	local nametagsizes = {}
	local kititems = {
		jade = "jade_hammer",
		archer = "tactical_crossbow",
		angel = "",
		cowgirl = "lasso",
		dasher = "wood_dao",
		axolotl = "axolotl",
		yeti = "snowball",
		smoke = "smoke_block",
		trapper = "snap_trap",
		pyro = "flamethrower",
		davey = "cannon",
		regent = "void_axe",
		baker = "apple",
		builder = "builder_hammer",
		farmer_cletus = "carrot_seeds",
		melody = "guitar",
		barbarian = "rageblade",
		gingerbread_man = "gumdrop_bounce_pad",
		spirit_catcher = "spirit",
		fisherman = "fishing_rod",
		oil_man = "oil_consumable",
		santa = "tnt",
		miner = "miner_pickaxe",
		sheep_herder = "crook",
		beast = "speed_potion",
		metal_detector = "metal_detector",
		cyber = "drone",
		vesta = "damage_banner",
		lumen = "light_sword",
		ember = "infernal_saber",
		queen_bee = "bee"
	}

	local nametagfuncs1 = {
		Normal = function(plr)
			if NameTagsTeammates.Enabled and (not plr.Targetable) and (not plr.Friend) then return end
			local thing = Instance.new("TextLabel")
			thing.BackgroundColor3 = Color3.new()
			thing.BorderSizePixel = 0
			thing.Visible = false
			thing.RichText = true
			thing.AnchorPoint = Vector2.new(0.5, 1)
			thing.Name = plr.Player.Name
			thing.Font = Enum.Font[NameTagsFont.Value]
			thing.TextSize = 14 * (NameTagsScale.Value / 10)
			thing.BackgroundTransparency = NameTagsBackground.Enabled and 0.5 or 1
			nametagstrs[plr.Player] = whitelist:tag(plr.Player, true)..(NameTagsDisplayName.Enabled and plr.Player.DisplayName or plr.Player.Name)
			if NameTagsHealth.Enabled then
				local color = Color3.fromHSV(math.clamp(plr.Humanoid.Health / plr.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
				nametagstrs[plr.Player] = nametagstrs[plr.Player]..' <font color="rgb('..tostring(math.floor(color.R * 255))..','..tostring(math.floor(color.G * 255))..','..tostring(math.floor(color.B * 255))..')">'..math.round(plr.Humanoid.Health).."</font>"
			end
			if NameTagsDistance.Enabled then
				nametagstrs[plr.Player] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..nametagstrs[plr.Player]
			end
			local nametagSize = textService:GetTextSize(removeTags(nametagstrs[plr.Player]), thing.TextSize, thing.Font, Vector2.new(100000, 100000))
			thing.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
			thing.Text = nametagstrs[plr.Player]
			thing.TextColor3 = getPlayerColor(plr.Player) or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
			thing.Parent = NameTagsFolder
			local hand = Instance.new("ImageLabel")
			hand.Size = UDim2.new(0, 30, 0, 30)
			hand.Name = "Hand"
			hand.BackgroundTransparency = 1
			hand.Position = UDim2.new(0, -30, 0, -30)
			hand.Image = ""
			hand.Parent = thing
			local helmet = hand:Clone()
			helmet.Name = "Helmet"
			helmet.Position = UDim2.new(0, 5, 0, -30)
			helmet.Parent = thing
			local chest = hand:Clone()
			chest.Name = "Chestplate"
			chest.Position = UDim2.new(0, 35, 0, -30)
			chest.Parent = thing
			local boots = hand:Clone()
			boots.Name = "Boots"
			boots.Position = UDim2.new(0, 65, 0, -30)
			boots.Parent = thing
			local kit = hand:Clone()
			kit.Name = "Kit"
			task.spawn(function()
				repeat task.wait() until plr.Player:GetAttribute("PlayingAsKit") ~= ""
				if kit then
					kit.Image = kititems[plr.Player:GetAttribute("PlayingAsKit")] and bedwars.getIcon({itemType = kititems[plr.Player:GetAttribute("PlayingAsKit")]}, NameTagsShowInventory.Enabled) or ""
				end
			end)
			kit.Position = UDim2.new(0, -30, 0, -65)
			kit.Parent = thing
			nametagsfolderdrawing[plr.Player] = {entity = plr, Main = thing}
		end,
		Drawing = function(plr)
			if NameTagsTeammates.Enabled and (not plr.Targetable) and (not plr.Friend) then return end
			local thing = {Main = {}, entity = plr}
			thing.Main.Text = Drawing.new("Text")
			thing.Main.Text.Size = 17 * (NameTagsScale.Value / 10)
			thing.Main.Text.Font = (math.clamp((table.find(fontitems, NameTagsFont.Value) or 1) - 1, 0, 3))
			thing.Main.Text.ZIndex = 2
			thing.Main.BG = Drawing.new("Square")
			thing.Main.BG.Filled = true
			thing.Main.BG.Transparency = 0.5
			thing.Main.BG.Visible = NameTagsBackground.Enabled
			thing.Main.BG.Color = Color3.new()
			thing.Main.BG.ZIndex = 1
			nametagstrs[plr.Player] = whitelist:tag(plr.Player, true)..(NameTagsDisplayName.Enabled and plr.Player.DisplayName or plr.Player.Name)
			if NameTagsHealth.Enabled then
				local color = Color3.fromHSV(math.clamp(plr.Humanoid.Health / plr.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
				nametagstrs[plr.Player] = nametagstrs[plr.Player]..' '..math.round(plr.Humanoid.Health)
			end
			if NameTagsDistance.Enabled then
				nametagstrs[plr.Player] = '[%s] '..nametagstrs[plr.Player]
			end
			thing.Main.Text.Text = nametagstrs[plr.Player]
			thing.Main.BG.Size = Vector2.new(thing.Main.Text.TextBounds.X + 4, thing.Main.Text.TextBounds.Y)
			thing.Main.Text.Color = getPlayerColor(plr.Player) or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
			nametagsfolderdrawing[plr.Player] = thing
		end
	}

	local nametagfuncs2 = {
		Normal = function(ent)
			local v = nametagsfolderdrawing[ent]
			nametagsfolderdrawing[ent] = nil
			if v then
				v.Main:Destroy()
			end
		end,
		Drawing = function(ent)
			local v = nametagsfolderdrawing[ent]
			nametagsfolderdrawing[ent] = nil
			if v then
				for i2,v2 in pairs(v.Main) do
					pcall(function() v2.Visible = false v2:Remove() end)
				end
			end
		end
	}

	local nametagupdatefuncs = {
		Normal = function(ent)
			local v = nametagsfolderdrawing[ent.Player]
			if v then
				nametagstrs[ent.Player] = whitelist:tag(ent.Player, true)..(NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name)
				if NameTagsHealth.Enabled then
					local color = Color3.fromHSV(math.clamp(ent.Humanoid.Health / ent.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
					nametagstrs[ent.Player] = nametagstrs[ent.Player]..' <font color="rgb('..tostring(math.floor(color.R * 255))..','..tostring(math.floor(color.G * 255))..','..tostring(math.floor(color.B * 255))..')">'..math.round(ent.Humanoid.Health).."</font>"
				end
				if NameTagsDistance.Enabled then
					nametagstrs[ent.Player] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..nametagstrs[ent.Player]
				end
				if NameTagsShowInventory.Enabled then
					local inventory = store.inventories[ent.Player] or {armor = {}}
					if inventory.hand then
						v.Main.Hand.Image = bedwars.getIcon(inventory.hand, NameTagsShowInventory.Enabled)
						if v.Main.Hand.Image:find("rbxasset://") then
							v.Main.Hand.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Hand.Image = ""
					end
					if inventory.armor[4] then
						v.Main.Helmet.Image = bedwars.getIcon(inventory.armor[4], NameTagsShowInventory.Enabled)
						if v.Main.Helmet.Image:find("rbxasset://") then
							v.Main.Helmet.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Helmet.Image = ""
					end
					if inventory.armor[5] then
						v.Main.Chestplate.Image = bedwars.getIcon(inventory.armor[5], NameTagsShowInventory.Enabled)
						if v.Main.Chestplate.Image:find("rbxasset://") then
							v.Main.Chestplate.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Chestplate.Image = ""
					end
					if inventory.armor[6] then
						v.Main.Boots.Image = bedwars.getIcon(inventory.armor[6], NameTagsShowInventory.Enabled)
						if v.Main.Boots.Image:find("rbxasset://") then
							v.Main.Boots.ResampleMode = Enum.ResamplerMode.Pixelated
						end
					else
						v.Main.Boots.Image = ""
					end
				end
				local nametagSize = textService:GetTextSize(removeTags(nametagstrs[ent.Player]), v.Main.TextSize, v.Main.Font, Vector2.new(100000, 100000))
				v.Main.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
				v.Main.Text = nametagstrs[ent.Player]
			end
		end,
		Drawing = function(ent)
			local v = nametagsfolderdrawing[ent.Player]
			if v then
				nametagstrs[ent.Player] = whitelist:tag(ent.Player, true)..(NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name)
				if NameTagsHealth.Enabled then
					nametagstrs[ent.Player] = nametagstrs[ent.Player]..' '..math.round(ent.Humanoid.Health)
				end
				if NameTagsDistance.Enabled then
					nametagstrs[ent.Player] = '[%s] '..nametagstrs[ent.Player]
					v.Main.Text.Text = entityLibrary.isAlive and string.format(nametagstrs[ent.Player], math.floor((entityLibrary.character.HumanoidRootPart.Position - ent.RootPart.Position).Magnitude)) or nametagstrs[ent.Player]
				else
					v.Main.Text.Text = nametagstrs[ent.Player]
				end
				v.Main.BG.Size = Vector2.new(v.Main.Text.TextBounds.X + 4, v.Main.Text.TextBounds.Y)
				v.Main.Text.Color = getPlayerColor(ent.Player) or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
			end
		end
	}

	local nametagcolorfuncs = {
		Normal = function(hue, sat, value)
			local color = Color3.fromHSV(hue, sat, value)
			for i,v in pairs(nametagsfolderdrawing) do
				v.Main.TextColor3 = getPlayerColor(v.entity.Player) or color
			end
		end,
		Drawing = function(hue, sat, value)
			local color = Color3.fromHSV(hue, sat, value)
			for i,v in pairs(nametagsfolderdrawing) do
				v.Main.Text.Color = getPlayerColor(v.entity.Player) or color
			end
		end
	}

	local nametagloop = {
		Normal = function()
			for i,v in pairs(nametagsfolderdrawing) do
				local headPos, headVis = worldtoscreenpoint((v.entity.RootPart:GetRenderCFrame() * CFrame.new(0, v.entity.Head.Size.Y + v.entity.RootPart.Size.Y, 0)).Position)
				if not headVis then
					v.Main.Visible = false
					continue
				end
				local mag = entityLibrary.isAlive and math.floor((entityLibrary.character.HumanoidRootPart.Position - v.entity.RootPart.Position).Magnitude) or 0
				if NameTagsRangeLimit.Value ~= 0 and mag > NameTagsRangeLimit.Value then
					v.Main.Visible = false
					continue
				end
				if NameTagsDistance.Enabled then
					local stringsize = tostring(mag):len()
					if nametagsizes[v.entity.Player] ~= stringsize then
						local nametagSize = textService:GetTextSize(removeTags(string.format(nametagstrs[v.entity.Player], mag)), v.Main.TextSize, v.Main.Font, Vector2.new(100000, 100000))
						v.Main.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
					end
					nametagsizes[v.entity.Player] = stringsize
					v.Main.Text = string.format(nametagstrs[v.entity.Player], mag)
				end
				v.Main.Position = UDim2.new(0, headPos.X, 0, headPos.Y)
				v.Main.Visible = true
			end
		end,
		Drawing = function()
			for i,v in pairs(nametagsfolderdrawing) do
				local headPos, headVis = worldtoscreenpoint((v.entity.RootPart:GetRenderCFrame() * CFrame.new(0, v.entity.Head.Size.Y + v.entity.RootPart.Size.Y, 0)).Position)
				if not headVis then
					v.Main.Text.Visible = false
					v.Main.BG.Visible = false
					continue
				end
				local mag = entityLibrary.isAlive and math.floor((entityLibrary.character.HumanoidRootPart.Position - v.entity.RootPart.Position).Magnitude) or 0
				if NameTagsRangeLimit.Value ~= 0 and mag > NameTagsRangeLimit.Value then
					v.Main.Text.Visible = false
					v.Main.BG.Visible = false
					continue
				end
				if NameTagsDistance.Enabled then
					local stringsize = tostring(mag):len()
					v.Main.Text.Text = string.format(nametagstrs[v.entity.Player], mag)
					if nametagsizes[v.entity.Player] ~= stringsize then
						v.Main.BG.Size = Vector2.new(v.Main.Text.TextBounds.X + 4, v.Main.Text.TextBounds.Y)
					end
					nametagsizes[v.entity.Player] = stringsize
				end
				v.Main.BG.Position = Vector2.new(headPos.X - (v.Main.BG.Size.X / 2), (headPos.Y + v.Main.BG.Size.Y))
				v.Main.Text.Position = v.Main.BG.Position + Vector2.new(2, 0)
				v.Main.Text.Visible = true
				v.Main.BG.Visible = NameTagsBackground.Enabled
			end
		end
	}

	local methodused

	local NameTags = {Enabled = false}
	NameTags = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "NameTags",
		Function = function(callback)
			if callback then
				methodused = NameTagsDrawing.Enabled and "Drawing" or "Normal"
				if nametagfuncs2[methodused] then
					table.insert(NameTags.Connections, entityLibrary.entityRemovedEvent:Connect(nametagfuncs2[methodused]))
				end
				if nametagfuncs1[methodused] then
					local addfunc = nametagfuncs1[methodused]
					for i,v in pairs(entityLibrary.entityList) do
						if nametagsfolderdrawing[v.Player] then nametagfuncs2[methodused](v.Player) end
						addfunc(v)
					end
					table.insert(NameTags.Connections, entityLibrary.entityAddedEvent:Connect(function(ent)
						if nametagsfolderdrawing[ent.Player] then nametagfuncs2[methodused](ent.Player) end
						addfunc(ent)
					end))
				end
				if nametagupdatefuncs[methodused] then
					table.insert(NameTags.Connections, entityLibrary.entityUpdatedEvent:Connect(nametagupdatefuncs[methodused]))
					for i,v in pairs(entityLibrary.entityList) do
						nametagupdatefuncs[methodused](v)
					end
				end
				if nametagcolorfuncs[methodused] then
					table.insert(NameTags.Connections, GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.FriendColorRefresh.Event:Connect(function()
						nametagcolorfuncs[methodused](NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
					end))
				end
				if nametagloop[methodused] then
					RunLoops:BindToRenderStep("NameTags", nametagloop[methodused])
				end
			else
				RunLoops:UnbindFromRenderStep("NameTags")
				if nametagfuncs2[methodused] then
					for i,v in pairs(nametagsfolderdrawing) do
						nametagfuncs2[methodused](i)
					end
				end
			end
		end,
		HoverText = "Renders nametags on entities through walls."
	})
	for i,v in pairs(Enum.Font:GetEnumItems()) do
		if v.Name ~= "SourceSans" then
			table.insert(fontitems, v.Name)
		end
	end
	NameTagsFont = NameTags.CreateDropdown({
		Name = "Font",
		List = fontitems,
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
	})
	NameTagsColor = NameTags.CreateColorSlider({
		Name = "Player Color",
		Function = function(hue, sat, val)
			if NameTags.Enabled and nametagcolorfuncs[methodused] then
				nametagcolorfuncs[methodused](hue, sat, val)
			end
		end
	})
	NameTagsScale = NameTags.CreateSlider({
		Name = "Scale",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = 10,
		Min = 1,
		Max = 50
	})
	NameTagsRangeLimit = NameTags.CreateSlider({
		Name = "Range",
		Function = function() end,
		Min = 0,
		Max = 1000,
		Default = 0
	})
	NameTagsBackground = NameTags.CreateToggle({
		Name = "Background",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsDisplayName = NameTags.CreateToggle({
		Name = "Use Display Name",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsHealth = NameTags.CreateToggle({
		Name = "Health",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end
	})
	NameTagsDistance = NameTags.CreateToggle({
		Name = "Distance",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end
	})
	NameTagsShowInventory = NameTags.CreateToggle({
		Name = "Equipment",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsTeammates = NameTags.CreateToggle({
		Name = "Teammates",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
		Default = true
	})
	NameTagsDrawing = NameTags.CreateToggle({
		Name = "Drawing",
		Function = function() if NameTags.Enabled then NameTags.ToggleButton(false) NameTags.ToggleButton(false) end end,
	})
end)

run(function()
	local nobobdepth = {Value = 8}
	local nobobhorizontal = {Value = 8}
	local nobobvertical = {Value = -2}
	local rotationx = {Value = 0}
	local rotationy = {Value = 0}
	local rotationz = {Value = 0}
	local oldc1
	local oldfunc
	local nobob = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "NoBob",
		Function = function(callback)
			local viewmodel = gameCamera:FindFirstChild("Viewmodel")
			if viewmodel then
				if callback then
					oldfunc = bedwars.ViewmodelController.playAnimation
					bedwars.ViewmodelController.playAnimation = function(self, animid, details)
						if animid == bedwars.AnimationType.FP_WALK then
							return
						end
						return oldfunc(self, animid, details)
					end
					bedwars.ViewmodelController:setHeldItem(lplr.Character and lplr.Character:FindFirstChild("HandInvItem") and lplr.Character.HandInvItem.Value and lplr.Character.HandInvItem.Value:Clone())
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -(nobobdepth.Value / 10))
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", (nobobhorizontal.Value / 10))
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", (nobobvertical.Value / 10))
					oldc1 = viewmodel.RightHand.RightWrist.C1
					viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
				else
					bedwars.ViewmodelController.playAnimation = oldfunc
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", 0)
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", 0)
					lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", 0)
					viewmodel.RightHand.RightWrist.C1 = oldc1
				end
			end
		end,
		HoverText = "Removes the ugly bobbing when you move and makes sword farther"
	})
	nobobdepth = nobob.CreateSlider({
		Name = "Depth",
		Min = 0,
		Max = 24,
		Default = 8,
		Function = function(val)
			if nobob.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -(val / 10))
			end
		end
	})
	nobobhorizontal = nobob.CreateSlider({
		Name = "Horizontal",
		Min = 0,
		Max = 24,
		Default = 8,
		Function = function(val)
			if nobob.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", (val / 10))
			end
		end
	})
	nobobvertical= nobob.CreateSlider({
		Name = "Vertical",
		Min = 0,
		Max = 24,
		Default = -2,
		Function = function(val)
			if nobob.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", (val / 10))
			end
		end
	})
	rotationx = nobob.CreateSlider({
		Name = "RotX",
		Min = 0,
		Max = 360,
		Function = function(val)
			if nobob.Enabled then
				gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
			end
		end
	})
	rotationy = nobob.CreateSlider({
		Name = "RotY",
		Min = 0,
		Max = 360,
		Function = function(val)
			if nobob.Enabled then
				gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
			end
		end
	})
	rotationz = nobob.CreateSlider({
		Name = "RotZ",
		Min = 0,
		Max = 360,
		Function = function(val)
			if nobob.Enabled then
				gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(rotationx.Value), math.rad(rotationy.Value), math.rad(rotationz.Value))
			end
		end
	})
end)

run(function()
	local SongBeats = {Enabled = false}
	local SongBeatsList = {ObjectList = {}}
	local SongBeatsIntensity = {Value = 5}
	local SongTween
	local SongAudio

	local function PlaySong(arg)
		local args = arg:split(":")
		local song = isfile(args[1]) and getcustomasset(args[1]) or tonumber(args[1]) and "rbxassetid://"..args[1]
		if not song then
			warningNotification("SongBeats", "missing music file "..args[1], 5)
			SongBeats.ToggleButton(false)
			return
		end
		local bpm = 1 / (args[2] / 60)
		SongAudio = Instance.new("Sound")
		SongAudio.SoundId = song
		SongAudio.Parent = workspace
		SongAudio:Play()
		repeat
			repeat task.wait() until SongAudio.IsLoaded or (not SongBeats.Enabled)
			if (not SongBeats.Enabled) then break end
			local newfov = math.min(bedwars.FovController:getFOV() * (bedwars.SprintController.sprinting and 1.1 or 1), 120)
			gameCamera.FieldOfView = newfov - SongBeatsIntensity.Value
			if SongTween then SongTween:Cancel() end
			SongTween = game:GetService("TweenService"):Create(gameCamera, TweenInfo.new(0.2), {FieldOfView = newfov})
			SongTween:Play()
			task.wait(bpm)
		until (not SongBeats.Enabled) or SongAudio.IsPaused
	end

	SongBeats = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "SongBeats",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if #SongBeatsList.ObjectList <= 0 then
						warningNotification("SongBeats", "no songs", 5)
						SongBeats.ToggleButton(false)
						return
					end
					local lastChosen
					repeat
						local newSong
						repeat newSong = SongBeatsList.ObjectList[Random.new():NextInteger(1, #SongBeatsList.ObjectList)] task.wait() until newSong ~= lastChosen or #SongBeatsList.ObjectList <= 1
						lastChosen = newSong
						PlaySong(newSong)
						if not SongBeats.Enabled then break end
						task.wait(2)
					until (not SongBeats.Enabled)
				end)
			else
				if SongAudio then SongAudio:Destroy() end
				if SongTween then SongTween:Cancel() end
				gameCamera.FieldOfView = bedwars.FovController:getFOV() * (bedwars.SprintController.sprinting and 1.1 or 1)
			end
		end
	})
	SongBeatsList = SongBeats.CreateTextList({
		Name = "SongList",
		TempText = "songpath:bpm"
	})
	SongBeatsIntensity = SongBeats.CreateSlider({
		Name = "Intensity",
		Function = function() end,
		Min = 1,
		Max = 10,
		Default = 5
	})
end)

run(function()
	local performed = false
	GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "UICleanup",
		Function = function(callback)
			if callback and not performed then
				performed = true
				task.spawn(function()
					local hotbar = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-app"]).HotbarApp
					local hotbaropeninv = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-open-inventory"]).HotbarOpenInventory
					local topbarbutton = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out).TopBarButton
					local gametheme = require(replicatedStorage["rbxts_include"]["node_modules"]["@easy-games"]["game-core"].out.shared.ui["game-theme"]).GameTheme
					bedwars.AppController:closeApp("TopBarApp")
					local oldrender = topbarbutton.render
					topbarbutton.render = function(self)
						local res = oldrender(self)
						if not self.props.Text then
							return bedwars.Roact.createElement("TextButton", {Visible = false}, {})
						end
						return res
					end
					hotbaropeninv.render = function(self)
						return bedwars.Roact.createElement("TextButton", {Visible = false}, {})
					end
					--[[debug.setconstant(hotbar.render, 52, 0.9975)
					debug.setconstant(hotbar.render, 73, 100)
					debug.setconstant(hotbar.render, 89, 1)
					debug.setconstant(hotbar.render, 90, 0.04)
					debug.setconstant(hotbar.render, 91, -0.03)
					debug.setconstant(hotbar.render, 109, 1.35)
					debug.setconstant(hotbar.render, 110, 0)
					debug.setconstant(debug.getupvalue(hotbar.render, 11).render, 30, 1)
					debug.setconstant(debug.getupvalue(hotbar.render, 11).render, 31, 0.175)
					debug.setconstant(debug.getupvalue(hotbar.render, 11).render, 33, -0.101)
					debug.setconstant(debug.getupvalue(hotbar.render, 18).render, 71, 0)
					debug.setconstant(debug.getupvalue(hotbar.render, 18).tweenPosition, 16, 0)]]
					gametheme.topBarBGTransparency = 0.5
					bedwars.TopBarController:mountHud()
					game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
					bedwars.AbilityUIController.abilityButtonsScreenGui.Visible = false
					bedwars.MatchEndScreenController.waitUntilDisplay = function() return false end
					task.spawn(function()
						repeat
							task.wait()
							local gui = lplr.PlayerGui:FindFirstChild("StatusEffectHudScreen")
							if gui then gui.Enabled = false break end
						until false
					end)
					task.spawn(function()
						repeat task.wait() until store.matchState ~= 0
						if bedwars.ClientStoreHandler:getState().Game.customMatch == nil then
							debug.setconstant(bedwars.QueueCard.render, 15, 0.1)
						end
					end)
					local slot = bedwars.ClientStoreHandler:getState().Inventory.observedInventory.hotbarSlot
					bedwars.ClientStoreHandler:dispatch({
						type = "InventorySelectHotbarSlot",
						slot = slot + 1 % 8
					})
					bedwars.ClientStoreHandler:dispatch({
						type = "InventorySelectHotbarSlot",
						slot = slot
					})
				end)
			end
		end
	})
end)

run(function()
	local AntiAFK = {Enabled = false}
	AntiAFK = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AntiAFK",
		Function = function(callback)
			if callback then
				bedwars.Client:Get("AfkInfo"):SendToServer({
					afk = false
				})
			end
		end
	})
end)

run(function()
	local AutoBalloonPart
	local AutoBalloonConnection
	local AutoBalloonDelay = {Value = 10}
	local AutoBalloonLegit = {Enabled = false}
	local AutoBalloonypos = 0
	local balloondebounce = false
	local AutoBalloon = {Enabled = false}
	AutoBalloon = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoBalloon",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.matchState ~= 0 or  not vapeInjected
					if vapeInjected and AutoBalloonypos == 0 and AutoBalloon.Enabled then
						local lowestypos = 99999
						for i,v in pairs(store.blocks) do
							local newray = workspace:Raycast(v.Position + Vector3.new(0, 800, 0), Vector3.new(0, -1000, 0), store.blockRaycast)
							if i % 200 == 0 then
								task.wait(0.06)
							end
							if newray and newray.Position.Y <= lowestypos then
								lowestypos = newray.Position.Y
							end
						end
						AutoBalloonypos = lowestypos - 8
					end
				end)
				task.spawn(function()
					repeat task.wait() until AutoBalloonypos ~= 0
					if AutoBalloon.Enabled then
						AutoBalloonPart = Instance.new("Part")
						AutoBalloonPart.CanCollide = false
						AutoBalloonPart.Size = Vector3.new(10000, 1, 10000)
						AutoBalloonPart.Anchored = true
						AutoBalloonPart.Transparency = 1
						AutoBalloonPart.Material = Enum.Material.Neon
						AutoBalloonPart.Color = Color3.fromRGB(135, 29, 139)
						AutoBalloonPart.Position = Vector3.new(0, AutoBalloonypos - 50, 0)
						AutoBalloonConnection = AutoBalloonPart.Touched:Connect(function(touchedpart)
							if entityLibrary.isAlive and touchedpart:IsDescendantOf(lplr.Character) and balloondebounce == false then
								autobankballoon = true
								balloondebounce = true
								local oldtool = store.localHand.tool
								for i = 1, 3 do
									if getItem("balloon") and (AutoBalloonLegit.Enabled and getHotbarSlot("balloon") or AutoBalloonLegit.Enabled == false) and (lplr.Character:GetAttribute("InflatedBalloons") and lplr.Character:GetAttribute("InflatedBalloons") < 3 or lplr.Character:GetAttribute("InflatedBalloons") == nil) then
										if AutoBalloonLegit.Enabled then
											if getHotbarSlot("balloon") then
												bedwars.ClientStoreHandler:dispatch({
													type = "InventorySelectHotbarSlot",
													slot = getHotbarSlot("balloon")
												})
												task.wait(AutoBalloonDelay.Value / 100)
												bedwars.BalloonController:inflateBalloon()
											end
										else
											task.wait(AutoBalloonDelay.Value / 100)
											bedwars.BalloonController:inflateBalloon()
										end
									end
								end
								if AutoBalloonLegit.Enabled and oldtool and getHotbarSlot(oldtool.Name) then
									task.wait(0.2)
									bedwars.ClientStoreHandler:dispatch({
										type = "InventorySelectHotbarSlot",
										slot = (getHotbarSlot(oldtool.Name) or 0)
									})
								end
								balloondebounce = false
								autobankballoon = false
							end
						end)
						AutoBalloonPart.Parent = workspace
					end
				end)
			else
				if AutoBalloonConnection then AutoBalloonConnection:Disconnect() end
				if AutoBalloonPart then
					AutoBalloonPart:Remove()
				end
			end
		end,
		HoverText = "Automatically Inflates Balloons"
	})
	AutoBalloonDelay = AutoBalloon.CreateSlider({
		Name = "Delay",
		Min = 1,
		Max = 50,
		Default = 20,
		Function = function() end,
		HoverText = "Delay to inflate balloons."
	})
	AutoBalloonLegit = AutoBalloon.CreateToggle({
		Name = "Legit Mode",
		Function = function() end,
		HoverText = "Switches to balloons in hotbar and inflates them."
	})
end)

local autobankapple = false
run(function()
	local AutoBuy = {Enabled = false}
	local AutoBuyArmor = {Enabled = false}
	local AutoBuySword = {Enabled = false}
	local AutoBuyGen = {Enabled = false}
	local AutoBuyProt = {Enabled = false}
	local AutoBuySharp = {Enabled = false}
	local AutoBuyDestruction = {Enabled = false}
	local AutoBuyDiamond = {Enabled = false}
	local AutoBuyAlarm = {Enabled = false}
	local AutoBuyGui = {Enabled = false}
	local AutoBuyTierSkip = {Enabled = true}
	local AutoBuyRange = {Value = 20}
	local AutoBuyCustom = {ObjectList = {}, RefreshList = function() end}
	local AutoBankUIToggle = {Enabled = false}
	local AutoBankDeath = {Enabled = false}
	local AutoBankStay = {Enabled = false}
	local buyingthing = false
	local shoothook
	local bedwarsshopnpcs = {}
	local id
	local armors = {
		[1] = "leather_chestplate",
		[2] = "iron_chestplate",
		[3] = "diamond_chestplate",
		[4] = "emerald_chestplate"
	}

	local swords = {
		[1] = "wood_sword",
		[2] = "stone_sword",
		[3] = "iron_sword",
		[4] = "diamond_sword",
		[5] = "emerald_sword"
	}

	local axes = {
		[1] = "wood_axe",
		[2] = "stone_axe",
		[3] = "iron_axe",
		[4] = "diamond_axe"
	}

	local pickaxes = {
		[1] = "wood_pickaxe",
		[2] = "stone_pickaxe",
		[3] = "iron_pickaxe",
		[4] = "diamond_pickaxe"
	}

	task.spawn(function()
		repeat task.wait() until store.matchState ~= 0 or not vapeInjected
		for i,v in pairs(collectionService:GetTagged("BedwarsItemShop")) do
			table.insert(bedwarsshopnpcs, {Position = v.Position, TeamUpgradeNPC = true, Id = v.Name})
		end
		for i,v in pairs(collectionService:GetTagged("TeamUpgradeShopkeeper")) do
			table.insert(bedwarsshopnpcs, {Position = v.Position, TeamUpgradeNPC = false, Id = v.Name})
		end
	end)

	local function nearNPC(range)
		local npc, npccheck, enchant, newid = nil, false, false, nil
		if entityLibrary.isAlive then
			local enchanttab = {}
			for i,v in pairs(collectionService:GetTagged("broken-enchant-table")) do
				table.insert(enchanttab, v)
			end
			for i,v in pairs(collectionService:GetTagged("enchant-table")) do
				table.insert(enchanttab, v)
			end
			for i,v in pairs(enchanttab) do
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= 6 then
					if ((not v:GetAttribute("Team")) or v:GetAttribute("Team") == lplr:GetAttribute("Team")) then
						npc, npccheck, enchant = true, true, true
					end
				end
			end
			for i, v in pairs(bedwarsshopnpcs) do
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= (range or 20) then
					npc, npccheck, enchant = true, (v.TeamUpgradeNPC or npccheck), false
					newid = v.TeamUpgradeNPC and v.Id or newid
				end
			end
			local suc, res = pcall(function() return lplr.leaderstats.Bed.Value == "✅"  end)
			if AutoBankDeath.Enabled and (workspace:GetServerTimeNow() - lplr.Character:GetAttribute("LastDamageTakenTime")) < 2 and suc and res then
				return nil, false, false
			end
			if AutoBankStay.Enabled then
				return nil, false, false
			end
		end
		return npc, not npccheck, enchant, newid
	end

	local function buyItem(itemtab, waitdelay)
		if not id then return end
		local res
		bedwars.Client:Get("BedwarsPurchaseItem"):CallServerAsync({
			shopItem = itemtab,
			shopId = id
		}):andThen(function(p11)
			if p11 then
				bedwars.SoundManager:playSound(bedwars.SoundList.BEDWARS_PURCHASE_ITEM)
				bedwars.ClientStoreHandler:dispatch({
					type = "BedwarsAddItemPurchased",
					itemType = itemtab.itemType
				})
			end
			res = p11
		end)
		if waitdelay then
			repeat task.wait() until res ~= nil
		end
	end

	local function getAxeNear(inv)
		for i5, v5 in pairs(inv or store.localInventory.inventory.items) do
			if v5.itemType:find("axe") and v5.itemType:find("pickaxe") == nil then
				return v5.itemType
			end
		end
		return nil
	end

	local function getPickaxeNear(inv)
		for i5, v5 in pairs(inv or store.localInventory.inventory.items) do
			if v5.itemType:find("pickaxe") then
				return v5.itemType
			end
		end
		return nil
	end

	local function getShopItem(itemType)
		if itemType == "axe" then
			itemType = getAxeNear() or "wood_axe"
			itemType = axes[table.find(axes, itemType) + 1] or itemType
		end
		if itemType == "pickaxe" then
			itemType = getPickaxeNear() or "wood_pickaxe"
			itemType = pickaxes[table.find(pickaxes, itemType) + 1] or itemType
		end
		for i,v in pairs(bedwars.ShopItems) do
			if v.itemType == itemType then return v end
		end
		return nil
	end

	local buyfunctions = {
		Armor = function(inv, upgrades, shoptype)
			if AutoBuyArmor.Enabled == false or shoptype ~= "item" then return end
			local currentarmor = (inv.armor[2] ~= "empty" and inv.armor[2].itemType:find("chestplate") ~= nil) and inv.armor[2] or nil
			local armorindex = (currentarmor and table.find(armors, currentarmor.itemType) or 0) + 1
			if armors[armorindex] == nil then return end
			local highestbuyable = nil
			for i = armorindex, #armors, 1 do
				local shopitem = getShopItem(armors[i])
				if shopitem and i == armorindex then
					local currency = getItem(shopitem.currency, inv.items)
					if currency and currency.amount >= shopitem.price then
						highestbuyable = shopitem
						bedwars.ClientStoreHandler:dispatch({
							type = "BedwarsAddItemPurchased",
							itemType = shopitem.itemType
						})
					end
				end
			end
			if highestbuyable and (highestbuyable.ignoredByKit == nil or table.find(highestbuyable.ignoredByKit, store.equippedKit) == nil) then
				buyItem(highestbuyable)
			end
		end,
		Sword = function(inv, upgrades, shoptype)
			if AutoBuySword.Enabled == false or shoptype ~= "item" then return end
			local currentsword = getItemNear("sword", inv.items)
			local swordindex = (currentsword and table.find(swords, currentsword.itemType) or 0) + 1
			if currentsword ~= nil and table.find(swords, currentsword.itemType) == nil then return end
			local highestbuyable = nil
			for i = swordindex, #swords, 1 do
				local shopitem = getShopItem(swords[i])
				if shopitem and i == swordindex then
					local currency = getItem(shopitem.currency, inv.items)
					if currency and currency.amount >= shopitem.price and (shopitem.category ~= "Armory" or upgrades.armory) then
						highestbuyable = shopitem
						bedwars.ClientStoreHandler:dispatch({
							type = "BedwarsAddItemPurchased",
							itemType = shopitem.itemType
						})
					end
				end
			end
			if highestbuyable and (highestbuyable.ignoredByKit == nil or table.find(highestbuyable.ignoredByKit, store.equippedKit) == nil) then
				buyItem(highestbuyable)
			end
		end
	}

	AutoBuy = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoBuy",
		Function = function(callback)
			if callback then
				buyingthing = false
				task.spawn(function()
					repeat
						task.wait()
						local found, npctype, enchant, newid = nearNPC(AutoBuyRange.Value)
						id = newid
						if found then
							local inv = store.localInventory.inventory
							local currentupgrades = bedwars.ClientStoreHandler:getState().Bedwars.teamUpgrades
							if store.equippedKit == "dasher" then
								swords = {
									[1] = "wood_dao",
									[2] = "stone_dao",
									[3] = "iron_dao",
									[4] = "diamond_dao",
									[5] = "emerald_dao"
								}
							elseif store.equippedKit == "ice_queen" then
								swords[5] = "ice_sword"
							elseif store.equippedKit == "ember" then
								swords[5] = "infernal_saber"
							elseif store.equippedKit == "lumen" then
								swords[5] = "light_sword"
							end
							if (AutoBuyGui.Enabled == false or (bedwars.AppController:isAppOpen("BedwarsItemShopApp") or bedwars.AppController:isAppOpen("BedwarsTeamUpgradeApp"))) and (not enchant) then
								for i,v in pairs(AutoBuyCustom.ObjectList) do
									local autobuyitem = v:split("/")
									if #autobuyitem >= 3 and autobuyitem[4] ~= "true" then
										local shopitem = getShopItem(autobuyitem[1])
										if shopitem then
											local currency = getItem(shopitem.currency, inv.items)
											local actualitem = getItem(shopitem.itemType == "wool_white" and getWool() or shopitem.itemType, inv.items)
											if currency and currency.amount >= shopitem.price and (actualitem == nil or actualitem.amount < tonumber(autobuyitem[2])) then
												buyItem(shopitem, tonumber(autobuyitem[2]) > 1)
											end
										end
									end
								end
								for i,v in pairs(buyfunctions) do v(inv, currentupgrades, npctype and "upgrade" or "item") end
								for i,v in pairs(AutoBuyCustom.ObjectList) do
									local autobuyitem = v:split("/")
									if #autobuyitem >= 3 and autobuyitem[4] == "true" then
										local shopitem = getShopItem(autobuyitem[1])
										if shopitem then
											local currency = getItem(shopitem.currency, inv.items)
											local actualitem = getItem(shopitem.itemType == "wool_white" and getWool() or shopitem.itemType, inv.items)
											if currency and currency.amount >= shopitem.price and (actualitem == nil or actualitem.amount < tonumber(autobuyitem[2])) then
												buyItem(shopitem, tonumber(autobuyitem[2]) > 1)
											end
										end
									end
								end
							end
						end
					until (not AutoBuy.Enabled)
				end)
			end
		end,
		HoverText = "Automatically Buys Swords, Armor, and Team Upgrades\nwhen you walk near the NPC"
	})
	AutoBuyRange = AutoBuy.CreateSlider({
		Name = "Range",
		Function = function() end,
		Min = 1,
		Max = 20,
		Default = 20
	})
	AutoBuyArmor = AutoBuy.CreateToggle({
		Name = "Buy Armor",
		Function = function() end,
		Default = true
	})
	AutoBuySword = AutoBuy.CreateToggle({
		Name = "Buy Sword",
		Function = function() end,
		Default = true
	})
	AutoBuyGui = AutoBuy.CreateToggle({
		Name = "Shop GUI Check",
		Function = function() end,
	})
	AutoBuyTierSkip = AutoBuy.CreateToggle({
		Name = "Tier Skip",
		Function = function() end,
		Default = true
	})
	AutoBuyCustom = AutoBuy.CreateTextList({
		Name = "BuyList",
		TempText = "item/amount/priority/after",
		SortFunction = function(a, b)
			local amount1 = a:split("/")
			local amount2 = b:split("/")
			amount1 = #amount1 and tonumber(amount1[3]) or 1
			amount2 = #amount2 and tonumber(amount2[3]) or 1
			return amount1 < amount2
		end
	})
	AutoBuyCustom.Object.AddBoxBKG.AddBox.TextSize = 14
end)

run(function()
	local AutoConsume = {Enabled = false}
	local AutoConsumeHealth = {Value = 100}
	local AutoConsumeSpeed = {Enabled = true}
	local AutoConsumeDelay = tick()

	local function AutoConsumeFunc()
		if entityLibrary.isAlive then
			local speedpotion = getItem("speed_potion")
			if lplr.Character:GetAttribute("Health") <= (lplr.Character:GetAttribute("MaxHealth") - (100 - AutoConsumeHealth.Value)) then
				autobankapple = true
				local item = getItem("apple")
				local pot = getItem("heal_splash_potion")
				if (item or pot) and AutoConsumeDelay <= tick() then
					if item then
						bedwars.Client:Get(bedwars.EatRemote):CallServerAsync({
							item = item.tool
						})
						AutoConsumeDelay = tick() + 0.6
					else
						local newray = workspace:Raycast((oldcloneroot or entityLibrary.character.HumanoidRootPart).Position, Vector3.new(0, -76, 0), store.blockRaycast)
						if newray ~= nil then
							bedwars.Client:Get(bedwars.ProjectileRemote):CallServerAsync(pot.tool, "heal_splash_potion", "heal_splash_potion", (oldcloneroot or entityLibrary.character.HumanoidRootPart).Position, (oldcloneroot or entityLibrary.character.HumanoidRootPart).Position, Vector3.new(0, -70, 0), game:GetService("HttpService"):GenerateGUID(), {drawDurationSeconds = 1})
						end
					end
				end
			else
				autobankapple = false
			end
			if speedpotion and (not lplr.Character:GetAttribute("StatusEffect_speed")) and AutoConsumeSpeed.Enabled then
				bedwars.Client:Get(bedwars.EatRemote):CallServerAsync({
					item = speedpotion.tool
				})
			end
			if lplr.Character:GetAttribute("Shield_POTION") and ((not lplr.Character:GetAttribute("Shield_POTION")) or lplr.Character:GetAttribute("Shield_POTION") == 0) then
				local shield = getItem("big_shield") or getItem("mini_shield")
				if shield then
					bedwars.Client:Get(bedwars.EatRemote):CallServerAsync({
						item = shield.tool
					})
				end
			end
		end
	end

	AutoConsume = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoConsume",
		Function = function(callback)
			if callback then
				table.insert(AutoConsume.Connections, vapeEvents.InventoryAmountChanged.Event:Connect(AutoConsumeFunc))
				table.insert(AutoConsume.Connections, vapeEvents.AttributeChanged.Event:Connect(function(changed)
					if changed:find("Shield") or changed:find("Health") or changed:find("speed") then
						AutoConsumeFunc()
					end
				end))
				AutoConsumeFunc()
			end
		end,
		HoverText = "Automatically heals for you when health or shield is under threshold."
	})
	AutoConsumeHealth = AutoConsume.CreateSlider({
		Name = "Health",
		Min = 1,
		Max = 99,
		Default = 70,
		Function = function() end
	})
	AutoConsumeSpeed = AutoConsume.CreateToggle({
		Name = "Speed Potions",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local AutoHotbarList = {Hotbars = {}, CurrentlySelected = 1}
	local AutoHotbarMode = {Value = "Toggle"}
	local AutoHotbarClear = {Enabled = false}
	local AutoHotbar = {Enabled = false}
	local AutoHotbarActive = false

	local function getCustomItem(v2)
		local realitem = v2.itemType
		if realitem == "swords" then
			local sword = getSword()
			realitem = sword and sword.itemType or "wood_sword"
		elseif realitem == "pickaxes" then
			local pickaxe = getPickaxe()
			realitem = pickaxe and pickaxe.itemType or "wood_pickaxe"
		elseif realitem == "axes" then
			local axe = getAxe()
			realitem = axe and axe.itemType or "wood_axe"
		elseif realitem == "bows" then
			local bow = getBow()
			realitem = bow and bow.itemType or "wood_bow"
		elseif realitem == "wool" then
			realitem = getWool() or "wool_white"
		end
		return realitem
	end

	local function findItemInTable(tab, item)
		for i, v in pairs(tab) do
			if v and v.itemType then
				if item.itemType == getCustomItem(v) then
					return i
				end
			end
		end
		return nil
	end

	local function findinhotbar(item)
		for i,v in pairs(store.localInventory.hotbar) do
			if v.item and v.item.itemType == item.itemType then
				return i, v.item
			end
		end
	end

	local function findininventory(item)
		for i,v in pairs(store.localInventory.inventory.items) do
			if v.itemType == item.itemType then
				return v
			end
		end
	end

	local function AutoHotbarSort()
		task.spawn(function()
			if AutoHotbarActive then return end
			AutoHotbarActive = true
			local items = (AutoHotbarList.Hotbars[AutoHotbarList.CurrentlySelected] and AutoHotbarList.Hotbars[AutoHotbarList.CurrentlySelected].Items or {})
			for i, v in pairs(store.localInventory.inventory.items) do
				local customItem
				local hotbarslot = findItemInTable(items, v)
				if hotbarslot then
					local oldhotbaritem = store.localInventory.hotbar[tonumber(hotbarslot)]
					if oldhotbaritem.item and oldhotbaritem.item.itemType == v.itemType then continue end
					if oldhotbaritem.item then
						bedwars.ClientStoreHandler:dispatch({
							type = "InventoryRemoveFromHotbar",
							slot = tonumber(hotbarslot) - 1
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
					local newhotbaritemslot, newhotbaritem = findinhotbar(v)
					if newhotbaritemslot then
						bedwars.ClientStoreHandler:dispatch({
							type = "InventoryRemoveFromHotbar",
							slot = newhotbaritemslot - 1
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
					if oldhotbaritem.item and newhotbaritemslot then
						local nextitem1, nextitem1num = findininventory(oldhotbaritem.item)
						bedwars.ClientStoreHandler:dispatch({
							type = "InventoryAddToHotbar",
							item = nextitem1,
							slot = newhotbaritemslot - 1
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
					local nextitem2, nextitem2num = findininventory(v)
					bedwars.ClientStoreHandler:dispatch({
						type = "InventoryAddToHotbar",
						item = nextitem2,
						slot = tonumber(hotbarslot) - 1
					})
					vapeEvents.InventoryChanged.Event:Wait()
				else
					if AutoHotbarClear.Enabled then
						local newhotbaritemslot, newhotbaritem = findinhotbar(v)
						if newhotbaritemslot then
							bedwars.ClientStoreHandler:dispatch({
								type = "InventoryRemoveFromHotbar",
								slot = newhotbaritemslot - 1
							})
							vapeEvents.InventoryChanged.Event:Wait()
						end
					end
				end
			end
			AutoHotbarActive = false
		end)
	end

	AutoHotbar = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoHotbar",
		Function = function(callback)
			if callback then
				AutoHotbarSort()
				if AutoHotbarMode.Value == "On Key" then
					if AutoHotbar.Enabled then
						AutoHotbar.ToggleButton(false)
					end
				else
					table.insert(AutoHotbar.Connections, vapeEvents.InventoryAmountChanged.Event:Connect(function()
						if not AutoHotbar.Enabled then return end
						AutoHotbarSort()
					end))
				end
			end
		end,
		HoverText = "Automatically arranges hotbar to your liking."
	})
	AutoHotbarMode = AutoHotbar.CreateDropdown({
		Name = "Activation",
		List = {"On Key", "Toggle"},
		Function = function(val)
			if AutoHotbar.Enabled then
				AutoHotbar.ToggleButton(false)
				AutoHotbar.ToggleButton(false)
			end
		end
	})
	AutoHotbarList = CreateAutoHotbarGUI(AutoHotbar.Children, {
		Name = "lol"
	})
	AutoHotbarClear = AutoHotbar.CreateToggle({
		Name = "Clear Hotbar",
		Function = function() end
	})
end)

run(function()
	local AutoKit = {Enabled = false}
	local AutoKitTrinity = {Value = "Void"}
	local oldfish
	local function GetTeammateThatNeedsMost()
		local plrs = GetAllNearestHumanoidToPosition(true, 30, 1000, true)
		local lowest, lowestplayer = 10000, nil
		for i,v in pairs(plrs) do
			if not v.Targetable then
				if v.Character:GetAttribute("Health") <= lowest and v.Character:GetAttribute("Health") < v.Character:GetAttribute("MaxHealth") then
					lowest = v.Character:GetAttribute("Health")
					lowestplayer = v
				end
			end
		end
		return lowestplayer
	end

	AutoKit = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoKit",
		Function = function(callback)
			if callback then
				oldfish = bedwars.FishermanController.startMinigame
				bedwars.FishermanController.startMinigame = function(Self, dropdata, func) func({win = true}) end
				task.spawn(function()
					repeat task.wait() until store.equippedKit ~= ""
					if AutoKit.Enabled then
						if store.equippedKit == "melody" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if getItem("guitar") then
										local plr = GetTeammateThatNeedsMost()
										if plr and healtick <= tick() then
											bedwars.Client:Get(bedwars.GuitarHealRemote):SendToServer({
												healTarget = plr.Character
											})
											healtick = tick() + 2
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "bigman" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged("treeOrb")
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and v:FindFirstChild("Spirit") and (entityLibrary.character.HumanoidRootPart.Position - v.Spirit.Position).magnitude <= 20 then
											if bedwars.Client:Get(bedwars.TreeRemote):CallServer({
												treeOrbSecret = v:GetAttribute("TreeOrbSecret")
											}) then
												v:Destroy()
												collectionService:RemoveTag(v, "treeOrb")
											end
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "metal_detector" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged("hidden-metal")
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and v.PrimaryPart and (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude <= 20 then
											bedwars.Client:Get(bedwars.PickupMetalRemote):SendToServer({
												id = v:GetAttribute("Id")
											})
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "battery" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = bedwars.BatteryEffectsController.liveBatteries
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and (entityLibrary.character.HumanoidRootPart.Position - v.position).magnitude <= 10 then
											bedwars.Client:Get(bedwars.BatteryRemote):SendToServer({
												batteryId = i
											})
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "grim_reaper" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = bedwars.GrimReaperController.soulsByPosition
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and lplr.Character:GetAttribute("Health") <= (lplr.Character:GetAttribute("MaxHealth") / 4) and v.PrimaryPart and (entityLibrary.character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude <= 120 and (not lplr.Character:GetAttribute("GrimReaperChannel")) then
											bedwars.Client:Get(bedwars.ConsumeSoulRemote):CallServer({
												secret = v:GetAttribute("GrimReaperSoulSecret")
											})
											v:Destroy()
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "farmer_cletus" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged("HarvestableCrop")
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and (entityLibrary.character.HumanoidRootPart.Position - v.Position).magnitude <= 10 then
											bedwars.Client:Get("CropHarvest"):CallServerAsync({
												position = bedwars.BlockController:getBlockPosition(v.Position)
											}):andThen(function(suc)
												if suc then
													bedwars.GameAnimationUtil.playAnimation(lplr.Character, 1)
													bedwars.SoundManager:playSound(bedwars.SoundList.CROP_HARVEST)
												end
											end)
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "pinata" then
							task.spawn(function()
								repeat
									task.wait()
									local itemdrops = collectionService:GetTagged(lplr.Name..':pinata')
									for i,v in pairs(itemdrops) do
										if entityLibrary.isAlive and getItem('candy') then
											bedwars.Client:Get(bedwars.PinataRemote):CallServer(v)
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "dragon_slayer" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if entityLibrary.isAlive then
										for i,v in pairs(bedwars.DragonSlayerController.dragonEmblems) do
											if v.stackCount >= 3 then
												bedwars.DragonSlayerController:deleteEmblem(i)
												local localPos = lplr.Character:GetPrimaryPartCFrame().Position
												local punchCFrame = CFrame.new(localPos, (i:GetPrimaryPartCFrame().Position * Vector3.new(1, 0, 1)) + Vector3.new(0, localPos.Y, 0))
												lplr.Character:SetPrimaryPartCFrame(punchCFrame)
												bedwars.DragonSlayerController:playPunchAnimation(punchCFrame - punchCFrame.Position)
												bedwars.Client:Get(bedwars.DragonRemote):SendToServer({
													target = i
												})
											end
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "mage" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if entityLibrary.isAlive then
										for i, v in pairs(collectionService:GetTagged("TomeGuidingBeam")) do
											local obj = v.Parent and v.Parent.Parent and v.Parent.Parent.Parent
											if obj and (entityLibrary.character.HumanoidRootPart.Position - obj.PrimaryPart.Position).Magnitude < 5 and obj:GetAttribute("TomeSecret") then
												local res = bedwars.Client:Get(bedwars.MageRemote):CallServer({
													secret = obj:GetAttribute("TomeSecret")
												})
												if res.success and res.element then
													bedwars.GameAnimationUtil.playAnimation(lplr, bedwars.AnimationType.PUNCH)
													bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
													bedwars.MageController:destroyTomeGuidingBeam()
													bedwars.MageController:playLearnLightBeamEffect(lplr, obj)
													local sound = bedwars.MageKitUtil.MageElementVisualizations[res.element].learnSound
													if sound and sound ~= "" then
														bedwars.SoundManager:playSound(sound)
													end
													task.delay(bedwars.BalanceFile.LEARN_TOME_DURATION, function()
														bedwars.MageController:fadeOutTome(obj)
														if lplr.Character and res.element then
															bedwars.MageKitUtil.changeMageKitAppearance(lplr, lplr.Character, res.element)
														end
													end)
												end
											end
										end
									end
								until (not AutoKit.Enabled)
							end)
						elseif store.equippedKit == "angel" then
							table.insert(AutoKit.Connections, vapeEvents.AngelProgress.Event:Connect(function(angelTable)
								task.wait(0.5)
								if not AutoKit.Enabled then return end
								if bedwars.ClientStoreHandler:getState().Kit.angelProgress >= 1 and lplr.Character:GetAttribute("AngelType") == nil then
									bedwars.Client:Get(bedwars.TrinityRemote):SendToServer({
										angel = AutoKitTrinity.Value
									})
								end
							end))
						elseif store.equippedKit == "miner" then
							task.spawn(function()
								repeat
									task.wait(0.1)
									if entityLibrary.isAlive then
										for i,v in pairs(collectionService:GetTagged("petrified-player")) do
											bedwars.Client:Get(bedwars.MinerRemote):SendToServer({
												petrifyId = v:GetAttribute("PetrifyId")
											})
										end
									end
								until (not AutoKit.Enabled)
							end)
						end
					end
				end)
			else
				bedwars.FishermanController.startMinigame = oldfish
				oldfish = nil
			end
		end,
		HoverText = "Automatically uses a kits ability"
	})
	AutoKitTrinity = AutoKit.CreateDropdown({
		Name = "Angel",
		List = {"Void", "Light"},
		Function = function() end
	})
end)

run(function()
	local AutoForge = {Enabled = false}
	local AutoForgeWeapon = {Value = "Sword"}
	local AutoForgeBow = {Enabled = false}
	local AutoForgeArmor = {Enabled = false}
	local AutoForgeSword = {Enabled = false}
	local AutoForgeBuyAfter = {Enabled = false}
	local AutoForgeNotification = {Enabled = true}

	local function buyForge(i)
		if not store.forgeUpgrades[i] or store.forgeUpgrades[i] < 6 then
			local cost = bedwars.ForgeUtil:getUpgradeCost(1, store.forgeUpgrades[i] or 0)
			if store.forgeMasteryPoints >= cost then
				if AutoForgeNotification.Enabled then
					local forgeType = "none"
					for name,v in pairs(bedwars.ForgeConstants) do
						if v == i then forgeType = name:lower() end
					end
					warningNotification("AutoForge", "Purchasing "..forgeType..".", bedwars.ForgeUtil.FORGE_DURATION_SEC)
				end
				bedwars.Client:Get("ForgePurchaseUpgrade"):SendToServer(i)
				task.wait(bedwars.ForgeUtil.FORGE_DURATION_SEC + 0.2)
			end
		end
	end

	AutoForge = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoForge",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						if store.matchState == 1 and entityLibrary.isAlive then
							if entityLibrary.character.HumanoidRootPart.Velocity.Magnitude > 0.01 then continue end
							if AutoForgeArmor.Enabled then buyForge(bedwars.ForgeConstants.ARMOR) end
							if entityLibrary.character.HumanoidRootPart.Velocity.Magnitude > 0.01 then continue end
							if AutoForgeBow.Enabled then buyForge(bedwars.ForgeConstants.RANGED) end
							if entityLibrary.character.HumanoidRootPart.Velocity.Magnitude > 0.01 then continue end
							if AutoForgeSword.Enabled then
								if AutoForgeBuyAfter.Enabled then
									if not store.forgeUpgrades[bedwars.ForgeConstants.ARMOR] or store.forgeUpgrades[bedwars.ForgeConstants.ARMOR] < 6 then continue end
								end
								local weapon = bedwars.ForgeConstants[AutoForgeWeapon.Value:upper()]
								if weapon then buyForge(weapon) end
							end
						end
					until (not AutoForge.Enabled)
				end)
			end
		end
	})
	AutoForgeWeapon = AutoForge.CreateDropdown({
		Name = "Weapon",
		Function = function() end,
		List = {"Sword", "Dagger", "Scythe", "Great_Hammer", "Gauntlets"}
	})
	AutoForgeArmor = AutoForge.CreateToggle({
		Name = "Armor",
		Function = function() end,
		Default = true
	})
	AutoForgeSword = AutoForge.CreateToggle({
		Name = "Weapon",
		Function = function() end
	})
	AutoForgeBow = AutoForge.CreateToggle({
		Name = "Bow",
		Function = function() end
	})
	AutoForgeBuyAfter = AutoForge.CreateToggle({
		Name = "Buy After",
		Function = function() end,
		HoverText = "buy a weapon after armor is maxed"
	})
	AutoForgeNotification = AutoForge.CreateToggle({
		Name = "Notification",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local alreadyreportedlist = {}
	local AutoReportV2 = {Enabled = false}
	local AutoReportV2Notify = {Enabled = false}
	AutoReportV2 = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoReportV2",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						for i,v in pairs(playersService:GetPlayers()) do
							if v ~= lplr and alreadyreportedlist[v] == nil and v:GetAttribute("PlayerConnected") and whitelist:get(v) == 0 then
								task.wait(1)
								alreadyreportedlist[v] = true
								bedwars.Client:Get(bedwars.ReportRemote):SendToServer(v.UserId)
								store.statistics.reported = store.statistics.reported + 1
								if AutoReportV2Notify.Enabled then
									warningNotification("AutoReportV2", "Reported "..v.Name, 15)
								end
							end
						end
					until (not AutoReportV2.Enabled)
				end)
			end
		end,
		HoverText = "dv mald"
	})
	AutoReportV2Notify = AutoReportV2.CreateToggle({
		Name = "Notify",
		Function = function() end
	})
end)

run(function()
	local justsaid = ""
	local leavesaid = false
	local alreadyreported = {}

	local function removerepeat(str)
		local newstr = ""
		local lastlet = ""
		for i,v in pairs(str:split("")) do
			if v ~= lastlet then
				newstr = newstr..v
				lastlet = v
			end
		end
		return newstr
	end

	local reporttable = {
		gay = "Bullying",
		gae = "Bullying",
		gey = "Bullying",
		hack = "Scamming",
		exploit = "Scamming",
		cheat = "Scamming",
		hecker = "Scamming",
		haxker = "Scamming",
		hacer = "Scamming",
		report = "Bullying",
		fat = "Bullying",
		black = "Bullying",
		getalife = "Bullying",
		fatherless = "Bullying",
		report = "Bullying",
		fatherless = "Bullying",
		disco = "Offsite Links",
		yt = "Offsite Links",
		dizcourde = "Offsite Links",
		retard = "Swearing",
		bad = "Bullying",
		trash = "Bullying",
		nolife = "Bullying",
		nolife = "Bullying",
		loser = "Bullying",
		killyour = "Bullying",
		kys = "Bullying",
		hacktowin = "Bullying",
		bozo = "Bullying",
		kid = "Bullying",
		adopted = "Bullying",
		linlife = "Bullying",
		commitnotalive = "Bullying",
		vape = "Offsite Links",
		futureclient = "Offsite Links",
		download = "Offsite Links",
		youtube = "Offsite Links",
		die = "Bullying",
		lobby = "Bullying",
		ban = "Bullying",
		wizard = "Bullying",
		wisard = "Bullying",
		witch = "Bullying",
		magic = "Bullying",
	}
	local reporttableexact = {
		L = "Bullying",
	}


	local function findreport(msg)
		local checkstr = removerepeat(msg:gsub("%W+", ""):lower())
		for i,v in pairs(reporttable) do
			if checkstr:find(i) then
				return v, i
			end
		end
		for i,v in pairs(reporttableexact) do
			if checkstr == i then
				return v, i
			end
		end
		for i,v in pairs(AutoToxicPhrases5.ObjectList) do
			if checkstr:find(v) then
				return "Bullying", v
			end
		end
		return nil
	end

	AutoToxic = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoToxic",
		Function = function(callback)
			if callback then
				table.insert(AutoToxic.Connections, vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
					if AutoToxicBedDestroyed.Enabled and bedTable.brokenBedTeam.id == lplr:GetAttribute("Team") then
						local custommsg = #AutoToxicPhrases6.ObjectList > 0 and AutoToxicPhrases6.ObjectList[math.random(1, #AutoToxicPhrases6.ObjectList)] or "How dare you break my bed >:( <name> | vxpe on top"
						if custommsg then
							custommsg = custommsg:gsub("<name>", (bedTable.player.DisplayName or bedTable.player.Name))
						end
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
						end
					elseif AutoToxicBedBreak.Enabled and bedTable.player.UserId == lplr.UserId then
						local custommsg = #AutoToxicPhrases7.ObjectList > 0 and AutoToxicPhrases7.ObjectList[math.random(1, #AutoToxicPhrases7.ObjectList)] or "nice bed <teamname> | vxpe on top"
						if custommsg then
							local team = bedwars.QueueMeta[store.queueType].teams[tonumber(bedTable.brokenBedTeam.id)]
							local teamname = team and team.displayName:lower() or "white"
							custommsg = custommsg:gsub("<teamname>", teamname)
						end
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
						end
					end
				end))
				table.insert(AutoToxic.Connections, vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill then
						local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
						local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
						if not killed or not killer then return end
						if killed == lplr then
							if (not leavesaid) and killer ~= lplr and AutoToxicDeath.Enabled then
								leavesaid = true
								local custommsg = #AutoToxicPhrases3.ObjectList > 0 and AutoToxicPhrases3.ObjectList[math.random(1, #AutoToxicPhrases3.ObjectList)] or "My gaming chair expired midfight, thats why you won <name> | vxpe on top"
								if custommsg then
									custommsg = custommsg:gsub("<name>", (killer.DisplayName or killer.Name))
								end
								if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
									textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
								else
									replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
								end
							end
						else
							if killer == lplr and AutoToxicFinalKill.Enabled then
								local custommsg = #AutoToxicPhrases2.ObjectList > 0 and AutoToxicPhrases2.ObjectList[math.random(1, #AutoToxicPhrases2.ObjectList)] or "L <name> | vxpe on top"
								if custommsg == lastsaid then
									custommsg = #AutoToxicPhrases2.ObjectList > 0 and AutoToxicPhrases2.ObjectList[math.random(1, #AutoToxicPhrases2.ObjectList)] or "L <name> | vxpe on top"
								else
									lastsaid = custommsg
								end
								if custommsg then
									custommsg = custommsg:gsub("<name>", (killed.DisplayName or killed.Name))
								end
								if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
									textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
								else
									replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
								end
							end
						end
					end
				end))
				table.insert(AutoToxic.Connections, vapeEvents.MatchEndEvent.Event:Connect(function(winstuff)
					local myTeam = bedwars.ClientStoreHandler:getState().Game.myTeam
					if myTeam and myTeam.id == winstuff.winningTeamId or lplr.Neutral then
						if AutoToxicGG.Enabled then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync("gg")
							if shared.ggfunction then
								shared.ggfunction()
							end
						end
						if AutoToxicWin.Enabled then
							local custommsg = #AutoToxicPhrases.ObjectList > 0 and AutoToxicPhrases.ObjectList[math.random(1, #AutoToxicPhrases.ObjectList)] or "EZ L TRASH KIDS | vxpe on top"
							if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
								textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
							else
								replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
							end
						end
					end
				end))
				table.insert(AutoToxic.Connections, vapeEvents.LagbackEvent.Event:Connect(function(plr)
					if AutoToxicLagback.Enabled then
						local custommsg = #AutoToxicPhrases8.ObjectList > 0 and AutoToxicPhrases8.ObjectList[math.random(1, #AutoToxicPhrases8.ObjectList)]
						if custommsg then
							custommsg = custommsg:gsub("<name>", (plr.DisplayName or plr.Name))
						end
						local msg = custommsg or "Imagine lagbacking L "..(plr.DisplayName or plr.Name).." | vxpe on top"
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, 'All')
						end
					end
				end))
				table.insert(AutoToxic.Connections, textChatService.MessageReceived:Connect(function(tab)
					if AutoToxicRespond.Enabled then
						local plr = playersService:GetPlayerByUserId(tab.TextSource.UserId)
						local args = tab.Text:split(" ")
						if plr and plr ~= lplr and not alreadyreported[plr] then
							local reportreason, reportedmatch = findreport(tab.Text)
							if reportreason then
								alreadyreported[plr] = true
								local custommsg = #AutoToxicPhrases4.ObjectList > 0 and AutoToxicPhrases4.ObjectList[math.random(1, #AutoToxicPhrases4.ObjectList)]
								if custommsg then
									custommsg = custommsg:gsub("<name>", (plr.DisplayName or plr.Name))
								end
								local msg = custommsg or "I don't care about the fact that I'm hacking, I care about you dying in a block game. L "..(plr.DisplayName or plr.Name).." | vxpe on top"
								if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
									textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
								else
									replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, 'All')
								end
							end
						end
					end
				end))
			end
		end
	})
	AutoToxicGG = AutoToxic.CreateToggle({
		Name = "AutoGG",
		Function = function() end,
		Default = true
	})
	AutoToxicWin = AutoToxic.CreateToggle({
		Name = "Win",
		Function = function() end,
		Default = true
	})
	AutoToxicDeath = AutoToxic.CreateToggle({
		Name = "Death",
		Function = function() end,
		Default = true
	})
	AutoToxicBedBreak = AutoToxic.CreateToggle({
		Name = "Bed Break",
		Function = function() end,
		Default = true
	})
	AutoToxicBedDestroyed = AutoToxic.CreateToggle({
		Name = "Bed Destroyed",
		Function = function() end,
		Default = true
	})
	AutoToxicRespond = AutoToxic.CreateToggle({
		Name = "Respond",
		Function = function() end,
		Default = true
	})
	AutoToxicFinalKill = AutoToxic.CreateToggle({
		Name = "Final Kill",
		Function = function() end,
		Default = true
	})
	AutoToxicTeam = AutoToxic.CreateToggle({
		Name = "Teammates",
		Function = function() end,
	})
	AutoToxicLagback = AutoToxic.CreateToggle({
		Name = "Lagback",
		Function = function() end,
		Default = true
	})
	AutoToxicPhrases = AutoToxic.CreateTextList({
		Name = "ToxicList",
		TempText = "phrase (win)",
	})
	AutoToxicPhrases2 = AutoToxic.CreateTextList({
		Name = "ToxicList2",
		TempText = "phrase (kill) <name>",
	})
	AutoToxicPhrases3 = AutoToxic.CreateTextList({
		Name = "ToxicList3",
		TempText = "phrase (death) <name>",
	})
	AutoToxicPhrases7 = AutoToxic.CreateTextList({
		Name = "ToxicList7",
		TempText = "phrase (bed break) <teamname>",
	})
	AutoToxicPhrases7.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases6 = AutoToxic.CreateTextList({
		Name = "ToxicList6",
		TempText = "phrase (bed destroyed) <name>",
	})
	AutoToxicPhrases6.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases4 = AutoToxic.CreateTextList({
		Name = "ToxicList4",
		TempText = "phrase (text to respond with) <name>",
	})
	AutoToxicPhrases4.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases5 = AutoToxic.CreateTextList({
		Name = "ToxicList5",
		TempText = "phrase (text to respond to)",
	})
	AutoToxicPhrases5.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases8 = AutoToxic.CreateTextList({
		Name = "ToxicList8",
		TempText = "phrase (lagback) <name>",
	})
	AutoToxicPhrases8.Object.AddBoxBKG.AddBox.TextSize = 12
end)

run(function()
	local ChestStealer = {Enabled = false}
	local ChestStealerDistance = {Value = 1}
	local ChestStealerDelay = {Value = 1}
	local ChestStealerOpen = {Enabled = false}
	local ChestStealerSkywars = {Enabled = true}
	local cheststealerdelays = {}
	local cheststealerfuncs = {
		Open = function()
			if bedwars.AppController:isAppOpen("ChestApp") then
				local chest = lplr.Character:FindFirstChild("ObservedChestFolder")
				local chestitems = chest and chest.Value and chest.Value:GetChildren() or {}
				if #chestitems > 0 then
					for i3,v3 in pairs(chestitems) do
						if v3:IsA("Accessory") and (cheststealerdelays[v3] == nil or cheststealerdelays[v3] < tick()) then
							task.spawn(function()
								pcall(function()
									cheststealerdelays[v3] = tick() + 0.2
									bedwars.Client:GetNamespace("Inventory"):Get("ChestGetItem"):CallServer(chest.Value, v3)
								end)
							end)
							task.wait(ChestStealerDelay.Value / 100)
						end
					end
				end
			end
		end,
		Closed = function()
			for i, v in pairs(collectionService:GetTagged("chest")) do
				if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= ChestStealerDistance.Value then
					local chest = v:FindFirstChild("ChestFolderValue")
					chest = chest and chest.Value or nil
					local chestitems = chest and chest:GetChildren() or {}
					if #chestitems > 0 then
						bedwars.Client:GetNamespace("Inventory"):Get("SetObservedChest"):SendToServer(chest)
						for i3,v3 in pairs(chestitems) do
							if v3:IsA("Accessory") then
								task.spawn(function()
									pcall(function()
										bedwars.Client:GetNamespace("Inventory"):Get("ChestGetItem"):CallServer(v.ChestFolderValue.Value, v3)
									end)
								end)
								task.wait(ChestStealerDelay.Value / 100)
							end
						end
						bedwars.Client:GetNamespace("Inventory"):Get("SetObservedChest"):SendToServer(nil)
					end
				end
			end
		end
	}

	ChestStealer = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "ChestStealer",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait() until store.queueType ~= "bedwars_test"
					if (not ChestStealerSkywars.Enabled) or store.queueType:find("skywars") then
						repeat
							task.wait(0.1)
							if entityLibrary.isAlive then
								cheststealerfuncs[ChestStealerOpen.Enabled and "Open" or "Closed"]()
							end
						until (not ChestStealer.Enabled)
					end
				end)
			end
		end,
		HoverText = "Grabs items from near chests."
	})
	ChestStealerDistance = ChestStealer.CreateSlider({
		Name = "Range",
		Min = 0,
		Max = 18,
		Function = function() end,
		Default = 18
	})
	ChestStealerDelay = ChestStealer.CreateSlider({
		Name = "Delay",
		Min = 1,
		Max = 50,
		Function = function() end,
		Default = 1,
		Double = 100
	})
	ChestStealerOpen = ChestStealer.CreateToggle({
		Name = "GUI Check",
		Function = function() end
	})
	ChestStealerSkywars = ChestStealer.CreateToggle({
		Name = "Only Skywars",
		Function = function() end,
		Default = true
	})
end)

run(function()
	local FastDrop = {Enabled = false}
	FastDrop = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "FastDrop",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait()
						if entityLibrary.isAlive and (not store.localInventory.opened) and (inputService:IsKeyDown(Enum.KeyCode.Q) or inputService:IsKeyDown(Enum.KeyCode.Backspace)) and inputService:GetFocusedTextBox() == nil then
							task.spawn(bedwars.DropItem)
						end
					until (not FastDrop.Enabled)
				end)
			end
		end,
		HoverText = "Drops items fast when you hold Q"
	})
end)

run(function()
	local MissileTP = {Enabled = false}
	local MissileTeleportDelaySlider = {Value = 30}
	MissileTP = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "MissileTP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if getItem("guided_missile") then
						local plr = EntityNearMouse(1000)
						if plr then
							local projectile = bedwars.RuntimeLib.await(bedwars.GuidedProjectileController.fireGuidedProjectile:CallServerAsync("guided_missile"))
							if projectile then
								local projectilemodel = projectile.model
								if not projectilemodel.PrimaryPart then
									projectilemodel:GetPropertyChangedSignal("PrimaryPart"):Wait()
								end;
								local bodyforce = Instance.new("BodyForce")
								bodyforce.Force = Vector3.new(0, projectilemodel.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
								bodyforce.Name = "AntiGravity"
								bodyforce.Parent = projectilemodel.PrimaryPart

								repeat
									task.wait()
									if projectile.model then
										if plr then
											projectile.model:SetPrimaryPartCFrame(CFrame.new(plr.RootPart.CFrame.p, plr.RootPart.CFrame.p + gameCamera.CFrame.lookVector))
										else
											warningNotification("MissileTP", "Player died before it could TP.", 3)
											break
										end
									end
								until projectile.model.Parent == nil
							else
								warningNotification("MissileTP", "Missile on cooldown.", 3)
							end
						else
							warningNotification("MissileTP", "Player not found.", 3)
						end
					else
						warningNotification("MissileTP", "Missile not found.", 3)
					end
				end)
				MissileTP.ToggleButton(true)
			end
		end,
		HoverText = "Spawns and teleports a missile to a player\nnear your mouse."
	})
end)

run(function()
	local PickupRangeRange = {Value = 1}
	local PickupRange = {Enabled = false}
	PickupRange = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "PickupRange",
		Function = function(callback)
			if callback then
				local pickedup = {}
				task.spawn(function()
					repeat
						local itemdrops = collectionService:GetTagged("ItemDrop")
						for i,v in pairs(itemdrops) do
							if entityLibrary.isAlive and (v:GetAttribute("ClientDropTime") and tick() - v:GetAttribute("ClientDropTime") > 2 or v:GetAttribute("ClientDropTime") == nil) then
								if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - v.Position).magnitude <= PickupRangeRange.Value and (pickedup[v] == nil or pickedup[v] <= tick()) then
									task.spawn(function()
										pickedup[v] = tick() + 0.2
										bedwars.Client:Get(bedwars.PickupRemote):CallServerAsync({
											itemDrop = v
										}):andThen(function(suc)
											if suc then
												bedwars.SoundManager:playSound(bedwars.SoundList.PICKUP_ITEM_DROP)
											end
										end)
									end)
								end
							end
						end
						task.wait()
					until (not PickupRange.Enabled)
				end)
			end
		end
	})
	PickupRangeRange = PickupRange.CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 10,
		Function = function() end,
		Default = 10
	})
end)

run(function()
	local RavenTP = {Enabled = false}
	RavenTP = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "RavenTP",
		Function = function(callback)
			if callback then
				task.spawn(function()
					if getItem("raven") then
						local plr = EntityNearMouse(1000)
						if plr then
							local projectile = bedwars.Client:Get(bedwars.SpawnRavenRemote):CallServerAsync():andThen(function(projectile)
								if projectile then
									local projectilemodel = projectile
									if not projectilemodel then
										projectilemodel:GetPropertyChangedSignal("PrimaryPart"):Wait()
									end
									local bodyforce = Instance.new("BodyForce")
									bodyforce.Force = Vector3.new(0, projectilemodel.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
									bodyforce.Name = "AntiGravity"
									bodyforce.Parent = projectilemodel.PrimaryPart

									if plr then
										projectilemodel:SetPrimaryPartCFrame(CFrame.new(plr.RootPart.CFrame.p, plr.RootPart.CFrame.p + gameCamera.CFrame.lookVector))
										task.wait(0.3)
										bedwars.RavenController:detonateRaven()
									else
										warningNotification("RavenTP", "Player died before it could TP.", 3)
									end
								else
									warningNotification("RavenTP", "Raven on cooldown.", 3)
								end
							end)
						else
							warningNotification("RavenTP", "Player not found.", 3)
						end
					else
						warningNotification("RavenTP", "Raven not found.", 3)
					end
				end)
				RavenTP.ToggleButton(true)
			end
		end,
		HoverText = "Spawns and teleports a raven to a player\nnear your mouse."
	})
end)

run(function()
	local tiered = {}
	local nexttier = {}

	for i,v in pairs(bedwars.ShopItems) do
		if type(v) == "table" then
			if v.tiered then
				tiered[v.itemType] = v.tiered
			end
			if v.nextTier then
				nexttier[v.itemType] = v.nextTier
			end
		end
	end

	GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "ShopTierBypass",
		Function = function(callback)
			if callback then
				for i,v in pairs(bedwars.ShopItems) do
					if type(v) == "table" then
						v.tiered = nil
						v.nextTier = nil
					end
				end
			else
				for i,v in pairs(bedwars.ShopItems) do
					if type(v) == "table" then
						if tiered[v.itemType] then
							v.tiered = tiered[v.itemType]
						end
						if nexttier[v.itemType] then
							v.nextTier = nexttier[v.itemType]
						end
					end
				end
			end
		end,
		HoverText = "Allows you to access tiered items early."
	})
end)

local lagbackedaftertouch = false
run(function()
	local AntiVoidPart
	local AntiVoidConnection
	local AntiVoidMode = {Value = "Normal"}
	local AntiVoidMoveMode = {Value = "Normal"}
	local AntiVoid = {Enabled = false}
	local AntiVoidTransparent = {Value = 50}
	local AntiVoidColor = {Hue = 1, Sat = 1, Value = 0.55}
	local lastvalidpos

	local function closestpos(block)
		local startpos = block.Position - (block.Size / 2) + Vector3.new(1.5, 1.5, 1.5)
		local endpos = block.Position + (block.Size / 2) - Vector3.new(1.5, 1.5, 1.5)
		local newpos = block.Position + (entityLibrary.character.HumanoidRootPart.Position - block.Position)
		return Vector3.new(math.clamp(newpos.X, startpos.X, endpos.X), endpos.Y + 3, math.clamp(newpos.Z, startpos.Z, endpos.Z))
	end

	local function getclosesttop(newmag)
		local closest, closestmag = nil, newmag * 3
		if entityLibrary.isAlive then
			local tops = {}
			for i,v in pairs(store.blocks) do
				local close = getScaffold(closestpos(v), false)
				if getPlacedBlock(close) then continue end
				if close.Y < entityLibrary.character.HumanoidRootPart.Position.Y then continue end
				if (close - entityLibrary.character.HumanoidRootPart.Position).magnitude <= newmag * 3 then
					table.insert(tops, close)
				end
			end
			for i,v in pairs(tops) do
				local mag = (v - entityLibrary.character.HumanoidRootPart.Position).magnitude
				if mag <= closestmag then
					closest = v
					closestmag = mag
				end
			end
		end
		return closest
	end

	local antivoidypos = 0
	local antivoiding = false
	AntiVoid = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "AntiVoid",
		Function = function(callback)
			if callback then
				task.spawn(function()
					AntiVoidPart = Instance.new("Part")
					AntiVoidPart.CanCollide = AntiVoidMode.Value == "Collide"
					AntiVoidPart.Size = Vector3.new(10000, 1, 10000)
					AntiVoidPart.Anchored = true
					AntiVoidPart.Material = Enum.Material.Neon
					AntiVoidPart.Color = Color3.fromHSV(AntiVoidColor.Hue, AntiVoidColor.Sat, AntiVoidColor.Value)
					AntiVoidPart.Transparency = 1 - (AntiVoidTransparent.Value / 100)
					AntiVoidPart.Position = Vector3.new(0, antivoidypos, 0)
					AntiVoidPart.Parent = workspace
					if AntiVoidMoveMode.Value == "Classic" and antivoidypos == 0 then
						AntiVoidPart.Parent = nil
					end
					AntiVoidConnection = AntiVoidPart.Touched:Connect(function(touchedpart)
						if touchedpart.Parent == lplr.Character and entityLibrary.isAlive then
							if (not antivoiding) and (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) and entityLibrary.character.Humanoid.Health > 0 and AntiVoidMode.Value ~= "Collide" then
								if AntiVoidMode.Value == "Velocity" then
									entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(entityLibrary.character.HumanoidRootPart.Velocity.X, 100, entityLibrary.character.HumanoidRootPart.Velocity.Z)
								else
									antivoiding = true
									local pos = getclosesttop(1000)
									if pos then
										local lastTeleport = lplr:GetAttribute("LastTeleported")
										RunLoops:BindToHeartbeat("AntiVoid", function(dt)
											if entityLibrary.isAlive and entityLibrary.character.Humanoid.Health > 0 and isnetworkowner(entityLibrary.character.HumanoidRootPart) and (entityLibrary.character.HumanoidRootPart.Position - pos).Magnitude > 1 and AntiVoid.Enabled and lplr:GetAttribute("LastTeleported") == lastTeleport then
												local hori1 = Vector3.new(entityLibrary.character.HumanoidRootPart.Position.X, 0, entityLibrary.character.HumanoidRootPart.Position.Z)
												local hori2 = Vector3.new(pos.X, 0, pos.Z)
												local newpos = (hori2 - hori1).Unit
												local realnewpos = CFrame.new(newpos == newpos and entityLibrary.character.HumanoidRootPart.CFrame.p + (newpos * ((3 + getSpeed()) * dt)) or Vector3.zero)
												entityLibrary.character.HumanoidRootPart.CFrame = CFrame.new(realnewpos.p.X, pos.Y, realnewpos.p.Z)
												antivoidvelo = newpos == newpos and newpos * 20 or Vector3.zero
												entityLibrary.character.HumanoidRootPart.Velocity = Vector3.new(antivoidvelo.X, entityLibrary.character.HumanoidRootPart.Velocity.Y, antivoidvelo.Z)
												if getPlacedBlock((entityLibrary.character.HumanoidRootPart.CFrame.p - Vector3.new(0, 1, 0)) + entityLibrary.character.HumanoidRootPart.Velocity.Unit) or getPlacedBlock(entityLibrary.character.HumanoidRootPart.CFrame.p + Vector3.new(0, 3)) then
													pos = pos + Vector3.new(0, 1, 0)
												end
											else
												RunLoops:UnbindFromHeartbeat("AntiVoid")
												antivoidvelo = nil
												antivoiding = false
											end
										end)
									else
										entityLibrary.character.HumanoidRootPart.CFrame += Vector3.new(0, 100000, 0)
										antivoiding = false
									end
								end
							end
						end
					end)
					repeat
						if entityLibrary.isAlive and AntiVoidMoveMode.Value == "Normal" then
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(0, -1000, 0), store.blockRaycast)
							if ray or GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled or GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled then
								AntiVoidPart.Position = entityLibrary.character.HumanoidRootPart.Position - Vector3.new(0, 21, 0)
							end
						end
						task.wait()
					until (not AntiVoid.Enabled)
				end)
			else
				if AntiVoidConnection then AntiVoidConnection:Disconnect() end
				if AntiVoidPart then
					AntiVoidPart:Destroy()
				end
			end
		end,
		HoverText = "Gives you a chance to get on land (Bouncing Twice, abusing, or bad luck will lead to lagbacks)"
	})
	AntiVoidMoveMode = AntiVoid.CreateDropdown({
		Name = "Position Mode",
		Function = function(val)
			if val == "Classic" then
				task.spawn(function()
					repeat task.wait() until store.matchState ~= 0 or not vapeInjected
					if vapeInjected and AntiVoidMoveMode.Value == "Classic" and antivoidypos == 0 and AntiVoid.Enabled then
						local lowestypos = 99999
						for i,v in pairs(store.blocks) do
							local newray = workspace:Raycast(v.Position + Vector3.new(0, 800, 0), Vector3.new(0, -1000, 0), store.blockRaycast)
							if i % 200 == 0 then
								task.wait(0.06)
							end
							if newray and newray.Position.Y <= lowestypos then
								lowestypos = newray.Position.Y
							end
						end
						antivoidypos = lowestypos - 8
					end
					if AntiVoidPart then
						AntiVoidPart.Position = Vector3.new(0, antivoidypos, 0)
						AntiVoidPart.Parent = workspace
					end
				end)
			end
		end,
		List = {"Normal", "Classic"}
	})
	AntiVoidMode = AntiVoid.CreateDropdown({
		Name = "Move Mode",
		Function = function(val)
			if AntiVoidPart then
				AntiVoidPart.CanCollide = val == "Collide"
			end
		end,
		List = {"Normal", "Collide", "Velocity"}
	})
	AntiVoidTransparent = AntiVoid.CreateSlider({
		Name = "Invisible",
		Min = 1,
		Max = 100,
		Default = 50,
		Function = function(val)
			if AntiVoidPart then
				AntiVoidPart.Transparency = 1 - (val / 100)
			end
		end,
	})
	AntiVoidColor = AntiVoid.CreateColorSlider({
		Name = "Color",
		Function = function(h, s, v)
			if AntiVoidPart then
				AntiVoidPart.Color = Color3.fromHSV(h, s, v)
			end
		end
	})
end)

run(function()
	local oldhitblock

	local AutoTool = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "AutoTool",
		Function = function(callback)
			if callback then
				oldhitblock = bedwars.BlockBreaker.hitBlock
				bedwars.BlockBreaker.hitBlock = function(self, maid, raycastparams, ...)
					if (GuiLibrary.ObjectsThatCanBeSaved["Lobby CheckToggle"].Api.Enabled == false or store.matchState ~= 0) then
						local block = self.clientManager:getBlockSelector():getMouseInfo(1, {ray = raycastparams})
						if block and block.target and not block.target.blockInstance:GetAttribute("NoBreak") and not block.target.blockInstance:GetAttribute("Team"..(lplr:GetAttribute("Team") or 0).."NoBreak") then
							if switchToAndUseTool(block.target.blockInstance, true) then return end
						end
					end
					return oldhitblock(self, maid, raycastparams, ...)
				end
			else
				bedwars.BlockBreaker.hitBlock = oldhitblock
				oldhitblock = nil
			end
		end,
		HoverText = "Automatically swaps your hand to the appropriate tool."
	})
end)

run(function()
	local BedProtector = {Enabled = false}
	local bedprotector1stlayer = {
		Vector3.new(0, 3, 0),
		Vector3.new(0, 3, 3),
		Vector3.new(3, 0, 0),
		Vector3.new(3, 0, 3),
		Vector3.new(-3, 0, 0),
		Vector3.new(-3, 0, 3),
		Vector3.new(0, 0, 6),
		Vector3.new(0, 0, -3)
	}
	local bedprotector2ndlayer = {
		Vector3.new(0, 6, 0),
		Vector3.new(0, 6, 3),
		Vector3.new(0, 3, 6),
		Vector3.new(0, 3, -3),
		Vector3.new(0, 0, -6),
		Vector3.new(0, 0, 9),
		Vector3.new(3, 3, 0),
		Vector3.new(3, 3, 3),
		Vector3.new(3, 0, 6),
		Vector3.new(3, 0, -3),
		Vector3.new(6, 0, 3),
		Vector3.new(6, 0, 0),
		Vector3.new(-3, 3, 3),
		Vector3.new(-3, 3, 0),
		Vector3.new(-6, 0, 3),
		Vector3.new(-6, 0, 0),
		Vector3.new(-3, 0, 6),
		Vector3.new(-3, 0, -3),
	}

	local function getItemFromList(list)
		local selecteditem
		for i3,v3 in pairs(list) do
			local item = getItem(v3)
			if item then
				selecteditem = item
				break
			end
		end
		return selecteditem
	end

	local function placelayer(layertab, obj, selecteditems)
		for i2,v2 in pairs(layertab) do
			local selecteditem = getItemFromList(selecteditems)
			if selecteditem then
				bedwars.placeBlock(obj.Position + v2, selecteditem.itemType)
			else
				return false
			end
		end
		return true
	end

	local bedprotectorrange = {Value = 1}
	BedProtector = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "BedProtector",
		Function = function(callback)
			if callback then
				task.spawn(function()
					for i, obj in pairs(collectionService:GetTagged("bed")) do
						if entityLibrary.isAlive and obj:GetAttribute("Team"..(lplr:GetAttribute("Team") or 0).."NoBreak") and obj.Parent ~= nil then
							if (entityLibrary.character.HumanoidRootPart.Position - obj.Position).magnitude <= bedprotectorrange.Value then
								local firstlayerplaced = placelayer(bedprotector1stlayer, obj, {"obsidian", "stone_brick", "plank_oak", getWool()})
								if firstlayerplaced then
									placelayer(bedprotector2ndlayer, obj, {getWool()})
								end
							end
							break
						end
					end
					BedProtector.ToggleButton(false)
				end)
			end
		end,
		HoverText = "Automatically places a bed defense (Toggle)"
	})
	bedprotectorrange = BedProtector.CreateSlider({
		Name = "Place range",
		Min = 1,
		Max = 20,
		Function = function(val) end,
		Default = 20
	})
end)

run(function()
	local Nuker = {Enabled = false}
	local nukerrange = {Value = 1}
	local nukereffects = {Enabled = false}
	local nukeranimation = {Enabled = false}
	local nukernofly = {Enabled = false}
	local nukerlegit = {Enabled = false}
	local nukerown = {Enabled = false}
	local nukerluckyblock = {Enabled = false}
	local nukerironore = {Enabled = false}
	local nukerbeds = {Enabled = false}
	local nukercustom = {RefreshValues = function() end, ObjectList = {}}
	local luckyblocktable = {}

	Nuker = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "Breaker",
		Function = function(callback)
			if callback then
				for i,v in pairs(store.blocks) do
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end
				table.insert(Nuker.Connections, collectionService:GetInstanceAddedSignal("block"):Connect(function(v)
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end))
				table.insert(Nuker.Connections, collectionService:GetInstanceRemovedSignal("block"):Connect(function(v)
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.remove(luckyblocktable, table.find(luckyblocktable, v))
					end
				end))
				task.spawn(function()
					repeat
						if (not nukernofly.Enabled or not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) then
							local broke = not entityLibrary.isAlive
							local tool = (not nukerlegit.Enabled) and {Name = "wood_axe"} or store.localHand.tool
							if nukerbeds.Enabled then
								for i, obj in pairs(collectionService:GetTagged("bed")) do
									if broke then break end
									if obj.Parent ~= nil then
										if obj:GetAttribute("BedShieldEndTime") then
											if obj:GetAttribute("BedShieldEndTime") > workspace:GetServerTimeNow() then continue end
										end
										if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - obj.Position).magnitude <= nukerrange.Value then
											if tool and bedwars.ItemTable[tool.Name].breakBlock and bedwars.BlockController:isBlockBreakable({blockPosition = obj.Position / 3}, lplr) then
												local res, amount = getBestBreakSide(obj.Position)
												local res2, amount2 = getBestBreakSide(obj.Position + Vector3.new(0, 0, 3))
												broke = true
												bedwars.breakBlock((amount < amount2 and obj.Position or obj.Position + Vector3.new(0, 0, 3)), nukereffects.Enabled, (amount < amount2 and res or res2), false, nukeranimation.Enabled)
												break
											end
										end
									end
								end
							end
							broke = broke and not entityLibrary.isAlive
							for i, obj in pairs(luckyblocktable) do
								if broke then break end
								if entityLibrary.isAlive then
									if obj and obj.Parent ~= nil then
										if ((entityLibrary.LocalPosition or entityLibrary.character.HumanoidRootPart.Position) - obj.Position).magnitude <= nukerrange.Value and (nukerown.Enabled or obj:GetAttribute("PlacedByUserId") ~= lplr.UserId) then
											if tool and bedwars.ItemTable[tool.Name].breakBlock and bedwars.BlockController:isBlockBreakable({blockPosition = obj.Position / 3}, lplr) then
												bedwars.breakBlock(obj.Position, nukereffects.Enabled, getBestBreakSide(obj.Position), true, nukeranimation.Enabled)
												break
											end
										end
									end
								end
							end
						end
						task.wait()
					until (not Nuker.Enabled)
				end)
			else
				luckyblocktable = {}
			end
		end,
		HoverText = "Automatically destroys beds & luckyblocks around you."
	})
	nukerrange = Nuker.CreateSlider({
		Name = "Break range",
		Min = 1,
		Max = 30,
		Function = function(val) end,
		Default = 30
	})
	nukerlegit = Nuker.CreateToggle({
		Name = "Hand Check",
		Function = function() end
	})
	nukereffects = Nuker.CreateToggle({
		Name = "Show HealthBar & Effects",
		Function = function(callback)
			if not callback then
				bedwars.BlockBreaker.healthbarMaid:DoCleaning()
			end
		 end,
		Default = true
	})
	nukeranimation = Nuker.CreateToggle({
		Name = "Break Animation",
		Function = function() end
	})
	nukerown = Nuker.CreateToggle({
		Name = "Self Break",
		Function = function() end,
	})
	nukerbeds = Nuker.CreateToggle({
		Name = "Break Beds",
		Function = function(callback) end,
		Default = true
	})
	nukernofly = Nuker.CreateToggle({
		Name = "Fly Disable",
		Function = function() end
	})
	nukerluckyblock = Nuker.CreateToggle({
		Name = "Break LuckyBlocks",
		Function = function(callback)
			if callback then
				luckyblocktable = {}
				for i,v in pairs(store.blocks) do
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end
			else
				luckyblocktable = {}
			end
		 end,
		Default = true
	})
	nukerironore = Nuker.CreateToggle({
		Name = "Break IronOre",
		Function = function(callback)
			if callback then
				luckyblocktable = {}
				for i,v in pairs(store.blocks) do
					if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) or (nukerironore.Enabled and v.Name == "iron_ore") then
						table.insert(luckyblocktable, v)
					end
				end
			else
				luckyblocktable = {}
			end
		end
	})
	nukercustom = Nuker.CreateTextList({
		Name = "NukerList",
		TempText = "block (tesla_trap)",
		AddFunction = function()
			luckyblocktable = {}
			for i,v in pairs(store.blocks) do
				if table.find(nukercustom.ObjectList, v.Name) or (nukerluckyblock.Enabled and v.Name:find("lucky")) then
					table.insert(luckyblocktable, v)
				end
			end
		end
	})
end)


run(function()
	local controlmodule = require(lplr.PlayerScripts.PlayerModule).controls
	local oldmove
	local SafeWalk = {Enabled = false}
	local SafeWalkMode = {Value = "Optimized"}
	SafeWalk = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "SafeWalk",
		Function = function(callback)
			if callback then
				oldmove = controlmodule.moveFunction
				controlmodule.moveFunction = function(Self, vec, facecam)
					if entityLibrary.isAlive and (not Scaffold.Enabled) and (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) then
						if SafeWalkMode.Value == "Optimized" then
							local newpos = (entityLibrary.character.HumanoidRootPart.Position - Vector3.new(0, entityLibrary.character.Humanoid.HipHeight * 2, 0))
							local ray = getPlacedBlock(newpos + Vector3.new(0, -6, 0) + vec)
							for i = 1, 50 do
								if ray then break end
								ray = getPlacedBlock(newpos + Vector3.new(0, -i * 6, 0) + vec)
							end
							local ray2 = getPlacedBlock(newpos)
							if ray == nil and ray2 then
								local ray3 = getPlacedBlock(newpos + vec) or getPlacedBlock(newpos + (vec * 1.5))
								if ray3 == nil then
									vec = Vector3.zero
								end
							end
						else
							local ray = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position + vec, Vector3.new(0, -1000, 0), store.blockRaycast)
							local ray2 = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position, Vector3.new(0, -entityLibrary.character.Humanoid.HipHeight * 2, 0), store.blockRaycast)
							if ray == nil and ray2 then
								local ray3 = workspace:Raycast(entityLibrary.character.HumanoidRootPart.Position + (vec * 1.8), Vector3.new(0, -1000, 0), store.blockRaycast)
								if ray3 == nil then
									vec = Vector3.zero
								end
							end
						end
					end
					return oldmove(Self, vec, facecam)
				end
			else
				controlmodule.moveFunction = oldmove
			end
		end,
		HoverText = "lets you not walk off because you are bad"
	})
	SafeWalkMode = SafeWalk.CreateDropdown({
		Name = "Mode",
		List = {"Optimized", "Accurate"},
		Function = function() end
	})
end)

run(function()
	local Schematica = {Enabled = false}
	local SchematicaBox = {Value = ""}
	local SchematicaTransparency = {Value = 30}
	local positions = {}
	local tempfolder
	local tempgui
	local aroundpos = {
		[1] = Vector3.new(0, 3, 0),
		[2] = Vector3.new(-3, 3, 0),
		[3] = Vector3.new(-3, -0, 0),
		[4] = Vector3.new(-3, -3, 0),
		[5] = Vector3.new(0, -3, 0),
		[6] = Vector3.new(3, -3, 0),
		[7] = Vector3.new(3, -0, 0),
		[8] = Vector3.new(3, 3, 0),
		[9] = Vector3.new(0, 3, -3),
		[10] = Vector3.new(-3, 3, -3),
		[11] = Vector3.new(-3, -0, -3),
		[12] = Vector3.new(-3, -3, -3),
		[13] = Vector3.new(0, -3, -3),
		[14] = Vector3.new(3, -3, -3),
		[15] = Vector3.new(3, -0, -3),
		[16] = Vector3.new(3, 3, -3),
		[17] = Vector3.new(0, 3, 3),
		[18] = Vector3.new(-3, 3, 3),
		[19] = Vector3.new(-3, -0, 3),
		[20] = Vector3.new(-3, -3, 3),
		[21] = Vector3.new(0, -3, 3),
		[22] = Vector3.new(3, -3, 3),
		[23] = Vector3.new(3, -0, 3),
		[24] = Vector3.new(3, 3, 3),
		[25] = Vector3.new(0, -0, 3),
		[26] = Vector3.new(0, -0, -3)
	}

	local function isNearBlock(pos)
		for i,v in pairs(aroundpos) do
			if getPlacedBlock(pos + v) then
				return true
			end
		end
		return false
	end

	local function gethighlightboxatpos(pos)
		if tempfolder then
			for i,v in pairs(tempfolder:GetChildren()) do
				if v.Position == pos then
					return v
				end
			end
		end
		return nil
	end

	local function removeduplicates(tab)
		local actualpositions = {}
		for i,v in pairs(tab) do
			if table.find(actualpositions, Vector3.new(v.X, v.Y, v.Z)) == nil then
				table.insert(actualpositions, Vector3.new(v.X, v.Y, v.Z))
			else
				table.remove(tab, i)
			end
			if v.blockType == "start_block" then
				table.remove(tab, i)
			end
		end
	end

	local function rotate(tab)
		for i,v in pairs(tab) do
			local radvec, radius = entityLibrary.character.HumanoidRootPart.CFrame:ToAxisAngle()
			radius = (radius * 57.2957795)
			radius = math.round(radius / 90) * 90
			if radvec == Vector3.new(0, -1, 0) and radius == 90 then
				radius = 270
			end
			local rot = CFrame.new() * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(radius))
			local newpos = CFrame.new(0, 0, 0) * rot * CFrame.new(Vector3.new(v.X, v.Y, v.Z))
			v.X = math.round(newpos.p.X)
			v.Y = math.round(newpos.p.Y)
			v.Z = math.round(newpos.p.Z)
		end
	end

	local function getmaterials(tab)
		local materials = {}
		for i,v in pairs(tab) do
			materials[v.blockType] = (materials[v.blockType] and materials[v.blockType] + 1 or 1)
		end
		return materials
	end

	local function schemplaceblock(pos, blocktype, removefunc)
		local fail = false
		local ok = bedwars.RuntimeLib.try(function()
			bedwars.ClientDamageBlock:Get("PlaceBlock"):CallServer({
				blockType = blocktype or getWool(),
				position = bedwars.BlockController:getBlockPosition(pos)
			})
		end, function(thing)
			fail = true
		end)
		if (not fail) and bedwars.BlockController:getStore():getBlockAt(bedwars.BlockController:getBlockPosition(pos)) then
			removefunc()
		end
	end

	Schematica = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "Schematica",
		Function = function(callback)
			if callback then
				local mouseinfo = bedwars.BlockEngine:getBlockSelector():getMouseInfo(0)
				if mouseinfo and isfile(SchematicaBox.Value) then
					tempfolder = Instance.new("Folder")
					tempfolder.Parent = workspace
					local newpos = mouseinfo.placementPosition * 3
					positions = game:GetService("HttpService"):JSONDecode(readfile(SchematicaBox.Value))
					if positions.blocks == nil then
						positions = {blocks = positions}
					end
					rotate(positions.blocks)
					removeduplicates(positions.blocks)
					if positions["start_block"] == nil then
						bedwars.placeBlock(newpos)
					end
					for i2,v2 in pairs(positions.blocks) do
						local texturetxt = bedwars.ItemTable[(v2.blockType == "wool_white" and getWool() or v2.blockType)].block.greedyMesh.textures[1]
						local newerpos = (newpos + Vector3.new(v2.X, v2.Y, v2.Z))
						local block = Instance.new("Part")
						block.Position = newerpos
						block.Size = Vector3.new(3, 3, 3)
						block.CanCollide = false
						block.Transparency = (SchematicaTransparency.Value == 10 and 0 or 1)
						block.Anchored = true
						block.Parent = tempfolder
						for i3,v3 in pairs(Enum.NormalId:GetEnumItems()) do
							local texture = Instance.new("Texture")
							texture.Face = v3
							texture.Texture = texturetxt
							texture.Name = tostring(v3)
							texture.Transparency = (SchematicaTransparency.Value == 10 and 0 or (1 / SchematicaTransparency.Value))
							texture.Parent = block
						end
					end
					task.spawn(function()
						repeat
							task.wait(.1)
							if not Schematica.Enabled then break end
							for i,v in pairs(positions.blocks) do
								local newerpos = (newpos + Vector3.new(v.X, v.Y, v.Z))
								if entityLibrary.isAlive and (entityLibrary.character.HumanoidRootPart.Position - newerpos).magnitude <= 30 and isNearBlock(newerpos) and bedwars.BlockController:isAllowedPlacement(lplr, getWool(), newerpos / 3, 0) then
									schemplaceblock(newerpos, (v.blockType == "wool_white" and getWool() or v.blockType), function()
										table.remove(positions.blocks, i)
										if gethighlightboxatpos(newerpos) then
											gethighlightboxatpos(newerpos):Remove()
										end
									end)
								end
							end
						until #positions.blocks == 0 or (not Schematica.Enabled)
						if Schematica.Enabled then
							Schematica.ToggleButton(false)
							warningNotification("Schematica", "Finished Placing Blocks", 4)
						end
					end)
				end
			else
				positions = {}
				if tempfolder then
					tempfolder:Remove()
				end
			end
		end,
		HoverText = "Automatically places structure at mouse position."
	})
	SchematicaBox = Schematica.CreateTextBox({
		Name = "File",
		TempText = "File (location in workspace)",
		FocusLost = function(enter)
			local suc, res = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(SchematicaBox.Value)) end)
			if tempgui then
				tempgui:Remove()
			end
			if suc then
				if res.blocks == nil then
					res = {blocks = res}
				end
				removeduplicates(res.blocks)
				tempgui = Instance.new("Frame")
				tempgui.Name = "SchematicListOfBlocks"
				tempgui.BackgroundTransparency = 1
				tempgui.LayoutOrder = 9999
				tempgui.Parent = SchematicaBox.Object.Parent
				local uilistlayoutschmatica = Instance.new("UIListLayout")
				uilistlayoutschmatica.Parent = tempgui
				uilistlayoutschmatica:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					tempgui.Size = UDim2.new(0, 220, 0, uilistlayoutschmatica.AbsoluteContentSize.Y)
				end)
				for i4,v4 in pairs(getmaterials(res.blocks)) do
					local testframe = Instance.new("Frame")
					testframe.Size = UDim2.new(0, 220, 0, 40)
					testframe.BackgroundTransparency = 1
					testframe.Parent = tempgui
					local testimage = Instance.new("ImageLabel")
					testimage.Size = UDim2.new(0, 40, 0, 40)
					testimage.Position = UDim2.new(0, 3, 0, 0)
					testimage.BackgroundTransparency = 1
					testimage.Image = bedwars.getIcon({itemType = i4}, true)
					testimage.Parent = testframe
					local testtext = Instance.new("TextLabel")
					testtext.Size = UDim2.new(1, -50, 0, 40)
					testtext.Position = UDim2.new(0, 50, 0, 0)
					testtext.TextSize = 20
					testtext.Text = v4
					testtext.Font = Enum.Font.SourceSans
					testtext.TextXAlignment = Enum.TextXAlignment.Left
					testtext.TextColor3 = Color3.new(1, 1, 1)
					testtext.BackgroundTransparency = 1
					testtext.Parent = testframe
				end
			end
		end
	})
	SchematicaTransparency = Schematica.CreateSlider({
		Name = "Transparency",
		Min = 0,
		Max = 10,
		Default = 7,
		Function = function()
			if tempfolder then
				for i2,v2 in pairs(tempfolder:GetChildren()) do
					v2.Transparency = (SchematicaTransparency.Value == 10 and 0 or 1)
					for i3,v3 in pairs(v2:GetChildren()) do
						v3.Transparency = (SchematicaTransparency.Value == 10 and 0 or (1 / SchematicaTransparency.Value))
					end
				end
			end
		end
	})
end)

run(function()
	store.TPString = shared.vapeoverlay or nil
	local origtpstring = store.TPString
	local Overlay = GuiLibrary.CreateCustomWindow({
		Name = "Overlay",
		Icon = "vape/assets/TargetIcon1.png",
		IconSize = 16
	})
	local overlayframe = Instance.new("Frame")
	overlayframe.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	overlayframe.Size = UDim2.new(0, 200, 0, 120)
	overlayframe.Position = UDim2.new(0, 0, 0, 5)
	overlayframe.Parent = Overlay.GetCustomChildren()
	local overlayframe2 = Instance.new("Frame")
	overlayframe2.Size = UDim2.new(1, 0, 0, 10)
	overlayframe2.Position = UDim2.new(0, 0, 0, -5)
	overlayframe2.Parent = overlayframe
	local overlayframe3 = Instance.new("Frame")
	overlayframe3.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	overlayframe3.Size = UDim2.new(1, 0, 0, 6)
	overlayframe3.Position = UDim2.new(0, 0, 0, 6)
	overlayframe3.BorderSizePixel = 0
	overlayframe3.Parent = overlayframe2
	local oldguiupdate = GuiLibrary.UpdateUI
	GuiLibrary.UpdateUI = function(h, s, v, ...)
		overlayframe2.BackgroundColor3 = Color3.fromHSV(h, s, v)
		return oldguiupdate(h, s, v, ...)
	end
	local framecorner1 = Instance.new("UICorner")
	framecorner1.CornerRadius = UDim.new(0, 5)
	framecorner1.Parent = overlayframe
	local framecorner2 = Instance.new("UICorner")
	framecorner2.CornerRadius = UDim.new(0, 5)
	framecorner2.Parent = overlayframe2
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -7, 1, -5)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = Enum.Font.Arial
	label.LineHeight = 1.2
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.TextSize = 16
	label.Text = ""
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Position = UDim2.new(0, 7, 0, 5)
	label.Parent = overlayframe
	local OverlayFonts = {"Arial"}
	for i,v in pairs(Enum.Font:GetEnumItems()) do
		if v.Name ~= "Arial" then
			table.insert(OverlayFonts, v.Name)
		end
	end
	local OverlayFont = Overlay.CreateDropdown({
		Name = "Font",
		List = OverlayFonts,
		Function = function(val)
			label.Font = Enum.Font[val]
		end
	})
	OverlayFont.Bypass = true
	Overlay.Bypass = true
	local overlayconnections = {}
	local oldnetworkowner
	local teleported = {}
	local teleported2 = {}
	local teleportedability = {}
	local teleportconnections = {}
	local pinglist = {}
	local fpslist = {}
	local matchstatechanged = 0
	local mapname = "Unknown"
	local overlayenabled = false

	task.spawn(function()
		pcall(function()
			mapname = workspace:WaitForChild("Map"):WaitForChild("Worlds"):GetChildren()[1].Name
			mapname = string.gsub(string.split(mapname, "_")[2] or mapname, "-", "") or "Blank"
		end)
	end)

	local function didpingspike()
		local currentpingcheck = pinglist[1] or math.floor(tonumber(game:GetService("Stats"):FindFirstChild("PerformanceStats").Ping:GetValue()))
		for i,v in pairs(pinglist) do
			if v ~= currentpingcheck and math.abs(v - currentpingcheck) >= 100 then
				return currentpingcheck.." => "..v.." ping"
			else
				currentpingcheck = v
			end
		end
		return nil
	end

	local function notlasso()
		for i,v in pairs(collectionService:GetTagged("LassoHooked")) do
			if v == lplr.Character then
				return false
			end
		end
		return true
	end
	local matchstatetick = tick()

	GuiLibrary.ObjectsThatCanBeSaved.GUIWindow.Api.CreateCustomToggle({
		Name = "Overlay",
		Icon = "vape/assets/TargetIcon1.png",
		Function = function(callback)
			overlayenabled = callback
			Overlay.SetVisible(callback)
			if callback then
				table.insert(overlayconnections, bedwars.Client:OnEvent("ProjectileImpact", function(p3)
					if not vapeInjected then return end
					if p3.projectile == "telepearl" then
						teleported[p3.shooterPlayer] = true
					elseif p3.projectile == "swap_ball" then
						if p3.hitEntity then
							teleported[p3.shooterPlayer] = true
							local plr = playersService:GetPlayerFromCharacter(p3.hitEntity)
							if plr then teleported[plr] = true end
						end
					end
				end))

				table.insert(overlayconnections, replicatedStorage["events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"].abilityUsed.OnClientEvent:Connect(function(char, ability)
					if ability == "recall" or ability == "hatter_teleport" or ability == "spirit_assassin_teleport" or ability == "hannah_execute" then
						local plr = playersService:GetPlayerFromCharacter(char)
						if plr then
							teleportedability[plr] = tick() + (ability == "recall" and 12 or 1)
						end
					end
				end))

				table.insert(overlayconnections, vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
					if bedTable.player.UserId == lplr.UserId then
						store.statistics.beds = store.statistics.beds + 1
					end
				end))

				local victorysaid = false
				table.insert(overlayconnections, vapeEvents.MatchEndEvent.Event:Connect(function(winstuff)
					local myTeam = bedwars.ClientStoreHandler:getState().Game.myTeam
					if myTeam and myTeam.id == winstuff.winningTeamId or lplr.Neutral then
						victorysaid = true
					end
				end))

				table.insert(overlayconnections, vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill then
						local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
						local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
						if not killed or not killer then return end
						if killed ~= lplr and killer == lplr then
							store.statistics.kills = store.statistics.kills + 1
						end
					end
				end))

				task.spawn(function()
					repeat
						local ping = math.floor(tonumber(game:GetService("Stats"):FindFirstChild("PerformanceStats").Ping:GetValue()))
						if #pinglist >= 10 then
							table.remove(pinglist, 1)
						end
						table.insert(pinglist, ping)
						task.wait(1)
						if store.matchState ~= matchstatechanged then
							if store.matchState == 1 then
								matchstatetick = tick() + 3
							end
							matchstatechanged = store.matchState
						end
						if not store.TPString then
							store.TPString = tick().."/"..store.statistics.kills.."/"..store.statistics.beds.."/"..(victorysaid and 1 or 0).."/"..(1).."/"..(0).."/"..(0).."/"..(0)
							origtpstring = store.TPString
						end
						if entityLibrary.isAlive and (not oldcloneroot) then
							local newnetworkowner = isnetworkowner(entityLibrary.character.HumanoidRootPart)
							if oldnetworkowner ~= nil and oldnetworkowner ~= newnetworkowner and newnetworkowner == false and notlasso() then
								local respawnflag = math.abs(lplr:GetAttribute("SpawnTime") - lplr:GetAttribute("LastTeleported")) > 3
								if (not teleported[lplr]) and respawnflag then
									task.delay(1, function()
										local falseflag = didpingspike()
										if not falseflag then
											store.statistics.lagbacks = store.statistics.lagbacks + 1
										end
									end)
								end
							end
							oldnetworkowner = newnetworkowner
						else
							oldnetworkowner = nil
						end
						teleported[lplr] = nil
						for i, v in pairs(entityLibrary.entityList) do
							if teleportconnections[v.Player.Name.."1"] then continue end
							teleportconnections[v.Player.Name.."1"] = v.Player:GetAttributeChangedSignal("LastTeleported"):Connect(function()
								if not vapeInjected then return end
								for i = 1, 15 do
									task.wait(0.1)
									if teleported[v.Player] or teleported2[v.Player] or matchstatetick > tick() or math.abs(v.Player:GetAttribute("SpawnTime") - v.Player:GetAttribute("LastTeleported")) < 3 or (teleportedability[v.Player] or tick() - 1) > tick() then break end
								end
								if v.Player ~= nil and (not v.Player.Neutral) and teleported[v.Player] == nil and teleported2[v.Player] == nil and (teleportedability[v.Player] or tick() - 1) < tick() and math.abs(v.Player:GetAttribute("SpawnTime") - v.Player:GetAttribute("LastTeleported")) > 3 and matchstatetick <= tick() then
									store.statistics.universalLagbacks = store.statistics.universalLagbacks + 1
									vapeEvents.LagbackEvent:Fire(v.Player)
								end
								teleported[v.Player] = nil
							end)
							teleportconnections[v.Player.Name.."2"] = v.Player:GetAttributeChangedSignal("PlayerConnected"):Connect(function()
								teleported2[v.Player] = true
								task.delay(5, function()
									teleported2[v.Player] = nil
								end)
							end)
						end
						local splitted = origtpstring:split("/")
						label.Text = "Session Info\nTime Played : "..os.date("!%X",math.floor(tick() - splitted[1])).."\nKills : "..(splitted[2] + store.statistics.kills).."\nBeds : "..(splitted[3] + store.statistics.beds).."\nWins : "..(splitted[4] + (victorysaid and 1 or 0)).."\nGames : "..splitted[5].."\nLagbacks : "..(splitted[6] + store.statistics.lagbacks).."\nUniversal Lagbacks : "..(splitted[7] + store.statistics.universalLagbacks).."\nReported : "..(splitted[8] + store.statistics.reported).."\nMap : "..mapname
						local textsize = textService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(9e9, 9e9))
						overlayframe.Size = UDim2.new(0, math.max(textsize.X + 19, 200), 0, (textsize.Y * 1.2) + 6)
						store.TPString = splitted[1].."/"..(splitted[2] + store.statistics.kills).."/"..(splitted[3] + store.statistics.beds).."/"..(splitted[4] + (victorysaid and 1 or 0)).."/"..(splitted[5] + 1).."/"..(splitted[6] + store.statistics.lagbacks).."/"..(splitted[7] + store.statistics.universalLagbacks).."/"..(splitted[8] + store.statistics.reported)
					until not overlayenabled
				end)
			else
				for i, v in pairs(overlayconnections) do
					if v.Disconnect then pcall(function() v:Disconnect() end) continue end
					if v.disconnect then pcall(function() v:disconnect() end) continue end
				end
				table.clear(overlayconnections)
			end
		end,
		Priority = 2
	})
end)

run(function()
	local ReachDisplay = {}
	local ReachLabel
	ReachDisplay = GuiLibrary.CreateLegitModule({
		Name = "Reach Display",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait(0.4)
						ReachLabel.Text = store.attackReachUpdate > tick() and store.attackReach.." studs" or "0.00 studs"
					until (not ReachDisplay.Enabled)
				end)
			end
		end
	})
	ReachLabel = Instance.new("TextLabel")
	ReachLabel.Size = UDim2.new(0, 100, 0, 41)
	ReachLabel.BackgroundTransparency = 0.5
	ReachLabel.TextSize = 15
	ReachLabel.Font = Enum.Font.Gotham
	ReachLabel.Text = "0.00 studs"
	ReachLabel.TextColor3 = Color3.new(1, 1, 1)
	ReachLabel.BackgroundColor3 = Color3.new()
	ReachLabel.Parent = ReachDisplay.GetCustomChildren()
	local ReachCorner = Instance.new("UICorner")
	ReachCorner.CornerRadius = UDim.new(0, 4)
	ReachCorner.Parent = ReachLabel
end)

task.spawn(function()
	repeat task.wait() until shared.VapeFullyLoaded
	if not AutoLeave.Enabled then
		AutoLeave.ToggleButton(false)
	end
end)

-- Custom Modules --

-- Blatant Modules --

--[[run(function()
    local AntiHit = {Enabled = false}
	local AntiHit = {Value = 23}

	function IsAlive(plr)
		plr = plr or lplr
		if not plr.Character then return false end
		if not plr.Character:FindFirstChild("Head") then return false end
		if not plr.Character:FindFirstChild("Humanoid") then return false end
		if plr.Character:FindFirstChild("Humanoid").Health < 0.11 then return false end
		return true
	end
    AntiHit = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
        Name = "AntiHit",
        Function = function(callback)
            if callback then
				spawn(function()
					while task.wait() do
						if (not AntiHit.Enabled) then return end
						if (not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled) and (not GuiLibrary.ObjectsThatCanBeSaved.InfiniteFlyOptionsButton.Api.Enabled) then
							for i, v in pairs(game:GetService("Players"):GetChildren()) do
								if v.Team ~= lplr.Team and IsAlive(v) and IsAlive(lplr) then
									if v and v ~= lplr then
										local TargetDistance = lplr:DistanceFromCharacter(v.Character:FindFirstChild("HumanoidRootPart").CFrame.p)
										if TargetDistance < AntiHitRange.Value then
											if not lplr.Character.HumanoidRootPart:FindFirstChildOfClass("BodyVelocity") then
												repeat task.wait() until store.matchState ~= 0
												if not (v.Character.HumanoidRootPart.Velocity.Y < -10*5) then
													lplr.Character.Archivable = true

													local Clone = lplr.Character:Clone()
													Clone.Parent = workspace
													Clone.Head:ClearAllChildren()
													gameCamera.CameraSubject = Clone:FindFirstChild("Humanoid")

													for i,v in pairs(Clone:GetChildren()) do
														if string.lower(v.ClassName):find("part") and v.Name ~= "HumanoidRootPart" then
															v.Transparency = 1
														end
														if v:IsA("Accessory") then
															v:FindFirstChild("Handle").Transparency = 1
														end
													end

													lplr.Character.HumanoidRootPart.CFrame = lplr.Character.HumanoidRootPart.CFrame + Vector3.new(0,100000,0)

													game:GetService("RunService").RenderStepped:Connect(function()
														if Clone ~= nil and Clone:FindFirstChild("HumanoidRootPart") then
															Clone.HumanoidRootPart.Position = Vector3.new(lplr.Character.HumanoidRootPart.Position.X, Clone.HumanoidRootPart.Position.Y, lplr.Character.HumanoidRootPart.Position.Z)
														end
													end)

													task.wait(0.3)
													lplr.Character.HumanoidRootPart.Velocity = Vector3.new(lplr.Character.HumanoidRootPart.Velocity.X, -1, lplr.Character.HumanoidRootPart.Velocity.Z)
													lplr.Character.HumanoidRootPart.CFrame = Clone.HumanoidRootPart.CFrame
													gameCamera.CameraSubject = lplr.Character:FindFirstChild("Humanoid")
													Clone:Destroy()
													task.wait(0.2)
												end
											end
										end
									end
								end
							end
						end
					end
				end)
			end
        end
    })
	AntiHitRange = AntiHit.CreateSlider({
        Name = "Range",
        Min = 1,
        Max = 23,
        Default = 20,
        Function = function() end
    })
end)

-- Blatant Modules Over -- 



-- Movement Modules --



-- Movement Modules Over -- 



-- Tween Teleportation Modules --

run(function()
    local BedTPPosition = nil
    local TweenSpeed = 0.7
    local HeightOffset = 10
    local BedTP = {}
    local TweenService = game:GetService("TweenService")
    local collectionService = game:GetService("CollectionService")
    local player = game.Players.LocalPlayer

    local function warningNotification(title, text, delay)
        local suc, res = pcall(function()
            local frame = GuiLibrary.CreateNotification(title, text, delay, "assets/InfoNotification.png")
            frame.Frame.Frame.ImageColor3 = Color3.fromRGB(236, 129, 44)
            return frame
        end)
        return (suc and res)
    end

    local function teleportWithTween(char, destination)
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            destination = destination + Vector3.new(0, HeightOffset, 0)
            local tweenInfo = TweenInfo.new(TweenSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            local goal = {CFrame = CFrame.new(destination)}
            local tween = TweenService:Create(root, tweenInfo, goal)
            tween:Play()
            tween.Completed:Wait()
            BedTP.ToggleButton(false)
        else
            warningNotification("BedTP", "Player not found.", 3)
        end
    end

    local function killPlayer(player)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end

    local function teamHasPlayers(team)
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if plr:GetAttribute('Team') == team then
                return true
            end
        end
        return false
    end

    local function getEnemyBed(range)
        range = range or math.huge
        local bed = nil

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local localPos = player.Character.HumanoidRootPart.Position
            local playerTeam = player:GetAttribute('Team')
            local beds = collectionService:GetTagged('bed')

            for _, v in ipairs(beds) do
                local placedByUserId = v:GetAttribute('PlacedByUserId')
                local bedId = v:GetAttribute('id')

                if placedByUserId and bedId then
                    if placedByUserId == 0 then
                        local bedTeam = bedId:sub(1, 1)
                        if bedTeam ~= playerTeam and teamHasPlayers(bedTeam) then
                            local bedPosition = v.Position
                            local bedDistance = (localPos - bedPosition).Magnitude
                            if bedDistance < range then
                                bed = v
                                range = bedDistance
                            end
                        end
                    end
                end
            end

            return bed
        else
            warningNotification("BedTP", "Player not found.", 5)
        end
    end

    local function canRespawn()
        local success, hasBed = pcall(function()
            return player.leaderstats.Bed.Value == '✅'
        end)
        return success and hasBed
    end

    BedTP = GuiLibrary["ObjectsThatCanBeSaved"]["BlatantWindow"]["Api"].CreateOptionsButton({
        ["Name"] = "BedTP",
        ["Function"] = function(callback)
            if callback then
                if canRespawn() then
                    task.spawn(function()
                        table.insert(BedTP.Connections, player.CharacterAdded:Connect(function(char)
                            if BedTPPosition then
                                task.spawn(function()
                                    local root = char:WaitForChild("HumanoidRootPart", 9000000000)
                                    if root and BedTPPosition then
                                        teleportWithTween(char, BedTPPosition)
                                        BedTPPosition = nil
                                    end
                                end)
                            end
                        end))

                        local bed = getEnemyBed()
                        if bed then
                            BedTPPosition = bed.Position
                            killPlayer(player)
                        else
                            warningNotification("Notifier", "No enemy bed found!", 5)
                            BedTP.ToggleButton(false)
                        end
                    end)
                else
                    warningNotification("Notifier", "Unable to use BedTP without bed!", 5)
                    BedTP.ToggleButton(false)
                end
            end
        end,
        HoverText = "Teleport to Bed nearest to you"
    })
end)

run(function()
    local PlayerTPPosition = nil
    local TweenSpeed = 0.7
    local HeightOffset = 5
    local PlayerTP = {}
    local player = game.Players.LocalPlayer
    local TweenService = game:GetService("TweenService")

    local function warningNotification(title, text, delay)
        local suc, res = pcall(function()
            local frame = GuiLibrary.CreateNotification(title, text, delay, "assets/InfoNotification.png")
            frame.Frame.Frame.ImageColor3 = Color3.fromRGB(236, 129, 44)
            return frame
        end)
        return (suc and res)
    end

    local function teleportWithTween(char, destination)
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            destination = destination + Vector3.new(0, HeightOffset, 0)
            local tweenInfo = TweenInfo.new(TweenSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            local goal = {CFrame = CFrame.new(destination)}
            local tween = TweenService:Create(root, tweenInfo, goal)
            tween:Play()
            tween.Completed:Wait()
            PlayerTP.ToggleButton(false)
        else
            warningNotification("Notifier", "Player not found.", 3)
        end
    end

    local function killPlayer(player)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end

    local function getNearestPlayer(range)
        range = range or math.huge
        local nearestPlayer = nil

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local localPos = player.Character.HumanoidRootPart.Position
            local playerTeam = player.Team
            local players = game.Players:GetPlayers()

            for _, p in ipairs(players) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local targetTeam = p.Team
                    if targetTeam ~= playerTeam then
                        local playerPos = p.Character.HumanoidRootPart.Position
                        local distance = (localPos - playerPos).Magnitude
                        if distance < range then
                            nearestPlayer = p
                            range = distance
                        end
                    end
                end
            end

            return nearestPlayer
        else
            warningNotification("Notifier", "Player not found.", 5)
        end
    end

    local function canRespawn()
        local success, hasBed
        if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Bed") then
            success, hasBed = pcall(function()
                return player.leaderstats.Bed.Value == '✅'
            end)
        else
            success, hasBed = false, false
        end
        
        if not success then
            warningNotification("Notifier", "Unable to verify bed status", 5)
        end

        return success and hasBed
    end

    PlayerTP = GuiLibrary["ObjectsThatCanBeSaved"]["BlatantWindow"]["Api"].CreateOptionsButton({
        ["Name"] = "PlayerTP",
        ["Function"] = function(callback)
            if callback then
                if canRespawn() then
                    task.spawn(function()
                        table.insert(PlayerTP.Connections, player.CharacterAdded:Connect(function(char)
                            if PlayerTPPosition then
                                task.spawn(function()
                                    local root = char:WaitForChild("HumanoidRootPart", 10)
                                    if root and PlayerTPPosition then
                                        teleportWithTween(char, PlayerTPPosition)
                                        PlayerTPPosition = nil
                                    end
                                end)
                            end
                        end))

                        local targetPlayer = getNearestPlayer()
                        if targetPlayer then
                            PlayerTPPosition = targetPlayer.Character.HumanoidRootPart.Position
                            killPlayer(player)
                        else
                            warningNotification("Notifier", "No enemy player found!", 5)
                            PlayerTP.ToggleButton(false)
                        end
                    end)
                else
                    warningNotification("Notifier", "Unable to use PlayerTP without bed!", 5)
                    PlayerTP.ToggleButton(false)
                end
            end
        end,
        HoverText = "Teleport to a Player"
    })
end)

run(function()
	local TweenService = game:GetService("TweenService")
	local playersService = game:GetService("Players")
	local lplr = playersService.LocalPlayer

	local function warningNotification(title, text, delay)
		local suc, res = pcall(function()
			local frame = GuiLibrary.CreateNotification(title, text, delay, "assets/InfoNotification.png")
			frame.Frame.Frame.ImageColor3 = Color3.fromRGB(236, 129, 44)
			return frame
		end)
		return (suc and res)
	end

	local DeathTPPos
	local deathtpmod = {["Enabled"] = false}
	local TweenSpeed = 0.7
	local HeightOffset = 5

	local function teleportWithTween(char, destination)
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			destination = destination + Vector3.new(0, HeightOffset, 0)
			local currentPosition = root.Position
			if (destination - currentPosition).Magnitude > 0.5 then
				local tweenInfo = TweenInfo.new(TweenSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
				local goal = {CFrame = CFrame.new(destination)}
				local tween = TweenService:Create(root, tweenInfo, goal)
				tween:Play()
				tween.Completed:Wait()
			end
		end
	end

	local function killPlayer(player)
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end

	local function onCharacterAdded(char)
		if DeathTPPos then 
			task.spawn(function()
				local root = char:WaitForChild("HumanoidRootPart", 9000000000)
				if root and DeathTPPos then 
					teleportWithTween(char, DeathTPPos)
					DeathTPPos = nil
				end
			end)
		end
	end

	lplr.CharacterAdded:Connect(onCharacterAdded)

	local function setTeleportPosition()
		local UserInputService = game:GetService("UserInputService")
		local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

		if isMobile then
			warningNotification("Notifier", "Please tap on the screen to set TP position.", 3)
			local connection
			connection = UserInputService.TouchTapInWorld:Connect(function(inputPosition, processedByUI)
				if not processedByUI then
					local mousepos = lplr:GetMouse().UnitRay
					local rayparams = RaycastParams.new()
					rayparams.FilterDescendantsInstances = {workspace.Map, workspace:FindFirstChild("SpectatorPlatform")}
					rayparams.FilterType = Enum.RaycastFilterType.Whitelist
					local ray = workspace:Raycast(mousepos.Origin, mousepos.Direction * 10000, rayparams)
					if ray then 
						DeathTPPos = ray.Position 
						warningNotification("Notifier", "Teleportation Started.", 3)
						killPlayer(lplr)
					end
					connection:Disconnect()
					deathtpmod["ToggleButton"](false)
				end
			end)
		else
			local mousepos = lplr:GetMouse().UnitRay
			local rayparams = RaycastParams.new()
			rayparams.FilterDescendantsInstances = {workspace.Map, workspace:FindFirstChild("SpectatorPlatform")}
			rayparams.FilterType = Enum.RaycastFilterType.Whitelist
			local ray = workspace:Raycast(mousepos.Origin, mousepos.Direction * 10000, rayparams)
			if ray then 
				DeathTPPos = ray.Position 
				warningNotification("Notifier", "Teleportation Started.", 3)
				killPlayer(lplr)
			end
			deathtpmod["ToggleButton"](false)
		end
	end

	deathtpmod = GuiLibrary["ObjectsThatCanBeSaved"]["BlatantWindow"]["Api"].CreateOptionsButton({
		["Name"] = "DeathTP",
		["Function"] = function(calling)
			if calling then
				task.spawn(function()
					local canRespawn = function() end
					canRespawn = function()
						local success, response = pcall(function() 
							return lplr.leaderstats.Bed.Value == '✅' 
						end)
						return success and response 
					end
					if not canRespawn() then 
						warningNotification("Notifier", "Unable to use DeathTP without bed!", 5)
						deathtpmod.ToggleButton()
					else
						setTeleportPosition()
					end
				end)
			end
		end
	})
end)

-- Tween Teleportation Modules Over --



-- Visual Modules -- 

run(function()
	local Shader = {Enabled = false}
	local ShaderColor = {Hue = 0, Sat = 0, Value = 0}
	local ShaderTintSlider
	local ShaderBlur
	local ShaderTint
	local oldlightingsettings = {
		Brightness = lightingService.Brightness,
		ColorShift_Top = lightingService.ColorShift_Top,
		ColorShift_Bottom = lightingService.ColorShift_Bottom,
		OutdoorAmbient = lightingService.OutdoorAmbient,
		ClockTime = lightingService.ClockTime,
		ExposureCompensation = lightingService.ExposureCompensation,
		ShadowSoftness = lightingService.ShadowSoftness,
		Ambient = lightingService.Ambient
	}
	Shader = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "CustomColorShaders",
		HoverText = "Color Shaders (Inspired by Voidware)",
		Function = function(callback)
			if callback then 
				task.spawn(function()
					pcall(function()
					ShaderBlur = Instance.new("BlurEffect")
					ShaderBlur.Parent = lightingService
					ShaderBlur.Size = 4
					end)
					pcall(function()
						ShaderTint = Instance.new("ColorCorrectionEffect")
						ShaderTint.Parent = lightingService
						ShaderTint.Saturation = -0.2
						ShaderTint.TintColor = Color3.fromRGB(255, 224, 219)
					end)
					pcall(function()
						lightingService.ColorShift_Bottom = Color3.fromHSV(ShaderColor.Hue, ShaderColor.Sat, ShaderColor.Value)
						lightingService.ColorShift_Top = Color3.fromHSV(ShaderColor.Hue, ShaderColor.Sat, ShaderColor.Value)
						lightingService.OutdoorAmbient = Color3.fromHSV(ShaderColor.Hue, ShaderColor.Sat, ShaderColor.Value)
						lightingService.ClockTime = 8.7
						lightingService.FogColor = Color3.fromHSV(ShaderColor.Hue, ShaderColor.Sat, ShaderColor.Value)
						lightingService.FogEnd = 1000
						lightingService.FogStart = 0
						lightingService.ExposureCompensation = 0.24
						lightingService.ShadowSoftness = 0
						lightingService.Ambient = Color3.fromRGB(59, 33, 27)
					end)
				end)
			else
				pcall(function() ShaderBlur:Destroy() end)
				pcall(function() ShaderTint:Destroy() end)
				pcall(function()
				lightingService.Brightness = oldlightingsettings.Brightness
				lightingService.ColorShift_Top = oldlightingsettings.ColorShift_Top
				lightingService.ColorShift_Bottom = oldlightingsettings.ColorShift_Bottom
				lightingService.OutdoorAmbient = oldlightingsettings.OutdoorAmbient
				lightingService.ClockTime = oldlightingsettings.ClockTime
				lightingService.ExposureCompensation = oldlightingsettings.ExposureCompensation
				lightingService.ShadowSoftness = oldlightingsettings.ShadowSoftnesss
				lightingService.Ambient = oldlightingsettings.Ambient
				lightingService.FogColor = oldthemesettings.FogColor
				lightingService.FogStart = oldthemesettings.FogStart
				lightingService.FogEnd = oldthemesettings.FogEnd
				end)
			end
		end
	})	
	ShaderColor = Shader.CreateColorSlider({
		Name = "Main Color",
		Function = function(h, s, v)
			if Shader.Enabled then 
				pcall(function()
					lightingService.ColorShift_Bottom = Color3.fromHSV(h, s, v)
					lightingService.ColorShift_Top = Color3.fromHSV(h, s, v)
					lightingService.OutdoorAmbient = Color3.fromHSV(h, s, v)
					lightingService.FogColor = Color3.fromHSV(h, s, v)
				end)
			end
		end
	})
end)

run(function()
    local DamageIndicator = {Enabled = false}
    repeat wait() until game:IsLoaded()
    local Indicators = {"GX+ On Top", "Tired of losing? Get GX+", "You look like a clown"}
    local Color = {Color3.fromRGB(128, 0, 128), Color3.fromRGB(0, 0, 255)}

    DamageIndicator = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
        Name = "DamageIndicators",
        HoverText = "Changes the Damage Indicator Text",
        Function = function(state)
            if state then
                workspace.ChildAdded:Connect(function(obj)
                    if obj:IsA("Part") and obj.Name == "DamageIndicatorPart" then
                        obj.BillboardGui.Frame.TextLabel.Text = Indicators[math.random(#Indicators)]
                        obj.BillboardGui.Frame.TextLabel.TextColor3 = Color[math.random(#Color)]
                    end
                end)
            end
        end
    })
end)

run(function()
    local DragonBreath = {["Enabled"] = false}

    DragonBreath = GuiLibrary["ObjectsThatCanBeSaved"]["RenderWindow"]["Api"]["CreateOptionsButton"]({
        ["Name"] = "DragonBreath",
        ["HoverText"] = "Spams DragonBreath remote.",
        ["Function"] = function(callback)
            if callback then 
                repeat
                    task.wait()
                    game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("DragonBreath"):FireServer({player = game:GetService("Players").LocalPlayer})
                until not DragonBreath["Enabled"]
            end
        end
    })
end)

run(function()
    local AzureHealthBar

    local function changeHealthbarColor()
        local healthbar = lplr.PlayerGui.hotbar["1"].HotbarHealthbarContainer.HealthbarProgressWrapper["1"]
        if healthbar and typeof(healthbar) == "Instance" then
            AzureHealthBar = healthbar
            healthbar.BackgroundColor3 = Color3.fromRGB(3, 140, 252)
        end
    end

    GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
        Name = "HealthbarMod",
        Function = function(enable)
            if enable then
                task.spawn(function()
                    changeHealthbarColor()
                    table.insert(HealthbarVisuals.Connections, lplr.PlayerGui.DescendantAdded:Connect(function(descendant)
                        if descendant.Name == "HotbarHealthbarContainer" and descendant.Parent and descendant.Parent.Parent and descendant.Parent.Parent.Name == "hotbar" then
                            changeHealthbarColor()
                        end
                    end))
                end)
            else
                if AzureHealthBar then
                    AzureHealthBar.BackgroundColor3 = Color3.fromRGB(203, 54, 36)
                end
                AzureHealthBar = nil
            end
        end,
        HoverText = "Change the color of your healthbar to Dark Azure Blue."
    })
end)

run(function()
	local Changed = {["Enabled"] = false}
	local ThemeChanger = {["Enabled"] = false}
	local SelectedTheme = {["Value"] = "ChillPurpleSky"}
	local AvaiableThemes = {
		["ChillPurpleSky"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=5260808177"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=5260653793"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=5260817288"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=5260800833"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=5260811073"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=5260824661"
				game.Lighting.FogColor = Color3.new(236, 88, 241)
				game.Lighting.FogEnd = "200"
				game.Lighting.FogStart = "0"
				game.Lighting.Ambient = Color3.new(0.5, 0, 1)
			end)
		end,
		["SpaceSky"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=1735468027"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=1735500192"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=1735467260"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=1735467682"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=1735466772"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=1735500898"
				game.Lighting.FogColor = Color3.new(236, 88, 241)
				game.Lighting.FogEnd = "200"
				game.Lighting.FogStart = "0"
				game.Lighting.Ambient = Color3.new(0.5, 0, 1)
			end)
		end,
		["MidNightPurpleSky"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=187713366"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=187712428"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=187712836"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=187713755"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=187714525"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=187712111"
				game.Lighting.FogColor = Color3.new(236, 88, 241)
				game.Lighting.FogEnd = "200"
				game.Lighting.FogStart = "0"
				game.Lighting.Ambient = Color3.new(0.5, 0, 1)
			end)
		end,
		["Chill"] = function()
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=169210090"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=169210108"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=169210121"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=169210133"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=169210143"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=169210149"
			end)
		end,
		["MountainSky"] = function()
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=174457450"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=174457519"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=174457566"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=174457651"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=174457702"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=174457748"
			end)
		end,
		["Darkness"] = function()
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=2240134413"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=2240136039"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=2240130790"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=2240133550"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=2240132643"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=2240135222"
			end)
		end,
		["RealisticSky"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=144933338"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=144931530"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=144933262"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=144933244"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=144933299"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=144931564"
			end)
		end,
        ["PinkSky"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=271042516"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=271077243"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=271042556"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=271042310"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=271042467"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=271077958"
			end)
        end,
        ["MoonLight"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=12064107"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=12064152"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=12064121"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=12063984"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=12064115"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=12064131"
			end)
        end,
        ["AstroidBelt"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=16262356578"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=16262358026"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=16262360469"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=16262362003"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=16262363873"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=16262366016"
			end)
        end,
        ["RainySky"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=4495864450"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=4495864887"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=4495865458"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=4495866035"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=4495866584"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=4495867486"
			end)
        end,
        ["RainyNight"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=149679669"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=149681979"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=149679690"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=149679709"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=149679722"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=149680199"
			end)
        end,
        ["StormyNight"] = function() 
			task.spawn(function()
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=15502511288"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=15502508460"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=15502510289"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=15502507918"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=15502509398"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=15502511911"
			end)
		end
	}
	ThemeChanger = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		["Name"] = "SkyThemeChanger",
		["Function"] = function(callback) 
			if callback then
				AvaiableThemes[SelectedTheme["Value"]]--[[() -- DO NOT FORGET
			else
				game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=7018684000"
				game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=6334928194"
				game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=7018684000"
				game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=7018684000"
				game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=7018684000"
				game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=7018689553"
				game.Lighting.FogColor = Color3.new(1, 1, 1)
				game.Lighting.FogEnd = "10000"
				game.Lighting.FogStart = "0"
				game.Lighting.Ambient = Color3.new(0, 0, 0)
			end
		end,
		["ExtraText"] = function()
			return SelectedTheme["Value"]
		end
	})	
	SelectedTheme = ThemeChanger.CreateDropdown({
		["Name"] = "Theme",
		["Function"] = function() end,
		["List"] = {"ChillPurpleSky","SpaceSky","MidNightPurpleSky", "RealisticSky", "Darkness", "MountainSky", "Chill", "RainySky", "StormyNight", "PinkSky", "RainyNight", "AstroidBelt", "MoonLight"}
	})
end)]]

-- Visual Modules Over --



-- Test Modules --

-- Obfuscated Script Here --

return(function(z,n,N,U,l,H,w,s,Q,b,L,Z,A,_,f,i,M,K,P,R,S,a,X,y,W,D,J,o,x,t,E,p)K={};E=(J.w);local C,I,h,j,T=unpack,{0B11__,0B101,0B10},0x3f;repeat if h<0B111111 then T=tostring;break;else if not(h>0b10010)then else j=(1);if not K[0X1167_]then K[0X5f9a]=(0X43C4fE2E+-J.G((J.N(p[0X003]-p[4]+p[0X6],p[8])),p[1],h));h=1225399025+-((h+h>p[0X1]and p[9]or p[0X3])+p[1]-h);K[4455]=(h);else h=(K[4455]);end;continue;end;end;until false;local k,V=({});h=(22);while true do if h==22 then if not K[10801]then(K)[7644]=(711164745+-J.J((J.i(J.g(p[0X7],K[0X1167])~=p[0X7]and p[0x6]or p[0X9]))));h=2970+-(J.D(p[0x4]-p[0X5_],K[0x1167])-p[0X1]+p[1]);(K)[10801]=(h);else h=K[0X2a31];end;continue;else if h==0B1_11__1__1_01__ then if not not K[0X1F8B]then h=K[0X1f__8b];else h=(3583802637+-(p[0x2]-p[0X4]+p[0B100]+p[0X6]-p[0B10_]));(K)[0X1f8b]=(h);end;continue;elseif h==0X038 then V=L;if not not K[0X6f6e]then h=(K[0X6f6e]);else K[0X6Ff5]=0B1_101_11+-(J.N((J.I(p[6]+p[0B101])),K[0X1F8B])-K[0X1167]);h=0X37+-J.I((J.i((J.J(p[0x5]+p[0b11__],K[24474],K[0X1167])))));(K)[0X6f6e]=(h);end;continue;elseif h==0X37 then if not K[16592]then h=(-814466541+-(J.U((J.s(p[8],K[28661])),K[0X01167])-p[0X9]-p[2]));K[0x040D0]=(h);else h=K[0X40D0__];end;continue;else if h==0X2a then if not K[0x1deF]then h=0x1+-J.I(p[1]+h-p[7]>=p[0x9]and p[5]or p[6]);(K)[0X1Def]=(h);else h=K[7663];end;else if h==0B1 then break;end;end;end;end;end;local G,e,d,g,m;h=(0X11_);while true do if h==0X11 then G=(function(...)return(...)[...];end);if not K[12930]then h=(3403969519+-J.N(J.s(K[28661],K[7644])-p[0B110]+p[0B101]));(K)[0X3282]=(h);else h=(K[0x32__82]);end;else if h==60 then e={};if not K[20473]then K[0X3904]=(0X2+-(J.C(p[0X9])+K[0x6F6e]-K[0X6F6e]-K[0X5f9A]));K[0x7093]=(0B1111+-J.D(J.G((J.U(p[6],K[4455])),p[2],K[0X1deF])-K[0X5f9A],K[7644]));h=1259284636+-(J.g(p[0X7],K[0X1dDC])+K[0x6F6E]-p[2]-K[7644]);(K)[20473]=(h);else h=(K[0X4fF9]);end;elseif h==0b1101_011 then d=(J.f);if not not K[0X3Cd6]then h=(K[15574]);else h=3583802659+-(p[2]+p[0X5]+K[0X1dDc__]-K[0X40D0]~=K[8075]and p[0x6]or K[0X4__0d0]);K[0X3CD6]=(h);end;continue;else if h==0X4E then g=function(z,n,N)local U,l=(120);repeat if U~=0B1111000 then if l>=0X8 then return n[N],n[N+X],n[N+0B10],n[N+0x3],n[N+4],n[N+0X5__],n[N+0X6],n[N+0X7],g(z,n,N+8);elseif l>=0X7 then return n[N],n[N+0x1],n[N+2],n[N+0X3],n[N+4],n[N+0X5],n[N+6],g(z,n,N+0X7_);elseif l>=0B110 then return n[N],n[N+0X1],n[N+w],n[N+S],n[N+0X004],n[N+0B101],g(z,n,N+0X6_);elseif l>=5 then return n[N],n[N+0X1],n[N+0B10_],n[N+3],n[N+0b100],g(z,n,N+0B101);elseif l>=0B100__ then return n[N],n[N+0x1],n[N+0B10],n[N+0x3],g(z,n,N+0x04);else if l>=0x3 then return n[N],n[N+0X1],n[N+2],g(z,n,N+3);else if not(l>=2)then return n[N],g(z,n,N+0X1);else return n[N],n[N+1],g(z,n,N+2);end;end;end;break;else if N>z then return;end;l=(z-N+1);U=0X77;continue;end;until false;end;if not K[20029]then h=(0x56__+-(J.J(p[0X7]<K[0x2A31]and K[7663]or K[7663],K[7644],K[0X4fF9])+K[0X6F6E]-K[0X6F6E_]));K[0X4E3d]=h;else h=K[20029];end;else if h~=0x55__ then else m=function(z,n,N)z=z or 0X1;local U=0X37;while true do if U==0X037 then U=0X2a;N=N or#n;continue;else if U~=0x2A then else if not(N-z+0X1>7997)then return C(n,z,N);else return g(N,n,z);end;break;end;end;end;end;break;end;end;end;end;end;local S=error;local X,C,g,F;h=(0X6);repeat if h==6 then if not not K[14968]then h=(K[14968]);else h=(0B110111+-J.C(J.g((J.G(K[0X4ff9])),K[28819])+K[16592]));K[14968]=(h);end;continue;elseif h==0B101101 then if not not K[0x3b77_]then h=K[15223];else h=(4287365159+-J.U((p[0X1]+p[0x9]<=K[0X001Def]and K[28819]or K[0X3904])-K[0x4fF9],K[28819]));K[15223]=(h);end;elseif h==0X28 then X=(pcall);if not not K[25194]then h=(K[25194]);else K[0X2eC1]=(J.s((J.N((J.N(K[28661])))),K[0X7093])<K[0X3_A78]and K[28526]or K[28661]);h=1073741988+-(J.D((J.s((J.J(K[14968],p[6],K[20029])),K[0X1DDC])),K[0X1dEF])+K[0x3282]);K[25194]=h;end;elseif h==0B1100111 then if not not K[14636]then h=(K[14636]);else h=1905623092+-(J.N(K[0X2eC1]+K[12930])-K[15223]+p[0X007]);(K)[0X392C]=h;end;elseif h==0X1_A then C=(4503599627370496);if not not K[0x629B]then h=(K[25243]);else(K)[0X373e]=2549731208+-J.N(K[0X4fF9]-p[0x6]-K[25194]-p[0X8_],K[0X00_6F6E],K[0X5F9a]);K[0X7585]=(31195223+-J.s(K[20473]+h+K[14636]-K[0X3B77],K[0X11__67]));h=66+-(J.i(K[7644]-K[0X3cD6]-p[0X4])<K[4455]and K[14636]or K[28661]);K[25243]=h;end;else if h==0X31 then g={};if not not K[0X6920]then h=(K[0x69_20]);else(K)[2559]=-2456400868+-(J.I(K[0x373e]+K[0X3B_7__7_]-K[14596])-p[0x8]);(K)[0X00f52]=(4294967182+-(J.i(K[0X2A31]+K[28819]-K[0X3282])-K[8075]));h=(-545320996+-(J.g((K[12930]>K[0X5F9A]and K[0X626a]or p[4])-K[25243],K[0X1ddC])-p[0X5]));(K)[26912]=h;end;continue;else if h==0x5C then F={};break;end;end;end;until false;local O=J.F;local q,Y,v;h=(0X8);while true do if h==8 then q=N.byte;if not not K[0X6689]then h=(K[26249]);else h=(0X1Bf_55e5C+-(J.U((J.s(K[14596]-p[9],K[7663])),K[0x1167])+K[10801]));K[26249]=(h);end;else if h==0X47 then Y=0X1;if not not K[0x3e54]then h=K[0X3E54];else K[0x15A3]=0XaB+-((K[0X4fF_9]+K[30085]-K[0X2EC1]~=p[4]and K[0x392C]or p[0X01])+K[0X7585]);h=754974842+-J.s((p[3]-K[0X629B]>p[6]and K[0X9fF]or K[0X3904])+K[0X40d0],K[0Xf52]);K[0X3e54]=(h);end;continue;else if h==0B11__11010 then for z=Q,0xFf do F[z]=E(z);end;if not not K[32422]then h=(K[0X7eA6]);else h=(0Xe__7+-(J.G((J.G((J.G(K[0X6920])))))+K[0X3E54_]));K[0x7ea6]=h;end;else if h==0B10001 then v=(function(z)z=H(z,"z",'!\x21\33\u{0021}\u{21}');return H(z,"\u{002E}.\z  ...",f({},{__index=function(z,n)local N,U,l,H,w=q(n,0X1__,0X5);local s=(w-0X21+(H-0B100001)*85+(l-0X21)*7225+(U-33)*0X9_5EEd+(N-0X21)*0X31c84B__1);H=Z("\62I4",s);(z)[n]=H;return H;end}));end)(O("LPH&fX:e\\(^+2QAT=%:z!'*:]#&\\R#@V'QsoG%]U+<VdL+<VdY/R)Ed$6UH6+<VdL+<VdL+<VdL+<VdL+<VdL+<W:%,q(Dr/1rP-/hSb/+<VdL+<W9h/hAP'0.8%k-9sgK$6UH6+<VdL+<VdL+<VdL+<VdL+<W'^+<VdX0.8%k,pjs(5X7R],q(/p0/\"t,-n$;b,pOWZ-n$_u.P*,'+<VdL+=o0!-mgPR+<VdL+<VdL+<VdL+<VdL+<Vd[.Ng>i5X7S\"5X7S\",qL/]/gr&35X6YC-71&d5X7S\"5X6Y@-n6c#/hSb//hSb+,sX^\\-nZVb/0cbS+<VdL+<VdL+<VdL+<VdL+=]#e/g`hK5X7S\"5Umm!-m^De+<W-^-71uC5X7R],q(5o/g)8Z+<VdL+<VdL+<W9f.OZMf-n7JI-7U,\\.P(oL+<VdL+<VdL+<VdL+<VdO/0HT25X7S\"5Umm+-7Buf-71Au/2&4o-71uC5UIm+5X7S\"5X7S\"5X7S\",:Y5s/hSb//2&>85X7S\"5X7R_+>+rI+<VdL+<VdL+<VdL+<VdO+<Vmo5X7S\".PF%5+>+lb/h\\V(/hAY*/2&Y+/1rJ,-n7JI5X7S\"5X7S\"5X6V\\5X7S\"5X7S\",;(3+5X7S\"5UJ*+,mkb;+<VdL+<VdL+<VdL0-DAa5X7S\"5X7S\"-m_,'+=\\]b.OIDG5X6PI-9sg]5VFE0/hA;65X7S\"5X6VK5X6YE/0H&d/1`D+/g)8d,sX^\\,9SHC+<VdL+<VdL+<VdL,9S*]-9sg]5X7S\"5X7S\"/1;nm5X7S\"5U.m(+<VdX-9sg@5X6YG+>,!+5X7S\"-7gbo5X7S\"0.&qL,q)#D5UIm4/1;hr+>58Q+<VdL+<VdL+=Jlc+<W't-71&c-9sg]-8-nm/3kF.5X7S\"/0H&X+<VdL+<s-:0.\\G8-6Os,5X7S\"/0uMe5X7S\"5U[`t+<VdV5X7S\"5UJ$.,q^;m$6UH6+<VdL+>4i[,;1Sm5X7R],:G2u,=\"LZ0-DQ+5X6Y]5X6_M+<VdL/1*VI-nZu&.Nfi[5X6eA+<Vsq5X7S\"5U@Nq+<VdL+=KK?-7C>r/hSFs/d`^D+<VdL+<Vd[0/#RU-7g8^-mh2E,:jr[+>5u5+=nuh5X7S\",:5Z@,pO]a-m_,*.NgB05X7S\"5UJ*+,=\"LZ,:5Z@5UId'5X7S\"5X6YI0.8;80-^fH+<VdL+<VdQ,q^N0,9STc5X7RZ+>5uF5X6VB5X7R]0.n@i+=o/o-nd&$+<W9i-9sg]5X7S\"5X7Rc.OHPr0-rkK,:Y$*5X6_B-n[,)/hA=o.R5Wo+<VdL+<VdL5UA$0-6Oof5X7R].NfiV+>5',5X7S\"5X7S\"5X7S\"5X7R]5X6PI-m_,D5X7S\"5X7S\"-7g8^-pU$_5X7S\"5X7S\"5VFZR5X7S\",;(;m$6UH6+<VdL+=8Ed,paZd-7U,\\+<W=&5X6_M+<W3`5X7S\"5UJ-40/\"t3,:FZf-9sg]5X7S\"5X7S\"5X7S\"-m0W`-9sg]5X7S\"5UJ$)-pU$E.PF%80+&gE+<VdL+<W9_.O.2,+>5uF5X6_?.R66a5X7Rf+<VdL+=\\[&5X7S\"5X6YK/3kO)/0c\\g/g`hK5X7S\",9ST`.O?Dp/0dDF5X6eA+<W.!5UJ-6-7T?F+<VdL+<VdL/g`5(,=\"LZ5X7S\"/0H&X.OIDG,q^_q5X6YE/0H&X+=noe5U@aB5X7S\"5X7S\"-nZu#+<W=&5X7S\"5X7S\"-7g8^+<VdL,sX^\\5V=Yr+<VdL+<VdL5Umm/,sX^\\5X7S\"5U[`t+<VdL+>+cZ+=KK?5X7S\"5X6_?+<VdL+<W9d-m^3*5X7S\"5X7S\"5X7R]-nHJ`/h\\h,5U@Nq+>5uF,p4fn$6UH6+<VdL+<Vdl.Ng>j5X7S\"5X6YK+<VdL+<VdL+<VdL+>,;o5X7Ra/g`hK5X7S\"5UJ$)/1N,#/g)8Z+>,2p-mg>p,sX^?+=09&+<W4#5U@O(,75P9+<VdL+<VdL+<W!^+>5uF5X7S\".NfiV+<VdL+<VdL+<VdL+<VdL+>+m(5X7S\"5X7Ra/gWbJ5X7R_/3lHc5X7R]+=nfe/g)8Z+<VdZ-9rk\"/0bKE+<VdL+<VdL+<VdL+>4ie5X7S\"5U.Bo+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+=09\"/hA4S+<VdL+<VdL+<VdL+<W'\\+>,!+5X7Ra+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<Vmo-8$ho$6UH6+<VdL+<VdL+<VdL/g`1n/1*VI5V+$#+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdT5UJ*7,75P9+<VdL+<VdL+<VdL+<VdL,;()k,sX^F+>5uF0-DA[+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL00gj:/1:iJ+<VdL+<VdL+<VdL+<VdL+<VdZ0-DA^5UA$*,sWe./0c\\g+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+>5uF/1rR_+<VdL+<VdL+<VdL+<VdL+<VdL+<W-^+<Vmo,q^;m+=KK?5X7R\\0.\\4g+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<W=&5V+N;$6UH6+<VdL+<VdL+<VdL+<VdL+<VdL+>5Aj+=09\"/0HE-5X7S\"5X7R_+=KK$0.n@i+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdO5X6kC-jh(>+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL,:Xfg-9sg@/g)Q-5X7R]/h0+O5X7S\"5X6VJ+=]#s+<VdL+<VdL+<VdL+<VdL+<W-d/gVu\"-9sgI+>4'E+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<Vdl.Ng>i5X7R\\/0HJs+>,oE5X7S\"5X7S\"/1r565X7S\",p4fe5X7Ra+<s,u/hSJ9.P*%l,sX^B/g)VN+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<Vd[+<W-\\5X7S\",qL/]+=\\cd5X7S\"-8$Dc5X7S\"5Umm$5X7R\\+=KK?.Ng8p+<Vd[5X7S\".Ng,H+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+@%/(+>+m(5X7S\"5UIm1/g)8Z+<VdL+<VdL+<VdL+<VdL+<VdZ/1N%o-9sg]5X6YK/gq&L+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL-7CJh+<W9i,sX^\\5X7S\"5X7S\"5X7S\"5X7S\"5X7S\"5X7S\"5X7S\"5X7R_/g)Pj$6UH6+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdX,;1N!+<VdL+<VdZ/hAP)/1`>'/1rP-/g)8Z+<VdL+<VdX0-^f2+<VdL+<VdL?!T$6$47mu+<VdL+<[!Nz!&-YF!WW3#z$3:,,z!#Q,WATVd#FCB9\"@VfVBz!!\"i@QN.!cz!#PiG?Yjg$#'Fg&@:O)>z!;MU?(^j\\XD.RftFCAWpAJbMjF^g[;!!$o,HItNMz!!\"lAQN.#Y\\<A/q5o9c4?X[JU(jfD(F`JTuF^ZD(DK]`7Df0E'DKI\"3De3u4DJsV>F*2G@DfTqBCi<`m+E)9CCi<`mF*)G:DJ(LCFD,6+AS,k$AKZ8:FWb+5AKZ,5@:F%a+EVNEF`V+:9QbAaE+gV?+=BiZ87,+f?WBp'5tk9I;^W])@:O=r/f4b'EcQ)=(^=SjEc#6,$3gJ1z!1*Zc!!%P3aZp[HD..NrBG^q\\?XmM\\C^RuYz!!&>czi,:jt\"CbeWA/GJW?Y!koQN.!c!!\"]u5Ss]HFE2)5B,CkdATVNqDKZj)3[c:b.k+[`%16C-z!!\"-,(]l<S(iUU<ATW'8DBO\"3FCo*%FspsFDI[d&Df-sU/hSRqEb0?8Ec*!GF!rXn/h%oSDIb:@F(KH1ATV@&@:F%a.!m(@+sh:S>p)9Q/hSb!I4QLf+CAJiDId='+?^i[ATVNqDK[EV/hSb*.3O$f.3Ju9z!!!!9\"]&fUCh+@eEcYo.Aos@>z!\"_D^z!!#SU(^=\\lF(KB6(^+GbDIaRk?XInnF*)G:DJ'dhFEqh:(^+>^@<*1i@rHL-FE2[E#'+-rF(KG##QOi)z(]eUn#'b)s@;KbHz!!)LSQN.!c!'mL55Ss]8Df0&nF;P$iQN.!c!!!#g5Ssc=F`(]2Bl@kr#ljr*zQN.!c!+7&;5[=AVz+q9;n(^4A_F>G\\=!!!!Q)$\"VA(^tIsFDYT2@<>peCh8q5!5N_,,j.H#AH2]1zQN.!c!!)qh5[=C-!?`3a@rHL-FDQ71\"98E%z(^48RE,Tq;#'4?lARfhKz!!#5K(^+JmF^c0mF(KH*ASu[X!!!\"lKVQRR(^+\\aFD)KoE+*6l$4Qt8z!#PlH?Ys^l(^=Vi@<?!mQN.!c!!!!Q6PohK(^+;nFCbd]z!!!\"czi$@bV(^+_fG]Xc+?XIYmC`!=t@:F%a$3pP2z!-T1d?XI\\^GA1r*AU#$l$3^D0z!1*Zcz:d>@7z!!!!9#'+-rB4Z0%\"*.sl(^\"5cEYo((Df^#@Bl7PjW@AG%s8W-!QN.!c!8n=K5aMHNzE'Y<EE+<<mC`!:aG].U0M%>*ns8W-!(]d2F!APDuCi<`mF*)G:DJ'dk@W-1$ARTJCz!!!!aQN.!c!!!\"<5Ss]!F`Lo0BF5ISz!!!i>?XIks@Mf>W?YOCgAU#$rFEqh:De9gh?XIV\\(^P5%DKTf*ATF+;z!2)Up#[^qKDf0&nFI)t-z5X:Y9z!:W4bO9,4?!=.]f!s8ei!WrO!f`K_+p]kQY!<XDKV#g`$/dim+>OhkD\"&K(A%5AY@!s`6:!uMgr*sZK^\"#D#D*sWqk\"#:Z/!s_*o\"#1`&!sa)R\"#:r?!s^7W\"#9s'\"$cr%(GZpK!s_C\"\"#:*'!s]PC\"#;)G\"'lun+#52g!s^O_\"#9s#!s_[*\"!nb_!s8eE!WrN0%0H]=\"\"s`]h#RT[>q[ue1++j[#IOR7\"#:rO!uMh-0*eT[!s:;'1BRlI!<WE[0/G79(G>jqM#d\\\\%504b//p5]#GD/#\"#:ZG\"#2S>\"#2_b!saed!s8i_(G?$0!<WEY(CL<MaT;PH1+sFG0cLW*@flfT2\\uRI!F-!K!saM]!s:7c(BXp0!<WF@$LIj-D'l@d$O>bo!s8eq!<WEY$QB0QR0!Hm<s&[0#Ftnu\"&8q7$O=cT!s::l(BYh?!YZ@T3<K@b!s\\oT!s8W[$PrmMm/[:k*Y/Jd1(+`t#OMQp\"!P&R',Ln=!s8W`#6P&5r;m''0c(3\"#E8ff\"#:B'!sdW`!s::\\$NhFX#7E9l%g*'a!WrN1!ttbAo`>3t#Q4Z*\"!/[/,6tIU!s9G3![B3#_#jcA1'8a'#FPYr\"#:*/\"!/g3-OhR^-O7Tm!s8dZ!<WED-OV.(T`YB!!\"Ge+Q3!6OScb\\h/Z&TO!OVsJ!ED-7z%\\;__#9<mK>Ohk0\"&K(-71]P+\"'[)[\"\"jZd!s\\u3!tkh@4;.f!#9<mK%i#0KhjFUOncK+!*X;cL#7Ub;-3F>P>]l/1Ka@uM!s<:4!t,?6!s9MZ#6P3\"!s8co!s8N'z\"2s@'#DE3]\"#;)3!uqgV$O9f:\"#:)p!saAZ!s:;_)Zq&r)[cnM!<WEZ9+qC=!uD%o)[c`QW<35)0e3n>*tKRuBc@-V1.NDg(Dd/U>P\\C;!se?!!s;j3(BXnr!<WEZ-P$:ajT,Gc0ddV:0e3n>#JC9C\"#<e.\"\"Z)=0-:iP\")/\\V\"#<@g!scdI!s9MV(DAQ\"(BXo9\"TniC(BXap:DX*<jT>Se*\"N8^1-Z9O#K6]G\"\"\"*P\"#;A;!uqgV$Sj@G!sd'O!s9MR#7Cdi!<WEZ6PBP,SH8lq*\"N8^1,BFC#LNYV\"#:f+!uqgV$O;@h!s9MR#7Cd=!<WEZ'+Y0Mf`D6X0cLW*0cq&20d@>6#@R]:&dJLI#K[,O\"#9rh!s]D?\"'u'G!sdK^!s9MR'+5E`\"&&qG!s8f20*<pb'*B<]1BS^$,6MX!!s:;K*s3;q!s:;S(BZB2%g+O.'*Bs6'*AKE!s8WF%gNIt(CpTQ]`A3;0fKaJ0fp$N#H7h.\"#<@g!sb(m!s:8*'*AIs!s9MR'+5&%!s8W\\$P*=Z%gNIt%hAa^%gNIIm/[:k*\"N8^1-6!K#Ftkt\"'u'C!sb4t!s:)%',*-\".g$$a\"Tni^7iqg<;$-n:(BXap:DX*f)\\3$**tn`^',)T-'.4GU-PIj4i<05b0cLW*0cq&20d@>60ddV:0e3n>0eX1B!s:1Y#JgNF\"#<Xg\"#1`*\"#1l2!tlg\\1^EgX!s:;K*s2b1!<WF1!uh=IR03To0g?<R*tL:4*s3_iBc@-V1.NDg#LN\\W\"#2SF\"#2_J!seub!sdoh!s9MR#7Cd!\"TniH',M;eK`hJ[2(K=R1FF\\#5pIU%#GD8&\"!/6l)]TY5'/EW*\"#9rp!s]\\G\"#:r/!uqgV$O6h;\"#;eG!sbA!!s:;S(BXp8!<WEY)\\3#l',)HB,81/c!uh=InH&dp/1W4a#AjPF0eX1B0f'IF#H7b,!tYPB!saee!s9>U!s:;S(BZB2%g+O.'*Bs6'*DPC)Zp>Y!s8W1K`V>Y7'd-V\"/l5#(YSn@!S.:'!epc6!fd>F!gWo9!La(]!hob=!R:`&!TF.F!=b.lV?3b!rW*!!!!!RljoG])!s8cG!s;fc!LF/)$75iW!tGD8$Yp+P\"\"aTW!s]D?!s]\\G!rr<$!!!!%[,qAoB`eGl*t&/UM#d\\\\?3;,K,9+W))dO7!(GZ@;\"#1l&!sa)R\"'u'G\"!\\VV!uD2^!s9VY#8]-'(BZB2'*AJ*!s;bZ\"!7UM,m+5o)r^l;#@.E6?3;,K>o+Fr8-9Y1>o+Fr1(,$'#6b231'7a`#E]#h\"#:6'!saAX!s;bb!@%[O;$-nT*tJGYT`G5t>7r._#7Ub;1'\\0h>Ohk,\"'_K#'*AIo!s;cq\"![nS!uh=I8HT&\"U(=^;V%+gS!s8N*\"VDIL!!!!*OQHQK&H`+j#7CVJ#6P&5)$9sr!s\\o5\"TniR!s8W1&H`+=UC+I3\"98K<Z3((,!!!,Gk5bg=\"Tni3JHZ,X(le`\\!Sn&/!s8X0-KbC3#LrkX\"$Npk\"-Wfli;j#_>J:3o!Wr\\D\"9SaFLBE;6E]o9^\",d7El2h'K!s]\\G\"$M5;\"\"sni!<WEeIKLf\"K`V>Y>9\\7n4lQPGHX#>.Ifip'!J:CT>CM>.\"'amiMZEoaL'*J;!se>s!s;asB*/D3!WrO/ecD*=\"$J7=RfWiV\"9S`hq>g[kE(`iq!=,\"n!s;bBQN71mL'!hF\"'a=XT)f$!h#[Z\\4lQMF:L!5f;Zg6q\"'5R0q#LR\">I\":a!<ZP0hZ3g`9&fpS#8%%?>OheN!sbA\"!s:\\-!tS#\\!=KEBdK:!^#K[,O\"%p]:$P*K!\"p4rjq>g\\R!XFPc!s:^_!<\\YjE0gZn\"-NajrW/Jj!saqm!s;b6P5tajM#d\\\\>P\\D*\"'`>;?NUPD\"9S`hc2e\"p>P8(J!s^gg\"'amhqZ-d(XTS_.>D`Ko!<ZQG!P\\X;#FPYr\"'_&n*s2a6!s;cE\"$6TJ[K-Ip#I+F7\"'b<ub5h]LXoluN\"'aUadfBOUeH>sV>IFXG!s;a/^B4QCo`YF\">Fko^!<WSS!s8X0[K<3)!sc(5!s;d,!j;V,>6_D7\"'aac[fHR9R0!Hm>KR\"_\"']Y]\"'^cfEruY=!s;d$!j_q1>G;/-!WuZ,!kSL9>8FsT!sbY*!s:^_!<^4?#MB1]\"'Z8e!WrZN!s;cm!V6<o#MfLb\"']rH!<ZOEWrW;-jT5Md>ODQn!s;b.Y6+k3]`eK?>E/a)!Wr\\h\"Tnj2Q3$FT!sbe-!s<M[!Q+r,!aFpl`rQ8I\\H2j89!SO,%gToO!s;b>rrN:,U&orL\"$QJ]\",?s`.0BZVV?-,e\"'^oio)]\"u@eTp+4o,0]qZ:a6!rE&!!se2q!s9/@\"\"X\\B\"Tnj2g&X,7#H\\%0\"'^)h!Wr\\L!s8X0XoeV(\"'a1TK)u,[f`;0W>FGY(!s`NB\"'\\OX!WuZt!oj=a4h:^tk5nj?lN..nr<!-(>FGTE!<WS+!<WF.3qiXW#E]&i\"'`bIT)o+!ecVZK\"$NL_\"/c3)L&n=V!seW)!s;cA!j;Y-#DE6^\"\"aTW!sb(o!s<Lt!f$ik!F+gjMZNtcf`_H[&-E:B4mE(N%r`$iWW<@P!<WE6!s?RGBa4_B63@Gp>ET\"S\"'[ZR!sa5V\"'aI\\ZNC;6Q3+Mt!scpL!s;aW'*CCL!<X-$g&hEr#GhJ(\"'a%QNrfDfaodh/!s`fJ\"'`bHb5qcM50j94>J^Hj!Wr\\$!s8Wg;?Of=#GhS+\"'_o/UB:T]Q3.5e!scLA!s:]t!Wrr<jT>Se4f/;`T*#>s\"Tni,z!-4+^!='&9!s]8;!s]8;\"#^Ad!sJc/#:9NT\"$Fm4K+,F$!!*K.!!!!$U#uF]N<01a#E8ce\"#:6G!s8We!s]PC\"\"-/4JH?(m!<WF=#m2[_f`VBZ<s&[0>Ohk8!s^O_\"#9s#!s_*o\"'b<u,6LaE)l3T<\"!7UM3<K?p!uD%E;$-o)-6!%kDBArc>lt15ncL*=:]hYR<s&[0#>#\"\"C7,/+)[@Yk\"#:6K!s8Wi!saAX!s8em!s8WF4$OMdPlUsh-U.^t!sc(3!s::\\3s,_e!<WEZ$U4^q\"$ZkmN<'+`!s:Ue#Ftkt!s`rN!s8We!scL?!s8dZ!WrN[\"$6Si[/g@3<s&[01'\\$d#NYsg!s8W5\"#9rh\"!7aY!t,25#;QYp!sd?W!s9kP!s8W-56Drk(I(\\[\",-a\\M#mb]1(-;K#Oqfs!sc48!s;cu!s\\o`!t,25!t,29SH8lq>Ohk,\"&K()i<3o3\"9TSJAHN#i$V(:(_#a]@1'^#G1(-GO#L*;P\"!7b<\")0t%!saM\\!s8W-6N[Rq!WrN[\"#C#]\"#C$7\"#g;er;m''1'9<7#MB1]!s`ZF\"#9s3!s8WY!sdoh!s9VM2ZmbI!s9Mn0,HAK.g$%H!WrN[\"#C#aW<35)1']<31'903!s:1Y#K6cI!s8W]!sc(5!s::\\2Zk-,2ZmbI!s9Mn0,Fl\\!WrN[\"#C$$#;ZHr.g#l/#;6/aeH,gT*sXS(Be'8f1']H7#E])j!usBe(C-c>!s::\\7fs!]\"9S`]\"%*/4#=AT-3s,R(#6R1G$UY!u\"%*.qnH/jq*sY:<7m@(X*'6A$#9<mK1(QGK#IO[:!s8Wi!seW(!s::d56D.m\"9Sa([12U7pBOnL.g$%(\"9Sa1ncLZM:]i3g>Ac(r#K[)N\"'5R0!sbY(!s<:0!s](Q!<WE(\"<A4#)#sX:!\"u[$!=+G^!s:Cs(E5+c)ZrAB(E3bf(BZDt#6P4-!<WEZ',(I'(Dd/YGln.(+!1SB)]Kka!tu1MD$'k^',(Hd!s8c`$O6b=<<E=Y$O6bh%grIEJH5iT1+*G3&-EFF1+O\"?1)h#31+sRK#6b231(+`t1(tH+#F,;l\"#:f7!s^7W\"#:5p!s]hK\"#:)d!sJc/#7!g&\"#;)?\"#:f;\"(*,l+pU+1\"%!(p\"#@OkH5HmD!<WEN!s8W*%?:I;APmT5!L<bT!M0=;&u#E(!<<*\"!\"$R*!=,.r!s8e!!<WEY#7CV=B`eGl(D?mA!uD%b-=I8eFTV^k-=I,a)$9tH'+Z/i0`qM4'-@;]\\H)d70aAX\"#>G:&!Q\"pX)^?TE!tPVs!s:7g,6J0b!s:h.#8[V2!s8d^!<WE,BaY.N#m18T-4pIf>lt0U!s8Wp_?1#Z7`#68)djI$\\H)pa!s;$0!s]Vf-<1iejT,Gc>Ohk,!sbY'!s8cO!s:Fh!s8dj!<WF.-5-IdR/mBl5pm$Z!Q\"pd-O80&!s:h2#8[EX\"!8TiXT8M+#9a0O0af?20b5o>#K6]G\"!]J9!tR*k*s2bi!<WESe-?Ya%p]hZ)_i!F!s_g.!rr<$!!!!/OlcZL)$9sG)$9sf!s8X>r!LaO\\ISo_!s;'rlN75Ik5teg#9a0O''fW%0F&<p!rr<$!!!\"HL?npGN=#ai#E9&m\"#6t[LB.K3ZN6g%!sf\"4!<Y+W!ODe/@'9U;!?h]e\"Tni]VZ@;10rk>M!<Y+W!NuM+#C-CR19Ub_!<WQu!s:<f!l\"a<#CumX!ttb=VZ@$6!s9VQWrW_cZN4\\@1:%%k!<XDOZN1RAE<?:UUB(H&#E8`d!tYR4!<Y'W!G;K>0`qM4])cOH#<;kg(T.99!s`*6\"!7o_!=pQY!<\\;r#F,;l\"#6\\SUB(H%5m%2ojU_Lr2p24(SI[Hu!BUB<cN-N<@flh^!=,\"n!s:=Y!QtKGA@%'nb5h\\MSH/fp<s&[0#H\\\"/!uKDe!s::lWrW;-aT;PH1\"-/e!<Y(.!QtKG1\"u`T!<WS?!WrNZf)a1u\"#8O2`rQ8I_#XW?'#O_P3!YQI!s9@g!<WE/blInK:]ma!M%28d!Oi(3#Qr6N!saYa!s::(!Q+p?#GhJ(\"#7gs_Z9iob5ndI!sf\"L!<Y(\"!Q+p?#Q4Z*\"#87*^B\"EB\"4$uM1\"-/e!<Y(.!QP3C1\"u`P!<WSs!<WE?dfBOQ1\"-/e!<WS_!<WEYY5t*n\"'b<uZN1.5q#LR\"1=H<:!<WSc!WrN0]`eK?%D)YY!kSI<h#[Z\\C69,2WrWJ$%Kcefb5l5X#I+@5\"!8?&!=oEd!s8WQb5h_@%0siS!s;U,#6P5$!WrNZdfDf<18b6+!<Y*X\"5<hY191N7!<WS;!s8W\\Y63AW\"'b<tgAqB]q#UX#1!]lm!<WRh!s8Wj!u',a/COXK!HSLB!s8W1bn^B`>Ohm&!<WS/\"9Sa3])fYI])`/q!s8W\\1VWqm#E8ig\"#;[I!<WeG!Q+uR!F>l;!<WT0ZN1.5\\HE!:1B.Ef!<Y+'!l\"a<#JgNF!sf\"@!<Y)5^B\"EAPlq0k%DMq]!l\"a@d/sIQ%DMq]!l\"b%])fME^B\"Sm!s8X,!s\\o`VZEh!!scpN!s;@%Wr]%3?*=:8!NuM/aTDVI:'7g'ZN1<9\"9S`8^B)4R^B\"Rj\"9S`]o)c)r\"#BTPZN1.`qZ=5-!seK$!s9SL])fYI#O)?n\"#7gs:BLjp\"9S`\\_Z=BP#N5df!sc(@!s::$!Oi(31!]m8!<WbJ!>>Pi_Z:DQ0uj=0!<Y*l!m:TH*XfR\\cN+Hl!>>P?nH8pr1#i;h!<WS+\"Tni]hZ:Uq!sb4t!s97p!<WE/]bLVO*kq`R!Q+pX[fOAIVZ@$Z%Kcf/])`\"f#7$A$!s:9U!J:CT'*A?7!=.!U!s8cO!s<;k$j4BJ#Fu;+\"'5R0!sdok!s:;kMZEo_MZLL-)_m6OK)l&f!s=G^#PeN*!scLU!s9UZ!N,t9!DgT6\"0i\"7r<EE,#K[P[\"#6hWK)l&f!s>S)#DiWe!st:pUB.7n0p_p=!<WS'\"p4r_ZN6s)!sH^VVZE+b#N69t\"#87*QN71Cf)a1u!sf\"X!<[6%!RV/$!=/E0!s<N\"!S[Xl!sd'T!s::<!BUAgf`hN\\2rao@JIXEt!T*n[#N5jh\"(ME8lN%7@\"p4s5Y5ts1Y5nlj#6P'7\"1&\"11=H<6!<We?!Q+uJ!C=$mZN7N9#FPf!\"#;[I!<WeG!Q+uR!=,;'!s;r3!NuOG&I5]K!s;:#ZN7B5#O)Ep\"$sO\"])fYI1>;lF!<ZX1[fHRdhZCCj!se?#!s8df\"p4r_f)iPb!tDjC_ZIFN#K6oM!scXQ!s::,!NQ5'8-@<A\"(]._cN++QaThnM@flhj!B8U2\".^/]f)[r81\"u`X!<WS[#6P&U^B\"Fn%L:)e!s:<n!m^lL#D!0`!tYRP!<WR\\#Qk/K#JU;W!=.ip!s:9u!KR6`#Or'%\"#8+&:BN?#!Oi(31\"QHH!<WbR!>>P?M%0Ui%*&A^!saek!s9O`!Q+r9!=.!X!s:9u!>>Pib5o?Y!seW-!s:9u!@It(b5o?Y!seK(!s::$!G;K>Pm@Ho1\"-/U!<WS+#Qk/K[fOAIVZ@%A#Qk/K^B)4QVZ@%]#Qk/2\"31EE#I+O:\"#@UmcN++Qfa%Z^?3A4K!uq]h!Q+pC\\Hi9>1.+8.#Q4u3\"#<YJ!sbA'!s:;W;Zd9$#m18N;]epL\"'5R0i<fYh1+tQg1,Cuo#F,Vu\"!2Y.G;>'WHNOn1!sB6h!<XTEWr_&XLB0,f!BUAgW=&e114O3E14oUK\"#>W4G68)`#m18N>9@&\\\"()-8km@Lp&-F]j1+,!_#JCKI!utf`?SZP0!sd3]!s::\\#6P5$$NgJN2`ifN2`CgDh$X;e1)hSC#IOm@\"#=M%!utf`?O+OW!s:;#.g$$5$j-SeB4h;OJI2J]12CA%#JCHH!s8Xd!<WR\\$NgJP2]jt65<ArPN<o[h107Z^#O)Ns\"#=(j\"#=4r!utf`?SZ,$!sbe4!s9T/+$U\"8$NgK@!s=_f2i@\\=obTB)@fnK1B*0o9CBGVn+);,7#m18t\"1*db,6snL!s:9=!H/&FbmFOT1.O\\6*^_#:#O)Tu\"#;Ag!us6]1C(/k!s:;O9*5Ea#m18b?Y9H\\@qT-RN=,gj)?'[n2_mHR!sd?`!s9):7fs\"<$NgJd#7CVh$P*>&_>s`P1(P0'1(tT/#FPu&\"!/s7.l&>&\"!0*;0*h.V!s::p*s2bA$NgJNdfJ&$<uA[QdfHWQ?./h`!Rh&S[1!->#Lrt[\"#@mtf)Yt0dfJ&$dfD2<!Rh&O#I+[>\"#8O2^B\"EB\"4mPU#GDP.\"#8C..g$$q$j-S<^B(YAdfB^$$j-SQ[fNB-])a:k!<]S:#MB4^\"\"\"*P\"!sE;R0E`uSJ))-/gJ[C!sbY3!s;@%b5njZ*6SB/!QP3GXUP@7&-KrR\"#A%#b5h\\XcN+,E#DETh\"'5R0!sc4C!s;cu\"4I8Q#D!<d\"#?bTb5h\\Mq$[?-'#O_P!!eJm!s8em!<WEY_Z>Aj!scpW!s92=\"2b-E]aY&G0s:VI!<ZQs\"1&\"1:]ma!Ymsh;#6Q]]!M]Yt'*A?;!AY=h!<WSS%0H\\ecN2Jq!sd3Y!s91b!<X#@nI5R&-0##s(BXoA'*A>O\\J#(G!=.Ei!s:=1!kSI8#FQ&(!tDjC_ZIFN#DEBb\"#BlWhZ3faW=B\"4*8:MO!Rh&SSJ;5/C>fR'WrWJ(&d&54\"2b/i\"XsP7!NQ5'\"02G)#ON!'\"'rYB[fO5E1<0F5!<WRd%g)nN])fYIY5nmM%Kceg'>jhQ17JBd!<ZQs\"3U]I#It<H\"#>o>Y5n_\\0=(Z]#D!Bf\"'5R0!scLL!s:<B\"1J:517&*T!<WSW%Kceh^B)4Q^B\"Sq%KcfJYnmMC!=,;$!s9jm!T=7c#DiNb\"&Zr;`W<[P#H\\L=\"'u)9!<Z(!ZN7B5?*=:8!NuN.ncQ3!\"&K*#!U0Xk\"1J:5#Ghq5\"#@UlVZ?lT_Z?e=!saMk!s:9E!P\\X;#D!Eg!uRp:])f)9#Pel4\"'rYBZN7fA#Ls=e\"#@ap^B\"ER^B)(M])`/u%g)nN[fO5EWrWI!&-E\">nI,L%1TLPW!LEgQY5ssjWrXun!ODe/4Kedl!NuM@VZF+)WrXur!Oi(3#Mfmm\"'rM>^B(qI1;a.-!<Y-i!P\\ZI!=/!&!s<:h'EcMZ#Isj;!sf\"H!<Y+S!QP3C+c-]H!QP3Gfan5f0uF$Y!<WSS&-E\"h`rWpU!sc@J!s8f,\"Tni?!s?FA#E9H#\"#7[oK)l&Zh%0Yj-bBB]klD%*%0H]-\"1&$7!=-FQ!s9\"M!Q+uV!=,#)!s:iq!ODg9!=/9/!s9\"I!Q+uR!A`+*_Z9iEr=B&5?,$EX!P\\X?fb\";g:]ma!Pn+>5!Q+uJ!=+;j!s9\"M!Q+uV!F>l?!<WSc&H`,>ncQ3!!sbM3!s;i4!ODg1!=-.I!s:<V!NQ5'1?/G>!<Y+#!j_n0#O)g&\"#;OI!<WS/&H`+@\"1J:5#Per6\"#B$@[fHRdlN4[!\"#A1(^B\"EAN=c6p1>`/F!<ZX1ZN1.`1UdAe#Gi\"7!ttb=])`/)&d&4kMZ^Ql!saYq!s8em!WrN6^B)4R^B%<G!P8BI!@PJ[\"2+jCh%Bel1;a0o!<WSK&d&4F])feN])a\\5!l\"a<#FuJ0\"#;gI!<WS7&d&4gWr]7%\"#@muY5n_\\b6#!N\"#A%$[fHR9_%HhP#LrkX\"#@=dVZ?l:VZE[rQN8kR!NQ5'1T(8S!N,rQQN<ub!seW7!s8eu$j-T5!s\\o`_ZHk>!saYr!s9pO!<\\;c#K[_`\"!3d0?^h'DRfNWa(C-cM!s;U,#6P3n'*A=AnIl!,<s&[0#JCiS\"\"1\\]\",RKmeIr#e0tRI!!sd'a!s:9q!Oi(3*tPsa%gT?Q!s:9m!H/&F_%QnQ#OM`u\"'<t[qZrc'1,lfG!tDjC_ZIFN#O)m(!sb)+!s8f$(BXbF)k-l#!=/E6!s:7sT)f$!m1TR(*nLE;gAs)$!T*n[#FQ8.\"#:PM!<XLa#2]IA!=,;4!s:@:!T*pm!=+Su!s8e%\"Tnj(_ZK*(^B\"qY!P8BI!@PJ[\"-jT+q%No5<s&[018b/R!<Y++!j;V,1A_-Z!<Y+O!k/1415>tD!<WS['E\\G'])fME^B\"S9'E\\FH])feN])a\\=!l\"a<#NZX%!tE!G_ZIRR?+U-P!P8@fLBG9l!tE!G_ZIRR#LO4f!sdWq!s:<2\"1nR9'*A?K!=,G9!s9:r!hTkX$7E.\\\"76X)SJD;0:V-W0_%-d]#6P&Sf)_QT!sbqC!s<<:'EbB:#IP6J\"'5R0!sbA-!s:9m!T*n[#I+gB!uScRhZ9n]#K7D[\"'sdb[fP@e1<0FU!<Y.8!TO4<!=-\"I!s8f2VZ?lTVZEh!!sdp&!s:KO!<_j#18b/V!<Z(!Y5tg-*ttCM\"%Ssa!s<$8\"/>l%i=uFs19U_F!<WR\\('=XnRfPSQ&-JO*\"#6PO0*<r,!Fl3dWr\\7^!sd?k!s:9q!J:CT'*A?S!=/!'!s:9Y!M]Yt#Qpt*\"#B`SWrW;G`<E.?WrWIE('=XnVZE+b!sbe@!s8c7!s8e1&d&4`cN+.D%0s-B!s9T_(q0na'1Iid1&D\"?!<WR`(BXaZo)\\Rdmf<[d('=X[o)\\.Xo)T)](BXaopAkd,#Mg-t\"!%%9f)b=@1B.CL!<WSg('=XnrrL.@!uL\\4!s8dZ%KceSo)UZA!=/Q=!s<N2!UBdW\"#?2Do)Spum1od+'*A?K!=-.O!s:=I!kSI8#H8LA!sb)%!s90o!<YRlfbX_m1@G71!<Y+K!Lj)l1A:gA!<X(3!<^fg\"UF!&!s90s!<Z:+knaF(-_g\\E`<?M:(BXaPP5tbR#K7J]!scLT!s9j-!W<`8#MfOc!s!1t!DP#V\"5s8$K`bJG!Ta?a\"/Q+1!ndVM!D2e^W<8gqN<>^RA]Y\"U!L3]M![XB<T`^\\bnH'<M!c=2(^]UhD20$G6[0\";J\"_!)cPllHJ!jMco!hBCp!kAF/!n@<;/c>_;!]dLei<\"]7h#cC5$2\"=m!Q>-=!Y*BT_#[QD\"2tAa\"3gqE!ZBeraT4i,!N?+1!R1\\&!aUojo`EMCM#i//JHNRdeH>1>f`SV_OTF\\IC\"399!Bng2N<7c7z5`t10#8mUG#8mUG-3F>P#8mUG0CfA>$A/LL%g*>2!s8dA!s9&h!ttbA'a\"O<!>,;3!!!5'k5bge\"9S`2W<<;*1+O^S>n\\S5:EotT!=-jM!s::l-Nb\"a\"\"+=\"!s8c7!s::p*s45B#6P2s!s9/l!uq^s'*AJN!s::t-NdWj-RUYg.g&'f)_2/!!s:hF)`%_a!<WEh!tua]Gln.E$NlLo#GhG'\"#2;2\"#:*7!s^[c\"#:rC\"#;)K\"#2;2\"#:fK\"'l]r0/=J&!s_g.\"!81(\")/t^\"#;5O!s`ZF!sdog!s9kP!s::l*s3/Y\"!7cY!<WE/R03To:CdQD!\\tE>!ttb=.gNll!s::l.g$Fe\"\"OW0!<WE/]`A3;'*A=a#E],k\"#:N;!sdW_!s:8F%g*'5!s8X2%kfR@i;s)`1+t]k#H\\(1!uF$$\"#;Mk!saef!s:8B1BT@!-NaUe!s8W[59Bt^6R)[<K`_DZ0gdGn#DE3]\"#3.b!uF$$\"#;Mk!sb@u!s:;/.g$%<!s8W[5:6O<W<*/((HV^$#Q4Z*\"'m-12[@G,!s;O21F=k-2Zj<<!WrN[.k^u0o`5-s0gdSr(HV^$0fq/n8-:pU(HV^$#MB1]\"#3\"j\"#3/%!uF$$\"#;Mk\"#3#!!seK#!s9?$!s8e9!s8W[58+,(YlY\"01+t]k#E]&i!uF$$\"#;Mk!scpL!s:;33s.3%$Ni+N'*AKe!WrN[0097j59g78m/[:k>otRI#OMQp!ttb=-O6=J!s::l-NaV@!s8WnQj:/([fnN#*s3/Y\"!7c-\"9S`2.0BZJ'*Fp2#PA0$\"&Bj<.0kD,!s;=@!so2M!s:Fd!s::\\$NgY(\"9S`\\)[?I##9O$i%i5aP(B^'.#DiTd!s8W=\"#:B'!sc4:!s::d'*AL(\"9S`]#9*bO!ttbAaTM\\J0c(&s#MfLb\"#1;k\"#:)p!sec-!s;j3$NjW(!Y5A<eH>sV#H\\\"/!rraD\\cQ#3JH7p2!@]TX&s31p!!!!2Y3#`i,m+5S,m+6(.jkE()$9sg.g(J+#9a0O!s:%U#8%%?#E]#h\"\"aTW!s^C[\"$M)8#7#YZ\"'u'C!tlCP-k[I$8-`Q*!tlg\\=9isN\"'_&m(B[m!!?2+G2$3qDIKKr_B`eGM*s3&Z70<X2$O_ss0bXos#>G:&&gmc(#71J7E!HX!!XDj1\"\"\"*P!ttb=.gH@_\"#2;R!saY`!s9@T#&;`kz!!!D1joG]5!s8cS!s:R6%^$5:%42/Z\"#:Z#\"#:)l!s^C[!uq[Z#6thC!tYP>!s_6s!uq[Z#;R5+!saAX!s::l$Ni-h%g*%W!s::\\$Ni-h%g*dZ%gN>N!s::h$Ni-h%g*dZ%gN>\"!s::d$Ni-h%g*dZ%gN>>!s:Rh$R7A6#6RL!$Ni.+%g*dZ%gOj7$Ni!h$Ni.3%g-)F%grVb!s8cS!s8N1aoR%oc2l>oecFJ*h>uU:7A^(c!!!!&VWIma4Tbck4Tbd-*tKS>FU',rD$'kM!s9WZ(BXbDncKg5:]hAR&-EFF#;$#[%KceH7h5\\(1'80l#=S^s70<Vs#:0HS1'\\Tt1(,$'#8I=C-3F>P<s&[01(t<''*A=M#>kR*#<`.kD4_<<%(-*k%jM0I\"![n_#m1hG<<E='\"f;;ljoO`JJH5`N!!!A3joG^H!<WE/N<'+`8-9Y1#H7_+\"&B^8#m[.)!s:1a'Cl5e_?1Gb#;lSc-Pljs#=S^s1D^i4#<`.k>n[kf#;$#[!Z)Ld#:0HS#FPSp\"'$-RncLtj!uDb0',M<OncKOA5o11N#DE0\\\"\"t0$ncLNQ)tF(9D$'l+(De\"q8HT&J$PW(542M(5'0HL5'*hqJ\"%WM1\"(^F%m0Tj(2@fll-P$:s#B^+N>Ohk4!s]D?\"'[)g!s],7\"\"\"*P!rr<$!!!!)Qf\\;R0`qL_0`qL_0`qMK!tPJF!tPJh!ttbV#87V'#871Z$PO$U.0BYn#7h=M%0H\\j$NgJ9&H`,-p]8S>m/n[;!s8N)6:LqT!!!5%joG]u!s8d>!s::`'*DVM'3,9_!s94\"&+0[p$8EV=!u)[V\"!.gT)[AA*\"#:Z3!uqgj#;R5;!s]\\G\"%WM5!t?%['*frg\"\"\"*P\"!.sX'.4Fq70d*#!t>bO$O96*!s^sk!s],7\"#^Mh\"#9rh!s`fJ\"(2KI<<lq7\"#:6#\"!L)@(C*qB!rrQQ/iGF-rW0h9z$('cT#9a0O#9a0O!j`!%%a>/(!s8W\\#8[Ia#8[Ia!tPJA!s8c`!s\\o53<K@=!tPJh#871A!ttbA&H`+H!t,29.0BYP!Y'tez#1Vc9#H7_+!sbe+!s9kP!s9bincKg3-6F<7)$9sGm/[:kD'noV'*m=o!s;gB#88it(BZB2$NgW\"!s;j3)Zr1m!ui0aD$'lE66?:7Gln.QncKC)1'\\Hp0c(3\">Ohk8!s`*6\"'Zrk\"$cr%'-e1=!>>\\a!s;:#)]NW@\\H*KOYlOq/>H.`L!saY`!s;cq\"![mQ2$3qG!tuJ+#9*b\"*t&/UJH5iT!s8c11'7md!s8o5#>#\"\"1'7a`#FPSp!s]hK!s6:LRKhCKD2n[o!Z)+#!<WEK+!qpt\"!7Ui+!qp3eH#aS#I+=4!s'_j*s^0o!s8eE!<WEq'-APK*s:m2#7Ub;:EK\\D!XHgJ!s;cu!uD&D-4^1`V#g`$#Q4Z*!uN+%)[D?(!s8SL![A?`Pl_$i>n8/)(aC+E#GD2$\"%WM9\"\"tH41-<>T+!1`A!WrNq\"!7UF!Z`-Y!!!!+#2WF$G<U]35>[cPF9T4S5L>Q77jK1Q5K5(\\Zq>!!5G7primKm656+NSFKHP<5:H9k]J6bU5FBD(V!!Bq5Nt!3c.;OOU1sc*YR,H\"&4IlYjLZ@P&6Kp-^]E^;.nnA7BHQjnDmX)%RMEph1fP+R0/+&?&\\tXgOEbKllkV2S7=#a,QBOVeQN.!c!!'f2^m>$$!!!#7Ekn\"A!!!#7)UQ8,g&M*Ps8W-!QSUER1G^i9^R\"p#!!!!a<PXq$z1!MtMz!,1*%(b@4Y5mT[h`fJUQRQ<<?6e$4`MpG5+G-Tt&3%u2+pl%+(+R'u\\r%P_@oLtSOz?uWoJz5^q0IQN.!c!!(Aj^m>$$!!!#7EPMomrr<#us8W*+PQ1[_s8W-!$KM-cs8W-!rtkg9=;VfKfk`$QR)k-L\\/3&#l+c,De\":L\"8s]MX!!%PZa1rMn&n).*s8W-!s8W+cz!5N<a(^0.9C[IGgz^kBK?#1^Ef8/,U$z!\"I5hQN.!c!!'fH^m>$$!!!!N\\j-ULs8W-!s8W+cz!5MpV(^?2#GPX2\\$Kh?fs8W-!rtl+6FC:K[&iWnBTGRtGX.$Hoc`Ut#(^OYr_mO'UKH-<Yzcu[!hz!\"a1d(^AfN9Q$9=QN.!c!.[_l^^B*$s8W-!s8SDczJ3q&<.9qqNodIJf(]tF1D[K\\Is8W-!s8NodZ2'o>$8:uNq7_'TTV<2p$$eFr7HbtF9hJCjXTHag.n4d;ikkm\\hO.1W\"]@ku[XAtug7Xc<>m@@J$@i*Us8W-!rtkkdn-C9V\"f;1#MADNYzJ7ZN_z!.\\(bQN.!c!!!5H^m>$$!!!#7AAFN3zrmnk%\"gDTX)ZL/?rr<#us8W*9#K7\"?-SsWI(b/'GS^c+Z_E0Gk<gIHra1tNKGI.3CE[=,moUI0qI(0g%r\\:bAs$mi*QN.!c!!#8t^m>$$!!#8@dQeWUI8/NNNl_9RdMN<mABh<]`(\"\\Rm[!nR!!!!QGJFRCrr<#us8W+cz!*G/pQN.!c!5OZE^m>$$!!!#7FMJ7^s8W-!s8W*+&,uV/s8W-!$D[Y$s8W-!rtl5g^Mt]37*8'7^t__t4dQ-Kz/AN).9,nN[*nI\"kQN.!c!!!\"/^m>$$zC;:Ys5M[PW8GP3F,A5uCXkQ_j$\"JY%88?*&q3i-3%CV#r9(@&<#N\"e_R'o^LQN.!c!!%O:^_dIb`4*99:Ch;iM,3H(z!;*K\\(^@_0S9<Ib(b.FOhsSJ'i.2qN<88SmV<Z>k[4+^6O?]`iG1Q6]hGPn-^Vcg^Q8jB)(^mP?#OBabDRH9iXHrnezDSR(k,7):+#Wlaj`XOYFn!=\"Sz>/1skCU*Ciof\\(LIFeZdag,9O]SRg0Xs^QBz!+98$(^.0JcZp?1I)KFiQN.!c!!%OO^_dpiB\\%U,bJd,d+2$lU/MLMas-lRj@AlHLQN.!c!!%Of5aMHN!!!!a?,2d,zI*P!Dz!&/H/QN.!c!!#O!^_e0NmuJosYE=`r'/l\"AQ*XI=`W+GJWneZq=.N(QW:Q>Uz!.2MJz!.[YV(_R:eM%=XrF0ZSVi$<og=t8>^QN.!c!'mU=5aMHN!71U.lTpj;z8;Ftt$3V+iL;JZ;nJ&p.z!.]I4(^2Vgn:bbHz!:YWVQN.!c!!!Rh^m>$$!!%Q1`5%]>!!!\"L\"Ob'mjo5;[s8W-!(^!FD'+1K6s8W-!s8NoB\";N>8lA>0!*gZj,!!!\"8]g.na!!!\"LGf;q7z!'kD:(_F8LrpcDh!]1PYl5X/fJCg+fz!&q\\1\"?UIYc'JD1!!!\"L:;E1rz!+N_NF8u:?s8W-!(b)Y`:8.%)@A^LjjeG;$7'3r9`$V7bd?oPO-](L[^K!.[W.iCkT32sI/(aZ!.5VL%^7Tc^40Cj8V/Q8/XrBu)?u(QonKT/X>n'-.%ZqtY7XEnUQN.!c!5K9)^_dFqPR$I&)jdKt3QW*Ujt*h5!!qKPJ$;.sDJbdRDMX6YTtI<>U6bi[!!'fUe3FiY'hR3q`@a&K&#M=Qz!!#d0(^V)'EOlS>f,Tj<z!-k)#QN.!c!!#8f^m>$$!!!#OJ\\W*A4bi<`,Pp='i9XBu8;!r!M_V%-N1?GD2OI+'z!$H-oQN.!c!'h%L^m>$$!!!#WTYMBo7PIUZ[<?Ld%L9r=%uW;+hXC\\o=qP.<Ra]7\\_CI6J*/Z<EQ(&'BD!72czJ7cT`zJ>h*c(^OH1r]i:`=i)\"*7PIUZ[<?Ld%L9r=%uW;+hXC\\o=qP.<Ra]7\\_CI6J*/Q?JS=^;WDr_`bbI<@gJ-g)@';2$@HGoU3PIH&L:JT^SkHs:\"(Si9A&WUSmA1!T+nV<G2!!!#7S'sWhz!$Gde(^+U,VZ)n^zJ7HB]z!$HC!(^1VhV5qS%z!3gLZQN.!c!!#9)^_d3APQ6Z/z!8qG((^?Z=.U!(MQN.!c!!%S\\^^<4's8W-!s8SDczk_d0Bz!:YBOQN.!c!!'6E^m>$$!!!#WG/+puS\\gqpg));n<R>5f94u2FJkI8W`W?ZVebWgUN*!Ud((#o(-M]UX/2GL=@$pfnjd,rI!!'esd(g\"!rr<#us8W+cz!,uto(]u*]SsKEW!!!!A@DE5cs8W-!s8W*9\"9BOj,76j=s8W-!s8SDc!!!#7qU**Fz!0DQCQN.!c!!!![^m>$$!!!#/KtnN3KlkpNGn;Ne^6\\g\"z@DJ30z5\\\\\"@FoVLAs8W-!QN.!c!!(qo^m>$$!!#:\"gV=X/Nke%!QN.!c!5N0t5Su$/e\"/;,jjDY76oEF/\\?oOSe$R\\iU4ESK:mW'3q!Z0*YC7H/LM6*d/!LkWBV&flWb,er$$I-oFej:0@7:!7VTRa(QN.!c!!#8^^m>$$!!!#?LVO`29%:]2c)-g-z5Z>Ibz!\"[pOQN.!c!!!\"%^_dE&n?*at,T+ni:)F6tp3(?e.@@9)z!.]+*$KqHhs8W-!rtl&.@JF%6jm7JEQN.!c!!'fB^^B<*s8W-!s8No\\'j0/o`%=+k*ia$+%3/4=V]:d_!o^(_F$UK_>Fg;\\(Pt!VhZ*WUs8W-!QN.!c!!!\"5^_dZaGH3R*rCo*kA_I'Q>8q4RQN.!c!!\"]p^_dB/TfAN6,qQf$(_A4`0s!0Xp:Rd3=@NPkQLU:Az!-l;Gz!3gmeQN.!c!!#8n^m>$$!!!!qFMJ6fs8W-!s8W+cz!5NfoQN.!c!!#iO^_d:GTh?ld3=>fds8W-!s8No@YSLqR\\([mLz!!%2XQN.!c!!(Z35aMHN!!!\"lBYYGi>rgHo$V6GIz!-!%qQN.!c!!!\"I^_dNP7&1(_l6MRg?6\\&V(`[=kn9FLgLHTUD<[Z/&;mYT3/F90BiV?K;;mM_iz!)^OuR[KS3R@2/]$H)oDs8W-!rtl?,\\F`#(Bfkd,4=Rb\\MXKb#QN.!c!!!:X^_eO5)*FOkcP%FhhA8mO_R=6ZR9$iZ#Xb3NC@rt!,&NN:A\"WT)iiCm]\\dB#Ks8W-!s8No?G^/n2]FYEKrr<#us8W+cz!-!Y-(bAc)%0XTD;Tg1+`hlm]<tHKTa2?+C_K@\\X7*IL\\bfBkSDrRT)DK5o8U\"]q=s8W-!s8W+cz!'kJ<QN.!c!!$DO^^<1's8W-!s8SDczTR4Hk/-^'S?M-31&Pbh!XA@#^H6+cZ\\XHA<O4k6O7Y9rDU>/?-\\5Q_XX\"U;[g6Vd>!!!#gKts#Tzn8lC3z!+9f^(_TgYL;J`=rA_c1j6c6afp??tQN.!c!!\":e5aMHN!!!\"qZ9X`Vz!,]Lg$&C`2R=X0o#4i2js8W-!s8W+cz!$H?uQN.!c!.[eZ^m>$$!!!!qMSPPYzi+0Wiz!!#X,QN.!c!!#9,^m>$$5Zm^Zk<Tpk<fkHbeXZ)'M3e2B!!!\",C;?/9zR#\\s!#=XUX[]`YVQN.!c!.^oh5aMHN!!!#'Fhj=DzA%OuC&^LS<&]j,C7\"p`S=Wm,\\#)a<)BUETeXDqdd*gZj,!!%P+f>*^Qz!(=Vhz!0k[BQN.!c!!#9F^m>$$!!!!^fK]eOrr<#us8W*9\"R._XZPWp?2@p31_7#[1z!$o@Hz!40C)(^\\00jB#BeLaqk[!!\".CqZ$\"M(^rqFf7;URdp=1Y:RIIKzb`Y5Xz!'k/3(bD>?p$<'J.\\l4LcCTT(hamP1hl?l=>2B)s9U*b\\6nl2r=3>A>f%NnLY:5e<z?t-p<z!'k24$GlcBs8W-!s-E]c!!!#gEPRn@z!*I#Dq>^Kps8W-!QN.!c!!#9-^m>$$!!#:.hS>HXzgp984z!\"ZBNQN.!c!.^cf^m>$$+O'ibmm39?z:kuiQz!6;W8$F9[2s8W-!s-E]c!!!!UfYEgRzJ7$*Yz^g,>R(^dOeNH5S4]hRgh(^A21`Hg^e$>BG=s8W-!s-E]c!!!\"l@_e<1z!+*GJ3WB'Ys8W-!(^(D&g\"@2Q*HhoB:S#Jf!.n`+Bi`fOz!!%\\fQN.!c!!'6F^_d?o+>\"07&]^f9z5Q]G#$L7Wjs8W-!rtkp\"XXs23QN.!c!'nr]^_d7Rcna<b(^qY-ih!^c,<OH>#$mPqzYeE@>#Da<hOFkkLQN.!c!!$tX^m>$$!!!#W@)/*/zaG%Erz!$G[b$5NR?s8W-!s-E]c!!!!AA\\aW4zcuHjfz!8qe2QN.!c!!\"-\\^m>$$!!!#WEki$2s8W-!s8W*9&e^4\"pSqZkVMcHf&nGa\\;tXjkz!!&\"oQN.!c!!\"-]^m>$$!!!#tg;'$TzY`6F8$jtVga!El?)6kbD%18^+s8W-!s8SDcz.)*J6.AFaRW[[5G%4X/!R,`s9(4)bWmA=a%Zb?Z2&hYPp::NG=%M&\\/ZNultz^fNc.6N@)cs8W-!(^5SsZiEFZz!8q>%(b3:A^<t^>nTLhk<HC'#eGY/D<-GT7Tr<&%\\%,][%qR'0*jIRR%1<A+(^YSO\"H8te\\Zk[lz!.[>M(^]aq&+6E)@l%.&\"n1u7-SUkez+DS\\/$NmsV36(90]'t54QN.!c!!\"-R^^>qts8W-!s8NoBE;%[-9=e+Cm?[eQ!!!#Ke%h:MzZF`@/ir8uXs8W-!QN.!c!!$DE^_d7>c2eDV(^]u/)3@eV*<cBLK)blNs8W-!QN.!c!!%OK^m>$$!!!\"LDSQU^s8W-!s8W*9\"k#\"jOU2j8i+9'ue<h#I[[<&XB.]+0z!2+nY$EX:-s8W-!s-E]c!!!#YaM8,urr<#us8W*+>6\"X&s8W-!$H2uEs8W-!rtlo[C9T\\'s$qJk=I/$;DH^,P9A5dVoXhXR8/$,*R8;cn$B\"l`s8W-!s-E]c!!!\"dK>8<.S^-r0eRt3Kz!8tVYz5\\AV5(^Z\\':5QbRP)V:8$%VeZpfe*em!k?%!$E$Ps6i7?z!7nBiQN.!c!!\"^2^m>$$!!!\"Ze3Fi]3lX*/&q8<lb5l>*QU\"iCz!0kYlQN.!c!!%OF^m>$$!!!#7BYXs0s8W-!s8W*+6i[2ds8W-!QN.!c!!'6M^m>$$zFMJ_C+fVQhRXaAeM2m?30TlXP\\Oe-hp\"7`rh&8^`h,=3H]9!GqHkI0MDW$i]!!!!ao?ff1K`D)Ps8W-!$A\\Z]s8W-!s-E]c!!!\"\\F24+BzJ7?<\\z!$H!kQN.!c!!$tZ^_dE_FaXMYOhiolCR5#$!!%Ogh7sj3<`g/F,F\"Mp!!!!ambGSp$[*&@Y,5?MR(re.QN.!c!!'6C^^<^6s8W-!s8SDczJ4IBl/)X11XNSt*j/@fphE``c#e7#ZCW,t9S\\3be<\".\"SnG9JT%]aUa)i\\Ig(]l.s(_(g26(Gj92hQ6!C.-ho$]]rkrqTEVEk&()QN.!c!!&sW^m>$$!!!#gHGGjIzJ98Sn!!!\"L]\\-(H(b:0Z9^b\"a\"-=t7-U#h^VV>6f7d--4F3]1pj`c,nS\\s3hW_JpF]W['IK,?'t[On<8(ijCW_</a_'mHlIp?,rP^Z#u-'kD.1($oTX%h/h6[02XF-C4]4!!!\"L=hp@(zn92U6z!2*o=QN.!c!!&su^^;t!s8W-!s8NoB;lW>rpfe*elkh:-<R>5f94u2FJkI8W`W?ZVebWgUN*!Ud((#o(-M]UX/2>\"2A\"EK+m&ekH'`\\45s8W-!QN.!c!!%OA^m>$$!!!!aF2/,<s8W-!s8W+cz!8qV-QN.!c!.Z6A5aMHN!!!\"LE57e?z!-#`?z!2+bU(^91&\"Ti%tz!8qt7(^L'SCQ!u^H^=^4!!!\"lDSR)?3Di0Lnct(4@0Ss8W1%%&J^I3m?,6>L[?;Q6V-4%lUF;sNdP!>p7UqPNQN.!c!!#9p5RKdUs8W-!s8Nocdr2OW#iVUP)i3`;i]Ma2CQDRQa/0TYn!kp,msP#s$.]^]m#KnCq<f(+T-(*;N1[hpYa5=i!!!#7@_`==rr<#us8W+cz!.[n](b.rMq*:8dme=qr1?,EuS\"*_Edg*Cp*bj9kd\"pVB!(7mG=fq5.O9)G(QN.!ce`HhW6'hQO!!#:2gcu4Vs8W-!s8W+czJ2k]eQN.!c!!#9+^_dLpp9LI?>')7nNo;e1QN.!c!!$D8^m>$$z;o\"_\"z^i.#Tz!-!V,QN.!c!!!\"3^^A-]s8W-!s8NoeY[1l\\qnTdafQfZ`EBPtBaI]U4'ZV]jm*4>(gca.PWi*f6>A-9\\[osm#$=<c4s8W-!s-E]cz-GUHJ28u50[bFmUr=U'sluqqaNFaT()*E\\S8Z)<Q@CE-_YIk:j&b,+BgiF;^m`<uaSM\"S)<mPUCf>Cn\"2Q4;T1+='ligXfq3o`]poJ3f6rBM)r1bKUJo0ms.QN.!c!!$De^m>$$!!!\"LD8;J<zTPVE1z!0D08(^0R6Em9pNz!%u'Rz!2*r>(_KQG[Z#9WR_TFC61:LgZAo]ez!4\\$((^NmQD'gO@cB8MUs8W-!s8W+cz!5NHeQN.!c3JRRK6'hQO!!!#7B>Bi6zpk-AKzJ6pL9(_D-Rd]jLD0G<%7:3f,?+@$8Rs8W-!s8W*+<WE+!s8W-!QN.!c!!$Dd^_d5bT<h@1(^^o7&[:qCUUKP\\(^1f!I'O\\./1NdR1(hBF-'F`'0^F4n%eBO#Q+f[tgEphG\\gDp,FteVIP]pjJ>kW8Q9c+,4B_j\\R6Hb\\qzi,$2qz!8qk4(_/QA;$u8ef4.8]3f:D$QN.!c!!#9%^m>$$!!!#gJ\\[TPzIEXsCz!)0U^$Ae]]s8W-!s-E]cz5JWTczJ5O+K!!#9Zm/P['QN.!c!!%O^^_d^J*VlNSk3P?h<0=QASg1#4PEu7L!!!!iMng/2h8P]\\z!(F\\iz!:YKR(b.FOhsSJ'i.2qN<88SmV<Z>k[4+^6O?]`iG1Q6]hGPn-]u-abT0I\\-QN.!c!!'fR^_dC4&!+g4K@8\"dQN.!c!'i$j^_dX,ENnPa+m?3ZfAfkb8u0*,d/X.Gs8W-!QN.!c!!&1U5aMHN!!%PE`5!3*5XeGtFL^JN9rpI`k=[Q[EmXQ?BFYjoWdnQYKF\"s[&PS,Q3Uq0rEFk.D,8^bDZVdO3eY=XpYS[Kkcada,$&4.\\WWe?R^:>(0A&\"a,G`fD&Mn%G1;G</QqnK)H=8$2n?d(U6Ik8dRq1]\"q?GF[\\D3k5&!!!#7C;:Z:XRa2`^Q_1u<.u7%[HYS.oJ-eMcnkAM@*uKgQjJ!G[a1jdT/M&'2.V(O.ZUGdk5>e2$+@%]`&FI)P*UnE+d*0,[mGGem[D%jb#Arl`EK,2ZBG7qp](9ns8W-!$<I3,s8W-!rtm4SPn9^f$R^Vp_MdC.#!u+V'tU4*bSU+9<_:JSjuIXXn+28<-!J%+UDO3fWf`QQ-^Of5!!!#OM85GXzJ%i^bz!!#$p$;CI!s8W-!s-E]czA\\]-4F&*EkBYakPHY>te66+o\\bAT?Q-\\h;Y:OJ)V:L%,Gkr/%`9'Wue=Nm*3zJ476j\"V9Mf`g<\"lzJ8`41SGrQgs8W-!$=s/9s8W-!rtl$)(s77inn]hCz!6`YQ(b+,mUutWgCDanMT-Xbh^-gka0&XF9>=K?JI?+QCAU=Lb!^j=)SM)1Rz!!$WHQN.!c!!$DK^m>$$!!!!dYeZS*zBZiXX\"8SR:(]oh@(^cqjU!Q<l-0=`M(_Wj8BW@(\"LuJgMMnrWt-^JdeQN.!c!!!jn^m>$$!!#82f>*^Q!!!#7$e7KZ%HA!U`Q;J)7hmU[S]-oqz8_H@qz5gn6!(^m,^N.!.)Dp`s,d?ah5!!'eZfYEgRzE.>Ziz!5bHq(^SjVM[4?+\\X\\udzfS%$W$*\\Gh)W6kL0AIBGVth/=&4@3]LU2_+ArZWp)OCF(!!!#sUd17Hz!#WKg\"R4E&oa3PUs8W-!s8SDcz?us+#$4.4(G6TU^^k:_c(+]8@W[)W/^7k'bIKdfUoIeF+4lp[Mz!+9`\\QN.!c!!!\"!^_eV(He,1'N>Xo%r/J<@^hb=cH[IH8b/rT-#g[LcT\\&\"Z_DI;dV5;63>AHTmz!'jW$QN.!c!!!VN^_dV@9[;nRRA%b/:04b.n=np/z!$J%%$82AYs8W-!rtl-Y?)-#nCqD3pp/%(Uz?t@%i//67+Yf@/98,SA+Ent.Slte.]QcP)fq$>Y]poo=reBTk.(87P@rDRH$MO+;C!!!#7<PXq$!!!!a<m\\W!\"MGdn/scP<z8AH&LeeMtR3?V8!@!E$.rr<#us8W+cz!'jo,QN.!c!!#F+5aMHN!!!\"\\Fhj=Dz$f/T8(._klb/P$]B+o/JbZLphmTPT0VY3KGz!!\"gj(^GW:9CjAq=I0!f!!%P3gcu2rs8W-!s8W+cz!75]#QN.$D*;0@#5o9c\\@6>`a(^Ou0.6/IY*6/ltC'9k'!!!!a);7=_5QCc`s8W-!QN.!c!!\"-b^m>$$!!!!aJA;M\\rr<#us8W+cz!&/E.(^@D8lFbUgQN.!c!.YL75SsX[L.Q4hq#CBos8W-!QN.!c!!%Om^_dJqT[8)I*eSNFO:sJY-NF,Gs8W-!(_?'+b7f_Z0NCm)Dkt2+9F>D2s8W-!s8SDczcum-jz!2+MN$Ln)qs8W-!rtl$E,R.3#]Mk+5\"m#YN-hEZ)z!&D?Vz!4KU,(b<0kj5PX\\7!/RSpcr&EJ_i^EW?i%>FDI27)JZ]6\\d\"h36dOg)I>hPZ>F,<i!!!\"lF24+B!!!\"L(;W8&z!!#U+QN.!c!!&[,^m>$$!!!#WDSVS=zBSaHjz!2*l<QN.!c!!$DL^_d+9(_s8rBc,ofi%E/H-LGk5,DX:%kk>f!li-qas8W-!QN.!c!!'fG^_eTK^.!G(TUO?>fcCW#SIbLorf::U-ONSl/\\E>kS[>&I!$YX^_l%%:2gq\"m!!!!a):cNhAnGXeAnE4%(_!tQd=?#]6c@u?U^daArr<#us8W*+zz$Fg$7s8W-!s-E]c!!!!ADSVS=zW//6Uz!2+2E(^/r#EKV.N*n*?/I!2q:4mSkA\\bM^GkEc/K!:o^\\mm39?zi+p+F&oMPYQ6Z@$maZ\"=3)r5t%C.FLz!$H<tQN.!c!!)M8^_eQK=a],lO43%?*`if$!qr\\ZfbX?/8-@^#W\\nFKiiUZ;+C)4rX_aRfE0gP)zCquA;z!-c3q!t>=A(^XIk]oR%[i8_,0z!2+>IQN.!c!!!\"?^m>$$!!!\",G/+qD3Di0Lnct(4@0Ss8W1%%&J^I3m?,6>L[?;Q6V-4%lUF;jHe1!8l6l6#$lme>%z!%Pbk0E;(Ps8W-!QN.!c!!(Ad^m>$$!!!\"lLqji4F&WcnEKs7bzJ<A2DQN.!c!!'f4^m>$$!!!\"PcG5bHzGc8EEz!0DWE(^X^(ehIH2R^BmJ*,I\\@cfuEPc`5bn438odOZd3/N=0t(If0oNj-K`G!!!!ADnq\\>z^f8+9z!!#0t(b76ac67\"(i?gLjAL#2#`%<o87&D1a;&BDNV[:O[5Lm._-j*.e*mp+772Q:>Q_\"b'pggfM.Q8=?8^o=P?9as^gJ2.8`=En-cF[iUJ.&=E&OXA.IB?u0.6YU<A\"<Q+QN$pas8W-!QN.!c!!$tb^^=BIs8W-!s8SDczZ+Idg)s]M.ojkKBg#3(!Zpl_'4(oUhB/@#<A(Le4QN.!c!!!;B^m>$$!!!!YMnkYZzd!!3kz5QoM#$K(m`s8W-!s-E]c!!!\",B##5t3Hnh/k>T3CDc&!E^=?CpS&YXuQN.!c!!!!A^m>$$!!!#(h8#?Wz!._j%.]U.&ZB7KGV%O`'Y\\X7nNcKO#'gBUt>GgkH3i;p,p94_I'(tXNhfJW$YQ+Y&s8W-!$??+Gs8W-!s-E]c!!!!aE53:ss!ql>LCACeFdE(.!!!!]a?Z'lz!+<U/z!.<51(^mX_^!-RL<KdsgU)5ge?O*cI-`/YEg]E3S2cg0lCbQ]/$/E!#`'6')jBlq/*Ban'c\\\"-7Ah59:_JZm!N.%u_[Cqn,z!&_P/!lhJPHN4$Fs8W-!(^=i3,W68M(^AdJ\"9Otf$98(cs8W-!rtl'em(uGr354lP(b.7c*<1o\"F+AO\"pFRL3QHP-\\[MZtsU]/N\\eV>`.:%PF$r*Nr'O1eU+QN.!c!'ou/^_dUE.(ALH$(K^X`?9qS9p:nDz!$&c]qZ$Tqs8W-!QN.!c!!!\"7^m>$$!!!\"LBYYGgd`[Xur>6`UHh/a\\9A1un,^[T1JC[qD&+80,1<X;[iHIFLeFS=glkg/gpk:5m\\t+hK>V(o%z!!\"jk$?,qDs8W-!s-E]cz?,.9_!CGCUUs\\$fQN.!c!!\"\"95aMHNz6bjNG?Y]kA2*).0\"kj<Frr<#us8W*9$*sKTY%]\"'oB$kl\\kVc5%Af>`ellVbl'piJ^hO43rr<#us8W+cz!'$*+(b3$RXX%DDo'=(WAk)T]pFsC+BB*em@[5H.jQoj2D!7USJVV0\"M%QSZ(b1:0&)MH;Y`[5OKIkGBp%k8a76):6TFY4iL;j:1mNPoX@m/8r9I[%hQN.!c!!(0e5SsfI*PngTU%NscQN.!c!!$D>^_dFFR@7!&K$4o5<gNdd!!%NohE[D-z!(+I<$'eRKk9e$t]BU4`[btM177LYcT%DIsT6hl!:;A`db/\"Y(.\\l]<EdM-@XP#^-+Qs]Oq(f;aM#[MTs8W-!(^)g^31q)pc0N8?[m.Fs:mV.^!!!!qNPLk\\zY^4*Oz!5NrsQN.!c!!!\"\"^_d5Mj(:@rQN.!c!.^N_5aMHN!!!!ih*@;,z!&23Tz!5NipQN.!c!!#pM5aMHNzh`r\"b=RgZUZbh.O<u;,?Q<Gi-$FKg4s8W-!s-E]c!!%ONb<VBo!!!\"LCWSi.z5Ub5L$Ln&ps8W-!s-E]c!!!\"lEki%[s8W-!s8W+cz!8qM*$BbAgs8W-!s-E]c!!!#D_a'OgzOE&(&z!$H'mQN.!c!!!RS^m>$$!!%P*`^#jjz&]R'Q.`:.1AJh]&\\guEYBC]jm+e.B1iqF4BAH2#Nc(E3qfbpZ[aSK(T7#8:<z!5MmU(^0uZ^\\id&$D=6[q$G5Vq\"i2O.q]5Zfq^dqc4@#T9-02mFoNu9IVYBT0\\a*ETsN)nmJV7+ZiT%qp$@^mQN.!c!!'N^^m>$$!!!#gGJG%&fYX)p#@bLZlg#Aq9\\2+7%&R2bU1S'U$1`CMM<YT^?/HJ20]V/PGr'fK>5F\\!nYDrs65U$[-qh-O*,j/aQN.!c!!(Af^m>$$!!!\"LF24+BzeBgGt&\"B4RrM2\"Cs)j2eW4g`QQN.!c!!&[-^m>$$!!!!qF24+Bz5\\%Trz5RQ:3(^\\p7[l+h3Mu+-Rz!)RmT(^Y<39uV3q+sW8;z!+:/h(^aMSN.MFCp3aLa(^YY1Zbh.O=&oiuz!\"a4eQN.!c!!&)6^_d<l`RA,h5!YG7z^g+Yl!^;R0z!'ju.(^S)2JM\\S-qA:%WD1WID?8`jgQ4fFKz!!!#7QN.!c!.^'N^m>$$!!!\",Ekn\"Az!!!\"cz!8sM8QN.!c!!#I-^_d1q__ROEz!76/0QN.!c!!'f=^m>$$!!!\"L>JQR*zLr7#pz!'jl+QN.!c!!\"-S^m>$$!!%P#gq]8FR@0J2RE<2\\\"Cbjljd,rI!!!#'GJKOF!!!!a_p^jf\"uMZM39=i]o`\"mjs8W-!QN.!c!!$tW^_eR&8^)+aT7[]S/uQBZ1+$5Yl,IBOGk4]/\\n1X7nf:)%0JCKhYrX<?%K[I\\X*grtV#4\"0.pL]e]42e\"\\R#.N/(8FBPmH?F8fNTN2rZrMEGLV;1<67,[-sM8rU5.2km>lSp#q:dEVStHQN.!c!!!!5^^;dps8W-!s8SDc!!!\"Lb0Iehz!5N$YQN.!c!'l7m5aMHN!!!\"0T\"pZmzJ6fr-\"@)W69:#VY!!!\"L?GMm-z?spd:z5UG+!QN.!c!!!\";^^?>*s8W-!s8NoD:VXZ(85+TR%hSi/z!5MsW(^P:%K!_+fA=!WSs8W-!s8W*+^&J'3s8W-!QN.!c!.]aG5aMHN!!!\",D8;J<z)pU\\c#;:4g4X*[TQN.!c!!'fW^m>$$!!%NhaM=,Bz^gk.ecN!qEs8W-!QN.!c!!'@E5aMHN!!!\"l@DJ30!+9aFs6`1>z!\"at%(^o#0RALr1H<Z]=e<^.8!!!\"l@)/*/zJ7651\"lhZkh>.rkddtO+QN.!c!!'f\\^m>$$!!!#7=25X\\&,?%<M7q4U8PGWk\"ID9,BpSf\"T`\"<Zmm39?z1#,#2,_-O=R5nl0bR8F$AY9:Ae/OaQ9f_VF4;auE.'.',PQerNGo-[ml9o<Pz!'k;7$C:_ls8W-!s-E]cz9Yctpz:jBdBz!!$!6$3L8-s8W-!s-E]c!!!\"L8AH&m#pJqb,'VdtOnS6DfP9jGdD;E9D9r[ajasTVF\\:3M;]XBALD=:)ITau(0`V1Qs8W-!$LRlns8W-!rtl%Bg#721MIgW($4d(8s8W-!s-E]cz,/=O^rr<#us8W+cz!.\\\"`(^e*f&@298!1*\"h$D%1rs8W-!rtl+jqfAOSaF:]`[J-!fz0QY$rz!.\\n$(^br#nI-@=5B+RW(^-9$(oEW\"z!+`m3z!\"aCj(^Ob4>f<:8VjJ;/A`)\\QKTo4`h_o-b&:8F2Tq.`Pc\"qYt*5HUgR?mmR!!!!#]\"f.5@*UV\\92On`-j^Ai_6\"f83%gih7!BOi4C*oqN(ntEH864d0(P3o$gV5fzJ4@Vq$3:,,!!!#grtl<5]42e\"ZWQ%\\B(rs:#?2ET/:ko:mlDNmO=@=[4j^L3gKA5[k`tpac@%b8GC=M&_qVDt:7=,PY)e*a_AE@p'MoVs2]MH^e1E[e5Fek1:10%\"%iZM6]5$S\\$`NM+6brGEX^TR*1r_smTCN=+/&@&NYPMTnd-5H2I?8J]Ri*Z0W)^@6N]m682ncM&K,aIJNS8ILm)d&\\QN.!c!!#\"75aMHN!!'h\"g->u^s8W-!s8W*+,6%WBs8W-!(]n:9QN.!c!!#8d^m>$$z8O/UBz8<(D%\"t9>H@dgcC.R3Mg;-\\fpp*XD$o=!:NI0]Anp+sQ/.._C:3STp^jeYS?0t=6?NeGRm#4`3fhO.3,z!\"aq$QN.!c!!!\\@^m>$$z:V`:sz:iO4:z!!%/WQN.!c!!'(*^_d-A.13!Ps8W-!s8No;E8$WYz5[2$jz!\"a.c$NC)*s8W-!rtl86FPceGB.@;l?fJ.ckc:$Mz!+3O.z!;M5_(^%O66l7HS1ObIV75;5`U_U60(mM^(1R'e=!o[fKY]kA^=O/:)$!?_FDG<ekJaf!+z^eqn6z!'k>8QN.!c!5KK)^m>$$!!!#gE53;'Jal_91I,9=0X`5_`3QZ$;EpL[AnGXeB'-jpzi,7U@QN.$$K)Yf=5o9o*io<p]=p,:'$Io(Ts8W-!rtm4ZdNN9GoHnL`AU9d[aWiWA''h2)'35^\\Yo&RIC\"Vbf.g&4g+5)d<6'hQO!!!\",BYYGs+2:J4D0T9(?5Mp6`FF/q4-opIz0u+,<s8W-!s8W*9%XAEpbI.nm4uh!O?@G_;z!4[g\"QN.!c!!!qf5aMHNz9u*(qzi*jEfz!2*u?QN.!c!!(r.^_d4.>a7/`.t/>U[LM)<H,fkh1e/326AF-P&V>:AB2Zp%^5A+T\\n(!!'4l1pO/1Sk$4-\\3s8W-!s-E]c!!!\",CquA;!!!\"L:Xq^sz!+9<PQN.!c!!&5<^m>$$!!!#adQeWOmU\"2*z!'l1P(b4o)\\>tY-h]+M2'D\\G1C<-\"ld]C7f%mkggn[#3d;?(hS)iJItB-`Z/(b8](%0XTD;Tg1+`hlm]<tHKTa2?+C_K@\\X7*IL\\bfBkPCZM6(DK5u9W#,s&co*5K0Ub?$\\4Ol1zJ5Oi^(_3,2OKR:C:047pqP3<+$M\"/rs8W-!rtm7n;]`2+APlJ5`3iO03&KIS;`%Mg+p!MKcki*3G]-$)0)1X##Oc?aU_+FKVr/SHHSmYt\"\\[;lGKL8ls8W-!s8W+cz!.[eZQN.!c!!#i<^_eQhaO^We/nc\\7cYV[o_d0Q+W4bJP.2^[rRr/]sj$r>+0sp*=5nHsK+UWJns8W-!s8SDcz!-5lAz!.\\e!QN.!c!!!\"T^_dLb=d<=[7!;1<;'\"b#QN.!c!!(qj^_dHt:k.:$c8@Ld)7C@hkQC%H/c5?0K0tt*!!!!a'Abt]+TMKAs8W-!(^kC&=s8(0B'F1W!Xe;os8W-!s8No>n[qFXdMOLNM%$Ta?UN3)DWcG0Eb:dY.>Fd$\\?h2YqP?-aZ<`)%oBMCjFT:aLc,1A'aP7\\)8sC3[z!+9BR(^/$FQ^8Nqfb`#!,$dSq[L2a.s8W-!s8SDcz3.o!`!kK,5z!'jDsQN.!c!!'fg^_d>lWqsZ(E2RlG!!(q6p&FJHQN.!c!!(qe^m>$$!!#9?fKbc'z8(,0[\"onW&s8W-!QN.!c!!&[6^_d=9U`+aUA@n0.!+>3`TBAM,z!2+8GQN.!c!!(?S5aMHN!!!!aH,,aHz+C`-Qz!$HF\"QN.!c!!$,Y^^<a6s8W-!s8SDcz!'@t5'5SNkg$TbPY)L@g1@?FgN&\"t&(^YA.f=mpYB@<%^.ed.*M%o@Q*e2u4RuX/c\"]&@X%f<9*^e<lE;$2>-]knsXjS\"<4+BYt:z!'jT#QN.!c!!!!h^_dAns.1*i;rScJQN.!c!!'f8^m>$$!!!\"L9>DALRti0cU*AN^z!!$*9QN.!c!'oo)^m>$$!!!\"q]YKj6zJ4.2>z!5NBc$GZT?s8W-!rsBVBs8W-!s8No>PX%>\\;jRIa!!!!a=hkjU3\\hNWE4M`0/CQZt\"\\P]<SE-\":z!-,f@z!'lLYQN.!c!!#iC^m>$$!!!#7DSR(tfbgLI:bjV$o^mfd(^Qt&\\+X!M*psjp@K_VSBrZR*C3+o-,KHca]&^[Zk,iIkr^VQ<mcW#YGl?sN^r$.lc<Q\\9z#`$3$!1*Zc!!!#gFhj=D!!!!a=jTDN/)ri<`V:$&)@JN-a3r0CJU9U06J$DB`8=8#/cVnF3I(d]V:[h#-KuG_$:t3ss8W-!s-E]c!!!\"L=2:.&z!!pB,z!5OB*$@r0Vs8W-!rtm4ZdNN9GoHnL`AU9d[aWiWA''h2)'35^\\Yo&RIC\"Vbf-j!+m)V^LA71/,Us8W-!s8SDcz?tmEC!!&\\kpAaSI(_lOjI>c/\\#(>=#DQ/[)RK!j9ORSS:z5\\.Zsz!1L@3QN.!c!!!!l^_dALM82KANATfT$9J4es8W-!rsFeds8W-!s8SDcz+Cr9S!!!#GLr050$@;^Os8W-!rtl&EpN^_a_L:KH$L7Zks8W-!s-E]c!!!\"<Fhj?R*eioW\\B_i+$/SetU><bs2A$:(s8W-!s8W+cz!3gX^(^X1$*<c+[;5fSCz!76D7(^ukS(mV<n)qHiW$G6`$s8W-!s8W+cz!!#L((]m6P$>9D=s8W-!s-E]c!!!!+V8*oQoB2@ui\"+M-z!+:#d$J>@Xs8W-!rsFGYs8W-!s8SDcz&;n7?.\\MgpljJn)UZfhFSq1b98GMW1Wrt@bh>A9ePg#+T0Y2I.b[NT^fh=#bz!.\\+c(^]bOA=(IM)e[unz!.]4-$7GiQs8W-!rtm8N8guGaN5!>[%:\\m6iN$e]WoFmd$SH^\\=l=NY!Dl`jZO3$C,=-S.j2Vuf!p&[iabnk*b#@6.K;T#6)T8<Y7ZGX@?74_f:<,,-f\\K.MW?UJ'XL:pM(^Cua^1\\t#@1'aKs8W-!s8SDcz+DAQWz!-!.tQN.!c!!%h-^m>$$!!%OK^q^cg99khD!!!#7g=efYz!!#:\"QN.!c!!$D^^_dM7o&GRC'mlNXl_npk(^@(pfor,QQN.!c!!#i8^m>$$!!!#7G/+qF5m`K'HJcV:C$oX4&G\"s&RAgB=eMo>p]m;!64YkgqRrE9O?grG]7R0M2z!4gt%(^?jn9PlAFQN.!c!!!!Y^_dbAUIVDrglDl<]9etK7kKcY[\\Q>/%DPT;bh.3G/!Kj'0d)e_z0Qk0tz!!)N'(b'C`No;OS+_LIj-\"D\\NK^JL9KP'98Ok@R%B?:O[s-<7\\BLRfj?Q7CZz!5MOKQN.!c!!!#)5Ssh2(H$`nLXl>*hNn3B!!!\"q]Kd;B]>=SRNgJ3_3n,_uQN.!c!!\"]l^m>$$!!!!qH,'cts8W-!s8W+cz!.\\UqQN.!c!!!!I^_dBL6b\"*8lOU4r(]pn)QN.!c!!!!W^_eBlE%R1[V=nA+b5TbJ]T,9l9n=>`[H#4Cq(i2#co8WcEmV>`(^AfM?\"TV\\QN.!c!!%7r^m>$$!!!!)MSL&38:?*C(^T3P?T[N_19QrDz=Fe1(#0;u=*(A9m.fc`;%'-U)6\\suE^*/JcBUB9ZbG859rL?%;Ztul*:tc`Zl]0hCqru,D(_1Fn6D\"PGVUa1\"nLm@6(_=bJ:BtrdQsS^\"?<UW7(RG+%!!!!aNPLk\\!!!\"Lkh*Zf$/h&afXpE;bhn`ez5Z#65.Q8=?8^o=P?9as^gJ2.8`=En-cF[iUJ.&=E&OXA.IB?u4.Po(4Bq,'fz!%u>XQN.!c!!'f:^m>$$!!!!aA\\aW4!!!!Od8*%8ec,UKs8W-!QN.!c!!&[7^m>$$z4MVd:3n@bbQN.!c!!!\"(^_dkH-g+@CB6aSAMQWIJ@F\"]`!^PGDA*B6Zz9#!WXz!!#3uQN.!c!!'f;^_dAci%@6-*i(tMQN.!c!!\"-X^m>$$!!!\"lE57e?!!!\"L=NE`E#;)cj/Ii4$QN.!c!!&+$^^?G-s8W-!s8SDc!!!\"L2:k)1\"VV'b]-n$&rr<#us8W+cz5g/\"L(^VI^!VO1edqm27ErQ+=s8W-!(^qm9].?7d3C]!c66d<sfDASt1_#keT6q)0Y!D?MDu9I8)bN\\0CPYdV,9U&n%77W5P9qP?H.nSbz5[;)A%;N\\dkKcfe.p#<i4eS,Az&9,FOz!!!SG(^U#2_?a:6J0($Wzn8c=2z!*J)CQN.!c!'h^W5Ss^C,00pBPSb:LD\"@=k]E:,-cJKU2LQU1p-dX[MLb!D1(^okd>p\\_hDAf?e-'nT3!!!\"<I)$R$?K7=Y9)ekjs8W-!QN.!c!5PM]^_d2b7NLubz!4on[QN.!c!!#9B^_dA463HeGqBYB7QN.!c!!!!s^_d.mND(/j4_>N=1)hi5N8qbsLh7tN$(LBYM82KANB7s[E4McLQN.!c!!(F$^_dNTmnLDRV\"Sd_/Q:-YQN.!c!!!#g572B/s8W-!s8No=]3Qhq(^N^uY;Z=S=IkcYzN75QLk5YJ]s8W-!$Anf_s8W-!s-E]c!!!#Jd(ktJz?u*QEz!.\\h\"QN.!c!!'*p^_d8jetV0sBU8]!!!!!r[QkZB:_hjJ7t4PF-:*FY`W2KV,\\*/@zTQe2<z!'kP>(^fhR@\"H?L$<>'<QN.!c!!&[+^m>$$!,h4sX[/9R!!!\"Lcc<hfz!.\\k#$N'l's8W-!rsB/6s8W-!s8SDczJ6]mVz!19]M(]ubVC6no#!!!\"L7_f@8s8W-!s8W*9#Ci`=$ODjc(_LokNk:]MB8jnE2-\\q2Au_\"2%02'A*2;3g!0I.uj=1uM_Cf7`/XHG;!!!#GMnf[ss8W-!s8W+cz!0DB>QN.!c!!%OI^m>$$!!!!QG/+q(%C_0+HMh6*$hN9nJJ\\O1IrJ_\\z!6i/BQN.!c!!#i9^g-sX%H;sNHMgRQ%JfN5PG/lr\"B?5(z!'jr-QN.!c!.`;65aMHN!!!#WFhj=DzJ:#'K#L5g*[>5_gQN.!c!!(qr^_dh1LU#Bi\"/W,ZNO)h>OT:cQEb*>W`X;YCs8W-!s8SDczJ6KaTz!.[AN$L%Khs8W-!s-E]c!!!!1G/0FEzJ:kWS$Ji'rCl@!\\$p`;LGlRgDs8W-!(_'n@EL0/X@t%*WG6[@M\"VS1Gl)^3O!!!!a@GX6d.RRR[jd7c&3icBYkAopnTc7?0@X\"+AjF:uM9cm'p=d^T\\8:K@S_@A_qz!3gFX$GuiCs8W-!s-E]cz>JQR*zi+Bckz!\"a:gQN.!c!._r8^m>$$!!!\"$LVT5V!!!\"L'[=E1#4Gh:H)XCQ#JCmV*Ns!\"(^mdu??:B,/R4+[g)(-J%j*tq0QVh/(^Zfjhe;EIdEpA[#u]2ic3ZbR&e10-z[)KhIz!/A_5QN.!c!.`88^^?#\"s8W-!s8NGSrr<#us8W+cz!.ND4QN.!c!!&[%^m>$$!!%N\\gd%2+z!,007z!5MdRQN.!c!!$d/^_dB0$m.Yn0QVg]QN.!c!!#8`^m>$$!!!\"L9YctpzJ7-0Zz!!#j2(^4[8VY&CU$\">BAn9X.VNH5p>\\n:O((^*[Q([[Ohz^iR:./HtN4o(Ra<9.gq&Y5q//QeFuPoHb0A5%MX\"&3fB%VaAMT=,+Fn,0i;l!T9:Ez!(\"C;)/+b:1neu?quXnj/5lhM4rb.N\"Oa=aJL(Z\"s8W-!s8W+cz!3h6oKolD#joG]!!s8c?!s8c?!s;uS\"0`-a#rW\"j\"\"+<U0aB-0!tl+HoDoX6!s8c_!s:]T!<W]7*<QBj!s8W*!=0)6zzz!!%$>!!!'#!!\"DI!!\"DI!!\"PM!!\"JK!!\"JK!!\"JK!!\"JK!!!.kjoG]=!s8c[!s8c[!s:7g$NgVS!s;#Y#iH/W!s]8;\"%WM)\"\"\"*P!tktD6jGjW\"$Q2Z!s]&W!s9n]\"!%V@!s9VQ#7h&.!s:7g#6P2g!s8cG!s8N(!YYP6zzz!1!]e!1!]e!/:IR!1!]e!1!]e!1!]e!0REa!0REa!0@9_!0@9_!1!]e!1!]e!0@9_!0@9_!1!]e!1!]e!!T.[!='bM!s]tO!s]tO!s]tO\"\"\"*P\"!@[N$RZ;a&I2G@\"#9r`!s_*o\"'`bL%g-&0+VOq_2$3qG!ttne#6PPC8HT&Z[Nc\"^#:T`W#8I=C(CL<I@0cc8!s`NB\"#:5l\"#9rh\"!@[N'*h56!s]D?\"#?ATJILEH!!<B+\"r71=zzzz!0R?_!0R?_!0R?_!0R?_!##>4!\"Ju/!6>-?!0R?_!0R?_!0@3]!0@3]!0R?_!0dKa!1!Wc!1!Wc!0dKa!0dKa!0dKa!0dKa!1!Wc!!TUh!='VI!s]hK\"$Npt!s]&_!s<KI#Dsc;efk@Q*$tai\"$Npt!s]'2!s<KI#Dsc3@06UN#7%CJ#8%%?E!HWN(N9TaMBi`',mVF\"4gGFt#7#MV\"$Npt!s`cM#HejJ,m+6g#7%CJE!HW*,R8#c!tYA9#:9Z^!s9)1*=(^N#B9hJ4gGFt#7!*g\")nJMXqu$^#Dsc;mNVu-%0q^j!s:]l$NgWQ#7%CJE!HW*,S.Hf#J(?L8HT&SRKL))jT5Z-!s8N'+92BAzz#64`(#64`(#Qk&,\"pP&-\"pP&-%L)n5%L)n5&-`+7&-`+7#R18/#R18/#R18/$3gJ1$3gJ1%L)n5%L)n5%L)n5\"pP&-\"pP&-\"pP&-%L)n5%L)n5\"pP&-\"pP&-#R18/#R18/$3gJ1$3gJ1$3gJ1$3gJ17fWMh-NF,H\"p4i*:]LIq\"52f;#AjPF#AjPF#AjPF#AjPF;9o]D&)R\\4#7$,3&+1YI[Nl+B!<WFC#7$,3&%VfIVABK6!WrNO!s8XE#7%CJ#CupY\"$cr%$VJ\\I#7Cbg!s:]l$NgV=V#^Z#5Q_Z-#JC0@\"$Npt!s]&c!s<KI#HejRegC^j%R%**!s])$!<WEeZ3pa>E!HWN(C,Kl!s9)%,R=/V#?:j.E!HW*,R9k@!s:]l$NgWQ#7%CJE!HW*,S0Gl#K@;[aT2JG&,I:OdLHM=!<WFC#7%CJ#Isj;\"'aap%g-%q(D?lUq#LR\"E!HW*,S/HM#Gre1Z3pa>#LNPS\"$Npt!s](i!<WFC#7%CJ4n]p!$ZHI]p&YK$!<WFC#7%CJ#8I=C4gGFt#7%X<!s<KI#HejJGln.QXqVZS#>G:&4n]p!$O;dq!s9)5#7$t>#=S^sE!m'I!aGL/%g-%i)&!*V^*=Er#<;kg4gGFt#B0nQXqu$^#Dsc3M#mb]E!HWN(C))c\"%qhq#7E]#$NgV=>lt0/!(6eezzzz!/^aV!'18`!'18`!'18`!'CDb!'CDb!'CDb!#Yb:!\"f22!2KYr!'g\\f!'g\\f!($hh!($hh!([7n!([7n!(6tj!(6tj!(I+l!(I+l!&au\\!&au\\!&au\\!(I+l!(I+l!&au\\!&au\\!(R\"h!%.aH!1X)j!&au\\!&au\\!'g\\f!'g\\f!($hh!($hh!($hh!'g\\f!'g\\f!($hh!($hh!'18`!'18`!($hh!($hh!($hh!($hh!'18`!'18`!'CDb!'CDb!(I+l!(I+l!($hh!($hh!([7n!([7n!'UPd!'UPd!/ggW!(d.j!2KYr!'UPd!'UPd!'UPd!'UPd!'CDb!'CDb!($hh!(6tj!!_KH!B(/b\"\"+<U`<?M6!WrN0&H`+M,6Rh!#&kq7iXdLgVA.Gu6j(?=#;:$L0DZ;cRO0fm#Ql^^AM5^6#:D/,3Es'90*>!'\"$p-T0*>K10.R#Q/+*I=.kBll9$S;%.rZj\\[NuI0)(2R3*?tY6#@R]:'tXSNqhPGq*ug(^&&'81dM?dD)m1Crc5@_`%ilSk+!R]i#7JcWm0*Ro#DE0\\!u2aWqhPGq*ujb^&&'81`ZT4B)lb(m\\fi0L)%Wkg+5.TO*ufe>&'c%7ndlf\\\"!7f_(Dd/YYlP61!XH+6!s98W\"8dlYE$$%Y+V2.-+3k`7^*=_S.1`R\"+1<J7*uk2+&'c%7iZT<]\"!@OD\"-Wc/\"pYS>!sdcc!s98W\"8dlYE$$#'&%Wo+c5@/,,9QU]&$?fmg)4iO)kI9F^*=`J(2t?7iYrER)'9&')Zq2Y!VRRu\"4%3B_#a]@#F,>m!u2aWqhPGq*ui3E&%Wo+g)1F8,9OoJE$$%a)\\9(i+5.TO*uj2]&'c%7`ZlKC\"!>_fiZSuu\"UBSZ[fHR9`<$,D'cR8PL^%f?)nI.&Xr8Cn+`JMBqBum\")'@iS*?,)&E!m'5!aEqnk6;\"nOTGUe..dSJ#0mM[nH&dp'dEhXL^%fG,Ou^#/#F$/*(0min,k=_0/(Hd>P90q!seu^!rsu-[M)Xo0DZ8d.k`CQ.kBHW<@]U!$VJ\\^-S'-`,LR\\Fc5A\"@*??@,-O7$]!s9;<\"9\\OW#&kY'p(e1Q,9QU]E$$%1*=pF5+8-Hj)Zq/fp(.<6#LrnY!sdK]!s98_\"8dlYE$lma+Xek<'[dsh\"2h_U05rQtmN=n\"_n-.0E&0<4&juh_n,kUg2`I$0>OhhW\"'_cC56G3o2Zm9a-9D<9\"#C#b\"\"sa^.k`CQ.k@21<@]T.&PBVX-S$SqVA.Gu6j(?=#;:$L0@h(1\"7)ul1N5-+JdOmJl`14KE&T_Y!=/c`\"%36Pn,kUg2`Jkt>M:Ab!seuf\"$n_!2d=-\"2Zm9E#s/5S!u!=n.k`CQ.k@>%<@]Tr#tiJ\\-S'-`,K:W4c5A##+WVd0-O5>/!s9:Q!<]A*E$$%!%1g`%+1`U+^*=`N'6#$4c2eI$)'@-A&&'81g*CVZ)tG-_c5@_L!?E*]+\"b52$^q*[!Q+p?O9-+(!s8eA\"Tni3_$'oC-3F>P#K[,O!u2aWqhPGq*ug(D&&'81_?+Zu)u^*Rc5@`')''Xu+!:Xj$R6#]m0*aN!<WE/nHB!s'dEhXL^%fG,J#3M/#F$/*(0nH]*C!.0/(lq6j&M>\"#FmP1WgV?M@2?F#Qljb#Ql^^6j&M>\"#FmP1QiMXc58JB#Qljb5qalI>q7QY!%TS.)HA:<M@iI`)CI%S-R8$i&'c%?V?e1e\"\"+>u\"p4rB)lj2?L^%f?)n%((c5@_<,7h@/+5.TO*uh'_&'c%7[O*\"6\"!:t+#Q=mn\":)aH!s8N)#m:\\;!!!'#!!((C!!((C!!!<*!!$1&!!$p=!!#Ig!!'P0!!')#!!$R3!!(4G!!(.E!!(.E!!((C!!((C!!$R2!!'V2!!$m<!!%9F!!(aR!!%!?!!!S6joG]q!s8d:!s8c;!s98K\"8dlYE\"`cI,7gpq'A==C'+b'V&&'8%dM?d8&%Wnpc5@;\\,979s'+t[gciL]Y2$3pc3<K?u%g2]b#&k4dXs4I[)ACgBE\"`cM!tVOQ'A==C'+^rA&'c%+mK4I?!tu@RgAqC'!t,29AHN#L%g2]b#&k4d^)%<k+VVR7E\"`bZ!>!Hn'>>]1'+][2&$?fag)4iC&)n-2c5@;0(EF\"g'0Z%#\"/?'>dg$,H!=&qS!s8d:!s:HW%H.JP$31&0zz!!!!(!!!!.!!!\"K!WW3@!!!!G!!!\"J!WW3#!!!!&eE?o<8HT&\"8HT&\"%0H\\I%g2]b#&k4djp2L3,88K@E\"`bn+V2j9'BTQ@%g*L4!D*@q#;$#['b:EDL^%f3&(VC)Xr7u-)/p6\"c41B1)&(R7*=i5c#>'[T!s_O&!u2USqhPGq)]+AV-m,<#dN!8X-mP0-0-_^=%p^8%*rmB)M?6d\"++a_iXr86$E#TVQ&eE8*)i>j\\(BYT]JH<do!u2=KqhPGq'+`qB&%Wntg)4iC&,m(MXr7u-)/p6\"MB`YW)&(jL*=i5c/HZ(c#H\\:;!sbq/!s98K\"8dlYE\"`c)+:l12'D;NI'+a(A&$?fag)4iC&#(*U\\fha@)%Wkg'A==C'+aXF&'c%+arh]8!u%m>eg(>&&e!k)n,a:/!s8eE#,;<^#7'Vs!s98S\"8dlYE#TUV*%2o+'[dsh\"2h_U,B+kPqA)I$_n-.$E$m$a)dE\"U.g$%Z-NaVV,6M3n,9Hn-+5SDG+!3+-Xr86$E#TUF*tQX7)j1CG(BYT][/pF4'bAn#qhPGq'+a(=&&'8%dM<A)+VWQIE\"`bj&eD,`'A==C'+^61&'c%+[LsSk!tu:T:XfE;!U0jlb6&\"2!WrN>%g2]b#&k4d^*F5l)ACgBE\"`cY!Y;jc'>>]1'+_Ys&'c%+q>qZJ!u!iK,QjqG&e!k)0F*^B!s8dn!s8W?(BaPj#&kLt`X+%8VA.Gu6j(?=#:\"14,OQ[YL*\\2L#Ql:R8L#I;%OWJ']`VL,+sR1c,6QU$6j&M>\"!_b0,Ou1GXrJek>F#=@\"'ba.0*=HA'-gd),9Hn-+3GX)+!6p]9!0'O+)i/8nfSIg)&pR%*>\\es#PeI[\"p5SN\"8dlYE\"`bR$4kE\"'@%J7'+`(h&'c%+WZ)rh!tu@R!s:^;,Qe8aV[!;d#E8oi!sbY*!s98S\"8dlYE#TUN#q-mm'[dsh\"2h_U,B+kPjq;\\!+Xc+R>J_C2\"'u'S\"'lun*rmB)h@*C++/0E@Xr86$-m,<#dMtXWO735rE$HTj(0cA0-NaVV,6KSD,H;GG\"-;pR-ZCF\\Oqq8f,V&s&\"\"+1V,:=^A+!Vj-+!8K.<?E<?,tblr)]s#<(]G:#+/Tb#*(0nH]*BR\",9t2M6j&M>\"\"/%8-h7UKZ5tLu>J_C6\"'ba.1BTlE'.3c--b^@#rYm?i?3;DS>ot:5!$<;k,#o^,mL`(*,9%_D)],pd&'c%3rYZ^m!unuUjTP_gmf<sn!W.ZWE\"`cI-kEI!'A==C'+b'[&'c%+l6mY`!u!iK,gQ]#&dnf;!YbkA!sdcd!s8dj\"p4rB%g2]b#&k4d=q@bS'A=<7\\fha@)/p6\"Z2tQJ+VWQIE\"`c=((\\\\.'3ZCe!tu@RrrV'_4k:k\\#7'Jo\"1J:9`<HDH'c-uLL^%f;(Q&_O+/Tb#*(0nH]*BR\",:!%#>G;WU!seuR\"'$QjM@No6,9Hn-+6\";@+!:1u9\"H/b+)i/8NXHBC)&r,l*>\\es#DEBb!u2=KqhPGq'+`A!&'c%+g)1F()ACgBE\"`cE\"V8<l'D;NI'+`du&'c%+c5CR7&$?TWc5@;0,B+;,ng\"ak)&)-9*=i5_a8sj;!s]J!#6WT['^#Q#\"\"'KA[fup>bm+=Q'c-uLL^%f;(Q&bP+/Tb#*(0npWs0ef,9qdI6j)bU\"t+@;-a!IU\"![nJ,9u1O6j&M>\"\"/%8-h7UKdN0n@>P87S\"'bI'1BTlE'.6'j,:?b=,9Hn-+,U>(+!7?`9\"H/b+)i/8XpYcc)&n_e*>\\es#H\\76!u2=KlNV;A&$d#_c5@;0,7h@/'A==C'+^N=&%Wnt^*@S1&!A=Oc5@:a,979s'+tZT^]G2T!s:^;,Qm31&dnfc!>N9N\",d?gT`bH\"#OMd!!u2=KqhPGq'+_5L&'c%+^*=0\"+VWQIE\"`bR(_=>*'CHWT'+^rE&$?fag)4iC&+0i:c5@:u\"W\\*U',8an\".''Peg/!5#8.CHbQ?o-#6P&5W<!)'#I+R;!u2USqhPGq)]+)K-m,<#dMtXW_n--uE$HUA'gr.bn,k%W-R[%T>CmP>!seuV\"'`nk.g')[,6L=9O736!E$m$U)I'KN.g$%Z-NcXZ,:?b=,9Hn-+3k-l+!:1p9\"lMh+)i/8$4kE\")l=)c(BYT]OU;0m'b:EDL^%f3&+U#;Xr7u-)/p6\"V@F-^)&)QI9+M+<4k:n!!XAtP#6P&DJ#s*>$31&P!!!!$!!!!3z!!!!H!!!!K!!!!\"!!!\"#!!!!X!!!\"\"!WW5'\"98G'\"98G'\"98FG!!!\"$!!!!Q!WW5,!!!\".!!!\"-!<<,<!WW5=!WW5D!!!\"Q!!!\"-!<<,6!rr>:!rr>:!rr<7!<<,8!!!#[!!!#A!<<,@!<<,@!<<+V!<<,F!!!#V!<<++\"98F.\"98Fs!<<,g!!!\"D!WW5k\"98Gk\"98Gk\"98Gb!<<*7!<<*(!!!!+!!!#;!!!#=!!!#;!!!#;!!!!X!WW3J!<<*Q!WW4X\"98F\\\"98FZ\"98FZ\"98F)!WW3o!<<*'!!!!.`od@-R03To#71J7'b:EDL^%f3%uM>;Xr7u-)/p6\"c5@/<)&%lI*=i5c#FP_,\"9SlX!s98K\"8dlYE\"`bB*Y5Cl'A==C'+a42&'c%+NZK2O!ttp-\"MY0D#>#\"\"'b:EDL^%f3&)n-2^*=<>(2sotee8S>)&)!@*=i5cquN2g!s9Y&$&f64#AjPF'b:EDL^%f3&#(K`^*=<b\")nnaWZVht)&&_n*=i5cgB\"Sf!s](e!WrN0OT>Od'b:EDL^%f3&,$DBXr7u-)/p6\"^*!s3)&'_/&$?fa^*@S1&&&hjc5@;0+<:sp'6'uU^BBE>#F,D'!s8eE!<WE=%g2]b#&k4darh5/,89bQE\"`c!&eE8*'?VF<%g*J`Z3pa>#E8ff!sdog!s98K\"8dlYE\"`bR#7nNn'@IY8'+Y9X^*=<^%WE'lr[8<&)&&#?*=i5cE!HW*,_H-g,mUk$p&Xsl!s8dn!WrN>%g2]b#&k4dOp2H2,88K@E\"`cA*tQX7'=&)g%g*IUefk@=(^n.^!s8e=!WrN>%g2]b#&k4d[Ls+R)ACgBE\"`bF*\"U=4',hl%!u!i'$NgWQ#7%CJ#H7mY\"9Snf!WrN>%g2]b#&k4dQ3e)))ABh0&&'8%g*CVN&)nB9c5@:]#osNY'3YXY#-JaIi<'/a&,I:OU'1e8!<WFC#7%CJ#N5[c!sb4r!s98K\"8dlYE\"`cM)%XG+'ClWP'+`eB&$?fag)4iC&#'LDc5@;`)''4i'6W^f#DNcp[0\"q`!scdI!s98K\"8dlYE\"`c=#nP<!'A==C'+_)h&'c%+h?b25!u!#>!<WE/jT>Se'b:EDL^%f3&&ot-Xr7tf,B+;,dM`Y!)ABh0E\"`cY)%Y\"1'?2C?%g*Ja#Hn>h,S0kZ_Z]B=4gGFt#B0nQXqq>f\"9S`2SHK#s'b:EDL^%f3&\"4UOc5@;0,B+;,L'\\Bn)ACgBE\"`bR$4kE\"'D_eO%g*J.Z3pa>E5)J[Xqu$^#Dsc3K`cr3!sd3V!s98K\"8dlYE\"`cA-kF$:'A=^N'+^*B&&'8%dM?d8&'bRoc5@;T-lig#'ANTn#Dse(!KdEc!sec-!s98K\"8dlYE\"`c!,S.$r'A==C'+a@>&$?fag)4iC&+UeQc5@;\\&028`'0WW/f*)Cu#7%CJ#E8b\"!sbq3!s98K\"8dlYE\"`c%\":qXR'>>]1'+adH&%Wntg)4iC&'>t)c5@;8\"<A!T'6\"2o\",\\?/eHH&E#7&oc!s98K\"8dlYE\"`bZ(_=2$'A=<7Xr7u-)/p6\"D@b#1'9WkH%g*IU\\cN+g*X?Do!g`of!#>P7!!<3$!#Yb:z!$hOE!&jlX!$_ID!3H;&!(d.j!&\"<P!36/$!+>j-!(6ee!3-)#!/ggW!)3Fn!3QA'!1a)i!*9.#!3?5%!3lM(!+>j-!3H;&!)`t#!)`t#!)s+%!)s+%!6kKD!,qo<!36/$!94%Z!-eJD!3QA'!:p0j!.t7O!3H;&!*f[-!*f[-!*f[-!\"T)1!0[B_!3$#\"!%@pK!1j/j!3QA'!'^Ja!3-#!!36/$!*91$!58F5!3?5%!!Tgo!=.um!s8eq!<WE/%0H\\I%g2]b#&k4dl6?hB)ACgB&%Wntg)4iC&%Wnpc5@;@%NQ&^'6\"0]MBiGO\"LeP!#;lSc'b:EDL^%f3&+0N1Xr7u-)/p6\"Xs4Ik,88K@&$?fag)4iC&,m7Rc5@;`\"!%mS'0WW/irKB%q#TX^!s`B>!u2=KqhPGq'+]sF&&'8%g*CVN&)n-2c5@:Q,979s',_#[Xqq>B\"9S`2M#d\\\\'b:EDL^%f3&#pfaXr7u-)/p6\"ndl>G,89bQE\"`bV.1a]A'Cl\\T%g*K^!O<(8#7\"]'\"9Sn:!<WE=%g2]b#&k4dU)jiJ)ABh0&&'8%nd]UP&,msfc5@;0,B+;,JfbN;,88K@E\"`c]-4eB>'E0C#%g*Jamfs)T,T-LcCUt%%0`qM@Z3pa>E!HWN(C/Im!s8f,!<WE=%g2]b#&k4djpr!:,88cVE\"`bV$kLW$'BTfG%g*L3!=&k4(C(6K!sbM$!s98K\"8dlYE\"`cI)\\9Y-'@IY8'+ad_&'c%+`ZlK7!u#VY#Hek<i;s)`#K6`H!u2=KqhPGq'+a(=&$?fag)4iC&,I[bc5@;T(EF\"g'.*hA!<[9G#Dsc;mNVsg#mZ.b!s8eu!WrN>%g2]b#&k4djoQ(-,88K@E\"`bV%1g/t'ClVDXr7tf,B+;,dNB(G)&&_R*=i5cpAsh2mfB^,4gGFt#?mZ\"!s8e)!s8W?%g2]b#&k4dL'%sh)ACgB&%Wntg)4iC&%WVhc5@;0,B+;,WWWjX)&'S!*=i5cE,u8e(N9TaMBiGo!ct[O#MB1]!u2=KqhPGq'+`A$&$?fa^*@S1&&oLuc5@;@&fhJb'6\"3F\"H\"H0q#^^$#Q4`,!u2=KqhPGq'+`e#&$?fa^*@S1&&K1pXr7u-)/p6\"jr+cU)&(^-*=i5c&,I<1\"l9JIZ3pa>#GD7C#6P45\"9S`@%g2]b#&k4dL'\\C%+VWQIE\"`bb%M-i&'A`p6%g*Ja#7$,3#LrqZZN:Zg+pX8D#JgHD!sdK^!s98K\"8dlYE\"`cE,7hL5'D;M=Xr7u-)%X;%'>>]1'+`dt&%Wntg)4iC&$?NU^*=<^%WE'lL(4a>)&'.c*=i5c`rWaQ#K@#=!O<*^#DWA\"#7%CJ#I+:3]*8\\I#I+c\\!sbM'!s98K\"8dlYE\"`c]\":r'e'A==C'+a@>&'c%+rWF5P!ttq,!<\\)^!!\"&?zz!!!6(!!!i9!!)9c!!\"eT!!\"PM!!)3a!!$4'!!#(\\!!)6b!!(.F!!(.F!!(.F!!%KK!!#Lh!!)9c!!&,]!!#gq!!)0`!!&bo!!$+$!!)9c!!(:J!!(:J!!(:J!!'P0!!$U2!!)-_!!(:J!!(:J!!(IJ!!%-A!!)-_!!)Bd!!%fT!!)*^!!(4H!!(4H!!!f9!!&2_!!)3a!!(LP!!(LP!!\"SO!!&bo!!)3a!!(FN!!(FN!!(FN!!(FI!!#js!!'/%z!!!2LjoG]=!s8c7!s98W\"8dlYE$$$V*\"TV(+5.TO*uiKC&'c%7MB!WU\"!7b\"\"&fFV!s:E=%(leg$3r9f!u2aWqhPGq*uiK/&$?fmg)4iO)r_D>Xr8D9)%XG++0lW#*uh@-&&'81iZW7_)sSXYc5@_,,97^*+-6L6!s9&IT*()S#AL4D!s`ZF!u2aWqhPGq*ugq'&&'81_?+Zu)lb\"kc5@^u.30?0+/8iM\"0DS/N<'+`'cR8PL^%f?)tFONXr8D9)%X;%+5.TO*ujJm&'c%7ndlf\\\"!7cu!P\\Z1#7%L7!s98W\"8dlYE$$%9%1g/t++b:>c5@_X)%X;%+5.TO*uh4(&'c%7_@7M)\"!7j$\"p<<V#MB+[!u2aWqhPGq*ufq`&&'81dM?dD)r`\"Oc5@_t\"!&<_+$K0!!tu:`\"2k3S'*A?^!J(:S!saM]!s98W\"8dlYE$$$R\"qSEm+4:o8\\fi0L)/pZ:Z6Tt+)'=S;*?,)&nH#`m\",@$[!<`W-!!!*$!!!?+z!!\"hU!!!l:!!!i9!!!$\"!!\"eT!!\"kV!!\"5F!!$j9!!#.^!!\"8G!!#Uo!!%KK!!#Oi!!\"8G!!!;IkQ(pb!<WE/#m18E0*D*-#&l@OMB!/0)Dg(bE&0/m)%Y\"11Q!.m0*=!8V#c>R!s^7W!u3HkqhPGq1G=b0&&'8E[NTTG0BNNNc5AEu*ZZm91VNkl%g+0i\"3CTLblInK#>kR*'e][dL^%fS0=DT+^*>G.$ue!Ujs1JK+Z%giE&008((\\\\.1U\\#=0*=#Z!O`%7%gR@^MZj?6!s98k\"8dlYE&0/i#S4'V1ThX81G@T-&%Wo?g)4ic0B*KQc5AF\\#TYQ#1L%j':BLhJ\"/c2*W<!)''e][dL^%fS0:i7V\\fil`)%XG+1X[%X1GA_<&'c%Kl4Y0k\"#DhC!s:Y[\"2=pCd/a=O'e][dL^%fS07k8V\\fil`)/qAbQ3\\#H))Hjd*A7LN#LrqZIg>KE!s98k\"8dlYE&0-O&$?g,ne#gs0:i:Wc5ADB*A7LN>O!4>!sb(m!s8f,!WrN0R0!Hm'e][dL^%fS0BsJe^*>GR+:kUn1X[%X1G?HM&&'8EdM?dX0BNcUc5AG')]^R61QDLI+ccX+$kj9VPQ?mJ!s8eQ!WrN>0*D*-#&l@OdNB(7,;\\TuE&0/U+V1^o1YN^c1G?$K&'c%KdNBP`\"#CJr'*DIe(Dd/Ym/^8j<LjNi#<2s>!s8W?0*D*-#&l@OWWWjH,;Xof&$?g,g)1FH))KtaE&0/5#nP<!1TCQu0*=#\\!VZYj!<WS+!s8W?0*D*-#&l@OW[/1Y)DgprE&000-P+K?1TD`A0*=!c\"+p[X#Gh\\.!sd'Q!s98k\"8dlYE&0.n&$?g,g)4ic0=i#3c5AF`)BCI51GK7N!seK'o)]\"!nH/jq'e][dL^%fS0>\\S;^*>H-'lYr^g'&#$,;\\%!E&0/M%M,]\\1YN^c1G?lk&'c%KSdHJk\"#E*K-j(EB!?3!O!\\kc)\"0_e.)Zp>]\"g\\:5#I+C6!u3HkqhPGq1G@#^&%Wo?g)1FH))KtaE&0/M)\\:431X6CL0*=!Af)um;#OMTq!sdK^!s98k\"8dlYE&000,7gpq1ThX81GAS<&%Wo?g)4ic0A7Q[^*>H-!tVsd1U\\TK1G=Im&'c%Kg*%Ii\"#FB*)$BmDE\"`oY!aF@rdffgYjTPbX!XG+s!s98k\"8dlYE&00H\":r3k1PR>t1G=n'&&'8EdM?dX0A6F;c5AG;\"<B,t1XH.)',.#>XTS_.#K6iK!u3HkqhPGq1G?HP&$?g,Xr;7809utVc5AFP%NR2)1J5)(MZFb%V#pf%#O)Bo!u3HkqhPGq1G=J(&%Wo?[O#lK08^&Hc5AG/+rr<=1L%\"#)Zs<u)'8rG!u$.hJHu>[#F,Jq!u3HkqhPGq1G=J#&%Wo?g)1F()Dg(bE&000-4d6t1X[%X1G@T*&%Wo?dM<@r)Dg(bE&0/U-4dg81YO)bc5AFd(2u&_L'J77))L[o*A7LNE\"`oY!aG(5(BZgX$3M5d)]P@_E#TaR#<dqOiru1_MuiMP+.a!^+0Pj*-3oe>b5po4#PeQ+!u3HkqhPGq1G@l#&%Wo?[O#lK0B+)bc5AG#%NR2)1HhlP\"2b0FOTkmi#Fu)%!u3HkqhPGq1G>m=&$?g,[NuHu,;\\m0E&008%1fT[1ThX81G=b3&&'8EdM?dX0>\\51c5AF@$QUl&1O^_##6Q\\2(BZo)b5rX9!R1lP!sdWe!s98k\"8dlYE&00$%1fT[1YN^c1GA;4&'c%K[LO<2\"#C9+#HA8<\\gJ^)#Q4q7!s8d^#Qk/D0*D*-#&l@OedW.m)DefJE&0/Q,nJ9=1Y*!U0*=\"9$a0[H#K[&M!sbe2!s98k\"8dlYE&0/9'+_f%1X[%X1GAGI&'c%K^)\\4I\"#E0M)&jML,7al)R0Nfr#LNeZ!u3HkqhPGq1G?`Y&$?g,nduDD+Z%O^E&0/1#nO`p1X[%X1G@0'&'c%K`Xa(C\"#E0M&&SP)\"hF`6#m187JI)D\\'e][dL^%fS0:j!k^*>G^(2u&_JgCrQ))K\\VE&0/1*tQX71P-nn0*=!E[fZ^7_u]f<!s8e1#m18E0*D*-#&l@OMAZr-)DgprE&0/u$kKom1YN^c1GA;%&'c%K`XNqA\"#CW5!s<KarrKPE5N3G#*s^U.\".KDui<]Sg'e][dL^%fS0?OJ0Xr9+M)%XG+1X[%X1GA\"r&'c%KdM?dX0DZLrc5AG'\"<B,t1DJRI!s=bgfa$C:!rrE@&02kn!!!*$!!!<*z!!!`6!!!T2!!)]m!!)Ef!!)Ef!!\"GJ!!\"GJ!!)]m!!$\"!!!\"eT!!!$\"!!$^5!!#(\\!!)`n!!%9E!!$=*!!!!\"!!\"2C!!'h8!!$^5!!)`n!!(OL!!%$>!!)lr!!)0^!!%?G!!)co!!)fp!!&8a!!)iq!!\"SO!!&hq!!)co!!#^o!!'5'!!)fp!!$L0!!'P0!!)iq!!%-B!!'h8!!)0^!!)Kh!!)Kh!!)Kh!!%oX!!(OL!!)fp!!(4D!!'2'!!)-]!!)fp!!(=G!!)]m!!)lr!!)Hg!!!!\"!!)uu!!!*&!!!<+!!)co!!!`8!!!Z5!!)lr!!\"GL!!\")A!!)os!!#:d!!\"GK!!)uu!!)Ef!!$(%!!\"hV!!)os!!$d9!!#=d!!)rt!!!J?joG]5!s8cS!s8cS!s8cS!s;PT\"HrtU\"'u'7!s_O&!tl7L<!PPg\"$Npt!s]'R!s9/`\"-`fkK`M8X4h<$D2[?_k!s;4!!uEWn)ZpV2!?8Tt#;$#[4gGFt$O:MN!tVsF43eKP56KC:8rb>^56q?M\"#1`R!saAX!s:dQ$k!FJV#^Z#5O&X^#@!K!%g*%O!s9kP!s9/d\"%X%X\"6]c)1Cp3*5H4c@1GLsE!uE`q!tmBl]E&6p!s;c=,ngAe!t,3M%h#*U#9<mKE&T`4&dQ)N!s<L$2sMH'2`J#RE&T`,+YX![!s_g.!rr<Rzzzz!!!!W!!!#;!WW5=!WW5G!WW5G!WW5=!WW5=!WW5c!WW5c!WW4P!rr=Q!rr>X!WW5Y!WW5Y!WW5Y!WW5?!WW5?!WW4R!rr=W!rr=U!rr=Q!rr=Q!rr=Q!rr>@!WW5?!WW5=!WW5=!WW5=!WW4T!rr<,!rr<@!rr<V!rr<V!rr<V!rr<V!rr<\\!rr<\\!rr>@!WW5?!WW5A!WW5A!WW4+!!!!T!!!#8!<<*3NTL6H&H`+?&H`+?&H`+?&H`+^!s8WRNXLXPdKomR\"TSN&zzzz!WW3#!41eg#GhG'!sbY'!s8e)!<WF4fE].tXpA7O\"qq)F!t,2Y$Ni6k0`qM5!t,29.0BZ:[K6gE#8%%?#>G:&-3F>PE\"<KM,>eQ_\"qtqh'D_lO',.Mm#CQ[V;$4fB#7$Xt!s<KQ&(2:\">lt1J%hHYaE\"<KU\"U@$i\"$cr%$VL7!#7Cbo!s<KY(Zl;7B`eH#Z5Wl^E#0>=(iU9-`WgAu(]\":?FTV_/Z5WlV#?:j.4iS?A$ZHI]p&YJ]!<WEZ!s\\pGrWP.a#9a0O!!*f?zzz!!!#_!!!!,!!!!/!!!!U!!!!@!!!!J!!!!V!!!\"4!!!\"4!!!!(o&g#YblRtL#L*;P!s]8;!u3HkqhPGq1G@;m&&'8Ep(_O&0CBSd\\fil`)/qAbiXud5+Z%gi&&'8Enf)O(0=i;;c5AG/%NR2)1Co3@,PiVt-NgjZ8rb>F-U\\%Y\"8`*(+,^.)o`bNE\"`PP*VB6&n\"9S`H'*B%)!uh=IW<EA+#AF8B'e][dL^%fS0>[c$Xr9+M)/qAbV?%41)DfYVE&0/m\"V8lr1[6>.0*=!a!t,2A\\eGP+)%YjI`s:<9&$dSkg)1,uVZ?l)T`G5t'e][dL^%fS0D5eb^*>G.-ZCjpap8O'))Lsp*A7LN1>3-U*s]%Q!s8eI!<WE=0*D*-#&l@OiYrE>+Z%giE&00<)\\:431ZB>o0*=!W!s=Sc#NYsg!u3HkqhPGq1G=au&$?g,p(_O&0:iCZ\\fil`)/qAbr[8<&))I9_*A7LN&-F-Z&%VifVA][G\"1&\"5Pl_$i'e][dL^%fS0>7f)Xr9+E(2u&_Z5!na,;[a`&$?g,g)4ic0B+&ac5AFX,98E>1Cq&!,E`EI-NbbhN[Z2##QsZ%\"/Z+(\"LA=8#LNST!u3HkqhPGq1G?0[&$?g,^*@SQ0>8A9\\fil`)/qAbNY2lJ))IQk*A7LN0EVO^%up\\^#J)8fAHTOH4mE+O*s\\JD!s8db!s8W?0*D*-#&l@OROA]L)Dg(bE&008-kEm41X[%X1GAS+&'c%KmO0)/\"#EQP&K>3bnH75E!sc49!s98k\"8dlYE&00D)%X;%1X[%X1G?lk&&'8EdM?dX0=i/7c5AFX)BCI51Hk\"*\"!;J(+,1J%L(kRK4mE+OUB,<U+1`+X\\e?#)*;op@!seK$!s98k\"8dlYE&0/M)\\9Y-1X[$L\\fil`)/qAb_ANlu,;Z&A&$?g,ne#gs0?t1@c5AFl\"W]5u1Hk\"*\"!;J(++bC1!J23D\"!9\\k!s9W3bln3M!sc4:!s98k\"8dlYE&00$#nO`p1X[%X1G>19&'c%Kc3t^H\"#DY>*s:m2_#XW?#MB4^!u3HkqhPGq1G?Tj&$?g,g)1F4+Z%giE&00$!=umh1YO*n1G@l8&$?g,nduDH,;Z&A&%Wo?dM?dX089rIc5AG#,98E>1Yr/0+.!)i\"$PoO\"!@%6+!8c99$Re`+$Jlk\"!;J(+0H1\\K`b-*!=,_1!s98k\"8dlYE&00H#S4Ki1X[%X1G?lm&'c%KrWjMt\"#E+*!s@9_#>kR*#LN\\W!u3HkqhPGq1GA/,&$?g,g)4ic0?+,*c5AFD(EG.21N4EXg'e4W!NQA+#PA6&!u3HkqhPGq1G?TL&&'8EdM<@r)Dg(bE&0/A*tPLm1\\MQ&1G>aL&'c%KU)tC/\"#CJjlN[MPOTN,t!sbY,!s98k\"8dlYE&0/m%1fT[1\\),s1G=J#&&'8EdM?dX0=E2<^*>Gf,]GOmhAm-0)DfeWE&0/q$kLW$1VOD@0*=\"L+!8c29$RS*\"Won=-j(Q1+!9>PE$'i:W[C\"Q+0lGs+!9&Wh#ZI8!s8f(\"p4rB0*D*-#&l@O[KI,D)Dg(bE&00D#7nNn1YO)bc5AFd(2u&_iZJcW))M*o*A7LNfE)!R#OVg%nHG6^!sd'P!s:d%\"*j#6!!\"eTzz!!!6(!!!N0!!)Ni!!)-`!!)'^!!(jX!!(jX!!(jX!!(4F!!(4F!!(\"@!!(.D!!(.D!!\"kV!!\"AH!!(sY!!#jr!!\"\\Q!!)9b!!$L/!!\"tY!!\"2E!!%'?!!#=c!!)Hg!!(pZ!!(pZ!!%oW!!#dp!!\"/D!!#Ik!!#Ci!!#7e!!#7e!!&tu!!$@+!!(pX!!(^T!!(^T!!'t<!!$g8!!)3`!!(aR!!%6D!!)<c!!(XR!!(XR!!(XR!!(XR!!)lr!!%lV!!)6a!!(LN!!(LN!!!r=!!&8a!!\",C!!\"SO!!&ep!!)-^!!(:H!!(:H!!(:H!!(@J!!(@J!!(@J!!$($!!'>*!!)-^!!$^6!!'Y3!!)9b!!%?H!!((?!!\",C!!&2`!!(UN!!)Be!!'8)!!(gT!!)Hg!!'\\5!!)6`!!\",Cz!!!JskQ(q-#m187`<cVK#7Ub;'dEhXL^%fG,N97_/#F$/*(0nH]*C!.0/*/;>=(+J#Ql^^<A-#^)dOsI.f_(Mh@N[;/$^Np^*>!UE$lmA+V2j9-fPaZ,6K:u9`kJ4)[#tn#&kY'c34`i+WoDUE$$%Y&eE8*+3k$#)Zq/e`<cWb#AjPF'dEhXL^%fG,H;q9/#F$/*(0nH]*C!.0/)_r>Lim4\"'^Kq2Zm@g0*<j\\0=D*k.k`CQ.k@b/<@]R@9!0'[.rZj\\WZVht)(2F.*?tY6#I+<I\"9TAX\"8dlYE$$%Y+V2:3+8,dI\\fi0@)/pZ:arh5/,9P>LE$$%!+qMs:+6\"Fa)Zq2:!U9[fCQAMd!WrN0i;j#_'cR8PL^%f?)km`O\\fi0@)/pZ:iYrER)'>R]*?,)&D8I'F\"m6$oJH>oU'dEhXL^%fG,8qs\\VA.Gu6j(?=#;:$L0DZGP\"-;pR1N5-+Q3pj1\"ZHNfrZO?*?3;tc0/GDI,mXT+\"'mE1.f_(MVB](k/%Q$Z\\fiFOE$llb.1a]A-]Sf[,6K:ud/jCP'cR7-\"`PP&dNB(3+WoDU&$?fmg)4iO)ibOAc5@_P+<;C'*s^a,QNHa_0b4Kk#PeE'!sec+!s98W\"8dlYE$$%a,S.U6+4:pD*uhp5&'c%7U(&+^\"!7dN$NkD)!<WF.\\fhRd#MB4^!sbe-!s98W\"8dlYE$$$R!tVOQ+2/t=*ui3<&%Wo+g)1F8,9P>LE$$%]-P+K?+8-Hj)Zq0I!tu&7WX#^1$f(i?\"U!3UE!m'5!XG7u!s8ei!s8W?,6Rh!#&kq7\\f)tIVA.Gu6j(?=#;:$L0CAs2\"2h_U1N5-+^(jl7&2s\\qaq-W:?3;tc>Ik2$\"'u'_\"'mE1.f_(MWWQ6O/'9)/c5@u[E$ln,)%Y\"1-^ktp,6K:u[0-R6'pf\")qhPGq*ufqE&%Wo+g)4iO)k%]Vc5@_L$lp8h*sD`K#<hc%!t,@e!s=_l#MfLb!u2aWqhPGq*uhL*&&'81`ZT4B)tG-_Xr8Cb)K6c;p'M>U)'?.(*?,)&;Q^rP\"'bU5P6:smV#pf%-3F>P#K6uO\"#Ki]B;P\\7R0<Zp'dEhXL^%fG,MEn]/#F$/*(0min,k=_0/&Uu>J:7s\"'ba32Zm@g0*=TEO736-E&0<@$<tp\\2Zm:$*BO@-_AtiC5Q_ZU(,%<s-SGSh\"[iHRn,k=_0/&Uu>J:7s\"'^d02Zm@g0*>!'\"8)h%rZ*Wo6j&M>\"#FmP1R8APncC`P>D=Id\"'u'c!td1>1FFgXW<P`mO736)E%`m8$<tY!1BUjI!]L3cl6\\Rp5Q_ZQ:G2g`#\"/QSn,k=_0/&J(>KQt&!seu^\"'mE1.f_(MM?Hp0/$9sdc5@u[E$lma!>!Hn-dE/A,6K:uh$*r`(&J.:qhPGq*uj2^&&'81g*CVZ)pSm'c5@_`+<;C'*s2`QhB+*M\",R0dJHl8Z'dEhXL^%fG,E<oq/#F$/*(0nH]*C!.0/(<e>IG2$\"'`>Y2Zm@g0*=TEl`14GE&0<4(ISAkWs1M%2`Il?#Qljb5qalI>q7QY!%TRo#urK+Q6f/+)CI%S-R7=Z&'c%?NZfDf\"\"+?,#GV>&'cR8PL^%f?)ic$O\\fi0L)/pZ:NZeqY)'=k]*?,)&#Ghb02[B-`!s98W\"8dlYE$$%M%1fT[+5.TO*ugdi&'c%7^*@S=)n$4ec5@^q)BBb!+)q)[#GrpTr<\\5`!sbY.!s98_\"8dlYE$ln(\"=Pdt'[dsh\"2h_U05rQt^(j$<_n-.0E&0<<\"@N?Qn,kUg2`Jkt>>dNb#Qm!f6j)bU#!6cc4+[f-\"7)ul5B&hOXoSe13s/dk1BUjm+#a:.\"\"sa^.k`CQ.k@J)<@]Sk(J:hK-S'-`,O,aLc5A#'\"<A]h-O5b?pAk@2)[#tn#&kY'mM$27)BZ[<E$$%%)%X;%+5.TO*uhp?&&'81g*CVZ)tjCFc5@_<,omp,+1VCW#L4H2#MTC<*s_HD\"7#smaU&%O'cR8PL^%f?)j144\\fi00,7hL5+8,dIXr8D9)/pZ:jp)F2,9P>LE$$$R#S52u+-HXF)Zq1t!O<[!!f$u!#7#u\">G2<)!saAa!s98W\"8dlYE$$$^%1g/t+5.tNXr8Cr,B+_D[L<\\l)'>\"N*?,)&=9j?$,mT\\=!s8e-$3LAF,6Rh!#&kq7ng>h9VA.Gu6j(?=#;:$L0>8/h\"2h_U1N5-+U*`81O7361E&T_u)I'?[3s,`j2Zj<f1BUk(#<)`k\"\"sa^.k`CQ.kB<e<@]TZ,YG3X-S'-`,D%$Kc5A#/\"s\"oj-O521!s98Wo*>/K#&kY'XqM>W+WoDU&$?fmg)4iO)u^$Pc5@_,'-/\"o*sZLUgBIWY\":P81!!<3$!#bh;z!&jlX!+u93!*]L)!7:cH!-eJD!*oX+!:p0j!0dH`!*fR*!%S'M!29Gn!*oX+!4E\"1z!;$6k!)3Io!8[\\U!*TF(!5AO7!;ult!*]L)!;uou!(d1k!*TF(!0mTc!+u<4!*]L)!\"k:S!DrsQ$3peB!s<KI#EgNT#7%O_8I#LS%S-[,\"&#'ck5fNK!s8W*!<N<&!!!*$!!!3'!!(+A!!(FI!!!+ljoG]Q!s8co!s8co!s9kP!s8d*!s9n]!t>Ji!s;cE-l2tl!tPJ='a\"P&hBr[A#9<mK#8%%?E!lp!(af[n%0oH,\"#^Ad!s^[c!s^7W\"#>uBd0ZQM%u)2;g)1,)!s8N'&HDe2zzz$3L8.%Kc\\2%Kc\\2%Kc\\2&HDe2$ig8-L&h8S%Kc\\2#Qk&,$3L8.$3L8.!WW3#!WW3#$3L8.e,TIK&-Dn4#0Q'/2?s<d-O0__#8%%?-3F>P#;$#[>Il!l\"'u';!sdog!s:4Z'*CD'$Nh1M9`kJ\\p(.<6E!m&F\"VUt?$O;4`!s;j3$NgWJ!s;bj,81.a]`A3;5O&Xn(C-3+!s:cr,7=ka70<WV[Nc.f>I\"nU!saed!s:cr,7=kaf`;0W5IMdE$X8o<'*DPC$NgX9!<WEeZ3paB5O&Xb$O?J.!s;j3$NgW6!s;c=,p*4q!uD&Y(Diei#KZuK\"&B:,/I-t2!s:cr,7=l`^*aQr?3:Q;#Oqfs\"'u';\"$`du$O[1_!s;/u#SS!j$NgJ<$NlCi#GhG'\"'](F\"'u';!s`*6\"$a4=$O^1Y)\\W;Y4TbdN[Nc.f#8I=C>G;35\"'u';!s`fJ!s]8;\"%;5V`W`^T!!*38!!!!#!!!\"d\"98Fh\"98Fh\"98Fh\"98E2!!!!,!!!!p!WW4j\"98Fl\"98Fl\"98Fl\"98EF!!!!J!!!!p!WW4n\"98Fp\"98F)!!!!U!!!!p!WW4n\"98Fp\"98F?!!!!b!!!!p!WW4n\"98E-gZAMA;$-n*;$-n*;$-n*;$-n*'a\"OQ(BaPj#&kLtNZJ_B+WJ-?E#TVQ&eD,`)ql0K)].oX&$?fig)4iK(TnYec5@Sl(EF:o)a3Hg!s^$a%g/R2@\\O+E)Zr7s*qo[?#F,AJ#6P32!s98S\"8dlYE#TV%'b@l!)nmO-Xr885)/pN2WYQ,j)&p\"!*>\\es4i.ut!ga(0#7'r(#Oqfs!saAX!s98S\"8dlYE#TVe$kKKZ)n%%'c5@ST)/pN2^*!s#,9+WFE#TVm-4d6t)nI1'\\fi$H)/pN2MB`YW)&rQ%*>\\es>M9d\\\"TJP[!Oa<g\"$j$olN[Y\"`<$,D#K6]G!u2USqhPGq)],4i&'c%3g)4iK(P3_>^*=T\")K6W3nf&+b)&o:k*>\\es#lar2\"!.OH#6thC!seK\"!s98S\"8dlYE#TVQ*tPq+)ql0K)]/2M&'c%3Sd-8P!ukIA&.8RF_#XY5\"UCFs!s98S\"8dlYE#TVY)\\9Y-)oa\">)]-L=&$?fi^*@S9(Zl5=c5@S@,97R&)fQ%k#3#]G!O`=C!sa5V\"!XT[!s^.T!s:K5$Gd-6!!*94zzzz!!!!,!!!!2!!!#s!<<,r!rr?!!rr?!!rr<O!!!!@!!!#r!<<*c!!!!Q!!!#u!<<+0!!!!f!!!#r!<<+Z!!!!t!!!#u!<<*)RH=MT3<K?g3<K?g3<K@1!s8X6R0_RSrrkpq)Zqf6(BXmW!s9/P\"8Dp>$PO%*)\\W;Y5m%3Pncf10#9a0O2@fll#;H;_-Q<.&#8mUG!!!T2zzz!!(XQ!!#gq!!(XQ!!(XQ!!(XQ!!(@I!!(:G!!(XQ!!(XQ!!(:G!!(:G!!!'#!!!'#!!(XQ!!!:ujoG\\j!s98K\"8dlYE\"`cU'bAS-'>>]1'+_f%&'c%+p(\\SY!u\"V2\"Tu%Y8-9)!#:T`W'b:EDL^%f3%uq\\AXr7u-)/p6\"jp2LC)&&#O*=i5c#6E9T\"\";k4>5A[59`kJ4%g2]b#&k4dc34`m,85YFE\"`cA&eE8*'@$b%%g*K.!<WE+!!*K2!!!!$!!!!*!!!!@!rr<9!!!!2z!!!!3!!!!H!!!!:!!!!@!rr<)Y3#`i0`qL_#m18E%g2]b#&k4dMB!/0)ACgBE\"`c-)%Y\"1'8dbM%g*IM0t.8f#;H;_99B;K#H%h40`qL_2$3pq%g2]b#&k4diXcX')ACgBE\"`c-\"V8<l'A=]BXr7tf,B+;,dNf@+)ACgBE\"`c]'G&J,'B0QD%g*J.p(3,d#>YSs\"I]?($Nlas#B>M$!s`rN!u2=KqhPGq'+][2&%Wntg)4iC&&JAYc5@;L)/p6\"[M9=u)&%T<*=i5c'F+`L#:@n(!s8N'#64`(!rr<$$31&+z8,rViz)ZTj<)?9a;Z2t\"+Ad&/7Ad&/73rf6\\-3+#GZ2t\"+\"jc<3#;H;_#;H;_#7Ub;'b^]HL^%f7'@%'uXr8,1)%Y\"1(YTaG(DFA'&'c%/c41j.!uEDi!Rh5\\#@R]:#;lSc'b^]HL^%f7'CGr5\\fhmD)%Y\"1(VV,5(DEqr&&'8)dM?d<'E/[Vc5@Gd\"!&$W(H2!k\"6T_R#m187AHN#L'*J,f#&k@lMB`YW)&LR9E#02I&.d&((Q'FX'*B$uo*,<q!=.E]!s8db!<WE='*J,f#&k@lndl>C+W&iM&$?feg)4iG';?odc5@Gt%il;c(HqI'!t,@9!S[jG\":)14!s98O\"8dlYE#02I+V2.-(YTaG(DEem&'c%/Sc]uH!uGna$^q)/%g.ak'FP!F#Q4Z*_Z=5,#/pq.%L:qn!s98O\"8dlYE#01^$kL&s(Xa(<(DGdI&'c%/U'r%U!uHptK`M8X#CupY!u2IOqhPGq(DHKg&$?feg)1FH)&M!EE#01B.1a]A(\\T-q'*B$tZNBk)!rrB0%LW7:zz!!`K(!\"8i-!(-be!#kn<!#P\\9!!*'\"!&FTT!$M=B!(-be!(?kf!&FTT!(6hf!/^gX!/L[V!/L[V!3cG'!-%u=!(R\"h!(-be!!^I*!=)I(!s],7!u2=KqhPGq'+a42&$?fag)1F4+VWQIE\"`c-)%Y\"1'BTQ@%g*IM;==RU!s^C[!u2=KqhPGq'+`Y-&%Wntg)4iC&'bXqc5@;H'-.Sc'*hA:UBLm\"!s9%V$+L?#\"p\\-1!u2=KqhPGq'+`M:&$?fag)4iC&#pBUc5@;D,TRBt'0Z%#6O*j=!s8dR!s98K\"8dlYE\"`c]%hHB!'@mh9'+`qB&$?fa^*=0&,88cV&'c%+^*@S1&*>,Jc5@;P+<:sp'.2T?o*:]bli@Ir,R:FP!s8e5!<WE=%g2]b#&k4diZSiH,88K@E\"`c!%1g`%'>>]1'+_)e&'c%+_@7Lr!tuC;\"Tnj:f`;0W#MfC_!u2=KqhPGq'+^fG&'c%+g)1F4+VWQIE\"`c)+:la8';>mU%g*IlNs>d)\"onW-!!!!$!!!!4z!!!!3!!!!L!!!!J!!!#[!WW5C\"TSPF\"TSO*!!!!_!!!#[!WW3(^?>S&jT,Gc#71J7'cR8PL^%f?)i>UG^*=`J(2t?7c5@/<)'=_U*?,)&\"m#ae!s^7W!u2aWqhPGq*ug4]&$?fmg)4iO)s.D:c5@^a*ZZ1%*s^m.WrW;-jT,Gc&;C=L&%2`K;$-n8)[#tn#&kY'WZVhd,9PVbE$$%e((\\\\.+0$G()Zq2<!=&k4(C/Im!s8dN!s98W\"8dlYE$$$N(D!Ye+2/t=*ui&u&$?fmg)4iO)n$Ilc5@^U(EFFs+)hIW\"c=Q1SH1MK#GD/#!u2aWqhPGq*ui'0&$?fmg)4iO)p/Esc5@_t$lp8h*tPpa#FZnCPle,m!scdG!s98W\"8dlYE$$%u-kEI!+5.TO*ujbi&'c%7iYrmW\"!9\\3$NgV=km7\"g!se&k!s98W\"8dlYE$$$j#7o)t+2/t=*ubCpXr8D9)/pZ:U)jij)'9&')Zq0FZ3q`ZE2*O@Xqq?1\"Tni3R0!Hm'cR8PL^%f?)nl[jXr8D9)%XG++4:pD*uk&)&&'81g*CVZ)s.YAc5@_h)]]k\"+$Hn;!sbV&#7%CJo`=jnmf`dublRtL'cR8PL^%f?)tG*^Xr8Cj-#aqFU(%XE+WoDUE$$%5,S.U6+5.tNXr8D-)/pZ:RKa;6+WoDU&&'81`ZT4B)mU1hc5@`#!Z`3^+$K<=!t-+WP61FZZN9%q&'\"cViYRpc!sbq2\".'#nSHArr'cR8PL^%f?)tG<dXr8Cn+`JMBp(e1Q,9OoJE$$$R!tVsd+5.TO*ujJj&'c%7ng5@r\"!:bD$c</N>M9r.\"/Q%4,8UFe\\HrAm#7&oa!s98W\"8dlYE$$%E&eD]$+5.uZ*ui3<&'c%7c4V-:\"!@LC#7$,3&+1YIL'.at!<WE/JHQ&W'cR8PL^%f?)m0Y]\\fi0L)/pZ:_ANm0)'@-A&$?fmc5CRC)k%NQc5@_@)''Xu+)pZR6hUQdR0*OA#I+C6!u2aWqhPGq*uj2f&'c%7g)4iO)tG']^*=`n\")o>$NZ/M?+WnuI&&'81U*jn%)s.86^*=`>+E/DAZ5aCd+WoDUE$$%%)\\:43+6E\\H)Zq0'XqVZS5aqul$O>r6#KHn9!O<(8#7%XA\"4IGZK`qP\\'cR8PL^%f?)u]sNXr8Cr,7i';+2/t=*ugLR&$?fmg)1F8,9P>L&%Wo+g)4iO)j1dD^*=`j%WEL/nf\\Oh)'Ah\\*?,)&E6eWQ#-Jc8!U_3<q@?WK#.jqd#K[,O!u2aWqhPGq*ug(D&&'81p&f7U)u^*Rc5@`')''Xu*tRog#N?q=Z3pa>#>G:&#Oqs\"!u2aWqhPGq*ug4J&$?fmg)4iO)d3c`+WnEC&$?fmg)1F8,9QU]E$$$b*tPLm+2/s1c5@_<,B+_DZ2tQN,9PVbE$$%e%hHr'+-muh)Zq1$Rg%[OMBi`/*='S#QiXK#hZV[=E!HWN(I&-0MBiGG\"nMs$-3F>P#L*GT!u2aWqhPGq*uioJ&'c%7^*@S=)o`R&\\fi00,7gpq+5.TO*ujbr&&'81p&f7U)l<lOc5@_D'HJ+p+$Hn;gBWW;E74gmXr#Cbp)X;D#Q4`,!tWs,#GNFJOTtsj#F,Mr!u2aWqhPGq*uj2L&&'81p&f7U)s.V@c5@_`%NQJj+();]!s](I#Qk/6\\H`3='cR8PL^%f?)n$4e^*=`J(2t?7q@F1O,9QIdE$$$Z+:l12+8,eU*ug(M&&'81g*CVZ)i>.:c5@^]&fhnn*u\"qbXqqPu-O9&Lc2k3Y!sbM#JHZ,X#Q4l0!u2aWqhPGq*ufeT&$?fmg)4iO)i>1;Xr8Cr,7hL5+7]n\\*ug@k&'c%7^*@S=)n$(ac5@^e-lj6/+)hGiMBp(?rWf>+U)H2#$NgWQ#7%CJE!HW*,R9/2QN[Hr`<ZPJ'cR8PL^%f?)mU:kc5@_<,7gpq+2/t=*uhp7&'c%7Z5=T$\"!;L6\"R?,l(C/%`!s8eq#Qk/D)[#tn#&kY'NWTg+,9P>LE$$%e$kLW$+3kQ@)Zq1$#7%CJ;/l[?#E];p!u2aWqhPGq*ufqL&%Wo+c5CRC)nlXi\\fi0L)/pZ:p&koO)'=SJ*?,)&9$RPEWrr[H\"p:J!#JCEG!u2aWqhPGq*uk1k&&'81L+.'`)nmU/c5@`'&KMem+2e0^'+5&)#m180!$qUF!!<3$!\"o83z!/(=P!%@mJ!#tt=!070]!':/\\!'(#Z!0@6^!-J8A!(?kf!0%$[!0$sY!)`ds!0I<_!2fes!+l32!0[Ha!7(WF!-J8A!1!Zd!:9ad!.OtK!070]!!**#!/ggW!1!Zd!#Ye;!1j/j!0[Ha!%8!N!%8!N!(-be!3lM(!0mTc!+c02!4`(0!0.*\\!$2:D!$2:D!-nSF!6kKD!0%$[!#u.B!#u.B!#u.B!#u.B!2T\\r!9*tY!1!Zd!$h^J!$h^J!6YBC!:9ad!0[Ha!8RYU!;lfs!0dNb!%J-P!%J-P!<3'\"!\"8l.!0I<_!$h^J!$h^J!$h^J!$h^J!$_OF!#bk<!0[Ha!&jrZ!$_LE!0@6^!(d4l!&aiX!1!Zd!!nhO!='2=!s]D?!s]D?\"!Zk4fF<lD4n]Eh#6u[[\"\"\"*P!tktDVudY<!s8cG!s<KI#FYYu*<QBK&H`+8!\"8i-zzz!6bEC!2'Jq!2'Jq!2'Jq!29Vs!2'Jq!2'Jq!2'Jq!2'Jq!!Cj8!='>A!s]PC!s]PC!s]PC\"\"\"*P\"#^Mh\"&B:,&I5-6!s::d)Zs<m(EW_a2$3q9\"!7UM<<E>-hBX<J>Ikt*!t6+^\"#:B+!s^C[\")o1qq?7$)#9*mk!s95V!s8dZ!<WEgRKOQK#A!u>'H7,V#AjPF$6'e]%U6Ll*s32r!s8dV!s8c?!s9YJ',q0^!s:E[&'P3Y#p0[\"\"%O.0\"%q,Z',LnY!<WEh!uDb$(B]3h#JC0@\"$bKA%hAo9!WrNfM@'G%#DE3]\")o%mQ5g/\"!<WEK,PE!\"#O)6k\"$`La(Dh$4&,IDf,7h'^#JgEC\"$QVa\"!9b9!ZrLgndd)M#E8`d\"#2/:!sb@t!s;/M%20O@rW**;#KZuK!s8W=!sbq0!s<KY(WHde\\H)d7E\"<Jj*'MFT!u#Ve'D;J4r;d!&#QkS>#E8ce\"#9rh!sbe+!s9JI!uF-\"!<X9[)]R'=#MB+[!s_C\"!rrN0$3C\\G&k2j$zzzz!(I%j!!3-#!(I%j!(I%j!*01%!*01%!*01%!*B='!*B='!*01%!*01%!*01%!*B='!*B='!)s%#!)s%#!)s%#!*B='!*B='!*fU+!*fU+!*fU+!*fU+!'(#Z!$D7A!3ZD'!*fU+!*fU+!2KSp!)*Ip!)*Ip!)*Ip!)*Ip!)Nat!)`n!!)`n!!([1l!([1l!)<Ur!)<Ur!)<Ur!)<Ur!+Q!/!&afW!2onu!)*Ip!)*Ip!)*Ip!)*Ip!)Nat!)Nat!)<Ur!)Nat!)Nat!(m=n!(m=n!)<Ur!)<Ur!([1l!(m=n!(m=n!(m=n!([1l!([1l!([1l!([1l!)*Ip!)*Ip!)*Ip!)*Ip!\"/8Z!=&c1!u3$_qhPGq-R7U`-nD//dMtXW_n-.,E%`lq)dA=E1BUk4#r_rm\"\"sa00/&J0>q7QY!%TR_&6152_BhgW)CI%S-R6>M&'c%?ee9&K\"\"+=F!s98W;u;@TE$$$V,7h@/+5.TO*uj>f&'c%7c5@.q)B[ZNE$$%M'+`A++4;DT)Zq0FMB)d(E!HX-#ZI&jRfVdi;$Wg@%gRXd\"2=mBK`M8X'cR8PL^%f?)r`\"O^*=`F\"`PP&Sc]M7+Wn9=&&'81U'tu_)jUa?c5@_,)K6c;arh4t)BZ[<E$$%9%1fT[+1`V7*uj2Y&&'81dM?dD)hJG.c5@^q\"!&<_+2%]T!Y5qWcN=8W*tOD;\"\"s`Y#;Qtm\"9YD\"i;j#_#NYsg!u3$_qhPGq-R5?5-nD//dMtn5jrj(16j&M>\"#FmP1QiMXq?Ak\\#Qljb5qalI>q7QY!%TSF*E=U?q?T^)+X\\dZ-R8U=&'c%?U*gs+\"\"+>Q!X#J-'cR8PL^%f?)mU1h\\fi0L)/pZ:NY2l*)B[ZNE$$$n-P+K?+0lV%)Zq/a!sdul-O76gd09it!s8W1f`D6X'cR8PL^%f?)n$n#^*=`J(2t?7dK'm()'>.W*?,)&'FP!FnH#<d!s8f,!WrN>)[#tn#&kY'joQ(-,9O',E$$%!\":qXR+5.TO*uhp5&'c%7joQPB\"!:bM$O[3U\"Hs&m#H7e-!u2aWqhPGq*uh4+&'c%7^*@S=)s/LYc5@_(,omp,+#9Sq%g*'e!WrN0bl\\%M'cR8PL^%f?)gW%?)'@-A&$?fm^*@S=)nHmtc5@^M*?,)&E:4#2#LXFonH/jq#PA0$!u2aWqhPGq*ugdY&&'81g*CVZ)mTYYc5@_L)/pZ:c4UZ5)'?-g*?,)&E8(O(`Wf-F$i1#3q#UX##GhP*!u2aWqhPGq*uk%Y&&'81dM?dD)n#n\\c5@`#\"!&<_+0>S.\"9S`2`<68F'cR8PL^%f?)r:].Xr8D-)%Y\"1+0HN$*ugXk&'c%7h?4i<\"!9;=!ODt4#GhM)\"\"\"*P!s2`j!QkZQo`P@!'cR8PL^%f?)qk<'^*=`f(2t?7OpDT$)B[ZNE$$%Y-kFT@+5-`9)Zq1%$NgJ9blu]%!sbM'!s98W\"8dlYE$$%e'b@Gc+5.TO*uk1b&$?fmg)4iO)sRtFc5@^i$QU/g*t/Mj\"&fT\"#-&.<r<A/_!sd3W!s98W\"8dlYE$$%e%hHB!+4:o8Xr8D9)/pZ:`WQgt)'A8W*?,)&,j>G=!seK&!s98W\"8dlYE$$%E+V2.-+5.TO*uj&?&%Wo+g)4iO)q#-*^*=`>+:l%,+5.TO*uh4$&'c%7dL7-8\"!?.rdMEF\\!aFpk'<_NDXTel_\"UD::!s98W\"8dlYE$$%1-4d6t+5.TO*ugLf&'c%7V?e1]\"!:aM)A`J\\SHZn8!sd?\\!s98W\"8dlYE$$%='G%bu+5.TO*uj2^&$?fmc5CRC)t\"@Mc5@_`+<;C'+#4eM\"To#\"\"Ttq0#D!*^!u2aWqhPGq*uj>E&$?fmg)4iO)n#k[Xr8Cn+`JMBg(Y(C)'?9i*?,)&>Il2W!<WSs\"MY0D!!`]8%MBNq*Y\\SS!!<3$!&FTT!($\\d!/:OT!/(CR!/(CR!,hi;!)ijt!)<Op!1j5l!1j5l!3H5$!+#X*!)Was!5AL6!,2E5!)N[r!7_&L!-/&>!)Was!9X=^!/LUT!)N[r!##A5!0@0\\!)EUq!$_LE!1Elf!)Was!1j5l!($Yc!':2]!2fes!)rt!!)Was!3lM(!)imu!+c02!5&:3!)rt!!.+_H!8dbV!)imu!5S[9!9jI`!)rt!!\"Pdd!=(%U!s^7W\"$cr%#6uCS\"'bIB'*AIG!s;cI\"qLe@&H`+_#6SB>2$3q9!s\\om[Nc\"^#8mUG#A!u>#<`.k1(+Hl1'8$h#>kR*@0cc8!s`6:\"!@[N',M#Y!s_C\"\"'WSLYmm!/-3F>P+9MiV-OU#b#<;kg!!<B+\"r71=zz!!`K(!!iQ)!0@3]!$VLF!$VLF!$D@D!$D@D!$D@D!$VLF!$VLF!$hXH!$hXH!$hXH!%%dJ!%%dJ!$hXH!$hXH!$hXH!6bEC!$VLF!$VLF!$VLF!!W)Z!=+_i!s8dj\"9S`2%0H\\I)[#tn#&kY'jp2L/+WoDUE$$%1+V2j9+6EhL)Zq/eOTYc!#IO^;\"\"\"*P!s^[c!u2aWqhPGq*uh4&&$?fmXr;7$)pSTtXr8Cj,nI^7+3#FB*uhX'&$?fmg)1F4+WoDUE$$%u'G&J,+3k$1)Zq/hdMn5K\"'_oHRfW[#$PNUIeH3JhZNCGX!s98_\"8dlYE$ln(,q(:@'[dsh\"2h_U05rQtqA*;\\'f,pt\"\"saE\"-;pR1N5-+Oqq9%&N9dt\"#C$b0/G7e.k`CQ.kBTh<@]SO\"%piV-S'-`,E<6^/#F$/*(0nH]*C!.0/'%H>G`N!!seu^\"%36Pn,kIc1Gd/l>ODYR!seub\"'mQ903p(].f_(M_AZE)/#EGA^*>!UE$lmm,S/0<-aG!<,6K:uK`V>Y\"WIR@L^%f?)hnP-\\fi0L)%XG++4:pD*uhL2&'c%7L'A[%!<XFr!A+CX#H7b,!u2aWqhPGq*uhL#&$?fm\\fl#7)ibOA^*=`f(2t?7U*gJs)'?.!*?,)&>Il2O#6PYJ!s8dN!s8e]!WrN>,6Rh!#&kq7\\fE1LVA.Gu6j(?=#;:$L0CAsIXpd)g#Ql^^<\\H+,-SGRQ\"'_c50*>!'\"-isV\"-;pR05rQtOqq9Q!]'oa\"\"sa^.k`CQ.k@2+<@]Tn-;(EZ-S'-`,LQT'c5A\"@*??@,-O7$]G68R!\"8dlYE$$%m((\\\\.+3kaC*uhd3&'c%7p(eYf\"!:I^\"UD%;#GhJ(!sdK]!s98W\"8dlYE$$%I)@sD&+5.TO*ui3I&%Wo+g)4iO)l<rQ\\fi0L)/pZ:`YoB5)'>^_*?,)&1*6ni\"C':j&#TU:0a#/q\"('RdJHc@E\"9S`@,6Rh!#&kq7js)9)VA.Gu6j(?=#;:$L0@h(HNZ9hW6j)bU\"ugK[2hDB)\"7)ul4)d8CXoSe12ZlGMO7365E'$/()I%e,56D/n3s._M'/)`UO736-E&0<@$<tpb2Zm:L-9D<6rWPLg5Q_ZU5qalI>q7QY!%TS>\"'$j%iWDfa+X\\dZ-R5W1&'c%?js(lk\"\"+>9\"U\"&n'cR8PL^%f?)pSHp^*=`:!cT5#js(D^)'@!C*?,)&2?s<dV#^f'/I*^,!sc@?!s98W\"8dlYE$$%e%hGf]+3k`7\\fi0L)%Y\"1+5.TO*uh4$&&'81dM?dD)mU7j\\fi0L)/pZ:NYE#L)'?.#*?,)&1'7n7\"0Vfj\"8;pOo`YF\"#PeN*!u2aWqhPGq*ufq>&'c%7c5CRC)j1^Bc5@^Y#9=`c+\")[C\"4[JYR0E`q'cR8PL^%f?)qlVL\\fi0@)/pZ:V@4!\\)'@QZ*?,)&4n]EhhZn*.$^q)$]`nQ@#JgTH!u3$_qhPGq-R7U\\-nD//dMrHEhA_%o-SGST#$^3o0*>!'\"5sGgWX:B]<A-\"k-s\\>V.f_(MZ5HXm/#ED@^*>!UE$lm9!Y<Qo-h8N',6K:uKa.\\^'cR8PL^%f?)i>.:Xr8D9)/pZ:jol:,+WoDU&$?fmg)4iO)n$FkXr8D9)/pZ:ng\"ak)'?:$lN%q,*tf+I!H]\"`QNdNs/a!AR\"98]Z&/><k.4#uE!!!!$!!!!+z!!!\"J!WW4L!WW3>!!!!>!!!\"$!<<*_!!!\"A!!!\"%!<<,e!!!\"O!!!\"$!<<,r!!!!,!<<,#!!!!\"!!!\"J!WW4L!WW4+!<<,=!!!!a!<<+Z!<<,G!!!!b!<<+n!<<,e!!!!c!<<+O!WW33X6'Ef<<E=.<<E=.<<E=1$O`sE#8mUG#E8`d!ttb=$O7CK\"'a1i%g*%c!s;c=\"qq)CXr8)Y$k!^N#7Ub;1'\\0h#9a0O0ae3g!s8o5#@.E6&dndE#A!u>&dJMp!=)=$\"&B:,I0XTk\"#1#g!s_*o!s^gg\"'+(]k5gVI'*A=E#DE0\\\"#:Ap!s`rN!saed!s8d.!s9kP!s8N+!X8uA(]XO9zzzSc\\rmSc\\rmRKENiSc\\rmSc\\rm'*&\"4&-)\\1c2dnFRKENiRKENiRKENiO95I_O95I_Mus%[Mus%[RKENiRKENiNWT7]NWT7]RKENi:&k7o4TGH^+ohTCd/a4Iz#28GF#E]8o!s],7!u4$&qhPGq6U0EM-qC-KdMtnQmNIH$6j&M>\"&El3:\\\"isSgIA<>F#=l\"'_&m>6@+m'2Mn,:J4t`91JtP8*U7X7n:iD9!0(\"7rUg[^*\"goVA.Gu6j(?=#>9#/9C;pN\"-;pR:N0**Q3pje!`K2*jrme.?3<t*<DQE]$q(2Yn,lU.;cAhp>J:,>!sf!-\"'u(&\"'nDi7fZ%Lef%OY8,=#o^*?!8E'lk8)%Y\"16coZT56F7XT`G5t'fY.TqhPGq4#cjA&%WoGg)4ik2p)C:c5A_;%/g2c\"$6aM#QqC<#JgEC!u3`sqhPGq4#c.<&$?g4g)1F8,<O<hE'$\"q&eE8*45q2\"2Zl,lOU.9X\")ob@q?7,#!s8W1m/[:k'fQ6lL^%f[2i\\@YXr9C9,B,_'JfbNK)*<ig*B+'^\"OS(8!\\Xe<!WrN>2Zrr5#&lX_U*gJc,<O<hE'#u_&'c%SU*gs?\"$8-;\"Tni3XTAS,'gDftL^%fc5O'LB8#@!K*(0nH]*CuJ92#*o6j(?=#>];7:\\k\\l\"-;pR;fGZ6ar4LX&Q]&?\"&f:-\"&B\")\"%r`%7nZ>P7n8jZ<C]QN*_NRR6Uu)_5F*#pc5B!8#ou546O//E!s98s\"8dlYE'$#@!Y;FP48'C\"^*>_n,]Gh(Q3e)I)*?s^*B.%]i;kHm#1==nK`qP\\#H7e-!u4$&qhPGq6U18O-qC-KdMtXWO736EE(`jp$<sqX:BOh<*E*&ErWQ@*5Q_ZmCeMVG9.*@7f`PHM!_WVk9*=,T>K.%D\"%36Pn,lI*:J[8`>J:8>\"'`bn<s)b2:BMA*92?p.\"+^SZNX8>\\:J1eH\"C&_M9*8Hi91JtP8#@V57n;899!0(\"7rUg[Xo^\"AVA.Gu91t-YL)`S`O736IE)08q$<t4J;Zg7P+'/PN\"&B\"b91r&d7nZ>P7n:uB<C]QB$;/#W6Uu)_5NX=(c5B\"C$6;>56O2EMZNC;K2Zrr5#&lX_nf\\OT+ZnBq&$?g4g)4ik2tdRhc5A_7+!!9B4$bM1.r[-pWZMK1!RCee\"UBkf!s98s\"8dlYE'$#$*tPq+45(P_^*>_f(2u>og*%!P)*>\\\\*B+'^E%<HY#!LoG\"-WlnPoKl.#IO^;!u3`sqhPGq4#b.^&'c%Sg)4ik2l[;tc5A^`\"<BE'4'nN^.g$$5#Qk/6f`_H['gDftL^%fc5IM7S8#@!K*(0nH]*CuJ92\"[q6j&M>\"&El3:R2>l^'.F;>J_1X\"'u(*\"(b8([Ke0U\"-!LhM?QcX:JV(h#\"/QSn,lI*:J[8`>Ohho\"'a%T<s)b2:BNueO736ME)T\\u(0fK)<s&^1;Zg7(.9?U:!u\"=57nZ>P7n9![<C]R5%naP\\6Uu)_5JddV8#@!K*(0nH]*CuJ92!hT6j(?=#>];7:\\k\\l\"-;pR;fGZ6ar4Km*EN=K\"&f:-\"&B\"e\"-;pR;fGZ6nd8U\\$s*O8p'+_'>P88.\"$cr%;dKQ!\"'nDi7fZ%LZ3aN$8\"pVgc5Au>E'lj-&'c%[[M0`H\"%0Kt[0Hd9'fQ6lL^%f[2i]$l^*>_Z+:kUn46e&04#aS^&'c%SmL:1l!WtMK[K7s0GfBq0!sc(7!s8ee#6P&C2Zrr5#&lX_Z6^%,)*?sdE'$\"i$4j]k45(Qk4#bk3&'c%SZ6^MM\"$:J.#:%Y6#Lrt[dfh*L\"47qjW>Yj@#F,Ps!u3`sqhPGq4#c:B&&'8MiZW8&2hE1`^*>`1)\\9M'45(Qk4#`lS&'c%SjrGI$\"$<F^#6P(,!=K.U\"]#L.i>2a@#Qk/D2Zrr5#&lX_Z5=+d,<O<hE'$#($4kE\"40f\\D2Zl.L!Jqcu!se&r!s99&\"8dlYE'lk8,Uc0['[dsh\"2h_U95mNs^(j$<O736IE)09P)I*1e;Zd:-:BOTm:Wa;SWWlB(?3<h&>t7OX!(TQM*E>U\"h?-Ba,==t?6U-;I-qC-KdMtXW_n-.HE(`jt#t+m5]*D,N:J^g&6j&M>\"&j/;;jIbpncDkp>OiV8\"'u(.!sf!)\"'^@$;Zg>.9*8Hi91JtP8&cfS7n<+R9$S;A7jpm)'[dsh\"2h_U95mNs`ZISNO736IE)08q$<t4J;Zg7d'NYBC\"&B#'ap1iI?3<h&6j&M>\"&El3:R2>l^'.F;>Cmhr\"'u(*\"'nPq93k%\\7fZ%Las^7[8(&eX\\fjF2E'lkT'G&J,6^e9$56F7Xd0]sX(&%k6_ZFd=2mru&\\fj/h)/qYrRKsGL)*>84J,qS23sXRH\"#C2P$3LAF56Le=#&lpoh@qA.VA.Gu6j(?=#>9#/9>2-/\"2h_U:N0**U*a*i&5rZ:\"&B#'eeV0d?3<h&>t7OX!(TQE%ol+iapC\\C)FI#66U-;E&'c%[V@=P1\"%*=,$NgJG2t$tJL^%f[2pN`\\Xr9BZ*\"Tb.46dJu4#`0<&&'8MQ3e)I)*@O,E'$\"U%1g`%43f/n2Zl-P\".KDqM?3/M-d`b9XW7KG-3F>P#Or0(!sec4!s99&\"8dlYE'lk$)^n4R'[dsh\"2h_U95mNsmK>o[O736IE)0:#$<sMT;Zg6i!`oJ.Q3(7m5Q_Zq<DQDJ'LW&hWs2LA;cA8T6j)bU#$5bF=0;Q0\"&f;+Q7,f:5Q_Zm>t7OX!(TQ5&lhFlmMAL@)+-nB8#@!K*(0nH]*CuJ92!8H6j(?=#>];7:\\k\\l\"-;pR;fGZ6Q3pj1\"]ke1Jdtue?3=+.#Qmj)>F#=h\"'u(&\"'nDi7fZ%LNXo,[7uA]e^*?!8E'lkH(_=n06eW=s56F7XXUP@7oDsjN\"8dlYE'$#4#7msU416FG^*>`),B,_'aor<e+ZnBqE'$\"a$kKom45(P_Xr9CU)/qYrg(t:F)*?7o*B+'^>O!4F\"'_oH)qP-A&,QD1#Fu@n\"ht6HnI5R&'fQ6lL^%f[2qB8c\\fj/h)/qYrMBNMU)*>PWE'$#8(D\"e/4,P1%2Zl,spB(p.>LF<$!seW0\"/>u(Tah/,'fQ6lL^%f[2j+=TXr9CU)/qYr[K@&c)*<ub*B+'^#Or1_!s8eE%KceJ2Zrr5#&lX_h@1\",+Zm7YE'$#4\"qRjT40BK@4#`<-&'c%SU(n\\-\"$9?^dMNKZ[K6tl\"^AtN(BXo9&-E\">oaV'+'gDftL^%fc5LL,l8#@!K*(0nH]*CuJ92!8H6j(?=#>];7:\\khp\"-;pR;fGZ6ar4L\\'NYAB\"&f:-\"&B\"e\"-;pR;fGZ6Q3pj1\"]ke1^*m1f?3=+.?3<h&>t7OX!(TPn\"B@r^hAJqg)FI#66U0iR&'c%[dLdKa\"%*=L%poDR2Zrr5#&lX_Je/Hq)EZXj&&'8M_?+[<2pr9Kc5A]q&03\\34#%6jm0s;O&-E\"L2Zrr5#&lX_OqSA?,<O<h&$?g4g)4ik2uXO&c5A^,'-0\"64(\"ruhZ<md!tPJ=nI>X'#H\\O>!u4$&qhPGq6U.^V-qC-KdMtXW_n-.HE(`jl+@H<mn,lI*:J^Ng>>eB%>P88&\"'bI'>6@+m'2Mi8-;t\"N^'RjC5Q_Zm<D,st>t7OX!(TQ!**#L!E_<JQ6Uu)_5LKof8#@!K*(0npWs24991sjD6j)bU##B26:Ta^(\"%r^r92!,F6j&M>\"&El3:R2>l^'.F;>HT5Q\"'u(*\"'nPq93k%\\7fZ%LhB>lh8!4ue\\fjF2E'ljQ,S/0<6dc>_56F7Xd1HKT\";NitqhPGq4#a;`&&'8MdM<A)+ZnBqE'$#,$P1N#40BVF2o>k^V#g6(\"/>og!uh=Iq%3]2'gDftL^%fc5Ct./8#@!K*(0min,l=&91tE`>J_@U!sf!%\"'A4Q,\"ks09=>'Q9*;\"'>M^Z!\"&DPlXV+j\\+\\MoC7nZ>P7n7;o7n<Os9!0(\"7rUg[efH50VA.Gu6j(?=#>9#/9DT8h\"-;pR:N0**nd8U@!E0))Q3(+i>F#=p\"$cr%:JFWZ'Mg)P\"7[\"._BMbX:JV)g&mLe9:BLk)9*8Hi91JtP8(&P\\7n:9%9$S;A7rUg[dLQl6)+3+\"*BsWn#FuM1!u6jt\"8dlYE'$#T+qMs:47Wso^*>`1)\\9M'45(Qk4#bk8&'c%Sp*Uk>M[)=F!s\\q+!Q,'KZNga*&H`+?bnC0]'fQ6lL^%f[2jOsbXr9Cm&TBfjmKjE<,<O$jE'$\"m!tWZp444m`4#c^<&'c%S^&oB7\"$85m\"W%7_$e#:nC`<K((^Ga/!s99&\"8dlYE'lkD(aqnO'[dso99(+R,;2\\_V?^Bs91JtP8,a]47n;\\T9\"H057rUg[Xp5K_)+1tF*BsWn#ItNN!u3`sqhPGq4#^UZc5A^t)/qYrSg\"]Z,<O<h&%WoGg)4ik2nBJ0c5A]Q*B+)X#7/c](BZhc+p/dV!QbuWmfEa]'E\\FP56Le=#&lpodKM$hVA.Gu6j(?=#>9#/9C<oj\"2h_U:N0**jq:mm%oWR7arsgg?3<t*#Qm^%>t7OX!(TPF%TQ\"hncqdu+[\\b=6U0E>&'c%[_?V)G\"%*=('a\"OQ2Zrr5#&lX_U'_F6)EYMR&&'8Mg*CW!2s)1m^*>_n,]Gh(_?UUs)*?t&*B+(a\":PeO`Wf9Nrrr6&#H\\dE\")o%m\\g9S$\";_jZJJ81g#Pf):!u4$&qhPGq6U-kW-qC-KdMtnQZ6A?<6j)bU##B26:Z`H]\"7)ul;fGZ6XoSe1:BOlq:J4t`91JtP7o!&S8%Ks<c5Au>E'ljm\"\"6[:'[dsh\"2h_U95mNsef.!ZO736IE)08q$<t4J;Zg6U(fpfG\"&B#!:J]OD>Q,14\"'^?X<s(\\i'2)V$91JtP7tq1I7n:,r9\"lN;7rUg[iWg\">)+0u=*BsWn#DErr!u98f\"8dlYE'$\"Y-kEm445(Qk4#aSS&&'8MqC$;E2kD0'c5A^P$(CrS\"$?,U\"4A\"s#O)p)1C(0$!s98s\"8dlYE'$\"I*Y5t048&bq4#aks&%WoGg)1F()EZXjE'$\"=,7i';40C\"Q2Zl-=\"6'b'J,uq`!uD4,'uL3m!XIg'!s98s\"8dlYE'$\"I*tPq+45(Qk4#`$$&'c%SRNEP/\"$84B$dSq\\Kbsmo#Dj9\"!u3`sqhPGq4#cR3&$?g4c5@/,,<NmfE'$\"Q)\\:43473:n2Zl.0!WE7p!Wu:%dMNKB%g22.#IPBN!u3`sqhPGq4#`$3&$?g4g)4ik2tdmqc5A^$'cf483sWG/Y6\"e2eJJAj'gDftL^%fc5DCF38#@!K*(0nH]*CuJ92!hT6j&M>\"&El3:\\\"isMAfCq>F#=l\"'ba.>6@+m'2L8W:U20KedGCY?3<h&>t7OX!(TQM#ZXAbdLo0t)+-nB8#@!K*(0nH]*CuJ92\"[q6j&M>\"&El3:\\\"isjp=rg>P88&\"'ba.>6@+m'2M_+h@ECdSdn[$?3<h&>t7OX!(TP2)HB9tl4Q^l)FI#66U.jj&'c%[g(58h\"%*=\\)$9sU2Zrr5#&lX_as%AA)*@C$E'$#4&.d&(43A`fVZk6G4!h?@m0Wq#N>_m$'fQ6lL^%f[2i\\.S\\fj/h)/qYrZ4RVm)*<ia*B+'^#PAZ2MZa9e)?U'V56Le=#&lpoOpia/VA.Gu6j&M>\"&!T+99oohncDSh>D`G[\"'u(&\"#!;?l4m;l9:dG87nZ>P7n;8J<C]Q^(eVLe6Uu)_5GB82c5B!0\"W]f06O39&!s98s\"8dlYE'$#H,nI^74-g0`c5A^$*,mtuhA$RH)*<]qE'$\"=\"V8lr45L]C2Zl-\\qZ8#%%BT[\"\";B0\"#Gi@A!u4$&qhPGq6U-ka-qC-KdN!7q(ea9E6j&M>\"&El3:QcJtiZ;###Qmj)5tajH>t7OX!(TQ1+B:p%mMnj%)FI#66U18T&'c%[Q7!\\;\"%*=X)tsF:'fQ6lL^%f[2o5Y-Xr9CU)%XG+444m`4#`HQ&'c%S_?1f;\"$8*6!j_t24h`!?$ZHI]L+!;c(BXao$R5`YSK%_6#GE+>!u4$&qhPGq6U.Fn-qC-KdMtXWO736EE(`jp$<otq\"'bI';Zg7t#$1ml!u\"<q\"-;pR:N0**Q3pje!`K2*mKckr?3<t*>t[sd<D-!I!F82g7fZ%Li[%Sp8!XQU\\fjF2E'ljE+V2j96co`V56F7XJK4gp'fQ6lL^%f[2qAcU\\fj/h)/qYrL)gf9+ZnBqE'$#$$4kE\"4,+ar2Zn[:0aBAL!sd3j\"-Wk(^^J[\"jTc$q*<QBY2Zrr5#&lX_ed;r5)*?sd&$?g4g)1F8,<NaDE'$\"Y%hHr'4,OIf2Zl-\\.jNIZmK'3dmfq/V#MgC&!u4$&qhPGq6U0E;-qC-KdMtXW_n-.HE(`k#(.87cn,lI*:J^Ng>Q,%0\"'bI'<s)\\##$V0p!u\"H9\"%r_r92!,B>t7OX!(TQ%\"'%i]jqUM&,==t?6U1P[&'c%[h@:Pj\"%.I@*WlKZ2Zrr5#&lX_WX'-H+ZnBqE'$#8%M-i&4/rQ,2Zl,HjTktO!WW9:*A.<l!!<3$!&srYz!&alY!&alY!-\\DC!(m4k!$)(?!1*Zc!,2E5!#kq=!7_&L!20Am!#u\">!(?ng!36)\"!#kq=!'1/]!*]I(!!E<&!#P_:!\"/i.!\"T)1!!*'\"!$MCD!#Ye;!\"T)1!&XfX!.4eI!#P_:!$hUG!$hUG!<3*#!7(ZG!%.dI!20Jp!'C;_!\"o;4!(m:m!.=tM!,qu>!#GY9!(m:m!(m:m!9XIb!.Y+N!#GY9!!<B)!13ff!#5M7!%n<Q!%n<Q!&k&]!4i43!##A5!%J$M!%J$M!%J$M!.>\"N!:'[d!##A5!8.MU!;6Ho!#,G6!%J$M!%J$M!:p?o!!*0%!\"T)1!!NQ,!\"&f.!\"]/2!#Gh>!#,M8!\"o;4!%S6R!(m=n!#GY9!1*li!+uB6!#Ye;!7:uN!.k:Q!#bk<!$21A!$21A!$21A!'C;_!'C;_!\"fG9!3-,$!$;4A!*B4$!*KO,!7CrL!#P_:!#U^X!='2=!s]D?!s]D?!s]D?\"\"\"*P\"(K[fp(\"26!!!0&zzzz!!!'#!!!#ejoG^h!<WE/XT8M+#H\\\"/!se&l!s8cC!s98S\"8dlYE#TUj!Y<Qo)ql/?Xr885)%XG+)hJlF)],Xq&'c%3V?.bS!unHF_[#'$\"&81e^^n'c#=/Fo'c-uLL^%f;([_A9Xr87f-#ae>neVh^)&quG*>\\es5Qf17#:B`Y&I2kL!u2USqhPGq)]+AV&$?fig)4iK(ZGu:c5@RY,97R&)[GU.EruZ$!<WE=(BaPj#&kLtndl>C+WK,QE#TVm%hHB!)kma[)]+)6&'c%3rXU\"c!uobk[Nc\"^#MfC_gB@he!<WE=(BaPj#&kLtiZSiD+WK,Q&&'8-l4\\+U(Wmj2\\fi$H)/pN2WZhu!)&qQY*>\\es^B\"EAcNOQ)!<Zh9`WcqU>NQ2)!s^sk!se2o!s98S\"8dlYE#TUR%M,]\\)ql0K)]+)J&'c%3NXd'G!uhISZNgR;N<01a'c-uLL^%f;(U=M]\\fi$H)/pN2Op2H2,9-V%E#TSt&'c%3Z47lk!ui$a\".'5<!=/T-!s]D?!scL@!s98S\"8dlYE#TVA!=u=O)pT=?)]-L=&'c%3dK(@)!uj!'Y5n_1h#[Z\\1'8$h+9Mi^#DiKa!se2p!s98S\"8dlYE#TUf%1g`%)pT=?)]/&f&'c%3g)1F8,9,J^E#TV5+:la8)tG*l(BYW/!L!Nh$R^Q0!tbdK!WrN)!sJ`1%KHJ/zzz#ljr*%KHJ/7KEJhU&Y/n+TMKB(B=F870*Ag0`V1R+92BA7KEJh6N@)d3WK-[70*AgG5qUC63$uc7KEJhLB%;S9E5%m7f`SiO9,C^O9,C^T)\\ik=o\\O&7f`Si[f?C.AcMf27KEJh#FX]T#<;kg#<;kg#<;kg.&R?J%[[PL!s8W<'*F0p(CL<I#9a0O#8%%?4oPHa$O86c\")nVUSfBtp!XfA@'a\"Or#6P&U#6PPC,m+5S3<K?`!XT;Czzz!!!#Y!!!\">\"98FF\"98E4!!!!/!!!![!WW3%!!!\">\"98FB\"98E*bN8g`$NgJq[K6[E#7Ub;>K-j`\"'u'?\"\"+T]M#mq\\!<WE/<<E>B+!6@F4c0RK,6tIS!s:]p-j(OrW<!)'5Q_Z90EW6r#;$#[E#0>a!aG(5)Zr6\\$3MAh+!7'g#9a0O4g#=u(C*5.\"#9s#\"$a43+!33b%g+O:(BZBF)Zp>)!<WEY,7=SZ\"!7UMT`G5t5N3G',8;@)!saYa!s:dj(EYlM%j*#1,6J$e,9O?1#CumX\"%p!M)]o;j!s<Ka+8,a@FTV_b,9rcjE$HTb-3lC1\")nnaq?7,k!<WEh!tu>R$PO1.$PNUI]`A3;>M9r2\"'_oH)Zs<u)'8qc`;p&CE\"`oY!XI6V!s:h*$PRIq(TJQ&q?r,](C,Wq!s:^+)$:NWjT,Gc#9<mK-3F>P=2tB^%tY#d!<k@]!!!'#!!)9c!!)9c!!)9c!!)9c!!)?e!!)?e!!)Qk!!)Wm!!)Wm!!)Wm!!)]o!!)]o!!)Wm!!)]o!!)]o!!)Wm!!)![!!\"AH!!!f8!!%<G!!\"_R!!\"#>!!%BI!!)]o!!)]o!!)]o!!)ou!!)ou!!)ou!!)cq!!)is!!)is!!)ou!!)ou!!)]o!!)]o!!)]o!!)]o!!)Wm!!)Wm!!)Wm!!)Ki!!)Ki!!$R1!!\"nW!!%3D!!)']!!)Eg!!)Eg!!)Eg!!)Eg!!)Qk!!)Qk!!)Qk!!)Qk!!)Eg!!)Eg!!)Qk!!)?e!!!G(k5bg%!s8c7!s98K\"8dlYE\"`cE#S4Ki'A=<7Xr7u-)/p6\"c5@/<)&)-<*=i5c#AG+^#AF8B>f@,O#4i.?#7$,3#Oqit!s^sk!u2=KqhPGq'+`@l&&'8%dM?d8&)n-2^*=<F,S.$r'>>]1'+aXD&'c%+iXd+@!u#ARcNUHfR/r]W!s8dF!s98K\"8dlYE\"`br(D\")#'A=<7^*=<>(2sotWZVht)&)9_*=i5c4gGFt#E/\\W!sAE'#F,;l!u2=KqhPGq'+adF&%Wnt^*@S1&&JqiXr7tf,B+;,V?%4Q)&'_,*=i5c&+V\"OMB>!e$NgKM#@jnQ#E],k!scpK!s98K\"8dlYE\"`c]-kEI!'>>]1'+a@A&'c%+r[8ct!tu4E#=mJh4gGFt#7'Vs!s8eu!<WE=%g2]b#&k4djpr!:,88K@E\"`cA*tPLm'>>]1'+^Z;&'c%+iZB0O!u#VYK*JIpUB.n.!s8e!!WrN>%g2]b#&k4d^'bIS)ABh0E\"`bf'b@Gc'A=<7\\fha@)%XG+'@IY8'+`e;&'c%+^'bql!u#VYLBWP\\N<,.BdflcQ#LNST!u2=KqhPGq'+`M6&%Wntg)4iC%uq85c5@;8+<:sp'6\"0]MBiGG!<\\5\\#PA-#!u2=KqhPGq'+^fH&$?fa^*@S1&*<p(\\fha@)/p6\"Q4a_R)&&_R*=i5c&,I=0\"4dT<Z3pa>#<;n8\")nJMXqq<t!s8e1!s8W?%g2]b#&k4dp(e1Q,88K@&%Wntg)4iC&+1hVc5@;,)''4i'+aLU#D*`=!RUuOT*GVO!s8W?%g2]b#&k4ddM`Y!)ABh0E\"`cE)@t+2'>>]1'+]g\"&'c%+`X*Xr!u!i'$NgWQVZmC/(N9TaMBi_D!XJ]64gGFt#B0ohXqq>f!WrN0Plq0k'b:EDL^%f3&\"4FJc5@;0,7hL5'A=^N'+_)^&'c%+RN!7X!u';f#7$,3#H7e-!scLB!s98K\"8dlYE\"`cA-kFT@'A=<7\\fha@)/p6\"`Z>Z9)&'_/E\"`cE\":qXR'>>]1'+^r]&'c%+`Z?-2!u#Y\"\"UBo1&(Vqo!KJ0If)u3A\":&WC!rr<>!!!!$!!!!,z!!!!e!!!\"2\"TSO7\"TSNE!!!!;!!!#+!WW3Z!!!!E!!!#*!WW3n!!!!O!!!#+!WW48\"TSO;\"TSO;\"TSO6!!!!Z!!!#.!WW4C!!!!g!!!#/!WW4]!!!!t!!!#+!WW5\"!!!\"(!!!#.!WW54!!!\"2!!!#*!WW46\"TSO9\"TSO7\"TSO7\"TSPS!!!\"@!!!#,!WW5d!!!\"M!!!#-!WW4<\"TSO?\"TSO?\"TSN1!<<+[!!!#,!WW3B!<<+j!!!#/!WW3([,qAo5m%2o5m%2o5m%3nneDf?>HSk\\!s]\\G!t5PN!t#D<WX]7o!s95F!s8dZ!<WEZ)[caPdMEDr#7Ub;>Il0m!s^+S\"$MM^!s]'&!s<KI#N?!r$NoZ0#@R]:!s8c1-O0`*#CQ[V;$Wg@%mR&q%hB9h\"0_hK%hAa\\!s8c`'*eUE<<E=.K`M8X-3F>P#FPSp\")6iu^B1tO1)C<#1'\\<l#H7_+\")nVQq?7+t!<WE-!t,JAN<'+`'FP!F#I+:3!saAX!s8N.\"pthQ()e5Bzzz!!!##!<<,$!<<,$!<<,$!<<,&!<<,&!<<,&!<<,&!<<,$!<<,$!<<,$!<<,&!<<,&!<<*E!!!!6!!!#<!!!\"n!<<+q!<<+q!<<+W!<<+W!<<+Y!<<+W!<<+W!<<+o!<<+o!<<+q!<<+q!<<+q!<<*d!!!\"t!<<+u!<<+u!<<+s!<<+s!<<+s!<<+s!<<+u!<<+u!<<*(eE-c:T`P;u#GD2$!sbM$!s::d'*DIU-5Qah)$9tFl5^fG>Ikt\"!t5hV!s^C[!sRQk[K`E.-3F>P5Q_fA5IM(A*s[W'!s:8.(BXms!s<KU'D;J4\\H)d70cpc*#Ql\"J9\"$,a)[EVK!s<Ka)n$Ofr;d!&E$$0Z-9qYH'*m%g!s:dj',+XZ',*).'*AJj!<WEeXq1[K#=S^s'H[DZ#@.E6>Il1,!u)gZ!s^C[\")o1uSeQ,_)i=k`M@'G-E$$0n%gQYJ\"#9rt!sd'O!s;cq*>\\f@M@'G)#Ftkt!t$+TWX]8r!<WEg[M^#'#DiKa\"#'fn\"$O(@!ul1u)tj=<9`kJ\\`YejlE\"`oY!aF@r(B[n(#TEkMg)1t7#B9hJ5N3G#*u#e!!scdG!s:8&%g+O6'*AJ&!s;j3%g+0i!t>L?!WrN_$NgJq[K6[E>K-j`!sb(m!s8ei!<WE(!u2@j63$uczzz#ljr*$31&+IfKHK'EA+5li7\"coDejkp&G'mp&G'moDejkoDejkn,NFgn,NFgnc/Xinc/Xinc/Xinc/Xip](9op](9on,NFgn,NFgn,NFgmJm4emJm4emJm4emJm4en,NFgn,NFgp&G'mp&G'mq>^Kqq>^Kqli7\"c;#gRr/-#YMGQ7^DoDejkoDejka8c2?n,NFgn,NFgq>^Kqq>^KqoDejkoDejknc/Xinc/Xinc/Xinc/XimJm4emJm4emJm4eaoDDAmJm4emJm4ep](9op](9op](9ooDejkoDejkoDejkl2Ueali7\"cli7\"c!WW3#l2Ueal2Ueal2Uea$`iCj#A!u>#A!u>#A!u>*1IJi%`]%a'a\"OQ%g2]b#&k4dV?.:>+VWQI&&'8%dM?d8&$?f]c5@;p'HI\\d',1ZR\"0DT4\"31KK4Tbd$%g2]b#&k4dXs4I[)ACgBE\"`cQ%M-i&'D<Xk%g*Ja#7$[u&dng>!XB=d!WsbO!s:^[&-E.B3<K?gE<?:X%g2]b#&k4d^)%<o,88K@&$?fag)4iC&(2^6c5@;0(EF\"g'4tgf\"9SW($NL/,zzz;ucmu$NL/,('\"=7p]:Eqnc]!nnc]!nn-&dln-&dln-&dl3<0$Z,6.]Dz\"lSMD#I+=4!s],7!u2=KqhPGq'+a42&&'8%dM<@r)ACgBE\"`c-)%Y\"1'BTQ@%g*IuYlae,!s^C[!u2=KqhPGq'+`Y-&$?fag)4iC&'bXqc5@;H'-.Sc'*kcDlN@;#j:/j4m0a.r!s98K\"8dlYE\"`cA%hH5p'A==C'+a4N&$?fag)1F4+VVR7E\"`cM((\\\\.'BUP\\%g*J.ncjjPT*,CI\")eEq!<WE=%g2]b#&k4dndl>G,88WAE\"`b^+qMC4'CHWT'+_qm&&'8%dM?d8%uMSBc5@;d&028`'+PBP:q6T3!s:^W\"p5)C$Np/)'F+^B/EHm7!scdG!s98K\"8dlYE\"`cA)\\9(i'A==C'+aXQ&'c%+iYrmK!tu:Tk6/-n#DE3]!se&k!s98K\"8dlYE\"`bf,S/0<'A==C'+^fY&'c%+Z6UG$!u!$9\"Tni3M#mb]'b:EDL^%f3&$cZU\\fha@)/p6\"Q5'qU)&'_/E\"`bB%M-i&':'@R%g*IZ%g)n=9`rE;#IOU8!u2=KqhPGq'+a(=&$?fag)4iC&%3)]\\fha$,7gpq'A==C'+^61&'c%+[LsSk!u!ig#1!OX\"UDjELB7P_YlY\"0!!<9,$4Hn7!!<3$!\"o83z!)rpu!%@mJ!$;1@!;Z]r!'pSb!%S$L!;ccs!;$?n!!!-%!!39'!!!-%!!!-%!+Q!/!'(#Z!;6En!-J8A!'pSb!!!'#!/1CQ!*B4$!;-?m!!TOf!=*TH!s`fJ!s`fJ\"!3()Ta1B\"#B9hJE!HWN(N9TaMBi_`+p[fF-3F>P&+1YIarERM$NgV=>lt1J#7%CJ#?:j.4gGFt#B0nQXqq=3!s<KI#Dsc;rW`\\b'0WW/!s]&G!s<KI#Dsc3,m+6g#7%CJE!HW*,R8#c!tVsE#6G,j!s:]l$NgV=Gln.f#7%CJE!HW*,S0_l#M'_TZ3pa>E!HWN(N9TaMBi`',mX,_4gGFt#6usc!rr<>zzz!!!\"Vz!!!#_\"TSPd\"TSPd\"TSPd\"TSP^\"TSP`\"TSP`\"TSP^\"TSP^\"TSNE!!!!4!!!#j!WW5a\"TSPd\"TSP^\"TSP^\"TSNW!!!!=!!!#i!WW3^!!!!B!!!#f!WW5Y\"TSP\\\"TSP\\\"TSP\\\"TSP^\"TSN)nE0fWnHB!s#71J7'c-uLL^%f;(Q'1CXr885)/pN2c5@/<)&nGQ*>\\es#OquX\"p5)Z!s98S\"8dlYE#TUR*Y5t0)kn^!)].WB&'c%3NZK2W!uiYC'F,\"/l2q+n#IO^;\"\"\"*P!s_g.!u2USqhPGq)].KE&%Wo'c5CR?(Q'FJc5@SH)%Wkg)pT=?)],Li&'c%3iX[%G!ujD;#QrNWE5M_bl50d)\"9S`2M#d\\\\'c-uLL^%f;(\\/+JXr885)%X;%)ql0K)],4t&'c%3rXU\"c!ujD;#QkG>`<M5%$O<p;!s98S\"8dlYE#TUb\":qXR)nmP9)],(d&%Wo'g)4iK(\\RqA^*=Tj\")o1qU)jiJ)B7BJE#TUn+qMs:)u_6+(BYU>l2q+n4h_36\"Uf8W$go94mNc!ERK;[U!s]'b!<])%#Q4Z*!u2USqhPGq)]+55&%Wo'g)4iK(\\T-c^*=Tn-u^+AU'qRX)&r8q*>\\es'EcV`$O=oX\"7$-rW<*/('c-uLL^%f;(U=bd^*=TF(2t3/U*gJs)&rE#*>\\es8u<[8$U*bW!s_f-\"Tni3d/jCP'c-uLL^%f;(R>[EXr885)/pN2NY2lJ)&pR<*>\\es9$RPE$U*bW!s]'.gBRfcq#UX#'c-uLL^%f;(Zkc0\\fi$,,B+S<WWWjH,9,&HE#TV%+V2j9)sS[h(BYUKJf+e$4mE+OQNr0EW<<;*#H7e-!u2USqhPGq)]-('&&'8-U*jn!(\\SUT^*=TF(2t3/jsL\\b)&p.)*>\\es0\\.TV$i9s!!s8eY!s8W?(BaPj#&kLtjr+cA+WJ-?E#TUj$4j9X)ql/?\\fi$H)/pN2L'%t3)&q]V*>\\es4mE+OQNL(eXq;$HklubCT)o7S\"9S`@(BaPj#&kLt_ANle)B7BJE#TV5-P+K?)n#nj(BYUR\"/[.J#GhK_!Wr\\0\"9S`@(BaPj#&kLtjoc4/,9*@)&$?fi^*@S9(WIL,^*=Tn-kFT@)ql0K)]+MR&'c%3g)4iK(\\/XY\\fi$H)%Wkg)ql0K)],Xe&'c%3`Z?-:!uoPeLB?0<$]kDC%\"eZj4mE+O#>nES'FP-lf)k[N#D!$\\!u2USqhPGq)]-X=&%Wo'g)4iK(W%F.^*=Sk-P*d3)pT=?)],e\"&'c%3_B^-<!ujSl(^IMQ#H\\\"/k5nK_c3k!bSH]/u#It!?!u2USqhPGq)]+A<&&'8-U*jn!([_eEXr885)/pN2rYZ6l)&q9IE#TUR'G&J,)u^]q(BYURrrgmm$\\nbo'*en.l2q+n#PeCY!<WT\"\"TniA(BaPj#&kLtV@4!<)B7BJE#TUf*tPq+)ql0K)],Lq&'c%3V@4I]!ujDg\"0Vq7#DE9_dffuM\"p4rB(BaPj#&kLtZ2tQJ+WJ]E&&'8-U*jn!(W$@ec5@S,!Z`'Z)\\UF(#O;Ktd/sIQ#K[/P!u2USqhPGq)].?O&&'8-dM?d@(YTf=c5@S0(`aCp)fQ/megHgcV#pf%#OM]t!u2USqhPGq)].WH&$?fig)4iK(T&/_\\fi$<)/pN2[O)O1)&oFm*>\\es9!/a2cNHDr\"7$0s;$2Cf$O?>+!s;Mh!TX?f!XJ6!!s8N(%OhAX!!<3$!!rW*z!#5J6!\"f22!#>V9!%nBS!%nBS!&ar[!%S$L!$M=B!#Yh<!(?kf!%S$L!#kt>!*K:%!'C5]!#bn=!&ar[!&ar[!.OtK!(d.j!#Pb;!0mNa!)W^r!\"f84!$h[I!$h[I!3#qu!*]F'!#Pb;!&=ZW!&=ZW!5/@4!+u93!#,J7!%J*O!%J*O!7_&L!-A2@!#kt>!:'Ub!.b+M!##D6!!NB'!/^aV!\"f84!#GY9!1X#h!#5P8!%\\6Q!%\\6Q!%\\6Q!'pVc!36)\"!#Yh<!$h[I!$h[I!*oU*!4i.1!#G\\:!&+NU!&+NU!.+_H!65'>!\"f84!0I9^!7:cH!\"o>5!2T\\r!87DQ!#kt>!4Mt/!9=+[!##D6!%7sM!%7sM!%7sM!&OZU!!fOd!=&c1!u2=KqhPGq'+b'V&%Wntg)1F8,88K@E\"`cI,7gpq'>>]1'+_f%&'c%+c41j*!u!ik&-E/V#90*49OS&'!s^gg!u2=KqhPGq'+ad]&%Wntg)1F()ACgBE\"`bZ!Y<Qo'D<Xk%g*Il\".KDm!YbkA!s^[c!tktDJ--$Z!s;!;!nROi%gR(V!u2=KqhPGq'+a@U&%Wntg)4iC&(2^6c5@;\\-QN^\"'*eO?qZHm!\"TSN&!rr<$(]XO9`W?,?NWfC_NWfC_n,NFg3<0$Z+ohTCz\"bu1@#;H;_#;H;_#;H;_=Q9e:%,2$m'a\"OQ'*J,f#&k@ll6?hN+W&iME#01j)@t+2([<4c'*B$t!sA-\"#;lSc'b^]HL^%f7'<WPjXr8,1)%Y\"1(VV,5(DH3=&&'8)iZW7W'E/[Vc5@Gd\"!&$W(V]tU!s9p[#.\"N5!XE9=!u2IOqhPGq(DDB.&&'8)dM<A)+W&iME#02I&.d&((P3#8'*B$qSHAu#!=+G^!s98O\"8dlYE#02e-4d6t(YTaG(DFM*&%Wo#g)1F()Ah*F&&'8)dM?d<';?odc5@Gt-63a%(Hq<nT*#J5!T=+##Eo8q]`A3;'b^]HL^%f7'B1/G\\fhmD)/pB*p'_JW)&M9U*>8Mk#8%'Y\"p`rb!s98O\"8dlYE#01^$kKom(YT`;Xr8,1)/pB*arh5?)&K\"U*>8Mk'FUrFNrfQs!<WE/K`V>Y'b^]HL^%f7';?ib\\fhmD)%XG+(Xa(<(DF)\"&'c%/L'AY3!uDR\\\"0_e?f`;2M#7%@4!s98O\"8dlYE#00+&&'8)p&f7M'=JMa^*=H^(([u\"(YTaG(DE)L&'c%/)BBIn(UaA8\"p55G%g.Id577Ro#7#q`!s8ei!WrN>'*J,f#&k@lnfSIg)&LR9E#01^%1fT[(YTaG(DH'Z&&'8)dM?d<'=o:sc5@Fe\"s\"?Z(D75\\_u^Y-!WrNfnck-X$^:[C!WrNfp(.<6E!m&B!=-^K!s8e1!s8W?'*J,f#&k@lng4mY+W&iME#02U-kFT@(\\/mn'*B$U&Ha*f%g/a2#LNVU!sd?Y!s98O\"8dlYE#02-#nO0W(YTaG(DGpL&&'8)dM?d<'8?T\"c5@G<#osZ](DI8;\"9[?YW<35)!!EiI#T4?Wzzz!!\"&?!!!B,!!!E-!!)Tk!!!r<!!!f8!!!$\"!!\"_R!!\"/B!!)Tk!!#Ff!!\"VO!!!N2!!$@+!!#7a!!!Q3!!%WO!!#Uk!!!T4!!&>c!!$+$!!!K1!!'>*!!$R1!!!N2!!\",E!!\",E!!)3b!!)3b!!)3b!!(UN!!%$>!!)Tk!!)9d!!)9d!!)<b!!%HJ!!)Wl!!!5fjoG_C!<WE/h#RT[#MfC_!sec*!s<KM#F5o+)$9tG$O[%A%0H\\7!ttbU#6PbIW<!)'1'\\<l5M?2M%gQ5>\")o1uc5-_\"!s;cu%jqGa`;p&C8qmcg(C*e>\"$QVa!uD2f!s8f2%g-b]&%W`Daq\"Rf#B9hJ4oPHa*s\\J?!s<KU'D;J4+Thg2U';DME$#Ve+E/P9Z3)<rp),([]`A3;E#0=V*!]%;\"$MMK!uGnm(WHdeN<'+`5ILV8*sY(6\"$QVa!uhJ*!s:dj(DeG8\"2t<HeH#aS0ddV:#I+:3\"!8$q\"%O.0\"%q,Z',Ln=!<WE/eH,gT1RATS\"dTT\\Z3pa>5O&X^#@$U5%g-,?#6SoQ#D*Bio`5-s-OU%T!='2=\"\"+HY/I/BZ!s9/T\")qQK'*Bs\"'*C5s%g*'a!WrO/SgbHX>Ikss!t5\\R\"&&e!%gTWH!s::\\%g-%a(D?lUR0!HmE\"`K)#!]*h',(V)!WrN3)\\]4]>Il1(!u)[V\"\"\"*P\")o1qq?7$)$QCi')Zs<m(EW``hBX<J>Ikt*!t6+^\"#:B+\"#:*'!saAZ!s8eI!WrN=)Zp0Ir;m''!!NrD'Iaknzzz!!!!*!!!!)!!!\"i!<<+5!rr=9!rr=9!rr=5!rr=5!rr=5!rr=9!rr=9!rr=9!rr=9!rr=;!rr=;!rr==!rr==!rr=5!rr=5!rr=7!rr=7!rr=9!rr=9!rr=7!rr=7!rr<c!!!!D!!!#.!<<*k!!!!I!!!#-!<<+7!rr=9!rr=9!rr=9!rr==!rr=?!rr=?!rr==!rr==!rr=9!rr=9!rr=9!rr=9!rr=?!rr=!!!!!Y!rr<\\!rr<\\!rr<\\!rr<^!rr<^!rr<^!rr<^!rr<b!rr<b!rr<j!rr<h!rr<h!rr<b!rr<b!rr<d!rr<d!rr<d!rr<f!rr<f!rr<d!rr<d!rr<d!rr<h!rr<h!rr<h!rr=I!rr=I!rr=I!rr<b!rr=A!rr=A!rr>+!!!\"(!!!#1!<<,3!!!\"-!!!#2!<<*,RcXVU0`qL_0`qL_0`qM4)]&S]8HT&&\\IXZ.SI?hI!s:^W\"p5MD3<K@<)\\W<$)ZrY:70<WM%g)n=*<QBV(B^0/*t&_m#:0HS#7Ub;8-9e5!!!W3zzz!!)!Y!!)!Y!!((?!!)!Y!!(XO!!(XO!!)!Y!!)!Y!!)!Y!!!'#!!!'#!!(^Q!!(XO!!(XO!!)!Y!!!;_k5bga!s8W1V#pf%#7Ub;'cR8PL^%f?)s.D:^*=`J(2t?7\\fhU0)'@uH*?,)&?DR`+!ug>5kQ.+S#;H;_'cR8PL^%f?)tkKe^*=`b'6#$4Xs4Ik,9P>L&%Wo+g)4iO)sSXYc5@_t,97^*+7]F;'*But(B]p'[06Zu!XE9=!u2aWqhPGq*ufe>&$?fmg)4iO)r_D>c5@^],97^*+$]oA$O;@iWrrM0M#d\\\\'cR8PL^%f?)u^?Y^*=`R,S/0<+3kaC*ugq'&'c%7rXU\"g\"!=3;k6)0Q,VfH4!s^C[!sc47!s98W\"8dlYE$$%9%1g/t+4:pD*uk2+&'c%7Q3\\KM\"!9\\k!s8cgW<NG,#MB+[!u2aWqhPGq*ubCp\\fi0L)%XG++6jMY*ug4M&$?fm[O#l7)r_qM^*=`J(2t?7iZSiX)'=kK*?,)&1'cD5!rr]FK*+@@'+=\")T`bH\"#FPVq!u2aWqhPGq*uhp%&&'81dM?dD)u:rnc5@_X)%X;%+5.SC^*=`b'6#$4jpr!J)'A]'*?,)&d/ek'&&SKhK`qP\\#L*;P!u2aWqhPGq*uh3_&&'81dM?dD)sS[Z\\fi0L)/pZ:nfSIG)B[6B&'c%7c5CRC)kmcPc5@_X)/pZ:^*F5l)B[ZNE$$%)'bAS-+20!@)Zq0Fl3$&N#<hc%!t0&mlN<.m15>oA\"#:)p4#.0[\"'<SI!s8e-!s8W?)[#tn#&kY'arM\"q)B[6BE$$%=#nO`p+4:pD*ufM:Xr8D9)%XG++8,eU*uiK<&%Wo+g)1F()BZO6&'c%7g)4iO)s/LYc5@_L)BBb!+$Jlk!sb@tp)Zj7E!u[KN[-AIRf\\KN-e/5\"!sec,!s98W\"8dlYE$$%)\"qSEm+8,eU*uj>\\&'c%7Z3D<g\"!:D*!s8ckp)X;D#DE0\\!sbY*!s98W\"8dlYE$$$f+:l12+/1+n\\fi0@)/pZ:[KR2e)'>:i*?,)&WWB77#O_m&YlOq/#L*AR!u2aWqhPGq*ujbo&$?fmg)1F4+WoDUE$$%)*\"T1j+2/t=*ujbm&&'81L+.'`)hnY0c5@_p*uu:&*sMf\\$VK\\$^BY,n\"1&$W!XFPc!s98W\"8dlYE$$%E!=u=O+0HN$*uh3h&&'81dM?dD)qlGGc5@_H*uu:&+#4'7\"#:8)\"p<-O@06T:\\HN';'cR8PL^%f?)nldmXr8D9)/pZ:SgY,P)BZC6E$$$Z'G&J,+.al$)Zq0I\"$6kqi<@C.!sdok!s98W\"8dlYE$$%a-kF$:+/1-%*uk1s&'c%7l6mYl\"!:*d)$^NSaT;PH#DiWe!u2aWqhPGq*uj&?&$?fmg)4iO)tF\"?c5@_P$lp8h+%jfd#7Ce4\"-Wfh#H\\14!u2aWqhPGq*uioL&$?fmg)1F8,9P>L&%Wo+g)4iO)nljo^*=`n\")o>$c63_D)'?R(*?,)&*qgWW$ZHI]N[+Xj!p9X2!=,G'!s8N*\"UPVL!!!!$!!!!+z!!!#/!!!!:!!!!9!!!!H!WW3V!!!!B!!!!G!WW3h!!!!M!!!!H!WW4)!!!!V!!!!G!WW4;!!!!f!!!!F!WW4[!!!!s!!!!G!WW4u!!!\"5!!!!I!WW5N!!!\"J!!!!F!WW6#!!!\"T!!!!H!WW36!<<+_!!!!F!WW3J!<<+n!!!!I!WW3h!<<,%!!!!G!WW4+!<<,9!!!!H!WW4S!<<,P!!!!G!WW3+o]?/Z\\H)d7#Isj;!sc@;!s::d1BRk&!s9o,\"3giO0`qM42_P7=\"#C#a'a\"PW2`I`Y#<`.kE&/a8\"[P'X1C#?2!sHjL#<)n`!<WEO.g+#s#OMNo!t5\\R!s`B>\"'`Vh'*DJ(*>\\f^Xr85]#>G:&#GD/#\"#:At!s_g.\"$O@?!t0&U$\\g&7I00QVeH#aS>K-j`!sb(l!s;C&dMNKZ[K6sM#CumX\"'u'?\"\"+T]Ba:=6!s9kP!s:7s$NgXA!<WF*!s\\o5V#^Z#8-9e52?s<d#JgEC\"#1/g\"&B:,eH#np!s9hgXTAS0XT8M+0aA'g#MfC_\"'ba.$Nj6.dMNKB%g-MNM#d\\\\D;#lP!@J,_!WrN0blInK0af3.0aBW>#PA*\"\"&>-m_$JHk#GD/#\"'a%d0*>M_-NaUA!WrNh^(DS?>ETdY\"'u'[\"\",GublJ'W!WrNh^(DS;#E8ce!s_6s\"$`Xr.k_.P!WrNi!u!=q0,)S2#MB.\\\"'`Ja2Zm9u,<Gu4_#a]@#7Ub;1'\\Tt#OMQp\"!7mi'*k'1!s:c>&f2?gncKs9?3:uG4mF3n)[D3%!s;j3'*AKq!WrNZ*u>\"ajT5Md5J@^C'3jH*)Zp=r!s8Wa)[\"=c;$55`%r`$i`WgAm&,HGb!ttbAOTP[f!!F;[/Kn-pzzz!!!<*!!!?+!!&kr!!#gr!!#gr!!#ap!!#gr!!#gr!!#mt!!#mt!!#Ih!!#Ih!!\"GJ!!!u=!!'A+!!\"VP!!\"VP!!\"VP!!\"VP!!#@d!!\"GJ!!&Gf!!$O1!!$O1!!#1`!!#1`!!$O1!!!'#!!!'#!!\"VP!!\"VP!!\"VP!!#1`!!#1`!!\"VP!!\"VP!!\"\\R!!\"hV!!\"hV!!\"hV!!#Oj!!#Oj!!$%#!!#t!!!$%#!!$%#!!&kr!!\"hV!!#7b!!#7b!!#7b!!#=d!!#=d!!#=d!!#Ih!!#Ih!!#7b!!#7b!!#Ih!!#Ul!!#Ul!!#Ul!!#[n!!#[n!!#Ul!!#Ul!!#Ul!!#[n!!#%\\!!#%\\!!#1`!!#1`!!#%\\!!#%\\!!#%\\!!#1`!!#1`!!\"tZ!!\"tZ!!#1`!!#1`!!\"tZ!!\"tZ!!\"tZ!!#1`!!\"nX!!\"nX!!\"nX!!\"tZ!!!PCjoG]E!s8cc!s8cc!s8cc!s:4Z56D.m!<WE:1BY]!#IOR7!tms'fDu4c!s;bn#9O%S!uD%EM#d\\\\>Q+d2\"#'fj\"$Npt!uD2b!s;j3)Zr7/$NhJi+!8'?#FPSp\"\"\"*P!tm6hg]7Wt!s;/U.6g0)I00R9l3nUN>KS9;!s_6s\"$c&Z(Dd<*!s9'g!C)kP#Qm-j#E]#h\"$Npt!uhJZ!s:7k3s,^f!s<Ka+/0ql,6P^^&gmdS!>6mbli@>o!s9(F\"$aXL#9a0O&iTo[!^4+C\"$6b(!<WFC4$2:3E'$/H*cO2&Z4Lt:44YP[&H`,@W<<b&!rr<Szzzz!!!\"J!<<+K!<<*P!<<*P!<<+Q!<<+Q!<<,F!!!#E!!!#E!!!#=!!!#C!!!#E!!!#E!!!#G!!!#I!!!#I!!!#I!!!#7!<<*>!<<*>!<<+O!<<+O!<<,H!!!#G!!!#G!!!#E!!!#E!!!#7!<<+K!<<+K!<<,H!!!#G!!!\"J!<<+K!<<,J!!!#O!!!#a!!!!)!<<**!<<+M!<<+M!<<+?!<<+,!!!!V!!!#6!!!!3n`TuYYlb(1#I+@5!s]8;!u2aWqhPGq*uiK8&%Wo+g)1F()B[ZNE$$%1+V2j9+3k?:)Zq/eYlhH=o)o:Q!s98W\"8dlYE$$%e(([u\"+5.SC^*=`J(2t?7l6?hb)'A8^*?,)&nH#ls\"7$1)^^0]<apnYZ!s98W\"8dlYE$$%],S.U6+5.tNXr8Cr,B+_Dp*1*n)'@ud*?,)&q>gi=\"g/XHYm(:4#CumX!u2aWqhPGq*ui?.&$?fm^*@S=)i>jNc5@_@!Z`3^+$Hn;!s`cMlN+.)#Ls\"\\\")nJMXqq>N$3LA8YlOq/'cR8PL^%f?)o<$p\\fi0L)/pZ:WZhu!)'>FP*?,)&E!HW*,S0;f#Pni6R0`t^!XIBZ!s98W\"8dlYE$$%]%hGf]+1<I+\\fi0@)/pZ:p*C6P)B[ZN&%Wo+g)4iO)ql;CXr8Cr,B+_DiZA]6)BZ+#E$$%Y+V2j9+6\"@_)Zq0d^*B*L\"$ct+\"NLO8c31$G$O<4.T*N[I#GhJ(!u2aWqhPGq*uk&)&$?fmg)4iO)hnP-c5@_h)]]k\"+)hGiXqq>F!V6Kt#K[#L!u2aWqhPGq*uiWP&%Wo+g)4iO)nl[jc5@_8+<;C'+)hGiMBiGo#m6Lq&,I:O\\ePJ/#Qk/lZ3pa>#GD2$!sec+!s98W\"8dlYE$$%]!Y<!i+5.uZ*uj>i&%Wo+g)4iO)nm7%c5@_d!Z`3^+2%[_$haX+iXQJ$#Iss>pB;)u,mWQP#Oqit!sc49!s98W\"8dlYE$$%=)@sP,+8,eU*ui?>&&'81dM?dD)nI%#c5@_D)BBb!+0P^N$NgXQ!Mof!!sdce!s98W\"8dlYE$$%=-P*d3+5.TO*uh'a&&'81nd]U\\)r:l3c5@_$$6:&f+\"Zh*#Pnr9I06)C#E8ig!u2aWqhPGq*uh@%&$?fmg)4iO)nHpu\\fi0L)/pZ:dM`YA)'?\"#*?,)&4gGGc#B0nQXqq?!!s9&=]`\\E>'cR8PL^%f?)ibdHXr8Cj,nI^7+3#FB*ui3@&%Wo+g)1F()B[ZNE$$$r*Y6O6+-%3Z)Zq0*iYU2L!sbY-=,R(anH8pr'cR8PL^%f?)jUjB\\fi0L)/pZ:WXTKa)'?R;&&'81g*CVZ)ibUC^*=`R,]FhErWEbG,9QId&$?fm^*@S=)j1dDXr8D9)/pZ:joc4?)'>jf*?,)&e,cHP#HekK#7$,3G.Iae#FZ)bZ4#[r#7&?W\".'%-#7%CJE!HW*,R<iE!s8eY\"TniA)[#tn#&kY'nfeUI)B[ZN&&'81dM?dD)sSg^\\fi0L)%Wkg+1`V7*ujn`&'c%7l6mYl\"!:bD$gRol#HRsb$A/E_#DiWe!u2aWqhPGq*ugLf&&'81dM?dD)pTT;^*=`j%WEL/nc99H)'@-I*?,)&He'PLmLF,k\"9S`2[0?^8'cR8PL^%f?)nI@,Xr8D9)/pZ:g*R?U)'?F:*?,)&4n]ro#7Ce4!WrN0f`hN\\'cR8PL^%f?)qku:\\fi0L)/pZ:`Y8rt,9QU]E$$%5&.d&(+3#!8)Zq0*p)X;D#D!*^f)l83#6P&C)[#tn#&kY'[KI,T,9P>LE$$%i,S/0<+8Q3_)Zq1$$OcY0g]>e+!s8e-#6P&C)[#tn#&kY'Xq_JY+WnuI&$?fm[O#l7)ql2@\\fi0L)/pZ:c3Flk+WnuIE$$%q&.c>q+5.TO*uj>E&'c%7g):tN\"!:aM'God25Qg<U]*:mm(^C.+Z3pa>#JCBFRfs&i#6P&C)[#tn#&kY'Sf/-N+WoDUE$$#K&&'81nd]U\\)ic$Oc5@]R*?,)&@+HM,_@Qs+$Np,(#GDD*!u2aWqhPGq*uj>_&'c%7g)4iO)qGH/c5@_d*??($+\"!0U!s8eE#Qk/D)[#tn#&kY'RL0SN)'?R;E$$$N+V2j9+.<NW)Zq1$mf`s!(C,Wu!s8ei#Qk/D)[#tn#&kY'eeo\"0+WoDU&&'81dM?dD)n%+)c5@_<,B+_DZ5=+t)'=k@*?,)&4gGFt#B0nQXqu&h\":'f0l2djd\"1&+8SI#B#'cR8PL^%f?)hnV/^*=`J(2t?7Xr.ba,9QU]&%Wo+^*@S=)m0>Tc5@_,)''Xu+*4^q\"7$#i!UU!l!sd'W!s98W\"8dlYE$$%Y'+`A++2/t=*ugpo&'c%7iY*=O\"!;KK!sbtF#K6`H!se?&!s98W\"8dlYE$$%A\"qSEm+7]n\\*ugXt&'c%7ap&k*\"!=0:rW`]!*X@f7!s8dn$3LAF)[#tn#&kY'p)\"=S,9P>LE$$%Y\"qSus+-H[G)Zq0FZ3pa>,fKoh!sc@D!s98W\"8dlYE$$$R+qMs:+2/t=*uioX&$?fmg)4iO)s.S?c5@^Y+rqU)+)p6F#Dsc3klUG[!sdop!s98W\"8dlYE$$%u\"qSEm+3#FB*uicD&'c%7rWXA^\"!9/L)&!)WeH#aS#Difj!u2aWqhPGq*uge!&&'81p&f7U)ibRBc5@^q-QO-.*tPXb!s]'2!s8N'.f]PL!rr<$'EA+5z!WW3#/H>bN*rl9@K`V5S5l^lb.0'>JL]RPVrWE3$rWE3$=TAF%2#mUVJH>fOD#aP98,rViL]RPVP5kR_;#gRrJH>fOV#UJq=o\\O&K)u#QrWE3$rWE3$!X/Q(!X/Q(^An66C&e56K`V5S!!N?&!!N?&gAh3RG5qUCIf]TMnGiOhNW9%ZLB7GU*ru?ARfEEgK`V5S3<9*[Y5eP&JcYoP\"pFu,\"pFu,#R(2.#R(2.#R(2.CB4D8_#OH8L]RPVK`M/RbQ%VCL&q>TRfNKheGoRLK`V5SXT8D%kl:\\`L]RPVeH#XMq>^KqK`V5S$j?V2$j?V2qZ-Zs#6=f)KE;,R&HVq4%flY1L]RPV+T_WD(]aU:L&q>T1BIOV-34)HJ-#]N:BCLr1'%@TJcYoPB*&&56id8fK)u#QMZNkY9`Y4oKE;,RSH8ck=9/C%If]TMZN:+,@0$?.L]RPV`<$#>B`S26K`V5S#g291#CupY!saAY!s8dZ!WrOD',048E\"`nb-ZB_4Z4Lsg'@n<\\!uD%ER/mBl*toFm7h5\\(4h<$D'*esK!tU+e(ZlJG)Zu0&8rb>:)[BdR\"'\\A6!sc(3!s9JI!tRQg*Wm&\\D$'lEOouF##=S^s#Qk_B0aA?o-3F>PE\"`oE!aD*/(BXnf!s;c])&iZ^RMHtI#Isj;\"'aIs)Zp>]!<WEC%g*2Dar(]l#?_-2&%ViZMB3![!s:^[*Wm2`W<!)'E#0>M!XFD[!s:^t$NgW.!s:dj',(VE!<WF.g)1t7>IFk`!s^+S\"$N4Z!t,@q!<WE0!t,29h#RT[-OU%$!=/8u!s92=!t.8t$Ngc$eccEh#LrhW!saed!s9'o!=-1`#L*8O\"#'f^!seW&!s<EOiWu4_!!\"DIzzz!!!<*!!!<*!!\"kX!!$U6!!$U6!!$a:!!$a:!!$m>!!%$B!!$s@!!$s@!!$O4!!$O4!!$U6!!$U6!!$U6!!$O4!!$O4!!$a:!!$a:!!$s@!!#\"Z!!\"5D!!\"eV!!$O4!!$O4!!$O4!!$g<!!$g<!!$U6!!$U6!!$U6!!$U6!!$O4!!$O4!!$@+!!\"eT!!\"eV!!$^5!!#1_!!\"_T!!$C0!!$C0!!$C0!!$C0!!!>%joI@F!s9nU\"\"=Hq!s9iSRL/$`!s8o5-OU#N#:0HS1'7md#8%%?#;lSc-3F>P'FP!F#:T`W4n]Eh$ZHI]RK4$3\".TAs/HZ(`$PNUIB`eGm*t&0TdMEDr#@R]:>HSk\\!s_6s\"'b$u'*AJB!s8l<#HA8<\\gJ!j'FP!F#:T`W!!kFn*<[ZC.3T6&!!!'#!!%ZQ!!%ZQ!!$U2!!!B,!!!?+!!'n:!!%ZQ!!%fU!!%`S!!%fU!!%fU!!%lW!!%lW!!\";F!!!o;!!(aR!!'M0!!'M0!!'M0!!!5%joG]Y!s8d\"!s8d\"!s8d\"!s9kP!s;c=-OU#I!t,34!s\\o5'a\"Oa$[DgZ*<QCJU*1<T8-9Y1E\"<Jj,sRCm%hB`i%g*mU$PPH,\"!oi1!s:^O+p/2X<<E=dZ3paF#;lSc8$)sf\"m?.piXHt3#B9hJ+XIp0#CumX\"'u'G!s`NB\"$aL3',Lm^!s8c[!s8N''`\\46zzzz-34)H-34)H-34)H*!$$>*!$$>*!$$>*!$$>+9;HB+9;HB*<6'>&c_n3NW9%Z!WW3#*!$$>*!$$>*!$$>*!$$>kPtS_1B7CT+92BANrT.[#c$M_#@.E6#71J7'b:EDL^%f3%uM>;Xr7u-)/p6\"c5@/<)&%lI*=i5c#@5d_!s`*6\"(B(Kjpes.#;H;_'b:EDL^%f3&)n34^*=<>(2sotl6?hb)&)!B*=i5cIpE-Y&dnfC!=*<@\")nJMRK3Xf!s:^[&-E.B<<E=M!s8W>#6P&5AHN#7!!WE'!!<3$!\"&]+z!4W\"/!#Yb:!##>4z!8[kZ!8[kZ!%e0N!#kn<!:Bmg!!SSK!=(%U!s^7W!s^7W!s^7W\")HEhh$V.,'F+^B-3F>PE!HW:!>5bBPQD()!s:^[&-E.B*<QBD!\"/c,zzzz!%%[G!-eYI!-eYI!-eYI!.\"eK!.\"eK!-eYI!!AVN!='2=!s]D?!s]D?!s^sk\"#^Ad\"!@[J$RZ;a+U8GY\"\"\"*P\"%8peOq\"VuE!m&B!>5nFGR$).!u)+F!s]tO\"$Q>h!t,>_!s8N)'I=:jzzz!!!u@!!!'#!!!u@!!!u@!!!u@!!!u@!!')#!!\"&B!!\",D!!\",D!!\"&B!!\"&B!!\"&B!!!.gjoI@F!s<KM#LXFo%0H\\[$Nh+K0`qM)!s8X=o)\\h\"SHL;N!u2&$!s;cE-l2tl!tPJ=*<QC.hBr[A#:0HS%u)2;g)1,1!s8N'$NL/,!WW3##QXo*#QXo*$3:,,$3:,,$3:,,8,rVi%KQP0%KQP0'`\\46%KHJ/L&_2R&-2b2#288A#N5sk!s],7!u2m[qhPGq,9Md_&$?fqg)4iS+3k`7c5@ja*$$+',7!06UBL`)i<]Sg-3F>P#;H;_'d!PTL^%fC+6!nDXr8P=)/pfBl6?hb)'e,R*?PA.4n]r+\"qLrq\"9S`2<<E=<*s;Cr#&ke/dNf@;,9tVPE$HI)((\\\\.,LRhX*s3a5.0BYWFTV^\\*s;Cr#&ke/V?%4A,9t2N&$?fqne#gc+1;mpc5@k(!?E6a,Kg,A)6X,E#JgWI!sb@t!s98[\"8dlYE$HIq)\\9(i,MF#S,9NKZ&%Wo/g)1F()C*rRE$HIA!Y<Qo,Ouco*s3`NZ4!!'$ZHI]Xqq>Z#kJ:j!=.!Q!s98[\"8dlYE$HIu!tW*j,LR><\\fi<P)/pfBQ3\\#H)'b^U*?PA.E!m&V(U!kA\"9Xtk#PeB&!u2m[qhPGq,9N'g&'c%;c5CRG+-mWP^*=lV,]FtMOp2H2,9umaE$HIE,7hL5,LR?H,9NKt&'c%;Q5(D^\"!bhe$Oa*R&+1\\Nq@C:@Z3paBE;'JCXqriF!s8eE!WrN>*s;Cr#&ke/\\f_Np+X>8ME$HIQ+qM7.,MF#S,9Q1i&'c%;\\f`\"8\"!]t7$Nm^?#PA*\"Ns>pW!WrN>*s;Cr#&ke/nfSIW,9tnfE$HHn\"qS9g,L.0G,9OoJ&'c%;RKacS\"!]t7$NmR;E!m&V(N9`iMBiG/\"p4r4T`YB!'d!PTL^%fC+7^`h^*=lB+E/PIW[/1e+X>\\YE$HIe!Y<Qo,H<%1*s3`lg)1Ru#,)(O)&EA[E<?:Jd/sIQ'd!PTL^%fC+/TAUXr8P=)/pfB`[;;\")C*rR&%Wo/g)4iS+.<rU^*=ln%WEX7p(e1a)'bRc*?PA.ncA/'$ap(!Z4$O2$O>&^_ZY`!#E8ig!u2m[qhPGq,9Oc?&$?fq\\fl#;+4;&<c5@kD)''e$,B+12\"ni!&SHArr#I+C6!u2m[qhPGq,9MXH&%Wo/\\fl#;+0HOnc5@j]#ot)i,<b`A\"/c>.[0?^8#LrqZ!u2m[qhPGq,9Qn&&$?fqc5@/,,9uahE$HJ(#S4'V,MF#S,9Q=g&'c%;c5CRG+8-0TXr8P1)%XG+,Ou=`,9Oo.&$?fqc5@/<)'dEEE$HJ(\":qXR,L.0G,9Le6^*=lr\")oJ,OqA5M)'dEEE$HI=%M,]\\,L.0G,9PVG&'c%;rWF5`\"!_amqZj8?E8Lg,MBi_D!XlF;4gGII!=NjJ$a(:b/)pkl,QdrMirQRhJcW.b!t0&U$a(:b$gRhN,cUmr,237/*^-e:!t,@Y!<WE/nHB!s'd!PTL^%fC+4:Q.\\fi<0+V2j9,MF\"GXr8On-#b(Nh?=G$+X=QAE$HIM+V2.-,MF#S,9Q=a&'c%;dL7-<\"!^'0MZs+`9'R6$UB_$h#m83N&+V\"SOq\\/W\"p4r4\\HW-<'d!PTL^%fC+2/9sXr8Or+V2:3,MFD^,9L)\"c5@k@&02hp,F8EA_Z]Z7#FPf!!sdch!s98[\"8dlYE$HI=*Y5Cl,MF#S,9Nd&&&'85g*CV^+6F%Dc5@kP)/pfBg(k4E)'cj:*?PA.4gGHb\":Ke^$Oa*RE5MkfMBiGO!s8W1SHf6!'d!PTL^%fC+6E_;^*=lB+E/PI_@I1&)'b\"L*?PA.>J;<q\"2FrO,8UFejTbki#K6oM!u2m[qhPGq,9PVX&%Wo/\\fl#;+0H:gc5@k\\)BBn%,<u>Edf]od#Qk/6km%:m'd!PTL^%fC+5.qM\\fi<P)/pfBNYW/:+X>\\YE$HIM#7o)t,MF@_*s3`l^*=T[!XJ)r\"1JL?Pm@Ho'd!PTL^%fC+5/(QXr8P=)%X;%,MF#S,9NX#&'c%;ne)rb\"!\\?Q*=K:V#O)<]#Hn5%c3+Lc#>kR*#K6rN!u2m[qhPGq,9JfSXr8P=)%XG+,LR?H,9Q=^&&'85g*CV^+2/a+c5@kp$lpDl,GP8I$]64Z!KdZR\"To#&#Qk/D*s;Cr#&ke/p&ko?,9uahE$HI1$4kE\",PD6\\*s3`-egCig*='7Z!s8dr#m18E*s;Cr#&ke/L(t6%)C*rRE$HIU)%Y\"1,DHpR*s3`NZ4$+'$O=3K!s8eA#m18E*s;Cr#&ke/edN(l)C*rRE$HI=,nJ9=,Q88q*s3a,$Oa*R#Or)?#6PR\"%dXRS#7'>s!s98[\"8dlYE$HI5$kLW$,JGCA,9P&:&'c%;[L=/u\"!]^Z\"p4rT#6U@p#Dici!u2m[qhPGq,9NX.&&'85rY,mS+X>8M&'c%;c5CRG+.aSc\\fi<D)%Wkg,MF#S,9Nd'&'c%;c5CRG+6it>c5@k(*??4(,?(oP#I5aD:BU=m'*DIJ!s^7W!rrB7$nD;X!!<3$!\"&]+z!$2=E!#Yb:!%%[G!#l\"?!)ERp!&FTT!\"oA6!,2E5!'L;^!#Pe<!.=hI!)*@m!#bq>!&b#]!&b#]!&b#]!20Am!*T@&!#bq>!4Mq.!+u93!##G7!7:cH!-8,?!#l\"?!9jI`!.Y%L!#,M8!%J0Q!%J0Q!!`N)!/ggW!#l\"?!#Ye;!0dH`!#Pe<!%S'M!3lM(!#5S9!%\\<S!%\\<S!%\\<S!%\\<S!%nHU!%nHU!%nHU!%nHU!-J;B!6Y?B!#Pe<!%%mM!%%mM!1a,j!7q2N!#Pe<!3lP)!9O7]!#,M8!7(ZG!:Tsg!#Pe<!94([!;QTp!#l\"?!;-?m!!E<&!#Pe<!\"/i.!\"K#0!\"oA6!&b#]!&b#]!$_OF!#u\">!\"oA6!':5^!&joY!#Yk=!'UA_!-82A!'gPb!!*'\"!$2=E!/1IS!)`gt!\"]54!\"$4\"!=.us!s8eq#6P&5m0<^qE!HW.!D`q&_$C8t!s:]t-j']n#7')uE!HXE%WDXXZ4I6M!s8e!#6P&=U)\"Q>+[*+M!uGnm(Xa-*5m%3RQ6R1^#QkkF4oPHa)bRgT(E3UE!<WE<)Zp1*JgLR=#E8`d\"'u'O!s`fJ\"'`Vj-NaT^!s;/e,T@ggrZ_La#GhG'\")o%mdMN3D!s:d%'H7tr<<E=f[K76e#AF8BE#TUr%gRdh!s:]l)Zpl]I00R9`W?qu*t'.m*s3Gq2]Dk$#!K7\"!t,@Q!<WF.\\g8!l#MB+[\"$c&Z$O[3Q!<WEG$O[%Y!s]Ju#6Tql?3:Q;5K3a4$O=oW!s:^c,6J/U[/g@3-3FJT5DC\"&-O6%@!s<Km,G#)EM#mb]4cU6Z-O6IL!s8f2-NaVD!<WEO-Ni01#H\\%0\"'^X30*>M_-NaU9!WrOD-R[1@#PeB&!sc4=!s;0(-lX65klLqhE#Taf\"^;`a!u)[V!sbA#!s:dj'-daM!s8XE+!7p>#PeK)\")o1u`Wc\\8\"9S`hZ5Wlj#E8ff\"$Npt!ujJi$l^-idNp+?#DiQc\"$$H\"!saYb!s;c])(u'saT;PH#E9#l\")oJ0dMQpJ,K9omh#mf^>ot:5#I+=4\"$`de)]KD7\"#pOJ\"9S`?)Zp1*p(.<FE#Taf\"UD^C!s;b^)BT%q)Zp0Iq#UX#5Q_ZA9#:iQ+$HnK!ul1u)q#Q.d0'ORE$$1A#&kY+[O=;Y)$;+&,9um`>M9rB\"'b=E.g$$-!s8XE.kB$bE%<HY#&l(C_?^C3\"Tnj5!uh=I_#siB(E3GY#H7h.\"$Nq/\"\"OWP!s8WgJgLR=#K[)N\"$Q>h!uhKU!WrNhL(P4@#H\\(1\"'`Vj-NaUm\"TnjG)]PLQ#GD5%\"$Nq/\"!7c!\"TnjG)]Qd$E$#n9\"p`NW!s<Ke,Jj_*,9ub(>F$T`!sb4s!s:^+)$:t\"+!:1X#N5^d\"%p!M)]o<Y\"9SaF+!8oJ5ILV8*s]=Z!s<K])q#Q.f`D6XE%<I$&I6D[!s:]l)Zq#aN<KCd<s&[04gH\"/)fQ`8dMN5&\"TniiZ5Wlf#LN\\W\")o1u`Wc[U\"Tnj5\"!7V;Sg56s#I+C6\")o>(dMN5F!s8WgSf\\%NE#0=r-jP_9!s;j3)Zt$u)n%/6)]SVn?3:iC#MB7_\"$Nq/!u!nR&ebo`Ka%V]E#T>9(^H<1!s8[c#o=6[T`tT$5ILV4)dC;d,6J24\"Tni3bm\"7P&$@3'^*<m=#Qk/T)hA%m#GhS+!sb@t!s<KY(Xa.>(Dk'q5Mdb((L)nI*s2bu\"p4rjZ5Wl^#It$@\"'u'G!sdWd!s;=8\"-!TlXU#\"2-Q</I#mZ\"d!s:]l)Zq/f!uh=IjTYeh4dI5n)[Ga7!s8dn#m19K#7')uE!HXI!XGP,!s<KI#EAg\\#6VdJ#H\\45\"$O4D!s]'b#6P'I#7%OG#E]5n!sdog!s9kP!s<Ki,J!tp`Wk6)-O6IP!s:cr![B&taThnM>NuYN\"'u'W!tVO\\-b^f1XTek0-O0aY#7'o,!s<KI#G))$!s\\o5f`qT]4n]Eh#7'2m!s8eM#Qk/lZ5Wl^E#0>M%:BhcN<oiP#Qk0J'+a(3#PeT,!sec1!s;U,#6P4I#Qk/lAciig(Dl3NDV>u1#T!`Z#Qk/lp(.<BE#0=^\"VUt?(C-K:!s8eA#m187m0<^q%]flR$3(/9#6Tte:Bpt>#OMNo\"\",GuXTf$t#Qk/n^(MY<>P]^#\"'u'W!sd?^!s8eE#6P&6!uh=i)Zu'+#Di`h\"$Mqn!uis:%g*(,#Qk/6q$$p',mT84!sb(s!s9n]\"-!UMZ5WlZ?k3p1#m^80!s<KY(WHXaXU,(3E#0>-#]LRrXs.HoJfTgW#K6uO\")o%edMN4c#m187[0?^8!!*.ezzz!!!!*!!!!-!!!!9!!!!c!!!!>!!!!3!!!!D!!!!i!!!!i!!!!i!!!!k!!!!P!!!!>!!!!G!!!!q!!!!q!!!!c!!!!c!!!!k!!!!k!!!!m!!!!m!!!!k!!!!k!!!!c!!!!c!!!!q!!!!q!!!!q!!!!q!!!\")!!!!\\!!!!:!!!!O!!!\"G!!!!m!!!!J!!!\".!!!\".!!!\">!!!\">!!!\">!!!\">!!!\".!!!\".!!!\"B!!!\"B!!!\"@!!!\"@!!!\"@!!!\"@!!!\"2!!!\"2!!!\"2!!!\"2!!!!a!!!!a!!!\".!!!\".!!!!a!!!\"@!!!\"@!!!\"@!!!\".!!!\".!!!\"2!!!\"4!!!\"4!!!\"F!!!#R!!!\">!!!!_!!!\"@!!!\"@!!!\"B!!!\"B!!!\"B!!!#h!!!\"J!!!!R!!!\"@!!!\"@!!!\"@!!!\"@!!!\"2!!!\"2!!!\"2!!!\"2!!!\"@!!!\"@!!!\"D!!!\"D!!!\">!!!\">!!!\"F!!!\"F!!!\"D!!!\"D!!!\"2!!!\"2!!!\"D!!!\"D!!!\"B!!!\"B!!!\"B!!!!R!<<+k!!!![!!!\"B!!!\"B!!!\"D!!!\"D!!!\"D!!!!j!<<,!!!!![!!!!q!!!\"#!<<,)!!!!R!!!\"D!!!\"D!!!\"D!!!\".!!!\".!!!![!!!![!!!![!!!\"A!<<,;!!!!=!!!![!!!![!!!!Y!!!!Y!!!!Y!!!![!!!!u!!!!u!!!!q!!!!q!!!!a!!!\"k!<<,Q!!!!?!!!#,!<<,Y!!!!;!!!#<!<<,d!!!!9!!!!M!!!!s!!!!s!!!!s!!!#Z!<<,n!!!!N!!!#f!<<-!!!!!7!!!$!!<<*'!<<*<!!!!S!!!!S!!!!2!WW33!<<*A!!!!M!!!!9!!!!O!!!!O!!!!O!!!!N!WW3?!<<*N!!!!\\!WW3F!<<*<!!!!S!!!!S!!!!W!!!!W!!!!W!!!!W!!!\"!!WW3T!<<*B!!!!-M!4pFh$F/c#71J7'cR8PL^%f?)i>UGXr8D9)/pZ:c5@/<)'=_U*?,)&#Mf^X\"p5+d#m187/HZ(i)[#tn#&kY'ee8Rs)B[ZNE$$%E%M-i&+4_)G)Zq/eh$Kt_\"%GBN!J:dc;$-n8)[#tn#&kY'[M9=U)B[ZNE$$%],S.$r+2/t=*ujV`&'c%7[M9f%\"!9\\k\"5<h]%u(e]#Ds]1\\H;p9#CumX!u2aWqhPGq*uh4(&%Wo+g)1F8,9P>L&$?fmg)4iO)tFONXr8D9)/pZ:MB`YW)'AD\\*?,)&;\\/I#\\eP#BN<6Ef]*ASK!<WE=)[#tn#&kY'iZSiD+WnECE$$%A+:l12+8,eU*uk2+&'c%7iZT<]\"!9\\k!s?:?V?-B3!t,@i\"9S`2jT,Gc'cR8PL^%f?)ibC=Xr8D9)/pZ:\"qS9g+5.TO*uk2-&'c%7NXd'K\"!9]\"*q':@#Ls\"\\dffu=!WrN>)[#tn#&kY'Q5'qU)'?:5E$$$j#7o)t+-mW^)Zq0\\.g+oO#DiQc!sc48!s98W\"8dlYE$$#;&$?fmg)4iO)j1C9c5@^a&fhnn*srY`jr\"ES#fcuK#MB.\\!u2aWqhPGq*ugLP&%Wo+^*@S=)nm7%Xr8Cr,B+_DdK'm()'?R3*?,)&&(W-.\"4@H<l2q-l\"qU,I#ML%#9`kJ&N<97b'cR8PL^%f?)nI%#Xr8D-)/pZ:neht@)B[ZN&&'81dM?dD)nmR.c5@_8*??($+)hU/N[0hiJHbWL!scLA!s98W\"8dlYE$$%=)@sD&+2/t=*ujVc&'c%7`Yoj:\"!9\\k!sAE)#IO[:!sdce!s98W\"8dlYE$$$r$4j9X+3kaC*ui3I&%Wo+g)4iO)r:l3c5@_$$6:&f+)hVF\"HF`4XTels!XF\\f!s98W\"8dlYE$$%%)\\9(i+5.TO*ugXf&%Wo+g)4iO)q#W8c5@_,)]]k\"+&`un\"gTN]nHoAj!XH7=!s98W\"8dlYE$$%m$4j]k+5.SCXr8D9)/pZ:\\f)+))'=SC*?,)&&%WDZg)1.K$e#-o!XIZe!s98W\"8dlYE$$%)*\"Tb.+4:pD*uh?a&'c%7nfJkk\"!;Ii$]ZKd!J(OZ!saM`!s98W\"8dlYE$$%A*tQ(1+0lW#*uiK+&$?fmg)4iO)tG-_c5@_@,TRg+*srM\\\\eKW-\"6LI+r<=bS#IO^;!u2aWqhPGq*uf).^*=`J(([Pd+5.TO*uh3h&'c%7p'r)^\"!9\\k!s8d\\!T='O\"p5+d\"TniA)[#tn#&kY'dL6Yh)B[ZN&&'81p&f7U)r:`/Xr8D9)%XG++8,eU*ui'$&$?fm^*@S=)knDb^*=_S.1a]A+5.TO*uge\"&'c%7U)tBp\"!9%O!>>i5XqC7+$S1KEZN1<h!VRS4\"UbQl!s8W1Ym(:4'cR8PL^%f?)nI@,Xr8D9)%XG++0lW#*ugLf&'c%7\\gAF:\"!:;LirQ_*#I+=4!sdK`!s98W\"8dlYE$$%Y+:l12+5.tNXr8D-)/pZ:^(:h#)'@i\\*?,)&W<!C=\"cai5I00QVJHl8Z'cR8PL^%f?)s.55Xr8D9)%XG++0lW#*uj2L&%Wo+c5CRC)qku:c5@_d\"!&<_+);\\!#-oXB!tu&7c3jmC!=,k1!s8e=#6P&C)[#tn#&kY'[L*PZ,9NX-&%Wo+c5@.q)BZ[<E$$%-%M,]\\+1<I+^*=_S.1a]A+5.TO*uioC&%Wo+g)4iO)i>.:c5@^a+<;C'*sredZ7)XP`s+I1?\\00a\"8`3+JHu@Q!=+;a!s98W\"8dlYE$$$^-kEm4+5.SC^*=`J(2t?7Z6^%,)'A,R*?,)&4mE+O#7oMs#FZ?_!O2e1ZNCH;#Qk/D)[#tn#&kY'RNi?S+WoDU&&'81dM?dD)i>1;c5@_P-64$-+$]oA$bcYH#m9o*#MB@b!u2aWqhPGq*ug@L&$?fmg)4iO)j29RXr8D9)/pZ:l3@jF)'>\"J*?,)&;]\"m,Z7#t2\"ig]I#DEHd!u2aWqhPGq*ugdg&&'81Z5%=#)tF+B^*=`*'lY66Q2qNA)'>Fe*?,)&irKYm\\eNct'*IA7#IOd=!sc4?!s98W\"8dlYE$$%u&J)T#+/1-%*uic>&$?fmg)4iO)ho(<c5@`'&KMem+7fNY\":#;]!ttbAi<]Sg'cR8PL^%f?)sRP:Xr8D9)/pZ:ap&Bj,9QU]&%Wo+c5CRC)u:B^c5@_h\"<AE`+$Jlk[fm$3!VRQ:Wr`O^!s8W1PmRTq'cR8PL^%f?)qGW4Xr8Cn+`JMBc6Nq')BZC6E$$%-#S4Ki+5.TO*ufqR&%Wo+g)1F()B[ZNE$$%Q+qLgp+3kaC*ufqY&$?fmg)4iO)r_&4c5@^Y+rqU)+$K<=2[aR4Nrn;B>Cms+\"p8(]$f;'h>H/e^7gH.%hZj)]#PAE+!u2aWqhPGq*ugLi&%Wo+g)4iO)kJDfc5@_X)%X;%+3kaC*ui35&%Wo+c5CRC)o<7!c5@^q-QO-.+$d^E'Cu?!l50cX\"UD.;\"60CeYmUX9'cR8PL^%f?)nmL,\\fi0L)/pZ:RMcXI+WnECE$$$j,7i';+.=&f)Zq0Fl2q,!#LrkX])`/m$NgJG)[#tn#&kY'eclZ!,9QU]E$$%-*\"T1j+5.TO*ujnt&'c%7ecm-6\"!<s4l2q+n#E]Aj!<W<&$7,ZP!!<3$!\"o83z!9aC_!%@mJ!$;1@!!iW+!'pSb!%\\*M!!NE(!*]F'!&srY!!<9&!-8,?!)*@m!!NE(!1Nrg!*'\"!!!*-$!3H5$!+,^+!!WK)!\"K,3!\"K,3!\"K,3!65'>!,_c:!!33%!8dbV!-\\DC!!r],!:^$h!.k1N!!*-$!!`N)!0$sY!!NE(!$)(?!1*Zc!!r],!&4KS!2';l!!<9&!(-be!3?/#!!33%!*]I(!4Dk-!!NE(!,hl<!6>-?!!*-$!!EE)!!EE)!!EE)!1<if!7_&L!!*-$!3H8%!8dbV!!NE(!5S[9!:9ad!!33%!8RYU!!!$\"!!<9&!!<9&!\"/f-!!E?'!#Yh<!#5M7!\"&c-!%e6P!$D:B!!*-$!(-ef!%\\-N!!<9&!*]L)!&joY!\"&c-!-&&?!(6hf!!*-$!/gmY!*fO)!\"&c-!4r:4!,DT8!!NE(!8.DR!-SAC!!WK)!:Ksh!.Y(M!\"&c-!!n_M!=-^I!s8c7!s98K\"8dlYE\"`b>*\"T1j'A==C'+`A+&'c%+MB!WI!ttp]!P\\X;#KZuK!s^C[!u2=KqhPGq'+a(8&%Wntg)1F8,88K@E\"`c-%M-i&'B0WF%g*KA!Qb?EY6G5/!s98K\"8dlYE\"`b^+:kUn'A==C'+aLH&'c%+WZW;m!u!i'$hj`.E!HWN(N9TaMBiH&!<WE/I00Qd%g2]b#&k4dap8Nh+VWQI&$?fag)4iC&)n*1c5@;4!Z_dR'6\"0]Xqq>:!RD!0#GhG'!u2=KqhPGq'+_qm&$?fa^*@S1&)JE>c5@;4&fhJb'6\"2[#)XZ:mNVtR,6ppF!sd'O!s98K\"8dlYE\"`cU!tW*j'A=^N'+^Z;&&'8%p&f7I&\"Wk6c5@:e\"<A!T'=%YE$NgY'!=&k4(C,Wr!s8f,!<WE=%g2]b#&k4dg)U^<,88K@E\"`bV$kLW$'BTfG%g*IU\\cN+s&c)O!!WrN0T`P;u'b:EDL^%f3&,I[b^*=<b\")nna^'bIc,88K@E\"`cU,nJ9='Da*t%g*K;!O<(8#Eo2Q!s8W1blRtL'b:EDL^%f3&%3Vl^*=<F,]FD-rYuH[+VWQIE\"`bf'bAS-'@J!D%g*IUrW`\\j$9b[&!s]#8#Hek^#7$,3&(Vp0\\e$1j\"1JL?M$!h^'b:EDL^%f3&)IU'Xr7tf,B+;,qABgH)ACgBE\"`c)(_<bf'>>]1'+`)$&&'8%g*@3S)&'_/E\"`c-)@sP,'@IX,Xr7u-)/p6\"q>q2Q)&'S!*=i5cE!HW*,S0_l#D*(AZ3pa>*;9UAXqu$^UBQN#&+V%(#PJipZ4\"PR#CLg_!<WSo!s8W?%g2]b#&k4dSdH\"2)ABh0&'c%+^*@S1&%2WPXr7u-)/p6\"g'&#4)&'_/E\"`b.&'c%+SdHJK!u#Y*\"R?)k(NA+0#Dsc3aTC?(!s[$QfEJG\\!!!N0!!!*$!!!Z4z!!\"GJ!!\"&?!!(jW!!#4`!!\"bS!!(gV!!$X3!!#1_!!(aT!!%KK!!#Lh!!(jW!!&,]!!$7(!!(mX!!'V2!!$F-!!(pY!!'t<!!%*@!!(aT!!'M4!!'M4!!'M4!!'M4!!'S6!!'S6!!)`n!!%iU!!(mX!!!1_k5bek!s98K\"8dlYE\"`cU'bAS-'A==C'+_f%&'c%+p(\\SY!u\"NJg'S((#7$D@#Isj;!s^C[!u2USqhPGq)]-4)-m,<#dMtXWl`147E$HU=#=J[[Ws0qj-RZ%t#Ql:R<?iab+YP&b3aEgP*rmB)c6u[7+4^rpXr86$-m,<#dMtn)M@Qp10-_^-'3u\\)*rmB)U(C<H+-mj<^*=R=E#TV=%M-i&)nm+/(BYUVOTF>E!u2=KqhPGq'+_f\"&$?fa^*=0\"+VWQI&&'8%p*FYk&&&hjc5@;p-63U!'1iE6g(&i<\"9/Ss\":)U@!s98S\"8dlYE#TV!%O`Er'[dsh\"2h_U,B+kPmK>o[l`14;E$m$q(ISAkWs1(n.k@b'#QlFV.jq>#-RU8DnGuj_$RZ$P-Nj/F>BV@r>KRC*\"%36Pn,k=_0/(Hd>HSu&!seu^\"$cr%,@)B9*rmB)^*Zi%+9!$J\\fi\"7E#TVe$kLW$)mTqo(BYT]YlY#_!u2=KqhPGq'+Yul\\fha@)%XG+'@IY8'+_AY&'c%+NY3?C!u#VY#I5ao.0G2*#MB.\\!u2=KqhPGq'+_Mp&&'8%JensC)&(^AE\"`c1!>!Hn'=K&)%g*Ibis,Yg(]Oa,!O`1;JHGuV'c-uLL^%f;(U=5n+/Tb#*(0min,jnS,9t>L>HT>$!seuR\"&1#s+sSH[\"/uB,iX6t5:Eot\\\"%36Pn,jnS,9uad>P]Bg\"'`V_.g'#T\"YTsC!tunI\"-;pR-ZCF\\nd8Te)CknoU)5Nc>O!Ok\"$cr%-X@rE,@)B9*rmB)iYb`<+2/Ra\\fi\"7E#TUZ#nP<!)k%N_(BYT]JHQ&W'b:EDL^%f3&\"X+=\\fha@)/p6\"RMHFZ)&&SK*=i8L\"pY/2rrE*#!WrE&!!<3$!+#X*!&\"?Q!\"&]+!5SX8!/:IRz!\"Gjg!=(%U!s],7!u2IOqhPGq(DDZG&%Wo#g)4iG'@%I+c5@FU*$#[p(C)Ak1F<2+!s^C[!u2IOqhPGq(DGd@&&'8)dM?d<'@%'uc5@GL'-._g(E`e^#JpL9!s8d*!s98O\"8dlYE#01r'bAS-(VV+)\\fhmD)/pB*mM6>Y)&L^H*>8Mk5DBaT#8@CF2[:W2\"'j.[nc_Si.0BYP!<N?'!!!*$!!!?+z!!!f8!!\"&?!!!K1!!%TN!!!5,joG]Q!s8co!s8co!s:?J#+5nd!='>A!u2=KqhPGq'+aXD&%Wntg)1FH)&'_/E\"`cQ(D\"e/'A==C'+_5a&'c%+ndZZN!tuC7!X\"nq-MIQD!s_6s!u2=KqhPGq'+_Md&$?fa^*@S1&)n*1Xr7u-)/p6\"js1J_)&(:5E\"`bB*Y6O6'@J-H%g*J.p(.<2E!In^!>=Ds\")%oOWs/Y2JH5iT'b:EDL^%f3&'>.g^*=<>(([u\"'A==C'+]sF&'c%+ap9!u!tuhD\"8`3$!!iQ)zzz!$2+?!\"/c,!$)%>!/psZ!#c\"@!#c\"@!'pSb!%.aHz!!Tal!=,\"n!s8dr!<WE/R/mBlE!lo^\")Y=gXT8e74Tbcu\\IA'=)K6&hJgbRG$\\AP$$Ob5d4h`!?%r`$iL*n_]'*Bj#'*AJ:!s<KM#D+@C$O_OiE!m'!#mX`<!sbq/!s8f2%g*7O#7h&R!s:^#*s3$m%hFCB#B9hJ9&^`s%gPf2\"#9rl\"\"k6#!seu>!t>bC%naD6$P*I_!s;j3$NgX1!<WF.iW0\\p#DiH`\"#^Ad\"$aL4#7Cd!!<WEO$NmL3#I+:3\"\"\"*P!s]8;!rrB(\"rmUCzzz!-SJF!-SJF!-SJF!&+BQ!\"f22!\"T&0!'LA`!-eVH!-eVH!-eVH!-eVH!.\"bJ!.\"bJ!.\"bJ!.\"bJ!-eVH!-eVH!-eVH!.\"bJ!.\"bJ!':/\\!$VCC!'C;_!-SJF!-SJF!-SJF!-SJF!!3-#!)W^r!%\\*M!':5^!!^F*!=-FC!s8eE!s8W1%0H\\I)[#tn#&kY'jp2L#)B[ZNE$$%1+V2j9+6EhL)Zq/e_#sE5!ue'Jbmg-H#;H;_'dEhXL^%fG,K^9?/#F$/*(0nH]*C!.0/*/7>Oiai!seu^\"%36Pn,kIc1Gb=(>OhhS\"'^Kf3s/dk1BTor0/Hla0.R#Q/+sTU.kA1C9$S;%.rZj\\l6?hb)(1\"D*?tY6#DE0\\!u2aWqhPGq*uk1i&&'81dM<@r)B[ZNE$$$N$P1N#+5S+\\,6K#NZ5WlV1!'OX!<WS/!<WE=)[#tn#&kY'ScfS,)B[ZN&&'81dM?dD)hK.B^*=`R,]FhEr[8;k,9PVb&$?fm^*@S=)tFONc5@_`)]]k\"+$GK%!s]#8]*%$u4c1Th$Tne)l5#'S/[klc#PA*\"!u3$_qhPGq-R62C-nD//dMtXWO736)E%`le)I('+1BRmb0*;2-0CBHQ0/'UH>q7QY!%TS>&QL>3Q5E6>)(-qR-R5>p-nD//dMtXWO736)E%`m8$<u?m1BUjI!]L3cQ3',M5Q_ZQ8M;ab$7@J/eH/tC)_V:h0*C#3>H/)b\"%36Pn,kIc1Gb=(>J:8\"\"'^cs3s/dk1BUo91G<#a0.R#Q/,C>f.k@&/9\"H/n.rZj\\p&biN)(4tt*?tY6#F,An!u2aWQN_=M)tFjW^*=`Z%r`U0mMQPH+WnECE$$%i+:la8+7^9iZNUFQTE,Q6!u_7D\"\"\"*P\"#9r`!sd3W!s<KQ%u(l*d/sIQ#LrnY!u3$_qhPGq-R8I$-nD//dMtXW_n-.,E%`m4+E>O61U7$cRN+6g?3;h_>q7QY!%TQ0<@]T\"+\\L#t-S'-`,Oup)/#F$/*(0nH]*C!.0/(lq6j&M>\"#FmP1WgV?U(K<d#Qljb<AQF_!=/c\\\"'mE1.f_(MecAc$/\"R/AXr8Z<-nD//dMtn5ed'n76j)bU\"uC3S1P,s%\"7)ul2fL]7XoSe11BUo91G<#a0.R#Q/'\\`,.kAaF9\"H/n.rZj\\L'%t3)(4ts*?tY6#Q4e+\"/c8:)[#tn#&kY'g&V_u,9PVbE$$%i*tQX7+5-`93s-Q\\%hG6E#Fu##!sbM'!s98W\"8dlYE$$%u#S4'V+1`U+\\fi0,+`JMBmM-8X)'?\"\"E$$%a&.d&(+8uNd)Zq0HWWMVmD\\BM_\"5Eq_nGr^o#Lrt[!u2aWqhPGq*ujVY&&'81iY$2P)tjaPc5@_l%ilSk+*[ki#7%4/!s8eE!s8W*!<NQ-!!!*$!!!?+z!!\"hU!!!l:!!$s<!!$X5!!(4G!!(4G!!)0^!!';)!!$X5!!(@K!!(@K!!$d8!!'\\4!!$U4!!!P7joG]!!s8c?!s8c?!s;!G$dK4<%m@3+!s`cM#HejJ.0BZk#7%CJE!HW*,R6a?\")nJMMBi`/*=&S_#A!u>E!HWN(N9TaMBi_`+pZ[>-3F>P&+V\"OhAuoe!<WFC#7%CJE!HW*,S.Hf#Hf3T>lt0lZ3pa>#B^+N4gGFt#6u7O\")nJMXqq>\"!<WFC#7%CJE!HW*,S0kZ#JqQGZ3pa>#;lScE!HW*,S0;f#N?^.SH/fp4gGFt#7#)J\"$Npt!s]'*!s8c?!s8N',ldoFzzz5QCcaH3F9KH3F9KH3F9KHj'KMHj'KMHj'KMH3F9KH3F9KH3F9KKEV>UKEV>UKEV>UKEV>UHj'KMHj'KMJ->oQJ->oQJ->oQJ->oQJcu,SJcu,SHj'KMHj'KMIK]]OIK]]OJcu,SJcu,SJcu,SKEV>UKEV>U7fWMh-NF,H^B+B8J->oQJ->oQ\".83O#9a0O#9a0O&dng.!XB;>\"!7mU%l\"S\"\"\"+T]/I*^,\"$Q2Z!s]&;!s8cg!s;'r%g*%[!s;bf#.+cb%l\"S&!s^C[\"\"\"*P!rr?B&-)\\1zzF9)@AF9)@AEWH.?GQ@dEGQ@dEGQ@dEEWH.?EWH.?GQ@dEGQ@dEzMuWhXGQ@dEGQ@dE\"f18]#<;kg#<;kg#<;kg-3F>P5Q_f-#?:j.E\"<K=!aFXo'*DI9$5WeKWZiAa5Q_Z18qI6T%l\"Fs\"%WM%\"$O4D!s`cM#Hf0S70<WI!t,2d#7gnl$PNUIAHN$R$O;7eE!m&*\"[2Q#!tPVS!s;c-'c-rW&H`+?3<K@@_ZY`(c3F=O\"UPVMzzz!!!#U!!!#Q!!!#Q!!!!0!!!!-!!!\":!!!#U!!!#U!!!!@!!!!6!!!\"9!!!#S!!!#S!!!#S!!!#S!!!#Q!!!#Qz!!!!(\\`Nnt'a\"OC'a\"OC'a\"PBU*0mH8-95%2?s<d0ae3g:C@7^#IOR7\"'`>a$Nip%$Nj04\")S9/!s:7_$Nk>U#LXFo/HZ([_#XW?>Il0i\"%WM%\"'`>a$Nip%$Nk>U#LXGR[K6gE>J_d%\"'u';\"&B:,PlV+Y!s<KM#LXGR[K6gE#DE0\\\"'u';\"&B:,<<nKa!s;c1%hf$MGln-R,m+5LRK`?p`WU5g#LXGR[K6gE>J_d%!sbY'!s;j3$Nk>U$\\fd-WW<P:#>G:&4gH\"/$O8Nk\"\"\"*P\"'`>a$Nip%$NgA/*<6'>zzz*WQ0?*WQ0?!WW3#'EA+5'EA+5'EA+5(]XO9(]XO9('\"=7('\"=7'EA+5('\"=7('\"=7('\"=7)?9a;)?9a;)uos=)uos=/H>bN)ZTj<%0-A.3<0$Z,QIfE$ig8-`W,u=9`P.n/H>bN%KHJ/'EA+5'EA+5*WQ0?('\"=7\"om`d#IOX9!sc49!s8c;!s99*\"8dlYE(<9m!Y<!i8(o5-7mlhW&%WoSg)1F()FrL!E(<:,+V2j98,a2C6N]hAZ3paNrrEoP\\g7SEk6LS]#=/Fo'h\\Z+L^%fo9D/H9;l18W*(0nH]*DDV='*B`6j(?=#?u.O>P8@k\"-;pR?Z9@ZQ3pje!b2=:p*aPU?3=O:>G`*E\"'u(6\"'_K#?NXU:<s)`,=&T)t;jn>!;cCOM9!0(.;^bSA'[dsh\"2h_U=)_5Bef.!Zl`14oE*HOu$:G!^Ws2pM?XKr:#Qn95=Bk2+>?fAT?NXU:<s)`,=&T)t;^,4?;hcMhc5BDVE)0-t(D\"e/:Wae#9*7rph#RT['gi*#L^%fg6_5;/c5B-T)K826arh5?)+U8=*JXlX#=i`c\"W*mW#DE3]\"#1HF\"\"\"*P\"$Npt!uhKA\"Tni3OTGUe'gi*#L^%fg6^AGtXr9h0'Q?Q0Sd,eO)+Tu-*CBp!8rb@P#!3?M!B7\"i#PeN*!sc@<!s992\"8dlYE)0-t+=L0c'[dsh\"-;pR=)_5BOqq8r-!LHW\"'5S,=2\"o@6j)bU#$Z%N>Cm2M\"7)ul?Z9@ZXoSe1>6A/4>?>*/=&T)t;n<TA;cDZ_9\"H0A;fGN*OrP\"X),H\\**D6K1#E])j!u40*mg!f%6^fD6Xr9ga)%Y\"18'VT`7mi^L&'c%_ROB1D\"%Nuf\"t-n^#PA3%!sc@=!s99*\"8dlYE(<:P#nO0W8%'^_7mm+j&&'8YdM?dl6h2**c5B-p(`bsG7pGrr#6PM>gAqE%!=8i1#O)<m!u40*qhPGq7mk9D&$?g@g)4j\"6d?S\\c5B-L$6;J97hR$K/.s=s\"7uX-.g(G*#IOU8!sb(o!s99*\"8dlYE(<9M#nO`p8(&/l7ml,;&'c%_dM<A-,=g;uE(<9a+:kUn8+I727mj9q&'c%_RNNV<\"%QZ\"])i'>_ZBqA!l\"ct!s8W1d0'OR'gi*#L^%fg6fKL)^*?.r(2uc2c3t6/)+V[f*CBp!0EX69&%Vj%RO-hleHH$W#PeK)!u40*qhPGq7mjEd&%WoSg)4j\"6]N)rc5B.K'-0FB7m4F3\"#FmP1Yra`1Ge;;E&0;U&-n$s\".o`%W<EA+'gi*#L^%fg6gb[\"\\fjT7&TC6-p'qVE+\\16(E(<:4,S/0<8+%*46N]hCl3nW@!F(ip,6J15\"9[fj#MB7_!u40*qhPGq7mj9t&'c%_V?1^,6Z*F[)+U\\J*CBp!&sE=uHj>W4!s8f,\"TniA9*>'I#&m@2g(Yr6VA.Gu6j(?=#?PkG=2l=M\"-;pR>B!eNnd8Up$XX!?Q3(Ou>O!PJ\"$cr%>?+m3Jd=aHO736YE*lt<$<t4J@forD&8))O\"().:\"'5S1;cclt;cB,\"<DuhR\"%piV:K)4.9;WO:c5BEd(`c6O:C#tc!s99*\"8dlYE(<:d,S.$r8*V<0^*?/A'lZZ1[MTP#)+X6C*M3?77g0\",!Wr]+!<WE/N<]Of'gi*#L^%fg6])BbXr9ga)%XG+8(&/l7mj^!&'c%_l6C7<6bXTPc5B-\\'HKOC7rXpu1Y*^@blfO!#JC?E!u40*qhPGq7mlh\\&$?g@g)1F8,=g/tE(<:X\"V8lr8+I<66N]h+[0,Rm\"!E4,Sdhq5!!\"#>zz!!!6(!!#4`!!)6`!!%6F!!'S3!!(LL!!(LL!!%iU!!#Xl!!#1`!!'S3!!'S3!!&Pi!!$j9!!\"PN!!(gT!!%3C!!)*\\!!(@H!!(@H!!)Zl!!%QM!!)]m!!!?-!!\"&A!!\"&A!!!B-!!&,]!!)9a!!(^R!!(^R!!\"GK!!&Jg!!#+^!!%<H!!%<H!!#._!!&tu!!#+^!!$\"\"!!'D,!!)9a!!$j:!!'_5!!#4a!!%KL!!)Ee!!#+^!!(mW!!)`nz!!!q?joG^L!<WE/OT>Od#E]#h!saqh!s9(F!XJ,o4gGFt#7#q`!s<KI#Dsc3FTV_b#7%CJE!HW*,S0_l#LX/HZ3pa>E!HWN(N9TaMBi`',mU^\\4gGFt#B0nQXqu$^#Dsc;mNVtf%R%**!s`cM#HejJAHN#FrW`\\J+U;id\")nJMMBiE=!s:]l$NgV=I00Q^efk@9\"==3Q\")nJMXqq<`!s<KI#Hek^#7$,3#@.E64gGFt#6uOW\"&G[$V[_Jf!!\"/Bzzzz!!&r$!!'#&!!'#&!!')(!!')(!!&_s!!&_s!!&_s!!&eu!!&eu!!&eu!!&eu!!&l\"!!&l\"!!&l\"!!&l\"!!&r$!!&r$!!&r$!!'#&!!'#&!!&r$!!&r$!!#\"Z!!\"/B!!(RO!!'#&!!'#&!!'#&!!&_s!!&_s!!!+rk5bff!s8c7!s98_\"8dlYE$llf*\"Tb.-dicL-R6nS&'c%?MB!W]\"\"24l<<E=..0BYe,6Rh!#&kq7WYQ,J)CO5VE$lmu((\\\\.-dES?^*>#b%r`m@jp2LC)(4hf*?tY6bQ7#1'+Y=Vk6(lF%g)nsncf10#E]#h!s`B>!u3$_qhPGq-R7n(&'c%?ne#gg,GHUtc5A##&TB*BiXcXG)(2.-*?tY60t.B$\"\"0]C\"4[GXXTAS,#F,;l!u3<gqhPGq0.R5T1Stl7*(0nH]*C962`K;,>J^e1\"'`2=56F:UO736=E'm\"`$<sA>7fuuh#\"o&&rWQ(\"5Q_Ze5Q_ZY;E*S=2^^NdjT.aOO7361E&T_u)I)>M3s,`j2Zli7\"76+ng*el^>r+Dq!&HFn$ro)>l5WF1,;1il0.Wn#&'c%G\"s#2r0AZ_h!WrN>,6Rh!#&kq7U*gJc,:D%UE$lk7&'c%?U*gs+\"\"0?7(B`\"c#:0HS#PA-#\"!cM-f)jA'#Ism<!u3$_qhPGq-R0N?\\fiHT)/prJOrP\"X)(-=C,6K;?!s?^N#MB.\\!u3$_qhPGq-R4oi&%Wo3g)4iW,LQT'c5A!q&fi2!-V+=YQN7?e!WrN>.g,[)#&l4GNYs6$VA.Gu6j(?=#<-T\\2s(`@\"-;pR4)d8COqq9!)a=E1\"$6T848pTh-T_F<\"%36Pn,kak4$1S'>CmPR!seuj\"&Cu\\aTFp5O7365E'$.E(0fc856D/n3s/]q#!W2r\"#g<f1H.)i1Gd`-<AQGZ,>,*W0/IQ#/\".S/1Stl7*(0nH]*C962`JGc6j&M>\"$:H`4-C@`p'<kb#Qm-j>G;-_\"'u'g\"%36Pn,kak4$3!?>N->]\"'`V_6N^Q0*Cg2s!u!a^2`Eg(1H.)i1GcTF<AQFo)+q%M0/IQ#/%-T3c5A:(+<;s70*fH!f*)6k,6Rh!#&kq7joc4/,:CnTE$lmM*Y5Cl-a\"?u\\fiHT)/prJRNN-d)(3EF*@!p!0cMpT!P8B_!WrN)!\"&]+!!<3$!!rW*z!#5J6!#5J6!:9ad!!3-#!87GR!87GR!&FTT!$hOE!:g*i!)!:l!)!:l!:Bge!9=.\\!3?/#!1a)i!1Nrg!:g*i!#1ma!=(ai!s^sk!s^sk\"$Q>h!t,>S!s95F!s8c[!s<KM$^q)/%g*(B'a\"Oqg'=khi<gn6!s8ck!s9YJ!t,?&!s:Fd!s8cc!s9nY\"\"a`e!s8N)$4[OGzzz!!!<*!!!9)!!(%>!!&)]!!&)]!!'Y3!!%rYz!!%rY!!%rY!!!'#!!!'#!!%rY!!!/JjoG]E!s8cc!s8cc!s8cc!s8cC!s98O\"8dlYE#02Q,7gpq(YTaG(DEqi&'c%/l6@;_!uE/q&$H!=#MfC_!s^gg!u2IOqhPGq(DEqr&%Wo#g)4iG'CGr5Xr8,1)/pB*V?.:R)&M]C*>8Mk4i.ut!s](A!<]M+#A!u>'b^]HL^%f7';bd@Xr8,1)/pB*l6d+F)Ag[:&&'8)`ZT4:'B0Q6c5@G`-QNj&(L=`phZj5h!s\\o5jT.RJ#FPSp!u2IOqhPGq(DFM*&$?feg)1FH)&M!EE#01>(D\"e/(VV\"4'*B$t:V-]2#JC-?!u2IOqhPGq(DFq6&&'8)dM?d<'D;hFc5@GX+WV3u(N9Tap&a4S@06U@[O(nq!sb(l!s8em!<WE='*J,f#&k@ljpr!6+W%j;E#02I*tQ(1(TnYec5@GP)%X;%(VV,5(DEMa&'c%/iZB0S!uLY3hZX,*!^5fN\"8`0*&H`,HT*gMZP6Cpe!Y#,0zzzz!\"/c,!\"Ao.!;?Ko!$)%>!$qUF!;6En!)3Fn!%n6O!;HQp!+,^+!&jlX!;6En!:U'j!:U'j!-J8A!(?kf!;6En!:Bph!:Bph!!^I-!=,k5!s8c7!s98[\"8dlYE$HH^*\"Tb.,LR?H,9P2K&'c%;MB!WY\"!_'U\"Tni3.0BYe-Nj7%#&l(?ari)cVA.Gu6j(?=#;^<T1[ZAR\"7)ul2fL]7\\d(V*l`14OE'$.a!=/cd\"%36Pn,kak4$3!?>M]EG\"'bI'6N^Ql\"\\/Y[!u!b#V@l)q5Q_ZU6j&M>\"#k0X2p*%Cq?/k^#Qm!f3&<KL-Skjm!CR$Nn,kIc1Gd/l>LFNN!seub\"&C]TT`JBs*]!n(0/G6]0/)<3<A-#J-VCrn.kbil-ft[Fc5A.L&fi>%.gNlk!s98[\"8dlYE$HIa)\\9(i,MF\"G\\fi<P)/pfB_@dC))'e,[*?PA2#I+I,\"j[E#!s8W[%grIEW<iY/#Oqfs!u30cqhPGq.jraG-nhG3dMtXW_n-.0E&0<H&juh_n,kUg2`Hm8>I\"c$!seuf\"%36Pn,kak4$3!?>CJd=>O!P&\"'b%;7fu!Y'0BJY4#[EI1BUo91G8_]08^0<0/&n/9$S;)05rEhScfSL)(QUG-Nbk(eH,gT'or@tqhPGq,9N3a&'c%;\\fhTe)C)s@E$HGC&'c%;Q4b2[\"!]P,\"2b<F-P$<Y#m^D1!s98[\"8dlYE$HIi,S.I0,MF\"G^*=lN(2tK?^)IU.)'eDl*?PA.>ibtgHSPg:!sbY)!s8e-!s8W?-Nj7%#&l(?`X+%HVA.Gu6j(?=#;^<T1[YB6\"-;pR2fL]7Q3pj1\"Zlfjq>ie_?3<+g0/khY-O9f1\"'mQ90*!XYN[@aZ0BOZT\\fiRWE%<<u-P+K?/&hl9-Nbk(q#^_k!YldZqhPGq,9NKa&%Wo/g)1F()C*rRE$HIE#nP<!,I.Lo*s3`ldMEQ!#FtuNrrWM\"\"9S`@*s;Cr#&ke/p'M>A+X>\\Y&$?fqg)4iS+3k9*\\fi<P)/pfBg'J:m)C+ebE$HIY\"V8lr,L-]<*s3`lRKjX1>HSmF\"p58E'*AKq\"SW+q\"pa)i!s98[\"8dlYE$HIq*tPq+,MF#S,9O&i&'c%;nfJko\"!\\'<!<^XO#Fu/'!saM`!s98[\"8dlYE$HII*tPLm,L.0G,9P23&%Wo/g)4iS+7^Qcc5@kD,TRs/,?q`,#6S2A-U.\\<r<*4l#7%X?!s98c\"8dlYE%<;r$Rd[*'[dsh\"2h_U1N5-+p'F+h_n-.4E&T`,)ajdhn,kak4$/`8>Ohh[\"'_W;6N^Ws3s/^X(-_n-\"#g<d[K\\eq?3;tc>q[ue!&$!_+B:'J\\eduM+Y,3b.jq>+&'c%CL'J_H\"\"OVA\"p4rB*s;Cr#&ke/V?d^8)C)g:&%Wo/g)4iS+1`d0^*=lN(2tK?g)CRJ)'cj?&$?fqg)4iS+,1\"2c5@k\\)]^\"&b68p`!J^ab1'=]_LB3hEfa%Z^#Ls\"\\!u30cqhPGq.js$h-nhG3dMtXW_n-.0E&0<<\"@N@XWs1M%2`H<q6j)bU#!6cc40ASi\"#g<M\"-;pR4)d8Car4L\\,sMJ;\"$6Tk\"#C$I\"7)ul2fL]7JdOmJl`14OE'$.a!=/cd\"'m]A1L2Xi0*!XYZ6iR)0E)e\\Xr8fDE%<=('+`A+/'\\YG-Nbk(aThnM'd!PTL^%fC+3k*%^*=l>!cTA+c4:H2)'c:!*?Vlp,@1H_\"*\"hRJHZ;G#6P&C-Nj7%#&l(?JfuNqVA.Gu6j(?=#;^<T1SQ4#Jd=:;#Qljb;D[;=1FFs\\PmCTk+u9<s1BX0R>OEgo\"'mQ90*!XY_?j3q0@gD$Xr8fDE%<;n&eE8*/*7im-Nbk(]a+]B'd&&/qhPGq,9Q1U&$?fqg)4iS+6FRSc5@kl#9=lg,6sVCdfT[Wh$=)b'd!PTL^%fC+4_;?^*=lN(([Pd,MF#S,9O?A&$?fqXr;7(+8,gJ^*=ks$kKom,J#%;,9N?]&'c%;p&lBX\"!bng[K7!.!F+7bmfrq(d0Ab9!sd3^!s;=(\"76*oSHArr-_UXe#IOX=XU,(3'd!PTL^%fC+3\"a#^*=lr,nJ9=,MF\"G\\fi<P)/pfBncTKK)'d-1*?PA.3cbhH\"UEQa!s98c\"8dlYE%<<i+t,+A'[dsh\"2h_U1N5-+jq:<G^(\\']>Q,R'\"'u'c\"'mQ90*!XYhBl5U0:i_IXr8fDE%<;n)%Y\"1/)gaR-Nbk(PmRTq'd!PTL^%fC+4_&8\\fi<0+`JYJc6j.*)C*rRE$HHZ)\\:43,JGCA,9Oc9&$?fq[NuHq+X>\\YE$HI5#S52u,L./;Xr8Or+V2.-,J#%;,9P2V&$?fqg)4iS+6!J8c5@kX&fi'T![Bl!\"p74*'Dho_!Zu?i\"oe][cNXm^0af5L\":(J(b67tQr<`W/'d!PTL^%fC+.<?D^*=lN(2tK?Q6HjB)C)g:&%Wo/\\fl#;+6\"\"G\\fi<P)/pfBVBHJq)'bFk*?PA.5ILX^\"TJU/Osq1L?3:`4\"H!5j$NgJ9]aFoE'dj+\\L^%fK-di5J0;]H3*(0nH]*C-21Gek?6j(?=#<-T\\2qAp9\"7)ul4)d8C\\d(V*l`14SE'HRi!=/ch!seuf!seub\"'mQ90*!XY_A$!'08:-4c5A,cE%<<5%1g`%/*7ck-Nbk(Pmd`s'r(s8qhPGq,9QUq&&'85_?+[$+6FLQc5@l#(EFS\",68;WJHZ:d$j-SH*s;Cr#&ke/Q66^P,9tVPE$HG[&'c%;Q671i\"!ce+h$jGg#Ls4b!u30cqhPGq.jpbf-nhG3dMtXW_n-.0E&0<<\"@N@0]*C962`LRG6j&M>\"$:H`4-C@`Z62@6#Qm-j#Qm!f>N.\"l\"%36Pn,kmo5<m:/>J:tB!seun\"$cr%1L2Xi0*!XYmN5F^0BO<Jc5A,cE%<<m,7i';.uk&Z-Nbk(]aY&G'qYO0qhPGq,9P&C&&'85dM?dH+-$d@c5@k$)''e$,>eQs$4gA:$3LA8i=,kk'd!PTL^%fC+4:i6^*=lN(2tK?dO,RN)'dQD*?PA.iW7F5!s8N)'cdhc!!!*$!!\"tYz!!%'?!!$X3!!#\"[!!(CH!!&Vk!!\"nX!!#:c!!')#!!\"bT!!$4(!!(FI!!\"PN!!&nt!!\"AI!!\"SO!!$a8!!$a8!!\"\\Q!!$(%!!\"hV!!#\"[!!$d9!!$.&!!\"VP!!$=,!!$7*!!$7*!!$7*!!'\\6!!'_6!!\"SO!!!Y5joG]I!s8c7!s98K\"8dlYE\"`cE#S4'V'A=<7\\fha@)/p6\"c5@/<)&)-<*=i5c#<DY`is#`K!s8cg!s:u[\"2>4r\"ssES!s^sk!u2=KqhPGq'+_)c&$?fag)1FH)&(:5E\"`c-\"V8<l'A=^N'+aXD&'c%+iXd+@!u!ik&-E.d#7$[u&jqif+9ulg!s`rN!u2=KqhPGq'+^r@&%Wntg)4iC&%32`c5@;0(EF\"g',1ZR!s^[cqZ-Zs\"onW'!rr<$$ig8-z*WQ0?*<6'>)?9a;Vucr!;?[%#;?[%#3rf6\\,QIfEVucr!\"h<[q#FPSp!sb4p!s8dr!<WE/R/mBl-3F>P%upYq\\gK06$NgX-!<WE0!tPJg$P*=E=T\\a:c6!_6,7ic:'CGr5rXon4('esa\")nb]l5g1i!<WEX!ttbI\\cWUt%h]Z\\!(r8#',Lls!s<KQ$^)hA@06Tc!ttbAW<!)'&e>);!]1FR+Tht'!<WE:(BZKdN[YVX#QkS>#I+:3\"$O4D!tPXI!<WFC%hGrWE\"<K1+U:F<\"#'f^!s]PC!tV[c$gn*%B`eGJ\\cWVW('cDn\"#LO[*s2`[!s<KQ&)Ip(4TbdbNXM3WoE5-o/-#YMzzzzTE\"rl$ig8-%KHJ/%KHJ/+ohTC+ohTC+ohTCRK*<fS,`NhScA`jScA`j+ohTC+ohTC+ohTC,QIfE-ia5I-3+#G-3+#GQ2gmbQ2gmbQ2gmbQ2gmb'EA+5&c_n3&c_n3TE\"rlTE\"rlQ2gmbQ2gmb70!;f-3+#G&HDe2$ig8-$ig8-%KHJ/%KHJ/QiI*dQiI*dQ2gmbQ2gmb+ohTC+ohTC#INUo#;lSc#;lSc#;lScBA<aA\"8`<.'a\"OQ'*J,f#&k@lrY,mG)Ah*F&%Wo#g)4iG'<W5ac5@Gt'HIhh(C)h@\"#C0B!s98O\"8dlYE#01f((\\\\.(YTaG(DEYI&'c%/WYQTg!uEDM\"9Sl6=T\\a2>lt0D'*J,f#&k@lV?%4A,8\\cDE#02%(D\"e/(VV+)^*=H^(([Pd(YT`;\\fhmD)/pB*mK4!F)&MQc*>8Mk5DBaT#HIl\\\"S2Yt\"RlGW!<WE/R/mBl'b^]HL^%f7'E0<h^*=GG(N:0(JensC)&N9!*>8MkjoGPd!rr?+#64`(zzz_uKc;$NL/,%0-A.z*<6'>,ldoF%fu_29`P.n/-#YMz#*S*L#8I=C#8I=C#8I=C@\"o!8%CH9C'a\"P$p(.<2E!HW:!>5bB&/5?O!s^7W\"\"\"*P!rr<.zzz!!!#=z!!!!U\"TSNZ\"TSN\\\"TSNZ\"TSNZ\"TSN)U?2I]4Tbck4Tbck4Tbck4TbdL\\gRXgE!m'1&dMPA!seu:\"#1#g!s^7W\"\"\"*P!tU+e&$c<N'*Cp#N[YJP#9<mK0EVO^%upYq\\gI^p!s:4Z%g*&6!s9(F!tUP>#;$#[E!m&R-ZBG$Z4Ls_$e?I+8HT&uh[Hk#q$I*%'`\\46zzzz$NL/,$31&+8-/bkQ370fPQUsdQimBhQ370fQ370fN!'+\\N!'+\\N!'+\\O9>O`O9>O`OotabOotabO9>O`O9>O`O9>O`O9>O`#3P(L#Isp=!s],7!u2m[qhPGq,9Q%R&&'85dM<@r)C*rRE$HIM)%Y\"1,N]7P*s3`Z\\HA#s!s^C[!u2m[qhPGq,9PJM&$?fqg)4iS+3k?,c5@kX'-/.s,6ta]]*/9TUBJpJap\\MP!s98c\"8dlYE%<<Y#Uh@''[dsh\"2h_U1N5-+^(j$<_n-.4E&T`P(0gbW3s,`j2Zm:,+Zfd4\"#C$b0/G6]0/(Tj<A-\"k(.u:c.kbil-gh`\\c5A.L!Z`Wj.gMUG!s<6Z\"8dlYE$HIa+V2j9,MF\"G\\fi<P)/pfBarh5/,9uIeE$HJ(-kF$:,LR?H,9Pna&$?fq[NuI0)'dEEE$HIA!Y<Qo,N9je*s3`CRfj,:\"o86)%g+RslN.1$!QbBF!se&k!s98[\"8dlYE$HIY*=o:k,OuFc,9QV*&&'85dM?dH+6\"@Q\\fi<P)/pfBU)jij)'e,_*?PA.>N-,+o)W'm$5WeKWZp$s!th4.!s8e)!WrN>*s;Cr#&ke/^'bIS)C*rR&&'85dM?dH+,0t1c5@l'-ljB3,<u>E%loUQ[fup>blRtL'd!PTL^%fC+9!5j^*=lB+:l%,,MF\"GXr8Of)K6oC^*F67)'dEEE$HJ$!Y;jc,JGB5^*=kW.<$LRZ5!nq)'f,#*?PA.:9#&,#P/!P!uKPlE6eXlJcuCY\"p4r4Plh*j'd!PTL^%fC+7^9[\\fi<P)/pfBnfSIg)'bRu*?PA.4n]p!%r`$iiW9AH!<_']#JC3A!u30cqhPGq.jp&X-nhG3dMrHIqAY.j-SkkT\"'b%51BUE/\"5O&`L(?'B6j&M>\"#k0X2t@;[Q74lt>F#=T\"'_&m6N]RU'/s2Q2`\"_m1G8_]09-*60/(<k9$S;)05rEhmMQP\\)(Vus*@Cq>#FP\\s!u2m[qhPGq,9PVG&'c%;^*=0&,9tnfE$HHZ%M,]\\,MF\"G^*=lN(2tK?c3t5t,9uma&%Wo/^*@SA+0l(]c5@kP$luqa\"!^^T-j,e=*n(,pXrt+Q:%nho#MfLb!u2m[qhPGq,9PV_&%Wo/g)4iS+0H4e\\fi<P)%XG+,LR><Xr8P=)/pfBp'M>U)'diY*?PA.0ae6X!s,e5NsEE$#E]/l!u2m[qhPGq,9P23&$?fqc5@/(+X=QAE$HIe,7i';,L-<1*s3`[Jd0s2gB%W5\"9S`2\\HN';'dj+\\L^%fK-f,Ue0;]H3*(0nH]*C-21Gc`[>OEOk\"'_W:3s/dk1BT-`Os2\\01BZ_B>Q,^#\"&C]Tm0-^;1BUo91G8_]0?+/q0/*#\"9\"lN#05rEhNYE#L)(UF_*@Cq>#E8oi\"2k3^\"8dlYE$HI]\"V8lr,MF#S,9MX]&'c%;h?=oA\"!^A&\":G;:XTek0'd!PTL^%fC+2/9s\\fi<P)%XG+,LR?H,9Q=e&'c%;c5CRG+3l#?c5@kp'-/.s,B3)R$\\AOqOTP^_#7'&h!s98[\"8dlYE$HIE'G%o&,D$^BXr8P=)/pfBc4(<0)'d-8*?PA.B`lN\\!rrE,#n7:C!!!*$!!!W3z!!')#!!\"GJ!!#\"Z!!)Ee!!%-A!!#ms!!)Hf!!&ns!!$I.!!)Ee!!(%>!!$m:!!)Hf!!(mV!!&;b!!)Ee!!\"YQ!!&bo!!)Kg!!#Rk!!',$!!)Hf!!$:*!!(.A!!)Kg!!&>d!!(RM!!)Hf!!'2'!!(jU!!)Kg!!!V!joG]I!s8cg!s8cg!s9kP!s8cg!s95F!s8cS!s<KM$^q)$0`qL_%0H\\qp(.<6#9<mK&e>(p!='>A\"#^Ad\"\"+<U%0n<a\"$6AeedU+<!!E`C(blBuzzz!!%fWz!!!H.!!!E-!!'t=!!%r[!!%r[!!!'#!!%fW!!%fW!!!.YklD$C\"Tni3K`qP\\#7Ub;'jCe;L^%g*>Q,<I\\fkF`)K9%fV?.:2)IM29E*lh\\+V2j9?g8jV>6A4F(B[o7eftj;\"qh_2j8fLn!<WE/5m%3(>6FbY#&mpRJdW+7).0ruE*li/%hHB!?_Soe?X&C4&'c&\"g)4j:>NR1A^*@!V*=pF5?iCaY?X*(;&'c&\"js1sO\"(-E4\"WmhcdM!QA#j2:+\"#8s>(BXou$3LA8N<'+`'jCe;L^%g*>H/kXc5Bul)K9%fr[&/i,@Ak7E*li7-P+K??`G:j>6A4FQNI>+o`=^i!s;0T&JGrcXTnq1#JgEC!u5#BqhPGq?X(Yq&$?gXg)4j:>J_!`c5C!3+<=Yg?P40=\"ip`Mo`YF\"#NYsg!u5#BqhPGq?X!^F\\fkG7)/rqeNXcT6,@C!XE*liK-kFT@?]GU:>6A6o!<Wi7#NZ0m>6g8l!s99B\"8dlYE*lh8'b@l!?`k;d?X'*,&'c&\"Q5(EE\"(+[/()*_L#71J7#IOU8!u5#BqhPGq?X'rO&%Wokg)4j:>LEN_c5C!;(3!VbOp2HB).1em*ErVQ'))V5kQ2\"F!X$mT#N5^d!u5#BqhPGq?X&s'&%Wokg)1F()IM29E*liG!Y;FP?h+eJ?X)M+&'c&\"q>q[A\"(+Z\\.F/&;)`Ij@#FPe2\"oAN0Plh*j'jCe;L^%g*>OiXB^*@\"9'6%;_mMQPH+^`q@E*li?+:la8?h,'T>6A5$(B_;O#E8ceK)u:o!s8W?>6FbY#&mpRH4RS1?d]^/?X(eo&$?gXg)4j:>M:>5c5C!c)')o`?Os^M)nl@d+3+QS!D8A$)p\\Qjm03Xp#PA0$!u5#BqhPGq?X'ZC&%Wokg)1F8,@Ak7E*lh@$4jiq?_Soe?X(eg&'c&\"SdHKB\"()2^-5.1.(B\\2?Os(JT&f1Z.!M][\\$NlRo#I+C6!u5#BqhPGq?X&6p&&'8qneVh^).2)8E*liC$4j]k?eQB:?X'ZP&'c&\"L(55.\"(16mCC:4LPm@Ju\"UEuh!s99B\"8dlYE*lhT*\"U=4?eQA.^*@\"U(N<_cXo]-Z).0Zh*ErVQTE3@?)Zp>Y!s8W1M$3t`'jCe;L^%g*>E0C.Xr:[$)%X;%?eQB:?X(eV&'c&\"g)4j:>M:52c5C!7!?GAH?P)B(#6PKs!=-1`#H\\,MP6;-(\"TniA>6FbY#&mpRM?sg)+^`q@E*lhT(D\"5)?cF4-?X)q/&&'8q`ZT5->Q+a9c5BuH#p!4P?X'rS47<4TU'*[_!KILS!scpU!s8f(\"TniA>6FbY#&mpRL'J7',@@/mE*lh4%hHr'?\\Se+>6A5s!Ql)i(C-')!s8e!\"p4rB>6FbY#&mpRNXHB#)IM29E*lhT!Y;FP?hP4R?X'6H&'c&\"Z2u%N\"(,9P*Oc4T#It,p#6P4Q\"p4rB>6FbY#&mpR[O)Nf)IM29&%Wokg)4j:>M:#,c5C!G*?A>d?TktK!uD31$MOS9!tl[X=9mpo!s8f(\"p4rB>6FbY#&mpR[KI,P+^_Aj&&'8qU*jne>P]6KXr:[$)%X;%?eQB:?X)M4&'c&\"[KIUT\"(,*o)AD]C&f1Z.!XJ5trs&?$#I+L9!u5#BqhPGq?X)5&&$?gX[NuHu,@@/mE*lhP'bA#'?d]]#Xr:[$)/rqeiXQLE).2qJ*ErVQ&f1YW!SIM=&VC<)PlZ^Bo*#4$km%:m'jCe;L^%g*>G<,K^*@\"5(3!Vbc3Fm*).0Zq*ErVQ&$dSo`Z6`8'*Aj`!uOYM*>97>!W<9+!sb5\"!s99B\"8dlYE*li'-P*p9?d]^/?X\"ujc5C![&fk0Y?Or.t$b@_#!T=%]!scLF!s99B\"8dlYE*lh4#nOTj?eQB:?X)e0&%Wokg)4j:>I\"SHXr:[4,B.!ojrFuX).2YC*ErVQ>Fl][(L,#r.g'#@&MF5jiXu%k\"'a>$2Zj;q\"To8?JI)D\\'jCe;L^%g*>D<k'\\fkG7)%Wkg?eQA.^*@\"5(3!Vb$4jiq?_Soe?X&[8&'c&\"ncTt;\"()ZW\",I$:!M1/B(SLlC!S[^[!XH7B!s99B\"8dlYE*li#$kKKZ?h+eJ?X(Y]&&'8qdM?e/>J:FTc5C!?$lrOS?P!>2!s9(F!uof&\"L/\"1!se&s!s99B\"8dlYE*lh8&J)Gr?eQA.^*@\"5(3!VbiY)jJ).2Y3*ErVQ9$SY#*s_rb\"#10\"\")o%al3ZMP[0Zqj!sbA(!s99B\"8dlYE*liK'+`A+?`k;d?X&7,&'c&\"Xr7hR)IKWcE*lh<#S4'V?`k;d?X&Nq&'c&\"\\g&5\"\"(-!`(Z#dD(P`6q-ZIfC^B:bQE9@B@efb:S\"9S`Q!s8W1jU)(l'jCe;L^%g*>G`bYXr:[$)%XG+?e,m0?X'*.&$?gX[O#m\">LjDtc5Bud-QQCn?f1r$o*+1V8ra85!Z)*\\\"p4r4R0s*!'jCe;L^%g*>IkX^Xr:ZU-#d3qV@='=)IKp!E*li?'G&J,?`\"8Q>6A5)U'0K\\(D7MdU]F*1&`Ws0#N6!l!sd'Y!s99B\"8dlYE*li+(_=>*?cF4-?X)e\"&%Wokg)4j:>Clnec5C!S\"s$nM?X)e68%Sq/aq78K>EU.*\"2+`d-;t!O4TbckK`qP\\./sd]\"LA42!(d.jzz!!`K(!\"8i-!3uY+!+H*3!-eYI!-eYI!$M=B!$;1@!$q^I!(7\"k!(7\"k!(7\"k!(R\"h!%e0N!71cI!-SMG!-SMG!+>j-!&srY!1Erh!-8,?!(-_d!.+bI!/U[U!)*@m!2fku!1Nrg!+Gp.!$hXH!(mFq!(mFq!6Y?B!,hi;!2or!!9!nX!-nPE!\"B#1!$2=E!#u1C!#u1C!;c`r!/COS!8.DR!6><D!6,0B!8I_X!8I_X!#Ye;!1*Zc!.\"\\H!&4KS!20Am!\"8r0!(?ng!3Q;%!-nVG!+,a,!5/@4!$q^I!.=kJ!6,!=!1<lg!07-\\!7:cH!$q^I!2T\\r!8@JR!\"8r0!'USe!'USe!5/C5!9jI`!7(]H!42n0!42n0!8.AQ!;?Hn!6,'?!/^p[!/^p[!;-?m!!**#!.+bI!;HZs!;ls\"!;Zfu!;Zfu!\"Au0!\"K#0!.\"\\H!$;7B!$;4A!$q^I!'pYd!%S'M!/psZ!#>_<!#>_<!*oX+!&joY!$VLF!(I.m!(I.m!-J>C!($\\d!$24B!#Pn?!#Pn?!(7\"k!(7\"k!070]!*91$!\"8r0!(mFq!4)_,!+Q$0!!36&!!3?)!!3?)!6kQF!,hl<!:9gf!:U-l!:C!j!:C!j!9XC`!.Y(M!$q^Iz!#Ua[!=,k6!s8e5\"p4r4%0H\\I*s;Cr#&ke/iXdLcVA.Gu6j(?=#:jaD/&iZ!\"-;pR05rQtnd8UD$SqlhU)5fk>Q+df\"$cr%0*!XYZ6*;N'/K_s\"\"OIZ-S$PE-RYo7<@90f#>2]T,:@FT+1`U+c5@kd&02hp,Aq&p!u2USqhPGq)]+)6&$?fig)1F4+WK,QE#TVQ&.d&()hJG<(BYT]Ym0e#MZX3@!<WE=*s;Cr#&ke/JfcBgVA.Gu6j(?=#:jaD/,C#c_@A4$#QlRZ6j&M>\"#\"UH09urLncCTL>J_LA\"'u'_\"&pd$0./7P`;s2_+tEak.g+#s>FHH\\\"'m9)-NGMAXsd9t-gDL?\\fi:GE$HI!.1a]A,D%!X*s3_mm/[=4!u2USqhPGq)],(N&$?fi\\fl#3(Zl5=Xr885)/pN2JfbNK)&o.P*>\\esE\"Btl^(5/n&%ViJq#crd!sb@u!s98[\"8dlYE$HI9)(6l0'[dsh\"2h_U.r[!hjq;=,(rct;-SGS8!aCNu0*>!'\"2t=G`YC-/>H0#+\"'u'[\"'m9)-NGMASd8=D-c-os\\fi:GE$HII*@N;4'[dsh\"-;pR.r[!hOqq9A&ha=m\"\"OI,.k@>)<\\#]W$R[G,PljDVl`14?E%<Gj$:G!^Ws14r0/'I/#QlRZ:FcOL\"%36Pn,k1[.k?nm>J:7o\"'^?s1BUqc.g'').jk<E-`/:l-RY&q9!0'W-ZC:Pg)U^L)'c^1*?PA.#L*>QqZ7KK\"8dlYE#TV=&eD,`)nmP9)]-L#&&'8-dM<A)+WK,QE#TV))%Y\"1)pT':(]+7QE\"=>1%sN^.\"'Z$/!s8W?(BaPj#&kLtZ3CiN+WJ!9E#TVU)@t+2)mTYg(BYUnc61X@lN%7<\"TniI_$H#1M?jH`\"9S`@*s;Cr#&ke/js)9%VA.GuEV^+pZ402(O736)E%`m8$=!?R1BUju*B+()rWP@c5Q_ZQ3%HX4-S#;P\"C'\"b.g&Qt\"7ZL^\"-;pR.r[!hQ3pj1\"YTs^JdaF;?3;\\[>ph-M!%0.O)c\\75qBS\\E+X8@R,9O>t&'c%;js(lg\"!\\&5\"Tte+'c-uLL^%f;(Wmg1Xr87n,B+S<js(D^)&p^?*>\\esE\"AuN^(2S%\"4[P[[06X7'c-uLL^%f;(WHRg^*=TF(2t3/WXTKa)&pQu*>\\es6.lDD!seK(!s9kP!s8ea\"TniA(BaPj#&kLtOq/)+)B6C8E#TUb-kFT@)j1^P(BYUq&(:]r%r`$i^(1I\"\"p4r4Ka%V]'c-uLL^%f;(X`^&Xr885)%Y\"1)nI23)]/&h&'c%3dL7-4!uiV[!h08A\"UCFs!s<D;.FeS0#N5jh!sc4<!s98S\"8dlYE#TVI(([Pd)ql0K)]-4\"&&'8-iZW7[(YU2Hc5@S8&02Ph)i=Y$!s<KM#J(!BW<UNM!sbM&!s8em\"p4rB*s;Cr#&ke/NZfeuVA.Gu6j(?=#:jaD/,C#L\"-;pR05rQtOqq:$,VoN.\"\"s`^\"\"OIA\"7)ul05rQtjqgDfl`14GE&0;Q!=/c\\!s0u+.jlhLYm4Le#V-!Q.g*<e>N-kX\"'m9)-NGMAaqdu)-iOoSXr8N4E$HI]*=pF5,E<of*s3_mfa%*R!u2USqhPGq)]+MW&&'8-dM?d@(QKXLc5@R]+<;7#)q\"c;\"Tni3q$.!('c-uLL^%f;(Ffs,+WJ]EE#TV%%M-i&)kn>n(BYU3!t,2E!s=#XjTYeh!!*--!!!!$!!!!Bz!!!!f!!!\"S!!!\"4!WW33!!!!4!<<,D!!!\"4!WW4i!<<,N!!!!\"!!!#G\"98GK\"98GK\"98G0!<<*(!<<+6!WW32Uuh[_@06T:@06T:%0H\\I%g2]b#&k4djp2L3,88WAE\"`bn+V2j9'BTQ@%g*Ku!=K#-!=(1Y!s^O_!u2=KqhPGq'+aL5&$?fag)4iC&$@,fc5@;L)%X;%'A=<7^*=;C(N:#ul6?hb)&)E?*=i5c'F0Nu!tG\\@`reKu&-E/V#7$[u#71J7#/()G!g*iq@06T3!!N?&zz!!`K(!\"/c,!8@PT!#Yb:!#kn<!87JS!1j/j!!SMI!='2=!s]D?!u(tB\"\"\"*P\"$Q>h!s`cM#FYZ+$NgeB#m187&H`+I]`j,sfa@c[#ljr*zz\"9ni+\"9ni+\"9ni+\"9ni+\"pP&-\"pP&-z\",c4A-3F>P#6=o/.^oTJ!k]!C!!3-#!!3-#z!!&5F!='JE!s]\\G\")nJMZ7&9L#MKXm'a\"P/!s\\p*\"54(eE!HW2.0g.]\"\"\"*P!uB_rmKTWn#8mUG!!*-(zz!!!!(!!!!+!!!#1!!!#E!!!!$J`m+>nHK't#71J7'dj+\\L^%fK-gh'b0;]H3*(0nH]*C-21GdT$6j&M>\"#k0X2t@;[N[6ah>J_CF\"'_&m6N]RU'/p1!1BUW51U8$,0/G6]0/(`\\<A-#>)G7.N.kbil-dES?c5A/#\"!&`k.gKA+#6P\\_\"8dlYE$HIa%hGf],MF\"G\\fi<P)/pfBmK4!F)'e,O*?PA.#Or#M\"2>$FnHK't#Or!#\"%:rMY6qZ=#E8`d!u2m[qhPGq,9Oc8&'c%;Xr7hb,9tbQE$HIu$kL&s,Ou=`,9Q1a&%Wo/g)4iS+6k3ac5@l#$lpDl,Hq3[!u$t:GOG\\;'M=B7',Lo<\"p:>!#L*8O!u2m[qhPGq,9MLZ&&'85JensC)'diQE$HHr!tWZp,D%!X*s3a\"`s2\\K#Oqfs!u30cqhPGq.jt$+-nhG3dMtXWO736-E&0;9$<t4J2Zm9Y#Wi,p\"#C$I\"-;pR2fL]7ar4L@*'46.\"#g<32`!6;1BX`\\>ODkT\"&C]T_#d\",O736-E&0;5(0d492Zj<f1BU#IO7361E&T`H$<s)83s/^\\#!W2orWPXk5Q_ZY&Ml4%-Skkd!aG(>1BUE/\"8N!d\"-;pR1N5-+Oqq9e+#a9-\"#C$b0/G6]0/'mL<A-\"g'hZ%\\.kbil-ghj#0;]H3*-(Nf1R]+[1Gan*>q[ue!&$\"*,ZQKN_@]DC)CmI[.jpnk&'c%CneiGq\"\"OVe!s8W?+7B7-L^%fC+3#30^*=lN(2tK?neht`)'ak<*?PC`!H8P[h@e$5W<EA+'Ft9J#KZuK!sdoi!s98[\"8dlYE$HIE-P+K?,J#%;,9MLd&%Wo/g)4iS+8Qicc5@kH-QO92,B1C\"&(VmX!ttbAM#d_5\":(1p!s98c\"8dlYE%<=$&1B3/'[dsh\"-;pR1N5-+Oqq91+#a9-\"#C$Z1Gan%8M`0\"+t#/Kd0)i>O736-E&0;9$=!'&2Zm9e#!2on\"#C$T1BZkE6j&M>\"#FmP1R8AP^'-Ft>D<PJ\"'u'c\"'mQ90*!XYScMhE09u`5^*>-]E%<<9)\\:43/(u-e-Nbk(M$3t`'d!PTL^%fC+0Gq]Xr8P=)/pfBg*%!P)'c9kT)g#9,8(Ca!^I\"\\\"Tni3XT\\e/'d!PTL^%fC+0l[nXr8Or+V2:3,MFD^,9Q=a&&'85dM<@r)C*rR&%Wo/g)4iS+,U@8^*=lV,S.$r,J#%;,9P&M&'c%;M?t:F\"!b2S%p,bY.1a/qZ4M6=\"8`<\"!seK&!s98c\"8dlYE%<<i(+:i5'[dsh\"2h_U1N5-+ef.7@as=,:6j)bU#!6cc4+[f-\"7)ul5B&hOXoSe13s/]]!C$ZO!u!Ir0/G6]0/&n4<A-#N*_O]q.kbil-`S3uc5A.d)]^:..gO0#!s98[\"8dlYE$HI]*=o_),MF#S,9PVY&'c%;[MU%B#6Q26\\gRXk#OMNoQNdtT!>D=G#MB1]!seK'!s98c\"8dlYE%<<i)CR89'[dsh\"2h_U1N5-+mK>o[O7361E&T_=(0ce'3s,`j2Zj%=2j,+aZ2m#h>I#G;\"$cr%1L2Xi0*!XYOon];0D5iI\\fiRWE%<;j)%Y\"1/'\\YG-Nbk(aThnM'd!PTL^%fC+3k*%Xr8P=)/pfBc4:H2)'c:!*?PBi!DERt#7$@oNs>ae!\"Ao.!!<3$!$M=Bz!)*@m!(R\"h!&\"<P!+H!0!6>9C!6,-A!6,-A!+u93!':/\\!-A8B!-nPE!/(=P!+>p/!\"/f-!3-#!!*TF(!*91$!87DQ!+>p/!9aOc!9aOc!4r73!;QTp!*94%!\"mE<!=.!S!s8c7!s98W\"8dlYE$$$V*\"TV(+5.TO*uiKC&'c%7MB!WU\"!7cq!s?RH#LNVU!s^C[!u2aWqhPGq*uicE&&'81dM?dD)pSp(c5@_T'-/\"o+4:0]!s8d&!s98_\"8dlYE$lm%#:M+\"'[dsh\"2h_U05rQtp'F+h_n-.0E&0<<+@H=tWs1M%2`J;Q6j)bU#!6cc40ASi\"#g<dL*\\n`>J:b8\"$cr%1L'PW2Zm@g0*>K10.R#Q/*\\E\\.kBlj9\"H/n.rZj\\p&c]nVA.Gu6j(?=#;:$L0CBreZ6;\"+>J^P&\"'u'_\"%36Pn,kIc1Gb=(>OhhS\"'_3<3s/dk1BUo91G<#a0.R#Q/(tA2.k?c\"9\"H/n.rZj\\iXudI)(5+[*?tY6#PA*\"_Z^bo\"8dlYE$$%]%hHB!+4:o8Xr8D9)/pZ:p&biN)'@i[*?,+8!Y:#.&)%m/nHkB`!sb@u!s98_\"8dlYE$lm1,q(:@'[dsh\"2h_U05rQtp'Frh!]'pH\"-;pR2fL]7Q3pje!]pKg[L5;%?3<+g?3;h_0/\"um#$i`4.f_(MRL`CK/#jCX\\fiFO-nD//dMtXW_n-.,E%`m4\"@N?Qn,kIc1Gb=(>OhhS\"'_?)3s/dk1BRV51Ys;]\"\"sa^.k`CQ.k@>(<@]S[(eVLe-S'-`,MF.Kc5A\"l-QOE6-O6UQ!s98W\"8dlYE$$%1)%XG++2S'iXr8D9)/pZ:jsL\\b)'ADrM?+Xu?Z6AXdMRrE$h\"8h#m\\!E!s8eY!s8W?,6Rh!#&kq7q@b8-VA.Gu6j(?=#;:$L0?,)%\"-;pR1N5-+Oqq8b-T;,5\"#C$41GeSA>LjlT\"'u'_\"'mE1.f_(MQ46hE/(+l!Xr8Z<-nD//dMtXW_n-.,E%`lq)f^HA1VO;d\"7)ul2fL]7jqgDfl`14OE'$.a!=/cd\"'u'_\"'mE1.f_(Mar=>2/&io.\\fiFOE$lmU!@TIq'[dsh\"-;pR05rQtQ3pje!]'p_NYaVV?3;h_!&$!W'icn?RK?bF0.R#Q/(,;8.k@n29\"lMt.rZj\\L'%t3)(4Pk*?tY6#E]/l!u2d<!QPC`*ug4S&$?fmg)4iO)la>X\\fi0L)/pZ:js(D^)'>jf58s\\H2?s?1\"p^Ot`s)VNYm(:4*U3i^!qus*`<?>G'dEhXL^%fG,MiSP/#F$/*(0nH]*C!.0/'%H6j(?=#;^<T1\\qkkhAS<T#Qljb#Ql^^>q7QY!%TR[$rnf.aoY2<)CI%S-R4ob&'c%?L)q?[\"\"+>5\"p4rB)[#tn#&kY'Q6-X?)B[ZN&&'81dM?dD)hoCEc5@_L+WVMo\"<UqP%g-Xq#YtO-[0?^8'dEhXL^%fG,OuKr/#F$/*(0nH]*C!.0/(lqDor`^#r<qb\"6g\"X\"-;pR1N5-+nd8TQ,<#^/p'*S\\>P87c\"$cr%1J]e/nHN3T(c)7urW>(]?3;h_>q7QY!%TS\"#urK+V?okt)CI%S-R5c.-nD//dMtXW_n-.,E%`m@&mNon1BRmb0*<j\\0=D*k.k`CQ.kC<6<@]TN&PB2E-S'-`,MFITc5A\"4'HJD#-O7TqRf`a-)[#tn#&kY'Xq_JY+WoDUE$$%%'G&J,+5.VR)s7GJ5Mdaq%gV2$\"6T^jkm%:m'dEhXL^%fG,Dm$\\/#F$/*-&8\"08^N5\"-;pR1N5-+Oqq9%*&ds*\"#C$F0/#+e.k`CQ.k@b3<@]SS$;.lQ-S'-`,L-N)c5A!m-ljN7-O6aZ!s98W\"7$#-*ugX^&%Wo+g)1F()BZ+#E$$$^-kFT@+.<i`)Zq0d_C3\"tLBe(#\"Tni3eHc6Z'dEhXL^%fG,N9@b/#F$/*(0min,k=_0/&Uu>J:7s\"'`2C2Zm@g0*<j\\0E)8G\"-;pR1N5-+Q3pje!]L3cQ5Mad?3;tc3%m'@-SGRi$!Z6s0*>!'\"0i/#\"7)ul05rQtjqgDfl`14GE&0;Q!=/c\\\"'mE1.f_(MqA!!\\/!^B3Xr8Z<E$lm!,7i';-cQT9,6K:ud0TmW'cR8PL^%f?)jUX<Xr8D9)/pZ:`XNI()'>.J*?.'^-P*6YnHfFL!s8f$#m18E)[#tn#&kY'V@F-^)'@QME$$$^!>!Hn+/TMg)Zq0/gB@Z]!!!E-!!!*$!!!?+z!!!f8!!!W3!!!9*!!\"AH!!#Ig!!!<+!!&&[!!%$>!!!0'!!!E/!!!E/!!)<b!!'/%!!!$\"!!!E/!!'G-!!$L0!!!]6!!!6)!!\"MN!!#+^!!!9*!!%?I!!#@e!!!3(!!!S/joG^$!s8dB!s::d'*AIW!s:7c#6P2S!s;c-'c-rWE<?;6!t,3M$O;7e#@.E6E!HWN+9sb+\"#9rd\"#:)l!s],7\")nb]iW<?D%MJqKV@\"+A>H/kd\"$cr%%n_EX$P*IS!s<KM$\\AOFp)X;H#=/Fo4h<$D#6ug_\"$cr)#6uOW!s`NB!s?%>]*Kc2!s8W*!sJu?'*&\"4zzciO1IciO1Ie,fUMe,fUMciO1IciO1Ie,fUMdK0CKdK0CK)#sX:&-)\\1BE8)5,6.]D)?9a;B`S26ciO1IciO1IciO1IciO1IzmJm4e#G1)Z#OMQp!s],7!u2=KqhPGq'+a42&&'8%dM<A)+VWQIE\"`c-)%Y\"1'BTQ@%g*IYm/dBJ!s^C[!u2=KqhPGq'+`Y-&&'8%dM?d8&'bXqc5@;H'-.Sc'.N;M!s8d&!s98K\"8dlYE\"`c-\"V7aS'A==C'+a(8&'c%+c354!!ttq,!kSR;#AjPF'b:EDL^%f3&*bMQ\\fha@)/p6\"WZVht)&&_n*=i5c&%VfI\\dSh[!X&0%#E]#h!u2=KqhPGq'+_)e&$?fag)4iC&&&hjc5@;d&028`'6\"0]MBiG7\"KMP*#IOR7!u2=KqhPGq'+^B7&%Wntg)4iC&,mmdc5@:]#TXEX'.*e`HO&(%!s98K\"8dlYE\"`bf,S.$r'>>\\%c5@;0,B+;,L+*Y9)ABh0&'c%+^*@S1&&Jbdc5@:M.3/p$'6'-9mfop2E2Ni>#Dsc;efk@M'F1lD!s8dj!WrN>%g2]b#&k4dOp2H2,89bQE\"`c%,7gpq'>>]1'+^Z>&'c%+Op2p;!u'u$Z3pa>E!HWN(N9V?#)XZ2[0$L5#K6`H!u2=KqhPGq'+`)*&$?fag)4iC&(2X4Xr7u-)/p6\"qBum\")&(FB*=i5c4gGFt#7(&+hZEsDZ3pa>E!HWN(C,p#!s8f,!WrN>%g2]b#&k4d\\fD<m+VWQIE\"`bN-kF$:'D;M=Xr7u-)/p6\"^)IU.)&'\"Q*=i5cE!HWN(N9TaMBi`3#7$8;?Est=!=&kW!<\\5\\#Isp=!u2=KqhPGq'+_5b&$?fa^*@S1&$cBMXr7u-)/p6\"SdH\"2)ABh0E\"`c!)%XG+'D;NI'+^NN&%Wntg)4iC&#pQZXr7tf,B+;,XptuF)ABh0E\"`bj\"V8<l'ClWP'+`e#&&'8%g*CVN&+USKc5@:q)]]Fk'+aX[ZNcR&4gGHZ\":&lNk5h_%W<!5/MBjtF,6seL\\cK)E!s`cM^B1PSE!NuUMBiF@\",d<f\\HE!:'b:EDL^%f3%u(Q)^*=<>(2sot\\f)+))&(^1*=i5c&,I:OdK6KNN<01a*m\"K6\"K)J)!#>P7!!<3$!#bh;z!&jlX!$_ID!;llu!(d.j!%\\*M!;QZr!*]F'!(-_d!<*$\"!/U[U!)NXq!;Z`s!2BMo!*]F'!;us!!:g9n!:g9n!:g9n!5AL6!,DQ7!;us!!;m!#!;m!#!8RVT!/1CQ!;Z`s!;6Qr!;6Qr!;6Qr!;6Qr!;H]t!;H]t!;H]t!;H]t!$)(?!1!Tb!;QZr!!T:`!=.E]!s8c7!s98K\"8dlYE\"`cE#S4'V'A=<7^*=<>(2sotc5@/<)&)-<*=i5co`<kLUBCZ(/HZ(i%g2]b#&k4dee8S>)&'_/E\"`c-%M-i&'@mg;%g*JaqZ[;.(C.&F!s8d*!s98K\"8dlYE\"`br(D!Ye'>>\\%c5@;0,B+;,U+$VU)ACgB&%Wnt^*@S1&#K@<\\fha@)%XG+'@IY8'+aLH&'c%+U+%)n!u!i'$e#?e!H88KXqu%eY5sM+@$LcqP6(uW!<WE=%g2]b#&k4d^*!s#,88K@E\"`b6(D\"e/'E0=!%g*IUefk@I\"KDKV\"9S`2]`A3;'b:EDL^%f3&)n`CXr7tf,B+;,p'_JW)&)!Q*=i5cE!OPiXqq?1!WrN0i;j#_'b:EDL^%f3&)nZA\\fha@)%XG+'@IY8'+Y9XXr7tf,B+;,iYrER)&&#?*=i5c4gGFt#B0po#Hek^#7$,3M#k!d\"4%,UR0!Hm'b:EDL^%f3&&o_&\\fha@)/p6\"[Ls+R)ACgBE\"`bn+:l12'A=^N'+`M8&&'8%nd]UP&)nB9^*=<F,S/0<'>>]1'+a49&'c%+dK(@!!tu45,7\"&P4gGI!#6tt3\":)(Gp]1U)MBnqt\\cN,R'aLQ<\"60UknH&dp'b:EDL^%f3&&';\"c5@;0,B+;,dNB(G)&'_0*=i5cE\"`J6,R9S8!s8dn!s8W?%g2]b#&k4d\\fD<a)ACgBE\"`cQ+:la8':L<i%g*J.Z3pa>#IslM!Wr\\<!s8W?%g2]b#&k4dV@!jF+VWQIE\"`cE)@rth'>>]1'+`5+&$?fa^*=0&,89VXE\"`c-&eD,`'A==C'+aXO&'c%+arMK5!tu@E*Kp_s+[*+=QN@D2#7%CJE!Mj6MBi`',mV^>#>G<p#7$(g!s98K\"8dlYE\"`bj\"V80f'A==C'+`)1&'c%+[KRZ^!u!!`\"7$+RZ3pa>#:T`W#I+C6!u2=KqhPGq'+adD&%Wntg)4iC%u(Q)Xr7tf,B+;,Xr@ns)&(^1*=i5cE!HW*,S0kZNs3N=#E])jlNIu]!j`!p#RBGo!s98K\"8dlYE\"`bf*\"TV('A==C'+`q&&'c%+Z5akq!ttpq!<^dP!!!K/!!!*$!!!?+z!!!f8!!!Z4!!(1D!!\"GJ!!\";F!!(+B!!#^n!!\"qX!!(4E!!%!=!!#Ff!!(%@!!%uY!!$%\"!!(+B!!'2&!!$4'!!(.C!!'P0!!$j9!!(4E!!(gT!!%BH!!(%@!!)lr!!%QM!!((A!!!0'!!%iU!!(4E!!!`7!!&>c!!(1D!!(FI!!\"eU!!&Vkz!!!0-",0x5));break;end;end;end;end;end;h=0b1000;while true do if not(h>=0X47__)then if not K[0X5cD]then h=(0B100_0111+-J.C(J.s(p[0X2],K[7644])+p[0X9]-K[8075]));(K)[0X5cD]=h;else h=K[0X5Cd];end;else break;end;end;F=function(z)local n=0X2c;while true do if n>27 then n=27;v=z;continue;else if n<0x2c then j=0X1;break;end;end;end;end;local H;h=(0B10_11111);while true do if not(h<0x5F)then if not not K[27848]then h=(K[0x6cc_8]);else K[0X2987]=(0X4__1+-J.J((J.D(p[0B11]-K[10801]~=p[7]and K[20029]or K[0X7585],K[0x392C])),K[15956]));K[0X593a]=-2456400685+-(J.J(K[15223])+K[12930]-p[0x8]+K[0X626A]);h=(-52+-(J.I((J.s(K[0XF52]==p[5]and K[0x4e3d]or K[0x3__904],K[7663])))-K[0x4__Ff9]));K[27848]=(h);end;continue;else H=function()local z,n=(0B1110001);repeat if z<0X71 then return n;else if z>0B11100 then n=q(v,j,j);j=(j+0X1);z=0X1c;end;end;until false;end;break;end;end;local Z=type;local B,r,u,c;h=(0X14_);while true do if h<=0x14__ then if h==13 then break;else B=(function()local z,n;for N=0B1001010,0b010000_010,0B1001 do if N==83 then j=n;else if N==74 then z,n=d("<\I4",v,j);continue;elseif N==0x5c then return z;end;end;end;end);r=function()local z,n,N=(0x24);while true do if z~=51 then n,N=d("\60\1058",v,j);j=(N);z=(0X33_);continue;else return n;end;end;end;if not K[0x1751__]then(K)[0x687c]=(-0X4cf8C510+-(h+K[27848]-p[4]-K[0X5CD__]-K[14142]));h=0X1c+-(J.s((J.s((J.I(K[0X2ec1])),K[0X01ddC])),K[7663])-K[0X5CD]);K[5969]=(h);else h=K[0X1751_];end;end;else if not(h<=0X63)then c=function()local z,n,N=0x05F;while true do if z==0B1011111 then z=(0X32);n,N=d('\x3C\100',v,j);continue;elseif z~=0X32 then else j=(N);break;end;end;return n;end;if not K[13070]then K[7957]=0X1_2D+-J.i(J.i(K[26249]+K[0X1dDc])-K[15574]);h=(-1225347442+-(J.s(K[0X6cc8]-K[0X6__87C],K[7663])+K[15223]-p[3]));(K)[0X330E]=(h);else h=(K[13070]);end;continue;else u=getfenv;if not K[10667]then h=0X9__7+-(K[14596]-K[0X6F_f_5]+K[0X593A]+K[0X373e]==K[25243]and K[0X593__a]or K[0X629b]);K[10667]=h;else h=(K[10667]);end;end;end;end;local d,zN,nN,NN;h=82;while true do if h==0X52 then d=function()local z,n=1,0;repeat local N=q(v,j,j);n=(n+(N>0B1111111 and N-0B100_00000 or N)*z);z=(z*128);j=(j+1);until(N<0X80);return n;end;if not K[0X6570]then K[0x3A0F]=(107+-J.J(J.J(K[0X2ec1],p[7],K[15223])-K[0x328__2]+K[0x4e3D],p[0X02],K[26748]));K[24610]=(4294967259+-J.i(J.C(K[26249]-h)+K[0x5F9A]));h=(2456400949+-(J.I((J.J(p[0x5]-K[3922],K[0X7093])))>=p[0X1]and K[5969]or p[0x8]));K[0X6570]=(h);else h=(K[0X6570]);end;continue;else if h==0B1001 then zN=function()local z;for n=0X17,0xa5,0B111001 do if n<0x50 then z=d();else if n>0X17 then if z>=C then return z-i;end;break;end;end;end;return z;end;if not not K[24857]then h=(K[0X61__19]);else h=(132+-((J.I(K[10667])-K[11969]==K[0X0f52]and K[0X6cC8]or K[0XF52])<K[26249]and K[14596]or K[0X2987]));(K)[24857]=h;end;continue;else if h==0X54__ then nN={[6]=0,[0X1]=0X8,[0X0]=nil,[3]=L,[0B1]=0x3,[0x4]=nil,[3]=L,[0]=nil,[0x2]=nil,[0x3]=L,[y]=6,[0X0]=0X6__,[0X4]=0x4,[7]=L,[W]=0X7,[z]=0X2,[0B1_11]=0X9,[0B11__]=0x4,[b]=0X6__,[1]=0X3};NN=R.bxor;break;end;end;end;end;local z,i,C=(function()local z=d();j+=z;return O(v,j-z,j-1);end);h=0b11_00000;while true do if not(h>0X3f)then C=(s.yield);break;else i=function(...)return x('#',...),{...};end;if not not K[0X5__7a4]then h=(K[0X57a4]);else K[0X3EB3]=(0X29+-J.I(J.U(K[0X3cD6]-K[0x6ff5],K[11969])-K[13070]));K[0X74__76]=-0X22+-(J.D(K[16592]<K[25194]and K[4455]or K[0X6119],K[28819])-K[5539]-K[14968]);h=(0B1000001+-J.C(J.i(K[0x1f15])+p[0B10]+K[0XF52]));K[22436]=h;end;continue;end;end;local s,x=(coroutine.wrap);h=(0X5C);repeat if h>0b1__011 then(k)[8460]=(g);if not K[24925]then h=0X2F+-J.s(J.J(K[0X7476]-K[0X7093],K[10801],K[0x3eb3])+K[26748],K[0x1DDc]);K[0X615__D]=(h);else h=(K[24925]);end;else if h<92 then x=nil;break;end;end;until false;local O,q,v=(L);E=nil;h=(0X1f);repeat if not(h>0X72)then if h<0X74 and h>0b101001 then v=(nil);if not not K[25569]then h=(K[25569]);else h=0B110_01__01+-((J.U(K[14968],K[0x00330E])-K[0X40D0]<p[0B1001]and K[5539]or K[4455])<p[0X8]and K[12930]or K[0x07093]);(K)[0x63e1_]=(h);end;else if h<0X29 then q=(function(z,n)local N,H,w=z[0X1],z[0X5],z[0B11];local Q;Q=function(...)local Q,b,L,A=o(H),0X1_,1;local H,f=i(...);local M,K,P,R,a,y,W,D,x=0X1,{[22644]=Q,[0x4337]=z,[0X611e]=N},(u()),1,0X0,{},({});local z,t,E,p=X(function()repeat local z=(N[M]);local N=z[0x01];M=(M+1);if N<0b11100__1 then if not(N<28)then if N>=0B101010 then if not(N>=0x31)then if N>=0X2D__ then if N<0B10111__1 then if N==0X2e then(Q)[z[5]]=(#Q[z[0B10_]]);else end;else if N~=0X30 then Q[z[5]]=(Q[z[0X2]]-z[4]);else local n,U,l,H,w=(0X73);while true do if n==0X073 then U=z;n=4294967282+-(J.i((J.G(z[0X3]>z[0B11]and N or z[0x3],n)))+N);continue;elseif n==0b110110 then l=1;n=4294967298+-J.i((J.N((J.C((J.N(z[0X2__],n)))))));elseif n~=0B11101 then else w=(0b0);break;end;end;local s,b=(0B0);n=(0X1C);local L;while true do if n~=0B0011100 then if n==75 then s*=b;n=153+-(J.I(J.G(z[0B10])==z[2]and z[0X2]or z[0b10])+n);elseif n~=0X2e then else b=k[0X7770];break;end;else b=(4503599627370495);n=(0X30b+-J.U((J.N(N+z[0B11]<z[3]and n or N,n)),n));continue;end;end;local Z,A=(k[30576]);b=(b.rrotate);local _,f;Z=Z.lrotate;local i;n=(0B1011001);while true do if n<0X064 then A=k[30576];n=(52+-((J.N(N,n)+n<=N and n or z[0x3])-N));continue;elseif n>0X64 then i=(k[0x7770]);break;else if n>89 and n<0b1110011 then A=A.bxor;n=(0B1010001_1+-(J.D((z[0X2]<z[0X02_]and n or n)-n,z[0X3])+N));end;end;end;i=(i.band);n=(0X73);while true do if not(n<0X58 and n>0x1D)then if n>54 and n<0B1110011 then f=(0X003);break;elseif n>0X58 then L=(k[30576]);n=169+-J.G(J.D(n+z[2],z[0X3_])-N,z[2],n);continue;elseif not(n<0X36_)then else H=z;n=0X0092+-J.D(n-z[0X3]+n+z[0B10],z[0X3]);end;else L=(L.bxor);n=0X7+-(J.C(z[0B10]+z[0X3])-n-z[3]);end;end;H=H[f];n=0B101;while true do if n>0B1_01 and n<0B1010010 then _=0X1_;n=(0b1010111+-J.I((J.N((z[2]~=n and z[3]or z[3])==n and n or n))));continue;elseif n>0B100000 then f=(f[_]);break;elseif not(n<32)then else f=z;n=(J.J((J.I(z[2])),N)+z[0X3]+z[0X3]);continue;end;end;n=(0x2B);while true do if n>0XF then if n<=0x15 then L=L(H,f);n=(0X71+-J.J(J.G(n,N)-n-n,n));continue;else if not(n>0X2b)then H-=f;n=(0X3E__+-((N+n<=n and z[2]or n)-N>n and n or N));continue;else H=(N);n=(95+-(J.C(n-N<z[2]and z[3]or z[0B10__])+N));continue;end;end;else if n~=0xf__ then f=(N);n=(4294967302+-J.D((J.i(J.I(z[0B10])<=z[0B10]and z[0X002]or n)),z[0B11]));continue;else i=i(L,H);break;end;end;end;n=(0x76);while true do if n<118 then H=0X1;break;elseif n>0X5D then L=(z);n=(0B0__1101__0011+-(J.J(n+n,n,z[2])+n+z[0X2_]));continue;end;end;L=(L[H]);n=0B1111000;while true do if n<0X78 then f=3;break;elseif not(n>119)then else H=z;n=(4294967366+-J.J((J.i((J.J(n==z[0X3]and n or n,N,n))))));end;end;H=(H[f]);A=A(i,L,H);i=z;L=(3);n=(0x1f);while true do if n==0x1f then i=(i[L]);n=145+-(J.D(J.G(N,n)~=n and n or n,n)==z[2]and n or n);continue;else if n==0B1110010 then Z=Z(A,i);n=(269+-(((J.G(n,n)==z[0X3]and z[2]or n)>n and n or n)+n));continue;elseif n==41 then A=z;i=0b0010;break;end;end;end;A=(A[i]);n=(47);while true do if n>0b101111 then Z=(z);A=0b11;break;elseif n<0X42_ then b=b(Z,A);n=(0B1110001+-J.g(J.D(n+n,z[2])<=n and N or n,z[0X2]));end;end;Z=Z[A];n=0X6F;while true do if n>4 then if not(n<=0B10011)then if n==0X79 then Z=(Z[A]);n=4294967293+-J.G(J.J(N+n,n)-n,n);continue;else b+=Z;n=(0X2+-(J.I(n-z[3])+n-n));continue;end;else s=(s+b);break;end;else if n==0b10 then Z=z;A=0X2;n=(0X77+-((J.i((J.C(n)))<=N and z[3]or z[0X3])-n));else b+=Z;n=0X0033+-(J.I(J.N(n,z[0x2],n)==z[0X2]and z[3]or n)+z[0b11]);continue;end;end;end;n=0X3A;while true do if n==0B111010 then w=(w+s);n=81+-J.C((J.N((J.i(N<=n and n or z[0x2__])),n)));elseif n==0B1010001 then U[l]=(w);n=(4294967419+-J.G((J.i(J.i(z[0X3])>=N and z[0X2]or n)),z[2]));elseif n==0X7C then U=(Q);n=(4294967042+-J.i(n+n+N+z[0X3]));continue;elseif n~=43 then if n==0Xe then w=0B101_;break;end;else l=z;n=(0X3f+-J.N(J.C((J.G(n,n,z[0X3])))-z[0X2],z[2],n));continue;end;end;l=(l[w]);n=(107);while true do if n>78 then w=({});n=0XD3+-(J.U(J.C(N)-z[2],z[0X2])+n);continue;elseif not(n<107)then else U[l]=(w);break;end;end;end;end;else if N<43 then(Q)[z[0B11__]]=(Q[z[0X5]]==Q[z[0x2]]);else if N~=0b101100 then(Q)[z[2]]=(Q[z[0B1_1]]~=z[0B110]);else Q[z[0b10]]=Q[z[0x3]]..Q[z[0X5]];end;end;end;else if not(N>=0X35)then if not(N<51)then if N~=0X34 then Q[z[0B10]]=(Q[z[0X3]]%Q[z[0X5]]);else(P)[z[0B110]]=Q[z[0X2]];end;else if N~=0X32 then Q[z[0X2]]=Q[z[0X5]];else Q[z[5]]=(n[z[0b10]]);end;end;else if not(N>=0X37)then if N==54 then for z=1,z[0x2]do(Q)[z]=(f[z]);end;else Q[z[0X2_]]=Q[z[0b101]]^Q[z[0x3]];end;else if N~=56 then W[b]=({[0B11]=x,[0X4]=D,[1]=A});b+=1;L=(z[0B10]);local n=s(function(...)(C)();for z,n in...do C(true,z,n);end;end);n(Q[L],Q[L+1],Q[L+0X2]);D=(n);M=(z[0x3]);else Q[z[0X3]]=(Q[z[0x2__]]~=Q[z[5]]);end;end;end;end;else if N<35 then if N<0X1f then if not(N>=0X1d)then(Q[z[0b11]])[Q[z[0X2]]]=(Q[z[0X5]]);else if N~=0X1e then for z=z[0x2],z[0x3]do Q[z]=nil;end;else Q[z[0X3]]=Q[z[5]][Q[z[0X2]]];end;end;else if not(N>=0B1000_01)then if N~=0x20 then local n,N,U=z[5],z[0x2],(z[0b11]);if N==0 then else L=n+N-0b1;end;local z,l;if N==0X1 then z,l=i(Q[n]());else z,l=i(Q[n](m(n+0X1_,Q,L)));end;if U==0X1 then L=n-0B1;else if U~=0x0 then z=n+U-0B10;L=(z+0X1);else z=z+n-0X001;L=z;end;N=0X0;for z=n,z do N+=0b1;(Q)[z]=(l[N]);end;end;else local U,l,H,w,s,b,L,Z,A,_=0x0,0X5,4503599627370495,z;while true do if l<=0X9 then if not(l>=9)then U*=H;l=4294965280+-J.g(l-N-N-l,l);else A=(k[30576]);A=(A.rshift);break;end;else if l>0X020 then H=(H.bor);l=73+-(J.N(l-N-N,l)-z[0X2]);else H=k[0X77__70];l=(114+-((l~=z[0X2]and l or l)-N+l<N and N or l));end;end;end;l=0X45;while true do if l<=0X3f then if l==0x3F then L=k[0X7770];l=0X32+-J.s(J.D((J.J(l,N)),N)+N,N);else L=L.bnot;break;end;else if l~=0B1100000 then b=k[0x7770];l=0X60+-J.g((J.G((J.I(z[0X2]<=l and N or z[0x2])),z[2])),N);continue;else b=b.rrotate;l=4294967230+-(J.s(J.i(N)-l,z[2])-z[2]);end;end;end;l=0B010001;while true do if l==0X11 then _=k[0X77__7__0];l=0B1001_101+-(J.i(l-l)-z[0X2]<l and N or l);else if l~=60 then else _=(_.bor);break;end;end;end;local f=(N);l=0B111101;while true do if not(l<0B1111000)then s=(0x1);break;else Z=(z);l=0X98+-(J.I((J.I(z[2]>=N and l or l)))>=N and N or N);end;end;Z=Z[s];l=(0X7d);while true do if l==0B1111101 then _=_(f,Z);l=0x38+-J.D(z[0B10]+l+l-z[2],N);elseif l==56 then L=L(_);l=-33+-(J.s(z[0x2],N)-l-N-z[2]);continue;elseif l==55 then _=(z);l=0x61+-J.G((J.I(l-l-l)),z[0X2],l);elseif l~=0X2A then if l==0b1 then _=_[f];b=b(L,_);l=4294967402+-(J.i((J.N((J.N(l,l)),N,N)))-l);elseif l==0B1101100 then L=z;l=(0X5b+-((J.g(N-N,z[0x2_])~=l and l or z[0B10])-l));continue;elseif l~=0X5b then else _=0X1;break;end;else f=2;l=(4294967280+-J.U(J.C(l+l)-l,N));end;end;L=L[_];b=b>=L;if not b then else f=nil;Z=nil;s=(0B1__10111);while true do if not(s<0X37 and s>0X1)then if s>0x2A then f=z;s=(0B101010);elseif not(s<0b101010)then else b=f[Z];break;end;else Z=(0X1);s=1;end;end;end;if not not b then else b=N;end;L=(z);_=0X2;l=(0B1000__011);while true do if l==0B1000011 then L=(L[_]);l=0xA9+-(J.C(l-z[0X2]-l)+l);continue;elseif l==0X46 then A=A(b,L);l=(0Xb3+-(l+l+l-l~=l and l or l));elseif l~=0B1101101 then if l==104 then b=b[L];break;end;else b=z;L=0X2;l=245+-J.U(J.G((J.J(l)),l,l)+N,N);end;end;A=A~=b;if not A then else _=(nil);for n=0X13,0B11001101,0X59 do if n>19 then A=(z[_]);break;elseif n<108 then _=2;continue;end;end;end;s=(1);if not not A then else _=(nil);Z=(nil);for n=0x41,0x0C6,0X2c do if n==109 then Z=1;break;elseif n~=0X0__041 then else _=z;end;end;A=(_[Z]);end;l=(0X38);while true do if l==0b111000 then b=z;l=4294967350+-J.g((J.i((J.g(l-l,N)))),z[2]);continue;else if l~=0b11011_1 then else L=2;break;end;end;end;b=b[L];f=9;l=(0X19__);while true do if l==0B11001 then A-=b;l=(68+-J.G((J.C(l)<l and l or l)>=N and l or N));else b=(z);break;end;end;L=(0x1);b=b[L];l=(0X59);while true do if not(l<=89)then U+=H;break;else H=H(A,b);l=215+-(J.N((J.C(l==z[2]and l or N)),l,l)+l);end;end;f+=U;w[s]=(f);w=n;l=(0x70);while true do if l>0Xf then s=(z);l=(0xf+-((N-z[0X2]+N>=l and N or N)-N));continue;elseif not(l<0X70)then else f=0X5;s=s[f];break;end;end;w=w[s];s=(Q);f=(z);U=(0X3);f=(f[U]);l=0b1011;while true do if l==0B1011 then U=(w);H=(0X01);l=(0Xb9_+-(N-N+N+N+l));elseif l==110 then U=U[H];l=(0x75+-J.g((J.I((J.C((J.s(N,z[0X2])))))),N));continue;elseif l==0X75_ then H=w;l=0B1010000+-(J.g(N,N)+l-l+z[2]);continue;elseif l~=80 then else A=(2);break;end;end;l=(0Xd);while true do if not(l>0B0__1000)then if not(l<13)then else(s)[f]=U;break;end;else H=(H[A]);U=(U[H]);l=(0x1a008__+-J.g((J.G(l+z[0B10]-l,l,z[0X2])),l));continue;end;end;end;else if N==0X22 then local N=(n[z[0X5]]);N[0X1][N[0X02]][z[0X7]]=Q[z[0X3]];else if Q[z[0B1__0__1]]~=Q[z[0b11]]then M=(z[2]);end;end;end;end;else if not(N<38)then if N<0X28 then if N==0B0100111 then if not Q[z[2]]then M=(z[0x3]);end;else repeat for z,n in y do if not(z>=0x001)then else n[1]={Q[z]};n[0X2]=(0b1);y[z]=(nil);end;end;until true;return;end;else if N==0X29 then local N=(n[z[0B101]]);(Q)[z[3]]=(N[0B01][N[0X2]]);else Q[z[0X2]]=(z[0x6]*z[0b100]);end;end;else if not(N<0X24)then if N~=0B100101 then if not(z[0X7]<Q[z[0x3]])then M=z[5];end;else local n=(z[0X2]);local N,U,l=D();if not N then else Q[n+0X1]=U;(Q)[n+0b10]=l;M=z[0X5];end;end;else(Q)[z[0B10]]=Q[z[0X3]]*z[0X6];end;end;end;end;else if N>=0B1110 then if N>=0B10101 then if N<0x18 then if not(N>=0B10110)then Q[z[0B10]]=(K[z[3]]);else if N==0B10111 then local n=z[2];(Q[n])(Q[n+0B1],Q[n+2]);L=(n-0X1);else(Q)[z[0X5]]=Q[z[0X2]]<=Q[z[0X3]];end;end;else if N>=26 then if N==0B0011011 then Q[z[0B11]]=o(z[0x2]);else local n=(z[0X3]);Q[n](m(n+0x1_,Q,L));L=(n-1);end;else if N~=25 then(Q)[z[0x5]]=(Q[z[0X3]]*Q[z[0X2]]);else Q[z[0x5]][Q[z[0X3]]]=z[0x7];end;end;end;else if not(N<17)then if N<0x1__3 then if N==0X12 then local N=z[4];local U=(N[0X2]);local H=#U;local w=H>0 and{};local s=q(N,w);l(s,P);(Q)[z[0X2]]=(s);if not w then else for z=1,H do s=U[z];N=(s[0x1]);local U=(s[2]);if N==0X0 then local n=y[U];if not not n then else n={[2]=U,[0B1]=Q};(y)[U]=n;end;w[z-0X1]=(n);elseif N==0B1 then w[z-0X1]=(Q[U]);else w[z-0x1]=n[U];end;end;end;else Q[z[5]]=Q[z[0B10]]<Q[z[0x03]];end;else if N~=0X1_4 then L=z[0X3__];Q[L]();L-=0b1;else local n=z[0X2];(Q[n])(Q[n+0X1_]);L=(n-0B1_);end;end;else if N<15 then local n,N,U=z[0b11],H-a-0X1,0X0;if not(N<0)then else N=(-0X1__);end;for z=n,n+N do(Q)[z]=(f[R+U]);U+=1;end;L=(n+N);else if N~=0X10 then Q[z[0B101]][z[7]]=z[0b100];else Q[z[0X5]]=({});end;end;end;end;else if not(N<0X7)then if N<10 then if N<8 then M=(z[0x2]);else if N~=0B1001 then local n=(z[0X5]);Q[n]=Q[n](Q[n+0X1]);L=(n);else(Q)[z[0X3]]=(NN(Q[z[2]],Q[z[0X5]]));end;end;else if N<0B1100 then if N==0Xb then repeat for z,n in y do if z>=0X1 then n[0X1]={Q[z]};n[0X02]=(0X1);(y)[z]=nil;end;end;until true;return true,z[0X3__],0;else local U,l,H,w,s,b=z,(0x0071);while true do if not(l>0X2e)then if l<=0X1c then s=(0X49);l=0B110_111+-(J.U((J.D(l,N)),l)-N-N);else b=(4503599627370495);w=(w*b);l=0B10_01111+-J.C(J.I((J.C(l)))<N and l or N);end;else if not(l<=53)then if l<=0X4_B then w=(0X0);l=(-0X1D+-(J.i((J.i(N-N)))-l));continue;else H=0X1;l=0B1_00110+-(J.D((J.s(N,N)),N)+l~=l and N or l);continue;end;else b=k[30576];break;end;end;end;b=(b.lrotate);local L,Z=k[0X77__70],k[30576];L=L.countrz;local A,_;l=(0B10_0_1001);while true do if l>0X049 then if l~=99 then Z=Z(_,A);break;else A=(N);l=(201+-(J.g(J.I(l)<l and N or l,N)~=l and l or N));continue;end;else if l==20 then _=N;l=(119+-((J.g(l,l)>=N and N or N)+l-N));else Z=Z.band;l=(-0B10101__1+-(J.J(N)-l+l-l));end;end;end;_=z;l=0X67__;while true do if l==0X067 then A=0X1__;_=(_[A]);l=0x24+-(J.i(l)-l+N~=l and N or l);elseif l~=26 then if l==49 then L=L(Z);l=0XBE+-(J.J(l)+l-N+N);else if l~=0X5__C then else Z=N;break;end;end;else Z-=_;l=4294967308+-(J.i(N+l)+l-l);continue;end;end;L=(L<Z);l=(0X73);while true do if l==115 then if not L then else _=(0B1);L=z[_];end;l=(0X40+-(J.I(N)+l-l<N and N or l));elseif l==0x36 then if not not L then else A=nil;local n;for N=88,0X10C,0B1011010 do if N>178 then L=(A[n]);elseif N<268 and N>88 then n=(0x1);elseif not(N<0xb2)then else A=(z);end;end;end;break;end;end;Z=(N);L=(L-Z);Z=(N);l=0X7d;while true do if l==125 then b=b(L,Z);l=(0XB5+-((l>=N and N or l)+l+N==l and l or l));continue;elseif l~=0X3__8 then else L=(N);break;end;end;b=(b~=L);if b then b=(N);end;l=(0X7E);while true do if l==0B1111110 then if not b then _=0X1;b=z[_];end;L=(z);l=(0x4D__+-J.J(J.g(N,N)+l+l,N));continue;elseif l==69 then Z=0X1;l=4294967382+-J.N(J.J((J.I(N)),N,N)-N);continue;elseif l~=96 then else L=L[Z];break;end;end;b=b==L;l=(89);while true do if l<0X59 then s=(s+w);break;elseif l>0x64 then w+=b;l=(0B1000000+-(J.i((J.s((J.D(l,N)),N)))>=N and N or N));continue;elseif not(l<115 and l>0B1011001)then if l<0X64 and l>0B110110 then if not b then else A=nil;_=nil;Z=0X75;while true do if Z>0x50 and Z<0X75 then b=(A[_]);break;elseif Z>0B1101111 then A=z;Z=(0b1010000);continue;elseif Z<0X6f then _=(0b1);Z=111;continue;end;end;end;l=0xc7+-((N<l and l or l)-l+N+l);end;else if not not b then else b=N;end;l=(0b1_1010111_+-J.G((N<=N and l or N)+N-N));end;end;U[H]=(s);l=(0X5b);while true do if not(l<=0B1000101)then if l~=91 then H=z;l=0Xb5+-J.N((J.C((J.s(l+N,N)))),l);continue;else U=n;l=0X16C23+-(J.g(J.s(l,N)==N and N or l,N)-l);continue;end;else s=0B101_;break;end;end;H=(H[s]);U=(U[H]);l=0x4D;while true do if l>0X48 then H=(Q);l=(0xEe+-(J.G(l-N,l)+N+l));continue;elseif l<0X4_d and l>0X7 then s=(z);l=(4294967148+-(J.i((l<=N and N or N)+l)-l));elseif l<0X48 then w=0X2;break;end;end;s=s[w];l=(0x4a);while true do if l==0X004a then w=(U);l=0x21+-(((J.D(N,N)==l and l or N)>=N and N or l)-N);elseif l~=0B10000_1 then if l~=12 then else w=(w[b]);break;end;else b=1;l=0X16+-J.J((J.N(l+l~=l and N or N)));end;end;b=U;l=0X2f;while true do if l==0x42 then b=b[L];break;else L=0X2;l=(4294967267+-J.i(N+l+l-N));end;end;w=(w[b]);l=(0X65);while true do if l>0X05F then b=z;L=4;l=(0X400065_+-(J.U((J.I((J.N(N)))),N)+l));elseif l<0B1011111 then b=b[L];w=(w[b]);l=41943135+-J.U((J.g(N+l~=l and N or N,l)),N);continue;elseif l>0 and l<0X65 then H[s]=(w);break;end;end;end;else if N==0B11_01 then Q[z[2]]=n[z[0X5]][Q[z[0x3]]];else local n=(z[0x2]);L=n+z[0b1_01]-0B1_;(Q[n])(m(n+0X1,Q,L));L=n-0X001;end;end;end;else if not(N>=0B11)then if not(N<0X1)then if N==0B10 then(Q)[z[0x2__]]=Q[z[3]]>=Q[z[0b101]];else(Q)[z[0X5]]=(Q[z[0X3]]/z[7]);end;else(Q)[z[0b10]]=(z[4]+Q[z[5]]);end;else if N>=0X5 then if N~=0B110 then local N=(n[z[0B101]]);N[1][N[0X2]]=(Q[z[0X3]]);else Q[z[0X2]]=(z[0X6]<=z[0B100]);end;else if N~=0X4 then L=(z[0b101]);(Q)[L]=Q[L]();else if not(Q[z[0B11]]<Q[z[0b1_01]])then M=z[0B10];end;end;end;end;end;end;end;else if not(N<0X55)then if not(N<0B110__0011)then if N<106 then if not(N>=0x66)then if not(N>=0B1100100)then Q[z[0X3]]=nil;else if N==0B110010__1 then Q[z[5]]=Q[z[2]]>z[0X4_];else(k)[z[0X02]]=(Q[z[0B101]]);end;end;else if N<104 then if N==0X67 then(Q)[z[3]]=(z[0B110]>=z[0x7]);else if not(Q[z[0B10]]<z[0B110])then else M=z[0B11];end;end;else if N~=0X69 then(Q)[z[3]]=(f[R]);else local n=z[0X2];Q[n]=Q[n](m(n+0X01,Q,L));L=(n);end;end;end;else if N<0x6E then if not(N<108)then if N==0B1101__101 then if Q[z[0X3]]~=z[0X7]then M=z[0b101];end;else(Q)[z[0B011]]=z[6]~=Q[z[0X2]];end;else if N~=0X6B then local n=(false);D=(D+x);if not(x<=0X0)then n=D<=A;else n=(D>=A);end;if not n then else M=z[0X2];(Q)[z[0X3]+0B11]=D;end;else repeat for z,n in y do if z>=0B1 then(n)[0B1]=({Q[z]});(n)[2]=0X1;y[z]=nil;end;end;until true;return false,z[0x2],L;end;end;else if not(N>=0X070)then if N==111 then Q[z[0X3]]=z[6]>z[0X7_];else if Q[z[0x3]]==z[0x7]then M=z[0X5];end;end;else if N~=0x71 then Q[z[2]]=Q[z[0B101]][z[0X4]];else(Q)[z[5]]=z[0x4]-z[7];end;end;end;end;else if not(N<0B1011_10__0_)then if not(N>=0X5F)then if not(N<0X5D)then if N~=0X5E then Q[z[0B11]]=(Q[z[0X2]]+Q[z[0X5_]]);else local n=(z[0X5]);(Q)[n]=Q[n](Q[n+0x1],Q[n+0b0__01_0]);L=(n);end;else(Q)[z[5]]=(not Q[z[2]]);end;else if not(N<0x61)then if N~=0X62 then local N=(n[z[0X2]]);(N[0X1])[N[0X2]]=(z[0X6]);else local N=n[z[0X3]];N[0B1][N[0B010]][z[0X6]]=z[7];end;else if N==0X60 then if Q[z[0B10]]==Q[z[5]]then M=z[3];end;else Q[z[0x2]]=(Q[z[0x5]]^z[0X4]);end;end;end;else if not(N>=88)then if not(N<0X56)then if N==87 then local n=z[5];local z=(b-n);n=W[z];for z=z,b do(W)[z]=(nil);end;D=(n[0B100]);A=(n[0x1_]);x=n[0b1__1];b=z;else(Q)[z[0X5]]=(Q[z[0X2]]<=z[0x4]);end;else Q[z[0B101]]=Q[z[0B10]]+z[4];end;else if not(N>=90)then if N==0X59 then if not(Q[z[0B10]]<=Q[z[0b11]])then M=z[5];end;else Q[z[0X3]]=(z[0X6]-Q[z[0X00__2]]);end;else if N~=0X5B then if not(Q[z[0b11]]<z[0B1_11])then M=(z[5]);end;else Q[z[0B101]]=z[0B111];end;end;end;end;end;else if N>=0b1000111 then if not(N>=0X4E)then if not(N<0B10__0__1010)then if N>=0B1001100 then if N==77 then(Q)[z[2]]=z[0x6]==Q[z[0X3]];else local n,U,l,H,w=0X4F;while true do if n==0B1001111 then l=z;n=98+-J.I((J.G((z[0B010]~=z[0X5]and n or n)+z[0x5])));elseif n~=98 then else U=0b1;H=99;break;end;end;local s,b,L;n=(8);while true do if not(n>0X47)then if n>0b1000 and n<122 then s=(4503599627370495);n=4294967275+-(J.g(J.i(z[0x5])-n,z[5])-n);elseif n<0x47 then L=0b0;n=0x4F+-J.D(n-n+n+z[0X5],z[0B0010]);end;else L=(L*s);break;end;end;local Z;n=0B1100;while true do if not(n>=123)then s=(k[0X7770]);s=(s.bnot);n=0xaB+-((N==z[0X5]and N or n)+n+n+n);else b=k[30576];break;end;end;local A,_;n=(0X4d);while true do if n>0X3A then if n<=0X48 then w=w.countrz;A=(z);Z=(1);n=0X4f+-(J.J((J.I(N)))+z[0X2]~=n and n or z[0X5]);else if n==0B1__001101 then b=b.lshift;_=(k[30576]);_=(_.lshift);w=(k[0X7770]);n=0b111000_10+-(J.G((N>=n and n or n)+z[0B10])+n);else A=z;Z=0X2;break;end;end;else if n~=0X7 then w=w(A);n=(0b1111001+-(J.G(n-z[0X5])-N+n));continue;else A=(A[Z]);n=0x33+-(J.J(z[0X2]-n+z[0x2],n,z[0x2])-n);end;end;end;A=(A[Z]);_=_(w,A);w=(z);A=2;w=(w[A]);b=b(_,w);n=0B1000110;while true do if not(n<=70)then w=0x5;break;else _=(z);n=0xb_3+-(J.U(n,z[0X5])+n-n-z[0X2]);continue;end;end;_=(_[w]);n=0X4e;while true do if n>0x30 then if not(n>=85)then b=(b+_);n=(0X56+-J.I((J.J((J.G((J.s(z[0B10],z[0X5])),n)),n))));else _=z;n=0X30__+-J.D(J.U(z[0X2],z[0X2])-z[5]-z[2],z[0b10]);continue;end;else w=0X2;break;end;end;_=_[w];b-=_;s=s(b);n=(0X2);while true do if n>61 then if n>0X6A then if n<=119 then H+=L;n=(0x6A+-J.D(J.J(n)-n+z[0X2],z[0X2]));continue;else if n==120 then L+=s;n=(0X11B+-((J.N(n,N,n)>N and n or n)+n-N));else s=s>b;n=4294967299+-J.s(J.i((J.I(n)))+z[0X2],z[0X2]);end;end;else if n<106 then b=(N);n=(137+-(J.g((J.s(z[0x5]>=n and n or n,z[0B10])),z[0B101])<=n and N or N));continue;else l[U]=H;l=Q;break;end;end;else if n>0X4 then if n<0X3d then if not s then s=(N);end;n=(0x45_+-(J.I(J.N(z[0x2],N,z[5])+z[0B101])-n));continue;else s=(s-b);n=(70+-(J.C((J.s((J.g(n,z[0X2])),z[5])))-N));end;else if n~=0B10 then if not s then else Z=(nil);A=(nil);for n=0x4e,0X13_a,118 do if n<314 and n>0X4e then A=1;continue;else if not(n>0Xc4)then if n<0Xc4 then Z=(z);continue;end;else s=(Z[A]);end;end;end;end;n=0Xf_+-(J.g((J.D(N,z[0B10])),z[0B10])-N-n);else b=N;n=(4294967340+-J.i((n+n~=z[2]and N or n)+z[0x2]));end;end;end;end;n=(0X29);while true do if n<=41 then U=z;H=(0x3);n=0X94+-J.D((J.I((J.J(n+n,z[0X5])))),z[0B101]);continue;else if n~=67 then U=(U[H]);n=(0xD0+-J.D((J.D(J.C(n)+n,z[5])),z[0b10]));else H=nil;l[U]=(H);break;end;end;end;end;else if N==0X4B then(Q)[z[0B1_0]]=(z[4]+z[6]);else(Q[z[5]])[z[0X7]]=(Q[z[0X3]]);end;end;else if N>=0X048 then if N==73 then Q[z[0B1_01]]=Q[z[2]]==z[0B100];else repeat for z,n in y do if z>=0x1 then(n)[0X1]={Q[z]};(n)[0x2]=0B1;(y)[z]=(nil);end;end;until true;local n=(z[0X5]);return false,n,n;end;else local n=z[0X2];local N=Q[n];local l=(z[5]);(U)(Q,n+1,L,l+0B1,N);end;end;else if N<0X51 then if not(N>=0B00_1001111_)then Q[z[0b101]]=(-Q[z[0B11]]);else if N==80 then W[b]={[3]=x,[4]=D,[0b1]=A};local n=z[0b101];b+=0X1__;x=(Q[n+0B10]+0b0);A=Q[n+0X1]+0b00;D=(Q[n]-x);M=z[0b11_];else if Q[z[2]]then M=z[3];end;end;end;else if not(N<0x53)then if N~=84 then local N=(n[z[0X5]]);Q[z[0b0010]]=(N[1][N[0X2]][z[0b100]]);else Q[z[5]]=Q[z[2]]>Q[z[0X3]];end;else if N==0X52 then Q[z[0X2]]=Q[z[3]]<z[0X6];else Q[z[3]]=n[z[0X2]][z[0x6]];end;end;end;end;else if not(N>=0B10000__00__)then if N>=60 then if N<0X3E then if N==61 then Q[z[3]]=P[z[0X007]];else Q[z[3]]=Q[z[2]]/Q[z[0x5]];end;else if N~=0X3f then local n=(z[0X5]);local N=Q[n];local l=z[3];(U)(Q,n+0b1,n+z[2],l+0x1,N);else local n,N=z[0X3],(Q[z[0X5]]);Q[n+0x1]=N;Q[n]=N[z[7]];end;end;else if N>=0X3a then if N~=0x3B then(n[z[0X3]])[Q[z[0X5]]]=Q[z[0X2]];else Q[z[0x03]]=(z[0X7]^Q[z[5]]);end;else repeat local n=z[5];for z,N in y do if z>=n then N[0X1]=({Q[z]});(N)[2]=0B1;(y)[z]=nil;end;end;until true;end;end;else if not(N>=0X43)then if not(N>=0x41)then local n=(z[0X3]);L=n+z[0B101]-0X1__;(Q)[n]=Q[n](m(n+1,Q,L));L=(n);else if N==0b1000010_ then repeat for z,n in y do if not(z>=0X1)then else(n)[1]={Q[z]};n[2]=0B1__;y[z]=(nil);end;end;until true;return true,z[0X5],0B1_;else Q[z[0B10]]=Q[z[0B101]]-Q[z[3]];end;end;else if not(N<0x45)then if N==0X46 then(Q)[z[0b11]]=(Q[z[0x5]]%z[0X7]);else a=(z[0x3]);for z=0X1,a do(Q)[z]=(f[z]);end;R=a+0X01;end;else if N==0X44 then Q[z[0X3]]=(k[z[0X5]]);else repeat for z,n in y do if z>=0X1 then(n)[0B001]=({Q[z]});n[2]=0X1;(y)[z]=(nil);end;end;until true;local n=z[0b11];return false,n,n+z[0X2]-0B010;end;end;end;end;end;end;end;until false;end);if not z then repeat for z,n in y do if not(z>=0x1)then else n[0B1]=({Q[z]});(n)[0X002]=1;y[z]=(nil);end;end;until true;if Z(t)=="\u{73}tr\i\z  n\u{0067}"then if _(t,':(\u{025}\d+\u{29}[\58\r\n]')then(S)('L\z \117\zr\z ap\z \x68\32S\u{063}r\105p\x74\58'..(w[M-0x1]or"(\in\x74ern\97l)")..'\58 '..T(t),0);else(S)(t,0b0);end;else S(t,0B0);end;else if t then if p==1 then return Q[E]();else return Q[E](m(E+0X1,Q,L));end;else if E then return m(E,Q,p);end;end;end;end;return Q;end);if not K[0X7318]then K[0X5b97]=(0X26+-J.C((K[0x5cd]~=K[28819]and K[0x3__73E__]or K[20473])+K[25243]==p[0B10]and K[0X1f15]or K[16051]));K[0X440a]=213+-(J.U(K[0X1DDC]-K[7644]>=K[0x1f8b]and K[11969]or K[0x060__22],h)+K[0X4E3D_]);h=(0X44CfC8b8+-J.N((J.C(J.J(p[0x6])+K[28526])),p[0x9]));K[0x7318__]=h;else h=(K[0x7318]);end;else if not(h<0X72 and h>0B0011111)then else v=(function()local z,n,N;for U=0X53,0B11000100,106 do if not(U<0xBd)then n=({});N=d()-29447;break;else z=({{},nil,{},nil,nil});end;end;local U,l=0X1,z[0x00__1];for z=0b1,N do local n,N,U,H,w,s,Q,L=53;while true do if n>16 and n<0X35 then l[z]=({[0X3]=nil,[0X7]=L,[0b1]=nil,[0X3]=(w-s)/4,[W]=nil,[b]=(H-Q)/0X4,[0x4]=nil,[0B10]=nil,[0X6]=Q,[0X4]=s,[0X2]=(U-L)/0X4,[0X1]=N});break;elseif n>0X2F then n=(0X10);N,U,H,w=zN(),zN(),zN(),zN();continue;elseif not(n<0X2f)then else n=0B101111;s,Q,L=w%4,H%4,U%4;end;end;end;l=nil;local H=(74);repeat if not(H<=0X21_)then if H<=0B1001010 then H=(33);for n=0B1,N do local N=(z[1][n]);for z,U in I do n=nil;z=nil;local l,H=(0X57);while true do if l==74 then z=N[U];H=(N[n]);if H==W then local U,l;for H=79,292,0X59 do if H<=79 then U=V[z];else if H==257 then if l then local z;for U=0X67,0X114,0X34 do if U~=0B10011011 then if U==0X67 then(N)[n]=(l[0X1]);continue;elseif U==0XCf then z[#z+0X1]=({N,n});break;end;else z=(l[0x02]);continue;end;end;end;break;else l=x[U];continue;end;end;end;elseif H==1 then(N)[U]=(z+0B1__);elseif H~=0x0 then else local U=O[z];for l=0B10000_1,0B10001110,109 do if not(l<=0B10__0001)then U[#U+0x1]={N,n};else if not U then for n=0X57,0x9C,0b1000101 do if not(n<=0X57)then O[z]=(U);else U=({});end;end;end;continue;end;end;end;break;else n=(nN[U]);l=0X4a;end;end;end;end;continue;else if not(H<=0X65)then H=(30);for z=0x1,B()do z=nil;local n;for N=118,333,0X30 do if not(N<=0B1110110)then if N>=0XD6 then if z%w~=0X0 then local z,N=(13);while true do if z<=0B1000 then for z=n-n%0X1_,U do(l)[z]=(N);end;break;else z=(0x8);U=B();N=B();continue;end;end;else l[U]=(n-n%0X1);end;break;else n=(z/0B10);end;else z=B();continue;end;end;U+=0X1;end;continue;else return z;end;end;elseif H>0Xc then if H<=0B11110 then z[0X5]=d();H=(0B1100101);continue;else H=(0XC);z[4]=d();continue;end;else H=0b1__111011;z[2]=n;l=z[D];for z=0B001,d()do local N,U;for l=94,0x79,27 do if l<0x79 then N=d();U=N/0X4;elseif not(l>0B1011110)then else(n)[z]={[0X1]=N%0X4,[0X2]=U-U%0X1_};end;end;end;continue;end;until false;end);if not not K[0x2bCC]then h=K[0x2BCc];else h=(173+-(J.I((J.i(K[0X392c]+p[0X3__])))+K[0X1F8b]));(K)[0X2BcC]=(h);end;end;end;end;else E=(nil);E=(function()V={};local n,N,U,l,s=0X1,(94);while true do if N<0x5e and N>0X25 then l=d()-23259;N=0X1F;continue;else if N<0b10__0000__0 and N>0X1f then N=0B10000__00;O=({});else if not(N<37)then if not(N>0x40)then else U={};x={};N=(37);continue;end;else s=(H()~=0x0);break;end;end;end;end;for N=0X1,l do local U,l=(H());if not(U<=24)then if U>0X5d then if U==P then l=c();else l=L;end;else l=(H()==0B1);end;else if U~=24 then l=r();else l=z();end;end;(V)[N-1]=(n);N=(nil);for z=0B111100__1,0X12d,0B1011010 do if z>0Xd3 then if not s then else for z=117,0X122,0X4d do if z>117 then Y=(Y+0X1);break;else if z<0b11000010 then g[Y]=(N);end;end;end;end;else if z<301 and z>121 then x[n]=N;n=(n+0X1);continue;else if z<0B11010011 then N=({l,{}});end;end;end;end;end;l=(d()-M);for z=0X0,l-0X1 do(U)[z]=v();end;n=(nil);N=(0X21);repeat if N==0X021 then for z,n in O do s=(U[z]);if not s then else for z,z in n do z[0X1][z[w]]=s;end;end;end;N=0xC;continue;elseif N==12 then n=(U[d()]);N=(0B111_1011);continue;else if N==0X7B then V=(nil);N=(0X1e);elseif N==30 then N=0X65;x=(L);elseif N==0B1100101 then O=nil;N=(0);else if N==0 then return n;end;end;end;until false;end);break;end;until false;N=(nil);y=nil;Q=nil;h=69;while true do if not(h>0X3F)then if h<=0x1_2 then Q=(function(z)for N=0X7E,0XE7,0x5e do if N==0X7e then if Z(z)~=a then else local N;for U=0B10001__00,0B11000100,0B1111011 do if U>68 then for z,n in z do N[z]=(n);end;break;elseif not(U<0B1_0_111111)then else N=f({},{[n]=z});end;end;return N;end;continue;elseif N==0XDc then return z;end;end;end);k[15875]=Q(J.S);if not not K[0X4F4]then h=K[1268];else h=(199+-J.N((J.C((J.s(K[0X1Def]<K[0X3Cd6]and K[17418]or p[0B0011],K[0X2eC1])))),K[0X5B97],K[15956]));K[0X4F4]=(h);end;continue;else if h>0X14 then y=E();if not K[0x2e1f]then(K)[9458]=2456401068+-J.N((J.s(K[23447],K[13070])>=K[17418]and K[25569]or K[13760])+p[0x8]);(K)[16297]=0X81__+-(J.U((J.I(K[23447]-K[17418])),K[24610])>=K[20029]and K[0Xf52]or K[0X15a3__]);h=0B10010001+-(K[0X3B77_]-K[0X9FF]+K[26249]+K[1485]+K[0X6FF5]);(K)[0X2e1F]=h;else h=(K[0x2E_1f]);end;continue;else(k)[A]=Q(R);break;end;end;elseif not(h>0b1__000101)then N=function(...)return(...)();end;if not K[29883]then h=137+-(J.I((J.U(K[0X298__7]+K[0x3904],K[0X6570])))+K[4455]);K[29883]=h;else h=K[0X74bB];end;continue;else if h==0X60 then if not not K[0X62de]then h=K[0X62DE];else K[27813]=(0Xd7+-((J.i(K[15956])-K[27848]>K[0X1751]and K[0X6119]or p[0B0110])+K[24857]));(K)[13760]=(8253+-J.g((J.I((J.N((J.C(p[0x8])),K[26912])))),K[0X005B__97]));h=0X3E314D92+-J.U(((K[0X373E]<K[0X0__01D__dC]and K[0X5B97]or p[0X9])>=K[10801]and K[0X4Ff9]or p[0B1001])+p[4],K[14636]);K[0X62De]=h;end;else(k)[25978]=Q(J.r);if not K[0x6Bc3]then K[0x1e46]=0B10111_10+-((J.g((J.D(K[0X2ec1],K[23447])),K[0X6ff5_])~=K[26912]and K[0X6cA5]or K[14636])-K[2559]);h=0B10100+-J.D((J.I(J.J(K[0x629b],K[0X2EC1])-K[0x29Ab])),K[0X3_9__2C]);(K)[0X6bc3]=h;else h=K[27587];end;end;end;end;h=(0X7_B);while true do if h>30 then y=q(y,e)(E,t,G,N,c,H,B,p,F,q);if not not K[0X60Ed]then h=K[24813];else h=2008097494+-J.U(J.D(K[9458],K[32422])-p[0X4]+p[0B1000],K[28661]);K[24813]=(h);end;continue;else if not(h<0X7b)then else return q(y,e);end;end;end;end)(4,'__\z  ind\z\101\120',string,table.move,setfenv,string.gsub,0X2,coroutine,0,0X5,nil,string.pack,30576,string.match,setmetatable,9007199254740992,18468,next,0x97,bit32,3,'t\x61\x62\108e',0B1,0B1_10,0X2,0B0011,{w=string.char,C=bit32.countlz,s=bit32.lrotate,F=string.sub,g=bit32.lshift,G=bit32.bor,r=math,S=string,I=bit32.countrz,U=bit32.rrotate,D=bit32.rshift,N=bit32.bxor,f=string.unpack,J=bit32.band,i=bit32.bnot},table.create,select,function(...)(...)[...]=nil;end,{},{0xC963_,888199143,0X490_951bb,0X4Cf8C4cA_,545321088,3583802581,1905623029,2456400940,0x44cFc846})(...);

-- Test Modules Over --