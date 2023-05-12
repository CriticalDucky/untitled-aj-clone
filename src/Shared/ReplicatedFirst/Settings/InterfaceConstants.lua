local patrickHandBold = Font.new("rbxasset://fonts/families/PatrickHand.json")
patrickHandBold.Bold = true

return {
	colors = {
		menuBackground = Color3.fromRGB(228, 197, 176),
		menuTitle = Color3.fromRGB(241, 227, 215),
		menuGreen1 = Color3.fromRGB(104, 120, 34),
		settingsBlue = Color3.fromRGB(70, 101, 120),

		buttonBluePrimary = Color3.fromRGB(83, 163, 188),
		buttonBlueSecondary = Color3.fromRGB(61, 120, 138),

		floatingIconButtonNormal = Color3.fromRGB(10, 66, 104),
		floatingIconButtonHover = Color3.fromRGB(37, 91, 128),
		floatingIconButtonPress = Color3.fromRGB(47, 114, 158),
	},

	fonts = {
		body = {
			font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
			size = 20,
		},
		header = {
			font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
			size = 20,
		},
		button = {
			font = patrickHandBold,
			size = 36,
		},
		thickTitle = {
			font = patrickHandBold,
			size = 60,
		},
	},
}
