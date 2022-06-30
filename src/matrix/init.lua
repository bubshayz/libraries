--[=[
	@class matrix

	A utility module for working with matrixes. A matrix is simply an array 
	consisting of arrays, e.g:

	```lua
	local matrix = {
		{1, 1, 2},
		{1, 1, 1},
		{3, 3, 3},
	}
	```
]=]

local matrix = {}

--[=[
	Searches `matrix` row wise, and returns a value in a row which matches with
	the rest of the values of that row. E.g:

	```lua
	local matrix = {
		{1, 1, 1},
		{5, 5, 2}, 
		{0, 0, 2},
	}

	print(matrix.getMatchingRowsValue(matrix)) --> 1 (The first row is equally matched (all 1s))
	```

	Additionally, you can specify `depth` if you want to control how far the 
	method should check each row. For e.g: 

	```lua
	local matrix = {
		{1, 2, 3, 4}, 
		{5, 6, 7, 8}, 
		{1, 1, 1, 0}, 
	}

	print(matrix.getMatchingRowsValue(matrix, 3)) --> 1  (The last row's first 3 values (1s) are equally matched)
	print(matrix.getMatchingRowsValue(matrix, 4)) --> nil  (No row's first 4 values are equally matched)
	```
]=]

function matrix.getMatchingRowsValue(matrix: { { any } }, depth: number?): any
	-- Search the matrix row-wise and return a value from  a row which matches with
	-- the rest of the rows in the matrix:
	for row = 1, #matrix do
		depth = depth or #matrix[row]
		local goalRowValue = matrix[row][1]

		for index = 1, depth do
			local currentRowValue = matrix[row][index]

			if currentRowValue ~= goalRowValue then
				break
			end

			if index == depth then
				return currentRowValue
			end
		end
	end

	return nil
end

--[=[
	Searches `matrix` diagonally, and returns a value which matches with the 
	rest of the values of the arrays in `matrix`. 
	
	E.g:

	```lua
	local matrix = {
		{5, 0, 0},
		{0, 5, 0},
		{0, 0, 5},
	}

	print(matrix.getMatchingDiagonalColumnsValue(matrix)) --> 1 (A column has matching values diagonally (just 5s))
	```

	Additionally, you can specify `depth` if you want to control how far the 
	method should search `matrix` diagonally. For e.g: 

	```lua
	local matrix = {
		{2, 0, 0, 0},
		{0, 2, 0, 0},
		{0, 0, 2, 0},
		{0, 0, 0, 0},
	}

	print(matrix.getMatchingDiagonalColumnsValue(matrix, 3)) --> 2 (A column has FIRST 3 matching values diagonally (just 2s))
	```
]=]

function matrix.getMatchingDiagonalColumnsValue(matrix: { { any } }, depth: number?): any
	depth = depth or #matrix

	-- Diagonally search from the top left side of the matrix, and return a value
	-- from a column which matches with the rest of the diagonal columns in the
	-- matrix:
	local goalColumnValue = matrix[1][1]

	for index = 1, depth do
		local currentColumnValue = matrix[index][index]

		if currentColumnValue ~= goalColumnValue then
			break
		end

		if index == depth then
			return currentColumnValue
		end
	end

	-- Diagonally search from the top right side of the matrix, and return a value
	-- from a column which matches with the rest of the diagonal columns in the matrix:
	goalColumnValue = matrix[1][#matrix[1]]

	for index = 1, depth do
		local currentColumnValue = matrix[index][#matrix[index] - (index - 1)]

		if currentColumnValue ~= goalColumnValue then
			break
		end

		if index == depth then
			return currentColumnValue
		end
	end

	return nil
end

--[=[
	Searches `matrix` column wise and returns a value of a column which matches 
	with the rest of the values of that column. E.g:

	```lua
	local matrix = {
		{5, 0, 0},
		{5, 1, 0},
		{5, 0, 1},
	}

	print(matrix.getMatchingColumnsValue(matrix)) --> 5 (A column has ALL equally matching values (just 5s))
	```

	Additionally, you can specify `depth` if you want to control how far the 
	method should check each column. For e.g: 

	```lua
	local matrix = {
		{5, 0, 0},
		{5, 0, 0},
		{2, 1, 1},
	}

	print(matrix.getMatchingColumnsValue(matrix, 2)) --> 5 (A column has FIRST 2 matching values (just 5s))
	```
]=]

function matrix.getMatchingColumnsValue(matrix: { { any } }, depth: number?): any
	depth = depth or #matrix

	-- Search the matrix column wise and return a value from a
	-- column in the matrix which matches with the rest of the columns:
	for index = 1, depth do
		local goalColumnValue = matrix[1][index]

		for row = 1, depth do
			local currentColumnValue = matrix[row][index]

			if currentColumnValue ~= goalColumnValue then
				break
			end

			if row == depth then
				return currentColumnValue
			end
		end
	end

	return nil
end

return table.freeze(matrix)
