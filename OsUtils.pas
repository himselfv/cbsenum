unit OsUtils;

interface
uses SysUtils, Windows;

function GetSystemDir: string;
function GetWindowsDir: string;
function GetModuleFilenameStr(hModule: HMODULE = 0): string;
function AppFolder: string;

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

//Max length, in symbols, of supported image path size.
const
  MAX_PATH_LEN = 8192;

function GetModuleFilenameStr(hModule: HMODULE = 0): string;
var nSize, nRes: dword;
begin
  nSize := 256;
  SetLength(Result, nSize);

  nRes := GetModuleFilenameW(hModule, @Result[1], nSize);
  while (nRes <> 0) and (nRes >= nSize) and (nSize < MAX_PATH_LEN) do begin
    nSize := nSize * 2;
    SetLength(Result, nSize);
    nRes := GetModuleFilenameW(hModule, @Result[1], nSize);
  end;

  if nRes = 0 then begin
    Result := '';
    exit;
  end;

  if nRes >= nSize then begin
    Result := '';
    exit;
  end;

  SetLength(Result, nRes);
end;

function AppFolder: string;
begin
  Result := GetModuleFilenameStr();
  if Result <> '' then
    Result := SysUtils.ExtractFilePath(Result);
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
