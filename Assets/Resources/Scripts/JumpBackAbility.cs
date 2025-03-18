using System.Collections;
using UnityEngine;

public class JumpBackAbility : BossAbility
{
    [Header("Jump Back Settings")]
    public float jumpBackSpeed = 8f;
    public float jumpBackUpwardForce = 5f;
    public float jumpBackDuration = 1f;

    private Rigidbody rb;
    private bool isJumpingBack = false;

    void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    public override void ActivateAbility(Transform target)
    {
        if (!CanUse() || isJumpingBack) return;
        GetComponent<Animator>().SetTrigger("Jump");
        isJumpingBack = true;
        Vector3 retreatDirection = (transform.position - target.position).normalized + Vector3.up * jumpBackUpwardForce;
        StartCoroutine(JumpBack(retreatDirection));
    }

    private IEnumerator JumpBack(Vector3 retreatDirection)
    {
        float startTime = Time.time;

        while (Time.time < startTime + jumpBackDuration)
        {
            rb.linearVelocity = retreatDirection * jumpBackSpeed;
            yield return null;
        }

        rb.linearVelocity = Vector3.zero;
        isJumpingBack = false;
        StartCooldown();
    }
}
