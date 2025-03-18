using Assets.Resources.Scripts;
using UnityEngine;

public abstract class Weapon : MonoBehaviour
{
    public string weaponName;
    public int damage = 10; // Base damage for all weapons
    public float attackCooldown = 1.0f; // Delay between attacks
    public Animator animator;
    public Collider weaponCollider;

    protected bool canAttack = true;

    [SerializeField] private LayerMask enemyLayer; // Layer to identify enemies

    public virtual void Start()
    {
        if (animator == null) animator = GetComponent<Animator>();
        if (weaponCollider != null) weaponCollider.enabled = false;
    }

    public virtual void Attack()
    {
        if (!canAttack) return;
        canAttack = false;

        // Play attack animation
        if (animator != null)
        {
            animator.SetTrigger("Attack");
        }

        // Enable the collider during animation for hit detection
        Invoke(nameof(EnableWeaponCollider), 0.1f); // Enable shortly after animation starts
        Invoke(nameof(DisableWeaponCollider), 0.3f); // Disable after impact

        // Reset cooldown
        Invoke(nameof(ResetAttack), attackCooldown);
    }

    protected void EnableWeaponCollider() { if (weaponCollider != null) weaponCollider.enabled = true; }
    protected void DisableWeaponCollider() { if (weaponCollider != null) weaponCollider.enabled = false; }
    protected void ResetAttack() { canAttack = true; }

    // 🔹 Now detecting enemy collisions
    private void OnTriggerEnter(Collider other)
    {
        Debug.Log("on trigger enter : " + other.gameObject.name);
        if (((1 << other.gameObject.layer) & enemyLayer) != 0) // Check if object is on the enemy layer
        {
            if(other.GetComponent<EnemyAI>() != null)
            {
                EnemyAI enemyAI = other.GetComponent<EnemyAI>();
                enemyAI.TakeDamage(damage);
                ApplyEffect(other);
            }
        }
    }

    public virtual void ApplyEffect(Collider enemy) { } // To be overridden in child classes
}
