#!/usr/bin/env luajit
-------------------------------------------------------------------------------
-- LuaJIT bindings to the jemalloc library
--
-- Copyright (c) 2014 Evan Wies.
-- Released under the MIT license.  See the LICENSE file.
--
-- Project home: https://github.com/neomantra/luajit-jemalloc
--
-- Simple exercises of the jemalloc binding
-- Must be run with jemalloc preloaded
--

local J = require 'jemalloc'

local version = J.mallctl_read('version')
io.stdout:write('jemalloc version is ', version or 'UNKNOWN', '\n')

io.stdout:write('JEMALLOC_PREFIX is: "', J.get_prefix(), '"')
-- exercise mallctl_write
local success, err = J.mallctl_write('arenas.purge', 1)
if not success then error('mallctl_write("arenas.purge") error: ' .. tostring(err)) end

-- allocate some memory
local size = 2*1024*1024
local iters = 1000

local ptrs = {}
for i = 0, iters do
    local ptr = J.mallocx( size )
    io.stdout:write(i, ' ', tostring(ptr), '\n')
    ptrs[#ptrs+1] = ptr
end

-- free the memory
for i = 1, #ptrs do
    J.dallocx( ptrs[i] )
end

-- print the stats
J.malloc_stats_print()

-- exercise binding the standard API
local success, err  = J.bind_standard_api()
if not success then error('failed to bind standard API: ' .. tostring(err)) end

