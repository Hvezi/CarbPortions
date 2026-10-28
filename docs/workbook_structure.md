# Workbook

## Parameters

Settings of the workbook.

- **FilePath (cell B1):** full path of the Open Food Facts file. Power Query reads the file from this cell, so if the file is moved to another folder, only this cell needs to change.

## Data

Clean product table, loaded by the Power Query query *qSource* (code in *powerquery/qSource.pq*).

- **Table name:** tblProducts.
- **Size:** 246,874 products and 29 columns.
- **Refresh:** Data > Refresh All reads the whole file again and takes a few minutes.