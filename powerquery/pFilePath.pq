/*
    pFilePath
    Reads the path of the data file from the named cell "FilePath" (sheet Settings).
    A macro writes the path when the workbook is opened (vba/ThisWorkbook.cls),
    so it works on any computer as long as the file is in data/raw/ (D26).
*/
let
    // Value of the first row and first column of the named cell
    Source = Excel.CurrentWorkbook(){[Name="FilePath"]}[Content]{0}[Column1]
in
    Source