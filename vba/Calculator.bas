' modCalculator (module)
' Clears the meal table so the user can start a new meal.
' Input:  button "Clear" in the Calculator sheet
' Output: Barcode and Amount columns of tblMeal empty; the formula columns empty themselves
' See docs/workbook_structure.md, Calculator

Sub ClearMeal()
    With ThisWorkbook.Worksheets("Calculator").ListObjects("tblMeal")
        ' Clear only the contents, so the Barcode column keeps its text format
        .ListColumns("Barcode").DataBodyRange.ClearContents
        .ListColumns("Amount (g or ml)").DataBodyRange.ClearContents
    End With
End Sub