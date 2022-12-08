local Lighting = game:GetService("Lighting")

local sky = Instance.new("Sky")
sky.Name = "Sky"
sky.MoonTextureId = "rbxassetid://6444320592"
sky.SkyboxBk = "rbxassetid://6444884337"
sky.SkyboxDn = "rbxassetid://6444884785"
sky.SkyboxFt = "rbxassetid://6444884337"
sky.SkyboxLf = "rbxassetid://6444884337"
sky.SkyboxRt = "rbxassetid://6444884337"
sky.SkyboxUp = "rbxassetid://6412503613"
sky.SunAngularSize = 11
sky.SunTextureId = "rbxassetid://6196665106"

local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "Atmosphere"
atmosphere.Color = Color3.fromRGB(199, 199, 199)
atmosphere.Decay = Color3.fromRGB(106, 112, 125)
atmosphere.Density = 0.3
atmosphere.Offset = 0.25

local bloom = Instance.new("BloomEffect")
bloom.Name = "Bloom"
bloom.Intensity = 1
bloom.Threshold = 2

local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.Name = "DepthOfField"
depthOfField.FarIntensity = 0.1
depthOfField.InFocusRadius = 30
depthOfField.Enabled = false

local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "SunRays"
sunRays.Intensity = 0.01
sunRays.Spread = 0.1

sky.Parent = Lighting
atmosphere.Parent = Lighting
bloom.Parent = Lighting
depthOfField.Parent = Lighting
sunRays.Parent = Lighting

Lighting.Ambient = Color3.fromRGB(166, 0, 188)
Lighting.Brightness = 3
Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1
Lighting.GlobalShadows = true
Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
Lighting.ShadowSoftness = 0.2
Lighting.ClockTime = 14
