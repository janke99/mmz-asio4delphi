{ *******************************************************
  单元名称：UntRmodbSvr.pas
  创建日期：2008-09-16 17:26:15
  创建者	  马敏钊
  功能:     远程数据库服务端
  当前版本：v3.0.0
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
  v3.00  2011-04-29
     修改一个简单的聊天服务演示程序
  ******************************************************* }

unit UntRmodbSvr;

interface

uses Classes, UntSocketServer, untFunctions, syncobjs,
  Windows, Forms, DBClient, untASIOSvr;

type
  Tuserinfo = class
  public
    Name: string;
    psd: string;
  end;

  RfileTrans = record //文件传输结构体
    Fileid: Integer;
    Dir: Byte; //方向    1 上传 2 下载
    RangeStart: Int64;
    len: Int64;
    Userdata: Integer;
  end;
  TFileidinfo = class
  public
    Fid: Integer;
    FileFullName: string;
    FileStream: TFileStream;
    constructor Create(Iid: Integer; ifilename: string);
    destructor Destroy; override;
  end;



  TFileSvr = class(TCenterServer)
  private
    GFileID: Integer;
    Flock: TCriticalSection;
    function ReadStream(Istream: TStream; ClientThread: TAsioClient)
      : TMemoryStream;
  public
    FFileIDLst: TStrings;
    function Getonlineuser: string; //获取在线用户列表
    procedure BroCastUserChange(ikind: integer; iclient: TAsioClient);
    procedure SendtoInfo(Ifrom, iwho: string; IContent: ansistring); overload;
    procedure SendtoInfo(Ifrom: string; IClientobj: TAsioClient; IContent:
      ansistring); overload;
    function OnCheckLogin(ClientThread: TAsioClient): boolean; override;
    function OnDataCase(ClientThread: TAsioClient; Ihead: Integer)
      : boolean; override;
    procedure OnDisConn(ClientThread: TAsioClient); override;
    procedure OnCreate(ISocket: TBaseSocketServer); override;
    procedure OnDestroy; override;
  end;

var
  Gob_Filesvr: TFileSvr;

implementation

uses sysUtils, Variants;

procedure TFileSvr.OnCreate(ISocket: TBaseSocketServer);
begin
  inherited;
  Flock := TCriticalSection.Create;
  FFileIDLst := TStringList.Create;
  GFileID := 0;
end;



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
        Resp := Resp + (iPath + FSearchRec.Name + '?' + IntToStr(FSearchRec.Size))
      else
        Resp := Resp + FSearchRec.Name + '?' + IntToStr(FSearchRec.Size);
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


var
  Gsendbuf: array[0..1023000] of Byte;

function TFileSvr.OnDataCase(ClientThread: TAsioClient;
  Ihead: Integer): boolean;
var
  i: Integer;
  Llen: Integer;
  LSQl, ls, lp: ansistring;
  lspit: TStrings;
  lRFrd: RfileTrans;
  lfileinfo: TFileidinfo;
  ldata: TPoolItem;

begin
  Result := true;
  try
    case Ihead of //
      0: begin // 断开连接
          ClientThread.Socket.Disconnect;
        end;
      1: begin //获取在线用户列表
          ls := Getonlineuser;
          Llen := length(ls);
          if Llen > 0 then begin
//            ldata := ClientThread.Socket.BeginMakeData;
//            ClientThread.Socket.MakeData_Writeinteger(ldata, 1);
//            ClientThread.Socket.MakeData_Writeinteger(ldata, llen);
//            ClientThread.Socket.MakeData_Write(ldata, ls);
//            ClientThread.Socket.EndMakeData(ldata);

            ClientThread.Socket.Writeinteger(1);
            ClientThread.Socket.Writeinteger(Llen);
            ClientThread.Socket.Write(ls);
          end;
        end;
      2: begin //聊天
          Llen := ClientThread.Socket.Readinteger();
          ls := ClientThread.Socket.ReadStr(Llen);
          lspit := TStringList.Create;
          //找到要发送的客户端
          try
            ExtractStrings(['|'], [' '], PansiChar(ls), lspit);
            if lspit.Count = 2 then begin
              if lspit[0] = 'all' then begin
                for i := Socket.FClientLst.Count - 1 downto 0 do begin
                  try
                    SendtoInfo(Tuserinfo(ClientThread.userdata).Name, TAsioClient(Socket.FClientLst.Objects[i]), lspit[1]);
                  except
                  end;
                end;
              end
              else begin
                SendtoInfo(Tuserinfo(ClientThread.userdata).Name, lspit[0], lspit[1]);
              end;
            end;
          //发送
          finally
            lspit.Free;
          end;
        end;
      3: begin //获取服务端文件列表
          MGetFileListToStr(ls, '|', '*.*', GetCurrPath() + 'UPLOAD\', FALSE, FALSE);
          Llen := length(ls);
          if Llen > 0 then begin
            ClientThread.Socket.Writeinteger(3);
            ClientThread.Socket.Writeinteger(Llen);
            ClientThread.Socket.Write(ls);
          end;
        end;
      5: begin //获取文件ID
          Llen := ClientThread.Socket.Readinteger();
          ls := ClientThread.Socket.ReadStr(Llen);
          LSQl := GetCurrPath() + 'upload\' + ls;
          if FileExists(LSQl) then begin
            i := FFileIDLst.IndexOf(ls);
            if i = -1 then begin
              lfileinfo := TFileidinfo.Create(FFileIDLst.Count + 1, LSQl);
              FFileIDLst.AddObject(ls, lfileinfo);
            end
            else begin
              lfileinfo := TFileidinfo(FFileIDLst.Objects[i]);
            end;
            ClientThread.Socket.Writeinteger(5);
            ClientThread.Socket.Writeinteger(lfileinfo.Fid);
            ClientThread.Socket.Writeinteger(Llen);
            ClientThread.Socket.Write(ls);
          end
          else begin
            //文件不存在则创建一个
            FileClose(FileCreate(LSQl));
            lfileinfo := TFileidinfo.Create(FFileIDLst.Count + 1, LSQl);
            FFileIDLst.AddObject(ls, lfileinfo);
            ClientThread.Socket.Writeinteger(5);
            ClientThread.Socket.Writeinteger(lfileinfo.Fid);
            ClientThread.Socket.Writeinteger(Llen);
            ClientThread.Socket.Write(ls);
          end;
        end;
      6: begin //传输文件内容
          ClientThread.Socket.ReadBuff(@lRFrd, SizeOf(lRFrd));
          lfileinfo := TFileidinfo(FFileIDLst.Objects[lRFrd.Fileid - 1]);
          if lRFrd.Dir = 1 then begin //上传
            ClientThread.Socket.ReadBuff(@Gsendbuf[0], lRFrd.len);
            lfileinfo.FileStream.Position := lRFrd.RangeStart;
            lfileinfo.FileStream.WriteBuffer(Gsendbuf[0], lRFrd.len);
            ClientThread.Socket.Writeinteger(6);
            ClientThread.Socket.Write(@lRFrd, sizeof(lRFrd));
          end
          else begin //下载
            lfileinfo.FileStream.Position := lRFrd.RangeStart;
            lfileinfo.FileStream.ReadBuffer(Gsendbuf[0], lRFrd.len);
            ClientThread.Socket.Writeinteger(6);
            ClientThread.Socket.Write(@lRFrd, SizeOf(lRFrd));
            ClientThread.Socket.Write(@Gsendbuf[0], lRFrd.len);
          end;
        end;
    end; // case
  except
    on e: Exception do
      if Shower <> nil then
        Shower.AddShow('线程执行异常<%s>', [e.Message]);
  end;
end;

procedure TFileSvr.OnDestroy;
begin
  inherited;
  Flock.Free;
  ClearAndFreeList(FFileIDLst);
end;

function TFileSvr.ReadStream(Istream: TStream; ClientThread: TAsioClient)
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


function TFileSvr.OnCheckLogin(ClientThread: TAsioClient): boolean;
var
  i: Integer;
  lbuff: Tuserinfo;
  lspit: TStrings;
  lname, lpsd, ls: ansistring;
  lws: string;
begin
  inherited OnCheckLogin(ClientThread);
  i := ClientThread.Socket.ReadInteger;
  ls := ClientThread.Socket.ReadStr(i);
  Result := false;
  try
    lspit := TStringList.Create;
    lws := ls;
    ExtractStrings(['|'], [' '], PChar(lws), lspit);
    if lspit.Count = 2 then begin
      if trim(lspit[0]) <> '' then begin
        // 做客户端登陆权限认证
        if Length(lspit[1]) > 0 then begin
          Result := True;
          for i := 0 to Socket.FClientLst.Count - 1 do begin
            if TAsioClient(Socket.FClientLst.Objects[i]).userdata <> nil then
              if Tuserinfo(TAsioClient(Socket.FClientLst.Objects[i]).userdata).Name = lspit[0] then begin
                Result := False;
                Break;
              end;
          end;
          if Result then begin
            lbuff := Tuserinfo.Create;
            lbuff.Name := lspit[0];
            lbuff.psd := lspit[1];
            ClientThread.userdata := lbuff;
            Result := true;
            BroCastUserChange(1, ClientThread);
            if Shower <> nil then
              Shower.AddShow('用户:%s，认证通过，成功连接...(在线用户数:%d)', [lspit[0], Socket.FClientLst.Count]);
          end
          else begin
            if Shower <> nil then
              Shower.AddShow('用户:%s，已经存在，登录失败...', [lspit[0]]);
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

function TFileSvr.Getonlineuser: string;
var
  i: integer;
begin
  for i := 0 to Socket.FClientLst.Count - 1 do begin
    if TAsioClient(Socket.FClientLst.Objects[i]).userdata <> nil then begin
      Result := Result + Tuserinfo(TAsioClient(Socket.FClientLst.Objects[i]).userdata).Name;
      if i < Socket.FClientLst.Count - 1 then
        Result := Result + ','
    end;
  end;
end;

procedure TFileSvr.SendtoInfo(Ifrom, iwho: string; IContent: ansistring);
var
  i, llen: integer;
  ls: AnsiString;
begin
  for i := 0 to Socket.FClientLst.Count - 1 do begin
    if iwho = Tuserinfo(TAsioClient(Socket.FClientLst.Objects[i]).userdata).Name then begin
      TAsioClient(Socket.FClientLst.Objects[i]).Socket.Writeinteger(2);
      ls := Format('%s|%s|%s', [Ifrom, iwho, IContent]);
      llen := length(ls);
      TAsioClient(Socket.FClientLst.Objects[i]).Socket.Writeinteger(llen);
      TAsioClient(Socket.FClientLst.Objects[i]).Socket.Write(ls);
      if Shower <> nil then
        Shower.AddShow('%s对%s说:%s', [Ifrom, iwho, IContent]);
      break;
    end;
  end;
end;

procedure TFileSvr.SendtoInfo(Ifrom: string; IClientobj: TAsioClient; IContent:
  ansistring);
var
  i, llen: integer;
  ls: AnsiString;
begin
  IClientobj.Socket.Writeinteger(2);
  ls := Format('%s|%s|%s', [Ifrom, Tuserinfo(IClientobj.userdata).Name, IContent]);
  llen := length(ls);
  IClientobj.Socket.Writeinteger(llen);
  IClientobj.Socket.Write(ls);
  if Shower <> nil then
    Shower.AddShow('%s对%s说:%s', [Ifrom, Tuserinfo(IClientobj.userdata).Name, IContent]);
end;

procedure TFileSvr.BroCastUserChange(ikind: integer; iclient: TAsioClient);
var
  i: integer;
begin
  for i := 0 to Socket.FClientLst.Count - 1 do begin
    if (iclient <> TAsioClient(Socket.FClientLst.Objects[i])) and (TAsioClient(Socket.FClientLst.Objects[i]).userdata <> nil) then begin
      TAsioClient(Socket.FClientLst.Objects[i]).Socket.Writeinteger(4);
      TAsioClient(Socket.FClientLst.Objects[i]).Socket.Writeinteger(ikind); //1 加入, 2 离开
    end;
  end;
end;

procedure TFileSvr.OnDisConn(ClientThread: TAsioClient);
begin
  if ClientThread.userdata <> nil then begin
    BroCastUserChange(2, ClientThread);
    Tuserinfo(ClientThread.userdata).Free;
  end;
  inherited;
end;

{ TFileidinfo }

constructor TFileidinfo.Create(Iid: Integer; ifilename: string);
begin
  Fid := Iid;
  FileFullName := ifilename;
  FileStream := TFileStream.Create(ifilename, fmOpenReadWrite);
end;

destructor TFileidinfo.Destroy;
begin
  FileStream.Free;
  inherited;
end;

end.

