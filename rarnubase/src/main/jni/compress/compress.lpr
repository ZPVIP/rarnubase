{.$DEFINE DEBUG}

{$IFDEF DEBUG}
program hjcompress;
{$ELSE}
library hjcompress;
{$ENDIF}

{$mode objfpc}{$H+}

uses
  {$IFNDEF WINDOWS}
  cthreads,
  {$ENDIF}
  JNI2,
  Classes,
  sysutils,
  strutils,
  hjunt_error,
  hjunt_status,
  hjunt_files,
  hjunt_zip,
  hjunt_tar,
  hjunt_gz,
  hjunt_bz2,
  hjunt_hjz,
  hjunt_targz,
  hjunt_tarbz;

const
  ZIP_FORMAT: array[0..11] of string = (
    '.hjz',   // 0
    '.hjp',   //
    '.zip',   // 1
    '.bz2',   // 2
    '.jar',   // 3
    '.tar',   // 4
    '.gz',    // 5
    '.gzip',   // 6
    '.tgz',   // 7
    '.tbz',   // 8
    '.tar.gz', // 9
    '.tar.bz2' // 10
    );

function extractFileRealExt(AFileName: string): string;
var
  i: Integer;
begin
  AFileName:= LowerCase(AFileName);
  for i:= 0 to Length(ZIP_FORMAT) - 1 do begin
    if AnsiEndsText(ZIP_FORMAT[i], AFileName) then begin
       Result := ZIP_FORMAT[i];
    end;
  end;
end;

// filePath: zip file to uncompress
// destPath: folder to save uncompressed files
// return:
//        -1: unsupported file format
//        -2: uncompress error
//        >=0: uncompressed file count
function _uncompress(filePath: PChar; dest: PChar): Integer;
var
  strPath: string;
  strDest: string;
  ext: string;
  errCode: Integer = 0;
  errMsg: string = '';
begin
  strPath:= string(filePath);
  strDest:= string(dest);
  ext := extractFileRealExt(strPath);
  WriteLn(Format('file format => %s', [ext]));
  errCode:= ERROR_FORMAT_NOT_SUPPORT;
  errMsg:= ERRMSG_FORMAT_NOT_SUPPORT;
  if (ext = '.zip') or (ext = '.jar') or (ext = '.hjp') then begin
    errCode := DoUnzip(strPath, strDest);
  // end else if (ext = '.bz2') then begin
  //   errCode := DoUnbz2(strPath, strDest);
  end else if (ext = '.tar') then begin
    errCode := DoUntar(strPath, strDest);
  end else if (ext = '.tgz') or (ext = '.tar.gz') then begin
    errCode := DoUnTarGz(strPath, strDest);
  end else if (ext = '.gz') or (ext = '.gzip') then begin
    errCode := DoUnGz(strPath, strDest);
  // end else if (ext = '.tbz') or (ext = '.tar.bz2') then begin
  //   errCode := DoUnTarBz(strPath, strDest);
  end else if (ext = '.hjz') then begin
    errCode := DoUnhjz(strPath, strDest);
  end;
  if (errCode = ERROR_FORMAT_NOT_SUPPORT) then begin
    AddCompressStatus(string(filePath), 0, 0, errCode, errMsg);
  end;
  Result := errCode;
end;

function _compress(filePath: PChar; src: PChar): Integer;
var
  strPath: string;
  strSrc: string;
  ext: string;
  errCode: Integer = 0;
  errMsg: string = '';
begin
  strPath := string(filePath);
  strSrc := string(src);
  ext := extractFileRealExt(strPath);
  errCode:= ERROR_FORMAT_NOT_SUPPORT;
  errMsg:= ERRMSG_FORMAT_NOT_SUPPORT;
  if (ext = '.zip') or (ext = '.jar') or (ext = '.hjp') then begin
    errCode := DoZip(strPath, strSrc);
  //end else if (ext = '.bz2') then begin
  //  errCode := DoBz2(strPath, strSrc);
  end else if (ext = '.tar') then begin
    errCode := DoTar(strPath, strSrc);
  end else if (ext = '.tgz') or (ext = '.tar.gz') then begin
    errCode := DoTarGz(strPath, strSrc);
  end else if (ext = '.gz') or (ext = '.gzip') then begin
    errCode := DoGz(strPath, strSrc);
  // end else if (ext = '.tbz') or (ext = '.tar.bz2') then begin
  //  errCode := DoTarBz(strPath, strSrc);
  end else if (ext = '.hjz') then begin
    errCode := DoHjz(strPath, strSrc);
  end;
  if (errCode = ERROR_FORMAT_NOT_SUPPORT) then begin
    AddUncompressStatus(string(filePath), 0, 0, errCode, errMsg);
  end;
  Result := errCode;
end;

function uncompress(filePath: PChar; dest: PChar): Integer; cdecl;
begin
  Result := _uncompress(filePath, dest);
end;

function compress(filePath: PChar; src: PChar): Integer; cdecl;
begin
  Result := _compress(filePath, src);
end;

// Java_com_rarnu_base_utils_ZipUtils

function Java_com_rarnu_base_utils_ZipUtils_uncompress(env: PJNIEnv; obj:jobject; filePath: jstring; dest: jstring): jint; stdcall;
var
  strFilePath: string;
  strDest: string;
begin
  strFilePath:= TJNIEnv.jstringToString(env, filePath);
  strDest:= TJNIEnv.jstringToString(env, dest);
  Result := _uncompress(PChar(strFilePath), PChar(strDest));
end;

function Java_com_rarnu_base_utils_ZipUtils_compress(env: PJNIEnv; obj: jobject; filePath: jstring; src: jstring): jint; stdcall;
var
  strFilePath: string;
  strSrc: string;
begin
  strFilePath:= TJNIEnv.jstringToString(env, filePath);
  strSrc:= TJNIEnv.jstringToString(env, src);
  Result := _compress(PChar(strFilePath), PChar(strSrc));
end;

function _getFileSize(path: PChar): PChar;
var
  pathStr: string;
  fs: TFileStream;
  ret: string;
begin
  pathStr:= string(path);
  ret := '0';
  if FileExists(pathStr) and (not DirectoryExists(pathStr)) then
  begin
    with TFileStream.Create(pathStr, fmOpenRead and fmShareDenyWrite) do begin
      ret := IntToStr(Size);
      Free;
    end;
  end;
  Result := StrAlloc(Length(ret));
  strcopy(Result, PChar(ret));
end;

function getFileSize(path: PChar): PChar; cdecl;
begin
  Result := _getFileSize(path);
end;

function Java_com_rarnu_base_utils_ZipUtils_getFileSize(env: PJNIEnv; obj: jobject; path: jstring): jstring; stdcall;
var
  pathStr: string;
  clsFile: jclass;
  initFile: jmethodID;
  objFile: jobject;
  mLength: jmethodID;
  size: Int64;
  ret: string;
begin
  pathStr:= TJNIEnv.jstringToString(env, path);

  clsFile:= env^^.FindClass(env, 'java/io/File');
  initFile:= env^^.GetMethodID(env, clsFile, '<init>', '(Ljava/lang/String;)V');
  objFile:= env^^.NewObjectA(env, clsFile, initFile, TJNIEnv.argsToJValues(env, [pathStr]));
  mLength:= env^^.GetMethodID(env, clsFile, 'length', '()J');

  size := Int64(env^^.CallLongMethodA(env, objFile, mLength, nil));
  ret := IntToStr(size);
  Result := TJNIEnv.stringToJString(env, ret);
  env^^.DeleteLocalRef(env, obj);
  env^^.DeleteLocalRef(env, clsFile);
end;

exports
  uncompress,
  compress,
  getFileSize,
  getCompressErrorCode,
  getCompressErrorMessage,
  getCompressFileCount,
  getCompressedCount,
  getUncompressErrorCode,
  getUncompressErrorMessage,
  getUncompressFileCount,
  getUncompressedCount,
  Java_com_rarnu_base_utils_ZipUtils_uncompress,
  Java_com_rarnu_base_utils_ZipUtils_compress,
  Java_com_rarnu_base_utils_ZipUtils_getFileSize,
  Java_com_rarnu_base_utils_ZipUtils_getCompressErrorCode,
  Java_com_rarnu_base_utils_ZipUtils_getCompressErrorMessage,
  Java_com_rarnu_base_utils_ZipUtils_getCompressFileCount,
  Java_com_rarnu_base_utils_ZipUtils_getCompressedCount,
  Java_com_rarnu_base_utils_ZipUtils_getUncompressErrorCode,
  Java_com_rarnu_base_utils_ZipUtils_getUncompressErrorMessage,
  Java_com_rarnu_base_utils_ZipUtils_getUncompressFileCount,
  Java_com_rarnu_base_utils_ZipUtils_getUncompressedCount;

{$IFDEF DEBUG}
var
  pCount: Integer;
  funType: string;
  ret: Integer;
  retStr: PChar;
  p1: string;
  p2: string;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  pCount:= ParamCount;
  funType:= ParamStr(1);
  p1 := ParamStr(2);
  p2 := ParamStr(3);
  if (funType = '-c') then begin
    ret := _compress(PChar(p1), PChar(p2));
    WriteLn(Format('Compress %s to %s => %d', [p2, p1, ret]));
  end else if (funType = '-d') then begin
    ret := _uncompress(PChar(p1), PChar(p2));
    WriteLn(Format('Decompress %s to %s => %d', [p1, p2, ret]));
  end else if (funType = '-s') then begin
    retStr:= _getFileSize(PChar(p1));
    WriteLn(Format('File Size => %s', [string(retStr)]));
  end;
  {$ENDIF}

end.

