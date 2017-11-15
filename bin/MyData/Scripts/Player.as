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

class Player : Character
{
    int             combo;
    int             killed;
    uint            lastAttackId = M_MAX_UNSIGNED;
    bool            applyGravity = true;

    void ObjectStart()
    {
        Character::ObjectStart();

        side = 1;
        @sensor = PhysicsSensor(sceneNode);

        Node@ tailNode = sceneNode.CreateChild("TailNode");
        ParticleEmitter@ emitter = tailNode.CreateComponent("ParticleEmitter");
        emitter.effect = cache.GetResource("ParticleEffect", "Particle/Tail.xml");
        tailNode.enabled = false;

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
            ChangeState("RunState");
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
                LogPrint("Enemy " + e.GetName() + " can not be redirected.");
                continue;
            }

            float enemyDir = e.GetCharacterAngle();
            float totalDir = Abs(AngleDiff(myDir - enemyDir));
            float dirDiff = Abs(totalDir - 180);
            LogPrint("Evade-- myDir=" + myDir + " enemyDir=" + enemyDir + " totalDir=" + totalDir + " dirDiff=" + dirDiff);
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
            if (!HasFlag(e.flags, flags))
            {
                if (d_log)
                    LogPrint(e.GetName() + " no flag: " + flags);
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
                    LogPrint(e.GetName() + " far way from player");
                em.scoreCache.Push(-1);
                continue;
            }

            float enemyAngle = Atan2(posDiff.x, posDiff.z);
            float diffAngle = targetAngle - enemyAngle;
            diffAngle = AngleDiff(diffAngle);

            if (Abs(diffAngle) > maxDiffAngle)
            {
                if (d_log)
                    LogPrint(e.GetName() + " diffAngle=" + diffAngle + " too large");
                em.scoreCache.Push(-1);
                continue;
            }

            if (d_log)
                LogPrint("enemyAngle="+enemyAngle+" targetAngle="+targetAngle+" diffAngle="+diffAngle);

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
                LogPrint("Enemy " + e.sceneNode.name + " dist=" + dist + " diffAngle=" + diffAngle + " score=" + score);
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
            LogPrint("CommonPicKEnemy-> attackEnemy is " + attackEnemy.GetName());
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
                if (e !is null && e !is attackEnemy && HasFlag(e.flags, FLAGS_ATTACK))
                {
                    LogPrint("Find a block enemy " + e.GetName() + " before " + attackEnemy.GetName());
                    @attackEnemy = e;
                }
            }
        }

        LogPrint("CommonPicKEnemy() time-cost = " + (time.systemTime - t) + " ms");
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
            if (!HasFlag(e.flags, flags))
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

        LogPrint("CommonCollectEnemies() len=" + enemies.length + " time-cost = " + (time.systemTime - t) + " ms");
    }

    String GetDebugText()
    {
        return Character::GetDebugText() +  "health=" + health + " flags=" + flags +
              " combo=" + combo + " killed=" + killed + " timeScale=" + timeScale + " tAngle=" + GetTargetAngle() +
              " grounded=" + sensor.grounded + " inAirHeight=" + sensor.inAirHeight + "\n";
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
        if (HasFlag(actionFlags, kInputAttack) && gInput.IsInputActioned(kInputAttack))
            return Attack();

        if (HasFlag(actionFlags, kInputDistract) && gInput.IsInputActioned(kInputDistract))
            return Distract();

        if (HasFlag(actionFlags, kInputCounter) && gInput.IsInputActioned(kInputCounter))
            return Counter();

        if (HasFlag(actionFlags, kInputEvade) && gInput.IsInputActioned(kInputEvade))
            return Evade();

        return false;
    }

    bool Attack()
    {
        LogPrint("Do--Attack--->");
        Enemy@ e = CommonPickEnemy(90, MAX_ATTACK_DIST, FLAGS_ATTACK, true, true);
        SetTarget(e);
        if (e !is null && HasFlag(e.flags, FLAGS_STUN))
            ChangeState("BeatDownHitState");
        else
            ChangeState("AttackState");
        return true;
    }

    bool Distract()
    {
        LogPrint("Do--Distract--->");
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
        LogPrint("CheckLastKill() alive=" + alive);
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
            target.flags = RemoveFlag(target.flags, FLAGS_NO_MOVE);
        Character::SetTarget(t);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        // debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), COLLISION_RADIUS, YELLOW, 32, false);
        // sensor.DebugDraw(debug);
        debug.AddNode(sceneNode.GetChild(TranslateBoneName, true), 0.5f, false);
    }

    void Update(float dt)
    {
        sensor.Update(dt);
        Character::Update(dt);
    }

    void SetVelocity(const Vector3&in vel)
    {
        if (!sensor.grounded && applyGravity)
            Character::SetVelocity(vel + Vector3(0, -9.8f, 0));
        else
            Character::SetVelocity(vel);
    }
};
