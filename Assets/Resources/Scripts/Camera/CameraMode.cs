using UnityEngine;

/// <summary>
/// Base interface for all camera modes (Fixed 2D, Rotatable 2D, Full 3D)
/// Each mode handles its own positioning, rotation, and constraints
/// </summary>
public interface ICameraMode
{
    /// <summary>
    /// Initialize the camera mode with a target player and camera transform
    /// </summary>
    void Initialize(Transform playerTransform, Camera cameraComponent);

    /// <summary>
    /// Update camera position and rotation based on player position and mode settings
    /// </summary>
    void UpdateCamera(float deltaTime);

    /// <summary>
    /// Called when transitioning TO this mode
    /// </summary>
    void OnModeEnter();

    /// <summary>
    /// Called when transitioning FROM this mode
    /// </summary>
    void OnModeExit();

    /// <summary>
    /// Get the current camera transform for smooth transitions
    /// </summary>
    CameraState GetCurrentState();

    /// <summary>
    /// Set movement constraints for the player (e.g., lock X axis in 2D)
    /// </summary>
    MovementConstraints GetMovementConstraints();
}

/// <summary>
/// Data structure representing camera state for smooth transitions
/// </summary>
public struct CameraState
{
    public Vector3 Position;
    public Quaternion Rotation;
    public float FieldOfView;

    public CameraState(Vector3 position, Quaternion rotation, float fov)
    {
        Position = position;
        Rotation = rotation;
        FieldOfView = fov;
    }
}

/// <summary>
/// Defines which axes the player can move along in a given camera mode
/// </summary>
public struct MovementConstraints
{
    public bool CanMoveX;
    public bool CanMoveY;
    public bool CanMoveZ;
    public bool CanRotate;

    public MovementConstraints(bool x, bool y, bool z, bool rotate = true)
    {
        CanMoveX = x;
        CanMoveY = y;
        CanMoveZ = z;
        CanRotate = rotate;
    }
}
