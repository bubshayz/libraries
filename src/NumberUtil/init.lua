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
	@prop e number <2.7182818284590>
	@within NumberUtil
	@readonly

	A mathematical constant, also known as Euler's number. 
]=]

--[=[ 
	@prop Phi number <1.618033988749895>
	@within NumberUtil
	@readonly

	A mathematical constant, also known as the golden ratio.
]=]

--[=[ 
	@prop Tau number <6.283185307179586>
	@within NumberUtil
	@readonly

	A mathematical constant, it is the circle constant representing the ratio between circumference and radius.
]=]

--[=[ 
	@prop G number <6.6743e-11>
	@within NumberUtil
	@readonly

	A mathematical constant, used in calculating the gravitational attraction between two objects.
]=]

local DEFAULT_NUMBER_EPSLION = 1e-5
local INVALID_ARGUMENT_TYPE = "Invalid argument#%d to %s. Expected %s, but got %s instead."
local NUMBER_SUFFIXES = {
	"K",
	"M",
	"B",
	"t",
	"q",
	"Q",
	"s",
	"S",
	"o",
	"n",
	"d",
	"U",
	"D",
	"T",
	"Qt",
	"Qd",
	"Sd",
	"St",
	"O",
	"N",
	"v",
	"c",
}

local NumberUtil = {
	e = 2.7182818284590,
	Tau = 2 * math.pi,
	Phi = 1.618033988749895,
	G = 6.6743e-11,
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
	Returns the average of `...` numbers against `sum`.

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.inverseLerp(100, 50, 25)) --> 0.75
	```
]=]

function NumberUtil.average(sum: number, ...: number): number
	local accumulatedSum = 0

	for _, number in { ... } do
		accumulatedSum += number
	end

	return accumulatedSum / sum
end

--[=[
	Return a string as the formatted version of `number`. 

	:::warning
	This method will struggle to format numbers larger than `10^66`.
	:::

	```lua
	local NumberUtil = require(...)

	print(NumberUtil.format(1650)) --> "1.65K"
	```
]=]

function NumberUtil.format(number: number): string
	local formattedNumberSuffix = math.floor(math.log(number, 1e3))

	return ("%.2f"):format(number / math.pow(10, formattedNumberSuffix * 3)):gsub("%.?0+$", "")
		.. (NUMBER_SUFFIXES[formattedNumberSuffix] or "")
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
