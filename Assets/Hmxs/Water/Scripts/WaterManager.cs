using Hmxs.Toolkit;
using Sirenix.OdinInspector;
using UnityEngine;
#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
#endif

namespace Hmxs.Water.Scripts.Editor
{
#if UNITY_EDITOR
	[InitializeOnLoad]
#endif
	public class WaterManager : SingletonMono<WaterManager>
	{
		#region Cached References
		private static readonly int WaterColorGradient = Shader.PropertyToID("_WaterColorGradient");
		#endregion

		[Title("References")]
		[OnValueChanged("UpdateMaterial")] [SerializeField] private MeshRenderer water;
		[OnValueChanged("AssignMaterial")] [SerializeField] private Material shaderGraphMaterial;

		[Title("Setting")]
		[InfoBox("Save the water color gradient texture to disk and re-import it to apply changes to the material.")]
		[InfoBox("Other material settings should be set directly in the material.")]
		[OnValueChanged("UpdateMaterial")] [SerializeField] private Vector2Int waterColorTextureSize = new(128, 4);
		[OnValueChanged("UpdateMaterial")] [InlineButton("SaveWaterColorGradient", SdfIconType.Save, " SAVE")] [SerializeField] private Gradient waterColorGradient;
		[FolderPath] [SerializeField] private string gradientTextSavePath;

		private Material _waterMaterial;

		private Texture2D UpdateWaterColorGradient(bool applyTexture = true)
		{
			// create texture
			var texture = new Texture2D(waterColorTextureSize.x, waterColorTextureSize.y, TextureFormat.ARGB32, false,
				false)
			{
				name = "DepthColorGradientTex",
				wrapMode = TextureWrapMode.Clamp,
				filterMode = FilterMode.Point
			};
			for (int w = 0; w < waterColorTextureSize.x; w++)
			for (int h = 0; h < waterColorTextureSize.y; h++)
				texture.SetPixel(w, h, waterColorGradient.Evaluate((float)w / waterColorTextureSize.x));
			texture.Apply(false);

			// assign it to material
			if (applyTexture) _waterMaterial.SetTexture(WaterColorGradient, texture);
			return texture;
		}

		private void AssignMaterial()
		{
			_waterMaterial = shaderGraphMaterial;
			UpdateMaterial();
		}

		[Button(SdfIconType.Archive, Stretch = false)]
		private void UpdateMaterial()
		{
			if (!_waterMaterial)
			{
				Debug.LogError("Water material is not assigned.");
				return;
			}
			water.material = _waterMaterial;
			UpdateWaterColorGradient();
		}

#if UNITY_EDITOR
		static WaterManager()
		{
			EditorSceneManager.sceneSaved += _ => Instance.SaveWaterColorGradient();
		}

		public void SaveWaterColorGradient()
		{
			// save it to disk
			if (string.IsNullOrEmpty(gradientTextSavePath))
			{
				Debug.LogError("Failed to get target folder.");
				return;
			}

			var texture = UpdateWaterColorGradient(false);
			if (!texture)
			{
				Debug.LogError("Failed to get water color texture");
				return;
			}

			string path = Path.Combine(gradientTextSavePath, $"{_waterMaterial.name}_{texture.name}.png");
			byte[] pngData = texture.EncodeToPNG();
			if (pngData == null)
			{
				Debug.LogError("Failed to encode texture to PNG.");
				return;
			}

			File.WriteAllBytes(path, pngData);
			AssetDatabase.Refresh();

			// re-import it from disk
			var importer = AssetImporter.GetAtPath(path) as TextureImporter;
			if (!importer)
			{
				Debug.LogError("Failed to get texture importer.");
				return;
			}

			// ensure texture settings are correct
			importer.textureShape = TextureImporterShape.Texture2D;
			importer.textureType = TextureImporterType.Default;
			importer.wrapMode = TextureWrapMode.Clamp;
			importer.filterMode = FilterMode.Point;
			importer.SaveAndReimport();
			var loadedTexture = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
			if (!loadedTexture)
			{
				Debug.LogError("Failed to load saved texture.");
				return;
			}

			// re-assign it to material
			_waterMaterial.SetTexture(WaterColorGradient, loadedTexture);
			Debug.Log($"Saved water color gradient to {path}");
		}
#endif
	}
}
