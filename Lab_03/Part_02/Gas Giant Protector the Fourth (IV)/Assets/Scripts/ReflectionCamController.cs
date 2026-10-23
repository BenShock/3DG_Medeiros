using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Camera))]
public class ReflectionCamController : MonoBehaviour
{
    private Camera ThisCam;
    private Camera ReflectionCam;
    int XRes = 0;
    int YRes = 0;
    RenderTexture ReflectionTexture;

    private void CreateRenderTextureifNecessary()
    {
        if (XRes == ThisCam.pixelWidth && YRes == ThisCam.pixelHeight)
            return;

        if (ReflectionTexture)
            ReflectionTexture.Release();

        XRes = ThisCam.pixelWidth;
        YRes = ThisCam.pixelHeight;

        ReflectionTexture = new RenderTexture(XRes / 2, YRes / 2, 24, RenderTextureFormat.DefaultHDR);
        ReflectionCam.targetTexture = ReflectionTexture;

        Debug.LogFormat("Recreated reflection texture.\nXRes: {0}\nYRes: {1}", XRes, YRes);
    }

    void Awake()
    {
        ThisCam = GetComponent<Camera>();
        GameObject reflectionCamObj = new GameObject("ReflectionCam");
        ReflectionCam = reflectionCamObj.AddComponent<Camera>();
        reflectionCamObj.AddComponent<ReflectionCam>();
        CreateRenderTextureifNecessary();

        RenderPipelineManager.beginCameraRendering += UpdateTextures;
    }
    void OnDestroy()
    {
        RenderPipelineManager.beginCameraRendering -= UpdateTextures;
    }

    void LateUpdate()
    {
        ReflectionCam.transform.position = new Vector3(transform.position.x, -transform.position.y, transform.position.z);

        ReflectionCam.transform.rotation = Quaternion.LookRotation(
            new Vector3(transform.forward.x, -transform.forward.y, transform.forward.z),
            new Vector3(transform.up.x, -transform.up.y, transform.up.z)
        );

        Matrix4x4 projMatrix = ThisCam.projectionMatrix;

        projMatrix[0] *= -1;

        ReflectionCam.projectionMatrix = projMatrix;
    }

    // Update is called once per frame
    void UpdateTextures(ScriptableRenderContext context, Camera camera)
    {
        if (camera == ReflectionCam)
        {
            CreateRenderTextureifNecessary();
            Shader.SetGlobalTexture("gReflectionTexture", ReflectionTexture);
        }
    }
}
