// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import fs
import fs.posix
import fs.windows
import system

POSIX-TESTS ::= [
  [[], ""],
  [["/"], "/"],
  [["a"], "a"],
  [["a", "b"], "a/b"],
  [["/", "a"], "/a"],
  [["/", "a", "b"], "/a/b"],
  [["/", "a", "b"], "/a////b"],
  [["/"], "/"],
  [["/", "a"], "//a"],
]

WINDOWS-TESTS ::= [
  [["\\", "foo"], "\\foo"],
  [[], ""],
  [["\\"], "/"],
  [["a"], "a"],
  [["a", "b"], "a\\b"],
  [["\\", "a"], "\\a"],
  [["\\", "a", "b"], "\\a\\b"],
  [["directory", "file"], "directory\\file"],
  [["C:","\\", "Windows", "System32"], "C:\\Windows\\System32"],
  [["C:","\\", "Windows"], "C:\\Windows"],
  [["C:", "a"], "C:a"],
  [["C:", "a", "b"], "C:a\\b"],
  [["C:","\\", "a"], "C:\\a"],
  [["\\\\host\\share", "foo"], "\\\\host\\share\\foo"],
  [["\\\\host\\share", "foo", "bar"], "\\\\host\\share\\foo\\bar"],
  [["\\"], "\\"],
  [["\\\\a"], "\\\\a"],
]

main:
  POSIX-TESTS.do: | test/List |
    path := test[1]
    expected := test[0]
    actual := posix.split path
    expect-list-equals expected actual
  WINDOWS-TESTS.do: | test/List |
    path := test[1]
    expected := test[0]
    actual := windows.split path
    expect-equals expected actual
    if path != "":
      expect-equals (windows.clean path) (windows.join actual)
