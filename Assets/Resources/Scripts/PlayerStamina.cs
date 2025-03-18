using UnityEngine;
using UnityEngine.UI;

public class PlayerStamina : MonoBehaviour
{
    [Header("Stamina Settings")]
    public float maxStamina = 20f;
    public float staminaRegenRate = 3f; // Sa shpejt rigjenerohet staminë në sekondë
    public float staminaRegenDelay = 2f; // Sa sekonda pas veprimeve rifillon rigjenerimi

    private float currentStamina;
    private bool isRegenerating = false;
    private float lastUsedTime;

    [Header("UI Elements")]
    public Slider staminaBar;
    public StaminaUI staminaUI;
    void Start()
    {
        currentStamina = maxStamina;
        if (staminaUI != null) staminaUI.SetStamina(20);

    }

    void Update()
    {
        if (Time.time - lastUsedTime >= staminaRegenDelay && currentStamina < maxStamina)
        {
            RegenerateStamina();
        }
    }
    public float GetStamina()
    {
        return currentStamina;
    }
    public bool UseStamina(float amount)
    {
        if (currentStamina >= amount)
        {
            currentStamina -= amount;
            lastUsedTime = Time.time;
            staminaUI.UpdateStamina(currentStamina);
            return true;
        }
        return false; // Nuk ka mjaftueshëm staminë për këtë veprim
    }

    private void RegenerateStamina()
    {
        currentStamina += staminaRegenRate * Time.deltaTime;
        currentStamina = Mathf.Clamp(currentStamina, 0, maxStamina);
        staminaUI.UpdateStamina(currentStamina);
    }

}
