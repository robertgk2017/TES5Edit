unit wbDataFormatWwise;

interface

uses
  System.Classes,

  wbInterface;

type
  IwbSoundBankArray = interface(IInterface)
  ['{5FEF18BF-C357-4B8A-9DBB-6F6D58923F89}']
    function TryLookupGUID(const aNodeType : TwbWwiseNodeType;
                           const aGUID     : TGUID;
                             var aName     : string;
                             var aFilename : string)
                                           : Boolean;

    function TryLookupDisplay(const aNodeType   : TwbWwiseNodeType;
                              const aDisplayStr : string;
                                var aGUID       : TGUID)
                                                : Boolean;

    procedure GetChildStrings(const aParentGUID: TGUID;
                              const aChildType: TwbWwiseNodeType;
                                var aList: TStringList);

    procedure GetStrings(const aNodeType : TwbWwiseNodeType;
                         const aMasters  : TStringList;
                           var aList     : TStringList);
  end;

var
  wbSoundBank: IwbSoundBankArray;

function wbSoundBankArray(const aLoadOrder: TStringList): IwbSoundBankArray;

implementation

uses
  System.Generics.Collections,
  System.Generics.Defaults,
  System.IOUtils,
  System.SysUtils,

  JsonDataObjects,

  wbHash;

type
  TwbSoundBankArray = class;

  TwbWwiseObject = class
  public
    FGUID: TGUID;
    FName: string;
    FParent: TwbWwiseObject;
    FRoot: TwbSoundBankArray;
  end;

  TwbActionSetState = class(TwbWwiseObject) end;
  TwbActionPostEvent = class(TwbWwiseObject) end;
  TwbAuxBusSend = class(TwbWwiseObject) end;
  TwbExternalSource = class(TwbWwiseObject) end;
  TwbGameParameter = class(TwbWwiseObject) end;
  TwbIncludedAuxBuss = class(TwbWwiseObject) end;
  TwbSwitch = class(TwbWwiseObject) end;
  TwbState = class(TwbWwiseObject) end;

  TwbSwitchGroup = class(TwbWwiseObject)
  public
    FSwitches: TArray<TwbSwitch>;

    procedure BuildSwitchGroup(const aSwitchGroup: TJSONArray; var aCount: Integer; const aBankFilename: string);
  end;

  TwbStateGroup = class(TwbWwiseObject)
  public
    FStates: TArray<TwbState>;

    procedure BuildStateGroup(const aStateGroup: TJSONArray; var aCount: Integer; const aBankFilename: string);
  end;

  TwbIncludedEvent = class(TwbWwiseObject)
  public
    FActionSetStates: TArray<TwbActionSetState>;
    FActionPostEvents: TArray<TwbActionPostEvent>;
    FAuxBusSends: TArray<TwbAuxBusSend>;

    procedure BuildEvent(const aEvent: TJSONObject; var aCount: Integer; const aBankFilename: string);
  end;

  TwbSoundBank = class(TwbWwiseObject)
  public
    FSoundBankArray: TwbSoundBankArray;
    FFilename: string;
    FIncludedEvents: TArray<TwbIncludedEvent>;
    FGameParameters: TArray<TwbGameParameter>;
    FStateGroups: TArray<TwbStateGroup>;
    FSwitchGroups: TArray<TwbSwitchGroup>;
    FIncludedAuxBusses: TArray<TwbIncludedAuxBuss>;
    FExternalSources: TArray<TwbExternalSource>;

    procedure BuildSoundBank(const aSoundBank: TJSONObject; var aCount: Integer; const aBankFilename: string);
  end;

  TwbSoundBankArray = class(TInterfacedObject, IwbSoundBankArray)
  strict private
    {---IwbSoundBankArray---}
    function TryLookupDisplay(const aNodeType   : TwbWwiseNodeType;
                              const aDisplayStr : string;
                                var aGUID       : TGUID)
                                                : Boolean;

    function TryLookupGUID(const aNodeType : TwbWwiseNodeType;
                           const aGUID     : TGUID;
                             var aName     : string;
                             var aFilename : string)
                                           : Boolean;

    procedure GetChildStrings(const aParentGUID: TGUID;
                              const aChildType: TwbWwiseNodeType;
                                var aList: TStringList);

    procedure GetStrings(const aNodeType : TwbWwiseNodeType;
                         const aMasters  : TStringList;
                           var aList     : TStringList);


    {---TwbSoundBankArray---}
    var FComboBoxMap: TDictionary<string, TDictionary<TwbWwiseNodeType, TStringList>>;
    var FDisplayMap: TDictionary<TwbWwiseNodeType, TDictionary<string, TGUID>>;
    var FGuidMap: TDictionary<TwbWwiseNodeType, TDictionary<TGUID, TwbWwiseObject>>;
    var FSoundBanks: TArray<TwbSoundBank>;

    procedure BuildIndexFile(const aFileName, aModuleName: string);
    procedure BuildIndexFiles(const aFileNames: TStringList; const aModuleName: string = '');
    procedure BuildSoundBanks(const aJSON: TJSONObject; const aModuleName: string; var aCount: Integer);

  public
    {---TwbSoundBankArray---}
    constructor Create(const aLoadOrder: TStringList);

    destructor Destroy; override;

    procedure BuildIndex(const aLoadOrder: TStringList);

    procedure RegisterNode(const aNodeType: TwbWwiseNodeType; const aObject: TwbWwiseObject; const aBankFileName: string);
  end;

function wbSoundBankArray(const aLoadOrder: TStringList): IwbSoundBankArray;
begin
  Result := TwbSoundBankArray.Create(aLoadOrder);
end;

{ TwbSwitchGroup }

procedure TwbSwitchGroup.BuildSwitchGroup(const aSwitchGroup: TJSONArray; var aCount: Integer; const aBankFilename: string);
begin
  if aSwitchGroup.Count = 0 then
    Exit;

  SetLength(FSwitches, aSwitchGroup.Count);

  for var I := 0 to Pred(aSwitchGroup.Count) do
  begin
    var lObject := aSwitchGroup[I];
    FSwitches[I] := TwbSwitch.Create;

    with FSwitches[I] do
    begin
      FGUID := StringToGUID(lObject.S['GUID']);
      FName := lObject.S['Name'];
      FParent := Self;
      FRoot := FParent.FRoot;

      FRoot.RegisterNode(wntSwitch, FSwitches[I], aBankFilename);
    end;
  end;

  Inc(aCount, aSwitchGroup.Count);
  //wbProgress('Processed [%d] Switches', [aSwitchGroup.Count]);
end;

{ TwbStateGroup }

procedure TwbStateGroup.BuildStateGroup(const aStateGroup: TJSONArray; var aCount: Integer; const aBankFilename: string);
begin
  if aStateGroup.Count = 0 then
    Exit;

  SetLength(FStates, aStateGroup.Count);

  for var I := 0 to Pred(aStateGroup.Count) do
  begin
    var lObject := aStateGroup[I];
    FStates[I] := TwbState.Create;

    with FStates[I] do
    begin
      FGUID := StringToGUID(lObject.S['GUID']);
      FName := lObject.S['Name'];
      FParent := Self;
      FRoot := FParent.FRoot;

      FRoot.RegisterNode(wntState, FStates[I], aBankFilename);
    end;
  end;

  Inc(aCount, aStateGroup.Count);
  //wbProgress('Processed [%d] States', [aStateGroup.Count]);
end;

{ TwbIncludedEvent }

procedure TwbIncludedEvent.BuildEvent(const aEvent: TJSONObject; var aCount: Integer; const aBankFilename: string);
begin
  var lArray := aEvent.A['ActionSetStates'];
  if lArray.Count > 0 then
  begin
    var lArrayCount := lArray.Count;
    SetLength(FActionSetStates, lArrayCount);

    for var I := 0 to Pred(lArrayCount) do
    begin
      var lObject := lArray[I];
      FActionSetStates[I] := TwbActionSetState.Create;

      with FActionSetStates[I] do
      begin
        FGUID := StringToGUID(lObject.S['GUID']);
        FName := lObject.S['Name'];
        FParent := Self;
        FRoot := FParent.FRoot;

        FRoot.RegisterNode(wntActionSetState, FActionSetStates[I], aBankFilename)
      end;
    end;

    Inc(aCount, lArray.Count);
    //wbProgress('Processed [%d] ActionSetStates', [lArray.Count]);
  end;

  lArray := aEvent.A['ActionPostEvents'];
  if lArray.Count > 0 then
  begin
    var lArrayCount := lArray.Count;
    SetLength(FActionPostEvents, lArrayCount);

    for var I := 0 to Pred(lArrayCount) do
    begin
      var lObject := lArray[I];
      FActionPostEvents[I] := TwbActionPostEvent.Create;

      with FActionPostEvents[I] do
      begin
        FGUID := StringToGUID(lObject.S['GUID']);
        FName := lObject.S['Name'];
        FParent := Self;
        FRoot := FParent.FRoot;

        FRoot.RegisterNode(wntActionPostEvent, FActionPostEvents[I], aBankFilename);
      end;
    end;

    Inc(aCount, lArray.Count);
    //wbProgress('Processed [%d] ActionPostEvents', [lArray.Count]);
  end;

  lArray := aEvent.A['AuxBusSends'];
  if lArray.Count > 0 then
  begin
    var lArrayCount := lArray.Count;
    SetLength(FAuxBusSends, lArrayCount);

    for var I := 0 to Pred(lArrayCount) do
    begin
      var lObject := lArray[I];
      FAuxBusSends[I] := TwbAuxBusSend.Create;

      with FAuxBusSends[I] do
      begin
        FGUID := StringToGUID(lObject.S['GUID']);
        FName := lObject.S['Name'];
        FParent := Self;
        FRoot := FParent.FRoot;

        FRoot.RegisterNode(wntAuxBusSend, FAuxBusSends[I], aBankFilename);
      end;
    end;

    Inc(aCount, lArray.Count);
    //wbProgress('Processed [%d] AuxBusSends', [lArray.Count]);
  end;
end;

{ TwbSoundBank }

procedure TwbSoundBank.BuildSoundBank(const aSoundBank: TJSONObject; var aCount: Integer; const aBankFilename: string);
begin
  var lArray := aSoundBank.A['IncludedEvents'];
  if lArray.Count > 0 then
  begin
    SetLength(FIncludedEvents, lArray.Count);

    for var I := 0 to Pred(lArray.Count) do
    begin
      var lObject := lArray[I];
      FIncludedEvents[I] := TwbIncludedEvent.Create;

      with FIncludedEvents[I] do
      begin
        FGUID := StringToGUID(lObject.S['GUID']);
        FName := lObject.S['Name'];
        FParent := Self;
        FRoot := FParent.FRoot;

        FRoot.RegisterNode(wntIncludedEvent, FIncludedEvents[I], aBankFilename);

        BuildEvent(lObject, aCount, aBankFilename);
      end;
    end;

    Inc(aCount, lArray.Count);
    //wbProgress('Processed [%d] IncludedEvents', [lArray.Count]);
  end;

  lArray := aSoundBank.A['GameParameters'];
  if lArray.Count > 0 then
  begin
    SetLength(FGameParameters, lArray.Count);

    for var I := 0 to Pred(lArray.Count) do
    begin
      var lObject := lArray[I];
      FGameParameters[I] := TwbGameParameter.Create;

      with FGameParameters[I] do
      begin
        FGUID := StringToGUID(lObject.S['GUID']);
        FName := lObject.S['Name'];
        FParent := Self;
        FRoot := FParent.FRoot;

        FRoot.RegisterNode(wntGameParameter, FGameParameters[I], aBankFilename);
      end;
    end;

    Inc(aCount, lArray.Count);
    //wbProgress('Processed [%d] GameParameters', [lArray.Count]);
  end;

  lArray := aSoundBank.A['StateGroups'];
  if lArray.Count > 0 then
  begin
    SetLength(FStateGroups, lArray.Count);

    for var I := 0 to Pred(lArray.Count) do
    begin
      var lObject := lArray[I];
      FStateGroups[I] := TwbStateGroup.Create;

      with FStateGroups[I] do
      begin
        FGUID := StringToGUID(lObject.S['GUID']);
        FName := lObject.S['Name'];
        FParent := Self;
        FRoot := FParent.FRoot;

        FRoot.RegisterNode(wntStateGroup, FStateGroups[I], aBankFilename);

        BuildStateGroup(lObject.A['States'], aCount, aBankFilename);
      end;
    end;

    Inc(aCount, lArray.Count);
    //wbProgress('Processed [%d] StateGroups', [lArray.Count]);
  end;

  lArray := aSoundBank.A['SwitchGroups'];
  if lArray.Count > 0 then
  begin
    SetLength(FSwitchGroups, lArray.Count);

    for var I := 0 to Pred(lArray.Count) do
    begin
      var lObject := lArray[I];
      FSwitchGroups[I] := TwbSwitchGroup.Create;

      with FSwitchGroups[I] do
      begin
        FGUID := StringToGUID(lObject.S['GUID']);
        FName := lObject.S['Name'];
        FParent := Self;
        FRoot := FParent.FRoot;

        FRoot.RegisterNode(wntSwitchGroup, FSwitchGroups[I], aBankFilename);

        BuildSwitchGroup(lObject.A['Switches'], aCount, aBankFilename);
      end;
    end;

    Inc(aCount, lArray.Count);
    //wbProgress('Processed [%d] SwitchGroups', [lArray.Count]);
  end;

  lArray := aSoundBank.A['IncludedAuxBusses'];
  if lArray.Count > 0 then
  begin
    SetLength(FIncludedAuxBusses, lArray.Count);

    for var I := 0 to Pred(lArray.Count) do
    begin
      var lObject := lArray[I];
      FIncludedAuxBusses[I] := TwbIncludedAuxBuss.Create;

      with FIncludedAuxBusses[I] do
      begin
        FGUID := StringToGUID(lObject.S['GUID']);
        FName := lObject.S['Name'];
        FParent := Self;
        FRoot := FParent.FRoot;

        FRoot.RegisterNode(wntIncludedAuxBuss, FIncludedAuxBusses[I], aBankFilename);
      end;
    end;

    Inc(aCount, lArray.Count);
    wbProgress('Processed [%d] IncludedAuxBusses', [lArray.Count]);
  end;

  lArray := aSoundBank.A['ExternalSources'];
  if lArray.Count > 0 then
  begin
    SetLength(FExternalSources, lArray.Count);

    for var I := 0 to Pred(lArray.Count) do
    begin
      var lObject := lArray[I];
      FExternalSources[I] := TwbExternalSource.Create;

      with FExternalSources[I] do
      begin
        FGUID := StringToGUID(lObject.S['GUID']);
        FName := lObject.S['Name'];
        FParent := Self;
        FRoot := FParent.FRoot;

        FRoot.RegisterNode(wntExternalSource, FExternalSources[I], aBankFilename);
      end;
    end;

    Inc(aCount, lArray.Count);
    //wbProgress('Processed [%d] ExternalSources', [lArray.Count]);
  end;
end;


{ TwbSoundBankArray }

procedure TwbSoundBankArray.BuildIndex(const aLoadOrder: TStringList);
begin
  BuildIndexFile('sound\soundbanks\soundbanksinfo.json', 'Starfield.esm');

  var lHardcodedSoundBanks := TStringList.Create;
  with lHardcodedSoundBanks do
  try
    Add('Init');
    Add('Starfield_AMB');
    Add('Starfield_DRS');
    Add('Starfield_FST');
    Add('Starfield_FX');
    Add('Starfield_ITM');
    Add('Starfield_MUS');
    Add('Starfield_NPC');
    Add('Starfield_OBJ');
    Add('Starfield_PHY');
    Add('Starfield_QST');
    Add('Starfield_UI');
    Add('Starfield_VEH');
    Add('Starfield_VOC');
    Add('Starfield_WPN');

    BuildIndexFiles(lHardcodedSoundBanks, 'Starfield.esm');
  finally
    Free;
  end;

  BuildIndexFiles(aLoadOrder);
end;

procedure TwbSoundBankArray.BuildIndexFile(const aFileName, aModuleName: string);
begin
  var lFile := wbContainerHandler.OpenResourceData('', aFileName);

  if Length(lFile) > 0 then
  begin
    var lJSON := TJSONObject.Create;
    try
      var lCount := 0;

      lJSON.FromUtf8JSON(PByte(@lFile[0]), Length(lFile));

      BuildSoundBanks(lJSON, aModuleName, lCount);

      wbProgress('[%s] Indexed %d GUIDs from', [aModuleName, lCount]);
    finally
      lJSON.Free;
    end;
  end;
end;

procedure TwbSoundBankArray.BuildIndexFiles(const aFileNames: TStringList; const aModuleName: string = '');
begin
  for var I := 0 to Pred(aFileNames.Count) do
  begin
    var lFile := aFileNames[I];
    var lFileName := TPath.GetFileNameWithoutExtension(lFile);
    var lHash := TwbHash.FNV132(lFileName, True);
    var lBankName := 'sound\soundbanks\' + UIntToStr(lHash) + '.json';

    var lModuleName: string;
    if aModuleName <> '' then
      lModuleName := aModuleName
    else
      lModuleName := lFile;

    BuildIndexFile(lBankName, lModuleName);
  end;
end;

procedure TwbSoundBankArray.BuildSoundBanks(const aJSON: TJSONObject; const aModuleName: string; var aCount: Integer);
begin
  var lSoundBanksInfo:= aJSON.O['SoundBanksInfo'];
  var lSoundBanks := lSoundBanksInfo.A['SoundBanks'];

  var lSoundBanksCount := lSoundBanks.Count;
  if lSoundBanksCount > 0 then
  begin
    for var I := 0 to Pred(lSoundBanksCount) do
    begin
      var lSoundBank := lSoundBanks[I];
      SetLength(FSoundBanks, Succ(Length(FSoundBanks)));

      FSoundBanks[High(FSoundBanks)] := TwbSoundBank.Create;

      with FSoundBanks[I] do
      begin
        FFilename := aModuleName;
        FGUID := StringToGUID(lSoundBank.S['GUID']);
        FName := lSoundBank.S['ShortName'];
        FRoot := Self;

        RegisterNode(wntSoundBank, FSoundBanks[I], FFilename);

        BuildSoundBank(lSoundBank, aCount, FFilename);
      end;
    end;
    Inc(aCount, lSoundBanksCount);
    //wbProgress('Processed [%d] SoundBanks', [lSoundBanksCount]);
  end;
end;

constructor TwbSoundBankArray.Create(const aLoadOrder: TStringList);
begin
  inherited Create;

  FComboBoxMap := TDictionary<string, TDictionary<TwbWwiseNodeType, TStringList>>.Create;
  FDisplayMap := TDictionary<TwbWwiseNodeType, TDictionary<string, TGUID>>.Create;
  FGuidMap := TDictionary<TwbWwiseNodeType, TDictionary<TGUID, TwbWwiseObject>>.Create;

  for var lNodeType := Low(TwbWwiseNodeType) to High(TwbWwiseNodeType) do
  begin
    FDisplayMap.Add(lNodeType, TDictionary<string, TGUID>.Create);
    FGUIDMap.Add(lNodeType, TDictionary<TGUID, TwbWwiseObject>.Create);
  end;

  BuildIndex(aLoadOrder);
end;

destructor TwbSoundBankArray.Destroy;
begin
  for var lNodeType := Low(TwbWwiseNodeType) to High(TwbWwiseNodeType) do
  begin
    FDisplayMap[lNodeType].Free;
    FGuidMap[lNodeType].Free;
  end;

  for var lInnerMap in FComboBoxMap.Values do
  begin
    for var llist in lInnerMap.Values do
      lList.Free;
    lInnerMap.Free;
  end;

  FComboBoxMap.Free;
  FDisplayMap.Free;
  FGuidMap.Free;

  inherited;
end;

procedure TwbSoundBankArray.GetChildStrings(const aParentGUID: TGUID;
                                            const aChildType: TwbWwiseNodeType;
                                              var aList: TStringList);
begin
  if not Assigned(aList) then
    Exit;

  aList.BeginUpdate;
  try
    aList.Sorted := True;
    aList.Duplicates := dupIgnore;

    var lParentObject: TwbWwiseObject;
    if FGuidMap[wntSwitchGroup].TryGetValue(aParentGUID, lParentObject) then
    begin
      var lWalk := lParentObject;
      while not (lWalk is TwbSoundBank) do
        lWalk := lWalk.FParent;

      var lBank := TwbSoundBank(lWalk);

      if lParentObject is TwbSwitchGroup then
      begin
        var lGroup := TwbSwitchGroup(lParentObject);
        
        for var I := 0 to Pred(Length(lGroup.FSwitches)) do
        begin
          aList.Add(Format('%s [%s]', [lGroup.FSwitches[I].FName, lBank.FFilename]));
        end;
      end;
    end;
  finally
    aList.EndUpdate;
  end;
end;

procedure TwbSoundBankArray.GetStrings(const aNodeType : TwbWwiseNodeType;
                                       const aMasters  : TStringList;
                                         var aList     : TStringList);
begin
  if not Assigned(aList) then
    Exit;

  aList.BeginUpdate;
  try
    aList.Sorted := True;
    aList.Duplicates := dupIgnore;

    var lInnerMap : TDictionary<TwbWwiseNodeType, TStringList>;
    for var I := 0 to Pred(aMasters.Count) do
    begin
      if FComboBoxMap.TryGetValue(aMasters[I], lInnerMap) then
      begin
        var lStrings: TStringList;
        if lInnerMap.TryGetValue(aNodeType, lStrings) then
          aList.AddStrings(lStrings);
      end;
    end;
  finally
    aList.EndUpdate;
  end;
end;

procedure TwbSoundBankArray.RegisterNode(const aNodeType     : TwbWwiseNodeType;
                                         const aObject       : TwbWwiseObject;
                                         const aBankFilename : string);
begin
  var lDisplayString := Format('%s [%s]', [aObject.FName, aBankFileName]);
  FDisplayMap[aNodeType].TryAdd(lDisplayString, aObject.FGUID);

  FGuidMap[aNodeType].TryAdd(aObject.FGUID, aObject);

  var lInnerMap: TDictionary<TwbWwiseNodeType, TStringList>;
  if not FComboBoxMap.TryGetValue(aBankFilename, lInnerMap) then
  begin
    lInnerMap := TDictionary<TwbWwiseNodeType, TStringList>.Create;
    FComboBoxMap.Add(aBankFilename, lInnerMap);
  end;

  var lTargetList: TStringList;
  if not lInnerMap.TryGetValue(aNodeType, lTargetList) then
  begin
    lTargetList := TStringList.Create;
    lTargetList.Sorted := True;
    lTargetList.Duplicates := dupIgnore;
    lInnerMap.Add(aNodeType, lTargetList);
  end;

  lTargetList.Add(lDisplayString);
end;

function TwbSoundBankArray.TryLookupDisplay(const aNodeType     : TwbWwiseNodeType;
                                            const aDisplayStr   : string;
                                              var aGUID: TGUID) : Boolean;
begin
  Result := False;

  if FDisplayMap[aNodeType].TryGetValue(aDisplayStr, aGUID) then
    Exit(True);

  var lString1: string;
  for lString1 in FDisplayMap[aNodeType].Keys do
  begin
    if SameText (lString1, aDisplayStr) then
    begin
      aGUID := FDisplayMap[aNodeType][lString1];
      Exit(True);
    end;
  end;
end;

function TwbSoundBankArray.TryLookupGUID(const aNodeType : TwbWwiseNodeType;
                                         const aGUID     : TGUID;
                                           var aName     : string;
                                           var aFilename : string): Boolean;
begin
  var lObj : TwbWwiseObject;
  Result := FGuidMap[aNodeType].TryGetValue(aGUID, lObj);
  if Result then
  begin
    aName := lObj.FName;

    var lParent := lObj;
    while not (lParent is TwbSoundBank)  do
      lParent := lParent.FParent;

    aFileName := TwbSoundBank(lParent).FFilename;
  end;
end;

end.
