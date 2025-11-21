//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const BumpAllocator = @This();

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

fn alloc(_: BumpAllocator) void {}
fn resize(_: BumpAllocator) void {}
fn remap(_: BumpAllocator) void {}
fn free(_: BumpAllocator) void {}
