NcipLookup = {};

-- Load the .Net types that we will be using.
local types = {};
types["log4net.LogManager"] = luanet.import_type("log4net.LogManager");

local log = types["log4net.LogManager"].GetLogger(rootLogger .. ".NcipLookup");
local allowOverwriteWithBlankValue = nil;
local fieldsToImport = nil;
local requestType = nil;

local function InitializeVariables(responderUrl, agencyId, overwriteWithBlankValue, toImport)
    NcipMessaging.ResponderUrl = responderUrl;
    NcipMessaging.AgencyId = agencyId;
    allowOverwriteWithBlankValue = overwriteWithBlankValue;
    fieldsToImport = toImport;
    if(product == "ILLiad") then
        requestType = GetFieldValue("Transaction","RequestType");
    end
end

local function DoLookup( itemBarcode )
    local succeeded, response = pcall(NcipMessaging.LookupItem, itemBarcode);

    if not succeeded then
        log:Error("Error performing lookup");
        return nil;
    end

    return PrepareLookupResults(response);
end

function PrepareLookupResults(response)
    if (response.Items.Length > 1 and response.Items[1]:GetType():ToString() == "AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemOptionalFields") then
        log:Debug("Item Response");
        local lookupResults = {};

        for i, fieldMapping in ipairs(DataMapping.FieldMapping[product]) do
            for j, fieldToImport in ipairs(fieldsToImport) do
                local success, result = pcall(function()
                -- If the field we're importing is on the Fields To Import list, import it
                    if(string.lower(Utility.Trim(fieldToImport)) == string.lower(fieldMapping.MappingName)) then
                        local destination = LookupUtility.GetValueDestination(fieldMapping, requestType);
                        local toImport = GetValueToImport(fieldMapping, response);
                        -- If overwrite with blank value is false and the value to import is nil or empty, return
                        if(not allowOverwriteWithBlankValue and (toImport == nil or toImport == "") ) then
                            return;
                        end
                        table.insert( lookupResults, {
                            valueDestination = destination;
                            valueToImport = toImport;
                        });
                    end
                end)
                if not success then
                    log:Warn(result.Message or result);
                end
            end
        end

        return lookupResults;
    elseif (response.Items[0]:GetType():ToString() == "AtlasSystems.Interchange.Ncip.v2.DataObjects.Problem") then
        log:Debug("Problem Response");
        local problemResponse = response.Items[0];

        log:ErrorFormat("NCIP Error {0}: {1}", problemResponse.ProblemType.Value, problemResponse.ProblemDetail);

        if (problemResponse.ProblemDetail == "Unknown Item") then
            log:Error("No item found.");
        else
            log:ErrorFormat("An error occurred while performing the information lookup ({0}).", problemResponse.ProblemDetail);
        end
    else
        log:Debug("No item fields or problem element returned.");
        log:Error("An error occurred while performing the information lookup.");
    end
end

local function RecursiveNavigateMapping(obj, strings)
  if(obj == nil) then
    log:Debug("obj is nil");
    return;
  end

  if #strings == 0 then
    log:DebugFormat("RecursiveNavigateMapping returning {0}", obj);
    return obj;
  end

  local temp = {};

  for i=2, #strings, 1 do
    table.insert(temp, strings[i]);
  end;

  return RecursiveNavigateMapping(obj:GetType():GetProperty(strings[1]):GetValue(obj, nil), temp);
end

function GetValueToImport(fieldMapping, result)
  local item = GetItemByType(fieldMapping.ObjectType, result);
  log:DebugFormat("item:{0}", item);

  local objectMappingArray = Utility.StringSplit(".", fieldMapping.ObjectMapping);
  local valueToImport = RecursiveNavigateMapping(item, objectMappingArray);

  return valueToImport;
end

-- Returns the mapped XML object
function GetItemByType(objectType, lookupItemResponse)
    for i=0, lookupItemResponse.Items.Length-1, 1 do
    local item = lookupItemResponse.Items[i];
        if(Utility.IsType(item, objectType, false)) then
            return item
        end
    end

    return nil;
end

-- Exports
NcipLookup.DoLookup = DoLookup;
NcipLookup.InitializeVariables = InitializeVariables;
NcipLookup.RecursiveNavigateMapping = RecursiveNavigateMapping;