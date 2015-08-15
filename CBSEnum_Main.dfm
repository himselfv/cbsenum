object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Packages'
  ClientHeight = 501
  ClientWidth = 602
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 417
    Top = 0
    Width = 185
    Height = 501
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitLeft = 348
    DesignSize = (
      185
      501)
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
    object Panel2: TPanel
      Left = 0
      Top = 123
      Width = 185
      Height = 41
      Anchors = [akLeft, akTop, akRight]
      BevelOuter = bvNone
      TabOrder = 3
      DesignSize = (
        185
        41)
      object rbGroupEachPart: TRadioButton
        Left = 6
        Top = 0
        Width = 171
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'By each part of the name'
        Checked = True
        TabOrder = 0
        TabStop = True
        OnClick = rbGroupEachPartClick
      end
      object rbGroupDistinctParts: TRadioButton
        Left = 6
        Top = 23
        Width = 171
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'By distinct parts'
        TabOrder = 1
        OnClick = rbGroupEachPartClick
      end
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 417
    Height = 501
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitLeft = 144
    ExplicitTop = 304
    ExplicitWidth = 185
    ExplicitHeight = 41
    object vtPackages: TVirtualStringTree
      Left = 0
      Top = 24
      Width = 417
      Height = 477
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
      TreeOptions.SelectionOptions = [toFullRowSelect, toRightClickSelect]
      OnFreeNode = vtPackagesFreeNode
      OnGetText = vtPackagesGetText
      OnPaintText = vtPackagesPaintText
      OnGetNodeDataSize = vtPackagesGetNodeDataSize
      OnInitNode = vtPackagesInitNode
      ExplicitTop = 0
      ExplicitWidth = 342
      ExplicitHeight = 501
      Columns = <>
    end
    object edtFilter: TEdit
      Left = 0
      Top = 0
      Width = 417
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
      ExplicitWidth = 342
    end
  end
  object PopupMenu: TPopupMenu
    OnPopup = PopupMenuPopup
    Left = 16
    Top = 16
    object pmCopyPackageName: TMenuItem
      Caption = 'Copy package name'
      OnClick = pmCopyPackageNameClick
    end
    object pmUninstall: TMenuItem
      Caption = 'Uninstall'
      OnClick = pmUninstallClick
    end
    object Uninstallall1: TMenuItem
      Caption = 'Uninstall all'
      OnClick = Uninstallall1Click
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
end
