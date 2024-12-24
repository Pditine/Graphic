using System;
using UnityEngine;

namespace Pditine.Shader
{
    public class Interactor : MonoBehaviour
    {
        private static int num = 0;

        private void Start()
        {
            num++;
            if (num > 1)
            {
                throw new Exception("Only one Interactor is allowed in the scene.");
            }
        }

        void Update()
        {
            UnityEngine.Shader.SetGlobalVector("_InteractorPosition", transform.position);
        }
    }
}