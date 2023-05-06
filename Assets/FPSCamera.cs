using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FPSCamera : MonoBehaviour
{
    public float m_RotateMultiplier;
    public float m_TranslateSpeed;

    Vector2 m_prevMouse;
    Vector2 m_LocalEulerAngles;

    void Awake()
    {
        m_prevMouse = Input.mousePosition;
    }

    void Start()
    {
        m_LocalEulerAngles = transform.localEulerAngles;
    }

    void Update()
    {
        Vector2 view = Camera.main.ScreenToViewportPoint(Input.mousePosition);
        bool isOutside = view.x < 0 || view.x > 1 || view.y < 0 || view.y > 1;
        Cursor.visible = isOutside;

                Vector2 mouse = Input.mousePosition;
        if (Input.GetMouseButtonDown(0))
        {
            m_prevMouse = mouse;
        }
        Vector2 mouseDelta = mouse - m_prevMouse;
        m_prevMouse = mouse;
        if (Input.GetMouseButton(0))
        {
            m_LocalEulerAngles.y += mouseDelta.x * m_RotateMultiplier;
            m_LocalEulerAngles.x -= mouseDelta.y * m_RotateMultiplier;
            m_LocalEulerAngles.x = Mathf.Clamp(m_LocalEulerAngles.x, -90, +90);
        }
        transform.localEulerAngles = m_LocalEulerAngles;

        float h = Input.GetAxisRaw("Horizontal");
        float v = Input.GetAxisRaw("Vertical");
        Vector2 input = new Vector2(h, v);
        input.Normalize();

        Vector3 newPosition = transform.localPosition;
        newPosition += transform.forward * input.y * Time.deltaTime * m_TranslateSpeed;
        newPosition += transform.right * input.x * Time.deltaTime * m_TranslateSpeed;
        transform.localPosition = newPosition;
    }
}
