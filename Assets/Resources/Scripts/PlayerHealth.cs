using UnityEngine;

/// <summary>
/// Souls-like player health system
/// No regeneration - only healing through flasks
/// Death at 0 health triggers respawn at room start
/// </summary>
public class PlayerHealth : MonoBehaviour
{
    [Header("Health Settings")]
    public float maxHealth = 100f;
    public int maxFlasks = 5;
    public float flaskHealAmount = 40f;

    private float currentHealth;
    private int currentFlasks;
    private bool isDead = false;

    [Header("UI Elements")]
    public HealthUI healthUI;

    [Header("Respawn Settings")]
    public Transform respawnPoint;
    private Rigidbody rb;
    private PlayerController playerController;

    private void Awake()
    {
        rb = GetComponent<Rigidbody>();
        playerController = GetComponent<PlayerController>();
    }

    private void Start()
    {
        currentHealth = maxHealth;
        currentFlasks = maxFlasks;
        isDead = false;

        if (healthUI != null)
        {
            healthUI.SetHealth(maxHealth); // ✅ Initialize with max health value for slider max
        }
    }

    /// <summary>
    /// Get current health
    /// </summary>
    public float GetHealth()
    {
        return currentHealth;
    }

    /// <summary>
    /// Get current flask count
    /// </summary>
    public int GetFlasks()
    {
        return currentFlasks;
    }

    /// <summary>
    /// Apply damage to player (called by enemies)
    /// </summary>
    public void TakeDamage(float damage)
    {
        if (isDead) return;

        currentHealth -= damage;
        currentHealth = Mathf.Clamp(currentHealth, 0, maxHealth);

        if (healthUI != null)
        {
            healthUI.UpdateHealth(currentHealth);
        }

        Debug.Log($"Player took {damage} damage. Health: {currentHealth}/{maxHealth}");

        if (currentHealth <= 0)
        {
            Die();
        }
    }

    /// <summary>
    /// Use a flask to heal (souls-like potion)
    /// </summary>
    public bool UseFlask()
    {
        if (currentFlasks <= 0)
        {
            Debug.Log("No flasks remaining!");
            return false;
        }

        currentFlasks--;
        Heal(flaskHealAmount);

        Debug.Log($"Used flask. Remaining: {currentFlasks}. Health: {currentHealth}/{maxHealth}");

        return true;
    }

    /// <summary>
    /// Heal the player (from flask or other source)
    /// </summary>
    public void Heal(float amount)
    {
        currentHealth += amount;
        currentHealth = Mathf.Clamp(currentHealth, 0, maxHealth);

        if (healthUI != null)
        {
            healthUI.UpdateHealth(currentHealth);
        }
    }

    /// <summary>
    /// Refill all flasks (at safe zones/checkpoints)
    /// </summary>
    public void RefillFlasks()
    {
        currentFlasks = maxFlasks;
        Debug.Log($"Flasks refilled. Flasks: {currentFlasks}/{maxFlasks}");
    }

    /// <summary>
    /// Player death - respawn at beginning of room
    /// </summary>
    private void Die()
    {
        isDead = true;
        Debug.Log("PLAYER DIED! Respawning...");

        // Stop all player actions
        if (playerController != null)
        {
            playerController.enabled = false;
        }

        // Trigger death animation
        Animator animator = GetComponent<Animator>();
        if (animator != null)
        {
            animator.SetTrigger("Die");
        }

        // Wait for death animation then respawn
        Invoke(nameof(Respawn), 2f);
    }

    /// <summary>
    /// Respawn player at the beginning of the room
    /// </summary>
    private void Respawn()
    {
        // Reset health and flasks
        currentHealth = maxHealth;
        currentFlasks = maxFlasks;
        isDead = false;

        // Move player to respawn point
        if (respawnPoint != null)
        {
            transform.position = respawnPoint.position;
            transform.rotation = respawnPoint.rotation;
            Debug.Log($"Respawned at {respawnPoint.name}");
        }
        else
        {
            Debug.LogWarning("No respawn point assigned!");
        }

        // Reset rigidbody
        if (rb != null)
        {
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }

        // Re-enable player controller
        if (playerController != null)
        {
            playerController.enabled = true;
        }

        // Update UI
        if (healthUI != null)
        {
            healthUI.SetHealth(maxHealth); // ✅ Re-initialize UI with max health
        }
    }

    /// <summary>
    /// Check if player is dead
    /// </summary>
    public bool IsDead()
    {
        return isDead;
    }
}
