' modSearch (module)
' Buttons ‹ and › next to the page number in the Search sheet.
' Input:  PageNumber, SearchPages (named cell and named formula)
' Output: PageNumber one page down or up, never below 1 or above the last page
' See docs/decisions.md, "Results in pages"

Sub PrevPage()
    With ThisWorkbook.Worksheets("Search").Range("PageNumber")
        If .Value > 1 Then .Value = .Value - 1
    End With
End Sub

Sub NextPage()
    Dim pages As Long
    ' Number of pages of the current search
    pages = ThisWorkbook.Worksheets("Search").Evaluate("SearchPages")
    With ThisWorkbook.Worksheets("Search").Range("PageNumber")
        If .Value < pages Then .Value = .Value + 1
    End With
End Sub
