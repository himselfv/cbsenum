program CBSEnum;

uses
  Vcl.Forms,
  CBSEnum_Main in 'CBSEnum_Main.pas' {MainForm},
  AclHelpers in 'AclHelpers.pas',
  CBSEnum_JobProcessor in 'CBSEnum_JobProcessor.pas' {JobProcessorForm},
  TakeOwnershipJob in 'TakeOwnershipJob.pas',
  DecouplePackagesJob in 'DecouplePackagesJob.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TJobProcessorForm, JobProcessorForm);
  Application.Run;
end.
