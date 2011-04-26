unit UntTBaseSocketClient;

interface
uses SysUtils,Classes, IdTCPClient, IdTCPConnection, IdSocks, idstack;
type
  Pint = ^integer;
  TBaseSocketClient = class
  protected
    procedure OnCreate; dynamic;
    procedure OnDestory; dynamic;
  public
    ExeGIDStack: TIdStack;
    Client: TIdTCPClient;
    function GetHead: Integer;               //读取报头
    procedure SendHead(ICmd: Integer);       //发送报头
    procedure SendObject(IObj: TObject);     //发送对象
    procedure GetObject(IObj: TObject; IClass: TClass); overload;
    //接收对象 自己根据类之类来创建对象
    procedure GetObject(IObj: TObject); overload; //由外部代入已经创建好的对象
    procedure SendZipFile(IFileName: string); //发送压缩文件
    procedure GetZipFile(IFileName: string); //接收压缩文件
    procedure GetZipStream(IStream: TStream);
    function SendZipStream(IStream: TStream):integer;
    constructor Create(IHost: string = '127.0.0.1'; IPort: Integer = 0); overload;
    constructor Create(const ProxyHost: string; ProxyPort: Integer;
      ProxyUser, ProxyPassword: string); overload;
    destructor Destroy; override;
  end;

implementation

uses  untfunctions;

{ TBaseSocketClient }

constructor TBaseSocketClient.Create(IHost: string = '127.0.0.1'; IPort:
  Integer = 0);
begin
  Client := TIdTCPClient.Create(Client);
  Client.Host := IHost;
  Client.Port := IPort;
  if (ExeGIDStack <> nil) and (GStack = nil) then
    ExeGIDStack := GStack;
  OnCreate;
end;

destructor TBaseSocketClient.Destroy;
begin
  try
    OnDestory;
    if Client.Connected then
      Client.Disconnect;
    Client.Free;
    Client := nil;
  except
  end;
  inherited;
end;

function TBaseSocketClient.GetHead: Integer;
begin
  Result := Client.ReadInteger;
end;

procedure TBaseSocketClient.GetObject(IObj: TObject; IClass: TClass);
var
  Ltep                   : pint;
begin
  IObj := TClass.Create;
  Ltep := Pointer(Iobj);
  inc(Ltep);
  Client.ReadBuffer(Ltep^, Iobj.InstanceSize - 4);
end;

procedure TBaseSocketClient.SendHead(ICmd: Integer);
begin
  Client.WriteInteger(ICmd);
end;

procedure TBaseSocketClient.SendObject(IObj: TObject);
var
  Ltep                   : Pint;
begin
  Ltep := Pointer(IObj);
  inc(Ltep);
  Client.WriteBuffer(ltep^, IObj.InstanceSize - 4);
end;

constructor TBaseSocketClient.Create(const ProxyHost: string; ProxyPort:
  Integer; ProxyUser, ProxyPassword: string);
begin
  Client.Socket.SocksInfo.Host := ProxyHost;
  Client.Socket.SocksInfo.Port := ProxyPort;
  Client.Socket.SocksInfo.Username := ProxyUser;
  Client.Socket.SocksInfo.Password := ProxyPassword;
  Client.Socket.SocksInfo.Version := svSocks5;
  OnCreate;
end;

procedure TBaseSocketClient.GetObject(IObj: TObject);
var
  Ltep                   : pint;
begin
  Ltep := Pointer(Iobj);
  inc(Ltep);
  Client.ReadBuffer(Ltep^, Iobj.InstanceSize - 4);
end;

procedure TBaseSocketClient.SendZipFile(IFileName: string);
var
  LZipMM                 : TMemoryStream;
begin
  LZipMM := TMemoryStream.Create;
  try
    LZipMM.LoadFromFile(IFileName);
    EnCompressStream(LZipMM);
    Client.WriteInteger(LZipMM.Size);
    Client.WriteBuffer(LZipMM.Memory^, LZipMM.Size);
  finally
    LZipMM.Free;
  end;
end;

procedure TBaseSocketClient.GetZipFile(IFileName: string);
var
  LZipMM                 : TMemoryStream;
begin
  LZipMM := TMemoryStream.Create;
  try
    LZipMM.Size := Client.ReadInteger;
    Client.ReadBuffer(LZipMM.Memory^, LZipMM.Size);
    DeCompressStream(LZipMM);
    LZipMM.SaveToFile(IFileName);
  finally                                    // wrap up
    LZipMM.Free;
  end;                                       // try/finally
end;

procedure TBaseSocketClient.OnCreate;
begin

end;

procedure TBaseSocketClient.OnDestory;
begin

end;

procedure TBaseSocketClient.GetZipStream(IStream: TStream);
var
  LZipMM                 : TMemoryStream;
begin
  LZipMM := TMemoryStream(IStream);
  LZipMM.Size := Client.ReadInteger;
  Client.ReadBuffer(LZipMM.Memory^, LZipMM.Size);
  DeCompressStream(LZipMM);
end;

function TBaseSocketClient.SendZipStream(IStream: TStream):integer;
var
  LZipMM                 : TMemoryStream;
begin
  LZipMM := TMemoryStream.Create;
  try
    LZipMM.LoadFromStream(IStream);
    EnCompressStream(TMemoryStream(LZipMM));
    Client.WriteInteger(LZipMM.Size);
    Client.WriteBuffer(TMemoryStream(LZipMM).Memory^, LZipMM.Size);
    Result := LZipMM.Size;
  finally
    LZipMM.Free;
  end;
end;

end.

