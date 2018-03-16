

## Some stuff that used to be in Windows.nim.

import winlean

const
  MB_USERICON* = 0x00000080
  MB_ICONASTERISK* = 0x00000040
  MB_ICONEXCLAMATION* = 0x00000030
  MB_ICONWARNING* = 0x00000030
  MB_ICONERROR* = 0x00000010
  MB_ICONHAND* = 0x00000010
  MB_ICONQUESTION* = 0x00000020
  MB_OK* = 0
  MB_ABORTRETRYIGNORE* = 0x00000002
  MB_APPLMODAL* = 0
  MB_DEFAULT_DESKTOP_ONLY* = 0x00020000
  MB_HELP* = 0x00004000
  MB_RIGHT* = 0x00080000
  MB_RTLREADING* = 0x00100000
  MB_TOPMOST* = 0x00040000
  MB_DEFBUTTON1* = 0
  MB_DEFBUTTON2* = 0x00000100
  MB_DEFBUTTON3* = 0x00000200
  MB_DEFBUTTON4* = 0x00000300
  MB_ICONINFORMATION* = 0x00000040
  MB_ICONSTOP* = 0x00000010
  MB_OKCANCEL* = 0x00000001
  MB_RETRYCANCEL* = 0x00000005
  MB_SERVICE_NOTIFICATION* = 0x00040000
  MB_SETFOREGROUND* = 0x00010000
  MB_SYSTEMMODAL* = 0x00001000
  MB_TASKMODAL* = 0x00002000
  MB_YESNO* = 0x00000004
  MB_YESNOCANCEL* = 0x00000003

  OFN_ALLOWMULTISELECT* = 0x00000200
  OFN_CREATEPROMPT* = 0x00002000
  OFN_ENABLEHOOK* = 0x00000020
  OFN_ENABLETEMPLATE* = 0x00000040
  OFN_ENABLETEMPLATEHANDLE* = 0x00000080
  OFN_EXPLORER* = 0x00080000
  OFN_EXTENSIONDIFFERENT* = 0x00000400
  OFN_FILEMUSTEXIST* = 0x00001000
  OFN_HIDEREADONLY* = 0x00000004
  OFN_LONGNAMES* = 0x00200000
  OFN_NOCHANGEDIR* = 0x00000008
  OFN_NODEREFERENCELINKS* = 0x00100000
  OFN_NOLONGNAMES* = 0x00040000
  OFN_NONETWORKBUTTON* = 0x00020000
  OFN_NOREADONLYRETURN* = 0x00008000
  OFN_NOTESTFILECREATE* = 0x00010000
  OFN_NOVALIDATE* = 0x00000100
  OFN_OVERWRITEPROMPT* = 0x00000002
  OFN_PATHMUSTEXIST* = 0x00000800
  OFN_READONLY* = 0x00000001
  OFN_SHAREAWARE* = 0x00004000
  OFN_SHOWHELP* = 0x00000010

type
  HGLOBAL* = HANDLE
  HLOCAL* = HANDLE
  HWND* = HANDLE
  HINST* = HANDLE

  TOPENFILENAME* = object
    lStructSize*: DWORD
    hwndOwner*: HWND
    hInstance*: HINST
    lpstrFilter*: cstring
    lpstrCustomFilter*: cstring
    nMaxCustFilter*: DWORD
    nFilterIndex*: DWORD
    lpstrFile*: cstring
    nMaxFile*: DWORD
    lpstrFileTitle*: cstring
    nMaxFileTitle*: DWORD
    lpstrInitialDir*: cstring
    lpstrTitle*: cstring
    flags*: DWORD
    nFileOffset*: int16
    nFileExtension*: int16
    lpstrDefExt*: cstring
    lCustData*: ByteAddress
    lpfnHook*: pointer
    lpTemplateName*: cstring
    pvReserved*: pointer
    dwreserved*: DWORD
    FlagsEx*: DWORD

  SHITEMID* = object
    cb*: uint16
    abID*: array[0..0, int8]

  LPSHITEMID* = ptr SHITEMID
  LPCSHITEMID* = ptr SHITEMID
  TSHITEMID* = SHITEMID
  PSHITEMID* = ptr SHITEMID
  ITEMIDLIST* = object
    mkid*: SHITEMID

  LPITEMIDLIST* = ptr ITEMIDLIST
  LPCITEMIDLIST* = ptr ITEMIDLIST
  TITEMIDLIST* = ITEMIDLIST
  PITEMIDLIST* = ptr ITEMIDLIST
  BROWSEINFO* = object
    hwndOwner*: HWND
    pidlRoot*: LPCITEMIDLIST
    pszDisplayName*: cstring
    lpszTitle*: cstring
    ulFlags*: int32
    lpfn*: pointer
    lParam*: ByteAddress
    iImage*: int32


proc messageBoxA*(wnd: Handle, lpText, lpCaption: cstring, uType: int): int32{.
    stdcall, dynlib: "user32", importc: "MessageBoxA".}

proc getOpenFileName*(para1: ptr TOPENFILENAME): WINBOOL{.stdcall,
    dynlib: "comdlg32", importc: "GetOpenFileNameA".}

proc getSaveFileName*(para1: ptr TOPENFILENAME): WINBOOL{.stdcall,
    dynlib: "comdlg32", importc: "GetSaveFileNameA".}


proc globalLock*(hMem: HGLOBAL): pointer{.stdcall, dynlib: "kernel32",
    importc: "GlobalLock".}
proc globalHandle*(pMem: pointer): HGLOBAL{.stdcall, dynlib: "kernel32",
    importc: "GlobalHandle".}
proc globalUnlock*(hMem: HGLOBAL): WINBOOL{.stdcall, dynlib: "kernel32",
    importc: "GlobalUnlock".}
proc globalFree*(hMem: HGLOBAL): HGLOBAL{.stdcall, dynlib: "kernel32",
    importc: "GlobalFree".}

proc globalUnlockPtr(lp: pointer): pointer =
  discard globalUnlock(globalHandle(lp))
  result = lp

proc globalFreePtr*(lp: pointer): pointer =
  result = cast[pointer](globalFree(cast[HWND](globalUnlockPtr(lp))))

proc shBrowseForFolder*(para1: ptr BROWSEINFO): LPITEMIDLIST{.stdcall,
    dynlib: "shell32", importc: "SHBrowseForFolder".}

proc shGetPathFromIDList*(para1: LPCITEMIDLIST, para2: cstring): WINBOOL{.
    stdcall, dynlib: "shell32", importc: "SHGetPathFromIDList".}
