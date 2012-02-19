{*******************************************************}
{      单元名：  modelCenterClient.pas                  }
{      创建日期：2006-2-23 23:43:07                     }
{      创建者    马敏钊                                 }
{      功能：    远程接口客户端                         }
{                用来连接分析端通信                     }
{*******************************************************}

unit modelCommClient;

interface
uses Classes, Forms, UntsocketDxBaseClient, ADODB, SyncObjs,
  Graphics;

type
  TWorkthread = class;
  //信令客户端对象
  TCommClient = class(TAsioClient)
  private
    function DatasetToStream(iRecordset: TADOQuery; Stream: TMemoryStream): boolean;

  public
    index: Integer;
    FUpEventLock: TCriticalSection;
    FWaiteUpWarningLst: TStrings;
    LiveTime: Cardinal;
    USerID: string; //唯一标识
    UserKind: Integer; //1下级用户
    GMemBuff: TMemoryStream;

    ReadThread: TWorkthread;
    MsgWnd: Integer;
    //具体的处理过程

    LCmd: integer; //开始还是结束
    Lid: integer; //id
    LStat: integer; //状态
    LInfo: string;

    Fdbid: Integer;
    FState: Integer;
    FexpBMP: TMemoryStream;
    FAreaid: Integer;
    FExpTime: Integer;
    FexpInfo: string;
    lbuff: array[0..511] of byte;

    lsum: Integer;
    beginSend: Cardinal;
    Fupstate: boolean; //请求的更新状态
    isRcv: Boolean;
    grcvTime: Cardinal;
    //开始工作
    procedure StartWork;
    procedure Stop;
    //改变请求状态
    procedure RequestState(IWant: boolean = true);
    //通知更新数据表
    procedure UpTable(Ikind, Idata: integer);

    //通知立即检测
    procedure NowCheck(Iid: string);

    //处理事件
    procedure DoCase; virtual;
    //连接成功
    procedure OnConnSuccess;
    procedure OnCreate; override;
    procedure OnDestory; override;
  end;

  //工作线程负责连接目标和发送缓存中的数据
  TWorkthread = class(TThread)
  public
    Client: TCommClient;
    procedure execute; override;
  end;

var
  modelIntfClient: TCommClient;

implementation

uses windows, untfunctions, SysUtils,  modelASIOtest, untASIOSvr;



procedure TCommClient.DoCase;
var
  Lport: Integer;

  Ls: string;
begin
  if ReceiveLength >= 12 then begin
    LCmd := ReadBuffer(@LCmd, 4); ;
    try
  //    case LCmd of
       // 1: begin //开始检测
      ReadBuffer(@lport, 4); ;
      ReadBuffer(@lport, 4);
//      Lport := Readinteger;
//      Lport := Readinteger;
      isRcv := True;
      grcvTime := GetTickCount;
      SendMessage(ASIO_test.handle, 1026, Integer(self), Lport);
//            OnConnSuccess;
    //      end;

//      end;
    except
    end;
  end;
end;

procedure TCommClient.OnConnSuccess;
var
  i, ln: Integer;
begin
//  WriteInteger(length(USerID));
//  Write(USerID);
//  if isRcv then begin

  beginSend := GetTickCount;
  Writeinteger(1);
  Writeinteger(4);
  ln := 1 + Random(98);
  lsum := ln * 4;
  FillMemory(@lbuff[0], 4, ln);
  WriteBuff(lbuff[0], 4);
  isRcv := False;
 // SendMessage(ASIO_test.Handle, 1027, 0, lsum);
//  end;
end;

procedure TCommClient.OnCreate;
begin
  isRcv := True;
  Fupstate := false;
//  ReadThread := TWorkthread.Create(True);
//  ReadThread.Client := Self;
  UserKind := 1;
  GMemBuff := TMemoryStream.Create;
  FWaiteUpWarningLst := TStringList.Create;
  FUpEventLock := TCriticalSection.Create;
end;

{ TWorkthread }



procedure TWorkthread.execute;
begin
  while (Terminated = false) do begin
    try
      if Client.IsConning then begin
        Client.DoCase;
        Sleep(10);
      end
      else begin
        if Client.Connto(Client.FHost, Client.FPort) then
          Client.OnConnSuccess
        else Sleep(1000);
      end;
    except

    end;
  end;
end;

function TCommClient.DatasetToStream(iRecordset: TADOQuery; Stream:
  TMemoryStream): boolean;
const
  adPersistADTG = $00000000;
var
  RS: Variant;
begin
  Result := false;
  if iRecordset = nil then
    Exit;
  try
    RS := iRecordset.Recordset;
    RS.Save(TStreamAdapter.Create(stream) as IUnknown, adPersistADTG);
    Stream.Position := 0;
    Result := true;
  finally;
  end;
end;

procedure TCommClient.StartWork;
begin
  ReadThread.Resume;
end;

procedure TCommClient.Stop;
begin
  ReadThread.Terminate;
end;

procedure TCommClient.OnDestory;
begin
  FWaiteUpWarningLst.Free;
  FUpEventLock.Free;
end;

procedure TCommClient.RequestState(IWant: boolean);
begin
  try
    FUpEventLock.Acquire;
    Fupstate := IWant;
    if IWant then
      Self.WriteInteger(1000)
    else
      Self.WriteInteger(1001);
  finally
    FUpEventLock.Release;
  end;
end;

procedure TCommClient.UpTable(Ikind, Idata: integer);
begin
  try
    FUpEventLock.Acquire;
    WriteInteger(1002);
    WriteInteger(Ikind);
    WriteInteger(Idata);
  finally
    FUpEventLock.Release;
  end;
end;

procedure TCommClient.NowCheck(Iid: string);
begin
  try
    FUpEventLock.Acquire;
    WriteInteger(1003);
    WriteInteger(length(Iid));
    Write(Iid);
  finally
    FUpEventLock.Release;
  end;
end;

end.

