using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerController : MonoBehaviour
{
    private InputSystem_Actions controls;
    private Rigidbody rb;
    private float movementX;

    public float speed = 4500f;

    private float introTimer = 0;

    void Awake()
    {
        controls = new InputSystem_Actions();
        rb = GetComponent<Rigidbody>();
    }

    void OnEnable()
    {
        controls.Player.Enable();
    }

    void Update()
    {
    }

    void FixedUpdate()
    {
        if (introTimer < 1.2f)
        {
            introTimer += Time.fixedDeltaTime;
        }
        else
        {
            Vector2 movementVector = controls.Player.Move.ReadValue<Vector2>();
            float movementX = movementVector.x;
            rb.AddForce(Vector3.right * movementVector * speed * Time.fixedDeltaTime);
        }

        rb.linearVelocity = new Vector3( Mathf.Clamp(rb.linearVelocity.x, -10f, 10f), 0, 0 );
    }

    void LateUpdate()
    {
        Vector3 pos = rb.position;
        pos.x = Mathf.Clamp(pos.x, -9f, 9f);

        if (pos.x == 9f || pos.x == -9f)
        {
            rb.linearVelocity = new Vector3(0f, rb.linearVelocity.y, rb.linearVelocity.z);
        }


        rb.position = pos;
    }
}