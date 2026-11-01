# Workbook

## Parameters

Settings of the workbook.

- **FilePath (cell B1):** path of the Open Food Facts file, calculated with a formula from the folder where the workbook is saved. It works on any computer as long as the file is in *data/raw/*.

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
- **SearchTotal:** number of matching products (sum of *SearchHits*).
- **SearchPages:** number of pages: *SearchTotal* divided by *ResultLimit*, rounded up. Never less than 1.
- **CurrentPage:** page really shown: *PageNumber* kept between 1 and *SearchPages*.

### Outputs

- **Results (cell B6):** one formula that spills the products of the current page: photo, barcode, name, brand, package, carbs, portions, sugars, fat, protein, kcal and data check.
- **Headers (B5:N5):** fixed text, not part of the formula. If the columns of the formula change order, the headers have to be moved by hand.
- **Counter (cell F3):** products on screen and total ("Showing 51–100 of 2,661"). Empty when there is no search or no match.
- **Page total (cell K3):** number of pages ("of 54").
- **Links (N6:N105):** one formula per row that builds a "View" link to the product page from the barcode in column C. Empty in rows without a product.
- **Messages:** "Type a product name or barcode" when the search is empty and "No results" when nothing matches.

Formulas and how they work: *docs/workbook_formulas.md*.