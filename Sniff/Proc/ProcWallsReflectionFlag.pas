unit ProcWallsReflectionFlag;

interface

uses
  System.Classes,
  System.SysUtils,

  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Mask,
  Vcl.StdCtrls,

  SniffProcessor;

type
  TFrameWallsReflectionFlag = class(TFrame)
    StaticText1: TStaticText;
    edMapScale: TLabeledEdit;
    edNormalIntensity: TLabeledEdit;
    edBlendIntensity: TLabeledEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TProcWallsReflectionFlag = class(TProcBase)
  private
    Frame: TFrameWallsReflectionFlag;
    fMapScale: string;
    fNormalIntensity: string;
    fBlendIntensity: string;
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
  wbDataFormatNif;

constructor TProcWallsReflectionFlag.Create(aManager: TProcManager);
begin
  inherited;

  fTitle := 'Real Time Reflections - NVSE';
  fSupportedGames := [gtFO3, gtFNV];
  fExtensions := ['nif'];
end;

function TProcWallsReflectionFlag.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameWallsReflectionFlag.Create(aOwner);
  Result := Frame;
end;

procedure TProcWallsReflectionFlag.OnShow;
begin
  Frame.edMapScale.Text := StorageGetString('sMapScale', Frame.edMapScale.Text);
  Frame.edNormalIntensity.Text := StorageGetString('sNormalIntensity', Frame.edNormalIntensity.Text);
  Frame.edBlendIntensity.Text := StorageGetString('sBlendIntensity', Frame.edBlendIntensity.Text);
end;

procedure TProcWallsReflectionFlag.OnHide;
begin
  StorageSetString('sMapScale', Frame.edMapScale.Text);
  StorageSetString('sNormalIntensity', Frame.edNormalIntensity.Text);
  StorageSetString('sBlendIntensity', Frame.edBlendIntensity.Text);
end;

procedure TProcWallsReflectionFlag.OnStart;
begin
  fMapScale := Frame.edMapScale.Text;
  if fMapScale <> '' then try
    dfStrToFloat(fMapScale);
  except
    raise Exception.Create('Invalid float number for map scale');
  end;

  fNormalIntensity := Frame.edNormalIntensity.Text;
  if fNormalIntensity <> '' then try
    dfStrToFloat(fNormalIntensity);
  except
    raise Exception.Create('Invalid float number for Normal Intensity');
  end;

  fBlendIntensity := Frame.edBlendIntensity.Text;
  if fBlendIntensity <> '' then try
    dfStrToFloat(fBlendIntensity);
  except
    raise Exception.Create('Invalid float number for Blend Intensity');
  end;
end;

function TProcWallsReflectionFlag.ProcessFile(aFile: TProcFileObject): TBytes;

  function AddFloatExtraData(aBlock: TwbNifBlock; const aName, aValue: string): Boolean;
  begin
    Result := False;
    if aValue = '' then
      Exit;

    var exdata := aBlock.ExtraDataByName(aName);
    if not Assigned(exdata) then begin
      exdata := aBlock.AddExtraData('NiFloatExtraData');
      exdata.EditValues['Name'] := aName;
      Result := True;
    end;
    if not SameValue(dfStrToFloat(exdata.EditValues['Float Data']), dfStrToFloat(aValue)) then begin
      exdata.EditValues['Float Data'] := aValue;
      Result := True;
    end;
  end;

var
  nif: TwbNifFile;
  bChanged: Boolean;
begin
  nif := TwbNifFile.Create;
  bChanged := False;

  try
    nif.LoadFromData(aFile.GetData);

    for var block in nif.BlocksByType('NiTriBasedGeom', True) do begin

      var shader := block.PropertyByType('BSShaderPPLightingProperty');
      if not Assigned(shader) then
        Continue;

      if not shader.NativeValues['Shader Flags 1\Environment_Mapping'] then
        Continue;

      if shader.NativeValues['Shader Flags 2\Envmap_Light_Fade'] or not shader.NativeValues['Shader Flags 2\Unknown10'] then begin
        shader.NativeValues['Shader Flags 2\Envmap_Light_Fade'] := 0;
        shader.NativeValues['Shader Flags 2\Unknown10'] := 1;
        bChanged := True;
      end;

      if (fMapScale <> '') and not SameValue(dfStrToFloat(shader.EditValues['Environment Map Scale']), dfStrToFloat(fMapScale)) then begin
        shader.EditValues['Environment Map Scale'] := fMapScale;
        bChanged := True;
      end;

      bChanged := AddFloatExtraData(block, 'NormalIntensity', fNormalIntensity) or bChanged;
      bChanged := AddFloatExtraData(block, 'BlendIntensity', fBlendIntensity) or bChanged;
    end;

    if bChanged then
      nif.SaveToData(Result);

  finally
    nif.Free;
  end;
end;



end.
