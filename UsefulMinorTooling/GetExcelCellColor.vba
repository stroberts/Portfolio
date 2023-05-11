Sub GetRGBColor_Fill()
'PURPOSE: Output the RGB color code for the ActiveCell's Fill Color
'SOURCE: www.TheSpreadsheetGuru.com

Dim HEXcolor As String
Dim RGBcolor As String

HEXcolor = Right("000000" & Hex(ActiveCell.Interior.Color), 6)

RGBcolor = "RGB (" & CInt("&H" & Right(HEXcolor, 2)) & _
", " & CInt("&H" & Mid(HEXcolor, 3, 2)) & _
", " & CInt("&H" & Left(HEXcolor, 2)) & ")"

MsgBox RGBcolor, vbInformation, "Cell " & ActiveCell.Address(False, False) & ":  Fill Color"

End Sub