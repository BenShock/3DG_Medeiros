using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float playerSpeed = 150f;

    private InputSystem_Actions controls;
    private Rigidbody playerRb;
    private GameObject focalPoint;
    void Awake()
    {
        controls = new InputSystem_Actions();
        playerRb = GetComponent<Rigidbody>();
        focalPoint = GameObject.Find("Focal Point");
    }


    private void OnEnable()
    {
        controls.Player.Enable();
        Debug.Log(controls.Player.Move);
    }

    private void Update()
    {
        Vector2 moveInput = controls.Player.Move.ReadValue<Vector2>();
        float forwardInput = moveInput.y;

        playerRb.AddForce(focalPoint.transform.forward * forwardInput * playerSpeed * Time.deltaTime);
    }
}
