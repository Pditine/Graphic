using System;
using UnityEngine;

namespace SkySystem
{
    [Serializable]
    public class LightElement : BaseElement
    {
        public Gradient sunLightGradient, moonLightGradient;
        public Vector2 lightRotation;
        public override void ManualUpdate()
        {

            SkySystem.Instance.mainLight.color = GetNowLightColor(sunLightGradient, 1);
            SkySystem.Instance.mainLight.color = GetNowLightColor(moonLightGradient, 1);
            SkySystem.Instance.mainLight.gameObject.transform.eulerAngles =
                new Vector3(lightRotation.y, lightRotation.x, 0);
        }

        public override void AutoUpdate(float time)
        {
            var isDayTime = time is > 6f and <= 18f;
            
            if (isDayTime)
            {
                SkySystem.Instance.mainLight.color = GetNowLightColor(sunLightGradient, time/24);
                SkySystem.Instance.mainLight.gameObject.transform.LookAt(SkySystem.Instance.lightDirection * 10000);
            }
            else
            {
                SkySystem.Instance.mainLight.color = GetNowLightColor(moonLightGradient, time/24);
                SkySystem.Instance.mainLight.gameObject.transform.LookAt(-SkySystem.Instance.lightDirection * 10000);
            }
        }
        private Color GetNowLightColor(Gradient gradient, float rate)
        {
            Color c = Color.black;
            if (gradient != null)
            {
                c = gradient.Evaluate(rate);
            }
            return c;
        }
    }
}