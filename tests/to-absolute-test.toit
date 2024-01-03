// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import fs
import fs.windows
import system
import host.directory

test-posix:
  expect-equals directory.cwd (fs.to-absolute "")
  expect-equals "/" (fs.to-absolute "/")
  expect-equals "/a/b/c" (fs.to-absolute "/a/b/c")
  expect-equals "/a/b/c" (fs.to-absolute "/a/b/c/") // clean removed the trainling slash
  expect-equals "$directory.cwd/a/b/c" (fs.to-absolute "a/b/c")

test-windows:
  expect-equals directory.cwd (fs.to-absolute "")
  expect-equals "$directory.cwd\\a" (fs.to-absolute "a")
  expect-equals "c:\\a\\b" (fs.to-absolute "c:\\a\\b")
  expect-equals "x:\\" (fs.to-absolute "x:\\")

  if windows.is-absolute-volume directory.cwd:
    // It seems impossible to fake UNC paths reliably on windows, so to test this probably, test
    // both from an UNC cwd (in powershell) and a local drive cwd.
    volume := windows.volume-indicator directory.cwd

    expect-equals "$volume\\" (fs.to-absolute "\\") // clean removed the trainling backslash
    expect-equals "$volume\\" (fs.to-absolute "/")
    expect-equals "$volume\\a\\b" (fs.to-absolute "/a/b")
    expect-equals "X:\\a\\b" (fs.to-absolute "X:a/b")
    expect-equals "$directory.cwd\\a" (fs.to-absolute "$(volume)a")
  else:
    expect-equals directory.cwd (fs.to-absolute "/")
    expect-equals directory.cwd (fs.to-absolute "\\")
    expect-equals "X:\\a\\b" (fs.to-absolute "X:a/b")
    expect-equals "$directory.cwd\\a" (fs.to-absolute "a")


main:
  if system.platform == system.PLATFORM-WINDOWS:
    test-windows
  else:
    test-posix
