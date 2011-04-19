{*******************************************************}
{      单元名：  UntCFGer.pas                           }
{      创建日期：2006-1-15 0:32:12                      }
{      创建者    马敏钊 QQ 22900104                     }
{      功能：    对配置文件的封装单元 省去创建和释放的  }
{                步骤                                   }
{                                                       }
{*******************************************************}

unit UntCFGer;

interface

uses IniFiles;

type
  TCFGer = class
  private
  public
    opter: TMemIniFile;
    {当前的节}
    CurrSecton: string;
    constructor Create(ICfg: string);
    destructor Destroy; override;
//------------------------------------------------------------------------------
// 读取一些常用的配置 2006-3-16 马敏钊
//------------------------------------------------------------------------------
    procedure SetSecton(iSecton: string);
    function ReadString(IName: string; IDefaultValue: string = ''): string;
    procedure WriteString(IName: string; IValue: string);
    function Readint(IName: string; IDefaultValue: integer = 0): Integer;
    procedure Writeint(IName: string; IValue: Integer);
    function ReadBoolean(IName: string; IDefaultValue: Boolean = False): Boolean;
    procedure WriteBoolean(IName: string; IValue: Boolean);
    function ReadDateTime(IName: string; IDefaultValue: TDateTime): TDateTime;
    procedure WriteDateTime(IName: string; IValue: TDateTime);
  published

  end;
var
  Gob_CFGer: TCFGer;

procedure AssignCfgFile(IfileName: string);


//------------------------------------------------------------------------------
// 定义一些常用的配置字符串 2006-3-16 马敏钊
//------------------------------------------------------------------------------
const
  CCfg_fileName = 'sys.ini';

  CCFG_Secon_Server = 'server';
  CCFG_Server_ServerPort = 'serverPort';
  CCFG_Server_ServerIP = 'ServerIP';

  CCFG_Secon_App = 'Application';
  CCFG_APP_Title = 'Title';
  CCFG_APP_Vison = 'Vison';

  CCFG_Secon_AutoUpdata = 'AutoUpdata';
  CCFG_AutoUpdata_IsEnable = 'IsEnable';
  CCFG_AutoUpdata_RmoServerIni = 'RmoServerIni';
  CCFG_AutoUpdata_IsAutoUpdata = 'IsAutoUpdata';
  CCFG_AutoUpdata_IsFindNewAsk = 'IsFindNewAsk';
  CCFG_AutoUpdata_IsUpdatedAsk = 'IsUpdatedAsk';
  CCFG_AutoUpdata_IsHintInUpdateFault = 'IsHintInUpdateFault';
  CCFG_AutoUpdata_OnHaventNewVison = 'OnHaventNewVison';

  CCFG_Secon_DB = 'DB';
  CCFG_DB_FileName = 'FileName';
  CCFG_DB_OnCreateBuff = 'BuffCount';
  CCFG_DB_IsBkupOnCreateApp = 'IsBkupOnCreateApp';
  CCFG_DB_UpdateDay = 'UpdateDay';
  CCFG_DB_LastBkTime = 'LastBkTime';
  CCFG_DB_backupdir = 'backupdir';




implementation

uses SysUtils;

{ TCFGer }

{-------------------------------------------------------------------------------
  过程名:    AssignCfgFile
  作者:      马敏钊
  日期:      2006.01.15
  参数:      IfileName: string
  返回值:    无
  说明:      自动生成配置文件操作类
-------------------------------------------------------------------------------}

procedure AssignCfgFile(IfileName: string);
begin
  if assigned(Gob_CFGer) then
    Gob_CFGer.Free;
  Gob_CFGer := TCFGer.Create(IfileName);
end;



constructor TCFGer.Create(ICfg: string);
begin
  if not FileExists(ICfg) then
    FileClose(FileCreate(ICfg));
  Opter := TMemIniFile.Create(ICfg);
end;

destructor TCFGer.Destroy;
begin
  Opter.UpdateFile;
  Opter.Free;
  inherited;
end;

function TCFGer.ReadBoolean(IName: string; IDefaultValue: Boolean = False):
  Boolean;
begin
  Result := opter.ReadBool(CurrSecton, IName, IDefaultValue);
end;

function TCFGer.ReadDateTime(IName: string; IDefaultValue: TDateTime):
  TDateTime;
begin
  Result := opter.ReadDateTime(CurrSecton, IName, IDefaultValue);
end;

function TCFGer.Readint(IName: string; IDefaultValue: integer = 0): Integer;
begin
  Result := opter.ReadInteger(CurrSecton, IName, IDefaultValue);
end;

function TCFGer.ReadString(IName: string; IDefaultValue: string = ''): string;
begin
  Result := opter.ReadString(CurrSecton, IName, IDefaultValue);
end;

procedure TCFGer.SetSecton(iSecton: string);
begin
  CurrSecton := iSecton;
end;

procedure TCFGer.WriteBoolean(IName: string; IValue: Boolean);
begin
  opter.WriteBool(CurrSecton, IName, IValue);
end;

procedure TCFGer.WriteDateTime(IName: string; IValue: TDateTime);
begin
  opter.WriteDateTime(CurrSecton, IName, IValue);
end;

procedure TCFGer.Writeint(IName: string; IValue: Integer);
begin
  opter.WriteInteger(CurrSecton, IName, IValue);
end;

procedure TCFGer.WriteString(IName: string; IValue: string);
begin
  opter.WriteString(CurrSecton, IName, IValue);
end;

initialization

finalization
  if assigned(Gob_CFGer) then
    Gob_CFGer.Free;

end.

