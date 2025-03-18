using UnityEngine;
using System.Linq;
using Assets.Resources.Scripts;
using System.Collections; // Required for LINQ filtering

public class EnemyRagdoll : MonoBehaviour
{
    private Rigidbody[] ragdollBodies;
    private Collider[] ragdollColliders;
    private Animator animator;
    private bool isRagdoll = false;
    private bool isGettingUp = false;

    [Header("Main Components")]
    public Rigidbody mainRigidbody; // Root Rigidbody for standing
    public Collider mainCollider;   // Root collider for standing

    public float standUpDelay = 0.1f; // Time before standing up
    public float CheckTimeIsLanded = 0.7f;
    public float CheckTimeIsLandedRepeat = 0.2f;

    public bool StartAsRagdoll = false;
    public bool DestroyAfter10Seconds = false;
    void Start()
    {
        animator = GetComponent<Animator>();

        // 🔹 Get the root Rigidbody & Collider
        mainRigidbody = GetComponent<Rigidbody>();
        mainCollider = GetComponent<Collider>();

        // 🔹 Ensure main Rigidbody exists for normal physics
        if (mainRigidbody == null)
        {
            mainRigidbody = gameObject.AddComponent<Rigidbody>();
            mainRigidbody.mass = 10f;
            mainRigidbody.freezeRotation = true;
            mainRigidbody.useGravity = true;
        }

        // 🔹 Ensure main Collider exists
        if (mainCollider == null)
        {
            mainCollider = gameObject.AddComponent<CapsuleCollider>(); // Keeps the enemy grounded
        }

        // 🔹 Get all child Rigidbodies, but EXCLUDE the main Rigidbody
        ragdollBodies = GetComponentsInChildren<Rigidbody>()
                        .Where(rb => rb != mainRigidbody)
                        .ToArray();

        ragdollColliders = GetComponentsInChildren<Collider>()
                          .Where(col => col != mainCollider)
                          .ToArray();

        // 🔹 Start with ragdoll disabled
        SetRagdollActive(StartAsRagdoll);
        if(StartAsRagdoll)
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
        GetComponent<EnemyAI>().IsStunned = true;
        GetComponent<ZombieAcidAttack>().StopAllCoroutines();
        isRagdoll = true;
        foreach (var rb in ragdollBodies)
        {
            rb.interpolation = RigidbodyInterpolation.Interpolate;
        }
        // 🔹 Disable main Rigidbody & Collider so ragdoll physics takes over
        if (mainRigidbody != null)
        {
            mainRigidbody.isKinematic = true;
            mainRigidbody.detectCollisions = false;
        }
        if (StartAsRagdoll)
        {
            mainRigidbody.detectCollisions = true;
            mainCollider.enabled = true;
        }
        else
        {
            mainRigidbody.detectCollisions = false;
            mainCollider.enabled = false;
        }

        SetRagdollActive(true);
        Rigidbody pushBody = ragdollBodies.FirstOrDefault(rb => rb.name.ToLower().Contains("hips") || rb.name.ToLower().Contains("chest"));

        if (pushBody == null) // If no hips or chest found, default to first ragdoll body
        {
            pushBody = ragdollBodies[0];
        }

        if (!pushBody.isKinematic)
        {
            // **Apply force in the correct direction**
            pushBody.AddForce(forceDirection * forceAmount, ForceMode.Impulse);
        }


        // **Apply force in the correct direction**

        // Start checking when the enemy lands
        InvokeRepeating(nameof(CheckIfLanded), CheckTimeIsLanded, CheckTimeIsLandedRepeat);
    }


    void SetRagdollActive(bool active)
    {
        if (active)
        {
            GetComponent<EnemyAI>().enabled = false;
        }
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
        GetComponent<EnemyAI>().IsStunned = false;
    }

    bool IsOnGround()
    {
        foreach (Rigidbody rb in ragdollBodies)
        {
            if (rb.linearVelocity.magnitude > 0.5f) return false;
        }
        return true;
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

            // **Step 1: Find Hips Transform to Determine Facing Direction**
            Transform hipsTransform = ragdollBodies.FirstOrDefault(rb => rb.name.ToLower().Contains("hips"))?.transform;
            yield return new WaitForEndOfFrame();
            if (hipsTransform != null)
            {
                yield return new WaitForEndOfFrame();

                // **Move Root to Hips Position**
                transform.position = hipsTransform.position;
                yield return new WaitForEndOfFrame();
                if (transform.position != hipsTransform.position)
                {
                    transform.position = hipsTransform.position;
                }
                // **Step 2: Adjust Rotation Based on Face-Up or Face-Down**
                float hipsUpDot = Vector3.Dot(hipsTransform.up, Vector3.up);

                if (hipsUpDot < 0) // **Face-Up Check (If Hips Are Upside Down)**
                {
                    //transform.Rotate(0, 180, 0); // Flip the enemy to face the correct way
                }
            }

            // **Step 3: Disable Ragdoll Physics**
            //SetRagdollActive(false);

            // **Step 4: Re-enable Main Rigidbody & Collider**
            if (mainRigidbody != null)
            {
                mainRigidbody.isKinematic = false;
                mainRigidbody.detectCollisions = true;
                mainRigidbody.useGravity = true;
            }
            if (mainCollider != null) mainCollider.enabled = true;
            foreach (var rb in ragdollBodies)
            {
                rb.interpolation = RigidbodyInterpolation.None;
            }
            // **Step 5: Re-enable Animator & Play Stand-Up Animation**
            animator.enabled = true;
            animator.SetTrigger("StandUp");
            GetComponent<EnemyAI>().enabled = true;
            GetComponent<EnemyAI>().IsStunned = false;
        }
    }
}
