using System;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;

namespace Hmxs.Outline.Scripts
{
	public class ShowMesh : MonoBehaviour
	{
		[Flags]
		private enum SmoothNormalBitmask
		{
			VertexColor = 1 << 0,
			Tangent = 1 << 1,
			UV1 = 1 << 2,
			UV2 = 1 << 3,
			UV3 = 1 << 4,
			UV4 = 1 << 5,
			Normal = 1 << 6,
			All = 0b1111111
		}

		[EnumToggleButtons]
		[SerializeField] private SmoothNormalBitmask showFlag = SmoothNormalBitmask.UV4;
		[SerializeField] private float length = 0.1f;

		private void OnDrawGizmos()
		{
			var meshFilter = GetComponent<MeshFilter>();
			if (meshFilter == null) return;
			var mesh = meshFilter.sharedMesh;
			if (mesh == null) return;

			Gizmos.color = Color.white;
			var vertices = mesh.vertices;
			for (int j = 0; j < mesh.vertexCount; j++)
			{
				vertices[j] = transform.TransformPoint(vertices[j]);
			}
			if (showFlag.HasFlag(SmoothNormalBitmask.VertexColor))
			{
				var colors = mesh.colors;
				if (vertices.Length == colors.Length)
				{
					for (int i = 0; i < mesh.vertexCount; i++)
					{
						var normal = new Vector3(colors[i].r * 2 - 1, colors[i].g * 2 - 1, colors[i].b * 2 - 1);
						Gizmos.DrawLine(vertices[i], vertices[i] + normal * length);
					}
				}
			}

			if (showFlag.HasFlag(SmoothNormalBitmask.Tangent))
			{
				var tangents = mesh.tangents;
				if (vertices.Length == tangents.Length)
				{
					for (int i = 0; i < mesh.vertexCount; i++)
					{
						var normal = new Vector3(tangents[i].x, tangents[i].y, tangents[i].z);
						Gizmos.DrawLine(vertices[i], vertices[i] + normal * length);
					}
				}
			}

			if (showFlag.HasFlag(SmoothNormalBitmask.UV1))
			{
				var normals = new List<Vector3>();
				mesh.GetUVs(1, normals);
				if (vertices.Length == normals.Count)
				{
					for (int i = 0; i < mesh.vertexCount; i++)
					{
						var normal = normals[i];
						Gizmos.DrawLine(vertices[i], vertices[i] + normal * length);
					}
				}
			}

			if (showFlag.HasFlag(SmoothNormalBitmask.UV2))
			{
				var normals = new List<Vector3>();
				mesh.GetUVs(2, normals);
				if (vertices.Length == normals.Count)
				{
					for (int i = 0; i < mesh.vertexCount; i++)
					{
						var normal = normals[i];
						Gizmos.DrawLine(vertices[i], vertices[i] + normal * length);
					}
				}
			}

			if (showFlag.HasFlag(SmoothNormalBitmask.UV3))
			{
				var normals = new List<Vector3>();
				mesh.GetUVs(3, normals);
				if (vertices.Length == normals.Count)
				{
					for (int i = 0; i < mesh.vertexCount; i++)
					{
						var normal = normals[i];
						Gizmos.DrawLine(vertices[i], vertices[i] + normal * length);
					}
				}
			}

			if (showFlag.HasFlag(SmoothNormalBitmask.UV4))
			{
				var normals = new List<Vector3>();
				mesh.GetUVs(4, normals);
				if (vertices.Length == normals.Count)
				{
					for (int i = 0; i < mesh.vertexCount; i++)
					{
						var normal = normals[i];
						Gizmos.DrawLine(vertices[i], vertices[i] + normal * length);
					}
				}
			}

			if (showFlag.HasFlag(SmoothNormalBitmask.Normal))
			{
				for (int i = 0; i < mesh.vertexCount; i++)
				{
					var normal = mesh.normals[i];
					Gizmos.DrawLine(vertices[i], vertices[i] + normal * length);
				}
			}

		}
	}
}
