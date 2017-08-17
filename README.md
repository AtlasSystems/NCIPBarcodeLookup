# NCIP Barcode Lookup Addon

## Versions
**1.0 -** Initial release

## Summary
An NCIP Barcode Lookup Addon that uses a barcode to perform an NCIP item lookup and import the data returned into Ares, Aeon, and ILLiad.

> **Note:** Currently, only the NCIP Lookup Item Response has been implemented. The code for the other NCIP operations in the `NcipMessaging.lua` file are only for reference.

## Settings

> **NCIP Responder URL:** The URL to the NCIP Responder.
>
> **NCIP Agency ID:** The Agency ID to use when performing NCIP LookupItem requests.
>
> **Allow Overwrite with Blank Value:** If turned on, empty values from the NCIP response will overwrite any existing data. *Note:* Non-empty responses will always overwrite existing data.
>
>**Fields to Import:** This is a comma separated lists of the fields to import from the NCIP response into the current product. The name of each field corresponds to the `MappingName` located in the `DataMapping.lua` file.
>The default fields to import are *CallNumber, ISXN, Title, ArticleTitle, Author, Edition, Place, PublicationDate, Pages, and Publisher*. See the *Data Mappings*  or *FAQ* section of the documentation for more details.
>
>**Field to Perform Lookup With:** This is the field in which the barcode is read from. You may specify a custom field or leave it as `{Default}` which will use the field outlined in `DataMapping.lua`. The first value is the table in the database and the second value is the column.
>*Examples: {Default} (uses the field outlined in the DataMapping), Item.ItemBarcode, Transaction.ItemInfo1, or Transaction.Location*

## Buttons
The buttons for the NCIP Barcode Lookup Addon are located in the *"Barcode Lookup"* ribbon in the top left of the requests.

>**Import By Barcode:** Currently, the only button in the NCIP Barcode Lookup Addon. When clicked, it will use the provided barcode, NCIP Responder URL and Agency ID to perform an NCIP lookup and will import the results into the mapped fields.

## Data Mappings
Below are the default data mappings from the NCIP response to Ares, Aeon, and ILLiad and the default location of the barcodes for each product. These data mappings can be changed in the `DataMapping.lua` file.

### Default Barcode Fields
| Product DataMapping                       | Location              |
|-------------------------------------------|-----------------------|
| DataMapping.BarcodeFieldMapping["Ares"]   | Item.ItemBarcode      |
| DataMapping.BarcodeFieldMapping["ILLiad"] | Transaction.ItemNumber|
| DataMapping.BarcodeFieldMapping["Aeon"]   | Transaction.ItemNumber|

#### Columns
>**Mapping Name:** Used to identify the mapping. The `Fields to Import` setting lists the *Mapping Names* for the addon to import.
>
>**Import Field:** The Ares, Aeon, or ILLiad field the NCIP response item maps to. The first value is the table the field maps to and the second value is the desired column in the specified table.
>
>**Object Type:** Object type is the name of the response type from the NCIP response.
>
>**Object Mapping:** Where the information is located within the object type.

### Ares
| Mapping Name    | Import Field      | Object Type          | Object Mapping                                                                 |
|-----------------|-------------------|--------------------|------------------------------------------------------------------------------|
| CallNumber      | Item.Callnumber   | ItemOptionalFields | ItemDescription.CallNumber                                                   |
| ISXN            | Item.ISXN         | ItemOptionalFields | BibliographicDescription.BibliographicRecordId.BibliographicRecordIdentifier |
| Title           | Item.Title        | ItemOptionalFields | BibliographicDescription.Title                                               |
| ArticleTitle    | Item.ArticleTitle | ItemOptionalFields | BibliographicDescription.TitleOfComponent                                    |
| Author          | Item.Author       | ItemOptionalFields | BibliographicDescription.Author                                              |
| Edition         | Item.Edition      | ItemOptionalFields | BibliographicDescription.Edition                                             |
| Place           | Item.PubPlace     | ItemOptionalFields | BibliographicDescription.PlaceOfPublication                                  |
| PublicationDate | Item.PubDate      | ItemOptionalFields | BibliographicDescription.PublicationDate                                     |
| Pages           | Item.PageCount    | ItemOptionalFields | BibliographicDescription.Pagination                                          |
| Publisher       | Item.Publisher    | ItemOptionalFields | BibliographicDescription.Publisher                                           |

### ILLiad
>***Note:*** Because ILLiad supports multiple request types, separate mappings to both *Loan* and *Article* can be provided to the appropriate fields.

| Mapping Name  | Request Type | Import Field                   | Object Type          | Object Mapping                                                                 |
|---------------|--------------|--------------------------------|--------------------|------------------------------------------------------------------------------|
| Author        | Loan         | Transaction.LoanAuthor         | ItemOptionalFields | BibliographicDescription.Author                                              |
| Author        | Article      | Transaction.PhotoItemAuthor    | ItemOptionalFields | BibliographicDescription.Author                                              |
| ISXN          | Both         | Transaction.ISSN               | ItemOptionalFields | BibliographicDescription.BibliographicRecordId.BibliographicRecordIdentifier |
| ArticleAuthor | Article      | Transaction.PhotoArticleAuthor | ItemOptionalFields | BibliographicDescription.AuthorOfComponent                                   |
| Edition       | Loan         | Transaction.LoanEdition        | ItemOptionalFields | BibliographicDescription.Edition                                             |
| Edition       | Article      | Transaction.PhotoItemEdition   | ItemOptionalFields | BibliographicDescription.Edition                                             |
| Pages         | Both         | Transaction.Pages              | ItemOptionalFields | BibliographicDescription.Pagination                                          |
| Place         | Loan         | Transaction.LoanPlace          | ItemOptionalFields | BibliographicDescription.PlaceOfPublication                                  |
| Place         | Article      | Transaction.PhotoItemPlace     | ItemOptionalFields | BibliographicDescription.PlaceOfPublication                                  |
| Publisher     | Loan         | Transaction.LoanPublisher      | ItemOptionalFields | BibliographicDescription.Publisher                                           |
| Publisher     | Article      | Transaction.PhotoItemPublisher | ItemOptionalFields | BibliographicDescription.Publisher                                           |
| Title         | Loan         | Transaction.LoanTitle          | ItemOptionalFields | Transaction.LoanTitle                                                        |
| Title         | Article      | Transaction.PhotoJournalTitle  | ItemOptionalFields | Transaction.PhotoJournalTitle                                                |
| ArticleTitle  | Article      | Transaction.PhotoArticleTitle  | ItemOptionalFields | BibliographicDescription.TitleOfComponent                                    |
| CallNumber    | Both         | Transaction.CallNumber         | ItemOptionalFields | ItemDescription.CallNumber                                                   |

### Aeon
| Mapping Name    | Import Field              | Object Type          | Object Mapping                                                                 |
|-----------------|---------------------------|--------------------|------------------------------------------------------------------------------|
| Title           | Transaction.ItemTitle     | ItemOptionalFields | BibliographicDescription.Title                                               |
| Author          | Transaction.ItemAuthor    | ItemOptionalFields | BibliographicDescription.Author                                              |
| ArticleTitle    | Transaction.ItemSubTitle  | ItemOptionalFields | BibliographicDescription.TitleOfComponent                                    |
| ISXN            | Transaction.ItemISxN      | ItemOptionalFields | BibliographicDescription.BibliographicRecordId.BibliographicRecordIdentifier |
| Publisher       | Transaction.ItemPublisher | ItemOptionalFields | BibliographicDescription.Publisher                                           |
| Pages           | Transaction.ItemPages     | ItemOptionalFields | BibliographicDescription.Pagination                                          |
| CallNumber      | Transaction.CallNumber    | ItemOptionalFields | ItemDescription.CallNumber                                                   |
| PublicationDate | Transaction.ItemDate      | ItemOptionalFields | BibliographicDescription.PublicationDate                                     |
| Place           | Transaction.ItemPlace     | ItemOptionalFields | BibliographicDescription.PlaceOfPublication                                  |
| Edition         | Transaction.ItemEdition   | ItemOptionalFields | BibliographicDescription.Edition                                             |

## FAQ

### How to change the field that the barcode is read from?
The setting that determines the field that the barcode is read from is located in the addon's settings as `"Field to Perform Lookup With"`. It takes in the word `{Default}` or the table name and the column name separated by a `'.'`.

By default it is `{Default}` which tells the addon to get the field from the `DataMapping.lua` file.

### How to change the mappings of an NCIP Lookup Response to Aeon, Ares, or ILLiad's field?
To modify the mappings in this addon, you must edit the `DataMapping.lua` file. Each mapping is an entry on the `DataMapping.FieldMapping[Product Name]` table.

*Example data mapping table:*
```lua
DataMapping.FieldMapping["Ares"] = {};
table.insert(DataMapping.FieldMapping["Ares"], {
    MappingName = "CallNumber",
    ImportField = "Item.Callnumber",
    ObjectType = "ItemOptionalFields",
    ObjectMapping = "ItemDescription.CallNumber"
});
```

To modify the Aeon, Ares, or ILLiad field the NCIP response item will go into, change the `ImportField` value to desired field. The ImportField formula is `"{Table Name}.{Column Name}"`.

To modify the NCIP response item to go into a particular Aeon, Ares, or ILLiad field, change the `ObjectMapping` value to the desired NCIP response path.

### How to change a mapping's name?
The mapping names can be modified to fit the desired use case. Just change the `MappingName` value to the desired name and be sure to include the new `MappingName` value in the `"Fields to Import"` setting, so the addon knows to import that particular mapping.

### How to change Default Barcode Field?
The default barcode field is defined in the `DataMapping.BarcodeFieldMapping[{Product}]` table within the `DataMapping.lua` file. To change the mapping, modify the respective variable to the `"{Table}.{Column}"` of the new field to be mapped to.
