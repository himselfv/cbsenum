object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Packages'
  ClientHeight = 578
  ClientWidth = 686
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 501
    Top = 0
    Width = 185
    Height = 360
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      185
      360)
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 30
      Height = 13
      Caption = 'Show:'
    end
    object Label2: TLabel
      Left = 6
      Top = 104
      Width = 33
      Height = 13
      Caption = 'Group:'
    end
    object cbShowWOW64: TCheckBox
      Left = 6
      Top = 27
      Width = 171
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'WOW64 versions'
      TabOrder = 0
      OnClick = cbShowWOW64Click
    end
    object cbShowLang: TCheckBox
      Left = 6
      Top = 50
      Width = 171
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Language variations'
      TabOrder = 1
      OnClick = cbShowWOW64Click
    end
    object cbShowKb: TCheckBox
      Left = 6
      Top = 73
      Width = 171
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = 'KB updates'
      TabOrder = 2
      OnClick = cbShowWOW64Click
    end
    object pnlGroupMode: TPanel
      Left = 0
      Top = 123
      Width = 185
      Height = 62
      Anchors = [akLeft, akTop, akRight]
      BevelOuter = bvNone
      TabOrder = 3
      DesignSize = (
        185
        62)
      object rbGroupEachPart: TRadioButton
        Left = 6
        Top = 0
        Width = 171
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'By each part of the name'
        TabOrder = 0
        OnClick = rbGroupEachPartClick
      end
      object rbGroupDistinctParts: TRadioButton
        Left = 6
        Top = 23
        Width = 171
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'By distinct parts'
        Checked = True
        TabOrder = 1
        TabStop = True
        OnClick = rbGroupEachPartClick
      end
      object rbGroupFlat: TRadioButton
        Left = 6
        Top = 46
        Width = 171
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Flat list'
        TabOrder = 2
        OnClick = rbGroupEachPartClick
      end
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 501
    Height = 360
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object vtPackages: TVirtualStringTree
      Left = 0
      Top = 24
      Width = 501
      Height = 336
      Align = alClient
      Header.AutoSizeIndex = 0
      Header.Font.Charset = DEFAULT_CHARSET
      Header.Font.Color = clWindowText
      Header.Font.Height = -11
      Header.Font.Name = 'Tahoma'
      Header.Font.Style = []
      Header.MainColumn = -1
      PopupMenu = PopupMenu
      TabOrder = 0
      TreeOptions.MiscOptions = [toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
      TreeOptions.PaintOptions = [toHideFocusRect, toShowButtons, toShowDropmark, toShowRoot, toShowTreeLines, toThemeAware, toUseBlendedImages]
      TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect, toRightClickSelect]
      OnFocusChanged = vtPackagesFocusChanged
      OnFreeNode = vtPackagesFreeNode
      OnGetText = vtPackagesGetText
      OnPaintText = vtPackagesPaintText
      OnGetNodeDataSize = vtPackagesGetNodeDataSize
      OnInitNode = vtPackagesInitNode
      Columns = <>
    end
    object edtFilter: TEdit
      Left = 0
      Top = 0
      Width = 501
      Height = 24
      Align = alTop
      BevelInner = bvNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnChange = edtFilterChange
      OnKeyDown = edtFilterKeyDown
    end
  end
  object pcPageInfo: TPageControl
    Left = 0
    Top = 360
    Width = 686
    Height = 218
    ActivePage = tsInfo
    Align = alBottom
    TabOrder = 2
    object tsInfo: TTabSheet
      Caption = 'Info'
      OnEnter = tsInfoEnter
      DesignSize = (
        678
        190)
      object lblDescription: TLabel
        Left = 6
        Top = 3
        Width = 669
        Height = 54
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        ExplicitWidth = 585
      end
      object lbUpdates: TListBox
        Left = 3
        Top = 63
        Width = 671
        Height = 97
        Anchors = [akLeft, akTop, akRight]
        ItemHeight = 13
        TabOrder = 0
      end
    end
    object tsFiles: TTabSheet
      Caption = 'Files'
      ImageIndex = 1
    end
  end
  object PopupMenu: TPopupMenu
    OnPopup = PopupMenuPopup
    Left = 144
    Top = 16
    object pmCopyPackageNames: TMenuItem
      Caption = 'Copy package names'
      Hint = 'Copy all selected package names into clipboard'
      OnClick = pmCopyPackageNamesClick
    end
    object pmCopyUninstallationCommands: TMenuItem
      Caption = 'Copy uninstallation commands'
      Hint = 
        'Copy DISM command for uninstalling all selected packages into cl' +
        'ipboard'
      OnClick = pmCopyUninstallationCommandsClick
    end
    object pmVisibility: TMenuItem
      Caption = 'Visibility'
      object pmMakeVisible: TMenuItem
        Caption = 'Make visible'
        OnClick = pmMakeVisibleClick
      end
      object pmMakeInvisible: TMenuItem
        Caption = 'Make invisible'
        OnClick = pmMakeInvisibleClick
      end
      object pmRestoreDefaultVisibility: TMenuItem
        Caption = 'Restore default visibility'
        OnClick = pmRestoreDefaultVisibilityClick
      end
    end
    object pmUninstall: TMenuItem
      Caption = 'Uninstall'
      Hint = 'Uninstall selected package'
      OnClick = pmUninstallAllClick
    end
    object pmUninstallAll: TMenuItem
      Caption = 'Uninstall all'
      Hint = 'Uninstall all selected packages'
      OnClick = pmUninstallAllClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object pmReload: TMenuItem
      Caption = 'Reload'
      OnClick = pmReloadClick
    end
  end
  object ImageList1: TImageList
    Left = 80
    Top = 16
  end
  object MainMenu: TMainMenu
    Left = 16
    Top = 16
    object File1: TMenuItem
      Caption = 'File'
      object Exit1: TMenuItem
        Caption = 'Exit'
        OnClick = Exit1Click
      end
    end
    object Edit1: TMenuItem
      Caption = 'Edit'
      object pmMakeAllVisibile: TMenuItem
        Caption = 'Make all visible'
        OnClick = pmMakeAllVisibileClick
      end
      object pmMakeAllInvisible: TMenuItem
        Caption = 'Make all invisible'
        OnClick = pmMakeAllInvisibleClick
      end
      object pmRestoreDefaltVisibilityAll: TMenuItem
        Caption = 'Restore default visibility for all'
        OnClick = pmRestoreDefaltVisibilityAllClick
      end
    end
    object Service1: TMenuItem
      Caption = 'Service'
      object pmOpenCBSRegistry: TMenuItem
        Caption = 'Open CBS registry...'
        Hint = 'Open registry editor at a CBS key'
        OnClick = pmOpenCBSRegistryClick
      end
      object Diskcleanup1: TMenuItem
        Caption = 'Disk cleanup...'
        Hint = 'Run disk cleanup utility'
        OnClick = Diskcleanup1Click
      end
      object Optionalfeatures1: TMenuItem
        Caption = 'Optional features...'
        Hint = 'Enable or disalbe optional Windows features'
        OnClick = Optionalfeatures1Click
      end
    end
  end
end
