program ASIOTestClient;

uses
  FastMM4,
  Forms,
  modelASIOtest in 'modelASIOtest.pas' {ASIO_test},
  modelCommClient in 'modelCommClient.pas',
  UntsocketDxBaseClient in 'UntsocketDxBaseClient.pas',
  untASIOSvr in '..\..\untAsioSvr\untASIOSvr.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TASIO_test, ASIO_test);
  Application.Run;
end.

