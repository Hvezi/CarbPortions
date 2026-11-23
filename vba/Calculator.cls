' Calculator (sheet module)
' Opens the calculator at 90%, from the top left corner.
' The keys C and ← are in vba/modCalculator.bas.
' See docs/decisions.md, D25

Private Sub Worksheet_Activate()
    ActiveWindow.Zoom = 90
    ActiveWindow.ScrollRow = 1
    ActiveWindow.ScrollColumn = 1
End Sub
