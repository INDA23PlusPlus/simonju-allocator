const std = @import("std");
const Allocator = @import("root.zig").block.BlockAllocator;

pub fn main() !void {
    const T = struct { x: u32, y: u32, z: u32 };
    const item_count = @sizeOf(T) * 8;
    var buffer: [item_count]u8 = undefined;
    var block_allocator = Allocator(T).init(&buffer);

    var x: [6]Allocator(T).Item = undefined;
    for (0..6) |i| {
        x[i] = try block_allocator.alloc();
        const j: u32 = @intCast(i);
        x[i].* = T { .x = j, .y = j, .z = j };
        std.debug.print("alloc: {}\n", .{x[i]});
    }

    for (0..6) |i| {
        block_allocator.free(x[i]);
        std.debug.print("alloc: {}\n", .{@intFromPtr(x[i])});
    }

    for (0..6) |i| {
        x[i] = try block_allocator.alloc();
        const j: u32 = @intCast(i);
        x[i].* = T { .x = j, .y = j, .z = j };
        std.debug.print("alloc: {}\n", .{x[i]});
    }
}
