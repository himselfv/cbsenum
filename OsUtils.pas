unit OsUtils;

interface
uses SysUtils, Windows;

function GetSystemDir: string;
function GetWindowsDir: string;

function StartProcess(const AProgramName, ACommandLine: string): TProcessInformation;
procedure RegeditOpenAndNavigate(const ARegistryPath: string);
procedure ShellOpen(const sCommand: string; const sParams: string = '');
procedure ExplorerAtFile(const AFilename: string);


implementation
uses Registry, ShellAPI;

function GetSystemDir: string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
   GetSystemDirectory(Buffer, MAX_PATH - 1);
   SetLength(Result, StrLen(Buffer));
   Result := Buffer;
end;

function GetWindowsDir: string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
   GetWindowsDirectory(Buffer, MAX_PATH - 1);
   SetLength(Result, StrLen(Buffer));
   Result := Buffer;
end;

function StartProcess(const AProgramName, ACommandLine: string): TProcessInformation;
var startupInfo: TStartupInfo;
begin
  FillChar(startupInfo, SizeOf(startupInfo), 0);
  FillChar(Result, SizeOf(Result), 0);
  if not CreateProcess(PChar(AProgramName), PChar(ACommandLine),
    nil, nil, false, 0, nil, nil, startupInfo, Result) then
    RaiseLastOsError();
end;

procedure RegeditOpenAndNavigate(const ARegistryPath: string);
var reg: TRegistry;
begin
 //That's the only damn way
 //Well, there's also regjump.exe from SysInternals but it shows EULA and it's
 //a dependency.
 //It can also be done directly using UI automation.
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if not reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Applets\Regedit', true) then
      raise Exception.Create('Cannot point regedit at a key.');
    reg.WriteString('LastKey', ARegistryPath);
  finally
    FreeAndNil(reg);
  end;
  StartProcess(GetWindowsDir()+'\regedit.exe', 'regedit.exe');
end;

procedure ShellOpen(const sCommand: string; const sParams: string = '');
begin
  ShellExecute(0, 'open', PChar(sCommand), PChar(sParams), '', SW_SHOW);
end;

procedure ExplorerAtFile(const AFilename: string);
begin
  ShellExecute(0, '', PChar('explorer.exe'), PChar('/select,"'+AFilename+'"'),
    '', SW_SHOW);
end;

end.
