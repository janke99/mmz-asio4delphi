program Dbsvr;

uses
  Forms,
  untMain in 'untMain.pas' {frm_main},
  UntRmodbSvr in '..\GobUnit\UntRmodbSvr.pas',
  DM in 'DM.pas' {DataModel: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tfrm_main, frm_main);
  Application.CreateForm(TDataModel, DataModel);
  Application.Run;
end.

