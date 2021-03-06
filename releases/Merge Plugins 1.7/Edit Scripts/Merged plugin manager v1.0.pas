{
  Merged Plugin Manager v1.0
  Created by matortheeternal
  
  * DESCRIPTION *
  Can remove plugins from a merged plugin and generate user
  reports on the effectiveness of a merged plugin.
}

unit mpManager;

uses mteFunctions;

const
  vs = 'v1.0';
  notesmax = 255;
  smartremove = false;
  // smart removal!  if true RemovePlugin won't remove forms that
  // are used by other plugins internally.

var
  cbArray: Array[0..254] of TCheckBox;
  lbArray: Array[0..254] of TLabel;
  arForms: Array[0..254] of TStringList;
  slPlugins, slDictionary: TStringList;
  plugin: IInterface;
  oldIndex: integer;
  oldNotes: string;
  btnClose: TButton;
  frm: TForm;
  done: boolean;

//=========================================================================
// GetDefinitionHint: Generates a hint based on the definition
function GetDefinitionHint(sl: TStringList): string;
var
  notes: String;
begin
  if sl.Count < 6 then
    Result := 'No user reports for this plugin have been submitted.'
  else begin
    notes := Trim(StringReplace(sl[5], '@13', #13, [rfReplaceAll]));
    Result := 'Average rating: '+sl[3]+#13+'Number of ratings: '+sl[4]+#13+'User notes: '+#13+notes;
  end;
end;
  
//=========================================================================
// GetMergeColor: gets the color associated with the file's merge rating
function GetMergeColor(sl: TStringList): integer;
var
  rating, k1, k2: float;
  c1, c2, c3, fc: TColor;
begin
  if sl.Count < 2 then
    Result := $404040
  else begin
    c1.Red := $FF; c1.Green := $00; c1.Blue := $00;
    c2.Red := $E5; c2.Green := $A8; c2.Blue := $00;
    c3.Red := $00; c3.Green := $90; c3.Blue := $00;
    fc.Blue := $00;
    rating := StrToFloat(sl[3]);
    if (rating > 2.0) then begin
      k2 := (rating - 2.0)/2.0;
      k1 := 1.0 - k2;
      fc.Red := c2.Red * k1 + c3.Red * k2;
      fc.Green := c2.Green * k1 + c3.Green * k2;
    end
    else begin
      k2 := (rating/2.0);
      k1 := 1.0 - k2;
      fc.Red := c1.Red * k1 + c2.Red * k2;
      fc.Green := c1.Green * k1 + c2.Green * k2;
    end;
    Result := ColorToInt(fc.Red, fc.Green, fc.Blue);
  end;
end;

//=========================================================================
// GetDefinition: gets a definition for the file from the dictionary
function GetDefinition(fn: string): string;
var
  i: integer;
  search: string;
begin
  Result := '';
  search := fn + ';';
  for i := 0 to Pred(slDictionary.Count) do begin
    if Pos(search, slDictionary[i]) = 1 then begin
      Result := slDictionary[i];
      break;
    end;
  end;
end;

//=========================================================================
procedure rfrm.SubmitReport(Sender: TObject);
var
  slReport: TStringList;
  s: String;
  p: TObject;
begin
  if MessageDlg('Are you sure you want to submit this report?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    exit
  else begin
    p := Sender.Parent;
    AddMessage('Submitting '+ p.Caption);
    slReport := TStringList.Create;
    oldIndex := p.Components[5].ItemIndex;
    oldNotes := p.Components[8].Lines.Text;
    s := p.Components[1].Text + ';' + p.Components[3].Text + ';' + IntToStr(p.Components[5].ItemIndex) 
    + ';' + p.Components[7].Text + ';' + StringReplace(p.Components[8].Lines.Text, ';', ',', [rfReplaceAll]);
    slReport.Add(s);
    AddMessage('  '+s+#13#10);
    slReport.SaveToFile(ProgramPath + 'Edit Scripts\mp\Report-'+Copy(p.Caption, 15, Length(p.Caption) - 14)+'.txt');
    slReport.Free;
  end;
end;

//=========================================================================
procedure rfrm.EnableSubmit(Sender: TObject);
var
  p: TObject;
begin
  p := Sender.Parent;
  
  // update characters remaining label
  p.Components[9].Text := IntToStr(notesmax - Length(p.Components[8].Lines.Text)) + ' characters remaining';
  p.Components[9].Left := p.Width - p.Components[9].Width - 45;
  if (Length(p.Components[8].Lines.Text) > notesmax) then
    p.Components[9].Font.Color := clRed
  else
    p.Components[9].Font.Color := clDefault;
    
  // enable/disable submit button
  if (p.Components[5].Text <> '') and (p.Components[7].Text <> '?') and (p.Components[8].Lines[0] <> 'Notes') 
  and (Length(p.Components[8].Lines.Text) < notesmax) then
    p.Components[10].Enabled := true
  else
    p.Components[10].Enabled := false;
end;

//=========================================================================
procedure MakeReport(fn: string; fc: Integer);
var
  rfrm: TForm;
  btnSubmit, btnCancel: TButton;
  lbl01, lbl02, lbl03, lbl04, lbl05: TLabel;
  ed01, ed02, ed03: TEdit;
  cb01: TComboBox;
  mm01: TMemo;
  s: String;
begin
  rfrm := TForm.Create(nil);
  try
    rfrm.Caption := 'Merge Report: '+fn;
    rfrm.Width := 415;
    rfrm.Height := 400;
    rfrm.Position := poScreenCenter;
    
    lbl01 := TLabel.Create(rfrm);
    lbl01.Parent := rfrm;
    lbl01.Text := 'Filename: ';
    lbl01.Width := 100;
    lbl01.Left := 20;
    lbl01.Top := 20;
    
    ed01 := TEdit.Create(rfrm);
    ed01.Parent := rfrm;
    ed01.Left := lbl01.Left + lbl01.Width + 8;
    ed01.Top := lbl01.Top;
    ed01.Width := 200;
    ed01.Text := fn;
    ed01.Enabled := false;
    
    lbl02 := TLabel.Create(rfrm);
    lbl02.Parent := rfrm;
    lbl02.Text := 'Number of Records: ';
    lbl02.Width := 100;
    lbl02.Left := lbl01.Left;;
    lbl02.Top := lbl01.Top + 25;
    
    ed02 := TEdit.Create(rfrm);
    ed02.Parent := rfrm;
    ed02.Left := lbl02.Left + lbl02.Width + 8;
    ed02.Top := lbl02.Top;
    ed02.Width := 200;
    ed02.Text := IntToStr(fc);
    ed02.Enabled := false;
    
    lbl03 := TLabel.Create(rfrm);
    lbl03.Parent := rfrm;
    lbl03.Text := 'Rating: ';
    lbl03.Width := 100;
    lbl03.Left := lbl01.Left;
    lbl03.Top := lbl02.Top + 25;
    
    cb01 := TCombobox.Create(rfrm);
    cb01.Parent := rfrm;
    cb01.Style := csDropDownList;
    cb01.Left := lbl03.Left + lbl03.Width + 8;
    cb01.Top := lbl03.Top;
    cb01.Width := 200;
    cb01.Items.Text := 'Cannot be merged'#13'Merges with errors'#13'Merges but CTDs ingame'#13'Merges, no CTDs'#13'Merges perfectly';
    if (oldIndex > -1) then
      cb01.ItemIndex := oldIndex;
    cb01.OnChange := EnableSubmit;
    
    lbl04 := TLabel.Create(rfrm);
    lbl04.Parent := rfrm;
    lbl04.Text := 'Merge Version: ';
    lbl04.Width := 100;
    lbl04.Left := lbl01.Left;
    lbl04.Top := lbl03.Top + 25;
    
    ed03 := TEdit.Create(rfrm);
    ed03.Parent := rfrm;
    ed03.Left := lbl04.Left + lbl04.Width + 8;
    ed03.Top := lbl04.Top;
    ed03.Width := 200;
    s := geev(ElementByIndex(plugin, 0), 'CNAM');
    if (Pos('Merge Plugins Script', s) = 1) then begin
      ed03.Text := Copy(s, 23, Length(s));
      ed03.Enabled := False;
    end
    else begin
      ed03.Text := '?';
      ed03.OnChange := EnableSubmit;
    end;
    
    mm01 := TMemo.Create(rfrm);
    mm01.Parent := rfrm;
    mm01.Left := lbl01.Left;
    mm01.Top := lbl04.Top + 35;
    mm01.Width := 350;
    mm01.Height := 150;
    mm01.Lines.Text := oldNotes;
    mm01.OnChange := EnableSubmit;
    
    lbl05 := TLabel.Create(rfrm);
    lbl05.Parent := rfrm;
    lbl05.Text := '';
    lbl05.Autosize := True;
    lbl05.Left := rfrm.Width - lbl05.Width - 45;
    lbl05.Top := lbl04.Top + 190;
    
    btnSubmit := TButton.Create(rfrm);
    btnSubmit.Parent := rfrm;
    btnSubmit.ModalResult := mrOk;
    btnSubmit.OnClick := SubmitReport;
    btnSubmit.Caption := 'Submit';
    btnSubmit.Left := (rfrm.Width div 2) - btnSubmit.Width - 8;
    btnSubmit.Top := rfrm.Height - 80;
    btnSubmit.Enabled := false;
    
    btnCancel := TButton.Create(rfrm);
    btnCancel.Parent := rfrm;
    btnCancel.ShowHint := true;
    btnCancel.Hint := 'You must fill in all enabled fields before you can submit a report.';
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := btnSubmit.Left + btnSubmit.Width + 16;
    btnCancel.Top := btnSubmit.top;
    
    EnableSubmit(mm01);
    if btnSubmit.Enabled then
      rfrm.ActiveControl := btnSubmit
    else
      rfrm.ActiveControl := btnCancel;
    if rfrm.ShowModal = mrOk then begin
      ;
    end;
  finally
    rfrm.Free;
  end;
end;

//=========================================================================
procedure frm.Report(Sender: TObject);
var
  x, i: integer;
  s, fn: string;
  group, forms: IInterface;
  mp: boolean;
begin
  mp := Pos('Merged Plugin', geev(ElementByIndex(plugin, 0), 'SNAM')) = 1;
  for x := 0 to slPlugins.Count - 1 do begin
    if (cbArray[x].Checked = True) then begin
      s := Trim(slPlugins[x]);
      fn := Copy(s, 0, Length(s) - 4);
      // find formlist
      if mp then begin
        group := GroupBySignature(plugin, 'FLST');
        for i := 0 to ElementCount(group) - 1 do begin
          if geev(ElementByIndex(group, i), 'EDID') = fn+'Forms' then
            forms := ElementByIndex(group, i);
        end;
        forms := ElementByPath(forms, 'FormIDs');
        if ElementCount(forms) > 0 then
          MakeReport(s, ElementCount(forms));
      end
      else
        MakeReport(s, RecordCount(FileByName(s)));
    end;
  end;
  frm.ActiveControl := btnClose;
end;

//=========================================================================
function NotDuplicateForm(form: string; x: integer): boolean;
var
  i: integer;
begin
  Result := true;
  for i := 0 to slPlugins.Count - 1 do begin
    if i = x then Continue;
    if arForms[x].IndexOf(form) > -1 then begin
      Result := false;
      break;
    end;
  end;
end;

//=========================================================================
procedure RemoveForms(flst: IInterface; x: integer);
var
  forms, rec, e: IInterface;
begin
  AddMessage('Removing FormIDs associated with: '+geev(flst, 'EDID'));
  forms := ElementByPath(flst, 'FormIDs');
  while ElementCount(forms) > 0 do begin
    e := ElementByIndex(forms, 0);
    rec := LinksTo(e);
    AddMessage('  removing '+SmallName(rec));
    Remove(e);
    if Assigned(rec) and smartremove then begin
      if NotDuplicateForm(GetEditValue(e), x) then RemoveNode(rec);
    end else if Assigned(rec) then
      RemoveNode(rec);
  end;
  RemoveNode(flst);
end;

//=========================================================================
procedure RemoveEmptyGroups;
var
  i: integer;
  group: IInterface;
begin
  for i := ElementCount(plugin) - 1 downto 1 do begin
    group := ElementByIndex(plugin, i);
    if ElementCount(group) = 0 then
      RemoveNode(group);
  end;
end;

//=========================================================================
procedure frm.RemovePlugin(Sender: TObject);
var
  m, i: integer;
  fn, desc: String;
  group: IInterface;
begin
  for m := 0 to slPlugins.Count - 1 do begin
    if (cbArray[m].Checked = True) then begin
      // string operations
      fn := Trim(slPlugins[m]);
      fn := Copy(fn, 0, Length(fn) - 4);
      // remove forms
      group := GroupBySignature(plugin, 'FLST');
      for i := 0 to ElementCount(group) - 1 do begin
        if geev(ElementByIndex(group, i), 'EDID') = fn+'Forms' then
          RemoveForms(ElementByIndex(group, i), m);
      end;
      // fix description
      desc := geev(ElementByIndex(plugin, 0), 'SNAM');
      desc := StringReplace(desc, slPlugins[m] + #13#10, '', [rfReplaceAll]);
      seev(ElementByIndex(plugin, 0), 'SNAM', desc);
    end;
  end;
  // remove empty groups
  RemoveEmptyGroups;
end;

//=========================================================================
// MainForm: Provides user with merged plugin managing
procedure MainForm(mp: boolean);
var
  btnReport, btnRemove: TButton;
  lbl1, lbl2: TLabel;
  pnl: TPanel;
  sb: TScrollBox;
  i, j, k, height, m: integer;
  holder: TObject;
  s, fn: string;
  slDefinition, sl: TStringList;
  forms, e, group: IInterface;
begin
  if mp then begin
    s := geev(ElementByIndex(plugin, 0), 'SNAM');
    slPlugins.Text := s;
    slPlugins.Delete(0);
    
    // create arForms stringlists
    for i := 0 to slPlugins.Count - 1 do begin
      fn := Trim(slPlugins[i]);
      fn := Copy(fn, 0, Length(fn) - 4);
      group := GroupBySignature(plugin, 'FLST');
      for j := 0 to ElementCount(group) - 1 do begin
        e := ElementByIndex(group, j);
        if geev(e, 'EDID') = fn+'Forms' then begin
          arForms[i] := TStringList.Create;
          forms := ElementByPath(e, 'FormIDs');
          for k := 0 to ElementCount(forms) - 1 do
            arForms[i].Add(GetEditValue(ElementByIndex(forms, k)));
        end;
      end;
    end;
  end;
  
  j := 0;
  k := 0;
  frm := TForm.Create(nil);
  try
    frm.Caption := 'Merged Plugin Manager';
    frm.Width := 415;
    frm.Position := poScreenCenter;
    height := slPlugins.Count*25 + 135;
    if height > (Screen.Height - 100) then begin
      frm.Height := Screen.Height - 100;
      sb := TScrollBox.Create(frm);
      sb.Parent := frm;
      sb.Height := Screen.Height - 290;
      sb.Align := alTop;
      holder := sb;
    end
    else begin
      frm.Height := height;
      holder := frm;
    end;

    lbl1 := TLabel.Create(holder);
    lbl1.Parent := holder;
    lbl1.Top := 8;
    lbl1.Left := 8;
    lbl1.AutoSize := False;
    lbl1.Wordwrap := True;
    lbl1.Width := 300;
    lbl1.Height := 50;
    lbl1.Caption := 'Select the plugins you want to manage.';
    
    // create file list
    for i := 0 to slPlugins.Count - 1 do begin
      s := Trim(slPlugins[i]);
      j := 25 * k;
      Inc(k);
      
      // load definition
      slDefinition := TStringList.Create;
      slDefinition.StrictDelimiter := true;
      slDefinition.Delimiter := ';';
      slDefinition.DelimitedText := GetDefinition(s);
      
      // set up checkbox
      cbArray[i] := TCheckBox.Create(holder);
      cbArray[i].Parent := holder;
      cbArray[i].Left := 24;
      cbArray[i].Top := 40 + j;
      cbArray[i].Width := 350;
      cbArray[i].ShowHint := true;
      cbArray[i].Hint := GetDefinitionHint(slDefinition);
      
      // set up label
      lbArray[i] := TLabel.Create(holder);
      lbArray[i].Parent := holder;
      lbArray[i].Left := 44;
      lbArray[i].Top := cbArray[i].Top;
      lbArray[i].Caption := '  [' + IntToHex(i + 1, 2) + ']  ' + s;
      lbArray[i].Font.Color := GetMergeColor(slDefinition);
      if slDefinition.Count > 5 then
        lbArray[i].Font.Style := lbArray[i].Font.Style + [fsbold];
      
      // free definition
      slDefinition.Free;
    end;
    
    if holder = sb then begin
      lbl2 := TLabel.Create(holder);
      lbl2.Parent := holder;
      lbl2.Top := j + 60;
    end;
    
    pnl := TPanel.Create(frm);
    pnl.Parent := frm;
    pnl.BevelOuter := bvNone;
    pnl.Align := alBottom;
    pnl.Height := 60;
    
    btnReport := TButton.Create(frm);
    btnReport.Parent := pnl;
    btnReport.OnClick := Report;
    btnReport.Caption := 'Report';
    btnReport.Left := 70;
    btnReport.Top := pnl.Height - 40;
    
    btnRemove := TButton.Create(frm);
    btnRemove.Parent := pnl;
    btnRemove.Caption := 'Remove';
    btnRemove.Left := btnReport.Left + btnReport.Width + 16;
    btnRemove.Top := btnReport.Top;
    btnRemove.Enabled := false;
    if mp then begin 
      btnRemove.OnClick := RemovePlugin;
      btnRemove.Enabled := true;
    end;
    
    btnClose := TButton.Create(frm);
    btnClose.Parent := pnl;
    btnClose.Caption := 'Close';
    btnClose.ModalResult := mrOk;
    btnClose.Left := btnRemove.Left + btnRemove.Width + 16;
    btnClose.Top := btnReport.Top;
    
    frm.ActiveControl := btnClose;
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

//=========================================================================
function Initialize: integer;
begin
  // welcome messages
  AddMessage(#13#10#13#10);
  AddMessage('-----------------------------------------------------------------------------');
  AddMessage('Merged plugin manager '+vs+': Used for managing merged files.');
  AddMessage('-----------------------------------------------------------------------------');
  
  // initialize vars
  oldIndex := -1;
  oldNotes := 'Notes'+#13;
  slPlugins := TStringList.Create;
  slDictionary := TStringList.Create;
  slDictionary.LoadFromFile(ScriptsPath + '\mp\dictionary.txt');
  
  ScriptProcessElements := [etFile];
end;

//=========================================================================
function Process(e: IInterface): integer;
var
  desc: string;
begin
  desc := geev(ElementByIndex(e, 0), 'SNAM');
  
  if Pos('Merged Plugin', desc) <> 1 then begin
    slPlugins.Add(GetFileName(e));
    exit;
  end;
    
  // create main form for merged plugin
  plugin := e;
  AddMessage('Managing: '+GetFileName(e));
  MainForm(true);
  done := true;
  AddMessage('');
end;

//==========================================================================
function Finalize: integer;
begin
  if not done then 
    MainForm(false);
  AddMessage('');
  AddMessage('-----------------------------------------------------------------------------');
  AddMessage('Finished managing merged plugins.');
  AddMessage(#13#10);
end;

end.
