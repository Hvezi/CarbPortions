# Workbook


## Order of the sheets

Search, Calculator, Analysis and Quality, with orange tabs, are for the user. Settings and Data, with grey tabs, are technical. AnalysisData is hidden (right click on a tab > Unhide). All the sheets share the palette, the fonts and the title band (D25).


## Search

Finds products by name, brand or barcode and shows them in pages, with photo, nutrients per 100 g and a link to the product page.

### Inputs

- **SearchTerm (cell C7, merged with D7):** product name, brand or barcode typed by the user. Formatted as text, so barcodes keep their leading zeros.
- **ResultLimit (cell G7):** products per page. Dropdown (data validation) with 20, 50 or 100.
- **PageNumber (cell I7):** page asked by the user. Changed with the ‹ and › buttons next to it (macros *PrevPage* and *NextPage*, *vba/modSearch.bas*).

### Named formulas

Calculations stored in the Name Manager, not in cells. Several cells use them, so each one is calculated in one place only.

- **SearchKey:** *SearchTerm* in lowercase and without accents, to compare it with *search_name* and *search_brand*.
- **SearchHits:** list with one value per product of *tblProducts*: 1 if it matches the search, 0 if not.
- **SearchTotal:** number of matching products. It points to cell P7 (hidden), which holds `=SUM(SIGN(SearchHits))`, so it is calculated once and every formula reads the stored value (D15).
- **SearchPages:** number of pages: *SearchTotal* divided by *ResultLimit*, rounded up. Never less than 1.
- **CurrentPage:** page really shown: *PageNumber* kept between 1 and *SearchPages*.

### Outputs

- **Results (cell B11):** one formula that spills the products of the current page: photo, barcode, name, brand, package, carbs, portions, sugars, fat, protein, kcal and data check.
- **Headers (B10:N10):** fixed text, not part of the formula. If the columns of the formula change order, the headers have to be moved by hand.
- **Counter (cell C8):** products on screen and total ("Showing 51–100 of 2,661"), under the search box. Empty when there is no search or no match.
- **Page total (cell K7):** number of pages ("of 54").
- **Links (N11:N110):** one formula per row that builds a "View" link to the product page from the barcode in column C.
- **Colours:** white and beige rows by conditional formatting, only in rows with a product.
- **How to search:** card on the left with the steps and what the Data column means.
- **Macros:** when *SearchTerm* or *ResultLimit* changes, *PageNumber* goes back to 1. When the sheet is opened, the zoom is set to 80%. Code in *vba/Search.cls*.

Formulas and how they work: *docs/workbook_formulas.md*. Decisions: D6 to D9, D12, D13, D15, D25.


## Calculator

Adds up the carbs and portions of a meal from the barcode and the amount of each food. It looks like a calculator (D25).

- **Table (tblMeal, C13:G23):** 10 rows, one per food. Empty rows show nothing.
- **Inputs (beige cells):** *Barcode* (formatted as text) and *Amount (g or ml)*. The barcode can be copied from Search with Ctrl + C and pasted with Ctrl + Shift + V. *Amount* only accepts numbers of 0 or more.
- **Product, Carbs (g), Portions (white cells):** filled by formulas. Names longer than 36 characters end in "…".
- **Screen:** total carbs and portions of the meal, text boxes linked to K1 and K2 (hidden columns).
- **Keys:** C empties the meal (*ClearMeal*). ← removes the last food (*RemoveLast*). Code in *vba/Calculator.bas*.
- **Messages:** each column shows a short message when a cell is selected (data validation).
- **How to use:** card on the left with the steps.

Formulas: *docs/workbook_formulas.md*. Decisions: D14, D25.


## Analysis

Dashboard of the Spanish market for a person with type 1 diabetes. It fits in one screen.

- **Title (rows 1 to 5):** orange band across the whole sheet.
- **Grid:** columns A to AF, all with the same width. The content goes from B to AE, so A and AF are the side margins. The columns after AF are hidden.
- **Key numbers:** five cards in the top row: products, median carbs, carb-free products, sugar-free products and brands. The number is a text box linked to its cell in AnalysisData (B143 to B155).
- **Charts:** the map next to the cards; products by carb band and share of sugar on the left; package promises in the middle; brand types and the 10 most scanned products on the right.
- **Map card:** next to the map, the country that shares the most products with Spain, its share and its number of products (AnalysisData, B140:B142).
- **Slicers:** in a strip at the bottom: carbs per 100 g, brand, says sugar free, says whole grain and says gluten free. The dashboard shows the whole market by default. A slicer doesn't filter the chart split by its own field (D22).
- **Boxes:** each card and chart sits on its own white box. The charts have no title or background; the title is a text box inside the box.
- **Most scanned list:** linked picture of the top 10 pivot table in AnalysisData, so it changes with the slicers.
- **Zoom:** when the sheet is opened, the zoom fits the dashboard to the width of the window. Code in *vba/Analysis.cls*.
- **Slicer events:** when a slicer changes, the labels chart moves its top line to the chosen carb range and the doughnut greys out the brands not chosen. Code in *vba/AnalysisData.cls*.

Decisions: D18 to D23.


## Quality

How far the data can be trusted (D24).

- **Cards:** products in the file, validated, flagged and with minor issues.
- **Why products are flagged:** products that break each rule of *nutrition_check*.
- **Missing data:** share of products without each field.
- **Things to know:** notes about the limits of the data, and the download date.
- **Calculations:** formulas in the hidden columns AH:AL. The charts read them.
- **Zoom:** fits columns A to AF to the window. Code in *vba/Quality.cls*.


## Settings

Information about the data and the workbook, one card per setting. The values are text boxes linked to the cells under the cards.

- **Source (C3):** link to the Open Food Facts download page.
- **License (C5):** link to the Open Database License (ODbL). The data can be used and shared if the source is credited.
- **DownloadDate (C7):** date when the export was downloaded. Typed by hand when the file is replaced.
- **Products (C9):** number of rows of *tblProducts*, counted with ROWS.
- **How to refresh (C11):** replace the file in *data\raw* and use Data > Refresh All.
- **Data file (C13):** relative path of the CSV.
- **Requirements (C15):** Excel for Microsoft 365, with macros enabled.
- **Repository (C17):** link to this repository.
- **FilePath (F2, hidden):** full path of the CSV, read by Power Query (*pFilePath*). Empty in the saved file; a macro writes it when the workbook is opened and after it is saved (D26, *vba/ThisWorkbook.cls*).


## Data

Clean product table, loaded by the Power Query query *qSource* (code in *powerquery/qSource.pq*).

- **Table name:** tblProducts.
- **Size:** 246,846 products and 32 columns. The last two, *search_name* and *search_brand*, are only used by the search sheet (D12).
- **Refresh:** Data > Refresh All reads the whole file again and takes a few minutes.
- **Look:** table style *CarbData* and frozen header. Nothing else (D25).


## AnalysisData

Hidden helper sheet with the pivot tables and cells that feed the dashboard. The user doesn't work on it.

- **Data Model:** *tblProducts*, *tblLabels*, *tblPrivateLabels* and *tblCountries* are loaded into the Data Model (Power Pivot). DAX columns and measures live in the model, so the Data sheet doesn't change (D16).
- **Pivot tables:** one per question: products by carb band, share of sugar by band, carbs by package promise, 10 most scanned products sold only in Spain, products by brand type, and share of products also sold in other countries.
- **tblLabels:** the three package promises. It gives one row per promise to its pivot table.
- **tblPrivateLabels:** the 51 supermarket brands, in lowercase and without accents (D17).
- **tblCountries:** 17 European countries and their tag in *countries_tags* (for example, "en:france"). After adding a country, Power Pivot > Linked Table > Update All, or the model doesn't know it.
- **Map data:** next to *tblCountries*, CUBEVALUE reads *Also sold in %* for each country from the Data Model. The filled map uses this range.
- **Band chart data:** next to the two band pivot tables (E2:F12 and E17:F27), the share of products and the share of sugar for each band, read with CUBEVALUE. The two band charts use these ranges (D20).
- **Key numbers (B142:B155):** title and value of the five cards of the dashboard: products, median carbs, carb-free products, sugar-free products and brands (D19).
- **Map card (B140:B142):** country with the highest share, its share and its number of products.
- **Sugar chart colours (G17:J27):** the share of sugar of each band split in four ranges, one per colour of the chart (D20).

Formulas: *docs/workbook_formulas.md*, Data model. Decisions: D16 to D23.