object FrameWallsReflectionFlag: TFrameWallsReflectionFlag
  Left = 0
  Top = 0
  Width = 567
  Height = 327
  TabOrder = 0
  object StaticText1: TStaticText
    Left = 0
    Top = 0
    Width = 567
    Height = 49
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    AutoSize = False
    Caption = 
      'Intended to be used with Real Time Reflections - NVSE. Set real ' +
      'time reflection (Unknown10) flag and unset Light fade flag in sh' +
      'aders with Environment map flag. Optionally set Environment map ' +
      'scale and NiFloatExtraData named NormalIntensity/BlendIntensity ' +
      'with defined value.'
    TabOrder = 0
  end
  object edMapScale: TLabeledEdit
    Left = 16
    Top = 80
    Width = 257
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    EditLabel.Width = 238
    EditLabel.Height = 15
    EditLabel.Margins.Left = 5
    EditLabel.Margins.Top = 5
    EditLabel.Margins.Right = 5
    EditLabel.Margins.Bottom = 5
    EditLabel.Caption = 'Environment map scale (empty to leave as is)'
    TabOrder = 1
    Text = '0.8'
  end
  object edNormalIntensity: TLabeledEdit
    Left = 16
    Top = 136
    Width = 257
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    EditLabel.Width = 229
    EditLabel.Height = 15
    EditLabel.Margins.Left = 5
    EditLabel.Margins.Top = 5
    EditLabel.Margins.Right = 5
    EditLabel.Margins.Bottom = 5
    EditLabel.Caption = 'Normal Intensity 0..15 (empty to leave as is)'
    TabOrder = 2
    Text = ''
  end
  object edBlendIntensity: TLabeledEdit
    Left = 16
    Top = 192
    Width = 257
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    EditLabel.Width = 213
    EditLabel.Height = 15
    EditLabel.Margins.Left = 5
    EditLabel.Margins.Top = 5
    EditLabel.Margins.Right = 5
    EditLabel.Margins.Bottom = 5
    EditLabel.Caption = 'Blend Intensity 0..1 (empty to leave as is)'
    TabOrder = 3
    Text = ''
  end
end
