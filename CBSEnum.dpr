program CBSEnum;

uses
  Vcl.Forms,
  CBSEnum_Main in 'CBSEnum_Main.pas' {MainForm},
  CBSEnum_JobProcessor in 'CBSEnum_JobProcessor.pas' {JobProcessorForm},
  AclHelpers in 'AclHelpers.pas',
  CommonResources in '..\ManifestEnum\CommonResources.pas' {ResourceModule},
  DelayLoadTree in '..\ManifestEnum\Views\DelayLoadTree.pas',
  TakeOwnershipJob in 'TakeOwnershipJob.pas',
  DecouplePackagesJob in 'DecouplePackagesJob.pas',
  WildcardMatching in 'WildcardMatching.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TJobProcessorForm, JobProcessorForm);
  Application.Run;
end.
