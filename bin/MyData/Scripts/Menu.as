

class TextMenu
{
    UIElement@          root;
    Array<String>       texts;
    Array<Text@>        items;
    String              fontName;
    int                 fontSize;
    int                 selection;
    Color               highLightColor = Color(1, 1, 0);
    Color               normalColor = Color(1, 0, 0);
    IntVector2          size = IntVector2(400, 100);

    TextMenu(const String& fName, int fSize)
    {
        fontName = fName;
        fontSize = fSize;
    }

    void Add()
    {
        if (root !is null)
            return;

        root = ui.root.CreateChild("UIElement");
        if (!engine.headless)
        {
            int height = graphics.height / 22;
            if (height > 64)
                height = 64;

            root.SetAlignment(HA_CENTER, VA_CENTER);
            root.SetPosition(0, -height * 2);
        }

        root.SetLayout(LM_VERTICAL, 8);
        root.SetFixedSize(size.x, size.y);

        for (uint i=0; i<texts.length; ++i)
        {
            AddText(texts[i]);
        }
    }

    void Remove()
    {
        if (root is null)
            return;
        items.Clear();
        root.Remove();
        root = null;
    }

    void AddText(const String& str)
    {
        Text@ text = root.CreateChild("Text");
        text.SetFont(cache.GetResource("Font", fontName), fontSize);
        text.text = str;
        text.color = normalColor;
        items.Push(text);
    }

    int Update(float dt)
    {
        int selIndex = selection;
        if (gInput.GetDirectionPressed() >= 0)
            selIndex ++;
        for (uint i=0; i<items.length; ++i)
        {
            if (items[i].hovering)
            {
                selIndex = int(i);
                break;
            }
        }
        ChangeSelection(selIndex);
        return gInput.IsEnterPressed() ? selection : -1;
    }

    void ChangeSelection(int index)
    {
        if (selection == index)
            return;

        if (selection >= 0)
            items[selection].color = normalColor;

        selection = index;
        if (selection >= 0)
            items[selection].color = highLightColor;
    }
};