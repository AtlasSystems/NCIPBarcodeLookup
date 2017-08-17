DataMapping = {};
DataMapping.HistoryEntries = {};
DataMapping.AcceptItem = {};
DataMapping.RequestItem = {};
DataMapping.CheckOutItem = {};
DataMapping.CheckInItem = {};
DataMapping.FieldMapping = {};


--Constants
DataMapping.ItemBarcodeField = "ReferenceNumber"; --This is the field of the transactions table that is used to check for an item barcode. The temporary barcode of an AcceptItem will also be store in this field.
DataMapping.TemporaryItemBarcodeFormat = "{TableField:Setting.RequestIdentifierPrefix}-{TableField:Transaction.TransactionNumber}"; --The formatting used to create an item barcode for temporary items

--AcceptItem Values
DataMapping.AcceptItem.RequestAgencyId = "ATLAS"; --The agency id used for the AcceptItem RequestId
DataMapping.AcceptItem.RequestIdentifierType = "Barcode Id"; --The request identifier type used for the AcceptItem RequestId
DataMapping.AcceptItem.RequestIdentifierValue = DataMapping.TemporaryItemBarcodeFormat; --The request identifier value used for the AcceptItem RequestId
DataMapping.AcceptItem.RequestedActionType = "Hold For Pickup"; --The RequestedActionType used for the AcceptItem message
DataMapping.AcceptItem.UserAgencyId = ""; --The value used for the user agencyid
DataMapping.AcceptItem.UserIdentifierType = "Barcode Id"; --The value used for the user identifier type of the AcceptItem UserId
DataMapping.AcceptItem.ItemAgencyId = ""; --The value used for the item agencyid
DataMapping.AcceptItem.ItemIdentifierType = "Barcode Id"; --The value used for the item identifier type of the AcceptItem ItemId
DataMapping.AcceptItem.OptionalTitle = "{TableField:Transaction.LoanTitle}";
DataMapping.AcceptItem.OptionalAuthor = "{TableField:Transaction.LoanAuthor}";

--PickupLocations
DataMapping.AcceptItem.PickupLocation = "{PickupLocation:User.NVTGC}"; --The value used for the PickupLocation of the AcceptItem message

--CheckOutItem Values
DataMapping.CheckOutItem.SendRequestId = true;
DataMapping.CheckOutItem.RequestAgencyId = "ATLAS"; --The agency id used for the AcceptItem RequestId
DataMapping.CheckOutItem.RequestIdentifierType = "Barcode Id"; --The request identifier type used for the AcceptItem RequestId
DataMapping.CheckOutItem.RequestIdentifierValue = DataMapping.TemporaryItemBarcodeFormat; --The request identifier value used for the CheckOut RequestId
DataMapping.CheckOutItem.UserAgencyId = ""; --The value used for the user agencyid
DataMapping.CheckOutItem.UserIdentifierType = "Barcode Id"; --The value used for the user identifier type of the CheckOutItem UserId
DataMapping.CheckOutItem.ItemAgencyId = ""; --The value used for the item agencyid
DataMapping.CheckOutItem.ItemIdentifierType = "Barcode Id"; --The value used for the item identifier type of the CheckOutItem ItemId

--CheckInItem Values
DataMapping.CheckInItem.ItemAgencyId = ""; --The value used for the item agencyid
DataMapping.CheckInItem.ItemIdentifierType = "Barcode Id"; --The value used for the item identifier type of the CheckInItem ItemId
DataMapping.CheckInItem.ItemIdentifierValue = "{TableField:Transaction." .. DataMapping.ItemBarcodeField .. "}"; --The value used for the item identifier value of the CheckInItem ItemId

-- Icon Mapping
DataMapping.ClientImage = {};
DataMapping.ClientImage["Ares"] = "Search32";
DataMapping.ClientImage["ILLiad"] = "Search32";
DataMapping.ClientImage["Aeon"] = "srch_32x32";

-- Barcode Field Mapping
DataMapping.BarcodeFieldMapping = {};
DataMapping.BarcodeFieldMapping["Ares"] = "Item.ItemBarcode";
DataMapping.BarcodeFieldMapping["ILLiad"] = "Transaction.ItemNumber";
DataMapping.BarcodeFieldMapping["Aeon"] = "Transaction.ItemNumber";

--Ares Field Mapping
DataMapping.FieldMapping["Ares"] = {};
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "CallNumber",
    ImportField = "Item.Callnumber",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "ItemDescription.CallNumber"
});
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "ISXN",
    ImportField = "Item.ISXN",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.BibliographicRecordId.BibliographicRecordIdentifier"
});
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "Title",
    ImportField = "Item.Title",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Title"
});
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "ArticleTitle",
    ImportField = "Item.ArticleTitle",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.TitleOfComponent"
});
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "Author",
    ImportField = "Item.Author",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Author"
});
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "Edition",
    ImportField = "Item.Edition",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Edition"
});
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "Place",
    ImportField = "Item.PubPlace",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.PlaceOfPublication"
});
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "PublicationDate",
    ImportField = "Item.PubDate",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.PublicationDate"
});
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "Pages",
    ImportField = "Item.PageCount",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Pagination"
});
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "Publisher",
    ImportField = "Item.Publisher",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Publisher"
});

-- ILLiad Field Mapping
DataMapping.FieldMapping["ILLiad"] = {};
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "Author",
    ImportField = {
        RequestType = {
            Loan = "Transaction.LoanAuthor",
            Article = "Transaction.PhotoItemAuthor"
        }
    },
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Author"
});
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "ISXN",
    ImportField = "Transaction.ISSN",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.BibliographicRecordId.BibliographicRecordIdentifier"
});
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "ArticleAuthor",
    ImportField = {
        RequestType = {
            Article = "Transaction.PhotoArticleAuthor"
        }
    },
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.AuthorOfComponent"
});
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "Edition",
    ImportField = {
        RequestType = {
            Loan = "Transaction.LoanEdition",
            Article = "Transaction.PhotoItemEdition"
        }
    },
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Edition"
});
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "Pages",
    ImportField = "Transaction.Pages",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Pagination"
});
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "Place",
    ImportField = {
        RequestType = {
            Loan = "Transaction.LoanPlace",
            Article = "Transaction.PhotoItemPlace"
        }
    },
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.PlaceOfPublication"
});
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "Publisher",
    ImportField = {
        RequestType = {
            Loan = "Transaction.LoanPublisher",
            Article = "Transaction.PhotoItemPublisher"
        }
    },
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Publisher"
});
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "Title",
    ImportField = {
        RequestType = {
            Loan = "Transaction.LoanTitle",
            Article = "Transaction.PhotoJournalTitle"
        }
    },
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Title"
});
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "ArticleTitle",
    ImportField = {
        RequestType = {
            Article = "Transaction.PhotoArticleTitle"
        }
    },
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.TitleOfComponent"
});
table.insert(DataMapping.FieldMapping["ILLiad"], {
    MappingName = "CallNumber",
    ImportField = "Transaction.CallNumber",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "ItemDescription.CallNumber"
});

-- Aeon Field Mapping
DataMapping.FieldMapping["Aeon"] = {};
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "Title",
    ImportField = "Transaction.ItemTitle",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Title"
});
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "Author",
    ImportField = "Transaction.ItemAuthor",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Author"
});
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "ArticleTitle",
    ImportField = "Transaction.ItemSubTitle",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.TitleOfComponent"
});
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "ISXN",
    ImportField = "Transaction.ItemISxN",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.BibliographicRecordId.BibliographicRecordIdentifier"
});
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "Publisher",
    ImportField = "Transaction.ItemPublisher",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Publisher"
});
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "Pages",
    ImportField = "Transaction.ItemPages",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Pagination"
});
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "CallNumber",
    ImportField = "Transaction.CallNumber",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "ItemDescription.CallNumber"
});
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "PublicationDate",
    ImportField = "Transaction.ItemDate",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.PublicationDate"
});
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "Place",
    ImportField = "Transaction.ItemPlace",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.PlaceOfPublication"
});
table.insert(DataMapping.FieldMapping["Aeon"], {
    MappingName = "Edition",
    ImportField = "Transaction.ItemEdition",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "BibliographicDescription.Edition"
});