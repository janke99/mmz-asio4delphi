unit asioTest;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, untASIOSvr, StdCtrls, ExtCtrls;

type
  Tview_main = class(TForm)
    lbl1: TLabel;
    lbl_Clientcount: TLabel;
    Label1: TLabel;
    lbl_TotRcv: TLabel;
    Label2: TLabel;
    lbl_Sendtot: TLabel;
    Label4: TLabel;
    lbl_ClientMemtot: TLabel;
    Label3: TLabel;
    lbl_SendBuff: TLabel;
    tmr1: TTimer;
    Label5: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Onmsg(var msg: TMessage); message 1026;
  end;

  {Echo对象服务端}
  TechoSvr = class(TAsioSvr)
  public
    GtotCount: integer;
    GRcvTot: Int64;
    GSendTot: Int64;

    procedure Doconn(Iclient: TasioClient);
    procedure Dodisconn(Iclient: TasioClient);
    procedure DoRcvdata(IClient: TAsioClient; Ibuff: Pointer; Ilen: integer);
    procedure DoSenddata(IClient: TAsioClient; Ibuff: Pointer; Ilen: integer);
    procedure Docase(IClient: TAsioClient; IwantLen: integer);
    constructor Create(WorkThreadCount: Integer = 1);
  end;

var
  view_main: Tview_main;
  GechoSvr: TechoSvr;
implementation




type
  RBaseCaserd = packed record
    Id: Integer;
    Len: Integer;
    Pointer: integer;
  end;
  PRBaseCaserd = ^RBaseCaserd;

{$R *.dfm}

procedure Tview_main.FormCreate(Sender: TObject);
begin
  GechoSvr := TechoSvr.Create();
  GechoSvr.StartSvr();
end;

{ TechoSvr }

constructor TechoSvr.Create(WorkThreadCount: Integer);
begin
  inherited Create(WorkThreadCount);
  FOnCaseData := Docase;
  FOnClientConn := Doconn;
  FOnClientDisConn := Dodisconn;
  FOnClientRecvData := DoRcvdata;
  FonClientSendData := DoSenddata;
end;

procedure TechoSvr.Docase(IClient: TAsioClient; IwantLen: integer);
var
  i, Lhead: Integer;
  LPrd: PRBaseCaserd;
  Lbuff: TPoolItem;
begin
  if IClient.DeadTime > 0 then Exit;
  //判断数据处理状态
  case IClient.RcvDataBuffer.State of //读取数据头
    CdataRcv_State_head: begin
        IClient.RcvDataBuffer.ReadInteger(True, true);
//        IClient.RcvDataBuffer.WantData := 4; //4个字节
//        IClient.RcvDataBuffer.State := CdataRcv_State_len; //获取数据长度
        IClient.RcvDataBuffer.WantData := IClient.RcvDataBuffer.ReadInteger(True, true); //4个字节
        IClient.RcvDataBuffer.State := CdataRcv_State_Body;
//        DeBug('收到数据<Currpost:%d ReadPos:%d NextSize:%d wantdata:%d>',
//          [IClient.RcvDataBuffer.CurrPost, IClient.RcvDataBuffer.ReadPos,
//          IClient.RcvDataBuffer.Memory.Position, IClient.RcvDataBuffer.WantData]);
      end;
    CdataRcv_State_len: begin //读取数据长度

        IClient.RcvDataBuffer.WantData := IClient.RcvDataBuffer.ReadInteger(True, true); //4个字节
        IClient.RcvDataBuffer.State := CdataRcv_State_Body;
//        DeBug('处理长度<Currpost:%d ReadPos:%d NextSize:%d wantdata:%d>',
//          [IClient.RcvDataBuffer.CurrPost, IClient.RcvDataBuffer.ReadPos,
//          IClient.RcvDataBuffer.Memory.Position, IClient.RcvDataBuffer.WantData]);
      end;
    CdataRcv_State_Body: begin //处理包体

        IClient.RcvDataBuffer.ReadBuff(@IClient.RcvDataBuffer.Gbuff[IClient.RcvDataBuffer.ReadPos], IClient.RcvDataBuffer.WantData, true); //4个字节
        IClient.RcvDataBuffer.WantData := 8;
        IClient.RcvDataBuffer.State := CdataRcv_State_head;
//        DeBug('处理包体<Currpost:%d ReadPos:%d NextSize:%d wantdata:%d>',
//          [IClient.RcvDataBuffer.CurrPost, IClient.RcvDataBuffer.ReadPos,
//          IClient.RcvDataBuffer.Memory.Position, IClient.RcvDataBuffer.wantdata]);
          {处理数据包}

        LPrd := PRBaseCaserd(@IClient.RcvDataBuffer.Gbuff[0]);
        case LPrd^.Id of
          1: begin //发送echo数据
              Lbuff := IClient.MemPool.GetBuff(Ckind_FreeMem);
              Lbuff.FMem.Position := 0;
              //运算并返回结果
              Lhead := 0;
              for i := 8 to 11 do begin
                inc(Lhead, IClient.RcvDataBuffer.Gbuff[i]);
              end;
              LPrd^.Id := 1;
              LPrd^.Len := 4;
              LPrd^.Pointer := Lhead;
              Lbuff.FMem.WriteBuffer(LPrd^, 8 + 4);
              IClient.SendData(Lbuff);
//              DeBug('回复->%d', [LPrd^.Pointer]);
            end;
          2: ; //心跳包
        end;
      end;
  end;
end;


procedure TechoSvr.Doconn(Iclient: TasioClient);
begin
  Inc(GtotCount);
  SendMessage(view_main.Handle, 1026, 1, GtotCount);
end;

procedure TechoSvr.Dodisconn(Iclient: TasioClient);
begin
  Dec(GtotCount);
  SendMessage(view_main.Handle, 1026, 1, GtotCount);
end;

var
  lrcvc: Cardinal;

procedure TechoSvr.DoRcvdata(IClient: TAsioClient; Ibuff: Pointer;
  Ilen: integer);
begin
  if Ilen > 0 then begin
    Inc(GRcvTot, Ilen);
    if GetTickCount - lrcvc > 1000 then begin
      lrcvc := GetTickCount;
      PostMessage(view_main.Handle, 1026, 2, GRcvTot);
    end;
  end;
end;

procedure Tview_main.Onmsg(var msg: TMessage);
begin
  if msg.WParam = 1 then
    lbl_Clientcount.Caption := IntToStr(msg.LParam)
  else if msg.WParam = 2 then
    lbl_TotRcv.Caption := GechoSvr.ShowBytes(msg.LParam)
  else if msg.WParam = 3 then
    lbl_Sendtot.Caption := GechoSvr.ShowBytes(msg.LParam);
end;


var
  llastsendc: Cardinal;

procedure TechoSvr.DoSenddata(IClient: TAsioClient; Ibuff: Pointer;
  Ilen: integer);
begin
  if Ilen > 0 then begin
    Inc(GSendTot, Ilen);
    if GetTickCount - llastsendc > 1000 then begin
      llastsendc := GetTickCount;
      PostMessage(view_main.Handle, 1026, 3, GSendTot);
    end;
  end;

end;

procedure Tview_main.tmr1Timer(Sender: TObject);
begin
  try
    lbl_ClientMemtot.Caption := GechoSvr.ShowBytes(GechoSvr.GetClientMem);
    lbl_SendBuff.Caption := GechoSvr.ShowBytes(GechoSvr.GetSendBuffMem);
//    if GAsioTCP.FClientLst.Count > 0 then
//      Label5.Caption := Format('%d', [(TAsioClient(GAsioTCP.FClientLst.Objects[0]).RcvDataBuffer.Memory.Position)]);
  except
  end;
end;

procedure Tview_main.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  KillTask(ParamStr(0));
end;

end.

