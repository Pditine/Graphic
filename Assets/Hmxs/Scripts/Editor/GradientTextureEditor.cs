using System.IO;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using UnityEditor;
using UnityEngine;

namespace Hmxs.Scripts.Editor
{
	public class GradientTextureEditor : OdinEditorWindow
	{
		[MenuItem("Tools/Hmxs/Generate Gradient Texture")]
		private static void OpenWindow() => GetWindow<GradientTextureEditor>().Show();

		[SerializeField] private string texName = "";
		[SerializeField] private Gradient gradient;
		[SerializeField] private int width = 128;
		[SerializeField] private int height = 4;
		[FolderPath]
		[SerializeField] private string folder = "Assets/Hmxs";

		private bool _isGenerating;

		[Button]
		private void Generate()
		{
			if (_isGenerating) return;
			_isGenerating = true;
			var texture = GradientTextureGenerator.Generate(gradient, width, height, texName);
			var path = Path.Combine(folder, $"{texture.name}.asset");
			GradientTextureGenerator.SaveTexture(texture, path);
			_isGenerating = false;
		}
	}
}
