program up;

uses
  Forms,
  viewMain in 'viewMain.pas' {View_main};

{$R *.res}

begin
  Application.Initialize;
//  if ParamCount > 1 then
    Application.CreateForm(TView_main, View_main);
  Application.Run;
end.

