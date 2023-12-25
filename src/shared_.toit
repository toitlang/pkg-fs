// Copyright (C) 2023 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import .fs

/**
Cleans the path.

The $path must already use the $separator as separators. Typically this is achieved
  by calling $from-slash.
*/
clean_ path/string --volume-name-size/int --separator/int -> string:
  // Note that volume-name-size can only be > 0 if we are on Windows.
  if path.size == volume-name-size:
    if path.starts-with "\\\\":
      // A UNC path.
      return path
    // Must be a drive path.
    // Without any path (not even a separator) it's a drive-relative path.
    return "$path."  // Note the trailing ".".

  // Add a terminating character so we don't need to check for out of bounds.
  path-size := path.size
  bytes := ByteArray path-size + 1
  bytes.replace 0 path
  bytes[path-size] = separator

  start-index := volume-name-size
  is-rooted := bytes[start-index] == separator

  separators := []  // Indexes of previous separators.
  at-separator := false
  if not is-rooted:
    // For simplicity treat this as if we just encountered a slash.
    at-separator = true
    separators.add (start-index - 1)

  target-index := start-index

  i := start-index
  while i < path-size:
    if at-separator and bytes[i] == separator:
      // Skip consecutive separators.
      i++
      continue
    if at-separator and bytes[i] == '.' and bytes[i + 1] == separator:
      // Drop "./" segments.
      i += 2
      continue
    if at-separator and
        bytes[i] == '.' and
        bytes[i + 1] == '.' and
        bytes[i + 2] == separator:
      // Discard the previous segment (between the last two separators).
      if separators.size < 2:
        // We don't have a previous segment to discard.
        if is-rooted:
          // Just drop them if the path is absolute.
          i += 3
          // No need to update `at-separator`. It's still true.
          continue
        // Otherwise we have to copy them over.
        bytes[target-index++] = bytes[i++]
        bytes[target-index++] = bytes[i++]
        bytes[target-index++] = bytes[i++]
        // Move the separator.
        // If we add a new segment that should be removed, it must be removed up
        // to the current position. Anything before should not be touched.
        // This happens when we have leading '..' that need to stay, like in `../abc/..`.
        separators[0] = target-index - 1
        // It's not a problem if 'target_index' is one after the '\0' (equal to
        // 'bytes.size'), but it feels cleaner (and more resistant to future
        // changes) if we fix it.
        if target-index > path-size: target-index--
        // No need to update `at-separator`. It's still true.
        continue
      // Still handling '..' here.
      // Reset to the last '/'.
      separators.resize (separators.size - 1)
      target-index = separators.last + 1
      i += 3
      // No need to update `at-separator`. It's still true.
      continue

    if bytes[i] == separator:
      separators.add target-index
      at-separator = true
    else:
      at-separator = false

    bytes[target-index++] = bytes[i++]

  if target-index == volume-name-size:
    if volume-name-size == 0: return "."
    if volume-name-size > 2:
      // Probably unreachable, but can't hurt to special case.
      // Must be a UNC path.
      // For example '//host/share'
      return path[..volume-name-size]
    // Must be a relatidrive path.
    // For example `c:foo/..` which gets cleaned to `c:.`
    bytes[target-index++] = '.'

  // Drop trailing path separator unless it's the root path.
  last-char-index := target-index - 1
  if last-char-index > start-index and bytes[last-char-index] == separator:
    target-index--

  return bytes[..target-index].to-string

/**
Convert the $path to a relative path in relation to $base.

If it is not possible to be relative, returns the absolute path of $path.

The result is cleaned by $clean before being returned.
*/
to-relative_ path/string base/string --handle-different-root/bool=false -> string:
  absolute-path := to-absolute path
  absolute-base := to-absolute base

  split-path := split absolute-path
  split-base := split absolute-base

  if handle-different-root and not split-path.is-empty and not split-base.is-empty:
    if split-base[0] != split-path[0]: return absolute-path

  idx := 0
  while idx < split-path.size and idx < split-base.size and split-path[idx] == split-base[idx]:
    idx++

  relativ-elements := List (split-base.size - idx) ".."
  relativ-elements.add-all split-path[idx..]

  return join relativ-elements
