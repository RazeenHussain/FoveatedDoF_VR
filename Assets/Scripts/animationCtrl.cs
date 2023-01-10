using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class animationCtrl : MonoBehaviour
{
    private float plrSpeed;
    GameObject coaster;
    SplineFollower plrScript;
    GameObject cameraVR;

    // Start is called before the first frame update
    void Start()
    {
        cameraVR = GameObject.Find("Camera");
//        cameraVR.GetComponent<readEye>().enabled = true;
//        cameraVR.GetComponent<blurEye>().enabled = false;
        coaster = GameObject.Find("Rollercoaster");
        plrScript = coaster.GetComponent<SplineFollower>();
        plrSpeed = plrScript.speed;
        coaster.GetComponent<SpeedController>().enabled = false;
        plrScript.speed = 0.001f;
    }

    // Update is called once per frame
    void Update()
    {
        // Rollercoaster movement enable/disable
        if (Input.GetKeyDown(KeyCode.P))
        {
            if (plrScript.speed >= 0.5f)
            {
                plrSpeed = plrScript.speed;
                coaster.GetComponent<SpeedController>().enabled = false;
            }
            plrScript.speed = 0.001f;
        }
        else if (Input.GetKeyDown(KeyCode.S))
        {
            plrScript.speed = plrSpeed;
            coaster.GetComponent<SpeedController>().enabled = true;
        }
/*
        // Blur enable/disable
        if (Input.GetKeyDown(KeyCode.B))
        {
//            cameraVR.GetComponent<readEye>().enabled = false;
//            cameraVR.GetComponent<blurEye>().enabled = true;
        }
        else if (Input.GetKeyDown(KeyCode.U))
        {
//            cameraVR.GetComponent<readEye>().enabled = true;
//            cameraVR.GetComponent<blurEye>().enabled = false;
        }
        */
    }
}
