using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Tobii.XR;
using Tobii.G2OM;
using System.IO;
using UnityEditor;

public class readEye : MonoBehaviour
{
    public float gazeX;
    public float gazeY;
    Camera cam;
    private Material materialGauss;
    private Vector3 lastGazeDirection;
    private Vector3 lastScreenPos;
    public IEyeTrackingProvider EyetrackingProvider { get; set; }
    private float defaultDistance;
//    StreamWriter outputWriter;
//    bool recordEyeData;
    private float distance;

    // Start is called before the first frame update
    void Start()
    {
        TobiiXR.Start();
        cam = GetComponentInChildren<Camera>();
        defaultDistance = cam.farClipPlane - 10f;
//        string pathOut = "Assets/Logs/eyeData.txt";
//        FileUtil.DeleteFileOrDirectory(pathOut);
//        outputWriter = new StreamWriter(pathOut, true);
//        recordEyeData = false;
        distance = defaultDistance;
    }

    void Awake()
    {
        materialGauss = new Material(Shader.Find("Hidden/eyeShader"));
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        materialGauss.SetFloat("_centreH", gazeX);
        materialGauss.SetFloat("_centreV", gazeY);
        materialGauss.SetFloat("_FocusDistance", distance);
        Graphics.Blit(source, destination, materialGauss,0);
//        var temporaryTexture = RenderTexture.GetTemporary(source.width, source.height);
//        Graphics.Blit(source, temporaryTexture, materialGauss, 0);
//        Graphics.Blit(temporaryTexture, destination, materialGauss, 1);
//        RenderTexture.ReleaseTemporary(temporaryTexture);
    }


    // Update is called once per frame
    void Update()
    {
        var provider = EyetrackingProvider ?? TobiiXR.Provider;
        var gazeModifierFilter = TobiiXR.Internal.Filter as Tobii.XR.GazeModifier.GazeModifierFilter;
        var eyeTrackingData = EyeTrackingDataHelper.Clone(provider.EyeTrackingData);
        if (gazeModifierFilter != null)
            gazeModifierFilter.FilterAccuracyOnly(eyeTrackingData);
        var gazeRay = eyeTrackingData.GazeRay;
        getGazePosition(gazeRay);
 /*       if(Input.GetKeyDown(KeyCode.R))
        {
            recordEyeData = true;
        }
        else if (Input.GetKeyDown(KeyCode.W))
        {
            recordEyeData = false;
        }
        if (recordEyeData)
        {
            saveGazeData(gazeRay, gazeX, gazeY);
        }
*/    }

    public void getGazePosition(TobiiXR_GazeRay gazeRay)
    {
        if (TobiiXR.EyeTrackingData.GazeRay.IsValid)
        {
            var rayOrigin = gazeRay.Origin;
            var rayDirection = gazeRay.Direction;
            RaycastHit hit;
//            distance = defaultDistance;
            if (Physics.Raycast(gazeRay.Origin, gazeRay.Direction, out hit))
            {
                distance = hit.distance;
            }
            var interpolatedGazeDirection = Vector3.Lerp(lastGazeDirection, rayDirection, 7 * Time.unscaledDeltaTime);
            var posi = rayOrigin + interpolatedGazeDirection.normalized * distance;
            Vector3 screenPos = cam.WorldToScreenPoint(posi);

//            screenPos = lowPassFilter(screenPos, lastScreenPos, 0.8f, true);

            gazeX = screenPos.x;
            gazeY = screenPos.y;
            lastGazeDirection = interpolatedGazeDirection;
            lastScreenPos = screenPos;
        }
    }

/*    public void saveGazeData(TobiiXR_GazeRay gazeRay, float coordX, float coordY)
    {
        if (TobiiXR.EyeTrackingData.GazeRay.IsValid)
        {
            outputWriter.WriteLine(System.DateTime.Now.TimeOfDay.ToString() + " " + gazeRay.Origin.x.ToString() + " " + gazeRay.Origin.y.ToString() + " " + gazeRay.Origin.z.ToString() + " " + gazeRay.Direction.x.ToString() + " " + gazeRay.Direction.y.ToString() + " " + gazeRay.Direction.z.ToString() + " " + coordX.ToString() + " " + coordY.ToString() + " " + distance.ToString());
        }
        else
        {
            outputWriter.WriteLine(System.DateTime.Now.TimeOfDay.ToString());
        }
    }
    */
    Vector3 lowPassFilter(Vector3 targetValue, Vector3 intermediateValueBuf, float factor, bool init)
    {

        Vector3 intermediateValue;

        //intermediateValue needs to be initialized at the first usage.
        if (init)
        {
            intermediateValueBuf = targetValue;
        }

        intermediateValue.x = (targetValue.x * factor) + (intermediateValueBuf.x * (1.0f - factor));
        intermediateValue.y = (targetValue.y * factor) + (intermediateValueBuf.y * (1.0f - factor));
        intermediateValue.z = (targetValue.z * factor) + (intermediateValueBuf.z * (1.0f - factor));

        intermediateValueBuf = intermediateValue;

        return intermediateValue;
    }
}
