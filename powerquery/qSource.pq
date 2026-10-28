/*
    qSource
    Reads the Open Food Facts export (.csv.gz), keeps only valid products sold in Spain,
    cleans empty values and sets the data types.
    Input:  pFilePath (path to the .csv.gz file)
    Output: one row per product, 29 columns (see docs/decisions.md, D1 to D4)
*/
let
    ---------- 1. Read the file ----------

    Read the compressed file from disk
    Source = File.Contents(pFilePath),

    Decompress it in memory (the file on disk stays compressed)
    Decompressed = Binary.Decompress(Source, Compression.GZip),

    Split the text into columns: tab-separated, UTF-8, quotes treated as normal characters
    Table = Csv.Document(Decompressed, [Delimiter="#(tab)", Encoding=65001, QuoteStyle=QuoteStyle.None]),

    Use the first row as column names
    Headers = Table.PromoteHeaders(Table, [PromoteAllScalars=true]),

    Keep the 34 columns chosen in D1
    Columns = Table.SelectColumns(Headers, {"code", "product_name", "brands_en", "image_small_url", "main_category_en", "pnns_groups_1", "pnns_groups_2", "countries_tags", "serving_size", "serving_quantity", "product_quantity", "energy-kcal_100g", "fat_100g", "saturated-fat_100g", "carbohydrates_100g", "proteins_100g", "sugars_100g", "added-sugars_100g", "glucose_100g", "starch_100g", "polyols_100g", "fiber_100g", "glycemic-index_100g", "salt_100g", "cholesterol_100g", "nutriscore_grade", "nova_group", "allergens_tags", "traces_tags", "completeness", "no_nutrition_data", "data_quality_errors_tags", "last_modified_datetime", "unique_scans_n"}),

    ---------- 2. Filter valid products ----------

    Remove spaces at the start and end of the barcode
    TrimCode = Table.TransformColumns(Columns, {{"code", Text.Trim, type text}}),

    Valid barcode: only digits and a length of 8, 12, 13 or 14 (EAN-8, UPC-A, EAN-13, GTIN-14)
    ValidCode = Table.SelectRows(TrimCode, each List.Contains({8, 12, 13, 14}, Text.Length([code])) and Text.Select([code], {"0".."9"}) = [code]),

    Sold in Spain: "contains" instead of exact values, because a product can list several countries
    SpainData = Table.SelectRows(ValidCode, each Text.Contains([countries_tags], "en:spain")),

    Must have a product name
    HasName = Table.SelectRows(SpainData, each [product_name] <> null and [product_name] <> ""),

    Must have carbs per 100 g (needed by the calculator)
    HasCarbs = Table.SelectRows(HasName, each [carbohydrates_100g] <> null and [carbohydrates_100g] <> ""),

    ---------- 3. Drop almost empty columns ----------

    Remove the 5 columns with data in less than 10% of products
    DropSparse = Table.RemoveColumns(HasCarbs, {"glucose_100g", "starch_100g", "glycemic-index_100g", "cholesterol_100g", "no_nutrition_data"}),

    ---------- 4. Clean empty values ----------

    Empty text ("") becomes a real empty value (null) in every column
    EmptyToNull = Table.ReplaceValue(DropSparse, "", null, Replacer.ReplaceValue, Table.ColumnNames(DropSparse)),

    The text "unknown" also becomes null ("not-applicable" is kept on purpose)
    UnknownToNull = Table.ReplaceValue(EmptyToNull, "unknown", null, Replacer.ReplaceValue, {"pnns_groups_1", "pnns_groups_2", "nutriscore_grade"}),

    ---------- 5. Data types ----------

    Text to decimal number, read with the English (US) format because the file uses a decimal point
    TypeDecimals = Table.TransformColumnTypes(UnknownToNull, {{"serving_quantity", type number}, {"product_quantity", type number}, {"energy-kcal_100g", type number}, {"fat_100g", type number}, {"saturated-fat_100g", type number}, {"carbohydrates_100g", type number}, {"proteins_100g", type number}, {"sugars_100g", type number}, {"added-sugars_100g", type number}, {"polyols_100g", type number}, {"fiber_100g", type number}, {"salt_100g", type number}, {"completeness", type number}}, "en-US"),

    Text to whole number
    TypeWholeNumbers = Table.TransformColumnTypes(TypeDecimals, {{"nova_group", Int64.Type}, {"unique_scans_n", Int64.Type}}, "en-US"),

    Round to 2 decimals: the extra decimals are computer rounding errors (19.29999924 -> 19.3)
    Round2 = Table.TransformColumns(TypeWholeNumbers, {{"serving_quantity", each Number.Round(_, 2), type number}, {"product_quantity", each Number.Round(_, 2), type number}, {"energy-kcal_100g", each Number.Round(_, 2), type number}, {"fat_100g", each Number.Round(_, 2), type number}, {"saturated-fat_100g", each Number.Round(_, 2), type number}, {"carbohydrates_100g", each Number.Round(_, 2), type number}, {"proteins_100g", each Number.Round(_, 2), type number}, {"sugars_100g", each Number.Round(_, 2), type number}, {"added-sugars_100g", each Number.Round(_, 2), type number}, {"polyols_100g", each Number.Round(_, 2), type number}, {"fiber_100g", each Number.Round(_, 2), type number}, {"salt_100g", each Number.Round(_, 2), type number}, {"completeness", each Number.Round(_, 2), type number}}),

    Unix time (seconds since 1 January 1970) to a normal date and time
    UnixToDate = Table.TransformColumns(Round2, {{"last_modified_datetime", each #datetime(1970, 1, 1, 0, 0, 0) + #duration(0, 0, 0, Number.FromText(_)), type datetime}})
in
    UnixToDate
