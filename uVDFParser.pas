unit uVDFParser;

interface

uses
  Windows, SysUtils, Classes;

type
  // VDF 树节点：可以是键值对（Name + Value），也可以包含子节点（Children）
  TVDFNode = class
  private
    FName: string;
    FValue: string;
    FChildren: TList; // 存放 TVDFNode 的指针
  public
    constructor Create(const AName: string = ''; const AValue: string = '');
    destructor Destroy; override;

    property Name: string read FName write FName;
    property Value: string read FValue write FValue;
    property Children: TList read FChildren;

    function FindFirstChild(const AName: string): TVDFNode;
    function ToIndentedString(const Indent: string = ''): string; // 调试用
  end;

  TVDFParser = class(TObject)
  private
    FSourceText: string;
    FRoot: TVDFNode;
    procedure RemoveComments(const AIn: string; out AOut: string);
    function ReadQuoted(var S: string; var Pos: Integer): string;
    procedure SkipWhiteSpace(const S: string; var Pos: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const FileName: string; AEncoding: TEncoding = nil);
    procedure LoadFromStream(Stream: TStream; AEncoding: TEncoding = nil);
    procedure Parse(const AString: string);

    property Text: string read FSourceText;
    property Root: TVDFNode read FRoot;
  end;

implementation

{ TVDFNode }

constructor TVDFNode.Create(const AName: string = '';
  const AValue: string = '');
begin
  inherited Create;
  FName := AName;
  FValue := AValue;
  FChildren := TList.Create;
end;

destructor TVDFNode.Destroy;
var
  I: Integer;
begin
  // 释放子节点
  if Assigned(FChildren) then
  begin
    for I := 0 to FChildren.Count - 1 do
      TObject(FChildren[I]).Free;
    FChildren.Free;
  end;
  inherited;
end;

function TVDFNode.FindFirstChild(const AName: string): TVDFNode;
var
  I: Integer;
  N: TVDFNode;
begin
  Result := nil;
  if not Assigned(FChildren) then
    Exit;
  for I := 0 to FChildren.Count - 1 do
  begin
    N := TVDFNode(FChildren[I]);
    if N.Name = AName then
    begin
      Result := N;
      Exit;
    end;
  end;
end;

function TVDFNode.ToIndentedString(const Indent: string): string;
var
  I: Integer;
  N: TVDFNode;
  L: string;
begin
  L := '';
  if FChildren.Count = 0 then
    L := Indent + '"' + FName + '" "' + FValue + '"' + sLineBreak
  else
  begin
    L := Indent + '"' + FName + '"' + sLineBreak;
    L := L + Indent + '{' + sLineBreak;
    for I := 0 to FChildren.Count - 1 do
    begin
      N := TVDFNode(FChildren[I]);
      L := L + N.ToIndentedString(Indent + '  ');
    end;
    L := L + Indent + '}' + sLineBreak;
  end;
  Result := L;
end;

{ TVDFParser }

constructor TVDFParser.Create;
begin
  inherited Create;
  FSourceText := '';
  FRoot := TVDFNode.Create('root');
end;

destructor TVDFParser.Destroy;
begin
  FRoot.Free;
  inherited;
end;

procedure TVDFParser.LoadFromFile(const FileName: string; AEncoding: TEncoding);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName, AEncoding);
    Parse(SL.Text);
  finally
    SL.Free;
  end;
end;

procedure TVDFParser.LoadFromStream(Stream: TStream; AEncoding: TEncoding);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromStream(Stream, AEncoding);
    Parse(SL.Text);
  finally
    SL.Free;
  end;
end;

// 删除 // 注释（只在 引号外 才视为注释起始）
// 保留原始行结束符，避免将多行合成一行
procedure TVDFParser.RemoveComments(const AIn: string; out AOut: string);
var
  I, Len: Integer;
  InQuotes: Boolean;
  OutBuf: TStringBuilder;
begin
  OutBuf := TStringBuilder.Create;
  try
    Len := Length(AIn);
    I := 1;
    InQuotes := False;
    while I <= Len do
    begin
      if AIn[I] = '"' then
      begin
        // 识别引号切换（不考虑转义的处理，这里在读取字符串时会做更完善的处理）
        InQuotes := not InQuotes;
        OutBuf.Append(AIn[I]);
        Inc(I);
      end
      else if (not InQuotes) and (AIn[I] = '/') and (I < Len) and
        (AIn[I + 1] = '/') then
      begin
        // 跳过直到行尾（保留行结束符）
        Inc(I, 2);

        while (I <= Len) and not CharInSet(AIn[I], [#10, #13]) do
          Inc(I);
        // 继续主循环，让循环把行结束符也复制
      end
      else
      begin
        OutBuf.Append(AIn[I]);
        Inc(I);
      end;
    end;
    AOut := OutBuf.ToString;
  finally
    OutBuf.Free;
  end;
end;

procedure TVDFParser.SkipWhiteSpace(const S: string; var Pos: Integer);
begin
  while (Pos <= Length(S)) and CharInSet(S[Pos], [#9, #10, #13, ' ', #$A0]) do
    Inc(Pos);
end;

// 从当前 Pos（指向第一个 "）读取带转义处理的字符串并返回（Pos 最终停在结束引号之后）
// 如果遇到文件结束则返回空字符串
function TVDFParser.ReadQuoted(var S: string; var Pos: Integer): string;
var
  Len: Integer;
  I: Integer;
  Ch: Char;
  Buf: TStringBuilder;
  Escaped: Boolean;
begin
  Result := '';
  Len := Length(S);
  if (Pos > Len) or (S[Pos] <> '"') then
    Exit;

  Inc(Pos); // 跳过起始引号
  Buf := TStringBuilder.Create;
  try
    Escaped := False;
    I := Pos;
    while I <= Len do
    begin
      Ch := S[I];
      if Escaped then
      begin
        // 支持常见的简单转义：\" \\ \n \t
        case Ch of
          '"':
            Buf.Append('"');
          '\':
            Buf.Append('\');
          'n':
            Buf.Append(#10);
          'r':
            Buf.Append(#13);
          't':
            Buf.Append(#9);
        else
          Buf.Append(Ch);
        end;
        Escaped := False;
      end
      else
      begin
        if Ch = '\' then
          Escaped := True
        else if Ch = '"' then
        begin
          // 结束引号，Pos 指向结束引号之后
          Pos := I + 1;
          Result := Buf.ToString;
          Exit;
        end
        else
          Buf.Append(Ch);
      end;
      Inc(I);
    end;
    // 如果跑到这里表示没有找到匹配的结束引号，返回缓冲内容
    Result := Buf.ToString;
    Pos := Len + 1;
  finally
    Buf.Free;
  end;
end;

procedure TVDFParser.Parse(const AString: string);
var
  Clean: string;
  Pos, Len: Integer;
  Key, Value: string;
  ParentStack: TList; // 存放当前父节点的 TVDFNode 指针
  CurrentParent: TVDFNode;
  NewNode: TVDFNode;
begin
  // 清理上次结果
  if Assigned(FRoot) then
  begin
    FRoot.Free;
    FRoot := TVDFNode.Create('root');
  end;

  // 去注释
  RemoveComments(AString, Clean);
  FSourceText := Clean;

  Pos := 1;
  Len := Length(Clean);

  ParentStack := TList.Create;
  try
    ParentStack.Add(FRoot); // 根为第一个父节点
    CurrentParent := TVDFNode(ParentStack[ParentStack.Count - 1]);

    while Pos <= Len do
    begin
      SkipWhiteSpace(Clean, Pos);
      if Pos > Len then
        Break;

      if Clean[Pos] = '"' then
      begin
        // 读取 key
        Key := ReadQuoted(Clean, Pos);
        SkipWhiteSpace(Clean, Pos);
        if Pos > Len then
          Break;

        // 情况 A: 后面直接是 { -> 这是一个对象（key 为对象名）
        if Clean[Pos] = '{' then
        begin
          // 创建节点（对象），加入当前父节点，然后进栈
          NewNode := TVDFNode.Create(Key, '');
          CurrentParent.Children.Add(NewNode);
          ParentStack.Add(NewNode);
          CurrentParent := NewNode;
          Inc(Pos); // 跳过 '{'
        end
        // 情况 B: 后面是另一个 quoted string -> key/value 对
        else if Clean[Pos] = '"' then
        begin
          Value := ReadQuoted(Clean, Pos);
          NewNode := TVDFNode.Create(Key, Value);
          CurrentParent.Children.Add(NewNode);
        end
        else
        begin
          // 既不是 { 也不是 " ，可能是格式不标准或有换行/空白，尝试跳过空白并再次检测
          SkipWhiteSpace(Clean, Pos);
          if (Pos <= Len) and (Clean[Pos] = '{') then
          begin
            NewNode := TVDFNode.Create(Key, '');
            CurrentParent.Children.Add(NewNode);
            ParentStack.Add(NewNode);
            CurrentParent := NewNode;
            Inc(Pos);
          end
          else if (Pos <= Len) and (Clean[Pos] = '"') then
          begin
            Value := ReadQuoted(Clean, Pos);
            NewNode := TVDFNode.Create(Key, Value);
            CurrentParent.Children.Add(NewNode);
          end
          else
          begin
            // 无法识别，跳过这个 key
            // 向前移动一个字符避免死循环
            Inc(Pos);
          end;
        end;
      end
      else if Clean[Pos] = '{' then
      begin
        // 有些 VDF 在 { 前可能没有给出 key（不常见），创建匿名节点
        NewNode := TVDFNode.Create('', '');
        CurrentParent.Children.Add(NewNode);
        ParentStack.Add(NewNode);
        CurrentParent := NewNode;
        Inc(Pos);
      end
      else if Clean[Pos] = '}' then
      begin
        // 结束当前对象
        if ParentStack.Count > 1 then
          ParentStack.Delete(ParentStack.Count - 1);
        if ParentStack.Count > 0 then
          CurrentParent := TVDFNode(ParentStack[ParentStack.Count - 1])
        else
          CurrentParent := nil;
        Inc(Pos);
      end
      else
      begin
        // 跳过未知字符
        Inc(Pos);
      end;
    end;
  finally
    ParentStack.Free;
  end;
end;

end.
