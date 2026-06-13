object FrameRagdollConstraintUpdate: TFrameRagdollConstraintUpdate
  Left = 0
  Top = 0
  Width = 528
  Height = 272
  TabOrder = 0
  object StaticText1: TStaticText
    Left = 0
    Top = 0
    Width = 528
    Height = 49
    Align = alTop
    AutoSize = False
    Caption = 
      'Calculate Twist plane axis (Motor in NifSkope) A and B values in' +
      ' bhkRagdollConstraint and bhkMalleableConstraint of Ragdoll type' +
      '. Havok A -> B must be used in NifSkope before running this.'
    TabOrder = 0
  end
  object chkConvertToMalleable: TCheckBox
    Left = 16
    Top = 55
    Width = 497
    Height = 17
    Caption = 
      'Convert all constraints to bhkMalleableConstraint (except bhkBre' +
      'akableConstraint)'
    TabOrder = 1
  end
end
