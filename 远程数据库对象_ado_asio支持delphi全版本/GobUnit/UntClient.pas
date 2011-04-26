{*******************************************************}
{      单元名：  UntClient.pas                          }
{      创建日期：2006-2-23 23:03:36                     }
{      创建者    马敏钊                                 }
{      功能：    通用Socket客户端                       }
{                                                       }
{*******************************************************}

unit UntClient;

interface

uses UntTBaseSocketClient, classes;

type
  TCenterClient = class;
  TreadThread = class(TThread)
  private
    CentClient: TCenterClient;
  public
    procedure Execute; override;
    destructor Destroy; override;
    constructor Create(ICent: TCenterClient; IStop: boolean);
  end;

  TCenterClient = class(TBaseSocketClient)
  private
    procedure DoCase;
  protected
    LivingTime: Cardinal;
    LivingCount: Byte;
    procedure OnCreate; override;
    procedure OnDestory; override;
    procedure DoReciveData; virtual; abstract;
  public
    ReadThread: TreadThread;
    function ConnToServer(ITimeOut: integer = 3000; IsRunReadBackThread: boolean =
      False): boolean; virtual;
  end;


implementation

uses SysUtils, IdIOHandlerSocket, IdSocketHandle, windows,
  IdTCPClient, untbaseProctol;

function TCenterClient.ConnToServer(ITimeOut: integer = 3000; IsRunReadBackThread:
  boolean = False): boolean;
begin
  Result := True;
  if not Client.Connected then begin
    try
      Client.Connect(ITimeOut);
    except
      Result := False;
    end;
    if Result = True then begin
      SendHead(1);
      Client.WriteInteger(8290);
      if Client.ReadInteger = STCLogined then begin
        ReadThread := TreadThread.Create(Self, IsRunReadBackThread);
        ReadThread.FreeOnTerminate := True;
      end
      else
        Result := False;
    end;
  end;
end;

procedure TCenterClient.DoCase;
begin
  DoReciveData;
end;

{ TreadThread }

constructor TreadThread.Create(ICent: TCenterClient; IStop: boolean);
begin
  inherited Create(istop);
  CentClient := ICent;
end;

destructor TreadThread.Destroy;
begin
  inherited;
end;

var
  Glf: TFileStream;
  glBuff: array[0..1023] of char;

procedure TreadThread.Execute;

begin
//  If Glf=nil Then
//    Glf:=TFileStream.Create('C:\1.wmv',fmCreate);

  while not Terminated do begin
//    CentClient.Client.ReadBuffer(glbuff[0],1024);
//    Glf.WriteBuffer(glbuff[0],1024);
    CentClient.DoCase;
  end; // while
end;

procedure TCenterClient.OnCreate;
begin
  inherited;
  LivingTime := GetTickCount;
  LivingCount := 4;
end;

procedure TCenterClient.OnDestory;
begin
  inherited;
  if ReadThread <> nil then begin
    ReadThread.FreeOnTerminate := True;
    ReadThread.Terminate;
  end;
end;

end.

