{
  Apply custom scripted filter for female NPC characters
}
unit ApplyCustomScriptedFilter;

function Filter(e: IInterface): Boolean;
begin
  if Signature(e) <> 'NPC_' then
    Exit;
  
  // Female flag
  Result := GetElementNativeValues(e, 'ACBS\Flags') and 1 > 0;
end;

function Initialize: Integer;
begin
  FilterConflictAll := False;
    FilterConflictAllSet :=
	[ // Comment out the options you Don't want
	  caOnlyOne,         //Single Record
	  caNoConflict,      //Multiple But No Conflict
	  caConflictBenign,  //Benign Conflict
	  caOverride,        //Override Without Conflict
	  caConflict,        //Conflict
	  caConflictCritical //Critical Conflict
	];

  FilterConflictThis := False;
    FilterConflictThisSet :=
	[ // Comment out the options you Don't want
	  ctNotDefined,                    //Not Defined
	  ctIdenticalToMaster,             //Identical To Master
	  ctOnlyOne,                       //Single Record
	  ctHiddenByModGroup,              //Hidden By Mod Group
	  ctMaster,                        //Master
	  ctConflictBenign,                //Benign Conflict
	  ctOverride,                      //Override Without Conflict
	  ctIdenticalToMasterWinsConflict, //Identical To Master But Conflict Winner
	  ctConflictWins,                  //Conflict Winner
	  ctConflictLoses                  //Conflict Loser
	];

  FilterDeleted := False;

  FilterByInjectStatus := False;
    FilterInjectStatus := False;

  FilterByReferencesInjectedStatus := False;
    FilterReferencesInjectedStatus := False;

  FilterByNotReachableStatus := False;
    FilterNotReachableStatus := False;

  FilterByEditorID := False;
    FilterEditorID := '';

  FilterByName := False;
    FilterName := '';

  FilterByVWD := False;
    FilterVWD := False;

  FilterByHasVWDMesh := False;
    FilterHasVWDMesh := False;

  FilterByHasPrecombinedMesh := False;
    FilterHasPrecombinedMesh := False;

  FilterByPersistent := False;
    FilterPersistent := False;
      FilterUnnecessaryPersistent := False;
        FilterMasterIsTemporary := False;
        FilterIsMaster := False;
      FilterPersistentPosChanged := False;

  FlattenBlocks := True;
  FlattenCellChilds := True;

  AssignPersWrldChild := False;

  InheritConflictByParent := False; // color conflicts

  FilterByElementValue := False;
    FilterElementValue := '';
	
  FilterByRegexComparison := False;

  FilterBySignature := False;
    FilterSignatures := '';
  FilterByBaseSignature := False;
    FilterBaseSignatures := '';

  FilterByBaseEditorID := False;
    FilterBaseEditorID := '';

  FilterByBaseName := False;
    FilterBaseName := '';

  FilterScaledActors := False;

  FilterScripted := True; // use custom Filter() function

  ApplyFilter;

  Result := 1;
end;

end.