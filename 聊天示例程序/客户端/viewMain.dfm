object view_Main: Tview_Main
  Left = 329
  Top = 227
  Width = 494
  Height = 423
  Caption = #23458#25143#31471
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 12
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 486
    Height = 49
    Align = alTop
    ParentBackground = False
    TabOrder = 0
    object Edit1: TEdit
      Left = 24
      Top = 16
      Width = 121
      Height = 20
      ImeName = 'Chinese (Simplified) - US Keyboard'
      TabOrder = 0
      Text = '127.0.0.1'
    end
    object btn1: TButton
      Left = 282
      Top = 14
      Width = 75
      Height = 25
      Caption = #36830#25509#24182#30331#24405
      TabOrder = 1
      OnClick = btn1Click
    end
    object Edit2: TEdit
      Left = 152
      Top = 16
      Width = 121
      Height = 20
      ImeName = 'Chinese (Simplified) - US Keyboard'
      TabOrder = 2
      Text = #23567#24378
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 49
    Width = 486
    Height = 340
    Align = alClient
    ParentBackground = False
    TabOrder = 1
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 484
      Height = 271
      Align = alClient
      Caption = 'Panel3'
      ParentBackground = False
      TabOrder = 0
      object Panel5: TPanel
        Left = 328
        Top = 1
        Width = 155
        Height = 269
        Align = alRight
        Caption = 'Panel5'
        ParentBackground = False
        TabOrder = 0
        object ListBox1: TListBox
          Left = 1
          Top = 1
          Width = 153
          Height = 267
          Align = alClient
          ImeName = 'Chinese (Simplified) - US Keyboard'
          ItemHeight = 12
          TabOrder = 0
        end
      end
      object mmo_show: TMemo
        Left = 1
        Top = 1
        Width = 327
        Height = 269
        Align = alClient
        ImeName = 'Chinese (Simplified) - US Keyboard'
        TabOrder = 1
      end
    end
    object Panel4: TPanel
      Left = 1
      Top = 272
      Width = 484
      Height = 67
      Align = alBottom
      Caption = 'Panel4'
      ParentBackground = False
      TabOrder = 1
      object Panel6: TPanel
        Left = 328
        Top = 1
        Width = 155
        Height = 65
        Align = alRight
        ParentBackground = False
        TabOrder = 0
        object Button2: TButton
          Left = 40
          Top = 7
          Width = 75
          Height = 25
          Caption = #21457#35328
          TabOrder = 0
          OnClick = Button2Click
        end
        object Button3: TButton
          Left = 40
          Top = 33
          Width = 75
          Height = 25
          Caption = #21457#25991#20214
          TabOrder = 1
          Visible = False
          OnClick = Button3Click
        end
      end
      object mmo_write: TMemo
        Left = 1
        Top = 1
        Width = 327
        Height = 65
        Align = alClient
        ImeName = 'Chinese (Simplified) - US Keyboard'
        Lines.Strings = (
          #38543#20415#35828#28857#21861)
        TabOrder = 1
      end
    end
  end
  object tmr_rcv: TTimer
    Enabled = False
    Interval = 10
    OnTimer = tmr_rcvTimer
    Left = 289
    Top = 346
  end
  object tmr_getlst: TTimer
    Enabled = False
    Interval = 300
    OnTimer = tmr_getlstTimer
    Left = 265
    Top = 282
  end
end
