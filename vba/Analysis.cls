' Analysis (sheet module)
' Fits the dashboard to the width of the window when the sheet is opened.
' Works on any screen size.
' See docs/decisions.md, D21

Private Sub Worksheet_Activate()
    Dim lastCol As Long

    ' Don't show the steps on screen
    Application.ScreenUpdating = False

    ' Last column: where the slicer box ends, plus one column of margin
    lastCol = Me.Shapes("Slicers").BottomRightCell.Column + 1

    ' Zoom so that columns A to lastCol fill the width of the window
    Me.Range(Me.Cells(1, 1), Me.Cells(1, lastCol)).Select
    ActiveWindow.Zoom = True

    ' Go to the top left corner
    ActiveWindow.ScrollRow = 1
    ActiveWindow.ScrollColumn = 1
    Me.Range("A1").Select

    Application.ScreenUpdating = True
End Sub
