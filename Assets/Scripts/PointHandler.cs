using System.Collections;
using UnityEngine;

public class Point : MonoBehaviour
{
    public float transitionDuration = 0.5f; // Duration of the scale and intensity transition
    public bool transition;
    public int transitionID;

    private MeshRenderer meshRenderer;
    private Light pointLight;

    private void Awake()
    {
        meshRenderer = GetComponentInChildren<MeshRenderer>();
        pointLight = GetComponentInChildren<Light>();
    }

    private void OnTriggerEnter(Collider other)
    {
        // Check if the colliding object is the player
        if (other.CompareTag("Player"))
        {
            // Notify the PointsManager to activate the next point
            PointsManager.Instance.ActivateNextPoint(transition, transitionID);

            // Start the coroutine to scale down and reduce light intensity
            StartCoroutine(DisablePoint());
        }
    }

    private IEnumerator DisablePoint()
    {
        float elapsedTime = 0f;
        Vector3 initialScale = meshRenderer.transform.localScale;
        float initialIntensity = pointLight.intensity;

        while (elapsedTime < transitionDuration)
        {
            elapsedTime += Time.deltaTime;
            float t = elapsedTime / transitionDuration;

            // Lerp scale and intensity to zero
            meshRenderer.transform.localScale = Vector3.Lerp(initialScale, Vector3.zero, t);
            pointLight.intensity = Mathf.Lerp(initialIntensity, 0f, t);

            yield return null;
        }

        // Ensure they are fully zeroed out
        meshRenderer.transform.localScale = Vector3.zero;
        pointLight.intensity = 0f;

        gameObject.SetActive(false); // Finally disable the point
    }
}
