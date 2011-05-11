unit DM;

//在此开启数据库连接选项
{$DEFINE  Access}
{.$DEFINE  InterBase}
{.$DEFINE  SqlServer}
{.$DEFINE  Sqlite}
{.$DEFINE  Oracle}
{.$DEFINE  MySql}
{.$DEFINE  Odbc}

interface
uses
  SysUtils, Classes, DB, MemDS, DBAccess, Uni, Provider, UniProvider
{$IFDEF Access}, AccessUniProvider{$ENDIF}
{$IFDEF InterBase}, InterBaseUniProvider{$ENDIF}
{$IFDEF SqlServer}, SQLServerUniProvider{$ENDIF}
{$IFDEF Sqlite}, SQLiteUniProvider{$ENDIF}
{$IFDEF Oracle}, OracleUniProvider, {$ENDIF}
{$IFDEF MySql}, MySQLUniProvider{$ENDIF}
{$IFDEF Odbc}, ODBCUniProvider{$ENDIF}
  , AsyncCalls, untASIOSvr, UntTIO, UntTBaseSocketServer, SyncObjs;

type
  Tdbpool = class //连接池对象
  public
    id: Integer;
    Isused: Boolean;
    Gtmpbuffer: TMemoryStream;
    Shower: TIOer;
    IParent: TBaseSocketServer;
    ISocker: TAsioClient;
    IcmdKind: Integer; //命令号
    IParam: string; //语句
    IAS: IAsyncCall;
    FDataProvider: TDataSetProvider;
    FConner: TUniConnection;
    FQRy: TUniQuery;
    FSql: TUniSQL;
    FProc: TUniStoredProc;
    constructor Create();
    destructor Destroy; override;
  end;

  TDbPoolsMM = class //连接池管理对象
  private
    Flock: TCriticalSection;
  public
    FLst: TStrings;
    function GetAnPools: Tdbpool;
    constructor Create();
    destructor Destroy; override;
  end;


  TDataModel = class(TDataModule)
    DP: TDataSetProvider;
    dpProc: TDataSetProvider;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    Coner: TUniConnection;
    Gqry: TUniQuery;
    UniSQL: TUniSQL;
    UniProc: TUniStoredProc;
    class procedure CfgDb(IConn: TUniConnection);
  end;

var
  DataModel: TDataModel;

implementation

uses
  untFunctions;

{$R *.dfm}



class procedure TDataModel.CfgDb(IConn: TUniConnection);
begin
//------------------------------------------------------------------------------
// 在此处可以根据需要连接不同的数据库以及填入不同连接参数 2010-04-23 马敏钊
//------------------------------------------------------------------------------
  with IConn do begin
//连接Access
{$IFDEF Access}
    ProviderName := 'Access';
    Database := GetCurrPath() + 'demo.mdb';
{$ENDIF}
//连接Interbase或者Firebird
{$IFDEF InterBase}
    ProviderName := 'InterBase'; //为InterBase,支持InterBase和FireBird
    UserName := 'SYSDBA'; //数据库密码
    Password := 'masterkey'; //数据库密码
    SpecificOptions.Clear;
{$IFDEF EMBED} //连接文件形式的
    Server := ''; //嵌入式为空
    DataBase := GetCurrPath() + 'demo.fdb';

{$ELSE} // 连接服务形式的
    Server := '192.168.1.88';
    Port := 3050; //确保服务器开放Firebird的3050端口
    Database := 'UniDemoDB'; //CS服务器使用了数据库别名
    SpecificOptions.Add('InterBase.ClientLibrary=fbembed.dll'); //设置embeddll的dll文件位置
{$ENDIF}
    SpecificOptions.Add('InterBase.CharLength=0'); //设置为0，自动读取FireBird设置
    SpecificOptions.Add('SQLDialet=3'); //设置为3
    SpecificOptions.Add('CharSet=GBK'); //设置为GBK
    SpecificOptions.Add(Format('InterBase.ClientLibrary=%s', ['gds32.dll'])); //设置fbclient.dll位置
{$ENDIF}
//连接SqlServer
{$IFDEF SqlServer}
    ProviderName := 'SQL Server'; //
    server := '127.0.0.1,7788';
    database := 'ubi100db';
    UserName := 'sa'; //数据库密码
    Password := 'admin'; //数据库密码
{$ENDIF}
//连接Sqlite
{$IFDEF Sqlite}
    ProviderName := 'SQLite'; //
    database := GetCurrPath() + 'test.db';
{$ENDIF}
//连接Oracle
{$IFDEF Oracle}
    ProviderName := 'Oracle'; //
    server := '192.168.0.36,7788';
    database := 'test';
    UserName := 'sa'; //数据库密码
    Password := 'sa'; //数据库密码
{$ENDIF}
//连接MySql
{$IFDEF MySql}
    ProviderName := 'MySQL'; //
    server := '192.168.0.36,7788';
    database := 'test';
    UserName := 'root'; //数据库密码
    Password := '123'; //数据库密码
{$ENDIF}
//连接Odbc
{$IFDEF Odbc}

{$ENDIF}
  end;
end;

procedure TDataModel.DataModuleCreate(Sender: TObject);
begin
  coner := TUniConnection.Create(self);
  CfgDb(Coner);
  coner.Connect;
  Gqry := TUniQuery.Create(Self);
  Gqry.Connection := coner;
  UniSQL := TUniSQL.Create(Self);
  UniSQL.Connection := coner;
  UniProc := TUniStoredProc.Create(self);
  UniProc.Connection := Coner;
  DP.DataSet := Gqry;
  dpProc.DataSet := UniProc;
end;

{ Tdbpool }

constructor Tdbpool.Create;
begin
  Isused := False;
  FConner := TUniConnection.Create(nil);
  FQRy := TUniQuery.Create(nil);
  FQRy.Connection := FConner;
  FSql := TUniSQL.Create(nil);
  FSql.Connection := FConner;
  FProc := TUniStoredProc.Create(nil);
  FProc.Connection := FConner;
  FDataProvider := TDataSetProvider.Create(nil);
  TDataModel.CfgDb(FConner);
  FConner.Connected := True;
end;

destructor Tdbpool.Destroy;
begin
  if IAS <> nil then
    IAS.Sync;
  FProc.Free;
  FSql.Free;
  FQRy.Free;
  FConner.Free;
  FDataProvider.Free;
  inherited;
end;

{ TDbPoolsMM }

constructor TDbPoolsMM.Create;
begin
  FLst := TStringList.Create;
  Flock := TCriticalSection.Create;
end;

destructor TDbPoolsMM.Destroy;
begin
  Flock.Free;
  ClearAndFreeList(FLst);
  inherited;
end;

function TDbPoolsMM.GetAnPools: Tdbpool;
var
  i: Integer;
begin
  Result := nil;
  Flock.Enter;
  try
    for i := 0 to FLst.Count - 1 do begin
      if Tdbpool(FLst.Objects[i]).Isused = False then begin
        Result := Tdbpool(FLst.Objects[i]);
        Break;
      end;
    end;
  finally
    Flock.Release;
  end;
  if Result = nil then begin
    Result := Tdbpool.Create;
    Result.id := FLst.AddObject('', Result);
  end;
  Result.Isused := True;
end;

end.

