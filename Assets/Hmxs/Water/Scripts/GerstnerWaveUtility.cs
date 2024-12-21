using UnityEngine;

namespace Hmxs.Water.Scripts.Editor
{
	public static class GerstnerWaveUtility
	{
		private static Vector3 GerstnerWave(Vector3 position, float steepness, float wavelength, float speed, float direction)
		{
			direction = direction * 2 - 1;
			Vector2 d = new Vector2(Mathf.Cos(Mathf.PI * direction), Mathf.Sin(Mathf.PI * direction)).normalized;
			float k = 2 * Mathf.PI / wavelength;
			float a = steepness / k;
			float f = k * (Vector2.Dot(d, new Vector2(position.x, position.z)) - speed * Time.time);

			return new Vector3(d.x * a * Mathf.Cos(f), a * Mathf.Sin(f), d.y * a * Mathf.Cos(f));
		}

		public static Vector3 GetWave(Vector3 position, float steepness, float wavelength, float speed, Vector4 directions)
		{
			Vector3 offset = Vector3.zero;

			offset += GerstnerWave(position, steepness, wavelength, speed, directions.x);
			offset += GerstnerWave(position, steepness, wavelength, speed, directions.y);
			offset += GerstnerWave(position, steepness, wavelength, speed, directions.z);
			offset += GerstnerWave(position, steepness, wavelength, speed, directions.w);

			return offset;
		}
	}
}
