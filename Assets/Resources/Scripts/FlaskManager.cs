using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Manages flask usage and display on the UI
/// Souls-like potion system
/// </summary>
public class FlaskManager : MonoBehaviour
{
    [Header("References")]
    public PlayerHealth playerHealth;
    public HealthUI healthUI;
    public Button flaskButton;
    public KeyCode flaskKey = KeyCode.E;

    [Header("Flask Settings")]
    public float flaskCooldown = 2f;
    private float lastFlaskUseTime = -2f;

    private void Start()
    {
        if (flaskButton != null)
        {
            flaskButton.onClick.AddListener(UseFlask);
        }

        if (playerHealth == null)
        {
            playerHealth = GetComponent<PlayerHealth>();
        }
    }

    private void Update()
    {
        // ✅ Allow flask use with E key on keyboard
        if (Input.GetKeyDown(flaskKey))
        {
            UseFlask();
        }
    }

    /// <summary>
    /// Use a flask to heal the player
    /// </summary>
    public void UseFlask()
    {
        // Check cooldown
        if (Time.time - lastFlaskUseTime < flaskCooldown)
        {
            Debug.Log("Flask is on cooldown!");
            return;
        }

        // Check if already at full health
        if (playerHealth.GetHealth() >= playerHealth.maxHealth)
        {
            Debug.Log("Already at full health!");
            return;
        }

        // Use flask and update UI
        if (playerHealth.UseFlask())
        {
            lastFlaskUseTime = Time.time;

            // Update flask count in UI
            if (healthUI != null)
            {
                healthUI.UpdateFlaskCount(playerHealth.GetFlasks(), playerHealth.maxFlasks);
            }

            Debug.Log("Flask used!");
        }
    }

    /// <summary>
    /// Refill flasks when at a safe zone/checkpoint
    /// </summary>
    public void RefillFlasks()
    {
        playerHealth.RefillFlasks();

        if (healthUI != null)
        {
            healthUI.UpdateFlaskCount(playerHealth.GetFlasks(), playerHealth.maxFlasks);
        }

        Debug.Log("Flasks refilled!");
    }
}
