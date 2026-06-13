{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit ProcUniversalTweaker;

interface

uses
  System.Classes,
  System.SysUtils,

  JsonDataObjects,

  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Mask,
  Vcl.Menus,
  Vcl.StdCtrls,

  SniffProcessor;

type
  TFrameUniversalTweaker = class(TFrame)
    StaticText1: TStaticText;
    edPath: TLabeledEdit;
    edValue: TLabeledEdit;
    Label1: TLabel;
    chkOldValueCheck: TCheckBox;
    cmbOldValueMode: TComboBox;
    edOldValue: TEdit;
    cmbNewValueMode: TComboBox;
    edBlocks: TEdit;
    chkInherited: TCheckBox;
    chkReport: TCheckBox;
    edOldPath: TEdit;
    btnPreset: TButton;
    menuPreset: TPopupMenu;
    miPresetAdd: TMenuItem;
    miPresetRemove: TMenuItem;
    N1: TMenuItem;
    procedure chkOldValueCheckClick(Sender: TObject);
    procedure edPathChange(Sender: TObject);
    procedure miPresetAddClick(Sender: TObject);
    procedure miPresetRemoveClick(Sender: TObject);
    procedure miPresetClick(Sender: TObject);
    procedure btnPresetClick(Sender: TObject);
  public
    fPresets: TJsonObject;
    fPreset: string;
    fPresetsChanged: Boolean;
    function AddPreset(const aPreset: string): TMenuItem;
  end;

  TTweakOldValueMode = (ovmEqual = 0, ovmNotEqual, ovmGreater, ovmLesser,
    ovmContains, ovmDoesntContain, ovmStartsWith, ovmEndsWith,
    ovmAnd, ovmAndNot, ovmRegExp);
  TTweakOldValueModes = set of TTweakOldValueMode;

  TTweakNewValueMode = (nvmSet = 0, nvmAdd, nvmMul, nvmReplace, nvmPrepend, nvmAppend,
    nvmAnd, nvmAndNot, nvmOr, nvmRemove, nvmRound, nvmMulRound);
  TTweakNewValueModes = set of TTweakNewValueMode;

const
  MathOld: TTweakOldValueModes = [ovmGreater, ovmLesser, ovmAnd, ovmAndNot];
  MathNew: TTweakNewValueModes = [nvmAdd, nvmMul, nvmAnd, nvmAndNot, nvmOr, nvmRound, nvmMulRound];

type
  TProcUniversalTweaker = class(TProcBase)
  private
    Frame: TFrameUniversalTweaker;
    fBlocks: array of string;
    fInherited: Boolean;
    fPath: string;
    fValue: string;
    fValueMode: TTweakNewValueMode;
    fOldValueCheck: Boolean;
    fOldPath: string;
    fOldValueMode: TTweakOldValueMode;
    fOldValue: string;
    fReportOnly: Boolean;
  public
    constructor Create(aManager: TProcManager); override;
    function GetFrame(aOwner: TComponent): TFrame; override;
    procedure OnShow; override;
    procedure OnHide; override;
    procedure OnStart; override;

    function ProcessFile(aFile: TProcFileObject): TBytes; override;
  end;

implementation

{$R *.dfm}

uses
  System.Math,
  System.RegularExpressionsCore,
  System.StrUtils,
  System.Types,

  Vcl.Dialogs,

  wbDataFormat,
  wbDataFormatNif,
  wbDataFormatMaterial;

constructor TProcUniversalTweaker.Create(aManager: TProcManager);
begin
  inherited;

  fTitle := 'Universal tweaker';
  fSupportedGames := [gtTES3, gtTES4, gtFO3, gtFNV, gtTES5, gtSSE, gtFO4];
  fExtensions := ['nif', 'kf', 'bgsm', 'bgem'];
end;

function TProcUniversalTweaker.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameUniversalTweaker.Create(aOwner);
  Result := Frame;
end;

procedure TFrameUniversalTweaker.btnPresetClick(Sender: TObject);
begin
  with ClientToScreen(Point(btnPreset.Left, btnPreset.Top + btnPreset.Height)) do
    menuPreset.Popup(X, Y);
end;

procedure TFrameUniversalTweaker.chkOldValueCheckClick(Sender: TObject);
begin
  edOldPath.Enabled := chkOldValueCheck.Checked;
  cmbOldValueMode.Enabled := chkOldValueCheck.Checked;
  edOldValue.Enabled := chkOldValueCheck.Checked;
end;

procedure TFrameUniversalTweaker.edPathChange(Sender: TObject);
begin
  edOldPath.TextHint := edPath.Text;
end;

function TFrameUniversalTweaker.AddPreset(const aPreset: string): TMenuItem;
begin
  for var Item in menuPreset.Items do
    if Item.Caption = aPreset then begin
      Result := Item;
      Exit;
    end;

  Result := TMenuItem.Create(menuPreset);
  Result.Caption := aPreset;
  Result.AutoCheck := True;
  Result.RadioItem := True;
  Result.GroupIndex := 1;
  Result.OnClick := miPresetClick;
  menuPreset.Items.Add(Result);
end;

procedure TFrameUniversalTweaker.miPresetClick(Sender: TObject);
begin
  var s := TMenuItem(Sender).Caption;
  if not fPresets.Contains(s) then
    Exit;

  with fPresets.O[s] do begin
    edBlocks.Text := S['sBlocks'];
    chkInherited.Checked := B['sDescendants'];
    edPath.Text := S['sPath'];
    edPathChange(nil);
    cmbNewValueMode.ItemIndex := cmbNewValueMode.Items.IndexOfObject(TObject(I['iValueMode']));
    edValue.Text := S['sValue'];
    chkOldValueCheck.Checked := B['bOldValueCheck'];
    edOldPath.Text := S['sOldPath'];
    cmbOldValueMode.ItemIndex := cmbOldValueMode.Items.IndexOfObject(TObject(I['iOldValueMode']));
    edOldValue.Text := S['sOldValue'];
  end;
  fPreset := s;
end;

procedure TFrameUniversalTweaker.miPresetAddClick(Sender: TObject);
var
  s: string;
begin
  if not InputQuery('Universal tweaker', 'Add preset', s) then
    Exit;

  if (Trim(s) = '') or (s = 'Add') or (s = 'Remove') or (s = '-') or (s = '&') then
    Exit;

  with fPresets.O[s] do begin
    S['sBlocks'] := edBlocks.Text;
    B['sDescendants'] := chkInherited.Checked;
    S['sPath'] := edPath.Text;
    I['iValueMode'] := Integer(cmbNewValueMode.Items.Objects[cmbNewValueMode.ItemIndex]);
    S['sValue'] := edValue.Text;
    B['bOldValueCheck'] := chkOldValueCheck.Checked;
    S['sOldPath'] := edOldPath.Text;
    I['iOldValueMode'] := Integer(cmbOldValueMode.Items.Objects[cmbOldValueMode.ItemIndex]);
    S['sOldValue'] := edOldValue.Text;
  end;

  AddPreset(s).Checked := True;
  fPreset := s;
  fPresetsChanged := True;
end;

procedure TFrameUniversalTweaker.miPresetRemoveClick(Sender: TObject);
begin
  if fPreset = '' then
    with TTaskDialog.Create(Self) do try
      Text := 'Select any preset first';
      Caption := Application.Title;
      Flags := [tfUseHiconMain, tfPositionRelativeToWindow, tfAllowDialogCancellation];
      CustomMainIcon := Application.Icon;
      CommonButtons := [tcbClose];
      Execute;
      Exit;
    finally
      Free;
    end;

  with TTaskDialog.Create(Self) do try
    Text := 'Remove preset:'#13 + fPreset;
    Caption := Application.Title;
    Flags := [tfUseHiconMain, tfPositionRelativeToWindow, tfAllowDialogCancellation];
    CustomMainIcon := Application.Icon;
    CommonButtons := [tcbYes, tcbNo];
    if not Execute or (ModalResult <> mrYes) then
      Exit;
  finally
    Free;
  end;

  fPresets.Remove(fPreset);
  for var Item in menuPreset.Items do
    if Item.Caption = fPreset then begin
      Item.Free;
      Break;
    end;

  fPreset := '';
  fPresetsChanged := True;
end;

procedure TProcUniversalTweaker.OnShow;
const
  cDefaultPresets = '''
    {"Change body part in BSDismemberSkinInstance partitions":{"sBlocks":"BSDismemberSkinInstance","sDescendants":false,"sPath":"Partitions\\[*]\\Body Part","iValueMode":0,"sValue":"SBP_32_BODY","bOldValueCheck":true,"sOldPath":"","iOldValueMode":0,"sOldValue":"SBP_34_FOREARMS"},
    "Set normal texture to diffuse with _n suffix in BSShaderTextureSet":{"sBlocks":"BSShaderTextureSet","sDescendants":false,"sPath":"Textures\\[1]","iValueMode":3,"sValue":"$1_n.dds","bOldValueCheck":true,"sOldPath":"Textures\\[0]","iOldValueMode":10,"sOldValue":"(.+)\\.dds"},
    "Change Author field in NiHeader":{"sBlocks":"NiHeader","sDescendants":false,"sPath":"Export Info\\Author","iValueMode":0,"sValue":"Sniff","bOldValueCheck":false,"sOldPath":"","iOldValueMode":0,"sOldValue":""},
    "Add Hidden flag to EditorMarker nodes":{"sBlocks":"NiAVObject","sDescendants":true,"sPath":"Flags","iValueMode":8,"sValue":"1","bOldValueCheck":true,"sOldPath":"Name","iOldValueMode":4,"sOldValue":"EditorMarker"},
    "Switch to Parallax shader in BSLightingShaderProperty if there is parallax texture":{"sBlocks":"BSLightingShaderProperty","sDescendants":false,"sPath":"Shader Type","iValueMode":0,"sValue":"Parallax","bOldValueCheck":true,"sOldPath":"Texture Set\\Textures\\[3]","iOldValueMode":4,"sOldValue":".dds"},
    "Add Glow_Map flag if shader is Glow Shader in BSLightingShaderProperty":{"sBlocks":"BSLightingShaderProperty","sDescendants":false,"sPath":"Shader Flags 2","iValueMode":5,"sValue":"| Glow_Map","bOldValueCheck":true,"sOldPath":"Shader Type","iOldValueMode":0,"sOldValue":"Glow Shader"},
    "Change priority of controlled blocks matched by name in NiControllerSequence":{"sBlocks":"NiControllerSequence","sDescendants":false,"sPath":"Controlled Blocks\\[*]\\Priority","iValueMode":0,"sValue":"10","bOldValueCheck":true,"sOldPath":"Node Name","iOldValueMode":10,"sOldValue":"Neck|Head"},
    "Change name of controlled blocks in NiControllerSequence":{"sBlocks":"NiControllerSequence","sDescendants":false,"sPath":"Controlled Blocks\\[*]\\Node Name","iValueMode":0,"sValue":"Bip01 Head","bOldValueCheck":true,"sOldPath":"","iOldValueMode":0,"sOldValue":"Bip01 Neck"},
    "Trim whitespaces from the Name field":{"sBlocks":"NiObjectNET","sDescendants":true,"sPath":"Name","iValueMode":3,"sValue":"","bOldValueCheck":true,"sOldPath":"","iOldValueMode":10,"sOldValue":"^\\s*|\\s*$"}}'
  ''';
begin
  Frame.cmbNewValueMode.Items.AddObject('Set', TObject(nvmSet));
  Frame.cmbNewValueMode.Items.AddObject('Add', TObject(nvmAdd));
  Frame.cmbNewValueMode.Items.AddObject('Mul', TObject(nvmMul));
  Frame.cmbNewValueMode.Items.AddObject('Round', TObject(nvmRound));
  Frame.cmbNewValueMode.Items.AddObject('Mul and Round', TObject(nvmMulRound));
  Frame.cmbNewValueMode.Items.AddObject('Replace with', TObject(nvmReplace));
  Frame.cmbNewValueMode.Items.AddObject('Prepend str', TObject(nvmPrepend));
  Frame.cmbNewValueMode.Items.AddObject('Append str', TObject(nvmAppend));
  Frame.cmbNewValueMode.Items.AddObject('Remove str', TObject(nvmRemove));
  Frame.cmbNewValueMode.Items.AddObject('AND &', TObject(nvmAnd));
  Frame.cmbNewValueMode.Items.AddObject('AND NOT &!', TObject(nvmAndNot));
  Frame.cmbNewValueMode.Items.AddObject('OR |', TObject(nvmOr));

  Frame.cmbOldValueMode.Items.AddObject('=', TObject(ovmEqual));
  Frame.cmbOldValueMode.Items.AddObject('<>', TObject(ovmNotEqual));
  Frame.cmbOldValueMode.Items.AddObject('>', TObject(ovmGreater));
  Frame.cmbOldValueMode.Items.AddObject('<', TObject(ovmLesser));
  Frame.cmbOldValueMode.Items.AddObject('Contains', TObject(ovmContains));
  Frame.cmbOldValueMode.Items.AddObject('Doesn''t contain', TObject(ovmDoesntContain));
  Frame.cmbOldValueMode.Items.AddObject('Starts with', TObject(ovmStartsWith));
  Frame.cmbOldValueMode.Items.AddObject('Ends with', TObject(ovmEndsWith));
  Frame.cmbOldValueMode.Items.AddObject('Regular Expr', TObject(ovmRegExp));
  Frame.cmbOldValueMode.Items.AddObject('AND &', TObject(ovmAnd));
  Frame.cmbOldValueMode.Items.AddObject('AND NOT &!', TObject(ovmAndNot));

  try
    Frame.chkReport.Checked := StorageGetBool('bReportOnly', Frame.chkReport.Checked);
    Frame.edBlocks.Text := StorageGetString('sBlocks', Frame.edBlocks.Text);
    Frame.chkInherited.Checked := StorageGetBool('bDescendants', Frame.chkInherited.Checked);
    Frame.edPath.Text := StorageGetString('sPath', Frame.edPath.Text);
    var i := Frame.cmbNewValueMode.Items.IndexOfObject(TObject(StorageGetInteger('iValueMode', 0)));
    if i = -1 then i := 0;
    Frame.cmbNewValueMode.ItemIndex := i;
    Frame.edValue.Text := StorageGetString('sValue', Frame.edValue.Text);
    Frame.edOldPath.Text := StorageGetString('sOldPath', Frame.edOldPath.Text);
    Frame.chkOldValueCheck.Checked := StorageGetBool('bOldValueCheck', Frame.chkOldValueCheck.Checked);
    i := Frame.cmbOldValueMode.Items.IndexOfObject(TObject(StorageGetInteger('iOldValueMode', 0)));
    if i = -1 then i := 0;
    Frame.cmbOldValueMode.ItemIndex := i;
    Frame.edOldValue.Text := StorageGetString('sOldValue', Frame.edOldValue.Text);
    Frame.chkOldValueCheckClick(nil);
  except end;

  Frame.fPresets := TJsonObject.Create;
  try Frame.fPresets.FromJSON(StorageGetString('sPresets', cDefaultPresets)); except end;
  with TStringList.Create do try
    for var i := 0 to Pred(Frame.fPresets.Count) do
      Add(Frame.fPresets.Names[i]);
    Sort;
    for var i := 0 to Pred(Count) do
      Frame.AddPreset(Strings[i]);
  finally
    Free;
  end;
end;

procedure TProcUniversalTweaker.OnHide;
begin
  StorageSetString('sBlocks', Frame.edBlocks.Text);
  StorageSetBool('bDescendants', Frame.chkInherited.Checked);
  StorageSetString('sPath', Frame.edPath.Text);
  StorageSetInteger('iValueMode', Integer(Frame.cmbNewValueMode.Items.Objects[Frame.cmbNewValueMode.ItemIndex]));
  StorageSetString('sValue', Frame.edValue.Text);
  StorageSetString('sOldPath', Frame.edOldPath.Text);
  StorageSetBool('bOldValueCheck', Frame.chkOldValueCheck.Checked);
  StorageSetInteger('iOldValueMode', Integer(Frame.cmbOldValueMode.Items.Objects[Frame.cmbOldValueMode.ItemIndex]));
  StorageSetString('sOldValue', Frame.edOldValue.Text);
  StorageSetBool('bReportOnly', Frame.chkReport.Checked);
  if Frame.fPresetsChanged then
    StorageSetString('sPresets', Frame.fPresets.ToJSON(True));

  Frame.fPresets.Free;
end;

procedure TProcUniversalTweaker.OnStart;
begin
  with TStringList.Create do try
    Delimiter := ',';
    StrictDelimiter := True;
    DelimitedText := Frame.edBlocks.Text;
    SetLength(fBlocks, Count);
    for var i := 0 to Pred(Count) do
      fBlocks[i] := Trim(Strings[i]);
  finally
    Free;
  end;

  fInherited := Frame.chkInherited.Checked;

  fPath := Frame.edPath.Text;
  if fPath = '' then
    raise Exception.Create('Field path can not be empty');

  fValueMode := TTweakNewValueMode(Frame.cmbNewValueMode.Items.Objects[Frame.cmbNewValueMode.ItemIndex]);
  fValue := Frame.edValue.Text;
  if (fValueMode = nvmRound) and (fValue = '') then
    fValue := '1';

  fOldValueCheck := Frame.chkOldValueCheck.Checked;
  if fOldValueCheck then begin
    fOldPath := Frame.edOldPath.Text;
    fOldValue := Frame.edOldValue.Text;
  end
  else begin
    fOldPath := '';
    fOldValue := '';
  end;
  fOldValueMode := TTweakOldValueMode(Frame.cmbOldValueMode.Items.Objects[Frame.cmbOldValueMode.ItemIndex]);

  if fValueMode in [nvmAdd, nvmMul, nvmAnd, nvmAndNot, nvmOr, nvmRound] then try
    dfStrToFloat(fValue);
  except
    raise Exception.Create('Value must be a number');
  end;

  if (fValueMode = nvmReplace) and not (fOldValueCheck and (fOldValueMode in [ovmContains, ovmStartsWith, ovmEndsWith, ovmRegExp]) and (fOldValue <> '') ) then
    raise Exception.Create('When replacing, if field must be checked using "Contains", "Starts with", "Ends with" or "Regular Expr" with non-empty value');

  if fOldValueCheck and (fOldValueMode in [ovmGreater, ovmLesser, ovmAnd, ovmAndNot]) then try
    dfStrToFloat(fOldValue);
  except
    raise Exception.Create('Another field''s value must be a number');
  end;

  fReportOnly := Frame.chkReport.Checked;
  fNoOutput := fReportOnly;
end;

function ModifyElement(aBlock: TdfElement;
  const aPath, aValue, aOldPath, aOldValue: string;
  aValueMode: TTweakNewValueMode;
  aOldValueCheck: Boolean;
  aOldValueMode: TTweakOldValueMode;
  Log: TStrings;
  regexp: TPerlRegEx
): Boolean;

  function NativeValue(const p: string): Variant;
  begin
    if p <> '' then
      Result := aBlock.NativeValues[p]
    else
      Result := aBlock.NativeValue;
  end;

  function EditValue(const p: string): string;
  begin
    if p <> '' then
      Result := aBlock.EditValues[p]
    else
      Result := aBlock.EditValue;
  end;

var
  OldValueString, NewValueString: string;
  OldValueFloat, NewValueFloat: Extended;
  OldValue, NewValue: string;
  Matched: Boolean;
begin
  Result := False;
  Matched := False;
  OldValueFloat := 0; NewValueFloat := 0;

  // processing all elements in arrays
  var i := Pos('[*]', aPath);
  if i <> 0 then begin
    aBlock := aBlock.Elements[Copy(aPath, 1, i - 2)];
    if not Assigned(aBlock) then
      Exit;
    var p := Copy(aPath, i + 4, Length(aPath));
    for i := 0 to Pred(aBlock.Count) do
      Result := ModifyElement(aBlock[i], p, aValue, aOldPath, aOldValue, aValueMode, aOldValueCheck, aOldValueMode, Log, regexp) or Result;
    Exit;
  end;

  try
    if aValueMode in MathNew then
      NewValueFloat := NativeValue(aPath)
    else
      NewValueString := EditValue(aPath);
  except Exit; end;

  if aOldValueCheck then begin
    var p := '';
    try
      if aOldPath <> '' then p := aOldPath else p := aPath;
      if aOldValueMode in MathOld then
        OldValueFloat := NativeValue(p)
      else
        OldValueString := EditValue(p);
    except Exit; end;

    // Equal and NotEqual can be used on both string and number values
    // which to use depends on aOldValue
    var EqNumber := False;
    if aOldValueMode in [ovmEqual, ovmNotEqual] then try
      var f: Extended;
      EqNumber := TextToFloat(aOldValue, f);
      if EqNumber then
        OldValueFloat := NativeValue(p);
    except EqNumber := False; end;

    case aOldValueMode of
      ovmEqual:    Matched := (not EqNumber and SameText(OldValueString, aOldValue)) or (EqNumber and SameValue(OldValueFloat, dfStrToFloat(aOldValue)));
      ovmNotEqual: Matched := (not EqNumber and not SameText(OldValueString, aOldValue)) or (EqNumber and not SameValue(OldValueFloat, dfStrToFloat(aOldValue)));
      ovmGreater:  Matched := OldValueFloat > dfStrToFloat(aOldValue);
      ovmLesser:   Matched := OldValueFloat < dfStrToFloat(aOldValue);
      ovmContains: Matched := ContainsText(OldValueString, aOldValue);
      ovmDoesntContain: Matched := not ContainsText(OldValueString, aOldValue);
      ovmStartsWith: Matched := OldValueString.StartsWith(aOldValue, True);
      ovmEndsWith: Matched := OldValueString.EndsWith(aOldValue, True);
      ovmAnd:      Matched := Trunc(OldValueFloat) and Trunc(dfStrToFloat(aOldValue)) <> 0;
      ovmAndNot:   Matched := Trunc(OldValueFloat) and Trunc(dfStrToFloat(aOldValue)) = 0;
      ovmRegExp:   begin
        regexp.Subject := OldValueString;
        regexp.Replacement := aValue;
        Matched := regexp.ReplaceAll;
      end;
    end;

    if not Matched then
      Exit;
  end;

  case aValueMode of
    nvmSet:     NewValue := aValue;
    nvmAdd:     NewValue := dfFloatToStr(NewValueFloat + dfStrToFloat(aValue));
    nvmMul:     NewValue := dfFloatToStr(NewValueFloat * dfStrToFloat(aValue));
    nvmRound:   NewValue := dfFloatToStr(Round(NewValueFloat / dfStrToFloat(aValue)) * dfStrToFloat(aValue));
    nvmMulRound:NewValue := dfFloatToStr(Round(NewValueFloat * dfStrToFloat(aValue)));
    nvmAnd:     NewValue := dfFloatToStr(Trunc(NewValueFloat) and Trunc(dfStrToFloat(aValue)));
    nvmAndNot:  NewValue := dfFloatToStr(Trunc(NewValueFloat) and not Trunc(dfStrToFloat(aValue)));
    nvmOr:      NewValue := dfFloatToStr(Trunc(NewValueFloat) or Trunc(dfStrToFloat(aValue)));
    nvmReplace: case aOldValueMode of
      ovmContains:   NewValue := StringReplace(NewValueString, aOldValue, aValue, [rfReplaceAll, rfIgnoreCase]);
      ovmStartsWith: NewValue := aValue + Copy(NewValueString, Length(aOldValue) + 1, Length(NewValueString));
      ovmEndsWith:   NewValue := Copy(NewValueString, 1, Length(NewValueString) - Length(aOldValue)) + aValue;
      ovmRegExp:     NewValue := regexp.Subject;
    end;
    nvmPrepend: NewValue := aValue + NewValueString;
    nvmAppend : NewValue := NewValueString + aValue;
    nvmRemove : NewValue := StringReplace(NewValueString, aValue, '', [rfIgnoreCase, rfReplaceAll]);
  end;

  // if fractional part is zero (ends with .00000)
  // then remove it in case we are working with int field
  if aValueMode in MathNew then begin
    var z := Copy(dfFloatToStr(1), 2, 100);
    if NewValue.EndsWith(z) then
      NewValue := Copy(NewValue, 1, Length(NewValue) - Length(z));
  end;

  if aPath <> '' then begin
    OldValue := aBlock.EditValues[aPath];
    aBlock.EditValues[aPath] := NewValue;
    NewValue := aBlock.EditValues[aPath];
  end
  else begin
    OldValue := aBlock.EditValue;
    aBlock.EditValue := NewValue;
    NewValue := aBlock.EditValue;
  end;

  Result := OldValue <> NewValue;

  if Assigned(Log) and Result then begin
    var p := aBlock.Path;
    if aPath <> '' then p := p + '\' + aPath;
    Log.Add(#9 + p + ': Changed from "' + OldValue + '" to "' + NewValue + '"');
  end;
end;

function TProcUniversalTweaker.ProcessFile(aFile: TProcFileObject): TBytes;
var
  nif: TwbNifFile;
  BGSM: TwbBGSMFile;
  BGEM: TwbBGEMFile;
  Log: TStringList;
  regexp: TPerlRegEx;
  i: Integer;
  block: TwbNifBlock;
  bChanged, bMatched: Boolean;
  ext: string;
begin
  bChanged := False;
  nif := nil; BGSM := nil; BGEM := nil; Log := nil; regexp := nil; // suppress compiler warning

  if fOldValueCheck and (fOldValueMode = ovmRegExp) then begin
    regexp := TPerlRegEx.Create;
    regexp.Options := [preCaseLess];
    regexp.RegEx := fOldValue;
    regexp.Study;
  end;

  if fReportOnly then
    Log := TStringList.Create;

  ext := ExtractFileExt(aFile.FileName);
  try
    // *.NIF file
    if SameText(ext, '.nif') or SameText(ext, '.kf') then begin
      nif := TwbNifFile.Create;
      nif.LoadFromData(aFile.GetData);

      // processing specific block by path
      if (Length(fBlocks) = 1) and (Pos('\', fBlocks[0]) <> 0) then begin
        block := nif.BlockByPath(fBlocks[0]);
        if not Assigned(block) then
          Exit;

        bChanged := ModifyElement(block, fPath, fValue, fOldPath, fOldValue, fValueMode, fOldValueCheck, fOldValueMode, Log, regexp);
      end

      else begin
        // if processing BSXFlags and it is missing, then add it
        if (nif.NifVersion >= nfTES4) and (Length(fBlocks) <> 0) and (fBlocks[0] = 'BSXFlags') then
          if not Assigned(nif.BlockByType('BSXFlags')) and (nif.BlocksCount <> 0) and nif.RootNode.IsNiObject('NiNode') then
            nif.RootNode.AddExtraData('BSXFlags').EditValues['Name'] := 'BSX';

        // processing blocks by type including NiHeader and NiFooter
        for i := 0 to Pred(nif.Count) do begin
          block := TwbNifBlock(nif[i]);

          bMatched:= False;
          for var s in fBlocks do
            if block.IsNiObject(s, fInherited) then
              bMatched := True;

          if not bMatched and (Length(fBlocks) <> 0) then
            Continue;

          bChanged := ModifyElement(block, fPath, fValue, fOldPath, fOldValue, fValueMode, fOldValueCheck, fOldValueMode, Log, regexp) or bChanged;
        end;
      end;
    end

    // *.BGSM file
    else if SameText(ext, '.bgsm') then begin
      BGSM := TwbBGSMFile.Create;
      BGSM.LoadFromData(aFile.GetData);

      bChanged := ModifyElement(BGSM, fPath, fValue, fOldPath, fOldValue, fValueMode, fOldValueCheck, fOldValueMode, Log, regexp) or bChanged;
    end

    // *.BGEM file
    else if SameText(ext, '.bgem') then begin
      BGEM := TwbBGEMFile.Create;
      BGEM.LoadFromData(aFile.GetData);

      bChanged := ModifyElement(BGEM, fPath, fValue, fOldPath, fOldValue, fValueMode, fOldValueCheck, fOldValueMode, Log, regexp) or bChanged;
    end;

    if bChanged and not fReportOnly then begin
      if Assigned(nif) then nif.SaveToData(Result);
      if Assigned(BGSM) then BGSM.SaveToData(Result);
      if Assigned(BGEM) then BGEM.SaveToData(Result);
    end;

    if bChanged and fReportOnly then begin
      Log.Insert(0, aFile.FileName);
      Log.Add('');
      fManager.AddMessages(Log);
    end;

  finally
    nif.Free;
    BGSM.Free;
    BGEM.Free;
    Log.Free;
    regexp.Free;
  end;

end;

end.
