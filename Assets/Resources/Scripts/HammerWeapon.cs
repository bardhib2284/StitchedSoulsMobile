using System.Collections;
using UnityEngine;

public class HammerWeapon : Weapon
{
    public float knockbackForce = 10f;
    public float knockbackUpward = 2f;
    public int DamageOverride;
    public override void Start()
    {
        base.Start();
        damage = DamageOverride;
    }
    public override void ApplyEffect(Collider enemy)
    {
        EnemyRagdoll enemyRagdoll = enemy.GetComponent<EnemyRagdoll>();

        if (enemyRagdoll != null)
        {
            Vector3 knockbackDirection = (enemy.transform.position - transform.position).normalized;
            knockbackDirection.y += knockbackUpward; // Add some upward lift

            enemyRagdoll.ActivateRagdoll(knockbackDirection, knockbackForce);
            StartCoroutine(DramaEffect());
        }
        
    }
    IEnumerator DramaEffect()
    {
        Time.timeScale = 0.15f;
        yield return new WaitForSecondsRealtime(1f);
        Time.timeScale = 1f;
    }
    public override void Attack()
    {
        if (!canAttack) return;
        canAttack = false;
        if(animator == null)
        {
            animator = GetComponentInParent<Animator>();
        }
        
        // Play attack animation
        if (animator != null)
        {
            animator.SetTrigger("HammerAttack");
        }

        // Enable the collider during animation for hit detection
        Invoke(nameof(EnableWeaponCollider), 0.35f); // Enable shortly after animation starts
        Invoke(nameof(DisableWeaponCollider), 0.88f); // Disable after impact

        // Reset cooldown
        Invoke(nameof(ResetAttack), attackCooldown);
    }
}
