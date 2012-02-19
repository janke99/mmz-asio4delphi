program unidac_Dbsvr;

uses
//  FastMM4,
  Forms,
  untMain in 'untMain.pas' {frm_main},
  UntRmodbSvr in '..\GobUnit\UntRmodbSvr.pas',
  DM in 'DM.pas' {DataModel: TDataModule},
  untASIOSvr in '..\..\untAsioSvr\untASIOSvr.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tfrm_main, frm_main);
  Application.CreateForm(TDataModel, DataModel);
  Application.Run;
end.

