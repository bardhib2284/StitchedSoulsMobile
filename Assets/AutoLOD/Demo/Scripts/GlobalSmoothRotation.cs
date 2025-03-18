using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AutoLOD.MeshDecimator
{
    public class GlobalSmoothRotation : MonoBehaviour
    {

        // Update is called once per frame
        void Update()
        {
            transform.Rotate(new Vector3(0f, 10f * Time.deltaTime, 0f), Space.World);
        }
    }
}
