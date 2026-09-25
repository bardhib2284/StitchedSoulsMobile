using Assets.Resources.Scripts;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Audio;

[DisallowMultipleComponent]
[RequireComponent(typeof(AudioSource))]
[RequireComponent(typeof(Rigidbody))]
public class PlayerController : MonoBehaviour
{
    private Rigidbody rb;
    public FloatingJoystick jStick;
    [SerializeField] private float moveSpeed;

    [Header("Attack Settings")]
    public float baseAttackSpeed = 1.0f;
    private float currentAttackSpeed;
    private float attackCooldown;
    private bool canAttack = true;
    public GameObject ProjectileGameObject;
    public Transform Target;

    // ✅ Cached animator parameter hashes (computed once in Awake)
    private int attackHashId;
    private int runHashId;
    private int rollHashId;
    private int happyIdleHashId;
    private int sneakyWalkHashId;
    private int hammerAttackHashId;

    [Header("Weapons")]
    public Weapon CurrentEquippedWeapon;
    public Weapon HammerWeapon;
    public Weapon GunWeapon;
    public GameObject HammerWeaponObject;
    public GameObject GunWeaponObject;


    [Header("Jump Settings")]
    public float jumpForce = 7f;
    public LayerMask groundLayer;
    public Transform groundCheck;
    private bool isGrounded;
    private bool wantsToJump;

    [Header("Roll Settings")]
    public float rollSpeed = 8f;
    public float rollDuration = 0.5f;
    public float rollCooldown = 1.5f;
    private bool isRolling = false;
    private bool canRoll = true;
    private Vector3 rollDirection;

    [Header("Other Components")]
    public Animator AnimatorController;
    public PlayerStamina PlayerStamina;
    public AudioClip WalkingAudioClip;

    [Header("Movement Thresholds")]
    public float IdleSpeedHandler = 0.05f;
    public float MoveSpeedHandler = 0.85f;
    public float RunSpeedHandler = 0.9f;

    private bool isAttacking = false;
    private bool wantsToRoll;

    public bool CanIdle = true;

    // ✅ Cached camera reference (avoid Camera.main lookup every frame)
    private Camera mainCamera;

    // ✅ Cached AtticLevelCinematic reference
    private AtticLevelCinematic atticLevelCinematic;

    // ✅ Ground check optimization (reduce frequency)
    private int groundCheckCounter = 0;
    private const int GROUND_CHECK_FREQUENCY = 2; // Check every 2 frames

    // ✅ Cached animator clip info (avoid multiple calls per frame)
    private AnimatorClipInfo[] cachedAnimatorClipInfo;

    // ✅ Track attack coroutine to prevent overlapping attacks
    private Coroutine attackCoroutine;

    //AUDIO


    [Header("Resources path base (under a Resources/ folder)")]
    [SerializeField] private string basePath = "Characters/Patches/Audio"; // e.g. Roar1 => Resources/Audio/Boss/Roar1

    [Header("Preload (names without extension)")]
    [SerializeField] private string[] preloadClipNames;

    [Header("Playback")]
    [Range(0f, 1f)][SerializeField] private float volume = 1f;
    [SerializeField] private Vector2 pitchJitter = new Vector2(0.97f, 1.03f);
    [SerializeField] private bool spatial3D = true;
    [SerializeField] private AudioMixerGroup mixerGroup; // optional routing

    private AudioSource source;
    private readonly Dictionary<string, AudioClip> cache = new Dictionary<string, AudioClip>();

    private void Awake()
    {
        rb = GetComponent<Rigidbody>();
        currentAttackSpeed = baseAttackSpeed;
        attackCooldown = 1f / currentAttackSpeed;
        AnimatorController = GetComponent<Animator>();
        CurrentEquippedWeapon = GetComponentInChildren<Weapon>();
        PlayerStamina = GetComponent<PlayerStamina>();

        source = GetComponent<AudioSource>();
        ConfigureSource();

        // ✅ Cache animator parameter hashes (computed once, no string lookups after)
        attackHashId = Animator.StringToHash("Attack");
        runHashId = Animator.StringToHash("Run");
        rollHashId = Animator.StringToHash("Roll");
        happyIdleHashId = Animator.StringToHash("HappyIdle");
        sneakyWalkHashId = Animator.StringToHash("SneakyWalk");
        hammerAttackHashId = Animator.StringToHash("HammerAttack");

        // ✅ Cache main camera reference (avoid Camera.main lookup)
        mainCamera = Camera.main;

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
    void Start()
    {
        CanIdle = true;
    }

    public void AssignJoystick(FloatingJoystick fj)
    {
        jStick = fj;
        jStick.Parent = this;
    }

    private void FixedUpdate()
    {
        // ✅ Keyboard input for testing on PC
        if(Input.GetKeyDown(KeyCode.R))
        {
            WantToRoll();
        }
        if(Input.GetKeyDown(KeyCode.Space))
        {
            WantToJump();
        }
        // ✅ NEW: Attack with A key for easier PC testing
        if(Input.GetKeyDown(KeyCode.A))
        {
            if (!isRolling && !isAttacking && canAttack)
            {
                AttackCoroutine();
            }
        }

        if (isRolling || isAttacking) return; // No movement if rolling or attacking

        // ✅ OPTIMIZATION: Check ground less frequently (every 2 frames instead of every frame)
        groundCheckCounter++;
        if (groundCheckCounter >= GROUND_CHECK_FREQUENCY)
        {
            isGrounded = Physics.CheckSphere(groundCheck.position, 0.02f, groundLayer);
            groundCheckCounter = 0;
        }

        if (wantsToRoll && canRoll && isGrounded)
        {
            StartCoroutine(Roll());
        }
        else
        {
            wantsToRoll = false;
        }

        if (wantsToJump && isGrounded)
        {
            Jump();
            wantsToJump = false;
        }

        HandleMovement();
    }

    private void HandleMovement()
    {
        float joystickMagnitude = new Vector2(jStick.Horizontal, jStick.Vertical).magnitude;
        float currentMoveSpeed = 0;

        if (joystickMagnitude < IdleSpeedHandler)
        {
            Idle();
        }
        else if (joystickMagnitude <= MoveSpeedHandler)
        {
            Move();
            currentMoveSpeed = moveSpeed * 0.5f;
        }
        else if (joystickMagnitude > RunSpeedHandler)
        {
            // ✅ Player is trying to run (joystick at max)
            if (PlayerStamina.GetStamina() > 0.5f)
            {
                // ✅ Has stamina - try to use it
                if (PlayerStamina.UseStamina(Time.deltaTime * 2f)) // ✅ Uses 2 stamina per second
                {
                    currentMoveSpeed = moveSpeed; // Full speed

                    // ✅ OPTIMIZATION: Cache animator clip info instead of calling multiple times
                    cachedAnimatorClipInfo = AnimatorController.GetCurrentAnimatorClipInfo(0);
                    if (cachedAnimatorClipInfo.Length >= 1)
                    {
                        var current_animation = cachedAnimatorClipInfo[0].clip?.name;
                        if (current_animation != "Run")
                        {
                            AnimatorController.SetTrigger(runHashId); // ✅ Use hash instead of string
                        }
                    }
                }
                else
                {
                    // ✅ UseStamina() failed but we have some stamina - fall back to walking
                    Move();
                    currentMoveSpeed = moveSpeed * 0.5f;
                }
            }
            else
            {
                // ✅ No stamina - walk instead of run
                Move();
                currentMoveSpeed = moveSpeed * 0.5f;
            }
        }

        if (joystickMagnitude >= 0.2f)
        {
            Vector3 moveDirection = GetMoveDirection();
            rb.linearVelocity = moveDirection * currentMoveSpeed + Vector3.up * rb.linearVelocity.y;

            Quaternion targetRotation = Quaternion.LookRotation(moveDirection);
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * 10f);
        }
    }

    private Vector3 GetMoveDirection()
    {
        // ✅ OPTIMIZATION: Use cached mainCamera instead of Camera.main lookup
        Vector3 camForward = mainCamera.transform.forward;
        Vector3 camRight = mainCamera.transform.right;

        camForward.y = 0;
        camRight.y = 0;

        return (camForward * jStick.Vertical + camRight * jStick.Horizontal).normalized;
    }

    private void Jump()
    {
        if (!PlayerStamina.UseStamina(3f)) return;

        rb.linearVelocity = new Vector3(rb.linearVelocity.x, 0, rb.linearVelocity.z);
        rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
    }

    private IEnumerator Roll()
    {
        if (!PlayerStamina.UseStamina(3f)) yield break;

        AnimatorController.SetTrigger("Roll");
        wantsToRoll = false;
        canRoll = false;
        isRolling = true;

        yield return new WaitForSeconds(0.05f);

        rollDirection = new Vector3(jStick.Horizontal, 0, jStick.Vertical);
        rollDirection *= -1;
        if (rollDirection.magnitude == 0) rollDirection = transform.forward;

        float elapsedTime = 0;
        while (elapsedTime < rollDuration)
        {
            rb.linearVelocity = rollDirection.normalized * rollSpeed;
            elapsedTime += Time.deltaTime;
            yield return null;
        }

        rb.linearVelocity = Vector3.zero;
        isRolling = false;
        yield return new WaitForSeconds(rollCooldown);
        canRoll = true;
    }

    private void Idle()
    {
        if(CanIdle)
        {
            if(AnimatorController != null && AnimatorController.GetCurrentAnimatorClipInfo(0) != null)
            {
                // ✅ OPTIMIZATION: Use cached animator info instead of calling multiple times
                cachedAnimatorClipInfo = AnimatorController.GetCurrentAnimatorClipInfo(0);
                if(cachedAnimatorClipInfo.Length > 0)
                {
                    if (!cachedAnimatorClipInfo[0].clip.name.Contains("Idle"))
                    {
                        AnimatorController.CrossFade(happyIdleHashId, 0.04f); // ✅ Use hash instead of string
                    }
                }
            }
        }
    }

    private void Move()
    {
        // ✅ OPTIMIZATION: Use cached animator info instead of calling multiple times
        cachedAnimatorClipInfo = AnimatorController.GetCurrentAnimatorClipInfo(0);
        if(cachedAnimatorClipInfo != null && cachedAnimatorClipInfo.Length > 0 && cachedAnimatorClipInfo[0].clip != null)
        {
            if (!cachedAnimatorClipInfo[0].clip.name.Contains("Walk"))
            {
                AnimatorController.SetTrigger(sneakyWalkHashId); // ✅ Use hash instead of string
            }
        }
    }

    public void AttackCoroutine()
    {
        // ✅ Stop previous attack if still running (prevents overlapping attacks)
        if (attackCoroutine != null)
        {
            StopCoroutine(attackCoroutine);
            isAttacking = false; // Reset state if interrupted
            canAttack = true;
        }
        attackCoroutine = StartCoroutine(Attack());
    }

    IEnumerator Attack()
    {
        yield return new WaitForEndOfFrame();

        var animatorInfo = AnimatorController.GetCurrentAnimatorClipInfo(0);
        if (animatorInfo.Length > 0)
        {
            var currentAnimation = animatorInfo[0].clip.name;

            // ✅ Prevent repeated attack animations
            if (currentAnimation.Contains("Attack"))
            {
                attackCoroutine = null;
                yield break;
            }
        }

        yield return new WaitForEndOfFrame();

        // ✅ Check if a weapon is equipped and attack is available
        if (CurrentEquippedWeapon != null && canAttack && !isAttacking)
        {
            canAttack = false;
            isAttacking = true;

            Debug.Log("Attack performed with " + CurrentEquippedWeapon.name);

            // ✅ **RESTORED: Call the correct weapon attack method**
            CurrentEquippedWeapon.Attack();

            // ✅ Ensure attack cooldown is applied
            yield return new WaitForSecondsRealtime(attackCooldown);

            isAttacking = false;
            canAttack = true;
            attackCoroutine = null; // ✅ Clear reference when complete
        }
        else
        {
            // ✅ If attack couldn't start, reset state
            isAttacking = false;
            canAttack = true;
            attackCoroutine = null;
        }
    }

    public void CheckAttackState()
    {
        Debug.Log("Attackking : " + isAttacking);
    }
    public bool IsRolling()
    {
        return isRolling;
    }

    public void WantToRoll()
    {
        if (canRoll)
            wantsToRoll = true;
    }

    public void WantToJump()
    {
        if (isGrounded)
            wantsToJump = true;
    }
    public void PickUpHammer()
    {
        if (HammerWeaponObject != null)
        {
            // ✅ Disable all other weapons before activating the hammer
            GunWeaponObject.SetActive(false);

            // ✅ Activate Hammer & Set as Equipped Weapon
            HammerWeaponObject.SetActive(true);
            CurrentEquippedWeapon = HammerWeapon;

            // ✅ OPTIMIZATION: Cache AtticLevelCinematic reference instead of searching every time
            if (atticLevelCinematic == null)
            {
                atticLevelCinematic = Object.FindAnyObjectByType<AtticLevelCinematic>();
            }

            if (atticLevelCinematic != null)
            {
                atticLevelCinematic.AttackButton.gameObject.SetActive(true);
                atticLevelCinematic.AttackButton.onClick.AddListener(AttackCoroutine);
            }
        }
    }

    public void SetIsAttackingFalse()
    {
        isAttacking = false;

        // ✅ Reset attack state if stuck
        if (attackCoroutine != null)
        {
            StopCoroutine(attackCoroutine);
            attackCoroutine = null;
        }
        canAttack = true;
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

    public void StopSound()
    {
        source.Stop();
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
