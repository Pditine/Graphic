using UnityEditor;
using UnityEngine;

namespace Hmxs.Scripts
{
	public static class GradientTextureGenerator
	{
		public static Texture2D Generate(Gradient gradient, int width, int height, string name = "")
		{
			var texture = new Texture2D(width, height, TextureFormat.ARGB32, false, false)
			{
				name = $"{name}_GradientTex_{width}x{height}",
				wrapMode = TextureWrapMode.Clamp,
				filterMode = FilterMode.Point
			};
			Color[] colors = new Color[width * height];
			for (int w = 0; w < width; w++)
			for (int h = 0; h < height; h++)
				colors[h * width + w] = gradient.Evaluate((float)w / width);
			texture.SetPixels(colors);
			texture.Apply(false);
			return texture;
		}
#if UNITY_EDITOR
		public static Texture2D SaveTexture(Texture2D texture, string path)
		{
			AssetDatabase.CreateAsset(texture, path);
			AssetDatabase.SaveAssets();
			EditorGUIUtility.PingObject(texture);
			AssetDatabase.Refresh();
			return AssetDatabase.LoadAssetAtPath<Texture2D>(path);
		}
#endif
	}
}
