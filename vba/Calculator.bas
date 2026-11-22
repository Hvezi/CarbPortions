' modCalculator (module)
' Keys of the Calculator sheet.
' ClearMeal (key C):   empties Barcode and Amount of every row to start a new meal
' RemoveLast (key ←):  empties Barcode and Amount of the last row with a food
' The formula columns empty themselves.
' See docs/workbook_structure.md, Calculator

Sub ClearMeal()
    With ThisWorkbook.Worksheets("Calculator").ListObjects("tblMeal")
        ' Clear only the contents, so the Barcode column keeps its text format
        .ListColumns("Barcode").DataBodyRange.ClearContents
        .ListColumns("Amount (g or ml)").DataBodyRange.ClearContents
    End With
End Sub

Sub RemoveLast()
    Dim lo As ListObject, r As Long
    Set lo = ThisWorkbook.Worksheets("Calculator").ListObjects("tblMeal")
    ' From the bottom up: the first row with a barcode is the last food added
    For r = lo.ListRows.Count To 1 Step -1
        If lo.ListColumns("Barcode").DataBodyRange.Cells(r).Value <> "" Then
            lo.ListColumns("Barcode").DataBodyRange.Cells(r).ClearContents
            lo.ListColumns("Amount (g or ml)").DataBodyRange.Cells(r).ClearContents
            Exit Sub
        End If
    Next r
End Sub
