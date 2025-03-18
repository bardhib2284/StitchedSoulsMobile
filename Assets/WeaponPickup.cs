using UnityEngine;

public class WeaponPickup : MonoBehaviour
{
    [Header("Weapon Settings")]
    public GameObject weaponPrefab; // Arma që lojtari do të marrë
    public float rotationSpeed = 50f; // Shpejtësia e rrotullimit
    public float hoverHeight = 0.2f; // Sa lart do të lëkundet arma
    public float hoverSpeed = 2f; // Shpejtësia e lëkundjes

    [Header("Pickup Settings")]
    public float pickupRange = 2f; // Sa afër duhet të jetë lojtari
    public KeyCode pickupKey = KeyCode.E; // Butoni për të marrë armën

    private Vector3 startPos;
    private bool isPlayerNearby;

    void Start()
    {
        startPos = transform.position;
    }

    void Update()
    {
        // 🔄 Rrotullimi i armës
        transform.Rotate(Vector3.up * rotationSpeed * Time.deltaTime);

        // 🔼 Lëvizja e lëkundjes lart e poshtë
        float newY = startPos.y + Mathf.Sin(Time.time * hoverSpeed) * hoverHeight;
        transform.position = new Vector3(transform.position.x, newY, transform.position.z);
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            isPlayerNearby = true;
            other.gameObject.GetComponent<PlayerController>().PickUpHammer();
            Destroy(gameObject);
        }
    }
}
