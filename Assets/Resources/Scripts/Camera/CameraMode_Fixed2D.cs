using UnityEngine;

/// <summary>
/// Fixed 2D Camera Mode - Side-scrolling perspective (like Little Nightmares attic section)
/// Camera position is locked except for following player X and Y movement
/// Camera cannot rotate; Z position is static
/// </summary>
public class CameraMode_Fixed2D : ICameraMode
{
    private Transform playerTransform;
    private Camera cameraComponent;
    private Vector3 currentPosition;
    private Vector3 velocity = Vector3.zero;

    // Settings
    private Vector3 baseOffset = new Vector3(0f, 1.5f, -10f);
    private float followSpeed = 5f;
    private float smoothTime = 0.15f;
    private float fieldOfView = 60f;

    // Bounds for camera movement
    private Vector3 minBounds = Vector3.zero;
    private Vector3 maxBounds = new Vector3(50f, 30f, -10f);

    public void Initialize(Transform playerTransform, Camera cameraComponent)
    {
        this.playerTransform = playerTransform;
        this.cameraComponent = cameraComponent;
        this.currentPosition = cameraComponent.transform.position;
    }

    public void UpdateCamera(float deltaTime)
    {
        if (playerTransform == null || cameraComponent == null)
            return;

        // Calculate target position (follow X and Y, keep Z fixed)
        Vector3 targetPosition = new Vector3(
            Mathf.Clamp(playerTransform.position.x + baseOffset.x, minBounds.x, maxBounds.x),
            Mathf.Clamp(playerTransform.position.y + baseOffset.y, minBounds.y, maxBounds.y),
            baseOffset.z // Z is always fixed
        );

        // Smoothly move camera to target
        currentPosition = Vector3.SmoothDamp(currentPosition, targetPosition, ref velocity, smoothTime);
        cameraComponent.transform.position = currentPosition;

        // Maintain rotation (always looking at the scene from the side)
        cameraComponent.transform.rotation = Quaternion.identity;
        cameraComponent.fieldOfView = fieldOfView;
    }

    public void OnModeEnter()
    {
        // Could add entry effects here (fade in, etc.)
    }

    public void OnModeExit()
    {
        // Could add exit effects here
    }

    public CameraState GetCurrentState()
    {
        return new CameraState(cameraComponent.transform.position, cameraComponent.transform.rotation, cameraComponent.fieldOfView);
    }

    public MovementConstraints GetMovementConstraints()
    {
        // In Fixed 2D: Can move X and Y, cannot move Z or rotate
        return new MovementConstraints(true, true, false, false);
    }

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

    public Vector3 GetBaseOffset() => baseOffset;
    public float GetFieldOfView() => fieldOfView;
    #endregion
}
