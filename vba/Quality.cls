' Quality (sheet module)
' Opens the sheet at 90%, from the top left corner.
' See docs/decisions.md, D24 and D25

Private Sub Worksheet_Activate()
    ActiveWindow.Zoom = 90
    ActiveWindow.ScrollRow = 1
    ActiveWindow.ScrollColumn = 1
End Sub
