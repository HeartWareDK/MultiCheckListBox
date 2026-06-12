unit HWMultiCheckListBox;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  HeartWare.MultiCheckListBox;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('HeartWare', [THWMultiCheckListBox]);
end;

end.
