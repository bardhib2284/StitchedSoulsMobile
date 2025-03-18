using System.Collections;
using UnityEngine;

public class PlayerSpotLightEffect : MonoBehaviour
{
    public float IntensityPlus;
    public Transform Player;
    public Light Light;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        Player = GameObject.FindGameObjectWithTag("Player").transform;
        Light = GetComponent<Light>();
        StartCoroutine(CheckDistanceBetweenLightAndPlayer());
    }

    IEnumerator CheckDistanceBetweenLightAndPlayer()
    {
        while (true)
        {
            Light.intensity = Vector3.Distance(transform.position, Player.transform.position) + IntensityPlus;
            yield return new WaitForSecondsRealtime(0.4f);
        }
        
    }
}
