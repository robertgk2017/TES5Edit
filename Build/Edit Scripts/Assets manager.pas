{
  Assets manager.

  Allows to check existence of used assets including textures, materials, etc. in meshes,
  and copy assets used by a plugin to separate folder or create a list of files in different formats
  including the CK assets list used for packaging using CK.

  Please keep in mind that the script checks only explicitly used assets defined in records.
  Implicitly used assets are not processed and you need to handle them yourself, for example:
    - voice files
    - worldspace LOD files
    - animations *.kf and behaviours *.hkx
}
unit AssetsManager;

const
  // work mode
  wmNone = 0;
  wmCheck = 1;
  wmList = 2;
  wmListCSV = 3;
  wmListJSON = 4;
  wmCopy = 5;

  // records to skip without assets
  sSkipSignatures = 'DIAL,DLBR,DLVW,DOBJ,FLST,GLOB,GMST,LAND,LCTN,LVLI,LVLN,NAVI,NAVM,PGRD';
  // ref signatures
  sRefSignatures = 'REFR,ACHR,ACRE,PARW,PBAR,PBEA,PCON,PFLA,PGRE,PHZD,PMIS';
  // records without models/icons
  sNoModels = sRefSignatures + ',CELL,LAND,NAVI,NAVM,PGRD';
  // TES4: ICON image is an interface one
  sTES4IconSigs = 'ALCH,AMMO,ARMO,BOOK,CLOT,INGR,KEYM,LIGH,MGEF,MISC,QUST,SGST,SLGM,WEAP';

var
  slAssetsType, sl, slRes, slDump: TStringList;
  slContainers, slTextures, slChecksum: TStringList;
  NifCache: TJsonObject;
  CurrentRecord: IInterface;
  optAsset, optMode, PexSource: integer;
  optPath: string;
  ResDescrPrefix: string;
  ChecksumsFileName: string;
  bSkipChecksum: boolean;

  frm: TForm;
  lbl: TLabel;
  clbAssets, clbContainers: TCheckListBox;
  mnPopup: TPopupMenu;
  MenuItem: TMenuItem;
  rbModeCheck, rbModeList, rbModeCopy: TRadioButton;
  rgList: TRadioGroup;
  edPath: TLabeledEdit;
  chkSkipChecksums: TCheckBox;
  btnChecksums, btnPath, btnOk, btnCancel: TButton;


//===========================================================================
procedure GetTexturesFromMaterial(aFileName: string; sl: TStringList);
var
  bgsm: TwbBGSMFile;
  bgem: TwbBGEMFile;
  i: integer;
  el: TdfElement;
begin
  if SameText(ExtractFileExt(aFileName), '.bgsm') then begin
    bgsm := TwbBGSMFile.Create;
    bgsm.LoadFromResource(aFileName);
    el := bgsm.Elements['Textures'];
    if Assigned(el) then
      for i := 0 to Pred(el.Count) do
        sl.Add(wbNormalizeResourceName(el[i].EditValue, atTexture));
    bgsm.Free;
  end
  else if SameText(ExtractFileExt(aFileName), '.bgem') then begin
    bgem := TwbBGEMFile.Create;
    bgem.LoadFromResource(aFileName);
    el := bgem.Elements['Textures'];
    if Assigned(el) then
      for i := 0 to Pred(el.Count) do
        sl.Add(wbNormalizeResourceName(el[i].EditValue, atTexture));
    bgem.Free;
  end
end;

//===========================================================================
procedure GetNifAssets(aFileName: string; sl: TStringList);
var
  nif: TwbNifFile;
  i, cnt, atype: integer;
begin
  nif := TwbNifFile.Create;
  try
    nif.LoadFromResource(aFileName);
    nif.GetAssetsList(sl);
    cnt := sl.Count;
    for i := 0 to Pred(cnt) do begin
      atype := AssetTypeByExtension(sl[i]);
      sl[i] := wbNormalizeResourceName(sl[i], AssetTypeByExtension(sl[i]));
      if atype = atMaterial then
        GetTexturesFromMaterial(sl[i], sl);
    end;
  finally
    nif.Free;
  end;
end;

//===========================================================================
procedure PopupMenuClick(Sender: TObject);
begin
  if TMenuItem(Sender).Tag = 1 then
    clbContainers.CheckAll(cbChecked, False, False)
  else
    clbContainers.CheckAll(cbUnChecked, False, False);
end;

//===========================================================================
procedure rbModeClick(Sender: TObject);
begin
  rgList.Enabled := rbModeList.Checked;
  edPath.Enabled := rbModeCopy.Checked;
  btnPath.Enabled := rbModeCopy.Checked;
  chkSkipChecksums.Enabled := rbModeCopy.Checked and FileExists(ChecksumsFileName);
end;

//===========================================================================
procedure btnPathClick(Sender: TObject);
var
  s: string;
begin
  s := SelectDirectory('Destination path to copy files to', '', edPath.Text, nil);
  if s <> '' then
    edPath.Text := s;
end;

//===========================================================================
procedure btnChecksumsClick(Sender: TObject);
var
  i, j: integer;
  cont, fname: string;
  slAssets: TStringList;
begin
  if MessageDlg('Build checksums index of files from selected containers? Warning: this can take some time, wait for a message box to appear.', mtConfirmation, [mbOk, mbCancel], 0) <> mrOk then
    Exit;

  slAssets := TStringList.Create;
  slChecksum.Clear;
  for i := 0 to Pred(clbContainers.Items.Count) do begin
    if not clbContainers.Checked[i] then
      Continue;
    cont := slContainers[i];
    AddMessage('Building index for ' + clbContainers.Items[i]);
    slAssets.Clear;
    ResourceList(cont, slAssets);
    for j := 0 to Pred(slAssets.Count) do begin
      fname := slAssets[j];
      // index only valid assets
      if AssetTypeByExtension(fname) <> atNone then try
        slChecksum.Values[fname] := IntToHex(wbCRC32Data(ResourceOpenData(cont, fname)), 8);
      except
        AddMessage('Error reading file ' + fname + ' from ' + cont);
        Exit;
      end;
    end;
  end;
  if slChecksum.Count > 0 then begin
    slChecksum.SaveToFile(ChecksumsFileName);
    chkSkipChecksums.Enabled := rbModeCopy.Checked;
    ShowMessage(Format('%d files were indexed.', [slChecksum.Count]));
  end else
    ShowMessage('Nothing to index.');
  slAssets.Free;
end;

//===========================================================================
// on key down event handler for form
procedure frmFormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    TForm(Sender).ModalResult := mrCancel;
end;

//===========================================================================
// on close event handler for form
procedure frmFormClose(Sender: TObject; var Action: TCloseAction);
begin
  if frm.ModalResult <> mrOk then Exit;
  if rbModeCopy.Checked and not DirectoryExists(edPath.Text) then begin
    MessageDlg('Please select existing destination folder', mtInformation, [mbOk], 0);
    Action := caNone;
  end;
end;

//===========================================================================
procedure ShowOptions;
var
  i: integer;
begin
  frm := TForm.Create(nil);
  try
    frm.Caption := wbGameName + ' Assets Manager';
    frm.Width := frm.ScaleValue(525);
    frm.Height := frm.ScaleValue(460);
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;
    frm.PopupMode := pmAuto;
    frm.KeyPreview := True;
    frm.OnKeyDown := frmFormKeyDown;
    frm.OnClose := frmFormClose;

    clbAssets := TCheckListBox.Create(frm);
    clbAssets.Parent := frm;
    clbAssets.Top := clbAssets.ScaleValue(15);
    clbAssets.Left := clbAssets.ScaleValue(5);
    clbAssets.Width := clbAssets.ScaleValue(185);
    clbAssets.Height := clbAssets.ScaleValue(155);
    clbAssets.Items.AddStrings(slAssetsType);
    clbAssets.CheckAll(cbChecked, False, False);

    lbl := TLabel.Create(frm);
    lbl.Parent := frm;
    lbl.Top := clbAssets.Top - lbl.ScaleValue(18);
    lbl.Left := clbAssets.Left;
    lbl.Caption := 'Processed assets';

    clbContainers := TCheckListBox.Create(frm);
    clbContainers.Parent := frm;
    clbContainers.Top := clbAssets.Top + clbAssets.Height + clbContainers.ScaleValue(15);
    clbContainers.Left := clbAssets.Left;
    clbContainers.Width := clbAssets.Width;
    clbContainers.Height := clbContainers.ScaleValue(215);
    for i := 0 to Pred(slContainers.Count) do
      clbContainers.Items.Add(SimpleName(slContainers[i]));
    clbContainers.CheckAll(cbChecked, False, False);

    lbl := TLabel.Create(frm);
    lbl.Parent := frm;
    lbl.Top := clbContainers.Top - lbl.ScaleValue(18);
    lbl.Left := clbContainers.Left;
    lbl.Caption := 'Processed containers';

    mnPopup := TPopupMenu.Create(frm);
    clbContainers.PopupMenu := mnPopup;
    MenuItem := TMenuItem.Create(mnPopup);
    MenuItem.Caption := 'Select All';
    MenuItem.OnClick := PopupMenuClick;
    MenuItem.Tag := 1;
    mnPopup.Items.Add(MenuItem);
    MenuItem := TMenuItem.Create(mnPopup);
    MenuItem.Caption := 'Select None';
    MenuItem.OnClick := PopupMenuClick;
    mnPopup.Items.Add(MenuItem);

    rbModeCheck := TRadioButton.Create(frm);
    rbModeCheck.Parent := frm;
    rbModeCheck.Top := clbAssets.Top;
    rbModeCheck.Left := clbAssets.Left + clbAssets.Width + rbModeCheck.ScaleValue(5);
    rbModeCheck.Width := rbModeCheck.ScaleValue(155);
    rbModeCheck.Font.Style := [fsBold];
    rbModeCheck.Caption := 'Check for missing assets';
    rbModeCheck.Checked := True;
    rbModeCheck.OnClick := rbModeClick;

    lbl := TLabel.Create(frm);
    lbl.Parent := frm;
    lbl.AutoSize := False;
    lbl.Wordwrap := True;
    lbl.Top := rbModeCheck.Top + lbl.ScaleValue(15);
    lbl.Left := rbModeCheck.Left + lbl.ScaleValue(5);
    lbl.Width := lbl.ScaleValue(290);
    lbl.Height := lbl.ScaleValue(50);
    lbl.Caption := 'Process all selected records and check referenced asset files for existence in selected containers. Useful to find out if all required files are present for particular mod.';

    rbModeList := TRadioButton.Create(frm);
    rbModeList.Parent := frm;
    rbModeList.Top := rbModeCheck.Top + rbModeList.ScaleValue(70);
    rbModeList.Left := rbModeCheck.Left;
    rbModeList.Width := rbModeList.ScaleValue(140);
    rbModeList.Font.Style := [fsBold];
    rbModeList.Caption := 'List referenced assets';
    rbModeList.OnClick := rbModeClick;

    lbl := TLabel.Create(frm);
    lbl.Parent := frm;
    lbl.AutoSize := False;
    lbl.Wordwrap := True;
    lbl.Top := rbModeList.Top + lbl.ScaleValue(15);
    lbl.Left := rbModeList.Left + lbl.ScaleValue(5);
    lbl.Width := lbl.ScaleValue(310);
    lbl.Height := lbl.ScaleValue(35);
    lbl.Caption := 'List asset files referenced by selected records. All assets are shown no matter if they exist in selected containers or not.';

    rgList := TRadioGroup.Create(frm);
    rgList.Parent := frm;
    rgList.Top := rbModeList.Top + rgList.ScaleValue(50);
    rgList.Left := rbModeList.Left + rgList.ScaleValue(5);
    rgList.Height := rgList.ScaleValue(65);
    rgList.Width := rgList.ScaleValue(115);
    rgList.Items.Text := 'to Messages Tab'#13'to CSV file'#13'to CK import file';
    rgList.ItemIndex := 0;

    rbModeCopy := TRadioButton.Create(frm);
    rbModeCopy.Parent := frm;
    rbModeCopy.Top := rgList.Top + rgList.Height + rbModeCopy.ScaleValue(5);
    rbModeCopy.Left := rbModeCheck.Left;
    rbModeCopy.Width := rbModeCopy.ScaleValue(150);
    rbModeCopy.Font.Style := [fsBold];
    rbModeCopy.Caption := 'Copy referenced assets';
    rbModeCopy.OnClick := rbModeClick;

    lbl := TLabel.Create(frm);
    lbl.Parent := frm;
    lbl.AutoSize := False;
    lbl.Wordwrap := True;
    lbl.Top := rbModeCopy.Top + lbl.ScaleValue(15);
    lbl.Left := rbModeCopy.Left + lbl.ScaleValue(5);
    lbl.Width := lbl.ScaleValue(300);
    lbl.Height := lbl.ScaleValue(100);
    lbl.Caption := 'Copy assets used in a mod to the separate destination folder retaining directory structure. Useful to package mod for distribution. You might want to deselect the game''s BSA archives to avoid copying vanilla files. Existing files in destination folder are not overwritten.';

    edPath := TLabeledEdit.Create(frm);
    edPath.Parent := frm;
    edPath.Left := lbl.Left;
    edPath.Top := lbl.Top + lbl.Height;
    edPath.Width := edPath.ScaleValue(275);
    edPath.LabelPosition := lpAbove;
    edPath.EditLabel.Caption := 'Destination folder';

    btnPath := TButton.Create(frm);
    btnPath.Parent := frm;
    btnPath.Top := edPath.Top;
    btnPath.Left := edPath.Left + edPath.Width + btnPath.ScaleValue(3);
    btnPath.Width := btnPath.ScaleValue(35);
    btnPath.Height := btnPath.ScaleValue(22);
    btnPath.Caption := '...';
    btnPath.OnClick := btnPathClick;

    chkSkipChecksums := TCheckBox.Create(frm);
    chkSkipChecksums.Parent := frm;
    chkSkipChecksums.Top := edPath.Top + edPath.Height;
    chkSkipChecksums.Left := edPath.Left;
    chkSkipChecksums.Width := chkSkipChecksums.ScaleValue(250);
    chkSkipChecksums.Height := chkSkipChecksums.ScaleValue(20);
    chkSkipChecksums.Caption := 'Skip copying files with matching checksums';

    lbl := TLabel.Create(frm);
    lbl.Parent := frm;
    lbl.AutoSize := False;
    lbl.Wordwrap := True;
    lbl.Top := chkSkipChecksums.Top + chkSkipCheckSums.Height + lbl.ScaleValue(5);
    lbl.Left := chkSkipChecksums.Left;
    lbl.Width := lbl.ScaleValue(275);
    lbl.Height := lbl.ScaleValue(45);
    lbl.Caption := 'Keep in mind that disabling processing of meshes also disables processing of textures used in meshes.';

    btnChecksums := TButton.Create(frm);
    btnChecksums.Parent := frm;
    btnChecksums.Top := frm.Height - btnChecksums.ScaleValue(55);
    btnChecksums.Left := clbAssets.Left;
    btnChecksums.Width := btnChecksums.ScaleValue(90);
    btnChecksums.Height := btnChecksums.ScaleValue(20);
    btnChecksums.Caption := 'Build cheksums';
    btnChecksums.OnClick := btnChecksumsClick;

    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Top := frm.Height - btnOk.ScaleValue(55);
    btnOk.Left := frm.Width - btnOk.ScaleValue(115);
    btnOk.Width := btnOk.ScaleValue(50);
    btnOk.Height := btnOk.ScaleValue(20);
    btnOk.Caption := 'OK';
    btnOk.ModalResult := mrOk;

    btnCancel := TButton.Create(frm);
    btnCancel.Parent := frm;
    btnCancel.Top := frm.Height - btnCancel.ScaleValue(55);
    btnCancel.Left := frm.Width - btnCancel.ScaleValue(60);
    btnCancel.Width := btnCancel.ScaleValue(50);
    btnCancel.Height := btnCancel.ScaleValue(20);
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;

    // update default state of elements
    rbModeClick(nil);

    if frm.ShowModal = mrOk then begin

      optAsset := 0;
      for i := 0 to Pred(clbAssets.Items.Count) do
        if clbAssets.Checked[i] then
          optAsset := optAsset or (1 shl Integer(clbAssets.Items.Objects[i]));

      // speedtree is in mesh category
      if optAsset and (1 shl atMesh) > 0 then
        optAsset := optAsset or (1 shl atSpeedTree);
      // material is in texture category
      if optAsset and (1 shl atTexture) > 0 then
        optAsset := optAsset or (1 shl atMaterial);

      for i := Pred(clbContainers.Items.Count) downto 0 do
        if not clbContainers.Checked[i] then
          slContainers.Delete(i);

      if rbModeCheck.Checked then
        optMode := wmCheck

      else if rbModeList.Checked then begin
        if rgList.ItemIndex = 0 then
          optMode := wmList
        else if rgList.ItemIndex = 1 then begin
          optMode := wmListCSV;
          slDump := TStringList.Create;
        end
        else if rgList.ItemIndex = 2 then begin
          optMode := wmListJSON;
          slDump := TStringList.Create;
        end;
      end

      else if rbModeCopy.Checked then begin
        optMode := wmCopy;
        optPath := IncludeTrailingBackslash(edPath.Text);
        bSkipChecksum := chkSkipChecksums.Checked;
      end;

    end else
      optMode := wmNone;

  finally
    frm.Free;
  end;
end;

//===========================================================================
// reduce container name to BSA file name or 'Data'
function SimpleName(aName: string): string;
begin
  Result := ExtractFileName(aName);
  if Result = '' then
    Result := 'Data';
end;

//==========================================================================
// perform operation with resource depending on workmode
// returns the last container's name (in selected) of resource if exists
function ProcessResource(aResName, aResDescr: string; aResType: integer): string;
var
  i: integer;
begin
  Result := '';

  if optAsset and (1 shl aResType) = 0 then
    Exit;

  aResDescr := ResDescrPrefix + aResDescr;
  slRes.Clear;
  ResourceCount(aResName, slRes);
  if slRes.Count = 0 then
    // Skyrim checks for both .wav and .xwm
    if (wbGameMode >= gmTES5) and EndsText('.wav', aResName) then begin
      aResName := ChangeFileExt(aResName, '.xwm');
      ResourceCount(aResName, slRes);
      aResName := ChangeFileExt(aResName, '.wav');
    end;

  // dump everything regardless of asset existance in selected containers
  if optMode = wmList then
    AddMessage(aResName + '   <-- ' + aResDescr)
  else if optMode = wmListCSV then
    slDump.Add(Format('[%s];%s;%s', [
      IntToHex(GetLoadOrderFormID(CurrentRecord), 8),
      aResName,
      aResDescr
    ]))
  else if optMode = wmListJSON then
    slDump.Add(aResName);

  // check if resource is in any of selected containers
  // starting from the last one
  for i := Pred(slRes.Count) downto 0 do
    if slContainers.IndexOf(slRes[i]) <> -1 then begin
      Result := slRes[i];
      Break;
    end;

  if optMode = wmCheck then begin
    if Result = '' then
      AddMessage(aResName + '   <-- ' + aResDescr);
  end
  else if (optMode = wmCopy) and (Result <> '') then begin
    // do not overwrite existing files or copy same files several times
    if FileExists(optPath + aResName) then
      Exit;
    // skip matching checksums
    if bSkipChecksum then begin
      i := slChecksum.IndexOfName(aResName);
      if i <> - 1 then
        if slChecksum.ValueFromIndex[i] = IntToHex(wbCRC32Data(ResourceOpenData(Result, aResName)), 8) then begin
          AddMessage('[Skipped] matching checksum: ' + aResName + '   <-- ' + aResDescr);
          Result := '';
          Exit;
        end;
    end;
    AddMessage(aResName + '   <-- ' + aResDescr);
    ResourceCopy(Result, aResName, optPath);
  end;
end;

//==========================================================================
procedure ProcessMeshAssets(aMesh, aContainer, aDescr: string);
var
  i: integer;
  arr: TJsonArray;
begin
  // some assets are in the "mesh" category but not nifs
  if not SameText(ExtractFileExt(aMesh), '.nif') then
    Exit;

  if NifCache.Contains(aMesh) then begin
    arr := NifCache.A[aMesh];
    for i := 0 to Pred(arr.Count) do
      ProcessResource(arr.S[i], 'Asset for ' + aDescr + ': ' + aMesh, atTexture);
    Exit;
  end;

  // suppress possible errors for invalid meshes
  sl.Clear;
  try
    GetNifAssets(aMesh, sl);
  except //on E: Exception do
    //Exit;
	//AddMessage('Error reading Mesh: ' + E.Message + ' ' + aMesh + ' for ' + aDescr);
  end;

  // remove duplicates and empty
  for i := 0 to Pred(sl.Count) do
    if sl[i] <> '' then
      slTextures.Add(sl[i]);

  arr := NifCache.A[aMesh];
  for i := 0 to Pred(slTextures.Count) do begin
    ProcessResource(slTextures[i], 'Asset for ' + aDescr + ': ' + aMesh, atTexture);
    arr.Add(slTextures[i]);
  end;

  slTextures.Clear;
end;

//==========================================================================
procedure ProcessMaterialAssets(aMaterial, aContainer, aDescr: string);
var
  i: integer;
begin
  sl.Clear;
  try
    GetTexturesFromMaterial(aMaterial, sl);
  except on E: Exception do
    AddMessage('Error reading Material: ' + E.Message + ' ' + aMaterial);
  end;

  // remove duplicates and empty
  for i := 0 to Pred(sl.Count) do
    if sl[i] <> '' then
      slTextures.Add(sl[i]);

  for i := 0 to Pred(slTextures.Count) do
    ProcessResource(slTextures[i], 'Asset for ' + aDescr + ': ' + aMaterial, atTexture);

  slTextures.Clear;
end;

//==========================================================================
// process resource by value and type
procedure ProcessAssetEx(el: IInterface; value, valuedescr: string; atype: integer);
var
  rescont: string;
begin
  if value = '' then
    Exit;

  if wbGameMode = gmTES4 then
    if aType = atTexture then
	  if Pos(Signature(CurrentRecord), sTES4IconSigs) <> 0 then
	    if Pos('Menus', Value) = 0 then
          value := 'Textures\Menus\Icons\' + value;

  if atype = atNone then
    atype := AssetTypeByFolder(value);

  if atype <> atNone then
    value := wbNormalizeResourceName(value, atype);

  if valuedescr = '' then
    if ResDescrPrefix = '' then
      valuedescr := Name(CurrentRecord) +  ' \ ' + Path(el)
    else
      valuedescr := Path(el);

  // find container for asset (archive or Data folder)
  rescont := ProcessResource(value, valuedescr, atype);
  if rescont = '' then
    Exit;

  // check embedded assets
  if (atype = atMesh) and (optAsset and (1 shl atTexture) <> 0) then
    ProcessMeshAssets(value, rescont, valuedescr)
  else if (atype = atMaterial) and (optAsset and (1 shl atTexture) <> 0) then
    ProcessMaterialAssets(value, rescont, valuedescr);
end;

//==========================================================================
procedure ProcessAsset(el: IInterface; atype: Integer);
var
  value: string;
begin
  if not Assigned(el) then
    Exit;

  value := GetEditValue(el);
  if value = '' then
    Exit;

  ProcessAssetEx(el, value, '', atype);
end;

//==========================================================================
procedure ProcessScript(e: IInterface; s: string);
begin
  if not Assigned(e) then
    Exit;

  if optAsset and (1 shl atScript) > 0 then
    ProcessAssetEx(e, s + '.pex', 'Papyrus Script attached to ' + Name(CurrentRecord), atScript);
  if optAsset and (1 shl PexSource) > 0 then
    ProcessAssetEx(e, s + '.psc', 'Papyrus Script Source attached to ' + Name(CurrentRecord), PexSource);
end;

//==========================================================================
// scan VMAD subrecord for scripts
procedure ScanForPapyrusScripts(e: IInterface);
var
  i, j: integer;
  s: string;
  Aliases, Alias : IInterface;
  Scripts, Script : IInterface;
begin
  if not Assigned(e) then
    Exit;

  if optAsset and (1 shl atScript + 1 shl PexSource) = 0 then
    Exit;

  Scripts := ElementByPath(e, 'Scripts');
  for i := 0 to Pred(ElementCount(Scripts)) do
  begin
    Script := ElementByIndex(Scripts, i);
    s := StringReplace(GetEditValue(ElementByName(Script, 'ScriptName')), ':', '\', [rfReplaceAll]);
    ProcessScript(e, s);
  end;

  Aliases := ElementByName(e, 'Aliases');
  if Assigned(Aliases) then
    for i := 0 to Pred(ElementCount(Aliases)) do
    begin
      Alias := ElementByIndex(Aliases, i);
      Scripts := ElementByName(Alias, 'Alias Scripts');
      for j := 0 to Pred(ElementCount(Scripts)) do
      begin
        Script := ElementByIndex(Scripts, J);
        s := StringReplace(GetEditValue(ElementByName(Script, 'ScriptName')), ':', '\', [rfReplaceAll]);
        ProcessScript(e, s);
      end;
    end;
end;

//==========================================================================
// Skyrim morph models
procedure ProcessOtherMorphModel(e: IInterface; path: string);
var
  el: IInterface;
  nif: string;
begin
  el := ElementByPath(e, path);
  nif := wbNormalizeResourceName(GetEditValue(el), atMesh);
  if EndsText('_1.nif', nif) then
    ProcessAssetEx(e, Copy(nif, 1, Length(nif) - 6) + '_0.nif', 'Morph model for ' + Name(e) + '\' + Path(el), atMesh)
  else if EndsText('_0.nif', nif) then
    ProcessAssetEx(e, Copy(nif, 1, Length(nif) - 6) + '_1.nif', 'Morph model for ' + Name(e) + '\' + Path(el), atMesh)
end;

//==========================================================================
// scan book text for images
procedure ScanForBookImages(e: IInterface);
var
  regexp: TPerlRegEx;
  t: string;
begin
  regexp := TPerlRegEx.Create;
  regexp.RegEx := 'src=["''](img:\/\/)?(.+?)["'']';
  regexp.Options := [preCaseLess];
  regexp.Subject := GetEditValue(e);
  while regexp.MatchAgain do begin
    t := regexp.Groups[2];
    if wbGameMode = gmTES4 then 
	  t := 'Menus\' + t;
    ProcessAssetEx(e, wbNormalizeResourceName(t, atTexture), 'Book text image for ' + Name(CurrentRecord), atTexture);
  end;
  regexp.Free;
end;

//==========================================================================
// scan sound folders
procedure ScanForSounds(e: IInterface);
var
  s: string;
  i: Integer;
  sl: TStringList;
begin
  s := GetEditValue(e);
  // single sound file
  if ExtractFileName(s) <> '' then
    ProcessAsset(e, atSound)
  // folder with sounds
  else if s <> '' then begin
    s := wbNormalizeResourceName(s, atSound);
    sl := TStringList.Create; sl.Sorted := True; sl.Duplicates := dupIgnore;
    ResourceList('', sl, s);
    // remove files from subdirectories
    for i := Pred(sl.Count) downto 0 do
      if ExtractFilePath(sl[i]) <> s then
        sl.Delete(i);
    // report missing files in folder when checking for missing assets
    if sl.Count = 0 then begin
      if optMode = wmCheck then
        ProcessAssetEx(e, s, 'Folder is empty for ' + Name(CurrentRecord), atSound);
    end else
      for i := 0 to Pred(sl.Count) do
        ProcessAssetEx(e, sl[i], '', atSound);
    sl.Free;
  end;
end;

//==========================================================================
function Initialize: integer;
begin
  {if (wbGameMode <> gmFO3) and
     (wbGameMode <> gmFNV) and
     (wbGameMode <> gmTES4) and
     (wbGameMode <> gmTES5) and
     (wbGameMode <> gmSSE)
  then begin
    MessageDlg('Sorry, script supports Skyrim, SSE, Oblivion and Fallouts only for now.', mtInformation, [mbOk], 0);
    Result := 1;
    Exit;
  end;}

  // selection list
  slAssetsType := TStringList.Create;
  slAssetsType.AddObject('Meshes', atMesh);
  slAssetsType.AddObject('Textures', atTexture);
  slAssetsType.AddObject('Sounds', atSound);
  slAssetsType.AddObject('Music', atMusic);

  if wbGameMode > gmFNV then begin
    slAssetsType.AddObject('Papyrus Scripts', atScript);
    if wbGameMode = gmSSE then PexSource := atSourceSSE else PexSource := atSource;
    slAssetsType.AddObject('Papyrus Source', PexSource);
  end;

  if (wbGameMode = gmTES5) or (wbGameMode = gmSSE) or (wbGameMode = gmTES5VR) then
    slAssetsType.AddObject('SEQ Files', atSeq);

  if (wbGameMode = gmFO4) or (wbGameMode = gmFO4VR) then begin
    slAssetsType.AddObject('Interface', atInterface);
    slAssetsType.AddObject('PipBoy Programs', atProgram);
  end;

  //slAssetsType.Sorted := True;

  slTextures := TStringList.Create;
  slTextures.Sorted := True;
  slTextures.Duplicates := dupIgnore;

  slChecksum := TStringList.Create;

  slContainers := TStringList.Create;
  ResourceContainerList(slContainers);

  slRes := TStringList.Create;
  sl := TStringList.Create;
  NifCache := TJsonObject.Create;

  ChecksumsFileName := Format('%sAssets Manager %s Checksums.txt', [ScriptsPath, wbGameName]);

  ShowOptions;

  if optMode = wmCheck then
    AddMessage('LIST OF MISSING ASSET FILES:')
  else if optMode = wmList then
    AddMessage('LIST OF USED ASSET FILES:')
  else if optMode = wmCopy then begin
    if bSkipChecksum and (slChecksum.Count = 0) and FileExists(ChecksumsFileName) then
      slChecksum.LoadFromFile(ChecksumsFileName);
    AddMessage('COPYING USED ASSET FILES:');
  end
  else if optMode = wmNone then begin
    Finalize;
    Result := 1;
  end;
end;

//==========================================================================
procedure ProcessTES3(e: IInterface);
var
  sig: string;
begin
  sig := Signature(e);
  if Pos(sig, sNoModels) = 0 then begin
    ProcessAsset(ElementBySignature(e, 'MODL'), atMesh);
    ProcessAsset(ElementBySignature(e, 'ITEX'), atTexture);
  end;

  if sig = 'ALCH' then ProcessAsset(ElementByPath(e, 'TEXT'), atTexture) else
  if sig = 'BSGN' then ProcessAsset(ElementByPath(e, 'TNAM'), atTexture) else
  if sig = 'LTEX' then ProcessAsset(ElementByPath(e, 'DATA'), atTexture) else
  if sig = 'MGEF' then ProcessAsset(ElementByPath(e, 'PTEX'), atTexture) else
  if sig = 'SOUN' then ProcessAsset(ElementByPath(e, 'FNAM'), atTexture);
end;

//==========================================================================
procedure ProcessTES4(e: IInterface);
var
  ent, ents: IInterface;
  sig, s: string;
  i: integer;
begin
  sig := Signature(e);
  if Pos(sig, sNoModels) = 0 then
    if sig = 'TREE' then begin
      ProcessAssetEx(ElementByPath(e, 'SPT File\MODL'), 'trees' + GetElementEditValues(e, 'SPT File\MODL'), '', atSpeedTree);
      ProcessAssetEx(ElementBySignature(e, 'ICON'), 'textures\trees\leaves\' + GetElementEditValues(e, 'ICON'), '', atTexture);
    end
    else begin
      ProcessAsset(ElementByPath(e, 'Model\MODL'), atMesh);
      if sig = 'LTEX' then
        ProcessAssetEx(ElementBySignature(e, 'ICON'), 'textures\landscape\' + GetElementEditValues(e, 'ICON'), '', atTexture)
      else
        ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
    end;

  if (sig = 'ARMO') or (sig = 'CLOT') then begin
    ProcessAsset(ElementByPath(e, 'Male\Biped Model\MODL'), atMesh);
    ProcessAsset(ElementByPath(e, 'Male\World Model\MOD2'), atMesh);
    ProcessAsset(ElementByPath(e, 'Male\ICON'), atTexture);
    ProcessAsset(ElementByPath(e, 'Female\Biped Model\MOD3'), atMesh);
    ProcessAsset(ElementByPath(e, 'Female\World Model\MOD4'), atMesh);
    ProcessAsset(ElementByPath(e, 'Female\ICO2'), atTexture);
  end

  else if (sig = 'BOOK') then
    ScanForBookImages(ElementByPath(e, 'DESC'))

  else if (sig = 'CLMT') then begin
    ProcessAsset(ElementByPath(e, 'FNAM'), atTexture);
    ProcessAsset(ElementByPath(e, 'GNAM'), atTexture);
  end

  else if (sig = 'NPC_') or (sig = 'CREA') then begin
    ents := ElementByPath(e, 'NIFZ');
    for i := 0 to ElementCount(ents) - 2 do
      ProcessAssetEx(ElementByIndex(ents, i), ExtractFilePath(GetElementEditValues(e, 'Model\MODL')) + GetEditValue(ElementByIndex(ents, i)), '', atMesh);
    ents := ElementByPath(e, 'KFFZ');
    for i := 0 to ElementCount(ents) - 2 do
      ProcessAssetEx(ElementByIndex(ents, i), ExtractFilePath(GetElementEditValues(e, 'Model\MODL')) + 'SpecialAnims\' + GetEditValue(ElementByIndex(ents, i)), '', atMesh);
    ProcessAsset(ElementByPath(e, 'NAM0'), atMesh);
    ProcessAsset(ElementByPath(e, 'NAM1'), atTexture);
  end

  else if (sig = 'EFSH') then
    ProcessAsset(ElementByPath(e, 'ICO2'), atTexture)

  else if (sig = 'FACT') then begin
    ents := ElementByName(e, 'Ranks');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'INAM'), atTexture);
  end

  else if (sig = 'RACE') then begin
    ents := ElementByPath(e, 'Face Data\Parts');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\MODL'), atMesh);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'ICON'), atTexture);
    end;
    ents := ElementByPath(e, 'Male Body Data\Parts');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\MODL'), atMesh);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'ICON'), atTexture);
    end;
    ents := ElementByPath(e, 'Female Body Data\Parts');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\MODL'), atMesh);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'ICON'), atTexture);
    end;
  end

  else if (sig = 'SOUN') then
    ScanForSounds(ElementByPath(e, 'FNAM'))

  // Trees billboard LOD
  else if (sig = 'TREE') and (optMode <> wmCheck) then begin
    s := ExtractFileName(GetElementEditValues(e, 'Model\MODL'));
    if s <> '' then begin
      s := 'Textures\Trees\Billboards\' + ChangeFileExt(s, '.dds');
      ProcessAssetEx(e, s, 'Tree Billboard LOD Texture For ' + Name(e), atMesh);
    end;
  end

  else if (sig = 'WATR') then
    ProcessAsset(ElementByPath(e, 'TNAM'), atTexture)

  else if (sig = 'WTHR') then begin
    ProcessAsset(ElementByPath(e, 'CNAM'), atTexture);
    ProcessAsset(ElementByPath(e, 'DNAM'), atTexture);
    ProcessAsset(ElementByPath(e, 'Precipitation Model\MODL'), atMesh);
  end;
end;

//==========================================================================
procedure ProcessFO3(e: IInterface);
var
  ent, ents: IInterface;
  sig, s: string;
  i: integer;
begin
  sig := Signature(e);
  if Pos(sig, sNoModels) = 0 then
    if sig = 'TREE' then begin
      ProcessAssetEx(ElementByPath(e, 'Model\MODL'), 'trees' + GetElementEditValues(e, 'Model\MODL'), '', atSpeedTree);
      ProcessAssetEx(ElementBySignature(e, 'Icon\ICON'), 'textures\trees\leaves\' + GetElementEditValues(e, 'Icon\ICON'), '', atTexture);
    end
    else begin
      ProcessAsset(ElementByPath(e, 'Model\MODL'), atMesh);
      ents := ElementByPath(e, 'Destructible\Stages');
      for i := 0 to Pred(ElementCount(ents)) do
        ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\DMDL'), atMesh);
    end;

  if (sig = 'ARMA') or (sig = 'ARMO') then begin
    ProcessAsset(ElementByPath(e, 'Male\Biped Model\MODL'), atMesh);
    ProcessAsset(ElementByPath(e, 'Male\World Model\ICON'), atTexture);
    ProcessAsset(ElementByPath(e, 'Male\World Model\MICO'), atTexture);
    ProcessAsset(ElementByPath(e, 'Female\Biped Model\MODL'), atMesh);
    ProcessAsset(ElementByPath(e, 'Female\World Model\ICO2'), atTexture);
    ProcessAsset(ElementByPath(e, 'Female\World Model\MIC2'), atTexture);
  end

  else if (sig = 'CCRD') then begin
    ents := ElementByName(e, 'High Res Image');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atTexture);
  end

  else if (sig = 'CLMT') then begin
    ProcessAsset(ElementByPath(e, 'FNAM'), atTexture);
    ProcessAsset(ElementByPath(e, 'GNAM'), atTexture);
  end

  else if (sig = 'CREA') then begin
    ents := ElementByPath(e, 'NIFZ');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAssetEx(ElementByIndex(ents, i), ExtractFilePath(GetElementEditValues(e, 'Model\MODL')) + GetEditValue(ElementByIndex(ents, i)), '', atMesh);
    ents := ElementByPath(e, 'KFFZ');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAssetEx(ElementByIndex(ents, i), ExtractFilePath(GetElementEditValues(e, 'Model\MODL')) + 'SpecialAnims\' + GetEditValue(ElementByIndex(ents, i)), '', atMesh);
  end

  else if (sig = 'CSNO') then begin
    ProcessAsset(ElementByPath(e, 'MODL'), atMesh);
    ProcessAsset(ElementByPath(e, 'MOD2'), atMesh);
    ProcessAsset(ElementByPath(e, 'MOD3'), atMesh);
    ProcessAsset(ElementByPath(e, 'MOD4'), atMesh);
    ents := ElementByName(e, 'Casino Chip Models');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atMesh);
    ents := ElementByName(e, 'Slot Reel Textures');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atTexture);
    ents := ElementByName(e, 'BlackJack Decks');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atTexture);
  end

  else if (sig = 'DEBR') then begin
    ents := ElementByName(e, 'Models');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'DATA\Model FileName'), atMesh);
  end

  else if (sig = 'EFSH') then begin
    ProcessAsset(ElementByPath(e, 'ICO2'), atTexture);
    ProcessAsset(ElementByPath(e, 'NAM7'), atTexture);
  end

  else if (sig = 'MSET') then begin
    ProcessAsset(ElementByPath(e, 'NAM2'), atMusic);
    ProcessAsset(ElementByPath(e, 'NAM3'), atMusic);
    ProcessAsset(ElementByPath(e, 'NAM4'), atMusic);
    ProcessAsset(ElementByPath(e, 'NAM5'), atMusic);
    ProcessAsset(ElementByPath(e, 'NAM6'), atMusic);
    ProcessAsset(ElementByPath(e, 'NAM7'), atMusic);
  end

  else if (sig = 'MUSC') then
    ProcessAsset(ElementByPath(e, 'FNAM'), atMusic)

  else if (sig = 'PROJ') then
    ProcessAsset(ElementByPath(e, 'Muzzle Flash Model\NAM1'), atMesh)

  else if (sig = 'RACE') then begin
    ents := ElementByPath(e, 'Head Data\Male Head Data\Parts');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\MODL'), atMesh);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\ICON'), atTexture);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\MICO'), atTexture);
    end;
    ents := ElementByPath(e, 'Head Data\Female Head Data\Parts');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\MODL'), atMesh);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\ICON'), atTexture);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\MICO'), atTexture);
    end;
    ents := ElementByPath(e, 'Body Data\Male Body Data\Parts');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\MODL'), atMesh);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\ICON'), atTexture);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\MICO'), atTexture);
    end;
    ents := ElementByPath(e, 'Body Data\Female Body Data\Parts');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\MODL'), atMesh);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\ICON'), atTexture);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\MICO'), atTexture);
    end;
  end

  else if (sig = 'RGDL') then
    ProcessAsset(ElementByPath(e, 'ANAM'), atMesh)

  else if (sig = 'SOUN') then
    ScanForSounds(ElementBySignature(e, 'FNAM'))

  // Statics LOD
  // we don't know if a mesh must have lod or not since it is not referenced directly from record, so skip it in "check missing" mode
  else if (sig = 'STAT') and (optMode <> wmCheck) then begin
    s := GetElementEditValues(e, 'Model\MODL');
    if s <> '' then begin
      s := ChangeFileExt(s, '') + '_LOD.nif';
      ProcessAssetEx(e, s, 'Static LOD Mesh for ' + Name(e), atMesh);
    end;
  end

  // Trees billboard LOD
  else if (sig = 'TREE') and (optMode <> wmCheck) then begin
    s := ExtractFileName(GetElementEditValues(e, 'Model\MODL'));
    if s <> '' then begin
      s := 'Textures\Trees\Billboards\' + ChangeFileExt(s, '.dds');
      ProcessAssetEx(e, s, 'Tree Billboard LOD Texture For ' + Name(e), atMesh);
    end;
  end

  else if (sig = 'TXST') then begin
    ents := ElementByPath(e, 'Textures (RGB/A)');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atTexture);
  end

  else if (sig = 'WATR') then
    ProcessAsset(ElementByPath(e, 'NNAM'), atTexture)

  else if (sig = 'WEAP') then begin
    ProcessAsset(ElementByPath(e, 'Shell Casing Model\MOD2'), atMesh);
    ProcessAsset(ElementByPath(e, 'Scope Model\MOD3'), atMesh);
    ProcessAsset(ElementByPath(e, 'World Model\MOD4'), atMesh);
    ProcessAsset(ElementByPath(e, 'MWD1'), atMesh);
    ProcessAsset(ElementByPath(e, 'MWD2'), atMesh);
    ProcessAsset(ElementByPath(e, 'MWD3'), atMesh);
    ProcessAsset(ElementByPath(e, 'MWD4'), atMesh);
    ProcessAsset(ElementByPath(e, 'MWD5'), atMesh);
    ProcessAsset(ElementByPath(e, 'MWD6'), atMesh);
    ProcessAsset(ElementByPath(e, 'MWD7'), atMesh);
  end

  else if (sig = 'WRLD') then begin
    ProcessAsset(ElementByPath(e, 'XNAM'), atTexture);
    ProcessAsset(ElementByPath(e, 'NNAM'), atTexture);
  end

  else if (sig = 'WTHR') then begin
    ProcessAsset(ElementByPath(e, 'DNAM'), atTexture);
    ProcessAsset(ElementByPath(e, 'CNAM'), atTexture);
    ProcessAsset(ElementByPath(e, 'ANAM'), atTexture);
    ProcessAsset(ElementByPath(e, 'BNAM'), atTexture);
  end;

end;

//==========================================================================
procedure ProcessTES5(e: IInterface);
var
  ent, ents: IInterface;
  sig, s: string;
  i, DisabledClouds: Cardinal;
  sl: TStringList;
begin
  ScanForPapyrusScripts(ElementBySignature(e, 'VMAD'));
  sig := Signature(e);

  // no assets in refs except papyrus scripts
  if Pos(sig, sRefSignatures) <> 0 then
    Exit;

  if Pos(sig, sNoModels) = 0 then begin
    ProcessAsset(ElementByPath(e, 'Model\MODL'), atMesh);
    ents := ElementByPath(e, 'Destructible\Stages');
    if Assigned(ents) then
      for i := 0 to Pred(ElementCount(ents)) do
        ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\DMDL'), atMesh);
  end;

  if (sig = 'ARMA') then begin
    ProcessAsset(ElementByPath(e, 'Biped Model\Male\MOD2'), atMesh);
    if GetElementNativeValues(e, 'DNAM\Weight Slider - Male\Enabled') <> 0 then
      ProcessOtherMorphModel(e, 'Biped Model\Male\MOD2');
    ProcessAsset(ElementByPath(e, 'Biped Model\Female\MOD3'), atMesh);
    if GetElementNativeValues(e, 'DNAM\Weight Slider - Female\Enabled') <> 0 then
      ProcessOtherMorphModel(e, 'Biped Model\Female\MOD3');
    ProcessAsset(ElementByPath(e, '1st Person\Male\MOD4'), atMesh);
    if GetElementNativeValues(e, 'DNAM\Weight Slider - Male\Enabled') <> 0 then
      ProcessOtherMorphModel(e, '1st Person\Male\MOD4');
    ProcessAsset(ElementByPath(e, '1st Person\Female\MOD5'), atMesh);
    if GetElementNativeValues(e, 'DNAM\Weight Slider - Female\Enabled') <> 0 then
      ProcessOtherMorphModel(e, '1st Person\Female\MOD5');
  end

  else if (sig = 'ARMO') then begin
    ProcessAsset(ElementByPath(e, 'Male\World Model\MOD2'), atMesh);
    ProcessAsset(ElementByPath(e, 'Female\World Model\MOD4'), atMesh);
    ProcessAsset(ElementBySignature(e, 'BCMT'), atMesh);
  end

  else if (sig = 'BOOK') then
    ScanForBookImages(ElementBySignature(e, 'DESC'))

  else if (sig = 'BPTD') then begin
    ents := ElementByName(e, 'Body Parts');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementBySignature(ElementByIndex(ents, i), 'NAM1'), atMesh);
  end

  else if (sig = 'CELL') then begin
    ProcessAsset(ElementBySignature(e, 'XNAM'), atTexture);
    ProcessAsset(ElementBySignature(e, 'XWEM'), atTexture);
  end

  else if (sig = 'CLMT') then begin
    ProcessAsset(ElementBySignature(e, 'FNAM'), atTexture);
    ProcessAsset(ElementBySignature(e, 'GNAM'), atTexture);
  end

  else if (sig = 'DEBR') then begin
    ents := ElementByName(e, 'Models');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'DATA\Model FileName'), atMesh);
  end

  else if (sig = 'EFSH') then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
    ProcessAsset(ElementBySignature(e, 'ICO2'), atTexture);
    ProcessAsset(ElementBySignature(e, 'NAM7'), atTexture);
    ProcessAsset(ElementBySignature(e, 'NAM8'), atTexture);
    ProcessAsset(ElementBySignature(e, 'NAM9'), atTexture);
  end

  else if (sig = 'EYES') then
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture)

  else if (sig = 'FURN') then
    ProcessAsset(ElementBySignature(e, 'XMRK'), atMesh)

  else if (sig = 'HDPT') then begin
    ents := ElementByName(e, 'Parts');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementBySignature(ElementByIndex(ents, i), 'NAM1'), atMesh);
  end

  else if (sig = 'IDLE') then
    ProcessAsset(ElementBySignature(e, 'DNAM'), atMesh)

  else if (sig = 'LENS') then begin
    ents := ElementByName(e, 'Lens Flare Sprites');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementBySignature(ElementByIndex(ents, i), 'FNAM'), atTexture);
  end

  else if (sig = 'LSCR') then
    ProcessAsset(ElementBySignature(e, 'MOD2'), atMesh)

  else if (sig = 'MUST') then begin
    ProcessAsset(ElementBySignature(e, 'ANAM'), atMusic);
    ProcessAsset(ElementBySignature(e, 'BNAM'), atMusic);
  end

  else if (sig = 'NPC_') then begin
    if not GetElementNativeValues(e, 'ACBS\Template Flags\Traits') and not GetElementNativeValues(e, 'ACBS\Flags\Is CharGen Face Preset') then
      if (GetElementNativeValues(e, 'RNAM') <> $19) and GetElementNativeValues(LinksTo(ElementBySignature(e, 'RNAM')), 'DATA\Flags\FaceGen Head') then
        ProcessAssetEx(e, Format('Meshes\Actors\Character\FaceGenData\FaceGeom\%s\%s.nif', [GetFileName(MasterOrSelf(e)), IntToHex(FormID(e) and $00FFFFFF, 8)]), 'Facegen for ' + Name(e), atMesh);
  end

  else if (sig = 'PROJ') then
    ProcessAsset(ElementByPath(e, 'Muzzle Flash Model\NAM1'), atMesh)

  else if (sig = 'QUST') then begin
    if GetElementNativeValues(e, 'DNAM\Flags') and 1 > 0 then
      if not Assigned(Master(e)) or (GetElementNativeValues(Master(e), 'DNAM\Flags') and 1 = 0) then
        ProcessAssetEx(e, 'Seq\' + ChangeFileExt(GetFileName(e), '.seq'), 'Start-Game Enabled Quest Requires SEQ File ' + Name(e), atSeq);
  end

  else if (sig = 'RACE') then begin
    ProcessAsset(ElementByPath(e, 'ANAM - Male Skeletal Model'), atMesh);
    ProcessAsset(ElementByPath(e, 'ANAM - Female Skeletal Model'), atMesh);
    //ents := ElementByPath(e, 'Body Data\Male Body Data\Parts');
    //for i := 0 to Pred(ElementCount(ents)) do
      //ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\MODL'), atMesh);
    //ents := ElementByPath(e, 'Body Data\Female Body Data\Parts');
    //for i := 0 to Pred(ElementCount(ents)) do
      //ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\MODL'), atMesh);
    ProcessAsset(ElementByPath(e, 'Male Behavior Graph\Model\MODL'), atMesh);
    ProcessAsset(ElementByPath(e, 'Female Behavior Graph\Model\MODL'), atMesh);
    ProcessAsset(ElementByPath(e, 'Head Data\Male Head Data\Model'), atMesh);
    ents := ElementByPath(e, 'Head Data\Male Head Data\Tint Masks');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Tint Layer\TINT'), atTexture);
    ProcessAsset(ElementByPath(e, 'Head Data\Female Head Data\Model'), atMesh);
    ents := ElementByPath(e, 'Head Data\Female Head Data\Tint Masks');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Tint Layer\TINT'), atTexture);
  end

  else if (sig = 'REGN') then begin
    ents := ElementByPath(e, 'Region Data Entries');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\ICON'), atTexture);
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Icon\MICO'), atTexture);
    end;
  end

  else if (sig = 'SNDR') then begin
    ents := ElementByPath(e, 'Sounds');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atSound);
  end

  else if (sig = 'SPGD') then
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture)

  // STAT LOD
  else if (sig = 'STAT') then begin
    ents := ElementBySignature(e, 'MNAM');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ent := ElementByIndex(ents, i);
      s := GetEditValue(ent);
      ProcessAssetEx(e, s, 'Static LOD Level ' + IntToStr(i) + ' Mesh For ' + Name(e), atMesh);
    end;
  end

  // TREE LOD
  // we don't know if a mesh must have lod or not since it is not referenced directly from record, so skip it in "check missing" mode
  else if (sig = 'TREE') then begin
    if (optMode <> wmCheck) then begin
      s := GetElementEditValues(e, 'Model\MODL');
      if s <> '' then begin
        s := ChangeFileExt(s, '') + '_LOD_%s.nif';
        ProcessAssetEx(e, Format(s, ['Flat']), 'Tree LOD Mesh for ' + Name(e), atMesh);
        ProcessAssetEx(e, Format(s, ['0']), 'xLODGen 0 Mesh for ' + Name(e), atMesh);
        ProcessAssetEx(e, Format(s, ['1']), 'xLODGen 1 Mesh for ' + Name(e), atMesh);
        ProcessAssetEx(e, Format(s, ['2']), 'xLODGen 2 Mesh for ' + Name(e), atMesh);
        ProcessAssetEx(e, Format(s, ['3']), 'xLODGen 3 Mesh for ' + Name(e), atMesh);
      end;
    end;
  end

  else if (sig = 'TXST') then begin
    ents := ElementByPath(e, 'Textures (RGB/A)');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atTexture);
  end

  else if (sig = 'WATR') then begin
    ents := ElementByPath(e, 'Old Noise Textures');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atTexture);
    ents := ElementByPath(e, 'Noise Textures');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atTexture);
    ProcessAsset(ElementBySignature(e, 'NAM5'), atTexture);
  end

  else if (sig = 'WEAP') then
    ProcessAsset(ElementByPath(e, 'Has Scope\MOD3'), atMesh)

  else if (sig = 'WRLD') then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
    ProcessAsset(ElementByPath(e, 'Cloud Model\Model\MODL'), atMesh);
    ProcessAsset(ElementBySignature(e, 'NNAM'), atTexture);
    ProcessAsset(ElementBySignature(e, 'XNAM'), atTexture);
    ProcessAsset(ElementBySignature(e, 'XWEM'), atTexture);
    ProcessAsset(ElementBySignature(e, 'TNAM'), atTexture);
    ProcessAsset(ElementBySignature(e, 'UNAM'), atTexture);
  end

  else if (sig = 'WTHR') then begin
    ents := ElementByPath(e, 'Old Cloud Textures');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atTexture);
    // check cloud texture layers except disabled ones
    sl := TStringList.Create;
    sl.CommaText := '00TX,10TX,20TX,30TX,40TX,50TX,60TX,70TX,80TX,90TX,:0TX,;0TX,<0TX,=0TX,>0TX,?0TX,@0TX,A0TX,B0TX,C0TX,D0TX,E0TX,F0TX,G0TX,H0TX,I0TX,J0TX,K0TX,L0TX';
    DisabledClouds := GetElementNativeValues(e, 'NAM1');
    for i := 0 to Pred(sl.Count) do begin
      if DisabledClouds and (1 shl i) = 0 then
        ProcessAsset(ElementByPath(e, 'Cloud Textures\' + sl[i]), atTexture);
    end;
    sl.Free;
    ProcessAsset(ElementByPath(e, 'Aurora\Model\MODL'), atMesh);
  end;
end;

//==========================================================================
procedure ProcessFO4(e: IInterface);
var
  ent, ents, ents2, ents3: IInterface;
  sig, s: string;
  i, j, k, DisabledClouds: Cardinal;
  sl: TStringList;
begin
  ScanForPapyrusScripts(ElementBySignature(e, 'VMAD'));
  sig := Signature(e);

  // no assets in refs except papyrus scripts
  if Pos(sig, sRefSignatures) <> 0 then
    Exit;

  if Pos(sig, sNoModels) = 0 then begin
    ProcessAsset(ElementByPath(e, 'Model\MODL'), atMesh);
    ents := ElementByPath(e, 'Destructible\Stages');
    if Assigned(ents) then
      for i := 0 to Pred(ElementCount(ents)) do
        ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'Model\DMDL'), atMesh);
  end;

  if sig = 'ALCH' then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
      ProcessAsset(ElementBySignature(e, 'MICO'), atTexture);
  end

  else if sig = 'AMMO' then begin
    ProcessAsset(ElementBySignature(e, 'NAM1'), atMesh);
  end

  else if sig = 'ARMA' then begin
    ProcessAsset(ElementByPath(e, 'Biped Model\Male\MOD2'), atMesh);
    ProcessAsset(ElementByPath(e, 'Biped Model\Female\MOD3'), atMesh);
    ProcessAsset(ElementByPath(e, '1st Person\Male\MOD4'), atMesh);
    ProcessAsset(ElementByPath(e, '1st Person\Female\MOD5'), atMesh);
  end

  else if sig = 'ARMO' then begin
    ProcessAsset(ElementByPath(e, 'Male\World Model\MOD2'), atMesh);
    ProcessAsset(ElementByPath(e, 'Male\ICON'), atTexture);
    ProcessAsset(ElementByPath(e, 'Male\MICO'), atTexture);
    ProcessAsset(ElementByPath(e, 'Female\World Model\MOD4'), atMesh);
    ProcessAsset(ElementByPath(e, 'Female\ICO2'), atTexture);
    ProcessAsset(ElementByPath(e, 'Female\MIC2'), atTexture);
  end

  else if sig = 'BOOK' then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
      ProcessAsset(ElementBySignature(e, 'MICO'), atTexture);
  end

  else if sig = 'BPTD' then begin
    ents := ElementByName(e, 'Body Parts');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementBySignature(ElementByIndex(ents, i), 'NAM1'), atMesh);
  end

  else if sig = 'CELL' then
    ProcessAsset(ElementBySignature(e, 'XWEM'), atTexture)

  else if sig = 'CLAS' then
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture)

  else if sig = 'CLMT' then begin
    ProcessAsset(ElementBySignature(e, 'FNAM'), atTexture);
      ProcessAsset(ElementBySignature(e, 'GNAM'), atTexture);
  end

  else if (sig = 'DEBR') then begin
    ents := ElementByName(e, 'Models');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByPath(ElementByIndex(ents, i), 'DATA\Model FileName'), atMesh);
  end

  else if (sig = 'EFSH') then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
    ProcessAsset(ElementBySignature(e, 'ICO2'), atTexture);
    ProcessAsset(ElementBySignature(e, 'NAM7'), atTexture);
    ProcessAsset(ElementBySignature(e, 'NAM8'), atTexture);
    ProcessAsset(ElementBySignature(e, 'NAM9'), atTexture);
  end

  else if (sig = 'FURN') then
    ProcessAsset(ElementBySignature(e, 'XMRK'), atMesh)

  else if (sig = 'HDPT') then begin
    ents := ElementByName(e, 'Parts');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementBySignature(ElementByIndex(ents, i), 'NAM1'), atMesh);
  end

  else if (sig = 'IDLE') then begin
    ProcessAsset(ElementBySignature(e, 'DNAM'), atMesh);
    ProcessAsset(ElementBySignature(e, 'GNAM'), atMesh); //May need a special handling function, not always a straight file path
  end

  else if sig = 'IMGS' then
    ProcessAsset(ElementBySignature(e, 'TX00'), atTexture)

  else if sig = 'INGR' then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
    ProcessAsset(ElementBySignature(e, 'MICO'), atTexture);
  end

  else if sig = 'KEYM' then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
    ProcessAsset(ElementBySignature(e, 'MICO'), atTexture);
  end

  else if sig = 'LENS' then begin
    ents := ElementByName(e, 'Lens Flare Sprites');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementBySignature(ElementByIndex(ents, i), 'FNAM'), atTexture);
  end

  else if (sig = 'LIGH') then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
    ProcessAsset(ElementBySignature(e, 'MICO'), atTexture);
    ProcessAsset(ElementBySignature(e, 'NAM0'), atTexture);
  end

  else if (sig = 'LSCR') then
    ProcessAsset(ElementByPath(e, 'MOD2'))

  else if (sig = 'MATT') then
    ProcessAsset(ElementByPath(e, 'ANAM'), atMesh)

  else if (sig = 'MESG') then
    ProcessAsset(ElementByPath(e, 'SNAM'), atInterface)

  else if sig = 'MISC' then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
      ProcessAsset(ElementBySignature(e, 'MICO'), atTexture);
  end

  else if sig = 'MSWP' then begin
    ents := ElementByName(e, 'Material Substitutions');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementBySignature(ElementByIndex(ents, i), 'SNAM'), atMaterial);
  end

  else if (sig = 'MUSC') then begin
    ProcessAsset(ElementByPath(e, 'ANAM'), atMusic);
    ProcessAsset(ElementByPath(e, 'BNAM'), atMusic);
  end

  else if sig = 'NOCM' then begin
    ents := ElementByName(e, 'Unknown');
      for i := 0 to Pred(ElementCount(ents)) do
        ProcessAsset(ElementBySignature(ElementByIndex(ents, i), 'NAM1'), atMesh);
  end

  else if (sig = 'NOTE') then
    ProcessAsset(ElementBySignature(e, 'PNAM'), atProgram)

  else if (sig = 'NPC_') then begin
    if not GetElementNativeValues(e, 'ACBS\Template Flags\Traits') and not GetElementNativeValues(e, 'ACBS\Flags\Is CharGen Face Preset') then
      if (GetElementNativeValues(e, 'RNAM') <> $19) and GetElementNativeValues(LinksTo(ElementBySignature(e, 'RNAM')), 'DATA\Flags\FaceGen Head') then
        ProcessAssetEx(e, Format('Meshes\Actors\Character\FaceGenData\FaceGeom\%s\%s.nif', [GetFileName(MasterOrSelf(e)), IntToHex(FormID(e) and $00FFFFFF, 8)]), 'Facegen for ' + Name(e), atMesh);
  end

  else if (sig = 'PERK') then begin
    ProcessAsset(ElementBySignature(e, 'ICON'), atTexture);
    ProcessAsset(ElementBySignature(e, 'FNAM'), atInterface);
  end

  else if (sig = 'PROJ') then
    ProcessAsset(ElementByPath(e, 'Muzzle Flash Model\NAM1'), atMesh)

  else if (sig = 'QUST') then
    ProcessAsset(ElementByPath(e, 'SNAM'), atInterface)

  else if (sig = 'RACE') then begin
    ProcessAsset(ElementByPath(e, 'ANAM - Male Skeletal Model'));
    ProcessAsset(ElementByPath(e, 'ANAM - Female Skeletal Model'));
    ents := ElementByPath(e, 'Body Data\Male Body Data\Parts');
      for i := 0 to Pred(ElementCount(ents) do
        ProcessAsset(ElementByIndex(ents, i), atMesh);
      ents := ElementByPath(e, 'Body Data\Female Body Data\Parts');
    for i := 0 to Pred(ElementCount(ents) do
      ProcessAsset(ElementByIndex(ents, i), atMesh);
    ProcessAsset(ElementByPath(e, 'Male Behavior Graph\Model\MODL'), atMesh);
    ProcessAsset(ElementByPath(e, 'Female Behavior Graph\Model\MODL'), atMesh);
    ents := ElementByName(e, 'Male Tint Layers');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ents2 := ElementByName(ents, 'Options');
      for j := 0 to Pred(ElementCount(ents2)) do begin
        ents3 := ElementByName(ents2, 'Textures');
        for k := 0 to Pred(ElementCount(ents3)) do
          ProcessAsset(ElementByIndex(ents3, k), atTexture);
      end;
      end;
    ents := ElementByName(e, 'Female Tint Layers');
    for i := 0 to Pred(ElementCount(ents)) do begin
      ents2 := ElementByName(ents, 'Options');
      for j := 0 to Pred(ElementCount(ents2)) do begin
        ents3 := ElementByName(ents2, 'Textures');
        for k := 0 to Pred(ElementCount(ents3) do
          ProcessAsset(ElementByIndex(ents3, k), atTexture);
      end;
    end;
  end

  else if (sig = 'SNDR') then begin
    ents := ElementByName(e, 'Sounds');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atSound);
  end

  else if (sig = 'SPGD') then
    ProcessAsset(ElementByPath(e, 'MNAM'), atMaterial)

  // STAT LOD
  else if (sig = 'STAT') and ElementExists(e, 'MNAM') then begin
    ents := ElementBySignature(e, 'MNAM');
    for i := 0 to Pred(ElementCount(ents)) do begin
      s := wbNormalizeResourceName(GetEditValue(ElementByIndex(ents, i)), atMesh);
      ProcessAssetEx(e, s, 'Static LOD Level ' + IntToStr(i) + ' Mesh for ' + Name(e), atMesh);
    end;
  end

  else if (sig = 'TERM') then begin
    ProcessAsset(ElementBySignature(e, 'XMRK'), atMesh);
    ents := ElementByName(e, 'Menu Items');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementBySignature(ElementByIndex(ents, i), 'VNAM'), atTexture);
  end

  else if (sig = 'TXST') then begin
    ents := ElementByPath(e, 'Textures (RGB/A)');
    for i := 0 to Pred(ElementCount(ents)) do
      ProcessAsset(ElementByIndex(ents, i), atTexture);
    ProcessAsset(ElementByPath(e, 'MNAM'), atMaterial);
  end

  else if (sig = 'WATR') then begin
    ProcessAsset(ElementByPath(e, 'NAM2'), atTexture);
    ProcessAsset(ElementByPath(e, 'NAM3'), atTexture);
    ProcessAsset(ElementByPath(e, 'NAM4'), atTexture);
  end

  else if (sig = 'WEAP') then
    ProcessAsset(ElementByPath(e, '1st Person Model\MOD4'), atMesh)

  else if (sig = 'WRLD') then begin
    ProcessAsset(ElementByPath(e, 'Cloud Model\Model\MODL'), atMesh);
    ProcessAsset(ElementBySignature(e, 'XWEM'), atTexture);
    ProcessAsset(ElementBySignature(e, 'TNAM'), atTexture);
    ProcessAsset(ElementBySignature(e, 'UNAM'), atTexture);
  end

  else if (sig = 'WTHR') then begin
    // check cloud texture layers except disabled ones
    sl := TStringList.Create;
    sl.CommaText := '00TX,10TX,20TX,30TX,40TX,50TX,60TX,70TX,80TX,90TX,:0TX,;0TX,<0TX,=0TX,>0TX,?0TX,@0TX,A0TX,B0TX,C0TX,D0TX,E0TX,F0TX,G0TX,H0TX,I0TX,J0TX,K0TX,L0TX';
    DisabledClouds := GetElementNativeValues(e, 'NAM1');
    for i := 0 to Pred(sl.Count) do begin
      if DisabledClouds and (1 shl i) = 0 then
        ProcessAsset(ElementBySignature(e, sl[i]), atTexture);
    end;
    sl.Free;
    ProcessAsset(ElementByPath(e, 'Aurora\Model\MODL'), atMesh);
  end;
end;

//==========================================================================
function Process(e: IInterface): integer;
begin
  // skip records without assets
  if Pos(Signature(e), sSkipSignatures) > 0 then
    Exit;

  CurrentRecord := e;

  case wbGameMode of
    gmTES3: ProcessTES3(e);
    gmTES4: ProcessTES4(e);
    gmFO3, gmFNV: ProcessFO3(e);
    gmTES5, gmSSE: ProcessTES5(e);
    gmFO4: ProcessFO4(e);
  end;
end;

//==========================================================================
function Finalize: integer;
var
  dlgSave: TSaveDialog;
  json: TJSONArray;
  slNoDups: TStringList;
  i: integer;
begin
  if optMode = wmListCSV then begin
    dlgSave := TSaveDialog.Create(nil);
    try
      dlgSave.Options := dlgSave.Options + [ofOverwritePrompt];
      dlgSave.InitialDir := wbDataPath;
      dlgSave.FileName := 'UsedAssets.csv';
      if dlgSave.Execute then begin
        AddMessage('Saving assets list to ' + dlgSave.FileName);
        slDump.SaveToFile(dlgSave.FileName);
      end;
    finally
      dlgSave.Free;
    end;
    slDump.Free;
  end;

  if optMode = wmListJSON then begin
    dlgSave := TSaveDialog.Create(nil);
    try
      dlgSave.Options := dlgSave.Options + [ofOverwritePrompt];
      dlgSave.InitialDir := wbDataPath;
      dlgSave.FileName := 'UsedAssets.achlist';
      if dlgSave.Execute then begin
        slNoDups := TStringList.Create;
        slNoDups.Sorted := True;
        slNoDups.Duplicates := dupIgnore;
        slNoDups.Assign(slDump);
        json := TJSONArray.Create;
        for i := 0 to slNoDups.Count - 1 do
          json.Add('Data\' + slNoDups[i]);
        AddMessage('Saving assets list to ' + dlgSave.FileName);
        json.SaveToFile(dlgSave.FileName, False);
        json.Free;
        slNoDups.Free;
      end;
    finally
      dlgSave.Free;
    end;
    slDump.Free;
  end;

  slAssetsType.Free;
  slContainers.Free;
  slTextures.Free;
  slChecksum.Free;
  slRes.Free;
  sl.Free;
  NifCache.Free;
end;

end.