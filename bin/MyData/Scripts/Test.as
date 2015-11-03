// ------------------------------------------------
#include "Scripts/Game.as"
#include "Scripts/AssetProcess.as"
#include "Scripts/Motion.as"
#include "Scripts/Input.as"
#include "Scripts/FSM.as"
#include "Scripts/Ragdoll.as"
#include "Scripts/Camera.as"
// ------------------------------------------------
#include "Scripts/GameObject.as"
#include "Scripts/Character.as"
#include "Scripts/Enemy.as"
#include "Scripts/Thug.as"
#include "Scripts/Player.as"

Scene@ scene_;
bool drawDebug = true;

float dragDistance = 0.0f;
Node@ draggingNode;

const String GAME_SCRIPT = "Scripts/Test.as";
Node@ characterNode;
Node@ thugNode;

Player@ player;
bool slowMotion = false;
bool pauseGame = false;
int globalState = 0;
float globalTime = 0;

void Start()
{
    cache.autoReloadResources = true;

    if (!test_ragdoll)
        gMotionMgr.Start();

    if (!engine.headless)
    {
        SetWindowTitleAndIcon();
        CreateConsoleAndDebugHud();
    }

    CreateScene();

    if (!engine.headless) {
        CreateUI();
        SetupViewport();
    }

    SubscribeToEvents();
    SetRandomSeed(time.systemTime);
}

void Stop()
{
    Print("Test Stop");
    gMotionMgr.Stop();
    ui.Clear();
    scene_.Remove();
    scene_ = null;
}

void CreateScene()
{
    scene_ = Scene();

    scene_.LoadXML(cache.GetFile("Scenes/1.xml"));

    Node@ cameraNode = scene_.CreateChild("Camera");
    Camera@ cam = cameraNode.CreateComponent("Camera");
    // cam.fillMode = FILL_WIREFRAME;

    characterNode = scene_.GetChild("bruce", true);

    Vector3 v_pos = characterNode.worldPosition;
    cameraNode.position = Vector3(v_pos.x, 10.0f, -10);

    if (!test_ragdoll)
    {
        @player = cast<Player>(characterNode.CreateScriptObject(GAME_SCRIPT, "Player"));
    }

    thugNode = scene_.GetChild("thug", true);
    if (!test_ragdoll)
    {
        Thug @thug = cast<Thug>(thugNode.CreateScriptObject(GAME_SCRIPT, "Thug"));
        @thug.target = player;
    }

    Node@ thugNode2 = scene_.GetChild("thug2", true);
    if (!test_ragdoll)
    {
        Thug @thug = cast<Thug>(thugNode2.CreateScriptObject(GAME_SCRIPT, "Thug"));
        @thug.target = player;
    }

    characterNode.CreateScriptObject(GAME_SCRIPT, "Ragdoll");
    thugNode.CreateScriptObject(GAME_SCRIPT, "Ragdoll");

    cameraNode.LookAt(Vector3(v_pos.x, 4, 0));

    gCameraMgr.Start(cameraNode);
    gCameraMgr.SetCameraController("Debug");

    if (test_ragdoll)
    {
        VariantMap data;
        data[DATA] = RAGDOLL_START;
        characterNode.children[0].SendEvent("AnimationTrigger", data);
    }

    //Animation@ anim = cache.GetResource("Animation", GetAnimationName("TG_Getup/GetUp_Back"));
    //AnimationTrack@ track = anim.tracks["Bip"];
    //DumpSkeletonNames(characterNode);
}

void SetWindowTitleAndIcon()
{
    Image@ icon = cache.GetResource("Image", "Textures/UrhoIcon.png");
    graphics.windowIcon = icon;
    graphics.windowTitle = "Test";
}

void CreateConsoleAndDebugHud()
{
    // Get default style
    XMLFile@ xmlFile = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    if (xmlFile is null)
        return;

    // Create console
    Console@ console = engine.CreateConsole();
    console.defaultStyle = xmlFile;
    console.background.opacity = 0.8f;

    // Create debug HUD
    DebugHud@ debugHud = engine.CreateDebugHud();
    debugHud.defaultStyle = xmlFile;
}

void CreateUI()
{
    // Create a Cursor UI element because we want to be able to hide and show it at will. When hidden, the mouse cursor will
    // control the camera, and when visible, it will point the raycast target
    //XMLFile@ style = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    //Cursor@ cursor = Cursor();
    //cursor.SetStyleAuto(style);
    //ui.cursor = cursor;
    // Set starting position of the cursor at the rendering window center
    //cursor.SetPosition(graphics.width / 2, graphics.height / 2);
    // input.SetMouseVisible(true);

    Text@ instructionText = ui.root.CreateChild("Text", "debug");
    instructionText.SetFont(cache.GetResource("Font", "Fonts/UbuntuMono-R.ttf"), 12);
    instructionText.horizontalAlignment = HA_LEFT;
    instructionText.verticalAlignment = VA_TOP;
    instructionText.SetPosition(0, 0);
    instructionText.color = Color(0, 1, 0);
}

void SetupViewport()
{
    Viewport@ viewport = Viewport(scene_, gCameraMgr.GetCamera());
    renderer.viewports[0] = viewport;
    graphics.windowTitle = "Test";
}

void ShootBox(Scene@ _scene)
{
    Node@ cameraNode = gCameraMgr.GetCameraNode();
    Node@ boxNode = _scene.CreateChild("SmallBox");
    boxNode.position = cameraNode.position;
    boxNode.rotation = cameraNode.rotation;
    boxNode.SetScale(1.0);
    StaticModel@ boxObject = boxNode.CreateComponent("StaticModel");
    boxObject.model = cache.GetResource("Model", "Models/Box.mdl");
    boxObject.material = cache.GetResource("Material", "Materials/StoneEnvMapSmall.xml");
    boxObject.castShadows = true;
    RigidBody@ body = boxNode.CreateComponent("RigidBody");
    body.mass = 0.25f;
    body.friction = 0.75f;
    body.collisionLayer = (1 << COLLISION_LAYER_PROP);
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
    body.collisionLayer = (1 << COLLISION_LAYER_PROP);
    CollisionShape@ shape = sphereNode.CreateComponent("CollisionShape");
    shape.SetSphere(1.0f);
    body.linearVelocity = cameraNode.rotation * Vector3(0.0f, 0.25f, 1.0f) * 10.0f;
}

void SubscribeToEvents()
{
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
    SubscribeToEvent("KeyDown", "HandleKeyDown");
    SubscribeToEvent("MouseMove", "HandleMouseMove");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();

    gInput.Update(timeStep);
    gCameraMgr.Update(timeStep);

    if (input.keyPress[KEY_1])
        ShootSphere(scene_);

    if (input.keyPress[KEY_2])
        ShootBox(scene_);

    if (input.mouseButtonPress[MOUSEB_RIGHT])
    {
        IntVector2 pos = ui.cursorPosition;
        // Check the cursor is visible and there is no UI element in front of the cursor
        if (ui.GetElementAt(pos, true) !is null)
            return;

        Camera@ camera = gCameraMgr.GetCamera();
        Ray cameraRay = camera.GetScreenRay(float(pos.x) / graphics.width, float(pos.y) / graphics.height);
        float rayDistance = 100.0f;
        PhysicsRaycastResult result = scene_.physicsWorld.RaycastSingle(cameraRay, rayDistance, COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_PROP);
        if (result.body !is null)
        {
            Print("RaycastSingle Hit " + result.body.node.name + " distance=" + result.distance);
            draggingNode = scene_.CreateChild("DraggingNode");
            draggingNode.scale = Vector3(0.1f, 0.1f, 0.1f);
            StaticModel@ sphereObject = draggingNode.CreateComponent("StaticModel");
            sphereObject.model = cache.GetResource("Model", "Models/Sphere.mdl");
            RigidBody@ body = draggingNode.CreateComponent("RigidBody");
            CollisionShape@ shape = draggingNode.CreateComponent("CollisionShape");
            shape.SetSphere(1);
            Constraint@ constraint = draggingNode.CreateComponent("Constraint");
            constraint.constraintType = CONSTRAINT_POINT;
            constraint.disableCollision = true;
            constraint.otherBody = result.body;
            dragDistance = result.distance;
            draggingNode.worldPosition = result.position;
        }
    }
    else {
        if (!input.mouseButtonDown[MOUSEB_RIGHT]) {
            if (draggingNode !is null) {
                draggingNode.Remove();
                draggingNode = null;
            }
        }
    }

    if (input.keyPress['T'])
    {
        slowMotion = !slowMotion;
        scene_.timeScale = slowMotion ? 0.1f : 1.0f;
        //SetWorldTimeScale(scene_, slowMotion ? 0.25f : 1.0f);
    }

    if (input.keyPress['R'])
    {
        pauseGame = !pauseGame;
        float speed = slowMotion ? 0.1f : 1.0f;
        scene_.timeScale = pauseGame ? 0 : speed;
    }

    if (test_ragdoll)
    {
        if (input.keyPress['E'])
        {
            Node@ renderNode = characterNode.children[0];

            VariantMap data;
            data[DATA] = RAGDOLL_STOP;
            renderNode.SendEvent("AnimationTrigger", data);

            AnimationController@ ctl = renderNode.GetComponent("AnimationController");
            Animation@ anim = Animation();
            String name = "Test_Pose";
            anim.name = name;
            anim.animationName = name;
            FillAnimationWithCurrentPose(anim, renderNode);
            cache.AddManualResource(anim);

            AnimatedModel@ model = renderNode.GetComponent("AnimatedModel");
            AnimationState@ state = model.AddAnimationState(anim);
            state.weight = 1.0f;
            ctl.PlayExclusive(anim.name, LAYER_MOVE, false, 0.0f);

            int ragdoll_direction = characterNode.vars[GETUP_INDEX].GetInt();
            String name1 = ragdoll_direction == 0 ? "TG_Getup/GetUp_Back" : "TG_Getup/GetUp_Front";
            PlayAnimation(ctl, GetAnimationName(name1), LAYER_MOVE, false, 0.25f, 0.0, 0.0);
        }
        else if (input.keyPress['F'])
        {
            Node@ renderNode = characterNode.children[0];
            AnimationController@ ctl = renderNode.GetComponent("AnimationController");
            int ragdoll_direction = characterNode.vars[GETUP_INDEX].GetInt();
            String name1 = ragdoll_direction == 0 ? "TG_Getup/GetUp_Back" : "TG_Getup/GetUp_Front";
            ctl.SetSpeed(GetAnimationName(name1), 1.0);
        }
    }
    else
    {
        if (input.keyPress['E'])
        {
            //String testName = "TG_Getup/GetUp_Back";
            //String testName = "TG_BM_Counter/Counter_Leg_Front_01";
            //String testName = "TG_HitReaction/Push_Reaction";
            //String testName = "TG_BM_Counter/Counter_Arm_Front_01";
            String testName = "TG_HitReaction/HitReaction_Right";
            //String testName = "BM_Attack/Attack_Far_Back_04";
            player.TestAnimation(testName);
        }
        else if (input.keyPress['F'])
        {
            scene_.timeScale = 1.0f;
            SetWorldTimeScale(scene_, 1);
        }
    }

    String debugText = "camera position=" + gCameraMgr.GetCameraNode().worldPosition.ToString() + "\n";
    debugText += gInput.GetDebugText();
    if (player !is null)
        debugText += player.GetDebugText();

    if (engine.headless)
    {
        globalTime += timeStep;

         if (globalTime > 0.5)
        {
            if (player !is null && globalState != 1)
            {
                globalState = 1;
                String testName = "BM_Attack/Attack_Close_Forward_02";
                player.TestAnimation(testName);
            }
        }

        if (globalTime > 5)
        {
            if (globalState == 999)
            {
                @player = null;
                characterNode.RemoveAllComponents();
                thugNode.RemoveAllComponents();
                @gEnemyMgr = null;
                gMotionMgr.Stop();
                globalState = 2;
            }
        }

        if (globalTime > 3.0)
        {
            // engine.Exit();
        }
    }
    else
    {
        Text@ text = ui.root.GetChild("debug", true);
        text.text = debugText;
    }
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    DebugRenderer@ debug = scene_.debugRenderer;
    gGame.PostRenderUpdate();

    if (!drawDebug)
        return;

    debug.AddNode(scene_, 1.0f, false);
    if (player !is null)
        player.DebugDraw(debug);

    gEnemyMgr.DebugDraw(debug);

    scene_.physicsWorld.DrawDebugGeometry(false);

    //AnimatedModel@ model = characterNode.children[0].GetComponent("AnimatedModel");
    //Skeleton@ skel = model.skeleton;
    //debug.AddSkeleton(skel, Color(1, 0, 0), false);

    //debug.AddNode(characterNode, 0.25, false);
    //debug.AddNode(characterNode.GetChild("Bip01_$AssimpFbx$_Translation", true), 0.25, false);
    //debug.AddNode(characterNode.GetChild("Bip01_$AssimpFbx$_Rotation", true), 0.25, false);
    // debug.AddNode(characterNode.GetChild("Bip01_Pelvis", true), 0.25, false);

    //debug.AddNode(characterNode.GetChild("Bip01_$AssimpFbx$_Scaling", true), 0.25, false);
    //debug.AddNode(characterNode.GetChild("Bip01_Spine1", true), 0.25, false);

    //Vector3 v1 = characterNode.GetChild("Bip01_L_Foot", true).worldPosition;
    //Vector3 v2 = characterNode.GetChild("Bip01_R_Foot", true).worldPosition;
    //debug.AddCross((v1+v2)*0.5f, 0.5f, Color(1,0,0), false);
    //Vector3 v3 = characterNode.GetChild("Bip01_Head", true).worldPosition;
    //debug.AddCross(v3, 0.5f, Color(1,0,0), false);
    //debug.AddLine((v1+v2)*0.5f, v3, Color(1,0,0), false);
}

void HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
    int key = eventData["Key"].GetInt();
    gGame.OnKeyDown(key);

    // Close console (if open) or exit when ESC is pressed
    if (key == KEY_ESC)
    {
        if (!console.visible)
            engine.Exit();
        else
            console.visible = false;
    }
    else if (key == KEY_F1)
        drawDebug = !drawDebug;
    else if (key == KEY_F2)
        debugHud.ToggleAll();
    else if (key == KEY_F3)
        console.Toggle();
}

void HandleMouseMove(StringHash eventType, VariantMap& eventData)
{
    int x = input.mousePosition.x;
    int y = input.mousePosition.y;
    gGame.OnMouseMove(x, y);
    // dragging physics object
    if (draggingNode !is null) {
        Camera@ camera = gCameraMgr.GetCamera();
        Vector3 v(float(x) / graphics.width, float(y) / graphics.height, dragDistance);
        draggingNode.worldPosition = camera.ScreenToWorldPoint(v);
    }
}

void DumpSkeletonNames(Node@ n)
{
    AnimatedModel@ model = n.GetComponent("AnimatedModel");
    if (model is null)
        model = n.children[0].GetComponent("AnimatedModel");
    if (model is null)
        return;

    Skeleton@ skeleton = model.skeleton;
    for (uint i=0; i<skeleton.numBones; ++i)
    {
        Print(skeleton.bones[i].name);
    }
}