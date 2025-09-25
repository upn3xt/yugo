const std = @import("std");

pub fn main() !void {
    var address = try std.net.Address.parseIp4("127.0.0.1", 8080);
    var server = try address.listen(.{
        .reuse_address = true,
    });

    std.debug.print("Listening on port 8080...\n", .{});
    while (true) {
        var connection = try server.accept();
        defer server.deinit();

        var buf: [1024]u8 = undefined;
        _ = try connection.stream.read(&buf);
        _ = try connection.stream.write("Hello world!");
    }
}
