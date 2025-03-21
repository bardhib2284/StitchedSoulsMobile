using System;
using System.Collections;
using UnityEngine;

public class EnemyAI : MonoBehaviour
{
    public enum EnemyState { Idle, Chasing, Attacking, Stunned, Dead }
    public EnemyState currentState = EnemyState.Idle;

    [Header("Components")]
    protected Rigidbody rb;
    public Transform Target;
    public Animator Animator;
    public PlayerController PlayerController;

    [Header("Movement Settings")]
    public float moveSpeed = 3f;
    public float stoppingDistance = 1.5f;
    public float rotationSpeed = 5f;

    [Header("Enemy Attributes")]
    public HealthUI HealthUI;
    public float maxHealth = 100;
    public float health = 100f;

    public float fieldOfView = 70f;
    public float attackRange = 0.4f;

    public bool isDead = false;

    public void Awake()
    {
        rb = GetComponent<Rigidbody>();
        Animator = GetComponent<Animator>();
        if(HealthUI != null)
            HealthUI.SetHealth(health);
    }

    public bool IsPlayerInFOV()
    {
        if (Target == null) return false;

        Vector3 directionToPlayer = (Target.position - transform.position).normalized;
        float dotProduct = Vector3.Dot(transform.forward, directionToPlayer);
        float angleToPlayer = Mathf.Acos(dotProduct) * Mathf.Rad2Deg;

        return angleToPlayer < fieldOfView;
    }

    public virtual void ChasePlayer()
    {
        if (currentState != EnemyState.Chasing || isDead || Target == null) return;

        float distanceToPlayer = Vector3.Distance(transform.position, Target.position);
        if (distanceToPlayer > stoppingDistance)
        {
            Vector3 direction = (Target.position - transform.position).normalized;
            rb.linearVelocity = new Vector3(direction.x * moveSpeed, rb.linearVelocity.y, direction.z * moveSpeed);

            // Smooth rotation towards player
            Quaternion targetRotation = Quaternion.LookRotation(new Vector3(direction.x, 0, direction.z));
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * rotationSpeed);
        }
        else
        {
            rb.linearVelocity = Vector3.zero;
        }
    }

    public void TakeDamage(float damage)
    {
        health -= damage;
        HealthUI.UpdateHealth(health);
        if (health <= 0)
        {
            isDead = true;
            currentState = EnemyState.Dead;
            Animator.SetTrigger("Die");
            Destroy(gameObject, 3f);
        }
    }

    public void SetStunned(bool stunned)
    {
        currentState = stunned ? EnemyState.Stunned : EnemyState.Idle;
    }

    public bool IsDead()
    {
        return isDead;
    }

    public void GetHit()
    {
        StopAllCoroutines();
        StartCoroutine(GetHitEnumerator());
    }

    IEnumerator GetHitEnumerator()
    {
        currentState = EnemyState.Stunned;
        Animator.SetTrigger("Hit");
        yield return new WaitForSeconds(1);
        currentState = EnemyState.Chasing;
    }
}
