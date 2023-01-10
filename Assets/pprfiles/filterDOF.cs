using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class filterDOF : MonoBehaviour
{
    public float Switch;
    public float BlurSize;
    public float StDev;
    public float Radius;
    public float BlurSize2;
    public float StDev2;
    public float Radius2;
    public float ViewDepth;
    public float centreH;
    public float centreV;
    private Material materialGauss;

    [Range(0.1f, 1000f)]
    public float focusDistance = 10f;
    [Range(0.1f, 100f)]
    public float focusRange = 3f;

    // Creates a private material used to the effect
    void Awake()
    {
        materialGauss = new Material(Shader.Find("Hidden/shaderDOF"));
//        materialGauss = new Material(Shader.Find("Hidden/shaderFOVE"));
//        materialGauss = new Material(Shader.Find("Hidden/shaderDEPTH"));
//        materialGauss = new Material(Shader.Find("Hidden/shaderCOC"));
    }

    // Postprocess the image
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // Set shader properties based on values from the inspector
        materialGauss.SetFloat("_Switch", Switch);
        materialGauss.SetFloat("_BlurSize", BlurSize);
        materialGauss.SetFloat("_StDev", StDev);
        materialGauss.SetFloat("_Radius", Radius);
        materialGauss.SetFloat("_BlurSize2", BlurSize2);
        materialGauss.SetFloat("_StDev2", StDev2);
        materialGauss.SetFloat("_Radius2", Radius2);
        materialGauss.SetFloat("_ViewDepth", ViewDepth);
        materialGauss.SetFloat("_centreH", centreH);
        materialGauss.SetFloat("_centreV", centreV);

        materialGauss.SetFloat("_FocusDistance", focusDistance);
        materialGauss.SetFloat("_FocusRange", focusRange);

        var temporaryTexture = RenderTexture.GetTemporary(source.width, source.height); // temporary texture only required if multiple passes in shader
        Graphics.Blit(source, temporaryTexture, materialGauss, 0); // vertical pass
        Graphics.Blit(temporaryTexture, destination, materialGauss, 1); // horizontal pass
        RenderTexture.ReleaseTemporary(temporaryTexture);
        Graphics.Blit(source, destination, materialGauss); // vertical pass
    }
}