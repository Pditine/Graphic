using System;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;

namespace SkySystem
{
    [Serializable]
    public class SkyElement:BaseElement
    {
        [GradientUsage(true)]
        public Gradient daySkyGradient;

        public Gradient nightSkyGradient;
        public Gradient fogColorGradient;
        private Texture2D _skyRampMap;

        public void ManualUpdate(float time)
        {
            Shader.SetGlobalTexture("_SkyRampMap",ApplyGradient(daySkyGradient));
            Shader.SetGlobalTexture("_SkyWorldYRampMap",ApplyGradient(nightSkyGradient));
            RenderSettings.fogColor = fogColorGradient.Evaluate(time/24);
        }
        
        /// <summary>
        /// 把Gradient类信息记录在Texture2D上(内存，未写入文件)
        /// </summary>
        private Texture2D ApplyGradient(Gradient ramp)
        {
            Texture2D tempTex = new Texture2D(256,1,TextureFormat.ARGB32,false,true);
            tempTex.filterMode = FilterMode.Bilinear;
            tempTex.wrapMode = TextureWrapMode.Clamp;
            tempTex.anisoLevel = 1;
            Color[] colors = new Color[256];
            float div = 256.0f;
            for (int i = 0; i < 256; ++i)
            {
                float t = (float)i / div;
                colors[i] = ramp.Evaluate(t);
            }
            tempTex.SetPixels(colors);
            tempTex.Apply();
            return tempTex;
        }
    }
}