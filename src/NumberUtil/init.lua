--[=[ 
	@class NumberUtil

	A utility module for working with numbers.
 
	```lua
	local NumberUtil = require(...)

	print(NumberUtil.e) --> 2.7182818284590
	print(NumberUtil.nan(3)) --> false
	```
]=]

--[=[ 
	@prop e number
	@within NumberUtil
	@readonly

	Also known as Euler's number. This is a mathematical constant approximately equal to approximately `2.7182818284590`.
]=]

--[=[ 
	@prop Phi number
	@within NumberUtil
	@readonly

	Also known as the golden ratio, equal to approximately `1.618033988749895`.
]=]

--[=[ 
	@prop Tau number
	@within NumberUtil
	@readonly

	It is the circle constant representing the ratio between circumference and radius and is equal to (2 times pi), so approximately `6.28`.
]=]

local DEFAULT_NUMBER_EPSLION = 1e-5
local INVALID_ARGUMENT_TYPE = "Invalid argument#%d to %s. Expected %s, but got %s instead."

local NumberUtil = {
	e = 2.7182818284590,
	Tau = 2 * math.pi,
	Phi = 1.618033988749895,
}

--[=[
	Interpolates `number` to `goal`, with `alpha` being the multiplier.

	```lua
	local NumberUtil = require(...)

	local num = 2
	local goal = 5

	num = NumberUtil.lerp(num, goal, 0.7)
	print(num) --> 4.1
	```
]=]

function NumberUtil.lerp(number: number, goal: number, alpha: number): number
	return number + (goal - number) * alpha
end

--[=[
	Quadraticly interpolates `number` to `goal`, with `alpha` being the multiplier.

	```lua
	local NumberUtil = require(...)

	local num = 2
	local goal = 5

	num = NumberUtil.quadraticLerp(num, goal, 0.7)
	print(num) --> 4.1
	```
]=]

function NumberUtil.quadraticLerp(number: number, goal: number, alpha: number): number
	return (number - goal) * alpha * (alpha - 2) + number
end

--[=[
	Inverse Lerp is the inverse operation of the Lerp Node. It can be used to determine what the input to a Lerp was 
	based on its output. For e.g, the value of a Lerp between `0` and `2` with `alpha` being `1` is `0.5`. Therefore the value of an Inverse Lerp between `0` and `2` with `alpha` being `0.5` is `1`.

	```lua
	local NumberUtil = require(...)

	local num = 2
	local goal = 5

	num = NumberUtil.inverseLerp(num, goal, 0.7)
	print(num) --> -0.43333333333333335
	```
]=]

function NumberUtil.inverseLerp(min: number, max: number, alpha: number): number
	return (alpha - min) / (max - min)
end

--[=[
	Maps `number` between `inMin` and `inMax`, and `outMin` and `outMax`.

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.map(1,2,3,4,5)) --> 3
	```
]=]

function NumberUtil.map(number: number, inMin: number, inMax: number, outMin: number, outMax: number): number
	return outMin + ((outMax - outMin) * ((number - inMin) / (inMax - inMin)))
end

--[=[
	Returns a boolean indicating if `number` is NaN (Not A Number). 

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.nan(0 / 0)) --> true
	```
]=]

function NumberUtil.nan(number: number): boolean
	assert(typeof(number) == "number", INVALID_ARGUMENT_TYPE:format(1, "NumberUtil.nan", "number", typeof(number)))

	return number ~= number
end

--[=[
	Returns a boolean indicating if the difference between `number` and `to` is lower than or equal to `eplsion`.

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.close(0.1 + 0.2, 0.3)) --> true
	print(NumberUtil.close(0.1 + 0.2, 0.3, 0)) --> false
	```

	- If `eplison` is not specified, then it will default to `1e-5`.
]=]

function NumberUtil.close(number: number, to: number, eplison: number?): boolean
	return math.abs(number - to) <= (eplison or DEFAULT_NUMBER_EPSLION)
end

--[=[
	Returns the `root` of `number`.

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.root(2, 3)) --> 1.2599210498948732 (same as cube root of 2)
	print(NumberUtil.root(2, 2)) --> 1.4142135623730951 (same as square root of 2)
	```
]=]

function NumberUtil.root(number: number, root: number): number
	return number ^ (1 / root)
end

--[=[
	Returns the factorial of `number`.

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.factorial(3)) --> 6
	```
]=]

function NumberUtil.factorial(number: number): number
	if number == 0 then
		return 1
	end

	return number * NumberUtil.factorial(number - 1)
end

--[=[
	Returns an array of all factors of `number`.

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.factors(2)) --> {1, 2}
	```
]=]

function NumberUtil.factors(number: number): { number }
	local factors = {}

	for index = 1, number do
		if number % index == 0 then
			table.insert(factors, index)
		end
	end

	if number == 0 then
		table.insert(factors, 0)
	end

	return table.freeze(factors)
end

--[=[
	Returns a boolean indicating if `number` is infinite. 

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.infinite(math.huge)) --> true
	```
]=]

function NumberUtil.infinite(number: number): boolean
	return math.abs(number) == math.huge
end

--[=[
	Clamps `number` to `clamp`, if `number` is greater than `max` or lower than `min`.

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.clampTo(1, 2, 5, 150)) --> 150
	```
]=]

function NumberUtil.clampTo(number: number, min: number, max: number, clamp: number): number
	if number > max or number < min then
		return clamp
	end

	return number
end

return table.freeze(NumberUtil)
