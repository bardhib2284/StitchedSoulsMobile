using UnityEngine;

/// <summary>
/// Optional helper script to initialize the camera system with default settings
/// Useful for testing or as a reference for how to configure the system
/// </summary>
public class CameraSystemInitializer : MonoBehaviour
{
    [Header("Initialization Settings")]
    [SerializeField] private bool initializeOnAwake = true;
    [SerializeField] private CameraModeType defaultMode = CameraModeType.Fixed2D;

    [Header("Default Fixed2D Configuration")]
    [SerializeField] private Vector3 fixed2D_Offset = new Vector3(0f, 1.5f, -10f);
    [SerializeField] private Vector3 fixed2D_BoundsMin = Vector3.zero;
    [SerializeField] private Vector3 fixed2D_BoundsMax = new Vector3(50f, 30f, 0f);
    [SerializeField] private float fixed2D_FOV = 60f;

    [Header("Default Rotatable2D Configuration")]
    [SerializeField] private Vector3 rotatable2D_Offset = new Vector3(0f, 2f, -8f);
    [SerializeField] private Vector3 rotatable2D_BoundsMin = Vector3.zero;
    [SerializeField] private Vector3 rotatable2D_BoundsMax = new Vector3(50f, 30f, 20f);
    [SerializeField] private float rotatable2D_FOV = 60f;

    [Header("Default Full3D Configuration")]
    [SerializeField] private Vector3 full3D_Offset = new Vector3(0f, 2f, -10f);
    [SerializeField] private Vector3 full3D_BoundsMin = new Vector3(-30f, 0f, -30f);
    [SerializeField] private Vector3 full3D_BoundsMax = new Vector3(30f, 30f, 30f);
    [SerializeField] private float full3D_MinZoom = 40f;
    [SerializeField] private float full3D_MaxZoom = 90f;

    private void Awake()
    {
        if (initializeOnAwake)
        {
            InitializeCamera();
        }
    }

    /// <summary>
    /// Initialize camera system with default settings
    /// </summary>
    public void InitializeCamera()
    {
        CameraManager manager = CameraManager.Instance;
        if (manager == null)
        {
            Debug.LogError("CameraManager instance not found! Make sure it exists in the scene.");
            return;
        }

        // Configure all modes with their default settings
        manager.ConfigureFixed2D(fixed2D_Offset, fixed2D_BoundsMin, fixed2D_BoundsMax, fixed2D_FOV);
        manager.ConfigureRotatable2D(rotatable2D_Offset, rotatable2D_BoundsMin, rotatable2D_BoundsMax, rotatable2D_FOV);
        manager.ConfigureFull3D(full3D_Offset, full3D_BoundsMin, full3D_BoundsMax, full3D_MinZoom, full3D_MaxZoom);

        // Switch to default mode
        manager.SwitchToMode(defaultMode, transitionDuration: 0.5f);

        Debug.Log($"Camera system initialized with {defaultMode} mode");
    }

    /// <summary>
    /// Example: Test switching between all modes
    /// </summary>
    public void TestCycleModes()
    {
        CameraManager manager = CameraManager.Instance;
        CameraModeType current = manager.GetCurrentModeType();

        switch (current)
        {
            case CameraModeType.Fixed2D:
                manager.SwitchToMode(CameraModeType.Rotatable2D);
                break;
            case CameraModeType.Rotatable2D:
                manager.SwitchToMode(CameraModeType.Full3D);
                break;
            case CameraModeType.Full3D:
                manager.SwitchToMode(CameraModeType.Fixed2D);
                break;
        }

        Debug.Log($"Switched to {manager.GetCurrentModeType()} mode");
    }

    /// <summary>
    /// Example: Test camera rotation in Rotatable2D
    /// </summary>
    public void TestRotateCamera(Vector3 eulerAngles)
    {
        CameraManager manager = CameraManager.Instance;
        manager.RotateCamera(eulerAngles, transitionTime: 0.5f);
        Debug.Log($"Rotating camera to {eulerAngles}");
    }

    #region Keyboard Input for Testing (Comment out for production)
    private void Update()
    {
        // Quick test: Press number keys to switch modes
        if (Input.GetKeyDown(KeyCode.Alpha1))
        {
            CameraManager.Instance.SwitchToMode(CameraModeType.Fixed2D);
            Debug.Log("Switched to Fixed2D");
        }
        if (Input.GetKeyDown(KeyCode.Alpha2))
        {
            CameraManager.Instance.SwitchToMode(CameraModeType.Rotatable2D);
            Debug.Log("Switched to Rotatable2D");
        }
        if (Input.GetKeyDown(KeyCode.Alpha3))
        {
            CameraManager.Instance.SwitchToMode(CameraModeType.Full3D);
            Debug.Log("Switched to Full3D");
        }

        // Test rotation (only works in Rotatable2D or Full3D)
        if (Input.GetKeyDown(KeyCode.Q))
        {
            CameraManager.Instance.RotateCamera(new Vector3(30, 0, 0), 0.5f);
            Debug.Log("Rotating to 30° up");
        }
        if (Input.GetKeyDown(KeyCode.W))
        {
            CameraManager.Instance.RotateCamera(Vector3.zero, 0.5f);
            Debug.Log("Rotating to front view");
        }
        if (Input.GetKeyDown(KeyCode.E))
        {
            CameraManager.Instance.RotateCamera(new Vector3(0, 45, 0), 0.5f);
            Debug.Log("Rotating to 45° side");
        }
    }
    #endregion
}
