unit uVDFParser;

interface

uses
  SysUtils, Classes;

type
  TVDFNode = class(TList)
  end;

  TVDFParser = class(TObject)
  private
    FText: string;
  public
    constructor Create;
    procedure LoadFormFile(FileName: string);
    procedure LoadFormStream(Stream: TMemoryStream);
    procedure Parser(AString: string);
  end;

implementation

constructor TVDFParser.Create;
begin
  inherited Create;
  FText := '';
end;

procedure TVDFParser.LoadFormFile(FileName: string);
var
  StringList: TStringList;
begin
  StringList := TStringList.Create;
  try
    StringList.LoadFromFile(FileName);
    Parser(StringList.Text);
  finally
    StringList.Free;
  end;
end;

procedure TVDFParser.LoadFormStream(Stream: TMemoryStream);
var
  StringList: TStringList;
begin
  StringList := TStringList.Create;
  try
    StringList.LoadFromStream(Stream);
    Parser(StringList.Text);
  finally
    StringList.Free;
  end;
end;

procedure TVDFParser.Parser(AString: string);
begin
  FText := AString;
end;

end.

