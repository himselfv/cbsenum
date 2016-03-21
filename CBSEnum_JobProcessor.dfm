object JobProcessorForm: TJobProcessorForm
  Left = 0
  Top = 0
  Caption = 'Processing'
  ClientHeight = 336
  ClientWidth = 527
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object mmLog: TMemo
    Left = 0
    Top = 0
    Width = 527
    Height = 336
    Align = alClient
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
    OnChange = mmLogChange
  end
  object UpdateTimer: TTimer
    Enabled = False
    Interval = 200
    OnTimer = UpdateTimerTimer
    Left = 8
    Top = 8
  end
end
