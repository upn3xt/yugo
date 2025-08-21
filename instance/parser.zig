// const std = @import("std");
// const eql = std.mem.eql;
// const toml = @import("toml");
// const YugoFile = @import("yugo_struct.zig").YugoFile;
//
// const x = blk: {
//     const allocator = std.heap.page_allocator;
//
//     var parser = toml.Parser(YugoFile).init(allocator);
//     defer parser.deinit();
//
//     const result = parser.parseFile("docs/tryouts/yugo.toml");
//     defer result.deinit();
//
//     const model = result.value;
//     _ = model;
// };
