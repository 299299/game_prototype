
const float fullTurnThreashold = 125;

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
        PlayAnimation(ownner.animCtrl, animations[RandomInt(animations.length)], LAYER_MOVE, true, 0.3);
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
    Array<Motion@>  closeFwdAttacks;
    Array<Motion@>  closeLeftAttacks;
    Array<Motion@>  closeRightAttacks;
    Array<Motion@>  closeBackwardAttacks;

    Array<Vector3>  closeFwdImpactMotion;
    Array<Vector3>  closeLeftImpactMotion;
    Array<Vector3>  closeRightImpactMotion;
    Array<Vector3>  closeBackImpactMotion;

    Vector3         attackImpactPos;

    Motion@         currentMotion;

    Enemy@          attackEnemy;

    PlayerAttackState(Character@ c)
    {
        super(c);
        name = "AttackState";
        @currentMotion = null;

        // motions
        for (int i=2; i<=8; ++i)
        {
            closeFwdAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Forward_0" + String(i)));
        }

        closeRightAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Right"));
        for (int i=1; i<=8; ++i)
        {
            if (i == 2)
                continue;
            closeRightAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Right_0" + String(i)));
        }

        closeLeftAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Left"));
        for (int i=1; i<=8; ++i)
        {
            closeLeftAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Left_0" + String(i)));
        }

        closeBackwardAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Back"));
        for (int i=1; i<=8; ++i)
        {
            closeBackwardAttacks.Push(gMotionMgr.FindMotion("BM_Attack/Attack_Close_Back_0" + String(i)));
        }

        // impact frames for animations
        Array<int> closeLeftImpactFrames = { 7, 18, 13, 21, 22, 15, 17, 15, 20 };
        Array<float> closeLeftImpactRadius = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0};

        closeLeftImpactMotion.Resize(closeLeftAttacks.length);
        for (uint i=0; i<closeLeftImpactFrames.length; ++i)
        {
            Vector4 k = closeLeftAttacks[i].motionKeys[closeLeftImpactFrames[i]];
            Vector3 p(k.x, k.y, k.z);
            p.x -= closeLeftImpactRadius[i];
            p.y = 0;
            closeLeftImpactMotion[i] = p;
            Print("closeLeftImpactMotion[" + String(i) + "]=" + p.ToString());
        }
    }

    ~PlayerAttackState()
    {
        @attackEnemy = null;
    }

    void Update(float dt)
    {
        if (currentMotion.Move(dt, ownner.sceneNode, ownner.animCtrl)) {
            ownner.stateMachine.ChangeState("StandState");
        }

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        Vector3 myPos = ownner.sceneNode.worldPosition;
        Vector3 enemyPos = attackEnemy.sceneNode.worldPosition;
        Vector3 posDiff = enemyPos - myPos;
        posDiff.y = 0;

        float angle = Atan2(posDiff.x, posDiff.z);
        int r = RadialSelectAnimation(ownner.sceneNode, 4, angle);
        Print("Attack-align pod-diff=" + posDiff.ToString() + " r-index=" + String(r));

        int i = 0;
        if (r == 0)
        {
            i = RandomInt(closeFwdAttacks.length);
            @currentMotion = closeFwdAttacks[i];
        }
        else if (r == 1)
        {
            i = RandomInt(closeRightAttacks.length);
            @currentMotion = closeRightAttacks[i];
        }
        else if (r == 2)
        {
            i = RandomInt(closeBackwardAttacks.length);
            @currentMotion = closeBackwardAttacks[i];
        }
        else if (r == 3)
        {
            float minDistSQR = 99999;
            int bestIndex = -1;
            for (uint i=0; i<closeLeftImpactMotion.length; ++i)
            {
                Vector3 impactPos = myPos + closeLeftImpactMotion[i];
                Vector3 diff = enemyPos - impactPos;
                diff.y = 0;
                float distSQR = diff.lengthSquared;
                if (distSQR < minDistSQR)
                {
                    bestIndex = i;
                    minDistSQR = distSQR;
                    attackImpactPos = impactPos;
                }
            }

            Print("Best left close attack = " + String(bestIndex));
            @currentMotion = closeLeftAttacks[bestIndex];
        }

        Print("Pick Attack " + currentMotion.animationName);
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
        currentMotion.DebugDraw(debug, ownner.sceneNode);
        debug.AddLine(currentMotion.startPosition, currentMotion.startPosition + attackImpactPos, Color(1.0f, 0.5f, 0.7f), false);
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