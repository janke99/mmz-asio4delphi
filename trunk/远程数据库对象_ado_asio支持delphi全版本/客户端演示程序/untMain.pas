unit untMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UntRemSql, ComCtrls, ExtCtrls, StdCtrls, Grids, DBGrids, DB, adodb;

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
    procedure FormCreate(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
    { Private declarations }
  public
    QryShower, Qryopt: TADOQuery;
  end;

var
  frm_main: Tfrm_main;
implementation

uses untfunctions;

{$R *.dfm}

procedure Tfrm_main.FormCreate(Sender: TObject);
begin
  //因为ADO对象 不能再没有连接数据库的情况下使用，所以建立一个空的access数据库连接
  Gob_DBMrg := TDBMrg.Create(TDBMrg.GetAccessConnStr(GetCurrPath + 'temp.mdb'));

  //创建客户端对象  连接服务端9000端口
  Gob_Rmo := TRmoHelper.Create(9000);
  //允许post时 同时填充id字段
  Gob_Rmo.FRmoClient.IsInserIDfield := True;
  //连接服务端 为了简单演示填为本机  如果需要连接远程机器改为其他机器的IP 即可
  if Gob_Rmo.ReConnSvr('127.0.0.1') = false then begin
    ErrorInfo('连接数据库服务程序失败，请先启动服务程序!');
    Application.Terminate;
  end;

  //获取一个ADOQUERY
  Qryopt := Gob_DBMrg.GetAnQuery('Qryopt');
  //获取另外一个adoquery 作为和dbgrid连接
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
  TipInfo('新增记录成功');


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


end.

