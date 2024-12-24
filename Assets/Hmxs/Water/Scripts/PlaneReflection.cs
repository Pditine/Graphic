using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Hmxs.Water.Scripts.Editor
{
	public class PlaneReflection : MonoBehaviour
	{
		private static readonly int ReflectionTex = Shader.PropertyToID("_ReflectionTex");

		[SerializeField] private Transform reflectionPlane;
		[SerializeField] private int textureSize = 512;
		[SerializeField] private float clipPlaneOffset = 0.07f;
		[SerializeField] private LayerMask reflectLayers = -1;
		[SerializeField] private Material reflectiveMaterial;

		private Camera _mainCamera;
		private Camera _reflectionCamera;
		private RenderTexture _reflectionTexture;
		private DrawingSettings _drawingSettings;
		private FilteringSettings _filteringSettings;

		private void Awake()
		{
			_mainCamera = Camera.main;
			if (_mainCamera == null) throw new Exception("Main camera not found.");

			var reflectionCameraObject = new GameObject("Reflection Camera" + reflectionPlane.GetInstanceID());
			_reflectionCamera = reflectionCameraObject.AddComponent<Camera>();
			_reflectionCamera.aspect = _mainCamera.aspect;
			_reflectionCamera.fieldOfView = _mainCamera.fieldOfView;
			_reflectionCamera.depth = -10;
			_reflectionCamera.enabled = false;

			var cameraData = _reflectionCamera.GetUniversalAdditionalCameraData();
			cameraData.requiresColorOption = CameraOverrideOption.Off;
			cameraData.requiresDepthOption = CameraOverrideOption.Off;
			cameraData.SetRenderer(0);

			_reflectionTexture = new RenderTexture(textureSize, textureSize, 24)
			{
				name = "_Reflection" + reflectionPlane.GetInstanceID(),
				format = RenderTextureFormat.ARGB32
			};

			_reflectionCamera.targetTexture = _reflectionTexture;
			_reflectionCamera.cullingMask = reflectLayers.value;
		}

		private void OnEnable() => RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;
		private void OnDisable() => RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;

		private void OnBeginCameraRendering(ScriptableRenderContext context, Camera currentCamera)
		{
			if (currentCamera.cameraType is CameraType.Reflection or CameraType.Preview) return;

			// Calculate reflection plane
			Vector3 planePosition = reflectionPlane.position;
			Vector3 planeNormal = reflectionPlane.up;
			float d = -Vector3.Dot(planeNormal, planePosition) - clipPlaneOffset;
			Vector4 plane = new Vector4(planeNormal.x, planeNormal.y, planeNormal.z, d); // equation: P * N + D = 0

			// Calculate reflection matrix
			Matrix4x4 reflectionMatrix = CalculateReflectionMatrix(plane);
			_reflectionCamera.worldToCameraMatrix = _mainCamera.worldToCameraMatrix * reflectionMatrix;

			// Calculate near clipping plane
			Vector4 clipPlane = _reflectionCamera.worldToCameraMatrix.inverse.transpose * plane;
			_reflectionCamera.projectionMatrix = _mainCamera.CalculateObliqueMatrix(clipPlane);

			// Render reflection
			GL.invertCulling = true;
			UniversalRenderPipeline.RenderSingleCamera(context, _reflectionCamera);
			GL.invertCulling = false;
			reflectiveMaterial.SetTexture(ReflectionTex, _reflectionTexture);
		}

		private static Matrix4x4 CalculateReflectionMatrix(Vector4 reflectionPlane)
		{
			Matrix4x4 matrix = default(Matrix4x4);
			matrix.m00 = -2 * reflectionPlane.x * reflectionPlane.x + 1;
			matrix.m01 = -2 * reflectionPlane.x * reflectionPlane.y;
			matrix.m02 = -2 * reflectionPlane.x * reflectionPlane.z;
			matrix.m03 = -2 * reflectionPlane.x * reflectionPlane.w;

			matrix.m10 = -2 * reflectionPlane.x * reflectionPlane.y;
			matrix.m11 = -2 * reflectionPlane.y * reflectionPlane.y + 1;
			matrix.m12 = -2 * reflectionPlane.y * reflectionPlane.z;
			matrix.m13 = -2 * reflectionPlane.y * reflectionPlane.w;

			matrix.m20 = -2 * reflectionPlane.z * reflectionPlane.x;
			matrix.m21 = -2 * reflectionPlane.z * reflectionPlane.y;
			matrix.m22 = -2 * reflectionPlane.z * reflectionPlane.z + 1;
			matrix.m23 = -2 * reflectionPlane.z * reflectionPlane.w;

			matrix.m30 = 0; matrix.m31 = 0;
			matrix.m32 = 0; matrix.m33 = 1;
			return matrix;
		}
	}
}
