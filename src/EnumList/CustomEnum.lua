--[=[ 
	@class CustomEnum
	@__index _prototype

	A custom enum is simply just an enum in an enum list, except that it is transformed to an instance
	of this class.

	```lua
	local enumList = EnumList.new("EnumList", {
		-- This enum below will be turned into an Custom Enum instance automatically 
		-- once this enum list is created!
		PhoneNumber = { 
			BabaBoey = 123,
		}
	})

	print(enumList.PhoneNumber:getEnumItems().BabaBoey) --> 123
	```
]=]

--[=[ 
	@prop name string
	@within CustomEnum
	@readonly

	The name of the custom enum.

	```lua
	local MyEnumList = EnumList.new("My", {Test = {}}) 
	print(MyEnumList.Test.name) --> "Test"
	```
]=]

local INVALID_ENUM_MEMBER = '"%s" is not a valid EnumItem of Enum "%s"!'

local CustomEnum = { _prototype = {} }

export type CustomEnum = typeof(setmetatable(
	{} :: {
		name: string,
		_enumItems: { [string]: any },
	},
	CustomEnum
))

--[=[
	@private
]=]

function CustomEnum.new(name: string, enumItems: { [string]: any })
	local self = setmetatable({
		name = name,
		_enumItems = enumItems,
	}, CustomEnum)

	self:_init()
	return self
end

--[=[
	@tag CustomEnum instance

	Returns the enum items of the enum.

	```lua
	local enumList = EnumList.new("EnumList", {
		PhoneNumber = { -- Custom Enum
			BabaBoey = 123,
		}
	})

	local enumItems = enumList.PhoneNumber:getEnumItems()
	print(enumItems == enumList.PhoneNumber) --> true
	print(enumItems.BabaBoey) --> 123
	```
]=]

function CustomEnum._prototype:getEnumItems(): { [string]: any }
	return self._enumItems
end

function CustomEnum._prototype:_init()
	table.freeze(self)
end

function CustomEnum:__index(key)
	local enumItem = CustomEnum._prototype[key] or self._enumItems[key]

	if enumItem == nil then
		error(INVALID_ENUM_MEMBER:format(tostring(key), self.name))
	end

	return enumItem
end

function CustomEnum:__tostring()
	return ("[CustomEnum]: (%s)"):format(self.name)
end

return table.freeze(CustomEnum)
