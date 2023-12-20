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
  [[""], ""],
  [["/"], "/"],
  [["a"], "a"],
  [["a", "b"], "a/b"],
  [["a", ""], "a"],
  [["", "b"], "b"],
  [["/", "a"], "/a"],
  [["/", "a/b"], "/a/b"],
  [["/", ""], "/"],
  [["/a", "b"], "/a/b"],
  [["a", "/b"], "a/b"],
  [["/a", "/b"], "/a/b"],
  [["a/", "b"], "a/b"],
  [["a/", ""], "a"],
  [["", ""], ""],
  [["/", "a", "b"], "/a/b"],
  [["//", "a"], "/a"],
]

WINDOWS-TESTS ::= [
  [["/", "/", "foo"], "\\foo"],
  [[], ""],
  [[""], ""],
  [["/"], "\\"],
  [["a"], "a"],
  [["a", "b"], "a\\b"],
  [["a", ""], "a"],
  [["", "b"], "b"],
  [["/", "a"], "\\a"],
  [["/", "a/b"], "\\a\\b"],
  [["/", ""], "\\"],
  [["/a", "b"], "\\a\\b"],
  [["a", "/b"], "a\\b"],
  [["/a", "/b"], "\\a\\b"],
  [["a/", "b"], "a\\b"],
  [["a/", ""], "a"],
  [["", ""], ""],
  [["/", "a", "b"], "\\a\\b"],
  [["directory", "file"], "directory\\file"],
  [["C:\\Windows\\", "System32"], "C:\\Windows\\System32"],
  [["C:\\Windows\\", ""], "C:\\Windows"],
  [["C:\\", "Windows"], "C:\\Windows"],
  [["C:", "a"], "C:a"],
  [["C:", "a\\b"], "C:a\\b"],
  [["C:", "a", "b"], "C:a\\b"],
  [["C:", "", "b"], "C:b"],
  [["C:", "", "", "b"], "C:b"],
  [["C:", ""], "C:."],
  [["C:", "", ""], "C:."],
  [["C:", "\\a"], "C:\\a"],
  [["C:", "", "\\a"], "C:\\a"],
  [["C:.", "a"], "C:a"],
  [["C:a", "b"], "C:a\\b"],
  [["C:a", "b", "d"], "C:a\\b\\d"],
  [["\\\\host\\share", "foo"], "\\\\host\\share\\foo"],
  [["\\\\host\\share\\foo"], "\\\\host\\share\\foo"],
  [["//host/share", "foo/bar"], "\\\\host\\share\\foo\\bar"],
  [["\\"], "\\"],
  [["\\", ""], "\\"],
  [["\\", "a"], "\\a"],
  [["\\\\", "a"], "\\\\a"],
  [["\\", "a", "b"], "\\a\\b"],
  [["\\\\", "a", "b"], "\\\\a\\b"],
  [["\\", "\\\\a\\b", "c"], "\\a\\b\\c"],
  [["\\\\a", "b", "c"], "\\\\a\\b\\c"],
  [["\\\\a\\", "b", "c"], "\\\\a\\b\\c"],
  [["//", "a"], "\\\\a"],
  [["a:\\b\\c", "x\\..\\y:\\..\\..\\z"], "a:\\b\\z"],
  [["\\", "??\\a"], "\\.\\??\\a"],
]

main:
  POSIX-TESTS.do: | test/List |
    elements := test[0]
    expected:= test[1]
    actual := posix.join elements
    expect-equals expected actual
  WINDOWS-TESTS.do: | test/List |
    elements := test[0]
    expected:= test[1]
    actual := windows.join elements
    expect-equals expected actual
  local-tests := system.platform == system.PLATFORM-WINDOWS ? WINDOWS-TESTS : POSIX-TESTS
  local-tests.do: | test/List |
    elements := test[0]
    expected:= test[1]
    actual := fs.join elements
    expect-equals expected actual
