unit viewMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, UntRmodbSvr;

type
  Tview_Main = class(TForm)
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  view_Main: Tview_Main;

implementation

uses
  UntTIO, untfunctions;

{$R *.dfm}
var
  Gio: TIOer;

procedure Tview_Main.FormCreate(Sender: TObject);
begin
  Gio := TIOer.Create(Memo1);
  ForceDirectories(GetCurrPath + 'upload\');
  Gob_Filesvr := TFileSvr.Create(9951, Gio);
  Gio.AddShow('聊天服务端演示程序...');
end;

procedure Tview_Main.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  Gob_Filesvr.Free;
  Gio.Free;
end;

end.

