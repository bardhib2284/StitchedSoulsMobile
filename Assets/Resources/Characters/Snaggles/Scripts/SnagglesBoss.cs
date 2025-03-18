using UnityEngine;
using System.Collections.Generic;
using System.Collections;
using System.Linq;

public class SnagglesBoss : MonoBehaviour
{
    public List<BossAbility> abilities = new List<BossAbility>();
    public Transform playerTarget;
    private Quaternion targetRotation;
    public float rotationSpeed = 5f; // How fast Snaggles rotates

    private BossAbility currentAbility;
    private float abilityCheckCooldown = 5f;
    private float lastAbilityCheckTime;

    private bool usedAlready = false;
    void Start()
    {
        // Auto-assign abilities if attached to Snaggles
        abilities.AddRange(GetComponents<BossAbility>());
        StartCoroutine(CheckAndRotate());
        lastAbilityCheckTime = Time.time * 20f;
    }

    void Update()
    {
        if (Time.time >= lastAbilityCheckTime + abilityCheckCooldown)
        {
            ChooseAbility();
            lastAbilityCheckTime = Time.time;
            usedAlready = true;
        }

    }

    void ChooseAbility()
    {
        List<BossAbility> usableAbilities = abilities.FindAll(a => a.CanUse());

        if (usableAbilities.Count > 0)
        {
            currentAbility = usableAbilities[Random.Range(0, usableAbilities.Count)];
            currentAbility.ActivateAbility(playerTarget);
        }
    }

    IEnumerator CheckAndRotate()
    {
        while (true)
        {
            yield return new WaitForSeconds(0.5f); // Check every 0.5 seconds

            if (playerTarget == null) yield break;

            Vector3 directionToPlayer = (playerTarget.position - transform.position).normalized;
            directionToPlayer.y = 0; // Prevent tilting up/down

            // Get the target rotation Snaggles should have
            targetRotation = Quaternion.LookRotation(directionToPlayer);

            // Check if Snaggles is not already facing the player
            if (Quaternion.Angle(transform.rotation, targetRotation) > 5f)
            {
                if(abilities.FirstOrDefault(x=> x is SeamRipperAbility) != null)
                {
                    var seamReaper = abilities.FirstOrDefault(x => x is SeamRipperAbility);
                    if (!(seamReaper as SeamRipperAbility).isDashing)
                    {
                        StartCoroutine(RotateTowardsPlayer());
                    }
                }
                
            }
        }
    }

    IEnumerator RotateTowardsPlayer()
    {
        while (Quaternion.Angle(transform.rotation, targetRotation) > 1f)
        {
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, rotationSpeed * Time.deltaTime);
            yield return null;
        }
    }
}
