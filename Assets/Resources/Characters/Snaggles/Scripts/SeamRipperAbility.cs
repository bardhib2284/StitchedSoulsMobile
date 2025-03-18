using Assets.Resources.Scripts;
using System.Collections;
using UnityEngine;
using static UnityEngine.Rendering.DebugUI;

public class SeamRipperAbility : BossAbility
{
    [Header("Seam Ripper Settings")]
    public float dashSpeed = 10f;
    public float dashDuration = 1.5f;
    public float damage = 15f;
    public float bleedDamage = 5f;
    public float bleedDuration = 5f;

    private Rigidbody rb;
    public bool isDashing = false;
    private Vector3 dashDirection;

    private float KnocbackForce = 2f;

    void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    public override void ActivateAbility(Transform target)
    {
        if (!CanUse()) return;

        if (!isDashing)
        {
            GetComponent<Animator>().SetTrigger("Dash");
            isDashing = true;
            dashDirection = (target.position - transform.position).normalized;
            StartCoroutine(Dash());
        }
    }

    private IEnumerator Dash()
    {
        float startTime = Time.time;

        while (Time.time < startTime + dashDuration)
        {
            rb.linearVelocity = dashDirection * dashSpeed;
            yield return new WaitForFixedUpdate();
        }

        rb.linearVelocity = Vector3.zero;
        isDashing = false;
        StartCooldown();
    }

    private void OnCollisionEnter(Collision collision)
    {
        Debug.Log(collision.gameObject.name);
        Debug.Log(collision.gameObject.tag);

        if (collision.transform.CompareTag("Player"))
        {
            //Health playerHealth = other.GetComponent<Health>();
            //if (playerHealth != null)
            //{
            //    playerHealth.TakeDamage(damage);
            //    playerHealth.ApplyBleed(bleedDamage, bleedDuration);
            //}
            collision.gameObject.GetComponent<PlayerController>().enabled = false;
            Vector3 knockbackDirection = (collision.transform.position - transform.position).normalized;
            Rigidbody pushBody = collision.gameObject.GetComponent<Rigidbody>();
            // **Apply force in the correct direction**
            if(!pushBody.isKinematic)
            pushBody.AddForce(knockbackDirection * KnocbackForce, ForceMode.Impulse);
            StopDash();
            rb.linearVelocity = Vector3.zero;
            collision.gameObject.GetComponent<PlayerController>().enabled = true;
        }
        else if (collision.transform.CompareTag("Obstacle"))
        {
            StopDash();
        }
    }

    private void StopDash()
    {
        StopAllCoroutines(); // Ensure all coroutines stop immediately
        rb.linearVelocity = Vector3.zero;
        rb.angularVelocity = Vector3.zero;
        rb.constraints = RigidbodyConstraints.FreezeAll; // Ensure instant stop
        isDashing = false;
        GetComponent<Animator>().SetTrigger("Idle");
        StartCooldown();
        StartCoroutine(ResetConstraints());
    }

    private IEnumerator ResetConstraints()
    {
        yield return new WaitForSeconds(0.1f); // Small delay to prevent unintended movement
        rb.constraints = RigidbodyConstraints.FreezeRotation; // Restore movement
    }
}
