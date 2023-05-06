using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnimatorRestarter : MonoBehaviour
{
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Animation animation = GetComponent<Animation>();
            if (animation)
            {
                animation.Stop();
                animation.Play();
            }
        }
    }
}
