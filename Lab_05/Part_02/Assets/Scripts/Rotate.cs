using UnityEngine;

public class Rotate : MonoBehaviour
{
    public float rotate_speed = 0.5f;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(0, rotate_speed, 0);
    }
}
