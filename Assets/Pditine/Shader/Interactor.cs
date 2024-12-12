using UnityEngine;

namespace Pditine.Shader
{
    public class Interactor : MonoBehaviour
    {
        void Update()
        {
            UnityEngine.Shader.SetGlobalVector("_PositionMoving", transform.position);
        }
    }
}