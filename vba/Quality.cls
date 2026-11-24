' Quality (sheet module)
' Opens the sheet at 90%, from the top left corner.
' See docs/decisions.md, "Quality sheet" and "Look of the sheets"

Private Sub Worksheet_Activate()
    ActiveWindow.Zoom = 90
    ActiveWindow.ScrollRow = 1
    ActiveWindow.ScrollColumn = 1
End Sub
