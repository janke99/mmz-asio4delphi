object frm_main: Tfrm_main
  Left = 216
  Top = 133
  Width = 582
  Height = 420
  Caption = #25968#25454#26381#21153#22120#28436#31034#31243#24207
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lvLog: TListView
    Left = 0
    Top = 0
    Width = 566
    Height = 382
    Align = alClient
    BevelInner = bvNone
    BevelOuter = bvNone
    Columns = <
      item
        Caption = #26102#38388
        MaxWidth = 200
        MinWidth = 120
        Width = 180
      end
      item
        AutoSize = True
        Caption = #26085#24535#20869#23481
      end>
    ColumnClick = False
    GridLines = True
    SmallImages = ImageListLogLevel
    StateImages = ImageListLogLevel
    TabOrder = 0
    ViewStyle = vsReport
  end
  object ImageListLogLevel: TImageList
    Left = 360
    Bitmap = {
      494C010105000600040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000002000000001002000000000000020
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000008484840000000000000000008484840000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000084848400FFFFFF0000000000000000008484840000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000FFFFFF00FFFFFF0000000000FFFFFF00FFFFFF0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000FFFFFF000000000000000000FFFFFF008484840084848400000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000084848400000000000000
      0000000000000000000000000000848484000000000000000000000000000000
      000000000000000000000000000063639C000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000084848400FFFFFF00FFFFFF000000
      0000FFFFFF000000000000000000C6C6C6000000000000000000000000000000
      0000000000000000000063639C00319CCE000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000084848400FFFFFF00000000000000
      0000FFFFFF0084848400C6C6C600FFFFFF008484840000000000FFFFFF008484
      84000000000063639C00319CCE0063CEFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000008484840000000000000000000000
      0000848484000000000000000000FFFFFF0000000000FFFFFF00FFFFFF00FFFF
      FF0063639C00319CCE0063CEFF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008484
      8400000000000000000000000000000000000000000000000000FFFFFF006363
      9C00319CCE0063CEFF0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000C6C6C600C6C6
      C6000000000000000000FFFFFF0000000000000000000000000063639C00319C
      CE0063CEFF000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000084848400C6C6C600FFFF
      FF0000000000FFFFFF00FFFFFF00FFFFFF000000000063639C00319CCE0063CE
      FF00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000848484008484
      84000000000000000000FFFFFF00FFFFFF0063639C00319CCE0063CEFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000063639C00319CCE0063CEFF00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000063639C00319CCE0063CEFF0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000063639C00319CCE0063CEFF000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000009C3100009C310000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000009C310000FFFFFF009C310000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000063CEFF00319CCE00319C
      CE00319CCE00319CCE00319CCE00319CCE00319CCE00319CCE00319CCE00319C
      CE00319CCE0063CEFF0000000000000000000000000000000000000000000000
      00009C9CCE0000008400000084000000840000008400000084009C9CCE000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000009C310000FFFFFF00FFFFFF009C310000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000063CEFF00319CCE0000FFFF0000FF
      FF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FF
      FF0000FFFF00319CCE0063CEFF00000000000000000000000000000000000000
      84000000CE000000FF000000FF000000FF000000FF000000FF000000CE000000
      840000000000000000000000000000000000000000000000000000000000CE9C
      63009C3100009C3100009C310000FFFFFF00FFFFFF009C3100009C310000CE9C
      6300000000000000000000000000000000000000000000000000000000000000
      0000000000000000000063CEFF00319CCE00319CCE0063CEFF00000000000000
      000000000000000000000000000000000000319CCE0000FFFF0000FFFF0000FF
      FF0000FFFF0000FFFF00319CCE0000316300319CCE0000FFFF0000FFFF0000FF
      FF0000FFFF0000FFFF00319CCE00000000000000000000000000000084000000
      FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000
      FF000000840000000000000000000000000000000000000000009C310000CE9C
      6300FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CE9C
      63009C3100000000000000000000000000000000000000000000319CCE00319C
      CE00319CCE00319CCE00319CCE0063CEFF0063CEFF00319CCE00319CCE00319C
      CE00319CCE00319CCE000000000000000000319CCE0000FFFF0000FFFF0000FF
      FF0000FFFF0000FFFF0000316300003163000031630000FFFF0000FFFF0000FF
      FF0000FFFF0000FFFF00319CCE000000000000000000000084000000FF000000
      FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000
      FF000000FF00000084000000000000000000000000009C310000FFFFFF00FFFF
      FF00FFFFFF009C3100009C3100009C3100009C3100009C310000FFFFFF00FFFF
      FF00FFFFFF009C31000000000000000000000000000000000000319CCE009CFF
      FF00FFFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0063CEFF0063CE
      FF0063CEFF00319CCE000000000000000000319CCE0063CEFF0000FFFF0000FF
      FF0000FFFF0000FFFF00319CCE0000316300319CCE0000FFFF0000FFFF0000FF
      FF0000FFFF0063CEFF00319CCE00000000009C9CCE000000CE000000FF000000
      FF00FFFFFF00FFFFFF000000FF000000FF000000FF00FFFFFF00FFFFFF000000
      FF000000FF000000CE009C9CCE0000000000CE9C6300CE9C6300FFFFFF00FFFF
      FF00FFFFFF00FFFFFF009C3100009C3100009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CE9C6300CE9C630000000000000000000000000000000000319C
      CE009CFFFF00FFFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0063CE
      FF00319CCE0000000000000000000000000063CEFF00319CCE0000FFFF0000FF
      FF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FF
      FF0000FFFF00319CCE0063CEFF0000000000000084000000FF000000FF000000
      FF00FFFFFF00FFFFFF00FFFFFF000000FF00FFFFFF00FFFFFF00FFFFFF000000
      FF000000FF000000FF0000008400000000009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF009C3100009C3100009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF009C310000000000000000000000000000000000000000
      0000319CCE0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF00319C
      CE000000000000000000000000000000000000000000319CCE0063CEFF0000FF
      FF0000FFFF0000FFFF0063CEFF000031630063CEFF0000FFFF0000FFFF0000FF
      FF0063CEFF00319CCE000000000000000000000084000000FF000000FF000000
      FF000000FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000FF000000
      FF000000FF000000FF0000008400000000009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF009C3100009C3100009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF009C310000000000000000000000000000000000000000
      0000319CCE0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF00319C
      CE00000000000000000000000000000000000000000063CEFF00319CCE0000FF
      FF0000FFFF0000FFFF00319CCE0000316300319CCE0000FFFF0000FFFF0000FF
      FF00319CCE0063CEFF000000000000000000000084000000FF000000FF000000
      FF000000FF000000FF00FFFFFF00FFFFFF00FFFFFF000000FF000000FF000000
      FF000000FF000000FF0000008400000000009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF009C3100009C3100009C3100009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF009C310000000000000000000000000000000000000000
      0000319CCE0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF00319C
      CE00000000000000000000000000000000000000000000000000319CCE0063CE
      FF0000FFFF0000FFFF0031639C000031630031639C0000FFFF0000FFFF0063CE
      FF00319CCE00000000000000000000000000000084000000FF000000FF000000
      FF000000FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF000000FF000000
      FF000000FF000000FF0000008400000000009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF009C310000000000000000000000000000000000000000
      0000319CCE00FFFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF00319C
      CE0000000000000000000000000000000000000000000000000063CEFF00319C
      CE0000FFFF0000FFFF0000316300003163000031630000FFFF0000FFFF00319C
      CE0063CEFF00000000000000000000000000000084000000FF000000FF000000
      FF00FFFFFF00FFFFFF00FFFFFF000000FF00FFFFFF00FFFFFF00FFFFFF000000
      FF000000FF000000FF0000008400000000009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CE9C63009C310000CE9C6300FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF009C310000000000000000000000000000000000000000
      000063CEFF0063CEFF00FFFFFF0000FFFF0000FFFF0000FFFF0063CEFF0063CE
      FF0000000000000000000000000000000000000000000000000000000000319C
      CE0063CEFF0000FFFF0000316300003163000031630000FFFF0063CEFF00319C
      CE00000000000000000000000000000000009C9CCE000000CE000000FF000000
      FF00FFFFFF00FFFFFF000000FF000000FF000000FF00FFFFFF00FFFFFF000000
      FF000000FF000000CE009C9CCE0000000000CE9C6300CE9C6300FFFFFF00FFFF
      FF00FFFFFF00FFFFFF009C3100009C3100009C310000FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CE9C6300CE9C6300000000000000000000000000000000000000
      000000000000319CCE009CFFFF00FFFFFF0000FFFF0000FFFF00319CCE000000
      00000000000000000000000000000000000000000000000000000000000063CE
      FF00319CCE0000FFFF00319CCE0000316300319CCE0000FFFF00319CCE0063CE
      FF000000000000000000000000000000000000000000000084000000FF000000
      FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000
      FF000000FF00000084000000000000000000000000009C310000FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CE9C63009C310000CE9C6300FFFFFF00FFFFFF00FFFF
      FF00FFFFFF009C31000000000000000000000000000000000000000000000000
      00000000000000000000319CCE00319CCE00319CCE00319CCE00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000319CCE0063CEFF0000FFFF0000FFFF0000FFFF0063CEFF00319CCE000000
      0000000000000000000000000000000000000000000000000000000084000000
      FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000
      FF000000840000000000000000000000000000000000000000009C310000CE9C
      6300FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CE9C
      63009C3100000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000063CEFF00319CCE00319CCE00319CCE00319CCE00319CCE0063CEFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      84000000CE000000FF000000FF000000FF000000FF000000FF000000CE000000
      840000000000000000000000000000000000000000000000000000000000CE9C
      63009C3100009C3100009C3100009C3100009C3100009C3100009C310000CE9C
      6300000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000063CEFF0063CEFF0063CEFF0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00009C9CCE0000008400000084000000840000008400000084009C9CCE000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000200000000100010000000000000100000000000000000000
      000000000000000000000000FFFFFF00FCFF000000000000F87F000000000000
      F07F000000000000E07F000000000000C03F000000000000803E000000000000
      001C000000000000000800000000000000010000000000008003000000000000
      8007000000000000800F000000000000C01F000000000000E03F000000000000
      F07F000000000000F8FF000000000000FF3FFFFFFFFFFFFFFE3FFFFF8003F01F
      FC3FFFFF0001E00FE00FFC3F0001C007C007C003000180038003C00300010001
      0001E007000100010001F00F800300010001F00F800300010001F00FC0070001
      0001F00FC00700010001F00FE00F00010001F81FE00F80038003FC3FF01FC007
      C007FFFFF01FE00FE00FFFFFFC7FF01F00000000000000000000000000000000
      000000000000}
  end
end
