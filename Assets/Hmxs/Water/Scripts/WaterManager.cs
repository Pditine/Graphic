using Hmxs.Scripts;
using Sirenix.OdinInspector;
using UnityEngine;
#if UNITY_EDITOR
using System.IO;
#endif

namespace Hmxs.Water.Scripts
{
	public class WaterManager : MonoBehaviour
	{
		#region Cached References

		private static readonly int WaterColorGradient = Shader.PropertyToID("_WaterColorGradient");

		#endregion

		[Title("References")]
		[OnValueChanged("UpdateMaterial")] [SerializeField] private MeshRenderer water;
		[OnValueChanged("UpdateMaterial")] [SerializeField] private Material material;

		[Title("Setting")]
		[InfoBox("Save the water color gradient texture to disk and re-import it to apply changes to the material.")]
		[InfoBox("Other material settings should be set directly in the material.")]
		[OnValueChanged("UpdateMaterial")] [SerializeField] private Vector2Int waterColorTextureSize = new(128, 4);
		[OnValueChanged("UpdateMaterial")] [InlineButton("SaveWaterColorGradient", SdfIconType.Save, " SAVE")] [SerializeField] private Gradient waterColorGradient;
		[FolderPath] [SerializeField] private string gradientTextSavePath;

		private Texture2D UpdateWaterColorGradient(bool applyTexture = true)
		{
			// create texture
			var texture = GradientTextureGenerator.Generate(waterColorGradient, waterColorTextureSize.x, waterColorTextureSize.y, material.name);
			// assign it to material
			if (applyTexture) material.SetTexture(WaterColorGradient, texture);
			return texture;
		}

		[Button(SdfIconType.Archive, Stretch = false)]
		private void UpdateMaterial()
		{
			if (!material)
			{
				Debug.LogError("Water material is not assigned.");
				return;
			}
			if (!water)
			{
				Debug.LogError("Water mesh renderer is not assigned.");
				return;
			}
			water.material = material;
			UpdateWaterColorGradient();
		}

#if UNITY_EDITOR
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

			string path = Path.Combine(gradientTextSavePath, $"{texture.name}.asset");
			var loadedTexture = GradientTextureGenerator.SaveTexture(texture, path);
			if (!loadedTexture)
			{
				Debug.LogError("Failed to load saved texture.");
				return;
			}

			// re-assign it to material
			material.SetTexture(WaterColorGradient, loadedTexture);
			Debug.Log($"Saved water color gradient to {path}");
		}
#endif
	}
}
