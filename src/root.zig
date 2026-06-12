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
        flags: AllocatorCreateFlags,
        instance: u64,
        physical_device: u64,
        device: u64,
        get_instance_proc_addr: c.PFN_vkGetInstanceProcAddr,
        get_device_proc_addr: c.PFN_vkGetDeviceProcAddr,
        api_version: u32,
    };

    pub fn init(opts: Options) !Allocator {
        var vulkan_functions = std.mem.zeroes(c.VmaVulkanFunctions);
        vulkan_functions.vkGetInstanceProcAddr = @ptrCast(opts.get_instance_proc_addr);
        vulkan_functions.vkGetDeviceProcAddr = @ptrCast(opts.get_device_proc_addr);

        var vma_create_info = std.mem.zeroes(c.VmaAllocatorCreateInfo);
        vma_create_info.flags = @bitCast(opts.flags);
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

    pub fn deinit(self: *const Allocator) void {
        c.vmaDestroyAllocator(self.handle);
    }
};

pub const Buffer = struct {
    handle: c.VkBuffer,
    allocation: c.VmaAllocation,
    size: usize,

    pub fn init(allocator: *const Allocator, buffer_create_info: anytype, create_flags: AllocationCreateFlags, usage: MemoryUsage) !Buffer {
        var alloc_create_info = std.mem.zeroes(c.VmaAllocationCreateInfo);
        alloc_create_info.flags = @bitCast(create_flags);
        alloc_create_info.usage = @bitCast(@intFromEnum(usage));
        var buffer: c.VkBuffer = undefined;
        var allocation: c.VmaAllocation = undefined;
        const result = c.vmaCreateBuffer(
            allocator.handle,
            @ptrCast(buffer_create_info),
            &alloc_create_info,
            &buffer,
            &allocation,
            null,
        );
        if (result != c.VK_SUCCESS) {
            return error.VmaBufferCreationFailed;
        }
        return Buffer{ .handle = buffer, .allocation = allocation, .size = buffer_create_info.size };
    }

    pub fn deinit(self: *const Buffer, allocator: *const Allocator) void {
        c.vmaDestroyBuffer(allocator.handle, self.handle, self.allocation);
    }

    pub fn map(self: *const Buffer, allocator: *const Allocator) ![]u8 {
        var data: ?*anyopaque = null;
        const result = c.vmaMapMemory(allocator.handle, self.allocation, &data);
        if (result != c.VK_SUCCESS) {
            return error.VmaBufferMappingFailed;
        }
        const ptr: [*]u8 = @ptrCast(data.?);
        return ptr[0..self.size];
    }

    pub fn unmap(self: *const Buffer, allocator: *const Allocator) void {
        c.vmaUnmapMemory(allocator.handle, self.allocation);
    }

    pub fn invalidate(self: *const Buffer, allocator: *const Allocator) !void {
        const result = c.vmaInvalidateAllocation(allocator.handle, self.allocation, 0, self.size);
        if (result != c.VK_SUCCESS) {
            return error.VmaBufferInvalidationFailed;
        }
    }
};

pub const AllocatorCreateFlags = packed struct(u32) {
    externally_synchronized: bool = false,
    khr_dedicated_allocation: bool = false,
    khr_bind_memory2: bool = false,
    ext_memory_budget: bool = false,
    amd_device_coherent_memory: bool = false,
    buffer_device_address: bool = false,
    ext_memory_priority: bool = false,
    khr_maintenance4: bool = false,
    khr_maintenance5: bool = false,
    khr_external_memory_win32: bool = false,
    _reserved_bit_10: bool = false,
    _reserved_bit_11: bool = false,
    _reserved_bit_12: bool = false,
    _reserved_bit_13: bool = false,
    _reserved_bit_14: bool = false,
    _reserved_bit_15: bool = false,
    _reserved_bit_16: bool = false,
    _reserved_bit_17: bool = false,
    _reserved_bit_18: bool = false,
    _reserved_bit_19: bool = false,
    _reserved_bit_20: bool = false,
    _reserved_bit_21: bool = false,
    _reserved_bit_22: bool = false,
    _reserved_bit_23: bool = false,
    _reserved_bit_24: bool = false,
    _reserved_bit_25: bool = false,
    _reserved_bit_26: bool = false,
    _reserved_bit_27: bool = false,
    _reserved_bit_28: bool = false,
    _reserved_bit_29: bool = false,
    _reserved_bit_30: bool = false,
    _reserved_bit_31: bool = false,
};

pub const MemoryUsage = enum(c_int) {
    unknown = c.VMA_MEMORY_USAGE_UNKNOWN,
    gpu_only = c.VMA_MEMORY_USAGE_GPU_ONLY,
    cpu_only = c.VMA_MEMORY_USAGE_CPU_ONLY,
    cpu_to_gpu = c.VMA_MEMORY_USAGE_CPU_TO_GPU,
    gpu_to_cpu = c.VMA_MEMORY_USAGE_GPU_TO_CPU,
    cpu_copy = c.VMA_MEMORY_USAGE_CPU_COPY,
    gpu_lazily_allocated = c.VMA_MEMORY_USAGE_GPU_LAZILY_ALLOCATED,
    auto = c.VMA_MEMORY_USAGE_AUTO,
    auto_prefer_device = c.VMA_MEMORY_USAGE_AUTO_PREFER_DEVICE,
    auto_prefer_host = c.VMA_MEMORY_USAGE_AUTO_PREFER_HOST,
};

pub const AllocationCreateFlags = packed struct(u32) {
    dedicated_memory: bool = false,
    never_allocate: bool = false,
    mapped: bool = false,
    _reserved_bit_3: bool = false,
    _reserved_bit_4: bool = false,
    user_data_copy_string: bool = false,
    upper_address: bool = false,
    dont_bind: bool = false,
    within_budget: bool = false,
    can_alias: bool = false,
    host_access_sequential_write: bool = false,
    host_access_random: bool = false,
    host_access_allow_transfer_instead: bool = false,
    _reserved_bit_13: bool = false,
    _reserved_bit_14: bool = false,
    _reserved_bit_15: bool = false,
    strategy_min_memory: bool = false,
    strategy_min_time: bool = false,
    strategy_min_offset: bool = false,
    _reserved_bit_19: bool = false,
    _reserved_bit_20: bool = false,
    _reserved_bit_21: bool = false,
    _reserved_bit_22: bool = false,
    _reserved_bit_23: bool = false,
    _reserved_bit_24: bool = false,
    _reserved_bit_25: bool = false,
    _reserved_bit_26: bool = false,
    _reserved_bit_27: bool = false,
    _reserved_bit_28: bool = false,
    _reserved_bit_29: bool = false,
    _reserved_bit_30: bool = false,
    _reserved_bit_31: bool = false,
};

pub const Image = struct {
    handle: c.VkImage,
    allocation: c.VmaAllocation,

    pub fn init(
        allocator: *const Allocator,
        image_create_info: anytype,
        create_flags: AllocationCreateFlags,
        memory_usage: MemoryUsage,
    ) !Image {
        var alloc_create_info = std.mem.zeroes(c.VmaAllocationCreateInfo);
        alloc_create_info.flags = @bitCast(create_flags);
        alloc_create_info.usage = @bitCast(@intFromEnum(memory_usage));
        var handle: c.VkImage = undefined;
        var allocation: c.VmaAllocation = undefined;
        const result = c.vmaCreateImage(
            allocator.handle,
            @ptrCast(image_create_info),
            &alloc_create_info,
            &handle,
            &allocation,
            null,
        );
        if (result != c.VK_SUCCESS) {
            return error.VmaImageCreationFailed;
        }
        return Image{ .handle = handle, .allocation = allocation };
    }

    pub fn deinit(self: *const Image, allocator: *const Allocator) void {
        c.vmaDestroyImage(allocator.handle, self.handle, self.allocation);
    }

    pub fn map(self: *const Image, allocator: *const Allocator, size: usize) ![]u8 {
        var data: ?*anyopaque = null;
        const result = c.vmaMapMemory(allocator.handle, self.allocation, &data);
        if (result != c.VK_SUCCESS) {
            return error.VmaImageMappingFailed;
        }
        const ptr: [*]u8 = @ptrCast(data.?);
        return ptr[0..size];
    }

    pub fn unmap(self: *const Image, allocator: *const Allocator) void {
        c.vmaUnmapMemory(allocator.handle, self.allocation);
    }

    pub fn invalidate(self: *const Image, allocator: *const Allocator, size: usize) !void {
        const result = c.vmaInvalidateAllocation(allocator.handle, self.allocation, 0, size);
        if (result != c.VK_SUCCESS) {
            return error.VmaImageInvalidationFailed;
        }
    }
};
