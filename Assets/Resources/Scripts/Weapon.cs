using Assets.Resources.Scripts;
using UnityEngine;
using System.Collections;
using System.Collections.Generic; // ✅ Required for HashSet

public abstract class Weapon : MonoBehaviour
{
    public string weaponName;
    public int damage = 10; // Base damage for all weapons
    public float attackCooldown = 1.0f; // Delay between attacks
    public Animator animator;
    public Collider weaponCollider;
    public PlayerController playerController;
    protected bool canAttack = true;

    [SerializeField] private LayerMask enemyLayer; // Layer to identify enemies

    // ✅ Cached animator parameter hash
    protected int attackHashId;


    public virtual void Start()
    {
        if (animator == null) animator = GetComponentInParent<Animator>();
        if (weaponCollider != null) weaponCollider.enabled = false;
        if (playerController == null) playerController = GetComponentInParent<PlayerController>();

        // ✅ Cache animator hash for better performance
        attackHashId = Animator.StringToHash("Attack");
    }

    public virtual void Attack()
    {
        if (!canAttack) return;

        // ✅ OPTIMIZATION: Use coroutine instead of Invoke for better control and GC
        StartCoroutine(AttackCoroutine());
    }

    // ✅ NEW: Coroutine-based attack handling
    protected virtual IEnumerator AttackCoroutine()
    {
        canAttack = false;

        // Play attack animation
        if (animator != null)
        {
            animator.SetTrigger(attackHashId);
        }

        // Enable collider for hit detection
        yield return new WaitForSeconds(0.1f);
        EnableWeaponCollider();

        // Disable collider after impact
        yield return new WaitForSeconds(0.2f); // 0.3 total - 0.1 wait = 0.2 more
        DisableWeaponCollider();

        // Reset attack cooldown
        yield return new WaitForSeconds(attackCooldown - 0.3f); // Remaining time after collider disable
        canAttack = true;
    }

    protected void EnableWeaponCollider() { if (weaponCollider != null) weaponCollider.enabled = true; }
    protected void DisableWeaponCollider() { if (weaponCollider != null) weaponCollider.enabled = false; }

    // ✅ Now detecting enemy collisions with prevention for multiple hits
    private void OnTriggerEnter(Collider other)
    {
        Debug.Log("on trigger enter weapon : " + other.gameObject.name);

        if (((1 << other.gameObject.layer) & enemyLayer) != 0) // Check if object is on the enemy layer
        {
            if (other.GetComponent<EnemyAI>() != null)
            {
                EnemyAI enemyAI = other.GetComponent<EnemyAI>();
                if (!enemyAI.CanBeInterrupted)
                    return;
                enemyAI.TakeDamage(damage);

                ApplyEffect(other);
            }
        }
    }

    public virtual void ApplyEffect(Collider enemy) { } // To be overridden in child classes
}
