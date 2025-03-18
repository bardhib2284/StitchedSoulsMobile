using Assets.Resources.Scripts;
using UnityEngine;

public class NeedleProjectile : MonoBehaviour
{
    public float speed = 1;
    public float rotationSpeed = 300f;
    public float maxLifetime = 3f;
    public GameObject stitchEffectPrefab; // Stitch impact effect

    private Vector3 targetPosition;
    private bool hasTarget = false;

    public void SetTarget(Vector3 target)
    {
        targetPosition = target;
        hasTarget = true;
        Destroy(gameObject, maxLifetime);
    }

    void Update()
    {
        if (!hasTarget) return;

        // Move toward target
        transform.position = Vector3.MoveTowards(transform.position, targetPosition, speed * Time.deltaTime);

        // Rotate slightly while flying
        transform.Rotate(Vector3.forward * rotationSpeed * Time.deltaTime);

        // Check if close to target
        if (Vector3.Distance(transform.position, targetPosition) < 0.1f)
        {
            Impact();
        }
    }

    private void Impact()
    {
        Destroy(gameObject);
    }
}
