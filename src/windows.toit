// Copyright (C) 2023 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.

import .shared_
import host.directory

/**
Windows implementation of the `fs` library.

See:
- https://learn.microsoft.com/en-us/dotnet/standard/io/file-path-formats
- https://googleprojectzero.blogspot.com/2016/02/the-definitive-guide-on-win32-to-nt.html
- https://github.com/golang/go/blob/master/src/path/filepath/path_windows.go
*/

/** The default path separator on Windows systems. */
SEPARATOR ::= "\\"
/** The $SEPARATOR as character (integer). */
SEPARATOR-CHAR ::= '\\'

/**
The list separator on Windows systems.

This separator is, for example, used in the `PATH` environment variable.
*/
LIST-SEPARATOR ::= ";"
/** The $LIST-SEPARATOR as character (integer). */
LIST-SEPARATOR-CHAR ::= ';'

/** Whether the given character $c is a valid separator. */
is-separator c/int -> bool:
  return c == '/' or c == '\\'

/**
Changes the given $path to use slashes as separators.
*/
to-slash path/string -> string:
  return path.replace --all "\\" "/"

/**
Changes the given $path to use backslashes as separators.
*/
from-slash path/string -> string:
  return path.replace --all "/" "\\"

/**
Whether the given $path is rooted.

A rooted path is a path that is fixed to a specific drive or UNC path.
Note that a rooted path can be absolute or drive-relative.

# Examples
All examples use slashes, but the function works with both slashes and backslashes:
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
```
*/
is-rooted path/string -> bool:
  if path.starts-with "\\" or path.starts-with "/": return true
  return path.size >= 2 and is-volume-letter_ path[0] and path[1] == ':'

/**
Whether the given $path is relative.

A path is relative if it is not rooted. A drive-relative path is thus *not*
relative. In practice this means that relative paths can be appended/joined
to other paths.
*/
is-relative path/string -> bool:
  return not is-rooted path

/**
Converts the $path to an absolute path by prepending the current working directory to the path
  if it is not already absolute.

The result is cleaned by $clean before being returned.
*/
to-absolute path/string -> string:
  if is-absolute path: return clean path

  if is-rooted path:
    if is-drive-relative_ path:
      if (is-drive-absolute_ directory.cwd) and directory.cwd[0..2] == path[0..2]:
        return join [directory.cwd, path[(volume-name-size_ path)..]]
      else:
        split-path := split path
        split-path[0] = "$split-path[0]$SEPARATOR"
        return join split-path
    else:
      if is-drive-absolute_ directory.cwd:
        return join [volume-indicator directory.cwd, path]
      // If the cwd is a UNC path, just use the default construction in the next line.

  return join [directory.cwd, path]

/**
Computes the relative path of $path with respect to $base.

Returns the absolute path of $path, if $path is not accessible relative to $base.

The result is cleaned by $clean before being returned.
*/
to-relative path/string base/string -> string:
  return to-relative_ path base --handle-different-root

/**
Returns whether the given $path starts with the given $prefix.

Accepts both forward and backward slashes as separators.
Matches case-insensitive.
*/
starts-with-volume-prefix_ path/string prefix/string -> bool:
  if path.size < prefix.size: return false
  path = path.to-ascii-upper
  prefix = prefix.to-ascii-upper
  prefix.size.repeat:
    c1 := path[it]
    c2 := prefix[it]
    if c1 == c2: continue.repeat
    if is-separator c1 and is-separator c2: continue.repeat
    return false
  if path.size == prefix.size: return true
  return is-separator path[prefix.size]

/**
Computes the size of the volume prefix of a UNC $path.

The $prefix-size is the prefix prior to the start of the UNC host. For
  example, for '//host/share' the $prefix-size is 2 (`//`).
*/
unc-size_ path/string --prefix-size/int -> int:
  encountered-separators := 0
  for i := prefix-size; i < path.size; i++:
    if is-separator path[i]:
      encountered-separators++
      if encountered-separators == 2: return i
  return path.size

/**
Cuts the given $path at the first separator and calls the given $block with the
  two parts.
If there is no separator, the $block is called with the full $path and `null`.
*/
cut-at-separator_ path/string [block]:
  for i := 0; i < path.size; i++:
    if is-separator path[i]:
      block.call path[0..i] path[i + 1..]
      return
  block.call path null

/**
Whether the given $path is absolute (aka "fully qualified").

# Examples
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
*/
is-absolute path/string -> bool:
  return is-drive-absolute_ path or is-unc-absolute_ path

/**
Path starts with a UNC volume.
For example: `//host/share`, `//./UNC/host/share`, ...
*/
is-unc-absolute_ path/string -> bool:
  volume-name-size := volume-name-size_ path

  if volume-name-size == 0:
    // Path doesn't have a volume name.
    // For example: `foo/bar`, `../foo`, `\foo\bar`, ...
    return false

  return is-separator path[0]

/**
Returns whether the given $path starts with an absolute drive indicator.
For example: `c:\\', 'd:/`, ...
*/
is-drive-absolute_ path/string -> bool:
  return path.size >= 3 and
      is-volume-letter_ path[0] and
      path[1] == ':' and
      is-separator path[2]

/**
Returns whether the given $ath starts with a relative drive indicator.
For example: `c:tmp', 'd:../foo`, 'e:', ...
*/
is-drive-relative_ path/string -> bool:
  return (path.size == 2 and
          is-volume-letter_ path[0] and
          path[1] == ':') or
         (path.size >= 3 and
          is-volume-letter_ path[0] and
          path[1] == ':' and
          not is-separator path[2])


/**
Whether the given character $letter a valid volume letter ([a-zA-Z])
*/
is-volume-letter_ letter/int -> bool:
  return 'a' <= letter <= 'z' or 'A' <= letter <= 'Z'

/**
Returns the volume indicator from an absolute path.

# Examples
The examples use `/` as `\\` would need to be escaped in the strings.
The results would always return `\\` instead of `/`.
```
volume-indicator "C:/tmp"            // "C:"
volume-indicator "//host/share/foo"  // "//host/share"
```

*/
volume-indicator path/string -> string?:
  if not is-absolute path: return null
  volume-name-size := volume-name-size_ path
  return path[..volume-name-size]

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

# Examples
The examples use `/` as `//` would need to be escaped in the strings.
The results would also return `\\` instead of `/`.
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
*/
dirname path/string -> string:
  path = from-slash path

  volume-name-size := volume-name-size_ path

  i := path.size - 1
  // Drop trailing separators.
  if volume-name-size != path.size:
    for ; i >= volume-name-size; i--:
      if not is-separator path[i]: break
    if i < volume-name-size:
      // Non-volume path consists entirely of separators.
      // For example: `c:\\\\`.
      // Keep the root directory.
      return clean path[.. volume-name-size + 1]

  // Find the last separator.
  for ; i >= volume-name-size; i--:
    if is-separator path[i]: break
  dir := clean-windows_ path[volume-name-size .. i + 1]
      --volume-name-size=0
      --do-post-clean=(volume-name-size == 0)
  if dir == "." and volume-name-size > 2:
    // Since the volume-name-size is > 2, this must be a UNC path.
    // For example `//host/share`.
    return path[.. volume-name-size]
  return clean-windows_ "$path[.. volume-name-size]$dir"
      --volume-name-size=volume-name-size
      --do-post-clean=(volume-name-size == 0)


/**
Returns the last segment of the $path.

Ignores any trailing separators.
The basename is the part after the last separator.
Returns "" if no basename exists, for example if the path is empty, or
  the root directory.

Volume names might contain separators which are not
  considered separators by this function. For example, `//host/share/`
  has no basename, but `//host/share/foo` has a basename of `foo`.

# Compatibility
Contrary to many other languages and libraries, this function returns an
  empty string if there is no basename.

# Examples
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
*/
basename path/string -> string:
  volume-name-size := volume-name-size_ path

  i := path.size - 1
  // Drop trailing separators.
  if volume-name-size != path.size:
    for ; i >= volume-name-size; i--:
      if not is-separator path[i]: break
    if i < volume-name-size:
      // Non-volume path consists entirely of separators.
      // For example: `c:\\\\`.
      return ""

  end := i + 1

  // Find the last separator.
  for ; i >= volume-name-size; i--:
    if is-separator path[i]: break
  return path[i + 1 .. end]

/**
Joins any number of path elements into a single path, separating them with `\\`.

Empty elements are ignored.
Returns "" (the empty string) if there are no elements or all elements are empty.
Otherwise, calls $clean before returning the result.

The result is only a UNC path (like `//host/share`) if the first
  element is a UNC path.

# Examples
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
*/
join elements/List -> string:
  max-size :=
      (elements.reduce --initial=0: | a b | a + b.size)
        + elements.size - 1
        + 1  // We add an additional character to avoid root local device paths.
  result := ByteArray max-size

  target-pos := 0
  elements.do: | segment/string |
    if segment == "": continue.do
    last-char := target-pos == 0 ? 0 : result[target-pos - 1]
    segment-start-pos := 0
    if target-pos == 0:
      // Write the first segment verbatim below. No need to deal with separators.
    else if is-separator last-char:
      // If the last character was a separator, we strip any leading separators.
      // We need to avoid creating a UNC path from individual segments.
      // For example `["/", "foo"]` should become `/foo` and not `//foo`.
      // In theory we don't need to strip leading separators if we have already
      // a volume, since 'clean' will get rid of multiple separators. However, it's
      // not that easy to figure out when a volume name is complete, and it's easy
      // to remove the leading separators.
      //   `["//host", "//share"]` -> `//host/share` and not `//host//share`?
      // If the segment consists entirely of separators we drop the segment.
      while segment-start-pos < segment.size and is-separator segment[segment-start-pos]:
        segment-start-pos++
      if target-pos == 1 and is-separator result[0] and segment.starts-with "??":
        // If the path is '/' and the next segment is '??' add an extra './' to
        // create '/./??' rather than '/??/' which is a root local device path.
        result[target-pos++] = '.'
        result[target-pos++] = SEPARATOR-CHAR
    else if last-char == ':' and target-pos == 2:
      // Note: Go does this for any segment and not just if the colon is in the 2nd
      // position.
      // If the path ends in a colon, keep the path relative to the current
      // directory on a drive, and don't add a separator. If the segment starts
      // with a separator, it will make the path absolute.
      //
      // For example: `c:` + `foo`  -> `c:foo` and not `c:/foo`.
      //          but `c:` + `/foo` -> `c:/foo`.
      /* Do nothing. Don't add a separator. */
    else:
      // Otherwise, add a separator.
      result[target-pos++] = SEPARATOR-CHAR

    result.replace target-pos segment segment-start-pos
    target-pos += segment.size - segment-start-pos

  // Nothing was added. Should not happen, but doesn't cost to check.
  if target-pos == 0: return ""
  return clean (result[.. target-pos]).to-string

/**
Variant of $(join elements).

Joins the given $base and $path1, and optionally $path2, $path3 and $path4.
*/
join base/string path1/string path2/string="" path3/string="" path4/string="" -> string:
  return join [base, path1, path2, path3, path4]

/**
Splits a path into its components using the seperator valid for the current OS.

Splits on both '/', '\\' and potentially after ':'.
*/
split path/string -> List:
  if path == "": return []

  result := []
  volume-name-size := volume-name-size_ path
  if volume-name-size > 0:
    prefix := path[..volume-name-size]
    if is-drive-absolute_ path: prefix = "$prefix$SEPARATOR"
    result.add prefix

    path = path[volume-name-size..]
  else if is-separator path[0]:
    result.add SEPARATOR

  (path.split "/" --drop-empty).do:
    result.add-all (it.split SEPARATOR --drop-empty)

  return result

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
  root directory (like `c:\\`).

All instances of slash are replaced by `\\`.

If the result would be the empty string returns ".".

Does not modify the volume name other than replacing any
  slashes with backslashes. For example `//host/share/../x` is changed
  to `\\host\share\x`.

# Examples
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
*/
clean path/string -> string:
  path = from-slash path
  volume-name-size := volume-name-size_ path
  return clean-windows_ path
      --volume-name-size=volume-name-size
      --do-post-clean=(volume-name-size == 0)

/**
Cleans the given $path and optionally (based on $do-post-clean) cleans up
  the result.

Uses $clean_ underneath.
*/
clean-windows_ path/string -> string
    --volume-name-size/int
    --do-post-clean/bool:
  result := clean_ path --volume-name-size=volume-name-size --separator=SEPARATOR-CHAR
  if not do-post-clean: return result
  // If the result starts with a segment that contains a ':' prefix it with './'.
  // For example 'foo/../c:' should not become 'c:', but './c:'.
  for i := 0; i < result.size; i++:
    if result[i] == SEPARATOR-CHAR:
      break
    if result[i] == ':':
      return ".\\$result"

  // If a path begins with `/??/` insert a `/.` at the beginning to avoid
  // converting paths like `/a/../??/c:/x` into `/??/c:/x` (which would be
  // equalint to `c:/x`).
  if result.starts-with "\\??\\":
    return "\\.$result"
  return result

volume-name-size_ path/string -> int:
  if path.size >= 2 and is-volume-letter_ path[0] and path[1] == ':':
    // Path starts with a drive letter.
    // For example: `c:`.
    // Only drives with a single ascii character are supported.
    return 2

  if path == "" or not is-separator path[0]:
    // Path is empty or doesn't starts with a separator, and thus doesn't have a volume.
    // For example: `foo/bar`, `../foo`, ...
    return 0

  if starts-with-volume-prefix_ path "//./UNC":
    // Path starts with a UNC volume.
    // For example: `//./UNC/host/share`.
    // In Go, the volume name is the full `//./UNC/host/share` prefix, but
    // the comment explicitly states that this isn't principled, as even Windows' own
    // `GetFullPathName` could happily remove the first component of the path.
    // We thus go with the Windows implementation and only conside `//./UNC/host` as the
    // volume name.
    return unc-size_ path --prefix-size="//./".size

  if starts-with-volume-prefix_ path "//." or
      starts-with-volume-prefix_ path "//?" or
      starts-with-volume-prefix_ path "/??":
    if path.size == 3: return 3

    // If the path starts with `//./`, then it is a local device path.
    // If it starts with `//?/` or `/??` then it is a root local device path.
    //
    // The path `//?/c:/` should not remove the trailing separator when calling 'clean'.
    // As such we include the 'c:' as part of the volume name.
    cut-at-separator_ path[4..]: | prefix/string rest/string? |
      if not rest: return path.size
      return path.size - rest.size - 1
    unreachable

  // Contrary to Go we require a host.
  // As a consequency `///` and `////` are not considered volumes as they are in Go.
  if path.size > 2 and is-separator path[1] and not is-separator path[2]:
    // Path starts with a UNC volume.
    // For example: `//host/share`.
    return unc-size_ path --prefix-size=2

  return 0
