using Assets.Resources.Scripts;
using System.Collections;
using UnityEngine;

public class GnashpatchAI : EnemyAI
{
    [Header("Ground & Movement")]
    public LayerMask groundLayer; // Layer to check ground collision
    public Transform groundCheck; // Empty GameObject placed at enemy's feet
    public bool isGrounded;

    [Header("Attack Settings")]
    public GameObject scissorProjectilePrefab; // Scissors projectile
    public Transform firePoint; // The point from where projectiles spawn
    public float attackCooldown = 2f;
    private bool canAttack = true;

    [Header("Jump Back Settings")]
    public bool isJumpingBack = false;
    public float jumpForce = 7f;
    public float jumpCooldown = 10f;
    private float timeLastJumped;
    private bool wantsToJump = false;

    protected void Awake()
    {
        base.Awake();
    }

    void Update()
    {
        if (!IsPlayerInFOV()) return; // Skip updates if player is out of sight

        float distanceToPlayer = Vector3.Distance(transform.position, Target.position);

        // Prioritize attacks over movement
        if (distanceToPlayer <= attackRange && canAttack && !isJumpingBack)
        {
            StartCoroutine(Attack());
        }
        else if (!isJumpingBack)
        {
            ChasePlayer();
        }
    }

    IEnumerator Attack()
    {
        canAttack = false;
        transform.LookAt(new Vector3(Target.position.x, transform.position.y, Target.position.z)); // Look at player
        Animator.SetTrigger("Throw");

        yield return new WaitForSeconds(2.3f); // Delay before throwing scissors

        // Instantiate and fire projectile
        GameObject scissor = Instantiate(scissorProjectilePrefab, firePoint.position, Quaternion.identity);
        NeedleProjectile scissorProjectile = scissor.GetComponent<NeedleProjectile>();
        scissorProjectile.SetTarget(Target.transform.position);

        yield return new WaitForSeconds(attackCooldown);
        canAttack = true;
    }

    private void FixedUpdate()
    {
        if (!IsPlayerInFOV()) return; // Skip physics updates if player is out of sight

        isGrounded = Physics.CheckSphere(groundCheck.position, 0.1f, groundLayer);

        if (PlayerIsClose() && Time.time >= (timeLastJumped + jumpCooldown))
        {
            wantsToJump = true;
        }

        if (isGrounded && wantsToJump)
        {
            JumpBack();
        }
    }

    private bool PlayerIsClose()
    {
        return Vector3.Distance(transform.position, Target.position) < attackRange;
    }

    void JumpBack()
    {
        if (isJumpingBack || rb.isKinematic) return; // Avoid jumping if already in air

        isJumpingBack = true;
        wantsToJump = false;
        Animator.SetTrigger("Jump");

        // Select random jump direction
        Vector3[] jumpDirections = { Vector3.back, Vector3.left, Vector3.right };
        Vector3 jumpDirection = jumpDirections[Random.Range(0, jumpDirections.Length)] + Vector3.up;

        rb.linearVelocity = Vector3.zero; // Reset velocity before applying force
        rb.AddForce(jumpDirection * jumpForce, ForceMode.Impulse);
        timeLastJumped = Time.time;

        StartCoroutine(JumpCooldownRoutine());
    }

    IEnumerator JumpCooldownRoutine()
    {
        yield return new WaitForSeconds(2f); // Wait while in air
        isJumpingBack = false;
        yield return new WaitForSeconds(jumpCooldown); // Wait before allowing next jump
        wantsToJump = true;
    }
}
