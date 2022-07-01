--[=[ 
	@class EnumList
	@__index _prototype

	A class for creating enum lists. An enum list in layman's terms is simply an object
	used to store *custom* enums inside.
 
	```lua
	local MyEnumList = EnumList.new("EnumList", {
		phoneNumber = {
			babaBoey = 123,
		}
	})

	print(MyEnumList.phoneNumber.babaBoey) --> 123
	```

	:::tip Generalization iteration!

	EnumLists are iterable, for e.g:

	```lua
	local MyEnumList = EnumList.new("EnumList", {
		test = {alphabet = "A"}
	})

	for enumName, enum in MyEnumList do
		print(enumName, enum.alphabet)
	end

	--> "test" "A"
	```
	:::

	:::warning
	EnumLists don't provide support for deep chained enums (they're *not* idiomatic, so you shouldn't be having deep chained enums anyways), 
	for e.g:

	```lua
	local MyEnumList = EnumList.new("MyEnumList", {
		t = {
			deep = {
				moreDeep = {
					b = 5
				}
			}
		}
	})

	print(MyEnumList.t.deep.moreDeep.lol) --> nil, but won't error..
	print(MyEnumList.t.deep.lo) --> nil, but won't error..
	print(MyEnumList.t.b) --> will error (as it is not a deep chain!)
	``` 
	:::
]=]

--[=[ 
	@prop EnumList Type 
	@within EnumList
	@readonly

	An exported Luau type of an EnumList object.

	```lua
	local MyEnumList : EnumList.EnumList = EnumList.new(...) 
	```
]=]

--[=[ 
	@prop name string
	@within EnumList
	@readonly

	The name of the enum list.

	```lua
	local MyEnumList = EnumList.new("My", {}) 
	print(MyEnumList.name) --> "My"
	```
]=]

local CustomEnum = require(script.CustomEnum)

local INVALID_ARGUMENT_TYPE = "Invalid argument#%d to %s. Expected %s, but got %s instead."
local INVALID_ENUM_LIST_MEMBER = '"%s" is not a valid Enum of EnumList "%s"!'
local INVALID_ENUM = 'Enum "%s" in EnumList "%s" must point to a table. Instead points to a %s!'
local INVALID_ENUM_NAME = 'Enum names in EnumList "%s" must be strings only!'

local EnumList = {
	_enumLists = {},
	_prototype = {},
}

export type EnumList = typeof(setmetatable(
	{} :: {
		name: string,
		_enums: { [string]: { [string]: any } },
	},
	EnumList
))

--[=[
	@return EnumList

	A constructor method which creates a new enum list out of `enumItems`, 
	with the name of `name`.

	```lua
	local MyEnumList = EnumList.new("Enums", {test = 123})

	print(MyEnumList.test) --> 123
	```
]=]

function EnumList.new(name: string, enums: { [string]: { [string]: any } }): EnumList
	assert(
		typeof(name) == "string",
		INVALID_ARGUMENT_TYPE:format(1, "EnumList.new", "string", typeof(name))
	)
	assert(
		typeof(enums) == "table",
		INVALID_ARGUMENT_TYPE:format(2, "EnumList.new", "table", typeof(enums))
	)

	local self = setmetatable({
		name = name,
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
	@return {[string]: CustomEnum}
	@tag EnumList instance

	Returns the enums of the enum list.
]=]

function EnumList._prototype:getEnums(): { [string]: { [string]: CustomEnum.CustomEnum } }
	return self._enums
end

function EnumList._prototype:_init()
	for enumName, enum in self._enums do
		assert(typeof(enumName) == "string", INVALID_ENUM_NAME:format(self.name))
		assert(typeof(enum) == "table", INVALID_ENUM:format(enumName, self.name, typeof(enum)))
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
		error(INVALID_ENUM_LIST_MEMBER:format(tostring(key), self.name))
	end

	return value
end

function EnumList:__tostring()
	return ("[EnumList]: (%s)"):format(self.name)
end

return table.freeze(EnumList)
