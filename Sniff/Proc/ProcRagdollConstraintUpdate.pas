{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit ProcRagdollConstraintUpdate;

interface

uses
  System.Classes,
  System.SysUtils,

  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,

  SniffProcessor;

type
  TFrameRagdollConstraintUpdate = class(TFrame)
    StaticText1: TStaticText;
    chkConvertToMalleable: TCheckBox;
  end;

  TProcRagdollConstraintUpdate = class(TProcBase)
  private
    Frame: TFrameRagdollConstraintUpdate;
    fConvert: Boolean;
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

constructor TProcRagdollConstraintUpdate.Create(aManager: TProcManager);
begin
  inherited;

  fTitle := 'Update ragdoll constraint';
  fSupportedGames := [gtFO3, gtFNV, gtTES5, gtSSE];
  fExtensions := ['nif'];
end;

function TProcRagdollConstraintUpdate.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameRagdollConstraintUpdate.Create(aOwner);
  Result := Frame;
end;

procedure TProcRagdollConstraintUpdate.OnShow;
begin
  Frame.chkConvertToMalleable.Checked := StorageGetBool('bConvert', Frame.chkConvertToMalleable.Checked);
end;

procedure TProcRagdollConstraintUpdate.OnHide;
begin
  StorageSetBool('bConvert', Frame.chkConvertToMalleable.Checked);
end;

procedure TProcRagdollConstraintUpdate.OnStart;
begin
  fConvert := Frame.chkConvertToMalleable.Checked;
end;

function TProcRagdollConstraintUpdate.ProcessFile(aFile: TProcFileObject): TBytes;

  function CalcUpdate(Twist, Plane, Motor: TdfElement): Boolean;
  var
    x, y, z: Single;
  begin
    Result := False;

    if not Assigned(Twist) or not Assigned(Plane) or not Assigned(Motor) then
      Exit;

    x := Twist.NativeValues['Y'] * Plane.NativeValues['Z'] - Twist.NativeValues['Z'] * Plane.NativeValues['Y'];
    y := Twist.NativeValues['Z'] * Plane.NativeValues['X'] - Twist.NativeValues['X'] * Plane.NativeValues['Z'];
    z := Twist.NativeValues['X'] * Plane.NativeValues['Y'] - Twist.NativeValues['Y'] * Plane.NativeValues['X'];

    Result :=
      not SameValue(Motor.NativeValues['X'], x) or
      not SameValue(Motor.NativeValues['Y'], y) or
      not SameValue(Motor.NativeValues['Z'], z);

    if Result then begin
      Motor.NativeValues['X'] := x;
      Motor.NativeValues['Y'] := y;
      Motor.NativeValues['Z'] := z;
    end;
  end;

var
  nif: TwbNifFile;
  i: Integer;
  Constraint: TwbNifBlock;
  ragdoll: TdfElement;
  bChanged: Boolean;
begin
  bChanged := False;
  nif := TwbNifFile.Create;
  try
    nif.LoadFromData(aFile.GetData);

    for i := 0 to Pred(nif.BlocksCount) do begin
      Constraint := nif.Blocks[i];

      if fConvert and (
        (Constraint.BlockType = 'bhkBallAndSocketConstraint') or
        (Constraint.BlockType = 'bhkHingeConstraint') or
        (Constraint.BlockType = 'bhkLimitedHingeConstraint') or
        (Constraint.BlockType = 'bhkPrismaticConstraint') or
        (Constraint.BlockType = 'bhkRagdollConstraint') or
        (Constraint.BlockType = 'bhkStiffSpringConstraint')
      ) then begin
        nif.ConvertBlock(i, 'bhkMalleableConstraint');
        Constraint := nif.Blocks[i];
        bChanged := True;
      end;

      if Constraint.BlockType = 'bhkRagdollConstraint' then
        ragdoll := Constraint.Elements['Ragdoll']
      else if (Constraint.BlockType = 'bhkMalleableConstraint') and (Constraint.EditValues['Hinge\Type'] = 'Ragdoll') then
        ragdoll := Constraint.Elements['Hinge\Ragdoll']
      else
        Continue;

      bChanged := CalcUpdate(
        ragdoll.Elements['Twist A'],
        ragdoll.Elements['Plane A'],
        ragdoll.Elements['Motor A']
      ) or bChanged;

      bChanged := CalcUpdate(
        ragdoll.Elements['Twist B'],
        ragdoll.Elements['Plane B'],
        ragdoll.Elements['Motor B']
      ) or bChanged;
    end;

    if bChanged then
      nif.SaveToData(Result);
  finally
    nif.Free;
  end;
end;

end.
