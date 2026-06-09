// © 2026 Antonio Caggiano
// SPDX-License-Identifier: MIT
const std = @import("std");

const c = @cImport({
    @cInclude("vk_mem_alloc.h");
});

test "links" {
    const f = &c.vmaCreateAllocator;
    if (@intFromPtr(f) == 0) unreachable;
}

pub const Allocator = struct {
    handle: c.VmaAllocator,

    pub const Options = struct {
        instance: u64,
        physical_device: u64,
        device: u64,
        get_instance_proc_addr: c.PFN_vkGetInstanceProcAddr,
        get_device_proc_addr: c.PFN_vkGetDeviceProcAddr,
        api_version: u32,
    };

    pub fn create(opts: Options) !Allocator {
        var vulkan_functions = std.mem.zeroes(c.VmaVulkanFunctions);
        vulkan_functions.vkGetInstanceProcAddr = @ptrCast(opts.get_instance_proc_addr);
        vulkan_functions.vkGetDeviceProcAddr = @ptrCast(opts.get_device_proc_addr);

        var vma_create_info = std.mem.zeroes(c.VmaAllocatorCreateInfo);
        vma_create_info.instance = @ptrFromInt(opts.instance);
        vma_create_info.physicalDevice = @ptrFromInt(opts.physical_device);
        vma_create_info.device = @ptrFromInt(opts.device);
        vma_create_info.vulkanApiVersion = opts.api_version;
        vma_create_info.pVulkanFunctions = &vulkan_functions;

        var vma: c.VmaAllocator = undefined;
        const result = c.vmaCreateAllocator(&vma_create_info, &vma);
        if (result != c.VK_SUCCESS) {
            return error.VmaAllocatorCreationFailed;
        }
        return Allocator{ .handle = vma };
    }

    pub fn destroy(self: *const Allocator) void {
        c.vmaDestroyAllocator(self.handle);
    }
};
