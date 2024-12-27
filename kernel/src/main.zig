const std = @import("std");

// Include the header file for the Ultra boot protocol.
const ultra = @cImport(@cInclude("ultra_protocol.h"));

inline fn done() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

fn findAttribute(boot_ctx: *ultra.ultra_boot_context, attr_type: u32) ?*ultra.ultra_attribute_header {
    var i: u32 = 0;
    var attribute = boot_ctx.attributes();

    while (i < boot_ctx.attribute_count) : ({
        i += 1;
        attribute = ultra.ULTRA_NEXT_ATTRIBUTE(attribute);
    }) {
        if (attribute.*.type == attr_type) {
            return attribute;
        }
    }

    return null;
}

// The following function will be our kernel's entry point.
export fn _start(boot_ctx: *ultra.ultra_boot_context) callconv(.C) noreturn {
    // Ensure the bootloader provided us with a framebuffer attribute.
    const framebuffer_attr: *ultra.ultra_framebuffer_attribute = @ptrCast(@alignCast(
        findAttribute(boot_ctx, ultra.ULTRA_ATTRIBUTE_FRAMEBUFFER_INFO) orelse
            @panic("Could not find framebuffer attribute"),
    ));

    // Extract the necessary framebuffer information.
    const address = framebuffer_attr.fb.physical_address;
    const pitch = framebuffer_attr.fb.pitch;

    // Draw a white diagonal line on the framebuffer.
    for (0..100) |i| {
        // Calculate the pixel offset using the framebuffer information we obtained above.
        // We skip `i` scanlines (pitch is provided in bytes) and add `i * 4` to skip `i` pixels forward.
        const pixel_offset = i * pitch + i * 4;

        // Write 0xffffffff to the provided pixel offset to fill it white.
        @as(*u32, @ptrFromInt(address + pixel_offset)).* = 0xffffffff;
    }

    done();
}

// Provide a stub panic handler.
pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, return_addr: ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = return_addr;

    done();
}
