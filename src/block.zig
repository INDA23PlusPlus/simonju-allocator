const std = @import("std");

pub fn BlockAllocator(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Item = *align(block_alignment) T;

        free_list: ?*align(block_alignment) Block,

        const block_size = @max(@sizeOf(Block), @sizeOf(T));
        const block_alignment = @max(@alignOf(*anyopaque), @alignOf(T));
        const block_adjustment = adj: {
            const rem = block_size % block_alignment;
            break :adj if (rem == 0) 0 else rem;
        };

        pub fn init(buffer: []u8) Self {
            var self = Self{ .free_list = null };
            const block_count = buffer.len / (block_size + block_adjustment);
            const blocks = @as([]align(block_alignment) u8, @ptrCast(@alignCast(buffer)));

            for (0..block_count) |i| {
                const block = blocks[i * (block_size + block_adjustment) ..];
                const aligned_block = @as([]align(block_alignment) u8, @ptrCast(@alignCast(block)));
                const block_ptr = @as(*align(block_alignment) Block, @ptrCast(aligned_block));
                block_ptr.* = Block{ .next = self.free_list };

                self.free_list = block_ptr;
            }

            return self;
        }

        pub fn alloc(self: *Self) !Item {
            const block = if (self.free_list) |b| l: {
                self.free_list = b.next;
                break :l b;
            } else {
                return error.OutOfMemory;
            };

            const ptr = @as(Item, @ptrCast(block));
            ptr.* = undefined;

            return ptr;
        }

        pub fn free(self: *Self, ptr: Item) void {
            ptr.* = undefined;

            const block = @as(*align(block_alignment) Block, @ptrCast(ptr));

            block.* = Block{ .next = self.free_list };
            self.free_list = block;
        }

        const Block = struct { next: ?*align(block_alignment) @This() };
    };
}
