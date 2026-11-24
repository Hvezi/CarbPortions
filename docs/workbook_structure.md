# Workbook structure

What is on each sheet and where. Why it is built that way is in [decisions.md](decisions.md), and every formula is explained in [workbook_formulas.md](workbook_formulas.md).

<br>

## Sheets

| Sheet | Tab | What it is |
|---|---|---|
| Home | orange | Cover, the workbook always opens here |
| Search | orange | Find any product |
| Calculator | orange | Carbs and portions of a meal |
| Analysis | orange | Dashboard of the Spanish market |
| Quality | orange | How far the data can be trusted |
| Settings | grey | Data source and how to refresh |
| Data | grey | The clean product table |
| AnalysisData | hidden | Pivot tables and cells behind the dashboard |

AnalysisData is hidden, not locked: right click on any tab > Unhide.

<br>

## Home

- One card per sheet, in the colour of its tab, with the name of the sheet, one line about it and a photo of it. Each card takes you to its sheet.
- The photos are pictures called *Shot Search*, *Shot Calculator* and so on. Data has no photo.
- When the sheet opens, the zoom fits columns A to AF to the window (*vba/Home.cls*).

<br>

## Search

**Inputs**

- **SearchTerm** (C7): name, brand or barcode. Formatted as text, so barcodes keep their leading zeros.
- **ResultLimit** (G7): products per page, 20, 50 or 100, from a dropdown.
- **PageNumber** (I7): the page to show, changed with the ‹ and › buttons (*vba/modSearch.bas*).

**Named formulas**

Saved in the Name Manager, not in cells, so each calculation lives in one place.

- **SearchKey:** the search in lowercase and without accents.
- **SearchHits:** one value per product, 1 if it matches the search and 0 if not.
- **SearchTotal:** number of matches. It reads the hidden cell P7, so the search over every product runs once instead of every time a formula needs the total.
- **SearchPages:** number of pages, never less than 1.
- **CurrentPage:** the page really shown, kept between 1 and the last page.

**What the user sees**

- The results: one formula that fills the whole page, under fixed headers.
- A counter under the search box ("Showing 51–100 of 2,661") and the number of pages next to the page box.
- A "View" link in every row with a product, one formula per row, because links inside a spilled formula can't be clicked.
- A card on the left with how to search and what the Data column means.

**Macros** (*vba/Search.cls*): the page goes back to 1 when the search or the page size changes, and the sheet opens at 80%.

<br>

## Calculator

- **tblMeal** (C13:G23): 10 rows, one per food. The user fills the beige cells, *Barcode* and *Amount (g or ml)*, and formulas fill the white ones, *Product*, *Carbs (g)* and *Portions*.
- **Screen:** the total carbs and portions, two text boxes linked to K1 and K2. Columns J onwards are hidden.
- **Keys:** C clears the meal and ← removes the last food (*vba/modCalculator.bas*).
- *Amount* only accepts numbers of 0 or more, and each column shows a short help message when a cell is selected.
- The sheet opens at 90% (*vba/Calculator.cls*).

<br>

## Analysis

- **Grid:** columns A to AF, all the same width. Columns after AF are hidden.
- **Key numbers:** five cards. Each number is a text box linked to a cell in AnalysisData.
- **Charts:** six, each one reading its numbers from AnalysisData. The most scanned list is a linked picture of a pivot table, so it changes with the filters.
- **Filters:** carb interval, brand type, says sugar free, says whole grain, says gluten free.
- **Macros:** the sheet opens at 80% (*vba/Analysis.cls*). When a filter changes, the labels chart moves its dashed line and the doughnut greys out the brands not chosen (*vba/AnalysisData.cls*).

<br>

## Quality

- **Cards:** products in the file, validated, flagged and with minor issues.
- **Charts:** why products are flagged, and which data is missing most often.
- **Things to know:** notes on the limits of the data, with the download date.
- Everything is calculated in the hidden columns AH:AL, and the cards and charts read from there.
- The sheet opens at 90% (*vba/Quality.cls*).

<br>

## Settings

One card per setting. Each value is a text box linked to the cell under it.

- **Source** (C3) and **License** (C5): links to Open Food Facts and the Open Database License.
- **DownloadDate** (C7): when the data was downloaded, typed by hand.
- **Products** (C9): number of products in the table.
- **How to refresh** (C11), **Data file** (C13), **Requirements** (C15) and **Repository** (C17).
- **FilePath** (F2, hidden column): the full address of the data file, which Power Query reads. It's empty in the saved file. A macro fills it when the workbook opens and again right after saving (*vba/ThisWorkbook.cls*).

<br>

## Data

- **tblProducts:** 246,846 products and 32 columns, loaded by Power Query (*powerquery/qSource.pq*). The last two, *search_name* and *search_brand*, are only for searching.
- Data > Refresh All reads the whole file again and takes a few minutes.

<br>

## AnalysisData

Hidden sheet with everything the dashboard reads. The user never works here.

**Tables**

- **tblLabels** (B34:B37): the three package labels.
- **tblPrivateLabels** (B64:B115): the 51 supermarket brands.
- **tblCountries** (B121:D138): 17 countries and their share, read from the data model. The map uses this table. After adding a country, Power Pivot > Linked Table > Update All.

**Pivot tables and the cells next to them**

| Range | What | Used by |
|---|---|---|
| B2:C12, cells E2:F12 | Products by carb interval | Carb chart |
| B17:C27, cells E17:J27 | Share of sugar by interval, split in four colour ranges | Sugar chart |
| C34:E37 | Carbs by package label | Labels chart |
| B49:D59 | 10 most scanned products sold only in Spain | Top 10 picture |
| D64:E67 | Products by brand type | Brand chart |
| F121:H138 | Products also sold in each country | tblCountries |

**Cards**

- **Map card** (B140:B142): the country with the highest share, its share and its number of products.
- **Key numbers** (B147, B150, B153, B156, B159): the value of each of the five cards.

The pivot tables, the filters and the cells read the data model (Power Pivot), where the DAX columns and measures live.
