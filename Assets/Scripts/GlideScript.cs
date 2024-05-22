using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GlideScript : MonoBehaviour
{
    public AnimationCurve LiftCurve;
    public AnimationCurve TurnAmountCurve;
    public float DividingAngle;
    public float MaxSpeed;
    public float Acceleration = 60;
 
 
    private Rigidbody rb;
 
    public float MaxLiftThreshhold;
 
    private float CurrentAccelAmount;
    private float CurrentAccelPercent;
    private float CurrentGlideAngle;
    public float speed;
 
    private float PrevYRot = 0;
    private float turnAmount;
 
    void Start()
    {
        rb = GetComponent<Rigidbody>();
 
    }
 
 
    void Update()
    {
 
       
 
 
        CurrentGlideAngle = rb.rotation.eulerAngles.z;
 
        CurrentAccelAmount = Mathf.Cos((CurrentGlideAngle + 90) / 180 * Mathf.PI) * 180;
 
        if (CurrentAccelAmount <= 0)
        {
            CurrentAccelPercent = (CurrentAccelAmount - DividingAngle) / (180 - -DividingAngle);
        }
        if (CurrentAccelAmount > 0)
        {
            CurrentAccelPercent = -(CurrentAccelAmount - DividingAngle) / (-180 - -DividingAngle);
        }
 
 
 
        float turnAmount = TurnAmountCurve.Evaluate(Mathf.Abs(PrevYRot - transform.eulerAngles.y) * Time.deltaTime );
 
        speed = speed * turnAmount;
 
        speed += CurrentAccelPercent * Acceleration;
 
        speed = Mathf.Clamp(speed, -1000, MaxSpeed);
 
 
 
        float GliderLift = LiftCurve.Evaluate(Mathf.Abs(speed) / MaxLiftThreshhold);
        Vector3 BeforeSpeedUpdate = rb.velocity;
        rb.velocity = (speed * Time.deltaTime * transform.right) * GliderLift;
        rb.velocity += BeforeSpeedUpdate * (1 - GliderLift);
 
 
        Debug.Log("TurnAmount:"  + turnAmount +        "speed:" + Mathf.Round(speed) + "     AccelPercent:" + CurrentAccelPercent);
 
 
        PrevYRot = transform.eulerAngles.y;
 
    }
 
}
