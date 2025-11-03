using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Audio;
using UnityEngine.Rendering;
using static Unity.VisualScripting.Member;
using Random = UnityEngine.Random;

[DisallowMultipleComponent]
[RequireComponent(typeof(AudioSource))]
[RequireComponent(typeof(Animator))]
public class EnemyAI : MonoBehaviour
{
    public enum EnemyState { Idle, Chasing, Attacking, Stunned, Dead }
    public EnemyState currentState = EnemyState.Idle;
    public bool CanBeInterrupted = true;
    [Header("Components")]
    protected Rigidbody rb;
    public Transform Target;
    public Animator Animator;
    public PlayerController PlayerController;

    [Header("Movement Settings")]
    public float moveSpeed = 3f;
    public float stoppingDistance = 1.5f;
    public float rotationSpeed = 5f;

    [Header("Enemy Attributes")]
    public HealthUI HealthUI;
    public float maxHealth = 100;
    public float health = 100f;

    public float fieldOfView = 70f;
    public float attackRange = 0.4f;

    public bool isDead = false;
    public bool JumpScare = false;
    [Header("CANVAS BLOCKER")]
    public GameObject CanvasBlocker;

    [Header("Resources path base (under a Resources/ folder)")]
    [SerializeField] private string basePath = "Audio/Boss"; // e.g. Roar1 => Resources/Audio/Boss/Roar1

    [Header("Preload (names without extension)")]
    [SerializeField] private string[] preloadClipNames;

    [Header("Playback")]
    [Range(0f, 1f)][SerializeField] private float volume = 1f;
    [SerializeField] private Vector2 pitchJitter = new Vector2(0.97f, 1.03f);
    [SerializeField] private bool spatial3D = true;
    [SerializeField] private AudioMixerGroup mixerGroup; // optional routing

    private AudioSource source;
    private readonly Dictionary<string, AudioClip> cache = new Dictionary<string, AudioClip>();


    public void Awake()
    {
        rb = GetComponent<Rigidbody>();
        Animator = GetComponent<Animator>();
        if(HealthUI != null)
            HealthUI.SetHealth(health);
        CanvasBlocker = GameObject.FindGameObjectWithTag("CanvasBlocker");

        source = GetComponent<AudioSource>();
        ConfigureSource();

        // Preload small SFX to avoid hiccups on first play
        if (preloadClipNames != null)
        {
            foreach (var n in preloadClipNames)
            {
                var clip = LoadClip(n);
                if (clip) cache[n] = clip;
            }
        }
    }

    private void Start()
    {
        if(JumpScare)
        {
            Animator.SetTrigger("JumpScare");
        }
    }

    public bool IsPlayerInFOV()
    {
        if (Target == null) return false;

        Vector3 directionToPlayer = (Target.position - transform.position).normalized;
        float dotProduct = Vector3.Dot(transform.forward, directionToPlayer);
        float angleToPlayer = Mathf.Acos(dotProduct) * Mathf.Rad2Deg;

        return angleToPlayer < fieldOfView;
    }

    public virtual void ChasePlayer()
    {
        if (currentState != EnemyState.Chasing || isDead || Target == null) return;

        float distanceToPlayer = Vector3.Distance(transform.position, Target.position);
        if (distanceToPlayer > stoppingDistance)
        {
            Vector3 direction = (Target.position - transform.position).normalized;
            rb.linearVelocity = new Vector3(direction.x * moveSpeed, rb.linearVelocity.y, direction.z * moveSpeed);

            // Smooth rotation towards player
            Quaternion targetRotation = Quaternion.LookRotation(new Vector3(direction.x, 0, direction.z));
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * rotationSpeed);
        }
        else
        {
            rb.linearVelocity = Vector3.zero;
        }
    }

    public void TakeDamage(float damage)
    {
        health -= damage;
        HealthUI.UpdateHealth(health);
        if (health <= 0)
        {
            isDead = true;
            currentState = EnemyState.Dead;
            Animator.SetTrigger("Die");
            Destroy(gameObject, 3f);
        }
    }

    public void SetStunned(bool stunned)
    {
        currentState = stunned ? EnemyState.Stunned : EnemyState.Idle;
    }

    public bool IsDead()
    {
        return isDead;
    }

    public void GetHit()
    {
        StopAllCoroutines();
        StartCoroutine(GetHitEnumerator());
    }

    IEnumerator GetHitEnumerator()
    {
        currentState = EnemyState.Stunned;
        Animator.SetTrigger("Hit");
        yield return new WaitForSeconds(1);
        currentState = EnemyState.Idle;
    }

    public void DestroyThis()
    {
        Destroy(this.gameObject);
    }


    //AUDIO 
    private void ConfigureSource()
    {
        source.playOnAwake = false;
        source.loop = false;
        source.spatialBlend = spatial3D ? 1f : 0f;    // 3D or 2D
        source.rolloffMode = AudioRolloffMode.Linear; // tweak to taste
        source.minDistance = 2f;
        source.maxDistance = 35f;
        if (mixerGroup) source.outputAudioMixerGroup = mixerGroup;
    }

    private AudioClip LoadClip(string clipName)
    {
        if (string.IsNullOrWhiteSpace(clipName)) return null;
        if (cache.TryGetValue(clipName, out var cached)) return cached;

        string path = string.IsNullOrEmpty(basePath) ? clipName : $"{basePath}/{clipName}";
        var clip = Resources.Load<AudioClip>(path);
        if (!clip)
        {
            Debug.LogWarning($"[BossSFX] AudioClip not found at Resources/{path}");
            return null;
        }
        cache[clipName] = clip;
        return clip;
    }

    // === Animation Event target ===
    // Add an Animation Event and set Function: PlaySound
    // String parameter: the clip name (e.g. "Roar1" if basePath = "Audio/Boss")
    public void PlaySound(string clipName)
    {
        var clip = LoadClip(clipName);
        if (!clip) return;

        float oldPitch = source.pitch;
        source.pitch = Random.Range(pitchJitter.x, pitchJitter.y);
        source.PlayOneShot(clip, volume);
        source.pitch = oldPitch;
    }

    // Optional: pass "Roar1,Roar2,Roar3" in the Animation Event to randomize
    public void PlayRandomFromList(string csvNames)
    {
        if (string.IsNullOrWhiteSpace(csvNames)) return;
        var parts = csvNames.Split(',');
        string pick = parts[Random.Range(0, parts.Length)].Trim();
        PlaySound(pick);
    }
}
