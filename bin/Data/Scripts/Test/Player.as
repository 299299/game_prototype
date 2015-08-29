#include "Scripts/Test/Character.as"

class PlayerStandState : CharacterState
{
    Array<String>           animations;

    PlayerStandState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "StandState";
        animations.Push("Animation/Stand_Idle.ani");
        animations.Push("Animation/Stand_Idle_01.ani");
        animations.Push("Animation/Stand_Idle_02.ani");
    }

    void Enter(State@ lastState)
    {
        if (ctrl !is null)
            ctrl.PlayExclusive(animations[RandomInt(animations.length)], 0, true, 0.1);
    }

    void Update(float dt)
    {
        if (!gInput.inLeftStickInDeadZone() && gInput.isLeftStickStationary())
            ownner.stateMachine.ChangeState("MoveState");
    }
};

class PlayerStandToMoveState : CharacterState
{
    Motion@ motion;

    PlayerStandToMoveState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "StandToMoveState";
        @motion = Motion("Animation/Stand_To_Walk_Left_90.ani", -90, 26, false, true);
    }

    void Update(float dt)
    {
        if (motion.Move(dt, characterNode))
            ownner.stateMachine.ChangeState("StandState");
    }

    void Enter(State@ lastState)
    {
        if (ctrl !is null)
            ctrl.PlayExclusive("Animation/Stand_To_Walk_Left_90.ani", 0, false, 0.1);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motion.DebugDraw(debug, characterNode);
    }
};

class PlayerMoveState : CharacterState
{
    Motion@ motion;

    PlayerMoveState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "MoveState";
        @motion = Motion("Animation/Walk_Forward.ani", 0, -1, true, false);
    }

    void Update(float dt)
    {
        // check if we should return to the idle state
        if (gInput.inLeftStickInDeadZone() && gInput.hasLeftStickBeenStationary(0.1))
            ownner.stateMachine.ChangeState("StandState");

        // compute the difference between the direction the character is facing
        // and the direction the user wants to go in
        float characterDifference = computeDifference();

        // if the difference is greater than this about, turn the character
        float fullTurnThreashold = 115;
        float turnSpeed = 5;

        characterNode.Yaw(characterDifference * turnSpeed * dt);

        motion.Move(dt, characterNode);
    }

    void Enter(State@ lastState)
    {
        motion.Start(characterNode);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motion.DebugDraw(debug, characterNode);
    }
};

class Player : Character
{
    void Start()
    {
        stateMachine.AddState(PlayerStandState(node, this));
        stateMachine.AddState(PlayerStandToMoveState(node, this));
        stateMachine.AddState(PlayerMoveState(node, this));
        stateMachine.ChangeState("StandState");
    }

    void Update(float dt)
    {
        Character::Update(dt);
    }
};


// clamps an angle to the rangle of [-2PI, 2PI]
float angleDiff( float diff )
{
    if (diff > 180)
        diff = diff - 360;
    if (diff < -180)
        diff = diff + 360;
    return diff;
}

//  divides a circle into numSlices and returns the index (in clockwise order) of the slice which
//  contains the gamepad's angle relative to the camera.
int RadialSelectAnimation( int numSlices )
{
    Vector3 fwd = Vector3(0, 0, 1);
    Vector3 camDir = cameraNode.worldRotation * fwd;
    float cameraAngle = Atan2(camDir.x, camDir.z);
    Vector3 characterDir = characterNode.worldRotation * fwd;
    float characterAngle = Atan2(characterDir.x, characterDir.z);

    // compute the angle that the character wants to go relative to the camera
    float angle = cameraAngle + gInput.m_leftStickAngle + characterAngle + (360 / (numSlices * numSlices) );

    // map the angle into the range 0 to 2 pi
    if ( angle < 0 )
        angle = angle + 360;
    else
        angle = angle - 360 * Floor( angle / 360 );

    // select the segement that points in that direction
    return int(Floor(angle / 360 * numSlices ));
}


// computes the difference between the characters current heading and the
// heading the user wants them to go in.
float computeDifference()
{
    // if the user is not pushing the stick anywhere return.  this prevents the character from turning while stopping (which
    // looks bad - like the skid to stop animation)
    //if( gInput.m_leftStickMagnitude < 0.5f )
    //    return 0;

    Vector3 fwd = Vector3(0, 0, 1);
    Vector3 camDir = cameraNode.worldRotation * fwd;
    float cameraAngle = Atan2(camDir.x, camDir.z);
    Vector3 characterDir = characterNode.worldRotation * fwd;
    float characterAngle = Atan2(characterDir.x, characterDir.z);

    // check the difference between the characters current heading and the desired heading from the gamepad
    return angleDiff(gInput.m_leftStickAngle + cameraAngle - characterAngle);
}
