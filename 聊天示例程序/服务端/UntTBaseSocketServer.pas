unit UntTBaseSocketServer;
{封装了ASIO服务端的基类}
interface
uses CLasses, untASIOSvr;
type
  Pint = ^integer;
  TBaseSocketServer = class(TAsioSvr)
  private
    procedure DefaultConn(ClientThread: TAsioClient);
  public
    Server: TAsioSvr;
    function GetHead(IConn: TAsioClient): Integer;
    procedure SendHead(ICmd: Integer; IConn: TAsioClient); overload; //发送报头
    procedure SendObject(IObj: TObject; IConn: TAsioClient);
    procedure GetObject(IObj: TObject; IClass: TClass; IConn: TAsioClient);
      overload;
    procedure GetObject(IObj: TObject; IConn: TAsioClient); overload;
    function GetZipFile(IFileName: string; IConn: TAsioClient): Integer;
    function SendZIpFile(IFileName: string; IConn: TAsioClient): Integer;
    function SendZIpStream(IStream: tStream; IConn: TAsioClient): Integer;
    function GetZipStream(IStream: TStream; IConn: TAsioClient): integer;
    procedure StartServer;
    constructor Create(Iport: Integer);
    destructor Destroy; override;
  end;

implementation

uses SysUtils, untfunctions, pmybasedebug, windows;
{ TBaseSocketServer }

constructor TBaseSocketServer.Create(Iport: Integer);
begin
  inherited Create(1);
  Server := Self;
  Fport := Iport;
end;

procedure TBaseSocketServer.DefaultConn(ClientThread: TAsioClient);
begin
  //本过程什么都不做 只为用户提供一个接口
end;

destructor TBaseSocketServer.Destroy;
begin
  inherited;
end;

function TBaseSocketServer.GetHead(IConn: TAsioClient): Integer;
begin
  Result := IConn.RcvDataBuffer.ReadInteger;
end;

function TBaseSocketServer.GetZipFile(IFileName: string; IConn: TAsioClient):
  Integer;
var
  LZipMM: TMemoryStream;
  LBuff: Pointer;
  i, ltot, x: Integer;
begin
  LZipMM := TMemoryStream.Create;
  try
    x := IConn.RcvDataBuffer.ReadInteger;
    LZipMM.Size := x;
    LBuff := LZipMM.Memory;
    ltot := LZipMM.Size;
    x := 0;
    while ltot > 0 do begin
      i := IConn.Socket.ReadBuff(PChar(LBuff) + x, ltot);
      Dec(ltot, i);
      inc(x, i);
    end; // while
    DeCompressStream(LZipMM);
    LZipMM.SaveToFile(IFileName);
    Result := LZipMM.Size;
  finally // wrap up
    LZipMM.Free;
  end; // try/finally
end;

procedure TBaseSocketServer.GetObject(IObj: TObject; IConn: TAsioClient);
var
  Ltep: pint;
begin
  IObj := TClass.Create;
  Ltep := Pointer(Iobj);
  inc(Ltep);
  IConn.RcvDataBuffer.ReadBuff(Ltep, Iobj.InstanceSize - 4);
end;



procedure TBaseSocketServer.SendHead(ICmd: Integer;
  IConn: TAsioClient);
begin
  IConn.Socket.WriteInteger(ICmd);
end;

procedure TBaseSocketServer.SendObject(IObj: TObject; IConn: TAsioClient);
var
  Ltep: Pint;
begin
  Ltep := Pointer(IObj);
  inc(Ltep);
  IConn.Socket.Write(ltep, IObj.InstanceSize - 4);
end;

procedure TBaseSocketServer.StartServer;
begin
  Server.StartSvr(Fport);
end;

procedure TBaseSocketServer.GetObject(IObj: TObject; IClass: TClass; IConn:
  TAsioClient);
var
  Ltep: pint;
begin
  Ltep := Pointer(Iobj);
  inc(Ltep);
  IConn.RcvDataBuffer.ReadBuff(Ltep, Iobj.InstanceSize - 4);
end;

function TBaseSocketServer.SendZIpFile(IFileName: string; IConn: TAsioClient):
  Integer;
var
  LZipMM: TMemoryStream;
begin
  LZipMM := TMemoryStream.Create;
  try
    LZipMM.LoadFromFile(IFileName);
    EnCompressStream(LZipMM);
    IConn.Socket.WriteInteger(LZipMM.Size);
    IConn.Socket.Write(LZipMM.Memory, LZipMM.Size);
    Result := LZipMM.Size;
  finally
    LZipMM.Free;
  end;
end;

function TBaseSocketServer.SendZIpStream(IStream: tStream; IConn: TAsioClient):
  Integer;
begin
  EnCompressStream(TMemoryStream(IStream));
  IConn.Socket.WriteInteger(IStream.Size);
  IConn.Socket.Write(TMemoryStream(IStream).Memory, IStream.Size);
  Result := IStream.Size;
end;

function TBaseSocketServer.GetZipStream(IStream: TStream; IConn: TAsioClient):
  integer;
var
  LZipMM: TMemoryStream;
  LBuff: Pointer;
  i, ltot, x: Integer;
begin
  LZipMM := TMemoryStream(IStream);
  x := IConn.Socket.ReadInteger;
  LZipMM.Size := x;
  LBuff := LZipMM.Memory;
  ltot := LZipMM.Size;
  x := 0;
  while ltot > 0 do begin
    i := IConn.Socket.ReadBuff(PChar(LBuff) + x, ltot);
    Dec(ltot, i);
    inc(x, i);
  end; // while
  DeCompressStream(LZipMM);
  Result := LZipMM.Size;
end;


end.

