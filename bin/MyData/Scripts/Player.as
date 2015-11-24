// ==============================================
//
//    Player Pawn and Controller Class
//
// ==============================================

const String MOVEMENT_GROUP = "BM_Combat_Movement/"; //"BM_Combat_Movement/"
const float MAX_COUNTER_DIST = 5.0f;
const float MAX_ATTACK_DIST = 25.0f;

class PlayerStandState : CharacterState
{
    Array<String>   animations;

    PlayerStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        animations.Push(GetAnimationName(MOVEMENT_GROUP + "Stand_Idle"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP + "Stand_Idle_01"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP + "Stand_Idle_02"));
    }

    void Enter(State@ lastState)
    {
        float blendTime = 0.25f;
        if (lastState !is null)
        {
            if (lastState.nameHash == ATTACK_STATE)
                blendTime = 10.0f;
            else if (lastState.nameHash == REDIRECT_STATE)
                blendTime = 2.5f;
            else if (lastState.nameHash == COUNTER_STATE)
                blendTime = 2.5f;
            else if (lastState.nameHash == GETUP_STATE)
                blendTime = 0.5f;
        }
        ownner.PlayAnimation(animations[RandomInt(animations.length)], LAYER_MOVE, true, blendTime);
        ownner.AddFlag(FLAGS_ATTACK);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK);
        CharacterState::Exit(nextState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

            Print("Stand->Move|Turn hold-frames=" + gInput.m_leftStickHoldFrames + " hold-time=" + gInput.m_leftStickHoldTime);

            if (index == 0)
                ownner.ChangeState("MoveState");
            else
                ownner.ChangeState("TurnState");
        }

        if (gInput.IsAttackPressed())
            ownner.Attack();
        else if (gInput.IsCounterPressed())
            ownner.Counter();
        else if (gInput.IsEvadePressed())
            ownner.Evade();

        CharacterState::Update(dt);
    }
};

class PlayerTurnState : MultiMotionState
{
    float turnSpeed;

    PlayerTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        AddMotion(MOVEMENT_GROUP + "Turn_Right_90");
        AddMotion(MOVEMENT_GROUP + "Turn_Right_180");
        AddMotion(MOVEMENT_GROUP + "Turn_Left_90");
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += turnSpeed * dt;

        if (gInput.IsAttackPressed())
            ownner.Attack();
        else if (gInput.IsCounterPressed())
            ownner.Counter();
        else if (gInput.IsEvadePressed())
            ownner.Evade();

        if (motions[selectIndex].Move(ownner, dt))
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        MultiMotionState::Enter(lastState);
        ownner.AddFlag(FLAGS_ATTACK);
        Motion@ motion = motions[selectIndex];
        Vector4 endKey = motion.GetKey(motion.endTime);
        float motionTargetAngle = ownner.motion_startRotation + endKey.w;
        float targetAngle = ownner.GetTargetAngle();
        float diff = AngleDiff(targetAngle - motionTargetAngle);
        turnSpeed = diff / motion.endTime;
        Print("motionTargetAngle=" + String(motionTargetAngle) + " targetAngle=" + String(targetAngle) + " diff=" + String(diff) + " turnSpeed=" + String(turnSpeed));
    }

    void Exit(State@ nextState)
    {
        MultiMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_ATTACK);
    }
};

class PlayerMoveState : SingleMotionState
{
    float turnSpeed = 5.0f;

    PlayerMoveState(Character@ c)
    {
        super(c);
        SetName("MoveState");
        SetMotion(MOVEMENT_GROUP + "Walk_Forward");
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
        }

        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
            ownner.ChangeState("StandState");

        if (gInput.IsAttackPressed())
            ownner.Attack();
        else if (gInput.IsCounterPressed())
            ownner.Counter();
        else if (gInput.IsEvadePressed())
            ownner.Evade();

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.AddFlag(FLAGS_ATTACK | FLAGS_MOVING);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_ATTACK | FLAGS_MOVING);
    }
};

class PlayerEvadeState : MultiMotionState
{
    PlayerEvadeState(Character@ c)
    {
        super(c);
        SetName("EvadeState");
        String prefix = "BM_Movement/";
        AddMotion(prefix + "Evade_Forward_01");
        AddMotion(prefix + "Evade_Right_01");
        AddMotion(prefix + "Evade_Back_01");
        AddMotion(prefix + "Evade_Left_01");
    }
};

class PlayerRedirectState : SingleMotionState
{
    Enemy@ redirectEnemy;

    PlayerRedirectState(Character@ c)
    {
        super(c);
        SetName("RedirectState");
        SetMotion("BM_Combat/Redirect");
    }

    void Exit(State@ nextState)
    {
        @redirectEnemy = null;
        SingleMotionState::Exit(nextState);
    }
};

enum AttackStateType
{
    ATTACK_STATE_ALIGN,
    ATTACK_STATE_BEFORE_IMPACT,
    ATTACK_STATE_AFTER_IMPACT,
};

class PlayerAttackState : CharacterState
{
    Array<AttackMotion@>    forwardAttacks;
    Array<AttackMotion@>    leftAttacks;
    Array<AttackMotion@>    rightAttacks;
    Array<AttackMotion@>    backAttacks;

    AttackMotion@           currentAttack;
    Enemy@                  attackEnemy;

    int                     state;
    Vector3                 movePerSec;
    Vector3                 predictPosition;
    Vector3                 motionPosition;

    float                   targetDistance;
    float                   alignTime = 0.3f;

    int                     forwadCloseNum = 0;
    int                     leftCloseNum = 0;
    int                     rightCloseNum = 0;
    int                     backCloseNum = 0;

    bool                    doAttackCheck = false;
    Node@                   attackCheckNode;

    bool                    weakAttack = true;
    bool                    slowMotion = false;
    bool                    isInAir = false;
    bool                    lastKill = false;

    PlayerAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");

        //========================================================================
        // FORWARD
        //========================================================================

        // forward weak
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward", 11, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_01", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_02", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_03", 11, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_04", 16, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_05", 12, ATTACK_PUNCH, L_HAND);

        // forward close
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_02", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_03", 11, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_04", 19, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_05", 24, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_06", 20, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_07", 15, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_08", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(forwardAttacks, "Attack_Close_Run_Forward", 12, ATTACK_PUNCH, R_HAND);

        // forward far
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward", 25, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_01", 17, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_02", 21, ATTACK_KICK, L_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_03", 22, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_04", 22, ATTACK_KICK, R_FOOT);
        AddAttackMotion(forwardAttacks, "Attack_Run_Far_Forward", 18, ATTACK_KICK, R_FOOT);

        //========================================================================
        // RIGHT
        //========================================================================
        // right weak
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right", 12, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_01", 10, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_02", 15, ATTACK_PUNCH, R_HAND);

        // right close
        AddAttackMotion(rightAttacks, "Attack_Close_Right", 16, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_01", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_03", 11, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_04", 19, ATTACK_KICK, R_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_05", 15, ATTACK_KICK, L_CALF);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_06", 20, ATTACK_KICK, R_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_07", 18, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_08", 18, ATTACK_KICK, L_FOOT);

        // right far
        AddAttackMotion(rightAttacks, "Attack_Far_Right", 25, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_01", 15, ATTACK_KICK, L_CALF);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_02", 21, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_03", 29, ATTACK_KICK, L_FOOT);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_04", 22, ATTACK_KICK, R_FOOT);

        //========================================================================
        // BACK
        //========================================================================
        // back weak
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back", 12, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back_01", 12, ATTACK_PUNCH, R_HAND);

        AddAttackMotion(backAttacks, "Attack_Close_Back", 11, ATTACK_PUNCH, L_ARM);
        AddAttackMotion(backAttacks, "Attack_Close_Back_01", 16, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_02", 18, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_03", 21, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_04", 18, ATTACK_KICK, R_FOOT);
        AddAttackMotion(backAttacks, "Attack_Close_Back_05", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_06", 15, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_07", 14, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Close_Back_08", 17, ATTACK_KICK, L_FOOT);

        // back far
        AddAttackMotion(backAttacks, "Attack_Far_Back", 14, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_01", 15, ATTACK_KICK, L_FOOT);
        AddAttackMotion(backAttacks, "Attack_Far_Back_02", 22, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(backAttacks, "Attack_Far_Back_03", 22, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(backAttacks, "Attack_Far_Back_04", 36, ATTACK_KICK, R_FOOT);

        //========================================================================
        // LEFT
        //========================================================================
        // left weak
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left", 13, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_01", 12, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_02", 13, ATTACK_PUNCH, L_HAND);

        // left close
        AddAttackMotion(leftAttacks, "Attack_Close_Left", 7, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_01", 18, ATTACK_PUNCH, R_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_02", 13, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_03", 21, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_04", 21, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_05", 15, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_06", 12, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_07", 15, ATTACK_PUNCH, L_HAND);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_08", 20, ATTACK_KICK, L_FOOT);


        // left far
        AddAttackMotion(leftAttacks, "Attack_Far_Left", 19, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_01", 22, ATTACK_KICK, R_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_02", 22, ATTACK_PUNCH, R_ARM);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_03", 21, ATTACK_KICK, L_FOOT);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_04", 23, ATTACK_KICK, R_FOOT);

        forwardAttacks.Sort();
        leftAttacks.Sort();
        rightAttacks.Sort();
        backAttacks.Sort();

        float min_dist = 2.0f;
        for (uint i=0; i<forwardAttacks.length; ++i)
        {
            if (forwardAttacks[i].impactDist >= min_dist)
                break;
            forwadCloseNum++;
        }
        for (uint i=0; i<rightAttacks.length; ++i)
        {
            if (rightAttacks[i].impactDist >= min_dist)
                break;
            rightCloseNum++;
        }
        for (uint i=0; i<backAttacks.length; ++i)
        {
            if (backAttacks[i].impactDist >= min_dist)
                break;
            backCloseNum++;
        }
        for (uint i=0; i<leftAttacks.length; ++i)
        {
            if (leftAttacks[i].impactDist >= min_dist)
                break;
            leftCloseNum++;
        }

        if (d_log)
        {
            Print("\n forward attacks(closeNum=" + forwadCloseNum + "): \n");
            DumpAttacks(forwardAttacks);
            Print("\n right attacks(closeNum=" + rightCloseNum + "): \n");
            DumpAttacks(rightAttacks);
            Print("\n back attacks(closeNum=" + backCloseNum + "): \n");
            DumpAttacks(backAttacks);
            Print("\n left attacks(closeNum=" + leftCloseNum + "): \n");
            DumpAttacks(leftAttacks);
        }
    }

    void DumpAttacks(Array<AttackMotion@>@ attacks)
    {
        for (uint i=0; i<attacks.length; ++i)
            Print(attacks[i].motion.animationName + " impactDist=" + String(attacks[i].impactDist));
    }

    void AddAttackMotion(Array<AttackMotion@>@ attacks, const String&in name, int frame, int type, const String&in bName)
    {
        attacks.Push(AttackMotion("BM_Attack/" + name, frame, type, bName));
    }

    ~PlayerAttackState()
    {
        @attackEnemy = null;
        @currentAttack = null;
    }

    void ChangeSubState(int newState)
    {
        Print("PlayerAttackState changeSubState from " + state + " to " + newState);
        state = newState;
    }

    void Update(float dt)
    {
        Motion@ motion = currentAttack.motion;

        Node@ _node = ownner.GetNode();
        Node@ tailNode = _node.GetChild("TailNode", true);
        Node@ attackNode = _node.GetChild(currentAttack.boneName, true);

        if (tailNode !is null && attackNode !is null) {
            tailNode.worldPosition = attackNode.worldPosition;
        }

        float t = ownner.animCtrl.GetTime(motion.animationName);
        if (state == ATTACK_STATE_ALIGN)
        {
            ownner.motion_deltaPosition += movePerSec * dt;
            if (t >= alignTime)
            {
                ChangeSubState(ATTACK_STATE_BEFORE_IMPACT);
                attackEnemy.RemoveFlag(FLAGS_NO_MOVE);
            }
        }
        else if (state == ATTACK_STATE_BEFORE_IMPACT)
        {
            if (t > currentAttack.impactTime)
            {
                ChangeSubState(ATTACK_STATE_AFTER_IMPACT);
                AttackImpact();
            }
        }
        else
        {

        }

        if (slowMotion)
        {
            float t_diff = Abs(currentAttack.impactTime - t);
            if (t_diff < 0.25f)
                ownner.SetSceneTimeScale(0.25f);
            else
                ownner.SetSceneTimeScale(1.0f);
        }

        if (attackEnemy !is null)
        {
            targetDistance = ownner.GetTargetDistance(attackEnemy.GetNode());
            if (ownner.motion_translateEnabled && targetDistance < COLLISION_SAFE_DIST)
            {
                Print("Player::AttackState TooClose set translateEnabled to false");
                ownner.motion_translateEnabled = false;
            }
        }

        if (doAttackCheck)
            AttackCollisionCheck();

        bool finished = motion.Move(ownner, dt);
        if (finished) {
            Print("Player::Attack finish attack movemont in sub state = " + state);
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        CheckInput(t);
        CharacterState::Update(dt);
    }


    void CheckInput(float t)
    {
        float y_diff = ownner.hipsNode.worldPosition.y - pelvisOrign.y;
        isInAir = y_diff > 0.5f;
        if (isInAir)
            return;

        int addition_frames = slowMotion ? 6 : 0;
        bool check_attack = t > currentAttack.impactTime + SEC_PER_FRAME * ( HIT_WAIT_FRAMES + 1 + addition_frames);
        bool check_others = t > currentAttack.impactTime + SEC_PER_FRAME * addition_frames;

        if (check_attack)
        {
            if (gInput.IsAttackPressed())
                ownner.Attack();
        }

        if (check_others)
        {
            if (gInput.IsCounterPressed())
                ownner.Counter();
            else if (gInput.IsEvadePressed())
                ownner.Evade();
        }
    }

    void ResetValues()
    {
        @currentAttack = null;
        @attackEnemy = null;
        state = ATTACK_STATE_ALIGN;
        movePerSec = Vector3(0, 0, 0);
    }

    void PickBestMotion(Array<AttackMotion@>@ attacks, int dir)
    {
        Vector3 myPos = ownner.GetNode().worldPosition;
        Vector3 enemyPos = attackEnemy.GetNode().worldPosition;
        Vector3 diff = enemyPos - myPos;
        diff.y = 0;
        float toEnenmyDistance = diff.length - COLLISION_SAFE_DIST;
        if (toEnenmyDistance < 0.0f)
            toEnenmyDistance = 0.0f;
        int bestIndex = 0;
        diff.Normalize();

        int index_start = -1;
        int index_num = 0;

        float min_dist = toEnenmyDistance - 3.0f;
        if (min_dist < 0.0f)
            min_dist = 0.0f;
        float max_dist = toEnenmyDistance + 0.1f;
        Print("Player attack toEnenmyDistance = " + toEnenmyDistance + "(" + min_dist + "," + max_dist + ")");

        for (uint i=0; i<attacks.length; ++i)
        {
            AttackMotion@ am = attacks[i];
            if (am.impactDist > max_dist)
                break;

            if (am.impactDist > min_dist)
            {
                if (index_start == -1)
                    index_start = i;
                index_num ++;
            }
        }

        if (index_num == 0)
        {
            if (toEnenmyDistance > attacks[attacks.length - 1].impactDist)
                bestIndex = attacks.length - 1;
            else
                bestIndex = 0;
        }
        else
        {
            bestIndex = index_start + RandomInt(index_num);
            Print("Attack bestIndex="+bestIndex+" index_start="+index_start+" index_num"+index_num);
        }

        @currentAttack = attacks[bestIndex];
        //alignTime = Min(0.5f, currentAttack.impactTime);
        alignTime = currentAttack.impactTime;

        predictPosition = myPos + diff * toEnenmyDistance;
        Print("Player Pick attack motion = " + currentAttack.motion.animationName);
    }

    void StartAttack()
    {
        if (attackEnemy !is null)
        {
            state = ATTACK_STATE_ALIGN;
            float diff = ownner.ComputeAngleDiff(attackEnemy.GetNode());
            int r = DirectionMapToIndex(diff, 4);
            Print("Attack-align " + " r-index=" + r + " diff=" + diff);

            if (r == 0)
                PickBestMotion(forwardAttacks, r);
            else if (r == 1)
                PickBestMotion(rightAttacks, r);
            else if (r == 2)
                PickBestMotion(backAttacks, r);
            else if (r == 3)
                PickBestMotion(leftAttacks, r);

            attackEnemy.RequestDoNotMove();
        }
        else {
            currentAttack = forwardAttacks[RandomInt(forwadCloseNum)];
            state = ATTACK_STATE_BEFORE_IMPACT;
        }

        Motion@ motion = currentAttack.motion;
        motion.Start(ownner);
        isInAir = false;
        weakAttack = cast<Player>(ownner).combo < 3;
        if (cast<Player>(ownner).combo >= 3)
            slowMotion = (RandomInt(10) == 1);
        else
            slowMotion = false;

        if (attackEnemy !is null)
        {
            motionPosition = motion.GetFuturePosition(ownner, currentAttack.impactTime);
            movePerSec = ( predictPosition - motionPosition ) / alignTime;
            movePerSec.y = 0;

            if (attackEnemy.HasFlag(FLAGS_COUNTER))
                slowMotion = true;

            if (attackEnemy.health <= ownner.attackDamage)
            {
                EnemyManager@ em = cast<EnemyManager>(ownner.GetScene().GetScriptObject("EnemyManager"));
                if (em !is null)
                {
                    if (em.GetNumOfEnemyHealthAbove(1) == 1)
                    {
                        lastKill = true;
                        ownner.SetSceneTimeScale(0.25f);
                    }
                }
            }
        }
        else
        {
            weakAttack = false;
            slowMotion = false;
        }

        ownner.EnableComponent("TailNode", "TailGenerator", true);
    }

    void Start()
    {
        ResetValues();
        Player@ p = cast<Player>(ownner);
        @attackEnemy = p.PickAttackEnemy();
        if (attackEnemy !is null)
             Print("Choose Attack Enemy " + attackEnemy.GetNode().name + " state=" + attackEnemy.GetState().name);
         else
            Print("No Attack Enemy");
        StartAttack();
    }

    void Enter(State@ lastState)
    {
        Print("################## Player::AttackState Enter from " + lastState.name  + " #####################");
        Start();
        CharacterState::Enter(lastState);
        ownner.AddFlag(FLAGS_ATTACK);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        ownner.EnableComponent("TailNode", "TailGenerator", false);

        if (nextState !is this)
            cast<Player>(ownner).lastAttackId = -1;

        if (attackEnemy !is null)
            attackEnemy.RemoveFlag(FLAGS_NO_MOVE);
        @attackEnemy = null;
        @currentAttack = null;
        ownner.RemoveFlag(FLAGS_ATTACK);
        if (slowMotion || lastKill)
            ownner.SetSceneTimeScale(1.0f);
        Print("################## Player::AttackState Exit to " + nextState.name  + " #####################");
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        CharacterState::OnAnimationTrigger(animState, eventData);
        StringHash name = eventData[NAME].GetStringHash();
        if (name == TIME_SCALE) {
            float scale = eventData[VALUE].GetFloat();
            SetWorldTimeScale(ownner.GetNode(), scale);
        }
        else if (name == COUNTER_CHECK)
        {
            int value = eventData[VALUE].GetInt();
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
                attackCheckNode = ownner.GetNode().GetChild(eventData[BONE].GetString(), true);
                Print("Player AttackCheck bone=" + attackCheckNode.name);
                AttackCollisionCheck();
            }
        }
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentAttack is null || attackEnemy is null)
            return;
        debug.AddLine(ownner.GetNode().worldPosition, attackEnemy.GetNode().worldPosition, Color(0.27f, 0.28f, 0.7f), false);
        debug.AddCross(predictPosition, 0.5f, Color(0.25f, 0.28f, 0.7f), false);
        debug.AddCross(motionPosition, 0.5f, Color(0.75f, 0.28f, 0.27f), false);
    }

    String GetDebugText()
    {
        return " name=" + name + " timeInState=" + String(timeInState) +
                "currentAttack=" + currentAttack.motion.animationName +
                " distToEnemy=" + targetDistance +
                " isInAir=" + isInAir +
                " weakAttack=" + weakAttack +
                " slowMotion=" + slowMotion +
                "\n";
    }

    void AttackCollisionCheck()
    {
        if (attackCheckNode is null) {
            doAttackCheck = false;
            return;
        }

        Vector3 position = attackCheckNode.worldPosition;
        Vector3 targetPosition = attackEnemy.GetNode().worldPosition;
        Vector3 diff = targetPosition - position;
        diff.y = 0;
        float distance = diff.length;
        if (distance < ownner.attackRadius + COLLISION_SAFE_DIST) {
            Vector3 dir = position - targetPosition;
            dir.y = 0;
            dir.Normalize();
            bool b = attackEnemy.OnDamage(ownner, position, dir, ownner.attackDamage);
            if (!b)
                return;
            ownner.OnAttackSuccess(attackEnemy);
        }
    }

    bool CanReEntered()
    {
        return true;
    }

    void AttackImpact()
    {
        if (attackEnemy is null)
            return;

        Node@ _node = ownner.GetNode();
        Vector3 dir = _node.worldPosition - attackEnemy.GetNode().worldPosition;
        dir.y = 0;
        dir.Normalize();
        Print("PlayerAttackState::" +  attackEnemy.GetName() + " OnDamage!!!!");

        Node@ n = _node.GetChild(currentAttack.boneName, true);
        Vector3 position = _node.worldPosition;
        if (n !is null)
            position = n.worldPosition;

        bool b = attackEnemy.OnDamage(ownner, position, dir, ownner.attackDamage, weakAttack);
        if (!b)
            return;

        ownner.SpawnParticleEffect(position, "Particle/SnowExplosion.xml", 5, 5.0f);
        ownner.OnAttackSuccess(attackEnemy);

        float freqScale = ownner.GetScene().timeScale;
        if (currentAttack.type == ATTACK_PUNCH)
        {
            int i = RandomInt(6) + 1;
            String name = "Sfx/punch_0" + i + ".ogg";
            ownner.PlaySound(name, freqScale);
        }
        else
        {
            int i = RandomInt(6) + 1;
            String name = "Sfx/kick_0" + i + ".ogg";
            ownner.PlaySound(name, freqScale);
        }
    }
};


class PlayerCounterState : CharacterCounterState
{
    Array<Motion@>  doubleCounterMotions;
    Array<Enemy@>   counterEnemies;
    bool            bCheckInput = false;
    bool            isInAir = false;

    PlayerCounterState(Character@ c)
    {
        super(c);
        String preFix = "BM_TG_Counter/";
        AddCounterMotions(preFix);
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsF"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsG"));
        doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsB"));
    }

    ~PlayerCounterState()
    {
    }

    void Update(float dt)
    {
        CheckInput();
        CharacterCounterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        uint t = time.systemTime;

        CharacterCounterState::Enter(lastState);

        Node@ myNode = ownner.GetNode();
        Vector3 myPos = myNode.worldPosition;
        float myRotation = myNode.worldRotation.eulerAngles.y;
        float rotationDiff = 0;
        Vector3 positionDiff(0, 0, 0);

        Print("PlayerCounter-> counterEnemies len=" + counterEnemies.length);

        // POST_PROCESS
        if (counterEnemies.length > 1)
        {
            Vector3 vPos(0, 0, 0);
            for (uint i=0; i<counterEnemies.length; ++i)
            {
                Enemy@ e = counterEnemies[i];
                Node@ eNode = e.GetNode();
                Vector3 expect_pos = eNode.worldPosition + eNode.worldRotation * Vector3(0, 0, COLLISION_RADIUS);
                vPos += expect_pos;
                e.ChangeState("CounterState");
                CharacterCounterState@ eCState = cast<CharacterCounterState>(e.GetState());
                eCState.ChangeSubState(COUNTER_WAITING);
            }
            @currentMotion = doubleCounterMotions[RandomInt(doubleCounterMotions.length)];
            targetRotation = myRotation;
            targetPosition = vPos / counterEnemies.length;
        }
        else if (counterEnemies.length == 1)
        {
            Enemy@ counterEnemy = counterEnemies[0];
            Node@ enemyNode = counterEnemy.GetNode();
            float dAngle = ownner.ComputeAngleDiff(enemyNode);
            bool isBack = false;
            if (Abs(dAngle) > 90)
                isBack = true;
            Print("Counter-align angle-diff=" + dAngle + " isBack=" + isBack);

            int attackType = enemyNode.vars[ATTACK_TYPE].GetInt();
            CharacterCounterState@ eCState = cast<CharacterCounterState>(counterEnemy.stateMachine.FindState("CounterState"));
            if (eCState is null)
                return;

            Array<Motion@>@ counterMotions = GetCounterMotions(attackType, isBack);
            Array<Motion@>@ enemyCounterMotions = eCState.GetCounterMotions(attackType, isBack);

            int idx = RandomInt(counterMotions.length);
            @currentMotion = counterMotions[idx];
            @eCState.currentMotion = enemyCounterMotions[idx];

            rotationDiff = isBack ? 0 : 180;
            float enemyYaw = enemyNode.worldRotation.eulerAngles.y;
            targetRotation = enemyYaw + rotationDiff;

            Vector3 s1 = currentMotion.startFromOrigin;
            Vector3 s2 = eCState.currentMotion.startFromOrigin;
            Vector3 originDiff = s1 - s2;
            originDiff.x = Abs(originDiff.x);
            originDiff.z = Abs(originDiff.z);
            Print("SingleCounter s1=" + s1.ToString() + " s2=" + s2.ToString() + " originDiff=" + originDiff.ToString());

            if (isBack)
                enemyYaw += 180;
            targetPosition = enemyNode.worldPosition + enemyNode.worldRotation * originDiff;
            targetPosition.y = myPos.y;

            counterEnemy.ChangeState("CounterState");
            eCState.ChangeSubState(COUNTER_WAITING);
        }

        bCheckInput = false;

        positionDiff = targetPosition - myPos;
        rotationDiff = AngleDiff(targetRotation - myRotation);

        yawPerSec = rotationDiff / alignTime;
        movePerSec = positionDiff / alignTime;
        movePerSec.y = 0;

        ChangeSubState(COUNTER_ALIGNING);
        Print("PlayerCounter-> targetPosition=" + targetPosition.ToString() + " positionDiff=" + positionDiff.ToString() + " rotationDiff=" + rotationDiff + " time-cost=" + (time.systemTime - t));

        if (counterEnemies.length == 0)
            ownner.ChangeState("StandState"); // Something Error Happened
    }

    void Exit(State@ nextState)
    {
        counterEnemies.Clear();
        CharacterCounterState::Exit(nextState);
    }

    void OnAlignTimeOut()
    {
        Print("OnAlignTimeOut");
        ownner.GetNode().worldPosition = targetPosition;
        ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);
        StartCounterMotion();
        for (uint i=0; i<counterEnemies.length; ++i)
        {
            CharacterCounterState@ enemyCounterState = cast<CharacterCounterState>(counterEnemies[i].GetState());
            enemyCounterState.StartCounterMotion();
        }

        if (counterEnemies.length > 1)
        {
            ownner.SetSceneTimeScale(0.1f);
        }
    }

    String GetDebugText()
    {
        return "current motion=" + currentMotion.animationName + " isInAir=" + isInAir + " bCheckInput=" + bCheckInput + "\n";
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(targetPosition, 1.0f, RED, false);
        DebugDrawDirection(debug, ownner.GetNode(), targetRotation, RED);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        CharacterState::OnAnimationTrigger(animState, eventData);
        StringHash name = eventData[NAME].GetStringHash();
        if (name == READY_TO_FIGHT)
            bCheckInput = true;
        else if (name == IMPACT)
        {
            Node@ _node = ownner.GetNode();
            Node@ boneNode = _node.GetChild(eventData[VALUE].GetString(), true);
            if (boneNode !is null)
            ownner.SpawnParticleEffect(boneNode.worldPosition, "Particle/SnowExplosionFade.xml", 5, 5.0f);
            ownner.PlaySound("Sfx/kick_04.ogg");

            Vector3 my_pos = _node.worldPosition;
            if (counterEnemies.length > 1)
            {
                for (uint i=0; i<counterEnemies.length; ++i)
                {
                    Vector3 v = my_pos - counterEnemies[i].GetNode().worldPosition;
                    v.y = 0;
                    v.Normalize();
                    v *= 2;
                    counterEnemies[i].MakeMeRagdoll(0, true, v);
                }
            }
        }
    }

    void CheckInput()
    {
        if (!bCheckInput)
            return;

        float y_diff = ownner.hipsNode.worldPosition.y - pelvisOrign.y;
        isInAir = y_diff > 0.5f;
        if (isInAir)
            return;

        if (gInput.IsAttackPressed())
            ownner.Attack();
        else if (gInput.IsCounterPressed())
            ownner.Counter();
        else if (gInput.IsEvadePressed())
            ownner.Evade();
    }

    bool CanReEntered()
    {
        return !isInAir && bCheckInput;
    }
};

class PlayerHitState : MultiMotionState
{
    PlayerHitState(Character@ c)
    {
        super(c);
        SetName("HitState");
        String hitPrefix = "BM_Combat_HitReaction/";
        AddMotion(hitPrefix + "HitReaction_Face_Right");
        AddMotion(hitPrefix + "Hit_Reaction_SideLeft");
        AddMotion(hitPrefix + "HitReaction_Back");
        AddMotion(hitPrefix + "Hit_Reaction_SideRight");
    }
};

class PlayerGetUpState : CharacterGetUpState
{
    PlayerGetUpState(Character@ c)
    {
        super(c);
        String prefix = "TG_Getup/";
        AddMotion(prefix + "GetUp_Back");
        AddMotion(prefix + "GetUp_Front");
    }
};

class PlayerDeadState : MultiMotionState
{
    Array<String>   animations;
    int             state = 0;

    PlayerDeadState(Character@ c)
    {
        super(c);
        SetName("DeadState");
        String prefix = "BM_Death_Primers/";
        AddMotion(prefix + "Death_Front");
        AddMotion(prefix + "Death_Side_Left");
        AddMotion(prefix + "Death_Back");
        AddMotion(prefix + "Death_Side_Right");
    }

    void Enter(State@ lastState)
    {
        state = 0;
        MultiMotionState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (state == 0)
        {
            if (motions[selectIndex].Move(ownner, dt)) {
                state = 1;
                gGame.OnCharacterKilled(null, ownner);
            }
        }
        else
        {

        }
        CharacterState::Update(dt);
    }
};

class Player : Character
{
    int combo;
    int killed;
    int lastAttackId = -1;

    void ObjectStart()
    {
        side = 1;
        Character::ObjectStart();
        stateMachine.AddState(PlayerStandState(this));
        stateMachine.AddState(PlayerTurnState(this));
        stateMachine.AddState(PlayerMoveState(this));
        stateMachine.AddState(PlayerAttackState(this));
        stateMachine.AddState(PlayerCounterState(this));
        stateMachine.AddState(PlayerEvadeState(this));
        stateMachine.AddState(PlayerHitState(this));
        stateMachine.AddState(PlayerRedirectState(this));
        stateMachine.AddState(AnimationTestState(this));
        stateMachine.AddState(CharacterRagdollState(this));
        stateMachine.AddState(PlayerGetUpState(this));
        stateMachine.AddState(PlayerDeadState(this));
        stateMachine.ChangeState("StandState");

        Node@ _node = sceneNode.CreateChild("TailNode");
        TailGenerator@ tail = _node.CreateComponent("TailGenerator");
        tail.material = cache.GetResource("Material", "Materials/Tail.xml");
        tail.width = 0.5f;
        tail.tailNum = 200;
        tail.SetArcValue(0.1f, 10.0f);
        tail.SetStartColor(Color(0.9f,0.5f,0.2f,1), Color(1.0f,1.0f,1.0f,5.0f));
        tail.SetEndColor(Color(1.0f,0.2f,1.0f,1), Color(1.0f,1.0f,1.0f,5.0f));
        // t.endNodeName = "Bip01";
        tail.enabled = false;

        animModel.skeleton.GetBone("Bip01_Head").animated = false;
    }

    bool Attack()
    {
        stateMachine.ChangeState("AttackState");
        return true;
    }

    bool Counter()
    {
        Print("Player::Counter");
        PlayerCounterState@ state = cast<PlayerCounterState>(stateMachine.FindState("CounterState"));
        if (state is null)
            return false;

        int len = PickCounterEnemy(state.counterEnemies);
        if (len == 0)
            return false;

        stateMachine.ChangeState("CounterState");
        return true;
    }

    bool Evade()
    {
        Print("Player::Evade()");
        Enemy@ redirectEnemy = PickRedirectEnemy();

        if (redirectEnemy !is null)
        {
            PlayerRedirectState@ s = cast<PlayerRedirectState>(stateMachine.FindState("RedirectState"));
            @s.redirectEnemy = redirectEnemy;
            stateMachine.ChangeState("RedirectState");
            redirectEnemy.Redirect();
        }
        else
        {
            // if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
            {
                int index = RadialSelectAnimation(4);
                Print("Evade Index = " + index);
                sceneNode.vars[ANIMATION_INDEX] = index;
                stateMachine.ChangeState("EvadeState");
            }
        }

        return true;
    }

    void CommonStateFinishedOnGroud()
    {
        if (health > 0)
        {
            if (gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
                stateMachine.ChangeState("StandState");
            else {
                stateMachine.ChangeState("MoveState");
            }
        }
        else
        {
            // ..............
        }
    }

    float GetTargetAngle()
    {
        return gInput.m_leftStickAngle + gCameraMgr.GetCameraAngle();
    }

    bool OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        if (!CanBeAttacked()) {
            if (d_log)
                Print("OnDamage failed because I can no be attacked " + GetName());
            return false;
        }

        combo = 0;
        health -= damage;
        int index = RadialSelectAnimation(attacker.GetNode(), 4);
        Print("Player::OnDamage RadialSelectAnimation index=" + index);

        if (health <= 0)
        {
            sceneNode.vars[ANIMATION_INDEX] = index;
            OnDead();
            health = 0;
        }
        else
        {
            sceneNode.vars[ANIMATION_INDEX] = index;
            stateMachine.ChangeState("HitState");
        }
        return true;
    }

    void OnAttackSuccess(Character@ target)
    {
        combo ++;
        Print("combo add to " + combo);

        if (target.health == 0)
        {
            killed ++;
            Print("killed add to " + killed);
            gGame.OnCharacterKilled(this, target);
        }
    }

    //====================================================================
    //      SMART ENEMY PICK FUNCTIONS
    //====================================================================
    Enemy@ PickAttackEnemy()
    {
        uint t = time.systemTime;
        Print("PickAttackEnemy() started");

        Scene@ _scene = GetScene();
        EnemyManager@ em = cast<EnemyManager>(_scene.GetScriptObject("EnemyManager"));
        if (em is null)
            return null;

        // Find the best enemy
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 myDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        float myAngle = Atan2(myDir.x, myDir.z);
        float cameraAngle = gCameraMgr.GetCameraAngle();
        float targetAngle = gInput.m_leftStickAngle + cameraAngle;
        em.scoreCache.Clear();

        Enemy@ attackEnemy = null;
        for (uint i=0; i<em.enemyList.length; ++i)
        {
            Enemy@ e = em.enemyList[i];
            if (!e.CanBeAttacked())
            {
                if (d_log)
                    Print(e.GetName() + " can not be attacked");
                em.scoreCache.Push(-1);
                continue;
            }

            Vector3 posDiff = e.sceneNode.worldPosition - myPos;
            posDiff.y = 0;
            int score = 0;
            float dist = posDiff.length;
            if (dist > MAX_ATTACK_DIST)
            {
                if (d_log)
                    Print(e.GetName() + " far way from player");
                em.scoreCache.Push(-1);
                continue;
            }
            bool isAttacking = false;
            if (e.GetState().nameHash == ATTACK_STATE)
                isAttacking = true;
            float enemyAngle = Atan2(posDiff.x, posDiff.z);
            float diffAngle = targetAngle - enemyAngle;
            diffAngle = AngleDiff(diffAngle);

            if (d_log)
                Print("enemyAngle="+enemyAngle+" targetAngle="+targetAngle+" diffAngle="+diffAngle);

            int threatScore = 0;
            if (isAttacking && dist < 5.0f)
                threatScore += 50;
            int angleScore = int((180.0f - Abs(diffAngle))/180.0f * 30.0f);
            int distScore = int((MAX_ATTACK_DIST - dist) / MAX_ATTACK_DIST * 20.0f);
            score += distScore;
            score += angleScore;
            score += threatScore;

            if (lastAttackId == int(e.sceneNode.id))
            {
                if (diffAngle < 90.0f)
                    score = 100;
            }

            em.scoreCache.Push(score);
            Print("Enemy " + e.sceneNode.name + " dist=" + dist + " diffAngle=" + diffAngle + " score=" + score);
        }

        int bestScore = 0;
        for (uint i=0; i<em.scoreCache.length;++i)
        {
            int score = em.scoreCache[i];
            if (score >= bestScore) {
                bestScore = score;
                @attackEnemy = em.enemyList[i];
            }
        }

        Print("PickAttackEnemy() time-cost = " + (time.systemTime - t) + " ms");
        lastAttackId = (attackEnemy !is null) ? int(attackEnemy.sceneNode.id) : -1;
        return attackEnemy;
    }

    int PickCounterEnemy(Array<Enemy@>@ counterEnemies)
    {
        EnemyManager@ em = cast<EnemyManager>(GetScene().GetScriptObject("EnemyManager"));
        if (em is null)
            return 0;

        counterEnemies.Clear();
        Vector3 myPos = sceneNode.worldPosition;
        for (uint i=0; i<em.enemyList.length; ++i)
        {
            Enemy@ e = em.enemyList[i];
            if (!e.CanBeCountered())
            {
                if (d_log)
                    Print(e.GetName() + " can not be countered");
                continue;
            }
            Vector3 posDiff = e.sceneNode.worldPosition - myPos;
            posDiff.y = 0;
            float distSQR = posDiff.lengthSquared;
            if (distSQR > MAX_COUNTER_DIST * MAX_COUNTER_DIST)
            {
                if (d_log)
                    Print(e.GetName() + " counter distance too long" + distSQR);
                continue;
            }
            counterEnemies.Push(e);
        }

        Print("PickCounterEnemy ret=" + counterEnemies.length);
        return counterEnemies.length;
    }

    Enemy@ PickRedirectEnemy()
    {
        EnemyManager@ em = cast<EnemyManager>(GetScene().GetScriptObject("EnemyManager"));
        if (em is null)
            return null;

        Enemy@ redirectEnemy = null;
        const float bestRedirectDist = 5;
        const float maxRedirectDist = 7;
        const float maxDirDiff = 45;

        float myDir = GetCharacterAngle();
        float bestDistDiff = 9999;

        for (uint i=0; i<em.enemyList.length; ++i)
        {
            Enemy@ e = em.enemyList[i];
            if (!e.CanBeRedirected()) {
                Print("Enemy " + e.GetName() + " can not be redirected.");
                continue;
            }

            float enemyDir = e.GetCharacterAngle();
            float totalDir = Abs(myDir - enemyDir);
            float dirDiff = Abs(totalDir - 180);
            Print("Evade-- myDir=" + myDir + " enemyDir=" + enemyDir + " totalDir=" + totalDir + " dirDiff=" + dirDiff);
            if (dirDiff > maxDirDiff)
                continue;

            float dist = GetTargetDistance(e.sceneNode);
            if (dist > maxRedirectDist)
                continue;

            dist = Abs(dist - bestRedirectDist);
            if (dist < bestDistDiff)
            {
                @redirectEnemy = e;
                dist = bestDistDiff;
            }
        }

        return redirectEnemy;
    }

    String GetDebugText()
    {
        return Character::GetDebugText() +  "health=" + health + " flags=" + flags +
              " combo=" + combo + " killed=" + killed + " timeScale=" + timeScale + "\n";
    }

    void Reset()
    {
        Character::Reset();
        combo = 0;
        killed = 0;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
    }

    void PostUpdate(float dt)
    {

    }
};