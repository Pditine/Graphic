using System;
using UnityEngine;

namespace Hmxs.Scripts
{
    /// <summary>
    /// generic singleton base class - inherit from MonoBehaviour
    /// </summary>
    public abstract class SingletonMono<T> : MonoBehaviour where T : SingletonMono<T>
    {
        private static readonly Lazy<T> InstanceHolder = new(() => {
            var instance = FindObjectOfType<T>();
            if (instance != null) return instance;
            var singletonObject = new GameObject(typeof(T).Name + "_Singleton");
            instance = singletonObject.AddComponent<T>();
            instance.OnInstanceCreated();
            return instance;
        });

        public static T Instance => InstanceHolder.Value;

        protected virtual void OnInstanceCreated() { }

        protected virtual void Awake()
        {
            if (InstanceHolder.IsValueCreated && InstanceHolder.Value != this) Destroy(gameObject);
        }
    }
}
