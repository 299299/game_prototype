

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
    DebugRenderer@ debug = scene_.debugRenderer;
    if (drawDebug == 0)
        return;

    gDebugMgr.Update(debug, dt);

    if (drawDebug > 0)
    {
        // gCameraMgr.DebugDraw(debug);
        debug.AddNode(scene_, 1.0f, false);
        Player@ player = GetPlayer();
        if (player !is null)
            player.DebugDraw(debug);
    }
    if (drawDebug > 1)
    {
        EnemyManager@ em = GetEnemyMgr();
        if (em !is null)
            em.DebugDraw(debug);
    }

    if (drawDebug > 2)
    {
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

    if (key == KEY_ESCAPE)
    {
         if (!console.visible)
            engine.Exit();
        else
            console.visible = false;
    }
    else if (key == KEY_F1)
    {
        ++drawDebug;
        if (drawDebug > 3)
            drawDebug = 0;

        Text@ text = ui.root.GetChild("debug", true);
        if (text !is null)
            text.visible = drawDebug != 0;
    }
    else if (key == KEY_F2)
        debugHud.ToggleAll();
    else if (key == KEY_F3)
        console.Toggle();
    else if (key == KEY_F4)
    {
        Camera@ cam = GetCamera();
        if (cam !is null)
            cam.fillMode = (cam.fillMode == FILL_SOLID) ? FILL_WIREFRAME : FILL_SOLID;
    }
    else if (key == KEY_1)
        ShootSphere(scene_);
    else if (key == KEY_2)
        ShootBox(scene_);
    else if (key == KEY_3)
        CreateEnemy(scene_);
    else if (key == KEY_4)
    {
        CameraController@ cc = gCameraMgr.currentController;
        if (cc.nameHash == StringHash("Debug"))
        {
            ui.cursor.visible = false;
            gCameraMgr.SetCameraController("LookAt");
        }
        else
        {
            ui.cursor.visible = true;
            gCameraMgr.SetCameraController("Debug");
        }
    }
    else if (key == KEY_5)
    {
        VariantMap data;
        data[TARGET_FOV] = 60;
        SendEvent("CameraEvent", data);
    }
    else if (key == KEY_R)
        scene_.updateEnabled = !scene_.updateEnabled;
    else if (key == KEY_T)
    {
        if (scene_.timeScale >= 0.999f)
            scene_.timeScale = 0.1f;
        else
            scene_.timeScale = 1.0f;
    }
    else if (key == KEY_Q)
        engine.Exit();
    else if (key == KEY_J)
        TestAnimations_Group_2();
    else if (key == KEY_K)
        TestAnimations_Group_3();
    else if (key == KEY_L)
        TestAnimations_Group_4();
    else if (key == KEY_H)
        TestAnimations_Group_Beat();
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
        String testName = "BM_Climb/Dangle_To_Hang"; //"BM_Climb/Walk_Climb_Down_128"; //"BM_Climb/Stand_Climb_Up_256_Hang";
        Player@ player = GetPlayer();
        testAnimations.Push(testName);
        //testAnimations.Push("BM_Climb/Dangle_Right");
        // testAnimations.Push(GetAnimationName("BM_Railing/Railing_Run_Forward_Idle"));
        if (player !is null)
            player.TestAnimation(testAnimations);
    }
    else if (key == KEY_F)
    {
        scene_.timeScale = 1.0f;
        // SetWorldTimeScale(scene_, 1);
    }
    else if (key == KEY_O)
    {
        Node@ n = scene_.GetChild("thug2");
        if (n !is null)
        {
            n.vars[ANIMATION_INDEX] = RandomInt(4);
            Thug@ thug = cast<Thug>(n.scriptObject);
            thug.ChangeState("HitState");
        }
    }
    else if (key == KEY_I)
    {
        Player@ p = GetPlayer();
        if (p !is null)
            p.SetPhysicsType(1 - p.physicsType);
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

    if (em.enemyList.length < thugAnims.length)
        return;

    Motion@ m_player = gMotionMgr.FindMotion(playerAnim);
    if (m_player is null)
        return;

    LogPrint("TestAnimation_Group " + playerAnim);

    Array<String> testAnims;

    for (uint i=0; i<thugAnims.length; ++i)
    {
        Motion@ m = gMotionMgr.FindMotion(thugAnims[i]);
        Enemy@ e = em.enemyList[i];
        Vector4 t = GetTargetTransform(player.GetNode(), m, m_player);
        e.Transform(Vector3(t.x, e.GetNode().worldPosition.y, t.z), Quaternion(0, t.w, 0));
        e.TestAnimation(thugAnims[i]);
    }
    player.TestAnimation(playerAnim);
    player.SetSceneTimeScale(0.0f);
}

void TestAnimation_Group_s(const String&in playerAnim, const String& thugAnim, bool baseOnPlayer = false)
{
    Player@ player = GetPlayer();
    EnemyManager@ em = GetEnemyMgr();

    if (em.enemyList.empty)
        return;

    Motion@ m_player = gMotionMgr.FindMotion(playerAnim);
    Motion@ m = gMotionMgr.FindMotion(thugAnim);
    Enemy@ e = em.enemyList[0];

    if (baseOnPlayer)
    {
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

void TestAnimations_Group_2()
{
    Player@ player = GetPlayer();
    EnemyManager@ em = GetEnemyMgr();
    if (em.enemyList.empty)
        return;

    Enemy@ e = em.enemyList[0];
    CharacterCounterState@ s1 = cast<CharacterCounterState>(player.FindState("CounterState"));
    CharacterCounterState@ s2 = cast<CharacterCounterState>(e.FindState("CounterState"));
    Motion@ m1, m2;
    int i = RandomInt(4);
    if (i == 0)
    {
        int k = RandomInt(s1.frontArmMotions.length);
        @m1 = s1.frontArmMotions[k];
        @m2 = s2.frontArmMotions[k];
    }
    else if (i == 1)
    {
        int k = RandomInt(s1.frontLegMotions.length);
        @m1 = s1.frontLegMotions[k];
        @m2 = s2.frontLegMotions[k];
    }
    else if (i == 2)
    {
        int k = RandomInt(s1.backArmMotions.length);
        @m1 = s1.backArmMotions[k];
        @m2 = s2.backArmMotions[k];
    }
    else if (i == 3)
    {
        int k = RandomInt(s1.backLegMotions.length);
        @m1 = s1.backLegMotions[k];
        @m2 = s2.backLegMotions[k];
    }

    Vector4 t = GetTargetTransform(e.GetNode(), m1, m2);
    player.Transform(Vector3(t.x, player.GetNode().worldPosition.y, t.z), Quaternion(0, t.w, 0));

    e.TestAnimation(m2.name);
    player.TestAnimation(m1.name);
    player.SetSceneTimeScale(0.0f);

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

    Text@ text = ui.root.GetChild("debug", true);
    if (text !is null)
        text.text = debugText;
}

enum DebugDrawCommandType
{
    DEBUG_DRAW_LINE,
    DEBUG_DRAW_SPHERE,
    DEBUG_DRAW_NODE,
    DEBUG_DRAW_CROSS,
    DEBUG_DRAW_CIRCLE,
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
};

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
    }
}

class DebugDrawMgr
{
    Array<DebugDrawCommand@> commands;

    void Stop()
    {
        commands.Clear();
    }

    void AddCommand(DebugDrawCommand@ cmd)
    {
        commands.Push(cmd);
    }

    void Update(DebugRenderer@ debug, float dt)
    {
        uint processed_num = 0;
        uint cur = 0;
        uint num_time_out = 0;
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
    }

    void AddLine(const Vector3&in start, const Vector3&in end, const Color& c, float t)
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

    void AddSphere(const Vector3&in pos, float radius, const Color& c, float t)
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

    void AddCross(const Vector3&in pos, float size, const Color& c, float t)
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
};

DebugDrawMgr@ gDebugMgr = DebugDrawMgr();

