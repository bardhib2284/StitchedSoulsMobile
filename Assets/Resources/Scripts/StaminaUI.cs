using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class StaminaUI : MonoBehaviour
{
    public Slider staminaSlider;      // Slider kryesor i Staminës (zbret menjëherë)
    public Slider backgroundSlider;   // Slider që zbret më ngadalë (për efekt vizual)
    public float smoothSpeed = 0.1f;  // Shpejtësia e animimit të background-it
    public float threshold = 0.3f;    // Diferenca për të nisur efektin vizual

    private Coroutine backgroundAnimCoroutine;
    private bool AnimationOn;
    public void SetStamina(float amount)
    {
        staminaSlider.maxValue = amount;
        backgroundSlider.maxValue = amount;
        backgroundSlider.value = amount;
        staminaSlider.value = amount;
        StartCoroutine(SmoothBackgroundUpdate());
    }
    public void UpdateStamina(float newStamina)
    {
        float oldStamina = staminaSlider.value;
        staminaSlider.value = newStamina; // 📉 Stamina kryesore bie menjëherë
        if(backgroundSlider.value < staminaSlider.value)
        {
            backgroundSlider.value = staminaSlider.value;
        }
        // ✅ Nëse rënia është më e madhe se threshold, fillo animimin
        if (oldStamina - newStamina >= threshold)
        {
            if (backgroundAnimCoroutine != null) StopCoroutine(backgroundAnimCoroutine);
            backgroundAnimCoroutine = StartCoroutine(SmoothBackgroundUpdate());
        }
        else
        {
            if(!AnimationOn)
                backgroundSlider.value = staminaSlider.value;
        }

    }

    private IEnumerator SmoothBackgroundUpdate()
    {
        AnimationOn = true;
        // 📉 Zbut ngadalë backgroundSlider derisa të arrijë vlerën e staminaSlider
        while (backgroundSlider.value > staminaSlider.value)
        {
            backgroundSlider.value = Mathf.Lerp(backgroundSlider.value, staminaSlider.value, Time.deltaTime * smoothSpeed);
            yield return new WaitForEndOfFrame(); // Sigurohet që të vazhdojë çdo frame
        }
        AnimationOn = false;
    }

    private IEnumerator SmoothBackgroundUpdateMin()
    {
        // 📉 Zbut ngadalë backgroundSlider derisa të arrijë vlerën e staminaSlider
        while (backgroundSlider.value < staminaSlider.value)
        {
            backgroundSlider.value = Mathf.Lerp(backgroundSlider.value, staminaSlider.value, Time.deltaTime * smoothSpeed);
            yield return null;
        }
    }
}
