using UnityEngine;

public class Bullet : MonoBehaviour
{
    public float speed = 15;

    private Vector3 dir = new Vector3(0.0f, -1.0f, 0.0f);

    private Material mat;
    private int BrightnessID;

    void Start()
    {
        mat = GetComponent<Renderer>().material;
        BrightnessID = Shader.PropertyToID("Brightness");
    }

    void Update()
    {
        if(gameObject.activeSelf)
        {
            transform.Translate(dir * speed * Time.deltaTime);

            const float kFadeDistance = 15.0f;
            const float kDieDistance = 23.0f;

            float fade = Mathf.Clamp01((1.0f / (kDieDistance - kFadeDistance)) * Mathf.Abs(gameObject.transform.position.z - kDieDistance));

            mat.SetFloat(BrightnessID, fade);

            if (gameObject.transform.position.z > kDieDistance)
            {
                gameObject.SetActive(false);
            }
        }
    }
}
