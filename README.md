# MultiCheckListBox

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

  Checks[Index, CheckBoxNo]
  --------------------------

  Gets or sets the checked state of one checkbox for one logical item.

      Checks[5, 0] := True;
      Checks[5, 1] := False;

  The first index is the logical item index.
  The second index is the checkbox number, from 0 to CheckBoxCount - 1.

  There's also a backwards-compatible Checked[Index] that always operate
  on CheckBoxNo = 0.

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

# Updates:
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
                SetCheck (with a possible "don't fire OnCheck events)
                Overloaded SetItemIndex (with a possible "don't fire OnClick" events)
              New .Ints[Index] property (uses Items.Objects[] to store the value)
              Renamed Checked to Checks for Multi-CheckBox access
              New Checked that always uses CheckBoxNo = 0 for better compatibilty
