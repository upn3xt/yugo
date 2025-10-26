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

    const main_command = args[0];
    const path = args[1];
    const extra = args[2..];

    if (eql(u8, main_command, "setup")) {
        _ = std.process.getEnvVarOwned(allocator, "HOME") catch |e| {
            std.debug.print("HOME environment variable was not found.\n", .{});
            return e;
        };
    } else if (eql(u8, main_command, "list")) {
        // list worlds
    } else if (eql(u8, main_command, "build")) {
        // something here
    } else if (eql(u8, main_command, "run")) {
        try run(allocator, path, extra);
    } else if (eql(u8, main_command, "ir")) {
        const pid = try std.fmt.parseInt(i32, extra[0], 10);
        if (isRunning(pid)) {
            std.debug.print("Process is running.\n", .{});
        } else std.debug.print("Process not running.\n", .{});
    } else if (eql(u8, main_command, "help")) {
        std.debug.print("USAGE: yugo <command>\nInvalid command, try \'help\' to see the list of the available commands\n", .{});
    } else {
        std.debug.print("USAGE: yugo <command>\nInvalid command, try \'help\' to see the list of the available commands\n", .{});
    }
    return;
}

/// Runs stuff
pub fn run(allocator: std.mem.Allocator, path: []const u8, args: [][:0]u8) !void {
    const wrapper = try allocator.create(ArgsWrapper);
    wrapper.args = args;

    try copyFiles(path, "/rootfs");
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
    // if (eql(u8, args[0], ""))
    itCommand(allocator, args) catch |e| {
        std.debug.print("Error while trying to execute command: {}\n", .{e});
        return 1;
    };
    // runDetached(allocator, args) catch |e| {
    //     std.debug.print("Error while trying to execute command: {}\n", .{e});
    //     return 1;
    // };
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
        .Exited => _ = try processx.kill(),
        .Signal => |sig| std.debug.print("Process exited with signal {}.\n", .{sig}),
        else => |e| std.debug.print("Unexpected behavior. Error:{}\n", .{e}),
    }
}

pub fn copyFiles(source: []const u8, dest: []const u8) !void {
    var current_path = try std.fs.cwd().openDir(source, .{ .iterate = true });

    var dest_path = try std.fs.cwd().openDir(dest, .{});
    _ = dest_path.openDir(source, .{}) catch {
        try dest_path.makeDir(source);
        return;
    };

    var buf: [1024]u8 = undefined;
    const concatn = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ dest, source });
    const final_path = try std.fs.cwd().openDir(concatn, .{});

    var it = current_path.iterate();
    while (try it.next()) |entryx| {
        const exists = blk: {
            const file = dest_path.openFile(entryx.name, .{}) catch {
                break :blk false;
            };
            defer file.close();
            break :blk true;
        };
        if (exists) {} else current_path.copyFile(entryx.name, final_path, entryx.name, .{}) catch {};
    }
}

pub fn runDetached(allocator: std.mem.Allocator, args: []const []const u8) !void {
    var processx = std.process.Child.init(args, allocator);

    processx.stdin_behavior = .Pipe;
    processx.stdout_behavior = .Inherit;
    processx.stderr_behavior = .Pipe;

    try processx.spawn();
    std.debug.print("{s}\n", .{processx.stdout});
    std.debug.print("New process(# {}) running.\n", .{processx.id});
}
