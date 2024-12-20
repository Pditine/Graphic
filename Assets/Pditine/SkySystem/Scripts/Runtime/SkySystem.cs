using Sirenix.OdinInspector;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;

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
        
        [PropertyRange(0,24)] [ShowInInspector]
        public float Hour
        {
            get => data.hour;
            set => data.hour = value;
        }

        public bool auto = true;
        public float timeSpeed = 1;
        [ShowInInspector]
        public bool timeControlEverything
        {
            get => data.timeControlEverything;
            set => data.timeControlEverything = value;
        }
        
        public Light mainLight;
        public Vector3 LightDirection;

        // sky
        private SkyElement skySettings;
        [FoldoutGroup("Sky",true)]
        public Gradient daySkyGradient;
        [FoldoutGroup("Sky",true)]
        public Gradient nightSkyGradient;

        // sun
        private SunElement sunSettings;
        [ShowInInspector][FoldoutGroup("Sun",true)]
        public Gradient sunDiscGradient;
        [ShowInInspector][FoldoutGroup("Sun",true)]
        public Vector2 sunRotation
        {
            get => sunSettings.sunRotation;
            set => sunSettings.sunRotation = value;
        }
        [ShowInInspector][FoldoutGroup("Sun",true)]
        public Vector4 sunHalo
        {
            get => sunSettings.sunHalo;
            set => sunSettings.sunHalo = value;
        }  
        [ShowInInspector][FoldoutGroup("Sun",true)]
        public Gradient sunColorGradient;
        [ShowInInspector][FoldoutGroup("Sun",true)]
        public float sunIntensity
        {
            get => sunSettings.sunIntensity;
            set => sunSettings.sunIntensity = value;
        }
         
        // moon
        private MoonElement moonSettings;
        [ShowInInspector][FoldoutGroup("moon",true)]
        public Texture2D moonTexture
        {
            get => moonSettings.moonTexture;
            set => moonSettings.moonTexture = value;
        }
        [FoldoutGroup("moon",true)]
        public Gradient moonColorGradient;
        [ShowInInspector][FoldoutGroup("moon",true)]
        public float moonIntensity
        {
            get => moonSettings.moonIntensity;
            set => moonSettings.moonIntensity = value;
        }
        [ShowInInspector][PropertyRange(0.9f,1f)][FoldoutGroup("moon",true)]
        public float moonSize
        {
            get => moonSettings.moonSize;
            set => moonSettings.moonSize = value;
        }
        [ShowInInspector][FoldoutGroup("moon",true)]
        public float moonDistance
        {
            get => moonSettings.moonDistance;
            set => moonSettings.moonDistance = value;
        }
        [ShowInInspector][FoldoutGroup("moon",true)]
        public Texture starTexture
        {
            get => moonSettings.starTexture;
            set => moonSettings.starTexture = value;
        }
        [ShowInInspector,InspectorRange(0f,1f)][FoldoutGroup("moon",true)]
        public float starIntensity
        {
            get => moonSettings.starIntensity;
            set => moonSettings.starIntensity = value;
        }
        
        
        // light
        private LightElement lightingSettings;
        [ShowInInspector][FoldoutGroup("Lighting",true)]
        public float lightIntensity
        {
            get => lightingSettings.lightIntensity;
            set => lightingSettings.lightIntensity = value;
        }
        [ShowInInspector][FoldoutGroup("Lighting",true)]
        public Vector2 lightRotation
        {
            get => lightingSettings.lightRotation;
            set => lightingSettings.lightRotation = value;
        }
        
        [SerializeField][FoldoutGroup("Lighting",true)]
        public Gradient sunLightGradient;
        [FoldoutGroup("Lighting",true)]
        public Gradient moonLightGradient;

        private CloudElement cloudSettings;

        [ShowInInspector] [FoldoutGroup("Cloud", true)]
        public Color cloudTint
        {
            get => cloudSettings.tint;
            set => cloudSettings.tint = value;
        }
        [ShowInInspector] [FoldoutGroup("Cloud", true)]
        public Color cloudTopColor
        {
            get => cloudSettings.cloudTopColor;
            set => cloudSettings.cloudTopColor = value;
        }
        [ShowInInspector] [FoldoutGroup("Cloud", true)]
        public Color cloudBottomColor
        {
            get => cloudSettings.cloudBottomColor;
            set => cloudSettings.cloudBottomColor = value;
        }

        [ShowInInspector] [FoldoutGroup("Cloud", true),PropertyRange(0f,1f)]
        public float GIIndex
        {
            get => cloudSettings.GIIndex;
            set => cloudSettings.GIIndex = value;
        }
        private ProbeElement probeSettings;
        [FoldoutGroup("EnvironmentSettings",true)]
        public Gradient fogColorGradient;
        [ShowInInspector][FoldoutGroup("EnvironmentSettings",true)]
        public AmbientMode ambientMode
        {
            get => probeSettings.AmbientMode;
            set => probeSettings.AmbientMode = value;
        }
        [ShowInInspector][FoldoutGroup("EnvironmentSettings",true)]
        public ReflectionProbeMode reflectionProbeMode
        {
            get => probeSettings.Mode;
            set => probeSettings.Mode = value;
        }

        [ShowInInspector][FoldoutGroup("EnvironmentSettings",true)]
        public ReflectionResolution reflectionResolition
        {
            get => (ReflectionResolution)probeSettings.Resolution;
            set => probeSettings.Resolution = (int)value;
        }
        [ShowInInspector][FoldoutGroup("EnvironmentSettings",true)]
        public bool boxProjection
        {
            get => probeSettings.BoxProjection;
            set => probeSettings.BoxProjection = value;
        }
        [ShowInInspector][FoldoutGroup("EnvironmentSettings",true)]
        public bool HDR
        {
            get => probeSettings.HDR;
            set => probeSettings.HDR = value;
        }
        [ShowInInspector][FoldoutGroup("EnvironmentSettings",true)]
        public ReflectionProbeClearFlags clearFlags
        {
            get => probeSettings.ClearFlags;
            set => probeSettings.ClearFlags = value;
        }

        [ShowInInspector][FoldoutGroup("EnvironmentSettings",true)]
        public Texture skyboxCubemap
        {
            get => probeSettings.CubeMap;
            set => probeSettings.CubeMap=value;
        }
        [ShowInInspector][FoldoutGroup("EnvironmentSettings",true)]
        public LayerMask cullingMask
        {
            get => probeSettings.CullingMask;
            set => probeSettings.CullingMask = value;
        }
        
        private Material skyboxMat;
        private Material defaultSkyboxMat;
        private SkySystemData data;
        
        private void Start()
        {
            if (data!=null)
            {
                data.SaveSystemData();
            }
            if( Application.isPlaying)
                DontDestroyOnLoad(gameObject);
        }
        
        private void OnEnable()
        {
            if (skyboxMat==null)
            {
                skyboxMat = new Material(Shader.Find("LiJianhao/SkyBox"));
            }
            if (skyboxMat!=null)
            {
                defaultSkyboxMat = RenderSettings.skybox;
                RenderSettings.skybox = skyboxMat;
            }

            data = ScriptableObject.CreateInstance<SkySystemData>();
            data.LoadSystemData();
            
            timeControlEverything = data.timeControlEverything;
            
            skySettings = new SkyElement(data);
            daySkyGradient = skySettings.daySkyGradient;
            nightSkyGradient = skySettings.nightSkyGradient;
            fogColorGradient = skySettings.fogColorGradient;
            if (GameObject.Find("Sun")==null)
            {
                GameObject sunObj = new GameObject("Sun");
                sunObj.transform.parent = transform;
            }
            if (sunSettings==null)
            {
                sunSettings = new SunElement(data);
            }

            sunDiscGradient = sunSettings.sunDiscGradient;
            sunColorGradient = sunSettings.sunColorGradient;
            sunIntensity = sunSettings.sunIntensity;
            
            if (GameObject.Find("Moon")==null)
            {
                GameObject moonObj = new GameObject("Moon");
                moonObj.transform.parent = transform;
            }
            if (moonSettings==null)
            {
                moonSettings = new MoonElement(data);
            }
            moonTexture = moonSettings.moonTexture;
            // starTexture = moonSettings.starTexture;
            // moonRotation = moonSettings.moonRotation;
            moonColorGradient = moonSettings.moonColorGradient;
            starIntensity = moonSettings.starIntensity;
            moonDistance = moonSettings.moonDistance;
            moonIntensity = moonSettings.moonIntensity;
            
            if (GameObject.Find("CloudController")==null)
            {
                GameObject cloudControllerObj = new GameObject("CloudController");
                cloudControllerObj.transform.parent = transform;
            }
            if (cloudSettings==null)
            {
                cloudSettings = new CloudElement(data);
            }
            cloudTint = cloudSettings.tint;
            cloudTopColor = cloudSettings.cloudTopColor;
            cloudBottomColor = cloudSettings.cloudBottomColor;
            GIIndex = cloudSettings.GIIndex;

            if (lightingSettings==null)
            {
                lightingSettings = new LightElement(data);
            }
            if (GameObject.Find("Sun&Moon Light")==null)
            {
                GameObject lightObj = new GameObject("Sun&Moon Light");
                lightObj.transform.parent = transform;
                mainLight = lightObj.AddComponent<Light>();
                RenderSettings.sun = mainLight;
                mainLight.shadows = LightShadows.Soft;
            }

            if (mainLight==null)
            {
                mainLight = GameObject.Find("Sun&Moon Light").GetComponent<Light>();
            }
            lightIntensity = lightingSettings.lightIntensity;
            sunLightGradient = lightingSettings.sunLightGradient;
            moonLightGradient = lightingSettings.moonLightGradient;
            lightRotation = lightingSettings.lightRotation;
            mainLight.type = LightType.Directional;

            //反射探针
            if (GameObject.Find("SkySystem_ReflectionProbe")==null)
            {
                GameObject probeObj = new GameObject("SkySystem_ReflectionProbe");
                probeObj.transform.SetParent(transform);
                probeObj.AddComponent<ReflectionProbe>();
                
            }

            if (probeSettings==null)
            {
                probeSettings = new ProbeElement(data);
            }
        }

        private void Update()
        {
            if (auto)
            {
                Hour += Time.deltaTime/2 * timeSpeed;
                Hour %= 24;
            }
            
            skySettings.ManualUpdate(Hour);
            cloudSettings.ManualUpdate(Hour);
            if (timeControlEverything)
            {
                sunSettings.AutoUpdate(Hour);
                lightingSettings.AutoUpdate(Hour);
                moonSettings.AutoUpdate(Hour);
            }
             
            else
            {
                sunSettings.ManualUpdate();
                lightingSettings.ManualUpdate();
                moonSettings.ManualUpdate();
            }
        }

        private void OnDisable()
        {
            if (skyboxMat!=null)
            {
                RenderSettings.skybox = defaultSkyboxMat;
            }
            data.SaveSystemData();
        }
    }
}