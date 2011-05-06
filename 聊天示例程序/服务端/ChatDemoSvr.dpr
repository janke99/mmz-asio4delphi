program ChatDemoSvr;

uses
 // FastMM4,
  Forms,
  viewMain in 'viewMain.pas' {view_Main},
  UntRmodbSvr in 'UntRmodbSvr.pas',
  untASIOSvr in '..\..\untAsioSvr\untASIOSvr.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tview_Main, view_Main);
  Application.Run;
end.
