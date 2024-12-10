using System.IO;
using Sirenix.OdinInspector;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Hmxs.Scripts.Water
{
#if UNITY_EDITOR
	public class WaterManager : MonoBehaviour
	{
		#region Cached References

		private static readonly int PropertyWaterDepthFadeFactor = Shader.PropertyToID("_WaterDepthFadeFactor");
		private static readonly int PropertyWaterColorGradient = Shader.PropertyToID("_WaterColorGradient");
		private static readonly int PropertyHorizonColor = Shader.PropertyToID("_HorizonColor");
		private static readonly int PropertyHorizonDistance = Shader.PropertyToID("_HorizonDistance");

		#endregion

		private enum MaterialType
		{
			ShaderGraph,
			ShaderCode
		}

		[Title("References")]
		[OnValueChanged("UpdateMaterial")] [SerializeField] private MeshRenderer water;
		[OnValueChanged("AssignMaterial")] [SerializeField] private Material shaderGraphMaterial;
		[OnValueChanged("AssignMaterial")] [SerializeField] private Material shaderCodeMaterial;
		[OnValueChanged("AssignMaterial")] [EnumToggleButtons] [SerializeField] private MaterialType materialType;

		[Title("Settings")]
		[OnValueChanged("UpdateMaterial")] [Range(0, 2f)] [SerializeField] private float waterDepthFadeFactor = 1f;
		[Space(15)]
		[OnValueChanged("UpdateMaterial")]
		[SerializeField] private Vector2Int waterColorTextureSize = new(128, 4);
		[OnValueChanged("UpdateMaterial")] [InlineButton("SaveWaterColorGradient", SdfIconType.Save, " SAVE")]
		[SerializeField] private Gradient waterColorGradient;
		[Space(15)]
		[OnValueChanged("UpdateMaterial")] [Range(0, 10f)] [SerializeField] private float horizonDistance = 1f;
		[OnValueChanged("UpdateMaterial")] [ColorUsage(true, true)] [SerializeField] private Color horizonColor;

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
			if (applyTexture) _waterMaterial.SetTexture(PropertyWaterColorGradient, texture);
			return texture;
		}

		private void SaveWaterColorGradient()
		{
			// save it to disk
			var texture = UpdateWaterColorGradient(false);
			if (!texture)
			{
				Debug.LogError("Failed to get water color texture");
				return;
			}

			string targetFolder = Path.GetDirectoryName(AssetDatabase.GetAssetPath(_waterMaterial));
			if (string.IsNullOrEmpty(targetFolder))
			{
				Debug.LogError("Failed to get target folder.");
				return;
			}

			string path = Path.Combine(targetFolder, $"{_waterMaterial.name}_{texture.name}.png");
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
			_waterMaterial.SetTexture(PropertyWaterColorGradient, loadedTexture);
		}

		private void AssignMaterial()
		{
			_waterMaterial = materialType switch
			{
				MaterialType.ShaderGraph => shaderGraphMaterial,
				MaterialType.ShaderCode => shaderCodeMaterial,
				_ => null
			};
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
			_waterMaterial.SetFloat(PropertyWaterDepthFadeFactor, waterDepthFadeFactor);
			UpdateWaterColorGradient();
			_waterMaterial.SetColor(PropertyHorizonColor, horizonColor);
			_waterMaterial.SetFloat(PropertyHorizonDistance, horizonDistance);
		}
	}
#endif
}