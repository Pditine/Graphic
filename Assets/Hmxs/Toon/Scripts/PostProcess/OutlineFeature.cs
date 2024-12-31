using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class OutlineFeature : ScriptableRendererFeature
{
    private class OutlineRenderPass : ScriptableRenderPass
    {
        private static readonly List<ShaderTagId> ShaderTagIds = new()
        {
            new ShaderTagId("SRPDefaultUnlit"),
            new ShaderTagId("UniversalForward"),
            new ShaderTagId("UniversalForwardOnly"),
        };
        private static readonly int OutlineMaskPropertyID = Shader.PropertyToID("_OutlineMask");

        private readonly Material _outlineMaterial;
        private readonly FilteringSettings _filteringSettings;
        private readonly MaterialPropertyBlock _propertyBlock;
        private RTHandle _outlineMaskRT;

        public OutlineRenderPass(Material outlineMaterial)
        {
            _outlineMaterial = outlineMaterial;
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            _filteringSettings = new FilteringSettings(RenderQueueRange.all, renderingLayerMask: 2);
            _propertyBlock = new MaterialPropertyBlock();
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ResetTarget();
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.msaaSamples = 1;
            descriptor.depthBufferBits = 0;
            descriptor.colorFormat = RenderTextureFormat.ARGB32;
            RenderingUtils.ReAllocateIfNeeded(ref _outlineMaskRT, descriptor, name: "_OutlineMaskRT");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("Outline Draw Command");

            // Draw Scene to Outline Mask RT
            cmd.SetRenderTarget(_outlineMaskRT);
            cmd.ClearRenderTarget(true, true, Color.clear);
            var drawingSettings = CreateDrawingSettings(ShaderTagIds, ref renderingData, SortingCriteria.None);
            var rendererListParams = new RendererListParams(renderingData.cullResults, drawingSettings, _filteringSettings);
            var renderList = context.CreateRendererList(ref rendererListParams);
            cmd.DrawRendererList(renderList);

            // Draw Outline
            cmd.SetRenderTarget(renderingData.cameraData.renderer.cameraColorTargetHandle);
            _propertyBlock.SetTexture(OutlineMaskPropertyID, _outlineMaskRT);
            cmd.DrawProcedural(Matrix4x4.identity, _outlineMaterial, 0, MeshTopology.Triangles, 3, 1, _propertyBlock);

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public void Dispose()
        {
            _outlineMaskRT?.Release();
            _outlineMaskRT = null;
        }
    }

    [SerializeField] private Material outlineMaterial;
    private OutlineRenderPass _outlineRenderPass;

    private bool IsMaterialValid => outlineMaterial && outlineMaterial.shader && outlineMaterial.shader.isSupported;

    public override void Create()
    {
        if (!IsMaterialValid) return;

        _outlineRenderPass = new OutlineRenderPass(outlineMaterial);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (_outlineRenderPass == null) return;

        renderer.EnqueuePass(_outlineRenderPass);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        _outlineRenderPass?.Dispose();
    }
}


