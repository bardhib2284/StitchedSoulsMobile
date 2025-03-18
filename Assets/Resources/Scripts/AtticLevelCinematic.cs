using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace Assets.Resources.Scripts
{
    public class AtticLevelCinematic : LevelCinematicManager
    {
        [Header("Player")]
        public PlayerController PlayerController;
        public Transform PlayerTransform;
        public Animator PlayerAnimator;
        public Light PlayerRealTimeLight;
        public Light HeadLight;
        public GameObject Joystick;

        [Header("UI")]
        public Joystick PlayerJoystick;
        public Button AttackButton;
        public Button JumpButton;


        [Header("Camera")]
        public Camera Camera;
        public Light CameraLight;

        internal void GiveLifeToPlayer()
        {
            StartCoroutine(GiveLifeToPlayerEnumerator());   
        }

        IEnumerator GiveLifeToPlayerEnumerator()
        {
            PlayerAnimator.SetTrigger("StandUp");
            yield return new WaitForSeconds(2f);
            PlayerController.enabled = true;
            PlayerRealTimeLight.enabled = true;
            HeadLight.enabled = true;
            Camera.GetComponent<CameraController>().enabled = true;
            Camera.GetComponent<CameraController>().ChangeRotation = true;
            Camera.GetComponent<CameraController>().RotationRequired = new Vector3(20f,Camera.main.transform.localEulerAngles.y, Camera.main.transform.localEulerAngles.z);

            PlayerJoystick.enabled = true ;
            PlayerController.MoveSpeedHandler = 0.85f;
            PlayerController.RunSpeedHandler = 0.95f;
            Joystick.SetActive(true);
            PlayerController.AssignJoystick(Joystick.GetComponent<FloatingJoystick>());
            CameraLight.gameObject.SetActive(true);
        }

        private void Start()
        {
            PlayerRealTimeLight.enabled = false;
            PlayerController.enabled = false;
            HeadLight.enabled = false;
            Camera.GetComponent<CameraController>().enabled = false;
            PlayerAnimator.SetTrigger("Dead");
            PlayerJoystick.enabled = false;
            //AttackButton.gameObject.SetActive(false);
            //JumpButton.gameObject.SetActive(false);
            CameraLight.gameObject.SetActive(false);
            Joystick.SetActive(false);
        }
    }
}
