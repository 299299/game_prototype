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
        PlayAnimation(ctrl, animations[RandomInt(animations.length)], LAYER_MOVE, true, 0.25f);
    }

    void Update(float dt)
    {
        if (!gInput.inLeftStickInDeadZone() && gInput.isLeftStickStationary())
        {
            int index = RadialSelectAnimation(4);
            characterNode.vars["AnimationIndex"] = index;
            if (index == 0)
                ownner.stateMachine.ChangeState("MoveState");
            else
                ownner.stateMachine.ChangeState("StandToMoveState");
        }

        if (gInput.isAttackPressed()) {
            Print("Attack!!");
            ownner.stateMachine.ChangeState("AttackState");
        }
    }
};

class PlayerStandToMoveState : MultiMotionState
{
    PlayerStandToMoveState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "StandToMoveState";
        motions.Push(Motion("Animation/Stand_To_Walk_Right_90.ani", 90, 36, false, true, 1.5));
        motions.Push(Motion("Animation/Stand_To_Walk_Right_180.ani", 180, 22, false, true, 1.0));
        motions.Push(Motion("Animation/Stand_To_Walk_Left_90.ani", -90, 26, false, true, 1.5));
        // motions.Push(Motion("Animation/Stand_To_Walk_Left_180.ani", -180, 17, false, true));
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, characterNode, ctrl))
        {
            if (gInput.inLeftStickInDeadZone() && gInput.hasLeftStickBeenStationary(0.1))
                ownner.stateMachine.ChangeState("StandState");
            else {
                ctrl.SetSpeed(motions[selectIndex].name, 1);
                ownner.stateMachine.ChangeState("MoveState");
            }
        }
    }

    int PickIndex()
    {
        return characterNode.vars["AnimationIndex"].GetInt() - 1;
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
        motion.Move(dt, characterNode, ctrl);

        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > fullTurnThreashold) && gInput.isLeftStickStationary() )
        {
            Print("Turn 180!!!");
            ownner.stateMachine.ChangeState("MoveTurn180State");
        }
    }

    void Enter(State@ lastState)
    {
        PlayerStandToMoveState@ standToMoveState = cast<PlayerStandToMoveState@>(lastState);
        float startTime = 0.0f;
        float blendTime = 0.2f;
        if (standToMoveState !is null)
        {
            Array<float> startTimes = {13.0f/30.0f, 13.0f/30.0f, 2.0f/30.0f};
            startTime = startTimes[standToMoveState.selectIndex];
            blendTime = 0.25f;
        }
        else {
            PlayerMoveTurn180State@ turn180State = cast<PlayerMoveTurn180State>(lastState);
            if (turn180State !is null)
                startTime = 13.0f/30.0f;
        }
        motion.Start(characterNode, ctrl, startTime, blendTime);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motion.DebugDraw(debug, characterNode);
    }
};

class PlayerMoveTurn180State : CharacterState
{
    Motion@ motion;

    PlayerMoveTurn180State(Node@ n, Character@ c)
    {
        super(n, c);
        name = "MoveTurn180State";
        @motion = Motion("Animation/Stand_To_Walk_Right_180.ani", 180, 22, false, true, 1.0);
    }

    void Update(float dt)
    {
        if (motion.Move(dt, characterNode, ctrl))
        {
            if (gInput.inLeftStickInDeadZone() && gInput.hasLeftStickBeenStationary(0.1))
                ownner.stateMachine.ChangeState("StandState");
            else {
                ownner.stateMachine.ChangeState("MoveState");
            }
        }
    }

    void Enter(State@ lastState)
    {
        motion.Start(characterNode, ctrl, 0.0f, 0.1f);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motion.DebugDraw(debug, characterNode);
    }
};

class PlayerAttackState : MultiMotionState
{
    PlayerAttackState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "AttackState";
        //motions.Push(Motion("Animation/Attack_Close_Forward_07.ani", 0, -1, false, false));
        //motions.Push(Motion("Animation/Attack_Close_Forward_08.ani", 0, -1, false, false));
        motions.Push(Motion("Animation/Counter_Arm_Front_01.ani", 0, -1, false, false));
        motions.Push(Motion("Animation/Counter_Arm_Front_01_TG.ani", 0, -1, false, false));
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, characterNode, ctrl))
            ownner.stateMachine.ChangeState("StandState");
    }

    int PickIndex()
    {
        return RandomInt(motions.length);
    }
};

class PlayerAlignState : CharacterAlignState
{
    PlayerAlignState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "AttackState";
    }
};

class Player : Character
{
    void Start()
    {
        stateMachine.AddState(PlayerStandState(node, this));
        stateMachine.AddState(PlayerStandToMoveState(node, this));
        stateMachine.AddState(PlayerMoveState(node, this));
        stateMachine.AddState(PlayerMoveTurn180State(node, this));
        stateMachine.AddState(PlayerAttackState(node, this));
        stateMachine.AddState(PlayerAlignState(node, this));
        stateMachine.ChangeState("StandState");
    }

    void Update(float dt)
    {
        // Print("Player::Update " + String(dt));
        Character::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddNode(characterNode, 1.0f, false);
        debug.AddNode(characterNode.GetChild("Bip01"), 1.0f, false);
        Vector3 fwd = Vector3(0, 0, 1);
        Vector3 camDir = cameraNode.worldRotation * fwd;
        float cameraAngle = Atan2(camDir.x, camDir.z);
        Vector3 characterDir = characterNode.worldRotation * fwd;
        float characterAngle = Atan2(characterDir.x, characterDir.z);
        float targetAngle = cameraAngle + gInput.m_leftStickAngle;
        float baseLen = 2.0f;
        DebugDrawDirection(debug, characterNode, targetAngle, Color(1, 1, 0), baseLen * gInput.m_leftStickMagnitude);
        DebugDrawDirection(debug, characterNode, characterAngle, Color(1, 0, 1), baseLen);
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
int RadialSelectAnimation( int numDirections )
{
    Vector3 fwd = Vector3(0, 0, 1);
    Vector3 camDir = cameraNode.worldRotation * fwd;
    float cameraAngle = Atan2(camDir.x, camDir.z);
    Vector3 characterDir = characterNode.worldRotation * fwd;
    float characterAngle = Atan2(characterDir.x, characterDir.z);
    float directionDifference = angleDiff(gInput.m_leftStickAngle + cameraAngle - characterAngle);
    float directionVariable = Floor(directionDifference / (180 / (numDirections / 2)) + 0.5f);

    // since the range of the direction variable is [-3, 3] we need to map negative
    // values to the animation index range in our selector which is [0,7]
    if( directionVariable < 0 )
        directionVariable += numDirections;
    return int(directionVariable);
}


// computes the difference between the characters current heading and the
// heading the user wants them to go in.
float computeDifference()
{
    // if the user is not pushing the stick anywhere return.  this prevents the character from turning while stopping (which
    // looks bad - like the skid to stop animation)
    if( gInput.m_leftStickMagnitude < 0.5f )
        return 0;

    Vector3 fwd = Vector3(0, 0, 1);
    Vector3 camDir = cameraNode.worldRotation * fwd;
    float cameraAngle = Atan2(camDir.x, camDir.z);
    Vector3 characterDir = characterNode.worldRotation * fwd;
    float characterAngle = Atan2(characterDir.x, characterDir.z);

    // check the difference between the characters current heading and the desired heading from the gamepad
    return angleDiff(gInput.m_leftStickAngle + cameraAngle - characterAngle);
}
