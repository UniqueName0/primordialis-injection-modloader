const std = @import("std");
const HookManager = @import("HookManager.zig");
const lua = @cImport(@cInclude("lua5.1/lua.h"));

// hooks
var init_lua_hook: *HookManager.Hook = undefined; // addr 0x1400064b5

pub fn init(allocator: std.mem.Allocator) void {
    init_lua_hook = HookManager.Hook.init(allocator, 0x14002be10, @intFromPtr(&init_lua));
}

export fn test_lua_func(_: ?*lua.lua_State) c_int {
    std.log.info("lua api extension working", .{});
    return 1;
}

var lua_inited = false;
fn init_lua() ?*lua.lua_State {
    if (lua_inited) return null;
    lua_inited = true;
    init_lua_hook.detach();

    std.log.info("init_lua hook", .{});
    const targetfunc: *@TypeOf(init_lua) = @ptrCast(init_lua_hook.target);
    const lua_state = targetfunc();

    lua.lua_pushcfunction(lua_state, &test_lua_func);
    lua.lua_setglobal(lua_state, "test_lua");
    lua.lua_pop(lua_state, lua.lua_gettop(lua_state));

    init_lua_hook.attach();
    return lua_state;
}
