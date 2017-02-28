// ==================================================================
//
//    Batch Process Asset Script for automatic pipeline
//
// ==================================================================］

const String OUT_DIR = "MyData/";
const String ASSET_DIR = "Asset/";
const Array<String> MODEL_ARGS = {"-t", "-na", "-cm", "-ct", "-ns", "-nt", "-nm", "-mb", "75"};//"-l", "-np"
const Array<String> ANIMATION_ARGS = {"-nm", "-nt", "-mb", "75"};
String exportFolder;
Scene@ processScene;
bool forceCompile = false;

void PreProcess()
{
    Array<String>@ arguments = GetArguments();
    for (uint i=0; i<arguments.length; ++i)
    {
        if (arguments[i] == "-f")
            exportFolder = arguments[i + 1];
        else if (arguments[i] == "-b")
            forceCompile = true;
    }

    Print("exportFolder=" + exportFolder);
    fileSystem.CreateDir(OUT_DIR + "Models");
    fileSystem.CreateDir(OUT_DIR + "Animations");
    fileSystem.CreateDir(OUT_DIR + "Objects");
    processScene = Scene();
    processScene.CreateComponent("Octree");
}

String DoProcess(const String&in inName, const String&in outName, const String&in command, const Array<String>&in args)
{
    if (!exportFolder.empty)
    {
        if (!inName.Contains(exportFolder))
            return "";
    }

    String iname = inName; //"Asset/" + folderName + name;
    String oname = outName; //OUT_DIR + folderName + GetFileName(name) + ".mdl";

    if (fileSystem.FileExists(oname) && !forceCompile)
    {
        // Print(oname + " exist ...");
        return oname;
    }

    uint pos = oname.FindLast('/');
    String outFolder = oname.Substring(0, pos);
    fileSystem.CreateDir(outFolder);

    bool is_windows = GetPlatform() == "Windows";
    if (is_windows) {
        iname.Replace("/", "\\");
        oname.Replace("/", "\\");
    }

    Array<String> runArgs;
    runArgs.Push(command);
    runArgs.Push("\"" + iname + "\"");
    runArgs.Push("\"" + oname + "\"");
    for (uint i=0; i<args.length; ++i)
        runArgs.Push(args[i]);

    int ret = fileSystem.SystemRun(fileSystem.programDir + "tool/AssetImporter", runArgs);
    if (ret != 0)
        Print("DoProcess " + inName + " ret=" + ret);

    return oname;
}

void ProcessModels()
{
    Array<String> models = fileSystem.ScanDir(ASSET_DIR + "Models", "*.*", SCAN_FILES, true);
    for (uint i=0; i<models.length; ++i)
    {
        // Print("Found a model " + models[i]);
        String model = models[i];
        uint pos = model.FindLast('.');
        DoProcess(ASSET_DIR + "Models/" + model, OUT_DIR + "Models/" + model.Substring(0, pos) + ".mdl", "model", MODEL_ARGS);
    }
}

void ProcessAnimations()
{
    Array<String> animations = fileSystem.ScanDir(ASSET_DIR + "Animations", "*.*", SCAN_FILES, true);
    for (uint i=0; i<animations.length; ++i)
    {
        // Print("Found a animation " + animations[i]);
        String anim = animations[i];
        uint pos = anim.FindLast('.');
        if (fileSystem.FileExists(OUT_DIR + "Animations/" + anim.Substring(0, pos) + "_Take 001.ani") && !forceCompile)
        {
            continue;
        }
        DoProcess(ASSET_DIR + "Animations/" + anim, OUT_DIR + "Animations/" + anim.Substring(0, pos) + ".mdl", "anim", ANIMATION_ARGS);
    }
}

void PostProcess()
{
    if (processScene !is null)
        processScene.Remove();
    @processScene = null;
}

void Start()
{
    Print("*************************************************************************");
    Print("Start Processing .....");
    Print("*************************************************************************");
    uint startTime = time.systemTime;
    PreProcess();

    ProcessModels();
    ProcessAnimations();

    PostProcess();
    engine.Exit();
    uint timeSec = (time.systemTime - startTime) / 1000;
    if (timeSec > 60)
        ErrorDialog("BATCH PROCESS", "Time cost = " + String(float(timeSec)/60.0f) + " min.");
    else
        Print("BATCH PROCESS  Time cost = " + timeSec + " sec.");
    Print("*************************************************************************");
    Print("*************************************************************************");
}