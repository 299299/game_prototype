
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
        }
        ownner.PlayAnimation(animations[RandomInt(animations.length)], LAYER_MOVE, true, blendTime);
        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.sceneNode.vars[ANIMATION_INDEX] = index -1;

            if (index == 0)
                ownner.stateMachine.ChangeState("MoveState");
            else
                ownner.stateMachine.ChangeState("TurnState");
        }

        if (gInput.IsAttackPressed())
            ownner.Attack();
        else if (gInput.IsCounterPressed())
            ownner.Counter();
        else if (gInput.IsEvadePressed())
            ownner.Evade();

        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        ownner.SetVelocity(Vector3(0, 0, 0));
        CharacterState::FixedUpdate(dt);
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
        turnSpeed = 0.0f;
    }

    void Update(float dt)
    {
        if (gInput.IsAttackPressed())
            ownner.Attack();
        else if (gInput.IsCounterPressed())
            ownner.Counter();
        else if (gInput.IsEvadePressed())
            ownner.Evade();
        MultiMotionState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        ownner.sceneNode.Yaw(turnSpeed * dt);
        MultiMotionState::FixedUpdate(dt);
    }

    void Enter(State@ lastState)
    {
        MultiMotionState::Enter(lastState);
        Motion@ motion = motions[selectIndex];
        Vector4 endKey = motion.GetKey(motion.endTime);
        float motionTargetAngle = motion.startRotation + endKey.w;
        float targetAngle = ownner.GetTargetAngle();
        float diff = AngleDiff(targetAngle - motionTargetAngle);
        turnSpeed = diff / motion.endTime;
        Print("motionTargetAngle=" + String(motionTargetAngle) + " targetAngle=" + String(targetAngle) + " diff=" + String(diff) + " turnSpeed=" + String(turnSpeed));
    }
};

class PlayerMoveState : SingleMotionState
{
    float turnSpeed;

    PlayerMoveState(Character@ c)
    {
        super(c);
        SetName("MoveState");
        SetMotion(MOVEMENT_GROUP + "Walk_Forward");
        turnSpeed = 5;
    }

    void Update(float dt)
    {
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
            ownner.stateMachine.ChangeState("StandState");

        if (gInput.IsAttackPressed())
            ownner.Attack();
        else if (gInput.IsCounterPressed())
            ownner.Counter();
        else if (gInput.IsEvadePressed())
            ownner.Evade();

        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        ownner.sceneNode.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(ownner, dt);

        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            ownner.sceneNode.vars[ANIMATION_INDEX] = 1;
            ownner.stateMachine.ChangeState("TurnState");
        }

        CharacterState::FixedUpdate(dt);
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

class PlayerAttackState : CharacterState
{
    Array<AttackMotion@>  forwardAttacks;
    Array<AttackMotion@>  leftAttacks;
    Array<AttackMotion@>  rightAttacks;
    Array<AttackMotion@>  backAttacks;

    AttackMotion@   currentAttack;
    Enemy@          attackEnemy;

    int             state;
    Vector3         movePerSec;
    float           targetAngle;
    float           targetDistance;

    int             forwadCloseNum;
    int             leftCloseNum;
    int             rightCloseNum;
    int             backCloseNum;

    PlayerAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");

        String preFix = "BM_Attack/";

        forwadCloseNum = 14;
        leftCloseNum = 12;
        rightCloseNum = 11;
        backCloseNum = 11;

        //========================================================================
        // FORWARD
        //========================================================================
        // forward weak
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward", 11));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward_01", 12));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward_02", 12));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward_03", 11));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward_04", 16));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward_05", 12));

        // forward close
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_02", 14));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_03", 11));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_04", 19));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_05", 24));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_06", 20));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_07", 15));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_08", 18));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Run_Forward", 12));

        // forward far
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Far_Forward", 25));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Far_Forward_01", 17));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Far_Forward_02", 21));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Far_Forward_03", 22));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Far_Forward_04", 22));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Run_Far_Forward", 14));

        //========================================================================
        // RIGHT
        //========================================================================
        // right weak
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Right", 12));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Right_01", 10));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Right_02", 15));

        // right close
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right", 16));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_01", 18));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_03", 11));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_04", 19));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_05", 15));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_06", 20));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_07", 18));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_08", 18));

        // right far
        rightAttacks.Push(AttackMotion(preFix + "Attack_Far_Right", 25));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Far_Right_01", 15));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Far_Right_02", 21));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Far_Right_03", 29));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Far_Right_04", 22));

        //========================================================================
        // BACK
        //========================================================================
        // back weak
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Back", 12));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Back_01", 12));

        // back close
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back", 9));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_01", 16));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_02", 18));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_03", 21));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_04", 18));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_05", 14));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_06", 15));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_07", 14));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_08", 17));

        // back far
        backAttacks.Push(AttackMotion(preFix + "Attack_Far_Back", 14));
        backAttacks.Push(AttackMotion(preFix + "Attack_Far_Back_01", 15));
        backAttacks.Push(AttackMotion(preFix + "Attack_Far_Back_02", 18));
        backAttacks.Push(AttackMotion(preFix + "Attack_Far_Back_03", 22));
        backAttacks.Push(AttackMotion(preFix + "Attack_Far_Back_04", 36));

        //========================================================================
        // LEFT
        //========================================================================
        // left weak
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Left", 13));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Left_01", 12));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Left_02", 13));

        // left close
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left", 7));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_01", 18));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_02", 13));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_03", 21));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_04", 21));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_05", 15));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_06", 12));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_07", 15));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_08", 20));

        // left far
        leftAttacks.Push(AttackMotion(preFix + "Attack_Far_Left", 19));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Far_Left_01", 22));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Far_Left_02", 22));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Far_Left_03", 21));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Far_Left_04", 23));

        forwardAttacks.Sort();
        leftAttacks.Sort();
        rightAttacks.Sort();
        backAttacks.Sort();

        Print("\nAfter sort forward attack motions:\n");
        DumpAttacks(forwardAttacks);

        Print("\nAfter sort right attack motions:\n");
        DumpAttacks(rightAttacks);

        Print("\nAfter sort back attack motions:\n");
        DumpAttacks(backAttacks);

        Print("\nAfter sort left attack motions:\n");
        DumpAttacks(leftAttacks);
    }

    void DumpAttacks(const Array<AttackMotion@>&in attacks)
    {
        for (uint i=0; i<attacks.length; ++i)
            Print(attacks[i].motion.animationName + " impactDist=" + String(attacks[i].impactDist));
    }

    ~PlayerAttackState()
    {
        @attackEnemy = null;
        @currentAttack = null;
    }

    void Update(float dt)
    {
        if (currentAttack is null)
            return;

        Motion@ motion = currentAttack.motion;
        if (attackEnemy !is null)
        {
            targetAngle = ownner.GetTargetAngle(attackEnemy.sceneNode);
            targetDistance = ownner.GetTargetDistance(attackEnemy.sceneNode);

            if (motion.translateEnabled && targetDistance < COLLISION_SAFE_DIST)
                motion.translateEnabled = false;
        }

        float t = ownner.animCtrl.GetTime(motion.animationName);
        if (state == 0)
        {
            if (t >= currentAttack.slowMotionTime.x) {
                state = 1;
                SetWorldTimeScale(ownner.sceneNode.scene, 0.25f);
            }
        }
        else if (state == 1)
        {
            if (attack_timing_test)
            {
                if (t < currentAttack.impactTime && ((t + dt) > currentAttack.impactTime))
                    ownner.sceneNode.scene.timeScale = 0.0f;
            }

            if (t >= currentAttack.slowMotionTime.y) {
                state = 2;
                SetWorldTimeScale(ownner.sceneNode.scene, 1.0f);
            }
        }

        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        Motion@ motion = currentAttack.motion;

        if (state != 2)
            motion.deltaPosition += movePerSec * dt;

        bool finished = motion.Move(ownner, dt);
        if (finished) {
            ownner.CommonStateFinishedOnGroud();
        }

        CharacterState::FixedUpdate(dt);
    }

    AttackMotion@ GetAttack(int dir, int index)
    {
        if (dir == 0)
            return forwardAttacks[index];
        else if (dir == 1)
            return rightAttacks[index];
        else if (dir == 2)
            return backAttacks[index];
        else
            return leftAttacks[index];
    }

    void ResetValues()
    {
        @currentAttack = null;
        @attackEnemy = null;
        state = 0;
        movePerSec = Vector3(0, 0, 0);
        targetAngle = 0.0f;
        targetDistance = 0.0f;
    }

    void PickBestMotion(const Array<AttackMotion@>&in attacks, int dir)
    {
        Vector3 myPos = ownner.sceneNode.worldPosition;
        Vector3 enemyPos = attackEnemy.sceneNode.worldPosition;
        Quaternion myRot = ownner.sceneNode.worldRotation;
        float yaw = myRot.eulerAngles.y;
        Vector3 enemyDir = enemyPos - myPos;
        float enemyDist = enemyDir.length;
        enemyDir.Normalize();

        float minDistance = 99999;
        float bestRange = 0;
        int bestIndex = -1;
        float baseDist = COLLISION_RADIUS * 1.75f;

        for (int i=attacks.length-1; i>=0; --i)
        {
            AttackMotion@ attack = attacks[i];
            float farRange = attack.impactDist + baseDist;
            Print("farRange = " + farRange + " enemyDist=" + enemyDist);
            if (farRange < enemyDist) {
                bestIndex = i;
                bestRange = farRange;
                break;
            }
        }

        if (bestIndex < 0) {
            Print("bestIndex is -1 !!!");
            if (dir == 0)
                bestIndex = RandomInt(forwadCloseNum);
            else if (dir == 1)
                bestIndex = RandomInt(rightCloseNum);
            else if (dir == 2)
                bestIndex = RandomInt(backCloseNum);
            else if (dir == 3)
                bestIndex = RandomInt(leftCloseNum);
        }

        @currentAttack = attacks[bestIndex];

        Vector3 predictPosition = myPos + enemyDir * (enemyDist -  COLLISION_SAFE_DIST);
        Vector3 futurePos = currentAttack.motion.GetFuturePosition(ownner.sceneNode, currentAttack.impactTime);
        movePerSec = ( predictPosition - futurePos ) / currentAttack.impactTime;

        Print("Player Pick attack motion = " + currentAttack.motion.animationName + " movePerSec=" + movePerSec.ToString());
    }

    void StartAttack()
    {
        if (attackEnemy !is null)
        {
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
        }
        else {
            currentAttack = forwardAttacks[RandomInt(forwadCloseNum)];
        }

        Motion@ motion = currentAttack.motion;
        motion.Start(ownner);
        state = 0;

        if (attack_timing_test)
            ownner.sceneNode.scene.timeScale = 0.0f;
    }

    void Start()
    {
        ResetValues();
        Player@ p = cast<Player@>(ownner);
        @attackEnemy = p.PickAttackEnemy();
        if (attackEnemy !is null)
             Print("Choose Attack Enemy " + attackEnemy.sceneNode.name);
        StartAttack();
    }

    void Enter(State@ lastState)
    {
        Start();
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        @attackEnemy = null;
        @currentAttack = null;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentAttack is null)
            return;
        debug.AddLine(ownner.sceneNode.worldPosition, attackEnemy.sceneNode.worldPosition, Color(0.7f, 0.8f, 0.7f), false);
        DebugDrawDirection(debug, ownner.sceneNode, targetAngle, Color(1, 0, 0), 2);
    }

    String GetDebugText()
    {
        String r = CharacterState::GetDebugText();
        r += "\ncurrentAttack=" + currentAttack.motion.animationName + " distToEnemy=" + targetDistance;
        return r;
    }
};


class PlayerCounterState : CharacterCounterState
{
    Enemy@              counterEnemy;
    float               alignTime;
    Vector3             movePerSec;
    float               yawPerSec;
    Vector3             targetPosition;

    PlayerCounterState(Character@ c)
    {
        super(c);
        alignTime = 0.2f;
        AddCounterMotions("BM_TG_Counter/");
        // Dump();
    }

    ~PlayerCounterState()
    {
    }

    void Update(float dt)
    {
        if (state == 0) {
            if (timeInState >= alignTime) {
                ownner.sceneNode.worldPosition = targetPosition;
                StartCounterMotion();
                CharacterCounterState@ enemyCounterState = cast<CharacterCounterState@>(counterEnemy.GetState());
                enemyCounterState.StartCounterMotion();
                // scene_.timeScale = 0.0f;
            }
        }
        CharacterCounterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        Node@ _node = ownner.sceneNode;
        if (state == 0) {
            _node.Yaw(yawPerSec * dt);
            if (ownner.IsPhysical())
                ownner.SetVelocity(movePerSec);
            else
                ownner.MoveTo(_node.worldPosition + movePerSec * dt, dt);
        }
        else {
            if (currentMotion.Move(ownner, dt))
                ownner.CommonStateFinishedOnGroud();
        }

        CharacterCounterState::FixedUpdate(dt);
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

        Vector3 currentPositionDiff = enemyNode.worldPosition - myNode.worldPosition;
        currentPositionDiff.y = 0;
        if (attackType == 0)
        {
            if (isBack)
            {
                //int idx = QueryBestCounterMotion(backArmMotions, enemyCounterState.backArmMotions, currentPositionDiff);
                int idx = RandomInt(backArmMotions.length);
                @currentMotion = backArmMotions[idx];
                @enemyCounterState.currentMotion = enemyCounterState.backArmMotions[idx];
            }
            else
            {
                //int idx = QueryBestCounterMotion(frontArmMotions, enemyCounterState.frontArmMotions, currentPositionDiff);
                int idx = RandomInt(frontArmMotions.length);
                @currentMotion = frontArmMotions[idx];
                @enemyCounterState.currentMotion = enemyCounterState.frontArmMotions[idx];
            }
        }
        else
        {
            if (isBack)
            {
                //int idx = QueryBestCounterMotion(backLegMotions, enemyCounterState.backLegMotions, currentPositionDiff);
                int idx = RandomInt(backLegMotions.length);
                @currentMotion = backLegMotions[idx];
                @enemyCounterState.currentMotion = enemyCounterState.backLegMotions[idx];
            }
            else
            {
                //int idx = QueryBestCounterMotion(frontLegMotions, enemyCounterState.frontLegMotions, currentPositionDiff);
                int idx = RandomInt(frontLegMotions.length);
                // idx = FindMotionIndex(frontLegMotions, "BM_TG_Counter/Counter_Leg_Back_Weak_03");
                @currentMotion = frontLegMotions[idx];
                @enemyCounterState.currentMotion = enemyCounterState.frontLegMotions[idx];
            }
        }

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
        targetPosition = enemyNode.worldPosition + enemyNode.worldRotation * originDiff;

        Vector3 positionDiff = targetPosition - myNode.worldPosition;
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
        AddMotion(hitPrefix + "HitReaction_Face_Left");
        AddMotion(hitPrefix + "HitReaction_Face_Right");
        AddMotion(hitPrefix + "Hit_Reaction_SideLeft");
        AddMotion(hitPrefix + "Hit_Reaction_SideRight");
        AddMotion(hitPrefix + "HitReaction_Stomach");
    }
};

class Player : Character
{
    int combo;

    Player()
    {
        super();
        combo = 0;
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
        stateMachine.ChangeState("StandState");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        float cameraAngle = gCameraMgr.GetCameraAngle();
        float targetAngle = cameraAngle + gInput.m_leftStickAngle;
        float baseLen = 2.0f;
        DebugDrawDirection(debug, sceneNode, targetAngle, Color(1, 1, 0), baseLen);
        Character::DebugDraw(debug);
    }

    void Attack()
    {
        stateMachine.ChangeState("AttackState");
    }

    void Counter()
    {
        Print("Player::Counter");
        Enemy@ counterEnemy = PickCounterEnemy();
        if (counterEnemy is null)
            return;

        Print("Choose Couter Enemy " + counterEnemy.sceneNode.name);
        PlayerCounterState@ state = cast<PlayerCounterState@>(stateMachine.FindState("CounterState"));
        if (state is null)
            return;
        @state.counterEnemy = counterEnemy;
        stateMachine.ChangeState("CounterState");
        counterEnemy.stateMachine.ChangeState("CounterState");
    }



    void Evade()
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
    }

    void Hit()
    {

    }

    bool CanBeAttacked()
    {
        return true;
    }

    bool CanBeCountered()
    {
        return false;
    }

    String GetDebugText()
    {
        return Character::GetDebugText() +  "flags=" + flags + " combo=" + combo + "\n";
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

    //====================================================================
    //      SMART ENEMY PICK FUNCTIONS
    //====================================================================
    Enemy@ PickAttackEnemy()
    {
        // Find the best enemy
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 myDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        float myAngle = Atan2(myDir.x, myDir.z);
        float cameraAngle = gCameraMgr.GetCameraAngle();
        float targetAngle = gInput.m_leftStickAngle + cameraAngle;
        gEnemyMgr.scoreCache.Clear();

        Enemy@ attackEnemy = null;
        Print("Attack targetAngle=" + targetAngle);

        for (uint i=0; i<gEnemyMgr.enemyList.length; ++i)
        {
            Enemy@ e = gEnemyMgr.enemyList[i];
            Vector3 posDiff = e.sceneNode.worldPosition - myPos;
            posDiff.y = 0;
            int score = 0;
            float distSQR = posDiff.lengthSquared;
            // Print(" distSQR=" + distSQR);
            if (distSQR > MAX_ATTACK_DIST * MAX_ATTACK_DIST || !e.CanBeAttacked())
            {
                gEnemyMgr.scoreCache.Push(-1);
                continue;
            }
            float diffAngle = Abs(Atan2(posDiff.x, posDiff.z));
            int angleScore = int((180.0f - diffAngle)/180.0f * 50.0f); // angle at 50% percant
            score += angleScore;
            gEnemyMgr.scoreCache.Push(score);
            Print("Enemy " + e.sceneNode.name + " distSQR=" + distSQR + " diffAngle=" + diffAngle + " score=" + score);
        }

        int bestScore = 0;
        for (uint i=0; i<gEnemyMgr.scoreCache.length;++i)
        {
            int score = gEnemyMgr.scoreCache[i];
            if (score >= bestScore) {
                bestScore = score;
                @attackEnemy = gEnemyMgr.enemyList[i];
            }
        }

        return attackEnemy;
    }

    Enemy@ PickCounterEnemy()
    {
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 myDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        float myAngle = Atan2(myDir.x, myDir.z);
        float curDistSQR = 999999;
        Vector3 curPosDiff;

        Enemy@ counterEnemy = null;

        for (uint i=0; i<gEnemyMgr.enemyList.length; ++i)
        {
            Enemy@ e = gEnemyMgr.enemyList[i];
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
        Enemy@ redirectEnemy = null;
        const float bestRedirectDist = 5;
        const float maxRedirectDist = 7;
        const float maxDirDiff = 45;

        float myDir = GetCharacterAngle();
        float bestDistDiff = 9999;

        for (uint i=0; i<gEnemyMgr.enemyList.length; ++i)
        {
            Enemy@ e = gEnemyMgr.enemyList[i];
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
};