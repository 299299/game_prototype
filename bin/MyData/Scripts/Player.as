
const String movement_group = "BM_Combat_Movement/"; //"BM_Combat_Movement/"
bool attack_timing_test = false;
const float ATTACK_SAFE_DIST = 3;

class PlayerStandState : RandomAnimationState
{
    PlayerStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        animations.Push(GetAnimationName(movement_group + "Stand_Idle"));
        animations.Push(GetAnimationName(movement_group + "Stand_Idle_01"));
        animations.Push(GetAnimationName(movement_group + "Stand_Idle_02"));
    }

    void Enter(State@ lastState)
    {
        float blendTime = 0.25f;
        if (lastState !is null)
        {
            if (lastState.name == "AttackState")
                blendTime = 10.0f;
            if (lastState.name == "RedirectState")
                blendTime = 2.5f;
        }
        StartBlendTime(blendTime);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1))
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.sceneNode.vars["AnimationIndex"] = index -1;

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

        RandomAnimationState::Update(dt);
    }
};

class PlayerTurnState : MultiMotionState
{
    float turnSpeed;

    PlayerTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        AddMotion(movement_group + "Turn_Right_90");
        AddMotion(movement_group + "Turn_Right_180");
        AddMotion(movement_group + "Turn_Left_90");
        turnSpeed = 0.0f;
    }

    void Update(float dt)
    {
        Motion@ motion = motions[selectIndex];

        motion.deltaRotation += dt * turnSpeed;
        // Print("deltaRotation = " + String(motion.deltaRotation));

        if (motion.Move(dt, ownner.sceneNode, ownner.animCtrl))
        {
            float characterDifference = ownner.ComputeAngleDiff();
            if ( (Abs(characterDifference) > fullTurnThreashold) && gInput.IsLeftStickStationary() )
            {
                ownner.sceneNode.vars["AnimationIndex"] = 1;
                ownner.stateMachine.ChangeState("TurnState");
            }
            else
            {
                ownner.CommonStateFinishedOnGroud();
            }
        }

        MultiMotionState::Update(dt);
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
        SetMotion(movement_group + "Walk_Forward");
        turnSpeed = 5;
    }

    void Update(float dt)
    {
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1))
            ownner.stateMachine.ChangeState("StandState");

        float characterDifference = ownner.ComputeAngleDiff();

        ownner.sceneNode.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(dt, ownner.sceneNode, ownner.animCtrl);

        if(gInput.IsEvadePressed())
            ownner.Evade();
        else
        {
            // if the difference is large, then turn 180 degrees
            if ( (Abs(characterDifference) > fullTurnThreashold) && gInput.IsLeftStickStationary() )
            {
                ownner.sceneNode.vars["AnimationIndex"] = 1;
                ownner.stateMachine.ChangeState("TurnState");
            }
        }

        CharacterState::Update(dt);
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

    void Update(float dt)
    {
        MultiMotionState::Update(dt);
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

    void Update(float dt)
    {
        SingleMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        @redirectEnemy = null;
        SingleMotionState::Exit(nextState);
    }
};

class PlayerAlignState : CharacterAlignState
{
    PlayerAlignState(Character@ c)
    {
        super(c);
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

    int             status;

    Vector3         predictPosition;
    Vector3         predictEnemyPosition;
    Vector3         movePosPerSec;
    Vector3         predictMotionPosition;

    float           targetAngle;
    float           targetDistance;

    bool            standBy;

    PlayerAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");

        String preFix = "BM_Attack/";

        //========================================================================
        // FORWARD
        //========================================================================
        // forward weak
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward", 11));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward_01", 12));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward_03", 11));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward_04", 16));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Forward_05", 12));

        // forward close
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_04", 19));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_05", 24));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Forward_06", 20));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Close_Run_Forward", 12));

        // forward far
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Far_Forward_01", 17));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Far_Forward_02", 21));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Far_Forward_03", 22));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Far_Forward_04", 22));
        forwardAttacks.Push(AttackMotion(preFix + "Attack_Run_Far_Forward", 14));

        //========================================================================
        // RIGHT
        //========================================================================
        // right weak
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Right_01", 10));

        // right close
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right", 16));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_01", 18));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_03", 11));
        rightAttacks.Push(AttackMotion(preFix + "Attack_Close_Right_05", 15));
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
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_05", 14));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_06", 15));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_07", 14));
        backAttacks.Push(AttackMotion(preFix + "Attack_Close_Back_08", 17));

        // back far
        backAttacks.Push(AttackMotion(preFix + "Attack_Far_Back_02", 18));

        //========================================================================
        // LEFT
        //========================================================================
        // left weak
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Left", 13));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Weak_Left_02", 13));

        // left close
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_02", 13));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_05", 15));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Close_Left_08", 20));

        // left far
        leftAttacks.Push(AttackMotion(preFix + "Attack_Far_Left", 19));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Far_Left_02", 22));
        leftAttacks.Push(AttackMotion(preFix + "Attack_Far_Left_03", 21));

        forwardAttacks.Sort();
        leftAttacks.Sort();
        rightAttacks.Sort();
        backAttacks.Sort();

        Print("After sort forward attack motions=:\n");
        for (uint i=0; i<forwardAttacks.length; ++i)
            Print(forwardAttacks[i].motion.animationName);

        Print("After sort left attack motions=:\n");
        for (uint i=0; i<leftAttacks.length; ++i)
            Print(leftAttacks[i].motion.animationName);

        Print("After sort right attack motions=:\n");
        for (uint i=0; i<rightAttacks.length; ++i)
            Print(rightAttacks[i].motion.animationName);

        Print("After sort back attack motions=:\n");
        for (uint i=0; i<backAttacks.length; ++i)
            Print(backAttacks[i].motion.animationName);
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
        targetAngle = ownner.GetTargetAngle(attackEnemy.sceneNode);
        targetDistance = ownner.GetTargetDistance(attackEnemy.sceneNode);

        bool standBy = targetDistance < ATTACK_SAFE_DIST;

        Vector3 oldPosition = ownner.sceneNode.worldPosition;
        float t = ownner.animCtrl.GetTime(motion.animationName);
        if (status == 0)
        {
            if (t >= currentAttack.slowMotionTime.x) {
                status = 1;
                ownner.sceneNode.scene.timeScale = 0.25f;
            }
        }
        else if (status == 1)
        {
            if (attack_timing_test)
            {
                if (t < currentAttack.impactTime && ((t + dt) > currentAttack.impactTime))
                    ownner.sceneNode.scene.timeScale = 0.0f;
            }

            if (t >= currentAttack.slowMotionTime.y) {
                status = 2;
                ownner.sceneNode.scene.timeScale = 1.0f;
            }
        }

        if (status != 2) {
            // motion.deltaRotation += fixRotatePerSec * dt;
            // Print("motion.deltaRotation=" + String(motion.deltaRotation));
            // ownner.sceneNode.worldPosition = ownner.sceneNode.worldPosition + movePosPerSec * dt;
            motion.deltaPosition += movePosPerSec * dt;
        }

        if (status > 0)
        {
            //float diffAngle = ownner.ComputeAngleDiff(attackEnemy.sceneNode);
            //const float turnSpeed = 15.0f;
            //motion.deltaRotation += diffAngle * dt * turnSpeed;
        }

        bool finished = motion.Move(dt, ownner.sceneNode, ownner.animCtrl);
        if (standBy) {
            ownner.sceneNode.worldPosition = oldPosition;
        }

        if (finished) {
            // ownner.sceneNode.scene.timeScale = 0.0f;
            ownner.stateMachine.ChangeState("StandState");
        }

        CharacterState::Update(dt);
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

    void PickBestMotion(const Array<AttackMotion@>&in attacks)
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
        float baseDist = collisionRadius * 1.75f;

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
            bestIndex = RandomInt(5);
        }

        @currentAttack = attacks[bestIndex];

        predictEnemyPosition = myPos + enemyDir * bestRange;
        predictPosition = myPos + enemyDir * (enemyDist -  2 * collisionRadius);

        Vector3 futurePos = currentAttack.motion.GetFuturePosition(ownner.sceneNode, currentAttack.impactTime);
        movePosPerSec = ( predictPosition - futurePos ) / currentAttack.impactTime;

        // attackEnemy.sceneNode.worldPosition = predictEnemyPosition;
        Print("Best attack motion = " + currentAttack.motion.animationName + " movePosPerSec=" + movePosPerSec.ToString());
    }

    void Enter(State@ lastState)
    {
        float diff = ownner.ComputeAngleDiff(attackEnemy.sceneNode);
        int r = DirectionMapToIndex(diff, 4);
        Print("Attack-align " + " r-index=" + r + " diff=" + diff);
        float turnAngle = 0;

        int i = 0;
        if (r == 0)
        {
            PickBestMotion(forwardAttacks);
            turnAngle = 0;
        }
        else if (r == 1)
        {
            PickBestMotion(rightAttacks);
            turnAngle = 90;
        }
        else if (r == 2)
        {
            PickBestMotion(backAttacks);
            turnAngle = diff < 0 ? -180 : 180;
        }
        else if (r == 3)
        {
            PickBestMotion(leftAttacks);
            turnAngle = -90;
        }

        if (currentAttack is null)
            return;

        Motion@ motion = currentAttack.motion;
        motion.Start(ownner.sceneNode, ownner.animCtrl);
        predictMotionPosition = motion.GetFuturePosition(currentAttack.impactTime);
        status = 0;

        if (attack_timing_test)
            ownner.sceneNode.scene.timeScale = 0.0f;
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
        // currentAttack.motion.DebugDraw(debug, ownner.sceneNode);
        debug.AddLine(ownner.sceneNode.worldPosition, attackEnemy.sceneNode.worldPosition, Color(0.7f, 0.8f, 0.7f), false);
        //AddDebugMark(debug, predictPosition, Color(0, 0, 1));
        //AddDebugMark(debug, predictEnemyPosition, Color(0, 1, 0));
        //AddDebugMark(debug, predictMotionPosition, Color(1, 0, 0));
        DebugDrawDirection(debug, ownner.sceneNode, targetAngle, Color(1, 0, 0), 2);
    }

    String GetDebugText()
    {
        String r = CharacterState::GetDebugText();
        r += "\ncurrentAttack=" + currentAttack.motion.animationName + " distToEnemy=" + targetDistance;
        return r;
    }
};


class PlayerCounterState : MultiMotionState
{
    Enemy@              counterEnemy;
    int                 status;
    Vector3             positionDiff;
    float               rotationDiff;
    int                 counterIndex;
    float               alignTime;

    PlayerCounterState(Character@ c)
    {
        super(c);
        SetName("CounterState");
        AddMotion("BM_TG_Counter/Counter_Arm_Front_01");
        alignTime = 0.2f;
    }

    ~PlayerCounterState()
    {
        @counterEnemy = null;
    }

    void Update(float dt)
    {
        if (status == 0) {
            // aligning
            float targetRotation = counterEnemy.sceneNode.worldRotation.eulerAngles.y + rotationDiff;
            Vector3 targetPos = Quaternion(0, targetRotation, 0) * positionDiff + node.worldPosition;
            targetPos = node.worldPosition.Lerp(targetPos, timeInState/alignTime);
            float curRot = node.worldRotation.eulerAngles.y;
            float dYaw = AngleDiff(targetRotation - curRot);
            float timeLeft = alignTime - timeInState;
            float yawPerSec = dYaw / timeLeft;
            node.worldRotation = Quaternion(0, curRot + yawPerSec * dt, 0);

            if (timeInState >= alignTime) {
                Print("FINISHED ALIGN!!!!");
                status = 1;
                counterEnemy.sceneNode.vars["CounterIndex"] = counterIndex;
                counterEnemy.stateMachine.ChangeState("CounterState");
                motions[counterIndex].Start(ownner.sceneNode, ownner.animCtrl);
            }
        }
        else {
            // real counting
            if (motions[counterIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
                ownner.stateMachine.ChangeState("StandState");
        }

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        status = 0;
        float dAngle = ownner.ComputeAngleDiff(counterEnemy.sceneNode);
        int front_back = 0;
        if (Abs(dAngle) > 90)
            front_back = 1;
        rotationDiff = (front_back == 0) ? 180 : 0;
        Print("Counter-align angle-diff=" + dAngle);

        ThugCounterState@ enemyCounterState = cast<ThugCounterState@>(counterEnemy.stateMachine.FindState("CounterState"));
        if (enemyCounterState is null)
            return;

        positionDiff = motions[counterIndex].startFromOrigin - enemyCounterState.motions[counterIndex].startFromOrigin;
        Print("positionDiff=" + positionDiff.ToString() + " rotationDiff=" + rotationDiff);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        @counterEnemy = null;
    }

    String GetDebugText()
    {
        String r = CharacterState::GetDebugText();
        r += "\ncurrent motion=" + motions[counterIndex].animationName;
        return r;
    }

    int PickIndex()
    {
        return counterIndex;
    }
};

class PlayerHitState : MultiMotionState
{
    PlayerHitState(Character@ c)
    {
        super(c);
        SetName("HitState");
    }

    void Update(float dt)
    {
        MultiMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        MultiMotionState::Enter(lastState);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["Hit"].GetInt();
    }
};

class Player : Character
{
    float maxAttackDistSQR;
    float maxCounterDistSQR;
    int combo;

    Player()
    {
        super();
        combo = 0;
        maxAttackDistSQR = 100.f * 100.0f;
        maxCounterDistSQR = 3.0f * 3.0f;
    }

    void ObjectStart()
    {
        uint startTime = time.systemTime;
        Character::ObjectStart();
        stateMachine.AddState(PlayerStandState(this));
        stateMachine.AddState(PlayerTurnState(this));
        stateMachine.AddState(PlayerMoveState(this));
        stateMachine.AddState(PlayerAttackState(this));
        stateMachine.AddState(PlayerAlignState(this));
        stateMachine.AddState(PlayerCounterState(this));
        stateMachine.AddState(PlayerEvadeState(this));
        stateMachine.AddState(PlayerHitState(this));
        stateMachine.AddState(PlayerRedirectState(this));
        stateMachine.AddState(AnimationTestState(this));

        stateMachine.ChangeState("StandState");
        Print("Player::ObjectStart time-cost=" + String(time.systemTime - startTime) + " ms");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Vector3 fwd = Vector3(0, 0, 1);
        Vector3 camDir = cameraNode.worldRotation * fwd;
        float cameraAngle = Atan2(camDir.x, camDir.z);
        float targetAngle = cameraAngle + gInput.m_leftStickAngle;
        float baseLen = 2.0f;
        DebugDrawDirection(debug, sceneNode, targetAngle, Color(1, 1, 0), baseLen);
        Character::DebugDraw(debug);
    }

    void Attack()
    {
        // Find the best enemy
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 myDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        float myAngle = Atan2(myDir.x, myDir.z);
        Vector3 camDir = cameraNode.worldRotation * Vector3(0, 0, 1);
        float cameraAngle = Atan2(camDir.x, camDir.z);
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
            Print(String(distSQR));
            if (distSQR > maxAttackDistSQR || !e.CanBeAttacked())
            {
                gEnemyMgr.scoreCache.Push(-1);
                continue;
            }
            float diffAngle = Abs(Atan2(posDiff.x, posDiff.z));
            int angleScore = (180 - diffAngle)/180 * 50; // angle at 50% percant
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

        if (attackEnemy is null)
            return;

        Print("Choose Attack Enemy " + attackEnemy.sceneNode.name);
        PlayerAttackState@ state = cast<PlayerAttackState@>(stateMachine.FindState("AttackState"));
        if (state is null)
            return;
        @state.attackEnemy = attackEnemy;
        stateMachine.ChangeState("AttackState");
    }

    void Counter()
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
                continue;
            Vector3 posDiff = e.sceneNode.worldPosition - myPos;
            posDiff.y = 0;
            float distSQR = posDiff.lengthSquared;
            if (distSQR > maxCounterDistSQR)
                continue;
            if (curDistSQR > distSQR)
            {
                counterEnemy = e;
                curDistSQR = distSQR;
                curPosDiff = posDiff;
            }
        }

        if (counterEnemy is null)
            return;

        Print("Choose Couter Enemy " + counterEnemy.sceneNode.name);
        PlayerCounterState@ state = cast<PlayerCounterState@>(stateMachine.FindState("CounterState"));
        if (state is null)
            return;
        @state.counterEnemy = counterEnemy;
        stateMachine.ChangeState("CounterState");
    }

    void Evade()
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
            if (!e.CanBeRedirected())
                continue;

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

        if (redirectEnemy !is null)
        {
            PlayerRedirectState@ s = cast<PlayerRedirectState>(stateMachine.FindState("RedirectState"));
            @s.redirectEnemy = redirectEnemy;
            stateMachine.ChangeState("RedirectState");
            redirectEnemy.Redirect();
        }
        else
        {
            if (!gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1))
            {
                sceneNode.vars["AnimationIndex"] = RadialSelectAnimation(2);
                stateMachine.ChangeState("EvadeState");
            }
        }
    }

    void Hit()
    {

    }

    String GetDebugText()
    {
        return Character::GetDebugText() +  "player combo=" + combo + "\n";
    }

    void CommonStateFinishedOnGroud()
    {
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1))
            stateMachine.ChangeState("StandState");
        else {
            stateMachine.ChangeState("MoveState");
        }
    }

    float GetTargetAngle()
    {
        Vector3 camDir = cameraNode.worldRotation * Vector3(0, 0, 1);
        float cameraAngle = Atan2(camDir.x, camDir.z);
        return gInput.m_leftStickAngle + cameraAngle;
    }
};