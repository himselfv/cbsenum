unit CBSEnum_Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, VirtualTrees, UniStrUtils, Menus, StdCtrls, ExtCtrls,
  Generics.Collections, Vcl.ImgList, Vcl.ComCtrls;

type
  TPackageData = record
    Name: string; //full package name
    DisplayName: string; //display name
    IsVisible: boolean;
  end;
  PPackageData = ^TPackageData;

  TPackageGroup = class
  protected
    Name: string;
    Subgroups: TObjectList<TPackageGroup>;
    Packages: array of TPackageData;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddPackage(const APackageData: TPackageData); overload;
    function AddPackage(APackageName: string; AFullPackageName: string): PPackageData; overload;
    function FindSubgroup(const AGroupName: string): TPackageGroup;
    function NeedSubgroup(const AGroupName: string): TPackageGroup;
    procedure CompactNames;
  end;

  TMainForm = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    cbShowWOW64: TCheckBox;
    PopupMenu: TPopupMenu;
    cbShowLang: TCheckBox;
    cbShowKb: TCheckBox;
    pmUninstall: TMenuItem;
    N1: TMenuItem;
    pmReload: TMenuItem;
    Label2: TLabel;
    Panel2: TPanel;
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
    tsFiles: TTabSheet;
    lblDescription: TLabel;
    lbUpdates: TListBox;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Service1: TMenuItem;
    Diskcleanup1: TMenuItem;
    Exit1: TMenuItem;
    Optionalfeatures1: TMenuItem;
    pmCopyUninstallationCommands: TMenuItem;
    pmOpenCBSRegistry: TMenuItem;
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
  protected
    FPackages: TPackageGroup;
    procedure ReloadPackageTree(AGroup: TPackageGroup; ATreeNode: PVirtualNode);
    function SplitPackageName(AName: string): TStringArray;
    function CreateNode(AParts: TStringArray; APackageName: string): PVirtualNode; overload;
    function CreateNode(AParent: PVirtualNode; ADisplayName, APackageName: string): PVirtualNode; overload;
    function FindNode(AParent: PVirtualNode; ADisplayName: string): PVirtualNode;
    procedure UpdateNodeVisibility(AParent: PVirtualNode = nil);
    procedure ResetVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Data: Pointer; var Abort: Boolean);
    procedure UpdatePackageVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Data: Pointer; var Abort: Boolean);
    procedure ApplyVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Data: Pointer; var Abort: Boolean);
    function IsPackageVisible(ANode: PVirtualNode): boolean;
    function GetChildPackageNames(ANode: PVirtualNode): TStringArray;
    procedure GetChildPackageNames_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Data: Pointer; var Abort: Boolean);
    procedure DismUninstall(const APackageName: string); overload;
    procedure DismUninstall(const APackageNames: TStringArray); overload;
  public
    procedure Reload;
  end;

var
  MainForm: TMainForm;

implementation
uses Registry, Clipbrd, XmlDoc, XmlIntf;

{$R *.dfm}


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
    if not reg.OpenKey('Software', true)
    or not reg.OpenKey('Microsoft', true)
    or not reg.OpenKey('Windows', true)
    or not reg.OpenKey('CurrentVersion', true)
    or not reg.OpenKey('Applets', true)
    or not reg.OpenKey('Regedit', true) then
      raise Exception.Create('Cannot point regedit at a key.');
    reg.WriteString('LastKey', ARegistryPath);
  finally
    FreeAndNil(reg);
  end;
  StartProcess(GetWindowsDir()+'\regedit.exe', 'regedit.exe');
end;


constructor TPackageGroup.Create;
begin
  inherited;
  Subgroups := TObjectList<TPackageGroup>.Create;
end;

destructor TPackageGroup.Destroy;
begin
  FreeAndNil(Subgroups);
  inherited;
end;

procedure TPackageGroup.AddPackage(const APackageData: TPackageData);
begin
  SetLength(Packages, Length(Packages)+1);
  Packages[Length(Packages)-1] := APackageData;
end;

function TPackageGroup.AddPackage(APackageName: string; AFullPackageName: string): PPackageData;
var pos_minus, pos_tilde: integer;
  AGroupName: string;
  AGroup: TPackageGroup;
  APackage: TPackageData;
begin
 //Eat one part of the name. Mind names like Microsoft-Windows-Defender~ru-RU (note last minus)
  pos_tilde := pos('~', APackageName);
  pos_minus := pos('-', APackageName);
  if (pos_minus > 0) and ((pos_tilde < 0) or (pos_minus < pos_tilde)) then begin
    AGroupName := copy(APackageName, 1, pos_minus-1);
    delete(APackageName, 1, pos_minus);
    AGroup := Self.NeedSubgroup(AGroupName);
    Result := AGroup.AddPackage(APackageName, AFullPackageName);
  end else begin
   //Most package names end with -Package. Ignore this.
    if (pos_tilde > 0) and SameText(copy(APackageName, 1, pos_tilde-1), 'Package') then
      delete(APackageName, 1, pos_tilde);
    APackage.Name := AFullPackageName;
    APackage.DisplayName := APackageName;
    AddPackage(APackage);
    Result := nil; //because whatever
  end;
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
  subpkg: TPackageData;
  i: integer;
begin
  for i := Subgroups.Count-1 downto 0 do begin
    Subgroups[i].CompactNames;
    if (Length(Subgroups[i].Packages)=1) and (Subgroups[i].Subgroups.Count=0) then begin
      subpkg := Subgroups[i].Packages[0];
      subpkg.DisplayName := Subgroups[i].Name + '-' + subpkg.DisplayName;
      Self.AddPackage(subpkg);
      Self.Subgroups.Remove(Subgroups[i]);
    end;
  end;

  if (Self.Subgroups.Count = 1) and (Length(Self.Packages) = 0) then begin
    group := Self.Subgroups[0];
    Self.Subgroups.Extract(group);
    for i := group.Subgroups.Count-1 downto 0 do begin
      Self.Subgroups.Add(group.Subgroups[i]);
      group.Subgroups.Extract(group.Subgroups[i]);
    end;
    for subpkg in group.Packages do
      Self.AddPackage(subpkg);
    Self.Name := Self.Name + '-' + group.Name;
    FreeAndNil(group);
  end;
end;


procedure TMainForm.FormShow(Sender: TObject);
begin
  Reload;
end;

procedure TMainForm.Reload;
var reg: TRegistry;
  packages: TStringList;
  i: integer;
begin
  FreeAndNil(FPackages);
  FPackages := TPackageGroup.Create;
  vtPackages.Clear;

  reg := TRegistry.Create;
  packages := TStringList.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if not reg.OpenKey('Software', true)
    or not reg.OpenKey('Microsoft', true)
    or not reg.OpenKey('Windows', true)
    or not reg.OpenKey('CurrentVersion', true)
    or not reg.OpenKey('Component Based Servicing', false)
    or not reg.OpenKey('Packages', false) then
      raise Exception.Create('Cannot open registry key for packages. Perpahs '
      +'you''re not running the app with administrator rights? Or the Windows '
      +'version is incompatible.');
    reg.GetKeyNames(packages);
    for i := 0 to packages.Count-1 do begin
      FPackages.AddPackage(packages[i], packages[i]);
    end;

    if rbGroupDistinctParts.Checked then
      FPackages.CompactNames;
    ReloadPackageTree(FPackages, nil);
  finally
    FreeAndNil(reg);
  end;

 //Have to do it again because just setting Node visibility one by one doesn't
 //take care of parent nodes becoming visible as needed when child nodes are
 //visible.
  UpdateNodeVisibility;
end;

procedure TMainForm.ReloadPackageTree(AGroup: TPackageGroup; ATreeNode: PVirtualNode);
var group: TPackageGroup;
  pkg: TPackageData;
  node: PVirtualNode;
begin
  for group in AGroup.Subgroups do begin
    node := CreateNode(ATreeNode, group.Name, '');
    ReloadPackageTree(group, node);
  end;
  for pkg in AGroup.Packages do
    CreateNode(ATreeNode, pkg.DisplayName, pkg.Name);
end;


//Возвращает путь из нод, в которых должен находиться пакет. Последний элемент
//это видимое имя самого пакета
function TMainForm.SplitPackageName(AName: string): TStringArray;
var parts: TStringArray;
  pos_tilde: integer;
begin
 //Удаляем из конца номер версии и имя языка
  pos_tilde := pos('~', AName);
  if pos_tilde > 0 then
    delete(AName, pos_tilde, MaxInt);

  parts := StrSplit(PChar(AName), '-');
  Assert(Length(parts)>=1);

 //Отбрасываем Package в конце
  if SameText(parts[Length(parts)-1], 'Package') then begin
    SetLength(parts, Length(parts)-1);
    Assert(Length(parts)>=1);
  end;

  Result := parts;

 //TODO:
 //1. Разбиение только для начинающихся с некоторых слов/наборов слов (CoreMessaging, Microsoft-Windows и т.п.)
 //2. Для всех остальных отделить только WOW64 в конце, этот всегда в подраздел
end;

function TMainForm.CreateNode(AParts: TStringArray; APackageName: string): PVirtualNode;
var AParent, ANewParent: PVirtualNode;
  i: integer;
  AData: PPackageData;
begin
  AParent := nil;
  i := 0;
  while i<Length(AParts) do begin
    ANewParent := FindNode(AParent, AParts[i]);
    if ANewParent <> nil then
      AParent := ANewParent
    else
      AParent := CreateNode(AParent, AParts[i], '');
    Inc(i);
  end;
  //Last node was package node
  AData := vtPackages.GetNodeData(AParent);

  //It could be that it already existed as packages with various ~EN_gb converge to one.
  //It could also be that the node existed but was not assigned a package, as it was
  //created while inserting a child package with -WOW64
  if AData.Name = '' then
    AData.Name := APackageName
  else
  //It could also be that we registered ~EN_gb version as a package name first,
  //so shorten the name when possible
  if Length(AData.Name) > Length(APackageName) then
    AData.Name := APackageName;
  Result := AParent;
end;

function TMainForm.CreateNode(AParent: PVirtualNode; ADisplayName, APackageName: string): PVirtualNode;
var AData: PPackageData;
begin
  Result := vtPackages.AddChild(AParent);
  vtPackages.ReinitNode(Result, false);
  AData := vtPackages.GetNodeData(Result);
  AData.Name := APackageName;
  AData.DisplayName := ADisplayName;
  vtPackages.IsVisible[Result] := IsPackageVisible(Result);
end;

function TMainForm.FindNode(AParent: PVirtualNode; ADisplayName: string): PVirtualNode;
var node: PVirtualNode;
  NodeData: PPackageData;
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
  NodeDataSize := SizeOf(TPackageData);
end;

procedure TMainForm.vtPackagesInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var Data: PPackageData;
begin
  Data := Sender.GetNodeData(Node);
  Initialize(Data^);
end;

procedure TMainForm.vtPackagesFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var Data: PPackageData;
begin
  Data := Sender.GetNodeData(Node);
  Finalize(Data^);
end;

procedure TMainForm.vtPackagesGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var Data: PPackageData;
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
var Data: PPackageData;
begin
  Data := Sender.GetNodeData(Node);
  if Data.Name <> '' then //has own package
    TargetCanvas.Font.Color := clBlue
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

procedure TMainForm.UpdateNodeVisibility(AParent: PVirtualNode = nil);
begin
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
end;

procedure TMainForm.ResetVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Data: Pointer; var Abort: Boolean);
var NodeData: PPackageData;
begin
  NodeData := Sender.GetNodeData(Node);
  NodeData.IsVisible := false;
end;

procedure TMainForm.UpdatePackageVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Data: Pointer; var Abort: Boolean);
var NodeData: PPackageData;
begin
  NodeData := Sender.GetNodeData(Node);
  if IsPackageVisible(Node) then begin //save on re-scanning the parents when nothing changed
    NodeData.IsVisible := True;
    Node := Node.Parent;
    while Node <> nil do begin
      NodeData := Sender.GetNodeData(Node);
      if (NodeData <> nil) and (cbShowWOW64.Checked or not SameText(NodeData.DisplayName, 'WOW64')) then
        NodeData.IsVisible := true;
      Node := Node.Parent;
    end;
  end;
end;

procedure TMainForm.ApplyVisibility_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Data: Pointer; var Abort: Boolean);
var NodeData: PPackageData;
begin
  NodeData := Sender.GetNodeData(Node);
  Sender.IsVisible[Node] := NodeData.IsVisible;
end;

function TMainForm.IsPackageVisible(ANode: PVirtualNode): boolean;
var NodeData: PPackageData;
begin
  NodeData := vtPackages.GetNodeData(ANode);
  Result := true;
  if (not cbShowWOW64.Checked) and SameText(NodeData.DisplayName, 'WOW64') then
    Result := false;
  if (not cbShowKB.Checked) and NodeData.DisplayName.StartsWith('Package_') then
    Result := false;
  if (edtFilter.Text <> '') and (pos(LowerCase(edtFilter.Text), LowerCase(NodeData.DisplayName))<=0) then
    Result := false;
end;

function TMainForm.GetChildPackageNames(ANode: PVirtualNode): TStringArray;
begin
  vtPackages.IterateSubtree(ANode, GetChildPackageNames_Callback, @Result)
end;

procedure TMainForm.GetChildPackageNames_Callback(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Data: Pointer; var Abort: Boolean);
var NodeData: PPackageData;
begin
  NodeData := Sender.GetNodeData(Node);
  if NodeData.Name <> '' then begin
    SetLength(PStringArray(Data)^, Length(PStringArray(Data)^)+1);
    PStringArray(Data)^[Length(PStringArray(Data)^)-1] := NodeData.Name;
  end;
end;

procedure TMainForm.PopupMenuPopup(Sender: TObject);
var AData: PPackageData;
begin
  if vtPackages.FocusedNode = nil then
    AData := nil
  else
    AData := vtPackages.GetNodeData(vtPackages.FocusedNode);
  pmUninstall.Visible := (AData <> nil) and (AData.Name <> '');
end;

procedure TMainForm.pmReloadClick(Sender: TObject);
begin
  Reload;
end;

procedure TMainForm.pmCopyPackageNamesClick(Sender: TObject);
var PackageNames: TStringArray;
begin
  if vtPackages.FocusedNode = nil then exit;
  PackageNames := GetChildPackageNames(vtPackages.FocusedNode);
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
    if (err <> 0) and (err <> 3010 {"have to restart PC later"}) then
      MessageBox(Self.Handle, PChar('Uninstall seems to have failed with error code '+IntToStr(err)),
      PChar('Uninstall failed'), MB_ICONERROR);
  finally
    CloseHandle(processInfo.hProcess);
    CloseHandle(processInfo.hThread);
  end;
end;

procedure TMainForm.pmUninstallAllClick(Sender: TObject);
var PackageNames: TStringArray;
  AConfirmationText: string;
begin
  if vtPackages.FocusedNode = nil then
    exit;

  PackageNames := GetChildPackageNames(vtPackages.FocusedNode);
  if Length(PackageNames) <= 0 then exit;

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
  if vtPackages.FocusedNode = nil then
    exit;

  PackageNames := GetChildPackageNames(vtPackages.FocusedNode);
  if Length(PackageNames) <= 0 then exit;

  AText := 'dism.exe /Online /Remove-Package';
  for APackageName in PackageNames do
    AText := AText + ' /PackageName='+APackageName;

  Clipboard.SetTextBuf(PChar(AText));
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
  NodeData: PPackageData;
  assembly, package, node: IXmlNode;
  assemblyName: string;
  copyright: string;
  i: integer;
begin
  lblDescription.Caption := '';
  lbUpdates.Items.Clear;

  NodeData := vtPackages.GetNodeData(vtPackages.FocusedNode);
  if (NodeData = nil) or (NodeData.Name = '') then
    exit;

  xml := TXmlDocument.Create(GetWindowsDir()+'\servicing\Packages\'+NodeData.Name+'.mum');
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
        lblDescription.Caption := NodeData.Name;

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

end.
