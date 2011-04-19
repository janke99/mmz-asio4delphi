program demoClient;

uses
  Forms,
  untMain in 'untMain.pas' {frm_main},
  UntRemSql in '..\GobUnit\UntRemSql.pas',
  ViewGraph in 'ViewGraph.pas' {View_Graph};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tfrm_main, frm_main);
  Application.CreateForm(TView_Graph, View_Graph);
  Application.Run;
end.
