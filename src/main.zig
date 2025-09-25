const builder = @import("yugo/builder.zig");

pub fn main() anyerror!void {
    try builder.entry();
}
