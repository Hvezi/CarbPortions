# Workbook

## Parameters

Settings of the workbook.

- **FilePath (cell B1):** path of the Open Food Facts file, calculated with a formula from the folder where the workbook is saved. It works on any computer as long as the file is in *data/raw/*.

## Data

Clean product table, loaded by the Power Query query *qSource* (code in *powerquery/qSource.pq*).

- **Table name:** tblProducts.
- **Size:** 246,846 products and 30 columns.
- **Refresh:** Data > Refresh All reads the whole file again and takes a few minutes.