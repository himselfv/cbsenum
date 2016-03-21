unit DecouplePackagesJob;

interface
uses Windows, CBSEnum_JobProcessor, UniStrUtils;

type
  TDecouplePackagesJob = class(TProcessingThread)
  protected
    FPackageNames: TStringArray;
    procedure DecouplePackages(const AKey: string; const APackageNames: TStringArray);
  public
    constructor Create(const APackageNames: TStringArray);
    procedure Execute; override;
  end;

implementation
uses SysUtils, Classes, Registry, CBSEnum_Main;

constructor TDecouplePackagesJob.Create(const APackageNames: TStringArray);
begin
  inherited Create;
  Self.FPackageNames := APackageNames;
end;

//Ownership has to be already taken.
//PackageNames: list of packages to be decoupled from their parents. Lowercase. Empty == all packages.
procedure TDecouplePackagesJob.DecouplePackages(const AKey: string; const APackageNames: TStringArray);
var reg: TRegistry;
  subkeys: TStringList;
  subkey: string;
begin
  Log('Trying '+AKey+'...');
  subkeys := nil;
  reg := TRegistry.Create;
  try
    reg.RootKey := hkCbsRoot;
    if not reg.OpenKey(AKey, false) then begin
      Log('No such key.');
      exit; //no key, whatever
    end;

    subkeys := TStringList.Create;
    reg.GetKeyNames(subkeys);

    for subkey in subkeys do begin
      if Terminated then break;
      Log(subkey+'...');
      if (Length(APackageNames) = 0) or IsPackageInList(APackageNames, subkey) then try
        reg.DeleteKey(subkey+'\Owners');
        Log('Owners removed.');
      except
        on E: EOSError do
          if E.ErrorCode = ERROR_FILE_NOT_FOUND then
            continue
          else
            raise;
      end;
    end;

  finally
    FreeAndNil(subkeys);
    FreeAndNil(reg);
  end;
end;

procedure TDecouplePackagesJob.Execute;
begin
  DecouplePackages(sCbsKey+'\Packages', FPackageNames);
  DecouplePackages(sCbsKey+'\PackageNames', FPackageNames);
end;

end.
