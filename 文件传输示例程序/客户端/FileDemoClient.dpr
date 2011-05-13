program FileDemoClient;

uses
  Forms,
  viewMain in 'viewMain.pas' {view_Main},
  untRmoDbClient in 'untRmoDbClient.pas',
  UntsocketDxBaseClient in 'UntsocketDxBaseClient.pas',
  untASIOSvr in '..\..\untAsioSvr\untASIOSvr.pas',
  viewFileMM in 'viewFileMM.pas' {view_FileMM};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tview_Main, view_Main);
  Application.CreateForm(Tview_FileMM, view_FileMM);
  Application.Run;
end.

