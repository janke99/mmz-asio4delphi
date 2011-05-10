unit UntRemSql;

interface

uses
  Classes, SysUtils, ADODB, Forms, Windows, DB,
  untRmoDbClient, pmybasedebug;


type
  TRmoHelper = class

  public
//    FChannel: tROIndyTCPChannel; // 设置Host 和 Port
//    FMessage: tROBinMessage;
//    FServer: tRORemoteService;
    FPublic: tadoquery;
    FLastSql: string; //最后一次查询的语句
    FRmoClient: TRmoClient;

      {查询ISqlStr到IADOQry控件}
    procedure MyQuery(IADOQry: TADOQuery; ISqlStr: string);
    {执行ISqlStr语句}
    procedure MyExec(ISqlStr: string);
    function GetCount(ItabName, IFieldName: string; Ivalue: variant):
      Cardinal;
    function OpenDataset(ISql: string; const Args: array of const): TADOQuery; overload;
    function OpenDataset(ISql: string): TADOQuery; overload;
    function OpenDataset(Iado: TADOQuery; ISql: string): TADOQuery; overload;
    function OpenDataset(Iado: TADOQuery; ISql: string; const Args: array of const):
      TADOQuery; overload;

    function ExecAnSql(Iado: TADoquery; Isql: string; const Args: array of const): Integer; overload;
    function ExecAnSql(Isql: string; const Args: array of const): Integer; overload;

    function OpenTable(ItabName: string; Iado: TADOQuery): TADOQuery;


   // function OpenTable(ItabName: string; Iado: TADOQuery): TADOQuery; overload;
    //function OpenTable(ItabName: string; IQueryRight: integer = 1): TADOQuery; overload;
      {连接数据库服务端 iTestTable是测试查询的表名，必须要有}
    function ConnetToSvr(ISvrIP: string; ISvrPort: Word): Boolean;
    //重新连接服务器
    function ReConnSvr(ISvrIP: string; ISvrPort: Integer = -1): boolean;
    constructor Create(Iport: integer = 9989);
    destructor Destroy; override;
  end;




var
  Gob_Rmo: TRmoHelper;

implementation

uses winsock, untFunctions;



function HostToIP(IName:  ansistring; var IIp: ansistring): Boolean;
var
  wsdata: TWSAData;
  hostName: array[0..255] of AnsiChar;
  hostEnt: PHostEnt;
  addr: PansiChar;
begin
  WSAStartup($0101, wsdata);
  try
    gethostname(hostName, sizeof(hostName));
    StrPCopy(hostName, iName);
    hostEnt := gethostbyname(hostName);
    if Assigned(hostEnt) then
      if Assigned(hostEnt^.h_addr_list) then begin
        addr := hostEnt^.h_addr_list^;
        if Assigned(addr) then begin
          iIP := Format('%d.%d.%d.%d', [byte(addr[0]),
            byte(addr[1]), byte(addr[2]), byte(addr[3])]);
          Result := True;
        end
        else
          Result := False;
      end
      else
        Result := False
    else begin
      Result := False;
    end;
  finally
    WSACleanup;
  end
end;

procedure TRmoHelper.MyQuery(IADOQry: TADOQuery;
  ISqlStr: string);
begin
  FRmoClient.OpenAndataSet(ISqlStr, IADOQry);
end;

procedure TRmoHelper.MyExec(ISqlStr: string);
begin
//  try
  FRmoClient.ExeSQl(ISqlStr);
//  except
//    on e: Exception do
//      Application.MessageBox(PChar('RO执行SQL异常：' + e.message), '提示', MB_OK +
//        MB_ICONINFORMATION);
//  end;
end;

constructor TRmoHelper.Create(Iport: integer = 9989);
begin
//  FChannel := tROIndyTCPChannel.Create(nil); // 设置Host 和 Port
//  FChannel.Port := 8090;
//  FChannel.Host := '127.0.0.1';
//  FMessage := tROBinMessage.Create(nil);
//  FServer := tRORemoteService.Create(nil);
//  FServer.Channel := FChannel;
//  FServer.Message := FMessage;
//  FServer.ServiceName := 'OracleAccessService';

  FPublic := TADOQuery.Create(nil);
  FRmoClient := TRmoClient.Create;
  FRmoClient.FHost := '127.0.0.1';
  FRmoClient.FPort := Iport;

end;

destructor TRmoHelper.Destroy;
begin
  FRmoClient.Free;
//  FPublic.Free;
//  FChannel.Free;
//  FMessage.Free;
//  FServer.Free;
  inherited;
end;



function TRmoHelper.OpenDataset(ISql: string;
  const Args: array of const): TADOQuery;
begin
  ISql := Format(Isql, Args);
  MyQuery(FPublic, ISql);
  Result := FPublic;
end;


function TRmoHelper.OpenDataset(ISql: string): TADOQuery;
begin
  MyQuery(FPublic, ISql);
  Result := FPublic;
end;

function TRmoHelper.OpenDataset(Iado: TADOQuery; ISql: string): TADOQuery;
begin
  MyQuery(Iado, ISql);
  Result := Iado
end;

function TRmoHelper.OpenDataset(Iado: TADOQuery; ISql: string; const Args: array of const):
  TADOQuery;
begin
  ISql := Format(Isql, Args);
  MyQuery(Iado, ISql);
  Result := Iado
end;

function TRmoHelper.GetCount(ItabName, IFieldName: string;
  Ivalue: variant): Cardinal;
var
  sql: string;
begin
  sql := 'select Count(' + IFieldName + ') as MyCount from ' + ItabName + ' where ' + IFieldName + ' = ' + Ivalue + '';
  MyQuery(FPublic, sql);
  Result := FPublic.fieldbyname('MyCount').AsInteger;
end;


function TRmoHelper.ExecAnSql(Iado: TADoquery; Isql: string;
  const Args: array of const): Integer;
begin
  MyExec(Format(Isql, Args));
end;

function TRmoHelper.ExecAnSql(Isql: string;
  const Args: array of const): Integer;
begin
  MyExec(Format(Isql, Args));
end;

function TRmoHelper.ConnetToSvr(ISvrIP: string; ISvrPort: Word): Boolean;
var
  LSql: string;
begin
  try
//    if IsLegalIP(ISvrIP) = false then
//      HostToIP(ISvrIP, ISvrIP);

    Result := FRmoClient.ConnToSvr(ISvrIP, ISvrPort);
  except
    Result := False;
  end;
end;

function TRmoHelper.OpenTable(ItabName: string;
  Iado: TADOQuery): TADOQuery;
begin
  MyQuery(Iado, Format('Select * from %s ', [ItabName]));
  Result := Iado;
end;

function TRmoHelper.ReConnSvr(ISvrIP: string; ISvrPort: Integer): boolean;
begin
  if IsLegalIP(ISvrIP) = false then
    HostToIP(ISvrIP, ISvrIP);
  Result := FRmoClient.ReConn(ISvrIP, ISvrPort);
end;

initialization


finalization
  if Assigned(Gob_Rmo) then
    Gob_Rmo.Free;

end.

