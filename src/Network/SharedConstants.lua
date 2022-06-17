local EnumList = require(script.Parent.Parent.EnumList)

return EnumList.new("SharedConstants", {
	ErrorMessage = {
		InvalidArgumentType = "Invalid argument#%d to %s, expected %s, got %s instead.",
	},

	Attribute = {
		NetworkFolder = "IsNetworkFolder",
		BoundToRemoteProperty = "IsBoundToRemoteProperty",
		BoundToRemoteSignal = "IsBoundToRemoteSignal",
	},
})
