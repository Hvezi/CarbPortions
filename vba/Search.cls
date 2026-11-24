' Search (sheet module)
' 1. Sets the results back to page 1 when the user changes the search or the page size.
' 2. Sets the zoom to 80% when the sheet is opened.
' Input:  SearchTerm, ResultLimit (named cells in the Search sheet)
' Output: PageNumber = 1
' See docs/decisions.md, "Results in pages"

Private Sub Worksheet_Change(ByVal Target As Range)
    ' Leave if the changed cell is not the search or the page size
    If Intersect(Target, Union(Me.Range("SearchTerm"), Me.Range("ResultLimit"))) Is Nothing Then Exit Sub

    ' Turn events off, so changing the page doesn't run this macro again
    Application.EnableEvents = False

    ' Go back to the first page
    Me.Range("PageNumber").Value = 1

    ' Turn events back on
    Application.EnableEvents = True
End Sub

Private Sub Worksheet_Activate()
    ' Same view every time: 80%, top left, cursor in the search box
    ActiveWindow.Zoom = 80
    ActiveWindow.ScrollRow = 1
    ActiveWindow.ScrollColumn = 1
    Me.Range("SearchTerm").Select
End Sub
