using System;
using System.IO;
using Sirenix.OdinInspector;
using UnityEditor;
using UnityEngine;

namespace Hmxs.Scripts.Water
{
    public class WaterManager : MonoBehaviour
    {
        [Title("References")]
        [OnValueChanged("SetMaterial")]
        [SerializeField] private MeshRenderer water;
        [OnValueChanged("SetMaterial")]
        [SerializeField] private Material waterMaterial;

        [Title("Settings")]
        [OnValueChanged("UpdateWaterColorTexture")]
        [SerializeField] private Vector2Int waterColorTextureSize = new(128, 4);
        [OnValueChanged("UpdateWaterColorTexture")]
        [SerializeField] private Gradient waterColorGradient;

        #region Cached References

        private static readonly int WaterColorTex = Shader.PropertyToID("_WaterColorTex");

        #endregion

        private void SetMaterial() => water.material = waterMaterial;

        private Texture2D UpdateWaterColorTexture(bool applyTexture = true)
        {
            // create texture
            var texture = new Texture2D(waterColorTextureSize.x, waterColorTextureSize.y, TextureFormat.ARGB32, false, false)
            {
                name = "_WaterColorGradientTex",
                wrapMode = TextureWrapMode.Clamp,
                filterMode = FilterMode.Point
            };
            for (int w = 0; w < waterColorTextureSize.x; w++)
            for (int h = 0; h < waterColorTextureSize.y; h++)
                texture.SetPixel(w, h, waterColorGradient.Evaluate((float) w / waterColorTextureSize.x));
            texture.Apply(false);

            // assign it to material
            if (applyTexture) waterMaterial.SetTexture(WaterColorTex, texture);
            return texture;
        }

#if UNITY_EDITOR

        [Button(SdfIconType.Save)]
        private void SaveWaterColorTexture()
        {
            // save it to disk
            var texture = UpdateWaterColorTexture(false);
            if (texture == null)
            {
                Debug.LogError("Failed to get water color texture");
                return;
            }
            string targetFolder = Path.GetDirectoryName(AssetDatabase.GetAssetPath(waterMaterial));
            if (string.IsNullOrEmpty(targetFolder))
            {
                Debug.LogError("Failed to get target folder.");
                return;
            }
            string path = Path.Combine(targetFolder, $"{waterMaterial.name}_{texture.name}.png");
            try
            {
                byte[] pngData = texture.EncodeToPNG();
                if (pngData == null)
                {
                    Debug.LogError("Failed to encode texture to PNG.");
                    return;
                }
                File.WriteAllBytes(path, pngData);
                AssetDatabase.Refresh();
                AssetDatabase.ImportAsset(path, ImportAssetOptions.Default);
                texture = (Texture2D)AssetDatabase.LoadAssetAtPath(path, typeof(Texture2D));
                texture.wrapMode = TextureWrapMode.Clamp;
                texture.filterMode = FilterMode.Point;
                if (texture != null)
                    waterMaterial.SetTexture(WaterColorTex, texture);
                else
                    Debug.LogError("Failed to load texture from path.");
            }
            catch (Exception e)
            {
                Debug.LogError($"An error occurred: {e.Message}");
            }
        }

#endif
    }
}