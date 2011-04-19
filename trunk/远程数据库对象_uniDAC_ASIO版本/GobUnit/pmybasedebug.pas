unit PMyBaseDebug;
{
单元名：PMyBaseDebug
创建者：马敏钊
创建日期：20050407
类：TBaseDebug
功能描述：
   提供基本的Debug方法 和日志显示记录的功能
   本单元自己维护一个全局变量Gob_Debug
20050412
  添加了TBaseDebug 的自动注册热键的能力
  将公开的 方法 InitDebugSystem(ImainForm: TForm)改为私有
  添加了窗体透明的拖动条
  添加了一个方法
  Function AddLogShower(IStrings:TStringList): Variant; Overload;
  将 FShower: TMemo;改为私有
  将 AutoSaveLog: boolean; 改名为 WantAutoSaveLog: boolean;
20050518
  添加了显示TDATASET的函数
  添加根据表名生成插入和更新SQL语句的函数
20051128
  添加一个累加记数的方法
  去掉了没多少用的接口ISHOWER
//------------------------------------------------------------------------------
// 增加一个编译指令 undebug 可以方便到去功能化  马敏钊 2009-02-02 16:55:07
//------------------------------------------------------------------------------
}

interface
uses Windows, SysUtils, Classes, Messages, Controls, Forms, StdCtrls, ExtCtrls,
  ComCtrls, DB, ADODB;
const
   {分割符号}
  CSplitStr = '===============================================================';
  ClogFileName = '.log';
type
  TDebugLogFile = class
  private
    FFileParth: string; //路径
    FText: Text;
    FIsCreateToNew: boolean; //是否是每次启动程序都创建新的记录文件 否则就是当天只会有1个文件
  public
    {带入日志文件存放的目录位置}
    constructor Create(Iparth: string);
    destructor Destroy; override;
    {写入内容即可自动记录}
    procedure AddLog(Icon: string);
    property IsCreateToNew: boolean read FIsCreateToNew write FIsCreateToNew;
  end;
  {
   显示接口
  }
  TEventShowed = procedure(ILogCon: string) of object;
  TDebuglog = class
  private
    FShower: TComponent; //容器
    FClearTager: Word; //显示多少条后清空一下
    FIsAddTime: boolean; //是否在每条显示前加时间
    FAfterShowed: TEventShowed; //显示后触发的事件 可以用来做日志
    FIsNeedSplt: boolean; //是否需要分割字符
    FSplitChar: string; //分割的字符
    FLog: TDebugLogFile;
  protected
    function DoAdd(Icon: string): Integer; virtual;
    function AddShow(ICon: string): Integer;
  published
    property AfterShowed: TEventShowed read FAfterShowed write FAfterShowed;
  public
    {如果带入记录文件存放路径的话就自动生成记录类}
    constructor Create(IShower: TComponent; IlogFIleDir: string = '');
    destructor Destroy; override;
    property ClearTager: Word read FClearTager write FClearTager;
    property IsAddTime: boolean read FIsAddTime write FIsAddTime;
    property IsNeedSplitChar: boolean read FIsNeedSplt write FIsNeedSplt;
    property SplitChar: string read FSplitChar write FSplitChar;
  end;

type
  //生成语句类型
  SCreateSqlKind = (SSk_insert, SSk_update);
  //显示类型
  SShowKind = (Sshowkind_None, Sshowkind_FieldHead, Sshowkind_Number, Sshowkind_All, Sshowkind_CurrNo);
  TBaseDebug = class
  private
    FStartTime,
      FEndTime: Cardinal;

    FLoger: TDebugLog;
    FtrackBar: TTrackBar;
    FGroupBox: TGroupBox;
    FShower: TMemo;
    F_gob_openFrom, F_gob_AutoLog: Integer;
    {加载热键系统 Alt+o 是打开debug窗体 +p是打开/关闭自动记录功能}
    procedure InitDebugSystem;
    {释放系统热键}
    procedure UnInitDebugSystem;
    {拖动滚动条}
    procedure TrackOnTrack(Iobj: TObject);
    {Hotkey}
    procedure hotykey(var Msg: TMsg; var Handled: Boolean);
    {根据TDATASET生成插入语句}
    function CreateInsertSql(IdataSet: TFields; ItabName: string): string;
    {根据TdataSet生成查询语句}
    function CreateUpdateSql(IdataSet: TFields; ItabName: string): string;
  public
    FBugShowForm: TForm;
    {是否在程序结束的时候自动保存除错信息 默认是False}
    WantAutoSaveLog: boolean;

    {开始记录时间}
    procedure StartLogTime;
    {停止记录并且返回时间差单位毫秒}
    function EndLogTIme: Cardinal;
    {弹出变量的值}
    function ShowVar(Ivar: Variant): Variant;
    {添加到Log容器}
    function AddLogShower(Ivar: Variant): Variant; overload;
    function AddLogShower(IStr: string; const Args: array of const): Variant; overload;
    function AddLogShower(IDesc: string; Ivar: Variant): Variant; overload;
    function AddLogShower(IStrings: TStrings): TStrings; overload;
    function AddLogShower(IRect: TRect): TRect; overload;
    function AddLogShower(IDateset: TDataSet; IshowKind: SShowKind = Sshowkind_None; IshowNumber: Integer = 0): TDataSet; overload;
    function AddLogShower(IBuff: Pointer; ILen: integer): string; overload;

    {根据表名自动生成SQL}
    function GetSqlWithTableName(IQuery: TADOQuery; ItabName: string; Issk: SCreateSqlKind): string;
    {显示Debug窗体}
    procedure ShowDebugform;
    {将所有记录的东东保存成日志}
    procedure SaveLog(IfileName: string = 'LogFile.log');
    constructor Create;
    destructor Destroy; override;
  end;

var
  Gob_Debug: TBaseDebug;
implementation

{ TDebugLog }

function TDebugLog.AddShow(ICon: string): Integer;
begin
  if FIsAddTime then
    ICon := DateTimeToStr(Now) + ' ' + Icon;
  if FIsNeedSplt then
    ICon := ICon + #13#10 + FSplitChar;
  Result := DoAdd(ICon);
  if assigned(FLog) then
    FLog.AddLog(ICon);
  if Assigned(FAfterShowed) then
    FAfterShowed(ICon);
end;

constructor TDebugLog.Create(IShower: TComponent; IlogFIleDir: string = '');
begin
  FClearTager := 3000;
  IsAddTime := True;
  FIsNeedSplt := True;
  FSplitChar := CSplitStr;
  FShower := IShower;
  if IlogFIleDir <> '' then
    FLog := TDebugLogFile.Create(IlogFIleDir);
end;

destructor TDebugLog.Destroy;
begin
  if assigned(FLog) then
    FLog.Free;
  inherited;
end;

function TDebugLog.DoAdd(Icon: string): Integer;
begin
  if (FShower is TMemo) then begin
    Result := TMemo(FShower).Lines.Add(Icon);
    if Result >= FClearTager then
      TMemo(FShower).Clear
  end
  else if (FShower is TListBox) then begin
    Result := TListBox(FShower).Items.Add(Icon);
    if Result >= FClearTager then
      TListBox(FShower).Clear
  end
  else
    raise Exception.Create('默认容器错误:' + FShower.ClassName);
end;

{ TDebugLogFile }

procedure TDebugLogFile.AddLog(Icon: string);
begin
  try
    Append(FText);
    Writeln(FText, icon);
  except
    IOResult;
  end;
end;

constructor TDebugLogFile.Create(Iparth: string);
var
  Ltep: string;
begin
  FIsCreateToNew := True;
  FFileParth := Iparth;
  if not DirectoryExists(FFileParth) then
    if not CreateDir(FFileParth) then begin
      raise Exception.Create('错误的路径，日志类对象不能被创建');
      exit;
    end;
  Ltep := FormatDateTime('yyyymmddhhnnss', Now);
  FileClose(FileCreate(FFileParth + ltep + ClogFileName));
  AssignFile(FText, FFileParth + ltep + ClogFileName);
end;

destructor TDebugLogFile.Destroy;
begin
  try
    CloseFile(FText);
  except
  end;
  inherited;
end;

{ TBaseDebug }

function TBaseDebug.AddLogShower(Ivar: Variant): Variant;
begin
  Result := Ivar;
{$IFNDEF undebug}
  try
    FLoger.AddShow(Ivar);
  except
    on e: Exception do
      AddLogShower(e.Message);
  end;
{$ENDIF}
end;

function TBaseDebug.AddLogShower(IDesc: string; Ivar: Variant): Variant;
var
  Ltep: string;
begin
  Ltep := Ivar;
  Result := Ivar;
{$IFNDEF undebug}
  try
    FLoger.AddShow('描述<' + IDesc + '> <值: ' + Ltep + '>');
  except
    on e: Exception do
      AddLogShower(e.Message);
  end;
{$ENDIF}
end;

constructor TBaseDebug.Create;
begin
{$IFNDEF undebug}
  FBugShowForm := TForm.Create(FBugShowForm);
  FBugShowForm.FormStyle := fsStayOnTop;
  FBugShowForm.Caption := '小马的Debug模块';
  FBugShowForm.Visible := False;
  FBugShowForm.Position := poScreenCenter;
  FBugShowForm.AlphaBlend := false;
  FBugShowForm.Width := 430;
  FBugShowForm.Height := 300;
  FShower := TMemo.Create(FBugShowForm);
  FShower.Parent := FBugShowForm;
  FShower.Align := alClient;
  FShower.ScrollBars := ssVertical;
  FShower.WordWrap := True;
  FLoger := TDebugLog.Create(FShower);
  FLoger.IsNeedSplitChar := False;
  FLoger.ClearTager := 10000;
  FGroupBox := TGroupBox.Create(FBugShowForm);
  FGroupBox.Parent := FBugShowForm;
  FGroupBox.Align := alBottom;
  FGroupBox.Height := 40;
  FGroupBox.Caption := '透明度';
  FtrackBar := TTrackBar.Create(nil);
  FtrackBar.Min := 50;
  FtrackBar.Max := 255;
  FtrackBar.Parent := FGroupBox;
  FtrackBar.Position := 200;
  FtrackBar.Align := alClient;
  FtrackBar.TickStyle := tsNone;
  FtrackBar.OnChange := TrackOnTrack;
  FtrackBar.OnChange(FtrackBar);
  WantAutoSaveLog := False;
  InitDebugSystem;
  AddLogShower(Format('程序启动...', []));
  AddLogShower(Format('程序标题(%s)', [Application.Title]));
  AddLogShower(Format('程序名(%s)', [Application.ExeName]));
{$ENDIF}
end;

destructor TBaseDebug.Destroy;
begin
{$IFNDEF undebug}
  AddLogShower(Format('程序结束时间(%s)', [DateTimeToStr(now)]));
  UnInitDebugSystem;
  if WantAutoSaveLog then
    SaveLog();
  FtrackBar.Free;
  FGroupBox.Free;
  FLoger.Free;
  FShower.Free;
  FBugShowForm.Free;
{$ENDIF}
  inherited;
end;

function TBaseDebug.EndLogTIme: Cardinal;
begin
  FEndTime := GetTickCount;
  Result := FEndTime - FStartTime;
end;

procedure TBaseDebug.InitDebugSystem;
begin
  F_gob_openFrom := GlobalAddAtom('Hot_OpenFrom');
  F_gob_AutoLog := GlobalAddAtom('Hot_AutoLog');
  RegisterHotKey(Application.Handle, F_gob_openFrom, MOD_ALT, ord('O'));
  RegisterHotKey(Application.Handle, F_gob_AutoLog, MOD_ALT, ord('P'));
  Application.OnMessage := hotykey;
end;

procedure TBaseDebug.SaveLog(IfileName: string);
begin
{$IFNDEF undebug}
  try
    CreateDir(ExtractFilePath(Application.ExeName) + 'DebugLog\');
    FShower.Lines.SaveToFile(ExtractFilePath(Application.ExeName) + 'DebugLog\' + Format('%s', [FormatDateTime('yyyymmddhhnnss', now) + IfileName]));
  except
    raise Exception.Create('保存Debug日志失败');
  end;
{$ENDIF}
end;

procedure TBaseDebug.ShowDebugform;
begin
{$IFNDEF undebug}
  FBugShowForm.Show;
  Application.ProcessMessages;
{$ENDIF}
end;

function TBaseDebug.ShowVar(Ivar: Variant): Variant;
var
  S: string;
begin
  Result := Ivar;
{$IFNDEF undebug}
  try
    s := Ivar;
    MessageBox(0, Pchar(s), 'Debug', 0);
  except
    on e: Exception do
      AddLogShower(e.Message);
  end;
{$ENDIF}
end;

procedure TBaseDebug.StartLogTime;
begin
  FStartTime := GetTickCount;
end;

procedure TBaseDebug.TrackOnTrack(Iobj: TObject);
begin
  FBugShowForm.AlphaBlendValue := TTrackBar(Iobj).Position;
end;

function TBaseDebug.AddLogShower(IStrings: TStrings): TStrings;
var
  I: Integer;
begin
  Result := IStrings;
{$IFNDEF undebug}
  AddLogShower('>>>开始显示Strings Items数量', IStrings.Count);
  for I := 0 to IStrings.Count - 1 do
    AddLogShower(IStrings.Strings[i]);
  AddLogShower('显示Strings结束<<< Items数量', IStrings.Count);
{$ENDIF}
end;

procedure TBaseDebug.UnInitDebugSystem;
begin
  UnregisterHotKey(Application.Handle, F_gob_openFrom);
  UnregisterHotKey(Application.Handle, F_gob_AutoLog);
  GlobalDeleteAtom(F_gob_openFrom);
  GlobalDeleteAtom(F_gob_AutoLog);
end;

procedure TBaseDebug.hotykey(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message = WM_HOTKEY then begin
    if loword(Msg.lParam) = MOD_ALT then
      case HiWord(msg.LParam) of //
        ord('o'), Ord('O'): begin
            FBugShowForm.Visible := not FBugShowForm.Visible;
            if Application.MainForm <> nil then
              Application.MainForm.SetFocus;
          end;
        ord('P'), ord('p'): begin
            WantAutoSaveLog := not WantAutoSaveLog;
            AddLogShower('当前自动保存的状态改为： ');
            AddLogShower(WantAutoSaveLog)
          end;
      end; // case
  end;
end;

function TBaseDebug.GetSqlWithTableName(IQuery: TADOQuery;
  ItabName: string; Issk: SCreateSqlKind): string;
begin
  with IQuery do begin
    Close;
    SQL.Text := Format('Select * from %s Where 1=2', [ItabName]);
    try
      Open;
      case Issk of //
        SSk_insert: Result := CreateInsertSql(IQuery.Fields, ItabName);
        SSk_update: Result := CreateUpdateSql(IQuery.Fields, ItabName);
      end; // case
    except
      on e: Exception do
        AddLogShower('生成语句函数读取数据库时异常,语句生成失败', e.Message);
    end;
  end; // with
end;

function TBaseDebug.CreateInsertSql(IdataSet: TFields; ItabName: string): string;
var
  I: Integer;
  LList: TStringList;
begin
  LList := TStringList.Create;
  with IdataSet do begin
    Result := 'Insert into ' + ItabName + '(';
    for I := 0 to Count - 1 do begin // Iterate
      Result := Result + Fields[i].FieldName;
      case Fields[i].DataType of
        ftCurrency, ftBCD, ftSmallint, ftWord, ftInteger, ftBytes: LList.Add('%d');
        ftFloat: LList.Add('%f');
      else
        LList.Add('''%s''');
      end; // case
      if i <> Count - 1 then
        Result := Result + ',';
    end; // for
    Result := Result + ') Values(';
    for I := 0 to LList.Count - 1 do begin // Iterate
      Result := Result + LList.Strings[i];
      if i <> LList.Count - 1 then
        Result := Result + ',';
    end; // for
    Result := Result + ')';
  end; // with
  LList.Free;
end;

function TBaseDebug.CreateUpdateSql(IdataSet: TFields; ItabName: string): string;
var
  I: Integer;
begin
  with IdataSet do begin
    Result := 'Update ' + ItabName + ' Set ';
    for I := 0 to Count - 1 do begin // Iterate
      Result := Result + Fields[i].FieldName + '=';
      case Fields[i].DataType of //
        ftCurrency, ftBCD, ftSmallint, ftWord, ftInteger, ftBytes: Result := Result + '%d';
        ftFloat: Result := Result + '%d'
      else
        Result := Result + '''%s''';
      end; // case
      if i <> Count - 1 then
        Result := Result + ',';
    end; // for
  end; // with
end;

function TBaseDebug.AddLogShower(IDateset: TDataSet; IshowKind: SShowKind;
  IshowNumber: Integer): TDataSet;
var
  I, N, tot: Integer;
  LTep: string;
begin
  Result := IDateset;
{$IFNDEF undebug}
  AddLogShower('>>>开始显示DataSet');
  AddLogShower('数据集%s打开与否:%s', [IDateset.Name, BoolToStr(IDateset.Active, True)]);
  AddLogShower('总记录数', IDateset.RecordCount);
  AddLogShower('当前记录数', IDateset.RecNo);
  AddLogShower('记录大小', IDateset.RecordSize);
  if IshowKind <> Sshowkind_None then begin
    AddLogShower('开始显示数据集记录>>>');
    for I := 0 to IDateset.Fields.Count - 1 do
      LTep := LTep + ' | ' + IDateset.Fields[i].FieldName;
    AddLogShower(LTep);
    if IshowKind = Sshowkind_FieldHead then begin
    end
    else if IshowKind = Sshowkind_CurrNo then begin
      LTep := '';
      for I := 0 to IDateset.Fields.Count - 1 do
        LTep := LTep + ' | ' + IDateset.Fields[i].AsString;
      AddLogShower(LTep);
    end
    else begin
      if IshowKind = Sshowkind_All then
        tot := IDateset.RecordCount
      else
        tot := IshowNumber;
      IDateset.First;
      for I := 0 to tot - 1 do begin
        LTep := '';
        for N := 0 to IDateset.FieldCount - 1 do
          LTep := LTep + ' | ' + IDateset.Fields[n].AsString;
        AddLogShower(LTep);
        IDateset.Next;
      end;
    end;
  end;
  AddLogShower('显示DataSet完毕<<<');
{$ENDIF}
end;

function TBaseDebug.AddLogShower(IStr: string; const Args: array of const):
  Variant;
begin
  Result := IStr;
{$IFNDEF undebug}
  try
    IStr := Format(IStr, Args);
    Result := IStr;
    FLoger.AddShow(Result);
  except
    on e: Exception do
      AddLogShower(e.Message);
  end;
{$ENDIF}
end;

function TBaseDebug.AddLogShower(IRect: TRect): TRect;
begin
  Result := IRect;
{$IFNDEF undebug}
  try
    FLoger.AddShow(Format('rect : left<%d> top<%d> right<%d> bottom<%d>', [IRect.Left, IRect.Left, IRect.Right, IRect.Bottom]));
  except
    on e: Exception do
      AddLogShower(e.Message);
  end;
{$ENDIF}
end;

function TBaseDebug.AddLogShower(IBuff: Pointer; ILen: integer): string;
var
  i: integer;
  lp: PByte;
  LS: string;
begin
  lp := IBuff;
  for i := 0 to ILen - 1 do begin // Iterate
    ls := LS + '$' + IntToHex(lp^, 2);
    inc(lp);
  end; // for
  Result := Ls;
{$IFNDEF undebug}
  Gob_Debug.AddLogShower('内存数据<' + IntToStr(ILen) + '>:' + LS);
{$ENDIF}
end;

initialization
  Gob_Debug := TBaseDebug.Create;
finalization
  Gob_Debug.Free;
end.

