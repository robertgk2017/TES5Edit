{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit frmVertexPaintHelper;

interface

uses
  System.Classes,

  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Imaging.pngimage;

type
  TFormVertexPaintHelper = class(TForm)
    Image1: TImage;
    procedure Image1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormVertexPaintHelper: TFormVertexPaintHelper;

implementation

{$R *.dfm}

uses
  Winapi.Windows;

procedure TFormVertexPaintHelper.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

procedure TFormVertexPaintHelper.Image1Click(Sender: TObject);
begin
  Close;
end;

end.
