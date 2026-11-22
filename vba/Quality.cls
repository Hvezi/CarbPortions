' Quality (sheet module)
' Fits columns A to AF to the width of the window when the sheet is opened.
' See docs/decisions.md, D24

Private Sub Worksheet_Activate()
    Application.ScreenUpdating = False
    Me.Range("A1:AF1").Select
    ActiveWindow.Zoom = True
    ActiveWindow.ScrollRow = 1
    ActiveWindow.ScrollColumn = 1
    Me.Range("A1").Select
    Application.ScreenUpdating = True
End Sub
