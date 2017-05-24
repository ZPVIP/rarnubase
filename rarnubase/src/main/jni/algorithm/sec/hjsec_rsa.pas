unit hjsec_rsa;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, hjlockbox, JNI2;

// keysize:  (aks128 = 0, aks256 = 1, aks512 = 2, aks768 = 3, aks1024 = 4)
// return Integer: succ = 0, other = error code
function rsaGenerateKeys(keySize: Integer; pubPass: PChar; privPass: PChar; pubSavePath: PChar; privSavePath: PChar): Integer; cdecl;
function rsaEncryptString(keySize: Integer; pubPass: PChar; pubPath: PChar; str: PChar): PChar; cdecl;
function rsaEncryptFile(keySize: Integer; pubPass: PChar; pubPath: PChar; filePath: PChar; outFilePath: PChar): Integer; cdecl;
function rsaDecryptString(keySize: Integer; privPass: PChar; privPath: PChar; str: PChar): PChar; cdecl;
function rsaDecryptFile(keySize: Integer; privPass: PChar; privPath: PChar; filePath: PChar; outFilePath: PChar): Integer; cdecl;
function rsaGetPubkeyModules(keySize: Integer; pubPass: PChar; pubPath: PChar): PChar; cdecl;
function rsaGetPrivkeyModules(keySize: Integer; privPass: PChar; privPath: PChar): PChar; cdecl;
function Java_com_rarnu_base_security_AlgorithmUtils_rsaGenerateKeys(env: PJNIEnv; obj: jobject; keySize: jint; pubPass: jstring; privPass: jstring; pubSavePath: jstring; privSavePath: jstring): jint; stdcall;
function Java_com_rarnu_base_security_AlgorithmUtils_rsaEncryptString(env: PJNIEnv; obj: jobject; keySize: jint; pubPass: jstring; pubPath: jstring; str: jstring): jstring; stdcall;
function Java_com_rarnu_base_security_AlgorithmUtils_rsaEncryptFile(env: PJNIEnv; obj: jobject; keySize: jint; pubPass: jstring; pubPath: jstring; filePath: jstring; outFilePath: jstring): jint; stdcall;
function Java_com_rarnu_base_security_AlgorithmUtils_rsaDecryptString(env: PJNIEnv; obj: jobject; keySize: jint; privPass: jstring; privPath: jstring; str: jstring): jstring; stdcall;
function Java_com_rarnu_base_security_AlgorithmUtils_rsaDecryptFile(env: PJNIEnv; obj: jobject; keySize: jint; privPass: jstring; privPath: jstring; filePath: jstring; outFilePath: jstring): jint; stdcall;
function Java_com_rarnu_base_security_AlgorithmUtils_rsaGetPubkeyModules(env: PJNIEnv; obj: jobject; keySize: jint; pubPass: jstring; pubPath: jstring): jstring; stdcall;
function Java_com_rarnu_base_security_AlgorithmUtils_rsaGetPrivkeyModules(env: PJNIEnv; obj: jobject; keySize: jint; privPass: jstring; privPath: jstring): jstring; stdcall;

implementation

function _rsaGenerateKeys(keySize: Integer; pubPass: PChar; privPass: PChar;
  pubSavePath: PChar; privSavePath: PChar): Integer;
var
  rsa: TLbRSA;
begin
  Result := -1;
  rsa := TLbRSA.Create(nil);
  try
    rsa.PrimeTestIterations := 20;
    rsa.KeySize:= TLbAsymKeySize(keySize);
    rsa.GenerateKeyPair;
    rsa.PublicKey.Passphrase:= String(pubPass);
    rsa.PublicKey.StoreToFile(string(pubSavePath));
    rsa.PrivateKey.Passphrase:= String(privPass);
    rsa.PrivateKey.StoreToFile(string(privSavePath));
    Result := 0;
  finally
    rsa.Free;
  end;
end;

function _rsaEncryptString(keySize: Integer; pubPass: PChar; pubPath: PChar;
  str: PChar): PChar;
var
  rsa: TLbRSA;
  ret: String = '';
begin
  try
    rsa := TLbRSA.Create(nil);
    try
      rsa.PrimeTestIterations:= 20;
      rsa.KeySize:= TLbAsymKeySize(keySize);
      rsa.PublicKey.Passphrase:= string(pubPass);
      rsa.PublicKey.LoadFromFile(string(pubPath));
      ret := rsa.EncryptString(string(str));
    finally
      rsa.Free;
    end;
    Result := StrAlloc(Length(ret));
    strcopy(Result, PChar(ret));
  except
    Result := '';
  end;
end;

function _rsaEncryptFile(keySize: Integer; pubPass: PChar; pubPath: PChar;
  filePath: PChar; outFilePath: PChar): Integer;
var
  rsa: TLbRSA;
begin
  Result := -1;
  try
    rsa := TLbRSA.Create(nil);
    try
      rsa.PrimeTestIterations:= 20;
      rsa.KeySize:= TLbAsymKeySize(keySize);
      rsa.PublicKey.Passphrase:= string(pubPass);
      rsa.PublicKey.LoadFromFile(string(pubPath));
      rsa.EncryptFile(string(filePath), string(outFilePath));
      Result := 0;
    finally
      rsa.Free;
    end;
  except
  end;
end;

function _rsaDecryptString(keySize: Integer; privPass: PChar; privPath: PChar;
  str: PChar): PChar;
var
  rsa: TLbRSA;
  ret: String = '';
begin
  try
    rsa := TLbRSA.Create(nil);
    try
      rsa.PrimeTestIterations:= 20;
      rsa.KeySize:= TLbAsymKeySize(keySize);
      rsa.PrivateKey.Passphrase:= string(privPass);
      rsa.PrivateKey.LoadFromFile(string(privPath));
      ret := rsa.DecryptString(string(str));
    finally
      rsa.Free;
    end;
    Result := StrAlloc(Length(ret));
    strcopy(Result, PChar(ret));
  except
    Result := '';
  end;
end;

function _rsaDecryptFile(keySize: Integer; privPass: PChar; privPath: PChar;
  filePath: PChar; outFilePath: PChar): Integer;
var
  rsa: TLbRSA;
begin
  Result := -1;
  try
    rsa := TLbRSA.Create(nil);
    try
      rsa.PrimeTestIterations:= 20;
      rsa.KeySize:= TLbAsymKeySize(keySize);
      rsa.PrivateKey.Passphrase:= string(privPass);
      rsa.PrivateKey.LoadFromFile(string(privPath));
      rsa.DecryptFile(string(filePath), string(outFilePath));
      Result := 0;
    finally
      rsa.Free;
    end;
  except
  end;
end;

function _rsaGetPubkeyModules(keySize: Integer; pubPass: PChar; pubPath: PChar
  ): PChar;
var
  rsa: TLbRSA;
  ret: string = '';
begin
  try
    rsa := TLbRSA.Create(nil);
    try
      rsa.PrimeTestIterations:= 20;
      rsa.KeySize:= TLbAsymKeySize(keySize);
      rsa.PublicKey.Passphrase:= string(pubPass);
      rsa.PublicKey.LoadFromFile(string(pubPath));
      ret := rsa.PublicKey.ModulusAsString;
    finally
      rsa.Free;
    end;
    Result := StrAlloc(Length(ret));
    strcopy(Result, PChar(ret));
  except
    Result := '';
  end;
end;

function _rsaGetPrivkeyModules(keySize: Integer; privPass: PChar;
  privPath: PChar): PChar;
var
  rsa: TLbRSA;
  ret: string = '';
begin
  try
    rsa := TLbRSA.Create(nil);
    try
      rsa.PrimeTestIterations:= 20;
      rsa.KeySize:= TLbAsymKeySize(keySize);
      rsa.PrivateKey.Passphrase:= string(privPass);
      rsa.PrivateKey.LoadFromFile(string(privPath));
      ret := rsa.PrivateKey.ModulusAsString;
    finally
      rsa.Free;
    end;
    Result := StrAlloc(Length(ret));
    strcopy(Result, PChar(ret));
  except
    Result := '';
  end;
end;

function rsaGenerateKeys(keySize: Integer; pubPass: PChar; privPass: PChar;
  pubSavePath: PChar; privSavePath: PChar): Integer; cdecl;
begin
  Result := _rsaGenerateKeys(keySize, pubPass, privPass, pubSavePath, privSavePath);
end;

function rsaEncryptString(keySize: Integer; pubPass: PChar; pubPath: PChar;
  str: PChar): PChar; cdecl;
begin
  Result := _rsaEncryptString(keySize, pubPass, pubPath, str);
end;

function rsaEncryptFile(keySize: Integer; pubPass: PChar; pubPath: PChar;
  filePath: PChar; outFilePath: PChar): Integer; cdecl;
begin
  Result := _rsaEncryptFile(keySize, pubPass, pubPath, filePath, outFilePath);
end;

function rsaDecryptString(keySize: Integer; privPass: PChar; privPath: PChar;
  str: PChar): PChar; cdecl;
begin
  Result := _rsaDecryptString(keySize, privPass, privPath, str);
end;

function rsaDecryptFile(keySize: Integer; privPass: PChar; privPath: PChar;
  filePath: PChar; outFilePath: PChar): Integer; cdecl;
begin
  Result := _rsaDecryptFile(keySize, privPass, privPath, filePath, outFilePath);
end;

function rsaGetPubkeyModules(keySize: Integer; pubPass: PChar; pubPath: PChar
  ): PChar; cdecl;
begin
  Result := _rsaGetPubkeyModules(keySize, pubPass, pubPath);
end;

function rsaGetPrivkeyModules(keySize: Integer; privPass: PChar; privPath: PChar
  ): PChar; cdecl;
begin
  Result := _rsaGetPrivkeyModules(keySize, privPass, privPath);
end;

function Java_com_rarnu_base_security_AlgorithmUtils_rsaGenerateKeys(
  env: PJNIEnv; obj: jobject; keySize: jint; pubPass: jstring;
  privPass: jstring; pubSavePath: jstring; privSavePath: jstring): jint;
  stdcall;
begin
  Result := _rsaGenerateKeys(keySize, PChar(TJNIEnv.JStringToString(env, pubPass)), PChar(TJNIEnv.JStringToString(env, privPass)), PChar(TJNIEnv.JStringToString(env, pubSavePath)), PChar(TJNIEnv.JStringToString(env, privSavePath)));
end;

function Java_com_rarnu_base_security_AlgorithmUtils_rsaEncryptString(
  env: PJNIEnv; obj: jobject; keySize: jint; pubPass: jstring;
  pubPath: jstring; str: jstring): jstring; stdcall;
var
  ret: PChar;
begin
  ret := _rsaEncryptString(keySize, PChar(TJNIEnv.JStringToString(env, pubPass)), PChar(TJNIEnv.JStringToString(env, pubPath)), PChar(TJNIEnv.JStringToString(env, str)));
  Result := TJNIEnv.StringToJString(env, string(ret));
end;

function Java_com_rarnu_base_security_AlgorithmUtils_rsaEncryptFile(
  env: PJNIEnv; obj: jobject; keySize: jint; pubPass: jstring;
  pubPath: jstring; filePath: jstring; outFilePath: jstring): jint; stdcall;
begin
  Result := _rsaEncryptFile(keySize, PChar(TJNIEnv.JStringToString(env, pubPass)), PChar(TJNIEnv.JStringToString(env, pubPath)), PChar(TJNIEnv.JStringToString(env, filePath)), PChar(TJNIEnv.JStringToString(env, outFilePath)));
end;

function Java_com_rarnu_base_security_AlgorithmUtils_rsaDecryptString(
  env: PJNIEnv; obj: jobject; keySize: jint; privPass: jstring;
  privPath: jstring; str: jstring): jstring; stdcall;
var
  ret: PChar;
begin
  ret := _rsaDecryptString(keySize, PChar(TJNIEnv.JStringToString(env, privPass)), PChar(TJNIEnv.JStringToString(env, privPath)), PChar(TJNIEnv.JStringToString(env, str)));
  Result := TJNIEnv.StringToJString(env, string(ret));
end;

function Java_com_rarnu_base_security_AlgorithmUtils_rsaDecryptFile(
  env: PJNIEnv; obj: jobject; keySize: jint; privPass: jstring;
  privPath: jstring; filePath: jstring; outFilePath: jstring): jint; stdcall;
begin
  Result := _rsaDecryptFile(keySize, PChar(TJNIEnv.JStringToString(env, privPass)), PChar(TJNIEnv.JStringToString(env, privPath)), PChar(TJNIEnv.JStringToString(env, filePath)), PChar(TJNIEnv.JStringToString(env, outFilePath)));
end;

function Java_com_rarnu_base_security_AlgorithmUtils_rsaGetPubkeyModules(
  env: PJNIEnv; obj: jobject; keySize: jint; pubPass: jstring; pubPath: jstring
  ): jstring; stdcall;
var
  ret: PChar;
begin
  ret := _rsaGetPubkeyModules(keySize, PChar(TJNIEnv.JStringToString(env, pubPass)), PChar(TJNIEnv.JStringToString(env, pubPath)));
  Result := TJNIEnv.stringToJString(env, string(ret));
end;

function Java_com_rarnu_base_security_AlgorithmUtils_rsaGetPrivkeyModules(
  env: PJNIEnv; obj: jobject; keySize: jint; privPass: jstring;
  privPath: jstring): jstring; stdcall;
var
  ret: PChar;
begin
  ret := _rsaGetPrivkeyModules(keySize, PChar(TJNIEnv.JStringToString(env, privPass)), PChar(TJNIEnv.JStringToString(env, privPath)));
  Result := TJNIEnv.StringToJString(env, string(ret));
end;

end.

