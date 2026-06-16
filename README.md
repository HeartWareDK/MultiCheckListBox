# MultiCheckListBox

  THWMultiCheckListBox
  --------------------
  Authored by ChatGPT (not Codex) in June 2026.
  
  Updated/Adapted by HeartWare
  
  (C) 2026 HeartWare

  License: Free for private and non-commercial use only.

  This source code may be used, modified, and redistributed in private or
  non-commercial projects, provided that this license notice remains intact.

  Commercial use is not permitted without prior agreement.

  For the purposes of this license, commercial use includes, but is not
  limited to, selling the software, including it in paid products, using it
  in paid client work, using it in donation-supported products, accepting
  donations or sponsorships connected to the software, or receiving any other
  monetary compensation or value-based items related to the use or distribution
  of this code.

  For commercial licensing, contact the author.

  This is a custom-drawn VCL TCheckListBox-style control that behaves like a
  logical TCheckListBox, but with two important extensions:

    1) Each item may have zero, one, or several CheckBoxes
       (same count for all Items).
    2) Individual items may be hidden without removing them from Items.

  The control is not descended from TListBox or TCheckListBox. It is drawn
  manually, and mouse/keyboard handling is implemented by the control itself.
  This allows the visual list to differ from the logical Items collection.

  Logical item indexes
  --------------------
  Items, Count, ItemIndex, Checks[], VisibleItem[] and Selected[] all use the
  original logical item index.

  If Items contains:

      0: 'Alpha'
      1: 'Beta'
      2: 'Gamma'
      3: 'Delta'

  and item 2 is hidden:

      VisibleItem[2] := False;

  then only Alpha, Beta and Delta are drawn, but the logical indexes remain
  0, 1, 2 and 3. Clicking or navigating to the bottom visible row therefore
  returns:

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
  Defines how many CheckBoxes each item has.

      CheckBoxCount := 0;  // no CheckBoxes, TListBox-style display only
      CheckBoxCount := 1;  // ordinary TCheckListBox look
      CheckBoxCount := 3;  // three independent CheckBoxes per item

  All items have the same number of ChexkBoxes.

  CheckBox indexes are zero-based.

  Checks[Index, CheckBoxNo]
  Checked[Index]
  --------------------------
  Gets or sets the checked state of one CheckBox for one logical item.

      Checks[5, 0] := True;
      Checks[5, 1] := False;

  The first index is the logical item index.
  The second index is the CheckBox number, from 0 to CheckBoxCount - 1.

  There's also a Checked[Index] : Boolean property that always addresses
  CheckBoxNo = 0 (for easy and backward-compatible use with plain TCheckBoxList)

  When the checked state actually changes, OnCheckBoxClicked is fired. This
  happens both for user interaction and for programmatic changes through the
  Checks[] property.

  However, see the description of OnCheckBoxClicked for overrides to this rule.

  ItemIndex and OnClick
  ---------------------
  ItemIndex is the logical selected item index, not the visible row number.

  OnClick is treated as an "ItemIndex changed" event. It fires when ItemIndex
  changes, including keyboard navigation. Merely clicking the already-selected
  item does not count as an ItemIndex change.

  There are user-callable SetItemIndex methods with an optional "FireEvent"
  parameter (default TRUE) that either suppresses or enforces an OnClick event,
  regardless of whether or not the selected item value changes.

  OnCheckBoxClicked
  -----------------
  Fires whenever a CheckBox changes state.

      OnCheckBoxClicked(Sender, ItemIndex, CheckBoxIndex, State)

  ItemIndex is the logical item index.
  CheckBoxIndex is the zero-based CheckBox number.
  State is the new checked state (Boolean).

  This event is fired for mouse clicks, keyboard toggles, and manual assignment
  to Checked[Index, CheckBoxNo], but only if the state actually changes.

  There are user-callable SetCheck methods to set CheckBoxes, again with an
  optional "FireEvent" parameter that overrides the "only when changed"
  condition and unconditionally calls (or suppresses) the OnChecked events.

  LOW / HIGH / ValidIndex
  -----------------------
  Helpers to easily iterate over all (logical) indexes, and to check if a given
  index is valid.

  BeginUpdate / EndUpdate
  -----------------------
  Use BeginUpdate / EndUpdate when changing many item states, especially
  VisibleItem[], to suppress repeated redraws and scrollbar recalculations.

      BeginUpdate;
      try
        for I := LOW to HIGH do
          VisibleItem[I] := ShouldShowItem(I);
      finally
        EndUpdate;
      end;

  BeginUpdate/EndUpdate can be nested.

  The control refreshes itself only when the final matching EndUpdate is called,
  ie. when there has been a sufficient number of "EndUpdate" calls to counteract
  all the ecurrently active BeginUpdate calls.

  OnGetTextInfo
  -------------
  This event is called whenever an item is about to be drawn. You can update
  the values (Font/Background Color) to have the item drawn using your
  modified values, but do not change the height of the Font, as there will
  not be enough/too much room in the visible portion to display the text.

  The text is drawn in the color that is contained within the TFont given.

  KbdCheckBoxNo
  -------------
  Specifies the CheckBoxNo that is toggled on keyboard (Space bar) toggling.
  Default = 0 (the first CheckBox).

  AutoAdvance
  -----------
  Specifies whether or not the selection bar advances to the next visible item
  in the list, if you use the keyboard to toggle the Checked state (of
  CheckBoxNo = KbdCheckBoxNo).

  Notes
  -----
  Because this is a custom-drawn control rather than a native ListBox, only
  the TCheckListBox-like behavior explicitly implemented by the component is
  available. The Items collection and logical selection model are compatible
  with normal ListBox usage, but native ListBox-specific Windows behavior,
  styles, and messages should not be assumed.

  Since the attached TStringList's Objects[] property is used for storing
  the Ints[] values, it is not safe to mix Objects[] and Ints[] in the same
  ListBox, unless you have another way to distinguish between these.

  Also, it is explicitly unsafe to call Clear(True) if you have stored Ints[]
  in the ListBox, as this will result in an attempt to free a value that is
  not an Object, but an arbitary index (which will then be interpreted as the
  address of a TObject instance).

# Updates:
```text
  16/06-2026  Updated README file to better describe properties and workflow
              New Event: OnGetTextInfo
  12/06-2026  Updated file structure.
              Several new support functions directly on the ListBox level:
                Overloaded Add/Insert new items with Ints[]/Objects[] support
                Direct access to Items.Objects[] via ListBox.Objects[]
                IndexOf(String/Object/Integer)
                ValidIndex check function
                CheckedIndices / VisibleItems -> TArray<Integer>
                .LOW and .HIGH accessors (to use in FOR I:=LOW TO HIGH)
                CheckAll
                UncheckAll
                SetCheck (with a possible "don't fire OnCheck events")
                Overloaded SetItemIndex (with a possible "don't fire OnClick" events)
              .CheckBoxStyle property (Modern/Classic)
              .KbdCheckBoxNo to specify which CheckBox the SPACE key toggles
              .AutoAdvance to specify if SPACE key toggling advances to next item
              New .Ints[Index] property (uses Items.Objects[] to store the value)
              Renamed Checked to Checks for Multi-CheckBox access
              New Checked property that always uses CheckBoxNo = 0 for better compatibilty
```
