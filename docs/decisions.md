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


## D14 - Meal calculator
<sub>3 November 2026</sub>

### Context

Search shows the carbs per 100 g of each product. A person with type 1 diabetes needs the carbs and portions of what they actually eat.

### Decision

A table where the user types the barcode and the amount of each food, and gets the carbs and portions of each one and of the whole meal.

- ***Barcode, not name:*** a name can match several products (8 "Paleta de Teruel"), a barcode only one.
- ***Amount typed by the user:*** in g, or in ml for drinks, because their labels give carbs per 100 ml.
- ***Excel table with 10 rows:*** each column has one formula for every row, and empty rows show nothing.
- ***Total portions from total carbs:*** not the sum of the rounded portions of each row.

### Rules

- The calculator stops at portions. It doesn't calculate insulin doses: they depend on each person's ratio and other factors.

### Discarded

- ***One spilled formula, like Search:*** Excel tables don't allow formulas that spill.
- ***Manufacturer serving as default amount:*** only 12% of products have it, and the user knows what they eat.
- ***Carbs per 100 g and data check columns:*** the user comes from Search, where both are already shown.
- ***Insulin ratio:*** see Rules.


## D15 - Search speed
<sub>4 November 2026</sub>

### Context

Excel froze during a search and the unsaved work was lost. A named formula is not stored: it is calculated again every time a formula uses it. *SearchHits* (246,846 products × each word) was calculated about 8 times per search, through *SearchTotal*, *SearchPages* and *CurrentPage*. It also used BYROW, which runs a small function once per product.

### Decision

Calculate the search fewer times and in a faster way. Searches with about 5,000 matches ("leche") now work without freezing.

- ***Total in a cell:*** P3 holds the number of matches and *SearchTotal* points to it. *SearchHits* is calculated twice per search instead of about 8 times.
- ***MMULT instead of BYROW:*** counting the words found in each row with one matrix operation is faster than running a function per row.
- ***Name check only on matches:*** the "every word in the name" check of D6 runs on the matching products, not on the whole table.

### Rules

- P3 must never be below B6, because the results spill down up to 100 rows.

### Discarded

- ***Manual calculation:*** the user would have to press F9 after every search.


## D16 - Data model for the dashboard
<sub>6 November 2026</sub>

### Context

The dashboard questions need groups and calculations that don't exist as columns: carb bands, the promises on the package, the share of sugar. A normal pivot table can group carbs into bands, but a calculated field on a grouped field returns 0. Formulas outside pivot tables can't be filtered by slicers.

### Decision

Build the dashboard on the Excel Data Model (Power Pivot) with DAX.

- ***Analysis logic in the model:*** DAX columns (*carb_band*, *sugar_free*, *whole_grain*, *gluten_free*, *name_and_brand*) and measures live in the model. The table in the Data sheet doesn't change.
- ***Only reliable data:*** every measure counts products with *nutrition_check* = "OK" (235,834). The 11,012 flagged products are analysed in the Quality sheet.
- ***Promises in one chart:*** a small table (*tblLabels*) with the three promises, not related to *tblProducts*. The measures read the promise of each row and use its column.
- ***Most scanned products:*** only products sold only in Spain (*countries_tags* = "en:spain"). Scans are counted worldwide (D6), so without this filter the top is French.

### Rules

- What goes in Power Query and what goes in the model: Power Query holds what is true for the product in any use and what the sheet formulas need (*nutrition_check*, *search_name*, *search_brand*). The model holds the groups and calculations of a specific analysis, which can change without touching the clean data.
- The promises are found in *search_name*, so accents and capitals don't matter. "sin azucar" also matches "sin azucares anadidos".
- The DAX of Power Pivot doesn't have SELECTEDVALUE. HASONEVALUE and VALUES do the same.

### Discarded

- ***New columns in Power Query:*** they would change the clean data for one chart.
- ***Pivot grouping and calculated fields:*** the calculated field returns 0 on a grouped field.
- ***Formulas next to the pivot tables:*** slicers don't filter them.
- ***Slicer for nutrition_check:*** data that doesn't add up is not useful for the user.

## D17 - Supermarket brands
<sub>7 November 2026</sub>

### Context

The export has no column that says if a brand belongs to a supermarket chain. Only *brands_en* exists, and it is empty in 35% of products.

### Decision

Classify each product in three groups with a list of supermarket brands (*tblPrivateLabels*, 51 brands).

- ***Private labels:*** the brand is in the list, or starts with a brand of the list followed by a space ("carrefour bio").
- ***Other brands:*** the product has a brand that is not in the list.
- ***Unknown brand:*** *brands_en* is empty.

### Rules

- The list has the own brands of the main Spanish chains, checked against the 100 most frequent brands of the "Other brands" group. Some small own brands may still be counted as "Other brands".
- The list is a table in the workbook, so a brand can be added without changing any formula.

### Discarded

- ***"Manufacturer brand" and "No brand":*** they state things the data doesn't prove. "Other brands" only means "not in the list", and an empty brand is unknown, not missing.


## D18 - Dashboard content
<sub>7 November 2026</sub>

### Decision

Six visuals in two blocks, each one a different chart type, and a panel of slicers.

- ***For a person with diabetes:*** products by carb band (columns), share of sugar in each band (lollipop, D20), carbs by package promise (bars), and the 10 most scanned products sold only in Spain (table).
- ***Spanish market:*** share of supermarket brands (doughnut) and share of products also sold in other European countries (filled map).
- ***Slicers:*** carb band, brand type and package promise (sugar free, whole grain, gluten free).

### Rules

- The map can't be a pivot chart. Its values come from the Data Model with CUBEVALUE.

### Discarded

- ***Food groups:*** *main_category_en* and *pnns_groups* are empty in more than half of the products.
- ***Nutri-Score slicer:*** only 41% of products have a grade, including "not-applicable".
- ***Energy split (carbs, fat, protein):*** replaced by the map, which says more about the market.
- ***All bar or column charts:*** a different chart for each question makes the dashboard easier to read.


## D19 - Key numbers
<sub>9 November 2026</sub>

### Context

The dashboard starts with a row of cards with the numbers that describe the data before any chart.

### Decision

Five cards, all with validated products only (*nutrition_check* = "OK").

- ***Products:*** 235,834.
- ***Median carbs:*** 10.5 g per 100 g.
- ***Carb-free products:*** share of products with 0.5 g of carbs or less per 100 g.
- ***Sugar-free products:*** share of products with 0.5 g of sugar or less per 100 g, out of the products with sugar data.
- ***Brands:*** 20,280 different brands, counting only the first brand of each product (*main_brand*).

### Rules

- The cards count the same products as the charts, so the numbers add up.
- 0.5 g is the limit of the EU rule for "sugar free" claims (Regulation (EC) No 1924/2006). The same limit is used for carbs.
- Median, not average: a few products with almost 100 g (sugar, flour) pull the average up to 24.2 g. The median is the product in the middle.
- *main_brand* takes the text before the first comma of *search_brand*: "hacendado, mercadona" counts as "hacendado". The number is approximate, because the same brand can be written in different ways.
- The values come from the Data Model with CUBEVALUE and TEXT, because CUBEVALUE overwrites the number format of the cell.

### Discarded

- ***All products (246,846):*** it doesn't match the charts. The products left out are analysed in the Quality sheet.
- ***Validated data:*** the same number as Products once Products counts only validated products.
- ***Share of consistent data:*** it says little to a person looking for food.


## D20 - Charts from cells
<sub>10 November 2026</sub>

### Context

Pivot charts only offer the basic chart types, show field buttons and can lose colours and labels on refresh. The band charts need things they don't allow: one bar in a different colour and a lollipop chart.

### Decision

The two band charts are normal charts that read cells next to their pivot table. The cells get each value from the Data Model with CUBEVALUE.

- ***Products by carb band:*** columns close together, like a histogram, with the 0-10 band in the accent colour.
- ***Share of sugar by band:*** lollipop, a line chart with markers and no line, and error bars from each point down to 0. The colour of each point goes from beige to red with its value.

### Rules

- Each cell asks for its band by name, so a slicer that hides a band doesn't move the other rows.
- The bands are typed as text ('10-20g). Without the apostrophe Excel turns them into dates.
- The band names end in "g" in the model (*carb_band*), so the axis and the slicer read "0-10g" without explaining what a band is.
- Colours by value: one series per range (50% or more, 40-50%, 30-40%, less than 30%), with #N/A for the bands out of the range. When a slicer changes the values, each point takes the colour of its new range. Painted by hand, the colours would stay where they were.
- The share of products is calculated in the cell (band / total). The *Products %* measure uses ALLSELECTED, which only works well inside a pivot table.
- No TEXT here: charts need numbers. The format goes in the chart labels.

### Discarded

- ***Excel Histogram chart:*** it needs the raw values and makes its own ranges. With the bands it counted how many bands fall in each range of sugar.
- ***Funnel:*** the bands are not steps, and the share goes up again between 30 and 60 g.
- ***Area:*** the same reading as columns.
- ***100% stacked columns:*** 20 blocks of colour to show one number per band.


## D21 - Dashboard layout
<sub>11 November 2026</sub>

### Context

The dashboard has twelve blocks: five key numbers, six visuals and the slicers. It has to look the same on any screen and read well in one screenshot.

### Decision

One screen, with all the blocks on a grid of equal boxes.

- ***Grid:*** columns A to AF with the same width. The content goes from B to AE, with A and AF as margins. A key number card is the unit: the big visuals are two or three cards wide, with the same gap between all the boxes.
- ***One screen:*** the dashboard ends at row 45. When the sheet is opened, a macro sets the zoom to 80% (D25).
- ***Key number cards:*** title, number and, when needed, a subtitle with the unit or the limit. All the cards have the same position for each part.
- ***Slicers at the bottom:*** the dashboard shows the whole market by default. The user filters only if they want to.
- ***Titles outside the charts:*** each chart sits on a box without title or background. The title is a text box in the box, so all titles are at the same height and with the same font. The charts have no subtitle.
- ***Map:*** no chart title and the legend named "Products (%)". France stands out because it really sells four times more Spanish products than the next country.

### Rules

- Aptos for text and Aptos Black for titles and key numbers. Both come with Microsoft 365, so the dashboard looks the same on other computers.
- The number of each card is a text box linked to its cell in AnalysisData, so it changes with the data.
- New chart types (map, funnel, histogram) don't allow moving or resizing their title. One more reason to keep titles outside.

### Discarded

- ***A page of 70 rows:*** the dashboard was almost square and the screen is wide. To see it whole the zoom had to go down to 50%, with half of the screen empty.
- ***Slicers at the top:*** they took the first place of the screen for something the user may never use.
- ***Capping the colour scale of the map at 2%:*** the legend would say that the highest value is 2%, when it is 6.4%.
- ***Open Sans:*** it is not installed on Windows. Other computers would show another font.


## D22 - Slicers
<sub>15 November 2026</sub>

Five slicers at the bottom of the dashboard: carbs per 100 g, brand, and one for each package label (says sugar free, whole grain, gluten free). The labels have one slicer each because a product can say more than one thing ("integral sin azúcar").

A slicer doesn't filter the chart that is already split by the same field. If the brand slicer filtered the doughnut, choosing Private labels would show one full ring at 100%. Instead, the doughnut keeps all the brands and greys out the ones that are not chosen, so the user sees how much the choice weighs in the market. The same goes for the two carb charts and the carb slicer, and for the labels chart and the label slicers.

The key numbers and the map are not pivot tables, so the slicers reach them in a different way: each CUBEVALUE formula takes the slicers as extra arguments.

The slicer titles say "Says sugar free" and not "Sugar free" because they filter by what the package says, not by the real sugar. The key number *Sugar-free* counts the real sugar. Only 46% of the products that say "sugar free" have 0.5 g or less: most of them mean "no added sugar".

Discarded: a slicer for countries. *tblCountries* has no relationship with the products, and the map already shows that information.


## D23 - Chart details
<sub>20 November 2026</sub>

- **Labels chart:** the axis ends a little after the top of the chosen carb range, and a dashed line marks that top ("30g"). Without it, a bar of 24 g looks almost full when the range is 20-30 g. The line is placed a little to the right of its real value so the bar labels don't touch it; the bar labels give the exact grams.
- **Map:** 17 countries instead of 10. With 10, Madeira and the Azores pulled the map to the left and half of the box was empty. A card next to the map shows the country that shares the most products and how many, and it changes with the slicers. France is first in almost every case: Open Food Facts started in France and most products are added by French and Spanish users, so French products are over-represented. On the Open Food Facts site, France has about 1.2 million products and Portugal fewer than 20,000, which is why Portugal ranks low even though it is next door.
- **Most scanned list:** 10 products instead of 15, so the text can be read without zoom. It is a linked picture of the pivot table, because a pivot table can't sit on top of the boxes. The colours come from a pivot table style, because cell formats stay with each product and are lost when the slicers change the list.
- **Titles:** text boxes outside the charts, all at the same distance from the top and left edge of their box.
- **Grams without space** ("24g"), the same in every chart.


## D24 - Quality sheet
<sub>21 November 2026</sub>

A sheet that shows how far the data can be trusted, so the numbers of the dashboard are not taken on faith.

- **Four cards:** products in the file, validated, flagged and with minor issues. The same counts that Power Query and Search use.
- **Why products are flagged:** one bar per rule of *nutrition_check*. The bars add up to more than the flagged products, because some products break more than one rule.
- **Missing data:** share of products without serving size, fibre, Nutri-Score, category, brand or sugars. It explains why some charts were left out (D18).
- **Things to know:** five short notes about the limits of the data, and the download date read from Settings.

Everything is calculated with formulas in hidden columns of the same sheet (AH:AL), so it changes on refresh.


## D25 - Look of the sheets
<sub>21 November 2026</sub>

Every sheet uses the same palette (orange, yellow, beige), Aptos for text and Aptos Black for titles and numbers.

- **Home:** the workbook opens on a cover with one card per sheet, each with a photo of the sheet and a line about what it does. Someone who opens the file for the first time knows where to go without reading the README.

- **Calculator:** it looks like a calculator. A screen with the total carbs and portions, the ten rows of the meal, and two keys: C clears the meal and ← removes the last food. The cells the user types in are beige and the ones Excel fills are white. The total row of the table was removed: the screen shows the totals.
- **Search:** the controls on top, the results below, and a card on the left with how to search and what the Data column means. The page buttons replace the spin button, which couldn't be styled.
- **Settings:** one card per setting. The values are text boxes linked to their cells, because cells can't have round corners.
- **Data:** only a table style with the colours of the workbook. Nothing else is touched, because every other sheet reads this table.
- **Order of the tabs:** Home first, then the sheets for the user in orange (Search, Calculator, Analysis, Quality), and the technical ones after and in grey (Settings, Data). AnalysisData is hidden, but anyone can unhide it.
- **Zoom:** each sheet opens at a fixed zoom, chosen by eye: 80% for Search and Analysis, 90% for Calculator and Quality. Fitting the zoom to the window gave a different size on each screen and sometimes failed. Only Home still fits columns A to AF to the window, because it is only cards.

Discarded: freezing the headers of Search. Excel draws the frozen line across the whole window, and a page has 100 results at most.


## D26 - Path of the data file
<sub>21 November 2026</sub>

Power Query needs the full path of the CSV, and Excel has no relative paths. Before, a formula calculated it in Settings, and the saved file kept the last result: the folders of the computer where it was saved.

Now the cell *FilePath* is empty in the saved file. When the workbook is opened, and right after it is saved, a macro writes the path of that computer: the folder of the workbook plus *data\raw\*, or one level up if the workbook is inside *workbook/*. Right before saving, it empties the cell again. Settings only shows the relative path.

The only condition is that macros are enabled, which the workbook already needs. Code in *vba/ThisWorkbook.cls*.

