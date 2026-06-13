unit MSHeap;

{
  Default MM override using Windows Heap API
  Roberto Della Pasqua www.dellapasqua.com
  10 sept 2022 added inline directive, zeromemory and freemem return value

  Manifest clause to use the new ("better") segment heap since Windows 10, version 2004 (build 19041):
  https://docs.microsoft.com/en-us/windows/win32/sbscs/application-manifests#heaptype

  <asmv3:application>
    <asmv3:windowsSettings xmlns="http://schemas.microsoft.com/SMI/2020/WindowsSettings">
      <heapType>SegmentHeap</heapType>
    </asmv3:windowsSettings>
  </asmv3:application>
}

{$LongStrings off}
{$Optimization on}
{$Overflowchecks off}
{$Rangechecks off}

interface

implementation

uses
  WinApi.Windows;

var
  ProcessHeap: THandle = 0;

function SysGetMem(Size: NativeInt): Pointer; inline;
begin
  Result := HeapAlloc(ProcessHeap, 0, Size);
end;

function SysFreeMem(P: Pointer): Integer; inline;
begin
  HeapFree(ProcessHeap, 0, P); //returns 0 if fail, but this can stop the execution
  Result := 0; //for Delphi management should be reversed to zero, else throws a runtime exception
end;

function SysReallocMem(P: Pointer; Size: NativeInt): Pointer; inline;
begin
  Result := HeapReAlloc(ProcessHeap, 0, P, Size);
end;

function SysAllocMem(Size: NativeInt): Pointer; inline;
begin
  Result := HeapAlloc(ProcessHeap, HEAP_ZERO_MEMORY, Size);
end;

function SysRegisterExpectedMemoryLeak(P: Pointer): Boolean;
begin
  Result := False;
end;

function SysUnregisterExpectedMemoryLeak(P: Pointer): Boolean;
begin
  Result := False;
end;

function OSVersionMajor: Cardinal;
const
  STATUS_SUCCESS = $00000000;
type
  TFuncRtlGetVersion = function(var RTL_OSVERSIONINFOEXW): DWORD; stdcall;
var
  RtlGetVersion: TFuncRtlGetVersion;
  VerInfo: TOSVersionInfoExW;
begin
  Result := 0;
  @RtlGetVersion := GetProcAddress(GetModuleHandle('ntdll.dll'), 'RtlGetVersion');
  if Assigned(RtlGetVersion) then begin
    ZeroMemory(@VerInfo, SizeOf(VerInfo));
    VerInfo.dwOSVersionInfoSize := SizeOf(VerInfo);
    if RtlGetVersion(VerInfo) = STATUS_SUCCESS then
      Result := VerInfo.dwMajorVersion;
  end;
end;

function NoMemoryAllocated: Boolean;
var
  State: TMemoryManagerState;
begin
  {$WARN SYMBOL_PLATFORM OFF}
  GetMemoryManagerState(State);
  {$WARN SYMBOL_PLATFORM ON}
  Result := (State.AllocatedMediumBlockCount = 0) and (State.AllocatedLargeBlockCount = 0);
end;

{$if not declared(SetDllDirectory)}
//WinBase.h:
function SetDllDirectory(lpPathName: PChar): BOOL; stdcall;
  external Windows.kernel32 name {$ifdef UNICODE}'SetDllDirectoryW'{$else}'SetDllDirectoryA'{$endif};
{$ifend}

const
  MemoryManager: TMemoryManagerEx = (
    GetMem: SysGetmem;
    FreeMem: SysFreeMem;
    ReallocMem: SysReAllocMem;
    AllocMem: SysAllocMem;
    RegisterExpectedMemoryLeak: SysRegisterExpectedMemoryLeak;
    UnregisterExpectedMemoryLeak: SysUnregisterExpectedMemoryLeak
  );


initialization

  // For a little additional security and performance, remove the current working directory of the process from the
  // search path for DLLs (effective for DLLs that are loaded after this point only).
  // Argument values:
  // - Pathname: Replaces the CWD in the Search Path with <Pathname>
  // - Empty string: Removes the CWD from the Search Path
  // - NULL: Restores the default search order

  //SetDllDirectory('');

  //{$IFNDEF DEBUG}
  if OSVersionMajor >= 10 then
  {$WARN SYMBOL_PLATFORM OFF}
  if DebugHook = 0 then begin
  {$WARN SYMBOL_PLATFORM ON}
    Assert(NoMemoryAllocated, 'Can not initialize MSHeap, memory is already allocated');
    ProcessHeap := GetProcessHeap;
    Assert(ProcessHeap <> 0);
    SetMemoryManager(MemoryManager);
  end;
  //{$ENDIF}

end.
