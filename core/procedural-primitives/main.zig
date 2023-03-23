const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;
const Renderer = @import("renderer.zig").Renderer;

pub const App = @This();
core: mach.Core,
renderer : Renderer,

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn init(app: *App) !void {
    var allocator = gpa.allocator();
    try app.core.init(allocator, .{ .required_limits = gpu.Limits{
        .max_vertex_buffers = 1,
        .max_vertex_attributes = 2,
        .max_bind_groups = 1,
        .max_uniform_buffers_per_shader_stage = 1,
        .max_uniform_buffer_binding_size = 16 * 1 * @sizeOf(f32),
    } });

    const timer = try mach.Timer.start();

    try app.renderer.init(&app.core, allocator, timer);
    app.renderer.curr_primitive_index = 0;
}

pub fn deinit(app: *App) void {
    defer _ = gpa.deinit();
    defer app.core.deinit();
    defer app.renderer.deinit();
}

pub fn update(app: *App) !bool {
    var iter = app.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space) return true;
                // TODO(Rok Kos): Improve this, maybe even make ImGui for this
                if (ev.key == .right) {
                    app.renderer.curr_primitive_index += 1;
                    app.renderer.curr_primitive_index %= @as(u4,app.renderer.primitives_data.len);
                }
            },
            .close => return true,
            else => {},
        }
    }

    app.renderer.update(&app.core);

    return false;
}
