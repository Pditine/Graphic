using System;
using UnityEngine;

namespace SkySystem
{
    public enum ReflectionResolution
    {
        R16=16,
        R32=32,
        R64=64,
        R128=128,
        R256=256,
        R512=512,
        R1024=1024,
        R2048=2048
    }
    
    [ExecuteInEditMode]
    public class SkySystem : MonoBehaviour
    {
        private static SkySystem _instance;
        public static SkySystem Instance
        { 
            get
            {
                if (_instance == null)
                    _instance = FindObjectOfType<SkySystem>();
                return _instance;
            }
        }
        [SerializeField] private Material skyboxMat;
        public SkySystemData data;
        
        public float Hour
        {
            get => data.hour;
            set => data.hour = value;
        }

        public bool auto = true;
        public float timeSpeed = 1;
        public bool TimeControlEverything
        {
            get => data.timeControlEverything;
            set => data.timeControlEverything = value;
        }
        
        public Light mainLight;
        public Vector3 lightDirection;

        private void Start()
        {
            data.skyElement.Init();
            data.cloudElement.Init();
            data.sunElement.Init();
            data.lightElement.Init();
            data.moonElement.Init();
        }

        private void OnEnable()
        {
            RenderSettings.skybox = skyboxMat;
        }

        private void Update()
        {
            if (auto)
            {
                Hour += Time.deltaTime/2 * timeSpeed;
                Hour %= 24;
            }
            
            data.skyElement.ManualUpdate(Hour);
            data.cloudElement.ManualUpdate(Hour);
            if (TimeControlEverything)
            {
                data.sunElement.AutoUpdate(Hour);
                data.lightElement.AutoUpdate(Hour);
                data.moonElement.AutoUpdate(Hour);
            }
             
            else
            {
                data.sunElement.ManualUpdate();
                data.lightElement.ManualUpdate();
                data.moonElement.ManualUpdate();
            }
        }
    }
}