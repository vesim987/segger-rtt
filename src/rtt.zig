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

    // TODO
    // const current_time = rp2040.time.get_time_since_boot();
    // const seconds = current_time.to_us() / std.time.us_per_s;
    // const microseconds = current_time.to_us() % std.time.us_per_s;

    default_log_writter.print(prefix ++ format ++ "\r\n", .{ 0, 0 } ++ args) catch {};
}

// const current_time = rp2040.time.get_time_since_boot();
// const seconds = current_time.to_us() / std.time.us_per_s;
// const microseconds = current_time.to_us() % std.time.us_per_s;

// (Writer{ .context = {} }).print(prefix ++ format ++ "\r\n", .{ seconds, microseconds } ++ args) catch {};
