using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class HealthUI : MonoBehaviour
{
    public Slider HealthSlider;      // Slider kryesor i Staminës (zbret menjëherë)
    public Slider backgroundSlider;   // Slider që zbret më ngadalë (për efekt vizual)
    public float smoothSpeed = 0.1f;  // Shpejtësia e animimit të background-it
    public float threshold = 0.3f;    // Diferenca për të nisur efektin vizual

    private Coroutine backgroundAnimCoroutine;
    private bool AnimationOn;

    public Image fillImageSlider; // Shto këtë për të marrë referencën e imazhit të mbushjes

    public Image fillImageBackground; // Shto këtë për të marrë referencën e imazhit të mbushjes

    public void SetHealth(float amount)
    {
        HealthSlider.maxValue = amount;
        backgroundSlider.maxValue = amount;
        backgroundSlider.value = amount;
        HealthSlider.value = amount;
        StartCoroutine(SmoothBackgroundUpdate());
    }
    public void UpdateHealth(float newHealth)
    {
        float oldHealth = HealthSlider.value;
        HealthSlider.value = newHealth; // 📉 Health kryesore bie menjëherë
        if (backgroundSlider.value < HealthSlider.value)
        {
            backgroundSlider.value = HealthSlider.value;
        }
        // ✅ Nëse rënia është më e madhe se threshold, fillo animimin
        if (oldHealth - newHealth >= threshold)
        {
            if (backgroundAnimCoroutine != null) StopCoroutine(backgroundAnimCoroutine);
            backgroundAnimCoroutine = StartCoroutine(SmoothBackgroundUpdate());
        }
        else
        {
            if (!AnimationOn)
                backgroundSlider.value = HealthSlider.value;
        }

    }

    private IEnumerator SmoothBackgroundUpdate()
    {
        if(this.gameObject.activeInHierarchy)
        {
            if (backgroundSlider != null && HealthSlider != null)
            {
                AnimationOn = true;
                // 📉 Zbut ngadalë backgroundSlider derisa të arrijë vlerën e HealthSlider
                while (backgroundSlider.value > HealthSlider.value)
                {
                    backgroundSlider.value = Mathf.Lerp(backgroundSlider.value, HealthSlider.value, Time.deltaTime * smoothSpeed);
                    yield return new WaitForEndOfFrame(); // Sigurohet që të vazhdojë çdo frame
                    if (backgroundSlider.value <= 3)
                    {
                        backgroundSlider.enabled = false;
                    }
                    fillImageSlider.enabled = HealthSlider.value > 0;
                    fillImageBackground.enabled = backgroundSlider.value > 2;
                }
                AnimationOn = false;
            }
        }
        

    }

    private IEnumerator SmoothBackgroundUpdateMin()
    {
        // 📉 Zbut ngadalë backgroundSlider derisa të arrijë vlerën e HealthSlider
        while (backgroundSlider.value < HealthSlider.value)
        {
            backgroundSlider.value = Mathf.Lerp(backgroundSlider.value, HealthSlider.value, Time.deltaTime * smoothSpeed);
            yield return null;
        }
    }
}
