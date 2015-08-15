program CBSEnum;

uses
  Vcl.Forms,
  CBSEnum_Main in 'CBSEnum_Main.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
