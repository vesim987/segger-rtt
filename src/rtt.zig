const std = @import("std");

const c = @cImport({
    @cInclude("SEGGER_RTT.h");
});

pub const Mode = enum(c_uint) {
    NoBlockSkip = c.SEGGER_RTT_MODE_NO_BLOCK_SKIP,
    NoBlockTrim = c.SEGGER_RTT_MODE_NO_BLOCK_TRIM,
    BlockIfFifoFull = c.SEGGER_RTT_MODE_BLOCK_IF_FIFO_FULL,
    _,
};

pub fn config_up_buffer(
    config: struct {
        index: c_uint,
        name: [*:0]const u8,
        buffer: ?[]u8 = null,
        mode: Mode,
    },
) void {
    _ = c.SEGGER_RTT_ConfigUpBuffer(
        config.index,
        config.name,
        if (config.buffer) |b| b.ptr else null,
        if (config.buffer) |b| b.len else 0,
        @intFromEnum(config.mode),
    );
}

const WriteError = error{};
const Writer = std.io.Writer(c_uint, WriteError, struct {
    pub fn write(context: c_uint, payload: []const u8) WriteError!usize {
        _ = c.SEGGER_RTT_Write(context, payload.ptr, payload.len);
        return payload.len;
    }
}.write);

var default_log_writter: Writer = .{ .context = 0 };

pub const Time = struct { seconds: u32, microseconds: u32 };
const Getter = fn () Time;
fn default_time_getter() Time {
    return Time{ .seconds = 0, .microseconds = 0 };
}

var time_getter: *const Getter = default_time_getter;

pub fn set_time_getter(comptime getter: Getter) void {
    time_getter = getter;
}

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_prefix = comptime "[{}.{:0>6}] " ++ level.asText();
    const prefix = comptime level_prefix ++ switch (scope) {
        .default => ": ",
        else => " (" ++ @tagName(scope) ++ "): ",
    };

    const time = time_getter();
    default_log_writter.print(prefix ++ format ++ "\r\n", .{ time.seconds, time.microseconds } ++ args) catch {};
}
