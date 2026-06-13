unit ProcTransformInfo;

interface

uses
  System.Classes,
  System.SysUtils,

  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,

  SniffProcessor;

type
  TFrameTransformInfo = class(TFrame)
    StaticText1: TStaticText;
    chkTranslation: TCheckBox;
    chkRotation: TCheckBox;
    chkScale: TCheckBox;
    chkSkipEmpty: TCheckBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TProcTransformInfo = class(TProcBase)
  private
    Frame: TFrameTransformInfo;
    fTranslation, fRotation, fScale: Boolean;
    fSkipEmpty: Boolean;
    fRotationEulerOld: Boolean;
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

  wbDataFormat,
  wbDataFormatNif,
  wbDataFormatNifTypes,
  wbNifMath;

constructor TProcTransformInfo.Create(aManager: TProcManager);
begin
  inherited;

  fTitle := 'Transform information';
  fSupportedGames := [gtTES3, gtTES4, gtFO3, gtFNV, gtTES5, gtSSE, gtFO4];
  fExtensions := ['nif'];
  fNoOutput := True;
end;

function TProcTransformInfo.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameTransformInfo.Create(aOwner);
  Result := Frame;
end;

procedure TProcTransformInfo.OnShow;
begin
  Frame.chkTranslation.Checked := StorageGetBool('bTranslation', Frame.chkTranslation.Checked);
  Frame.chkRotation.Checked := StorageGetBool('bRotation', Frame.chkRotation.Checked);
  Frame.chkScale.Checked := StorageGetBool('bScale', Frame.chkScale.Checked);
  Frame.chkSkipEmpty.Checked := StorageGetBool('bSkipEmpty', Frame.chkSkipEmpty.Checked);
  fRotationEulerOld := wbRotationEuler;
end;

procedure TProcTransformInfo.OnHide;
begin
  StorageSetBool('bTranslation', Frame.chkTranslation.Checked);
  StorageSetBool('bRotation', Frame.chkRotation.Checked);
  StorageSetBool('bScale', Frame.chkScale.Checked);
  StorageSetBool('bSkipEmpty', Frame.chkSkipEmpty.Checked);
  wbRotationEuler := fRotationEulerOld;
end;

procedure TProcTransformInfo.OnStart;
begin
  fTranslation := Frame.chkTranslation.Checked;
  fRotation := Frame.chkRotation.Checked;
  fScale := Frame.chkScale.Checked;
  if not (fTranslation or fRotation or fScale) then
    raise Exception.Create('Select options to report');

  fScale := Frame.chkSkipEmpty.Checked;
  wbRotationEuler := True;
end;

function TProcTransformInfo.ProcessFile(aFile: TProcFileObject): TBytes;
var
  nif: TwbNifFile;
  Log: TStringList;
begin
  nif := TwbNifFile.Create;
  Log := TStringList.Create;
  try
    nif.LoadFromData(aFile.GetData);

    for var i := 0 to Pred(nif.BlocksCount) do begin
      var b := nif.Blocks[i];

      if not (b.IsNiObject('NiAVObject') or b.IsNiObject('bhkRigidBodyT')) then
        Continue;

      var path := '';
      if b.IsNiObject('NiAVObject') then begin
        if fSkipEmpty and (b.GetCollision = nil) and (Length(b.ChildrenByType('NiAVObject', True)) = 0) then
          Continue;
        path := 'Transform\';
      end;

      var t: TTransform;
      if not b.GetTransform(t) then
        Continue;

      var infos: array of string;

      if fTranslation and not t.Translation.IsZero then
        // this is vector4 in rigid body, so use XYZ values only
        infos := infos + ['Translation: ' + Format('%s %s %s', [
          b.EditValues[path + 'Translation\X'],
          b.EditValues[path + 'Translation\Y'],
          b.EditValues[path + 'Translation\Z']
        ])];

      if fRotation and not t.Rotation.IsIdentity then
        infos := infos + ['Rotation: ' + b.EditValues[path + 'Rotation']];

      if fScale and not SameValue(RoundTo(t.Scale, -3), 1.0) then
        infos := infos + ['Scale: ' + b.EditValues[path + 'Scale']];

      if Length(infos) <> 0 then
        Log.Add(#9 + b.Name + ': ' + String.Join(#9, infos));
    end;

    if Log.Count > 0 then begin
      Log.Insert(0, aFile.FileName);
      Log.Add('');
      AddMessages(Log);
    end;

  finally
    nif.Free;
    Log.Free;
  end;

end;


end.
