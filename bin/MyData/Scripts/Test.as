#include "Scripts/Utilities/Sample.as"
// ------------------------------------------------
#include "Scripts/AssetProcess.as"
#include "Scripts/Motion.as"
#include "Scripts/Input.as"
#include "Scripts/FSM.as"
// ------------------------------------------------
#include "Scripts/GameObject.as"
#include "Scripts/Character.as"
#include "Scripts/Enemy.as"
#include "Scripts/Thug.as"
#include "Scripts/Player.as"


const String GAME_SCRIPT = "Scripts/Test.as";
Node@ characterNode;
Node@ thugNode;

Player@ player;
Thug@ thug;
bool slowMotion = false;
bool pauseGame = false;
int globalState = 0;
float globalTime = 0;

void Start()
{
    cache.autoReloadResources = true;
    gMotionMgr.Start();

    if (!engine.headless)
        SampleStart();

    CreateScene();

    if (!engine.headless) {
        CreateInstructions();
        SetupViewport();
    }

    SubscribeToEvents();
}

void Stop()
{
    gMotionMgr.Stop();
}

void CreateScene()
{
    scene_ = Scene();

    scene_.LoadXML(cache.GetFile("Scenes/1.xml"));

    cameraNode = scene_.CreateChild("Camera");
    Camera@ cam = cameraNode.CreateComponent("Camera");
    // cam.fillMode = FILL_WIREFRAME;

    // Set an initial position for the camera scene node above the plane
    cameraNode.position = Vector3(0.0f, 10.0f, -10.0f);
    pitch = 45;

    characterNode = scene_.GetChild("bruce", true);
    characterNode.Translate(Vector3(5, 0, 0));
    // characterNode.GetChild("RootNode", true).rotation = Quaternion(0, -180, 0);

    @gEnemyMgr = EnemyManager();
    @player = cast<Player>(characterNode.CreateScriptObject(GAME_SCRIPT, "Player"));
    if (player is null) {
        Print("player is null!!");
        engine.Exit();
        return;
    }

    thugNode = scene_.GetChild("bruce2", true);
    @thug = cast<Thug>(thugNode.CreateScriptObject(GAME_SCRIPT, "Thug"));
    if (thug is null) {
        Print("thug is null!!");
        engine.Exit();
        return;
    }

    Vector3 pos = cameraNode.worldPosition;
    Vector3 playerPos = characterNode.worldPosition;
    pos.x = playerPos.x;
    pos.z = playerPos.z;
    pos.z -= 5;
    cameraNode.worldPosition = pos;
}

void CreateInstructions()
{
    Text@ instructionText = ui.root.CreateChild("Text", "instruction");
    instructionText.SetFont(cache.GetResource("Font", "Fonts/UbuntuMono-R.ttf"), 12);
    instructionText.horizontalAlignment = HA_LEFT;
    instructionText.verticalAlignment = VA_TOP;
    instructionText.SetPosition(0, 0);
    instructionText.color = Color(0, 1, 0);
    SetLogoVisible(false);
}

void SetupViewport()
{
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;

    //if (GetPlatform() == "Linux")
    //    graphics.windowPosition = IntVector2(0, 800);
}

void MoveCamera(float timeStep)
{
    if (ui.focusElement !is null)
        return;

    const float MOVE_SPEED = 20.0f;
    const float MOUSE_SENSITIVITY = 0.1f;

    IntVector2 mouseMove = input.mouseMove;
    yaw += MOUSE_SENSITIVITY * mouseMove.x;
    pitch += MOUSE_SENSITIVITY * mouseMove.y;
    pitch = Clamp(pitch, -90.0f, 90.0f);

    cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);

    if (input.keyDown['W'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, 1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['S'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, -1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['A'])
        cameraNode.Translate(Vector3(-1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['D'])
        cameraNode.Translate(Vector3(1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
}

void SubscribeToEvents()
{
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("SceneUpdate", "HandleSceneUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();

    MoveCamera(timeStep);

    gInput.Update(timeStep);

    if (input.keyPress['T'])
    {
        slowMotion = !slowMotion;
        scene_.timeScale = slowMotion ? 0.05f : 1.0f;
    }

    if (input.keyPress['R'])
    {
        pauseGame = !pauseGame;
        float speed = slowMotion ? 0.1f : 1.0f;
        scene_.timeScale = pauseGame ? 0 : speed;
    }

    if (input.keyPress['E'])
    {
        String testName = "BM_Attack/Attack_Close_Forward_03"; //"TG_BM_Counter/Counter_Arm_Front_01";
        player.TestAnimation(testName);
    }

    if (input.keyPress['F']) {
        scene_.timeScale = 1.0f;
    }

    String debugText = gInput.GetDebugText();
    if (player !is null)
    {
        debugText += player.GetDebugText();

        /*
        Vector3 fwd = Vector3(0, 0, 1);
        Vector3 camDir = cameraNode.worldRotation * fwd;
        float cameraAngle = Atan2(camDir.x, camDir.z);
        Vector3 characterDir = characterNode.worldRotation * fwd;
        float characterAngle = Atan2(characterDir.x, characterDir.z);

        //Print("cameraAngle=" + String(cameraAngle) + " characterAngle=" + String(characterAngle) + " inputAngle=" + String(gInput.m_leftStickAngle));
        float diff = computeDifference();
        // debugText = "DIFF=" + String(diff) + " SEL=" + String(RadialSelectAnimation(4)) + " m=" + String(gInput.m_leftStickMagnitude) + " l=" + String(gInput.m_leftStickHoldTime);
        */
    }

    if (engine.headless)
    {
        //if (!debugText.empty)
        //    Print(debugText);

        globalTime += timeStep;

         if (globalTime > 0.5)
        {
            if (player !is null && globalState != 1)
            {
                globalState = 1;
                player.Attack();
            }
        }

        if (globalTime > 1)
        {
            if (globalState != 2)
            {
                @player = null;
                @thug = null;
                characterNode.RemoveAllComponents();
                thugNode.RemoveAllComponents();
                @gEnemyMgr = null;
                gMotionMgr.Stop();
                globalState = 2;
            }
        }

        if (globalTime > 3.0)
        {
            engine.Exit();
        }
    }
    else
    {
        Text@ text = ui.root.GetChild("instruction", true);
        text.text = debugText;
    }
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    DebugRenderer@ debug = scene_.debugRenderer;
    if (true)
    {
        // debug.AddNode(scene_, 2.0f, false);
        if (player !is null)
            player.DebugDraw(debug);
        if (thug !is null)
            thug.DebugDraw(debug);
    }
}

String patchInstructions = "";