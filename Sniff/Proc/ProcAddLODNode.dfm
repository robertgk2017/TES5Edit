object FrameAddLODNode: TFrameAddLODNode
  Left = 0
  Top = 0
  Width = 566
  Height = 324
  TabOrder = 0
  object Label1: TLabel
    Left = 32
    Top = 54
    Width = 94
    Height = 15
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Caption = 'LOD Level Extents'
  end
  object Label2: TLabel
    Left = 200
    Top = 54
    Width = 92
    Height = 15
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Caption = 'Proportion Levels'
  end
  object StaticText1: TStaticText
    Left = 0
    Top = 0
    Width = 566
    Height = 25
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    AutoSize = False
    Caption = 
      'Move NiTriStrips and NiTriShape from the root node to the NiLODN' +
      'ode (added if missing)'
    TabOrder = 0
  end
  object memoExtents: TMemo
    Left = 32
    Top = 75
    Width = 121
    Height = 73
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      '2000'
      '50000')
    ParentFont = False
    TabOrder = 1
    WordWrap = False
  end
  object chkRange: TRadioButton
    Left = 16
    Top = 31
    Width = 137
    Height = 17
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'NiRangeLODData'
    Checked = True
    TabOrder = 2
    TabStop = True
  end
  object chkScreen: TRadioButton
    Left = 184
    Top = 31
    Width = 137
    Height = 17
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'NiScreenLODData'
    TabOrder = 3
  end
  object memoProportions: TMemo
    Left = 200
    Top = 75
    Width = 121
    Height = 73
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      '0.48')
    ParentFont = False
    TabOrder = 4
    WordWrap = False
  end
end
