{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

program BSArchPro;

{$I baDefines.inc}

{$IFDEF EXCEPTION_LOGGING_ENABLED}
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG ON
// JCL_DEBUG_EXPERT_DELETEMAPFILE ON
{$ENDIF}

uses
  MSHeap,
  {$IFDEF EXCEPTION_LOGGING_ENABLED}
  nxExceptionHook,
  {$ENDIF }
  System.IOUtils,
  System.SysUtils,

  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Themes,

  wbBSArchive in 'Core\wbBSArchive.pas',
  wbCompression in 'Core\wbCompression.pas',
  wbDDS in 'Core\wbDDS.pas',
  wbHash in 'Core\wbHash.pas',
  wbStreams in 'Core\wbStreams.pas',
  wbTaskProgress in 'Core\wbTaskProgress.pas' {FormTaskProgress},

  frmArchiveInfo in 'BSArch\frmArchiveInfo.pas' {FormArchiveInfo},
  frmMain in 'BSArch\frmMain.pas' {FormMain},
  frmPack in 'BSArch\frmPack.pas' {FormPack},
  frmSearchReplace in 'BSArch\frmSearchReplace.pas' {FormSearchReplace};

{$R *.res}

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;

{$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}

procedure bapInitStyles;
begin
  var Path := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'Themes';
  if TDirectory.Exists(Path) then
    for var s in TDirectory.GetFiles(Path, '*.vsf' ) do try
      TStyleManager.LoadFromFile(s);
    except
      on E: Exception do
        ShowMessage(Format('Error loading theme file "%s": %s', [s, E.Message]));
    end;
end;

begin
  {$IFDEF EXCEPTION_LOGGING_ENABLED}
  nxEHAppVersion := 'BSArchPro v' + csBSAVersion;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowHint := True;
  Application.HintPause := 200;
  Application.HintHidePause := 10000;
  Application.Title := 'BSArchPro';
  bapInitStyles;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
