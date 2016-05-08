// ==================================================================
//
//    Batch Process Asset Script for automatic pipeline
//
// ==================================================================

const String OUT_DIR = "MyData/";
const String ASSET_DIR = "Asset/";
const Array<String> MODEL_ARGS = {"-t", "-na", "-l", "-cm", "-ct", "-ns", "-nt", "-mb", "75"};//"-nm",
const Array<String> ANIMATION_ARGS = {"-nm", "-nt", "-mb", "75"};
String exportFolder;
Scene@ processScene;

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
    fileSystem.CreateDir(OUT_DIR + "Objects");
    processScene = Scene();
}

String DoProcess(const String&in name, const String&in folderName, const Array<String>&in args, bool checkFolders)
{
    if (!exportFolder.empty && checkFolders)
    {
        if (!name.Contains(exportFolder))
            return "";
    }

    String iname = "Asset/" + folderName + name;
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
        Print("Found a model " + models[i]);
        DoProcess(models[i], "Models/", MODEL_ARGS, false);
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

void ProcessObjects()
{
    Array<String> objects = fileSystem.ScanDir(ASSET_DIR + "Objects", "*.*", SCAN_FILES, true);
    for (uint i=0; i<objects.length; ++i)
    {
        String object = objects[i];
        Print("Found a object " + object);
        String outMdlName = DoProcess(object, "Objects/", MODEL_ARGS, false);

        String oname = OUT_DIR + "Objects/" + object;
        String objectFile = oname.Substring(0, oname.FindLast('/'));
        String objectResourceFolder = "Objects/" + object.Substring(0, object.FindLast('/') + 1);
        Print("objectResourceFolder=" + objectResourceFolder);

        int index = objectFile.FindLast('/') + 1;
        String objectName = objectFile.Substring(index, objectFile.length - index);
        objectFile += "/" + objectName + ".xml";
        Print("ObjectFile: " + objectFile);

        if (!fileSystem.FileExists(objectFile))
        {
            Node@ node = processScene.CreateChild(objectName);
            int i = outMdlName.Find('/') + 1;
            String modelName = outMdlName.Substring(i, outMdlName.length - i);
            Model@ model = cache.GetResource("Model", modelName);
            if (model is null)
            {
                Print("model " + modelName + " load failed!!");
                return;
            }

            String matFile = outMdlName;
            matFile.Replace(".mdl", ".txt");
            Print("matFile=" + matFile);

            Array<String> matList;
            File file;
            if (file.Open(matFile, FILE_READ))
            {
                while (!file.eof)
                {
                    String line = file.ReadLine();
                    if (!line.empty)
                    {
                        Print(line);
                        matList.Push(line);
                    }
                }
            }

            if (model.skeleton.numBones > 0)
            {
                Node@ renderNode = node.CreateChild("RenderNode");
                AnimatedModel@ am = renderNode.CreateComponent("AnimatedModel");
                renderNode.worldRotation = Quaternion(0, 180, 0);
                am.model = model;
                am.castShadows = true;

                for (uint i=0; i<matList.length; ++i)
                {
                    am.materials[i] = cache.GetResource("Material", objectResourceFolder + matList[i]);
                }
            }
            else
            {
                StaticModel@ sm = node.CreateComponent("StaticModel");
                sm.model = model;
                sm.castShadows = true;

                for (uint i=0; i<matList.length; ++i)
                {
                    sm.materials[i] = cache.GetResource("Material", objectResourceFolder + matList[i]);
                }
            }

            File outFile(objectFile, FILE_WRITE);
            node.SaveXML(outFile);
        }
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
    uint startTime = time.systemTime;
    PreProcess();
    ProcessModels();
    ProcessObjects();
    ProcessAnimations();
    PostProcess();
    engine.Exit();
    uint timeSec = (time.systemTime - startTime) / 1000;
    if (timeSec > 60)
        ErrorDialog("BATCH PROCESS", "Time cost = " + String(float(timeSec)/60.0f) + " min");
    else
        ErrorDialog("BATCH PROCESS", "Time cost = " + String(timeSec) + " sec");
}