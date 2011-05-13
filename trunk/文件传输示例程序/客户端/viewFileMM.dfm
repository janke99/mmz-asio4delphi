object view_FileMM: Tview_FileMM
  Left = 259
  Top = 221
  Width = 451
  Height = 502
  Caption = #25991#20214#31649#29702
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 12
  object lv_FileLst: TListView
    Left = 0
    Top = 41
    Width = 443
    Height = 427
    Align = alClient
    Columns = <
      item
        Caption = #25991#20214#21517
        Width = 150
      end
      item
        Caption = #23384#20648#26041#21521
        Width = 60
      end
      item
        Caption = #29366#24577
        Width = 60
      end
      item
        Caption = #19979#36733#36827#24230
        Width = 80
      end
      item
        Caption = #25991#20214#22823#23567
        Width = 80
      end>
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 443
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object btn1: TButton
      Left = 328
      Top = 8
      Width = 75
      Height = 25
      Caption = #19978#20256
      TabOrder = 0
      Visible = False
      OnClick = btn1Click
    end
    object Button1: TButton
      Left = 24
      Top = 8
      Width = 75
      Height = 25
      Caption = #19979#36733
      TabOrder = 1
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 216
      Top = 8
      Width = 81
      Height = 25
      Caption = #21024#38500#26412#22320#25991#20214
      TabOrder = 2
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 120
      Top = 8
      Width = 75
      Height = 25
      Caption = #21047#26032
      TabOrder = 3
      OnClick = Button3Click
    end
  end
end
