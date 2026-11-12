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


## Analysis

Dashboard of the Spanish market for a person with type 1 diabetes. It fits in one screen.

- **Title (rows 1 to 5):** orange band across the whole sheet.
- **Grid:** columns A to AF, all with the same width. The content goes from B to AE, so A and AF are the side margins. The columns after AF are hidden.
- **Key numbers:** five cards in the top row: products, median carbs, carb-free products, sugar-free products and brands. The number is a text box linked to its cell in AnalysisData (B143 to B155).
- **Charts:** the map next to the cards; products by carb band and share of sugar on the left; package promises in the middle; brand types and the 15 most scanned products on the right.
- **Slicers:** in a strip at the bottom. The dashboard shows the whole market by default.
- **Boxes:** each card and chart sits on its own white box. The charts have no title or background; the title is a text box inside the box.
- **Zoom:** when the sheet is opened, the zoom fits columns A to AF to the width of the window. Code in *vba/Analysis.cls*.

Decisions: D18 to D21.


## AnalysisData

Helper sheet with the pivot tables and charts that feed the dashboard. The user doesn't work on it.

- **Data Model:** *tblProducts*, *tblLabels*, *tblPrivateLabels* and *tblCountries* are loaded into the Data Model (Power Pivot). DAX columns and measures live in the model, so the Data sheet doesn't change (D16).
- **Pivot tables:** one per question: products by carb band, share of sugar by band, carbs by package promise, 15 most scanned products sold only in Spain, products by brand type, and share of products also sold in other countries.
- **tblLabels:** the three package promises. It gives one row per promise to its pivot table.
- **tblPrivateLabels:** the 51 supermarket brands, in lowercase and without accents (D17).
- **tblCountries:** ten European countries and their tag in *countries_tags* (for example, "en:france").
- **Map data:** next to *tblCountries*, CUBEVALUE reads *Also sold in %* for each country from the Data Model. The filled map uses this range.
- **Band chart data:** next to the two band pivot tables (E2:F12 and E17:F27), the share of products and the share of sugar for each band, read with CUBEVALUE. The two band charts use these ranges (D20).
- **Key numbers (B142:B155):** title and value of the five cards of the dashboard: products, median carbs, carb-free products, sugar-free products and brands (D19).
- **Sugar chart colours (G17:J27):** the share of sugar of each band split in four ranges, one per colour of the chart (D20).

Formulas: *docs/workbook_formulas.md*, Data model. Decisions: D16 to D21.