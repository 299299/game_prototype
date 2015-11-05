
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
        return;

        float dist = ownner.GetTargetDistance()  - COLLISION_SAFE_DIST;
        if (dist < -0.25f && !ownner.HasFlag(FLAGS_NO_MOVE))
        {
            ownner.ChangeState("StepMoveState");
            return;
        }

        if (timeInState > thinkTime)
        {
            float diff = Abs(ownner.ComputeAngleDiff());
            if (diff > MIN_TURN_ANGLE)
            {
                ownner.ChangeState("TurnState");
                return;
            }

            int rand_i = RandomInt(2);
            Print("rand_i=" + rand_i + " dist=" + dist);

            if (rand_i == 0)
            {
                float attack_dist = KICK_DIST + 0.5f;
                if (dist <= attack_dist)
                {
                    Print("do attack because dist <= " + attack_dist);
                    if (ownner.Attack())
                        return;
                }
            }

            if (!ownner.HasFlag(FLAGS_NO_MOVE))
            {
                // try to move to player
                String nextState = "StepMoveState";
                float run_dist = STEP_MAX_DIST + 0.5f;
                if (dist >= run_dist)
                {
                    Print("do run because dist >= " + run_dist);
                   nextState = "RunState";
                }
                ownner.ChangeState(nextState);
            }

            timeInState = 0.0f;
            thinkTime = Random(0.5f, 3.0f);
        }

        CharacterState::Update(dt);
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
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Left");
        // long step
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Forward_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Back_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Left_Long");
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(ownner, dt))
        {
            float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
            bool attack = false;

            if (dist <= attackRange && dist >= -0.5f)
            {
                if (Abs(ownner.ComputeAngleDiff()) < MIN_TURN_ANGLE)
                {
                    if (ownner.Attack())
                        return;
                }
                else
                {
                    ownner.ChangeState("TurnState");
                    return;
                }
            }
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        int index = 0;
        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist < 0)
        {
            index = ownner.RadialSelectAnimation(4);
            index = (index + 2) % 4;
        }
        else
        {
            bool step_long = false;
            if (dist > motions[0].endDistance + 0.25f)
                step_long = true;
            if (step_long)
                index += 3;
        }

        Print("ThugStepMoveState-> index = " + index);

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
    float turnSpeed = 5.0f;
    float attackRange;

    ThugRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        SetMotion(MOVEMENT_GROUP_THUG + "Run_Forward_Combat");
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        ownner.sceneNode.Yaw(characterDifference * turnSpeed * dt);

        // if the difference is large, then turn 180 degrees
        if (Abs(characterDifference) > FULLTURN_THRESHOLD)
        {
            ownner.ChangeState("TurnState");
            return;
        }

        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist <= attackRange)
        {
            if (ownner.Attack())
                return;
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        SingleMotionState::Update(dt);
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

    void Update(float dt)
    {
        if (state == 1)
        {
            if (currentMotion.Move(ownner, dt)) {
                ownner.CommonStateFinishedOnGroud();
                return;
            }
        }
        CharacterCounterState::Update(dt);
    }
};


class ThugAttackState : CharacterState
{
    AttackMotion@               currentAttack;
    Array<AttackMotion@>        attacks;
    float                       turnSpeed = 0.5f;
    bool                        doAttackCheck = false;
    Node@                       attackCheckNode;

    ThugAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");
        AddAttackMotion("Attack_Punch", 23, ATTACK_PUNCH);
        AddAttackMotion("Attack_Punch_01", 23, ATTACK_PUNCH);
        AddAttackMotion("Attack_Punch_02", 23, ATTACK_PUNCH);
        AddAttackMotion("Attack_Kick", 24, ATTACK_KICK);
        AddAttackMotion("Attack_Kick_01", 24, ATTACK_KICK);
        AddAttackMotion("Attack_Kick_02", 24, ATTACK_KICK);
    }

    void AddAttackMotion(const String&in name, int impactFrame, int type)
    {
        attacks.Push(AttackMotion(MOVEMENT_GROUP_THUG + name, impactFrame, type));
    }

    void Update(float dt)
    {
        Motion@ motion = currentAttack.motion;
        float targetDistance = ownner.GetTargetDistance();
        if (ownner.motion_translateEnabled && targetDistance < COLLISION_SAFE_DIST)
            ownner.motion_translateEnabled = false;

        float characterDifference = ownner.ComputeAngleDiff();
        ownner.motion_deltaRotation += characterDifference * turnSpeed * dt;

        if (doAttackCheck)
            AttackCollisionCheck();

        // TODO ....
        bool finished = motion.Move(ownner, dt);
        if (finished) {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        float targetDistance = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        float punchDist = attacks[0].motion.endDistance;
        Print("targetDistance=" + targetDistance + " punchDist=" + punchDist);
        int index = RandomInt(3);
        if (targetDistance > punchDist + 0.5f)
            index += 3; // a kick attack
        @currentAttack = attacks[index];
        ownner.sceneNode.vars[ATTACK_TYPE] = currentAttack.type;
        Motion@ motion = currentAttack.motion;
        motion.Start(ownner);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        doAttackCheck = false;
        CharacterState::Enter(lastState);
        Print("Thug Pick attack motion = " + motion.animationName);
    }

    void Exit(State@ nextState)
    {
        @currentAttack = null;
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK | FLAGS_COUNTER);
        ownner.SetTimeScale(1.0f);
        attackCheckNode = null;
        ShowHint(false);
        CharacterState::Exit(nextState);
    }

    void ShowHint(bool bshow)
    {
        ownner.SetHintText(bshow ? "COUNTER!!!!!!!" : ownner.sceneNode.name);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        CharacterState::OnAnimationTrigger(animState, eventData);
        StringHash name = eventData[NAME].GetStringHash();
        if (name == TIME_SCALE)
        {
            float scale = eventData[VALUE].GetFloat();
            ownner.SetTimeScale(scale);
        }
        else if (name == COUNTER_CHECK)
        {
            int value = eventData[VALUE].GetInt();
            ShowHint(value == 1);
            if (value == 1)
                ownner.AddFlag(FLAGS_COUNTER);
            else
                ownner.RemoveFlag(FLAGS_COUNTER);
        }
        else if (name == ATTACK_CHECK)
        {
            int value = eventData[VALUE].GetInt();
            bool bCheck = value == 1;
            if (doAttackCheck == bCheck)
                return;

            doAttackCheck = bCheck;
            if (value == 1)
            {
                attackCheckNode = ownner.sceneNode.GetChild(eventData[BONE].GetString(), true);
                Print("Thug AttackCheck bone=" + attackCheckNode.name);
                AttackCollisionCheck();
            }
        }
    }

    void AttackCollisionCheck()
    {
        if (attackCheckNode is null) {
            doAttackCheck = false;
            return;
        }

        Character@ target = ownner.target;
        Vector3 position = attackCheckNode.worldPosition;
        Vector3 targetPosition = target.sceneNode.worldPosition;
        Vector3 diff = targetPosition - position;
        diff.y = 0;
        float distance = diff.length;
        if (distance < ownner.attackRadius + COLLISION_RADIUS) {
            Vector3 dir = position - targetPosition;
            dir.y = 0;
            dir.Normalize();
            target.OnDamage(ownner, position, dir, ownner.attackDamage);
            ownner.OnAttackSuccess();
        }
    }
};

class ThugHitState : MultiMotionState
{
    ThugHitState(Character@ c)
    {
        super(c);
        SetName("HitState");
        String preFix = "TG_HitReaction/";
        AddMotion(preFix + "HitReaction_Right");
        AddMotion(preFix + "HitReaction_Left");
        AddMotion(preFix + "HitReaction_Back_NoTurn");
        AddMotion(preFix + "HitReaction_Back");

        AddMotion(preFix + "Push_Reaction");
        AddMotion(preFix + "Push_Reaction_From_Back");
    }

    void Update(float dt)
    {
        if (timeInState > 0.25f)
            ownner.AddFlag(FLAGS_ATTACK);
        MultiMotionState::Update(dt);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK);
        MultiMotionState::Exit(nextState);
    }

    bool CanReEntered()
    {
        return timeInState > 0.25f;
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

    void Update(float dt)
    {
        Motion@ motion = motions[selectIndex];
        float t = ownner.animCtrl.GetTime(motion.animationName);
        float characterDifference = Abs(ownner.ComputeAngleDiff());
        if (t >= endTime || characterDifference < 5)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }
        ownner.sceneNode.Yaw(turnSpeed * dt);
        CharacterState::Update(dt);
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
        motions[selectIndex].Start(ownner, 0.0f, 0.5f);
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
        AddMotion(prefix + "GetUp_Back");
        AddMotion(prefix + "GetUp_Front");
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
        DebugDrawDirection(debug, sceneNode, targetAngle, Color(1, 1, 0), 2.0f);
    }

    bool Attack()
    {
        // try to attack
        int num = gEnemyMgr.GetNumOfEnemyInState(ATTACK_STATE);
        if (num >= MAX_NUM_OF_ATTACK)
            return false;
        if (!target.CanBeAttacked())
            return false;
        stateMachine.ChangeState("AttackState");
        return true;
    }

    bool Redirect()
    {
        stateMachine.ChangeState("RedirectState");
        return true;
    }

    void CommonStateFinishedOnGroud()
    {
        stateMachine.ChangeState("StandState");
    }

    void OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        if (!CanBeAttacked())
        {
            Print("OnDamage failed because I can no be attacked " + GetName());
            return;
        }

        // health -= damage;
        if (health <= 0)
        {
            OnDead();
            health = 0;
        }
        else
        {
            Node@ attackNode = attacker.GetNode();
            float diff = ComputeAngleDiff(attackNode);
            if (weak) {
                int index = 0;
                if (diff < 0)
                    index = 1;
                if (Abs(diff) > 135)
                    index = 2 + RandomInt(2);
                sceneNode.vars[ANIMATION_INDEX] = index;
                stateMachine.ChangeState("HitState");
            }
            else {
                MakeMeRagdoll();
            }
        }
    }

    void RequestDoNotMove()
    {
        Character::RequestDoNotMove();
        StringHash nameHash = stateMachine.currentState.nameHash;
        if (nameHash == RUN_STATE || nameHash == RUN_STATE)
        {
            stateMachine.ChangeState("StandState");
            return;
        }

        if (nameHash == HIT_STATE)
        {
            // I dont know how to do ...
            // special case
            // thug.motion_translateEnabled = false;
        }
    }
};

