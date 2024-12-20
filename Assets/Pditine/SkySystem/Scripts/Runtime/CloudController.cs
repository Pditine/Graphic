using UnityEngine;

namespace SkySystem
{
    public class CloudController : MonoBehaviour
    {
        [SerializeField] private Transform followTarget;
        [SerializeField] private float speed;
        [SerializeField]private float yScale = 1.0f;
        private Vector3 positionOffset;
        private Quaternion rotationOffset;
        private float angle;
        private void Awake()
        {
            positionOffset = transform.position - followTarget.position;
            var dir = -positionOffset.normalized;
            rotationOffset = Quaternion.LookRotation(dir);
        }

        private void Update()
        {
            Sync();
        }

        private void Sync()
        {
            angle += Time.deltaTime * speed;
            Quaternion currentRotation = Quaternion.Euler(0, angle, 0);
            transform.position = new Vector3(followTarget.position.x, followTarget.position.y * yScale,
                                     followTarget.position.z) + currentRotation * positionOffset;
            transform.rotation = currentRotation * rotationOffset;
        }
    }
}