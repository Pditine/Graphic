using System;
using Unity.VisualScripting;
using UnityEngine;

namespace SkySystem
{
    [Serializable]
    public class CloudElement : BaseElement
    {
        public Color tint;
        public Color cloudTopColor;
        public Color cloudBottomColor;
        public float GIIndex;
        
        public void ManualUpdate(float time)
        {
            Shader.SetGlobalColor("_BaseColor",tint);
            Shader.SetGlobalColor("_CloudTopColor",cloudTopColor);
            Shader.SetGlobalColor("_CloudBottomColor",cloudBottomColor);
            Shader.SetGlobalFloat("_GIIndex",GIIndex);
            Shader.SetGlobalFloat("_CloudTime",time);
        }
    }
}