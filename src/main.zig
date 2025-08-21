const std = @import("std");
const Mapper = @import("yugo/mapper.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var mapper = Mapper.init(allocator, "model/yugo.toml");

    const specs = try mapper.map();
    const x = specs.*;

    std.debug.print("Software: {s}\n", .{x.entry.name});
}
