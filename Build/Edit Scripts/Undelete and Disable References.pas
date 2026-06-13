{
  Undelete and disable references, almost the copy of internal
  xEdit code.
  Does not require applied filter.
}
unit UserScript;

var
  UndeletedCount, NAVMCount: integer;
  
function Process(e: IInterface): integer;
var
  Sig: string;
  XESP: IInterface;
begin
  Result := 0;
  
  if not (IsEditable(e) and GetIsDeleted(e)) then
    Exit;
  
  Sig := Signature(e);

  if 
    (Sig <> 'REFR') and
    (Sig <> 'PGRE') and
    (Sig <> 'PMIS') and
    (Sig <> 'ACHR') and
    (Sig <> 'ACRE') and
    (Sig <> 'NAVM') and
    (Sig <> 'PARW') and // Skyrim
    (Sig <> 'PBAR') and // Skyrim
    (Sig <> 'PBEA') and // Skyrim
    (Sig <> 'PCON') and // Skyrim
    (Sig <> 'PFLA') and // Skyrim
    (Sig <> 'PHZD')     // Skyrim
  then
    Exit;

  // don't process navmeshes but count deleted ones
  if Sig = 'NAVM' then begin
    Inc(NAVMCount);
    Exit;
  end;
  
  AddMessage('Undeleting: ' + Name(e));
  
  // undelete
  SetIsDeleted(e, True);
  SetIsDeleted(e, False);
    
  // place it below the ground
  SetElementNativeValues(e, 'DATA\Position\Z', -30000);

  RemoveElement(e, 'XTEL');
  // ... remove anything else here
  
  // set to disabled
  SetIsInitiallyDisabled(e, True);
  
  // add enabled opposite of player (true - silent)
  XESP := ElementBySignature(e, 'XESP');
  if not Assigned(XESP) then
    XESP := Add(e, 'XESP', True);
  
  SetElementNativeValues(XESP, 'Reference', $14); // Player ref
  SetElementNativeValues(XESP, '[1]', 1);  // opposite of parent flag

  Inc(UndeletedCount);
end;

function Finalize: integer;
begin
  AddMessage('Undeleted Records: ' + IntToStr(UndeletedCount));
  if NAVMCount > 0 then
    AddMessage(Format('<Warning: Plugin contains %d deleted NavMeshes which can not be undeleted>', [NAVMCount]));
end;

end.