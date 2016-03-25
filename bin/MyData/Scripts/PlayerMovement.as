
class PlayerStandState : CharacterState
{
    Array<String>   animations;

    PlayerStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        ownner.PlayAnimation(animations[RandomInt(animations.length)], LAYER_MOVE, true, 0.2f, 0.0f, animSpeed);
        ownner.SetVelocity(Vector3(0,0,0));

        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

            Print("Stand->Move|Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            if (index == 0)
                ownner.ChangeState(gInput.IsRunHolding() ? "RunState" : "WalkState");
            else
                ownner.ChangeState("TurnState");

            return;
        }

        if (ownner.CheckFalling())
            return;

        if (ownner.CheckDocking())
            return;

        if (ownner.ActionCheck(true, true, true, true))
            return;

        if (timeInState > 0.25f && gInput.IsCrouchDown())
            ownner.ChangeState("CrouchState");

        CharacterState::Update(dt);
    }
};

class PlayerEvadeState : MultiMotionState
{
    PlayerEvadeState(Character@ c)
    {
        super(c);
        SetName("EvadeState");
    }
};

class PlayerTurnState : MultiMotionState
{
    float turnSpeed;

    PlayerTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        flags = FLAGS_ATTACK;
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += turnSpeed * dt;
        MultiMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        MultiMotionState::Enter(lastState);
        Motion@ motion = motions[selectIndex];
        float alignTime = motion.endTime;
        float motionTargetAngle = motion.GetFutureRotation(ownner, alignTime);
        float targetAngle = ownner.GetTargetAngle();
        float diff = AngleDiff(targetAngle - motionTargetAngle);
        turnSpeed = diff / alignTime;
        combatReady = true;
        Print("motionTargetAngle=" + String(motionTargetAngle) + " targetAngle=" + String(targetAngle) + " diff=" + String(diff) + " turnSpeed=" + String(turnSpeed));
    }
};

class PlayerWalkState : SingleMotionState
{
    float turnSpeed = 5.0f;
    int runHoldingFrames = 0;

    PlayerWalkState(Character@ c)
    {
        super(c);
        SetName("WalkState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        Node@ _node = ownner.GetNode();
        _node.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(ownner, dt);
        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            _node.vars[ANIMATION_INDEX] = 1;
            ownner.ChangeState("TurnState");
            return;
        }
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("StandState");
            return;
        }
        if (gInput.IsCrouchDown())
        {
            ownner.ChangeState("CrouchMoveState");
            return;
        }

        if (gInput.IsRunHolding())
            runHoldingFrames ++;
        else
            runHoldingFrames = 0;

        if (runHoldingFrames > 4)
        {
            ownner.ChangeState("RunState");
            return;
        }

        if (ownner.CheckFalling())
            return;
        if (ownner.CheckDocking())
            return;
        if (ownner.ActionCheck(true, true, true, true))
            return;

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetTarget(null);
        combatReady = true;
    }
};

class PlayerRunState : SingleMotionState
{
    float turnSpeed = 7.5f;
    int walkHoldingFrames = 0;
    int maxWalkHoldFrames = 4;

    PlayerRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            ownner.ChangeState("RunTurn180State");
            return;
        }

        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("RunToStandState");
            return;
        }
        if (gInput.IsCrouchDown())
        {
            ownner.ChangeState("SlideInState");
            return;
        }

        if (!gInput.IsRunHolding())
            walkHoldingFrames ++;
        else
            walkHoldingFrames = 0;

        if (walkHoldingFrames > maxWalkHoldFrames)
        {
            ownner.ChangeState("WalkState");
            return;
        }

        if (ownner.CheckFalling())
            return;
        if (ownner.CheckDocking(4))
            return;
        if (ownner.ActionCheck(true, true, true, true))
            return;

        Node@ _node = ownner.GetNode();
        _node.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(ownner, dt);

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        float blendSpeed = 0.2f;
        if (lastState.name == "RunTurn180State")
            blendSpeed = 0.01f;
        motion.Start(ownner, 0.0f, blendSpeed, animSpeed);
        ownner.SetTarget(null);
        combatReady = true;
        CharacterState::Enter(lastState);
    }
};

class PlayerRunToStandState : SingleMotionState
{
    PlayerRunToStandState(Character@ c)
    {
        super(c);
        SetName("RunToStandState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }
};

class PlayerRunTurn180State : SingleMotionState
{
    Vector3   targetPos;
    float     targetAngle;
    float     yawPerSec;
    int       state;

    PlayerRunTurn180State(Character@ c)
    {
        super(c);
        SetName("RunTurn180State");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        targetAngle = AngleDiff(ownner.GetTargetAngle());
        float alignTime = motion.endTime;
        Vector4 tFinnal = motion.GetKey(alignTime);
        Vector4 t1 = motion.GetKey(0.78f);
        float dist = Abs(t1.z - tFinnal.z);
        targetPos = ownner.GetNode().worldPosition + Quaternion(0, targetAngle, 0) * Vector3(0, 0, dist);
        float rotation = motion.GetFutureRotation(ownner, alignTime);
        yawPerSec = AngleDiff(targetAngle - rotation) / alignTime;
        Vector3 v = motion.GetFuturePosition(ownner, alignTime);
        ownner.motion_velocity = (targetPos - v) / alignTime;
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += yawPerSec * dt;
        SingleMotionState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        SingleMotionState::DebugDraw(debug);
        DebugDrawDirection(debug, ownner.GetNode(), targetAngle, Color(0.75f, 0.5f, 0.45f), 2.0f);
        debug.AddCross(targetPos, 0.5f, YELLOW, false);
    }
};


class PlayerSlideInState : SingleMotionState
{
    int state = 0;
    float slideTimer = 1.0f;
    Vector3 idleVelocity = Vector3(0, 0, 10);

    PlayerSlideInState(Character@ c)
    {
        super(c);
        SetName("SlideInState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void OnMotionFinished()
    {
        state = 1;
        timeInState = 0.0f;
    }

    void Update(float dt)
    {
        if (state == 0)
        {
            SingleMotionState::Update(dt);
        }
        else if (state == 1)
        {
            if (timeInState >= slideTimer)
            {
                int index = 0;
                if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary() && gInput.IsRunHolding())
                {
                    index = 1;
                }
                ownner.GetNode().vars[ANIMATION_INDEX] = index;
                ownner.ChangeState("SlideOutState");
                return;
            }
            if (ownner.physicsType == 0)
            {
                Vector3 oldPos = ownner.GetNode().worldPosition;
                oldPos += (ownner.GetNode().worldRotation * idleVelocity * dt);
                ownner.MoveTo(oldPos, dt);
            }
            else
                ownner.SetVelocity(ownner.GetNode().worldRotation * idleVelocity);

            CharacterState::Update(dt);
        }
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.SetHeight(CHARACTER_HEIGHT);
    }
};

class PlayerSlideOutState : MultiMotionState
{
    PlayerSlideOutState(Character@ c)
    {
        super(c);
        SetName("SlideOutState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void OnMotionFinished()
    {
        if (selectIndex == 1)
        {
            ownner.ChangeState("RunState");
            return;
        }
        MultiMotionState::OnMotionFinished();
    }
};

class PlayerCrouchState : SingleAnimationState
{
    PlayerCrouchState(Character@ c)
    {
        super(c);
        SetName("CrouchState");
        flags = FLAGS_ATTACK;
        looped = true;
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        ownner.SetVelocity(Vector3(0,0,0));
        ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
        SingleAnimationState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        SingleAnimationState::Exit(nextState);
        ownner.SetHeight(CHARACTER_HEIGHT);
    }

    void Update(float dt)
    {
        if (timeInState > 0.25f && !gInput.IsCrouchDown())
        {
            ownner.ChangeState("StandState");
            return;
        }
        if (ownner.CheckFalling())
            return;

        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

            Print("Crouch->Move|Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            if (index == 0)
                ownner.ChangeState("CrouchMoveState");
            else
                ownner.ChangeState("CrouchTurnState");
        }

        SingleAnimationState::Update(dt);
    }
};

class PlayerCrouchTurnState : PlayerTurnState
{
    PlayerCrouchTurnState(Character@ c)
    {
        super(c);
        SetName("CrouchTurnState");
    }

    void Enter(State@ lastState)
    {
        PlayerTurnState::Enter(lastState);
        ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
    }

    void Exit(State@ nextState)
    {
        PlayerTurnState::Exit(nextState);
        ownner.SetHeight(CHARACTER_HEIGHT);
    }
};



class PlayerCrouchMoveState : SingleMotionState
{
    float turnSpeed = 2.0f;
    PlayerCrouchMoveState(Character@ c)
    {
        super(c);
        SetName("CrouchMoveState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        Node@ _node = ownner.GetNode();
        _node.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(ownner, dt);
        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            _node.vars[ANIMATION_INDEX] = 1;
            ownner.ChangeState("CrouchTurnState");
            return;
        }

        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("CrouchState");
            return;
        }

        if (!gInput.IsCrouchDown())
        {
            ownner.ChangeState("WalkState");
            return;
        }

        if (ownner.CheckFalling())
            return;

        if (ownner.CheckDocking())
            return;

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetTarget(null);
        combatReady = true;
        ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.SetHeight(CHARACTER_HEIGHT);
    }
};


class PlayerFallState : SingleAnimationState
{
    PlayerFallState(Character@ c)
    {
        super(c);
        SetName("FallState");
        flags = FLAGS_ATTACK;
    }

    void Update(float dt)
    {
        Player@ p = cast<Player@>(ownner);
        if (p.sensor.grounded)
        {
            ownner.ChangeState("LandState");
            return;
        }
        SingleAnimationState::Update(dt);
    }

    void OnMotionFinished()
    {
    }
};

class PlayerLandState : SingleAnimationState
{
    PlayerLandState(Character@ c)
    {
        super(c);
        SetName("LandState");
        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.SetVelocity(Vector3(0, 0, 0));
        SingleAnimationState::Enter(lastState);
    }
};

class PlayerCoverState : SingleAnimationState
{
    int    state;
    float  alignTime = 0.25f;
    float  yawPerSec;
    float  startYaw;
    float  dockDirection;
    Vector3 dockPosition;
    float  yawAdjustSpeed = 15.0f;

    PlayerCoverState(Character@ c)
    {
        super(c);
        SetName("CoverState");
        looped = true;
        blendTime = alignTime;
    }

    void Enter(State@ lastState)
    {
        ownner.SetVelocity(Vector3(0, 0, 0));

        Line@ l = ownner.dockLine;
        Vector3 proj = l.Project(ownner.GetNode().worldPosition);
        dockPosition = proj;

        if (!lastState.name.StartsWith("Cover"))
        {
            alignTime = 0.4f;

            float to_start = (proj - l.ray.origin).lengthSquared;
            float to_end = (proj - l.end).lengthSquared;
            float min_dist_sqr = COLLISION_RADIUS * COLLISION_RADIUS;
            int head = l.GetHead(ownner.GetNode().worldRotation);

            Vector3 dir;
            if (head == 1)
            {
                dir = l.ray.origin - l.end;
                if (to_start < min_dist_sqr)
                    dockPosition = l.ray.origin - dir.Normalized() * COLLISION_RADIUS;
                else if (to_end < min_dist_sqr)
                    dockPosition = l.end + dir.Normalized() * COLLISION_RADIUS;
            }
            else
            {
                dir = l.end - l.ray.origin;
                if (to_start < min_dist_sqr)
                    dockPosition = l.ray.origin + dir.Normalized() * COLLISION_RADIUS;
                else if (to_end < min_dist_sqr)
                   dockPosition = l.end - dir.Normalized() * COLLISION_RADIUS;
            }
            dockDirection = Atan2(dir.x, dir.z);
        }
        else
        {
            alignTime = 0.1f;
            dockDirection = l.GetHeadDirection(ownner.GetNode().worldRotation);
        }

        dockPosition.y = ownner.GetNode().worldPosition.y;
        Vector3 diff = dockPosition - ownner.GetNode().worldPosition;
        ownner.SetVelocity(diff / alignTime);
        startYaw = AngleDiff(ownner.GetNode().worldRotation.eulerAngles.y);
        yawPerSec = AngleDiff(dockDirection - startYaw) / alignTime;
        state = 0;

        SingleAnimationState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        SingleAnimationState::Exit(nextState);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(dockPosition, 0.5f, RED, false);
        DebugDrawDirection(debug, dockPosition, dockDirection, YELLOW, 2.0f);
    }

    void Update(float dt)
    {
        if (state == 0)
        {
            if (timeInState >= alignTime)
            {
                state = 1;
                ownner.SetVelocity(Vector3(0, 0, 0));
            }

            startYaw += yawPerSec * dt;
            ownner.GetNode().worldRotation = Quaternion(0, startYaw, 0);
        }
        else if (state == 1)
        {
            if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
            {
                float characterDifference = ownner.ComputeAngleDiff();
                if ( (Abs(characterDifference) > 135) && gInput.IsLeftStickStationary() )
                {
                    ownner.ChangeState("CoverTransitionState");
                    return;
                }
                else
                {
                    float faceDiff = ownner.dockLine.GetProjectFacingDir(ownner.GetNode().worldPosition, ownner.GetTargetAngle());
                    Print("CoverState faceDiff=" + faceDiff);
                    if (faceDiff > 145)
                        ownner.ChangeState("WalkState");
                    else if (faceDiff > 45)
                        ownner.ChangeState("CoverRunState");
                }
            }

            float curAngle = ownner.GetCharacterAngle();
            float diff = AngleDiff(dockDirection - curAngle);
            ownner.GetNode().Yaw(diff * yawAdjustSpeed * dt);
        }
        SingleAnimationState::Update(dt);
    }
};


class PlayerCoverRunState : SingleMotionState
{
    Vector3 dockPosition;

    PlayerCoverRunState(Character@ c)
    {
        super(c);
        SetName("CoverRunState");
        flags = FLAGS_MOVING;
    }

    void Update(float dt)
    {
        Vector3 proj = ownner.dockLine.Project(ownner.GetNode().worldPosition);
        dockPosition = proj;
        dockPosition.y = ownner.GetNode().worldPosition.y;

        if (!ownner.dockLine.IsProjectPositionInLine(proj))
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("CoverState");
            return;
        }

        float characterDifference = ownner.ComputeAngleDiff();
        if ( (Abs(characterDifference) > 135) && gInput.IsLeftStickStationary() )
        {
            ownner.ChangeState("CoverTransitionState");
            return;
        }
        else
        {
            float faceDiff = ownner.dockLine.GetProjectFacingDir(ownner.GetNode().worldPosition, ownner.GetTargetAngle());
            if (faceDiff > 145)
                ownner.ChangeState("WalkState");
        }

        SingleMotionState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(dockPosition, 0.5f, RED, false);
    }
};

class PlayerCoverTransitionState : SingleMotionState
{
    float yawPerSec;

    PlayerCoverTransitionState(Character@ c)
    {
        super(c);
        SetName("CoverTransitionState");
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += yawPerSec * dt;
        SingleMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);

        float curAngle = ownner.GetNode().worldRotation.eulerAngles.y;
        float targetAngle = AngleDiff(curAngle + 180);
        float alignTime = motion.endTime;
        float motionAngle = motion.GetFutureRotation(ownner, alignTime);
        yawPerSec = AngleDiff(targetAngle - motionAngle) / alignTime;
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("CoverState");
    }
};

class PlayerClimbAlignState : MultiMotionState
{
    float alignTime = 0.1f;
    float rotatePerSec;
    float targetAngle;
    int state = 0;
    bool adjustHeight = false;

    PlayerClimbAlignState(Character@ c)
    {
        super(c);
    }

    void Enter(State@ lastState)
    {
        ownner.SetPhysicsType(0);
        ownner.SetVelocity(Vector3(0, 0, 0));

        Vector3 myPos = ownner.GetNode().worldPosition;
        Vector3 proj = ownner.dockLine.Project(myPos);
        proj.y = myPos.y;
        Vector3 dir = proj - myPos;
        targetAngle = Atan2(dir.x, dir.z);
        float angle = ownner.GetCharacterAngle();
        float angleDiff = AngleDiff(targetAngle - angle);
        rotatePerSec = angleDiff / alignTime;
        state = 0;

        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.SetPhysicsType(1);
        ownner.SetVelocity(Vector3(0, 0, 0));
        MultiMotionState::Exit(nextState);
    }

    void StartMotion()
    {
        Start();

        if (adjustHeight)
        {
            Motion@ motion = motions[selectIndex];
            float targetHeight = ownner.dockLine.end.y + 0.2f;
            float alignTime = motion.endTime;
            Vector4 motionOut = motion.GetKey(alignTime);
            float motionHeight = motion.GetFuturePosition(ownner, alignTime).y;
            Print(name + " targetHeight=" + targetHeight + " motionHeight=" + motionHeight);
            ownner.motion_velocity = Vector3(0, (targetHeight - motionHeight) / motion.endTime, 0);
        }
    }

    void Update(float dt)
    {
        if (state == 0)
        {
            ownner.GetNode().Yaw(rotatePerSec * dt);
            if (timeInState >= alignTime)
            {
                state = 1;
                StartMotion();
            }

            CharacterState::Update(dt);
        }
        else if (state == 1)
            MultiMotionState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetAngle, RED, 4.0f);
    }
};

class PlayerClimbOverState : PlayerClimbAlignState
{
    PlayerClimbOverState(Character@ c)
    {
        super(c);
        SetName("ClimbOverState");
    }

    void Enter(State@ lastState)
    {
        int index = 0;
        if (lastState.nameHash == RUN_STATE)
            index = 1;
        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        PlayerClimbAlignState::Enter(lastState);
    }
};

class PlayerClimbUpState : PlayerClimbAlignState
{
    PlayerClimbUpState(Character@ c)
    {
        super(c);
        SetName("ClimbUpState");
        adjustHeight = true;
    }

    void Enter(State@ lastState)
    {
        int index = 0, startIndex = 0;
        if (lastState.nameHash == RUN_STATE)
            startIndex = 3;

        float curHeight = ownner.GetNode().worldPosition.y;
        float lineHeight = ownner.dockLine.end.y;

        float minHeightDiff = 9999;
        for (int i=0; i<3; ++i)
        {
            Motion@ motion = motions[startIndex + i];
            float motionHeight = curHeight + motion.GetKey(motion.endTime).y;
            float curHeightDiff = Abs(lineHeight - motionHeight);
            if (curHeightDiff < minHeightDiff)
            {
                minHeightDiff = curHeightDiff;
                index = startIndex + i;
            }
        }

        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        PlayerClimbAlignState::Enter(lastState);
    }
};
