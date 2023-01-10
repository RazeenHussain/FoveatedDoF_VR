using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using Tobii.XR;
using Tobii.G2OM;
using System.IO;
using UnityEditor;

//[ExecuteInEditMode, ImageEffectAllowedInSceneView]
[ExecuteInEditMode]
public class depthEye : MonoBehaviour
{
    [HideInInspector]
    public Shader dofShader;

    [NonSerialized]
    Material dofMaterial;

    const int circleOfConfusionPass = 0;
    const int preFilterPass = 1;
    const int bokehPass = 2;
    const int postFilterPass = 3;
    const int combinePass = 4;

    [Range(0.1f, 1000f)]
    public float focusDistance = 100f;

    [Range(0.1f, 400f)]
    public float focusRange = 30f;

    [Range(1f, 10f)]
    public float bokehRadius = 4f;

    public bool BlurControl = false;
    public bool PlayerMotion = false;
    private float plrSpeed = 0.001f;
    GameObject coaster = null;
    SplineFollower plrScript = null;
    private bool prevPlay = false;

    public float gazeX;
    public float gazeY;
    private Camera cam = null;
    private Vector3 lastGazeDirection;
    private Vector3 lastScreenPos;
    public IEyeTrackingProvider EyetrackingProvider { get; set; }
    private float defaultDistance;
    private StreamWriter outputWriter = null;
    private bool recordEyeData;
    private float distance;
    //string pathOut = "Assets/Logs/Name.txt";

    public blurEye bscript;


    void Start()
    {
        bscript = GetComponent<blurEye>();
        TobiiXR.Start();
        cam = GetComponentInChildren<Camera>();
        defaultDistance = cam.farClipPlane - 10f;
        //int i = 0;
        //while (File.Exists("Assets/Logs/Data" + i + ".txt"))
        //{
            //i++;
        //}
        //pathOut = "Assets/Logs/Data" + i + ".txt";
        recordEyeData = false;
        distance = defaultDistance;
        coaster = GameObject.Find("Rollercoaster");
        plrScript = coaster.GetComponent<SplineFollower>();
        plrSpeed = plrScript.speed;
        coaster.GetComponent<SpeedController>().enabled = false;
        plrScript.speed = 0.001f;
        Debug.Log("width"+ cam.pixelWidth);
        Debug.Log("height" + cam.pixelHeight);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (dofMaterial == null)
        {
            dofMaterial = new Material(dofShader);
            dofMaterial.hideFlags = HideFlags.HideAndDontSave;
        }
        if (BlurControl)
        {
            dofMaterial.SetFloat("_FocusDistance", focusDistance);
            dofMaterial.SetFloat("_FocusRange", focusRange);
            dofMaterial.SetFloat("_BokehRadius", bokehRadius);

            int width = source.width / 2;
            int height = source.height / 2;
            RenderTextureFormat format = source.format;
            RenderTexture dof0 = RenderTexture.GetTemporary(width, height, 0, format);
            RenderTexture dof1 = RenderTexture.GetTemporary(width, height, 0, format);
            RenderTexture coc = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.RHalf, RenderTextureReadWrite.Linear);

            dofMaterial.SetTexture("_CoCTex", coc);
            dofMaterial.SetTexture("_DoFTex", dof0);

//          Graphics.Blit(source, destination, dofMaterial, circleOfConfusionPass);
            Graphics.Blit(source, coc, dofMaterial,circleOfConfusionPass);
            Graphics.Blit(source, dof0, dofMaterial, preFilterPass);
            Graphics.Blit(dof0, dof1, dofMaterial, bokehPass);
            Graphics.Blit(dof1, dof0, dofMaterial, postFilterPass);
            Graphics.Blit(source, destination, dofMaterial, combinePass);

            RenderTexture.ReleaseTemporary(coc);
            RenderTexture.ReleaseTemporary(dof0);
            RenderTexture.ReleaseTemporary(dof1);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
        {
            PlayerMotion = true;
        }
        if (Input.GetKeyDown(KeyCode.D))
        {
            bscript.enabled = false;
            BlurControl = true;
        }
        if (Input.GetKeyDown(KeyCode.F))
        {
            bscript.enabled = true;
            BlurControl = false;
        }
        if (Input.GetKeyDown(KeyCode.U))
        {
            bscript.enabled = false;
            BlurControl = false;
        }


        var provider = EyetrackingProvider ?? TobiiXR.Provider;
        var gazeModifierFilter = TobiiXR.Internal.Filter as Tobii.XR.GazeModifier.GazeModifierFilter;
        var eyeTrackingData = EyeTrackingDataHelper.Clone(provider.EyeTrackingData);
        if (gazeModifierFilter != null)
            gazeModifierFilter.FilterAccuracyOnly(eyeTrackingData);
        var gazeRay = eyeTrackingData.GazeRay;
        getGazePosition(gazeRay);

        if (PlayerMotion)
        {
            saveGazeData(gazeRay, gazeX, gazeY);

            if(prevPlay != PlayerMotion)
            {
                plrScript.speed = plrSpeed;
                coaster.GetComponent<SpeedController>().enabled = true;
                prevPlay = PlayerMotion;
            }
        }
        else
        {
            if (plrScript.speed >= 0.5f)
            {
                plrSpeed = plrScript.speed;
                coaster.GetComponent<SpeedController>().enabled = false;
            }
            plrScript.speed = 0.001f;
        }
    }

    public void getGazePosition(TobiiXR_GazeRay gazeRay)
    {
        if (TobiiXR.EyeTrackingData.GazeRay.IsValid)
        {
            var rayOrigin = gazeRay.Origin;
            var rayDirection = gazeRay.Direction;
            RaycastHit hit;
            distance = defaultDistance;
            if (Physics.Raycast(gazeRay.Origin, gazeRay.Direction, out hit))
            {
                distance = hit.distance;
                focusDistance = distance;
            }
            var interpolatedGazeDirection = Vector3.Lerp(lastGazeDirection, rayDirection, 7 * Time.unscaledDeltaTime);
            var posi = rayOrigin + interpolatedGazeDirection.normalized * distance;
            Vector3 screenPos = cam.WorldToScreenPoint(posi);
            // screenPos = lowPassFilter(screenPos, lastScreenPos, 0.8f, true);
            gazeX = screenPos.x;
            gazeY = screenPos.y;
            lastGazeDirection = interpolatedGazeDirection;
            lastScreenPos = screenPos;
        }
    }

    public void saveGazeData(TobiiXR_GazeRay gazeRay, float coordX, float coordY)
    {
        /*outputWriter = new StreamWriter(pathOut, true);
        string content ="fdasfas";
        if (TobiiXR.EyeTrackingData.GazeRay.IsValid)
        {
            content = System.DateTime.Now.TimeOfDay.ToString() + " " + coaster.transform.position.x.ToString() + " " + coaster.transform.position.y.ToString() + " " + coaster.transform.position.z.ToString() + " " + coaster.transform.rotation.x.ToString() + " " + coaster.transform.rotation.y.ToString() + " " + coaster.transform.rotation.z.ToString() + " " + gazeRay.Origin.x.ToString() + " " + gazeRay.Origin.y.ToString() + " " + gazeRay.Origin.z.ToString() + " " + gazeRay.Direction.x.ToString() + " " + gazeRay.Direction.y.ToString() + " " + gazeRay.Direction.z.ToString() + " " + coordX.ToString() + " " + coordY.ToString() + " " + distance.ToString() + "\n";
        }
        else
        {
            content = System.DateTime.Now.TimeOfDay.ToString() + " " + coaster.transform.position.x.ToString() + " " + coaster.transform.position.y.ToString() + " " + coaster.transform.position.z.ToString() + " " + coaster.transform.rotation.x.ToString() + " " + coaster.transform.rotation.y.ToString() + " " + coaster.transform.rotation.z.ToString() + " -1 -1 -1 -1 -1 -1 -1 -1 -1\n";
        }
        outputWriter.Write(content);
        outputWriter.Flush();
        outputWriter.Dispose();*/
    }
}

