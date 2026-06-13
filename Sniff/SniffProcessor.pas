{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit SniffProcessor;

interface

uses
  System.Classes,
  System.IniFiles,
  System.SyncObjs,
  System.SysUtils,

  Vcl.Forms,

  wbBSArchive;

type
  TGameType = (gtTES3, gtTES4, gtFO3, gtFNV, gtTES5, gtSSE, gtFO4);
  TGameTypes = set of TGameType;

  TProcBase = class;
  TProcBases = array of TProcBase;
  TProcManager = class;

  TProcFileObject = class
    Manager: TProcManager;
    FileName: string;
    FileEntry: TwbBSFileEntry;
    function GetData: TBytes;
  end;

  TProcManager = class
  protected
    fSettings: TMemIniFile;
    fMessages: TStringList;
    fDirectories: TStringList;
    {$IF CompilerVersion >= 34.0} { Delphi 10.4 } SyncLog: TLightweightMREW; {$ELSE} SyncLog: IReadWriteSync; {$IFEND}
    {$IF CompilerVersion >= 34.0} { Delphi 10.4 } SyncIO: TLightweightMREW; {$ELSE} SyncIO: IReadWriteSync; {$IFEND}
    fInputArchive: TwbBSArchive;
    fInputDirectory: string;
    fOutputDirectory: string;
    fCopyAll: Boolean;
    fSkipOnErrors: Boolean;
    fProc: TProcBase;
    fModifiedCount: Integer;
    fProcessedCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function GameTypeName(aGameType: TGameType): string;
    procedure SetIniFile(aFile: TMemIniFile);
    procedure AddMessage(const aText: string);
    procedure AddMessages(const aStrings: TStrings);
    procedure ClearMessages;
    procedure CreateDirectory(const aPath: string);
    procedure InitializeProcessing(aProc: TProcBase);
    procedure Process(aFile: TProcFileObject);

    property Settings: TMemIniFile read fSettings;
    property Messages: TStringList read fMessages;
    property InputArchive: TwbBSArchive read fInputArchive write fInputArchive;
    property InputDirectory: string read fInputDirectory write fInputDirectory;
    property OutputDirectory: string read fOutputDirectory write fOutputDirectory;
    property CopyAll: Boolean read fCopyAll write fCopyAll;
    property SkipOnErrors: Boolean read fSkipOnErrors write fSkipOnErrors;
    property Proc: TProcBase read fProc;
    property ModifiedCount: Integer read fModifiedCount;
    property ProcessedCount: Integer read fProcessedCount;
  end;

  TProcBase = class
  protected
    fManager: TProcManager;
    fGroupID: Integer;
    fTitle: string;
    fSupportedGames: TGameTypes;
    fExtensions: array of string;
    fNoOutput: Boolean;
    fThreads: Integer;

    procedure AddMessage(const aText: string);
    procedure AddMessages(const aStrings: TStrings);
    function GetSupportedGameNames: string;
    function GetExtensionNames: string;
    procedure SetExtensionNames(const aExtensions: string);
    function GetStorageSection: string;

    procedure StorageSetBool(const aName: string; aValue: Boolean);
    procedure StorageSetInteger(const aName: string; aValue: Integer);
    procedure StorageSetString(const aName: string; const aValue: string);
    function StorageGetBool(const aName: string; aDefaultValue: Boolean): Boolean;
    function StorageGetInteger(const aName: string; aDefaultValue: Integer): Integer;
    function StorageGetString(const aName: string; const aDefaultValue: string): string;

  public
    constructor Create(aManager: TProcManager); virtual;
    function GetFrame(aOwner: TComponent): TFrame; virtual; abstract;
    function IsAcceptedFile(const aFileName: string): Boolean;
    function ProcessFile(aFile: TProcFileObject): TBytes; virtual;

    procedure OnShow; virtual;
    procedure OnHide; virtual;
    procedure OnStart; virtual;
    procedure OnStop; virtual;

    property GroupID: Integer read fGroupID write fGroupID;
    property Title: string read fTitle;
    property NoOutput: Boolean read fNoOutput;
    property Threads: Integer read fThreads write fThreads;
    property SupportedGames: TGameTypes read fSupportedGames;
    property SupportedGameNames: string read GetSupportedGameNames;
    property ExtensionNames: string read GetExtensionNames write SetExtensionNames;
    property StorageSection: string read GetStorageSection;
  end;

function SelectFolder(var aPath: string): Boolean;
function SelectArchive(var aPath: string): Boolean;
function TextToString(const aText: string): string;
function StringToText(const aText: string): string;
function IsPowerOf2(x: Cardinal): Boolean;


implementation

uses
  System.IOUtils,

  Vcl.Dialogs;

function SelectFolder(var aPath: string): Boolean;
begin
  with TFileOpenDialog.Create(Application.MainForm) do try
    Options := [fdoPickFolders, fdoPathMustExist];
    DefaultFolder := aPath;

    Result := Execute;
    if Result then
      aPath := FileName;
  finally
    Free;
  end;
end;

function SelectArchive(var aPath: string): Boolean;
begin
  with TFileOpenDialog.Create(Application.MainForm) do try
    with FileTypes.Add do begin
      DisplayName := 'BSA archive';
      FileMask := '*.bsa';
    end;
    with FileTypes.Add do begin
      DisplayName := 'BA2 archive';
      FileMask := '*.ba2';
    end;
    Options := [fdoFileMustExist];
    if TwbBSArchive.IsArchive(aPath) then begin
      FileName := aPath;
      if SameText(ExtractFileExt(aPath), '.ba2') then
        FileTypeIndex := 2;
    end else
      DefaultFolder := ExtractFilePath(aPath);

    Result := Execute;
    if Result then
      aPath := FileName;
  finally
    Free;
  end;
end;

function TextToString(const aText: string): string;
begin
  Result := StringReplace(aText, #13, '#13', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '#10', [rfReplaceAll]);
end;

function StringToText(const aText: string): string;
begin
  Result := StringReplace(aText, '#13', #13, [rfReplaceAll]);
  Result := StringReplace(Result, '#10', #10, [rfReplaceAll]);
end;

function IsPowerOf2(x: Cardinal): Boolean;
begin
  Result := (x <> 0) and (x <> 1) and ( (x and (x - 1)) = 0 );
end;

{ TProcFileObject }

function TProcFileObject.GetData: TBytes;
begin
  if Assigned(FileEntry) then
    Result := FileEntry.Unpack
  else
    Result := TFile.ReadAllBytes(Manager.InputDirectory + FileName);
end;

constructor TProcManager.Create;
begin
  fMessages := TStringList.Create;
  fDirectories := TStringList.Create;
  fDirectories.Sorted := True;
  {$IF CompilerVersion < 34.0}
  SyncLog := TReadWriteSync.Create;
  SyncIO := TReadWriteSync.Create;
  {$IFEND}
end;

{ TProcManager }

destructor TProcManager.Destroy;
begin
  fMessages.Free;
  fDirectories.Free;
  if Assigned(fInputArchive) then
    fInputArchive.Free;
end;

procedure TProcManager.InitializeProcessing(aProc: TProcBase);
begin
  fProc := aProc;
  fMessages.Clear;
  fDirectories.Clear;
  fModifiedCount := 0;
  fProcessedCount := 0;
end;

procedure TProcManager.Process(aFile: TProcFileObject);
var
  outfile, d, err: string;
  data: TBytes;
  bUpdated: Boolean;
  bSkipped: Boolean;
begin
  bUpdated := False;
  bSkipped := False;

  try
    data := Proc.ProcessFile(aFile);
  except
    on E: Exception do begin
      if fSkipOnErrors { Pos('Unknown NIF version', E.Message) <> 0 } then begin
        bSkipped := True;
        err := E.Message;
      end else
        raise;
    end;
  end;

  AtomicIncrement(fProcessedCount);

  if not bSkipped then begin
    if Proc.NoOutput then
      Exit;

    // file has been changed
    bUpdated := Length(data) <> 0;

    // if not changed but option to copy all is checked then load original
    if not bUpdated and fCopyAll then
      data := aFile.GetData;

    // if nothing to save at this point
    if Length(data) = 0 then
      Exit;

    // saving output file
    outfile := fOutputDirectory + aFile.FileName;
    d := ExtractFilePath(outfile);
    if d <> fOutputDirectory then
      CreateDirectory(d);

    TFile.WriteAllBytes(outfile, data);
  end;

  if bSkipped then
    AddMessage('Skipped: ' + aFile.FileName + ': ' + err)
  else if bUpdated then begin
    AddMessage('Updated: ' + aFile.FileName);
    AtomicIncrement(fModifiedCount);
  end else
    AddMessage('Unchanged: ' + aFile.FileName);
end;

procedure TProcManager.AddMessage(const aText: string);
begin
  SyncLog.BeginWrite;
  try
    fMessages.Add(aText);
  finally
    SyncLog.EndWrite;
  end;
end;

procedure TProcManager.AddMessages(const aStrings: TStrings);
begin
  SyncLog.BeginWrite;
  try
    fMessages.AddStrings(aStrings);
  finally
    SyncLog.EndWrite;
  end;
end;

procedure TProcManager.ClearMessages;
begin
  fMessages.Clear;
end;

procedure TProcManager.CreateDirectory(const aPath: string);
begin
  SyncIO.BeginWrite;
  try
    if fDirectories.IndexOf(aPath) <> -1 then
      Exit;

    if not ForceDirectories(aPath) then
      raise Exception.Create('Can not create directory: ' + aPath);

    fDirectories.Add(aPath);
  finally
    SyncIO.EndWrite;
  end;
end;

function TProcManager.GameTypeName(aGameType: TGameType): string;
const
  GameNames: array[TGameType] of string = (
    'Morrowind',
    'Oblivion',
    'Fallout 3',
    'New Vegas',
    'Skyrim LE',
    'Skyrim SE',
    'Fallout 4'
  );
begin
  Result := GameNames[aGameType];
end;

procedure TProcManager.SetIniFile(aFile: TMemIniFile);
begin
  fSettings := aFile;
end;


{ TProcBase }

constructor TProcBase.Create(aManager: TProcManager);
begin
  fManager := aManager;
end;

procedure TProcbase.AddMessage(const aText: string);
begin
  fManager.AddMessage(aText);
end;

procedure TProcBase.AddMessages(const aStrings: TStrings);
begin
  fManager.AddMessages(aStrings);
end;

function TProcBase.GetSupportedGameNames: string;
begin
  Result := '';
  for var g in fSupportedGames do begin
    if Result <> '' then
      Result := Result + ', ';

    Result := Result + fManager.GameTypeName(g);
  end;
end;

function TProcBase.GetExtensionNames: string;
begin
  Result := '';
  for var s in fExtensions do begin
    if Result <> '' then
      Result := Result + ', ';

    Result := Result + '*.' + s
  end;
end;

procedure TProcBase.SetExtensionNames(const aExtensions: string);
var
  NewExtensions: array of String;
begin
  for var s in aExtensions.Split([',']) do begin
    var ext := LowerCase(ExtractFileExt(Trim(s)));
    if ext = '' then Continue;
    if ext[1] = '.' then
      Delete(ext, 1, 1);
    NewExtensions := NewExtensions + [ext];
  end;

  SetLength(fExtensions, 0);
  for var s in NewExtensions do
    fExtensions := fExtensions + [s];
end;

function TProcBase.IsAcceptedFile(const aFileName: string): Boolean;
var
  ext: string;
begin
  Result := False;
  ext := LowerCase(ExtractFileExt(aFileName));
  if ext <> '' then
    Delete(ext, 1, 1);
  for var s: string in fExtensions do
    if s = ext then Exit(True)
end;

function TProcBase.ProcessFile(aFile: TProcFileObject): TBytes;
begin

end;


function TProcBase.GetStorageSection: string;
begin
  Result := StringReplace(fTitle, ' ', '', [rfReplaceAll]);
end;

procedure TProcBase.StorageSetBool(const aName: string; aValue: Boolean);
begin
  if Assigned(fManager.Settings) then
    fManager.Settings.WriteBool(StorageSection, aName, aValue);
end;

procedure TProcBase.StorageSetInteger(const aName: string; aValue: Integer);
begin
  if Assigned(fManager.Settings) then
    fManager.Settings.WriteInteger(StorageSection, aName, aValue);
end;

procedure TProcBase.StorageSetString(const aName: string; const aValue: string);
begin
  if Assigned(fManager.Settings) then
    fManager.Settings.WriteString(StorageSection, aName, aValue);
end;

function TProcBase.StorageGetBool(const aName: string; aDefaultValue: Boolean): Boolean;
begin
  Result := aDefaultValue;
  if Assigned(fManager.Settings) then
    Result := fManager.Settings.ReadBool(StorageSection, aName, aDefaultValue);
end;

function TProcBase.StorageGetInteger(const aName: string; aDefaultValue: Integer): Integer;
begin
  Result := aDefaultValue;
  if Assigned(fManager.Settings) then
    Result := fManager.Settings.ReadInteger(StorageSection, aName, aDefaultValue);
end;

function TProcBase.StorageGetString(const aName: string; const aDefaultValue: string): string;
begin
  Result := aDefaultValue;
  if Assigned(fManager.Settings) then
    Result := fManager.Settings.ReadString(StorageSection, aName, aDefaultValue);
end;

procedure TProcBase.OnShow;
begin

end;

procedure TProcBase.OnHide;
begin

end;

procedure TProcBase.OnStart;
begin

end;

procedure TProcBase.OnStop;
begin

end;

end.
