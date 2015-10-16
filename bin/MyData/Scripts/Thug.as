
const String MOVEMENT_GROUP_THUG = "TG_Combat/";
const float MIN_TURN_ANGLE = 30;
float PUNCH_DIST = 0.0f;
float KICK_DIST = 0.0f;
float STEP_MAX_DIST = 0.0f;

class ThugStandState : CharacterState
{
    Array<String>   animations;
    float thinkTime;

    ThugStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_01"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_02"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_03"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_04"));
    }

    void Enter(State@ lastState)
    {
        float blendTime = 0.25f;
        if (lastState !is null)
        {
            if (lastState.nameHash == ATTACK_STATE || lastState.nameHash == TURN_STATE)
                blendTime = 5.0f;
        }
        ownner.PlayAnimation(animations[RandomInt(animations.length)], LAYER_MOVE, true, blendTime);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        thinkTime = Random(0.5f, 3.0f);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        CharacterState::Exit(nextState);
    }

    void Update(float dt)
    {
        float dist = ownner.GetTargetDistance()  - COLLISION_SAFE_DIST;
        if (dist < 0)
        {
            ownner.stateMachine.ChangeState("StepMoveState");
            return;
        }

        if (timeInState > thinkTime)
        {
            float diff = Abs(ownner.ComputeAngleDiff());
            if (diff > MIN_TURN_ANGLE)
            {
                ownner.stateMachine.ChangeState("TurnState");
                return;
            }

            if (dist > KICK_DIST + 0.5f)
            {
                // try to move to player
                String nextState = "StepMoveState";
                if (dist >= STEP_MAX_DIST + 0.5f)
                {
                   nextState = "RunState";
                }
                ownner.stateMachine.ChangeState(nextState);
                return;
            }
            else
            {
                ownner.Attack();
            }

            timeInState = 0.0f;
            thinkTime = Random(0.5f, 3.0f);
        }

        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        ownner.SetVelocity(Vector3(0, 0, 0));
        CharacterState::FixedUpdate(dt);
    }
};

class ThugStepMoveState : MultiMotionState
{
    float attackRange;

    ThugStepMoveState(Character@ c)
    {
        super(c);
        SetName("StepMoveState");
        // short step
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Forward");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Back");
        // long step
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Forward_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Back_Long");
    }

    void FixedUpdate(float dt)
    {
        if (motions[selectIndex].Move(ownner, dt))
        {
            float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
            if (dist <= attackRange)
            {
                int num = gEnemyMgr.GetNumOfEnemyInState(ATTACK_STATE);
                if (num >= MAX_NUM_OF_ATTACK)
                {
                    ownner.stateMachine.ChangeState("StandState");
                }
                else {
                    ownner.stateMachine.ChangeState("AttackState");
                }
            }
            else
                ownner.CommonStateFinishedOnGroud();
        }

        CharacterState::FixedUpdate(dt);
    }

    void Enter(State@ lastState)
    {
        int index = 0;
        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist < 0)
        {
            index = 2;
        }
        else
        {
            bool step_long = false;
            if (dist > motions[0].endDistance + 0.25f)
                step_long = true;
            if (step_long)
                index += 3;
        }

        //TODO OTHER left/back/right
        ownner.sceneNode.vars[ANIMATION_INDEX] = index;
        attackRange = Random(0.0, 6.0);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);

        MultiMotionState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        MultiMotionState::Exit(nextState);
    }
};

class ThugRunState : SingleMotionState
{
    float turnSpeed;
    float attackRange;

    ThugRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        SetMotion(MOVEMENT_GROUP_THUG + "Run_Forward_Combat");
        turnSpeed = 5.0f;
    }

    void Update(float dt)
    {
        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist <= attackRange)
        {
            int num = gEnemyMgr.GetNumOfEnemyInState(ATTACK_STATE);
            if (num >= MAX_NUM_OF_ATTACK)
            {
                ownner.stateMachine.ChangeState("StandState");
            }
            else {
                ownner.stateMachine.ChangeState("AttackState");
            }
        }

        SingleMotionState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        ownner.sceneNode.Yaw(characterDifference * turnSpeed * dt);

        // if the difference is large, then turn 180 degrees
        if (Abs(characterDifference) > FULLTURN_THRESHOLD)
        {
            ownner.stateMachine.ChangeState("TurnState");
            return;
        }

        SingleMotionState::FixedUpdate(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        attackRange = Random(0.0, 6.0);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
    }
};

class ThugCounterState : CharacterCounterState
{
    ThugCounterState(Character@ c)
    {
        super(c);
        AddCounterMotions("TG_BM_Counter/");
    }

    void FixedUpdate(float dt)
    {
        if (state == 1)
        {
            if (currentMotion.Move(ownner, dt))
                ownner.CommonStateFinishedOnGroud();
        }
        CharacterCounterState::FixedUpdate(dt);
    }

    void OnAnimationTrigger(AnimationState@ animState, const StringHash&in data)
    {
        if (data == RAGDOLL_START) {
            ownner.stateMachine.ChangeState("RagdollState");
        }
    }
};


class ThugAttackState : CharacterState
{
    AttackMotion@               currentAttack;
    Array<AttackMotion@>        attacks;
    int                         state;
    float                       turnSpeed;

    ThugAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");
        AddAttackMotion("Attack_Punch", 23, 14);
        AddAttackMotion("Attack_Punch_01", 23, 14);
        AddAttackMotion("Attack_Punch_02", 23, 14);
        AddAttackMotion("Attack_Kick", 24, 14);
        AddAttackMotion("Attack_Kick_01", 24, 14);
        AddAttackMotion("Attack_Kick_02", 24, 14);
        turnSpeed = 1;
    }

    void AddAttackMotion(const String&in name, int impactFrame, int counterStartFrame)
    {
        attacks.Push(AttackMotion(MOVEMENT_GROUP_THUG + name, impactFrame, counterStartFrame));
    }

    void Update(float dt)
    {
        if (currentAttack is null)
            return;

        Motion@ motion = currentAttack.motion;

        float targetDistance = ownner.GetTargetDistance();
        if (motion.translateEnabled && targetDistance < COLLISION_SAFE_DIST)
            motion.translateEnabled = false;

        float t = ownner.animCtrl.GetTime(motion.animationName);
        if (state == 0)
        {
            if (t >= currentAttack.slowMotionTime.x) {
                state = 1;
                ownner.SetTimeScale(0.25f);
                ownner.AddFlag(FLAGS_COUNTER);
                ShowHint(true);
            }
        }
        else if (state == 1)
        {
            if (t >= currentAttack.slowMotionTime.y) {
                state = 2;
                ownner.SetTimeScale(1.0f);
                ownner.RemoveFlag(FLAGS_COUNTER);
                ShowHint(false);
            }
        }

        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        Motion@ motion = currentAttack.motion;
        motion.deltaRotation += characterDifference * turnSpeed * dt;

        // TODO ....
        bool finished = motion.Move(ownner, dt);
        if (finished) {
            ownner.CommonStateFinishedOnGroud();
        }

        CharacterState::FixedUpdate(dt);
    }

    void Enter(State@ lastState)
    {
        float targetDistance = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        float punchDist = attacks[0].motion.endDistance;
        Print("targetDistance=" + targetDistance + " punchDist=" + punchDist);
        int index = RandomInt(3);
        int attackType = 0;
        if (targetDistance > punchDist + 0.5f)
        {
            index += 3; // a kick attack
            attackType = 1;
        }
        ownner.sceneNode.vars[ATTACK_TYPE] = attackType;

        @currentAttack = attacks[index];
        state = 0;
        Motion@ motion = currentAttack.motion;
        motion.Start(ownner);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        CharacterState::Enter(lastState);
        Print("Thug Pick attack motion = " + motion.animationName);
    }

    void Exit(State@ nextState)
    {
        @currentAttack = null;
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK | FLAGS_COUNTER);
        ownner.SetTimeScale(1.0f);
        ShowHint(false);
        CharacterState::Exit(nextState);
    }

    void ShowHint(bool bshow)
    {
        Text@ text = ui.root.GetChild("debug", true);
        text.visible = bshow;
    }
};

class ThugHitState : MultiMotionState
{
    ThugHitState(Character@ c)
    {
        super(c);
        SetName("HitState");
        String preFix = "TG_HitReaction/";
        AddMotion(preFix + "Generic_Hit_Reaction");
        AddMotion(preFix + "HitReaction_Back_NoTurn");
        AddMotion(preFix + "HitReaction_Left");
        AddMotion(preFix + "HitReaction_Right");
        AddMotion(preFix + "Push_Reaction");
        AddMotion(preFix + "Push_Reaction_From_Back");
    }
};

class ThugTurnState : MultiMotionState
{
    float turnSpeed;
    float endTime;

    ThugTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        AddMotion(MOVEMENT_GROUP_THUG + "135_Turn_Right");
        AddMotion(MOVEMENT_GROUP_THUG + "135_Turn_Left");
    }

    void FixedUpdate(float dt)
    {
        Motion@ motion = motions[selectIndex];
        float t = ownner.animCtrl.GetTime(motion.animationName);
        float characterDifference = Abs(ownner.ComputeAngleDiff());
        if (t >= endTime || characterDifference < 5)
        {
            ownner.CommonStateFinishedOnGroud();
        }
        ownner.sceneNode.Yaw(turnSpeed * dt);
        CharacterState::FixedUpdate(dt);
    }

    void Enter(State@ lastState)
    {
        float diff = ownner.ComputeAngleDiff();
        int index = 0;
        if (diff < 0)
            index = 1;
        ownner.sceneNode.vars[ANIMATION_INDEX] = index;
        endTime = motions[index].endTime;
        turnSpeed = diff / endTime;
        Print("ThugTurnState diff=" + diff + " turnSpeed=" + turnSpeed + " time=" + motions[selectIndex].endTime);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        MultiMotionState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        MultiMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
    }
};

class ThugRedirectState : MultiMotionState
{
    ThugRedirectState(Character@ c)
    {
        super(c);
        SetName("RedirectState");
        AddMotion(MOVEMENT_GROUP_THUG + "Redirect_push_back");
        AddMotion(MOVEMENT_GROUP_THUG + "Redirect_Stumble_JK");
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        Print(name + " pick " + motions[selectIndex].animationName);
        float blendTime = 0.5f;
        motions[selectIndex].Start(ownner, 0.0f, blendTime);
    }

    int PickIndex()
    {
        return RandomInt(2);
    }
};


class ThugGetUpState : CharacterGetUpState
{
    ThugGetUpState(Character@ c)
    {
        super(c);
        String prefix = "TG_Getup/";
        animations.Push(GetAnimationName(prefix + "GetUp_Front"));
        animations.Push(GetAnimationName(prefix + "GetUp_Front_Idle"));
        animations.Push(GetAnimationName(prefix + "GetUp_Back"));
        animations.Push(GetAnimationName(prefix + "GetUp_Back_Idle"));
    }
};

class Thug : Enemy
{
    void ObjectStart()
    {
        Enemy::ObjectStart();
        stateMachine.AddState(ThugStandState(this));
        stateMachine.AddState(ThugCounterState(this));
        stateMachine.AddState(ThugHitState(this));
        stateMachine.AddState(ThugStepMoveState(this));
        stateMachine.AddState(ThugTurnState(this));
        stateMachine.AddState(ThugRunState(this));
        stateMachine.AddState(ThugRedirectState(this));
        stateMachine.AddState(ThugAttackState(this));
        stateMachine.AddState(CharacterRagdollState(this));
        stateMachine.AddState(ThugGetUpState(this));
        stateMachine.ChangeState("StandState");

        Motion@ kickMotion = gMotionMgr.FindMotion("TG_Combat/Attack_Kick");
        KICK_DIST = kickMotion.endDistance;
        Motion@ punchMotion = gMotionMgr.FindMotion("TG_Combat/Attack_Punch");
        PUNCH_DIST = punchMotion.endDistance;
        Motion@ stepMotion = gMotionMgr.FindMotion("TG_Combat/Step_Forward_Long");
        STEP_MAX_DIST = stepMotion.endDistance;
        Print("Thug kick-dist=" + KICK_DIST + " punch-dist=" + String(PUNCH_DIST) + " step-fwd-long-dis=" + STEP_MAX_DIST);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        float targetAngle = GetTargetAngle();
        float baseLen = 2.0f;
        DebugDrawDirection(debug, sceneNode, targetAngle, Color(1, 1, 0), baseLen);
    }

    void Attack()
    {
        // try to attack
        int num = gEnemyMgr.GetNumOfEnemyInState(ATTACK_STATE);
        if (num < MAX_NUM_OF_ATTACK)
            stateMachine.ChangeState("AttackState");
    }

    void Counter()
    {
    }

    void Evade()
    {
    }

    void Redirect()
    {
        stateMachine.ChangeState("RedirectState");
    }

    void CommonStateFinishedOnGroud()
    {
        stateMachine.ChangeState("StandState");
    }
};

