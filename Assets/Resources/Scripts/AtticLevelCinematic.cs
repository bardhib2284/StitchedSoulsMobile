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
        public GameObject CanvasBlocker;

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
            yield return new WaitForSeconds(2.5f);
            PlayerAnimator.CrossFade("WakeUpAtticAnimation", 0.5f);
            HeadLight.enabled = true;
            PlayerRealTimeLight.enabled = true;
            yield return new WaitForSeconds(0.5f);
            HeadLight.enabled = false;
            PlayerRealTimeLight.enabled = false;
            yield return new WaitForSeconds(1.5f);
            yield return new WaitForSeconds(0.2f);
            HeadLight.enabled = false;
            PlayerRealTimeLight.enabled = false;
            yield return new WaitForSeconds(0.1f);
            HeadLight.enabled = true;
            PlayerRealTimeLight.enabled = true;
            yield return new WaitForSeconds(0.2f);
            HeadLight.enabled = false;
            PlayerRealTimeLight.enabled = false;
            yield return new WaitForSeconds(1.5f);
            yield return new WaitForSeconds(0.05f);
            HeadLight.enabled = true;
            PlayerRealTimeLight.enabled = true;
            yield return new WaitForSeconds(0.05f);
            HeadLight.enabled = false;
            PlayerRealTimeLight.enabled = false;
            yield return new WaitForSeconds(0.05f);
            HeadLight.enabled = true;
            PlayerRealTimeLight.enabled = true;
            yield return new WaitForSeconds(0.04f);
            HeadLight.enabled = false;
            PlayerRealTimeLight.enabled = false;
            yield return new WaitForSeconds(.5f);
            yield return new WaitForSeconds(0.04f);
            HeadLight.enabled = true;
            PlayerRealTimeLight.enabled = true;
            yield return new WaitForSeconds(0.04f);
            HeadLight.enabled = false;
            PlayerRealTimeLight.enabled = false;
            yield return new WaitForSeconds(0.03f);
            HeadLight.enabled = true;
            PlayerRealTimeLight.enabled = true;
            yield return new WaitForSeconds(0.03f);
            HeadLight.enabled = false;
            PlayerRealTimeLight.enabled = false;
            yield return new WaitForSeconds(0.01f);
            HeadLight.enabled = true;
            PlayerRealTimeLight.enabled = true;
            yield return new WaitForSeconds(0.01f);
            HeadLight.enabled = false;
            PlayerRealTimeLight.enabled = false;
            yield return new WaitForSeconds(0.01f);
            HeadLight.enabled = true;
            PlayerRealTimeLight.enabled = true;
            yield return new WaitForSeconds(0.01f);
            HeadLight.enabled = false;
            PlayerRealTimeLight.enabled = false;
            yield return new WaitForSeconds(0.01f);
            HeadLight.enabled = true;
            PlayerRealTimeLight.enabled = true;

            yield return new WaitForSeconds(1f);
            PlayerController.enabled = true;
            PlayerRealTimeLight.enabled = true;
            

            Camera.GetComponent<CameraController>().enabled = true;
            Camera.GetComponent<CameraController>().ChangeRotation = true;
            Camera.GetComponent<CameraController>().RotationRequired = new Vector3(40f,Camera.main.transform.localEulerAngles.y, Camera.main.transform.localEulerAngles.z);

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
            CanvasBlocker.SetActive(false);

        }
    }
}
