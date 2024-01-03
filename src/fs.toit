// Copyright (C) 2023 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import system
import .posix as posix
import .windows as windows
import host.directory

/**
A library to work with paths.

All functions in this library work syntactically on paths. They do not access
  the file system.

# Windows
Windows introduces lots of complications compared to Posix systems. This
  section describes some of the concepts.

## Path separators
Windows allows both forward slashes and backslashes as path separators.
  This library keeps the original separators when possible, but always
  uses backslashes when introducing new separators. The $clean function
  furthermore replaces all forward slashes with backslashes.

## Types of paths
Drive paths are paths that start with a drive letter and a colon. For
  example `c:`.

Drive absolute paths are drive paths that are fully qualified (absolute).
  For example `c:\\path\\to\\file`. They start with a drive letter and a
  colon, followed by a path that is rooted on the drive.

Drive relative paths are drive paths that are relative to the current
  working directory of the drive. For example, `c:foo\\bar`. They start
  with a drive letter and a colon, followed by a path that is *not*
  rooted on the drive. This type of path is a relict from the DOS days
  and should not be used anymore. On current versions of Windows there
  isn't a drive-specific working directory anymore, although there are hidden
  environment variables to indicate drive-specific current working
  directories. If the drive of a drive relative path is the same
  as the current working directory, then the path is equivalent to a
  relative path. If the drive is different, then the path is equivalent
  to an absolute path (unless the environment variable is set).

Rooted paths start with a path separator. These are rooted on the
  drive of the current working directory. The full path is
  obtained by prepending the root drive (or UNC path if set).
  Example: `\\path\\to\\file`.

Relative paths are paths that are relative to the current working
  directory. They are not rooted.

Universal Naming Convention (UNC) absolute paths are, more or less, Window's
  alternative to URLs. They are used to access remote
  file systems (typically SMB). A network share
  always starts with two separators. After the separators comes the
  host (either a NetBIOS machine name, or an IP address), followed by
  the share name. Together, this makes up the volume name of a UNC
  path. Example: `\\\\host\\share\\path`.

Local device paths are paths that start with the sequence "\\\\.\\"
  (two backslashes, a dot, and another backslash). They are used to
  access devices directly, bypassing the file system. For example
  `\\\\.\\COM1` is the first serial port.

## Volume name
A volume name is the name of a drive, for example `C:` or `D:`, or a UNC
  path, for example `\\\\host\\share`.

## Examples
Examples for Windows paths. Each example is followed by the result of calling $is-absolute, $is-rooted, and $is-relative on the path.
- `C:\\Documents\\Newsletters\\Summer2018.pdf` - an absolute file path from the root of drive `C:`.
- `\\Program Files\\Custom Utilities\\StringFinder.exe` - a relative path from the root of the current drive.
- `2018\\January.xlsx` - a relative path to a file in a subdirectory of the current directory.
- `..\\Publications\\TravelBrochure.pdf` - a relative path to a file in a directory starting from the current directory.
- `C:\\Projects\\apilibrary\\apilibrary.sln` - an absolute path to a file from the root of drive `C:`.
- `C:Projects\\apilibrary\\apilibrary.sln` - a relative path from the current directory oft he `C:` drive.
*/

is-windows_/bool ::= system.platform == system.PLATFORM-WINDOWS

/** The default path separator on this systems. */
SEPARATOR ::= is-windows_ ? windows.SEPARATOR : posix.SEPARATOR
/** The $SEPARATOR as character (integer). */
SEPARATOR-CHAR ::= is-windows_ ? windows.SEPARATOR-CHAR : posix.SEPARATOR-CHAR

/**
The list separator on this system.

This separator is, for example, used in the `PATH` environment variable.
*/
LIST-SEPARATOR ::= is-windows_ ? windows.LIST-SEPARATOR : posix.LIST-SEPARATOR
/** The $LIST-SEPARATOR as character (integer). */
LIST-SEPARATOR-CHAR ::= is-windows_ ? windows.LIST-SEPARATOR-CHAR : posix.LIST-SEPARATOR-CHAR

/** Whether the given character $c is a valid separator. */
is-separator c/int -> bool:
  return is-windows_ ? windows.is-separator c : posix.is-separator c

/**
Changes the given $path to use slashes as separators.

This function has no effect on Posix systems.
*/
to-slash path/string -> string:
  return is-windows_ ? windows.to-slash path : path

/**
Changes the given $path to use the default separator for this system.
*/
from-slash path/string -> string:
  return is-windows_ ? windows.from-slash path : path

/**
Whether the given $path is absolute.

On Windows the term "fully qualified" is often used for absolute paths.

# Examples
## Windows:
For simplicity we use `/` in the examples. All examples work with both `/` and `\\`,
  but `\\` would need to be escaped in the strings.

```
is-absolute ""                 // False.
is-absolute "/"                // False.
is-absolute "C:"               // False. Drive-relative.
is-absolute "C:/"              // True.
is-absolute "C:/foo/bar"       // True.
is-absolute "C:foo/bar"        // False. Drive-relative.
is-absolute "/foo/bar"         // False. Rooted, but not absolute.
is-absolute "//share/foo/bar"  // True.
is-absolute "foo/bar"          // False.
is-absolute "../foo/bar"       // False.
```

## Posix:
```
is-absolute ""                 // False.
is-absolute "/"                // True.
is-absolute "/foo/bar"         // True.
is-absolute "foo/bar"          // False.
is-absolute "../foo/bar"       // False.
```
*/
is-absolute path/string -> bool:
  return is-windows_ ? windows.is-absolute path : posix.is-absolute path

/**
Whether the given $path is rooted.

On Posix systems, where rooted paths, don't really exist we give it the same
  meaning as $is-absolute.

On Windows, a rooted path is a path that is fixed to a specific drive or UNC path.
Note that a rooted path can be absolute or drive-relative.

# Examples
## Windows
The examples use `/` as `\\` would need to be escaped in the strings.
```
  is-rooted ""                 // False.
  is-rooted "c"                // False.
  is-rooted "C:"               // True. Drive-relative rooted path.
  is-rooted "C:/foo/bar"       // True.
  is-rooted "C:foo/bar"        // True. Drive-relative rooted path.
  is-rooted "/foo/bar"         // True.
  is-rooted "//share/foo/bar"  // True.
  is-rooted "foo/bar"          // False.
  is-rooted "../foo/bar"       // False.

On Posix:
  is-rooted ""                 // False.
  is-rooted "/"                // True.
  is-rooted "/foo/bar"         // True.
  is-rooted "foo/bar"          // False.
  is-rooted "../foo/bar"       // False.
```
*/
is-rooted path/string -> bool:
  return is-windows_ ? windows.is-rooted path : posix.is-rooted path

/**
Whether the given $path is relative.

A path is relative if it is not rooted ($is-rooted). A drive-relative path
  is thus *not* relative. In practice this means that relative paths can be
  appended/joined
  to other paths.
*/
is-relative path/string -> bool:
  return not is-rooted path

/**
Convert the $path to an absolute path by prepending the current working directory to the path
  if it is not already absolute.

The result is cleaned by $clean before being returned.
*/
to-absolute path/string -> string:
  return is-windows_ ? windows.to-absolute path : posix.to-absolute path

/**
Computes the relative path of $path with respect to $base.

Returns the absolute path of $path, if $path is not accessible relative to $base.

The result is cleaned by $clean before being returned.
*/
to-relative path/string base/string -> string:
  return is-windows_ ? windows.to-relative path base : posix.to-relative path base

/**
Strips the $basename component of a given $path.

Ignores any trailing separators (unless it is part of the root directory).

In the usual case this function returns the string up to, but not including,
  the final separator (and $basename returns the component following the final separator).

Returns "." if the $path is empty.
Returns "." if the $path does not contain any separators.
Returns the root directory if the $path is the root directory.

Calls $clean on the result.

Due to calling $clean returns a single separator if the $path consists entirely of separators.

The result does not end with a separator unless it is the root directory.

# Compatibility
There are many different implementations of `dirname` and most of them are
  slightly incompatible. Some known differences:

- C's `dirname` and `/usr/bin/dirname`: Do not clean the result.
  `dirname /foo/../bar` -> `/foo/..`
- Golang: Does not ignore trailing separators. `path.Dir("/foo/bar/")` -> `/foo/bar`

# Examples
## Windows
The examples use `/` as `\\` would need to be escaped in the strings.
The results would always return `\\` instead of `/`.
```
dirname ""                 // "."
dirname "foo"              // "."
dirname "/"                // "/"
dirname "/foo/bar"         // "/foo"
dirname "foo/bar"          // "foo"
dirname "c:"               // "c:."
dirname "c:/"              // "c:/"
dirname "c:/foo"           // "c:/"
dirname "c:/foo/bar"       // "c:/bar"
dirname "//host/share/"    // "//host/share/"
dirname "//host/share/foo" // "//host/share/"
```

## Posix
```
dirname ""                 // "."
dirname "foo"              // "."
dirname "/"                // "/"
dirname "/foo/bar"         // "/foo"
dirname "foo/bar"          // "foo"
```

## Walk up a directory tree
Example to walk up a directory tree (independent of the system):
```
walk path/string [block]:
  // We use 'clean' to make sure we don't accidentally visit the
  // root directory multiple times.
  // On Windows the input could be `c:/` which would yield a dirname of `c:\\`.
  // The `next == path` check below would not trigger if we didn't
  // clean the path first.
  path := fs.clean path
  while true:
    block.call path
    next := fs.dirname path
    if next == path: return
```
*/
dirname path/string -> string:
  return is-windows_ ? windows.dirname path : posix.dirname path

/**
Returns the last segment of the $path.

Ignores any trailing separators.
The basename is the part after the last separator.
Returns "" if no basename exists, for example if the path is empty, or
  the root directory.

On Windows, volume names might contain separators which are not
  considered separators by this function. For example, `//host/share/`
  has no basename, but `//host/share/foo` has a basename of `foo`.

# Compatibility
Contrary to many other languages and libraries, this function returns an
  empty string if there is no basename.

# Examples
## Windows
The examples use `/` as `\\` would need to be escaped in the strings.
The results would always return `\\` instead of `/`.
```
basename ""                 // ""
basename "foo"              // "foo"
basename "/"                // ""
basename "/foo/bar.exe"     // "bar.exe"
basename "foo/bar"          // "bar"
basename "//host/share/"    // ""
basename "//host/share/foo" // "foo"
basename "c:/"              // ""
basename "foo/.."           // ".."
```

## Posix
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
  return is-windows_ ? windows.basename path : posix.basename path

/**
Joins any number of path elements into a single path, separating them
  with the OS specific $SEPARATOR.

Empty elements are ignored.
Returns "" (the empty string) if there are no elements or all elements are empty.
Otherwise, calls $clean before returning the result.

On Windows the result is only a UNC path (like `//host/share`) if the first
  element is a UNC path.

# Examples
## Windows
The examples use `/` as `\\` would need to be escaped in the strings.
The results would always return `\\` instead of `/`.
```
join []                         // ""
join [""]                       // ""
join ["foo"]                    // "foo"
join ["foo", "bar"]             // "foo/bar"
join ["foo", "bar", "baz"]      // "foo/bar/baz"
join ["foo", "", "bar"]         // "foo/bar"
join ["c:", "foo"]              // "c:foo"
join ["c:", "/foo"]             // "c:foo/bar"
join ["c:/", "foo"]             // "c:/foo"
join ["//host/share", "foo"]    // "//host/share/foo"
join ["//host", "share", "foo"] // "//host/share/foo"
join ["/", "/", "foo"]          // "/foo"
```

## Posix
```
join []                         // ""
join [""]                       // ""
join ["foo"]                    // "foo"
join ["foo", "bar"]             // "foo/bar"
join ["foo", "bar", "baz"]      // "foo/bar/baz"
join ["foo", "", "bar"]         // "foo/bar"
join ["/", "foo", "", "bar"]    // "/foo/bar"
join ["/foo", "", "bar"]        // "/foo/bar"
```
*/
join elements/List -> string:
  return is-windows_ ? windows.join elements : posix.join elements

/**
Variant of $(join elements).

Joins the given $base and $path1, and optionally $path2, $path3 and $path4.
*/
join base/string path1/string path2/string="" path3/string="" path4/string="" -> string:
  return join [base, path1, path2, path3, path4]

/**
Splits a path into its components using the seperator valid for the current OS.

On Windows it splits on both '/', '\\' and potentially after ':', on Posix it splits on '/' only.
If a path (potentially after a leading volume name) starts with a separator, then the entry before the first path segment is a separator.
*/
split path/string -> List:
  return is-windows_ ? windows.split path : posix.split path

/**
Cleans a path, removing redundant path separators and resolving "." and ".."
  segments.
This operation is purely syntactical.

Applies the following rules iteratively until no more changes are made:
- Replace multiple consecutive path separators with a single one.
- Remove "./" segments.
- Remove the previous segment (between the last two slashes) if it is "..".
- Remove .. segments at the beginning of a rooted path (see $is-rooted).

The result ends with a separator if and only if the results represents a
  root directory (like / on Posix or c:\ on Windows.)

All instances of slash are replaced by the system's path separator.

If the result would be the empty string returns ".".

On Windows, does not modify the volume name other than replacing any
  slashes with backslashes. For example `//host/share/../x` is changed
  to `\\host\share\x`.

# Examples
## Windows
The examples use `/` as `\\` would need to be escaped in the strings.
The results would always return `\\` instead of `/`.
```
clean ""                         // "."
clean "foo"                      // "foo"
clean "c:/foo"                   // "c:/foo"
clean "c:/foo/../bar/"           // "c:/bar"
clean "c:/foo/.."                // "c:/"
clean "c:/foo/../.."             // "c:/"
clean "//host/share/foo/.."      // "//host/share/"
clean "//host/share/foo/bar/.."  // "//host/share/foo"
clean "c:/foo/////bar"           // "c:/foo/bar"
clean "c:/foo/./bar"             // "c:/foo/bar"
```

## Posix:
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
  return is-windows_ ? windows.clean path : posix.clean path

