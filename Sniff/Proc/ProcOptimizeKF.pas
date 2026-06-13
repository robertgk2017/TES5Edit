{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit ProcOptimizeKF;

interface

uses
  System.Classes,
  System.SysUtils,

  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,

  SniffProcessor;

type
  TFrameOptimizeKF = class(TFrame)
    StaticText1: TStaticText;
  end;

  TProcOptimizeKF = class(TProcBase)
  private
    Frame: TFrameOptimizeKF;
  public
    constructor Create(aManager: TProcManager); override;
    function GetFrame(aOwner: TComponent): TFrame; override;

    function ProcessFile(aFile: TProcFileObject): TBytes; override;
  end;


implementation

{$R *.dfm}

uses
  System.StrUtils,

  wbDataFormat,
  wbDataFormatNif;

constructor TProcOptimizeKF.Create(aManager: TProcManager);
begin
  inherited;

  fTitle := 'Optimize Animations';
  fSupportedGames := [gtTES4, gtFO3, gtFNV, gtTES5, gtSSE, gtFO4];
  fExtensions := ['kf', 'nif'];
end;

function TProcOptimizeKF.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameOptimizeKF.Create(aOwner);
  Result := Frame;
end;

function TProcOptimizeKF.ProcessFile(aFile: TProcFileObject): TBytes;

  function KeyValue(aKey: TdfElement): string;
  begin
    Result := aKey.EditValues['Value'];

    if Assigned(aKey.Elements['Forward']) then
      Result := ' ' + aKey.EditValues['Forward'] + ' ' + aKey.EditValues['Backward'];

    if Assigned(aKey.Elements['TBC']) then
      Result := ' ' + aKey.EditValues['TBC\T'] + ' ' + aKey.EditValues['TBC\B'] + ' ' + aKey.EditValues['TBC\C'];

    Result := StringReplace(Result, dfFloatToStr(-0.0), dfFloatToStr(0.0), [rfReplaceAll]);
  end;

  function Optimize(aKeys: TdfElement; const aKeysCount: string = ''): Boolean;
  var
    current, prev, next: string;
    j: Integer;
  begin
    Result := False;

    if not Assigned(aKeys) then
      Exit;

    if aKeys.Count < 3 then
      Exit;

    next := KeyValue(aKeys[aKeys.Count - 1]);
    current := KeyValue(aKeys[aKeys.Count - 2]);

    for j := aKeys.Count - 2 downto 1 do begin
      prev := KeyValue(aKeys[j - 1]);

      if (current = prev) and (current = next) then begin
        aKeys.Delete(j);
        Result := True;
      end;

      next := current;
      current := prev;
    end;

    if Result and (aKeysCount <> '') then
      aKeys.NativeValues[aKeysCount] := aKeys.Count;
  end;

begin
  var bChanged := False;
  var nif := TwbNifFile.Create;
  try
    nif.LoadFromData(aFile.GetData);

    for var block in nif.BlocksByType('NiKeyBasedInterpolator', True) do begin
      var datalink := block.Elements['Data'];
      if not Assigned(datalink) then
        Continue;

      var data := TwbNifBlock(datalink.LinksTo);
      if not Assigned(data) then
        Continue;

      var entries := data.Elements['Quaternion Keys'];
      if Assigned(entries) and Optimize(entries, '..\Num Rotation Keys') then
        bChanged := True;

      entries := data.Elements['Translations\Keys'];
      if Assigned(entries) and Optimize(entries, '..\Num Keys') then
        bChanged := True;

      entries := data.Elements['Scales\Keys'];
      if Assigned(entries) and Optimize(entries, '..\Num Keys') then
        bChanged := True;

      entries := data.Elements['XYZ Rotations'];
      if Assigned(entries) then
        for var j := 0 to Pred(entries.Count) do
          if Optimize(entries[j].Elements['Keys'], '..\Num Keys') then
            bChanged := True;
    end;

    if bChanged then
      nif.SaveToData(Result);

  finally
    nif.Free;
  end;

end;

end.
