pub const Game = struct { name: []const u8, entry_point: []const u8, version: []const u8 };

pub const Build = struct {
    app_type: []const u8,
    dependencies: []const []const u8,
    ignore: []const []const u8,
    profile: struct { release: struct {
        opt_level: u8,
    }, debug: ?struct {
        opt_level: u8,
    } = null },
};

pub const Env = struct {
    env_vars: []const []const u8,
};

pub const Metadata = struct { author: []const u8, description: ?[]const u8 = null, license: ?[]const u8 = null };

pub const YugoFile = struct { game: Game, build: Build, env: Env, metadata: Metadata };
