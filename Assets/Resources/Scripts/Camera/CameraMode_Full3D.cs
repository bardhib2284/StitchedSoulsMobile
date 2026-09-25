using UnityEngine;

/// <summary>
/// Full 3D Camera Mode - Traditional third-person camera with full rotation freedom
/// Player can move and rotate freely, camera follows with zoom support
/// Based on your existing CameraController implementation
/// </summary>
public class CameraMode_Full3D : ICameraMode
{
    private Transform playerTransform;
    private Camera cameraComponent;
    private Vector3 currentPosition;
    private Vector3 velocity = Vector3.zero;

    // Settings
    private Vector3 baseOffset = new Vector3(0f, 2f, -10f);
    private float followSpeed = 5f;
    private float smoothTime = 0.15f;

    // Zoom settings
    private float targetZoom;
    private float minZoom = 40f;
    private float maxZoom = 90f;
    private float zoomSpeed = 0.05f;
    private float zoomVelocity = 0f;
    private float zoomYOffset = 3f;
    private float zoomZOffset = 5f;

    // Bounds for camera movement
    private Vector3 minBounds = Vector3.zero;
    private Vector3 maxBounds = new Vector3(100f, 50f, 50f);

    // Pinch zoom state
    private float initialDistance = 0f;
    private bool isPinching = false;
    private float pinchThreshold = 5f;
    private bool shouldFollowZ = false;

    // Rotation
    private Quaternion targetRotation = Quaternion.identity;
    private bool isRotating = false;

    public void Initialize(Transform playerTransform, Camera cameraComponent)
    {
        this.playerTransform = playerTransform;
        this.cameraComponent = cameraComponent;
        this.currentPosition = cameraComponent.transform.position;
        this.targetZoom = cameraComponent.fieldOfView;
    }

    public void UpdateCamera(float deltaTime)
    {
        if (playerTransform == null || cameraComponent == null)
            return;

        HandlePinchZoom();

        // Adjust Y position based on zoom
        float yAdjustment = (targetZoom - minZoom) / (maxZoom - minZoom) * zoomYOffset;

        // Adjust Z position only if zoomed in (FoV < 70)
        float zAdjustment = shouldFollowZ ? zoomZOffset : 0f;

        // Define target position
        Vector3 targetPosition = new Vector3(
            Mathf.Clamp(playerTransform.position.x + baseOffset.x, minBounds.x, maxBounds.x),
            Mathf.Clamp(playerTransform.position.y + baseOffset.y - yAdjustment, minBounds.y, maxBounds.y),
            Mathf.Clamp(shouldFollowZ ? playerTransform.position.z + baseOffset.z - zAdjustment : currentPosition.z, minBounds.z, maxBounds.z)
        );

        // Smoothly move the camera towards the target position
        currentPosition = Vector3.SmoothDamp(currentPosition, targetPosition, ref velocity, smoothTime);
        cameraComponent.transform.position = currentPosition;

        // Handle rotation if needed
        if (isRotating)
        {
            cameraComponent.transform.rotation = Quaternion.Lerp(cameraComponent.transform.rotation, targetRotation, smoothTime * 5f);
        }

        // Update FOV with smooth damping
        cameraComponent.fieldOfView = Mathf.SmoothDamp(cameraComponent.fieldOfView, targetZoom, ref zoomVelocity, smoothTime);
    }

    public void OnModeEnter()
    {
        // Could add entry effects here
        targetZoom = cameraComponent.fieldOfView;
    }

    public void OnModeExit()
    {
        // Clean up zoom state
        isPinching = false;
    }

    public CameraState GetCurrentState()
    {
        return new CameraState(cameraComponent.transform.position, cameraComponent.transform.rotation, cameraComponent.fieldOfView);
    }

    public MovementConstraints GetMovementConstraints()
    {
        // In Full 3D: Can move and rotate freely
        return new MovementConstraints(true, true, true, true);
    }

    #region Pinch Zoom
    private void HandlePinchZoom()
    {
        if (Input.touchCount == 2)
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

        // Enable Z follow only when zooming in (FoV < 60)
        shouldFollowZ = targetZoom < 60f;
    }
    #endregion

    #region Rotation Control
    public void RotateToAngle(Vector3 eulerAngles)
    {
        targetRotation = Quaternion.Euler(eulerAngles);
        isRotating = true;
    }

    public void InstantRotateToAngle(Vector3 eulerAngles)
    {
        targetRotation = Quaternion.Euler(eulerAngles);
        cameraComponent.transform.rotation = targetRotation;
        isRotating = false;
    }
    #endregion

    #region Configuration Methods
    public void SetBaseOffset(Vector3 offset) => baseOffset = offset;
    public void SetFollowSpeed(float speed) => followSpeed = speed;
    public void SetSmoothTime(float time) => smoothTime = time;
    public void SetZoomRange(float min, float max)
    {
        minZoom = min;
        maxZoom = max;
        targetZoom = Mathf.Clamp(targetZoom, minZoom, maxZoom);
    }
    public void SetBounds(Vector3 min, Vector3 max)
    {
        minBounds = min;
        maxBounds = max;
    }
    public void SetZoomOffsets(float yOffset, float zOffset)
    {
        zoomYOffset = yOffset;
        zoomZOffset = zOffset;
    }

    public Vector3 GetBaseOffset() => baseOffset;
    public float GetCurrentZoom() => cameraComponent.fieldOfView;
    #endregion
}
