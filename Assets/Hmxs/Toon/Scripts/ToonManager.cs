using System.IO;
using Hmxs.Scripts;
using Sirenix.OdinInspector;
using UnityEngine;

public class ToonManager : MonoBehaviour
{
	#region Cached References

	private static readonly int ToonDiffuseRamp = Shader.PropertyToID("_DiffuseRamp");

	#endregion

	[Title("References")]
	[OnValueChanged("UpdateMaterial")] [SerializeField] private Material material;
	[OnValueChanged("UpdateMaterial")] [SerializeField] private Vector2Int textureSize = new(128, 4);
	[OnValueChanged("UpdateMaterial")] [InlineButton("SaveRamp", SdfIconType.Save, " SAVE")] [SerializeField] private Gradient diffuseRamp;
	[FolderPath] [SerializeField] private string gradientTextSavePath = "Assets/Hmxs/Toon/Textures";

	[Button(SdfIconType.Archive, Stretch = false)]
	private void UpdateMaterial()
	{
		if (!material)
		{
			Debug.LogError("Material is not assigned.");
			return;
		}
		UpdateRamp();
	}

	private Texture2D UpdateRamp(bool applyTexture = true)
	{
		// create texture
		var texture = GradientTextureGenerator.Generate(diffuseRamp, textureSize.x, textureSize.y, material.name);
		// assign it to material
		if (applyTexture) material.SetTexture(ToonDiffuseRamp, texture);
		return texture;
	}

#if UNITY_EDITOR
	private void SaveRamp()
	{
		// save it to disk
		if (string.IsNullOrEmpty(gradientTextSavePath))
		{
			Debug.LogError("Failed to get target folder.");
			return;
		}

		var texture = UpdateRamp(false);
		if (!texture)
		{
			Debug.LogError("Failed to get ramp texture");
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
		material.SetTexture(ToonDiffuseRamp, loadedTexture);
		Debug.Log($"Saved ramp texture to {path}");
	}
#endif
}
