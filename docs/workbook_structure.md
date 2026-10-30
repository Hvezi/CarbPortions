# Workbook

## Parameters

Settings of the workbook.

- **FilePath (cell B1):** path of the Open Food Facts file, calculated with a formula from the folder where the workbook is saved. It works on any computer as long as the file is in *data/raw/*.

## Data

Clean product table, loaded by the Power Query query *qSource* (code in *powerquery/qSource.pq*).

- **Table name:** tblProducts.
- **Size:** 246,846 products and 30 columns.
- **Refresh:** Data > Refresh All reads the whole file again and takes a few minutes.

## Search

Finds products by name or barcode and shows the 20 most popular matches.

- **Input (SearchTerm, cell C3):** product name or barcode. The cell is formatted as text, so barcodes keep their leading zeros.
- **Results (cell B6):** one LET formula that spills the matching rows of *tblProducts*.
- **Match:** the name contains the text (not case sensitive) or the barcode is exactly the same.
- **Order:** most scanned first (*unique_scans_n*), then most complete (*completeness*). Only the first 20 are shown.
- **Messages:** "Type a product name or barcode" when the input is empty and "No results" when nothing matches.