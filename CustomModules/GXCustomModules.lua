-- Custom Modules --

-- Blatant Modules --

function IsAlive(plr)
    plr = plr or lplr
    if not plr.Character then return false end
    if not plr.Character:FindFirstChild("Head") then return false end
    if not plr.Character:FindFirstChild("Humanoid") then return false end
    if plr.Character:FindFirstChild("Humanoid").Health < 0.11 then return false end
    return true
end

run(function()
    local AntiHit = {Enabled = false}
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
										if TargetDistance < 25 then
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
													task.wait(0.15)
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
end)

-- Blatant Modules Over -- 



-- Movement Modules --



-- Movement Modules Over -- 



-- Tween Teleportation Modules --

run(function()
    local CollectionService = game:GetService("CollectionService")
    local TweenService = game:GetService("TweenService")
    local player = game.Players.LocalPlayer
	
    local BedTPPosition = nil
    local TweenSpeed = 0.7
    local HeightOffset = 10
    local BedTP = {}

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
            local beds = CollectionService:GetTagged('bed')

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
    local player = game.Players.LocalPlayer
    local TweenService = game:GetService("TweenService")

    local PlayerTPPosition = nil
    local TweenSpeed = 0.7
    local HeightOffset = 5
    local PlayerTP = {}

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
	local Player = game.Players.LocalPlayer
	local TweenService = game:GetService("TweenService")

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

	Player.CharacterAdded:Connect(onCharacterAdded)

	local function setTeleportPosition()
		local UserInputService = game:GetService("UserInputService")
		local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

		if isMobile then
			warningNotification("Notifier", "Please tap on the screen to set TP position.", 3)
			local connection
			connection = UserInputService.TouchTapInWorld:Connect(function(inputPosition, processedByUI)
				if not processedByUI then
					local mousepos = Player:GetMouse().UnitRay
					local rayparams = RaycastParams.new()
					rayparams.FilterDescendantsInstances = {workspace.Map, workspace:FindFirstChild("SpectatorPlatform")}
					rayparams.FilterType = Enum.RaycastFilterType.Whitelist
					local ray = workspace:Raycast(mousepos.Origin, mousepos.Direction * 10000, rayparams)
					if ray then 
						DeathTPPos = ray.Position 
						warningNotification("Notifier", "Teleportation Started.", 3)
						killPlayer(Player)
					end
					connection:Disconnect()
					deathtpmod["ToggleButton"](false)
				end
			end)
		else
			local mousepos = Player:GetMouse().UnitRay
			local rayparams = RaycastParams.new()
			rayparams.FilterDescendantsInstances = {workspace.Map, workspace:FindFirstChild("SpectatorPlatform")}
			rayparams.FilterType = Enum.RaycastFilterType.Whitelist
			local ray = workspace:Raycast(mousepos.Origin, mousepos.Direction * 10000, rayparams)
			if ray then 
				DeathTPPos = ray.Position 
				warningNotification("Notifier", "Teleportation Started.", 3)
				killPlayer(Player)
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
							return Player.leaderstats.Bed.Value == '✅' 
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
        local healthbar = Player.PlayerGui.hotbar["1"].HotbarHealthbarContainer.HealthbarProgressWrapper["1"]
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
                    table.insert(HealthbarVisuals.Connections, Player.PlayerGui.DescendantAdded:Connect(function(descendant)
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
				AvaiableThemes[SelectedTheme["Value"]]() -- DO NOT FORGET
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
end)

-- Visual Modules Over --



-- Test Modules --



-- Test Modules Over --