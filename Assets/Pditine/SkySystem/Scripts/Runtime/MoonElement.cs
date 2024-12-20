using System;
using Unity.Mathematics;
using UnityEngine;

namespace SkySystem
{
    [Serializable]
    public class MoonElement : BaseElement
    {
        private GameObject _moon;
        public Texture2D moonTexture;
        public Gradient moonColorGradient;
        public Texture starTexture;
        public float starIntensity;
        public float moonIntensity;
        public float moonDistance;
        [Range(0,1)]public float moonSize;
        
        public override void Init()
        {
            _moon = GameObject.Find("Moon");
            if (_moon==null)
            {
                Debug.LogError("Moon Not Found");
            }
        }
        public override void AutoUpdate(float time)
        {
            if (_moon==null)
            {
                _moon = GameObject.Find("Moon");
            }
            time %= 24;
            
            _moon.transform.LookAt(-SkySystem.Instance.lightDirection*10000);
            Shader.SetGlobalVector("_MoonDir",_moon.transform.forward);
            Shader.SetGlobalTexture("_MoonTexture",moonTexture);
            Shader.SetGlobalTexture("_StarTexture",starTexture);
            Shader.SetGlobalVector("_MoonGlowColor",moonColorGradient.Evaluate(time/24));
            Shader.SetGlobalFloat("_StarIntensity",starIntensity*math.saturate( math.abs(time-12)-5.5f));

            Shader.SetGlobalFloat("_MoonIntensity",moonIntensity*math.saturate( math.abs(time-12)-5));
            Shader.SetGlobalFloat("_MoonDistance", moonDistance);
            Shader.SetGlobalFloat("_MoonSize", moonSize);

        }
        public override void ManualUpdate()
        {
            if (_moon==null)
            {
                _moon = GameObject.Find("Moon");
            }
            Shader.SetGlobalVector("_MoonDir",_moon.transform.forward);
            Shader.SetGlobalTexture("_MoonTexture",moonTexture);
            Shader.SetGlobalTexture("_StarTexture",starTexture);
            //Shader.SetGlobalVector("_MoonGlowColor",moonColorGradient);
        }
         
        private Color GetNowLightColor(Gradient gradient,float rate)
        {
            Color c = Color.black;
            if (gradient!=null)
            {
                c=gradient.Evaluate(rate);
            }
            
            return c;
        }
    }
}