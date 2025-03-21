using UnityEngine;
using System.Linq;
using System.Collections;

public class EnemyRagdoll : MonoBehaviour
{
    private Rigidbody[] ragdollBodies;
    private Collider[] ragdollColliders;
    private Animator animator;
    private bool isRagdoll = false;
    private bool isGettingUp = false;

    [Header("Main Components")]
    public Rigidbody mainRigidbody;
    public Collider mainCollider;

    public float standUpDelay = 0.1f;
    public float CheckTimeIsLanded = 0.7f;
    public float CheckTimeIsLandedRepeat = 0.2f;

    public bool StartAsRagdoll = false;
    public bool DestroyAfter10Seconds = false;

    void Start()
    {
        animator = GetComponent<Animator>();

        mainRigidbody = GetComponent<Rigidbody>();
        mainCollider = GetComponent<Collider>();

        if (mainRigidbody == null)
        {
            mainRigidbody = gameObject.AddComponent<Rigidbody>();
            mainRigidbody.mass = 10f;
            mainRigidbody.freezeRotation = true;
            mainRigidbody.useGravity = true;
        }

        if (mainCollider == null)
        {
            mainCollider = gameObject.AddComponent<CapsuleCollider>();
        }

        ragdollBodies = GetComponentsInChildren<Rigidbody>()
                        .Where(rb => rb != mainRigidbody)
                        .ToArray();

        ragdollColliders = GetComponentsInChildren<Collider>()
                          .Where(col => col != mainCollider)
                          .ToArray();

        SetRagdollActive(StartAsRagdoll);
        if (StartAsRagdoll)
        {
            standUpDelay = 10000;
            CheckTimeIsLanded = 3;
            CheckTimeIsLandedRepeat = 0.3f;
            ActivateRagdoll(Vector3.up, 30f);
            Destroy(this.gameObject, 10);
        }
    }

    public void ActivateRagdoll(Vector3 forceDirection, float forceAmount)
    {
        if (isRagdoll) return;
        animator.enabled = false;
        isRagdoll = true;
        SetRagdollActive(true);

        if (mainRigidbody != null)
        {
            mainRigidbody.isKinematic = true;
            mainRigidbody.detectCollisions = false;
        }

        Rigidbody pushBody = ragdollBodies.FirstOrDefault(rb => rb.name.ToLower().Contains("hips") || rb.name.ToLower().Contains("chest"));

        if (pushBody == null)
        {
            pushBody = ragdollBodies[0];
        }

        if (!pushBody.isKinematic)
        {
            pushBody.AddForce(forceDirection * forceAmount, ForceMode.Impulse);
        }

        InvokeRepeating(nameof(CheckIfLanded), CheckTimeIsLanded, CheckTimeIsLandedRepeat);
    }

    void SetRagdollActive(bool active)
    {
        foreach (Rigidbody rb in ragdollBodies)
        {
            rb.isKinematic = !active;
            rb.detectCollisions = active;
        }

        foreach (Collider col in ragdollColliders)
        {
            col.enabled = active;
        }
    }

    void CheckIfLanded()
    {
        SetRagdollActive(false);
        isGettingUp = true;
        CancelInvoke(nameof(CheckIfLanded));
        Invoke(nameof(StandUp), standUpDelay);
    }

    public bool IsRagdollActive()
    {
        return isRagdoll;
    }

    void StandUp()
    {
        StartCoroutine(StandUpEnumerator());
    }

    IEnumerator StandUpEnumerator()
    {
        if (!GetComponent<EnemyAI>().isDead)
        {
            isRagdoll = false;
            isGettingUp = false;

            Transform hipsTransform = ragdollBodies.FirstOrDefault(rb => rb.name.ToLower().Contains("hips"))?.transform;
            yield return new WaitForEndOfFrame();
            if (hipsTransform != null)
            {
                yield return new WaitForEndOfFrame();
                transform.position = hipsTransform.position;
            }

            if (mainRigidbody != null)
            {
                mainRigidbody.isKinematic = false;
                mainRigidbody.detectCollisions = true;
                mainRigidbody.useGravity = true;
            }
            if (mainCollider != null) mainCollider.enabled = true;

            animator.enabled = true;
            animator.SetTrigger("StandUp");
        }
    }
}
