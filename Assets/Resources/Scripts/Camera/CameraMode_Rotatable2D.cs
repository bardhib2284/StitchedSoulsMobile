using UnityEngine;

/// <summary>
/// Rotatable 2D Camera Mode - 2.5D perspective that can rotate between fixed angles
/// Similar to Little Nightmares where camera angle changes between areas
/// Player can move in X, Y, Z but camera rotates to show different 2.5D views
/// </summary>
public class CameraMode_Rotatable2D : ICameraMode
{
    private Transform playerTransform;
    private Camera cameraComponent;
    private Vector3 currentPosition;
    private Quaternion currentRotation;
    private Vector3 velocity = Vector3.zero;

    // Settings
    private Vector3 baseOffset = new Vector3(0f, 2f, -8f);
    private float followSpeed = 5f;
    private float smoothTime = 0.15f;
    private float fieldOfView = 60f;

    // Rotation settings
    private Quaternion targetRotation = Quaternion.identity;
    private float rotationSpeed = 3f; // How quickly to rotate between angles
    private float rotationTransitionTime = 0.5f;
    private float rotationTimer = 0f;
    private Quaternion rotationStarted = Quaternion.identity;

    // Bounds for camera movement
    private Vector3 minBounds = Vector3.zero;
    private Vector3 maxBounds = new Vector3(50f, 30f, 20f);

    // Whether camera is currently transitioning rotation
    private bool isRotating = false;

    public void Initialize(Transform playerTransform, Camera cameraComponent)
    {
        this.playerTransform = playerTransform;
        this.cameraComponent = cameraComponent;
        this.currentPosition = cameraComponent.transform.position;
        this.currentRotation = cameraComponent.transform.rotation;
    }

    public void UpdateCamera(float deltaTime)
    {
        if (playerTransform == null || cameraComponent == null)
            return;

        // Calculate target position (follow X, Y, and Z with constraints)
        Vector3 targetPosition = new Vector3(
            Mathf.Clamp(playerTransform.position.x + baseOffset.x, minBounds.x, maxBounds.x),
            Mathf.Clamp(playerTransform.position.y + baseOffset.y, minBounds.y, maxBounds.y),
            Mathf.Clamp(playerTransform.position.z + baseOffset.z, minBounds.z, maxBounds.z)
        );

        // Smoothly move camera to target
        currentPosition = Vector3.SmoothDamp(currentPosition, targetPosition, ref velocity, smoothTime);
        cameraComponent.transform.position = currentPosition;

        // Handle rotation (either transitioning or maintaining current angle)
        if (isRotating)
        {
            rotationTimer += deltaTime;
            float t = Mathf.Clamp01(rotationTimer / rotationTransitionTime);
            currentRotation = Quaternion.Lerp(rotationStarted, targetRotation, t);

            if (t >= 1f)
            {
                isRotating = false;
                currentRotation = targetRotation;
            }
        }
        else
        {
            currentRotation = targetRotation;
        }

        cameraComponent.transform.rotation = currentRotation;
        cameraComponent.fieldOfView = fieldOfView;
    }

    public void OnModeEnter()
    {
        // Reset rotation state when entering
        isRotating = false;
        targetRotation = cameraComponent.transform.rotation;
        currentRotation = targetRotation;
    }

    public void OnModeExit()
    {
        // Clean up rotation timer
        rotationTimer = 0f;
    }

    public CameraState GetCurrentState()
    {
        return new CameraState(cameraComponent.transform.position, cameraComponent.transform.rotation, cameraComponent.fieldOfView);
    }

    public MovementConstraints GetMovementConstraints()
    {
        // In Rotatable 2D: Can move X, Y, and Z, but player rotation might be limited
        return new MovementConstraints(true, true, true, true);
    }

    #region Rotation Control
    /// <summary>
    /// Rotate camera to a specific angle (in Euler angles)
    /// </summary>
    public void RotateToAngle(Vector3 eulerAngles, float transitionTime = 0.5f)
    {
        targetRotation = Quaternion.Euler(eulerAngles);
        rotationTransitionTime = transitionTime;
        if (transitionTime > 0f)
        {
            isRotating = true;
            rotationStarted = currentRotation;
            rotationTimer = 0f;
        }
        else
        {
            currentRotation = targetRotation;
            isRotating = false;
        }
    }

    /// <summary>
    /// Instantly rotate to a specific angle (no transition)
    /// </summary>
    public void InstantRotateToAngle(Vector3 eulerAngles)
    {
        RotateToAngle(eulerAngles, 0f);
    }

    /// <summary>
    /// Check if camera is currently rotating
    /// </summary>
    public bool IsRotating() => isRotating;
    #endregion

    #region Configuration Methods
    public void SetBaseOffset(Vector3 offset)
    {
        baseOffset = offset;
    }

    public void SetFollowSpeed(float speed)
    {
        followSpeed = speed;
    }

    public void SetSmoothTime(float time)
    {
        smoothTime = time;
    }

    public void SetFieldOfView(float fov)
    {
        fieldOfView = fov;
    }

    public void SetBounds(Vector3 min, Vector3 max)
    {
        minBounds = min;
        maxBounds = max;
    }

    public void SetRotationSpeed(float speed)
    {
        rotationSpeed = speed;
    }

    public Vector3 GetBaseOffset() => baseOffset;
    public float GetFieldOfView() => fieldOfView;
    public Quaternion GetTargetRotation() => targetRotation;
    #endregion
}
