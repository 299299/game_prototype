

void UpdateExt(float dt)
{
    if (input.keyPress['J'] || input.keyPress['j'])
    {
        SaveSelectedPrefab();
    }
}

void SaveSelectedPrefab()
{
    if (editNode is null)
        return;

    Array<String> folders = fileSystem.ScanDir("MyData/Objects", "*", SCAN_DIRS, true);
    for (uint i=0; i<folders.length; ++i)
    {
        String fileName = "MyData/Objects/" + folders[i] + "/" + editNode.name + ".xml";
        if (fileSystem.FileExists(fileName))
        {
            Print("SaveSelectedPrefab " + editNode.name + " found " + fileName);
            SaveNode(fileName);
            return;
        }
    }
}