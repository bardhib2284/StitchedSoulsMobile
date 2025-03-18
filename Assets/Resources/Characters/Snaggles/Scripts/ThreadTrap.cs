using System.Collections;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UI;

public class ThreadTrap : MonoBehaviour
{
    private Transform target;
    private float speed;
    private float pullStrength;
    private float effectDuration;
    
    private bool pullingPlayer = false;
    private PlayerController player;
    public Transform Parent;
    Coroutine pullCoroutine;
    float timer = 0f;

    public Button ScissorsUIPrefab;

    public Button ScissorsUIClone;
    public void Initialize(Transform target, float speed, float pullStrength, float effectDuration,Transform parent)
    {
        this.target = target;
        this.speed = speed;
        this.pullStrength = pullStrength;
        this.effectDuration = effectDuration;
        this.Parent = parent;
        timer = 0f;
    }
    
    public void ReducePullTime()
    {
        timer += 1.5f;
    }


    void Update()
    {
        if (!pullingPlayer && target != null)
        {
            transform.position = Vector3.MoveTowards(transform.position, target.position, speed * Time.deltaTime);
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player") && !pullingPlayer)
        {
            pullingPlayer = true;
            player = other.GetComponent<PlayerController>();
            if (player != null)
            {
                StartPulling();
            }
        }
    }

    private void StartPulling()
    {
        if (pullCoroutine == null)
        {
            var canvas = FindAnyObjectByType(typeof(Canvas));
            ScissorsUIClone = Instantiate(ScissorsUIPrefab,GameObject.FindGameObjectWithTag("Canvas").transform);
            ScissorsUIClone.onClick.AddListener(ReducePullTime);
            pullCoroutine = StartCoroutine(PullPlayer());
        }
    }

    private IEnumerator PullPlayer()
    {

        while (true) // Infinite loop, must be exited manually
        {
            if (player == null)
            {
                Debug.Log("Player is null, stopping pull.");
                break;
            }
            player.enabled = false;
            var playerRb = player.GetComponent<Rigidbody>();
            float distance = Vector3.Distance(player.transform.position, transform.position);
            playerRb.isKinematic = true;
            playerRb.useGravity = false;
            playerRb.constraints = RigidbodyConstraints.FreezeRotation | RigidbodyConstraints.FreezePositionY;
            // Keep pulling the player towards the trap
            Vector3 targetPosition = Vector3.MoveTowards(player.transform.position, Parent.position - Vector3.one, pullStrength * Time.deltaTime);
            playerRb.MovePosition(targetPosition);

            timer += Time.deltaTime;
            if (timer >= effectDuration)
            {
                player.enabled = true;
                Destroy(this.gameObject);
                Destroy(ScissorsUIClone.gameObject);
                break;
            }

            yield return new WaitForFixedUpdate(); // Ensure physics-based smooth movement
        }
        var playerRbb = player.GetComponent<Rigidbody>();
        playerRbb.isKinematic = false;
        playerRbb.useGravity = true;
        playerRbb.constraints = RigidbodyConstraints.FreezeRotation;
        pullCoroutine = null; // Reset coroutine tracker
    }
}
