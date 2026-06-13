unit ProcHavokSearchMaterial;

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
  TFrameHavokMaterial = class(TFrame)
    StaticText1: TStaticText;
    cmbSearch: TComboBox;
    cmbReplace: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    edSearch: TLabeledEdit;
    edReplace: TLabeledEdit;
    rbTES4: TRadioButton;
    rbFO3: TRadioButton;
    rbTES5: TRadioButton;
    chkSkipRoot: TCheckBox;
    procedure rbTES5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Proc: TProcBase;
  end;

  TProcHavokSearchMaterial = class(TProcBase)
  private
    Frame: TFrameHavokMaterial;
    fMaterialSearch: string;
    fMaterialReplace: string;
    fSkipRoot: Boolean;
  public
    slMaterial: TStringList;
    Ready: Boolean;

    constructor Create(aManager: TProcManager); override;
    destructor Destroy; override;
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
  wbDataFormatNif,
  wbDataFormatNifTypes;

procedure TFrameHavokMaterial.rbTES5Click(Sender: TObject);
var
  prefix: string;
begin
  if not TProcHavokSearchMaterial(Proc).Ready then
    Exit;

  if rbTES5.Checked then prefix := 'SKY_' else
  if rbFO3.Checked then prefix := 'FO_' else
  if rbTES4.Checked then prefix := 'OB_';

  var mats := TProcHavokSearchMaterial(Proc).slMaterial;
  var f1 := UpperCase(Trim(edSearch.Text));
  var f2 := UpperCase(Trim(edReplace.Text));

  cmbSearch.Items.BeginUpdate;
  cmbReplace.Items.BeginUpdate;
  try
    if (Sender is TRadioButton) or (Sender = edSearch) then cmbSearch.Items.Clear;
    if (Sender is TRadioButton) or (Sender = edReplace) then cmbReplace.Items.Clear;
    for var i := 0 to Pred(mats.Count) do begin
      var mat := mats[i];
      if (Sender = nil) or (Sender is TRadioButton) or (Sender = edSearch) then
        if (mat = '') or ( mat.StartsWith(prefix) and ((f1 = '') or mat.Contains(f1)) ) then
          cmbSearch.Items.AddObject(mat, mats.Objects[i]);
      if (Sender = nil) or (Sender is TRadioButton) or (Sender = edReplace) then
        if (mat = '') or ( mat.StartsWith(prefix) and ((f2 = '') or mat.Contains(f2)) ) then
          cmbReplace.Items.AddObject(mat, mats.Objects[i]);
    end;
  finally
    cmbSearch.Items.EndUpdate;
    cmbReplace.Items.EndUpdate;
  end;

  if Sender = nil then cmbSearch.ItemIndex := 0;
  if Sender = nil then cmbReplace.ItemIndex := 0;

  if (Sender = edSearch) and not cmbSearch.DroppedDown then
    cmbSearch.DroppedDown := True;
  if (Sender = edReplace) and not cmbReplace.DroppedDown then
    cmbReplace.DroppedDown := True;
end;

constructor TProcHavokSearchMaterial.Create(aManager: TProcManager);
var
  i: Integer;
begin
  inherited;

  fTitle := 'Search for Havok material';
  fSupportedGames := [gtTES4, gtFO3, gtFNV, gtTES5, gtSSE];
  fExtensions := ['nif'];

  slMaterial := TStringList.Create;
  with TdfEnumDef(wbOblivionHavokMaterial('', '', [])) do try
    for i := 0 to Pred(ValuesMapCount) do
      slMaterial.Add(Values[i]);
  finally
    Free;
  end;
  with TdfEnumDef(wbFallout3HavokMaterial('', '', [])) do try
    for i := 0 to Pred(ValuesMapCount) do
      slMaterial.Add(Values[i]);
  finally
    Free;
  end;
  with TdfEnumDef(wbSkyrimHavokMaterial('', '', [])) do try
    for i := 0 to Pred(ValuesMapCount) do
      slMaterial.Add(Values[i]);
  finally
    Free;
  end;
  slMaterial.Sort;
  slMaterial.Insert(0, '');
end;

destructor TProcHavokSearchMaterial.Destroy;
begin
  slMaterial.Free;
end;

function TProcHavokSearchMaterial.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameHavokMaterial.Create(aOwner);
  Frame.Proc := Self;
  Result := Frame;
end;

procedure TProcHavokSearchMaterial.OnShow;
var
  i: Integer;
begin
  Ready := False;
  i := StorageGetInteger('iGame', 2);
  if i = 0 then Frame.rbTES4.Checked := True else
  if i = 1 then Frame.rbFO3.Checked := True else
    Frame.rbTES5.Checked := True;
  Frame.chkSkipRoot.Checked := StorageGetBool('bSkipRoot', Frame.chkSkipRoot.Checked);
  Frame.edSearch.Text := StorageGetString('sFilterSearch', Frame.edSearch.Text);
  Frame.edReplace.Text := StorageGetString('sFilterReplace', Frame.edReplace.Text);
  Ready := True;
  Frame.rbTES5Click(nil);

  i := Frame.cmbSearch.Items.IndexOf(StorageGetString('sMaterialSearch', ''));
  if i <> -1 then Frame.cmbSearch.ItemIndex := i;
  i := Frame.cmbReplace.Items.IndexOf(StorageGetString('sMaterialReplace', ''));
  if i <> -1 then Frame.cmbReplace.ItemIndex := i;
end;

procedure TProcHavokSearchMaterial.OnHide;
var
  i: Integer;
begin
  if Frame.rbTES4.Checked then i := 0 else
  if Frame.rbFO3.Checked then i := 1 else
    i := 2;
  StorageSetInteger('iGame', i);
  StorageSetBool('bSkipRoot', Frame.chkSkipRoot.Checked);
  StorageSetString('sMaterialSearch', Frame.cmbSearch.Text);
  StorageSetString('sFilterSearch', Frame.edSearch.Text);
  StorageSetString('sMaterialReplace', Frame.cmbReplace.Text);
  StorageSetString('sFilterReplace', Frame.edReplace.Text);
end;

procedure TProcHavokSearchMaterial.OnStart;
begin
  fMaterialSearch := Frame.cmbSearch.Text;
  fMaterialReplace := Frame.cmbReplace.Text;
  fSkipRoot := Frame.chkSkipRoot.Checked;
  fNoOutput := fMaterialReplace = '';

  if (fMaterialSearch = fMaterialReplace) and (fMaterialSearch <> '') then
    raise Exception.Create('Searched and replacing materials must be different');
end;

function TProcHavokSearchMaterial.ProcessFile(aFile: TProcFileObject): TBytes;

  procedure UpdateField(const el: TdfElement; const aValue: string; var aChanged: Boolean);
  begin
    if not Assigned(el) or (aValue = '') then
      Exit;

    if el.EditValue <> aValue then begin
      el.EditValue := aValue;
      aChanged := True;
    end;
  end;

  function GetTarget(aBlock: TwbNifBlock): TwbNifBlock;
  begin
    Result := nil;
    if aBlock.IsNiObject('bhkCollisionObject') then
      Result := TwbNifBlock(aBlock.Elements['Target'].LinksTo)
    else
    for var ref in aBlock.ReferencedBy do begin
      var refblock := ref;
      while not (refblock is TwbNifBlock) do refblock := refblock.Parent;
      Result := GetTarget(TwbNifBlock(refblock));
      Break;
    end;
  end;

var
  nif: TwbNifFile;
  i: Integer;
  block, root: TwbNifBlock;
  bChanged: Boolean;
  Log: TStringList;
begin
  bChanged := False;
  Log := TStringList.Create;
  nif := TwbNifFile.Create;
  try
    nif.LoadFromData(aFile.GetData);
    root := nif.RootNode;

    for i := 0 to Pred(nif.BlocksCount) do begin
      block := nif.Blocks[i];

      if (block.BlockType = 'hkPackedNiTriStripsData') or (block.BlockType = 'bhkCompressedMeshShapeData') then begin
        if fSkipRoot and (GetTarget(block) = root) then
          Continue;

        var subshapes := block.Elements['Sub Shapes'];
        if not Assigned(subshapes) then
          subshapes := block.Elements['Chunk Materials'];
        if not Assigned(subshapes) then
          Continue;

        for var j := 0 to Pred(subshapes.Count) do begin
          var subshape := subshapes[j];
          if (fMaterialSearch <> '') and (subshape.EditValues['Material'] <> fMaterialSearch) then
            Continue;
          if fMaterialReplace = '' then
            Log.Add(#9 + subshape.Path + ': ' + subshape.EditValues['Material'])
          else
            UpdateField(subshape.Elements['Material'], fMaterialReplace, bChanged);
        end;
      end

      else if block.IsNiObject('bhkShape', True) then begin
        if fSkipRoot and (GetTarget(block) = root) then
          Continue;

        if block.EditValues['Material'] = '' then
          Continue;

        if (fMaterialSearch <> '') and (block.EditValues['Material'] <> fMaterialSearch) then
          Continue;

        if fMaterialReplace = '' then
          Log.Add(#9 + block.Name + ': ' + block.EditValues['Material'])
        else
          UpdateField(block.Elements['Material'], fMaterialReplace, bChanged);
      end;

    end;

    if Log.Count > 0 then begin
      Log.Insert(0, aFile.FileName);
      Log.Add('');
      AddMessages(Log);
    end;

    if bChanged then
      nif.SaveToData(Result);

  finally
    Log.Free;
    nif.Free;
  end;

end;


end.
