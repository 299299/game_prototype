// ==============================================
//
//    Player Pawn and Controller Class
//
// ==============================================

const float MAX_COUNTER_DIST = 4.0f;
const float PLAYER_COLLISION_DIST = COLLISION_RADIUS * 1.8f;
const float DIST_SCORE = 10.0f;
const float ANGLE_SCORE = 30.0f;
const float THREAT_SCORE = 30.0f;
const float LAST_ENEMY_ANGLE = 45.0f;
const int   LAST_ENEMY_SCORE = 5;
const int   MAX_WEAK_ATTACK_COMBO = 3;
const float MAX_DISTRACT_DIST = 4.0f;
const float MAX_DISTRACT_DIR = 90.0f;
const int   HIT_WAIT_FRAMES = 3;
const float LAST_KILL_SPEED = 0.35f;
const float COUNTER_ALIGN_MAX_DIST = 1.5f;
const float PLAYER_NEAR_DIST = 6.0f;
const float GOOD_COUNTER_DIST = 3.0f;
const float ATTACK_DIST_PICK_RANGE = 6.0f;
float MAX_ATTACK_DIST = 25.0f;
float MAX_BEAT_DIST = 25.0f;

class PlayerStandState : CharacterState
{
    Array<String>   animations;

    PlayerStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        ownner.PlayAnimation(animations[RandomInt(animations.length)], LAYER_MOVE, true, 0.2f);
        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

            Print("Stand->Move|Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            if (index == 0)
                ownner.ChangeState("MoveState");
            else
                ownner.ChangeState("TurnState");
        }

        ownner.ActionCheck(true, true, true, true);
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
        flags = FLAGS_ATTACK;
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += turnSpeed * dt;
        MultiMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        MultiMotionState::Enter(lastState);
        Motion@ motion = motions[selectIndex];
        Vector4 endKey = motion.GetKey(motion.endTime);
        float motionTargetAngle = ownner.motion_startRotation + endKey.w;
        float targetAngle = ownner.GetTargetAngle();
        float diff = AngleDiff(targetAngle - motionTargetAngle);
        turnSpeed = diff / motion.endTime;
        combatReady = true;
        Print("motionTargetAngle=" + String(motionTargetAngle) + " targetAngle=" + String(targetAngle) + " diff=" + String(diff) + " turnSpeed=" + String(turnSpeed));
    }
};

class PlayerMoveState : SingleMotionState
{
    float turnSpeed = 5.0f;

    PlayerMoveState(Character@ c)
    {
        super(c);
        SetName("MoveState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
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
            return;
        }
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("StandState");
            return;
        }
        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetTarget(null);
        combatReady = true;
    }
};

class PlayerEvadeState : MultiMotionState
{
    PlayerEvadeState(Character@ c)
    {
        super(c);
        SetName("EvadeState");
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

    int                     state;
    Vector3                 movePerSec;
    Vector3                 predictPosition;
    Vector3                 motionPosition;

    float                   alignTime = 0.2f;

    int                     forwadCloseNum = 0;
    int                     leftCloseNum = 0;
    int                     rightCloseNum = 0;
    int                     backCloseNum = 0;

    int                     slowMotionFrames = 2;

    int                     lastAttackDirection = -1;
    int                     lastAttackIndex = -1;

    bool                    weakAttack = true;
    bool                    slowMotion = false;
    bool                    lastKill = false;

    PlayerAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");
        flags = FLAGS_ATTACK;
    }

    void DumpAttacks(Array<AttackMotion@>@ attacks)
    {
        for (uint i=0; i<attacks.length; ++i)
        {
            Motion@ m = attacks[i].motion;
            if (m !is null)
                Print(m.animationName + " impactDist=" + String(attacks[i].impactDist));
        }
    }

    float UpdateMaxDist(Array<AttackMotion@>@ attacks, float dist)
    {
        if (attacks.empty)
            return dist;

        float maxDist = attacks[attacks.length-1].motion.endDistance;
        return (maxDist > dist) ? maxDist : dist;
    }

    void Dump()
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

    ~PlayerAttackState()
    {
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
                ownner.target.RemoveFlag(FLAGS_NO_MOVE);
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

        if (slowMotion)
        {
            float t_diff = currentAttack.impactTime - t;
            if (t_diff > 0 && t_diff < SEC_PER_FRAME * slowMotionFrames)
                ownner.SetSceneTimeScale(0.1f);
            else
                ownner.SetSceneTimeScale(1.0f);
        }

        ownner.CheckTargetDistance(ownner.target, PLAYER_COLLISION_DIST);

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
        if (ownner.IsInAir())
            return;

        int addition_frames = slowMotion ? slowMotionFrames : 0;
        bool check_attack = t > currentAttack.impactTime + SEC_PER_FRAME * ( HIT_WAIT_FRAMES + 1 + addition_frames);
        bool check_others = t > currentAttack.impactTime + SEC_PER_FRAME * addition_frames;
        ownner.ActionCheck(check_attack, check_others, check_others, check_others);
    }

    void PickBestMotion(Array<AttackMotion@>@ attacks, int dir)
    {
        Vector3 myPos = ownner.GetNode().worldPosition;
        Vector3 enemyPos = ownner.target.GetNode().worldPosition;
        Vector3 diff = enemyPos - myPos;
        diff.y = 0;
        float toEnenmyDistance = diff.length - PLAYER_COLLISION_DIST;
        if (toEnenmyDistance < 0.0f)
            toEnenmyDistance = 0.0f;
        int bestIndex = 0;
        diff.Normalize();

        int index_start = -1;
        int index_num = 0;

        float min_dist = Max(0.0f, toEnenmyDistance - ATTACK_DIST_PICK_RANGE/2.0f);
        float max_dist = toEnenmyDistance + ATTACK_DIST_PICK_RANGE;
        Print("Player attack toEnenmyDistance = " + toEnenmyDistance + "(" + min_dist + "," + max_dist + ")");

        for (uint i=0; i<attacks.length; ++i)
        {
            AttackMotion@ am = attacks[i];
            // Print("am.impactDist=" + am.impactDist);
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
            int r_n = RandomInt(index_num);
            bestIndex = index_start + r_n % index_num;
            if (lastAttackDirection == dir && bestIndex == lastAttackIndex)
            {
                Print("Repeat Attack index index_num=" + index_num);
                bestIndex = index_start + (r_n + 1) % index_num;
            }
            lastAttackDirection = dir;
            lastAttackIndex = bestIndex;
        }

        Print("Attack bestIndex="+bestIndex+" index_start="+index_start+" index_num="+index_num);

        @currentAttack = attacks[bestIndex];
        alignTime = currentAttack.impactTime;

        predictPosition = myPos + diff * toEnenmyDistance;
        Print("PlayerAttack dir=" + lastAttackDirection + " index=" + lastAttackIndex + " Pick attack motion = " + currentAttack.motion.animationName);
    }

    void StartAttack()
    {
        Player@ p = cast<Player>(ownner);
        if (ownner.target !is null)
        {
            state = ATTACK_STATE_ALIGN;
            float diff = ownner.ComputeAngleDiff(ownner.target.GetNode());
            int r = DirectionMapToIndex(diff, 4);

            if (d_log)
                Print("Attack-align " + " r-index=" + r + " diff=" + diff);

            if (r == 0)
                PickBestMotion(forwardAttacks, r);
            else if (r == 1)
                PickBestMotion(rightAttacks, r);
            else if (r == 2)
                PickBestMotion(backAttacks, r);
            else if (r == 3)
                PickBestMotion(leftAttacks, r);

            ownner.target.RequestDoNotMove();
            p.lastAttackId = ownner.target.GetNode().id;
        }
        else
        {
            int index = ownner.RadialSelectAnimation(4);
            if (index == 0)
                currentAttack = forwardAttacks[RandomInt(forwadCloseNum)];
            else if (index == 1)
                currentAttack = rightAttacks[RandomInt(rightCloseNum)];
            else if (index == 2)
                currentAttack = backAttacks[RandomInt(backCloseNum)];
            else if (index == 3)
                currentAttack = leftAttacks[RandomInt(leftCloseNum)];
            state = ATTACK_STATE_BEFORE_IMPACT;
            p.lastAttackId = M_MAX_UNSIGNED;

            // lost combo
            p.combo = 0;
            p.StatusChanged();
        }

        Motion@ motion = currentAttack.motion;
        motion.Start(ownner);
        weakAttack = cast<Player>(ownner).combo < MAX_WEAK_ATTACK_COMBO;
        slowMotion = (p.combo >= 3) ? (RandomInt(10) == 1) : false;

        if (ownner.target !is null)
        {
            motionPosition = motion.GetFuturePosition(ownner, currentAttack.impactTime);
            movePerSec = ( predictPosition - motionPosition ) / alignTime;
            movePerSec.y = 0;

            //if (attackEnemy.HasFlag(FLAGS_COUNTER))
            //    slowMotion = true;

            lastKill = p.CheckLastKill();
        }
        else
        {
            weakAttack = false;
            slowMotion = false;
        }

        if (lastKill)
        {
            ownner.SetSceneTimeScale(LAST_KILL_SPEED);
            weakAttack = false;
            slowMotion = false;
        }

        ownner.SetNodeEnabled("TailNode", true);
    }

    void Enter(State@ lastState)
    {
        Print("################## Player::AttackState Enter from " + lastState.name  + " #####################");
        lastKill = false;
        slowMotion = false;
        @currentAttack = null;
        state = ATTACK_STATE_ALIGN;
        movePerSec = Vector3(0, 0, 0);
        StartAttack();
        //ownner.SetSceneTimeScale(0.25f);
        //ownner.SetTimeScale(1.5f);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        ownner.SetNodeEnabled("TailNode", false);
        //if (nextState !is this)
        //    cast<Player>(ownner).lastAttackId = M_MAX_UNSIGNED;
        if (ownner.target !is null)
            ownner.target.RemoveFlag(FLAGS_NO_MOVE);
        @currentAttack = null;
        ownner.SetSceneTimeScale(1.0f);
        Print("################## Player::AttackState Exit to " + nextState.name  + " #####################");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentAttack is null || ownner.target is null)
            return;
        debug.AddLine(ownner.GetNode().worldPosition, ownner.target.GetNode().worldPosition, RED, false);
        debug.AddCross(predictPosition, 0.5f, Color(0.25f, 0.28f, 0.7f), false);
        debug.AddCross(motionPosition, 0.5f, Color(0.75f, 0.28f, 0.27f), false);
    }

    String GetDebugText()
    {
        return " name=" + name + " timeInState=" + String(timeInState) + "\n" +
                "currentAttack=" + currentAttack.motion.animationName +
                " weakAttack=" + weakAttack +
                " slowMotion=" + slowMotion +
                "\n";
    }

    bool CanReEntered()
    {
        return true;
    }

    void AttackImpact()
    {
        Character@ e = ownner.target;

        if (e is null)
            return;

        Node@ _node = ownner.GetNode();
        Vector3 dir = _node.worldPosition - e.GetNode().worldPosition;
        dir.y = 0;
        dir.Normalize();
        Print("PlayerAttackState::" +  e.GetName() + " OnDamage!!!!");

        Node@ n = _node.GetChild(currentAttack.boneName, true);
        Vector3 position = _node.worldPosition;
        if (n !is null)
            position = n.worldPosition;

        int damage = ownner.attackDamage;
        if (lastKill)
            damage = 9999;
        else
            damage = RandomInt(ownner.attackDamage, ownner.attackDamage + 20);
        bool b = e.OnDamage(ownner, position, dir, damage, weakAttack);
        if (!b)
            return;

        ownner.SpawnParticleEffect(position, "Particle/SnowExplosion.xml", 5.0f, 5.0f);
        ownner.SpawnParticleEffect(position, "Particle/HitSpark.xml", 1.0f, 0.6f);

        int sound_type = e.health == 0 ? 1 : 0;
        ownner.PlayRandomSound(sound_type);
        ownner.OnAttackSuccess(e);
    }

    void PostInit(float closeDist = 2.5f)
    {
        forwardAttacks.Sort();
        leftAttacks.Sort();
        rightAttacks.Sort();
        backAttacks.Sort();

        float dist = 0.0f;
        dist = UpdateMaxDist(forwardAttacks, dist);
        dist = UpdateMaxDist(leftAttacks, dist);
        dist = UpdateMaxDist(rightAttacks, dist);
        dist = UpdateMaxDist(backAttacks, dist);

        Print(ownner.GetName() + " max attack dist = " + dist);
        dist += 10.0f;
        MAX_ATTACK_DIST = Min(MAX_ATTACK_DIST, dist);

        for (uint i=0; i<forwardAttacks.length; ++i)
        {
            if (forwardAttacks[i].impactDist >= closeDist)
                break;
            forwadCloseNum++;
        }
        for (uint i=0; i<rightAttacks.length; ++i)
        {
            if (rightAttacks[i].impactDist >= closeDist)
                break;
            rightCloseNum++;
        }
        for (uint i=0; i<backAttacks.length; ++i)
        {
            if (backAttacks[i].impactDist >= closeDist)
                break;
            backCloseNum++;
        }
        for (uint i=0; i<leftAttacks.length; ++i)
        {
            if (leftAttacks[i].impactDist >= closeDist)
                break;
            leftCloseNum++;
        }

        if (d_log)
            Dump();
    }
};


class PlayerCounterState : CharacterCounterState
{
    Array<Enemy@>   counterEnemies;
    Array<int>      intCache;
    int             lastCounterIndex = -1;
    int             lastCounterDirection = -1;

    PlayerCounterState(Character@ c)
    {
        super(c);
        intCache.Reserve(50);
    }

    void Update(float dt)
    {
        if (counterEnemies.empty || currentMotion is null)
        {
            ownner.CommonStateFinishedOnGroud(); // Something Error Happened
            return;
        }
        CharacterCounterState::Update(dt);
    }

    void ChooseBestIndices(Motion@ alignMotion, int index)
    {
        Vector4 v4 = GetTargetTransform(ownner.GetNode(), alignMotion, currentMotion);
        Vector3 v3 = Vector3(v4.x, 0.0f, v4.z);

        float minDistSQR = 999999;
        int possed = -1;

        for (uint i=0; i<counterEnemies.length; ++i)
        {
            Enemy@ e = counterEnemies[i];
            CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());

            if (s.index >= 0)
                continue;

            Vector3 ePos = e.GetNode().worldPosition;
            Vector3 diff = v3 - ePos;
            diff.y = 0;

            float disSQR = diff.lengthSquared;
            if (disSQR < minDistSQR)
            {
                minDistSQR = disSQR;
                possed = i;
            }
        }

        Enemy@ e = counterEnemies[possed];
        if (minDistSQR > GOOD_COUNTER_DIST * GOOD_COUNTER_DIST)
        {
            Print(alignMotion.name + " too far");
            return;
        }

        CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
        @s.currentMotion = alignMotion;
        s.index = possed;
        s.SetTargetTransform(Vector3(v4.x, e.GetNode().worldPosition.y, v4.z), v4.w);
    }

    int GetValidNumOfCounterEnemy()
    {
        int num = 0;
        for (uint i=0; i<counterEnemies.length; ++i)
        {
            Enemy@ e = counterEnemies[i];
            CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
            if (s.index >= 0)
                num ++;
        }
        return num;
    }

    int TestTrippleCounterMotions(int i)
    {
        for (uint k=0; k<counterEnemies.length; ++k)
            cast<CharacterCounterState>(counterEnemies[k].GetState()).index = -1;

        CharacterCounterState@ s = cast<CharacterCounterState>(counterEnemies[0].GetState());
        @currentMotion = tripleCounterMotions[i];
        Motion@ m1 = s.tripleCounterMotions[i * 3 + 0];
        ChooseBestIndices(m1, 0);
        Motion@ m2 = s.tripleCounterMotions[i * 3 + 1];
        ChooseBestIndices(m2, 1);
        Motion@ m3 = s.tripleCounterMotions[i * 3 + 2];
        ChooseBestIndices(m3, 2);
        return GetValidNumOfCounterEnemy();
    }

    int TestDoubleCounterMotions(int i)
    {
        for (uint k=0; k<counterEnemies.length; ++k)
            cast<CharacterCounterState>(counterEnemies[k].GetState()).index = -1;

        CharacterCounterState@ s = cast<CharacterCounterState>(counterEnemies[0].GetState());
        @currentMotion = doubleCounterMotions[i];
        Motion@ m1 = s.doubleCounterMotions[i * 2 + 0];
        ChooseBestIndices(m1, 0);
        Motion@ m2 = s.doubleCounterMotions[i * 2 + 1];
        ChooseBestIndices(m2, 1);
        return GetValidNumOfCounterEnemy();
    }

    void Enter(State@ lastState)
    {
        Print("############# PlayerCounterState::Enter ##################");

        uint t = time.systemTime;

        CharacterCounterState::Enter(lastState);

        Print("PlayerCounter-> counterEnemies len=" + counterEnemies.length);
        type = counterEnemies.length;

        // POST_PROCESS
        for (int i=0; i<type; ++i)
        {
            Enemy@ e = counterEnemies[i];
            e.ChangeState("CounterState");
            CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
            s.index = -1;
            s.type = type;
            s.ChangeSubState(COUNTER_ALIGNING);
        }

        if (counterEnemies.length == 3)
        {
            for (uint i=0; i<tripleCounterMotions.length; ++i)
            {
                if (TestTrippleCounterMotions(i) == 3)
                    break;
            }

            for (uint i=0; i<counterEnemies.length; ++i)
            {
                Enemy@ e = counterEnemies[i];
                CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
                if (s.index < 0)
                {
                    e.CommonStateFinishedOnGroud();
                    counterEnemies.Erase(i);
                }
            }

            ChangeSubState(COUNTER_WAITING);
        }

        if (counterEnemies.length == 2)
        {
            for (uint i=0; i<doubleCounterMotions.length; ++i)
            {
                if (TestDoubleCounterMotions(i) == 2)
                    break;
            }

            for (uint i=0; i<counterEnemies.length; ++i)
            {
                Enemy@ e = counterEnemies[i];
                CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
                if (s.index < 0)
                {
                    e.CommonStateFinishedOnGroud();
                    counterEnemies.Erase(i);
                }
            }

            ChangeSubState(COUNTER_WAITING);
        }

        if (counterEnemies.length == 1)
        {
            Node@ myNode = ownner.GetNode();
            Vector3 myPos = myNode.worldPosition;

            Enemy@ e = counterEnemies[0];
            Node@ eNode = e.GetNode();
            float dAngle = ownner.ComputeAngleDiff(eNode);
            bool isBack = false;
            if (Abs(dAngle) > 90)
                isBack = true;

            e.ChangeState("CounterState");

            int attackType = eNode.vars[ATTACK_TYPE].GetInt();
            CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
            Array<Motion@>@ counterMotions = GetCounterMotions(attackType, isBack);
            Array<Motion@>@ eCounterMotions = s.GetCounterMotions(attackType, isBack);

            intCache.Clear();
            float maxDistSQR = COUNTER_ALIGN_MAX_DIST * COUNTER_ALIGN_MAX_DIST;
            float bestDistSQR = 999999;
            int bestIndex = -1;

            for (uint i=0; i<counterMotions.length; ++i)
            {
                Motion@ alignMotion = counterMotions[i];
                Motion@ baseMotion = eCounterMotions[i];
                Vector4 v4 = GetTargetTransform(eNode, alignMotion, baseMotion);
                Vector3 v3 = Vector3(v4.x, myPos.y, v4.z);
                float distSQR = (v3 - myPos).lengthSquared;
                if (distSQR < bestDistSQR)
                {
                    bestDistSQR = distSQR;
                    bestIndex = int(i);
                }
                if (distSQR > maxDistSQR)
                    continue;
                intCache.Push(i);
            }

            Print("CounterState - intCache.length=" + intCache.length);
            int cur_direction = GetCounterDirection(attackType, isBack);
            int idx;
            if (intCache.empty)
            {
                idx = bestIndex;
            }
            else
            {
                int k = RandomInt(intCache.length);
                idx = intCache[k];
                if (cur_direction == lastCounterDirection && idx == lastCounterIndex)
                {
                    k = (k + 1) % intCache.length;
                    idx = intCache[k];
                }
            }

            lastCounterDirection = cur_direction;
            lastCounterIndex = idx;

            @currentMotion = counterMotions[idx];
            @s.currentMotion = eCounterMotions[idx];
            Print("Counter-align angle-diff=" + dAngle + " isBack=" + isBack + " name:" + currentMotion.animationName);

            s.ChangeSubState(COUNTER_WAITING);
            ChangeSubState(COUNTER_ALIGNING);

            Vector4 vt = GetTargetTransform(eNode, currentMotion, s.currentMotion);
            SetTargetTransform(Vector3(vt.x, myPos.y, vt.z), vt.w);
        }

        Print("PlayerCounterState::Enter time-cost=" + (time.systemTime - t));
    }

    void Exit(State@ nextState)
    {
        Print("############# PlayerCounterState::Exit ##################");
        CharacterCounterState::Exit(nextState);
        if (nextState !is this)
            counterEnemies.Clear();
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(targetPosition, 1.0f, RED, false);
        DebugDrawDirection(debug, ownner.GetNode(), targetRotation, YELLOW);
    }

    void StartAnimating()
    {
        StartCounterMotion();
        for (uint i=0; i<counterEnemies.length; ++i)
        {
            CharacterCounterState@ s = cast<CharacterCounterState>(counterEnemies[i].GetState());
            s.StartCounterMotion();
        }
    }

    void OnAlignTimeOut()
    {
        CharacterCounterState::OnAlignTimeOut();
        StartAnimating();
    }

    void OnWaitingTimeOut()
    {
        CharacterCounterState::OnWaitingTimeOut();
        StartAnimating();
    }

    void StartCounterMotion()
    {
        CharacterCounterState::StartCounterMotion();
        gCameraMgr.CheckCameraAnimation(currentMotion.name);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == READY_TO_FIGHT)
            ownner.OnCounterSuccess();
        CharacterState::OnAnimationTrigger(animState, eventData);
    }

    bool CanReEntered()
    {
        return true;
    }
};

class PlayerHitState : MultiMotionState
{
    PlayerHitState(Character@ c)
    {
        super(c);
        SetName("HitState");
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
            if (motions[selectIndex].Move(ownner, dt))
            {
                state = 1;
                gGame.OnCharacterKilled(null, ownner);
            }
        }
        CharacterState::Update(dt);
    }
};

class PlayerBeatDownEndState : MultiMotionState
{
    PlayerBeatDownEndState(Character@ c)
    {
        super(c);
        SetName("BeatDownEndState");
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        if (selectIndex >= int(motions.length))
        {
            Print("ERROR: a large animation index=" + selectIndex + " name:" + ownner.GetName());
            selectIndex = 0;
        }

        if (cast<Player>(ownner).CheckLastKill())
            ownner.SetSceneTimeScale(LAST_KILL_SPEED);

        Character@ target = ownner.target;
        if (target !is null)
        {
            Motion@ m1 = motions[selectIndex];
            ThugBeatDownEndState@ state = cast<ThugBeatDownEndState>(target.FindState("BeatDownEndState"));
            Motion@ m2 = state.motions[selectIndex];
            Vector4 t = GetTargetTransform(target.GetNode(), m1, m2);
            ownner.Transform(Vector3(t.x, ownner.GetNode().worldPosition.y, t.z), Quaternion(0, t.w, 0));
            target.GetNode().vars[ANIMATION_INDEX] = selectIndex;
            target.ChangeState("BeatDownEndState");
        }

        if (d_log)
            Print(ownner.GetName() + " state=" + name + " pick " + motions[selectIndex].animationName);
        motions[selectIndex].Start(ownner);

        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        Print("BeatDownEndState Exit!!");
        ownner.SetSceneTimeScale(1.0f);
        MultiMotionState::Exit(nextState);
    }

    int PickIndex()
    {
        return RandomInt(motions.length);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == IMPACT)
        {
            Node@ boneNode = ownner.GetNode().GetChild(eventData[VALUE].GetString(), true);
            Vector3 position = ownner.GetNode().worldPosition;
            if (boneNode !is null)
                position = boneNode.worldPosition;
            ownner.SpawnParticleEffect(position, "Particle/SnowExplosionFade.xml", 5, 10.0f);
            ownner.SpawnParticleEffect(position, "Particle/HitSpark.xml", 0.5f, 0.5f);
            ownner.PlayRandomSound(1);
            combatReady = true;
            Character@ target = ownner.target;
            if (target !is null)
            {
                Vector3 dir = ownner.GetNode().worldPosition - target.GetNode().worldPosition;
                dir.y = 0;
                dir.Normalize();
                target.OnDamage(ownner, position, dir, 9999, false);
                ownner.OnAttackSuccess(target);
            }
            return;
        }
        CharacterState::OnAnimationTrigger(animState, eventData);
    }
};

class PlayerBeatDownHitState : MultiMotionState
{
    int beatIndex = 0;
    int beatNum = 0;
    int maxBeatNum = 15;
    int minBeatNum = 7;
    int beatTotal = 0;

    float alignTime = 0.1f;
    Vector3 movePerSec;
    Vector3 targetPosition;
    float targetRotation;

    int state = 0;
    bool needToTransition = false;
    bool attackPressed = false;

    PlayerBeatDownHitState(Character@ c)
    {
        super(c);
        SetName("BeatDownHitState");
        flags = FLAGS_ATTACK;
    }

    bool CanReEntered()
    {
        return true;
    }

    bool IsTransitionNeeded(float curDist)
    {
        return false;
    }

    void Update(float dt)
    {
        // Print("PlayerBeatDownHitState::Update() " + dt);
        Character@ target = ownner.target;
        if (target is null)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        if (needToTransition)
        {
            ownner.ChangeState("TransitionState");
            PlayerTransitionState@ s = cast<PlayerTransitionState>(ownner.GetState());
            if (s !is null)
            {
                s.nextStateName = name;
                return;
            }
        }

        if (state == 0)
        {
            ownner.MoveTo(ownner.GetNode().worldPosition + movePerSec * dt, dt);

            if (timeInState >= alignTime)
            {
                Print("PlayerBeatDownHitState::Update align time-out");
                state = 1;
                HitStart(false, beatIndex, false);
                timeInState = 0.0f;
            }
        }
        else if (state == 1)
        {
            if (gInput.IsAttackPressed())
                attackPressed = true;

            if (combatReady && attackPressed)
            {
                ++ beatIndex;
                ++ beatNum;
                beatIndex = beatIndex % motions.length;
                ownner.ChangeState("BeatDownHitState");
                return;
            }

            if (gInput.IsCounterPressed())
            {
                ownner.Counter();
                return;
            }

            if (motions[selectIndex].Move(ownner, dt)) {
                Print("Beat Animation finished");
                OnMotionFinished();
                return;
            }
        }

        CharacterState::Update(dt);
    }

    void HitStart(bool bFirst, int i, bool checkDist)
    {
        Character@ target = ownner.target;
        if (target is null)
            return;

        if (checkDist)
        {
            float curDist = ownner.GetTargetDistance();
            // Print("HitStart bFirst=" + bFirst + " i=" + i + " current-dist=" + curDist);
            needToTransition = IsTransitionNeeded(curDist - PLAYER_COLLISION_DIST);
        }

        MultiMotionState@ s = cast<MultiMotionState>(ownner.target.FindState("BeatDownHitState"));
        Motion@ m1 = motions[i];
        Motion@ m2 = s.motions[i];

        Vector3 myPos = ownner.GetNode().worldPosition;
        if (bFirst)
        {
            Vector3 dir = myPos - target.GetNode().worldPosition;
            float e_targetRotation = Atan2(dir.x, dir.z);
            target.GetNode().worldRotation = Quaternion(0, e_targetRotation, 0);
        }

        Vector4 t = GetTargetTransform(target.GetNode(), m1, m2);
        targetRotation = t.w;
        targetPosition = Vector3(t.x, myPos.y, t.z);
        ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);

        if (bFirst)
        {
            state = 0;
            movePerSec = (targetPosition - myPos)/alignTime;
        }
        else
        {
            state = 1;
            ownner.GetNode().worldPosition = targetPosition;
            target.GetNode().vars[ANIMATION_INDEX] = i;
            motions[i].Start(ownner);
            selectIndex = i;
            target.ChangeState("BeatDownHitState");
        }
    }

    void Enter(State@ lastState)
    {
        //Print("========================= BeatDownHitState Enter start ===========================");
        attackPressed = false;
        needToTransition = false;
        if (lastState !is this)
        {
            beatNum = 0;
            beatTotal = RandomInt(minBeatNum, maxBeatNum);
        }
        HitStart(lastState !is this, beatIndex, lastState.name != "TransitionState");
        CharacterState::Enter(lastState);
        // Print("Beat Total = " + beatTotal + " Num = " + beatNum + " FROM " + lastState.name);
        //Print("========================= BeatDownHitState Enter end ===========================");
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == IMPACT)
        {
            // Print("BeatDownHitState On Impact");
            combatReady = true;
            Node@ boneNode = ownner.GetNode().GetChild(eventData[VALUE].GetString(), true);
            Vector3 position = ownner.GetNode().worldPosition;
            if (boneNode !is null)
                position = boneNode.worldPosition;
            ownner.SpawnParticleEffect(position, "Particle/SnowExplosionFade.xml", 5, 10.0f);
            ownner.SpawnParticleEffect(position, "Particle/HitSpark.xml", 0.5f, 0.4f);
            ownner.PlayRandomSound(0);

            ownner.OnAttackSuccess(ownner.target);

            if (beatNum >= beatTotal)
                ownner.ChangeState("BeatDownEndState");
            return;
        }
        CharacterState::OnAnimationTrigger(animState, eventData);
    }

    int PickIndex()
    {
        return beatIndex;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(targetPosition, 1.0f, RED, false);
        DebugDrawDirection(debug, ownner.GetNode(), targetRotation, YELLOW);
    }

    String GetDebugText()
    {
        return " name=" + name + " timeInState=" + String(timeInState) + " current motion=" + motions[selectIndex].animationName + "\n" +
        " combatReady=" + combatReady + " attackPressed=" + attackPressed + "\n";
    }
};

class PlayerTransitionState : SingleMotionState
{
    String nextStateName;

    PlayerTransitionState(Character@ c)
    {
        super(c);
        SetName("TransitionState");
    }

    void OnMotionFinished()
    {
        // Print(ownner.GetName() + " state:" + name + " finshed motion:" + motion.animationName);
        if (!nextStateName.empty)
            ownner.ChangeState(nextStateName);
        else
            ownner.CommonStateFinishedOnGroud();
    }

    void Enter(State@ lastState)
    {
        Character@ target = ownner.target;
        if (target !is null)
        {
            target.RequestDoNotMove();
            Vector3 dir = target.GetNode().worldPosition - ownner.GetNode().worldPosition;
            float angle = Atan2(dir.x, dir.z);
            ownner.GetNode().worldRotation = Quaternion(0, angle, 0);
            target.GetNode().worldRotation = Quaternion(0, angle + 180, 0);
        }
        SingleMotionState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        if (ownner.target !is null)
            ownner.target.RemoveFlag(FLAGS_NO_MOVE);
        Print("After Player Transition Target dist = " + ownner.GetTargetDistance());
    }

    String GetDebugText()
    {
        return " name=" + name + " timeInState=" + String(timeInState) + " nextState=" + nextStateName + "\n";
    }
};

class Player : Character
{
    int         combo;
    int         killed;
    uint        lastAttackId = M_MAX_UNSIGNED;
    uint        lightNodeId = M_MAX_UNSIGNED;

    void ObjectStart()
    {
        side = 1;
        Character::ObjectStart();
        AddStates();
        ChangeState("StandState");
        lightNodeId = GetScene().GetChild("light").id;

        Node@ tailNode = sceneNode.CreateChild("TailNode");
        ParticleEmitter@ emitter = tailNode.CreateComponent("ParticleEmitter");
        emitter.effect = cache.GetResource("ParticleEffect", "Particle/Tail.xml");
        tailNode.enabled = false;
    }

    void AddStates()
    {
    }

    bool Counter()
    {
        // Print("Player::Counter");
        PlayerCounterState@ state = cast<PlayerCounterState>(stateMachine.FindState("CounterState"));
        if (state is null)
            return false;

        int len = PickCounterEnemy(state.counterEnemies);
        if (len == 0)
            return false;

        ChangeState("CounterState");
        return true;
    }

    bool Evade()
    {
        sceneNode.vars[ANIMATION_INDEX] = RadialSelectAnimation(4);
        ChangeState("EvadeState");
        return true;
    }

    void CommonStateFinishedOnGroud()
    {
        if (health > 0)
        {
            if (gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
                ChangeState("StandState");
            else
                ChangeState("MoveState");
        }
    }

    float GetTargetAngle()
    {
        return gInput.GetLeftAxisAngle() + gCameraMgr.GetCameraAngle();
    }

    bool OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        if (!CanBeAttacked()) {
            if (d_log)
                Print("OnDamage failed because I can no be attacked " + GetName());
            return false;
        }

        health -= damage;
        health = Max(0, health);
        combo = 0;

        SetHealth(health);

        int index = RadialSelectAnimation(attacker.GetNode(), 4);
        Print("Player::OnDamage RadialSelectAnimation index=" + index);

        if (health <= 0)
            OnDead();
        else
        {
            sceneNode.vars[ANIMATION_INDEX] = index;
            ChangeState("HitState");
        }

        StatusChanged();
        return true;
    }

    void OnAttackSuccess(Character@ target)
    {
        if (target is null)
        {
            Print("Player::OnAttackSuccess target is null");
            return;
        }

        combo ++;
        Print("OnAttackSuccess combo add to " + combo);

        if (target.health == 0)
        {
            killed ++;
            Print("killed add to " + killed);
            gGame.OnCharacterKilled(this, target);
        }

        StatusChanged();
    }

    void OnCounterSuccess()
    {
        combo ++;
        Print("OnCounterSuccess combo add to " + combo);
        StatusChanged();
    }

    void StatusChanged()
    {
        const int speed_up_combo = 10;
        float fov = BASE_FOV;

        if (combo < speed_up_combo)
        {
            SetTimeScale(1.0f);
        }
        else
        {
            int max_comb = 80;
            int c = Min(combo, max_comb);
            float a = float(c)/float(max_comb);
            const float max_time_scale = 1.35f;
            float time_scale = Lerp(1.0f, max_time_scale, a);
            SetTimeScale(time_scale);
            const float max_fov = 75;
            fov = Lerp(BASE_FOV, max_fov, a);
        }
        VariantMap data;
        data[TARGET_FOV] = fov;
        SendEvent("CameraEvent", data);
        gGame.OnPlayerStatusUpdate(this);
    }

    //====================================================================
    //      SMART ENEMY PICK FUNCTIONS
    //====================================================================
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
            float totalDir = Abs(AngleDiff(myDir - enemyDir));
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

    Enemy@ CommonPickEnemy(float maxDiffAngle, float maxDiffDist, int flags, bool checkBlock, bool checkLastAttack)
    {
        uint t = time.systemTime;
        Scene@ _scene = GetScene();
        EnemyManager@ em = cast<EnemyManager>(_scene.GetScriptObject("EnemyManager"));
        if (em is null)
            return null;

        // Find the best enemy
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 myDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        float myAngle = Atan2(myDir.x, myDir.z);
        float targetAngle = GetTargetAngle();
        em.scoreCache.Clear();

        Enemy@ attackEnemy = null;
        for (uint i=0; i<em.enemyList.length; ++i)
        {
            Enemy@ e = em.enemyList[i];
            if (!e.HasFlag(flags))
            {
                if (d_log)
                    Print(e.GetName() + " no flag: " + flags);
                em.scoreCache.Push(-1);
                continue;
            }

            Vector3 posDiff = e.GetNode().worldPosition - myPos;
            posDiff.y = 0;
            int score = 0;
            float dist = posDiff.length - PLAYER_COLLISION_DIST;

            if (dist > maxDiffDist)
            {
                if (d_log)
                    Print(e.GetName() + " far way from player");
                em.scoreCache.Push(-1);
                continue;
            }

            float enemyAngle = Atan2(posDiff.x, posDiff.z);
            float diffAngle = targetAngle - enemyAngle;
            diffAngle = AngleDiff(diffAngle);

            if (Abs(diffAngle) > maxDiffAngle)
            {
                if (d_log)
                    Print(e.GetName() + " diffAngle=" + diffAngle + " too large");
                em.scoreCache.Push(-1);
                continue;
            }

            if (d_log)
                Print("enemyAngle="+enemyAngle+" targetAngle="+targetAngle+" diffAngle="+diffAngle);

            int threatScore = 0;
            if (dist < 1.0f + COLLISION_SAFE_DIST)
            {
                CharacterState@ state = cast<CharacterState>(e.GetState());
                threatScore += int(state.GetThreatScore() * THREAT_SCORE);
            }
            int angleScore = int((180.0f - Abs(diffAngle))/180.0f * ANGLE_SCORE);
            int distScore = int((maxDiffDist - dist) / maxDiffDist * DIST_SCORE);
            score += distScore;
            score += angleScore;
            score += threatScore;

            if (checkLastAttack)
            {
                if (lastAttackId == e.sceneNode.id)
                {
                    if (diffAngle <= LAST_ENEMY_ANGLE)
                        score += LAST_ENEMY_SCORE;
                }
            }

            em.scoreCache.Push(score);

            if (d_log)
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

        if (attackEnemy !is null && checkBlock)
        {
            Print("CommonPicKEnemy-> attackEnemy is " + attackEnemy.GetName());
            Vector3 v_pos = sceneNode.worldPosition;
            v_pos.y = CHARACTER_HEIGHT / 2;
            Vector3 e_pos = attackEnemy.GetNode().worldPosition;
            e_pos.y = v_pos.y;
            Vector3 dir = e_pos - v_pos;
            float len = dir.length;
            dir.Normalize();
            Ray ray;
            ray.Define(v_pos, dir);
            PhysicsRaycastResult result = sceneNode.scene.physicsWorld.RaycastSingle(ray, len, COLLISION_LAYER_CHARACTER);
            if (result.body !is null)
            {
                Node@ n = result.body.node.parent;
                Enemy@ e = cast<Enemy>(n.scriptObject);
                if (e !is null && e !is attackEnemy && e.HasFlag(FLAGS_ATTACK))
                {
                    Print("Find a block enemy " + e.GetName() + " before " + attackEnemy.GetName());
                    @attackEnemy = e;
                }
            }
        }

        Print("CommonPicKEnemy() time-cost = " + (time.systemTime - t) + " ms");
        return attackEnemy;
    }

    void CommonCollectEnemies(Array<Enemy@>@ enemies, float maxDiffAngle, float maxDiffDist, int flags)
    {
        enemies.Clear();

        uint t = time.systemTime;
        Scene@ _scene = GetScene();
        EnemyManager@ em = cast<EnemyManager>(_scene.GetScriptObject("EnemyManager"));
        if (em is null)
            return;

        Vector3 myPos = sceneNode.worldPosition;
        Vector3 myDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        float myAngle = Atan2(myDir.x, myDir.z);
        float targetAngle = GetTargetAngle();

        for (uint i=0; i<em.enemyList.length; ++i)
        {
            Enemy@ e = em.enemyList[i];
            if (!e.HasFlag(flags))
                continue;
            Vector3 posDiff = e.GetNode().worldPosition - myPos;
            posDiff.y = 0;
            int score = 0;
            float dist = posDiff.length - PLAYER_COLLISION_DIST;
            if (dist > maxDiffDist)
                continue;
            float enemyAngle = Atan2(posDiff.x, posDiff.z);
            float diffAngle = targetAngle - enemyAngle;
            diffAngle = AngleDiff(diffAngle);
            if (Abs(diffAngle) > maxDiffAngle)
                continue;
            enemies.Push(e);
        }

        Print("CommonCollectEnemies() len=" + enemies.length + " time-cost = " + (time.systemTime - t) + " ms");
    }

    String GetDebugText()
    {
        return Character::GetDebugText() +  "health=" + health + " flags=" + flags +
              " combo=" + combo + " killed=" + killed + " timeScale=" + timeScale + " tAngle=" + GetTargetAngle() + "\n";
    }

    void Reset()
    {
        SetSceneTimeScale(1.0f);
        Character::Reset();
        combo = 0;
        killed = 0;
        gGame.OnPlayerStatusUpdate(this);
        VariantMap data;
        data[TARGET_FOV] = BASE_FOV;
        SendEvent("CameraEvent", data);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), PLAYER_NEAR_DIST, YELLOW, 32, false);
    }

    bool ActionCheck(bool bAttack, bool bDistract, bool bCounter, bool bEvade)
    {
        if (bAttack && gInput.IsAttackPressed())
            return Attack();

        if (bDistract && gInput.IsDistractPressed())
            return Distract();

        if (bCounter && gInput.IsCounterPressed())
            return Counter();

        if (bEvade && gInput.IsEvadePressed())
            return Evade();

        return false;
    }

    bool Attack()
    {
        Print("Do--Attack--->");
        Enemy@ e = CommonPickEnemy(90, MAX_ATTACK_DIST, FLAGS_ATTACK, true, true);
        SetTarget(e);
        if (e !is null && e.HasFlag(FLAGS_STUN))
            ChangeState("BeatDownHitState");
        else
            ChangeState("AttackState");
        return true;
    }

    bool Distract()
    {
        Print("Do--Distract--->");
        Enemy@ e = CommonPickEnemy(45, MAX_ATTACK_DIST, FLAGS_ATTACK | FLAGS_STUN, true, true);
        if (e is null)
            return false;
        SetTarget(e);
        ChangeState("BeatDownHitState");
        return true;
    }

    bool CheckLastKill()
    {
        EnemyManager@ em = cast<EnemyManager>(sceneNode.scene.GetScriptObject("EnemyManager"));
        if (em is null)
            return false;

        int alive = em.GetNumOfEnemyAlive();
        Print("CheckLastKill() alive=" + alive);
        if (alive == 1)
        {
            VariantMap data;
            data[NODE] = target.GetNode().id;
            data[NAME] = CHANGE_STATE;
            data[VALUE] = StringHash("Death");
            SendEvent("CameraEvent", data);
            return true;
        }
        return false;
    }

    void SetTarget(Character@ t)
    {
        if (target is t)
            return;
        if (target !is null)
            target.RemoveFlag(FLAGS_NO_MOVE);
        Character::SetTarget(t);
    }

    void Update(float dt)
    {
        Node@ lightNode = GetScene().GetNode(lightNodeId);
        if (lightNode !is null)
        {
            Vector3 v = sceneNode.worldPosition;
            float h = lightNode.worldPosition.y;
            lightNode.worldPosition = Vector3(v.x, h, v.z);
        }

        Character::Update(dt);
    }
};
