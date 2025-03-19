
using Assets.Resources.Scripts;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    Rigidbody rb;
    public FloatingJoystick jStick;
    [SerializeField] float moveSpeed;

    public float baseAttackSpeed = 1.0f; // Attacks per second
    private float currentAttackSpeed;
    private float attackCooldown;
    private bool canAttack = true;
    public GameObject ProjectileGameObject;
    public Transform Target;
    public float jumpForce = 7f; // Adjust for higher or lower jumps
    public LayerMask groundLayer; // Set this to detect ground objects
    public Transform groundCheck; // Empty GameObject placed at player's feet
    public bool isGrounded;
    public Animator AnimatorController;
    public bool WantsToJump;
    public bool WantsToRoll;

    public bool Attacking;
    public Weapon CurrentEquipedWeapon;

    public AudioClip WalkingAudioClip;


    public Weapon HammerWeapon;
    public Weapon GunWeapon;

    public GameObject HammerWeaponObject;
    public GameObject GunWeaponObject;

    public float IdleSpeedHanlder = 0.05f;
    public float MoveSpeedHandler = 0.85f;
    public float RunSpeedHandler = 0.9f;

    [Header("Roll Settings")]
    public float rollSpeed = 8f;  // Speed of the roll
    public float rollDuration = 0.5f;  // How long the roll lasts
    public float rollCooldown = 1.5f;  // Cooldown between rolls

    private bool isRolling = false;
    private bool canRoll = true;
    private Vector3 rollDirection;

    public PlayerStamina PlayerStamina;
    public bool GetCanAttack()
    {
        return canAttack;
    }

    void Start()
    {
        rb = this.GetComponent<Rigidbody>();
        currentAttackSpeed = baseAttackSpeed;
        attackCooldown = 1f / currentAttackSpeed;
        AnimatorController = GetComponent<Animator>();
        CurrentEquipedWeapon = GetComponentInChildren<Weapon>();
        PlayerStamina = GetComponent<PlayerStamina>();
    }
    public void AssignJoystick(FloatingJoystick fj)
    {
        jStick = fj;
        jStick.Parent = this;
    }
    public void Projectile()
    {
        if (ProjectileGameObject != null)
        {
            transform.GetChild(2).transform.localPosition = new Vector3(-2.980187e-08f, 2.75f, 2.75f);
            var gb = Instantiate(ProjectileGameObject, transform.GetChild(2));
            gb.transform.localScale = new Vector3(0.5f, 0.5f, 0.5f);
        }

    }

    public void PickUpHammer()
    {
        HammerWeaponObject.SetActive(true);
        CurrentEquipedWeapon = HammerWeapon;
        var atc = Object.FindAnyObjectByType<AtticLevelCinematic>();
        atc.AttackButton.gameObject.SetActive(true);
        atc.AttackButton.onClick.AddListener(AttackCoroutine);

    }
    IEnumerator IdleEnumerator()
    {
        yield return new WaitForEndOfFrame();
        yield return new WaitForEndOfFrame();
        if (this.enabled && !Attacking)
        {
            var animatorinfo = AnimatorController.GetCurrentAnimatorClipInfo(0);
            var current_animation = animatorinfo[0].clip.name;
            if (!current_animation.Contains("Idle"))
            {
                var IdleAnimation = Random.Range(0, 101);
                if (IdleAnimation >= 50)
                {
                    AnimatorController.SetTrigger("Idle");
                }
                else
                    AnimatorController.SetTrigger("HappyIdle");
            }
        }
    }

    public void Idle()
    {
        StartCoroutine(IdleEnumerator());
    }

    IEnumerator MoveEnumerator()
    {
        yield return new WaitForEndOfFrame();
        yield return new WaitForEndOfFrame();
        if (this.enabled && !Attacking)
        {
            var animatorinfo = AnimatorController.GetCurrentAnimatorClipInfo(0);
            var current_animation = animatorinfo[0].clip.name;
            if (current_animation.Contains("Walk"))
                yield break;
            var walkAnimation = Random.Range(0, 101);
            if (walkAnimation >= 50)
            {
                AnimatorController.SetTrigger("SneakyWalk");
            }
            else
                AnimatorController.SetTrigger("Walk");
        }
    }
    public void Move()
    {
        StartCoroutine(MoveEnumerator());
    }
    void Jump()
    {
        if (this.enabled && !Attacking)
        {
            if (PlayerStamina.UseStamina(3f))
            {
                rb.linearVelocity = new Vector3(rb.linearVelocity.x, 0, rb.linearVelocity.z); // Reset Y velocity before jumping
                rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
            }
            else
                WantsToJump = false;
        }
    }
    public void WantToRoll()
    {
        if(canRoll)
            WantsToRoll = true;
    }
    public void WantToJump()
    {
        if(isGrounded)
            WantsToJump = true;
    }

    private float nextCheckTime = 0f;
    public float checkInterval = 1f; // Koha ndërmjet check-eve (1 sekondë)

    private void FixedUpdate()
    {
        if (isRolling)
            return;
        if (Attacking)
        {
            return;
        }
        if (WantsToRoll && canRoll && isGrounded) // Change for mobile input if needed
        {
            StartCoroutine(Roll());
        }
        else
            WantsToRoll = false;
        
        // Check if the player is touching the ground
        isGrounded = Physics.CheckSphere(groundCheck.position, 0.02f, groundLayer);
        if(Input.GetKeyDown(KeyCode.R))
        {
            WantsToRoll = true;
        }
        if (Input.GetKeyDown(KeyCode.A))
        {
            AttackCoroutine();
        }
        if (Input.GetKeyDown(KeyCode.Space))
            WantsToJump = true;
        // Jump when pressing space (or mobile button)
        if (isGrounded && WantsToJump)
        {
            Jump();
            WantsToJump = false;
        }
        else
        {
            WantsToJump = false;
        }
        // Get camera forward and right directions
        Vector3 camForward = Camera.main.transform.forward;
        Vector3 camRight = Camera.main.transform.right;

        // Prevent unwanted Y-axis movement (flatten direction)
        camForward.y = 0;
        camRight.y = 0;

        // Normalize so diagonal movement isn't faster
        camForward.Normalize();
        camRight.Normalize();

        // Calculate the joystick input magnitude
        float joystickMagnitude = new Vector2(jStick.Horizontal, jStick.Vertical).magnitude;

        // Determine movement speed based on joystick magnitude
        float currentMoveSpeed = 0;

        if (joystickMagnitude < IdleSpeedHanlder && !Attacking)
        {
            if (Time.time >= nextCheckTime)
            {
                nextCheckTime = Time.time + checkInterval; // Riset për kontrollin tjetër
                Idle();
            }
        }
        else if (joystickMagnitude <= MoveSpeedHandler && !Attacking)
        {
            Move();
            currentMoveSpeed = moveSpeed * 0.5f; // 30% speed for 20-45%
        }
        else if (joystickMagnitude > RunSpeedHandler && !Attacking)
        {
            // ✅ Kontrollo nëse ka mjaftueshëm stamina para se të fillojë vrapimin
            if (PlayerStamina.GetStamina() > 0.5f)
            {
                if (PlayerStamina.UseStamina(Time.deltaTime * 2f)) // ✅ Hargjon 2 stamina për sekondë
                {
                    currentMoveSpeed = moveSpeed; // Full speed above 45%

                    var animatorInfo = AnimatorController.GetCurrentAnimatorClipInfo(0);
                    var current_animation = animatorInfo[0].clip.name;
                    if (current_animation != "Run")
                    {
                        AnimatorController.SetTrigger("Run");
                    }
                }
            }
            else
            {
                Move();
                currentMoveSpeed = moveSpeed * 0.5f; // ✅ Kur s’ka stamina, kalo në ecje
            }
        }


        // If there's any movement input, apply it
        if (joystickMagnitude >= 0.2f)
        {
            // Convert joystick input to world space
            Vector3 moveDirection = (camForward * jStick.Vertical + camRight * jStick.Horizontal).normalized;

            // Apply movement with adjusted speed
            rb.linearVelocity = moveDirection * currentMoveSpeed + Vector3.up * rb.linearVelocity.y;
        }

        // Check if the joystick is being used for rotation
        if (jStick.Horizontal != 0 || jStick.Vertical != 0)
        {
            // Calculate the direction the player should face
            Vector3 direction = new Vector3(rb.linearVelocity.x, 0, rb.linearVelocity.z);

            // Ensure direction is not zero to avoid LookRotation errors
            if (direction.magnitude > 0.1f)
            {
                Quaternion targetRotation = Quaternion.LookRotation(direction);

                // Smoothly rotate over time (adjust 5f for faster/slower rotation)
                transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * 10f);
            }
        }

    }


    public void AttackCoroutine()
    {
        StartCoroutine(Attack());

        
    }

    IEnumerator Attack()
    {
        yield return new WaitForEndOfFrame();
        var animatorinfo = AnimatorController.GetCurrentAnimatorClipInfo(0);
        var current_animation = animatorinfo[0].clip.name;
        if (current_animation.Contains("Attack")) yield break;
        yield return new WaitForEndOfFrame();

        if (CurrentEquipedWeapon != null && canAttack && !Attacking)
        {

            if (CurrentEquipedWeapon != null)
            {
                canAttack = false;
                Attacking = true;
                Debug.Log("Attack performed!");
                CurrentEquipedWeapon = GetComponentInChildren<Weapon>();
                CurrentEquipedWeapon.Attack();
                yield return new WaitForSecondsRealtime(attackCooldown);
                Attacking = false;
                canAttack = true;
            }
            
        }
    }

    public void FinishAttack()
    {

    }
    public void ModifyAttackSpeed(float multiplier)
    {
        currentAttackSpeed = baseAttackSpeed * multiplier;
        attackCooldown = 1f / currentAttackSpeed;
    }

    public void WalkSound()
    {
        var sound = GetComponent<AudioSource>();
        //sound.clip = WalkingAudioClip;
        //sound.Play();
    }

    private IEnumerator Roll()
    {
        if (PlayerStamina.UseStamina(3f))
        {
            AnimatorController.SetTrigger("Roll");
            WantsToRoll = false;
            canRoll = false;
            isRolling = true;
            yield return new WaitForSeconds(0.05f);
            // Store current movement direction (if stationary, roll forward)
            rollDirection = new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical"));
            if (rollDirection.magnitude == 0) rollDirection = transform.forward; // Default to forward roll

            // TODO Apply invulnerability
            //if (playerHealth != null) playerHealth.SetInvulnerable(true);

            float elapsedTime = 0;
            while (elapsedTime < rollDuration)
            {
                rb.linearVelocity = rollDirection.normalized * rollSpeed;
                elapsedTime += Time.deltaTime;
                yield return null;
            }

            // Reset velocity and disable invulnerability
            rb.linearVelocity = Vector3.zero;
            yield return new WaitForSeconds(0.075f);
            isRolling = false;
            //TODO
            //if (playerHealth != null) playerHealth.SetInvulnerable(false);

            // Start cooldown
            yield return new WaitForSeconds(rollCooldown - 0.5f);
            canRoll = true;
        }
        else
            WantsToRoll = false;
    }

    public bool IsRolling()
    {
        return isRolling;
    }
}