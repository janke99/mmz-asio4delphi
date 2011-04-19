unit untMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UntRemSql, ComCtrls, ExtCtrls, StdCtrls, Grids, DBGrids, DB, dbclient,midaslib;

type
  Tfrm_main = class(TForm)
    pnl_head: TPanel;
    pgc_ctl: TPageControl;
    ts_one: TTabSheet;
    ds1: TDataSource;
    DBGrid1: TDBGrid;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    lbl_hint: TLabel;
    Button6: TButton;
    ts_two: TTabSheet;
    pnlower: TPanel;
    ListBox1: TListBox;
    btn1: TButton;
    btn2: TButton;
    ts_sub: TTabSheet;
    ds_master: TDataSource;
    ds_slave: TDataSource;
    DBGrid2: TDBGrid;
    DBGrid3: TDBGrid;
    Label1: TLabel;
    Button7: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure pgc_ctlChange(Sender: TObject);
    procedure Button7Click(Sender: TObject);
  private
    { Private declarations }
  public
    QryShower, Qryopt, QryMaster, QrySlave: TClientDataSet;
  end;

var
  frm_main: Tfrm_main;
implementation

uses untfunctions, ViewGraph, PMyBaseDebug;

{$R *.dfm}

procedure Tfrm_main.FormCreate(Sender: TObject);
begin

  Gob_DBMrg := TDBMrg.Create();
  //创建客户端对象  连接服务端9000端口
  Gob_Rmo := TRmoHelper.Create(9000);
  //连接服务端 为了简单演示填为本机  如果需要连接远程机器改为其他机器的IP 即可
  //登陆时需要填上用户名和密码 服务端配置文件sys.ini中做设置。
  if Gob_Rmo.ReConnSvr('127.0.0.1', -1, 'client', '456') = false then begin
    ErrorInfo('连接数据库服务程序失败，请先启动服务程序!');
    Application.Terminate;
  end;
  //获取一个
  Qryopt := Gob_DBMrg.GetAnQuery('Qryopt');
  //获取另外一个数据集 作为和dbgrid连接
  QryShower := Gob_DBMrg.GetAnQuery('qry_show');

  ds1.DataSet := QryShower;

  Button5.Click;
end;

procedure Tfrm_main.Button5Click(Sender: TObject);
begin
  //查询远程数据库的表 并显示到dbgrid里边
  Gob_Rmo.OpenTable('treeinfo', QryShower);
end;

procedure Tfrm_main.Button2Click(Sender: TObject);
var
  lid: Integer;
begin
  //如果数据集是空的 就查询一下
  if QryShower.IsEmpty then
    Button5.Click;

  //获取下一条记录的ID
  QryShower.Append;
  QryShower.FieldByName('Caption').AsString := '新增记录' + QryShower.FieldByName('id').AsString;
  QryShower.FieldByName('parentid').AsInteger := -1;
  QryShower.FieldByName('Flevel').AsInteger := 10;
  QryShower.FieldByName('kind').AsInteger := 1;
  QryShower.Post;
  TipInfo('新增记录成功新纪录ID号<%d>', [QryShower.FieldByName('id').AsInteger]);
end;

procedure Tfrm_main.Button4Click(Sender: TObject);
begin
  QryShower.Delete;
  TipInfo('删除记录成功');
end;

procedure Tfrm_main.Button1Click(Sender: TObject);
begin
  //执行一条语句
  Gob_Rmo.ExecAnSql('delete from treeinfo where id=%d', [QryShower.FieldByName('id').AsInteger]);
end;

procedure Tfrm_main.Button3Click(Sender: TObject);
begin
  //执行一条语句
  Gob_Rmo.OpenDataset(QryShower, 'select  * from treeinfo where id> 0', []);
  TipInfo('共查询出%d条记录', [QryShower.RecordCount]);
end;

procedure Tfrm_main.Button6Click(Sender: TObject);
begin
  //如果语句错误 可以获得和本地数据库一致的错误提示，以便发现问题
  Gob_Rmo.OpenDataset(QryShower, 'select * from treeinfo where Fid> 0', []);
end;


procedure Tfrm_main.FormShow(Sender: TObject);
var
  Litem: TInfoMap;
begin
  Litem := TInfoMap.Create;
  Litem.id := '1';
  Litem.Cpt := '拖放节点1';
  ListBox1.Clear;
  ListBox1.Items.AddObject(Litem.Cpt, Litem);


  Litem := TInfoMap.Create;
  Litem.id := '2';
  Litem.Cpt := '拖放节点2';
  ListBox1.Items.AddObject(Litem.Cpt, Litem);




  View_Graph := TView_Graph.Create(Application);
  View_Graph.Parent := pnlower;
  View_Graph.Show;
  ListBox1.OnClick := View_Graph.OnModelTreeClick;

end;

procedure Tfrm_main.btn1Click(Sender: TObject);
var
  i: Integer;
  lst: TStringList;

begin
  //方法一
  Gob_Rmo.AddBathExecSql('insert into treeinfo(caption) values(''%s'')', ['批量测试1']);
  Gob_Rmo.AddBathExecSql('insert into treeinfo(caption) values(''%s'')', ['批量测试2']);
  Gob_Rmo.AddBathExecSql('insert into treeinfo(caption) values(''批量测试3'')');
  Gob_Rmo.BathExec; //这一句才真正提交到服务器执行

  //方法2
  lst := TStringList.Create;
  lst.Add(format('insert into treeinfo(caption) values(''%s'')', ['批量测试1']));
  lst.Add(format('insert into treeinfo(caption) values(''%s'')', ['批量测试2']));
  lst.Add('insert into treeinfo(caption) values(''批量测试3'')');
  Gob_Rmo.BathExecSqls(lst); //这一句才真正提交到服务器执行
  lst.Free;


end;

procedure Tfrm_main.btn2Click(Sender: TObject);
var
  i: Integer;
  lst: TStringList;
begin
 //执行自动生成语句插入1000条记录
//  Gob_Debug.StartLogTime;
//  for i := 0 to 1000 - 1 do begin // Iterate
//    QryShower.Insert;
//    QryShower.FieldByName('caption').AsString := format('批量测试%d', [i + 1]);
//    QryShower.Post;
//  end; // for
//  Gob_Debug.ShowVar(Format('Post方式，批量插入1000条记录，使用了%d秒', [Gob_Debug.EndLogTIme div 1000]));

  //执行插入1000条记录
  Gob_Debug.StartLogTime;
  for i := 0 to 1000 - 1 do begin // Iterate
    Gob_Rmo.AddBathExecSql('insert into treeinfo(caption) values(''大批量测试%d'')', [i + 1]);
  end; // for
  Gob_Rmo.BathExec; //这一句才真正提交到服务器执行
  Gob_Debug.ShowVar(Format('批量插入1000条记录，使用了%d秒', [Gob_Debug.EndLogTIme div 1000]));
end;

procedure Tfrm_main.pgc_ctlChange(Sender: TObject);
begin
  if pgc_ctl.ActivePageIndex = 2 then begin
    if QryMaster = nil then begin
      QryMaster := Gob_DBMrg.GetAnQuery('QryMaster');
      ds_master.DataSet := QryMaster;
      QrySlave := Gob_DBMrg.GetAnQuery('QrySlave');
      ds_slave.DataSet := QrySlave;
      QrySlave.MasterSource := ds_master;
      QrySlave.MasterFields := 'id';
      QrySlave.IndexFieldNames := 'fpid'
    end;
    Gob_Rmo.OpenTable('Tmaster', QryMaster);
    Gob_Rmo.OpenDataset(QrySlave, 'select * from Tslave');
  end;
end;

procedure Tfrm_main.Button7Click(Sender: TObject);
begin
  Gob_Rmo.FRmoClient.CheckUpdate;
end;

end.

