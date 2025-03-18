using UnityEngine;

public class EnemyHealth : MonoBehaviour
{
    public int health = 100;
    private EnemyRagdoll ragdoll;

    void Start()
    {
        ragdoll = GetComponent<EnemyRagdoll>();
    }

    public void TakeDamage(int damage, Vector3 forceDirection, float forceAmount)
    {
        health -= damage;
        ragdoll.ActivateRagdoll(forceDirection, forceAmount);

        if (health <= 0)
        {
            Die(forceDirection, forceAmount);
        }
    }

    void Die(Vector3 forceDirection, float forceAmount)
    {
        Destroy(this); // Remove this script so the enemy stops functioning
    }
}
