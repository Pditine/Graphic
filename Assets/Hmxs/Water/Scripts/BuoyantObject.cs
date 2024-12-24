using System;
using Sirenix.OdinInspector;
using UnityEngine;

namespace Hmxs.Water.Scripts.Editor
{
	public class BuoyantObject : MonoBehaviour
	{
		[Header("Water")]
		[SerializeField] private float waterHeight;

		[Title("WaveSetting")]
		[SerializeField] [ReadOnly] private float steepness;
		[SerializeField] [ReadOnly] private float wavelength;
		[SerializeField] [ReadOnly] private float speed;
		[SerializeField] [ReadOnly] private Vector4 direction;

		[Button]
		private void UpdateWaveSetting() => WaterManager.Instance.GetWaveSetting(out steepness, out wavelength, out speed, out direction);

		private Vector3 _initialPosition;

		private void Start() => _initialPosition = transform.position;

		private void Update()
		{
			Vector3 offset = GerstnerWaveUtility.GetWave(_initialPosition, steepness, wavelength, speed, direction);
			offset.y += waterHeight;
			transform.position = _initialPosition + offset;
		}
	}
}
