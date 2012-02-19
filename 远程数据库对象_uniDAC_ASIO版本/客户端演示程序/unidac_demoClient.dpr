program unidac_demoClient;

uses
  Forms,
  untMain in 'untMain.pas' {frm_main},
  UntRemSql in '..\GobUnit\UntRemSql.pas',
  untASIOSvr in '..\..\untAsioSvr\untASIOSvr.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tfrm_main, frm_main);
  Application.Run;
end.
