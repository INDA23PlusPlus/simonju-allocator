const std = @import("std");

pub const LinearAllocator = struct {
    offset: usize,
    buffer: []u8,

    pub const vtable = std.mem.Allocator.VTable{
        .alloc = alloc,
        .free = std.mem.Allocator.noFree,
        .resize = std.mem.Allocator.noResize,
    };

    pub fn init(buffer: []u8) @This() {
        return .{
            .offset = 0,
            .buffer = buffer,
        };
    }

    pub fn reset(self: *@This()) void {
        self.offset = 0;
    }

    pub fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
        _ = ret_addr;
        std.debug.assert(len > 0);

        const alignment = @as(usize, 1) << @intCast(ptr_align);
        std.debug.assert((alignment & (alignment - 1)) == 0);

        const self: *@This() = @ptrCast(@alignCast(ctx));
        const remainder = @intFromPtr(self.buffer.ptr + self.offset) % alignment;
        const alignment_offset = if (remainder == 0) self.offset else self.offset + alignment - remainder;

        if (alignment_offset + len > self.buffer.len) return null;

        self.offset = alignment_offset + len;

        return self.buffer.ptr + alignment_offset;
    }

    pub fn allocator(self: *@This()) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }
};

test "standard tests" {
    var buffer: [1000000]u8 = undefined;
    var linear_allocator = std.mem.validationWrap(LinearAllocator.init(&buffer));

    try std.heap.testAllocator(linear_allocator.allocator());
    try std.heap.testAllocatorAligned(linear_allocator.allocator());
    try std.heap.testAllocatorLargeAlignment(linear_allocator.allocator());
}
