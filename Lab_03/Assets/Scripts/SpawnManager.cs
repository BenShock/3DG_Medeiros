using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpawnManager : MonoBehaviour
{

    public GameObject enemyPrefab;
    public GameObject powerupPrefab;

    public int enemyCount;

    private float spawnRange = 9.0f;
    private int wave = 1;

    void Start()
    {
        SpawnEnemyWave(wave);
    }

    void Update()
    {
       enemyCount = FindObjectsByType<Enemy>(FindObjectsSortMode.None).Length;

        if (enemyCount == 0)
        {
            wave++;
            SpawnEnemyWave(wave);
            Instantiate(powerupPrefab, GenerateSpawnPosition(), powerupPrefab.transform.rotation);
        }
    }

    void SpawnEnemyWave(int enemiesToSpawn)
    {
        for (int i = 0; i < enemiesToSpawn; i++)
        {
            Instantiate(enemyPrefab, GenerateSpawnPosition(), enemyPrefab.transform.rotation);
        }
    }

    private Vector3 GenerateSpawnPosition()
    {
        float spawnX = Random.Range(-spawnRange, spawnRange);
        float spawnY = 0;
        float spawnZ = Random.Range(-spawnRange, spawnRange);

        return new Vector3(spawnX, spawnY, spawnZ);
    }
}
