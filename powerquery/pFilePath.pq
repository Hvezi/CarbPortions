/*
    pFilePath
    Reads the path of the data file from the named cell "FilePath" (sheet Parameters).
    Change the path in that cell, not here, if the file is in another folder.
*/
let
    // Value of the first row and first column of the named cell
    Source = Excel.CurrentWorkbook(){[Name="FilePath"]}[Content]{0}[Column1]
in
    Source
