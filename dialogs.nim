#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "LICENSE", included in this
#    distribution, for details about the copyright.
#


## This module implements portable dialogs for Nim; the implementation
## builds on the GTK interface. On Windows, native dialogs are shown instead.

when defined(Windows):
  import winlean, private/winaux, os

  type PWindow = pointer
elif defined(macosx):
  import glib2, gtk2
  {.passL: "-framework AppKit".}

  type
    NSSavePanel {.importobjc: "NSSavePanel*", header: "<AppKit/AppKit.h>",
        incompleteStruct.} = object
    NSOpenPanel {.importobjc: "NSOpenPanel*", header: "<AppKit/AppKit.h>",
        incompleteStruct.} = object

  proc newOpenPanel: NSOpenPanel {.importobjc: "NSOpenPanel openPanel", nodecl.}
  proc newSavePanel: NSSavePanel {.importobjc: "NSSavePanel savePanel", nodecl.}
else:
  import glib2, gtk2

proc info*(window: PWindow, msg: string) =
  ## Shows an information message to the user. The process waits until the
  ## user presses the OK button.
  when defined(Windows):
    discard messageBoxA(0, msg, "Information", MB_OK or MB_ICONINFORMATION)
  else:
    var dialog = message_dialog_new(window,
                DIALOG_MODAL or DIALOG_DESTROY_WITH_PARENT,
                MESSAGE_INFO, BUTTONS_OK, "%s", cstring(msg))
    setTitle(dialog, "Information")
    discard run(dialog)
    destroy(PWidget(dialog))

proc warning*(window: PWindow, msg: string) =
  ## Shows a warning message to the user. The process waits until the user
  ## presses the OK button.
  when defined(Windows):
    discard messageBoxA(0, msg, "Warning", MB_OK or MB_ICONWARNING)
  else:
    var dialog = DIALOG(message_dialog_new(window,
                DIALOG_MODAL or DIALOG_DESTROY_WITH_PARENT,
                MESSAGE_WARNING, BUTTONS_OK, "%s", cstring(msg)))
    setTitle(dialog, "Warning")
    discard run(dialog)
    destroy(PWidget(dialog))

proc error*(window: PWindow, msg: string) =
  ## Shows an error message to the user. The process waits until the user
  ## presses the OK button.
  when defined(Windows):
    discard messageBoxA(0, msg, "Error", MB_OK or MB_ICONERROR)
  else:
    var dialog = DIALOG(message_dialog_new(window,
                DIALOG_MODAL or DIALOG_DESTROY_WITH_PARENT,
                MESSAGE_ERROR, BUTTONS_OK, "%s", cstring(msg)))
    setTitle(dialog, "Error")
    discard run(dialog)
    destroy(PWidget(dialog))


proc chooseFileToOpen*(window: PWindow, root: string = ""): string =
  ## Opens a dialog that requests a filename from the user. Returns ""
  ## if the user closed the dialog without selecting a file. On Windows,
  ## the native dialog is used, else the GTK dialog is used.
  when defined(Windows):
    var
      opf: TOPENFILENAME
      buf: array[0..2047, char]
    opf.lStructSize = sizeof(opf).int32
    if root.len > 0:
      opf.lpstrInitialDir = root
    opf.lpstrFilter = "All Files\0*.*\0\0"
    opf.flags = OFN_FILEMUSTEXIST
    opf.lpstrFile = addr buf
    opf.nMaxFile = sizeof(buf).int32
    var res = getOpenFileName(addr(opf))
    if res != 0:
      result = $(addr buf)
    else:
      result = ""
  elif defined(macosx):
    {.emit: "NSAutoreleasePool* pool = [NSAutoreleasePool new];".}
    let dialog = newOpenPanel()
    let ctitle : cstring = "Open File"
    var cres: cstring

    {.emit: """
    [`dialog` setCanChooseFiles:YES];
    `dialog`.title = [NSString stringWithUTF8String: `ctitle`];
    if ([`dialog` runModal] == NSOKButton && `dialog`.URLs.count > 0) {
      `cres` = [`dialog`.URLs objectAtIndex: 0].path.UTF8String;
    }
    """.}
    if not cres.isNil:
      result = $cres
    else:
      result = ""
    {.emit: "[pool drain];".}
  else:
    var chooser = file_chooser_dialog_new("Open File", window,
                FILE_CHOOSER_ACTION_OPEN,
                STOCK_CANCEL, RESPONSE_CANCEL,
                STOCK_OPEN, RESPONSE_OK, nil)
    if root.len > 0:
      discard set_current_folder(chooser, root)
    if run(chooser) == cint(RESPONSE_OK):
      var x = get_filename(chooser)
      result = $x
      g_free(x)
    else:
      result = ""
    destroy(PWidget(chooser))

proc chooseFilesToOpen*(window: PWindow, root: string = ""): seq[string] =
  ## Opens a dialog that requests filenames from the user. Returns ``@[]``
  ## if the user closed the dialog without selecting a file. On Windows,
  ## the native dialog is used, else the GTK dialog is used.
  when defined(Windows):
    var
      opf: TOPENFILENAME
      buf: array[0..2047*4, char]
    opf.lStructSize = sizeof(opf).int32
    if root.len > 0:
      opf.lpstrInitialDir = root
    opf.lpstrFilter = "All Files\0*.*\0\0"
    opf.flags = OFN_FILEMUSTEXIST or OFN_ALLOWMULTISELECT or OFN_EXPLORER
    opf.lpstrFile = addr buf
    opf.nMaxFile = sizeof(buf).int32
    var res = getOpenFileName(addr(opf))
    result = @[]
    if res != 0:
      # parsing the result is horrible:
      var
        i = 0
        s: string
        path = ""
      while buf[i] != '\0':
        add(path, buf[i])
        inc(i)
      inc(i)
      if buf[i] != '\0':
        while true:
          s = ""
          while buf[i] != '\0':
            add(s, buf[i])
            inc(i)
          add(result, s)
          inc(i)
          if buf[i] == '\0': break
        for i in 0..result.len-1: result[i] = os.joinPath(path, result[i])
      else:
        # only one file selected --> gosh, what an ugly thing
        # the windows API is
        add(result, path)
  elif defined(macosx):
    {.emit: "NSAutoreleasePool* pool = [NSAutoreleasePool new];".}
    let dialog = newOpenPanel()
    let ctitle : cstring = "Open File"
    var cres: array[100, cstring]
    var count = 0

    {.emit: """
    [`dialog` setCanChooseFiles:YES];
    [`dialog` setAllowsMultipleSelection:YES];
    `dialog`.title = [NSString stringWithUTF8String: `ctitle`];
    if ([`dialog` runModal] == NSOKButton && `dialog`.URLs.count > 0) {
      `count` = `dialog`.URLs.count;
      if (`count` > 100) {
        `count` = 100;
      }
      for (int i = 0; i < `count`; i++) {
        `cres`[i] = [`dialog`.URLs objectAtIndex: i].path.UTF8String;
      }
    }
    """.}
    result = @[]
    for i in 0 .. <count:
      result.add($cres[i])
    {.emit: "[pool drain];".}
  else:
    var chooser = file_chooser_dialog_new("Open Files", window,
                FILE_CHOOSER_ACTION_OPEN,
                STOCK_CANCEL, RESPONSE_CANCEL,
                STOCK_OPEN, RESPONSE_OK, nil)
    if root.len > 0:
      discard set_current_folder(chooser, root)
    set_select_multiple(chooser, true)
    result = @[]
    if run(chooser) == cint(RESPONSE_OK):
      var L = get_filenames(chooser)
      var it = L
      while it != nil:
        add(result, $cast[cstring](it.data))
        g_free(it.data)
        it = it.next
      free(L)
    destroy(PWidget(chooser))


proc chooseFileToSave*(window: PWindow, root: string = ""): string =
  ## Opens a dialog that requests a filename to save to from the user.
  ## Returns "" if the user closed the dialog without selecting a file.
  ## On Windows, the native dialog is used, else the GTK dialog is used.
  when defined(Windows):
    var
      opf: TOPENFILENAME
      buf: array[0..2047, char]
    opf.lStructSize = sizeof(opf).int32
    if root.len > 0:
      opf.lpstrInitialDir = root
    opf.lpstrFilter = "All Files\0*.*\0\0"
    opf.flags = OFN_OVERWRITEPROMPT
    opf.lpstrFile = addr buf
    opf.nMaxFile = sizeof(buf).int32
    var res = getSaveFileName(addr(opf))
    if res != 0:
      result = $(addr buf)
    else:
      result = ""
  elif defined(macosx):
    {.emit: "NSAutoreleasePool* pool = [NSAutoreleasePool new];".}
    let dialog = newSavePanel()
    let ctitle : cstring = "Save File"
    var cres: cstring

    {.emit: """
    `dialog`.canCreateDirectories = YES;
    `dialog`.title = [NSString stringWithUTF8String: `ctitle`];
    if ([`dialog` runModal] == NSOKButton) {
      `cres` = `dialog`.URL.path.UTF8String;
    }
    """.}
    if not cres.isNil:
      result = $cres
    else:
      result = ""
    {.emit: "[pool drain];".}
  else:
    var chooser = file_chooser_dialog_new("Save File", window,
                FILE_CHOOSER_ACTION_SAVE,
                STOCK_CANCEL, RESPONSE_CANCEL,
                STOCK_SAVE, RESPONSE_OK, nil)
    if root.len > 0:
      discard set_current_folder(chooser, root)
    set_do_overwrite_confirmation(chooser, true)
    if run(chooser) == cint(RESPONSE_OK):
      var x = get_filename(chooser)
      result = $x
      g_free(x)
    else:
      result = ""
    destroy(PWidget(chooser))


proc chooseDir*(window: PWindow, root: string = ""): string =
  ## Opens a dialog that requests a directory from the user.
  ## Returns "" if the user closed the dialog without selecting a directory.
  ## On Windows, the native dialog is used, else the GTK dialog is used.
  when defined(Windows):
    var
      lpItemID: PItemIDList
      browseInfo: BrowseInfo
      displayName: array[0..MAX_PATH, char]
      tempPath: array[0..MAX_PATH, char]
    result = ""
    #BrowseInfo.hwndOwner = Application.Handle
    browseInfo.pszDisplayName = addr displayName
    browseInfo.ulFlags = 1 #BIF_RETURNONLYFSDIRS
    lpItemID = shBrowseForFolder(addr(browseInfo))
    if lpItemId != nil:
      discard shGetPathFromIDList(lpItemID, addr tempPath)
      result = $(addr tempPath)
      discard globalFreePtr(lpItemID)
  else:
    var chooser = file_chooser_dialog_new("Select Directory", window,
                FILE_CHOOSER_ACTION_SELECT_FOLDER,
                STOCK_CANCEL, RESPONSE_CANCEL,
                STOCK_OPEN, RESPONSE_OK, nil)
    if root.len > 0:
      discard set_current_folder(chooser, root)
    if run(chooser) == cint(RESPONSE_OK):
      var x = get_filename(chooser)
      result = $x
      g_free(x)
    else:
      result = ""
    destroy(PWidget(chooser))

