using System;
using System.Transactions;
using Sirenix.OdinInspector;
using UnityEngine;

namespace SkySystem
{
    [Serializable]
    public class SunElement:BaseElement
    {
        private GameObject _sun;

        public Gradient sunDiscGradient = new();
        public Vector2 sunRotation;
        public Vector4 sunHalo = new(0.25f,0.25f,0.25f,0.25f);
        public float sunIntensity;
        public Gradient sunColorGradient = new();

        public override void Init()
        {
            _sun = GameObject.Find("Sun");
            if (_sun==null)
            {
                Debug.LogError("Sun Not Found");
            }
        }

        public override void AutoUpdate(float time)
        {
            if (_sun==null)
            {
                _sun = GameObject.Find("Sun");
            }
            
            sunRotation.y = 90f + time * 90f / 6f;
            _sun.transform.eulerAngles = new Vector3(sunRotation.y,sunRotation.x,0);
            Shader.SetGlobalVector("_SunDir",this._sun.transform.forward);
            Shader.SetGlobalVector("_SunHalo",sunHalo);
            Shader.SetGlobalColor("_SunGlowColor",sunColorGradient.Evaluate(time/24));
            Shader.SetGlobalFloat("_SunIntensity",sunIntensity);
            Shader.SetGlobalTexture("_SunDiscGradient",ApplyGradient(sunDiscGradient));
            SkySystem.Instance.lightDirection = -_sun.transform.forward;
        }
        public override void ManualUpdate()
        {
            if (_sun==null)
            {
                _sun = GameObject.Find("Sun");
            }
            _sun.transform.eulerAngles = new Vector3(sunRotation.y,sunRotation.x,0);
            Shader.SetGlobalVector("_SunDir",this._sun.transform.forward);
            Shader.SetGlobalVector("_SunHalo",sunHalo);
            Shader.SetGlobalColor("_SunGlowColor",sunColorGradient.Evaluate(0));
            SkySystem.Instance.lightDirection = -_sun.transform.forward;
        }
        
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