unit CBSEnum_JobProcessor;
// Runs threaded jobs

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TLogEvent = procedure(const AMessage: string) of object;
  TProcessingThread = class(TThread)
  protected
    FOnLog: TLogEvent;
    procedure Log(const AMessage: string);
  public
    constructor Create;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

  TJobProcessorForm = class(TForm)
    mmLog: TMemo;
    UpdateTimer: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure UpdateTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mmLogChange(Sender: TObject);
  protected
    FThread: TProcessingThread;
    FLogSync: TRtlCriticalSection;
    FNewLogLines: TStringList;
    procedure ProcessingThreadLog(const AMessage: string);
    procedure PostLogEntries;
  public
    procedure Log(const msg: string);
    procedure Process(AJob: TProcessingThread);
    procedure EndProcessing;
  end;

var
  JobProcessorForm: TJobProcessorForm;

implementation

{$R *.dfm}

constructor TProcessingThread.Create;
begin
  inherited Create({Suspended=}true); //always create suspended
end;

procedure TProcessingThread.Log(const AMessage: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AMessage);
end;

procedure TJobProcessorForm.FormCreate(Sender: TObject);
begin
  InitializeCriticalSection(FLogSync);
  FNewLogLines := TStringList.Create;
end;

procedure TJobProcessorForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FNewLogLines);
  DeleteCriticalSection(FLogSync);
end;

procedure TJobProcessorForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := (not Assigned(FThread))
    or (MessageBox(Self.Handle, PChar('The operation is still in progress, do you want to abort it?'),
      PChar('Confirm abort'), MB_ICONQUESTION + MB_YESNO) = ID_YES);
end;

procedure TJobProcessorForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  EndProcessing;
end;

procedure TJobProcessorForm.Process(AJob: TProcessingThread);
begin
  if Assigned(FThread) then
    raise Exception.Create('Operation is still in progress');
  FThread := AJob;
  FThread.OnLog := ProcessingThreadLog;
  FThread.Start;
  UpdateTimer.Enabled := true;
end;

procedure TJobProcessorForm.EndProcessing;
begin
  if Assigned(FThread) then begin
    FThread.Terminate;
    FThread.WaitFor;
    FreeAndNil(FThread);
  end;
  UpdateTimer.Enabled := false;
  PostLogEntries(); //in case there's anything pending
end;

procedure TJobProcessorForm.UpdateTimerTimer(Sender: TObject);
begin
  PostLogEntries;

  if FThread = nil then begin
    UpdateTimer.Enabled := false;
    exit;
  end;

  if FThread.FatalException <> nil then begin
    Log('Fatal exception '+FThread.FatalException.ClassName+': '+Exception(FThread.FatalException).Message);
    EndProcessing();
    exit;
  end;

  if FThread.Finished then
    EndProcessing;
end;

procedure TJobProcessorForm.ProcessingThreadLog(const AMessage: string);
begin
  EnterCriticalSection(FLogSync);
  try
    FNewLogLines.Add(AMessage);
  finally
    LeaveCriticalSection(FLogSync);
  end;
end;

procedure TJobProcessorForm.PostLogEntries;
var line: string;
begin
  EnterCriticalSection(FLogSync);
  try
    mmLog.Lines.BeginUpdate;
    for line in FNewLogLines do
      mmLog.Lines.Add(line);
    FNewLogLines.Clear;
    mmLog.Lines.EndUpdate;
    mmLog.Refresh;
  finally
    LeaveCriticalSection(FLogSync);
  end;
end;

procedure TJobProcessorForm.Log(const msg: string);
begin
  mmLog.Lines.Add(msg);
end;


procedure TJobProcessorForm.mmLogChange(Sender: TObject);
begin
  SendMessage(mmLog.Handle, EM_LINESCROLL, 0, mmLog.Lines.Count);
end;

end.
