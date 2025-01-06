const std = @import("std");
const builtin = @import("builtin");
const util = switch (builtin.os.tag) {
    .windows => @import("util/windows-util.zig"),
    else => @import("util/windows-util.zig"), //defaults to windows for now
};

var hooks: std.AutoHashMap(usize, Hook) = undefined;
var base_address: usize = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    base_address = util.get_base_addr();
    hooks = @TypeOf(hooks).init(allocator);
}

const HookBytesStruct = extern struct {
    push_rax: u8 = 0x50,
    mov_rax: [2]u8 = .{ 0x48, 0xb8 },
    address: usize align(1),
    xchg_rax_rsp: [4]u8 = .{ 0x48, 0x87, 0x04, 0x24 },
    ret: u8 = 0xC3,
};

pub const HookBytes = extern union {
    formatted: HookBytesStruct,
    raw: [16]u8,
};

pub const Hook = struct {
    target: *HookBytes = undefined,
    userCallbacks: std.ArrayList(HookBytes) = undefined,
    tmpBytesBuf: std.ArrayList([16]u8) = undefined,
    depth: usize = 0,

    pub fn init(allocator: std.mem.Allocator, targetAddress: usize, hookAdress: usize) error{OutOfMemory}!*Hook {
        var addr = base_address + targetAddress;
        if (targetAddress > 0x140000000) addr -= (0x140000000);

        const res = try hooks.getOrPut(addr);
        if (!res.found_existing) {
            res.value_ptr.* = .{};
        }
        var self: *Hook = res.value_ptr;

        if (self.depth == 0) {
            self.userCallbacks = @TypeOf(self.userCallbacks).init(allocator);
            self.tmpBytesBuf = @TypeOf(self.tmpBytesBuf).init(allocator);
            self.target = @ptrFromInt(addr);
        }

        util.mem_protect_rw(addr);
        try self.tmpBytesBuf.append(self.target.*.raw);
        try self.userCallbacks.append(.{ .formatted = .{ .address = hookAdress } });
        util.mem_protect_restore(addr);

        self.attach();
        return self;
    }

    pub fn attach(self: *Hook) void {
        util.mem_protect_rw(@intFromPtr(self.target));
        self.target.*.raw = self.userCallbacks.items[self.depth].raw;
        util.mem_protect_restore(@intFromPtr(self.target));

        self.depth += 1;
    }

    pub fn detach(self: *Hook) void {
        self.depth -= 1;

        util.mem_protect_rw(@intFromPtr(self.target));
        self.target.*.raw = self.tmpBytesBuf.items[self.depth];
        util.mem_protect_restore(@intFromPtr(self.target));
    }
};

// for now this just saves and restores every register (except stack)
pub const Registers = extern struct {
    rax: usize = 0,
    rbx: usize = 0,
    rcx: usize = 0,
    rdx: usize = 0,
    rsi: usize = 0,
    rdi: usize = 0,
    r8: usize = 0,
    r9: usize = 0,
    r10: usize = 0,
    r11: usize = 0,
    r12: usize = 0,
    r13: usize = 0,
    r14: usize = 0,
    r15: usize = 0,

    pub inline fn save() Registers {
        var rax: usize = 0;
        var rbx: usize = 0;
        var rcx: usize = 0;
        var rdx: usize = 0;
        var rsi: usize = 0;
        var rdi: usize = 0;
        var r8: usize = 0;
        var r9: usize = 0;
        var r10: usize = 0;
        var r11: usize = 0;
        var r12: usize = 0;
        var r13: usize = 0;
        var r14: usize = 0;
        var r15: usize = 0;
        asm volatile ("mov %[rax], %%rax"
            : [rax] "={rax}" (rax),
        );
        asm volatile ("mov %[rbx], %%rbx"
            : [rbx] "={rbx}" (rbx),
        );
        asm volatile ("mov %[rcx], %%rcx"
            : [rcx] "={rcx}" (rcx),
        );
        asm volatile ("mov %[rdx], %%rdx"
            : [rdx] "={rdx}" (rdx),
        );
        asm volatile ("mov %[rsi], %%rsi"
            : [rsi] "={rsi}" (rsi),
        );
        asm volatile ("mov %[rdi], %%rdi"
            : [rdi] "={rdi}" (rdi),
        );
        asm volatile ("mov %[r8], %%r8"
            : [r8] "={r8}" (r8),
        );
        asm volatile ("mov %[r9], %%r9"
            : [r9] "={r9}" (r9),
        );
        asm volatile ("mov %[r10], %%r10"
            : [r10] "={r10}" (r10),
        );
        asm volatile ("mov %[r11], %%r11"
            : [r11] "={r11}" (r11),
        );
        asm volatile ("mov %[r12], %%r12"
            : [r12] "={r12}" (r12),
        );
        asm volatile ("mov %[r13], %%r13"
            : [r13] "={r13}" (r13),
        );
        asm volatile ("mov %[r14], %%r14"
            : [r14] "={r14}" (r14),
        );
        asm volatile ("mov %[r15], %%r15"
            : [r15] "={r15}" (r15),
        );

        return Registers{
            .rax = rax,
            .rbx = rbx,
            .rcx = rcx,
            .rdx = rdx,
            .rsi = rsi,
            .rdi = rdi,
            .r8 = r8,
            .r9 = r9,
            .r10 = r10,
            .r11 = r11,
            .r12 = r12,
            .r13 = r13,
            .r14 = r14,
            .r15 = r15,
        };
    }

    pub inline fn restore(self: *Registers) void {
        asm volatile (""
            :
            : [rax] "{rax}" (self.rax),
              [rbx] "{rbx}" (self.rbx),
              [rcx] "{rcx}" (self.rcx),
              [rdx] "{rdx}" (self.rdx),
              [rsi] "{rsi}" (self.rsi),
              [rdi] "{rdi}" (self.rdi),
              [r8] "{r8}" (self.r8),
              [r9] "{r9}" (self.r9),
              [r10] "{r10}" (self.r10),
              [r11] "{r11}" (self.r11),
              [r12] "{r12}" (self.r12),
              [r13] "{r13}" (self.r13),
              [r14] "{r14}" (self.r14),
              [r15] "{r15}" (self.r15),
        );
    }
};
