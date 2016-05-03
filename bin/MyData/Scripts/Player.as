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

    Array<Vector3>                    points;
    Array<PhysicsRaycastResult>       results;
    BoundingBox                       box;

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
        if (game_type != 0)
            return false;

        // Print("Player::Counter");
        PlayerCounterState@ state = cast<PlayerCounterState>(stateMachine.FindState("CounterState"));
        if (state is null)
            return false;

        state.counterEnemy = PickCounterEnemy();
        if (state.counterEnemy is null)
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

        if (CheckFalling())
            return;

        bool bCrouch = gInput.IsCrouchDown();
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = RadialSelectAnimation(4);
            sceneNode.vars[ANIMATION_INDEX] = index -1;
            Print("CommonStateFinishedOnGroud crouch=" + bCrouch + "To->Move|Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());
            if (index != 0)
            {
                if (bCrouch)
                {
                    if (ChangeState("CrouchTurnState"))
                        return;
                }
                else
                {
                    if (ChangeState(gInput.IsRunHolding() ? "StandToRunState" : "StandToWalkState"))
                        return;
                }
            }

            if (bCrouch)
                ChangeState("CrouchState");
            else
                ChangeState(gInput.IsRunHolding() ? "RunState" : "WalkState");
        }
        else
            ChangeState(bCrouch ? "CrouchState" : "StandState");
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
        // Print("OnAttackSuccess combo add to " + combo);

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
    Enemy@ PickCounterEnemy()
    {
        EnemyManager@ em = cast<EnemyManager>(GetScene().GetScriptObject("EnemyManager"));
        if (em is null)
            return null;

        Vector3 myPos = sceneNode.worldPosition;
        Enemy@ ret = null;
        float maxDistSQR = 999999;

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

            if (distSQR < maxDistSQR)
            {
                maxDistSQR = distSQR;
                @ret = e;
            }
        }

        return ret;
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

    bool ActionCheck(bool bAttack, bool bCounter, bool bEvade)
    {
        if (bAttack && gInput.IsAttackPressed())
            return Attack();

        if (bCounter && gInput.IsCounterPressed())
            return Counter();

        if (bEvade && gInput.IsEvadePressed())
            return Evade();

        return false;
    }

    bool Attack()
    {
        if (game_type != 0)
            return false;

        Print("Do--Attack--->");
        Enemy@ e = CommonPickEnemy(90, MAX_ATTACK_DIST, FLAGS_ATTACK, true, true);
        SetTarget(e);
        if (e !is null && e.HasFlag(FLAGS_STUN))
            ChangeState("BeatDownHitState");
        else
            ChangeState("AttackState");
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

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        // debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), COLLISION_RADIUS, YELLOW, 32, false);
        // sensor.DebugDraw(debug);
        debug.AddNode(sceneNode.GetChild(TranslateBoneName, true), 0.5f, false);
        if (dockLine !is null)
            debug.AddLine(dockLine.ray.origin, dockLine.end, YELLOW, false);

        if (points.length > 1)
        {
            for (uint i=0; i<points.length-1; ++i)
            {
                debug.AddLine(points[i], points[i+1], Color(0.5, 0.45, 0.75), false);
            }

            for (uint i=0; i<results.length; ++i)
            {
                if (results[i].body !is null)
                    debug.AddCross(results[i].position, 0.25f, Color(0.1f, 0.7f, 0.25f), false);
            }
        }

        debug.AddBoundingBox(box, Color(0.25, 0.75, 0.25), false);
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

    bool CheckFalling()
    {
        if (!sensor.grounded && sensor.inAirHeight > 1.5f && sensor.inAirFrames > 2 && applyGravity)
        {
            ChangeState("FallState");
            return true;
        }
        return false;
    }

    bool CheckDocking(float distance = 3)
    {
        Vector3 charPos = sceneNode.worldPosition;
        float charAngle = GetCharacterAngle();
        Line@ l = gLineWorld.GetNearestLine(charPos, charAngle, distance);

        if (l is null)
            return false;

        String stateToChange;

        if (l.type == LINE_COVER)
            stateToChange = "CoverState";
        else if (l.type == LINE_EDGE)
        {
            Vector3 proj = l.Project(charPos);
            float lineToMe = proj.y - charPos.y;
            // Print("lineToMe_Height=" + lineToMe);

            if (lineToMe < 0.1f)
            {
                // move down case
                float distSQR = (proj- charPos).lengthSquared;
                const float minDownDist = 1.5f;
                if (distSQR < minDownDist * minDownDist)
                {
                    int animIndex = 0;
                    ClimbDownRaycasts(l);

                    bool hitForward = results[0].body !is null;
                    bool hitDown = results[1].body !is null;
                    bool hitBack = results[2].body !is null;
                    Vector3 groundPos = results[1].position;
                    float lineToGround = l.end.y - groundPos.y;

                    Print("CheckDocking lineToGround=" + lineToGround + " hitForward=" + hitForward + " hitDown=" + hitDown + " hitBack=" + hitBack);

                    if (lineToGround > (HEIGHT_128 + HEIGHT_256) / 2)
                        stateToChange = "ClimbDownState";

                }
            }
            else if (lineToMe > HEIGHT_128 / 4)
            {
                // ClimbUpRaycasts(l);
                Line@ line = FindForwardUpDownLine(l);

                bool hitUp = results[0].body !is null;
                bool hitForward = results[1].body !is null;
                bool hitDown = results[2].body !is null;
                bool hitBack = results[3].body !is null;

                float lineToGround = l.end.y - results[2].position.y;
                bool isWallTooShort = lineToMe < (HEIGHT_128 + HEIGHT_256) / 2;

                // Print("CheckDocking hitUp=" + hitUp + " hitForward=" + hitForward + " hitDown=" + hitDown + " hitBack=" + hitBack + " lineToGround=" + lineToGround + " isWallTooShort=" + isWallTooShort);

                if (!hitUp)
                {
                    if (!hitForward)
                    {
                        if (hitDown && lineToGround < 0.25f)
                        {
                            if (!l.HasFlag(LINE_SHORT_WALL))
                                stateToChange = "ClimbUpState";
                        }
                        else
                        {
                            // TODO
                            if (isWallTooShort && l.HasFlag(LINE_THIN_WALL))
                            {
                                stateToChange = "ClimbOverState";
                                PlayerClimbOverState@ s = cast<PlayerClimbOverState>(FindState(stateToChange));
                                if (s !is null)
                                    @s.downLine = line;
                            }
                            else
                                stateToChange = "HangUpState"; // "ClimbOverState";
                        }
                    }
                    else
                    {
                        stateToChange = "HangUpState";
                    }
                }
            }
        }

        if (stateToChange.empty)
            return false;

        AssignDockLine(l);
        ChangeState(stateToChange);
        return true;
    }

    void ClimbUpRaycasts(Line@ line)
    {
        results.Resize(4);
        points.Resize(7);

        PhysicsWorld@ world = GetScene().physicsWorld;
        Vector3 charPos = GetNode().worldPosition;
        Vector3 proj = line.Project(charPos);
        float h_diff = proj.y - charPos.y;
        float above_height = 1.0f;
        Vector3 v1, v2, v3, v4, v5, v6, v7;
        Vector3 dir = proj - charPos;
        dir.y = 0;
        float fowardDist = dir.length + COLLISION_RADIUS * 1.5f;

        // up test
        v1 = charPos;
        Ray ray;
        ray.Define(v1, Vector3(0, 1, 0));
        float dist = h_diff + above_height;
        v2 = ray.origin + ray.direction * dist;
        results[0] = world.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE);

        // forward test
        ray.Define(v2, dir);
        dist = fowardDist;
        v3 = ray.origin + ray.direction * dist;
        results[1] = world.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE);

        // down test
        v4 = v3;
        v4.y = line.end.y;
        v4.y += HEIGHT_384;
        ray.Define(v4, Vector3(0, -1, 0));
        dist = HEIGHT_384 + HEIGHT_256;
        v5 = ray.origin + ray.direction * dist;
        results[2] = world.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE);

        // here comes the tricking part
        v6 = v5;
        v6.y = line.end.y;
        v6.y -= HEIGHT_128;
        dir *= -1;
        dir.Normalize();
        dist = fowardDist;
        v7 = v6 + dir * dist;
        results[3] = world.ConvexCast(sensor.verticalShape, v6, Quaternion(), v7, Quaternion(), COLLISION_LAYER_LANDSCAPE);

        points[0] = v1;
        points[1] = v2;
        points[2] = v3;
        points[3] = v4;
        points[4] = v5;
        points[5] = v6;
        points[6] = v7;
    }

    void ClimbDownRaycasts(Line@ line)
    {
        results.Resize(3);
        points.Resize(5);

        PhysicsWorld@ world = GetScene().physicsWorld;
        Vector3 charPos = GetNode().worldPosition;
        Vector3 proj = line.Project(charPos);
        float h_diff = proj.y - charPos.y;
        float above_height = 1.0f;
        Vector3 v1, v2, v3, v4, v5;
        Vector3 dir = proj - charPos;
        dir.y = 0;
        float fowardDist = dir.length + COLLISION_RADIUS * 1.5f;
        float dist;

        // forward test
        v1 = charPos + Vector3(0, above_height, 0);
        Ray ray;
        ray.Define(v1, dir);
        dist = fowardDist;
        v2 = ray.origin + ray.direction * dist;
        results[0] = world.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE);

        // down test
        ray.Define(v2, Vector3(0, -1, 0));
        dist = above_height + HEIGHT_256;
        v3 = ray.origin + ray.direction * dist;
        results[1] = world.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE);

        // here comes the tricking part
        v4 = v3;
        v4.y = line.end.y;
        v4.y -= HEIGHT_128;
        dir *= -1;
        dir.Normalize();
        dist = fowardDist;
        v5 = v4 + dir * dist;

        results[2] = world.ConvexCast(sensor.verticalShape, v4, Quaternion(), v5, Quaternion(), COLLISION_LAYER_LANDSCAPE);

        points[0] = v1;
        points[1] = v2;
        points[2] = v3;
        points[3] = v4;
        points[4] = v5;
    }

    void ClimbLeftOrRightRaycasts(Line@ line, bool bLeft)
    {
        results.Resize(3);
        points.Resize(4);

        PhysicsWorld@ world = GetScene().physicsWorld;

        Vector3 myPos = sceneNode.worldPosition;
        Vector3 proj = line.Project(myPos);
        Vector3 dir;
        dir = proj - myPos;

        Quaternion q(0, Atan2(dir.x, dir.z), 0);

        Vector3 towardDir = bLeft ? Vector3(-1, 0, 0) : Vector3(1, 0, 0);
        towardDir = q * towardDir;
        Vector3 linePt = line.GetLinePoint(towardDir);

        Vector3 v1, v2, v3, v4;

        v1 = myPos;
        v1.y = sceneNode.GetChild(L_HAND, true).worldPosition.y;

        Vector3 v = linePt - v1;
        v.y = 0;
        dir = towardDir;
        dir.y = 0;

        float len = v.length + COLLISION_RADIUS;

        Ray ray;
        ray.Define(v1, dir);
        v2 = ray.origin + ray.direction * len;
        // results[0] = world.RaycastSingle(ray, len, COLLISION_LAYER_LANDSCAPE);
        results[0] = world.ConvexCast(sensor.verticalShape, v1, Quaternion(), v2, Quaternion(), COLLISION_LAYER_LANDSCAPE);

        dir = q * Vector3(0, 0, 1);
        len = COLLISION_RADIUS * 2;
        ray.Define(v2, dir);
        v3 = v2 + ray.direction * len;
        results[1] = world.ConvexCast(sensor.verticalShape, v2, Quaternion(), v3, Quaternion(), COLLISION_LAYER_LANDSCAPE);

        dir = bLeft ? Vector3(1, 0, 0) : Vector3(-1, 0, 0);
        dir = q * dir;
        ray.Define(v3, dir);
        v4 = v3 + ray.direction * len;
        results[2] = world.ConvexCast(sensor.verticalShape, v3, Quaternion(), v4, Quaternion(), COLLISION_LAYER_LANDSCAPE);

        points[0] = v1;
        points[1] = v2;
        points[2] = v3;
        points[3] = v4;
    }

    Line@ FindCrossLine(bool left, int& out convexIndex)
    {
        Line@ oldLine = dockLine;
        ClimbLeftOrRightRaycasts(oldLine, left);

        bool hit1 = results[0].body !is null;
        bool hit2 = results[1].body !is null;
        bool hit3 = results[2].body !is null;

        Print("FindCrossLine hit1=" + hit1 + " hit2=" + hit2 + " hit3=" + hit3);
        convexIndex = 1;
        Array<Line@>@ lines = gLineWorld.cacheLines;
        lines.Clear();

        if (hit1)
        {
            convexIndex = 2;
            gLineWorld.CollectLinesByNode(results[0].body.node, lines);
        }
        else if (!hit2 && hit3)
        {
            convexIndex = 1;
            gLineWorld.CollectLinesByNode(results[2].body.node, lines);
        }
        else
            return null;

        if (lines.empty)
            return null;

        Line@ bestLine = null;
        float maxHeightDiff = 1.0f;
        float maxDistSQR = 999999;
        Vector3 comparePot = (convexIndex == 1) ? points[1] : points[2];

        for (uint i=0; i<lines.length; ++i)
        {
            Line@ l = lines[i];
            if (!l.TestAngleDiff(oldLine, 90))
                continue;
            if (Abs(l.end.y - oldLine.end.y) > maxHeightDiff)
                continue;
            Vector3 proj = l.Project(comparePot);
            proj.y = comparePot.y;
            float distSQR = (proj - comparePot).lengthSquared;
            if (distSQR < maxDistSQR)
            {
                @bestLine = l;
                maxDistSQR = distSQR;
            }
        }
        return bestLine;
    }

    Line@ FindParalleLine(bool left, float& outDistErrorSQR)
    {
        Line @oldLine = dockLine;
        Node@ n = GetNode();
        Vector3 myPos = n.worldPosition;

        Vector3 towardDir = left ? Vector3(-1, 0, 0) : Vector3(1, 0, 0);
        towardDir = n.worldRotation * towardDir;
        Vector3 linePt = oldLine.GetLinePoint(towardDir);

        towardDir = linePt - oldLine.Project(myPos);

        float myAngle = GetCharacterAngle();
        float angle = Atan2(towardDir.x, towardDir.z);

        float w = 6.0f;
        float h = 2.0f;
        float l = 2.0f;
        Vector3 halfSize(w/2, h/2, l/2);
        Vector3 min = halfSize * -1;
        Vector3 max = halfSize;
        box.Define(min, max);

        Quaternion q(0, angle + 90, 0);
        Vector3 center = towardDir.Normalized() * halfSize.x + linePt;
        Matrix3x4 m;
        m.SetTranslation(center);
        m.SetRotation(q.rotationMatrix);
        box.Transform(m);

        Array<Line@>@ lines = gLineWorld.cacheLines;
        lines.Clear();

        int num = gLineWorld.CollectLinesInBox(GetScene(), box, oldLine.nodeId, lines);
        if (num == 0)
            return null;

        Print("FindParalleLine lines.num=" + num);

        Line@ bestLine = null;
        float maxHeightDiff = 1.0f;
        float maxDistSQR = 5.0f * 5.0f;
        Vector3 comparePot = myPos;

        for (uint i=0; i<lines.length; ++i)
        {
            Line@ line = lines[i];
            if (!line.TestAngleDiff(oldLine, 0) && !line.TestAngleDiff(oldLine, 180))
                continue;
            if (Abs(line.end.y - oldLine.end.y) > maxHeightDiff)
                continue;
            if (!line.IsAngleValid(myAngle))
                continue;

            Vector3 v = line.GetNearPoint(comparePot);
            v -= comparePot;
            v.y = 0;
            float distSQR = v.lengthSquared;
            if (distSQR < maxDistSQR)
            {
                @bestLine = line;
                maxDistSQR = distSQR;
            }
        }

        outDistErrorSQR = maxDistSQR;
        return bestLine;
    }

    Line@ FindDownLine(Array<Line@>@ lines, Line@ oldLine)
    {
        Vector3 comparePot = oldLine.end;
        float maxDistSQR = COLLISION_RADIUS*COLLISION_RADIUS;
        Line@ bestLine;

        if (lines.empty)
            return null;

        // Print("FindDownLine lines.num=" + lines.length);

        for (uint i=0; i<lines.length; ++i)
        {
            Line@ l = lines[i];
            if (l is oldLine)
                continue;

            if (!l.TestAngleDiff(oldLine, 0) && !l.TestAngleDiff(oldLine, 180))
                continue;

            float heightDiff = oldLine.end.y - l.end.y;
            float diffTo128 = Abs(heightDiff - HEIGHT_128);
            Print("heightDiff= " + heightDiff + " diffTo128 = " + diffTo128);

            if (diffTo128 > HEIGHT_128/2)
                continue;

            Vector3 tmpV = l.Project(comparePot);
            tmpV.y = comparePot.y;
            float distSQR = (tmpV - comparePot).lengthSquared;
            Print("distSQR=" + distSQR);

            if (distSQR < maxDistSQR)
            {
                @bestLine = l;
                maxDistSQR = distSQR;
            }
        }

        return bestLine;
    }

    Line@ FindDownLine(Line@ oldLine)
    {
        ClimbDownRaycasts(oldLine);
        if (results[2].body is null)
            return null;
        Array<Line@>@ lines = gLineWorld.cacheLines;
        lines.Clear();
        Vector3 myPos = sceneNode.worldPosition;
        gLineWorld.CollectLinesByNode(results[2].body.node, lines);
        return FindDownLine(lines, oldLine);
    }

    Line@ FindForwardUpDownLine(Line@ oldLine)
    {
        ClimbUpRaycasts(oldLine);
        if (results[3].body is null)
            return null;
        Array<Line@>@ lines = gLineWorld.cacheLines;
        lines.Clear();
        Vector3 myPos = sceneNode.worldPosition;
        gLineWorld.CollectLinesByNode(results[3].body.node, lines);
        return FindDownLine(lines, oldLine);
    }

    void ClearPoints()
    {
        points.Clear();
        results.Clear();
    }
};
