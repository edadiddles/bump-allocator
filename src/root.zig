//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const BumpAllocator = @This();

const AllocationError = error{ OutOfMemory };

buffer: []u8,
offset: usize,


pub fn init(buffer: []u8) BumpAllocator {
    return .{
        .buffer = buffer,
        .offset = 0,
    };
}

pub fn allocator(self: *BumpAllocator) std.mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        },
    };
}

fn alloc(ctx: *anyopaque, n: usize, alignment: std.mem.Alignment, ra: usize) ?[*]u8 {
    const self: *BumpAllocator = @ptrCast(@alignCast(ctx));
    _ = ra;

    const mem_align = alignment.toByteUnits();
    const adj_size = std.mem.alignPointerOffset(self.buffer.ptr + self.offset, mem_align) orelse return null;
    const adj_offset = self.offset + adj_size;
    const new_offset = adj_offset + n;
    if (new_offset >= self.buffer.len) return null;
    self.offset = new_offset;

    return self.buffer.ptr + adj_offset;
}

fn resize(ctx: *anyopaque, buf: []u8, alignment: std.mem.Alignment, new_size: usize, return_address: usize) bool {
    const self: *BumpAllocator = @ptrCast(@alignCast(ctx));
    _ = alignment;
    _ = return_address;

    if (buf.ptr + buf.len != self.buffer.ptr + self.offset) { return false; }
    if (self.offset - buf.len + new_size >= self.buffer.len) { return false; }

    self.offset = self.offset - buf.len + new_size;

    return true;
}

fn remap(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, return_address: usize) ?[*]u8 {
    const self: *BumpAllocator = @ptrCast(@alignCast(ctx));
    _ = alignment;
    _ = return_address;


    const old_offset = self.offset;
    const new_offset = old_offset - memory.len + new_len;
    if (memory.ptr + memory.len != self.buffer.ptr + self.offset) { return null; }
    if (new_offset >= self.buffer.len) { return null; }

    self.offset = new_offset;

    return self.buffer.ptr + old_offset - memory.len;
}

fn free(ctx: *anyopaque, buf: []u8, alignment: std.mem.Alignment, return_address: usize) void {
    const self: *BumpAllocator = @ptrCast(@alignCast(ctx));
    _ = alignment;
    _ = return_address;

    if (buf.ptr + buf.len != self.buffer.ptr + self.offset) { return; }
    self.offset -= buf.len;
}

var test_fixed_buffer_allocator_memory: [800000 * @sizeOf(u64)]u8 = undefined;
var test_small_fixed_buffer_allocator_memory: [8 * @sizeOf(u64)]u8 align(@alignOf(u64)) = undefined;
test "alloc" {
    var bump_allocator = BumpAllocator.init(test_fixed_buffer_allocator_memory[0..]);
    const a = bump_allocator.allocator();
    _ = a;
}
