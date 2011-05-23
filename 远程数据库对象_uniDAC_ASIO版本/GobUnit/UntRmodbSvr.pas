{ *******************************************************
  单元名称：UntRmodbSvr.pas
  创建日期：2008-09-16 17:26:15
  创建者	  马敏钊
  功能:     远程数据库服务端
  当前版本：v2.0.5
  历史：
  v2.0.0 2011-04-18
  对ASIO进行高效率的封装，
  同时封装高效的数据处理模型
  v2.0.1 2011-04-19
  增加存储过程调用的支持（参考静水流深发布的修改版本）
  在此对静水流深标示感谢
  v2.0.2 2011-04-20
  由于MAX()方式获取数据记录当数据表内存在大量记录时会很慢，而且可能导致ID冲突，
  所以特，增加快速获取自增长ID的方式，客户端可配置是否使用这种方式
  v2.0.3 2011-04-25
  根据群友Daniel建议 批量执行语句时添加事务安全
  v2.0.4 2011-05-10
  添加异步数据库调用 (数据库连接池)，加强多客户端访问性能
  v2.0.5 2011-05-10
  增加数据库连接池开关，在工程文件中定义dbpools即开 默认为开
 ******************************************************* }

unit UntRmodbSvr;

interface

uses Classes, UntSocketServer, UntTBaseSocketServer, untFunctions, syncobjs,
  Windows, Forms, DBClient, untASIOSvr, DM;

type
  Tider = class
  public
    Tablename: string;
    Id: Integer;
  end;

  TRmodbSvr = class(TCenterServer)
  private
    Flock: TCriticalSection;
    function ReadStream(Istream: TStream; ClientThread: TAsioClient)
      : TMemoryStream;
  public
    DBPoolsMM: TDbPoolsMM;
    GGDBPath: ansistring;
    gLastCpTime: Cardinal;
{$IFNDEF dbpools}
    gLmemStream: TMemoryStream;
    glBatchLst: TStrings;
{$ENDIF}
    Fidlst: TStrings;
    gider: Tider;
    // 连接到数据库
    function ConnToDb(IConnStr: ansistring): boolean;
    function OnCheckLogin(ClientThread: TAsioClient): boolean; override;
    function OnDataCase(ClientThread: TAsioClient; Ihead: Integer)
      : boolean; override;
    procedure OnCreate(ISocket: TBaseSocketServer); override;
    procedure OnDestroy; override;
    function GetCurrDBPath(InPath: ansistring): ansistring;
    function DatasetFromStream(Idataset: TClientDataSet;
      Stream: TMemoryStream): boolean;
    function DatasetToStream(iRecordset: TClientDataSet;
      Stream: TMemoryStream): boolean;
  end;

var
  Gob_RmoDBsvr: TRmodbSvr;

implementation

uses sysUtils, db, Variants, UntCFGer, IniFiles, AsyncCalls;

{ TRmoSvr }

function TRmodbSvr.DatasetFromStream(Idataset: TClientDataSet;
  Stream: TMemoryStream): boolean;
var
  RS: Variant;
begin
  Result := false;
  if Stream.Size < 1 then
    Exit;
  try
    Stream.Position := 0;
    // RS := Idataset.Recordset;
    RS.Open(TStreamAdapter.Create(Stream) as IUnknown);
    Result := true;
  finally;
  end;
end;

function TRmodbSvr.DatasetToStream(iRecordset: TClientDataSet;
  Stream: TMemoryStream): boolean;
const
  adPersistADTG = $00000000;
var
  RS: Variant;
begin
  Result := false;
  if iRecordset = nil then
    Exit;
  try
    // RS := iRecordset.Recordset;
    RS.Save(TStreamAdapter.Create(Stream) as IUnknown, adPersistADTG);
    Stream.Position := 0;
    Result := true;
  finally;
  end;
end;

function TRmodbSvr.ConnToDb(IConnStr: ansistring): boolean;
begin
  Result := true;
  if Shower <> nil then begin
    Shower.AddShow('连接数据库功<%s>', [IConnStr]);
  end;
end;

procedure TRmodbSvr.OnCreate(ISocket: TBaseSocketServer);
begin
  inherited;
  Flock := TCriticalSection.Create;
  Fidlst := TStringList.Create;
{$IFNDEF dbpools}
  gLmemStream := TMemoryStream.Create;
  glBatchLst := TStringList.Create;
{$ENDIF}
  gLastCpTime := 0;
  DBPoolsMM := TDbPoolsMM.Create;
end;

function StreamToVarArray(const S: TStream): Variant;
var
  P: Pointer;
  C: Integer;
  L: Integer;
begin
  S.Position := 0;
  C := S.Size;
  Result := VarArrayCreate([1, C], varByte);
  L := Length(Result);
  if L <> 0 then ;
  P := VarArrayLock(Result);
  try
    S.Read(P^, C);
  finally
    VarArrayUnlock(Result);
  end;
end;

procedure VarArrayToStream(const V: Variant; S: TStream);
var
  P: Pointer;
  C: Integer;
begin
  if not VarIsArray(V) then
    raise Exception.Create('Var is not array');
  if VarType(V[1]) <> varByte then
    raise Exception.Create('Var array is not blob array');
  C := VarArrayHighBound(V, 1) - VarArrayLowBound(V, 1) + 1;
  if not (C > 0) then
    Exit;

  P := VarArrayLock(V);
  try
    S.Write(P^, C * SizeOf(Byte));
    S.Position := 0;
  finally
    VarArrayUnlock(V);
  end;
end;

var
  lini: TIniFile;

procedure MGetFileListToStr(var Resp: ansistring; ISpit: ansistring;
  iFilter, iPath: ansistring; ContainSubDir: boolean = true;
  INeedPath: boolean = true);
var
  FSearchRec, DSearchRec: TSearchRec;
  FindResult: Cardinal;
begin
  FindResult := FindFirst(iPath + iFilter, sysUtils.faAnyFile, FSearchRec);
  try
    while FindResult = 0 do begin
      if ((FSearchRec.Attr and faDirectory) = faDirectory) or
        (FSearchRec.Name = '.') or (FSearchRec.Name = '..') or
        (ExtractFileExt(FSearchRec.Name) = '.lnk') then begin
        FindResult := FindNext(FSearchRec);
        Continue;
      end;
      if INeedPath then
        Resp := Resp + (iPath + FSearchRec.Name)
      else
        Resp := Resp + FSearchRec.Name;
      Resp := Resp + ISpit;
      FindResult := FindNext(FSearchRec);
    end;
    if ContainSubDir then begin
      FindResult := FindFirst(iPath + iFilter, faDirectory, DSearchRec);
      while FindResult = 0 do begin
        if ((DSearchRec.Attr and faDirectory) = faDirectory) and
          (DSearchRec.Name <> '.') and (DSearchRec.Name <> '..') then begin
          MGetFileListToStr(Resp, ISpit, iFilter, iPath + DSearchRec.Name + '\',
            ContainSubDir);
        end;
        FindResult := FindNext(DSearchRec);
      end;
    end;
  finally
    sysUtils.FindClose(FSearchRec);
    sysUtils.FindClose(DSearchRec);
  end;
end;


{$IFDEF dbpools}

procedure DoansyExec(ibuff: Tdbpool);
var
  Lemsg: AnsiString;
begin
  try
    case ibuff.IcmdKind of
      1: begin //执行语句
          try
            ibuff.FSql.sql.Clear;
            ibuff.FSql.SQL.Add(ibuff.IParam);
            ibuff.FSql.Execute;
            ibuff.ISocker.Socket.WriteInteger(1);
          except
            on e: Exception do begin
              ibuff.ISocker.Socket.WriteInteger(-1);
              Lemsg:=e.Message;
              ibuff.ISocker.Socket.WriteInteger(Length(Lemsg));
              ibuff.ISocker.Socket.Write(Lemsg);
              if ibuff.Shower <> nil then
                ibuff.Shower.AddShow('客户端执行语句异常<%s><DBPoolID:%d>', [e.Message, ibuff.id]);
            end;
          end;
        end;
      2: begin //执行查询
          try
            ibuff.FQRy.Close;
            ibuff.FQRy.SQL.Clear;
            ibuff.FQRy.SQL.Add(ibuff.IParam);
            ibuff.FQRy.Open;
            ibuff.FDataProvider.DataSet := ibuff.FQRy;
            ibuff.Gtmpbuffer := TMemoryStream.Create;
            try
              VarArrayToStream(ibuff.FDataProvider.Data, ibuff.Gtmpbuffer);
              ibuff.ISocker.Socket.WriteInteger(1);
              ibuff.IParent.SendZIpStream(ibuff.Gtmpbuffer, ibuff.ISocker);
            finally
              ibuff.FQRy.Close;
              ibuff.Gtmpbuffer.Free;
              ibuff.Gtmpbuffer := nil;
            end;
          except
            on e: Exception do begin
              ibuff.ISocker.Socket.WriteInteger(-1);
              lemsg:=e.Message;
              ibuff.ISocker.Socket.WriteInteger(Length(lemsg));
              ibuff.ISocker.Socket.Write(lemsg);
              if ibuff.Shower <> nil then
                ibuff.Shower.AddShow('客户端执行语句异常<%s><DBPoolID:%d>', [e.Message, ibuff.id]);
            end;
          end;
        end;
      110: begin //执行批量语句

        end;
      1010: begin
          ibuff.FProc.sql.Clear;
          ibuff.FProc.SQL.Add(ibuff.IParam);
          if not ibuff.FConner.InTransaction then begin
            ibuff.FConner.StartTransaction;
            if ibuff.Shower <> nil then begin
              ibuff.Shower.AddShow('%s启动事务',
                [ibuff.ISocker.PeerIP + '' + IntToStr(ibuff.ISocker.PeerPort)]);
                // Shower.AddShow('%s执行<%s>', [sClient,LSQl]);
              ibuff.Shower.AddShow('%s更新语句',
                [ibuff.ISocker.PeerIP + '' + IntToStr(ibuff.ISocker.PeerPort)]);
            end;
            try
              ibuff.FProc.ExecProc;
              ibuff.FConner.Commit;
              ibuff.ISocker.Socket.WriteInteger(1);

            except
              on e: Exception do begin
                ibuff.ISocker.Socket.WriteInteger(-1);
                lemsg:=e.Message;
                ibuff.ISocker.Socket.WriteInteger(Length(lemsg));
                ibuff.ISocker.Socket.Write(lemsg);
                ibuff.FConner.Rollback;
                if ibuff.Shower <> nil then
                  ibuff.Shower.AddShow('事务回滚，%s执行语句异常<%s>',
                    [ibuff.ISocker.PeerIP + '' +
                    IntToStr(ibuff.ISocker.PeerPort), e.Message]);
              end;
            end;
          end;
        end;
      1011: begin
          ibuff.FProc.SQL.Clear;
          ibuff.FProc.SQL.Add(ibuff.IParam);
          ibuff.FDataProvider.DataSet := ibuff.FProc;
          try
            ibuff.FProc.Open;
            try
              ibuff.Gtmpbuffer := TMemoryStream.Create;
              VarArrayToStream(ibuff.FDataProvider.Data, ibuff.Gtmpbuffer);
              ibuff.ISocker.Socket.WriteInteger(1);
              ibuff.IParent.SendZIpStream(ibuff.Gtmpbuffer, ibuff.ISocker);
              if ibuff.Shower <> nil then
                ibuff.Shower.AddShow('存储过程返回数据集，记录条数%s',
                  [IntToStr(ibuff.FDataProvider.DataSet.RecordCount)]);
            finally
              ibuff.FProc.Close;
              ibuff.Gtmpbuffer.Free;
              ibuff.Gtmpbuffer := nil;
            end;
          except
            on e: Exception do begin
              ibuff.ISocker.Socket.WriteInteger(-1);
              lemsg:=e.Message
              ibuff.ISocker.Socket.WriteInteger(Length(lemsg));
              ibuff.ISocker.Socket.Write(lemsg);
              if ibuff.Shower <> nil then
                ibuff.Shower.AddShow('%s存储过程存取失败<%s>', [e.Message]);
            end;
          end;
        end;
    end;
  except
    on E: Exception do begin
      if ibuff.Shower <> nil then
        ibuff.Shower.AddShow('异步执行失败<%d, %s, %s>', [ibuff.IcmdKind, ibuff.IParam, e.Message]);
    end;
  end;
  ibuff.Isused := False;
end;

function TRmodbSvr.OnDataCase(ClientThread: TAsioClient;
  Ihead: Integer): boolean;
var
{$IFDEF dbpools}
  Lbuff: Tdbpool;
  glBatchLst: TStrings;
{$ENDIF}
  Ltmp: TMemoryStream;
  i: Integer;
  Llen: Integer;
  LSQl, ls, lp: ansistring;
begin
  Result := true;
  try
    case Ihead of //
      9998: begin
          // 客户端查询升级信息
          if FileExists(GetCurrPath() + 'update.ini') then begin
            if lini = nil then
              lini := TIniFile.Create(GetCurrPath + 'update.ini');
            ClientThread.Socket.WriteInteger(1);
            ClientThread.Socket.WriteInteger(lini.ReadInteger('info',
              'ver', 0));
            i := lini.ReadInteger('info', 'isfrce', 1);
            ClientThread.Socket.WriteInteger(i);
            lp := GetCurrPath;
            Llen := Length(lp);
            ClientThread.Socket.WriteInteger(llen);
            ClientThread.Socket.Write(lp);
            ls := lini.ReadString('info', 'hint', '无');
            ClientThread.Socket.WriteInteger(Length(ls));
            ClientThread.Socket.Write(ls);
            ls := '';
            MGetFileListToStr(ls, '|', '*.*',
              GetCurrPath + lini.ReadString('info', 'filepath',
              'update'), true);
            ClientThread.Socket.WriteInteger(Length(ls));
            ClientThread.Socket.Write(ls);
          end
          else
            ClientThread.Socket.WriteInteger(0);
        end;
      9997: begin
          Llen := ClientThread.Socket.ReadInteger;
          ls := ClientThread.Socket.ReadStr(Llen);
          if FileExists(ls) then begin
            ClientThread.Socket.WriteInteger(1);
            Socket.SendZIpFile(ls, ClientThread);
          end
          else
            ClientThread.Socket.WriteInteger(0);
        end;
      0: begin // 断开连接
          ClientThread.Socket.Disconnect;
        end;
      1: begin // 执行一条SQL语句 更新或者执行
          Llen := ClientThread.Socket.ReadInteger;
          LSQl := ClientThread.Socket.ReadStr(Llen);
          Lbuff := DBPoolsMM.GetAnPools;
          if Shower <> nil then
            Shower.AddShow('客户端执行语句<%s><dbpoolid:%d>', [LSQl, Lbuff.id]);
          Lbuff.ISocker := ClientThread;
          Lbuff.IcmdKind := 1;
          Lbuff.IParam := LSQl;
          Lbuff.Shower := Shower;
          Lbuff.IAS := AsyncCall(@DoansyExec, Lbuff);
        end;
      1010: { //执行存储过程 } begin // 执行一条SQL语句 更新或者执行
          Llen := ClientThread.Socket.ReadInteger;
          LSQl := ClientThread.Socket.ReadStr(Llen);

          Lbuff := DBPoolsMM.GetAnPools;
          Lbuff.ISocker := ClientThread;
          Lbuff.IcmdKind := 1010;
          Lbuff.IParam := LSQl;
          Lbuff.Shower := Shower;
          Lbuff.IAS := AsyncCall(@DoansyExec, Lbuff);
        end;
      1011: { //执行存储过程 并返回结果集 } begin

          Llen := ClientThread.Socket.ReadInteger;
          LSQl := ClientThread.Socket.ReadStr(Llen);

          Lbuff := DBPoolsMM.GetAnPools;
          Lbuff.ISocker := ClientThread;
          Lbuff.IcmdKind := 1011;
          Lbuff.IParam := LSQl;
          Lbuff.Shower := Shower;
          Lbuff.IAS := AsyncCall(@DoansyExec, Lbuff);
        end;
      110: begin // 批量执行语句
          Ltmp := TMemoryStream.Create;
          glBatchLst := TStringList.Create;
          try
            Socket.GetZipStream(Ltmp, ClientThread);
            glBatchLst.LoadFromStream(Ltmp);
          finally
            Ltmp.Free;
          end;
          if Shower <> nil then
            Shower.AddShow('客户端批量执行语句', [LSQl]);
          try
            if glBatchLst.Count > 0 then begin
                // ------------------------------------------------------------------------------
                // 根据群友Daniel建议 批量处理添加事务  2011-04-25 10:12:47   马敏钊
                // ------------------------------------------------------------------------------
              DataModel.Coner.StartTransaction;
              try
                for Llen := 0 to glBatchLst.Count - 1 do begin // Iterate
                  DataModel.UniSQL.SQL.Clear;
                  DataModel.UniSQL.SQL.Add(glBatchLst[Llen]);
                  DataModel.UniSQL.Execute;
                end; // for
                DataModel.Coner.Commit;
              except
                DataModel.Coner.Rollback;
                raise;
              end;
            end;
            ClientThread.Socket.WriteInteger(1);
          except
            on e: Exception do begin
                // glBatchLst.SaveToFile('D:\1.txt');
              ClientThread.Socket.WriteInteger(-1);
              lsql:=e.Message;
              ClientThread.Socket.WriteInteger(Length(lsql));
              ClientThread.Socket.Write(lsql);
              if Shower <> nil then
                Shower.AddShow('客户端执行语句异常<%s>', [e.Message]);
            end;
          end;
          glBatchLst.Free;
        end;
      2: begin // 执行一个查询语句
          Llen := ClientThread.Socket.ReadInteger;
          LSQl := ClientThread.Socket.ReadStr(Llen);
          Lbuff := DBPoolsMM.GetAnPools;
          if Shower <> nil then
            Shower.AddShow('客户端执行查询语句<%s><dbpoolid:%d>', [LSQl, Lbuff.id]);
          Lbuff.ISocker := ClientThread;
          Lbuff.IcmdKind := 2;
          Lbuff.IParam := LSQl;
          Lbuff.Shower := Shower;
          Lbuff.IAS := AsyncCall(@DoansyExec, Lbuff);
        end;
      3: begin // 查询服务端数据库连接是否正常
        end;
      4: begin // 激活包
        end;
      6: begin
          Ltmp := TMemoryStream.Create;
          Llen := ClientThread.Socket.ReadInteger;
          LSQl := ClientThread.Socket.ReadStr(Llen);
          Ltmp := ReadStream(Ltmp, ClientThread);
          if Shower <> nil then
            Shower.AddShow('客户端执行Blob字段<%s>', [LSQl]);
          try
            DataModel.Gqry.Close;
            DataModel.Gqry.SQL.Clear;
            DataModel.Gqry.SQL.Add(LSQl);
            DataModel.Gqry.Params.ParamByName('Pbob')
              .LoadFromStream(Ltmp, ftBlob);
            DataModel.Gqry.Execute;
          except
            on e: Exception do begin
              ClientThread.Socket.WriteInteger(-1);
              lsql:=e.Message;
              ClientThread.Socket.WriteInteger(Length(lsql));
              ClientThread.Socket.Write(lsql);
              if Shower <> nil then
                Shower.AddShow('客户端执行Blob字段<%s>', [e.Message]);
            end;
          end;
          Ltmp.Free;
        end;
      7: begin // 自动增长ID
          // 维护一个ID列表 ，每次获取自增长ID由服务端来做唯一
          Llen := ClientThread.Socket.ReadInteger;
          LSQl := ClientThread.Socket.ReadStr(Llen);
          if Shower <> nil then
            Shower.AddShow('客户端<%s>查询ID<%s>', [ClientThread.PeerIP, LSQl]);
          Flock.Enter;
          try
            Llen := Fidlst.IndexOf(LowerCase(copy(LSQl, pos('|', LSQl) + 1,
              Length(LSQl))));
            try
              if Llen = -1 then begin
                gider := Tider.Create;
                gider.Tablename :=
                  LowerCase(copy(LSQl, pos('|', LSQl) + 1, Length(LSQl)));
                DataModel.Gqry.Close;
                DataModel.Gqry.SQL.Clear;
                DataModel.Gqry.SQL.Add(format('select max(%s) as maxid from %s',
                  [copy(LSQl, 1, pos('|', LSQl) - 1), gider.Tablename]));
                DataModel.Gqry.Open;
                if (DataModel.Gqry.RecordCount = 0) then
                  gider.Id := 1
                else
                  gider.Id := DataModel.Gqry.FieldByName('maxid').AsInteger + 1;
                Fidlst.AddObject(gider.Tablename, gider);
              end
              else begin
                gider := Tider(Fidlst.Objects[Llen]);
                inc(gider.Id);
              end;
              Llen := gider.Id;
              ClientThread.Socket.WriteInteger(1);
              ClientThread.Socket.WriteInteger(Llen);
            except
              on e: Exception do begin
                ClientThread.Socket.WriteInteger(-1);
                ClientThread.Socket.WriteInteger(Length(e.Message));
                ClientThread.Socket.Write(e.Message);
                if Shower <> nil then
                  Shower.AddShow('客户端获取ID异常<%s>', [e.Message]);
                if e is EAccessViolation then begin
                  if Shower <> nil then
                    Shower.AddShow('发现数据库对象地址访问错误', [e.Message]);
                end;
              end;
            end;
          finally
            Flock.Leave;
          end;
        end;
    end; // case
  except
    on e: Exception do
      if Shower <> nil then
        Shower.AddShow('线程执行异常<%s>', [e.Message]);
  end;
end;
{$ELSE}

function TRmodbSvr.OnDataCase(ClientThread: TAsioClient;
  Ihead: Integer): boolean;
var
  i: Integer;
  Llen: Integer;
  LSQl, ls, lp: ansistring;
begin
  Result := true;
  try
    case Ihead of //
      9998:
        begin
          // 客户端查询升级信息
          if FileExists(GetCurrPath() + 'update.ini') then
          begin
            if lini = nil then
              lini := TIniFile.Create(GetCurrPath + 'update.ini');
            ClientThread.Socket.WriteInteger(1);
            ClientThread.Socket.WriteInteger(lini.ReadInteger('info',
              'ver', 0));
            i := lini.ReadInteger('info', 'isfrce', 1);
            ClientThread.Socket.WriteInteger(i);
            lp := GetCurrPath;
            Llen := Length(lp);
            ClientThread.Socket.WriteInteger(llen);
            ClientThread.Socket.Write(lp);
            ls := lini.ReadString('info', 'hint', '无');
            ClientThread.Socket.WriteInteger(Length(ls));
            ClientThread.Socket.Write(ls);
            ls := '';
            MGetFileListToStr(ls, '|', '*.*',
              GetCurrPath + lini.ReadString('info', 'filepath',
              'update'), true);
            ClientThread.Socket.WriteInteger(Length(ls));
            ClientThread.Socket.Write(ls);
          end
          else
            ClientThread.Socket.WriteInteger(0);
        end;
      9997:
        begin
          Llen := ClientThread.Socket.ReadInteger;
          ls := ClientThread.Socket.ReadStr(Llen);
          if FileExists(ls) then
          begin
            ClientThread.Socket.WriteInteger(1);
            Socket.SendZIpFile(ls, ClientThread);
          end
          else
            ClientThread.Socket.WriteInteger(0);
        end;
      0:
        begin // 断开连接
          ClientThread.Socket.Disconnect;
        end;
      1:
        begin // 执行一条SQL语句 更新或者执行
          Flock.Enter;
          try
            Llen := ClientThread.Socket.ReadInteger;
            LSQl := ClientThread.Socket.ReadStr(Llen);
            if Shower <> nil then
              Shower.AddShow('客户端执行语句<%s>', [LSQl]);
            try
              DataModel.UniSQL.SQL.Clear;
              DataModel.UniSQL.SQL.Add(LSQl);
              DataModel.UniSQL.Execute;
              ClientThread.Socket.WriteInteger(1);
            except
              on e: Exception do
              begin
                ClientThread.Socket.WriteInteger(-1);
                lsql:=e.Message;
                ClientThread.Socket.WriteInteger(Length(lsql));
                ClientThread.Socket.Write(lsql);
                if Shower <> nil then
                  Shower.AddShow('客户端执行语句异常<%s>', [e.Message]);
              end;
            end;
          finally
            Flock.Leave;
          end;
        end;
      1010: { //执行存储过程 }
        begin // 执行一条SQL语句 更新或者执行
          Flock.Enter;
          try
            Llen := ClientThread.Socket.ReadInteger;
            LSQl := ClientThread.Socket.ReadStr(Llen);

            DataModel.UniProc.SQL.Clear;
            DataModel.UniProc.SQL.Add(LSQl);

            if not DataModel.Coner.InTransaction then
            begin
              DataModel.Coner.StartTransaction;
              if Shower <> nil then
              begin
                Shower.AddShow('%s启动事务',
                  [ClientThread.PeerIP + '' + IntToStr(ClientThread.PeerPort)]);
                // Shower.AddShow('%s执行<%s>', [sClient,LSQl]);
                Shower.AddShow('%s更新语句',
                  [ClientThread.PeerIP + '' + IntToStr(ClientThread.PeerPort)]);
              end;
              try
                DataModel.UniProc.ExecProc;
                DataModel.Coner.Commit;
                ClientThread.Socket.WriteInteger(1);
                // 向客户端返回output参数值
                { TODO -owshx -c :  2010-11-10 下午 02:26:32 }
                { with DataModel.UniProc1 do
                  begin
                  if ParamCount > 0 then
                  for i := 0 to ParamCount -1 do
                  begin
                  tmp := tmp + '####' +
                  Params.Items[i].Name + ':'
                  + VarToStrDef(Params.Items[i],'NoValue';
                  end;
                  System.delete(tmp,1,4);
                  ClientThread.Socket.WriteInteger(Length(tmp));
                  ClientThread.Socket.Write(tmp);
                  end; }
                // if Shower <> nil then Shower.AddShow('客户端提交事务成功');
              except
                on e: Exception do
                begin
                  ClientThread.Socket.WriteInteger(-1);
                  lsql:=e.Message;
                  ClientThread.Socket.WriteInteger(Length(lsql));
                  ClientThread.Socket.Write(lsql);
                  DataModel.Coner.Rollback;
                  if Shower <> nil then
                    Shower.AddShow('事务回滚，%s执行语句异常<%s>',
                      [ClientThread.PeerIP + '' +
                      IntToStr(ClientThread.PeerPort), e.Message]);
                end;
              end;
            end;

          finally
            Flock.Leave;
          end;
        end;
      1011: { //执行存储过程 并返回结果集 }
        begin
          Flock.Enter;
          try
            Llen := ClientThread.Socket.ReadInteger;
            LSQl := ClientThread.Socket.ReadStr(Llen);

            DataModel.UniProc.SQL.Clear;
            DataModel.UniProc.SQL.Add(LSQl);
            try
              DataModel.UniProc.Open;
              if gLmemStream <> nil then
                gLmemStream.Clear;
              VarArrayToStream(DataModel.dpProc.Data, gLmemStream);
              ClientThread.Socket.WriteInteger(1);
              Socket.SendZIpStream(gLmemStream, ClientThread);
              if Shower <> nil then
                Shower.AddShow('存储过程返回数据集，记录条数%s',
                  [IntToStr(DataModel.dpProc.DataSet.RecordCount)]);
            except
              on e: Exception do
              begin
                ClientThread.Socket.WriteInteger(-1);
                lsql:=e.Message;
                ClientThread.Socket.WriteInteger(Length(lsql));
                ClientThread.Socket.Write(lsql);
                if Shower <> nil then
                  Shower.AddShow('%s存储过程存取失败<%s>', [e.Message]);
              end;
            end;
          finally
            Flock.Leave;
          end;
        end;

      110:
        begin // 批量执行语句
          Flock.Enter;
          try
            gLmemStream.Size := 0;
            Socket.GetZipStream(gLmemStream, ClientThread);
            glBatchLst.LoadFromStream(gLmemStream);
            gLmemStream.Size := 0;
            if Shower <> nil then
              Shower.AddShow('客户端批量执行语句', [LSQl]);
            try
              if glBatchLst.Count > 0 then
              begin
                // ------------------------------------------------------------------------------
                // 根据群友Daniel建议 批量处理添加事务  2011-04-25 10:12:47   马敏钊
                // ------------------------------------------------------------------------------
                DataModel.Coner.StartTransaction;
                try
                  for Llen := 0 to glBatchLst.Count - 1 do
                  begin // Iterate
                    DataModel.UniSQL.SQL.Clear;
                    DataModel.UniSQL.SQL.Add(glBatchLst[Llen]);
                    DataModel.UniSQL.Execute;
                  end; // for
                  DataModel.Coner.Commit;
                except
                  DataModel.Coner.Rollback;
                  raise;
                end;
              end;
              ClientThread.Socket.WriteInteger(1);
            except
              on e: Exception do
              begin
                // glBatchLst.SaveToFile('D:\1.txt');
                ClientThread.Socket.WriteInteger(-1);
                lsql:=e.Message;
                ClientThread.Socket.WriteInteger(Length(LSQl));
                ClientThread.Socket.Write(lsql);
                if Shower <> nil then
                  Shower.AddShow('客户端执行语句异常<%s>', [e.Message]);
              end;
            end;
          finally
            Flock.Leave;
          end;
        end;
      2:
        begin // 执行一个查询语句
          Flock.Enter;
          try
            gLmemStream.Size := 0;
            Llen := ClientThread.Socket.ReadInteger;
            LSQl := ClientThread.Socket.ReadStr(Llen);
            try
              // ls := GetCurrPath + GetDocDate + GetDocTime;
              if Shower <> nil then
                Shower.AddShow('客户端执行查询语句<%s>', [LSQl]);
              DataModel.Gqry.Close;
              DataModel.Gqry.SQL.Clear;
              DataModel.Gqry.SQL.Add(LSQl);
              DataModel.Gqry.Open;
              VarArrayToStream(DataModel.Dp.Data, gLmemStream);
              ClientThread.Socket.WriteInteger(1);
              Socket.SendZIpStream(gLmemStream, ClientThread);
            except
              on e: Exception do
              begin
                ClientThread.Socket.WriteInteger(-1);
                LSQl:=e.Message;
                ClientThread.Socket.WriteInteger(Length(lsql));
                ClientThread.Socket.Write(lsql);
                if Shower <> nil then
                  Shower.AddShow('客户端执行语句异常<%s>', [e.Message]);
              end;
            end;
          finally
            Flock.Leave;
          end;
        end;
      3:
        begin // 查询服务端数据库连接是否正常
        end;
      4:
        begin // 激活包
        end;
      5:
        begin
          Flock.Enter;
          try
            ls := GetCurrDBPath(GGDBPath) + 'cfg1.mdb';
            if (gLastCpTime = 0) or
              (GetTickCount - gLastCpTime > 3600 * 1000 * 5) then
            begin
              CopyFile(PChar(GetCurrDBPath(GGDBPath) + 'cfg.mdb'),
                PChar(GetCurrDBPath(GGDBPath) + 'cfg1.mdb'), false);
              gLastCpTime := GetTickCount;
            end;
            Socket.SendZIpFile(ls, ClientThread);
          finally
            Flock.Leave;
          end;
        end;
      6:
        begin
          Flock.Enter;
          try
            gLmemStream.Size := 0;
            Llen := ClientThread.Socket.ReadInteger;
            LSQl := ClientThread.Socket.ReadStr(Llen);
            gLmemStream := ReadStream(gLmemStream, ClientThread);
            if Shower <> nil then
              Shower.AddShow('客户端执行Blob字段<%s>', [LSQl]);
            try
              DataModel.Gqry.Close;
              DataModel.Gqry.SQL.Clear;
              DataModel.Gqry.SQL.Add(LSQl);
              DataModel.Gqry.Params.ParamByName('Pbob')
                .LoadFromStream(gLmemStream, ftBlob);
              DataModel.Gqry.Execute;
            except
              on e: Exception do
              begin
                ClientThread.Socket.WriteInteger(-1);
                lsql:=e.message;
                ClientThread.Socket.WriteInteger(Length(lsql));
                ClientThread.Socket.Write(lsql);
                if Shower <> nil then
                  Shower.AddShow('客户端执行Blob字段<%s>', [e.Message]);
              end;
            end;
          finally
            Flock.Leave;
          end;
        end;
      7:
        begin // 自动增长ID
          // 维护一个ID列表 ，每次获取自增长ID由服务端来做唯一
          Flock.Enter;
          try
            Llen := ClientThread.Socket.ReadInteger;
            LSQl := ClientThread.Socket.ReadStr(Llen);
            if Shower <> nil then
              Shower.AddShow('客户端<%s>查询ID<%s>', [ClientThread.PeerIP, LSQl]);
            Llen := Fidlst.IndexOf(LowerCase(copy(LSQl, pos('|', LSQl) + 1,
              Length(LSQl))));
            try
              if Llen = -1 then
              begin
                gider := Tider.Create;
                gider.Tablename :=
                  LowerCase(copy(LSQl, pos('|', LSQl) + 1, Length(LSQl)));
                DataModel.Gqry.Close;
                DataModel.Gqry.SQL.Clear;
                DataModel.Gqry.SQL.Add(format('select max(%s) as maxid from %s',
                  [copy(LSQl, 1, pos('|', LSQl) - 1), gider.Tablename]));
                DataModel.Gqry.Open;
                if (DataModel.Gqry.RecordCount = 0) then
                  gider.Id := 1
                else
                  gider.Id := DataModel.Gqry.FieldByName('maxid').AsInteger + 1;
                Fidlst.AddObject(gider.Tablename, gider);
              end
              else
              begin
                gider := Tider(Fidlst.Objects[Llen]);
                inc(gider.Id);
              end;
              Llen := gider.Id;
              ClientThread.Socket.WriteInteger(1);
              ClientThread.Socket.WriteInteger(Llen);
            except
              on e: Exception do
              begin
                ClientThread.Socket.WriteInteger(-1);
                lsql:=e.Message;
                ClientThread.Socket.WriteInteger(Length(lsql));
                ClientThread.Socket.Write(lsql);
                if Shower <> nil then
                  Shower.AddShow('客户端获取ID异常<%s>', [e.Message]);
                if e is EAccessViolation then
                begin
                  if Shower <> nil then
                    Shower.AddShow('发现数据库对象地址访问错误', [e.Message]);
                end;
              end;
            end;
          finally
            Flock.Leave;
          end;
        end;
    end; // case
  except
    on e: Exception do
      if Shower <> nil then
        Shower.AddShow('线程执行异常<%s>', [e.Message]);
  end;
end;
{$ENDIF}

procedure TRmodbSvr.OnDestroy;
begin
  inherited;
  DBPoolsMM.Free;
  ClearAndFreeList(Fidlst);
  Flock.Free;
{$IFNDEF dbpools}
  glBatchLst.Free;
  gLmemStream.Free;
{$ENDIF}
end;

function TRmodbSvr.GetCurrDBPath(InPath: ansistring): ansistring;
var
  ISql: string;
  IGetPath: string;
  TStr: TStrings;
  i: Integer;
  iCount: Integer;
begin
  try
    Result := '';
    ISql := InPath;
    TStr := TStringList.Create;
    GetEveryWord(ISql, TStr, '\');
    iCount := TStr.Count;
    for i := 0 to TStr.Count - 2 do begin
      IGetPath := IGetPath + TStr[i] + '\';
    end;
    TStr.Free;
  finally
    Result := IGetPath;
  end;
end;

function TRmodbSvr.ReadStream(Istream: TStream; ClientThread: TAsioClient)
  : TMemoryStream;
var
  LBuff: Pointer;
  i, ltot, x: Integer;
begin
  if Istream = nil then
    Istream := TMemoryStream.Create;
  x := ClientThread.Socket.ReadInteger;
  TMemoryStream(Istream).Size := x;
  LBuff := TMemoryStream(Istream).Memory;
  ltot := Istream.Size;
  x := 0;
  while ltot > 0 do begin
    i := ClientThread.Socket.ReadBuff(PansiChar(LBuff) + x, ltot);
    Dec(ltot, i);
    inc(x, i);
  end; // while
  Result := TMemoryStream(Istream);
end;

function TRmodbSvr.OnCheckLogin(ClientThread: TAsioClient): boolean;
var
  i: Integer;
  lspit: TStrings;
  lname, lpsd, ls: ansistring;
  lws: string;
begin
  inherited OnCheckLogin(ClientThread);
  i := ClientThread.Socket.ReadInteger;
  ls := ClientThread.Socket.ReadStr(i);
  Result := false;
  try
    Gob_CFGer.SetSecton('auth');
    lspit := TStringList.Create;
    lws := ls;
    ExtractStrings(['|'], [' '], PChar(lws), lspit);
    if lspit.Count = 2 then begin
      if trim(lspit[0]) <> '' then begin
        // 做客户端登陆权限认证
        lpsd := Gob_CFGer.ReadString(lspit[0]);
        if Length(lspit[1]) > 0 then begin
          if lpsd = Str_Decry(lspit[1], 'rmo') then begin
            Result := true;
            if Shower <> nil then
              Shower.AddShow('用户:%s，认证通过，成功连接...', [lspit[0]]);
          end;
        end;
      end;
    end
  finally
    lspit.Free;
  end;
  if Result then
    ClientThread.Socket.WriteInteger(1001)
  else
    ClientThread.Socket.WriteInteger(1002)
end;

end.

