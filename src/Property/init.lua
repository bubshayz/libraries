--[=[ 
    @class Property

    A class for wrapping values around setters and getters. A property in layman's terms is simply an object which contains some value.
 
    ```lua
    local property = Property.new(5)
    print(property:get()) --> 5

    property.updated:Connect(function(newValue)
        print(newValue) --> 10
    end)

    property:set(10) 
    ```
]=]

--[=[ 
    @prop updated Signal <newValue: any>
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
    @readonly

    An exported Luau type of a property object.
]=]

local Signal = require(script.Parent.Signal)

local Property = { __index = {} }

--[=[
    @return Property

    A constructor method that creates a new property object, with `initialValue` as the current value
    of the property.
]=]

function Property.new(initialValue: any): Property
	return setmetatable({
		updated = Signal.new(),
		_value = initialValue,
	}, Property)
end

--[=[
    A method that returns a boolean indicating if `self` is a property or not.
]=]

function Property.is(self: any): boolean
	return getmetatable(self) == Property
end

--[=[
    @tag Property Instance

    Sets the value of the property to `value`, if this new value isn't the same as the previous value. 
]=]

function Property.__index:set(value: any)
	if self._value == value then
		return
	end

	self._value = value
	self.updated:Fire(self._value)
end

--[=[
    @tag Property Instance

    Works the same as [Property:set], except the updating of the property's value to `value` is deferred through [task.defer](https://create.roblox.com/docs/reference/engine/libraries/task#defer).
]=]

function Property.__index:deferredSet(value: any)
	if self._value == value then
		return
	end

	task.defer(function()
		self._value = value
		self.updated:Fire(value)
	end)
end

--[=[
    @tag Property Instance

    Works the same as [Property:set] except that tables aren't checked for equality, e.g:

    ```lua
    local property = Property.new()

    property.updated:Connect(function(newVal)
        warn(newVal) --> {1}
    end)

    local t = {1}

    property:forceSet(t) --> Fires off the .Updated signal (expected)

    -- This ought to not fire off the signal, but the previous and new value
    -- aren't checked for equality since they're both tables)
    property:forceSet(t) 

    -- Fires off the .Updated signal (expected as a number ~= table) 
    property:forceSet(1) 

    -- Does NOT fire off the .Updated signal, since the previous value 
    -- (a number, not a table) and the new value (a number, not a table) are the
    -- same!
    property:forceSet(1) 
    ```
]=]

function Property.__index:forceSet(value: any)
	if self._value == value and typeof(value) ~= "table" and typeof(self._value) ~= "table" then
		return
	end

	self._value = value
	self.updated:Fire(value)
end

--[=[
    @tag Property Instance

    Works almost the same as [Property:set], but never fires off the [Property.updated] signal.
]=]

function Property.__index:bulkSet(value: any)
	self._value = value
end

--[=[
    @tag Property Instance

    Returns the current value of the property.

    ```lua
    local property = Property.new()

    property:Set(5)
    print(property:get()) --> 5
    ```
]=]

function Property.__index:get(): any
	return self._value
end

--[=[
    @tag Property Instance

    Destroys the property and renders it unusable.
]=]

function Property.__index:destroy()
	self.updated:Destroy()
	setmetatable(self, nil)
end

function Property:__tostring()
	return ("[Property]: (%s)"):format(tostring(self._value))
end

export type Property = typeof(setmetatable({} :: {
	updated: any,
	_value: any,
}, Property))

return table.freeze(Property)
