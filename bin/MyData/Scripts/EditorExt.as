
Array<String> cachedFolders;
bool searched = false;

void UpdateExt(float dt)
{
    if (input.keyPress['J'] || input.keyPress['j'])
    {
        SaveSelectedPrefab();
    }
    else if (input.keyPress['K'] || input.keyPress['k'])
    {
        ReloadSceneByPrefab();
    }
}

String FindObjectByName(const String&in name)
{
    if (!searched)
    {
        cachedFolders = fileSystem.ScanDir("MyData/Objects", "*", SCAN_DIRS, true);
        searched = true;
    }

    for (uint i=0; i<cachedFolders.length; ++i)
    {
        String fileName = "MyData/Objects/" + cachedFolders[i] + "/" + name + ".xml";
        if (fileSystem.FileExists(fileName))
        {
            return fileName;
        }
    }
    return "";
}

void SaveSelectedPrefab()
{
    if (editNode is null)
        return;

    String fileName = FindObjectByName(editNode.name);
    if (!fileName.empty)
    {
        Print("SaveSelectedPrefab " + editNode.name + " found " + fileName);
        SaveNode(fileName);
    }
}

void ReloadSceneByPrefab()
{
    if (editorScene is null)
        return;

    Array<Node@> nodes;
    Array<String> objects;
    for (uint i=0; i<editorScene.numChildren; ++i)
    {
        Node@ _node = editorScene.children[i];
        String objectFile = FindObjectByName(_node.name);
        if (objectFile.empty)
            continue;

        nodes.Push(_node);
        objects.Push(objectFile);
    }

    for (uint i=0; i<nodes.length; ++i)
    {
        Node@ oldNode = nodes[i];
        Print("Reloading prefab " + oldNode.name);
        Node@ newNode = LoadNode(objects[i]);
        newNode.position = oldNode.position;
        newNode.rotation = oldNode.rotation;
        newNode.scale = oldNode.scale;
        newNode.id = oldNode.id;
        oldNode.Remove();
    }

    UpdateWindowTitle();
    DisableInspectorLock();
    UpdateHierarchyItem(editorScene, true);
    CollapseHierarchy();
    ClearEditActions();
}

