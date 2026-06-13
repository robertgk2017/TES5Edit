object FrameUniversalTweaker: TFrameUniversalTweaker
  Left = 0
  Top = 0
  Width = 475
  Height = 280
  Hint = 
    'When checked also process descendants of specified block types, ' +
    'for example for NiNode it would be BSFadeNode, etc.'
  TabOrder = 0
  DesignSize = (
    475
    280)
  object Label1: TLabel
    Left = 16
    Top = 23
    Width = 443
    Height = 46
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 
      'Comma separated block types to process. Or a path to the block u' +
      'sing types or names, for example "\BSFadeNode\arms2:2\NiAlphaPro' +
      'perty". When empty process all blocks. Not used for material fil' +
      'es.'
    WordWrap = True
  end
  object StaticText1: TStaticText
    Left = 0
    Top = 0
    Width = 475
    Height = 17
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alTop
    AutoSize = False
    Caption = 
      'Change any field in defined block(s) of nif/kf and FO4 material ' +
      'files. '
    TabOrder = 0
  end
  object edPath: TLabeledEdit
    Left = 16
    Top = 119
    Width = 247
    Height = 23
    Hint = 
      'Path examples: scale value in transformation structure "Transfor' +
      'm\Scale", first texture in texture set "Textures\[0]". You can c' +
      'heck field names by converting to JSON format using Convert to J' +
      'SON operation.'
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    EditLabel.Width = 84
    EditLabel.Height = 15
    EditLabel.Margins.Left = 5
    EditLabel.Margins.Top = 5
    EditLabel.Margins.Right = 5
    EditLabel.Margins.Bottom = 5
    EditLabel.Caption = 'Path to the field'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    Text = 'Alpha'
    OnChange = edPathChange
  end
  object edValue: TLabeledEdit
    Left = 382
    Top = 119
    Width = 77
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 28
    EditLabel.Height = 15
    EditLabel.Margins.Left = 5
    EditLabel.Margins.Top = 5
    EditLabel.Margins.Right = 5
    EditLabel.Margins.Bottom = 5
    EditLabel.Caption = 'Value'
    TabOrder = 2
    Text = '0.8'
  end
  object chkOldValueCheck: TCheckBox
    Left = 16
    Top = 148
    Width = 313
    Height = 17
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'If another field (empty for the same field)'
    TabOrder = 3
    OnClick = chkOldValueCheckClick
  end
  object cmbOldValueMode: TComboBox
    Left = 269
    Top = 171
    Width = 107
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Style = csDropDownList
    DropDownCount = 20
    TabOrder = 4
  end
  object edOldValue: TEdit
    Left = 382
    Top = 171
    Width = 77
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 5
  end
  object cmbNewValueMode: TComboBox
    Left = 269
    Top = 119
    Width = 107
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Style = csDropDownList
    DropDownCount = 20
    TabOrder = 6
  end
  object edBlocks: TEdit
    Left = 16
    Top = 75
    Width = 217
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 7
    Text = 'NiMaterialProperty'
  end
  object chkInherited: TCheckBox
    Left = 239
    Top = 78
    Width = 121
    Height = 17
    Hint = 
      'When checked also process descendants of specified block types, ' +
      'for example for NiNode it would be BSFadeNode, BSLeadAnimNode, B' +
      'SOrderedNode, etc.'
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Anchors = [akTop, akRight]
    Caption = 'and descendants'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 8
  end
  object chkReport: TCheckBox
    Left = 16
    Top = 200
    Width = 257
    Height = 17
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Report only, don'#39't save anything'
    TabOrder = 9
  end
  object edOldPath: TEdit
    Left = 16
    Top = 171
    Width = 247
    Height = 23
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 10
  end
  object btnPreset: TButton
    Left = 366
    Top = 75
    Width = 93
    Height = 25
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Anchors = [akTop, akRight]
    Caption = 'Presets'
    DropDownMenu = menuPreset
    Style = bsSplitButton
    TabOrder = 11
    TabStop = False
    OnClick = btnPresetClick
  end
  object menuPreset: TPopupMenu
    AutoHotkeys = maManual
    Left = 416
    Top = 24
    object miPresetAdd: TMenuItem
      Caption = 'Add'
      OnClick = miPresetAddClick
    end
    object miPresetRemove: TMenuItem
      Caption = 'Remove'
      OnClick = miPresetRemoveClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
  end
end
