local tableUtil = {}

function tableUtil.deepCopy(tabl)
	local deepCopiedTable = {}

	for key, value in tabl do
		deepCopiedTable[key] = if typeof(value) == "table" then tableUtil.deepCopy(value) else value
	end

	return deepCopiedTable
end

function tableUtil.reconcileDeep(tabl, template)
	local reconciled = tableUtil.deepCopy(tabl)

	for key, value in template do
		local tablValue = tabl[key]

		if typeof(tablValue) == "table" then
			tablValue = tableUtil.reconcileDeep(tablValue, template[key])
		end

		reconciled[key] = tablValue
			or if typeof(value) == "table" then tableUtil.deepCopy(value) else value
	end

	return reconciled
end

return tableUtil
