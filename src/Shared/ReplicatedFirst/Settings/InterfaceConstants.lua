local patrickHandBold = Font.new("rbxasset://fonts/families/PatrickHand.json")
patrickHandBold.Bold = true

return {
	colors = {
		menuBackground = Color3.fromHex "#E4C5B0",
		menuTitle = Color3.fromHex "#F1E3D7",
		menuGreen1 = Color3.fromHex "#687822",

		buttonBluePrimary = Color3.fromHex "#53A3BC",
		buttonBlueSecondary = Color3.fromHex "#3D788A",
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
