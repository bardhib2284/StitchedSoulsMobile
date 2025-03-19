using UnityEngine;
using System.Collections.Generic;
using Assets.Resources.Scripts;

public class GunWeapon : Weapon
{
    [Header("Gun Settings")]
    public float fireRate = 0.5f;
    public Transform firePoint;
    public GameObject needleProjectilePrefab;

    private float nextFireTime = 0f;
    public List<EnemyAI> visibleEnemies = new List<EnemyAI>();

    public override void Attack()
    {
        if (animator == null)
        {
            animator = GetComponentInParent<Animator>();
        }

        // Play attack animation
        if (animator != null)
        {
            this.GetComponent<Renderer>().enabled = true;
            animator.SetTrigger("GunAttack");
        }
        if (Time.time >= nextFireTime)
        {
            EnemyAI target = FindClosestEnemy();
            if (target != null)
            {
                Shoot(target);
                nextFireTime = Time.time + fireRate;
            }
            else
            {
                Shoot(null);
                nextFireTime = Time.time + fireRate;
            }
        }
    }

    private bool CanShoot()
    {
        return Input.GetButtonDown("Fire1") && visibleEnemies.Count > 0;
    }

    private EnemyAI FindClosestEnemy()
    {
        EnemyAI closestEnemy = null;
        float minDistance = Mathf.Infinity;
        Vector3 playerPosition = transform.position;

        foreach (EnemyAI enemy in visibleEnemies)
        {
            if (enemy == null || enemy.IsDead())
                continue; // Skip dead enemies

            float distance = Vector3.Distance(playerPosition, enemy.transform.position);
            if (distance < minDistance)
            {
                minDistance = distance;
                closestEnemy = enemy;
            }
        }
        return closestEnemy;
    }

    private void Shoot(EnemyAI target)
    {

        if (target != null)
        {
            // Rotate player to face the enemy
            Vector3 direction = (target.transform.position - transform.position).normalized;
            Quaternion lookRotation = Quaternion.LookRotation(direction);
            //transform.rotation = Quaternion.Euler(0, lookRotation.eulerAngles.y, 0); // Rotate only on Y-axis
            playerController.transform.rotation = lookRotation;
            playerController.transform.LookAt(target.transform.position);
            // Instantiate needle projectile
            GameObject projectile = Instantiate(needleProjectilePrefab, new Vector3(firePoint.position.x, firePoint.position.y, firePoint.position.z), Quaternion.Euler(0, playerController.transform.eulerAngles.y, 0));
            projectile.transform.LookAt(target.transform);
            ShotBehavior needle = projectile.GetComponent<ShotBehavior>();
            if (needle != null)
            {
                needle.enemy = target.transform;
            }
        }
        else
        {
            GameObject projectile = Instantiate(needleProjectilePrefab, new Vector3(firePoint.position.x,firePoint.position.y , firePoint.position.z), Quaternion.Euler(0, playerController.transform.eulerAngles.y, 0));
        }
        
    }

    // These methods will be called by the Light's trigger collider
    public void AddEnemy(EnemyAI enemy)
    {
        if (!visibleEnemies.Contains(enemy))
            visibleEnemies.Add(enemy);
    }

    public void RemoveEnemy(EnemyAI enemy)
    {
        if (visibleEnemies.Contains(enemy))
            visibleEnemies.Remove(enemy);
    }
}
