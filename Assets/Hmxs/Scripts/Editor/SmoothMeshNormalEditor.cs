using System.Collections.Generic;
using System.IO;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using UnityEditor;
using UnityEngine;

namespace Hmxs.Scripts.Editor
{
	public class SmoothMeshNormal : OdinEditorWindow
	{
		[MenuItem("Tools/Hmxs/Smooth Mesh Normal")]
		private static void OpenWindow() => GetWindow<SmoothMeshNormal>().Show();

		[SerializeField] private bool enableSelected = true;

		[AssetSelector]
		[SerializeField] private List<Mesh> meshes = new();

		[EnumToggleButtons]
		[SerializeField] private MeshUtility.SmoothNormalChannel channel = MeshUtility.SmoothNormalChannel.UV4;

		[SerializeField] private bool createNewMesh = true;

		[EnableIf("createNewMesh")][FolderPath]
		[SerializeField] private string folder = "Assets/Hmxs/Outline/Mesh";



		 private bool _isProcessing;

		[DisableIf("_isProcessing")]
		[Button]
		private void Smooth()
		{
			if (_isProcessing) return;
			_isProcessing = true;

			if (createNewMesh && !Directory.Exists(folder))
				Directory.CreateDirectory(folder);
			foreach (var mesh in meshes)
			{
				var newMesh = MeshUtility.SmoothNormal(mesh, channel, createNewMesh, folder);
				if (!newMesh)
				{
					Debug.LogWarning($"{mesh.name} failed to smooth");
					continue;
				}
				if (createNewMesh)
				{
					var path = Path.Combine(folder, $"{mesh.name}_Smoothed_{GetChannelName(channel)}.asset");
					AssetDatabase.CreateAsset(newMesh, path);
					AssetDatabase.SaveAssets();
					EditorGUIUtility.PingObject(newMesh);
					AssetDatabase.Refresh();
				}
				else
					EditorUtility.SetDirty(mesh);
			}
			_isProcessing = false;
		}

		private static string GetChannelName(MeshUtility.SmoothNormalChannel currentChannel)
		{
			return currentChannel switch
			{
				MeshUtility.SmoothNormalChannel.VertexColor => "Vertex Color",
				MeshUtility.SmoothNormalChannel.Tangent => "Tangent",
				MeshUtility.SmoothNormalChannel.UV1 => "UV1",
				MeshUtility.SmoothNormalChannel.UV2 => "UV2",
				MeshUtility.SmoothNormalChannel.UV3 => "UV3",
				MeshUtility.SmoothNormalChannel.UV4 => "UV4",
				_ => throw new System.ArgumentOutOfRangeException()
			};
		}

		private void OnSelectionChange()
		{
			if (!enableSelected || _isProcessing) return;

			var obj = Selection.activeObject;
			if (!obj) return;

			switch (obj)
			{
				case Mesh mesh when !meshes.Contains(mesh):
					meshes.Add(mesh);
					break;
				case GameObject gameObject:
				{
					if (gameObject.TryGetComponent(out MeshFilter meshFilter))
						if (meshFilter.sharedMesh)
						{
							if (!meshes.Contains(meshFilter.sharedMesh))
								meshes.Add(meshFilter.sharedMesh);
						}
					break;
				}
				default:
					return;
			}
		}
	}
}
