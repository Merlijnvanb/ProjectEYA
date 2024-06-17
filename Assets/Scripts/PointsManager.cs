using UnityEditor;
using UnityEngine;

public class PointsManager : MonoBehaviour
{
    public static PointsManager Instance { get; private set; }

    public GameObject[] points; // Array of pre-placed points
    public GlidingSystem glider;
    public Transform player; // Reference to the player's transform
    public ArrowIndicator arrowIndicator; // Reference to the arrow indicator

    private int currentPointIndex = -1;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
        }
        else
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        Cursor.visible = false;
    }

    private void Start()
    {
        ActivateNextPoint();
    }

    public void ActivateNextPoint(bool transition = false, int transitionID = 0)
    {
        if (currentPointIndex >= 0)
        {
            StartCoroutine(glider.BoostSequence());
        }

        currentPointIndex = (currentPointIndex + 1) % points.Length;
        if (transition) TransitionEvent(transitionID);

        points[currentPointIndex].SetActive(true);
        arrowIndicator.SetTarget(points[currentPointIndex].transform);
    }

    private void TransitionEvent(int id)
    {
        switch (id)
        {
            case 1:
                StartCoroutine(TerrainManager.Instance.Transition1to2());
                break;

            case 2:
                StartCoroutine(TerrainManager.Instance.Transition2to3());
                break;
            case 3:
                Application.Quit();
                break;
        }
    }
}
