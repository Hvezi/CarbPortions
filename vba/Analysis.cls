' Analysis (sheet module)
' Opens the dashboard at 80%, from the top left corner.
' See docs/decisions.md, "Dashboard layout" and "Look of the sheets"

Private Sub Worksheet_Activate()
    ActiveWindow.Zoom = 80
    ActiveWindow.ScrollRow = 1
    ActiveWindow.ScrollColumn = 1
End Sub
