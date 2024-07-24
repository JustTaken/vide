const std = @import("std");

const c = @import("../bind.zig").c;
const util = @import("../util.zig");
const check = @import("result.zig").check;

const Instance = @import("instance.zig").Instance;
const Device = @import("device.zig").Device;

pub const GraphicsPipeline = struct {
    handle: c.VkPipeline,
    layout: c.VkPipelineLayout,
    render_pass: c.VkRenderPass,
    descriptors: [2]Descriptor,
    // global_layout: c.VkDescriptorSetLayout,
    // global_pool: c.VkDescriptorPool,
    // texture_pool: c.VkDescriptorPool,
    // texture_layout: c.VkDescriptorSetLayout,
    format: c.VkSurfaceFormatKHR,

    pub fn init(
        instance: *const Instance,
        device: *const Device,
    ) !GraphicsPipeline {
        var graphics_pipeline: GraphicsPipeline = undefined;
        var buffer: [8000]u8 = undefined;

        const vert_module = try create_shader_module(device, "zig-out/shader/vert.spv", &buffer);
        defer device.dispatch.vkDestroyShaderModule(device.handle, vert_module, null);

        const frag_module = try create_shader_module(device, "zig-out/shader/frag.spv", &buffer);
        defer device.dispatch.vkDestroyShaderModule(device.handle, frag_module, null);

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

        // const coords_binding_description = c.VkVertexInputBindingDescription {
        //     .binding = 0,
        //     .stride = @sizeOf(f32) * 2,
        //     .inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX,
        // };

        // const coords_attribute_description = c.VkVertexInputAttributeDescription {
        //     .binding = 0,
        //     .location = 0,
        //     .format = c.VK_FORMAT_R32G32_SFLOAT,
        //     .offset = 0,
        // };


        const binding_descriptions = &[_]c.VkVertexInputBindingDescription {
            .{
                .binding = 0,
                .stride = @sizeOf(u32) * 4,
                .inputRate = c.VK_VERTEX_INPUT_RATE_INSTANCE,
            },
        };

        const attribute_descriptions = &[_]c.VkVertexInputAttributeDescription {
            .{
                .binding = 0,
                .location = 0,
                .format = c.VK_FORMAT_R32_UINT,
                .offset = 0,
            },
            // .{
            //     .binding = 0,
            //     .location = 1,
            //     .format = c.VK_FORMAT_R32G32_UINT,
            //     .offset = @sizeOf(u32),
            // },
            .{
                .binding = 0,
                .location = 1,
                .format = c.VK_FORMAT_R32G32B32_UINT,
                .offset = @sizeOf(u32) * 1,
            },
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

        try check(device.dispatch.vkCreateDescriptorSetLayout(device.handle, &global_layout_info, null, &graphics_pipeline.descriptors[0].layout));

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

        try check(device.dispatch.vkCreateDescriptorSetLayout(device.handle, &texture_layout_info, null, &graphics_pipeline.descriptors[1].layout));

        const set_layouts = [_]c.VkDescriptorSetLayout {
            graphics_pipeline.descriptors[0].layout,
            graphics_pipeline.descriptors[1].layout,
        };

        const layout_info = c.VkPipelineLayoutCreateInfo {
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .pushConstantRangeCount = 0,
            .pPushConstantRanges = null,
            .setLayoutCount = set_layouts.len,
            .pSetLayouts = &set_layouts,
        };

        try check(device.dispatch.vkCreatePipelineLayout(device.handle, &layout_info, null, &graphics_pipeline.layout));

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

        try check(device.dispatch.vkCreateDescriptorPool(device.handle, &global_pool_info, null, &graphics_pipeline.descriptors[0].pool));

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

        try check(device.dispatch.vkCreateDescriptorPool(device.handle, &texture_pool_info, null, &graphics_pipeline.descriptors[1].pool));

        graphics_pipeline.format = blk: {
            var count: u32 = 0;
            var formats: [20]c.VkSurfaceFormatKHR = undefined;

            try check(instance.dispatch.vkGetPhysicalDeviceSurfaceFormatsKHR(device.physical_device.handle, instance.surface, &count, null));
            try check(instance.dispatch.vkGetPhysicalDeviceSurfaceFormatsKHR(device.physical_device.handle, instance.surface, &count, &formats));

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

        try check(device.dispatch.vkCreateRenderPass(device.handle, &render_pass_info, null, &graphics_pipeline.render_pass));

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

        try check(device.dispatch.vkCreateGraphicsPipelines(device.handle, null, 1, &graphics_pipeline_info, null, &graphics_pipeline.handle));

        return graphics_pipeline;
    }


    pub fn deinit(self: *const GraphicsPipeline, device: *const Device) void {
        for (self.descriptors) |descriptor| {
            descriptor.deinit(device);
        }

        device.dispatch.vkDestroyPipelineLayout(device.handle, self.layout, null);
        device.dispatch.vkDestroyRenderPass(device.handle, self.render_pass, null);
        device.dispatch.vkDestroyPipeline(device.handle, self.handle, null);
    }
};

fn create_shader_module(device: *const Device, comptime path: []const u8, buffer: []u8) !c.VkShaderModule {
    const len = try util.read_file(path, buffer);

    const info = c.VkShaderModuleCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .codeSize = len,
        .pCode = @as([*]const u32, @ptrCast(@alignCast(buffer))),
    };

    var shader_module: c.VkShaderModule = undefined;
    try check(device.dispatch.vkCreateShaderModule(device.handle, &info, null, &shader_module));

    return shader_module;
}

pub const Descriptor = struct {
    pool: c.VkDescriptorPool,
    layout: c.VkDescriptorSetLayout,

    pub fn get_set(
        self: *const Descriptor,
        device: *const Device,
    ) !DescriptorSet {
        const info = c.VkDescriptorSetAllocateInfo {
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = self.pool,
            .descriptorSetCount = 1,
            .pSetLayouts = &self.layout,
        };

        var set: c.VkDescriptorSet = undefined;
        try check(device.dispatch.vkAllocateDescriptorSets(device.handle, &info, &set));

        return DescriptorSet.init(set);
    }

    pub fn deinit(self: *const Descriptor, device: *const Device) void {
        device.dispatch.vkDestroyDescriptorPool(device.handle, self.pool, null);
        device.dispatch.vkDestroyDescriptorSetLayout(device.handle, self.layout, null);
    }
};

pub const DescriptorSet = struct {
    handle: c.VkDescriptorSet,

    fn init(set: c.VkDescriptorSet) DescriptorSet {
        return DescriptorSet {
            .handle = set,
        };
    }

    pub fn update_buffer(
        self: *const DescriptorSet,
        T: type,
        buffer: c.VkBuffer,
        binding: u32,
        len: u32,
        device: *const Device,
    ) void {
        const info = c.VkDescriptorBufferInfo {
            .buffer = buffer,
            .offset = 0,
            .range = @sizeOf(T) * len,
        };

        const write = c.VkWriteDescriptorSet {
            .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = self.handle,
            .dstBinding = binding,
            .dstArrayElement = 0,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            .pBufferInfo = &info,
            .descriptorCount = 1,
        };

        device.dispatch.vkUpdateDescriptorSets(device.handle, 1, &.{ write }, 0, null);
    }

    pub fn update_image(
        self: *const DescriptorSet,
        view: c.VkImageView,
        sampler: c.VkSampler,
        binding: u32,
        device: *const Device,
    ) void {
        const info = c.VkDescriptorImageInfo {
            .imageLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .imageView = view,
            .sampler = sampler,
        };

        const write = c.VkWriteDescriptorSet {
            .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = self.handle,
            .dstBinding = binding,
            .descriptorCount = 1,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .pImageInfo = &info,
        };

        device.dispatch.vkUpdateDescriptorSets(device.handle, 1, &.{ write }, 0, null);
    }
};

