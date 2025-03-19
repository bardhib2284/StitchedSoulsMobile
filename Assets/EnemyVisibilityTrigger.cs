using Assets.Resources.Scripts;
using System.Collections;
using UnityEngine;

public class EnemyVisibilityTrigger : MonoBehaviour
{
    private int isLitID;
    public float fadeDuration = 5f; // Controls the fade speed
    private int visibilityAlphaID;
    private PlayerController Parent;
    void Start()
    {
        isLitID = Shader.PropertyToID("_IsLit");
        visibilityAlphaID = Shader.PropertyToID("_VisibilityAlpha");
        Parent = GetComponentInParent<PlayerController>();
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Enemy")) // Ensure enemies have the "Enemy" tag
        {
            
            var enemyAI = other.GetComponent<EnemyAI>();
            
            if (enemyAI != null)
            {
                enemyAI.Target = Parent.transform;
                enemyAI.PlayerController = this.Parent;
                Renderer enemyRenderer = other.GetComponent<Renderer>();
                if (enemyRenderer == null)
                {
                    enemyRenderer = other.transform.GetComponentInChildren<Renderer>();
                }
                if (enemyRenderer != null)
                {
                    other.transform.GetChild(2).gameObject.SetActive(true);
                    enemyRenderer.material.SetFloat(visibilityAlphaID, 1);
                    StartCoroutine(FadeOutline(enemyRenderer, 1)); // Fade in
                    if (Parent.GetComponent<PlayerController>().CurrentEquipedWeapon is GunWeapon)
                    {
                        var enemy = other.transform.GetComponent<EnemyAI>();
                        (Parent.GetComponent<PlayerController>().CurrentEquipedWeapon as GunWeapon).AddEnemy(enemy);

                    }
                }
            }
            
        }
    }

    IEnumerator FadeOutline(Renderer enemyRenderer, float targetValue)
    {
        if (enemyRenderer != null)
        {
            float startValue = enemyRenderer.material.GetFloat(isLitID);
            float timeElapsed = 0;
            if(startValue < targetValue)
            {
                while (timeElapsed < fadeDuration)
                {
                    if (enemyRenderer != null)
                    {
                        timeElapsed += Time.deltaTime;
                        float newValue = Mathf.Lerp(startValue, targetValue, timeElapsed / fadeDuration);
                        enemyRenderer.material.SetFloat(isLitID, newValue);
                        yield return null;

                    }
                }
                enemyRenderer.material.SetFloat(isLitID, targetValue);
            }
        }
    }

    private void OnTriggerExit(Collider other)
    {
        Debug.Log("OnTriggerExit" + other.gameObject.name);
        if (other.CompareTag("Enemy")) // Ensure enemies have the "Enemy" tag
        {
            Renderer enemyRenderer = other.transform.GetChild(1).GetComponent<Renderer>();
            if (enemyRenderer != null)
            {
                if(other != null)
                    other.transform.GetChild(2).gameObject.SetActive(false);
                if (Parent.GetComponent<PlayerController>().CurrentEquipedWeapon is GunWeapon)
                {
                    var enemy = other.transform.GetComponent<EnemyAI>();
                    (Parent.GetComponent<PlayerController>().CurrentEquipedWeapon as GunWeapon).RemoveEnemy(enemy);
                }
            }
        }
    }
}
