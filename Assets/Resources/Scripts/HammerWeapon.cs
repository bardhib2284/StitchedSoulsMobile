using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HammerWeapon : Weapon
{
    public float knockbackForce = 10f;
    public float knockbackUpward = 2f;
    public int DamageOverride;

    public new HashSet<Collider> hitEnemies = new HashSet<Collider>(); // 🛑 Prevents double damage

    // ✅ Cached animator parameter hash for HammerAttack
    private int hammerAttackHashId;

    public override void Start()
    {
        base.Start();
        damage = DamageOverride;

        // ✅ Cache hammer-specific animation parameter
        hammerAttackHashId = Animator.StringToHash("HammerAttack");
    }

    public override void Attack()
    {
        if (!canAttack) return;
        if (playerController.PlayerStamina.UseStamina(3f))
        {
            // ✅ OPTIMIZATION: Use coroutine instead of Invoke for better control
            StartCoroutine(HammerAttackCoroutine());
        }
    }

    // ✅ NEW: Custom coroutine for hammer-specific attack timing
    private IEnumerator HammerAttackCoroutine()
    {
        canAttack = false;
        hitEnemies.Clear(); // 🔄 Reset hit list for this attack

        if (animator == null)
        {
            animator = GetComponentInParent<Animator>();
        }

        // Play attack animation
        if (animator != null)
        {
            animator.SetTrigger(hammerAttackHashId); // ✅ Use hash instead of string
        }

        // Enable collider for hit detection (shortly after animation starts)
        yield return new WaitForSeconds(0.25f);
        EnableWeaponCollider();

        // Disable collider after impact (0.68 - 0.25 = 0.43 seconds)
        yield return new WaitForSeconds(0.43f);
        DisableWeaponCollider();

        // Reset cooldown (full attackCooldown - 0.68 seconds)
        yield return new WaitForSeconds(attackCooldown - 0.68f);
        canAttack = true;
    }

    public override void ApplyEffect(Collider enemy)
    {
        // 🛑 Prevents multiple hits on the same enemy per swing
        if (hitEnemies.Contains(enemy)) return;
        hitEnemies.Add(enemy);

        EnemyAI enemyAI = enemy.GetComponent<EnemyAI>();

        if (enemyAI.health <= 0) // If enemy is dead, apply ragdoll
        {
            EnemyRagdoll enemyRagdoll = enemy.GetComponent<EnemyRagdoll>();

            if (enemyRagdoll != null)
            {
                Vector3 knockbackDirection = (enemy.transform.position - transform.position).normalized;
                knockbackDirection.y += knockbackUpward; // Add some upward force

                enemyRagdoll.ActivateRagdoll(knockbackDirection, knockbackForce);
                StartCoroutine(DramaEffect());
            }
        }
        else
        {
            enemyAI.GetHit();
        }
    }

    IEnumerator DramaEffect()
    {
        playerController.enabled = false;
        Time.timeScale = 0.2f;
        yield return new WaitForSecondsRealtime(1.5f);
        playerController.enabled = true;
        Time.timeScale = 1f;
    }
}
