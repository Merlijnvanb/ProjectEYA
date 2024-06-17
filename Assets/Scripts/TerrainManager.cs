using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
public class TerrainManager : MonoBehaviour
{
    public static TerrainManager Instance { get; private set; }


    public Material marcher;
    public GameObject marcherCube;

    private float value1to2;
    private float value2to3;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
        }
        else
        {
            Instance = this;
            //DontDestroyOnLoad(gameObject);
        }

        marcher.SetFloat("_1to2", 0f);
        marcher.SetFloat("_2to3", 0f);
    }

    public IEnumerator Transition1to2()
    {   
        while (value1to2 < 1f)
        {
            value1to2 += .1f * Time.deltaTime;
            marcher.SetFloat("_1to2", Mathf.Min(1f, value1to2));
            //Debug.Log(value1to2);
            yield return null;
        }
    }

    public IEnumerator Transition2to3()
    {
        while (value2to3 < 1f)
        {
            value2to3 += .1f * Time.deltaTime;
            marcher.SetFloat("_2to3", Mathf.Min(1f, value2to3));
            Debug.Log(value1to2);
            yield return null;
        }
    }
}
