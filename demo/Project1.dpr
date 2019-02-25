program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  uVDFParser in '..\uVDFParser.pas',
  superobject in '..\..\PT_Client_6.0_Source\librarys\superobject\superobject.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
