using UnityEngine;
using UnityEngine.InputSystem;

public class Sphere : MonoBehaviour
{
    public Transform Camera;
    public float Speed = 5.0f;

    protected Rigidbody rb;
    protected Vector2 movementVector;

    void Start()
    {
        rb = GetComponent<Rigidbody>();
        if (Camera == null)
            Camera = UnityEngine.Camera.main.transform;
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        Vector3 right = new Vector3(Camera.right.x, 0, Camera.right.z).normalized;
        Vector3 forward = new Vector3(Camera.forward.x, 0, Camera.forward.z).normalized;
        rb.AddForce(((right * movementVector.x) + (forward * movementVector.y)) * Speed);

        //if (rb.linearVelocity.magnitude > 0.1)
        //    transform.LookAt(transform.position + new Vector3(rb.linearVelocity.x, 0, rb.linearVelocity.z), Vector3.up);
    }

    void LateUpdate()
    {
        Shader.SetGlobalVector("PlayerPos", transform.position);
    }

    void OnTriggerEnter(Collider other)
    {
        Vector3 currentScale = rb.transform.localScale;
        float posScale = 1.05f;
        float negScale = 0.75f;

        if (other.gameObject.CompareTag("PickUp"))
        {
            Vector3 roidRadius = other.gameObject.transform.localScale;
            Vector3 playerRadius = rb.transform.localScale;

            if(other.gameObject.transform.localScale.x < rb.transform.localScale.x &&
                other.gameObject.transform.localScale.y < rb.transform.localScale.y &&
                other.gameObject.transform.localScale.z < rb.transform.localScale.z)
            {
                rb.transform.localScale = new Vector3(currentScale.x * posScale, currentScale.y * posScale, currentScale.z * posScale);
                other.gameObject.SetActive(false);
            } else
            {
                rb.transform.localScale = new Vector3(currentScale.x * negScale, currentScale.y * negScale, currentScale.z * negScale);
            }
        }
    }

    void OnMove(InputValue movementValue)
    {
        movementVector = movementValue.Get<Vector2>();
    }
}
