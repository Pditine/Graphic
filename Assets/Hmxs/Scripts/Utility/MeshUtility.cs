using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace Hmxs.Scripts
{
	public static class MeshUtility
	{
		public enum SmoothNormalChannel
		{
			VertexColor,
			Tangent,
			UV1,
			UV2,
			UV3,
			UV4
		}

		public static Mesh SmoothNormal(Mesh mesh, SmoothNormalChannel channel = SmoothNormalChannel.UV4,
			bool createNewMesh = false, string path = null)
		{
			if (!createNewMesh && !mesh.isReadable)
			{
				Debug.LogWarning($"{mesh.name} is not readable, consider creating a new mesh");
				return null;
			}

			mesh = createNewMesh ? CopyMesh(mesh) : mesh;

			// calculate average normals
			var averageNormalsDic = new Dictionary<Vector3, Vector3>();
			for (int i = 0; i < mesh.vertexCount; i++)
			{
				var vertex = mesh.vertices[i];
				var normal = mesh.normals[i];
				if (!averageNormalsDic.TryAdd(vertex, normal))
					averageNormalsDic[vertex] += normal;
			}

			averageNormalsDic = averageNormalsDic.ToDictionary(kvp => kvp.Key, kvp => kvp.Value.normalized);

			// assign average normals
			var newNormals = new Vector3[mesh.vertexCount];
			for (int i = 0; i < mesh.vertexCount; i++)
				newNormals[i] = averageNormalsDic[mesh.vertices[i]];

			// assign new normals to the mesh
			switch (channel)
			{
				case SmoothNormalChannel.VertexColor:
				{
					var colors = new Color[mesh.vertexCount];
					for (int i = 0; i < mesh.vertexCount; i++)
					{
						var r = (newNormals[i].x + 1) / 2;
						var g = (newNormals[i].y + 1) / 2;
						var b = (newNormals[i].z + 1) / 2;
						colors[i] = new Color(r, g, b, 1);
					}
					mesh.colors = colors;
					break;
				}
				case SmoothNormalChannel.Tangent:
				{
					var tangents = new Vector4[mesh.vertexCount];
					for (int i = 0; i < mesh.vertexCount; i++)
						tangents[i] = new Vector4(newNormals[i].x, newNormals[i].y, newNormals[i].z, 1);
					mesh.tangents = tangents;
					break;
				}
				case SmoothNormalChannel.UV1:
				case SmoothNormalChannel.UV2:
				case SmoothNormalChannel.UV3:
				case SmoothNormalChannel.UV4:
				{
					var uvIndex = channel switch
					{
						SmoothNormalChannel.UV1 => 1,
						SmoothNormalChannel.UV2 => 2,
						SmoothNormalChannel.UV3 => 3,
						SmoothNormalChannel.UV4 => 4,
						SmoothNormalChannel.VertexColor => throw new ArgumentOutOfRangeException(nameof(channel), channel, null),
						SmoothNormalChannel.Tangent => throw new ArgumentOutOfRangeException(nameof(channel), channel, null),
						_ => throw new ArgumentOutOfRangeException(nameof(channel), channel, null)
					};
					mesh.SetUVs(uvIndex, newNormals);
					break;
				}
				default:
					throw new ArgumentOutOfRangeException(nameof(channel), channel, null);
			}

			return mesh;
		}

		private static Mesh CopyMesh(Mesh source)
		{
			Mesh mesh = new Mesh
			{
				vertices = source.vertices,
				normals = source.normals,
				tangents = source.tangents,
				uv = source.uv,
				uv2 = source.uv2,
				uv3 = source.uv3,
				uv4 = source.uv4,
				colors = source.colors,
				colors32 = source.colors32,
				triangles = source.triangles,
				bindposes = source.bindposes,
				boneWeights = source.boneWeights
			};
			if (source.blendShapeCount > 0)
			{
				for (int i = 0; i < source.blendShapeCount; i++)
				{
					string shapeName = source.GetBlendShapeName(i);
					int frameCount = source.GetBlendShapeFrameCount(i);
					for (int j = 0; j < frameCount; j++)
					{
						Vector3[] deltaVertices = new Vector3[source.vertexCount];
						Vector3[] deltaNormals = new Vector3[source.vertexCount];
						Vector3[] deltaTangents = new Vector3[source.vertexCount];
						float frameWeight = source.GetBlendShapeFrameWeight(i, j);
						source.GetBlendShapeFrameVertices(i, j, deltaVertices, deltaNormals, deltaTangents);
						mesh.AddBlendShapeFrame(shapeName, frameWeight, deltaVertices, deltaNormals, deltaTangents);
					}
				}
			}

			mesh.subMeshCount = source.subMeshCount;
			if (mesh.subMeshCount > 1)
				for (int i = 0; i < mesh.subMeshCount; i++)
					mesh.SetTriangles(source.GetTriangles(i), i);
			return mesh;
		}
	}
}
