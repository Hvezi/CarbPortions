' Calculator (sheet module)
' Opens the calculator at 90%, from the top left corner.
' The keys C and ← are in vba/modCalculator.bas.
' See docs/decisions.md, "Meal calculator" and "Look of the sheets"

Private Sub Worksheet_Activate()
    ActiveWindow.Zoom = 90
    ActiveWindow.ScrollRow = 1
    ActiveWindow.ScrollColumn = 1
End Sub
