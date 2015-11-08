// ==============================================
//
//    Player Pawn and Controller Class
//
// ==============================================

const String MOVEMENT_GROUP = "BM_Combat_Movement/"; //"BM_Combat_Movement/"
bool attack_timing_test = false;
const float MAX_COUNTER_DIST = 6.0f;
const float MAX_ATTACK_DIST = 30.0f;

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
            ownner.sceneNode.vars[ANIMATION_INDEX] = index -1;

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
            // ownner.sceneNode.scene.timeScale = 0.0f;
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
        ownner.sceneNode.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(ownner, dt);

        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            ownner.sceneNode.vars[ANIMATION_INDEX] = 1;
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
        ownner.AddFlag(FLAGS_ATTACK);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_ATTACK);
    }
};

class PlayerEvadeState : MultiMotionState
{
    PlayerEvadeState(Character@ c)
    {
        super(c);
        SetName("EvadeState");
        AddMotion("BM_Combat/Evade_Forward_01");
        AddMotion("BM_Combat/Evade_Back_01");
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

    int                     noEnemyStartIndex = 0;

    bool                    doAttackCheck = false;
    Node@                   attackCheckNode;

    bool                    weakAttack = true;
    bool                    isInAir = false;

    PlayerAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");

        //========================================================================
        // FORWARD
        //========================================================================
        String lHand = "Bip01_L_Hand";
        String rHand = "Bip01_R_Hand";
        String lFoot = "Bip01_L_Foot";
        String rFoot = "Bip01_R_Foot";
        String lArm = "Bip01_L_Forearm";
        String rArm = "Bip01_R_Forearm";
        String lCalf = "Bip01_L_Calf";
        //String rCalf = "Bip01_R_Calf";

        // forward weak
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward", 11, ATTACK_PUNCH, rHand);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_01", 12, ATTACK_PUNCH, lHand);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_02", 12, ATTACK_PUNCH, lHand);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_03", 11, ATTACK_PUNCH, lHand);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_04", 16, ATTACK_PUNCH, rHand);
        AddAttackMotion(forwardAttacks, "Attack_Close_Weak_Forward_05", 12, ATTACK_PUNCH, lHand);

        // forward close
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_02", 14, ATTACK_PUNCH, lHand);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_03", 11, ATTACK_KICK, lFoot);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_04", 19, ATTACK_KICK, rFoot);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_05", 24, ATTACK_PUNCH, lArm);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_06", 20, ATTACK_PUNCH, rHand);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_07", 15, ATTACK_PUNCH, rHand);
        AddAttackMotion(forwardAttacks, "Attack_Close_Forward_08", 18, ATTACK_PUNCH, rArm);
        AddAttackMotion(forwardAttacks, "Attack_Close_Run_Forward", 12, ATTACK_PUNCH, rHand);

        // forward far
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward", 25, ATTACK_PUNCH, rHand);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_01", 17, ATTACK_KICK, rFoot);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_02", 21, ATTACK_KICK, lFoot);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_03", 22, ATTACK_PUNCH, rHand);
        AddAttackMotion(forwardAttacks, "Attack_Far_Forward_04", 22, ATTACK_KICK, rFoot);
        AddAttackMotion(forwardAttacks, "Attack_Run_Far_Forward", 18, ATTACK_KICK, rFoot);

        //========================================================================
        // RIGHT
        //========================================================================
        // right weak
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right", 12, ATTACK_PUNCH, lHand);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_01", 10, ATTACK_PUNCH, rArm);
        AddAttackMotion(rightAttacks, "Attack_Close_Weak_Right_02", 15, ATTACK_PUNCH, rHand);

        // right close
        AddAttackMotion(rightAttacks, "Attack_Close_Right", 16, ATTACK_PUNCH, lHand);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_01", 18, ATTACK_PUNCH, rArm);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_03", 11, ATTACK_PUNCH, lHand);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_04", 19, ATTACK_KICK, rFoot);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_05", 15, ATTACK_KICK, lCalf);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_06", 20, ATTACK_KICK, rFoot);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_07", 18, ATTACK_PUNCH, rArm);
        AddAttackMotion(rightAttacks, "Attack_Close_Right_08", 18, ATTACK_KICK, lFoot);

        // right far
        AddAttackMotion(rightAttacks, "Attack_Far_Right", 25, ATTACK_PUNCH, lHand);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_01", 15, ATTACK_KICK, lCalf);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_02", 21, ATTACK_PUNCH, rHand);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_03", 29, ATTACK_KICK, lFoot);
        AddAttackMotion(rightAttacks, "Attack_Far_Right_04", 22, ATTACK_KICK, rFoot);

        //========================================================================
        // BACK
        //========================================================================
        // back weak
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back", 12, ATTACK_PUNCH, lArm);
        AddAttackMotion(backAttacks, "Attack_Close_Weak_Back_01", 12, ATTACK_PUNCH, rHand);

        AddAttackMotion(backAttacks, "Attack_Close_Back", 11, ATTACK_PUNCH, lArm);
        AddAttackMotion(backAttacks, "Attack_Close_Back_01", 16, ATTACK_PUNCH, lHand);
        AddAttackMotion(backAttacks, "Attack_Close_Back_02", 18, ATTACK_KICK, lFoot);
        AddAttackMotion(backAttacks, "Attack_Close_Back_03", 21, ATTACK_KICK, rFoot);
        AddAttackMotion(backAttacks, "Attack_Close_Back_04", 18, ATTACK_KICK, rFoot);
        AddAttackMotion(backAttacks, "Attack_Close_Back_05", 14, ATTACK_PUNCH, lHand);
        AddAttackMotion(backAttacks, "Attack_Close_Back_06", 15, ATTACK_PUNCH, rHand);
        AddAttackMotion(backAttacks, "Attack_Close_Back_07", 14, ATTACK_PUNCH, lHand);
        AddAttackMotion(backAttacks, "Attack_Close_Back_08", 17, ATTACK_KICK, lFoot);

        // back far
        AddAttackMotion(backAttacks, "Attack_Far_Back", 14, ATTACK_KICK, lFoot);
        AddAttackMotion(backAttacks, "Attack_Far_Back_01", 15, ATTACK_KICK, lFoot);
        AddAttackMotion(backAttacks, "Attack_Far_Back_02", 22, ATTACK_PUNCH, rArm);
        AddAttackMotion(backAttacks, "Attack_Far_Back_03", 22, ATTACK_PUNCH, lHand);
        AddAttackMotion(backAttacks, "Attack_Far_Back_04", 36, ATTACK_KICK, rFoot);

        //========================================================================
        // LEFT
        //========================================================================
        // left weak
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left", 13, ATTACK_PUNCH, rHand);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_01", 12, ATTACK_PUNCH, rHand);
        AddAttackMotion(leftAttacks, "Attack_Close_Weak_Left_02", 13, ATTACK_PUNCH, lHand);

        // left close
        AddAttackMotion(leftAttacks, "Attack_Close_Left", 7, ATTACK_PUNCH, rHand);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_01", 18, ATTACK_PUNCH, rHand);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_02", 13, ATTACK_KICK, rFoot);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_03", 21, ATTACK_KICK, lFoot);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_04", 21, ATTACK_KICK, rFoot);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_05", 15, ATTACK_KICK, lFoot);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_06", 12, ATTACK_KICK, rFoot);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_07", 15, ATTACK_PUNCH, lHand);
        AddAttackMotion(leftAttacks, "Attack_Close_Left_08", 20, ATTACK_KICK, lFoot);


        // left far
        AddAttackMotion(leftAttacks, "Attack_Far_Left", 19, ATTACK_KICK, lFoot);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_01", 22, ATTACK_KICK, rFoot);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_02", 22, ATTACK_PUNCH, rArm);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_03", 21, ATTACK_KICK, lFoot);
        AddAttackMotion(leftAttacks, "Attack_Far_Left_04", 23, ATTACK_KICK, rFoot);

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

        Print("\n forward attacks(closeNum=" + forwadCloseNum + "): \n");
        DumpAttacks(forwardAttacks);
        Print("\n right attacks(closeNum=" + rightCloseNum + "): \n");
        DumpAttacks(rightAttacks);
        Print("\n back attacks(closeNum=" + backCloseNum + "): \n");
        DumpAttacks(backAttacks);
        Print("\n left attacks(closeNum=" + leftCloseNum + "): \n");
        DumpAttacks(leftAttacks);
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

        Node@ tailNode = ownner.sceneNode.GetChild("TailNode", true);
        Node@ attackNode = ownner.sceneNode.GetChild(currentAttack.boneName, true);

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

        if (attackEnemy !is null)
        {
            targetDistance = ownner.GetTargetDistance(attackEnemy.sceneNode);
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

        float y_diff = ownner.hipsNode.worldPosition.y - pelvisOrign.y;
        isInAir = y_diff > 0.5f;
        if (!isInAir)
            CheckInput();

        CharacterState::Update(dt);
    }


    void CheckInput()
    {
        if (state == ATTACK_STATE_AFTER_IMPACT)
        {
            if (gInput.IsAttackPressed())
                ownner.Attack();
        }

        if (gInput.IsCounterPressed())
            ownner.Counter();
        else if (gInput.IsEvadePressed())
            ownner.Evade();
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
        Vector3 myPos = ownner.sceneNode.worldPosition;
        Vector3 enemyPos = attackEnemy.sceneNode.worldPosition;
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
        //alignTime = Min(0.3f, currentAttack.impactTime);
        alignTime = currentAttack.impactTime;

        predictPosition = myPos + diff * toEnenmyDistance;
        Print("Player Pick attack motion = " + currentAttack.motion.animationName);
    }

    void StartAttack()
    {
        if (attackEnemy !is null)
        {
            state = ATTACK_STATE_ALIGN;
            float diff = ownner.ComputeAngleDiff(attackEnemy.sceneNode);
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
            currentAttack = forwardAttacks[noEnemyStartIndex];
            state = ATTACK_STATE_BEFORE_IMPACT;
            ++noEnemyStartIndex;

            if (noEnemyStartIndex > 4)
                noEnemyStartIndex = 0;
        }

        Motion@ motion = currentAttack.motion;
        motion.Start(ownner);
        isInAir = false;

        if (attackEnemy !is null)
        {
            motionPosition = motion.GetFuturePosition(ownner, currentAttack.impactTime);
            movePerSec = ( predictPosition - motionPosition ) / alignTime;
            movePerSec.y = 0;
        }

        if (attack_timing_test)
            ownner.sceneNode.scene.timeScale = 0.0f;

        ownner.EnableComponent("TailNode", "TailGenerator", true);
    }

    void Start()
    {
        ResetValues();
        Player@ p = cast<Player@>(ownner);
        @attackEnemy = p.PickAttackEnemy();
        if (attackEnemy !is null)
             Print("Choose Attack Enemy " + attackEnemy.sceneNode.name);
         else
            Print("No Attack Enemy");
        StartAttack();
    }

    void Enter(State@ lastState)
    {
        Print("################## Player::AttackState Enter from " + lastState.name  + " #####################");
        Start();
        CharacterState::Enter(lastState);
        if (lastState !is this)
            noEnemyStartIndex = 0;
        ownner.AddFlag(FLAGS_ATTACK);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        ownner.EnableComponent("TailNode", "TailGenerator", false);

        if (attackEnemy !is null)
            attackEnemy.RemoveFlag(FLAGS_NO_MOVE);
        @attackEnemy = null;
        @currentAttack = null;
        ownner.RemoveFlag(FLAGS_ATTACK);
        Print("################## Player::AttackState Exit to " + nextState.name  + " #####################");
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        CharacterState::OnAnimationTrigger(animState, eventData);
        StringHash name = eventData[NAME].GetStringHash();
        if (name == TIME_SCALE) {
            float scale = eventData[VALUE].GetFloat();
            SetWorldTimeScale(ownner.sceneNode, scale);
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
                attackCheckNode = ownner.sceneNode.GetChild(eventData[BONE].GetString(), true);
                Print("Player AttackCheck bone=" + attackCheckNode.name);
                AttackCollisionCheck();
            }
        }
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentAttack is null || attackEnemy is null)
            return;
        debug.AddLine(ownner.sceneNode.worldPosition, attackEnemy.sceneNode.worldPosition, Color(0.27f, 0.28f, 0.7f), false);
        debug.AddCross(predictPosition, 0.5f, Color(0.25f, 0.28f, 0.7f), false);
        debug.AddCross(motionPosition, 0.5f, Color(0.75f, 0.28f, 0.27f), false);
    }

    String GetDebugText()
    {
        String r = CharacterState::GetDebugText();
        r += "\ncurrentAttack=" + currentAttack.motion.animationName + " distToEnemy=" + targetDistance;
        return r;
    }

    void AttackCollisionCheck()
    {
        if (attackCheckNode is null) {
            doAttackCheck = false;
            return;
        }

        Character@ target = attackEnemy;
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

    bool CanReEntered()
    {
        return true;
    }

    void AttackImpact()
    {
        if (attack_timing_test)
            ownner.sceneNode.scene.timeScale = 0.0f;

        if (attackEnemy is null)
            return;

        Vector3 dir = ownner.sceneNode.worldPosition - attackEnemy.sceneNode.worldPosition;
        dir.y = 0;
        dir.Normalize();
        Print("PlayerAttackState::" +  attackEnemy.GetName() + " OnDamage!!!!");
        //ownner.sceneNode.scene.timeScale = 0.0f;

        Node@ n = ownner.sceneNode.GetChild(currentAttack.boneName, true);
        Vector3 position = ownner.sceneNode.worldPosition;
        if (n !is null)
            position = n.worldPosition;

        attackEnemy.OnDamage(ownner, position, dir, ownner.attackDamage, weakAttack);
        ownner.SpawnParticleEffect(position, "Particle/SnowExplosion.xml", 5, 5.0f);
        ownner.OnAttackSuccess();
        weakAttack = cast<Player@>(ownner).combo < 3;

        if (currentAttack.type == ATTACK_PUNCH)
        {
            int i = RandomInt(6) + 1;
            String name = "Sfx/punch_0" + i + ".ogg";
            ownner.PlaySound(name);
        }
        else
        {
            int i = RandomInt(6) + 1;
            String name = "Sfx/kick_0" + i + ".ogg";
            ownner.PlaySound(name);
        }
    }
};


class PlayerCounterState : CharacterCounterState
{
    Enemy@              counterEnemy;
    float               alignTime = 0.3f;
    Vector3             movePerSec;
    float               yawPerSec;
    Vector3             targetPosition;

    PlayerCounterState(Character@ c)
    {
        super(c);
        AddCounterMotions("BM_TG_Counter/");
        // Dump();
    }

    ~PlayerCounterState()
    {
    }

    void Update(float dt)
    {
        Node@ _node = ownner.sceneNode;
        if (state == 0) {

            _node.Yaw(yawPerSec * dt);
            ownner.MoveTo(_node.worldPosition + movePerSec * dt, dt);

            if (timeInState >= alignTime) {
                ownner.sceneNode.worldPosition = targetPosition;
                StartCounterMotion();
                CharacterCounterState@ enemyCounterState = cast<CharacterCounterState@>(counterEnemy.GetState());
                enemyCounterState.StartCounterMotion();
            }
        }
        else {
             if (currentMotion.Move(ownner, dt)) {
                ownner.CommonStateFinishedOnGroud();
                return;
             }

        }

        CharacterCounterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        Node@ enemyNode = counterEnemy.sceneNode;
        Node@ myNode = ownner.sceneNode;

        state = 0;
        float dAngle = ownner.ComputeAngleDiff(enemyNode);
        bool isBack = false;
        if (Abs(dAngle) > 90)
            isBack = true;
        Print("Counter-align angle-diff=" + dAngle + " isBack=" + isBack);

        int attackType = enemyNode.vars[ATTACK_TYPE].GetInt();

        CharacterCounterState@ enemyCounterState = cast<CharacterCounterState@>(counterEnemy.stateMachine.FindState("CounterState"));
        if (enemyCounterState is null)
            return;

        Vector3 myPos = myNode.worldPosition;
        Vector3 enemyPos = enemyNode.worldPosition;
        Vector3 currentPositionDiff = enemyPos - myPos;
        currentPositionDiff.y = 0;

        Array<Motion@>@ counterMotions = GetCounterMotions(attackType, isBack);
        Array<Motion@>@ enemyCounterMotions = enemyCounterState.GetCounterMotions(attackType, isBack);

        int idx = RandomInt(counterMotions.length);
        @currentMotion = counterMotions[idx];
        @enemyCounterState.currentMotion = enemyCounterMotions[idx];

        float rotationDiff = isBack ? 0 : 180;
        float enemyYaw = enemyNode.worldRotation.eulerAngles.y;
        float targetRotation = enemyYaw + rotationDiff;
        float myRotation = myNode.worldRotation.eulerAngles.y;
        Vector3 s1 = currentMotion.startFromOrigin;
        Vector3 s2 = enemyCounterState.currentMotion.startFromOrigin;
        Vector3 originDiff = s1 - s2;
        originDiff.x = Abs(originDiff.x);
        originDiff.z = Abs(originDiff.z);

        if (isBack)
            enemyYaw += 180;
        targetPosition = enemyPos + enemyNode.worldRotation * originDiff;
        targetPosition.y = myPos.y;

        Vector3 positionDiff = targetPosition - myPos;
        rotationDiff = AngleDiff(targetRotation - myRotation);

        Print("positionDiff=" + positionDiff.ToString() + " rotationDiff=" + rotationDiff + " s1=" + s1.ToString() + " s2=" + s2.ToString() + " originDiff=" + originDiff.ToString());

        yawPerSec = rotationDiff / alignTime;
        movePerSec = positionDiff / alignTime;
        movePerSec.y = 0;

        CharacterCounterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        @counterEnemy = null;
        @currentMotion = null;
        CharacterCounterState::Exit(nextState);
    }

    String GetDebugText()
    {
        String r = CharacterCounterState::GetDebugText();
        r += "\ncurrent motion=" + currentMotion.animationName;
        return r;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(targetPosition, 0.25f, Color(0, 1, 0), false);
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
        AddMotion(hitPrefix + "Hit_Reaction_SideRight");
        AddMotion(hitPrefix + "HitReaction_Back");
        AddMotion(hitPrefix + "Hit_Reaction_SideLeft");
        AddMotion(hitPrefix + "HitReaction_Stomach");
        AddMotion(hitPrefix + "BM_Hit_Reaction");
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

class Player : Character
{
    int combo;

    Player()
    {
        super();
    }

    void ObjectStart()
    {
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
        stateMachine.ChangeState("StandState");

        Node@ _node = sceneNode.CreateChild("TailNode");
        TailGenerator@ t = _node.CreateComponent("TailGenerator");
        t.material = cache.GetResource("Material", "Materials/Tail.xml");
        t.width = 0.5f;
        t.tailNum = 200;
        t.SetArcValue(0.1f, 10.0f);
        t.SetStartColor(Color(0.9f,0.5f,0.2f,1), Color(1.0f,1.0f,1.0f,5.0f));
        t.SetEndColor(Color(1.0f,0.2f,1.0f,1), Color(1.0f,1.0f,1.0f,5.0f));
        // t.endNodeName = "Bip01";
        t.enabled = false;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        float cameraAngle = gCameraMgr.GetCameraAngle();
        float targetAngle = cameraAngle + gInput.m_leftStickAngle;
        float baseLen = 2.0f;
        DebugDrawDirection(debug, sceneNode, targetAngle, Color(1, 1, 0), baseLen);
        Character::DebugDraw(debug);
    }

    bool Attack()
    {
        stateMachine.ChangeState("AttackState");
        return true;
    }

    bool Counter()
    {
        Print("Player::Counter");
        Enemy@ counterEnemy = PickCounterEnemy();
        if (counterEnemy is null)
            return false;

        Print("Choose Couter Enemy " + counterEnemy.sceneNode.name);
        PlayerCounterState@ state = cast<PlayerCounterState@>(stateMachine.FindState("CounterState"));
        if (state is null)
            return false;
        @state.counterEnemy = counterEnemy;
        stateMachine.ChangeState("CounterState");
        counterEnemy.stateMachine.ChangeState("CounterState");
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
            if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
            {
                sceneNode.vars[ANIMATION_INDEX] = RadialSelectAnimation(2);
                stateMachine.ChangeState("EvadeState");
            }
        }

        return true;
    }

    void CommonStateFinishedOnGroud()
    {
        if (gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
            stateMachine.ChangeState("StandState");
        else {
            stateMachine.ChangeState("MoveState");
        }
    }

    float GetTargetAngle()
    {
        return gInput.m_leftStickAngle + gCameraMgr.GetCameraAngle();
    }

    void OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        if (!CanBeAttacked()) {
            Print("OnDamage failed because I can no be attacked " + GetName());
            return;
        }

        combo = 0;
        health -= damage;
        if (health <= 0)
        {
            OnDead();
            health = 0;
        }
        else
        {
            Node@ attackNode = attacker.GetNode();
            float diff = ComputeAngleDiff(attackNode);
            int r = DirectionMapToIndex(diff, 4);
            int attackType = attackNode.vars[ATTACK_TYPE].GetInt();
            // flip left and right
            if (r == 1)
                r = 3;
            if (r == 3)
                r = 1;
            int index = r;
            /*if (index == 0)
            {
                if (attackType == ATTACK_KICK)
                {
                    index = 4 + RandomInt(2);
                }
            }*/
            sceneNode.vars[ANIMATION_INDEX] = index;
            stateMachine.ChangeState("HitState");
        }
    }

    void OnAttackSuccess()
    {
        combo ++;
        Print("combo add to " + combo);
    }

    //====================================================================
    //      SMART ENEMY PICK FUNCTIONS
    //====================================================================
    Enemy@ PickAttackEnemy()
    {
        uint t = time.systemTime;
        Print("PickAttackEnemy() started");

        EnemyManager@ em = cast<EnemyManager@>(sceneNode.scene.GetScriptObject("EnemyManager"));
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
                Print(e.GetName() + " far way from player");
                em.scoreCache.Push(-1);
                continue;
            }
            float enemyAngle = Atan2(posDiff.x, posDiff.z);
            float diffAngle = targetAngle - enemyAngle;
            diffAngle = AngleDiff(diffAngle);
            Print("enemyAngle="+enemyAngle+" targetAngle="+targetAngle+" diffAngle="+diffAngle);
            int angleScore = int((180.0f - Abs(diffAngle))/180.0f * 80.0f);
            int distScore = int((MAX_ATTACK_DIST - dist) / MAX_ATTACK_DIST) * 20.0f;
            score += distScore;
            score += angleScore;
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
        return attackEnemy;
    }

    Enemy@ PickCounterEnemy()
    {
        EnemyManager@ em = cast<EnemyManager@>(sceneNode.scene.GetScriptObject("EnemyManager"));
        if (em is null)
            return null;

        Vector3 myPos = sceneNode.worldPosition;
        Vector3 myDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        float myAngle = Atan2(myDir.x, myDir.z);
        float curDistSQR = 999999;
        Vector3 curPosDiff;

        Enemy@ counterEnemy = null;

        for (uint i=0; i<em.enemyList.length; ++i)
        {
            Enemy@ e = em.enemyList[i];
            if (!e.CanBeCountered())
            {
                Print(e.GetName() + " can not be countered");
                continue;
            }
            Vector3 posDiff = e.sceneNode.worldPosition - myPos;
            posDiff.y = 0;
            float distSQR = posDiff.lengthSquared;
            if (distSQR > MAX_COUNTER_DIST * MAX_COUNTER_DIST)
            {
                Print(distSQR);
                continue;
            }
            if (curDistSQR > distSQR)
            {
                @counterEnemy = e;
                curDistSQR = distSQR;
                curPosDiff = posDiff;
            }
        }

        return counterEnemy;
    }

    Enemy@ PickRedirectEnemy()
    {
        EnemyManager@ em = cast<EnemyManager@>(sceneNode.scene.GetScriptObject("EnemyManager"));
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
        return Character::GetDebugText() +  "flags=" + flags + " combo=" + combo + " timeScale=" + timeScale + "\n";
    }

    String GetHintText()
    {
        return sceneNode.name + " state=" + stateMachine.currentState.name + " combo=" + combo;
    }
};