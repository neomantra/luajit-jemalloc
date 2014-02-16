luajit-jemalloc
===============

LuaJIT FFI bindings to the jemalloc library

Does not load jemalloc, this must be done explicitly by the client
either with ffi.load or through a preload mechanism.

Only binds the 'non-standard API'
Adheres to API version 3.5.0

Here's how I run on OSX Homebrew:
```
JEMALLOC_PREFIX=je_ DYLD_INSERT_LIBRARIES=/usr/local/Cellar/jemalloc/3.5.0/lib/libjemalloc.1.dylib  ./test-jemalloc.lua
```

TODO
====

 * better documentation
 * mallctl_write
 * use MIBs in mallctl
 * malloc_stats_print callbacks

License
=======

```
Copyright (c) 2014 Evan Wies

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom
the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
```
