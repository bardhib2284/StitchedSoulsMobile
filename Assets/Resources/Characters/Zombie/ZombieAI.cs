using Assets.Resources.Scripts;
using System.Collections;
using UnityEngine;

public class ZombieAI : EnemyAI
{
    private bool isChasing = false;
    private bool isMoving = false;
    ZombieAcidAttack ZombieAcidAttack;
    EnemyRagdoll EnemyRagdoll;
    public GameObject AcidPrefab;
    void Start()
    {
        base.Start();
        ZombieAcidAttack = GetComponent<ZombieAcidAttack>();
        EnemyRagdoll = GetComponent<EnemyRagdoll>();
    }

    void FixedUpdate()
    {
        if (Target != null && !isChasing && !Attacking)
        {
            if(IsPlayerInFOV())
            {
                StartChasing();
            }
        }
        if (isMoving && Target != null)
        {
            if(!IsStunned && !Attacking)
            {
                ChasePlayer();
            }
            if (Target != null)
            {
                var DistanceToPlayer = Vector3.Distance(transform.position, Target.position);
                if (DistanceToPlayer <= ZombieAcidAttack.attackRange && ZombieAcidAttack.canAttack)
                {
                    if(!IsStunned && !EnemyRagdoll.mainRigidbody.isKinematic)
                        GetComponent<ZombieAcidAttack>().ShootAcidCor();
                }
            }
        }
    }

    public float GetDistanceToPlayer()
    {
        if (IsPlayerInFOV() && Target != null)
            return DistanceToPlayer = Vector3.Distance(transform.position, Target.position);
        else
            return 1000;
    }

    // Call this when the zombie sees the player
    public void StartChasing()
    {
        isChasing = true;
        StartCoroutine(Chase());
    }


    public IEnumerator Chase()
    {
        transform.LookAt(Target.position);
        GetComponent<Animator>().SetTrigger("Roar");
        yield return new WaitForSeconds(2f);
        isMoving = true;
        GetComponent<Animator>().SetTrigger("Walk");
    }
    // Call this when the zombie loses sight of the player
    public void StopChasing()
    {
        isChasing = false;
        isMoving = false;
        rb.linearVelocity = Vector3.zero; // Stop movement when the player is lost
    }


    public override void SetStunnedFalse()
    {
        base.SetStunnedFalse();
        ZombieAcidAttack.canAttack = true;
    }

    public override void SetStunnedTrue()
    {
        base.SetStunnedTrue();
        ZombieAcidAttack.canAttack = false;
        
    }

}
