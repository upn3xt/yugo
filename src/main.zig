const std = @import("std");
const eql = std.mem.eql;
// const toml = @import("toml");
// const YugoFile = @import("yugo_struct.zig").YugoFile;
//

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (eql(u8, args[1], "run")) {
        var process = std.process.Child.init(args[2..], allocator);

        process.stdin_behavior = .Inherit;
        process.stdout_behavior = .Inherit;
        process.stderr_behavior = .Inherit;

        const result = try process.spawnAndWait();

        if (result != .Exited) {
            std.debug.print("Something went wrong", .{});
        }
    } else {
        std.debug.print("Command not found!", .{});
    }
}
// pub fn main() !void {
// const allocator = std.heap.page_allocator;
//
// var parser = toml.Parser(YugoFile).init(allocator);
// defer parser.deinit();
//
// const result = try parser.parseFile("docs/tryouts/yugo.toml");
// defer result.deinit();
//
// const model = result.value;
//
// std.debug.print("Name: {s}\n", .{model.game.name});

// std.os.linux.chroot("");
// std.os.linux.fork();
// std.os.linux.clone();
// }
