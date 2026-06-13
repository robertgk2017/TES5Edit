object frmModuleSelect: TfrmModuleSelect
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Module Selection'
  ClientHeight = 613
  ClientWidth = 898
  Color = clBtnFace
  ParentFont = True
  KeyPreview = True
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  DesignSize = (
    898
    613)
  TextHeight = 15
  object lblPreset: TLabel
    Left = 415
    Top = 8
    Width = 35
    Height = 15
    Anchors = [akTop, akRight]
    Caption = '&Preset:'
    FocusControl = cbPreset
  end
  object btnOK: TButton
    Left = 821
    Top = 580
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 9
    OnClick = btnOKClick
  end
  object vstModules: TVirtualStringTree
    Left = 8
    Top = 37
    Width = 888
    Height = 539
    Anchors = [akLeft, akTop, akRight, akBottom]
    Header.AutoSizeIndex = 0
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible]
    Header.SortColumn = 0
    PopupMenu = pmuModules
    TabOrder = 6
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toCheckSupport, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toPopupMode, toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines, toUseBlendedSelection]
    TreeOptions.SelectionOptions = [toFullRowSelect, toLevelSelectConstraint, toMultiSelect, toRightClickSelect, toSiblingSelectConstraint]
    OnChecked = vstModulesChecked
    OnCompareNodes = vstModulesCompareNodes
    OnFreeNode = vstModulesFreeNode
    OnGetText = vstModulesGetText
    OnPaintText = vstModulesPaintText
    OnHeaderClick = vstModulesHeaderClick
    OnIncrementalSearch = vstModulesIncrementalSearch
    OnInitChildren = vstModulesInitChildren
    OnInitNode = vstModulesInitNode
    OnKeyDown = vstModulesKeyDown
    OnKeyPress = vstModulesKeyPress
    OnNodeDblClick = vstModulesNodeDblClick
    OnBeforeGetCheckState = vstModulesBeforeGetCheckState
    Columns = <
      item
        MinWidth = 300
        Position = 0
        Text = 'Filename'
        Width = 300
      end
      item
        Alignment = taRightJustify
        CaptionAlignment = taCenter
        MinWidth = 200
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coUseCaptionAlignment, coEditable, coStyleColor]
        Position = 1
        Text = 'File Order'
        Width = 200
      end
      item
        Alignment = taCenter
        CaptionAlignment = taCenter
        MinWidth = 50
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coUseCaptionAlignment, coEditable, coStyleColor]
        Position = 2
        Text = 'ESM'
      end
      item
        Alignment = taCenter
        CaptionAlignment = taCenter
        MinWidth = 50
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coUseCaptionAlignment, coEditable, coStyleColor]
        Position = 3
        Text = 'Light'
      end
      item
        Alignment = taRightJustify
        CaptionAlignment = taCenter
        MinWidth = 75
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coUseCaptionAlignment, coEditable, coStyleColor]
        Position = 6
        Text = 'Load Order'
        Width = 75
      end
      item
        CaptionAlignment = taCenter
        MinWidth = 90
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coUseCaptionAlignment, coEditable, coStyleColor]
        Position = 7
        Text = 'FormID Prefix'
        Width = 90
      end
      item
        Alignment = taCenter
        CaptionAlignment = taCenter
        MinWidth = 70
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coUseCaptionAlignment, coEditable, coStyleColor]
        Position = 5
        Text = 'Update'
        Width = 70
      end
      item
        Alignment = taCenter
        CaptionAlignment = taCenter
        MinWidth = 50
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coUseCaptionAlignment, coEditable, coStyleColor]
        Position = 4
        Text = 'Med'
      end>
  end
  object pnlError: TPanel
    Left = 8
    Top = 580
    Width = 721
    Height = 26
    Alignment = taLeftJustify
    Anchors = [akLeft, akRight, akBottom]
    BevelOuter = bvLowered
    BorderWidth = 3
    TabOrder = 7
  end
  object edFilter: TLabeledEdit
    Left = 40
    Top = 5
    Width = 314
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 29
    EditLabel.Height = 23
    EditLabel.Caption = '&Filter:'
    LabelPosition = lpLeft
    TabOrder = 0
    Text = ''
    StyleElements = [seFont, seBorder]
    OnChange = edFilterChange
    OnKeyDown = edFilterKeyDown
  end
  object cbRegExFilter: TCheckBox
    Left = 359
    Top = 4
    Width = 52
    Height = 24
    Anchors = [akTop, akRight]
    Caption = '&RegEx'
    TabOrder = 1
    OnClick = cbRegExFilterClick
  end
  object btnCancel: TButton
    Left = 740
    Top = 580
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 8
    Visible = False
  end
  object bnDelete: TButton
    Left = 821
    Top = 4
    Width = 75
    Height = 25
    Action = acPresetDelete
    Anchors = [akTop, akRight]
    TabOrder = 5
  end
  object bnSave: TButton
    Left = 740
    Top = 4
    Width = 75
    Height = 25
    Action = acPresetSave
    Anchors = [akTop, akRight]
    TabOrder = 4
  end
  object bnLoad: TButton
    Left = 659
    Top = 4
    Width = 75
    Height = 25
    Action = acPresetLoad
    Anchors = [akTop, akRight]
    BiDiMode = bdRightToLeft
    ParentBiDiMode = False
    TabOrder = 3
  end
  object cbPreset: TComboBox
    Left = 456
    Top = 5
    Width = 197
    Height = 23
    Anchors = [akTop, akRight]
    TabOrder = 2
    OnKeyPress = cbPresetKeyPress
  end
  object pmuModules: TPopupMenu
    OnPopup = pmuModulesPopup
    Left = 128
    Top = 184
    object mniSelectAll: TMenuItem
      Caption = 'Select All'
      OnClick = mniSelectAllClick
    end
    object mniSelectNone: TMenuItem
      Caption = 'Select None'
      OnClick = mniSelectNoneClick
    end
    object mniInvertSelection: TMenuItem
      Caption = 'Invert Selection'
      OnClick = mniInvertSelectionClick
    end
  end
  object aclModules: TActionList
    Left = 424
    Top = 320
    object acPresetLoad: TAction
      Caption = '&Load'
      OnExecute = acPresetLoadExecute
      OnUpdate = acPresetLoadUpdate
    end
    object acPresetSave: TAction
      AutoCheck = True
      Caption = '&Save'
      OnExecute = acPresetSaveExecute
      OnUpdate = acPresetSaveUpdate
    end
    object acPresetDelete: TAction
      Caption = '&Delete'
      OnExecute = acPresetDeleteExecute
      OnUpdate = acPresetDeleteUpdate
    end
  end
end
