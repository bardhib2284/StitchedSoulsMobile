using System.Collections;
using UnityEngine;

public class ZombieAI : EnemyAI
{
    private bool isMoving = false;
    private ZombieAcidAttack zombieAcidAttack;
    private EnemyRagdoll enemyRagdoll;

    private bool HasRoared = false;
    void Awake()
    {
        base.Awake();
        zombieAcidAttack = GetComponent<ZombieAcidAttack>();
        enemyRagdoll = GetComponent<EnemyRagdoll>();
    }
    public bool IsRagdollActive()
    {
        return enemyRagdoll.IsRagdollActive();
    }
    void FixedUpdate()
    {
        if (isDead) return;

        // Always rotate to player if in Chasing state
        if (currentState == EnemyState.Chasing && Target != null)
        {
            FaceTarget(); // Ensures the enemy is facing the player even when not moving
        }

        // Start chasing if player enters FOV
        if (Target != null && currentState == EnemyState.Idle && IsPlayerInFOV())
        {
            StartCoroutine(StartChase());
        }

        if (isMoving && currentState == EnemyState.Chasing)
        {
            ChasePlayer();

            float distanceToPlayer = Vector3.Distance(transform.position, Target.position);
            if (distanceToPlayer <= zombieAcidAttack.attackRange && zombieAcidAttack.canAttack)
            {
                float angle = Vector3.Angle(transform.forward, (Target.position - transform.position).normalized);
                if (angle < fieldOfView)
                {
                    // ✅ Use StartAttack() to properly manage coroutine lifecycle
                    zombieAcidAttack.StartAttack();
                }
            }
        }
    }

    private IEnumerator StartChase()
    {
        if(!HasRoared)
        {
            Animator.SetTrigger("Roar");
            HasRoared = true;
            yield return new WaitForSeconds(2f);
        }
        else
        {
            currentState = EnemyState.Chasing;
            isMoving = true;
            Animator.CrossFade("Walk", 0.1f);
        }
    }

    // New method to keep the enemy always facing the player
    private void FaceTarget()
    {
        if (Target == null) return;

        Vector3 direction = (Target.position - transform.position).normalized;
        Quaternion targetRotation = Quaternion.LookRotation(new Vector3(direction.x, 0, direction.z));
        transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * rotationSpeed);
    }
}
