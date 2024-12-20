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
        
        public void RenderSkybox(string path)
        {
            string texturePath = path;
            if (!Directory.Exists(texturePath))
            {
                Directory.CreateDirectory(texturePath);
            }
            TextureFormat format = _probe.hdr ? TextureFormat.RGBAFloat : TextureFormat.RGBA64;
            Cubemap tempCubemap = new Cubemap(_probe.resolution,format,false);
            
            GameObject camObj = new GameObject("RenderCam");
            _renderCam = camObj.AddComponent<Camera>();
            camObj.transform.position = Vector3.zero;
            InitCamSetting();
            //renderCam.enabled = true;
            _renderCam.RenderToCubemap(tempCubemap);
            Texture2D tex = GetTexture2DByCubeMap(tempCubemap, format);
            SaveTexture2DFile(tex, texturePath+"/Skybox_"+SkySystem.Instance.Hour+".png");
            AssetDatabase.Refresh();
            SetTextureAsCubeMap(texturePath);
            //收尾工作
            AssetDatabase.Refresh();
            _renderCam = null;
            GameObject.DestroyImmediate(camObj);
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
        private Texture2D GetTexture2DByCubeMap(Cubemap cubemap , TextureFormat format)
        {
            int everyW = cubemap.width;
            int everyH = cubemap.height;

            Texture2D texture2D = new Texture2D(everyW * 4, everyH * 3,format,false);
            texture2D.SetPixels(everyW, 0, everyW, everyH, cubemap.GetPixels(CubemapFace.PositiveY));
            texture2D.SetPixels(0, everyH, everyW, everyH, cubemap.GetPixels(CubemapFace.NegativeX));
            texture2D.SetPixels(everyW, everyH, everyW, everyH, cubemap.GetPixels(CubemapFace.PositiveZ));
            texture2D.SetPixels(2 * everyW, everyH, everyW, everyH, cubemap.GetPixels(CubemapFace.PositiveX));
            texture2D.SetPixels(3 * everyW, everyH, everyW, everyH, cubemap.GetPixels(CubemapFace.NegativeZ));
            texture2D.SetPixels(everyW, 2 * everyH, everyW, everyH, cubemap.GetPixels(CubemapFace.NegativeY));
            texture2D.Apply();
            texture2D = FlipPixels(texture2D, false, true);
            return texture2D;
        }
        
        private Texture2D FlipPixels(Texture2D texture, bool flipX, bool flipY)
        {
            if (!flipX && !flipY)
            {
                return texture;
            }
            if (flipX)
            {
                for (int i = 0; i < texture.width / 2; i++)
                {
                    for (int j = 0; j < texture.height; j++)
                    {
                        Color tempC = texture.GetPixel(i, j);
                        texture.SetPixel(i, j, texture.GetPixel(texture.width - 1 - i, j));
                        texture.SetPixel(texture.width - 1 - i, j, tempC);
                    }
                }
            }
            if (flipY)
            {
                for (int i = 0; i < texture.width; i++)
                {
                    for (int j = 0; j < texture.height / 2; j++)
                    {
                        Color tempC = texture.GetPixel(i, j);
                        texture.SetPixel(i, j, texture.GetPixel(i, texture.height - 1 - j));
                        texture.SetPixel(i, texture.height - 1 - j, tempC);
                    }
                }
            }
            texture.Apply();
            return texture;
        }
        private void SetTextureAsCubeMap(string path)
        {
            string[] paths = Directory.GetFiles(path, "*.png", SearchOption.AllDirectories);

            foreach (var t in paths)
            {
                string assetPath = t.Substring(path.IndexOf("Assets/"));
                Debug.Log(assetPath);
                TextureImporter importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
                importer.textureShape = TextureImporterShape.TextureCube;
                AssetDatabase.ImportAsset(assetPath);
            }
        }
    }
}