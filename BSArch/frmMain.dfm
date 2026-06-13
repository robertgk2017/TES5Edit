object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'BSArchPro'
  ClientHeight = 561
  ClientWidth = 1024
  Color = clWindow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDefault
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object pnlFilter: TPanel
    Left = 0
    Top = 0
    Width = 1024
    Height = 41
    Align = alTop
    BevelEdges = [beBottom]
    BevelKind = bkTile
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      1024
      39)
    object lblAssets: TLabel
      Left = 636
      Top = 13
      Width = 38
      Height = 13
      Caption = '0/0 files'
    end
    object edFilter: TLabeledEdit
      Left = 40
      Top = 10
      Width = 329
      Height = 21
      EditLabel.Width = 24
      EditLabel.Height = 21
      EditLabel.Caption = 'Filter'
      LabelPosition = lpLeft
      TabOrder = 0
      Text = ''
      OnKeyPress = edFilterKeyPress
    end
    object rbAll: TRadioButton
      Left = 385
      Top = 12
      Width = 41
      Height = 17
      Caption = 'All'
      Checked = True
      TabOrder = 1
      TabStop = True
      OnClick = rbAllClick
    end
    object rbCompressed: TRadioButton
      Left = 432
      Top = 12
      Width = 88
      Height = 17
      Caption = 'Compressed'
      TabOrder = 2
      OnClick = rbAllClick
    end
    object rbUncompressed: TRadioButton
      Left = 526
      Top = 12
      Width = 90
      Height = 17
      Caption = 'Uncompressed'
      TabOrder = 3
      OnClick = rbAllClick
    end
    object btnFilterReset: TButton
      Left = 765
      Top = 7
      Width = 108
      Height = 24
      Caption = 'Show All'
      TabOrder = 4
      OnClick = btnFilterResetClick
    end
    object btnClearList: TButton
      Left = 907
      Top = 7
      Width = 108
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Clear List'
      TabOrder = 5
      OnClick = btnClearListClick
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 512
    Width = 1024
    Height = 49
    Align = alBottom
    BevelEdges = [beTop]
    BevelKind = bkTile
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      1024
      47)
    object btnPack: TButton
      Left = 785
      Top = 10
      Width = 108
      Height = 27
      Anchors = [akTop, akRight]
      Caption = 'Pack'
      TabOrder = 0
      OnClick = btnPackClick
    end
    object btnExit: TButton
      Left = 907
      Top = 10
      Width = 108
      Height = 27
      Anchors = [akTop, akRight]
      Caption = 'Exit'
      TabOrder = 1
      OnClick = btnExitClick
    end
  end
  object pnlTip: TPanel
    Left = 0
    Top = 448
    Width = 1024
    Height = 64
    Align = alBottom
    BevelOuter = bvNone
    ParentColor = True
    ShowCaption = False
    TabOrder = 2
    object lblTip: TLabel
      Left = 0
      Top = 0
      Width = 1024
      Height = 64
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Caption = 'Tip'
      PopupMenu = mnAssets
      ShowAccelChar = False
      Layout = tlCenter
    end
  end
  object vtAssets: TVirtualStringTree
    Left = 0
    Top = 41
    Width = 1024
    Height = 407
    Align = alClient
    BevelInner = bvLowered
    BevelOuter = bvRaised
    BorderStyle = bsNone
    Colors.SelectionTextColor = clWindowText
    DefaultNodeHeight = 17
    Header.AutoSizeIndex = 1
    Header.Height = 17
    Header.Options = [hoAutoResize, hoColumnResize, hoHotTrack, hoShowImages, hoShowSortGlyphs, hoVisible]
    IncrementalSearch = isAll
    IncrementalSearchStart = ssAlwaysStartOver
    PopupMenu = mnAssets
    SelectionBlendFactor = 32
    SelectionCurveRadius = 3
    TabOrder = 3
    TreeOptions.AutoOptions = [toAutoScrollOnExpand, toAutoSort, toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toCheckSupport, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toThemeAware, toUseBlendedImages, toUseBlendedSelection]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect, toRightClickSelect]
    Visible = False
    OnBeforeCellPaint = vtAssetsBeforeCellPaint
    OnChecked = vtAssetsChecked
    OnCompareNodes = vtAssetsCompareNodes
    OnDblClick = vtAssetsDblClick
    OnGetText = vtAssetsGetText
    OnHeaderClick = vtAssetsHeaderClick
    OnInitNode = vtAssetsInitNode
    OnKeyDown = vtAssetsKeyDown
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        MinWidth = 50
        Options = [coAllowClick, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coEditable, coStyleColor]
        Position = 0
        Text = '[Compressed] Asset Name'
        Width = 400
      end
      item
        MinWidth = 50
        Options = [coAllowClick, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coEditable, coStyleColor]
        Position = 1
        Text = 'Source File'
        Width = 624
      end>
  end
  object mnAssets: TPopupMenu
    OnPopup = mnAssetsPopup
    Left = 384
    Top = 208
    object mniAssetOpen: TMenuItem
      Caption = 'Open'
      OnClick = mniAssetOpenClick
    end
    object mniAssetEdit: TMenuItem
      Caption = 'Edit'
      OnClick = mniAssetEditClick
    end
    object mniArchiveInfo: TMenuItem
      Caption = 'Asset Archive Information'
      OnClick = mniArchiveInfoClick
    end
    object mniAssetReplace: TMenuItem
      Caption = 'Search and Replace'
      OnClick = mniAssetReplaceClick
    end
    object mniAssetRemoveSelected: TMenuItem
      Caption = 'Remove Selected'
      ShortCut = 46
      OnClick = mniAssetRemoveSelectedClick
    end
    object mniAssetRemoveUnselected: TMenuItem
      Caption = 'Remove Unselected'
      OnClick = mniAssetRemoveUnselectedClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object mniAssetCompress: TMenuItem
      Caption = 'Set Compressed Where Applicable'
      OnClick = mniAssetCompressClick
    end
    object mniAssetFindIdentical: TMenuItem
      Caption = 'Find Identical Assets'
      OnClick = mniAssetFindIdenticalClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object mniAssetUnpack: TMenuItem
      Caption = 'Unpack Selected'
      OnClick = mniAssetUnpackClick
    end
    object mniAssetUnpackSaveAs: TMenuItem
      Caption = 'Unpack Asset and Save As'
      OnClick = mniAssetUnpackSaveAsClick
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object mniAssetPack: TMenuItem
      Caption = 'Pack Selected'
      OnClick = mniAssetPackClick
    end
    object N4: TMenuItem
      Caption = '-'
    end
    object mniLoadList: TMenuItem
      Caption = 'Load List'
      OnClick = mniLoadListClick
    end
    object mniSaveList: TMenuItem
      Caption = 'Save List'
      OnClick = mniSaveListClick
    end
  end
  object dlgSameAsset: TTaskDialog
    Buttons = <
      item
        Caption = 'Replace All'
        Default = True
        ModalResult = 100
      end
      item
        Caption = 'Skip All'
        ModalResult = 101
      end
      item
        Caption = 'Add All'
        ModalResult = 102
      end>
    CommonButtons = [tcbCancel]
    Flags = [tfUseHiconMain, tfAllowDialogCancellation, tfUseCommandLinksNoIcon, tfExpandedByDefault, tfPositionRelativeToWindow, tfSizeToContent]
    RadioButtons = <>
    Text = 'Text Matching Asset'
    Left = 384
    Top = 264
  end
  object dlgPackingCheck: TTaskDialog
    Buttons = <
      item
        Caption = 'Show All'
        ModalResult = 100
      end
      item
        Caption = 'Continue'
        Enabled = False
        ModalResult = 101
      end>
    CommonButtons = [tcbCancel]
    DefaultButton = tcbCancel
    Flags = [tfUseHiconMain, tfAllowDialogCancellation, tfPositionRelativeToWindow, tfSizeToContent]
    RadioButtons = <>
    Left = 384
    Top = 320
  end
  object timerFilter: TTimer
    Interval = 300
    OnTimer = timerFilterTimer
    Left = 384
    Top = 120
  end
  object dlgIdenticalFiles: TTaskDialog
    Buttons = <
      item
        Caption = 'Group Identical'
        CommandLinkHint = 
          'Reorder list to group identical files and increase their chance ' +
          'to end up in the same archive'
        ModalResult = 100
      end
      item
        Caption = 'Filter By Identical'
        CommandLinkHint = 'Show identical assets in the list'
        ModalResult = 101
      end
      item
        Caption = 'Show Identical Assets'
        CommandLinkHint = 'Preview in separate window as text'
        ModalResult = 102
      end>
    Caption = 'Identical Assets'
    CommonButtons = [tcbCancel]
    ExpandedText = 
      'Group Identical files before packing and check Shared Data optio' +
      'n to take advantage of packing same files together'
    Flags = [tfUseHiconMain, tfAllowDialogCancellation, tfUseCommandLinks, tfExpandedByDefault, tfPositionRelativeToWindow, tfSizeToContent]
    RadioButtons = <>
    Left = 384
    Top = 376
  end
end
