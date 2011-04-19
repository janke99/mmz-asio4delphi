object frm_main: Tfrm_main
  Left = 296
  Top = 163
  Width = 685
  Height = 513
  Caption = #36828#31243#25968#25454#24211#28436#31034#23458#25143#31471#31243#24207
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnl_head: TPanel
    Left = 0
    Top = 0
    Width = 677
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lbl_hint: TLabel
      Left = 72
      Top = 8
      Width = 569
      Height = 33
      AutoSize = False
      Caption = 
        #20351#29992#26412#36828#31243#23545#35937#65292#19981#29992#23433#35013#20219#20309#31532'3'#26041#25511#20214#65292#23601#21487#20351'ClientDataset'#20855#26377#25805#20316#36828#31243#25968#25454#24211#30340#33021#21147#13#10#26597#35810#20986#25968#25454#21518#65292#30452#25509#22312'dbgr' +
        'id'#20869#30340#20462#25913#23558#20250#33258#21160#25552#20132#21040#36828#31243#25968#25454#24211
    end
  end
  object pgc_ctl: TPageControl
    Left = 0
    Top = 49
    Width = 677
    Height = 430
    ActivePage = ts_one
    Align = alClient
    TabOrder = 1
    OnChange = pgc_ctlChange
    object ts_one: TTabSheet
      Caption = #36828#31243#25968#25454#28436#31034
      object DBGrid1: TDBGrid
        Left = 0
        Top = 0
        Width = 669
        Height = 320
        Align = alTop
        DataSource = ds1
        ImeName = 'Chinese (Simplified) - US Keyboard'
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
      object Button1: TButton
        Left = 224
        Top = 336
        Width = 129
        Height = 25
        Caption = 'SQl'#35821#21477#25191#34892#21024#38500
        TabOrder = 1
        OnClick = Button1Click
      end
      object Button2: TButton
        Left = 85
        Top = 336
        Width = 129
        Height = 25
        Caption = 'Append'#26041#24335#26032#22686
        TabOrder = 2
        OnClick = Button2Click
      end
      object Button3: TButton
        Left = 85
        Top = 369
        Width = 75
        Height = 25
        Caption = 'SQl'#35821#21477#26597#35810
        TabOrder = 3
        OnClick = Button3Click
      end
      object Button4: TButton
        Left = 224
        Top = 369
        Width = 129
        Height = 25
        Caption = 'delete'#26041#27861#21024#38500#25152#36873
        TabOrder = 4
        OnClick = Button4Click
      end
      object Button5: TButton
        Left = 3
        Top = 336
        Width = 75
        Height = 25
        Caption = #26597#35810#26174#31034
        TabOrder = 5
        OnClick = Button5Click
      end
      object Button6: TButton
        Left = 365
        Top = 335
        Width = 129
        Height = 25
        Caption = #27169#25311#36828#31471'SQl'#35821#21477#38169#35823
        TabOrder = 6
        OnClick = Button6Click
      end
      object btn1: TButton
        Left = 366
        Top = 369
        Width = 129
        Height = 25
        Caption = #25209#37327#25191#34892'SQL'#35821#21477
        TabOrder = 7
        OnClick = btn1Click
      end
      object btn2: TButton
        Left = 520
        Top = 337
        Width = 131
        Height = 25
        Caption = #25209#37327#25554#20837#24615#33021#27979#35797
        TabOrder = 8
        OnClick = btn2Click
      end
      object Button7: TButton
        Left = 517
        Top = 371
        Width = 132
        Height = 21
        Caption = #23458#25143#31471#33258#21160#21319#32423
        TabOrder = 9
        OnClick = Button7Click
      end
    end
    object ts_two: TTabSheet
      Caption = #22823#20108#36827#21046#23383#27573#23384#21462#28436#31034
      ImageIndex = 1
      object pnlower: TPanel
        Left = 137
        Top = 0
        Width = 532
        Height = 402
        Align = alClient
        Caption = 'pnlower'
        ParentBackground = False
        TabOrder = 0
      end
      object ListBox1: TListBox
        Left = 0
        Top = 0
        Width = 137
        Height = 402
        Align = alLeft
        DragMode = dmAutomatic
        ImeName = 'Chinese (Simplified) - US Keyboard'
        ItemHeight = 13
        Items.Strings = (
          #25302#25918#33410#28857'1'
          #25302#25918#33410#28857'1'
          #25302#25918#33410#28857'1')
        TabOrder = 1
      end
    end
    object ts_sub: TTabSheet
      Caption = #20027#20174#34920#28436#31034
      ImageIndex = 2
      object Label1: TLabel
        Left = 70
        Top = 185
        Width = 146
        Height = 13
        Caption = #19978#36793#26159#20027#34920'  '#19979#36793#26159#20174#34920
      end
      object DBGrid2: TDBGrid
        Left = 0
        Top = 0
        Width = 669
        Height = 171
        Align = alTop
        DataSource = ds_master
        ImeName = 'Chinese (Simplified) - US Keyboard'
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
      object DBGrid3: TDBGrid
        Left = 0
        Top = 213
        Width = 669
        Height = 189
        Align = alBottom
        DataSource = ds_slave
        ImeName = 'Chinese (Simplified) - US Keyboard'
        TabOrder = 1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
    end
  end
  object ds1: TDataSource
    Left = 20
    Top = 169
  end
  object ds_master: TDataSource
    Left = 633
    Top = 82
  end
  object ds_slave: TDataSource
    Left = 638
    Top = 300
  end
end
