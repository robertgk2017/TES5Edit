{******************************************************************************

  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

unit frMessages;

interface

uses
  System.Classes,

  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Imaging.jpeg,
  Vcl.StdCtrls;

type
  TFrameMessages = class(TFrame)
    memoMessages: TMemo;
    imgTrash: TImage;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

end.
