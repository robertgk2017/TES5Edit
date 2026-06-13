unit ProcSoftParticles;

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
  TFrameSoftParticles = class(TFrame)
    StaticText1: TStaticText;
    edSoftScale: TLabeledEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TProcSoftParticles = class(TProcBase)
  private
    Frame: TFrameSoftParticles;
    fSoftScale: string;
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

constructor TProcSoftParticles.Create(aManager: TProcManager);
begin
  inherited;

  fTitle := 'Vanilla Plus Particles - NVSE';
  fSupportedGames := [gtFO3, gtFNV];
  fExtensions := ['nif'];
end;

function TProcSoftParticles.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameSoftParticles.Create(aOwner);
  Result := Frame;
end;

procedure TProcSoftParticles.OnShow;
begin
  Frame.edSoftScale.Text := StorageGetString('sSoftScale', Frame.edSoftScale.Text);
end;

procedure TProcSoftParticles.OnHide;
begin
  StorageSetString('sSoftScale', Frame.edSoftScale.Text);
end;

procedure TProcSoftParticles.OnStart;
begin
  fSoftScale := Frame.edSoftScale.Text;
  if fSoftScale <> '' then try
    dfStrToFloat(fSoftScale);
  except
    raise Exception.Create('Invalid float number for soft scale');
  end;
end;

function TProcSoftParticles.ProcessFile(aFile: TProcFileObject): TBytes;
const
  cVPSoftScale = 'VPSoftScale';
var
  nif: TwbNifFile;
  bChanged: Boolean;
begin
  nif := TwbNifFile.Create;
  bChanged := False;

  try
    nif.LoadFromData(aFile.GetData);

    for var block in nif.BlocksByType('NiTriBasedGeom', True) do begin

      if block.IsEditorMarker then
        Continue;

      var shader := block.PropertyByType('BSShaderNoLightingProperty');
      if not Assigned(shader) then
        Continue;

      if not shader.NativeValues['Shader Flags 2\Unknown9'] then begin
        shader.NativeValues['Shader Flags 2\Unknown9'] := 1;
        bChanged := True;
      end;

      if fSoftScale <> '' then begin
        var exdata := block.ExtraDataByName(cVPSoftScale);
        if not Assigned(exdata) then begin
          exdata := block.AddExtraData('NiFloatExtraData');
          exdata.EditValues['Name'] := cVPSoftScale;
          bChanged := True;
        end;

        if not SameValue(dfStrToFloat(exdata.EditValues['Float Data']), dfStrToFloat(fSoftScale)) then begin
          exdata.EditValues['Float Data'] := fSoftScale;
          bChanged := True;
        end;
      end;

    end;

    if bChanged then
      nif.SaveToData(Result);

  finally
    nif.Free;
  end;
end;


end.
