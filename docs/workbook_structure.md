# Workbook


## Settings

Information about the data source and the path to the data file.

- **Source (cell B3):** link to the Open Food Facts download page.
- **License (cell B4):** link to the Open Database License (ODbL). The data can be used and shared if the source is credited.
- **DownloadDate (cell B5):** date when the export was downloaded (21 October 2026). Typed by hand when the file is replaced.
- **Products (cell B6):** number of products in *tblProducts*, counted with ROWS, so it updates on refresh.
- **How to refresh (cell B7):** replace the file in *data/raw* and use Data > Refresh All.
- **FilePath (cell B8):** path of the Open Food Facts file, calculated with a formula from the folder where the workbook is saved. It works on any computer as long as the file is in *data/raw/*.


## Data

Clean product table, loaded by the Power Query query *qSource* (code in *powerquery/qSource.pq*).

- **Table name:** tblProducts.
- **Size:** 246,846 products and 32 columns. The last two, *search_name* and *search_brand*, are only used by the search sheet (D12).
- **Refresh:** Data > Refresh All reads the whole file again and takes a few minutes.


## Search

Finds products by name, brand or barcode and shows them in pages, with photo, nutrients per 100 g and a link to the product page.

### Inputs

- **SearchTerm (cell C3):** product name, brand or barcode typed by the user. Formatted as text, so barcodes keep their leading zeros.
- **ResultLimit (cell E3):** products per page. Dropdown (data validation) with 20, 50 or 100.
- **PageNumber (cell I3):** page asked by the user. Changed with the spin button next to it (minimum 1, maximum 999).

### Named formulas

Calculations stored in the Name Manager, not in cells. Several cells use them, so each one is calculated in one place only.

- **SearchKey:** *SearchTerm* in lowercase and without accents, to compare it with *search_name* and *search_brand*.
- **SearchHits:** list with one value per product of *tblProducts*: 1 if it matches the search, 0 if not.
- **SearchTotal:** number of matching products. It points to cell P3 (`=SUM(SIGN(SearchHits))`), so it is calculated once and every formula reads the stored value (D15).
- **SearchPages:** number of pages: *SearchTotal* divided by *ResultLimit*, rounded up. Never less than 1.
- **CurrentPage:** page really shown: *PageNumber* kept between 1 and *SearchPages*.

### Outputs

- **Results (cell B6):** one formula that spills the products of the current page: photo, barcode, name, brand, package, carbs, portions, sugars, fat, protein, kcal and data check.
- **Headers (B5:N5):** fixed text, not part of the formula. If the columns of the formula change order, the headers have to be moved by hand.
- **Counter (cell F3):** products on screen and total ("Showing 51–100 of 2,661"). Empty when there is no search or no match.
- **Page total (cell K3):** number of pages ("of 54").
- **Links (N6:N105):** one formula per row that builds a "View" link to the product page from the barcode in column C. Empty in rows without a product.
- **Messages:** "Type a product name or barcode" when the search is empty and "No results" when nothing matches.
- **Macro:** when *SearchTerm* or *ResultLimit* changes, *PageNumber* goes back to 1. Code in *vba/Search.cls*.

Formulas and how they work: *docs/workbook_formulas.md*.


## Calculator

Adds up the carbs and portions of a meal from the barcode and the amount of each food.

- **Table (tblMeal, B5:F15):** 10 rows, one per food, and a total row (row 16). Empty rows show nothing.
- **Inputs:** *Barcode* (formatted as text) and *Amount (g or ml)*, typed by the user. The barcode can be copied from Search: Ctrl + C, then Ctrl + Shift + V to paste only the value.
- **Product:** name of the product, to check that the barcode is the right one. "Not found" if the barcode is not in *tblProducts*.
- **Carbs (g):** carbs in the amount eaten.
- **Portions:** carbs divided by 10.
- **Total row:** carbs and portions of the whole meal.
- **Clear button:** empties *Barcode* and *Amount* of every row to start a new meal. Macro *ClearMeal* (*vba/Calculator.bas*).

Formulas: *docs/workbook_formulas.md*. Decisions: D14.


## AnalysisData

Helper sheet with the pivot tables and charts that feed the dashboard. The user doesn't work on it.

- **Data Model:** *tblProducts*, *tblLabels*, *tblPrivateLabels* and *tblCountries* are loaded into the Data Model (Power Pivot). DAX columns and measures live in the model, so the Data sheet doesn't change (D16).
- **Pivot tables:** one per question: products by carb band, share of sugar by band, carbs by package promise, 15 most scanned products sold only in Spain, products by brand type, and share of products also sold in other countries.
- **tblLabels:** the three package promises. It gives one row per promise to its pivot table.
- **tblPrivateLabels:** the 51 supermarket brands, in lowercase and without accents (D17).
- **tblCountries:** ten European countries and their tag in *countries_tags* (for example, "en:france").
- **Map data:** next to *tblCountries*, CUBEVALUE reads *Also sold in %* for each country from the Data Model. The filled map uses this range.

Formulas: *docs/workbook_formulas.md*, Data model. Decisions: D16 to D18.