object ASIO_test: TASIO_test
  Left = 749
  Top = 177
  Width = 335
  Height = 558
  Caption = 'ASIO'#26381#21153#31471#24615#33021#27979#35797#31243#24207
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  object lbl_hint: TLabel
    Left = 17
    Top = 34
    Width = 6
    Height = 12
  end
  object ListBox1: TListBox
    Left = 0
    Top = 73
    Width = 327
    Height = 451
    Align = alClient
    ImeName = 'Chinese (Simplified) - US Keyboard'
    ItemHeight = 12
    TabOrder = 0
    Visible = False
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 327
    Height = 73
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object lbl1: TLabel
      Left = 16
      Top = 9
      Width = 72
      Height = 12
      Caption = #26381#21153#22120#22320#22336#65306
    end
    object Label1: TLabel
      Left = 40
      Top = 30
      Width = 48
      Height = 12
      Caption = #36830#25509#25968#65306
    end
    object lbl_conn: TLabel
      Left = 208
      Top = 56
      Width = 6
      Height = 12
    end
    object edt1: TEdit
      Left = 98
      Top = 5
      Width = 95
      Height = 20
      ImeName = 'Chinese (Simplified) - US Keyboard'
      TabOrder = 0
      Text = '127.0.0.1'
    end
    object Button1: TButton
      Left = 208
      Top = 11
      Width = 75
      Height = 25
      Caption = #24320#22987#27979#35797
      TabOrder = 1
      OnClick = Button1Click
    end
    object Edit1: TEdit
      Left = 98
      Top = 26
      Width = 57
      Height = 20
      ImeName = 'Chinese (Simplified) - US Keyboard'
      TabOrder = 2
      Text = '10'
    end
    object CheckBox1: TCheckBox
      Left = 97
      Top = 50
      Width = 97
      Height = 17
      Caption = #25171#21360#20449#24687
      TabOrder = 3
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 73
    Width = 327
    Height = 451
    Align = alClient
    ImeName = 'Chinese (Simplified) - US Keyboard'
    Lines.Strings = (
      #27979#35797#27969#31243#35828#26126#65306
      #23458#25143#31471#24320#22987#27979#35797#21518#23558#19982#26381#21153#22120#24314#31435#36830#25509#65292#24182#19988#21457#36865'520'#23383#33410#30340
      #25968#25454#65292#27599#27425#21457#36865#20250#26377#19968#20010#38543#26426#25968#65292#20174#31532'100'#23383#33410#24320#22987'10'#20010#23383#33410
      #35760#24405#38543#26426#25968#23383#65292#26381#21153#31471#36816#31639#23436#25104#21518#36820#22238#19968#20010#36816#31639#32467#26524#65292#23458#25143
      #31471#26174#31034#21453#39304#26102#38388
      #21644#36816#31639#26159#21542#27491#30830)
    TabOrder = 2
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 56
    Top = 200
  end
end
