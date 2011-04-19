{*******************************************************
      单元名：  ViewGraph.pas
      创建日期：2009-06-29 15:40:23
      创建者    马敏钊
      功能：    导航视图

*******************************************************}

unit ViewGraph;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, RzButton, RzPanel, RzTreeVw, dbclient;

type
  TView_Graph = class;
  TViewItem = class
  private
    FAutoChangeTime: TTimer; //用来在改变了位置之后自动提交数据
    Fx, Fy, Foldx, Foldy: Integer; //坐标
    FFount: TFont;
    procedure OnAutoPostTime(Sender: TObject);

    procedure setx(const Value: integer);
    procedure sety(const Value: integer);

  public
    FView: TView_Graph;
    FdbID: integer; //自己的数据库ID
    FCpt: string; //标注
    Fkind: Integer; //标注类别
    FLinkID: integer; //连接的节点ID
    FPic: TBitmap; //容纳的图片对象
    FRect: TRect; //区域
    property x: integer read Fx write setx;
    property y: integer read Fy write sety;
    property Font: TFont read FFount write FFount;
    constructor Create(IView: TView_Graph);
    destructor destroy; override;
  end;
  TInfoMap = class
    id: string;
    Cpt: string;
  end;

  TView_Graph = class(TForm)
    img_head: TImage;
    lbl_hint: TLabel;
    RzPanel1: TRzPanel;
    RzBitBtn1: TRzBitBtn;
    dlgOpen: TOpenDialog;
    pl_Ower: TRzPanel;
    scrlbx_hoder: TScrollBox;
    img_hoder: TImage;
    procedure RzBitBtn1Click(Sender: TObject);
    procedure pl_OwerResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btn_SetEdtStateClick(Sender: TObject);
    procedure img_hoderDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure img_hoderDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FormDestroy(Sender: TObject);
    procedure img_hoderMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure img_hoderMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure img_hoderMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure img_hoderDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    CurrState: integer; //当前状态 9 可编辑 其它非编辑状态

    FFace, FbackGround: TBitmap;
    FCanvas: TCanvas;
    Fitemlst: TStrings; // 焦点对象
    FDragobj: TViewItem; //拖放对象
    FwantView: Boolean; //双击打算看视频
    function FindObj(x, y: integer): TViewItem;
    procedure SetState(const Value: Integer);
  public
    Model: integer;
    GSelobj: TInfoMap; //当前选中的对象
    FDataQry: TClientDataSet;

    property EditState: Integer read CurrState write SetState;


    //树模块单击事件
    procedure OnModelTreeClick(Sender: TObject);
    //从数据库读取相关数据
    procedure ReadInfoFromDB;

    function OpenBmp(IFileName: string; IsNew: boolean = true): boolean;
    procedure DrawBg; //绘制背景
    procedure DrawItems; //绘制焦点对象
    procedure DrawToShow; //绘制到显示区域
    procedure DrawAll;
  end;

var
  View_Graph: TView_Graph;

implementation

uses untfunctions, ComCtrls, pmybasedebug, DB, UntRemSql;

{$R *.dfm}

procedure TView_Graph.RzBitBtn1Click(Sender: TObject);
begin
  if (GSelobj <> nil) then begin
    if dlgOpen.Execute then begin
      OpenBmp(dlgOpen.FileName);
    end;
  end
  else begin
    ErrorInfo('请先从树内选择要查看的站点！');
  end;
end;

procedure TView_Graph.pl_OwerResize(Sender: TObject);
begin
  scrlbx_hoder.Top := 0;
  scrlbx_hoder.Left := 0;
  scrlbx_hoder.Height := pl_Ower.Height;
  scrlbx_hoder.Width := pl_Ower.Width;
end;

function TView_Graph.OpenBmp(IFileName: string; IsNew: boolean = true): boolean;
begin
  Result := false;
  if FileExists(IFileName) then begin
    img_hoder.Picture.LoadFromFile(IFileName);
    img_hoder.AutoSize := true;
    img_hoder.Top := 0;
    img_hoder.Left := 0;
    img_hoder.AutoSize := False;
    FCanvas := img_hoder.Canvas;
    if img_hoder.Width > FFace.Width then begin
      FFace.Width := img_hoder.Width;
      FFace.Height := img_hoder.Height;
      FbackGround.Width := FFace.Width;
      FbackGround.Height := FFace.Height;
    end;
    FFace.Canvas.Draw(0, 0, img_hoder.Picture.Graphic);
    FbackGround.Canvas.Draw(0, 0, FFace);
    if IsNew then begin
      if Model > 0 then
        FDataQry.Edit
      else
        FDataQry.Insert;
      FDataQry.FieldByName('FReMark').AsString := GSelobj.Cpt;
      FDataQry.FieldByName('FnodeID').AsString := GSelobj.Id;
      FDataQry.FieldByName('FKind').AsInteger := 999;
      TBlobField(FDataQry.FieldByName('Fbg')).LoadFromFile(IFileName);
      FDataQry.Post;
    end;
    Result := true;
  end;
  DrawAll;
end;

procedure TView_Graph.FormCreate(Sender: TObject);
begin

  FFace := TBitmap.Create;
  FFace.Width := 1280;
  FFace.Height := 1024;
  FFace.PixelFormat := pf24bit;
  FFace.Canvas.FillRect(FFace.Canvas.ClipRect);
  FbackGround := TBitmap.Create;
  FbackGround.Assign(FFace);
  Fitemlst := TStringList.Create;
end;

procedure TView_Graph.btn_SetEdtStateClick(Sender: TObject);
begin
  if GSelobj <> nil then
    EditState := 9;
end;

procedure TView_Graph.img_hoderDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  if Source is TListBox then begin
    Accept := True
  end
  else
    Accept := False;
end;

procedure TView_Graph.img_hoderDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  LTreeview: TListBox;
  Litem: TViewItem;
begin
  if Source is TListBox then begin
    LTreeview := TListBox(Source);
    if LTreeview.ItemIndex > -1 then begin
      Litem := TViewItem.Create(Self);
      Litem.FCpt := LTreeview.Items[LTreeview.itemindex];
      Litem.FPic := TBitmap.Create;
      Litem.FPic.Transparent := True;
      Litem.FPic.LoadFromFile(GetCurrPath + 'dvs.bmp');
      Litem.Font := Litem.FPic.Canvas.Font;
      Litem.x := x;
      Litem.y := y;
      Fitemlst.AddObject('', Litem);
      DrawAll;
      FDataQry.Insert;
      FDataQry.FieldByName('FReMark').AsString := Litem.FCpt;
      FDataQry.FieldByName('Fx').AsInteger := x;
      FDataQry.FieldByName('Fy').AsInteger := y;
      FDataQry.FieldByName('FnodeID').AsInteger := Litem.FLinkID;
      FDataQry.FieldByName('FKind').AsInteger := Litem.Fkind;
      FDataQry.Post;
      Litem.FdbID := FDataQry.FieldValues['Fid'];
    end;
  end;
end;

procedure TView_Graph.FormDestroy(Sender: TObject);
begin
  ClearAndFreeList(Fitemlst);
end;

procedure TView_Graph.img_hoderMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  Lbuff: TViewItem;
begin
  FDragobj := FindObj(x, y);
end;

procedure TView_Graph.img_hoderMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if FDragobj <> nil then begin
    Screen.Cursor := crHandPoint;
    FDragobj.x := x;
    FDragobj.y := y;
    DrawAll;
  end
  else begin
    if FindObj(x, y) = nil then
      Screen.Cursor := crDefault
    else
      Screen.Cursor := crHandPoint;
  end;
end;


{ TViewItem }

constructor TViewItem.Create(IView: TView_Graph);
begin
  FView := IView;
end;

destructor TViewItem.destroy;
begin
  //如果要释放了立即保存一下
  FAutoChangeTime.Tag := 0;
  FAutoChangeTime.OnTimer(FAutoChangeTime);
  FAutoChangeTime.Free;
  inherited;
end;

procedure TViewItem.OnAutoPostTime(Sender: TObject);
begin
  FAutoChangeTime.Tag := TTimer(Sender).Tag - 1;
  if FAutoChangeTime.Tag <= 0 then begin
    FAutoChangeTime.Enabled := False;
    if FView.FDataQry.Locate('Fid', FdbID, []) then begin
      FView.FDataQry.Edit;
      FView.FDataQry.FieldByName('Fx').AsInteger := Foldx;
      FView.FDataQry.FieldByName('Fy').AsInteger := Foldy;
      FView.FDataQry.Post;
    end;
  end;
end;

procedure TViewItem.setx(const Value: integer);
begin
  if Foldx = Value then
    exit;

  Foldx := Value;
  Fx := Value - FPic.Width div 2;
  FRect := Rect(x, y, x + FPic.Width, y + FPic.Height);
  if FAutoChangeTime = nil then begin
    FAutoChangeTime := TTimer.Create(nil);
    FAutoChangeTime.OnTimer := OnAutoPostTime;
  end;

  if FAutoChangeTime.Enabled = false then begin
    FAutoChangeTime.Enabled := True;
  end;
  FAutoChangeTime.Tag := 3;
end;

procedure TViewItem.sety(const Value: integer);
begin
  if Foldy = Value then
    exit;

  Foldy := Value;
  Fy := Value - FPic.Height div 2;
  FRect := Rect(x, y, x + FPic.Width, y + FPic.Height);
  if FAutoChangeTime = nil then begin
    FAutoChangeTime := TTimer.Create(nil);
    FAutoChangeTime.OnTimer := OnAutoPostTime;
  end;

  if FAutoChangeTime.Enabled = false then begin
    FAutoChangeTime.Enabled := True;
  end;
  FAutoChangeTime.Tag := 3;
end;

procedure TView_Graph.DrawBg;
begin
  FFace.Canvas.Draw(0, 0, FbackGround);
end;

procedure TView_Graph.DrawItems;
var
  i: Integer;
  Lbuff: TViewItem;
begin
  for i := 0 to Fitemlst.Count - 1 do begin // Iterate
    Lbuff := TViewItem(Fitemlst.Objects[i]);
    FFace.Canvas.Draw(Lbuff.x, Lbuff.y, Lbuff.FPic);
    FFace.Canvas.Font.Color := clBlack;
    FFace.Canvas.Font.Height := 14;
    FFace.Canvas.Brush.Style := bsClear;
    FFace.Canvas.TextOut(Lbuff.FRect.Left, Lbuff.FRect.Bottom + 2, Lbuff.FCpt +
      Format('<%d,%d>', [Lbuff.x, Lbuff.y]));
    if FDragobj = Lbuff then begin
      FFace.Canvas.Pen.Color := clBlack;
      FFace.Canvas.DrawFocusRect(Lbuff.FRect);
    end;
  end; // for
end;

procedure TView_Graph.DrawToShow;
begin
  if FCanvas <> nil then
    FCanvas.Draw(0, 0, FFace);
end;

procedure TView_Graph.DrawAll;
begin
  DrawBg;
  DrawItems;
  DrawToShow;
end;

procedure TView_Graph.img_hoderMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (FDragobj <> nil) and (FwantView) then begin
    TipInfo('要看图像');
    FwantView := False;
  end;

  Screen.Cursor := crDefault;
  FDragobj := nil;
end;

function TView_Graph.FindObj(x, y: integer): TViewItem;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Fitemlst.Count - 1 do begin // Iterate
    if PtInRect(TViewItem(Fitemlst.Objects[i]).FRect, Point(x, y)) then begin
      Result := TViewItem(Fitemlst.Objects[i]);
      Exit;
    end;
  end; // for
end;

procedure TView_Graph.img_hoderDblClick(Sender: TObject);
begin
  FwantView := True;
end;

procedure TView_Graph.OnModelTreeClick(Sender: TObject);
var
  Lbuff: TInfoMap;
begin
  EditState := 0;
  if TListBox(Sender).ItemIndex = -1 then
    Exit;

  Lbuff := TInfoMap(TListBox(Sender).Items.Objects[TListBox(Sender).ItemIndex]);
    //如果是相同的点就退出
  if Lbuff = GSelobj then
    Exit;

  GSelobj := TInfoMap(TListBox(Sender).Items.Objects[TListBox(Sender).ItemIndex]);
  ReadInfoFromDB;
end;

procedure TView_Graph.ReadInfoFromDB;
var
  Lstream: TMemoryStream;
  Litem: TViewItem;
begin

  ClearList(Fitemlst);

  with Gob_Rmo.OpenDataset(FDataQry, 'select * from TNodeMap where FnodeID=%s', [GSelobj.Id]) do begin
    First;
    while not eof do begin
      if FieldValues['FKind'] = 999 then begin
        Lstream := TMemoryStream.Create;
        //导入背景图片
        TBlobField(FieldByName('FBg')).SaveToStream(Lstream);
        DeCompressStream(Lstream);
        Lstream.SaveToFile(GetCurrPath + 'tmpgview.bmp');
        OpenBmp(GetCurrPath + 'tmpgview.bmp', false);
        Lstream.Free;
        Model := FieldValues['Fid'];
      end
      else begin
        //导入节点
        Litem := TViewItem.Create(Self);
        Litem.FCpt := FieldValues['FreMark'];
        Litem.FLinkID := FieldValues['FnodeID'];
        Litem.FPic := TBitmap.Create;
        Litem.FPic.Transparent := True;
        Litem.FPic.LoadFromFile(GetCurrPath + 'dvs.bmp');
        Litem.x := FieldValues['Fx'];
        Litem.y := FieldValues['Fy'];
        Litem.FdbID := FieldValues['Fid'];
        Fitemlst.AddObject('', Litem);
      end;
      Next;
    end; // while
  end;
  DrawAll;
end;

procedure TView_Graph.SetState(const Value: Integer);
begin
  CurrState := Value;
//  btn_SetEdtState.Enabled := ifthen(Value <> 9, true, false);
end;

procedure TView_Graph.FormShow(Sender: TObject);
begin
  if FDataQry = nil then
    FDataQry := Gob_DBMrg.GetAnQuery('GvDataQry');
end;

end.

