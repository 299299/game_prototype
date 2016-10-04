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
    }
};

void Create_Max_Motions()
{

}

void Add_Max_AnimationTriggers()
{
    AddStringAnimationTrigger("AS_Gen_Max/A_GEN_WalkMaxGP_Loop_SF", 14, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger("AS_Gen_Max/A_GEN_WalkMaxGP_Loop_SF", 32, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger("AS_Gen_Body_SF/A_S_Gen_Jog01", 10, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger("AS_Gen_Body_SF/A_S_Gen_Jog01", 23, FOOT_STEP, L_FOOT);
}

