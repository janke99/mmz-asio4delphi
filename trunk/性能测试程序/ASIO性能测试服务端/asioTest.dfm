object view_main: Tview_main
  Left = 192
  Top = 114
  Width = 320
  Height = 336
  Caption = 'ASIO'#24615#33021#27979#35797#26381#21153#31471
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  object lbl1: TLabel
    Left = 32
    Top = 32
    Width = 84
    Height = 12
    Caption = #24403#21069#36830#25509#24635#25968#65306
  end
  object lbl_Clientcount: TLabel
    Left = 160
    Top = 32
    Width = 6
    Height = 12
  end
  object Label1: TLabel
    Left = 32
    Top = 56
    Width = 108
    Height = 12
    Caption = #24403#21069#25509#25910#25968#25454#24635#25968#65306
  end
  object lbl_TotRcv: TLabel
    Left = 160
    Top = 56
    Width = 6
    Height = 12
  end
  object Label2: TLabel
    Left = 32
    Top = 80
    Width = 108
    Height = 12
    Caption = #24403#21069#21457#36865#25968#25454#24635#25968#65306
    Visible = False
  end
  object lbl_Sendtot: TLabel
    Left = 160
    Top = 80
    Width = 6
    Height = 12
    Visible = False
  end
  object Label4: TLabel
    Left = 32
    Top = 104
    Width = 108
    Height = 12
    Caption = #24403#21069#29992#25143#20869#23384#24635#25968#65306
  end
  object lbl_ClientMemtot: TLabel
    Left = 160
    Top = 104
    Width = 6
    Height = 12
  end
  object Label3: TLabel
    Left = 32
    Top = 128
    Width = 108
    Height = 12
    Caption = #24403#21069#21457#36865#32531#20914#24635#25968#65306
  end
  object lbl_SendBuff: TLabel
    Left = 160
    Top = 128
    Width = 6
    Height = 12
  end
  object Label5: TLabel
    Left = 40
    Top = 208
    Width = 36
    Height = 12
    Caption = 'Label5'
    Visible = False
  end
  object btn1: TButton
    Left = 112
    Top = 232
    Width = 75
    Height = 25
    Caption = #26242#20572
    TabOrder = 0
    OnClick = btn1Click
  end
  object Button1: TButton
    Left = 200
    Top = 232
    Width = 75
    Height = 25
    Caption = #24674#22797
    TabOrder = 1
    OnClick = Button1Click
  end
  object tmr1: TTimer
    Interval = 3000
    OnTimer = tmr1Timer
    Left = 40
    Top = 160
  end
end
