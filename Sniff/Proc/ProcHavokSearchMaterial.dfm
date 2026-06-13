object FrameHavokMaterial: TFrameHavokMaterial
  Left = 0
  Top = 0
  Width = 482
  Height = 330
  TabOrder = 0
  object Label1: TLabel
    Left = 16
    Top = 64
    Width = 99
    Height = 15
    Caption = 'Search for material'
  end
  object Label2: TLabel
    Left = 16
    Top = 117
    Width = 113
    Height = 15
    Caption = 'Replace with material'
  end
  object StaticText1: TStaticText
    Left = 0
    Top = 0
    Width = 482
    Height = 33
    Align = alTop
    AutoSize = False
    Caption = 
      'Search for Havok material in bhkShape* nodes. Leave "Replace wit' +
      'h" field empty to only report found files.'
    TabOrder = 0
  end
  object cmbSearch: TComboBox
    Left = 16
    Top = 83
    Width = 377
    Height = 23
    Style = csDropDownList
    DropDownCount = 24
    TabOrder = 1
  end
  object cmbReplace: TComboBox
    Left = 16
    Top = 136
    Width = 377
    Height = 23
    Style = csDropDownList
    DropDownCount = 24
    TabOrder = 2
  end
  object edSearch: TLabeledEdit
    Left = 399
    Top = 83
    Width = 73
    Height = 23
    EditLabel.Width = 26
    EditLabel.Height = 15
    EditLabel.Caption = 'Filter'
    TabOrder = 3
    Text = ''
    OnChange = rbTES5Click
  end
  object edReplace: TLabeledEdit
    Left = 399
    Top = 136
    Width = 73
    Height = 23
    EditLabel.Width = 26
    EditLabel.Height = 15
    EditLabel.Caption = 'Filter'
    TabOrder = 4
    Text = ''
    OnChange = rbTES5Click
  end
  object rbTES4: TRadioButton
    Left = 16
    Top = 39
    Width = 89
    Height = 17
    Caption = 'Oblivion'
    TabOrder = 5
    OnClick = rbTES5Click
  end
  object rbFO3: TRadioButton
    Left = 120
    Top = 39
    Width = 105
    Height = 17
    Caption = 'Fallout 3/NV'
    TabOrder = 6
    OnClick = rbTES5Click
  end
  object rbTES5: TRadioButton
    Left = 240
    Top = 39
    Width = 105
    Height = 17
    Caption = 'Skyrim'
    Checked = True
    TabOrder = 7
    TabStop = True
    OnClick = rbTES5Click
  end
  object chkSkipRoot: TCheckBox
    Left = 16
    Top = 176
    Width = 169
    Height = 17
    Caption = 'Skip root node collision'
    TabOrder = 8
  end
end
