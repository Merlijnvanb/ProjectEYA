using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

[ExecuteInEditMode]

[RequireComponent(typeof(MeshRenderer))]
[RequireComponent(typeof(MeshFilter))]
public class PlaneGenerator : MonoBehaviour
{
    Mesh myMesh;
    MeshFilter meshFilter;

    [SerializeField] Vector2 planeSize = new Vector2(1, 1);
    [SerializeField] int planeResolution = 1;

    private Vector2 previousSize;
    private int previousRes;

    List<Vector3> vertices;
    List<int> triangles;
    List<Vector3> normals;

    void Awake()
    {
        myMesh = new Mesh();
        meshFilter = GetComponent<MeshFilter>();
        meshFilter.mesh = myMesh;
    }

    void Start()
    {
        planeResolution = Mathf.Clamp(planeResolution, 1, 500);

        GeneratePlane(planeSize, planeResolution);
        AssignMesh();
    }

    void Update()
    {
        if (planeResolution != previousRes || planeSize != previousSize)
        {
            planeResolution = Mathf.Clamp(planeResolution, 1, 500);

            previousRes = planeResolution;
            previousSize = planeSize;

            GeneratePlane(planeSize, planeResolution);
            AssignMesh();
        }
    }

    void GeneratePlane(Vector2 size, int resolution)
    {
        //Create vertices
        vertices = new List<Vector3>();
        normals = new List<Vector3>();
        float xPerStep = size.x / resolution;
        float yPerStep = size.y / resolution;
        float xOffset = size.x / 2;
        float yOffset = size.y / 2;
        for (int y = 0; y < resolution + 1; y++)
        {
            for (int x = 0; x < resolution + 1; x++)
            {
                float xPos = x * xPerStep - xOffset;
                float yPos = y * yPerStep - yOffset;
                vertices.Add(new Vector3(xPos, 0, yPos));
                normals.Add(Vector3.up); // Add normal pointing up
            }
        }

        //Create triangles
        triangles = new List<int>();
        for (int row = 0; row < resolution; row++)
        {
            for (int column = 0; column < resolution; column++)
            {
                int i = (row * resolution) + row + column;
                //first triangle
                triangles.Add(i);
                triangles.Add(i + resolution + 1);
                triangles.Add(i + resolution + 2);

                //second triangle
                triangles.Add(i);
                triangles.Add(i + resolution + 2);
                triangles.Add(i + 1);
            }
        }
        Debug.Log("Generated Plane");
    }

    void AssignMesh()
    {
        myMesh.Clear();
        myMesh.vertices = vertices.ToArray();
        myMesh.triangles = triangles.ToArray();
        myMesh.normals = normals.ToArray(); // Assign normals to the mesh
        Debug.Log("Assigned Mesh");
    }
}
