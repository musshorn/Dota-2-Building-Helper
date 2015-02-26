-- KeyValue file de-serializer
-- Author: Myll

KVDeserializer = {}

function KVDeserializer:Init( KVTable )

	function KVTable:GetVal( key, expectedType )
		local val = KVTable[key]

		-- Evaluate val to nil if key was not found and the expectedType is bool.
		if val == nil and expectedType == "bool" then
			return false
		end

		-- Like above, but if expectedType is not a bool, evaluate to nil.
		if val == nil and expectedType ~= "bool" then
			return nil
		end

		-- Val is not nil, so get the val as a string.
		local sVal = tostring(val)

		if expectedType == "bool" then
			if sVal == "1" then
				return true;
			elseif sVal == "0" then
				return false;
			end
		end

		-- Number constitutes both floats and integers. Lua treats all numbers as floats.
		if expectedType == "number" then
			print(key .. " is " .. tonumber(val))
			return tonumber(val);
		end

		if expectedType == "string" then
			if sVal == "" then
				return nil;
			else
				return sVal;
			end
		end
	end

	-- Deserializes the table. Does not go deeper than the 1st level children.
	function KVTable:Parse()
		local newTable = {}
		for k,v in pairs(KVTable) do
			local ty = type(v)
			if ty == "table" or ty == "function" or ty == "userdata" or ty == "thread" or ty == "nil" then
				newTable[k] = v
			else
				local keyLen = string.len(k);
				local isBool = false;

				for word,_ in ipairs(StartWordsForBool) do
					if string.starts(k, word) and string.len(k) > string.len(word) then
						isBool = true;
					end
				end

				if ExactWordsForBool[k] then
					isBool = true;
				end

				if isBool then
					newTable[k] = KVTable:GetVal(k, "bool")
				else
					-- v wasn't a bool, try a number now.
					local val = tonumber(v)
					if val ~= nil then
						newTable[k] = val
					else
						-- parse v to be a string.
						newTable[k] = tostring(v)
					end
				end
			end
		end

		function newTable:TestParse(  )
			for k,v in pairs(newTable) do
				local ty = type(v)
				local str = "\t"
				if ty == "boolean" then
					str = str .. k .. " : " .. tostring(v) .. " : boolean"
				elseif tonumber(v) ~= nil then
					str = str .. k .. " : " .. v .. " : number"
				elseif ty == "table" then
					str = str .. k .. " : table"
				elseif ty == "function" or ty == "userdata" or ty == "thread" or ty == "nil" then

				else
					str = str .. k .. " : " .. tostring(v) .. " : string"
				end
				if str ~= "\t" then
					print(str)
				end
			end
		end

		return newTable;

	end

	-- ********* UTILITY FUNCTIONS **************

	local function string_starts(String,Start)
	   return string.sub(String,1,string.len(Start))==Start
	end

	return KVTable;
end


-- Keys that start with these words will be parsed as bools.
StartWordsForBool =
{
	["Can"] = true,
	["Is"] = true,
	["Has"] = true,
}

ExactWordsForBool = 
{
	-- Items
	["ItemSellable"] = true,
	["ItemRequiresCharges"] = true,
	["ItemDroppable"] = true,
	["ItemPurchasable"] = true,
	["SideShop"] = true,
	-- For BuildingHelper
	["UpdateHealth"] = true,
	["Scale"] = true,
	["PlayerCanControl"] = true,
	["Building"] = true,
	["CancelsBuildingGhost"] = true,

	-- LinearProjectile
	["HasFrontalCone"] = true,
	["ProvidesVision"] = true,
}