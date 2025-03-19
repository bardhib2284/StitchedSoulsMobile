using AutoLOD.Utilities.Heap;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace Assets.Resources.Scripts
{
    public class EnemyAI : MonoBehaviour
    {
        [Header("Components")]
        protected Rigidbody rb;
        public PlayerController PlayerController;
        public Transform Target;
        public Animator Animator;


        [Header("Movement Settings")]
        public float moveSpeed = 3f;
        public float stoppingDistance = 1.5f;
        public float Health;

        public bool IsStunned = false;
        public bool Attacking = false;

        public float DistanceToPlayer = 0;

        [Header("Enemy Attributes")]
        public HealthUI HealthUI;
        public float MaxHealth = 100;
        public float CurrentHealth;
        public float FieldOfView = 70f;
        public EnemyAI() { }

        public void Start()
        {
            CurrentHealth = MaxHealth;
            rb = GetComponent<Rigidbody>();
            Target = GameObject.FindGameObjectWithTag("Player").transform;
            PlayerController = GameObject.FindGameObjectWithTag("Player").GetComponent<PlayerController>();
            Animator = GetComponent<Animator>();
            if(HealthUI != null)
            HealthUI.SetHealth(CurrentHealth);
        }
        public void TakeDamage(float damage) {
            HealthUI.UpdateHealth(CurrentHealth - damage);
            CurrentHealth -= damage;
            if (CurrentHealth <= 0)
            {
                isDead = true;
                this.gameObject.transform.GetChild(2).gameObject.SetActive(false);
                var scripts = GetComponents<MonoBehaviour>();
                foreach (var script in scripts)
                {
                    if (script != null)
                    {
                        script.StopAllCoroutines();
                        script.enabled = false;
                    }
                }
                Destroy(this.gameObject, 3f);
            }
        }

        public bool isDead { get; set; }

        public bool IsDead()
        {
            return isDead;
        }

        public virtual bool IsPlayerInFOV()
        {
            if (Target != null)
            {
                Vector3 directionToPlayer = (Target.position - transform.position).normalized;
                float dotProduct = Vector3.Dot(transform.forward, directionToPlayer);

                // Convert dot product to angle
                float angleToPlayer = Mathf.Acos(dotProduct) * Mathf.Rad2Deg;
                // Check if the player is within 70 degrees in front of the zombie (total 60-degree FOV)
                return angleToPlayer < FieldOfView;
            }
            return false;
        }

        public virtual void ChasePlayer()
        {
            if (!IsStunned || !isDead)
            {
                if (Target == null) return;

                var animatorInfo = GetComponent<Animator>().GetCurrentAnimatorClipInfo(0);
                var current_animation = animatorInfo[0].clip.name;
                if (!current_animation.Contains("Walk"))
                {
                    GetComponent<Animator>().SetTrigger("Walk");
                }

                DistanceToPlayer = Vector3.Distance(transform.position, Target.position);

                if (DistanceToPlayer > stoppingDistance) // Stops when close
                {
                    // Calculate direction towards player
                    Vector3 direction = (Target.position - transform.position).normalized;

                    // Apply movement
                    rb.linearVelocity = new Vector3(direction.x * moveSpeed, rb.linearVelocity.y, direction.z * moveSpeed);

                    // Rotate towards player smoothly
                    Quaternion targetRotation = Quaternion.LookRotation(new Vector3(direction.x, 0, direction.z));
                    transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * 5f);
                }
                else
                {
                    rb.linearVelocity = Vector3.zero; // Stop moving if close
                }
            }
        }


        public virtual void SetStunnedTrue()
        {
            IsStunned = true;
            Attacking = false;
        }
        public virtual void SetStunnedFalse()
        {
            IsStunned = false;
            Attacking = false;
        }
    }
}
