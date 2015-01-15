--        Copyright 2014, Big Switch Networks, Inc.
--
-- Licensed under the Eclipse Public License, Version 1.0 (the
-- "License"); you may not use this file except in compliance
-- with the License. You may obtain a copy of the License at
--
--        http://www.eclipse.org/legal/epl-v10.html
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
-- either express or implied. See the License for the specific
-- language governing permissions and limitations under the
-- License.

local bit = require("bit")
local ffi = require("ffi")
local C = ffi.C

local sandbox = {
    assert=assert,
    error=error,
    _G=sandbox,
    ipairs=ipairs,
    next=next,
    pairs=pairs,
    pcall=pcall,
    select=select,
    -- setmetatable is only safe as long as we include a __metatable
    -- field in our own metatables, to prevent untrusted code from
    -- changing them.
    setmetatable=setmetatable,
    tonumber=tonumber,
    tostring=tostring,
    type=type,
    unpack=unpack,
    _VERSION=_VERSION,
    xpcall=xpcall,

    bit=bit,

    string={
        byte=string.byte,
        char=string.char,
        find=string.find,
        format=string.format,
        gmatch=string.gmatch,
        gsub=string.gsub,
        len=string.len,
        lower=string.lower,
        match=string.match,
        rep=string.rep,
        reverse=string.reverse,
        sub=string.sub,
        upper=string.upper,
    },

    table={
        concat=table.concat,
        insert=table.insert,
        max=table.maxn,
        remove=table.remove,
        sort=table.sort,
    },

    os={
        clock=os.clock,
    },

    field_names=field_names,

    -- hashtable added by hashtable.lua
    -- murmur added by murmur.lua
}

_G.sandbox = sandbox -- global for C to use

-- To be overridden by uploaded code
function sandbox.ingress() end

-- Entrypoint for packet processing
function process()
    sandbox.ingress()
end

-- To be overridden by uploaded code
function sandbox.command(reader, writer) end

-- Entrypoint for command request
function command(request_data, request_data_length, reply_data, reply_data_length)
    local reader = Reader.new(request_data, request_data_length)
    local writer = Writer.new(reply_data, reply_data_length)
    sandbox.command(reader, writer)
    return writer.offset()
end

function sandbox.require(name)
    return sandbox[name]
end

function sandbox.loadstring(s, name)
    return setfenv(loadstring(s, name), sandbox)
end

ffi.cdef[[
void pipeline_lua_log(const char *str);
]]

function log(...)
    C.pipeline_lua_log(string.format(...))
end

sandbox.log = log

---- Context

-- Create a struct declaration for the field names given to us by C
do
    local lines = {}
    table.insert(lines, "struct fields {")
    for i, v in ipairs(field_names) do
        table.insert(lines, string.format("uint32_t %s;", v))
    end
    table.insert(lines, "};")
    local str = table.concat(lines, "\n")
    ffi.cdef(str)
end

ffi.cdef[[
struct xbuf;
struct action_context;

struct context {
    struct xbuf *stats;
    struct action_context *actx;
    struct fields fields;
};
]]

context = ffi.cast(ffi.typeof('struct context *'), _context)

-- Create a safe proxy for the raw fields pointer
sandbox.fields = setmetatable({}, { __index=context.fields, __metatable=true })

-- Wrap the unsafe register_table API exported by C (which uses raw pointers)
-- with a safe version that wraps the pointers in Readers.
--
-- The 'ops' argument should be a table with 'add', 'modify', and 'delete'
-- functions. Each of these functions is passed Readers for the key and
-- (except for delete) the value. If the optional 'parse_key' and 'parse_value'
-- functions are defined, they are called to transform the corresponding Reader
-- before calling the operation. This is often used to parse the binary stream
-- into a table.
function sandbox.register_table(name, ops)
    local new_reader = Reader.new
    local parse_key = ops.parse_key or function(x) return x end
    local parse_value = ops.parse_value or function(x) return x end
    local add = ops.add
    local modify = ops.modify
    local delete = ops.delete

    local function op_add(key_data, key_len, value_data, value_len)
        add(parse_key(new_reader(key_data, key_len)),
            parse_value(new_reader(value_data, value_len)))
    end

    local function op_modify(key_data, key_len, value_data, value_len)
        modify(parse_key(new_reader(key_data, key_len)),
               parse_value(new_reader(value_data, value_len)))
    end

    local function op_delete(key_data, key_len)
        delete(parse_key(new_reader(key_data, key_len)))
    end

    register_table(name, op_add, op_modify, op_delete)
end
