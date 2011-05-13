program FileDemoSvr;

uses
 // FastMM4,
  Forms,
  viewMain in 'viewMain.pas' {view_Main},
  UntRmodbSvr in 'UntRmodbSvr.pas',
  untASIOSvr in '..\..\untAsioSvr\untASIOSvr.pas',
  untfunctions;

{$R *.res}

begin
  Application.Initialize;
  if AppRunOnce then begin
    Application.CreateForm(Tview_Main, view_Main);
  end;
  Application.Run;
end.

