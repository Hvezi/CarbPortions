/*
    pFilePath
    Reads the path of the data file from the named cell "FilePath" (sheet Parameters).
    The path is calculated with a formula from the folder where the workbook is saved,
    so it works on any computer as long as the file is in data/raw/.
*/
let
    // Value of the first row and first column of the named cell
    Source = Excel.CurrentWorkbook(){[Name="FilePath"]}[Content]{0}[Column1]
in
    Source