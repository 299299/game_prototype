

class GameInput
{
    float m_leftStickX = 0;
    float m_leftStickY = 0;
    float m_leftStickMagnitude = 0;
    float m_leftStickAngle = 0;

    float m_rightStickX;
    float m_rightStickY;
    float m_rightStickMagnitude;

    float m_lastLeftStickX;
    float m_lastLeftStickY;
    float m_leftStickHoldTime;

    float m_smooth;

    GameInput()
    {
        m_leftStickX = 0;
        m_leftStickY = 0;
        m_leftStickMagnitude = 0;
        m_leftStickAngle = 0;

        m_rightStickX = 0;
        m_rightStickY = 0;
        m_rightStickMagnitude = 0;

        m_lastLeftStickX = 0;
        m_lastLeftStickY = 0;

        m_leftStickHoldTime = 0;

        m_smooth = 0.9f;
    }

    ~GameInput()
    {

    }

    void Update(float dt)
    {
        m_lastLeftStickX = m_leftStickX;
        m_lastLeftStickY = m_leftStickY;

        Vector2 leftStick = GetLeftStick();
        Vector2 rightStick = GetRightStick();

        m_leftStickX = Lerp(m_leftStickX, leftStick.x, m_smooth);
        m_leftStickY = Lerp(m_leftStickY, leftStick.y, m_smooth);
        m_rightStickX = Lerp(m_rightStickX, rightStick.x, m_smooth);
        m_rightStickY = Lerp(m_rightStickY, rightStick.y, m_smooth);

        m_leftStickMagnitude = m_leftStickX * m_leftStickX + m_leftStickY * m_leftStickY;
        m_rightStickMagnitude = m_rightStickX * m_rightStickX + m_rightStickY * m_rightStickY;

        m_leftStickAngle = Atan2(m_leftStickX, m_leftStickY);

        float diffX = m_lastLeftStickX - m_leftStickX;
        float diffY = m_lastLeftStickY - m_leftStickY;
        float stickDifference = diffX * diffX + diffY * diffY;

        if(stickDifference < 0.1f)
            m_leftStickHoldTime += dt;
        else
            m_leftStickHoldTime = 0;

        // Print("m_leftStickX=" + String(m_leftStickX) + " m_leftStickY=" + String(m_leftStickY));
    }

    Vector2 GetLeftStick()
    {
        Vector2 ret;
        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
        {
            if (joystick.numAxes >= 2)
            {
                ret.x = joystick.axisPosition[0];
                ret.y = -joystick.axisPosition[1];
            }
        }
        else
        {
            if (input.keyDown[KEY_UP])
                ret.y += 1.0f;
            if (input.keyDown[KEY_DOWN])
                ret.y -= 1.0f;
            if (input.keyDown[KEY_RIGHT])
                ret.x += 1.0f;
            if (input.keyDown[KEY_LEFT])
                ret.x -= 1.0f;
        }
        return ret;
    }

    Vector2 GetRightStick()
    {
        Vector2 ret;
        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
        {
            if (joystick.numAxes >= 4)
            {
                ret.x = joystick.axisPosition[2];
                ret.y = joystick.axisPosition[3];
            }
        }
        else
        {
            ret.x = input.mouseMoveX;
            ret.y = input.mouseMoveY;
        }
        return ret;
    }

    JoystickState@ GetJoystick()
    {
        if (input.numJoysticks > 0)
        {
            return input.joysticksByIndex[0];
        }
        return null;
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

    // Returns true if the right stick is the dead zone, false otherwise
    bool IsRightStickInDeadZone()
    {
        return m_rightStickMagnitude < 0.1;
    }

    bool IsAttackPressed()
    {
        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
            return joystick.buttonPress[1];
        else
            return input.mouseButtonPress[MOUSEB_LEFT];
    }

    bool IsCounterPressed()
    {
        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
            return joystick.buttonPress[2];
        else
            return input.mouseButtonPress[MOUSEB_RIGHT];
    }

    bool IsEvadePressed()
    {
        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
            return joystick.buttonPress[3];
        else
            return input.keyPress[KEY_SPACE];
    }

    String GetDebugText()
    {
        return "leftStick:(" + m_leftStickX + "," + m_leftStickY + ")" +
               " left-angle=" + m_leftStickAngle + " hold-time=" + m_leftStickHoldTime + " left-magnitude=" + m_leftStickMagnitude +
               " rightStick:(" + m_rightStickX + "," + m_rightStickY + ")\n";
    }
};

GameInput@ gInput = GameInput();