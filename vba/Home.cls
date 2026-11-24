' Home (sheet module)
' Fits columns A to AF to the width of the window when the sheet is opened,
' so the cards fill the screen on any computer.
' See docs/decisions.md, "Home sheet"

Private Sub Worksheet_Activate()
    ' Don't show the steps on screen
    Application.ScreenUpdating = False

    ' Zoom so that columns A to AF fill the width of the window
    Me.Range("A1:AF1").Select
    ActiveWindow.Zoom = True

    ' Go to the top left corner
    ActiveWindow.ScrollRow = 1
    ActiveWindow.ScrollColumn = 1
    Me.Range("A1").Select

    Application.ScreenUpdating = True
End Sub
