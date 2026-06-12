unit HeartWare.MultiCheckListBox;

{
  THWMultiCheckListBox
  --------------------

  Authored by ChatGPT (not Codex) in June 2026.
  Updated/Adapted by HeartWare
  (C) 2026 HeartWare

  License: Free for private and non-commercial use only.

  This source code may be used, modified, and redistributed in private or
  non-commercial projects, provided that this license notice remains intact.

  Commercial use is not permitted.

  For the purposes of this license, commercial use includes, but is not
  limited to, selling the software, including it in paid products, using it
  in paid client work, using it in donation-supported products, accepting
  donations or sponsorships connected to the software, or receiving any other
  monetary compensation related to the use or distribution of this code.

  For commercial licensing, contact the author.

  This is a custom-drawn VCL TCheckListBox-style control that behaves like a
  logical TCheckListBox, but with two important extensions:

    1) Each item may have zero, one, or several checkboxes
       (same count for all Items).
    2) Individual items may be hidden without removing them from Items.

  The control is not descended from TListBox or TCheckListBox. It is drawn
  manually, and mouse/keyboard handling is implemented by the control itself.
  This allows the visual list to differ from the logical Items collection.

  Logical item indexes
  --------------------

  Items, Count, ItemIndex, Checked[], VisibleItem[] and Selected[] all use the
  original logical item index.

  If Items contains:

      0: 'Alpha'
      1: 'Beta'
      2: 'Gamma'
      3: 'Delta'

  and item 2 is hidden:

      VisibleItem[2] := False;

  then only Alpha, Beta and Delta are drawn, but the logical indexes remain
  0, 1, 2 and 3. Selecting the bottom visible row therefore returns:

      ItemIndex = 3

  not 2.

  VisibleItem[Index]
  ------------------

  Controls whether a logical item is currently displayed.

      VisibleItem[Index] := False;

  hides the item visually, but does not delete it from Items and does not
  change the logical indexes of any other item.

  Setting ItemIndex to a hidden item automatically makes that item visible
  again, then selects it and redraws the control.

  CheckBoxCount
  -------------

  Defines how many checkboxes each item has.

      CheckBoxCount := 0;  // no checkboxes, TlistBox-style display only
      CheckBoxCount := 1;  // ordinary TCheckListBox look
      CheckBoxCount := 3;  // three independent checkboxes per item

  Checkbox indexes are zero-based.

  Checked[Index, CheckBoxNo]
  --------------------------

  Gets or sets the checked state of one checkbox for one logical item.

      Checked[5, 0] := True;
      Checked[5, 1] := False;

  The first index is the logical item index.
  The second index is the checkbox number, from 0 to CheckBoxCount - 1.

  When the checked state actually changes, OnCheckBoxClicked is fired. This
  happens both for user interaction and for programmatic changes through the
  Checked[] property.

  ItemIndex and OnClick
  ---------------------

  ItemIndex is the logical selected item index, not the visible row number.

  OnClick is treated as an "ItemIndex changed" event. It fires when ItemIndex
  changes, including keyboard navigation. Merely clicking the already-selected
  item does not count as an ItemIndex change.

  OnCheckBoxClicked
  -----------------

  Fires whenever a checkbox changes state.

      OnCheckBoxClicked(Sender, ItemIndex, CheckBoxIndex, State)

  ItemIndex is the logical item index.
  CheckBoxIndex is the zero-based checkbox number.
  State is the new checked state (Boolean).

  This event is fired for mouse clicks, keyboard toggles, and manual assignment
  to Checked[Index, CheckBoxNo], but only if the state actually changes.

  BeginUpdate / EndUpdate
  -----------------------

  Use BeginUpdate / EndUpdate when changing many item states, especially
  VisibleItem[], to suppress repeated redraws and scrollbar recalculations.

      BeginUpdate;
      try
        for I := 0 to Count - 1 do
          VisibleItem[I] := ShouldShowItem(I);
      finally
        EndUpdate;
      end;

  The control refreshes itself when the final matching EndUpdate is called.

  Notes
  -----

  Because this is a custom-drawn control rather than a native listbox, only
  the TCheckListBox-like behavior explicitly implemented by the component is
  available. The Items collection and logical selection model are compatible
  with normal listbox usage, but native listbox-specific Windows behavior,
  styles, and messages should not be assumed.
}

interface

uses
  System.Classes,
  System.SysUtils,
  System.Math,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms;

type
  THWMultiCheckListBox = class;

  THWCheckBoxClickedEvent = procedure(Sender: TObject; ItemIndex, CheckBoxIndex: Integer; State: Boolean) of object;

  THWMultiCheckListBoxStrings = class(TStringList)
  private
    FOwner: THWMultiCheckListBox;
  protected
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject); override;
  public
    constructor Create(AOwner: THWMultiCheckListBox);
    procedure Delete(Index: Integer); override;
    procedure Clear; override;
  end;

  THWMultiCheckListBox = class(TCustomControl)
  private
    FItems: TStrings;
    FVisibleItems: array of Boolean;
    FChecked: array of array of Boolean;

    FCheckBoxCount: Integer;
    FItemIndex: Integer;
    FTopVisibleRow: Integer;
    FItemHeight: Integer;
    FBorderStyle: TBorderStyle;
    FUpdateCount: Integer;

    FOnClickCheck: TNotifyEvent;
    FOnCheckBoxClicked: THWCheckBoxClickedEvent;

    function GetCount: Integer;
    function GetChecked(Index, CheckBoxNo: Integer): Boolean;
    procedure SetChecked(Index, CheckBoxNo: Integer; const Value: Boolean);
    function ChangeChecked(Index, CheckBoxNo: Integer; const Value,FireEvent: Boolean): Boolean;
    procedure DoCheckBoxClicked(Index, CheckBoxNo: Integer; State: Boolean);
    function GetVisibleItem(Index: Integer): Boolean;
    procedure SetVisibleItem(Index: Integer; const Value: Boolean);
    function GetSelected(Index: Integer): Boolean;
    procedure SetSelected(Index: Integer; const Value: Boolean);

    procedure SetItems(const Value: TStrings);
    procedure ItemsChanged(Sender: TObject);

    procedure SetCheckBoxCount(const Value: Integer);
    procedure SetItemIndex_(const Value: Integer);
    procedure SetItemHeight(const Value: Integer);
    procedure SetBorderStyle(const Value: TBorderStyle);

    procedure CheckItemIndex(Index: Integer);
    procedure CheckCheckBoxNo(CheckBoxNo: Integer);

    procedure InsertState(Index: Integer);
    procedure DeleteState(Index: Integer);
    procedure ClearStates;
    procedure EnsureStateArrays;

    function EffectiveItemHeight: Integer;
    function CheckBoxSize: Integer;
    function FirstVisibleIndex: Integer;
    function LastVisibleIndex: Integer;
    function NextVisibleIndex(FromIndex, Delta: Integer): Integer;
    function VisibleOrdinalOfIndex(Index: Integer): Integer;
    function IndexOfVisibleOrdinal(Ordinal: Integer): Integer;
    function GetVisibleCount: Integer;
    function VisibleRowsOnScreen: Integer;

    procedure SetTopVisibleRow(Value: Integer);
    procedure MakeItemVisible(Index: Integer);
    procedure UpdateScrollBar;
    procedure RequestUpdate;
    procedure InvalidateItem(Index: Integer);

    procedure DrawItem(Index, Y: Integer);
    function CheckBoxNoAtX(X: Integer): Integer;
    function Updating: Boolean; inline;

    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    function GetItem(Index: Integer): String;

    function GetInt(Index: Integer): NativeInt;
    procedure SetInt(Index: Integer; Value: NativeInt);

    function GetObj(Index: Integer): TObject;
    procedure SetObj(Index: Integer; Value: TObject);

    procedure SetCheckAll(CheckBoxNo: Integer; Checked,FireEvent: Boolean);

  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoClickCheck; virtual;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

  public
    const       LOW = Integer(0);
    function    HIGH : Integer; inline;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure BeginUpdate;
    procedure EndUpdate;

    function ItemAtPos(P: TPoint; Existing: Boolean): Integer; overload;
    function ItemAtPos(X, Y: Integer; Existing: Boolean): Integer; overload;
    function CheckBoxAtPos(P: TPoint; out Index, CheckBoxNo: Integer): Boolean;

    function ValidIndex(Index: Integer): Boolean; overload;
    function ValidIndex: Boolean; overload; inline;
    procedure Clear(FreeObjects: Boolean = false);
    function VisibleItems: TArray<Integer>;
    function Add(const S: String; O: TObject = nil): Integer; overload; inline;
    function Add(const S: String; I: NativeInt): Integer; overload; inline;
    function Add(const S: String; I: NativeInt; Checked: Boolean): Integer; overload; inline;
    function Insert(Index: Integer; const S: String; O: TObject = nil): Integer; overload; inline;
    function Insert(Index: Integer; const S: String; I: NativeInt): Integer; overload; inline;
    function Insert(Index: Integer; const S: String; I: NativeInt; Checked: Boolean): Integer; overload; inline;
    function IndexOf(const S: String): Integer; overload; inline;
    function IndexOf(O: TObject): Integer; overload; inline;
    function IndexOf(I: NativeInt): Integer; overload; inline;

    procedure SetItemIndex(Index: Integer; FireEvent: Boolean = True); overload;
    procedure SetItemIndex(const S:String; FireEvent: Boolean = True); overload; inline;
    procedure SetItemIndex(O: TObject; FireEvent: Boolean = True); overload; inline;
    procedure SetItem(Index: Integer; const S: String ; O: TObject); inline;

    function SetCheck(Index,CheckBoxNo: Integer; State,FireEvent: Boolean): Integer; OVERLOAD;
    function SetCheck(O: TObject; CheckBoxNo: Integer; State: BOOLEAN; FireEvent: BOOLEAN = true) : Integer; OVERLOAD;
    function SetCheckInt(I: NativeInt; CheckBoxNo: Integer; State: BOOLEAN; FireEvent: BOOLEAN = true) : Integer; OVERLOAD;
    function SetCheckInt(I: NativeInt; State: BOOLEAN; FireEvent: BOOLEAN = true) : Integer; OVERLOAD; INLINE;

    property Count: Integer read GetCount;
    property Checks[Index, CheckBoxNo: Integer]: Boolean read GetChecked write SetChecked;
    property Checked[Index: Integer]: Boolean Index 0 read GetChecked write SetChecked;
    property VisibleItem[Index: Integer]: Boolean read GetVisibleItem write SetVisibleItem;
    property Selected[Index: Integer]: Boolean read GetSelected write SetSelected;
    property Item[Index: Integer]: String read GetItem; default;
    property Ints[Index: Integer]: NativeInt Read GetInt Write SetInt;
    property Objects[Index: Integer]: TObject read GetObj Write SetObj;
    function NextVisible(Index: Integer; Wrap: Boolean): Integer;
    function IsEmpty: Boolean; inline;
    function CheckedIndices(CheckBoxNo: Integer = 0): TArray<Integer>;

    procedure UncheckAll(FireEvent: Boolean; CheckBoxNo: Integer = 0); overload; inline;
    procedure UncheckAll(CheckBoxNo: Integer; FireEvent: Boolean = true); overload;
    procedure checkAll(FireEvent: Boolean; CheckBoxNo: Integer = 0); overload; inline;
    procedure checkAll(CheckBoxNo: Integer; FireEvent: Boolean = true); overload;

  published
    property Align;
    property Anchors;
    property BiDiMode;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property CheckBoxCount: Integer read FCheckBoxCount write SetCheckBoxCount default 0;
    property Color default clWindow;
    property Constraints;
    property Ctl3D;
    property DoubleBuffered;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Items: TStrings read FItems write SetItems;
    property ItemHeight: Integer read FItemHeight write SetItemHeight default 0;
    property ItemIndex: Integer read FItemIndex write SetItemIndex_ default -1;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentDoubleBuffered;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    property OnClick;
    property OnClickCheck: TNotifyEvent read FOnClickCheck write FOnClickCheck; // legacy: user checkbox click/space only
    property OnCheckBoxClicked: THWCheckBoxClickedEvent read FOnCheckBoxClicked write FOnCheckBoxClicked;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

{ THWMultiCheckListBoxStrings }

constructor THWMultiCheckListBoxStrings.Create(AOwner: THWMultiCheckListBox);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure THWMultiCheckListBoxStrings.InsertItem(Index: Integer; const S: string; AObject: TObject);
begin
  if Assigned(FOwner) then
    FOwner.InsertState(Index);

  inherited InsertItem(Index, S, AObject);
end;

procedure THWMultiCheckListBoxStrings.Delete(Index: Integer);
begin
  if Assigned(FOwner) then
    FOwner.DeleteState(Index);

  inherited Delete(Index);
end;

procedure THWMultiCheckListBoxStrings.Clear;
begin
  if Assigned(FOwner) then
    FOwner.ClearStates;

  inherited Clear;
end;

{ THWMultiCheckListBox }

constructor THWMultiCheckListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks] - [csClickEvents];

  Width := 145;
  Height := 97;

  TabStop := True;
  ParentColor := False;
  Color := clWindow;

  FItems := THWMultiCheckListBoxStrings.Create(Self);
  TStringList(FItems).OnChange := ItemsChanged;

  //FCheckBoxCount := 1;
  FItemIndex := -1;
  FTopVisibleRow := 0;
  FItemHeight := 0;
  FBorderStyle := bsSingle;
end;

destructor THWMultiCheckListBox.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure THWMultiCheckListBox.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);

  Params.Style := Params.Style or WS_VSCROLL;

  if FBorderStyle = bsSingle then
    Params.Style := Params.Style or WS_BORDER;
end;

procedure THWMultiCheckListBox.CreateWnd;
begin
  inherited CreateWnd;
  UpdateScrollBar;
end;

function THWMultiCheckListBox.Add(const S: String; O: TObject = nil): Integer;
begin
  Result:=Items.AddObject(S, O);
end;

function THWMultiCheckListBox.Add(const S: String; I: NativeInt): Integer;
begin
  Result:=Items.AddObject(S, TObject(I))
end;

function THWMultiCheckListBox.Add(const S: String; I: NativeInt; Checked: Boolean): Integer;
begin
  Result:=Add(S,I);
  Self.Checked[Result]:=Checked
end;

procedure THWMultiCheckListBox.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure THWMultiCheckListBox.EndUpdate;
begin
  if Updating then
    Dec(FUpdateCount);

  if not Updating then
  begin
    EnsureStateArrays;
    UpdateScrollBar;
    Invalidate;
  end;
end;

function THWMultiCheckListBox.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function THWMultiCheckListBox.GetInt(Index: Integer): NativeInt;
begin
  Result:=NativeInt(Objects[Index])
end;

function THWMultiCheckListBox.GetItem(Index: Integer): String;
begin
  if ValidIndex(Index) then Result:=Items[Index] else Result:=''
end;

function THWMultiCheckListBox.GetObj(Index: Integer): TObject;
begin
  Result:=if ValidIndex(Index) then Items.Objects[Index] else nil
end;

procedure THWMultiCheckListBox.SetItems(const Value: TStrings);
begin
  BeginUpdate;
  try
    FItems.Assign(Value);
  finally
    EndUpdate;
  end;
end;

procedure THWMultiCheckListBox.SetObj(Index: Integer; Value: TObject);
begin
  if ValidIndex(Index) then Items.Objects[Index]:=Value;
end;

procedure THWMultiCheckListBox.ItemsChanged(Sender: TObject);
begin
  EnsureStateArrays;
  RequestUpdate;
end;

procedure THWMultiCheckListBox.CheckItemIndex(Index: Integer);
begin
  if (Index < 0) or (Index >= Count) then
    raise EListError.CreateFmt('Item index out of bounds (%d)', [Index]);
end;

procedure THWMultiCheckListBox.CheckCheckBoxNo(CheckBoxNo: Integer);
begin
  if (CheckBoxNo < 0) or (CheckBoxNo >= FCheckBoxCount) then
    raise EListError.CreateFmt('Checkbox index out of bounds (%d)', [CheckBoxNo]);
end;

function THWMultiCheckListBox.CheckedIndices(CheckBoxNo: Integer = 0): TArray<Integer>;
var
  I: Integer;
begin
  SetLength(Result,0);
  for I:=LOW to HIGH do if Checks[I,CheckBoxNo] then Result:=Result+[i]
end;

function THWMultiCheckListBox.Insert(Index: Integer; const S: String; O: TObject): Integer;
begin
  Items.InsertObject(Index, S, O);
  Result := Index
end;

function THWMultiCheckListBox.Insert(Index: Integer; const S: String; I: NativeInt): Integer;
begin
  Items.Insert(Index,S);
  Ints[Index] := I;
end;

function THWMultiCheckListBox.Insert(Index: Integer; const S: String; I: NativeInt; Checked: Boolean): Integer;
begin
  Items.Insert(Index,S);
  Ints[Index] := I; Self.Checked[Index] := Checked
end;

procedure THWMultiCheckListBox.InsertState(Index: Integer);
var
  I: Integer;
begin
  Index := EnsureRange(Index, 0, Length(FVisibleItems));

  SetLength(FVisibleItems, Length(FVisibleItems) + 1);
  for I := System.High(FVisibleItems) downto Index + 1 do
    FVisibleItems[I] := FVisibleItems[I - 1];
  FVisibleItems[Index] := True;

  SetLength(FChecked, Length(FChecked) + 1);
  for I := System.High(FChecked) downto Index + 1 do
    FChecked[I] := FChecked[I - 1];

  FChecked[Index] := nil;
  SetLength(FChecked[Index], FCheckBoxCount);

  if FItemIndex >= Index then
    Inc(FItemIndex);
end;

procedure THWMultiCheckListBox.DeleteState(Index: Integer);
var
  I: Integer;
begin
  if (Index < 0) or (Index >= Length(FVisibleItems)) then
    Exit;

  for I := Index to System.High(FVisibleItems) - 1 do
    FVisibleItems[I] := FVisibleItems[I + 1];

  SetLength(FVisibleItems, Length(FVisibleItems) - 1);

  for I := Index to System.High(FChecked) - 1 do
    FChecked[I] := FChecked[I + 1];

  SetLength(FChecked, Length(FChecked) - 1);

  if FItemIndex = Index then
    FItemIndex := -1
  else if FItemIndex > Index then
    Dec(FItemIndex);
end;

procedure THWMultiCheckListBox.Clear(FreeObjects: Boolean);
begin
  if FreeObjects then for var i:=LOW to HIGH do Items.Objects[i].Free;
  Items.Clear
end;

procedure THWMultiCheckListBox.ClearStates;
begin
  SetLength(FVisibleItems, 0);
  SetLength(FChecked, 0);
  FItemIndex := -1;
  FTopVisibleRow := 0;
end;

procedure THWMultiCheckListBox.EnsureStateArrays;
var
  OldCount: Integer;
  NewCount: Integer;
  I: Integer;
begin
  OldCount := Length(FVisibleItems);
  NewCount := FItems.Count;

  SetLength(FVisibleItems, NewCount);

  for I := OldCount to NewCount - 1 do
    FVisibleItems[I] := True;

  SetLength(FChecked, NewCount);

  for I := 0 to NewCount - 1 do
    SetLength(FChecked[I], FCheckBoxCount);

  if NewCount = 0 then
    FItemIndex := -1
  else if FItemIndex >= NewCount then
    FItemIndex := NewCount - 1;
end;

function THWMultiCheckListBox.GetChecked(Index, CheckBoxNo: Integer): Boolean;
begin
  CheckItemIndex(Index);
  CheckCheckBoxNo(CheckBoxNo);
  Result := FChecked[Index][CheckBoxNo];
end;

procedure THWMultiCheckListBox.DoCheckBoxClicked(Index, CheckBoxNo: Integer; State: Boolean);
begin
  if Assigned(FOnCheckBoxClicked) then
    FOnCheckBoxClicked(Self, Index, CheckBoxNo, State);
end;

procedure THWMultiCheckListBox.DoClickCheck;
begin
  if Assigned(FOnClickCheck) then
    FOnClickCheck(Self);
end;

function THWMultiCheckListBox.ChangeChecked(Index, CheckBoxNo: Integer; const Value,FireEvent: Boolean): Boolean;
begin
  CheckItemIndex(Index);
  CheckCheckBoxNo(CheckBoxNo);

  Result := FChecked[Index][CheckBoxNo] <> Value;

  if Result then
  begin
    FChecked[Index][CheckBoxNo] := Value;
    InvalidateItem(Index);
    if FireEvent then
      DoCheckBoxClicked(Index,CheckBoxNo,Value);
  end;
end;

procedure THWMultiCheckListBox.CheckAll(CheckBoxNo: Integer; FireEvent: Boolean = true);
begin
  SetCheckAll(CheckBoxNo,true,FireEvent);
end;

procedure THWMultiCheckListBox.CheckAll(FireEvent: Boolean; CheckBoxNo: Integer = 0);
begin
  CheckAll(CheckBoxNo,FireEvent);
end;

procedure THWMultiCheckListBox.SetChecked(Index, CheckBoxNo: Integer; const Value: Boolean);
begin
  SetCheck(Index,CheckBoxNo,Value,true);
end;

function THWMultiCheckListBox.SetCheckInt(I: NativeInt; State: Boolean; FireEvent: Boolean = true): Integer;
begin
  Result:=SetCheckInt(I,0,State,FireEvent);
end;

function THWMultiCheckListBox.SetCheckInt(I: NativeInt; CheckBoxNo: Integer; State: Boolean; FireEvent: Boolean = true): Integer;
begin
  Result:=SetCheck(IndexOf(I),CheckBoxNo,State,FireEvent)
end;

function THWMultiCheckListBox.GetVisibleItem(Index: Integer): Boolean;
begin
  CheckItemIndex(Index);
  Result := FVisibleItems[Index];
end;

function THWMultiCheckListBox.HIGH: Integer;
begin
  Result := Count-1;
end;

procedure THWMultiCheckListBox.SetVisibleItem(Index: Integer; const Value: Boolean);
begin
  CheckItemIndex(Index);

  if FVisibleItems[Index] <> Value then
  begin
    FVisibleItems[Index] := Value;
    RequestUpdate;
  end;
end;

function THWMultiCheckListBox.GetSelected(Index: Integer): Boolean;
begin
  CheckItemIndex(Index);
  Result := Index = FItemIndex;
end;

procedure THWMultiCheckListBox.SetSelected(Index: Integer; const Value: Boolean);
begin
  CheckItemIndex(Index);

  if Value then
    ItemIndex := Index
  else if FItemIndex = Index then
    ItemIndex := -1;
end;

function THWMultiCheckListBox.SetCheck(O: TObject; CheckBoxNo: Integer; State: Boolean; FireEvent: Boolean = true): Integer;
begin
  Result:=SetCheck(IndexOf(O),CheckBoxNo,State,FireEvent);
end;

function THWMultiCheckListBox.SetCheck(Index, CheckBoxNo: Integer; State,FireEvent: Boolean): Integer;
begin
  ChangeChecked(Index,CheckBoxNo,State,FireEvent);
end;

procedure THWMultiCheckListBox.SetCheckAll(CheckBoxNo: Integer; Checked,FireEvent: Boolean);
var
  I: Integer;

begin
  for I:=LOW to HIGH do SetCheck(I, CheckBoxNo, Checked, FALSE);
  if FireEvent then DoClickCheck;
end;

procedure THWMultiCheckListBox.SetCheckBoxCount(const Value: Integer);
var
  NewValue: Integer;
  I: Integer;
begin
  NewValue := Max(0, Value);

  if FCheckBoxCount <> NewValue then
  begin
    FCheckBoxCount := NewValue;

    for I := 0 to Count - 1 do
      SetLength(FChecked[I], FCheckBoxCount);

    RequestUpdate;
  end;
end;

procedure THWMultiCheckListBox.SetItemIndex(O: TObject; FireEvent: Boolean = true);
begin
  SetItemIndex(IndexOf(O), FireEvent);
end;

procedure THWMultiCheckListBox.SetItemIndex(const S: String; FireEvent: Boolean = true);
begin
  SetItemIndex(IndexOf(S), FireEvent);
end;

procedure THWMultiCheckListBox.SetItemIndex_(const Value: Integer);
var
  NewValue: Integer;
begin
  NewValue := EnsureRange(Value,-1,HIGH);

  if ValidIndex(NewValue) then
  begin
    if not FVisibleItems[NewValue] then
      FVisibleItems[NewValue] := True;
  end;

  if FItemIndex <> NewValue then
  begin
    FItemIndex := NewValue;

    MakeItemVisible(FItemIndex);

    RequestUpdate;
    Click;
  end
  else if FItemIndex >= 0 then
  begin
    MakeItemVisible(FItemIndex);
    RequestUpdate;
  end;
end;

procedure THWMultiCheckListBox.SetInt(Index: Integer; Value: NativeInt);
begin
  Objects[Index]:=TObject(Value)
end;

procedure THWMultiCheckListBox.SetItem(Index: Integer; const S: String;
  O: TObject);
begin
  Items[Index]:=S; Items.Objects[Index]:=O;
end;

procedure THWMultiCheckListBox.SetItemHeight(const Value: Integer);
begin
  if Value < 0 then
    raise ERangeError.Create('ItemHeight cannot be negative');

  if FItemHeight <> Value then
  begin
    FItemHeight := Value;
    RequestUpdate;
  end;
end;

procedure THWMultiCheckListBox.SetItemIndex(Index: Integer; FireEvent: Boolean);
begin
  VAR BAK := OnClick;
  try
    OnClick:=nil; ItemIndex:=Index;
  finally
    OnClick:=BAK;
  end;
  if FireEvent and Assigned(BAK) then BAK(Self);
end;

procedure THWMultiCheckListBox.SetBorderStyle(const Value: TBorderStyle);
begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    RecreateWnd;
  end;
end;

function THWMultiCheckListBox.EffectiveItemHeight: Integer;
begin
  if FItemHeight > 0 then
    Exit(FItemHeight);

  Canvas.Font := Font;

  Result := Max(
    Canvas.TextHeight('Wg') + 4,
    GetSystemMetrics(SM_CYMENUCHECK) + 4
  );

  Result := Max(Result, 12);
end;

function THWMultiCheckListBox.CheckBoxSize: Integer;
begin
  Result := Max(
    GetSystemMetrics(SM_CXMENUCHECK),
    GetSystemMetrics(SM_CYMENUCHECK)
  );

  Result := Max(Result, 13);
end;

function THWMultiCheckListBox.GetVisibleCount: Integer;
var
  I: Integer;
begin
  Result := 0;

  for I := 0 to Count - 1 do
    if FVisibleItems[I] then
      Inc(Result);
end;

function THWMultiCheckListBox.VisibleRowsOnScreen: Integer;
begin
  Result := EnsureRange(ClientHeight div EffectiveItemHeight, 1, MAXINT);
end;

function THWMultiCheckListBox.ValidIndex(Index: Integer): Boolean;
begin
  Result:=InRange(Index,LOW,HIGH);
end;

function THWMultiCheckListBox.ValidIndex: Boolean;
begin
  Result:=ValidIndex(ItemIndex);
end;

function THWMultiCheckListBox.VisibleItems: TArray<Integer>;
var
  I: Integer;
begin
  SetLength(Result,0);
  for i:=LOW to HIGH do
    if FVisibleItems[i] then
      Result:=Result+[i]
end;

function THWMultiCheckListBox.VisibleOrdinalOfIndex(Index: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  if not (ValidIndex(Index) and FVisibleItems[Index]) then
    Exit;

  Result := 0;

  for I := 0 to Index - 1 do
    if FVisibleItems[I] then
      Inc(Result);
end;

function THWMultiCheckListBox.IndexOf(const S: String): Integer;
begin
  Result:=Items.IndexOf(S);
end;

function THWMultiCheckListBox.IndexOf(O: TObject): Integer;
begin
  Result:=Items.IndexOfObject(O);
end;

function THWMultiCheckListBox.IndexOfVisibleOrdinal(Ordinal: Integer): Integer;
var
  I: Integer;
  N: Integer;
begin
  Result := -1;
  N := 0;

  for I := 0 to Count - 1 do
  begin
    if FVisibleItems[I] then
    begin
      if N = Ordinal then
        Exit(I);

      Inc(N);
    end;
  end;
end;

function THWMultiCheckListBox.FirstVisibleIndex: Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to Count - 1 do
    if FVisibleItems[I] then
      Exit(I);
end;

function THWMultiCheckListBox.LastVisibleIndex: Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := Count - 1 downto 0 do
    if FVisibleItems[I] then
      Exit(I);
end;

function THWMultiCheckListBox.NextVisible(Index: Integer;
  Wrap: Boolean): Integer;
begin
  Result:=Index;
  repeat
    inc(Result);
    if not ValidIndex(Result) then break;
    if VisibleItem[Result] then exit;
  until false;
  if Wrap then
    for Result:=LOW to HIGH do if VisibleItem[Result] then exit;
  Result:=-1
end;

function THWMultiCheckListBox.NextVisibleIndex(FromIndex, Delta: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  if Delta = 0 then
    Exit;

  I := FromIndex + Delta;

  while (I >= 0) and (I < Count) do
  begin
    if FVisibleItems[I] then
      Exit(I);

    Inc(I, Delta);
  end;
end;

procedure THWMultiCheckListBox.SetTopVisibleRow(Value: Integer);
var
  MaxTop: Integer;
begin
  MaxTop := Max(0, GetVisibleCount - VisibleRowsOnScreen);
  Value := EnsureRange(Value, 0, MaxTop);

  if FTopVisibleRow <> Value then
  begin
    FTopVisibleRow := Value;
    UpdateScrollBar;
    Invalidate;
  end;
end;

procedure THWMultiCheckListBox.MakeItemVisible(Index: Integer);
var
  Ordinal: Integer;
  Rows: Integer;
begin
  if (Index < 0) or (Index >= Count) then
    Exit;

  if not FVisibleItems[Index] then
    FVisibleItems[Index] := True;

  Ordinal := VisibleOrdinalOfIndex(Index);

  if Ordinal < 0 then
    Exit;

  Rows := VisibleRowsOnScreen;

  if Ordinal < FTopVisibleRow then
    FTopVisibleRow := Ordinal
  else if Ordinal >= FTopVisibleRow + Rows then
    FTopVisibleRow := Ordinal - Rows + 1;

  UpdateScrollBar;
end;

procedure THWMultiCheckListBox.UncheckAll(CheckBoxNo: Integer; FireEvent: Boolean = true);
begin
  SetCheckAll(CheckBoxNo,false,FireEvent);
end;

procedure THWMultiCheckListBox.UncheckAll(FireEvent: Boolean; CheckBoxNo: Integer = 0);
begin
  UncheckAll(CheckBoxNo,FireEvent);
end;

procedure THWMultiCheckListBox.UpdateScrollBar;
var
  SI: TScrollInfo;
  VisCount: Integer;
  Rows: Integer;
begin
  if not HandleAllocated then
    Exit;

  VisCount := GetVisibleCount;
  Rows := VisibleRowsOnScreen;

  FTopVisibleRow := EnsureRange(
    FTopVisibleRow,
    0,
    Max(0, VisCount - Rows)
  );

  ZeroMemory(@SI, SizeOf(SI));
  SI.cbSize := SizeOf(SI);
  SI.fMask := SIF_RANGE or SIF_PAGE or SIF_POS;
  SI.nMin := 0;

  if VisCount > 0 then
    SI.nMax := VisCount - 1
  else
    SI.nMax := 0;

  SI.nPage := Rows;
  SI.nPos := FTopVisibleRow;

  SetScrollInfo(Handle, SB_VERT, SI, True);
  ShowScrollBar(Handle, SB_VERT, VisCount > Rows);
end;

function THWMultiCheckListBox.Updating: Boolean;
begin
  Result:=(FUpdateCount>0);
end;

procedure THWMultiCheckListBox.RequestUpdate;
begin
  if not Updating then
  begin
    UpdateScrollBar;
    Invalidate;
  end;
end;

procedure THWMultiCheckListBox.InvalidateItem(Index: Integer);
var
  Ordinal: Integer;
  H: Integer;
  R: TRect;
begin
  if Updating then
    Exit;

  if not HandleAllocated then
    Exit;

  Ordinal := VisibleOrdinalOfIndex(Index);

  if Ordinal < 0 then
    Exit;

  if (Ordinal < FTopVisibleRow) or (Ordinal >= FTopVisibleRow + VisibleRowsOnScreen + 1) then
    Exit;

  H := EffectiveItemHeight;

  R := Rect(
    0,
    (Ordinal - FTopVisibleRow) * H,
    ClientWidth,
    (Ordinal - FTopVisibleRow + 1) * H
  );

  InvalidateRect(Handle, @R, False);
end;

function THWMultiCheckListBox.IsEmpty: Boolean;
begin
  Result:=(Count=0);
end;

procedure THWMultiCheckListBox.Paint;
var
  Y: Integer;
  H: Integer;
  Index: Integer;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  H := EffectiveItemHeight;
  Y := 0;

  Index := IndexOfVisibleOrdinal(FTopVisibleRow);

  while (Index >= 0) and (Index < Count) and (Y < ClientHeight) do
  begin
    if FVisibleItems[Index] then
    begin
      DrawItem(Index, Y);
      Inc(Y, H);
    end;

    Inc(Index);
  end;
end;

procedure THWMultiCheckListBox.DrawItem(Index, Y: Integer);
var
  R: TRect;
  TextR: TRect;
  BoxR: TRect;
  I: Integer;
  X: Integer;
  S: string;
  H: Integer;
  B: Integer;
  Flags: UINT;
  IsSelected: Boolean;
  BkColor: TColor;
  TextColor: TColor;
begin
  H := EffectiveItemHeight;
  B := CheckBoxSize;

  R := Rect(0, Y, ClientWidth, Y + H);

  IsSelected := Index = FItemIndex;

  if not Enabled then
  begin
    BkColor := Color;
    TextColor := clGrayText;
  end
  else if IsSelected then
  begin
    BkColor := clHighlight;
    TextColor := clHighlightText;
  end
  else
  begin
    BkColor := Color;
    TextColor := Font.Color;
  end;

  Canvas.Brush.Color := BkColor;
  Canvas.FillRect(R);

  X := 2;

  for I := 0 to FCheckBoxCount - 1 do
  begin
    BoxR := Rect(
      X,
      Y + ((H - B) div 2),
      X + B,
      Y + ((H - B) div 2) + B
    );

    Flags := DFCS_BUTTONCHECK;

    if FChecked[Index][I] then
      Flags := Flags or DFCS_CHECKED;

    if not Enabled then
      Flags := Flags or DFCS_INACTIVE;

    DrawFrameControl(Canvas.Handle, BoxR, DFC_BUTTON, Flags);

    Inc(X, B + 2);
  end;

  if FCheckBoxCount = 0 then
    X := 4
  else
    Inc(X, 2);

  TextR := Rect(X, Y, ClientWidth - 2, Y + H);

  Canvas.Font := Font;
  Canvas.Font.Color := TextColor;
  SetBkMode(Canvas.Handle, TRANSPARENT);

  S := FItems[Index];

  DrawText(
    Canvas.Handle,
    PChar(S),
    Length(S),
    TextR,
    DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX
  );

  if Focused and IsSelected then
  begin
    R.Right := ClientWidth;
    WinAPI.Windows.DrawFocusRect(Canvas.Handle, R);
  end;
end;

procedure THWMultiCheckListBox.Resize;
begin
  inherited Resize;
  RequestUpdate;
end;

procedure THWMultiCheckListBox.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure THWMultiCheckListBox.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

procedure THWMultiCheckListBox.CMFontChanged(var Message: TMessage);
begin
  inherited;
  RequestUpdate;
end;

procedure THWMultiCheckListBox.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure THWMultiCheckListBox.WMVScroll(var Message: TWMVScroll);
var
  NewTop: Integer;
begin
  NewTop := FTopVisibleRow;

  case Message.ScrollCode of
    SB_LINEUP:
      Dec(NewTop);

    SB_LINEDOWN:
      Inc(NewTop);

    SB_PAGEUP:
      Dec(NewTop, VisibleRowsOnScreen);

    SB_PAGEDOWN:
      Inc(NewTop, VisibleRowsOnScreen);

    SB_THUMBPOSITION,
    SB_THUMBTRACK:
      NewTop := Message.Pos;

    SB_TOP:
      NewTop := 0;

    SB_BOTTOM:
      NewTop := GetVisibleCount - VisibleRowsOnScreen;
  end;

  SetTopVisibleRow(NewTop);
end;

procedure THWMultiCheckListBox.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

function THWMultiCheckListBox.ItemAtPos(P: TPoint; Existing: Boolean): Integer;
var
  Row: Integer;
begin
  Result := -1;

  if (P.X < 0) or (P.X >= ClientWidth) or
     (P.Y < 0) or (P.Y >= ClientHeight) then
    Exit;

  Row := P.Y div EffectiveItemHeight;
  Result := IndexOfVisibleOrdinal(FTopVisibleRow + Row);
  if Result > HIGH then
    if Existing then Result := -1 else Result := HIGH + 1;
end;

function THWMultiCheckListBox.ItemAtPos(X, Y: Integer; Existing: Boolean): Integer;
begin
  Result := ItemAtPos(Point(X, Y), Existing);
end;

function THWMultiCheckListBox.CheckBoxNoAtX(X: Integer): Integer;
var
  I: Integer;
  B: Integer;
  LeftPos: Integer;
begin
  Result := -1;

  if FCheckBoxCount <= 0 then
    Exit;

  B := CheckBoxSize;
  LeftPos := 2;

  for I := 0 to FCheckBoxCount - 1 do
  begin
    if (X >= LeftPos) and (X < LeftPos + B) then
      Exit(I);

    Inc(LeftPos, B + 2);
  end;
end;

function THWMultiCheckListBox.CheckBoxAtPos(P: TPoint; out Index, CheckBoxNo: Integer): Boolean;
begin
  Index := ItemAtPos(P, True);
  CheckBoxNo := -1;

  if Index < 0 then
    Exit(False);

  CheckBoxNo := CheckBoxNoAtX(P.X);
  Result := CheckBoxNo >= 0;
end;

procedure THWMultiCheckListBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
  CheckNo: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Button <> mbLeft then
    Exit;

  if CanFocus then
    SetFocus;

  Index := ItemAtPos(X, Y, True);

  if Index < 0 then
    Exit;

  ItemIndex := Index;

  CheckNo := CheckBoxNoAtX(X);

  if CheckNo >= 0 then
  begin
    if ChangeChecked(Index, CheckNo, not FChecked[Index][CheckNo],true) then
    begin
      DoClickCheck;
    end;
  end;
end;

function THWMultiCheckListBox.DoMouseWheel(
  Shift: TShiftState;
  WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  Lines: Integer;
  Steps: Integer;
begin
  Result := True;

  Lines := Mouse.WheelScrollLines;

  if Lines <= 0 then
    Lines := 3;

  Steps := WheelDelta div WHEEL_DELTA;

  if Steps <> 0 then
    SetTopVisibleRow(FTopVisibleRow - Steps * Lines);
end;

procedure THWMultiCheckListBox.KeyDown(var Key: Word; Shift: TShiftState);
var
  NewIndex: Integer;
  Ordinal: Integer;
begin
  inherited KeyDown(Key, Shift);

  NewIndex := FItemIndex;

  case Key of
    VK_UP:
      begin
        if FItemIndex < 0 then
          NewIndex := LastVisibleIndex
        else
          NewIndex := NextVisibleIndex(FItemIndex, -1);
      end;

    VK_DOWN:
      begin
        if FItemIndex < 0 then
          NewIndex := FirstVisibleIndex
        else
          NewIndex := NextVisibleIndex(FItemIndex, 1);
      end;

    VK_HOME:
      NewIndex := FirstVisibleIndex;

    VK_END:
      NewIndex := LastVisibleIndex;

    VK_PRIOR:
      begin
        if FItemIndex < 0 then
          NewIndex := FirstVisibleIndex
        else
        begin
          Ordinal := VisibleOrdinalOfIndex(FItemIndex);
          if Ordinal < 0 then
            Ordinal := FTopVisibleRow;

          NewIndex := IndexOfVisibleOrdinal(Max(0, Ordinal - VisibleRowsOnScreen));
        end;
      end;

    VK_NEXT:
      begin
        if FItemIndex < 0 then
          NewIndex := FirstVisibleIndex
        else
        begin
          Ordinal := VisibleOrdinalOfIndex(FItemIndex);
          if Ordinal < 0 then
            Ordinal := FTopVisibleRow;

          NewIndex := IndexOfVisibleOrdinal(
            Min(GetVisibleCount - 1, Ordinal + VisibleRowsOnScreen)
          );
        end;
      end;

    VK_SPACE:
      begin
        if (FItemIndex >= 0) and (FCheckBoxCount > 0) then
        begin
          if ChangeChecked(FItemIndex, 0, not FChecked[FItemIndex][0],true) then
          begin
            DoClickCheck
          end;
        end;

        Key := 0;
        Exit;
      end;
  else
    Exit;
  end;

  if NewIndex >= 0 then
    ItemIndex := NewIndex;

  Key := 0;
end;

function THWMultiCheckListBox.IndexOf(I: NativeInt): Integer;
begin
  Result:=IndexOf(TObject(I));
end;

end.
