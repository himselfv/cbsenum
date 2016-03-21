unit AclHelpers;
//Windows security-related functions helper

interface
uses Windows, AccCtrl;

const
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));

  SECURITY_BUILTIN_DOMAIN_RID = $00000020;

  DOMAIN_ALIAS_RID_ADMINS = $00000220;

  SE_TAKE_OWNERSHIP_NAME = 'SeTakeOwnershipPrivilege';

  OBJECT_INHERIT_ACE       = 1;
  CONTAINER_INHERIT_ACE    = 2;

type
  TLuid = TLargeInteger;

{$IFDEF DEBUG}
type
  TMsgEvent = procedure(const AMessage: string) of object;

var
  OnLog: TMsgEvent;
{$ENDIF}

procedure Log(const msg: string);// inline;

function LookupPrivilegeValue(lpSystemName, lpName: LPCWSTR): TLuid;

function SetPrivilege(hToken: THandle; const APrivilege: TLuid; const AValue: boolean): boolean; overload;
function SetPrivilege(hToken: THandle; const APrivilege: string; const AValue: boolean): boolean; overload;

function AllocateSidBuiltinAdministrators: PSID;

//pDescriptor has to be LocalFree()d, other out-parameters don't.
function SetOwnership(const AObjectName: string; AObjectType: SE_OBJECT_TYPE; aNewOwner: PSID): cardinal;
function SwitchOwnership(const AObjectName: string; AObjectType: SE_OBJECT_TYPE;
  aNewOwner: PSID; out aPreviousOwner: PSID; out pDescriptor: PSECURITY_DESCRIPTOR): cardinal;

function AddExplicitPermissions(const AObjectName: string; AObjectType: SE_OBJECT_TYPE; aTrustee: PSID;
  APermissions: cardinal): cardinal;


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

//Allocates a SID for BUILTIN\Administrators. SID has to be freed with FreeSid.
function AllocateSidBuiltinAdministrators: PSID;
var SIDAuthNT: SID_IDENTIFIER_AUTHORITY;
begin
  SIDAuthNT := SECURITY_NT_AUTHORITY;
  if not AllocateAndInitializeSid(@SIDAuthNT, 2, SECURITY_BUILTIN_DOMAIN_RID,
    DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, Result) then
    RaiseLastOsError();
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
    LocalFree(NativeUInt(pDescriptor));
    aPreviousOwner := nil;
    Result := ERROR_SUCCESS;
    exit;
  end;

  Log('SetNamedSecurityInfo: '+AObjectName);
  Result := SetNamedSecurityInfo(PChar(AObjectName), AObjectType, OWNER_SECURITY_INFORMATION,
    aNewOwner, nil, nil, nil);
end;

//Adds access permissions for a trustee, if those were not already present.
function AddExplicitPermissions(const AObjectName: string; AObjectType: SE_OBJECT_TYPE; aTrustee: PSID;
  APermissions: cardinal): cardinal;
var pDescriptor: PSecurityDescriptor;
  pDacl: PACL;
  AceCount: cardinal;
  pAceEntries, pAceEntry: PEXPLICIT_ACCESS;
  pNewDacl: PACL;
  pNewAccess: EXPLICIT_ACCESS;
begin
  pNewDacl := nil;
  pAceEntries := nil;

  Log('GetNamedSecurityInfo: '+AObjectName);
  Result := GetNamedSecurityInfo(PChar(AObjectName), AObjectType, DACL_SECURITY_INFORMATION,
    nil, nil, @pDacl, nil, pointer(pDescriptor));
  if Result <> ERROR_SUCCESS then exit;
  try
    Log('GetExplicitEntriesFromAcl');
    Result := GetExplicitEntriesFromAcl(pDacl^, AceCount, PEXPLICIT_ACCESS_(@pAceEntries));
    if Result <> ERROR_SUCCESS then exit; //we could continue and try to write anyway, but let's not take risks

    Log('Checking entries...');
    pAceEntry := pAceEntries;
    while AceCount > 0 do begin
      if ((pAceEntry.grfAccessMode = GRANT_ACCESS) or (pAceEntry.grfAccessMode = SET_ACCESS))
      //we only settle on "all required rights in one go" because otherwise it's just too unstable
      //we also don't care if there's explicit "deny" or "re-set to less" afterwards, whoever placed it it's their problem
      and (pAceEntry.grfAccessPermissions and APermissions = APermissions)
      and (pAceEntry.Trustee.TrusteeForm = TRUSTEE_IS_SID) // I hope TRUSTEE_IS_NAME is never returned, or we have to convert and check
      and EqualSid(PSID(pAceEntry.Trustee.ptstrName), aTrustee) then begin
        Log('Existing grant_entry found');
       //Entry exist!
        Result := ERROR_SUCCESS;
        exit;
      end;

      Dec(AceCount);
      Inc(pAceEntry);
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
    Result := SetEntriesInAcl(1, @pNewAccess, pDacl, pNewDacl);
    if Result <> ERROR_SUCCESS then exit;

    Log('SetNamedSecurityInfo');
    Result := SetNamedSecurityInfo(PChar(AObjectName), AObjectType, DACL_SECURITY_INFORMATION,
      nil, nil, pNewDacl, nil);
  finally
    if pAceEntries <> nil then
      LocalFree(NativeUInt(pAceEntries));
    LocalFree(NativeUInt(pDescriptor));
    if pNewDacl <> nil then
      LocalFree(NativeUInt(pNewDacl));
  end;
end;

end.
