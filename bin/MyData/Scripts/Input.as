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

class GameInput
{
    float m_leftStickX;
    float m_leftStickY;
    float m_leftStickMagnitude;
    float m_leftStickAngle;

    float m_rightStickX;
    float m_rightStickY;
    float m_rightStickMagnitude;

    float m_lastLeftStickX;
    float m_lastLeftStickY;
    float m_leftStickHoldTime;

    float m_smooth = 0.9f;

    Vector2  m_rightAxis = Vector2(0, 30);

    float mouseSensitivity = 0.125f;
    float joySensitivity = 0.5;
    float joyLookDeadZone = 0.05;

    int   m_leftStickHoldFrames = 0;

    uint lastMiddlePressedTime = 0;

    GameInput()
    {
        JoystickState@ js = GetJoystick();
        if (js !is null)
            Print("joystick " + js.name);
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
        {
            m_leftStickHoldTime += dt;
            ++m_leftStickHoldFrames;
        }
        else
        {
            m_leftStickHoldTime = 0;
            m_leftStickHoldFrames = 0;
        }

        if (input.mouseButtonPress[MOUSEB_MIDDLE])
            lastMiddlePressedTime = time.systemTime;

        // Print("m_leftStickX=" + String(m_leftStickX) + " m_leftStickY=" + String(m_leftStickY));
    }

    Vector3 GetLeftAxis()
    {
        return Vector3(m_leftStickX, m_leftStickY, m_leftStickMagnitude);
    }

    Vector3 GetRightAxis()
    {
        return Vector3(m_rightStickX, m_rightStickY, m_rightStickMagnitude);
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
            if (input.keyDown['W'])
                ret.y += 1.0f;
            if (input.keyDown['S'])
                ret.y -= 1.0f;
            if (input.keyDown['D'])
                ret.x += 1.0f;
            if (input.keyDown['A'])
                ret.x -= 1.0f;
        }
        return ret;
    }

    Vector2 GetRightStick()
    {
        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
        {
            if (joystick.numAxes >= 4)
            {
                float lookX = joystick.axisPosition[2];
                float lookY = joystick.axisPosition[3];
                Vector2 rightAxis = m_rightAxis;

                if (lookX < -joyLookDeadZone)
                    rightAxis.x -= joySensitivity * lookX * lookX;
                if (lookX > joyLookDeadZone)
                    rightAxis.x += joySensitivity * lookX * lookX;
                if (lookY < -joyLookDeadZone)
                    rightAxis.y -= joySensitivity * lookY * lookY;
                if (lookY > joyLookDeadZone)
                    rightAxis.y += joySensitivity * lookY * lookY;
                m_rightAxis = rightAxis;
            }
        }
        else
        {
            m_rightAxis.x += mouseSensitivity * input.mouseMoveX;
            m_rightAxis.y += mouseSensitivity * input.mouseMoveY;
        }
        return m_rightAxis;
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
        if (freezeInput)
            return false;

        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
            return joystick.buttonPress[2];
        else
            return input.mouseButtonPress[MOUSEB_LEFT];
    }

    bool IsCounterPressed()
    {
        if (freezeInput)
            return false;

        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
            return joystick.buttonPress[3];
        else
            return input.mouseButtonPress[MOUSEB_RIGHT];
    }

    bool IsEvadePressed()
    {
        if (freezeInput)
            return false;

        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
            return joystick.buttonPress[0];
        else
            return input.keyPress[KEY_SPACE];
    }

    bool IsEnterPressed()
    {
        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
        {
            if (joystick.buttonPress[2])
                return true;
        }
        return input.keyPress[KEY_RETURN] || input.keyPress[KEY_SPACE] || input.mouseButtonPress[MOUSEB_LEFT];
    }

    bool IsDistractPressed()
    {
        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
            return joystick.buttonPress[1];
        else
            return input.mouseButtonPress[MOUSEB_MIDDLE];
    }

    int GetDirectionPressed()
    {
        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
        {
            if (m_lastLeftStickY > 0.333f)
                return 0;
            else if (m_lastLeftStickX > 0.333f)
                return 1;
            else if (m_lastLeftStickY < -0.333f)
                return 2;
            else if (m_lastLeftStickX < -0.333f)
                return 3;
        }

        if (input.keyDown[KEY_UP])
            return 0;
        else if (input.keyDown[KEY_RIGHT])
            return 1;
        else if (input.keyDown[KEY_DOWN])
            return 2;
        else if (input.keyDown[KEY_LEFT])
            return 3;

        return -1;
    }

    bool IsRunHolding()
    {
        return input.keyDown[KEY_LSHIFT];
    }

    String GetDebugText()
    {
        String ret =   "leftStick:(" + m_leftStickX + "," + m_leftStickY + ")" +
                       " left-angle=" + m_leftStickAngle + " hold-time=" + m_leftStickHoldTime + " hold-frames" + m_leftStickHoldFrames + " left-magnitude=" + m_leftStickMagnitude +
                       " rightStick:(" + m_rightStickX + "," + m_rightStickY + ")\n";

        JoystickState@ joystick = GetJoystick();
        if (joystick !is null)
        {
            ret += "joystick button--> 0=" + joystick.buttonDown[0] + " 1=" + joystick.buttonDown[1] + " 2=" + joystick.buttonDown[2] + " 3=" + joystick.buttonDown[3] + "\n";
            ret += "joystick axis--> 0=" + joystick.axisPosition[0] + " 1=" + joystick.axisPosition[1] + " 2=" + joystick.axisPosition[2] + " 3=" + joystick.axisPosition[3] + "\n";
        }

        return ret;
    }
};
