using UnityEditor;
using UnityEngine;

namespace SkySystem
{
    [CustomEditor(typeof(SkySystem))]
    public class SkySystemEditor : Editor
    {
        private SkySystem Target => target as SkySystem;
        private Editor _currentDataEditor;
        private SkySystemData _dataBuffer;
        
        private void OnEnable()
        {
            _currentDataEditor = CreateEditor(Target.data);
        }
        
        public override void OnInspectorGUI()
        {
            var style = new GUIStyle
            {
                fontSize = 25,
                normal = {textColor = Color.white},
            };
            EditorGUILayout.LabelField("Sky System", style);
            base.OnInspectorGUI();
            EditorGUILayout.Space();
            style.fontSize = 15;
            EditorGUILayout.LabelField("Data", style);
            ShowData();
        }
        
        private void ShowData()
        {
            if (Target.data == null) return;
            
            if (Target.data != _dataBuffer)
            {
                _dataBuffer = Target.data;
                if (_currentDataEditor != null)
                    DestroyImmediate(_currentDataEditor);
                _currentDataEditor = CreateEditor(Target.data);
            }
            _currentDataEditor.OnInspectorGUI();
        }
    }
}