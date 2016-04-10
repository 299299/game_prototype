
class PlayerStandState : MultiAnimationState
{
    PlayerStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        flags = FLAGS_ATTACK;
        looped = true;
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        ownner.SetVelocity(Vector3(0,0,0));
        MultiAnimationState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

            Print("Stand->Move|Turn index=" + index + " hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

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

        MultiAnimationState::Update(dt);
    }

    int PickIndex()
    {
        return RandomInt(animations.length);
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
        ownner.SetTarget(null);
        CaculateTargetRotation();
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
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetRotation, YELLOW, 2.0f);
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
            Print(this.name + " turn 180!!");
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
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetAngle, Color(0.75f, 0.5f, 0.45f), 2.0f);
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
    int             motionFlagAfterAlign;
    int             motionFlagBeforeAlign = kMotion_ALL;
    float           alignTime = 0.1f;

    float           turnSpeed;
    Vector3         motionPositon;
    Vector3         targetPosition;

    int             dockBlendingMethod;
    float           targetRotation;
    float           climbBaseHeight;
    float           dockInTargetBound = 0.25f;

    PlayerClimbAlignState(Character@ c)
    {
        super(c);
        physicsType = 0;
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += turnSpeed*dt;
        MultiMotionState::Update(dt);
    }

    void OnMotionAlignTimeOut()
    {
        if (dockBlendingMethod > 0)
        {
            turnSpeed = 0;
            ownner.motion_velocity = Vector3(0, 0, 0);

            if (motionFlagAfterAlign != 0)
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
                if (motionFlagAfterAlign & kMotion_X != 0)
                    v.x = diff.x;
                if (motionFlagAfterAlign & kMotion_Y != 0)
                    v.y = diff.y;
                if (motionFlagAfterAlign & kMotion_Z != 0)
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
            Motion@ m = motions[startIndex + i];
            float motionHeight = curHeight + m.maxHeight + climbBaseHeight;
            float curHeightDiff = Abs(lineHeight - motionHeight);
            Print(this.name + " "  + m.name + " maxHeight=" + m.maxHeight + " heightDiff=" + curHeightDiff);
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

    Vector3 PickDockInTarget()
    {
        Vector3 v = ownner.dockLine.Project(motionPositon);
        v = ownner.dockLine.FixProjectPosition(v, dockInTargetBound);
        return v;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(motionPositon, 0.5f, RED, false);
        debug.AddCross(targetPosition, 0.5f, BLUE, false);
        DebugDrawDirection(debug, targetPosition, targetRotation, BLUE, 2.0f);
        MultiMotionState::DebugDraw(debug);
    }

    void Enter(State@ lastState)
    {
        // ownner.SetSceneTimeScale(0);

        if (dockBlendingMethod == 1)
        {
            MultiMotionState::Enter(lastState);
            Motion@ m = motions[selectIndex];
            Vector3 v = ownner.GetNode().worldPosition;
            targetPosition = ownner.dockLine.Project(v);
            float curAngle = ownner.GetCharacterAngle();
            if (motionFlagBeforeAlign & kMotion_R == 0)
                targetRotation = curAngle;
            else
            {
                Vector3 dir = targetPosition - v;
                targetRotation = Atan2(dir.x, dir.z);
            }

            float t = m.dockAlignTime;
            turnSpeed = AngleDiff(targetRotation - curAngle) / t;
            motionPositon = m.GetDockAlignPosition(ownner, targetRotation);
            targetPosition = PickDockInTarget();

            Vector3 vel = (targetPosition - motionPositon) / t;
            Vector3 filterV = Vector3(0, 0, 0);

            if (motionFlagBeforeAlign & kMotion_X != 0)
                filterV.x = vel.x;
            if (motionFlagBeforeAlign & kMotion_Y != 0)
                filterV.y = vel.y;
            if (motionFlagBeforeAlign & kMotion_Z != 0)
                filterV.z = vel.z;

            ownner.motion_velocity = filterV;
            Print(this.name + " animation:" + m.name + " vel=" + ownner.motion_velocity.ToString());
        }
        else if (dockBlendingMethod == 2)
        {
            MultiMotionState::Enter(lastState);
        }
        else
        {
            if (lastState.nameHash == ALIGN_STATE)
            {
                MultiMotionState::Enter(lastState);

                if (motionFlagAfterAlign != 0)
                {
                    Motion@ motion = motions[selectIndex];
                    Vector3 targetPos = ownner.dockLine.Project(ownner.GetNode().worldPosition);
                    float t = motion.endTime;
                    Vector3 motionPos = motion.GetFuturePosition(ownner, t);
                    Vector3 diff = targetPos - motionPos;
                    diff /= t;
                    Vector3 v(0, 0, 0);
                    if (motionFlagAfterAlign & kMotion_X != 0)
                        v.x = diff.x;
                    if (motionFlagAfterAlign & kMotion_Y != 0)
                        v.y = diff.y;
                    if (motionFlagAfterAlign & kMotion_Z != 0)
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
        motionFlagAfterAlign = 0;
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
                motionFlagAfterAlign = kMotion_Y;
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
        motionFlagAfterAlign = kMotion_Y;
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
        motionFlagAfterAlign = kMotion_XYZ;
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
        physicsType = 0;
    }

    void Enter(State@ lastState)
    {
        ownner.SetVelocity(Vector3(0,0,0));
        SingleAnimationState::Enter(lastState);
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
        physicsType = 0;
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
        physicsType = 0;
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
        physicsType = 0;
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
        physicsType = 0;
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
        targetRotation = AngleDiff(ownner.GetCharacterAngle() + 180);
        float alignTime = motion.endTime;
        float motionTargetAngle = motion.GetFutureRotation(ownner, alignTime);
        Vector3 motionPos = motion.GetFuturePosition(ownner, alignTime);
        targetPosition = ownner.dockLine.Project(motionPos);
        motionPos.y = targetPosition.y;
        ownner.motion_velocity = (targetPosition - motionPos) / alignTime;

        float diff = AngleDiff(targetRotation - motionTargetAngle);
        turnSpeed = diff / alignTime;
        Print(this.name + " motionTargetAngle=" + String(motionTargetAngle) + " targetRotation=" + targetRotation + " diff=" + diff + " turnSpeed=" + turnSpeed);
        SingleMotionState::Enter(lastState);
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
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetRotation, YELLOW, 2.0f);
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
        physicsType = 0;
        animSpeed = 0.0f;
    }

    void Enter(State@ lastState)
    {
        ownner.SetVelocity(Vector3(0,0,0));
        ownner.PlayAnimation(animation, LAYER_MOVE, looped, 0.2f, 1.0f, animSpeed);
        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = DirectionMapToIndex(gInput.GetLeftAxisAngle(), 4); //ownner.RadialSelectAnimation(4); //DirectionMapToIndex(gInput.GetLeftAxisAngle(), 4);
            // Print(this.name + " input index=" + index);
            if (index == 0)
            {
                ownner.ChangeState("HangOverState");
            }
            else if (index == 2)
            {
                ownner.ChangeState("FallState");
            }
            else
                StartHangMove(index == 3);
        }

        SingleAnimationState::Update(dt);
    }

    void StartHangMove(bool left)
    {
        int index = left ? 0 : 3;
        PlayerHangMoveState@ s = cast<PlayerHangMoveState>(ownner.FindState("HangMoveState"));
        if (s.TestHangMove(left))
            ownner.ChangeState(s.nameHash);
    }
};

class PlayerHangOverState : MultiMotionState
{
    PlayerHangOverState(Character@ ownner)
    {
        super(ownner);
        SetName("HangOverState");
        physicsType = 0;
    }
};

class PlayerHangMoveState : PlayerClimbAlignState
{
    Vector3         r1, r2, r3;
    Vector3         linePt;
    Line@           oldLine;
    bool            drawDebug;
    int             numOfAnimations = 4;
    int             type = 0;

    PlayerHangMoveState(Character@ ownner)
    {
        super(ownner);
        SetName("HangMoveState");
        dockBlendingMethod = 1;
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("HangIdleState");
    }

    void Enter(State@ lastState)
    {
        motionFlagBeforeAlign = kMotion_XZR;
        if (type == 1)
            motionFlagBeforeAlign = kMotion_XZ;
        PlayerClimbAlignState::Enter(lastState);
        Print(this.name + " enter type = " + type);
        if (oldLine !is null)
        {
            float y_diff = ownner.dockLine.end.y - oldLine.end.y;
            Print(this.name + " dock line y diff=" + y_diff);
            ownner.motion_velocity.y = y_diff / motions[selectIndex].dockAlignTime;
        }
    }

    void Exit(State@ nextState)
    {
        @oldLine = null;
        PlayerClimbAlignState::Exit(nextState);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (drawDebug)
        {
            debug.AddCross(linePt, 0.5f, Color(0.25, 0.65, 0.35), false);
            debug.AddLine(r1, r2, Color(0.5, 0.45, 0.75), false);
            debug.AddLine(r2, r3, Color(0.5, 0.45, 0.75), false);
        }
        PlayerClimbAlignState::DebugDraw(debug);
    }

    bool TestHangMove(bool left)
    {
        int index = left ? 0 : numOfAnimations;
        Motion@ m = motions[index];
        Vector4 motionOut = m.GetKey(m.endTime);
        Node@ n = ownner.GetNode();
        Vector3 myPos = n.worldPosition;
        Vector3 futurePos = n.worldRotation * Vector3(motionOut.x, motionOut.y, motionOut.z) + myPos;
        Vector3 futureProj = ownner.dockLine.Project(futurePos);
        @oldLine = ownner.dockLine;
        drawDebug = false;

        if (!oldLine.IsProjectPositionInLine(futureProj, 0.5f))
        {
            Vector3 towardDir = left ? Vector3(-1, 0, 0) : Vector3(1, 0, 0);
            towardDir = n.worldRotation * towardDir;
            Vector3 linePt = oldLine.GetLinePoint(towardDir);
            gLineWorld.CollectCloseCrossLine(oldLine, linePt);
            if (gLineWorld.cacheLines.empty)
            {
                @oldLine = null;
                ownner.GetNode().vars[ANIMATION_INDEX] = left ? 0 : 1;
                ownner.ChangeState("HangMoveStartState");
                return false;
            }

            Print(this.name + " CollectCloseCrossLine num=" + gLineWorld.cacheLines.length);

            r1 = myPos;
            r1.y += 0.5f;

            Vector3 v = linePt - r1;
            v.y = 0;
            Vector3 dir = towardDir.Normalized();
            float len = v.length + 1.5f;
            r2 = r1 + dir * len;
            Ray ray;
            ray.Define(r1, dir);
            bool hit1 = ownner.GetScene().physicsWorld.RaycastSingle(ray, len, COLLISION_LAYER_LANDSCAPE).body !is null;
            dir = n.worldRotation * Vector3(0, 0, 1);
            dir.Normalize();
            len = 4.0f;
            r3 = r2 + dir * len;
            ray.Define(r2, dir);
            bool hit2 = ownner.GetScene().physicsWorld.RaycastSingle(ray, len, COLLISION_LAYER_LANDSCAPE).body !is null;

            Print(this.name + " hit1=" + hit1 + " hit2=" + hit2);

            Line@ bestLine = null;
            int convexIndex = 1;

            // choose lines
            for (uint i=0; i<gLineWorld.cacheLines.length; ++i)
            {
                Line@ l = gLineWorld.cacheLines[i];
                Vector3 otherProj = l.Project(myPos);
                convexIndex = l.IsProjectPositionInLine(otherProj, 0.0f) ? 2 : 1;

                if (convexIndex == 1)
                {
                    if (hit1)
                        continue;
                    if (hit2)
                        continue;

                    @bestLine = l;
                }
                else if (convexIndex == 2)
                {
                    if (!hit1)
                        continue;

                    @bestLine = l;
                }
            }

            if (bestLine is null)
            {
                @oldLine = null;
                return false;
            }

            index += convexIndex;
            ownner.AssignDockLine(bestLine);
            dockBlendingMethod = 1;
            linePt = linePt;
            drawDebug = true;
            type = 1;

            // ownner.SetSceneTimeScale(0);
        }
        else
        {
            dockBlendingMethod = 2;
            @oldLine = null;
            type = 0;
        }

        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        return true;
    }

    void StartHangJump(Line@ line, const Vector3&in linePt, bool left)
    {
        @oldLine = ownner.dockLine;
        int index = left ? 3 : 7;
        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        dockBlendingMethod = 1;
        ownner.AssignDockLine(line);
        type = 2;
        dockInTargetBound = 1.5f;
        // ownner.SetSceneTimeScale(0);
        // Vector3 newLinePoint = line.GetNearPoint(linePt);
    }
};

class PlayerHangMoveStartState : MultiAnimationState
{
    bool        searched = false;

    PlayerHangMoveStartState(Character@ c)
    {
        super(c);
        SetName("HangMoveStartState");
        physicsType = 0;
    }

    void Enter(State@ lastState)
    {
        searched = false;
        MultiAnimationState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (ownner.animCtrl.IsAtEnd(animations[selectIndex]))
        {
            bool backToIdle = true;
            if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
            {
                backToIdle = false;
            }

            if (backToIdle)
            {
                ownner.ChangeState("HangIdleState");
                return;
            }

            if (SearchLine())
                return;
        }

        CharacterState::Update(dt);
    }

    bool SearchLine()
    {
        if (searched)
            return false;

        searched = true;
        bool left = selectIndex == 0;
        Vector3 towardDir = left ? Vector3(-1, 0, 0) : Vector3(1, 0, 0);
        towardDir = ownner.GetNode().worldRotation * towardDir;
        Vector3 linePt = ownner.dockLine.GetLinePoint(towardDir);
        Line@ l = gLineWorld.FindCloseParallelLine(ownner.dockLine, linePt, 1.0f, 10.0f);
        if (l is null)
            return false;

        PlayerHangMoveState@ s = cast<PlayerHangMoveState>(ownner.FindState("HangMoveState"));
        s.StartHangJump(l, linePt, left);
        ownner.ChangeState("HangMoveState");
        return true;
    }
};

class PlayerHangMoveEndState : MultiAnimationState
{
    PlayerHangMoveEndState(Character@ c)
    {
        super(c);
        SetName("HangMoveEndState");
        physicsType = 0;
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("HangIdleState");
    }

    int PickIndex()
    {
        return RandomInt(animations.length);
    }
};


class PlayerDangleIdleState : PlayerHangIdleState
{
    PlayerDangleIdleState(Character@ c)
    {
        super(c);
        SetName("DangleIdleState");
        animSpeed = 1.0f;
    }
};

class PlayerDangleOverState : PlayerHangOverState
{
    PlayerDangleOverState(Character@ ownner)
    {
        super(ownner);
        SetName("DangleOverState");
    }
};

class PlayerDangleMoveState : PlayerHangMoveState
{
    PlayerDangleMoveState(Character@ ownner)
    {
        super(ownner);
        SetName("DangleMoveState");
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("DangleIdleState");
    }
};

class PlayerDangleMoveStartState : PlayerHangMoveStartState
{
    PlayerDangleMoveStartState(Character@ c)
    {
        super(c);
        SetName("DangleMoveStartState");
    }
};

class PlayerDangleMoveEndState : PlayerHangMoveEndState
{
    PlayerDangleMoveEndState(Character@ c)
    {
        super(c);
        SetName("DangleMoveEndState");
    }
};

class PlayerClimbDownState : PlayerClimbAlignState
{
    Vector3 groundPos;

    PlayerClimbDownState(Character@ c)
    {
        super(c);
        SetName("ClimbDownState");
        dockBlendingMethod = 2;
        motionFlagAfterAlign = kMotion_Y;
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

    void Enter(State@ lastState)
    {
        int animIndex = 0;
        if (lastState.name == "RunState")
            animIndex = 1;
        else if (lastState.name == "CrouchMoveState")
            animIndex = 2;
        ownner.GetNode().vars[ANIMATION_INDEX] = animIndex;
        PlayerClimbAlignState::Enter(lastState);
        //Vector3 myPos = ownner.GetNode().worldPosition;
        //Vector3 futurePos = ownner.GetNode().worldRotation * Vector3(0, 0, 2.0f) + myPos;
        //Player@ p = cast<Player>(ownner);
        //groundPos = p.sensor.GetGround(futurePos);
    }
};
