object FrameTransformInfo: TFrameTransformInfo
  Left = 0
  Top = 0
  Width = 499
  Height = 307
  TabOrder = 0
  object StaticText1: TStaticText
    Left = 0
    Top = 0
    Width = 449
    Height = 19
    Align = alTop
    Caption = 
      'Show non-default transform info on descendants of NiAVObject and' +
      ' bhkRigidBodyT'
    TabOrder = 0
  end
  object chkTranslation: TCheckBox
    Left = 16
    Top = 25
    Width = 113
    Height = 17
    Caption = 'Translation'
    Checked = True
    State = cbChecked
    TabOrder = 1
  end
  object chkRotation: TCheckBox
    Left = 16
    Top = 48
    Width = 113
    Height = 17
    Caption = 'Rotation'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object chkScale: TCheckBox
    Left = 16
    Top = 71
    Width = 113
    Height = 17
    Caption = 'Scale'
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object chkSkipEmpty: TCheckBox
    Left = 16
    Top = 111
    Width = 145
    Height = 17
    Caption = 'Skip empty nodes'
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
end
