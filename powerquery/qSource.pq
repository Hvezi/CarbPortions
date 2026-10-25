/*
    qSource
    Reads the Open Food Facts export (.csv.gz) and keeps only valid products sold in Spain.
    Input:  pFilePath (path to the .csv.gz file)
    Output: one row per product, 34 columns (see docs/decisions.md, D1 and D2)
*/
let
    // Read the compressed file from disk
    Source = File.Contents(pFilePath),

    // Decompress it in memory (the file on disk stays compressed)
    Decompressed = Binary.Decompress(Source, Compression.GZip),

    // Split the text into columns: tab-separated, UTF-8, quotes treated as normal characters
    Table = Csv.Document(Decompressed, [Delimiter="#(tab)", Encoding=65001, QuoteStyle=QuoteStyle.None]),

    // Use the first row as column names
    Headers = Table.PromoteHeaders(Table, [PromoteAllScalars=true]),

    // Keep the 34 columns chosen in D1
    Columns = Table.SelectColumns(Headers, {"code", "product_name", "brands_en", "image_small_url", "main_category_en", "pnns_groups_1", "pnns_groups_2", "countries_tags", "serving_size", "serving_quantity", "product_quantity", "energy-kcal_100g", "fat_100g", "saturated-fat_100g", "carbohydrates_100g", "proteins_100g", "sugars_100g", "added-sugars_100g", "glucose_100g", "starch_100g", "polyols_100g", "fiber_100g", "glycemic-index_100g", "salt_100g", "cholesterol_100g", "nutriscore_grade", "nova_group", "allergens_tags", "traces_tags", "completeness", "no_nutrition_data", "data_quality_errors_tags", "last_modified_datetime", "unique_scans_n"}),

    // Remove spaces at the start and end of the barcode
    TrimCode = Table.TransformColumns(Columns, {{"code", Text.Trim, type text}}),

    // Valid barcode: only digits and a length of 8, 12, 13 or 14 (EAN-8, UPC-A, EAN-13, GTIN-14)
    ValidCode = Table.SelectRows(TrimCode, each List.Contains({8, 12, 13, 14}, Text.Length([code])) and Text.Select([code], {"0".."9"}) = [code]),

    // Sold in Spain: "contains" instead of exact values, because a product can list several countries
    SpainData = Table.SelectRows(ValidCode, each Text.Contains([countries_tags], "en:spain")),

    // Must have a product name
    HasName = Table.SelectRows(SpainData, each [product_name] <> null and [product_name] <> ""),

    // Must have carbs per 100 g (needed by the calculator)
    HasCarbs = Table.SelectRows(HasName, each [carbohydrates_100g] <> null and [carbohydrates_100g] <> "")
in
    HasCarbs
