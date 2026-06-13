unit ProcMergeProperties;

interface

uses
  System.Classes,
  System.SysUtils,

  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,

  SniffProcessor;

type
  TFrameMergeProperties = class(TFrame)
    StaticText1: TStaticText;
    lvProps: TListView;
    chkIgnoreName: TCheckBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TProcMergeProperties = class(TProcBase)
  private
    Frame: TFrameMergeProperties;
    fBlocks: array of string;
    fIgnoreName: Boolean;
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
  JsonDataObjects,

  wbDataFormat,
  wbDataFormatNif;

constructor TProcMergeProperties.Create(aManager: TProcManager);
begin
  inherited;

  fTitle := 'Merge properties';
  fSupportedGames := [gtTES3, gtTES4, gtFO3, gtFNV, gtTES5, gtSSE, gtFO4];
  fExtensions := ['nif'];
end;

function TProcMergeProperties.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameMergeProperties.Create(aOwner);
  Result := Frame;
end;

procedure TProcMergeProperties.OnShow;
var
  blocks, sl: TStringList;
begin
  Frame.chkIgnoreName.Checked := StorageGetBool('bIgnoreName', Frame.chkIgnoreName.Checked);
  blocks := TStringList.Create;
  sl := TStringList.Create;
  try
    blocks.CommaText := StorageGetString('sBlocks', 'BSShaderTextureSet,NiMaterialProperty');
    for var s in wbNiObjectList do
      if (s = 'BSShaderTextureSet') or ((s <> 'NiProperty') and wbIsNiObject(s, 'NiProperty') and not wbIsNiObject(s, 'NiShadeProperty')) then
        sl.Add(s);
    sl.Sort;

    for var i := 0 to Pred(sl.Count) do
      with Frame.lvProps.Items.Add do begin
        Caption := sl[i];
        Checked := blocks.IndexOf(sl[i]) <> -1;
      end;
  finally
    blocks.Free;
    sl.Free;
  end;
end;

procedure TProcMergeProperties.OnHide;
begin
  StorageSetBool('bIgnoreName', Frame.chkIgnoreName.Checked);
  with TStringList.Create do try
    for var i := 0 to Pred(Frame.lvProps.Items.Count) do
      if Frame.lvProps.Items[i].Checked then
        Add(Frame.lvProps.Items[i].Caption);
    StorageSetString('sBlocks', CommaText);
  finally
    Free;
  end;
end;

procedure TProcMergeProperties.OnStart;
begin
  fIgnoreName := Frame.chkIgnoreName.Checked;
  SetLength(fBlocks, 0);
  for var i := 0 to Pred(Frame.lvProps.Items.Count) do
    if Frame.lvProps.Items[i].Checked then
      fBlocks := fBlocks + [Frame.lvProps.Items[i].Caption];

  if Length(fBlocks) = 0 then
    raise Exception.Create('Select properties to merge');
end;

function TProcMergeProperties.ProcessFile(aFile: TProcFileObject): TBytes;
var
  nif: TwbNifFile;
  block: TwbNifBlock;
  js: TJsonObject;
  props: TStringList;
  token: string;
  bChanged, bFound: Boolean;

  procedure UnlinkBlock(aBlock: TwbNifBlock);
  begin
    for var i := 0 to Pred(nif.BlocksCount) do begin
      var b := nif.Blocks[i];
      for var j := 0 to Pred(b.RefsCount) do
        if TwbNifBlock(b.Refs[j].LinksTo) = aBlock then
          b.Refs[j].NativeValue := -1;
    end;
  end;

begin
  bChanged := False;
  nif := TwbNifFile.Create;
  nif.Options := [nfoCollapseLinkArrays, nfoRemoveUnusedStrings];
  js := TJsonObject.Create;
  props := TStringList.Create;
  try
    nif.LoadFromData(aFile.GetData);

    // in reverse order because we are goint to remove some
    for var i := Pred(nif.BlocksCount) downto 0 do begin
      block := nif.Blocks[i];

      bFound := False;
      for var b in fBlocks do begin
        bFound := block.BlockType = b;
        if bFound then Break;
      end;
      if not bFound then Continue;

      for var el in block do begin
        if fIgnoreName and (el.Def.Name = 'Name') then
          Continue;
        // unused fields
        if (nif.NifVersion >= nfFO3) and (block.BlockType = 'NiMaterialProperty') and (el.Def.Name = 'Specular Color') then
          Continue;

        el.SerializeToJSON(js);
      end;
      token := block.BlockType + ' ' + js.ToJSON;
      js.Clear;

      var j := props.IndexOf(token);
      if j <> -1 then begin
        var idx := TwbNifBlock(props.Objects[j]).Index;
        // relink to the matched prop and remove
        for var ref in block.ReferencedBy do
          ref.NativeValue := idx;
        block.RemoveBranch;
        bChanged := True;
      end else
        props.AddObject(token, block);
    end;

    if bChanged then
      nif.SaveToData(Result);

  finally
    nif.Free;
    js.Free;
    props.Free;
  end;

end;


end.
