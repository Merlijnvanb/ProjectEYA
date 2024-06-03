using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CollisionManager : MonoBehaviour
{
    [SerializeField] private GameObject terrain;

    private BoxCollider terrainCollider;

    void Start()
    {
        terrainCollider = terrain.GetComponent<BoxCollider>();
    }

    // Update is called once per frame
    void Update()
    {
        //Debug.Log(terrainMat.color);
    }
}
