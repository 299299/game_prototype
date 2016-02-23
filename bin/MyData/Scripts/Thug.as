// ==============================================
//
//    Thug Pawn and Controller Class
//
// ==============================================

// --- CONST
const String MOVEMENT_GROUP_THUG = "TG_Combat/";
const float MIN_TURN_ANGLE = 30;
const float MIN_THINK_TIME = 0.25f;
const float MAX_THINK_TIME = 1.0f;
const float KEEP_DIST_WITHIN_PLAYER = 20.0f;
const float MAX_ATTACK_RANGE = 3.0f;
const float KEEP_DIST = 1.5f;
const Vector3 HIT_RAGDOLL_FORCE(25.0f, 10.0f, 0.0f);

// -- NON CONST
float PUNCH_DIST = 0.0f;
float KICK_DIST = 0.0f;
float STEP_MAX_DIST = 0.0f;
float STEP_MIN_DIST = 0.0f;
float KEEP_DIST_WITH_PLAYER = -0.25f;

class ThugStandState : CharacterState
{
    Array<String>   animations;
    float           thinkTime;

    float           attackRange;

    bool            firstEnter = true;

    ThugStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_01"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_02"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_03"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_04"));
        flags = FLAGS_REDIRECTED | FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.PlayAnimation(animations[RandomInt(animations.length)], LAYER_MOVE, true, 0.2f);
        float min_think_time = MIN_THINK_TIME;
        float max_think_time = MAX_THINK_TIME;
        if (firstEnter)
        {
            min_think_time = 2.0f;
            max_think_time = 3.0f;
            firstEnter = false;
        }
        thinkTime = Random(min_think_time, max_think_time);
        if (d_log)
            Print(ownner.GetName() + " thinkTime=" + thinkTime);
        ownner.ClearAvoidance();
        attackRange = Random(0.0f, MAX_ATTACK_RANGE);
        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (freeze_ai != 0)
           return;

        float diff = Abs(ownner.ComputeAngleDiff());
        if (diff > MIN_TURN_ANGLE)
        {
            // I should always turn to look at player.
            ownner.ChangeState("TurnState");
            return;
        }

        if (timeInState > thinkTime)
        {
            OnThinkTimeOut();
            timeInState = 0.0f;
            thinkTime = Random(MIN_THINK_TIME, MAX_THINK_TIME);
        }

        CharacterState::Update(dt);
    }

    void OnThinkTimeOut()
    {
        Node@ _node = ownner.GetNode();
        EnemyManager@ em = cast<EnemyManager>(_node.scene.GetScriptObject("EnemyManager"));
        float dist = ownner.GetTargetDistance()  - COLLISION_SAFE_DIST;
        if (ownner.CanAttack() && dist <= attackRange)
        {
            Print("do attack because dist <= " + attackRange);
            if (ownner.Attack())
                return;
        }

        int rand_i = 0;
        int num_of_moving_thugs = em.GetNumOfEnemyHasFlag(FLAGS_MOVING);
        //bool can_i_see_player = !ownner.IsTargetSightBlocked();
        int num_of_with_player = em.GetNumOfEnemyWithinDistance(PLAYER_NEAR_DIST);
        if (num_of_moving_thugs < MAX_NUM_OF_MOVING && num_of_with_player <  MAX_NUM_OF_NEAR && !ownner.HasFlag(FLAGS_NO_MOVE))
        {
            // try to move to player
            rand_i = RandomInt(6);
            String nextState = "StepMoveState";
            float run_dist = STEP_MAX_DIST + 1.0f;
            if (dist >= run_dist || rand_i == 1)
            {
                nextState = "RunState";
            }
            else
            {
                ThugStepMoveState@ state = cast<ThugStepMoveState>(ownner.FindState("StepMoveState"));
                int index = state.GetStepMoveIndex();
                //Print(ownner.GetName() + " apply animation index for step move in thug stand state: " + index);
                _node.vars[ANIMATION_INDEX] = index;
            }
            ownner.ChangeState(nextState);
        }
        else
        {
            if (dist >= KEEP_DIST_WITHIN_PLAYER)
            {
                ThugStepMoveState@ state = cast<ThugStepMoveState>(ownner.FindState("StepMoveState"));
                int index = state.GetStepMoveIndex();
                //Print(ownner.GetName() + " apply animation index for keep with with player in stand state: " + index);
                _node.vars[ANIMATION_INDEX] = index;
                ownner.ChangeState("StepMoveState");
                return;
            }

            rand_i = RandomInt(10);
            if (rand_i > 8)
            {
                int index = RandomInt(4);
                _node.vars[ANIMATION_INDEX] = index;
                //Print(ownner.GetName() + " apply animation index for random move in stand state: " + index);
                ownner.ChangeState("StepMoveState");
            }
        }

        attackRange = Random(0.0f, MAX_ATTACK_RANGE);
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckAvoidance(dt);
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
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Left");
        // long step
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Forward_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Back_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Left_Long");
        flags = FLAGS_REDIRECTED | FLAGS_ATTACK | FLAGS_MOVING;

        if (STEP_MAX_DIST != 0.0f)
        {
            STEP_MIN_DIST = motions[0].endDistance;
            STEP_MAX_DIST = motions[4].endDistance;
            Print("Thug min-step-dist=" + STEP_MIN_DIST + " max-step-dist=" + STEP_MAX_DIST);
        }
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(ownner, dt))
        {
            float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
            bool attack = false;

            if (dist <= attackRange && dist >= -0.5f)
            {
                if (Abs(ownner.ComputeAngleDiff()) < MIN_TURN_ANGLE && freeze_ai == 0)
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

    int GetStepMoveIndex()
    {
        int index = 0;
        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist < KEEP_DIST_WITH_PLAYER)
        {
            index = ownner.RadialSelectAnimation(4);
            index = (index + 2) % 4;
            // Print("ThugStepMoveState->GetStepMoveIndex() Keep Dist Within Player =->" + index);
        }
        else
        {
            if (dist > motions[4].endDistance + 2.0f)
                index += 4;
            // Print("ThugStepMoveState->GetStepMoveIndex()=->" + index + " dist=" + dist);
        }
        return index;
    }

    void Enter(State@ lastState)
    {
        attackRange = Random(0.0, MAX_ATTACK_RANGE);
        MultiMotionState::Enter(lastState);
    }

    float GetThreatScore()
    {
        return 0.333f;
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
        flags = FLAGS_REDIRECTED | FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        ownner.GetNode().Yaw(characterDifference * turnSpeed * dt);

        // if the difference is large, then turn 180 degrees
        if (Abs(characterDifference) > FULLTURN_THRESHOLD)
        {
            ownner.ChangeState("TurnState");
            return;
        }

        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist <= attackRange)
        {
            if (ownner.Attack() && freeze_ai == 0)
                return;
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        SingleMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        attackRange = Random(0.0, MAX_ATTACK_RANGE);
        ownner.ClearAvoidance();
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckAvoidance(dt);
        CharacterState::FixedUpdate(dt);
    }

    float GetThreatScore()
    {
        return 0.333f;
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
        flags = FLAGS_REDIRECTED | FLAGS_ATTACK;
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
        ownner.GetNode().Yaw(turnSpeed * dt);
        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        float diff = ownner.ComputeAngleDiff();
        int index = 0;
        if (diff < 0)
            index = 1;
        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        endTime = motions[index].endTime;
        turnSpeed = diff / endTime;
        // Print("ThugTurnState diff=" + diff + " turnSpeed=" + turnSpeed + " time=" + motions[selectIndex].endTime);
        ownner.ClearAvoidance();
        MultiMotionState::Enter(lastState);
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckAvoidance(dt);
        CharacterState::FixedUpdate(dt);
    }
};


class ThugCounterState : CharacterCounterState
{
    ThugCounterState(Character@ c)
    {
        super(c);
        if (playerType == 0)
            AddBW_Counter_Animations("TG_BW_Counter/", false);
        else if (playerType == 1)
            AddCW_Counter_Animations("TG_CW_Counter/", false);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == READY_TO_FIGHT)
        {
            ownner.AddFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
            return;
        }
        CharacterCounterState::OnAnimationTrigger(animState, eventData);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
        CharacterCounterState::Exit(nextState);
    }
};


class ThugAttackState : CharacterState
{
    AttackMotion@               currentAttack;
    Array<AttackMotion@>        attacks;
    float                       turnSpeed = 1.25f;
    bool                        doAttackCheck = false;
    Node@                       attackCheckNode;

    ThugAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");
        AddAttackMotion("Attack_Punch", 23, ATTACK_PUNCH, "Bip01_R_Hand");
        AddAttackMotion("Attack_Punch_01", 23, ATTACK_PUNCH, "Bip01_R_Hand");
        AddAttackMotion("Attack_Punch_02", 23, ATTACK_PUNCH, "Bip01_R_Hand");
        AddAttackMotion("Attack_Kick", 24, ATTACK_KICK, "Bip01_L_Foot");
        AddAttackMotion("Attack_Kick_01", 24, ATTACK_KICK, "Bip01_L_Foot");
        AddAttackMotion("Attack_Kick_02", 24, ATTACK_KICK, "Bip01_L_Foot");

        if (PUNCH_DIST != 0.0f)
        {
            PUNCH_DIST = attacks[0].motion.endDistance;
            KICK_DIST = attacks[3].motion.endDistance;
            Print("Thug kick-dist=" + KICK_DIST + " punch-dist=" + PUNCH_DIST);
        }
    }

    void AddAttackMotion(const String&in name, int impactFrame, int type, const String&in bName)
    {
        attacks.Push(AttackMotion(MOVEMENT_GROUP_THUG + name, impactFrame, type, bName));
    }

    void Update(float dt)
    {
        if (firstUpdate)
        {
            if (cast<Thug>(ownner).KeepDistanceWithEnemy())
                return;
        }

        Motion@ motion = currentAttack.motion;
        ownner.CheckTargetDistance(ownner.target, COLLISION_SAFE_DIST);

        float characterDifference = ownner.ComputeAngleDiff();
        ownner.motion_deltaRotation += characterDifference * turnSpeed * dt;

        if (doAttackCheck)
            AttackCollisionCheck();

        // TODO ....
        bool finished = motion.Move(ownner, dt);
        if (finished)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        if (!ownner.target.HasFlag(FLAGS_ATTACK))
        {
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
        if (targetDistance > punchDist + 1.0f)
            index += 3; // a kick attack
        @currentAttack = attacks[index];
        ownner.GetNode().vars[ATTACK_TYPE] = currentAttack.type;
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
        ShowAttackIndicator(false);
        CharacterState::Exit(nextState);
    }

    void ShowAttackIndicator(bool bshow)
    {
        HeadIndicator@ indicator = cast<HeadIndicator>(ownner.GetNode().GetScriptObject("HeadIndicator"));
        if (indicator !is null)
            indicator.ChangeState(bshow ? STATE_INDICATOR_ATTACK : STATE_INDICATOR_HIDE);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == TIME_SCALE)
        {
            float scale = eventData[VALUE].GetFloat();
            ownner.SetTimeScale(scale);
            return;
        }
        else if (name == COUNTER_CHECK)
        {
            int value = eventData[VALUE].GetInt();
            ShowAttackIndicator(value == 1);
            if (value == 1)
                ownner.AddFlag(FLAGS_COUNTER);
            else
                ownner.RemoveFlag(FLAGS_COUNTER);
            return;
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
                attackCheckNode = ownner.GetNode().GetChild(eventData[BONE].GetString(), true);
                Print("Thug AttackCheck bone=" + attackCheckNode.name);
                AttackCollisionCheck();
            }

            return;
        }

        CharacterState::OnAnimationTrigger(animState, eventData);
        return;
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
        if (distance < ownner.attackRadius + COLLISION_RADIUS * 0.8f)
        {
            Vector3 dir = position - targetPosition;
            dir.y = 0;
            dir.Normalize();
            bool b = target.OnDamage(ownner, position, dir, ownner.attackDamage);
            if (!b)
                return;

            if (currentAttack.type == ATTACK_PUNCH)
            {
                ownner.PlaySound("Sfx/impact_10.ogg");
            }
            else
            {
                ownner.PlaySound("Sfx/impact_13.ogg");
            }
            ownner.OnAttackSuccess(target);
        }
    }

    float GetThreatScore()
    {
        return 0.75f;
    }

};

class ThugHitState : MultiMotionState
{
    float recoverTimer = 3 * SEC_PER_FRAME;

    ThugHitState(Character@ c)
    {
        super(c);
        SetName("HitState");
        String preFix = "TG_HitReaction/";
        AddMotion(preFix + "HitReaction_Right");
        AddMotion(preFix + "HitReaction_Left");
        AddMotion(preFix + "HitReaction_Back_NoTurn");
        AddMotion(preFix + "HitReaction_Back");
    }

    void Update(float dt)
    {
        if (timeInState >= recoverTimer)
            ownner.AddFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
        MultiMotionState::Update(dt);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
        MultiMotionState::Exit(nextState);
    }

    bool CanReEntered()
    {
        return timeInState >= recoverTimer;
    }

    void FixedUpdate(float dt)
    {
        Node@ _node = ownner.GetNode().GetChild("Collision");
        if (_node is null)
            return;

        RigidBody@ body = _node.GetComponent("RigidBody");
        if (body is null)
            return;

        Array<RigidBody@>@ neighbors = body.collidingBodies;
        for (uint i=0; i<neighbors.length; ++i)
        {
            Node@ n_node = neighbors[i].node.parent;
            if (n_node is null)
                continue;
            Character@ object = cast<Character>(n_node.scriptObject);
            if (object is null)
                continue;
            if (object.HasFlag(FLAGS_MOVING))
                continue;

            float dist = ownner.GetTargetDistance(n_node);
            if (dist < 1.0f)
            {
                State@ state = ownner.GetState();
                if (state.nameHash == RUN_STATE || state.nameHash == STAND_STATE)
                {
                    object.ChangeState("PushBack");
                }
            }
        }
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

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == READY_TO_FIGHT)
        {
            ownner.AddFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
            return;
        }
        CharacterGetUpState::OnAnimationTrigger(animState, eventData);
    }

    void Enter(State@ lastState)
    {
        CharacterGetUpState::Enter(lastState);
        ownner.SetNodeEnabled("Collision", true);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
        CharacterGetUpState::Exit(nextState);
    }
};

class ThugDeadState : CharacterState
{
    float  duration = 5.0f;

    ThugDeadState(Character@ c)
    {
        super(c);
        SetName("DeadState");
    }

    void Enter(State@ lastState)
    {
        Print(ownner.GetName() + " Entering ThugDeadState");
        ownner.SetNodeEnabled("Collision", false);
        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        duration -= dt;
        if (duration <= 0)
        {
            if (!ownner.IsVisible())
                ownner.duration = 0;
            else
                duration = 0;
        }
    }
};

class ThugBeatDownHitState : MultiMotionState
{
    ThugBeatDownHitState(Character@ c)
    {
        super(c);
        SetName("BeatDownHitState");
        if (playerType == 0)
        {
            String preFix = "TG_BM_Beatdown/";
            AddMotion(preFix + "Beatdown_HitReaction_01");
            AddMotion(preFix + "Beatdown_HitReaction_02");
            AddMotion(preFix + "Beatdown_HitReaction_03");
            AddMotion(preFix + "Beatdown_HitReaction_04");
            AddMotion(preFix + "Beatdown_HitReaction_05");
            AddMotion(preFix + "Beatdown_HitReaction_06");
        }
        else if (playerType == 1)
        {
            String preFix = "TG_CW_Beatdown/";
            AddMotion(preFix + "Beatdown_01");
            AddMotion(preFix + "Beatdown_02");
            AddMotion(preFix + "Beatdown_03");
            AddMotion(preFix + "Beatdown_04");
            AddMotion(preFix + "Beatdown_05");
            AddMotion(preFix + "Beatdown_06");
        }

        flags = FLAGS_STUN | FLAGS_ATTACK;
    }

    bool CanReEntered()
    {
        return true;
    }

    float GetThreatScore()
    {
        return 0.9f;
    }

    void OnMotionFinished()
    {
        // Print(ownner.GetName() + " state:" + name + " finshed motion:" + motions[selectIndex].animationName);
        ownner.ChangeState("StunState");
    }
};

class ThugBeatDownEndState : MultiMotionState
{
    ThugBeatDownEndState(Character@ c)
    {
        super(c);
        SetName("BeatDownEndState");
        if (playerType == 0)
        {
            String preFix = "TG_BM_Beatdown/";
            AddMotion(preFix + "Beatdown_Strike_End_01");
            AddMotion(preFix + "Beatdown_Strike_End_02");
            AddMotion(preFix + "Beatdown_Strike_End_03");
            AddMotion(preFix + "Beatdown_Strike_End_04");
        }
        else if (playerType == 1)
        {
            String preFix = "TG_CW_Beatdown/";
            AddMotion(preFix + "Beatdown_End_01");
            AddMotion(preFix + "Beatdown_End_02");
            AddMotion(preFix + "Beatdown_End_03");
        }

        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.SetHealth(0);
        MultiMotionState::Enter(lastState);
    }
};


class ThugStunState : CharacterState
{
    ThugStunState(Character@ ownner)
    {
        super(ownner);
        SetName("StunState");
        flags = FLAGS_STUN | FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.PlayAnimation(GetAnimationName("TG_HitReaction/CapeHitReaction_Idle"), LAYER_MOVE, true, 0.2f);
        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (timeInState > 5.0f)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        CharacterState::Update(dt);
    }
};

class ThugPushBackState : SingleMotionState
{
    ThugPushBackState(Character@ ownner)
    {
        super(ownner);
        SetName("PushBack");
        flags = FLAGS_ATTACK;
        SetMotion("TG_HitReaction/HitReaction_Left");
    }
};

class Thug : Enemy
{
    float           checkAvoidanceTimer = 0.0f;
    float           checkAvoidanceTime = 0.1f;

    void ObjectStart()
    {
        Enemy::ObjectStart();
        stateMachine.AddState(ThugStandState(this));
        stateMachine.AddState(ThugCounterState(this));
        stateMachine.AddState(ThugHitState(this));
        stateMachine.AddState(ThugStepMoveState(this));
        stateMachine.AddState(ThugTurnState(this));
        stateMachine.AddState(ThugRunState(this));
        stateMachine.AddState(ThugAttackState(this));
        stateMachine.AddState(CharacterRagdollState(this));
        stateMachine.AddState(ThugGetUpState(this));
        stateMachine.AddState(ThugDeadState(this));
        stateMachine.AddState(ThugBeatDownHitState(this));
        stateMachine.AddState(ThugBeatDownEndState(this));
        stateMachine.AddState(ThugStunState(this));
        stateMachine.AddState(ThugPushBackState(this));
        stateMachine.AddState(AnimationTestState(this));
        ChangeState("StandState");

        Node@ collisionNode = sceneNode.CreateChild("Collision");
        CollisionShape@ shape = collisionNode.CreateComponent("CollisionShape");
        shape.SetCapsule(KEEP_DIST*2, CHARACTER_HEIGHT, Vector3(0, CHARACTER_HEIGHT/2, 0));
        RigidBody@ body = collisionNode.CreateComponent("RigidBody");
        body.mass = 10;
        body.collisionLayer = COLLISION_LAYER_CHARACTER;
        body.collisionMask = COLLISION_LAYER_CHARACTER;
        body.kinematic = true;
        body.trigger = true;
        body.collisionEventMode = COLLISION_ALWAYS;

        attackDamage = 20;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
    }

    bool CanAttack()
    {
        EnemyManager@ em = cast<EnemyManager>(sceneNode.scene.GetScriptObject("EnemyManager"));
        if (em is null)
            return false;
        int num = em.GetNumOfEnemyAttackValid();
        if (num >= MAX_NUM_OF_ATTACK)
            return false;
        if (!target.CanBeAttacked())
            return false;
        return true;
    }

    bool Attack()
    {
        if (!CanAttack())
            return false;
        if (KeepDistanceWithEnemy())
            return false;
        ChangeState("AttackState");
        return true;
    }

    bool Redirect()
    {
        ChangeState("RedirectState");
        return true;
    }

    void CommonStateFinishedOnGroud()
    {
        ChangeState("StandState");
    }

    bool OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        if (!CanBeAttacked())
        {
            Print("OnDamage failed because I can no be attacked " + GetName());
            return false;
        }

        Print(GetName() + " OnDamage: pos=" + position.ToString() + " dir=" + direction.ToString() + " damage=" + damage + " weak=" + weak);
        health -= damage;
        health = Max(0, health);
        SetHealth(health);

        Node@ attackNode = attacker.GetNode();

        Vector3 v = direction * -1;
        v.y = 1.0f;
        v.Normalize();
        v *= GetRagdollForce();

        if (health <= 0)
        {
            v *= 1.5f;
            MakeMeRagdoll(v, position);
            OnDead();
        }
        else
        {
            float diff = ComputeAngleDiff(attackNode);
            if (weak) {
                int index = 0;
                if (diff < 0)
                    index = 1;
                if (Abs(diff) > 135)
                    index = 2 + RandomInt(2);
                sceneNode.vars[ANIMATION_INDEX] = index;
                ChangeState("HitState");
            }
            else {
                MakeMeRagdoll(v, position);
            }
        }
        return true;
    }

    void RequestDoNotMove()
    {
        Character::RequestDoNotMove();
        StringHash nameHash = stateMachine.currentState.nameHash;
        if (HasFlag(FLAGS_MOVING))
        {
            ChangeState("StandState");
            return;
        }

        if (nameHash == HIT_STATE)
        {
            // I dont know how to do ...
            // special case
            motion_translateEnabled = false;
        }
    }

    int GetSperateDirection(int& outDir)
    {
        Node@ _node = sceneNode.GetChild("Collision");
        if (_node is null)
            return 0;

        RigidBody@ body = _node.GetComponent("RigidBody");
        if (body is null)
            return 0;

        int len = 0;
        Vector3 myPos = sceneNode.worldPosition;
        Array<RigidBody@>@ neighbors = body.collidingBodies;
        float totalAngle = 0;

        for (uint i=0; i<neighbors.length; ++i)
        {
            Node@ n_node = neighbors[i].node.parent;
            if (n_node is null)
                continue;

            //Print("neighbors[" + i + "] = " + n_node.name);

            Character@ object = cast<Character>(n_node.scriptObject);
            if (object is null)
                continue;

            if (object.HasFlag(FLAGS_MOVING))
                continue;

            ++len;

            float angle = ComputeAngleDiff(object.sceneNode);
            if (angle < 0)
                angle += 180;
            else
                angle = 180 - angle;

            //Print("neighbors angle=" + angle);
            totalAngle += angle;
        }

        if (len == 0)
            return 0;

        outDir = DirectionMapToIndex(totalAngle / len, 4);

        if (d_log)
            Print("GetSperateDirection() totalAngle=" + totalAngle + " outDir=" + outDir + " len=" + len);

        return len;
    }

    void CheckAvoidance(float dt)
    {
        checkAvoidanceTimer += dt;
        if (checkAvoidanceTimer >= checkAvoidanceTime)
        {
            checkAvoidanceTimer -= checkAvoidanceTime;
            CheckCollision();
        }
    }

    void ClearAvoidance()
    {
        checkAvoidanceTimer = 0.0;
        checkAvoidanceTime = Random(0.05f, 0.1f);
    }

    bool KeepDistanceWithEnemy()
    {
        if (HasFlag(FLAGS_NO_MOVE))
            return false;
        int dir = -1;
        if (GetSperateDirection(dir) == 0)
            return false;
        // Print(GetName() + " CollisionAvoidance index=" + dir);
        MultiMotionState@ state = cast<MultiMotionState>(FindState("StepMoveState"));
        Motion@ motion = state.motions[dir];
        Vector4 motionOut = motion.GetKey(motion.endTime);
        Vector3 endPos = sceneNode.worldRotation * Vector3(motionOut.x, motionOut.y, motionOut.z) + sceneNode.worldPosition;
        Vector3 diff = endPos - target.sceneNode.worldPosition;
        diff.y = 0;
        if((diff.length - COLLISION_SAFE_DIST) < -0.25f)
        {
            Print("can not avoid collision because player is in front of me.");
            return false;
        }
        sceneNode.vars[ANIMATION_INDEX] = dir;
        ChangeState("StepMoveState");
        return true;
    }

    bool KeepDistanceWithPlayer(float max_dist = KEEP_DIST_WITH_PLAYER)
    {
        if (HasFlag(FLAGS_NO_MOVE))
            return false;
        float dist = GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist >= max_dist)
            return false;
        int index = RadialSelectAnimation(4);
        index = (index + 2) % 4;
        // Print(GetName() + " KeepDistanceWithPlayer index=" + index + " max_dist=" + max_dist);
        sceneNode.vars[ANIMATION_INDEX] = index;
        ChangeState("StepMoveState");
        return true;
    }

    void CheckCollision()
    {
        if (KeepDistanceWithPlayer())
            return;
        KeepDistanceWithEnemy();
    }

    bool Distract()
    {
        ChangeState("DistractState");
        return true;
    }
};

Vector3 GetRagdollForce()
{
    float x = Random(HIT_RAGDOLL_FORCE.x*0.75f, HIT_RAGDOLL_FORCE.x*1.25f);
    float y = Random(HIT_RAGDOLL_FORCE.y*0.75f, HIT_RAGDOLL_FORCE.y*1.25f);
    return Vector3(x, y, x);
}

void CreateThugMotions()
{
    AssignMotionRig("Models/thug.mdl");

    String preFix = "TG_Combat/";
    Global_CreateMotion(preFix + "Step_Forward");
    Global_CreateMotion(preFix + "Step_Right");
    Global_CreateMotion(preFix + "Step_Back");
    Global_CreateMotion(preFix + "Step_Left");
    Global_CreateMotion(preFix + "Step_Forward_Long");
    Global_CreateMotion(preFix + "Step_Right_Long");
    Global_CreateMotion(preFix + "Step_Back_Long");
    Global_CreateMotion(preFix + "Step_Left_Long");

    Global_CreateMotion(preFix + "135_Turn_Left", kMotion_XZR, kMotion_R, 32);
    Global_CreateMotion(preFix + "135_Turn_Right", kMotion_XZR, kMotion_R, 32);

    Global_CreateMotion(preFix + "Run_Forward_Combat", kMotion_XZR, kMotion_XZR, -1, true);
    Global_CreateMotion(preFix + "Walk_Forward_Combat", kMotion_XZR, kMotion_XZR, -1, true);

    Global_CreateMotion(preFix + "Attack_Kick");
    Global_CreateMotion(preFix + "Attack_Kick_01");
    Global_CreateMotion(preFix + "Attack_Kick_02");
    Global_CreateMotion(preFix + "Attack_Punch");
    Global_CreateMotion(preFix + "Attack_Punch_01");
    Global_CreateMotion(preFix + "Attack_Punch_02");

    preFix = "TG_HitReaction/";
    Global_CreateMotion(preFix + "HitReaction_Left");
    Global_CreateMotion(preFix + "HitReaction_Right");
    Global_CreateMotion(preFix + "HitReaction_Back_NoTurn");
    Global_CreateMotion(preFix + "HitReaction_Back");
    Global_AddAnimation(preFix + "CapeHitReaction_Idle");

    preFix = "TG_Getup/";
    Global_CreateMotion(preFix + "GetUp_Front", kMotion_XZ);
    Global_CreateMotion(preFix + "GetUp_Back", kMotion_XZ);

    /*Global_CreateMotion(preFix + "Double_Counter_2ThugsA_01");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsA_02");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsB_01", kMotion_XZR, kMotion_XZR, -1, false, -90);
    Global_CreateMotion(preFix + "Double_Counter_2ThugsB_02", kMotion_XZR, kMotion_XZR, -1, false, 90);
    Global_CreateMotion(preFix + "Double_Counter_2ThugsD_01");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsD_02");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsE_01");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsE_02");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsF_01");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsFg_02");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsG_01");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsG_02", kMotion_XZR, kMotion_XZR, -1, false, 90);
    Global_CreateMotion(preFix + "Double_Counter_2ThugsH_01");
    Global_CreateMotion(preFix + "Double_Counter_2ThugsH_02", kMotion_XZR, kMotion_XZR, -1, false, 90);
    Global_CreateMotion(preFix + "Double_Counter_3ThugsA_01", kMotion_XZR, kMotion_XZR, -1, false, -90);
    Global_CreateMotion(preFix + "Double_Counter_3ThugsA_02");
    Global_CreateMotion(preFix + "Double_Counter_3ThugsA_03", kMotion_XZR, kMotion_XZR, -1, false, 90);
    Global_CreateMotion(preFix + "Double_Counter_3ThugsB_01");
    Global_CreateMotion(preFix + "Double_Counter_3ThugsB_02", kMotion_XZR, kMotion_XZR, -1, false, 90);
    Global_CreateMotion(preFix + "Double_Counter_3ThugsB_03");
    Global_CreateMotion(preFix + "Double_Counter_3ThugsC_01");
    Global_CreateMotion(preFix + "Double_Counter_3ThugsC_02", kMotion_XZR, kMotion_XZR, -1, false, 90);
    Global_CreateMotion(preFix + "Double_Counter_3ThugsC_03");*/
    Global_CreateMotion_InFolder("TG_BW_Counter/");
    Global_CreateMotion_InFolder("TG_CW_Counter/");

    preFix = "TG_BM_Beatdown/";
    Global_CreateMotion(preFix + "Beatdown_HitReaction_01");
    Global_CreateMotion(preFix + "Beatdown_HitReaction_02");
    Global_CreateMotion(preFix + "Beatdown_HitReaction_03");
    Global_CreateMotion(preFix + "Beatdown_HitReaction_04");
    Global_CreateMotion(preFix + "Beatdown_HitReaction_05");
    Global_CreateMotion(preFix + "Beatdown_HitReaction_06");

    Global_CreateMotion(preFix + "Beatdown_Strike_End_01");
    Global_CreateMotion(preFix + "Beatdown_Strike_End_02");
    Global_CreateMotion(preFix + "Beatdown_Strike_End_03");
    Global_CreateMotion(preFix + "Beatdown_Strike_End_04");

    preFix = "TG_Combat/";
    Global_AddAnimation(preFix + "Stand_Idle_Additive_01");
    Global_AddAnimation(preFix + "Stand_Idle_Additive_02");
    Global_AddAnimation(preFix + "Stand_Idle_Additive_03");
    Global_AddAnimation(preFix + "Stand_Idle_Additive_04");

    preFix = "TG_CW_Beatdown/";
    Global_CreateMotion(preFix + "Beatdown_01");
    Global_CreateMotion(preFix + "Beatdown_02");
    Global_CreateMotion(preFix + "Beatdown_03");
    Global_CreateMotion(preFix + "Beatdown_04");
    Global_CreateMotion(preFix + "Beatdown_05");
    Global_CreateMotion(preFix + "Beatdown_06");

    Global_CreateMotion(preFix + "Beatdown_End_01");
    Global_CreateMotion(preFix + "Beatdown_End_02");
    Global_CreateMotion(preFix + "Beatdown_End_03");
}

void AddThugAnimationTriggers()
{
    String preFix = "TG_BW_Counter/";
    AddRagdollTrigger(preFix + "Counter_Leg_Front_01", 30, 35);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_02", 46, 56);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_03", 38, 48);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_04", 30, 46);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_05", 38, 42);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_06", 32, 36);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_Weak", 50, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Arm_Front_01", 34, 35);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_02", 44, 48);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_03", 35, 40);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_04", 36, 40);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_05", 60, 66);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_06", -1, 44);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_07", 38, 43);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_08", 54, 60);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_09", 60, 68);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_10", -1, 56);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_02", 50, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Arm_Back_01", 35, 40);
    AddRagdollTrigger(preFix + "Counter_Arm_Back_02", -1, 48);
    AddRagdollTrigger(preFix + "Counter_Arm_Back_03", 30, 35);
    AddRagdollTrigger(preFix + "Counter_Arm_Back_04", 30, 35);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_Weak_01", 50, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Leg_Back_01", 50, 54);
    AddRagdollTrigger(preFix + "Counter_Leg_Back_02", 60, 54);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_Weak_01", 55, READY_TO_FIGHT);

    /*
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsA_01", -1, 99);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsA_02", -1, 99);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsB_01", -1, 58);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsB_02", -1, 58);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsD_01", -1, 48);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsD_02", -1, 48);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsE_01", 80, 84);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsE_02", 80, 84);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsF_01", 26, 28);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsF_02", 19, 24);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsG_01", -1, 26);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsG_02", -1, 26);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsH_01", -1, 62);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsH_02", -1, 62);

    AddRagdollTrigger(preFix + "Double_Counter_3ThugsA_01", 24, 30);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsA_02", 30, 36);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsA_03", 26, 34);

    AddRagdollTrigger(preFix + "Double_Counter_3ThugsB_01", 25, 33);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsB_02", 25, 33);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsB_03", 25, 33);

    AddRagdollTrigger(preFix + "Double_Counter_3ThugsC_01", 35, 41);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsC_02", 35, 45);
    */

    preFix = "TG_CW_Counter/";
    AddRagdollTrigger(preFix + "Counter_Arm_Back_01", -1, 66);
    AddRagdollTrigger(preFix + "Counter_Arm_Back_02", -1, 85);
    AddRagdollTrigger(preFix + "Counter_Arm_Back_03", 32, 38);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_Weak_01", 53, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_Weak_02", 53, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Arm_Front_01", -1, 30);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_02", -1, 38);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_03", 51, 66);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_04", -1, 63);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_05", -1, 64);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_01", 70, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_02", 85, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Leg_Back_01", -1, 35);
    AddRagdollTrigger(preFix + "Counter_Leg_Back_02", 64, 80);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_Weak_01", 75, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_Weak_02", 65, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Leg_Front_01", -1, 30);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_03", 55, 70);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_04", 50, 60);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_Weak_01", 35, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_Weak_02", 55, READY_TO_FIGHT);

    preFix = "TG_Combat/";
    int frame_fixup = 6;
    // name counter-start counter-end attack-start attack-end attack-bone
    AddComplexAttackTrigger(preFix + "Attack_Kick", 15 - frame_fixup, 24, 24, 27, "Bip01_L_Foot");
    AddComplexAttackTrigger(preFix + "Attack_Kick_01", 12 - frame_fixup, 24, 24, 27, "Bip01_L_Foot");
    AddComplexAttackTrigger(preFix + "Attack_Kick_02", 19 - frame_fixup, 24, 24, 27, "Bip01_L_Foot");
    AddComplexAttackTrigger(preFix + "Attack_Punch", 15 - frame_fixup, 22, 22, 24, "Bip01_R_Hand");
    AddComplexAttackTrigger(preFix + "Attack_Punch_01", 15 - frame_fixup, 23, 23, 24, "Bip01_R_Hand");
    AddComplexAttackTrigger(preFix + "Attack_Punch_02", 15 - frame_fixup, 23, 23, 24, "Bip01_R_Hand");

    AddStringAnimationTrigger(preFix + "Run_Forward_Combat", 2, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Run_Forward_Combat", 13, FOOT_STEP, R_FOOT);

    AddStringAnimationTrigger(preFix + "Step_Back", 15, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Back_Long", 9, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Back_Long", 19, FOOT_STEP, L_FOOT);

    AddStringAnimationTrigger(preFix + "Step_Forward", 12, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Forward_Long", 10, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Forward_Long", 22, FOOT_STEP, R_FOOT);

    AddStringAnimationTrigger(preFix + "Step_Left", 11, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Left_Long", 8, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Left_Long", 22, FOOT_STEP, R_FOOT);

    AddStringAnimationTrigger(preFix + "Step_Right", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Right_Long", 15, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Right_Long", 28, FOOT_STEP, L_FOOT);

    AddStringAnimationTrigger(preFix + "135_Turn_Left", 8, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "135_Turn_Left", 20, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "135_Turn_Left", 31, FOOT_STEP, R_FOOT);

    AddStringAnimationTrigger(preFix + "135_Turn_Right", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "135_Turn_Right", 24, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "135_Turn_Right", 39, FOOT_STEP, R_FOOT);

    preFix = "TG_Getup/";
    AddAnimationTrigger(preFix + "GetUp_Front", 44, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "GetUp_Back", 68, READY_TO_FIGHT);
}


