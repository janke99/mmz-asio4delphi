{*******************************************************}
{      单元名：  Un_socket_control.pas                  }
{      创建日期：2008-7-7 23:18:37                      }
{      创建者    马敏钊                                 }
{      功能：    通讯对象单元                           }
{                                                       }
{*******************************************************}

unit UntsocketDxBaseClient;

interface

uses classes,
  Windows,
  Winsock;
// ONLY ENABLE THIS - IF YOU LICENSED OUR TLS-EDITION OF DXSOCK
// IT IS NOT FREE - IT IS NOT INCLUDED WITH WWS - IT'S AS A LEGAL ISSUE!
//
{.$DEFINE TLS_EDITION}
{.$DEFINE SUPPORT_DESIGNTIME_CLIENTS}

// ONLY ENABLE THIS - IF YOU LICENSED OUR CODE TRACER SUITE
{.$DEFINE CODE_TRACER}

// custom feature for SMTP Sender -> SMTP Relay -> track session ID
{$DEFINE SMTP_SESSION_FEATURE}

// THESE CAN BE CHANGED BY YOU:
{.$DEFINE FINALBUILD}
   {.$DEFINE OCX_ONLY}// not done - will be in DXSock 4.0
{.$DEFINE OBJECTS_ONLY}
{$DEFINE ASM8086}
// LANGUAGE FILE FOR ERROR MESSAGE TEXT
{$DEFINE ENGLISH1}
{.$DEFINE FRENCH1}
{.$DEFINE GERMAN1}
{.$DEFINE ITALIAN1}
{.$DEFINE LOWMEM1}
{.$DEFINE PORTUGUESE1}
{.$DEFINE RUSSIAN1}
{.$DEFINE SPANISH1}
{.$DEFINE TURKISH1}

////////////////////////////////////////////////////////////////////////////////
{$IFDEF VER90}
{$DEFINE VER100}
{$ENDIF}
{$IFDEF VER105}
{$DEFINE VER100}
{$ENDIF}

{$IFDEF FINALBUILD}
{$ALIGN ON}
{$ASSERTIONS OFF}
{$DEBUGINFO OFF}
{$DEFINITIONINFO OFF}
{$DESCRIPTION 'Uses Brain Patchwork DX, LLC. DXSock 4.0.0'}
{$EXTENDEDSYNTAX ON}
{$HINTS ON}
{$IMAGEBASE $2112CAFE}
{$IMPORTEDDATA ON}
{$IOCHECKS ON}
{$LOCALSYMBOLS OFF}
{$LONGSTRINGS ON}
{$OBJEXPORTALL ON}
{$OPTIMIZATION ON}
{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}
{$REALCOMPATIBILITY OFF}
{$REFERENCEINFO OFF}
{$RUNONLY OFF}
{$STACKFRAMES OFF}
{$VARSTRINGCHECKS ON}
{$WARNINGS ON}
{$ENDIF}
// END OF FILE //

const
  INVALID_SOCKET = Winsock.INVALID_SOCKET;
  SO_KeepAlive = Winsock.SO_KEEPALIVE;
  WSAENOBUFS = Winsock.WSAENOBUFS;
  WSAETIMEDOUT = Winsock.WSAETIMEDOUT;
  WSAECONNABORTED = Winsock.WSAECONNABORTED;
  Socket_Error = Winsock.SOCKET_ERROR;
   // 7-27:
  WSAEWOULDBLOCK = Winsock.WSAEWOULDBLOCK;
   // 6-27:
  WSAECONNRESET = Winsock.WSAECONNRESET;


{$IFDEF VER100}
type
  in_addr = TInAddr;
{$ENDIF}

type
  TDXBlockSizeFlags = (
    bsfZero, // special meaning for TLS!
    bsfRealSmall,
    bsfSmall, bsfNormal,
    bsfBigger,
    bsfBiggest,
    bsfHUGE);
{$J+} // 4.0
const
  TDXHugeSize = 8192 * 2; // 16kb CHUNKS
  TDXXferTimeout: Word = 50000; // if data loss then set to 50000
  TDXMaxSocketBuffer: Word = TDXHugeSize; // Winsock Buffer Size
  PeekBufferSize: Byte = 250; // do not go over 250!
{$J-}
var
{$IFDEF LINUX}
  SizeOfInt: Cardinal = 4; // optimize compiling
{$ELSE}
  SizeOfInt: Integer = 4; // optimize compiling
{$ENDIF}

type
  Str1 = string[1];
{$IFDEF LINUX}
type
  DWord = LongWord;
  TThreadPriority = (tpIdle, tpLowest, tpLower, tpNormal, tpHigher, tpHighest, pTimeCritical);
{$ELSE}
type
  PInteger = Windows.PInteger;
  DWORD = Windows.DWord;
{$ENDIF}

type

  TDXDataDirection = (ddAboutToWrite, ddAfterRead, ddCleanRead, ddFreePointer);

  TDXFilterCallBack = procedure(DataDirection: TDXDataDirection; const InData: Pointer; var OutData: Pointer; const
    InSize: Integer; var OutSize: Integer; var Handled: Boolean; xClientThread: TThread) of object;

  TDXBSArray = array[0..65500] of Char;
  TDXBSArray2 = array[0..250] of Char;
{$IFDEF LINUX}
  TSockAddrIn = Libc.TSockAddrin;
  TTimeVal = Libc.TTimeVal;
  TFDSet = Libc.TFDSet;
{$ELSE}
  TSockAddrIn = Winsock.TSockAddrIn;
  TTimeVal = Winsock.TTimeVal;
  TFDSet = Winsock.TFDSet;
{$ENDIF}
  PNewConnect = ^TNewConnect;
  TNewConnect = record
    Port: Integer;
    UseNAGLE: Boolean;
    UseUDP: Boolean;
    UseBlocking: Boolean;
    ipAddress: string;
  end;

  PNewListen = ^TNewListen;
  TNewListen = record
    Port: Integer;
    WinsockQueue: Integer;
    UseNAGLE: Boolean;
    UseUDP: Boolean;
    UseBlocking: Boolean;
    ConnectionLess: Boolean;
  end;

  PWinsockInfo = ^TWinsockInfo; // 2.3 changed array from 0.. to 1..
  TWinsockInfo = record
    Major_Version: Byte; {current version}
    Minor_Version: Byte; {current version}
    Highest_Major_Version: Byte; {available on disk}
    Highest_Minor_Version: Byte; {available on disk}
    Description: array[1..256] of Char; // C++ Char Description[256];
    SystemStatus: array[1..128] of Char; // C++ Char Description[128];
    MaxSockets: Word; // C++ Unsigned short MaxSockets;
    MaxUDPDatagramSize: Word; // C++ Unsigned short MaxUDPDatagramSize;
    VendorInfo: PChar; // C++ Char FAR * VendorInfo;
  end;

const
  ConstSizeofTSockAddrIn = 16;
type
  TDXSock = class(Tobject) // RC2
  private
{$IFDEF CODE_TRACER}
    CodeTracer: TDXCodeTracer;
{$ENDIF}
{$IFDEF TLS_EDITION}
    tBuf: TBrkApart;
    tStack: TMJBLIFO;
    Straggler: string;
{$ENDIF}
    FClientThread: TThread;
    FTLS: Boolean;
    fChunkBuf: Pointer;
    fbClientMode: Boolean;
    fbIsUDP: Boolean;
    fbIsKeepAlive: Boolean;
    FsBindTo: string;
    FPeekBuffer: ^TDXBSArray2;
    FReadTimeout: Boolean;
    FUseBlocking: Boolean;
    FBlockSizeFlags: TDXBlockSizeFlags;
    FActualBlockSize: Integer;
    FErrStatus: Integer;
    fTooManyCharacters: Integer;
    feOnFilter: TDXFilterCallBack;
{$IFDEF TLS_EDITION}
    feOnReadFilter: TDXFilterCallBack;
{$ENDIF}
    GlobalPeerPort: Integer;
    GlobalPeerIPAddress: string;
//      GlobalTimeout:TTimeVal;
    VarConstSizeofTSockAddrIn: Integer;
// new 4.0 features
    fTotalWBytes: Cardinal;
    fTotalRBytes: Cardinal;
    fCPSStart: TDateTime;
  protected
    function GetReleaseDate: string;
    procedure SetReleaseDate(value: string);
    function GetMyLocalPort: Integer;
    function GetMyLocalIPAddr: string;
    function IsConnected: Boolean;
    function IsValidSocket: Boolean;
    function IsReadable: Boolean;
    function IsWritable: Boolean;
    function DidReadTimeout: Boolean;
    procedure SetfBlockSizeFlags(Value: TDXBlockSizeFlags);
    function CountmyWaiting: Integer;

  public
    SockAddr: TSockAddrIn;
{$IFDEF LINUX}
    Sock: TFileDescriptor;
{$ELSE}
    Sock: Integer;
{$ENDIF}

{$IFNDEF OBJECTS_ONLY}
{$ENDIF}

    constructor Create;
    destructor Destroy; override;
    function Connect(Parameters: PNewConnect): Boolean;
    function Listen(Parameters: PNewListen): Boolean;
    function Accept(var NewSock: TDXSock): Boolean;
    procedure CloseGracefully;
    procedure Disconnect; // Borland Friendly
    procedure CloseNow;
    function SendBuf(const Buf; Count: Integer): Integer; // Borland friendly
    function ReceiveBuf(var Buf; Count: Integer): Integer; // Borland friendly
    function Readbuffer(iBuf: pointer; Count: Integer): Integer; // Borland friendly

    function CloseConn: Boolean;
    function IsConning: Boolean;
    function WriteString(const s: string): Integer;


{$IFDEF VER100}
    function BlockWrite(buf: Pointer; len: Integer): Integer;
    function WriteCh(c: Char): Integer;
    function Write(const s: string): Integer;
{$ELSE}
    function Write(c: Char): Integer; overload;
    function Write(const s: string): Integer; overload;
    function Write(buf: Pointer; len: Integer): Integer; overload;
{$ENDIF}
    function WriteLn(const s: string): Integer;
    function WriteResultCode(const Code: Integer; const Rslt: string): Integer;
    function WriteWithSize(S: string): Boolean;
    function WriteInteger(const n: integer): integer;

{$IFDEF VER100}
    function SendFromStreamRange(Stream: TStream; Range: Integer): Boolean;
    function SendFromStream(Stream: TStream): Boolean;
    function SendFromWindowsFile(var Handle: Integer): boolean;
    function SendFromBorlandFile(var Handle: file): boolean;
{$ELSE}
    function SendFrom(Stream: TStream; Range: Integer): Boolean; overload;
    function SendFrom(Stream: TStream): Boolean; overload;
    function SendFrom(var Handle: Integer): boolean; overload;
    function SendFrom(var Handle: file): boolean; overload;
{$ENDIF}
    function SendFromStreamWithSize(Stream: TStream): Boolean;
{$IFDEF VER100}
    function BlockRead(buf: Pointer; len: Integer): Integer;
    function Read: Char;
{$ELSE}
    function Read(buf: Pointer; len: Integer): Integer; overload;
    function Read: Char; overload;
{$ENDIF}
    function ReadInteger: integer;
    function ReadStr(MaxLength: Integer): string;
    function ReadString(MaxLength: Integer; iTimeout: Longword): string;
    function ReadLn(iTimeout: Longword = 100000): string;
    function ReadCRLF(iTimeout: Longword): string;
    function ReadToAnyDelimiter(iTimeout: Longword; Delimiter: string): string;
    function ReadNull(Timeout: Longword): string;
    function ReadSpace(Timeout: Longword): string;
    function ReadWithSize: string;
{$IFDEF VER100}
    function SaveToStream(Stream: TStream; Timeout: Longword): Boolean;
    function SaveToWindowsFile(var Handle: Integer; Timeout: Longword): boolean;
    function SaveToBorlandFile(var Handle: file; Timeout: Longword): boolean;
{$ELSE}
    function SaveTo(Stream: TStream; iTimeout: Longword): Boolean; overload;
    function SaveTo(var Handle: Integer; iTimeout: Longword): boolean; overload;
    function SaveTo(var Handle: file; iTimeout: Longword): boolean; overload;
{$ENDIF}
    function SaveToStreamWithSize(Stream: TStream; iTimeout: Longword): Boolean;
    function GetChar: Str1;
    function GetByte: Byte;
    function FilterRead(const InBuf: Pointer; var OutBuf: Pointer; InSize: Integer; xClientThread: TThread): Integer;
    function PeekString: string;
    function PeekChar: Char;
    function GetErrorStr: string;
    function GetMyErrorDesc(errorCode: Integer): string;
    procedure SetbNagle(TurnOn: Boolean);
    procedure SetbBlocking(TurnOn: Boolean);
    procedure WinsockVersion(var WinsockInfo: PWinsockInfo);
    // made public for new TDXSockClient:
    procedure SockClientSetGlobal(I: string; P: Integer);
    procedure SetTimeoutAndBuffer(SocketHandle: Integer);
// new 3.0 features:
    function DroppedConnection: Boolean;
    function WaitForData(itimeout: Longint): Boolean;
// new 4.0 features:
    procedure RestartCharactersPerSecondTimer;
    function CharactersPerSecondWritten: Integer;
    function CharactersPerSecondReceived: Integer;
  published
    property TLSActive: Boolean read FTLS write FTLS;
    property TLSClientThread: TThread read FClientThread write FClientThread;
    property BindTo: string read fsBindTo
      write fsBindTo;
    property Connected: Boolean read IsConnected;
    property CharactersToRead: Integer read CountmyWaiting;
    property ReceiveLength: Integer read CountmyWaiting; // Borland Friendly
    property ValidSocket: Boolean read IsValidSocket;
    property LastReadTimeout: Boolean read DidReadTimeout;
    property LastCommandStatus: Integer read FErrStatus write FErrStatus;
    property OutputBufferSize: TDXBlockSizeFlags read fBlockSizeFlags
      write SetfBlockSizeFlags;
    property TooManyCharacters: Integer read fTooManyCharacters
      write fTooManyCharacters;
    property IsUDPMode: Boolean read fbIsUDP
      write fbIsUDP;
    property IsKeepAliveMode: Boolean read fbIsKeepAlive write fbIsKeepAlive;
    property PeerIPAddress: string read GlobalPeerIPAddress
      write GlobalPeerIPAddress;
    property PeerPort: Integer read GlobalPeerPort
      write GlobalPeerPort;
    property LocalIPAddress: string read GetMyLocalIPAddr;
    property LocalPort: Integer read GetMyLocalPort;
    property Readable: Boolean read IsReadable;
    property Writable: Boolean read IsWritable;
    property ReleaseDate: string read GetReleaseDate
      write SetReleaseDate;
    property OnFilter: TDXFilterCallBack read feOnFilter
      write feOnFilter;
{$IFDEF CODE_TRACER}
    property DXCodeTracer: TDXCodeTracer read CodeTracer
      write CodeTracer;
{$ENDIF}
{$IFDEF TLS_EDITION}
    property OnReadFilter: TDXFilterCallBack read feOnReadFilter
      write feOnReadFilter;
{$ENDIF}
  end;



  //客户端对象

  TAsioClient = class(TDXSock)
  private
  public
    FHost, Facc, Fpsd: string;
    FPort: Word;
    Socket: TAsioClient;
    constructor Create;
    destructor Destroy; override;
    function GetCanUseSize: integer;
    procedure SetConnParam(Ihost: string; Iport: word);
    procedure SendAsioHead(Ilen: integer);
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

    function SendZIpStream(IStream: tStream; IConn: TAsioClient;
      IisEnc: boolean = false): Integer;
    //连接
    function Connto(IIP: string; Iport: Word): boolean;

    procedure OnCreate; virtual; abstract;
    procedure OnDestory; virtual; abstract;
  end;


var
  GSocketClient: TAsioClient;

implementation

uses
  SysUtils, untfunctions, Math, Types, Messages, Dialogs;

////////////////////////////////////////////////////////////////////////////////
//public fun
var
{$IFNDEF LINUX}
  DLLData: TWSAData;
{$ENDIF}
  StartupResult: Integer;
var
  GlobalTimeout: TTimeVal; //6-9


const
  _WSAEINTR = 'Interrupted system call'; // 10004 L:4
  _WSAEBADF = 'Bad file number'; // 10009 L:9
  _WSAEACCES = 'Permission denied'; // 10013 L:13
  _WSAEFAULT = 'Bad address'; // 10014 L:14
  _WSAEINVAL = 'Invalid argument'; // 10022 L:22
  _WSAEMFILE = 'Too many open files'; // 10024 L:24
  _WSAEWOULDBLOCK = 'Operation would block'; // 10035 L:11 (?L:35?)
  _WSAEINPROGRESS = 'Operation now in progress'; // 10036 L:115
  _WSAEALREADY = 'Operation already in progress'; // 10037 L:114
  _WSAENOTSOCK = 'Socket operation on non-socket'; // 10038 L:88
  _WSAEDESTADDRREQ = 'Destination address required'; // 10039 L:89
  _WSAEMSGSIZE = 'Message too long'; // 10040 L:90
  _WSAEPROTOTYPE = 'Protocol wrong type for socket'; // 10041 L:91
  _WSAENOPROTOOPT = 'Protocol not available'; // 10042 L:92
  _WSAEPROTONOSUPPORT = 'Protocol not supported'; // 10043 L:93
  _WSAESOCKTNOSUPPORT = 'Socket type not supported'; // 10044 L:94
  _WSAEOPNOTSUPP = 'Operation not supported on socket'; // 10045 L:95
  _WSAEPFNOSUPPORT = 'Protocol family not supported'; // 10046 L:96
  _WSAEAFNOSUPPORT = 'Address family not supported by protocol family'; // 10047 L:97
  _WSAEADDRINUSE = 'Address already in use'; // 10048 L:98
  _WSAEADDRNOTAVAIL = 'Can''t assign requested address'; // 10049 L:99
  _WSAENETDOWN = 'Network is down'; // 10050 L:100
  _WSAENETUNREACH = 'Network is unreachable'; // 10051 L:101
  _WSAENETRESET = 'Network dropped connection on reset'; // 10052 L:102
  _WSAECONNABORTED = 'Software caused connection abort'; // 10053 L:103
  _WSAECONNRESET = 'Connection reset by peer'; // 10054 L:104
  _WSAENOBUFS = 'No buffer space available'; // 10055 L:105
  _WSAEISCONN = 'Socket is already connected'; // 10056 L:106
  _WSAENOTCONN = 'Socket is not connected'; // 10057 L:107
  _WSAESHUTDOWN = 'Can''t send after socket shutdown'; // 10058 L:108
  _WSAETOOMANYREFS = 'Too many references can''t splice'; // 10059 L:109
  _WSAETIMEDOUT = 'Connection timed out'; // 10060 L:110
  _WSAECONNREFUSED = 'Connection refused'; // 10061 L:111
  _WSAELOOP = 'Too many levels of symbolic links'; // 10062 L:40
  _WSAENAMETOOLONG = 'File name too long'; // 10063 L:36
  _WSAEHOSTDOWN = 'Host is down'; // 10064 L:112
  _WSAEHOSTUNREACH = 'No route to host'; // 10065 L:113
  _WSAENOTEMPTY = 'Directory not empty'; // 10066 L:39
  _WSAEPROCLIM = 'Too many processes'; // 10067
  _WSAEUSERS = 'Too many users'; // 10068 L:87
  _WSAEDQUOT = 'Disk quota exceeded'; // 10069 L:122
  _WSAESTALE = 'Stale NFS file handle'; // 10070 L:116
  _WSAEREMOTE = 'Too many levels of remote in path'; // 10071 L:66
  _WSASYSNOTREADY = 'Network sub-system is unusable'; // 10091
  _WSAVERNOTSUPPORTED = 'WSOCK32.DLL DLL cannot support this application'; // 10092
  _WSANOTINITIALISED = 'WSOCK32.DLL not initialized'; // 10093
  _WSAHOST_NOT_FOUND = 'Host not found'; // 11001 L:1
  _WSATRY_AGAIN = 'Non-authoritative host not found'; // 11002 L:2
  _WSANO_RECOVERY = 'Non-recoverable error'; // 11003 L:3
  _WSANO_DATA = 'No Data'; // 11004 L:4
  _WSAUNKNOWN = 'Unknown Socket Error';

const
  Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  AlphabetLength = 64;
{$IFDEF VER100}
  TIME_ZONE_ID_STANDARD = 1;
  TIME_ZONE_ID_DAYLIGHT = 2;
{$ENDIF}
{$IFNDEF VER90}
  ole32 = 'ole32.dll';
{$ENDIF}
  crc_32_tab: array[0..255] of LONGINT = (
    $00000000, $77073096, $EE0E612C, $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3,
    $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
    $1DB71064, $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
    $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
    $3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
    $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
    $26D930AC, $51DE003A, $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
    $2802B89E, $5F058808, $C60CD9B2, $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
    $76DC4190, $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
    $7807C9A2, $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
    $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
    $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
    $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
    $4369E96A, $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
    $5005713C, $270241AA, $BE0B1010, $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F,
    $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
    $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
    $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
    $F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB, $196C3671, $6E6B06E7,
    $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
    $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
    $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
    $CB61B38C, $BC66831A, $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F,
    $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
    $9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713,
    $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
    $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
    $88085AE6, $FF0F6A70, $66063BCA, $11010B5C, $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
    $A00AE278, $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB,
    $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
    $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF,
    $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);
  crc_arc_tab: array[0..$FF] of Word =
  ($00000, $0C0C1, $0C181, $00140, $0C301, $003C0, $00280, $0C241,
    $0C601, $006C0, $00780, $0C741, $00500, $0C5C1, $0C481, $00440,
    $0CC01, $00CC0, $00D80, $0CD41, $00F00, $0CFC1, $0CE81, $00E40,
    $00A00, $0CAC1, $0CB81, $00B40, $0C901, $009C0, $00880, $0C841,
    $0D801, $018C0, $01980, $0D941, $01B00, $0DBC1, $0DA81, $01A40,
    $01E00, $0DEC1, $0DF81, $01F40, $0DD01, $01DC0, $01C80, $0DC41,
    $01400, $0D4C1, $0D581, $01540, $0D701, $017C0, $01680, $0D641,
    $0D201, $012C0, $01380, $0D341, $01100, $0D1C1, $0D081, $01040,
    $0F001, $030C0, $03180, $0F141, $03300, $0F3C1, $0F281, $03240,
    $03600, $0F6C1, $0F781, $03740, $0F501, $035C0, $03480, $0F441,
    $03C00, $0FCC1, $0FD81, $03D40, $0FF01, $03FC0, $03E80, $0FE41,
    $0FA01, $03AC0, $03B80, $0FB41, $03900, $0F9C1, $0F881, $03840,
    $02800, $0E8C1, $0E981, $02940, $0EB01, $02BC0, $02A80, $0EA41,
    $0EE01, $02EC0, $02F80, $0EF41, $02D00, $0EDC1, $0EC81, $02C40,
    $0E401, $024C0, $02580, $0E541, $02700, $0E7C1, $0E681, $02640,
    $02200, $0E2C1, $0E381, $02340, $0E101, $021C0, $02080, $0E041,
    $0A001, $060C0, $06180, $0A141, $06300, $0A3C1, $0A281, $06240,
    $06600, $0A6C1, $0A781, $06740, $0A501, $065C0, $06480, $0A441,
    $06C00, $0ACC1, $0AD81, $06D40, $0AF01, $06FC0, $06E80, $0AE41,
    $0AA01, $06AC0, $06B80, $0AB41, $06900, $0A9C1, $0A881, $06840,
    $07800, $0B8C1, $0B981, $07940, $0BB01, $07BC0, $07A80, $0BA41,
    $0BE01, $07EC0, $07F80, $0BF41, $07D00, $0BDC1, $0BC81, $07C40,
    $0B401, $074C0, $07580, $0B541, $07700, $0B7C1, $0B681, $07640,
    $07200, $0B2C1, $0B381, $07340, $0B101, $071C0, $07080, $0B041,
    $05000, $090C1, $09181, $05140, $09301, $053C0, $05280, $09241,
    $09601, $056C0, $05780, $09741, $05500, $095C1, $09481, $05440,
    $09C01, $05CC0, $05D80, $09D41, $05F00, $09FC1, $09E81, $05E40,
    $05A00, $09AC1, $09B81, $05B40, $09901, $059C0, $05880, $09841,
    $08801, $048C0, $04980, $08941, $04B00, $08BC1, $08A81, $04A40,
    $04E00, $08EC1, $08F81, $04F40, $08D01, $04DC0, $04C80, $08C41,
    $04400, $084C1, $08581, $04540, $08701, $047C0, $04680, $08641,
    $08201, $042C0, $04380, $08341, $04100, $081C1, $08081, $04040);
  crc_16_tab: array[0..$FF] of Word =
  ($00000, $01021, $02042, $03063, $04084, $050A5, $060C6, $070E7,
    $08108, $09129, $0A14A, $0B16B, $0C18C, $0D1AD, $0E1CE, $0F1EF,
    $01231, $00210, $03273, $02252, $052B5, $04294, $072F7, $062D6,
    $09339, $08318, $0B37B, $0A35A, $0D3BD, $0C39C, $0F3FF, $0E3DE,
    $02462, $03443, $00420, $01401, $064E6, $074C7, $044A4, $05485,
    $0A56A, $0B54B, $08528, $09509, $0E5EE, $0F5CF, $0C5AC, $0D58D,
    $03653, $02672, $01611, $00630, $076D7, $066F6, $05695, $046B4,
    $0B75B, $0A77A, $09719, $08738, $0F7DF, $0E7FE, $0D79D, $0C7BC,
    $048C4, $058E5, $06886, $078A7, $00840, $01861, $02802, $03823,
    $0C9CC, $0D9ED, $0E98E, $0F9AF, $08948, $09969, $0A90A, $0B92B,
    $05AF5, $04AD4, $07AB7, $06A96, $01A71, $00A50, $03A33, $02A12,
    $0DBFD, $0CBDC, $0FBBF, $0EB9E, $09B79, $08B58, $0BB3B, $0AB1A,
    $06CA6, $07C87, $04CE4, $05CC5, $02C22, $03C03, $00C60, $01C41,
    $0EDAE, $0FD8F, $0CDEC, $0DDCD, $0AD2A, $0BD0B, $08D68, $09D49,
    $07E97, $06EB6, $05ED5, $04EF4, $03E13, $02E32, $01E51, $00E70,
    $0FF9F, $0EFBE, $0DFDD, $0CFFC, $0BF1B, $0AF3A, $09F59, $08F78,
    $09188, $081A9, $0B1CA, $0A1EB, $0D10C, $0C12D, $0F14E, $0E16F,
    $01080, $000A1, $030C2, $020E3, $05004, $04025, $07046, $06067,
    $083B9, $09398, $0A3FB, $0B3DA, $0C33D, $0D31C, $0E37F, $0F35E,
    $002B1, $01290, $022F3, $032D2, $04235, $05214, $06277, $07256,
    $0B5EA, $0A5CB, $095A8, $08589, $0F56E, $0E54F, $0D52C, $0C50D,
    $034E2, $024C3, $014A0, $00481, $07466, $06447, $05424, $04405,
    $0A7DB, $0B7FA, $08799, $097B8, $0E75F, $0F77E, $0C71D, $0D73C,
    $026D3, $036F2, $00691, $016B0, $06657, $07676, $04615, $05634,
    $0D94C, $0C96D, $0F90E, $0E92F, $099C8, $089E9, $0B98A, $0A9AB,
    $05844, $04865, $07806, $06827, $018C0, $008E1, $03882, $028A3,
    $0CB7D, $0DB5C, $0EB3F, $0FB1E, $08BF9, $09BD8, $0ABBB, $0BB9A,
    $04A75, $05A54, $06A37, $07A16, $00AF1, $01AD0, $02AB3, $03A92,
    $0FD2E, $0ED0F, $0DD6C, $0CD4D, $0BDAA, $0AD8B, $09DE8, $08DC9,
    $07C26, $06C07, $05C64, $04C45, $03CA2, $02C83, $01CE0, $00CC1,
    $0EF1F, $0FF3E, $0CF5D, $0DF7C, $0AF9B, $0BFBA, $08FD9, $09FF8,
    $06E17, $07E36, $04E55, $05E74, $02E93, $03EB2, $00ED1, $01EF0);

///////////////////////////////////////////////////////////////////////////////
// Internal Version Control Routines (used for DCU's mainly)
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Windows/Operating System Routines
///////////////////////////////////////////////////////////////////////////////

procedure ProcessWindowsMessageQueue;
{$IFDEF LINUX}
begin
  Application.ProcessMessages;
end;
{$ELSE}
var
  MsgRec: TMsg;

begin
  if not IsConsole then
    while PeekMessage(MsgRec, 0, 0, 0, PM_REMOVE) do begin
      TranslateMessage(MsgRec);
      DispatchMessage(MsgRec)
    end;
end;
{$ENDIF}

function HiByteOfWord(const W: Word): Byte;
begin
  Result := Hi(W);
end;


procedure UNPACKTIME(const P: LONGINT; var DT: TDATETIME);
begin
  DT := FILEDATETODATETIME(P);
end;

procedure PACKTIME(var DT: TDATETIME; var P: LONGINT);
begin
  P := DATETIMETOFILEDATE(DT);
end;

function GetDosDate: LongInt;
begin
  Result := DATETIMETOFILEDATE(Now);
end;

function GetDOW: Word;
begin
  Result := DayOfWeek(Now);
end;

function TimeCounter: Comp;
begin
  Result := TimeStampToMSecs(DateTimeToTimeStamp(Now));
end;

function TimeOut(const MyTime: Comp): Boolean;
begin
  Result := MyTime <= TimeCounter;
end;



function AddBackSlash(const S: string): string;
begin
  Result := S;
  if Copy(Result, Length(Result), 1) <> '\' then Result := Result + '\';
end;

function NoBackSlash(const S: string): string;
var
  I: Integer;

begin
  Result := S;
  I := Length(S);
  if I > 0 then
    if Result[I] = '\' then Delete(Result, Length(Result), 1);
end;





function MakeBytesToWord(const A, B: Byte): Word;
begin
  Result := (A shl 8) + B;
end;

function WindowsWriteFile(hFile: THandle; const Buffer; nNumberOfBytesToWrite: DWORD;
  var lpNumberOfBytesWritten: DWORD): Boolean;
begin
{$IFDEF LINUX}
  lpNumberOfBytesWritten := FileWrite(hFile, Buffer, nNumberOfBytesToWrite);
  Result := lpNumberOfBytesWritten = nNumberOfBytesToWrite;
{$ELSE}
  Result := WriteFile(hFile, Buffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, nil);
{$ENDIF}
end;

procedure ShowMessageWindow(const Caption, Message: string);
begin
{$IFDEF LINUX}
  MessageDlg(Caption, Message, mtError, [mbOk], 0);
{$ELSE}
  MessageBox(0, PChar(Message), PChar(Caption), MB_ICONEXCLAMATION or MB_SYSTEMMODAL);
{$ENDIF}
end;

procedure DoSleepEX(const Interval: DWord);
begin
{$IFDEF LINUX}
  Sleep(Interval);
{$ELSE}
  SleepEx(Interval, False {True});
{$ENDIF}
end;




{$IFDEF LINUX}

function CoCreateGuid(var GUID: TGUID): HResult;
begin
  Result := CreateGUID(GUID);
end;
{$ENDIF}

///////////////////////////////////////////////////////////////////////////////
// Numeric Routines
///////////////////////////////////////////////////////////////////////////////

function IsCharAlphaNumeric(const C: char): Boolean;
begin
{$IFNDEF ASM8086}
  Result := C in ['0'..'9', 'A'..'Z', 'a'..'z'];
{$ELSE}
  asm
   mov AL,C
   cmp AL, $30   // 0
   jl @NoMatch   // it's before '0' so Result=False/Exit
   cmp AL, $7A   // z
   jg @NoMatch   // it's after 'z' so Result=False/Exit
   cmp AL, $39   // 9
   jg @TryAlpha  // it's after '9' so see if it is Alpha now
   jmp @Matched  // it's 0..9 so Result=True/Exit
@TryAlpha:
   cmp AL, $41   // A
   jl @NoMatch   // it's before 'A' so Result=False/Exit
   cmp AL, $5A   // Z
   jg @TryLower  // it's after 'Z' so see if it is lowecase Alpha
   jmp @Matched  // it's 'A'..'Z' so Result=True/Exit
@TryLower:
   cmp AL, $61   // a
   jl @NoMatch   // it's before 'a' so Result=False/Exit
   jmp @Matched  // it's 'a'..'z' so Result=True/Exit
@NoMatch:
   mov Result,0
   jmp @TheEnd
@Matched:
   mov Result,1
@TheEnd:
   end{asm}
{$ENDIF}
  end;

function IsCharAlpha(const c: Char): Boolean;
begin
{$IFNDEF ASM8086}
  Result := C in ['A'..'Z', 'a'..'z'];
{$ELSE}
  asm
   mov AL,C
   cmp AL, $41   // A
   jl @NoMatch   // it's before 'A' so Result=False/Exit
   cmp AL, $7A   // z
   jg @NoMatch   // it's after 'z' so Result=False/Exit
   cmp AL, $5A   // Z
   jg @TryLower  // it's after 'Z' so see if it is lower now
   jmp @Matched  // it's A..Z so Result=True/Exit
@TryLower:
   cmp AL, $61   // a
   jl @NoMatch   // it's before 'a' so Result=False/Exit
   jmp @Matched  // it's 'a'..'z' so Result=True/Exit
@NoMatch:
   mov Result,0
   jmp @TheEnd
@Matched:
   mov Result,1
@TheEnd:
   end{asm}
{$ENDIF}
  end;

function IsNumeric(const c: char): Boolean;
begin
{$IFNDEF ASM8086}
  Result := IsCharAlphaNumeric(c) and not IsCharAlpha(c);
{$ELSE}
  asm
   mov AL,C
   cmp AL, $30   // 0
   jl @NoMatch   // it's before '0' so Result=False/Exit
   cmp AL, $39   // 9
   jg @NoMatch   // it's after '9' so Result=False/Exit
   jmp @Matched  // it's 0..9 so Result=True/Exit
@NoMatch:
   mov Result,0
   jmp @TheEnd
@Matched:
   mov Result,1
@TheEnd:
   end{asm}
{$ENDIF}
  end;

function isNumericString(const S: string): Boolean;
var
  Loop, MaxLoop: Integer;

begin
  Result := True;
  MaxLoop := Length(S);
  Loop := 0;
  while (Loop < MaxLoop) and (Result) do begin
    if S[Loop + 1] <> '.' then
      Result := IsNumeric(S[Loop + 1]);
    Inc(Loop);
  end;
end;

function Min(const I1, I2: Integer): Integer;
begin
{$IFNDEF ASM8086}
  if I1 < I2 then
    Result := I1
  else
    Result := I2;
{$ELSE}
  Result := I1;
  asm
   mov ECX, I2    // Store I2 in ECX
   mov EDX, I1    // Store I1 in EDX
   cmp EDX, ECX   // compare I2 to I1
   jl @TheEnd     // if I2<I1 then Exit {result already set}
@ItIsLess:
   mov Result,ECX // result=I2/Exit
@TheEnd:
  end; {asm}
{$ENDIF}
end;

function Max(const I1, I2: Integer): Integer;

begin
{$IFNDEF ASM8086}
  if I1 > I2 then
    Result := I1
  else
    Result := I2;
{$ELSE}
  Result := I1;
  asm
   mov ECX, I2    // Store I2 in ECX
   mov EDX, I1    // Store I1 in EDX
   cmp EDX, ECX   // compare I2 to I1
   jg @TheEnd     // if I2>I1 then Exit {result already set}
@ItIsLess:
   mov Result,ECX // result=I2/Exit
@TheEnd:
  end; {asm}
{$ENDIF}
end;

function StringToInteger(const S: string): Integer;
var
  E: Integer;

begin
  Val(S, Result, E);
end;

procedure SwapMove(Source: Word; var Dest);
begin
  Source := (HI(Source)) + (LO(Source) * 256);
  Move(Source, Dest, 2);
end;

function IntToCommaStr(const Number: Integer): string;
var
  StrPos: Integer;

begin
  Result := IntToStr(Number);
  StrPos := Length(Result) - 2;
  while StrPos > 1 do begin
    Insert(',', Result, StrPos);
    StrPos := StrPos - 3;
  end;
end;

function BinaryToString(const Number: Byte): string;
var
  Temp2: Byte;
  i: Word;

begin
  Setlength(Result, 8);
  FillChar(Result[1], 8, '0');
  Temp2 := $80;
  for i := 1 to 8 do begin
    if (Number and Temp2) <> 0 then Result[i] := '1';
    Temp2 := Temp2 shr 1;
  end;
end;

function StringToBinary(S: string): Byte;
var
  i: Word;
  Temp1: Byte;
  Temp2: Byte;

begin
  S := Trim(S);
  while Length(S) < 8 do
    S := '0' + S;
  Temp1 := 0;
  Temp2 := $80;
  for i := 1 to 8 do begin
    if S[i] = '1' then Inc(Temp1, Temp2);
    Temp2 := Temp2 shr 1;
  end;
  Result := Temp1;
end;



//==============================================================================
type
  CharSet = set of Char;

function Center(S: string; MaxWidth: Integer): string;
var
  I: Integer;
  Ws: string;

begin
  if Length(S) mod 2 = 0 then
    Result := S
  else
    Result := S + #32;
  if Length(Result) >= MaxWidth then Exit;
  I := MaxWidth - Length(Result);
  if I mod 2 <> 0 then begin
    Result := Result + #32;
    Dec(I);
  end;
  if I > 0 then begin
    SetLength(Ws, I div 2);
    FillChar(Ws[1], I div 2, #32);
    Result := Ws + Result + Ws;
  end;
end;

function LeftJustifyCh(const S: string; const Ch: Char; const MaxLength: Integer): string;
begin
  if MaxLength < Length(S) then begin
    Result := Copy(S, 1, MaxLength);
    Exit;
  end;
  SetLength(Result, MaxLength);
  FillChar(Result[1], MaxLength, Ch);
  Move(S[1], Result[1], Min(MaxLength, Length(S)));
end;

function RightJustifyCh(const S: string; const Ch: Char; const MaxLength: Integer): string;
begin
  if MaxLength < Length(S) then begin
    Result := Copy(S, 1, MaxLength);
    Exit;
  end;
  SetLength(Result, MaxLength);
  FillChar(Result[1], MaxLength, Ch);
  Move(S[1], Result[MaxLength - Pred(Length(S))], Min(MaxLength, Length(S)));
end;

function EncodeTabs(S: string; TabSize: Byte): string;
var
  Ws: string;

begin
  Setlength(Ws, Tabsize);
  FillChar(Ws[1], TabSize, #32);
  Result := StringReplace(S, Ws, #9, [rfReplaceAll]);
end;

function DecodeTabs(S: string; TabSize: Byte): string;
var
  Ws: string;

begin
  Setlength(Ws, Tabsize);
  FillChar(Ws[1], TabSize, #32);
  Result := StringReplace(S, #9, Ws, [rfReplaceAll]);
end;

function Filter(S: string; CS: CharSet): string;
var
  Loop: Integer;

begin
  Result := '';
  for Loop := 1 to Length(S) do begin
    if not (S[Loop] in CS) then begin
      Result := Result + S[Loop];
    end;
  end;
end;

function SoundEx(S: string): string;
const
  Table: array[1..26] of Char = '.123.12..22455.12623.1.2.2';

var
  SoundString: string[255];
  I1: Integer;
  I2: Integer;
  isNum: boolean;
  Ch: Char;

begin
  Result := S;
  if S = '' then Exit;
  isNum := true;
  repeat
    Ch := UpCase(S[1]);
    if Ch > #64 then
      isNum := false
    else
      Delete(S, 1, 1);
  until (isNum = false) or (S = '');
  Result := S;
  if S = '' then Exit;
  SoundString[0] := #255;
  FillChar(SoundString[1], 255, '0');
// Step 1: ASCII to Soundex
  for I1 := 1 to Length(S) - 1 do begin
    I2 := Ord(UpCase(S[I1 + 1])) - 64;
    if ((I2 < 1) or (I2 > 26)) then I2 := 1;
    SoundString[I1] := Table[I2];
  end;
// Initialize for second pass
  I1 := 1;
  repeat
    while (SoundString[I1] = '.') do
      Delete(SoundString, I1, 1);
    while ((SoundString[I1] = SoundString[I1 + 1]) and (SoundString[I1] <> '0')) do
      Delete(SoundString, I1, 1);
    Inc(I1);
  until (SoundString[I1] = '0');
  Result := Ch + Copy(SoundString, 1, 3);
end;



function QuickPos(const aFindString, aSourceString: string): integer;
var
  SourceLen, aSourceLen, aFindLen, StartPos: integer;

begin
{$IFNDEF ASM8086}
  Result := Pos(aFindString, aSourceString);
{$ELSE}
  Result := 0;
  aSourceLen := Length(aSourceString);
  if aSourceLen = 0 then Exit;
  aFindLen := Length(aFindString);
  if (aFindLen = 0) or (aFindlen > AsourceLen) then Exit; {GSW FIX!}
  StartPos := 1;
  SourceLen := aSourceLen - aFindLen;
  SourceLen := (SourceLen - StartPos) + 2;

  asm
   push ESI
   push EDI
   push EBX
   mov EDI, aSourceString
   add EDI, StartPos
   dec EDI
   mov ESI, aFindString
   mov ECX, SourceLen
   mov Al, [ESI]
@ScaSB:
   mov Ah, [EDI]
   cmp Ah,Al
   jne @NextChar
@CompareStrings:
   mov EBX, aFindLen
   dec EBX
   jz @FullMatch
@CompareNext:
   mov Al, [ESI+EBX]
   mov Ah, [EDI+EBX]
   cmp Al, Ah
   jz @Matches
   mov Al, [ESI]
   jmp @NextChar
@Matches:
   dec EBX
   jnz @CompareNext
@FullMatch:
   mov EAX, EDI
   sub EAX, aSourceString
   inc EAX
   mov Result, EAX
   jmp @TheEnd
@NextChar:
   inc EDI
   dec ECX
   jnz @ScaSB
   mov Result,0
@TheEnd:
   pop EBX
   pop EDI
   pop ESI
  end; {asm}
{$ENDIF}
end;

function CharPos(const C: Char; const aSource: string): Integer;
var
  L: Integer;
begin
  L := Length(aSource);
  Result := 0;
  if L = 0 then exit;

  asm
  PUSH EDI                 //Preserve this register
  mov  EDI, aSource        //Point EDI at aSource
  mov  ECX, L              //Make a note of how many chars to search through
  mov  AL,  C              //and which char we want
@Loop:
  mov  AH, [EDI]
  inc  EDI
  xor  AH, AL
  jz   @Found
  dec  ECX
  jnz  @Loop
  jmp  @NotFound
@Found:
  sub  EDI, aSource        //EDI has been incremented, so EDI-OrigAdress = Char pos !
  mov  Result,   EDI
  jmp @TheEnd
@NotFound:
  mov  Result, 0 // fix (ozz)
@TheEnd:
  POP  EDI
  end;
end;

function Fetch(var S: string; const Sub: string; const IgnoreCase: Boolean): string;
var
  P: Integer;

begin
  if IgnoreCase then
    P := QuickPos(Uppercase(Sub), Uppercase(S))
  else
    P := QuickPos(Sub, S);
  if (P = 0) then begin
    Result := S;
    S := '';
  end
  else begin
    Result := Copy(S, 1, P - 1);
    Delete(S, 1, P + (Length(Sub) - 1));
  end;
end;

function FetchByChar(var S: string; const Sub: Char; const IgnoreCase: Boolean): string;
var
  P: Integer;

begin
  if IgnoreCase then
    P := CharPos(Upcase(Sub), Uppercase(S))
  else
    P := CharPos(Sub, S);
  if (P = 0) then begin
    Result := S;
    S := '';
  end
  else begin
    Result := Copy(S, 1, P - 1);
    Delete(S, 1, P);
  end;
end;

function Uppercase(const S: string): string;
{$IFNDEF ASM8086}
var
  Loop: Integer;
  MaxLoop: Integer;

begin
  Result := S;
  MaxLoop := Length(Result);
  for Loop := MaxLoop downto 1 do
    if Result[Loop] in ['a'..'z'] then Dec(Result[Loop], 32);
end;
{$ELSE}
var
  LenOfString: Integer;
  FirstSource, FirstDest: Pointer;

  begin
    LenOfString := Length(S);
    if LenOfString = 0 then begin
      Result := '';
      Exit;
    end;
    SetLength(Result, LenOfString);
    FirstSource := Pointer(s);
    FirstDest := Pointer(Result);
    asm
   PUSH ESI            //Firstly and most importantly
   PUSH EDI            //Delphi uses EBX, ESI, EDI extensively, so we need to
                       //push them onto the stack, and then pop them off after
   mov ESI, FirstSource//Move the address of Result into ESI
   mov EDI, FirstDest  //ESI and EDI are 2 generic "data moving" registers
                       //ESI = Source, EDI = Destination
                       //MovSB (MoveString Byte, there is also, MovSW word and MovSD double)
                       //MovXX copy from EDI to ESI, and then INC *both* ESI and EDI
                       //  and also DEC ECX (generic string length counter)
                       //But I will not use these as I need to Uppercase the results
   mov ECX, LenOfString//ECX will contain a count of how many chars left to do
@NextChar:
   mov AL, [ESI]       //Move ESI^ into AL
                       //  AL = Char, AX = Word, EAX = DWord, all different parts
                       //  of the same register
   cmp AL, $61
   jl  @NoUpper        // < 'a' don't convert
   cmp AL, $7A
   jg  @NoUpper        // > 'z' don't convert
   and AL, $DF         // Convert to uppercase
@NoUpper:
   mov [EDI], AL       // Put AL back into EDI^  (That's what [] means)
   Inc ESI             //Point to next character
   Inc EDI
   Dec ECX             //Decrement the count, if it reaches 0, the ZERO flag will be set
   jnz @NextChar       //"J"ump if "n"ot "z"ero to the next character
   POP EDI
   POP ESI
    end; {asm}
  end;
{$ENDIF}

function Lowercase(const S: string): string;
{$IFNDEF ASM8086}
var
  Loop: Integer;
  MaxLoop: Integer;

begin
  Result := S;
  MaxLoop := Length(Result);
  for Loop := MaxLoop downto 1 do
    if Result[Loop] in ['A'..'Z'] then Inc(Result[Loop], 32);
end;
{$ELSE}
var
  LenOfString: Integer;
  FirstSource, FirstDest: Pointer;

  begin
    LenOfString := Length(S);
    if LenOfString = 0 then begin
      Result := '';
      Exit;
    end;
    SetLength(Result, LenOfString);
    FirstSource := Pointer(S);
    FirstDest := Pointer(Result);
    asm
   PUSH ESI            //Firstly and most importantly
   PUSH EDI            //Delphi uses EBX, ESI, EDI extensively, so we need to
                       //push them onto the stack, and then pop them off after
   mov ESI, FirstSource//Move the address of Result into ESI
   mov EDI, FirstDest  //ESI and EDI are 2 generic "data moving" registers
                       //ESI = Source, EDI = Destination
                       //MovSB (MoveString Byte, there is also, MovSW word and MovSD double)
                       //MovXX copy from EDI to ESI, and then INC *both* ESI and EDI
                       //  and also DEC ECX (generic string length counter)
                       //But I will not use these as I need to Uppercase the results
   mov ECX, LenOfString//ECX will contain a count of how many chars left to do
@NextChar:
   mov AL, [ESI]       //Move ESI^ into AL
                       //  AL = Char, AX = Word, EAX = DWord, all different parts
                       //  of the same register
   cmp AL, 'A'
   jl  @NoUpper        // < 'a' don't convert
   cmp AL, 'Z'
   jg  @NoUpper        // > 'z' don't convert
   xor AL, $20         // Convert to lowercase
@NoUpper:
   mov [EDI], AL       // Put AL back into EDI^  (That's what [] means)
   Inc ESI             //Point to next character
   Inc EDI
   Dec ECX             //Decrement the count, if it reaches 0, the ZERO flag will be set
   jnz @NextChar       //"J"ump if "n"ot "z"ero to the next character
   POP EDI
   POP ESI
    end; {asm}
  end;
{$ENDIF}

function ProperCase(const S: string): string;
var
  Len: Integer;
  MaxLen: Integer;

begin
  Len := Length(S);
  MaxLen := Len;
  SetLength(Result, Len);
  Result := Lowercase(S);
  while Len > 0 do begin
    if not (Result[Len] in ['a'..'z']) and (Len < MaxLen) then
      Result[Len + 1] := Upcase(Result[Len + 1]);
    Dec(Len);
  end;
  if (MaxLen > 0) and (Result[1] in ['a'..'z']) then
    Result[1] := Upcase(Result[1]);
end;

function Trim(const S: string): string;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do
    Inc(I);
  if I > L then
    Result := ''
  else begin
    while S[L] <= ' ' do
      Dec(L);
    Result := Copy(S, I, L - I + 1);
  end;
end;

function NoCRLF(const S: string): string;
begin
  Result := StringReplace(S, #13#10, '', [rfReplaceAll]);
end;

function NoAngleBrackets(const S: string): string;
var
  LenOfStr: Integer;

begin
  Result := S;
  LenOfStr := Length(Result);
  if LenOfStr > 1 then
    if (Result[1] = '<') and (Result[LenOfStr] = '>') then
      Result := Copy(Result, 2, LenOfStr - 2);
end;

// Known Commands should be a 0 based array!
// For testing Winshoes products against ours, this command is useless to our
// engine. We use a dynamic parser which provides a much more flexible
// development solution for you.

function InStrArray(const SearchStr: string; const KnownCommands: array of string): Integer;
begin
  for Result := High(KnownCommands) downto Low(KnownCommands) do
    if SearchStr = KnownCommands[Result] then Exit;
  Result := -1;
end;

procedure InverseString(var S: string; Count: Integer);
var
  TmpStr: string;
  Ctr: Integer;
  Ch: Char;

begin
  TmpStr := Copy(S, 1, Count);
  Ctr := 0;
  while Count > 0 do begin
    Ch := TmpStr[Count];
    Dec(Count);
    Move(Ch, S[Ctr + 1], 1);
    Inc(Ctr);
  end;
end;

function HexDump(const S: string): string;
var
  Loop: Integer;
  MaxLoop: Integer;

begin
  Result := '';
  Loop := 0;
  MaxLoop := Length(S);
  while Loop < MaxLoop do begin
    Result := Result + IntToHex(Ord(S[Loop + 1]), 2) + #32;
    Inc(Loop);
  end;
end;

function ReplaceChar(const Source: string; const OldChar, NewChar: Char): string;
var
  Loop: Integer;

begin
  Result := Source;
  if OldChar = NewChar then Exit;
  Loop := Length(Source);
  while Loop > 0 do begin
    if Result[Loop] = OldChar then Result[Loop] := NewChar;
    Dec(loop);
  end;
end;

function ExtractLeft(const aSourceString: string; const Size: Integer): string;
begin
  if Size > Length(aSourceString) then
    Result := aSourceString
  else begin
    Setlength(Result, Size);
    Move(aSourceString[1], Result[1], Size);
  end;
end;

function ExtractRight(const aSourceString: string; const Size: Integer): string;
var
  Len: Integer;

begin
  Len := Length(aSourceString);
  if Size > Len then
    Result := aSourceString
  else begin
    Setlength(Result, Size);
    Move(aSourceString[Len - Pred(Size)], Result[1], Size);
  end;
end;

function ExtractWordAt(const Text: string; Position: Integer): string;
var
  Done: Boolean;
  StartAt: Integer;
  Len: Integer;
  OrgPosition: Integer;

begin
  Len := Length(Text);
  Result := '';
  Done := not (UpCase(Text[Position]) in ['A'..'Z', '0'..'9']);
  if (Position > 0) and (Position <= Len) and not Done then begin
    OrgPosition := Position;
    while (Position > 0) and not Done do begin
      Done := not (UpCase(Text[Position]) in ['A'..'Z', '0'..'9']);
      if not Done then Dec(Position);
    end;
    StartAt := Position;
    Position := OrgPosition;
    Done := False;
    while (Position <= Len) and not Done do begin
      Done := not (UpCase(Text[Position]) in ['A'..'Z', '0'..'9']);
      if not Done then Inc(Position);
    end;
    Result := Copy(Text, StartAt + 1, Pred(Position) - StartAt);
  end;
end;

function LeftJustify(const S: string; const MaxLength: Integer): string;
begin
  Result := LeftJustifyCh(S, #32, MaxLength);
end;

function RightJustify(const S: string; const MaxLength: Integer): string;
begin
  Result := RightJustifyCh(S, #32, MaxLength);
end;

function CleanChar(const InChar: Char): Char;
const
  CtlChars: string[32] = 'oooooooooXoollo><|!Pg*|^v><-^v';
  HiChars: string[64] = 'CueaaaageeeiiiAAEaaooouuyOUcLYPfarounNao?--//!<>***|||||||||||||';
  HiChars2: string[64] = '|--|-+||||=+|=++-=--==-||||*****abcnEduto0nd80En=+><fj/~oo.vn2* ';

begin
  case InChar of
    #0..#31: Result := CtlChars[Ord(InChar) + 1];
    #128..#191: Result := HiChars[Ord(InChar) - 127];
    #192..#255: Result := HiChars2[Ord(InChar) - 191];
  else
    Result := InChar;
  end;
end;

function CleanStr(const InStr: string): string;
begin
  Result := '';
  while Length(Result) < Length(InStr) do
    Result := Result + CleanChar(InStr[Length(Result) + 1]);
end;

function PosLastChar(const Ch: Char; const S: string): Integer;
var
  I: Integer;

begin
  i := Length(S);
  while ((i > 0) and (s[i] <> ch)) do
    Dec(i);
  Result := I;
end;

function AsciiToOem(const ax: string): string;
var
  i: integer;

begin
  Result := AX;
  for i := Length(Result) downto 1 do begin
    case Ord(Result[i]) of
      132: Result[i] := Char(228);
      142: Result[i] := Char(196);
      129: Result[i] := Char(252);
      154: Result[i] := Char(220);
      148: Result[i] := Char(246);
      153: Result[i] := Char(214);
      225: Result[i] := Char(223);
    end;
  end;
end;

function OemToAscii(const ax: string): string;
var
  i: integer;

begin
  Result := AX;
  for i := Length(Result) downto 1 do begin
    case Ord(Result[i]) of
      228: Result[i] := Char(132);
      196: Result[i] := Char(142);
      252: Result[i] := Char(129);
      220: Result[i] := Char(154);
      246: Result[i] := Char(148);
      214: Result[i] := Char(153);
      223: Result[i] := Char(225);
    end;
  end;
end;

function WordCount(const S: string): Integer;
var
  I, Len: Integer;

begin
  Len := Length(S);
  Result := 0;
  I := 1;
  while I <= Len do begin
    while (i <= len) and ((S[i] = #32) or (S[i] = #9) or (S[i] = ';')) do
      inc(i);
    if I <= len then inc(Result);
    while (I <= len) and (S[i] <> #32) and (S[i] <> #9) and (S[i] <> ';') do
      inc(i);
  end;
end;

function CRC32ByChar(const Ch: Char; const starting_crc: LONGINT): LONGINT;
begin
  Result := crc_32_tab[BYTE(starting_crc xor LONGINT(Ord(Ch)))] xor ((starting_crc shr 8) and $00FFFFFF);
end;

function CRC32ByString(const S: string; const starting_crc: LONGINT): LONGINT;
var
  Loop: Integer;
  MaxLoop: Integer;

begin
  Result := starting_crc;
  MaxLoop := Length(S);
  for Loop := 1 to MaxLoop do
//      Result:=CRC32ByChar(S[Loop],Result);
    Result := crc_32_tab[BYTE(Result xor LONGINT(Ord(S[Loop])))] xor ((Result shr 8) and $00FFFFFF);
end;

function CRC16ByChar(const Ch: Char; const starting_crc: word): word;
begin
  Result := crc_16_tab[BYTE(starting_crc xor Word(Ord(Ch)))] xor ((starting_crc shr 8) and $00FF)
end;

function CRC16ByString(const S: string; const starting_crc: word): word;
var
  Loop: Integer;
  MaxLoop: Integer;

begin
  Result := starting_crc;
  MaxLoop := Length(S);
  for Loop := 1 to MaxLoop do
//      Result:=CRC16ByChar(S[Loop],Result);
    Result := crc_16_tab[BYTE(Result xor Word(Ord(S[Loop])))] xor ((Result shr 8) and $00FF)
end;

function CRCARCByChar(const Ch: Char; const starting_crc: word): word;
begin
  Result := crc_arc_tab[BYTE(starting_crc xor Word(Ord(Ch)))] xor ((starting_crc shr 8) and $00FF)
end;

function CRCARCByString(const S: string; const starting_crc: word): word;
var
  Loop: Integer;
  MaxLoop: Integer;

begin
  Result := starting_crc;
  MaxLoop := Length(S);
  for Loop := 1 to MaxLoop do
//      Result:=CRCARCByChar(S[Loop],Result);
    Result := crc_arc_tab[BYTE(Result xor Word(Ord(S[Loop])))] xor ((Result shr 8) and $00FF)
end;


procedure SetLongBit(var L: LongInt; const Bit: Byte; const Setting: Boolean);
var
  Mask: LongInt;

begin
  Mask := 1;
  Mask := Mask shl (Bit - 1);
  if Setting then
    L := L or Mask
  else
    L := (L and (not Mask));
end;

function GetLongBit(const L: LongInt; const Bit: Byte): Boolean;
var
  Mask: LongInt;

begin
  Mask := 1;
  Mask := Mask shl (Bit - 1);
  Result := (L and Mask) <> 0;
end;

procedure SetWordBit(var L: Word; const Bit: Byte; const Setting: Boolean);
var
  Mask: Word;

begin
  Mask := 1;
  Mask := Mask shl (Bit - 1);
  if Setting then
    L := L or Mask
  else
    L := (L and (not Mask));
end;

function GetWordBit(const L: Word; const Bit: Byte): Boolean;
var
  Mask: Word;

begin
  Mask := 1;
  Mask := Mask shl (Bit - 1);
  Result := (L and Mask) <> 0;
end;

procedure SetByteBit(var L: Byte; const Bit: Byte; const Setting: Boolean);
var
  Mask: Byte;

begin
  Mask := 1;
  Mask := Mask shl (Bit - 1);
  if Setting then
    L := L or Mask
  else
    L := (L and (not Mask));
end;

function GetByteBit(const L: Byte; const Bit: Byte): Boolean;
var
  Mask: Byte;

begin
  Mask := 1;
  Mask := Mask shl (Bit - 1);
  Result := (L and Mask) <> 0;
end;

function Replicate(const Source: string; NumberOfTimes: Integer): string;
var
  SourceLength: Integer;
  Dest: Integer;

begin
  Dest := 1;
  SourceLength := Length(Source);
  SetLength(Result, SourceLength * NumberOfTimes);
  while NumberOfTimes > 0 do begin
    Move(Source[1], Result[Dest], SourceLength);
    Inc(Dest, SourceLength);
    Dec(NumberOfTimes);
  end;
end;

function IsWildCard(const Source: string): Boolean;
begin
  Result := CharPos('*', Source) + CharPos('?', Source) + CharPos('%', Source) > 0;
end;

///////////////////////////////////////////////////////////////////////////////
// Internet Routines
///////////////////////////////////////////////////////////////////////////////

function GetIndex(const c: char): Integer;
var
  i: Integer;
{$IFDEF ASM8086}
  S: string;
{$ENDIF}

begin
{$IFNDEF ASM8086}
  i := CharPos(c, Alphabet); //overkill for just 1 character
{$ELSE}
  S := Alphabet;
  asm
   PUSH EDI                 //Preserve this register
   mov  EDI, S              //Point EDI at Alphabet string
   mov  ECX, AlphaBetLength //Tell CPU how big Alphabet is
   mov  AL,  C              //and which char we want
   RepNE ScaSB              //"Rep"eat while "N"ot "E"qual
                            //this is the same as
                            //While (EDI^ <> AL) and (ECX>0) do begin
                            //  Inc(EDI);
                            //  Dec(ECX);
                            //end;
   jnz  @NotFound           //Zero flag will be set if there was a match
   sub  EDI, S              //EDI has been incremented, so EDI-OrigAdress = Char pos !
   mov  I,   EDI
@NotFound:
   POP  EDI
  end;
{$ENDIF}
  if (i > 0) then Dec(i);
  result := i;
end;

function Base64ToString(const S: string): string;
var
  i: Integer;

  function DecodeUnit(const InStr: string): ShortString;
  var
    a, b, c, d: Byte;


  begin
    a := GetIndex(InStr[1]);
    b := GetIndex(InStr[2]);
    if InStr[3] = '=' then begin
      SetLength(Result, 1);
      result[1] := chr((a shl 2) or (b shr 4));
    end
    else
      if InStr[4] = '=' then begin
        SetLength(Result, 2);
        c := GetIndex(InStr[3]);
        result[1] := chr((a shl 2) or (b shr 4));
        result[2] := chr((b shl 4) or (c shr 2));
      end
      else begin
        c := GetIndex(InStr[3]);
        d := GetIndex(InStr[4]);
        SetLength(result, 3);
        result[1] := chr((a shl 2) or (b shr 4));
        result[2] := chr((b shl 4) or (c shr 2));
        result[3] := chr((c shl 6) or d);
      end;
  end;


begin
  Result := '';
  for i := ((Length(s) div 4) - 1) downto 0 do
    Result := DecodeUnit(Copy(s, i * 4 + 1, 4)) + Result;
end;

function StringToBase64(const S1: string): string;
const
  Table: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

var
  I, K, L: Integer;
  S: string;

begin
  L := Length(S1);
  if L mod 3 <> 0 then Inc(L, 3);
  SetLength(S, (L div 3) * 4);
  FillChar(S[1], Length(S), '=');
  I := 0;
  K := 1;
  while I < Length(S1) do begin
    S[K] := Table[1 + (Ord(S1[I + 1]) shr 2)];
    S[K + 1] := Table[1 + (((Ord(S1[I + 1]) and $03) shl 4) or (Ord(S1[I + 2]) shr 4))];
    if I + 1 >= Length(S1) then Break;
    S[K + 2] := Table[1 + (((Ord(S1[I + 2]) and $0F) shl 2) or (Ord(S1[I + 3]) shr 6))];
    if I + 2 >= Length(S1) then Break;
    S[K + 3] := Table[1 + (Ord(S1[I + 3]) and $3F)];
    Inc(I, 3);
    Inc(K, 4);
  end;
  Result := S;
end;

function FixDottedIP(const S: string): string;
var
  n: Cardinal;

begin
  Result := '.' + S;
  n := QuickPos('.0', Result);
  while n > 0 do begin
    Delete(Result, n + 1, 1);
    n := QuickPos('.0', Result);
  end;
  n := QuickPos('..', Result);
  while N > 0 do begin
    Insert('0', Result, n + 1);
    n := QuickPos('..', Result);
  end;
  if Result[Length(Result)] = '.' then Result := Result + '0';
  Delete(Result, 1, 1);
end;



function IPAddressFormatted(const I1, I2, I3, I4: Integer): string;
begin
  Result := IntToStr(I4);
  while Length(Result) < 3 do
    Result := '0' + Result;
  Result := IntToStr(I3) + '.' + Result;
  while Length(Result) < 7 do
    Result := '0' + Result;
  Result := IntToStr(I2) + '.' + Result;
  while Length(Result) < 11 do
    Result := '0' + Result;
  Result := IntToStr(I1) + '.' + Result;
  while Length(Result) < 15 do
    Result := '0' + Result;
end;



function IPStringFormated(S: string): string;
var
  n1, n2, n3, n4: Integer;

begin
  N1 := StrToInt(Copy(S, 1, CharPos('.', S) - 1));
  Delete(S, 1, CharPos('.', S));
  N2 := StrToInt(Copy(S, 1, CharPos('.', S) - 1));
  Delete(S, 1, CharPos('.', S));
  N3 := StrToInt(Copy(S, 1, CharPos('.', S) - 1));
  Delete(S, 1, CharPos('.', S));
  N4 := StringToInteger(S);
  Result := IPAddressFormatted(N1, N2, N3, N4);
end;


function EscapeDecode(const S: string): string;
var
  ch: Char;
  val: string;
  I: Integer;

begin
  Result := S;
  I := CharPos('%', Result);
  while I > 0 do begin
    Val := '$' + Copy(Result, I + 1, 2);
    try
      Ch := Char(StrToInt(Val));
    except
      Ch := 'a';
    end;
    Result := Copy(Result, 1, I - 1) + Ch + Copy(Result, I + 3, Length(Result));
    I := CharPos('%', Result);
  end;
  I := CharPos('+', Result);
  while I > 0 do begin
    Result := Copy(Result, 1, I - 1) + #32 + Copy(Result, I + 1, Length(Result));
    I := CharPos('+', Result);
  end;
end;

function LocalTimeZoneBias: Integer;
{$IFDEF LINUX}
var
  TV: TTimeval;
  TZ: TTimezone;

begin
  gettimeofday(TV, TZ);
  Result := TZ.tz_minuteswest;
end;
{$ELSE}
var
  TimeZoneInformation: TTimeZoneInformation;
  Bias: Longint;

  begin
    case GetTimeZoneInformation(TimeZoneInformation) of
      TIME_ZONE_ID_STANDARD: Bias := TimeZoneInformation.Bias + TimeZoneInformation.StandardBias;
      TIME_ZONE_ID_DAYLIGHT: Bias := TimeZoneInformation.Bias + ((TimeZoneInformation.DaylightBias div 60) * -100);
    else
      Bias := TimeZoneInformation.Bias;
    end;
    Result := Bias;
  end;
{$ENDIF}

function TimeZone: string;
{$IFDEF LINUX}
begin
  Result := ShortTimeZone;
end;
{$ELSE}
var
  lpTimeZoneInfo: TTimeZoneInformation;

  begin
    Result := '';
    if GetTimeZoneInformation(lpTimeZoneInfo) = TIME_ZONE_ID_STANDARD then
{$IFDEF VER90}
      Result := WideCharToString({@} Pointer(lpTimeZoneInfo.StandardName))
{$ELSE}
      Result := lpTimeZoneInfo.StandardName
{$ENDIF}
    else
      if GetTimeZoneInformation(lpTimeZoneInfo) = TIME_ZONE_ID_DAYLIGHT then
{$IFDEF VER90}
        Result := WideCharToString({@} Pointer(lpTimeZoneInfo.DaylightName));
{$ELSE}
    Result := lpTimeZoneInfo.DaylightName;
{$ENDIF}
  end;
{$ENDIF}

function ShortTimeZone: string;
{$IFDEF LINUX}
var
  T: TTime_T;
  UT: TUnixTime;
begin
  __time(@T);
  localtime_r(@T, UT);
  Result := PChar(UT.__tm_zone);
end;
{$ELSE}
var
  TPos: Integer;

  begin
    Result := TimeZone;
    TPos := 1;
    while TPos <= Length(Result) do
      if not (Result[TPos] in ['A'..'Z']) then
        Delete(Result, TPos, 1)
      else
        Inc(TPos);
  end;
{$ENDIF}

function TimeZoneBias: string;
begin
  Result := IntToStr(LocalTimeZoneBIAS);
  while Length(Result) < 4 do
    Result := '0' + Result;
  if IsNumeric(Result[1]) then Result := '-' + Result;
end;



function EscapeEncode(const S: string): string;
var
  Loop: Integer;
  MaxLoop: Integer;

begin
  Result := '';
  MaxLoop := Length(S);
  for Loop := 1 to MaxLoop do
    if S[Loop] in ['0'..'9', '.', '-'] then
      Result := Result + S[Loop]
    else
      if S[Loop] = #32 then
        Result := Result + '+'
      else
        if (S[Loop] < #21) or
          (S[Loop] > #127) then
          Result := Result + '%' + IntToHex(Ord(S[Loop]), 2)
        else
          Result := Result + S[Loop]
end;

function EncodeDomain(S: string): string;
var
  Dot: Integer;

begin
  Result := '';
  while (S <> '') do begin
    Dot := CharPos('.', S);
    case Dot of
      0: begin
          Result := Result + Chr(Length(S)) + S;
          S := '';
        end;
    else begin
        Result := Result + Chr(Dot - 1) + Copy(S, 1, Dot - 1);
        Delete(S, 1, Dot);
      end;
    end;
  end;
  Result := Result + #0;
end;

function EncodeAddress(S: string): string;
var
  Dot: Integer;

begin
  Result := '';
  while (S <> '') do begin
    Dot := Pos('.', S);
    case Dot of
      0: begin
          Result := Result + Chr(Length(S)) + S;
          S := '';
        end;
    else begin
        Result := Result + Chr(Dot - 1) + Copy(S, 1, Dot - 1);
        Delete(S, 1, Dot);
      end;
    end;
  end;
  Result := Result + #7'in-addr'#4'arpa'#0;
end;

function DecodeDomain(S: string): string;
var
  L: Integer;

begin
  Result := '';
  while Length(S) > 0 do begin
    L := Ord(S[1]);
    if L > Length(S) then begin
      Result := '';
      Exit;
    end;
    Result := Result + Copy(S, 2, L) + '.';
    Delete(S, 1, L + 1);
  end;
  if Copy(Result, Length(Result), 1) = '.' then Delete(Result, Length(Result), 1);
end;

function GetActualEmailAddress(Parm, Command: string): string;
var
  Colon, Quote: Integer;

begin
   // posibilities are:
   // [cmd]:<mailadrress>
   // [cmd] :<mailadrress>
   // [cmd]: <mailadrress>
   // [cmd] : <mailadrress>
   // [cmd] <mailadrress>
   // [cmd]<mailadrress>
   // you can also have "firstname lastname" in there also
  Quote := CharPos('"', Parm);
  if Quote > 0 then begin
    if CharPos('>', Parm) > Quote then begin
      Delete(Parm, 1, Quote);
      Delete(Parm, 1, CharPos('"', Parm));
    end
    else begin
      Colon := PosLastChar('"', Parm);
      Delete(Parm, Quote, Colon - Pred(Quote));
    end;
  end;
   // check if space, if so let remove everything before
  Trim(Parm);
   // ok now possibilities are:
   // [cmd]:<mailadrress>
   // :<mailadrress>
   // : <mailadrress>
   // [cmd]<mailadrress>
  Colon := CharPos(':', Parm);
   // check if colon, if so let remove everything before
  if Colon > 0 then
    Delete(Parm, 1, Colon);
   // ok now possibilities are:
   //  <mailadrress>
   // [cmd]<mailadrress>
   // now let check if we have a command
  if lowercase(copy(parm, 1, length(command))) = lowercase(command) then
    delete(Parm, 1, length(command));
   // we trim to make sure we dont have any space left in there
  Parm := Trim(Parm);
   // and return the result with no brackets
  Result := NoAngleBrackets(Parm);
end;

///////////////////////////////////////////////////////////////////////////////
// Date and/or Time Routines
///////////////////////////////////////////////////////////////////////////////

function DayOfTheYear(const DT: TDateTime): Integer;
var
  J, Y: Word;

begin
  DecodeDate(DT, Y, J, J);
  Result := Trunc(DT) - Trunc(EncodeDate(Y, 1, 1)) + 1;
end;


function DaysLeftThisYear(const DT: TDateTime): Integer;
var
  J, Y: Word;

begin
  DecodeDate(DT, Y, J, J);
  case IsLeapYear(Y) of
    True: Result := 366 - DayOfTheYear(DT);
    False: Result := 365 - DayOfTheYear(DT);
  end;
end;

function DaysThisMonth(const DT: TDateTime): Integer;
var
  J, M, Y: Word;

begin
  DecodeDate(DT, Y, M, J);
  case M of
    2:
      if IsLeapYear(Y) then
        Result := 29
      else
        Result := 28;
    4, 6, 9, 11: Result := 30;
  else
    Result := 31;
  end;
end;

function DaysLeftThisMonth(const DT: TDateTime): Integer;
var
  J, M, Y: Word;

begin
  DecodeDate(DT, Y, M, J);
  case M of
    2:
      if IsLeapYear(Y) then
        Result := 29
      else
        Result := 28;
    4, 6, 9, 11: Result := 30;
  else
    Result := 31;
  end;
  Result := Result - J;
end;

function IsTimeAM(const DT: TDateTime): Boolean;
begin
  Result := Frac(DT) < 0.5;
end;

function IsTimePM(const DT: TDateTime): Boolean;
begin
  Result := Frac(DT) > 0.5;
end;

function IsTimeNoon(const DT: TDateTime): Boolean;
begin
  Result := Frac(DT) = 0.5;
end;

function IsTimeMidnight(const DT: TDateTime): Boolean;
begin
  Result := Frac(DT) = 0.0;
end;

function DateTimeToGMT(const DT: TDateTime): TDateTime;
begin
  Result := DT + LocalTimeZoneBias / 1440;
end;

function DateTimeToLocal(const DT: TDateTime): TDateTime;
begin
  Result := DT - LocalTimeZoneBias / 1440;
end;

function IsLeapYear(const Year: Word): Boolean;
begin
  Result := ((Year and 3) = 0) and ((Year mod 100 > 0) or (Year mod 400 = 0));
end;




function ToUnixSlashes(const S: string): string;
{.$IFNDEF ASM8086}
var
  Loop: Integer;
  MaxLoop: Integer;

begin
  Result := S;
  MaxLoop := Length(Result);
  for Loop := 1 to MaxLoop do
    if Result[Loop] = '\' then Result[Loop] := '/';
end;
(*
{$ElSE}
Var
   LenOfResult:Integer;
   FirstChar:Pointer;

Begin
   Result:=S;
   LenOfResult:=Length(Result);
   If LenOfResult<1 then Exit;
   FirstChar:=Pointer(Result);
asm
   push ESI
   mov  ESI, FirstChar;
   mov  ECX, LenOfResult
@Loop:
   mov  Al, [ESI]
   cmp  Al, '\'
   jne  @NoChange
   mov  Al, '/'
   mov  [ESI], Al
@NoChange:
   Inc  ESI
   Dec  ECX
   jnz  @Loop
   pop  ESI
end;
End;
{$ENDIF}
*)

function ToDOSSlashes(const S: string): string;
{.$IFNDEF ASM8086}
var
  Loop: Integer;
  MaxLoop: Integer;

begin
  Result := S;
  MaxLoop := Length(Result);
  for Loop := 1 to MaxLoop do
    if Result[Loop] = '/' then Result[Loop] := '\';
end;
(*
{$ElSE}
Var
   LenOfResult:Integer;
   FirstChar:Pointer;

Begin
   Result:=S;
   LenOfResult:=Length(Result);
   If LenOfResult<1 then Exit;
   FirstChar:=Pointer(Result);
asm
   push ESI
   mov  ESI, FirstChar;
   mov  ECX, LenOfResult
@Loop:
   mov  Al, [ESI]
   cmp  Al, '/'
   jne  @NoChange
   mov  Al, '\'
   mov  [ESI], Al
@NoChange:
   Inc  ESI
   Dec  ECX
   jnz  @Loop
   pop  ESI
end;
End;
{$ENDIF}
*)

function ToOSSlashes(const S: string): string;
begin
{$IFDEF LINUX}
  Result := ToUnixSlashes(S);
{$ELSE}
  Result := ToDOSSlashes(S);
{$ENDIF}
end;

(******************************************************************************
CHANGEDIR: {Rewritten to call Windows.API for the result!}
          The GetFullPathName function merges the name of the current drive and
          directory with the specified filename to determine the full path and
          filename of the specified file. It also calculates the address of the
          filename portion of the full path and filename. This function does not
          verify that the resulting path and filename are valid or that they
          refer to an existing file on the associated volume.
******************************************************************************)

function ChangeDir(const S, RP: string): string;
{$IFDEF LINUX}
begin
  Result := ''; // redesign
end;
{$ELSE}
var
  FileName: string;
  FName: PChar;
  Buffer: array[0..MAX_PATH - 1] of Char;

  begin
    FileName := ToDOSSlashes(S + RP);
    SetString(Result, Buffer, GetFullPathName(PChar(FileName), SizeOf(Buffer),
      Buffer, FName));
  end;
{$ENDIF}

function DateTimeToGMTRFC822(const DT: TDateTime): string;
begin
  Result := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss', DateTimeToGMT(DT)) + ' GMT';
end;

function DateTimeToGMTRFC850(const DT: TDateTime): string;
begin
  Result := FormatDateTime('dddd, dd-mmm-yy hh:nn:ss', DateTimeToGMT(DT)) + ' GMT';
end;

function DateTimeToRFC850(const DT: TDateTime): string;
begin
  Result := FormatDateTime('dddd, dd-mmm-yy hh:nn:ss', DT) + #32 + ShortTimeZone;
end;

function DateTimeToRFC850Bias(const DT: TDateTime): string;
begin
  Result := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss', DT) + #32 + TimeZoneBias;
end;

function RFCToDateTime(S: string): TDateTime;
var
  M, D, Y: Word;
  H, N, Sc, T: Word;
  Ch, CHtag: Char;
  Ts: string;
  PosCh: integer;

begin
  posch := CharPos(';', S);
  if posch > 0 then
    delete(s, posCH, length(s) - posCh + 1);
  T := 0;
  Ch := S[3];
  S := Uppercase(S);
  if Ch = #32 then begin
    Delete(S, 1, 4);
    Ts := Copy(S, 1, CharPos(#32, S) - 1);
    Delete(S, 1, Length(TS));
    S := Trim(S);
    M := QuickPos(TS, #32#32'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC') div 3;
    Ts := Copy(S, 1, CharPos(#32, S) - 1);
    Delete(S, 1, Length(TS) + 1);
    S := Trim(S);
    try
      D := StrToInt(TS);
    except
      D := 1;
    end;
    Ch := S[3];
    if Ch <> ':' then begin
      Ts := Copy(S, 1, CharPos(#32, S) - 1);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        Y := StrToInt(TS);
      except
        DecodeDate(Now, Y, T, T);
        T := 0;
      end;
    end;
    Ts := Copy(S, 1, CharPos(':', S) - 1);
    Delete(S, 1, Length(TS) + 1);
    S := Trim(S);
    try
      H := StrToInt(TS);
    except
      H := 0;
    end;
    Ts := Copy(S, 1, 2);
    Delete(S, 1, Length(TS) + 1);
    S := Trim(S);
    try
      N := StrToInt(TS);
    except
      N := 0;
    end;
    Ts := Copy(S, 1, 2);
    Delete(S, 1, Length(TS) + 1);
    S := Trim(S);
    try
      Sc := StrToInt(TS);
    except
      Sc := 0;
    end;
    if S <> '' then begin
      Ch := S[1];
      if Ch in ['0'..'9'] then begin
        try
          Y := StrToInt(S);
        except
          DecodeDate(Now, Y, T, T);
          T := 0;
        end;
      end;
    end;
  end
  else
    if Ch = ',' then begin // RFC 822 or RFC 1123
      Delete(S, 1, CharPos(#32, S));
      S := Trim(S);
      Ts := Copy(S, 1, CharPos(#32, S) - 1);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        D := StrToInt(TS);
      except
        D := 1;
      end;
      Ts := Copy(S, 1, CharPos(#32, S) - 1);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      M := QuickPos(TS, #32#32'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC') div 3;
      Ts := Copy(S, 1, CharPos(#32, S) - 1);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        Y := StrToInt(TS);
      except
        DecodeDate(Now, Y, T, T);
        T := 0;
      end;
      Ts := Copy(S, 1, CharPos(':', S) - 1);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        H := StrToInt(TS);
      except
        H := 0;
      end;
      Ts := Copy(S, 1, 2);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        N := StrToInt(TS);
      except
        N := 0;
      end;
      Ts := Copy(S, 1, 2);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        Sc := StrToInt(TS);
      except
        Sc := 0;
      end;
    end
    else begin // RFC 850 or RFC 1036
      Delete(S, 1, CharPos(#32, S));
      S := Trim(S);
      chtag := '-';
      posCh := charpos(chtag, S);
      if (posCH > 0) and (posCh < 5) then
        chtag := '-'
      else
        chtag := ' ';
      Ts := Copy(S, 1, CharPos(chtag, S) - 1);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        D := StrToInt(TS);
      except
        D := 1;
      end;
      Ts := Copy(S, 1, CharPos(chtag, S) - 1);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      M := QuickPos(TS, #32#32'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC') div 3;
      Ts := Copy(S, 1, CharPos(#32, S) - 1);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        Y := StrToInt(TS);
      except
        DecodeDate(Now, Y, T, T);
        T := 0;
      end;
      Ts := Copy(S, 1, CharPos(':', S) - 1);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        H := StrToInt(TS);
      except
        H := 0;
      end;
      Ts := Copy(S, 1, 2);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        N := StrToInt(TS);
      except
        N := 0;
      end;
      Ts := Copy(S, 1, 2);
      Delete(S, 1, Length(TS) + 1);
      S := Trim(S);
      try
        Sc := StrToInt(TS);
      except
        Sc := 0;
      end;
    end;
  if Y < 100 then begin
    DecodeDate(Now, Y, T, T);
  end;
  try
    Result := EncodeDate(Y, M, D) + EncodeTime(H, N, Sc, T);
  except
    result := now;
  end;
end;



{$IFDEF VER100}

function StringReplace(const S, OldPattern, NewPattern: string;
  Flags: TReplaceFlags): string;
var
  SearchStr, Patt, NewStr: string;
  Offset: Integer;
begin
  if rfIgnoreCase in Flags then begin
    SearchStr := AnsiUpperCase(S);
    Patt := AnsiUpperCase(OldPattern);
  end
  else begin
    SearchStr := S;
    Patt := OldPattern;
  end;
  NewStr := S;
  Result := '';
  while SearchStr <> '' do begin
{$IFDEF VER90}
    Offset := Pos(Patt, SearchStr);
{$ELSE}
    Offset := AnsiPos(Patt, SearchStr);
{$ENDIF}
    if Offset = 0 then begin
      Result := Result + NewStr;
      Break;
    end;
    Result := Result + Copy(NewStr, 1, Offset - 1) + NewPattern;
    NewStr := Copy(NewStr, Offset + Length(OldPattern), MaxInt);
    if not (rfReplaceAll in Flags) then begin
      Result := Result + NewStr;
      Break;
    end;
    SearchStr := Copy(SearchStr, Offset + Length(Patt), MaxInt);
  end;
end;

procedure FreeAndNil(var Obj);
var
  Temp: TObject;

begin
  Temp := TObject(Obj);
  Pointer(Obj) := nil;
  Temp.Free;
end;
{$ENDIF}

function PCharLen(Str: PChar): integer;
{$IFDEF ASM8086}
asm
      MOV     EDX,7
      ADD     EDX,EAX                   { pointer+7 used in the end }
      PUSH    EBX                       { is necessary; even in your version}
      MOV     EBX,[EAX]                 { read first 4 bytes}
      ADD     EAX,4                     { increment pointer}
@L1:  LEA     ECX,[EBX-$01010101]       { subtract 1 from each byte}
      XOR     EBX,-1                    { invert all bytes}
      AND     ECX,EBX                   { and these two}
      MOV     EBX,[EAX]                 { read next 4 bytes}
      ADD     EAX,4                     { increment pointer}
      AND     ECX,80808080H             { test all sign bits}
      JZ      @L1                       { no zero bytes, continue loop}
      TEST    ECX,00008080H             { test first two bytes}
      JNZ     @L2                       { *was JNZ SHORT @L2*}
      SHR     ECX,16                    { not in the first 2 bytes}
      ADD     EAX,2
@L2:  SHL     CL,1                      { use carry flag to avoid a branch}
      POP     EBX                       { Likewise; see above}
      SBB     EAX,EDX                   { compute length}
end;
{$ELSE}
var
  p: ^cardinal;
  q: pchar;
  bytes, r1, r2: cardinal;
  begin
    p := pointer(tStr);
    repeat
      q := pchar(p^);
      r2 := cardinal({@} Pointer(q[-$01010101]));
      r1 := cardinal(q) xor $FFFFFFFF;
      bytes := r1 and r2;
      inc(p);
    until (bytes and $80808080) <> 0;
    result := integer(p) - integer(tStr) - 4;
    if (bytes and $00008080) = 0 then begin
      bytes := bytes shr 16;
      inc(result, 2);
    end;
    if (bytes and $80) = 0 then
      inc(result);
  end;
{$ENDIF}

{$IFDEF ASM8086}

function LRot16(X: Word; c: longint): Word; assembler;
asm
  mov ecx,&c
  mov ax,&X
  rol ax,cl
  mov &Result,ax
end;

function RRot16(X: Word; c: longint): Word; assembler;
asm
  mov ecx,&c
  mov ax,&X
  ror ax,cl
  mov &Result,ax
end;

function LRot32(X: DWord; c: longint): DWord; register; assembler;
asm
  mov ecx, edx
  rol eax, cl
end;

function RRot32(X: DWord; c: longint): DWord; register; assembler;
asm
  mov ecx, edx
  ror eax, cl
end;

function SwapDWord(X: DWord): DWord; register; assembler;
asm
  xchg al,ah
  rol  eax,16
  xchg al,ah
end;
{$ELSE}

function LRot16(X: Word; c: longint): Word;
begin
  LRot16 := (X shl c) or (X shr (16 - c));
end;

function RRot16(X: Word; c: longint): Word;
begin
  RRot16 := (X shr c) or (X shl (16 - c));
end;

function LRot32(X: DWord; c: longint): DWord;
begin
  LRot32 := (X shl c) or (X shr (32 - c));
end;

function RRot32(X: DWord; c: longint): DWord;
begin
  RRot32 := (X shr c) or (X shl (32 - c));
end;

function SwapDWord(X: DWord): DWord;
begin
  Result := (X shr 24) or ((X shr 8) and $FF00) or ((X shl 8) and $FF0000) or (X shl 24);
end;
{$ENDIF}

function WildCompare(LookingFor, SourceStr: string): Boolean;
var
  Ws: string;
  MaxInputWord: Integer;
  MaxWild: Integer;
  cInput: Integer;
  cWild: Integer;
  HelpWild: string;
  LengthHelpWild: Integer;
  Q: Integer;

  function FindPart(helpwilds, input_word: string): integer;
  var
    Q1, Q2, Q3: Integer;
    Diff: Integer;

  begin
    Q1 := CharPos('?', helpwilds);
    if Q1 = 0 then
      Result := QuickPos(helpwilds, input_word)
    else begin
      Q3 := Length(helpwilds);
      Diff := Length(input_word) - Q3;
      if Diff < 0 then begin
        Result := 0;
        Exit;
      end;
      for Q1 := 0 to Diff do begin
        for Q2 := 1 to Q3 do begin
          if (input_word[Q1 + Q2] = helpwilds[Q2]) or
            (helpwilds[Q2] = '?') then begin
            if Q2 = Q3 then begin
              Result := Q1 + 1;
              Exit;
            end;
          end
          else
            Break;
        end;
      end;
      Result := 0;
    end;
  end;

  function SearchNext(var WildS: string): Integer;
  begin
    Result := CharPos('*', WildS);
    if Result <> 0 then WildS := Copy(WildS, 1, Result - 1);
  end;

begin
  Ws := LookingFor;
  while CharPos('%', Ws) > 0 do
    Ws[CharPos('%', Ws)] := '*';
  while QuickPos('**', Ws) > 0 do
    Delete(Ws, QuickPos('**', Ws), 1);
  MaxInputWord := Length(SourceStr);
  MaxWild := Length(Ws);
  cInput := 1;
  cWild := 1;
  Result := True;
  repeat
    if SourceStr[cInput] = Ws[cWild] then begin
      inc(cWild);
      inc(cInput);
      continue;
    end
    else
      if Ws[cWild] = '?' then begin
        inc(cWild);
        inc(cInput);
        continue;
      end
      else
        if Ws[cWild] = '*' then begin
          HelpWild := Copy(Ws, cWild + 1, MaxWild);
          q := SearchNext(HelpWild);
          LengthHelpWild := Length(HelpWild);
          if Q = 0 then begin
            if HelpWild = '' then Exit;
            for Q := 0 to LengthHelpWild - 1 do
              if (HelpWild[LengthHelpWild - Q] <> SourceStr[MaxInputWord - Q]) and
                (HelpWild[LengthHelpWild - Q] <> '?') then begin
                Result := False;
                Exit;
              end;
            Exit;
          end;
          Inc(cWild, 1 + LengthHelpWild);
          Q := FindPart(HelpWild, Copy(SourceStr, cInput, Length(SourceStr)));
          if Q = 0 then begin
            Result := False;
            Exit;
          end;
          cInput := Q + LengthHelpWild;
          Continue;
        end;
    Result := False;
    Exit;
  until (cInput > MaxInputWord) or (cWild > MaxWild);
  if cInput <= MaxInputWord then
    Result := False
  else
    if cWild <= MaxWild then
      Result := False;
end;

// DXSock 4.0 Additions

function SizeStamp(CPS: Integer): string;
begin
  if CPS < 1024 then Result := IntToStr(CPS) + 'bps'
  else if CPS < 1024000 then Result := IntToStr(CPS div 1024) + 'kbps'
  else if CPS < 1024000000 then Result := IntToStr(CPS div 1024000) + 'mbps'
  else Result := IntToStr(CPS div 1024000000) + 'gbps';
end;

procedure DivMod(Dividend: Integer; Divisor: Word;
  var Result, Remainder: Word);
asm
   PUSH    EBX
   MOV     EBX,EDX
   MOV     EDX,EAX
   SHR     EDX,16
   DIV     BX
   MOV     EBX,Remainder
   MOV     [ECX],AX
   MOV     [EBX],DX
   POP     EBX
end;

function GetUserName: string;
var
  N: DWord;
  Buf: array[0..1023] of AnsiChar;
begin
  N := SizeOf(Buf) - 1;
  Windows.GetUserName(Buf, N);
  Result := PChar(@Buf[0]);
end;

function GetComputerName: string;
var
  N: DWORD;
  Buf: array[0..16] of AnsiChar;
begin
  N := SizeOf(Buf) - 1;
  Windows.GetComputerName(Buf, N);
  Result := PChar(@Buf[0]);
end;

function GetAbsoluteFileName(CurrentDir, RelativeName: string): string;

  function IncPtr(P: Pointer; Delta: Longint): Pointer; register;
  asm
   add   eax, edx
  end;

  function IsAbsoluteFileName(FileName: string): Boolean;
  var
    P: PWord;
  begin
    P := PWord(PChar(FileName));
    Result := P^ = $5C5C; // Network name
    if not Result then begin
      P := IncPtr(P, 1);
      Result := P^ = $5C3A; // Local name
    end;
  end;

  procedure RemoveLastSubDir(var Dir: string);
  var
    P: Longint;
  begin
    P := Length(Dir);
    while (P > 0) and (Dir[P] <> '\') do Dec(P);
    if P = 0 then Dir := '' else Dir := Copy(Dir, 1, P - 1);
  end;

  function FindDots(Name: string; var P: Longint): Longint;
  var
    Ptr: PInteger;
  begin
    Ptr := IncPtr(PChar(Name), P);
    while (P >= 0) and ((Ptr^ and $00FFFFFF) <> $5C2E2E) do begin
      Dec(P);
      Ptr := IncPtr(Ptr, -1);
    end;
    Inc(P);
    Result := P;
  end;

var
  Drive: string;

begin
  if IsAbsoluteFileName(RelativeName) then Result := RelativeName
  else begin
    if Copy(CurrentDir, Length(CurrentDir), 1) = '\' then Delete(CurrentDir, Length(CurrentDir), 1);
    if Copy(RelativeName, 1, 1) = '\' then Delete(RelativeName, 1, 1);
    Drive := ExtractFileDrive(CurrentDir);
    Delete(CurrentDir, 1, Length(Drive) + 1);
    Result := IncludeTrailingBackslash(Drive + '\' + CurrentDir) + RelativeName;
  end;
end;

function GetTempDirectory: string;
var
  Buf: array[0..MAX_PATH - 1] of AnsiChar;
begin
  GetTempPath(SizeOf(Buf), @Buf);
  Result := IncludeTrailingBackslash(PChar(@Buf));
end;

function GetTempFile(const ThreeLetterPrefix: string): string;
var
  Buf: array[0..MAX_PATH - 1] of AnsiChar;
begin
  GetTempFileName(PChar(GetTempDirectory), PChar(ThreeLetterPrefix), 0, @Buf);
  Result := PChar(@Buf);
end;

//==============================================================================


{$IFDEF LINUX}


function WSAGetLastError: Integer;
begin
  Result := System.GetLastError
end;
{$ENDIF}

function CreateSocket(sin_family, socket_type, protocol: integer;
  var ErrorCode: Integer): TSocket;
begin
  ErrorCode := 0;
  Result := {$IFDEF LINUX}Libc.
{$ELSE}Winsock.
{$ENDIF}Socket(sin_family, socket_type, protocol);
  if Result = Invalid_Socket then ErrorCode := WSAGetLastError;
end;

function SetErrorCode(ResultCode: Integer): Integer;
begin
  if ResultCode = Socket_Error then Result := WSAGetLastError
  else Result := 0;
end;

procedure SetNagle(Sock: TSocket;
  TurnOn: Boolean;
  var ErrorCode: Integer);
var
  TA: array[0..3] of Char;

begin
  if not TurnOn then TA := '1111'
  else TA := '0000';
  ErrorCode := SetErrorCode(SetSockOpt(Sock, IPPROTO_TCP, TCP_NODELAY, @TA, SizeofInt));
end;

procedure SetBlocking(Sock: TSocket;
  UseBlocking: Boolean;
  var ErrorCode: Integer);
{$IFDEF LINUX}
const
  FIONBIO = $5421;
{$ENDIF}

var
{$IFDEF VER90}
  iBlocking: u_long;
{$ELSE}
  iBlocking: Integer;
{$ENDIF}

begin
  if UseBlocking then iBlocking := 0
  else iBlocking := 1;
  ErrorCode := SetErrorCode(
{$IFDEF VER90}
    Winsock.ioctlsocket(Sock, FIONBIO, iBlocking)
{$ELSE}
{$IFDEF LINUX}Libc.ioctl(Sock, FIONBIO, iBlocking)
{$ELSE}Winsock.ioctlsocket(Sock, FIONBIO, iBlocking)
{$ENDIF}
{$ENDIF}
    );
end;

procedure SetReceiveTimeout(Sock: TSocket;
  TimeoutMS: Integer;
  var ErrorCode: Integer);
begin
  ErrorCode := SetErrorCode(setsockopt(Sock, SOL_SOCKET, SO_RCVTIMEO, @TimeoutMS, SizeOfInt));
end;

procedure SetSendTimeout(Sock: TSocket;
  TimeoutMS: Integer;
  var ErrorCode: Integer);
begin
  ErrorCode := SetErrorCode(setsockopt(Sock, SOL_SOCKET, SO_SNDTIMEO, @TimeoutMS, SizeofInt));
end;

procedure SetReceiveBuffer(Sock: TSocket;
  WantedSize: Integer;
  var ErrorCode: Integer);
begin
  ErrorCode := SetErrorCode(setsockopt(Sock, SOL_SOCKET, SO_RCVBUF, @WantedSize, SizeofInt));
end;

procedure ResetBufferAndTimeout(Sock: TSocket;
  TimeoutMS: Integer;
  WantedSize: Integer);
begin
  setsockopt(Sock, SOL_SOCKET, SO_SNDTIMEO, @TimeoutMS, SizeofInt);
  setsockopt(Sock, SOL_SOCKET, SO_RCVTIMEO, @TimeoutMS, SizeOfInt);
  setsockopt(Sock, SOL_SOCKET, SO_RCVBUF, @WantedSize, SizeofInt);
  setsockopt(Sock, SOL_SOCKET, SO_SNDBUF, @WantedSize, SizeofInt);
end;

function GetSockStatusBool(Sock: TSocket;
  SO_Flag: Integer;
  var ErrorCode: Integer): Boolean;
var
  Rslt: Boolean;

begin
// 7-27
  ErrorCode := SetErrorCode(GetSockOpt(Sock, SOL_SOCKET, SO_Flag, PChar(@Rslt), SizeofInt));
  if ErrorCode = 0 then Result := Rslt
  else Result := False;
end;

function GetSockStatusInt(Sock: TSocket;
  SO_Flag: Integer;
  var ErrorCode: Integer): Integer;
var
  Rslt: Integer;

begin
// 7-27
  ErrorCode := SetErrorCode(GetSockOpt(Sock, SOL_SOCKET, SO_Flag, PChar(@Rslt), SizeofInt));
  if ErrorCode = 0 then Result := Rslt
  else Result := 0;
end;

procedure SetSockStatusBool(Sock: TSocket;
  SO_Flag: Integer;
  Setting: Boolean;
  var ErrorCode: Integer);
var
  intval: integer;

begin
  if (Setting) then intval := 1
  else intval := 0;
  ErrorCode := SetErrorCode(SetSockOpt(Sock, SOL_Socket, SO_Flag, @intval, SizeofInt));
end;

procedure SetSockStatusInt(Sock: TSocket;
  SO_Flag: Integer;
  Setting: Integer;
  var ErrorCode: Integer);
begin
  ErrorCode := SetErrorCode(SetSockOpt(Sock, SOL_Socket, SO_Flag, @Setting, SizeofInt));
end;


procedure SetSendBuffer(Sock: TSocket;
  WantedSize: Integer;
  var ErrorCode: Integer);
begin
  ErrorCode := SetErrorCode(setsockopt(Sock, SOL_SOCKET, SO_SNDBUF, @WantedSize, SizeofInt));
end;

function GetReceiveBuffer(Sock: TSocket;
  var ErrorCode: Integer): Integer;
begin
  Result := GetSockStatusInt(Sock, SO_RCVBUF, ErrorCode);
end;

function GetSendBuffer(Sock: TSocket;
  var ErrorCode: Integer): Integer;
begin
  Result := GetSockStatusInt(Sock, SO_SNDBUF, ErrorCode);
end;

procedure KillSocket(var Sock: TSocket);
begin
  if Sock <> Invalid_Socket then begin
    ShutDown(Sock, 2);
{$IFDEF LINUX}
    Libc.__close(Sock);
{$ELSE}
    CloseSocket(Sock);
{$ENDIF}
    Sock := Invalid_Socket;
  end;
end;

procedure CloseConnection(var Sock: TSocket;
  Gracefully: Boolean);
var
{$IFDEF VER100} // Delphi3 code
  Lin: TLinger;
{$ELSE}
  Lin: Linger;
{$ENDIF}

begin
  if Sock = Invalid_Socket then Exit;
  Lin.l_linger := 0;
  if Gracefully then begin
    Lin.l_onoff := 1; // Not(0);
{$IFDEF LINUX}Libc.
{$ELSE}Winsock.
{$ENDIF}setsockopt(Sock, SOL_SOCKET, SO_LINGER, @lin, Sizeof(Lin));
  end
  else begin
    Lin.l_onoff := 0;
{$IFDEF LINUX}Libc.
{$ELSE}Winsock.
{$ENDIF}setsockopt(Sock, SOL_SOCKET, SO_LINGER, @lin, sizeof(lin)); {DONT 2.0.f}
  end;
  KillSocket(Sock);
end;

function GetIPAddressByHost(Host: string; Which: Integer): string;
var
  HostEnt: PHostEnt;
  iAddr: Integer;

begin
  HostEnt := gethostbyname(PChar(Host));
  if Assigned(HostEnt) then begin
    if Which <= (HostEnt^.h_length div 4) then begin
      Move(PByteArray(HostEnt^.h_addr_list^)[(Which - 1) * 4], iAddr, 4);
      Result := inet_ntoa(in_Addr(iAddr));
    end
    else Result := '';
  end
  else Result := '';
end;


function GetHostByIPAddress(IPAddress: string): string;
var
  HostEnt: PHostEnt;
  InAddr: u_long;

begin
  IPAddress := FixDottedIp(IPAddress);
  InAddr := inet_addr(PChar(IPAddress));
  HostEnt := gethostbyaddr(@InAddr, Length(IPAddress), AF_INET);
  if Assigned(HostEnt) then Result := StrPas(HostEnt^.h_name)
  else Result := '';
end;


function ClientConnectToServer(ServerIPAddress: string;
  ServerPort: Integer;
  UseUDP, UseNAGLE: Boolean;
  ResultSockAddr: PSockAddr;
  var ErrorCode: Integer): TSocket;
{$IFDEF LINUX}
const
  SOCK_dgram = 2;
  SOCK_stream = 1;
{$ENDIF}

begin
  Result := Invalid_Socket;
  if ServerIPAddress = '' then Exit;
  ServerIPAddress := FixDottedIp(ServerIPAddress);
  FillChar(ResultSockAddr^, Sizeof(ResultSockAddr^), #0);
  ResultSockAddr.sin_family := AF_INET;
  ResultSockAddr.sin_port := htons(ServerPort);
  if IsNumericString(ServerIPAddress) then begin
    ResultSockAddr.sin_addr.S_addr := Inet_Addr(Pchar(ServerIPAddress));
  end
  else begin
    ServerIPAddress := GetIPAddressByHost(ServerIPAddress, 1);
    if ServerIPAddress = '' then begin
      ErrorCode := WSAEFAULT; // invalid address
      Exit;
    end;
    ResultSockAddr.sin_addr.S_addr := Inet_Addr(Pchar(ServerIPAddress));
  end;
  case UseUDP of
    True: begin
        Result := CreateSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP, ErrorCode);
        Exit;
      end;
  else begin
      Result := CreateSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, ErrorCode);
      if (Result <> Invalid_Socket) and (not UseNAGLE) then
        SetNAGLE(Result, UseNAGLE, ErrorCode);
    end;
  end;
  if Result = Invalid_Socket then Exit;
  SetSendTimeout(Result, 500, ErrorCode);
  if Connect(Result, ResultSockAddr^, ConstSizeofTSockAddrIn) = SOCKET_ERROR then begin
    ErrorCode := WSAGetLastError;
    KillSocket(Result);
  end;
end;

function BindAndListen(BindToIPAddress: string;
  BindToPort, WinsockQueue: Integer;
  UseUDP, UseNAGLE, ConnectionLess: Boolean;
  ResultSockAddr: PSockAddr;
  var ErrorCode: Integer): TSocket;
{$IFDEF LINUX}
const
  SOCK_dgram = 2;
  SOCK_stream = 1;
{$ENDIF}

begin
  FillChar(ResultSockAddr^, Sizeof(ResultSockAddr^), #0); // DO ! USE ZEROMEMORY
// SPX: Result:=CreateSocket(AF_IPX,SOCK_STREAM,NSPROTO_SPX,ErrorCode);
// IPX: Result:=CreateSocket(AF_IPX,SOCK_DGRAM,NSPROTO_IPX,ErrorCode);
  case UseUDP of
    True: Result := CreateSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP, ErrorCode);
  else begin
      Result := CreateSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, ErrorCode);
      if (Result <> Invalid_Socket) and (not UseNAGLE) then SetNAGLE(Result, UseNAGLE, ErrorCode);
    end;
  end;
  if Result = Invalid_Socket then Exit;
  ResultSockAddr.sin_family := AF_INET;
  ResultSockAddr.sin_port := htons(BindToPORT);
// 7-27
  if (length(BindToIPAddress) < 7) then ResultSockAddr.sin_addr.S_addr := INADDR_ANY
  else ResultSockAddr.sin_addr.S_addr := Inet_Addr(PChar(BindToIPAddress));
  if Bind(Result, ResultSockAddr^, ConstSizeofTSockAddrIn) = Socket_Error then begin
    Result := Invalid_Socket;
    ErrorCode := WSAGetLastError;
    Exit;
  end;
// 7-27
  if not ConnectionLess then
    if Listen(Result, WinsockQueue) = Socket_Error then begin
      Result := Invalid_Socket;
      ErrorCode := WSAGetLastError;
    end;
end;

function IsAcceptWaiting(ListenerSock: TSocket): Boolean;
{$IFNDEF LINUX}
var
  SockList: TFDSet;
{$ENDIF}

begin
{$IFDEF LINUX}
  Result := BasicSelect(ListenerSock, True, GlobalTimeout) > 0;
{$ELSE}
  SockList.fd_count := 1;
  SockList.fd_array[0] := ListenerSock;
  Result := Select(0, @sockList, nil, nil, @GlobalTimeout) > 0;
{$ENDIF}
end;

function AcceptNewConnect(ListenerSock: TSocket;
  ResultAddr: PSockAddr;
  ResultAddrlen: PInteger;
  var ErrorCode: Integer): TSocket;
begin
  Result := {$IFDEF LINUX}Libc.
{$ELSE}Winsock.
{$ENDIF}Accept(ListenerSock,
{$IFDEF VER90}
    ResultAddr^, ResultAddrLen^);
{$ELSE}
{$IFDEF LINUX}
  ResultAddr, PSocketLength(ResultAddrLen));
{$ELSE}
  ResultAddr, ResultAddrLen);
{$ENDIF}
{$ENDIF}
if Result = Invalid_Socket then ErrorCode := WSAGetLastError
else if ResultAddrLen^ = 0 then ErrorCode := WSAEFault
else ErrorCode := 0;
end;

function BasicSend(Sock: TSocket;
  var Buf;
  Len: Integer;
  Flags: Integer;
  var ErrorCode: Integer): Integer;
begin
//   Result:=Socket_Error;
//   ErrorCode:=WSAEINTR;
//   While (Result<0) and ((ErrorCode=WSAEINTR) or (ErrorCode=WSAETIMEDOUT)) do Begin
  Result := Send(Sock, Buf, Len, Flags);
  ErrorCode := SetErrorCode(Result);
//   End;
end;

function UDPSend(Sock: TSocket;
  var Buf;
  Len: Integer;
  Flags: Integer;
  SendTo: TSockAddr;
  SendToSize: Integer;
  var ErrorCode: Integer): Integer;
begin
  Result := {$IFDEF LINUX}Libc.
{$ELSE}Winsock.
{$ENDIF}SendTo(Sock, Buf, Len, Flags, SendTo, SendToSize);
  ErrorCode := SetErrorCode(Result);
end;

function BasicRecv(Sock: TSocket;
  var Buf;
  Len: Integer;
  Flags: Integer;
  var ErrorCode: Integer): Integer;
begin
  Result := Recv(Sock, Buf, Len, Flags);
  ErrorCode := SetErrorCode(Result);
end;

function UDPRecv(Sock: TSocket;
  var Buf;
  Len: Integer;
  Flags: Integer;
  var RcvFrom: TSockAddr;
  var RcvFromSize: Integer;
  var ErrorCode: Integer): Integer;
begin
  Result := {$IFDEF LINUX}Libc.recvfrom(Sock, Buf, Len, Flags, @RcvFrom, @RcvFromSize);
{$ELSE}Winsock.recvfrom(Sock, Buf, Len, Flags, RcvFrom, RcvFromSize);
{$ENDIF}
  ErrorCode := SetErrorCode(Result);
end;

function BasicPeek(Sock: TSocket;
  var Buf;
  Len: Integer): Integer;
begin
  Result := Recv(Sock, Buf, Len, MSG_PEEK);
end;

function BasicSelect(Sock: TSocket;
  CheckRead: Boolean;
  Timeout: TTimeVal): Integer;
var
  SockList: TFDSet;

begin
{$IFDEF LINUX}
  FD_ZERO(SockList);
  SockList.fds_bits[0] := Sock;
  if CheckRead then
    Result := Select(1, @SockList, nil, nil, @Timeout)
  else
    Result := Select(1, nil, @SockList, nil, @Timeout);
{$ELSE}
  SockList.fd_count := 1;
  SockList.fd_array[0] := Sock;
  if CheckRead then
    Result := Select(0, @sockList, nil, nil, @Timeout)
  else
    Result := Select(0, nil, @sockList, nil, @Timeout)
{$ENDIF}
end;

function CountWaiting(Sock: TSocket; var ErrorCode: Integer): Integer;
{$IFDEF LINUX}
const
  FIONREAD = $541B;
{$ENDIF}
var
  numWaiting: longint;

begin
  Result := 0;
// in linux IOCtl is used to "set" not "get" values.
  ErrorCode := SetErrorCode({$IFDEF LINUX}Libc.IOCtl(Sock, FIONREAD, numWaiting));
{$ELSE}Winsock.IOCtlSocket(Sock, FIONREAD, numWaiting));
{$ENDIF}
if ErrorCode = 0 then Result := numWaiting;
end;

function GetAddressCountByIP(IPAddress: string): Integer;
var
  HostEnt: PHostEnt;
  InAddr: u_long;

begin
  IPAddress := FixDottedIp(IPAddress);
  InAddr := inet_addr(PChar(IPAddress));
  HostEnt := gethostbyaddr(@InAddr, Length(IPAddress), AF_INET);
  if Assigned(HostEnt) then Result := HostEnt^.h_length div 4
  else Result := 0;
end;

function GetAddressCountByHost(Host: string): Integer;
var
  HostEnt: PHostEnt;

begin
  HostEnt := gethostbyname(PChar(Host));
  if Assigned(HostEnt) then Result := HostEnt^.h_length div 4
  else Result := 0;
end;



function GetLocalHostName: string;
begin
  Result := GetHostByIPAddress(
    GetIPAddressByHost('localhost', 1));
  if Result = '' then Result := 'Localhost';
end;

function GetLocalPort(Sock: TSocket): Integer;
var
  addr: TSockAddrIn;
{$IFDEF LINUX}
  addrlen: cardinal;
{$ELSE}
  addrlen: integer;
{$ENDIF}

begin
  addrlen := ConstSizeofTSockAddrIn;
  if getsockname(Sock, addr, addrlen) = 0 then Result := ntohs(addr.sin_port)
  else Result := 0;
end;

function GetLocalIPAddr(Sock: TSocket): string;
var
  addr: TSockAddrIn;
{$IFDEF LINUX}
  addrlen: cardinal;
{$ELSE}
  addrlen: integer;
{$ENDIF}

begin
  addrlen := ConstSizeofTSockAddrIn;
  FillChar(Addr, Sizeof(TSockAddrIn), #0);
  getsockname(Sock, addr, addrlen);
  Result := inet_ntoa(addr.sin_addr);
end;

procedure GetRemoteSockAddr(Sock: TSocket;
  ResultAddr: PSockAddr;
  ResultAddrlen: PInteger;
  var ErrorCode: Integer);
{$IFDEF LINUX}
var
  TmpAddrLen: Cardinal;
{$ENDIF}

begin
{$IFDEF LINUX}
  ErrorCode := SetErrorCode(getpeername(Sock, ResultAddr^, TmpAddrlen));
  ResultAddrLen^ := TmpAddrLen;
{$ELSE}
  ErrorCode := SetErrorCode(getpeername(Sock, ResultAddr^, ResultAddrlen^));
{$ENDIF}
end;

function GetLastError: Integer;
begin
  Result := WSAGetLastError;
end;

function GetErrorDesc(errorCode: Integer): string;
begin
// If you compile and get "Undeclared Identified -
// Edit DXSock.DEF - and select a language!
  case errorCode of
    WSAEINTR: Result := _WSAEINTR;
    WSAEBADF: Result := _WSAEBADF;
    WSAEACCES: Result := _WSAEACCES;
    WSAEFAULT: Result := _WSAEFAULT;
    WSAEINVAL: Result := _WSAEINVAL;
    WSAEMFILE: Result := _WSAEMFILE;
    WSAEWOULDBLOCK: Result := _WSAEWOULDBLOCK;
    WSAEINPROGRESS: Result := _WSAEINPROGRESS;
    WSAEALREADY: Result := _WSAEALREADY;
    WSAENOTSOCK: Result := _WSAENOTSOCK;
    WSAEDESTADDRREQ: Result := _WSAEDESTADDRREQ;
    WSAEMSGSIZE: Result := _WSAEMSGSIZE;
    WSAEPROTOTYPE: Result := _WSAEPROTOTYPE;
    WSAENOPROTOOPT: Result := _WSAENOPROTOOPT;
    WSAEPROTONOSUPPORT: Result := _WSAEPROTONOSUPPORT;
    WSAESOCKTNOSUPPORT: Result := _WSAESOCKTNOSUPPORT;
    WSAEOPNOTSUPP: Result := _WSAEOPNOTSUPP;
    WSAEPFNOSUPPORT: Result := _WSAEPFNOSUPPORT;
    WSAEAFNOSUPPORT: Result := _WSAEAFNOSUPPORT;
    WSAEADDRINUSE: Result := _WSAEADDRINUSE;
    WSAEADDRNOTAVAIL: Result := _WSAEADDRNOTAVAIL;
    WSAENETDOWN: Result := _WSAENETDOWN;
    WSAENETUNREACH: Result := _WSAENETUNREACH;
    WSAENETRESET: Result := _WSAENETRESET;
    WSAECONNABORTED: Result := _WSAECONNABORTED;
    WSAECONNRESET: Result := _WSAECONNRESET;
    WSAENOBUFS: Result := _WSAENOBUFS;
    WSAEISCONN: Result := _WSAEISCONN;
    WSAENOTCONN: Result := _WSAENOTCONN;
    WSAESHUTDOWN: Result := _WSAESHUTDOWN;
    WSAETOOMANYREFS: Result := _WSAETOOMANYREFS;
    WSAETIMEDOUT: Result := _WSAETIMEDOUT;
    WSAECONNREFUSED: Result := _WSAECONNREFUSED;
    WSAELOOP: Result := _WSAELOOP;
    WSAENAMETOOLONG: Result := _WSAENAMETOOLONG;
    WSAEHOSTDOWN: Result := _WSAEHOSTDOWN;
    WSAEHOSTUNREACH: Result := _WSAEHOSTUNREACH;
    WSAENOTEMPTY: Result := _WSAENOTEMPTY;
    WSAEPROCLIM: Result := _WSAEPROCLIM;
    WSAEUSERS: Result := _WSAEUSERS;
    WSAEDQUOT: Result := _WSAEDQUOT;
    WSAESTALE: Result := _WSAESTALE;
    WSAEREMOTE: Result := _WSAEREMOTE;
    WSASYSNOTREADY: Result := _WSASYSNOTREADY;
    WSAVERNOTSUPPORTED: Result := _WSAVERNOTSUPPORTED;
    WSANOTINITIALISED: Result := _WSANOTINITIALISED;
    WSAHOST_NOT_FOUND: Result := _WSAHOST_NOT_FOUND;
    WSATRY_AGAIN: Result := _WSATRY_AGAIN;
    WSANO_RECOVERY: Result := _WSANO_RECOVERY;
    WSANO_DATA: Result := _WSANO_DATA;
  else Result := _WSAUNKNOWN + ' (' + IntToCommaStr(ErrorCode) + ')';
  end;
end;

function ByteSwap4(long: Cardinal): Cardinal;
begin
  result := ntohl(long);
end;

function ByteSwap2(short: smallint): smallint;
begin
  result := ntohs(short);
end;

function IPIntToIPStr(IPAddr: Integer): string;
var
  Ws: string;

begin
  Setlength(Ws, 4);
  Move(IPAddr, Ws[1], 4);
  Result := IntToStr(Ord(Ws[1])) + '.' +
    IntToStr(Ord(Ws[2])) + '.' +
    IntToStr(Ord(Ws[3])) + '.' +
    IntToStr(Ord(Ws[4]));
end;

function IPStrToIPInt(IPAddr: string): Integer;
var
  Ws: string;

begin
  Setlength(Ws, 4);
  Ws[1] := Char(StrToInt(FetchByChar(IPAddr, '.', False)));
  Ws[2] := Char(StrToInt(FetchByChar(IPAddr, '.', False)));
  Ws[3] := Char(StrToInt(FetchByChar(IPAddr, '.', False)));
  Ws[4] := Char(StrToInt(FetchByChar(IPAddr, '.', False)));
  Move(Ws[1], Result, 4);
end;

function SocketLayerLoaded: Boolean;
begin
  Result := (StartupResult = 999);
end;

procedure GetSocketVersion(WinsockInfo: PWinsockInfo);
begin
{$IFDEF LINUX}
  with WinsockInfo^ do begin
    Major_Version := 2;
    Minor_Version := 0;
    Highest_Major_Version := 2;
    Highest_Minor_Version := 0;
    Move('Linux Socket Layer 2.0', Description, 256);
    Move('Ready', SystemStatus, 128);
    MaxSockets := 65000;
    MaxUDPDatagramSize := 1500;
    VendorInfo := 'Brain Patchwork DX, LLC.';
  end;
{$ELSE}
  with WinsockInfo^ do begin
    Major_Version := BYTE(DllData.wVersion);
    Minor_Version := BYTE(DllData.wVersion);
    Highest_Major_Version := BYTE(DllData.wHighVersion);
    Highest_Minor_Version := BYTE(DllData.wHighVersion);
    Move(DllData.szDescription, Description, 256);
    Move(DllData.szSystemStatus, SystemStatus, 128);
    MaxSockets := DllData.iMaxSockets;
    MaxUDPDatagramSize := DllData.iMaxUdpDg;
    VendorInfo := DllData.lpVendorInfo;
  end;
{$ENDIF}
end;

function ntohs(netshort: Word): Word;
begin
  Result := {$IFDEF LINUX}Libc.
{$ELSE}Winsock.
{$ENDIF}ntohs(Netshort);
end;

function inet_ntoa(inaddr: in_addr): PChar;
begin
  Result := {$IFDEF LINUX}Libc.
{$ELSE}Winsock.
{$ENDIF}inet_ntoa(inaddr);
end;

function htonl(Hostlong: Integer): Integer;
begin
  Result := {$IFDEF LINUX}Libc.
{$ELSE}Winsock.
{$ENDIF}htonl(Hostlong);
end;

function ntohl(Netlong: Integer): Integer;
begin
  Result := {$IFDEF LINUX}Libc.
{$ELSE}Winsock.
{$ENDIF}ntohl(netlong)
end;



////////////////////////////////////////////////////////////////////////////////
{ TSocketClient }

function TAsioClient.Connto(IIP: string; Iport: Word): boolean;
var
  lp: TNewConnect;
begin
  Result := false;
  FHost := IIP;
  FPort := Iport;
  lp.Port := Iport;
  lp.ipAddress := IIP;
  lp.UseUDP := false;
  lp.UseBlocking:=true;
  lp.UseNAGLE:=true;
  Result := Connect(@lp);
end;

constructor TAsioClient.Create;
begin
  inherited Create;
  Socket := self;
  OnCreate;
end;

destructor TAsioClient.Destroy;
begin
  OnDestory;
  CloseNow;

  inherited;
end;

function TAsioClient.GetCanUseSize: integer;
begin
  Result := Self.ReceiveLength;
end;

function TAsioClient.GetHead: Integer;
begin
  Result := ReadInteger;
end;

function TAsioClient.Getipandport(IConn: TAsioClient): string;
begin
  Result := format('%S:%d', [PeerIPAddress, PeerPort]);
end;

procedure TAsioClient.GetObject(IObj: TObject; IClass: TClass);
var
  Ltep: pint;
begin
  IObj := TClass.Create;
  Ltep := Pointer(Iobj);
  inc(Ltep);
  ReadBuffer(Ltep, Iobj.InstanceSize - 4);
end;

procedure TAsioClient.GetObject(IObj: TObject);
var
  Ltep: pint;
begin
  Ltep := Pointer(Iobj);
  inc(Ltep);
  ReadBuffer(Ltep, Iobj.InstanceSize - 4);
end;

function TAsioClient.GetStream(IStream: TStream; IConn: TAsioClient):
  integer;
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
    i := ReadBuffer(PansiChar(LBuff) + x, ltot);
    Dec(ltot, i);
    inc(x, i);
  end; // while
//  DeCompressStream(LZipMM);
end;



function TAsioClient.GetZipFile(IFileName: string): integer;
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
      i := ReadBuffer(PansiChar(LBuff) + x, ltot);
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

function TAsioClient.GetZipStream(IStream: TStream; IConn: TAsioClient):
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
    i := ReadBuffer(PansiChar(LBuff) + x, ltot);
    Dec(ltot, i);
    inc(x, i);
  end; // while
  DeCompressStream(LZipMM);
end;

procedure TAsioClient.SendAsioHead(Ilen: integer);
begin
  WriteInteger(Ilen);
  WriteInteger(Ilen);
end;

procedure TAsioClient.SendHead(ICmd: Integer);
begin
  WriteInteger(ICmd);
end;

procedure TAsioClient.SendObject(IObj: TObject);
var
  Ltep: Pint;
begin
  Ltep := Pointer(IObj);
  inc(Ltep);
  Write(ltep, IObj.InstanceSize - 4);
end;

procedure TAsioClient.SendZipFile(IFileName: string);
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

function TAsioClient.SendZIpStream(IStream: tStream; IConn: TAsioClient;
  IisEnc: boolean = false): Integer;
begin
  if IisEnc = false then
    EnCompressStream(TMemoryStream(IStream));
  IConn.WriteInteger(IStream.Size);
  IConn.Write(TMemoryStream(IStream).Memory, IStream.Size);
  Result := IStream.Size;
end;

procedure TAsioClient.SetConnParam(Ihost: string; Iport: word);
begin
  FHost := Ihost;
  FPort := Iport;

end;

procedure TAsioClient.WriteBuff(var obj; Ilen: integer);
begin
  Write(@obj, Ilen);
end;

procedure TAsioClient.WriteStream(Istream: TStream);
begin
  WriteInteger(Istream.Size);
  Write(TMemoryStream(Istream).Memory, Istream.Size);
end;


function TDXSock.GetReleaseDate: string;
begin
  Result := '2012-02-19';
end;

procedure TDXSock.SetReleaseDate(value: string);
begin
       // Absorb!
end;

constructor TDXSock.Create;
begin
  inherited Create; // RC2
  FReadTimeout := False;
//   GetMem (FPeekBuffer,PeekBufferSize) ;
  FPeekBuffer := System.GetMemory(PeekBufferSize);
  fChunkBuf := nil;
  SetFBlockSizeFlags(bsfNormal);
  if not SocketLayerLoaded then
    ShowMessage('Fatal Socket Error' + '(WSAStartup) ' + GetErrorStr);
  fTooManyCharacters := 2048;
  Sock := INVALID_SOCKET;
  fbIsUDP := False;
  fbIsKeepAlive := False;
  fbClientMode := False;
  FUseBlocking := True;
  GlobalPeerPort := 0;
  GlobalPeerIPAddress := '';
//   GlobalTimeout.tv_Sec:=0;
//   GlobalTimeout.tv_uSec:=1000; // was 10000 4RC2
  VarConstSizeofTSockAddrIn := ConstSizeofTSockAddrIn;
end;

destructor TDXSock.Destroy;
begin
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.EndTransaction;
  end;
{$ENDIF}
{$IFDEF TLS_EDITION}
  if assigned(tstack) then begin
    tStack.Free;
    tStack := nil;
  end;
{$ENDIF}
  if Assigned(fChunkBuf) then
//      FreeMem (fChunkBuf,fActualBlockSize);
    System.FreeMemory(fChunkBuf);
  fChunkBuf := nil;
//   FreeMem (FPeekBuffer,PeekBufferSize);
  System.FreeMemory(FPeekBuffer);
  if Sock <> INVALID_SOCKET then
    CloseNow;
  inherited Destroy;
end;

function TDXSock.IsConning: Boolean;
begin
  Result := IsConnected;
end;

function TDXSock.WriteString(const s: string): Integer;
begin
  Result := Write(s);
end;


function TDXSock.CloseConn: Boolean;
begin
  CloseNow;
  Result := True;
end;




procedure TDXSock.SetTimeoutAndBuffer(SocketHandle: Integer);
begin
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.SetTimeoutAndBuffer(' + IntToStr(SocketHandle) + ')');
  end;
{$ENDIF}
  ResetBufferAndTimeout(SocketHandle, TDXXferTimeout, TDXMaxSocketBuffer);
  FErrStatus := 0;
end;

function TDXSock.Connect(Parameters: PNewConnect): Boolean;
begin
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.StartTransaction;
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.Connect');
  end;
{$ENDIF}
  fTotalWBytes := 0;
  fTotalRBytes := 0;
  Result := False;

  with Parameters^ do begin
    FUseBlocking := UseBlocking;
    fbIsUDP := UseUDP;
    Sock := ClientConnectToServer(ipAddress, Port, UseUDP, UseNAGLE, @SockAddr, FErrStatus);
    if (FErrStatus <> 0) then
      Exit;
    GlobalPeerPort := ntohs(SockAddr.sin_port);
    GlobalPeerIPAddress := inet_ntoa(SockAddr.sin_addr);
    SetBlocking(Sock, UseBlocking, FErrStatus);
    fbIsKeepAlive := False;
    if not FbIsUDP then begin
      SetSockStatusBool(Sock, SO_KeepAlive, True, FErrStatus);
      fbIsKeepAlive := FErrStatus = 0;
    end;
    SetTimeoutAndBuffer(Sock);
//      if FbIsUDP then begin
    SetReceiveBuffer(Sock, TDXMaxSocketBuffer * 4, FErrStatus);
    if FErrStatus <> 0 then
      SetReceiveBuffer(Sock, TDXMaxSocketBuffer * 3, FErrStatus);
    if FErrStatus <> 0 then
      SetReceiveBuffer(Sock, TDXMaxSocketBuffer * 2, FErrStatus);
    if FErrStatus <> 0 then
      SetReceiveBuffer(Sock, TDXMaxSocketBuffer, FErrStatus);
//      end;
  end;
  fbClientMode := True;
  Result := True;
  fCPSStart := Now;
end;

function TDXSock.Listen(Parameters: PNewListen): Boolean;
begin
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.StartTransaction;
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.Listen');
  end;
{$ENDIF}
  Result := False;
  with Parameters^ do begin
    FUseBlocking := UseBlocking;
    Sock := BindAndListen(fsBindTo, Port, WinsockQueue, UseUDP, UseNAGLE,
      Connectionless, @SockAddr, FErrStatus);
    fbIsUDP := UseUDP;
    if Sock = Invalid_Socket then
      Exit; // linux does not set FErrStatus!
    if FErrStatus = 0 then
      SetBlocking(Sock, UseBlocking, FErrStatus)
    else
      Exit;
    if not fbIsUDP then begin
      SetSockStatusBool(Sock, SO_KeepAlive, True, FErrStatus);
      fbIsKeepAlive := fErrStatus = 0;
    end;
    SetTimeoutAndBuffer(Sock);
    SetReceiveBuffer(Sock, TDXMaxSocketBuffer * 4, FErrStatus);
    if FErrStatus <> 0 then
      SetReceiveBuffer(Sock, TDXMaxSocketBuffer * 3, FErrStatus);
    if FErrStatus <> 0 then
      SetReceiveBuffer(Sock, TDXMaxSocketBuffer * 2, FErrStatus);
    if FErrStatus <> 0 then
      SetReceiveBuffer(Sock, TDXMaxSocketBuffer, FErrStatus);
  end;
  fErrStatus := 0;
  fbClientMode := False;
  Result := True;
  GlobalPeerPort := 0;
  GlobalPeerIPAddress := '';
end;

function TDXSock.Accept(var NewSock: TDXSock): Boolean;
var
  ICreatedIt: Boolean;

begin
  Result := False;
  if Sock = INVALID_SOCKET then
    exit;
  Result := IsAcceptWaiting(Sock);
  if (not Result) or fbIsUDP then
    Exit;
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.Accept');
  end;
{$ENDIF}
  ICreatedIt := not Assigned(NewSock);
  if ICreatedIt then
    NewSock := TDXSock.Create(); // RC2
  NewSock.Sock := AcceptNewConnect(Sock, @NewSock.SockAddr, @VarConstSizeofTSockAddrIn, FErrStatus);
  if FErrStatus <> 0 then begin
    NewSock.Sock := Invalid_Socket;
    if ICreatedIt then begin
      NewSock.Free;
      NewSock := nil;
    end;
    Result := False;
    Exit;
  end;
  NewSock.GlobalPeerPort := ntohs(NewSock.SockAddr.sin_port);
  NewSock.GlobalPeerIPAddress := inet_ntoa(NewSock.SockAddr.sin_addr);
  NewSock.fbClientMode := False;
  NewSock.fCPSStart := Now;
//   SetTimeoutAndBuffer(NewSock.Sock);
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    NewSock.DXCodeTracer := CodeTracer; // link new sessions automatically
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.Accepted/Configured');
  end;
{$ENDIF}
end;

{$IFDEF SUPPORT_DESIGNTIME_CLIENTS}

procedure ProcessMessages;
var
  MsgRec: TMsg;

begin
  if not IsConsole then
    if PeekMessage(MsgRec, 0, 0, 0, PM_REMOVE) then begin
      TranslateMessage(MsgRec);
      DispatchMessage(MsgRec)
    end;
end;
{$ENDIF}

{$IFDEF VER100}

function TDXSock.BlockWrite(buf: Pointer; len: Integer): Integer;
{$ELSE}

  function TDXSock.Write(buf: Pointer; len: Integer): Integer;
  {$ENDIF}
  var
    BytesLeft: Integer;
    BytesSent: Integer;
    XferSize: Integer;
    TmpP: Pointer;
    Filtered: Pointer;
    NewLen: Integer;
    Handled: Boolean;

  begin
{$IFDEF TLS_EDITION}
    DoSleepEx(0);
{$ENDIF}
    Result := 0;
    if Sock = INVALID_SOCKET then
      Exit;
    if (Len < 1) then begin
      if fbIsUDP then begin
        UDPSend(Sock, Buf^, 0, 0, SockAddr, ConstSizeofTSockAddrIn, FErrStatus); // 2.3 - empty udp packet
        GlobalPeerPort := ntohs(SockAddr.sin_port);
        GlobalPeerIPAddress := inet_ntoa(SockAddr.sin_addr);
      end;
      Exit;
    end;
    NewLen := 0;
    if Assigned(feOnFilter) then begin
      Handled := False;
      Filtered := nil;
      feOnFilter(ddAboutToWrite, Buf, Filtered, Len, NewLen, Handled, FClientThread);
      if not Handled then begin
        fErrStatus := 9999; {onFilter failed!}
        Exit;
      end;
    end;
    if fbIsUDP then begin
      if NewLen = 0 then
        Result := UDPSend(Sock, Buf^, Len, 0, SockAddr, ConstSizeofTSockAddrIn, FErrStatus)
      else begin
        Result := UDPSend(Sock, Filtered^, NewLen, 0, SockAddr, ConstSizeofTSockAddrIn, FErrStatus);
        if Assigned(feOnFilter) then
          feOnFilter(ddFreePointer, Filtered, Filtered, NewLen, NewLen, Handled, FClientThread);
      end;
      GlobalPeerPort := ntohs(SockAddr.sin_port);
      GlobalPeerIPAddress := inet_ntoa(SockAddr.sin_addr);
      Exit;
    end;
    if NewLen = 0 then begin
      BytesLeft := Len;
      TmpP := Buf;
    end
    else begin
      BytesLeft := NewLen;
      Len := NewLen;
      TmpP := Filtered;
    end;
    fErrStatus := 0;
    repeat
{$IFDEF SUPPORT_DESIGNTIME_CLIENTS}
      ProcessMessages;
{$ENDIF}
      XferSize := BytesLeft;
      if IsWritAble then begin
// DXS4 do not remove this line: it is manditory!
        if XFerSize > FActualBlockSize then
          XFerSize := FActualBlockSize;
        BytesSent := BasicSend(Sock, TmpP^, XferSize, 0, FErrStatus);
{$IFDEF CODE_TRACER}
        if Assigned(CodeTracer) then begin
          CodeTracer.SendMessage(dxctDebug, 'TDXSock.Write SENT: [' + IntToStr(BytesSent) + ' bytes] FErrStatus=' + IntToStr(FErrStatus));
        end;
{$ENDIF}
        case BytesSent of
          -1: begin
              case fErrStatus of
                WSAETIMEDOUT,
                  WSAENOBUFS,
                  WSAEWOULDBLOCK: fErrStatus := 0;
                WSAECONNABORTED, WSAECONNRESET: begin
                    CloseNow;
                  end;
//                  else ShowMessageWindow('','unknown fErrStatus='+IntToStr(fErrStatus));
              end;
            end;
          0: begin
//               ShowMessageWindow('','ReadError(0) '+IntToStr(fErrStatus));
              CloseNow;
            end;
        else begin
            if BytesSent > 0 then
              Dec(BytesLeft, BytesSent);
            if (BytesLeft > 0) and (fErrStatus = 0) then begin // 3.0 [major bug fix!!]
              Inc(LongInt(TmpP), BytesSent);
            end;
          end;
        end;
      end; // Is Write able.
    until (BytesLeft = 0) or (FErrStatus <> 0) or (sock = Invalid_Socket);
    Result := Len - BytesLeft;
    if Result > 0 then
      fTotalWBytes := fTotalWBytes + Result;
    if Assigned(feOnFilter) then
      feOnFilter(ddFreePointer, nil, Filtered, NewLen, NewLen, Handled, FClientThread);
  end;

  function TDXSock.WriteInteger(const n: integer): integer;
  var
    x: integer;
  begin
{$IFDEF CODE_TRACER}
    if Assigned(CodeTracer) then begin
      CodeTracer.SendMessage(dxctDebug, 'TDXSock.WriteInteger(' + IntToStr(N) + ')');
    end;
{$ENDIF}
    x := htonl(n);
{$IFDEF VER100}
    result := BlockWrite(@x, sizeof(x));
{$ELSE}
    result := Write(@x, sizeof(x));
{$ENDIF}
  end;

{$IFDEF VER100}

  function TDXSock.WriteCh(c: Char): Integer;
  {$ELSE}

    function TDXSock.Write(c: Char): Integer;
    {$ENDIF}
    begin
  {$IFDEF CODE_TRACER}
      if Assigned(CodeTracer) then begin
        CodeTracer.SendMessage(dxctDebug, 'TDXSock.WriteCh(' + C + ')');
      end;
  {$ENDIF}
  {$IFDEF VER100}
      Result := BlockWrite(@C, 1);
  {$ELSE}
      Result := Write(@C, 1);
  {$ENDIF}
    end;

    function TDXSock.Write(const s: string): Integer;
    begin
  {$IFDEF CODE_TRACER}
      if Assigned(CodeTracer) then begin
        CodeTracer.SendMessage(dxctDebug, 'TDXSock.Write(' + S + ')');
      end;
  {$ENDIF}
  {$IFDEF VER100}
      Result := BlockWrite(@S[1], Length(S));
  {$ELSE}
      Result := Write(@S[1], Length(S));
  {$ENDIF}
    end;

    function TDXSock.WriteLn(const s: string): Integer;
    var
      Len: Integer;
      Ws: string;

    begin
  {$IFDEF CODE_TRACER}
      if Assigned(CodeTracer) then begin
        CodeTracer.SendMessage(dxctDebug, 'TDXSock.WriteLn(' + S + ')');
      end;
  {$ENDIF}
      if Assigned(feOnFilter) then begin
        Len := 2;
        Result := Write(S) + Len; // send via filter
        Ws := #13#10;
        if fbIsUDP then begin // append CRLF unfiltered!
          UDPSend(Sock, Ws[1], Len, 0, SockAddr, ConstSizeofTSockAddrIn, FErrStatus);
        end
        else begin
          BasicSend(Sock, Ws[1], Len, 0, FErrStatus);
        end;
      end
      else
        Result := Write(S + #13#10);
    end;

    function TDXSock.WriteResultCode(const Code: Integer; const Rslt: string): Integer;
    begin
  {$IFDEF CODE_TRACER}
      if Assigned(CodeTracer) then begin
        CodeTracer.SendMessage(dxctDebug, 'TDXSock.WriteResult()');
      end;
  {$ENDIF}
      Result := Writeln(IntToStr(Code) + #32 + Rslt);
    end;

    function TDXSock.ReadInteger: integer;
    var
      n: integer;
      cnt: integer;

    begin
  {$IFDEF VER100}
      cnt := BlockRead(@n, sizeof(n));
  {$ELSE}
      cnt := Read(@n, sizeof(n));
  {$ENDIF}
      if cnt = sizeof(n) then begin
        n := ntohl(n);
        result := n;
      end
      else
        result := -1;
  {$IFDEF CODE_TRACER}
      if Assigned(CodeTracer) then begin
        CodeTracer.SendMessage(dxctDebug, 'TDXSock.ReadInteger=' + IntToStr(Result));
      end;
  {$ENDIF}
    end;

  {$IFDEF VER100}

function TDXSock.BlockRead(buf: Pointer; len: Integer): Integer;
{$ELSE}

function TDXSock.Read(buf: Pointer; len: Integer): Integer;
{$ENDIF}
var
  UDPAddrSize: Integer;
//   Tries:Integer;
{$IFDEF TLS_EDITION}
  Filtered, InData: Pointer;
  Handled: Boolean;
  NewLen: Integer;
  StartTime: Longword;
  SizeToRead: Integer;
{$ENDIF}

begin
{$IFDEF TLS_EDITION}
  DoSleepEx(0);
{$ENDIF}
  fReadTimeout := False;
  Result := 0;
  if (Sock = INVALID_SOCKET) or (Len < 1) then
    exit;
//   Tries:=0;
  if fbIsUDP then begin
    UDPAddrSize := ConstSizeofTSockAddrIn;
    Result := UDPRecv(Sock, Buf^, Len, 0, SockAddr, UDPAddrSize, FErrStatus);
    GlobalPeerPort := ntohs(SockAddr.sin_port);
    GlobalPeerIPAddress := inet_ntoa(SockAddr.sin_addr);
  end
  else begin
{$IFNDEF TLS_EDITION}
//      if (CountWaiting>0) or (Tries>=3) then begin
    Result := BasicRecv(Sock, Buf^, Len, 0, FErrStatus);
{$IFDEF CODE_TRACER}
    if Assigned(CodeTracer) then begin
      if (Result = -1) and ((fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK)) then {absorb}
      else if Result > 0 then
        CodeTracer.SendMessage(dxctDebug, 'TDXSock.Read RECV: ' + PChar(Buf) + ' [' + IntToStr(Result) + '] fes=' + IntToStr(FErrStatus))
      else
        CodeTracer.SendMessage(dxctDebug, 'TDXSock.Read RECV: [' + IntToStr(Result) + '] fes=' + IntToStr(FErrStatus));
    end;
{$ENDIF}
 //     end;
{$ELSE}
//      if (CountWaiting>0) or (Tries>=3) then begin
    if Assigned(feOnFilter) then begin
      SetBlocking(True);
      SizeToRead := 0;
      StartTime := DxString.TimeCounter + 120000;
      while (SizeToRead = 0) and Connected and (not DXString.Timeout(StartTime)) do begin
        ioctlsocket(Sock, FIONREAD, Longint(SizeToRead));
        DoSleepEx(1);
      end;
      if SizeToRead <> 0 then begin
        InData := nil;
        Filtered := nil;
//               GetMem (InData,SizeToRead) ;
        InData := System.GetMemory(SizeToRead);
        Result := Recv(Sock, InData^, SizeToRead, 0);
      end;
    end
    else
      Result := BasicRecv(Sock, Buf^, Len, 0, FErrStatus);
//      end;
  end;
  if Result = 0 then
    CloseGracefully;
  fReadTimeout := Result < 1;
  if (Result > 0) and Assigned(feOnFilter) then begin
    Handled := False;
    Len := 0;
    feOnFilter(ddAfterRead, InData, Filtered, SizeToRead, Len, Handled, FClientThread);
    if not Handled then begin
      fErrStatus := 9999; {onFilter failed!}
      if InData <> nil then begin
//            FreeMem (InData,SizeToRead) ;
        System.FreeMemory(InData);
        InData := nil;
      end;
      CloseGracefully;
    end
    else
      Result := Len;
    if Filtered = nil then
      Result := 0;
    if Filtered <> nil then
      Move(Filtered^, Buf^, Len);
    if InData <> nil then begin
//         FreeMem (InData,SizeToRead) ;
      System.FreeMemory(InData);
      InData := nil;
    end;
    feOnFilter(ddFreePointer, nil, Filtered, Len, Len, Handled, FClientThread);
  end;
{$ENDIF}
end;
fReadTimeout := Result < 1;
if Result = 0 then
  CloseGracefully
else if Result > 0 then
  fTotalRBytes := fTotalRBytes + Result;
end;

function TDXSock.Read: Char;
var
  Size: Integer;

begin
{$IFDEF VER100}
  Size := BlockRead(@Result, 1);
{$ELSE}
  Size := Read(@Result, 1);
{$ENDIF}
  if Size < 1 then
    Result := #0;
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.Read=' + Result);
  end;
{$ENDIF}
end;

function TDXSock.ReadStr(MaxLength: Integer): string;
var
  Size: Integer;
  Ctr: Integer;
  Done: Boolean;
  ReadSize: Integer;

begin
  fReadTimeout := False;
  if Sock = INVALID_SOCKET then
    Exit;
  Result := '';
  if MaxLength = 0 then
    Exit;
  Size := MaxLength;
  if MaxLength < 0 then
    Size := TDXHugeSize;
  Setlength(Result, Size);
  fErrStatus := 0;
  Ctr := 0;
  Done := False;
  while (not Done) and (IsConnected) do begin
{$IFDEF VER100}
    ReadSize := BlockRead(@Result[Ctr + 1], Size - Ctr);
{$ELSE}
    ReadSize := Read(@Result[Ctr + 1], Size - Ctr);
{$ENDIF}
    Done := (Ctr + ReadSize = Size) or
      ((ReadSize = -1) and (MaxLength = -1));
    if not Done then begin
      if ReadSize > 0 then
        Inc(Ctr, ReadSize);
      if (ReadSize > 0) and
        (MaxLength = -1) and
        (CountmyWaiting = 0) then begin
        Done := True;
      end
      else begin
        DoSleepEx(1); // allow sockets to digest tcpip.sys packets...
        ProcessWindowsMessageQueue;
      end;
    end
    else
      fErrStatus := 0;
  end;
  if (((fErrStatus <> 0) and (fErrStatus <> WSAETIMEDOUT) and (fErrStatus <> WSAEWOULDBLOCK))) or (Size = 0) then
    Result := ''
  else if (Size = Socket_Error) then
    Result := ''
  else begin
    Setlength(Result, MaxLength);
    fReadTimeout := False;
  end;
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    if Result <> '' then
      CodeTracer.SendMessage(dxctDebug, 'TDXSock.ReadStr=' + Result);
  end;
{$ENDIF}
end;

function TDXSock.ReadString(MaxLength: Integer; iTimeout: Longword): string;
var
  Size: Integer;
  StartTime: Comp;

begin
  if (MaxLength < 1) or (MaxLength > 250) then begin // 4RC2
    Result := ReadStr(MaxLength);
    Exit;
  end;
  Result := '';
  fReadTimeout := False;
  if Sock = INVALID_SOCKET then
    Exit;
  fReadTimeout := False;
  StartTime := TimeCounter + iTimeout;
  fErrStatus := 0;
  while (CountmyWaiting < MaxLength) and
    (not Timeout(StartTime)) and
    (IsConnected) do begin
    DoSleepEx(1);
  end;
  if (CountmyWaiting < MaxLength) then begin
    fReadTimeout := True;
    Exit;
  end;
  Setlength(Result, MaxLength);
  FillChar(Result[1], MaxLength, 0);
{$IFDEF VER100}
  Size := BlockRead(@Result[1], MaxLength);
{$ELSE}
  Size := Read(@Result[1], MaxLength);
{$ENDIF}
  if (((fErrStatus <> 0) and (fErrStatus <> WSAETIMEDOUT) and (fErrStatus <> WSAEWOULDBLOCK))) or (Size = 0) then
    Result := ''
  // 3.0
  else if (Size = Socket_Error) then
    Result := ''
  else
    Setlength(Result, Size);
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.ReadString=' + Result);
  end;
{$ENDIF}
end;

function TDXSock.GetChar: Str1;
var
  Size: Integer;

begin
// 7-27   SetLength(Result, 1);
  Result := #32;
{$IFDEF VER100}
  Size := BlockRead(@Result[1], 1);
{$ELSE}
  Size := Read(@Result[1], 1);
{$ENDIF}
  case Size of
    0: begin
        CloseNow;
        Result := '';
      end;
    1: begin
      end;
  else begin
      if (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK) then
        fReadTimeout := False;
      Result := '';
    end;
  end;
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.GetChar=' + Result);
  end;
{$ENDIF}
end;

function TDXSock.GetByte: Byte;
var
  L: Str1;

begin
  L := GetChar;
  if L = '' then
    Result := 0
  else
    Result := Ord(L[1]);
end;

function TDXSock.ReadLn(iTimeout: Longword = 100000): string;
var
  markerCR, markerLF: Integer;
  s: string;
  startTime: Comp;
  LastChar: Str1;
  pstring: string;

{$IFDEF TLS_EDITION}
  function TestStack(ts: TMJBLIFO): Boolean;
  begin
    Result := False;
    if assigned(tStack) then
      Result := ts.ItemCount > 0
    else
      tStack := TMJBLIFO.Create;
  end;
{$ENDIF}

begin
  Result := '';
  fReadTimeout := False;
  if Sock = INVALID_SOCKET then
    exit;
{$IFDEF TLS_EDITION}
  if FTLS = True then begin
    if TestStack(tStack) then
      Result := tStack.Pop
    else begin
      pString := ReadStr(-1);
      if pString = '' then
        pString := ReadStr(-1);
  //   If pString[1] = #0 Then pString := ReadStr(-1);
      if Straggler <> '' then
        pString := Straggler + pString;
{$IFDEF OBJECTS_ONLY}
      tBuf := TBrkApart.Create;
{$ELSE}
      tBuf := TBrkApart.Create(nil);
{$ENDIF}
      tBuf.AllowEmptyString := True;
      tBuf.BaseString := pString;
      tBuf.BreakString := #13#10;
      tBuf.BreakApart;
      MarkerLF := tbuf.StringList.Count - 2; // Allow for last String as CRLF
      for markerCR := MarkerLF downto 0 do begin
        tStack.Push(tbuf.StringList.Strings[markerCR]);
      end;
      Straggler := tBuf.Straggler;
      FreeAndNil(tBuf);
      if tStack.ItemCount > 0 then
        Result := tStack.Pop
      else
        Result := pString;
    end;
    Exit;
  end;
{$ENDIF}
  S := GetChar;
  LastChar := S;
  if (Sock = INVALID_SOCKET) {or (fReadTimeout) removed 7-27} then
    exit;
  MarkerLF := 0;
  MarkerCR := 0;
  fErrStatus := 0;
  StartTime := TimeCounter + iTimeout;
  while (Sock <> Invalid_Socket) and
    (MarkerLF + MarkerCR = 0) and
    (not Timeout(StartTime)) and
    (Length(S) < fTooManyCharacters) and
    ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT)
    // 7-27:
    or (fErrStatus = WSAEWOULDBLOCK)) do begin
    if fErrStatus = WSAEWOULDBLOCK then
      ProcessWindowsMessageQueue;
    if (LastChar = '') or (not (LastChar[1] in [#10, #13])) then begin {handles getchar from above!}
      pString := PeekString;
      if Timeout(StartTime) then
        Break;
      if (pString = '') then begin
        LastChar := GetChar;
      end
      else begin
        MarkerLF := CharPos(#10, pString);
        MarkerCR := CharPos(#13, pString);
        if MarkerLF + MarkerCR > 0 then begin
          if MarkerLF = 0 then
            MarkerLF := MarkerCR
          else if MarkerCR = 0 then
            MarkerCR := MarkerLF;
          if Min(MarkerLF, MarkerCR) > 1 then // 2.4
            S := S + Copy(pString, 1, Min(MarkerLF, MarkerCR) - 1);
          ReadStr(Min(MarkerLF, MarkerCR));
          LastChar := #13;
        end
        else begin
          S := S + pString;
          ReadStr(Length(pString));
          LastChar := '';
        end;
      end;
      if Timeout(StartTime) then
        Break;
      if LastChar > '' then begin
        S := S + LastChar;
      end;
    end;
    if (Length(LastChar) > 0) and (LastChar[1] in [#10, #13]) then begin
      MarkerLF := CharPos(#10, S);
      MarkerCR := CharPos(#13, S);
      if MarkerLF + MarkerCR > 0 then begin
        if MarkerLF = Length(S) then begin {unix or DOS}
          if MarkerCR = 0 then begin {unix or Mac}
            if CountmyWaiting > 0 then
              if PeekChar = #13 then begin {Mac}
                LastChar := GetChar;
                S := S + LastChar;
              end;
          end
          else if MarkerCR < MarkerLF then
            MarkerLF := MarkerCR;
          MarkerCR := MarkerLF;
        end;
        if MarkerCR = Length(S) then begin {Mac or DOS}
          if MarkerLF = 0 then begin {Mac or DOS}
            if CountmyWaiting > 0 then
              if PeekChar = #10 then begin {DOS}
                LastChar := GetChar;
                S := S + LastChar;
              end;
          end
          else if MarkerLF < MarkerCR then
            MarkerCR := MarkerLF;
          MarkerLF := MarkerCR;
        end;
      end;
    end;
  end;
  if Sock = INVALID_SOCKET then
    exit;
  FReadTimeout := (MarkerCR < 1) and (Timeout(StartTime));
  Result := Copy(S, 1, MarkerCR - 1);
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.ReadLn=' + Result);
  end;
{$ENDIF}
end;

function TDXSock.ReadCRLF(iTimeout: Longword): string;
begin
  Result := ReadToAnyDelimiter(iTimeout, #13#10);
end;
{var
  marker: Integer;
  s: string;
  startTime: Longword;

begin
  Result := '';
  fReadTimeout := False;
  if Sock = INVALID_SOCKET then exit;
  Marker := 0;
  StartTime := TimeCounter + Timeout;
  fErrStatus := 0;
  while (sock <> Invalid_Socket) and
    (Marker = 0) and
    (not DXString.Timeout(StartTime)) and
    (Length(S) < fTooManyCharacters) and
    ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT)) do begin
    S := S + GetChar;
    Marker := QuickPos(#13#10, S);
  end;
  if Sock = INVALID_SOCKET then exit;
  Result := Copy(S, 1, Marker - 1);
end;}

function TDXSock.ReadToAnyDelimiter(iTimeout: Longword; Delimiter: string):
  string;
var
  slen: Integer;
  marker: Integer;
  s: string;
  startTime: Comp;
  pString: string;
  iDel: Integer;

begin
  Result := '';
  fReadTimeout := False;
  if Sock = INVALID_SOCKET then
    exit;
  S := '';
  sLen := 0;
  StartTime := TimeCounter + iTimeout;
  Marker := 0;
  while (sock <> Invalid_Socket) and
    (Marker = 0) and
    (not Timeout(StartTime)) and
    (sLen < fTooManyCharacters) and
    ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK)) do begin
    pString := PeekString;
    if pString <> '' then begin
      sLen := Length(S);
      S := S + pString;
      Marker := QuickPos(Delimiter, S);
      if Marker = 0 then begin
        ReadStr(Length(pString)); // clear socket
      end
      else begin
        S := Copy(S, 1, Marker - 1);
        if Marker < sLen then
          iDel := Length(Delimiter) - (sLen - Marker)
        else
          iDel := (Marker - sLen) + Length(Delimiter);
//          If Marker<sLen then iDel:=Length(Delimiter)-(sLen-Marker+1)
//          Else iDel:=Marker-sLen+(Length(Delimiter)-1);
        ReadStr(iDel);
      end;
    end
    else begin
      pString := GetChar;
      if pString = '' then
        DoSleepEx(1)
      else begin
        Inc(sLen);
        S := S + pString;
      end;
    end;
  end;
  if Sock = INVALID_SOCKET then
    exit;
  fReadTimeout := Timeout(StartTime);
  Result := S; // return what ever is collected, even if not done!
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.ReadToAnyDelimeter=' + Result);
  end;
{$ENDIF}
end;

function TDXSock.ReadNull(Timeout: Longword): string;
begin
  Result := ReadToAnyDelimiter(Timeout, #0);
end;

function TDXSock.ReadSpace(Timeout: Longword): string;
begin
  Result := ReadToAnyDelimiter(Timeout, #32);
end;

function TDXSock.SendBuf(const Buf; Count: Integer): Integer; // Borland friendly
begin
{$IFDEF VER100}
  Result := BlockWrite(@Buf, Count);
{$ELSE}
  Result := Write(@Buf, Count);
{$ENDIF}
end;

function TDXSock.Readbuffer(iBuf: pointer; Count: Integer): Integer;
var
  ltot, i, X: Integer;
begin
  Result := -1;
  x := 0;
  while (ltot > 0) and Self.Connected do begin
    i := Read(PChar(iBuf) + x, ltot);
    Dec(ltot, i);
    inc(x, i);
  end; // while
  Result := x;
end;

function TDXSock.ReceiveBuf(var Buf; Count: Integer): Integer; // Borland friendly
begin
{$IFDEF VER100}
  Result := BlockRead(@Buf, Count);
{$ELSE}
  Result := Read(@Buf, Count);
{$ENDIF}
end;

function TDXSock.SendFrom(Stream: TStream): Boolean;
var
  Len: Integer;
  SSize, SPosition: Integer;
  Tries: Integer;

begin
{$IFDEF CODE_TRACER}
  if Assigned(CodeTracer) then begin
    CodeTracer.SendMessage(dxctDebug, 'TDXSock.SendFrom');
  end;
{$ENDIF}
  fErrStatus := 0;
  SSize := Stream.Size;
  SPosition := Stream.Position;
  Tries := 0;
  while (sock <> Invalid_Socket) and
    (Stream.Position < Stream.Size) and
    (fErrStatus = 0) and
    (Tries < 3) do begin
    if (SSize - SPosition) < FActualBlockSize then
      Len := SSize - SPosition
    else
      Len := FActualBlockSize;
    if Len > 0 then begin
      Stream.Seek(SPosition, 0);
      Stream.Read(fChunkBuf^, Len);
{$IFDEF VER100}
      Len := BlockWrite(fChunkBuf, Len);
{$ELSE}
      Len := Write(fChunkBuf, Len);
{$ENDIF}
      SPosition := SPosition + Len;
      if fErrStatus > 0 then begin
        Tries := 3;
      end
      else if Len < 1 then
        Inc(Tries)
      else
        Tries := 0;
    end;
  end;
  Result := (Sock <> INVALID_SOCKET) and (fErrStatus = 0);
end;

{$IFDEF VER100}

function TDXSock.SendFromStreamRange(Stream: TStream; Range: Integer): Boolean;
{$ELSE}

  function TDXSock.SendFrom(Stream: TStream; Range: Integer): Boolean;
  {$ENDIF}
  var
    Len: Integer;
    SSize, SPosition: Integer;
    Tries: Integer;

  begin
{$IFDEF CODE_TRACER}
    if Assigned(CodeTracer) then begin
      CodeTracer.SendMessage(dxctDebug, 'TDXSock.SendFromRange');
    end;
{$ENDIF}
    fErrStatus := 0;
    SSize := Range;
    SPosition := Stream.Position;
    Tries := 0;
    while (sock <> Invalid_Socket) and
      (Stream.Position < Stream.Size) and
      (fErrStatus = 0) and
      (Tries < 3) do begin
      if (SSize - SPosition) < FActualBlockSize then
        Len := SSize - SPosition
      else
        Len := FActualBlockSize;
      if Len > 0 then begin
        Stream.Seek(SPosition, 0);
        Stream.Read(fChunkBuf^, Len);
{$IFDEF VER100}
        Len := BlockWrite(fChunkBuf, Len);
{$ELSE}
        Len := Write(fChunkBuf, Len);
{$ENDIF}
        SPosition := SPosition + Len;
        if fErrStatus > 0 then begin
          Tries := 3;
        end
        else if Len < 1 then
          Inc(Tries)
        else
          Tries := 0;
      end;
    end;
    Result := (Sock <> INVALID_SOCKET) and (fErrStatus = 0);
  end;

{$IFDEF VER100}

  function TDXSock.SendFromWindowsFile(var Handle: Integer): boolean;
  {$ELSE}

    function TDXSock.SendFrom(var Handle: Integer): boolean;
    {$ENDIF}
    var
      Len: Integer;
      SLen: Integer;
      Offset: Integer;
      FSize: Integer;
      Tries: Integer;

    begin
  {$IFDEF CODE_TRACER}
      if Assigned(CodeTracer) then begin
        CodeTracer.SendMessage(dxctDebug, 'TDXSock.SendFrom');
      end;
  {$ENDIF}
      Result := False;
      fReadTimeout := False;
      if Sock = INVALID_SOCKET then
        Exit;
      if Handle <> 0 then begin
        Offset := FileSeek(Handle, 0, 1);
        FSize := FileSeek(Handle, 0, 2);
        FileSeek(Handle, Offset, 0);
        fErrStatus := 0;
        Tries := 0;
        while (sock <> Invalid_Socket) and
          (Offset < FSize) and
          (fErrStatus = 0) and
          (Tries < 3) do begin
          if Sock <> INVALID_SOCKET then begin
            Len := FileRead(Handle, fChunkBuf^, FActualBlockSize - 1);
            if Len > 0 then begin
  {$IFDEF VER100}
              SLen := BlockWrite(fChunkBuf, Len);
  {$ELSE}
              SLen := Write(fChunkBuf, Len);
  {$ENDIF}
              if SLen <> Len then begin
                Offset := SLen + Offset;
                FileSeek(Handle, Offset, 0);
                Inc(Tries);
              end
              else
                Tries := 0;
              if fErrStatus > 0 then
                Tries := 3;
            end;
          end;
          Offset := FileSeek(Handle, 0, 1);
        end;
      end;
      Result := (Sock <> INVALID_SOCKET) and (fErrStatus = 0);
    end;

  {$IFDEF VER100}

    function TDXSock.SendFromBorlandFile(var Handle: file): boolean;
    {$ELSE}

      function TDXSock.SendFrom(var Handle: file): boolean;
      {$ENDIF}
      var
        Len: Integer;
        SLen: Integer;
        OffSet: Integer;
        Tries: Integer;

      begin
    {$IFDEF CODE_TRACER}
        if Assigned(CodeTracer) then begin
          CodeTracer.SendMessage(dxctDebug, 'TDXSock.SendFrom');
        end;
    {$ENDIF}
        Result := False;
        fReadTimeout := False;
        if Sock = INVALID_SOCKET then
          Exit;
        fErrStatus := 0;
        Tries := 0;
        while not Eof(Handle) and (fErrStatus = 0) and (Tries < 3) and (sock <> Invalid_Socket) do begin
          Offset := System.FilePos(Handle);
          if (Sock <> INVALID_SOCKET) then begin
            System.BlockRead(Handle, fChunkBuf^, FActualBlockSize - 1, Len);
    {$IFDEF VER100}
            SLen := BlockWrite(fChunkBuf, Len);
    {$ELSE}
            SLen := Write(fChunkBuf, Len);
    {$ENDIF}
            if SLen = Len then begin
              Tries := 0;
            end
            else begin
              Offset := SLen + Offset;
              System.Seek(Handle, Offset);
              Inc(Tries);
            end;
            if fErrStatus > 0 then
              Tries := 3;
          end;
        end;
        Result := (Sock <> INVALID_SOCKET) and (fErrStatus = 0);
      end;

    {$IFDEF VER100}

      function TDXSock.SaveToStream(Stream: TStream; Timeout: Longword): Boolean;
      {$ELSE}

        function TDXSock.SaveTo(Stream: TStream; iTimeout: Longword): Boolean;
        {$ENDIF}
        var
          SLen: Integer;
          StartTime: Comp;
          OldSize: Integer;

        begin
      {$IFDEF CODE_TRACER}
          if Assigned(CodeTracer) then begin
            CodeTracer.SendMessage(dxctDebug, 'TDXSock.SaveTo');
          end;
      {$ENDIF}
          OldSize := Stream.Size;
          fErrStatus := 0;
          fReadTimeout := False;
          StartTime := TimeCounter + iTimeout;
          while ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK)) and
            (not Timeout(StartTime)) do begin
      {$IFDEF VER100}
            SLen := BlockRead(fChunkBuf, FActualBlockSize);
      {$ELSE}
            SLen := Read(fChunkBuf, FActualBlockSize);
      {$ENDIF}
            if SLen < 1 then begin
              if SLen = 0 then
                Break;
            end
            else
              Stream.Write(fChunkBuf^, SLen);
            if SLen < FActualBlockSize then
              Break; //GT for TLS Stops looping until timeout
          end;
          Result := (Sock <> INVALID_SOCKET) and ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK));
          if Result then
            Result := Stream.Size <> OldSize;
        end;

      {$IFDEF VER100}

        function TDXSock.SaveToWindowsFile(var Handle: Integer; Timeout: Longword): boolean;
        {$ELSE}

          function TDXSock.SaveTo(var Handle: Integer; iTimeout: Longword): boolean;
          {$ENDIF}
          var
            SLen: Integer;
          {$IFDEF VER100}
            STmp: Integer;
          {$ELSE}
            STmp: Cardinal;
          {$ENDIF}
            StartTime: Comp;

          begin
        {$IFDEF CODE_TRACER}
            if Assigned(CodeTracer) then begin
              CodeTracer.SendMessage(dxctDebug, 'TDXSock.SaveTo');
            end;
        {$ENDIF}
            fErrStatus := 0;
            fReadTimeout := False;
            StartTime := TimeCounter + iTimeout;
            while ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK)) and
              (not Timeout(StartTime)) do begin
        {$IFDEF VER100}
              SLen := BlockRead(fChunkBuf, FActualBlockSize);
        {$ELSE}
              SLen := Read(fChunkBuf, FActualBlockSize);
        {$ENDIF}
              STmp := 0;
              if SLen < 1 then begin
                if SLen = 0 then
                  Break;
              end
              else
                WindowsWriteFile(Handle, fChunkBuf^, SLen, STmp);
            end;
            Result := (Sock <> INVALID_SOCKET) and ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK));
          end;

        {$IFDEF VER100}

          function TDXSock.SaveToBorlandFile(var Handle: file; Timeout: Longword): boolean;
          {$ELSE}

            function TDXSock.SaveTo(var Handle: file; iTimeout: Longword): boolean;
            {$ENDIF}
            var
              SLen: Integer;
              StartTime: Comp;

            begin
          {$IFDEF CODE_TRACER}
              if Assigned(CodeTracer) then begin
                CodeTracer.SendMessage(dxctDebug, 'TDXSock.SaveTo');
              end;
          {$ENDIF}
              fErrStatus := 0;
              fReadTimeout := False;
              StartTime := TimeCounter + iTimeout;
              while ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK)) and
                (not Timeout(StartTime)) do begin
          {$IFDEF VER100}
                SLen := BlockRead(fChunkBuf, FActualBlockSize);
          {$ELSE}
                SLen := Read(fChunkBuf, FActualBlockSize);
          {$ENDIF}
                if SLen < 1 then begin
                  if SLen = 0 then
                    Break;
                end
                else
                  System.BlockWrite(Handle, fChunkBuf^, SLen);
              end;
              Result := (Sock <> INVALID_SOCKET) and ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK));
            end;

            function TDXSock.WriteWithSize(S: string): Boolean;
            var
              Size, OriginalSize: Integer;
              Ws: string;

            begin
          {$IFDEF CODE_TRACER}
              if Assigned(CodeTracer) then begin
                CodeTracer.SendMessage(dxctDebug, 'TDXSock.WriteWithSize(' + S + ')');
              end;
          {$ENDIF}
              Result := False;
              if S = '' then
                Exit;
              OriginalSize := Length(S);
              SetLength(Ws, OriginalSize + 4);
              Move(S[1], Ws[5], OriginalSize);
              size := htonl(OriginalSize);
              Move(Size, Ws[1], 4);
          {$IFDEF VER100}
              Result := BlockWrite(@Ws[1], OriginalSize + 4) = OriginalSize + 4;
          {$ELSE}
              Result := Write(@Ws[1], OriginalSize + 4) = OriginalSize + 4;
          {$ENDIF}
            end;

            function TDXSock.ReadWithSize: string;
            var
              Done: Boolean;
              Size: Integer;

            begin
              Result := '';
              FErrStatus := 0;
   // redesigned for non-blocking mode and blocking mode and nagle on/off
              Done := False;
              while ((fErrStatus = 0) or (fErrStatus = WSAEWOULDBLOCK)) and not Done do begin
                Result := Result + GetChar; // ReadStr(4-Length(Result));
                Done := Length(Result) = 4;
              end;
              if not Done then
                Exit;
              Move(Result[1], Size, 4);
              size := ntohl(size);
              if (Size > fTooManyCharacters) or (Size < 1) then begin
//      ShowMessageWindow ('',HexDump (Result) +#13+
//         CleanStr (ReadStr (100) ) ) ;
                exit;
              end;
              Result := ReadStr(Size);
            end;

            function TDXSock.SendFromStreamWithSize(Stream: TStream): Boolean;
            var
              Size: Integer;

            begin
          {$IFDEF CODE_TRACER}
              if Assigned(CodeTracer) then begin
                CodeTracer.SendMessage(dxctDebug, 'TDXSock.SendFromStreamWithSize');
              end;
          {$ENDIF}
              Result := False;
              Size := Stream.Size;
              if size < 1 then
                Exit;
              size := htonl(size);
              Stream.Seek(0, 0);
          {$IFDEF VER100}
              if BlockWrite(@Size, 4) = 4 then
                Result := SendFromStream(Stream);
          {$ELSE}
              if Write(@Size, 4) = 4 then
                Result := SendFrom(Stream);
          {$ENDIF}
            end;

            function TDXSock.SaveToStreamWithSize(Stream: TStream; iTimeout: Longword):
                Boolean;
            var
              Size: Integer;
              StartTime: Comp;
              SLen: Integer;

            begin
          {$IFDEF CODE_TRACER}
              if Assigned(CodeTracer) then begin
                CodeTracer.SendMessage(dxctDebug, 'TDXSock.SaveToStreamWithSize');
              end;
          {$ENDIF}
              Stream.Size := 0;
              fReadTimeout := False;
          {$IFDEF VER100}
              if BlockRead(@Size, 4) = 4 then begin
          {$ELSE}
                if Read(@Size, 4) = 4 then begin
          {$ENDIF}
                  size := ntohl(size);
                  StartTime := TimeCounter + iTimeout;
                  fErrStatus := 0;
                  while ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK)) and
                    (not Timeout(StartTime)) and
                    (Size > 0) do begin
          {$IFDEF VER100}
                    SLen := BlockRead(fChunkBuf, Min(Size, FActualBlockSize));
          {$ELSE}
                    SLen := Read(fChunkBuf, Min(Size, FActualBlockSize));
          {$ENDIF}
                    case SLen of
                      -1: begin // non-fatal
                        end;
                      0: Break; // fatal
                    else begin
                        Stream.Write(fChunkBuf^, SLen);
                        Dec(Size, SLen);
                      end;
                    end;
                  end;
                end;
                Result := (Sock <> INVALID_SOCKET) and ((fErrStatus = 0) or (fErrStatus = WSAETIMEDOUT) or (fErrStatus = WSAEWOULDBLOCK)) and
                  ((Size = 0) and (Stream.Size > 0)); // 2.3c
              end;

              function TDXSock.PeekString: string;
              var
                Size: Integer;
            {$IFDEF TLS_EDITION}
                Filtered, InData: Pointer;
                Handled: Boolean;
                NewLen: Integer;
                SizeToRead: Integer;
                S: string;
                StartTime: Longword;
            {$ENDIF}

              begin
                Result := '';
          {$IFDEF TLS_EDITION}
                indata := nil;
          {$ENDIF}
                fReadTimeout := False;
                if Sock = INVALID_SOCKET then
                  exit;
          {$IFDEF TLS_EDITION}
                if Assigned(feOnFilter) then begin
                  SizeToRead := 0;
                  StartTime := DxString.TimeCounter + 1000;
                  while (SizeToRead = 0) and Connected and (not DXString.Timeout(StartTime)) do begin
                    ioctlsocket(Sock, FIONREAD, Longint(SizeToRead));
                    DoSleepEx(1);
                  end;
                  if SizeToRead = 0 then begin
                    Result := '';
                    Exit;
                  end;

//      GetMem (InData,SizeToRead) ;
                  InData := System.GetMemory(SizeToRead);

                  if Sock <> Invalid_Socket then
                    FErrStatus := Recv(Sock, Indata^, SizeToRead, 0)
                  else
                    FErrStatus := Socket_Error;
                end
                else
          {$ENDIF}
                  FErrStatus := BasicPeek(Sock, FPeekBuffer^, PeekBufferSize);
                if FErrStatus = Socket_Error then begin
                  FErrStatus := 0;
                  Exit;
                end
                else
                  Size := FErrStatus;
          {$IFDEF TLS_EDITION}
                if Assigned(feOnFilter) then begin
                  Handled := False;
                  Filtered := nil;
                  feOnFilter(ddAfterRead, InData, Filtered, SizeToRead, NewLen, Handled, FClientThread);
                  if not Handled then begin
                    fErrStatus := 9999; {onFilter failed!}
                    if Assigned(feOnFilter) then begin
                      feOnFilter(ddFreePointer, nil, Filtered, NewLen, NewLen, Handled, FClientThread);
                      if InData <> nil then begin
//               FreeMem (InData,SizeToRead) ;
                        System.FreeMemory(InData);
                        InData := nil;
                      end;
                    end;
                    Exit;
                  end;
                  if Filtered <> nil then begin
                    SetLength(S, NewLen);
                    Move(TDXBSArray(Filtered^), S[1], NewLen);
                    Result := S;
                    fReadTimeout := False;
                    FErrStatus := 0;
                  end
                  else
                    Result := '';
                  if Assigned(feOnFilter) then begin
                    feOnFilter(ddFreePointer, nil, Filtered, NewLen, NewLen, Handled, FClientThread);
                    if InData <> nil then begin
//            FreeMem (InData,SizeToRead) ;
                      System.FreeMemory(InData);
                      InData := nil;
                    end;
                  end;
                end
                else begin
          {$ENDIF}
                  Setlength(Result, Size);
                  if Size > 0 then
                    Move(FPeekBuffer^, Result[1], Size); // 3.0
          {$IFDEF TLS_EDITION}
                  fReadTimeout := False;
                  FErrStatus := 0;
                end;
          {$ENDIF}
              end;

              function TDXSock.PeekChar: Char;
              begin
                Result := #0;
                fReadTimeout := False;
                if Sock = INVALID_SOCKET then
                  exit;
                FErrStatus := BasicPeek(Sock, FPeekBuffer^, 1);
                case fErrStatus of
                  0: begin
//         ShowMessageWindow('','PeekChar '+IntToStr(fErrStatus));
                      CloseNow;
                    end;
                  Socket_Error: FErrStatus := 0;
                else
                  Result := FPeekBuffer^[0];
                end;
              end;

              procedure TDXSock.CloseGracefully;
              begin
          {$IFDEF CODE_TRACER}
                if Assigned(CodeTracer) then begin
                  CodeTracer.SendMessage(dxctDebug, 'TDXSock.CloseGraceFully');
                end;
          {$ENDIF}
                CloseConnection(Sock, True);
              end;

              procedure TDXSock.Disconnect;
              begin
          {$IFDEF CODE_TRACER}
                if Assigned(CodeTracer) then begin
                  CodeTracer.SendMessage(dxctDebug, 'TDXSock.Disconnect');
                end;
          {$ENDIF}
                CloseConnection(Sock, True);
              end;

              procedure TDXSock.CloseNow;
              begin
          {$IFDEF CODE_TRACER}
                if Assigned(CodeTracer) then begin
                  CodeTracer.SendMessage(dxctDebug, 'TDXSock.CloseNow');
                end;
          {$ENDIF}
                CloseConnection(Sock, False);
              end;

              function TDXSock.IsValidSocket: Boolean;
              begin
                Result := Sock <> INVALID_SOCKET;
              end;

              function TDXSock.IsConnected: Boolean;
              begin
                Result := (Sock <> INVALID_SOCKET)
                  and ((FErrStatus = 0) or (FErrStatus = WSAETIMEDOUT) or
                  (FErrStatus = WSAEWOULDBLOCK) or (fErrStatus = 10038));
                if not Result and (CountmyWaiting > 0) then
                  Result := True;
{   If (fErrStatus<>0) and
      (fErrStatus<>WSAEWOULDBLOCK) and
      (fErrStatus<>WSAETIMEDOUT) and
      (fErrStatus<>10038) then ShowMessageWindow('IsConnected',IntToStr(fErrStatus));
   If not Result then Begin
      If Sock=INVALID_SOCKET then ShowMessageWindow('IsConnected','Invalid_Socket');
   End;}
              end;

              function TDXSock.IsReadable: Boolean;
              begin
                fReadTimeout := False;
                Result := False;
                if Sock = INVALID_SOCKET then
                  exit;
                Result := BasicSelect(Sock, True, GlobalTimeout) > 0;
//   SetTimeoutAndBuffer(Sock);
                fErrStatus := 0;
              end;

              function TDXSock.IsWritable: Boolean;
              begin
                fReadTimeout := False;
                Result := False;
                if Sock = INVALID_SOCKET then
                  exit;
                Result := BasicSelect(Sock, False, GlobalTimeout) > 0;
//   SetTimeoutAndBuffer(Sock);
                fErrStatus := 0;
              end;

              function TDXSock.DidReadTimeout: Boolean;
              begin
                Result := fReadTimeout;
              end;

              function TDXSock.GetMyLocalPort: Integer;
              begin
                Result := 0;
                if Sock = INVALID_SOCKET then
                  exit;
                Result := GetLocalPort(Sock);
              end;

              function TDXSock.GetMyLocalIPAddr: string;
              begin
                Result := '';
                if Sock = INVALID_SOCKET then
                  exit;
                Result := GetLocalIPAddr(Sock);
              end;

              function TDXSock.GetErrorStr: string;
              begin
                result := GetErrorDesc(GetLastError);
              end;

              procedure TDXSock.WinsockVersion(var WinsockInfo: PWinsockInfo);
              begin
                if not Assigned(WinsockInfo) then
                  Exit;
                if not SocketLayerLoaded then
                  Exit;
                GetSocketVersion(WinsockInfo);
              end;

              procedure TDXSock.SetbNagle(TurnOn: Boolean);
              begin
                SetNagle(Sock, TurnOn, FErrStatus);
              end;

              procedure TDXSock.SetbBlocking(TurnOn: Boolean);
              begin
                fUseBlocking := TurnOn;
                SetBlocking(Sock, TurnOn, FErrStatus);
              end;

              function TDXSock.GetmyErrorDesc(errorCode: Integer): string;
              begin
                Result := GetErrorDesc(ErrorCode);
              end;

              procedure TDXSock.SetfBlockSizeFlags(Value: TDXBlockSizeFlags);
              begin
          {$IFDEF CODE_TRACER}
                if Assigned(CodeTracer) then begin
                  CodeTracer.SendMessage(dxctDebug, 'TDXSock.SetfBlockSizeFlags');
                end;
          {$ENDIF}
                if Assigned(fChunkBuf) then
//      FreeMem (fChunkBuf,FActualBlockSize);
                  System.FreeMemory(fChunkBuf);
                fChunkBuf := nil;
                fBlockSizeFlags := Value;
                case FBlockSizeFlags of
                  bsfZero: fActualBlockSize := 0;
                  bsfRealSmall: fActualBlockSize := 128;
                  bsfSmall: fActualBlockSize := 256;
                  bsfNormal: fActualBlockSize := 512;
                  bsfBigger: fActualBlockSize := 2048;
                  bsfBiggest: fActualBlockSize := 4096;
                  bsfHUGE: fActualBlockSize := 32768;
                else
                  fActualBlockSize := TDXHugeSize;
                end;
                if FBlockSizeFlags <> bsfZero then
//      GetMem (fChunkBuf,FActualBlockSize) ;
                  fChunkBuf := System.GetMemory(FActualBlockSize);
              end;

              function TDXSOCK.CountmyWaiting: Integer;
              begin
                Result := CountWaiting(Sock, FErrStatus);
                if FErrStatus <> 0 then begin
//------------------------------------------------------------------------------
// 抛出异常 2008-2-14 马敏钊
//------------------------------------------------------------------------------
//    raise Exception.Create('检查 等待数据时发现socket 已断开，抛出异常');

                  Result := 0;
                  Exit;
                end;
              end;

              function TDXSOCK.FilterRead(const InBuf: Pointer; var OutBuf: Pointer; InSize: Integer; xClientThread: TThread): Integer;
              var
                Handled: Boolean;

              begin
                if InSize > 0 then
                  if Assigned(feOnFilter) then begin
                    Handled := False;
                    Result := 0;
                    feOnFilter(ddAfterRead, InBuf, OutBuf, InSize, Result, Handled, xClientThread);
                    if not Handled then begin
                      fErrStatus := 9999; {onFilter failed!}
                      Exit;
                    end;
                  end;
              end;

// used by TDXSockClient only!

              procedure TDXSock.SockClientSetGlobal(I: string; P: Integer);
              begin
                GlobalPeerPort := P;
                GlobalPeerIPAddress := I;
              end;

// new 3.0 features:

              function TDXSock.DroppedConnection: Boolean;
              begin
                Result := False;
                if IsReadable then
                  if CharactersToRead = 0 then begin
                    CloseNow; // invalidates the handle
                    Result := True;
                  end;
              end;

              function TDXSock.WaitForData(itimeout: Longint): Boolean;
              var
                StartTime: Comp;

              begin
          {$IFDEF CODE_TRACER}
                if Assigned(CodeTracer) then begin
                  CodeTracer.SendMessage(dxctDebug, 'TDXSock.WaitForData');
                end;
          {$ENDIF}
                Result := False;
                StartTime := TimeCounter + Cardinal(itimeout);
                while not TimeOut(StartTime) do begin
                  if DroppedConnection then begin
                    CloseNow;
                    Exit;
                  end
                  else begin
                    if CharactersToRead > 0 then begin
                      Result := True;
                      Exit;
                    end
                    else begin
                      ProcessWindowsMessageQueue;
                      DoSleepEx(0);
                    end;
                  end;
                end;
              end;

              procedure TDXSock.RestartCharactersPerSecondTimer;
              begin
                fCPSStart := Now;
                fTotalWBytes := 0;
                fTotalRBytes := 0;
              end;

              function TDXSock.CharactersPerSecondWritten: Integer;
              var
                H1, M1, S1, MS1: Word;

              begin
                try
                  DecodeTime(Now - fCPSStart, H1, M1, S1, MS1);
                  Result := fTotalWBytes div Max(((MS1 + (S1 * 1000) + (M1 * 3600000) + (H1 * 216000000)) div 1000), 1);
                except
                  Result := 0;
                end;
              end;

              function TDXSock.CharactersPerSecondReceived: Integer;
              var
                H1, M1, S1, MS1: Word;

              begin
                try
                  DecodeTime(Now - fCPSStart, H1, M1, S1, MS1);
                  Result := fTotalRBytes div Max(((MS1 + (S1 * 1000) + (M1 * 3600000) + (H1 * 216000000)) div 1000), 1);
                except
                  Result := 0;
                end;
              end;


            initialization
          {$IFDEF LINUX}
            StartupResult := 0;
          {$ELSE}
            StartupResult := WSAStartup(MAKEBytesToWORD(2, 2), DLLData);
          {$ENDIF}
            if StartupResult = 0 then begin
              StartupResult := 999;
      // 6-9: added to load 1 time.
              GlobalTimeout.tv_Sec := 0;
              GlobalTimeout.tv_uSec := 500; //2500;
            end
            else StartupResult := 123;


          finalization
          {$IFNDEF LINUX}
            if StartupResult = 999 then WSACleanup;
          {$ENDIF}


          end.

