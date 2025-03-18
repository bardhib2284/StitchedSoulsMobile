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

    private Transform player;
    public bool canAttack = true;
    void Start()
    {
        player = GameObject.FindGameObjectWithTag("Player").transform; // Gjej lojtarin
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
        canAttack = false;
        Animator animator = GetComponent<Animator>();
        animator.SetTrigger("Bite");
        yield return new WaitForEndOfFrame();
        yield return new WaitForSecondsRealtime(0.2f);
        if (GetComponent<ZombieAI>().DistanceToPlayer <= attackRange)
        {
            if (!this.GetComponent<EnemyAI>().IsStunned)
            {
                yield return new WaitForEndOfFrame();
                yield return new WaitForSecondsRealtime(0.2f);

                if (!this.GetComponent<EnemyRagdoll>().mainRigidbody.isKinematic)
                {
                    yield return new WaitForEndOfFrame();
                    yield return new WaitForSecondsRealtime(0.2f);

                    if (GetComponent<ZombieAI>().DistanceToPlayer <= attackRange)
                    {
                        yield return new WaitForEndOfFrame();
                        yield return new WaitForSecondsRealtime(0.2f);
                        if (!player.GetComponent<PlayerController>().IsRolling())
                        {
                            yield return new WaitForEndOfFrame();
                            animator.SetTrigger("Bite");
                            GetComponent<EnemyAI>().IsStunned = true;
                            player.GetComponent<PlayerController>().enabled = false;
                            player.GetComponent<PlayerController>().StopAllCoroutines();
                            var canvas = Object.FindFirstObjectByType<Canvas>();
                            var CanvasBlocker = canvas.transform.GetChild(canvas.transform.childCount - 1);
                            CanvasBlocker.gameObject.SetActive(true);
                            yield return new WaitForSeconds(0.6f);

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
                            // Prisni pak para se t� lejojm� nj� sulm tjet�r
                            yield return new WaitForSeconds(attackCooldown);
                            canAttack = true;
                        }
                        else
                        {
                            animator.SetTrigger("Walk");
                            canAttack = true;
                        }
                    }
                    else
                    {
                        animator.SetTrigger("Walk");
                        canAttack = true;
                    }
                }
                else
                {
                    animator.SetTrigger("Walk");
                    canAttack = true;
                }
            }
            else
            {
                animator.SetTrigger("Walk");
                canAttack = true;
            }
        }
        else
        {
            animator.SetTrigger("Walk");
            canAttack = true;
        }
    }
}
