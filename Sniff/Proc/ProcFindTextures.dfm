object FrameFindTextures: TFrameFindTextures
  Left = 0
  Top = 0
  Width = 549
  Height = 365
  DoubleBuffered = True
  ParentDoubleBuffered = False
  TabOrder = 0
  object StaticText1: TStaticText
    Left = 0
    Top = 0
    Width = 549
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    AutoSize = False
    Caption = 
      'Find textures by their properties and optionally copy them. Righ' +
      't click on formats list to check/uncheck all currently filtered.'
    TabOrder = 0
  end
  object lvFormat: TListView
    AlignWithMargins = True
    Left = 0
    Top = 93
    Width = 265
    Height = 272
    Margins.Left = 0
    Margins.Top = 60
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alLeft
    BevelEdges = []
    BevelInner = bvSpace
    BevelOuter = bvRaised
    BevelKind = bkSoft
    BorderStyle = bsNone
    Checkboxes = True
    Columns = <
      item
        Width = 240
      end>
    ColumnClick = False
    DoubleBuffered = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    ParentColor = True
    ParentDoubleBuffered = False
    PopupMenu = menuFormats
    ShowColumnHeaders = False
    TabOrder = 1
    ViewStyle = vsReport
    OnItemChecked = lvFormatItemChecked
  end
  object edFormatFilter: TLabeledEdit
    Left = 85
    Top = 63
    Width = 180
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    EditLabel.Width = 65
    EditLabel.Height = 23
    EditLabel.Margins.Left = 5
    EditLabel.Margins.Top = 5
    EditLabel.Margins.Right = 5
    EditLabel.Margins.Bottom = 5
    EditLabel.Caption = 'Format filter'
    LabelPosition = lpLeft
    TabOrder = 2
    Text = ''
    OnChange = edFormatFilterChange
  end
  object edProp: TValueListEditor
    AlignWithMargins = True
    Left = 269
    Top = 63
    Width = 275
    Height = 302
    Margins.Left = 4
    Margins.Top = 30
    Margins.Right = 12
    Margins.Bottom = 0
    Align = alLeft
    DefaultColWidth = 130
    DefaultRowHeight = 27
    DropDownRows = 20
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goDrawFocusSelected, goEditing, goAlwaysShowEditor, goThumbTracking, goFixedRowClick]
    Strings.Strings = (
      '=')
    TabOrder = 3
    TitleCaptions.Strings = (
      'Parameter'
      'Value')
    ColWidths = (
      130
      139)
  end
  object chkReportOnly: TCheckBox
    Left = 3
    Top = 40
    Width = 214
    Height = 17
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Report only, don'#39't save anything'
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object chkHeaderDump: TCheckBox
    Left = 220
    Top = 40
    Width = 324
    Height = 17
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Include DDS header dump in report (except BA2 DDS)'
    TabOrder = 5
  end
  object menuFormats: TPopupMenu
    Tag = 1
    Left = 104
    Top = 136
    object mniCheckAll: TMenuItem
      Tag = 1
      Caption = 'Check all'
      OnClick = mniCheckAllClick
    end
    object mniUncheckAll: TMenuItem
      Caption = 'Uncheck all'
      OnClick = mniCheckAllClick
    end
  end
end
