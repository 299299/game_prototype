// ==============================================
//
//    Max Class
//
// ==============================================

class MaxStandState : PlayerStandState
{
    MaxStandState(Character@ c)
    {
        super(c);
        AddMotion("AS_DIAL_Stand01_SF/A_Dial_Stand01_Base_SF");
    }

    void Update(float dt)
    {
        Player@ p = cast<Player>(ownner);
        p.UpdateCollects();

        if (gInput.IsEnterPressed())
        {
            p.DoInteract();
        }

        PlayerStandState::Update(dt);
    }
};

class MaxWalkState : PlayerWalkState
{
    MaxWalkState(Character@ c)
    {
        super(c);
        SetMotion("AS_Gen_Max/A_GEN_WalkMaxGP_Loop_SF");
    }

    void Update(float dt)
    {
        Player@ p = cast<Player>(ownner);
        p.UpdateCollects();

        if (gInput.IsEnterPressed())
        {
            p.DoInteract();
        }

        PlayerWalkState::Update(dt);
    }
};

class MaxRunState : PlayerRunState
{
    MaxRunState(Character@ c)
    {
        super(c);
        SetMotion("AS_Gen_Body_SF/A_S_Gen_Jog01");
    }

    void Update(float dt)
    {
        Player@ p = cast<Player>(ownner);
        p.UpdateCollects();

        if (gInput.IsEnterPressed())
        {
            p.DoInteract();
        }

        PlayerRunState::Update(dt);
    }
};

class MaxOpenDoorState : MultiAnimationState
{
    Vector3 velocity = Vector3(0, 0, 1.5f);

    MaxOpenDoorState(Character@ c)
    {
        super(c);
        SetName("OpenDoorState");
        AddMotion("AS_INTERACT_Interact/A_Max_GP_Interact_Door02_SF");
        AddMotion("AS_INTERACT_Interact/A_Max_GP_Interact_Door01_SF");
    }

    void Update(float dt)
    {
        if (timeInState >= 48.0f / 30.0f && timeInState <= 105.0f / 30.0f)
            ownner.SetVelocity(ownner.GetNode().worldRotation * velocity);
        MultiAnimationState::Update(dt);
    }
};

class Max : Player
{
    Max()
    {
        super();
    }

    void AddStates()
    {
        stateMachine.AddState(MaxStandState(this));
        stateMachine.AddState(MaxWalkState(this));
        stateMachine.AddState(MaxRunState(this));
        stateMachine.AddState(CharacterAlignState(this));
        stateMachine.AddState(AnimationTestState(this));
        stateMachine.AddState(MaxOpenDoorState(this));
    }
};

void Create_Max_Motions()
{
    AssignMotionRig("Models/LIS/CH_Max/CH_S_Max01.mdl", "RootNode", "Hips");
    RotateAnimation(GetAnimationName("AS_INTERACT_Interact/A_Max_GP_Interact_Door01_SF"), 90);
    RotateAnimation(GetAnimationName("AS_INTERACT_Interact/A_Max_GP_Interact_Door02_SF"), -90);
}

void Add_Max_AnimationTriggers()
{
    AddStringAnimationTrigger("AS_Gen_Max/A_GEN_WalkMaxGP_Loop_SF", 14, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger("AS_Gen_Max/A_GEN_WalkMaxGP_Loop_SF", 32, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger("AS_Gen_Body_SF/A_S_Gen_Jog01", 10, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger("AS_Gen_Body_SF/A_S_Gen_Jog01", 23, FOOT_STEP, L_FOOT);
}

