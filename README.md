# luajit-jemalloc

LuaJIT FFI bindings to the [jemalloc memory allocator library](http://www.canonware.com/jemalloc/), 

**It currently only supports jemalloc version 3.5**.

This module provide an API that is nearly identical to jemalloc, so one should consult the [jemalloc documentation](ttp://www.canonware.com/download/jemalloc/jemalloc-latest/doc/jemalloc.html) for details on the functions.  This documentation just details how its functionality is exposed to Lua.

This documentation assumes that the `jemalloc` Lua module has been require'd and stored in a variable named `J`, as shown in the following example:

```
local ffi = require 'ffi'
local J = require 'jemalloc'

-- allocate memory for 1000 doubles
-- then cast it to a double* cdata that automatically deallocates when GC'd
local ptr, err = J.mallocx( 1000*ffi.sizeof('double'), J.MALLOCX_ZERO() )
local doubles = ffi.gc( ffi.cast( ffi.typeof('double*'), ptr ), J.dallocx )

doubles[0] = math.random()
```

## Installation and Usage

To install the library, simply copy the file [`jemalloc.lua`](https://raw.github.com/neomantra/luajit-jemalloc/master/jemalloc.lua) to any directory in your `LUA_PATH`.  

The **luajit-jemalloc** module does not 'load' the jemalloc shared library itself.  This is generally done by the user through `LD_PRELOAD` on Linux or `DYLD_INSERT_LIBRARIES` on OSX; see the [jemalloc wiki](https://github.com/jemalloc/jemalloc/wiki/Getting-Started) for details.   

If you are not using a preload mechanism, then the shared library may be loaded programmatically using the FFI:
```
ffi.load('jemalloc')
```

The **luajit-jemalloc** module may then be loaded with `J = require 'jemalloc'` and the resulting `J` table will contain the API.  The shared library must be loaded before or the `jemalloc` module require will fail.


Here's how I run on **luajit-jemalloc** on various systems:

 * OSX Homebrew
```DYLD_INSERT_LIBRARIES=/usr/local/Cellar/jemalloc/3.5.0/lib/libjemalloc.1.dylib  ./test-jemalloc.lua```

*  Ubuntu with the [`chris-lea/redis-server` PPA](https://launchpad.net/~chris-lea/+archive/redis-server) version 3.5
```LD_PRELOAD=/usr/lib/libjemalloc.so.1 ./test-jemalloc```

----

# API Documentation

## jemalloc's "Non-standard" API

**luajit-jemalloc** binds the jemalloc [non-standard API](http://www.canonware.com/download/jemalloc/jemalloc-latest/doc/jemalloc.html#idm207258046544).  The parameters and return values are identical.

The `flags` parameter may be omitted and defaults to 0.  Otherwise you may use the following functions to generate flags, which may be combined with `J.bor` (which is just `bit.bor`):

  * `J.MALLOCX_LG_ALIGN( la )`
  * `J.MALLOCX_ALIGN( a )`
  * `J.MALLOCX_ZERO()`
  * `J.MALLOCX_ARENA( a )`

#### ptr = J.mallocx( size, flags )

#### ptr = J.rallocx( ptr, size, flags)
  * Note that `rallocx` does *not* fall back to `mallocx` if `ptr` is `nil`, but will segfault.
  * I'm not yet sure if I want to replace that behavior as you will then need to always pass the appropriates `flags` to `rallocx`.

#### size = J.xallocx( ptr, size, extra, flags)

#### size = J.sallocx( ptr, flags )

#### J.dallocx( ptr, flags)

#### size = J.nallocx( size, flags)

#### size = J.malloc_usable_size( ptr )

#### J.malloc_stats_print()
  * Does not support any arguments and invokes the default behavior.


## jemalloc's "Standard" API

**luajit-jemalloc** does not bind the "standard" API memory allocation functions by default.  If you want to bind it, call `J.bind_standard_api()`.  It will then be available in the `J` API table.   The interface is identical to the "standard" API, except that the names do not have a prefix and uniformly return `success, err` (so one doesn't need to access `errno`).


#### success, err = J.bind_standard_api()
  * `ffi.cdef` the jemalloc "standard" library and make the proceeding functions available in the `J` API table.
  * Returns `true` if successful, otherwise `nil` will be false and `err` will contain a string with the error description.
  * Multiple invocations of this function will do nothing but return the original return value.

#### ptr, err = J.malloc( size )
  * If `ptr` is `nil`, then `err` will be `J.ENOMEM`.

#### ptr, err = J.calloc( number, size )
  * If `ptr` is `nil`, then `err` will be `J.ENOMEM`.

#### success, err = J.posix_memalign( ptr, alignment, size )
  * If `success` is `false`, then `err` may be `J.EINVAL` or `J.ENOMEM`.

#### ptr, err = J.aligned_alloc( alignment, size )
  * If `ptr` is `nil`, then `err` may be `J.EINVAL` or `J.ENOMEM`.

#### ptr, err = J.realloc( ptr, size )
  * If `ptr` is `nil`, then `err` will be `J.ENOMEM`.

#### J.free( ptr )


## mallctl 

**luajit-jemalloc** provides two functions for accessing the `mallctl` interface, which is for introspecting the allocator, setting modifiable parameters, and triggering actions.  For a list of the parameters, their type, and if they are readable, writable, or triggers, see the jemalloc [documentation for MALLCTL_NAMESPACE](http://www.canonware.com/download/jemalloc/jemalloc-latest/doc/jemalloc.html#mallctl_namespace).  Either function may be used to trigger an action.

#### result, err = J.mallctl_read( param )
 * Reads the parameter `param` from jemalloc.
 * Returns the result, or `nil` and an error. The error may be a string, `J.EINVAL`, `J.ENOENT`, `J.EPERM`, `J.EAGAIN`, or `J.EFAULT`.

#### success, err = J.mallctl_write( param, value )
 * Writes `value` to the jemalloc parameter `param`.
 * Returns true if successful, or `nil` and an error. The error may be a string, `J.EINVAL`, `J.ENOENT`, `J.EPERM`, `J.EAGAIN`, or `J.EFAULT`.
 * NOTE: this function relies upon [LuaJIT's conversions](http://luajit.org/ext_ffi_semantics.html) which may fail.  The failure message is returned as an error string.


## jemalloc prefix

If your jemalloc library was built with `--with-jemalloc-prefix` then **luajit-jemalloc** needs to know that prefix.  There are two ways to specify this:

 * Set the *Lua global variable* `JEMALLOC_PREFIX` *BEFORE* you first `require` the module.

 * Set the *OS environment variable* `JEMALLOC_PREFIX`.  Note that the *global* variable takes precedence.

As per the jemalloc documentation, `JEMALLOC_PREFIX` defaults to `''` on all platforms except OSX where it is `'je_'`.

The prefix does not affect the **luajit-jemalloc** API, just the internal mechanisms of the module.

#### prefix = J.get_prefix()

  * Returns the value of `JEMALLOC_PREFIX` used by the module.

----

# TODO

 * access to more mallctl params
 * use MIBs in mallctl
 * malloc_stats_print callbacks
 * maybe change the mallctl interface to be more table-like?
 * decide what to do with `J.rallocx`


# License

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
