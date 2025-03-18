using System.Collections;
using UnityEngine;

public class ThreadTrapAbility : BossAbility
{
    public GameObject threadTrapPrefab;
    public Transform firePoint;
    public float threadSpeed = 15f;
    public float pullStrength = 5f;
    public float effectDuration = 3f;

    public override void ActivateAbility(Transform target)
    {
        if (!CanUse()) return;
        this.GetComponent<Animator>().SetTrigger("Thread");
        GameObject thread = Instantiate(threadTrapPrefab, firePoint.position, Quaternion.identity);
        ThreadTrap trap = thread.GetComponent<ThreadTrap>();
        trap.Initialize(target, threadSpeed, pullStrength, effectDuration,this.transform);

        StartCooldown(); // Start ability cooldown
    }
}
