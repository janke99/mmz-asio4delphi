{*******************************************************}
{      单元名：  untFunctions.pas                       }
{      创建日期：2006-01-06 9:07:22                     }
{      创建者    马敏钊 QQ 22900104                     }
{      功能：    提供公共的方法                         }
{                                                       }
{*******************************************************}

unit untFunctions;

interface
//------------------------------------------------------------------------------
// 根据此配置文件决定编译那些函数
//------------------------------------------------------------------------------
{$DEFINE Db} //数据库操作函数
{$DEFINE File} //文件操作函数
{.$DEFINE Graph}//图形操作函数
{$DEFINE dialog} //对话筐
{$DEFINE List} //列表
{$DEFINE Zlib} //压缩
{$DEFINE Debug} //轻量级DEBUG
{$DEFINE Message} //消息
{$DEFINE Process} //进程
{$DEFINE TreeView} //树
{$DEFINE Registry}


uses SysUtils

{$IFDEF dialog}
  , dialogs
  , Controls
{$ENDIF}

{$IFDEF Db}
  , Contnrs
  , Variants
  , adodb, db, ComObj
{$ENDIF}

{$IFDEF File}
  , Windows
  , Forms
{$ENDIF}

{$IFDEF Graph}
  , Graphics
{$ENDIF}

{$IFDEF List}
  , Classes
{$ENDIF}

{$IFDEF ZLib}
  , ZLibex
{$ENDIF}
{$IFDEF Message}
  , Messages
{$ENDIF}
{$IFDEF Process}
  , TlHelp32
{$ENDIF}
{$IFDEF TreeView}
  , ComCtrls
{$ENDIF}
{$IFDEF Registry}
  , Registry
{$ENDIF}


  ;

//------------------------------------------------------------------------------
// 数据库
//------------------------------------------------------------------------------

{$IFDEF Db}
const
  CDb_State_NoneUsed = '';
  CDb_State_EverUsed = -1;
  CDb_State_CanUsed = 0;
//------------------------------------------------------------------------------
// 数据库操作类
//------------------------------------------------------------------------------
type
  {检查ADO是否可用的线程}
  TDBMrg = class;

  TCheckThread = class(TThread)
  private
    CheckTime: Cardinal;
  public
    DbMrg: TDbmrg;
    procedure Execute; override;
    constructor Create(IsStop: boolean; IDbMrg: TDbmrg);
  end;
  TDBMrg = class
  private
    FConn: TADOConnection;
    FPool: TStringList;
    FName: Integer;
    FAutoFreeConn: boolean;
    FTotCount: Integer;
    FThread_Check: TCheckThread;
    function GetIsConnectioned: Boolean;
  public
    FautoFree: boolean;
    {一个公共的BUff 启动时未创建}
    TepBuff: TADOQuery;
    property IsConnectioned: Boolean read GetIsConnectioned;
    property TotCount: Integer read FTotCount write FTotCount;
    constructor Create(IConStr: string; iTimeOut: integer = 15; ICreateBuffCount:
      Integer = 5); overload;
    constructor Create(IConn: TADOConnection; ICreateBuffCount: Integer = 5);
      overload;
    destructor Destroy; override;
    {获取一个ADO对象 可以指定名字 如果没有名字 系统自己返回一合适的对象}
    function GetAnQuery(IuserTime: integer = 1; Iname: string = ''): TADOQuery; overload;
    function GetAnQuery(Iname: string): TADOQuery; overload;
    {获取自动增长的ID号码}
    function GetId(ItabName, IFieldName: string): Integer;
    function GetMaxID(ItabName, IFieldName: string): Integer;
    {获取符合记录的个数}
    function GetCount(ItabName, IFieldName: string; Ivalue: variant): Cardinal;
      overload;
    function GetCount(ItabName: string): Cardinal; overload;
    {根据字段名和值删除表内容}
    procedure DeleteSomeThing(ItabName, IFieldName: string; Ivalue: Variant);
    {读取某个字段的值}
    function GetSomeThing(ItabName, IGetField, IWhereField: string; Ivalue: Variant): variant;
    {判断是否已经存在这个值}
    function IsExitThis(ItabName, IFieldName: string; Ivalue: Variant): boolean;
    {在数据集内定位记录}
    function FindDataInDataSet(IData: TDataSet; IFieldName, IFieldValue: string; Iopt: TLocateOptions): boolean;
    {执行一个语句}
    function ExecAnSql(Isql: string): Integer; overload;
    function ExecAnSql(Isql: string; const Args: array of const): Integer; overload;
    function ExecAnSql(IQueryRight: integer; Isql: string; const Args: array of const): Integer; overload;
    function ExecAnSql(Iado: TADoquery; Isql: string; const Args: array of const): Integer; overload;
    {执行一个查询语句}
    function OpenDataset(ISql: string): TADOQuery; overload;
    function OpenDataset(Iado: TADoquery; Isql: string): TADOQuery; overload;
    {用指定的ＡＤＯ执行}
    function OpenDataset(IadoName, ISql: string): TADOQuery; overload;
    function OpenDataset(Iado: TADOQuery; ISql: string; const Args: array of const):
      TADOQuery; overload;

    function OpenDataset(ISql: string; const Args: array of const): TADOQuery; overload;
    function OpenDataset(IQueryRight: integer; ISql: string; const Args: array of
      const): TADOQuery; overload;
    {释放ADO使用权以便其它人员使用}
    procedure BackToPool(Iado: TADOQuery); overload;
    procedure BackToPool(IName: string); overload;
    {加入一个由外部创建的ADO 帮它管理生命周期和重用}
    procedure AddAnOutAdo(Iado: TADOQuery);
    {为操作表预备一个ADO}
    function Ready(ItabName: string; Iado: TADOQuery): TADOQuery; overload;
    function Ready(ItabName: string; IQueryRight: integer = 1): TADOQuery; overload;
    {打开一个表}
    function OpenTable(ItabName: string; Iado: TADOQuery): TADOQuery; overload;
    function OpenTable(ItabName: string; IQueryRight: integer = 1): TADOQuery; overload;

    {检查是否处于可修改状态}
    function CheckModState(IAdo: TADOQuery): boolean;
    {安全保存}
    function SafePost(Iado: TADOQuery): boolean;
    {查询总共有多少个ADOquery}
    function PoolCount: Integer;
    {空闲着的ADO数量}
    function PoolFreeCount: Integer;
    {获取连接}
    function GetConn: TADOConnection;
    {获取ACCESS连接字符串}
    class function GetAccessConnStr(IDataSource: string; Ipsd: string = ''): string;
    {获取MSSQL连接字符串}
    class function GetMsSQLConnStr(IDataSource, IAcc, Ipsd, IDataBase: string): string;
    {获取Oracle连接字符串}
    class function GetOracleConnStr(IDataSource, IAcc, Ipsd: string): string;
    {获取Excel连接字符串}
    class function GetExcelConnStr(IFileName: string): string;
    {获取Text连接字符串}
    class function GetTextConnStr(IDBPath: string): string;
    {获取Dbf连接字符串}
    class function GetDBFConnStr(IDBPath: string): string;
    {获取MySQl连接字符串}
    class function GetMySqlConnStr(IDataSource, IDbName, IAcc, Ipsd: string): string;
    {创建一个空Access数据库文件}
    class function CreateAccessFile(IFileName: string): string;
  end;
//------------------------------------------------------------------------------
// 一个全局的变量
//------------------------------------------------------------------------------
var
  Gob_DBMrg: TDBMrg = nil;
  {分割字符串列表所用 自动释放}
  GlGetEveryWord: TStrings;

  {判断变体是是空就返回0或者''}
function IsNullReturnint(Ivar: Variant): Integer;
function IsNullReturnFloat(Ivar: Variant): Double;
function IsNullReturnStr(Ivar: Variant): string;
{$ENDIF}

//------------------------------------------------------------------------------
// 对话筐
//------------------------------------------------------------------------------
{$IFDEF dialog}
{几个常用的对话筐}
function QueryInfo(Info: string): Boolean; overload;
function QueryInfo(Info: string; const Args: array of const): Boolean; overload;
procedure ErrorInfo(Info: string); overload;
procedure ErrorInfo(Info: string; const Args: array of const); overload;
procedure WarningInfo(Info: string); overload;
procedure WarningInfo(Info: string; const Args: array of const); overload;
procedure TipInfo(Info: string); overload;
procedure TipInfo(Info: string; const Args: array of const); overload;
procedure ExceptTip(Info: string); overload;
procedure ExceptTip(Info: string; const Args: array of const); overload;
procedure ExceptionInfo(Info: string); overload;
{$ENDIF}
//------------------------------------------------------------------------------
// 列表
//------------------------------------------------------------------------------
{$IFDEF List}
{清除列表}
procedure ClearList(IList: TStrings; ISFree: boolean = False);
{释放列表}
procedure ClearAndFreeList(Ilist: TStrings);
{添加到列表}
procedure AddList(Ilist: Tstrings; ICapTion: string; Iobj: TObject);
{获取选中对象}
function GetObj(Ilist: TStrings; Iidx: Integer): TObject;
{分割字符串}
procedure GetEveryWord(S: string; E: TStrings; C: string); overload;
{分割字符串自动维护返回的TStrings}
function GetEveryWord(IStr: string; IChar: string): TStrings; overload;

{$ENDIF}
//------------------------------------------------------------------------------
// 图形
//------------------------------------------------------------------------------
{$IFDEF Graph}
{RGBTODElphiColor}
function RGB2BGR(C: Cardinal): TColor;
{DelphiColorTORGB}
function BGR2RGB(C: TColor): Cardinal;
{$ENDIF}
//------------------------------------------------------------------------------
// 文件
//------------------------------------------------------------------------------

{$IFDEF File}
{文件是否在使用中}
function IsFileInUse(FName: string): Boolean;
{取Windows系统目录}
function GetWindowsDir: string;
{取临时文件目录}
function GetWinTempDir: string;
{查找指定目录下文件}
procedure FindFileList(Path, Filter: string; FileList: TStrings; ContainSubDir: Boolean);
{修正目录名称 }
function FixPathName(Ipath: string): string;
{获取文件名称}
function GetOnlyFileName(IfileName: string): string;
{获取目录下的列表}
procedure GetFileDirToStr(var InResp: string; Ipath: string);
{获取目录下的文件到列表}
procedure GetFileList(Ilist: TStrings; iFilter, iPath: string; ContainSubDir:
  Boolean = True; INeedPath: boolean = True);
{获取目录下的文件到字符串}
procedure GetFileListToStr(var Resp: string; ISpit: string; iFilter, iPath:
  string; ContainSubDir: Boolean = True; INeedPath: boolean = True);
{清空为空的list}
procedure TrimList(Ilist: TStrings; IxmlFileName: string);
{获取目录下的文件夹和文件}
procedure GetCurrDirToStr(var InResp: string; Ipath: string);
{获取目录下的文件夹和文件大小}
procedure GetCurrDirAndSizeToStr(var InResp: string; Ipath: string);
{删除目录}
procedure DelDir(aDir: string; dDel: Boolean = true);
{$ENDIF}


{$IFDEF ZLib}
procedure EnCompressStream(CompressedStream: TMemoryStream);
procedure DeCompressStream(CompressedStream: TMemoryStream);
function EnCompStr(IStr: string): string;
function DeCompStr(IEncPstr: string): string;
{$ENDIF}

{$IFDEF Debug}

{轻量级控制台DEBUG类}
type
  TDeBug = class
  private
    m_hConsole: THandle;
  public
    constructor Create;
    destructor Destroy; override;
    procedure write(str: string);
    procedure read(var str: string);
    procedure ReadAnyKey();
  end;
var
  _Gob_Debug: TDeBug;
  ShowDeBug: boolean = True;
function DeBug(ICon: Variant): Variant; overload;
procedure DeBug(ICon: string; const Args: array of const); overload;
{$ENDIF}


//------------------------------------------------------------------------------
// 公共函数
//------------------------------------------------------------------------------
{IFTHen}
function IfThen(AValue: Boolean; const ATrue: Integer; const AFalse: Integer = 0): Integer; overload;
function IfThen(AValue: Boolean; const ATrue: Int64; const AFalse: Int64 = 0): Int64; overload;
function IfThen(AValue: Boolean; const ATrue: Double; const AFalse: Double = 0.0): Double; overload;
function IfThen(AValue: Boolean; const ATrue: string; const AFalse: string = ''): string; overload;
function IfThen(AValue: Boolean; const ATrue: boolean; const AFalse: boolean): boolean; overload;

{*随机字符串}
function RandomStr(aLength: Longint): string;
{*缩短路径显示}
function FormatPath(APath: string; Width: Integer): string;
{当前项目的路径}
function GetCurrPath(IsAutoGetDll: boolean = true): string;
{获取当前动态库的路径}
function GetCurrDllpath: string;
{判断是否都是数字}
function IsallNumber(IStr: string): boolean;
{获取格式化的当前时间}
function GetFormatTime: string;
{获取格式化的当前日期和时间}
function GetDocTime: string;
{获取格式化的当前日期}
function GetFormatDate: string;
{获取格式化的当前日期}
function GetDocDate: string;
{获取日期和时间}
function GetFormatDateTime: string;
{设置系统时间}
function SetSystime(ATime: TDateTime): boolean;
{//系统时间设置函数；只对当前有效 参数 年月日之间的分隔符号 默认 -}
function SetSystimeFormat(SS: char = '-'): boolean;




{是否是合法IP}
function IsLegalIP(IP: string): boolean;

{程序只运行一个实列}
function AppRunOnce: Boolean;
function AppRunAgian: Integer;
{发送跨进程数据}
{$IFDEF Message}
procedure SendProsData(Ihnd: Integer; var IData; ILen: Integer);
{$ENDIF}

{$IFDEF Process}
function KillTask(ExeFileName: string): integer;
{$ENDIF}

{$IFDEF TreeView}
function TreeNodeMove(mTreeNode: TTreeNode; mAnchorKind: TAnchorKind;
  mIsTry: Boolean = False): Boolean;
{$ENDIF}

{$IFDEF Registry}
{获取桌面}
function GetDeskeptPath: string;
{获取我的文档}
function GetMyDoumentpath: string;
{$ENDIF}

{字符串简单加密}
function Str_Encry(ISrc: string; key: string = 'mMz'): string;
{字符串简单解密}
function Str_Decry(ISrc: string; key: string = 'mMz'): string;

{获取硬盘剩余空间情况}
function GetDiskInfo(IdiskName: string): string;
{取文件长度}
function GetFileSize(FileName: string): int64;
function GetFileSize64(const FileName: string): Int64;
{获取文件夹大小}
function GetDirectorySize(Path: string): Int64;
{睡眠中处理消息}
procedure SleepMy(Itime: Cardinal); overload;
procedure SleepMy(var IVar: boolean; Itime: Cardinal; IIsCaseMsg:
  boolean = True); overload;


{全屏/恢复一个窗体}
function FullWindow(IForm: TWinControl): Boolean;

{锁住一个窗体的更新}
function LockWindow(Iwnd: HWND): boolean;
{恢复锁住的窗体}
procedure RestoreWindows;

{将秒转换为时间}
function SecondsToTime(Seconds: integer): string;

{目录拷贝}
function CopyDir(sDirName: string;
  sToDirName: string): Boolean;

{删除目录  }
function DeleteDir(sDirName: string): Boolean;

{获取汉字的拼音字母}
function GetPYIndexChar(Ihzchar: string; IlowCase: boolean = False): char;


{执行并等待完毕}
function ExecAndWait(const Filename, Params: string; WindowState: word):
  boolean;
{-------------------------------------------------------------------------------
  过程名:    GetBinData
  作者:      马敏钊
  日期:      2006.12.22
  参数:      ISourData:String;IParamNum,ILen:Integer;var IBuff
  返回值:    无
  说明:      获取数据  ISourData是源数据   IParamNum第几个二进制参数 ILen 参数长度  参数实参
-------------------------------------------------------------------------------}

{从字符串内取出二进制数据并且写入变量内}
procedure GetBinData(ISourData: string; IParamNum: integer; IBuff:
  TmemoryStream; ISpit: Char = '|'); overload;
{从字符串内取出二进制数据并且写入变量内}
procedure GetBinData(ISourData: pointer; ISourLen: integer; IParamNum, Ilen:
  integer; IBuff: pointer; ISpit: Char = '|'); overload;




implementation

uses ComConst, strutils;



{$IFDEF ZLib}
{-------------------------------------------------------------------------------
  过程名:    EnCompressStream
  作者:      马敏钊
  日期:      2006.03.01
  参数:      CompressedStream: TMemoryStream
  返回值:    无
  说明:     流压缩函数
-------------------------------------------------------------------------------}

procedure EnCompressStream(CompressedStream: TMemoryStream);
var
  SM: TZCompressionStream;
  DM: TMemoryStream;
  Count: int64; //注意，此处修改了,原来是int
begin
  if CompressedStream.Size <= 0 then
    exit;
  CompressedStream.Position := 0;
  Count := CompressedStream.Size; //获得流的原始尺寸
  DM := TMemoryStream.Create;
  SM := TZCompressionStream.Create(DM, zcMax);
  try
    CompressedStream.SaveToStream(SM); //SourceStream中保存着原始的流
    SM.Free; //将原始流进行压缩，DestStream中保存着压缩后的流
    CompressedStream.Clear;
    CompressedStream.WriteBuffer(Count, SizeOf(Count)); //写入原始文件的尺寸
    CompressedStream.CopyFrom(DM, 0); //写入经过压缩的流
    CompressedStream.Position := 0;
  finally
    DM.Free;
  end;
end;


{-------------------------------------------------------------------------------
  过程名:    DeCompressStream
  作者:      马敏钊
  日期:      2006.03.01
  参数:      CompressedStream: TMemoryStream
  返回值:    无
  说明:      解压缩函数
-------------------------------------------------------------------------------}

procedure DeCompressStream(CompressedStream: TMemoryStream);
var
  MS: TZDecompressionStream;
  Buffer: PChar;
  Count: int64;
begin
  if CompressedStream.Size <= 0 then
    exit;
  CompressedStream.Position := 0; //复位流指针
  CompressedStream.ReadBuffer(Count, SizeOf(Count));
  //从被压缩的文件流中读出原始的尺寸
  GetMem(Buffer, Count); //根据尺寸大小为将要读入的原始流分配内存块
  MS := TZDecompressionStream.Create(CompressedStream);
  try
    MS.ReadBuffer(Buffer^, Count);
    //将被压缩的流解压缩，然后存入 Buffer内存块中
    CompressedStream.Clear;
    CompressedStream.WriteBuffer(Buffer^, Count); //将原始流保存至 MS流中
    CompressedStream.Position := 0; //复位流指针
  finally
    FreeMem(Buffer);
    MS.Free;
  end;
end;

function EnCompStr(IStr: string): string;
//var
//  Lenc, LTe: Pointer;
//  LencLen: Integer;
begin
  Result := IStr;
//  CompressBuf(PChar(IStr), length(IStr), Lenc, LencLen);
//  SetLength(Result, LencLen);
//  CopyMemory(@result, Lenc, LencLen);
//  ShowMessage( IntToStr(length(Result)) );
//  FreeMem(Lenc);
//  DecompressBuf(Result,LencLen,0,LTe,LencLen);
//  ShowMessage(StrPas(LTe));
end;

function DeCompStr(IEncPstr: string): string;
//var
//  Lenc: Pointer;
//  LencLen: Integer;
begin
  Result := IEncPstr;
//  DecompressBuf(@IEncPstr, length(IEncPstr), 0, Lenc, LencLen);
//  Result := StrPas(PChar(Lenc));
//  FreeMem(Lenc);
end;


{$ENDIF}


{$IFDEF TreeView}

function TreeNodeMove(mTreeNode: TTreeNode; mAnchorKind: TAnchorKind;
  mIsTry: Boolean = False): Boolean;
var
  vTreeNode: TTreeNode;
begin
  Result := Assigned(mTreeNode);
  if not Result then
    Exit;
  case mAnchorKind of
    akTop: begin
        vTreeNode := mTreeNode.GetPrev;
        while Assigned(vTreeNode) do begin
          if vTreeNode = mTreeNode.GetPrevSibling then begin
            if not mIsTry then
              mTreeNode.MoveTo(vTreeNode, naInsert);
            Exit;
          end
          else if (vTreeNode.Level = mTreeNode.Level) then begin
            if not mIsTry then
              mTreeNode.MoveTo(vTreeNode, naAdd);
            Exit;
          end
          else if (vTreeNode <> mTreeNode.Parent) and
            (vTreeNode.Level + 1 = mTreeNode.Level) then begin
            if not mIsTry then
              mTreeNode.MoveTo(vTreeNode, naAddChild);
            Exit;
          end;
          vTreeNode := vTreeNode.GetPrev;
        end;
      end;
    akBottom: begin
        vTreeNode := mTreeNode.GetNext;
        while Assigned(vTreeNode) do begin
          if vTreeNode = mTreeNode.GetNextSibling then begin
            if not mIsTry then
              vTreeNode.MoveTo(mTreeNode, naInsert);
            Exit;
          end
          else if (vTreeNode.Level = mTreeNode.Level) then begin
            if not mIsTry then
              mTreeNode.MoveTo(vTreeNode, naAddFirst);
            Exit;
          end
          else if vTreeNode.Level + 1 = mTreeNode.Level then begin
            if not mIsTry then
              mTreeNode.MoveTo(vTreeNode, naAddChildFirst);
            Exit;
          end;
          vTreeNode := vTreeNode.GetNext;
        end;
      end;
    akLeft: begin
        vTreeNode := mTreeNode.Parent;
        if Assigned(vTreeNode) then begin
          if not mIsTry then
            mTreeNode.MoveTo(vTreeNode, naInsert);
          Exit;
        end;
      end;
    akRight: begin
        vTreeNode := mTreeNode.GetNextSibling;
        if Assigned(vTreeNode) then begin
          if not mIsTry then
            mTreeNode.MoveTo(vTreeNode, naAddChildFirst);
          Exit;
        end;
      end;
  end;
  Result := False;
end;

{
begin
  if not (ssCtrl in Shift) then
    Exit;
  case Key of
    VK_UP: TreeNodeMove(TTreeView(Sender).Selected, akTop);
    VK_DOWN: TreeNodeMove(TTreeView(Sender).Selected, akBottom);
    VK_LEFT: TreeNodeMove(TTreeView(Sender).Selected, akLeft);
    VK_RIGHT: TreeNodeMove(TTreeView(Sender).Selected, akRight);
  end;
end;
}


{$ENDIF}


{-------------------------------------------------------------------------------
  过程名:    GetCurrPath
  作者:      马敏钊
  日期:      2006.01.09
  参数:      无
  返回值:    String
  说明:      获取当前项目的路径
-------------------------------------------------------------------------------}

function GetCurrPath(IsAutoGetDll: boolean = true): string;
var
  ModName: array[0..MAX_PATH] of Char;
begin
  if ModuleIsLib and IsAutoGetDll then begin
    GetModuleFileName(HInstance, ModName, SizeOf(ModName));
    Result := ExtractFilePath(ModName);
  end
  else
    Result := ExtractFilePath(ParamStr(0));
end;


function GetCurrDllpath: string;
var
  p: pchar;
begin
  getmem(p, 255);
  try
    getmodulefilename(hinstance, p, 255);
    result := trim(strpas(p));
  finally
    freemem(p, 255);
  end;
end;
{--------------------------------
  过程名:    IsallNumber
  作者:      mmz
  日期:      2006.01.06
  参数:      IStr: string
  返回值:    boolean
  说明:
-------------------------------------------------------------------------------}

function IsallNumber(IStr: string): boolean;
var
  i: Integer;
begin
  if Length(IStr) = 0 then begin
    Result := False;
    Exit;
  end;
  Result := True;
  for I := 1 to Length(IStr) do begin // Iterate
    if not (IStr[i] in ['0'..'9']) then begin
      Result := False;
      Exit;
    end;
  end; // for
end;

{-------------------------------------------------------------------------------
  过程名:    GetDateTime
  作者:      马敏钊
  日期:      2006.01.15
  参数:      无
  返回值:    String
  说明:      获取格式化的时间
-------------------------------------------------------------------------------}

function GetFormatTime: string;
begin
  Result := FormatDateTime('hh:nn:ss', now);
end;

function GetDocTime: string;
begin
  Result := FormatDateTime('hhnnss', Time);
end;

function GetFormatDate: string;
begin
  Result := FormatDateTime('yyyy-mm-dd', Date);
end;

function GetDocDate: string;
begin
  Result := FormatDateTime('yyyymmdd', Date);
end;

function GetFormatDateTime: string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
end;


function SetSystimeFormat(SS: char = '-'): boolean;
var s: boolean;
begin
  //change the application's date time format.
  DateSeparator := SS;
  shortdateformat := 'YYYY' + SS + 'MM' + SS + 'DD';
  ShortTimeFormat := 'hh:mm:ss';
  TimeAMString := '';
  TimePMString := '';
  s := application.UpdateFormatSettings;
  // by luyear 20020709
  result := s;
end;

function SetSystime(ATime: TDateTime): boolean;
var
  ADateTime: TSystemTime;
  yy, mon, dd, hh, min, ss, ms: Word;
begin
  decodedate(ATime, yy, mon, dd);
  decodetime(ATime, hh, min, ss, ms);
  with ADateTime do begin
    wYear := yy;
    wMonth := mon;
    wDay := dd;
    wHour := hh;
    wMinute := min;
    wSecond := ss;
    wMilliseconds := ms;
  end;
  Result := SetLocalTime(ADateTime);
 // PostMessage(HWND_BROADCAST, WM_TIMECHANGE, 0, 0);
end;


{$IFDEF Registry}


function GetShellFolders(strDir: string): string;
const
  regPath = '\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders';
var
  Reg: TRegistry;
  strFolders: string;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(regPath, false) then begin
      strFolders := Reg.ReadString(strDir);
    end;
  finally
    Reg.Free;
  end;
  result := strFolders;
end;

{获取桌面}

function GetDeskeptPath: string;
begin
  Result := GetShellFolders('Desktop'); //是取得桌面文件夹的路径
end;

{获取我的文档}

function GetMyDoumentpath: string;
begin
  Result := GetShellFolders('Personal'); //我的文档
end;
{$ENDIF}



function IsLegalIP(IP: string): boolean;
var
  i, j, l: integer;
  ips: array[1..4] of string;
begin
  i := 1;
  for l := 1 to 4 do
    ips[l] := '';
  for j := 1 to length(ip) do
    if ip[j] <> '.' then begin
      if (ip[j] < '0') or (ip[j] > '9') then begin
        Result := false;
        exit;
      end;
      ips[i] := ips[i] + ip[j]
    end
    else
      inc(i);

  if (i <> 4)
    or ((strtoint(ips[1]) > 255) or (strtoint(ips[1]) < 0)) //originally is <1
    or ((strtoint(ips[2]) > 255) or (strtoint(ips[2]) < 0))
    or ((strtoint(ips[3]) > 255) or (strtoint(ips[3]) < 0))
    or ((strtoint(ips[4]) > 255) or (strtoint(ips[4]) < 0)) then
    Result := false
  else
    Result := true;
end;


{-------------------------------------------------------------------------------
  过程名:    AppRunOnce
  作者:      马敏钊
  日期:      2006.02.28
  参数:      无
  返回值:    Boolean
  说明:      程序只运行一个实列
-------------------------------------------------------------------------------}

function AppRunOnce: Boolean;
var
  HW: Thandle;
  sClassName, sTitle: string;
begin
  sClassName := application.ClassName;
  sTitle := application.Title;
  Randomize;
  application.Title := Format('F982D120-BA%dE-4199-%dFBD-F4EED%dE8A7',
    [random(20), Random(50), random(100)]); //更改当前app标题
  HW := findwindow(pchar(sClassName), pchar(sTitle));
  if HW <> 0 then begin
  //  ShowWindow(HW, SW_SHOW);
    SetForegroundWindow(HW);
    application.Terminate;
  end;
  application.Title := sTitle; //恢复app标题
  result := Hw = 0;
end;

{返回大于0就代表已经运行}

function AppRunAgian: Integer;
var
  HW: Thandle;
  sClassName, sTitle: string;
begin
  sClassName := application.ClassName;
  sTitle := application.Title;
  Randomize;
  application.Title := Format('F982D120-BA%dE-4199-%dFBD-F4EED%dE8A7',
    [random(20), Random(50), random(100)]); //更改当前app标题
  HW := findwindow(pchar(sClassName), pchar(sTitle));
  if HW <> 0 then begin
    ShowWindow(HW, SW_SHOW);
    SetForegroundWindow(HW);
  end;
  application.Title := sTitle; //恢复app标题
  result := Hw;
end;

{$IFDEF Process}

function KillTask(ExeFileName: string): integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot
    (TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle,
    FProcessEntry32);
  while integer(ContinueLoop) <> 0 do begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(ExeFileName))
      or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(OpenProcess(
        PROCESS_TERMINATE, BOOL(0),
        FProcessEntry32.th32ProcessID), 0));
    ContinueLoop := Process32Next(FSnapshotHandle,
      FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;
{$ENDIF}

{$IFDEF Message}

{-------------------------------------------------------------------------------
  过程名:    SendProsData
  作者:      马敏钊
  日期:      2006.07.27
  参数:      ISendHnd, Ihnd: Integer; var IData; ILen: Integer
  返回值:    无
  说明:      ISendHnd 发送的者的窗体句柄
-------------------------------------------------------------------------------}

procedure SendProsData(Ihnd: Integer; var IData; ILen: Integer);
var
  Lds: TCopyDataStruct;
begin
  Lds.cbData := ILen;
  Lds.lpData := Pointer(IData);
  SendMessage(Ihnd, WM_COPYDATA, 0, integer(@Lds));
end;
{$ENDIF}

function GetDiskInfo(IdiskName: string): string;
var
 // lpFreeBytesAvailableToCaller, lpUsedBytes: int64;
  lpFreeBytesAvailableToCaller: int64;
  lpTotalNumberOfBytes: int64;
  lpTotalNumberOfFreeBytes: TLargeInteger;
  sDrive: string;
begin
  sDrive := IdiskName + ':\';
  if GetDriveType(pchar(sDrive)) = DRIVE_FIXED then begin
    GetDiskFreeSpaceEx(PChar(sDrive), lpFreeBytesAvailableToCaller,
      lpTotalNumberOfBytes, @lpTotalNumberOfFreeBytes);
   // lpUsedBytes := lpTotalNumberOfBytes - lpFreeBytesAvailableToCaller;
    Result := IntToStr(lpFreeBytesAvailableToCaller div 1024 div 1024) + 'M'
      + ' / ' + IntToStr(lpTotalNumberOfBytes div 1024 div 1024) + 'M';
  end;
end;

{-------------------------------------------------------------------------------
  过程名:    GetFileSize
  作者:      马敏钊
  日期:      2006.01.06
  参数:      FileName: string
  返回值:    Integer
  说明:      取文件长度
-------------------------------------------------------------------------------}

function GetFileSize(FileName: string): int64;
var
  SearchRec: TSearchRec;
begin
  try
    if FindFirst(ExpandFileName(FileName), faAnyFile, SearchRec) = 0 then begin
      Result := SearchRec.Size;
      if Result < 0 then
        Result := GetFileSize64(FileName);
    end
    else
      Result := -1;
  finally
    SysUtils.FindClose(SearchRec);
  end;
end;


function GetFileSize64(const FileName: string): Int64;
var
  LStream: TFileStream;
begin
  if FileExists(FileName) = False then begin
    Result := -1;
    exit;
  end;
{$WARNINGS OFF}
  LStream := TFileStream.Create(FileName, fmShareDenyNone);
{$WARNINGS ON}
  try
    Result := LStream.Size;
  finally
    LStream.Free;
  end;
end;

function GetDirectorySize(Path: string): Int64;
var
  SR: TSearchRec;
begin
  Result := 0;
  if FindFirst(Path + '*.*', faAnyFile, SR) = 0 then begin
    if (sr.Name <> '.') and (sr.Name <> '..') and (sr.Attr = faDirectory) then
      Result := Result + GetDirectorySize(Path + Sr.Name + '\')
    else
      Result := Result + Sr.Size;
    while FindNext(sr) = 0 do
      if (sr.Name <> '.') and (sr.Name <> '..') and (sr.Attr = faDirectory) then
        Result := Result + GetdirectorySize(Path + Sr.Name + '\')
      else
        Result := Result + GetFileSize(Path + Sr.Name);
    Sysutils.FindClose(sr);
  end;
end;



procedure SleepMy(Itime: Cardinal);
var
  LS: Cardinal;
begin
  LS := GetTickCount;
  while GetTickCount - LS < Itime do begin
    if Application.Terminated then
      exit;
    Application.ProcessMessages;
    Sleep(10);
  end; // while
end;

procedure SleepMy(var IVar: boolean; Itime: Cardinal; IIsCaseMsg: boolean = True);
var
  LS: Cardinal;
begin
  LS := GetTickCount;
  while (GetTickCount - LS < Itime) and (not IVar) do begin
    Application.ProcessMessages;
    if Application.Terminated then
      exit;
    Sleep(10);
  end; // while
end;

function LockWindow(Iwnd: HWND): boolean;
begin
  Result := LockWindowUpdate(Iwnd);
end;

procedure RestoreWindows;
begin
  LockWindowUpdate(0);
end;

var
  _Form, _Parent: Cardinal; _OldLeft, _OldTop, _OldW, _OldH, _SavWL1: integer;
  _Alg: TAlign;

function FullWindow(IForm: TWinControl): Boolean;
begin
  Result := False;
//  LockWindowUpdate(IForm.Handle);
//  try
  {如果=就代表全屏}
  if cardinal(IForm) <> _Form then begin
    _Form := integer(IForm);
    _OldLeft := IForm.Left;
    _OldTop := IForm.Top;
    _OldW := IForm.Width;
    _OldH := IForm.Height;
    _Parent := IForm.Parent.Handle;
    _Alg := IForm.Align;
    IForm.Align := alNone;
    _SavWL1 := GetWindowLong(IForm.Handle, GWL_STYLE);
    SetParent(IForm.Handle, 0);
   // SetWindowLong(IForm.Handle, GWL_STYLE, Integer(WS_POPUP or WS_VISIBLE));
    SetWindowPos(IForm.Handle, HWND_TOPMOST, -6, -6, Screen.Width + 12, Screen.Height + 12, SWP_DRAWFRAME or SWP_FRAMECHANGED);
    Result := True;
  end {否则就代表恢复}
  else begin
    _Form := 0;
    IForm.Left := _OldLeft;
    IForm.Top := _OldTop;
    IForm.Width := _OldW;
    IForm.Height := _OldH;
    SetWindowLong(IForm.Handle, GWL_STYLE, _SavWL1);
    SetWindowPos(IForm.Handle, HWND_NOTOPMOST, _OldLeft, _OldTop, _OldW, _OldH, SWP_DRAWFRAME or SWP_FRAMECHANGED);
    SetParent(IForm.Handle, _Parent);
    IForm.Align := _Alg;
    IForm.Parent.Show;
  end;
//  finally
//     LockWindowUpdate(0);
//  end;
end;

function DoCopyDir(sDirName: string;
  sToDirName: string): Boolean;
var
  hFindFile: Cardinal;
  t, tfile: string;
  sCurDir: string[255];
  FindFileData: WIN32_FIND_DATA;
begin
  //先保存当前目录
  sCurDir := GetCurrentDir;
  ChDir(sDirName);
  hFindFile := FindFirstFile('*.*', FindFileData);
  if hFindFile <> INVALID_HANDLE_VALUE then begin
    if not DirectoryExists(sToDirName) then
      ForceDirectories(sToDirName);
    repeat
      tfile := FindFileData.cFileName;
      if (tfile = '.') or (tfile = '..') then
        Continue;
      if FindFileData.dwFileAttributes =
        FILE_ATTRIBUTE_DIRECTORY then begin
        t := sToDirName + '\' + tfile;
        if not DirectoryExists(t) then
          ForceDirectories(t);
        if sDirName[Length(sDirName)] <> '\' then
          DoCopyDir(sDirName + '\' + tfile, t)
        else
          DoCopyDir(sDirName + tfile, sToDirName + tfile);
      end
      else begin
        t := sToDirName + '\' + tFile;
        CopyFile(PChar(tfile), PChar(t), True);
      end;
    until FindNextFile(hFindFile, FindFileData) = false;
    windows.FindClose(hFindFile);
  end
  else begin
    ChDir(sCurDir);
    result := false;
    exit;
  end;
  //回到原来的目录下
  ChDir(sCurDir);
  result := true;
end;

function CopyDir(sDirName: string;
  sToDirName: string): Boolean;
begin
  Result := False;
  if Length(sDirName) <= 0 then
    exit;
  //拷贝...
  Result := DoCopyDir(sDirName, sToDirName);
end;

function DoRemoveDir(sDirName: string): Boolean;
var
  hFindFile: Cardinal;
  tfile: string;
  sCurDir: string;
  bEmptyDir: Boolean;
  FindFileData: WIN32_FIND_DATA;
begin
//如果删除的是空目录,则置bEmptyDir为True
//初始时,bEmptyDir为True
  bEmptyDir := True;
//先保存当前目录
  sCurDir := GetCurrentDir;
  SetLength(sCurDir, Length(sCurDir));
  ChDir(sDirName);
  hFindFile := FindFirstFile('*.*', FindFileData);
  if hFindFile <> INVALID_HANDLE_VALUE then begin
    repeat
      tfile := FindFileData.cFileName;
      if (tfile = '.') or (tfile = '..') then begin
        bEmptyDir := bEmptyDir and True;
        Continue;
      end;
//不是空目录,置bEmptyDir为False
      bEmptyDir := False;
      if FindFileData.dwFileAttributes =
        FILE_ATTRIBUTE_DIRECTORY then begin
        if sDirName[Length(sDirName)] <> '\' then
          DoRemoveDir(sDirName + '\' + tfile)
        else
          DoRemoveDir(sDirName + tfile);
        if not RemoveDirectory(PChar(tfile)) then
          result := false
        else
          result := true;
      end
      else begin
        if not DeleteFile(PChar(tfile)) then
          result := false
        else
          result := true;
      end;
    until FindNextFile(hFindFile, FindFileData) = false;
    FindClose(hFindFile);
  end
  else begin
    ChDir(sCurDir);
    result := false;
    exit;
  end;
//如果是空目录,则删除该空目录
  if bEmptyDir then begin
//返回上一级目录
    ChDir('..');
//删除空目录
    RemoveDirectory(PChar(sDirName));
  end;

//回到原来的目录下
  ChDir(sCurDir);
  result := true;
end;
//删除目录的函数：DeleteDir

function DeleteDir(sDirName: string): Boolean;
begin
  Result := False;
  if Length(sDirName) <= 0 then
    exit;
  Result := DoRemoveDir(sDirName) and RemoveDir(sDirName);
end;


function ExecAndWait(const Filename, Params: string; WindowState: word):
  boolean;
var
  SUInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  CmdLine: string;
begin
  CmdLine := filename + ' ' + params;
  FillChar(SUInfo, SizeOf(SUInfo), #0);
  with SUInfo do begin
    cb := SizeOf(SUInfo);
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := WindowState;
  end;
  Result := CreateProcess(nil, PChar(CmdLine), nil, nil, FALSE,
    CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil,
    PChar(ExtractFilePath(Filename)), SUInfo, ProcInfo);
  if Result then begin
    //等待应用程序结束
    WaitForSingleObject(ProcInfo.hProcess, INFINITE);
    //删除句柄
    CloseHandle(ProcInfo.hProcess);
    CloseHandle(ProcInfo.hThread);
  end;
end;

function GetPYIndexChar(Ihzchar: string; IlowCase: boolean = False): char;
var
  LS: string;
begin
  case WORD(Ihzchar[1]) shl 8 + WORD(Ihzchar[2]) of
    $B0A1..$B0C4: result := 'A';
    $B0C5..$B2C0: result := 'B';
    $B2C1..$B4ED: result := 'C';
    $B4EE..$B6E9: result := 'D';
    $B6EA..$B7A1: result := 'E';
    $B7A2..$B8C0: result := 'F';
    $B8C1..$B9FD: result := 'G';
    $B9FE..$BBF6: result := 'H';
    $BBF7..$BFA5: result := 'J';
    $BFA6..$C0AB: result := 'K';
    $C0AC..$C2E7: result := 'L';
    $C2E8..$C4C2: result := 'M';
    $C4C3..$C5B5: result := 'N';
    $C5B6..$C5BD: result := 'O';
    $C5BE..$C6D9: result := 'P';
    $C6DA..$C8BA: result := 'Q';
    $C8BB..$C8F5: result := 'R';
    $C8F6..$CBF9: result := 'S';
    $CBFA..$CDD9: result := 'T';
    $CDDA..$CEF3: result := 'W';
    $CEF4..$D1B8: result := 'X';
    $D1B9..$D4D0: result := 'Y';
    $D4D1..$D7F9: result := 'Z';
  else
    result := 'x';
  end;
  if IlowCase then begin
    LS := Result;
    LS := LowerCase(LS);
    Result := ls[1];
  end;
end;


procedure GetBinData(ISourData: pointer; ISourLen: integer; IParamNum, Ilen:
  integer; IBuff: pointer; ISpit: Char = '|');
var
  sLtep, slBuff: string;
  lp: PChar;
  Charlen: Integer;
begin
  slBuff := leftStr(StrPas(PAnsiChar(ISourData)), ISourLen);
  sLtep := '*' + IntToStr(IParamNum);
  Charlen := Pos(sLtep, slBuff) + Length(sLtep) - 1;
  lp := ISourData;
  inc(lp, Charlen);
  CopyMemory(ibuff, lp, Ilen);
end;

procedure GetBinData(ISourData: string; IParamNum: integer; IBuff:
  TmemoryStream; ISpit: Char = '|');
var
  i: Integer;
  sLtep, sLlen: string;
  iLlen, x: Integer;
begin
  sLtep := '*' + IntToStr(IParamNum);
  iLlen := Pos(sLtep, ISourData);
  x := 0;
  for i := iLlen downto 1 do begin // Iterate
    if ISourData[i] <> ISpit then
      inc(x)
    else
      break;
  end; // for
  sLlen := copy(ISourData, iLlen - x + 1, x - 1);
  IBuff.SetSize(StrToInt(sLlen));
  CopyMemory(IBuff.Memory, PChar(ISourData) + Pos(sLtep, ISourData) + Length(sLtep), StrToInt(sLlen));
end;



function SecondsToTime(Seconds: integer): string;
var m, s: integer;
begin
  if Seconds < 0 then
    Seconds := 0;
  m := (Seconds div 60) mod 60;
  s := Seconds mod 60;
  Result := IntToStr(Seconds div 3600)
    + ':' + char(48 + m div 10) + char(48 + m mod 10)
    + ':' + char(48 + s div 10) + char(48 + s mod 10);
end;

function Str_Encry(ISrc: string; key: string = 'mMz'): string;
var
  KeyLen: Integer;
  KeyPos: Integer;
  offset: Integer;
  dest: string;
  SrcPos: Integer;
  SrcAsc: Integer;
  Range: Integer;
begin
  KeyLen := Length(Key);
  KeyPos := 0;
  Range := 256;
  Randomize;
  offset := Random(Range);
  dest := format('%1.2x', [offset]);
  for SrcPos := 1 to Length(ISrc) do begin
    SrcAsc := (Ord(ISrc[SrcPos]) + offset) mod 255;
    if KeyPos < KeyLen then
      KeyPos := KeyPos + 1
    else
      KeyPos := 1;
    SrcAsc := SrcAsc xor Ord(Key[KeyPos]);
    dest := dest + format('%1.2x', [SrcAsc]);
    offset := SrcAsc;
  end;
  Result := Dest;
end;

function Str_Decry(ISrc: string; key: string = 'mMz'): string;
var
  KeyLen: Integer;
  KeyPos: Integer;
  offset: Integer;
  dest: string;
  SrcPos: Integer;
  SrcAsc: Integer;
  TmpSrcAsc: Integer;
begin
  KeyLen := Length(Key);
  KeyPos := 0;
  offset := StrToInt('$' + copy(ISrc, 1, 2));
  SrcPos := 3;
  SrcAsc := 0;
  repeat
    try
      SrcAsc := StrToInt('$' + copy(ISrc, SrcPos, 2));
    except
    end;
    if KeyPos < KeyLen then
      KeyPos := KeyPos + 1
    else
      KeyPos := 1;
    TmpSrcAsc := SrcAsc xor Ord(Key[KeyPos]);
    if TmpSrcAsc <= offset then
      TmpSrcAsc := 255 + TmpSrcAsc - offset
    else
      TmpSrcAsc := TmpSrcAsc - offset;
    dest := dest + chr(TmpSrcAsc);
    offset := srcAsc;
    SrcPos := SrcPos + 2;
  until SrcPos >= Length(ISrc);
  Result := Dest;
end;
{-------------------------------------------------------------------------------
  过程名:    FormatPath
  作者:      马敏钊
  日期:      2006.01.06
  参数:      APath: string; Width: Integer
  返回值:    string
  说明:      路径太长显示的时候以...代替
-------------------------------------------------------------------------------}

function FormatPath(APath: string; Width: Integer): string;
var
  SLen: Integer;
  i, j: Integer;
  LString: string;
begin
  SLen := Length(APath);
  if (SLen <= Width) or (Width <= 6) then begin
    Result := APath;
    Exit
  end
  else begin
    i := SLen;
    LString := APath;
    for j := 1 to 2 do begin
      while (LString[i] <> '\') and (SLen - i < Width - 8) do
        i := i - 1;
      i := i - 1;
    end;
    for j := SLen - i - 1 downto 0 do
      LString[Width - j] := LString[SLen - j];
    for j := SLen - i to SLen - i + 2 do
      LString[Width - j] := '.';
    Delete(LString, Width + 1, 255);
    Result := LString;
  end;
end;

{-------------------------------------------------------------------------------
  过程名:    RandomStr
  作者:      mmz
  日期:      2006.01.06
  参数:      aLength : Longint
  返回值:    String
  说明:      随机字符串
-------------------------------------------------------------------------------}

function RandomStr(aLength: Longint): string;
var
  X: Longint;
begin
  if aLength <= 0 then
    exit;
  SetLength(Result, aLength);
  for X := 1 to aLength do
    Result[X] := Chr(Random(26) + 65);
end;


{-------------------------------------------------------------------------------
  过程名:    IfThen
  作者:      马敏钊
  日期:      2006.01.06
  参数:      AValue: Boolean; const ATrue: Integer; const AFalse: Integer = 0
  返回值:    Integer
  说明:
-------------------------------------------------------------------------------}

function IfThen(AValue: Boolean; const ATrue: Integer; const AFalse: Integer = 0): Integer; overload;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

{-------------------------------------------------------------------------------
  过程名:    IfThen
  作者:      马敏钊
  日期:      2006.01.06
  参数:      AValue: Boolean; const ATrue: Int64; const AFalse: Int64 = 0
  返回值:    Int64
  说明:
-------------------------------------------------------------------------------}

function IfThen(AValue: Boolean; const ATrue: Int64; const AFalse: Int64 = 0): Int64; overload;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

{-------------------------------------------------------------------------------
  过程名:    IfThen
  作者:      马敏钊
  日期:      2006.01.06
  参数:      AValue: Boolean; const ATrue: Double; const AFalse: Double = 0.0
  返回值:    Double
  说明:
-------------------------------------------------------------------------------}

function IfThen(AValue: Boolean; const ATrue: Double; const AFalse: Double = 0.0): Double; overload;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

function IfThen(AValue: Boolean; const ATrue: string; const AFalse: string = ''): string; overload;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

function IfThen(AValue: Boolean; const ATrue: boolean; const AFalse: boolean): boolean; overload;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;
{$IFDEF File}
{-------------------------------------------------------------------------------
  过程名:    IsFileInUse
  作者:      马敏钊
  日期:      2006.01.06
  参数:      FName: string
  返回值:    Boolean
  说明:      文件是否在使用中
-------------------------------------------------------------------------------}

function IsFileInUse(FName: string): Boolean;
var
  HFileRes: HFILE;
begin
  Result := False;
  if not FileExists(FName) then
    Exit;
  HFileRes := CreateFile(PChar(FName), GENERIC_READ or GENERIC_WRITE, 0,
    nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Result := (HFileRes = INVALID_HANDLE_VALUE);
  if not Result then
    CloseHandle(HFileRes);
end;



{-------------------------------------------------------------------------------
  过程名:    GetWindowsDir
  作者:      马敏钊
  日期:      2006.01.06
  参数:      无
  返回值:    string
  说明:     取Windows系统目录
-------------------------------------------------------------------------------}

function GetWindowsDir: string;
var
  Buf: array[0..MAX_PATH] of Char;
begin
  GetWindowsDirectory(Buf, MAX_PATH);
  Result := Buf;
end;

{-------------------------------------------------------------------------------
  过程名:    GetWinTempDir
  作者:      马敏钊
  日期:      2006.01.06
  参数:      无
  返回值:    string
  说明:      取临时文件目录
-------------------------------------------------------------------------------}

function GetWinTempDir: string;
var
  Buf: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, Buf);
  Result := Buf;
end;
{$ENDIF}

{$IFDEF Graph}

{-------------------------------------------------------------------------------
  过程名:    RGB2BGR
  作者:      马敏钊
  日期:      2006.01.06
  参数:      C: Cardinal
  返回值:    TColor
  说明:
-------------------------------------------------------------------------------}

function RGB2BGR(C: Cardinal): TColor;
var
  R, G, B: byte;
  RGBColor: Longint;
begin
  RGBColor := ColorToRGB(C);
  R := GetRValue(RGBColor);
  G := GetGValue(RGBColor);
  B := GetBValue(RGBColor);
  Result := RGB(B, G, R);
end;

{-------------------------------------------------------------------------------
  过程名:    BGR2RGB
  作者:      马敏钊
  日期:      2006.01.06
  参数:      C: TColor
  返回值:    Cardinal
  说明:
-------------------------------------------------------------------------------}

function BGR2RGB(C: TColor): Cardinal;
var
  R, G, B: byte;
begin
  B := GetRValue(C);
  G := GetGValue(C);
  R := GetBValue(C);
  Result := RGB(R, G, B);
end;
{$ENDIF}




{$IFDEF dialog}

{-------------------------------------------------------------------------------
  过程名:    TipInfo
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Info: string
  返回值:    无
  说明:
-------------------------------------------------------------------------------}

procedure TipInfo(Info: string);
begin
  MessageDlg(Info, mtInformation, [mbok], 0)
end;

procedure TipInfo(Info: string; const Args: array of const);
begin
  MessageDlg(Format(Info, Args), mtInformation, [mbok], 0)
end;
{-------------------------------------------------------------------------------
  过程名:    WarningInfo
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Info: string
  返回值:    无
  说明:
-------------------------------------------------------------------------------}

procedure WarningInfo(Info: string);
begin
  MessageDlg(Info, mtWarning, [mbok], 0);
end;

procedure WarningInfo(Info: string; const Args: array of const);
begin
  MessageDlg(Format(Info, Args), mtWarning, [mbok], 0);
end;
{-------------------------------------------------------------------------------
  过程名:    ErrorInfo
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Info: string
  返回值:    无
  说明:
-------------------------------------------------------------------------------}

procedure ErrorInfo(Info: string);
begin
  MessageDlg(Info, mtError, [mbok], 0)
end;

procedure ErrorInfo(Info: string; const Args: array of const);
begin
  ErrorInfo(Format(Info, Args));
end;

{-------------------------------------------------------------------------------
  过程名:    QueryInfo
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Info: string
  返回值:    Boolean
  说明:
-------------------------------------------------------------------------------}

function QueryInfo(Info: string): Boolean;
begin
  Result := MessageDlg(Info, mtConfirmation, [mbYES, mbNO], 0) = mrYES;
end;

function QueryInfo(Info: string; const Args: array of const): Boolean; overload;
begin
  Result := MessageDlg(Format(info, Args), mtConfirmation, [mbYES, mbNO], 0) = mrYES;
end;

{-------------------------------------------------------------------------------
  过程名:    ExceptTip
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Info: string
  返回值:    无
  说明:
-------------------------------------------------------------------------------}

procedure ExceptTip(Info: string);
begin
  MessageDlg(Info, mtInformation, [mbok], 0);
  Abort;
end;

procedure ExceptTip(Info: string; const Args: array of const);
begin
  MessageDlg(Format(Info, Args), mtInformation, [mbok], 0);
  Abort;
end;

procedure ExceptionInfo(Info: string);
begin
  raise Exception.Create(Info);
end;

{-------------------------------------------------------------------------------
  过程名:    IsNullBackStr
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Ivar: Variant
  返回值:    string
  说明:
-------------------------------------------------------------------------------}
{$ENDIF}

{$IFDEF List}
{-------------------------------------------------------------------------------
  过程名:    GetObj
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Ilist: TStrings; Iidx: Integer
  返回值:    TObject
  说明:
-------------------------------------------------------------------------------}

function GetObj(Ilist: TStrings; Iidx: Integer): TObject;
begin
  Result := Ilist.Objects[Iidx];
end;

{-------------------------------------------------------------------------------
  过程名:    AddList
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Ilist: Tstrings; ICapTion: string; Iobj: Tobject
  返回值:    无
  说明:
-------------------------------------------------------------------------------}

procedure AddList(Ilist: Tstrings; ICapTion: string; Iobj: Tobject);
begin
  Ilist.AddObject(ICapTion, Iobj);
end;

{-------------------------------------------------------------------------------
  过程名:    ClearList
  作者:      马敏钊
  日期:      2006.01.06
  参数:      IList: TStrings
  返回值:    无
  说明:
-------------------------------------------------------------------------------}

procedure ClearList(IList: TStrings; ISFree: boolean = False);
var
  i: Integer;
begin
  for I := 0 to IList.Count - 1 do begin
    try
      IList.Objects[i].free;
    except
    end;
  end;
  IList.Clear;
  if ISFree then
    IList.Free;
end;

procedure ClearAndFreeList(Ilist: TStrings);
begin
  ClearList(Ilist);
  FreeAndNil(Ilist);
end;

{-------------------------------------------------------------------------------
  过程名:    GetOnlyFileName
  作者:      马敏钊
  日期:      2006.01.06
  参数:      IfileName:String
  返回值:    string
  说明:      获取文件名称 不带路径和后缀
-------------------------------------------------------------------------------}

function GetOnlyFileName(IfileName: string): string;
var
  Tmp, Ext: string;
begin
  Tmp := ExtractFileName(IfileName);
  Ext := ExtractFileExt(IfileName);
  Result := copy(Tmp, 1, Length(Tmp) - Length(Ext));
end;

{-------------------------------------------------------------------------------
  过程名:    GetEveryWord
  作者:      马敏钊
  日期:      2006.01.06
  参数:      S: string; E: TStringList; C: string
  返回值:    无
  说明:      分割字符串 返回的StringList由外部自己管理内存
-------------------------------------------------------------------------------}

procedure GetEveryWord(S: string; E: TStrings; C: string);
var
  t, a: string;
begin
  if E = nil then
    E := TStringList.Create
  else
    E.Clear;
  t := s;
  while Pos(c, t) > 0 do begin
    a := copy(t, 1, pos(c, t) - 1);
    t := copy(t, pos(c, t) + 1, length(t) - pos(c, t));
    e.Add(a);
  end;
  if Trim(t) <> '' then
    e.Add(t);
end;

function GetEveryWord(IStr: string; IChar: string): TStrings;
var
  t, a: string;
begin
  if assigned(GlGetEveryWord) = False then
    GlGetEveryWord := TStringList.Create;
  GlGetEveryWord.Clear;
  t := IStr;
  while Pos(IChar, t) > 0 do begin
    a := copy(t, 1, pos(IChar, t) - 1);
    t := copy(t, pos(IChar, t) + 1, length(t) - pos(IChar, t));
    GlGetEveryWord.Add(a);
  end;
  if Trim(t) <> '' then
    GlGetEveryWord.Add(t);
  Result := GlGetEveryWord;
end;

{-------------------------------------------------------------------------------
  过程名:    FindFileList
  作者:      马敏钊
  日期:      2006.01.16
  参数:      path:路径, filter:文件扩展名过滤, FileList:文件列表, ContainSubDir:是否包含子目录
  返回值:    无
  说明:     查找一个路径下的所有文件。
-------------------------------------------------------------------------------}

procedure FindFileList(Path, Filter: string; FileList: TStrings; ContainSubDir: Boolean);
var
  FSearchRec, DSearchRec: TSearchRec;
  FindResult: Cardinal;
begin
  FindResult := FindFirst(path + Filter, sysutils.faAnyFile, FSearchRec);
  while FindResult = 0 do begin
    FileList.Add(FSearchRec.Name);
    FindResult := FindNext(FSearchRec);
  end;
  sysutils.FindClose(FSearchRec);
  if ContainSubDir then begin
    FindResult := FindFirst(path + Filter, faDirectory, DSearchRec);
    while FindResult = 0 do begin
      if ((DSearchRec.Attr and faDirectory) = faDirectory)
        and (DSearchRec.Name <> '.') and (DSearchRec.Name <> '..') then
        FindFileList(Path, Filter, FileList, ContainSubDir);
      FindResult := FindNext(DSearchRec);
    end;
    sysutils.FindClose(DSearchRec);
  end;
end;

{修正目录名称 }

function FixPathName(Ipath: string): string;
var
  Ls: string;
begin
  Result := Ipath;
  Ls := Copy(Result, length(Result), 1);
  if ls <> '\' then
    Result := Result + '\';
end;

{获取文件夹为字符串}

procedure GetFileDirToStr(var InResp: string; Ipath: string);
var
  FSearchRec: TSearchRec;
  FindResult: Cardinal;
begin
  Ipath := FixPathName(Ipath);
  FindResult := FindFirst(Ipath + '*.*', sysutils.faAnyFile, FSearchRec);
  while FindResult = 0 do begin
    if (FSearchRec.Name = '.') or (FSearchRec.Name = '..') then begin
      FindResult := FindNext(FSearchRec);
      Continue;
    end;
    InResp := InResp + FSearchRec.Name;
    if (FSearchRec.Attr = 16) or (FSearchRec.Attr = 48) then begin
      InResp := InResp + '**';
      GetFileDirToStr(InResp, Ipath + FSearchRec.Name + '\');
    end
    else
      InResp := InResp + '*';
    FindResult := FindNext(FSearchRec);
  end;
  sysutils.FindClose(FSearchRec);
end;

procedure TrimList(Ilist: TStrings; IxmlFileName: string);
var
  i: Integer;
  ls: string;
begin
  for i := Ilist.Count - 1 downto 0 do begin // Iterate
    ls := Ilist.Strings[i];
    if (Trim(ls) = '') or (Trim(ls) = ' ') or (ExtractFileName(Trim(ls)) = IxmlFileName) or (ExtractFileName(Trim(ls)) = 'database.xml') then
      Ilist.Delete(i);
  end; // for
end;

procedure GetFileListToStr(var Resp: string; ISpit: string; iFilter, iPath:
  string; ContainSubDir: Boolean = True; INeedPath: boolean = True);
var
  FSearchRec, DSearchRec: TSearchRec;
  FindResult: Cardinal;
begin
  FindResult := FindFirst(iPath + iFilter, sysutils.faAnyFile, FSearchRec);

  while FindResult = 0 do begin
    if ((FSearchRec.Attr and faDirectory) = faDirectory) or (FSearchRec.Name = '.') or (FSearchRec.Name = '..') then begin
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
  sysutils.FindClose(FSearchRec);
  if ContainSubDir then begin
    FindResult := FindFirst(iPath + iFilter, faDirectory, DSearchRec);
    while FindResult = 0 do begin
      if ((DSearchRec.Attr and faDirectory) = faDirectory)
        and (DSearchRec.Name <> '.') and (DSearchRec.Name <> '..') then begin
        GetFileListToStr(Resp, ISpit, iFilter, iPath + DSearchRec.Name + '\', ContainSubDir);
      end;
      FindResult := FindNext(DSearchRec);
    end;
  end;
  sysutils.FindClose(DSearchRec);
end;


procedure GetFileList(Ilist: TStrings; iFilter, iPath: string; ContainSubDir:
  Boolean = True; INeedPath: boolean = True);
var
  FSearchRec, DSearchRec: TSearchRec;
  FindResult: Cardinal;
begin
  FindResult := FindFirst(iPath + iFilter, sysutils.faAnyFile, FSearchRec);
  while FindResult = 0 do begin
    if ((FSearchRec.Attr and faDirectory) = faDirectory) or (FSearchRec.Name = '.') or (FSearchRec.Name = '..') then begin
      FindResult := FindNext(FSearchRec);
      Continue;
    end;
    if INeedPath then
      Ilist.Add(iPath + FSearchRec.Name)
    else
      Ilist.Add(FSearchRec.Name);
    FindResult := FindNext(FSearchRec);
  end;
  sysutils.FindClose(FSearchRec);
  if ContainSubDir then begin
    FindResult := FindFirst(iPath + iFilter, faDirectory, DSearchRec);
    while FindResult = 0 do begin
      if ((DSearchRec.Attr and faDirectory) = faDirectory)
        and (DSearchRec.Name <> '.') and (DSearchRec.Name <> '..') then
        GetFileList(Ilist, iFilter, iPath + DSearchRec.Name + '\', ContainSubDir);
      FindResult := FindNext(DSearchRec);
    end;
    sysutils.FindClose(DSearchRec);
  end;
end;

procedure GetCurrDirAndSizeToStr(var InResp: string; Ipath: string);
var
  FSearchRec: TSearchRec;
  FindResult: Cardinal;
begin
  Ipath := FixPathName(Ipath);
  {先找文件夹}
  FindResult := FindFirst(Ipath + '*.*', sysutils.faAnyFile, FSearchRec);

  while FindResult = 0 do begin
    if (FSearchRec.Name = '.') or (FSearchRec.Name = '..') then begin
      FindResult := FindNext(FSearchRec);
      Continue;
    end;
    if (FSearchRec.Attr = 16) or (FSearchRec.Attr = 48) then begin
      InResp := InResp + FSearchRec.Name;
      InResp := InResp + ',' + IntToStr(GetDirectorySize(Ipath + FSearchRec.Name));
      InResp := InResp + '*';
    end;
    FindResult := FindNext(FSearchRec);
  end;
  sysutils.FindClose(FSearchRec);
  if InResp <> '' then
    InResp := InResp + '|';
  FindResult := FindFirst(Ipath + '*.*', sysutils.faAnyFile, FSearchRec);
  while FindResult = 0 do begin
    if (FSearchRec.Name = '.') or (FSearchRec.Name = '..') then begin
      FindResult := FindNext(FSearchRec);
      Continue;
    end;
    if (FSearchRec.Attr <> 16) and (FSearchRec.Attr <> 48) then begin
      InResp := InResp + FSearchRec.Name;
      InResp := InResp + ',' + IntToStr(FSearchRec.Size);
      InResp := InResp + '*';
    end;
    FindResult := FindNext(FSearchRec);
  end;
  sysutils.FindClose(FSearchRec);
end;

procedure GetCurrDirToStr(var InResp: string; Ipath: string);
var
  FSearchRec: TSearchRec;
  FindResult: Cardinal;
begin
  Ipath := FixPathName(Ipath);
  {先找文件夹}
  FindResult := FindFirst(Ipath + '*.*', sysutils.faAnyFile, FSearchRec);
  while FindResult = 0 do begin
    if (FSearchRec.Name = '.') or (FSearchRec.Name = '..') then begin
      FindResult := FindNext(FSearchRec);
      Continue;
    end;
    if (FSearchRec.Attr = 16) or (FSearchRec.Attr = 48) then begin
      InResp := InResp + FSearchRec.Name;
      InResp := InResp + '*';
    end;
    FindResult := FindNext(FSearchRec);
  end;
  if InResp <> '' then
    InResp := InResp + '|';

  sysutils.FindClose(FSearchRec);
  FindResult := FindFirst(Ipath + '*.*', sysutils.faAnyFile, FSearchRec);
  while FindResult = 0 do begin
    if (FSearchRec.Name = '.') or (FSearchRec.Name = '..') then begin
      FindResult := FindNext(FSearchRec);
      Continue;
    end;
    if (FSearchRec.Attr <> 16) and (FSearchRec.Attr <> 48) then begin
      InResp := InResp + FSearchRec.Name;
      InResp := InResp + '*';
    end;
    FindResult := FindNext(FSearchRec);
  end;
  sysutils.FindClose(FSearchRec);
end;



procedure DelDir(aDir: string; dDel: Boolean = true);
var
  i: Integer;
  aFsr: TSearchRec;
  dLst: TStrings;
  str: string;
begin
  if not DirectoryExists(aDir) then
    Exit;
  dLst := TStringList.Create;
  i := FindFirst(aDir + '*.*', faAnyFile, aFsr);
  while i = 0 do begin
    if (aFsr.Attr = faDirectory) then begin
      if (aFsr.Name <> '.') and (aFsr.Name <> '..') then
        dLst.Add(aDir + aFsr.Name + '\')
    end
    else try
      DeleteFile(PChar(aDir + aFsr.Name));
    except
    end;
    i := FindNext(aFsr);
  end;
  sysutils.FindClose(aFsr);
  for i := 0 to Pred(dLst.Count) do begin
    str := ExpandFileName(dLst[i]);
    if (Pos(aDir, str) = 1) and (Length(str) = Length(aDir)) then
      DelDir(dLst[i], True);
  end;
  dLst.Free;
  if dDel then
    RemoveDir(aDir);
end;

{$ENDIF}


{$IFDEF db}

function IsNullReturnStr(Ivar: Variant): string;
begin
  if VarIsNull(Ivar) then
    Result := ''
  else
    Result := Ivar;
end;

{-------------------------------------------------------------------------------
  过程名:    IsNullBackFloat
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Ivar: Variant
  返回值:    Double
  说明:
-------------------------------------------------------------------------------}

function IsNullReturnFloat(Ivar: Variant): Double;
begin
  if VarIsNull(Ivar) then
    Result := 0
  else
    Result := Ivar;
end;

{-------------------------------------------------------------------------------
  过程名:    IsNullBackint
  作者:      马敏钊
  日期:      2006.01.06
  参数:      Ivar: Variant
  返回值:    Integer
  说明:
-------------------------------------------------------------------------------}

function IsNullReturnint(Ivar: Variant): Integer;
begin
  if VarIsNull(Ivar) then
    Result := 0
  else
    Result := Ivar;
end;



{ TBaseDbMrg }

constructor TDBMrg.Create(IConStr: string; iTimeOut: integer = 15;
  ICreateBuffCount: Integer = 5);
var
  I: Integer;
begin
  FautoFree := true;
  FName := 0;
  FTotCount := 500;
  FAutoFreeConn := True;
  FConn := TADOConnection.Create(nil);
  FConn.ConnectionTimeout := iTimeOut;
  FConn.LoginPrompt := False;
  FPool := TStringList.Create;
  FConn.ConnectionString := IConStr;
  try
    FConn.Connected := True;
  except
  end;

  
  for I := 0 to ICreateBuffCount do
    GetAnQuery();
  FThread_Check := TCheckThread.Create(False, Self);
end;

constructor TDBMrg.Create(IConn: TADOConnection; ICreateBuffCount: Integer = 5);
var
  I: Integer;
begin
  FautoFree := true;
  FName := 0;
  FTotCount := 500;
  FConn := IConn;
  if IConn <> nil then
    FConn.LoginPrompt := False;
  FAutoFreeConn := False;
  FPool := TStringList.Create;
  for I := 0 to ICreateBuffCount - 1 do
    GetAnQuery();
  FThread_Check := TCheckThread.Create(False, Self);
end;

destructor TDBMrg.Destroy;
var
  I: Integer;
begin
  FThread_Check.Terminate;
  if FAutoFreeConn then
    FConn.Free;
  for I := 0 to FPool.Count - 1 do
    FPool.Objects[i].Free;
  FPool.Free;
  inherited;
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.AddAnOutAdo
  作者:      马敏钊
  日期:      2006.01.11
  参数:      Iado: TADOQuery
  返回值:    无
  说明:      加入一个由外部创建的ADO 帮它管理生命周期和重用
-------------------------------------------------------------------------------}

procedure TDBMrg.AddAnOutAdo(Iado: TADOQuery);
begin
  Iado.Close;
  Iado.Connection := FConn;
  if PoolCount + 1 > FTotCount then
    raise Exception.Create('已经达到最大限度不允许在添加新的QUERY');
  Iado.Tag := FPool.AddObject(CDb_State_NoneUsed, Iado);
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.BackToPool
  作者:      马敏钊
  日期:      2006.01.11
  参数:      Iado: TADOQuery
  返回值:    无
  说明:     释放ADO使用权以便其它人员使用
-------------------------------------------------------------------------------}

procedure TDBMrg.BackToPool(IName: string);
var
  I: Integer;
begin
  for I := 0 to FPool.Count - 1 do begin // Iterate
    if TADOQuery(FPool.Objects[i]).Name = IName then begin
      FPool.Strings[i] := CDb_State_NoneUsed;
    end;
  end; // for
end;

procedure TDBMrg.BackToPool(Iado: TADOQuery);
begin
  if Iado = nil then
    Exit;
  try
    FPool.Strings[Iado.Tag] := CDb_State_NoneUsed;
  except
    raise Exception.Create('回归Adoquery的时候异常 Tag属性被改变');
  end;
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.DeleteSomeThing
  作者:      马敏钊
  日期:      2006.01.11
  参数:      ItabName, IFieldName: string; Ivalue: Variant
  返回值:    无
  说明:     根据字段名和值删除表内容
-------------------------------------------------------------------------------}

procedure TDBMrg.DeleteSomeThing(ItabName, IFieldName: string;
  Ivalue: Variant);
begin
  with GetAnQuery(CDb_State_CanUsed) do begin
    try
      Close;
      SQL.Text := Format('Delete from %s where %s=:VarIant', [ItabName, IFieldName]);
      Parameters.ParamValues['VarIant'] := Ivalue;
      ExecSQL;
    finally
      Close;
    end;
  end; // with
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.ExecAnSql
  作者:      马敏钊
  日期:      2006.01.11
  参数:      Isql: string
  返回值:    Integer
  说明:      执行一个语句
-------------------------------------------------------------------------------}

function TDBMrg.ExecAnSql(Isql: string): Integer;
begin
  with GetAnQuery do begin
    try
      Close;
      SQL.Clear;
      SQL.Add(Isql);
      Result := ExecSQL;
    finally // wrap up
      Close;
    end; // try/finally
  end; // with
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.GetAnQuery
  作者:      马敏钊
  日期:      2006.01.11
  参数:      Iname: string
  返回值:    TADOQuery
  说明:获取一个ADO对象 可以指定名字 如果没有名字 系统自己返回一合适的对象
-------------------------------------------------------------------------------}

function TDBMrg.GetAnQuery(Iname: string): TADOQuery;
var
  I: Integer;
begin
  Result := nil;
  if PoolCount > FTotCount then begin
    raise Exception.Create('AdoQuery已经达到最大限制数量！缓冲池不允许再添加新对象' + #13
      + '请检查是否由于忘记回归ADOQUERY所导致');
    Exit;
  end;
  if Iname <> '' then begin
    for I := 0 to FPool.Count - 1 do
      if TADOQuery(FPool.Objects[i]).Name = 'MyPool' + Iname then begin
        Result := TADOQuery(FPool.Objects[i]);
        Exit;
      end;
    Result := TADOQuery.Create(nil);
    Result.Connection := FConn;
    Result.Name := 'MyPool' + Iname;
    Result.Tag := FPool.AddObject(IntToStr(CDb_State_EverUsed), Result);
  end;
end;


function TDBMrg.GetAnQuery(IuserTime: integer = 1; Iname: string = ''):
  TADOQuery;
var
  I: Integer;
  LState: string;
begin
  if IuserTime = CDb_State_CanUsed then
    LState := ''
  else
    LState := IntToStr(IuserTime);
  if PoolCount > FTotCount then begin
    raise Exception.Create('AdoQuery已经达到最大限制数量！缓冲池不允许再添加新对象' + #13
      + '请检查是否由于忘记回归ADOQUERY所导致');
    Exit;
  end;
  if Iname <> '' then begin
    for I := 0 to FPool.Count - 1 do
      if TADOQuery(FPool.Objects[i]).Name = 'MyPool' + Iname then begin
        Result := TADOQuery(FPool.Objects[i]);
        FPool.Strings[i] := LState;
        Exit;
      end;
    Result := TADOQuery.Create(nil);
    Result.Connection := FConn;
    Result.Name := 'MyPool' + Iname;
    Result.Tag := FPool.AddObject(IntToStr(CDb_State_EverUsed), Result);
  end
  else begin
    for I := 0 to FPool.Count - 1 do begin // Iterate
      if (FPool.Strings[i] = CDb_State_NoneUsed) then begin
        Result := TADOQuery(FPool.Objects[i]);
        FPool.Strings[i] := LState;
        Exit;
      end;
    end; // for
    Result := TADOQuery.Create(nil);
    Result.Connection := FConn;
    Inc(FName);
    Result.Name := 'MyPool' + IntToStr(FName);
    Result.Tag := FPool.AddObject(LState, Result);
  end;
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.GetConn
  作者:      马敏钊
  日期:      2006.01.11
  参数:      无
  返回值:    TADOConnection
  说明:      获取连接
-------------------------------------------------------------------------------}

function TDBMrg.GetConn: TADOConnection;
begin
  Result := FConn;
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.GetCount
  作者:      马敏钊
  日期:      2006.01.11
  参数:      ItabName, IFieldName: string; Ivalue: variant
  返回值:    Integer
  说明:      获取符合记录的个数
-------------------------------------------------------------------------------}

function TDBMrg.GetCount(ItabName, IFieldName: string; Ivalue: variant):
  Cardinal;
begin
  with GetAnQuery do begin
    Close;
    SQL.Text := Format('Select Count(%s) as MyCount from %s where %s=:variant',
      [IFieldName, ItabName, IFieldName]);
    Parameters.ParamValues['VarIant'] := Ivalue;
    try
      Open;
      Result := Fieldbyname('MyCount').AsInteger;
    except
      Result := 0;
    end;
  end; // with
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.GetId
  作者:      马敏钊
  日期:      2006.01.11
  参数:      ItabName, IFieldName: string
  返回值:    Integer
  说明:      获取自动增长的ID号码
-------------------------------------------------------------------------------}

function TDBMrg.GetId(ItabName, IFieldName: string): Integer;
begin
  Result := 0;
  with GetAnQuery do begin
    Close;
    SQL.Text := Format('Select Max(%s) as myMax  from  %s', [IFieldName, ItabName]);
    Open;
    if FieldByName('MyMax').AsInteger > 0 then
      Result := FieldByName('MyMax').AsInteger;
  end; // with
  inc(Result);
end;

function TDBMrg.GetMaxID(ItabName, IFieldName: string): Integer;
begin
  Result := 0;
  with GetAnQuery do begin
    Close;
    SQL.Text := Format('Select Max(%s) as myMax  from  %s', [IFieldName, ItabName]);
    Open;
    if FieldByName('MyMax').AsInteger > 0 then
      Result := FieldByName('MyMax').AsInteger;
  end; // with
end;


{-------------------------------------------------------------------------------
  过程名:    TDBMrg.GetSomeThing
  作者:      马敏钊
  日期:      2006.01.11
  参数:      ItabName, IGetField, IWHereField: string; Ivalue: Variant
  返回值:    variant
  说明:      读取某个字段的值
-------------------------------------------------------------------------------}

function TDBMrg.GetSomeThing(ItabName, IGetField, IWHereField: string;
  Ivalue: Variant): variant;
begin
  with GetAnQuery(CDb_State_CanUsed) do begin
    try
      Close;
      SQL.Text := Format('Select %s as MyGetField from %s where %s=:VarIant', [IGetField, ItabName, IWHereField]);
      Parameters.ParamValues['VarIant'] := Ivalue;
      Open;
      if RecordCount > 0 then
        Result := FieldValues['MyGetField']
      else
        Result := Unassigned;
    finally
      Close;
    end;
  end; // with
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.IsExitThis
  作者:      马敏钊
  日期:      2006.01.11
  参数:      ItabName, IFieldName: string; Ivalue: Variant
  返回值:    boolean
  说明:     判断是否已经存在这个值
-------------------------------------------------------------------------------}

function TDBMrg.IsExitThis(ItabName, IFieldName: string;
  Ivalue: Variant): boolean;
begin
  Result := False;
  with GetAnQuery(CDb_State_CanUsed) do begin
    try
      Close;
      SQL.Text := Format('Select Count(%s) as MyCount from %s where %s=:variant',
        [IFieldName, ItabName, IFieldName]);
      Parameters.ParamValues['VarIant'] := Ivalue;
      Open;
      if Fieldbyname('MyCount').AsInteger > 0 then
        Result := True;
    finally
      Close;
    end;
  end; // with
end;



{-------------------------------------------------------------------------------
  过程名:    TDBMrg.OpenDataset
  作者:      马敏钊
  日期:      2006.01.11
  参数:      ISql: string
  返回值:    TADOQuery
  说明:      执行一个查询语句 记得使用完归还（Close）
-------------------------------------------------------------------------------}

function TDBMrg.OpenDataset(ISql: string): TADOQuery;
begin
  Result := GetAnQuery;
  with Result do begin
    Close;
    SQL.Clear;
    SQL.Add(ISql);
    Open;
  end; // with
end;


{-------------------------------------------------------------------------------
  过程名:    TDBMrg.OpenDataset
  作者:      马敏钊
  日期:      2006.01.11
  参数:      IadoName, ISql: string
  返回值:    TADOQuery
  说明:      用指定的ＡＤＯ执行
-------------------------------------------------------------------------------}

function TDBMrg.OpenDataset(IadoName, ISql: string): TADOQuery;
begin
  Result := GetAnQuery(IadoName);
  with Result do begin
    Close;
    SQL.Clear;
    SQL.Add(ISql);
    Open;
  end; // with
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.PoolCount
  作者:      马敏钊
  日期:      2006.01.11
  参数:      无
  返回值:    Integer
  说明:      查询总共有多少个ADOquery
-------------------------------------------------------------------------------}

function TDBMrg.PoolCount: Integer;
begin
  Result := FPool.Count;
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.PoolFreeCount
  作者:      马敏钊
  日期:      2006.01.11
  参数:      无
  返回值:    Integer
  说明:      空闲着的ADO数量
-------------------------------------------------------------------------------}

function TDBMrg.PoolFreeCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FPool.Count - 1 do
    if TADOQuery(FPool.Objects[i]).IsEmpty then
      Inc(Result);
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.FindDataInDataSet
  作者:      马敏钊
  日期:      2006.01.11
  参数:      IData: TDataSet; IFieldName, IFieldValue: string; Iopt: TLocateOptions
  返回值:    boolean
  说明:      在数据集内定位记录
-------------------------------------------------------------------------------}

function TDBMrg.FindDataInDataSet(IData: TDataSet; IFieldName,
  IFieldValue: string; Iopt: TLocateOptions): boolean;
var
  i, BeginNO: Integer;
  LfieldValue, LThenValue: string;
begin
  Result := false;
  with TADOQuery(IData) do begin
    IData.DisableControls;
    try
      BeginNO := IData.RecNo;
      for i := IData.RecNo to IData.RecordCount - 1 do begin // Iterate
        LfieldValue := LowerCase(Idata.FieldByName(IFieldName).AsString);
        LThenValue := LowerCase(IFieldValue);
        if loPartialKey in Iopt then begin
          if Pos(LThenValue, LfieldValue) > 0 then begin
            Result := True;
            Break;
          end;
        end
        else if CompareText(LThenValue, LfieldValue) = 0 then begin
          Result := True;
          Break;
        end;
        IData.Next;
      end; // for
      if not Result then
        Idata.RecNo := BeginNO;
    finally
      Idata.EnableControls;
    end;
  end; // with
end;

class function TDBMrg.GetAccessConnStr(IDataSource: string; Ipsd: string = ''):
  string;
begin
  if Ipsd <> '' then
    Result := Format('Provider=Microsoft.Jet.OLEDB.4.0;Data Source=%s;Persist Security' +
      ' Info=True;Jet OLEDB:Database Password=%s;', [IDataSource, Ipsd])
  else
    Result := Format('Provider=Microsoft.Jet.OLEDB.4.0;Password="";Data Source=%s;Mode=Share Deny None;' +
      ' Extended Properties = ""', [IDataSource]);
end;

{$ENDIF}

class function TDBMrg.GetExcelConnStr(IFileName: string): string;
begin
  Result := Format('Provider = Microsoft.Jet.OLEDB.4.0;Data Source ' +
    '= %s; Extended Properties = EXCEL 8.0; Persist Security Info = False;', [IFileName]);
end;

class function TDBMrg.GetMsSQLConnStr(IDataSource, IAcc, Ipsd, IDataBase:
  string): string;
begin
  Result := Format('Provider=SQLOLEDB.1;Password=%s;Persist Security Info=' +
    'True;User ID=%s;Initial Catalog=%s;Data Source=%s', [Ipsd, IAcc,
    IDataBase, IDataSource]);
end;

class function TDBMrg.GetOracleConnStr(IDataSource, IAcc, Ipsd: string): string;
begin
  Result := Format('Provider=OraOLEDB.Oracle.1;Password=%s;Persist Security Info=True;' +
    'User ID=%s;Data Source=%s', [Ipsd, IAcc, IDataSource]);
end;


class function TDBMrg.GetDBFConnStr(IDBPath: string): string;
begin
  Result := Format('Provider=MSDASQL.1;Persist Security Info=False; Extended ' +
    'Properties="Driver={Microsoft Visual FoxPro Driver};UID=;SourceDB=%s;' +
    'SourceType=DBF;Exclusive=No;BackgroundFetch=Yes;Collate=PINYIN;Null=Yes;Deleted=no;"',
    [IDBPath]);
end;

class function TDBMrg.GetTextConnStr(IDBPath: string): string;
begin
  Result := Format('Provider=Microsoft.Jet.OLEDB.4.0;User ID=Admin;Data Source=%s' +
    ';Extended Properties=text', [IDBPath]);
end;

function TDBMrg.GetCount(ItabName: string): Cardinal;
begin
  with GetAnQuery(CDb_State_CanUsed) do begin
    Close;
    SQL.Text := Format('Select Count(*) as MyCount from %s',
      [ItabName]);
    Open;
    Result := Fieldbyname('MyCount').AsInteger;
  end; // with
end;

{-------------------------------------------------------------------------------
  过程名:    TDBMrg.Ready
  作者:      马敏钊
  日期:      2006.02.21
  参数:      ItabName:string;Iado:TADOQuery
  返回值:    无
  说明:      为操作表预备一个ADO
-------------------------------------------------------------------------------}

function TDBMrg.Ready(ItabName: string; Iado: TADOQuery): TADOQuery;
begin
  with Iado do begin
    Close;
    SQL.Text := Format('Select * from %s where 1=2', [ItabName]);
    Open;
  end; // with
  Result := Iado;
end;

function TDBMrg.Ready(ItabName: string; IQueryRight: integer = 1): TADOQuery;
begin
  Result := GetAnQuery(IQueryRight);
  with TADOQuery(Result) do begin
    Close;
    SQL.Text := Format('Select * from %s where 1=2', [ItabName]);
    Open;
  end; // with
end;


function TDBMrg.OpenDataset(IQueryRight: integer; ISql: string; const Args: array
  of const): TADOQuery;
begin
  ISql := Format(Isql, Args);
  Result := GetAnQuery(IQueryRight);
  with Result do begin
    Close;
    SQL.Clear;
    SQL.Add(ISql);
    Open;
  end; // with
end;

function TDBMrg.ExecAnSql(Isql: string;
  const Args: array of const): Integer;
begin
  Isql := Format(Isql, Args);
  with GetAnQuery do begin
    try
      Close;
      SQL.Clear;
      SQL.Add(Isql);
      Result := ExecSQL;
    finally // wrap up
      Close;
    end; // try/finally
  end; // with
end;

{ TCheckThread }

constructor TCheckThread.Create(IsStop: boolean; IDbMrg: TDbmrg);
begin
  inherited Create(IsStop);
  CheckTime := GetTickCount;
  DbMrg := IDbMrg;
  FreeOnTerminate := True;
end;

procedure TCheckThread.Execute;
var
  I: Integer;
begin
  while not Terminated do begin
    if ModuleIsLib then begin
      sleep(100);
      Continue;
    end;

    if GetTickCount - CheckTime < 1000 then
      Sleep(100)
    else begin
      CheckTime := GetTickCount;
      with DbMrg.FPool do begin
        for I := DbMrg.FPool.Count - 1 downto 0 do begin // Iterate
          {如果是可用的就跳过}
          if Strings[i] = CDb_State_NoneUsed then
            Continue;
          if StrToInt(Strings[i]) = CDb_State_EverUsed then
            Continue;
          {否则倒记时就自动下降1秒}
          try
            {如果是0就标示为可用}
            if Strings[i] = '0' then
              Strings[i] := CDb_State_NoneUsed
            else
              Strings[i] := Format('%d', [StrToInt(Strings[i]) - 1]);
          except
            Strings[i] := CDb_State_NoneUsed;
          end;
        end; // for
      end; // with
    end;
  end; // while
end;


function TDBMrg.OpenDataset(ISql: string;
  const Args: array of const): TADOQuery;
begin
  ISql := Format(Isql, Args);
  Result := GetAnQuery;
  with Result do begin
    Close;
    SQL.Clear;
    SQL.Add(ISql);
    Open;
  end; // with
end;


function OpenDataset(Iado: TADOQuery; ISql: string):
  TADOQuery; overload;
begin
  Result := Iado;
  with Result do begin
    Close;
    SQL.Text := ISql;
    Open;
  end; // with
end;


function TDBMrg.OpenDataset(Iado: TADOQuery; ISql: string; const Args: array of
  const): TADOQuery;
begin
  ISql := Format(Isql, Args);
  Result := Iado;
  with Result do begin
    Close;
    SQL.Clear;
    SQL.Add(ISql);
    Open;
  end; // with
end;

function TDBMrg.ExecAnSql(IQueryRight: integer; Isql: string;
  const Args: array of const): Integer;
begin
  Isql := Format(Isql, Args);
  with GetAnQuery(IQueryRight) do begin
    try
      Close;
      SQL.Clear;
      SQL.Add(Isql);
      Result := ExecSQL;
    finally // wrap up
      Close;
    end; // try/finally
  end; // with
end;

function TDBMrg.ExecAnSql(Iado: TADoquery; Isql: string; const Args: array of const): Integer;
begin
  Isql := Format(Isql, Args);
  with Iado do begin
    try
      Close;
      SQL.Clear;
      SQL.Add(Isql);
      Result := ExecSQL;
    finally // wrap up
      Close;
    end; // try/finally
  end; // with
end;


class function TDBMrg.GetMySqlConnStr(IDataSource, IDbName, IAcc, Ipsd: string):
  string;
begin
  Result := Format('DRIVER={MySQL ODBC 3.51 Driver};SERVER=%s;DATABASE=%s;UID=%s;PASSWORD=%s;OPTION=3',
    [IDataSource, IDbName, IAcc, Ipsd]);
end;

function TDBMrg.OpenTable(ItabName: string; Iado: TADOQuery): TADOQuery;
begin
  with Iado do begin
    Close;
    SQL.Text := Format('Select * from %s ', [ItabName]);
    Open;
  end; // with
  Result := Iado;
end;

function TDBMrg.CheckModState(IAdo: TADOQuery): boolean;
begin
  Result := IAdo.State in [dsEdit, dsinsert];
end;

function TDBMrg.SafePost(Iado: TADOQuery): boolean;
begin
  Result := CheckModState(Iado);
  if Result then
    Iado.Post;
end;

function TDBMrg.OpenTable(ItabName: string; IQueryRight: integer = 1): TADOQuery;
begin
  Result := GetAnQuery(IQueryRight);
  with TADOQuery(Result) do begin
    Close;
    SQL.Text := Format('Select * from %s ', [ItabName]);
    Open;
  end; // with
end;

{ TDeBug }
{$IFDEF Debug}

constructor TDeBug.Create;
begin
  AllocConsole;
  m_hConsole := CreateConsoleScreenBuffer(GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, CONSOLE_TEXTMODE_BUFFER, nil);
  SetConsoleActiveScreenBuffer(m_hConsole);
  SetConsoleMode(m_hConsole, ENABLE_LINE_INPUT or ENABLE_ECHO_INPUT);
  SetConsoleTitle('小马的清凉级Debug窗体');
end;

destructor TDeBug.Destroy;
begin
  FreeConsole;
  inherited;
end;

procedure TDeBug.read(var str: string);
var
  n: DWORD;
  buf: array[0..256] of char;
begin
  n := 0;
  ReadConsole(m_hConsole, @buf[0], 256, n, nil);
  SetString(str, PChar(@buf[0]), Integer(n));
end;


procedure TDeBug.ReadAnyKey;
var
  s: string;
begin
  self.write('按任意键继续....');
  Self.read(s);
end;

procedure TDeBug.write(str: string);
var
  n: DWORD;
begin
  WriteConsole(m_hConsole,
    PChar(GetFormatTime + '-> ' + str + #13#10),
    Length(GetFormatTime + '-> ' + str) + 2,
    n,
    nil);
end;

function DeBug(ICon: Variant): Variant;
var
  LStr: string;
begin
  if not assigned(_Gob_Debug) then
    _Gob_Debug := TDeBug.Create;
  if ShowDeBug then begin
    LStr := ICon;
    _Gob_Debug.write(LStr);
  end;
  Result := LStr;
end;

procedure DeBug(ICon: string; const Args: array of const);
begin
  DeBug(Format(ICon, Args));
end;
{$ENDIF}

class function TDBMrg.CreateAccessFile(IFileName: string): string;
var
  CreateAccess: OleVariant;
begin
  CreateAccess := CreateOleObject('ADOX.Catalog');
  CreateAccess.Create('Provider=Microsoft.Jet.OLEDB.4.0;Data Source=' + IFilename);
end;

function TDBMrg.GetIsConnectioned: Boolean;
begin
  if Assigned(FConn) then
  begin
    Result := FConn.Connected;
  end
  else
  begin
    Result := False;
  end;
end;


function TDBMrg.OpenDataset(Iado: TADOQuery; ISql: string): TADOQuery;
begin
  Result := Iado;
  with Result do begin
    Close;
    SQL.Clear;
    SQL.Add(ISql);
    Open;
  end; // with
end;

initialization

finalization
{$IFDEF Db}
//------------------------------------------------------------------------------
// 如果使用了就自动释放
//------------------------------------------------------------------------------
  if assigned(Gob_DBMrg) then begin
    try
      if Gob_DBMrg.FautoFree then
        Gob_DBMrg.free;
    except
    end;
  end;
{$ENDIF}
{$IFDEF Debug}
  if assigned(_Gob_Debug) then
    _Gob_Debug.Free;
{$ENDIF}
  if assigned(GlGetEveryWord) then
    GlGetEveryWord.Free;
end.

