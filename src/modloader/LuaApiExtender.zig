const std = @import("std");
const HookManager = @import("HookManager.zig");
const lua = @cImport(@cInclude("lua5.1/lua.h"));

// hooks
var init_lua_hook: *HookManager.Hook = undefined; // addr 0x1400064b5

pub fn init(allocator: std.mem.Allocator) void {
    init_lua_hook = HookManager.Hook.init(allocator, 0x14002be10, @intFromPtr(&init_lua));
}

var lua_inited = false;
export fn init_lua() ?*lua.lua_State {
    if (lua_inited) return null;
    lua_inited = true;
    init_lua_hook.detach();

    std.log.info("init_lua hook", .{});
    const targetfunc: *@TypeOf(init_lua) = @ptrCast(init_lua_hook.target);
    const lua_state = targetfunc();

    init_lua_hook.attach();
    return lua_state;
}
