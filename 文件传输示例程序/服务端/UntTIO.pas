{*******************************************************}
{      单元名：  UntTIO.pas                             }
{      创建日期：2006-1-14 23:20:08                     }
{      创建者    马敏钊 QQ 22900104                     }
{      功能：    I/O单元                                }
{                                                       }
{*******************************************************}
//  增加一个级别
//    约定：0 - Information
//          1 - Notice
//          2 - Warning
//          3 - Error
//          4 - Report
unit UntTIO;

interface
uses Classes, SysUtils, ComCtrls;
type
  TGameLogFile = class
  private
    FFileParth: string; //路径
    FText: Cardinal;
    FIsCreateToNew: boolean;
    //是否是每次启动程序都创建新的记录文件 否则就是当天只会有1个文件
  public
    {带入日志文件存放的目录位置}
    constructor Create(Iparth: string);
    destructor Destroy; override;
    {写入内容即可自动记录}
    procedure AddLog(Icon: string; const LogLevel: Integer = 0);
    procedure AddShow(ICon: string; const Args: array of const; const LogLevel:
      Integer = 0); overload;
    procedure AddShow(ICon: string; const LogLevel: Integer = 0); overload;
    property IsCreateToNew: boolean read FIsCreateToNew write FIsCreateToNew;
  end;

  TEventShowed = procedure(ILogCon: string) of object;
  TIOer = class(TObject)
  private
    FIsAddTime: boolean; //是否在每条显示前加时间
    FAfterShowed: TEventShowed; //显示后触发的事件 可以用来做日志
    FIsNeedSplt: boolean; //是否需要分割字符
    FSplitChar: string; //分割的字符
    FLog: TGameLogFile;
  protected
    FShower: TComponent; //容器
    FClearTager: Word; //显示多少条后清空一下
    function DoAdd(Icon: string; const LogLevel: Integer = 0): Integer; virtual;

  public
    Enabled: Boolean;
    function AddShow(ICon: string; const Args: array of const; const LogLevel:
      Integer = 0): Integer; overload;
    function AddShow(ICon: string; const LogLevel: Integer = 0): Integer;
      overload;
    {如果带入记录文件存放路径的话就自动生成记录类}
    constructor Create(IShower: TComponent; IlogFIleDir: string = '');
    destructor Destroy; override;
    property ClearTager: Word read FClearTager write FClearTager;
    property IsAddTime: boolean read FIsAddTime write FIsAddTime;
    property IsNeedSplitChar: boolean read FIsNeedSplt write FIsNeedSplt;
    property SplitChar: string read FSplitChar write FSplitChar;
    property AfterShowed: TEventShowed read FAfterShowed write FAfterShowed;
  end;

implementation
uses StdCtrls, Forms;
const
  {分割符号}
  CSplitStr = '===============================================================';
  ClogFileName = '.txt';
  { TGameLogFile }

procedure TGameLogFile.AddLog(Icon: string; const LogLevel: integer = 0);
begin
  Icon := Icon+#13#10;
  FileWrite(FText, PChar(Icon)^, Length(ICon));
  //{$I-}
//    Append(FText);
//     Writeln(FText, icon);
//    IOResult;
  //{$I+}
end;

procedure TGameLogFile.AddShow(ICon: string; const Args: array of const; const
  LogLevel: Integer = 0);
begin
  AddLog(Format(ICon, args));
end;

procedure TGameLogFile.AddShow(ICon: string; const LogLevel: Integer = 0);
begin
  AddLog(ICon);
end;

constructor TGameLogFile.Create(Iparth: string);
var
  Ltep: string;
begin
  FIsCreateToNew := False;
  FFileParth := Iparth;
  if not DirectoryExists(FFileParth) then
    if not ForceDirectories(FFileParth) then begin
      raise
        Exception.Create('错误的路径，日志类对象不能被创建');
    end;
  if FIsCreateToNew then begin
    Ltep := FormatDateTime('yyyymmddhhnnss', Now);
    FText := (FileCreate(FFileParth + ltep + ClogFileName));
  end
  else
    Ltep := FormatDateTime('yyyymmdd', Now);
  if not FileExists(FFileParth + ltep + ClogFileName) then
    FText := (FileCreate(FFileParth + ltep + ClogFileName))
  else
    FText := (FileOpen(FFileParth + ltep + ClogFileName, fmOpenWrite));
  FileSeek(FText, soFromEnd, soFromEnd);
end;

destructor TGameLogFile.Destroy;
begin
  try
    FileClose(FText);
  except
  end;
  inherited;
end;

{ TGameIO }

function TIOer.AddShow(ICon: string; const Args: array of const; const LogLevel:
  Integer = 0): Integer;
begin
  Result := 0;
  try
    ICon := Format(ICon, Args);
    if FIsAddTime then
      ICon := DateTimeToStr(Now) + ' ' + Icon;
    if FIsNeedSplt then
      ICon := ICon + #13#10 + FSplitChar;
    Result := DoAdd(ICon, LogLevel);
    if assigned(FLog) then
      FLog.AddLog(ICon);
    if Assigned(FAfterShowed) then
      FAfterShowed(ICon);
  except
  end;
end;

function TIOer.AddShow(ICon: string; const LogLevel: Integer = 0): Integer;
begin
  if FIsAddTime then
    ICon := DateTimeToStr(Now) + ' ' + Icon;
  if FIsNeedSplt then
    ICon := ICon + #13#10 + FSplitChar;
  Result := DoAdd(ICon, LogLevel);
  if assigned(FLog) then
    FLog.AddLog(ICon);
  if Assigned(FAfterShowed) then
    FAfterShowed(ICon);
end;

constructor TIOer.Create(IShower: TComponent; IlogFIleDir: string);
begin
  FClearTager := 1000;
  IsAddTime := True;
  FIsNeedSplt := False;
  FSplitChar := CSplitStr;
  FShower := IShower;
  Enabled := True;
  if IlogFIleDir <> '' then
    FLog := TGameLogFile.Create(IlogFIleDir);
end;

destructor TIOer.Destroy;
begin
  if assigned(FLog) then
    FLog.Free;
  inherited;
end;

function TIOer.DoAdd(Icon: string; const LogLevel: Integer = 0): Integer;
var
  ListItem: TListItem;
begin
  Result := -1;
  if Application.Terminated then
    exit;
  if (not Enabled) then
    exit;
  if (FShower is TMemo) then begin
    Result := TMemo(FShower).Lines.Add(Icon);
    if Result >= FClearTager then
      TMemo(FShower).Clear
  end
  else if (FShower is TRichEdit) then begin
    Result := TRichEdit(FShower).Lines.Add(Icon);
    if Result >= FClearTager then
      TRichEdit(FShower).Clear
  end
  else if (FShower is TListBox) then begin
    Result := TListBox(FShower).Items.Add(Icon);
    if Result >= FClearTager then
      TListBox(FShower).Clear
  end
  else if (FShower is TListView) then begin
    ListItem := TListView(FShower).Items.Add;
    ListItem.Caption := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
    ListItem.ImageIndex := LogLevel;
    ListItem.SubItems.Add(Icon);
    if TListView(FShower).Items.Count >= FClearTager then
      TListView(FShower).Items.Clear;
  end
  else
    raise Exception.Create('默认容器错误:' + FShower.ClassName);
end;

end.

