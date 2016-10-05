#include "Scripts/Constants.as"
// ------------------------------------------------
#include "Scripts/Game.as"
#include "Scripts/AssetProcess.as"
#include "Scripts/Motion.as"
#include "Scripts/Input.as"
#include "Scripts/FSM.as"
#include "Scripts/Camera.as"
#include "Scripts/Menu.as"
#include "Scripts/Follow.as"
#include "Scripts/PhysicsSensor.as"
// ------------------------------------------------
#include "Scripts/GameObject.as"
#include "Scripts/Interactable.as"
#include "Scripts/Door.as"
#include "Scripts/Food.as"
#include "Scripts/Character.as"
#include "Scripts/Max.as"
#include "Scripts/Player.as"

enum RenderFeature
{
    RF_NONE     = 0,
    RF_SHADOWS  = (1 << 0),
    RF_HDR      = (1 << 1),

    RF_FULL     = RF_SHADOWS | RF_HDR,
};

int drawDebug = 1;
bool bHdr = true;
bool bigHeadMode = false;
bool nobgm = true;
int colorGradingIndex = 0;

Node@ musicNode;
float BGM_BASE_FREQ = 44100;

String CAMERA_NAME = "Camera";

uint playerId = M_MAX_UNSIGNED;

int render_features = RF_FULL;

String LUT = "";
const String UI_FONT = "Fonts/GAEN.ttf";
int UI_FONT_SIZE = 20;

GameInput@ gInput = GameInput();
bool debugCamera = false;

void LoadGlobalVars()
{
    Variant v = GetGlobalVar("Draw_Debug");
    if (!v.empty)
    {
        drawDebug = v.GetInt();
    }

    v = GetGlobalVar("Color_Grading");
    if (!v.empty)
    {
        colorGradingIndex = v.GetInt();
    }

    v = GetGlobalVar("Debug_Camera");
    if (!v.empty)
    {
        debugCamera = v.GetBool();

        gCameraMgr.SetDebugCamera(debugCamera);
        ui.cursor.visible = !debugCamera;
    }
}

void SaveGlobalVars()
{
    SetGlobalVar("Draw_Debug", Variant(drawDebug));
    SetGlobalVar("Color_Grading", Variant(colorGradingIndex));
    SetGlobalVar("Debug_Camera", Variant(debugCamera));
}

void Start()
{
    Print("Game Running Platform: " + GetPlatform());
    // lowend_platform = GetPlatform() != "Windows";

    Array<String>@ arguments = GetArguments();
    for (uint i = 0; i < arguments.length; ++i)
    {
        String argument = arguments[i].ToLower();
        if (argument[0] == '-')
        {
            argument = argument.Substring(1);
            if (argument == "bgm")
                nobgm = !nobgm;
            else if (argument == "bighead")
                bigHeadMode = !bigHeadMode;
            else if (argument == "lowend")
                render_features = RF_NONE;
        }
    }

    if (!engine.headless && graphics.width < 640)
        render_features = RF_NONE;

    cache.autoReloadResources = true;
    engine.pauseMinimized = true;
    script.defaultScriptFile = scriptFile;
    if (renderer !is null && (render_features & RF_HDR != 0))
        renderer.hdrRendering = true;

    LoadGlobalVars();

    SetRandomSeed(time.systemTime);
    @gMotionMgr = LIS_Game_MotionManager();

    if (!engine.headless)
    {
        SetWindowTitleAndIcon();
        CreateConsoleAndDebugHud();
        CreateUI();
    }

    InitAudio();
    SubscribeToEvents();

    gGame.Start();
    gGame.ChangeState("LoadingState");
}

void Stop()
{
    Print("Test Stop");
    gMotionMgr.Stop();
    ui.Clear();
}

void InitAudio()
{
    if (engine.headless)
        return;

    audio.masterGain[SOUND_MASTER] = 0.5f;
    audio.masterGain[SOUND_MUSIC] = 0.5f;
    audio.masterGain[SOUND_EFFECT] = 1.0f;

    if (!nobgm)
    {
        Sound@ musicFile = cache.GetResource("Sound", "Sfx/bgm.ogg");
        musicFile.looped = true;

        BGM_BASE_FREQ = musicFile.frequency;

        // Note: the non-positional sound source component need to be attached to a node to become effective
        // Due to networked mode clearing the scene on connect, do not attach to the scene itself
        musicNode = Node();
        SoundSource@ musicSource = musicNode.CreateComponent("SoundSource");
        musicSource.soundType = SOUND_MUSIC;
        musicSource.gain = 0.5f;
        musicSource.Play(musicFile);
    }
}

void SetWindowTitleAndIcon()
{
    Image@ icon = cache.GetResource("Image", "Textures/UrhoIcon.png");
    graphics.windowIcon = icon;
}

void CreateConsoleAndDebugHud()
{
    // Get default style
    XMLFile@ xmlFile = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    if (xmlFile is null)
        return;

    // Create consoleui
    Console@ console = engine.CreateConsole();
    console.defaultStyle = xmlFile;
    console.background.opacity = 0.8f;

    // Create debug HUD
    DebugHud@ debugHud = engine.CreateDebugHud();
    debugHud.defaultStyle = xmlFile;
}

void CreateUI()
{
    ui.root.defaultStyle = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    // Create a Cursor UI element because we want to be able to hide and show it at will. When hidden, the mouse cursor will
    // control the camera, and when visible, it will point the raycast target
    XMLFile@ style = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    Cursor@ cursor = Cursor();
    cursor.SetStyleAuto(style);
    ui.cursor = cursor;
    cursor.visible = false;

    // Set starting position of the cursor at the rendering window center
    //cursor.SetPosition(graphics.width / 2, graphics.height / 2);
    //input.SetMouseVisible(true);
    Text@ text = ui.root.CreateChild("Text", "debug");
    text.SetFont(cache.GetResource("Font", "Fonts/Anonymous Pro.ttf"), 12);
    text.horizontalAlignment = HA_LEFT;
    text.verticalAlignment = VA_TOP;
    text.SetPosition(5, 0);
    text.color = Color(0, 0, 1);
    text.priority = -99999;
    // text.textEffect = TE_SHADOW;
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

Player@ GetPlayer()
{
    Scene@ scene_ = script.defaultScene;
    if (scene_ is null)
        return null;
    Node@ characterNode = scene_.GetNode(playerId);
    if (characterNode is null)
        return null;
    return cast<Player>(characterNode.scriptObject);
}

void SubscribeToEvents()
{
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
    SubscribeToEvent("KeyDown", "HandleKeyDown");
    SubscribeToEvent("MouseButtonDown", "HandleMouseButtonDown");
    SubscribeToEvent("AsyncLoadFinished", "HandleSceneLoadFinished");
    SubscribeToEvent("AsyncLoadProgress", "HandleAsyncLoadProgress");
    SubscribeToEvent("CameraEvent", "HandleCameraEvent");
    SubscribeToEvent("SliderChanged", "HandleSliderChanged");
    SubscribeToEvent("ReloadFinished", "HandleResourceReloadFinished");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();

    gInput.Update(timeStep);
    gCameraMgr.Update(timeStep);
    gGame.Update(timeStep);

    if (engine.headless)
        ExecuteCommand();

    if (script.defaultScene is null)
        return;

    if (drawDebug > 0)
    {
        String seperator = "-------------------------------------------------------------------------------------------------------\n";
        String debugText = seperator;
        debugText += gGame.GetDebugText();
        debugText += seperator;
        debugText += "current LUT: " + LUT + "\n";
        debugText += gCameraMgr.GetDebugText();
        debugText += gInput.GetDebugText();
        debugText += seperator;
        Player@ player = GetPlayer();
        if (player !is null)
            debugText += player.GetDebugText();
        debugText += seperator;

        Text@ text = ui.root.GetChild("debug", true);
        if (text !is null)
            text.text = debugText;
    }
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    Scene@ scene_ = script.defaultScene;
    if (scene_ is null)
        return;

    DebugRenderer@ debug = scene_.debugRenderer;
    if (drawDebug == 0)
        return;

    if (drawDebug > 0)
    {
        gCameraMgr.DebugDraw(debug);
        debug.AddNode(scene_, 1.0f, false);
        gGame.DebugDraw(debug);
    }
    if (drawDebug > 1)
        scene_.physicsWorld.DrawDebugGeometry(true);
}

void HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
    Scene@ scene_ = script.defaultScene;
    int key = eventData["Key"].GetInt();
    gGame.OnKeyDown(key);

    // Print("Key Down = " + key);

    if (key == KEY_F1)
    {
        ++drawDebug;
        if (drawDebug > 3)
            drawDebug = 0;

        Text@ text = ui.root.GetChild("debug", true);
        if (text !is null)
            text.visible = drawDebug != 0;

        SaveGlobalVars();
    }
    else if (key == KEY_F2)
        debugHud.ToggleAll();
    else if (key == KEY_F3)
        console.Toggle();
    else if (key == KEY_F4)
    {
        Camera@ cam = gCameraMgr.GetCamera();
        if (cam !is null)
            cam.fillMode = (cam.fillMode == FILL_SOLID) ? FILL_WIREFRAME : FILL_SOLID;
    }
    else if (key == KEY_F5)
        ToggleDebugWindow();
    else if (key == KEY_1)
        ShootSphere(scene_);
    else if (key == KEY_2)
        ShootBox(scene_);
    else if (key == KEY_3)
    {
        debugCamera = !debugCamera;
        gCameraMgr.SetDebugCamera(debugCamera);
        ui.cursor.visible = !debugCamera;
        SaveGlobalVars();
    }
    else if (key == KEY_4)
    {
        colorGradingIndex ++;
        SetColorGrading(colorGradingIndex);
        SaveGlobalVars();
    }
    else if (key == KEY_5)
    {
        colorGradingIndex --;
        SetColorGrading(colorGradingIndex);
        SaveGlobalVars();
    }
    else if (key == 'R' || key == 'r')
        scene_.updateEnabled = !scene_.updateEnabled;
    else if (key == 'T'  || key == 't')
    {
        scene_.timeScale = (scene_.timeScale >= 0.999f) ? 0.1f : 1.0f;
    }
    else if (key == 'Q' || key == 'q')
        engine.Exit();
    else if (key == 'E' || key == 'e')
    {
        String testName = GetAnimationName("AS_INTERACT_Interact/A_Max_GP_Interact_Door01_SF");
        Array<String> testAnimations;
        Player@ player = GetPlayer();
        testAnimations.Push(testName);
        //testAnimations.Push("BM_Climb/Dangle_Right");
        testAnimations.Push(GetAnimationName("AS_INTERACT_Interact/A_Max_GP_Interact_Door02_SF"));
        if (player !is null)
            player.TestAnimation(testAnimations);
    }
    else if (key == 'F' || key == 'f')
    {
        scene_.timeScale = 1.0f;
        // SetWorldTimeScale(scene_, 1);
    }
    else if (key == 'I' || key == 'i')
    {
        Player@ p = GetPlayer();
        if (p !is null)
            p.SetPhysicsType(1 - p.physicsType);
    }
    else if (key == 'M' || key == 'm')
    {
        Player@ p = GetPlayer();
        if (p !is null)
        {
            Print("------------------------------------------------------------");
            for (uint i=0; i<p.stateMachine.states.length; ++i)
            {
                State@ s = p.stateMachine.states[i];
                Print("name=" + s.name + " nameHash=" + s.nameHash.ToString());
            }
            Print("------------------------------------------------------------");
        }
    }
    else if (key == 'U' || key == 'u')
    {
        Player@ p = GetPlayer();
        if (p.timeScale > 1.0f)
            p.timeScale = 1.0f;
        else
            p.timeScale = 1.25f;
    }
    else if (key == 'G' || key == 'g')
    {
        GetPlayer().ChangeState("OpenDoorState");
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

        //CreateDrag(float(pos.x), float(pos.y));
        SubscribeToEvent("MouseMove", "HandleMouseMove");
        SubscribeToEvent("MouseButtonUp", "HandleMouseButtonUp");
    }
}

void HandleMouseButtonUp(StringHash eventType, VariantMap& eventData)
{
    int button = eventData["Button"].GetInt();
    if (button == MOUSEB_RIGHT)
    {
        //DestroyDrag();
        UnsubscribeFromEvent("MouseMove");
        UnsubscribeFromEvent("MouseButtonUp");
    }
}

void HandleMouseMove(StringHash eventType, VariantMap& eventData)
{
    int x = input.mousePosition.x;
    int y = input.mousePosition.y;
    //MoveDrag(float(x), float(y));
}

void HandleSceneLoadFinished(StringHash eventType, VariantMap& eventData)
{
    Print("HandleSceneLoadFinished");
    gGame.OnSceneLoadFinished(eventData["Scene"].GetPtr());
}

void HandleAsyncLoadProgress(StringHash eventType, VariantMap& eventData)
{
    Print("HandleAsyncLoadProgress");
    Scene@ _scene = eventData["Scene"].GetPtr();
    float progress = eventData["Progress"].GetFloat();
    int loadedNodes = eventData["LoadedNodes"].GetInt();
    int totalNodes = eventData["TotalNodes"].GetInt();
    int loadedResources = eventData["LoadedResources"].GetInt();
    int totalResources = eventData["TotalResources"].GetInt();
    gGame.OnAsyncLoadProgress(_scene, progress, loadedNodes, totalNodes, loadedResources, totalResources);
}

void HandleCameraEvent(StringHash eventType, VariantMap& eventData)
{
    gCameraMgr.OnCameraEvent(eventData);
}

void HandleResourceReloadFinished(StringHash eventType, VariantMap& eventData)
{

}

int FindRenderCommand(RenderPath@ path, const String&in tag)
{
    for (uint i=0; i<path.numCommands; ++i)
    {
        if (path.commands[i].tag == tag)
            return i;
    }
    return -1;
}

void ChangeRenderCommandTexture(RenderPath@ path, const String&in tag, const String&in texture, TextureUnit unit)
{
    int i = FindRenderCommand(path, tag);
    if (i < 0)
    {
        Print("Can not find renderpath tag " + tag);
        return;
    }

    RenderPathCommand cmd = path.commands[i];
    cmd.textureNames[unit] = texture;
    path.commands[i] = cmd;
}

void SetColorGrading(int index)
{
    Array<String> colorGradingTextures =
    {
        "Weathered",
        "Hipster",
        "Vintage",
        "Hollywood",
        "BleachBypass",
        "CrossProcess",
        "Dream",
        "Negative",
        "Rainbow",
        "Posterize",
        "Noire",
        "SciFi",
        "SinCity",
        "Saw",
        "Sepia",
        "1960",
        "Action",
        "AlienInvasion",
        "BadFilm",
        "Beach",
        "Cyberpunk",
        "Dark",
        "DayForNight",
        "Documentary",
        "FinalBattle",
        "Fire",
        "Flashback",
        "Hackers",
        "HeatSignature",
        "Hitchcock",
        "AlienWorld",
        "Horror",
        "HotSun",
        "Intensity",
        "Matrix",
        "Millennium",
        "MusicVideo",
        "OldCountry",
        "OrangeTeal",
        "PurpleHaze",
        "RedAndBlue",
        "RedRoom",
        "RobotVision",
        "Romantic",
        "TexMex",
        "Toxic",
        "TritonePurple",
        "Underwater",
        "War",
        "Warm",
        "LUTIdentity"
    };
    int len = int(colorGradingTextures.length);
    if (index >= len)
        index = 0;
    if (index < 0)
        index = len - 1;
    colorGradingIndex = index;
    LUT = colorGradingTextures[index];
    ChangeRenderCommandTexture(renderer.viewports[0].renderPath, "ColorCorrection", "Textures/LUT/" + LUT + ".xml", TU_VOLUMEMAP);
}

void ToggleDebugWindow()
{
    Window@ win = ui.root.GetChild("DebugWindow", true);
    if (win !is null)
    {
        win.Remove();
        input.SetMouseVisible(false);
        freezeInput = false;
        return;
    }

    win = Window();
    win.name = "DebugWindow";
    win.movable = true;
    win.resizable = true;
    win.opacity = 0.8f;
    win.SetLayout(LM_VERTICAL, 2, IntRect(2,4,2,4));
    win.SetAlignment(HA_LEFT, VA_TOP);
    win.SetStyleAuto();
    ui.root.AddChild(win);

    Text@ windowTitle = Text();
    windowTitle.text = "Debug Parameters";
    windowTitle.SetStyleAuto();
    win.AddChild(windowTitle);

    IntVector2 scrSize(graphics.width, graphics.height);
    IntVector2 winSize(scrSize);
    winSize.x = int(float(winSize.x) * 0.3f);
    winSize.y = int(float(winSize.y) * 0.5f);
    win.size = winSize;
    win.SetPosition(5, (scrSize.y - winSize.y)/3);
    input.SetMouseVisible(true);
    freezeInput = true;

    RenderPath@ path = renderer.viewports[0].renderPath;
    UIElement@ parent = win;
    CreateDebugSlider(parent, "TonemapMaxWhite", 0, 0.0f, 5.0f, path.shaderParameters["TonemapMaxWhite"].GetFloat());
    CreateDebugSlider(parent, "TonemapExposureBias", 0, 0.0f, 5.0f, path.shaderParameters["TonemapExposureBias"].GetFloat());
    //CreateDebugSlider(parent, "BloomHDRBlurRadius", 0, 0.0f, 10.0f, path.shaderParameters["BloomHDRBlurRadius"].GetFloat());
    CreateDebugSlider(parent, "BloomHDRMix_x", 1, 0.0f, 1.0f, path.shaderParameters["BloomHDRMix"].GetVector2().x);
    CreateDebugSlider(parent, "BloomHDRMix_y", 2, 0.0f, 5.0f, path.shaderParameters["BloomHDRMix"].GetVector2().y);
}

void CreateDebugSlider(UIElement@ parent, const String&in label, int tag, float min, float max, float cur)
{
    UIElement@ textContainer = UIElement();
    parent.AddChild(textContainer);
    textContainer.layoutMode = LM_HORIZONTAL;
    textContainer.SetStyleAuto();

    Text@ text = Text();
    textContainer.AddChild(text);
    text.text = label + ": ";
    text.SetStyleAuto();

    Text@ valueText = Text();
    textContainer.AddChild(valueText);
    valueText.name = label + "_value";
    valueText.text = String(cur);
    valueText.SetStyleAuto();

    Slider@ slider = Slider();
    slider.name = label;
    slider.SetStyleAuto();
    slider.range = max - min;
    slider.value = cur - min;
    slider.SetMinSize(2, 16);
    slider.vars[RANGE] = Vector2(min, max);
    slider.vars[TAG] = tag;
    parent.AddChild(slider);
}

void HandleSliderChanged(StringHash eventType, VariantMap& eventData)
{
    UIElement@ ui = eventData["Element"].GetPtr();
    float value = eventData["Value"].GetFloat();
    if (!ui.vars.Contains(TAG))
        return;

    Vector2 range = ui.GetVar(RANGE).GetVector2();
    value += range.x;
    int tag = ui.GetVar(TAG).GetInt();
    Text@ valueText = ui.parent.GetChild(ui.name + "_value", true);
    if (valueText !is null)
        valueText.text = String(value);

    RenderPath@ path = renderer.viewports[0].renderPath;

    switch (tag)
    {
    case 0:
        path.shaderParameters[ui.name] = value;
        break;
    case 1:
        {
            Vector2 v = path.shaderParameters["BloomHDRMix"].GetVector2();
            v.x = value;
            path.shaderParameters["BloomHDRMix"] = Variant(v);
        }
        break;
    case 2:
        {
            Vector2 v = path.shaderParameters["BloomHDRMix"].GetVector2();
            v.y = value;
            path.shaderParameters["BloomHDRMix"] = Variant(v);
        }
        break;
    }
}

void ExecuteCommand()
{
    String commands = GetConsoleInput();
    if(commands.length == 0)
        return;

    Print("######### Console Input: [" + commands + "] #############");
    Array<String> command_list = commands.Split(',');
    String command = command_list.empty ? commands : command_list[0];

    if (command == "dump")
    {
        String debugText = "camera position=" + gCameraMgr.GetCameraNode().worldPosition.ToString() + "\n";
        debugText += gInput.GetDebugText();

        Scene@ scene_ = script.defaultScene;
        if (scene_ !is null)
        {
            Array<Node@> nodes = scene_.GetChildrenWithScript("GameObject", true);
            for (uint i=0; i<nodes.length; ++i)
            {
                GameObject@ object = cast<GameObject@>(nodes[i].scriptObject);
                if (object !is null)
                    debugText += object.GetDebugText();
            }
        }
        Print(debugText);
    }
    else if (command == "anim")
    {
        String testName = "BM_Attack/Attack_Close_Forward_02";
        Player@ player = GetPlayer();
        if (player !is null)
            player.TestAnimation(testName);
    }
    else if (command == "stop")
    {
        gMotionMgr.Stop();
        Scene@ scene_ = script.defaultScene;
        if (scene_ is null)
            return;
        scene_.Clear();
    }
}

class LIS_Game_MotionManager : MotionManager
{
    void AddMotions()
    {
        Create_Max_Motions();
    }

    void AddTriggers()
    {
        Add_Max_AnimationTriggers();
    }
};