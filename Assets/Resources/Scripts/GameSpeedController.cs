using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// Controls game speed with a button for testing/debugging
/// Cycles through: 1x → 2x → 4x → 8x → 1x
/// </summary>
public class GameSpeedController : MonoBehaviour
{
    [Header("UI")]
    public Button speedButton;
    public TextMeshProUGUI speedDisplayText;

    [Header("Speed Settings")]
    private float[] speedMultipliers = { 1f, 2f, 4f, 8f };
    private int currentSpeedIndex = 0;

    private void Start()
    {
        if (speedButton != null)
        {
            speedButton.onClick.AddListener(CycleGameSpeed);
        }

        // Set initial speed display
        UpdateSpeedDisplay();
    }

    /// <summary>
    /// Cycle through speed multipliers
    /// </summary>
    public void CycleGameSpeed()
    {
        // Move to next speed (1x → 2x → 4x → 8x → 1x)
        currentSpeedIndex = (currentSpeedIndex + 1) % speedMultipliers.Length;

        // Apply new speed
        Time.timeScale = speedMultipliers[currentSpeedIndex];

        Debug.Log($"Game speed changed to: {speedMultipliers[currentSpeedIndex]}x");
        UpdateSpeedDisplay();
    }

    /// <summary>
    /// Update the speed display text on UI
    /// </summary>
    private void UpdateSpeedDisplay()
    {
        if (speedDisplayText != null)
        {
            speedDisplayText.text = $"{speedMultipliers[currentSpeedIndex]}x";
        }
    }

    /// <summary>
    /// Get current game speed
    /// </summary>
    public float GetCurrentSpeed()
    {
        return speedMultipliers[currentSpeedIndex];
    }

    /// <summary>
    /// Set game speed to normal (for important scenes or gameplay)
    /// </summary>
    public void SetSpeedToNormal()
    {
        currentSpeedIndex = 0;
        Time.timeScale = speedMultipliers[currentSpeedIndex];
        UpdateSpeedDisplay();
    }
}
