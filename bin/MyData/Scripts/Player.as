// ==============================================
//
//    Player Pawn and Controller Class
//
// ==============================================

class Player : Character
{
    int             combo;
    int             killed;

    void ObjectStart()
    {
        Character::ObjectStart();

        side = 1;

        Node@ tailNode = sceneNode.CreateChild("TailNode");
        //ParticleEmitter@ emitter = tailNode.CreateComponent("ParticleEmitter");
        //emitter.effect = cache.GetResource("ParticleEffect", "Particle/Tail.xml");
        tailNode.enabled = false;
        RibbonTrail@ trail = tailNode.CreateComponent("RibbonTrail");
        trail.material = cache.GetResource("Material", "Materials/RibbonTrail.xml");
        trail.startColor = Color(1.0f, 0.0f, 0.0f, 1.0f);
        trail.endColor = Color(1.0f, 0.0f, 1.0f, 0.0f);
        trail.width = 0.25f;
        trail.tailColumn = 4;
        trail.updateInvisible = true;

        AddStates();
        ChangeState("StandState");
    }

    void AddStates()
    {
    }

    bool Counter()
    {
        // LogPrint("Player::Counter");
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
        ChangeState("EvadeState");
        return true;
    }

    void CommonStateFinishedOnGroud()
    {
        if (health <= 0)
            return;

        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
            ChangeState(player_walk ? "WalkState" : "RunState");
        else
            ChangeState("StandState");
    }

    float GetTargetAngle()
    {
        return gInput.GetLeftAxisAngle() + gCameraMgr.GetCameraAngle();
    }

    bool OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        if (!CanBeAttacked()) {
            if (d_log)
                LogPrint("OnDamage failed because I can no be attacked " + GetName());
            return false;
        }

        health -= damage;
        health = Max(0, health);
        combo = 0;

        SetHealth(health);

        int index = RadialSelectAnimation(attacker.GetNode(), 4);
        LogPrint("Player::OnDamage RadialSelectAnimation index=" + index);

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
            LogPrint("Player::OnAttackSuccess target is null");
            return;
        }

        combo ++;
        // LogPrint("OnAttackSuccess combo add to " + combo);

        if (target.health == 0)
        {
            killed ++;
            LogPrint("killed add to " + killed);
            gGame.OnCharacterKilled(this, target);
        }

        StatusChanged();
    }

    void OnCounterSuccess()
    {
        combo ++;
        LogPrint("OnCounterSuccess combo add to " + combo);
        StatusChanged();
    }

    void StatusChanged()
    {
        const int speed_up_combo = 10;
        float fov = BASE_FOV;

        if (combo < speed_up_combo)
        {
            if (debug_mode != 3)
                SetTimeScale(1.0f);
        }
        else
        {
            int max_comb = 80;
            int c = Min(combo, max_comb);
            float a = float(c)/float(max_comb);
            const float max_time_scale = 1.35f;
            float time_scale = Lerp(1.0f, max_time_scale, a);
            if (debug_mode != 3)
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
        EnemyManager@ em = GetEnemyMgr();
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
                    LogPrint(e.GetName() + " can not be countered");
                continue;
            }
            Vector3 posDiff = e.sceneNode.worldPosition - myPos;
            posDiff.y = 0;
            float distSQR = posDiff.lengthSquared;
            if (distSQR > MAX_COUNTER_DIST * MAX_COUNTER_DIST)
            {
                if (d_log)
                    LogPrint(e.GetName() + " counter distance too long" + distSQR);
                continue;
            }
            counterEnemies.Push(e);
        }

        LogPrint("PickCounterEnemy ret=" + counterEnemies.length);
        return counterEnemies.length;
    }

    Enemy@ CommonPickEnemy(float maxDiffAngle, float maxDiffDist, int flags, bool checkBlock)
    {
        LogPrint("\n CommonPickEnemy Start !!!!!!!!!!!! ");

        uint t = time.systemTime;
        Scene@ _scene = GetScene();
        EnemyManager@ em = GetEnemyMgr();
        if (em is null)
            return null;

        // Find the best enemy
        Vector3 myPos = sceneNode.worldPosition;
        float targetAngle = GetTargetAngle();
        g_int_cache.Clear();

        // LogPrint(gInput.GetDebugText());

        Enemy@ attackEnemy = null;
        for (uint i=0; i<em.enemyList.length; ++i)
        {
            Enemy@ e = em.enemyList[i];
            if (!e.HasFlag(flags))
            {
                //if (d_log)
                    LogPrint(e.GetName() + " no flag: " + flags);
                g_int_cache.Push(-1);
                continue;
            }

            Vector3 ePos = e.GetNode().worldPosition;
            Vector3 posDiff = ePos - myPos;
            posDiff.y = 0;
            int score = 0;
            float dist = posDiff.length;
            if (dist > maxDiffDist)
            {
                //if (d_log)
                    LogPrint(e.GetName() + " far way from player");
                g_int_cache.Push(-1);
                continue;
            }

            float enemyAngle = Atan2(posDiff.x, posDiff.z);
            float diffAngle = targetAngle - enemyAngle;
            diffAngle = AngleDiff(diffAngle);

            //if (d_log)
                LogPrint(e.GetName() + " enemyAngle="+enemyAngle+" targetAngle="+targetAngle+" diffAngle="+diffAngle);

            if (Abs(diffAngle) > maxDiffAngle / 2.0f)
            {
                // if (d_log)
                    LogPrint(e.GetName() + " diffAngle=" + diffAngle + " too large");
                g_int_cache.Push(-1);
                continue;
            }

            int threatScore = 0;
            if (dist < AI_NEAR_DIST)
            {
                CharacterState@ state = cast<CharacterState>(e.GetState());
                threatScore += int(state.GetThreatScore() * THREAT_SCORE);
            }
            int angleScore = int((180.0f - Abs(diffAngle))/180.0f * ANGLE_SCORE);
            int distScore = int((maxDiffDist - dist) / maxDiffDist * DIST_SCORE);
            score += distScore;
            score += angleScore;
            score += threatScore;

            g_int_cache.Push(score);

            /*
            if (debug_draw_flag > 0)
            {
                gDebugMgr.AddLine(myPos, ePos, TARGET_COLOR);
            }
            */

            //if (d_log)
                LogPrint("Enemy " + e.GetName() + " dist=" + dist + " diffAngle=" + diffAngle + " score=" + score);
        }

        int bestScore = 0;
        for (uint i=0; i<g_int_cache.length;++i)
        {
            int score = g_int_cache[i];
            if (score >= bestScore) {
                bestScore = score;
                @attackEnemy = em.enemyList[i];
            }
        }

        if (attackEnemy !is null && checkBlock)
        {
            LogPrint("CommonPicKEnemy-> attackEnemy is " + attackEnemy.GetName() + " flags=" + attackEnemy.flags);
            Node@ n = GetTargetSightBlockedNode(attackEnemy.GetNode().worldPosition);
            if (n !is null)
            {
                Enemy@ e = cast<Enemy>(n.scriptObject);
                if (e !is null && e !is attackEnemy && e.HasFlag(flags))
                {
                    LogPrint("Find a block enemy " + e.GetName() + " before " + attackEnemy.GetName());
                    @attackEnemy = e;
                }
            }
        }

        if (debug_draw_flag > 0)
        {
            gDebugMgr.AddDirection(myPos, targetAngle - maxDiffAngle/2.0f, maxDiffDist, YELLOW);
            gDebugMgr.AddDirection(myPos, targetAngle + maxDiffAngle/2.0f, maxDiffDist, YELLOW);
            if (attackEnemy !is null)
                gDebugMgr.AddLine(myPos, attackEnemy.GetNode().worldPosition, RED);
            gDebugMgr.AddDirection(myPos, targetAngle, maxDiffDist, BLUE);
        }

        LogPrint("CommonPicKEnemy() time-cost = " + (time.systemTime - t) + " ms \n");
        return attackEnemy;
    }

    String GetDebugText()
    {
        return Character::GetDebugText() +  " flags=" + flags + " combo=" + combo +  "killed=" + killed + " timeScale=" + timeScale +
              "\n tAngle=" + GetTargetAngle() +" grounded=" + mover.grounded + " inAirHeight=" + mover.inAirHeight +
              "scale=" + renderNode.GetChild(ScaleBoneName, true).scale.ToString() + "\n";
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

    bool ActionCheck(uint actionFlags)
    {
        // Print("HasFlag = " + HasFlag(actionFlags, 1 << kInputAttack));
        if (Global_HasFlag(actionFlags, 1 << kInputAttack) && gInput.IsInputActioned(kInputAttack))
            return Attack();

        if (Global_HasFlag(actionFlags, 1 << kInputDistract) && gInput.IsInputActioned(kInputDistract))
            return Distract();

        if (Global_HasFlag(actionFlags, 1 << kInputCounter) && gInput.IsInputActioned(kInputCounter))
            return Counter();

        if (Global_HasFlag(actionFlags, 1 << kInputEvade) && gInput.IsInputActioned(kInputEvade))
            return Evade();

        return false;
    }

    bool Attack()
    {
        LogPrint("Do--Attack--->");
        Enemy@ e = null;
        if (debug_mode == 1 || debug_mode == 3)
        {
            EnemyManager@ em = GetEnemyMgr();
            @e = em.enemyList[RandomInt(em.enemyList.length)];
        }
        else
        {
            @e = CommonPickEnemy(75, MAX_ATTACK_DIST, FLAGS_ATTACK, true);
        }

        SetTarget(e);
        if (e !is null && e.HasFlag(FLAGS_STUN))
            ChangeState("BeatDownHitState");
        else
            ChangeState("AttackState");
        return true;
    }

    bool Distract()
    {
        LogPrint("Do--Distract--->");
        Enemy@ e = CommonPickEnemy(45, MAX_ATTACK_DIST, FLAGS_ATTACK | FLAGS_STUN, true);
        if (e is null)
            return false;
        SetTarget(e);
        ChangeState("BeatDownHitState");
        return true;
    }

    bool CheckLastKill()
    {
        EnemyManager@ em = GetEnemyMgr();
        if (em is null)
            return false;

        int alive = em.GetNumOfEnemyAlive();
        LogPrint("CheckLastKill() alive=" + alive);
        int max_health = 50;
        if (test_enemy_num_override == 1)
            max_health = 20;
        if (alive == 1 && em.enemyList[0].health < max_health)
        {
            VariantMap data;
            data[NODE] = target.GetNode().id;
            data[NAME] = CHANGE_STATE;
            data[STATE] = StringHash("Death");
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

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        /*debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), AI_FAR_DIST, YELLOW, 32, false);
        debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), AI_NEAR_DIST, RED, 32, false);
        debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), MAX_ATTACK_DIST, BLUE, 32, false);
        debug.AddSkeleton(animModel.skeleton, WHITE, false);*/
    }
};
