using UnityEngine;

namespace SkySystem
{
    public class CloudController : MonoBehaviour
    {
        [SerializeField] private Transform followTarget;
        [SerializeField] private float speed;
        [SerializeField]private float yScale = 1.0f;
        private Vector3 _positionOffset;
        private Quaternion _rotationOffset;
        private float _angle;
        private void Awake()
        {
            _positionOffset = transform.position - followTarget.position;
            var dir = -_positionOffset.normalized;
            _rotationOffset = Quaternion.LookRotation(dir);
        }

        private void Update()
        {
            Move();
        }

        private void Move()
        {
            _angle += Time.deltaTime * speed;
            var currentRotation = Quaternion.Euler(0, _angle, 0);
            transform.position = new Vector3(followTarget.position.x, followTarget.position.y * yScale,
                                     followTarget.position.z) + currentRotation * _positionOffset;
            transform.rotation = currentRotation * _rotationOffset;
        }
    }
}