using UnityEngine;

public class BulletManager : MonoBehaviour
{

    public GameObject bulletPrefab;
    public GameObject player;

    private Rigidbody playerRb;
    private InputSystem_Actions controls;

    public int max_bullets = 5;
    private GameObject [] bullets;


    void Start()
    {
        controls = new InputSystem_Actions();
        controls.Player.Enable();
        playerRb = player.GetComponent<Rigidbody>();

        bullets = new GameObject[max_bullets];

        for (int i = 0; i < max_bullets; i++)
        {
            Vector3 playerPos = new Vector3(playerRb.position.x, playerRb.position.y, -7.65f);
            GameObject bullet = Instantiate(bulletPrefab, playerPos, Quaternion.Euler(-90.0f, 0.0f, 0.0f), this.transform);
            bullet.SetActive(false);
            bullets[i] = bullet;
        }
    }

    void Update()
    {
        if(controls.Player.Jump.WasPressedThisFrame())
        {
            Vector3 playerPos = new Vector3(playerRb.position.x, playerRb.position.y, -7.65f);

            for (int i = 0; i < max_bullets; i++)
            {
                if (!bullets[i].activeSelf)
                {
                    bullets[i].transform.position = playerPos;
                    bullets[i].SetActive(true);
                    break;
                }
            }
        }
    }
}
