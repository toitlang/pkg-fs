// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import fs

BASE-DIR-TESTS ::= [
  ["foo", "."],
  ["foo/bar", "foo"],
  ["foo/bar/baz", "foo/bar"],
]

main:
  BASE-DIR-TESTS.do: | test/List |
    input := test[0]
    expected := test[1]
    actual := fs.dirname input
    expect-equals expected actual
