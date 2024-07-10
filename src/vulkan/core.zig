const std = @import("std");
const c = @import("../bind.zig").c;
const truetype = @import("../font/core.zig");
const wayland = @import("../wayland/core.zig");
const math = @import("../math.zig");

const Window = wayland.Wayland;
const Font = truetype.TrueType;

var ARENA = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ALLOCATOR = ARENA.allocator();


pub const GraphicsPipeline = struct {
    handle: c.VkPipeline,
    layout: c.VkPipelineLayout,
    render_pass: c.VkRenderPass,
    global_pool: c.VkDescriptorPool,
    global_layout: c.VkDescriptorSetLayout,
    texture_pool: c.VkDescriptorPool,
    texture_layout: c.VkDescriptorSetLayout,
    format: c.VkSurfaceFormatKHR,
};

const Swapchain = struct {
    handle: c.VkSwapchainKHR,
    images: []c.VkImage,
    image_views: []c.VkImageView,
    framebuffers: []c.VkFramebuffer,

    render_finished: c.VkSemaphore,
    image_available: c.VkSemaphore,
    in_flight: c.VkFence,

    capabilities: c.VkSurfaceCapabilitiesKHR,
    extent: c.VkExtent2D,
    image_count: u32,

    allocator: std.mem.Allocator,
};

const CommandPool = struct {
    handle: c.VkCommandPool,
    buffers: []c.VkCommandBuffer,
    allocator: std.mem.Allocator,
};

const TextureData = struct {
    positions: Buffer,
    dst: [][5]u32,
    capacity: u32,
};

pub const Painter = struct {
    index_buffer: Buffer,
    uniform: Uniform,

    char_coords: Buffer,
    chars: []TextureData,
    char_texture: Image,
    char_texture_descriptor: TextureDescriptor,

    plain_elements: TextureData,

    general_coords: Buffer,
    general_texture: Image,
    general_texture_descriptor: TextureDescriptor,

    allocator: std.mem.Allocator,
};

const Buffer = struct {
    handle: c.VkBuffer,
    memory: c.VkDeviceMemory,
};

const TextureDescriptor = struct {
    sampler: c.VkSampler,
    set: c.VkDescriptorSet,
};

const Image = struct {
    handle: c.VkImage,
    memory: c.VkDeviceMemory,
    view: c.VkImageView,
    width: u32,
    height: u32,
};

const Uniform = struct {
    buffer: Buffer,
    set: c.VkDescriptorSet,
    dst: []f32,
};


fn read_file(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const end_pos = try file.getEndPos();
    const content = try ALLOCATOR.alloc(u8, end_pos);
    if (try file.read(content) < end_pos) return error.IncompleteContetent;

    return content;
}

fn create_shader_module(device_dispatch: *const DeviceDispatch, path: []const u8) c.VkShaderModule {
    const code = read_file(path) catch blk: {
        std.debug.print("could not read file content", .{});
        break :blk "";
    };
    const info = c.VkShaderModuleCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .codeSize = code.len,
        .pCode = @as([*]const u32, @ptrCast(@alignCast(code))),
    };

    var shader_module: c.VkShaderModule = undefined;
    if (0 != device_dispatch.vkCreateShaderModule(device_dispatch.handle, &info, null, &shader_module)) {
        std.debug.print("could not create shader module", .{});
    }

    return shader_module;
}

pub fn graphics_pipeline_init(
    instance_dispatch: *const InstanceDispatch,
    device_dispatch: *const DeviceDispatch,
) !GraphicsPipeline {
    var graphics_pipeline: GraphicsPipeline = undefined;

    const vert_module = create_shader_module(device_dispatch, "zig-out/shader/vert.spv");
    defer device_dispatch.vkDestroyShaderModule(device_dispatch.handle, vert_module, null);

    const frag_module = create_shader_module(device_dispatch, "zig-out/shader/frag.spv");
    defer device_dispatch.vkDestroyShaderModule(device_dispatch.handle, frag_module, null);

    const name = "main";

    const shader_stage_infos = &[_]c.VkPipelineShaderStageCreateInfo {
        .{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
            .pName = name,
            .module = vert_module,
        },
        .{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
            .pName = name,
            .module = frag_module,
        },
    };

    const dynamic_states = &[_]c.VkDynamicState { c.VK_DYNAMIC_STATE_VIEWPORT, c.VK_DYNAMIC_STATE_SCISSOR };
    const dynamic_state_info = c.VkPipelineDynamicStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .pDynamicStates = dynamic_states.ptr,
        .dynamicStateCount = dynamic_states.len,
    };

    const coords_binding_description = c.VkVertexInputBindingDescription {
        .binding = 0,
        .stride = @sizeOf(f32) * 2,
        .inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX,
    };

    const coords_attribute_description = c.VkVertexInputAttributeDescription {
        .binding = 0,
        .location = 0,
        .format = c.VK_FORMAT_R32G32_SFLOAT,
        .offset = 0,
    };

    const position_binding_description = c.VkVertexInputBindingDescription {
        .binding = 1,
        .stride = @sizeOf(u32) * 5,
        .inputRate = c.VK_VERTEX_INPUT_RATE_INSTANCE,
    };

    const position_attribute_description = c.VkVertexInputAttributeDescription {
        .binding = 1,
        .location = 1,
        .format = c.VK_FORMAT_R32G32_UINT,
        .offset = 0,
    };

    const color_attribute_description = c.VkVertexInputAttributeDescription {
        .binding = 1,
        .location = 2,
        .format = c.VK_FORMAT_R32G32B32_UINT,
        .offset = @sizeOf(u32) * 2,
    };

    const binding_descriptions = &[_]c.VkVertexInputBindingDescription {
        coords_binding_description,
        position_binding_description,
    };

    const attribute_descriptions = &[_]c.VkVertexInputAttributeDescription {
        coords_attribute_description,
        position_attribute_description,
        color_attribute_description,
    };

    const input_state_info = c.VkPipelineVertexInputStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .pVertexBindingDescriptions = binding_descriptions.ptr,
        .vertexBindingDescriptionCount = binding_descriptions.len,
        .pVertexAttributeDescriptions = attribute_descriptions.ptr,
        .vertexAttributeDescriptionCount = attribute_descriptions.len,
    };

    const input_assembly_state_info = c.VkPipelineInputAssemblyStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        .primitiveRestartEnable = c.VK_FALSE,
    };

    const viewport = c.VkViewport {
        .x = 0.0,
        .y = 0.0,
        .width = 1920.0,
        .height = 1080.0,
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };

    const scissor = c.VkRect2D {
        .offset = c.VkOffset2D {
            .x = 0,
            .y = 0,
        },
        .extent = c.VkExtent2D {
            .width = 1920,
            .height = 1080,
        }
    };

    const viewport_state_info = c.VkPipelineViewportStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .viewportCount = 1,
        .pViewports = &viewport,
        .scissorCount = 1,
        .pScissors = &scissor
    };

    const rasterize_state_info = c.VkPipelineRasterizationStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .cullMode = c.VK_CULL_MODE_BACK_BIT,
        .frontFace = c.VK_FRONT_FACE_CLOCKWISE,
        .polygonMode = c.VK_POLYGON_MODE_FILL,
        .depthBiasEnable = c.VK_FALSE,
        .depthClampEnable = c.VK_FALSE,
        .rasterizerDiscardEnable = c.VK_FALSE,
        .lineWidth = 1.0,
        .depthBiasClamp = 0.0,
        .depthBiasConstantFactor = 0.0,
    };

    const multisampling_state_info = c.VkPipelineMultisampleStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .pSampleMask = null,
        .alphaToOneEnable = c.VK_FALSE,
        .sampleShadingEnable = c.VK_FALSE,
        .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
        .alphaToCoverageEnable = c.VK_FALSE,
        .minSampleShading = 1.0,
    };

    const color_blend_attachment = c.VkPipelineColorBlendAttachmentState {
        .blendEnable = c.VK_TRUE,
        .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT | c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
        .srcColorBlendFactor = c.VK_BLEND_FACTOR_SRC_ALPHA,
        .dstColorBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
        .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
        .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ZERO,
        .colorBlendOp = c.VK_BLEND_OP_ADD,
        .alphaBlendOp = c.VK_BLEND_OP_ADD,
    };

    const color_blend_state_info = c.VkPipelineColorBlendStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .logicOp = c.VK_LOGIC_OP_COPY,
        .logicOpEnable = c.VK_FALSE,
        .blendConstants = .{ 0.0, 0.0, 0.0, 0.0 },
        .attachmentCount = 1,
        .pAttachments = &color_blend_attachment,
    };

    const depth_stencil_state_info = c.VkPipelineDepthStencilStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
        .maxDepthBounds = 1.0,
        .minDepthBounds = 0.0,
        .depthCompareOp = c.VK_COMPARE_OP_LESS,
        .depthTestEnable = c.VK_FALSE,
        .depthWriteEnable = c.VK_FALSE,
        .stencilTestEnable = c.VK_FALSE,
        .depthBoundsTestEnable = c.VK_FALSE,
    };

    const global_binding = c.VkDescriptorSetLayoutBinding {
        .binding = 0,
        .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
    };

    const global_layout_info = c.VkDescriptorSetLayoutCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = 1,
        .pBindings = &global_binding,
    };

    _ = device_dispatch.vkCreateDescriptorSetLayout(device_dispatch.handle, &global_layout_info, null, &graphics_pipeline.global_layout);

    const texture_binding = c.VkDescriptorSetLayoutBinding {
        .binding = 0,
        .stageFlags = c.VK_SHADER_STAGE_FRAGMENT_BIT,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        .descriptorCount = 1,
    };

    const texture_layout_info = c.VkDescriptorSetLayoutCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = 1,
        .pBindings = &texture_binding,
    };

    _ = device_dispatch.vkCreateDescriptorSetLayout(device_dispatch.handle, &texture_layout_info, null, &graphics_pipeline.texture_layout);

    // const push_constant = c.VkPushConstantRange {
    //   .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
    //   .offset = 0,
    //   .size = @sizeOf(f32) * 2,
    // };

    const set_layouts = [_]c.VkDescriptorSetLayout {
        graphics_pipeline.global_layout,
        graphics_pipeline.texture_layout
    };

    const layout_info = c.VkPipelineLayoutCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .pushConstantRangeCount = 0,
        .pPushConstantRanges = null,
        .setLayoutCount = set_layouts.len,
        .pSetLayouts = &set_layouts,
    };

    _ = device_dispatch.vkCreatePipelineLayout(device_dispatch.handle, &layout_info, null, &graphics_pipeline.layout);

    const global_pool_size = c.VkDescriptorPoolSize {
        .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 16,
    };

    const global_pool_info = c.VkDescriptorPoolCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = 1,
        .pPoolSizes = &global_pool_size,
        .maxSets = 16,
    };

    _ = device_dispatch.vkCreateDescriptorPool(device_dispatch.handle, &global_pool_info, null, &graphics_pipeline.global_pool);

    const texture_pool_size = c.VkDescriptorPoolSize {
        .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        .descriptorCount = 16,
    };

    const texture_pool_info = c.VkDescriptorPoolCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = 1,
        .pPoolSizes = &texture_pool_size,
        .maxSets = 16,
    };

    _ = device_dispatch.vkCreateDescriptorPool(device_dispatch.handle, &texture_pool_info, null, &graphics_pipeline.texture_pool);

    graphics_pipeline.format = blk: {
        var count: u32 = 0;
        _ = instance_dispatch.vkGetPhysicalDeviceSurfaceFormatsKHR(device_dispatch.physical_device, instance_dispatch.surface, &count, null);
        const formats = try ALLOCATOR.alloc(c.VkSurfaceFormatKHR, count);
        _ = instance_dispatch.vkGetPhysicalDeviceSurfaceFormatsKHR(device_dispatch.physical_device, instance_dispatch.surface, &count, formats.ptr);

        const format = for (formats) |format| {
            if (format.format == c.VK_FORMAT_R8G8B8A8_SRGB and format.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) break format;
        } else formats[0];

        break :blk format;
    };

    const render_pass_attachment = c.VkAttachmentDescription {
        .format = graphics_pipeline.format.format,
        .samples = c.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
        .finalLayout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
    };

    const subpass = c.VkSubpassDescription {
        .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = &.{
            .attachment = 0,
            .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        },
    };

    const dependency = c.VkSubpassDependency {
        .srcSubpass = c.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcAccessMask = 0,
        .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | c.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
        .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
    };

    const render_pass_info = c.VkRenderPassCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = 1,
        .pAttachments = &render_pass_attachment,
        .subpassCount = 1,
        .pSubpasses = &subpass,
        .dependencyCount = 1,
        .pDependencies = &dependency,
    };

    _ = device_dispatch.vkCreateRenderPass(device_dispatch.handle, &render_pass_info, null, &graphics_pipeline.render_pass);

    const graphics_pipeline_info = c.VkGraphicsPipelineCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        .stageCount = shader_stage_infos.len,
        .pStages = shader_stage_infos.ptr,
        .pVertexInputState = &input_state_info,
        .pInputAssemblyState = &input_assembly_state_info,
        .pViewportState = &viewport_state_info,
        .pRasterizationState = &rasterize_state_info,
        .pMultisampleState = &multisampling_state_info,
        .pDepthStencilState = &depth_stencil_state_info,
        .pColorBlendState = &color_blend_state_info,
        .pDynamicState = &dynamic_state_info,
        .layout = graphics_pipeline.layout,
        .renderPass = graphics_pipeline.render_pass,
    };

    _ = device_dispatch.vkCreateGraphicsPipelines(device_dispatch.handle, null, 1, &graphics_pipeline_info, null, &graphics_pipeline.handle);

    return graphics_pipeline;
}

pub fn swapchain_init(
    instance_dispatch: *const InstanceDispatch,
    device_dispatch: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    window: *const Window,
    allocator: std.mem.Allocator,
) !Swapchain {
    var swapchain: Swapchain = undefined;
    swapchain.handle = null;

    const semaphore_info = c.VkSemaphoreCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    const fence_info = c.VkFenceCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
    };

    _ = device_dispatch.vkCreateSemaphore(device_dispatch.handle, &semaphore_info, null, &swapchain.render_finished);
    _ = device_dispatch.vkCreateFence(device_dispatch.handle, &fence_info, null, &swapchain.in_flight);

    _ = instance_dispatch.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device_dispatch.physical_device, instance_dispatch.surface, &swapchain.capabilities);

    swapchain.image_count = if (swapchain.capabilities.maxImageCount > 0) @min(swapchain.capabilities.minImageCount + 1, swapchain.capabilities.maxImageCount)
  else swapchain.capabilities.minImageCount + 1;

    swapchain.images = try allocator.alloc(c.VkImage, swapchain.image_count);
    swapchain.image_views = try allocator.alloc(c.VkImageView, swapchain.image_count);
    swapchain.framebuffers = try allocator.alloc(c.VkFramebuffer, swapchain.image_count);
    swapchain.allocator = allocator;

    swapchain_init_aux(
        &swapchain,
        instance_dispatch,
        device_dispatch,
        graphics_pipeline,
        window,
    );

    return swapchain;
}

fn recreate_swapchain(
    swapchain: *Swapchain,
    instance_dispatch: *const InstanceDispatch,
    device_dispatch: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    window: *const Window,
) void {
    swapchain_init_aux(
        swapchain,
        instance_dispatch,
        device_dispatch,
        graphics_pipeline,
        window,
    );
}

fn swapchain_init_aux(
    swapchain: *Swapchain,
    instance_dispatch: *const InstanceDispatch,
    device_dispatch: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    window: *const Window,
) void {
    swapchain.extent = c.VkExtent2D {
        .width = window.width,
        .height = window.height,
    };

    const present_mode = c.VK_PRESENT_MODE_FIFO_KHR;

    var unique_families: [4]u32 = undefined;
    var family_count: u32 = 0;
    {
        var last_value: u32 = 255;
        for (device_dispatch.families) |family| {
            if (family != last_value) {
                unique_families[family_count] = family;
                last_value = family;
                family_count += 1;
            }
        }
    }

    const old_swapchain = swapchain.handle;

    const info = c.VkSwapchainCreateInfoKHR {
        .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = instance_dispatch.surface,
        .minImageCount = swapchain.image_count,
        .imageFormat = graphics_pipeline.format.format,
        .imageColorSpace = graphics_pipeline.format.colorSpace,
        .imageExtent = swapchain.extent,
        .imageSharingMode = if (family_count > 1) c.VK_SHARING_MODE_CONCURRENT else c.VK_SHARING_MODE_EXCLUSIVE,
        .presentMode = present_mode,
        .preTransform = swapchain.capabilities.currentTransform,
        .clipped = c.VK_TRUE,
        .imageArrayLayers = 1,
        .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .queueFamilyIndexCount = family_count,
        .pQueueFamilyIndices = &unique_families[0],
        .oldSwapchain = old_swapchain,
    };

    _ = device_dispatch.vkCreateSwapchainKHR(device_dispatch.handle, &info, null, &swapchain.handle);
    _ = device_dispatch.vkGetSwapchainImagesKHR(device_dispatch.handle, swapchain.handle, &swapchain.image_count, swapchain.images.ptr);

    if (old_swapchain) |_| {
        for (0..swapchain.image_count) |i| {
            device_dispatch.vkDestroyImageView(device_dispatch.handle, swapchain.image_views[i], null);
            device_dispatch.vkDestroyFramebuffer(device_dispatch.handle, swapchain.framebuffers[i], null);
        }

        device_dispatch.vkDestroySemaphore(device_dispatch.handle, swapchain.image_available, null);
        device_dispatch.vkDestroySwapchainKHR(device_dispatch.handle, old_swapchain, null);
    }

    for (0..swapchain.image_count) |i| {
        swapchain.image_views[i] = image_view_init(device_dispatch, swapchain.images[i], graphics_pipeline.format.format);

        const framebuffer_info = c.VkFramebufferCreateInfo {
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = graphics_pipeline.render_pass,
            .attachmentCount = 1,
            .pAttachments = &swapchain.image_views[i],
            .width = swapchain.extent.width,
            .height = swapchain.extent.height,
            .layers = 1,
        };

        _ = device_dispatch.vkCreateFramebuffer(device_dispatch.handle, &framebuffer_info, null, &swapchain.framebuffers[i]);
    }

    const semaphore_info = c.VkSemaphoreCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    _ = device_dispatch.vkCreateSemaphore(device_dispatch.handle, &semaphore_info, null, &swapchain.image_available);
}

pub fn command_pool_init(
    device: *const DeviceDispatch,
    swapchain: *const Swapchain,
    allocator: std.mem.Allocator,
) !CommandPool {
    var command_pool: CommandPool = undefined;

    const info = c.VkCommandPoolCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = device.families[0],
    };

    _ = device.vkCreateCommandPool(device.handle, &info, null, &command_pool.handle);

    const count = swapchain.framebuffers.len;
    command_pool.buffers = try allocator.alloc(c.VkCommandBuffer, count);
    command_pool.allocator = allocator;

    {
        const buffers_info = c.VkCommandBufferAllocateInfo {
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .commandPool = command_pool.handle,
            .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
            .commandBufferCount = @intCast(count),
        };

        _ = device.vkAllocateCommandBuffers(device.handle, &buffers_info, &command_pool.buffers[0]);
    }

    return command_pool;
}

const CHAR_COUNT: u32 = 95;
pub fn painter_init(
    device: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    command_pool: *const CommandPool,
    window: *const Window,
    font: *const Font,
    allocator: std.mem.Allocator,
) !Painter {
    var painter: Painter = undefined;

    const global_binding = 0;
    const uniform_data = [_]f32 { window.scale, font.scale, font.x_ratio };
    painter.uniform = uniform_buffer_init(
        f32,
        device,
        &uniform_data,
        graphics_pipeline.global_pool,
        graphics_pipeline.global_layout,
        global_binding
    );

    const glyph_width = truetype.normalized_width(font);
    const glyph_height = truetype.normalized_height(font);

    var coords: [CHAR_COUNT][4][2]f32 = undefined;
    painter.chars = try allocator.alloc(TextureData, CHAR_COUNT);
    painter.allocator = allocator;

    const initial_allocation_count: u32 = 10;
    for (0..CHAR_COUNT) |i| {
        const offset = truetype.glyph_normalized_offset(font, i);

        coords[i] = .{
            .{ offset[0], offset[1] },
            .{ offset[0] + glyph_width, offset[1] },
            .{ offset[0], offset[1] + glyph_height},
            .{ offset[0] + glyph_width, offset[1] + glyph_height },
        };

        painter.chars[i].positions = buffer_init(
            [5]u32,
            device,
            c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
            c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            initial_allocation_count
        );

        _ = device.vkMapMemory(device.handle, painter.chars[i].positions.memory, 0, initial_allocation_count * @sizeOf([5]u32), 0, @ptrCast(&painter.chars[i].dst));
        painter.chars[i].capacity = initial_allocation_count;
        painter.chars[i].dst.len = 0;
    }

    const general_coords: [4][2]f32 = .{
        .{ 0.0, 0.0 },
        .{ 1.0, 0.0 },
        .{ 0.0, 1.0 },
        .{ 1.0, 1.0 },
    };

    painter.plain_elements.positions = buffer_init(
        [5]u32,
        device,
        c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        10
    );

    _ = device.vkMapMemory(device.handle, painter.plain_elements.positions.memory, 0, 10 * @sizeOf([5]u32), 0, @ptrCast(&painter.plain_elements.dst));
    painter.plain_elements.dst.len = 0;
    painter.plain_elements.capacity = 10;

    painter.char_coords = buffer_init(
        [4][2]f32,
        device,
        c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        coords.len
    );

    painter.general_coords = buffer_init(
        [4][2]f32,
        device,
        c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        1
    );

    const indices = [_]u16 { 0, 1, 2, 1, 3, 2 };
    painter.index_buffer = buffer_init(
        u16,
        device,
        c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
        c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        indices.len
    );

    painter.char_texture = image_init(
        device,
        c.VK_FORMAT_R8_UNORM,
        c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_SAMPLED_BIT,
        font.bitmap.width,
        font.bitmap.height
    );

    var plain_elements_texture = [_]u8 { 100 } ** 256;

    painter.general_texture = image_init(
        device,
        c.VK_FORMAT_R8_UNORM,
        c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_SAMPLED_BIT,
        16,
        16,
    );

    copy_data_to_buffer([4][2]f32, device, &painter.char_coords, command_pool, &coords);
    copy_data_to_buffer([2]f32, device, &painter.general_coords, command_pool, &general_coords);
    copy_data_to_buffer(u16, device, &painter.index_buffer, command_pool, &indices);
    copy_data_to_image(device, &painter.char_texture, command_pool, font.bitmap.handle);
    copy_data_to_image(device, &painter.general_texture, command_pool, &plain_elements_texture);

    painter.char_texture_descriptor = texture_descriptor_init(device, graphics_pipeline, &painter.char_texture);
    painter.general_texture_descriptor = texture_descriptor_init(device, graphics_pipeline, &painter.general_texture);

    return painter;
}

fn update_painter_plain_elements(device: *const DeviceDispatch, painter: *Painter, window: *const Window) void {
    painter.plain_elements.dst.len = 1;
    const offset = wayland.get_offset(window);

    if (wayland.is_selection_active(window)) {
        const lines = wayland.get_selected_lines(window);
        const selection_boundary = wayland.get_selection_boundary(window);

        const len = selection_boundary[1].y + 1 - selection_boundary[0].y;
        const cols = window.cols - 1;
        const position_count: u32 = len * cols;

        if (painter.plain_elements.capacity <= position_count + 1) {
            _ = device.vkUnmapMemory(device.handle, painter.plain_elements.positions.memory);
            buffer_deinit(device, &painter.plain_elements.positions);

            painter.plain_elements.positions = buffer_init(
                [5]u32,
                device,
                c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                position_count,
            );

            painter.plain_elements.capacity = position_count;
            _ = device.vkMapMemory(device.handle, painter.plain_elements.positions.memory, 0, (1 + position_count) * @sizeOf([2]u32), 0, @ptrCast(&painter.plain_elements.dst));
        }

        var index: u32 = 1;
        for (0..len) |i| {
            const boundary: [2]u32 = condition: {
                if (i == 0) {
                    break :condition .{
                        math.max(offset[0], selection_boundary[0].x),
                        if (len == 1) selection_boundary[1].x else lines[selection_boundary[0].y].char_count,
                    };
                }
                if (i == len - 1) break :condition .{ math.max(0, offset[0]), selection_boundary[1].x };
                break :condition .{ math.max(0, offset[0]), lines[selection_boundary[0].y + i].char_count };
            };

            const diff = boundary[1] - boundary[0] + 1;
            painter.plain_elements.dst.len += diff;

            const ii: u32 = @intCast(i);
            for (boundary[0]..boundary[1] + 1) |j| {
                const jj: u32 = @intCast(j);
                painter.plain_elements.dst[index] = .{
                    jj - offset[0], ii + selection_boundary[0].y - offset[1],
                    0, 255, 255
                };

                index += 1;
            }
        }
    }

    const cursor_data = wayland.get_cursor_position(window);
    painter.plain_elements.dst[0] = .{
        cursor_data[0] - offset[0], cursor_data[1] - offset[1],
        255, 255, 255
    };
}

fn update_painter(device: *const DeviceDispatch, painter: *Painter, window: *const Window) void {
    for (0..CHAR_COUNT) |i| {
        const data = wayland.get_char_data(window, i);
        const len: u32 = @intCast(data.pos.len);
        painter.chars[i].dst.len = len;

        if (len == 0) continue;
        if (painter.chars[i].capacity < len) {
            _ = device.vkUnmapMemory(device.handle, painter.chars[i].positions.memory);
            buffer_deinit(device, &painter.chars[i].positions);

            painter.chars[i].positions = buffer_init(
                [5]u32,
                device,
                c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                len,
            );

            painter.chars[i].capacity = len;
            _ = device.vkMapMemory(device.handle, painter.chars[i].positions.memory, 0, len * @sizeOf([5]u32), 0, @ptrCast(&painter.chars[i].dst));
        }

        for (0..len) |k| {
            painter.chars[i].dst[k] = data.pos[k];
        }
    }
}

fn texture_descriptor_init(
    device: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    image: *const Image
) TextureDescriptor {
    var handle: TextureDescriptor = undefined;

    handle.sampler = sampler_init(device);
    handle.set = allocate_descriptor_set(device, graphics_pipeline.texture_pool, graphics_pipeline.texture_layout);
    update_image_descriptor_set(device, image.view, handle.sampler, handle.set);

    return handle;
}

fn image_init(
    device: *const DeviceDispatch,
    format: u32,
    usage: u32,
    width: u32,
    height: u32
) Image {
    var image: Image = undefined;

    const info = c.VkImageCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .imageType = c.VK_IMAGE_TYPE_2D,
        .mipLevels = 1,
        .arrayLayers = 1,
        .tiling = c.VK_IMAGE_TILING_OPTIMAL,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
        .samples = c.VK_SAMPLE_COUNT_1_BIT,

        .usage = usage,
        .format = format,
        .extent = c.VkExtent3D {
            .width = width,
            .height = height,
            .depth = 1,
        },
    };

    image.width = width;
    image.height = height;

    _ = device.vkCreateImage(device.handle, &info, null, &image.handle);

    var memory_requirements: c.VkMemoryRequirements = undefined;
    device.vkGetImageMemoryRequirements(device.handle, image.handle, &memory_requirements);

    image.memory = allocate_device_memory(device, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &memory_requirements);
    _ = device.vkBindImageMemory(device.handle, image.handle, image.memory, 0);

    image.view = image_view_init(device, image.handle, format);

    return image;
}

fn update_image_descriptor_set(
    device: *const DeviceDispatch,
    view: c.VkImageView,
    sampler: c.VkSampler,
    set: c.VkDescriptorSet
) void {
    const info = c.VkDescriptorImageInfo {
        .imageLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        .imageView = view,
        .sampler = sampler,
    };

    const write = c.VkWriteDescriptorSet {
        .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        .dstSet = set,
        .dstBinding = 0,
        .descriptorCount = 1,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        .pImageInfo = &info,
    };

    device.vkUpdateDescriptorSets(device.handle, 1, &.{ write }, 0, null);
}

fn sampler_init(device: *const DeviceDispatch) c.VkSampler {
    const info = c.VkSamplerCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
        .magFilter = c.VK_FILTER_LINEAR,
        .minFilter = c.VK_FILTER_LINEAR,
        .addressModeU = c.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeV = c.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeW = c.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .anisotropyEnable = c.VK_FALSE,
        .maxAnisotropy = 1.0,
        .borderColor = c.VK_BORDER_COLOR_INT_OPAQUE_BLACK,
        .unnormalizedCoordinates = c.VK_FALSE,
        .compareEnable = c.VK_FALSE,
        .compareOp = c.VK_COMPARE_OP_ALWAYS,
        .mipmapMode = c.VK_SAMPLER_MIPMAP_MODE_LINEAR,
        .mipLodBias = 0.0,
        .minLod = 0.0,
        .maxLod = 0.0,
    };

    var handle: c.VkSampler = undefined;
    _ = device.vkCreateSampler(device.handle, &info, null, &handle);

    return handle;
}

pub fn sync(device: *const DeviceDispatch, swapchain: *const Swapchain) void {
    std.time.sleep(1000000 * 20);
    _ = device.vkWaitForFences(device.handle, 1, &swapchain.in_flight, c.VK_TRUE, 0xFFFFFF);
    _ = device.vkQueueWaitIdle(device.queues[0]);
}

pub fn draw_frame(
    swapchain: *Swapchain,
    instance: *const InstanceDispatch,
    device: *const DeviceDispatch,
    command_pool: *const CommandPool,
    graphics_pipeline: *const GraphicsPipeline,
    window: *const Window,
    painter: *Painter,
) void {
    const start = std.time.Instant.now() catch return;

    var image_index: u32 = 0;
    var result = device.vkAcquireNextImageKHR(device.handle, swapchain.handle, 0xFFFFFF, swapchain.image_available, null, &image_index);

    while (result == c.VK_SUBOPTIMAL_KHR or result == c.VK_ERROR_OUT_OF_DATE_KHR) {
        recreate_swapchain(swapchain, instance, device, graphics_pipeline, window);
        result = device.vkAcquireNextImageKHR(device.handle, swapchain.handle, 0xFFFFFF, swapchain.image_available, null, &image_index);
        painter.uniform.dst[0] = window.scale;
    }

    update_painter_plain_elements(device, painter, window);
    update_painter(device, painter, window);
    record_draw_command(
        device,
        graphics_pipeline,
        command_pool,
        swapchain,
        painter,
        image_index,
    );

    _ = device.vkResetFences(device.handle, 1, &swapchain.in_flight);

    const wait_dst_stage: u32 = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    const submit_info = c.VkSubmitInfo {
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &swapchain.image_available,
        .pWaitDstStageMask = &wait_dst_stage,
        .commandBufferCount = 1,
        .pCommandBuffers = &command_pool.buffers[image_index],
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &swapchain.render_finished,
    };

    _ = device.vkQueueSubmit(device.queues[0], 1, &submit_info, swapchain.in_flight);

    const present_info = c.VkPresentInfoKHR {
        .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .swapchainCount = 1,
        .pSwapchains = &swapchain.handle,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &swapchain.render_finished,
        .pImageIndices = &image_index,
    };

    _ = device.vkQueuePresentKHR(device.queues[1], &present_info);

    const end = std.time.Instant.now() catch return;
    std.debug.print("time for draw frame: {} ns\n", .{end.since(start)});
}

fn record_draw_command(
    device: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    command_pool: *const CommandPool,
    swapchain: *const Swapchain,
    painter: *const Painter,
    index: u32,
) void {
    const command_buffer = command_pool.buffers[index];
    const framebuffer = swapchain.framebuffers[index];

    const width = swapchain.extent.width;
    const height = swapchain.extent.height;

    const begin_info = c.VkCommandBufferBeginInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
    };

    const clear_value = c.VkClearValue {
        .color = .{
            .float32 = .{ 0.0, 0.0, 0.0, 1.0 },
        },
    };

    const render_pass_info = c.VkRenderPassBeginInfo {
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = graphics_pipeline.render_pass,
        .framebuffer = framebuffer,
        .renderArea = c.VkRect2D {
            .offset = c.VkOffset2D {
                .x = 0,
                .y = 0,
            },
            .extent = c.VkExtent2D {
                .width = width,
                .height = height,
            },
        },
        .pClearValues = &clear_value,
        .clearValueCount = 1,
    };

    const viewport = c.VkViewport {
        .x = 0.0,
        .y = 0.0,
        .width = @floatFromInt(width),
        .height = @floatFromInt(height),
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };

    const scissor = c.VkRect2D {
        .offset = c.VkOffset2D {
            .x = 0,
            .y = 0,
        },
        .extent = c.VkExtent2D {
            .width = width,
            .height = height,
        },
    };

    _ = device.vkBeginCommandBuffer(command_buffer, &begin_info);

    device.vkCmdBeginRenderPass(command_buffer, &render_pass_info, c.VK_SUBPASS_CONTENTS_INLINE);
    device.vkCmdSetViewport(command_buffer, 0, 1, &viewport);
    device.vkCmdSetScissor(command_buffer, 0, 1, &scissor);
    device.vkCmdBindPipeline(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.handle);
    device.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.layout, 0, 2, &.{ painter.uniform.set, painter.char_texture_descriptor.set }, 0, &0);
    device.vkCmdBindIndexBuffer(command_buffer, painter.index_buffer.handle, 0, c.VK_INDEX_TYPE_UINT16);

    for (0..CHAR_COUNT) |i| {
        const len: u32 = @intCast(painter.chars[i].dst.len);
        if (len == 0) continue;

        const vertex_offsets = &[_]u64 { @sizeOf(f32) * 4 * 2 * i, 0 };
        const vertex_buffers = &[_]c.VkBuffer { painter.char_coords.handle, painter.chars[i].positions.handle };

        device.vkCmdBindVertexBuffers(command_buffer, 0, vertex_buffers.len, &vertex_buffers[0], &vertex_offsets[0]);
        device.vkCmdDrawIndexed(command_buffer, 6, len, 0, 0, 0);
    }

    const vertex_offsets = &[_]u64 { 0, 0 };
    const vertex_buffers = &[_]c.VkBuffer { painter.general_coords.handle, painter.plain_elements.positions.handle };

    device.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.layout, 0, 2, &.{ painter.uniform.set, painter.general_texture_descriptor.set }, 0, &0);
    device.vkCmdBindVertexBuffers(command_buffer, 0, vertex_buffers.len, &vertex_buffers[0], &vertex_offsets[0]);
    device.vkCmdDrawIndexed(command_buffer, 6, @intCast(painter.plain_elements.dst.len), 0, 0, 0);

    device.vkCmdEndRenderPass(command_buffer);
    _ = device.vkEndCommandBuffer(command_buffer);
}

fn image_view_init(device: *const DeviceDispatch, image: c.VkImage, format: u32) c.VkImageView {
    const sub = c.VkImageSubresourceRange {
        .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
        .baseMipLevel = 0,
        .levelCount = 1,
        .baseArrayLayer = 0,
        .layerCount = 1,
    };

    const comp = c.VkComponentMapping {
        .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
    };

    const info = c.VkImageViewCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
        .subresourceRange = sub,
        .components = comp,

        .image = image,
        .format = format,
    };

    var image_view: c.VkImageView = undefined;
    _ = device.vkCreateImageView(device.handle, &info, null, &image_view);

    return image_view;
}

fn copy_data_to_image(
    device: *const DeviceDispatch,
    image: *const Image,
    command_pool: *const CommandPool,
    data: []const u8,
) void {
    var dst: []u8 = undefined;
    const len: u32 = @intCast(data.len);

    const buffer = buffer_init(u8, device, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);
    _ = device.vkMapMemory(device.handle, buffer.memory, 0, len * @sizeOf(u8), 0, @ptrCast(&dst));

    copy(u8, data, &dst);

    const sub = c.VkImageSubresourceRange {
        .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
        .baseMipLevel = 0,
        .levelCount = 1,
        .layerCount = 1,
        .baseArrayLayer = 0,
    };

    const barrier = c.VkImageMemoryBarrier {
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .oldLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .newLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .image = image.handle,
        .subresourceRange = sub,
        .srcAccessMask = 0,
        .dstAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT,
    };

    const image_sub = c.VkImageSubresourceLayers {
        .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
        .mipLevel = 0,
        .baseArrayLayer = 0,
        .layerCount = 1,
    };

    const offset = c.VkOffset3D {
        .x = 0, .y = 0, .z = 0,
    };

    const extent = c.VkExtent3D {
        .width = image.width,
        .height = image.height,
        .depth = 1,
    };

    const region = c.VkBufferImageCopy {
        .bufferOffset = 0,
        .bufferRowLength = 0,
        .bufferImageHeight = 0,
        .imageSubresource = image_sub,
        .imageOffset = offset,
        .imageExtent = extent,
    };

    const second_barrier = c.VkImageMemoryBarrier {
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .oldLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .newLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .image = image.handle,
        .subresourceRange = sub,
        .srcAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT,
        .dstAccessMask = c.VK_ACCESS_SHADER_READ_BIT,
    };

    const command_buffer = begin_command_buffer(device, command_pool);

    device.vkCmdPipelineBarrier(
        command_buffer,
        c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
        c.VK_PIPELINE_STAGE_TRANSFER_BIT,
        0, 0, null, 0, null, 1, &barrier
    );

    device.vkCmdCopyBufferToImage(
        command_buffer,
        buffer.handle,
        image.handle,
        c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        1, &region
    );

    device.vkCmdPipelineBarrier(
        command_buffer,
        c.VK_PIPELINE_STAGE_TRANSFER_BIT,
        c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
        0, 0, null, 0, null, 1, &second_barrier
    );

    end_command_buffer(device, command_pool, command_buffer);
    _ = device.vkUnmapMemory(device.handle, buffer.memory);
    buffer_deinit(device, &buffer);
}

fn allocate_device_memory(
    device: *const DeviceDispatch,
    properties: u32,
    requirements: *const c.VkMemoryRequirements
) c.VkDeviceMemory {
    var index: u32 = 0;

    for (0..device.physical_device_properties.memoryTypeCount) |i| {
        const a: u5 = @intCast(i);
        const b: u32 = 1;

        if ((requirements.memoryTypeBits & (b << a)) > 0 and (device.physical_device_properties.memoryTypes[i].propertyFlags & properties) == properties) {
            index = @intCast(i);
            break;
        }
    }

    const alloc_info = c.VkMemoryAllocateInfo {
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = requirements.size,
        .memoryTypeIndex = index,
    };

    var memory: c.VkDeviceMemory = undefined;
    _ = device.vkAllocateMemory(device.handle, &alloc_info, null, &memory);

    return memory;
}

fn uniform_buffer_init(
    T: type,
    device: *const DeviceDispatch,
    data: []const T,
    pool: c.VkDescriptorPool,
    layout: c.VkDescriptorSetLayout,
    binding: u32,
) Uniform {
    var uniform: Uniform = undefined;

    const len: u32 = @intCast(data.len);

    uniform.buffer = buffer_init(T, device, c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);

    _ = device.vkMapMemory(device.handle, uniform.buffer.memory, 0, len * @sizeOf(T), 0, @ptrCast(&uniform.dst));

    copy(T, data, &uniform.dst);

    const info = c.VkDescriptorBufferInfo {
        .buffer = uniform.buffer.handle,
        .offset = 0,
        .range = @sizeOf(T) * len,
    };

    uniform.set = allocate_descriptor_set(device, pool, layout);
    const write = c.VkWriteDescriptorSet {
        .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        .dstSet = uniform.set,
        .dstBinding = binding,
        .dstArrayElement = 0,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .pBufferInfo = &info,
        .descriptorCount = 1,
    };

    device.vkUpdateDescriptorSets(device.handle, 1, &.{ write }, 0, null);

    return uniform;
}

fn copy(T: type, src: []const T, dst: *[]T) void {
    @setRuntimeSafety(false);

    const len = src.len;
    dst.*.len = len;

    for (0..len) |i| {
        dst.*[i] = src[i];
    }
}

fn copy_data_to_buffer(
    T: type,
    device: *const DeviceDispatch,
    buffer: *const Buffer,
    command_pool: *const CommandPool,
    data: []const T,
) void {
    var dst: []T = undefined;
    const len: u32 = @intCast(data.len);

    const staging_buffer = buffer_init(T, device, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);
    _ = device.vkMapMemory(device.handle, staging_buffer.memory, 0, len * @sizeOf(T), 0, @ptrCast(&dst));

    copy(T, data, &dst);

    const copy_info = c.VkBufferCopy {
        .srcOffset = 0,
        .dstOffset = 0,
        .size = @sizeOf(T) * len,
    };

    const command_buffer = begin_command_buffer(device, command_pool);

    device.vkCmdCopyBuffer(command_buffer, staging_buffer.handle, buffer.handle, 1, &copy_info);
    device.vkUnmapMemory(device.handle, staging_buffer.memory);

    end_command_buffer(device, command_pool, command_buffer);
    buffer_deinit(device, &staging_buffer);
}

fn end_command_buffer(device: *const DeviceDispatch, command_pool: *const CommandPool, command_buffer: c.VkCommandBuffer) void {
    _ = device.vkEndCommandBuffer(command_buffer);

    const submit_info = c.VkSubmitInfo {
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = &command_buffer,
    };

    _ = device.vkQueueSubmit(device.queues[0], 1, &submit_info, null);
    _ = device.vkQueueWaitIdle(device.queues[0]);
    device.vkFreeCommandBuffers(device.handle, command_pool.handle, 1, &command_buffer);
}

fn begin_command_buffer(device: *const DeviceDispatch, command_pool: *const CommandPool) c.VkCommandBuffer {
    var command_buffer: c.VkCommandBuffer = undefined;

    const alloc_info = c.VkCommandBufferAllocateInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = command_pool.handle,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = 1,
    };

    _ = device.vkAllocateCommandBuffers(device.handle, &alloc_info, &command_buffer);
    const begin_info = c.VkCommandBufferBeginInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    };

    _ = device.vkBeginCommandBuffer(command_buffer, &begin_info);

    return command_buffer;
}

fn allocate_descriptor_set(
    device: *const DeviceDispatch,
    descriptor_pool: c.VkDescriptorPool,
    layout: c.VkDescriptorSetLayout
) c.VkDescriptorSet {
    const info = c.VkDescriptorSetAllocateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .descriptorPool = descriptor_pool,
        .descriptorSetCount = 1,
        .pSetLayouts = &layout,
    };

    var set: c.VkDescriptorSet = undefined;
    _ = device.vkAllocateDescriptorSets(device.handle, &info, &set);

    return set;
}

inline fn buffer_init(
    T: type,
    device: *const DeviceDispatch,
    usage: u32,
    properties: u32,
    len: u32,
) Buffer {
    const info = c.VkBufferCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = @sizeOf(T) * len,
        .usage = usage,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    };

    var buffer: c.VkBuffer = undefined;
    _ = device.vkCreateBuffer(device.handle, &info, null, &buffer);

    var requirements: c.VkMemoryRequirements = undefined;
    _ = device.vkGetBufferMemoryRequirements(device.handle, buffer, &requirements);

    const memory = allocate_device_memory(device, properties, &requirements);
    _ = device.vkBindBufferMemory(device.handle, buffer, memory, 0);

    return .{
        .handle = buffer,
        .memory = memory,
    };
}

fn buffer_deinit(device: *const DeviceDispatch, buffer: *const Buffer) void {
    device.vkDestroyBuffer(device.handle, buffer.handle, null);
    device.vkFreeMemory(device.handle, buffer.memory, null);
}

fn image_deinit(device: *const DeviceDispatch, image: *const Image) void {
    device.vkFreeMemory(device.handle, image.memory, null);
    device.vkDestroyImage(device.handle, image.handle, null);
    device.vkDestroyImageView(device.handle, image.view, null);
}

fn texture_descriptor_deinit(device: *const DeviceDispatch, texture_descriptor: *const TextureDescriptor) void {
    device.vkDestroySampler(device.handle, texture_descriptor.sampler, null);
}

pub fn painter_deinit(device: *const DeviceDispatch, painter: *const Painter) void {
    texture_descriptor_deinit(device, &painter.char_texture_descriptor);
    texture_descriptor_deinit(device, &painter.general_texture_descriptor);
    image_deinit(device, &painter.char_texture);
    image_deinit(device, &painter.general_texture);

    buffer_deinit(device, &painter.uniform.buffer);
    buffer_deinit(device, &painter.char_coords);
    buffer_deinit(device, &painter.general_coords);
    buffer_deinit(device, &painter.index_buffer);

    buffer_deinit(device, &painter.plain_elements.positions);
    for (painter.chars) |char| {
        buffer_deinit(device, &char.positions);
    }

    painter.allocator.free(painter.chars);
}

pub fn command_pool_deinit(device: *const DeviceDispatch, command_pool: *const CommandPool) void {
    const count: u32 = @intCast(command_pool.buffers.len);

    device.vkFreeCommandBuffers(device.handle, command_pool.handle, count, &command_pool.buffers[0]);
    device.vkDestroyCommandPool(device.handle, command_pool.handle, null);

    command_pool.allocator.free(command_pool.buffers);
}

pub fn swapchain_deinit(device: *const DeviceDispatch, swapchain: *const Swapchain) void {
    const count = swapchain.framebuffers.len;

    for (0..count) |i| {
        device.vkDestroyImageView(device.handle, swapchain.image_views[i], null);
        device.vkDestroyFramebuffer(device.handle, swapchain.framebuffers[i], null);
    }

    swapchain.allocator.free(swapchain.framebuffers);
    swapchain.allocator.free(swapchain.image_views);

    device.vkDestroySemaphore(device.handle, swapchain.render_finished, null);
    device.vkDestroySemaphore(device.handle, swapchain.image_available, null);
    device.vkDestroyFence(device.handle, swapchain.in_flight, null);

    device.vkDestroySwapchainKHR(device.handle, swapchain.handle, null);
}

pub fn graphics_pipeline_deinit(dispatch: *const DeviceDispatch, graphics_pipeline: *const GraphicsPipeline) void {
    dispatch.vkDestroyDescriptorPool(dispatch.handle, graphics_pipeline.global_pool, null);
    dispatch.vkDestroyDescriptorSetLayout(dispatch.handle, graphics_pipeline.global_layout, null);
    dispatch.vkDestroyDescriptorPool(dispatch.handle, graphics_pipeline.texture_pool, null);
    dispatch.vkDestroyDescriptorSetLayout(dispatch.handle, graphics_pipeline.texture_layout, null);
    dispatch.vkDestroyPipelineLayout(dispatch.handle, graphics_pipeline.layout, null);
    dispatch.vkDestroyRenderPass(dispatch.handle, graphics_pipeline.render_pass, null);
    dispatch.vkDestroyPipeline(dispatch.handle, graphics_pipeline.handle, null);
}

pub fn device_deinit(device: *const DeviceDispatch) void {
    device.vkDestroyDevice(device.handle, null);
}
