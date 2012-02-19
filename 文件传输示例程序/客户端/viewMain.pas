unit viewMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  Tview_Main = class(TForm)
    Panel1: TPanel;
    Edit1: TEdit;
    btn1: TButton;
    Edit2: TEdit;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    mmo_show: TMemo;
    Panel6: TPanel;
    mmo_write: TMemo;
    ListBox1: TListBox;
    Button2: TButton;
    Button3: TButton;
    tmr_rcv: TTimer;
    tmr_getlst: TTimer;
    procedure btn1Click(Sender: TObject);
    procedure tmr_rcvTimer(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure tmr_getlstTimer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    procedure Onmove(var msg: TMessage); message wm_move;
  public
    { Public declarations }
    procedure AddShow(IConn: string);



  end;

var
  view_Main: Tview_Main;

implementation

uses
  untRmoDbClient, untfunctions, untASIOSvr, viewFileMM;

{$R *.dfm}

procedure Tview_Main.AddShow(IConn: string);
begin
  IConn := StringReplace(IConn, '|', ':', [rfReplaceAll]);
  mmo_show.Lines.Add(FormatDateTime('hh:nn:ss', now) + ':' + iconn);
end;

procedure Tview_Main.btn1Click(Sender: TObject);
begin
  if Gob_RmoCtler = nil then begin
    Gob_RmoCtler := TfileClient.Create;
  end;
  if Gob_RmoCtler.ConnToSvr(Edit1.Text, 9951, Edit2.Text, Str_Encry('12345', 'cht')) = false then begin
    ShowMessage('登录服务器失败！');
    exit;
//    KillTask(ExtractFileName(ParamStr(0)));
  end
  else begin
    AddShow('连接服务器成功，请求返回在线用户列表,以及服务端文件列表');
    tmr_getlst.Enabled := true;
    btn1.Enabled := false;
    Edit2.Enabled := False;
    tmr_rcv.Enabled := True;
  end;
end;

var
  Gbuff: array[0..512000] of Byte;

procedure Tview_Main.tmr_rcvTimer(Sender: TObject);
var
  Lid, Lhead, llen: Integer;
  lls: string;
  Lspit: TStrings;
  lfileinfo: TFileMisson;
  lrdbuff: RfileTrans;
begin
  if (Gob_RmoCtler <> nil) and (Gob_RmoCtler.IsConning) then begin
    if Gob_RmoCtler.Socket.GetCanUseSize > 4 then begin
      Lhead := Gob_RmoCtler.Readinteger();
      if Lhead = 1 then begin
        llen := Gob_RmoCtler.Readinteger();
        lls := Gob_RmoCtler.ReadStr(llen);
        ListBox1.Items.CommaText := lls;
        llen := ListBox1.Items.IndexOf(Edit2.Text);
        Caption := Format('聊天演示客户端-在线%d', [ListBox1.Items.count]);

        if ListBox1.Items.Count > -1 then begin
          ListBox1.ItemIndex := 0;
        end;
      end
      else if Lhead = 2 then begin //聊天信息  谁发的|发给谁|什么内容|
        llen := Gob_RmoCtler.Readinteger();
        lls := Gob_RmoCtler.ReadStr(llen);
        Lspit := TStringList.Create;
        try
          if lls <> '' then begin
            ExtractStrings(['|'], [' '], PansiChar(lls), lspit);
            if Lspit[0] <> Edit2.Text then
              AddShow(Format('%s对你说%s', [Lspit[0], Lspit[2]]));
          end;
        finally
          Lspit.Free;
        end;
      end
      else if Lhead = 3 then begin //文件列表
        llen := Gob_RmoCtler.Readinteger();
        lls := Gob_RmoCtler.ReadStr(llen);
        Lspit := TStringList.Create;
        Lspit.Delimiter := '|';
        Lspit.DelimitedText := lls;
        view_FileMM.RfFileInfo(Lspit);
        Lspit.Free;

      end
      else if Lhead = 4 then begin //用户上下线
        llen := Gob_RmoCtler.Readinteger();
        if llen = 1 then
          AddShow('有新用户上线')
        else
          AddShow('有用户离线');
        tmr_getlst.Enabled := True;
      end
      else if Lhead = 5 then begin //确定文件ID
        Lid := Gob_RmoCtler.Readinteger();
        llen := Gob_RmoCtler.Readinteger();
        lls := Gob_RmoCtler.ReadStr(llen);
        Lhead := view_FileMM.FFileIDlst.IndexOf(lls);
        if Lhead > -1 then begin
          lfileinfo := TFileMisson(view_FileMM.FFileIDlst.Objects[lhead]);
          lfileinfo.Transrd.Fileid := Lid;
          lfileinfo.Transrd.RangeStart := 0;
          view_FileMM.FMissonlst.AddObject(lfileinfo.FileName, lfileinfo);
          Gob_RmoCtler.TransFile(lfileinfo);
        end;
      end
      else if Lhead = 6 then begin //文件传输
        Gob_RmoCtler.ReadBuffer(@lrdbuff, sizeof(lrdbuff));
        if lrdbuff.Dir = 1 then begin //上传

        end
        else begin //下载
          lfileinfo := TFileMisson(lrdbuff.UseData);
          //写入文件
          Gob_RmoCtler.ReadBuffer(@gbuff, lfileinfo.Transrd.len);
          lfileinfo.FileStream.WriteBuffer(gbuff, lfileinfo.Transrd.len);
          Inc(lfileinfo.Transrd.RangeStart, lrdbuff.len);
          if lrdbuff.RangeStart < lfileinfo.FileSize then begin
            Gob_RmoCtler.TransFile(lfileinfo);
            lfileinfo.Info.SubItems[2] := IntToStr(lfileinfo.Transrd.RangeStart * 100 div lfileinfo.FileSize) + '%'; //显示进度
            lfileinfo.Info.SubItems[1] := '下载中';
          end
          else begin
            lfileinfo.Info.SubItems[2] := '100%'; //显示进度
            lfileinfo.Info.SubItems[0] := '本地';
            lfileinfo.Info.SubItems[1] := '已完成';
            lfileinfo.FileStream.Free;
            lfileinfo.FileStream := nil;
            llen := view_FileMM.FMissonlst.IndexOf(lfileinfo.FileName);
            if llen > -1 then
              view_FileMM.FMissonlst.Delete(llen);
          end;
        end;
      end
      else begin
        DeBug('异常数据，客户端解析数据包是发现不认识的数据头');
      end;
    end;
  end;
end;


var
  Lcrd: Cardinal;

procedure Tview_Main.Button2Click(Sender: TObject);
begin
  if GetTickCount - Lcrd > 100 then begin

  end
  else begin
  // AddShow('不要发言太快啦');
//    exit;
  end;
  Lcrd := GetTickCount;
  if ListBox1.ItemIndex = -1 then begin
    Gob_RmoCtler.SaySome('', mmo_write.Text);
    AddShow(Format('你对大家说:%s', [ mmo_write.Text]));
  end
  else begin
    Gob_RmoCtler.SaySome(ListBox1.Items[ListBox1.itemindex], mmo_write.Text);
    AddShow(Format('你对%s说:%s', [ListBox1.Items[ListBox1.itemindex], mmo_write.Text]));
  end;
end;

procedure Tview_Main.tmr_getlstTimer(Sender: TObject);
begin
  tmr_getlst.Enabled := false;
  Gob_RmoCtler.Getonlineuser;
  Gob_RmoCtler.GetsvrFilelist;
end;

procedure Tview_Main.Button3Click(Sender: TObject);
begin
  if view_FileMM.Showing then
    view_FileMM.Hide
  else
    view_FileMM.Show;
  if view_FileMM.Showing then begin
    Left := Screen.Width div 2 - Width;
  end;
end;

procedure Tview_Main.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  tmr_rcv.Enabled := False;
  tmr_getlst.Enabled := False;
  Sleep(100);
  Gob_RmoCtler.Free;
end;

procedure Tview_Main.Onmove(var msg: TMessage);
begin
  if view_FileMM <> nil then
    if view_FileMM.Showing then begin
      view_FileMM.Show;
      view_FileMM.Top := Top;
      view_FileMM.Left := Left + Width + 1;
    end;
end;

procedure Tview_Main.FormShow(Sender: TObject);
begin
  Button3.Click;
end;

procedure Tview_Main.FormCreate(Sender: TObject);
begin
  ForceDirectories(GetCurrPath() + 'download\');
end;

end.

