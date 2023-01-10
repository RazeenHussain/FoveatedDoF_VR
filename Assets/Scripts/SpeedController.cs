using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using BezierSolution;

public class SpeedController : MonoBehaviour
{

    public float normalSpeed = 15.0f;
    public float dropSpeed = 20.0f;
    public float climbUpSpeed = 10.0f;

    public float speedChangeAcceleration = 5.0f;

    public AudioClip fastAudioClip;
    public AudioClip normalAudioClip;
    public AudioClip slowAudioClip;

    private DoubleAudioSource doubleAudioSource;
    private const int NORMAL_SPEED_MODE = 1;
    private const int DROP_SPEED_MODE = 2;
    private const int CLIMB_UP_SPEED_MODE = 3;

    private int speedMode = NORMAL_SPEED_MODE;
    private int previousSpeedMode = NORMAL_SPEED_MODE;

    private bool changeSpeed = false;

    private SplineFollower splineFollower;

    private int round = 0;

    [Range(1, 10)]
    public int totalRounds = 4;

    // Use this for initialization
    void Start()
    {
        splineFollower = GetComponent<SplineFollower>();
        doubleAudioSource = GetComponent<DoubleAudioSource>();
        if (doubleAudioSource != null && normalAudioClip != null)
        {
            doubleAudioSource.CrossFade(normalAudioClip, 1.0f, 2.0f);

        }
        splineFollower.speed = normalSpeed;
    }

    // Update is called once per frame
    void Update()
    {
        if (changeSpeed)
        {
            if (previousSpeedMode == NORMAL_SPEED_MODE && speedMode == CLIMB_UP_SPEED_MODE)
            {
                splineFollower.speed -= (speedChangeAcceleration * Time.deltaTime);

                if (splineFollower.speed <= climbUpSpeed)
                {
                    print("Reached climb up speed");

                    changeSpeed = false;
                }
            }
            else if (previousSpeedMode == CLIMB_UP_SPEED_MODE && speedMode == NORMAL_SPEED_MODE)
            {
                splineFollower.speed += (speedChangeAcceleration * Time.deltaTime);

                if (splineFollower.speed >= normalSpeed)
                {
                    print("Reached normal speed");
                    changeSpeed = false;
                }
            }
            else if (previousSpeedMode == NORMAL_SPEED_MODE && speedMode == DROP_SPEED_MODE)
            {
                splineFollower.speed += (speedChangeAcceleration * Time.deltaTime);

                if (splineFollower.speed >= dropSpeed)
                {
                    print("Reached drop speed");
                    changeSpeed = false;
                }
            }
            else if (previousSpeedMode == DROP_SPEED_MODE && speedMode == NORMAL_SPEED_MODE)
            {
                splineFollower.speed -= (speedChangeAcceleration * Time.deltaTime);

                if (splineFollower.speed <= normalSpeed)
                {
                    print("Reached normal speed");
                    changeSpeed = false;
                }
            }
            if ((round/2)>totalRounds)
            {
                GameObject cameraVR = GameObject.Find("Camera");
                depthEye eyeScript = cameraVR.GetComponent<depthEye>();
                eyeScript.PlayerMotion = false;
            }
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        print("OnTriggerEnter " + other.tag);
        previousSpeedMode = speedMode;

        if (other.CompareTag("Normal"))
        {
            speedMode = NORMAL_SPEED_MODE;
            changeSpeed = true;
            print("Change to normal speed");

            if (doubleAudioSource != null && normalAudioClip != null)
            {
                doubleAudioSource.CrossFade(normalAudioClip, 1.0f, 2.0f);
            }

        }
        else if (other.CompareTag("Drop"))
        {
            speedMode = DROP_SPEED_MODE;
            changeSpeed = true;
            print("Change to drop speed");

            if (doubleAudioSource != null && fastAudioClip != null)
            {
                doubleAudioSource.CrossFade(fastAudioClip, 1.0f, 2.0f);
            }

        }
        else if (other.CompareTag("Climb up"))
        {
            speedMode = CLIMB_UP_SPEED_MODE;
            changeSpeed = true;
            print("Change to climb up speed");
            if (doubleAudioSource != null && slowAudioClip != null)
            {
                doubleAudioSource.CrossFade(slowAudioClip, 1.0f, 2.0f);

            }

        }
        else if (other.CompareTag("Checkpoint"))
        {
            print(round);
            round++;
        }
    }
    private void OnTriggerExit(Collider other)
    {
        print("OnTriggerExit");
    }
    private void OnCollisionEnter(Collision collision)
    {
        print(collision.gameObject.name);
        if (collision.collider.name=="checkPoint")
        {
            round++;
        }
    }
}
