using UnityEngine;
using UnityEngine.UIElements;

public class Camera : MonoBehaviour
{
    public Transform Target;
    public float MinDist = 1.5f;
    public float MaxDist = 5.0f;
    public float MinHeight = 2.5f;

    // Update is called once per frame
    void Update()
    {
        if (Target == null) // don't do anything if we don't have a target set
            return;

        Vector3 relativePosition = Vector3.Lerp(transform.position - Target.position, new Vector3(0, MaxDist, -MaxDist), 2 * Time.deltaTime);
        float length = relativePosition.magnitude;
        relativePosition = relativePosition.normalized; // normalize it

        RaycastHit hit;

        float maxDist = MaxDist;

        if (Physics.Raycast((relativePosition * MinDist * 0.5f) + Target.position, relativePosition, out hit, MaxDist))
            maxDist = hit.distance;

        relativePosition *= Mathf.Clamp(length, MinDist, maxDist);

        transform.position = relativePosition + Target.position;
        //if (Physics.Raycast(transform.position, Vector3.down, out hit, MinHeight))
        //    transform.position = new Vector3(transform.position.x, hit.point.y + MinHeight, transform.position.z);
        transform.LookAt(Target, Vector3.up); // point camera at the target
    }
}
