--[=[ 
	@class EnumList
	@__index __prototype

	A class for creating enum lists. An enum list in layman's terms is simply an object
	used to store *custom* enums inside.
 
	```lua
	local enumList = EnumList.new("EnumList", {
		PhoneNumber = {
			BabaBoey = 123,
		}
	})

	print(enumList.PhoneNumber.BabaBoey) --> 123
	```

	:::tip Generalization iteration!

	EnumLists are iterable, e.g:

	```lua
	local enumList = EnumList.new("EnumList", {
		Test = {Alphabet = "A"}
	})

	for enumName, enum in enumList do
		print(enumName, enum.Alphabet)
	end

	--> "Test" "A"
	```
	:::

	:::note
	EnumLists don't provide support for deep chained enums (they're *not* idiomatic, so you shouldn't be having deep chained enums anyways), e.g:

	```lua
	local EnumList = require(...)

	local enumList = EnumList.new("EnumList", {
		Enum = {
			Deep = {
				MoreDeep = {
					Lol = 5
				}
			}
		}
	})

	print(enumList.Enum.Deep.MoreDeep.none) --> nil, but won't error..
	print(enumList.Enum.Deep.lo) --> nil, but won't error..
	print(enumList.Enum.b) --> will error (not a deep chain!)
	``` 
	:::
]=]

local CustomEnum = require(script.CustomEnum)

local INVALID_ARGUMENT_TYPE = "Invalid argument#%d to %s. Expected %s, but got %s instead."
local INVALID_ENUM_LIST_MEMBER = '"%s" is not a valid Enum of EnumList "%s"!'
local INVALID_ENUM = 'Enum "%s" in EnumList "%s" must point to a table. Instead points to a %s!'
local INVALID_ENUM_NAME = 'Enum names in EnumList "%s" must be a string only!'

local EnumList = {
	_enumLists = {},
	__prototype = {},
}

--[=[
	@return EnumList

	A constructor method which creates a new enum list out of `enumItems`, and with name `name`.

	```lua
	local EnumList = require(...)

	local enumList = EnumList.new("Enums", {Test = 123})

	print(enumList.Test) --> 123
	```
]=]

function EnumList.new(name: string, enums: { [string]: { [string]: any } }): EnumList
	assert(typeof(name) == "string", INVALID_ARGUMENT_TYPE:format(1, "EnumList.new", "string", typeof(name)))
	assert(typeof(enums) == "table", INVALID_ARGUMENT_TYPE:format(2, "EnumList.new", "table", typeof(enums)))

	local self = setmetatable({
		_name = name,
		_enums = enums,
	}, EnumList)

	self:_init()
	return self
end

--[=[
	A method which returns a boolean indicating if `self` is a enumlist or not.
]=]

function EnumList.IsA(self: any): boolean
	return getmetatable(self) == EnumList
end

--[=[
	@return {[string]: CustomEnum}
	@tag EnumList instance

	Returns the enums of the enum list.
]=]

function EnumList.__prototype:GetEnums(): { [string]: { [string]: any } }
	return self._enums
end

function EnumList.__prototype:_init()
	for enumName, enum in self._enums do
		assert(typeof(enumName) == "string", INVALID_ENUM_NAME:format(self._name))
		assert(typeof(enum) == "table", INVALID_ENUM:format(enumName, self._name, typeof(enum)))
		self._enums[enumName] = CustomEnum.new(enumName, enum)
	end

	table.insert(EnumList._enumLists, self)
	table.freeze(self)
end

function EnumList:__iter()
	return next, self._enums
end

function EnumList:__index(key)
	local value = EnumList.__prototype[key] or self._enums[key]

	if value == nil then
		error(INVALID_ENUM_LIST_MEMBER:format(tostring(key), self._name))
	end

	return value
end

export type EnumList = typeof(setmetatable({} :: {
	_name: string,
	_enums: { [string]: { [string]: any } },
}, EnumList))

return table.freeze(EnumList)
