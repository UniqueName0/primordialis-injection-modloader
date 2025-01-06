const std = @import("std");
const HookManager = @import("HookManager.zig");

var hook: *HookManager.Hook = undefined;

// these funcs might need a different calling convention to be fully compatible with how the game calls its functions but I'm not sure
// also should be noted that they must match the signature of the game's function (same number of params and same param sizes and same output)
fn test1(param_1: c_longlong, param_2: u32) void {
    var regs = HookManager.Registers.save();

    hook.detach();

    std.log.info("1st hook on world creation func", .{});
    std.log.info("param_1: {x}", .{param_1}); // param_1 is probably a pointer to a base/this object
    std.log.info("param_2: {}", .{param_2});

    std.log.info("adding 10 to param_1 in call", .{});
    const targetfunc: *@TypeOf(test1) = @ptrCast(hook.target);
    regs.restore();
    targetfunc(param_1 + 10, param_2);

    hook.attach();
}

var hook2: *HookManager.Hook = undefined;

fn test2(param_1: c_longlong, param_2: u32) void {
    var regs = HookManager.Registers.save();

    hook.detach();

    std.log.info("2nd hook on world creation func", .{});
    std.log.info("param_1: {x}", .{param_1}); // param_1 is probably a pointer to a base/this object
    std.log.info("param_2: {}", .{param_2});

    std.log.info("subtracting 10 from param_1 in call", .{});
    const targetfunc: *@TypeOf(test1) = @ptrCast(hook.target);
    regs.restore();
    targetfunc(param_1 - 10, param_2);

    hook.attach();
}

var arena: std.heap.ArenaAllocator = undefined;
pub fn entry() void {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const allocator = arena.allocator();
    std.log.info("Modloader Started", .{});
    HookManager.init(allocator);

    const addr: usize = 0x14005af60;
    hook = HookManager.Hook.init(allocator, addr, @intFromPtr(&test1)) catch {
        std.log.err("out of mem", .{}); // this might be changed to be handled in Hook.init instead of by the user
        return;
    };
    hook2 = HookManager.Hook.init(allocator, addr, @intFromPtr(&test2)) catch {
        std.log.err("out of mem", .{});
        return;
    };
}

pub fn exit() void {
    arena.deinit();
}
