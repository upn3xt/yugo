// TASK: CREATE A CONTAINER FROM THE INFORMATION RECEIVED ON THE MAPPER. EXPLANATION BELOW
// READ THE MAPPER
// COPY THE FILES TO THE CONTAINER

const std = @import("std");
const linux = std.os.linux;

const ArgsWrapper = struct {
    args: []const []const u8,
};

const Builder = @This();

/// Make is responsible for the creation of the container
/// It's basically where all will happen
pub fn make() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = std.process.argsAlloc(allocator) catch return;

    if (args.len <= 1) {
        std.debug.print("Try a valid command.\n", .{});
        return;
    }

    const command_args = args[1..];
    const wrapper = try allocator.create(ArgsWrapper);
    wrapper.args = command_args;
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
    runCommand(allocator, args) catch |e| {
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

pub fn runCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
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
