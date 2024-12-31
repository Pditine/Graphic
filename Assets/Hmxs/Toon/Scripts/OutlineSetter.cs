using System;
using UnityEngine;

namespace Hmxs.Toon.Scripts
{
	public class OutlineSetter : MonoBehaviour
	{
		[SerializeField] private bool enableOutline = true;
		[SerializeField] private uint outlineRenderingLayerMask = 2;

		private MeshRenderer _meshRenderer;
		private uint _originRenderingLayerMask;

		private void Start()
		{
			_meshRenderer = GetComponent<MeshRenderer>();
			if (_meshRenderer)
				_originRenderingLayerMask = _meshRenderer.renderingLayerMask;
		}

		private void OnMouseEnter()
		{
			if (_meshRenderer && enableOutline)
			{
				_meshRenderer.renderingLayerMask |= outlineRenderingLayerMask;
			}
		}

		private void OnMouseExit()
		{
			if (_meshRenderer) _meshRenderer.renderingLayerMask = _originRenderingLayerMask;
		}
	}
}
