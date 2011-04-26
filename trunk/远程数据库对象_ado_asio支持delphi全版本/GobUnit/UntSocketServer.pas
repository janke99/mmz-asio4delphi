{*******************************************************}
{      单元名：  UntSocketServer.pas                    }
{      创建日期：2006-2-28 20:36:19                     }
{      创建者    马敏钊                                 }
{      功能：    Tcp服务抽象基类                        }
{                                                       }
{*******************************************************}



unit UntSocketServer;

interface
uses
  UntTBaseSocketServer, UntTIO, sysutils, untASIOSvr, WinSock;
type
  TCenterServer = class
  private
  protected
    procedure OnCreate(ISocket: TBaseSocketServer); virtual;
    procedure OnDestroy; virtual;
    procedure OnConning(ClientThread: TAsioClient); virtual;
    function OnCheckLogin(ClientThread: TAsioClient): boolean; virtual;
    {用户断开事件}
    procedure OnDisConn(ClientThread: TAsioClient); virtual;
    function OnDataCase(ClientThread: TAsioClient; Ihead: integer): Boolean;
      virtual;
    procedure OnException(ClientThread: TAsioClient; Ie: Exception); virtual;
//------------------------------------------------------------------------------
// 本类自己使用的方法 2006-8-23 马敏钊
//------------------------------------------------------------------------------
    {用户连接事件 也是入口事件}
    procedure UserConn(ClientThread: TAsioClient; Iwantlen: integer);
    {处理命令事件}
    procedure DataCase(ClientThread: TAsioClient); virtual;
  public
    Shower: TIOer;
    Socket: TBaseSocketServer;
    {*根据线程获取IP和端口号}
    function GetUserIpAndPort(ClientThread: TAsioClient): string;
    constructor Create(IServerPort: Integer; Iio: TIOer = nil);
    destructor Destroy; override;
  end;


implementation

uses UntBaseProctol, pmybasedebug;

{ TSocketServer }

constructor TCenterServer.Create(IServerPort: Integer; Iio: TIOer = nil);
begin
  Socket := TBaseSocketServer.Create(IServerPort);
  Socket.Server.FOnCaseData := UserConn;
  Socket.Server.FOnClientDisConn := OnDisConn;
  Socket.Server.StartSvr(IServerPort);
  Shower := Iio;
  OnCreate(Socket);
end;

destructor TCenterServer.Destroy;
begin
  OnDestroy;
  Socket.Free;
  inherited;
end;

procedure TCenterServer.DataCase(ClientThread: TAsioClient);
var
  Lhead: Integer;
begin
  if (ClientThread.DeadTime = 0) then begin
    Lhead := ClientThread.RcvDataBuffer.ReadInteger;
    case Lhead of //
      -1: ; //Shower.AddShow('收到Client %s:%d 的心跳信息',[ClientThread.Socket.PeerIPAddress, ClientThread.Socket.PeerPort]);
    else
      if not OnDataCase(ClientThread, Lhead) then
        if Shower <> nil then
          Shower.AddShow(Format('收到错误的命令包%d', [Lhead]));
    end; // case
  end; // while
end;


procedure TCenterServer.OnCreate(ISocket: TBaseSocketServer);
begin
  if Shower <> nil then
    Shower.AddShow('服务成功启动...端口:%d', [ISocket.Server.Fport]);
end;

type
  RBaseCaserd = packed record
    Id: Integer;
    Len: Integer;
    Pointer: integer;
  end;
  PRBaseCaserd = ^RBaseCaserd;

procedure TCenterServer.UserConn(ClientThread: TAsioClient; Iwantlen: integer);
var
  i, Lhead: Integer;
  LPrd: PRBaseCaserd;
  Lbuff: TPoolItem;
  IClient: TAsioClient;
begin
  IClient := ClientThread;
  if IClient.DeadTime > 0 then Exit;
  try
    if IClient.ConnState = Casio_State_Init then begin
      OnConning(ClientThread);
      if OnCheckLogin(ClientThread) then begin
        ClientThread.ConnState := Casio_State_Conned
      end
      else begin
        ClientThread.ConnState := Casio_State_DisConn;
        OnDisConn(ClientThread);
        ClientThread.Socket.Disconnect;
      end;
    end
    else if IClient.ConnState = Casio_State_Conned then begin
      //判断数据处理状态
      case IClient.RcvDataBuffer.State of //读取数据头
        CdataRcv_State_head: begin
            IClient.RcvDataBuffer.ReadInteger(true); //包头
            IClient.RcvDataBuffer.WantData := IClient.RcvDataBuffer.ReadInteger(true); //4个字节 //长度
            IClient.RcvDataBuffer.State := CdataRcv_State_Body; //读取包体
//        DeBug('收到数据<Currpost:%d ReadPos:%d NextSize:%d wantdata:%d>',
//          [IClient.RcvDataBuffer.CurrPost, IClient.RcvDataBuffer.ReadPos,
//          IClient.RcvDataBuffer.Memory.Position, IClient.RcvDataBuffer.WantData]);
          end;
        CdataRcv_State_len: begin //读取数据长度
            IClient.RcvDataBuffer.WantData := IClient.RcvDataBuffer.ReadInteger(true); //4个字节
            IClient.RcvDataBuffer.State := CdataRcv_State_Body;
//        DeBug('处理长度<Currpost:%d ReadPos:%d NextSize:%d wantdata:%d>',
//          [IClient.RcvDataBuffer.CurrPost, IClient.RcvDataBuffer.ReadPos,
//          IClient.RcvDataBuffer.Memory.Position, IClient.RcvDataBuffer.WantData]);
          end;
        CdataRcv_State_Body: begin //处理包体
           //IClient.RcvDataBuffer.ReadBuff(IClient.RcvDataBuffer.WantData); //4个字节
            IClient.RcvDataBuffer.WantData := 8;
            IClient.RcvDataBuffer.State := CdataRcv_State_head;
//        DeBug('处理包体<Currpost:%d ReadPos:%d NextSize:%d wantdata:%d>',
//          [IClient.RcvDataBuffer.CurrPost, IClient.RcvDataBuffer.ReadPos,
//          IClient.RcvDataBuffer.Memory.Position, IClient.RcvDataBuffer.wantdata]);
          {处理数据包}
            DataCase(IClient);
//            LPrd := PRBaseCaserd(@IClient.RcvDataBuffer.Gbuff[0]);
//            case LPrd^.Id of
//              1: begin //发送echo数据
//                  Lbuff := IClient.MemPool.GetBuff(Ckind_FreeMem);
//                  Lbuff.FMem.Position := 0;
//              //运算并返回结果
//                  Lhead := 0;
//                  for i := 8 to 11 do begin
//                    inc(Lhead, IClient.RcvDataBuffer.Gbuff[i]);
//                  end;
//                  LPrd^.Pointer := Lhead;
//                  Lbuff.FMem.WriteBuffer(LPrd^, 8 + 4);
//                  IClient.SendData(Lbuff);
////              DeBug('回复->%d', [LPrd^.Pointer]);
//                end;
//              2: ; //心跳包
//            end;
          end;
      end;
    end;
  except
    on e: exception do begin
      OnException(ClientThread, e);
    end;
  end;
end;

procedure TCenterServer.OnConning(ClientThread: TAsioClient);
begin
  if Shower <> nil then
    Shower.AddShow(Format('来自%s:%d用户建立连接', [ClientThread.PeerIP, ClientThread.PeerPort]));
end;

function TCenterServer.OnCheckLogin(ClientThread: TAsioClient): boolean;
begin
  Result := True;
  if ClientThread.RcvDataBuffer.ReadInteger <> CTSLogin then begin
    Result := False;
    Socket.SendHead(STCLoginFault_Vison, ClientThread);
  end;
  if ClientThread.Socket.ReadInteger <> CClientID then begin
    Result := False;
    Socket.SendHead(STCLoginFault_Vison, ClientThread);
  end;
  if Result then
    Socket.SendHead(STCLogined, ClientThread);
end;

procedure TCenterServer.OnDisConn(ClientThread: TAsioClient);
begin
  if (ClientThread <> nil) and (ClientThread.Socket <> nil) then begin
    if Shower <> nil then
      Shower.AddShow('用户断开连接了');
    ClientThread.Socket.Disconnect;
  end
end;

function TCenterServer.OnDataCase(ClientThread: TAsioClient; Ihead: integer):
  Boolean;
begin
  Result := True;
end;

procedure TCenterServer.OnException(ClientThread: TAsioClient; Ie: Exception);
begin
  if Shower <> nil then
    Shower.AddShow(Format('用户服务线程异常 原因:%s', [Ie.ClassName + '>> ' + Ie.Message]));
end;

procedure TCenterServer.OnDestroy;
begin
  if Shower <> nil then
    Shower.AddShow('服务释放成功...');
end;

function TCenterServer.GetUserIpAndPort(ClientThread: TAsioClient): string;
begin
  Result := ClientThread.PeerIP + ':' + IntToStr(ClientThread.PeerPort);
end;

end.

