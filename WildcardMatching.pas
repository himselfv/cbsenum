unit WildcardMatching;

interface

function WildcardMatchCase(a, w: PChar): boolean;

implementation

function WildcardMatchCase(a, w: PChar): boolean;
label new_segment, test_match;
var i: integer;
  star: boolean;
begin
new_segment:
  star := false;
  if w^='*' then begin
    star := true;
    repeat Inc(w) until w^ <> '*';
  end;

test_match:
  i := 0;
  while (w[i]<>#00) and (w[i]<>'*') do
    if a[i] <> w[i] then begin
      if a[i]=#00 then begin
        Result := false;
        exit;
      end;
      if (w[i]='?') and (a[i] <> '.') then begin
        Inc(i);
        continue;
      end;
      if not star then begin
        Result := false;
        exit;
      end;
      Inc(a);
      goto test_match;
    end else
      Inc(i);

  if w[i]='*' then begin
    Inc(a, i);
    Inc(w, i);
    goto new_segment;
  end;

  if a[i]=#00 then begin
    Result := true;
    exit;
  end;

  if (i > 0) and (w[i-1]='*') then begin
    Result := true;
    exit;
  end;

  if not star then begin
    Result := false;
    exit;
  end;

  Inc(a);
  goto test_match;
end;

end.
