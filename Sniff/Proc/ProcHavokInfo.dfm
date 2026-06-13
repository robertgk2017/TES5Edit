object FrameHavokInfo: TFrameHavokInfo
  Left = 0
  Top = 0
  Width = 527
  Height = 323
  TabOrder = 0
  object StaticText1: TStaticText
    Left = 0
    Top = 0
    Width = 527
    Height = 33
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    AutoSize = False
    Caption = 
      'Show info on Havok collision objects: Target, Mass, Layer, Shape' +
      ' type. Select additional fields if needed.'
    TabOrder = 0
  end
  object chkPerObject: TCheckBox
    Left = 303
    Top = 39
    Width = 153
    Height = 17
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Per collision object'
    Checked = True
    State = cbChecked
    TabOrder = 1
  end
  object lvFields: TListView
    Left = 0
    Top = 33
    Width = 289
    Height = 290
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
        Caption = 'Fields'
        Width = 250
      end>
    ColumnClick = False
    DoubleBuffered = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    ParentColor = True
    ParentDoubleBuffered = False
    ShowColumnHeaders = False
    TabOrder = 2
    ViewStyle = vsReport
  end
  object chkSameLine: TCheckBox
    Left = 303
    Top = 62
    Width = 221
    Height = 17
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Additional fields on the same line'
    TabOrder = 3
  end
end
