// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import fs
import fs.posix
import fs.windows
import system

GO-POSIX-TESTS ::= {
  "abc": "abc",
  "abc/def": "abc/def",
  "a/b/c": "a/b/c",
  ".": ".",
  "..": "..",
  "../..": "../..",
  "../../abc": "../../abc",
  "/abc": "/abc",
  "/": "/",

  // Empty is current dir.
  "": ".",

  // Remove trailing slash.
  "abc/": "abc",
  "abc/def/": "abc/def",
  "a/b/c/": "a/b/c",
  "./": ".",
  "../": "..",
  "../../": "../..",
  "/abc/": "/abc",

  // Remove doubled slash.
  "abc//def//ghi": "abc/def/ghi",
  "abc//": "abc",

  // Remove . elements.
  "abc/./def": "abc/def",
  "/./abc/def": "/abc/def",
  "abc/.": "abc",

  // Remove .. elements.
  "abc/def/ghi/../jkl": "abc/def/jkl",
  "abc/def/../ghi/../jkl": "abc/jkl",
  "abc/def/..": "abc",
  "abc/def/../..": ".",
  "/abc/def/../..": "/",
  "abc/def/../../..": "..",
  "/abc/def/../../..": "/",
  "abc/def/../../../ghi/jkl/../../../mno": "../../mno",
  "/../abc": "/abc",
  "a/../b:/../../c": "../c",

  // Combinations.
  "abc/./../def": "def",
  "abc//./../def": "def",
  "abc/../../././../def": "../../def",

  // Remove leading doubled slash.
  "//abc": "/abc",
  "///abc": "/abc",
  "//abc//": "/abc",
}

POSIX-TESTS ::= {
  "foo": "foo",
  ".": ".",
  "/": "/",
  "./foo": "foo",
  "../foo": "../foo",
  "foo/./bar": "foo/bar",
  "foo/////bar": "foo/bar",
  "///foo": "/foo",
  "foo/../bar/gee": "bar/gee",
}

GO-WINDOWS-TESTS ::= {
  "c:": "c:.",
  "c:\\": "c:\\",
  "c:\\abc": "c:\\abc",
  "c:abc\\..\\..\\.\\.\\..\\def": "c:..\\..\\def",
  "c:\\abc\\def\\..\\..": "c:\\",
  "c:\\..\\abc": "c:\\abc",
  "c:..\\abc": "c:..\\abc",
  "c:\\b:\\..\\..\\..\\d": "c:\\d",
  "\\": "\\",
  "/": "\\",
  "\\\\i\\..\\c\$": "\\\\i\\..\\c\$",
  "\\\\i\\..\\i\\c\$": "\\\\i\\..\\i\\c\$",
  "\\\\i\\..\\I\\c\$": "\\\\i\\..\\I\\c\$",
  "\\\\host\\share\\foo\\..\\bar": "\\\\host\\share\\bar",
  "//host/share/foo/../baz": "\\\\host\\share\\baz",
  "\\\\host\\share\\foo\\..\\..\\..\\..\\bar": "\\\\host\\share\\bar",
  "\\\\.\\C:\\a\\..\\..\\..\\..\\bar": "\\\\.\\C:\\bar",
  "\\\\.\\C:\\\\\\\\a": "\\\\.\\C:\\a",
  "\\\\a\\b\\..\\c": "\\\\a\\b\\c",
  "\\\\a\\b": "\\\\a\\b",
  ".\\c:": ".\\c:",
  ".\\c:\\foo": ".\\c:\\foo",
  ".\\c:foo": ".\\c:foo",
  "//abc": "\\\\abc",
  "///abc": "\\abc",  // Modified from original test. We  don't allow empty hosts.
  "//abc//": "\\\\abc\\\\",
  "\\\\?\\C:\\": "\\\\?\\C:\\",
  "\\\\?\\C:\\a": "\\\\?\\C:\\a",

  // Don't allow cleaning to move an element with a colon to the start of the path.
  "a\\..\\c:": ".\\c:",
  "a\\..\\c:": ".\\c:",
  "a\\..\\c:\\a": ".\\c:\\a",
  "a\\..\\..\\c:": "..\\c:",
  "foo:bar": ".\\foo:bar",  // Modified from original test. We always add ./ to the path if it has a colon.

  // Don't allow cleaning to create a Root Local Device path like \\??\\a.
  "/a/..\\??\\a": "\\.\\??\\a",
}

WINDOWS-TESTS ::= {
  "foo": "foo",
  "foo/": "foo",
  ".": ".",
  "./": ".",
  "/": "\\",
  "//": "\\",
  "./foo": "foo",
  "./foo/": "foo",
  "../foo": "..\\foo",
  "../foo/": "..\\foo",
  "foo/./bar": "foo\\bar",
  "foo/./bar/": "foo\\bar",
  "foo/////bar": "foo\\bar",
  "foo/////bar/": "foo\\bar",
  "foo/../bar/gee": "bar\\gee",
  "foo/../bar/gee/": "bar\\gee",
  "\\": "\\",
  "\\\\": "\\",
  ".\\foo": "foo",
  ".\\foo\\": "foo",
  "..\\foo": "..\\foo",
  "..\\foo\\": "..\\foo",
  "foo\\.\\bar": "foo\\bar",
  "foo\\.\\bar\\": "foo\\bar",
  "foo\\\\\\\\bar": "foo\\bar",
  "foo\\\\\\\\bar\\": "foo\\bar",
  "\\foo": "\\foo",
  "\\foo\\": "\\foo",
  "foo\\..\\bar/gee": "bar\\gee",
  "foo\\..\\bar/gee\\": "bar\\gee",
  "c:foo": "c:foo",
  "c:foo\\": "c:foo",
  "c:../foo": "c:..\\foo",
  "c:../foo\\": "c:..\\foo",
  "c:\\foo/bar": "c:\\foo\\bar",
  "c:\\foo/bar\\": "c:\\foo\\bar",
  "c://foo/bar": "c:\\foo\\bar",
  "c://foo/bar\\": "c:\\foo\\bar",
  "c:/../foo/bar": "c:\\foo\\bar",
  "c:/../foo/bar\\": "c:\\foo\\bar",
  "//foo/bar": "\\\\foo\\bar",
  "//foo/bar\\": "\\\\foo\\bar\\",  // Note that the root-dir of the shared drive stays.
  "///foo": "\\foo",
  "///foo\\": "\\foo",
  "//host/foo": "\\\\host\\foo",
  "//host/foo\\": "\\\\host\\foo\\",  // Note that the root-dir of the shared drive stays.
  "\\\\foo/bar": "\\\\foo\\bar",
  "\\\\foo/bar\\": "\\\\foo\\bar\\",  // Note that the root-dir of the shared drive stays.
  "/\\foo/bar": "\\\\foo\\bar",
  "/\\foo/bar\\": "\\\\foo\\bar\\",  // Note that the root-dir of the shared drive stays.
  "\\/foo/bar": "\\\\foo\\bar",
  "\\/foo/bar\\": "\\\\foo\\bar\\",  // Note that the root-dir of the shared drive stays.
  "c:foo/..": "c:.",
  "c:foo/..\\": "c:.",
  "c:foo/../bar": "c:bar",
  "c:foo/../bar\\": "c:bar",
}

main:
  POSIX-TESTS.do: | path expected |
    actual := posix.clean path
    expect-equals expected actual
  GO-POSIX-TESTS.do: | path expected |
    actual := posix.clean path
    expect-equals expected actual
  WINDOWS-TESTS.do: | path expected |
    actual := windows.clean path
    expect-equals expected actual
  GO-WINDOWS-TESTS.do: | path expected |
    actual := windows.clean path
    expect-equals expected actual
  local-tests := system.platform == system.PLATFORM-WINDOWS ? WINDOWS-TESTS : POSIX-TESTS
  local-tests.do: | path expected |
    actual := fs.clean path
    expect-equals expected actual
  local-go-tests := system.platform == system.PLATFORM-WINDOWS ? GO-WINDOWS-TESTS : GO-POSIX-TESTS
  local-go-tests.do: | path expected |
    actual := fs.clean path
    expect-equals expected actual
