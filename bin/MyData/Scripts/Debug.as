/*


             ==============       ==============
            |               |____|               |
            \               /    \               /
              =============        ==============
                             ●   ●

DEBUG Features

*/


int test_beat_index = 1;
bool base_on_player = false;
int test_counter_index = 0;
int test_double_counter_index = 0;
int test_triple_counter_index = 0;
int test_attack_id = 0;
int test_environment_counter_index = 0;

void ShootBox(Scene@ _scene)
{
    Node@ cameraNode = gCameraMgr.GetCameraNode();
    Node@ boxNode = _scene.CreateChild("SmallBox");
    boxNode.position = cameraNode.position;
    boxNode.rotation = cameraNode.rotation;
    boxNode.SetScale(1.0);
    StaticModel@ boxObject = boxNode.CreateComponent("StaticModel");
    boxObject.model = cache.GetResource("Model", "Models/Box.mdl");
    boxObject.material = cache.GetResource("Material", "Materials/StoneSmall.xml");
    boxObject.castShadows = true;
    RigidBody@ body = boxNode.CreateComponent("RigidBody");
    body.mass = 0.25f;
    body.friction = 0.75f;
    body.collisionLayer = COLLISION_LAYER_PROP;
    CollisionShape@ shape = boxNode.CreateComponent("CollisionShape");
    shape.SetBox(Vector3(1.0f, 1.0f, 1.0f));
    body.linearVelocity = cameraNode.rotation * Vector3(0.0f, 0.25f, 1.0f) * 10.0f;
}

void ShootSphere(Scene@ _scene)
{
    Node@ cameraNode = gCameraMgr.GetCameraNode();
    Node@ sphereNode = _scene.CreateChild("Sphere");
    sphereNode.position = cameraNode.position;
    sphereNode.rotation = cameraNode.rotation;
    sphereNode.SetScale(1.0);
    StaticModel@ boxObject = sphereNode.CreateComponent("StaticModel");
    boxObject.model = cache.GetResource("Model", "Models/Sphere.mdl");
    boxObject.material = cache.GetResource("Material", "Materials/StoneSmall.xml");
    boxObject.castShadows = true;
    RigidBody@ body = sphereNode.CreateComponent("RigidBody");
    body.mass = 1.0f;
    body.rollingFriction = 0.15f;
    body.collisionLayer = COLLISION_LAYER_PROP;
    CollisionShape@ shape = sphereNode.CreateComponent("CollisionShape");
    shape.SetSphere(1.0f);
    body.linearVelocity = cameraNode.rotation * Vector3(0.0f, 0.25f, 1.0f) * 10.0f;
}

void DrawDebug(float dt)
{
    Scene@ scene_ = script.defaultScene;
    if (scene_ is null)
        return;

    EnemyManager@ em = GetEnemyMgr();
    Player@ p = GetPlayer();

    if (!scene_.updateEnabled)
    {
        if (em !is null)
        {
            for (uint i=0; i<em.enemyList.length; ++i)
            {
                HeadIndicator@ h = cast<HeadIndicator>(em.enemyList[i].GetNode().GetScriptObject("HeadIndicator"));
                if (h !is null)
                    h.Update(0);
            }
        }

        if (p !is null)
        {
            HeadIndicator@ h = cast<HeadIndicator>(p.GetNode().GetScriptObject("HeadIndicator"));
            if (h !is null)
                h.Update(0);
        }
    }

    // DrawDebugText();

    DebugRenderer@ debug = scene_.debugRenderer;
    if (drawDebug == 0)
        return;

    gDebugMgr.Update(debug, dt);

    if (drawDebug > 0)
    {
        debug.AddNode(scene_, 1.0f, false);
        if (p !is null)
            p.DebugDraw(debug);
    }
    if (drawDebug > 1)
    {
        if (em !is null)
            em.DebugDraw(debug);
    }

    if (drawDebug > 2)
    {
        // gCameraMgr.DebugDraw(debug);

        DynamicNavigationMesh@ dnm = scene_.GetComponent("DynamicNavigationMesh");
        if (dnm !is null)
            dnm.DrawDebugGeometry(true);

        CrowdManager@ cm = scene_.GetComponent("CrowdManager");
        if (cm !is null)
            cm.DrawDebugGeometry(true);

        PhysicsWorld@ pw = scene_.physicsWorld;
        if (pw !is null)
            pw.DrawDebugGeometry(true);
    }
}

void HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
    Scene@ scene_ = script.defaultScene;
    int key = eventData["Key"].GetInt();

    if (key == KEY_ESCAPE || key == KEY_Q)
         engine.Exit();
    else if (key == KEY_BACKQUOTE)
    {
        test_mode ++;
        test_mode = test_mode % 2;
        OnTestModeChanged();
    }
    else if (key == KEY_1)
    {
        ++drawDebug;
        if (drawDebug > 3)
            drawDebug = 0;
    }
    else if (key == KEY_2)
        debugHud.ToggleAll();
    else if (key == KEY_3)
    {
        Camera@ cam = GetCamera();
        if (cam !is null)
            cam.fillMode = (cam.fillMode == FILL_SOLID) ? FILL_WIREFRAME : FILL_SOLID;
    }
    else if (key == KEY_4)
        ShootSphere(scene_);
    else if (key == KEY_5)
        ShootBox(scene_);
    else if (key == KEY_6)
        CreateEnemy(scene_);
    else if (key == KEY_7)
    {
        CameraController@ cc = gCameraMgr.currentController;
        if (cc.nameHash == StringHash("Debug"))
        {
            ui.cursor.visible = false;
            gCameraMgr.SetCameraController(GAME_CAMEAR_NAME);
        }
        else
        {
            ui.cursor.visible = true;
            gCameraMgr.SetCameraController("Debug");
        }
    }
    else if (key == KEY_8)
    {
        VariantMap data;
        data[TARGET_FOV] = 60;
        SendEvent("CameraEvent", data);
    }
    else if (key == KEY_9)
    {
        CameraShake();
    }
    else if (key == KEY_0)
    {
        TestAnimations_Group_2("Counter_Arm_Front_09");
    }
    else if (key == KEY_MINUS)
    {
        TestAttack();
    }
    else if (key == KEY_EQUALS)
    {
        RandomEnemyPositions();
    }
    else if (key == KEY_R)
    {
        if (scene_ !is null)
            scene_.updateEnabled = !scene_.updateEnabled;
    }
    else if (key == KEY_T)
    {
        if (scene_ !is null)
        {
            if (scene_.timeScale >= 0.999f)
                scene_.timeScale = 0.1f;
            else
                scene_.timeScale = 1.0f;
        }
    }
    else if (key == KEY_J)
        TestAnimations_Group_2();
    else if (key == KEY_K)
        TestAnimations_Group_3();
    else if (key == KEY_L)
        TestAnimations_Group_4();
    else if (key == KEY_H)
        TestAnimations_Group_Beat();
    else if (key == KEY_V)
        TestAnimations_Group_5();
    else if (key == KEY_E)
    {
        Array<String> testAnimations;
        //String testName = "TG_Getup/GetUp_Back";
        //String testName = "TG_BM_Counter/Counter_Leg_Front_01";
        //String testName = "TG_HitReaction/Push_Reaction";
        //String testName = "BM_TG_Beatdown/Beatdown_Strike_End_01";
        //String testName = "TG_HitReaction/HitReaction_Back_NoTurn";
        //String testName = "BM_Attack/Attack_Far_Back_04";
        //String testName = "TG_BM_Counter/Double_Counter_2ThugsB_01";
        //String testName = "BM_Attack/Attack_Far_Back_03";
        //String testName = "BM_Climb/Stand_Climb_Up_256_Hang";
        //String testName = GetAnimationName("BM_Railing/Railing_Idle");
        //String testName = ("BM_Railing/Railing_Climb_Down_Forward");
        //String testName = "BM_Climb/Stand_Climb_Up_256_Hang";
        String testName = "BM_Attack/Attack_Far_Forward_02"; //"BM_Climb/Walk_Climb_Down_128"; //"BM_Climb/Stand_Climb_Up_256_Hang";
        Player@ player = GetPlayer();
        testAnimations.Push(testName);
        //testAnimations.Push("BM_Climb/Dangle_Right");
        // testAnimations.Push(GetAnimationName("BM_Railing/Railing_Run_Forward_Idle"));
        if (player !is null)
            player.TestAnimation(testAnimations);
    }
    else if (key == KEY_F)
    {
        Player@ p = GetPlayer();
        if (p !is null)
        {
            if (p.HasFlag(FLAGS_INVINCIBLE))
                p.RemoveFlag(FLAGS_INVINCIBLE);
            else
                p.AddFlag(FLAGS_INVINCIBLE);
        }
    }
    else if (key == KEY_O)
    {
        if (scene_ !is null)
        {
            Node@ n = scene_.GetChild("thug2");
            if (n !is null)
            {
                n.vars[ANIMATION_INDEX] = RandomInt(4);
                Thug@ thug = cast<Thug>(n.scriptObject);
                thug.ChangeState("HitState");
            }
        }
    }
    else if (key == KEY_M)
    {
        Player@ p = GetPlayer();
        if (p !is null)
        {
            LogPrint("------------------------------------------------------------");
            for (uint i=0; i<p.stateMachine.states.length; ++i)
            {
                State@ s = p.stateMachine.states[i];
                LogPrint("name=" + s.name + " nameHash=" + s.nameHash.ToString());
            }
            LogPrint("------------------------------------------------------------");
        }
    }
    else if (key == KEY_C)
    {
        TestCounter(6);
    }
    else if (key == KEY_U)
    {
        Player@ p = GetPlayer();
        if (p.timeScale > 1.0f)
            p.timeScale = 1.0f;
        else
            p.timeScale = 1.25f;
    }
}

void HandleMouseButtonDown(StringHash eventType, VariantMap& eventData)
{
    int button = eventData["Button"].GetInt();
    if (button == MOUSEB_RIGHT)
    {
        IntVector2 pos = ui.cursorPosition;
        // Check the cursor is visible and there is no UI element in front of the cursor
        if (ui.GetElementAt(pos, true) !is null)
            return;

        CreateDrag(float(pos.x), float(pos.y));
        SubscribeToEvent("MouseMove", "HandleMouseMove");
        SubscribeToEvent("MouseButtonUp", "HandleMouseButtonUp");
    }
    else if(button == MOUSEB_LEFT)
    {
        if (test_mode > 0)
        {
            script.defaultScene.updateEnabled = true;
            script.defaultScene.timeScale = 1.0f;
        }
    }
}

void HandleMouseButtonUp(StringHash eventType, VariantMap& eventData)
{
    int button = eventData["Button"].GetInt();
    if (button == MOUSEB_RIGHT)
    {
        DestroyDrag();
        UnsubscribeFromEvent("MouseMove");
        UnsubscribeFromEvent("MouseButtonUp");
    }
}

void HandleMouseMove(StringHash eventType, VariantMap& eventData)
{
    int x = input.mousePosition.x;
    int y = input.mousePosition.y;
    MoveDrag(float(x), float(y));
}

void TestAnimation_Group(const String&in playerAnim, Array<String>@ thugAnims)
{
    Player@ player = GetPlayer();
    EnemyManager@ em = GetEnemyMgr();

    if (player is null || em is null)
        return;

    if (em.enemyList.length < thugAnims.length)
        return;

    Motion@ m_player = gMotionMgr.FindMotion(playerAnim);
    if (m_player is null)
        return;

    LogPrint("TestAnimation_Group " + playerAnim);

    Array<String> testAnims;
    int index = RandomInt(em.enemyList.length);

    for (uint i=0; i<thugAnims.length; ++i)
    {
        Motion@ m = gMotionMgr.FindMotion(thugAnims[i]);
        Enemy@ e = em.enemyList[(index + i) % em.enemyList.length];
        Ragdoll@ rg = cast<Ragdoll>(e.GetNode().GetScriptObject("Ragdoll"));
        rg.ChangeState(RAGDOLL_NONE);

        Vector4 t = GetTargetTransform(player.GetNode(), m, m_player);
        e.Transform(Vector3(t.x, e.GetNode().worldPosition.y, t.z), Quaternion(0, t.w, 0));
        e.TestAnimation(thugAnims[i]);
    }
    player.TestAnimation(playerAnim);
    // player.SetSceneTimeScale(0.0f);
}

void TestAnimation_Group_s(const String&in playerAnim, const String& thugAnim, bool baseOnPlayer = false)
{
    Player@ player = GetPlayer();
    EnemyManager@ em = GetEnemyMgr();

    if (em.enemyList.empty)
        return;

    Motion@ m_player = gMotionMgr.FindMotion(playerAnim);
    Motion@ m = gMotionMgr.FindMotion(thugAnim);
    Enemy@ e = em.enemyList[RandomInt(em.enemyList.length)];

    if (baseOnPlayer)
    {
        Ragdoll@ rg = cast<Ragdoll>(e.GetNode().GetScriptObject("Ragdoll"));
        rg.ChangeState(RAGDOLL_NONE);

        Vector4 t = GetTargetTransform(player.GetNode(), m, m_player);
        e.Transform(Vector3(t.x, e.GetNode().worldPosition.y, t.z), Quaternion(0, t.w, 0));
    }
    else
    {
        Vector4 t = GetTargetTransform(e.GetNode(), m_player, m);
        player.Transform(Vector3(t.x, player.GetNode().worldPosition.y, t.z), Quaternion(0, t.w, 0));
    }

    e.TestAnimation(thugAnim);
    player.TestAnimation(playerAnim);
}

void TestAnimations_Group_Beat()
{
    String playerAnim = "BM_Attack/Beatdown_Test_0" + test_beat_index;
    String thugAnim = "TG_BM_Beatdown/Beatdown_HitReaction_0" + test_beat_index;
    test_beat_index ++;
    if (test_beat_index > 6)
    {
        test_beat_index = 1;
        base_on_player = !base_on_player;
    }
    TestAnimation_Group_s(playerAnim, thugAnim, base_on_player);
}

void TestAnimations_Group_2(const String& counterName = "")
{
    Player@ player = GetPlayer();
    EnemyManager@ em = GetEnemyMgr();
    if (player is null or em is null)
        return;

    if (em.enemyList.empty)
        return;

    Enemy@ e = em.enemyList[RandomInt(em.enemyList.length)];
    CharacterCounterState@ s1 = cast<CharacterCounterState>(player.FindState("CounterState"));
    CharacterCounterState@ s2 = cast<CharacterCounterState>(e.FindState("CounterState"));
    Motion@ m1, m2;
    if (counterName.empty)
    {
        int l1 = int(s1.frontArmMotions.length);
        int l2 = int(s1.frontLegMotions.length);
        int l3 = int(s1.backArmMotions.length);
        int l4 = int(s1.backLegMotions.length);

        if (test_counter_index >= l1 + l2 + l3)
        {
            int index = test_counter_index - (l1 + l2 + l3);
            @m1 = s1.backLegMotions[index];
            @m2 = s2.backLegMotions[index];
        }
        else if (test_counter_index >= l1 + l2)
        {
            int index = test_counter_index - (l1 + l2);
            @m1 = s1.backArmMotions[index];
            @m2 = s2.backArmMotions[index];
        }
        else if (test_counter_index >= l1)
        {
            int index = test_counter_index - l1;
            @m1 = s1.frontLegMotions[index];
            @m2 = s2.frontLegMotions[index];
        }
        else
        {
            @m1 = s1.frontArmMotions[test_counter_index];
            @m2 = s2.frontArmMotions[test_counter_index];
        }

        ++ test_counter_index;
        if (test_counter_index >= l1 + l2 + l3 + l4)
            test_counter_index = 0;
    }
    else
    {
        @m1 = gMotionMgr.FindMotion("BM_TG_Counter/" + counterName);
        @m2 = gMotionMgr.FindMotion("TG_BM_Counter/" + counterName);
    }

    Vector4 t = GetTargetTransform(e.GetNode(), m1, m2);
    player.Transform(Vector3(t.x, player.GetNode().worldPosition.y, t.z), Quaternion(0, t.w, 0));

    e.TestAnimation(m2.name);
    player.TestAnimation(m1.name);

    LogPrint("TestAnimations_Group_2 -> " + m1.name);
}

void TestAnimations_Group_3()
{
    Array<String> tests =
    {
        "Double_Counter_2ThugsA",
        "Double_Counter_2ThugsB",
        "Double_Counter_2ThugsC",
        "Double_Counter_2ThugsD",
        "Double_Counter_2ThugsE",
        "Double_Counter_2ThugsF",
        "Double_Counter_2ThugsG",
        "Double_Counter_2ThugsH"
    };
    String preFix = "BM";
    String test = tests[test_double_counter_index];
    test_double_counter_index ++;
    if (test_double_counter_index >= int(tests.length))
        test_double_counter_index = 0;
    String playerAnim = preFix + "_TG_Counter/" + test;
    Array<String> thugAnims;
    String thugAnim = "TG_" + preFix + "_Counter/" + test;
    thugAnims.Push(thugAnim + "_01");
    thugAnims.Push(thugAnim + "_02");
    TestAnimation_Group(playerAnim, thugAnims);
}

void TestAnimations_Group_4()
{
    String preFix = "BM";
    Array<String> tests =
    {
        "Double_Counter_3ThugsA",
        "Double_Counter_3ThugsB",
        "Double_Counter_3ThugsC"
    };
    String test = tests[test_triple_counter_index];
    test_triple_counter_index ++;
    if (test_triple_counter_index >= int(tests.length))
        test_triple_counter_index = 0;
    String playerAnim = preFix + "_TG_Counter/" + test;
    Array<String> thugAnims;
    String thugAnim = "TG_" + preFix + "_Counter/" + test;
    thugAnims.Push(thugAnim + "_01");
    thugAnims.Push(thugAnim + "_02");
    thugAnims.Push(thugAnim + "_03");
    TestAnimation_Group(playerAnim, thugAnims);
}

void TestAnimations_Group_5()
{
    String preFix = "BM";
    Array<String> tests =
    {
        /*"Environment_Counter_128_Back_02",
        "Environment_Counter_128_Front_01",
        "Environment_Counter_128_Left_01",
        "Environment_Counter_128_Right_01",*/
        "Environment_Counter_Wall_Back_02",
        "Environment_Counter_Wall_Front_01",
        "Environment_Counter_Wall_Front_02",
        "Environment_Counter_Wall_Left_02",
        "Environment_Counter_Wall_Right_02",
        "Environment_Counter_Wall_Right"
    };
    String test = tests[test_environment_counter_index];
    test_environment_counter_index ++;
    if (test_environment_counter_index >= int(tests.length))
        test_environment_counter_index = 0;
    String playerAnim = preFix + "_TG_Counter/" + test;
    Array<String> thugAnims;
    String thugAnim = "TG_" + preFix + "_Counter/" + test;
    TestAnimation_Group_s(playerAnim, thugAnim);
}

void TestCounter(float range = MAX_COUNTER_DIST)
{
    Player@ player = GetPlayer();
    EnemyManager@ em = GetEnemyMgr();
    if (player is null or em is null)
        return;

    if (em.enemyList.empty)
        return;

    PlayerCounterState@ state = cast<PlayerCounterState>(player.stateMachine.FindState("CounterState"));
    if (state is null)
        return;

    state.counterEnemies.Clear();
    for (uint i=0; i<em.enemyList.length; ++i)
    {
        float d = em.enemyList[i].GetTargetDistance();
        if (d > MAX_COUNTER_DIST)
            continue;
        state.counterEnemies.Push(em.enemyList[i]);
        if (state.counterEnemies.length >= 3)
            break;
    }

    if (state.counterEnemies.empty)
        return;

    player.ChangeState("CounterState");
}

void TestAttack()
{
    Player@ player = GetPlayer();
    if (player is null)
        return;

    player.GetScene().updateEnabled = true;
    Motion@ am;
    PlayerAttackState@ s = cast<PlayerAttackState>(player.stateMachine.FindState("AttackState"));
    int l1 = s.forwardAttacks.length;
    int l2 = s.leftAttacks.length;
    int l3 = s.rightAttacks.length;
    int l4 = s.backAttacks.length;
    if (test_attack_id >= l1 + l2 + l3)
    {
        int id = test_attack_id - (l1 + l2 + l3);
        @am = s.backAttacks[id];
    }
    else if (test_attack_id >= l1 + l2)
    {
        int id = test_attack_id - (l1 + l2);
        @am = s.rightAttacks[id];
    }
    else if (test_attack_id >= l1)
    {
        int id = test_attack_id - l1;
        @am = s.leftAttacks[id];
    }
    else
    {
        @am = s.forwardAttacks[test_attack_id];
    }

    player.TestAnimation(am.name);
    test_attack_id ++;
    if (test_attack_id >=  l1 + l2 + l3 + l4)
        test_attack_id = 0;
}

void RandomEnemyPositions()
{
    EnemyManager@ em = GetEnemyMgr();
    if (em is null)
        return;

    Player@ p = GetPlayer();
    if (p is null)
        return;

    CrowdManager@ cm = script.defaultScene.GetComponent("CrowdManager");
    if (cm is null)
        return;

    Vector3 c = p.GetNode().worldPosition;
    for (uint i=0; i<em.enemyList.length; ++i)
    {
        Enemy@ e = em.enemyList[i];
        e.MoveTo(cm.GetRandomPointInCircle(c, 5.0f, e.agent.queryFilterType), 0.0f);
    }
}

/***********************************************

   ##### DEBUG DRAW STUFF

***********************************************/
void DebugDrawDirection(DebugRenderer@ debug, const Vector3& start, float angle, const Color&in color, float radius = 1.0)
{
    Vector3 end = start + Vector3(Sin(angle) * radius, 0, Cos(angle) * radius);
    debug.AddLine(start, end, color, false);
}

void AddDebugMark(DebugRenderer@ debug, const Vector3&in position, const Color&in color, float size=0.15f)
{
    Sphere sp;
    sp.Define(position, size);
    debug.AddSphere(sp, color, false);
}


void DrawDebugText()
{
    Text@ text = ui.root.GetChild("debug", true);
    if (text is null)
        return;

    if (drawDebug == 0)
    {
        text.visible = false;
        return;
    }

    text.visible = true;
    String seperator = "-------------------------------------------------------------------------------------------------------\n";
    String debugText = seperator;
    debugText += gGame.GetDebugText();
    debugText += seperator;
    debugText += gCameraMgr.GetDebugText();
    debugText += gInput.GetDebugText();
    debugText += seperator;
    Player@ player = GetPlayer();
    if (player !is null)
        debugText += player.GetDebugText();
    debugText += seperator;
    if (drawDebug > 1)
    {
        EnemyManager@ em = GetEnemyMgr();
        if (em !is null && !em.enemyList.empty)
        {
            debugText += em.enemyList[0].GetDebugText();
            debugText += seperator;
        }
    }
    text.text = debugText;
}

enum DebugDrawCommandType
{
    DEBUG_DRAW_LINE,
    DEBUG_DRAW_SPHERE,
    DEBUG_DRAW_NODE,
    DEBUG_DRAW_CROSS,
    DEBUG_DRAW_CIRCLE,
    DEBUG_DRAW_TEXT,
    DEBUG_DRAW_HINT,
};


class DebugDrawCommand
{
    uint    id;

    int     type;
    float   time;
    Color   color;
    bool    depth;

    Vector3 v1;
    Vector3 v2;
    Vector3 v3;
    uint    data1;
    float   data2;
    String  data3;
};

const int MAX_DEBUG_TEXTS = 10;
class DebugDrawMgr
{
    Array<DebugDrawCommand@> commands;
    Array<Text@>             texts;
    Text@                    hintText;
    uint                     numTexts;
    String                   hintString;

    void Start()
    {
        hintText = ui.root.CreateChild("Text", "hint_debug_text");
        hintText.SetFont(cache.GetResource("Font", DEBUG_FONT), 20);
        hintText.SetPosition(5, 100);
        hintText.color = WHITE;
        hintText.priority = -99999;
        hintText.visible = false;

        for (int i=0; i<MAX_DEBUG_TEXTS; ++i)
        {
            Text@ text = ui.root.CreateChild("Text", "DebugText_" + i);
            text.SetFont(cache.GetResource("Font", DEBUG_FONT), 15);
            text.visible = false;
        }
    }

    void Stop()
    {
        commands.Clear();

        if (hintText !is null)
        {
            hintText.Remove();
            @hintText = null;
        }
    }

    void AddCommand(DebugDrawCommand@ cmd)
    {
        commands.Push(cmd);
    }

    void Update(DebugRenderer@ debug, float dt)
    {
        Scene@ s = script.defaultScene;
        if (!s.updateEnabled)
            dt = 0;
        dt *= s.timeScale;

        hintText.visible = false;
        hintString.Clear();
        for (uint i=0; i<texts.length; ++i)
        {
            texts[i].visible = false;
        }

        uint processed_num = 0;
        uint cur = 0;
        uint num_time_out = 0;
        numTexts = 0;

        while (processed_num != commands.length)
        {
            DebugDrawCommand@ cmd = commands[cur];
            ProcessDebugDrawCommand(debug, cmd);
            ++ processed_num;
            if (cmd.time >= 0)
            {
                cmd.time -= dt;
                if (cmd.time > 0)
                {
                    cur ++;
                }
                else
                {
                    // swap to the last element
                    DebugDrawCommand@ last = commands[commands.length - 1 - num_time_out];
                    commands[cur] = last;
                    ++ num_time_out;
                }
            }
        }

        if (num_time_out > 0)
            commands.Resize(commands.length - num_time_out);

        if (!hintString.empty)
        {
            hintText.text = hintString;
            hintText.visible = true;
        }
    }

    void ProcessDebugDrawCommand(DebugRenderer@ debug, const DebugDrawCommand&in cmd)
    {
        switch (cmd.type)
        {
        case DEBUG_DRAW_LINE:
            debug.AddLine(cmd.v1, cmd.v2, cmd.color, cmd.depth);
            break;
        case DEBUG_DRAW_SPHERE:
            {
                Sphere sp;
                sp.Define(cmd.v1, cmd.data2);
                debug.AddSphere(sp, cmd.color, cmd.depth);
            }
            break;
        case DEBUG_DRAW_NODE:
            {
                Node@ node = script.defaultScene.GetNode(cmd.data1);
                if (node !is null)
                {
                    debug.AddNode(node, cmd.data2, cmd.depth);
                }
            }
            break;
        case DEBUG_DRAW_CROSS:
            debug.AddCross(cmd.v1, cmd.data2, cmd.color, cmd.depth);
            break;
        case DEBUG_DRAW_CIRCLE:
            debug.AddCircle(cmd.v1, cmd.v2, cmd.data2, cmd.color, 32, cmd.depth);
            break;
        case DEBUG_DRAW_HINT:
            {
                hintString += cmd.data3;
                hintString += "\n";
                break;
            }
        case DEBUG_DRAW_TEXT:
            {
                if (numTexts < texts.length)
                {
                    Text@ text = texts[numTexts];
                    ++numTexts;
                    text.visible = true;
                    text.text = cmd.data3;
                    text.color = cmd.color;
                    Vector2 pos_2d = GetCamera().WorldToScreenPoint(cmd.v1);
                    text.SetPosition(pos_2d.x, pos_2d.y);
                }

                break;
            }
        }
    }

    void AddLine(const Vector3&in start, const Vector3&in end, const Color& c, float t = 1.0f)
    {
        DebugDrawCommand@ cmd = DebugDrawCommand();
        cmd.type = DEBUG_DRAW_LINE;
        cmd.v1 = start;
        cmd.v2 = end;
        cmd.depth = false;
        cmd.color = c;
        cmd.time = t;
        AddCommand(cmd);
    }

    void AddSphere(const Vector3&in pos, float radius, const Color& c, float t = 1.0f)
    {
        DebugDrawCommand@ cmd = DebugDrawCommand();
        cmd.type = DEBUG_DRAW_SPHERE;
        cmd.v1 = pos;
        cmd.data2 = radius;
        cmd.depth = false;
        cmd.color = c;
        cmd.time = t;
        AddCommand(cmd);
    }

    void AddCross(const Vector3&in pos, float size, const Color& c, float t = 1.0f)
    {
        DebugDrawCommand@ cmd = DebugDrawCommand();
        cmd.type = DEBUG_DRAW_CROSS;
        cmd.v1 = pos;
        cmd.data2 = size;
        cmd.depth = false;
        cmd.color = c;
        cmd.time = t;
        AddCommand(cmd);
    }

    void AddDirection(const Vector3& start, float angle, float radius, const Color&in color, float t = 1.0f)
    {
        Vector3 end = start + Vector3(Sin(angle) * radius, 0, Cos(angle) * radius);
        AddLine(start, end, color, t);
    }

    void AddHintText(const String&in text, float t = 1.0f)
    {
        DebugDrawCommand@ cmd = DebugDrawCommand();
        cmd.type = DEBUG_DRAW_HINT;
        cmd.data3 = text;
        cmd.time = t;
        AddCommand(cmd);
    }

    void AddText(const String&in text, const Color& in color, const Vector3&in position, float t = 1.0f)
    {
        DebugDrawCommand@ cmd = DebugDrawCommand();
        cmd.type = DEBUG_DRAW_TEXT;
        cmd.color = color;
        cmd.data3 = text;
        cmd.v1 = position;
        cmd.time = t;
        AddCommand(cmd);
    }
};

DebugDrawMgr@ gDebugMgr = DebugDrawMgr();


// ======================================================================
//
//  Debug UI Slider Changed
//
// ======================================================================
const float sliderRange = 20.0f;
const float cameraDistMin = 3.0f;
const float cameraDistMax = 40.0f;
const float cameraPitchMin = -60.0f;
const float cameraPitchMax = 90.0f;
const String TAG_DEBUG = "TAG_DEBUG";

Slider@ CreateSlider(int x, int y, int xSize, int ySize, const String& text)
{
    Font@ font = cache.GetResource("Font", DEBUG_FONT);
    // Create text and slider below it
    Text@ sliderText = ui.root.CreateChild("Text");
    sliderText.SetPosition(x, y);
    sliderText.SetFont(font, 20);
    sliderText.text = text;
    sliderText.name = text + "_Text";
    sliderText.AddTag(TAG_DEBUG);
    sliderText.visible = false;
    Slider@ slider = ui.root.CreateChild("Slider");
    slider.SetStyleAuto();
    slider.SetPosition(x, y + ySize);
    slider.SetSize(xSize, ySize);
    slider.name = text;
    slider.range = sliderRange;
    slider.AddTag(TAG_DEBUG);
    slider.visible = false;
    return slider;
}

Button@ CreateButton(int x, int y, int xSize, int ySize, const String& text)
{
    Font@ font = cache.GetResource("Font", DEBUG_FONT);
    Button@ button = ui.root.CreateChild("Button");
    button.SetStyleAuto();
    button.SetPosition(x, y);
    button.SetSize(xSize, ySize);
    button.name = text;
    Text@ buttonText = button.CreateChild("Text");
    buttonText.SetFont(font, 20);
    buttonText.text = text;
    return button;
}

void CreateDebugUI()
{
    int gw = graphics.width;
    int gh = graphics.height;
    int buttonWidth = gw / 8;
    int buttonHeight = gw / 40;
    int y = 30;
    Button@ b = CreateButton(gw - buttonWidth - 30, y, buttonWidth, buttonHeight, "Debug");
    int x = gw / 2;
    int w = gw / 4;
    int h = gw / 40;
    int gap = 10;
    ThirdPersonCameraController@ tpc = cast<ThirdPersonCameraController>(gCameraMgr.FindCameraController(StringHash("ThirdPerson")));
    if (tpc !is null)
    {
        Slider@ s = CreateSlider(x, y, w, h, "Camera_Distance");
        y += (h*2 + gap);
        s.value = (tpc.targetCameraDistance - cameraDistMin) / (cameraDistMax - cameraDistMin) * sliderRange;

        s = CreateSlider(x, y, w, h, "Camera_Pitch");
        y += (h*2 + gap);
        s.value = (tpc.pitch - cameraPitchMin) / (cameraPitchMax - cameraPitchMin) * sliderRange;
    }

}

void HandleSliderChanged(StringHash eventType, VariantMap& eventData)
{
    UIElement@ e = eventData["Element"].GetPtr();
    float newValue = eventData["Value"].GetFloat();
    Print(e.name + " newValue=" + newValue);
    newValue /= sliderRange;
    ThirdPersonCameraController@ tpc = cast<ThirdPersonCameraController>(gCameraMgr.FindCameraController(StringHash("ThirdPerson")));
    if (tpc !is null)
    {
        if (e.name == "Camera_Distance")
        {
            tpc.targetCameraDistance = Lerp(cameraDistMin, cameraDistMax, newValue);
            Text@ text = ui.root.GetChild(e.name + "_Text", true);
            if (text !is null)
                text.text = "Camera Distance: " + tpc.targetCameraDistance;
        }
        else if (e.name == "Camera_Pitch")
        {
            tpc.pitch = Lerp(cameraPitchMin, cameraPitchMax, newValue);
            Text@ text = ui.root.GetChild(e.name + "_Text", true);
            if (text !is null)
                text.text = "Camera Pitch: " + tpc.pitch;
        }
    }
}

void HandleButtonPressed(StringHash eventType, VariantMap& eventData)
{
    UIElement@ e = eventData["Element"].GetPtr();
    if (e.name == "Debug")
    {
        debug_mode = (debug_mode == 0) ? 1 : 0;
        if (debug_mode == 1)
        {
            freeze_ai = 1;
            drawDebug = 1;
        }
        else
        {
            freeze_ai = 0;
            drawDebug = 0;
        }

        Array<UIElement@>@ elements = ui.root.GetChildrenWithTag(TAG_DEBUG);
        for (uint i = 0; i < elements.length; ++i)
            elements[i].visible = (debug_mode == 1);
    }
}

void OnTestModeChanged()
{
    Player@ p = GetPlayer();
    p.SetTimeScale(test_mode == 3 ? 1.5f : 1.0f);
}
