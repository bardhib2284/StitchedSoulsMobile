using Assets.Resources.Scripts;
using System.Collections;
using UnityEngine;

public class ZombieAcidAttack : MonoBehaviour
{
    [Header("Acid Attack Settings")]
    public GameObject acidPrefab;  // Prefabi i acidit
    public Transform firePoint;    // Pika nga ku gjuan acidi
    public float attackRange = 0.4f;  // Distanca maksimale p�r t� sulmuar
    public float maxAcidDistance = 0.2f; // Distanca maksimale e fluturimit t� acidit
    public float acidSpeed = 5f;   // Shpejt�sia e acidit
    public float attackCooldown = 3f; // Koha midis sulmeve
    public bool Attacking = false;
    private Transform player;
    public bool canAttack = true;
    public ZombieAI ZombieAI;
    void Start()
    {
        ZombieAI = GetComponent<ZombieAI>();
    }

    void Update()
    {

    }
    public void ShootAcidCor()
    {
        StartCoroutine(ShootAcid());
    }

    private IEnumerator ShootAcid()
    {
        player = ZombieAI.Target;
        if(player != null)
        {
            canAttack = false;
            Animator animator = GetComponent<Animator>();
            animator.SetTrigger("Bite");
            ZombieAI.Attacking = true;
            ZombieAI.IsStunned = true;
            yield return new WaitForEndOfFrame();
            yield return new WaitForSecondsRealtime(0.4f);
            yield return new WaitForSecondsRealtime(0.4f);
            if (ZombieAI.GetDistanceToPlayer() <= attackRange)
            {
                if (ZombieAI.IsStunned && !ZombieAI.isDead)
                {
                    yield return new WaitForEndOfFrame();
                    yield return new WaitForSecondsRealtime(0.1f);

                    if (!this.GetComponent<EnemyRagdoll>().mainRigidbody.isKinematic)
                    {
                        yield return new WaitForEndOfFrame();
                        yield return new WaitForSecondsRealtime(0.1f);

                        if (ZombieAI.DistanceToPlayer <= attackRange)
                        {
                            yield return new WaitForEndOfFrame();
                            yield return new WaitForSecondsRealtime(0.1f);
                            if (!player.GetComponent<PlayerController>().IsRolling() && !player.GetComponent<PlayerController>().Attacking)
                            {
                                yield return new WaitForEndOfFrame();
                                yield return new WaitForSeconds(0.1f);
                                player.GetComponent<PlayerController>().enabled = false;
                                player.GetComponent<PlayerController>().StopAllCoroutines();
                                var canvas = Object.FindFirstObjectByType<Canvas>();
                                var CanvasBlocker = canvas.transform.GetChild(canvas.transform.childCount - 1);
                                CanvasBlocker.gameObject.SetActive(true);

                                // Llogarit drejtimin drejt lojtarit
                                Vector3 directionToPlayer = (player.position - firePoint.position).normalized;
                                // Krijo nj� instance t� acidit

                                yield return new WaitForEndOfFrame();
                                player.GetComponent<Animator>().SetTrigger("HeadHit");
                                Camera.main.GetComponent<CameraController>().enabled = false;
                                var currentCameraRotation = Camera.main.transform.localEulerAngles;
                                Camera.main.transform.LookAt(player.transform.position);
                                var cameraDestination = 32;
                                while (Camera.main.fieldOfView > cameraDestination)
                                {
                                    Camera.main.fieldOfView = Mathf.Lerp(Camera.main.fieldOfView, cameraDestination / 1.4f, Time.deltaTime * 3f);
                                    yield return new WaitForEndOfFrame();
                                }
                                yield return new WaitForSeconds(2f);
                                cameraDestination = 60;
                                while (Camera.main.fieldOfView < cameraDestination)
                                {
                                    Camera.main.fieldOfView = Mathf.Lerp(Camera.main.fieldOfView, cameraDestination * 1.4f, Time.deltaTime * 3f);
                                    yield return new WaitForEndOfFrame();
                                }
                                Camera.main.transform.localEulerAngles = currentCameraRotation;
                                player.GetComponent<Animator>().SetTrigger("Fall");
                                yield return new WaitForSeconds(0.1f);
                                // Merr drejtimin nga zombie tek lojetari
                                Vector3 knockbackDirection = (player.transform.position - transform.position).normalized;
                                // Shto një forcë në atë drejtim për ta larguar lojetarin nga zombie
                                if (!player.GetComponent<Rigidbody>().isKinematic)
                                {
                                    player.GetComponent<Rigidbody>().AddForce(knockbackDirection * 5f + Vector3.up * 2f, ForceMode.Impulse);
                                }

                                yield return new WaitForSeconds(1f);
                                player.GetComponent<Animator>().SetTrigger("StandUp");
                                yield return new WaitForSecondsRealtime(0.5f);
                                player.GetComponent<PlayerController>().enabled = true;
                                Camera.main.GetComponent<CameraController>().enabled = true;
                                CanvasBlocker.gameObject.SetActive(false);
                                GetComponent<EnemyAI>().IsStunned = false;
                                ZombieAI.Attacking = false;
                                // Prisni pak para se t� lejojm� nj� sulm tjet�r
                                yield return new WaitForSeconds(attackCooldown);
                                canAttack = true;
                                ZombieAI.IsStunned = false;
                            }
                            else
                            {
                                yield return new WaitForSeconds(attackCooldown);
                                canAttack = true;
                                ZombieAI.Attacking = false; ZombieAI.IsStunned = false;

                            }
                        }
                        else
                        {
                            yield return new WaitForSeconds(attackCooldown);
                            canAttack = true; ZombieAI.Attacking = false; ZombieAI.IsStunned = false;


                        }
                    }
                    else
                    {
                        yield return new WaitForSeconds(attackCooldown);
                        canAttack = true; ZombieAI.Attacking = false;
                        ZombieAI.IsStunned = false;

                    }
                }
                else
                {
                    yield return new WaitForSeconds(attackCooldown);
                    canAttack = true; ZombieAI.Attacking = false;
                    ZombieAI.IsStunned = false;

                }
            }
            else
            {
                yield return new WaitForSeconds(attackCooldown);
                canAttack = true; ZombieAI.Attacking = false;
                ZombieAI.IsStunned = false;

            }
        }
        
    }
}
