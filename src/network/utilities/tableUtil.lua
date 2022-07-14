local tableUtil = {}

function tableUtil.deepCopy(tabl: { [any]: any }): { [any]: any }
	local deepCopiedTable = {}

	for key, value in tabl do
		deepCopiedTable[key] = if typeof(value) == "table" then tableUtil.deepCopy(value) else value
	end

	return deepCopiedTable
end

function tableUtil.reconcileDeep(tabl: { [any]: any }, template: { [any]: any }): { [any]: any }
	local reconciled = tableUtil.deepCopy(tabl)

	for key, value in template do
		local tablValue = tabl[key]

		if typeof(tablValue) == "table" then
			tablValue = tableUtil.reconcileDeep(tablValue, template[key])
		end

		reconciled[key] = tablValue or if typeof(value) == "table" then tableUtil.deepCopy(value) else value
	end

	return reconciled
end

return table.freeze(tableUtil)
