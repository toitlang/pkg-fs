// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import fs
import fs.posix
import fs.windows
import system

POSIX-TESTS ::= {
  "": "",
  "foo": "foo",
  "/": "",
  "/foo/bar": "bar",
  "foo/bar": "bar",
  "foo/bar/": "bar",
  "foo/..": "..",
}

WINDOWS-TESTS ::= {
  "": "",
  "foo": "foo",
  "/": "",
  "/foo/bar.exe": "bar.exe",
  "foo/bar": "bar",
  "//host/share/": "",
  "//host/share/foo": "foo",
  "c:/": "",
  "foo/..": "..",
}

main:
  POSIX-TESTS.do: | path expected |
    actual := posix.basename path
    expect-equals expected actual
  WINDOWS-TESTS.do: | path expected |
    actual := windows.basename path
    expect-equals expected actual

    path = windows.from-slash path
    actual = windows.basename path
    expect-equals expected actual

  local-tests := system.platform == system.PLATFORM-WINDOWS ? WINDOWS-TESTS : POSIX-TESTS
  local-tests.do: | path expected |
    actual := fs.basename path
    expect-equals expected actual
