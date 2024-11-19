const std = @import("std");
const builtin = @import("builtin");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const assert = std.debug.assert;

const Builtin = enum {
    exit,
    echo,
    type,
};

pub fn main() !void {
    var i: u32 = 0;
    while (true) : (i += 1) {
        var buf: [1024]u8 = undefined;
        try stdout.print("$ ", .{});
        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var command = line;
            if (builtin.os.tag == .windows) {
                command = @constCast(std.mem.trimRight(u8, command, '\r'));
            }
            if (command.len != 0) {
                try handle_input(command);
            } else {
                try stdout.print("\n", .{});
            }
        }
    }
}

fn handler(T: Builtin, args: []const u8) !void {
    switch (T) {
        Builtin.exit => std.process.exit(try std.fmt.parseInt(u8, args, 10)),
        Builtin.echo => try stdout.print("{s}\n", .{args}),
        Builtin.type => try handle_type(args),
    }
}

fn handle_type(args: []const u8) !void {
    const args_type = std.meta.stringToEnum(Builtin, args);
    if (args_type) |@"type"| {
        try stdout.print("{s} is a shell builtin\n", .{@tagName(@"type")});
    } else {
        try stdout.print("{s}: not found\n", .{args});
    }
}
fn handle_input(input: []const u8) !void {
    assert(input.len != 0);
    var input_slices = std.mem.splitScalar(u8, input, ' ');
    const first_arg = input_slices.first();
    const rest_of_input = input_slices.rest();
    const shell_builtin = std.meta.stringToEnum(Builtin, first_arg);

    if (shell_builtin) |bi| {
        try handler(bi, rest_of_input);
    } else {
        try stdout.print("{s}: command not found\n", .{first_arg});
    }
}
