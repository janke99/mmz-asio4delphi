unit modelASIOtest;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, modelCommClient, ExtCtrls;

type
  TASIO_test = class(TForm)
    lbl_hint: TLabel;
    ListBox1: TListBox;
    Panel1: TPanel;
    lbl1: TLabel;
    edt1: TEdit;
    Button1: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    Memo1: TMemo;
    CheckBox1: TCheckBox;
    lbl_conn: TLabel;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    lst: TStrings;
    client: TCommClient;
    procedure Onrcv(var msg: TMessage); message 1026;
    procedure Onsend(var msg: TMessage); message 1027;
  end;


  Tthreadsend = class(tthread)
  public
    procedure Execute; override;
  end;

var
  ASIO_test: TASIO_test;
  worker: Tthreadsend;
  GtConn: Integer;
implementation

uses
  untfunctions;

{$R *.dfm}

procedure TASIO_test.FormCreate(Sender: TObject);
begin
  lst := TStringList.Create;
  ListBox1.DoubleBuffered := True;
end;

procedure TASIO_test.Button1Click(Sender: TObject);
var
  i, n: Integer;
begin
  Button1.Enabled := False;
  n := StrToInt(Edit1.Text);
//  ListBox1.Items.BeginUpdate;
  try
    for i := 1 to n do begin
      client := TCommClient.Create;
      client.SetConnParam(edt1.Text, 9951);
      client.index := i;
     // client.Connto(edt1.Text, 9951);
      lst.AddObject(IntToStr(i), client);
    //  lbl_conn.Caption := Format('正在连接第:%d个', [i]);
    end;
  finally
//    ListBox1.Items.EndUpdate;
  end;
  worker := Tthreadsend.Create(false);
  Timer1.Enabled := True;
end;

procedure TASIO_test.Onrcv(var msg: TMessage);
begin
 // ListBox1.Items[msg.LParam - 1] := (Format('第%d个连接,当前数据返回:%d 毫秒', [msg.LParam, GetTickCount - TCommClient(msg.WParam).beginSend]));
  if CheckBox1.Checked then
    if Memo1.Lines.Add((Format('第%d个连接,当前数据返回:%d 毫秒,原始结果 %d 运算结果:%d ,%s',
      [TCommClient(msg.WParam).index,
      GetTickCount - TCommClient(msg.WParam).beginSend, TCommClient(msg.WParam).lsum, msg.LParam,
        ifthen(msg.LParam = TCommClient(msg.WParam).lsum, '正确', '错误')
        ]))) > 10000 then
      Memo1.Lines.Clear;
end;

procedure TASIO_test.Button2Click(Sender: TObject);
begin
  client.WriteInteger(11);
end;

procedure TASIO_test.Button4Click(Sender: TObject);
var
  lc: array[0..100] of byte;
begin
  client.WriteBuff(Pointer(@lc[0])^, 1);
end;

{ Tthreadsend }


procedure Tthreadsend.Execute;
var
  i, n: integer;
begin
  while not Terminated do begin
    Randomize;
    n := 0;
    for i := 0 to ASIO_test.lst.Count - 1 do begin
      if Terminated then Break;
      if TCommClient(ASIO_test.lst.Objects[i]).IsConning = false then begin
        if TCommClient(ASIO_test.lst.Objects[i]).Connto(TCommClient(ASIO_test.lst.Objects[i]).FHost, TCommClient(ASIO_test.lst.Objects[i]).FPort) then begin
          Inc(n);
          if n > 100 then Break;
        end;
      end
      else begin
        TCommClient(ASIO_test.lst.Objects[i]).DoCase;
        if TCommClient(ASIO_test.lst.Objects[i]).isRcv then begin
          if GetTickCount - TCommClient(ASIO_test.lst.Objects[i]).grcvTime > 3000 + Random(2000) then
            TCommClient(ASIO_test.lst.Objects[i]).OnConnSuccess;
        end;
      end;
      if i mod 100 = 0 then
        Sleep(10);
    end;
    GtConn := 0;
    for i := 0 to ASIO_test.lst.Count - 1 do begin
      if TCommClient(ASIO_test.lst.Objects[i]).IsConning then
        Inc(GtConn);
    end;
    Sleep(10);
  end;
end;

procedure TASIO_test.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if worker <> nil then begin
    worker.Terminate;
    Sleep(100);
  end;
  KillTask(ParamStr(0));
end;

procedure TASIO_test.Timer1Timer(Sender: TObject);
begin
  lbl_conn.Caption := Format('当前连接共:%d个', [GtConn]);
end;

procedure TASIO_test.Onsend(var msg: TMessage);
begin
  if CheckBox1.Checked then
    Memo1.Lines.Add(Format('----------------------------->发送 (%d)', [msg.LParam]));
end;



end.

