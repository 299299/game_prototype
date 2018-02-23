// ==================================================================
//
//    Batch Process Asset Script for automatic pipeline
//
// ==================================================================

const String OUT_DIR = "MyData/";
const String ASSET_DIR = "Asset/";
const int MAX_BONES = 64; //75
const Array<String> MODEL_ARGS = {"-na", "-l", "-cm", "-ct", "-nm", "-nt", "-mb", String(MAX_BONES), "-np", "-s", "Gundummy02"}; //"-t",
const Array<String> ANIMATION_ARGS = {"-nm", "-nt", "-mb", String(MAX_BONES), "-np", "-s", "Gundummy02"};
String exportFolder;

void PreProcess()
{
    Array<String>@ arguments = GetArguments();
    for (uint i=0; i<arguments.length; ++i)
    {
        if (arguments[i] == "-folder")
            exportFolder = arguments[i + 1];
    }

    Print("exportFolder=" + exportFolder);
    fileSystem.CreateDir(OUT_DIR + "Models");
    fileSystem.CreateDir(OUT_DIR + "Animations");
}

String DoProcess(const String&in name, const String&in folderName, const Array<String>&in args, bool checkFolders)
{
    String fName = folderName + name;
    if (!exportFolder.empty && checkFolders)
    {
        if (!fName.Contains(exportFolder))
            return "";
    }

    String iname = "Asset/" + fName;
    uint pos = name.FindLast('.');
    String oname = OUT_DIR + folderName + name.Substring(0, pos) + ".mdl";
    pos = oname.FindLast('/');
    String outFolder = oname.Substring(0, pos);
    fileSystem.CreateDir(outFolder);

    bool is_windows = GetPlatform() == "Windows";
    if (is_windows) {
        iname.Replace("/", "\\");
        oname.Replace("/", "\\");
    }

    Array<String> runArgs;
    runArgs.Push("model");
    runArgs.Push("\"" + iname + "\"");
    runArgs.Push("\"" + oname + "\"");
    for (uint i=0; i<args.length; ++i)
        runArgs.Push(args[i]);

    //for (uint i=0; i<runArgs.length; ++i)
    //    Print("args[" + i +"]=" + runArgs[i]);

    int ret = fileSystem.SystemRun(fileSystem.programDir + "tool/AssetImporter", runArgs);
    if (ret != 0)
        Print("DoProcess " + name + " ret=" + ret);

    return oname;
}

void ProcessModels()
{
    Array<String> models = fileSystem.ScanDir(ASSET_DIR + "Models", "*.*", SCAN_FILES, true);
    for (uint i=0; i<models.length; ++i)
    {
        // Print("Found a model " + models[i]);
        DoProcess(models[i], "Models/", MODEL_ARGS, true);
    }
}

void ProcessAnimations()
{
    Array<String> animations = fileSystem.ScanDir(ASSET_DIR + "Animations", "*.*", SCAN_FILES, true);
    for (uint i=0; i<animations.length; ++i)
    {
        // Print("Found a animation " + animations[i]);
        String outMdlName = DoProcess(animations[i], "Animations/", ANIMATION_ARGS, true);
        if (!outMdlName.empty)
            fileSystem.Delete(outMdlName);
    }
}

void PostProcess()
{

}

void Start()
{
    uint startTime = time.systemTime;
    PreProcess();
    ProcessModels();
    ProcessAnimations();
    PostProcess();
    engine.Exit();
    uint timeSec = (time.systemTime - startTime) / 1000;
    String timeMsg = (timeSec > 60) ? (String(float(timeSec)/60.0f) + " min") : (String(timeSec) + " sec");
    Print("BATCH PROCESS Total Time cost = " + String(timeSec) + " sec");
}