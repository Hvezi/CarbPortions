' ThisWorkbook (workbook module)
' Writes the path of the data file in the named cell FilePath, which Power Query reads.
' The cell is emptied right before saving, so the saved file never holds the folders
' of the computer where it was saved.
' See docs/decisions.md, D26

Private Sub Workbook_Open()
    SetFilePath
End Sub

Private Sub Workbook_BeforeSave(ByVal SaveAsUI As Boolean, Cancel As Boolean)
    Me.Worksheets("Settings").Range("FilePath").ClearContents
End Sub

Private Sub Workbook_AfterSave(ByVal Success As Boolean)
    SetFilePath
End Sub

Public Sub SetFilePath()
    Const FILE_NAME As String = "\data\raw\en.openfoodfacts.org.products.csv.gz"
    Dim p As String: p = Me.Path
    ' The workbook can be in the repository folder or inside workbook/
    If Dir(p & FILE_NAME) = "" Then p = Left(p, InStrRev(p, "\") - 1)
    Me.Worksheets("Settings").Range("FilePath").Value = p & FILE_NAME
End Sub
