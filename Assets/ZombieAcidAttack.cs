using System.Collections;
using UnityEngine;

public class ZombieAcidAttack : MonoBehaviour
{
    [Header("Acid Attack Settings")]
    public GameObject acidPrefab;
    public Transform firePoint;
    public float attackRange = 0.4f;
    public float attackCooldown = 3f;
    public bool canAttack = true;

    private ZombieAI zombieAI;
    private Transform player;
    
    void Awake()
    {
        zombieAI = GetComponent<ZombieAI>();
    }

    public IEnumerator ShootAcid()
    {
        // **Pre-Attack Check: Ensure zombie isn't dead or ragdolled**
        if (!canAttack || zombieAI.currentState != EnemyAI.EnemyState.Chasing || zombieAI.IsRagdollActive() || zombieAI.isDead)
        {
            yield break; // Cancel attack
        }

        player = zombieAI.Target;
        if (player == null) yield break;

        // **Ensure player is still within range before starting attack**
        float distanceToPlayer = Vector3.Distance(transform.position, player.position);
        if (distanceToPlayer > attackRange || player.GetComponent<PlayerController>().IsRolling())
        {
            yield break; // Cancel attack if player dodged before it started
        }

        canAttack = false;
        zombieAI.currentState = EnemyAI.EnemyState.Attacking;
        zombieAI.Animator.SetTrigger("Bite");

        yield return new WaitForSeconds(0.8f); // Delay before checking again
        zombieAI.CanBeInterrupted = false;
        // **Mid-Attack Check: Did the zombie die before finishing attack?**
        if (zombieAI.IsRagdollActive() || zombieAI.isDead)
        {
            yield return new WaitForSeconds(3f);
            CancelAttack();
            yield break;
        }

        // **Ensure player is still in range mid-attack**
        distanceToPlayer = Vector3.Distance(transform.position, player.position);
        if (distanceToPlayer > attackRange || player.GetComponent<PlayerController>().IsRolling())
        {
            yield return new WaitForSeconds(3f);
            CancelAttack();
            yield break;
        }

        // **Knockback Effect (Only if zombie is still active)**
        if (!zombieAI.IsRagdollActive())
        {
            PlayerController playerController = player.GetComponent<PlayerController>();
            Animator playerAnimator = player.GetComponent<Animator>();
            var CanvasBlocker = zombieAI.CanvasBlocker;
            CanvasBlocker.gameObject.SetActive(true);
            // **Disable Player Movement**
            playerController.enabled = false;
            playerController.StopAllCoroutines();
            yield return new WaitForEndOfFrame();
            playerAnimator.enabled = true;
            playerAnimator.SetTrigger("HeadHit");

            // **Camera Effect**
            Camera.main.GetComponent<CameraController>().enabled = false;
            var currentCameraRotation = Camera.main.transform.localEulerAngles;
            Camera.main.transform.LookAt(player.transform.position);

            float zoomInFOV = 32;
            while (Camera.main.fieldOfView > zoomInFOV)
            {
                Camera.main.fieldOfView = Mathf.Lerp(Camera.main.fieldOfView, zoomInFOV / 1.4f, Time.deltaTime * 3f);
                yield return null;
            }

            yield return new WaitForSeconds(2f);

            // **Trigger Player Hit Animation**

            yield return new WaitForSeconds(0.1f);

            // **Knockback Effect**
            Vector3 knockbackDirection = (player.position - transform.position).normalized;
            if (!player.GetComponent<Rigidbody>().isKinematic)
            {
                player.GetComponent<Rigidbody>().AddForce(knockbackDirection * 5f + Vector3.up * 2f, ForceMode.Impulse);
            }

            yield return new WaitForSeconds(1f);

            // **Trigger Player Stand Up Animation**
            playerAnimator.SetTrigger("StandUp");

            // **Reset Camera**
            float defaultFOV = 60;
            while (Camera.main.fieldOfView < defaultFOV)
            {
                Camera.main.fieldOfView = Mathf.Lerp(Camera.main.fieldOfView, defaultFOV * 1.4f, Time.deltaTime * 3f);
                yield return null;
            }
            Camera.main.transform.localEulerAngles = currentCameraRotation;
            Camera.main.GetComponent<CameraController>().enabled = true;

            // **Unblock Player & UI**
            yield return new WaitForSeconds(0.5f);
            playerController.enabled = true;
            playerController.AnimatorController.enabled = true;
            playerController.SetIsAttackingFalse();
            CanvasBlocker.gameObject.SetActive(false);
            zombieAI.CanBeInterrupted = true;
        }

        // **Resume Chasing**
        zombieAI.currentState = EnemyAI.EnemyState.Chasing;

        yield return new WaitForSeconds(attackCooldown);
        canAttack = true;
    }

    private void CancelAttack()
    {
        zombieAI.currentState = EnemyAI.EnemyState.Chasing;
        canAttack = true;
    }
}
