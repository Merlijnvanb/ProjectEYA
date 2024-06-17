using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Collisionknop : MonoBehaviour
{
    public Camera mainCam;

    private bool inRange;

    void Update()
    {
        if (inRange)
        {
            if (Input.GetKeyDown(KeyCode.E) && Vector3.Dot(mainCam.transform.forward,
                transform.position - mainCam.transform.position)
                >= .8f)
            {
                //Whatever er moet gebeuren wanneer je de knop indrukt
            }


        }
    }

    void OnTriggerEnter()
    {
        inRange = true;
    }

    void OnTriggerExit()
    {
        inRange = false;
    }
}
