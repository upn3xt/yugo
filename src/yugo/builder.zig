const std = @import("std");
const linux = std.os.linux;
const eql = std.mem.eql;

const ArgsWrapper = struct {
    args: []const []const u8,
};

const Builder = @This();

/// Makes all shit start
pub fn entry() !void {
    var abuf: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&abuf);
    const allocator = fba.allocator();

    const raw = try std.process.argsAlloc(allocator);
    defer allocator.free(raw);
    const args = raw[1..];

    const arg1 = args[0];
    const arg2 = args[1..];

    if (eql(u8, arg1, "setup")) {
        _ = std.process.getEnvVarOwned(allocator, "HOME") catch |e| {
            std.debug.print("HOME environment variable was not found.\n", .{});
            return e;
        };
    } else if (eql(u8, arg1, "list")) {
        // list worlds
    } else if (eql(u8, arg1, "build")) {} else if (eql(u8, arg1, "run")) {
        try run(allocator, arg2);
    } else if (eql(u8, arg1, "help")) {
        std.debug.print("USAGE: yugo <command>\nInvalid command, try \'help\' to see the list of the available commands\n", .{});
    } else {
        std.debug.print("USAGE: yugo <command>\nInvalid command, try \'help\' to see the list of the available commands\n", .{});
    }
    return;
}

/// Runs stuff
pub fn run(allocator: std.mem.Allocator, args: [][:0]u8) !void {
    const wrapper = try allocator.create(ArgsWrapper);
    wrapper.args = args;
    try cloneWrapper(process, @intFromPtr(wrapper));
}

/// This function is exactly what you expect, a clone syscall wrapper, it's a helper function
pub fn cloneWrapper(func: *const fn (usize) callconv(.c) u8, argv: usize) !void {
    const stack_size = 4096 * 4;
    var stack: [stack_size]u8 align(16) = undefined;
    const stack_top = @intFromPtr(&stack) + stack.len;
    const flags = linux.CLONE.NEWUTS | linux.CLONE.NEWPID | linux.CLONE.NEWNS | linux.SIG.CHLD;
    const pid_usize = linux.clone(func, stack_top, flags, argv, null, 0, null);

    const INVALID_PID: usize = @bitCast(@as(isize, -1));
    if (pid_usize == INVALID_PID) {
        std.debug.print("Clone failed. Reason: Unkown \n", .{});
        return error.CloneFailed;
    }
    if (pid_usize == @intFromEnum(linux.E.INVAL)) return error.InvalidArgument;

    const pid: i32 = @intCast(pid_usize);

    var status: u32 = 0;
    _ = std.os.linux.waitpid(pid, &status, 0);
}

/// This function is the process that will be executed in the clone syscall.
pub fn process(argv: usize) callconv(.c) u8 {
    const allocator = std.heap.page_allocator;
    const wrapper: *ArgsWrapper = @ptrFromInt(argv);
    const args = wrapper.args;

    std.debug.print("Running {s} as PID {}...\n", .{ args[0], linux.getpid() });

    try containerize();
    bgCommand(allocator, args) catch |e| {
        std.debug.print("Error while trying to execute command: {}\n", .{e});
        return 1;
    };
    return 0;
}

/// This function uses syscalls: chroot, chdir, unshare and mount to prepare the container environment
/// It is a helper function
pub fn containerize() !void {
    _ = linux.chroot("/rootfs");
    _ = linux.chdir("/");
    _ = linux.unshare(linux.CLONE.NEWNS);
    const mount_flags = linux.MS.NOSUID | linux.MS.NOEXEC | linux.MS.NODEV;
    _ = linux.mount("proc", "/proc", "proc", mount_flags, 0);
}

pub fn bgCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var processx = std.process.Child.init(args, allocator);

    processx.stdin_behavior = .Ignore;
    processx.stdout_behavior = .Pipe;
    processx.stderr_behavior = .Pipe;

    try processx.spawn();
    std.debug.print("New process(# {}) running.\n", .{processx.id});
}

pub fn isRunning(pid: i32) bool {
    return linux.kill(pid, 0) == 0;
}

pub fn itCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var processx = std.process.Child.init(args, allocator);

    processx.stdin_behavior = .Inherit;
    processx.stdout_behavior = .Inherit;
    processx.stderr_behavior = .Inherit;

    const result = try processx.spawnAndWait();

    switch (result) {
        .Exited => {},
        .Signal => |sig| std.debug.print("Process exited with signal {}.\n", .{sig}),
        else => |e| std.debug.print("Unexpected behavior. Error:{}\n", .{e}),
    }
}

pub fn copyFiles(source: []const u8, dest: []const u8) !void {
    var current_path = try std.fs.cwd().openDir(source, .{ .iterate = true });
    var dest_path = try std.fs.cwd().openDir(dest, .{});

    const it = current_path.iterate();
    while (try it.next()) |entryx| {
        try dest_path.copyFile(current_path, entryx.name, dest_path, entryx.name, .{});
    }
}
