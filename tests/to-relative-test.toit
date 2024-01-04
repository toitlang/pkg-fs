// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import fs
import fs.windows
import system
import host.directory

test-posix:
  expect-equals ".." (fs.to-relative "a" "a/b")
  expect-equals "b" (fs.to-relative "a/b" "a")
  expect-equals "../../b" (fs.to-relative "a/b" "a/c/d")
  expect-equals "../../b" (fs.to-relative "/a/b" "/a/c/d")
  expect-equals "../c/d" (fs.to-relative "/a/c/d" "/a/b" )

test-windows:
  expect-equals ".." (fs.to-relative "a" "a/b")
  expect-equals "b" (fs.to-relative "a/b" "a")
  expect-equals "..\\..\\b" (fs.to-relative "a/b" "a/c/d")
  expect-equals "..\\..\\b" (fs.to-relative "c:\\a\\b" "c:\\a\\c\\d")
  expect-equals "c:\\a\\b" (fs.to-relative "c:\\a\\b" "h:\\a\\c\\d")
  expect-equals "..\\..\\b" (fs.to-relative "\\\\host\\share\\b" "\\\\host\\share\\a\\b")
  expect-equals "\\\\host\\share1\\b" (fs.to-relative "\\\\host\\share1\\b" "\\\\host\\share2\\a\\b")

main:
  if system.platform == system.PLATFORM-WINDOWS:
    test-windows
  else:
    test-posix
