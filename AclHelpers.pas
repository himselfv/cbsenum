unit AclHelpers;
//Windows security-related functions helper

interface
uses Windows, AccCtrl;

{$IFDEF DEBUG}
//Logging for this module
type
  TMsgEvent = procedure(const AMessage: string) of object;
var
  OnLog: TMsgEvent;
{$ENDIF}


//LocalAlloc/LocalFree overrides, simplified
function LocalAlloc(uBytes: NativeUInt): pointer; inline;
function LocalReAlloc(ptr: pointer; uBytes: NativeUInt): pointer; inline;
procedure LocalFree(ptr: pointer); inline;


const
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));

  SECURITY_BUILTIN_DOMAIN_RID = $00000020;

  DOMAIN_ALIAS_RID_ADMINS = $00000220;

  SE_TAKE_OWNERSHIP_NAME = 'SeTakeOwnershipPrivilege';
  SE_BACKUP_NAME = 'SeBackupPrivilege';
  SE_RESTORE_NAME = 'SeRestorePrivilege';
  SE_SECURITY_NAME = 'SeSecurityPrivilege';

  OBJECT_INHERIT_ACE       = 1;
  CONTAINER_INHERIT_ACE    = 2;

  ACCESS_ALLOWED_ACE_TYPE  = 0;

type
  TLuid = TLargeInteger;

  ACE_HEADER = record
    AceType: BYTE;
    AceFlags: BYTE;
    AceSize: WORD;
  end;
  PACE_HEADER = ^ACE_HEADER;

  ACCESS_ALLOWED_ACE = record
    Header: ACE_HEADER;
    Mask: ACCESS_MASK;
    SidStart: DWORD;
  end;
  PACCESS_ALLOWED_ACE = ^ACCESS_ALLOWED_ACE;


function LookupPrivilegeValue(lpSystemName, lpName: LPCWSTR): TLuid;

function SetPrivilege(hToken: THandle; const APrivilege: TLuid; const AValue: boolean): boolean; overload;
function SetPrivilege(hToken: THandle; const APrivilege: string; const AValue: boolean): boolean; overload;

{
This is a sort of a wrapper shortcut. Usage:
if ClaimPrivilege(SE_PRIVILEGE_NAME, hPriv) <> 0 then begin
  ...
  ReleasePrivilege(hPriv);
end;
}
type
  TPrivToken = record
    hProcToken: THandle;
    luid: TLuid;
  end;

function ClaimPrivilege(const APrivilege: TLuid; out AToken: TPrivToken): boolean; overload;
function ClaimPrivilege(const APrivilege: string; out AToken: TPrivToken): boolean; overload; inline;
procedure ReleasePrivilege(const AToken: TPrivToken); overload;


function AllocateSidBuiltin(Group: DWORD): PSID;
function AllocateSidBuiltinAdministrators: PSID;

function IsUserInBuiltinGroup(Group: DWORD): BOOL;
function IsUserAdmin: BOOL;


{
To work with SDs directly they have to be converted to an absolute (unpacked) format.
This requires keeping 5 buffers.
Each edit replaces one of those buffers with the new version, the old one has
to be Free()d.
To store it, it has to be packed back to self-relative.

Since we're working only with the memory here, the functions simply throw instead of
sophisticated error codes.

ALL buffers passed MUST be allocated with LocalAlloc, since we'll LocalFree them.
This ensures interop with the API itself which uses these.
}
type
  TAbsoluteSD = class
  private
    FpAbsSD: PSECURITY_DESCRIPTOR;
    FpOwner: PSID;
    FpGroup: PSID;
    FpDacl: PACL;
    FpSacl: PACL;
    procedure Clear;
  public
    constructor FromSelfRelativeSD(pSelfRelativeSD: PSECURITY_DESCRIPTOR);
    destructor Destroy; override;
    function ToSelfRelativeSD(out Size: DWORD): PSECURITY_DESCRIPTOR;

    procedure ReplaceOwner(pNewOwner: PSID);
    function SwitchOwner(pNewOwner: PSID): PSID;

    procedure ReplaceGroup(pNewGroup: PSID);

    procedure ReplaceDacl(pNewDacl: PACL);
    function EnsureExplicitPermissions(aTrustee: PSID; APermissions: cardinal;
      APreviousPermissions: PCardinal = nil): boolean;

    procedure ReplaceSacl(pNewSacl: PACL);

    property PSD: PSECURITY_DESCRIPTOR read FpAbsSD;
  end;


//Changes owner info in the PSECURITY_DESCRIPTOR
function SwitchOwnership(pDescriptor: PSECURITY_DESCRIPTOR; aNewOwner: PSID;
  out aPreviousOwner: PSID): cardinal; overload;
//Creates a new DACL with explicit permissions for a trustee, unless it already had those.
procedure EnsureExplicitPermissions(const pDacl: PACL; aTrustee: PSID;
  APermissions: cardinal; APreviousPermissions: PCardinal; out pNewDacl: PACL);


//Changes owner info for a named security object
//pDescriptor has to be LocalFree()d, other out-parameters don't.
function SetOwnership(const AObjectName: string; AObjectType: SE_OBJECT_TYPE; aNewOwner: PSID): cardinal;
function SwitchOwnership(const AObjectName: string; AObjectType: SE_OBJECT_TYPE;
  aNewOwner: PSID; out aPreviousOwner: PSID; out pDescriptor: PSECURITY_DESCRIPTOR): cardinal; overload;

//Same, but extracts DACL, updates it and writes it back with SetNamedSecurityInfo.
function AddExplicitPermissions(const AObjectName: string; AObjectType: SE_OBJECT_TYPE; aTrustee: PSID;
  APermissions: cardinal; APreviousPermissions: PCardinal = nil): cardinal;

{
Does the standard unlock sequence on objects passed to it:
  Replaces the owner with the new one.
  Gives the old owner full rights.
  Gives the new owner full rights.
Returns 0 on success or error code from GetLastError().
}
type
  TUnlockResults = record
    hadOwnershipChanged: boolean;
    hadPermissionsChanged: boolean;
  end;
function UnlockNamedObject(const AObjectName: string; AObjectType: SE_OBJECT_TYPE;
  ANewOwner: PSID; AEnsurePermissions: cardinal; out Results: TUnlockResults): cardinal;




implementation
uses SysUtils, AclAPI;

{$IFDEF DEBUG}
procedure Log(const msg: string);
begin
  if Assigned(OnLog) then
    OnLog(msg);
end;
{$ELSE}
procedure Log(const msg: string);
begin
end;
{$ENDIF}

function LocalAlloc(uBytes: NativeUInt): pointer; inline;
begin
  Result := pointer(Windows.LocalAlloc(LMEM_FIXED, uBytes));
end;

function LocalReAlloc(ptr: pointer; uBytes: NativeUInt): pointer;
begin
  Result := pointer(Windows.LocalReAlloc(NativeUInt(ptr), uBytes, LMEM_FIXED));
end;

procedure LocalFree(ptr: pointer); inline;
begin
  Windows.LocalFree(NativeUInt(ptr));
end;


function CheckTokenMembership(TokenHandle: THandle; SidToCheck: PSID;
  out IsMember: BOOL): BOOL; stdcall; external advapi32;


//A version of LookupPrivilegeValue which handles failure by throwing error
function LookupPrivilegeValue(lpSystemName, lpName: LPCWSTR): TLuid;
begin
  if not Windows.LookupPrivilegeValue(lpSystemName, lpName, Result) then
    RaiseLastOsError();
end;

function SetPrivilege(hToken: THandle; const APrivilege: TLuid; const AValue: boolean): boolean; overload;
var tp: TOKEN_PRIVILEGES;
begin
  tp.PrivilegeCount := 1;
  tp.Privileges[0].Luid := APrivilege;
  if AValue then
    tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
  else
    tp.Privileges[0].Attributes := 0; //disabled

  Result := AdjustTokenPrivileges(hToken, false, tp, sizeof(tp), PTokenPrivileges(nil)^, PCardinal(nil)^);
end;

function SetPrivilege(hToken: THandle; const APrivilege: string; const AValue: boolean): boolean;
var sePrivilege: TLuid;
begin
  if not Windows.LookupPrivilegeValue(nil, PChar(APrivilege), sePrivilege) then
    Result := false
  else
    Result := SetPrivilege(hToken, sePrivilege, AValue);
end;

function ClaimPrivilege(const APrivilege: TLuid; out AToken: TPrivToken): boolean;
var err: integer;
begin
  AToken.luid := APrivilege;
  if not OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, AToken.hProcToken) then begin
    Result := false;
    exit;
  end;
  if not SetPrivilege(AToken.hProcToken, APrivilege, true) then begin
    err := GetLastError();
    CloseHandle(AToken.hProcToken); //can modify LastError
    AToken.hProcToken := 0;
    SetLastError(err);
    Result := false;
  end;
  Result := true;
end;

function ClaimPrivilege(const APrivilege: string; out AToken: TPrivToken): boolean; overload;
var sePrivilege: TLuid;
begin
  if not Windows.LookupPrivilegeValue(nil, PChar(APrivilege), sePrivilege) then begin
    Result := false;
    exit;
  end;
  Result := ClaimPrivilege(sePrivilege, AToken);
end;

procedure ReleasePrivilege(const AToken: TPrivToken); overload;
begin
  if AToken.hProcToken = 0 then exit;
  SetPrivilege(AToken.hProcToken, AToken.luid, false);
  CloseHandle(AToken.hProcToken);
end;


//Allocates a SID for a BUILTIN group. SID has to be freed with FreeSid
function AllocateSidBuiltin(Group: DWORD): PSID;
var SIDAuthNT: SID_IDENTIFIER_AUTHORITY;
begin
  SIDAuthNT := SECURITY_NT_AUTHORITY;
  if not AllocateAndInitializeSid(@SIDAuthNT, 2, SECURITY_BUILTIN_DOMAIN_RID,
    Group, 0, 0, 0, 0, 0, 0, Result) then
    RaiseLastOsError();
end;

//Allocates a SID for BUILTIN\Administrators. SID has to be freed with FreeSid.
function AllocateSidBuiltinAdministrators: PSID;
var SIDAuthNT: SID_IDENTIFIER_AUTHORITY;
begin
  SIDAuthNT := SECURITY_NT_AUTHORITY;
  if not AllocateAndInitializeSid(@SIDAuthNT, 2, SECURITY_BUILTIN_DOMAIN_RID,
    DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, Result) then
    RaiseLastOsError();
end;

//Returns true if the user is a member of a given builtin group
function IsUserInBuiltinGroup(Group: DWORD): BOOL;
var sidGroup: PSID;
begin
  sidGroup := AllocateSidBuiltin(Group);
  try
    if not CheckTokenMembership(0, sidGroup, Result) then
      Result := False;
  finally
    FreeSid(sidGroup);
  end;
end;

//Returns true if you are currently running with admin privileges
//Under Vista+ will return false when non-elevated.
function IsUserAdmin: BOOL;
var sidAdmin: PSID;
begin
  sidAdmin := AllocateSidBuiltinAdministrators;
  try
    if not CheckTokenMembership(0, sidAdmin, Result) then
      Result := False;
  finally
    FreeSid(sidAdmin);
  end;
end;


{
TAbsoluteSD
}

constructor TAbsoluteSD.FromSelfRelativeSD(pSelfRelativeSD: PSECURITY_DESCRIPTOR);
var
  SDSize, DaclSize, SaclSize, OwnerSize, GroupSize: DWORD;
begin
  inherited Create;

  //Determine required buffer sizes
  SDSize := 0; DaclSize := 0; SaclSize := 0; OwnerSize := 0; GroupSize := 0;
  Windows.MakeAbsoluteSD(pSelfRelativeSD, nil, SDSize, PACL(nil)^, DaclSize,
      PACL(nil)^, SaclSize, nil, OwnerSize, nil, GroupSize);

  //Allocate buffers based on returned sizes
  FpAbsSD := LocalAlloc(SDSize);
  if DaclSize  > 0 then FpDacl := LocalAlloc(DaclSize);
  if SaclSize  > 0 then FpSacl := LocalAlloc(SaclSize);
  if OwnerSize > 0 then FpOwner := LocalAlloc(OwnerSize);
  if GroupSize > 0 then FpGroup := LocalAlloc(GroupSize);

  //Second Call: Actually perform the conversion
  if not MakeAbsoluteSD(pSelfRelativeSD, FpAbsSD, SDSize, FpDacl^, DaclSize,
    FpSacl^, SaclSize, FpOwner, OwnerSize, FpGroup, GroupSize) then
  begin
    Clear;
    RaiseLastOSError;
  end;
end;

//The result has to be LocalFreed by the caller.
function TAbsoluteSD.ToSelfRelativeSD(out Size: DWORD): PSECURITY_DESCRIPTOR;
begin
  Size := 0;
  // Get required size
  MakeSelfRelativeSD(FpAbsSD, nil, Size);

  Result := LocalAlloc(Size);
  if not MakeSelfRelativeSD(FpAbsSD, Result, Size) then
  begin
    LocalFree(Result);
    RaiseLastOSError;
  end;
end;

procedure TAbsoluteSD.Clear;
begin
  if FpAbsSD <> nil then LocalFree(FpAbsSD);
  if FpDacl  <> nil then LocalFree(FpDacl);
  if FpSacl  <> nil then LocalFree(FpSacl);
  if FpOwner <> nil then LocalFree(FpOwner);
  if FpGroup <> nil then LocalFree(FpGroup);
end;

destructor TAbsoluteSD.Destroy;
begin
  Clear;
  inherited;
end;

procedure TAbsoluteSD.ReplaceOwner(pNewOwner: PSID);
begin
  if not SetSecurityDescriptorOwner(FpAbsSD, pNewOwner, False) then
    RaiseLastOSError;

  if FpOwner <> nil then LocalFree(FpOwner);
  FpOwner := pNewOwner;
end;

//Changes the owner IF the owner is different. Returns old SID if the switch happened.
//In any case, assumes ownership of the SID passed.
function TAbsoluteSD.SwitchOwner(pNewOwner: PSID): PSID;
begin
  if EqualSid(FpOwner, pNewOwner) then begin
    LocalFree(pNewOwner);
    Result := nil;
    exit;
  end;

  if not SetSecurityDescriptorOwner(FpAbsSD, pNewOwner, False) then
    RaiseLastOSError;

  Result := FpOwner;
  FpOwner := pNewOwner;
end;

procedure TAbsoluteSD.ReplaceGroup(pNewGroup: PSID);
begin
  if not SetSecurityDescriptorOwner(FpAbsSD, pNewGroup, False) then
    RaiseLastOSError;

  if FpGroup <> nil then LocalFree(FpGroup);
  FpGroup := pNewGroup;
end;

procedure TAbsoluteSD.ReplaceDacl(pNewDacl: PACL);
begin
  if not SetSecurityDescriptorDacl(FpAbsSD, True, pNewDacl, False) then
    RaiseLastOSError;

  if FpDacl <> nil then LocalFree(FpDacl);
  FpDacl := pNewDacl;
end;

//Adds access permissions for a trustee, if those were not already present.
function TAbsoluteSD.EnsureExplicitPermissions(aTrustee: PSID; APermissions: cardinal;
  APreviousPermissions: PCardinal = nil): boolean;
var pNewDacl: PACL;
begin
  AclHelpers.EnsureExplicitPermissions(Self.FpDacl, aTrustee, APermissions,
    APreviousPermissions, pNewDacl);
  Result := (pNewDacl <> nil);
  if pNewDacl <> nil then
    Self.ReplaceDacl(pNewDacl);
end;

procedure TAbsoluteSD.ReplaceSacl(pNewSacl: PACL);
begin
  if not SetSecurityDescriptorDacl(FpAbsSD, True, pNewSacl, False) then
    RaiseLastOSError;

  if FpSacl <> nil then LocalFree(FpSacl);
  FpSacl := pNewSacl;
end;


function SwitchOwnership(pDescriptor: PSECURITY_DESCRIPTOR; aNewOwner: PSID;
  out aPreviousOwner: PSID): cardinal;
var ownerDefaulted: LongBool;
begin
  if not Windows.GetSecurityDescriptorOwner(pDescriptor, aPreviousOwner, ownerDefaulted) then begin
    Result := GetLastError;
    exit;
  end;

  if EqualSid(aPreviousOwner, aNewOwner) then begin
    aPreviousOwner := nil;
    Result := ERROR_SUCCESS;
    exit;
  end;

  if not SetSecurityDescriptorOwner(pDescriptor, aNewOwner, false) then begin
    Result := GetLastError;
    exit;
  end;

  Result := ERROR_SUCCESS;
end;

//Replaces ownership for the object
function SetOwnership(const AObjectName: string; AObjectType: SE_OBJECT_TYPE; aNewOwner: PSID): cardinal;
begin
  Result := SetNamedSecurityInfo(PChar(AObjectName), AObjectType, OWNER_SECURITY_INFORMATION,
    @aNewOwner, nil, nil, nil);
end;

//Replaces ownership for the object, returns the previous owner or nil if no change was needed.
function SwitchOwnership(const AObjectName: string; AObjectType: SE_OBJECT_TYPE; aNewOwner: PSID;
  out aPreviousOwner: PSID; out pDescriptor: PSECURITY_DESCRIPTOR): cardinal;
begin
  Log('GetNamedSecurityInfo: '+AObjectName);
  Result := GetNamedSecurityInfo(PChar(AObjectName), AObjectType, OWNER_SECURITY_INFORMATION,
    @aPreviousOwner, nil, nil, nil, pDescriptor);
  if Result <> ERROR_SUCCESS then exit;

  if EqualSid(aPreviousOwner, aNewOwner) then begin
    LocalFree(pDescriptor);
    aPreviousOwner := nil;
    Result := ERROR_SUCCESS;
    exit;
  end;

  Log('SetNamedSecurityInfo: '+AObjectName);
  Result := SetNamedSecurityInfo(PChar(AObjectName), AObjectType, OWNER_SECURITY_INFORMATION,
    aNewOwner, nil, nil, nil);
end;


{
Adds access permissions for a trustee, if those were not already present.
Returns the newly allocated modified DACL if any changes had been needed.
Does not assume ownership of aTrustee or the old DACL.

This is mostly just memory modifications so I'm throwing on failures as hopeless.
There are edge cases: ACEs have entry limits. But atm I don't think these are common
enough to care about graceful continuation with error codes.
}
procedure EnsureExplicitPermissions(const pDacl: PACL; aTrustee: PSID;
  APermissions: cardinal; APreviousPermissions: PCardinal; out pNewDacl: PACL);
var i: integer;
  pAce: PACE_HEADER;
  pNewAccess: EXPLICIT_ACCESS;
  err: integer;
begin
  Log('Checking entries...');
  for i := 0 to pDacl.AceCount-1 do begin
    if not GetAce(pDacl, i, pointer(pAce)) then
      RaiseLastOsError(); //we could continue and try to write anyway, but let's not take risks

    if pAce.AceType = ACCESS_ALLOWED_ACE_TYPE then
      Log('Entry: Type='+IntToStr(pAce.AceType)+', mask='+IntToStr(PACCESS_ALLOWED_ACE(pAce)^.Mask))
    else
      Log('Entry: Type='+IntToStr(pAce.AceType));

   //we only settle on "all required rights in one go" because otherwise it's just too unstable
   //we also don't care if there's explicit "deny" or "re-set to less" afterwards, whoever placed it it's their problem
    if pAce.AceType <> ACCESS_ALLOWED_ACE_TYPE then continue;
    if PACCESS_ALLOWED_ACE(pAce)^.Mask and APermissions <> APermissions then continue;
    if not EqualSid(PSID(@PACCESS_ALLOWED_ACE(pAce).SidStart), aTrustee) then continue;

    Log('Existing grant_entry found');
   //Entry exist!
    if APreviousPermissions <> nil then
      APreviousPermissions^ := PACCESS_ALLOWED_ACE(pAce)^.Mask;
    pNewDacl := nil;
  end;

  Log('Adding new grant_entry');
 //No granting entry found, add explicitly
  pNewAccess.grfAccessPermissions := APermissions;
  pNewAccess.grfAccessMode := GRANT_ACCESS;
  pNewAccess.grfInheritance := CONTAINER_INHERIT_ACE or OBJECT_INHERIT_ACE;
  pNewAccess.Trustee.pMultipleTrustee := nil;
  pNewAccess.Trustee.MultipleTrusteeOperation := NO_MULTIPLE_TRUSTEE;
  pNewAccess.Trustee.TrusteeForm := TRUSTEE_IS_SID;
  pNewAccess.Trustee.TrusteeType := TRUSTEE_IS_UNKNOWN;
  pNewAccess.Trustee.ptstrName := PChar(aTrustee);

  Log('SetEntriesInAcl');
  err := SetEntriesInAcl(1, @pNewAccess, pDacl, pNewDacl);
  if err <> ERROR_SUCCESS then
    RaiseLastOsError(err);

  if APreviousPermissions <> nil then
    APreviousPermissions^ := 0;
end;

//Adds access permissions for a trustee, if those were not already present.
function AddExplicitPermissions(const AObjectName: string; AObjectType: SE_OBJECT_TYPE; aTrustee: PSID;
  APermissions: cardinal; APreviousPermissions: PCardinal): cardinal;
var pDescriptor: PSecurityDescriptor;
  pDacl: PACL;
  pNewDacl: PACL;
begin
  pNewDacl := nil;
  pDescriptor := nil;

  Log('GetNamedSecurityInfo: '+AObjectName);
  Result := GetNamedSecurityInfo(PChar(AObjectName), AObjectType, DACL_SECURITY_INFORMATION,
    nil, nil, @pDacl, nil, pointer(pDescriptor));
  if Result <> ERROR_SUCCESS then exit;
  try
    EnsureExplicitPermissions(pDacl, aTrustee, APermissions, APreviousPermissions, pNewDacl);
    if pNewDacl = nil then //Nothing to change
      exit;

    Log('SetNamedSecurityInfo');
    Result := SetNamedSecurityInfo(PChar(AObjectName), AObjectType, DACL_SECURITY_INFORMATION,
      nil, nil, pNewDacl, nil);
    if Result <> ERROR_SUCCESS then begin
      Log('SetNamedSecurityInfo: error '+IntToStr(Result));
      exit;
    end;
  finally
    LocalFree(pDescriptor);
    if pNewDacl <> nil then
      LocalFree(pNewDacl);
  end;
end;

function UnlockNamedObject(const AObjectName: string; AObjectType: SE_OBJECT_TYPE;
  ANewOwner: PSID; AEnsurePermissions: cardinal; out Results: TUnlockResults): cardinal;
var pSidPreviousOwner: PSID;
  pPreviousDesc: PSECURITY_DESCRIPTOR;
  APreviousPermissions: cardinal;
begin
  Results.hadOwnershipChanged := false;
  Results.hadPermissionsChanged := false;

  Log('Checking ownership for '+AObjectName+'...');
  Result := SwitchOwnership(AObjectName, AObjectType, ANewOwner, pSidPreviousOwner, pPreviousDesc);
  if Result <> 0 then begin
    Log('Cannot switch ownership: '+IntToStr(Result));
    exit;
  end;

  if pSidPreviousOwner <> nil then begin
    Log('Ownership changed for '+AObjectName+', giving the original owner all permissions...');
    Results.hadOwnershipChanged := true;
    AddExplicitPermissions(AObjectName, AObjectType, pSidPreviousOwner, AEnsurePermissions);
    if pPreviousDesc <> nil then
      LocalFree(pPreviousDesc);
  end;
  Log('Giving new owner all permissions...');
  Result := AddExplicitPermissions(AObjectName, AObjectType, ANewOwner, AEnsurePermissions, @APreviousPermissions);
  if Result = 0 then
    Results.hadPermissionsChanged := ((APreviousPermissions and AEnsurePermissions) <> AEnsurePermissions)
  else begin
    Log('Cannot give permissions, error '+IntToStr(Result));
  end;
end;


end.
