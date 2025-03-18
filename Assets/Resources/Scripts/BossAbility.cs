using UnityEngine;

public abstract class BossAbility : MonoBehaviour
{
    public string abilityName;
    public float cooldownTime;
    protected float lastUsedTime;
    public bool Canuse;
    public abstract void ActivateAbility(Transform target);

    public bool CanUse()
    {
        return Canuse && Time.time >= lastUsedTime + cooldownTime;
    }

    protected void StartCooldown()
    {
        lastUsedTime = Time.time;
    }
}
