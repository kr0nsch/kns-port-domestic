// Адаптеры — те же экземпляры, что разбирают регистры чтения в PRG_FieldIn
PRG_FieldIn.fbVfdP101.Encode(xQReset := GVL_IO.xP101_VfdQReset, rSpeedRef_pct := GVL_IO.rP101_SpeedRef_pct);
GVL_IO.wP101_CTW := PRG_FieldIn.fbVfdP101.wCtw;
GVL_IO.uiP101_FREF := PRG_FieldIn.fbVfdP101.uiFref;

PRG_FieldIn.fbVfdP102.Encode(xQReset := GVL_IO.xP102_VfdQReset, rSpeedRef_pct := GVL_IO.rP102_SpeedRef_pct);
GVL_IO.wP102_CTW := PRG_FieldIn.fbVfdP102.wCtw;
GVL_IO.uiP102_FREF := PRG_FieldIn.fbVfdP102.uiFref;

PRG_FieldIn.fbVfdP103.Encode(xQReset := GVL_IO.xP103_VfdQReset, rSpeedRef_pct := GVL_IO.rP103_SpeedRef_pct);
GVL_IO.wP103_CTW := PRG_FieldIn.fbVfdP103.wCtw;
GVL_IO.uiP103_FREF := PRG_FieldIn.fbVfdP103.uiFref;
