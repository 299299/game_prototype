
const float fullTurnThreashold = 125;
const float attackRadius = 3;

class PlayerStandState : CharacterState
{
    Array<String>           animations;

    PlayerStandState(Character@ c)
    {
        super(c);
        name = "StandState";
        animations.Push(GetAnimationName("BM_Combat_Movement/Stand_Idle"));
        animations.Push(GetAnimationName("BM_Combat_Movement/Stand_Idle_01"));
        animations.Push(GetAnimationName("BM_Combat_Movement/Stand_Idle_02"));
    }

    void Enter(State@ lastState)
    {
        PlayAnimation(ownner.animCtrl, animations[RandomInt(animations.length)], LAYER_MOVE, true, 0.5);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);

    /*
        Vector3 leftFootPos = ownner.sceneNode.GetChild("Bip01_L_Foot", true).worldPosition;
        Vector3 rightFootPos = ownner.sceneNode.GetChild("Bip01_R_Foot", true).worldPosition;
        Vector3 diff = leftFootPos - rightFootPos;
        diff.y = 0;
        Print("Distance from left foot to right foot is " + String(diff.length));
    */
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = RadialSelectAnimation_Player(ownner.sceneNode, 4);
            ownner.sceneNode.vars["AnimationIndex"] = index;
            if (index == 0)
                ownner.stateMachine.ChangeState("MoveState");
            else
                ownner.stateMachine.ChangeState("StandToMoveState");
        }

        if (gInput.IsAttackPressed())
            ownner.Attack();
        else if(gInput.IsCounterPressed())
            ownner.Counter();

        CharacterState::Update(dt);
    }
};

class PlayerStandToMoveState : MultiMotionState
{
    float turnSpeed;

    PlayerStandToMoveState(Character@ c)
    {
        super(c);
        name = "StandToMoveState";
        motions.Push(gMotionMgr.FindMotion("BM_Combat_Movement/Turn_Right_90"));
        motions.Push(gMotionMgr.FindMotion("BM_Combat_Movement/Turn_Right_180"));
        motions.Push(gMotionMgr.FindMotion("BM_Combat_Movement/Turn_Left_90"));
        turnSpeed = 5;
    }

    void Update(float dt)
    {
        float characterDifference = ComputeDifference_Player(ownner.sceneNode);
        float a = timeInState / motions[selectIndex].endTime;
        float dYaw = characterDifference * turnSpeed * dt * a;
        //motions[selectIndex].startRotation += dYaw;

        if ( (Abs(characterDifference) > fullTurnThreashold) && gInput.IsLeftStickStationary() )
        {
            Print("180!!!");
            ownner.stateMachine.ChangeState("MoveTurn180State");
        }

        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
        {
            if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1))
                ownner.stateMachine.ChangeState("StandState");
            else
                ownner.stateMachine.ChangeState("MoveState");
        }

        CharacterState::Update(dt);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["AnimationIndex"].GetInt() - 1;
    }
};

class PlayerMoveState : CharacterState
{
    Motion@ motion;
    float turnSpeed;

    PlayerMoveState(Character@ c)
    {
        super(c);
        name = "MoveState";
        @motion = gMotionMgr.FindMotion("BM_Combat_Movement/Walk_Forward");
        turnSpeed = 5;
    }

    void Update(float dt)
    {
        // check if we should return to the idle state
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1))
            ownner.stateMachine.ChangeState("StandState");

        // compute the difference between the direction the character is facing
        // and the direction the user wants to go in
        float characterDifference = ComputeDifference_Player(ownner.sceneNode)  ;

        // if the difference is greater than this about, turn the character
        ownner.sceneNode.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(dt, ownner.sceneNode, ownner.animCtrl);

        bool evade = gInput.IsEvadePressed();

        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > fullTurnThreashold) && gInput.IsLeftStickStationary() )
        {
            Print("180!!!");
            if (evade) {
                ownner.sceneNode.vars["AnimationIndex"] = 1;
                ownner.stateMachine.ChangeState("EvadeState");
            }
            else
                ownner.stateMachine.ChangeState("MoveTurn180State");
        }

        if(evade) {
            ownner.sceneNode.vars["AnimationIndex"] = 0;
            ownner.stateMachine.ChangeState("EvadeState");
        }

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        PlayerStandToMoveState@ standToMoveState = cast<PlayerStandToMoveState@>(lastState);
        motion.Start(ownner.sceneNode, ownner.animCtrl, 0.0, 0.2);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motion.DebugDraw(debug, ownner.sceneNode);
    }
};

class PlayerMoveTurn180State : CharacterState
{
    Motion@ motion;

    PlayerMoveTurn180State(Character@ c)
    {
        super(c);
        name = "MoveTurn180State";
        @motion = gMotionMgr.FindMotion("BM_Combat_Movement/Turn_Right_180");
    }

    void Update(float dt)
    {
        if (motion.Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.CommonStateFinishedOnGroud();

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        motion.Start(ownner.sceneNode, ownner.animCtrl, 0.0f, 0.1f);
    }
};

class PlayerEvadeState : MultiMotionState
{
    PlayerEvadeState(Character@ c)
    {
        super(c);
        name = "EvadeState";
        motions.Push(gMotionMgr.FindMotion("BM_Movement/Evade_Forward_01"));
        motions.Push(gMotionMgr.FindMotion("BM_Movement/Evade_Back_01"));
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.CommonStateFinishedOnGroud();

        MultiMotionState::Update(dt);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["AnimationIndex"].GetInt();
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motions[selectIndex].DebugDraw(debug, ownner.sceneNode);
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
    Array<Motion@>  forwadAttacks;
    Array<Motion@>  leftAttacks;
    Array<Motion@>  rightAttacks;
    Array<Motion@>  backAttacks;

    Array<Vector3>  forwadImpacts;
    Array<Vector3>  leftImpacts;
    Array<Vector3>  rightImpacts;
    Array<Vector3>  backImpacts;

    Vector3         attackImpactPos;
    float           attackImpactTime;

    float           fixRotatePerSec;

    Motion@         currentMotion;

    Enemy@          attackEnemy;

    PlayerAttackState(Character@ c)
    {
        super(c);
        name = "AttackState";
        @currentMotion = null;

        // motions
        // forward
        for (int i=2; i<=8; ++i)
        {
            forwadAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Forward_0" + String(i)));
        }
        forwadAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Far_Forward"));
        for (int i=1; i<=4; ++i)
        {
            forwadAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Far_Forward_0" + String(i)));
        }

        // right
        rightAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Right"));
        for (int i=1; i<=8; ++i)
        {
            if (i == 2)
                continue;
            rightAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Right_0" + String(i)));
        }
        rightAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Far_Right"));
        for (int i=1; i<=4; ++i)
        {
            rightAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Far_Right_0" + String(i)));
        }

        // left
        leftAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Left"));
        for (int i=1; i<=8; ++i)
        {
            leftAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Left_0" + String(i)));
        }
        leftAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Far_Left"));
        for (int i=1; i<=4; ++i)
        {
            leftAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Far_Left_0" + String(i)));
        }

        // back
        backAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Back"));
        for (int i=1; i<=8; ++i)
        {
            backAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Back_0" + String(i)));
        }

        backAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Far_Back"));
        for (int i=1; i<=4; ++i)
        {
            backAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Far_Back_0" + String(i)));
        }

        float r = attackRadius;
        // impact frames for animations
        Array<int> leftImpactFrames = { 7, 18, 13, 21, 22, 15, 17, 15, 20, 19, 23, 22, 21, 23 };
        Print("Collecting leftImpacts");
        AssignImpactFrames(leftAttacks, leftImpactFrames, Vector3(-r, 0, 0), leftImpacts);

        Array<int> forwardImpactFrames = { 14, 12, 19, 24, 20, 19, 18, 24, 17, 21, 22, 22};
        Print("Collecting forwadImpacts");
        AssignImpactFrames(forwadAttacks, forwardImpactFrames, Vector3(0, 0, r), forwadImpacts);

        Array<int> rightImpactFrames = { 16,  18, 11, 19, 15, 21, 16, 18, 25, 15, 21, 29, 22 };
        Print("Collecting rightImpacts");
        AssignImpactFrames(rightAttacks, rightImpactFrames, Vector3(r, 0, 0), rightImpacts);

        Array<int> backImpactFrames = { 9, 16, 18, 21, 14, 14, 15, 14, 17, 14, 15, 18, 23, 20 };
        Print("Collecting backImpacts");
        AssignImpactFrames(backAttacks, backImpactFrames, Vector3(0, 0, -r), backImpacts);
    }

    void AssignImpactFrames(const Array<Motion@>&in animations, const Array<int>&in impactFrames, const Vector3&in offset, Array<Vector3>&out outImpacts)
    {
        if (animations.length != impactFrames.length)
        {
            ErrorDialog("Player", "impact frame num != attack num");
            return;
        }

        outImpacts.Resize(animations.length);
        for (uint i=0; i<impactFrames.length; ++i)
        {
            float t = impactFrames[i] * SEC_PER_FRAME;
            Vector4 k = animations[i].GetKey(t);
            Vector3 p(k.x, k.y, k.z);
            p += offset;
            outImpacts[i] = p;
            // hack here using y component to store impact time
            outImpacts[i].y = t;
            Print("outImpacts[" + String(i) + "]=" + p.ToString());
        }
    }

    ~PlayerAttackState()
    {
        @attackEnemy = null;
    }

    void Update(float dt)
    {
        //if (ownner.animCtrl.GetTime(currentMotion.animationName) >= attackImpactTime)
        //    ownner.animCtrl.SetSpeed(currentMotion.animationName, 0.0f);

        if (currentMotion.Move(dt, ownner.sceneNode, ownner.animCtrl)) {
            ownner.stateMachine.ChangeState("StandState");
        }

        if (input.keyPress['F'])
            ownner.stateMachine.ChangeState("StandState");

        CharacterState::Update(dt);
    }

    void PickBestMotion(const Array<Motion@>&in motions, const Array<Vector3>&in impacts)
    {
        Vector3 myPos = ownner.sceneNode.worldPosition;
        Vector3 enemyPos = attackEnemy.sceneNode.worldPosition;
        Vector3 enemyToMePos = enemyPos - myPos;

        Quaternion myRot = ownner.sceneNode.worldRotation;
        float yaw = myRot.eulerAngles.y;
        Vector3 impactPosDiff;
        float distFromEnemyToMeSQR = enemyToMePos.lengthSquared;

        float minDistSQR = 99999;
        int bestIndex = -1;
        for (uint i=0; i<impacts.length; ++i)
        {
            Vector3 imp = impacts[i];
            imp.y = 0;
            Vector3 impactPos = myPos + myRot * imp;
            Vector3 diff = enemyPos - impactPos;
            diff.y = 0;
            float distSQR = diff.lengthSquared;
            if (distSQR < minDistSQR)
            {
                bestIndex = i;
                minDistSQR = distSQR;
                attackImpactPos = impactPos;
                attackImpactTime = impacts[i].y;
                impactPosDiff = diff;
            }
        }

        if (bestIndex < 0)
            return;

        @currentMotion = motions[bestIndex];
        float diffAngle = Atan2(impactPosDiff.x, impactPosDiff.z);

        Print("Best attack motion = " + String(currentMotion.animationName) +
              " impact pos=" + attackImpactPos.ToString() +
              " minDistSQR=" + String(minDistSQR) +
              " diffAngle=" + String(diffAngle));
    }

    void Enter(State@ lastState)
    {
        Vector3 myPos = ownner.sceneNode.worldPosition;
        Vector3 enemyPos = attackEnemy.sceneNode.worldPosition;
        Vector3 posDiff = enemyPos - myPos;
        posDiff.y = 0;
        Quaternion myRot = ownner.sceneNode.worldRotation;

        float angle = Atan2(posDiff.x, posDiff.z);
        int r = RadialSelectAnimation(ownner.sceneNode, 4, angle);
        Print("Attack-align pos-diff=" + posDiff.ToString() + " r-index=" + String(r) + " angle=" + String(angle));
        float targetAngle = 0;

        int i = 0;
        if (r == 0)
        {
            PickBestMotion(forwadAttacks, forwadImpacts);
        }
        else if (r == 1)
        {
            PickBestMotion(rightAttacks, rightImpacts);
        }
        else if (r == 2)
        {
            PickBestMotion(backAttacks, backImpacts);
        }
        else if (r == 3)
        {
            PickBestMotion(leftAttacks, leftImpacts);
        }

        if (currentMotion is null)
            return;

        currentMotion.Start(ownner.sceneNode, ownner.animCtrl);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        @attackEnemy = null;
        @currentMotion = null;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        // currentMotion.DebugDraw(debug, ownner.sceneNode);
        debug.AddLine(currentMotion.startPosition, attackImpactPos, Color(1.0f, 0.0f, 0.7f), false);
        debug.AddLine(ownner.sceneNode.worldPosition, attackEnemy.sceneNode.worldPosition, Color(0.25f, 0.25f, 0.25f), false);
    }
};


class PlayerCounterState : CharacterState
{
    Array<Motion@>      motions;
    Enemy@              counterEnemy;
    int                 status;
    Vector3             positionDiff;
    float               rotationDiff;
    int                 counterIndex;
    float               alignTime;

    PlayerCounterState(Character@ c)
    {
        super(c);
        name = "CounterState";
        motions.Push(gMotionMgr.FindMotion("BM_TG_Counter/Counter_Arm_Front_01"));
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
            float dYaw = angleDiff(targetRotation - curRot);
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
        Vector3 myPos = ownner.sceneNode.worldPosition;
        Vector3 myDir = ownner.sceneNode.worldRotation * Vector3(0, 0, 1);
        float myAngle = Atan2(myDir.x, myDir.z);
        Vector3 enemyPos = counterEnemy.sceneNode.worldPosition;
        Vector3 posDiff = enemyPos - myPos;
        posDiff.y = 0;

        float angle = Atan2(posDiff.x, posDiff.z);
        float dAngle = angleDiff(angle - myAngle);
        int front_back = 0;
        if (Abs(dAngle) > 90)
            front_back = 1;
        rotationDiff = (front_back == 0) ? 180 : 0;
        Print("Counter-align pod-diff=" + posDiff.ToString() + " angle-diff=" + String(dAngle));

        counterIndex = 0; // FIXME TODO
        ThugCounterState@ enemyCounterState = cast<ThugCounterState@>(counterEnemy.stateMachine.FindState("CounterState"));
        if (enemyCounterState is null)
            return;

        positionDiff = motions[counterIndex].startFromOrigin - enemyCounterState.motions[counterIndex].startFromOrigin;
        Print("positionDiff=" + positionDiff.ToString() + " rotationDiff=" + String(rotationDiff));
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        @counterEnemy = null;
    }
};

class PlayerHitState : MultiMotionState
{
    PlayerHitState(Character@ c)
    {
        super(c);
        name = "HitState";
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.stateMachine.ChangeState("StandState");

        CharacterState::Update(dt);
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

    void Start()
    {
        uint startTime = time.systemTime;
        Character::Start();
        stateMachine.AddState(PlayerStandState(this));
        stateMachine.AddState(PlayerStandToMoveState(this));
        stateMachine.AddState(PlayerMoveState(this));
        stateMachine.AddState(PlayerMoveTurn180State(this));
        stateMachine.AddState(PlayerAttackState(this));
        stateMachine.AddState(PlayerAlignState(this));
        stateMachine.AddState(PlayerCounterState(this));
        stateMachine.AddState(PlayerEvadeState(this));
        stateMachine.AddState(PlayerHitState(this));
        stateMachine.ChangeState("StandState");
        Print("Player::Start time-cose=" + String(time.systemTime - startTime) + " ms");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddNode(sceneNode, 1.0f, false);
        debug.AddNode(sceneNode.GetChild("Bip01", true), 1.0f, false);
        Vector3 fwd = Vector3(0, 0, 1);
        Vector3 camDir = cameraNode.worldRotation * fwd;
        float cameraAngle = Atan2(camDir.x, camDir.z);
        Vector3 characterDir = sceneNode.worldRotation * fwd;
        float characterAngle = Atan2(characterDir.x, characterDir.z);
        float targetAngle = cameraAngle + gInput.m_leftStickAngle;
        float baseLen = 2.0f;
        DebugDrawDirection(debug, sceneNode, targetAngle, Color(1, 1, 0), baseLen);
        DebugDrawDirection(debug, sceneNode, characterAngle, Color(1, 0, 1), baseLen);
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
        Print("Attack targetAngle=" + String(targetAngle));

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
            Print("Enemy " + e.sceneNode.name + " distSQR=" + String(distSQR) + " diffAngle=" + String(diffAngle) + " score=" + String(score));
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

        for (uint i=0; i<gEnemyMgr.attackerList.length; ++i)
        {
            Enemy@ e = gEnemyMgr.attackerList[i];
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

    void Hit()
    {

    }


    String GetDebugText()
    {
        return Character::GetDebugText() +  "player combo=" + String(combo) + "\n";
    }

    void CommonStateFinishedOnGroud()
    {
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1))
            stateMachine.ChangeState("StandState");
        else {
            stateMachine.ChangeState("MoveState");
        }
    }
};


// computes the difference between the characters current heading and the
// heading the user wants them to go in.
float ComputeDifference_Player(Node@ n)
{
    // if the user is not pushing the stick anywhere return.  this prevents the character from turning while stopping (which
    // looks bad - like the skid to stop animation)
    if( gInput.m_leftStickMagnitude < 0.5f )
        return 0;

    Vector3 camDir = cameraNode.worldRotation * Vector3(0, 0, 1);
    float cameraAngle = Atan2(camDir.x, camDir.z);
    // check the difference between the characters current heading and the desired heading from the gamepad
    return ComputeDifference(n, gInput.m_leftStickAngle + cameraAngle);
}

//  divides a circle into numSlices and returns the index (in clockwise order) of the slice which
//  contains the gamepad's angle relative to the camera.
int RadialSelectAnimation_Player(Node@ n, int numDirections)
{
    Vector3 camDir = cameraNode.worldRotation * Vector3(0, 0, 1);
    float cameraAngle = Atan2(camDir.x, camDir.z);
    return RadialSelectAnimation(n, numDirections, gInput.m_leftStickAngle + cameraAngle);
}