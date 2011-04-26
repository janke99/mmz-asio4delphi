unit untMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UntRmodbSvr, ImgList, ComCtrls;

type
  Tfrm_main = class(TForm)
    lvLog: TListView;
    ImageListLogLevel: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frm_main: Tfrm_main;

implementation
uses
  UntTIO, untFunctions;

{$R *.dfm}

var
  Gio: TIOer; //日志对象 可显示和记录日志信息

procedure Tfrm_main.FormCreate(Sender: TObject);
begin
  //创建日志对象
  Gio := TIOer.Create(lvLog, GetCurrPath + 'log\');
  //创建数据服务器对象 使用9000端口
  Gob_RmoDBsvr := TRmodbSvr.Create(9000, Gio);

   //此处连接exe目录下的access数据库文件 demo.mdb
   //当然可以连接任意一种数据库
  if Gob_RmoDBsvr.ConnToDb(TDBMrg.GetAccessConnStr(GetCurrPath() + 'demo.mdb')) then
    Gio.AddShow('连接本地数据库成功，可以提供远程数据服务了!');


// TDBMrg具有很方便的类方法 可以提供生成不同数据库的连接字符串哦
//    {获取ACCESS连接字符串}
//    class function GetAccessConnStr(IDataSource: string; Ipsd: string = ''): string;
//    {获取MSSQL连接字符串}
//    class function GetMsSQLConnStr(IDataSource, IAcc, Ipsd, IDataBase: string): string;
//    {获取Oracle连接字符串}
//    class function GetOracleConnStr(IDataSource, IAcc, Ipsd: string): string;
//    {获取Excel连接字符串}
//    class function GetExcelConnStr(IFileName: string): string;
//    {获取Text连接字符串}
//    class function GetTextConnStr(IDBPath: string): string;
//    {获取Dbf连接字符串}
//    class function GetDBFConnStr(IDBPath: string): string;
//    {获取MySQl连接字符串}
//    class function GetMySqlConnStr(IDataSource, IDbName, IAcc, Ipsd: string): string;
end;

procedure Tfrm_main.FormDestroy(Sender: TObject);
begin
//记得养成有借有还的好习惯
  Gob_RmoDBsvr.Free;
  Gio.Free;
end;

end.

