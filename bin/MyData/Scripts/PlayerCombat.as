
enum AttackStateType
{
    ATTACK_STATE_ALIGN,
    ATTACK_STATE_BEFORE_IMPACT,
    ATTACK_STATE_AFTER_IMPACT,
};

class PlayerAttackState : CharacterState
{
    Array<Motion@>@         forwardAttacks;
    Array<Motion@>@         leftAttacks;
    Array<Motion@>@         rightAttacks;
    Array<Motion@>@         backAttacks;

    Motion@                 currentAttack;

    int                     state;
    Vector3                 targetPosition;
    Vector3                 motionPosition;

    float                   alignTime = 0.2f;

    float                   motionRotation;
    float                   targetRotation;
    float                   yawPerSec;

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

    Vector3                 lastDockBonePosition;
    Vector3                 lastFrameDockBonePosition;

    PlayerAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");
        flags = FLAGS_ATTACK;
    }

    ~PlayerAttackState()
    {
        @forwardAttacks = null;
        @leftAttacks = null;
        @rightAttacks = null;
        @backAttacks = null;
        @currentAttack = null;
    }

    float GetMaxDist(Array<Motion@>@ attacks, float dist)
    {
        if (attacks.empty)
            return dist;
        return Max(attacks[attacks.length-1].endDistance, dist);
    }

    void ChangeSubState(int newState)
    {
        LogPrint("PlayerAttackState changeSubState from " + state + " to " + newState);
        state = newState;
    }

    void Update(float dt)
    {
        Node@ _node = ownner.GetNode();
        Node@ tailNode = _node.GetChild("TailNode", true);
        Node@ attackNode = _node.GetChild(currentAttack.dockAlignBoneName, true);

        if (tailNode !is null && attackNode !is null) {
            tailNode.worldPosition = attackNode.worldPosition;
        }

        float t = ownner.animCtrl.GetTime(currentAttack.animationName);
        if (state == ATTACK_STATE_ALIGN)
        {
            ownner.motion_deltaRotation += yawPerSec * dt;

            float t1 = alignTime - 0.025f;
            if (t < t1 && t + dt > t1)
            {
                lastDockBonePosition = attackNode.worldPosition;
                if (debug_draw_flag > 0)
                    gDebugMgr.AddSphere(lastDockBonePosition, 0.25f, GREEN);
            }
        }


        if (slowMotion)
        {
            float t_diff = currentAttack.dockAlignTime - t;
            if (t_diff > 0 && t_diff < SEC_PER_FRAME * slowMotionFrames)
                ownner.SetSceneTimeScale(0.1f);
            else
                ownner.SetSceneTimeScale(1.0f);
        }

        if (state == ATTACK_STATE_AFTER_IMPACT)
            ownner.CheckTargetDistance(ownner.target);

        int ret = currentAttack.Move(ownner, dt);
        if (ret == 1) {
            OnMotionFinished();
            return;
        }
        else if (ret == 2)
        {
            OnDockAlignTimeOut();
        }

        CheckInput(t);
        CharacterState::Update(dt);

        if (debug_draw_flag > 0)
        {
            Vector3 curPos = attackNode.worldPosition;
            gDebugMgr.AddLine(lastFrameDockBonePosition, curPos, GREEN);
            lastFrameDockBonePosition = curPos;
        }
    }

    void OnMotionFinished()
    {
        LogPrint("Player::Attack finish attack movemont in sub state = " + state);
        ownner.CommonStateFinishedOnGroud();
    }

    void OnDockAlignTimeOut()
    {
        AttackImpact();
    }

    void CheckInput(float t)
    {
        if (ownner.IsInAir())
            return;

        int addition_frames = slowMotion ? slowMotionFrames : 0;
        bool check_attack = t > currentAttack.dockAlignTime + SEC_PER_FRAME * ( HIT_WAIT_FRAMES + 1 + addition_frames);
        bool check_others = t > currentAttack.dockAlignTime + SEC_PER_FRAME * addition_frames;
        uint actionFlags = check_attack ? (1 << kInputAttack) : 0;
        if (check_others)
        {
            actionFlags = Global_AddFlag(actionFlags, 1 << kInputCounter);
            actionFlags = Global_AddFlag(actionFlags, 1 << kInputEvade);
            actionFlags = Global_AddFlag(actionFlags, 1 << kInputDistract);
        }
        ownner.ActionCheck(actionFlags);
    }

    void PickBestMotion(Array<Motion@>@ attacks, int dir)
    {
        Vector3 myPos = ownner.GetNode().worldPosition;
        Vector3 enemyPos = ownner.target.GetNode().GetChild(PELVIS, true).worldPosition;
        Vector3 diff = enemyPos - myPos;
        diff.y = 0;
        // float toEnenmyDistance = Max(0.0f, diff.length - COLLISION_SAFE_DIST + 0.25f);
        float toEnenmyDistance = Max(0.0f, diff.length - 1.0f);

        /*float angleDif = ownner.target.ComputeAngleDiff(ownner.GetNode());
        if (Abs(angleDif) > 90)
        {
            // means thug is back face to us
            toEnenmyDistance = Max(0.0f, diff.length - COLLISION_RADIUS + 0.5f);
            LogPrint("Attack thug is back face player !!");
        }*/

        int bestIndex = 0;
        diff.Normalize();
        int index_start = -1;
        int index_num = 0;

        if (attack_choose_closest_one)
        {
            LogPrint("Player attack " + ownner.target.GetName() + " toEnenmyDistance = " + toEnenmyDistance);
            float dist_attack = 99999;
            for (uint i=0; i<attacks.length; ++i)
            {
                Motion@ m = attacks[i];
                if (d_log)
                    LogPrint("AttackMotion name="  + m.name  + " impactDist="+ m.dockDist);
                float d = Abs(m.dockDist - toEnenmyDistance);
                if (d < dist_attack)
                {
                    dist_attack = d;
                    bestIndex = i;
                }
            }

            LogPrint("Attack bestIndex="+bestIndex + " dist_attack=" + dist_attack);
        }
        else
        {
            float min_dist = Max(0.0f, toEnenmyDistance - ATTACK_DIST_PICK_SHORT_RANGE);
            float max_dist = toEnenmyDistance + ATTACK_DIST_PICK_LONG_RANGE;
            LogPrint("Player attack " + ownner.target.GetName() + " dist:" + toEnenmyDistance + "(" + min_dist + "," + max_dist + ")");

            for (uint i=0; i<attacks.length; ++i)
            {
                Motion@ m = attacks[i];
                if (m.dockDist > max_dist)
                    break;

                if (m.dockDist > min_dist)
                {
                    if (index_start == -1)
                        index_start = i;
                    index_num ++;

                    LogPrint("AttackMotion name="  + m.name  + " impactDist="+ m.dockDist);
                }
            }

            if (index_num == 0)
            {
                if (toEnenmyDistance > attacks[attacks.length - 1].dockDist)
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
                    LogPrint("Repeat Attack index index_num=" + index_num);
                    bestIndex = index_start + (r_n + 1) % index_num;
                }
                lastAttackDirection = dir;
                lastAttackIndex = bestIndex;
            }

            LogPrint("Attack bestIndex="+bestIndex+" index_start="+index_start+" index_num="+index_num);
        }

        @currentAttack = attacks[bestIndex];

        targetPosition = myPos + diff * toEnenmyDistance;
        LogPrint("PlayerAttack dir=" + lastAttackDirection + " index=" + lastAttackIndex +
                " Pick attack motion=" + currentAttack.animationName);

        if (debug_draw_flag > 0)
        {
            if (attack_choose_closest_one)
            {
                for (uint i=0; i<attacks.length; ++i)
                {
                    Vector3 v3 = attacks[i].GetFuturePosition(ownner, attacks[i].dockAlignTime);
                    gDebugMgr.AddCross(v3, 0.15f, SOURCE_COLOR, 2.0f);
                }
            }
            else
            {
                for (uint i=0; i<attacks.length; ++i)
                {
                    Vector3 v3 = attacks[i].GetFuturePosition(ownner, attacks[i].dockAlignTime);

                    if (i >= index_start && i < index_start + index_num)
                        gDebugMgr.AddCross(v3, 0.15f, TARGET_COLOR, 2.0f);
                    else
                        gDebugMgr.AddCross(v3, 0.15f, SOURCE_COLOR, 2.0f);
                }
            }
        }
    }

    void StartAttack()
    {
        Player@ p = cast<Player>(ownner);
        if (ownner.target !is null)
        {
            state = ATTACK_STATE_ALIGN;
            float diff = ownner.ComputeAngleDiff(ownner.target.GetNode());
            int r = DirectionMapToIndex(diff, 4);
            float targetAngle = 0;

            if (d_log)
                LogPrint("Attack-align " + " r-index=" + r + " diff=" + diff);

            if (r == 0)
            {
                PickBestMotion(forwardAttacks, r);
                targetAngle = 0;
            }
            else if (r == 1)
            {
                PickBestMotion(rightAttacks, r);
                targetAngle = 90;
            }
            else if (r == 2)
            {
                PickBestMotion(backAttacks, r);
                targetAngle = 180;
            }
            else if (r == 3)
            {
                PickBestMotion(leftAttacks, r);
                targetAngle = -90;
            }

            // yawPerSec = AngleDiff(AngleDiff(targetAngle - diff) / alignTime);

            ownner.target.RequestDoNotMove();
        }
        else
        {
            int index = ownner.RadialSelectAnimation(4);
            if (index == 0)
                @currentAttack = forwardAttacks[RandomInt(forwadCloseNum)];
            else if (index == 1)
                @currentAttack = rightAttacks[RandomInt(rightCloseNum)];
            else if (index == 2)
                @currentAttack = backAttacks[RandomInt(backCloseNum)];
            else if (index == 3)
                @currentAttack = leftAttacks[RandomInt(leftCloseNum)];
            state = ATTACK_STATE_BEFORE_IMPACT;

            // lost combo
            p.combo = 0;
            p.StatusChanged();
            LogPrint("PlayerAttack no target pick attack " + currentAttack.name);
        }

        currentAttack.Start(ownner);
        weakAttack = cast<Player>(ownner).combo < MAX_WEAK_ATTACK_COMBO;
        slowMotion = (p.combo >= 3) ? (RandomInt(10) == 1) : false;
        alignTime = currentAttack.dockAlignTime;

        if (ownner.target !is null)
        {
            float curAngle = ownner.GetCharacterAngle();
            motionPosition = currentAttack.GetDockAlignPositionAtTime(ownner, curAngle, alignTime);
            targetPosition.y = motionPosition.y;
            // motionPosition = currentAttack.GetImpactPosition(ownner);
            ownner.motion_velocity = ( targetPosition - motionPosition ) / alignTime;
            ownner.motion_velocity.y = 0;

            float futureRotation = currentAttack.GetFutureRotation(ownner, alignTime);
            float dockRotation = Atan2(currentAttack.dockAlignOffset.x, currentAttack.dockAlignOffset.z);
            motionRotation = futureRotation; //AngleDiff(dockRotation + futureRotation);
            // motionRotation = AngleDiff(motionRotation);
            Vector3 v = ownner.target.GetNode().worldPosition - ownner.GetNode().worldPosition;
            targetRotation = Atan2(v.x, v.z);

            // yawPerSec = AngleDiff(targetRotation - motionRotation) / alignTime;

            LogPrint("PlayerAttack ownner.motion_velocity=" + ownner.motion_velocity.ToString() +
                     " motion.dockAlignOffset=" + currentAttack.dockAlignOffset.ToString() +
                     " motionRotation=" + motionRotation + " targetRotation=" + targetRotation + " dockRotation=" + dockRotation +
                     " yawPerSec=" + yawPerSec);

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

        if (debug_mode == 2)
            weakAttack = true;
        else if (debug_mode == 4)
            weakAttack = false;

        ownner.SetNodeEnabled("TailNode", true);
    }

    void Enter(State@ lastState)
    {
        LogPrint("################## Player::AttackState Enter from " + lastState.name  + " #####################");
        lastKill = false;
        slowMotion = false;
        @currentAttack = null;
        state = ATTACK_STATE_ALIGN;
        yawPerSec = 0;
        StartAttack();
        CharacterState::Enter(lastState);
        lastDockBonePosition =  ownner.GetNode().GetChild(currentAttack.dockAlignBoneName, true).worldPosition;
        lastFrameDockBonePosition = lastDockBonePosition;
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        ownner.SetNodeEnabled("TailNode", false);
        if (ownner.target !is null)
            ownner.target.RemoveFlag(FLAGS_NO_MOVE);
        @currentAttack = null;
        ownner.SetSceneTimeScale(1.0f);
        LogPrint("################## Player::AttackState Exit to " + nextState.name  + " #####################");
    }

    String GetDebugText()
    {
        return CharacterState::GetDebugText() +
                "currentAttack=" + currentAttack.animationName +
                " weakAttack=" + weakAttack +
                " slowMotion=" + slowMotion;
    }

    bool CanReEntered()
    {
        return true;
    }

    void AttackImpact()
    {
        ownner.motion_velocity = Vector3::ZERO;
        ChangeSubState(ATTACK_STATE_AFTER_IMPACT);

        Character@ e = ownner.target;
        if (e is null)
            return;

        e.RemoveFlag(FLAGS_NO_MOVE);

        Node@ _node = ownner.GetNode();
        Vector3 dir = _node.GetChild(currentAttack.dockAlignBoneName, true).worldPosition - e.GetNode().worldPosition;
        dir.y = 0;
        if (dir.length > MAX_ATTACK_CHECK_DIST)
        {
            if (debug_draw_flag > 0)
                DebugPause(true);
            LogPrint("PlayerAttack " + e.GetName() + " dist too far way !!");
            return;
        }

        LogPrint("PlayerAttackState::" +  e.GetName() + " OnDamage!!!!");

        Node@ n = _node.GetChild(currentAttack.dockAlignBoneName, true);
        Vector3 position = _node.worldPosition;
        if (n !is null)
            position = n.worldPosition;

        Vector3 vPos = _node.GetChild(currentAttack.dockAlignBoneName, true).worldPosition;
        dir = vPos - lastDockBonePosition;
        dir.Normalize();

        Vector3 pelvisPos = _node.GetChild(PELVIS, true).worldPosition;

        Vector3 dir2 = vPos - pelvisPos;
        dir2.Normalize();

        float hAngle = Atan2(dir.x, dir.z);
        float tAngle = Atan2(dir2.x, dir2.z);

        if (debug_draw_flag > 0)
        {
            gDebugMgr.AddDirection(vPos, dir, 5.0f, RED);
            gDebugMgr.AddDirection(vPos, dir2, 5.0f, BLACK);
        }

        if (Abs(tAngle - hAngle) > 100)
        {
            LogPrint("Angle Diff too much, chooose pelvis angle.");
            dir = dir2;
        }

        int damage = ownner.attackDamage;
        if (lastKill)
            damage = 9999;
        else
            damage = RandomInt(ownner.attackDamage, ownner.attackDamage + 20);

        if (debug_mode != 1)
        {
            bool b = e.OnDamage(ownner, position, dir, damage, weakAttack);
            if (!b)
                return;
        }

        ownner.SpawnParticleEffect(position, "Particle/HitDust.xml", 1.0f, 1.0f);
        // ownner.SpawnParticleEffect(position, "Particle/HitSpark.xml", 1.0f, 0.6f);

        int sound_type = e.health == 0 ? 1 : 0;
        ownner.PlayRandomSound(sound_type);
        ownner.OnAttackSuccess(e);

        if (debug_mode == 1 || debug_mode == 3 || debug_mode == 4)
        {
            DebugPause(true);

            if (debug_mode == 1)
                DebugTimeScale(0.1f);
        }
    }

    void PostInit(float closeDist = 2.5f)
    {
        if (forwardAttacks is null)
            return;

        forwardAttacks.Sort();
        leftAttacks.Sort();
        rightAttacks.Sort();
        backAttacks.Sort();

        float dist = 0.0f;
        dist = GetMaxDist(forwardAttacks, dist);
        dist = GetMaxDist(leftAttacks, dist);
        dist = GetMaxDist(rightAttacks, dist);
        dist = GetMaxDist(backAttacks, dist);
        MAX_ATTACK_DIST = Min(MAX_ATTACK_DIST, dist + 5.0f);
        MAX_ATTACK_DIST += COLLISION_SAFE_DIST;
        LogPrint(ownner.GetName() + " animation max attack dist = " + dist + " MAX_ATTACK_DIST=" + MAX_ATTACK_DIST);

        for (uint i=0; i<forwardAttacks.length; ++i)
        {
            if (forwardAttacks[i].dockDist >= closeDist)
                break;
            forwadCloseNum++;
        }
        for (uint i=0; i<rightAttacks.length; ++i)
        {
            if (rightAttacks[i].dockDist >= closeDist)
                break;
            rightCloseNum++;
        }
        for (uint i=0; i<backAttacks.length; ++i)
        {
            if (backAttacks[i].dockDist >= closeDist)
                break;
            backCloseNum++;
        }
        for (uint i=0; i<leftAttacks.length; ++i)
        {
            if (leftAttacks[i].dockDist >= closeDist)
                break;
            leftCloseNum++;
        }
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentAttack is null || ownner.target is null)
            return;

        debug.AddLine(ownner.GetNode().worldPosition, ownner.target.GetNode().worldPosition, GREEN, false);
        AddDebugMark(debug, targetPosition, TARGET_COLOR, 0.25f);
        AddDebugMark(debug, motionPosition,  SOURCE_COLOR, 0.25f);
        //Vector3 v = ownner.GetNode().worldPosition;
        //DebugDrawDirection(debug, v, motionRotation, SOURCE_COLOR, 5.0f);
        //DebugDrawDirection(debug, v, targetRotation, TARGET_COLOR, 5.0f);
        currentAttack.DebugDraw(debug, ownner);
    }
};

class PlayerCounterState : CharacterCounterState
{
    Array<Enemy@>   counterEnemies;
    Array<Vector4>  environmentCounterStartOffsets;
    int             lastCounterIndex = -1;
    int             lastCounterDirection = -1;

    PlayerCounterState(Character@ c)
    {
        super(c);
    }

    void Enter(State@ lastState)
    {
        LogPrint("############# PlayerCounterState::Enter ##################");
        uint t = time.systemTime;

        LogPrint("PlayerCounter-> counterEnemies len=" + counterEnemies.length);

        for (int i=0; i<counterEnemies.length; ++i)
        {
            Enemy@ e = counterEnemies[i];
            e.ChangeState("CounterState");
            CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
            s.index = -1;
        }

        if (counterEnemies.length == 3)
        {
            TripleCounter();
        }

        if (counterEnemies.length == 2)
        {
            DoubleCounter();
        }

        if (counterEnemies.length == 1)
        {
            if (!EnvironmentCounter())
                SingleCounter();
        }

        LogPrint("PlayerCounterState::Enter time-cost=" + (time.systemTime - t));
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        LogPrint("############# PlayerCounterState::Exit ##################");
        CharacterCounterState::Exit(nextState);
        counterEnemies.Clear();
        // ownner.GetScene().timeScale = 1.0f;
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

    void SingleCounter()
    {
        bool alignPlayer = true;
        Node@ myNode = ownner.GetNode();
        Vector3 myPos = myNode.worldPosition;

        Enemy@ e = counterEnemies[0];
        Node@ eNode = e.GetNode();
        Vector3 ePos = eNode.worldPosition;
        float dAngle = ownner.ComputeAngleDiff(eNode);
        bool isBack = false;
        if (Abs(dAngle) > 90)
            isBack = true;

        e.ChangeState("CounterState");
        ownner.SetTarget(e);

        int attackType = eNode.vars[ATTACK_TYPE].GetInt();
        CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
        Array<Motion@>@ counterMotions = GetCounterMotions(attackType, isBack);
        Array<Motion@>@ eCounterMotions = s.GetCounterMotions(attackType, isBack);

        const float maxDistSQR = COUNTER_ALIGN_MAX_DIST * COUNTER_ALIGN_MAX_DIST;
        float bestDistSQR = 999999;
        int bestIndex = -1;
        g_int_cache.Clear();

        for (uint i=0; i<counterMotions.length; ++i)
        {
            Motion@ alignMotion = counterMotions[i];
            Motion@ baseMotion = eCounterMotions[i];
            float distSQR = GetTargetTransformErrorSqr(myNode, eNode, alignMotion, baseMotion);
            if (distSQR < bestDistSQR)
            {
                bestDistSQR = distSQR;
                bestIndex = int(i);
            }
            // Print("distSQR=" + distSQR + " maxDistSQR=" + maxDistSQR);
            if (distSQR > maxDistSQR)
                continue;
            g_int_cache.Push(i);
        }

        float bestDistSQR2 = 999999;
        int bestIndex2 = -1;
        for (uint i=0; i<counterMotions.length; ++i)
        {
            Motion@ alignMotion = eCounterMotions[i];
            Motion@ baseMotion = counterMotions[i];
            float distSQR = GetTargetTransformErrorSqr(eNode, myNode, alignMotion, baseMotion);
            if (distSQR < bestDistSQR2)
            {
                bestDistSQR2 = distSQR;
                bestIndex2 = int(i);
            }
        }

        int cur_direction = GetCounterDirection(attackType, isBack);
        int idx;
        LogPrint("COUNTER bestDistSQR=" + bestDistSQR + " bestDistSQR2=" + bestDistSQR2 + " g_int_cache.length=" + g_int_cache.length);

        if (counter_choose_closest_one || g_int_cache.empty)
        {
            if (bestDistSQR > maxDistSQR && bestDistSQR2 <= bestDistSQR)
            {
                idx = bestIndex2;
                alignPlayer = false;
            }
            else
                idx = bestIndex;
        }
        else
        {
            int k = RandomInt(g_int_cache.length);
            idx = g_int_cache[k];
            if (cur_direction == lastCounterDirection && idx == lastCounterIndex)
            {
                k = (k + 1) % g_int_cache.length;
                idx = g_int_cache[k];
            }
        }

        lastCounterDirection = cur_direction;
        lastCounterIndex = idx;

        @currentMotion = counterMotions[idx];
        @s.currentMotion = eCounterMotions[idx];
        LogPrint("COUNTER angle-diff=" + dAngle + " isBack=" + isBack + " name:" +
            currentMotion.animationName + " alignPlayer=" + alignPlayer);

        if (alignPlayer)
        {
            s.StartCounterMotion();
            SetTargetTransform(GetTargetTransform(eNode, currentMotion, s.currentMotion));
            StartAligning();
        }
        else
        {
            StartCounterMotion();
            s.SetTargetTransform(GetTargetTransform(myNode, s.currentMotion, currentMotion));
            s.StartAligning();
        }
    }

    void DoubleCounter()
    {
        Node@ myNode = ownner.GetNode();
        float min_error_sqr = 9999;
        int bestIndex = -1;
        Enemy@ e1 = counterEnemies[0];
        Enemy@ e2 = counterEnemies[1];
        Node@ eNode1 = e1.GetNode();
        Node@ eNode2 = e2.GetNode();
        Vector3 myPos = ownner.GetNode().worldPosition;
        CharacterCounterState@ s1 = cast<CharacterCounterState>(e1.GetState());
        CharacterCounterState@ s2 = cast<CharacterCounterState>(e2.GetState());
        Motion@ eMotion1, eMotion2;
        Motion@ motion1, motion2;
        int who_is_reference = -1;
        Array<Motion@>@ eDoubleMotions = s1.doubleMotions;

        for (uint i=0; i<doubleMotions.length; ++i)
        {
            Motion@ playerMotion = doubleMotions[i];

            // e1 as reference, e1 motion 0, e2 motion 1
            @motion1 = eDoubleMotions[i*2 + 0];
            @motion2 = eDoubleMotions[i*2 + 1];
            float err_player = GetTargetTransformErrorSqr(myNode, eNode1, playerMotion, motion1);
            float err_e = GetTargetTransformErrorSqr(eNode2, eNode1, motion2, motion1);
            float err_sum = err_player + err_e;
            if (err_sum < min_error_sqr)
            {
                bestIndex = i;
                who_is_reference = 0;
                min_error_sqr = err_sum;
                @eMotion1 = motion1;
                @eMotion2 = motion2;
            }

            // e1 as reference, e1 motion 1, e2 motion 0
            @motion1 = eDoubleMotions[i*2 + 1];
            @motion2 = eDoubleMotions[i*2 + 0];
            err_player = GetTargetTransformErrorSqr(myNode, eNode1, playerMotion, motion1);
            err_e = GetTargetTransformErrorSqr(eNode2, eNode1, motion2, motion1);
            err_sum = err_player + err_e;
            if (err_sum < min_error_sqr)
            {
                bestIndex = i;
                who_is_reference = 0;
                min_error_sqr = err_sum;
                @eMotion1 = motion1;
                @eMotion2 = motion2;
            }

            // e2 as reference, e1 motion 0, e2 motion 1
            @motion1 = eDoubleMotions[i*2 + 0];
            @motion2 = eDoubleMotions[i*2 + 1];
            err_player = GetTargetTransformErrorSqr(myNode, eNode2, playerMotion, motion2);
            err_e = GetTargetTransformErrorSqr(eNode1, eNode2, motion1, motion2);
            err_sum = err_player + err_e;
            if (err_sum < min_error_sqr)
            {
                bestIndex = i;
                who_is_reference = 1;
                min_error_sqr = err_sum;
                @eMotion1 = motion1;
                @eMotion2 = motion2;
            }

            // e2 as reference, e1 motion 1, e2 motion 0
            @motion1 = eDoubleMotions[i*2 + 1];
            @motion2 = eDoubleMotions[i*2 + 0];
            err_player = GetTargetTransformErrorSqr(myNode, eNode2, playerMotion, motion2);
            err_e = GetTargetTransformErrorSqr(eNode1, eNode2, motion1, motion2);
            err_sum = err_player + err_e;
            if (err_sum < min_error_sqr)
            {
                bestIndex = i;
                who_is_reference = 1;
                min_error_sqr = err_sum;
                @eMotion1 = motion1;
                @eMotion2 = motion2;
            }
        }

        Print("DoubleCounter bestIndex=" + bestIndex);

        if (bestIndex >= 0)
        {
            Node@ referenceNode = (who_is_reference == 0) ? eNode1 : eNode2;
            Node@ alignNode = (who_is_reference == 0) ? eNode2 : eNode1;
            CharacterCounterState@ referenceState = (who_is_reference == 0) ? s1 : s2;
            CharacterCounterState@ alignState = (who_is_reference == 0) ? s2 : s1;

            @currentMotion = doubleMotions[bestIndex];
            @s1.currentMotion = eMotion1;
            @s2.currentMotion = eMotion2;
            SetTargetTransform(GetTargetTransform(referenceNode, currentMotion, referenceState.currentMotion));
            StartAligning();
            referenceState.StartCounterMotion();
            alignState.SetTargetTransform(GetTargetTransform(referenceNode, alignState.currentMotion, referenceState.currentMotion));
            alignState.StartAligning();
        }
        else
        {
            counterEnemies.Erase(0);
        }
    }

    float TripleCounterTest(int i,
                            int referenceIdx,
                            int motionIdx1,
                            int motionIdx2,
                            int motionIdx3)
    {
        Enemy@ e1 = counterEnemies[0];
        Enemy@ e2 = counterEnemies[1];
        Enemy@ e3 = counterEnemies[2];
        Node@ eNode1 = e1.GetNode();
        Node@ eNode2 = e2.GetNode();
        Node@ eNode3 = e3.GetNode();
        Node@ playerNode = ownner.GetNode();
        Motion@ playerMotion = tripleMotions[i];
        CharacterCounterState@ s = cast<CharacterCounterState>(e1.GetState());
        Array<Motion@>@ eTripleMotions = s.tripleMotions;
        Motion@ m1 = eTripleMotions[i*3 + motionIdx1];
        Motion@ m2 = eTripleMotions[i*3 + motionIdx2];
        Motion@ m3 = eTripleMotions[i*3 + motionIdx3];

        Node@ referenceNode = counterEnemies[referenceIdx].GetNode();
        float err_player, err_other1, err_other2;

        if (referenceIdx == 0)
        {
            err_player = GetTargetTransformErrorSqr(playerNode, referenceNode, playerMotion, m1);
            err_other1 = GetTargetTransformErrorSqr(eNode2, referenceNode, m2, m1);
            err_other2 = GetTargetTransformErrorSqr(eNode3, referenceNode, m3, m1);
        }
        else if (referenceIdx == 1)
        {
            err_player = GetTargetTransformErrorSqr(playerNode, referenceNode, playerMotion, m2);
            err_other1 = GetTargetTransformErrorSqr(eNode1, referenceNode, m1, m2);
            err_other2 = GetTargetTransformErrorSqr(eNode3, referenceNode, m3, m2);
        }
        else
        {
            err_player = GetTargetTransformErrorSqr(playerNode, referenceNode, playerMotion, m3);
            err_other1 = GetTargetTransformErrorSqr(eNode1, referenceNode, m1, m3);
            err_other2 = GetTargetTransformErrorSqr(eNode2, referenceNode, m2, m3);
        }

        return err_player + err_other1 + err_other2;

    }

    void TripleCounter()
    {
        Node@ myNode = ownner.GetNode();
        float min_error_sqr = 9999;
        int bestIndex = -1;
        Enemy@ e1 = counterEnemies[0];
        Enemy@ e2 = counterEnemies[1];
        Enemy@ e3 = counterEnemies[2];
        Node@ eNode1 = e1.GetNode();
        Node@ eNode2 = e2.GetNode();
        Node@ eNode3 = e3.GetNode();
        CharacterCounterState@ s1 = cast<CharacterCounterState>(e1.GetState());
        CharacterCounterState@ s2 = cast<CharacterCounterState>(e2.GetState());
        CharacterCounterState@ s3 = cast<CharacterCounterState>(e3.GetState());
        Motion@ eMotion1, eMotion2, eMotion3;
        Motion@ motion1, motion2, motion3;
        int who_is_reference = -1;
        Array<Motion@>@ eTripleMotions = s1.tripleMotions;
        float error;
        int idx1, idx2, idx3, refIdx;

        for (uint i=0; i<tripleMotions.length; ++i)
        {
            Motion@ playerMotion = tripleMotions[i];

            for (int j=0; j<3; ++j)
            {
                refIdx = j;

                idx1 = 0; idx2 = 1; idx3 = 2;
                error = TripleCounterTest(i, refIdx, idx1, idx2, idx3);
                if (error < min_error_sqr)
                {
                    bestIndex = i;
                    who_is_reference = refIdx;
                    min_error_sqr = error;
                    @eMotion1 = eTripleMotions[i*3 + idx1];
                    @eMotion2 = eTripleMotions[i*3 + idx2];
                    @eMotion3 = eTripleMotions[i*3 + idx3];
                }

                idx1 = 0; idx2 = 2; idx3 = 1;
                error = TripleCounterTest(i, refIdx, idx1, idx2, idx3);
                if (error < min_error_sqr)
                {
                    bestIndex = i;
                    who_is_reference = refIdx;
                    min_error_sqr = error;
                    @eMotion1 = eTripleMotions[i*3 + idx1];
                    @eMotion2 = eTripleMotions[i*3 + idx2];
                    @eMotion3 = eTripleMotions[i*3 + idx3];
                }

                idx1 = 1; idx2 = 2; idx3 = 0;
                error = TripleCounterTest(i, refIdx, idx1, idx2, idx3);
                if (error < min_error_sqr)
                {
                    bestIndex = i;
                    who_is_reference = refIdx;
                    min_error_sqr = error;
                    @eMotion1 = eTripleMotions[i*3 + idx1];
                    @eMotion2 = eTripleMotions[i*3 + idx2];
                    @eMotion3 = eTripleMotions[i*3 + idx3];
                }

                idx1 = 1; idx2 = 0; idx3 = 2;
                error = TripleCounterTest(i, refIdx, idx1, idx2, idx3);
                if (error < min_error_sqr)
                {
                    bestIndex = i;
                    who_is_reference = refIdx;
                    min_error_sqr = error;
                    @eMotion1 = eTripleMotions[i*3 + idx1];
                    @eMotion2 = eTripleMotions[i*3 + idx2];
                    @eMotion3 = eTripleMotions[i*3 + idx3];
                }

                // e1 as reference, e1 motion 2, e2 motion 1, e3 motion 0
                idx1 = 2; idx2 = 1; idx3 = 0;
                error = TripleCounterTest(i, refIdx, idx1, idx2, idx3);
                if (error < min_error_sqr)
                {
                    bestIndex = i;
                    who_is_reference = refIdx;
                    min_error_sqr = error;
                    @eMotion1 = eTripleMotions[i*3 + idx1];
                    @eMotion2 = eTripleMotions[i*3 + idx2];
                    @eMotion3 = eTripleMotions[i*3 + idx3];
                }

                // e1 as reference, e1 motion 2, e2 motion 0, e3 motion 1
                idx1 = 2; idx2 = 0; idx3 = 1;
                error = TripleCounterTest(i, refIdx, idx1, idx2, idx3);
                if (error < min_error_sqr)
                {
                    bestIndex = i;
                    who_is_reference = refIdx;
                    min_error_sqr = error;
                    @eMotion1 = eTripleMotions[i*3 + idx1];
                    @eMotion2 = eTripleMotions[i*3 + idx2];
                    @eMotion3 = eTripleMotions[i*3 + idx3];
                }
            }
        }

        if (bestIndex >= 0)
        {

            Print("TripleCounter bestIndex=" + bestIndex +
                  " who_is_reference=" + who_is_reference +
                  " eMotion1=" + eMotion1.name +
                  " eMotion2=" + eMotion2.name +
                  " eMotion3=" + eMotion3.name);

            @currentMotion = tripleMotions[bestIndex];
            @s1.currentMotion = eMotion1;
            @s2.currentMotion = eMotion2;
            @s3.currentMotion = eMotion3;

            if (who_is_reference == 0)
            {
                s1.StartCounterMotion();
                SetTargetTransform(GetTargetTransform(eNode1, currentMotion, s1.currentMotion));
                StartAligning();
                s2.SetTargetTransform(GetTargetTransform(eNode1, s2.currentMotion, s1.currentMotion));
                s2.StartAligning();
                s3.SetTargetTransform(GetTargetTransform(eNode1, s3.currentMotion, s1.currentMotion));
                s3.StartAligning();
            }
            else if (who_is_reference == 1)
            {
                s2.StartCounterMotion();
                SetTargetTransform(GetTargetTransform(eNode2, currentMotion, s2.currentMotion));
                StartAligning();
                s1.SetTargetTransform(GetTargetTransform(eNode2, s1.currentMotion, s2.currentMotion));
                s1.StartAligning();
                s3.SetTargetTransform(GetTargetTransform(eNode2, s3.currentMotion, s2.currentMotion));
                s3.StartAligning();
            }
            else
            {
                s3.StartCounterMotion();
                SetTargetTransform(GetTargetTransform(eNode3, currentMotion, s3.currentMotion));
                StartAligning();
                s1.SetTargetTransform(GetTargetTransform(eNode3, s1.currentMotion, s3.currentMotion));
                s1.StartAligning();
                s2.SetTargetTransform(GetTargetTransform(eNode3, s2.currentMotion, s3.currentMotion));
                s2.StartAligning();
            }
        }
        else
        {
            counterEnemies.Erase(0);
        }
    }

    float TestWall(const Vector3&in position, float rotation, int& outIndex)
    {
        Enemy@ e = counterEnemies[0];
        Node@ eNode = e.GetNode();
        Vector3 ePos = eNode.worldPosition;
        Vector3 myPos = ownner.GetNode().worldPosition;

        int bestIndex = -1;
        float min_error_sqr = 99999;
        Vector3 basePosition = position;
        float baseRotation = rotation;
        CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());

        for (uint i=0; i<environmentMotions.length; ++i)
        {
            Motion@ playerMotion = environmentMotions[i];
            Motion@ enemyMotion = s.environmentMotions[i];
            Vector4 v = environmentCounterStartOffsets[i];
            Vector4 vt_player = GetTargetTransform(basePosition, baseRotation, Vector3(v.x, v.y, v.z), v.w, playerMotion);
            Vector4 vt_enemey = GetTargetTransform(basePosition, baseRotation, Vector3(v.x, v.y, v.z), v.w, enemyMotion);
            //gDebugMgr.AddSphere(Vector3(vt_player.x, vt_player.y, vt_player.z), 0.25f, BLUE, 2);
            //gDebugMgr.AddSphere(Vector3(vt_enemey.x, vt_enemey.y, vt_enemey.z), 0.25f, RED, 2);

            float err_player = (Vector3(vt_player.x, myPos.y, vt_player.z) - myPos).lengthSquared;
            float err_enemy = (Vector3(vt_enemey.x, vt_enemey.y, vt_enemey.z) - ePos).lengthSquared;
            if (err_player > GOOD_COUNTER_DIST * GOOD_COUNTER_DIST ||
                err_enemy > GOOD_COUNTER_DIST * GOOD_COUNTER_DIST)
            {
                continue;
            }

            float err_sum = err_player + err_enemy;
            if (err_sum < min_error_sqr)
            {
                bestIndex = int(i);
                min_error_sqr = err_sum;
            }
        }

        if (bestIndex >= 0)
        {
            Print("pick environment motions " + environmentMotions[bestIndex].name + " min_error_sqr=" + min_error_sqr);
        }

        outIndex = bestIndex;
        return min_error_sqr;
    }


    bool EnvironmentCounter()
    {
        Enemy@ e = counterEnemies[0];
        e.ChangeState("CounterState");
        CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
        ownner.SetTarget(e);
        Node@ eNode = e.GetNode();
        Vector3 ePos = eNode.worldPosition;
        Ray r(ePos, Vector3(0, 0, 1));
        const float detect_range = 6.0f;
        ePos.y += CHARACTER_HEIGHT / 2.0f;
        PhysicsRaycastResult front_result = PhysicsRayCast(ePos, Vector3(0, 0, 1), detect_range, COLLISION_LAYER_LANDSCAPE);
        PhysicsRaycastResult right_result = PhysicsRayCast(ePos, Vector3(1, 0, 0), detect_range, COLLISION_LAYER_LANDSCAPE);
        PhysicsRaycastResult back_result = PhysicsRayCast(ePos, Vector3(0, 0, -1), detect_range, COLLISION_LAYER_LANDSCAPE);
        PhysicsRaycastResult left_result = PhysicsRayCast(ePos, Vector3(-1, 0, 0), detect_range, COLLISION_LAYER_LANDSCAPE);

        Vector3 myPos = ownner.GetNode().worldPosition;
        int bestIndex = -1;
        float min_error_sqr = 9999;
        Vector3 wallPosition;
        float wallRotation = 0;

        if (front_result.body !is null)
        {
            int index = -1;
            float rotation = Atan2(front_result.normal.x, front_result.normal.z);
            float err = TestWall(front_result.position, rotation, index);
            if (err < min_error_sqr)
            {
                min_error_sqr = err;
                bestIndex = index;
                wallPosition = front_result.position;
                wallRotation = rotation;
            }
        }
        if (right_result.body !is null)
        {
            int index = -1;
            float rotation = Atan2(right_result.normal.x, right_result.normal.z);
            float err = TestWall(right_result.position, rotation, index);
            if (err < min_error_sqr)
            {
                min_error_sqr = err;
                bestIndex = index;
                wallPosition = right_result.position;
                wallRotation = rotation;
            }
        }
        if (back_result.body !is null)
        {
            int index = -1;
            float rotation = Atan2(back_result.normal.x, back_result.normal.z);
            float err = TestWall(back_result.position, rotation, index);
            if (err < min_error_sqr)
            {
                min_error_sqr = err;
                bestIndex = index;
                wallPosition = back_result.position;
                wallRotation = rotation;
            }
        }
        if (left_result.body !is null)
        {
            int index = -1;
            float rotation = Atan2(left_result.normal.x, left_result.normal.z);
            float err = TestWall(left_result.position, rotation, index);
            if (err < min_error_sqr)
            {
                min_error_sqr = err;
                bestIndex = index;
                wallPosition = left_result.position;
                wallRotation = rotation;
            }
        }

        if (bestIndex >= 0)
        {
            Motion@ playerMotion = environmentMotions[bestIndex];
            Motion@ enemyMotion = s.environmentMotions[bestIndex];
            @currentMotion = playerMotion;
            @s.currentMotion = enemyMotion;
            Vector4 v = environmentCounterStartOffsets[bestIndex];
            Vector4 vt_player = GetTargetTransform(wallPosition, wallRotation, Vector3(v.x, v.y, v.z), v.w, playerMotion);
            Vector4 vt_enemey = GetTargetTransform(wallPosition, wallRotation, Vector3(v.x, v.y, v.z), v.w, enemyMotion);
            SetTargetTransform(vt_player);
            s.SetTargetTransform(vt_enemey);
            StartAligning();
            s.StartAligning();
            return true;
        }
        return false;
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
        flags = FLAGS_DEAD;
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
            if (motions[selectIndex].Move(ownner, dt) == 1)
            {
                state = 1;
                gGame.OnCharacterKilled(null, ownner);
            }
        }
        CharacterState::Update(dt);
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
        // LogPrint(ownner.GetName() + " state:" + name + " finshed motion:" + motion.animationName);
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
        LogPrint("After Player Transition Target dist = " + ownner.GetTargetDistance());
    }

    String GetDebugText()
    {
        return CharacterState::GetDebugText() + " nextState=" + nextStateName;
    }
};


