using System.Collections;
using System.Collections.Generic;
using System.Threading;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    [Header("Frame Rate Settings")]
    int MaxRate = 300;

    public float TargetFrameRate = 300;

    public float currentFrameTime;

    public LevelCinematicManager CurrentLevelCinematic;
    // Start is called before the first frame update
    void Awake()
    {
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = MaxRate;
        if(CurrentLevelCinematic == null)
        {
            Application.Quit(0);
            Debug.LogError("Missing level cinematic");
        }
    }

    private int FramesPerSec;
    private float frequency = 1.0f;
    private string fps;



    void Start()
    {
        StartCoroutine(FPS());
    }

    private IEnumerator FPS()
    {
        for (; ; )
        {
            // Capture frame-per-second
            int lastFrameCount = Time.frameCount;
            float lastTime = Time.realtimeSinceStartup;
            yield return new WaitForSeconds(frequency);
            float timeSpan = Time.realtimeSinceStartup - lastTime;
            int frameCount = Time.frameCount - lastFrameCount;

            // Display it

            fps = string.Format("FPS: {0}", Mathf.RoundToInt(frameCount / timeSpan));
        }
    }


    void OnGUI()
    {
        GUI.Label(new Rect(Screen.width - 100, 10, 500, 200), fps);
    }

}
