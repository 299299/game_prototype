// ==============================================
//
//    Input Processing Class
//
//
//    Joystick: 0 -> A 1 -> B 2 -> X 3 -> Y
//
//
// ==============================================

bool  freezeInput = false;
const float touch_scale_x = 0.15;
const float button_scale_x = 0.1;
const float border_offset = 2.0;
const String tag_input = "tag_input";
const String touch_btn_name = "touch_move";
const String touch_icon_name = "touch_move_icon";

enum InputAction
{
    kInputAttack = 0,
    kInputEvade,
    kInputCounter,
    kInputDistract,
};

class GameInput
{
    float m_leftStickX;
    float m_leftStickY;
    float m_leftStickMagnitude;
    float m_leftStickAngle;

    float m_lastLeftStickX;
    float m_lastLeftStickY;
    float m_leftStickHoldTime;

    float m_smooth = 0.9f;
    int   m_leftStickHoldFrames = 0;

    Array<String> actionNames;
    Array<IntVector2> touchedPositions;
    bool touchMovingArea = false;
    IntVector2 touchMovingPosition;

    GameInput()
    {
        if (!mobile)
            input.mouseVisible = true;
    }

    void Update(float dt)
    {
        m_lastLeftStickX = m_leftStickX;
        m_lastLeftStickY = m_leftStickY;

        Vector2 leftStick = GetLeftStick();

        m_leftStickX = Lerp(m_leftStickX, leftStick.x, m_smooth);
        m_leftStickY = Lerp(m_leftStickY, leftStick.y, m_smooth);

        m_leftStickMagnitude = m_leftStickX * m_leftStickX + m_leftStickY * m_leftStickY;
        m_leftStickAngle = Atan2(m_leftStickX, m_leftStickY);

        float diffX = m_lastLeftStickX - m_leftStickX;
        float diffY = m_lastLeftStickY - m_leftStickY;
        float stickDifference = diffX * diffX + diffY * diffY;

        if(stickDifference < 0.1f)
        {
            m_leftStickHoldTime += dt;
            ++m_leftStickHoldFrames;
        }
        else
        {
            m_leftStickHoldTime = 0;
            m_leftStickHoldFrames = 0;
        }

        /*if (input.numTouches > 0)
        {
            TouchState@ ts = input.touches[0];
            String uiName = "null";
            if (ts.touchedElement !is null)
                uiName = ts.touchedElement.name;
            Print("TouchState position=" + ts.position.ToString() +
                  " delta=" + ts.delta.ToString() +
                  " pressure=" + ts.pressure +
                  " touchedElement=" + uiName);
        }*/

        UpdateInputUI();
    }

    Vector3 GetLeftAxis()
    {
        return Vector3(m_leftStickX, m_leftStickY, m_leftStickMagnitude);
    }

    float GetLeftAxisAngle()
    {
        return m_leftStickAngle;
    }

    int GetLeftAxisHoldingFrames()
    {
        return m_leftStickHoldFrames;
    }

    float GetLeftAxisHoldingTime()
    {
        return m_leftStickHoldTime;
    }

    Vector2 GetLeftStick()
    {
        touchMovingArea = false;
        Vector2 ret;
        if (!IsTouching())
            return ret;

        GetTouchedPosition();
        for (uint i=0; i<touchedPositions.length; ++i)
        {
            UIElement@ e = ui.GetElementAt(touchedPositions[i]);
            if (e !is null)
            {
                if (e.name == touch_btn_name)
                {
                    float w = float(e.size.x) / 2.0;
                    float cx = float(e.position.x) + w;
                    float cy = float(e.position.y) + w;
                    float mx = float(touchedPositions[i].x);
                    float my = float(touchedPositions[i].y);
                    ret.x = (mx - cx) / w;
                    ret.y = -(my - cy) / w;
                    touchMovingArea = true;
                    touchMovingPosition = touchedPositions[i];
                    return ret;
                }
            }
        }

        return ret;
    }

    // Returns true if the left game stick hasn't moved in the given time frame
    bool HasLeftStickBeenStationary(float value)
    {
        return m_leftStickHoldTime > value;
    }

    // Returns true if the left game pad hasn't moved since the last update
    bool IsLeftStickStationary()
    {
        return HasLeftStickBeenStationary(0.01f);
    }

    // Returns true if the left stick is the dead zone, false otherwise
    bool IsLeftStickInDeadZone()
    {
        return m_leftStickMagnitude < 0.025f;
    }

    bool IsInputActioned(int action)
    {
        if (freezeInput)
            return false;

        bool ret = false;
        if (IsTouching())
        {
            GetTouchedPosition();
            for (uint i=0; i<touchedPositions.length; ++i)
            {
                UIElement@ e = ui.GetElementAt(touchedPositions[i]);
                if (e !is null && e.name == actionNames[action])
                {
                    ret = true;
                    break;
                }
            }
        }

        if (!mobile && !ret)
        {
            if (action == kInputAttack)
                ret = input.keyPress[KEY_1];
            else if (action == kInputEvade)
                ret = input.keyPress[KEY_2];
            else if (action == kInputCounter)
                ret = input.keyPress[KEY_3];
            else if (action == kInputDistract)
                ret = input.keyPress[KEY_4];
        }

        return ret;
    }

    String GetDebugText()
    {
        String ret =   "leftStick:(" + m_leftStickX + "," + m_leftStickY + ")" +
                       " left-angle=" + m_leftStickAngle + " hold-time=" + m_leftStickHoldTime +
                       " hold-frames=" + m_leftStickHoldFrames + " left-magnitude=" + m_leftStickMagnitude + "\n";

        return ret;
    }

    void CreateGUI()
    {
        CreateHatButton();
        CreateHatIconButton();
        float w = float(graphics.width) * button_scale_x;
        float x = float(graphics.width) - (w + border_offset) * 4;
        float y = graphics.height - w - border_offset;
        Button@ btn = CreateButton(x, y, "attack");
        actionNames.Push(btn.name);
        x += (w + border_offset);
        btn = CreateButton(x, y, "evade");
        actionNames.Push(btn.name);
        x += (w + border_offset);
        btn = CreateButton(x, y, "counter");
        actionNames.Push(btn.name);
        x += (w + border_offset);
        btn = CreateButton(x, y, "distract");
        actionNames.Push(btn.name);
    }

    Button@ CreateButton(float x, float y, const String& text)
    {
        Button@ button = Button();
        button.name = text;
        button.texture = cache.GetResource("Texture2D", "Textures/TouchInput.png");
        button.imageRect = IntRect(96,0,192,96);
        float w = float(graphics.width) * button_scale_x;
        button.SetFixedSize(int(w), int(w));
        button.SetPosition(int(x), int(y));
        button.visible = false;
        button.AddTag(tag_input);
        Text@ buttonText = button.CreateChild("Text");
        buttonText.SetAlignment(HA_CENTER, VA_CENTER);
        buttonText.SetFont(cache.GetResource("Font", UI_FONT), 30);
        buttonText.color = Color(1, 0, 0);
        buttonText.text = text;
        ui.root.AddChild(button);
        return button;
    }

    Button@ CreateHatButton()
    {
        Button@ button = Button();
        button.name = touch_btn_name;
        button.texture = cache.GetResource("Texture2D", "Textures/TouchInput.png");
        button.imageRect = IntRect(0,0,96,96);
        float w = float(graphics.width) * touch_scale_x;
        button.SetFixedSize(int(w), int(w));
        button.SetPosition(int(border_offset), int(graphics.height - w - border_offset));
        button.visible = false;
        button.AddTag(tag_input);
        ui.root.AddChild(button);
        return button;
    }

    Button@ CreateHatIconButton()
    {
        Button@ button = Button();
        button.name = touch_icon_name;
        button.texture = cache.GetResource("Texture2D", "Textures/TouchInput.png");
        button.imageRect = IntRect(0,0,96,96);
        float w = float(graphics.width) * touch_scale_x / 4.0f;
        button.SetFixedSize(int(w), int(w));
        button.visible = false;
        button.enabled = false;
        button.AddTag(tag_input);
        ui.root.AddChild(button);
        return button;
    }

    void ShowHideUI(bool bShow)
    {
        Array<UIElement@> elements = ui.root.GetChildrenWithTag(tag_input);
        for (uint i=0; i<elements.length; ++i)
            elements[i].visible = bShow;
    }

    void UpdateInputUI()
    {
        Button@ icon_btn = ui.root.GetChild(touch_icon_name, false);
        if (icon_btn !is null)
        {
            icon_btn.visible = touchMovingArea;
            IntVector2 pos = touchMovingPosition;
            pos.x -= icon_btn.size.x / 2;
            pos.y -= icon_btn.size.y / 2;
            icon_btn.position = pos;
        }
    }

    bool IsTouching()
    {
        if (input.numTouches > 0)
        {
            TouchState@ ts = input.touches[0];
            return ts.pressure > 0.9f;
        }
        return input.mouseButtonDown[MOUSEB_LEFT];
    }

    void GetTouchedPosition()
    {
        touchedPositions.Clear();
        if (input.numTouches > 0)
        {
            for (uint i=0; i<touchedPositions.length; ++i)
            {
                touchedPositions.Push(input.touches[i].position);
            }
        }
        else
        {
            touchedPositions.Push(input.mousePosition);
        }
    }
};
