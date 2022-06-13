--[=[ 
	@class Property

	A class for wrapping values around setters and getters. A property in layman's terms, is simply a object which contains some value.
 
	```lua
	local Property = require(...)

	local property = Property.new(5)
	print(property:Get()) --> 5

	property.Updated:Connect(function(newValue)
		print(newValue) --> 10
	end)

	property:Set(10) 
	```
]=]

--[=[ 
	@prop Updated Signal <newValue: any>
	@within Property
	@readonly
	@tag Signal
	@tag Property Instance

	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the value of the property is 
	set to a new one. The signal is only passed the new value as the only argument.
]=]

--[=[ 
	@prop Property Type 
	@within Property
	@tag Luau Type
	@readonly

	An exported Luau type of a property object.

	```lua
	local Property = require(...)

	local property: Property.Property = Property.new(...) 
	```
]=]

local Signal = require(script.Parent.Signal)

local Property = { __index = {} }

--[=[
	@return Property

	A constructor method which creates a new property object, with `initialValue` as the current value
	of the property.
]=]

function Property.new(initialValue: any): Property
	return setmetatable({
		Updated = Signal.new(),
		_value = initialValue,
	}, Property)
end

--[=[
	A method which returns a boolean indicating if `self` is a property or not.
]=]

function Property.IsA(self: any): boolean
	return getmetatable(self) == Property
end

--[=[
	@tag Property Instance

	Sets the value of the property to `value`, if this new value isn't the same as the previous value. 
]=]

function Property.__index:Set(value: any)
	if self._value == value then
		return
	end

	self._value = value
	self.Updated:Fire(self._value)
end

--[=[
	@tag Property Instance

	Works exactly the same as [Property.Set], except the updating of the property's value to `value` is deferred through [task.defer](https://create.roblox.com/docs/reference/engine/libraries/task#defer).
]=]

function Property.__index:DeferredSet(value: any)
	if self._value == value then
		return
	end

	task.defer(function()
		self._value = value
		self.Updated:Fire(value)
	end)
end

--[=[
	@tag Property Instance

	Works exactly the same as [Property.Set] except that tables aren't checked for equality, e.g:

	```lua
	local Property = require(...)

	local property = Property.new()

	property.Updated:Connect(function(newVal)
		warn(newVal) --> {1}
	end)

	local t = {1}
	property:ForceSet(t) --> Fires off the .Updated signal (expected)
	property:ForceSet(t) --> Fires off the .Updated signal (this ought to not fire off the signal, but the previous and new value aren't checked for equality since they're both tables)

	property:ForceSet(1) --> Fires off the .Updated signal (expected as a number ~= table)
	property:ForceSet(1) --> DOES NOT fire off the .Updated signal, since the previous value (a number, not a table) and the new value (a number, not a table) are the same!
	```
]=]

function Property.__index:ForceSet(value: any)
	if self._value == value and typeof(value) ~= "table" and typeof(self._value) ~= "table" then
		return
	end

	self._value = value
	self.Updated:Fire(value)
end

--[=[
	@tag Property Instance

	Works almost exactly the same as [Property:Set], but never fires off the [Property.Updated] signal.
]=]

function Property.__index:BulkSet(value: any)
	self._value = value
end

--[=[
	@tag Property Instance

	Returns the current value of the property.

	```lua
	local Property = require(...)

	local property = Property.new()

	property:Set(5)
	print(property:Get()) --> 5
	```
]=]

function Property.__index:Get(): any
	return self._value
end

--[=[
	@tag Property Instance

	Destroys the property and renders it unusable.
]=]

function Property.__index:Destroy()
	self.Updated:Destroy()
	setmetatable(self, nil)
end

export type Property = typeof(setmetatable({} :: {
	Updated: any,
	_value: any,
}, Property))

return Property
