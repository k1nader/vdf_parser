program Project1;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  uVDFParser in '..\uVDFParser.pas';

procedure PrintNode(Node: TVDFNode; const Indent: string);
var
  i: Integer;
  Child: TVDFNode;
  HasChildren: Boolean;
begin
  if Node = nil then
    Exit;

  HasChildren := Node.Children.Count > 0;

  // 只打印有名字的节点（匿名节点会被跳过显示）
  if Node.Name <> '' then
  begin
    if HasChildren then
      Writeln(Indent, Node.Name, ':')
    else
      Writeln(Indent, Node.Name, ' = ', Node.Value);
  end;

  for i := 0 to Node.Children.Count - 1 do
  begin
    Child := TVDFNode(Node.Children[i]);
    PrintNode(Child, Indent + '  ');
  end;
end;

var
  Parser: TVDFParser;
  i: Integer;
  fname: string;

begin
  try
    Parser := TVDFParser.Create;
    try
      fname := 'F:\shared\gamedata\config.txt';
      Parser.LoadFromFile(fname, TEncoding.UTF8);

      for i := 0 to Parser.Root.Children.Count - 1 do
        PrintNode(TVDFNode(Parser.Root.Children[i]), '');

    finally
      Parser.Free;
    end;

    Readln;
  except
    on E: Exception do
      Writeln('Error: ', E.ClassName, ': ', E.Message);
  end;

end.
