unit ProcHavokInfo;

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
  TFrameHavokInfo = class(TFrame)
    StaticText1: TStaticText;
    chkPerObject: TCheckBox;
    lvFields: TListView;
    chkSameLine: TCheckBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TProcHavokInfo = class(TProcBase)
  private
    Frame: TFrameHavokInfo;
    fPerObject: Boolean;
    fSameLine: Boolean;
    fFields: array of string;
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
  wbDataFormat,
  wbDataFormatNif;

constructor TProcHavokInfo.Create(aManager: TProcManager);
begin
  inherited;

  fTitle := 'Havok information';
  fSupportedGames := [gtTES4, gtFO3, gtFNV, gtTES5, gtSSE];
  fExtensions := ['nif'];
  fNoOutput := True;
end;

function TProcHavokInfo.GetFrame(aOwner: TComponent): TFrame;
begin
  Frame := TFrameHavokInfo.Create(aOwner);
  Result := Frame;
end;

procedure TProcHavokInfo.OnShow;
const
  Fields: TArray<String> = [
    'Inertia Tensor',
    'Linear Damping',
    'Angular Damping',
    'Time Factor',
    'Gravity Factor',
    'Friction',
    'Rolling Friction Multiplier',
    'Restitution',
    'Max Linear Velocity',
    'Max Angular Velocity',
    'Penetration Depth',
    'Motion System',
    'Deactivator Type',
    'Enable Deactivation',
    'Solver Deactivation',
    'Motion Quality'
  ];
var
  checkedfields: TStringList;
begin
  Frame.chkPerObject.Checked := StorageGetBool('bPerObject', Frame.chkPerObject.Checked);
  Frame.chkSameLine.Checked := StorageGetBool('bSameLine', Frame.chkSameLine.Checked);

  checkedfields := TStringList.Create;
  checkedfields.CommaText := StorageGetString('sFields', '');
  try
    for var f in Fields do
      with Frame.lvFields.Items.Add do begin
        Caption := f;
        Checked := checkedfields.IndexOf(f) <> -1;
      end;
  finally
    checkedfields.Free;
  end;
end;

procedure TProcHavokInfo.OnHide;
begin
  StorageSetBool('bPerObject', Frame.chkPerObject.Checked);
  StorageSetBool('bSameLine', Frame.chkSameLine.Checked);
  with TStringList.Create do try
    for var i := 0 to Pred(Frame.lvFields.Items.Count) do
      if Frame.lvFields.Items[i].Checked then
        Add(Frame.lvFields.Items[i].Caption);
    StorageSetString('sFields', CommaText);
  finally
    Free;
  end;
end;

procedure TProcHavokInfo.OnStart;
begin
  fPerObject := Frame.chkPerObject.Checked;
  fSameLine := Frame.chkSameLine.Checked;
  SetLength(fFields, 0);
  for var i := 0 to Pred(Frame.lvFields.Items.Count) do
    if Frame.lvFields.Items[i].Checked then
      fFields := fFields + [Frame.lvFields.Items[i].Caption];
end;

function TProcHavokInfo.ProcessFile(aFile: TProcFileObject): TBytes;
var
  nif: TwbNifFile;
  Log: TStringList;
  statics, dynamics: Integer;
  mass: Single;
begin
  nif := TwbNifFile.Create;
  Log := TStringList.Create;
  try
    nif.LoadFromData(aFile.GetData);

    statics := 0; dynamics := 0; mass := 0;
    for var col in nif.BlocksByType('bhkCollisionObject', True) do begin
      var rigid := TwbNifBlock(col.Elements['Body'].LinksTo);
      if not Assigned(rigid) then
        Continue;

      var target := TwbNifBlock(col.Elements['Target'].LinksTo);
      var name := '<No target>';
      if Assigned(target) then begin
        name := target.EditValues['Name'];
        if name = '' then
          name := target.Name;
      end else
        name := '<No target>';

      var shape := TwbNifBlock(rigid.Elements['Shape'].LinksTo);
      if Assigned(shape) and (shape.BlockType = 'bhkTransformShape') then
        shape := TwbNifBlock(shape.Elements['Shape'].LinksTo);
      var shapetype := '<No shape>';
      if Assigned(shape) then
        shapetype := shape.BlockType;

      if fPerObject then begin
        var line := Format(#9'%s      %s    %s    %s', [name,
          rigid.EditValues['Mass'],
          rigid.EditValues['Havok Filter\Layer'],
          shapetype
        ]);

        for var f in fFields do begin
          var el := rigid.Elements[f];
          if not Assigned(el) then
            Continue;

          var fvalue := '';
          if f = 'Inertia Tensor' then
            fvalue := Format('"%s %s %s"', [el.EditValues['m11'], el.EditValues['m22'], el.EditValues['m33']])
          else
            fvalue := el.EditValue;

          if fSameLine then
            line := line + '    ' + fvalue
          else
            line := line + #13#10#9#9 + f + ':'#9 + fvalue;
        end;

        Log.Add(line);
      end;

      if rigid.IsDynamicRigidBody then
        Inc(dynamics)
      else
        Inc(statics);

      mass := mass + rigid.NativeValues['Mass'];
    end;

    Log.Sort;
    if statics + dynamics > 0 then
      Log.Add(Format(#9'Static: %d    Dynamic: %d    Total Mass: %s', [statics, dynamics, dfFloatToStr(mass)]));

    if Log.Count > 0 then begin
      Log.Insert(0, aFile.FileName);
      Log.Add('');
      fManager.AddMessages(Log);
    end;

  finally
    nif.Free;
    Log.Free;
  end;

end;


end.
