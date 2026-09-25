using UnityEngine;

/// <summary>
/// Manages camera settings for a specific room/area
/// Each room can have different camera mode, angle, and boundaries
/// </summary>
public class RoomManager : MonoBehaviour
{
    [Header("Room Settings")]
    [SerializeField] private string roomName = "Room";
    [SerializeField] private Collider roomBounds;

    [Header("Camera Mode Settings")]
    [SerializeField] private CameraModeType cameraModeType = CameraModeType.Fixed2D;
    [SerializeField] private Vector3 cameraOffset = new Vector3(0f, 1.5f, -10f);
    [SerializeField] private Vector3 cameraBoundsMin = Vector3.zero;
    [SerializeField] private Vector3 cameraBoundsMax = new Vector3(50f, 30f, 20f);
    [SerializeField] private float cameraFOV = 60f;

    [Header("2.5D Rotation (for Rotatable2D mode)")]
    [SerializeField] private Vector3 cameraRotationEuler = Vector3.zero;
    [SerializeField] private float rotationTransitionTime = 0.5f;
    [SerializeField] private bool shouldRotateOnEntry = false;

    [Header("Full 3D Settings")]
    [SerializeField] private float minZoom = 40f;
    [SerializeField] private float maxZoom = 90f;

    [Header("Cinematic Settings")]
    [SerializeField] private bool hasCinematicOnEntry = false;
    [SerializeField] private float cinematicDuration = 3f;

    [Header("Audio")]
    [SerializeField] private AudioClip ambientLoop;
    [SerializeField] private float ambientVolume = 0.5f;

    private CameraManager cameraManager;
    private AudioSource ambientSource;
    private bool hasBeenEntered = false;
    private bool isPlayerInRoom = false;

    private void OnTriggerEnter(Collider collision)
    {
        if (collision.CompareTag("Player"))
        {
            EnterRoom();
        }
    }

    private void OnTriggerStay(Collider collision)
    {
        if (collision.CompareTag("Player"))
        {
            isPlayerInRoom = true;
        }
    }

    private void OnTriggerExit(Collider collision)
    {
        if (collision.CompareTag("Player"))
        {
            isPlayerInRoom = false;
            ExitRoom();
        }
    }

    private void EnterRoom()
    {
        if (hasBeenEntered)
            return; // Only apply settings on first entry

        hasBeenEntered = true;
        isPlayerInRoom = true;

        cameraManager = CameraManager.Instance;
        if (cameraManager == null)
            return;

        // Apply camera settings
        ApplyCameraSettings();

        // Switch to this room's camera mode with transition
        cameraManager.SwitchToMode(cameraModeType, transitionDuration: 0.5f);

        // If this mode supports rotation, apply it
        if (shouldRotateOnEntry && (cameraModeType == CameraModeType.Rotatable2D || cameraModeType == CameraModeType.Full3D))
        {
            cameraManager.RotateCamera(cameraRotationEuler, rotationTransitionTime);
        }

        // Play ambient audio
        if (ambientLoop != null)
        {
            PlayAmbientAudio();
        }

        // Trigger cinematic if needed
        if (hasCinematicOnEntry)
        {
            TriggerCinematic();
        }

        Debug.Log($"Entered Room: {roomName} (Camera Mode: {cameraModeType})");
    }

    private void ExitRoom()
    {
        Debug.Log($"Exited Room: {roomName}");
        StopAmbientAudio();
    }

    /// <summary>
    /// Apply all camera configuration settings from this room to the CameraManager
    /// </summary>
    private void ApplyCameraSettings()
    {
        switch (cameraModeType)
        {
            case CameraModeType.Fixed2D:
                cameraManager.ConfigureFixed2D(cameraOffset, cameraBoundsMin, cameraBoundsMax, cameraFOV);
                break;

            case CameraModeType.Rotatable2D:
                cameraManager.ConfigureRotatable2D(cameraOffset, cameraBoundsMin, cameraBoundsMax, cameraFOV);
                break;

            case CameraModeType.Full3D:
                cameraManager.ConfigureFull3D(cameraOffset, cameraBoundsMin, cameraBoundsMax, minZoom, maxZoom);
                break;
        }
    }

    /// <summary>
    /// Play ambient background music for this room
    /// </summary>
    private void PlayAmbientAudio()
    {
        if (ambientSource == null)
        {
            ambientSource = gameObject.AddComponent<AudioSource>();
        }

        ambientSource.clip = ambientLoop;
        ambientSource.volume = ambientVolume;
        ambientSource.loop = true;
        ambientSource.Play();
    }

    /// <summary>
    /// Stop playing ambient audio
    /// </summary>
    private void StopAmbientAudio()
    {
        if (ambientSource != null && ambientSource.isPlaying)
        {
            ambientSource.Stop();
        }
    }

    /// <summary>
    /// Trigger cinematic sequence on room entry
    /// </summary>
    private void TriggerCinematic()
    {
        // This is a placeholder - implement custom cinematic logic per room
        Debug.Log($"Starting cinematic in {roomName} for {cinematicDuration} seconds");

        // Example: Pause player, play animation, etc.
    }

    #region Editor Visualization
    private void OnDrawGizmos()
    {
        // Draw room bounds
        if (roomBounds != null)
        {
            Gizmos.color = Color.green;
            Gizmos.DrawWireCube(roomBounds.bounds.center, roomBounds.bounds.size);
        }

        // Draw camera bounds
        Gizmos.color = Color.cyan;
        Vector3 boundsCenter = (cameraBoundsMin + cameraBoundsMax) / 2f;
        Vector3 boundsSize = cameraBoundsMax - cameraBoundsMin;
        Gizmos.DrawWireCube(boundsCenter + transform.position, boundsSize);

        // Draw camera offset position
        Gizmos.color = Color.yellow;
        Gizmos.DrawLine(transform.position, transform.position + cameraOffset);
    }
    #endregion

    #region Getters
    public string GetRoomName() => roomName;
    public bool IsPlayerInRoom() => isPlayerInRoom;
    public CameraModeType GetCameraModeType() => cameraModeType;
    public Vector3 GetCameraOffset() => cameraOffset;
    public Vector3 GetCameraRotationEuler() => cameraRotationEuler;
    #endregion

    #region Setters (for dynamic room configuration)
    public void SetCameraModeType(CameraModeType mode) => cameraModeType = mode;
    public void SetCameraOffset(Vector3 offset) => cameraOffset = offset;
    public void SetCameraRotation(Vector3 rotation) => cameraRotationEuler = rotation;
    public void SetCameraBounds(Vector3 min, Vector3 max)
    {
        cameraBoundsMin = min;
        cameraBoundsMax = max;
    }
    #endregion
}
