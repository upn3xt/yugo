pub const Entry = struct { name: []const u8, entry_point: []const u8, version: []const u8 };

pub const YugoFile = struct { entry: Entry };
