
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

    void Enter(State@ lastState)
    {
        ownner.GetNode().vars[ANIMATION_INDEX] = ownner.RadialSelectAnimation(4);
        MultiMotionState::Enter(lastState);
    }
};

class PlayerTurnState : MultiMotionState
{
    float       turnSpeed;
    float       targetRotation;

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
        CaculateTargetRotation();
        ownner.SetTarget(null);
        MultiMotionState::Enter(lastState);
        Motion@ motion = motions[selectIndex];
        float alignTime = motion.endTime;
        float motionTargetAngle = motion.GetFutureRotation(ownner, alignTime);
        float diff = AngleDiff(targetRotation - motionTargetAngle);
        turnSpeed = diff / alignTime;
        combatReady = true;
        Print(this.name + " motionTargetAngle=" + String(motionTargetAngle) + " targetRotation=" + targetRotation + " diff=" + diff + " turnSpeed=" + turnSpeed);
    }

    void OnMotionFinished()
    {
        ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);
        MultiMotionState::OnMotionFinished();
    }

    void CaculateTargetRotation()
    {
        targetRotation = ownner.GetTargetAngle();
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        DebugDrawDirection(debug, ownner.GetNode(), targetRotation, YELLOW, 2.0f);
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
        if (ownner.CheckDocking(6))
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
    Array<Vector3>  targetOffsets;
    int             targetMotionFlag = 0;
    float           alignTime = 0.1f;

    float           turnSpeed;
    Vector3         motionPositon;
    Vector3         targetPosition;

    int             dockBlendingMethod = 0;
    float           targetRotation;
    float           climbBaseHeight = 0;

    PlayerClimbAlignState(Character@ c)
    {
        super(c);
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += turnSpeed*dt;
        MultiMotionState::Update(dt);
    }

    void OnMotionAlignTimeOut()
    {
        if (dockBlendingMethod == 1)
        {
            turnSpeed = 0;
            ownner.motion_velocity = Vector3(0, 0, 0);

            if (targetMotionFlag != 0)
            {
                Vector3 targetPos = PickDockOutTarget();
                Motion@ m = motions[selectIndex];
                float t = m.endTime - m.dockAlignTime;
                Vector4 motionOut = m.GetKey(m.endTime);
                Vector3 tWorld = Quaternion(0, targetRotation, 0) * Vector3(motionOut.x, motionOut.y, motionOut.z) + ownner.motion_startPosition + ownner.motion_deltaPosition;
                Vector3 diff = (targetPos - tWorld) / t;
                motionPositon = tWorld;
                targetPosition = targetPos;
                Vector3 v(0, 0, 0);
                if (targetMotionFlag & kMotion_X != 0)
                    v.x = diff.x;
                if (targetMotionFlag & kMotion_Y != 0)
                    v.y = diff.y;
                if (targetMotionFlag & kMotion_Z != 0)
                    v.z = diff.z;
                ownner.motion_velocity = v;
                Print(this.name + " animation:" + m.name + " OnMotionAlignTimeOut vel=" + v.ToString());
            }

            //ownner.SetSceneTimeScale(0.0);
        }
    }

    int PickTargetMotionByHeight(State@ lastState, int numOfStandAnimations = 3)
    {
        if (lastState.nameHash == ALIGN_STATE)
            return 0;

        int index = 0, startIndex = 0;
        if (lastState.nameHash == RUN_STATE)
            startIndex = numOfStandAnimations;

        alignTime = (lastState.nameHash != RUN_STATE) ? 0.2f : 0.1f;

        float curHeight = ownner.GetNode().worldPosition.y;
        float lineHeight = ownner.dockLine.end.y;
        float minHeightDiff = 9999;

        for (int i=0; i<numOfStandAnimations; ++i)
        {
            Motion@ motion = motions[startIndex + i];
            float motionHeight = curHeight + motion.GetKey(motion.endTime).y + climbBaseHeight;
            float curHeightDiff = Abs(lineHeight - motionHeight);
            Print(this.name + " "  + motion.name + " heightDiff=" + curHeightDiff);
            if (curHeightDiff < minHeightDiff)
            {
                minHeightDiff = curHeightDiff;
                index = startIndex + i;
            }
        }

        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        return index;
    }

    Vector3 PickDockOutTarget()
    {
        return ownner.dockLine.Project(ownner.GetNode().worldPosition);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(motionPositon, 0.5f, RED, false);
        debug.AddCross(targetPosition, 0.5f, BLUE, false);
        MultiMotionState::DebugDraw(debug);
    }

    void Enter(State@ lastState)
    {
        ownner.SetPhysicsType(0);
        // ownner.SetSceneTimeScale(0);

        if (dockBlendingMethod == 1)
        {
            MultiMotionState::Enter(lastState);
            Motion@ m = motions[selectIndex];
            Vector3 v = ownner.GetNode().worldPosition;
            targetPosition = ownner.dockLine.Project(v);
            Vector3 dir = targetPosition - v;
            targetRotation = Atan2(dir.x, dir.z);
            float t = m.dockAlignTime;
            Print("FUCK + " + m.name);
            turnSpeed = AngleDiff(targetRotation - ownner.GetCharacterAngle()) / t;
            motionPositon = m.GetDockAlignPosition(ownner, targetRotation);

            v = ownner.GetNode().GetChild(m.dockAlignBoneName, true).worldPosition;
            targetPosition = ownner.dockLine.Project(v);
            targetPosition = ownner.dockLine.FixProjectPosition(targetPosition, 0.1f);

            ownner.motion_velocity = (targetPosition - motionPositon) / t;
            Print(this.name + " animation:" + m.name + " vel=" + ownner.motion_velocity.ToString());
        }
        else
        {
            if (lastState.nameHash == ALIGN_STATE)
            {
                MultiMotionState::Enter(lastState);

                if (targetMotionFlag != 0)
                {
                    Motion@ motion = motions[selectIndex];
                    Vector3 targetPos = ownner.dockLine.Project(ownner.GetNode().worldPosition);
                    float t = motion.endTime;
                    Vector3 motionPos = motion.GetFuturePosition(ownner, t);
                    Vector3 diff = targetPos - motionPos;
                    diff /= t;
                    Vector3 v(0, 0, 0);
                    if (targetMotionFlag & kMotion_X != 0)
                        v.x = diff.x;
                    if (targetMotionFlag & kMotion_Y != 0)
                        v.y = diff.y;
                    if (targetMotionFlag & kMotion_Z != 0)
                        v.z = diff.z;
                    ownner.motion_velocity = v;
                    Print(this.name + " animation:" + motion.name + " after align vel=" + v.ToString());
                }
            }
            else
            {
                selectIndex = PickIndex();
                Vector3 myPos = ownner.GetNode().worldPosition;
                Vector3 proj = ownner.dockLine.Project(myPos);
                proj.y = myPos.y;
                Vector3 dir = proj - myPos;
                float targetAngle = Atan2(dir.x, dir.z);
                Vector3 targetPos = proj + Quaternion(0, targetAngle, 0) * targetOffsets[selectIndex];

                // Run-Case
                if (selectIndex >= 3)
                {
                    float len_diff = (targetPos - myPos).length;
                    Print("state:" + this.name + " selectIndex=" + selectIndex + " len_diff=" + len_diff);
                    if (len_diff > 3)
                        selectIndex -= 3;
                    targetPos = proj + Quaternion(0, targetAngle, 0) * targetOffsets[selectIndex];
                    ownner.GetNode().vars[ANIMATION_INDEX] = selectIndex;
                }

                CharacterAlignState@ s = cast<CharacterAlignState>(ownner.FindState(ALIGN_STATE));
                String alignAnim = "";
                // walk
                if (selectIndex == 0)
                    alignAnim = ownner.walkAlignAnimation;
                s.Start(this.nameHash, targetPos,  targetAngle, alignTime, 0, alignAnim);

                ownner.ChangeStateQueue(ALIGN_STATE);
            }
        }
    }

    void Exit(State@ nextState)
    {
        ownner.SetPhysicsType(1);
        ownner.SetVelocity(Vector3(0, 0, 0));
        MultiMotionState::Exit(nextState);
    }
};

class PlayerClimbOverState : PlayerClimbAlignState
{
    Vector3 groundPos;

    PlayerClimbOverState(Character@ c)
    {
        super(c);
        SetName("ClimbOverState");
        dockBlendingMethod = 1;
    }

    void Enter(State@ lastState)
    {
        targetMotionFlag = 0;
        int index = PickTargetMotionByHeight(lastState);
        if (index == 0 || index == 3)
        {
            Vector3 myPos = ownner.GetNode().worldPosition;
            Motion@ m = motions[index];
            Vector4 motionOut = m.GetKey(m.endTime);
            Vector3 proj = ownner.dockLine.Project(myPos);
            Vector3 dir = proj - myPos;
            float targetRotation = Atan2(dir.x, dir.z);
            Vector3 futurePos = Quaternion(0, targetRotation, 0) * Vector3(0, 0, 2.0f) + proj;
            futurePos.y = myPos.y;
            Player@ p = cast<Player>(ownner);
            groundPos = p.sensor.GetGround(futurePos);
            float height = groundPos.y - myPos.y;
            if (height < 1.5f)
            {
                if (index == 0)
                    index = 6;
                else
                    index = 7;
                targetMotionFlag = kMotion_Y;
                ownner.GetNode().vars[ANIMATION_INDEX] = index;
            }
        }
        // Print(this.name + " index = " + index);
        PlayerClimbAlignState::Enter(lastState);
    }

    Vector3 PickDockOutTarget()
    {
        return groundPos;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        PlayerClimbAlignState::DebugDraw(debug);
        debug.AddCross(groundPos, 0.5f, BLUE, false);
    }

    void OnMotionFinished()
    {
        if (selectIndex == 6 || selectIndex == 7)
            PlayerClimbAlignState::OnMotionFinished();
        else
            ownner.ChangeState("FallState");
    }
};

class PlayerClimbUpState : PlayerClimbAlignState
{
    PlayerClimbUpState(Character@ c)
    {
        super(c);
        SetName("ClimbUpState");
        targetMotionFlag = kMotion_Y;
        dockBlendingMethod = 1;
    }

    void Enter(State@ lastState)
    {
        PickTargetMotionByHeight(lastState);
        PlayerClimbAlignState::Enter(lastState);
    }
};


class PlayerRailUpState : PlayerClimbAlignState
{
    PlayerRailUpState(Character@ c)
    {
        super(c);
        SetName("RailUpState");
        targetMotionFlag = kMotion_XYZ;
        dockBlendingMethod = 1;
    }

    void Enter(State@ lastState)
    {
        PickTargetMotionByHeight(lastState);
        PlayerClimbAlignState::Enter(lastState);
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("RailIdleState");
    }
};

class PlayerRailIdleState : SingleAnimationState
{
    PlayerRailIdleState(Character@ c)
    {
        super(c);
        SetName("RailIdleState");
        looped = true;
    }

    void Enter(State@ lastState)
    {
        ownner.SetVelocity(Vector3(0,0,0));
        ownner.SetPhysicsType(0);
        SingleAnimationState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.SetPhysicsType(1);
        SingleAnimationState::Exit(nextState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            Print(this.name + " Idle->Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            PlayerRailTurnState@ s = cast<PlayerRailTurnState>(ownner.FindState("RailTurnState"));
            float turnAngle = 0;
            int animIndex = 0;
            StringHash nextState;

            if (index == 0)
            {
                ownner.ChangeState("RailDownState");
                return;
            }
            else if (index == 1)
            {
                turnAngle = 90;
                animIndex = 0;
                nextState = StringHash("RailFwdIdleState");
            }
            else if (index == 2)
            {
                turnAngle = 180;
                animIndex = 0;
                nextState = StringHash("RailIdleState");
            }
            else if (index == 3)
            {
                turnAngle = -90;
                animIndex = 1;
                nextState = StringHash("RailFwdIdleState");
            }

            s.turnAngle = turnAngle;
            s.nextStateName = nextState;
            ownner.GetNode().vars[ANIMATION_INDEX] = animIndex;
            ownner.ChangeState("RailTurnState");

            return;
        }

        SingleAnimationState::Update(dt);
    }
};

class PlayerRailTurnState : PlayerTurnState
{
    float       turnAngle;
    StringHash  nextStateName;

    PlayerRailTurnState(Character@ c)
    {
        super(c);
        SetName("RailTurnState");
    }

    void Enter(State@ lastState)
    {
        PlayerTurnState::Enter(lastState);
        ownner.SetPhysicsType(0);
    }

    void Exit(State@ nextState)
    {
        PlayerTurnState::Exit(nextState);
        ownner.SetPhysicsType(1);
    }

    void CaculateTargetRotation()
    {
        targetRotation = AngleDiff(ownner.GetCharacterAngle() + turnAngle);
    }

    void OnMotionFinished()
    {
        ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);
        ownner.ChangeState(nextStateName);
    }
};

class PlayerRailFwdIdleState : SingleAnimationState
{
    PlayerRailFwdIdleState(Character@ c)
    {
        super(c);
        SetName("RailFwdIdleState");
        looped = true;
    }

    void Enter(State@ lastState)
    {
        SingleAnimationState::Enter(lastState);
        ownner.SetPhysicsType(0);
    }

    void Exit(State@ nextState)
    {
        SingleAnimationState::Exit(nextState);
        ownner.SetPhysicsType(1);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            Print(this.name + " Idle->Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            PlayerRailTurnState@ s = cast<PlayerRailTurnState>(ownner.FindState("RailTurnState"));
            float turnAngle = 0;
            int animIndex = 0;
            StringHash nextState;

            if (index == 0)
            {
                ownner.ChangeState("RailRunForwardState");
                return;
            }
            else if (index == 2)
            {
                ownner.ChangeState("RailRunTurn180State");
                return;
            }
            else if (index == 1)
            {
                turnAngle = 90;
                animIndex = 0;
                nextState = StringHash("RailIdleState");
            }
            else if (index == 3)
            {
                turnAngle = -90;
                animIndex = 1;
                nextState = StringHash("RailIdleState");
            }

            s.turnAngle = turnAngle;
            s.nextStateName = nextState;
            ownner.GetNode().vars[ANIMATION_INDEX] = animIndex;
            ownner.ChangeState("RailTurnState");

            return;
        }

        SingleAnimationState::Update(dt);
    }
};

class PlayerRailDownState : MultiMotionState
{
    Vector3 groundPos;

    PlayerRailDownState(Character@ c)
    {
        super(c);
        SetName("RailDownState");
    }

    void Enter(State@ lastState)
    {
        int animIndex = 0;
        Vector3 myPos = ownner.GetNode().worldPosition;
        Vector3 futurePos = ownner.GetNode().worldRotation * Vector3(0, 0, 2.0f) + myPos;
        Player@ p = cast<Player>(ownner);
        groundPos = p.sensor.GetGround(futurePos);
        float height = myPos.y - groundPos.y;
        if (height > 4.5f)
            animIndex = 1;

        Print(this.name + " height-diff=" + height);
        ownner.GetNode().vars[ANIMATION_INDEX] = animIndex;
        ownner.SetPhysicsType(0);
        MultiMotionState::Enter(lastState);

        if (animIndex == 0)
        {
            Motion@ m = motions[selectIndex];
            float t = m.endTime;
            Vector3 v = m.GetFuturePosition(ownner, t);
            float y_diff = groundPos.y - v.y;
            ownner.motion_velocity = Vector3(0, y_diff/t, 0);
        }
    }

    void Exit(State@ nextState)
    {
        ownner.SetPhysicsType(1);
        MultiMotionState::Exit(nextState);
    }

    void OnMotionFinished()
    {
        if (selectIndex == 0)
            MultiMotionState::OnMotionFinished();
        else
            ownner.ChangeState("FallState");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(groundPos, 0.5f, BLUE, false);
    }
};

class PlayerRailRunForwardState : SingleMotionState
{
    PlayerRailRunForwardState(Character@ c)
    {
        super(c);
        SetName("RailRunForwardState");
    }

    void Enter(State@ lastState)
    {
        Print("Enter RailRunForwardState");
        SingleMotionState::Enter(lastState);
        ownner.SetPhysicsType(0);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.SetPhysicsType(1);
    }

    void Update(float dt)
    {
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("RailFwdIdleState");
            return;
        }
        float characterDifference = ownner.ComputeAngleDiff();
        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            ownner.ChangeState("RailRunTurn180State");
            return;
        }

        Vector3 facePoint;
        if (ownner.dockLine.GetHead(ownner.GetNode().worldRotation) == 0)
            facePoint = ownner.dockLine.end;
        else
            facePoint = ownner.dockLine.ray.origin;

        float dist_sqr = (ownner.GetNode().worldPosition - facePoint).lengthSquared;
        float max_dist = 1.0f;

        if (dist_sqr < max_dist * max_dist)
        {
            ownner.ChangeState("RailDownState");
            return;
        }

        SingleMotionState::Update(dt);
    }
};

class PlayerRailTurn180State : SingleMotionState
{
    Vector3 targetPosition;
    float targetRotation;
    float turnSpeed;

    PlayerRailTurn180State(Character@ c)
    {
        super(c);
        SetName("RailRunTurn180State");
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetPhysicsType(0);
        targetRotation = AngleDiff(ownner.GetCharacterAngle() + 180);
        float alignTime = motion.endTime;
        float motionTargetAngle = motion.GetFutureRotation(ownner, alignTime);
        Vector3 motionPos = motion.GetFuturePosition(ownner, alignTime);
        targetPosition = ownner.dockLine.Project(motionPos);
        motionPos.y = targetPosition.y;
        ownner.motion_velocity = (targetPosition - motionPos) / alignTime;

        float diff = AngleDiff(targetRotation - motionTargetAngle);
        turnSpeed = diff / alignTime;
        combatReady = true;
        Print(this.name + " motionTargetAngle=" + String(motionTargetAngle) + " targetRotation=" + targetRotation + " diff=" + diff + " turnSpeed=" + turnSpeed);
        SingleMotionState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.SetPhysicsType(1);
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += turnSpeed * dt;
        SingleMotionState::Update(dt);
    }

    void OnMotionFinished()
    {
        ownner.GetNode().worldPosition = targetPosition;
        ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);
        ownner.ChangeState("RailRunForwardState");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        DebugDrawDirection(debug, ownner.GetNode(), targetRotation, YELLOW, 2.0f);
        debug.AddCross(targetPosition, 0.5f, RED, false);
    }
};

class PlayerHangUpState : PlayerClimbAlignState
{
    PlayerHangUpState(Character@ c)
    {
        super(c);
        SetName("HangUpState");
        climbBaseHeight = 3.0f;
        dockBlendingMethod = 1;
    }

    void Enter(State@ lastState)
    {
        PickTargetMotionByHeight(lastState, 2);
        PlayerClimbAlignState::Enter(lastState);
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("HangIdleState");
    }
};

class PlayerHangIdleState : SingleAnimationState
{
    PlayerHangIdleState(Character@ c)
    {
        super(c);
        SetName("HangIdleState");
        looped = true;
    }

    void Enter(State@ lastState)
    {
        ownner.SetVelocity(Vector3(0,0,0));
        ownner.SetPhysicsType(0);
        ownner.PlayAnimation(animation, LAYER_MOVE, looped, 0.2f, 1.0f, 0.0f);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.SetPhysicsType(1);
        SingleAnimationState::Exit(nextState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            Print(this.name + " Idle->Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            if (index == 0)
            {
                ownner.ChangeState("HangOverState");
            }
            else
            {

            }

            return;
        }

        SingleAnimationState::Update(dt);
    }
};

class PlayerHangOverState : MultiMotionState
{
    PlayerHangOverState(Character@ ownner)
    {
        super(ownner);
        SetName("HangOverState");
    }
};

class PlayerHangLeftState : MultiMotionState
{
    PlayerHangLeftState(Character@ ownner)
    {
        super(ownner);
        SetName("HangLeftState");
    }
};

class PlayerHangRightState : MultiMotionState
{
    PlayerHangRightState(Character@ ownner)
    {
        super(ownner);
        SetName("HangLeftState");
    }
};