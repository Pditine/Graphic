using System;
using UnityEngine;
[ExecuteInEditMode]//�ڱ༭ģʽ��ִ�У�����Ԥ��

//���Ƶ���ֲ��ķ�Ͱڶ�Ч��������ͨ�����ʲ����������ǿ�ȡ��ٶȡ�����
public class WindTest : MonoBehaviour
{
    public Texture2D NoiseTexture = default; //�����������
    public bool Wiggle = true; //�ݵİڶ�
    public bool Wind = true; //�Ƿ��з紵��
    [Range(0f, 1f)]
    public float WindStrenght = .5f; //���ǿ��
    [Range(0f, 1f)]
    public float WindSpeed = .5f; //����ٶ�
    [Range(0f, 1f)]
    public float WindTurbulence = .5f; //�����������
    [Range(0f, 1f)]
    public float LeavesWiggle = .5f; //��Ҷҡ�ڷ���
    [Range(0f, 1f)]
    public float GrassWiggle = .5f; //�ݵ�ҡ�ڷ���
    private float WindGizmo = 0.5f; //��ʾ��ͼ(OnDrawGizmos���Ƶģ�����ʾǿ��

    private void Start()
    {
        Cursor.visible = false;
    }

    //����Shader����
    void Update()
    {

        //�Ƿ�Wiggle�����Ϊtrue�ͼ���_WIGGLE_ON��shader���һ��Switch�����ݵİڶ�����Ч
        if (Wiggle)
        {
            Shader.EnableKeyword("_WIGGLE_ON");
        }
        else
        {
            Shader.DisableKeyword("_WIGGLE_ON");
        }

        //ͬ��true�ͼ���_WIND_ON�����÷紵Ч��
        if (Wind)
        {
            Shader.EnableKeyword("_WIND_ON");
        }
        else
        {
            Shader.DisableKeyword("_WIND_ON");
        }

        //����ȫ�ֱ�����Ȼ���ٴ���shader�ڣ�����ֱ��ͳһ���Բ�ֲͬ�������
        Shader.SetGlobalTexture("NoiseTextureFloat", NoiseTexture);
        Shader.SetGlobalVector("WindDirection", transform.rotation * Vector3.back);
        Shader.SetGlobalFloat("WindStrenghtFloat", WindStrenght);
        Shader.SetGlobalFloat("WindSpeedFloat", WindSpeed);
        Shader.SetGlobalFloat("WindTurbulenceFloat", WindTurbulence);
        Shader.SetGlobalFloat("LeavesWiggleFloat", LeavesWiggle);
        Shader.SetGlobalFloat("GrassWiggleFloat", GrassWiggle);

    }

    //����һ����ķ����ǿ�ȵ�ʾ��ͼ
    void OnDrawGizmos()
    {
        //Vector3 dir = (transform.position + transform.forward).normalized; //���峯��

        Gizmos.color = Color.green; //������ɫ
        Vector3 up = transform.up; //������Ϸ���
        Vector3 side = transform.right; //������ҷ���

        //����ʾ��ͼ����㡢�յ���е�
        Vector3 end = transform.position + transform.forward * (WindGizmo * 5f); //����ǰ��5������λ��
        Vector3 mid = transform.position + transform.forward * (WindGizmo * 2.5f);
        Vector3 start = transform.position + transform.forward * (WindGizmo * 0f); //���屾���λ��

        float s = WindGizmo; //�ٴ���֣���
        Vector3 front = transform.forward * WindGizmo; //�õ�һ����ǰ���ĵ�λ����

        //ͨ��Gizmos���ߣ������ķ����ǿ��
        Gizmos.DrawLine(start, start - front + up * s); //��Ĵ�ֱ����
        Gizmos.DrawLine(start, start - front - up * s);
        Gizmos.DrawLine(start, start - front + side * s); //��ĺ������
        Gizmos.DrawLine(start, start - front - side * s);
        Gizmos.DrawLine(start, start - front * 2); //�籾��ķ���

        //����м�λ��
        Gizmos.DrawLine(mid, mid - front + up * s);
        Gizmos.DrawLine(mid, mid - front - up * s);
        Gizmos.DrawLine(mid, mid - front + side * s);
        Gizmos.DrawLine(mid, mid - front - side * s);
        Gizmos.DrawLine(mid, mid - front * 2);

        //��Ľ�β����
        Gizmos.DrawLine(end, end - front + up * s);
        Gizmos.DrawLine(end, end - front - up * s);
        Gizmos.DrawLine(end, end - front + side * s);
        Gizmos.DrawLine(end, end - front - side * s);
        Gizmos.DrawLine(end, end - front * 2);

        //�ó���ķ���ǿ�Ⱥͷ����ɢ��Χ
    }
}