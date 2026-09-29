using UnityEngine;

public class Rotator : MonoBehaviour
{

    void Start()
    {
        
    }

    void Update()
    {
        transform.Rotate(new Vector3(15, 30, 45) * Time.deltaTime);
    }
}
