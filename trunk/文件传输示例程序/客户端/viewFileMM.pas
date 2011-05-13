unit viewFileMM;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls;

type
  RfileTrans = record //文件传输结构体
    Fileid: Integer;
    Dir: Byte; //方向    1 上传 2 下载
    RangeStart: Int64;
    len: Int64;
    UseData: Integer; //用户数据
  end;
  TFileMisson = class
  public
    Transrd: RfileTrans;
    State: Integer;
    FileName: string;
    FileSize: Int64;
    Info: TListItem;
    FileStream: TFileStream;
  end;

  Tview_FileMM = class(TForm)
    lv_FileLst: TListView;
    Panel1: TPanel;
    btn1: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure btn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    FFileIDlst: TStrings;
    FMissonlst: TStrings;
    //刷新文件列表
    procedure RfFileInfo(ISvrLst: TStrings);

    //上传文件
    procedure UpFile(IFile: string);

    //下载文件
    procedure DwFile(Iinfo: TListitem);

  end;

var
  view_FileMM: Tview_FileMM;

implementation

uses
  untfunctions, untRmoDbClient;

{$R *.dfm}

{ Tview_FileMM }

procedure Tview_FileMM.RfFileInfo(ISvrLst: TStrings);
var
  i: Integer;
  litem: TListItem;
  lbuff: TFileMisson;
begin
  lv_FileLst.Clear;
  for i := 0 to ISvrLst.Count - 2 do begin
    litem := lv_FileLst.Items.Add;
    litem.Caption := Copy(ISvrLst[i], 1, Pos('?', ISvrLst[i]) - 1);
    litem.SubItems.Add(IfThen(FileExists(GetCurrPath() + 'download\' + litem.Caption), '本地', '服务器'));
    if FMissonlst.IndexOf(litem.Caption) > -1 then begin
      lbuff := TFileMisson(FMissonlst.Objects[i]);
      if lbuff.FileSize = lbuff.Transrd.RangeStart then begin
        litem.SubItems.Add('下载完成');
        litem.SubItems.Add('');
      end
      else begin
        litem.SubItems.Add('下载中');
        litem.SubItems.Add(IntToStr(lbuff.Transrd.RangeStart));
      end;
    end
    else begin
      litem.SubItems.Add(IfThen(litem.SubItems[0] = '本地', '已下载', '未下载'));
      litem.SubItems.Add('');
    end;
    litem.SubItems.Add(Copy(ISvrLst[i], Pos('?', ISvrLst[i]) + 1, 10));
  end;
  Button3.Enabled := True;
end;

procedure Tview_FileMM.FormCreate(Sender: TObject);
begin
  FFileIDlst := TStringList.Create;
  FMissonlst := TStringList.Create;
end;

procedure Tview_FileMM.FormDestroy(Sender: TObject);
begin
//  ClearList(FMissonlst);
  ClearList(FFileIDlst);
end;

procedure Tview_FileMM.DwFile(Iinfo: TListitem);
var
  Lbuff: TFileMisson;
begin
  if Iinfo.SubItems[0] = '本地' then
    ExceptTip('该文件已经存在于本地目录！');
  Lbuff := TFileMisson.Create;
  Lbuff.FileName := Iinfo.Caption;
  Lbuff.FileSize := StrToInt64(Iinfo.SubItems[3]);
  Lbuff.Info := Iinfo;
  Lbuff.Transrd.Dir := 2;
  Lbuff.Transrd.UseData := integer(Lbuff);
  Lbuff.FileStream := TFileStream.Create(GetCurrPath() + '\download\' + Lbuff.FileName, fmCreate or fmOpenWrite);
  FFileIDlst.AddObject(Lbuff.FileName, Lbuff);
  Gob_RmoCtler.GetFileID(Lbuff.FileName);
end;

procedure Tview_FileMM.UpFile(IFile: string);
begin

end;

procedure Tview_FileMM.Button1Click(Sender: TObject);
begin
  if lv_FileLst.Selected <> nil then begin
    DwFile(lv_FileLst.Selected);
  end;
end;

procedure Tview_FileMM.Button3Click(Sender: TObject);
begin
  Gob_RmoCtler.GetsvrFilelist;
  Button3.Enabled := False;
end;

procedure Tview_FileMM.Button2Click(Sender: TObject);
var
  lls: string;
begin
  if lv_FileLst.Selected <> nil then begin
    lls := GetCurrPath + 'download\' + lv_FileLst.Selected.Caption;
    if FileExists(lls) then
      if QueryInfo('确认要删除本地的文件<%s>?', [lv_FileLst.Selected.Caption]) then begin
        DeleteFile(lls);
        lv_FileLst.Selected.SubItems[0] := '服务器';
        lv_FileLst.Selected.SubItems[1] := '未下载';
      end;
  end;
end;

procedure Tview_FileMM.btn1Click(Sender: TObject);
begin
  TipInfo('暂未实现！');
end;

end.

