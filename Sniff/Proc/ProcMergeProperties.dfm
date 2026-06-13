object FrameMergeProperties: TFrameMergeProperties
  Left = 0
  Top = 0
  Width = 531
  Height = 369
  TabOrder = 0
  object StaticText1: TStaticText
    Left = 0
    Top = 0
    Width = 531
    Height = 25
    Align = alTop
    AutoSize = False
    Caption = 
      'Merge identical NiProperty descendants and BSTextureSet blocks, ' +
      'remove redundant ones'
    TabOrder = 0
  end
  object lvProps: TListView
    Left = 0
    Top = 25
    Width = 320
    Height = 344
    Margins.Left = 8
    Margins.Top = 0
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
        Width = 300
      end>
    ColumnClick = False
    DoubleBuffered = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    ParentColor = True
    ParentDoubleBuffered = False
    ShowColumnHeaders = False
    TabOrder = 1
    ViewStyle = vsReport
  end
  object chkIgnoreName: TCheckBox
    Left = 336
    Top = 31
    Width = 153
    Height = 17
    Caption = 'Ignore Name field'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
end
