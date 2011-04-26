{*******************************************************}
{      单元名：  Un_socket_control.pas                  }
{      创建日期：2008-7-7 23:18:37                      }
{      创建者    马敏钊                                 }
{      功能：    通讯对象单元                           }
{                                                       }
{*******************************************************}

unit UntsocketDxBaseClient;

interface

uses classes, untASIOSvr;

type
  //客户端对象
  TSocketClient = class(TAsioClient)
  private
  public
    FHost, Facc, Fpsd: string;
    FPort: Word;
    constructor Create;
    destructor Destroy; override;
    procedure SetConnParam(Ihost: string; Iport: word);
    procedure WriteBuff(var obj; Ilen: integer);
    procedure WriteStream(Istream: TStream);
    function Getipandport(IConn: TAsioClient): string;
    function GetHead: Integer; //读取报头
    procedure SendHead(ICmd: Integer); //发送报头
    procedure SendObject(IObj: TObject); //发送对象
    procedure GetObject(IObj: TObject; IClass: TClass); overload;
    //接收对象 自己根据类之类来创建对象
    procedure GetObject(IObj: TObject); overload;
    //由外部代入已经创建好的对象
    procedure SendZipFile(IFileName: string); //发送压缩文件
    function GetZipFile(IFileName: string): Integer; //接收压缩文件   //MMWIN:MEMBERSCOPY
    function GetZipStream(IStream: TStream; IConn: TAsioClient): integer;
    function GetStream(IStream: TStream; IConn: TAsioClient): integer;

    function SendZIpStream(IStream: tStream; IConn: TAsioClient): Integer;
    //连接
    function Connto(IIP: string; Iport: Word): boolean;

    procedure OnCreate; virtual; abstract;
    procedure OnDestory; virtual; abstract;
  end;

var
  GSocketClient: TSocketClient;

implementation

uses
  Windows, SysUtils, untfunctions;

{ TSocketClient }

function TSocketClient.Connto(IIP: string; Iport: Word): boolean;
begin
  Result := false;
  FHost := IIP;
  FPort := Iport;
  Result := ConnToSvr(IIP, Iport);
end;

constructor TSocketClient.Create;
begin
  inherited Create;
  OnCreate;
end;

destructor TSocketClient.Destroy;
begin
  OnDestory;
  CloseConn;

  inherited;
end;

function TSocketClient.GetHead: Integer;
begin
  Result := ReadInteger;
end;

function TSocketClient.Getipandport(IConn: TAsioClient): string;
begin
  Result := format('%S:%d', [PeerIP, PeerPort]);
end;

procedure TSocketClient.GetObject(IObj: TObject; IClass: TClass);
var
  Ltep: pint;
begin
  IObj := TClass.Create;
  Ltep := Pointer(Iobj);
  inc(Ltep);
  ReadBuffer(Ltep, Iobj.InstanceSize - 4);
end;

procedure TSocketClient.GetObject(IObj: TObject);
var
  Ltep: pint;
begin
  Ltep := Pointer(Iobj);
  inc(Ltep);
  ReadBuffer(Ltep, Iobj.InstanceSize - 4);
end;

function TSocketClient.GetStream(IStream: TStream; IConn: TAsioClient): integer;
var
  LZipMM: TMemoryStream;
  LBuff: Pointer;
  i, ltot, x: Integer;
begin

  LZipMM := TMemoryStream(IStream);
  ltot := IConn.ReadInteger;
  LZipMM.Size := ltot;
  IStream.Position := 0;
  LBuff := LZipMM.Memory;
  x := 0;
  while ltot > 0 do begin
    i := ReadBuffer(PChar(LBuff) + x, ltot);
    Dec(ltot, i);
    inc(x, i);
  end; // while
//  DeCompressStream(LZipMM);
end;



function TSocketClient.GetZipFile(IFileName: string): integer;
var
  LZipMM: TMemoryStream;
  LBuff: Pointer;
  i, ltot, x: Integer;
begin
  LZipMM := TMemoryStream.Create;
  try
    ltot := ReadInteger;
    LZipMM.Size := ltot;
    LBuff := LZipMM.Memory;
    x := 0;
    while ltot > 0 do begin
      i := ReadBuffer(PChar(LBuff) + x, ltot);
      Dec(ltot, i);
      inc(x, i);
    end; // while
    DeCompressStream(LZipMM);
    LZipMM.SaveToFile(IFileName);
    Result := LZipMM.Size;
  finally // wrap up
    LZipMM.Free;
  end; // try/finally
end;

function TSocketClient.GetZipStream(IStream: TStream; IConn: TAsioClient):
  integer;
var
  LZipMM: TMemoryStream;
  LBuff: Pointer;
  i, ltot, x: Integer;
begin
  LZipMM := TMemoryStream(IStream);
  ltot := IConn.ReadInteger;
  LZipMM.Size := ltot;
  LBuff := LZipMM.Memory;
  x := 0;
  while ltot > 0 do begin
    i := ReadBuffer(PChar(LBuff) + x, ltot);
    Dec(ltot, i);
    inc(x, i);
  end; // while
  DeCompressStream(LZipMM);
end;

procedure TSocketClient.SendHead(ICmd: Integer);
begin
  WriteInteger(ICmd);
end;

procedure TSocketClient.SendObject(IObj: TObject);
var
  Ltep: Pint;
begin
  Ltep := Pointer(IObj);
  inc(Ltep);
  Write(ltep, IObj.InstanceSize - 4);
end;

procedure TSocketClient.SendZipFile(IFileName: string);
var
  LZipMM: TMemoryStream;
begin
  LZipMM := TMemoryStream.Create;
  try
    LZipMM.LoadFromFile(IFileName);
    EnCompressStream(LZipMM);
    WriteInteger(LZipMM.Size);
    WriteBuff(LZipMM.Memory^, LZipMM.Size);
  finally
    LZipMM.Free;
  end;
end;

function TSocketClient.SendZIpStream(IStream: tStream; IConn: TAsioClient):
  Integer;
begin
  EnCompressStream(TMemoryStream(IStream));
  IConn.WriteInteger(IStream.Size);
  IConn.Write(TMemoryStream(IStream).Memory, IStream.Size);
  Result := IStream.Size;
end;

procedure TSocketClient.SetConnParam(Ihost: string; Iport: word);
begin
  FHost := Ihost;
  FPort := Iport;

end;

procedure TSocketClient.WriteBuff(var obj; Ilen: integer);
begin
  Write(@obj, Ilen);
end;

procedure TSocketClient.WriteStream(Istream: TStream);
begin
  WriteInteger(Istream.Size);
  Write(TMemoryStream(Istream).Memory, Istream.Size);
end;

end.

