// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import fs
import fs.posix
import fs.windows
import system

POSIX-TESTS ::= {
  "": ".",
  ".": ".",
  "/.": "/",
  "/foo": "/",
  "x/": ".",
  "abc": ".",
  "abc/def": "abc",
  "a/b/.x": "a/b",
  "a/b/c.": "a/b",
  "a/b/c.x": "a/b",
  "/a/b/c/": "/a/b",
  "/a/b/c////": "/a/b",
  "/////": "/",
}

WINDOWS-TESTS ::= {
  "c:\\": "c:\\",
  "c:.": "c:.",
  "c:": "c:.",
  "c:\\a\\b": "c:\\a",
  "c:a\\b": "c:a",
  "c:a\\b\\c": "c:a\\b",
  "\\\\host\\share": "\\\\host\\share",
  "\\\\host\\share\\": "\\\\host\\share\\",
  "\\\\host\\share\\a": "\\\\host\\share\\",
  "\\\\host\\share\\a\\b": "\\\\host\\share\\a",
  "\\\\\\\\": "\\",
  "/": "\\",
  "": ".",
  "foo": ".",
  "/foo/bar": "\\foo",
  "foo/bar": "foo",
  "c:/foo": "c:\\",
  "c:/foo/bar": "c:\\foo",
  "//host/share/": "\\\\host\\share\\",
  "//host/share/foo": "\\\\host\\share\\",
  "c:///foo/bar": "c:\\foo", // Test that fails in Go.
}

main:
  POSIX-TESTS.do: | path expected |
    actual := posix.dirname path
    expect-equals expected actual
  WINDOWS-TESTS.do: | path expected |
    actual := windows.dirname path
    expect-equals expected actual
  local-tests := system.platform == system.PLATFORM-WINDOWS ? WINDOWS-TESTS : POSIX-TESTS
  local-tests.do: | path expected |
    actual := fs.dirname path
    expect-equals expected actual
