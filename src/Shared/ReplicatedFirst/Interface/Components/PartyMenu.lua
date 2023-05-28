local PELLET_SIZE_Y = 80
local LIST_LENGTH = 7

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"
local serverFolder = replicatedStorageShared:WaitForChild "Server"

local InterfaceConstants = require(replicatedStorageShared:WaitForChild "Constants":WaitForChild "InterfaceConstants")
local ActiveParties = require(serverFolder:WaitForChild "ActiveParties")
local PartyType = require(enumsFolder:WaitForChild "PartyType")
local outlinedMenu = require(componentsFolder:WaitForChild "OutlinedMenu")
local bannerButton = require(componentsFolder:WaitForChild "BannerButton")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Hydrate = Fusion.Hydrate
local Ref = Fusion.Ref
local Children = Fusion.Children
local Cleanup = Fusion.Cleanup
local Out = Fusion.Out
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Attribute = Fusion.Attribute
local AttributeChange = Fusion.AttributeChange
local AttributeOut = Fusion.AttributeOut
local Value = Fusion.Value
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs
local ForKeys = Fusion.ForKeys
local ForValues = Fusion.ForValues
local Observer = Fusion.Observer
local Tween = Fusion.Tween
local Spring = Fusion.Spring
local peek = Fusion.peek
local cleanup = Fusion.cleanup
local doNothing = Fusion.doNothing

type CanBeState<T> = Fusion.CanBeState<T>
-- #endregion

export type Props = {
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	Size: CanBeState<UDim2>?,
	ZIndex: CanBeState<number>?,

	onExitRequest: (any) -> nil,
}

type PartyPelletProps = {
	Index: number,
}

--[[
	This component creates a party list.
]]
local function Component(props: Props)
	local partiesPink = InterfaceConstants.colors.partiesPink

	local function partyPellet(partyPelletProps: PartyPelletProps)
		local index = partyPelletProps.Index

		local partyEnum = Computed(function(use)
			local list = ActiveParties.generatePartyList(LIST_LENGTH, nil, use)
			local partyUnit = list[index]

			return partyUnit.partyType
		end)

		local button = bannerButton {
			Name = "PartyPellet" .. index,
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, PELLET_SIZE_Y),
			
			RoundnessPixels = 0,
		}
	end

	local frame = outlinedMenu {
		Name = "PartyMenu",
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		OutlineColor = partiesPink,
		TitleText = "Parties",

		onExitButtonClicked = props.onExitRequest,

		InnerChildren = {
			New "UIPadding" {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 32),
				PaddingBottom = UDim.new(0, 24),
			},
		},
	}

	return frame
end

return Component
