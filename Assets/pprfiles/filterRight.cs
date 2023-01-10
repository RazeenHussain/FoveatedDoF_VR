using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class filterRight : MonoBehaviour
{

    public float BlurSize;
    public float Gauss;
    public float StDev;
    public float StDev2;
    public float Radius;
    public float Radius2;
    private Material materialGauss;

    // Creates a private material used to the effect
    void Awake()
    {
        materialGauss = new Material(Shader.Find("Hidden/shaderRight"));
    }

    // Postprocess the image
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // Set shader properties based on values from the inspector
        materialGauss.SetFloat("_BlurSize", BlurSize);
        materialGauss.SetFloat("_StDev", StDev);
        materialGauss.SetFloat("_StDev2", StDev2);
        materialGauss.SetFloat("_Gauss", Gauss);
        materialGauss.SetFloat("_Radius", Radius);
        materialGauss.SetFloat("_Radius2", Radius2);

        var temporaryTexture = RenderTexture.GetTemporary(source.width, source.height); // temporary texture only required if multiple passes in shader
        Graphics.Blit(source, temporaryTexture, materialGauss, 0); // vertical pass
        Graphics.Blit(temporaryTexture, destination, materialGauss, 1); // horizontal pass
        RenderTexture.ReleaseTemporary(temporaryTexture);

//        Graphics.Blit(source, destination, materialGauss);
    }
}