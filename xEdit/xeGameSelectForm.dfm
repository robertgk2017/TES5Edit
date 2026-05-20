object frmGameSelect: TfrmGameSelect
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Select Game Mode'
  ClientHeight = 503
  ClientWidth = 330
  Color = clBtnFace
  ParentFont = True
  KeyPreview = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  DesignSize = (
    330
    503)
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 11
    Width = 35
    Height = 15
    Caption = 'Search'
  end
  object Label2: TLabel
    Left = 8
    Top = 442
    Width = 238
    Height = 45
    Anchors = [akLeft, akBottom]
    Caption = 
      'Skip this dialog by specifying the game mode as an argument or b' +
      'y renaming the application file to include it.'
    WordWrap = True
  end
  object ListBox1: TListBox
    AlignWithMargins = True
    Left = 3
    Top = 40
    Width = 324
    Height = 393
    Margins.Top = 40
    Margins.Bottom = 70
    Align = alClient
    Anchors = [akLeft, akTop, akRight]
    ItemHeight = 15
    TabOrder = 0
    OnDblClick = ListBox1DblClick
  end
  object edSearch: TEdit
    Left = 47
    Top = 8
    Width = 280
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    OnChange = edSearchChange
  end
  object btnOK: TButton
    Left = 247
    Top = 470
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
  end
end
