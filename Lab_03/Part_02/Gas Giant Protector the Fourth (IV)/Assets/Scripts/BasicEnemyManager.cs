using UnityEngine;
using UnityEngine.EventSystems;

public class BasicEnemyManager : MonoBehaviour
{
    public GameObject enemyPrefab;
    public float spacing = 1.5f;
    public float moveSpeed = 2.0f;
    public float bounds = 10.0f;

    public int ROWS = 6;
    public int COLS = 6;
    private const float zSpawn = 14;

    private int moveDir = 1; // 1 == Right, -1 == Left
    private GameObject[][] enemies;

    private bool isMovingDown = false;
    private float targetZ = 0f;
    private const float zMoveSpeed = 1.0f;



    void Start()
    {
        enemies = new GameObject[COLS][];

        float totalWidth = (COLS - 1) * spacing;
        float startX = -totalWidth / 2f;

        for (int col = 0; col < COLS; col++)
        {
            enemies[col] = new GameObject[ROWS];

            for (int row = 0; row < ROWS; row++)
            {
                float distance = (ROWS - 1 - row) * spacing;
                float xPos = startX + (col * spacing);
                float yPos = 15.5f;
                float zPos = zSpawn - distance;

                Vector3 spawnPos = new Vector3(xPos, yPos, zPos);
                GameObject newEnemy = Instantiate(enemyPrefab, spawnPos, Quaternion.identity, this.transform);
                enemies[col][row] = newEnemy;
            }
        }
    }

    void Update()
    {
        DetectBounds();
        MoveBasicEnemies();
    }


    void DetectBounds()
    {
        bool hitBounds = false;

        for(int col = 0; col < COLS; col++)
        {
            for (int row = 0; row < ROWS; row++)
            {
                if (!enemies[col][row].activeSelf)
                {
                    continue;
                }

                if (moveDir == 1)
                {
                    if (enemies[col][row].transform.position.x >= bounds)
                    {
                        hitBounds = true;
                        break;
                    }
                }
                else if (moveDir == -1)
                {
                    if (enemies[col][row].transform.position.x <= -bounds)
                    {
                        hitBounds = true;
                        break;
                    }
                }
            }
        }

        if (hitBounds)
        {
            moveDir *= -1;

            for (int col = 0; col < COLS; col++)
            {
                if (enemies[col][0].activeSelf)
                {
                    targetZ = enemies[col][0].transform.position.z - 1.0f;
                    isMovingDown = true;
                    break;
                }
            }
        }
    }

    void MoveBasicEnemies()
    {
        for (int col = 0; col < COLS; col++)
        {
            for (int row = 0; row < ROWS; row++)
            {
                if (!enemies[col][row].activeSelf)
                {
                    continue;
                }

                Rigidbody rb = enemies[col][row].GetComponent<Rigidbody>();
                if (rb != null)
                {
                    float currentZ = rb.position.z;
                    float zVelocity = 0f;

                    if (isMovingDown)
                    {
                        if (currentZ > targetZ)
                        {
                            zVelocity = -zMoveSpeed;
                        }
                        else
                        {
                            isMovingDown = false;
                        }
                    }

                    rb.linearVelocity = new Vector3(moveDir * moveSpeed, 0, zVelocity);
                }
            }
        }
    }
}