unit uVDFParser;

interface

uses
  Windows, SysUtils, Classes, superobject;

type
  TVDFParser = class(TObject)
  private
    FSourceText: string;
    FJsonText: string;
    procedure Check(AString: string);
  public
    constructor Create;
    procedure LoadFormFile(FileName: string);
    procedure LoadFormStream(Stream: TMemoryStream);
    procedure Parser(AString: string);
    property Text: string read FSourceText;
    property Json: string read FJsonText;
  end;

implementation

constructor TVDFParser.Create;
begin
  inherited Create;
  FSourceText := '';
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

procedure TVDFParser.Check(AString: string);
var
  StringList: TStringList;
  ParserString: string;
  I: Integer;
begin

  StringList := TStringList.Create;
  StringList.Text := AString;

  for I := 0 to StringList.Count - 1 do
  begin
    ParserString := Trim(StringList.Strings[I]);

    if Length(ParserString) >= 2 then
    begin
      if (ParserString[1] = '/') and (ParserString[2] = '/') then
      begin
        StringList.Strings[I] := '';
      end;
    end;
  end;

  FSourceText := StringList.Text;
end;

procedure TVDFParser.Parser(AString: string);
var
  I, Len, QuotaCount, MarkStart, MarkEnd, KeyCount: Integer;
  AChar, AKey, AValue, AReKey: string;
  AParentJson, ARootJson, AValueJson: ISuperObject;
begin

  AParentJson := nil;
  ARootJson := nil;
  AValueJson := nil;

  Check(AString);

  Len := Length(FSourceText);
  AKey := '';
  AValue := '';

  MarkStart := 0;
  QuotaCount := 0;

  for I := 1 to Len do
  begin
    AChar := FSourceText[I];

    if AChar = '"' then
    begin
      Inc(QuotaCount);

      if QuotaCount = 1 then
      begin
        MarkStart := I;
      end;

      if QuotaCount = 2 then
      begin
        MarkEnd := I;
        AKey := Copy(FSourceText, MarkStart + 1, MarkEnd - MarkStart - 1);
      end;

      if QuotaCount = 3 then
      begin
        MarkStart := I;
      end;

      if QuotaCount = 4 then
      begin
        MarkEnd := I;

        AValue := Copy(FSourceText, MarkStart + 1, MarkEnd - MarkStart - 1);

        if AValueJson.O[AKey] = nil then
        begin
          AValueJson.S[AKey] := AValue;
        end
        else
        begin

          KeyCount := 1;

          AReKey := AKey;
  
          while AValueJson.O[AReKey] <> nil do
          begin
            AReKey := AKey + '_fix_' + IntToStr(KeyCount);
            Inc(KeyCount);
          end;

          AValueJson.S[AReKey] := AValue;

        end;

        QuotaCount := 0;
      end;

    end
    else if AChar = '{' then
    begin

      QuotaCount := 0;

      if ARootJson = nil then
      begin

        ARootJson := SO('{}');
        ARootJson.O[AKey] := SO('{}');
        AValueJson := ARootJson.O[AKey];
        AParentJson := ARootJson;

      end
      else
      begin

        AParentJson := AValueJson;
        AValueJson.O[AKey] := SO('{}');
        AValueJson := AValueJson.O[AKey];

      end;

    end
    else if AChar = '}' then
    begin
      AValueJson := AParentJson;
      QuotaCount := 0;
    end;

  end;

  FJsonText := ARootJson.AsJSon(True, True);

end;

end.

