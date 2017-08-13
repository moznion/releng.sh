releng.sh [![Build Status](https://travis-ci.org/moznion/releng.sh.svg?branch=master)](https://travis-ci.org/moznion/releng.sh)
==

Description
--

Pure bash scripts for release engineering.

### release.sh

This script performs the following releng processing.

- Initializing
- Edit changes file
- git
  - `git commit $CHANGES_FILE`
  - `git tag $VERSION`
  - `git push origin $VERSION`
- Create GitHub release

#### Usage

```sh
$ export EDITOR="vim"
$ export GITHUB_TOKEN="token"
$ release.sh --init 'Your Project Name' /path/to/changes/file
$ release.sh /path/to/changes/file
Next version [0.0.1]:
No description for next version in file: '/tmp/M4t7cmru'
Edit file? [Y/n (default: Y)]: y
# Lauch editor: fill description under the `%%NEXT_VERSIONT%%`
#
# And execute git command like bellow
#   - git commit /path/to/changes/file
#   - git tag $VERSION
#   - git push origin $VERSION
#
# Then create GitHub release!
```

#### Requires

- Set the `$EDITOR` environment variable (e.g. `vim`, `emacs`)
- Set the `$GITHUB_TOKEN` environment variable (the token must have `repo` authorization)

### changes.sh

This script performs the following processing.

- Edit changes file

#### Usage

```sh
$ export EDITOR="vim"
$ changes.sh /path/to/changes/file
Next version [0.0.1]:
No description for next version in file: '/tmp/M4t7cmru'
Edit file? [Y/n (default: Y)]: y
# Lauch editor: fill description under the `%%NEXT_VERSIONT%%`
```

#### Requires

- Set the `$EDITOR` environment variable (e.g. `vim`, `emacs`)

Requires
--

- bash
- git
- GNU sed
- GNU data

For Developers
--

### Run tests

```sh
$ cpanm -n Carton
$ carton install
$ carton exec -- prove t/
```

#### Ref

- [https://github.com/miyagawa/cpanminus](https://github.com/miyagawa/cpanminus)
- [https://github.com/perl-carton/carton](https://github.com/perl-carton/carton)

License
--

```
The MIT License (MIT)
Copyright © 2017- moznion, http://moznion.net/ <moznion@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

