using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GlideController : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.W)) {
            transform.eulerAngles = new Vector3(transform.eulerAngles.x + 2.5f, transform.eulerAngles.y, transform.localEulerAngles.z);
        }
        if (Input.GetKeyDown(KeyCode.S)) {
            transform.eulerAngles = new Vector3(transform.eulerAngles.x - 2.5f, transform.eulerAngles.y, transform.localEulerAngles.z);
        }
    }
}
