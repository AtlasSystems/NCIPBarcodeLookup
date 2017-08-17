require "Atlas.AtlasHelpers";
local rootLogger = "AtlasSystems.Addons.NCIPBarcodeLookupAddon";

luanet.load_assembly("System.Windows.Forms");  -- For cursor manipulation
luanet.load_assembly("log4net");

-- Load the .Net types that we will be using.
local types = {};
types["System.Windows.Forms.Cursor"] = luanet.import_type("System.Windows.Forms.Cursor");
types["System.Windows.Forms.Cursors"] = luanet.import_type("System.Windows.Forms.Cursors");
types["System.Windows.Forms.Application"] = luanet.import_type("System.Windows.Forms.Application");
types["log4net.LogManager"] = luanet.import_type("log4net.LogManager");
local log = types["log4net.LogManager"].GetLogger(rootLogger);
log:Debug("Finished creating types");

-- Load settings
local settings = {};
settings.LookupType = GetSetting("Look Up Type");
settings.ResponderUrl = GetSetting("NCIP Responder URL");
settings.AgencyId = GetSetting("NCIP Agency ID");
settings.AllowOverwriteWithBlankValue = GetSetting("Allow Overwrite With Blank Value");
settings.FieldsToImport = Utility.StringSplit(",", GetSetting("Fields to Import"));
settings.FieldToPerformLookupWith = GetSetting("Field to Perform Lookup With");

-- We will store the interface manager object here so that we don't have to make multiple GetInterfaceManager calls.
local interfaceMngr = nil;
log:Debug("Created Interface Manager");

local product = types["System.Windows.Forms.Application"].ProductName;

function Init()
  log:Debug("Starting");
  interfaceMngr = GetInterfaceManager();
  log:Debug("Got Interface Manager");

  -- Retrieve Ribbon Page and Add Buttons.
  local ribbonPage = interfaceMngr:CreateRibbonPage("Barcode Lookup");
  log:Debug("Created Ribbon Page");

  ribbonPage:CreateButton("Import by Barcode", GetClientImage(DataMapping.ClientImage[product]), "ImportItem", "Options");

  log:Debug("Created Button");

  -- Find the field to perform lookup with
  if settings.FieldToPerformLookupWith:lower() == "{default}" then
    settings.FieldToPerformLookupWith = Utility.StringSplit(".", DataMapping.BarcodeFieldMapping[product]);
    settings.FieldToPerformLookupWith[1] = Utility.Trim(settings.FieldToPerformLookupWith[1]);
    settings.FieldToPerformLookupWith[2] = Utility.Trim(settings.FieldToPerformLookupWith[2]);
    log:InfoFormat("Field to Perform Lookup With is {0}.{1}", settings.FieldToPerformLookupWith[1], settings.FieldToPerformLookupWith[2]);
  else
    log:Warn("Invalid Field to Perform Lookup With");
  end

  InitializeVariables();

end

function InitializeVariables()
  log:Debug("Initializing Variables");
  NcipLookup.InitializeVariables(settings.ResponderUrl, settings.AgencyId, settings.AllowOverwriteWithBlankValue, settings.FieldsToImport);
  log:Debug("Finished Initializing Variables");
end

function ImportItem()
  log:Debug("Importing Item...");
  local lookupResult = DoLookup();
  log:Debug("DoLookup Complete");

  if(lookupResult ~= nil) then
    for _, result in ipairs(lookupResult) do
      log:InfoFormat("Importing {0} into {1}.{2}", result.valueToImport, result.valueDestination[1], result.valueDestination[2]);
      SetFieldValue(result.valueDestination[1], result.valueDestination[2], result.valueToImport);
    end
  else
    interfaceMngr:ShowMessage("No item found.", "Item Not found");
  end
end

-- Returns a lookUpResult that contains a valueDestination array and the value to import
-- The valueDestination array has the table in the first position and the column in the second
function DoLookup()
  -- Set the mouse cursor to busy.
  types["System.Windows.Forms.Cursor"].Current = types["System.Windows.Forms.Cursors"].WaitCursor;
  local itemBarcode = nil;
  local succeeded, result = pcall(function() return GetFieldValue(settings.FieldToPerformLookupWith[1], settings.FieldToPerformLookupWith[2]) end)

  if succeeded then
    itemBarcode = result;
  end

  if itemBarcode == nil then
    log:Warn("Barcode is nil");
    return nil;
  end

  local lookupResult = NcipLookup.DoLookup(itemBarcode);

  -- Set the mouse cursor back to default.
  types["System.Windows.Forms.Cursor"].Current = types["System.Windows.Forms.Cursors"].Default;

  return lookupResult;
end
