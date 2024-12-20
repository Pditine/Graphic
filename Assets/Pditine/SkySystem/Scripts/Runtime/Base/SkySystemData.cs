using System;
using SkySystem;
using UnityEngine;

[Serializable]
[CreateAssetMenu(fileName = "SkySystemDefaultData",menuName = "ScriptableObjects/CreateSkySystemData")]
public class SkySystemData : ScriptableObject
{
    [Range(0, 24)]public float hour;
    public bool timeControlEverything;
    public SkyElement skyElement;
    public SunElement sunElement;
    public MoonElement moonElement;
    public LightElement lightElement;
    public CloudElement cloudElement;
    public ProbeElement probeElement;
}