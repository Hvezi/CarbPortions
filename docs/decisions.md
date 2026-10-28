# Decisions log

## Day1 - Column selection
<sub>25 October 2026</sub>

### Context

The Open Food Facts export has 201 columns. Most of them are not useful for this project, and loading all of them makes the workbook slow and hard to read.

### Decision

Keep 34 columns.

- **Identification:** find a product and show its photo in the search sheet. *(code, product_name, brands_en, image_small_url)*
- **Category:** group products for the analysis. *(main_category_en, pnns_groups_1, pnns_groups_2)*
- **Filter:*** keep only products sold in Spain. *(countries_tags)*
- **Serving and package:** suggest a default amount in the calculator. *(serving_size, serving_quantity, product_quantity)*
- **Macros (per 100 g):** basic nutrition. carbohydrates_100g is the key column. *(energy-kcal_100g, fat_100g, saturated-fat_100g, carbohydrates_100g, proteins_100g)*
- **Diabetes (per 100 g):** show what kind of carbs a product has. *(sugars_100g, added-sugars_100g, glucose_100g, starch_100g, polyols_100g, fiber_100g, glycemic-index_100g)*
- **General health:** heart health, food quality and a gluten-free filter. *(salt_100g, cholesterol_100g, nutriscore_grade, nova_group, allergens_tags, traces_tags)*
- **Data quality:** measure how reliable each product is and sort by popularity. *(completeness, no_nutrition_data, data_quality_errors_tags, last_modified_datetime, unique_scans_n)*

### Rules

- When a column comes in two versions, `_tags` is used to filter and `_en` to display. Only one version is kept.
- Repeated data is dropped: sodium_100g (salt = sodium × 2.5) and the energy columns in kJ.

### Discarded

- **URLs and most images:** only one small photo is needed.
- **Single fatty acids (30+ columns):** too detailed; total and saturated fat are enough.
- **Vitamins and minerals:** almost always empty and not relevant for carb counting.
- **Ingredient text:** free text, hard to analyse in Excel.
- **Environmental data:** outside the scope of the project.
- **Stores:** very incomplete; countries_tags is enough to filter.
- **Who edited each product and when it was created:** not useful for the user.


## Day2 - Minimum valid record
<sub>25 October 2026</sub>

### Context

The first ~15,900 rows of the file are broken records: empty barcodes, fake codes like 0, or a category written as the product name. More broken records are spread across the rest of the file.

### Decision

A product is only kept if it meets all these rules:

- ***Valid barcode:*** only digits and a length of 8, 12, 13 or 14. Spaces are removed first.
- ***Sold in Spain:*** *countries_tags* contains *en:spain*.
- ***Has a name:*** *product_name* is not empty.
- ***Has carbs:*** *carbohydrates_100g* is not empty.

### Rules

- The barcode is the unique ID of each product. Without it, two products with the same name can't be told apart.
- The Spain filter uses "contains" instead of exact values. *countries_tags* lists every country where a product is sold (for example *en:portugal,en:spain*), so an exact match would drop products sold in Spain and other countries.
- Other columns can be empty. Asking for all 34 columns to be filled would remove almost every product.

## Day3 - Almost empty columns

<sub>28 October 2026<sub>

### Context

After the D2 filters, 246,874 products remain. Measured on all of them, some columns are almost empty.

### Decision

Keep 29 columns.

Columns with data in less than 10% of products are dropped:

- ***glycemic-index_100g:*** less than 1%.
- ***no_nutrition_data:*** less than 1%. It is also useless now, because every product left has carbs.
- ***glucose_100g:*** 6%.
- ***starch_100g:*** 7%.
- ***cholesterol_100g:*** 7%.

Kept as exceptions:

- ***allergens_tags (12%) and traces_tags (7%):*** safety information. They can show "contains gluten" or "may contain gluten", but never "gluten-free", because an empty cell means "unknown", not "none".
- ***polyols_100g (7%):*** about 17,000 products, enough for one insight about "sugar-free" products.
- ***data_quality_errors_tags (6%):*** here an empty cell means "no errors found", so 6% is the share of products with detected errors.


## Day4 - Cleaning and data types

<sub>28 October 2026<sub>

### Decision

- ***Empty values:*** empty cells and the text "unknown" (in *pnns_groups_1*, *pnns_groups_2* and *nutriscore_grade*) are turned into real empty values (null). "not-applicable" in *nutriscore_grade* is kept, because it is real information.
- ***Barcode as text:*** *code* stays as text. As a number, leading zeros would be lost (00000142 would become 142).
- ***Decimal point:*** numbers are read with the English (US) format, because the file uses a point. Read with the Spanish format, 18.1 could become 181.
- ***Two decimals:*** nutrient values are rounded to 2 decimals. The extra decimals (19.29999924) are computer rounding errors, and labels show 1 decimal at most.
- ***Date:*** *last_modified_datetime* comes as Unix time (seconds since 1 January 1970) and is converted into a normal date.