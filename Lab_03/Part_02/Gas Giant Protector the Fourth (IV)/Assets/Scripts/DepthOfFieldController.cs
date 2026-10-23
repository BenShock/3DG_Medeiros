using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DepthOfFieldController : MonoBehaviour
{
    public Volume volume;

    public float FocusDistance = 40;
    public float FocalLength = 1;

    DepthOfField dof;

    void Awake()
    {
        VolumeProfile volumeProfile = volume.profile;
        if (!volumeProfile) throw new System.NullReferenceException(nameof(VolumeProfile));

        if (!volumeProfile.TryGet(out dof)) throw new System.NullReferenceException(nameof(dof));
    }

    void LateUpdate()
    {
        dof.focusDistance.Override(FocusDistance);
        dof.focalLength.Override(FocalLength);
    }
}
