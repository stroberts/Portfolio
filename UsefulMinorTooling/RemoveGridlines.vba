Sub RemoveGridlines()
Dim i As Integer
For i = 1 To Worksheets.Count
    Sheets(i).Select
    ActiveWindow.DisplayGridlines = False
Next i

End Sub