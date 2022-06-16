--[=[ 
	@class EnumList
	@__index _prototype

	A class for creating enum lists. An enum list in layman's terms is simply an object
	used to store *custom* enums inside.
 
	```lua
	local MyEnumList = EnumList.new("EnumList", {
		PhoneNumber = {
			BabaBoey = 123,
		}
	})

	print(MyEnumList.PhoneNumber.BabaBoey) --> 123
	```

	:::tip Generalization iteration!

	EnumLists are iterable, e.g:

	```lua
	local MyEnumList = EnumList.new("EnumList", {
		Test = {Alphabet = "A"}
	})

	for enumName, enum in MyEnumList do
		print(enumName, enum.Alphabet)
	end

	--> "Test" "A"
	```
	:::

	:::note
	EnumLists don't provide support for deep chained enums (they're *not* idiomatic, so you shouldn't be having deep chained enums anyways), e.g:

	```lua
	local EnumList = require(...)

	local MyEnumList = EnumList.new("MyEnumList", {
		Enum = {
			Deep = {
				MoreDeep = {
					Lol = 5
				}
			}
		}
	})

	print(MyEnumList.Enum.Deep.MoreDeep.none) --> nil, but won't error..
	print(MyEnumList.Enum.Deep.lo) --> nil, but won't error..
	print(MyEnumList.Enum.b) --> will error (not a deep chain!)
	``` 
	:::
]=]

--[=[ 
	@prop EnumList Type 
	@within EnumList
	@tag Luau Type
	@readonly

	An exported Luau type of an EnumList object.

	```lua
	local EnumList = require(...)

	local MyEnumList : EnumList.EnumList = EnumList.new(...) 
	```
]=]

local CustomEnum = require(script.CustomEnum)

local INVALID_ARGUMENT_TYPE = "Invalid argument#%d to %s. Expected %s, but got %s instead."
local INVALID_ENUM_LIST_MEMBER = '"%s" is not a valid Enum of EnumList "%s"!'
local INVALID_ENUM = 'Enum "%s" in EnumList "%s" must point to a table. Instead points to a %s!'
local INVALID_ENUM_NAME = 'Enum names in EnumList "%s" must be a string only!'

local EnumList = {
	_enumLists = {},
	_prototype = {},
}

--[=[
	@return EnumList

	A constructor method which creates a new enum list out of `enumItems`, 
	with the name of `name`.

	```lua
	local EnumList = require(...)

	local MyEnumList = EnumList.new("Enums", {Test = 123})

	print(MyEnumList.Test) --> 123
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

function EnumList.is(self: any): boolean
	return getmetatable(self) == EnumList
end

--[=[
	@return string
	@tag EnumList instance

	Returns the name of the enum list.
]=]

function EnumList._prototype:getName(): string
	return self._name
end

--[=[
	@return {[string]: CustomEnum}
	@tag EnumList instance

	Returns the enums of the enum list.
]=]

function EnumList._prototype:getEnums(): { [string]: { [string]: any } }
	return self._enums
end

function EnumList._prototype:_init()
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
	local value = EnumList._prototype[key] or self._enums[key]

	if value == nil then
		error(INVALID_ENUM_LIST_MEMBER:format(tostring(key), self._name))
	end

	return value
end

function EnumList:__tostring()
	return ("[EnumList]: (%s)"):format(self._name)
end

export type EnumList = typeof(setmetatable({} :: {
	name: string,
	_enums: { [string]: { [string]: any } },
}, EnumList))

return table.freeze(EnumList)
