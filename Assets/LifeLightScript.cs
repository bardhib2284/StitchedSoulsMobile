using Assets.Resources.Scripts;
using UnityEngine;

public class LifeLightScript : MonoBehaviour
{

    public void DestroyAndGiveLife()
    {
        Destroy(this.gameObject);
        var cinematic = Object.FindFirstObjectByType<LevelCinematicManager>();
        if(cinematic != null && cinematic is AtticLevelCinematic alc)
        {
            alc.GiveLifeToPlayer();
        }
    }
}
