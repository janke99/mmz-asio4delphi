program ASIOTESpro;

uses
  fastmm4,
  Forms,
  asioTest in 'asioTest.pas' {view_main},
  untASIOSvr in '..\..\untAsioSvr\untASIOSvr.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tview_main, view_main);
  Application.Run;
end.

