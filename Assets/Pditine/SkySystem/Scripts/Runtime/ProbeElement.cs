using System;
using System.IO;
using Sirenix.OdinInspector;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace SkySystem
{
    [Serializable]
    public class ProbeElement : BaseElement
    {
        private ReflectionProbe _probe;
        private Camera _renderCam;

        [ShowIf("@_probe != null")]
        public AmbientMode AmbientMode
        {
            get => RenderSettings.ambientMode;
            set => RenderSettings.ambientMode = value;
        }
        [ShowIf("@_probe != null")]
        public ReflectionProbeMode Mode
        {
            get => _probe.mode;
            set => _probe.mode = value;
        }
        [ShowIf("@_probe != null")]
        public Texture CubeMap
        {
            get => _probe.customBakedTexture;
            set => _probe.customBakedTexture = value;
        }
        [ShowIf("@_probe != null")]
        public bool BoxProjection
        {
            get => _probe.boxProjection;
            set => _probe.boxProjection = value;
        }
        [ShowIf("@_probe != null")]
        public Vector3 BoxSize
        {
            get => _probe.size;
            set => _probe.size = value;
        }
        [ShowIf("@_probe != null")]
        public int Resolution
        {
            get => _probe.resolution;
            set => _probe.resolution = value;
        }
        [ShowIf("@_probe != null")]
        public bool HDR
        {
            get => _probe.hdr;
            set => _probe.hdr = value;
        }
        [ShowIf("@_probe != null")]
        public ReflectionProbeClearFlags ClearFlags
        {
            get => _probe.clearFlags;
            set => _probe.clearFlags = value;
        }
        [ShowIf("@_probe != null")]
        public int CullingMask
        {
            get => _probe.cullingMask;
            set => _probe.cullingMask = value;
        }
        
        public override void Init()
        {
            GameObject obj = GameObject.Find("SkySystem_ReflectionProbe");
            if (obj!=null)
            {
                _probe = obj.GetComponent<ReflectionProbe>();
            }
            else
            {
                throw new Exception("No probeObj");
            }
            _probe.size = Vector3.one * 10000;
            _probe.refreshMode = ReflectionProbeRefreshMode.EveryFrame;
        }
        
        private void InitCamSetting()
        {
            
            _renderCam.cameraType = CameraType.Reflection;
            _renderCam.hideFlags = HideFlags.HideAndDontSave;
            _renderCam.gameObject.SetActive(true);
            _renderCam.fieldOfView = 90;
            _renderCam.farClipPlane = _probe.farClipPlane;
            _renderCam.nearClipPlane = _probe.nearClipPlane;
            _renderCam.clearFlags = (CameraClearFlags)_probe.clearFlags;
            _renderCam.backgroundColor = _probe.backgroundColor;
            _renderCam.allowHDR = _probe.hdr;
            _renderCam.cullingMask = _probe.cullingMask;
            _renderCam.enabled = false;
        }
        private void SaveTexture2DFile(Texture2D texture, string path)
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }
            
            byte[] vs = texture.EncodeToPNG();
            FileStream fileStream = new FileStream(path, FileMode.Create, FileAccess.Write);
            fileStream.Write(vs , 0 , vs.Length);
            fileStream.Dispose();
            fileStream.Close();
        }
    }
}