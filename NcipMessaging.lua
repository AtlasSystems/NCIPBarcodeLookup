--This handles NCIPv2 calls for AcceptItem, CheckOutItem, and CheckInItem

local NcipMessagingInternal = {};

NcipMessagingInternal.ResponderUrl = nil;
NcipMessagingInternal.AgencyId = nil;
NcipMessagingInternal.SendInitiationHeader = nil;
NcipMessagingInternal.DebugEnabled = nil;

--Set up events
NcipMessagingInternal.OnAcceptItemSuccess = nil;
NcipMessagingInternal.OnRequestItemSuccess = nil;
NcipMessagingInternal.OnCheckOutSuccess = nil;
NcipMessagingInternal.OnCheckInSuccess = nil;

local types = {};

-- Import the LogManager type
types["log4net.LogManager"] = luanet.import_type("log4net.LogManager");

-- Create a logger
local log = types["log4net.LogManager"].GetLogger(rootLogger .. ".NCIPMessaging");

NcipMessaging = NcipMessagingInternal;

types["System.Type"] = luanet.import_type("System.Type");
types["System.String"] = luanet.import_type("System.String");
types["System.Array"] = luanet.import_type("System.Array");
types["System.Activator"] = luanet.import_type("System.Activator");
types["System.Reflection.Assembly"] = luanet.import_type("System.Reflection.Assembly");
types["System.Object"] = luanet.import_type("System.Object");

-- Load the NCIP .NET assembly from the addon directory
local ncipAssembly = types["System.Reflection.Assembly"].LoadFile(AddonInfo.Directory .. "\\AtlasSystems.Interchange.Ncip.dll");

--Finish getting the NCIP types
types["AtlasSystems.Interchange.Ncip.v2.Client"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.Client");
types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair");
types["AtlasSystems.Interchange.Ncip.v2.DataObjects.RequestId"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.DataObjects.RequestId");
types["AtlasSystems.Interchange.Ncip.v2.DataObjects.UserId"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.DataObjects.UserId");
types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemId"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemId");
types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemDescription"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemDescription");
types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemOptionalFields"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemOptionalFields");
types["AtlasSystems.Interchange.Ncip.v2.DataObjects.BibliographicDescription"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.DataObjects.BibliographicDescription");
types["AtlasSystems.Interchange.Ncip.v2.NcipMessage"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.NcipMessage");
types["AtlasSystems.Interchange.Ncip.v2.Updates.Requests.AcceptItem"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.Updates.Requests.AcceptItem");
types["AtlasSystems.Interchange.Ncip.v2.Updates.Requests.RequestItem"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.Updates.Requests.RequestItem");
types["AtlasSystems.Interchange.Ncip.v2.Updates.Requests.CheckOutItem"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.Updates.Requests.CheckOutItem");
types["AtlasSystems.Interchange.Ncip.v2.Updates.Requests.CheckInItem"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.Updates.Requests.CheckInItem");
types["AtlasSystems.Interchange.Ncip.v2.Lookups.Requests.LookupItem"] = ncipAssembly:GetType("AtlasSystems.Interchange.Ncip.v2.Lookups.Requests.LookupItem");

local function LogProblem(response)
  local problemMessage = "";
  local problemCount = 0;
  for i=0, response.Items.Length - 1 do
    for j=0, response.Items[i].Items.Length - 1 do
      if (Utility.IsType(response.Items[i].Items[j], "AtlasSystems.Interchange.Ncip.v2.DataObjects.Problem", true)) then
        problemCount = problemCount + 1;
        log:WarnFormat("Type: {0}", response.Items[i].Items[j].ProblemType.Value);
        log:WarnFormat("Detail: {0}", response.Items[i].Items[j].ProblemDetail);
        log:WarnFormat("Element: {0}", response.Items[i].Items[j].ProblemElement);
        log:WarnFormat("Value: {0}", response.Items[i].Items[j].ProblemValue);

        problemMessage = problemMessage .. types["System.String"].Format("[Problem {0}] Type: {1}. Detail: {2}.", problemCount, response.Items[i].Items[j].ProblemType.Value, response.Items[i].Items[j].ProblemDetail);
      end
    end
  end

  log:Debug("Returning Problem Message");

  return problemMessage;
end

local function LogInfoMessageHandler(sender, e)
  log:Info(e.Message);
end

local function LogDebugMessageHandler(sender, e)
  log:Debug(e.Message);
end

local function ResponseHasProblem(response)
  log:Debug("Checking if response has NCIP problem");
  if response == nil then
    return false;
  end

  for i=0, response.Items.Length - 1 do
    for j=0, response.Items[i].Items.Length - 1 do
      if (Utility.IsType(response.Items[i].Items[j], "AtlasSystems.Interchange.Ncip.v2.DataObjects.Problem", true)) then
        return true;
      end
    end
  end

  log:Debug("NCIP problem not detected");
  return false;
end

local function IsValidNcipResponse(response, expectedResponseType)
  log:Debug("Checking if valid NCIP response");
  if (
  (response == nil) or
  (not Utility.IsType(response, "AtlasSystems.Interchange.Ncip.v2.NcipMessage", true)) or
  (response.Items.Length == 0) or
  (not Utility.IsType(response.Items[0], expectedResponseType, true)) or
  (ResponseHasProblem(response)) ) then

    if (response ~= nil) then
      log:DebugFormat("Response Type: {0}", response:GetType());
      if (response.Items ~= nil and response.Items.Length > 0) then
        log:DebugFormat("Response Type: {0}", response.Items[0]:GetType());
      end
    end

    local errorMessage = "Invalid response received from NCIP server.";

    local hasProblems = ResponseHasProblem(response);
    if (hasProblems) then
      local problemMessage = LogProblem(response);
      errorMessage = errorMessage .. " " .. problemMessage;
    end

    log:Debug("NCIP Error Message: " .. errorMessage);
    error({Message=errorMessage});
  end

  log:Debug("Valid NCIP response");
end

local function SendNcipMessage(request)
  local ncipMessageItems = types["System.Array"].CreateInstance(types["System.Type"].GetType("System.Object"), 1);
  ncipMessageItems[0] = request;

  local message = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.NcipMessage"]);
  message.Items = ncipMessageItems;

  local client = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.Client"], NcipMessagingInternal.ResponderUrl);
  client.OnInfoMessage:Add(LogInfoMessageHandler);
  client.OnDebugMessage:Add(LogDebugMessageHandler);

  log:Debug("Sending NCIP message");
  return client:Send(message);
end

local function AcceptItem(itemBarcode, userBarcode)
  log:Debug("[NcipMessaging.AcceptItem]");

  --Create a new Accept Item object
  local request = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.Updates.Requests.AcceptItem"]);

  log:Debug("[NcipMessaging.RequestItem] Setting RequestId");
  local requestId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.RequestId"]);
  local requestAgencyId = TagProcessor.ReplaceTags(DataMapping.AcceptItem.RequestAgencyId) or NcipMessagingInternal.AgencyId;
  requestId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], requestAgencyId);
  requestId.RequestIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.AcceptItem.RequestIdentifierType);
  requestId.RequestIdentifierValue = TagProcessor.ReplaceTags(DataMapping.AcceptItem.RequestIdentifierValue);
  request.RequestId = requestId;

  log:Debug("[NcipMessaging.RequestItem] Setting UserId");
  local userId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.UserId"]);
  local userAgencyId = TagProcessor.ReplaceTags(DataMapping.AcceptItem.UserAgencyId) or NcipMessagingInternal.AgencyId;
  userId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], userAgencyId);
  userId.UserIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.AcceptItem.UserIdentifierType);
  userId.UserIdentifierValue = userBarcode;
  request.UserId = userId;

  log:Debug("[NcipMessaging.RequestItem] Setting ItemId");
  local itemId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemId"]);
  local itemAgencyId = TagProcessor.ReplaceTags(DataMapping.AcceptItem.ItemAgencyId) or NcipMessagingInternal.AgencyId;
  itemId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], itemAgencyId);
  itemId.ItemIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.AcceptItem.ItemIdentifierType);
  itemId.ItemIdentifierValue = itemBarcode;
  request.ItemId = itemId;

  log:Debug("[NcipMessaging.RequestItem] Setting RequestedActionType");
  request.RequestedActionType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.AcceptItem.RequestedActionType);

  log:Debug("[NcipMessaging.RequestItem] Setting PickupLocation");
  local pickupLocation = TagProcessor.ReplaceTags(DataMapping.AcceptItem.PickupLocation);
  request.PickupLocation = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], pickupLocation);

  log:Debug("[NcipMessaging.AcceptItem] Setting Bibliographic Description fields");
  local bibInfo = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.BibliographicDescription"]);
  bibInfo.Title = TagProcessor.ReplaceTags(DataMapping.AcceptItem.OptionalTitle);
  bibInfo.Author = TagProcessor.ReplaceTags(DataMapping.AcceptItem.OptionalAuthor);

  local itemOptionalFields = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemOptionalFields"]);
  itemOptionalFields.BibliographicDescription = bibInfo;

  log:Debug("[NcipMessaging.RequestItem] Setting Number of Pieces");
  local pieces = GetFieldValue("Transaction", "Pieces");
  if tonumber(pieces) ~= nil then
    local itemDescription = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemDescription"]);
    itemDescription.NumberOfPieces = pieces;
    itemOptionalFields.ItemDescription = itemDescription;
  else
    log:Warn("Transaction pieces is not set. Cannot set NCIP NumberOfPieces");
  end
  request.ItemOptionalFields = itemOptionalFields;

  log:Debug("Attempting to retrieve the transaction due date");
  local dueDate = GetFieldValue("Transaction", "DueDate");
  if (dueDate ~= nil) then
    request.Item = dueDate; --The NCIP library should serialize the date as the DateForReturn field based on the object type
  else
    log:Warn("Transaction due date is not set. Cannot set NCIP DueDate");
  end

  local response = SendNcipMessage(request);
  if (not response) then
    error({Message="Error sending NCIP message"});
  end

  IsValidNcipResponse(response, "AtlasSystems.Interchange.Ncip.v2.Updates.Responses.AcceptItemResponse");

  --Call the OnAcceptItemSuccess handler if it exists
  if ((NcipMessagingInternal.OnAcceptItemSuccess ~= nil) and (type(NcipMessagingInternal.OnAcceptItemSuccess) == "function")) then
    NcipMessagingInternal.OnAcceptItemSuccess();
  end

  log:Debug("[NcipMessaging.AcceptItem] Completed");
end

local function RequestItem(itemBarcode, userBarcode)
  log:Debug("[NcipMessaging.RequestItem]");

  --Create a new Request Item object
  local request = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.Updates.Requests.RequestItem"]);

  log:Debug("[NcipMessaging.RequestItem] Building RequestIdentifier");
  local requestId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.RequestId"]);
  local requestAgencyId = TagProcessor.ReplaceTags(DataMapping.RequestItem.RequestAgencyId) or NcipMessagingInternal.AgencyId;
  requestId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], requestAgencyId);
  requestId.RequestIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.RequestItem.RequestIdentifierType);
  requestId.RequestIdentifierValue = TagProcessor.ReplaceTags(DataMapping.RequestItem.RequestIdentifierValue);

  log:Debug("[NcipMessaging.RequestItem] Building UserIdentifier");
  local userId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.UserId"]);
  local userAgencyId = TagProcessor.ReplaceTags(DataMapping.RequestItem.UserAgencyId) or NcipMessagingInternal.AgencyId;
  userId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], userAgencyId);
  userId.UserIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.RequestItem.UserIdentifierType);
  userId.UserIdentifierValue = userBarcode;

  log:Debug("[NcipMessaging.RequestItem] Building ItemIdentifier");
  local itemId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemId"]);
  local itemAgencyId = TagProcessor.ReplaceTags(DataMapping.RequestItem.ItemAgencyId) or NcipMessagingInternal.AgencyId;
  itemId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], itemAgencyId);
  itemId.ItemIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.RequestItem.ItemIdentifierType);
  itemId.ItemIdentifierValue = itemBarcode;

  log:Debug("[NcipMessaging.RequestItem] Setting RequestID");
  request.RequestId = requestId;
  log:Debug("[NcipMessaging.RequestItem] Setting UserId");
  local items = types["System.Array"].CreateInstance(types["System.Type"].GetType("System.Object"), 1);
  items[0] = userId;
  request.Items = items;
  log:Debug("[NcipMessaging.RequestItem] Setting ItemId");
  request.Item = itemId;

  log:Debug("[NcipMessaging.RequestItem] Setting PickupLocation");
  local pickupLocation = TagProcessor.ReplaceTags(DataMapping.RequestItem.PickupLocation);
  request.PickupLocation = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], pickupLocation);

  local bibInfo = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.BibliographicDescription"]);
  bibInfo.Title = TagProcessor.ReplaceTags(DataMapping.RequestItem.OptionalTitle);
  bibInfo.Author = TagProcessor.ReplaceTags(DataMapping.RequestItem.OptionalAuthor);

  local itemOptionalFields = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemOptionalFields"]);
  itemOptionalFields.BibliographicDescription = bibInfo;

  request.ItemOptionalFields = itemOptionalFields;

  log:Debug("[NcipMessaging.RequestItem] Setting RequestType");
  local requestType = TagProcessor.ReplaceTags(DataMapping.RequestItem.RequestType);
  request.RequestType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], requestType);
  log:Debug("[NcipMessaging.RequestItem] Setting ScopeType");
  local requestScope = TagProcessor.ReplaceTags(DataMapping.RequestItem.RequestScopeType);
  request.RequestScopeType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], requestScope);

  local response = SendNcipMessage(request);
  if (not response) then
    error({Message="Error sending NCIP message"});
  end

  IsValidNcipResponse(response, "AtlasSystems.Interchange.Ncip.v2.Updates.Responses.RequestItemResponse");

  --Call the OnRequestItemSuccess handler if it exists
  if ((NcipMessagingInternal.OnRequestItemSuccess ~= nil) and (type(NcipMessagingInternal.OnRequestItemSuccess) == "function")) then
    NcipMessagingInternal.OnRequestItemSuccess();
  end

  log:Debug("[NcipMessaging.RequestItem] Completed");
end


local function CheckOutItem(itemBarcode, userBarcode)
  log:Debug("[NcipMessaging.CheckOutItem]");

  --Create a new CheckOutItem object
  local request = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.Updates.Requests.CheckOutItem"]);

  if (DataMapping.CheckOutItem.SendRequestId) then
    log:Debug("[NcipMessaging.CheckOutItem] Setting RequestId");
    local requestId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.RequestId"]);
    local requestAgencyId = TagProcessor.ReplaceTags(DataMapping.CheckOutItem.RequestAgencyId) or NcipMessagingInternal.AgencyId;
    requestId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], requestAgencyId);
    requestId.RequestIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.CheckOutItem.RequestIdentifierType);
    requestId.RequestIdentifierValue = TagProcessor.ReplaceTags(DataMapping.CheckOutItem.RequestIdentifierValue);
    request.RequestId = requestId;
  end

  local userId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.UserId"]);
  local userAgencyId = TagProcessor.ReplaceTags(DataMapping.CheckOutItem.UserAgencyId) or NcipMessagingInternal.AgencyId;
  userId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], userAgencyId);
  userId.UserIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.CheckOutItem.UserIdentifierType);
  userId.UserIdentifierValue = userBarcode;

  local itemId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemId"]);
  local itemAgencyId = TagProcessor.ReplaceTags(DataMapping.CheckOutItem.ItemAgencyId) or NcipMessagingInternal.AgencyId;
  itemId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], itemAgencyId);
  itemId.ItemIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.CheckOutItem.ItemIdentifierType);
  itemId.ItemIdentifierValue = itemBarcode;

  request.UserId = userId;
  request.ItemId = itemId;

  local response = SendNcipMessage(request);
  if (not response) then
    error({Message="Error sending NCIP message"});
  end

  IsValidNcipResponse(response, "AtlasSystems.Interchange.Ncip.v2.Updates.Responses.CheckOutItemResponse");

  --Call the OnCheckOutSuccess handler if it exists
  if ((NcipMessagingInternal.OnCheckOutSuccess ~= nil) and (type(NcipMessagingInternal.OnCheckOutSuccess) == "function")) then
    NcipMessagingInternal.OnCheckOutSuccess();
  end

  log:Debug("[NcipMessaging.CheckOutItem] Completed");
end

local function CheckInItem(itemBarcode)
  log:Debug("[NcipMessaging.CheckInItem]");

  --Create a new CheckInItem object
  local request = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.Updates.Requests.CheckInItem"]);

  local itemId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemId"]);
  local itemAgencyId = TagProcessor.ReplaceTags(DataMapping.CheckInItem.ItemAgencyId) or NcipMessagingInternal.AgencyId;
  itemId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], itemAgencyId);
  itemId.ItemIdentifierType = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], DataMapping.CheckInItem.ItemIdentifierType);
  itemId.ItemIdentifierValue = itemBarcode;

  request.ItemId = itemId;

  local response = SendNcipMessage(request);
  if (not response) then
    error({Message="Error sending NCIP message"});
  end

  IsValidNcipResponse(response, "AtlasSystems.Interchange.Ncip.v2.Updates.Responses.CheckInItemResponse");

  --Call the OnCheckInSuccess handler if it exists
  if ((NcipMessagingInternal.OnCheckInSuccess ~= nil) and (type(NcipMessagingInternal.OnCheckInSuccess) == "function")) then
    NcipMessagingInternal.OnCheckInSuccess();
  end

  log:Debug("[NcipMessaging.CheckInItem] Completed");
end

-- LogEventArgs from the NCIP dll only has one property (Message)
local function OnNcipLogMessage(sender, args)
  log:Debug(args.Message);
end

local function LookupItem(itemBarcode)
  log:Debug("[NcipMessaging.LookupItem]");

  if (itemBarcode == nil or itemBarcode == "") then
    log:Warn("A barcode must be entered before performing an item lookup.");
    error({Message="A barcode must be entered before performing an item lookup."});
    return;
  end

  log:Debug("Creating Request Object");
  local request = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.Lookups.Requests.LookupItem"]);

  request.ItemId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.ItemId"]);
  request.ItemId.AgencyId = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], NcipMessagingInternal.AgencyId);
  request.ItemId.ItemIdentifierValue = itemBarcode;

  request.ItemElementType = types["System.Array"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], 2);
  request.ItemElementType[0] = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], "Bibliographic Description");
  request.ItemElementType[1] = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.DataObjects.SchemeValuePair"], "Item Description");

  log:Debug("Creating Message");
  local message = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.NcipMessage"]);
  message.Items = types["System.Array"].CreateInstance(types["System.Type"].GetType("System.Object"), 1);
  message.Items[0] = request;

  log:Debug("Creating Client");
  local client = types["System.Activator"].CreateInstance(types["AtlasSystems.Interchange.Ncip.v2.Client"], NcipMessagingInternal.ResponderUrl);

  -- Setup logging NCIP client logging hooks because the NCIP dll doesn't
  -- reference log4net directly to avoid versioning conflicts between products.
  client.OnInfoMessage:Add(OnNcipLogMessage);

  if (NcipMessagingInternal.DebugEnabled) then
    client.OnDebugMessage:Add(OnNcipLogMessage);
  end

  log:Debug("Sending NCIP Message");
  local response = client:Send(message);

  log:Debug("Recieved Response");
  if (response.Items[0]:GetType():ToString() == "AtlasSystems.Interchange.Ncip.v2.Lookups.Responses.LookupItemResponse") then
    local lookupItemResponse = response.Items[0];
    return lookupItemResponse;
  else
    log:Debug("Unexpected NCIP response type (" .. response.Items[0]:GetType():ToString() .. ").");
    error({Message="An error occurred while performing the information lookup."});
  end
end


-- Exports
NcipMessaging.AcceptItem = AcceptItem;
NcipMessaging.RequestItem = RequestItem;
NcipMessaging.CheckOutItem = CheckOutItem;
NcipMessaging.CheckInItem = CheckInItem;
NcipMessaging.LookupItem = LookupItem;
