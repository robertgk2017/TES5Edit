unit wbConflict;

interface

uses
  wbInterface;

function wbConflictLevelForNodeDatas(const aNodeDatas: PwbConflictNodeDatas; aNodeCount: Integer; aSiblingCompare, aInjected: Boolean): TConflictAll;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Math;

function wbConflictLevelForNodeDatas(const aNodeDatas: PwbConflictNodeDatas; aNodeCount: Integer; aSiblingCompare, aInjected: Boolean): TConflictAll;
var
  Element                : IwbElement;
  CompareElement         : IwbElement;
  i, j                   : Integer;
  UniqueValues           : TwbFastStringListCS;

  MasterPosition         : Integer;
  FirstElement           : IwbElement;
  FirstElementNotIgnored : IwbElement;
  LastElement            : IwbElement;
  SameAsLast             : Boolean;
  SameAsFirst            : Boolean;
  OverallConflictThis    : TConflictThis;
  Priority               : TwbConflictPriority;
  ThisPriority           : TwbConflictPriority;
  FoundAny               : Boolean;

  ElementTypes           : TwbElementTypes;
  DefTypes               : TwbDefTypes;
  OptionalAndMissing     : Boolean;
begin
//  if aSiblingCompare then
//    Priority := cpBenign
//  else
//    Priority := cpNormal;
//  IgnoreConflicts := False;
  FoundAny := False;
  MasterPosition := 0;
  OverallConflictThis := ctUnknown;

  var lNodeCount := 0;
  var lFirstNode := PwbConflictNodeData(nil);

  if aNodeCount = 1 then begin
    lNodeCount := 1;
    lFirstNode := @aNodeDatas[0];
  end else
    for i := 0 to Pred(aNodeCount) do
      if aNodeDatas[i].ViewNodeFlags * [vnfDontShow, vnfIgnore] <> [] then with aNodeDatas[i] do begin
        ConflictThis := ctNotDefined;
        if Assigned(Element) and (vnfIgnore in ViewNodeFlags) then
          ConflictThis := ctIgnored;
      end else begin
        Inc(lNodeCount);
        if not Assigned(lFirstNode) then
          lFirstNode := @aNodeDatas[i];
      end;

  case lNodeCount of
    0: Result := caUnknown;
    1: begin
        Element := lFirstNode^.Element;
        if Assigned(Element) then begin
          if Element.ConflictPriority = cpIgnore then
            lFirstNode^.ConflictThis := ctIgnored
          else
            lFirstNode^.ConflictThis := ctOnlyOne;
        end else
          lFirstNode^.ConflictThis := ctNotDefined;
        Result := caOnlyOne;
      end
  else
    var lLastIndex := Pred(aNodeCount);

    LastElement := aNodeDatas[lLastIndex].Element;
    while not Assigned(LastElement) and (vnfIsPartialForm in aNodeDatas[lLastIndex].ViewNodeFlags) and (lLastIndex > 0) do begin
      Dec(lLastIndex);
      LastElement := aNodeDatas[lLastIndex].Element;
    end;
    FirstElement := lFirstNode.Element;

    UniqueValues := TwbFastStringListCS.Create;
    UniqueValues.Sorted := True;
    UniqueValues.Duplicates := dupIgnore;
    Priority := cpNormal;
    try
      for i := 0 to Pred(aNodeCount) do begin
        Element := aNodeDatas[i].Element;
        if Assigned(Element) then begin
          FoundAny := True;
          Priority := Element.ConflictPriority;
          if Priority = cpNormalIgnoreEmpty then begin
            FirstElement := Element;
            MasterPosition := i;
            for j := Pred(aNodeCount) downto i do begin
              LastElement := aNodeDatas[j].Element;
              if Assigned(LastElement) then
                Break;
            end;
          end;
          if Element.ConflictPriorityCanChange then begin
            for j := Succ(i) to Pred(aNodeCount) do begin
              Element := aNodeDatas[j].Element;
              if Assigned(Element) then begin
                ThisPriority := Element.ConflictPriority;
                if ThisPriority > Priority then
                  Priority := ThisPriority;
              end;
            end;
          end;
          Break;
        end;
      end;

      if aSiblingCompare then
        if Priority > cpBenign then
          Priority := cpBenign;
      if aInjected and (Priority >= cpNormal) then
        Priority := cpCritical;

      if (Priority > cpIgnore) and (not Assigned(FirstElement) or (FirstElement.ConflictPriority = cpIgnore)) then
        FirstElementNotIgnored := nil
      else
        FirstElementNotIgnored := FirstElement;

      ElementTypes := [];
      DefTypes := [];
      OptionalAndMissing := False;

      for i := 0 to Pred(aNodeCount) do begin
        Element := aNodeDatas[i].Element;
        if Assigned(Element) then begin
          Include(ElementTypes, Element.ElementType);
          if Assigned(Element.ValueDef) then
            Include(DefTypes, Element.ValueDef.DefType)
          else
            Include(DefTypes, dtEmpty);
          OptionalAndMissing := OptionalAndMissing or (esOptionalAndMissing in Element.ElementStates);

          ThisPriority := Element.ConflictPriority;
          if ThisPriority <> cpIgnore then
            UniqueValues.Add(Element.DisplaySortKey[True]);
        end else if (vnfIsPartialForm in aNodeDatas[i].ViewNodeFlags) then begin
          ThisPriority := cpIgnore;
        end else begin
          Include(DefTypes, dtEmpty);
          ThisPriority := Priority;
          if not (vnfIgnore in aNodeDatas[i].ViewNodeFlags) then
            if Priority <> cpNormalIgnoreEmpty then
              UniqueValues.Add('');
        end;

        if (ThisPriority = cpNormalIgnoreEmpty) and not Assigned(Element) then
          aNodeDatas[i].ConflictThis := ctIgnored
        else if ThisPriority = cpIgnore then
          aNodeDatas[i].ConflictThis := ctIgnored
        else if aSiblingCompare then
          aNodeDatas[i].ConflictThis := ctOnlyOne
        else if i = MasterPosition then begin

          if Assigned(Element) then
            aNodeDatas[i].ConflictThis := ctMaster
          else
            aNodeDatas[i].ConflictThis := ctUnknown;

        end else begin
          SameAsLast := (i = Pred(aNodeCount)) or not (
            (Assigned(Element) <> Assigned(LastElement)) or
            (Assigned(Element) and not SameStr(Element.DisplaySortKey[True], LastElement.DisplaySortKey[True]))
            );

          SameAsFirst := not (
            (Assigned(Element) <> Assigned(FirstElementNotIgnored)) or
            (Assigned(Element) and not SameStr(Element.DisplaySortKey[True], FirstElementNotIgnored.DisplaySortKey[True]))
            );

          if not SameAsFirst and
             (ThisPriority = cpBenignIfAdded) and
             SameAsLast and  // We are not overriden later
             not Assigned(FirstElementNotIgnored) then begin // The master did not have that element
            ThisPriority := cpBenign;
            Priority := cpBenign;
            SameAsFirst := True;
          end;

          if SameAsFirst then
            aNodeDatas[i].ConflictThis := ctIdenticalToMaster
          else if SameAsLast then
            aNodeDatas[i].ConflictThis := ctConflictWins
          else
            aNodeDatas[i].ConflictThis := ctConflictLoses;
        end;

        if (ThisPriority = cpBenign) and (aNodeDatas[i].ConflictThis > ctConflictBenign) then
          aNodeDatas[i].ConflictThis := ctConflictBenign;
        if (ThisPriority = cpOverride) and (aNodeDatas[i].ConflictThis > ctOverride) then
          aNodeDatas[i].ConflictThis := ctOverride;

        if aNodeDatas[i].ConflictThis > OverallConflictThis then
          OverallConflictThis := aNodeDatas[i].ConflictThis;
      end;

      case UniqueValues.Count of
        0: Result := caNoConflict;
        1: Result := caNoConflict;
        2: begin
            Element := aNodeDatas[0].Element;
            var lCompareIndex := Pred(aNodeCount);
            CompareElement := aNodeDatas[lCompareIndex].Element;
            while not Assigned(CompareElement) and (vnfIsPartialForm in aNodeDatas[lCompareIndex].ViewNodeFlags) and (lCompareIndex > 0) do begin
              Dec(lCompareIndex);
              CompareElement := aNodeDatas[lCompareIndex].Element;
            end;
            if (Assigned(Element) <> Assigned(CompareElement)) or
              (Assigned(Element) and not SameStr(Element.DisplaySortKey[True], CompareElement.DisplaySortKey[True])) then
              Result := caOverride
            else if (UniqueValues.IndexOf('') >= 0) and Assigned(CompareElement) and (CompareElement.DisplaySortKey[True] <> '') then
              Result := caOverride
            else
              Result := caConflict;
          end
      else
        Result := caConflict;
      end;

      if aSiblingCompare and (Result > caConflictBenign) then
        Result := caConflictBenign;

      if not FoundAny then
        for i := 0 to Pred(aNodeCount) do
          aNodeDatas[i].ConflictThis := ctNotDefined;

      if Result > caNoConflict then
        case Priority of
          cpBenign: Result := caConflictBenign;
          cpOverride: Result := caOverride;
          cpCritical: begin
              if UniqueValues.Find('', i) then
                UniqueValues.Delete(i);
              if UniqueValues.Count > 1 then
                Result := caConflictCritical;
            end;
        end;

      if Priority > cpBenign then
        if OverallConflictThis > ctOverride then
          with aNodeDatas[Pred(aNodeCount)] do
            if ConflictThis < ctOverride then
              if ConflictThis = ctIdenticalToMaster then
                ConflictThis := ctIdenticalToMasterWinsConflict
              else
                ConflictThis := ctConflictWins;

      if Result in [caNoConflict, caOverride, caConflict] then
        for i := 0 to Pred(aNodeCount) do begin
          case aNodeDatas[i].ConflictThis of
            ctIdenticalToMaster: case Result of
                caNoConflict: ;
                caOverride, caConflict: if i = Pred(aNodeCount) then
                  aNodeDatas[i].ConflictThis := ctIdenticalToMasterWinsConflict
              end;
            ctConflictWins: case Result of
              caNoConflict: aNodeDatas[i].ConflictThis := ctIdenticalToMaster;
              caOverride: aNodeDatas[i].ConflictThis := ctOverride;
              caConflict: ;
            end;
          end;
        end;

      if Result < caConflict then
        for i := 0 to Pred(aNodeCount) do
          if aNodeDatas[i].ConflictThis >= ctIdenticalToMasterWinsConflict then begin
            Result := caConflict;
            Break;
          end;

      if    (Result > caNoConflict)
        and OptionalAndMissing
        and (ElementTypes <= [etArray, etStruct, etValue])
        and (dtEmpty in DefTypes)
        and ((DefTypes - [dtEmpty]).Count = 1)
        and ((DefTypes - [dtEmpty, dtString..dtInteger, dtFloat, dtArray, dtStruct]).Count = 0) then begin

        for i := 0 to Pred(aNodeCount) do
          if Assigned(aNodeDatas[i].Element) then
            if not aNodeDatas[i].Element.ContentIsAllZero then
              Exit;

        Result := caNoConflict;

        for i := 0 to Pred(aNodeCount) do begin
          if aNodeDatas[i].ConflictThis > ctIdenticalToMaster then
            aNodeDatas[i].ConflictThis := ctIdenticalToMaster;
          if aNodeDatas[i].ConflictAll > caNoConflict then
            aNodeDatas[i].ConflictAll := caNoConflict;
        end;

      end;

    finally
      FreeAndNil(UniqueValues);
    end;
  end;
end;

end.
