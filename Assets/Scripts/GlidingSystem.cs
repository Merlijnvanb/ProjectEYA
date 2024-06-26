using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GlidingSystem : MonoBehaviour
{
    [SerializeField] private float MaxThrustSpeed = 25f;
    [SerializeField] private float ThrustFactor = 15f;
    [SerializeField] private float DragFactor = 5f;
    [SerializeField] private float DragCap = 5f;
    [SerializeField] private float MagnitudeLimit = 25f;
    [SerializeField] private float RotationSpeed = 5f;
    [SerializeField] private float TiltStrength = 200f;
    [SerializeField] private float LowPercent = 0.8f, HighPercent = 1f;

    [SerializeField] private Material Marcher;

    private float CurrentThrustSpeed;
    private float TiltValue, LerpValue;

    private bool isBoosting;
    private float boostFactor;

    private Transform CameraTransform;
    private Rigidbody Rb;

    void Start()
    {
        CameraTransform = Camera.main.transform.parent;
        Rb = GetComponent<Rigidbody>();
    }

    private void FixedUpdate()
    {
        GlidingMovement();

        Marcher.SetFloat("_Speed", Rb.velocity.magnitude);
        Marcher.SetFloat("_MaxSpeed", MagnitudeLimit);
        //Debug.Log(Rb.velocity.magnitude/MagnitudeLimit + "           " + Rb.velocity.magnitude);
        //Debug.Log(boostFactor);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.R))
        {
            SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
        }
        ManageRotation();
    }

    public IEnumerator BoostSequence()
    {
        boostFactor = 5f;
        isBoosting = true;

        yield return new WaitForSecondsRealtime(5f);

        while (boostFactor > 1f)
        {
            boostFactor -= .02f;
            boostFactor = Mathf.Max(1, boostFactor);
            yield return null;
        }

        isBoosting = false;
    }

    private void GlidingMovement()
    {
        float pitchInDeg = transform.eulerAngles.x % 360;
        float pitchInRads = transform.eulerAngles.x * Mathf.Deg2Rad;
        float mappedPitch = Mathf.Sin(pitchInRads) * ThrustFactor;
        float offsetMappedPitch = Mathf.Cos(pitchInRads) * DragFactor;
        float accelerationPercent = pitchInDeg >= 300f ? LowPercent : HighPercent;
        Vector3 glidingForce = Vector3.forward * CurrentThrustSpeed;

        CurrentThrustSpeed += mappedPitch * accelerationPercent * Time.deltaTime;
        CurrentThrustSpeed = Mathf.Clamp(CurrentThrustSpeed, 0, MaxThrustSpeed);

        if (isBoosting)
        {
            Rb.AddRelativeForce(glidingForce * boostFactor);
            Rb.drag = Mathf.Clamp(offsetMappedPitch / boostFactor, 0.2f, DragCap);
        }
        else
        {
            Rb.AddRelativeForce(glidingForce);
            Rb.drag = Mathf.Clamp(offsetMappedPitch, 0.2f, DragCap);
        }

        if (Rb.velocity.magnitude > MagnitudeLimit)
        {
            Vector3 currentVelocityNormalized = Rb.velocity.normalized;
            Rb.velocity = currentVelocityNormalized * MagnitudeLimit;
        }

        //Debug.Log("Magnitude: " + Rb.velocity.magnitude + "               Mapped Pitch: " + mappedPitch);
    }

    private void ManageRotation()
    {
        float mouseX = Input.GetAxis("Mouse X");
        TiltValue += mouseX * TiltStrength * Time.deltaTime;

        if (mouseX == 0)
        {
            TiltValue = Mathf.Lerp(TiltValue, 0, LerpValue);
            LerpValue += Time.deltaTime;
        }
        else
        {
            LerpValue = 0;
        }

        //Debug.Log(TiltValue);

        Quaternion targetRotation = Quaternion.Euler(CameraTransform.eulerAngles.x, CameraTransform.eulerAngles.y, Mathf.Clamp(-TiltValue, -85f, 85f));
        transform.rotation = Quaternion.Lerp(transform.rotation, targetRotation, RotationSpeed * Time.deltaTime);
    }
}