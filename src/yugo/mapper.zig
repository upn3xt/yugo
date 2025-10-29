const std = @import("std");
const toml = @import("toml");
const Allocator = std.mem.Allocator;
const YugoFile = @import("yugofile.zig").YugoFile;

const Mapper = @This();

allocator: Allocator,
path: []const u8,

pub fn init(allocator: Allocator, path: []const u8) Mapper {
    return Mapper{ .allocator = allocator, .path = path };
}

pub fn map(self: *Mapper) !YugoFile {
    var parser = toml.Parser(YugoFile).init(self.allocator);
    defer parser.deinit();

    const parsed = try parser.parseFile(self.path);

    const specs_ref = parsed.value;

    const specs: YugoFile = undefined;

    specs = .{ .entry = specs_ref.entry };

    return specs;
}
