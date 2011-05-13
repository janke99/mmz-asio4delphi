{*******************************************************
        单元名称：untRmoDbClient.pas
        创建日期：2008-09-16 17:25:52
        创建者	  马敏钊
        功能:     远程数据库客户端
        当前版本： v2.0.2

更新历史
v1.0  单元实现
v1.1  解决不支持自增长字段的问题
v1.2  解决id号必须是第1个字段的问题
v1.3  为增加速度，做缓冲不用每次生成语句 ，改变自动更新时导致filter属性暂用的方式
v1.4  在sabason 兄的热心帮助下，解决了流试传输存在的问题，大大提高了传输效率 20100413
v1.5  全面修改为支持高效率的UniDAC数据库驱动套件 和ClientDataset (原来是ADO方式)支持所有主流数据库，大幅提高传输效率，且使用方法没有改变
v1.6  解决流传输存在的BUG  ，修正最后一个字段为blob字段导致语句生成错误的BUG
v1.7  增加服务端sys.ini文件配置客户端登陆权限，增加批量执行SQL语句接口
v1.8  增加服务端提供自动升级功能，可以升级多个文件或者目录，可选择强制升级或者客户端可选升级
v2.0  增加asio高性能 C++ 完成端口稳定库的封装支持
v2.1  增加存储过程调用的支持（参考静水流深的修改版本，在此表示感谢）
v2.0.2 2011-04-20
                  统一和服务端的版本号 ，从v2.1修改为v2.0.2
                  由于MAX()方式获取数据记录当数据表内存在大量记录时会很慢，而且可能导致ID冲突，
                  所以特，增加快速获取自增长ID的方式，客户端可配置是否使用这种方式
*******************************************************}


unit untRmoDbClient;

interface

uses
  Classes, UntsocketDxBaseClient, IdComponent, Controls, ExtCtrls, db, viewFileMM,
  SyncObjs;

type
  TConnthread = class;



  TchatClient = class(TSocketClient)
  private
    gLmemStream: TMemoryStream;
    FCachSQllst, FsqlLst: TStrings; //用来记录已经打开了的数据集 以及对于的语句
    FSqlPart1, FSqlPart2: string;

    Fsn: Cardinal;
    FIsDisConn: boolean; //是否是自己手动断开连接的
    Ftimer: TTimer; //连接保活器
    FisConning: Boolean; //是否连接成功
    //定时检查是否需要重连 或者连接断开
    procedure OnCheck(Sender: TObject);
     //检查是否连接存活
    procedure checkLive;

  public
    Flock: TCriticalSection;
    IsSpeedGetID: Boolean; //是否使用高速方式获取自增长ID
    IsInserIDfield: boolean; //是否插入语句 支持ID字段 自增长不允许插入该字段默认是false
    FLastInsertID: Integer; //insert语句时返回插入记录的自增字段的值

    //连接服务端
    function ConnToSvr(ISvrIP: ansistring; ISvrPort: Integer = 9988; Iacc: ansistring = '';
      iPsd: ansistring = ''): boolean;
    //断开连接
    procedure DisConn;

    //获取在线用户列表
    procedure Getonlineuser;
    //获取服务端文件列表
    procedure GetsvrFilelist;

    //获取文件ID
    procedure GetFileID(IFile: string);
    //文件传输
    procedure TransFile(IMisson: TFileMisson);

    //发言
    procedure SaySome(itoWho: string; IContent: string);

    //重新连接新的IP
    function ReConn(ISvrIP: ansistring; IPort: Integer = -1; Iacc: ansistring = '';
      iPsd: ansistring = ''): boolean;

    procedure OnCreate; override;
    procedure OnDestory; override;
  end;


  TConnthread = class(TThread)
  public
    Client: TchatClient;
    procedure execute; override;
  end;

var
  //远程连接控制对象
  Gob_RmoCtler: TchatClient;
  GCurrVer: integer = 1; //当前程序升级版本号

implementation

uses untfunctions, sysUtils, UntBaseProctol, IniFiles, ADOInt, Variants,
  Windows, untASIOSvr, Math;


procedure TchatClient.checkLive;
begin
  try
    if IsConnected then begin
      SendAsioHead(4);
      if WriteInteger(4) <> 4 then begin
        if FIsDisConn = False then
          FisConning := False;
      end;
    end
    else begin
      if FIsDisConn = False then
        FisConning := False;
    end;

  except
    if FIsDisConn = False then
      FisConning := False;
  end;
end;

function TchatClient.ConnToSvr(ISvrIP: ansistring; ISvrPort: Integer = 9988;
  Iacc: ansistring = ''; iPsd: ansistring = ''): boolean;
var
  i: Integer;
  ls: ansistring;
begin
  Result := True;
  if (FisConning = false) or (FHost <> ISvrIP) or (FPort <> ISvrPort) then begin
   // DisConn;
    FHost := ISvrIP;
    FPort := ISvrPort;
    Facc := Iacc;
    Fpsd := iPsd;
    FIsDisConn := False;

    try
      Result := Connto(FHost, FPort);
    except
      Result := False;
      FIsDisConn := False;
    end;
    if Result = True then begin
//        SendHead(CTSLogin);
//        WriteInteger(CClientID);
//        if ReadInteger <> STCLogined then
//          Result := False;
      ls := format('%s|%s', [Iacc, Str_Encry(iPsd, 'cht')]);
      Writeinteger(Length(ls));
      Write(ls);
      if ReadInteger <> STCLogined then begin
        Result := False;
        DisConn;
        FisConning := False;
        Exit;
      end;
      FisConning := True;
      FIsDisConn := False;
      Ftimer.Enabled := True;

    end;
  end;
end;

procedure TchatClient.DisConn;
begin
  try
//    if IsConnected then
    CloseConn;
  except
  end;
  FisConning := False;
  FIsDisConn := True;
end;

{ TConnthread }

procedure TConnthread.execute;
begin
  try
    if Client.ConnToSvr(Client.FHost, Client.FPort, Client.Facc, Client.Fpsd) then begin
      Client.FisConning := True;
    end;
  finally
    Client.Ftimer.Tag := 0;
  end;
end;



procedure TchatClient.GetsvrFilelist;
begin
  if Gob_RmoCtler.IsConning then begin
    Flock.Enter;
    try
      SendAsioHead(4);
      Writeinteger(3);
    finally
      Flock.Release;
    end;
  end;
end;

procedure TchatClient.Getonlineuser;
begin
  if Gob_RmoCtler.IsConning then begin
    Flock.Enter;
    try
      SendAsioHead(4);
      Writeinteger(1);
    finally
      Flock.Release;
    end;
  end;
end;

procedure TchatClient.OnCheck(Sender: TObject);
begin
  if TTimer(sender).tag = 0 then begin
    if ((IsConnected = false) or (FisConning = false)) and (FIsDisConn = false) then begin
      TTimer(sender).tag := 1;
      with TConnthread.Create(True) do begin
        FreeOnTerminate := True;
        Client := Self;
        Resume;
      end;
    end
    else begin
      checkLive;
    end;
  end;
end;

procedure TchatClient.OnCreate;
begin
  inherited;
  Flock := TCriticalSection.Create;
  IsSpeedGetID := True;
  FCachSQllst := THashedStringList.Create;
  Ftimer := TTimer.Create(nil);
  Ftimer.OnTimer := OnCheck;
  Ftimer.Interval := 3000;
  Ftimer.Enabled := False;
  Ftimer.Tag := 0;
  FisConning := false;
  FIsDisConn := False;
  FsqlLst := THashedStringList.Create;
  gLmemStream := TMemoryStream.Create;
end;

procedure TchatClient.OnDestory;
begin
  inherited;
  FCachSQllst.Free;
  Ftimer.Free;
  FsqlLst.Free;
  gLmemStream.Free;
  Flock.Free;
end;

function TchatClient.ReConn(ISvrIP: ansistring; IPort: Integer = -1; Iacc: ansistring = '';
  iPsd: ansistring = ''): boolean;
begin
  Result := False;
  if IsLegalIP(ISvrIP) then begin
    Result := ConnToSvr(ISvrIP, untfunctions.IfThen(IPort = -1, FPort, IPort), iacc, ipsd);
  end;
end;

procedure TchatClient.SaySome(itoWho: string; IContent: string);
var
  llen: integer;
  lls: string;
begin
  IContent := StringReplace(IContent, #13, ' ', [rfReplaceAll]);
  IContent := StringReplace(IContent, #10, ' ', [rfReplaceAll]);
  lls := Format('%s|%s', [iToWho, IContent]);
  llen := length(lls);
  Flock.Acquire;
  try
    SendAsioHead(8 + llen);
    Writeinteger(2);
    Writeinteger(llen);
    WriteString(lls);
  finally
    Flock.Release;
  end;
end;

procedure TchatClient.GetFileID(IFile: string);
var
  llen: integer;
begin
  Flock.Acquire;
  try
    llen := length(IFile);
    SendAsioHead(8 + llen);
    Writeinteger(5);
    Writeinteger(llen);
    WriteString(IFile);
  finally
    Flock.Release;
  end;
end;

procedure TchatClient.TransFile(IMisson: TFileMisson);
var
  llen: integer;
begin
  if IMisson.Transrd.Dir = 1 then begin //上传

  end
  else begin //下载
    IMisson.Transrd.len := Min(256000, IMisson.FileSize - IMisson.Transrd.RangeStart);
    llen := sizeof(IMisson.Transrd);
    Flock.Acquire;
    try
      SendAsioHead(4 + llen);
      Writeinteger(6);
      Gob_RmoCtler.WriteBuff(IMisson.Transrd, sizeof(IMisson.Transrd));
    finally
      Flock.Release;
    end;
//    IMisson.FileSize.
  end;
end;

end.

