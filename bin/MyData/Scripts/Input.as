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
const float touch_scale_x = 0.2;
const float button_scale_x = 0.1;
const int border_offset = 2;
const String tag_input = "Tag_Input";

enum InputAction
{
    kInputAttack,
    kInputCounter,
    kInputEvade,
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

    GameInput()
    {
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

        if (input.numTouches > 0)
        {
            TouchState@ ts = input.touches[0];
            String uiName = "null";
            if (ts.touchedElement !is null)
                uiName = ts.touchedElement.name;
            Print("TouchState position=" + ts.position.ToString() +
                  " delta=" + ts.delta.ToString() +
                  " pressure=" + ts.pressure +
                  " touchedElement=" + uiName);
        }
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
        Vector2 ret;
        if (input.numTouches > 0)
        {
            TouchState@ ts = input.touches[0];
            float x = float(ts.position.x);
            float y = float(graphics.height) - float(ts.position.y);
            float w = float(graphics.width) * touch_scale_x;
            float h = w;
            if (x < w && y < h)
            {
                float half_w = w / 2.0;
                float half_h = h / 2.0;
                ret.x = (x - half_w) / half_w;
                ret.y = (y - half_h) / half_h;
            }
            Print(" x=" + x + " ,y=" + y + " ret=" + ret.ToString());
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
        return m_leftStickMagnitude < 0.1;
    }

    bool IsInputActioned(int action)
    {
        if (freezeInput)
            return false;
        return false;
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
        CreateButton(0, 0);
    }

    Button@ CreateButton(float x, float y)
    {
        Button@ button = Button();
        button.name = "Button";
        button.texture = cache.GetResource("Texture2D", "Textures/TouchInput.png");
        button.imageRect = IntRect(96,0,192,96);
        float w = float(graphics.width) * button_scale_x;
        button.SetFixedSize(w, w);
        button.SetPosition(x, y);
        button.visible = false;
        button.AddTag(tag_input);
        ui.root.AddChild(button);
        return button;
    }

    Button@ CreateHatButton()
    {
        Button@ button = Button();
        button.texture = cache.GetResource("Texture2D", "Textures/TouchInput.png");
        button.imageRect = IntRect(0,0,96,96);
        float w = float(graphics.width) * touch_scale_x;
        button.SetFixedSize(w, w);
        button.SetPosition(border_offset, graphics.height - w - border_offset);
        button.visible = false;
        button.AddTag(tag_input);
        ui.root.AddChild(button);
        return button;
    }

    void ShowHideUI(bool bShow)
    {
        Array<UIElement@> buttons = ui.root.GetChildrenWithTag(tag_input);
        for (uint i=0; i<buttons.length; ++i)
        {
            buttons[i].visible = bShow;
        }
    }
};
