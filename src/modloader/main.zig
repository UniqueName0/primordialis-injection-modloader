const std = @import("std");
const HookManager = @import("HookManager.zig");

const LuaApiExtender = @import("LuaApiExtender.zig");

var arena: std.heap.ArenaAllocator = undefined;
pub fn entry() void {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    HookManager.init(allocator);
    LuaApiExtender.init(allocator);
    std.log.info("Modloader Started", .{});
}

pub fn exit() void {
    arena.deinit();
}
