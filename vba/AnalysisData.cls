' AnalysisData (sheet module)
' Runs every time a slicer updates a pivot table of this sheet.
' 1. Labels chart: the top line marks the highest carb range chosen (100g if none).
' 2. Doughnut: brands not chosen in the brand slicer turn grey.
' See docs/decisions.md, D22 and D23

Private Sub Worksheet_PivotTableUpdate(ByVal Target As PivotTable)
    Dim sc As SlicerCache, it, v As Double, mx As Double

    ' Highest carb range chosen: "20-30g" gives 30
    Set sc = ThisWorkbook.SlicerCaches("Slicer_carb_band")
    mx = 100
    If Not sc.FilterCleared Then
        mx = 0
        For Each it In sc.VisibleSlicerItemsList
            v = Val(Split(Split(it, "&[")(1), "-")(1))
            If v > mx Then mx = v
        Next it
        If mx = 0 Then mx = 100
    End If

    ' Axis a little longer than the range, line at 105% so the bar labels don't touch it,
    ' and the label of the line shows the real top ("30g")
    With ThisWorkbook.Worksheets("Analysis").ChartObjects("Labels chart").Chart.Axes(xlValue)
        .MaximumScale = mx * 1.12
        .MajorUnit = mx * 1.05
        .TickLabels.NumberFormat = """" & mx & "g"";;"
    End With

    ' Brands chosen in the brand slicer (empty if none)
    Dim bc As SlicerCache, s As Series, x, i As Long, picked As Boolean, sel As String
    Set bc = ThisWorkbook.SlicerCaches("Slicer_brand_type")
    sel = ""
    If Not bc.FilterCleared Then
        For Each it In bc.VisibleSlicerItemsList
            sel = sel & it
        Next it
    End If

    ' Colour of each slice: its own colour if chosen, grey if not
    Set s = ThisWorkbook.Worksheets("Analysis").ChartObjects("Brand chart").Chart.SeriesCollection(1)
    x = s.XValues
    For i = 1 To s.Points.Count
        picked = (sel = "") Or (InStr(sel, "&[" & x(i) & "]") > 0)
        If Not picked Then
            s.Points(i).Format.Fill.ForeColor.RGB = RGB(225, 225, 225)
        ElseIf x(i) = "Private labels" Then
            s.Points(i).Format.Fill.ForeColor.RGB = RGB(231, 63, 30)
        ElseIf x(i) = "Other brands" Then
            s.Points(i).Format.Fill.ForeColor.RGB = RGB(249, 182, 55)
        Else
            s.Points(i).Format.Fill.ForeColor.RGB = RGB(255, 221, 156)
        End If
    Next i
End Sub
