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
    private Coroutine attackCoroutine; // ✅ Track current attack coroutine
    
    void Awake()
    {
        zombieAI = GetComponent<ZombieAI>();
    }

    public void StartAttack()
    {
        // ✅ Stop previous attack if still running
        if (attackCoroutine != null)
        {
            StopCoroutine(attackCoroutine);
        }
        attackCoroutine = StartCoroutine(ShootAcid());
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

        // **Mid-Attack Check: Did the zombie die before finishing attack?**
        if (zombieAI.IsRagdollActive() || zombieAI.isDead)
        {
            // ✅ FIX: Reset canAttack immediately when hit during attack
            canAttack = true;
            zombieAI.CanBeInterrupted = true;
            attackCoroutine = null; // ✅ Clear coroutine reference
            CancelAttack();
            yield break;
        }

        // **Ensure player is still in range mid-attack**
        distanceToPlayer = Vector3.Distance(transform.position, player.position);
        if (distanceToPlayer > attackRange || player.GetComponent<PlayerController>().IsRolling())
        {
            // ✅ Player escaped! Zombie continues animation but CAN be interrupted
            // This gives player a chance to punish the zombie for missing
            yield return new WaitForSeconds(3f);
            CancelAttack();
            yield break;
        }

        // ✅ Player is still in range - NOW make zombie invulnerable during hit
        zombieAI.CanBeInterrupted = false;

        // **Knockback Effect (Only if zombie is still active)**
        if (!zombieAI.IsRagdollActive())
        {
            PlayerController playerController = player.GetComponent<PlayerController>();
            PlayerHealth playerHealth = player.GetComponent<PlayerHealth>();
            Animator playerAnimator = player.GetComponent<Animator>();
            var CanvasBlocker = zombieAI.CanvasBlocker;
            CanvasBlocker.gameObject.SetActive(true);
            // **Disable Player Movement**
            playerController.enabled = false;
            playerController.StopAllCoroutines();
            yield return new WaitForEndOfFrame();
            playerAnimator.enabled = true;
            playerAnimator.SetTrigger("HeadHit");

            // ✅ Deal damage to player
            if (playerHealth != null)
            {
                playerHealth.TakeDamage(20f); // Zombie attack deals 20 damage
            }

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
        attackCoroutine = null; // ✅ Clear coroutine reference when complete
    }

    private void CancelAttack()
    {
        zombieAI.currentState = EnemyAI.EnemyState.Chasing;
        canAttack = true;
        attackCoroutine = null; // ✅ Clear coroutine reference
    }
}
