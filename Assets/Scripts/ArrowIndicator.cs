using UnityEngine;

public class ArrowIndicator : MonoBehaviour
{
    private Transform target; // The current active point
    public Transform player; // Reference to the player's transform

    void Update()
    {
        transform.position = player.position;
        if (target != null)
        {
            Vector3 direction = (target.position - player.position).normalized;
            Quaternion lookRotation = Quaternion.LookRotation(direction);
            transform.rotation = Quaternion.Slerp(transform.rotation, lookRotation, 5f * Time.deltaTime);
        }
    }

    public void SetTarget(Transform newTarget)
    {
        target = newTarget;
    }
}
