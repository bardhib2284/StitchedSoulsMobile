using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Central camera manager that orchestrates different camera modes
/// Handles mode switching, transitions, and communication with RoomManager
/// </summary>
public class CameraManager : MonoBehaviour
{
    [SerializeField] private Camera mainCamera;
    [SerializeField] private Transform playerTransform;

    // Camera mode instances
    private ICameraMode currentMode;
    private CameraMode_Fixed2D mode_Fixed2D;
    private CameraMode_Rotatable2D mode_Rotatable2D;
    private CameraMode_Full3D mode_Full3D;

    // Transition state
    private bool isTransitioning = false;
    private float transitionTimer = 0f;
    private float transitionDuration = 0.5f;
    private CameraState transitionStartState;
    private CameraState transitionEndState;

    // Movement constraints from current mode
    private MovementConstraints currentConstraints = new MovementConstraints(true, true, true, true);

    // Singleton pattern (optional, for easy access)
    public static CameraManager Instance { get; private set; }

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else if (Instance != this)
        {
            Destroy(gameObject);
            return;
        }

        // Initialize all camera modes
        mode_Fixed2D = new CameraMode_Fixed2D();
        mode_Rotatable2D = new CameraMode_Rotatable2D();
        mode_Full3D = new CameraMode_Full3D();

        // Set default mode to Fixed 2D
        SwitchToMode(CameraModeType.Fixed2D, transitionDuration: 0f);
    }

    private void Start()
    {
        if (mainCamera == null)
            mainCamera = Camera.main;
    }

    private void Update()
    {
        // Handle camera transitions
        if (isTransitioning)
        {
            HandleTransition();
        }

        // Update current camera mode
        if (currentMode != null)
        {
            currentMode.UpdateCamera(Time.deltaTime);
        }

        // Update movement constraints for player
        currentConstraints = currentMode.GetMovementConstraints();
    }

    /// <summary>
    /// Switch to a different camera mode with optional transition
    /// </summary>
    public void SwitchToMode(CameraModeType modeType, float transitionDuration = 0.5f)
    {
        ICameraMode newMode = modeType switch
        {
            CameraModeType.Fixed2D => mode_Fixed2D,
            CameraModeType.Rotatable2D => mode_Rotatable2D,
            CameraModeType.Full3D => mode_Full3D,
            _ => currentMode
        };

        if (newMode == null || newMode == currentMode)
            return;

        // Prepare transition
        if (currentMode != null && transitionDuration > 0f)
        {
            isTransitioning = true;
            transitionTimer = 0f;
            transitionDuration = transitionDuration;
            transitionStartState = currentMode.GetCurrentState();
        }

        // Exit old mode
        if (currentMode != null)
            currentMode.OnModeExit();

        // Switch to new mode
        currentMode = newMode;
        currentMode.Initialize(playerTransform, mainCamera);
        currentMode.OnModeEnter();

        // Get target state for transition
        transitionEndState = currentMode.GetCurrentState();
    }

    /// <summary>
    /// Smoothly transition between camera states
    /// </summary>
    private void HandleTransition()
    {
        transitionTimer += Time.deltaTime;
        float t = Mathf.Clamp01(transitionTimer / transitionDuration);

        // Interpolate position
        Vector3 transitionPosition = Vector3.Lerp(transitionStartState.Position, transitionEndState.Position, t);

        // Interpolate rotation
        Quaternion transitionRotation = Quaternion.Lerp(transitionStartState.Rotation, transitionEndState.Rotation, t);

        // Interpolate FOV
        float transitionFOV = Mathf.Lerp(transitionStartState.FieldOfView, transitionEndState.FieldOfView, t);

        // Apply transition state
        mainCamera.transform.position = transitionPosition;
        mainCamera.transform.rotation = transitionRotation;
        mainCamera.fieldOfView = transitionFOV;

        if (t >= 1f)
        {
            isTransitioning = false;
        }
    }

    #region Mode Configuration Methods

    /// <summary>
    /// Configure Fixed 2D mode
    /// </summary>
    public void ConfigureFixed2D(Vector3 offset, Vector3 minBounds, Vector3 maxBounds, float fov = 60f)
    {
        mode_Fixed2D.SetBaseOffset(offset);
        mode_Fixed2D.SetBounds(minBounds, maxBounds);
        mode_Fixed2D.SetFieldOfView(fov);
    }

    /// <summary>
    /// Configure Rotatable 2D mode
    /// </summary>
    public void ConfigureRotatable2D(Vector3 offset, Vector3 minBounds, Vector3 maxBounds, float fov = 60f)
    {
        mode_Rotatable2D.SetBaseOffset(offset);
        mode_Rotatable2D.SetBounds(minBounds, maxBounds);
        mode_Rotatable2D.SetFieldOfView(fov);
    }

    /// <summary>
    /// Configure Full 3D mode
    /// </summary>
    public void ConfigureFull3D(Vector3 offset, Vector3 minBounds, Vector3 maxBounds, float minZoom = 40f, float maxZoom = 90f)
    {
        mode_Full3D.SetBaseOffset(offset);
        mode_Full3D.SetBounds(minBounds, maxBounds);
        mode_Full3D.SetZoomRange(minZoom, maxZoom);
    }

    #endregion

    #region Rotation Control

    /// <summary>
    /// Rotate camera to a specific angle (only works for Rotatable2D and Full3D)
    /// </summary>
    public void RotateCamera(Vector3 eulerAngles, float transitionTime = 0.5f)
    {
        if (currentMode is CameraMode_Rotatable2D rotatableMode)
        {
            rotatableMode.RotateToAngle(eulerAngles, transitionTime);
        }
        else if (currentMode is CameraMode_Full3D fullMode)
        {
            fullMode.RotateToAngle(eulerAngles);
        }
    }

    /// <summary>
    /// Instantly rotate camera to angle
    /// </summary>
    public void InstantRotateCamera(Vector3 eulerAngles)
    {
        if (currentMode is CameraMode_Rotatable2D rotatableMode)
        {
            rotatableMode.InstantRotateToAngle(eulerAngles);
        }
        else if (currentMode is CameraMode_Full3D fullMode)
        {
            fullMode.InstantRotateToAngle(eulerAngles);
        }
    }

    #endregion

    #region Getters

    public MovementConstraints GetMovementConstraints() => currentConstraints;

    public CameraModeType GetCurrentModeType()
    {
        return currentMode switch
        {
            CameraMode_Fixed2D => CameraModeType.Fixed2D,
            CameraMode_Rotatable2D => CameraModeType.Rotatable2D,
            CameraMode_Full3D => CameraModeType.Full3D,
            _ => CameraModeType.Fixed2D
        };
    }

    public bool IsTransitioning() => isTransitioning;

    public bool IsRotating()
    {
        if (currentMode is CameraMode_Rotatable2D rotatableMode)
            return rotatableMode.IsRotating();
        return false;
    }

    #endregion
}

/// <summary>
/// Enumeration for all available camera modes
/// </summary>
public enum CameraModeType
{
    Fixed2D,      // Side-scrolling, locked perspective
    Rotatable2D,  // 2.5D with rotatable camera angles
    Full3D        // Traditional third-person with full freedom
}
