// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import fs
import fs.posix
import fs.windows
import system

POSIX-TESTS ::= {
  "": false,
  "/": true,
  "/usr/bin/gcc": true,
  "..": false,
  "/a/../bb": true,
  ".": false,
  "./": false,
  "lala": false,
}

WINDOWS-TESTS ::= {
  "": false,
  "c": false,
  "cc": false,
  "C:\\": true,
  "c\\": false,
  "c::": false,
  "c:": false,
  "/": false,
  "\\": false,
  "\\Windows": false,
  "c:a\\b": false,
  "c:\\a\\b": true,
  "c:/a/b": true,
  "\\\\host\\share": true,
  "\\\\host\\share\\": true,
  "\\\\host\\share\\foo": true,
  "//host/share/foo/bar": true,
  "\\\\?\\a\\b\\c": true,
  "\\??\\a\\b\\c": true,
  "æ:\\": false,
  "🙈:\\": false,
  "\\\\?\\z:": true,
}

main:
  POSIX-TESTS.do: | path expected |
    actual := posix.is-absolute path
    expect-equals expected actual
  WINDOWS-TESTS.do: | path expected |
    actual := windows.is-absolute path
    expect-equals expected actual
  local-tests := system.platform == system.PLATFORM-WINDOWS ? WINDOWS-TESTS : POSIX-TESTS
  local-tests.do: | path expected |
    actual := fs.is-absolute path
    expect-equals expected actual
