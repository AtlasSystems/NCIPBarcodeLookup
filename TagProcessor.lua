local TagProcessorInternal = {};

-- Import the LogManager type
types["log4net.LogManager"] = luanet.import_type("log4net.LogManager");

-- Create a logger
local log = types["log4net.LogManager"].GetLogger(rootLogger .. ".TagProcessor");

TagProcessor = TagProcessorInternal;

local function MapFieldValue(fieldDefinition)
	if (fieldDefinition) then
		log:Debug("[TagProcessor] Mapping FieldValue for " .. fieldDefinition);
		local separatorIndex = string.find(fieldDefinition, "%.");

		if (separatorIndex and separatorIndex > 0) then
			local table = string.sub(fieldDefinition, 1, separatorIndex - 1);
			local field = string.sub(fieldDefinition, separatorIndex + 1);

			local value = nil;

			if (table == "Setting") then
				log:Debug("[TagProcessor] Getting TableField. Setting: " .. field);
				value = GetSetting(field);
			else
				log:Debug("[TagProcessor] Getting TableField. Table: ".. table .. ". Field: " .. field .. ".");
				value = GetFieldValue(table, field);
			end

			if (value == null) then
				log:Debug("[TagProcessor] Replacement value is null.");
				value = "";
			end

			return value;
		end
	end

	return "";
end

local function ReplaceTag(input)
    log:Debug('Process tag replacements for '..input);

    if (input:sub(1,11):lower() == "tablefield:") then
        return MapFieldValue(input:sub(12));
		elseif (input:sub(1,15):lower() == "pickuplocation:") then
				log:DebugFormat("[TagProcessor] Retrieving pickup location for {0}.", input:sub(16));
				--Handle Case-Sensitive Locations by creating a copy of the locations with lowercase keys
				local lowercaseLocations = { }
				for k, v in pairs(DataMapping.PickupLocations) do lowercaseLocations[k:lower()] = v end

				local pickupLocation = lowercaseLocations[MapFieldValue(input:sub(16)):lower()];
				if (pickupLocation == nil) then
		      error({message="Pickup Location mapping is undefined"});
		    end
				return pickupLocation;
		else
        return '';
    end
end

local function ReplaceTags(input)
    return input:gsub( '{(.-)}', function( token ) return ReplaceTag(token) end )
end

-- Exports
TagProcessor.ReplaceTags = ReplaceTags;
