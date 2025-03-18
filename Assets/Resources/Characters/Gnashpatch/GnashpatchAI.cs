using Assets.Resources.Scripts;
using System.Collections;
using UnityEngine;

public class GnashpatchAI : EnemyAI
{
    public LayerMask groundLayer; // Set this to detect ground objects
    public Transform groundCheck; // Empty GameObject placed at player's feet
    public bool isGrounded;
    [Header("Gnashpatch Settings")]
    public GameObject scissorProjectilePrefab; // Prefabi i g�rsh�r�ve q� do t� hedh�
    public Transform firePoint; // Vendi nga ku del projektili
    public float attackRange = 10f; // Distanca e sulmit
    public float attackCooldown = 2f; // Koha mes sulmeve
    public float safeDistance = 3f; // Distanca minimale para k�rcimit mbrapa
    private bool canAttack = true;

    [Header("Jump Back Settings")]
       // Kontroll nëse mund të kërcejë
    public bool isJumpingBack = false;
    public float jumpForce = 7f; // Adjust for higher or lower jumps
    public float jumpCooldown = 10f;
    public bool CanJump = false;
    public float TimeLastJumped = 0f;
    public bool WantsToJump;



    protected void Start()
    {
        base.Start();
    }

    void Update()
    {
        if (!IsPlayerInFOV()) return; // N�se lojtari nuk �sht� brenda FOV, mos b�j asgj�
        this.transform.LookAt(Target.position);
        float distanceToPlayer = Vector3.Distance(transform.position, Target.position);

        if (isJumpingBack)
            return;
        if (distanceToPlayer <= attackRange && canAttack)
        {
            isJumpingBack = false;
            StartCoroutine(Attack());
        }
        else
        {
            ChasePlayer(); // P�rdor ndjekjen nga EnemyAI n�se �sht� jasht� range-it t� sulmit
        }
    }

    IEnumerator Attack()
    {
        canAttack = false;
        transform.LookAt(new Vector3(Target.position.x, transform.position.y, Target.position.z)); // Shiko lojtarin
        Animator.SetTrigger("Throw");
        yield return new WaitForSeconds(2.3f);
        // Krijo g�rsh�r�t dhe drejtoji nga lojtari
        GameObject scissor = Instantiate(scissorProjectilePrefab, firePoint.position, Quaternion.identity);
        NeedleProjectile scissorProjectile = scissor.GetComponent<NeedleProjectile>();
        scissorProjectile.SetTarget(Target.transform.position);

        yield return new WaitForSeconds(attackCooldown);
        canAttack = true;
    }
    private void FixedUpdate()
    {
        if (!IsPlayerInFOV()) return; // N�se lojtari nuk �sht� brenda FOV, mos b�j asgj�

        isGrounded = Physics.CheckSphere(groundCheck.position, 0.1f, groundLayer);
        if (PlayerIsClose() && Time.time >= (TimeLastJumped + jumpCooldown))
            WantsToJump = true;
        if (isGrounded && WantsToJump)
        {
            JumpBack();
            WantsToJump = false;
        }
    }
    private bool PlayerIsClose()
    {
        float distance = Vector3.Distance(transform.position, Target.position);
        Debug.Log("Distanca mes " + this.name + " " + distance);
        return distance < safeDistance; // Nëse lojtari është afër, kthehet e vërtetë
    }
    void JumpBack()
    {
        rb.linearVelocity = new Vector3(rb.linearVelocity.x, 0, rb.linearVelocity.z); // Reset Y velocity before jumping
        var rng = Random.Range(0, 3);
        Animator.SetTrigger("Jump");
        if (rng == 0)
        {
            if(!rb.isKinematic)
            rb.AddForce((Vector3.back + Vector3.up) * jumpForce, ForceMode.Impulse);
            TimeLastJumped = Time.time;
        }
        else if (rng == 1)
        {
            if (!rb.isKinematic)
                rb.AddForce((Vector3.left + Vector3.up) * jumpForce, ForceMode.Impulse);
            TimeLastJumped = Time.time;
        }
        else if (rng == 2)
        {
            if (!rb.isKinematic)
                rb.AddForce((Vector3.right + Vector3.up) * jumpForce, ForceMode.Impulse);
            TimeLastJumped = Time.time;
        }
        StartCoroutine(IsJumping());
    }
    IEnumerator IsJumping()
    {
        WantsToJump = false;
        isJumpingBack = true;
        yield return new WaitForSeconds(2f);
        isJumpingBack = false;
        yield return new WaitForSeconds(jumpCooldown);
        WantsToJump = true;
    }
}
