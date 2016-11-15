unit CBSEnum_Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, Menus,
  StdCtrls, ExtCtrls, ImgList, ComCtrls, ExtDlgs, VirtualTrees, Generics.Collections, Registry,
  UniStrUtils, AssemblyDb, AssemblyDb.Assemblies, AssemblyResourcesView;

type
  TPackage = class
    Name: string; //full package name
    DisplayName: string; //display name
    Variation: string; //base/WOW64
    CbsVisibility: integer;
    DefaultCbsVisibility: integer; //if preserved in DefVis key by anyone
  end;

  TPackageArray = array of TPackage;
  PPackageArray = ^TPackageArray;

  TPackageGroup = class
  protected
    Name: string;
    Subgroups: TObjectList<TPackageGroup>;
    Packages: TObjectList<TPackage>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddPackage(APackageName: string; APackage: TPackage); overload;
    function AddPackage(AFullPackageName: string): TPackage; overload;
    function FindSubgroup(const AGroupName: string): TPackageGroup;
    function NeedSubgroup(const AGroupName: string): TPackageGroup;
    procedure CompactNames;
    function SelectMatching(const AMask: string): TPackageArray; overload;
    procedure SelectMatching(AMask: string; var AArray: TPackageArray); overload;
  end;

  TNdPackageData = record
    DisplayName: string; //display name
    Package: TPackage; //if assigned
    IsVisible: boolean;
  end;
  PNdPackageData = ^TNdPackageData;

  TMainForm = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    cbShowWOW64: TCheckBox;
    PopupMenu: TPopupMenu;
    cbShowKb: TCheckBox;
    pmUninstall: TMenuItem;
    N1: TMenuItem;
    pmReload: TMenuItem;
    Label2: TLabel;
    pnlGroupMode: TPanel;
    rbGroupEachPart: TRadioButton;
    rbGroupDistinctParts: TRadioButton;
    Panel3: TPanel;
    vtPackages: TVirtualStringTree;
    edtFilter: TEdit;
    pmUninstallAll: TMenuItem;
    ImageList1: TImageList;
    pmCopyPackageNames: TMenuItem;
    pcPageInfo: TPageControl;
    tsInfo: TTabSheet;
    lblDescription: TLabel;
    lbUpdates: TListBox;
    MainMenu: TMainMenu;
    File1: TMenuItem;
    Service1: TMenuItem;
    Diskcleanup1: TMenuItem;
    Exit1: TMenuItem;
    Optionalfeatures1: TMenuItem;
    pmCopyUninstallationCommands: TMenuItem;
    pmOpenCBSRegistry: TMenuItem;
    Edit1: TMenuItem;
    rbGroupFlat: TRadioButton;
    pmMakeVisible: TMenuItem;
    pmMakeInvisible: TMenuItem;
    pmRestoreDefaultVisibility: TMenuItem;
    pmVisibility: TMenuItem;
    pmMakeAllVisibile: TMenuItem;
    pmMakeAllInvisible: TMenuItem;
    pmRestoreDefaltVisibilityAll: TMenuItem;
    cbShowHidden: TCheckBox;
    pmUninstallByList: TMenuItem;
    N2: TMenuItem;
    UninstallListOpenDialog: TOpenDialog;
    pmSavePackageList: TMenuItem;
    PackageListSaveDialog: TSaveTextFileDialog;
    Saveselectedpackagelist1: TMenuItem;
    pmTakeRegistryOwnership: TMenuItem;
    pmDecoupleAllPackages: TMenuItem;
    pmDecouplePackages: TMenuItem;
    N3: TMenuItem;
    pmCopySubmenu: TMenuItem;
    pmManageSubmenu: TMenuItem;
    N4: TMenuItem;
    Rebuildassemblydatabase1: TMenuItem;
    DismCleanup1: TMenuItem;
    tsResources: TTabSheet;
    procedure FormShow(Sender: TObject);
    procedure vtPackagesGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure vtPackagesFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vtPackagesGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure vtPackagesInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure cbShowWOW64Click(Sender: TObject);
    procedure vtPackagesPaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure PopupMenuPopup(Sender: TObject);
    procedure pmReloadClick(Sender: TObject);
    procedure rbGroupEachPartClick(Sender: TObject);
    procedure edtFilterChange(Sender: TObject);
    procedure edtFilterKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure pmUninstallAllClick(Sender: TObject);
    procedure pmCopyPackageNamesClick(Sender: TObject);
    procedure vtPackagesFocusChanged(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex);
    procedure tsInfoEnter(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Diskcleanup1Click(Sender: TObject);
    procedure Optionalfeatures1Click(Sender: TObject);
    procedure pmCopyUninstallationCommandsClick(Sender: TObject);
    procedure pmOpenCBSRegistryClick(Sender: TObject);
    procedure pmMakeVisibleClick(Sender: TObject);
    procedure pmMakeInvisibleClick(Sender: TObject);
    procedure pmRestoreDefaultVisibilityClick(Sender: TObject);
    procedure pmMakeAllVisibileClick(Sender: TObject);
    procedure pmMakeAllInvisibleClick(Sender: TObject);
    procedure pmRestoreDefaltVisibilityAllClick(Sender: TObject);
    procedure pmUninstallByListClick(Sender: TObject);
    procedure Saveselectedpackagelist1Click(Sender: TObject);
    procedure pmSavePackageListClick(Sender: TObject);
    procedure pmDecoupleAllPackagesClick(Sender: TObject);
    procedure pmDecouplePackagesClick(Sender: TObject);
    procedure pmTakeRegistryOwnershipClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Rebuildassemblydatabase1Click(Sender: TObject);
    procedure DismCleanup1Click(Sender: TObject);
    procedure tsResourcesEnter(Sender: TObject);
  protected
    FPackages: TPackageGroup;
    FTotalPackages: integer;

  protected
    FVisiblePackages: integer;
    procedure ReloadPackageTree(AGroup: TPackageGroup; ATreeNode: PVirtualNode);
    function CreateNode(AParent: PVirtualNode; ADisplayName: string; APackage: TPackage): PVirtualNode;
    function FindNode(AParent: PVirtualNode; ADisplayName: string): PVirtualNode;
    procedure UpdateNodeVisibility();
    procedure ResetVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode; Data: Pointer; var Abort: Boolean);
    procedure UpdatePackageVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode; Data: Pointer; var Abort: Boolean);
    procedure ApplyVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode; Data: Pointer; var Abort: Boolean);
    procedure CountVisiblePackages_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode; Data: Pointer; var Abort: Boolean);
    function IsPackageNodeVisible(ANode: PVirtualNode): boolean;
  protected
    function GetAllPackages: TPackageArray;
    function GetSelectedPackages: TPackageArray;
    function GetChildPackages(ANode: PVirtualNode): TPackageArray;
    procedure GetPackages_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Data: Pointer; var Abort: Boolean);
    function GetSelectedPackageNames: TStringArray;
    function GetChildPackageNames(ANode: PVirtualNode): TStringArray;

  protected
    procedure DismUninstall(const APackageName: string); overload;
    procedure DismUninstall(const APackageNames: TStringArray); overload;
    procedure SetCbsVisibility(const AKey: string; APackages: TPackageArray; AVisibility: integer); overload;
    procedure SetCbsVisibility(APackages: TPackageArray; AVisibility: integer); overload;
    procedure SavePackageList(APackageNames: TStringArray);

  protected //Assembly database
    FDb: TAssemblyDb;
    FResources: TAssemblyResourcesForm;

  protected
    procedure UpdateFormCaption;
  public
    procedure Reload;

  end;

var
  MainForm: TMainForm;

const
  hkCbsRoot = HKEY_LOCAL_MACHINE;
  sCbsRootSec = 'MACHINE'; //for security-related functions
  sCbsKey = 'Software\Microsoft\Windows\CurrentVersion\Component Based Servicing';

const
  CBS_E_INVALID_PACKAGE = $800F0805;

function IsPackageInList(const AList: TPackageArray; APackage: TPackage): boolean; inline; overload;
function IsPackageInList(const AList: TStringArray; APackageName: string): boolean; inline; overload;

implementation
uses Clipbrd, XmlDoc, XmlIntf, AccCtrl, OsUtils, AclHelpers, CBSEnum_JobProcessor, TakeOwnershipJob,
  DecouplePackagesJob, FilenameUtils, AssemblyDbBuilder, Generics.Defaults;

{$R *.dfm}

resourcestring
  sCannotOpenCbsRegistry = 'Cannot open registry key for packages. Perpahs '
    +'you''re not running the app with administrator rights? Or the Windows '
    +'version is incompatible.';


function IsPackageInList(const AList: TPackageArray; APackage: TPackage): boolean; inline; overload;
var i: integer;
begin
  Result := false;
  for i := 0 to Length(AList)-1 do
    if AList[i]=APackage then begin
      Result := true;
      break;
    end;
end;

function IsPackageInList(const AList: TStringArray; APackageName: string): boolean; inline; overload;
var i: integer;
begin
  Result := false;
  for i := 0 to Length(AList)-1 do
    if SameText(AList[i], APackageName) then begin
      Result := true;
      break;
    end;
end;

function PackagesToPackageNames(APackages: TPackageArray): TStringArray;
var i: integer;
begin
  SetLength(Result, Length(APackages));
  for i := 0 to Length(APackages)-1 do
    Result[i] := APackages[i].Name;
end;


constructor TPackageGroup.Create;
begin
  inherited;
  Subgroups := TObjectList<TPackageGroup>.Create;
  Packages := TObjectList<TPackage>.Create;
end;

destructor TPackageGroup.Destroy;
begin
  FreeAndNil(Packages);
  FreeAndNil(Subgroups);
  inherited;
end;

//Mostly used internally to route package to appropriate group
procedure TPackageGroup.AddPackage(APackageName: string; APackage: TPackage);
var pos_minus, pos_tilde: integer;
  AGroupName: string;
  AGroup: TPackageGroup;
begin
 //Eat one part of the name. Mind names like Microsoft-Windows-Defender~ru-RU (note last minus)
  pos_tilde := pos('~', APackageName);
  repeat
    pos_minus := pos('-', APackageName);
    if (pos_minus <= 0) or ((pos_tilde > 0) and (pos_tilde < pos_minus)) then
      break; //last part

    AGroupName := copy(APackageName, 1, pos_minus-1);
    delete(APackageName, 1, pos_minus);
    pos_tilde := pos_tilde - pos_minus; //since we've eaten some chars

    if SameText(AGroupName, 'WOW64') then begin
      APackage.Variation := 'WOW64';
      APackageName := APackageName + ' (WOW64)'; //could be made properly, on display
      continue; //chew another part
    end;

    AGroup := Self.NeedSubgroup(AGroupName);
    AGroup.AddPackage(APackageName, APackage);
    exit;
  until false;

 //Most package names end with -Package. Ignore this.
  if (pos_tilde > 0) and SameText(copy(APackageName, 1, pos_tilde-1), 'Package') then
    delete(APackageName, 1, pos_tilde);
  APackage.DisplayName := APackageName;
  Packages.Add(APackage);
end;

//Mostly call this from outside
function TPackageGroup.AddPackage(AFullPackageName: string): TPackage;
begin
  Result := TPackage.Create;
  Result.Name := AFullPackageName;
  Self.AddPackage(AFullPackageName, Result);
end;

function TPackageGroup.FindSubgroup(const AGroupName: string): TPackageGroup;
var group: TPackageGroup;
begin
  Result := nil;
  for group in Subgroups do
    if SameText(group.Name, AGroupName) then begin
      Result := group;
      break;
    end;
end;

function TPackageGroup.NeedSubgroup(const AGroupName: string): TPackageGroup;
begin
  Result := FindSubgroup(AGroupName);
  if Result = nil then begin
    Result := TPackageGroup.Create;
    Result.Name := AGroupName;
    Self.Subgroups.Add(Result);
  end;
end;

procedure TPackageGroup.CompactNames;
var group: TPackageGroup;
  subpkg: TPackage;
  i: integer;
begin
  for i := Subgroups.Count-1 downto 0 do begin
    Subgroups[i].CompactNames;
    if (Subgroups[i].Packages.Count=1) and (Subgroups[i].Subgroups.Count=0) then begin
      subpkg := Subgroups[i].Packages[0];
      subpkg.DisplayName := Subgroups[i].Name + '-' + subpkg.DisplayName;
      Self.Packages.Add(subpkg);
      Subgroups[i].Packages.Extract(subpkg);
      Self.Subgroups.Remove(Subgroups[i]);
    end;
  end;

  if (Self.Subgroups.Count = 1) and (Self.Packages.Count = 0) then begin
    group := Self.Subgroups[0];
    Self.Subgroups.Extract(group);
    for i := group.Subgroups.Count-1 downto 0 do begin
      Self.Subgroups.Add(group.Subgroups[i]);
      group.Subgroups.Extract(group.Subgroups[i]);
    end;
    for i := group.Packages.Count-1 downto 0 do begin
      Self.Packages.Add(group.Packages[i]);
      group.Packages.Extract(group.Packages[i]);
    end;
    Self.Name := Self.Name + '-' + group.Name;
    FreeAndNil(group);
  end;
end;


function WildcardMatchCase(a, w: PChar): boolean;
label new_segment, test_match;
var i: integer;
  star: boolean;
begin
new_segment:
  star := false;
  if w^='*' then begin
    star := true;
    repeat Inc(w) until w^ <> '*';
  end;

test_match:
  i := 0;
  while (w[i]<>#00) and (w[i]<>'*') do
    if a[i] <> w[i] then begin
      if a[i]=#00 then begin
        Result := false;
        exit;
      end;
      if (w[i]='?') and (a[i] <> '.') then begin
        Inc(i);
        continue;
      end;
      if not star then begin
        Result := false;
        exit;
      end;
      Inc(a);
      goto test_match;
    end else
      Inc(i);

  if w[i]='*' then begin
    Inc(a, i);
    Inc(w, i);
    goto new_segment;
  end;

  if a[i]=#00 then begin
    Result := true;
    exit;
  end;

  if (i > 0) and (w[i-1]='*') then begin
    Result := true;
    exit;
  end;

  if not star then begin
    Result := false;
    exit;
  end;

  Inc(a);
  goto test_match;
end;

function TPackageGroup.SelectMatching(const AMask: string): TPackageArray;
begin
  SetLength(Result, 0);
  SelectMatching(AMask, Result);
end;

procedure TPackageGroup.SelectMatching(AMask: string; var AArray: TPackageArray);
var i: integer;
begin
  AMask := AMask.ToLower;
  for i := 0 to Packages.Count-1 do
    if WildcardMatchCase(PChar(Packages[i].Name.ToLower), PChar(AMask))
    and not IsPackageInList(AArray, Packages[i]) then begin
      SetLength(AArray, Length(AArray)+1);
      AArray[Length(AArray)-1] := Packages[i];
    end;

  for i := 0 to Subgroups.Count-1 do
    Subgroups[i].SelectMatching(AMask, AArray);
end;



//Sets Visibility parameter for all packages from the list where applicable.
//Preserves old value in DefVis if none yet preserved (like other tools do).
//Skips packages where no changes are needed.
//-1 is a special value meaning "restore to DefVis".
procedure TMainForm.SetCbsVisibility(const AKey: string; APackages: TPackageArray; AVisibility: integer);
var package: TPackage;
  reg: TRegistry;
  curDefVis: integer;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := hkCbsRoot;
    for package in APackages do try
      if (AVisibility >= 0) and (package.CbsVisibility = AVisibility) then
        continue; //nothing to change
      if (AVisibility < 0) and (package.CbsVisibility = package.DefaultCbsVisibility) then
        continue;
      //And there's no point in querying the registry again. Even if someone
      //changed it in the background, just Refresh() and do this again.

      //We want to store DefVis once, and then never touch it because it contains
      //original value, whatever changes happen later
      if not reg.OpenKey(AKey+'\'+Package.Name, false) then exit; //no key, whatever
      try
        curDefVis := reg.ReadInteger('DefVis');
      except
       //Only write if we can't read, no key. Otherwise leave alone
        on E: ERegistryException do begin
         //if there's no key then we set DefaultCbsVisibility to CbsVisibility on load
          reg.WriteInteger('DefVis', package.DefaultCbsVisibility);
          curDefVis := package.DefaultCbsVisibility;
        end;
      end;

      package.DefaultCbsVisibility := curDefVis; //we've read it anyway
      if AVisibility >= 0 then
        package.CbsVisibility := AVisibility
      else
        package.CbsVisibility := package.DefaultCbsVisibility;
      reg.WriteInteger('Visibility', package.CbsVisibility);
      reg.CloseKey;
    except
      on E: ERegistryException do begin
        reg.CloseKey;
        if MessageBox(Self.Handle,
          PChar('Cannot process package '+Package.Name+':'#13+E.Message+'. '
          +'Continue with other packages nevertheless?'),
          PChar('Error'), MB_ICONERROR+MB_YESNO) <> ID_YES then break;
        //else continue, whatever
      end;
    end;

  finally
    FreeAndNil(reg);
  end;
end;

procedure TMainForm.SetCbsVisibility(APackages: TPackageArray; AVisibility: integer);
begin
  SetCbsVisibility(sCbsKey+'\Packages', APackages, AVisibility);
  SetCbsVisibility(sCbsKey+'\PackagesPending', APackages, AVisibility);

  UpdateNodeVisibility(); //update everywhere because it's easier than figuring out who's whose parent and whatnot
  vtPackages.InvalidateChildren(nil, false);
  vtPackages.Repaint;
end;



procedure TMainForm.FormCreate(Sender: TObject);
begin
  FDb := TAssemblyDb.Create;
  FDb.Open(AppFolder+'\assembly.db');
  FResources := TAssemblyResourcesForm.Create(Self);
  FResources.ShowDependencies := true;
  FResources.Db := FDb;
  FResources.ManualDock(tsResources, tsResources, alClient);
  FResources.Align := alClient;
  FResources.Visible := true;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FResources);
  FreeAndNil(FDb);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  Reload;
end;

procedure TMainForm.Reload;
var reg: TRegistry;
  packages: TStringList;
  package: TPackage;
  i: integer;
begin
  FreeAndNil(FPackages);
  FPackages := TPackageGroup.Create;
  FTotalPackages := 0;
  vtPackages.Clear;
  FVisiblePackages := 0; //will be set in first UpdateNodeVisibility

  reg := TRegistry.Create;
  packages := TStringList.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    reg.Access := KEY_READ;
    if not reg.OpenKey(sCbsKey+'\Packages', false) then
      raise Exception.Create(sCannotOpenCbsRegistry);
    reg.GetKeyNames(packages);
    FTotalPackages := packages.Count;
    for i := 0 to packages.Count-1 do begin
      if rbGroupFlat.Checked then begin
        package := TPackage.Create;
        package.Name := packages[i];
        package.DisplayName := packages[i];
        FPackages.Packages.Add(package);
      end else
        package := FPackages.AddPackage(packages[i]);
      reg.CloseKey;
      if not reg.OpenKey(sCbsKey+'\Packages\'+packages[i], false) then
        continue; //because whatever
      try
        package.CbsVisibility := reg.ReadInteger('Visibility');
      except
        on E: ERegistryException do //don't break on each missing property
          package.CbsVisibility := 1; //assume visible
      end;
      try
        package.DefaultCbsVisibility := reg.ReadInteger('DefVis');
      except
        on E: ERegistryException do
          package.DefaultCbsVisibility := package.CbsVisibility; //assume current
      end;
    end;

  finally
    FreeAndNil(reg);
  end;

  if rbGroupDistinctParts.Checked then
    FPackages.CompactNames;

  vtPackages.BeginUpdate;
  try
    ReloadPackageTree(FPackages, nil);
    if rbGroupFlat.Checked then
      vtPackages.TreeOptions.PaintOptions := vtPackages.TreeOptions.PaintOptions - [toShowRoot]
    else
      vtPackages.TreeOptions.PaintOptions := vtPackages.TreeOptions.PaintOptions + [toShowRoot];
  finally
    vtPackages.EndUpdate;
  end;

 //Have to do it again because just setting Node visibility one by one doesn't
 //take care of parent nodes becoming visible as needed when child nodes are
 //visible.
  UpdateNodeVisibility;
end;

procedure TMainForm.UpdateFormCaption;
begin
  Self.Caption := IntToStr(FVisiblePackages) + ' packages ('+IntToStr(FTotalPackages) + ' total)';
end;

procedure TMainForm.ReloadPackageTree(AGroup: TPackageGroup; ATreeNode: PVirtualNode);
var group: TPackageGroup;
  pkg: TPackage;
  node: PVirtualNode;
begin
  for group in AGroup.Subgroups do begin
    node := CreateNode(ATreeNode, group.Name, nil);
    ReloadPackageTree(group, node);
  end;
  for pkg in AGroup.Packages do
    CreateNode(ATreeNode, pkg.DisplayName, pkg);
end;

function TMainForm.CreateNode(AParent: PVirtualNode; ADisplayName: string;
  APackage: TPackage): PVirtualNode;
var AData: PNdPackageData;
begin
  Result := vtPackages.AddChild(AParent);
  vtPackages.ReinitNode(Result, false);
  AData := vtPackages.GetNodeData(Result);
  AData.DisplayName := ADisplayName;
  AData.Package := APackage;
  vtPackages.IsVisible[Result] := IsPackageNodeVisible(Result); //not enough though, see UpdateNodeVisibility
end;

function TMainForm.FindNode(AParent: PVirtualNode; ADisplayName: string): PVirtualNode;
var node: PVirtualNode;
  NodeData: PNdPackageData;
begin
  Result := nil;
  for node in vtPackages.ChildNodes(AParent) do begin
    NodeData := vtPackages.GetNodeData(Node);
    if SameText(NodeData.DisplayName, ADisplayName) then begin
      Result := node;
      break;
    end;
  end;
end;

procedure TMainForm.vtPackagesGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TNdPackageData);
end;

procedure TMainForm.vtPackagesInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var Data: PNdPackageData;
begin
  Data := Sender.GetNodeData(Node);
  Initialize(Data^);
end;

procedure TMainForm.vtPackagesFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var Data: PNdPackageData;
begin
  Data := Sender.GetNodeData(Node);
  Finalize(Data^);
end;

procedure TMainForm.vtPackagesGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var Data: PNdPackageData;
begin
  if TextType <> ttNormal then exit;
  Data := Sender.GetNodeData(Node);
  case Column of
  0, NoColumn:
    CellText := Data.DisplayName;
  end;
end;

procedure TMainForm.vtPackagesPaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var Data: PNdPackageData;
begin
  Data := Sender.GetNodeData(Node);
  if Data.Package <> nil then //is a package
    if Data.Package.CbsVisibility=1 then //visible
      TargetCanvas.Font.Color := clBlue
    else
      TargetCanvas.Font.Color := RGB(135, 153, 255) //light blue
  else
    TargetCanvas.Font.Color := clBlack;
end;

procedure TMainForm.cbShowWOW64Click(Sender: TObject);
begin
  UpdateNodeVisibility();
end;

procedure TMainForm.rbGroupEachPartClick(Sender: TObject);
begin
  Reload;
end;

procedure TMainForm.UpdateNodeVisibility();
begin
 //Big idea with visibility:
 //Leaf nodes (packages) are visible or invisible according to a set of rules -
 //see IsPackageNodeVisible.
 //Group nodes are by default all invisible, but are made visible as required
 //to show all visible leaf nodes.
 //It is therefore hard to update visibility on just one leaf node, as this can
 //potentially change visibility on group nodes up to the top.
  vtPackages.BeginUpdate;
  try
   //Groups have to stay visible when one of their child nodes is visible,
   //thus this complicated 3-step way
    vtPackages.IterateSubtree(nil, ResetVisibility_Callback, nil);
    vtPackages.IterateSubtree(nil, UpdatePackageVisibility_Callback, nil);
    vtPackages.IterateSubtree(nil, ApplyVisibility_Callback, nil);
  finally
    vtPackages.EndUpdate;
  end;

  FVisiblePackages := 0;
  vtPackages.IterateSubtree(nil, CountVisiblePackages_Callback, @FVisiblePackages);
  UpdateFormCaption;
end;

procedure TMainForm.ResetVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Data: Pointer; var Abort: Boolean);
var NodeData: PNdPackageData;
begin
  NodeData := Sender.GetNodeData(Node);
  NodeData.IsVisible := false;
end;

procedure TMainForm.UpdatePackageVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Data: Pointer; var Abort: Boolean);
var NodeData: PNdPackageData;
begin
  NodeData := Sender.GetNodeData(Node);
  if (NodeData.Package <> nil) and IsPackageNodeVisible(Node) then begin //save on re-scanning the parents when nothing changed
    NodeData.IsVisible := True;
    Node := Node.Parent;
    while (Node <> nil) and (Node <> Sender.RootNode) do begin
      NodeData := Sender.GetNodeData(Node);
      if NodeData <> nil then
        NodeData.IsVisible := true;
      Node := Node.Parent;
    end;
  end;
end;

procedure TMainForm.ApplyVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Data: Pointer; var Abort: Boolean);
var NodeData: PNdPackageData;
begin
  NodeData := Sender.GetNodeData(Node);
  Sender.IsVisible[Node] := NodeData.IsVisible;
end;

function TMainForm.IsPackageNodeVisible(ANode: PVirtualNode): boolean;
var NodeData: PNdPackageData;
begin
  NodeData := vtPackages.GetNodeData(ANode);
  Result := true;
  if (not cbShowHidden.Checked) and (NodeData.Package <> nil) and (NodeData.Package.CbsVisibility <> 1) then
    Result := false;
  if (not cbShowWOW64.Checked) and (NodeData.Package <> nil) and SameText(NodeData.Package.Variation, 'WOW64') then
    Result := false;
  if (not cbShowKB.Checked) and NodeData.DisplayName.StartsWith('Package_') then
    Result := false;
  if (edtFilter.Text <> '') and (pos(LowerCase(edtFilter.Text), LowerCase(NodeData.DisplayName))<=0)
  and ((NodeData.Package=nil) or (pos(LowerCase(edtFilter.Text), LowerCase(NodeData.Package.Name))<=0)) then
    Result := false;
end;

procedure TMainForm.CountVisiblePackages_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode; Data: Pointer; var Abort: Boolean);
var NodeData: PNdPackageData;
begin
  NodeData := Sender.GetNodeData(Node);
  if (NodeData.Package <> nil) and Sender.IsVisible[Node] then
    Inc(PInteger(Data)^);
end;


//Returns a list of all Packages in the tree
function TMainForm.GetAllPackages: TPackageArray;
begin
  SetLength(Result, 0);
  vtPackages.IterateSubtree(nil, GetPackages_Callback, @Result)
end;

//Returns a list of all Packages in all selected nodes and its subnodes
function TMainForm.GetSelectedPackages: TPackageArray;
var node: PVirtualNode;
begin
  SetLength(Result, 0);
  for node in vtPackages.SelectedNodes() do
    vtPackages.IterateSubtree(node, GetPackages_Callback, @Result, [vsVisible]);
end;

//Returns a list of all Packages in this node and its children
function TMainForm.GetChildPackages(ANode: PVirtualNode): TPackageArray;
begin
  SetLength(Result, 0);
  vtPackages.IterateSubtree(ANode, GetPackages_Callback, @Result, [vsVisible])
end;

procedure TMainForm.GetPackages_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Data: Pointer; var Abort: Boolean);
var List: PPackageArray absolute Data;
  NodeData: PNdPackageData;
begin
  NodeData := Sender.GetNodeData(Node);
  if NodeData.Package <> nil then begin
   //This is required if we allow multiselect on different levels
   //Both parent and one of its children can be selected independently => doubles
    if IsPackageInList(List^, NodeData.Package) then
      exit;
    SetLength(List^, Length(List^)+1);
    List^[Length(List^)-1] := NodeData.Package;
  end;
end;

//Returns a list of package names for all Packages in all selected nodes and its subnodes
function TMainForm.GetSelectedPackageNames: TStringArray;
begin
  Result := PackagesToPackageNames(GetSelectedPackages());
end;

//Returns a list of package names for all Packages in this node and its children
function TMainForm.GetChildPackageNames(ANode: PVirtualNode): TStringArray;
begin
  Result := PackagesToPackageNames(GetChildPackages(ANode));
end;


//Saves a list of package names into a file of user choosing
procedure TMainForm.SavePackageList(APackageNames: TStringArray);
var sl: TStringList;
  item: string;
begin
  if not PackageListSaveDialog.Execute then exit;

  TArray.Sort<string>(APackageNames);

  sl := TStringList.Create;
  try
    for item in APackageNames do
      sl.Add(item);
    sl.SaveToFile(PackageListSaveDialog.Filename);
  finally
    FreeAndNil(sl);
  end;
end;

procedure TMainForm.pmSavePackageListClick(Sender: TObject);
begin
  SavePackageList(PackagesToPackageNames(GetAllPackages()));
end;


procedure TMainForm.PopupMenuPopup(Sender: TObject);
var Packages: TPackageArray;
  HaveVisible, HaveInvisible: boolean;
  HaveVisibilityChanged: boolean;
  i: integer;
begin
  Packages := GetSelectedPackages();
  pmCopyPackageNames.Visible := Length(Packages)>=1;
  pmCopyUninstallationCommands.Visible := Length(Packages)>=1;
  pmUninstall.Visible := Length(Packages)=1;
  pmUninstallAll.Visible := Length(Packages)>1;

  HaveVisible := false;
  HaveInvisible := false;
  HaveVisibilityChanged := false;
  for i := 0 to Length(Packages)-1 do begin
    if Packages[i].CbsVisibility=1 then
      HaveVisible := true
    else
      HaveInvisible := true;
    if Packages[i].DefaultCbsVisibility <> Packages[i].CbsVisibility then
      HaveVisibilityChanged := true;
  end;
  pmMakeVisible.Visible := HaveInvisible;
  pmMakeInvisible.Visible := HaveVisible;
  pmRestoreDefaultVisibility.Visible := HaveVisibilityChanged;
  pmVisibility.Visible := pmMakeVisible.Visible or pmMakeInvisible.Visible
    or pmRestoreDefaultVisibility.Visible;
end;

procedure TMainForm.pmReloadClick(Sender: TObject);
begin
  Reload;
end;

procedure TMainForm.pmCopyPackageNamesClick(Sender: TObject);
var PackageNames: TStringArray;
begin
  PackageNames := GetSelectedPackageNames();
  if Length(PackageNames) <= 0 then exit;
  Clipboard.SetTextBuf(PChar(SepJoin(PackageNames, #13)));
end;

procedure TMainForm.DismUninstall(const APackageName: string);
var ANames: TStringArray;
begin
  SetLength(ANames, 1);
  ANames[0] := APackageName;
  DismUninstall(ANames);
end;

procedure TMainForm.DismUninstall(const APackageNames: TStringArray);
var processInfo: TProcessInformation;
  err: cardinal;
  APackageNamesStr: string;
  AName: string;
begin
  APackageNamesStr := '';
  for AName in APackageNames do
    APackageNamesStr := APackageNamesStr + ' /Packagename='+AName;
  processInfo := StartProcess(GetSystemDir()+'\dism.exe',
    PChar('dism.exe /Online /Remove-Package '+APackageNamesStr));
  try
    WaitForSingleObject(processInfo.hProcess, INFINITE);
    if not GetExitCodeProcess(processInfo.hProcess, err) then
      RaiseLastOsError;
    case err of
      0: begin end; // OK
      ERROR_SUCCESS_REBOOT_REQUIRED: begin end;
      CBS_E_INVALID_PACKAGE:
        MessageBox(Self.Handle, PChar('Uninstall says there''s no such package. Perhaps refresh? '+
          'Or maybe you have forgotten to make packages visible. This also sometimes happens when the '+
          'package is marked for deletion until reboot.'),
          PChar('Uninstall failed'), MB_ICONERROR);
    else
      MessageBox(Self.Handle, PChar('Uninstall seems to have failed with error code '+IntToStr(err)),
        PChar('Uninstall failed'), MB_ICONERROR);
    end;

  finally
    CloseHandle(processInfo.hProcess);
    CloseHandle(processInfo.hThread);
  end;
end;

procedure TMainForm.pmUninstallAllClick(Sender: TObject);
var PackageNames: TStringArray;
  AConfirmationText: string;
begin
  PackageNames := GetSelectedPackageNames();
  if Length(PackageNames) <= 0 then exit;

  //Sort the array in reverse, so that packages with ~EN_us suffixes are deleted earlier (otherwise they get dependency-deleted first)
  //Ideally we should just check dependencies and skip stuff already in it
  TArray.Sort<string>(PackageNames, TDelegatedComparer<string>.Construct(
    function(const Left, Right: string): Integer
    begin
      Result := CompareText(Left, Right);
    end));

  if Length(PackageNames) = 1 then
    AConfirmationText := 'Do you really want to uninstall'#13
    +PackageNames[0]+'?'+#13
    +'After uninstalling, it will be impossible to install again without repairing Windows.'
  else
    AConfirmationText := 'Do you really want to uninstall '+IntToStr(Length(PackageNames))+' packages?'#13
    +SepJoin(PackageNames, #13)+#13
    +'After uninstalling, it will be impossible to install again without repairing Windows.';

  if MessageBox(Self.Handle, PChar(AConfirmationText),
    PChar('Confirm uninstall'),  MB_ICONWARNING or MB_YESNO) <> ID_YES then
    exit;

  DismUninstall(PackageNames);
  Reload;
end;

procedure TMainForm.pmCopyUninstallationCommandsClick(Sender: TObject);
var PackageNames: TStringArray;
  AText, APackageName: string;
begin
  PackageNames := GetSelectedPackageNames();
  if Length(PackageNames) <= 0 then exit;

  AText := 'dism.exe /Online /Remove-Package';
  for APackageName in PackageNames do
    AText := AText + ' /PackageName='+APackageName;

  Clipboard.SetTextBuf(PChar(AText));
end;

procedure TMainForm.Saveselectedpackagelist1Click(Sender: TObject);
var PackageNames: TStringArray;
begin
  PackageNames := GetSelectedPackageNames();
  if Length(PackageNames) <= 0 then exit;

  SavePackageList(PackageNames);
end;

procedure TMainForm.pmTakeRegistryOwnershipClick(Sender: TObject);
begin
  JobProcessorForm.Caption := 'Taking ownership...';
  JobProcessorForm.Show();
  JobProcessorForm.Process(TTakeOwnershipJob.Create())
end;

procedure TMainForm.pmDecoupleAllPackagesClick(Sender: TObject);
begin
  JobProcessorForm.Caption := 'Decoupling...';
  JobProcessorForm.Show();
  JobProcessorForm.Process(TDecouplePackagesJob.Create(nil))
end;

procedure TMainForm.pmDecouplePackagesClick(Sender: TObject);
var packages: TStringArray;
begin
  packages := GetSelectedPackageNames();
  if Length(packages) <= 0 then exit; //because that would mean "Decouple all"
  JobProcessorForm.Caption := 'Decoupling...';
  JobProcessorForm.Show();
  JobProcessorForm.Process(TDecouplePackagesJob.Create(packages))
end;

procedure TMainForm.pmMakeVisibleClick(Sender: TObject);
begin
  SetCbsVisibility(GetSelectedPackages(), 1);
end;

procedure TMainForm.pmMakeInvisibleClick(Sender: TObject);
begin
  SetCbsVisibility(GetSelectedPackages(), 2);
end;

procedure TMainForm.pmRestoreDefaultVisibilityClick(Sender: TObject);
begin
  SetCbsVisibility(GetSelectedPackages(), -1);
end;

procedure TMainForm.pmMakeAllVisibileClick(Sender: TObject);
begin
  SetCbsVisibility(GetAllPackages(), 1);
end;

procedure TMainForm.pmMakeAllInvisibleClick(Sender: TObject);
begin
  SetCbsVisibility(GetAllPackages(), 2);
end;

procedure TMainForm.pmRestoreDefaltVisibilityAllClick(Sender: TObject);
begin
  SetCbsVisibility(GetAllPackages(), -1);
end;


procedure TMainForm.edtFilterChange(Sender: TObject);
begin
  UpdateNodeVisibility;
end;

procedure TMainForm.edtFilterKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    TEdit(Sender).Text := '';
end;

procedure TMainForm.vtPackagesFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
begin
  if Assigned(pcPageInfo.ActivePage.OnEnter) then
    pcPageInfo.ActivePage.OnEnter(pcPageInfo.ActivePage);
end;

procedure TMainForm.tsInfoEnter(Sender: TObject);
var xml: IXmlDocument;
  NodeData: PNdPackageData;
  assembly, package, node: IXmlNode;
  assemblyName: string;
  copyright: string;
  i: integer;
begin
  lblDescription.Caption := '';
  lbUpdates.Items.Clear;

  NodeData := vtPackages.GetNodeData(vtPackages.FocusedNode);
  if (NodeData = nil) or (NodeData.Package = nil) then
    exit;

  xml := TXmlDocument.Create(GetWindowsDir()+'\servicing\Packages\'+NodeData.Package.Name+'.mum');
  try
    assembly := xml.ChildNodes['assembly'];
    if assembly = nil then exit;
    package := assembly.ChildNodes['package'];

    assemblyName := '';
    if assembly.HasAttribute('name') then
      assemblyName := assemblyName + assembly.Attributes['name']+#13;
    if assembly.HasAttribute('description') then
      assemblyName := assemblyName + assembly.Attributes['description']+#13;
    if (assemblyName='') and (package <> nil) then begin
      if package.HasAttribute('name') then
        assemblyName := assemblyName + package.Attributes['name']+#13;
      if package.HasAttribute('description') then
        assemblyName := assemblyName + package.Attributes['description']+#13;
    end;
   //If nothing else, use registry package name
    if assemblyName='' then
      if (package <> nil) and (package.HasAttribute('identifier')) then
        lblDescription.Caption := package.Attributes['identifier']
      else
        lblDescription.Caption := NodeData.Package.Name;

    copyright := '';
    if assembly.HasAttribute('copyright') then
      copyright := copyright + assembly.Attributes['copyright'];
    if (copyright = '') and (package <> nil) then begin
      if package.HasAttribute('copyright') then
        copyright := copyright + package.Attributes['copyright'];
    end;

    lblDescription.Caption := assemblyName;
    if copyright <> '' then
      lblDescription.Caption := lblDescription.Caption + #13 + copyright;

    if package <> nil then
      for i := 0 to package.ChildNodes.Count-1 do begin
        node := package.ChildNodes[i];
        if node.NodeName='update' then begin
          assemblyName := '';
          if node.HasAttribute('displayName') then
            assemblyName := assemblyName + node.Attributes['displayName'] + ' ';
          if node.HasAttribute('description') then
            assemblyName := assemblyName + node.Attributes['description'] + ' ';
          if assemblyName = '' then
            assemblyName := node.Attributes['name'];
          lbUpdates.Items.Add(assemblyName);
        end;
      end;

  finally
    xml := nil;
  end;
end;


function textAttribute(const ANode: IXmlNode; const AAttribName: string): string;
begin
  if ANode.HasAttribute(AAttribName) then
    Result := ANode.attributes[AAttribName]
  else
    Result := '';
end;

//Parses a given assemblyIdentity node, extracting all the fields that identify an assembly
function XmlReadAssemblyIdentityData(const ANode: IXmlNode): TAssemblyIdentity;
begin
  Result.name := textAttribute(ANode, 'name');
  Result.type_ := textAttribute(ANode, 'type');
  Result.language := textAttribute(ANode, 'language');
  Result.buildType := textAttribute(ANode, 'buildType');
  Result.processorArchitecture := textAttribute(ANode, 'processorArchitecture');
  Result.version := textAttribute(ANode, 'version');
  Result.publicKeyToken := textAttribute(ANode, 'publicKeyToken');
  Result.versionScope := textAttribute(ANode, 'versionScope');
end;


type
  TXmlNodeList = array of IXmlNode;

function ListPackageAssemblies(xml: IXmlDocument): TXmlNodeList; overload;
var assembly, package, update, component, node: IXmlNode;
  i, j: integer;
begin
  SetLength(Result, 0);

  assembly := xml.ChildNodes['assembly'];
  if assembly = nil then exit;
  package := assembly.ChildNodes['package'];
  if package = nil then exit;

  for i := 0 to package.ChildNodes.Count-1 do begin
    update := package.ChildNodes[i];
    if update.NodeName <> 'update' then continue;

    for j := 0 to update.ChildNodes.Count-1 do begin
      component := update.ChildNodes[j];
      if component.NodeName <> 'component' then continue;

      node := component.ChildNodes.FindNode('assemblyIdentity');
      if node = nil then continue; //that component wasn't assembly. huh.

      SetLength(Result, Length(Result)+1);
      Result[Length(Result)-1] := node;
    end;
  end;
end;


procedure Log(const msg: string);
begin
  MessageBox(0, PChar(msg), PChar('Log'), 0);
end;

procedure TMainForm.tsResourcesEnter(Sender: TObject);
var xml: IXmlDocument;
  NodeData: PNdPackageData;
  node: IXmlNode;
  assemblyData: TAssemblyIdentity;
  assemblyId: TAssemblyId;
begin
  FResources.Assemblies.Clear;
  NodeData := vtPackages.GetNodeData(vtPackages.FocusedNode);
  if (NodeData = nil) or (NodeData.Package = nil) then
    exit;

  xml := TXmlDocument.Create(GetWindowsDir()+'\servicing\Packages\'+NodeData.Package.Name+'.mum');
  try
    for node in ListPackageAssemblies(xml) do begin
      assemblyData := XmlReadAssemblyIdentityData(node);
      assemblyId := FDb.Assemblies.NeedAssembly(assemblyData);
      FResources.Assemblies.Add(assemblyId);
    end;
  finally
    xml := nil;
  end;
  FResources.Reload;
end;


procedure TMainForm.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.pmOpenCBSRegistryClick(Sender: TObject);
begin
  RegeditOpenAndNavigate('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\'
    +'CurrentVersion\Component Based Servicing');
end;

procedure TMainForm.Diskcleanup1Click(Sender: TObject);
begin
  StartProcess(GetSystemDir()+'\cleanmgr.exe', 'cleanmgr.exe');
end;

procedure TMainForm.Optionalfeatures1Click(Sender: TObject);
begin
  StartProcess(GetSystemDir()+'\OptionalFeatures.exe', 'OptionalFeatures.exe');
end;

procedure TMainForm.DismCleanup1Click(Sender: TObject);
begin
  StartProcess(GetSystemDir()+'\dism.exe',
    PChar('dism.exe /Online /Cleanup-Image /StartComponentCleanup'));
end;

procedure TMainForm.pmUninstallByListClick(Sender: TObject);
var lines: TStringList;
  line: string;
  i, i_pos: integer;
  packages: TPackageArray;
  packageNames: TStringArray;
begin
  if not UninstallListOpenDialog.Execute then
    exit;

  SetLength(packages, 0);

  lines := TStringList.Create;
  try
    lines.LoadFromFile(UninstallListOpenDialog.FileName);

    for i := 0 to lines.Count-1 do begin
      line := Trim(lines[i]);
      if line = '' then continue;
      if line.StartsWith('//') then continue;

      // #-style comments are also supported at the end of the line
      i_pos := pos('#', line);
      if i_pos > 0 then begin
        line := Trim(copy(line, 1, i_pos-1));
        if line = '' then continue;
      end;

      FPackages.SelectMatching(line, packages);
    end;
  finally
    FreeAndNil(lines);
  end;

  packageNames := PackagesToPackageNames(packages);

  if Length(packageNames) <= 0 then begin
    MessageBox(Self.Handle, PChar('Nothing to remove.'), PChar('Uninstall by list'), MB_ICONINFORMATION + MB_OK);
    exit;
  end else
    if MessageBox(Self.Handle, PChar(IntToStr(Length(packageNames))+' packages is going to be removed. Do you really want to do this?'),
      PChar('Confirm removal'), MB_ICONQUESTION + MB_YESNO) <> ID_YES then
      exit;

  DismUninstall(packageNames);
  Reload;
end;

procedure TMainForm.Rebuildassemblydatabase1Click(Sender: TObject);
begin
  RebuildAssemblyDatabase(FDb, AppFolder+'\assembly.db');
end;

end.
