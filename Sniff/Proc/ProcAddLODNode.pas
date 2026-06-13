{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit ProcAddLODNode;

interface

uses
  System.Classes,
  System.SysUtils,

  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,

  SniffProcessor;

type
  TFrameAddLODNode = class(TFrame)
    StaticText1: TStaticText;
    memoExtents: TMemo;
    Label1: TLabel;
    chkRange: TRadioButton;
    chkScreen: TRadioButton;
    Label2: TLabel;
    memoProportions: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TProcAddLODNode = class(TProcBase)
  private
    Frame: TFrameAddLODNode;
    fLODData: string;
    fExtents, fProportions: TArray<Double>;
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
  wbDataFormat,
  wbDataFormatNif;

constructor TProcAddLODNode.Create(aManager: TProcManager);
begin
  inherited;

  fTitle := 'Add NiLODNode';
  fSupportedGames := [gtTES4, gtFO3, gtFNV];
  fExtensions := ['nif'];
end;

function TProcAddLODNode.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameAddLODNode.Create(aOwner);
  Result := Frame;
end;

procedure TProcAddLODNode.OnShow;
begin
  var LODData := StorageGetString('sLODData', 'NiRangeLODData');
  Frame.chkRange.Checked := LODData = 'NiRangeLODData';
  Frame.chkScreen.Checked := LODData = 'NiScreenLODData';
  Frame.memoExtents.Text := StringToText(StorageGetString('sExtents', Frame.memoExtents.Text));
  Frame.memoProportions.Text := StringToText(StorageGetString('sProportions', Frame.memoProportions.Text));
end;

procedure TProcAddLODNode.OnHide;
begin
  var LODData := 'NiRangeLODData';
  if Frame.chkScreen.Checked then LODData := 'NiScreenLODData';
  StorageSetString('sLODData', LODData);
  StorageSetString('sExtents', TextToString(Frame.memoExtents.Text));
  StorageSetString('sProportions', TextToString(Frame.memoProportions.Text));
end;

procedure TProcAddLODNode.OnStart;
var
  f: Double;
begin
  if Frame.chkRange.Checked then fLODData := 'NiRangeLODData';
  if Frame.chkScreen.Checked then fLODData := 'NiScreenLODData';

  fExtents := [0];
  for var i := 0 to Pred(Frame.memoExtents.Lines.Count) do begin
    var s := Trim(Frame.memoExtents.Lines[i]);
    if s = '' then
      Continue;
    try
      f := dfStrToFloat(s);
      fExtents := fExtents + [f];
    except
      raise Exception.CreateFmt('Line %d has invalid extent value %s', [i + 1, s]);
    end;
  end;

  fProportions := [];
  for var i := 0 to Pred(Frame.memoProportions.Lines.Count) do begin
    var s := Trim(Frame.memoProportions.Lines[i]);
    if s = '' then
      Continue;
    try
      f := dfStrToFloat(s);
      fProportions := fProportions + [f];
    except
      raise Exception.CreateFmt('Line %d has invalid proportion value %s', [i + 1, s]);
    end;
  end;
end;

function TProcAddLODNode.ProcessFile(aFile: TProcFileObject): TBytes;
var
  nif: TwbNifFile;
  root, child, LODNode, LODDataNode: TwbNifBlock;
  entries, entry: TdfElement;
  shapes: TList;
begin
  shapes := TList.Create;
  nif := TwbNifFile.Create;
  nif.Options := [nfoCollapseLinkArrays];
  try
    nif.LoadFromData(aFile.GetData);

    if nif.BlocksCount = 0 then
      Exit;

    root := nif.RootNode;
    if root.BlockType <> 'BSFadeNode' then
      Exit;

    entries := root.Elements['Children'];
    if not Assigned(entries)then
      Exit;

    LODNode := nil;
    for var i := 0 to Pred(entries.Count) do begin
      entry := entries[i];
      child := TwbNifBlock(entry.LinksTo);
      if not Assigned(child) then
        Continue;
      // checking for existing NiLODNode block
      if child.BlockType = 'NiLODNode' then
        LODNode := child
      // collecting strips/shapes
      else if child.IsNiObject('NiTriBasedGeom') then
        shapes.Add(entry);
    end;

    if (shapes.Count < 2) and not Assigned(LODNode) then
      Exit;

    if not Assigned(LODNode) then begin
      // inserting NiLODNode at the position of the first shape
      LODNode := nif.InsertBlock(TdfElement(shapes[0]).NativeValue, 'NiLODNode');
      // adding to the root's children
      entries.Add.NativeValue := LODNode.Index;
      LODDataNode := nil;
    end
    else
      LODDataNode := TwbNifBlock(LODNode.Elements['LOD Level Data'].LinksTo);

    // adding LODData
    if not Assigned(LODDataNode) then begin
      LODDataNode := nif.AddBlock(fLODData);
      LODNode.NativeValues['LOD Level Data'] := LODDataNode.Index;
    end
    else if LODDataNode.BlockType <> fLODData then begin
      var i := LODDataNode.Index;
      nif.ConvertBlock(i, fLODData);
      LODDataNode := nif.Blocks[i];
    end;

    // moving shapes under NiLODNode
    for var i := 0 to Pred(shapes.Count) do begin
      LODNode.Elements['Children'].Add.NativeValue := TdfElement(shapes[i]).NativeValue;
      TdfElement(shapes[i]).NativeValue := -1;
    end;

    // filling LODData for NiLODNode children
    var children := LODNode.Elements['Children'];
    for var i := 0 to Pred(children.Count) do begin
      if LODDataNode.BlockType = 'NiRangeLODData' then begin
        entries := LODDataNode.Elements['LOD Levels'];
        if i = 0 then entries.Count := 0;
        entry := entries.Add;
        if i + 1 <= High(fExtents) then begin
          entry.NativeValues['Near Extent'] := fExtents[i];
          entry.NativeValues['Far Extent'] := fExtents[i + 1];
        end;
      end
      else if LODDataNode.BlockType = 'NiScreenLODData' then begin
        entries := LODDataNode.Elements['Proportion Levels'];
        if i = 0 then entries.Count := 0;
        if i <= High(fProportions) then
          entries.Add.NativeValue := fProportions[i];
      end;
    end;

    nif.SaveToData(Result);

  finally
    nif.Free;
    shapes.Free;
  end;

end;


end.
