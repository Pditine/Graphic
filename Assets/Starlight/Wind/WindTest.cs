using System;
using UnityEngine;
[ExecuteInEditMode]//在编辑模式下执行（方便预览

//控制单株植物的风和摆动效果，允许通过材质参数调整风的强度、速度、湍流
public class WindTest : MonoBehaviour
{
    public Texture2D NoiseTexture = default; //风的噪声纹理
    public bool Wiggle = true; //草的摆动
    public bool Wind = true; //是否有风吹动
    [Range(0f, 1f)]
    public float WindStrenght = .5f; //风的强度
    [Range(0f, 1f)]
    public float WindSpeed = .5f; //风的速度
    [Range(0f, 1f)]
    public float WindTurbulence = .5f; //风的湍流波动
    [Range(0f, 1f)]
    public float LeavesWiggle = .5f; //树叶摇摆幅度
    [Range(0f, 1f)]
    public float GrassWiggle = .5f; //草的摇摆幅度
    private float WindGizmo = 0.5f; //风示意图(OnDrawGizmos绘制的）的显示强度

    private void Start()
    {
        Cursor.visible = false;
    }

    //更新Shader参数
    void Update()
    {

        //是否Wiggle，如果为true就激活_WIGGLE_ON（shader里的一个Switch），草的摆动就生效
        if (Wiggle)
        {
            Shader.EnableKeyword("_WIGGLE_ON");
        }
        else
        {
            Shader.DisableKeyword("_WIGGLE_ON");
        }

        //同理，true就激活_WIND_ON，启用风吹效果
        if (Wind)
        {
            Shader.EnableKeyword("_WIND_ON");
        }
        else
        {
            Shader.DisableKeyword("_WIND_ON");
        }

        //设置全局变量，然后再传入shader内，方便直接统一调试不同植物的数据
        Shader.SetGlobalTexture("NoiseTextureFloat", NoiseTexture);
        Shader.SetGlobalVector("WindDirection", transform.rotation * Vector3.back);
        Shader.SetGlobalFloat("WindStrenghtFloat", WindStrenght);
        Shader.SetGlobalFloat("WindSpeedFloat", WindSpeed);
        Shader.SetGlobalFloat("WindTurbulenceFloat", WindTurbulence);
        Shader.SetGlobalFloat("LeavesWiggleFloat", LeavesWiggle);
        Shader.SetGlobalFloat("GrassWiggleFloat", GrassWiggle);

    }

    //绘制一个风的方向和强度的示意图
    void OnDrawGizmos()
    {
        //Vector3 dir = (transform.position + transform.forward).normalized; //物体朝向

        Gizmos.color = Color.green; //绘制绿色
        Vector3 up = transform.up; //物体的上方向
        Vector3 side = transform.right; //物体的右方向

        //风向示意图的起点、终点和中点
        Vector3 end = transform.position + transform.forward * (WindGizmo * 5f); //物体前方5倍距离位置
        Vector3 mid = transform.position + transform.forward * (WindGizmo * 2.5f);
        Vector3 start = transform.position + transform.forward * (WindGizmo * 0f); //物体本身的位置

        float s = WindGizmo; //少打点字（）
        Vector3 front = transform.forward * WindGizmo; //得到一个朝前方的单位向量

        //通过Gizmos画线，代表风的方向和强度
        Gizmos.DrawLine(start, start - front + up * s); //风的垂直分量
        Gizmos.DrawLine(start, start - front - up * s);
        Gizmos.DrawLine(start, start - front + side * s); //风的横向分量
        Gizmos.DrawLine(start, start - front - side * s);
        Gizmos.DrawLine(start, start - front * 2); //风本身的方向

        //风的中间位置
        Gizmos.DrawLine(mid, mid - front + up * s);
        Gizmos.DrawLine(mid, mid - front - up * s);
        Gizmos.DrawLine(mid, mid - front + side * s);
        Gizmos.DrawLine(mid, mid - front - side * s);
        Gizmos.DrawLine(mid, mid - front * 2);

        //风的结尾部分
        Gizmos.DrawLine(end, end - front + up * s);
        Gizmos.DrawLine(end, end - front - up * s);
        Gizmos.DrawLine(end, end - front + side * s);
        Gizmos.DrawLine(end, end - front - side * s);
        Gizmos.DrawLine(end, end - front * 2);

        //得出风的方向、强度和风的扩散范围
    }
}