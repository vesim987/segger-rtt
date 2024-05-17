const std = @import("std");

pub fn build(b: *std.Build) void {
    const rtt = b.addModule("rtt", .{
        .root_source_file = b.path("src/rtt.zig"),
    });
    rtt.addCSourceFile(.{
        .file = b.path("RTT/SEGGER_RTT.c"),
    });
    rtt.addIncludePath(b.path("RTT"));
    // rtt.defineCMacro("SEGGER_RTT_SECTION", "\".segger_rtt_section\"");
    // rtt.defineCMacro("SEGGER_RTT_BUFFER_SECTION", "\".segger_rtt_section\"");
}
