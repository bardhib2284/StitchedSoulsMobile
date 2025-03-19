using UnityEngine;

public class CameraController : MonoBehaviour
{
    [Header("Zoom Settings")]
    public float zoomSpeed = 0.05f;  // Speed of zooming
    public float minZoom = 40f;      // Minimum zoom (closer)
    public float maxZoom = 90f;      // Maximum zoom (farther)
    public float smoothTime = 0.15f; // Smooth transition time
    public float pinchThreshold = 5f; // Minimum pinch movement required to trigger zoom

    [Header("Camera Follow Settings")]
    public Transform player;   // Reference to the player
    public float followSpeed = 5f; // Speed of camera movement
    public Vector3 baseOffset = new Vector3(0f, 2f, -10f); // Default offset
    public float zoomYOffset = 3f; // How much to adjust Y when zooming
    public float zoomZOffset = 5f; // How much to adjust Z when zooming in
    public Vector3 RestrictedMovementMax;
    public Vector3 RestrictedMovementMin;

    private Camera cam;
    private float targetZoom;
    private float zoomvelocity = 0f;
    private float initialDistance;
    private bool isPinching = false;
    private bool shouldFollowZ = false; // Determines if camera should follow Z
    private Vector3 velocity = Vector3.zero; // SmoothDamp velocity


    public bool ChangeRotation = false;
    public Vector3 RotationRequired;
    void Start()
    {
        cam = GetComponent<Camera>();
        targetZoom = cam.fieldOfView;
    }
    public int CameraCheckEveryHowManyFrames = 2;
    public int counter = 0;
    void Update()
    {
        counter++;
        if (counter % CameraCheckEveryHowManyFrames == 0)
        {
            //HandlePinchZoom();
            FollowPlayer();
        }
    }

    void HandlePinchZoom()
    {
        if (Input.touchCount == 2) // Check for two fingers on screen
        {
            Touch touch1 = Input.GetTouch(0);
            Touch touch2 = Input.GetTouch(1);

            float currentDistance = Vector2.Distance(touch1.position, touch2.position);

            if (touch1.phase == TouchPhase.Began || touch2.phase == TouchPhase.Began)
            {
                initialDistance = currentDistance;
                isPinching = false;
            }

            float difference = currentDistance - initialDistance;

            if (Mathf.Abs(difference) > pinchThreshold)
            {
                isPinching = true;
            }

            if (isPinching && (touch1.phase == TouchPhase.Moved || touch2.phase == TouchPhase.Moved))
            {
                targetZoom -= difference * zoomSpeed;
                targetZoom = Mathf.Clamp(targetZoom, minZoom, maxZoom);
                initialDistance = currentDistance;
            }
        }

        cam.fieldOfView = Mathf.SmoothDamp(cam.fieldOfView, targetZoom, ref zoomvelocity, smoothTime);

        // Enable Z follow only when zooming in (FoV < 60)
        shouldFollowZ = targetZoom < 60f;
    }

    void FollowPlayer()
    {
        // Adjust Y position based on zoom
        float yAdjustment = (targetZoom - minZoom) / (maxZoom - minZoom) * zoomYOffset;

        // Adjust Z position only if zoomed in (FoV < 70)
        float zAdjustment = shouldFollowZ ? zoomZOffset : 0f;

        // Define target position
        Vector3 targetPosition = new Vector3(
            Mathf.Clamp(player.position.x, -Mathf.Infinity, RestrictedMovementMax.x),
            Mathf.Clamp(player.position.y + baseOffset.y - yAdjustment,-Mathf.Infinity, RestrictedMovementMax.y), // Move Y when zooming
            Mathf.Clamp(shouldFollowZ ? player.position.z - zAdjustment : transform.position.z,-Mathf.Infinity,RestrictedMovementMax.z) // Follow Z only when zooming in
        );

        // Smoothly move the camera towards the target position
        transform.position = Vector3.SmoothDamp(transform.position, targetPosition, ref velocity, smoothTime);
        if(ChangeRotation)
        {
            transform.localEulerAngles = Vector3.Slerp(transform.localEulerAngles, RotationRequired, smoothTime);
            if((transform.localEulerAngles.x - RotationRequired.x) <= 0.1 
                && (transform.localEulerAngles.y - RotationRequired.y) <= 0.1
                && (transform.localEulerAngles.z - RotationRequired.z) <= 0.1)
            {
                ChangeRotation = false;
            }
        }
    }
}
