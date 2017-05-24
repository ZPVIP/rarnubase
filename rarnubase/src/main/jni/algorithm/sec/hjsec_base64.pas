unit hjsec_base64;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, JNI2, base64;

function base64EncryptString(str: PChar): PChar; cdecl;
function base64DecryptString(str: Pchar): PChar; cdecl;
function Java_com_rarnu_base_security_AlgorithmUtils_base64EncryptString(env: PJNIEnv; obj: jobject; str: jstring): jstring; stdcall;
function Java_com_rarnu_base_security_AlgorithmUtils_base64DecryptString(env: PJNIEnv; obj: jobject; str: jstring): jstring; stdcall;

implementation

function _base64EncryptString(str: PChar): PChar;
var
  ret: string;
begin
  try
    ret := EncodeStringBase64(string(str));
    Result := StrAlloc(Length(ret));
    strcopy(Result, PChar(ret));
  except
    Result := '';
  end;
end;

function _base64DecryptString(str: Pchar): PChar;
var
  ret: string;
begin
  try
    ret := DecodeStringBase64(string(str));
    Result := StrAlloc(Length(ret));
    strcopy(Result, PChar(ret));
  except
    Result := '';
  end;
end;

function base64EncryptString(str: PChar): PChar; cdecl;
begin
  Result := _base64EncryptString(str);
end;

function base64DecryptString(str: Pchar): PChar; cdecl;
begin
  Result := _base64DecryptString(str);
end;

function Java_com_rarnu_base_security_AlgorithmUtils_base64EncryptString(
  env: PJNIEnv; obj: jobject; str: jstring): jstring; stdcall;
var
  ret: PChar;
begin
  ret := _base64EncryptString(PChar(TJNIEnv.JStringToString(env, str)));
  Result := TJNIEnv.StringToJString(env, string(ret));
end;

function Java_com_rarnu_base_security_AlgorithmUtils_base64DecryptString(
  env: PJNIEnv; obj: jobject; str: jstring): jstring; stdcall;
var
  ret: PChar;
  rs: string;
  rs2: string;
  i: Integer;
begin
  ret := _base64DecryptString(PChar(TJNIEnv.JStringToString(env, str)));
  rs := string(ret);
  rs2 := UTF8Encode(UTF8Decode(rs));
  if rs = rs2 then begin
    Result := TJNIEnv.StringToJString(env, string(ret));
  end else begin
    ret := '';
    Result := TJNIEnv.StringToJString(env, string(ret));
  end;
end;

end.

