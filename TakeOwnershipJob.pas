unit TakeOwnershipJob;

interface
uses Windows, Registry, AccCtrl, CBSEnum_JobProcessor;

{$IFDEF DEBUG}
//{$DEFINE DEBUG_HELPER}
{$ENDIF}

type
  TTakeOwnershipJob = class(TProcessingThread)
  protected
   {$IFDEF DEBUG_HELPER}
    procedure AclHelpersLog(const AMsg: string);
   {$ENDIF}
    procedure TakeRegistryOwnership();
    procedure TakeRegistryOwnershipOfKey(AReg: TRegistry; const AKey: string; ANewOwner: PSID);
  public
    procedure Execute; override;
  end;

implementation
uses SysUtils, Classes, AclHelpers, CBSEnum_Main;

{$IFDEF DEBUG_HELPER}
procedure TTakeOwnershipJob.AclHelpersLog(const AMsg: string);
begin
  Self.Log(AMsg);
end;
{$ENDIF}

procedure TTakeOwnershipJob.Execute;
begin
 {$IFDEF DEBUG_HELPER}
  AclHelpers.OnLog := Self.AclHelpersLog;
 {$ENDIF}
  TakeRegistryOwnership();
 {$IFDEF DEBUG_HELPER}
  AclHelpers.OnLog := nil;
 {$ENDIF}
end;

procedure TTakeOwnershipJob.TakeRegistryOwnership();
var hProcToken: THandle;
  pSidAdmin: PSID;
  reg: TRegistry;
begin
  pSidAdmin := nil;

 //Before we take ownership, we need to claim that privilege
  Log('Opening process token');
  if not OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, hProcToken) then
    RaiseLastOsError();
  Log('Setting SE_TAKE_OWNERSHIP_NAME');
  if not SetPrivilege(hProcToken, SE_TAKE_OWNERSHIP_NAME, true) then
    RaiseLastOsError();

 //Clear and release the handles later
  try
    Log('Getting BUILTIN\Administrators reference');
   //We're going to give ownership to BUILTIN\Administrators, this is comparatively safe + fits our needs
    pSidAdmin := AllocateSidBuiltinAdministrators();

    reg := TRegistry.Create;
    try
      reg.RootKey := hkCbsRoot;
      reg.Access := KEY_READ;
      TakeRegistryOwnershipOfKey(reg, '\'+sCbsKey, pSidAdmin);
    finally
      FreeAndNil(reg);
    end;

  finally
    if pSIDAdmin <> nil then
      FreeSid(pSIDAdmin);

    Log('Clearing SE_TAKE_OWNERSHIP_NAME');
    SetPrivilege(hProcToken, SE_TAKE_OWNERSHIP_NAME, false);
    CloseHandle(hProcToken);
  end;
  Log('Done.');
end;

//Called for every child key, recursively. Sets its owner to ANewOwner and gives the previous owner full rights.
//Key must start with /
procedure TTakeOwnershipJob.TakeRegistryOwnershipOfKey(AReg: TRegistry; const AKey: string; ANewOwner: PSID);
var subkeys: TStringList;
  subkey: string;
  err: cardinal;
  pSidPreviousOwner: PSID;
  pPreviousOwnerDescriptor: PSECURITY_DESCRIPTOR;
begin
  Log('Processing key '+AKey);
 //There's no way to "go one level upper" with TRegistry so we're stuck with non-efficient "open each key from the root"
  if not AReg.OpenKey(AKey, false) then
    RaiseLastOsError();

  err := SwitchOwnership(sCbsRootSec+AKey, SE_REGISTRY_KEY, ANewOwner, pSIDPreviousOwner,
    pPreviousOwnerDescriptor);
  if err <> ERROR_SUCCESS then RaiseLastOsError(err);

  if pSidPreviousOwner <> nil then try
    Log('...ownership taken, granting permissions to previous owner');
   //Give explicit full permissions to the previous owner
    err := AddExplicitPermissions(sCbsRootSec+AKey, SE_REGISTRY_KEY, pSidPreviousOwner, KEY_ALL_ACCESS);
    if err <> ERROR_SUCCESS then
      RaiseLastOsError(err);

  finally
    LocalFree(NativeUInt(pPreviousOwnerDescriptor));
    pPreviousOwnerDescriptor := nil;
    pSidPreviousOwner := nil;
  end else
    Log('...already owned.');

 //Give new owner full access (if they don't have it)
  err := AddExplicitPermissions(sCbsRootSec+AKey, SE_REGISTRY_KEY, ANewOwner, KEY_ALL_ACCESS);
  if err <> ERROR_SUCCESS then
    RaiseLastOsError(err);

 //Process subkeys
  subkeys := TStringList.Create;
  try
    AReg.GetKeyNames(subkeys);
    for subkey in subkeys do begin
      TakeRegistryOwnershipOfKey(AReg, AKey+'\'+subkey, ANewOwner);
      if Terminated then break;
    end;
  finally
    FreeAndNil(subkeys);
  end;
end;


end.
