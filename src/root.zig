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

pub const Buffer = struct {
    handle: c.VkBuffer,
    allocation: c.VmaAllocation,
    size: usize,

    pub fn create(self: *const Allocator, buffer_create_info: anytype, required_flags: u32) !Buffer {
        var alloc_create_info = std.mem.zeroes(c.VmaAllocationCreateInfo);
        alloc_create_info.requiredFlags = required_flags;
        var buffer: c.VkBuffer = undefined;
        var allocation: c.VmaAllocation = undefined;
        const result = c.vmaCreateBuffer(self.handle, @ptrCast(buffer_create_info), &alloc_create_info, &buffer, &allocation, null);
        if (result != c.VK_SUCCESS) return error.VmaBufferCreationFailed;
        return Buffer{ .handle = buffer, .allocation = allocation, .size = buffer_create_info.size };
    }

    pub fn destroy(self: *const Buffer, allocator: *const Allocator) void {
        c.vmaDestroyBuffer(allocator.handle, self.handle, self.allocation);
    }

    pub fn map(self: *const Buffer, allocator: *const Allocator) ![]u8 {
        var data: ?*anyopaque = null;
        const result = c.vmaMapMemory(allocator.handle, self.allocation, &data);
        if (result != c.VK_SUCCESS) return error.VmaBufferMappingFailed;
        const ptr: [*]u8 = @ptrCast(data.?);
        return ptr[0..self.size];
    }

    pub fn unmap(self: *const Buffer, allocator: *const Allocator) void {
        c.vmaUnmapMemory(allocator.handle, self.allocation);
    }
};
