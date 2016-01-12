// ==============================================
//
//    All Dummy Scripts but never used
//
// ==============================================

class PlayerDistractState : SingleMotionState
{
    PlayerDistractState(Character@ c)
    {
        super(c);
        SetName("DistractState");
        SetMotion("BM_Attack/CapeDistract_Close_Forward");
        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        float targetRotation = ownner.GetTargetAngle();
        ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);
        SingleMotionState::Enter(lastState);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == IMPACT)
        {
            ownner.PlaySound("Sfx/swing.ogg");

            Player@ p = cast<Player>(ownner);
            Array<Enemy@> enemies;
            p.CommonCollectEnemies(enemies, MAX_DISTRACT_DIR, MAX_DISTRACT_DIST, FLAGS_ATTACK);

            combatReady = true;

            for (uint i=0; i<enemies.length; ++i)
                enemies[i].Distract();

            return;
        }
        CharacterState::OnAnimationTrigger(animState, eventData);
    }
};

class PlayerBeatDownStartState : CharacterState
{
    Motion@     motion;

    float       alignTime = 0.2f;
    int         state = 0;
    Vector3     movePerSec;
    Vector3     targetPosition;

    PlayerBeatDownStartState(Character@ c)
    {
        super(c);
        SetName("BeatDownStartState");
        flags = FLAGS_ATTACK;
        @motion = gMotionMgr.FindMotion("BM_Combat/Into_Takedown");
    }

    void Enter(State@ lastState)
    {
        Character@ target = ownner.target;
        float angle = ownner.GetTargetAngle();
        ownner.GetNode().worldRotation = Quaternion(0, angle, 0);

        target.RequestDoNotMove();

        alignTime = 0.2f;
        Vector3 myPos = ownner.GetNode().worldPosition;
        Vector3 enemyPos = target.GetNode().worldPosition;

        float dist = COLLISION_RADIUS*2 + motion.endDistance;
        targetPosition = enemyPos + ownner.GetNode().worldRotation * Vector3(0, 0, -dist);
        movePerSec = ( targetPosition - myPos ) / alignTime;
        movePerSec.y = 0;

        state = 0;

        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        if (ownner.target !is null)
            ownner.target.RemoveFlag(FLAGS_NO_MOVE);
    }

    void Update(float dt)
    {
        if (state == 0)
        {
            ownner.MoveTo(ownner.GetNode().worldPosition + movePerSec * dt, dt);

            if (timeInState >= alignTime)
            {
                state = 1;
                motion.Start(ownner);

                Character@ target = ownner.target;
                float angle = ownner.GetTargetAngle();
                target.GetNode().worldRotation = Quaternion(0, angle + 180, 0);
                target.ChangeState("BeatDownStartState");
            }
        }
        else if (state == 1)
        {
            if (motion.Move(ownner, dt)) {
                ownner.ChangeState("BeatDownHitState");
                return;
            }
        }

        CharacterState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (ownner.target is null)
            return;
        debug.AddLine(ownner.GetNode().worldPosition, ownner.target.GetNode().worldPosition, RED, false);
        debug.AddCross(targetPosition, 1.0f, RED, false);
    }
};