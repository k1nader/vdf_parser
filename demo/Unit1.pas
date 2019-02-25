unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, uVDFParser;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    FVDFParser: TVDFParser;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  FVDFParser := TVDFParser.Create;
  FVDFParser.LoadFormFile('H:\Steam\config\loginusers.vdf');
  Memo1.Lines.Text := FVDFParser.Json;
end;

end.

