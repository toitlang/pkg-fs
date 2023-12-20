// Copyright (C) 2023 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import .fs show clean_

/**
Posix implementation of the `fs` library.
*/

/** The path separator on Posix systems. */
SEPARATOR ::= "/"
/** The $SEPARATOR as character (integer). */
SEPARATOR-CHAR ::= '/'

/**
The list separator on Posix systems.

This separator is, for example, used in the `PATH` environment variable.
*/
LIST-SEPARATOR ::= ":"
/** The $LIST-SEPARATOR as character (integer). */
LIST-SEPARATOR-CHAR ::= ':'

/** Whether the given character $c is a valid separator. */
is-separator c/int -> bool:
  return c == '/'

/**
Whether the given path is absolute.

On Posix systems this is true if the path starts with a slash.

# Examples
```
is-absolute ""                 // False.
is-absolute "/"                // True.
is-absolute "/foo/bar"         // True.
is-absolute "foo/bar"          // False.
is-absolute "../foo/bar"       // False.
```
*/
is-absolute path/string -> bool:
  return not path.is-empty and  path[0] == '/'

/**
Whether the given $path is rooted.

Posix doesn't have the concept of a rooted path, so we give it the same
  meaning as absolute paths.
*/
is-rooted path/string -> bool:
  return is-absolute path

/**
Whether the given $path is relative.
*/
is-relative path/string -> bool:
  return not is-absolute path

volume-name-size_ path/string -> int:
  return 0

/**
Returns the given $path verbatim as Posix systems always use slash as separators.
*/
to-slash path/string -> string:
  return path

/**
Returns the given $path verbatim as Posix systems always use slash as separators.
*/
from-slash path/string -> string:
  return path

/**
Strips the $basename component of a given $path.

Ignores any trailing separators (unless it is the root '/').

In the usual case this function returns the string up to, but not including,
  the final separator (and $basename returns the component following the final '/').

Returns "." if the $path is empty.
Returns "." if the $path does not contain any separators.
Returns the root directory if the $path is the root directory.

Calls $clean on the result.

Due to calling $clean returns a single separator if the $path consists entirely of separators.

The result does not end with a separator unless it is the root directory.

# Examples
```
dirname ""                 // "."
dirname "foo"              // "."
dirname "/"                // "/"
dirname "/foo/bar"         // "/foo"
dirname "foo/bar"          // "foo"
```
*/
dirname path/string -> string:
  if path == "": return "."

  i := path.size - 1

  // Ignore trailing separators.
  for ; i >= 0; i--:
    if path[i] != '/': break
  if i < 0:
    // Path consisted entirely of separators.
    return "/"

  // Find the last separator.
  for ; i >= 0; i--:
    if path[i] == '/': break
  if i < 0: return "."  // No separator in the whole path.
  if i == 0: return "/"  // Root directory.
  return clean path[0 .. i]


/**
Returns the last segment of the $path.

Ignores any trailing separators.
The basename is the part after the last separator.
Returns the empty string if no basename exists, for example if the path is empty, or
  equal to '/'.

# Compatibility
Contrary to many other languages and libraries, this function returns an
  empty string if there is no basename.

# Examples
```
basename ""                 // ""
basename "foo"              // "foo"
basename "/"                // ""
basename "/foo/bar"         // "bar"
basename "foo/bar"          // "bar"
basename "foo/bar/"         // "bar"
basename "foo/.."           // ".."
```
*/
basename path/string -> string:
  if path == "": return ""

  i := path.size - 1

  // Ignore trailing separators.
  for ; i >= 0; i--:
    if path[i] != '/': break
  if i < 0:
    // Path consisted entirely of separators.
    return ""

  end := i + 1

  // Find the last separator.
  for ; i >= 0; i--:
    if path[i] == '/': break
  return path[i + 1 .. end]

/**
Cleans a path, removing redundant path separators and resolving "." and ".."
  segments.
This operation is purely syntactical.

Applies the following rules iteratively until no more changes are made:
- Replace multiple consecutive path separators with a single one.
- Remove "./" segments.
- Remove the previous segment (between the last two slashes) if it is "..".
- Remove .. segments at the beginning of a rooted path (see $is-rooted).

The result ends with a separator if and only if the results is "/".

If the result would be the empty string returns ".".

# Examples
```
clean ""                     // "."
clean "foo"                  // "foo"
clean "/foo"                 // "/foo"
clean "/foo/../bar/"         // "/bar"
clean "/foo/.."              // "/"
clean "/../../.."            // "/"
clean "/foo/////bar"         // "/foo/bar"
clean "/foo/./bar"           // "/foo/bar"
```
*/
clean path/string -> string:
  return clean_ path --volume-name-size=0 --separator='/'
