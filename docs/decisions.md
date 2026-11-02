# Decisions log

## D1 - Column selection
<sub>25 October 2026</sub>

### Context

The Open Food Facts export has 201 columns. Most of them are not useful for this project, and loading all of them makes the workbook slow and hard to read.

### Decision

Keep 34 columns.

- **Identification:** find a product and show its photo in the search sheet. *(code, product_name, brands_en, image_small_url)*
- **Category:** group products for the analysis. *(main_category_en, pnns_groups_1, pnns_groups_2)*
- **Filter:** keep only products sold in Spain. *(countries_tags)*
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


## D2 - Minimum valid record
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

## D3 - Almost empty columns

<sub>28 October 2026</sub>

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


## D4 - Cleaning and data types

<sub>28 October 2026</sub>

### Decision

- ***Empty values:*** empty cells and the text "unknown" (in *pnns_groups_1*, *pnns_groups_2* and *nutriscore_grade*) are turned into real empty values (null). "not-applicable" in *nutriscore_grade* is kept, because it is real information.
- ***Barcode as text:*** *code* stays as text. As a number, leading zeros would be lost (00000142 would become 142).
- ***Decimal point:*** numbers are read with the English (US) format, because the file uses a point. Read with the Spanish format, 18.1 could become 181.
- ***Two decimals:*** nutrient values are rounded to 2 decimals. The extra decimals (19.29999924) are computer rounding errors, and labels show 1 decimal at most.
- ***Date:*** *last_modified_datetime* comes as Unix time (seconds since 1 January 1970) and is converted into a normal date.


## D5 - Text cleaning and impossible values
<sub>29 October 2026</sub>

### Context

Product names and brands are written by thousands of people: all caps, all lowercase, double spaces, final dots, several brands in one cell. Some nutrition values are also impossible.

### Decision

Keep 30 columns and 246,846 products.

- ***Product name:*** extra spaces and invisible characters are removed. Names written all in caps or all in lowercase become "First letter in caps". Names that already mix caps and lowercase are not changed, so abbreviations like "D.O.P." stay. A final dot is removed only when the last word has one dot.
- ***Brand:*** only the first brand is kept, hyphens become spaces and each word starts with a capital ("HERBALIFE" and "herbalife" become "Herbalife").
- ***Category:*** language prefixes like "es:" are removed and the first letter is capitalised.
- ***Impossible carbs:*** products with carbs below 0 g or above 100 g per 100 g are removed (26 products). The calculator depends on this value.
- ***Suspicious values:*** a new column *nutrition_check* marks "Check" when sugars are higher than carbs, saturated fat is higher than fat, or fat + carbs + proteins are above 105 g per 100 g. These products are kept but flagged.
- ***Broken rows:*** 2 products had their columns shifted in the original file (for example a URL in the category column), probably because of an extra tab inside a text. They are removed completely, because none of their values can be trusted.

### Rules

- Text cleaning stops here. Free text written by thousands of people can't be made perfect, and each new rule fixes very few cases.
- Similar names (for example several "Paleta de Teruel") are not merged: each one has its own barcode and is a different product.
- Brands with a real hyphen (Coca-Cola) lose it. A small cost compared to the brands it fixes.
- *serving_size* is not cleaned: *serving_quantity* already has the same value as a clean number.


## D6 - Search order
<sub>30 October 2026</sub>

### Context

The search sheet shows one page of results at a time, so the order decides what the user sees first. Each product in *tblProducts* has *unique_scans_n*, the number of people who scanned it with the Open Food Facts app. This number is calculated by Open Food Facts for each product, and it includes scans made in any country where the product is sold.

### Decision

Sort by four rules, each one only breaks ties of the one before.

- ***Reliable data first:*** green, then amber, then red products (D13).
- ***Name before brand:*** products with every search word in *product_name* come before the ones that only match through *brands_en*. Without this rule, "galleta" showed almost only Gullón products, because their brand is "Galletas Gullón".
- ***Popularity:*** most scanned first (*unique_scans_n*).
- ***Completeness:*** many products have few or no scans, so ties are common. The product with more data wins.

### Rules

- Popularity is not only Spanish: a product sold in Spain and France also counts the scans made in France. With a search term this barely matters, because the matches already have Spanish names.

### Discarded

- ***Spanish barcodes first (prefix 840-849):*** the prefix shows where the company registered the code, not where the product is sold. Products like Nutella would fall below unknown products with no scans.
- ***Completeness first:*** well-documented products that nobody buys would come first.
- ***Most popular products when the search is empty:*** most of them have French names. The sheet asks the user to type instead.


## D7 - Search match
<sub>31 October 2026</sub>

### Context

The first version only looked for the exact text inside the product name. Users often remember the brand but not the exact name, type the words in a different order, or have the package in their hands with the barcode.

### Decision

A product matches when every word typed is in its name or brand, or when the barcode is exactly the same.

- ***Several words:*** the text is split by spaces. "galleta gullon" and "gullon galleta" return the same products.
- ***Name and brand:*** both are searched together, so the user can type the brand without knowing where it is stored.
- ***Not case sensitive:*** "leche" finds "Leche entera".
- ***Barcode:*** exact match only. A partial code like "8410" would match thousands of products.
- ***Input as text:*** the search cell is formatted as text, so barcodes keep their leading zeros and don't turn into numbers like 8.41E+12.

### Rules

- Accents are ignored since D12: "maria" finds "María".

### Discarded

- ***Exact phrase in the name:*** "galleta gullon" found nothing, because no name has both words together.
- ***Any word instead of every word:*** each extra word would return more products instead of fewer.


## D8 - Search results
<sub>31 October 2026</sub>

### Context

*tblProducts* has 30 columns, most of them for analysis or data quality. The search sheet only needs what helps the user recognise a product and count its carbs.

### Decision

Show 13 columns: photo, barcode, name, brand, package, carbs, portions, sugars, fat, protein, kcal, data check and link.

- ***Nutrients per 100 g:*** carbs first, because the workbook is about carb counting. Sugars, fat and protein are added because they change how fast blood glucose rises. Fibre (27% coverage) and salt are left out.
- ***Portions:*** carbs per 100 g divided by 10. In Spain, 1 carb portion is 10 g of carbs. Insulin doses are not calculated: they depend on each person's ratio and are a medical decision.
- ***Empty values:*** shown as "–". Without this, Excel shows empty cells as 0, and "0 g of sugar" is not the same as "unknown".
- ***Data check:*** each product shows "✔", "Minor issue" or "⚠ Check label" (D13). Flagged products stay in the results, but at the end.
- ***Photo:*** loaded from *image_small_url* with IMAGE. The workbook only stores the address, so the photo needs internet.
- ***Link:*** opens the product page on es.openfoodfacts.org, where the user can see the real label. It is the way to check a product with "⚠ Check label".

### Rules

- The link column is one formula per row (N6:N105), not part of the main formula. Links inside a spilled result are not clickable. If a page size above 100 is added, the column has to be extended.

### Discarded

- ***All 30 columns:*** most of them are not useful to find a product.
- ***Hide flagged products:*** a user who searches their own barcode would get "No results" for a product that is in the table.
- ***Custom portion size:*** every product in the table is sold in Spain, where the portion is 10 g.


## D9 - Search pages
<sub>31 October 2026</sub>

### Context

"galleta" returns 2,661 products. Showing all of them with photos took more than 4 minutes, because each photo is downloaded from the internet. 20 or 50 products took about 5 seconds.

### Decision

Show results in pages of 20, 50 or 100, with buttons to move between pages.

- ***Page size:*** chosen by the user in a dropdown.
- ***Counter:*** shows which products are on screen and the total ("Showing 51-100 of 2,661").
- ***Page limit:*** a page number above the last page shows the last page.
- ***Shared calculations:*** the matches, the total, the number of pages and the current page are named formulas. The results, the counter and the page total use the same names, so they can't disagree.

### Rules

- ### Rules

- A macro sets the page back to 1 when the search or the page size changes (*vba/Search.cls*).

### Discarded

- ***"All" option:*** too slow with photos.
- ***"All" without photos:*** pages solve the same problem and keep the photos.


## D10 - Kcal check
<sub>1 November 2026</sub>

### Context

The rules of D5 only compare macros with each other. Products with impossible kcal passed as "OK": a pack of digestive biscuits showed 3,305 kcal per 100 g.

### Decision

Add two rules to *nutrition_check*. 11,012 products are flagged as "Check" (4.5%), before 275.

- ***Impossible kcal:*** more than 900 kcal per 100 g (590 products). Pure fat, the most energy-dense nutrient, has about 900.
- ***Kcal that don't match the macros:*** the kcal are calculated with the EU factors (4 per g of carbs without polyols, 2.4 polyols, 4 protein, 9 fat, 2 fibre) and compared with *energy-kcal_100g*. A product is flagged when the difference is more than 50 kcal and more than 50%. The most common cause is kJ written in the kcal field: the value is about 4 times higher.

### Rules

- The second rule only runs when the product has kcal, protein and fat. Missing polyols or fibre count as 0.
- Flagged products are kept: the user can still find them, with a warning (D8).

### Discarded

- ***Margin of 20% or 30%:*** it flagged 14,554 and 12,878 products. The count barely drops between 20% and 50%, so most errors are big. 50% catches them without flagging small rounding differences.
- ***Fix the kcal (divide by 4.184):*** there is no way to know if the wrong value is the kcal or the macros.


## D11 - Capital first letter
<sub>1 November 2026</sub>

### Context

D5 only fixes names written all in caps or all in lowercase. Mixed names that start with a lowercase letter, like "galleta Deco", stayed as they were.

### Decision

Every product name starts with a capital letter. The rest of the name is not changed, so abbreviations like "D.O.P." stay.


## D12 - Search without accents
<sub>1 November 2026</sub>

### Context

Excel's SEARCH doesn't ignore accents, and each user writes names their own way. "maria" didn't find "Galletas María", and "maría" didn't find "Galletas Maria Sin Gluten".

### Decision

Add two search columns: *search_name* and *search_brand*, the name and brand in lowercase and without accents. The search text is cleaned the same way in Excel (*SearchKey*). Now "maria" and "maría" return the same 555 products.

### Rules

- The columns are only used to search. The search sheet still shows the original name and brand.
- They are added at the end of the table (columns 31 and 32), so the column positions used by the search sheet don't change.
- "ñ" becomes "n" on both sides, so "espana" also finds "españa".

### Discarded

- ***Clean the names in Excel:*** it would clean 246,846 names again on every search. Power Query does it once, when the data is loaded.


## D13 - Data reliability levels
<sub>2 November 2026</sub>

### Context

The data check of D8 only had two states, based on *nutrition_check*. *data_quality_errors_tags* lists the errors that Open Food Facts finds in each product, and it was not used yet. Most of its errors check the same things as *nutrition_check*, but with stricter limits.

### Decision

Show three reliability levels in the search sheet.

- ***Green ("✔"):*** passes *nutrition_check* and Open Food Facts finds no nutrition errors. 230,921 products (93.5%).
- ***Amber ("Minor issue"):*** passes *nutrition_check*, but Open Food Facts finds a nutrition error, like kcal that don't fully match the macros. 4,913 products (2.0%).
- ***Red ("⚠ Check label"):*** fails *nutrition_check*. 11,012 products (4.5%).

### Rules

- Only errors that contain "nutrition" count. 373 products whose only errors are about categories (for example, tagged as a drink and as a meal) stay green, because those errors don't change the numbers.
- The level is calculated in the search sheet, not in Power Query, so it doesn't need a refresh.

### Discarded

- ***Any Open Food Facts error as amber:*** category errors don't affect carbs.
- ***Low completeness as amber:*** a missing brand or photo doesn't mean the carbs are wrong.